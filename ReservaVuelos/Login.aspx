<%@ Page Title="Login" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="ReservaVuelos.Login" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Login</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <div>
        <asp:Label runat="server" Text="Email" AssociatedControlID="txtEmail"></asp:Label><br />
        <asp:TextBox ID="txtEmail" runat="server"></asp:TextBox><br />
        <asp:Label runat="server" Text="Contraseña" AssociatedControlID="txtPassword"></asp:Label><br />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"></asp:TextBox>
        &nbsp;<input type="checkbox" id="chkShowPwd" onclick="(function(){var p=document.getElementById('<%= txtPassword.ClientID %>'); p.type = this.checked ? 'text' : 'password';}).call(this);" /> Mostrar contraseña<br />
        <asp:Button ID="btnLogin" runat="server" Text="Entrar" OnClick="btnLogin_Click" />
    </div>
</asp:Content>
