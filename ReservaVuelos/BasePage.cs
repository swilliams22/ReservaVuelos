using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
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

        protected override void OnUnload(EventArgs e)
        {
            IdiomaService.Instancia.Desuscribir(this);
            base.OnUnload(e);
        }

        /// <summary>Lo llama el Subject cuando cambia el idioma, y también al cargar la página.</summary>
        public virtual void ActualizarIdioma(Idioma idioma)
        {
            Traductor.TraducirPagina(this, idioma);

            if (ClaveTitulo != null)
                Title = Traductor.T(ClaveTitulo, idioma);
        }

        /// <summary>Atajo para traducir mensajes armados en el code-behind.</summary>
        protected string T(string clave)
        {
            return Traductor.T(clave);
        }
    }
}
