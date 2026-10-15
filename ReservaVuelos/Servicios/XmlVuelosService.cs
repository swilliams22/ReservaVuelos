using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;

namespace ReservaVuelos.Servicios
{
    /// <summary>
    /// Exporta e importa vuelos en XML.
    ///
    /// Exportar: genera con XmlTextWriter un XML con los vuelos de una consulta (por ejemplo la grilla de AdminVuelos).
    /// Importar: carga masiva de vuelos desde un XML. Se lee con XmlTextReader, se valida la estructura
    /// y cada vuelo pasa por VueloBLL.Create, por lo que se aplican las mismas reglas y el mismo
    /// cálculo de DVH/DVV que al crear un vuelo a mano.
    ///
    /// Formato:
    ///   &lt;vuelos&gt;
    ///     &lt;vuelo&gt;
    ///       &lt;origen&gt;Buenos Aires&lt;/origen&gt;  &lt;destino&gt;Mendoza&lt;/destino&gt;
    ///       &lt;fecha&gt;2026-12-05&lt;/fecha&gt;  &lt;hora&gt;08:30&lt;/hora&gt;
    ///       &lt;precio&gt;120000.00&lt;/precio&gt;  &lt;cupos&gt;150&lt;/cupos&gt;
    ///     &lt;/vuelo&gt;
    ///   &lt;/vuelos&gt;
    /// Los atributos id y estado que agrega la exportación son informativos y se ignoran al importar.
    /// </summary>
    public class XmlVuelosService
    {
        public const int MAX_BYTES = 1024 * 1024;   // 1 MB
        public const int MAX_VUELOS = 500;

        public class ResultadoImportacion
        {
            public int Total { get; set; }
            public int Importados { get; set; }
            public List<string> Rechazados { get; } = new List<string>();
        }

        // ---------- Exportación ----------

        public byte[] Exportar(IEnumerable<Vuelo> vuelos)
        {
            var lista = vuelos.ToList();
            using (var ms = new MemoryStream())
            {
                var writer = new XmlTextWriter(ms, new UTF8Encoding(false));
                writer.Formatting = Formatting.Indented;
                writer.Indentation = 2;

                writer.WriteStartDocument();
                writer.WriteStartElement("vuelos");
                writer.WriteAttributeString("generado", DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture));
                writer.WriteAttributeString("cantidad", lista.Count.ToString(CultureInfo.InvariantCulture));

                foreach (var v in lista)
                {
                    writer.WriteStartElement("vuelo");
                    writer.WriteAttributeString("id", v.IdVuelo.ToString(CultureInfo.InvariantCulture));
                    writer.WriteAttributeString("estado", v.Activo ? "Activo" : "Baja");
                    writer.WriteElementString("origen", v.Origen);
                    writer.WriteElementString("destino", v.Destino);
                    writer.WriteElementString("fecha", v.FechaSalida.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture));
                    writer.WriteElementString("hora", v.HoraSalida.ToString(@"hh\:mm", CultureInfo.InvariantCulture));
                    writer.WriteElementString("precio", v.Precio.ToString("0.00", CultureInfo.InvariantCulture));
                    writer.WriteElementString("cupos", v.CuposDisponibles.ToString(CultureInfo.InvariantCulture));
                    writer.WriteEndElement();   // vuelo
                }

                writer.WriteEndElement();       // vuelos
                writer.WriteEndDocument();
                writer.Flush();
                writer.Close();
                return ms.ToArray();
            }
        }

        // ---------- Importación ----------

        /// <summary>
        /// Lee el archivo y crea los vuelos. Un vuelo inválido o repetido no frena a los demás:
        /// queda en Rechazados con el motivo. Si el archivo en sí es inválido lanza FormatException.
        /// </summary>
        public ResultadoImportacion Importar(Stream contenido, VueloBLL vueloBLL)
        {
            var registros = LeerRegistros(contenido);
            var resultado = new ResultadoImportacion { Total = registros.Count };

            // Para no duplicar: vuelos activos que ya existen (misma ruta, fecha y hora) y los ya cargados desde este archivo.
            var existentes = new HashSet<string>(
                vueloBLL.Search(null, null, null, "Todos").Where(v => v.Activo).Select(Clave));

            for (int i = 0; i < registros.Count; i++)
            {
                var r = registros[i];
                var etiqueta = "Vuelo " + (i + 1) + " (" + Valor(r, "origen") + " -> " + Valor(r, "destino") + ")";
                try
                {
                    var vuelo = Convertir(r);
                    if (!existentes.Add(Clave(vuelo)))
                        throw new ArgumentException("Ya existe un vuelo activo con el mismo origen, destino, fecha y hora.");

                    vueloBLL.Create(vuelo);
                    resultado.Importados++;
                }
                catch (InvalidOperationException)
                {
                    throw;   // contingencia de integridad: se corta toda la importación
                }
                catch (Exception ex)
                {
                    resultado.Rechazados.Add(etiqueta + ": " + ex.Message);
                }
            }
            return resultado;
        }

        private static string Clave(Vuelo v)
        {
            return v.Origen.Trim().ToLowerInvariant() + "|" + v.Destino.Trim().ToLowerInvariant() + "|" +
                   v.FechaHoraSalida.ToString("yyyyMMddHHmm", CultureInfo.InvariantCulture);
        }

        private static readonly string[] CAMPOS = { "origen", "destino", "fecha", "hora", "precio", "cupos" };

        private static string Valor(Dictionary<string, string> r, string campo)
        {
            string v;
            return r.TryGetValue(campo, out v) ? v : "?";
        }

        private static string Requerido(Dictionary<string, string> r, string campo)
        {
            string v;
            if (!r.TryGetValue(campo, out v) || string.IsNullOrWhiteSpace(v))
                throw new ArgumentException("Falta el campo <" + campo + ">.");
            return v.Trim();
        }

        private static Vuelo Convertir(Dictionary<string, string> r)
        {
            var origen = Requerido(r, "origen");
            var destino = Requerido(r, "destino");
            var fecha = Requerido(r, "fecha");
            var hora = Requerido(r, "hora");
            var precio = Requerido(r, "precio");
            var cupos = Requerido(r, "cupos");

            if (origen.Length > 100 || destino.Length > 100)
                throw new ArgumentException("Origen y destino admiten hasta 100 caracteres.");

            DateTime f;
            if (!DateTime.TryParseExact(fecha, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out f))
                throw new ArgumentException("La fecha '" + fecha + "' no tiene el formato yyyy-MM-dd.");

            TimeSpan h;
            if (!TimeSpan.TryParseExact(hora, new[] { @"hh\:mm", @"hh\:mm\:ss" }, CultureInfo.InvariantCulture, out h))
                throw new ArgumentException("La hora '" + hora + "' no es válida (use HH:mm).");

            decimal p;
            if (!decimal.TryParse(precio, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out p))
                throw new ArgumentException("El precio '" + precio + "' no es válido.");

            int c;
            if (!int.TryParse(cupos, NumberStyles.None, CultureInfo.InvariantCulture, out c))
                throw new ArgumentException("Los cupos '" + cupos + "' no son válidos (entero mayor o igual a 0).");

            return new Vuelo
            {
                Origen = origen,
                Destino = destino,
                FechaSalida = f,
                HoraSalida = h,
                Precio = p,
                CuposDisponibles = c,
                Activo = true
            };
        }

        /// <summary>
        /// Recorre el XML con XmlTextReader. Valida la estructura (raíz "vuelos", hijos "vuelo" y solo los
        /// campos conocidos); los valores se validan después, vuelo por vuelo.
        /// </summary>
        private static List<Dictionary<string, string>> LeerRegistros(Stream contenido)
        {
            var registros = new List<Dictionary<string, string>>();
            try
            {
                using (var lector = new XmlTextReader(contenido))
                {
                    lector.DtdProcessing = DtdProcessing.Prohibit;   // sin DTD: evita ataques XXE
                    lector.XmlResolver = null;
                    lector.WhitespaceHandling = WhitespaceHandling.None;

                    bool raizOk = false;
                    Dictionary<string, string> actual = null;

                    while (lector.Read())
                    {
                        if (lector.NodeType == XmlNodeType.Element)
                        {
                            if (!raizOk)
                            {
                                if (lector.Name != "vuelos")
                                    throw new FormatException("El elemento raíz debe ser <vuelos>.");
                                raizOk = true;
                            }
                            else if (lector.Name == "vuelo" && lector.Depth == 1)
                            {
                                if (registros.Count >= MAX_VUELOS)
                                    throw new FormatException("El archivo supera el máximo permitido de " + MAX_VUELOS + " vuelos.");
                                actual = new Dictionary<string, string>();
                                registros.Add(actual);
                            }
                            else if (actual != null && lector.Depth == 2 && Array.IndexOf(CAMPOS, lector.Name) >= 0)
                            {
                                var campo = lector.Name;
                                if (actual.ContainsKey(campo))
                                    throw new FormatException("El vuelo " + registros.Count + " repite el campo <" + campo + ">.");
                                actual[campo] = lector.ReadString();   // deja el lector en el cierre del campo
                            }
                            else
                            {
                                throw new FormatException("Elemento inesperado <" + lector.Name + "> en la línea " + lector.LineNumber + ".");
                            }
                        }
                        else if (lector.NodeType == XmlNodeType.EndElement && lector.Name == "vuelo")
                        {
                            actual = null;
                        }
                    }

                    if (!raizOk)
                        throw new FormatException("El archivo está vacío.");
                }
            }
            catch (XmlException ex)
            {
                throw new FormatException("El archivo no es un XML válido: " + ex.Message);
            }
            return registros;
        }
    }
}
