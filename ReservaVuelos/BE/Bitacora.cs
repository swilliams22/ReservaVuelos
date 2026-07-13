using System;

namespace ReservaVuelos.BE
{
    public class Bitacora
    {
        public int IdBitacora { get; set; }
        public DateTime Fecha { get; set; }
        public string Usuario { get; set; }
        public string Accion { get; set; }
        public int Criticidad { get; set; }
        public string CriticidadDescripcion
        {
            get
            {
                switch (Criticidad)
                {
                    case 1: return "1 - Información";
                    case 2: return "2 - Advertencia";
                    case 3: return "3 - Error";
                    case 4: return "4 - Crítica";
                    default: return Criticidad.ToString();
                }
            }
        }
        public string Pantalla { get; set; }
    }
}
