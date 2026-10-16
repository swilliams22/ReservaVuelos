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
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (SqlTransaction tran = cn.BeginTransaction())
                {
                    try
                    {
                        int idReservaCabecera;
                        using (SqlCommand cmd = new SqlCommand(@"INSERT INTO ReservaCabecera (IdCliente, IdUsuarioCreador, FechaReserva, Estado, MontoTotal, FechaCreacion, FechaActualizacion, FechaCancelacion, IdUsuarioCancela, DVH)
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

                        HashSet<int> vuelosAfectados = new HashSet<int>();
                        List<int> detallesInsertados = new List<int>();
                        foreach (ReservaDetalle detalle in detalles)
                        {
                            using (SqlCommand cmdCheck = new SqlCommand(@"SELECT Activo, CuposDisponibles, FechaSalida, HoraSalida
FROM Vuelos WITH (UPDLOCK, ROWLOCK)
WHERE IdVuelo = @IdVuelo", cn, tran))
                            {
                                cmdCheck.Parameters.AddWithValue("@IdVuelo", detalle.IdVuelo);
                                using (SqlDataReader rdr = cmdCheck.ExecuteReader())
                                {
                                    if (!rdr.Read())
                                        throw new Exception(string.Format("Vuelo {0} no encontrado.", detalle.IdVuelo));

                                    bool activo = Convert.ToBoolean(rdr["Activo"]);
                                    int cupos = Convert.ToInt32(rdr["CuposDisponibles"]);
                                    DateTime fechaSalida = Convert.ToDateTime(rdr["FechaSalida"]);
                                    TimeSpan horaSalida = (TimeSpan)rdr["HoraSalida"];
                                    DateTime fechaHoraSalida = fechaSalida.Date.Add(horaSalida);

                                    if (!activo)
                                        throw new Exception(string.Format("El vuelo {0} no se encuentra activo.", detalle.IdVuelo));

                                    if (fechaHoraSalida <= DateTime.Now)
                                        throw new Exception(string.Format("No se pueden reservar vuelos pasados. Vuelo {0}.", detalle.IdVuelo));

                                    if (cupos < detalle.Cantidad)
                                        throw new Exception(string.Format("No hay suficientes cupos disponibles para el vuelo {0}. Disponibles: {1}, Solicitados: {2}", detalle.IdVuelo, cupos, detalle.Cantidad));
                                }
                            }

                            using (SqlCommand cmdUpdate = new SqlCommand(@"UPDATE Vuelos
SET CuposDisponibles = CuposDisponibles - @Cantidad,
    FechaActualizacion = @FechaActualizacion
WHERE IdVuelo = @IdVuelo
  AND CuposDisponibles >= @Cantidad", cn, tran))
                            {
                                cmdUpdate.Parameters.AddWithValue("@Cantidad", detalle.Cantidad);
                                cmdUpdate.Parameters.AddWithValue("@FechaActualizacion", DateTime.Now);
                                cmdUpdate.Parameters.AddWithValue("@IdVuelo", detalle.IdVuelo);
                                int rows = cmdUpdate.ExecuteNonQuery();
                                if (rows == 0)
                                    throw new Exception(string.Format("No fue posible reservar cupos para el vuelo {0}. Reintente la operación.", detalle.IdVuelo));
                            }
                            vuelosAfectados.Add(detalle.IdVuelo);

                            using (SqlCommand cmd = new SqlCommand(@"INSERT INTO ReservaDetalle (IdReservaCabecera, IdVuelo, Cantidad, PrecioUnitario, SubTotal, Estado, DVH)
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

                        List<int> reservaPasajeroInsertados = new List<int>();
                        foreach (ReservaPasajero rp in pasajeros)
                        {
                            using (SqlCommand cmd = new SqlCommand(@"INSERT INTO ReservaPasajero (IdReservaCabecera, IdPasajero, DVH)
VALUES (@IdReservaCabecera, @IdPasajero, 0);
SELECT SCOPE_IDENTITY();", cn, tran))
                            {
                                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                                cmd.Parameters.AddWithValue("@IdPasajero", rp.IdPasajero);
                                reservaPasajeroInsertados.Add(Convert.ToInt32(cmd.ExecuteScalar()));
                            }
                        }

                        IntegrityService integrity = new IntegrityService();
                        integrity.UpdateRecordDVH(cn, tran, "ReservaCabecera", idReservaCabecera);
                        foreach (int detalleId in detallesInsertados)
                            integrity.UpdateRecordDVH(cn, tran, "ReservaDetalle", detalleId);
                        foreach (int reservaPasajeroId in reservaPasajeroInsertados)
                            integrity.UpdateRecordDVH(cn, tran, "ReservaPasajero", reservaPasajeroId);
                        foreach (int vueloId in vuelosAfectados)
                            integrity.UpdateRecordDVH(cn, tran, "Vuelos", vueloId);

                        integrity.UpdateTableDVV(cn, tran, "ReservaCabecera");
                        integrity.UpdateTableDVV(cn, tran, "ReservaDetalle");
                        integrity.UpdateTableDVV(cn, tran, "ReservaPasajero");
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
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand("SELECT * FROM ReservaCabecera WHERE IdReservaCabecera = @IdReservaCabecera", cn))
            {
                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearCabecera(rdr);
                }
            }

            return null;
        }

        public List<ReservaCabecera> GetByIdCliente(int idCliente)
        {
            List<ReservaCabecera> res = new List<ReservaCabecera>();
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand("SELECT * FROM ReservaCabecera WHERE IdCliente = @IdCliente ORDER BY FechaReserva DESC", cn))
            {
                cmd.Parameters.AddWithValue("@IdCliente", idCliente);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        res.Add(MapearCabecera(rdr));
                }
            }

            return res;
        }

        public List<ReservaCabecera> GetByIdPasajero(int idPasajero)
        {
            List<ReservaCabecera> res = new List<ReservaCabecera>();
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand(@"SELECT DISTINCT rc.*
FROM ReservaCabecera rc
INNER JOIN ReservaPasajero rp ON rc.IdReservaCabecera = rp.IdReservaCabecera
WHERE rp.IdPasajero = @IdPasajero
ORDER BY rc.FechaReserva DESC", cn))
            {
                cmd.Parameters.AddWithValue("@IdPasajero", idPasajero);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        res.Add(MapearCabecera(rdr));
                }
            }

            return res;
        }

        public int Cancel(int idReservaCabecera, int? idUsuarioCancela)
        {
            if (!idUsuarioCancela.HasValue)
                throw new System.Web.HttpException(403, "Debe identificarse para cancelar una reserva.");
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (SqlTransaction tran = cn.BeginTransaction())
                {
                    try
                    {
                        string estado = null;
                        // Validación de pertenencia en la misma transacción que cancela.
                        // Se conserva el acceso de titular o pasajero vinculado de MisReservas.
                        using (SqlCommand cmdGet = new SqlCommand(@"SELECT rc.Estado FROM ReservaCabecera rc WITH (UPDLOCK, ROWLOCK)
WHERE rc.IdReservaCabecera = @Id AND (
 EXISTS (SELECT 1 FROM Clientes c WHERE c.IdCliente=rc.IdCliente AND c.IdUsuario=@Usuario)
 OR EXISTS (SELECT 1 FROM ReservaPasajero rp JOIN Pasajeros p ON p.IdPasajero=rp.IdPasajero
            WHERE rp.IdReservaCabecera=rc.IdReservaCabecera AND p.IdUsuario=@Usuario))", cn, tran))
                        {
                            cmdGet.Parameters.AddWithValue("@Id", idReservaCabecera);
                            cmdGet.Parameters.AddWithValue("@Usuario", idUsuarioCancela.Value);
                            object result = cmdGet.ExecuteScalar();
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

                        List<Tuple<int, int, int>> detalles = new List<Tuple<int, int, int>>();
                        using (SqlCommand cmdDetalles = new SqlCommand("SELECT IdReservaDetalle, IdVuelo, Cantidad FROM ReservaDetalle WHERE IdReservaCabecera = @Id AND Estado = @Estado", cn, tran))
                        {
                            cmdDetalles.Parameters.AddWithValue("@Id", idReservaCabecera);
                            cmdDetalles.Parameters.AddWithValue("@Estado", "Activo");
                            using (SqlDataReader rdr = cmdDetalles.ExecuteReader())
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

                        DateTime ahora = DateTime.Now;
                        using (SqlCommand cmdUpd = new SqlCommand(@"UPDATE ReservaCabecera
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

                        using (SqlCommand cmdDetalles = new SqlCommand(@"UPDATE ReservaDetalle
SET Estado = @Estado
WHERE IdReservaCabecera = @Id AND Estado = @EstadoActual", cn, tran))
                        {
                            cmdDetalles.Parameters.AddWithValue("@Estado", "Cancelado");
                            cmdDetalles.Parameters.AddWithValue("@EstadoActual", "Activo");
                            cmdDetalles.Parameters.AddWithValue("@Id", idReservaCabecera);
                            cmdDetalles.ExecuteNonQuery();
                        }

                        foreach (Tuple<int, int, int> detalle in detalles)
                        {
                            using (SqlCommand cmdSeats = new SqlCommand(@"UPDATE Vuelos
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

                        IntegrityService integrity = new IntegrityService();
                        integrity.UpdateRecordDVH(cn, tran, "ReservaCabecera", idReservaCabecera);
                        foreach (Tuple<int, int, int> detalle in detalles)
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
