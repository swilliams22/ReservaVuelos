using ReservaVuelos.BE;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public class UsuarioDAL
    {
        public Usuario GetByEmail(string email)
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand("SELECT * FROM Usuarios WHERE Email = @Email", cn))
            {
                cmd.Parameters.AddWithValue("@Email", email);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read()) return Mapear(rdr);
                }
            }
            return null;
        }

        public Usuario GetById(int idUsuario)
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand("SELECT * FROM Usuarios WHERE IdUsuario = @Id", cn))
            {
                cmd.Parameters.AddWithValue("@Id", idUsuario);
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read()) return Mapear(rdr);
                }
            }
            return null;
        }

        // Listado para la administración: no devuelve hash ni salt de la contraseña.
        public List<Usuario> Listar()
        {
            List<Usuario> res = new List<Usuario>();
            using (SqlConnection cn = ConexionDAL.GetConnection())
            using (SqlCommand cmd = new SqlCommand("SELECT IdUsuario, Nombre, Email, Rol, Activo, FechaAlta FROM Usuarios ORDER BY Nombre, Email", cn))
            {
                cn.Open();
                using (SqlDataReader rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        res.Add(new Usuario
                        {
                            IdUsuario = Convert.ToInt32(rdr["IdUsuario"]),
                            Nombre = rdr["Nombre"].ToString(),
                            Email = rdr["Email"].ToString(),
                            Rol = rdr["Rol"].ToString(),
                            Activo = Convert.ToBoolean(rdr["Activo"]),
                            FechaAlta = Convert.ToDateTime(rdr["FechaAlta"])
                        });
                    }
                }
            }
            return res;
        }

        public int Create(Usuario u)
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (SqlTransaction tran = cn.BeginTransaction())
                {
                    try
                    {
                        int id;
                        using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Usuarios (Nombre, Email, PasswordHash, PasswordSalt, Rol, Activo, FechaAlta, DVH)
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

        // Cambia el rol sólo si todavía es rolAnterior (evita pisar un cambio concurrente)
        // y recalcula DVH/DVV en la misma transacción. Devuelve false si no se modificó.
        // El trigger TR_Usuarios_ValidarRol rechaza (50004) un rol que no sea un grupo existente.
        public bool ActualizarRol(int idUsuario, string rolAnterior, string rolNuevo)
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (SqlTransaction tran = cn.BeginTransaction(IsolationLevel.Serializable))
                {
                    try
                    {
                        int filas;
                        using (SqlCommand cmd = new SqlCommand("UPDATE Usuarios SET Rol = @Nuevo WHERE IdUsuario = @Id AND Rol = @Anterior", cn, tran))
                        {
                            cmd.Parameters.AddWithValue("@Nuevo", rolNuevo);
                            cmd.Parameters.AddWithValue("@Id", idUsuario);
                            cmd.Parameters.AddWithValue("@Anterior", rolAnterior);
                            filas = cmd.ExecuteNonQuery();
                        }
                        if (filas != 1)
                        {
                            tran.Rollback();
                            return false;
                        }

                        new IntegrityService().UpdateRecordAndTableDVV(cn, tran, "Usuarios", idUsuario);
                        tran.Commit();
                        return true;
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        throw;
                    }
                }
            }
        }

        private static Usuario Mapear(SqlDataReader rdr)
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
