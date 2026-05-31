<%@ Page Title="Mis reservas" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MisReservas.aspx.cs" Inherits="ReservaVuelos.MisReservas" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Mis reservas</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <asp:GridView ID="gvReservas" runat="server" CssClass="grid" AutoGenerateColumns="false" OnRowCommand="gvReservas_RowCommand" OnRowDataBound="gvReservas_RowDataBound" DataKeyNames="IdReserva">
        <Columns>
            <asp:BoundField DataField="IdReserva" HeaderText="IdReserva" />
            <asp:BoundField DataField="Origen" HeaderText="Origen" />
            <asp:BoundField DataField="Destino" HeaderText="Destino" />
            <asp:BoundField DataField="FechaSalida" HeaderText="FechaSalida" DataFormatString="{0:yyyy-MM-dd}" />
            <asp:BoundField DataField="HoraSalida" HeaderText="HoraSalida" DataFormatString="{0:hh\:mm}" />
            <asp:BoundField DataField="Precio" HeaderText="Precio" DataFormatString="{0:C}" />
            <asp:BoundField DataField="Estado" HeaderText="Estado" />
            <asp:BoundField DataField="FechaReserva" HeaderText="FechaReserva" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:TemplateField>
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnCancelar" CssClass="btn-grid" Text="Cancelar" CommandName="Cancelar" CommandArgument='<%# Eval("IdReserva") %>' OnClientClick="return showConfirm('Confirma cancelar esta reserva?', this);" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
