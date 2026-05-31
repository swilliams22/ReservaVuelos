using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class VueloDAL
    {
        public List<Vuelo> Search(string origen, string destino, DateTime? fecha)
        {
            var res = new List<Vuelo>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT * FROM Vuelos WHERE Activo = 1 AND (@Origen IS NULL OR Origen LIKE @OrigenLike) AND (@Destino IS NULL OR Destino LIKE @DestinoLike) AND (@Fecha IS NULL OR FechaSalida = @Fecha)", cn))
            {
                cmd.Parameters.AddWithValue("@Origen", string.IsNullOrWhiteSpace(origen) ? (object)DBNull.Value : origen);
                cmd.Parameters.AddWithValue("@OrigenLike", string.IsNullOrWhiteSpace(origen) ? (object)DBNull.Value : ("%" + origen + "%"));
                cmd.Parameters.AddWithValue("@Destino", string.IsNullOrWhiteSpace(destino) ? (object)DBNull.Value : destino);
                cmd.Parameters.AddWithValue("@DestinoLike", string.IsNullOrWhiteSpace(destino) ? (object)DBNull.Value : ("%" + destino + "%"));
                cmd.Parameters.AddWithValue("@Fecha", fecha.HasValue ? (object)fecha.Value.Date : (object)DBNull.Value);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Vuelo
                        {
                            IdVuelo = Convert.ToInt32(rdr["IdVuelo"]),
                            Origen = rdr["Origen"].ToString(),
                            Destino = rdr["Destino"].ToString(),
                            FechaSalida = Convert.ToDateTime(rdr["FechaSalida"]),
                            HoraSalida = (TimeSpan)rdr["HoraSalida"],
                            Precio = Convert.ToDecimal(rdr["Precio"]),
                            CuposDisponibles = Convert.ToInt32(rdr["CuposDisponibles"]),
                            Activo = Convert.ToBoolean(rdr["Activo"])
                        });
                    }
                }
            }
            return res;
        }

        public Vuelo GetById(int id)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Vuelos WHERE IdVuelo = @Id", cn))
            {
                cmd.Parameters.AddWithValue("@Id", id);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        return new Vuelo
                        {
                            IdVuelo = Convert.ToInt32(rdr["IdVuelo"]),
                            Origen = rdr["Origen"].ToString(),
                            Destino = rdr["Destino"].ToString(),
                            FechaSalida = Convert.ToDateTime(rdr["FechaSalida"]),
                            HoraSalida = (TimeSpan)rdr["HoraSalida"],
                            Precio = Convert.ToDecimal(rdr["Precio"]),
                            CuposDisponibles = Convert.ToInt32(rdr["CuposDisponibles"]),
                            Activo = Convert.ToBoolean(rdr["Activo"])
                        };
                    }
                }
            }
            return null;
        }

        public int Create(Vuelo v)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"INSERT INTO Vuelos (Origen,Destino,FechaSalida,HoraSalida,Precio,CuposDisponibles,Activo) VALUES (@Origen,@Destino,@FechaSalida,@HoraSalida,@Precio,@CuposDisponibles,@Activo); SELECT SCOPE_IDENTITY();", cn))
            {
                cmd.Parameters.AddWithValue("@Origen", v.Origen);
                cmd.Parameters.AddWithValue("@Destino", v.Destino);
                cmd.Parameters.AddWithValue("@FechaSalida", v.FechaSalida.Date);
                cmd.Parameters.AddWithValue("@HoraSalida", v.HoraSalida);
                cmd.Parameters.AddWithValue("@Precio", v.Precio);
                cmd.Parameters.AddWithValue("@CuposDisponibles", v.CuposDisponibles);
                cmd.Parameters.AddWithValue("@Activo", v.Activo);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        public void UpdateSeats(int idVuelo, int delta)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("UPDATE Vuelos SET CuposDisponibles = CuposDisponibles + @Delta WHERE IdVuelo = @Id", cn))
            {
                cmd.Parameters.AddWithValue("@Delta", delta);
                cmd.Parameters.AddWithValue("@Id", idVuelo);
                cn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public int SoftDelete(int id)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("UPDATE Vuelos SET Activo = 0 WHERE IdVuelo = @Id", cn))
            {
                cmd.Parameters.AddWithValue("@Id", id);
                cn.Open();
                return cmd.ExecuteNonQuery();
            }
        }
    }
}
