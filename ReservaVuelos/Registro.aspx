<%@ Page Title="Registro" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Registro.aspx.cs" Inherits="ReservaVuelos.Registro" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="ui.registro.007">Registro</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <div>
        <asp:Label runat="server" Text="Nombre" data-i18n="ui.registro.002"></asp:Label><br />
        <asp:TextBox ID="txtNombre" runat="server"></asp:TextBox><br />
        <asp:Label runat="server" Text="Email" data-i18n="ui.registro.003"></asp:Label><br />
        <asp:TextBox ID="txtEmail" runat="server"></asp:TextBox><br />
        <asp:Label runat="server" Text="Contraseña" data-i18n="ui.registro.004"></asp:Label><br />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"></asp:TextBox>
        &nbsp;<input type="checkbox" id="chkShowPwdReg" onclick="(function(){var p=document.getElementById('<%= txtPassword.ClientID %>'); p.type = this.checked ? 'text' : 'password';}).call(this);" /> <span runat="server" data-i18n="ui.registro.008">Mostrar Contraseña</span><br />
        <asp:Button ID="btnRegister" runat="server" Text="Registrarme" data-i18n="ui.registro.005" OnClick="btnRegister_Click" OnClientClick="return showConfirm('Confirma crear este usuario?', this);" data-i18n-confirm="ui.registro.006" />
    </div>
</asp:Content>

