<%@ Page Title="Bitácora" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Bitacora.aspx.cs" Inherits="ReservaVuelos.Bitacora" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Bitácora</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <asp:GridView ID="gvBitacora" runat="server" AutoGenerateColumns="false">
        <Columns>
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:BoundField DataField="Usuario" HeaderText="Usuario" />
            <asp:BoundField DataField="Accion" HeaderText="Acción" />
            <asp:BoundField DataField="Criticidad" HeaderText="Criticidad" />
            <asp:BoundField DataField="Pantalla" HeaderText="Pantalla" />
        </Columns>
    </asp:GridView>
</asp:Content>
