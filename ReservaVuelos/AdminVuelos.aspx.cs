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

            if (!IsPostBack)
            {
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
                    var ok = _vBLL.SoftDelete(id);
                    if (ok)
                    {
                        _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Vuelo dado de baja. IdVuelo: {id}", Criticidad = "Media", Pantalla = "AdminVuelos" });
                        BindGrid();
                        lblMsg.ForeColor = System.Drawing.Color.Green;
                        lblMsg.Text = "Vuelo dado de baja correctamente.";
                    }
                    else
                    {
                        lblMsg.Text = "No se encontró el vuelo o ya estaba dado de baja.";
                    }
                }
                catch (Exception ex)
                {
                    lblMsg.Text = "Error: " + ex.Message;
                }
            }
        }

        private void BindGrid()
        {
            var lista = _vBLL.Search(null, null, null);
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
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Vuelo creado. IdVuelo: {idVuelo}", Criticidad = "Media", Pantalla = "AdminVuelos" });
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
