using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;


namespace ReservaVuelos.Servicios
{
    public class SeguridadService
    {
        private UsuarioDAL _ud = new UsuarioDAL();
        private BitacoraDAL _bd = new BitacoraDAL();

        public Usuario Authenticate(string email, string password)
        {
            var u = _ud.GetByEmail(email);
            if (u == null)
            {
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login fallido - usuario no encontrado", Criticidad = "Media", Pantalla = "Login" });
                return null;
            }
            if (!u.Activo)
            {
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login fallido - usuario inactivo", Criticidad = "Media", Pantalla = "Login" });
                return null;
            }
            if (HashService.VerifyPassword(password, u.PasswordHash, u.PasswordSalt))
            {
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login exitoso", Criticidad = "Baja", Pantalla = "Login" });
                return u;
            }
            else
            {
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login fallido - contraseña incorrecta", Criticidad = "Media", Pantalla = "Login" });
                return null;
            }
        }

        public int RegistrarUsuario(Usuario u, string password)
        {
            string hash, salt;
            HashService.CreateHash(password, out hash, out salt);
            u.PasswordHash = hash;
            u.PasswordSalt = salt;
            u.FechaAlta = DateTime.Now;
            u.Activo = true;
            var id = _ud.Create(u);
            _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = u.Email, Accion = $"Registro de usuario. IdUsuario: {id}", Criticidad = "Baja", Pantalla = "Registro" });
            return id;
        }
    }
}
