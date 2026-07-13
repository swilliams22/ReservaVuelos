using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class ReservaCabeceraDAL
    {
        public int CreateWithDetails(ReservaCabecera cabecera, List<ReservaDetalle> detalles, List<ReservaPasajero> pasajeros)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        int idReservaCabecera;
                        using (var cmd = new SqlCommand(@"INSERT INTO ReservaCabecera (IdCliente, IdUsuarioCreador, FechaReserva, Estado, MontoTotal, FechaCreacion, FechaActualizacion, FechaCancelacion, IdUsuarioCancela, DVH)
VALUES (@IdCliente, @IdUsuarioCreador, @FechaReserva, @Estado, @MontoTotal, @FechaCreacion, @FechaActualizacion, @FechaCancelacion, @IdUsuarioCancela, 0);
SELECT SCOPE_IDENTITY();", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@IdCliente", cabecera.IdCliente);
                            cmd.Parameters.AddWithValue("@IdUsuarioCreador", cabecera.IdUsuarioCreador);
                            cmd.Parameters.AddWithValue("@FechaReserva", cabecera.FechaReserva);
                            cmd.Parameters.AddWithValue("@Estado", cabecera.Estado ?? "Activa");
                            cmd.Parameters.AddWithValue("@MontoTotal", cabecera.MontoTotal);
                            cmd.Parameters.AddWithValue("@FechaCreacion", cabecera.FechaCreacion == default(DateTime) ? DateTime.Now : cabecera.FechaCreacion);
                            cmd.Parameters.AddWithValue("@FechaActualizacion", cabecera.FechaActualizacion.HasValue ? (object)cabecera.FechaActualizacion.Value : DBNull.Value);
                            cmd.Parameters.AddWithValue("@FechaCancelacion", cabecera.FechaCancelacion.HasValue ? (object)cabecera.FechaCancelacion.Value : DBNull.Value);
                            cmd.Parameters.AddWithValue("@IdUsuarioCancela", cabecera.IdUsuarioCancela.HasValue ? (object)cabecera.IdUsuarioCancela.Value : DBNull.Value);
                            idReservaCabecera = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        var vuelosAfectados = new HashSet<int>();
                        var detallesInsertados = new List<int>();
                        foreach (var detalle in detalles)
                        {
                            using (var cmdCheck = new SqlCommand(@"SELECT Activo, CuposDisponibles, FechaSalida, HoraSalida
FROM Vuelos WITH (UPDLOCK, ROWLOCK)
WHERE IdVuelo = @IdVuelo", cn, tran))
                            {
                                cmdCheck.Parameters.AddWithValue("@IdVuelo", detalle.IdVuelo);
                                using (var rdr = cmdCheck.ExecuteReader())
                                {
                                    if (!rdr.Read())
                                        throw new Exception(string.Format("Vuelo {0} no encontrado.", detalle.IdVuelo));

                                    var activo = Convert.ToBoolean(rdr["Activo"]);
                                    var cupos = Convert.ToInt32(rdr["CuposDisponibles"]);
                                    var fechaSalida = Convert.ToDateTime(rdr["FechaSalida"]);
                                    var horaSalida = (TimeSpan)rdr["HoraSalida"];
                                    var fechaHoraSalida = fechaSalida.Date.Add(horaSalida);

                                    if (!activo)
                                        throw new Exception(string.Format("El vuelo {0} no se encuentra activo.", detalle.IdVuelo));

                                    if (fechaHoraSalida <= DateTime.Now)
                                        throw new Exception(string.Format("No se pueden reservar vuelos pasados. Vuelo {0}.", detalle.IdVuelo));

                                    if (cupos < detalle.Cantidad)
                                        throw new Exception(string.Format("No hay suficientes cupos disponibles para el vuelo {0}. Disponibles: {1}, Solicitados: {2}", detalle.IdVuelo, cupos, detalle.Cantidad));
                                }
                            }

                            using (var cmdUpdate = new SqlCommand(@"UPDATE Vuelos
SET CuposDisponibles = CuposDisponibles - @Cantidad,
    FechaActualizacion = @FechaActualizacion
WHERE IdVuelo = @IdVuelo
  AND CuposDisponibles >= @Cantidad", cn, tran))
                            {
                                cmdUpdate.Parameters.AddWithValue("@Cantidad", detalle.Cantidad);
                                cmdUpdate.Parameters.AddWithValue("@FechaActualizacion", DateTime.Now);
                                cmdUpdate.Parameters.AddWithValue("@IdVuelo", detalle.IdVuelo);
                                var rows = cmdUpdate.ExecuteNonQuery();
                                if (rows == 0)
                                    throw new Exception(string.Format("No fue posible reservar cupos para el vuelo {0}. Reintente la operación.", detalle.IdVuelo));
                            }
                            vuelosAfectados.Add(detalle.IdVuelo);

                            using (var cmd = new SqlCommand(@"INSERT INTO ReservaDetalle (IdReservaCabecera, IdVuelo, Cantidad, PrecioUnitario, SubTotal, Estado, DVH)
VALUES (@IdReservaCabecera, @IdVuelo, @Cantidad, @PrecioUnitario, @SubTotal, @Estado, 0);
SELECT SCOPE_IDENTITY();", cn, tran))
                            {
                                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                                cmd.Parameters.AddWithValue("@IdVuelo", detalle.IdVuelo);
                                cmd.Parameters.AddWithValue("@Cantidad", detalle.Cantidad);
                                cmd.Parameters.AddWithValue("@PrecioUnitario", detalle.PrecioUnitario);
                                cmd.Parameters.AddWithValue("@SubTotal", detalle.SubTotal);
                                cmd.Parameters.AddWithValue("@Estado", detalle.Estado ?? "Activo");
                                detallesInsertados.Add(Convert.ToInt32(cmd.ExecuteScalar()));
                            }
                        }

                        foreach (var rp in pasajeros)
                        {
                            using (var cmd = new SqlCommand(@"INSERT INTO ReservaPasajero (IdReservaCabecera, IdPasajero)
VALUES (@IdReservaCabecera, @IdPasajero);", cn, tran))
                            {
                                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                                cmd.Parameters.AddWithValue("@IdPasajero", rp.IdPasajero);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        var integrity = new IntegrityService();
                        integrity.UpdateRecordDVH(cn, tran, "ReservaCabecera", idReservaCabecera);
                        foreach (var detalleId in detallesInsertados)
                            integrity.UpdateRecordDVH(cn, tran, "ReservaDetalle", detalleId);
                        foreach (var vueloId in vuelosAfectados)
                            integrity.UpdateRecordDVH(cn, tran, "Vuelos", vueloId);

                        integrity.UpdateTableDVV(cn, tran, "ReservaCabecera");
                        integrity.UpdateTableDVV(cn, tran, "ReservaDetalle");
                        integrity.UpdateTableDVV(cn, tran, "Vuelos");

                        tran.Commit();
                        return idReservaCabecera;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        public ReservaCabecera GetById(int idReservaCabecera)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM ReservaCabecera WHERE IdReservaCabecera = @IdReservaCabecera", cn))
            {
                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearCabecera(rdr);
                }
            }

            return null;
        }

        public List<ReservaCabecera> GetByIdCliente(int idCliente)
        {
            var res = new List<ReservaCabecera>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM ReservaCabecera WHERE IdCliente = @IdCliente ORDER BY FechaReserva DESC", cn))
            {
                cmd.Parameters.AddWithValue("@IdCliente", idCliente);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        res.Add(MapearCabecera(rdr));
                }
            }

            return res;
        }

        public List<ReservaCabecera> GetByIdPasajero(int idPasajero)
        {
            var res = new List<ReservaCabecera>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT DISTINCT rc.*
FROM ReservaCabecera rc
INNER JOIN ReservaPasajero rp ON rc.IdReservaCabecera = rp.IdReservaCabecera
WHERE rp.IdPasajero = @IdPasajero
ORDER BY rc.FechaReserva DESC", cn))
            {
                cmd.Parameters.AddWithValue("@IdPasajero", idPasajero);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        res.Add(MapearCabecera(rdr));
                }
            }

            return res;
        }

        public int Cancel(int idReservaCabecera, int? idUsuarioCancela)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        string estado = null;
                        using (var cmdGet = new SqlCommand("SELECT Estado FROM ReservaCabecera WITH (UPDLOCK, ROWLOCK) WHERE IdReservaCabecera = @Id", cn, tran))
                        {
                            cmdGet.Parameters.AddWithValue("@Id", idReservaCabecera);
                            var result = cmdGet.ExecuteScalar();
                            if (result == null)
                            {
                                tran.Rollback();
                                return 0;
                            }

                            estado = result.ToString();
                        }

                        if (string.Equals(estado, "Cancelada", StringComparison.OrdinalIgnoreCase))
                        {
                            tran.Rollback();
                            return 0;
                        }

                        var detalles = new List<Tuple<int, int, int>>();
                        using (var cmdDetalles = new SqlCommand("SELECT IdReservaDetalle, IdVuelo, Cantidad FROM ReservaDetalle WHERE IdReservaCabecera = @Id AND Estado = @Estado", cn, tran))
                        {
                            cmdDetalles.Parameters.AddWithValue("@Id", idReservaCabecera);
                            cmdDetalles.Parameters.AddWithValue("@Estado", "Activo");
                            using (var rdr = cmdDetalles.ExecuteReader())
                            {
                                while (rdr.Read())
                                {
                                    detalles.Add(Tuple.Create(
                                        Convert.ToInt32(rdr["IdReservaDetalle"]),
                                        Convert.ToInt32(rdr["IdVuelo"]),
                                        Convert.ToInt32(rdr["Cantidad"])));
                                }
                            }
                        }

                        var ahora = DateTime.Now;
                        using (var cmdUpd = new SqlCommand(@"UPDATE ReservaCabecera
SET Estado = @Estado,
    FechaActualizacion = @FechaActualizacion,
    FechaCancelacion = @FechaCancelacion,
    IdUsuarioCancela = @IdUsuarioCancela
WHERE IdReservaCabecera = @Id", cn, tran))
                        {
                            cmdUpd.Parameters.AddWithValue("@Estado", "Cancelada");
                            cmdUpd.Parameters.AddWithValue("@FechaActualizacion", ahora);
                            cmdUpd.Parameters.AddWithValue("@FechaCancelacion", ahora);
                            cmdUpd.Parameters.AddWithValue("@IdUsuarioCancela", idUsuarioCancela.HasValue ? (object)idUsuarioCancela.Value : DBNull.Value);
                            cmdUpd.Parameters.AddWithValue("@Id", idReservaCabecera);
                            cmdUpd.ExecuteNonQuery();
                        }

                        using (var cmdDetalles = new SqlCommand(@"UPDATE ReservaDetalle
SET Estado = @Estado
WHERE IdReservaCabecera = @Id AND Estado = @EstadoActual", cn, tran))
                        {
                            cmdDetalles.Parameters.AddWithValue("@Estado", "Cancelado");
                            cmdDetalles.Parameters.AddWithValue("@EstadoActual", "Activo");
                            cmdDetalles.Parameters.AddWithValue("@Id", idReservaCabecera);
                            cmdDetalles.ExecuteNonQuery();
                        }

                        foreach (var detalle in detalles)
                        {
                            using (var cmdSeats = new SqlCommand(@"UPDATE Vuelos
SET CuposDisponibles = CuposDisponibles + @Cantidad,
    FechaActualizacion = @FechaActualizacion
WHERE IdVuelo = @IdVuelo", cn, tran))
                            {
                                cmdSeats.Parameters.AddWithValue("@Cantidad", detalle.Item3);
                                cmdSeats.Parameters.AddWithValue("@FechaActualizacion", ahora);
                                cmdSeats.Parameters.AddWithValue("@IdVuelo", detalle.Item2);
                                cmdSeats.ExecuteNonQuery();
                            }
                        }

                        var integrity = new IntegrityService();
                        integrity.UpdateRecordDVH(cn, tran, "ReservaCabecera", idReservaCabecera);
                        foreach (var detalle in detalles)
                        {
                            integrity.UpdateRecordDVH(cn, tran, "ReservaDetalle", detalle.Item1);
                            integrity.UpdateRecordDVH(cn, tran, "Vuelos", detalle.Item2);
                        }

                        integrity.UpdateTableDVV(cn, tran, "ReservaCabecera");
                        integrity.UpdateTableDVV(cn, tran, "ReservaDetalle");
                        integrity.UpdateTableDVV(cn, tran, "Vuelos");

                        tran.Commit();
                        return 1;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        private ReservaCabecera MapearCabecera(SqlDataReader rdr)
        {
            return new ReservaCabecera
            {
                IdReservaCabecera = Convert.ToInt32(rdr["IdReservaCabecera"]),
                IdCliente = Convert.ToInt32(rdr["IdCliente"]),
                IdUsuarioCreador = Convert.ToInt32(rdr["IdUsuarioCreador"]),
                FechaReserva = Convert.ToDateTime(rdr["FechaReserva"]),
                Estado = rdr["Estado"].ToString(),
                MontoTotal = Convert.ToDecimal(rdr["MontoTotal"]),
                FechaCreacion = Convert.ToDateTime(rdr["FechaCreacion"]),
                FechaActualizacion = rdr["FechaActualizacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaActualizacion"]) : (DateTime?)null,
                FechaCancelacion = rdr["FechaCancelacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaCancelacion"]) : (DateTime?)null,
                IdUsuarioCancela = rdr["IdUsuarioCancela"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuarioCancela"]) : (int?)null
            };
        }
    }
}
