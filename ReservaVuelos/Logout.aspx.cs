using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class Logout : System.Web.UI.Page
    {
        private BitacoraBLL _bBLL = new BitacoraBLL();
        protected void Page_Load(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            if (user != null)
            {
                // Logout -> Info
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Logout", Criticidad = "Info", Pantalla = "Logout" });
            }
            SesionService.Clear();
            Response.Redirect("Default.aspx");
        }
    }
}
