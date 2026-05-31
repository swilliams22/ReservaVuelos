using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class ReservaDAL
    {
        public int Create(Reserva r)
        {
            // Operación transaccional: verificar cupos, decrementar y crear reserva
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        // Bloquear fila del vuelo para evitar race conditions
                        using (var cmdCheck = new SqlCommand("SELECT CuposDisponibles FROM Vuelos WITH (UPDLOCK, ROWLOCK) WHERE IdVuelo = @IdVuelo", cn, tran))
                        {
                            cmdCheck.Parameters.AddWithValue("@IdVuelo", r.IdVuelo);
                            var obj = cmdCheck.ExecuteScalar();
                            if (obj == null) throw new Exception("Vuelo no encontrado.");
                            var cupos = Convert.ToInt32(obj);
                            if (cupos <= 0) throw new Exception("No hay cupos disponibles para este vuelo.");
                        }

                        using (var cmdUpdate = new SqlCommand("UPDATE Vuelos SET CuposDisponibles = CuposDisponibles - 1 WHERE IdVuelo = @IdVuelo", cn, tran))
                        {
                            cmdUpdate.Parameters.AddWithValue("@IdVuelo", r.IdVuelo);
                            cmdUpdate.ExecuteNonQuery();
                        }

                        using (var cmdInsert = new SqlCommand(@"INSERT INTO Reservas (IdUsuario,IdVuelo,FechaReserva,Estado) VALUES (@IdUsuario,@IdVuelo,@FechaReserva,@Estado); SELECT SCOPE_IDENTITY();", cn, tran))
                        {
                            cmdInsert.Parameters.AddWithValue("@IdUsuario", r.IdUsuario);
                            cmdInsert.Parameters.AddWithValue("@IdVuelo", r.IdVuelo);
                            cmdInsert.Parameters.AddWithValue("@FechaReserva", r.FechaReserva);
                            cmdInsert.Parameters.AddWithValue("@Estado", r.Estado);
                            var idObj = cmdInsert.ExecuteScalar();
                            tran.Commit();
                            return Convert.ToInt32(idObj);
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

        public List<Reserva> GetByUsuario(int idUsuario)
        {
            var res = new List<Reserva>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Reservas WHERE IdUsuario = @IdUsuario", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Reserva
                        {
                            IdReserva = Convert.ToInt32(rdr["IdReserva"]),
                            IdUsuario = Convert.ToInt32(rdr["IdUsuario"]),
                            IdVuelo = Convert.ToInt32(rdr["IdVuelo"]),
                            FechaReserva = Convert.ToDateTime(rdr["FechaReserva"]),
                            Estado = rdr["Estado"].ToString()
                        });
                    }
                }
            }
            return res;
        }

        public int Cancel(int idReserva)
        {
            // Transacción: marcar reserva como cancelada y restaurar cupo en vuelo
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        // Obtener reserva y bloquear
                        int idVuelo = 0;
                        string estado = null;
                        using (var cmdGet = new SqlCommand("SELECT IdVuelo, Estado FROM Reservas WITH (UPDLOCK, ROWLOCK) WHERE IdReserva = @Id", cn, tran))
                        {
                            cmdGet.Parameters.AddWithValue("@Id", idReserva);
                            using (var rdr = cmdGet.ExecuteReader())
                            {
                                if (rdr.Read())
                                {
                                    idVuelo = Convert.ToInt32(rdr["IdVuelo"]);
                                    estado = rdr["Estado"].ToString();
                                }
                                else
                                {
                                    tran.Rollback();
                                    return 0; // no encontrada
                                }
                            }
                        }

                        if (string.Equals(estado, "Cancelada", StringComparison.OrdinalIgnoreCase))
                        {
                            tran.Rollback();
                            return 0; // ya estaba cancelada
                        }

                        using (var cmdUpd = new SqlCommand("UPDATE Reservas SET Estado = @Estado WHERE IdReserva = @Id", cn, tran))
                        {
                            cmdUpd.Parameters.AddWithValue("@Estado", "Cancelada");
                            cmdUpd.Parameters.AddWithValue("@Id", idReserva);
                            cmdUpd.ExecuteNonQuery();
                        }

                        using (var cmdSeats = new SqlCommand("UPDATE Vuelos SET CuposDisponibles = CuposDisponibles + 1 WHERE IdVuelo = @IdVuelo", cn, tran))
                        {
                            cmdSeats.Parameters.AddWithValue("@IdVuelo", idVuelo);
                            cmdSeats.ExecuteNonQuery();
                        }

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

        public bool ExistsActiveReservation(int idUsuario, int idVuelo)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Reservas WHERE IdUsuario = @IdUsuario AND IdVuelo = @IdVuelo AND Estado = @Estado", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cmd.Parameters.AddWithValue("@IdVuelo", idVuelo);
                cmd.Parameters.AddWithValue("@Estado", "Activa");
                cn.Open();
                var obj = cmd.ExecuteScalar();
                return Convert.ToInt32(obj) > 0;
            }
        }

        public Reserva GetById(int idReserva)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Reservas WHERE IdReserva = @Id", cn))
            {
                cmd.Parameters.AddWithValue("@Id", idReserva);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        return new Reserva
                        {
                            IdReserva = Convert.ToInt32(rdr["IdReserva"]),
                            IdUsuario = Convert.ToInt32(rdr["IdUsuario"]),
                            IdVuelo = Convert.ToInt32(rdr["IdVuelo"]),
                            FechaReserva = Convert.ToDateTime(rdr["FechaReserva"]),
                            Estado = rdr["Estado"].ToString()
                        };
                    }
                }
            }
            return null;
        }

        public List<Reserva> GetAll()
        {
            var res = new List<Reserva>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Reservas", cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Reserva
                        {
                            IdReserva = Convert.ToInt32(rdr["IdReserva"]),
                            IdUsuario = Convert.ToInt32(rdr["IdUsuario"]),
                            IdVuelo = Convert.ToInt32(rdr["IdVuelo"]),
                            FechaReserva = Convert.ToDateTime(rdr["FechaReserva"]),
                            Estado = rdr["Estado"].ToString()
                        });
                    }
                }
            }
            return res;
        }
    }
}
