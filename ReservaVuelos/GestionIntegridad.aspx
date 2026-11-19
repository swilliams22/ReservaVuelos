<%@ Page Title="Gestión de Integridad" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="GestionIntegridad.aspx.cs" Inherits="ReservaVuelos.GestionIntegridad" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="ui.gestionintegridad.006">Gestión de Integridad</h2>

    <asp:Label ID="lblMsg" runat="server"></asp:Label>

    <div class="panel">
        <p><strong runat="server" data-i18n="ui.gestionintegridad.007">Modo contingencia:</strong> <asp:Label ID="lblModo" runat="server"></asp:Label></p>
        <p><strong runat="server" data-i18n="ui.gestionintegridad.008">Última validación:</strong> <asp:Label ID="lblUltimaValidacion" runat="server"></asp:Label></p>
        <p><strong runat="server" data-i18n="ui.gestionintegridad.009">Motivo:</strong> <asp:Label ID="lblMotivo" runat="server"></asp:Label></p>
    </div>

    <p>
        <asp:Button ID="btnValidar" runat="server" Text="Volver a validar" data-i18n="ui.gestionintegridad.002" CssClass="btn-grid" OnClick="btnValidar_Click" />
        <asp:Button ID="btnResolver" runat="server" Text="Validar y salir de contingencia" data-i18n="ui.gestionintegridad.003" CssClass="btn-grid" OnClick="btnResolver_Click" />
        <asp:Button ID="btnRecalcular" runat="server" Text="Recalcular DVH/DVV" data-i18n="ui.gestionintegridad.004" CssClass="btn-grid" OnClick="btnRecalcular_Click"
            OnClientClick="return showConfirm('Recalcular los dígitos verificadores aceptará como válido el estado actual de los datos. Utilice esta opción únicamente después de revisar y corregir la causa de la inconsistencia. ¿Confirma el recálculo?', this);" data-i18n-confirm="ui.gestionintegridad.005" />
        <a class="btn-grid" href="Backup.aspx" runat="server" data-i18n="ui.gestionintegridad.010">Backups</a>
        <a class="btn-grid" href="Bitacora.aspx" runat="server" data-i18n="ui.gestionintegridad.011">Bitácora</a>
    </p>

    <div class="filter-row">
        <asp:Label runat="server" AssociatedControlID="txtFiltrogvErrores" Text="Buscar en la tabla" data-i18n="grillas.buscar" />
        <asp:TextBox ID="txtFiltrogvErrores" runat="server" MaxLength="150" />
        <asp:Button runat="server" Text="Filtrar" data-i18n="grillas.filtrar" OnClick="FiltrargvErrores" CommandArgument="aplicar" CausesValidation="false" CssClass="btn-grid" />
        <asp:Button runat="server" Text="Limpiar" data-i18n="grillas.limpiar" OnClick="FiltrargvErrores" CommandArgument="limpiar" CausesValidation="false" CssClass="btn-grid" />
    </div>
    <asp:GridView ID="gvErrores" runat="server" AllowPaging="true" PageSize="20" OnPageIndexChanging="gvErrores_PageIndexChanging" CssClass="grid" AutoGenerateColumns="false" data-i18n-headers="ui.gestionintegridad.012,ui.gestionintegridad.013,ui.gestionintegridad.014,ui.gestionintegridad.015,grillas.fecha,grillas.estado">
        <Columns>
            <asp:BoundField DataField="TipoOperacion" HeaderText="Operacion" />
            <asp:BoundField DataField="TipoError" HeaderText="Falla" />
            <asp:BoundField DataField="NombreTabla" HeaderText="Tabla" />
            <asp:BoundField DataField="IdRegistroAfectado" HeaderText="Registro" />
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
            <asp:TemplateField HeaderText="Estado">
                <ItemTemplate><asp:Label runat="server" Text='<%# Eval("Estado") %>' data-i18n='<%# Convert.ToString(Eval("Estado")) == "Activo" ? "grillas.activo" : "grillas.resuelto" %>' /></ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
