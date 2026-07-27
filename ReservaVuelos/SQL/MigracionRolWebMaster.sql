USE ReservaVuelosDB;
GO

/*
Agrega WebMaster a una base ya creada.
Este script no elige qué usuario promover: reemplazar el email de ejemplo
por el usuario técnico que corresponda.
*/

IF EXISTS
(
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Usuarios_Rol'
      AND parent_object_id = OBJECT_ID(N'dbo.Usuarios')
)
BEGIN
    ALTER TABLE dbo.Usuarios DROP CONSTRAINT CK_Usuarios_Rol;
END;
GO

ALTER TABLE dbo.Usuarios WITH CHECK
ADD CONSTRAINT CK_Usuarios_Rol
CHECK (Rol IN (N'Administrador', N'WebMaster', N'Usuario'));
GO

ALTER TABLE dbo.Usuarios CHECK CONSTRAINT CK_Usuarios_Rol;
GO

-- Descomentar, indicar el email real y ejecutar para promover un usuario:
-- UPDATE dbo.Usuarios
-- SET Rol = N'WebMaster'
-- WHERE Email = N'webmaster@aerolink.com';
-- GO

/*
IMPORTANTE:
Usuarios es una tabla protegida. Cambiar el rol directamente por SQL hará que
el control detecte un UPDATE, que es el comportamiento esperado.

Después de promover el usuario:
1. Iniciar sesión con ese usuario WebMaster.
2. Entrar a Gestión de Integridad.
3. Ejecutar "Recalcular DVH/DVV".

No se debe recalcular el DVH manualmente por SQL.
*/
