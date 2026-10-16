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
            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                rng.GetBytes(salt);
            }
            // derive
            using (Rfc2898DeriveBytes derive = new Rfc2898DeriveBytes(password, salt, 10000))
            {
                byte[] key = derive.GetBytes(32);
                passwordSalt = Convert.ToBase64String(salt);
                passwordHash = Convert.ToBase64String(key);
            }
        }

        public static bool VerifyPassword(string password, string storedHash, string storedSalt)
        {
            byte[] salt = Convert.FromBase64String(storedSalt);
            using (Rfc2898DeriveBytes derive = new Rfc2898DeriveBytes(password, salt, 10000))
            {
                byte[] key = derive.GetBytes(32);
                string keyBase64 = Convert.ToBase64String(key);
                return keyBase64 == storedHash;
            }
        }
    }
}
