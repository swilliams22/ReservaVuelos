using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.DAL;
using System;


namespace ReservaVuelos.Servicios
{
    public class SeguridadService
    {
        private UsuarioDAL _ud = new UsuarioDAL();
        private BitacoraDAL _bd = new BitacoraDAL();
        private PasajeroBLL _pBLL = new PasajeroBLL();

        public Usuario Authenticate(string email, string password)
        {
            var u = _ud.GetByEmail(email);
            if (u == null)
            {
                // Usuario no encontrado -> Advertencia
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login fallido - usuario no encontrado", Criticidad = 2, Pantalla = "Login" });
                return null;
            }
            if (!u.Activo)
            {
                // Usuario inactivo -> Advertencia
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login fallido - usuario inactivo", Criticidad = 2, Pantalla = "Login" });
                return null;
            }
            if (HashService.VerifyPassword(password, u.PasswordHash, u.PasswordSalt))
            {
                // Login exitoso -> Info
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login exitoso", Criticidad = 1, Pantalla = "Login" });

                // Vincular pasajero si existe
                VincularPasajeroConUsuario(u);
                new IntegrityService().ValidateTable("Usuarios");

                return u;
            }
            else
            {
                // Contraseña incorrecta -> Advertencia
                _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = email, Accion = "Login fallido - Contraseña incorrecta", Criticidad = 2, Pantalla = "Login" });
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

            // Registro exitoso -> Info
            _bd.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = u.Email, Accion = $"Registro de usuario. IdUsuario: {id}", Criticidad = 1, Pantalla = "Registro" });

            // Vincular pasajero si existe
            u.IdUsuario = id;
            VincularPasajeroConUsuario(u);

            return id;
        }

        private void VincularPasajeroConUsuario(Usuario u)
        {
            try
            {
                // Buscar pasajero por email (preferido)
                Pasajero pasajero = null;
                if (!string.IsNullOrWhiteSpace(u.Email))
                {
                    pasajero = _pBLL.GetByEmail(u.Email);
                }

                // Si no existe vinculación, intentar por documento (si Usuario tiene campo documento en el futuro)
                // Por ahora solo por email

                if (pasajero != null && !pasajero.IdUsuario.HasValue)
                {
                    _pBLL.VincularConUsuario(pasajero.IdPasajero, u.IdUsuario);
                    _bd.Create(new ReservaVuelos.BE.Bitacora 
                    { 
                        Fecha = DateTime.Now, 
                        Usuario = u.Email, 
                        Accion = $"Pasajero vinculado automáticamente. IdPasajero: {pasajero.IdPasajero}", 
                        Criticidad = 1, 
                        Pantalla = "Login" 
                    });
                }
            }
            catch
            {
                // No fallar el login/registro si la vinculación falla
            }
        }
    }
}

