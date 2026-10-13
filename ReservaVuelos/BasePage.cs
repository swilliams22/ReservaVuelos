using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Web;
using System.Web.UI;

namespace ReservaVuelos
{
    /// <summary>
    /// Página base: es un Observer del idioma.
    /// Las páginas que quieran traducirse heredan de BasePage en lugar de System.Web.UI.Page.
    /// </summary>
    public class BasePage : Page, IIdiomaObserver
    {
        /// <summary>Clave del título de la pestaña (opcional). Las páginas la sobrescriben.</summary>
        protected virtual string ClaveTitulo
        {
            get { return null; }
        }

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            IdiomaService.Instancia.Suscribir(this);
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            ActualizarIdioma(IdiomaService.Instancia.IdiomaActual);
        }

        // Despues de los eventos: traduce lo que se creo recien (filas de una grilla, paneles que se muestran).
        protected override void OnPreRender(EventArgs e)
        {
            base.OnPreRender(e);
            ActualizarIdioma(IdiomaService.Instancia.IdiomaActual);
        }

        protected override void OnUnload(EventArgs e)
        {
            IdiomaService.Instancia.Desuscribir(this);
            base.OnUnload(e);
        }

        /// <summary>Lo llama el Subject cuando cambia el idioma, y también al cargar la página.</summary>
        public virtual void ActualizarIdioma(Idioma idioma)
        {
            Traductor.TraducirPagina(this, idioma);

            // Si la clave no existe se conserva el titulo del .aspx (no se muestra [clave] en la pestaña).
            if (ClaveTitulo != null)
                Title = Traductor.TraducirOConservar(ClaveTitulo, idioma, Title);
        }

        /// <summary>Atajo para traducir mensajes armados en el code-behind.</summary>
        protected string T(string clave)
        {
            return Traductor.T(clave);
        }

        /// <summary>Texto listo para ponerlo entre comillas simples dentro de un script del .aspx.</summary>
        protected string TJs(string clave)
        {
            return HttpUtility.JavaScriptStringEncode(Traductor.T(clave));
        }
    }
}
