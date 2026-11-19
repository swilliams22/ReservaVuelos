<%@ Page Title="Acerca de" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="About.aspx.cs" Inherits="ReservaVuelos.About" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main aria-labelledby="title">
        <h2 id="title" runat="server" data-i18n="ui.about.002">Acerca de</h2>
        <h3 runat="server" data-i18n="ui.about.003">Descripción de la aplicación.</h3>
        <p runat="server" data-i18n="ui.about.004">Sistema académico para buscar vuelos y gestionar reservas.</p>
    </main>
</asp:Content>
