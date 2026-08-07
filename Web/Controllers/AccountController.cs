using BLL.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Web.Models;
using Entities.Models;

namespace mi_inventario_plus_web.Controllers
{
    public class AccountController : Controller
    {
        private readonly UsuarioService _usuarioService = new UsuarioService(); [HttpGet]
        public ActionResult Login() => View();

        [HttpPost]
        public ActionResult Login(LoginViewModel model)
        {
            if (!ModelState.IsValid) return View(model);

            var usuario = _usuarioService.ValidarLogin(model.Correo, model.Contrasenia);
            if (usuario == null)
            {
                ModelState.AddModelError("", "Correo o contraseña incorrectos.");
                return View(model);
            }

            Session["UsuarioId"] = usuario.UsuarioId;
            Session["NombreUsuario"] = usuario.NombreUsuario;
            Session["Rol"] = usuario.Rol;

            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public ActionResult Register() => View();

        [HttpPost]
        public ActionResult Register(Usuario model)
        {
            if (!ModelState.IsValid) return View(model);

            var creado = _usuarioService.Registrar(model);
            if (!creado)
            {
                ModelState.AddModelError("", "Ese correo ya está registrado.");
                return View(model);
            }

            TempData["Mensaje"] = "Cuenta creada. Ya puedes iniciar sesión.";
            return RedirectToAction("Login");
        }

        public ActionResult Logout()
        {
            Session.Clear();
            return RedirectToAction("Login");
        }
    }
}