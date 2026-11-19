<%@ Page Title="Proximamente" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="EnConstruccion.aspx.cs" Inherits="ReservaVuelos.EnConstruccion" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="hero-banner">
        <h1><span runat="server" data-i18n="ui.enconstruccion.006">VOLA EN CUOTAS</span> <span class="hero-sep">|</span> <span class="hero-accent" runat="server" data-i18n="ui.enconstruccion.002">POR ARGENTINA</span></h1>
    </div>

    <div class="search-card en-construccion">
        <div class="en-construccion-icon">&#128736;</div>
        <h2 runat="server" data-i18n="ui.enconstruccion.003">Página en construcción</h2>
        <p runat="server" data-i18n="ui.enconstruccion.004">Esta sección todavía no está disponible. Estamos trabajando para tenerla lista pronto.</p>
        <a href="BuscarVuelos.aspx" class="btn-buscar" runat="server" data-i18n="ui.enconstruccion.005">VOLVER A BUSCAR VUELOS</a>
    </div>

</asp:Content>
