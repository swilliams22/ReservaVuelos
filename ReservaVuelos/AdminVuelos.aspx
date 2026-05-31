<%@ Page Title="Administración de vuelos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="AdminVuelos.aspx.cs" Inherits="ReservaVuelos.AdminVuelos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Administración de vuelos</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <h3>Crear vuelo</h3>
    <div>
        <asp:TextBox ID="txtOrigen" runat="server" Placeholder="Origen"></asp:TextBox>
        <asp:TextBox ID="txtDestino" runat="server" Placeholder="Destino"></asp:TextBox>
        <asp:TextBox ID="txtFecha" runat="server" TextMode="Date" Placeholder="yyyy-mm-dd"></asp:TextBox>
        <asp:TextBox ID="txtHora" runat="server" Placeholder="HH:mm"></asp:TextBox>
        <asp:TextBox ID="txtPrecio" runat="server" Placeholder="Precio"></asp:TextBox>
        <asp:TextBox ID="txtCupos" runat="server" Placeholder="Cupos"></asp:TextBox>
        <asp:Button ID="btnCrear" runat="server" Text="Crear" OnClick="btnCrear_Click" OnClientClick="return confirm('Confirma crear este vuelo?');" />
    </div>

    <h3>Filtro</h3>
    <asp:DropDownList ID="ddlFiltro" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlFiltro_SelectedIndexChanged">
        <asp:ListItem Value="Todos">Todos</asp:ListItem>
        <asp:ListItem Value="Activos" Selected="True">Activos</asp:ListItem>
        <asp:ListItem Value="Baja">Dados de baja</asp:ListItem>
    </asp:DropDownList>

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
    <h3>Vuelos</h3>
    <asp:GridView ID="gvVuelosAdmin" runat="server" AutoGenerateColumns="false" DataKeyNames="IdVuelo" OnRowCommand="gvVuelosAdmin_RowCommand">
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
                    <asp:Label runat="server" Text='<%# (Convert.ToBoolean(Eval("Activo")) ? "Activo" : "Dado de baja") %>' />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField>
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnBaja" Text="Baja" CommandName="Baja" CommandArgument='<%# Eval("IdVuelo") %>' OnClientClick="return confirm('Confirma dar de baja este vuelo?');" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
