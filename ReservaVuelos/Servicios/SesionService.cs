using System.Web;
using ReservaVuelos.BE;

namespace ReservaVuelos.Servicios
{
    // Servicio simple para manejo de sesión usando HttpContext.Current
    public static class SesionService
    {
        public static void SetUser(Usuario u)
        {
            HttpContext.Current.Session["User"] = u;
        }

        public static Usuario GetUser()
        {
            return HttpContext.Current.Session["User"] as Usuario;
        }

        public static void Clear()
        {
            HttpContext.Current.Session.Remove("User");
        }
    }
}
