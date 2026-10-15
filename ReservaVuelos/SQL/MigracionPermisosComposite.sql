USE ReservaVuelosDB;
GO
-- Migración aditiva e idempotente. No modifica Usuarios.Rol ni DVH/DVV.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.Permisos', N'U') IS NULL
BEGIN
 CREATE TABLE dbo.Permisos (
  IdPermiso INT IDENTITY PRIMARY KEY,
  Codigo NVARCHAR(100) NOT NULL UNIQUE,
  EsGrupo BIT NOT NULL
 );
 CREATE TABLE dbo.PermisoRelacion (
  IdPadre INT NOT NULL REFERENCES dbo.Permisos(IdPermiso),
  IdHijo INT NOT NULL REFERENCES dbo.Permisos(IdPermiso),
  CONSTRAINT PK_PermisoRelacion PRIMARY KEY (IdPadre, IdHijo),
  CONSTRAINT CK_PermisoRelacion_NoPropio CHECK (IdPadre <> IdHijo)
 );
END;
-- No pisa una configuración existente al volver a ejecutar.
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos)
BEGIN
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'OperacionesUsuario', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'GestionVuelos', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'GestionTecnica', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Usuario', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Administrador', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'WebMaster', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Reservas.Crear', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Reservas.VerPropias', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Reservas.CancelarPropias', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Datos.VerPropios', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Datos.EditarPropios', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Administrar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Crear', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.DarBaja', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Importar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Exportar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Validar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Resolver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Recalcular', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Backup.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Backup.Crear', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Backup.Restaurar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Bitacora.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Idiomas.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Idiomas.Editar', 0);
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Reservas.Crear';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Reservas.VerPropias';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Reservas.CancelarPropias';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Datos.VerPropios';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Datos.EditarPropios';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Administrar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Crear';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.DarBaja';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Importar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Exportar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Validar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Resolver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Recalcular';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Backup.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Backup.Crear';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Backup.Restaurar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Bitacora.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Idiomas.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Idiomas.Editar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'Usuario' AND h.Codigo=N'OperacionesUsuario';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'Administrador' AND h.Codigo=N'OperacionesUsuario';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'Administrador' AND h.Codigo=N'GestionVuelos';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'WebMaster' AND h.Codigo=N'OperacionesUsuario';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'WebMaster' AND h.Codigo=N'GestionTecnica';
END;
COMMIT;
GO
CREATE OR ALTER TRIGGER dbo.TR_PermisoRelacion_Validar
ON dbo.PermisoRelacion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Total INT;
 SELECT @Total=COUNT(*) FROM dbo.Permisos WITH (TABLOCKX, HOLDLOCK);
 IF EXISTS (SELECT 1 FROM dbo.PermisoRelacion r JOIN dbo.Permisos p ON p.IdPermiso=r.IdPadre WHERE p.EsGrupo=0)
  THROW 50001, 'Un permiso simple no puede contener hijos.', 1;
 DECLARE @Ciclo BIT=0;
 ;WITH Camino AS (
  SELECT r.IdHijo AS Actual,
   CAST('/'+CONVERT(VARCHAR(12),r.IdPadre)+'/'+CONVERT(VARCHAR(12),r.IdHijo)+'/' AS VARCHAR(MAX)) AS Ruta,
   CAST(0 AS BIT) AS Ciclo
  FROM dbo.PermisoRelacion r
  UNION ALL
  SELECT r.IdHijo, CAST(c.Ruta+CONVERT(VARCHAR(12),r.IdHijo)+'/' AS VARCHAR(MAX)),
   CAST(CASE WHEN CHARINDEX('/'+CONVERT(VARCHAR(12),r.IdHijo)+'/', c.Ruta)>0 THEN 1 ELSE 0 END AS BIT)
  FROM Camino c JOIN dbo.PermisoRelacion r ON r.IdPadre=c.Actual WHERE c.Ciclo=0
 )
 SELECT TOP (1) @Ciclo=1 FROM Camino WHERE Ciclo=1 OPTION (MAXRECURSION 100);
 IF @Ciclo=1 THROW 50002, 'La estructura de permisos no puede contener ciclos.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.TR_Permisos_ValidarTipo
ON dbo.Permisos AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PermisoRelacion r ON r.IdPadre=i.IdPermiso WHERE i.EsGrupo=0)
  THROW 50003, 'Un grupo con hijos no puede convertirse en permiso simple.', 1;
END;
GO
