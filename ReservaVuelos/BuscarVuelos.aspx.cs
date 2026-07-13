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
        private BitacoraBLL _bBLL = new BitacoraBLL();

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                new IntegrityService().EnsureTableIsValid("Vuelos");
            }
            catch
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                throw;
            }

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

        private int? ObtenerCantidadPasajeros()
        {
            if (string.IsNullOrWhiteSpace(txtCantidadPasajeros.Text))
                return null;

            int cantidad;
            if (!int.TryParse(txtCantidadPasajeros.Text, out cantidad))
                return null;

            return cantidad;
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

            var cantidadPasajeros = ObtenerCantidadPasajeros();
            if (!cantidadPasajeros.HasValue || cantidadPasajeros.Value < 1)
            {
                lblMsg.Text = "Debe indicar una cantidad de pasajeros válida.";
                return;
            }

            string origen = txtOrigen.Text.Trim();
            string destino = txtDestino.Text.Trim();

            // Si no se cargan filtros, Search devuelve todos los vuelos activos.
            var listaIda = _vBLL.Search(origen, destino, fechaIda, "Activos");
            listaIda = listaIda.FindAll(v => v.CuposDisponibles >= cantidadPasajeros.Value);
            gvVuelos.DataSource = listaIda;
            gvVuelos.DataBind();

            if (listaIda.Count == 0)
                lblMsg.Text = "No se encontraron vuelos para la búsqueda seleccionada.";

            // Si el usuario selecciona Ida y vuelta, buscar el tramo inverso.
            // La vuelta debe ser posterior a la fecha de ida cuando hay fecha de ida.
            if (rbIdaVuelta.Checked &&
                !string.IsNullOrWhiteSpace(origen) && !string.IsNullOrWhiteSpace(destino))
            {
                var listaVuelta = _vBLL.Search(
                    destino,
                    origen,
                    fechaVuelta,
                    "Activos",
                    fechaIda
                );
                listaVuelta = listaVuelta.FindAll(v => v.CuposDisponibles >= cantidadPasajeros.Value);

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
                int id = Convert.ToInt32(e.CommandArgument);
                var user = SesionService.GetUser();
                if (user == null)
                {
                    Session["ReturnUrl"] = "BuscarVuelos.aspx";
                    Response.Redirect("Login.aspx");
                    return;
                }

                var cantidadPasajeros = ObtenerCantidadPasajeros();
                if (!cantidadPasajeros.HasValue || cantidadPasajeros.Value < 1)
                {
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = "Debe indicar una cantidad de pasajeros válida.";
                    return;
                }

                Response.Redirect($"DetalleReserva.aspx?IdVuelo={id}&CantidadPasajeros={cantidadPasajeros.Value}");
                return;
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

                var cantidadPasajeros = ObtenerCantidadPasajeros();
                if (!cantidadPasajeros.HasValue || cantidadPasajeros.Value < 1)
                {
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = "Debe indicar una cantidad de pasajeros válida.";
                    return;
                }

                var vuelosVuelta = _vBLL.Search(
                    vueloIda.Destino,
                    vueloIda.Origen,
                    fechaVuelta,
                    "Activos",
                    vueloIda.FechaSalida.Date
                );
                vuelosVuelta = vuelosVuelta.FindAll(v => v.CuposDisponibles >= cantidadPasajeros.Value);

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

