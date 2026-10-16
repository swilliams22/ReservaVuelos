using System;
using System.Collections.Generic;
using System.Linq;

namespace ReservaVuelos.BE
{
    public abstract class PermisoComponente
    {
        public string Codigo { get; private set; }
        protected PermisoComponente(string codigo)
        {
            if (string.IsNullOrWhiteSpace(codigo)) throw new ArgumentException("Código requerido.");
            Codigo = codigo;
        }
        public abstract bool TienePermiso(string codigo);
    }

    public sealed class PermisoSimple : PermisoComponente
    {
        public PermisoSimple(string codigo) : base(codigo) { }
        public override bool TienePermiso(string codigo)
        {
            return string.Equals(Codigo, codigo, StringComparison.OrdinalIgnoreCase);
        }
    }

    public sealed class GrupoPermisos : PermisoComponente
    {
        private readonly List<PermisoComponente> hijos = new List<PermisoComponente>();
        public IEnumerable<PermisoComponente> Hijos { get { return hijos.AsReadOnly(); } }
        public GrupoPermisos(string codigo) : base(codigo) { }
        public void Agregar(PermisoComponente componente)
        {
            if (componente == null) throw new ArgumentNullException("componente");
            if (Contiene(componente, this)) throw new InvalidOperationException("El árbol de permisos contiene un ciclo.");
            if (!hijos.Contains(componente)) hijos.Add(componente);
        }
        private static bool Contiene(PermisoComponente nodo, PermisoComponente buscado)
        {
            if (ReferenceEquals(nodo, buscado)) return true;
            GrupoPermisos grupo = nodo as GrupoPermisos;
            return grupo != null && grupo.hijos.Any(h => Contiene(h, buscado));
        }
        public override bool TienePermiso(string codigo)
        {
            // Un nombre de grupo no concede permisos: sólo las hojas lo hacen.
            return hijos.Any(h => h.TienePermiso(codigo));
        }
    }
}
