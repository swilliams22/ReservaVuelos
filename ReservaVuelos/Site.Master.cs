using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;

namespace ReservaVuelos
{
    public partial class SiteMaster : MasterPage, IIdiomaObserver
    {
        // ----- Observer del idioma -----

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            IdiomaService.Instancia.Suscribir(this);
        }

        protected override void OnUnload(EventArgs e)
        {
            IdiomaService.Instancia.Desuscribir(this);
            base.OnUnload(e);
        }

        // El Subject llama a este método cuando cambia el idioma.
        public void ActualizarIdioma(Idioma idioma)
        {
            Traductor.TraducirControles(this, idioma);
            SeleccionarIdioma(idioma);
        }

        protected void ddlIdioma_SelectedIndexChanged(object sender, EventArgs e)
        {
            IdiomaService.Instancia.CambiarIdioma(ddlIdioma.SelectedValue);
        }

        // Para textos dentro de los scripts de la Master.
        protected string TJs(string clave)
        {
            return HttpUtility.JavaScriptStringEncode(Traductor.T(clave));
        }

        private void CargarIdiomas()
        {
            ddlIdioma.DataSource = new IdiomaBLL().GetActivos();
            ddlIdioma.DataTextField = "Nombre";
            ddlIdioma.DataValueField = "Codigo";
            ddlIdioma.DataBind();
            SeleccionarIdioma(IdiomaService.Instancia.IdiomaActual);
        }

        private void SeleccionarIdioma(Idioma idioma)
        {
            var item = ddlIdioma.Items.FindByValue(idioma.Codigo);
            if (item == null) return;
            ddlIdioma.ClearSelection();
            item.Selected = true;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // En un postback NO se recarga ni se reselecciona el combo acá: ASP.NET todavía
            // tiene que disparar SelectedIndexChanged con el valor elegido por el usuario.
            if (!IsPostBack) CargarIdiomas();
            Traductor.TraducirControles(this, IdiomaService.Instancia.IdiomaActual);

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

            if (integrity.IsContingencyMode() && SesionService.IsWebMaster(user) &&
                !string.Equals(pageName, "GestionIntegridad.aspx", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(pageName, "Backup.aspx", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(pageName, "Bitacora.aspx", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/GestionIntegridad.aspx");
                return;
            }

            if (menuMisReservas != null) menuMisReservas.Visible = AutorizacionService.TienePermiso(user, Permisos.VerReservas);
            if (menuMisDatos != null) menuMisDatos.Visible = AutorizacionService.TienePermiso(user, Permisos.VerDatos);
            if (menuLogin != null) menuLogin.Visible = user == null;
            if (menuRegistro != null) menuRegistro.Visible = user == null;
            if (menuLogout != null) menuLogout.Visible = user != null;
            if (menuAdmin != null) menuAdmin.Visible = AutorizacionService.TienePermiso(user, Permisos.VerVuelos);
            if (menuIntegridad != null) menuIntegridad.Visible = AutorizacionService.TienePermiso(user, Permisos.VerIntegridad);
            if (menuBackup != null) menuBackup.Visible = AutorizacionService.TienePermiso(user, Permisos.VerBackup);
            if (menuBitacora != null) menuBitacora.Visible = AutorizacionService.TienePermiso(user, Permisos.VerBitacora);
            if (menuIdiomas != null) menuIdiomas.Visible = AutorizacionService.TienePermiso(user, Permisos.VerIdiomas);
        }
    }
}
