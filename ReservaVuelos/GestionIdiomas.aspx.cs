using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;

namespace ReservaVuelos
{
    /// <summary>
    /// Pantalla del WebMaster para dar de alta idiomas, cargar traducciones y activarlos,
    /// sin tocar código ni scripts.
    /// </summary>
    public partial class GestionIdiomas : BasePage
    {
        private IdiomaBLL _bll = new IdiomaBLL();
        private BitacoraBLL _bBLL = new BitacoraBLL();

        protected override string ClaveTitulo { get { return "idiomas.titulo"; } }

        protected void Page_Load(object sender, EventArgs e)
        {
            Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerIdiomas))
            {
                Response.Redirect("Login.aspx");
                return;
            }
            btnCrear.Visible = AutorizacionService.TienePermiso(user, Permisos.EditarIdiomas);
            btnGuardar.Visible = AutorizacionService.TienePermiso(user, Permisos.EditarIdiomas);
            if (!IsPostBack)
                CargarIdiomas();
        }

        // ---------- Lista de idiomas ----------

        private void CargarIdiomas()
        {
            gvIdiomas.DataSource = FiltrarGrilla(_bll.GetTodos(), FiltrogvIdiomas, v => v.Codigo + " " + v.Nombre + " " + T(v.Activo ? "usuarios.estado.activo" : "usuarios.estado.inactivo"));
            gvIdiomas.PageIndex = Math.Min(gvIdiomas.PageIndex, Math.Max(0, ((System.Collections.ICollection)gvIdiomas.DataSource).Count - 1) / gvIdiomas.PageSize);
            gvIdiomas.DataBind();
        }

        protected void gvIdiomas_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            Idioma idioma = (Idioma)e.Row.DataItem;

            // La clave va en data-i18n: BasePage la traduce al mostrar la página (también si cambia el idioma).
            Label lblEstado = (Label)e.Row.FindControl("lblEstado");
            string clave = idioma.EsDefault ? "idiomas.estado.default" : idioma.Activo ? "idiomas.estado.activo" : "idiomas.estado.inactivo";
            lblEstado.Attributes[Traductor.ATRIBUTO] = clave;
            lblEstado.Text = idioma.EsDefault ? "Por defecto" : idioma.Activo ? "Activo" : "Inactivo";

            ((Label)e.Row.FindControl("lblProgreso")).Text =
                idioma.Traducidas + " / " + idioma.Total + " (" + idioma.Porcentaje + "%)";

            string id = idioma.IdIdioma.ToString();
            Button btnEditar = (Button)e.Row.FindControl("btnEditar");
            Button btnActivar = (Button)e.Row.FindControl("btnActivar");
            Button btnDesactivar = (Button)e.Row.FindControl("btnDesactivar");
            btnEditar.CommandArgument = id;
            btnActivar.CommandArgument = id;
            btnDesactivar.CommandArgument = id;
            bool puedeEditar = AutorizacionService.TienePermiso(SesionService.GetUser(), Permisos.EditarIdiomas);
            btnEditar.Visible = puedeEditar;
            btnActivar.Visible = puedeEditar && !idioma.Activo;
            btnDesactivar.Visible = puedeEditar && idioma.Activo && !idioma.EsDefault;
        }

        protected void gvIdiomas_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Page") return;
            AutorizacionService.Exigir(Permisos.EditarIdiomas);
            int idIdioma;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out idIdioma)) return;

            Idioma idioma = _bll.GetTodos().FirstOrDefault(i => i.IdIdioma == idIdioma);
            if (idioma == null) return;

            lblMsg.Text = "";
            try
            {
                switch (e.CommandName)
                {
                    case "Editar":
                        AbrirEdicion(idioma);
                        break;
                    case "Activar":
                        _bll.CambiarActivo(idioma, true);
                        Registrar("Idioma " + idioma.Codigo + " activado", 2);
                        Mensaje("idiomas.msg.activado", false);
                        break;
                    case "Desactivar":
                        if (!_bll.CambiarActivo(idioma, false))
                        {
                            Mensaje("idiomas.msg.noDesactivarDefault", true);
                            break;
                        }
                        Registrar("Idioma " + idioma.Codigo + " desactivado", 2);
                        Mensaje("idiomas.msg.desactivado", false);
                        break;
                }
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("idiomas.msg.error") + ": " + ReservaVuelos.Servicios.Traductor.Mensaje(ex.Message);
            }
            CargarIdiomas();
        }

        protected void btnCrear_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.EditarIdiomas);
            lblMsg.Text = "";
            try
            {
                Idioma creado;
                string error = _bll.Crear(txtCodigo.Text, txtNombre.Text, out creado);
                if (error != null)
                {
                    Mensaje("idiomas.msg.crear." + error, true);
                    return;
                }

                Registrar("Alta de idioma " + creado.Codigo, 2);
                txtCodigo.Text = "";
                txtNombre.Text = "";
                CargarIdiomas();
                AbrirEdicion(creado);
                Mensaje("idiomas.msg.creado", false);
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("idiomas.msg.error") + ": " + ReservaVuelos.Servicios.Traductor.Mensaje(ex.Message);
            }
        }

        // ---------- Edición de traducciones ----------

        private void AbrirEdicion(Idioma idioma)
        {
            ViewState.Remove("TraduccionesPendientes");
            FiltrogvEtiquetas = "";
            txtFiltrogvEtiquetas.Text = "";
            gvEtiquetas.PageIndex = 0;
            hfIdIdioma.Value = idioma.IdIdioma.ToString();
            lblIdiomaEditado.Text = idioma.Nombre + " (" + idioma.Codigo + ")";

            ddlPantalla.Items.Clear();
            ddlPantalla.Items.Add(new ListItem(T("idiomas.todas"), ""));
            foreach (string p in _bll.GetPantallas())
                ddlPantalla.Items.Add(new ListItem(p, p));
            chkPendientes.Checked = false;

            pnlEditar.Visible = true;
            CargarEtiquetas();
        }

        private Idioma IdiomaEnEdicion()
        {
            int id;
            if (!int.TryParse(hfIdIdioma.Value, out id)) return null;
            return _bll.GetTodos().FirstOrDefault(i => i.IdIdioma == id);
        }

        private void CargarEtiquetas()
        {
            Idioma idioma = IdiomaEnEdicion();
            if (idioma == null) { pnlEditar.Visible = false; return; }

            gvEtiquetas.DataSource = FiltrarGrilla(_bll.GetEtiquetas(idioma, ddlPantalla.SelectedValue, chkPendientes.Checked), FiltrogvEtiquetas, v => v.Clave + " " + v.TextoBase + " " + v.Texto);
            gvEtiquetas.PageIndex = Math.Min(gvEtiquetas.PageIndex, Math.Max(0, ((System.Collections.ICollection)gvEtiquetas.DataSource).Count - 1) / gvEtiquetas.PageSize);
            gvEtiquetas.DataBind();
            var pendientes = ViewState["TraduccionesPendientes"] as Dictionary<int, string>;
            if (pendientes != null)
                foreach (GridViewRow fila in gvEtiquetas.Rows)
                {
                    string texto;
                    if (pendientes.TryGetValue(Convert.ToInt32(gvEtiquetas.DataKeys[fila.RowIndex].Value), out texto))
                        ((TextBox)fila.FindControl("txtTexto")).Text = texto;
                }
        }

        protected void btnFiltrar_Click(object sender, EventArgs e)
        {
            CapturarTraducciones();
            gvEtiquetas.PageIndex = 0;
            lblMsg.Text = "";
            CargarEtiquetas();
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.EditarIdiomas);
            lblMsg.Text = "";
            Idioma idioma = IdiomaEnEdicion();
            if (idioma == null) return;

            CapturarTraducciones();
            Dictionary<int, string> textos = (Dictionary<int, string>)ViewState["TraduccionesPendientes"];

            try
            {
                _bll.GuardarTraducciones(idioma, textos);
                ViewState.Remove("TraduccionesPendientes");
                Registrar("Traducciones guardadas del idioma " + idioma.Codigo, 1);
                Mensaje("idiomas.msg.guardado", false);
            }
            catch (Exception ex)
            {
                lblMsg.ForeColor = System.Drawing.Color.Red;
                lblMsg.Text = T("idiomas.msg.error") + ": " + ReservaVuelos.Servicios.Traductor.Mensaje(ex.Message);
            }
            CargarEtiquetas();
            CargarIdiomas();
        }

        protected void btnCerrar_Click(object sender, EventArgs e)
        {
            lblMsg.Text = "";
            hfIdIdioma.Value = "";
            pnlEditar.Visible = false;
        }

        // ---------- Auxiliares ----------

        private void Mensaje(string clave, bool esError)
        {
            lblMsg.ForeColor = esError ? System.Drawing.Color.Red : System.Drawing.Color.Green;
            lblMsg.Text = T(clave);
        }

        private void Registrar(string accion, int criticidad)
        {
            try
            {
                _bBLL.Create(new ReservaVuelos.BE.Bitacora
                {
                    Fecha = DateTime.Now,
                    Usuario = SesionService.GetUser().Email,
                    Accion = accion,
                    Criticidad = criticidad,
                    Pantalla = "GestionIdiomas"
                });
            }
            catch (Exception)
            {
                // La bitácora no debe impedir la operación.
            }
        }
        protected void gvIdiomas_PageIndexChanging(object sender, System.Web.UI.WebControls.GridViewPageEventArgs e)
        {
            gvIdiomas.PageIndex = e.NewPageIndex;
            CargarIdiomas();
        }

        protected void gvEtiquetas_PageIndexChanging(object sender, System.Web.UI.WebControls.GridViewPageEventArgs e)
        {
            CapturarTraducciones();
            gvEtiquetas.PageIndex = e.NewPageIndex;
            CargarEtiquetas();
        }

        private void CapturarTraducciones()
        {
            Dictionary<int, string> textos = ViewState["TraduccionesPendientes"] as Dictionary<int, string> ?? new Dictionary<int, string>();
            foreach (GridViewRow fila in gvEtiquetas.Rows)
            {
                TextBox txt = (TextBox)fila.FindControl("txtTexto");
                textos[Convert.ToInt32(gvEtiquetas.DataKeys[fila.RowIndex].Value)] = txt.Text;
            }

            ViewState["TraduccionesPendientes"] = textos;
        }

        private string FiltrogvIdiomas { get { return ViewState["FiltrogvIdiomas"] as string ?? ""; } set { ViewState["FiltrogvIdiomas"] = value; } }
        protected void FiltrargvIdiomas(object sender, EventArgs e)
        {
            if (((System.Web.UI.WebControls.Button)sender).CommandArgument == "limpiar") txtFiltrogvIdiomas.Text = "";
            FiltrogvIdiomas = txtFiltrogvIdiomas.Text.Trim();
            gvIdiomas.PageIndex = 0;
            CargarIdiomas();
        }

        private string FiltrogvEtiquetas { get { return ViewState["FiltrogvEtiquetas"] as string ?? ""; } set { ViewState["FiltrogvEtiquetas"] = value; } }
        protected void FiltrargvEtiquetas(object sender, EventArgs e)
        {
            CapturarTraducciones();
            if (((System.Web.UI.WebControls.Button)sender).CommandArgument == "limpiar") txtFiltrogvEtiquetas.Text = "";
            FiltrogvEtiquetas = txtFiltrogvEtiquetas.Text.Trim();
            gvEtiquetas.PageIndex = 0;
            CargarEtiquetas();
        }

    }
}
