using ReservaVuelos.BE;
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
            using (var cmd = new SqlCommand(@"INSERT INTO Bitacora (Fecha,Usuario,Accion,Criticidad,Pantalla) VALUES (@Fecha,@Usuario,@Accion,@Criticidad,@Pantalla); SELECT SCOPE_IDENTITY();", cn))
            {
                cmd.Parameters.AddWithValue("@Fecha", b.Fecha);
                cmd.Parameters.AddWithValue("@Usuario", b.Usuario ?? string.Empty);
                cmd.Parameters.AddWithValue("@Accion", b.Accion ?? string.Empty);
                cmd.Parameters.AddWithValue("@Criticidad", b.Criticidad ?? string.Empty);
                cmd.Parameters.AddWithValue("@Pantalla", b.Pantalla ?? string.Empty);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar());
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
                            Criticidad = rdr["Criticidad"].ToString(),
                            Pantalla = rdr["Pantalla"].ToString()
                        });
                    }
                }
            }
            return res;
        }

        public List<ReservaVuelos.BE.Bitacora> GetByFilters(DateTime? desde, DateTime? hasta, string usuario, string criticidad, string pantalla)
        {
            var res = new List<ReservaVuelos.BE.Bitacora>();
            using (var cn = ConexionDAL.GetConnection())
            {
                var sql = "SELECT * FROM Bitacora WHERE 1=1";
                if (desde.HasValue) sql += " AND Fecha >= @Desde";
                if (hasta.HasValue) sql += " AND Fecha <= @Hasta";
                if (!string.IsNullOrWhiteSpace(usuario)) sql += " AND Usuario LIKE @Usuario";
                if (!string.IsNullOrWhiteSpace(criticidad) && criticidad != "Todos") sql += " AND Criticidad = @Criticidad";
                if (!string.IsNullOrWhiteSpace(pantalla)) sql += " AND Pantalla LIKE @Pantalla";
                sql += " ORDER BY Fecha DESC";

                using (var cmd = new SqlCommand(sql, cn))
                {
                    if (desde.HasValue) cmd.Parameters.AddWithValue("@Desde", desde.Value);
                    if (hasta.HasValue) cmd.Parameters.AddWithValue("@Hasta", hasta.Value);
                    if (!string.IsNullOrWhiteSpace(usuario)) cmd.Parameters.AddWithValue("@Usuario", "%" + usuario + "%");
                    if (!string.IsNullOrWhiteSpace(criticidad) && criticidad != "Todos") cmd.Parameters.AddWithValue("@Criticidad", criticidad);
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
                                Criticidad = rdr["Criticidad"].ToString(),
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
