<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="ReservaVuelos._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h2>Bienvenido al Sistema de Reserva de Vuelos</h2>
    <p>Esta aplicación académica permite buscar vuelos, registrarse, reservar y administrar vuelos según permisos.</p>
    <p>
        <asp:HyperLink runat="server" NavigateUrl="~/BuscarVuelos.aspx">Buscar vuelos</asp:HyperLink>
    </p>

</asp:Content>
