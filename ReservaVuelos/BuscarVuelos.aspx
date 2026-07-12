<%@ Page Title="Buscar vuelos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="BuscarVuelos.aspx.cs" Inherits="ReservaVuelos.BuscarVuelos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="hero-banner">
        <h1>VOLA EN CUOTAS <span class="hero-sep">|</span> <span class="hero-accent">POR ARGENTINA</span></h1>
    </div>

    <div class="search-card">
        <nav class="search-tabs">
            <a href="BuscarVuelos.aspx" class="active">&#9992; VUELOS</a>
            <a href="EnConstruccion.aspx">CHECK-IN</a>
            <a href="EnConstruccion.aspx">ESTADO DE VUELO</a>
            <a href="MisReservas.aspx">MI RESERVA</a>
        </nav>

        <asp:Label ID="lblMsg" runat="server" CssClass="search-msg" ForeColor="Red"></asp:Label>

        <div class="trip-type">
            <label>
                <asp:RadioButton ID="rbIda" runat="server" GroupName="TipoViaje" Text="Ida" onclick="toggleReturn();" />
            </label>
            <label>
                <asp:RadioButton ID="rbIdaVuelta" runat="server" GroupName="TipoViaje" Text="Ida y vuelta" Checked="True" onclick="toggleReturn();" />
            </label>
            <label class="trip-type-disabled" title="Proximamente">
                <input type="radio" disabled="disabled" /> Multidestino
            </label>
        </div>

        <div class="search-fields">
            <div class="search-field">
                <label for="<%= txtOrigen.ClientID %>">Origen</label>
                <asp:TextBox ID="txtOrigen" runat="server" placeholder="Ciudad de origen"></asp:TextBox>
            </div>

            <button type="button" class="swap-btn" onclick="swapOrigenDestino(); return false;" title="Intercambiar origen y destino">&#8646;</button>

            <div class="search-field">
                <label for="<%= txtDestino.ClientID %>">Destino</label>
                <asp:TextBox ID="txtDestino" runat="server" placeholder="Ciudad de destino"></asp:TextBox>
            </div>

            <div class="search-field">
                <label for="<%= txtFecha.ClientID %>">Salida</label>
                <asp:TextBox ID="txtFecha" runat="server" TextMode="Date"></asp:TextBox>
            </div>

            <span id="spanVuelta" class="search-field" style="display:none;">
                <label for="<%= txtFechaVuelta.ClientID %>">Regreso</label>
                <asp:TextBox ID="txtFechaVuelta" runat="server" TextMode="Date"></asp:TextBox>
            </span>
        </div>

        <div class="search-actions">
            <asp:Button ID="btnBuscar" runat="server" CssClass="btn-buscar" Text="BUSCAR VUELOS" OnClick="btnBuscar_Click" OnClientClick="return validateDates();" />
        </div>
    </div>

    <script type="text/javascript">
        function toggleReturn() {
            var rbIdaVuelta = document.getElementById('<%= rbIdaVuelta.ClientID %>');
            var span = document.getElementById('spanVuelta');
            if (!rbIdaVuelta || !span) return;
            if (rbIdaVuelta.checked) span.style.display = 'inline-flex'; else span.style.display = 'none';
        }

        function swapOrigenDestino() {
            var o = document.getElementById('<%= txtOrigen.ClientID %>');
            var d = document.getElementById('<%= txtDestino.ClientID %>');
            if (!o || !d) return;
            var tmp = o.value;
            o.value = d.value;
            d.value = tmp;
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
