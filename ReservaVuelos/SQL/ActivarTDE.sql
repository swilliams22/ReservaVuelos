-- TDE opcional. Configurar SESSION_CONTEXT en la misma conexión antes de ejecutar.
-- No guardar contraseñas ni archivos .cer/.pvk en el repositorio.
USE master;
GO
IF ISNULL(TRY_CONVERT(bit, SESSION_CONTEXT(N'ReservaVuelos.ActivarTDE')), 0) = 1
BEGIN
    DECLARE @Edicion int = CONVERT(int, SERVERPROPERTY('EngineEdition'));
    DECLARE @Version int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
    IF NOT (@Edicion = 3 OR (@Edicion = 2 AND @Version >= 15))
        THROW 50100, 'Esta edición/version de SQL Server no está contemplada para TDE.', 1;
    IF DB_ID(N'ReservaVuelosDB') IS NULL
        THROW 50101, 'La base ReservaVuelosDB debe existir antes de activar TDE.', 1;

    DECLARE @ClaveMaestra nvarchar(128) = CONVERT(nvarchar(128), SESSION_CONTEXT(N'ReservaVuelos.ClaveMaestraTDE'));
    DECLARE @ClaveRespaldo nvarchar(128) = CONVERT(nvarchar(128), SESSION_CONTEXT(N'ReservaVuelos.ClaveRespaldoTDE'));
    DECLARE @RutaCertificado nvarchar(4000) = CONVERT(nvarchar(4000), SESSION_CONTEXT(N'ReservaVuelos.RutaCertificadoTDE'));
    DECLARE @RutaPrivada nvarchar(4000) = CONVERT(nvarchar(4000), SESSION_CONTEXT(N'ReservaVuelos.RutaPrivadaTDE'));
    DECLARE @Sql nvarchar(max);

    IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##')
    BEGIN
        IF NULLIF(@ClaveMaestra, N'') IS NULL
            THROW 50102, 'Falta ClaveMaestraTDE para crear la clave maestra de master.', 1;
        SET @Sql = N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = ' + QUOTENAME(@ClaveMaestra, '''') + N';';
        EXEC sys.sp_executesql @Sql;
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertificadoTDE_ReservaVuelos')
        EXEC(N'CREATE CERTIFICATE CertificadoTDE_ReservaVuelos WITH SUBJECT = ''TDE ReservaVuelosDB'';');

    -- Respaldo obligatorio antes de crear/activar la DEK. No sobreescribe archivos.
    IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertificadoTDE_ReservaVuelos' AND (pvt_key_last_backup_date IS NULL OR ISNULL(TRY_CONVERT(bit,SESSION_CONTEXT(N'ReservaVuelos.RespaldarTDE')),0)=1))
    BEGIN
        IF NULLIF(@ClaveRespaldo, N'') IS NULL OR NULLIF(@RutaCertificado, N'') IS NULL OR NULLIF(@RutaPrivada, N'') IS NULL
            THROW 50103, 'Configurar la contraseña y rutas del respaldo del certificado y clave privada TDE.', 1;
        SET @Sql = N'BACKUP CERTIFICATE CertificadoTDE_ReservaVuelos TO FILE = N''' + REPLACE(@RutaCertificado, '''', '''''') +
            N''' WITH PRIVATE KEY (FILE = N''' + REPLACE(@RutaPrivada, '''', '''''') +
            N''', ENCRYPTION BY PASSWORD = ' + QUOTENAME(@ClaveRespaldo, '''') + N');';
        EXEC sys.sp_executesql @Sql;
    END;

    DECLARE @Huella varbinary(64) = (SELECT thumbprint FROM sys.certificates WHERE name = N'CertificadoTDE_ReservaVuelos');
    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND encryptor_thumbprint <> @Huella)
        THROW 50104, 'La base ya tiene una clave protegida por otro certificado. No se modificó su configuración TDE.', 1;

    IF NOT EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB'))
        EXEC(N'USE ReservaVuelosDB; CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE CertificadoTDE_ReservaVuelos;');

    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND (key_algorithm <> 'AES' OR key_length <> 256))
        THROW 50106, 'La clave existente no es AES-256. Revisar antes de cambiar su algoritmo.', 1;
    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND encryption_state = 5)
        THROW 50105, 'Hay un descifrado en curso. Esperar antes de activar TDE.', 1;
    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND encryption_state = 1)
        EXEC(N'ALTER DATABASE ReservaVuelosDB SET ENCRYPTION ON;');

    SELECT DB_NAME(database_id) AS Base, encryption_state AS Estado, percent_complete AS Porcentaje
    FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB');
    PRINT 'Estado 2: cifrado en curso. Estado 3: cifrado completo. Conservar certificado, clave privada y contraseña fuera del equipo.';
END
ELSE
    PRINT 'TDE omitido: habilitar ReservaVuelos.ActivarTDE en SESSION_CONTEXT para ejecutarlo.';
GO
USE ReservaVuelosDB;
GO

/*
-- CONSULTA PARA DEMOSTRAR EL CIFRADO TDE (copiar y ejecutar en SSMS).
-- Se deja comentada: no se ejecuta con el script.
SELECT
    DB_NAME(database_id) AS BaseDeDatos,
    CASE encryption_state
        WHEN 2 THEN 'Cifrado en curso'
        WHEN 3 THEN 'Cifrado completo'
        ELSE 'Otro estado'
    END AS Estado,
    key_algorithm AS Algoritmo,
    key_length AS Bits
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID(N'ReservaVuelosDB');
-- Resultado esperado: ReservaVuelosDB | Cifrado completo | AES | 256.
*/
