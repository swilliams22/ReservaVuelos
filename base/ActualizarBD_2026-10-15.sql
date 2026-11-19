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
