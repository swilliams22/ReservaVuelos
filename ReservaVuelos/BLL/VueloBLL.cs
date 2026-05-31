using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Collections.Generic;

namespace ReservaVuelos.BLL
{
    public class VueloBLL
    {
        private VueloDAL _dal = new VueloDAL();

        public List<Vuelo> Search(string origen, string destino, DateTime? fecha) => _dal.Search(origen, destino, fecha);
        public Vuelo GetById(int id) => _dal.GetById(id);
        public int Create(Vuelo v) => _dal.Create(v);
        public void UpdateSeats(int idVuelo, int delta) => _dal.UpdateSeats(idVuelo, delta);
        public bool SoftDelete(int id) => _dal.SoftDelete(id) > 0;
    }
}
