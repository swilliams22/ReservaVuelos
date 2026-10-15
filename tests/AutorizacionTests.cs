using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Data.SqlClient;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.Services.Protocols;
using System.Text.RegularExpressions;
using ReservaVuelos;
using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;

class AutorizacionTests
{
    static int pruebas;
    static void Verificar(bool condicion, string nombre)
    {
        if (!condicion) throw new Exception("FALLO: " + nombre);
        pruebas++;
        Console.WriteLine("OK " + nombre);
    }
    static void Rechaza(Action accion, string nombre)
    {
        try { accion(); }
        catch (HttpException ex) { Verificar(ex.GetHttpCode() == 403, nombre); return; }
        throw new Exception("FALLO: no rechazó " + nombre);
    }
    static object Sql(string sql)
    {
        using (var cn = ConexionDAL.GetConnection())
        using (var cmd = new SqlCommand(sql, cn)) { cn.Open(); return cmd.ExecuteScalar(); }
    }
    static Usuario Crear(string rol)
    {
        string hash, salt;
        HashService.CreateHash("Prueba-Composite-2026!", out hash, out salt);
        var u = new Usuario { Nombre=rol, Email=rol+"@test.local", Rol=rol, Activo=true, FechaAlta=DateTime.Now, PasswordHash=hash, PasswordSalt=salt };
        u.IdUsuario = new UsuarioDAL().Create(u);
        return u;
    }
    static HttpContext Contexto(Usuario usuario, string pagina)
    {
        HttpContext.Current = null;
        var c = new HttpContext(new HttpRequest("", "http://localhost/"+pagina, ""), new HttpResponse(new StringWriter()));
        SessionStateUtility.AddHttpSessionStateToContext(c, new HttpSessionStateContainer("test", new SessionStateItemCollection(), new HttpStaticObjectsCollection(), 20, true, HttpCookieMode.UseCookies, SessionStateMode.InProc, false));
        HttpContext.Current = c;
        if (usuario != null) SesionService.SetUser(usuario);
        c.Handler = new Page { AppRelativeVirtualPath="~/"+pagina };
        return c;
    }
    static void Gate(Usuario usuario, string pagina) { AutorizacionService.ControlarPeticion(Contexto(usuario,pagina)); }

    static void Main()
    {
        // Este ejecutable sólo se usa contra la base temporal que crea Test-Autorizacion.ps1.
        using (var cn=ConexionDAL.GetConnection())
            if (!cn.Database.StartsWith("ReservaVuelosAuthTest_", StringComparison.Ordinal)) throw new Exception("Base de prueba requerida.");

        var hoja=new PermisoSimple("Accion");
        var padre=new GrupoPermisos("Padre"); var hijo=new GrupoPermisos("Hijo");
        hijo.Agregar(hoja); padre.Agregar(hijo);
        Verificar(padre.TienePermiso("accion") && !padre.TienePermiso("Padre"), "Composite recursivo: sólo hojas conceden permisos");
        try { hijo.Agregar(padre); throw new Exception("Aceptó ciclo"); }
        catch (InvalidOperationException) { Verificar(true,"Composite rechaza ciclos"); }

        // Simular la base anterior al Composite con integridad inicializada.
        new IntegrityService().EnsureStartupValidation();
        Sql("DROP TABLE dbo.PermisoRelacion; DROP TABLE dbo.Permisos; ALTER TABLE dbo.Usuarios DROP CONSTRAINT CK_Usuarios_Rol; ALTER TABLE dbo.Usuarios ADD CONSTRAINT CK_Usuarios_Rol CHECK (Rol IN ('Usuario','Administrador'));");
        string database;
        using (var cn=ConexionDAL.GetConnection()) database=cn.Database;
        var deployment=File.ReadAllText(Path.Combine(Environment.GetEnvironmentVariable("AUTH_SOURCE"),"..","base","ActualizarBD_2026-10-15.sql")).Replace("ReservaVuelosDB",database);
        int cuentasAntes=Convert.ToInt32(Sql("SELECT COUNT(*) FROM Usuarios"));
        foreach(var lote in Regex.Split(deployment,@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
            if(!string.IsNullOrWhiteSpace(lote)) Sql(lote);
        Verificar(Convert.ToInt32(Sql("SELECT COUNT(*) FROM Usuarios"))==cuentasAntes,"Actualización conserva las cuentas existentes");
        Verificar(new PermisoDAL().ObtenerPorRol("WebMaster").TienePermiso(Permisos.RestaurarBackup),"Actualización crea el grupo WebMaster con permisos técnicos");
        Verificar(new IntegrityService().ValidateTable("Usuarios").IsValid,"Migración conserva DVH/DVV de Usuarios");
        Sql("DELETE r FROM PermisoRelacion r JOIN Permisos p ON p.IdPermiso=r.IdPadre JOIN Permisos h ON h.IdPermiso=r.IdHijo WHERE p.Codigo='GestionVuelos' AND h.Codigo='Vuelos.Crear'");
        foreach(var lote in Regex.Split(deployment,@"^\s*GO\s*$",RegexOptions.Multiline|RegexOptions.IgnoreCase))
            if(!string.IsNullOrWhiteSpace(lote)) Sql(lote);
        Verificar(Convert.ToInt32(Sql("SELECT COUNT(*) FROM Usuarios"))==cuentasAntes,"Reejecución de actualización no cambia cuentas");
        Verificar(!new PermisoDAL().ObtenerPorRol("Administrador").TienePermiso(Permisos.CrearVuelo),"Reejecución no repone permisos revocados");
        Sql("INSERT PermisoRelacion SELECT p.IdPermiso,h.IdPermiso FROM Permisos p CROSS JOIN Permisos h WHERE p.Codigo='GestionVuelos' AND h.Codigo='Vuelos.Crear'");

        var usuario=Crear("Usuario"); var admin=Crear("Administrador"); var wm=Crear("WebMaster");
        // Regresión: el selector propone Córdoba y el seed guarda Cordoba.
        var vuelos = new VueloDAL();
        var sinTilde = vuelos.Search(null,"Cordoba",null);
        var conTilde = vuelos.Search(null,"Córdoba",null);
        Verificar(sinTilde.Count>0 && sinTilde.Select(v=>v.IdVuelo).SequenceEqual(conTilde.Select(v=>v.IdVuelo)),"Destino con y sin tilde encuentra los mismos vuelos");
        Verificar(vuelos.Search(null,"  cÓrDoBa  ",null).Select(v=>v.IdVuelo).SequenceEqual(sinTilde.Select(v=>v.IdVuelo)),"Destino ignora mayúsculas y espacios externos");
        var origen = vuelos.Search("Cordoba",null,null);
        Verificar(origen.Count>0 && origen.Select(v=>v.IdVuelo).SequenceEqual(vuelos.Search("Córdoba",null,null).Select(v=>v.IdVuelo)),"Origen con y sin tilde encuentra los mismos vuelos");
        foreach (var u in new[]{usuario,admin,wm})
        {
            HttpContext.Current=null;
            foreach (var campo in typeof(Permisos).GetFields(BindingFlags.Public|BindingFlags.Static))
            {
                var codigo=(string)campo.GetRawConstantValue();
                bool esperado=codigo.StartsWith("Reservas.") || codigo.StartsWith("Datos.") ||
                    (u.Rol=="Administrador" && codigo.StartsWith("Vuelos.")) ||
                    (u.Rol=="WebMaster" && !codigo.StartsWith("Vuelos."));
                Verificar(AutorizacionService.TienePermiso(u,codigo)==esperado,u.Rol+": "+codigo);
            }
        }
        Verificar(!AutorizacionService.TienePermiso(null,Permisos.CrearVuelo),"Anónimo sin permisos");
        Verificar(!AutorizacionService.TienePermiso(new Usuario{Activo=true,Rol="Inventado"},Permisos.VerDatos),"Rol desconocido sin permisos");
        usuario.Activo=false;
        Verificar(!AutorizacionService.TienePermiso(usuario,Permisos.VerDatos),"Usuario inactivo sin permisos"); usuario.Activo=true;

        foreach (var archivo in Directory.GetFiles(Environment.GetEnvironmentVariable("AUTH_SOURCE"),"*.aspx"))
        {
            string permiso;
            Verificar(PoliticaPaginas.IntentarObtener("~/"+Path.GetFileName(archivo),out permiso),"Política explícita: "+Path.GetFileName(archivo));
        }
        string ignorado;
        Verificar(!PoliticaPaginas.IntentarObtener("~/Nueva.aspx",out ignorado),"Página nueva denegada por defecto");
        Verificar(!PoliticaPaginas.IntentarObtener("~/otra/AdminVuelos.aspx",out ignorado),"Una subcarpeta no hereda políticas por nombre");

        Gate(usuario,"MisReservas.aspx"); Verificar(true,"Usuario accede a sus reservas");
        Gate(admin,"AdminVuelos.aspx"); Verificar(true,"Administrador accede por URL directa");
        Gate(wm,"GestionIntegridad.aspx"); Verificar(true,"WebMaster accede a integridad");
        Rechaza(()=>Gate(usuario,"AdminVuelos.aspx"),"Usuario bloqueado por URL de administración");
        Rechaza(()=>Gate(admin,"Backup.aspx"),"Administrador bloqueado por URL técnica");
        Rechaza(()=>Gate(wm,"AdminVuelos.aspx"),"WebMaster no hereda Administrador");
        Rechaza(()=>Gate(admin,"Nueva.aspx"),"Handler de página sin política bloqueado");
        Contexto(usuario,"MisReservas.aspx");
        Rechaza(()=>AutorizacionService.Exigir(Permisos.CrearVuelo),"Acción forzada sin permiso bloqueada");
        Sql("UPDATE Usuarios SET Rol='Usuario' WHERE IdUsuario="+admin.IdUsuario);
        Rechaza(()=>Gate(admin,"AdminVuelos.aspx"),"Cambio de rol invalida acceso de sesión abierta");
        Sql("UPDATE Usuarios SET Rol='Administrador' WHERE IdUsuario="+admin.IdUsuario);

        // Cambiar permisos de un grupo no exige cerrar sesión; tampoco borra el permiso de lectura.
        string bajaRelacion="DELETE r FROM PermisoRelacion r JOIN Permisos p ON p.IdPermiso=r.IdPadre JOIN Permisos h ON h.IdPermiso=r.IdHijo WHERE p.Codigo='GestionVuelos' AND h.Codigo='Vuelos.Crear'";
        Sql(bajaRelacion);
        Gate(admin,"AdminVuelos.aspx");
        Rechaza(()=>AutorizacionService.Exigir(Permisos.CrearVuelo),"Permiso de acción revocado con sesión abierta");
        Sql("INSERT PermisoRelacion SELECT p.IdPermiso,h.IdPermiso FROM Permisos p CROSS JOIN Permisos h WHERE p.Codigo='GestionVuelos' AND h.Codigo='Vuelos.Crear'");

        try { Sql("INSERT PermisoRelacion SELECT p.IdPermiso,h.IdPermiso FROM Permisos p CROSS JOIN Permisos h WHERE p.Codigo='OperacionesUsuario' AND h.Codigo='Usuario'"); throw new Exception("SQL aceptó ciclo"); }
        catch (SqlException ex) { Verificar(ex.Number==50002,"SQL impide ciclos de grupos"); }
        try { Sql("INSERT PermisoRelacion SELECT p.IdPermiso,h.IdPermiso FROM Permisos p CROSS JOIN Permisos h WHERE p.Codigo='Vuelos.Crear' AND h.Codigo='Usuario'"); throw new Exception("SQL aceptó hoja con hijos"); }
        catch (SqlException ex) { Verificar(ex.Number==50001,"SQL impide hojas con hijos"); }
        try { Sql("UPDATE Permisos SET EsGrupo=0 WHERE Codigo='GestionVuelos'"); throw new Exception("SQL cambió grupo con hijos a hoja"); }
        catch (SqlException ex) { Verificar(ex.Number==50003,"SQL protege el tipo de grupo"); }

        HttpContext.Current=null;
        var ws=new AeroLinkWS();
        var login=ws.Login(admin.Email,"Prueba-Composite-2026!");
        if (!login.Exitoso) throw new Exception("Login SOAP de prueba: "+login.Codigo+" "+login.Mensaje);
        var token=login.Token;
        Verificar(!string.IsNullOrEmpty(token),"SOAP entrega token autenticado");
        ws.ObtenerInformeVuelosXml(token,"Todos"); Verificar(true,"SOAP permite exportar a Administrador");
        Sql("UPDATE Usuarios SET Rol='Usuario' WHERE IdUsuario="+admin.IdUsuario);
        try { ws.ObtenerInformeVuelosXml(token,"Todos"); throw new Exception("Token conservó privilegios"); }
        catch (SoapException) { Verificar(true,"SOAP vuelve a consultar rol con token existente"); }
        Sql("UPDATE Usuarios SET Rol='Administrador' WHERE IdUsuario="+admin.IdUsuario);
        Sql("UPDATE Usuarios SET Activo=0 WHERE IdUsuario="+admin.IdUsuario);
        try { ws.ObtenerInformeVuelosXml(token,"Todos"); throw new Exception("Token de inactivo aceptado"); }
        catch (SoapException) { Verificar(true,"SOAP rechaza cuenta desactivada"); }
        Sql("UPDATE Usuarios SET Activo=1 WHERE IdUsuario="+admin.IdUsuario);

        Sql("INSERT Clientes(IdUsuario,Nombre,Email) VALUES ("+usuario.IdUsuario+",'Titular','titular@test.local')");
        int reserva=Convert.ToInt32(Sql("INSERT ReservaCabecera(IdCliente,IdUsuarioCreador) SELECT IdCliente,IdUsuario FROM Clientes WHERE IdUsuario="+usuario.IdUsuario+"; SELECT SCOPE_IDENTITY();"));
        Verificar(new ReservaCabeceraDAL().Cancel(reserva,admin.IdUsuario)==0,"No puede cancelar reserva ajena aun siendo administrador");
        Verificar(new ReservaCabeceraDAL().Cancel(reserva,usuario.IdUsuario)==1,"Titular puede cancelar su reserva");
        Verificar(new ReservaCabeceraDAL().Cancel(reserva,usuario.IdUsuario)==0,"Cancelación sigue siendo idempotente");
        Rechaza(()=>new ReservaCabeceraDAL().Cancel(reserva,null),"Cancelación anónima rechazada");

        Sql("UPDATE ConfiguracionSistema SET ModoContingencia=1 WHERE IdConfiguracion=1");
        var integridad=new IntegrityService();
        Verificar(!integridad.CanAccessDuringContingency("AdminVuelos.aspx",admin),"Contingencia bloquea operación administrativa");
        Verificar(integridad.CanAccessDuringContingency("Backup.aspx",wm),"Contingencia conserva recuperación técnica");
        Sql("UPDATE ConfiguracionSistema SET ModoContingencia=0 WHERE IdConfiguracion=1");
        Console.WriteLine("TOTAL: "+pruebas+" verificaciones correctas.");
    }
}
