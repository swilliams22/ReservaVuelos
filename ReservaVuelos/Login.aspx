<%@ Page Title="Login" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="ReservaVuelos.Login" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="login.titulo">Login</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <div>
        <asp:Label runat="server" data-i18n="login.lbl.email" Text="Email" AssociatedControlID="txtEmail"></asp:Label><br />
        <asp:TextBox ID="txtEmail" runat="server"></asp:TextBox><br />
        <asp:Label runat="server" data-i18n="login.lbl.password" Text="Contrase&#241;a" AssociatedControlID="txtPassword"></asp:Label><br />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"></asp:TextBox>
        &nbsp;<input type="checkbox" id="chkShowPwd" onclick="(function(){var p=document.getElementById('<%= txtPassword.ClientID %>'); p.type = this.checked ? 'text' : 'password';}).call(this);" /> <span runat="server" data-i18n="login.chk.mostrarPassword">Mostrar Contrase&#241;a</span><br />
        <asp:Button ID="btnLogin" runat="server" data-i18n="login.btn.entrar" Text="Entrar" OnClick="btnLogin_Click" />
    </div>
</asp:Content>
