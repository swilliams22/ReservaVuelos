using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using System.Web.SessionState;
using ReservaVuelos.Servicios;

namespace ReservaVuelos
{
    public class Global : HttpApplication
    {
        void Application_PreRequestHandlerExecute(object sender, EventArgs e)
        {
            AutorizacionService.ControlarPeticion(Context);
        }

        void Application_Error(object sender, EventArgs e)
        {
            HttpException error = Server.GetLastError() as HttpException;
            if (error == null || error.GetHttpCode() != 403) return;
            Server.ClearError();
            Response.Clear();
            Response.StatusCode = 403;
            Response.TrySkipIisCustomErrors = true;
            Response.ContentType = "text/plain; charset=utf-8";
            Response.Write("Acceso denegado. No tiene permiso para acceder a esta página o ejecutar esta acción.");
            CompleteRequest();
        }

        void Application_Start(object sender, EventArgs e)
        {
            // Código que se ejecuta al iniciar la aplicación
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
            new IntegrityService().EnsureStartupValidation();
        }
    }
}
