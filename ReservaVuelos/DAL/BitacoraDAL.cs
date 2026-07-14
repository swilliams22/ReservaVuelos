using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class BitacoraDAL
    {
        public int Create(ReservaVuelos.BE.Bitacora b)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        int id;
                        using (var cmd = new SqlCommand(@"INSERT INTO Bitacora (Fecha,Usuario,Accion,Criticidad,Pantalla,DVH) VALUES (@Fecha,@Usuario,@Accion,@Criticidad,@Pantalla,0); SELECT SCOPE_IDENTITY();", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@Fecha", b.Fecha);
                            cmd.Parameters.AddWithValue("@Usuario", b.Usuario ?? string.Empty);
                            cmd.Parameters.AddWithValue("@Accion", b.Accion ?? string.Empty);
                            cmd.Parameters.AddWithValue("@Criticidad", b.Criticidad);
                            cmd.Parameters.AddWithValue("@Pantalla", b.Pantalla ?? string.Empty);
                            id = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Bitacora", id);
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

        public List<ReservaVuelos.BE.Bitacora> GetAll()
        {
            var res = new List<ReservaVuelos.BE.Bitacora>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Bitacora ORDER BY Fecha DESC", cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new ReservaVuelos.BE.Bitacora
                        {
                            IdBitacora = Convert.ToInt32(rdr["IdBitacora"]),
                            Fecha = Convert.ToDateTime(rdr["Fecha"]),
                            Usuario = rdr["Usuario"].ToString(),
                            Accion = rdr["Accion"].ToString(),
                            Criticidad = Convert.ToInt32(rdr["Criticidad"]),
                            Pantalla = rdr["Pantalla"].ToString()
                        });
                    }
                }
            }
            return res;
        }

        public List<ReservaVuelos.BE.Bitacora> GetByFilters(DateTime? desde, DateTime? hasta, string usuario, int? criticidad, string pantalla)
        {
            var res = new List<ReservaVuelos.BE.Bitacora>();
            using (var cn = ConexionDAL.GetConnection())
            {
                var sql = "SELECT * FROM Bitacora WHERE 1=1";
                if (desde.HasValue) sql += " AND Fecha >= @Desde";
                if (hasta.HasValue) sql += " AND Fecha <= @Hasta";
                if (!string.IsNullOrWhiteSpace(usuario)) sql += " AND Usuario LIKE @Usuario";
                if (criticidad.HasValue) sql += " AND Criticidad = @Criticidad";
                if (!string.IsNullOrWhiteSpace(pantalla)) sql += " AND Pantalla LIKE @Pantalla";
                sql += " ORDER BY Fecha DESC";

                using (var cmd = new SqlCommand(sql, cn))
                {
                    if (desde.HasValue) cmd.Parameters.AddWithValue("@Desde", desde.Value);
                    if (hasta.HasValue) cmd.Parameters.AddWithValue("@Hasta", hasta.Value);
                    if (!string.IsNullOrWhiteSpace(usuario)) cmd.Parameters.AddWithValue("@Usuario", "%" + usuario + "%");
                    if (criticidad.HasValue) cmd.Parameters.AddWithValue("@Criticidad", criticidad.Value);
                    if (!string.IsNullOrWhiteSpace(pantalla)) cmd.Parameters.AddWithValue("@Pantalla", "%" + pantalla + "%");
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            res.Add(new ReservaVuelos.BE.Bitacora
                            {
                                IdBitacora = Convert.ToInt32(rdr["IdBitacora"]),
                                Fecha = Convert.ToDateTime(rdr["Fecha"]),
                                Usuario = rdr["Usuario"].ToString(),
                                Accion = rdr["Accion"].ToString(),
                                Criticidad = Convert.ToInt32(rdr["Criticidad"]),
                                Pantalla = rdr["Pantalla"].ToString()
                            });
                        }
                    }
                }
            }
            return res;
        }
    }
}
