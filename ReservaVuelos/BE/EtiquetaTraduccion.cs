namespace ReservaVuelos.BE
{
    /// <summary>Una etiqueta (clave de texto) con su texto base y su traducción a un idioma.</summary>
    public class EtiquetaTraduccion
    {
        public int IdEtiqueta { get; set; }
        public string Clave { get; set; }
        public string Pantalla { get; set; }
        public string TextoBase { get; set; }   // texto en el idioma por defecto
        public string Texto { get; set; }       // traducción al idioma que se está editando ('' si falta)
    }
}
