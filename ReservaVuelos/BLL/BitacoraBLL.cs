using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System.Collections.Generic;

namespace ReservaVuelos.BLL
{
    public class BitacoraBLL
    {
        private BitacoraDAL _dal = new BitacoraDAL();

        public int Create(ReservaVuelos.BE.Bitacora b) => _dal.Create(b);
        public List<ReservaVuelos.BE.Bitacora> GetAll() => _dal.GetAll();
    }
}
