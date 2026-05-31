using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class VueloDAL
    {
        public List<Vuelo> Search(string origen, string destino, DateTime? fecha, string estado = "Activos")
        {
            var res = new List<Vuelo>();
            using (var cn = ConexionDAL.GetConnection())
            {
                // construir consulta según filtro de estado
                string sql = "SELECT * FROM Vuelos WHERE (@Origen IS NULL OR Origen LIKE @OrigenLike) AND (@Destino IS NULL OR Destino LIKE @DestinoLike) AND (@Fecha IS NULL OR FechaSalida = @Fecha)";
                if (string.Equals(estado, "Activos", StringComparison.OrdinalIgnoreCase)) sql = "SELECT * FROM Vuelos WHERE Activo = 1 AND (@Origen IS NULL OR Origen LIKE @OrigenLike) AND (@Destino IS NULL OR Destino LIKE @DestinoLike) AND (@Fecha IS NULL OR FechaSalida = @Fecha)";
                else if (string.Equals(estado, "Baja", StringComparison.OrdinalIgnoreCase) || string.Equals(estado, "Dados de baja", StringComparison.OrdinalIgnoreCase)) sql = "SELECT * FROM Vuelos WHERE Activo = 0 AND (@Origen IS NULL OR Origen LIKE @OrigenLike) AND (@Destino IS NULL OR Destino LIKE @DestinoLike) AND (@Fecha IS NULL OR FechaSalida = @Fecha)";
                using (var cmd = new SqlCommand(sql, cn))
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
            // Transacción: dar de baja vuelo y cancelar reservas activas asociadas
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        // verificar existencia
                        using (var cmdCheck = new SqlCommand("SELECT COUNT(1) FROM Vuelos WHERE IdVuelo = @Id", cn, tran))
                        {
                            cmdCheck.Parameters.AddWithValue("@Id", id);
                            var obj = cmdCheck.ExecuteScalar();
                            if (Convert.ToInt32(obj) == 0)
                            {
                                tran.Rollback();
                                return -1; // no encontrado
                            }
                        }

                        using (var cmdUpd = new SqlCommand("UPDATE Vuelos SET Activo = 0 WHERE IdVuelo = @Id", cn, tran))
                        {
                            cmdUpd.Parameters.AddWithValue("@Id", id);
                            cmdUpd.ExecuteNonQuery();
                        }

                        using (var cmdCancel = new SqlCommand("UPDATE Reservas SET Estado = @Estado WHERE IdVuelo = @Id AND Estado <> @Estado", cn, tran))
                        {
                            cmdCancel.Parameters.AddWithValue("@Estado", "Cancelada");
                            cmdCancel.Parameters.AddWithValue("@Id", id);
                            var canceled = cmdCancel.ExecuteNonQuery();
                            tran.Commit();
                            return canceled; // cantidad de reservas canceladas
                        }
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }
    }
}
