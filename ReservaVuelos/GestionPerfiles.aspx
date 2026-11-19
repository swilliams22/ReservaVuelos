<%@ Page Title="Gestión de perfiles" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="GestionPerfiles.aspx.cs" Inherits="ReservaVuelos.GestionPerfiles" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="perfiles.titulo">Gestión de perfiles</h2>
    <p style="color:#555;" runat="server" data-i18n="perfiles.ayuda">Un perfil agrupa permisos. A un perfil se le pueden asignar permisos simples y otros perfiles. Los permisos simples están definidos por el sistema y no se crean desde esta pantalla.</p>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <asp:Panel ID="pnlNuevo" runat="server">
        <h4 runat="server" data-i18n="perfiles.nuevo.titulo">Nuevo perfil</h4>
        <div class="filter-row">
            <asp:Label runat="server" AssociatedControlID="txtNombre" data-i18n="perfiles.lbl.nombre" Text="Nombre (hasta 30 caracteres)"></asp:Label>
            <asp:TextBox ID="txtNombre" runat="server" MaxLength="30"></asp:TextBox>
            <asp:Button ID="btnCrear" runat="server" Text="Crear perfil" data-i18n="perfiles.btn.crear" OnClick="btnCrear_Click" CssClass="btn-grid" />
        </div>
    </asp:Panel>

    <h4 runat="server" data-i18n="perfiles.lista.titulo">Perfiles</h4>
    <asp:GridView ID="gvPerfiles" runat="server" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="IdPermiso"
        OnRowDataBound="gvPerfiles_RowDataBound" OnRowCommand="gvPerfiles_RowCommand"
        data-i18n-headers="perfiles.col.nombre,perfiles.col.usuarios,perfiles.col.acciones">
        <Columns>
            <asp:BoundField DataField="Codigo" HeaderText="Nombre" />
            <asp:BoundField DataField="CantidadUsuarios" HeaderText="Usuarios asignados" />
            <asp:TemplateField HeaderText="Acciones">
                <ItemTemplate>
                    <asp:Button ID="btnVer" runat="server" Text="Ver / editar" data-i18n="perfiles.btn.ver" CommandName="Ver" CssClass="btn-grid" CausesValidation="false" />
                    <asp:Button ID="btnEliminar" runat="server" Text="Eliminar" data-i18n="perfiles.btn.eliminar" CommandName="Eliminar" CssClass="btn-grid" CausesValidation="false" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>

    <asp:Panel ID="pnlDetalle" runat="server" Visible="false" Style="margin-top:24px;">
        <asp:HiddenField ID="hfIdPerfil" runat="server" />
        <h4><span runat="server" data-i18n="perfiles.detalle.titulo">Perfil:</span> <asp:Label ID="lblPerfil" runat="server" Font-Bold="true"></asp:Label></h4>

        <div class="row">
            <div class="col-md-5">
                <h5 runat="server" data-i18n="perfiles.arbol.titulo">Permisos efectivos (árbol completo)</h5>
                <asp:TreeView ID="tvArbol" runat="server" ShowLines="true" EnableViewState="false"></asp:TreeView>
            </div>
            <div class="col-md-7">
                <h5 runat="server" data-i18n="perfiles.asignados.titulo">Asignados directamente</h5>
                <asp:GridView ID="gvAsignados" runat="server" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="IdPermiso"
                    OnRowDataBound="gvAsignados_RowDataBound" OnRowCommand="gvAsignados_RowCommand"
                    data-i18n-headers="perfiles.col.permiso,perfiles.col.tipo,perfiles.col.acciones">
                    <Columns>
                        <asp:BoundField DataField="Codigo" HeaderText="Permiso" />
                        <asp:TemplateField HeaderText="Tipo">
                            <ItemTemplate>
                                <asp:Label ID="lblTipo" runat="server"></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Acciones">
                            <ItemTemplate>
                                <asp:Button ID="btnQuitar" runat="server" Text="Quitar" data-i18n="perfiles.btn.quitar" CommandName="Quitar" CssClass="btn-grid" CausesValidation="false" />
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>

                <asp:Panel ID="pnlAgregar" runat="server" Style="margin-top:12px;">
                    <h5 runat="server" data-i18n="perfiles.agregar.titulo">Agregar permiso o perfil</h5>
                    <div class="filter-row">
                        <asp:DropDownList ID="ddlDisponibles" runat="server"></asp:DropDownList>
                        <asp:Button ID="btnAgregar" runat="server" Text="Agregar" data-i18n="perfiles.btn.agregar" OnClick="btnAgregar_Click" CssClass="btn-grid" CausesValidation="false" />
                    </div>
                </asp:Panel>
            </div>
        </div>

        <div style="margin-top:12px;">
            <asp:Button ID="btnCerrar" runat="server" Text="Cerrar" data-i18n="perfiles.btn.cerrar" OnClick="btnCerrar_Click" CssClass="btn-grid" CausesValidation="false" />
        </div>
    </asp:Panel>
</asp:Content>
