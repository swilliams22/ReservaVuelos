using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Web;
using System.Web.UI;

namespace ReservaVuelos.Servicios
{
    public static class AutorizacionService
    {
        private const string ClaveArbol = "Autorizacion.Arbol";

        public static bool TienePermiso(Usuario usuario, string codigo)
        {
            if (usuario == null || !usuario.Activo || string.IsNullOrWhiteSpace(codigo)) return false;
            var contexto = HttpContext.Current;
            string clave = ClaveArbol + ":" + usuario.IdUsuario + ":" + usuario.Rol;
            var arbol = contexto == null ? null : contexto.Items[clave] as PermisoComponente;
            if (arbol == null)
            {
                arbol = new PermisoDAL().ObtenerPorRol(usuario.Rol);
                if (contexto != null) contexto.Items[clave] = arbol;
            }
            return arbol != null && arbol.TienePermiso(codigo);
        }

        public static void Exigir(string codigo)
        {
            if (!TienePermiso(SesionService.GetUser(), codigo))
                throw new HttpException(403, "No tiene permiso para ejecutar esta acción.");
        }

        public static void ControlarPeticion(HttpContext contexto)
        {
            var pagina = contexto.CurrentHandler as Page;
            if (pagina == null) return; // SOAP aplica su política en cada operación.

            // Refrescar rol y estado una vez por petición. Nunca confiar en el rol de una sesión vieja.
            var anterior = SesionService.GetUser();
            Usuario usuario = null;
            if (anterior != null)
            {
                usuario = new UsuarioDAL().GetByEmail(anterior.Email);
                if (usuario == null || !usuario.Activo || usuario.IdUsuario != anterior.IdUsuario)
                {
                    SesionService.Clear();
                    usuario = null;
                }
                else SesionService.SetUser(usuario);
            }

            string permiso;
            if (!PoliticaPaginas.IntentarObtener(pagina.AppRelativeVirtualPath, out permiso))
                throw new HttpException(403, "Esta página no tiene una política de acceso definida.");
            if (permiso != null)
            {
                if (usuario == null)
                {
                    contexto.Response.Redirect(VirtualPathUtility.ToAbsolute("~/Login.aspx"), true);
                    return;
                }
                if (!TienePermiso(usuario, permiso))
                    throw new HttpException(403, "No tiene permiso para acceder a esta página.");
            }

            // Antes del ciclo de vida de Page: también frena postbacks y acciones durante contingencia.
            var integridad = new IntegrityService();
            if (!integridad.CanAccessDuringContingency(pagina.AppRelativeVirtualPath, usuario))
            {
                string destino = SesionService.IsWebMaster(usuario) ? "~/GestionIntegridad.aspx" : "~/Mantenimiento.aspx";
                contexto.Response.Redirect(VirtualPathUtility.ToAbsolute(destino), true);
            }
        }
    }
}
