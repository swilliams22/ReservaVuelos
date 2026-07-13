using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;

namespace ReservaVuelos
{
    public partial class MisDatos : System.Web.UI.Page
    {
        private readonly ClienteBLL _clienteBLL = new ClienteBLL();
        private readonly PasajeroBLL _pasajeroBLL = new PasajeroBLL();

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
                CargarDatos(user);
            }
        }

        private void CargarDatos(Usuario user)
        {
            var cliente = _clienteBLL.GetByIdUsuario(user.IdUsuario);
            if (cliente != null)
            {
                txtNombreCliente.Text = cliente.Nombre;
                txtEmailCliente.Text = cliente.Email;
                txtDocumentoCliente.Text = cliente.Documento;
                txtTelefonoCliente.Text = cliente.Telefono;
                txtDireccionCliente.Text = cliente.Direccion;
            }
            else
            {
                txtNombreCliente.Text = user.Nombre;
                txtEmailCliente.Text = user.Email;
            }

            var pasajero = _pasajeroBLL.GetByIdUsuario(user.IdUsuario);
            if (pasajero != null)
            {
                txtNombrePasajero.Text = pasajero.Nombre;
                txtApellidoPasajero.Text = pasajero.Apellido;
                txtEmailPasajero.Text = pasajero.Email;
                txtDocumentoPasajero.Text = pasajero.Documento;
                txtNacionalidadPasajero.Text = pasajero.Nacionalidad;
                txtFechaNacimientoPasajero.Text = pasajero.FechaNacimiento.HasValue ? pasajero.FechaNacimiento.Value.ToString("yyyy-MM-dd") : string.Empty;
            }
            else
            {
                txtNombrePasajero.Text = user.Nombre;
                txtEmailPasajero.Text = user.Email;
            }
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            var user = SesionService.GetUser();
            if (user == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            try
            {
                GuardarCliente(user);
                GuardarPasajero(user);

                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = "Datos actualizados correctamente.";
                CargarDatos(user);
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = "Error al guardar datos: " + ex.Message;
            }
        }

        private void GuardarCliente(Usuario user)
        {
            var cliente = _clienteBLL.GetByIdUsuario(user.IdUsuario);
            if (cliente == null)
            {
                cliente = new Cliente
                {
                    IdUsuario = user.IdUsuario,
                    Nombre = txtNombreCliente.Text.Trim(),
                    Email = txtEmailCliente.Text.Trim(),
                    Documento = txtDocumentoCliente.Text.Trim(),
                    Telefono = txtTelefonoCliente.Text.Trim(),
                    Direccion = txtDireccionCliente.Text.Trim()
                };

                _clienteBLL.Create(cliente);
                return;
            }

            cliente.Nombre = txtNombreCliente.Text.Trim();
            cliente.Email = txtEmailCliente.Text.Trim();
            cliente.Documento = txtDocumentoCliente.Text.Trim();
            cliente.Telefono = txtTelefonoCliente.Text.Trim();
            cliente.Direccion = txtDireccionCliente.Text.Trim();
            _clienteBLL.Update(cliente);
        }

        private void GuardarPasajero(Usuario user)
        {
            var pasajero = _pasajeroBLL.GetByIdUsuario(user.IdUsuario);
            DateTime fechaNacimiento;
            DateTime? fecha = null;
            if (DateTime.TryParse(txtFechaNacimientoPasajero.Text, out fechaNacimiento))
                fecha = fechaNacimiento;

            if (pasajero == null)
            {
                var documento = txtDocumentoPasajero.Text.Trim();
                if (!string.IsNullOrWhiteSpace(documento))
                {
                    pasajero = _pasajeroBLL.GetByDocumento(documento);
                    if (pasajero != null && !pasajero.IdUsuario.HasValue)
                    {
                        _pasajeroBLL.VincularConUsuario(pasajero.IdPasajero, user.IdUsuario);
                        pasajero = _pasajeroBLL.GetByIdUsuario(user.IdUsuario);
                    }
                }
            }

            if (pasajero == null)
            {
                pasajero = new Pasajero
                {
                    IdUsuario = user.IdUsuario,
                    Nombre = txtNombrePasajero.Text.Trim(),
                    Apellido = txtApellidoPasajero.Text.Trim(),
                    Email = txtEmailPasajero.Text.Trim(),
                    Documento = txtDocumentoPasajero.Text.Trim(),
                    Nacionalidad = txtNacionalidadPasajero.Text.Trim(),
                    FechaNacimiento = fecha
                };

                _pasajeroBLL.Create(pasajero);
                return;
            }

            pasajero.Nombre = txtNombrePasajero.Text.Trim();
            pasajero.Apellido = txtApellidoPasajero.Text.Trim();
            pasajero.Email = txtEmailPasajero.Text.Trim();
            pasajero.Documento = txtDocumentoPasajero.Text.Trim();
            pasajero.Nacionalidad = txtNacionalidadPasajero.Text.Trim();
            pasajero.FechaNacimiento = fecha;
            _pasajeroBLL.Update(pasajero);
        }
    }
}
