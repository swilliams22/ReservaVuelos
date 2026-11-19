using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace ReservaVuelos.DAL
{
    public class PermisoDAL
    {
        // ----- Composite -----

        // Devuelve el árbol del grupo con ese código (rol o familia), o null si no es un grupo.
        public PermisoComponente ObtenerPorRol(string rol)
        {
            Dictionary<int, PermisoComponente> nodos = new Dictionary<int, PermisoComponente>();
            Dictionary<string, GrupoPermisos> grupos = new Dictionary<string, GrupoPermisos>(StringComparer.OrdinalIgnoreCase);
            using (SqlConnection cn = ConexionDAL.GetConnection())
            // Una sola lectura coherente del catálogo y sus relaciones.
            using (SqlCommand cmd = new SqlCommand(@"SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
SELECT IdPermiso, Codigo, EsGrupo FROM dbo.Permisos;
SELECT IdPadre, IdHijo FROM dbo.PermisoRelacion;
COMMIT;", cn))
            {
                cn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        int id = reader.GetInt32(0);
                        string codigo = reader.GetString(1);
                        if (reader.GetBoolean(2))
                        {
                            GrupoPermisos grupo = new GrupoPermisos(codigo);
                            nodos.Add(id, grupo);
                            grupos.Add(codigo, grupo);
                        }
                        else nodos.Add(id, new PermisoSimple(codigo));
                    }
                    reader.NextResult();
                    while (reader.Read())
                    {
                        GrupoPermisos padre = nodos[reader.GetInt32(0)] as GrupoPermisos;
                        if (padre == null) throw new InvalidOperationException("Un permiso simple no puede contener hijos.");
                        padre.Agregar(nodos[reader.GetInt32(1)]);
                    }
                }
            }
            GrupoPermisos raiz;
            return rol != null && grupos.TryGetValue(rol, out raiz) ? raiz : null;
        }

        // ----- Consultas para la administración de perfiles -----

        private const string SelectItems = @"SELECT p.IdPermiso, p.Codigo, p.EsGrupo,
 (SELECT COUNT(*) FROM dbo.Usuarios u WHERE p.EsGrupo = 1 AND u.Rol = p.Codigo) AS CantidadUsuarios
FROM dbo.Permisos p";

        public List<PermisoItem> Listar()
        {
            return LeerItems(SelectItems + " ORDER BY p.EsGrupo DESC, p.Codigo", null);
        }

        public PermisoItem ObtenerPorId(int idPermiso)
        {
            return LeerItems(SelectItems + " WHERE p.IdPermiso = @Id", cmd => cmd.Parameters.AddWithValue("@Id", idPermiso)).FirstOrDefault();
        }

        public PermisoItem ObtenerPorCodigo(string codigo)
        {
            return LeerItems(SelectItems + " WHERE p.Codigo = @Codigo", cmd => cmd.Parameters.AddWithValue("@Codigo", codigo ?? "")).FirstOrDefault();
        }

        // Hijos directos de un grupo.
        public List<PermisoItem> ListarHijos(int idPadre)
        {
            return LeerItems(SelectItems + " JOIN dbo.PermisoRelacion r ON r.IdHijo = p.IdPermiso WHERE r.IdPadre = @Id ORDER BY p.EsGrupo DESC, p.Codigo",
                cmd => cmd.Parameters.AddWithValue("@Id", idPadre));
        }

        // Todos los grupos que contienen (directa o indirectamente) al permiso indicado.
        // Agregar uno de ellos como hijo de ese permiso formaría un ciclo.
        public HashSet<int> ObtenerAncestros(int idPermiso)
        {
            HashSet<int> res = new HashSet<int>();
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand(@";WITH Ancestros AS (
 SELECT IdPadre FROM dbo.PermisoRelacion WHERE IdHijo = @Id
 UNION ALL
 SELECT r.IdPadre FROM dbo.PermisoRelacion r JOIN Ancestros a ON r.IdHijo = a.IdPadre
)
SELECT DISTINCT IdPadre FROM Ancestros OPTION (MAXRECURSION 100);", cn))
            {
                cmd.Parameters.AddWithValue("@Id", idPermiso);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                    while (rdr.Read()) res.Add(rdr.GetInt32(0));
            }
            return res;
        }

        // ----- Cambios -----

        public int CrearGrupo(string codigo)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tx = cn.BeginTransaction(IsolationLevel.Serializable))
                {
                    var integrity = new IntegrityService();
                    integrity.BeforeChange(cn, tx, "Permisos");
                    int id;
                    using (var cmd = new SqlCommand("INSERT INTO dbo.Permisos (Codigo, EsGrupo) VALUES (@Codigo, 1); SELECT CAST(SCOPE_IDENTITY() AS INT);", cn, tx))
                    {
                        cmd.Parameters.AddWithValue("@Codigo", codigo);
                        id = Convert.ToInt32(cmd.ExecuteScalar());
                    }
                    integrity.AfterChange(cn, tx, "Permisos");
                    tx.Commit();
                    return id;
                }
            }
        }

        public void AgregarHijo(int idPadre, int idHijo)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tx = cn.BeginTransaction(IsolationLevel.Serializable))
                {
                    var integrity = new IntegrityService();
                    integrity.BeforeChange(cn, tx, "Permisos", "PermisoRelacion");
                    using (var cmd = new SqlCommand("INSERT INTO dbo.PermisoRelacion (IdPadre, IdHijo) VALUES (@Padre, @Hijo);", cn, tx))
                    {
                        cmd.Parameters.AddWithValue("@Padre", idPadre);
                        cmd.Parameters.AddWithValue("@Hijo", idHijo);
                        cmd.ExecuteNonQuery();
                    }
                    integrity.AfterChange(cn, tx, "PermisoRelacion");
                    tx.Commit();
                }
            }
        }

        // Devuelve false (sin aplicar el cambio) si el editor perdería alguno de los permisos indicados.
        public bool QuitarHijo(int idPadre, int idHijo, int idEditor, string[] permisosAConservar)
        {
            return EjecutarConservando(idEditor, permisosAConservar, (cn, tran) =>
            {
                using (SqlCommand cmd = new SqlCommand("DELETE FROM dbo.PermisoRelacion WHERE IdPadre = @Padre AND IdHijo = @Hijo;", cn, tran))
                {
                    cmd.Parameters.AddWithValue("@Padre", idPadre);
                    cmd.Parameters.AddWithValue("@Hijo", idHijo);
                    cmd.ExecuteNonQuery();
                }
            });
        }

        // Borra el grupo y sus relaciones (como padre y como hijo de otros grupos).
        // El trigger TR_Permisos_ProtegerRolEnUso rechaza (50005) borrar un rol asignado a usuarios.
        public bool EliminarGrupo(int idGrupo, int idEditor, string[] permisosAConservar)
        {
            return EjecutarConservando(idEditor, permisosAConservar, (cn, tran) =>
            {
                using (SqlCommand cmd = new SqlCommand(@"DELETE FROM dbo.PermisoRelacion WHERE IdPadre = @Id OR IdHijo = @Id;
DELETE FROM dbo.Permisos WHERE IdPermiso = @Id AND EsGrupo = 1;", cn, tran))
                {
                    cmd.Parameters.AddWithValue("@Id", idGrupo);
                    cmd.ExecuteNonQuery();
                }
            });
        }

        // ----- Auxiliares -----

        private bool EjecutarConservando(int idEditor, string[] permisosAConservar, Action<SqlConnection, SqlTransaction> cambio)
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (SqlTransaction tran = cn.BeginTransaction(IsolationLevel.Serializable))
                {
                    try
                    {
                        var integrity = new IntegrityService();
                        integrity.BeforeChange(cn, tran, "Permisos", "PermisoRelacion");
                        cambio(cn, tran);
                        if (permisosAConservar != null && permisosAConservar.Length > 0 &&
                            !UsuarioTienePermisos(cn, tran, idEditor, permisosAConservar))
                        {
                            tran.Rollback();
                            return false;
                        }
                        integrity.AfterChange(cn, tran, "Permisos", "PermisoRelacion");
                        tran.Commit();
                        return true;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        // Recorre en SQL el árbol del rol del usuario (activo) y verifica que alcance todas las hojas pedidas.
        private static bool UsuarioTienePermisos(SqlConnection cn, SqlTransaction tran, int idUsuario, string[] codigos)
        {
            string[] distintos = codigos.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
            string[] parametros = distintos.Select((c, i) => "@c" + i).ToArray();
            using (SqlCommand cmd = new SqlCommand(@";WITH Arbol AS (
 SELECT p.IdPermiso FROM dbo.Usuarios u JOIN dbo.Permisos p ON p.Codigo = u.Rol AND p.EsGrupo = 1
 WHERE u.IdUsuario = @IdUsuario AND u.Activo = 1
 UNION ALL
 SELECT r.IdHijo FROM Arbol a JOIN dbo.PermisoRelacion r ON r.IdPadre = a.IdPermiso
)
SELECT COUNT(DISTINCT p.Codigo) FROM Arbol a JOIN dbo.Permisos p ON p.IdPermiso = a.IdPermiso
WHERE p.EsGrupo = 0 AND p.Codigo IN (" + string.Join(",", parametros) + @")
OPTION (MAXRECURSION 100);", cn, tran))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                for (int i = 0; i < distintos.Length; i++) cmd.Parameters.AddWithValue(parametros[i], distintos[i]);
                return Convert.ToInt32(cmd.ExecuteScalar()) == distintos.Length;
            }
        }

        private static List<PermisoItem> LeerItems(string sql, Action<SqlCommand> parametros)
        {
            List<PermisoItem> res = new List<PermisoItem>();
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand(sql, cn))
            {
                if (parametros != null) parametros(cmd);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new PermisoItem
                        {
                            IdPermiso = Convert.ToInt32(rdr["IdPermiso"]),
                            Codigo = rdr["Codigo"].ToString(),
                            EsGrupo = Convert.ToBoolean(rdr["EsGrupo"]),
                            CantidadUsuarios = Convert.ToInt32(rdr["CantidadUsuarios"])
                        });
                    }
                }
            }
            return res;
        }
    }
}
