using System;
using System.IO;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using ReservaVuelos.Servicios;
using ReservaVuelos.BLL;

class IdiomasTests
{
    static void Check(bool condicion, string nombre)
    {
        if (!condicion) throw new Exception(nombre);
        Console.WriteLine("OK: " + nombre);
    }
    static void Main()
    {
        var contexto = new HttpContext(new HttpRequest("", "http://localhost/", ""), new HttpResponse(new StringWriter()));
        HttpContext.Current = contexto;
        SessionStateUtility.AddHttpSessionStateToContext(contexto, new HttpSessionStateContainer("test", new SessionStateItemCollection(), new HttpStaticObjectsCollection(), 20, true, HttpCookieMode.UseCookies, SessionStateMode.InProc, false));
        Check(IdiomaService.Instancia.CambiarIdioma("en-US"), "Cambiar a ingles");
        Check(Traductor.T("ui.adminvuelos.001") == "Flight management", "Catalogo ingles");
        Check(Traductor.Mensaje("No puede cambiar su propio rol.") == "You cannot change your own role.", "Validacion BLL");
        Check(Traductor.Mensaje("El nombre del perfil admite hasta 30 caracteres.") == "Profile names can contain up to 30 characters.", "Validacion con parametros");
        Check(Traductor.Mensaje("Falta el campo <origen>.") == "Missing field <origen>.", "Validacion XML con parametros");
        Check(Traductor.Mensaje("SQL diagnostic") == "SQL diagnostic", "Diagnostico externo conservado");
        var panel = new Panel();
        var boton = new Button();
        boton.Attributes["data-i18n-confirm"] = "ui.adminvuelos.007";
        panel.Controls.Add(boton);
        var lista = new DropDownList();
        var item = new ListItem("Todos", "Todos");
        item.Attributes["data-i18n"] = "ui.adminvuelos.016";
        lista.Items.Add(item); panel.Controls.Add(lista);
        Traductor.TraducirControles(panel, IdiomaService.Instancia.IdiomaActual);
        Check(boton.OnClientClick.Contains("Create this flight?"), "Confirmacion traducida");
        // El valor del filtro debe ser estable aunque su etiqueta cambie.
        Check(item.Text == "All", "Etiqueta del filtro traducida");
        Check(item.Value == "Todos", "Valor del filtro conservado");
        Check(IdiomaService.Instancia.CambiarIdioma("es-AR"), "Volver a espanol");
        Check(Traductor.T("ui.adminvuelos.001") == "Administración de vuelos", "Catalogo espanol");
        string mensaje;
        Check(!PasswordPolicyService.Validate("abc", out mensaje) && mensaje.Contains("contraseña"), "Politica de clave y codificacion");
    }
}
