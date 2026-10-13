namespace ReservaVuelos.BE
{
    public class Idioma
    {
        public int IdIdioma { get; set; }
        public string Codigo { get; set; }      // 'es-AR', 'en-US'
        public string Nombre { get; set; }      // 'Español', 'English'
        public bool EsDefault { get; set; }
        public bool Activo { get; set; }

        // Solo los completa la pantalla de administración (GetTodos): avance de la traducción.
        public int Traducidas { get; set; }
        public int Total { get; set; }
        public int Porcentaje
        {
            get { return Total == 0 ? 0 : (int)System.Math.Round(Traducidas * 100.0 / Total); }
        }
    }
}
