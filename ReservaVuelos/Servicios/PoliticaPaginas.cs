using System;
using System.Collections.Generic;

namespace ReservaVuelos.Servicios
{
    public static class PoliticaPaginas
    {
        // Lista explícita: una página nueva queda bloqueada hasta definir su política.
        // null significa pública, un código exige autenticación y ese permiso.
        private static readonly Dictionary<string, string> paginas = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "Default.aspx", null }, { "BuscarVuelos.aspx", null },
            { "Login.aspx", null }, { "Registro.aspx", null }, { "Logout.aspx", null },
            { "About.aspx", null }, { "Contact.aspx", null },
            { "Mantenimiento.aspx", null }, { "EnConstruccion.aspx", null },
            { "DetalleReserva.aspx", Permisos.Reservar },
            { "MisReservas.aspx", Permisos.VerReservas }, { "MisDatos.aspx", Permisos.VerDatos },
            { "AdminVuelos.aspx", Permisos.VerVuelos },
            { "GestionIntegridad.aspx", Permisos.VerIntegridad },
            { "Backup.aspx", Permisos.VerBackup }, { "Bitacora.aspx", Permisos.VerBitacora },
            { "GestionIdiomas.aspx", Permisos.VerIdiomas }
        };
        public static bool IntentarObtener(string ruta, out string permiso)
        {
            // Se usa la ruta del Page resuelto por ASP.NET, no el texto de la URL.
            string nombre = ruta ?? "";
            if (nombre.StartsWith("~/", StringComparison.Ordinal)) nombre = nombre.Substring(2);
            else nombre = nombre.TrimStart('/');
            return paginas.TryGetValue(nombre, out permiso);
        }
    }
}
