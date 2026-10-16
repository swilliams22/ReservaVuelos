using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class Bitacora : System.Web.UI.Page
    {
        private BitacoraBLL _bBLL = new BitacoraBLL();
        protected void Page_Load(object sender, EventArgs e)
        {
            ReservaVuelos.BE.Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerBitacora))
            {
                Response.Redirect("Login.aspx");
                return;
            }
            if (!IsPostBack)
            {
                LoadGrid();
            }
        }

        // Filtros vigentes: se guardan en ViewState para que el paginado respete el filtro aplicado.
        private DateTime? Desde { get { return ViewState["Desde"] as DateTime?; } set { ViewState["Desde"] = value; } }
        private DateTime? Hasta { get { return ViewState["Hasta"] as DateTime?; } set { ViewState["Hasta"] = value; } }
        private string UsuarioFiltro { get { return ViewState["Usuario"] as string; } set { ViewState["Usuario"] = value; } }
        private int? Criticidad { get { return ViewState["Criticidad"] as int?; } set { ViewState["Criticidad"] = value; } }
        private string PantallaFiltro { get { return ViewState["Pantalla"] as string; } set { ViewState["Pantalla"] = value; } }

        private void LoadGrid()
        {
            List<ReservaVuelos.BE.Bitacora> lista = _bBLL.GetByFilters(Desde, Hasta, UsuarioFiltro, Criticidad, PantallaFiltro);
            gvBitacora.DataSource = lista;
            gvBitacora.DataBind();
        }

        protected void btnFiltrar_Click(object sender, EventArgs e)
        {
            DateTime d;
            Desde = DateTime.TryParse(txtDesde.Text, out d) ? (DateTime?)d : null;
            Hasta = DateTime.TryParse(txtHasta.Text, out d) ? (DateTime?)d : null;
            UsuarioFiltro = txtUsuarioFiltro.Text.Trim();
            int criticidadParsed;
            Criticidad = int.TryParse(ddlCriticidad.SelectedValue, out criticidadParsed) ? (int?)criticidadParsed : null;
            PantallaFiltro = txtPantallaFiltro.Text.Trim();
            gvBitacora.PageIndex = 0;
            LoadGrid();
        }

        protected void gvBitacora_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvBitacora.PageIndex = e.NewPageIndex;
            LoadGrid();
        }

        protected void btnLimpiar_Click(object sender, EventArgs e)
        {
            txtDesde.Text = string.Empty;
            txtHasta.Text = string.Empty;
            txtUsuarioFiltro.Text = string.Empty;
            ddlCriticidad.SelectedIndex = 0;
            txtPantallaFiltro.Text = string.Empty;
            Desde = null;
            Hasta = null;
            UsuarioFiltro = null;
            Criticidad = null;
            PantallaFiltro = null;
            gvBitacora.PageIndex = 0;
            LoadGrid();
        }
    }
}
