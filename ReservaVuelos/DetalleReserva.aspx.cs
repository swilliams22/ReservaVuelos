using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class DetalleReserva : BasePage
    {
        protected override string ClaveTitulo
        {
            get { return "detallereserva.tituloPagina"; }
        }

        private VueloBLL _vBLL = new VueloBLL();
        private ClienteBLL _cBLL = new ClienteBLL();
        private PasajeroBLL _pBLL = new PasajeroBLL();
        private ReservaCabeceraV2BLL _rBLL = new ReservaCabeceraV2BLL();

        // Observer: el texto del confirm del botón se arma en el idioma vigente.
        public override void ActualizarIdioma(Idioma idioma)
        {
            base.ActualizarIdioma(idioma);
            btnConfirmar.OnClientClick = "return confirm('" + TJs("detallereserva.msg.confirmar") + "');";
        }

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
            Usuario user = SesionService.GetUser();
            if (user == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                string idVueloStr = Request.QueryString["IdVuelo"];
                string cantidadPasajerosStr = Request.QueryString["CantidadPasajeros"];

                int idVuelo;
                int cantidadPasajeros;
                if (!int.TryParse(idVueloStr, out idVuelo) || !int.TryParse(cantidadPasajerosStr, out cantidadPasajeros) || cantidadPasajeros < 1)
                {
                    Response.Redirect("BuscarVuelos.aspx");
                    return;
                }

                Vuelo vuelo = _vBLL.GetById(idVuelo);
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
            lblCantidadActualPasajeros.Text = string.Format(T("detallereserva.fmt.cantidadDe"), PasajerosTemporal.Count, CantidadPasajerosDeclarada);
        }

        private void ActualizarMontoTotal()
        {
            int cantidad = CantidadPasajerosDeclarada;
            decimal total;
            try
            {
                // El cálculo lo hace el web service (AeroLinkWS.CalcularPrecioReserva).
                AeroLinkServiceReference.ArrayOfInt ids = new AeroLinkServiceReference.ArrayOfInt();
                ids.AddRange(VuelosSeleccionados.Select(v => v.IdVuelo));
                ReservaVuelos.AeroLinkServiceReference.CalculoReserva calculo = AeroLinkCliente.Llamar(c => c.CalcularPrecioReserva(ids, cantidad));
                if (!calculo.Valido)
                    throw new InvalidOperationException(calculo.Mensaje);
                total = calculo.Total;
            }
            catch (Exception)
            {
                // Si el servicio no responde, la pantalla sigue funcionando con el cálculo local.
                total = VuelosSeleccionados.Sum(v => v.Precio * cantidad);
            }
            lblMontoTotal.Text = total.ToString("C");
        }

        protected void btnAgregarPasajero_Click(object sender, EventArgs e)
        {
            lblMsg.Text = string.Empty;
            lblMsg.ForeColor = System.Drawing.Color.Red;

            string nombre = txtNombrePasajero.Text.Trim();
            string apellido = txtApellidoPasajero.Text.Trim();
            string documento = txtDocumentoPasajero.Text.Trim();
            string email = txtEmailPasajero.Text.Trim();
            string nacionalidad = txtNacionalidadPasajero.Text.Trim();

            if (string.IsNullOrWhiteSpace(nombre))
            {
                lblMsg.Text = T("detallereserva.msg.nombreRequerido");
                return;
            }

            if (string.IsNullOrWhiteSpace(documento))
            {
                lblMsg.Text = T("detallereserva.msg.documentoRequerido");
                return;
            }

            if (PasajerosTemporal.Any(p => string.Equals(p.Documento, documento, StringComparison.OrdinalIgnoreCase)))
            {
                lblMsg.Text = T("detallereserva.msg.documentoDuplicado");
                return;
            }

            if (PasajerosTemporal.Count >= CantidadPasajerosDeclarada)
            {
                lblMsg.Text = T("detallereserva.msg.cantidadAlcanzada");
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
            lblMsg.Text = T("detallereserva.msg.pasajeroAgregado");
        }

        protected void gvPasajeros_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Eliminar")
            {
                string documento = e.CommandArgument.ToString();
                Pasajero pasajero = PasajerosTemporal.FirstOrDefault(p => p.Documento == documento);
                if (pasajero != null)
                {
                    PasajerosTemporal.Remove(pasajero);
                    CargarPasajeros();
                    ActualizarMontoTotal();
                    lblMsg.ForeColor = System.Drawing.Color.Green;
                    lblMsg.Text = T("detallereserva.msg.pasajeroEliminado");
                }
            }
        }

        protected void btnConfirmar_Click(object sender, EventArgs e)
        {
            lblMsg.Text = string.Empty;
            lblMsg.ForeColor = System.Drawing.Color.Red;

            Usuario user = SesionService.GetUser();
            if (user == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (CantidadPasajerosDeclarada < 1)
            {
                lblMsg.Text = T("detallereserva.msg.cantidadInvalida");
                return;
            }

            if (PasajerosTemporal.Count != CantidadPasajerosDeclarada)
            {
                lblMsg.Text = string.Format(T("detallereserva.msg.cantidadExacta"), CantidadPasajerosDeclarada);
                return;
            }

            try
            {
                string documentoCliente = txtDocumentoCliente.Text.Trim();
                Cliente cliente = _cBLL.GetOrCreateByUsuario(user.IdUsuario, user.Nombre, user.Email, documentoCliente);

                List<Pasajero> pasajerosConId = new List<Pasajero>();
                foreach (Pasajero pasajeroTemporal in PasajerosTemporal)
                {
                    // Se busca por Documento O por Email: si se buscara solo por Documento,
                    // un pasajero nuevo que reutiliza un Email ya registrado en otro
                    // pasajero terminaria intentando un INSERT que choca contra el indice
                    // unico IX_Pasajeros_Email_Unique.
                    Pasajero pasajeroExistente = _pBLL.FindByEmailOrDocumento(pasajeroTemporal.Email, pasajeroTemporal.Documento);
                    if (pasajeroExistente != null)
                    {
                        pasajeroExistente.Nombre = pasajeroTemporal.Nombre;
                        pasajeroExistente.Apellido = pasajeroTemporal.Apellido;
                        pasajeroExistente.Email = pasajeroTemporal.Email;
                        pasajeroExistente.Documento = pasajeroTemporal.Documento;
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

                List<ReservaDetalle> detalles = VuelosSeleccionados.Select(v => new ReservaDetalle
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

                Response.Redirect("MisReservas.aspx?msg=" + Server.UrlEncode(T("detallereserva.msg.reservaCreada")));
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.Text = T("detallereserva.msg.errorCrear") + ": " + ex.Message;
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
