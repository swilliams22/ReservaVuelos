using System;

namespace ReservaVuelos.BE
{
    public class Pasajero
    {
        public int IdPasajero { get; set; }
        public int? IdUsuario { get; set; }
        public string Nombre { get; set; }
        public string Apellido { get; set; }
        public string Email { get; set; }
        public string Documento { get; set; }
        public string Nacionalidad { get; set; }
        public DateTime? FechaNacimiento { get; set; }
        public DateTime FechaAlta { get; set; }
        public DateTime? FechaActualizacion { get; set; }

        public string NombreCompleto
        {
            get
            {
                if (string.IsNullOrWhiteSpace(Apellido))
                    return Nombre;

                return string.Format("{0} {1}", Nombre, Apellido).Trim();
            }
        }
    }
}
