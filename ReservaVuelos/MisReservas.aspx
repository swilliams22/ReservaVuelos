<%@ Page Title="Mis reservas" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MisReservas.aspx.cs" Inherits="ReservaVuelos.MisReservas" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Mis reservas</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>
    <asp:GridView ID="gvReservas" runat="server" AutoGenerateColumns="false" OnRowCommand="gvReservas_RowCommand" OnRowDataBound="gvReservas_RowDataBound" DataKeyNames="IdReserva">
        <Columns>
            <asp:BoundField DataField="IdReserva" HeaderText="Id" />
            <asp:BoundField DataField="IdVuelo" HeaderText="IdVuelo" />
            <asp:BoundField DataField="FechaReserva" HeaderText="FechaReserva" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:BoundField DataField="Estado" HeaderText="Estado" />
            <asp:TemplateField>
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnCancelar" Text="Cancelar" CommandName="Cancelar" CommandArgument='<%# Eval("IdReserva") %>' OnClientClick="return confirm('Confirma cancelar esta reserva?');" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
