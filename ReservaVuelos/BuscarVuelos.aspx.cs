using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class BuscarVuelos : System.Web.UI.Page
    {
        private VueloBLL _vBLL = new VueloBLL();
        private ReservaBLL _rBLL = new ReservaBLL();
        private BitacoraBLL _bBLL = new BitacoraBLL();

        protected void Page_Load(object sender, EventArgs e)
        {
            // asociar datalist a textboxes para sugerencias
            txtOrigen.Attributes["list"] = "listaCiudadesBusqueda";
            txtDestino.Attributes["list"] = "listaCiudadesBusqueda";
        }

        protected void btnBuscar_Click(object sender, EventArgs e)
        {
            DateTime? fecha = null;
            DateTime? fechaVuelta = null;
            if (!string.IsNullOrWhiteSpace(txtFecha.Text))
            {
                DateTime f;
                if (DateTime.TryParse(txtFecha.Text, out f)) fecha = f;
            }
            if (!string.IsNullOrWhiteSpace(txtFechaVuelta.Text))
            {
                DateTime fv;
                if (DateTime.TryParse(txtFechaVuelta.Text, out fv)) fechaVuelta = fv;
            }

            // Si es ida y vuelta validar fechas
            if (ddlTipoViaje != null && ddlTipoViaje.SelectedValue == "IdaVuelta")
            {
                if (!fecha.HasValue || !fechaVuelta.HasValue)
                {
                    lblMsg.Text = "Ingrese fechas de ida y vuelta.";
                    return;
                }
                if (fechaVuelta.Value.Date < fecha.Value.Date)
                {
                    lblMsg.Text = "La fecha de vuelta no puede ser anterior a la fecha de ida.";
                    return;
                }
            }

            var lista = _vBLL.Search(txtOrigen.Text.Trim(), txtDestino.Text.Trim(), fecha);
            gvVuelos.DataSource = lista;
            gvVuelos.DataBind();

            // Si es ida y vuelta y hay fecha vuelta, mostrar sugerencias para la vuelta (origen/destino invertidos)
            if (ddlTipoViaje != null && ddlTipoViaje.SelectedValue == "IdaVuelta" && fechaVuelta.HasValue)
            {
                var listaReturn = _vBLL.Search(txtDestino.Text.Trim(), txtOrigen.Text.Trim(), fechaVuelta);
                gvVuelosReturn.Visible = true;
                lblVueltaTitle.Visible = true;
                gvVuelosReturn.DataSource = listaReturn;
                gvVuelosReturn.DataBind();
            }
            else
            {
                gvVuelosReturn.Visible = false;
                lblVueltaTitle.Visible = false;
            }
        }

        protected void gvVuelos_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Reservar")
            {
                // CommandArgument contiene IdVuelo (ver TemplateField en la .aspx)
                int id = Convert.ToInt32(e.CommandArgument);
                var user = SesionService.GetUser();
                if (user == null)
                {
                    // debe loguearse
                    Session["ReturnUrl"] = "BuscarVuelos.aspx";
                    Response.Redirect("Login.aspx");
                    return;
                }
                // verificar si ya existe reserva activa para este usuario y vuelo
                if (_rBLL.ExistsActiveReservation(user.IdUsuario, id))
                {
                    lblMsg.Text = "Ya tiene una reserva activa para este vuelo.";
                    return;
                }

                // crear reserva
                var r = new Reserva { IdUsuario = user.IdUsuario, IdVuelo = id, FechaReserva = DateTime.Now, Estado = "Activa" };
                try
                {
                    var idReserva = _rBLL.Create(r);
                    // Reserva creada -> Info
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = $"Reserva creada. IdReserva: {idReserva} - IdVuelo: {id}", Criticidad = "Info", Pantalla = "BuscarVuelos" });
                    lblMsg.ForeColor = System.Drawing.Color.Green;
                    lblMsg.Text = "Reserva creada correctamente.";
                    // actualizar resultados de búsqueda para reflejar cupos
                    btnBuscar_Click(null, null);
                }
                catch (Exception ex)
                {
                    lblMsg.Text = "Error: " + ex.Message;
                }
            }
        }
    }
}
