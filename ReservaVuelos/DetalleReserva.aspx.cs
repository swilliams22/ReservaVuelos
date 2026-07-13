using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class DetalleReserva : System.Web.UI.Page
    {
        private VueloBLL _vBLL = new VueloBLL();
        private ClienteBLL _cBLL = new ClienteBLL();
        private PasajeroBLL _pBLL = new PasajeroBLL();
        private ReservaCabeceraV2BLL _rBLL = new ReservaCabeceraV2BLL();

        private List<Vuelo> VuelosSeleccionados
        {
            get { return Session["VuelosSeleccionados"] as List<Vuelo> ?? new List<Vuelo>(); }
            set { Session["VuelosSeleccionados"] = value; }
        }

        private List<Pasajero> PasajerosTemporal
        {
            get { return Session["PasajerosTemporal"] as List<Pasajero> ?? new List<Pasajero>(); }
            set { Session["PasajerosTemporal"] = value; }
        }

        private int CantidadPasajerosDeclarada
        {
            get { return Session["CantidadPasajerosDeclarada"] != null ? (int)Session["CantidadPasajerosDeclarada"] : 0; }
            set { Session["CantidadPasajerosDeclarada"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            if (user == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                var idVueloStr = Request.QueryString["IdVuelo"];
                var cantidadPasajerosStr = Request.QueryString["CantidadPasajeros"];

                int idVuelo;
                int cantidadPasajeros;
                if (!int.TryParse(idVueloStr, out idVuelo) || !int.TryParse(cantidadPasajerosStr, out cantidadPasajeros) || cantidadPasajeros < 1)
                {
                    Response.Redirect("BuscarVuelos.aspx");
                    return;
                }

                var vuelo = _vBLL.GetById(idVuelo);
                if (vuelo == null || !vuelo.Activo || vuelo.CuposDisponibles < cantidadPasajeros || vuelo.FechaHoraSalida <= DateTime.Now)
                {
                    Response.Redirect("BuscarVuelos.aspx");
                    return;
                }

                VuelosSeleccionados = new List<Vuelo> { vuelo };
                CantidadPasajerosDeclarada = cantidadPasajeros;
                PasajerosTemporal = new List<Pasajero>();

                lblNombreCliente.Text = user.Nombre;
                lblEmailCliente.Text = user.Email;
                lblCantidadPasajeros.Text = cantidadPasajeros.ToString();

                CargarVuelos();
                CargarPasajeros();
                ActualizarMontoTotal();
            }
        }

        private void CargarVuelos()
        {
            gvVuelosSeleccionados.DataSource = VuelosSeleccionados.Select(v => new
            {
                v.Origen,
                v.Destino,
                v.FechaSalida,
                v.HoraSalida,
                Precio = v.Precio.ToString("C")
            }).ToList();
            gvVuelosSeleccionados.DataBind();
        }

        private void CargarPasajeros()
        {
            gvPasajeros.DataSource = PasajerosTemporal;
            gvPasajeros.DataBind();
            lblCantidadActualPasajeros.Text = string.Format("{0} de {1}", PasajerosTemporal.Count, CantidadPasajerosDeclarada);
        }

        private void ActualizarMontoTotal()
        {
            var cantidad = CantidadPasajerosDeclarada;
            var total = VuelosSeleccionados.Sum(v => v.Precio * cantidad);
            lblMontoTotal.Text = total.ToString("C");
        }

        protected void btnAgregarPasajero_Click(object sender, EventArgs e)
        {
            lblMsg.Text = string.Empty;
            lblMsg.ForeColor = System.Drawing.Color.Red;

            var nombre = txtNombrePasajero.Text.Trim();
            var apellido = txtApellidoPasajero.Text.Trim();
            var documento = txtDocumentoPasajero.Text.Trim();
            var email = txtEmailPasajero.Text.Trim();
            var nacionalidad = txtNacionalidadPasajero.Text.Trim();

            if (string.IsNullOrWhiteSpace(nombre))
            {
                lblMsg.Text = "El nombre del pasajero es requerido.";
                return;
            }

            if (string.IsNullOrWhiteSpace(documento))
            {
                lblMsg.Text = "El documento del pasajero es requerido.";
                return;
            }

            if (PasajerosTemporal.Any(p => string.Equals(p.Documento, documento, StringComparison.OrdinalIgnoreCase)))
            {
                lblMsg.Text = "Ya existe un pasajero con ese documento en la lista.";
                return;
            }

            if (PasajerosTemporal.Count >= CantidadPasajerosDeclarada)
            {
                lblMsg.Text = "Ya alcanzó la cantidad de pasajeros declarada para esta reserva.";
                return;
            }

            DateTime? fechaNacimiento = null;
            if (!string.IsNullOrWhiteSpace(txtFechaNacimientoPasajero.Text))
            {
                DateTime fecha;
                if (DateTime.TryParse(txtFechaNacimientoPasajero.Text, out fecha))
                    fechaNacimiento = fecha;
            }

            PasajerosTemporal.Add(new Pasajero
            {
                Nombre = nombre,
                Apellido = apellido,
                Documento = documento,
                Email = string.IsNullOrWhiteSpace(email) ? null : email,
                Nacionalidad = string.IsNullOrWhiteSpace(nacionalidad) ? null : nacionalidad,
                FechaNacimiento = fechaNacimiento
            });

            txtNombrePasajero.Text = string.Empty;
            txtApellidoPasajero.Text = string.Empty;
            txtDocumentoPasajero.Text = string.Empty;
            txtEmailPasajero.Text = string.Empty;
            txtNacionalidadPasajero.Text = string.Empty;
            txtFechaNacimientoPasajero.Text = string.Empty;

            CargarPasajeros();
            ActualizarMontoTotal();
            lblMsg.ForeColor = System.Drawing.Color.Green;
            lblMsg.Text = "Pasajero agregado correctamente.";
        }

        protected void gvPasajeros_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Eliminar")
            {
                var documento = e.CommandArgument.ToString();
                var pasajero = PasajerosTemporal.FirstOrDefault(p => p.Documento == documento);
                if (pasajero != null)
                {
                    PasajerosTemporal.Remove(pasajero);
                    CargarPasajeros();
                    ActualizarMontoTotal();
                    lblMsg.ForeColor = System.Drawing.Color.Green;
                    lblMsg.Text = "Pasajero eliminado.";
                }
            }
        }

        protected void btnConfirmar_Click(object sender, EventArgs e)
        {
            lblMsg.Text = string.Empty;
            lblMsg.ForeColor = System.Drawing.Color.Red;

            var user = SesionService.GetUser();
            if (user == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (CantidadPasajerosDeclarada < 1)
            {
                lblMsg.Text = "La cantidad de pasajeros declarada es inválida.";
                return;
            }

            if (PasajerosTemporal.Count != CantidadPasajerosDeclarada)
            {
                lblMsg.Text = string.Format("Debe cargar exactamente {0} pasajero(s) para continuar.", CantidadPasajerosDeclarada);
                return;
            }

            try
            {
                var documentoCliente = txtDocumentoCliente.Text.Trim();
                var cliente = _cBLL.GetOrCreateByUsuario(user.IdUsuario, user.Nombre, user.Email, documentoCliente);

                var pasajerosConId = new List<Pasajero>();
                foreach (var pasajeroTemporal in PasajerosTemporal)
                {
                    var pasajeroExistente = _pBLL.GetByDocumento(pasajeroTemporal.Documento);
                    if (pasajeroExistente != null)
                    {
                        pasajeroExistente.Nombre = pasajeroTemporal.Nombre;
                        pasajeroExistente.Apellido = pasajeroTemporal.Apellido;
                        pasajeroExistente.Email = pasajeroTemporal.Email;
                        pasajeroExistente.Nacionalidad = pasajeroTemporal.Nacionalidad;
                        pasajeroExistente.FechaNacimiento = pasajeroTemporal.FechaNacimiento;
                        _pBLL.Update(pasajeroExistente);
                        pasajerosConId.Add(pasajeroExistente);
                    }
                    else
                    {
                        pasajeroTemporal.IdPasajero = _pBLL.Create(pasajeroTemporal);
                        pasajerosConId.Add(pasajeroTemporal);
                    }
                }

                var detalles = VuelosSeleccionados.Select(v => new ReservaDetalle
                {
                    IdVuelo = v.IdVuelo,
                    Cantidad = CantidadPasajerosDeclarada,
                    PrecioUnitario = v.Precio,
                    SubTotal = v.Precio * CantidadPasajerosDeclarada,
                    Estado = "Activo"
                }).ToList();

                _rBLL.CreateWithDetails(cliente.IdCliente, detalles, pasajerosConId, user);

                Session.Remove("VuelosSeleccionados");
                Session.Remove("PasajerosTemporal");
                Session.Remove("CantidadPasajerosDeclarada");

                Response.Redirect("MisReservas.aspx?msg=" + Server.UrlEncode("Reserva creada exitosamente."));
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.Text = "Error al crear la reserva: " + ex.Message;
            }
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            Session.Remove("VuelosSeleccionados");
            Session.Remove("PasajerosTemporal");
            Session.Remove("CantidadPasajerosDeclarada");
            Response.Redirect("BuscarVuelos.aspx");
        }
    }
}
