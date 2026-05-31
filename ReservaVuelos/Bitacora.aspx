<%@ Page Title="Bitácora" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Bitacora.aspx.cs" Inherits="ReservaVuelos.Bitacora" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Bitácora</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <div class="filter-row">
        Fecha desde: <asp:TextBox ID="txtDesde" runat="server" TextMode="Date"></asp:TextBox>
        Fecha hasta: <asp:TextBox ID="txtHasta" runat="server" TextMode="Date"></asp:TextBox>
        Usuario: <asp:TextBox ID="txtUsuarioFiltro" runat="server"></asp:TextBox>
        Criticidad: <asp:DropDownList ID="ddlCriticidad" runat="server">
            <asp:ListItem Value="Todos">Todas</asp:ListItem>
            <asp:ListItem Value="Info">Info</asp:ListItem>
            <asp:ListItem Value="Advertencia">Advertencia</asp:ListItem>
            <asp:ListItem Value="Error">Error</asp:ListItem>
            <asp:ListItem Value="Critico">Critico</asp:ListItem>
        </asp:DropDownList>
        Pantalla: <asp:TextBox ID="txtPantallaFiltro" runat="server"></asp:TextBox>
        <asp:Button ID="btnFiltrar" runat="server" Text="Filtrar" OnClick="btnFiltrar_Click" CssClass="btn-grid" />
        <asp:Button ID="btnLimpiar" runat="server" Text="Limpiar filtros" OnClick="btnLimpiar_Click" CssClass="btn-grid" />
    </div>

    <asp:GridView ID="gvBitacora" runat="server" CssClass="grid" AutoGenerateColumns="false">
        <Columns>
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:BoundField DataField="Usuario" HeaderText="Usuario" />
            <asp:BoundField DataField="Accion" HeaderText="Acción" />
            <asp:BoundField DataField="Criticidad" HeaderText="Criticidad" />
            <asp:BoundField DataField="Pantalla" HeaderText="Pantalla" />
        </Columns>
    </asp:GridView>
</asp:Content>
