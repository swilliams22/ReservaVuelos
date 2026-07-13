# Guia rapida para presentar y navegar el codigo

Objetivo: tener un mapa para responder rapido preguntas del tipo "donde validan esto?", "como se reserva?", "donde se calculan los digitos verificadores?", "que pasa si falla integridad?", "como vuelve a validar?".

Tip de uso en Visual Studio: abrir el archivo indicado y usar `Ctrl+G` para ir a la linea, o `Ctrl+F` con el nombre del metodo.

## Arquitectura en una frase

La app esta separada en:

- `BE`: entidades simples del negocio, por ejemplo `Usuario`, `Vuelo`, `ReservaCabecera`, `Pasajero`.
- `BLL`: reglas de negocio y validaciones antes de llegar a base.
- `DAL`: acceso a SQL Server, transacciones y consultas.
- `Servicios`: seguridad, sesion, hash, integridad, cifrado.
- Paginas `.aspx` / `.aspx.cs`: interfaz Web Forms y eventos de botones.

## Mapa express de archivos importantes

| Tema | Donde mirar | Que responder |
| --- | --- | --- |
| Login | `ReservaVuelos/Login.aspx.cs:21` | Toma email/password, llama a `SeguridadService.Authenticate`, guarda sesion y valida integridad. |
| Registro | `ReservaVuelos/Registro.aspx.cs:14` | Valida politica de password y registra usuario. |
| Politica de password | `ReservaVuelos/Servicios/PasswordPolicyService.cs:7` | Minimo 8, mayuscula, minuscula, numero y caracter especial. |
| Hash/salt | `ReservaVuelos/Servicios/HashService.cs:9` | Usa PBKDF2 con salt aleatorio y 10000 iteraciones. |
| Sesion | `ReservaVuelos/Servicios/SesionService.cs:9` | Guarda el usuario en `Session["User"]`. |
| Buscar vuelos | `ReservaVuelos/BuscarVuelos.aspx.cs:56` | Valida fechas, cantidad de pasajeros, cupos y muestra resultados. |
| Ir a reserva | `ReservaVuelos/BuscarVuelos.aspx.cs:121` | Al presionar reservar exige usuario logueado y redirige a detalle. |
| Detalle de reserva | `ReservaVuelos/DetalleReserva.aspx.cs:37` | Lee query string, valida vuelo, cupos y fecha futura. |
| Agregar pasajero | `ReservaVuelos/DetalleReserva.aspx.cs:106` | Valida nombre/documento, duplicados y cantidad maxima. |
| Confirmar reserva | `ReservaVuelos/DetalleReserva.aspx.cs:189` | Revalida cantidad exacta, crea/actualiza pasajeros y llama a BLL. |
| Reglas fuertes de reserva | `ReservaVuelos/BLL/ReservaCabeceraV2BLL.cs:18` | Valida cliente, detalles, pasajeros, subtotales e integridad. |
| Transaccion de reserva | `ReservaVuelos/DAL/ReservaCabeceraDAL.cs:11` | Inserta cabecera/detalles/pasajeros, descuenta cupos y recalcula DVH/DVV dentro de transaccion. |
| Cancelar reserva | `ReservaVuelos/MisReservas.aspx.cs:118` y `ReservaVuelos/DAL/ReservaCabeceraDAL.cs:188` | Cancela cabecera/detalles y devuelve cupos. |
| Mis datos | `ReservaVuelos/MisDatos.aspx.cs:73` | Guarda cliente y pasajero asociado al usuario. |
| Alta de vuelo | `ReservaVuelos/AdminVuelos.aspx.cs:80` y `ReservaVuelos/BLL/VueloBLL.cs:16` | Solo admin; valida origen/destino, precio, cupos y fecha futura. |
| Baja de vuelo | `ReservaVuelos/AdminVuelos.aspx.cs:34` y `ReservaVuelos/BLL/VueloBLL.cs:39` | Baja logica y cancela reservas asociadas si corresponde. |
| Bitacora | `ReservaVuelos/DAL/BitacoraDAL.cs:10` | Registra eventos con fecha, usuario, accion, criticidad y pantalla. |
| Integridad al iniciar | `ReservaVuelos/Global.asax.cs:15` y `ReservaVuelos/Global.asax.cs:20` | Al iniciar la app ejecuta `EnsureStartupValidation`. |
| Digitos verificadores | `ReservaVuelos/Servicios/IntegrityService.cs:34` | Calcula DVH con campos normalizados, primos y modulo 251. |
| Tablas protegidas | `ReservaVuelos/Servicios/IntegrityService.cs:18` | Usuarios, Clientes, Vuelos, ReservaCabecera, ReservaDetalle. |
| Validacion general | `ReservaVuelos/Servicios/IntegrityService.cs:231` y `:248` | Recorre tablas criticas, persiste errores y activa contingencia si falla. |
| Recalculo DVH/DVV | `ReservaVuelos/Servicios/IntegrityService.cs:264` | Recalcula todos los DVH y DVV dentro de transaccion. |
| Salir de contingencia | `ReservaVuelos/Servicios/IntegrityService.cs:296` | Solo sale si `ValidateAll` da correcto. |
| Pantalla integridad | `ReservaVuelos/GestionIntegridad.aspx.cs:24` | Botones para validar, resolver y recalcular. |
| Restriccion por contingencia | `ReservaVuelos/Site.Master.cs:23` | Si hay contingencia, bloquea pantallas no permitidas. |
| Backup | `ReservaVuelos/Backup.aspx.cs:44` y `:163` | Genera/restaura backup, verifica y registra en bitacora. |
| Modelo SQL | `ReservaVuelos/SQL/ReservaVuelos.sql:21` | Define tablas, constraints, indices, DVH/DVV e integridad. |

## Preguntas probables y respuesta corta

### "Donde validan la contrasena?"

- En `Registro.aspx.cs:21` se llama a `PasswordPolicyService.Validate`.
- En `PasswordPolicyService.cs:7` estan las reglas:
  - largo minimo 8,
  - al menos una mayuscula,
  - al menos una minuscula,
  - al menos un numero,
  - al menos un caracter especial.
- En `SeguridadService.cs:52` se genera hash y salt antes de guardar.
- En `HashService.cs:9` se usa PBKDF2 para crear hash.
- En `HashService.cs:26` se verifica la password al loguear.

Respuesta para decir: "La password no se guarda plana. Primero se valida la politica y despues se guarda como hash PBKDF2 con salt. En login se recalcula el hash con el salt guardado y se compara."

### "Donde manejan la sesion?"

- `Login.aspx.cs:29`: si autentica bien, guarda el usuario.
- `SesionService.cs:9`: `SetUser`.
- `SesionService.cs:14`: `GetUser`.
- `SesionService.cs:19`: `Clear`.

Respuesta para decir: "Centralizamos el usuario logueado en `SesionService`, usando `Session['User']`, para que las paginas consulten si hay usuario y que rol tiene."

### "Donde validan que solo admin pueda entrar a administracion?"

- `AdminVuelos.aspx.cs:17`: si no hay usuario o no es `Administrador`, redirige a login.
- `GestionIntegridad.aspx.cs:11`: misma idea para integridad.
- `Site.Master.cs:40` a `:47`: muestra u oculta menus segun rol.

Respuesta para decir: "La validacion esta en el servidor, no solo en el menu. Aunque no vea el menu, si entra directo a la URL, el `Page_Load` vuelve a validar rol."

### "Donde se buscan vuelos?"

- `BuscarVuelos.aspx.cs:56`: evento del boton buscar.
- `BuscarVuelos.aspx.cs:65`: valida que vuelta sea posterior a ida.
- `BuscarVuelos.aspx.cs:71`: exige cantidad valida de pasajeros.
- `BuscarVuelos.aspx.cs:83`: filtra por cupos disponibles.
- `BuscarVuelos.aspx.cs:92` a `:105`: si es ida y vuelta, busca tramo inverso.
- `BuscarVuelos.aspx:80`: validacion cliente de fechas en JavaScript.

Respuesta para decir: "Hay una primera validacion en cliente para fechas, y despues en servidor se vuelve a validar cantidad, orden de fechas y cupos."

### "Donde se vuelve a validar antes de reservar?"

Hay varias capas:

- `DetalleReserva.aspx.cs:51`: parsea `IdVuelo` y `CantidadPasajeros`.
- `DetalleReserva.aspx.cs:59`: valida que el vuelo exista, este activo, tenga cupos y no sea pasado.
- `DetalleReserva.aspx.cs:201`: cantidad declarada valida.
- `DetalleReserva.aspx.cs:207`: pasajeros cargados deben coincidir exactamente con la cantidad.
- `ReservaCabeceraV2BLL.cs:18`: validaciones de negocio antes de persistir.
- `ReservaCabeceraV2BLL.cs:37`: la cantidad del detalle debe coincidir con pasajeros cargados.
- `ReservaCabeceraV2BLL.cs:41`: subtotal debe ser `PrecioUnitario * Cantidad`.
- `ReservaCabeceraDAL.cs:41`: dentro de la transaccion vuelve a leer el vuelo con lock.
- `ReservaCabeceraDAL.cs:57`: verifica que el vuelo este activo.
- `ReservaCabeceraDAL.cs:60`: verifica que no sea pasado.
- `ReservaCabeceraDAL.cs:63`: verifica cupos suficientes.
- `ReservaCabeceraDAL.cs:69`: descuenta cupos con condicion `CuposDisponibles >= @Cantidad`.

Respuesta para decir: "No confiamos solo en la pantalla. La reserva se valida en pantalla, en BLL y finalmente en DAL dentro de una transaccion con bloqueo y condicion de cupos."

### "Donde validan documento/pasajeros?"

- `DetalleReserva.aspx.cs:116`: nombre requerido.
- `DetalleReserva.aspx.cs:122`: documento requerido.
- `DetalleReserva.aspx.cs:129`: no permite dos pasajeros con el mismo documento en la misma reserva.
- `DetalleReserva.aspx.cs:135`: no permite superar la cantidad declarada.
- `PasajeroBLL.cs:71`: validacion central de pasajero.
- `PasajeroBLL.cs:77`: documento requerido.
- `DetalleReserva.aspx.cs:221`: si ya existe pasajero por documento, lo actualiza; si no, lo crea.
- `MisDatos.aspx.cs:125`: intenta vincular un pasajero existente por documento al usuario.

Respuesta para decir: "El documento identifica al pasajero. Se valida al agregarlo a la reserva y despues tambien en la BLL antes de crear o actualizar."

### "Como se crea una reserva?"

Flujo:

1. `BuscarVuelos.aspx.cs:121`: boton reservar.
2. `BuscarVuelos.aspx.cs:142`: redirige a `DetalleReserva.aspx?IdVuelo=...&CantidadPasajeros=...`.
3. `DetalleReserva.aspx.cs:37`: carga detalle y valida vuelo.
4. `DetalleReserva.aspx.cs:106`: se agregan pasajeros temporalmente en Session.
5. `DetalleReserva.aspx.cs:189`: boton confirmar.
6. `DetalleReserva.aspx.cs:216`: obtiene o crea cliente.
7. `DetalleReserva.aspx.cs:219` a `:236`: crea o actualiza pasajeros.
8. `DetalleReserva.aspx.cs:240` a `:246`: arma detalles con cantidad, precio y subtotal.
9. `DetalleReserva.aspx.cs:248`: llama a `CreateWithDetails`.
10. `ReservaCabeceraV2BLL.cs:18`: valida reglas de negocio.
11. `ReservaCabeceraDAL.cs:11`: persiste todo en una transaccion.

Respuesta para decir: "La pantalla arma los datos, la BLL valida reglas, y el DAL hace la operacion atomica: cabecera, detalle, pasajeros, descuento de cupos e integridad."

### "Como evitan que dos usuarios reserven el ultimo cupo?"

- `ReservaCabeceraDAL.cs:16`: abre transaccion.
- `ReservaCabeceraDAL.cs:41` y `:42`: lee el vuelo con `UPDLOCK, ROWLOCK`.
- `ReservaCabeceraDAL.cs:69` a `:72`: descuenta cupos solo si `CuposDisponibles >= @Cantidad`.
- `ReservaCabeceraDAL.cs:77`: si no actualizo filas, lanza error.
- `ReservaCabeceraDAL.cs:119`: confirma con `Commit`.
- `ReservaCabeceraDAL.cs:124`: si algo falla, `Rollback`.

Respuesta para decir: "La validacion final de cupos ocurre dentro de una transaccion y con lock. Ademas, el update tiene condicion de cupos; si otro usuario los tomo antes, no actualiza y se cancela la operacion."

### "Como se cancela una reserva?"

- `MisReservas.aspx.cs:118`: evento del boton cancelar.
- `ReservaCabeceraV2BLL.cs:107`: metodo `Cancel`.
- `ReservaCabeceraDAL.cs:188`: transaccion de cancelacion.
- `ReservaCabeceraDAL.cs:198`: bloquea la cabecera.
- `ReservaCabeceraDAL.cs:210`: si ya esta cancelada, no hace nada.
- `ReservaCabeceraDAL.cs:238`: marca cabecera como `Cancelada`.
- `ReservaCabeceraDAL.cs:250`: marca detalles como `Cancelado`.
- `ReservaCabeceraDAL.cs:263`: devuelve cupos a vuelos.
- `ReservaCabeceraDAL.cs:275` a `:284`: recalcula DVH/DVV.

Respuesta para decir: "La cancelacion es idempotente: si ya estaba cancelada, no duplica devolucion de cupos. Si estaba activa, cambia estados y devuelve cupos dentro de una transaccion."

### "Donde se calculan los digitos verificadores?"

- `IntegrityService.cs:34`: algoritmo base `CalculateDVH`.
- `IntegrityService.cs:51`: DVH de Usuarios.
- `IntegrityService.cs:62`: DVH de Clientes.
- `IntegrityService.cs:76`: DVH de Vuelos.
- `IntegrityService.cs:91`: DVH de ReservaCabecera.
- `IntegrityService.cs:106`: DVH de ReservaDetalle.
- `IntegrityService.cs:332`: actualiza DVV de tabla.
- `IntegrityService.cs:346`: actualiza DVH de un registro.
- `IntegrityService.cs:498`: recalcula DVH segun la tabla leida de SQL.
- `IntegrityService.cs:681`: normaliza campos antes de calcular.

Respuesta para decir: "El DVH se calcula por registro uniendo campos normalizados. El DVV se calcula como la suma de los DVH de la tabla. Cada cambio critico actualiza el registro y despues el DVV de la tabla."

### "Que tablas estan protegidas por integridad?"

- `IntegrityService.cs:18`: arreglo `CriticalTables`.
- Protegidas: `Usuarios`, `Clientes`, `Vuelos`, `ReservaCabecera`, `ReservaDetalle`.
- En SQL estan los campos `DVH`, por ejemplo:
  - `ReservaVuelos.sql:31`: `Usuarios`.
  - `ReservaVuelos.sql:49`: `Clientes`.
  - `ReservaVuelos.sql:105`: `Vuelos`.
  - `ReservaVuelos.sql:127`: `ReservaCabecera`.
  - `ReservaVuelos.sql:146`: `ReservaDetalle`.

Respuesta para decir: "Protegemos las tablas que afectan seguridad, datos del cliente, vuelos y reservas. No todas las tablas necesitan DVH, por ejemplo la bitacora queda como auditoria."

### "Cuando validan integridad?"

- Al iniciar la aplicacion: `Global.asax.cs:20`.
- Al login correcto: `Login.aspx.cs:31`.
- Antes de operaciones criticas:
  - crear cliente: `ClienteBLL.cs:24`.
  - actualizar cliente: `ClienteBLL.cs:35`.
  - crear vuelo: `VueloBLL.cs:33`.
  - baja de vuelo: `VueloBLL.cs:41` a `:44`.
  - crear reserva: `ReservaCabeceraV2BLL.cs:29` a `:33`.
  - cancelar reserva: `ReservaCabeceraV2BLL.cs:112` a `:114`.
- Desde pantalla admin: `GestionIntegridad.aspx.cs:24`, `:33`, `:44`.

Respuesta para decir: "La integridad se valida al inicio, al login y antes de tocar tablas criticas. Si algo falla, se activa contingencia."

### "Que pasa si falla la integridad?"

- `IntegrityService.cs:202`: valida tabla.
- `IntegrityService.cs:215`: persiste errores.
- `IntegrityService.cs:221`: `EnsureTableIsValid` corta la operacion.
- `IntegrityService.cs:258`: persiste errores en validacion general.
- `IntegrityService.cs:259`: activa modo contingencia.
- `IntegrityService.cs:366`: define que paginas se pueden usar durante contingencia.
- `Site.Master.cs:23`: redirige si no se puede acceder.
- `IntegrityService.cs:396`: redireccion auxiliar a integridad o mantenimiento.

Respuesta para decir: "Si detecta diferencia entre DVH/DVV guardado y calculado, registra el error, activa contingencia y bloquea pantallas normales. El admin puede ir a Gestion de Integridad o Backup."

### "Como salen de contingencia?"

- `GestionIntegridad.aspx.cs:33`: boton resolver.
- `IntegrityService.cs:296`: `TryResolveAfterValidation`.
- `IntegrityService.cs:298`: primero vuelve a ejecutar `ValidateAll`.
- `IntegrityService.cs:301`: si siguen errores, persiste y mantiene contingencia.
- `IntegrityService.cs:307` a `:317`: si esta todo bien, marca errores como resueltos.
- `IntegrityService.cs:320`: desactiva contingencia.

Respuesta para decir: "No se sale manualmente a ciegas. El sistema vuelve a validar todo; solo si no hay errores, marca inconsistencias como resueltas y desactiva contingencia."

### "Donde esta el recalculo de digitos?"

- `GestionIntegridad.aspx.cs:39`: boton recalcular.
- `IntegrityService.cs:264`: `RecalculateAll`.
- `IntegrityService.cs:274`: recorre tablas criticas.
- `IntegrityService.cs:476`: recalcula cada registro.
- `IntegrityService.cs:482`: recalcula DVV de la tabla.
- `IntegrityService.cs:293`: despues intenta resolver validando nuevamente.

Respuesta para decir: "El recalculo tambien es transaccional. Recalcula DVH registro por registro, despues DVV de cada tabla, y al final vuelve a validar."

### "Donde se registra la bitacora?"

- Insercion central: `BitacoraDAL.cs:10`.
- Login exitoso/fallido: `SeguridadService.cs:21`, `:27`, `:33`, `:44`.
- Registro: `SeguridadService.cs:60`.
- Reserva creada/cancelada: `ReservaCabeceraV2BLL.cs:66` y `:119`.
- Admin vuelos: `AdminVuelos.aspx.cs:44`, `:47`, `:95`.
- Backup: `Backup.aspx.cs:122`, `:210`, `:223`.
- Integridad: `IntegrityService.cs:698`.
- Filtros de bitacora: `Bitacora.aspx.cs:30` y `BitacoraDAL.cs:51`.

Respuesta para decir: "La bitacora audita acciones funcionales y tecnicas con criticidad. Se usa para login, reservas, admin, backup e integridad."

### "Como funciona backup y restore?"

- Generar backup: `Backup.aspx.cs:44`.
- Ejecuta `BACKUP DATABASE`: `Backup.aspx.cs:86`.
- Verifica backup: `Backup.aspx.cs:103`.
- Restaurar backup: `Backup.aspx.cs:163`.
- Valida ruta/archivo: `Backup.aspx.cs:174` y `:285`.
- Verifica antes de restaurar: `Backup.aspx.cs:192`.
- Ejecuta `RESTORE DATABASE`: `Backup.aspx.cs:203`.
- Despues valida integridad: `Backup.aspx.cs:212`.

Respuesta para decir: "El backup no solo crea archivo: lo verifica. El restore tambien verifica el archivo, restaura, registra en bitacora y vuelve a correr integridad."

## Flujo completo para mostrar en la presentacion

```text
Usuario busca vuelo
  -> BuscarVuelos.aspx.cs valida fechas/cantidad/cupos
  -> Selecciona reservar
  -> DetalleReserva.aspx.cs valida login, vuelo activo, cupos y fecha futura
  -> Carga pasajeros en Session
  -> Confirma
  -> DetalleReserva.aspx.cs revalida cantidad exacta
  -> ClienteBLL/PasajeroBLL validan datos base
  -> ReservaCabeceraV2BLL valida reglas de negocio e integridad
  -> ReservaCabeceraDAL abre transaccion
  -> Bloquea vuelos, revalida cupos, descuenta cupos
  -> Inserta cabecera, detalle y pasajeros
  -> Actualiza DVH/DVV
  -> Commit
  -> Registra bitacora
```

## Como explicar las capas

- Pantalla: recibe datos y da feedback al usuario.
- BLL: contiene reglas de negocio. Ejemplo: cantidad de pasajeros, subtotal, vuelos validos.
- DAL: hace SQL y transacciones. Ejemplo: descuento real de cupos y rollback.
- Servicios: funcionalidades transversales. Ejemplo: seguridad, sesion, integridad.

Frase util: "Una validacion importante aparece mas de una vez a proposito: primero para experiencia de usuario y despues para seguridad/consistencia del servidor."

## Checklist de defensa

- Si preguntan por validaciones de pantalla: ir a `.aspx` y `.aspx.cs`.
- Si preguntan por reglas reales: ir a `BLL`.
- Si preguntan por SQL/transacciones/cupos: ir a `DAL`.
- Si preguntan por login, hash, sesion: ir a `Servicios`.
- Si preguntan por DVH/DVV/contingencia: ir a `IntegrityService`.
- Si preguntan por auditoria: ir a `BitacoraDAL` y buscar llamadas a `_bBLL.Create`.
- Si preguntan por modelo de datos: ir a `ReservaVuelos/SQL/ReservaVuelos.sql`.

## Lugares para abrir primero si te quedas sin tiempo

1. `ReservaVuelos/DetalleReserva.aspx.cs:189` - confirmacion de reserva.
2. `ReservaVuelos/BLL/ReservaCabeceraV2BLL.cs:18` - reglas de negocio de reserva.
3. `ReservaVuelos/DAL/ReservaCabeceraDAL.cs:11` - transaccion real de reserva.
4. `ReservaVuelos/Servicios/IntegrityService.cs:34` - calculo DVH.
5. `ReservaVuelos/Servicios/IntegrityService.cs:248` - validacion general y contingencia.
6. `ReservaVuelos/Servicios/SeguridadService.cs:15` - autenticacion.
7. `ReservaVuelos/Servicios/HashService.cs:9` - hash/salt.
8. `ReservaVuelos/AdminVuelos.aspx.cs:80` - alta de vuelo.
9. `ReservaVuelos/MisReservas.aspx.cs:118` - cancelacion.
10. `ReservaVuelos/Backup.aspx.cs:163` - restauracion de backup.
