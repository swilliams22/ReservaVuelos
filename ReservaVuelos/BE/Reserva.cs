using System;

namespace ReservaVuelos.BE
{
    public class Reserva
    {
        public int IdReserva { get; set; }
        public int IdUsuario { get; set; }
        public int IdVuelo { get; set; }
        public DateTime FechaReserva { get; set; }
        public string Estado { get; set; }
    }
}
