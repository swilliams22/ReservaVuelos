using System;
using System.Security.Cryptography;

namespace ReservaVuelos.Servicios
{
    public static class HashService
    {
        // PBKDF2
        public static void CreateHash(string password, out string passwordHash, out string passwordSalt)
        {
            // salt
            byte[] salt = new byte[16];
            using (var rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(salt);
            }
            // derive
            using (var derive = new Rfc2898DeriveBytes(password, salt, 10000))
            {
                var key = derive.GetBytes(32);
                passwordSalt = Convert.ToBase64String(salt);
                passwordHash = Convert.ToBase64String(key);
            }
        }

        public static bool VerifyPassword(string password, string storedHash, string storedSalt)
        {
            var salt = Convert.FromBase64String(storedSalt);
            using (var derive = new Rfc2898DeriveBytes(password, salt, 10000))
            {
                var key = derive.GetBytes(32);
                var keyBase64 = Convert.ToBase64String(key);
                return keyBase64 == storedHash;
            }
        }
    }
}
