using ReservaVuelos.BE;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class ReservaDetalleDAL
    {
        public List<ReservaDetalle> GetByReservaCabecera(int idReservaCabecera)
        {
            var res = new List<ReservaDetalle>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT rd.*, v.Origen, v.Destino, v.FechaSalida, v.HoraSalida
FROM ReservaDetalle rd
INNER JOIN Vuelos v ON rd.IdVuelo = v.IdVuelo
WHERE rd.IdReservaCabecera = @IdReservaCabecera
ORDER BY v.FechaSalida ASC, v.HoraSalida ASC", cn))
            {
                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var fechaSalida = Convert.ToDateTime(rdr["FechaSalida"]);
                        var horaSalida = (TimeSpan)rdr["HoraSalida"];
                        var precioUnitario = Convert.ToDecimal(rdr["PrecioUnitario"]);

                        res.Add(new ReservaDetalle
                        {
                            IdReservaDetalle = Convert.ToInt32(rdr["IdReservaDetalle"]),
                            IdReservaCabecera = Convert.ToInt32(rdr["IdReservaCabecera"]),
                            IdVuelo = Convert.ToInt32(rdr["IdVuelo"]),
                            Cantidad = Convert.ToInt32(rdr["Cantidad"]),
                            PrecioUnitario = precioUnitario,
                            SubTotal = Convert.ToDecimal(rdr["SubTotal"]),
                            Estado = rdr["Estado"].ToString(),
                            Origen = rdr["Origen"].ToString(),
                            Destino = rdr["Destino"].ToString(),
                            FechaSalida = fechaSalida,
                            HoraSalida = horaSalida,
                            FechaHoraSalida = fechaSalida.Date.Add(horaSalida),
                            Precio = precioUnitario,
                            DVH = rdr["DVH"] != DBNull.Value ? Convert.ToInt32(rdr["DVH"]) : 0
                        });
                    }
                }
            }

            return res;
        }
    }
}
