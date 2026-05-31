using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System.Collections.Generic;

namespace ReservaVuelos.BLL
{
    public class ReservaBLL
    {
        private ReservaDAL _dal = new ReservaDAL();
        private VueloDAL _vueloDal = new VueloDAL();

        public int Create(Reserva r)
        {
            // Delegar a DAL la operación transaccional (verifica cupos, decrementa y crea reserva)
            return _dal.Create(r);
        }

        public List<Reserva> GetByUsuario(int idUsuario) => _dal.GetByUsuario(idUsuario);

        public bool Cancel(int idReserva)
        {
            var rows = _dal.Cancel(idReserva);
            return rows > 0;
        }

        public bool ExistsActiveReservation(int idUsuario, int idVuelo) => _dal.ExistsActiveReservation(idUsuario, idVuelo);

        public Reserva GetById(int idReserva) => _dal.GetById(idReserva);

        public List<Reserva> GetAll() => _dal.GetAll();
    }
}
