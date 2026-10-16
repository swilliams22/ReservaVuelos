using System.Web.SessionState;
using System.Collections;
using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace ReservaVuelos.Servicios
{
    /// <summary>
    /// ConcreteSubject del patrón Observer.
    ///
    /// En una aplicación web el Subject NO puede ser un singleton estático: lo compartirían
    /// todos los usuarios y el idioma de uno cambiaría el de los demás. Por eso:
    ///  - el idioma elegido vive en Session (uno por usuario);
    ///  - la instancia del Subject y su lista de observers viven en HttpContext.Items
    ///    (uno por request, se descarta al terminar);
    ///  - lo único compartido entre usuarios es la caché de traducciones (solo lectura, en IdiomaBLL).
    /// </summary>
    public class IdiomaService : IIdiomaSubject
    {
        private const string KEY_INSTANCIA = "IdiomaService.Instancia";
        private const string KEY_IDIOMA = "IdiomaActual";

        private readonly List<IIdiomaObserver> _observadores = new List<IIdiomaObserver>();
        private readonly IdiomaBLL _bll = new IdiomaBLL();

        private IdiomaService() { }

        /// <summary>Subject del request actual.</summary>
        public static IdiomaService Instancia
        {
            get
            {
                IDictionary items = HttpContext.Current.Items;
                IdiomaService servicio = items[KEY_INSTANCIA] as IdiomaService;
                if (servicio == null)
                {
                    servicio = new IdiomaService();
                    items[KEY_INSTANCIA] = servicio;
                }
                return servicio;
            }
        }

        /// <summary>Idioma del usuario actual (el de la sesión, o el idioma por defecto).</summary>
        public Idioma IdiomaActual
        {
            get
            {
                HttpSessionState session = HttpContext.Current.Session;
                Idioma actual = session == null ? null : session[KEY_IDIOMA] as Idioma;
                return actual ?? _bll.GetDefault();
            }
        }

        // ----- Subject -----

        public void Suscribir(IIdiomaObserver observer)
        {
            if (observer != null && !_observadores.Contains(observer))
                _observadores.Add(observer);
        }

        public void Desuscribir(IIdiomaObserver observer)
        {
            _observadores.Remove(observer);
        }

        public void Notificar()
        {
            Idioma idioma = IdiomaActual;
            foreach (IIdiomaObserver observer in _observadores.ToList())
                observer.ActualizarIdioma(idioma);
        }

        // ----- Cambio de idioma -----

        /// <summary>Cambia el idioma del usuario actual y avisa a todos los observers.</summary>
        public bool CambiarIdioma(string codigo)
        {
            Idioma idioma = _bll.GetByCodigo(codigo);
            HttpSessionState session = HttpContext.Current.Session;
            if (idioma == null || session == null) return false;

            session[KEY_IDIOMA] = idioma;
            Notificar();
            GuardarPreferenciaYRegistrar(idioma);
            return true;
        }

        /// <summary>Al iniciar sesión: si el usuario tiene un idioma guardado, lo aplica.</summary>
        public void AplicarPreferenciaDeUsuario(Usuario usuario)
        {
            HttpSessionState session = HttpContext.Current.Session;
            if (usuario == null || session == null) return;

            int? idIdioma = _bll.GetPreferencia(usuario.IdUsuario);
            if (!idIdioma.HasValue) return;

            Idioma idioma = _bll.GetById(idIdioma.Value);
            if (idioma != null) session[KEY_IDIOMA] = idioma;
        }

        private void GuardarPreferenciaYRegistrar(Idioma idioma)
        {
            Usuario usuario = SesionService.GetUser();
            if (usuario == null) return;   // sin sesión iniciada solo cambia para esta visita

            try
            {
                _bll.GuardarPreferencia(usuario.IdUsuario, idioma.IdIdioma);

                string pantalla = Path.GetFileName(HttpContext.Current.Request.AppRelativeCurrentExecutionFilePath);
                new BitacoraBLL().Create(new ReservaVuelos.BE.Bitacora
                {
                    Fecha = DateTime.Now,
                    Usuario = usuario.Email,
                    Accion = "Cambio de idioma a " + idioma.Codigo,
                    Criticidad = 1,
                    Pantalla = string.IsNullOrEmpty(pantalla) ? "Site.Master" : pantalla
                });
            }
            catch (Exception)
            {
                // Que falle guardar la preferencia o la bitácora no debe impedir el cambio de idioma en pantalla.
            }
        }
    }
}
