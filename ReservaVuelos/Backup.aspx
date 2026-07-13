<%@ Page Title="Backups" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Backup.aspx.cs" Inherits="ReservaVuelos.Backup" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Backups</h2>

    <div class="filter-row">
        <asp:Label ID="lblBackupAviso" runat="server" ForeColor="Red" Text="Los backups se almacenan en la carpeta C:\AeroLink\backups\ del equipo donde se ejecuta SQL Server"></asp:Label>
    </div>

    <h3>Generación de backup</h3>
    <div class="filter-row">
        <asp:Button ID="btnGenerarBackup" runat="server" Text="Generar backup" CssClass="btn-grid" OnClick="btnGenerarBackup_Click" OnClientClick="return showConfirm('Confirma generar un backup de base de datos?', this);" />
    </div>

    <div class="filter-row">
        <strong>Nombre del archivo:</strong> <asp:Label ID="lblBackupNombre" runat="server"></asp:Label><br />
        <strong>Fecha y hora:</strong> <asp:Label ID="lblBackupFechaHora" runat="server"></asp:Label><br />
        <strong>Ruta completa:</strong> <asp:Label ID="lblBackupRuta" runat="server"></asp:Label><br />
        <strong>Resultado:</strong> <asp:Label ID="lblBackupResultado" runat="server"></asp:Label><br />
        <strong>Mensaje:</strong> <asp:Label ID="lblBackupMensaje" runat="server"></asp:Label>
    </div>

    <h3>Restauración de backup</h3>
    <div class="filter-row" style="color:#b71c1c;">
        Restaurar un backup reemplazará el estado actual de la base de datos. Los cambios posteriores a la copia seleccionada pueden perderse.
    </div>
    <div class="filter-row" style="color:#555;">
        La ruta mostrada corresponde al equipo donde corre SQL Server.
    </div>
    <div class="filter-row">
        <asp:Button ID="btnActualizarListaBackups" runat="server" Text="Actualizar lista" CssClass="btn-grid" OnClick="btnActualizarListaBackups_Click" />
    </div>

    <asp:GridView ID="gvBackupsDisponibles" runat="server" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="RutaCompleta" OnRowCommand="gvBackupsDisponibles_RowCommand">
        <Columns>
            <asp:BoundField DataField="Nombre" HeaderText="Nombre" />
            <asp:BoundField DataField="Fecha" HeaderText="Fecha" />
            <asp:BoundField DataField="Tamanio" HeaderText="Tamaño" />
            <asp:BoundField DataField="RutaCompleta" HeaderText="Ruta" />
            <asp:TemplateField HeaderText="Seleccionar">
                <ItemTemplate>
                    <asp:Button runat="server" ID="btnSeleccionarBackup" Text="Seleccionar" CommandName="SeleccionarBackup" CommandArgument='<%# Eval("RutaCompleta") %>' CssClass="btn-grid" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>

    <div class="filter-row">
        <strong>Archivo seleccionado:</strong> <asp:Label ID="lblBackupSeleccionado" runat="server"></asp:Label><br />
        <asp:HiddenField ID="hfBackupSeleccionado" runat="server" />
        <asp:Button ID="btnRestaurarBackup" runat="server" Text="Restaurar backup" CssClass="btn-grid" OnClick="btnRestaurarBackup_Click" OnClientClick="return showConfirm('Confirma restaurar el backup seleccionado? Esta acción reemplazará el estado actual de la base.', this);" />
    </div>

    <div class="filter-row">
        <strong>Resultado restauración:</strong> <asp:Label ID="lblRestoreResultado" runat="server"></asp:Label><br />
        <strong>Mensaje restauración:</strong> <asp:Label ID="lblRestoreMensaje" runat="server"></asp:Label>
    </div>
</asp:Content>
