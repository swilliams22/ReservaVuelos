using System;

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

        // Datos adicionales del vuelo (para mostrar en MisReservas)
        public string Origen { get; set; }
        public string Destino { get; set; }
        public DateTime FechaSalida { get; set; }
        public TimeSpan HoraSalida { get; set; }
        public decimal Precio { get; set; }
    }
}
