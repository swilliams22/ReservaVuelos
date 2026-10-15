# Actualización de base de datos

Para actualizar una instalación existente con las tablas de integridad:

```powershell
sqlcmd -S . -E -b -f 65001 -i base/ActualizarBD_2026-10-15.sql
```

El script agrega el rol WebMaster al CHECK de roles y las tablas, relaciones y
validaciones de permisos Composite. Es idempotente y conserva los usuarios,
contraseñas, reservas y permisos configurados. No crea cuentas ni contiene sus
credenciales. Publicar también el código actualizado para activar la autorización
por permisos y la búsqueda sin distinguir tildes.

No ejecutar `ReservaVuelos/SQL/ReservaVuelos.sql` para actualizar una base con datos:
ese archivo elimina y recrea la base. Ajustar la instancia en el comando y en
`Web.config`; la base destino del script se llama `ReservaVuelosDB`.

El backup de esta entrega, su SHA-256, `INFO_ENTREGA.md` y la migración completa
con el alta inicial se conservan sólo en el equipo local y están excluidos de Git.
Las instrucciones de restauración y los accesos están en ese archivo local.
