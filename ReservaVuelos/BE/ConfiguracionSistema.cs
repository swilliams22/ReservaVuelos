using System;

namespace ReservaVuelos.BE
{
    public class ConfiguracionSistema
    {
        public int IdConfiguracion { get; set; }
        public bool ModoContingencia { get; set; }
        public DateTime? FechaUltimaValidacion { get; set; }
        public string MotivoContingencia { get; set; }
    }
}
