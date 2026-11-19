using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Collections.Generic;
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
            HttpContext contexto = HttpContext.Current;
            string clave = ClaveArbol + ":" + usuario.IdUsuario + ":" + usuario.Rol;
            PermisoComponente arbol = contexto == null ? null : contexto.Items[clave] as PermisoComponente;
            if (arbol == null)
            {
                arbol = new PermisoDAL().ObtenerPorRol(usuario.Rol);
                if (contexto != null) contexto.Items[clave] = arbol;
            }
            return arbol != null && arbol.TienePermiso(codigo);
        }

        // Después de cambiar perfiles o roles, el resto de la petición (menú, botones) usa el árbol nuevo.
        public static void InvalidarCache()
        {
            HttpContext contexto = HttpContext.Current;
            if (contexto == null) return;
            List<object> claves = new List<object>();
            foreach (object clave in contexto.Items.Keys)
            {
                string texto = clave as string;
                if (texto != null && texto.StartsWith(ClaveArbol + ":", StringComparison.Ordinal)) claves.Add(clave);
            }
            foreach (object clave in claves) contexto.Items.Remove(clave);
        }

        public static void Exigir(string codigo)
        {
            if (!TienePermiso(SesionService.GetUser(), codigo))
                throw new HttpException(403, "No tiene permiso para ejecutar esta acción.");
        }

        public static void ControlarPeticion(HttpContext contexto)
        {
            string destino = PrepararPeticion(contexto);
            if (destino != null) Redirigir(contexto, destino);
        }

        private static string PrepararPeticion(HttpContext contexto)
        {
            Page pagina = contexto.CurrentHandler as Page;
            if (pagina == null) return null; // SOAP aplica su política en cada operación.

            string permiso;
            if (!PoliticaPaginas.IntentarObtener(pagina.AppRelativeVirtualPath, out permiso))
                throw new HttpException(403, "Esta página no tiene una política de acceso definida.");

            Usuario anterior = SesionService.GetUser();
            IntegrityService integridad = new IntegrityService();
            // Detectar cambios SQL mientras la sesión sigue abierta, antes de
            // consultar roles/permisos o ejecutar el ciclo de vida de la página.
            if (anterior != null && permiso != null && !integridad.IsContingencyMode())
                integridad.ValidateAllAndPersist();

            Usuario usuario = null;
            if (anterior != null)
            {
                usuario = new UsuarioDAL().GetById(anterior.IdUsuario);
                bool filaAlterada = usuario != null && !integridad.EsUsuarioIntegro(usuario);
                if (usuario == null || filaAlterada || !usuario.Activo)
                {
                    SesionService.Clear();
                    usuario = null;
                    if (filaAlterada && permiso != null)
                    {
                        return "~/Mantenimiento.aspx";
                    }
                }
                else SesionService.SetUser(usuario);
            }

            // La contingencia tiene prioridad sobre la autorización normal.
            if (!integridad.CanAccessDuringContingency(pagina.AppRelativeVirtualPath, usuario))
            {
                return SesionService.IsWebMaster(usuario) ? "~/GestionIntegridad.aspx" : "~/Mantenimiento.aspx";
            }

            if (permiso != null)
            {
                if (usuario == null)
                {
                    return "~/Login.aspx";
                }
                if (!TienePermiso(usuario, permiso))
                    throw new HttpException(403, "No tiene permiso para acceder a esta página.");
            }
            return null;
        }

        private static void Redirigir(HttpContext contexto, string destino)
        {
            contexto.Response.Redirect(VirtualPathUtility.ToAbsolute(destino), true);
        }
    }
}
