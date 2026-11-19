<%@ Page Title="Gestión de usuarios" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="GestionUsuarios.aspx.cs" Inherits="ReservaVuelos.GestionUsuarios" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="usuarios.titulo">Gestión de usuarios</h2>
    <p style="color:#555;" runat="server" data-i18n="usuarios.ayuda">Elija el perfil de cada usuario. El cambio se aplica en su próxima acción, sin cerrar su sesión. No puede cambiar su propio perfil.</p>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <asp:GridView ID="gvUsuarios" runat="server" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="IdUsuario"
        OnRowDataBound="gvUsuarios_RowDataBound" OnRowCommand="gvUsuarios_RowCommand"
        data-i18n-headers="usuarios.col.nombre,usuarios.col.email,usuarios.col.estado,usuarios.col.rol,usuarios.col.acciones">
        <Columns>
            <asp:BoundField DataField="Nombre" HeaderText="Nombre" />
            <asp:BoundField DataField="Email" HeaderText="Email" />
            <asp:TemplateField HeaderText="Estado">
                <ItemTemplate>
                    <asp:Label ID="lblEstado" runat="server"></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Perfil">
                <ItemTemplate>
                    <asp:Label ID="lblRol" runat="server"></asp:Label>
                    <asp:DropDownList ID="ddlRol" runat="server"></asp:DropDownList>
                    <asp:Label ID="lblUsted" runat="server" data-i18n="usuarios.usted" Text="(usted)" Visible="false"></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Acciones">
                <ItemTemplate>
                    <asp:Button ID="btnAsignar" runat="server" Text="Asignar" data-i18n="usuarios.btn.asignar" CommandName="Asignar" CssClass="btn-grid" CausesValidation="false" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
