using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class ReservaPasajeroDAL
    {
        private readonly EncryptionService _encryptionService = new EncryptionService();
        public int Create(ReservaPasajero rp)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"INSERT INTO ReservaPasajero (IdReservaCabecera, IdPasajero)
VALUES (@IdReservaCabecera, @IdPasajero); SELECT SCOPE_IDENTITY();", cn))
            {
                cmd.Parameters.AddWithValue("@IdReservaCabecera", rp.IdReservaCabecera);
                cmd.Parameters.AddWithValue("@IdPasajero", rp.IdPasajero);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        public List<ReservaPasajero> GetByReservaCabecera(int idReservaCabecera)
        {
            var res = new List<ReservaPasajero>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM ReservaPasajero WHERE IdReservaCabecera = @IdReservaCabecera", cn))
            {
                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new ReservaPasajero
                        {
                            IdReservaPasajero = Convert.ToInt32(rdr["IdReservaPasajero"]),
                            IdReservaCabecera = Convert.ToInt32(rdr["IdReservaCabecera"]),
                            IdPasajero = Convert.ToInt32(rdr["IdPasajero"])
                        });
                    }
                }
            }

            return res;
        }

        public List<Pasajero> GetPasajerosByReservaCabecera(int idReservaCabecera)
        {
            var res = new List<Pasajero>();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"SELECT p.* FROM Pasajeros p
INNER JOIN ReservaPasajero rp ON p.IdPasajero = rp.IdPasajero
WHERE rp.IdReservaCabecera = @IdReservaCabecera
ORDER BY p.Nombre, p.Apellido, p.Documento", cn))
            {
                cmd.Parameters.AddWithValue("@IdReservaCabecera", idReservaCabecera);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Pasajero
                        {
                            IdPasajero = Convert.ToInt32(rdr["IdPasajero"]),
                            IdUsuario = rdr["IdUsuario"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuario"]) : (int?)null,
                            Nombre = rdr["Nombre"].ToString(),
                            Apellido = rdr["Apellido"] != DBNull.Value ? rdr["Apellido"].ToString() : null,
                            Email = rdr["Email"] != DBNull.Value ? rdr["Email"].ToString() : null,
                            Documento = rdr["Documento"].ToString(),
                            Nacionalidad = DecryptOrNull(rdr["Nacionalidad"]),
                            FechaNacimiento = rdr["FechaNacimiento"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaNacimiento"]) : (DateTime?)null,
                            FechaAlta = Convert.ToDateTime(rdr["FechaAlta"]),
                            FechaActualizacion = rdr["FechaActualizacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaActualizacion"]) : (DateTime?)null
                        });
                    }
                }
            }

            return res;
        }

        private string DecryptOrNull(object dbValue)
        {
            if (dbValue == DBNull.Value || dbValue == null) return null;
            var value = dbValue.ToString();
            if (string.IsNullOrWhiteSpace(value)) return string.Empty;
            return _encryptionService.Decrypt(value);
        }
    }
}
