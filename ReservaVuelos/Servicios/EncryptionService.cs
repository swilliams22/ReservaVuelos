using System;
using System.Configuration;
using System.Security.Cryptography;
using System.Text;

namespace ReservaVuelos.Servicios
{
    public class EncryptionService
    {
        private const string Prefix = "v1";
        private readonly byte[] _key;

        public EncryptionService()
        {
            var keyBase64 = ConfigurationManager.AppSettings["EncryptionKey"];
            if (string.IsNullOrWhiteSpace(keyBase64))
                throw new InvalidOperationException("Falta la clave de encriptación en Web.config (appSettings: EncryptionKey).");

            try
            {
                _key = Convert.FromBase64String(keyBase64);
            }
            catch (FormatException)
            {
                throw new InvalidOperationException("La clave de encriptación (EncryptionKey) no es Base64 válida.");
            }

            if (_key == null || (_key.Length != 16 && _key.Length != 24 && _key.Length != 32))
                throw new InvalidOperationException("La clave de encriptación (EncryptionKey) debe decodificar a 16, 24 o 32 bytes.");
        }

        public string Encrypt(string value)
        {
            if (value == null) return null;
            if (value.Length == 0) return string.Empty;

            using (var aes = Aes.Create())
            {
                aes.Key = _key;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;
                aes.GenerateIV();

                var plainBytes = Encoding.UTF8.GetBytes(value);
                using (var encryptor = aes.CreateEncryptor(aes.Key, aes.IV))
                {
                    var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);
                    return string.Format("{0}:{1}:{2}", Prefix, Convert.ToBase64String(aes.IV), Convert.ToBase64String(cipherBytes));
                }
            }
        }

        public string Decrypt(string value)
        {
            if (value == null) return null;
            if (value.Length == 0) return string.Empty;
            if (!value.StartsWith(Prefix + ":", StringComparison.Ordinal)) return value;

            var parts = value.Split(':');
            if (parts.Length != 3 || !string.Equals(parts[0], Prefix, StringComparison.Ordinal))
                throw new InvalidOperationException("El valor cifrado tiene un formato inválido.");

            byte[] iv;
            byte[] cipherBytes;
            try
            {
                iv = Convert.FromBase64String(parts[1]);
                cipherBytes = Convert.FromBase64String(parts[2]);
            }
            catch (FormatException)
            {
                throw new InvalidOperationException("El valor cifrado tiene contenido Base64 inválido.");
            }

            try
            {
                using (var aes = Aes.Create())
                {
                    aes.Key = _key;
                    aes.IV = iv;
                    aes.Mode = CipherMode.CBC;
                    aes.Padding = PaddingMode.PKCS7;

                    using (var decryptor = aes.CreateDecryptor(aes.Key, aes.IV))
                    {
                        var plainBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);
                        return Encoding.UTF8.GetString(plainBytes);
                    }
                }
            }
            catch (CryptographicException ex)
            {
                throw new InvalidOperationException("No se pudo desencriptar el valor sensible. El dato puede estar corrupto o la clave no coincide.", ex);
            }
        }
    }
}
