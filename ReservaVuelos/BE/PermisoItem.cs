namespace ReservaVuelos.BE
{
    // Fila del catálogo de permisos para listados de la pantalla de perfiles.
    public class PermisoItem
    {
        public int IdPermiso { get; set; }
        public string Codigo { get; set; }
        public bool EsGrupo { get; set; }
        // Usuarios que tienen este grupo como rol (0 para permisos simples).
        public int CantidadUsuarios { get; set; }
        public string Tipo { get { return EsGrupo ? "Compuesto" : "Simple"; } }
    }
}
