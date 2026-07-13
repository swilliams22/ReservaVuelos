<%@ Page Title="Bitácora" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Bitacora.aspx.cs" Inherits="ReservaVuelos.Bitacora" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Bitácora</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <div class="filter-row">
        Fecha desde: <asp:TextBox ID="txtDesde" runat="server" TextMode="Date"></asp:TextBox>
        Fecha hasta: <asp:TextBox ID="txtHasta" runat="server" TextMode="Date"></asp:TextBox>
        Usuario: <asp:TextBox ID="txtUsuarioFiltro" runat="server"></asp:TextBox>
        Criticidad: <asp:DropDownList ID="ddlCriticidad" runat="server">
            <asp:ListItem Value="">Todas</asp:ListItem>
            <asp:ListItem Value="1">1 - Información</asp:ListItem>
            <asp:ListItem Value="2">2 - Advertencia</asp:ListItem>
            <asp:ListItem Value="3">3 - Error</asp:ListItem>
            <asp:ListItem Value="4">4 - Crítica</asp:ListItem>
        </asp:DropDownList>
        Pantalla: <asp:TextBox ID="txtPantallaFiltro" runat="server"></asp:TextBox>
        <asp:Button ID="btnFiltrar" runat="server" Text="Filtrar" OnClick="btnFiltrar_Click" CssClass="btn-grid" />
        <asp:Button ID="btnLimpiar" runat="server" Text="Limpiar filtros" OnClick="btnLimpiar_Click" CssClass="btn-grid" />
    </div>

    <div style="margin:8px 0 12px 0; font-size:0.95em; color:#555;">
        Leyenda de criticidad: 1 = Información, 2 = Advertencia, 3 = Error, 4 = Crítica.
    </div>

    <asp:GridView ID="gvBitacora" runat="server" CssClass="grid" AutoGenerateColumns="false">
        <Columns>
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:BoundField DataField="Usuario" HeaderText="Usuario" />
            <asp:BoundField DataField="Accion" HeaderText="Acción" />
            <asp:BoundField DataField="CriticidadDescripcion" HeaderText="Criticidad" />
            <asp:BoundField DataField="Pantalla" HeaderText="Pantalla" />
        </Columns>
    </asp:GridView>
</asp:Content>

