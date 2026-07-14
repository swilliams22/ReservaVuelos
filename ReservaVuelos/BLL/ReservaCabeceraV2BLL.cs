using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using BitacoraEntity = ReservaVuelos.BE.Bitacora;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ReservaVuelos.BLL
{
    public class ReservaCabeceraV2BLL
    {
        private ReservaCabeceraDAL _dal = new ReservaCabeceraDAL();
        private ReservaDetalleDAL _detalleDAL = new ReservaDetalleDAL();
        private ReservaPasajeroDAL _pasajeroDAL = new ReservaPasajeroDAL();
        private BitacoraBLL _bitacoraBLL = new BitacoraBLL();

        public int CreateWithDetails(int idCliente, List<ReservaDetalle> detalles, List<Pasajero> pasajeros, Usuario usuarioActual)
        {
            if (idCliente <= 0)
                throw new ArgumentException("El ID del cliente es requerido.");
            if (detalles == null || detalles.Count == 0)
                throw new ArgumentException("Debe seleccionar al menos un vuelo.");
            if (pasajeros == null || pasajeros.Count == 0)
                throw new ArgumentException("Debe registrar al menos un pasajero.");
            if (usuarioActual == null)
                throw new ArgumentException("El usuario actual es requerido.");

            var integrity = new IntegrityService();
            integrity.EnsureAllTablesAreValid();

            foreach (var detalle in detalles)
            {
                if (detalle.Cantidad <= 0)
                    throw new ArgumentException("La cantidad de pasajeros debe ser mayor o igual a 1.");
                if (detalle.Cantidad != pasajeros.Count)
                    throw new ArgumentException("La cantidad de pasajeros de la reserva no coincide con los pasajeros cargados.");
                if (detalle.PrecioUnitario < 0)
                    throw new ArgumentException("El precio unitario no puede ser negativo.");
                if (detalle.SubTotal != detalle.PrecioUnitario * detalle.Cantidad)
                    throw new ArgumentException("El subtotal de la reserva es inválido.");
            }

            decimal montoTotal = detalles.Sum(d => d.SubTotal);
            var cabecera = new ReservaCabecera
            {
                IdCliente = idCliente,
                IdUsuarioCreador = usuarioActual.IdUsuario,
                FechaReserva = DateTime.Now,
                Estado = "Activa",
                MontoTotal = montoTotal,
                FechaCreacion = DateTime.Now
            };

            var reservaPasajeros = pasajeros.Select(p => new ReservaPasajero
            {
                IdPasajero = p.IdPasajero
            }).ToList();

            try
            {
                int idReservaCabecera = _dal.CreateWithDetails(cabecera, detalles, reservaPasajeros);
                _bitacoraBLL.Create(new BitacoraEntity
                {
                    Fecha = DateTime.Now,
                    Usuario = usuarioActual.Email ?? "Sistema",
                    Accion = string.Format("Reserva creada. IdReservaCabecera: {0} - Vuelos: {1} - Pasajeros: {2} - MontoTotal: {3}", idReservaCabecera, detalles.Count, pasajeros.Count, montoTotal),
                    Criticidad = 1,
                    Pantalla = "ReservaV2"
                });

                return idReservaCabecera;
            }
            catch (Exception ex)
            {
                _bitacoraBLL.Create(new BitacoraEntity
                {
                    Fecha = DateTime.Now,
                    Usuario = usuarioActual.Email ?? "Sistema",
                    Accion = string.Format("Error al crear reserva: {0}", ex.Message),
                    Criticidad = 3,
                    Pantalla = "ReservaV2"
                });
                throw;
            }
        }

        public ReservaCabecera GetById(int idReservaCabecera)
        {
            return _dal.GetById(idReservaCabecera);
        }

        public List<ReservaCabecera> GetByIdCliente(int idCliente)
        {
            return _dal.GetByIdCliente(idCliente);
        }

        public List<ReservaCabecera> GetByIdPasajero(int idPasajero)
        {
            return _dal.GetByIdPasajero(idPasajero);
        }

        public List<ReservaDetalle> GetDetalles(int idReservaCabecera)
        {
            return _detalleDAL.GetByReservaCabecera(idReservaCabecera);
        }

        public List<Pasajero> GetPasajeros(int idReservaCabecera)
        {
            return _pasajeroDAL.GetPasajerosByReservaCabecera(idReservaCabecera);
        }

        public bool Cancel(int idReservaCabecera, Usuario usuarioActual)
        {
            try
            {
                var integrity = new IntegrityService();
                integrity.EnsureAllTablesAreValid();

                var rows = _dal.Cancel(idReservaCabecera, usuarioActual != null ? (int?)usuarioActual.IdUsuario : null);
                if (rows > 0)
                {
                    _bitacoraBLL.Create(new BitacoraEntity
                    {
                        Fecha = DateTime.Now,
                        Usuario = usuarioActual != null ? usuarioActual.Email : "Sistema",
                        Accion = string.Format("Reserva cancelada. IdReservaCabecera: {0}", idReservaCabecera),
                        Criticidad = 1,
                        Pantalla = "ReservaV2"
                    });
                }

                return rows > 0;
            }
            catch (Exception ex)
            {
                _bitacoraBLL.Create(new BitacoraEntity
                {
                    Fecha = DateTime.Now,
                    Usuario = usuarioActual != null ? usuarioActual.Email : "Sistema",
                    Accion = string.Format("Error al cancelar reserva {0}: {1}", idReservaCabecera, ex.Message),
                    Criticidad = 3,
                    Pantalla = "ReservaV2"
                });
                throw;
            }
        }
    }
}
