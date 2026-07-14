using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class GestionIntegridad : System.Web.UI.Page
    {
        private readonly IntegrityService _integrity = new IntegrityService();

        protected void Page_Load(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            if (user == null || user.Rol != "Administrador")
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (!IsPostBack) Cargar();
        }

        protected void btnValidar_Click(object sender, EventArgs e)
        {
            var result = _integrity.ValidateAllAndPersist();
            lblMsg.ForeColor = result.IsValid ? System.Drawing.Color.Green : System.Drawing.Color.Red;
            lblMsg.Text = result.IsValid ? "Validación correcta." : "Se detectaron inconsistencias. El modo de contingencia permanece activo.";
            Cargar();
        }

        protected void btnResolver_Click(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            var result = _integrity.TryResolveAfterValidation(user != null ? (int?)user.IdUsuario : null, "Validación completa correcta");
            lblMsg.ForeColor = result.IsValid ? System.Drawing.Color.Green : System.Drawing.Color.Red;
            lblMsg.Text = result.IsValid ? "Integridad validada. Modo contingencia desactivado." : "Persisten inconsistencias. No se puede salir de contingencia.";
            Cargar();
        }

        protected void btnRecalcular_Click(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            try
            {
                _integrity.RecalculateAll(user != null ? (int?)user.IdUsuario : null, "Recalculo manual de DVH/DVV");
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = "Recalculo finalizado y validado.";
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = "No se pudo recalcular la integridad: " + ex.Message;
            }

            Cargar();
        }

        private void Cargar()
        {
            var cfg = _integrity.GetConfiguracion();
            lblModo.Text = cfg.ModoContingencia ? "Activo" : "Inactivo";
            lblModo.ForeColor = cfg.ModoContingencia ? System.Drawing.Color.Red : System.Drawing.Color.Green;
            lblUltimaValidacion.Text = cfg.FechaUltimaValidacion.HasValue ? cfg.FechaUltimaValidacion.Value.ToString("yyyy-MM-dd HH:mm:ss") : "-";
            lblMotivo.Text = string.IsNullOrWhiteSpace(cfg.MotivoContingencia) ? "-" : cfg.MotivoContingencia;

            gvErrores.DataSource = _integrity.GetErrors(cfg.ModoContingencia);
            gvErrores.DataBind();
        }
    }
}
