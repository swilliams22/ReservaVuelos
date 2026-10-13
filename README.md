# ReservaVuelos

Aplicación ASP.NET Web Forms sobre .NET Framework 4.7.2 para búsqueda de vuelos, gestión de reservas y administración básica.

## Stack

- ASP.NET Web Forms
- C#
- SQL Server
- ADO.NET con capas BE / BLL / DAL
- Visual Studio

## Modelo actual de reservas

La solución ya no trabaja con una tabla única de reservas. El flujo vigente usa:

- `Usuarios`: autenticación y autorización.
- `Clientes`: titular de la reserva, relación 1:1 con `Usuarios`.
- `Pasajeros`: personas que viajan; pueden o no estar vinculadas a un `Usuario`.
- `Vuelos`: disponibilidad, precio y estado del vuelo.
- `ReservaCabecera`: encabezado de la reserva.
- `ReservaDetalle`: tramos reservados, cantidad, precio unitario y subtotal histórico.
- `ReservaPasajero`: asociación entre reserva y pasajeros.
- `Bitacora`: auditoría funcional.
- `Idioma`, `Etiqueta` y `Traduccion`: idiomas de la interfaz y sus textos.

## Reglas de negocio principales

- Solo se pueden reservar vuelos activos, futuros y con cupos suficientes.
- La cantidad de pasajeros declarada debe coincidir exactamente con los pasajeros cargados.
- El subtotal se calcula como `PrecioUnitario x Cantidad`.
- El monto total de la reserva es la suma de los subtotales de sus detalles.
- La cancelación de una reserva es idempotente y devuelve los cupos al vuelo.
- Si un pasajero luego crea usuario, puede vincularse al usuario existente por email; en la pantalla `Mis datos` también puede reutilizarse por documento cuando no estaba vinculado.

## Páginas principales

- `BuscarVuelos.aspx`: búsqueda de vuelos y selección de cantidad de pasajeros.
- `DetalleReserva.aspx`: confirmación de la reserva y carga exacta de pasajeros.
- `MisReservas.aspx`: visualización de reservas, detalles, pasajeros y cancelación.
- `MisDatos.aspx`: edición restringida de datos del cliente titular y del pasajero vinculado al usuario autenticado.
- `AdminVuelos.aspx`: alta y baja lógica de vuelos.
- `Bitacora.aspx`: seguimiento administrativo.
- `GestionIdiomas.aspx`: administración de idiomas y traducciones (solo WebMaster).

## Base de datos

El script principal está en:

- `ReservaVuelos/SQL/ReservaVuelos.sql`

Ese script:

- crea el esquema completo desde cero,
- agrega restricciones, claves e índices,
- inserta vuelos de ejemplo,
- incluye consultas de auditoría para detectar inconsistencias.

## Múltiples idiomas (patrón Observer)

La interfaz se puede ver en distintos idiomas con el selector de la barra de navegación. Cambian títulos, etiquetas, botones y mensajes de las pantallas traducidas; no cambian fechas, números ni moneda.

- Las traducciones están en SQL Server (`Idioma`, `Etiqueta`, `Traduccion`), no en archivos, para que el WebMaster agregue un idioma sin programar.
- `IdiomaService` es el Subject: guarda el idioma elegido en la sesión y notifica a los observers. Los observers son `Site.Master` y `BasePage`, de la que heredan las páginas traducibles (`Login`, `BuscarVuelos`, `GestionIdiomas`).
- Un control del `.aspx` se traduce con `data-i18n="clave"`. En el code-behind se usa `T("clave")`. Si la clave no existe en el idioma elegido se usa el idioma por defecto (es-AR) y, si tampoco existe, el texto escrito en el `.aspx`.
- La preferencia de cada usuario se guarda en `Usuarios.IdIdioma` y se aplica al iniciar sesión. Ese campo no forma parte del DVH.

### Administrar idiomas

`GestionIdiomas.aspx` (menú **Idiomas**, solo rol WebMaster) permite:

- crear un idioma con su código (por ejemplo `pt-BR`) y nombre; queda inactivo hasta que se lo activa,
- ver el porcentaje traducido de cada idioma,
- editar las traducciones, filtrando por pantalla o por textos pendientes (un texto vacío elimina la traducción),
- activar o desactivar idiomas (el idioma por defecto no se puede desactivar).

Las altas, activaciones y guardados quedan en la bitácora.

### Agregar textos de una pantalla nueva

1. Marcar los controles con `data-i18n="pantalla.tipo.nombre"` y heredar la página de `BasePage`.
2. Agregar las claves y sus textos en es-AR y en-US en la sección "IDIOMAS Y TEXTOS DE LA INTERFAZ" de `ReservaVuelos/SQL/ReservaVuelos.sql`.
3. Sobre una base ya creada, ejecutar solo esa sección (a partir de `USE ReservaVuelosDB`). Es re-ejecutable: agrega lo que falta y no pisa traducciones editadas. No ejecutar el script completo, porque recrea la base.

## Configuración regional

La aplicación quedó configurada en `es-AR` y UTF-8 en `Web.config`. El idioma de la interfaz es independiente de esa configuración (ver Múltiples idiomas).

## Estado del proyecto

El flujo de reservas quedó alineado con el modelo `ReservaCabecera` / `ReservaDetalle` / `ReservaPasajero`, sin dependencia del modelo legacy eliminado del código.