using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Data;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class UsuarioDAL
    {
        public Usuario GetByEmail(string email)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT * FROM Usuarios WHERE Email = @Email", cn))
            {
                cmd.Parameters.AddWithValue("@Email", email);
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        return new Usuario
                        {
                            IdUsuario = Convert.ToInt32(rdr["IdUsuario"]),
                            Nombre = rdr["Nombre"].ToString(),
                            Email = rdr["Email"].ToString(),
                            PasswordHash = rdr["PasswordHash"].ToString(),
                            PasswordSalt = rdr["PasswordSalt"].ToString(),
                            Rol = rdr["Rol"].ToString(),
                            Activo = Convert.ToBoolean(rdr["Activo"]),
                            FechaAlta = Convert.ToDateTime(rdr["FechaAlta"]),
                            DVH = rdr["DVH"] != DBNull.Value ? Convert.ToInt32(rdr["DVH"]) : 0
                        };
                    }
                }
            }
            return null;
        }

        public int Create(Usuario u)
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        int id;
                        using (var cmd = new SqlCommand(@"INSERT INTO Usuarios (Nombre, Email, PasswordHash, PasswordSalt, Rol, Activo, FechaAlta, DVH)
VALUES (@Nombre,@Email,@PasswordHash,@PasswordSalt,@Rol,@Activo,@FechaAlta,0); SELECT SCOPE_IDENTITY();", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@Nombre", u.Nombre);
                            cmd.Parameters.AddWithValue("@Email", u.Email);
                            cmd.Parameters.AddWithValue("@PasswordHash", u.PasswordHash);
                            cmd.Parameters.AddWithValue("@PasswordSalt", u.PasswordSalt);
                            cmd.Parameters.AddWithValue("@Rol", u.Rol);
                            cmd.Parameters.AddWithValue("@Activo", u.Activo);
                            cmd.Parameters.AddWithValue("@FechaAlta", u.FechaAlta);
                            id = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Usuarios", id);
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
    }
}
