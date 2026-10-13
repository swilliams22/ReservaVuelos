using ReservaVuelos.BE;

namespace ReservaVuelos.Servicios
{
    /// <summary>
    /// Observer: quien quiere enterarse cuando cambia el idioma
    /// (la Master, cada página, los user controls).
    /// </summary>
    public interface IIdiomaObserver
    {
        void ActualizarIdioma(Idioma idioma);
    }
}
