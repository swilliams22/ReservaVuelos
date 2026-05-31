using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class Login : System.Web.UI.Page
    {
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
            var srv = new SeguridadService();
            var user = srv.Authenticate(email, pwd);
            if (user != null)
            {
                SesionService.SetUser(user);
                Response.Redirect("Default.aspx");
            }
            else
            {
                lblMsg.Text = "Usuario o contraseña incorrectos.";
            }
        }
    }
}
