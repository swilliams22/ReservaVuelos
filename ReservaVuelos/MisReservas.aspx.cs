using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class MisReservas : BasePage
    {
        protected override string ClaveTitulo
        {
            get { return "misreservas.titulo"; }
        }

        private ReservaCabeceraV2BLL _rBLL = new ReservaCabeceraV2BLL();
        private ClienteBLL _cBLL = new ClienteBLL();
        private PasajeroBLL _pBLL = new PasajeroBLL();

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
                // Mostrar mensaje si viene desde query string
                string msg = Request.QueryString["msg"];
                if (!string.IsNullOrEmpty(msg))
                {
                    lblMsg.ForeColor = System.Drawing.Color.Green;
                    lblMsg.Text = Server.UrlDecode(msg);
                }

                CargarReservas(user.IdUsuario);
            }
        }

        private void CargarReservas(int idUsuario)
        {
            try
            {
                List<ReservaCabecera> todasLasReservas = new List<ReservaCabecera>();

                // 1. Reservas como cliente
                Cliente cliente = _cBLL.GetByIdUsuario(idUsuario);
                if (cliente != null)
                {
                    List<ReservaCabecera> reservasCliente = _rBLL.GetByIdCliente(cliente.IdCliente);
                    todasLasReservas.AddRange(reservasCliente);
                }

                // 2. Reservas como pasajero
                Pasajero pasajero = _pBLL.FindByEmailOrDocumento(
                    SesionService.GetUser()?.Email, 
                    null // Si tienes documento en Usuario, pásalo aquí
                );

                if (pasajero != null && pasajero.IdUsuario.HasValue && pasajero.IdUsuario.Value == idUsuario)
                {
                    List<ReservaCabecera> reservasPasajero = _rBLL.GetByIdPasajero(pasajero.IdPasajero);

                    // Evitar duplicados (si el usuario es cliente Y pasajero en la misma reserva)
                    foreach (ReservaCabecera rp in reservasPasajero)
                    {
                        if (!todasLasReservas.Any(r => r.IdReservaCabecera == rp.IdReservaCabecera))
                        {
                            todasLasReservas.Add(rp);
                        }
                    }
                }

                // Ordenar por fecha descendente
                todasLasReservas = todasLasReservas.OrderByDescending(r => r.FechaReserva).ToList();

                if (todasLasReservas.Count > 0)
                {
                    if (string.IsNullOrEmpty(Request.QueryString["msg"]))
                        lblMsg.Text = string.Empty;

                    rptReservas.DataSource = todasLasReservas;
                    rptReservas.DataBind();
                }
                else
                {
                    lblMsg.ForeColor = System.Drawing.Color.Blue;
                    lblMsg.Text = T("misreservas.msg.sinReservas");
                }
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("misreservas.msg.errorCargar") + ": " + ex.Message;
            }
        }

        // Observer: al cambiar el idioma se vuelve a armar el texto del confirm de cada botón Cancelar.
        public override void ActualizarIdioma(Idioma idioma)
        {
            base.ActualizarIdioma(idioma);
            string confirmar = "return confirm('" + TJs("misreservas.msg.confirmarCancelar") + "');";
            foreach (RepeaterItem item in rptReservas.Items)
            {
                Button btn = item.FindControl("btnCancelar") as Button;
                if (btn != null) btn.OnClientClick = confirmar;
            }
        }

        protected List<ReservaDetalle> GetDetalles(int idReservaCabecera)
        {
            try
            {
                return _rBLL.GetDetalles(idReservaCabecera);
            }
            catch
            {
                return new List<ReservaDetalle>();
            }
        }

        protected List<Pasajero> GetPasajeros(int idReservaCabecera)
        {
            try
            {
                return _rBLL.GetPasajeros(idReservaCabecera);
            }
            catch
            {
                return new List<Pasajero>();
            }
        }

        protected string GetEstadoClass(string estado)
        {
            if (string.Equals(estado, "Activa", StringComparison.OrdinalIgnoreCase))
                return "status-activa";
            if (string.Equals(estado, "Cancelada", StringComparison.OrdinalIgnoreCase))
                return "status-cancelada";
            return "";
        }

        protected void rptReservas_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            AutorizacionService.Exigir(Permisos.CancelarReserva);
            if (e.CommandName == "Cancelar")
            {
                int idReservaCabecera = Convert.ToInt32(e.CommandArgument);
                Usuario user = SesionService.GetUser();

                try
                {
                    bool ok = _rBLL.Cancel(idReservaCabecera, user);
                    if (ok)
                    {
                        lblMsg.ForeColor = System.Drawing.Color.Green;
                        lblMsg.Text = T("misreservas.msg.cancelada");
                        CargarReservas(user.IdUsuario);
                    }
                    else
                    {
                        lblMsg.ForeColor = System.Drawing.Color.Red;
                        lblMsg.Text = T("misreservas.msg.yaCancelada");
                    }
                }
                catch (Exception ex)
                {
                    if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                    lblMsg.ForeColor = System.Drawing.Color.Red;
                    lblMsg.Text = T("misreservas.msg.errorCancelar") + ": " + ex.Message;
                }
            }
        }
    }
}
