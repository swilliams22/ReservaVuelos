USE ReservaVuelosDB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
-- Filtros traducibles. No reemplaza textos editados.
DECLARE @Filtros TABLE (Clave nvarchar(100), Es nvarchar(500), En nvarchar(500));
INSERT @Filtros VALUES (N'grillas.buscar', N'Buscar en la tabla', N'Search table'), (N'grillas.filtrar', N'Filtrar', N'Filter'), (N'grillas.limpiar', N'Limpiar', N'Clear'), (N'grillas.fecha', N'Fecha', N'Date'), (N'grillas.estado', N'Estado', N'Status'), (N'grillas.activo', N'Activo', N'Active'), (N'grillas.resuelto', N'Resuelto', N'Resolved');
INSERT dbo.Etiqueta(Clave,Pantalla,Descripcion) SELECT Clave,N'Grillas',Es FROM @Filtros f WHERE NOT EXISTS(SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave=f.Clave);
INSERT dbo.Traduccion(IdIdioma,IdEtiqueta,Texto) SELECT i.IdIdioma,e.IdEtiqueta,CASE i.Codigo WHEN N'es-AR' THEN f.Es ELSE f.En END FROM @Filtros f JOIN dbo.Etiqueta e ON e.Clave=f.Clave JOIN dbo.Idioma i ON i.Codigo IN(N'es-AR',N'en-US') WHERE NOT EXISTS(SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma=i.IdIdioma AND t.IdEtiqueta=e.IdEtiqueta);
GO
USE ReservaVuelosDB;
GO
SET XACT_ABORT ON;
GO
CREATE OR ALTER FUNCTION dbo.CalcularDVHAmpliado(@texto nvarchar(max)) RETURNS int AS
BEGIN
 DECLARE @i int=1,@n int=DATALENGTH(@texto)/2,@s bigint=0,@p int;
 WHILE @i<=@n
 BEGIN
  SET @p=CASE (@i-1)%25 WHEN 0 THEN 2 WHEN 1 THEN 3 WHEN 2 THEN 5 WHEN 3 THEN 7 WHEN 4 THEN 11 WHEN 5 THEN 13 WHEN 6 THEN 17 WHEN 7 THEN 19 WHEN 8 THEN 23 WHEN 9 THEN 29 WHEN 10 THEN 31 WHEN 11 THEN 37 WHEN 12 THEN 41 WHEN 13 THEN 43 WHEN 14 THEN 47 WHEN 15 THEN 53 WHEN 16 THEN 59 WHEN 17 THEN 61 WHEN 18 THEN 67 WHEN 19 THEN 71 WHEN 20 THEN 73 WHEN 21 THEN 79 WHEN 22 THEN 83 WHEN 23 THEN 89 ELSE 97 END;
  SET @s=@s+CONVERT(bigint,UNICODE(SUBSTRING(@texto COLLATE Latin1_General_100_BIN2,@i,1)))*@p*@i;
  SET @i=@i+1;
 END;
 RETURN CONVERT(int,@s%251);
END;
GO
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.Idioma','DVH') IS NULL ALTER TABLE dbo.Idioma ADD DVH int NOT NULL CONSTRAINT DF_Idioma_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Idioma AS SELECT CONVERT(nvarchar(100),IdIdioma) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdIdioma]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Codigo]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Nombre]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[EsDefault]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Activo]),N'')))) AS Calculado FROM dbo.Idioma;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Idioma')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Idioma') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Idioma t JOIN dbo.DV_Idioma v ON v.IdRegistro=CONVERT(nvarchar(100),IdIdioma);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Idioma',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Idioma;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Idioma',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Idioma;
END;
GO
IF COL_LENGTH('dbo.Etiqueta','DVH') IS NULL ALTER TABLE dbo.Etiqueta ADD DVH int NOT NULL CONSTRAINT DF_Etiqueta_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Etiqueta AS SELECT CONVERT(nvarchar(100),IdEtiqueta) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdEtiqueta]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Clave]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Pantalla]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Descripcion]),N'')))) AS Calculado FROM dbo.Etiqueta;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Etiqueta')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Etiqueta') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Etiqueta t JOIN dbo.DV_Etiqueta v ON v.IdRegistro=CONVERT(nvarchar(100),IdEtiqueta);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Etiqueta',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Etiqueta;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Etiqueta',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Etiqueta;
END;
GO
IF COL_LENGTH('dbo.Traduccion','DVH') IS NULL ALTER TABLE dbo.Traduccion ADD DVH int NOT NULL CONSTRAINT DF_Traduccion_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Traduccion AS SELECT CONVERT(nvarchar(100),CONCAT(IdIdioma, ':', IdEtiqueta)) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdIdioma]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdEtiqueta]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Texto]),N'')))) AS Calculado FROM dbo.Traduccion;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Traduccion')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Traduccion') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Traduccion t JOIN dbo.DV_Traduccion v ON v.IdRegistro=CONVERT(nvarchar(100),CONCAT(IdIdioma, ':', IdEtiqueta));
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Traduccion',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Traduccion;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Traduccion',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Traduccion;
END;
GO
IF COL_LENGTH('dbo.Permisos','DVH') IS NULL ALTER TABLE dbo.Permisos ADD DVH int NOT NULL CONSTRAINT DF_Permisos_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Permisos AS SELECT CONVERT(nvarchar(100),IdPermiso) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdPermiso]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Codigo]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[EsGrupo]),N'')))) AS Calculado FROM dbo.Permisos;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Permisos')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Permisos') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Permisos t JOIN dbo.DV_Permisos v ON v.IdRegistro=CONVERT(nvarchar(100),IdPermiso);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Permisos',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Permisos;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Permisos',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Permisos;
END;
GO
IF COL_LENGTH('dbo.PermisoRelacion','DVH') IS NULL ALTER TABLE dbo.PermisoRelacion ADD DVH int NOT NULL CONSTRAINT DF_PermisoRelacion_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_PermisoRelacion AS SELECT CONVERT(nvarchar(100),CONCAT(IdPadre, ':', IdHijo)) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdPadre]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdHijo]),N'')))) AS Calculado FROM dbo.PermisoRelacion;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'PermisoRelacion')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'PermisoRelacion') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.PermisoRelacion t JOIN dbo.DV_PermisoRelacion v ON v.IdRegistro=CONVERT(nvarchar(100),CONCAT(IdPadre, ':', IdHijo));
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'PermisoRelacion',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_PermisoRelacion;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'PermisoRelacion',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.PermisoRelacion;
END;
GO
IF COL_LENGTH('dbo.ConfiguracionSistema','DVH') IS NULL ALTER TABLE dbo.ConfiguracionSistema ADD DVH int NOT NULL CONSTRAINT DF_ConfiguracionSistema_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_ConfiguracionSistema AS SELECT CONVERT(nvarchar(100),IdConfiguracion) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdConfiguracion]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[ModoContingencia]),N'')))+N'|'+ISNULL(CONVERT(nvarchar(19),[FechaUltimaValidacion],126),N'')+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[MotivoContingencia]),N'')))) AS Calculado FROM dbo.ConfiguracionSistema;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'ConfiguracionSistema')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'ConfiguracionSistema') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.ConfiguracionSistema t JOIN dbo.DV_ConfiguracionSistema v ON v.IdRegistro=CONVERT(nvarchar(100),IdConfiguracion);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'ConfiguracionSistema',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_ConfiguracionSistema;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'ConfiguracionSistema',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.ConfiguracionSistema;
END;
GO
IF COL_LENGTH('dbo.IntegridadError','DVH') IS NULL ALTER TABLE dbo.IntegridadError ADD DVH int NOT NULL CONSTRAINT DF_IntegridadError_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_IntegridadError AS SELECT CONVERT(nvarchar(100),IdError) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdError]),N'')))+N'|'+ISNULL(CONVERT(nvarchar(19),[Fecha],126),N'')+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[TipoError]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[TipoOperacion]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[NombreTabla]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdRegistroAfectado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[ValorEsperado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[ValorCalculado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Estado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdUsuarioAdministrador]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[AccionTomada]),N'')))) AS Calculado FROM dbo.IntegridadError;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'IntegridadError')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'IntegridadError') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.IntegridadError t JOIN dbo.DV_IntegridadError v ON v.IdRegistro=CONVERT(nvarchar(100),IdError);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'IntegridadError',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_IntegridadError;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'IntegridadError',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.IntegridadError;
END;
GO
COMMIT;
GO
BEGIN TRANSACTION;
DECLARE @CambiosEtiqueta int=0,@CambiosTraduccion int=0;
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Etiqueta')
BEGIN
 UPDATE e SET DVH=v.Calculado FROM dbo.Etiqueta e JOIN dbo.DV_Etiqueta v ON v.IdRegistro=CONVERT(nvarchar(100),e.IdEtiqueta) WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Etiqueta' AND r.IdRegistro=v.IdRegistro);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Etiqueta',v.IdRegistro,v.Calculado,SYSDATETIME() FROM dbo.DV_Etiqueta v JOIN dbo.Etiqueta e ON CONVERT(nvarchar(100),e.IdEtiqueta)=v.IdRegistro WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Etiqueta' AND r.IdRegistro=v.IdRegistro);
 SET @CambiosEtiqueta=@@ROWCOUNT;
 UPDATE t SET DVH=v.Calculado FROM dbo.Traduccion t JOIN dbo.DV_Traduccion v ON v.IdRegistro=CONCAT(t.IdIdioma,':',t.IdEtiqueta) JOIN dbo.Etiqueta e ON e.IdEtiqueta=t.IdEtiqueta WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Traduccion' AND r.IdRegistro=v.IdRegistro);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Traduccion',v.IdRegistro,v.Calculado,SYSDATETIME() FROM dbo.DV_Traduccion v JOIN dbo.Traduccion t ON CONCAT(t.IdIdioma,':',t.IdEtiqueta)=v.IdRegistro JOIN dbo.Etiqueta e ON e.IdEtiqueta=t.IdEtiqueta WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Traduccion' AND r.IdRegistro=v.IdRegistro);
 SET @CambiosTraduccion=@@ROWCOUNT;
 UPDATE dbo.IntegridadDVV SET ValorDVV=(SELECT ISNULL(SUM(CONVERT(bigint,DVH)),0) FROM dbo.Etiqueta) WHERE NombreTabla=N'Etiqueta' AND @CambiosEtiqueta>0;
 UPDATE dbo.IntegridadDVV SET ValorDVV=(SELECT ISNULL(SUM(CONVERT(bigint,DVH)),0) FROM dbo.Traduccion) WHERE NombreTabla=N'Traduccion' AND @CambiosTraduccion>0;
END;
COMMIT;
GO
