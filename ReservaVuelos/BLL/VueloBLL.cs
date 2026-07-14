using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;

namespace ReservaVuelos.BLL
{
    public class VueloBLL
    {
        private VueloDAL _dal = new VueloDAL();

        public List<Vuelo> Search(string origen, string destino, DateTime? fecha, string estado = "Activos", DateTime? fechaMinima = null) => _dal.Search(origen, destino, fecha, estado, fechaMinima);
        public Vuelo GetById(int id) => _dal.GetById(id);

        public int Create(Vuelo v)
        {
            if (v == null)
                throw new ArgumentException("El vuelo es requerido.");
            if (string.IsNullOrWhiteSpace(v.Origen))
                throw new ArgumentException("El origen del vuelo es requerido.");
            if (string.IsNullOrWhiteSpace(v.Destino))
                throw new ArgumentException("El destino del vuelo es requerido.");
            if (v.Origen.Trim().Equals(v.Destino.Trim(), StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException("El origen y destino del vuelo deben ser diferentes.");
            if (v.Precio < 0)
                throw new ArgumentException("El precio del vuelo no puede ser negativo.");
            if (v.CuposDisponibles < 0)
                throw new ArgumentException("Los cupos disponibles no pueden ser negativos.");
            if (v.FechaHoraSalida <= DateTime.Now)
                throw new ArgumentException("No se pueden crear vuelos con fecha y hora pasada.");

            new IntegrityService().EnsureAllTablesAreValid();
            v.FechaCreacion = DateTime.Now;
            return _dal.Create(v);
        }

        public void UpdateSeats(int idVuelo, int delta) => _dal.UpdateSeats(idVuelo, delta);
        public int SoftDelete(int id)
        {
            var integrity = new IntegrityService();
            integrity.EnsureAllTablesAreValid();
            return _dal.SoftDelete(id);
        }
    }
}
