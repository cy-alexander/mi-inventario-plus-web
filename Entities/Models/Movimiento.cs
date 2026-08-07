using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace Entities.Models
{
    public class Movimiento
    {
        public int MovimientoId { get; set; }

        [Required(ErrorMessage = "El Producto es obligatorio")]
        [Range(1, int.MaxValue, ErrorMessage = "Debe seleccionar un producto válido")]
        public int ProductoId { get; set; }

        [Required(ErrorMessage = "El Usuario es obligatorio")]
        public int UsuarioId { get; set; }

        [Required(ErrorMessage = "El Tipo de movimiento es obligatorio")]
        [RegularExpression("^(Entrada|Salida)$", ErrorMessage = "El Tipo debe ser 'Entrada' o 'Salida'")]
        public string TipoMovimiento { get; set; }

        [Required(ErrorMessage = "La Cantidad es obligatoria")]
        [Range(1, int.MaxValue, ErrorMessage = "La Cantidad debe ser al menos 1")]
        public int Cantidad { get; set; }

        [StringLength(200, ErrorMessage = "El Motivo no puede superar los 200 caracteres")]
        public string Motivo { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime Fecha { get; set; } = DateTime.Now;

        // Propiedades extra para capturar los JOINs en sp_Reporte_MovimientosPorRango
        public string ProductoNombre { get; set; }
        public string NombreUsuario { get; set; }
    }
}