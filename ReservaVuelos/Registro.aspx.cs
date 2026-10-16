using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class Registro : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnRegister_Click(object sender, EventArgs e)
        {
            string nombre = txtNombre.Text.Trim();
            string email = txtEmail.Text.Trim();
            string pwd = txtPassword.Text;

            string msg;
            if (!PasswordPolicyService.Validate(pwd, out msg))
            {
                lblMsg.Text = msg;
                return;
            }

            BE.Usuario usuario = new BE.Usuario
            {
                Nombre = nombre,
                Email = email,
                Rol = "Usuario"
            };

            SeguridadService srv = new SeguridadService();
            try
            {
                int id = srv.RegistrarUsuario(usuario, pwd);
                // redirigir a login mostrando mensaje
                Response.Redirect("Login.aspx?msg=" + Server.UrlEncode("Usuario creado correctamente. Inicie sesión."));
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.Text = "Error al registrar: " + ex.Message;
            }
        }
    }
}

