using System;

namespace ReservaVuelos.BE
{
    public class ReservaDetalle
    {
        public int IdReservaDetalle { get; set; }
        public int IdReservaCabecera { get; set; }
        public int IdVuelo { get; set; }
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }
        public decimal SubTotal { get; set; }
        public string Estado { get; set; }
        public int DVH { get; set; }

        // Datos adicionales del vuelo (para mostrar en UI)
        public string Origen { get; set; }
        public string Destino { get; set; }
        public DateTime FechaSalida { get; set; }
        public TimeSpan HoraSalida { get; set; }
        public DateTime FechaHoraSalida { get; set; }
        public decimal Precio { get; set; }
    }
}
