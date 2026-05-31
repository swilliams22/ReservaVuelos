using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Globalization;
using System.Linq;

namespace ReservaVuelos
{
    public partial class AdminVuelos : System.Web.UI.Page
    {
        private VueloBLL _vBLL = new VueloBLL();
        private BitacoraBLL _bBLL = new BitacoraBLL();

        protected void Page_Load(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            if (user == null || user.Rol != "Administrador")
            {
                Response.Redirect("Login.aspx");
                return;
            }

            // asociar datalist a textboxes para sugerencias
            txtOrigen.Attributes["list"] = "listaCiudades";
            txtDestino.Attributes["list"] = "listaCiudades";

            if (!IsPostBack)
            {
                // cargar grilla según filtro (por defecto Activos)
                BindGrid();
            }
        }

        protected void gvVuelosAdmin_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Baja")
            {
                int id = Convert.ToInt32(e.CommandArgument);
                try
                {
                    var canceledCount = _vBLL.SoftDelete(id);
                    if (canceledCount >= 0)
                    {
                    // Baja de vuelo -> Info
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Vuelo dado de baja. IdVuelo: {id}", Criticidad = "Info", Pantalla = "AdminVuelos" });
                        if (canceledCount > 0)
                        {
                            // Cancelaciones por baja de vuelo -> Info
                            _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Reservas canceladas por baja de vuelo. IdVuelo: {id} - Cantidad: {canceledCount}", Criticidad = "Info", Pantalla = "AdminVuelos" });
                        }
                        BindGrid();
                        lblMsg.ForeColor = System.Drawing.Color.Green;
                        lblMsg.Text = "Vuelo dado de baja correctamente." + (canceledCount > 0 ? (" Reservas canceladas: " + canceledCount) : string.Empty);
                    }
                    else
                    {
                        lblMsg.Text = "No se encontró el vuelo.";
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = "Error: " + ex.Message;
                }
            }
        }

        protected void ddlFiltro_SelectedIndexChanged(object sender, EventArgs e)
        {
            BindGrid();
        }

        private void BindGrid()
        {
            var filtro = "Activos";
            if (ddlFiltro != null) filtro = ddlFiltro.SelectedValue;
            var lista = _vBLL.Search(null, null, null, filtro);
            gvVuelosAdmin.DataSource = lista;
            gvVuelosAdmin.DataBind();
        }

        protected void btnCrear_Click(object sender, EventArgs e)
        {
            try
            {
                var v = new Vuelo
                {
                    Origen = txtOrigen.Text.Trim(),
                    Destino = txtDestino.Text.Trim(),
                    FechaSalida = DateTime.Parse(txtFecha.Text, CultureInfo.InvariantCulture),
                    HoraSalida = TimeSpan.Parse(txtHora.Text),
                    Precio = decimal.Parse(txtPrecio.Text),
                    CuposDisponibles = int.Parse(txtCupos.Text),
                    Activo = true
                };
                var idVuelo = _vBLL.Create(v);
                // Creación de vuelo -> Info
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Vuelo creado. IdVuelo: {idVuelo}", Criticidad = "Info", Pantalla = "AdminVuelos" });
                BindGrid();
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = "Vuelo creado.";
            }
            catch (Exception ex)
            {
                lblMsg.Text = "Error: " + ex.Message;
            }
        }
    }
}
