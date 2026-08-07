using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace Entities.Models
{
    public class Usuario
    {
        public int UsuarioId { get; set; }

        [Required(ErrorMessage = "El nombre de usuario es obligatorio")]
        [StringLength(100, ErrorMessage = "El nombre de usuario no puede superar los 100 caracteres")]
        public string NombreUsuario { get; set; }

        [Required(ErrorMessage = "El apellido de usuario es obligatorio")]
        [StringLength(100, ErrorMessage = "El apellido de usuario no puede superar los 100 caracteres")]
        public string ApellidoUsuario { get; set; }

        [Required(ErrorMessage = "El correo es obligatorio")]
        [EmailAddress(ErrorMessage = "Ingrese un correo válido")]
        [StringLength(150)]
        [DataType(DataType.EmailAddress)]
        public string CorreoUsuario { get; set; }

        [Required(ErrorMessage = "La contraseña es obligatoria")]
        [StringLength(50)]
        [DataType(DataType.Password)]
        public string Contrasenia { get; set; }

        [Required(ErrorMessage = "El rol es obligatorio")]
        [RegularExpression("^(Admin|Operador)$", ErrorMessage = "El Rol debe ser 'Admin' u 'Operador'")]
        public string Rol { get; set; } = "Operador";
    }
}