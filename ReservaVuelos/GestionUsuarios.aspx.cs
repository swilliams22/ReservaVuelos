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
    /// <summary>
    /// Pantalla del WebMaster para asignar un perfil (rol) a cada usuario.
    /// </summary>
    public partial class GestionUsuarios : BasePage
    {
        private readonly UsuarioBLL _bll = new UsuarioBLL();
        private List<PermisoItem> _perfiles;

        protected override string ClaveTitulo { get { return "usuarios.titulo"; } }

        private bool PuedeAsignar
        {
            get { return AutorizacionService.TienePermiso(SesionService.GetUser(), Permisos.AsignarRol); }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AutorizacionService.TienePermiso(SesionService.GetUser(), Permisos.VerUsuarios))
            {
                Response.Redirect("Login.aspx");
                return;
            }
            if (!IsPostBack)
                CargarUsuarios();
        }

        private void CargarUsuarios()
        {
            _perfiles = new PerfilBLL().ListarPerfiles();
            gvUsuarios.DataSource = _bll.Listar();
            gvUsuarios.DataBind();
        }

        protected void gvUsuarios_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            Usuario usuario = (Usuario)e.Row.DataItem;
            Usuario actual = SesionService.GetUser();
            bool esUsted = actual != null && actual.IdUsuario == usuario.IdUsuario;
            bool editable = PuedeAsignar && !esUsted;

            Label lblEstado = (Label)e.Row.FindControl("lblEstado");
            lblEstado.Attributes[Traductor.ATRIBUTO] = usuario.Activo ? "usuarios.estado.activo" : "usuarios.estado.inactivo";
            lblEstado.Text = usuario.Activo ? "Activo" : "Inactivo";

            Label lblRol = (Label)e.Row.FindControl("lblRol");
            lblRol.Text = usuario.Rol;
            lblRol.Visible = !editable;
            e.Row.FindControl("lblUsted").Visible = esUsted;

            DropDownList ddlRol = (DropDownList)e.Row.FindControl("ddlRol");
            ddlRol.Visible = editable;
            if (editable)
            {
                foreach (PermisoItem perfil in _perfiles)
                    ddlRol.Items.Add(new ListItem(perfil.Codigo, perfil.Codigo));
                // Si el rol actual no figura (no debería pasar por el trigger) se agrega para no cambiarlo sin querer.
                if (ddlRol.Items.FindByValue(usuario.Rol) == null)
                    ddlRol.Items.Insert(0, new ListItem(usuario.Rol, usuario.Rol));
                ddlRol.SelectedValue = usuario.Rol;
            }

            Button btnAsignar = (Button)e.Row.FindControl("btnAsignar");
            btnAsignar.CommandArgument = usuario.IdUsuario.ToString();
            btnAsignar.Visible = editable;
        }

        protected void gvUsuarios_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Asignar") return;
            AutorizacionService.Exigir(Permisos.AsignarRol);
            lblMsg.Text = "";

            int idUsuario;
            GridViewRow fila = ((Control)e.CommandSource).NamingContainer as GridViewRow;
            if (fila == null || !int.TryParse(Convert.ToString(e.CommandArgument), out idUsuario)) return;
            DropDownList ddlRol = (DropDownList)fila.FindControl("ddlRol");

            try
            {
                _bll.AsignarRol(idUsuario, ddlRol.SelectedValue, SesionService.GetUser());
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = T("usuarios.msg.asignado");
            }
            catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentException)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = ex.Message;
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("usuarios.msg.error") + ": " + ex.Message;
            }
            CargarUsuarios();
        }
    }
}
