using System.Web;
using ReservaVuelos.BE;
using System;

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

        public static bool IsAdministrator(Usuario user)
        {
            return HasRole(user, "Administrador");
        }

        public static bool IsWebMaster(Usuario user)
        {
            return HasRole(user, "WebMaster");
        }

        private static bool HasRole(Usuario user, string role)
        {
            return user != null &&
                   string.Equals(user.Rol, role, StringComparison.OrdinalIgnoreCase);
        }
    }
}

