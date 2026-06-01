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
            // Asociar datalist a textboxes para sugerencias.
            txtOrigen.Attributes["list"] = "listaCiudadesBusqueda";
            txtDestino.Attributes["list"] = "listaCiudadesBusqueda";
        }

        private DateTime? ObtenerFechaOpcional(string valor)
        {
            if (string.IsNullOrWhiteSpace(valor))
                return null;

            DateTime fecha;
            if (DateTime.TryParse(valor, out fecha))
                return fecha.Date;

            return null;
        }

        protected void btnBuscar_Click(object sender, EventArgs e)
        {
            lblMsg.ForeColor = System.Drawing.Color.Red;
            lblMsg.Text = "";

            DateTime? fechaIda = ObtenerFechaOpcional(txtFecha.Text);
            DateTime? fechaVuelta = ObtenerFechaOpcional(txtFechaVuelta.Text);

            // Las fechas son opcionales. Solo validamos el orden si ambas fueron informadas.
            if (fechaIda.HasValue && fechaVuelta.HasValue && fechaVuelta.Value.Date <= fechaIda.Value.Date)
            {
                lblMsg.Text = "La fecha de vuelta debe ser posterior a la fecha de ida.";
                return;
            }

            string origen = txtOrigen.Text.Trim();
            string destino = txtDestino.Text.Trim();

            // Si no se cargan filtros, Search devuelve todos los vuelos activos.
            var listaIda = _vBLL.Search(origen, destino, fechaIda, "Activos");
            gvVuelos.DataSource = listaIda;
            gvVuelos.DataBind();

            if (listaIda.Count == 0)
                lblMsg.Text = "No se encontraron vuelos para la búsqueda seleccionada.";

            // Si el usuario selecciona Ida y vuelta, buscar el tramo inverso.
            // La vuelta debe ser posterior a la fecha de ida cuando hay fecha de ida.
            if (ddlTipoViaje != null && ddlTipoViaje.SelectedValue == "IdaVuelta" &&
                !string.IsNullOrWhiteSpace(origen) && !string.IsNullOrWhiteSpace(destino))
            {
                var listaVuelta = _vBLL.Search(
                    destino,
                    origen,
                    fechaVuelta,
                    "Activos",
                    fechaIda
                );

                gvVuelosReturn.Visible = true;
                lblVueltaTitle.Visible = true;
                gvVuelosReturn.DataSource = listaVuelta;
                gvVuelosReturn.DataBind();

                if (listaVuelta.Count == 0)
                    lblMsg.Text = "No se encontraron vuelos de vuelta disponibles.";
            }
            else
            {
                gvVuelosReturn.DataSource = null;
                gvVuelosReturn.DataBind();
                gvVuelosReturn.Visible = false;
                lblVueltaTitle.Visible = false;
            }
        }

        protected void gvVuelos_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Reservar")
            {
                // CommandArgument contiene IdVuelo (ver TemplateField en la .aspx).
                int id = Convert.ToInt32(e.CommandArgument);
                var user = SesionService.GetUser();
                if (user == null)
                {
                    // Debe loguearse.
                    Session["ReturnUrl"] = "BuscarVuelos.aspx";
                    Response.Redirect("Login.aspx");
                    return;
                }

                // Verificar si ya existe reserva activa para este usuario y vuelo.
                if (_rBLL.ExistsActiveReservation(user.IdUsuario, id))
                {
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = "Ya tiene una reserva activa para este vuelo.";
                    return;
                }

                var r = new Reserva
                {
                    IdUsuario = user.IdUsuario,
                    IdVuelo = id,
                    FechaReserva = DateTime.Now,
                    Estado = "Activa"
                };

                try
                {
                    var idReserva = _rBLL.Create(r);
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora
                    {
                        Fecha = DateTime.Now,
                        Usuario = user.Email,
                        Accion = $"Reserva creada. IdReserva: {idReserva} - IdVuelo: {id}",
                        Criticidad = "Info",
                        Pantalla = "BuscarVuelos"
                    });

                    // Actualizar resultados para reflejar cupos y mantener mensaje de éxito.
                    btnBuscar_Click(null, null);
                    lblMsg.ForeColor = System.Drawing.Color.Green;
                    lblMsg.Text = "Reserva creada correctamente.";
                }
                catch (Exception ex)
                {
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = "Error: " + ex.Message;
                }
            }
            else if (e.CommandName == "VerVueltas")
            {
                int idVuelo = Convert.ToInt32(e.CommandArgument);
                Vuelo vueloIda = _vBLL.GetById(idVuelo);

                if (vueloIda == null)
                {
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = "No se pudo obtener el vuelo seleccionado.";
                    return;
                }

                DateTime? fechaVuelta = ObtenerFechaOpcional(txtFechaVuelta.Text);

                // Si el usuario cargó fecha de vuelta, debe ser posterior a la fecha del vuelo de ida seleccionado.
                if (fechaVuelta.HasValue && fechaVuelta.Value.Date <= vueloIda.FechaSalida.Date)
                {
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = "La fecha de vuelta debe ser posterior a la fecha de ida seleccionada.";
                    return;
                }

                var vuelosVuelta = _vBLL.Search(
                    vueloIda.Destino,
                    vueloIda.Origen,
                    fechaVuelta,
                    "Activos",
                    vueloIda.FechaSalida.Date
                );

                gvVuelosReturn.Visible = true;
                lblVueltaTitle.Visible = true;
                gvVuelosReturn.DataSource = vuelosVuelta;
                gvVuelosReturn.DataBind();

                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = vuelosVuelta.Count == 0
                    ? "No se encontraron vuelos de vuelta disponibles."
                    : "";
            }
        }

    }
}
