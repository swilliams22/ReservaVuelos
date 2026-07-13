<%@ Page Title="Detalle de Reserva" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="DetalleReserva.aspx.cs" Inherits="ReservaVuelos.DetalleReserva" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Confirmar Reserva</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <div class="reservation-section">
        <h3>Vuelos seleccionados</h3>
        <asp:GridView ID="gvVuelosSeleccionados" runat="server" CssClass="grid" AutoGenerateColumns="false">
            <Columns>
                <asp:BoundField DataField="Origen" HeaderText="Origen" />
                <asp:BoundField DataField="Destino" HeaderText="Destino" />
                <asp:BoundField DataField="FechaSalida" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd}" />
                <asp:BoundField DataField="HoraSalida" HeaderText="Hora" />
                <asp:BoundField DataField="Precio" HeaderText="Precio" DataFormatString="{0:C}" />
            </Columns>
        </asp:GridView>
    </div>

    <div class="reservation-section">
        <h3>Datos del titular de la reserva</h3>
        <p><strong>Nombre:</strong> <asp:Label ID="lblNombreCliente" runat="server"></asp:Label></p>
        <p><strong>Email:</strong> <asp:Label ID="lblEmailCliente" runat="server"></asp:Label></p>
        <div class="form-group">
            <label for="<%= txtDocumentoCliente.ClientID %>">Documento (opcional):</label>
            <asp:TextBox ID="txtDocumentoCliente" runat="server" CssClass="form-control" MaxLength="50"></asp:TextBox>
        </div>
    </div>

    <div class="reservation-section">
        <h3>Pasajeros</h3>
        <p>
            Cantidad declarada: <strong><asp:Label ID="lblCantidadPasajeros" runat="server"></asp:Label></strong><br />
            Debe cargar exactamente esa cantidad para confirmar la reserva.
        </p>

        <asp:GridView ID="gvPasajeros" runat="server" CssClass="grid" AutoGenerateColumns="false" 
            OnRowCommand="gvPasajeros_RowCommand" DataKeyNames="Documento">
            <Columns>
                <asp:BoundField DataField="NombreCompleto" HeaderText="Nombre" />
                <asp:BoundField DataField="Documento" HeaderText="Documento" />
                <asp:BoundField DataField="Email" HeaderText="Email" />
                <asp:BoundField DataField="Nacionalidad" HeaderText="Nacionalidad" />
                <asp:TemplateField>
                    <ItemTemplate>
                        <asp:Button runat="server" ID="btnEliminar" CssClass="btn-grid" Text="Eliminar" 
                            CommandName="Eliminar" CommandArgument='<%# Eval("Documento") %>' />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>

        <div class="form-inline" style="margin-top: 20px;">
            <h4>Agregar Pasajero</h4>
            <div class="form-group">
                <label for="<%= txtNombrePasajero.ClientID %>">Nombre *:</label>
                <asp:TextBox ID="txtNombrePasajero" runat="server" CssClass="form-control" MaxLength="100"></asp:TextBox>
            </div>
            <div class="form-group">
                <label for="<%= txtApellidoPasajero.ClientID %>">Apellido:</label>
                <asp:TextBox ID="txtApellidoPasajero" runat="server" CssClass="form-control" MaxLength="100"></asp:TextBox>
            </div>
            <div class="form-group">
                <label for="<%= txtDocumentoPasajero.ClientID %>">Documento *:</label>
                <asp:TextBox ID="txtDocumentoPasajero" runat="server" CssClass="form-control" MaxLength="50"></asp:TextBox>
            </div>
            <div class="form-group">
                <label for="<%= txtEmailPasajero.ClientID %>">Email:</label>
                <asp:TextBox ID="txtEmailPasajero" runat="server" CssClass="form-control" MaxLength="150"></asp:TextBox>
            </div>
            <div class="form-group">
                <label for="<%= txtNacionalidadPasajero.ClientID %>">Nacionalidad:</label>
                <asp:TextBox ID="txtNacionalidadPasajero" runat="server" CssClass="form-control" MaxLength="100"></asp:TextBox>
            </div>
            <div class="form-group">
                <label for="<%= txtFechaNacimientoPasajero.ClientID %>">Fecha Nacimiento:</label>
                <asp:TextBox ID="txtFechaNacimientoPasajero" runat="server" CssClass="form-control" TextMode="Date"></asp:TextBox>
            </div>
            <asp:Button ID="btnAgregarPasajero" runat="server" Text="Agregar Pasajero" CssClass="btn-buscar" 
                OnClick="btnAgregarPasajero_Click" />
        </div>
    </div>

    <div class="reservation-section">
        <h3>Resumen</h3>
        <p><strong>Cantidad de pasajeros:</strong> <asp:Label ID="lblCantidadActualPasajeros" runat="server"></asp:Label></p>
        <p><strong>Monto Total:</strong> <asp:Label ID="lblMontoTotal" runat="server" Font-Bold="true"></asp:Label></p>
        <asp:Button ID="btnConfirmar" runat="server" Text="CONFIRMAR RESERVA" CssClass="btn-buscar" 
            OnClick="btnConfirmar_Click" OnClientClick="return confirm('¿Confirma la reserva?');" />
        <asp:Button ID="btnCancelar" runat="server" Text="Cancelar" CssClass="btn-secondary" 
            OnClick="btnCancelar_Click" />
    </div>

    <style>
        .reservation-section {
            margin: 30px 0;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: #f9f9f9;
        }
        .form-group {
            margin-bottom: 15px;
        }
        .form-group label {
            display: block;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .form-control {
            width: 100%;
            padding: 8px;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        .form-inline {
            background-color: #fff;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .btn-secondary {
            background-color: #6c757d;
            color: white;
            border: none;
            padding: 10px 20px;
            cursor: pointer;
            border-radius: 4px;
            margin-left: 10px;
        }
        .btn-secondary:hover {
            background-color: #5a6268;
        }
    </style>
</asp:Content>
