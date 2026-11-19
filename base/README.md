# Actualización de base de datos

Para actualizar una instalación existente con las tablas de integridad:

```powershell
sqlcmd -S . -E -b -f 65001 -i base/ActualizarBD_2026-10-15.sql
```

El script agrega el rol WebMaster al CHECK de roles y las tablas, relaciones y
validaciones de permisos Composite, y los perfiles administrables
(permisos `Perfiles.*` y `Usuarios.*`, y validación del rol por trigger).
Es idempotente y conserva los usuarios,
contraseñas, reservas y permisos configurados. No crea cuentas ni contiene sus
credenciales. Publicar también el código actualizado para activar la autorización
por permisos y la búsqueda sin distinguir tildes.

No ejecutar `ReservaVuelos/SQL/ReservaVuelos.sql` para actualizar una base con datos:
ese archivo elimina y recrea la base. Ajustar la instancia en el comando y en
`Web.config`; la base destino del script se llama `ReservaVuelosDB`.

El backup de esta entrega, su SHA-256, `INFO_ENTREGA.md` y la migración completa
con el alta inicial se conservan sólo en el equipo local y están excluidos de Git.
Las instrucciones de restauración y los accesos están en ese archivo local.

El script de actualización incluye las traducciones de administración, backups, bitácora, integridad, registro y páginas informativas. Para actualizar únicamente esos textos, ejecutar `ReservaVuelos/SQL/MigracionIdiomasCompletar.sql`. Ambas opciones conservan las traducciones ya editadas. Reiniciar la aplicación o esperar hasta dos minutos para que venza la caché de traducciones.

La actualización incluye `MigracionGrillasIntegridad.sql`: filtros traducibles y DVH/DVV para idiomas, etiquetas, traducciones, perfiles, relaciones, configuración y errores. Publicar el código actualizado junto con la migración. No recalcula referencias existentes ni recrea la base.

## Cifrado automático para la presentación

Desde la raíz del proyecto, ejecutar:

```powershell
.\base\Activar-Cifrado.ps1
```

Usa SQL Server local e inicio de sesión integrado de Windows. Para otra instancia: `-Servidor '.\SQLEXPRESS'` (la edición debe admitir TDE). El comando genera contraseñas aleatorias, las guarda protegidas con DPAPI en `base/local/tde/` (excluido de Git), respalda certificado y clave privada en la carpeta de backups de SQL Server, activa AES-256 y espera hasta confirmar `Estado=3`. Se puede repetir; si ya está cifrada, verifica el estado sin recrear la base ni cambiar sus claves. Después de recrear la base, ejecutar nuevamente este comando.

Los archivos JSON locales indican las rutas de los respaldos y contienen las contraseñas protegidas. Sólo el usuario de Windows que los generó puede descifrarlas con DPAPI en este equipo. Para una recuperación en otro equipo se necesita el certificado, la clave privada y la contraseña de ese respaldo recuperada antes desde el equipo original; copiar sólo el JSON no alcanza. Conservar una copia de recuperación segura fuera de este equipo. `ClaveMaestraCreadaPorEsteProceso=false` indica que la clave maestra ya existía y la contraseña generada no corresponde a ella.

El script devuelve error si la edición no es compatible, falta la base, no puede respaldar la clave o se agota la espera. En este último caso SQL Server puede continuar cifrando: volver a ejecutar consulta el estado hasta finalizar. No hay contraseñas en el código ni en los argumentos del proceso.

## Cifrado TDE opcional

`ReservaVuelos/SQL/ActivarTDE.sql` está incluido al final de los scripts de instalación y actualización. Por defecto se omite: requiere habilitación explícita en la misma conexión. Para una base existente, ejecutar únicamente `ActivarTDE.sql`; no recrear la base para cifrarla.

La instancia local verificada es SQL Server 2022 Developer. TDE cifra archivos de datos y registro en reposo, no oculta los valores a quien tiene permiso para consultar la base ni cifra la conexión de red. Se conserva el cifrado por campos existente.

En SSMS, con permisos de administración, configurar estos valores en una ventana y ejecutar después el contenido de `ActivarTDE.sql` en esa misma ventana. Reemplazar las contraseñas de ejemplo y no guardar el texto resultante en Git:

```sql
EXEC sys.sp_set_session_context @key=N'ReservaVuelos.ActivarTDE', @value=1;
EXEC sys.sp_set_session_context @key=N'ReservaVuelos.ClaveMaestraTDE', @value=N'REEMPLAZAR_CON_UNA_CONTRASEÑA_PROPIA';
EXEC sys.sp_set_session_context @key=N'ReservaVuelos.ClaveRespaldoTDE', @value=N'REEMPLAZAR_CON_OTRA_CONTRASEÑA_PROPIA';
EXEC sys.sp_set_session_context @key=N'ReservaVuelos.RutaCertificadoTDE', @value=N'C:\AeroLink\backups\CertificadoTDE_ReservaVuelos.cer';
EXEC sys.sp_set_session_context @key=N'ReservaVuelos.RutaPrivadaTDE', @value=N'C:\AeroLink\backups\CertificadoTDE_ReservaVuelos.pvk';
```

Las rutas corresponden al servidor SQL: la carpeta debe existir y la cuenta del servicio debe poder escribir en ella. El respaldo no sobrescribe archivos. Guardar el certificado, la clave privada cifrada y su contraseña en una ubicación segura fuera del servidor; se necesitan para restaurar backups cifrados en otra instancia. El script exige respaldar la clave privada antes de activar el cifrado y no cambia una DEK existente que use otro certificado o algoritmo.

La ejecución muestra `Estado=2` mientras cifra y `Estado=3` cuando termina. El proceso es asíncrono; consultar nuevamente `sys.dm_database_encryption_keys` para confirmar su finalización. Una vez configurados los secretos, cerrar la conexión elimina los valores de SESSION_CONTEXT.

Referencia: https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption
