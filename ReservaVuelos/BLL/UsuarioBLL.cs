using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.BLL
{
    public class UsuarioBLL
    {
        private const string Pantalla = "GestionUsuarios";
        private UsuarioDAL _dal = new UsuarioDAL();

        public Usuario GetByEmail(string email) => _dal.GetByEmail(email);

        public int Create(Usuario u) => _dal.Create(u);

        public List<Usuario> Listar() => _dal.Listar();

        // Asigna un perfil (grupo del Composite) como rol del usuario.
        public void AsignarRol(int idUsuario, string rolNuevo, Usuario editor)
        {
            if (editor == null) throw new InvalidOperationException("Debe iniciar sesión.");
            // Así quien administra no puede dejarse sin acceso a sí mismo.
            if (idUsuario == editor.IdUsuario) throw new InvalidOperationException("No puede cambiar su propio rol.");

            rolNuevo = (rolNuevo ?? "").Trim();
            if (!new PerfilBLL().EsPerfil(rolNuevo)) throw new InvalidOperationException("El perfil seleccionado no existe.");

            Usuario usuario = _dal.GetById(idUsuario);
            if (usuario == null) throw new InvalidOperationException("El usuario no existe.");
            if (string.Equals(usuario.Rol, rolNuevo, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException(usuario.Email + " ya tiene el rol " + rolNuevo + ".");

            // No recalcular el DVH sobre un registro adulterado: primero se valida la tabla.
            new IntegrityService().EnsureTableIsValid("Usuarios");

            bool actualizado;
            try { actualizado = _dal.ActualizarRol(idUsuario, usuario.Rol, rolNuevo); }
            catch (SqlException ex) when (ex.Number == 50004)
            {
                throw new InvalidOperationException("El perfil seleccionado no existe.");
            }
            if (!actualizado)
                throw new InvalidOperationException("El usuario fue modificado mientras tanto. Vuelva a cargar la lista e intente de nuevo.");

            AutorizacionService.InvalidarCache();
            Registrar(editor, "Cambió el rol de " + usuario.Email + " de " + usuario.Rol + " a " + rolNuevo + ".");
        }

        private static void Registrar(Usuario editor, string accion)
        {
            try
            {
                new BitacoraBLL().Create(new ReservaVuelos.BE.Bitacora
                {
                    Fecha = DateTime.Now,
                    Usuario = editor.Email,
                    Accion = accion,
                    Criticidad = 2,
                    Pantalla = Pantalla
                });
            }
            catch (Exception)
            {
                // La bitácora no debe deshacer un cambio ya confirmado.
            }
        }
    }
}
