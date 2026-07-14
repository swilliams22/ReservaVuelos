using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos.BLL
{
    public class PasajeroBLL
    {
        private PasajeroDAL _dal = new PasajeroDAL();

        public int Create(Pasajero p)
        {
            ValidarPasajero(p);
            new IntegrityService().EnsureAllTablesAreValid();
            p.FechaAlta = DateTime.Now;
            return _dal.Create(p);
        }

        public bool Update(Pasajero p)
        {
            if (p == null || p.IdPasajero <= 0)
                throw new ArgumentException("El pasajero es inválido.");

            ValidarPasajero(p);
            new IntegrityService().EnsureAllTablesAreValid();
            p.FechaActualizacion = DateTime.Now;
            return _dal.Update(p) > 0;
        }

        public Pasajero GetById(int idPasajero)
        {
            return _dal.GetById(idPasajero);
        }

        public Pasajero GetByEmail(string email)
        {
            return _dal.GetByEmail(email);
        }

        public Pasajero GetByDocumento(string documento)
        {
            return _dal.GetByDocumento(documento);
        }

        public Pasajero GetByIdUsuario(int idUsuario)
        {
            return _dal.GetByIdUsuario(idUsuario);
        }

        public Pasajero FindByEmailOrDocumento(string email, string documento)
        {
            Pasajero p = null;

            if (!string.IsNullOrWhiteSpace(email))
                p = GetByEmail(email);

            if (p == null && !string.IsNullOrWhiteSpace(documento))
                p = GetByDocumento(documento);

            return p;
        }

        public bool ExistsWithEmail(string email)
        {
            return _dal.ExistsWithEmail(email);
        }

        public bool VincularConUsuario(int idPasajero, int idUsuario)
        {
            new IntegrityService().EnsureAllTablesAreValid();
            return _dal.VincularConUsuario(idPasajero, idUsuario) > 0;
        }

        private static void ValidarPasajero(Pasajero p)
        {
            if (p == null)
                throw new ArgumentException("El pasajero es requerido.");
            if (string.IsNullOrWhiteSpace(p.Nombre))
                throw new ArgumentException("El nombre del pasajero es requerido.");
            if (string.IsNullOrWhiteSpace(p.Documento))
                throw new ArgumentException("El documento del pasajero es requerido.");
        }
    }
}
