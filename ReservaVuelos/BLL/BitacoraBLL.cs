using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Collections.Generic;

namespace ReservaVuelos.BLL
{
    public class BitacoraBLL
    {
        private BitacoraDAL _dal = new BitacoraDAL();
        public int Create(ReservaVuelos.BE.Bitacora b) => _dal.Create(b);
        public List<ReservaVuelos.BE.Bitacora> GetAll() => _dal.GetAll();
        public List<ReservaVuelos.BE.Bitacora> GetByFilters(DateTime? desde, DateTime? hasta, string usuario, string criticidad, string pantalla) => _dal.GetByFilters(desde, hasta, usuario, criticidad, pantalla);
    }
}
