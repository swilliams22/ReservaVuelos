<%@ Page Title="Registro" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Registro.aspx.cs" Inherits="ReservaVuelos.Registro" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Registro</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <div>
        <asp:Label runat="server" Text="Nombre"></asp:Label><br />
        <asp:TextBox ID="txtNombre" runat="server"></asp:TextBox><br />
        <asp:Label runat="server" Text="Email"></asp:Label><br />
        <asp:TextBox ID="txtEmail" runat="server"></asp:TextBox><br />
        <asp:Label runat="server" Text="Contraseña"></asp:Label><br />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"></asp:TextBox><br />
        <asp:Button ID="btnRegister" runat="server" Text="Registrarme" OnClick="btnRegister_Click" OnClientClick="return confirm('Confirma crear este usuario?');" />
    </div>
</asp:Content>
