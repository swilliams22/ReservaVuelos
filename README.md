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

## Base de datos

El script principal está en:

- `ReservaVuelos/SQL/ReservaVuelos.sql`

Ese script:

- crea el esquema completo desde cero,
- agrega restricciones, claves e índices,
- inserta vuelos de ejemplo,
- incluye consultas de auditoría para detectar inconsistencias.

## Configuración regional

La aplicación quedó configurada en `es-AR` y UTF-8 en `Web.config`.

## Estado del proyecto

El flujo de reservas quedó alineado con el modelo `ReservaCabecera` / `ReservaDetalle` / `ReservaPasajero`, sin dependencia del modelo legacy eliminado del código.