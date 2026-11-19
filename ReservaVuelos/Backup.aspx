<%@ Page Title="Backups" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Backup.aspx.cs" Inherits="ReservaVuelos.Backup" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="ui.backup.009">Backups</h2>

    <div class="filter-row">
        <asp:Label ID="lblBackupAviso" runat="server" ForeColor="Red" Text="Los backups se almacenan en la carpeta C:\AeroLink\backups\ del equipo donde se ejecuta SQL Server" data-i18n="ui.backup.002"></asp:Label>
    </div>

    <h3 runat="server" data-i18n="ui.backup.010">Generación de backup</h3>
    <div class="filter-row">
        <asp:Button ID="btnGenerarBackup" runat="server" Text="Generar backup" data-i18n="ui.backup.003" CssClass="btn-grid" OnClick="btnGenerarBackup_Click" OnClientClick="return showConfirm('Confirma generar un backup de base de datos?', this);" data-i18n-confirm="ui.backup.004" />
    </div>

    <div class="filter-row">
        <strong runat="server" data-i18n="ui.backup.011">Nombre del archivo:</strong> <asp:Label ID="lblBackupNombre" runat="server"></asp:Label><br />
        <strong runat="server" data-i18n="ui.backup.012">Fecha y hora:</strong> <asp:Label ID="lblBackupFechaHora" runat="server"></asp:Label><br />
        <strong runat="server" data-i18n="ui.backup.013">Ruta completa:</strong> <asp:Label ID="lblBackupRuta" runat="server"></asp:Label><br />
        <strong runat="server" data-i18n="ui.backup.014">Resultado:</strong> <asp:Label ID="lblBackupResultado" runat="server"></asp:Label><br />
        <strong runat="server" data-i18n="ui.backup.015">Mensaje:</strong> <asp:Label ID="lblBackupMensaje" runat="server"></asp:Label>
    </div>

    <h3 runat="server" data-i18n="ui.backup.016">Restauración de backup</h3>
    <div class="filter-row" style="color:#b71c1c;">
        <span runat="server" data-i18n="ui.backup.020">Restaurar un backup reemplazará el estado actual de la base de datos. Los cambios posteriores a la copia seleccionada pueden perderse.</span>
    </div>
    <div class="filter-row" style="color:#555;">
        <span runat="server" data-i18n="ui.backup.021">La ruta mostrada corresponde al equipo donde corre SQL Server.</span>
    </div>
    <div class="filter-row">
        <asp:Button ID="btnActualizarListaBackups" runat="server" Text="Actualizar lista" data-i18n="ui.backup.005" CssClass="btn-grid" OnClick="btnActualizarListaBackups_Click" />
    </div>

    <div class="filter-row">
        <asp:Label runat="server" AssociatedControlID="txtFiltrogvBackupsDisponibles" Text="Buscar en la tabla" data-i18n="grillas.buscar" />
        <asp:TextBox ID="txtFiltrogvBackupsDisponibles" runat="server" MaxLength="150" />
        <asp:Button runat="server" Text="Filtrar" data-i18n="grillas.filtrar" OnClick="FiltrargvBackupsDisponibles" CommandArgument="aplicar" CausesValidation="false" CssClass="btn-grid" />
        <asp:Button runat="server" Text="Limpiar" data-i18n="grillas.limpiar" OnClick="FiltrargvBackupsDisponibles" CommandArgument="limpiar" CausesValidation="false" CssClass="btn-grid" />
    </div>
    <asp:GridView ID="gvBackupsDisponibles" runat="server" AllowPaging="true" PageSize="20" OnPageIndexChanging="gvBackupsDisponibles_PageIndexChanging" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="RutaCompleta" OnRowCommand="gvBackupsDisponibles_RowCommand" data-i18n-headers="ui.backup.022,ui.backup.023,ui.backup.024,ui.backup.025,ui.backup.026">
        <Columns>
            <asp:BoundField DataField="Nombre" HeaderText="Nombre" />
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" />
            <asp:BoundField DataField="Tamanio" HeaderText="Tamaño" />
            <asp:BoundField DataField="RutaCompleta" HeaderText="Ruta" />
            <asp:TemplateField HeaderText="Seleccionar">
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnSeleccionarBackup" Text="Seleccionar" data-i18n="ui.backup.006" CommandName="SeleccionarBackup" CommandArgument='<%# Eval("RutaCompleta") %>' CssClass="btn-grid" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>

    <div class="filter-row">
        <strong runat="server" data-i18n="ui.backup.017">Archivo seleccionado:</strong> <asp:Label ID="lblBackupSeleccionado" runat="server"></asp:Label><br />
        <asp:HiddenField ID="hfBackupSeleccionado" runat="server" />
        <asp:Button ID="btnRestaurarBackup" runat="server" Text="Restaurar backup" data-i18n="ui.backup.007" CssClass="btn-grid" OnClick="btnRestaurarBackup_Click" OnClientClick="return showConfirm('Confirma restaurar el backup seleccionado? Esta acción reemplazará el estado actual de la base.', this);" data-i18n-confirm="ui.backup.008" />
    </div>

    <div class="filter-row">
        <strong runat="server" data-i18n="ui.backup.018">Resultado restauración:</strong> <asp:Label ID="lblRestoreResultado" runat="server"></asp:Label><br />
        <strong runat="server" data-i18n="ui.backup.019">Mensaje restauración:</strong> <asp:Label ID="lblRestoreMensaje" runat="server"></asp:Label>
    </div>
</asp:Content>
