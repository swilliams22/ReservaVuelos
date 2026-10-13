using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class Login : BasePage
    {
        protected override string ClaveTitulo
        {
            get { return "login.titulo"; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Mostrar mensaje si viene por query string (p. ej. después de registro)
            var msg = Request.QueryString["msg"];
            if (!string.IsNullOrEmpty(msg))
            {
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = Server.UrlDecode(msg);
            }

        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            var email = txtEmail.Text.Trim();
            var pwd = txtPassword.Text;
            try
            {
                var srv = new SeguridadService();
                var user = srv.Authenticate(email, pwd);
                if (user != null)
                {
                    SesionService.SetUser(user);
                    IdiomaService.Instancia.AplicarPreferenciaDeUsuario(user);
                    var integrity = new IntegrityService();
                    integrity.ValidateAllAndPersist();
                    if (integrity.IsContingencyMode())
                    {
                        Response.Redirect(SesionService.IsWebMaster(user) ? "GestionIntegridad.aspx" : "Mantenimiento.aspx");
                        return;
                    }
                    Response.Redirect("Default.aspx");
                }
                else
                {
                    lblMsg.Text = T("login.msg.credencialesInvalidas");
                }
            }
            catch (Exception ex)
            {
                var integrity = new IntegrityService();
                if (integrity.RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.Text = T("login.msg.errorIniciarSesion") + ": " + ex.Message;
            }
        }
    }
}

