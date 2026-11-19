/*
Actualiza una ReservaVuelosDB existente al estado de roles/permisos de esta entrega.
Ejecutar con sqlcmd -S SERVIDOR -E -b -i base/ActualizarBD_2026-10-15.sql
No ejecutar ReservaVuelos.sql sobre una base con datos: ese script la recrea.
No cambia contraseñas de cuentas existentes.
*/
USE ReservaVuelosDB;
GO
SET XACT_ABORT ON;
IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
 OR OBJECT_ID(N'dbo.IntegridadRegistro', N'U') IS NULL
 OR OBJECT_ID(N'dbo.IntegridadDVV', N'U') IS NULL
 THROW 50010, 'Falta el esquema previo de la aplicacion. Restaurar el backup completo o instalar el esquema inicial.', 1;
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name=N'CK_Usuarios_Rol' AND parent_object_id=OBJECT_ID(N'dbo.Usuarios'))
 ALTER TABLE dbo.Usuarios DROP CONSTRAINT CK_Usuarios_Rol;
-- Una vez instalados los perfiles, el rol lo valida TR_Usuarios_ValidarRol (ver final del script).
IF OBJECT_ID(N'dbo.TR_Usuarios_ValidarRol', N'TR') IS NULL
 ALTER TABLE dbo.Usuarios WITH CHECK ADD CONSTRAINT CK_Usuarios_Rol
  CHECK (Rol IN (N'Administrador', N'WebMaster', N'Usuario'));
COMMIT;
GO
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
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'Administrador' AND h.Codigo=N'GestionVuelos';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'WebMaster' AND h.Codigo=N'GestionTecnica';
END;
COMMIT;
GO
BEGIN TRANSACTION;
-- Administrador y WebMaster no operan como clientes: se quita OperacionesUsuario de esos roles.
-- Idempotente: en una base nueva no hay nada que borrar; en una existente aplica el cambio.
DELETE r
FROM dbo.PermisoRelacion r
JOIN dbo.Permisos p ON p.IdPermiso = r.IdPadre
JOIN dbo.Permisos h ON h.IdPermiso = r.IdHijo
WHERE p.Codigo IN (N'Administrador', N'WebMaster')
  AND h.Codigo = N'OperacionesUsuario';
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

USE ReservaVuelosDB;
GO
/*
Perfiles administrables desde la aplicación.
Requiere MigracionPermisosComposite.sql. Es aditiva e idempotente: se puede repetir.
- Agrega las hojas Perfiles.Ver, Perfiles.Editar, Usuarios.Ver y Usuarios.AsignarRol
  dentro de GestionTecnica (WebMaster). Si se quitan desde la pantalla, no se reponen.
- Carga los textos (es-AR y en-US) de las pantallas de perfiles y usuarios.
- Reemplaza el CHECK fijo de Usuarios.Rol por triggers: el rol de un usuario debe ser
  un grupo existente de Permisos, y no se puede borrar un grupo asignado a usuarios.
No modifica Usuarios ni DVH/DVV.
*/
SET XACT_ABORT ON;
IF OBJECT_ID(N'dbo.Permisos', N'U') IS NULL OR OBJECT_ID(N'dbo.PermisoRelacion', N'U') IS NULL
 THROW 50020, 'Ejecutar antes MigracionPermisosComposite.sql.', 1;
IF EXISTS (SELECT 1 FROM dbo.Usuarios u WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = u.Rol AND p.EsGrupo = 1))
 THROW 50021, 'Hay usuarios con un rol que no existe como grupo en Permisos.', 1;
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Usuarios_Rol' AND parent_object_id = OBJECT_ID(N'dbo.Usuarios'))
 ALTER TABLE dbo.Usuarios DROP CONSTRAINT CK_Usuarios_Rol;

DECLARE @Tecnica INT = (SELECT IdPermiso FROM dbo.Permisos WHERE Codigo = N'GestionTecnica' AND EsGrupo = 1);
DECLARE @Nuevas TABLE (IdPermiso INT NOT NULL);
-- Sólo se cuelgan de GestionTecnica las hojas creadas en esta ejecución.
INSERT dbo.Permisos (Codigo, EsGrupo)
OUTPUT inserted.IdPermiso INTO @Nuevas (IdPermiso)
SELECT v.Codigo, 0
FROM (VALUES (N'Perfiles.Ver'), (N'Perfiles.Editar'), (N'Usuarios.Ver'), (N'Usuarios.AsignarRol')) v (Codigo)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = v.Codigo);
IF @Tecnica IS NOT NULL
 INSERT dbo.PermisoRelacion (IdPadre, IdHijo) SELECT @Tecnica, IdPermiso FROM @Nuevas;
COMMIT;
GO
CREATE OR ALTER TRIGGER dbo.TR_Usuarios_ValidarRol
ON dbo.Usuarios AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT UPDATE(Rol) RETURN;
 IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = i.Rol AND p.EsGrupo = 1))
  THROW 50004, 'El rol asignado debe ser un perfil existente.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.TR_Permisos_ProtegerRolEnUso
ON dbo.Permisos AFTER DELETE, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM dbo.Usuarios u
  WHERE u.Rol IN (SELECT Codigo FROM deleted)
    AND NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = u.Rol AND p.EsGrupo = 1))
  THROW 50005, 'El perfil está asignado a usuarios.', 1;
END;
GO
-- Textos de las pantallas de perfiles y usuarios (no pisa traducciones editadas).
IF OBJECT_ID(N'dbo.Etiqueta', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.Traduccion', N'U') IS NOT NULL
BEGIN
 DECLARE @Seed TABLE (Clave NVARCHAR(100), Pantalla NVARCHAR(50), Descripcion NVARCHAR(200), Es NVARCHAR(500), En NVARCHAR(500));
 INSERT INTO @Seed (Clave, Pantalla, Descripcion, Es, En)
 VALUES
    (N'menu.perfiles', N'Menú', N'Menú: gestión de perfiles', N'Perfiles', N'Profiles'),
    (N'menu.usuarios', N'Menú', N'Menú: gestión de usuarios', N'Usuarios', N'Users'),
    (N'perfiles.titulo', N'Gestión de perfiles', N'Título de la pantalla y de la pestaña', N'Gestión de perfiles', N'Profile management'),
    (N'perfiles.ayuda', N'Gestión de perfiles', N'Texto de ayuda', N'Un perfil agrupa permisos. A un perfil se le pueden asignar permisos simples y otros perfiles. Los permisos simples están definidos por el sistema y no se crean desde esta pantalla.', N'A profile groups permissions. A profile can be given simple permissions and other profiles. Simple permissions are defined by the system and cannot be created from this screen.'),
    (N'perfiles.nuevo.titulo', N'Gestión de perfiles', N'Subtítulo: nuevo perfil', N'Nuevo perfil', N'New profile'),
    (N'perfiles.lbl.nombre', N'Gestión de perfiles', N'Etiqueta del nombre', N'Nombre (hasta 30 caracteres)', N'Name (up to 30 characters)'),
    (N'perfiles.btn.crear', N'Gestión de perfiles', N'Botón crear', N'Crear perfil', N'Create profile'),
    (N'perfiles.lista.titulo', N'Gestión de perfiles', N'Subtítulo: lista', N'Perfiles', N'Profiles'),
    (N'perfiles.col.nombre', N'Gestión de perfiles', N'Columna nombre', N'Nombre', N'Name'),
    (N'perfiles.col.usuarios', N'Gestión de perfiles', N'Columna usuarios asignados', N'Usuarios asignados', N'Assigned users'),
    (N'perfiles.col.acciones', N'Gestión de perfiles', N'Columna acciones', N'Acciones', N'Actions'),
    (N'perfiles.col.permiso', N'Gestión de perfiles', N'Columna permiso', N'Permiso', N'Permission'),
    (N'perfiles.col.tipo', N'Gestión de perfiles', N'Columna tipo', N'Tipo', N'Type'),
    (N'perfiles.tipo.simple', N'Gestión de perfiles', N'Tipo: permiso simple', N'Simple', N'Simple'),
    (N'perfiles.tipo.compuesto', N'Gestión de perfiles', N'Tipo: perfil (compuesto)', N'Compuesto', N'Composite'),
    (N'perfiles.btn.ver', N'Gestión de perfiles', N'Botón ver/editar', N'Ver / editar', N'View / edit'),
    (N'perfiles.btn.eliminar', N'Gestión de perfiles', N'Botón eliminar', N'Eliminar', N'Delete'),
    (N'perfiles.btn.quitar', N'Gestión de perfiles', N'Botón quitar permiso', N'Quitar', N'Remove'),
    (N'perfiles.btn.agregar', N'Gestión de perfiles', N'Botón agregar permiso', N'Agregar', N'Add'),
    (N'perfiles.btn.cerrar', N'Gestión de perfiles', N'Botón cerrar', N'Cerrar', N'Close'),
    (N'perfiles.detalle.titulo', N'Gestión de perfiles', N'Subtítulo del detalle', N'Perfil:', N'Profile:'),
    (N'perfiles.arbol.titulo', N'Gestión de perfiles', N'Subtítulo del árbol', N'Permisos efectivos (árbol completo)', N'Effective permissions (full tree)'),
    (N'perfiles.asignados.titulo', N'Gestión de perfiles', N'Subtítulo de asignados', N'Asignados directamente', N'Directly assigned'),
    (N'perfiles.agregar.titulo', N'Gestión de perfiles', N'Subtítulo de agregar', N'Agregar permiso o perfil', N'Add permission or profile'),
    (N'perfiles.sinAsignados', N'Gestión de perfiles', N'Grilla vacía', N'Este perfil todavía no tiene permisos.', N'This profile has no permissions yet.'),
    (N'perfiles.sinDisponibles', N'Gestión de perfiles', N'Lista de disponibles vacía', N'No hay más permisos para agregar', N'No more permissions to add'),
    (N'perfiles.msg.creado', N'Gestión de perfiles', N'Mensaje: perfil creado', N'Perfil creado.', N'Profile created.'),
    (N'perfiles.msg.agregado', N'Gestión de perfiles', N'Mensaje: permiso agregado', N'Permiso agregado.', N'Permission added.'),
    (N'perfiles.msg.quitado', N'Gestión de perfiles', N'Mensaje: permiso quitado', N'Permiso quitado.', N'Permission removed.'),
    (N'perfiles.msg.eliminado', N'Gestión de perfiles', N'Mensaje: perfil eliminado', N'Perfil eliminado.', N'Profile deleted.'),
    (N'perfiles.msg.confirmarEliminar', N'Gestión de perfiles', N'Confirmación al eliminar', N'¿Eliminar este perfil?', N'Delete this profile?'),
    (N'perfiles.msg.error', N'Gestión de perfiles', N'Error: prefijo', N'Error', N'Error'),
    (N'usuarios.titulo', N'Gestión de usuarios', N'Título de la pantalla y de la pestaña', N'Gestión de usuarios', N'User management'),
    (N'usuarios.ayuda', N'Gestión de usuarios', N'Texto de ayuda', N'Elija el perfil de cada usuario. El cambio se aplica en su próxima acción, sin cerrar su sesión. No puede cambiar su propio perfil.', N'Choose each user''s profile. The change applies on their next action, without closing their session. You cannot change your own profile.'),
    (N'usuarios.col.nombre', N'Gestión de usuarios', N'Columna nombre', N'Nombre', N'Name'),
    (N'usuarios.col.email', N'Gestión de usuarios', N'Columna email', N'Email', N'Email'),
    (N'usuarios.col.estado', N'Gestión de usuarios', N'Columna estado', N'Estado', N'Status'),
    (N'usuarios.col.rol', N'Gestión de usuarios', N'Columna perfil', N'Perfil', N'Profile'),
    (N'usuarios.col.acciones', N'Gestión de usuarios', N'Columna acciones', N'Acciones', N'Actions'),
    (N'usuarios.estado.activo', N'Gestión de usuarios', N'Estado: activo', N'Activo', N'Active'),
    (N'usuarios.estado.inactivo', N'Gestión de usuarios', N'Estado: inactivo', N'Inactivo', N'Inactive'),
    (N'usuarios.usted', N'Gestión de usuarios', N'Marca del usuario actual', N'(usted)', N'(you)'),
    (N'usuarios.btn.asignar', N'Gestión de usuarios', N'Botón asignar perfil', N'Asignar', N'Assign'),
    (N'usuarios.msg.asignado', N'Gestión de usuarios', N'Mensaje: perfil asignado', N'Perfil asignado.', N'Profile assigned.'),
    (N'usuarios.msg.error', N'Gestión de usuarios', N'Error: prefijo', N'Error', N'Error');
 INSERT INTO dbo.Etiqueta (Clave, Pantalla, Descripcion)
 SELECT s.Clave, s.Pantalla, s.Descripcion FROM @Seed s
 WHERE NOT EXISTS (SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave = s.Clave);
 INSERT INTO dbo.Traduccion (IdIdioma, IdEtiqueta, Texto)
 SELECT i.IdIdioma, e.IdEtiqueta, CASE i.Codigo WHEN N'es-AR' THEN s.Es ELSE s.En END
 FROM @Seed s
 JOIN dbo.Etiqueta e ON e.Clave = s.Clave
 JOIN dbo.Idioma i ON i.Codigo IN (N'es-AR', N'en-US')
 WHERE NOT EXISTS (SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma = i.IdIdioma AND t.IdEtiqueta = e.IdEtiqueta);
END;
GO

-- Actualización de esquema finalizada. No crea cuentas ni modifica credenciales.

-- BEGIN MigracionIdiomasCompletar.sql (mantener sincronizado con SQL/MigracionIdiomasCompletar.sql)
USE ReservaVuelosDB;
GO
-- Traducciones faltantes: aditiva, repetible y sin sobrescribir textos editados.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Textos TABLE (Clave NVARCHAR(100), Pantalla NVARCHAR(50), Descripcion NVARCHAR(500), Es NVARCHAR(500), En NVARCHAR(500));
INSERT INTO @Textos (Clave, Pantalla, Descripcion, Es, En) VALUES
 (N'validacion.perfiles.proteger', N'Validaciones', N'Protección del acceso propio', N'No se puede eliminar {0}: su propio perfil perdería el acceso a la administración de perfiles.', N'Cannot delete {0}: your own profile would lose access to profile management.'),
 (N'ui.adminvuelos.001', N'AdminVuelos', N'Administración de vuelos', N'Administración de vuelos', N'Flight management'),
 (N'ui.adminvuelos.002', N'AdminVuelos', N'Origen', N'Origen', N'Origin'),
 (N'ui.adminvuelos.003', N'AdminVuelos', N'Destino', N'Destino', N'Destination'),
 (N'ui.adminvuelos.004', N'AdminVuelos', N'Precio', N'Precio', N'Price'),
 (N'ui.adminvuelos.005', N'AdminVuelos', N'Cupos', N'Cupos', N'Available seats'),
 (N'ui.adminvuelos.006', N'AdminVuelos', N'Crear', N'Crear', N'Create'),
 (N'ui.adminvuelos.007', N'AdminVuelos', N'Confirma crear este vuelo?', N'Confirma crear este vuelo?', N'Create this flight?'),
 (N'ui.adminvuelos.008', N'AdminVuelos', N'Exportar vuelos a XML', N'Exportar vuelos a XML', N'Export flights to XML'),
 (N'ui.adminvuelos.009', N'AdminVuelos', N'Importar vuelos desde XML', N'Importar vuelos desde XML', N'Import flights from XML'),
 (N'ui.adminvuelos.010', N'AdminVuelos', N'Confirma importar los vuelos del archivo XML?', N'Confirma importar los vuelos del archivo XML?', N'Import the flights from this XML file?'),
 (N'ui.adminvuelos.011', N'AdminVuelos', N'Baja', N'Baja', N'Deactivate'),
 (N'ui.adminvuelos.012', N'AdminVuelos', N'Administración de vuelos', N'Administración de vuelos', N'Flight management'),
 (N'ui.adminvuelos.013', N'AdminVuelos', N'Crear vuelo', N'Crear vuelo', N'Create flight'),
 (N'ui.adminvuelos.014', N'AdminVuelos', N'Filtro', N'Filtro', N'Filter'),
 (N'ui.adminvuelos.015', N'AdminVuelos', N'Vuelos', N'Vuelos', N'Flights'),
 (N'ui.adminvuelos.016', N'AdminVuelos', N'Todos', N'Todos', N'All'),
 (N'ui.adminvuelos.017', N'AdminVuelos', N'Activos', N'Activos', N'Active'),
 (N'ui.adminvuelos.018', N'AdminVuelos', N'Dados de baja', N'Dados de baja', N'Deactivated'),
 (N'ui.adminvuelos.019', N'AdminVuelos', N'Id', N'Id', N'ID'),
 (N'ui.adminvuelos.020', N'AdminVuelos', N'Origen', N'Origen', N'Origin'),
 (N'ui.adminvuelos.021', N'AdminVuelos', N'Destino', N'Destino', N'Destination'),
 (N'ui.adminvuelos.022', N'AdminVuelos', N'Fecha', N'Fecha', N'Date'),
 (N'ui.adminvuelos.023', N'AdminVuelos', N'Hora', N'Hora', N'Time'),
 (N'ui.adminvuelos.024', N'AdminVuelos', N'Precio', N'Precio', N'Price'),
 (N'ui.adminvuelos.025', N'AdminVuelos', N'Cupos', N'Cupos', N'Available seats'),
 (N'ui.adminvuelos.026', N'AdminVuelos', N'Estado', N'Estado', N'Status'),
 (N'ui.backup.001', N'Backup', N'Backups', N'Backups', N'Backups'),
 (N'ui.backup.002', N'Backup', N'Los backups se almacenan en la carpeta C:\AeroLink\backups\ del equipo donde se ejecuta SQL Server', N'Los backups se almacenan en la carpeta C:\AeroLink\backups\ del equipo donde se ejecuta SQL Server', N'Backups are stored in C:\AeroLink\backups\ on the computer running SQL Server'),
 (N'ui.backup.003', N'Backup', N'Generar backup', N'Generar backup', N'Create backup'),
 (N'ui.backup.004', N'Backup', N'Confirma generar un backup de base de datos?', N'Confirma generar un backup de base de datos?', N'Create a database backup?'),
 (N'ui.backup.005', N'Backup', N'Actualizar lista', N'Actualizar lista', N'Refresh list'),
 (N'ui.backup.006', N'Backup', N'Seleccionar', N'Seleccionar', N'Select'),
 (N'ui.backup.007', N'Backup', N'Restaurar backup', N'Restaurar backup', N'Restore backup'),
 (N'ui.backup.008', N'Backup', N'Confirma restaurar el backup seleccionado? Esta acción reemplazará el estado actual de la base.', N'Confirma restaurar el backup seleccionado? Esta acción reemplazará el estado actual de la base.', N'Restore the selected backup? This will replace the current database.'),
 (N'ui.backup.009', N'Backup', N'Backups', N'Backups', N'Backups'),
 (N'ui.backup.010', N'Backup', N'Generación de backup', N'Generación de backup', N'Backup creation'),
 (N'ui.backup.011', N'Backup', N'Nombre del archivo:', N'Nombre del archivo:', N'File name:'),
 (N'ui.backup.012', N'Backup', N'Fecha y hora:', N'Fecha y hora:', N'Date and time:'),
 (N'ui.backup.013', N'Backup', N'Ruta completa:', N'Ruta completa:', N'Full path:'),
 (N'ui.backup.014', N'Backup', N'Resultado:', N'Resultado:', N'Result:'),
 (N'ui.backup.015', N'Backup', N'Mensaje:', N'Mensaje:', N'Message:'),
 (N'ui.backup.016', N'Backup', N'Restauración de backup', N'Restauración de backup', N'Backup restoration'),
 (N'ui.backup.017', N'Backup', N'Archivo seleccionado:', N'Archivo seleccionado:', N'Selected file:'),
 (N'ui.backup.018', N'Backup', N'Resultado restauración:', N'Resultado restauración:', N'Restoration result:'),
 (N'ui.backup.019', N'Backup', N'Mensaje restauración:', N'Mensaje restauración:', N'Restoration message:'),
 (N'ui.backup.020', N'Backup', N'Restaurar un backup reemplazará el estado actual de la base de datos. Los cambios posteriores a la copia seleccionada pueden perderse.', N'Restaurar un backup reemplazará el estado actual de la base de datos. Los cambios posteriores a la copia seleccionada pueden perderse.', N'Restoring a backup will replace the current database. Changes made after the selected backup may be lost.'),
 (N'ui.backup.021', N'Backup', N'La ruta mostrada corresponde al equipo donde corre SQL Server.', N'La ruta mostrada corresponde al equipo donde corre SQL Server.', N'The displayed path refers to the computer running SQL Server.'),
 (N'ui.backup.022', N'Backup', N'Nombre', N'Nombre', N'Name'),
 (N'ui.backup.023', N'Backup', N'Fecha', N'Fecha', N'Date'),
 (N'ui.backup.024', N'Backup', N'Tamaño', N'Tamaño', N'Size'),
 (N'ui.backup.025', N'Backup', N'Ruta', N'Ruta', N'Path'),
 (N'ui.backup.026', N'Backup', N'Seleccionar', N'Seleccionar', N'Select'),
 (N'ui.bitacora.001', N'Bitacora', N'Bitácora', N'Bitácora', N'Audit log'),
 (N'ui.bitacora.002', N'Bitacora', N'Filtrar', N'Filtrar', N'Filter'),
 (N'ui.bitacora.003', N'Bitacora', N'Limpiar filtros', N'Limpiar filtros', N'Clear filters'),
 (N'ui.bitacora.004', N'Bitacora', N'Bitácora', N'Bitácora', N'Audit log'),
 (N'ui.bitacora.005', N'Bitacora', N'Leyenda de criticidad: 1 = Información, 2 = Advertencia, 3 = Error, 4 = Crítica.', N'Leyenda de criticidad: 1 = Información, 2 = Advertencia, 3 = Error, 4 = Crítica.', N'Severity: 1 = Information, 2 = Warning, 3 = Error, 4 = Critical.'),
 (N'ui.bitacora.006', N'Bitacora', N'Fecha desde:', N'Fecha desde:', N'Start date:'),
 (N'ui.bitacora.007', N'Bitacora', N'Fecha hasta:', N'Fecha hasta:', N'End date:'),
 (N'ui.bitacora.008', N'Bitacora', N'Criticidad:', N'Criticidad:', N'Severity:'),
 (N'ui.bitacora.009', N'Bitacora', N'Pantalla:', N'Pantalla:', N'Page:'),
 (N'ui.bitacora.010', N'Bitacora', N'Usuario:', N'Usuario:', N'User:'),
 (N'ui.bitacora.011', N'Bitacora', N'Todas', N'Todas', N'All'),
 (N'ui.bitacora.012', N'Bitacora', N'1 - Información', N'1 - Información', N'1 - Information'),
 (N'ui.bitacora.013', N'Bitacora', N'2 - Advertencia', N'2 - Advertencia', N'2 - Warning'),
 (N'ui.bitacora.014', N'Bitacora', N'3 - Error', N'3 - Error', N'3 - Error'),
 (N'ui.bitacora.015', N'Bitacora', N'4 - Crítica', N'4 - Crítica', N'4 - Critical'),
 (N'ui.bitacora.016', N'Bitacora', N'Fecha', N'Fecha', N'Date'),
 (N'ui.bitacora.017', N'Bitacora', N'Usuario', N'Usuario', N'User'),
 (N'ui.bitacora.018', N'Bitacora', N'Acción', N'Acción', N'Action'),
 (N'ui.bitacora.019', N'Bitacora', N'Criticidad', N'Criticidad', N'Severity'),
 (N'ui.bitacora.020', N'Bitacora', N'Pantalla', N'Pantalla', N'Page'),
 (N'ui.bitacora.021', N'Bitacora', N'Fecha desde:', N'Fecha desde:', N'Start date:'),
 (N'ui.bitacora.022', N'Bitacora', N'Fecha hasta:', N'Fecha hasta:', N'End date:'),
 (N'ui.bitacora.023', N'Bitacora', N'Usuario:', N'Usuario:', N'User:'),
 (N'ui.bitacora.024', N'Bitacora', N'Criticidad:', N'Criticidad:', N'Severity:'),
 (N'ui.bitacora.025', N'Bitacora', N'Pantalla:', N'Pantalla:', N'Page:'),
 (N'ui.gestionintegridad.001', N'GestionIntegridad', N'Gestión de Integridad', N'Gestión de Integridad', N'Integrity management'),
 (N'ui.gestionintegridad.002', N'GestionIntegridad', N'Volver a validar', N'Volver a validar', N'Validate again'),
 (N'ui.gestionintegridad.003', N'GestionIntegridad', N'Validar y salir de contingencia', N'Validar y salir de contingencia', N'Validate and exit contingency mode'),
 (N'ui.gestionintegridad.004', N'GestionIntegridad', N'Recalcular DVH/DVV', N'Recalcular DVH/DVV', N'Recalculate DVH/DVV'),
 (N'ui.gestionintegridad.005', N'GestionIntegridad', N'Recalcular los dígitos verificadores aceptará como válido el estado actual de los datos. Utilice esta opción únicamente después de revisar y corregir la causa de la inconsistencia. ¿Confirma el recálculo?', N'Recalcular los dígitos verificadores aceptará como válido el estado actual de los datos. Utilice esta opción únicamente después de revisar y corregir la causa de la inconsistencia. ¿Confirma el recálculo?', N'Recalculating check digits will accept the current data as valid. Use this option only after reviewing and fixing the inconsistency. Confirm recalculation?'),
 (N'ui.gestionintegridad.006', N'GestionIntegridad', N'Gestión de Integridad', N'Gestión de Integridad', N'Integrity management'),
 (N'ui.gestionintegridad.007', N'GestionIntegridad', N'Modo contingencia:', N'Modo contingencia:', N'Contingency mode:'),
 (N'ui.gestionintegridad.008', N'GestionIntegridad', N'Última validación:', N'Última validación:', N'Last validation:'),
 (N'ui.gestionintegridad.009', N'GestionIntegridad', N'Motivo:', N'Motivo:', N'Reason:'),
 (N'ui.gestionintegridad.010', N'GestionIntegridad', N'Backups', N'Backups', N'Backups'),
 (N'ui.gestionintegridad.011', N'GestionIntegridad', N'Bitácora', N'Bitácora', N'Audit log'),
 (N'ui.gestionintegridad.012', N'GestionIntegridad', N'Operacion', N'Operacion', N'Operation'),
 (N'ui.gestionintegridad.013', N'GestionIntegridad', N'Falla', N'Falla', N'Failure'),
 (N'ui.gestionintegridad.014', N'GestionIntegridad', N'Tabla', N'Tabla', N'Table'),
 (N'ui.gestionintegridad.015', N'GestionIntegridad', N'Registro', N'Registro', N'Record'),
 (N'ui.registro.001', N'Registro', N'Registro', N'Registro', N'Registration'),
 (N'ui.registro.002', N'Registro', N'Nombre', N'Nombre', N'Name'),
 (N'ui.registro.003', N'Registro', N'Email', N'Email', N'Email'),
 (N'ui.registro.004', N'Registro', N'Contraseña', N'Contraseña', N'Password'),
 (N'ui.registro.005', N'Registro', N'Registrarme', N'Registrarme', N'Register'),
 (N'ui.registro.006', N'Registro', N'Confirma crear este usuario?', N'Confirma crear este usuario?', N'Create this user?'),
 (N'ui.registro.007', N'Registro', N'Registro', N'Registro', N'Registration'),
 (N'ui.registro.008', N'Registro', N'Mostrar Contraseña', N'Mostrar Contraseña', N'Show password'),
 (N'ui.registro.009', N'Registro', N'Mostrar Contraseña', N'Mostrar Contraseña', N'Show password'),
 (N'ui.mantenimiento.001', N'Mantenimiento', N'Mantenimiento', N'Mantenimiento', N'Maintenance'),
 (N'ui.mantenimiento.002', N'Mantenimiento', N'Mantenimiento', N'Mantenimiento', N'Maintenance'),
 (N'ui.mantenimiento.003', N'Mantenimiento', N'La aplicación se encuentra temporalmente en mantenimiento debido a una verificación de integridad. Comuníquese con el WebMaster.', N'La aplicación se encuentra temporalmente en mantenimiento debido a una verificación de integridad. Comuníquese con el WebMaster.', N'The application is temporarily under maintenance due to an integrity check. Please contact the WebMaster.'),
 (N'ui.enconstruccion.001', N'EnConstruccion', N'Proximamente', N'Proximamente', N'Coming soon'),
 (N'ui.enconstruccion.002', N'EnConstruccion', N'POR ARGENTINA', N'POR ARGENTINA', N'ACROSS ARGENTINA'),
 (N'ui.enconstruccion.003', N'EnConstruccion', N'Página en construcción', N'Página en construcción', N'Page under construction'),
 (N'ui.enconstruccion.004', N'EnConstruccion', N'Esta sección todavía no está disponible. Estamos trabajando para tenerla lista pronto.', N'Esta sección todavía no está disponible. Estamos trabajando para tenerla lista pronto.', N'This section is not available yet. We are working to make it available soon.'),
 (N'ui.enconstruccion.005', N'EnConstruccion', N'VOLVER A BUSCAR VUELOS', N'VOLVER A BUSCAR VUELOS', N'BACK TO FLIGHT SEARCH'),
 (N'ui.enconstruccion.006', N'EnConstruccion', N'VOLA EN CUOTAS', N'VOLA EN CUOTAS', N'FLY IN INSTALLMENTS'),
 (N'ui.enconstruccion.007', N'EnConstruccion', N'VOLA EN CUOTAS', N'VOLA EN CUOTAS', N'FLY IN INSTALLMENTS'),
 (N'ui.default.001', N'Default', N'Inicio', N'Inicio', N'Home'),
 (N'ui.default.002', N'Default', N'Bienvenido al Sistema de Reserva de Vuelos', N'Bienvenido al Sistema de Reserva de Vuelos', N'Welcome to the Flight Reservation System'),
 (N'ui.default.003', N'Default', N'Esta aplicación académica permite buscar vuelos, registrarse, reservar y administrar vuelos según permisos.', N'Esta aplicación académica permite buscar vuelos, registrarse, reservar y administrar vuelos según permisos.', N'This academic application lets you search flights, register, book and manage flights according to your permissions.'),
 (N'ui.default.004', N'Default', N'Buscar vuelos', N'Buscar vuelos', N'Search flights'),
 (N'ui.about.001', N'About', N'Acerca de', N'Acerca de', N'About'),
 (N'ui.about.002', N'About', N'Acerca de', N'Acerca de', N'About'),
 (N'ui.about.003', N'About', N'Descripción de la aplicación.', N'Descripción de la aplicación.', N'Application description.'),
 (N'ui.about.004', N'About', N'Sistema académico para buscar vuelos y gestionar reservas.', N'Sistema académico para buscar vuelos y gestionar reservas.', N'Academic system for searching flights and managing reservations.'),
 (N'ui.contact.001', N'Contact', N'Contacto', N'Contacto', N'Contact'),
 (N'ui.contact.002', N'Contact', N'Contacto', N'Contacto', N'Contact'),
 (N'ui.contact.003', N'Contact', N'Información de contacto.', N'Información de contacto.', N'Contact information.'),
 (N'ui.contact.004', N'Contact', N'Soporte:', N'Soporte:', N'Support:'),
 (N'ui.contact.005', N'Contact', N'Marketing:', N'Marketing:', N'Marketing:'),
 (N'ui.logout.001', N'Logout', N'Logout', N'Logout', N'Sign out'),
 (N'ui.logout.002', N'Logout', N'Logout', N'Logout', N'Sign out'),
 (N'ui.adminvuelos.msg027', N'AdminVuelos', N'Vuelo dado de baja correctamente.', N'Vuelo dado de baja correctamente.', N'Flight deactivated successfully.'),
 (N'ui.adminvuelos.msg028', N'AdminVuelos', N' Reservas canceladas: ', N' Reservas canceladas: ', N' Reservations cancelled: '),
 (N'ui.adminvuelos.msg029', N'AdminVuelos', N'No se encontró el vuelo.', N'No se encontró el vuelo.', N'Flight not found.'),
 (N'ui.adminvuelos.msg030', N'AdminVuelos', N'Error: ', N'Error: ', N'Error: '),
 (N'ui.adminvuelos.msg031', N'AdminVuelos', N'Vuelo creado.', N'Vuelo creado.', N'Flight created.'),
 (N'ui.adminvuelos.msg032', N'AdminVuelos', N'Cierre sesión y vuelva a ingresar para usar el web service.', N'Cierre sesión y vuelva a ingresar para usar el web service.', N'Sign out and sign in again to use the web service.'),
 (N'ui.adminvuelos.msg033', N'AdminVuelos', N'Error al exportar: ', N'Error al exportar: ', N'Export failed: '),
 (N'ui.adminvuelos.msg034', N'AdminVuelos', N'Seleccione un archivo XML.', N'Seleccione un archivo XML.', N'Select an XML file.'),
 (N'ui.adminvuelos.msg035', N'AdminVuelos', N'El archivo supera el máximo de ', N'El archivo supera el máximo de ', N'The file exceeds the maximum size of '),
 (N'ui.adminvuelos.msg036', N'AdminVuelos', N'Error al importar: ', N'Error al importar: ', N'Import failed: '),
 (N'ui.adminvuelos.importacion.resumen', N'AdminVuelos', N'Vuelos en el archivo: {0}. Importados: {1}. Rechazados: {2}.', N'Vuelos en el archivo: {0}. Importados: {1}. Rechazados: {2}.', N'Flights in file: {0}. Imported: {1}. Rejected: {2}.'),
 (N'ui.backup.msg027', N'Backup', N'No se pudo crear/verificar la carpeta en SQL Server. ', N'No se pudo crear/verificar la carpeta en SQL Server. ', N'Could not create or check the folder on SQL Server. '),
 (N'ui.backup.msg028', N'Backup', N'Error al generar backup. ', N'Error al generar backup. ', N'Backup creation failed. '),
 (N'ui.backup.msg029', N'Backup', N'Backup generado, pero no se pudo verificar con RESTORE VERIFYONLY. ', N'Backup generado, pero no se pudo verificar con RESTORE VERIFYONLY. ', N'Backup created, but verification with RESTORE VERIFYONLY failed. '),
 (N'ui.backup.msg030', N'Backup', N'Backup generado y verificado correctamente.', N'Backup generado y verificado correctamente.', N'Backup created and verified successfully.'),
 (N'ui.backup.msg031', N'Backup', N'Backup generado con advertencias de permisos/configuración.', N'Backup generado con advertencias de permisos/configuración.', N'Backup created with permission or configuration warnings.'),
 (N'ui.backup.msg032', N'Backup', N'No se pudo generar el backup.', N'No se pudo generar el backup.', N'Could not create the backup.'),
 (N'ui.backup.msg033', N'Backup', N'Error inesperado al ejecutar backup. ', N'Error inesperado al ejecutar backup. ', N'Unexpected backup error. '),
 (N'ui.backup.msg034', N'Backup', N'Éxito', N'Éxito', N'Success'),
 (N'ui.backup.msg035', N'Backup', N'Advertencia', N'Advertencia', N'Warning'),
 (N'ui.backup.msg036', N'Backup', N'Error', N'Error', N'Error'),
 (N'ui.backup.msg037', N'Backup', N'Restauración completada correctamente con el archivo ', N'Restauración completada correctamente con el archivo ', N'Restoration completed successfully using file '),
 (N'ui.backup.msg038', N'Backup', N'Backup restaurado, pero persisten inconsistencias de integridad. El modo de contingencia permanece activo.', N'Backup restaurado, pero persisten inconsistencias de integridad. El modo de contingencia permanece activo.', N'Backup restored, but integrity inconsistencies remain. Contingency mode is still active.'),
 (N'ui.backup.msg039', N'Backup', N'Error al restaurar backup. ', N'Error al restaurar backup. ', N'Backup restoration failed. '),
 (N'ui.backup.msg040', N'Backup', N'Advertencia: no se pudo asegurar MULTI_USER. ', N'Advertencia: no se pudo asegurar MULTI_USER. ', N'Warning: could not ensure MULTI_USER mode. '),
 (N'ui.backup.msg041', N'Backup', N'No se pudo leer la carpeta de backups: ', N'No se pudo leer la carpeta de backups: ', N'Could not read the backup folder: '),
 (N'ui.backup.msg042', N'Backup', N'Debe seleccionar un archivo de backup de la lista.', N'Debe seleccionar un archivo de backup de la lista.', N'Select a backup file from the list.'),
 (N'ui.backup.msg043', N'Backup', N'Ruta inválida.', N'Ruta inválida.', N'Invalid path.'),
 (N'ui.backup.msg044', N'Backup', N'No se permite usar rutas externas a la carpeta de backups.', N'No se permite usar rutas externas a la carpeta de backups.', N'Paths outside the backup folder are not allowed.'),
 (N'ui.backup.msg045', N'Backup', N'El archivo seleccionado no es un .bak válido.', N'El archivo seleccionado no es un .bak válido.', N'The selected file is not a valid .bak file.'),
 (N'ui.backup.msg046', N'Backup', N'El archivo seleccionado no existe.', N'El archivo seleccionado no existe.', N'The selected file does not exist.'),
 (N'ui.gestionintegridad.msg016', N'GestionIntegridad', N'Validación correcta.', N'Validación correcta.', N'Validation successful.'),
 (N'ui.gestionintegridad.msg017', N'GestionIntegridad', N'Se detectaron inconsistencias. El modo de contingencia permanece activo.', N'Se detectaron inconsistencias. El modo de contingencia permanece activo.', N'Inconsistencies detected. Contingency mode is still active.'),
 (N'ui.gestionintegridad.msg018', N'GestionIntegridad', N'Integridad validada. Modo contingencia desactivado.', N'Integridad validada. Modo contingencia desactivado.', N'Integrity validated. Contingency mode disabled.'),
 (N'ui.gestionintegridad.msg019', N'GestionIntegridad', N'Persisten inconsistencias. No se puede salir de contingencia.', N'Persisten inconsistencias. No se puede salir de contingencia.', N'Inconsistencies remain. Cannot exit contingency mode.'),
 (N'ui.gestionintegridad.msg020', N'GestionIntegridad', N'Recalculo finalizado y validado.', N'Recalculo finalizado y validado.', N'Recalculation completed and validated.'),
 (N'ui.gestionintegridad.msg021', N'GestionIntegridad', N'No se pudo recalcular la integridad: ', N'No se pudo recalcular la integridad: ', N'Could not recalculate integrity: '),
 (N'ui.gestionintegridad.msg022', N'GestionIntegridad', N'Activo', N'Activo', N'Active'),
 (N'ui.gestionintegridad.msg023', N'GestionIntegridad', N'Inactivo', N'Inactivo', N'Inactive'),
 (N'ui.registro.msg010', N'Registro', N'Usuario creado correctamente. Inicie sesión.', N'Usuario creado correctamente. Inicie sesión.', N'User created successfully. Please sign in.'),
 (N'ui.registro.msg011', N'Registro', N'Error al registrar: ', N'Error al registrar: ', N'Registration failed: '),
 (N'ui.vuelos.estado.activo', N'AdminVuelos', N'Activo', N'Activo', N'Active'),
 (N'ui.vuelos.estado.baja', N'AdminVuelos', N'Dado de baja', N'Dado de baja', N'Deactivated'),
 (N'validacion.password.5', N'Validaciones', N'La contraseña debe contener al menos un carácter especial.', N'La contraseña debe contener al menos un carácter especial.', N'The password must contain at least one special character.'),
 (N'validacion.password.4', N'Validaciones', N'La contraseña debe contener al menos un número.', N'La contraseña debe contener al menos un número.', N'The password must contain at least one number.'),
 (N'validacion.password.3', N'Validaciones', N'La contraseña debe contener al menos una letra minúscula.', N'La contraseña debe contener al menos una letra minúscula.', N'The password must contain at least one lowercase letter.'),
 (N'validacion.password.2', N'Validaciones', N'La contraseña debe contener al menos una letra mayúscula.', N'La contraseña debe contener al menos una letra mayúscula.', N'The password must contain at least one uppercase letter.'),
 (N'validacion.password.1', N'Validaciones', N'La contraseña debe tener al menos 8 caracteres.', N'La contraseña debe tener al menos 8 caracteres.', N'The password must contain at least 8 characters.'),
 (N'validacion.general.001', N'Validaciones', N'El vuelo es requerido.', N'El vuelo es requerido.', N'A flight is required.'),
 (N'validacion.general.002', N'Validaciones', N'El origen del vuelo es requerido.', N'El origen del vuelo es requerido.', N'Flight origin is required.'),
 (N'validacion.general.003', N'Validaciones', N'El destino del vuelo es requerido.', N'El destino del vuelo es requerido.', N'Flight destination is required.'),
 (N'validacion.general.004', N'Validaciones', N'El origen y destino del vuelo deben ser diferentes.', N'El origen y destino del vuelo deben ser diferentes.', N'Flight origin and destination must be different.'),
 (N'validacion.general.005', N'Validaciones', N'El precio del vuelo no puede ser negativo.', N'El precio del vuelo no puede ser negativo.', N'Flight price cannot be negative.'),
 (N'validacion.general.006', N'Validaciones', N'Los cupos disponibles no pueden ser negativos.', N'Los cupos disponibles no pueden ser negativos.', N'Available seats cannot be negative.'),
 (N'validacion.general.007', N'Validaciones', N'No se pueden crear vuelos con fecha y hora pasada.', N'No se pueden crear vuelos con fecha y hora pasada.', N'Cannot create flights with a departure date and time in the past.'),
 (N'validacion.general.008', N'Validaciones', N'El cliente es inválido.', N'El cliente es inválido.', N'Invalid customer.'),
 (N'validacion.general.009', N'Validaciones', N'El cliente es requerido.', N'El cliente es requerido.', N'A customer is required.'),
 (N'validacion.general.010', N'Validaciones', N'El nombre del cliente es requerido.', N'El nombre del cliente es requerido.', N'Customer name is required.'),
 (N'validacion.general.011', N'Validaciones', N'El email del cliente es requerido.', N'El email del cliente es requerido.', N'Customer email is required.'),
 (N'validacion.general.012', N'Validaciones', N'El pasajero es inválido.', N'El pasajero es inválido.', N'Invalid passenger.'),
 (N'validacion.general.013', N'Validaciones', N'El pasajero es requerido.', N'El pasajero es requerido.', N'A passenger is required.'),
 (N'validacion.general.014', N'Validaciones', N'El nombre del pasajero es requerido.', N'El nombre del pasajero es requerido.', N'Passenger name is required.'),
 (N'validacion.general.015', N'Validaciones', N'El documento del pasajero es requerido.', N'El documento del pasajero es requerido.', N'Passenger document number is required.'),
 (N'validacion.general.016', N'Validaciones', N'Sólo puede crear reservas para su propio cliente.', N'Sólo puede crear reservas para su propio cliente.', N'You can only create reservations for your own customer.'),
 (N'validacion.general.017', N'Validaciones', N'El ID del cliente es requerido.', N'El ID del cliente es requerido.', N'Customer ID is required.'),
 (N'validacion.general.018', N'Validaciones', N'Debe seleccionar al menos un vuelo.', N'Debe seleccionar al menos un vuelo.', N'Select at least one flight.'),
 (N'validacion.general.019', N'Validaciones', N'Debe registrar al menos un pasajero.', N'Debe registrar al menos un pasajero.', N'Register at least one passenger.'),
 (N'validacion.general.020', N'Validaciones', N'El usuario actual es requerido.', N'El usuario actual es requerido.', N'The current user is required.'),
 (N'validacion.general.021', N'Validaciones', N'La cantidad de pasajeros debe ser mayor o igual a 1.', N'La cantidad de pasajeros debe ser mayor o igual a 1.', N'The number of passengers must be at least 1.'),
 (N'validacion.general.022', N'Validaciones', N'La cantidad de pasajeros de la reserva no coincide con los pasajeros cargados.', N'La cantidad de pasajeros de la reserva no coincide con los pasajeros cargados.', N'The reservation passenger count does not match the registered passengers.'),
 (N'validacion.general.023', N'Validaciones', N'El precio unitario no puede ser negativo.', N'El precio unitario no puede ser negativo.', N'Unit price cannot be negative.'),
 (N'validacion.general.024', N'Validaciones', N'El subtotal de la reserva es inválido.', N'El subtotal de la reserva es inválido.', N'Invalid reservation subtotal.'),
 (N'validacion.general.025', N'Validaciones', N'Usuario inválido para cancelar la reserva.', N'Usuario inválido para cancelar la reserva.', N'Invalid user for cancelling the reservation.'),
 (N'validacion.general.026', N'Validaciones', N'Ingrese el nombre del perfil.', N'Ingrese el nombre del perfil.', N'Enter a profile name.'),
 (N'validacion.general.027', N'Validaciones', N'El nombre del perfil admite hasta {0} caracteres.', N'El nombre del perfil admite hasta {0} caracteres.', N'Profile names can contain up to {0} characters.'),
 (N'validacion.general.028', N'Validaciones', N'El nombre del perfil sólo admite letras, números, espacios, guiones y guiones bajos.', N'El nombre del perfil sólo admite letras, números, espacios, guiones y guiones bajos.', N'Profile names may contain only letters, numbers, spaces, hyphens and underscores.'),
 (N'validacion.general.029', N'Validaciones', N'Ya existe un perfil o permiso con ese nombre.', N'Ya existe un perfil o permiso con ese nombre.', N'A profile or permission with that name already exists.'),
 (N'validacion.general.030', N'Validaciones', N'El permiso seleccionado no existe.', N'El permiso seleccionado no existe.', N'The selected permission does not exist.'),
 (N'validacion.general.031', N'Validaciones', N'No se puede agregar {0} a {1} porque ya lo contiene (se formaría un ciclo).', N'No se puede agregar {0} a {1} porque ya lo contiene (se formaría un ciclo).', N'Cannot add {0} to {1} because it already contains it (this would create a cycle).'),
 (N'validacion.general.032', N'Validaciones', N'{0} ya tiene asignado {1}.', N'{0} ya tiene asignado {1}.', N'{0} already has {1} assigned.'),
 (N'validacion.general.033', N'Validaciones', N'No se puede agregar {0} a {1} porque se formaría un ciclo.', N'No se puede agregar {0} a {1} porque se formaría un ciclo.', N'Cannot add {0} to {1} because this would create a cycle.'),
 (N'validacion.general.034', N'Validaciones', N'Un permiso simple no puede contener otros permisos.', N'Un permiso simple no puede contener otros permisos.', N'A simple permission cannot contain other permissions.'),
 (N'validacion.general.035', N'Validaciones', N'El permiso no está asignado a {0}.', N'El permiso no está asignado a {0}.', N'The permission is not assigned to {0}.'),
 (N'validacion.general.036', N'Validaciones', N'No se puede quitar {0} de {1}: su propio perfil perdería el acceso a la administración de perfiles.', N'No se puede quitar {0} de {1}: su propio perfil perdería el acceso a la administración de perfiles.', N'Cannot remove {0} from {1}: your own profile would lose access to profile management.'),
 (N'validacion.general.037', N'Validaciones', N'No se puede eliminar {0}: está asignado a {1} usuario(s).', N'No se puede eliminar {0}: está asignado a {1} usuario(s).', N'Cannot delete {0}: it is assigned to {1} user(s).'),
 (N'validacion.general.038', N'Validaciones', N'No se puede eliminar {0}: está asignado a usuarios.', N'No se puede eliminar {0}: está asignado a usuarios.', N'Cannot delete {0}: it is assigned to users.'),
 (N'validacion.general.039', N'Validaciones', N'El perfil seleccionado no existe.', N'El perfil seleccionado no existe.', N'The selected profile does not exist.'),
 (N'validacion.general.040', N'Validaciones', N'Debe iniciar sesión.', N'Debe iniciar sesión.', N'Please sign in.'),
 (N'validacion.general.041', N'Validaciones', N'No puede cambiar su propio rol.', N'No puede cambiar su propio rol.', N'You cannot change your own role.'),
 (N'validacion.general.042', N'Validaciones', N'El usuario no existe.', N'El usuario no existe.', N'The user does not exist.'),
 (N'validacion.general.043', N'Validaciones', N'{0} ya tiene el rol {1}.', N'{0} ya tiene el rol {1}.', N'{0} already has the role {1}.'),
 (N'validacion.general.044', N'Validaciones', N'El usuario fue modificado mientras tanto. Vuelva a cargar la lista e intente de nuevo.', N'El usuario fue modificado mientras tanto. Vuelva a cargar la lista e intente de nuevo.', N'The user has changed. Refresh the list and try again.'),
 (N'validacion.general.045', N'Validaciones', N'Usuario o contraseña incorrectos.', N'Usuario o contraseña incorrectos.', N'Incorrect email or password.'),
 (N'validacion.general.046', N'Validaciones', N'Indique al menos un vuelo.', N'Indique al menos un vuelo.', N'Select at least one flight.'),
 (N'validacion.general.047', N'Validaciones', N'La cantidad de pasajeros debe ser mayor a cero.', N'La cantidad de pasajeros debe ser mayor a cero.', N'The number of passengers must be greater than zero.'),
 (N'validacion.general.048', N'Validaciones', N'No existe el vuelo {0}.', N'No existe el vuelo {0}.', N'Flight {0} does not exist.'),
 (N'validacion.general.049', N'Validaciones', N'El vuelo {0} está dado de baja.', N'El vuelo {0} está dado de baja.', N'Flight {0} is deactivated.'),
 (N'validacion.general.050', N'Validaciones', N'El XML está vacío.', N'El XML está vacío.', N'The XML file is empty.'),
 (N'validacion.general.051', N'Validaciones', N'El XML supera el máximo de {0} KB.', N'El XML supera el máximo de {0} KB.', N'The XML exceeds the maximum size of {0} KB.'),
 (N'validacion.general.052', N'Validaciones', N'El elemento raíz debe ser <vuelos>.', N'El elemento raíz debe ser <vuelos>.', N'The root element must be <vuelos>.'),
 (N'validacion.general.053', N'Validaciones', N'Hay un dato con formato inválido (fecha yyyy-MM-dd, hora HH:mm, precio y cupos numéricos).', N'Hay un dato con formato inválido (fecha yyyy-MM-dd, hora HH:mm, precio y cupos numéricos).', N'Invalid data format (date yyyy-MM-dd, time HH:mm, numeric price and seat count).'),
 (N'validacion.general.054', N'Validaciones', N'Falta el campo <{0}>.', N'Falta el campo <{0}>.', N'Missing field <{0}>.'),
 (N'validacion.general.055', N'Validaciones', N'Vuelo {0}: {1}', N'Vuelo {0}: {1}', N'Flight {0}: {1}'),
 (N'validacion.general.056', N'Validaciones', N'El archivo no es un XML válido: {0}', N'El archivo no es un XML válido: {0}', N'The file is not valid XML: {0}'),
 (N'validacion.general.057', N'Validaciones', N'Token inválido o vencido. Inicie sesión nuevamente.', N'Token inválido o vencido. Inicie sesión nuevamente.', N'Invalid or expired token. Please sign in again.'),
 (N'validacion.general.058', N'Validaciones', N'No tiene permiso para esta operación.', N'No tiene permiso para esta operación.', N'You do not have permission for this operation.'),
 (N'validacion.general.059', N'Validaciones', N'Operación no disponible durante contingencia.', N'Operación no disponible durante contingencia.', N'This operation is unavailable in contingency mode.'),
 (N'ui.bitacora.criticidad.1', N'Bitacora', N'1 - Información', N'1 - Información', N'1 - Information'),
 (N'ui.bitacora.criticidad.2', N'Bitacora', N'2 - Advertencia', N'2 - Advertencia', N'2 - Warning'),
 (N'ui.bitacora.criticidad.3', N'Bitacora', N'3 - Error', N'3 - Error', N'3 - Error'),
 (N'ui.bitacora.criticidad.4', N'Bitacora', N'4 - Crítica', N'4 - Crítica', N'4 - Critical');
INSERT dbo.Etiqueta (Clave, Pantalla, Descripcion)
SELECT s.Clave, s.Pantalla, LEFT(s.Descripcion, 200) FROM @Textos s
WHERE NOT EXISTS (SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave = s.Clave);
INSERT dbo.Traduccion (IdIdioma, IdEtiqueta, Texto)
SELECT i.IdIdioma, e.IdEtiqueta, CASE i.Codigo WHEN N'es-AR' THEN s.Es ELSE s.En END
FROM @Textos s JOIN dbo.Etiqueta e ON e.Clave = s.Clave
JOIN dbo.Idioma i ON i.Codigo IN (N'es-AR', N'en-US')
WHERE NOT EXISTS (SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma = i.IdIdioma AND t.IdEtiqueta = e.IdEtiqueta);
COMMIT;
GO
-- END MigracionIdiomasCompletar.sql

-- BEGIN MigracionGrillasIntegridad.sql
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
-- END MigracionGrillasIntegridad.sql

-- BEGIN ActivarTDE.sql
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
-- END ActivarTDE.sql
