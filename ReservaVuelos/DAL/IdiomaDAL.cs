using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class IdiomaDAL
    {
        public List<Idioma> GetActivos()
        {
            var res = new List<Idioma>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT IdIdioma, Codigo, Nombre, EsDefault, Activo FROM Idioma WHERE Activo = 1 ORDER BY EsDefault DESC, Nombre", cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Idioma
                        {
                            IdIdioma = Convert.ToInt32(rdr["IdIdioma"]),
                            Codigo = rdr["Codigo"].ToString(),
                            Nombre = rdr["Nombre"].ToString(),
                            EsDefault = Convert.ToBoolean(rdr["EsDefault"]),
                            Activo = Convert.ToBoolean(rdr["Activo"])
                        });
                    }
                }
            }
            return res;
        }

        // Clave -> texto, para un idioma
        public Dictionary<string, string> GetTraducciones(int idIdioma)
        {
            var res = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT e.Clave, t.Texto
FROM Traduccion t
INNER JOIN Etiqueta e ON e.IdEtiqueta = t.IdEtiqueta
WHERE t.IdIdioma = @IdIdioma", cn))
            {
                cmd.Parameters.AddWithValue("@IdIdioma", idIdioma);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        res[rdr["Clave"].ToString()] = rdr["Texto"].ToString();
                }
            }
            return res;
        }

        public int? GetPreferencia(int idUsuario)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT IdIdioma FROM Usuarios WHERE IdUsuario = @IdUsuario", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cn.Open();
                var o = cmd.ExecuteScalar();
                if (o == null || o == DBNull.Value) return null;
                return Convert.ToInt32(o);
            }
        }

        // IdIdioma no forma parte del DVH de Usuarios: no hay que recalcular integridad.
        public void GuardarPreferencia(int idUsuario, int idIdioma)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("UPDATE Usuarios SET IdIdioma = @IdIdioma WHERE IdUsuario = @IdUsuario", cn))
            {
                cmd.Parameters.AddWithValue("@IdIdioma", idIdioma);
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        // ---------- Administración de idiomas ----------

        public List<Idioma> GetTodos()
        {
            var res = new List<Idioma>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT i.IdIdioma, i.Codigo, i.Nombre, i.EsDefault, i.Activo,
    (SELECT COUNT(*) FROM Traduccion t WHERE t.IdIdioma = i.IdIdioma AND LEN(LTRIM(RTRIM(t.Texto))) > 0) AS Traducidas,
    (SELECT COUNT(*) FROM Etiqueta) AS Total
FROM Idioma i
ORDER BY i.EsDefault DESC, i.Nombre", cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Idioma
                        {
                            IdIdioma = Convert.ToInt32(rdr["IdIdioma"]),
                            Codigo = rdr["Codigo"].ToString(),
                            Nombre = rdr["Nombre"].ToString(),
                            EsDefault = Convert.ToBoolean(rdr["EsDefault"]),
                            Activo = Convert.ToBoolean(rdr["Activo"]),
                            Traducidas = Convert.ToInt32(rdr["Traducidas"]),
                            Total = Convert.ToInt32(rdr["Total"])
                        });
                    }
                }
            }
            return res;
        }

        public bool ExisteCodigo(string codigo)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(*) FROM Idioma WHERE Codigo = @Codigo", cn))
            {
                cmd.Parameters.AddWithValue("@Codigo", codigo);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        // El idioma nuevo queda inactivo hasta que el WebMaster termine de traducirlo.
        public int Crear(string codigo, string nombre)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"INSERT INTO Idioma (Codigo, Nombre, EsDefault, Activo) VALUES (@Codigo, @Nombre, 0, 0);
SELECT CAST(SCOPE_IDENTITY() AS INT);", cn))
            {
                cmd.Parameters.AddWithValue("@Codigo", codigo);
                cmd.Parameters.AddWithValue("@Nombre", nombre);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        // El idioma por defecto no se puede desactivar.
        public void CambiarActivo(int idIdioma, bool activo)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("UPDATE Idioma SET Activo = @Activo WHERE IdIdioma = @IdIdioma AND (@Activo = 1 OR EsDefault = 0)", cn))
            {
                cmd.Parameters.AddWithValue("@Activo", activo);
                cmd.Parameters.AddWithValue("@IdIdioma", idIdioma);
                cn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public List<string> GetPantallas()
        {
            var res = new List<string>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT DISTINCT Pantalla FROM Etiqueta WHERE Pantalla IS NOT NULL ORDER BY Pantalla", cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read()) res.Add(rdr["Pantalla"].ToString());
                }
            }
            return res;
        }

        public List<EtiquetaTraduccion> GetEtiquetas(int idIdioma, int idIdiomaBase, string pantalla, bool soloPendientes)
        {
            var res = new List<EtiquetaTraduccion>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT e.IdEtiqueta, e.Clave, e.Pantalla, ISNULL(b.Texto, N'') AS TextoBase, ISNULL(t.Texto, N'') AS Texto
FROM Etiqueta e
LEFT JOIN Traduccion b ON b.IdEtiqueta = e.IdEtiqueta AND b.IdIdioma = @IdBase
LEFT JOIN Traduccion t ON t.IdEtiqueta = e.IdEtiqueta AND t.IdIdioma = @IdIdioma
WHERE (@Pantalla IS NULL OR e.Pantalla = @Pantalla)
  AND (@SoloPendientes = 0 OR t.Texto IS NULL OR LTRIM(RTRIM(t.Texto)) = N'')
ORDER BY e.Pantalla, e.Clave", cn))
            {
                cmd.Parameters.AddWithValue("@IdBase", idIdiomaBase);
                cmd.Parameters.AddWithValue("@IdIdioma", idIdioma);
                cmd.Parameters.AddWithValue("@Pantalla", string.IsNullOrEmpty(pantalla) ? (object)DBNull.Value : pantalla);
                cmd.Parameters.AddWithValue("@SoloPendientes", soloPendientes);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new EtiquetaTraduccion
                        {
                            IdEtiqueta = Convert.ToInt32(rdr["IdEtiqueta"]),
                            Clave = rdr["Clave"].ToString(),
                            Pantalla = rdr["Pantalla"] == DBNull.Value ? "" : rdr["Pantalla"].ToString(),
                            TextoBase = rdr["TextoBase"].ToString(),
                            Texto = rdr["Texto"].ToString()
                        });
                    }
                }
            }
            return res;
        }

        // Todo o nada: texto vacío = borrar la traducción (vuelve a mostrarse el idioma por defecto).
        public void GuardarTraducciones(int idIdioma, Dictionary<int, string> textos)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tx = cn.BeginTransaction())
                {
                    try
                    {
                        foreach (var par in textos)
                        {
                            var texto = (par.Value ?? "").Trim();
                            using (var cmd = new SqlCommand(texto.Length == 0
                                ? "DELETE FROM Traduccion WHERE IdIdioma = @IdIdioma AND IdEtiqueta = @IdEtiqueta"
                                : @"UPDATE Traduccion SET Texto = @Texto WHERE IdIdioma = @IdIdioma AND IdEtiqueta = @IdEtiqueta;
IF @@ROWCOUNT = 0 INSERT INTO Traduccion (IdIdioma, IdEtiqueta, Texto) VALUES (@IdIdioma, @IdEtiqueta, @Texto);", cn, tx))
                            {
                                cmd.Parameters.AddWithValue("@IdIdioma", idIdioma);
                                cmd.Parameters.AddWithValue("@IdEtiqueta", par.Key);
                                if (texto.Length > 0) cmd.Parameters.Add("@Texto", SqlDbType.NVarChar, 500).Value = texto;
                                cmd.ExecuteNonQuery();
                            }
                        }
                        tx.Commit();
                    }
                    catch
                    {
                        tx.Rollback();
                        throw;
                    }
                }
            }
        }
    }
}
