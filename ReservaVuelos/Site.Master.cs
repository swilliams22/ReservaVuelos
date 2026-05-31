using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Mostrar/ocultar elementos del menú según sesión y rol
            var user = Session["User"] as BE.Usuario;
            if (menuMisReservas != null) menuMisReservas.Visible = user != null;
            if (menuLogin != null) menuLogin.Visible = user == null;
            if (menuRegistro != null) menuRegistro.Visible = user == null;
            if (menuLogout != null) menuLogout.Visible = user != null;
            if (menuAdmin != null) menuAdmin.Visible = user != null && user.Rol == "Administrador";
            if (menuBitacora != null) menuBitacora.Visible = user != null && user.Rol == "Administrador";
        }
    }
}