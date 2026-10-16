using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class PermisoDAL
    {
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
    }
}
