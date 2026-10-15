using ReservaVuelos.AeroLinkServiceReference;
using System;

namespace ReservaVuelos.Servicios
{
    /// <summary>
    /// Punto único para consumir el web service AeroLinkWS desde las páginas.
    /// Usa la referencia de servicio (AeroLinkServiceReference) y su configuración del Web.config,
    /// y se ocupa de cerrar el cliente aunque la llamada falle.
    /// </summary>
    public static class AeroLinkCliente
    {
        public static T Llamar<T>(Func<AeroLinkWSSoapClient, T> operacion)
        {
            var cliente = new AeroLinkWSSoapClient();
            try
            {
                var resultado = operacion(cliente);
                cliente.Close();
                return resultado;
            }
            catch
            {
                cliente.Abort();
                throw;
            }
        }
    }
}
