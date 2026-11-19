using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;

namespace ReservaVuelos.BLL
{
    /// <summary>
    /// Administración de perfiles (grupos del Composite). Los permisos simples no se crean
    /// desde la aplicación: están definidos en Permisos.cs y en el script SQL.
    /// A un perfil se le pueden asignar permisos simples y otros perfiles.
    /// </summary>
    public class PerfilBLL
    {
        // Usuarios.Rol es NVARCHAR(30): un perfil más largo no se podría asignar.
        public const int LargoMaximoCodigo = 30;
        private const string Pantalla = "GestionPerfiles";
        private static readonly Regex FormatoCodigo = new Regex(@"^[\p{L}\p{N}][\p{L}\p{N} _-]*$");

        // Quien edita no puede quedarse sin acceso a esta administración.
        private static readonly string[] PermisosDelEditor = { Permisos.VerPerfiles, Permisos.EditarPerfiles };

        private readonly PermisoDAL _dal = new PermisoDAL();
        private readonly BitacoraBLL _bitacora = new BitacoraBLL();

        // ----- Consultas -----

        public List<PermisoItem> ListarPerfiles()
        {
            return _dal.Listar().Where(p => p.EsGrupo).ToList();
        }

        public PermisoItem ObtenerPerfil(int idPerfil)
        {
            PermisoItem item = _dal.ObtenerPorId(idPerfil);
            return item != null && item.EsGrupo ? item : null;
        }

        public bool EsPerfil(string codigo)
        {
            PermisoItem item = _dal.ObtenerPorCodigo(codigo);
            return item != null && item.EsGrupo;
        }

        public List<PermisoItem> ListarAsignados(int idPerfil)
        {
            return _dal.ListarHijos(idPerfil);
        }

        // Permisos simples y perfiles que se pueden agregar sin repetir ni formar un ciclo.
        public List<PermisoItem> ListarDisponibles(int idPerfil)
        {
            HashSet<int> excluidos = _dal.ObtenerAncestros(idPerfil);
            excluidos.Add(idPerfil);
            foreach (PermisoItem hijo in _dal.ListarHijos(idPerfil)) excluidos.Add(hijo.IdPermiso);
            return _dal.Listar().Where(p => !excluidos.Contains(p.IdPermiso)).ToList();
        }

        // Árbol completo del perfil (Composite), para mostrarlo en un TreeView.
        public GrupoPermisos ObtenerArbol(string codigoPerfil)
        {
            return _dal.ObtenerPorRol(codigoPerfil) as GrupoPermisos;
        }

        // ----- Cambios -----

        public int CrearPerfil(string codigo, Usuario editor)
        {
            ValidarEditor(editor);
            codigo = (codigo ?? "").Trim();
            if (codigo.Length == 0) throw new ArgumentException("Ingrese el nombre del perfil.");
            if (codigo.Length > LargoMaximoCodigo) throw new ArgumentException("El nombre del perfil admite hasta " + LargoMaximoCodigo + " caracteres.");
            // Sin punto: los códigos con punto (Reservas.Crear) son permisos simples.
            if (!FormatoCodigo.IsMatch(codigo)) throw new ArgumentException("El nombre del perfil sólo admite letras, números, espacios, guiones y guiones bajos.");
            if (_dal.ObtenerPorCodigo(codigo) != null) throw new InvalidOperationException("Ya existe un perfil o permiso con ese nombre.");

            int id;
            try { id = _dal.CrearGrupo(codigo); }
            catch (SqlException ex) when (ex.Number == 2627 || ex.Number == 2601)
            {
                throw new InvalidOperationException("Ya existe un perfil o permiso con ese nombre.");
            }
            Registrar(editor, "Creó el perfil " + codigo + ".");
            return id;
        }

        public void AgregarPermiso(int idPerfil, int idPermiso, Usuario editor)
        {
            ValidarEditor(editor);
            PermisoItem perfil = ExigirPerfil(idPerfil);
            PermisoItem permiso = _dal.ObtenerPorId(idPermiso);
            if (permiso == null) throw new InvalidOperationException("El permiso seleccionado no existe.");
            if (idPerfil == idPermiso || _dal.ObtenerAncestros(idPerfil).Contains(idPermiso))
                throw new InvalidOperationException("No se puede agregar " + permiso.Codigo + " a " + perfil.Codigo + " porque ya lo contiene (se formaría un ciclo).");
            if (_dal.ListarHijos(idPerfil).Any(h => h.IdPermiso == idPermiso))
                throw new InvalidOperationException(perfil.Codigo + " ya tiene asignado " + permiso.Codigo + ".");

            try { _dal.AgregarHijo(idPerfil, idPermiso); }
            catch (SqlException ex) when (ex.Number == 2627)
            {
                throw new InvalidOperationException(perfil.Codigo + " ya tiene asignado " + permiso.Codigo + ".");
            }
            catch (SqlException ex) when (ex.Number == 50002)
            {
                throw new InvalidOperationException("No se puede agregar " + permiso.Codigo + " a " + perfil.Codigo + " porque se formaría un ciclo.");
            }
            catch (SqlException ex) when (ex.Number == 50001)
            {
                throw new InvalidOperationException("Un permiso simple no puede contener otros permisos.");
            }
            AutorizacionService.InvalidarCache();
            Registrar(editor, "Agregó " + permiso.Codigo + " al perfil " + perfil.Codigo + ".");
        }

        public void QuitarPermiso(int idPerfil, int idPermiso, Usuario editor)
        {
            ValidarEditor(editor);
            PermisoItem perfil = ExigirPerfil(idPerfil);
            PermisoItem permiso = _dal.ListarHijos(idPerfil).FirstOrDefault(h => h.IdPermiso == idPermiso);
            if (permiso == null) throw new InvalidOperationException("El permiso no está asignado a " + perfil.Codigo + ".");

            if (!_dal.QuitarHijo(idPerfil, idPermiso, editor.IdUsuario, PermisosDelEditor))
                throw new InvalidOperationException("No se puede quitar " + permiso.Codigo + " de " + perfil.Codigo +
                    ": su propio perfil perdería el acceso a la administración de perfiles.");
            AutorizacionService.InvalidarCache();
            Registrar(editor, "Quitó " + permiso.Codigo + " del perfil " + perfil.Codigo + ".");
        }

        public void EliminarPerfil(int idPerfil, Usuario editor)
        {
            ValidarEditor(editor);
            PermisoItem perfil = ExigirPerfil(idPerfil);
            if (perfil.CantidadUsuarios > 0)
                throw new InvalidOperationException("No se puede eliminar " + perfil.Codigo + ": está asignado a " + perfil.CantidadUsuarios + " usuario(s).");

            bool eliminado;
            try { eliminado = _dal.EliminarGrupo(idPerfil, editor.IdUsuario, PermisosDelEditor); }
            catch (SqlException ex) when (ex.Number == 50005 || ex.Number == 547)
            {
                throw new InvalidOperationException("No se puede eliminar " + perfil.Codigo + ": está asignado a usuarios.");
            }
            if (!eliminado)
                throw new InvalidOperationException("No se puede eliminar " + perfil.Codigo +
                    ": su propio perfil perdería el acceso a la administración de perfiles.");
            AutorizacionService.InvalidarCache();
            Registrar(editor, "Eliminó el perfil " + perfil.Codigo + ".");
        }

        // ----- Auxiliares -----

        private PermisoItem ExigirPerfil(int idPerfil)
        {
            PermisoItem perfil = ObtenerPerfil(idPerfil);
            if (perfil == null) throw new InvalidOperationException("El perfil seleccionado no existe.");
            return perfil;
        }

        private static void ValidarEditor(Usuario editor)
        {
            if (editor == null) throw new InvalidOperationException("Debe iniciar sesión.");
        }

        private void Registrar(Usuario editor, string accion)
        {
            try
            {
                _bitacora.Create(new ReservaVuelos.BE.Bitacora
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
