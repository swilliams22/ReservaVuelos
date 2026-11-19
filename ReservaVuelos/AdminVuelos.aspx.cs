using System.Collections.Generic;
using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Globalization;
using System.Text;

namespace ReservaVuelos
{
    public partial class AdminVuelos : BasePage
    {
        protected override string ClaveTitulo { get { return "ui.adminvuelos.001"; } }

        private VueloBLL _vBLL = new VueloBLL();
        private BitacoraBLL _bBLL = new BitacoraBLL();

        protected void Page_Load(object sender, EventArgs e)
        {
            Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerVuelos))
            {
                Response.Redirect("Login.aspx");
                return;
            }

            btnCrear.Visible = AutorizacionService.TienePermiso(user, Permisos.CrearVuelo);
            btnExportar.Visible = AutorizacionService.TienePermiso(user, Permisos.ExportarVuelos);
            btnImportar.Visible = AutorizacionService.TienePermiso(user, Permisos.ImportarVuelos);

            // asociar datalist a textboxes para sugerencias
            txtOrigen.Attributes["list"] = "listaCiudades";
            txtDestino.Attributes["list"] = "listaCiudades";

            if (!IsPostBack)
            {
                // cargar grilla según filtro (por defecto Activos)
                BindGrid();
            }
        }

        protected void gvVuelosAdmin_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            AutorizacionService.Exigir(Permisos.BajaVuelo);
            if (e.CommandName == "Baja")
            {
                int id = Convert.ToInt32(e.CommandArgument);
                try
                {
                    int canceledCount = _vBLL.SoftDelete(id);
                    if (canceledCount >= 0)
                    {
                        _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Vuelo dado de baja. IdVuelo: {id}", Criticidad = 1, Pantalla = "AdminVuelos" });
                        if (canceledCount > 0)
                        {
                            _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Reservas canceladas por baja de vuelo. IdVuelo: {id} - Cantidad: {canceledCount}", Criticidad = 1, Pantalla = "AdminVuelos" });
                        }
                        BindGrid();
                        lblMsg.ForeColor = System.Drawing.Color.Green;
                        lblMsg.Text = T("ui.adminvuelos.msg027") + (canceledCount > 0 ? (T("ui.adminvuelos.msg028") + canceledCount) : string.Empty);
                    }
                    else
                    {
                        lblMsg.Text = T("ui.adminvuelos.msg029");
                    }
                }
                catch (Exception ex)
                {
                    if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                    lblMsg.Text = T("ui.adminvuelos.msg030") + Traductor.Mensaje(ex.Message);
                }
            }
        }

        protected void ddlFiltro_SelectedIndexChanged(object sender, EventArgs e)
        {
            gvVuelosAdmin.PageIndex = 0;
            BindGrid();
        }

        private void BindGrid()
        {
            string filtro = "Activos";
            if (ddlFiltro != null) filtro = ddlFiltro.SelectedValue;
            List<Vuelo> lista = _vBLL.Search(null, null, null, filtro);
            gvVuelosAdmin.DataSource = FiltrarGrilla(lista, FiltrogvVuelosAdmin, v => v.Origen + " " + v.Destino);
            gvVuelosAdmin.PageIndex = Math.Min(gvVuelosAdmin.PageIndex, Math.Max(0, ((System.Collections.ICollection)gvVuelosAdmin.DataSource).Count - 1) / gvVuelosAdmin.PageSize);
            gvVuelosAdmin.DataBind();
        }

        protected void btnCrear_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.CrearVuelo);
            try
            {
                Vuelo v = new Vuelo
                {
                    Origen = txtOrigen.Text.Trim(),
                    Destino = txtDestino.Text.Trim(),
                    FechaSalida = DateTime.Parse(txtFecha.Text, CultureInfo.InvariantCulture),
                    HoraSalida = TimeSpan.Parse(txtHora.Text),
                    Precio = decimal.Parse(txtPrecio.Text),
                    CuposDisponibles = int.Parse(txtCupos.Text),
                    Activo = true
                };
                int idVuelo = _vBLL.Create(v);
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = SesionService.GetUser().Email, Accion = $"Vuelo creado. IdVuelo: {idVuelo}", Criticidad = 1, Pantalla = "AdminVuelos" });
                BindGrid();
                lblMsg.ForeColor = System.Drawing.Color.Green;
                lblMsg.Text = T("ui.adminvuelos.msg031");
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblMsg.Text = T("ui.adminvuelos.msg030") + Traductor.Mensaje(ex.Message);
            }
        }

        protected void btnExportar_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.ExportarVuelos);
            lblXmlResultado.ForeColor = System.Drawing.Color.Red;
            string token = SesionService.GetTokenServicio();
            if (string.IsNullOrEmpty(token))
            {
                lblXmlResultado.Text = T("ui.adminvuelos.msg032");
                return;
            }

            try
            {
                // El informe lo genera el web service (AeroLinkWS.ObtenerInformeVuelosXml), que también lo registra en la bitácora.
                string filtro = ddlFiltro.SelectedValue;
                string xml = AeroLinkCliente.Llamar(c => c.ObtenerInformeVuelosXml(token, filtro));

                Response.Clear();
                Response.ContentType = "application/xml";
                Response.AddHeader("Content-Disposition", "attachment; filename=vuelos_" + DateTime.Now.ToString("yyyyMMdd_HHmm") + ".xml");
                Response.BinaryWrite(new UTF8Encoding(false).GetBytes(xml));
                Response.Flush();
                Response.SuppressContent = true;   // evita que ASP.NET agregue el HTML de la página al final del archivo
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblXmlResultado.Text = Server.HtmlEncode(T("ui.adminvuelos.msg033") + Traductor.Mensaje(ex.Message));
            }
        }

        protected void btnImportar_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.ImportarVuelos);
            lblXmlResultado.ForeColor = System.Drawing.Color.Red;
            if (!fuXml.HasFile)
            {
                lblXmlResultado.Text = T("ui.adminvuelos.msg034");
                return;
            }
            if (fuXml.PostedFile.ContentLength > XmlVuelosService.MAX_BYTES)
            {
                lblXmlResultado.Text = T("ui.adminvuelos.msg035") + (XmlVuelosService.MAX_BYTES / 1024) + " KB.";
                return;
            }
            string token = SesionService.GetTokenServicio();
            if (string.IsNullOrEmpty(token))
            {
                lblXmlResultado.Text = T("ui.adminvuelos.msg032");
                return;
            }

            try
            {
                string xml;
                using (System.IO.StreamReader lector = new System.IO.StreamReader(fuXml.PostedFile.InputStream, Encoding.UTF8))
                    xml = lector.ReadToEnd();

                // La importación la hace el web service (AeroLinkWS.ImportarVuelosXml), que también la registra en la bitácora.
                ReservaVuelos.AeroLinkServiceReference.ResultadoImportacionWS r = AeroLinkCliente.Llamar(c => c.ImportarVuelosXml(token, xml));
                if (!r.Exitoso)
                {
                    lblXmlResultado.Text = Server.HtmlEncode(Traductor.Mensaje(r.Mensaje));
                    return;
                }

                BindGrid();

                StringBuilder sb = new StringBuilder();
                sb.Append(Server.HtmlEncode(string.Format(T("ui.adminvuelos.importacion.resumen"), r.Total, r.Importados, r.Rechazados.Count)));
                foreach (string motivo in r.Rechazados)
                    sb.Append("<br />").Append(Server.HtmlEncode(Traductor.Mensaje(motivo)));
                lblXmlResultado.Text = sb.ToString();
                lblXmlResultado.ForeColor = r.Rechazados.Count == 0 ? System.Drawing.Color.Green
                    : r.Importados > 0 ? System.Drawing.Color.DarkOrange : System.Drawing.Color.Red;
            }
            catch (Exception ex)
            {
                if (new IntegrityService().RedirectIfContingencyActive(SesionService.GetUser())) return;
                lblXmlResultado.Text = Server.HtmlEncode(T("ui.adminvuelos.msg036") + Traductor.Mensaje(ex.Message));
            }
        }
        protected void gvVuelosAdmin_PageIndexChanging(object sender, System.Web.UI.WebControls.GridViewPageEventArgs e)
        {
            gvVuelosAdmin.PageIndex = e.NewPageIndex;
            BindGrid();
        }

        private string FiltrogvVuelosAdmin { get { return ViewState["FiltrogvVuelosAdmin"] as string ?? ""; } set { ViewState["FiltrogvVuelosAdmin"] = value; } }
        protected void FiltrargvVuelosAdmin(object sender, EventArgs e)
        {
            if (((System.Web.UI.WebControls.Button)sender).CommandArgument == "limpiar") txtFiltrogvVuelosAdmin.Text = "";
            FiltrogvVuelosAdmin = txtFiltrogvVuelosAdmin.Text.Trim();
            gvVuelosAdmin.PageIndex = 0;
            BindGrid();
        }


    }
}
