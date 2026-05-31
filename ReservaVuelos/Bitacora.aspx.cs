using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class Bitacora : System.Web.UI.Page
    {
        private BitacoraBLL _bBLL = new BitacoraBLL();
        protected void Page_Load(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            if (user == null || user.Rol != "Administrador")
            {
                Response.Redirect("Login.aspx");
                return;
            }
            if (!IsPostBack)
            {
                gvBitacora.DataSource = _bBLL.GetAll();
                gvBitacora.DataBind();
            }
        }
    }
}
