using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

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
            List<Idioma> activos = GetActivos();
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
                Dictionary<string, string> textos = _dal.GetTraducciones(idioma.IdIdioma);
                _traducciones[idioma.Codigo] = new TraduccionesEnCache
                {
                    Textos = textos,
                    Vence = DateTime.Now.AddMinutes(MINUTOS_CACHE)
                };
                return textos;
            }
            catch (Exception)
            {
                Dictionary<string, string> vacio = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
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

        // ---------- Administración (pantalla del WebMaster) ----------

        public List<Idioma> GetTodos() { return _dal.GetTodos(); }

        public List<string> GetPantallas() { return _dal.GetPantallas(); }

        public List<EtiquetaTraduccion> GetEtiquetas(Idioma idioma, string pantalla, bool soloPendientes)
        {
            Idioma baseIdioma = GetTodos().First(i => i.EsDefault);
            return _dal.GetEtiquetas(idioma.IdIdioma, baseIdioma.IdIdioma, pantalla, soloPendientes);
        }

        /// <summary>Crea un idioma (queda inactivo hasta que se lo active). Devuelve el mensaje de error o null si salió bien.</summary>
        public string Crear(string codigo, string nombre, out Idioma creado)
        {
            creado = null;
            codigo = (codigo ?? "").Trim();
            nombre = (nombre ?? "").Trim();

            if (nombre.Length == 0 || nombre.Length > 50) return "nombre";
            if (!Regex.IsMatch(codigo, @"^[a-z]{2,3}(-[A-Za-z0-9]{2,4})?$")) return "codigo";
            if (_dal.ExisteCodigo(codigo)) return "existe";

            int id = _dal.Crear(codigo, nombre);
            LimpiarCache();
            creado = new Idioma { IdIdioma = id, Codigo = codigo, Nombre = nombre };
            return null;
        }

        /// <summary>Activa o desactiva un idioma. El idioma por defecto no se puede desactivar.</summary>
        public bool CambiarActivo(Idioma idioma, bool activo)
        {
            if (!activo && idioma.EsDefault) return false;
            _dal.CambiarActivo(idioma.IdIdioma, activo);
            LimpiarCache();
            return true;
        }

        public void GuardarTraducciones(Idioma idioma, Dictionary<int, string> textos)
        {
            _dal.GuardarTraducciones(idioma.IdIdioma, textos);
            LimpiarCache();
        }

        /// <summary>Descarta la caché (la usará la pantalla de administración al guardar cambios).</summary>
        public static void LimpiarCache()
        {
            lock (_lock) { _idiomas = null; }
            _traducciones.Clear();
        }
    }
}
