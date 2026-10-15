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
            var nodos = new Dictionary<int, PermisoComponente>();
            var grupos = new Dictionary<string, GrupoPermisos>(StringComparer.OrdinalIgnoreCase);
            using (var cn = ConexionDAL.GetConnection())
            // Una sola lectura coherente del catálogo y sus relaciones.
            using (var cmd = new SqlCommand(@"SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
SELECT IdPermiso, Codigo, EsGrupo FROM dbo.Permisos;
SELECT IdPadre, IdHijo FROM dbo.PermisoRelacion;
COMMIT;", cn))
            {
                cn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        int id = reader.GetInt32(0);
                        string codigo = reader.GetString(1);
                        if (reader.GetBoolean(2))
                        {
                            var grupo = new GrupoPermisos(codigo);
                            nodos.Add(id, grupo);
                            grupos.Add(codigo, grupo);
                        }
                        else nodos.Add(id, new PermisoSimple(codigo));
                    }
                    reader.NextResult();
                    while (reader.Read())
                    {
                        var padre = nodos[reader.GetInt32(0)] as GrupoPermisos;
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
