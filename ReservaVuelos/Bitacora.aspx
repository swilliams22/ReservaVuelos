<%@ Page Title="Bitácora" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Bitacora.aspx.cs" Inherits="ReservaVuelos.Bitacora" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="ui.bitacora.004">Bitácora</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <div class="filter-row">
        <span runat="server" data-i18n="ui.bitacora.006">Fecha desde:</span> <asp:TextBox ID="txtDesde" runat="server" TextMode="Date"></asp:TextBox>
        <span runat="server" data-i18n="ui.bitacora.007">Fecha hasta:</span> <asp:TextBox ID="txtHasta" runat="server" TextMode="Date"></asp:TextBox>
        <span runat="server" data-i18n="ui.bitacora.010">Usuario:</span> <asp:TextBox ID="txtUsuarioFiltro" runat="server"></asp:TextBox>
        <span runat="server" data-i18n="ui.bitacora.008">Criticidad:</span> <asp:DropDownList ID="ddlCriticidad" runat="server">
            <asp:ListItem Value="" data-i18n="ui.bitacora.011">Todas</asp:ListItem>
            <asp:ListItem Value="1" data-i18n="ui.bitacora.012">1 - Información</asp:ListItem>
            <asp:ListItem Value="2" data-i18n="ui.bitacora.013">2 - Advertencia</asp:ListItem>
            <asp:ListItem Value="3" data-i18n="ui.bitacora.014">3 - Error</asp:ListItem>
            <asp:ListItem Value="4" data-i18n="ui.bitacora.015">4 - Crítica</asp:ListItem>
        </asp:DropDownList>
        <span runat="server" data-i18n="ui.bitacora.009">Pantalla:</span> <asp:TextBox ID="txtPantallaFiltro" runat="server"></asp:TextBox>
        <asp:Button ID="btnFiltrar" runat="server" Text="Filtrar" data-i18n="ui.bitacora.002" OnClick="btnFiltrar_Click" CssClass="btn-grid" />
        <asp:Button ID="btnLimpiar" runat="server" Text="Limpiar filtros" data-i18n="ui.bitacora.003" OnClick="btnLimpiar_Click" CssClass="btn-grid" />
    </div>

    <div style="margin:8px 0 12px 0; font-size:0.95em; color:#555;">
        <span runat="server" data-i18n="ui.bitacora.005">Leyenda de criticidad: 1 = Información, 2 = Advertencia, 3 = Error, 4 = Crítica.</span>
    </div>

    <asp:GridView DataKeyNames="Criticidad" ID="gvBitacora" runat="server" CssClass="grid" AutoGenerateColumns="false"
        AllowPaging="true" PageSize="20" OnPageIndexChanging="gvBitacora_PageIndexChanging" data-i18n-headers="ui.bitacora.016,ui.bitacora.017,ui.bitacora.018,ui.bitacora.019,ui.bitacora.020">
        <Columns>
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:BoundField DataField="Usuario" HeaderText="Usuario" />
            <asp:BoundField DataField="Accion" HeaderText="Acción" />
            <asp:BoundField DataField="CriticidadDescripcion" HeaderText="Criticidad" />
            <asp:BoundField DataField="Pantalla" HeaderText="Pantalla" />
        </Columns>
    </asp:GridView>
</asp:Content>

