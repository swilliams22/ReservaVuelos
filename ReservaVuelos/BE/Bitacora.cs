using System;

namespace ReservaVuelos.BE
{
    public class Bitacora
    {
        public int IdBitacora { get; set; }
        public DateTime Fecha { get; set; }
        public string Usuario { get; set; }
        public string Accion { get; set; }
        public string Criticidad { get; set; }
        public string Pantalla { get; set; }
    }
}
