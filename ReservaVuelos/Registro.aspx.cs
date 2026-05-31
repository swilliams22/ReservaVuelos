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
            var nombre = txtNombre.Text.Trim();
            var email = txtEmail.Text.Trim();
            var pwd = txtPassword.Text;

            string msg;
            if (!PasswordPolicyService.Validate(pwd, out msg))
            {
                lblMsg.Text = msg;
                return;
            }

            var usuario = new BE.Usuario
            {
                Nombre = nombre,
                Email = email,
                Rol = "Usuario"
            };

            var srv = new SeguridadService();
            try
            {
                var id = srv.RegistrarUsuario(usuario, pwd);
                // redirigir a login mostrando mensaje
                Response.Redirect("Login.aspx?msg=" + Server.UrlEncode("Usuario creado correctamente. Inicie sesión."));
            }
            catch (Exception ex)
            {
                lblMsg.Text = "Error al registrar: " + ex.Message;
            }
        }
    }
}
