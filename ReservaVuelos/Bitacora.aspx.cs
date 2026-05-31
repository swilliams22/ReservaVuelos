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
                LoadGrid();
            }
        }

        private void LoadGrid()
        {
            gvBitacora.DataSource = _bBLL.GetAll();
            gvBitacora.DataBind();
        }

        protected void btnFiltrar_Click(object sender, EventArgs e)
        {
            DateTime? desde = null, hasta = null;
            DateTime d;
            if (DateTime.TryParse(txtDesde.Text, out d)) desde = d;
            if (DateTime.TryParse(txtHasta.Text, out d)) hasta = d;
            var usuario = txtUsuarioFiltro.Text.Trim();
            var criticidad = ddlCriticidad.SelectedValue;
            var pantalla = txtPantallaFiltro.Text.Trim();
            var lista = _bBLL.GetByFilters(desde, hasta, usuario, criticidad, pantalla);
            gvBitacora.DataSource = lista;
            gvBitacora.DataBind();
        }

        protected void btnLimpiar_Click(object sender, EventArgs e)
        {
            txtDesde.Text = string.Empty;
            txtHasta.Text = string.Empty;
            txtUsuarioFiltro.Text = string.Empty;
            ddlCriticidad.SelectedIndex = 0;
            txtPantallaFiltro.Text = string.Empty;
            LoadGrid();
        }
    }
}
