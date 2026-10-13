using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;

namespace ReservaVuelos.BLL
{
    /// <summary>
    /// Idiomas y traducciones, con caché compartida entre usuarios (es de solo lectura).
    /// Si las tablas de idiomas todavía no existen o la base falla, el sitio sigue
    /// funcionando en español con los textos que ya tienen las páginas.
    /// </summary>
    public class IdiomaBLL
    {
        private const int MINUTOS_CACHE = 2;
        private const int SEGUNDOS_CACHE_ERROR = 10;   // si falla la base, no reintentar en cada control

        private class TraduccionesEnCache
        {
            public Dictionary<string, string> Textos;
            public DateTime Vence;
        }

        private static readonly object _lock = new object();
        private static List<Idioma> _idiomas;
        private static DateTime _idiomasVence;
        private static readonly ConcurrentDictionary<string, TraduccionesEnCache> _traducciones =
            new ConcurrentDictionary<string, TraduccionesEnCache>(StringComparer.OrdinalIgnoreCase);

        private readonly IdiomaDAL _dal = new IdiomaDAL();

        public static Idioma IdiomaRespaldo
        {
            get { return new Idioma { IdIdioma = 0, Codigo = "es-AR", Nombre = "Español", EsDefault = true, Activo = true }; }
        }

        public List<Idioma> GetActivos()
        {
            lock (_lock)
            {
                if (_idiomas != null && DateTime.Now < _idiomasVence)
                    return new List<Idioma>(_idiomas);
            }

            List<Idioma> lista;
            DateTime vence;
            try
            {
                lista = _dal.GetActivos();
                vence = DateTime.Now.AddMinutes(MINUTOS_CACHE);
                if (lista.Count == 0)
                {
                    lista = new List<Idioma> { IdiomaRespaldo };
                    vence = DateTime.Now.AddSeconds(SEGUNDOS_CACHE_ERROR);
                }
            }
            catch (Exception)
            {
                // Tablas inexistentes o base no disponible: se sigue en español y se reintenta en unos segundos.
                lista = new List<Idioma> { IdiomaRespaldo };
                vence = DateTime.Now.AddSeconds(SEGUNDOS_CACHE_ERROR);
            }

            lock (_lock)
            {
                _idiomas = lista;
                _idiomasVence = vence;
            }
            return new List<Idioma>(lista);
        }

        public Idioma GetDefault()
        {
            var activos = GetActivos();
            return activos.FirstOrDefault(i => i.EsDefault) ?? activos.First();
        }

        public Idioma GetByCodigo(string codigo)
        {
            if (string.IsNullOrWhiteSpace(codigo)) return null;
            return GetActivos().FirstOrDefault(i => string.Equals(i.Codigo, codigo, StringComparison.OrdinalIgnoreCase));
        }

        public Idioma GetById(int idIdioma)
        {
            return GetActivos().FirstOrDefault(i => i.IdIdioma == idIdioma);
        }

        public Dictionary<string, string> GetTraducciones(Idioma idioma)
        {
            if (idioma == null || idioma.IdIdioma <= 0)
                return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            TraduccionesEnCache enCache;
            if (_traducciones.TryGetValue(idioma.Codigo, out enCache) && DateTime.Now < enCache.Vence)
                return enCache.Textos;

            try
            {
                var textos = _dal.GetTraducciones(idioma.IdIdioma);
                _traducciones[idioma.Codigo] = new TraduccionesEnCache
                {
                    Textos = textos,
                    Vence = DateTime.Now.AddMinutes(MINUTOS_CACHE)
                };
                return textos;
            }
            catch (Exception)
            {
                var vacio = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                _traducciones[idioma.Codigo] = new TraduccionesEnCache
                {
                    Textos = vacio,
                    Vence = DateTime.Now.AddSeconds(SEGUNDOS_CACHE_ERROR)
                };
                return vacio;
            }
        }

        public int? GetPreferencia(int idUsuario)
        {
            try { return _dal.GetPreferencia(idUsuario); }
            catch (Exception) { return null; }
        }

        public void GuardarPreferencia(int idUsuario, int idIdioma)
        {
            _dal.GuardarPreferencia(idUsuario, idIdioma);
        }

        /// <summary>Descarta la caché (la usará la pantalla de administración al guardar cambios).</summary>
        public static void LimpiarCache()
        {
            lock (_lock) { _idiomas = null; }
            _traducciones.Clear();
        }
    }
}
