using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class ClienteDAL
    {
        private readonly EncryptionService _encryptionService = new EncryptionService();
        public Cliente GetByIdUsuario(int idUsuario)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Clientes WHERE IdUsuario = @IdUsuario", cn))
            {
                cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearCliente(rdr);
                }
            }

            return null;
        }

        public Cliente GetById(int idCliente)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Clientes WHERE IdCliente = @IdCliente", cn))
            {
                cmd.Parameters.AddWithValue("@IdCliente", idCliente);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                        return MapearCliente(rdr);
                }
            }

            return null;
        }

        public int Create(Cliente c)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        int id;
                        using (var cmd = new SqlCommand(@"INSERT INTO Clientes (IdUsuario, Nombre, Email, Documento, Telefono, Direccion, FechaAlta, FechaActualizacion, DVH)
VALUES (@IdUsuario, @Nombre, @Email, @Documento, @Telefono, @Direccion, @FechaAlta, @FechaActualizacion, 0); SELECT SCOPE_IDENTITY();", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@IdUsuario", c.IdUsuario);
                            cmd.Parameters.AddWithValue("@Nombre", c.Nombre ?? string.Empty);
                            cmd.Parameters.AddWithValue("@Email", c.Email ?? string.Empty);
                            cmd.Parameters.AddWithValue("@Documento", string.IsNullOrWhiteSpace(c.Documento) ? (object)DBNull.Value : c.Documento.Trim());
                            cmd.Parameters.AddWithValue("@Telefono", EncryptOrDbNull(c.Telefono));
                            cmd.Parameters.AddWithValue("@Direccion", EncryptOrDbNull(c.Direccion));
                            cmd.Parameters.AddWithValue("@FechaAlta", c.FechaAlta);
                            cmd.Parameters.AddWithValue("@FechaActualizacion", c.FechaActualizacion.HasValue ? (object)c.FechaActualizacion.Value : DBNull.Value);
                            id = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Clientes", id);
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

        public int Update(Cliente c)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        int rows;
                        using (var cmd = new SqlCommand(@"UPDATE Clientes
SET Nombre = @Nombre,
    Email = @Email,
    Documento = @Documento,
    Telefono = @Telefono,
    Direccion = @Direccion,
    FechaActualizacion = @FechaActualizacion
WHERE IdCliente = @IdCliente", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@IdCliente", c.IdCliente);
                            cmd.Parameters.AddWithValue("@Nombre", c.Nombre ?? string.Empty);
                            cmd.Parameters.AddWithValue("@Email", c.Email ?? string.Empty);
                            cmd.Parameters.AddWithValue("@Documento", string.IsNullOrWhiteSpace(c.Documento) ? (object)DBNull.Value : c.Documento.Trim());
                            cmd.Parameters.AddWithValue("@Telefono", EncryptOrDbNull(c.Telefono));
                            cmd.Parameters.AddWithValue("@Direccion", EncryptOrDbNull(c.Direccion));
                            cmd.Parameters.AddWithValue("@FechaActualizacion", c.FechaActualizacion.HasValue ? (object)c.FechaActualizacion.Value : DateTime.Now);
                            rows = cmd.ExecuteNonQuery();
                        }

                        if (rows > 0) new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Clientes", c.IdCliente);
                        tran.Commit();
                        return rows;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        private Cliente MapearCliente(SqlDataReader rdr)
        {
            return new Cliente
            {
                IdCliente = Convert.ToInt32(rdr["IdCliente"]),
                IdUsuario = Convert.ToInt32(rdr["IdUsuario"]),
                Nombre = rdr["Nombre"].ToString(),
                Email = rdr["Email"].ToString(),
                Documento = rdr["Documento"] != DBNull.Value ? rdr["Documento"].ToString() : null,
                Telefono = DecryptOrNull(rdr["Telefono"]),
                Direccion = DecryptOrNull(rdr["Direccion"]),
                FechaAlta = Convert.ToDateTime(rdr["FechaAlta"]),
                FechaActualizacion = rdr["FechaActualizacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaActualizacion"]) : (DateTime?)null,
                DVH = rdr["DVH"] != DBNull.Value ? Convert.ToInt32(rdr["DVH"]) : 0
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
