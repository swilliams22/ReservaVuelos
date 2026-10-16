<%@ Page Title="Mis reservas" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MisReservas.aspx.cs" Inherits="ReservaVuelos.MisReservas" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="misreservas.titulo">Mis reservas</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <asp:Repeater ID="rptReservas" runat="server" OnItemCommand="rptReservas_ItemCommand">
        <ItemTemplate>
            <div class="reservation-card">
                <div class="reservation-header">
                    <h3><span runat="server" data-i18n="misreservas.lbl.reserva">Reserva #</span><%# Eval("IdReservaCabecera") %></h3>
                    <span runat="server" class='reservation-status <%# GetEstadoClass(Eval("Estado").ToString()) %>' data-i18n='<%# "misreservas.estado." + Eval("Estado").ToString().ToLowerInvariant() %>'><%# Eval("Estado") %></span>
                </div>
                <div class="reservation-info">
                    <p><strong runat="server" data-i18n="misreservas.lbl.fechaCreacion">Fecha de creación:</strong> <%# Eval("FechaReserva", "{0:yyyy-MM-dd HH:mm}") %></p>
                    <p><strong runat="server" data-i18n="misreservas.lbl.montoTotal">Monto total:</strong> <%# Eval("MontoTotal", "{0:C}") %></p>
                    <p runat="server" visible='<%# Eval("FechaCancelacion") != DBNull.Value && Eval("FechaCancelacion") != null %>'><strong runat="server" data-i18n="misreservas.lbl.fechaCancelacion">Fecha de cancelación:</strong> <%# Eval("FechaCancelacion", "{0:yyyy-MM-dd HH:mm}") %></p>
                </div>

                <div class="reservation-details">
                    <h4 runat="server" data-i18n="misreservas.sec.vuelos">Vuelos:</h4>
                    <asp:Repeater ID="rptDetalles" runat="server" DataSource='<%# GetDetalles((int)Eval("IdReservaCabecera")) %>'>
                        <ItemTemplate>
                            <div class="flight-detail">
                                <span>✈ <%# Eval("Origen") %> → <%# Eval("Destino") %></span>
                                <span><%# Eval("FechaSalida", "{0:yyyy-MM-dd}") %> <%# Eval("HoraSalida") %></span>
                                <span><span runat="server" data-i18n="misreservas.lbl.cantidad">Cantidad:</span> <%# Eval("Cantidad") %> | <span runat="server" data-i18n="misreservas.lbl.precioUnitario">Precio unitario:</span> <%# Eval("PrecioUnitario", "{0:C}") %> | <span runat="server" data-i18n="misreservas.lbl.subtotal">Subtotal:</span> <%# Eval("SubTotal", "{0:C}") %></span>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>

                <div class="reservation-passengers">
                    <h4 runat="server" data-i18n="misreservas.sec.pasajeros">Pasajeros:</h4>
                    <asp:Repeater ID="rptPasajeros" runat="server" DataSource='<%# GetPasajeros((int)Eval("IdReservaCabecera")) %>'>
                        <ItemTemplate>
                            <div class="passenger-info">
                                <span>👤 <%# Eval("NombreCompleto") %></span>
                                <span><span runat="server" data-i18n="misreservas.lbl.doc">Doc:</span> <%# Eval("Documento") %></span>
                                <span runat="server" visible='<%# Eval("Email") != null && !string.IsNullOrEmpty(Eval("Email").ToString()) %>'>| <span runat="server" data-i18n="misreservas.lbl.email">Email:</span> <%# Eval("Email") %></span>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>

                <div class="reservation-actions">
                    <asp:Button runat="server" ID="btnCancelar" CssClass="btn-cancel" data-i18n="misreservas.btn.cancelar" Text="Cancelar Reserva" 
                        CommandName="Cancelar" CommandArgument='<%# Eval("IdReservaCabecera") %>' 
                        Visible='<%# Eval("Estado").ToString() == "Activa" && ReservaVuelos.Servicios.AutorizacionService.TienePermiso(ReservaVuelos.Servicios.SesionService.GetUser(), ReservaVuelos.Servicios.Permisos.CancelarReserva) %>' />
                </div>
            </div>
        </ItemTemplate>
    </asp:Repeater>

    <style>
        .reservation-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            background-color: #f9f9f9;
        }
        .reservation-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
            margin-bottom: 15px;
        }
        .reservation-header h3 {
            margin: 0;
            color: #007bff;
        }
        .reservation-status {
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 0.9em;
        }
        .status-activa {
            background-color: #28a745;
            color: white;
        }
        .status-cancelada {
            background-color: #dc3545;
            color: white;
        }
        .reservation-info p {
            margin: 5px 0;
        }
        .reservation-details, .reservation-passengers {
            margin-top: 15px;
            padding: 10px;
            background-color: white;
            border-radius: 4px;
        }
        .reservation-details h4, .reservation-passengers h4 {
            margin-top: 0;
            color: #333;
        }
        .flight-detail, .passenger-info {
            padding: 8px;
            margin: 5px 0;
            background-color: #f0f0f0;
            border-left: 3px solid #007bff;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .passenger-info {
            border-left-color: #6c757d;
        }
        .reservation-actions {
            margin-top: 15px;
            text-align: right;
        }
        .btn-cancel {
            background-color: #dc3545;
            color: white;
            border: none;
            padding: 10px 20px;
            cursor: pointer;
            border-radius: 4px;
        }
        .btn-cancel:hover {
            background-color: #c82333;
        }
    </style>
</asp:Content>
