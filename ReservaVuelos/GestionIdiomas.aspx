<%@ Page Title="Gestión de idiomas" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="GestionIdiomas.aspx.cs" Inherits="ReservaVuelos.GestionIdiomas" %>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2 runat="server" data-i18n="idiomas.titulo">Gestión de idiomas</h2>
    <p style="color:#555;" runat="server" data-i18n="idiomas.ayuda">Cree un idioma, cargue sus traducciones y actívelo para que los usuarios puedan elegirlo en el selector. Los textos que queden sin traducir se muestran en el idioma por defecto.</p>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red"></asp:Label>

    <h4 runat="server" data-i18n="idiomas.nuevo.titulo">Nuevo idioma</h4>
    <div class="filter-row">
        <asp:Label runat="server" AssociatedControlID="txtCodigo" data-i18n="idiomas.lbl.codigo" Text="Código (ej: pt-BR)"></asp:Label>
        <asp:TextBox ID="txtCodigo" runat="server" MaxLength="10" Width="90px"></asp:TextBox>
        <asp:Label runat="server" AssociatedControlID="txtNombre" data-i18n="idiomas.lbl.nombre" Text="Nombre (ej: Português)"></asp:Label>
        <asp:TextBox ID="txtNombre" runat="server" MaxLength="50"></asp:TextBox>
        <asp:Button ID="btnCrear" runat="server" Text="Crear idioma" data-i18n="idiomas.btn.crear" OnClick="btnCrear_Click" CssClass="btn-grid" />
    </div>

    <h4 runat="server" data-i18n="idiomas.lista.titulo">Idiomas</h4>
    <asp:GridView ID="gvIdiomas" runat="server" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="IdIdioma"
        OnRowDataBound="gvIdiomas_RowDataBound" OnRowCommand="gvIdiomas_RowCommand"
        data-i18n-headers="idiomas.col.codigo,idiomas.col.nombre,idiomas.col.estado,idiomas.col.progreso,idiomas.col.acciones">
        <Columns>
            <asp:BoundField DataField="Codigo" HeaderText="Código" />
            <asp:BoundField DataField="Nombre" HeaderText="Nombre" />
            <asp:TemplateField HeaderText="Estado">
                <ItemTemplate>
                    <asp:Label ID="lblEstado" runat="server"></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Traducido">
                <ItemTemplate>
                    <asp:Label ID="lblProgreso" runat="server"></asp:Label>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="Acciones">
                <ItemTemplate>
                    <asp:Button ID="btnEditar" runat="server" Text="Editar textos" data-i18n="idiomas.btn.editar" CommandName="Editar" CssClass="btn-grid" CausesValidation="false" />
                    <asp:Button ID="btnActivar" runat="server" Text="Activar" data-i18n="idiomas.btn.activar" CommandName="Activar" CssClass="btn-grid" CausesValidation="false" />
                    <asp:Button ID="btnDesactivar" runat="server" Text="Desactivar" data-i18n="idiomas.btn.desactivar" CommandName="Desactivar" CssClass="btn-grid" CausesValidation="false" />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>

    <asp:Panel ID="pnlEditar" runat="server" Visible="false" Style="margin-top:24px;">
        <asp:HiddenField ID="hfIdIdioma" runat="server" />
        <h4><span runat="server" data-i18n="idiomas.edit.titulo">Traducciones de:</span> <asp:Label ID="lblIdiomaEditado" runat="server" Font-Bold="true"></asp:Label></h4>

        <div class="filter-row">
            <asp:Label runat="server" AssociatedControlID="ddlPantalla" data-i18n="idiomas.lbl.pantalla" Text="Pantalla"></asp:Label>
            <asp:DropDownList ID="ddlPantalla" runat="server"></asp:DropDownList>
            <asp:CheckBox ID="chkPendientes" runat="server" Text="Solo pendientes" data-i18n="idiomas.chk.pendientes" />
            <asp:Button ID="btnFiltrar" runat="server" Text="Filtrar" data-i18n="idiomas.btn.filtrar" OnClick="btnFiltrar_Click" CssClass="btn-grid" />
        </div>

        <asp:GridView ID="gvEtiquetas" runat="server" CssClass="grid" AutoGenerateColumns="false" DataKeyNames="IdEtiqueta"
            data-i18n-headers="idiomas.col.pantalla,idiomas.col.clave,idiomas.col.textoBase,idiomas.col.traduccion">
            <Columns>
                <asp:BoundField DataField="Pantalla" HeaderText="Pantalla" />
                <asp:BoundField DataField="Clave" HeaderText="Clave" />
                <asp:BoundField DataField="TextoBase" HeaderText="Texto base" />
                <asp:TemplateField HeaderText="Traducción">
                    <ItemTemplate>
                        <asp:TextBox ID="txtTexto" runat="server" Text='<%# Eval("Texto") %>' MaxLength="500" CssClass="form-control form-control-sm" Width="100%"></asp:TextBox>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>

        <div style="margin-top:12px;">
            <asp:Button ID="btnGuardar" runat="server" Text="Guardar traducciones" data-i18n="idiomas.btn.guardar" OnClick="btnGuardar_Click" CssClass="btn-grid" />
            <asp:Button ID="btnCerrar" runat="server" Text="Cerrar" data-i18n="idiomas.btn.cerrar" OnClick="btnCerrar_Click" CssClass="btn-grid" />
        </div>
    </asp:Panel>
</asp:Content>
