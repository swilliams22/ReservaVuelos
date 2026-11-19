using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using ReservaVuelos;
using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
class FiltroFixture : BasePage
{
 public static List<string> Aplicar(string[] rows,string text) {return FiltrarGrilla(rows,text,x=>x);}
}
class IntegridadAmpliadaTests
{
 static int tests;
 static void Check(bool ok,string name){if(!ok)throw new Exception(name);Console.WriteLine("OK: "+name);tests++;}
 static object Sql(string sql){using(var c=ConexionDAL.GetConnection()){c.Open();using(var q=new SqlCommand(sql,c))return q.ExecuteScalar();}}
 static void Tamper(string table,string sql)
 {
  using(var c=ConexionDAL.GetConnection())
  {
   c.Open();using(var tx=c.BeginTransaction())
   {
    using(var cmd=new SqlCommand(sql,c,tx))cmd.ExecuteNonQuery();
    var result=new IntegrityValidationResult();
    typeof(IntegrityService).GetMethod("ValidateTable",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(new IntegrityService(),new object[]{c,tx,table,result});
    Check(!result.IsValid,"Detecta alteracion en "+table);
    tx.Rollback();
   }
  }
 }
 static void Main()
 {
  var integrity=new IntegrityService();
  integrity.RecalculateAll(null,"Fixture de pruebas");
  Check(integrity.ValidateAll().IsValid,"Base inicial valida");
  Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM IntegridadDVV"))==15,"15 tablas protegidas");
  foreach(string t in new[]{"Idioma","Etiqueta","Traduccion","Permisos","PermisoRelacion","ConfiguracionSistema","IntegridadError"})
   Check(Convert.ToInt32(Sql("SELECT COUNT(*) FROM "+t+" t JOIN DV_"+t+" v ON v.IdRegistro="+(t=="Traduccion"?"CONCAT(t.IdIdioma,':',t.IdEtiqueta)":t=="PermisoRelacion"?"CONCAT(t.IdPadre,':',t.IdHijo)":"CONVERT(nvarchar(100),t."+new Dictionary<string,string>{{"Idioma","IdIdioma"},{"Etiqueta","IdEtiqueta"},{"Permisos","IdPermiso"},{"ConfiguracionSistema","IdConfiguracion"},{"IntegridadError","IdError"}}[t]+")")+" WHERE t.DVH<>v.Calculado"))==0,"Paridad SQL/C# "+t);
  var idiomas=new IdiomaDAL();int idioma=idiomas.Crear("pt-BR","Portugues");idiomas.CambiarActivo(idioma,true);
  int etiqueta=Convert.ToInt32(Sql("SELECT MIN(IdEtiqueta) FROM Etiqueta"));
  idiomas.GuardarTraducciones(idioma,new Dictionary<int,string>{{etiqueta,"Teste"}});
  Check(integrity.ValidateAll().IsValid,"Alta idioma y traduccion legitimas");
  idiomas.GuardarTraducciones(idioma,new Dictionary<int,string>{{etiqueta,""}});
  Check(integrity.ValidateAll().IsValid,"Baja traduccion con clave compuesta");
  var permisos=new PermisoDAL();int grupo=permisos.CrearGrupo("PruebaDV");int hoja=Convert.ToInt32(Sql("SELECT MIN(IdPermiso) FROM Permisos WHERE EsGrupo=0"));
  permisos.AgregarHijo(grupo,hoja);
  Check(integrity.ValidateAll().IsValid,"Alta de perfil y relacion legitimas");
  int wm=Convert.ToInt32(Sql("SELECT TOP 1 IdUsuario FROM Usuarios WHERE Rol='WebMaster'"));
  Check(permisos.QuitarHijo(grupo,hoja,wm,null),"Quitar relacion");
  Check(permisos.EliminarGrupo(grupo,wm,null),"Eliminar perfil");
  Check(integrity.ValidateAll().IsValid,"Bajas de perfiles mantienen DVH/DVV");
  Tamper("Idioma","UPDATE Idioma SET Nombre=N'ALTERADO XYZ' WHERE IdIdioma=(SELECT MIN(IdIdioma) FROM Idioma)");
  Tamper("Etiqueta","UPDATE Etiqueta SET Descripcion=N'ALTERADO XYZ' WHERE IdEtiqueta=(SELECT MIN(IdEtiqueta) FROM Etiqueta)");
  Tamper("Traduccion","UPDATE Traduccion SET Texto=N'ALTERADO XYZ' WHERE IdEtiqueta=(SELECT MIN(IdEtiqueta) FROM Traduccion)");
  Tamper("Permisos","INSERT Permisos(Codigo,EsGrupo) VALUES(N'PerfilInyectado',1)");
  Tamper("PermisoRelacion","DELETE TOP(1) FROM PermisoRelacion");
  Tamper("ConfiguracionSistema","UPDATE ConfiguracionSistema SET MotivoContingencia=N'ALTERADO XYZ'");
  Tamper("IntegridadError","INSERT IntegridadError(Fecha,TipoError,NombreTabla,Estado) VALUES(SYSDATETIME(),'DVH','Idioma','Activo')");
  Check(integrity.ValidateAll().IsValid,"Rollback de manipulaciones no altera la base");
  string nombre=Convert.ToString(Sql("SELECT Nombre FROM Idioma WHERE IdIdioma=1"));
  Sql("UPDATE Idioma SET Nombre=N'ALTERADO XYZ' WHERE IdIdioma=1");
  Check(!integrity.ValidateAllAndPersist().IsValid,"Persistir inconsistencias activa contingencia");
  Sql("UPDATE Idioma SET Nombre=N'"+nombre.Replace("'","''")+"' WHERE IdIdioma=1");
  Check(integrity.ValidateAll().IsValid,"Registrar errores no invalida sus digitos");
  Check(integrity.TryResolveAfterValidation(null,"Prueba de recuperacion").IsValid,"Resolver errores mantiene integridad");
  Check(integrity.ValidateAll().IsValid,"Configuracion y errores validos despues de recuperar");
  Check(FiltroFixture.Aplicar(new[]{"Buenos Aires","CORDOBA"},"cordoba").SequenceEqual(new[]{"CORDOBA"}),"Filtro ignora mayusculas");
  Check(FiltroFixture.Aplicar(new[]{"Uno","Dos"},"").Count==2,"Limpiar filtro devuelve todo");
  Console.WriteLine(tests+" comprobaciones aprobadas");
 }
}
