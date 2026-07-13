using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ReservaVuelos.Servicios;

namespace ReservaVuelos
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Mostrar/ocultar elementos del menú según sesión y rol
            var user = Session["User"] as BE.Usuario;
            var pageName = System.IO.Path.GetFileName(Request.AppRelativeCurrentExecutionFilePath);
            var integrity = new IntegrityService();
            if (string.IsNullOrWhiteSpace(pageName))
                pageName = System.IO.Path.GetFileName(Request.FilePath);
            pageName = integrity.NormalizePageName(pageName);

            if (!integrity.CanAccessDuringContingency(pageName, user))
            {
                Response.Redirect("~/Mantenimiento.aspx");
                return;
            }

            if (integrity.IsContingencyMode() && user != null && user.Rol == "Administrador" &&
                !string.Equals(pageName, "GestionIntegridad.aspx", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(pageName, "Backup.aspx", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(pageName, "Bitacora.aspx", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/GestionIntegridad.aspx");
                return;
            }

            if (menuMisReservas != null) menuMisReservas.Visible = user != null;
            if (menuMisDatos != null) menuMisDatos.Visible = user != null;
            if (menuLogin != null) menuLogin.Visible = user == null;
            if (menuRegistro != null) menuRegistro.Visible = user == null;
            if (menuLogout != null) menuLogout.Visible = user != null;
            if (menuAdmin != null) menuAdmin.Visible = user != null && user.Rol == "Administrador";
            if (menuIntegridad != null) menuIntegridad.Visible = user != null && user.Rol == "Administrador";
            if (menuBackup != null) menuBackup.Visible = user != null && user.Rol == "Administrador";
            if (menuBitacora != null) menuBitacora.Visible = user != null && user.Rol == "Administrador";
        }
    }
}
