using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace Entities.Models
{
    public class Producto
    {
        public int ProductoId { get; set; }

        [Required(ErrorMessage = "El nombre del producto es obligatorio")]
        [StringLength(150, ErrorMessage = "El Nombre no puede superar los 150 caracteres")]
        public string NombreProducto { get; set; }

        [StringLength(500, ErrorMessage = "La descripción no puede superar los 500 caracteres")]
        public string DescripcionProducto { get; set; }

        [Required(ErrorMessage = "El precio es obligatorio")]
        [Range(0.01, 99999999.99, ErrorMessage = "El Precio debe ser un valor positivo mayor a 0")]
        public decimal Precio { get; set; }

        [Required(ErrorMessage = "El stock es obligatorio")]
        [Range(0, int.MaxValue, ErrorMessage = "El Stock no puede ser un número negativo")]
        public int Stock { get; set; }

        [Required(ErrorMessage = "La categoría es obligatoria")]
        [Range(1, int.MaxValue, ErrorMessage = "Debe seleccionar una Categoría válida")]
        public int CategoriaId { get; set; }

        [StringLength(300, ErrorMessage = "La URL de la imagen no puede superar los 300 caracteres")]
        [DataType(DataType.ImageUrl)]
        public string ImagenUrl { get; set; }

        public bool Activo { get; set; } = true;

        [DataType(DataType.DateTime)]
        public DateTime FechaCreacion { get; set; } = DateTime.Now;

        // Propiedad extra para capturar el INNER JOIN en sp_Producto_ListarPaginado
        public string CategoriaNombre { get; set; }

    }
}