using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    public partial class MisReservas : System.Web.UI.Page
    {
        private ReservaBLL _rBLL = new ReservaBLL();
        private BitacoraBLL _bBLL = new BitacoraBLL();

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
                BindGrid(user.IdUsuario);
            }
        }

        private void BindGrid(int idUsuario)
        {
            gvReservas.DataSource = _rBLL.GetByUsuario(idUsuario);
            gvReservas.DataBind();
        }

        protected void gvReservas_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Cancelar")
            {
                // CommandArgument contiene IdReserva (ver TemplateField en la .aspx)
                int id = Convert.ToInt32(e.CommandArgument);
                var user = SesionService.GetUser();
                var ok = _rBLL.Cancel(id);
                if (ok)
                {
                    // Reserva cancelada -> Info
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = $"Reserva cancelada. IdReserva: {id}", Criticidad = "Info", Pantalla = "MisReservas" });
                    BindGrid(user.IdUsuario);
                    lblMsg.ForeColor = System.Drawing.Color.Green;
                    lblMsg.Text = "Reserva cancelada correctamente.";
                }
                else
                {
                    lblMsg.Text = "La reserva ya estaba cancelada.";
                }
            }
        }

        protected void gvReservas_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == System.Web.UI.WebControls.DataControlRowType.DataRow)
            {
                var estado = DataBinder.Eval(e.Row.DataItem, "Estado")?.ToString();
                var btn = e.Row.FindControl("btnCancelar") as System.Web.UI.WebControls.Button;
                if (btn != null && string.Equals(estado, "Cancelada", StringComparison.OrdinalIgnoreCase))
                {
                    btn.Enabled = false;
                    btn.Text = "Cancelada";
                }
            }
        }
    }
}
