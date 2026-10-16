using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.Services;
using System.Web.Services.Protocols;

namespace ReservaVuelos
{
    public class ResultadoLogin
    {
        public bool Exitoso { get; set; }
        public string Codigo { get; set; }      
        public string Mensaje { get; set; }
        public string Token { get; set; }       // se envía en las operaciones que lo requieren
        public int IdUsuario { get; set; }
        public string Nombre { get; set; }
        public string Email { get; set; }
        public string Rol { get; set; }
    }

    public class LineaCalculo
    {
        public int IdVuelo { get; set; }
        public string Descripcion { get; set; }
        public decimal PrecioUnitario { get; set; }
        public int Cantidad { get; set; }
        public decimal Subtotal { get; set; }
    }

    public class CalculoReserva
    {
        public bool Valido { get; set; }
        public string Mensaje { get; set; }
        public decimal Total { get; set; }
        public LineaCalculo[] Lineas { get; set; }
    }

    public class ResultadoImportacionWS
    {
        public bool Exitoso { get; set; }
        public string Mensaje { get; set; }
        public int Total { get; set; }
        public int Importados { get; set; }
        public string[] Rechazados { get; set; }
    }

    /// <summary>
    /// Web service de AeroLink (ASMX, SOAP). Es una capa fina sobre la BLL y los servicios que ya existen:
    /// no tiene reglas de negocio propias.
    ///
    ///  - Login: valida credenciales y devuelve un token de la llamada siguiente.
    ///  - CalcularPrecioReserva: precio de una reserva según los vuelos y la cantidad de pasajeros.
    ///  - ObtenerInformeVuelosXml: informe de vuelos en XML (solo Administrador).
    ///  - ImportarVuelosXml: carga masiva de vuelos desde XML (solo Administrador).
    ///
    /// El web service no comparte la sesión del navegador: cada llamada es independiente. Por eso las
    /// operaciones restringidas reciben el token que entrega Login, y el servicio vuelve a verificar el rol.
    /// </summary>
    [WebService(Namespace = "http://aerolink.reservavuelos/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    public class AeroLinkWS : WebService
    {
        private const int MINUTOS_TOKEN = 30;

        private class DatosToken
        {
            public int IdUsuario;
            public string Email;
            public DateTime Vence;
        }

        private static readonly ConcurrentDictionary<string, DatosToken> _tokens =
            new ConcurrentDictionary<string, DatosToken>();

        // ---------- Operaciones ----------

        [WebMethod(Description = "Valida el email y la contraseña. Si son correctos devuelve los datos básicos del usuario y un token.")]
        public ResultadoLogin Login(string email, string password)
        {
            try
            {
                Usuario usuario = new SeguridadService().Authenticate((email ?? "").Trim(), password ?? "");
                if (usuario == null)
                    return new ResultadoLogin { Exitoso = false, Codigo = "CREDENCIALES", Mensaje = "Usuario o contraseña incorrectos." };

                string token = Guid.NewGuid().ToString("N");
                LimpiarVencidos();
                _tokens[token] = new DatosToken { IdUsuario = usuario.IdUsuario, Email = usuario.Email, Vence = DateTime.Now.AddMinutes(MINUTOS_TOKEN) };

                return new ResultadoLogin
                {
                    Exitoso = true,
                    Codigo = "OK",
                    Mensaje = "Ingreso correcto.",
                    Token = token,
                    IdUsuario = usuario.IdUsuario,
                    Nombre = usuario.Nombre,
                    Email = usuario.Email,
                    Rol = usuario.Rol
                };
            }
            catch (Exception ex)
            {
                return new ResultadoLogin { Exitoso = false, Codigo = "ERROR", Mensaje = ex.Message };
            }
        }

        [WebMethod(Description = "Calcula el precio de una reserva: suma, para cada vuelo, el precio unitario por la cantidad de pasajeros.")]
        public CalculoReserva CalcularPrecioReserva(int[] idsVuelo, int cantidadPasajeros)
        {
            if (idsVuelo == null || idsVuelo.Length == 0)
                return new CalculoReserva { Valido = false, Mensaje = "Indique al menos un vuelo.", Lineas = new LineaCalculo[0] };
            if (cantidadPasajeros <= 0)
                return new CalculoReserva { Valido = false, Mensaje = "La cantidad de pasajeros debe ser mayor a cero.", Lineas = new LineaCalculo[0] };

            VueloBLL vuelos = new VueloBLL();
            List<LineaCalculo> lineas = new List<LineaCalculo>();
            foreach (int id in idsVuelo)
            {
                Vuelo v = vuelos.GetById(id);
                if (v == null)
                    return new CalculoReserva { Valido = false, Mensaje = "No existe el vuelo " + id + ".", Lineas = new LineaCalculo[0] };
                if (!v.Activo)
                    return new CalculoReserva { Valido = false, Mensaje = "El vuelo " + id + " está dado de baja.", Lineas = new LineaCalculo[0] };

                lineas.Add(new LineaCalculo
                {
                    IdVuelo = v.IdVuelo,
                    Descripcion = v.Origen + " - " + v.Destino,
                    PrecioUnitario = v.Precio,
                    Cantidad = cantidadPasajeros,
                    Subtotal = v.Precio * cantidadPasajeros
                });
            }

            return new CalculoReserva
            {
                Valido = true,
                Mensaje = "OK",
                Lineas = lineas.ToArray(),
                Total = lineas.Sum(l => l.Subtotal)
            };
        }

        [WebMethod(Description = "Informe de vuelos en XML. Filtro: Todos, Activos o Baja. Requiere el token de un Administrador.")]
        public string ObtenerInformeVuelosXml(string token, string filtro)
        {
            DatosToken datos = ExigirPermiso(token, Permisos.ExportarVuelos);

            string estado = string.IsNullOrWhiteSpace(filtro) ? "Activos" : filtro.Trim();
            List<Vuelo> lista = new VueloBLL().Search(null, null, null, estado);
            string xml = Encoding.UTF8.GetString(new XmlVuelosService().Exportar(lista));

            Registrar(datos.Email, "Informe XML de vuelos por web service. Filtro: " + estado + " - Cantidad: " + lista.Count, 1);
            return xml;
        }

        [WebMethod(Description = "Importa vuelos desde un XML (mismo formato que el informe). Requiere el token de un Administrador.")]
        public ResultadoImportacionWS ImportarVuelosXml(string token, string xml)
        {
            DatosToken datos = ExigirPermiso(token, Permisos.ImportarVuelos);

            if (string.IsNullOrWhiteSpace(xml))
                return new ResultadoImportacionWS { Exitoso = false, Mensaje = "El XML está vacío.", Rechazados = new string[0] };

            byte[] bytes = new UTF8Encoding(false).GetBytes(xml);
            if (bytes.Length > XmlVuelosService.MAX_BYTES)
                return new ResultadoImportacionWS { Exitoso = false, Mensaje = "El XML supera el máximo de " + (XmlVuelosService.MAX_BYTES / 1024) + " KB.", Rechazados = new string[0] };

            try
            {
                XmlVuelosService.ResultadoImportacion r;
                using (MemoryStream ms = new MemoryStream(bytes))
                    r = new XmlVuelosService().Importar(ms, new VueloBLL());

                Registrar(datos.Email, "Importación XML de vuelos por web service. Importados: " + r.Importados + " - Rechazados: " + r.Rechazados.Count, r.Rechazados.Count > 0 ? 2 : 1);

                return new ResultadoImportacionWS
                {
                    Exitoso = true,
                    Mensaje = "Importación finalizada.",
                    Total = r.Total,
                    Importados = r.Importados,
                    Rechazados = r.Rechazados.ToArray()
                };
            }
            catch (FormatException ex)
            {
                return new ResultadoImportacionWS { Exitoso = false, Mensaje = ex.Message, Rechazados = new string[0] };
            }
        }

        // ---------- Auxiliares ----------

        private static DatosToken ExigirPermiso(string token, string permiso)
        {
            DatosToken datos;
            if (string.IsNullOrEmpty(token) || !_tokens.TryGetValue(token, out datos) || datos.Vence < DateTime.Now)
                throw new SoapException("Token inválido o vencido. Inicie sesión nuevamente.", SoapException.ClientFaultCode);

            // El token identifica al usuario; el rol y el estado se consultan nuevamente.
            Usuario usuario = new UsuarioBLL().GetByEmail(datos.Email);
            if (usuario == null || usuario.IdUsuario != datos.IdUsuario || !usuario.Activo || !AutorizacionService.TienePermiso(usuario, permiso))
                throw new SoapException("No tiene permiso para esta operación.", SoapException.ClientFaultCode);
            if (new IntegrityService().IsContingencyMode())
                throw new SoapException("Operación no disponible durante contingencia.", SoapException.ClientFaultCode);

            datos.Vence = DateTime.Now.AddMinutes(MINUTOS_TOKEN);
            return datos;
        }

        private static void LimpiarVencidos()
        {
            DatosToken descartado;
            foreach (KeyValuePair<string, DatosToken> par in _tokens.Where(p => p.Value.Vence < DateTime.Now).ToList())
                _tokens.TryRemove(par.Key, out descartado);
        }

        private static void Registrar(string email, string accion, int criticidad)
        {
            try
            {
                new BitacoraBLL().Create(new ReservaVuelos.BE.Bitacora
                {
                    Fecha = DateTime.Now,
                    Usuario = email,
                    Accion = accion,
                    Criticidad = criticidad,
                    Pantalla = "AeroLinkWS"
                });
            }
            catch (Exception)
            {
                // La bitácora no debe impedir la operación.
            }
        }
    }
}
