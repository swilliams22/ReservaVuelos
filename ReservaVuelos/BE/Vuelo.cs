using System;

namespace ReservaVuelos.BE
{
    public class Vuelo
    {
        public int IdVuelo { get; set; }
        public string Origen { get; set; }
        public string Destino { get; set; }
        public DateTime FechaSalida { get; set; }
        public TimeSpan HoraSalida { get; set; }
        public decimal Precio { get; set; }
        public int CuposDisponibles { get; set; }
        public bool Activo { get; set; }
    }
}
