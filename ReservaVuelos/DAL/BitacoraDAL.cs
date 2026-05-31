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
    }
}
