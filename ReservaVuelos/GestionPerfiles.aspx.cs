using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    /// <summary>
    /// Pantalla del WebMaster para crear perfiles (grupos del Composite) y asignarles
    /// permisos simples u otros perfiles. Los permisos simples no se crean desde acá.
    /// </summary>
    public partial class GestionPerfiles : BasePage
    {
        private readonly PerfilBLL _bll = new PerfilBLL();

        protected override string ClaveTitulo { get { return "perfiles.titulo"; } }

        private bool PuedeEditar
        {
            get { return AutorizacionService.TienePermiso(SesionService.GetUser(), Permisos.EditarPerfiles); }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!AutorizacionService.TienePermiso(SesionService.GetUser(), Permisos.VerPerfiles))
            {
                Response.Redirect("Login.aspx");
                return;
            }
            pnlNuevo.Visible = PuedeEditar;
            if (!IsPostBack)
                CargarPerfiles();
            else if (pnlDetalle.Visible)
                CargarArbol();   // el árbol no guarda ViewState: se vuelve a armar en cada postback
        }

        // ---------- Lista de perfiles ----------

        private void CargarPerfiles()
        {
            gvPerfiles.DataSource = _bll.ListarPerfiles();
            gvPerfiles.DataBind();
        }

        protected void gvPerfiles_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            PermisoItem perfil = (PermisoItem)e.Row.DataItem;
            string id = perfil.IdPermiso.ToString();

            ((Button)e.Row.FindControl("btnVer")).CommandArgument = id;
            Button btnEliminar = (Button)e.Row.FindControl("btnEliminar");
            btnEliminar.CommandArgument = id;
            // Un perfil asignado a usuarios no se puede eliminar (también lo valida PerfilBLL).
            btnEliminar.Visible = PuedeEditar && perfil.CantidadUsuarios == 0;
            btnEliminar.OnClientClick = "return confirm('" + HttpUtility.JavaScriptStringEncode(T("perfiles.msg.confirmarEliminar")) + "');";
        }

        protected void gvPerfiles_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            int idPerfil;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out idPerfil)) return;
            lblMsg.Text = "";

            switch (e.CommandName)
            {
                case "Ver":
                    AbrirDetalle(idPerfil);
                    break;
                case "Eliminar":
                    AutorizacionService.Exigir(Permisos.EditarPerfiles);
                    if (Ejecutar(() => _bll.EliminarPerfil(idPerfil, SesionService.GetUser()), "perfiles.msg.eliminado")
                        && hfIdPerfil.Value == idPerfil.ToString())
                        CerrarDetalle();
                    CargarPerfiles();
                    break;
            }
        }

        protected void btnCrear_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.EditarPerfiles);
            lblMsg.Text = "";
            int idCreado = 0;
            if (Ejecutar(() => idCreado = _bll.CrearPerfil(txtNombre.Text, SesionService.GetUser()), "perfiles.msg.creado"))
            {
                txtNombre.Text = "";
                CargarPerfiles();
                AbrirDetalle(idCreado);
            }
        }

        // ---------- Detalle de un perfil ----------

        private PermisoItem PerfilAbierto()
        {
            int id;
            return int.TryParse(hfIdPerfil.Value, out id) ? _bll.ObtenerPerfil(id) : null;
        }

        private void AbrirDetalle(int idPerfil)
        {
            hfIdPerfil.Value = idPerfil.ToString();
            pnlDetalle.Visible = true;
            CargarDetalle();
        }

        private void CerrarDetalle()
        {
            hfIdPerfil.Value = "";
            pnlDetalle.Visible = false;
        }

        private void CargarDetalle()
        {
            PermisoItem perfil = PerfilAbierto();
            if (perfil == null) { CerrarDetalle(); return; }

            lblPerfil.Text = perfil.Codigo;
            CargarArbol();

            gvAsignados.EmptyDataText = T("perfiles.sinAsignados");
            gvAsignados.DataSource = _bll.ListarAsignados(perfil.IdPermiso);
            gvAsignados.DataBind();

            pnlAgregar.Visible = PuedeEditar;
            ddlDisponibles.Items.Clear();
            List<PermisoItem> disponibles = _bll.ListarDisponibles(perfil.IdPermiso);
            foreach (PermisoItem p in disponibles)
                ddlDisponibles.Items.Add(new ListItem(p.Codigo + " (" + TextoTipo(p) + ")", p.IdPermiso.ToString()));
            if (disponibles.Count == 0)
                ddlDisponibles.Items.Add(new ListItem(T("perfiles.sinDisponibles"), ""));
            btnAgregar.Enabled = disponibles.Count > 0;
        }

        // Muestra el Composite completo: los perfiles se abren en sus hijos, las hojas son los permisos.
        private void CargarArbol()
        {
            tvArbol.Nodes.Clear();
            PermisoItem perfil = PerfilAbierto();
            GrupoPermisos arbol = perfil == null ? null : _bll.ObtenerArbol(perfil.Codigo);
            if (arbol == null) return;
            tvArbol.Nodes.Add(CrearNodo(arbol));
            tvArbol.ExpandAll();
        }

        private static TreeNode CrearNodo(PermisoComponente componente)
        {
            GrupoPermisos grupo = componente as GrupoPermisos;
            string texto = HttpUtility.HtmlEncode(componente.Codigo);
            TreeNode nodo = new TreeNode(grupo != null ? "<b>" + texto + "</b>" : texto) { SelectAction = TreeNodeSelectAction.None };
            if (grupo != null)
                foreach (PermisoComponente hijo in grupo.Hijos)
                    nodo.ChildNodes.Add(CrearNodo(hijo));
            return nodo;
        }

        protected void gvAsignados_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            PermisoItem item = (PermisoItem)e.Row.DataItem;

            Label lblTipo = (Label)e.Row.FindControl("lblTipo");
            lblTipo.Attributes[Traductor.ATRIBUTO] = item.EsGrupo ? "perfiles.tipo.compuesto" : "perfiles.tipo.simple";
            lblTipo.Text = item.EsGrupo ? "Compuesto" : "Simple";

            Button btnQuitar = (Button)e.Row.FindControl("btnQuitar");
            btnQuitar.CommandArgument = item.IdPermiso.ToString();
            btnQuitar.Visible = PuedeEditar;
        }

        protected void gvAsignados_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Quitar") return;
            AutorizacionService.Exigir(Permisos.EditarPerfiles);
            lblMsg.Text = "";
            PermisoItem perfil = PerfilAbierto();
            int idPermiso;
            if (perfil == null || !int.TryParse(Convert.ToString(e.CommandArgument), out idPermiso)) return;

            Ejecutar(() => _bll.QuitarPermiso(perfil.IdPermiso, idPermiso, SesionService.GetUser()), "perfiles.msg.quitado");
            CargarDetalle();
        }

        protected void btnAgregar_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.EditarPerfiles);
            lblMsg.Text = "";
            PermisoItem perfil = PerfilAbierto();
            int idPermiso;
            if (perfil == null || !int.TryParse(ddlDisponibles.SelectedValue, out idPermiso)) return;

            Ejecutar(() => _bll.AgregarPermiso(perfil.IdPermiso, idPermiso, SesionService.GetUser()), "perfiles.msg.agregado");
            CargarDetalle();
        }

        protected void btnCerrar_Click(object sender, EventArgs e)
        {
            lblMsg.Text = "";
            CerrarDetalle();
        }

        // ---------- Auxiliares ----------

        private string TextoTipo(PermisoItem item)
        {
            return T(item.EsGrupo ? "perfiles.tipo.compuesto" : "perfiles.tipo.simple");
        }

        // Ejecuta una acción de PerfilBLL y muestra su resultado. Las reglas de negocio
        // devuelven el motivo en el mensaje de la excepción.
        private bool Ejecutar(Action accion, string claveExito)
        {
            try
            {
                accion();
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = T(claveExito);
                return true;
            }
            catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentException)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = ex.Message;
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("perfiles.msg.error") + ": " + ex.Message;
            }
            return false;
        }
    }
}
