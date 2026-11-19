using System;
using System.IO;
using System.Data.SqlClient;
using System.Reflection;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
class AutorizacionIntegridadTests
{
 static int tests;
 static void Check(bool ok,string name){if(!ok)throw new Exception(name);Console.WriteLine("OK: "+name);tests++;}
 static object Sql(string sql){using(var c=ConexionDAL.GetConnection()){c.Open();using(var cmd=new SqlCommand(sql,c))return cmd.ExecuteScalar();}}
 static string Gate(Usuario usuario,string pagina)
 {
  var c=new HttpContext(new HttpRequest("","http://localhost/"+pagina,""),new HttpResponse(new StringWriter()));
  SessionStateUtility.AddHttpSessionStateToContext(c,new HttpSessionStateContainer("test",new SessionStateItemCollection(),new HttpStaticObjectsCollection(),20,true,HttpCookieMode.UseCookies,SessionStateMode.InProc,false));
  HttpContext.Current=c;SesionService.SetUser(usuario);c.Handler=new Page{AppRelativeVirtualPath="~/"+pagina};
  try{return (string)typeof(AutorizacionService).GetMethod("PrepararPeticion",BindingFlags.Static|BindingFlags.NonPublic).Invoke(null,new object[]{c});}
  catch(TargetInvocationException e){throw e.InnerException;}
 }
 static void Main()
 {
  var integrity=new IntegrityService();integrity.RecalculateAll(null,"Fixture");
  int wmId=Convert.ToInt32(Sql("SELECT TOP 1 IdUsuario FROM Usuarios WHERE Rol='WebMaster'"));
  int otroId=Convert.ToInt32(Sql("SELECT TOP 1 IdUsuario FROM Usuarios WHERE Rol='Usuario'"));
  var dal=new UsuarioDAL();var wm=dal.GetById(wmId);var otro=dal.GetById(otroId);
  try{Gate(wm,"DetalleReserva.aspx");throw new Exception("WebMaster pudo reservar");}
  catch(HttpException e){Check(e.GetHttpCode()==403,"Base sana: WebMaster sin permiso de reserva conserva 403");}
  Sql("UPDATE Usuarios SET Rol='Administrador' WHERE IdUsuario="+otroId);
  Check(Gate(wm,"DetalleReserva.aspx")=="~/GestionIntegridad.aspx","Rol de otro usuario alterado: WebMaster va a integridad antes del 403");
  Check(integrity.IsContingencyMode(),"Manipulacion activa contingencia");
  Check(SesionService.GetUser().IdUsuario==wmId,"WebMaster no alterado conserva su sesion");
  Check(Gate(wm,"GestionIntegridad.aspx")==null,"WebMaster no alterado conserva acceso de recuperacion");
  Check(Gate(otro,"DetalleReserva.aspx")=="~/Mantenimiento.aspx","Fila propia alterada no concede permisos");
  Check(SesionService.GetUser()==null,"Sesion de fila alterada se invalida");
  Sql("UPDATE Usuarios SET Rol='Usuario' WHERE IdUsuario="+otroId);
  Check(integrity.TryResolveAfterValidation(wmId,"Restaurado valor original").IsValid,"Restaurar rol original permite recuperar sin recalcular");
  Check(Gate(otro,"DetalleReserva.aspx")==null,"Base recuperada: Usuario puede reservar");
  // Un cambio legitimo actualiza sus digitos y debe aplicarse en la siguiente peticion.
  using(var c=ConexionDAL.GetConnection()){c.Open();using(var tx=c.BeginTransaction()){
   using(var cmd=new SqlCommand("UPDATE Usuarios SET Rol='Administrador' WHERE IdUsuario=@Id",c,tx)){cmd.Parameters.AddWithValue("@Id",otroId);cmd.ExecuteNonQuery();}
   integrity.UpdateRecordAndTableDVV(c,tx,"Usuarios",otroId);tx.Commit();}}
  Check(Gate(otro,"AdminVuelos.aspx")==null,"Cambio legitimo de rol aplica sin contingencia");
  Check(!integrity.IsContingencyMode(),"Cambio legitimo no activa mantenimiento");
  Console.WriteLine(tests+" comprobaciones aprobadas");
 }
}
