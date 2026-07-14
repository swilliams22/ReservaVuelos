using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos.BLL
{
    public class ClienteBLL
    {
        private ClienteDAL _dal = new ClienteDAL();

        public Cliente GetByIdUsuario(int idUsuario)
        {
            return _dal.GetByIdUsuario(idUsuario);
        }

        public Cliente GetById(int idCliente)
        {
            return _dal.GetById(idCliente);
        }

        public int Create(Cliente c)
        {
            ValidarCliente(c);
            new IntegrityService().EnsureAllTablesAreValid();
            c.FechaAlta = DateTime.Now;
            return _dal.Create(c);
        }

        public bool Update(Cliente c)
        {
            if (c == null || c.IdCliente <= 0)
                throw new ArgumentException("El cliente es inválido.");

            ValidarCliente(c);
            new IntegrityService().EnsureAllTablesAreValid();
            c.FechaActualizacion = DateTime.Now;
            return _dal.Update(c) > 0;
        }

        public Cliente GetOrCreateByUsuario(int idUsuario, string nombre, string email, string documento = null)
        {
            var cliente = GetByIdUsuario(idUsuario);
            if (cliente != null)
                return cliente;

            var nuevoCliente = new Cliente
            {
                IdUsuario = idUsuario,
                Nombre = nombre,
                Email = email,
                Documento = documento,
                FechaAlta = DateTime.Now
            };

            var idCliente = Create(nuevoCliente);
            nuevoCliente.IdCliente = idCliente;
            return nuevoCliente;
        }

        private static void ValidarCliente(Cliente c)
        {
            if (c == null)
                throw new ArgumentException("El cliente es requerido.");
            if (string.IsNullOrWhiteSpace(c.Nombre))
                throw new ArgumentException("El nombre del cliente es requerido.");
            if (string.IsNullOrWhiteSpace(c.Email))
                throw new ArgumentException("El email del cliente es requerido.");
        }
    }
}
