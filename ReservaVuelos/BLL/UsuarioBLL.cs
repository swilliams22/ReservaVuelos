using ReservaVuelos.BE;
using ReservaVuelos.DAL;

namespace ReservaVuelos.BLL
{
    public class UsuarioBLL
    {
        private UsuarioDAL _dal = new UsuarioDAL();

        public Usuario GetByEmail(string email) => _dal.GetByEmail(email);

        public int Create(Usuario u) => _dal.Create(u);
    }
}
