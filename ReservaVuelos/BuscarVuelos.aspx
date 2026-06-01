<%@ Page Title="Buscar vuelos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="BuscarVuelos.aspx.cs" Inherits="ReservaVuelos.BuscarVuelos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Buscar vuelos</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <div>
        <asp:Label runat="server" Text="Origen"></asp:Label>
        <asp:TextBox ID="txtOrigen" runat="server"></asp:TextBox>
        <asp:Label runat="server" Text="Destino"></asp:Label>
        <asp:TextBox ID="txtDestino" runat="server"></asp:TextBox>

        <asp:Label runat="server" Text="Tipo de viaje"></asp:Label>
        <asp:DropDownList ID="ddlTipoViaje" runat="server" onchange="toggleReturn();">
            <asp:ListItem Value="SoloIda" Selected="True">Solo ida</asp:ListItem>
            <asp:ListItem Value="IdaVuelta">Ida y vuelta</asp:ListItem>
        </asp:DropDownList>

        <asp:Label runat="server" Text="Fecha ida"></asp:Label>
        <asp:TextBox ID="txtFecha" runat="server" TextMode="Date"></asp:TextBox>

        <span id="spanVuelta" style="display:none;">
            <asp:Label runat="server" Text="Fecha vuelta"></asp:Label>
            <asp:TextBox ID="txtFechaVuelta" runat="server" TextMode="Date"></asp:TextBox>
        </span>

        <asp:Button ID="btnBuscar" runat="server" Text="Buscar" OnClick="btnBuscar_Click" OnClientClick="return validateDates();" />
    </div>

    <script type="text/javascript">
        function toggleReturn() {
            var ddl = document.getElementById('<%= ddlTipoViaje.ClientID %>');
            var span = document.getElementById('spanVuelta');
            if (!ddl || !span) return;
            if (ddl.value === 'IdaVuelta') span.style.display = 'inline-block'; else span.style.display = 'none';
        }

        function validateDates() {
            var fechaIda = document.getElementById('<%= txtFecha.ClientID %>');
            var fechaVuelta = document.getElementById('<%= txtFechaVuelta.ClientID %>');
            var lbl = document.getElementById('<%= lblMsg.ClientID %>');
            if (!fechaIda || !fechaVuelta || !lbl) return true;

            lbl.innerText = '';

            // Las fechas son opcionales. Solo se valida el orden cuando ambas fueron informadas.
            if (fechaIda.value && fechaVuelta.value) {
                var d1 = new Date(fechaIda.value);
                var d2 = new Date(fechaVuelta.value);
                if (d2 <= d1) {
                    lbl.style.color = 'red';
                    lbl.innerText = 'La fecha de vuelta debe ser posterior a la fecha de ida.';
                    return false;
                }
            }

            return true;
        }

        // asegurar estado inicial
        window.addEventListener ? window.addEventListener('load', toggleReturn) : window.onload = toggleReturn;
    </script>

    <p><strong>Aclaración:</strong> Las reservas se realizan por tramo. Para un viaje de ida y vuelta, reserve primero el vuelo de ida y luego el vuelo de vuelta.</p>

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
    <asp:Label runat="server" Text="Vuelos - Ida" Font-Bold="True" />
    <asp:GridView ID="gvVuelos" runat="server" CssClass="grid" AutoGenerateColumns="false" OnRowCommand="gvVuelos_RowCommand" DataKeyNames="IdVuelo">
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
                    <asp:Button runat="server" ID="btnReservar" CssClass="btn-grid" Text="Reservar" CommandName="Reservar" CommandArgument='<%# Eval("IdVuelo") %>' OnClientClick="return showConfirm('Confirma reservar este vuelo?', this);" />
                    <asp:Button runat="server" ID="btnVerVueltas" CssClass="btn-grid" Text="Ver vueltas" CommandName="VerVueltas" CommandArgument='<%# Eval("IdVuelo") %>' />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>

    <asp:Label runat="server" ID="lblVueltaTitle" Text="Vuelos - Vuelta" Font-Bold="True" Visible="false" />
    <asp:GridView ID="gvVuelosReturn" runat="server" CssClass="grid" AutoGenerateColumns="false" OnRowCommand="gvVuelos_RowCommand" DataKeyNames="IdVuelo" Visible="false">
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
                    <asp:Button runat="server" ID="btnReservarReturn" CssClass="btn-grid" Text="Reservar" CommandName="Reservar" CommandArgument='<%# Eval("IdVuelo") %>' OnClientClick="return showConfirm('Confirma reservar este vuelo?', this);" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
