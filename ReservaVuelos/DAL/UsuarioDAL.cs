using ReservaVuelos.BE;
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
                            FechaAlta = Convert.ToDateTime(rdr["FechaAlta"])
                        };
                    }
                }
            }
            return null;
        }

        public int Create(Usuario u)
        {
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"INSERT INTO Usuarios (Nombre, Email, PasswordHash, PasswordSalt, Rol, Activo, FechaAlta)
VALUES (@Nombre,@Email,@PasswordHash,@PasswordSalt,@Rol,@Activo,@FechaAlta); SELECT SCOPE_IDENTITY();", cn))
            {
                cmd.Parameters.AddWithValue("@Nombre", u.Nombre);
                cmd.Parameters.AddWithValue("@Email", u.Email);
                cmd.Parameters.AddWithValue("@PasswordHash", u.PasswordHash);
                cmd.Parameters.AddWithValue("@PasswordSalt", u.PasswordSalt);
                cmd.Parameters.AddWithValue("@Rol", u.Rol);
                cmd.Parameters.AddWithValue("@Activo", u.Activo);
                cmd.Parameters.AddWithValue("@FechaAlta", u.FechaAlta);
                cn.Open();
                var obj = cmd.ExecuteScalar();
                return Convert.ToInt32(obj);
            }
        }
    }
}
