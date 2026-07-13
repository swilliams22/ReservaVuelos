using System;

namespace ReservaVuelos.BE
{
    public class IntegridadError
    {
        public int IdError { get; set; }
        public DateTime Fecha { get; set; }
        public string TipoError { get; set; }
        public string NombreTabla { get; set; }
        public string IdRegistroAfectado { get; set; }
        public string ValorEsperado { get; set; }
        public string ValorCalculado { get; set; }
        public string Estado { get; set; }
        public int? IdUsuarioAdministrador { get; set; }
        public string AccionTomada { get; set; }
    }
}
