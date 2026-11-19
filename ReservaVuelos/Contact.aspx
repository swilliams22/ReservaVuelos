<%@ Page Title="Contacto" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Contact.aspx.cs" Inherits="ReservaVuelos.Contact" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main aria-labelledby="title">
        <h2 id="title" runat="server" data-i18n="ui.contact.002">Contacto</h2>
        <h3 runat="server" data-i18n="ui.contact.003">Información de contacto.</h3>
        <address>
            One Microsoft Way<br />
            Redmond, WA 98052-6399<br />
            <abbr title="Phone">P:</abbr>
            425.555.0100
        </address>

        <address>
            <strong runat="server" data-i18n="ui.contact.004">Soporte:</strong>   <a href="mailto:Support@example.com">Support@example.com</a><br />
            <strong runat="server" data-i18n="ui.contact.005">Marketing:</strong> <a href="mailto:Marketing@example.com">Marketing@example.com</a>
        </address>
    </main>
</asp:Content>
