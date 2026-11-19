using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class GestionIntegridad : BasePage
    {
        protected override string ClaveTitulo { get { return "ui.gestionintegridad.001"; } }

        private readonly IntegrityService _integrity = new IntegrityService();

        protected void Page_Load(object sender, EventArgs e)
        {
            Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerIntegridad))
            {
                Response.Redirect("Login.aspx");
                return;
            }

            btnValidar.Visible = AutorizacionService.TienePermiso(user, Permisos.ValidarIntegridad);
            btnResolver.Visible = AutorizacionService.TienePermiso(user, Permisos.ResolverIntegridad);
            btnRecalcular.Visible = AutorizacionService.TienePermiso(user, Permisos.RecalcularIntegridad);
            if (!IsPostBack) Cargar();
        }

        protected void btnValidar_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.ValidarIntegridad);
            IntegrityValidationResult result = _integrity.ValidateAllAndPersist();
            lblMsg.ForeColor = result.IsValid ? System.Drawing.Color.Green : System.Drawing.Color.Red;
            lblMsg.Text = result.IsValid ? T("ui.gestionintegridad.msg016") : T("ui.gestionintegridad.msg017");
            Cargar();
        }

        protected void btnResolver_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.ResolverIntegridad);
            Usuario user = SesionService.GetUser();
            IntegrityValidationResult result = _integrity.TryResolveAfterValidation(user != null ? (int?)user.IdUsuario : null, "Validación completa correcta");
            lblMsg.ForeColor = result.IsValid ? System.Drawing.Color.Green : System.Drawing.Color.Red;
            lblMsg.Text = result.IsValid ? T("ui.gestionintegridad.msg018") : T("ui.gestionintegridad.msg019");
            Cargar();
        }

        protected void btnRecalcular_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.RecalcularIntegridad);
            Usuario user = SesionService.GetUser();
            try
            {
                _integrity.RecalculateAll(user != null ? (int?)user.IdUsuario : null, "Recalculo manual de DVH/DVV");
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = T("ui.gestionintegridad.msg020");
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("ui.gestionintegridad.msg021") + Traductor.Mensaje(ex.Message);
            }

            Cargar();
        }

        private void Cargar()
        {
            ConfiguracionSistema cfg = _integrity.GetConfiguracion();
            lblModo.Attributes[Traductor.ATRIBUTO] = cfg.ModoContingencia ? "ui.gestionintegridad.msg022" : "ui.gestionintegridad.msg023";
            lblModo.Text = cfg.ModoContingencia ? T("ui.gestionintegridad.msg022") : T("ui.gestionintegridad.msg023");
            lblModo.ForeColor = cfg.ModoContingencia ? System.Drawing.Color.Red : System.Drawing.Color.Green;
            lblUltimaValidacion.Text = cfg.FechaUltimaValidacion.HasValue ? cfg.FechaUltimaValidacion.Value.ToString("yyyy-MM-dd HH:mm:ss") : "-";
            lblMotivo.Text = string.IsNullOrWhiteSpace(cfg.MotivoContingencia) ? "-" : cfg.MotivoContingencia;

            gvErrores.DataSource = FiltrarGrilla(_integrity.GetErrors(false), FiltrogvErrores, v => v.NombreTabla + " " + v.Fecha.ToString("yyyy-MM-dd") + " " + v.Estado + " " + v.TipoOperacion + " " + v.TipoError + " " + v.IdRegistroAfectado);
            gvErrores.PageIndex = Math.Min(gvErrores.PageIndex, Math.Max(0, ((System.Collections.ICollection)gvErrores.DataSource).Count - 1) / gvErrores.PageSize);
            gvErrores.DataBind();
        }
        protected void gvErrores_PageIndexChanging(object sender, System.Web.UI.WebControls.GridViewPageEventArgs e)
        {
            gvErrores.PageIndex = e.NewPageIndex;
            Cargar();
        }

        private string FiltrogvErrores { get { return ViewState["FiltrogvErrores"] as string ?? ""; } set { ViewState["FiltrogvErrores"] = value; } }
        protected void FiltrargvErrores(object sender, EventArgs e)
        {
            if (((System.Web.UI.WebControls.Button)sender).CommandArgument == "limpiar") txtFiltrogvErrores.Text = "";
            FiltrogvErrores = txtFiltrogvErrores.Text.Trim();
            gvErrores.PageIndex = 0;
            Cargar();
        }

    }
}
