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
    /// Exportar: genera el XML con XmlTextWriter.
    /// Importar: lee el XML con XmlDocument y crea cada vuelo con VueloBLL.Create
    /// (mismas reglas y mismo cálculo de DVH/DVV que al crear un vuelo a mano).
    ///
    /// Formato:
    ///   &lt;vuelos&gt;
    ///     &lt;vuelo&gt;
    ///       &lt;origen&gt;Buenos Aires&lt;/origen&gt;  &lt;destino&gt;Mendoza&lt;/destino&gt;
    ///       &lt;fecha&gt;2026-12-05&lt;/fecha&gt;  &lt;hora&gt;08:30&lt;/hora&gt;
    ///       &lt;precio&gt;120000.00&lt;/precio&gt;  &lt;cupos&gt;150&lt;/cupos&gt;
    ///     &lt;/vuelo&gt;
    ///   &lt;/vuelos&gt;
    /// </summary>
    public class XmlVuelosService
    {
        public const int MAX_BYTES = 1024 * 1024;   // 1 MB

        public class ResultadoImportacion
        {
            public int Total { get; set; }
            public int Importados { get; set; }
            public List<string> Rechazados { get; } = new List<string>();
        }

        // ---------- Exportación ----------

        public byte[] Exportar(IEnumerable<Vuelo> vuelos)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                XmlTextWriter writer = new XmlTextWriter(ms, new UTF8Encoding(false));
                writer.Formatting = Formatting.Indented;

                writer.WriteStartDocument();
                writer.WriteStartElement("vuelos");

                foreach (Vuelo v in vuelos)
                {
                    writer.WriteStartElement("vuelo");
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
        /// Lee el archivo y crea los vuelos. Un vuelo inválido no frena a los demás:
        /// queda en Rechazados con el motivo. Si el archivo en sí es inválido lanza FormatException.
        /// </summary>
        public ResultadoImportacion Importar(Stream contenido, VueloBLL vueloBLL)
        {
            XmlDocument doc = new XmlDocument();
            doc.XmlResolver = null;   // sin recursos externos (evita XXE)
            try
            {
                doc.Load(contenido);
            }
            catch (XmlException ex)
            {
                throw new FormatException("El archivo no es un XML válido: " + ex.Message);
            }

            if (doc.DocumentElement == null || doc.DocumentElement.Name != "vuelos")
                throw new FormatException("El elemento raíz debe ser <vuelos>.");

            XmlNodeList nodos = doc.DocumentElement.SelectNodes("vuelo");
            ResultadoImportacion resultado = new ResultadoImportacion { Total = nodos.Count };

            for (int i = 0; i < nodos.Count; i++)
            {
                try
                {
                    Vuelo vuelo = Convertir(nodos[i]);
                    vueloBLL.Create(vuelo);
                    resultado.Importados++;
                }
                catch (InvalidOperationException)
                {
                    throw;   // contingencia de integridad: se corta toda la importación
                }
                catch (Exception ex)
                {
                    resultado.Rechazados.Add("Vuelo " + (i + 1) + ": " + ex.Message);
                }
            }
            return resultado;
        }

        private static Vuelo Convertir(XmlNode nodo)
        {
            try
            {
                return new Vuelo
                {
                    Origen = Texto(nodo, "origen"),
                    Destino = Texto(nodo, "destino"),
                    FechaSalida = DateTime.ParseExact(Texto(nodo, "fecha"), "yyyy-MM-dd", CultureInfo.InvariantCulture),
                    HoraSalida = TimeSpan.ParseExact(Texto(nodo, "hora"), @"hh\:mm", CultureInfo.InvariantCulture),
                    Precio = decimal.Parse(Texto(nodo, "precio"), CultureInfo.InvariantCulture),
                    CuposDisponibles = int.Parse(Texto(nodo, "cupos"), CultureInfo.InvariantCulture),
                    Activo = true
                };
            }
            catch (FormatException)
            {
                throw new ArgumentException("Hay un dato con formato inválido (fecha yyyy-MM-dd, hora HH:mm, precio y cupos numéricos).");
            }
        }

        private static string Texto(XmlNode nodo, string campo)
        {
            XmlNode hijo = nodo.SelectSingleNode(campo);
            if (hijo == null || string.IsNullOrWhiteSpace(hijo.InnerText))
                throw new ArgumentException("Falta el campo <" + campo + ">.");
            return hijo.InnerText.Trim();
        }
    }
}
