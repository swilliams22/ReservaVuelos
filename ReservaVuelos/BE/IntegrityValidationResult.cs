using System.Collections.Generic;

namespace ReservaVuelos.BE
{
    public class IntegrityValidationResult
    {
        public IntegrityValidationResult()
        {
            Errors = new List<IntegridadError>();
        }

        public bool IsValid { get { return Errors.Count == 0; } }
        public string TableName { get; set; }
        public string ErrorType { get; set; }
        public string RecordId { get; set; }
        public string StoredValue { get; set; }
        public string CalculatedValue { get; set; }
        public string Message { get; set; }
        public List<IntegridadError> Errors { get; private set; }
    }
}
