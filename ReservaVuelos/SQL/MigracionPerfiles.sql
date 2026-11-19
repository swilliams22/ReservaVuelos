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
