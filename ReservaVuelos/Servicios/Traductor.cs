using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using System.Collections.Generic;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace ReservaVuelos.Servicios
{
    /// <summary>
    /// Aplica las traducciones.
    ///
    /// En el .aspx se marca cada control con la clave de su texto:
    ///     &lt;asp:Label runat="server" data-i18n="login.lbl.email" Text="Email" /&gt;
    /// y TraducirControles reemplaza el texto según el idioma. Si la clave no existe,
    /// se conserva el texto original del .aspx.
    ///
    /// Para mensajes armados en código se usa T("clave").
    /// </summary>
    public static class Traductor
    {
        public const string ATRIBUTO = "data-i18n";

        // ---------- Textos armados en código ----------

        /// <summary>Texto de la clave en el idioma del usuario actual.</summary>
        public static string T(string clave)
        {
            return T(clave, IdiomaService.Instancia.IdiomaActual);
        }

        public static string T(string clave, Idioma idioma)
        {
            string texto;
            if (BuscarTexto(clave, idioma, out texto)) return texto;
            return "[" + clave + "]";   // se nota enseguida qué clave falta cargar
        }

        // ---------- Controles marcados con data-i18n ----------

        /// <summary>
        /// Traduce un control y sus hijos. Cada observer traduce lo suyo: al recorrer no se
        /// baja a una MasterPage ni a un ContentPlaceHolder (salvo que sea la raíz).
        /// </summary>
        public static void TraducirControles(Control raiz, Idioma idioma)
        {
            if (raiz == null || idioma == null) return;
            Recorrer(raiz, idioma, true);
        }

        /// <summary>Traduce el contenido propio de una página (lo que está en los ContentPlaceHolder de la Master).</summary>
        public static void TraducirPagina(Page pagina, Idioma idioma)
        {
            if (pagina == null || idioma == null) return;

            if (pagina.Master == null)
            {
                TraducirControles(pagina, idioma);
                return;
            }

            foreach (var contenido in BuscarPlaceHolders(pagina.Master))
                TraducirControles(contenido, idioma);
        }

        private static IEnumerable<ContentPlaceHolder> BuscarPlaceHolders(Control padre)
        {
            foreach (Control hijo in padre.Controls)
            {
                var placeHolder = hijo as ContentPlaceHolder;
                if (placeHolder != null) yield return placeHolder;

                foreach (var anidado in BuscarPlaceHolders(hijo))
                    yield return anidado;
            }
        }

        private static void Recorrer(Control control, Idioma idioma, bool esRaiz)
        {
            if (!esRaiz && (control is MasterPage || control is ContentPlaceHolder)) return;

            Aplicar(control, idioma);

            foreach (Control hijo in control.Controls)
                Recorrer(hijo, idioma, false);
        }

        private static void Aplicar(Control control, Idioma idioma)
        {
            var clave = ObtenerClave(control);
            if (string.IsNullOrEmpty(clave)) return;

            string texto;
            if (!BuscarTexto(clave, idioma, out texto)) return;   // conserva el texto del .aspx

            AsignarTexto(control, texto);
        }

        private static string ObtenerClave(Control control)
        {
            var web = control as WebControl;
            if (web != null) return web.Attributes[ATRIBUTO];

            var html = control as HtmlControl;
            if (html != null) return html.Attributes[ATRIBUTO];

            return null;
        }

        private static void AsignarTexto(Control control, string texto)
        {
            if (control is Label) { ((Label)control).Text = texto; return; }
            if (control is Button) { ((Button)control).Text = texto; return; }
            if (control is LinkButton) { ((LinkButton)control).Text = texto; return; }
            if (control is HyperLink) { ((HyperLink)control).Text = texto; return; }
            if (control is CheckBox) { ((CheckBox)control).Text = texto; return; }            // incluye RadioButton
            if (control is TextBox) { ((TextBox)control).Attributes["placeholder"] = texto; return; }
            if (control is HtmlInputButton) { ((HtmlInputButton)control).Value = texto; return; }
            if (control is HtmlContainerControl) { ((HtmlContainerControl)control).InnerText = texto; return; }  // a, h2, span, button...
        }

        // ---------- Búsqueda ----------

        // Primero el idioma pedido; si falta, el idioma por defecto.
        private static bool BuscarTexto(string clave, Idioma idioma, out string texto)
        {
            var bll = new IdiomaBLL();

            if (bll.GetTraducciones(idioma).TryGetValue(clave, out texto) && !string.IsNullOrWhiteSpace(texto))
                return true;

            var porDefecto = bll.GetDefault();
            if (porDefecto.IdIdioma != idioma.IdIdioma &&
                bll.GetTraducciones(porDefecto).TryGetValue(clave, out texto) && !string.IsNullOrWhiteSpace(texto))
                return true;

            texto = null;
            return false;
        }
    }
}
