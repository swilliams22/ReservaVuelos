namespace ReservaVuelos.Servicios
{
    /// <summary>
    /// Subject: mantiene la lista de observers y los avisa cuando cambia el idioma.
    /// </summary>
    public interface IIdiomaSubject
    {
        void Suscribir(IIdiomaObserver observer);
        void Desuscribir(IIdiomaObserver observer);
        void Notificar();
    }
}
