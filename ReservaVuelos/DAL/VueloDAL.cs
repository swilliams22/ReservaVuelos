using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class VueloDAL
    {
        public List<Vuelo> Search(string origen, string destino, DateTime? fecha, string estado = "Activos", DateTime? fechaMinima = null)
        {
            var res = new List<Vuelo>();
            using (var cn = ConexionDAL.GetConnection())
            {
                var sql = @"SELECT *
FROM Vuelos
WHERE (@Origen IS NULL OR Origen LIKE @OrigenLike)
  AND (@Destino IS NULL OR Destino LIKE @DestinoLike)
  AND (@Fecha IS NULL OR FechaSalida = @Fecha)
  AND (@FechaMinima IS NULL OR FechaSalida > @FechaMinima)";

                if (string.Equals(estado, "Activos", StringComparison.OrdinalIgnoreCase))
                {
                    sql += @"
  AND Activo = 1
  AND CuposDisponibles > 0
  AND DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), HoraSalida), CAST(FechaSalida AS DATETIME2(0))) > @Ahora";
                }
                else if (string.Equals(estado, "Baja", StringComparison.OrdinalIgnoreCase) || string.Equals(estado, "Dados de baja", StringComparison.OrdinalIgnoreCase))
                {
                    sql += @"
  AND Activo = 0";
                }

                sql += " ORDER BY FechaSalida ASC, HoraSalida ASC";

                using (var cmd = new SqlCommand(sql, cn))
                {
                    cmd.Parameters.AddWithValue("@Origen", string.IsNullOrWhiteSpace(origen) ? (object)DBNull.Value : origen);
                    cmd.Parameters.AddWithValue("@OrigenLike", string.IsNullOrWhiteSpace(origen) ? (object)DBNull.Value : ("%" + origen.Trim() + "%"));
                    cmd.Parameters.AddWithValue("@Destino", string.IsNullOrWhiteSpace(destino) ? (object)DBNull.Value : destino);
                    cmd.Parameters.AddWithValue("@DestinoLike", string.IsNullOrWhiteSpace(destino) ? (object)DBNull.Value : ("%" + destino.Trim() + "%"));
                    cmd.Parameters.AddWithValue("@Fecha", fecha.HasValue ? (object)fecha.Value.Date : DBNull.Value);
                    cmd.Parameters.AddWithValue("@FechaMinima", fechaMinima.HasValue ? (object)fechaMinima.Value.Date : DBNull.Value);
                    cmd.Parameters.AddWithValue("@Ahora", DateTime.Now);
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            res.Add(MapearVuelo(rdr));
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
                        return MapearVuelo(rdr);
                }
            }

            return null;
        }

        public int Create(Vuelo v)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        int id;
                        using (var cmd = new SqlCommand(@"INSERT INTO Vuelos (Origen, Destino, FechaSalida, HoraSalida, Precio, CuposDisponibles, Activo, FechaCreacion, FechaActualizacion, DVH)
VALUES (@Origen, @Destino, @FechaSalida, @HoraSalida, @Precio, @CuposDisponibles, @Activo, @FechaCreacion, @FechaActualizacion, 0);
SELECT SCOPE_IDENTITY();", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@Origen", v.Origen);
                            cmd.Parameters.AddWithValue("@Destino", v.Destino);
                            cmd.Parameters.AddWithValue("@FechaSalida", v.FechaSalida.Date);
                            cmd.Parameters.AddWithValue("@HoraSalida", v.HoraSalida);
                            cmd.Parameters.AddWithValue("@Precio", v.Precio);
                            cmd.Parameters.AddWithValue("@CuposDisponibles", v.CuposDisponibles);
                            cmd.Parameters.AddWithValue("@Activo", v.Activo);
                            cmd.Parameters.AddWithValue("@FechaCreacion", v.FechaCreacion == default(DateTime) ? DateTime.Now : v.FechaCreacion);
                            cmd.Parameters.AddWithValue("@FechaActualizacion", v.FechaActualizacion.HasValue ? (object)v.FechaActualizacion.Value : DBNull.Value);
                            id = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Vuelos", id);
                        tran.Commit();
                        return id;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        public void UpdateSeats(int idVuelo, int delta)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        using (var cmd = new SqlCommand(@"UPDATE Vuelos
SET CuposDisponibles = CuposDisponibles + @Delta,
    FechaActualizacion = @FechaActualizacion
WHERE IdVuelo = @Id", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@Delta", delta);
                            cmd.Parameters.AddWithValue("@FechaActualizacion", DateTime.Now);
                            cmd.Parameters.AddWithValue("@Id", idVuelo);
                            cmd.ExecuteNonQuery();
                        }

                        new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Vuelos", idVuelo);
                        tran.Commit();
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        public int SoftDelete(int id)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        using (var cmdCheck = new SqlCommand("SELECT COUNT(1) FROM Vuelos WHERE IdVuelo = @Id", cn, tran))
                        {
                            cmdCheck.Parameters.AddWithValue("@Id", id);
                            if (Convert.ToInt32(cmdCheck.ExecuteScalar()) == 0)
                            {
                                tran.Rollback();
                                return -1;
                            }
                        }

                        using (var cmdUpd = new SqlCommand(@"UPDATE Vuelos
SET Activo = 0,
    FechaActualizacion = @FechaActualizacion
WHERE IdVuelo = @Id", cn, tran))
                        {
                            cmdUpd.Parameters.AddWithValue("@FechaActualizacion", DateTime.Now);
                            cmdUpd.Parameters.AddWithValue("@Id", id);
                            cmdUpd.ExecuteNonQuery();
                        }

                        var detallesAfectados = new List<Tuple<int, int, int>>();
                        var reservasProcesadas = new HashSet<int>();
                        using (var cmdDetalles = new SqlCommand(@"SELECT IdReservaDetalle, IdReservaCabecera, Cantidad
FROM ReservaDetalle
WHERE IdVuelo = @IdVuelo AND Estado = @Estado", cn, tran))
                        {
                            cmdDetalles.Parameters.AddWithValue("@IdVuelo", id);
                            cmdDetalles.Parameters.AddWithValue("@Estado", "Activo");
                            using (var rdr = cmdDetalles.ExecuteReader())
                            {
                                while (rdr.Read())
                                {
                                    detallesAfectados.Add(Tuple.Create(
                                        Convert.ToInt32(rdr["IdReservaDetalle"]),
                                        Convert.ToInt32(rdr["IdReservaCabecera"]),
                                        Convert.ToInt32(rdr["Cantidad"])));
                                }
                            }
                        }

                        if (detallesAfectados.Count > 0)
                        {
                            using (var cmdCancelDetalles = new SqlCommand(@"UPDATE ReservaDetalle
SET Estado = @EstadoCancelado
WHERE IdVuelo = @IdVuelo AND Estado = @EstadoActivo", cn, tran))
                            {
                                cmdCancelDetalles.Parameters.AddWithValue("@EstadoCancelado", "Cancelado");
                                cmdCancelDetalles.Parameters.AddWithValue("@EstadoActivo", "Activo");
                                cmdCancelDetalles.Parameters.AddWithValue("@IdVuelo", id);
                                cmdCancelDetalles.ExecuteNonQuery();
                            }

                            var ahora = DateTime.Now;
                            int cuposADevolver = 0;
                            foreach (var detalle in detallesAfectados)
                            {
                                cuposADevolver += detalle.Item3;

                                if (reservasProcesadas.Contains(detalle.Item2))
                                    continue;

                                reservasProcesadas.Add(detalle.Item2);
                                using (var cmdActivos = new SqlCommand(@"SELECT COUNT(1)
FROM ReservaDetalle
WHERE IdReservaCabecera = @IdReservaCabecera AND Estado = @EstadoActivo", cn, tran))
                                {
                                    cmdActivos.Parameters.AddWithValue("@IdReservaCabecera", detalle.Item2);
                                    cmdActivos.Parameters.AddWithValue("@EstadoActivo", "Activo");
                                    if (Convert.ToInt32(cmdActivos.ExecuteScalar()) == 0)
                                    {
                                        using (var cmdCabecera = new SqlCommand(@"UPDATE ReservaCabecera
SET Estado = @Estado,
    FechaActualizacion = @FechaActualizacion,
    FechaCancelacion = ISNULL(FechaCancelacion, @FechaCancelacion)
WHERE IdReservaCabecera = @IdReservaCabecera AND Estado <> @Estado", cn, tran))
                                        {
                                            cmdCabecera.Parameters.AddWithValue("@Estado", "Cancelada");
                                            cmdCabecera.Parameters.AddWithValue("@FechaActualizacion", ahora);
                                            cmdCabecera.Parameters.AddWithValue("@FechaCancelacion", ahora);
                                            cmdCabecera.Parameters.AddWithValue("@IdReservaCabecera", detalle.Item2);
                                            cmdCabecera.ExecuteNonQuery();
                                        }
                                    }
                                }
                            }

                            if (cuposADevolver > 0)
                            {
                                using (var cmdSeats = new SqlCommand(@"UPDATE Vuelos
SET CuposDisponibles = CuposDisponibles + @Cantidad,
    FechaActualizacion = @FechaActualizacion
WHERE IdVuelo = @IdVuelo", cn, tran))
                                {
                                    cmdSeats.Parameters.AddWithValue("@Cantidad", cuposADevolver);
                                    cmdSeats.Parameters.AddWithValue("@FechaActualizacion", ahora);
                                    cmdSeats.Parameters.AddWithValue("@IdVuelo", id);
                                    cmdSeats.ExecuteNonQuery();
                                }
                            }
                        }

                        var integrity = new IntegrityService();
                        integrity.UpdateRecordAndTableDVV(cn, tran, "Vuelos", id);
                        foreach (var detalle in detallesAfectados)
                        {
                            integrity.UpdateRecordDVH(cn, tran, "ReservaDetalle", detalle.Item1);
                        }

                        foreach (var reservaId in reservasProcesadas)
                        {
                            integrity.UpdateRecordDVH(cn, tran, "ReservaCabecera", reservaId);
                        }

                        integrity.UpdateTableDVV(cn, tran, "ReservaCabecera");
                        integrity.UpdateTableDVV(cn, tran, "ReservaDetalle");

                        tran.Commit();
                        return detallesAfectados.Count;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        private Vuelo MapearVuelo(SqlDataReader rdr)
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
                Activo = Convert.ToBoolean(rdr["Activo"]),
                FechaCreacion = rdr["FechaCreacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaCreacion"]) : default(DateTime),
                FechaActualizacion = rdr["FechaActualizacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaActualizacion"]) : (DateTime?)null,
                DVH = rdr["DVH"] != DBNull.Value ? Convert.ToInt32(rdr["DVH"]) : 0
            };
        }
    }
}
