<%@ Page Title="Mis datos" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="MisDatos.aspx.cs" Inherits="ReservaVuelos.MisDatos" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Mis datos</h2>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <div class="profile-section">
        <h3>Cliente titular</h3>
        <div class="form-row">
            <label for="txtNombreCliente">Nombre</label>
            <asp:TextBox ID="txtNombreCliente" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtEmailCliente">Email</label>
            <asp:TextBox ID="txtEmailCliente" runat="server" TextMode="Email"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtDocumentoCliente">Documento</label>
            <asp:TextBox ID="txtDocumentoCliente" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtTelefonoCliente">Teléfono</label>
            <asp:TextBox ID="txtTelefonoCliente" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtDireccionCliente">Dirección</label>
            <asp:TextBox ID="txtDireccionCliente" runat="server"></asp:TextBox>
        </div>
    </div>

    <div class="profile-section">
        <h3>Pasajero asociado</h3>
        <div class="form-row">
            <label for="txtNombrePasajero">Nombre</label>
            <asp:TextBox ID="txtNombrePasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtApellidoPasajero">Apellido</label>
            <asp:TextBox ID="txtApellidoPasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtEmailPasajero">Email</label>
            <asp:TextBox ID="txtEmailPasajero" runat="server" TextMode="Email"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtDocumentoPasajero">Documento</label>
            <asp:TextBox ID="txtDocumentoPasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtNacionalidadPasajero">Nacionalidad</label>
            <asp:TextBox ID="txtNacionalidadPasajero" runat="server"></asp:TextBox>
        </div>
        <div class="form-row">
            <label for="txtFechaNacimientoPasajero">Fecha de nacimiento</label>
            <asp:TextBox ID="txtFechaNacimientoPasajero" runat="server" TextMode="Date"></asp:TextBox>
        </div>
    </div>

    <div class="actions">
        <asp:Button ID="btnGuardar" runat="server" Text="Guardar cambios" OnClick="btnGuardar_Click" />
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