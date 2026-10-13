namespace ReservaVuelos.BE
{
    public class Idioma
    {
        public int IdIdioma { get; set; }
        public string Codigo { get; set; }      // 'es-AR', 'en-US'
        public string Nombre { get; set; }      // 'Español', 'English'
        public bool EsDefault { get; set; }
        public bool Activo { get; set; }
    }
}
