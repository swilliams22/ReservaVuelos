using System;

namespace ReservaVuelos.BE
{
    public class ReservaCabecera
    {
        public int IdReservaCabecera { get; set; }
        public int IdCliente { get; set; }
        public int IdUsuarioCreador { get; set; }
        public DateTime FechaReserva { get; set; }
        public string Estado { get; set; }
        public decimal MontoTotal { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaActualizacion { get; set; }
        public DateTime? FechaCancelacion { get; set; }
        public int? IdUsuarioCancela { get; set; }
        public int DVH { get; set; }
    }
}
