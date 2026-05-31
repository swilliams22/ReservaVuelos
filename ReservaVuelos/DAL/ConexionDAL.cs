using System.Configuration;
using System.Data.SqlClient;

namespace ReservaVuelos.DAL
{
    public static class ConexionDAL
    {
        public static SqlConnection GetConnection()
        {
            var cs = ConfigurationManager.ConnectionStrings["ReservaVuelosConnectionString"]?.ConnectionString;
            return new SqlConnection(cs);
        }
    }
}
