using System.Security.Cryptography;
using System.Text;
using DAL.Repositories;
using Entities.Models;

namespace BLL.Services
{
    public class UsuarioService
    {
        private readonly UsuarioRepository _repo = new UsuarioRepository();

        public Usuario ValidarLogin(string correo, string contraseniaPlano)
        {
            return _repo.ValidarLogin(correo, HashSHA256(contraseniaPlano));
        }

        public bool Registrar(Usuario u)
        {
            int resultado = _repo.Registrar(u, HashSHA256(u.Contrasenia));
            return resultado != -1;
        }

        public static string HashSHA256(string texto)
        {
            using (var sha = SHA256.Create())
            {
                var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(texto));
                return System.Convert.ToBase64String(bytes);
            }
        }
    }
}