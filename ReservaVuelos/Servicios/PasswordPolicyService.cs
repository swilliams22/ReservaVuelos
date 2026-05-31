using System.Text.RegularExpressions;

namespace ReservaVuelos.Servicios
{
    public static class PasswordPolicyService
    {
        public static bool Validate(string password, out string message)
        {
            message = string.Empty;
            if (string.IsNullOrEmpty(password) || password.Length < 8)
            {
                message = "La contraseña debe tener al menos 8 caracteres.";
                return false;
            }
            if (!Regex.IsMatch(password, "[A-Z]"))
            {
                message = "La contraseña debe contener al menos una letra mayúscula.";
                return false;
            }
            if (!Regex.IsMatch(password, "[a-z]"))
            {
                message = "La contraseña debe contener al menos una letra minúscula.";
                return false;
            }
            if (!Regex.IsMatch(password, "[0-9]"))
            {
                message = "La contraseña debe contener al menos un número.";
                return false;
            }
            if (!Regex.IsMatch(password, "[^a-zA-Z0-9]"))
            {
                message = "La contraseña debe contener al menos un carácter especial.";
                return false;
            }
            return true;
        }
    }
}
