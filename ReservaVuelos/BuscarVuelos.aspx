<%@ Page Title="Buscar vuelos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="BuscarVuelos.aspx.cs" Inherits="ReservaVuelos.BuscarVuelos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Buscar vuelos</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <div>
        <asp:Label runat="server" Text="Origen"></asp:Label>
        <asp:TextBox ID="txtOrigen" runat="server"></asp:TextBox>
        <asp:Label runat="server" Text="Destino"></asp:Label>
        <asp:TextBox ID="txtDestino" runat="server"></asp:TextBox>
        <asp:Label runat="server" Text="Fecha (yyyy-mm-dd)"></asp:Label>
        <asp:TextBox ID="txtFecha" runat="server"></asp:TextBox>
        <asp:Button ID="btnBuscar" runat="server" Text="Buscar" OnClick="btnBuscar_Click" />
    </div>

    <!-- Datalist para sugerencias de ciudades -->
    <datalist id="listaCiudadesBusqueda">
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
    <br />
    <asp:GridView ID="gvVuelos" runat="server" AutoGenerateColumns="false" OnRowCommand="gvVuelos_RowCommand" DataKeyNames="IdVuelo">
        <Columns>
            <asp:BoundField DataField="IdVuelo" HeaderText="Id" />
            <asp:BoundField DataField="Origen" HeaderText="Origen" />
            <asp:BoundField DataField="Destino" HeaderText="Destino" />
            <asp:BoundField DataField="FechaSalida" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="HoraSalida" HeaderText="Hora" />
            <asp:BoundField DataField="Precio" HeaderText="Precio" DataFormatString="{0:C}" />
            <asp:BoundField DataField="CuposDisponibles" HeaderText="Cupos" />
            <asp:TemplateField>
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnReservar" Text="Reservar" CommandName="Reservar" CommandArgument='<%# Eval("IdVuelo") %>' OnClientClick="return confirm('Confirma reservar este vuelo?');" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
