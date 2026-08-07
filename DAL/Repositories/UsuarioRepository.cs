using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using Entities.Models;

namespace DAL.Repositories
{
    public class UsuarioRepository
    {
        private readonly string _cadena =
            ConfigurationManager.ConnectionStrings["cn"].ConnectionString;

        public Usuario ValidarLogin(string correo, string contraseniaHash)
        {
            using (var conn = new SqlConnection(_cadena))
            using (var cmd = new SqlCommand("sp_Usuario_ValidarLogin", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@CorreoUsuario", correo);
                cmd.Parameters.AddWithValue("@ContraseniaHash", contraseniaHash);
                conn.Open();

                using (var reader = cmd.ExecuteReader())
                {
                    if (!reader.Read()) return null;
                    return new Usuario
                    {
                        UsuarioId = (int)reader["UsuarioId"],
                        NombreUsuario = reader["NombreUsuario"].ToString(),
                        ApellidoUsuario = reader["ApellidoUsuario"].ToString(),
                        CorreoUsuario = reader["CorreoUsuario"].ToString(),
                        Rol = reader["Rol"].ToString()
                    };
                }
            }
        }

        public int Registrar(Usuario u, string contraseniaHash)
        {
            using (var conn = new SqlConnection(_cadena))
            using (var cmd = new SqlCommand("sp_Usuario_Registrar", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@NombreUsuario", u.NombreUsuario);
                cmd.Parameters.AddWithValue("@ApellidoUsuario", u.ApellidoUsuario);
                cmd.Parameters.AddWithValue("@CorreoUsuario", u.CorreoUsuario);
                cmd.Parameters.AddWithValue("@ContraseniaHash", contraseniaHash);
                cmd.Parameters.AddWithValue("@Rol", u.Rol ?? "Operador");
                conn.Open();
                return (int)cmd.ExecuteScalar();
            }
        }
    }
}