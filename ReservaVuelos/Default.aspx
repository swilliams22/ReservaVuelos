<%@ Page Title="Inicio" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="ReservaVuelos._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h2 runat="server" data-i18n="ui.default.002">Bienvenido al Sistema de Reserva de Vuelos</h2>
    <p runat="server" data-i18n="ui.default.003">Esta aplicación académica permite buscar vuelos, registrarse, reservar y administrar vuelos según permisos.</p>
    <p>
        <asp:HyperLink runat="server" NavigateUrl="~/BuscarVuelos.aspx" data-i18n="ui.default.004">Buscar vuelos</asp:HyperLink>
    </p>

</asp:Content>
