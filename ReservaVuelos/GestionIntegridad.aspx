<%@ Page Title="Gestión de Integridad" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="GestionIntegridad.aspx.cs" Inherits="ReservaVuelos.GestionIntegridad" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Gestión de Integridad</h2>

    <asp:Label ID="lblMsg" runat="server"></asp:Label>

    <div class="panel">
        <p><strong>Modo contingencia:</strong> <asp:Label ID="lblModo" runat="server"></asp:Label></p>
        <p><strong>Última validación:</strong> <asp:Label ID="lblUltimaValidacion" runat="server"></asp:Label></p>
        <p><strong>Motivo:</strong> <asp:Label ID="lblMotivo" runat="server"></asp:Label></p>
    </div>

    <p>
        <asp:Button ID="btnValidar" runat="server" Text="Volver a validar" CssClass="btn-grid" OnClick="btnValidar_Click" />
        <asp:Button ID="btnResolver" runat="server" Text="Validar y salir de contingencia" CssClass="btn-grid" OnClick="btnResolver_Click" />
        <asp:Button ID="btnRecalcular" runat="server" Text="Recalcular DVH/DVV" CssClass="btn-grid" OnClick="btnRecalcular_Click"
            OnClientClick="return showConfirm('Recalcular los dígitos verificadores aceptará como válido el estado actual de los datos. Utilice esta opción únicamente después de revisar y corregir la causa de la inconsistencia. ¿Confirma el recálculo?', this);" />
        <a class="btn-grid" href="Backup.aspx">Backups</a>
        <a class="btn-grid" href="Bitacora.aspx">Bitácora</a>
    </p>

    <asp:GridView ID="gvErrores" runat="server" CssClass="grid" AutoGenerateColumns="false">
        <Columns>
            <asp:BoundField DataField="TipoOperacion" HeaderText="Operacion" />
            <asp:BoundField DataField="TipoError" HeaderText="Falla" />
            <asp:BoundField DataField="NombreTabla" HeaderText="Tabla" />
            <asp:BoundField DataField="IdRegistroAfectado" HeaderText="Registro" />
        </Columns>
    </asp:GridView>
</asp:Content>
