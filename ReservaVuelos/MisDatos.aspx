<%@ Page Title="Mis datos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MisDatos.aspx.cs" Inherits="ReservaVuelos.MisDatos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="misdatos.titulo">Mis datos</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <div class="profile-section">
        <h3 runat="server" data-i18n="misdatos.sec.cliente">Cliente titular</h3>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.nombre" Text="Nombre" AssociatedControlID="txtNombreCliente"></asp:Label>
            <asp:TextBox ID="txtNombreCliente" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.email" Text="Email" AssociatedControlID="txtEmailCliente"></asp:Label>
            <asp:TextBox ID="txtEmailCliente" runat="server" TextMode="Email"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.documento" Text="Documento" AssociatedControlID="txtDocumentoCliente"></asp:Label>
            <asp:TextBox ID="txtDocumentoCliente" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.telefono" Text="Teléfono" AssociatedControlID="txtTelefonoCliente"></asp:Label>
            <asp:TextBox ID="txtTelefonoCliente" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.direccion" Text="Dirección" AssociatedControlID="txtDireccionCliente"></asp:Label>
            <asp:TextBox ID="txtDireccionCliente" runat="server"></asp:TextBox>
        </div>
    </div>

    <div class="profile-section">
        <h3 runat="server" data-i18n="misdatos.sec.pasajero">Pasajero asociado</h3>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.nombre" Text="Nombre" AssociatedControlID="txtNombrePasajero"></asp:Label>
            <asp:TextBox ID="txtNombrePasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.apellido" Text="Apellido" AssociatedControlID="txtApellidoPasajero"></asp:Label>
            <asp:TextBox ID="txtApellidoPasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.email" Text="Email" AssociatedControlID="txtEmailPasajero"></asp:Label>
            <asp:TextBox ID="txtEmailPasajero" runat="server" TextMode="Email"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.documento" Text="Documento" AssociatedControlID="txtDocumentoPasajero"></asp:Label>
            <asp:TextBox ID="txtDocumentoPasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.nacionalidad" Text="Nacionalidad" AssociatedControlID="txtNacionalidadPasajero"></asp:Label>
            <asp:TextBox ID="txtNacionalidadPasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <asp:Label runat="server" data-i18n="misdatos.lbl.fechaNacimiento" Text="Fecha de nacimiento" AssociatedControlID="txtFechaNacimientoPasajero"></asp:Label>
            <asp:TextBox ID="txtFechaNacimientoPasajero" runat="server" TextMode="Date"></asp:TextBox>
        </div>
    </div>

    <div class="actions">
        <asp:Button ID="btnGuardar" runat="server" data-i18n="misdatos.btn.guardar" Text="Guardar cambios" OnClick="btnGuardar_Click" />
    </div>

    <style>
        .profile-section {
            margin-bottom: 24px;
            padding: 16px;
            background: #f9f9f9;
            border: 1px solid #ddd;
            border-radius: 8px;
        }

        .profile-section h3 {
            margin-top: 0;
        }

        .form-row {
            display: flex;
            flex-direction: column;
            margin-bottom: 12px;
            max-width: 420px;
        }

        .form-row label {
            font-weight: 600;
            margin-bottom: 4px;
        }

        .actions {
            margin-top: 16px;
        }
    </style>
</asp:Content>