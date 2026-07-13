using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class PasajeroDAL
    {
        private readonly EncryptionService _encryptionService = new EncryptionService();
        public int Create(Pasajero p)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"INSERT INTO Pasajeros (IdUsuario, Nombre, Apellido, Email, Documento, Nacionalidad, FechaNacimiento, FechaAlta, FechaActualizacion)
VALUES (@IdUsuario, @Nombre, @Apellido, @Email, @Documento, @Nacionalidad, @FechaNacimiento, @FechaAlta, @FechaActualizacion); SELECT SCOPE_IDENTITY();", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", p.IdUsuario.HasValue ? (object)p.IdUsuario.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@Nombre", p.Nombre ?? string.Empty);
                cmd.Parameters.AddWithValue("@Apellido", string.IsNullOrWhiteSpace(p.Apellido) ? (object)DBNull.Value : p.Apellido.Trim());
                cmd.Parameters.AddWithValue("@Email", string.IsNullOrWhiteSpace(p.Email) ? (object)DBNull.Value : p.Email.Trim());
                cmd.Parameters.AddWithValue("@Documento", p.Documento ?? string.Empty);
                cmd.Parameters.AddWithValue("@Nacionalidad", EncryptOrDbNull(p.Nacionalidad));
                cmd.Parameters.AddWithValue("@FechaNacimiento", p.FechaNacimiento.HasValue ? (object)p.FechaNacimiento.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@FechaAlta", p.FechaAlta);
                cmd.Parameters.AddWithValue("@FechaActualizacion", p.FechaActualizacion.HasValue ? (object)p.FechaActualizacion.Value : DBNull.Value);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        public Pasajero GetById(int idPasajero)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Pasajeros WHERE IdPasajero = @IdPasajero", cn))
            {
                cmd.Parameters.AddWithValue("@IdPasajero", idPasajero);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearPasajero(rdr);
                }
            }

            return null;
        }

        public Pasajero GetByEmail(string email)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Pasajeros WHERE Email = @Email", cn))
            {
                cmd.Parameters.AddWithValue("@Email", email);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearPasajero(rdr);
                }
            }

            return null;
        }

        public Pasajero GetByDocumento(string documento)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Pasajeros WHERE Documento = @Documento", cn))
            {
                cmd.Parameters.AddWithValue("@Documento", documento);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearPasajero(rdr);
                }
            }

            return null;
        }

        public Pasajero GetByIdUsuario(int idUsuario)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Pasajeros WHERE IdUsuario = @IdUsuario", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearPasajero(rdr);
                }
            }

            return null;
        }

        public bool ExistsWithEmail(string email)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM Pasajeros WHERE Email = @Email", cn))
            {
                cmd.Parameters.AddWithValue("@Email", email);
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        public int Update(Pasajero p)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"UPDATE Pasajeros
SET Nombre = @Nombre,
    Apellido = @Apellido,
    Email = @Email,
    Documento = @Documento,
    Nacionalidad = @Nacionalidad,
    FechaNacimiento = @FechaNacimiento,
    FechaActualizacion = @FechaActualizacion
WHERE IdPasajero = @IdPasajero", cn))
            {
                cmd.Parameters.AddWithValue("@IdPasajero", p.IdPasajero);
                cmd.Parameters.AddWithValue("@Nombre", p.Nombre ?? string.Empty);
                cmd.Parameters.AddWithValue("@Apellido", string.IsNullOrWhiteSpace(p.Apellido) ? (object)DBNull.Value : p.Apellido.Trim());
                cmd.Parameters.AddWithValue("@Email", string.IsNullOrWhiteSpace(p.Email) ? (object)DBNull.Value : p.Email.Trim());
                cmd.Parameters.AddWithValue("@Documento", p.Documento ?? string.Empty);
                cmd.Parameters.AddWithValue("@Nacionalidad", EncryptOrDbNull(p.Nacionalidad));
                cmd.Parameters.AddWithValue("@FechaNacimiento", p.FechaNacimiento.HasValue ? (object)p.FechaNacimiento.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@FechaActualizacion", p.FechaActualizacion.HasValue ? (object)p.FechaActualizacion.Value : DateTime.Now);
                cn.Open();
                return cmd.ExecuteNonQuery();
            }
        }

        public int VincularConUsuario(int idPasajero, int idUsuario)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"UPDATE Pasajeros
SET IdUsuario = @IdUsuario,
    FechaActualizacion = @FechaActualizacion
WHERE IdPasajero = @IdPasajero
  AND IdUsuario IS NULL", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cmd.Parameters.AddWithValue("@IdPasajero", idPasajero);
                cmd.Parameters.AddWithValue("@FechaActualizacion", DateTime.Now);
                cn.Open();
                return cmd.ExecuteNonQuery();
            }
        }

        private Pasajero MapearPasajero(SqlDataReader rdr)
        {
            return new Pasajero
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
            };
        }

        private object EncryptOrDbNull(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return DBNull.Value;
            return _encryptionService.Encrypt(value.Trim());
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
