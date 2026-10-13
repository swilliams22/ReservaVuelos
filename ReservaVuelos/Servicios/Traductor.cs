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

        // GridView: claves de los encabezados, una por columna y separadas por coma (vacia = no traducir).
        public const string ATRIBUTO_ENCABEZADOS = "data-i18n-headers";

        // data-i18n-xxx="clave" traduce el atributo HTML xxx (tooltip, placeholder).
        private static readonly string[][] ATRIBUTOS_HTML =
        {
            new[] { "data-i18n-title", "title" },
            new[] { "data-i18n-placeholder", "placeholder" }
        };

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

        /// <summary>Texto traducido; si la clave no existe devuelve el texto actual (el del .aspx).</summary>
        public static string TraducirOConservar(string clave, Idioma idioma, string textoActual)
        {
            string texto;
            return BuscarTexto(clave, idioma, out texto) ? texto : textoActual;
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
            if (!control.Visible) return;   // lo que no se muestra no hace falta traducirlo
            if (!esRaiz && (control is MasterPage || control is ContentPlaceHolder)) return;

            Aplicar(control, idioma);

            foreach (Control hijo in control.Controls)
                Recorrer(hijo, idioma, false);
        }

        private static void Aplicar(Control control, Idioma idioma)
        {
            var atributos = ObtenerAtributos(control);
            if (atributos == null) return;

            string texto;

            // Si la clave no existe se conserva el texto original del .aspx.
            var clave = atributos[ATRIBUTO];
            if (!string.IsNullOrEmpty(clave) && BuscarTexto(clave, idioma, out texto))
                AsignarTexto(control, texto);

            foreach (var par in ATRIBUTOS_HTML)
            {
                var claveAtributo = atributos[par[0]];
                if (!string.IsNullOrEmpty(claveAtributo) && BuscarTexto(claveAtributo, idioma, out texto))
                    atributos[par[1]] = texto;
            }

            var grilla = control as GridView;
            if (grilla != null)
                TraducirEncabezados(grilla, atributos[ATRIBUTO_ENCABEZADOS], idioma);
        }

        private static void TraducirEncabezados(GridView grilla, string claves, Idioma idioma)
        {
            if (string.IsNullOrEmpty(claves) || grilla.HeaderRow == null) return;

            var lista = claves.Split(',');
            for (int i = 0; i < lista.Length && i < grilla.HeaderRow.Cells.Count; i++)
            {
                var clave = lista[i].Trim();
                string texto;
                if (clave.Length > 0 && BuscarTexto(clave, idioma, out texto))
                    grilla.HeaderRow.Cells[i].Text = texto;
            }
        }

        private static AttributeCollection ObtenerAtributos(Control control)
        {
            var web = control as WebControl;
            if (web != null) return web.Attributes;

            var html = control as HtmlControl;
            if (html != null) return html.Attributes;

            return null;
        }

        private static void AsignarTexto(Control control, string texto)
        {
            if (control is Label) { ((Label)control).Text = texto; return; }
            if (control is Button) { ((Button)control).Text = texto; return; }
            if (control is LinkButton) { ((LinkButton)control).Text = texto; return; }
            if (control is HyperLink) { ((HyperLink)control).Text = texto; return; }
            if (control is CheckBox) { ((CheckBox)control).Text = texto; return; }            // incluye RadioButton
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
