<%@ Page Title="Administración de vuelos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="AdminVuelos.aspx.cs" Inherits="ReservaVuelos.AdminVuelos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="ui.adminvuelos.012">Administración de vuelos</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <h3 runat="server" data-i18n="ui.adminvuelos.013">Crear vuelo</h3>
    <div>
        <asp:TextBox ID="txtOrigen" runat="server" Placeholder="Origen" data-i18n-placeholder="ui.adminvuelos.002"></asp:TextBox>
        <asp:TextBox ID="txtDestino" runat="server" Placeholder="Destino" data-i18n-placeholder="ui.adminvuelos.003"></asp:TextBox>
        <asp:TextBox ID="txtFecha" runat="server" TextMode="Date" Placeholder="yyyy-mm-dd"></asp:TextBox>
        <asp:TextBox ID="txtHora" runat="server" Placeholder="HH:mm"></asp:TextBox>
        <asp:TextBox ID="txtPrecio" runat="server" Placeholder="Precio" data-i18n-placeholder="ui.adminvuelos.004"></asp:TextBox>
        <asp:TextBox ID="txtCupos" runat="server" Placeholder="Cupos" data-i18n-placeholder="ui.adminvuelos.005"></asp:TextBox>
        <asp:Button ID="btnCrear" runat="server" Text="Crear" data-i18n="ui.adminvuelos.006" OnClick="btnCrear_Click" OnClientClick="return showConfirm('Confirma crear este vuelo?', this);" data-i18n-confirm="ui.adminvuelos.007" />
    </div>

    <h3 runat="server" data-i18n="ui.adminvuelos.014">Filtro</h3>
    <asp:DropDownList ID="ddlFiltro" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlFiltro_SelectedIndexChanged">
        <asp:ListItem Value="Todos" data-i18n="ui.adminvuelos.016">Todos</asp:ListItem>
        <asp:ListItem Value="Activos" Selected="True" data-i18n="ui.adminvuelos.017">Activos</asp:ListItem>
        <asp:ListItem Value="Baja" data-i18n="ui.adminvuelos.018">Dados de baja</asp:ListItem>
    </asp:DropDownList>

    <h3>XML</h3>
    <div class="filter-row">
        <asp:Button ID="btnExportar" runat="server" Text="Exportar vuelos a XML" data-i18n="ui.adminvuelos.008" OnClick="btnExportar_Click" CssClass="btn-grid" CausesValidation="false" />
        (exporta los vuelos según el filtro elegido)
    </div>
    <div class="filter-row">
        <asp:FileUpload ID="fuXml" runat="server" accept=".xml" />
        <asp:Button ID="btnImportar" runat="server" Text="Importar vuelos desde XML" data-i18n="ui.adminvuelos.009" OnClick="btnImportar_Click" CssClass="btn-grid" OnClientClick="return showConfirm('Confirma importar los vuelos del archivo XML?', this);" data-i18n-confirm="ui.adminvuelos.010" />
    </div>
    <asp:Label ID="lblXmlResultado" runat="server"></asp:Label>

    <!-- Datalists para sugerencias de origen/destino -->
    <datalist id="listaCiudades">
        <option value="Buenos Aires"></option>
        <option value="Córdoba"></option>
        <option value="Mendoza"></option>
        <option value="Rosario"></option>
        <option value="Bariloche"></option>
        <option value="Salta"></option>
        <option value="Ushuaia"></option>
        <option value="Iguazú"></option>
        <option value="Neuquén"></option>
        <option value="Mar del Plata"></option>
        <option value="Tucumán"></option>
        <option value="Jujuy"></option>
        <option value="San Juan"></option>
        <option value="San Luis"></option>
        <option value="Santa Fe"></option>
        <option value="La Plata"></option>
        <option value="Asunción"></option>
        <option value="Santiago de Chile"></option>
        <option value="Montevideo"></option>
        <option value="Río de Janeiro"></option>
        <option value="Madrid"></option>
        <option value="Miami"></option>
    </datalist>
    <h3 runat="server" data-i18n="ui.adminvuelos.015">Vuelos</h3>
    <div class="filter-row">
        <asp:Label runat="server" AssociatedControlID="txtFiltrogvVuelosAdmin" Text="Buscar en la tabla" data-i18n="grillas.buscar" />
        <asp:TextBox ID="txtFiltrogvVuelosAdmin" runat="server" MaxLength="150" />
        <asp:Button runat="server" Text="Filtrar" data-i18n="grillas.filtrar" OnClick="FiltrargvVuelosAdmin" CommandArgument="aplicar" CausesValidation="false" CssClass="btn-grid" />
        <asp:Button runat="server" Text="Limpiar" data-i18n="grillas.limpiar" OnClick="FiltrargvVuelosAdmin" CommandArgument="limpiar" CausesValidation="false" CssClass="btn-grid" />
    </div>
    <asp:GridView ID="gvVuelosAdmin" runat="server" AllowPaging="true" PageSize="20" OnPageIndexChanging="gvVuelosAdmin_PageIndexChanging" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="IdVuelo" OnRowCommand="gvVuelosAdmin_RowCommand" data-i18n-headers="ui.adminvuelos.019,ui.adminvuelos.020,ui.adminvuelos.021,ui.adminvuelos.022,ui.adminvuelos.023,ui.adminvuelos.024,ui.adminvuelos.025,ui.adminvuelos.026,">
        <Columns>
            <asp:BoundField DataField="IdVuelo" HeaderText="Id" />
            <asp:BoundField DataField="Origen" HeaderText="Origen" />
            <asp:BoundField DataField="Destino" HeaderText="Destino" />
            <asp:BoundField DataField="FechaSalida" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="HoraSalida" HeaderText="Hora" />
            <asp:BoundField DataField="Precio" HeaderText="Precio" DataFormatString="{0:C}" />
            <asp:BoundField DataField="CuposDisponibles" HeaderText="Cupos" />
            <asp:TemplateField HeaderText="Estado">
                <ItemTemplate>
                    <asp:Label runat="server" data-i18n='<%# Convert.ToBoolean(Eval("Activo")) ? "ui.vuelos.estado.activo" : "ui.vuelos.estado.baja" %>' Text='<%# (Convert.ToBoolean(Eval("Activo")) ? "Activo" : "Dado de baja") %>' />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField>
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnBaja" CssClass="btn-grid" Text="Baja" data-i18n="ui.adminvuelos.011" CommandName="Baja" CommandArgument='<%# Eval("IdVuelo") %>' Visible='<%# ReservaVuelos.Servicios.AutorizacionService.TienePermiso(ReservaVuelos.Servicios.SesionService.GetUser(), ReservaVuelos.Servicios.Permisos.BajaVuelo) %>' OnClientClick="return showConfirm('Confirma dar de baja este vuelo?', this);" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>

