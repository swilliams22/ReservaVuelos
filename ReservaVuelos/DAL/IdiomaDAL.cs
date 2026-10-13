using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
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
    }
}
