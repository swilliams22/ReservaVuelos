using ReservaVuelos.BE;
using ReservaVuelos.BLL;
using ReservaVuelos.DAL;
using ReservaVuelos.Servicios;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;

namespace ReservaVuelos
{
    public partial class Backup : System.Web.UI.Page
    {
        private BitacoraBLL _bBLL = new BitacoraBLL();

        private class BackupListItem
        {
            public string Nombre { get; set; }
            public string Fecha { get; set; }
            public string Tamanio { get; set; }
            public string RutaCompleta { get; set; }
            public DateTime FechaOrden { get; set; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerBackup))
            {
                Response.Redirect("Login.aspx");
                return;
            }

            btnGenerarBackup.Visible = AutorizacionService.TienePermiso(user, Permisos.CrearBackup);
            btnRestaurarBackup.Visible = AutorizacionService.TienePermiso(user, Permisos.RestaurarBackup);
            if (!IsPostBack)
            {
                LimpiarResultadoBackup();
                LimpiarResultadoRestore();
                CargarBackupsDisponibles();
            }
        }

        protected void btnGenerarBackup_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.CrearBackup);
            Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerBackup))
            {
                Response.Redirect("Login.aspx");
                return;
            }

            DateTime fecha = DateTime.Now;
            string backupDirectory = GetBackupDirectory();
            string archivo = "AeroLink_" + fecha.ToString("yyyy-MM-dd_HH-mm-ss") + ".bak";
            string rutaCompleta = Path.Combine(backupDirectory, archivo);

            bool backupGenerado = false;
            bool advertencia = false;
            string mensaje = string.Empty;

            try
            {
                using (SqlConnection cn = GetMasterConnection())
                {
                    cn.Open();
                    string dbName = GetDatabaseName();
                    string safeDbName = dbName.Replace("]", "]]" );

                    try
                    {
                        using (SqlCommand cmdDir = new SqlCommand("EXEC master.dbo.xp_create_subdir @Dir", cn))
                        {
                            cmdDir.Parameters.AddWithValue("@Dir", backupDirectory);
                            cmdDir.ExecuteNonQuery();
                        }
                    }
                    catch (Exception exDir)
                    {
                        advertencia = true;
                        mensaje = "No se pudo crear/verificar la carpeta en SQL Server. " + exDir.Message;
                    }

                    try
                    {
                        using (SqlCommand cmdBackup = new SqlCommand("BACKUP DATABASE [" + safeDbName + "] TO DISK = @Ruta WITH INIT, CHECKSUM", cn))
                        {
                            cmdBackup.Parameters.AddWithValue("@Ruta", rutaCompleta);
                            cmdBackup.ExecuteNonQuery();
                            backupGenerado = true;
                        }
                    }
                    catch (Exception exBackup)
                    {
                        backupGenerado = false;
                        mensaje = "Error al generar backup. " + exBackup.Message;
                    }

                    if (backupGenerado)
                    {
                        try
                        {
                            using (SqlCommand cmdVerify = new SqlCommand("RESTORE VERIFYONLY FROM DISK = @Ruta WITH CHECKSUM", cn))
                            {
                                cmdVerify.Parameters.AddWithValue("@Ruta", rutaCompleta);
                                cmdVerify.ExecuteNonQuery();
                            }
                        }
                        catch (Exception exVerify)
                        {
                            advertencia = true;
                            if (!string.IsNullOrWhiteSpace(mensaje)) mensaje += " ";
                            mensaje += "Backup generado, pero no se pudo verificar con RESTORE VERIFYONLY. " + exVerify.Message;
                        }
                    }
                }

                if (backupGenerado && !advertencia)
                {
                    if (string.IsNullOrWhiteSpace(mensaje)) mensaje = "Backup generado y verificado correctamente.";
                    MostrarResultadoBackup(archivo, fecha, rutaCompleta, "Éxito", mensaje, System.Drawing.Color.Green);
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Backup generado correctamente. Archivo: " + archivo + " - Ruta: " + rutaCompleta, Criticidad = 1, Pantalla = "Backup" });
                }
                else if (backupGenerado)
                {
                    if (string.IsNullOrWhiteSpace(mensaje)) mensaje = "Backup generado con advertencias de permisos/configuración.";
                    MostrarResultadoBackup(archivo, fecha, rutaCompleta, "Advertencia", mensaje, System.Drawing.Color.DarkOrange);
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Backup generado con advertencias. Archivo: " + archivo + " - Ruta: " + rutaCompleta + " - Detalle: " + mensaje, Criticidad = 2, Pantalla = "Backup" });
                }
                else
                {
                    if (string.IsNullOrWhiteSpace(mensaje)) mensaje = "No se pudo generar el backup.";
                    MostrarResultadoBackup(archivo, fecha, rutaCompleta, "Error", mensaje, System.Drawing.Color.Red);
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Error al generar backup. Archivo: " + archivo + " - Ruta: " + rutaCompleta + " - Detalle: " + mensaje, Criticidad = 3, Pantalla = "Backup" });
                }

                CargarBackupsDisponibles();
            }
            catch (Exception ex)
            {
                string error = "Error inesperado al ejecutar backup. " + ex.Message;
                MostrarResultadoBackup(archivo, fecha, rutaCompleta, "Error", error, System.Drawing.Color.Red);
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user != null ? user.Email : "Sistema", Accion = "Error inesperado al generar backup. Detalle: " + ex.Message, Criticidad = 3, Pantalla = "Backup" });
            }
        }

        protected void btnActualizarListaBackups_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.VerBackup);
            CargarBackupsDisponibles();
        }

        protected void gvBackupsDisponibles_RowCommand(object sender, System.Web.UI.WebControls.GridViewCommandEventArgs e)
        {
            AutorizacionService.Exigir(Permisos.VerBackup);
            if (e.CommandName != "SeleccionarBackup") return;

            string ruta = e.CommandArgument == null ? string.Empty : e.CommandArgument.ToString();
            hfBackupSeleccionado.Value = ruta;
            lblBackupSeleccionado.Text = Path.GetFileName(ruta) + " - " + ruta;
            lblRestoreResultado.Text = string.Empty;
            lblRestoreMensaje.Text = string.Empty;
        }

        protected void btnRestaurarBackup_Click(object sender, EventArgs e)
        {
            AutorizacionService.Exigir(Permisos.RestaurarBackup);
            Usuario user = SesionService.GetUser();
            if (!AutorizacionService.TienePermiso(user, Permisos.VerBackup))
            {
                Response.Redirect("Login.aspx");
                return;
            }

            string rutaBackup;
            string mensajeValidacion;
            if (!TryObtenerRutaBackupValida(out rutaBackup, out mensajeValidacion))
            {
                MostrarResultadoRestore("Error", mensajeValidacion, System.Drawing.Color.Red);
                return;
            }

            string archivo = Path.GetFileName(rutaBackup);
            string dbName = GetDatabaseName();
            string safeDbName = dbName.Replace("]", "]]" );

            _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Inicio de restauración de backup. Archivo: " + archivo + " - Ruta: " + rutaBackup, Criticidad = 1, Pantalla = "Backup" });

            SqlConnection cn = null;
            try
            {
                cn = GetMasterConnection();
                cn.Open();

                using (SqlCommand cmdVerify = new SqlCommand("RESTORE VERIFYONLY FROM DISK = @Ruta WITH CHECKSUM", cn))
                {
                    cmdVerify.Parameters.AddWithValue("@Ruta", rutaBackup);
                    cmdVerify.ExecuteNonQuery();
                }

                using (SqlCommand cmdSingleUser = new SqlCommand("ALTER DATABASE [" + safeDbName + "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE", cn))
                {
                    cmdSingleUser.ExecuteNonQuery();
                }

                using (SqlCommand cmdRestore = new SqlCommand("RESTORE DATABASE [" + safeDbName + "] FROM DISK = @Ruta WITH REPLACE, RECOVERY, CHECKSUM", cn))
                {
                    cmdRestore.Parameters.AddWithValue("@Ruta", rutaBackup);
                    cmdRestore.ExecuteNonQuery();
                }

                MostrarResultadoRestore("Éxito", "Restauración completada correctamente con el archivo " + archivo + ".", System.Drawing.Color.Green);
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Restauración de backup exitosa. Archivo: " + archivo + " - Ruta: " + rutaBackup, Criticidad = 1, Pantalla = "Backup" });

                IntegrityValidationResult integrityResult = new IntegrityService().TryResolveAfterValidation(user.IdUsuario, "Restauracion de backup validada");
                if (!integrityResult.IsValid)
                {
                    MostrarResultadoRestore("Advertencia", "Backup restaurado, pero persisten inconsistencias de integridad. El modo de contingencia permanece activo.", System.Drawing.Color.DarkOrange);
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Restauración finalizada con inconsistencias de integridad persistentes.", Criticidad = 4, Pantalla = "Backup" });
                }
            }
            catch (Exception ex)
            {
                string mensaje = "Error al restaurar backup. " + ex.Message;
                MostrarResultadoRestore("Error", mensaje, System.Drawing.Color.Red);
                _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = "Error en restauración de backup. Archivo: " + archivo + " - Ruta: " + rutaBackup + " - Detalle: " + ex.Message, Criticidad = 3, Pantalla = "Backup" });
            }
            finally
            {
                try
                {
                    if (cn != null && cn.State == System.Data.ConnectionState.Open)
                    {
                        using (SqlCommand cmdMultiUser = new SqlCommand("ALTER DATABASE [" + safeDbName + "] SET MULTI_USER", cn))
                        {
                            cmdMultiUser.ExecuteNonQuery();
                        }
                    }
                }
                catch (Exception exMulti)
                {
                    string warning = "Advertencia: no se pudo asegurar MULTI_USER. " + exMulti.Message;
                    if (string.IsNullOrWhiteSpace(lblRestoreMensaje.Text)) lblRestoreMensaje.Text = warning;
                    else lblRestoreMensaje.Text += " " + warning;
                    _bBLL.Create(new ReservaVuelos.BE.Bitacora { Fecha = DateTime.Now, Usuario = user.Email, Accion = warning + " Archivo: " + archivo + " - Ruta: " + rutaBackup, Criticidad = 2, Pantalla = "Backup" });
                }
                finally
                {
                    if (cn != null) cn.Dispose();
                }
            }
        }

        private void CargarBackupsDisponibles()
        {
            List<BackupListItem> lista = new List<BackupListItem>();
            string backupDirectory = GetBackupDirectory();

            try
            {
                if (!Directory.Exists(backupDirectory))
                {
                    Directory.CreateDirectory(backupDirectory);
                }

                foreach (string file in Directory.GetFiles(backupDirectory, "*.bak", SearchOption.TopDirectoryOnly))
                {
                    FileInfo fi = new FileInfo(file);
                    lista.Add(new BackupListItem
                    {
                        Nombre = fi.Name,
                        Fecha = fi.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture),
                        Tamanio = FormatearTamanio(fi.Length),
                        RutaCompleta = fi.FullName,
                        FechaOrden = fi.LastWriteTime
                    });
                }
            }
            catch (Exception ex)
            {
                MostrarResultadoRestore("Advertencia", "No se pudo leer la carpeta de backups: " + ex.Message, System.Drawing.Color.DarkOrange);
            }

            gvBackupsDisponibles.DataSource = lista.OrderByDescending(x => x.FechaOrden).ToList();
            gvBackupsDisponibles.DataBind();
        }

        private bool TryObtenerRutaBackupValida(out string rutaBackup, out string mensaje)
        {
            rutaBackup = string.Empty;
            mensaje = string.Empty;

            string seleccion = hfBackupSeleccionado.Value == null ? string.Empty : hfBackupSeleccionado.Value.Trim();
            if (string.IsNullOrWhiteSpace(seleccion))
            {
                mensaje = "Debe seleccionar un archivo de backup de la lista.";
                return false;
            }

            if (seleccion.Contains(".."))
            {
                mensaje = "Ruta inválida.";
                return false;
            }

            string baseDir = Path.GetFullPath(GetBackupDirectory());
            if (!baseDir.EndsWith("\\")) baseDir += "\\";

            string fullPath = Path.GetFullPath(seleccion);
            if (!fullPath.StartsWith(baseDir, StringComparison.OrdinalIgnoreCase))
            {
                mensaje = "No se permite usar rutas externas a la carpeta de backups.";
                return false;
            }

            if (!string.Equals(Path.GetExtension(fullPath), ".bak", StringComparison.OrdinalIgnoreCase))
            {
                mensaje = "El archivo seleccionado no es un .bak válido.";
                return false;
            }

            if (!File.Exists(fullPath))
            {
                mensaje = "El archivo seleccionado no existe.";
                return false;
            }

            rutaBackup = fullPath;
            return true;
        }

        private string GetBackupDirectory()
        {
            string backupDirectory = ConfigurationManager.AppSettings["BackupDirectory"] ?? @"C:\AeroLink\backups\";
            backupDirectory = Path.GetFullPath(backupDirectory);
            if (!backupDirectory.EndsWith("\\")) backupDirectory += "\\";
            return backupDirectory;
        }

        private string GetDatabaseName()
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                return new SqlConnectionStringBuilder(cn.ConnectionString).InitialCatalog;
            }
        }

        private SqlConnection GetMasterConnection()
        {
            using (SqlConnection cn = ConexionDAL.GetConnection())
            {
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder(cn.ConnectionString);
                builder.InitialCatalog = "master";
                return new SqlConnection(builder.ConnectionString);
            }
        }

        private string FormatearTamanio(long bytes)
        {
            if (bytes < 1024) return bytes + " B";
            if (bytes < 1024 * 1024) return (bytes / 1024d).ToString("N2", CultureInfo.InvariantCulture) + " KB";
            if (bytes < 1024L * 1024L * 1024L) return (bytes / (1024d * 1024d)).ToString("N2", CultureInfo.InvariantCulture) + " MB";
            return (bytes / (1024d * 1024d * 1024d)).ToString("N2", CultureInfo.InvariantCulture) + " GB";
        }

        private void LimpiarResultadoBackup()
        {
            lblBackupNombre.Text = string.Empty;
            lblBackupFechaHora.Text = string.Empty;
            lblBackupRuta.Text = string.Empty;
            lblBackupResultado.Text = string.Empty;
            lblBackupMensaje.Text = string.Empty;
        }

        private void LimpiarResultadoRestore()
        {
            lblBackupSeleccionado.Text = string.Empty;
            hfBackupSeleccionado.Value = string.Empty;
            lblRestoreResultado.Text = string.Empty;
            lblRestoreMensaje.Text = string.Empty;
        }

        private void MostrarResultadoBackup(string archivo, DateTime fecha, string rutaCompleta, string resultado, string mensaje, System.Drawing.Color color)
        {
            lblBackupNombre.Text = archivo;
            lblBackupFechaHora.Text = fecha.ToString("yyyy-MM-dd HH:mm:ss");
            lblBackupRuta.Text = rutaCompleta;
            lblBackupResultado.Text = resultado;
            lblBackupResultado.ForeColor = color;
            lblBackupMensaje.Text = mensaje;
        }

        private void MostrarResultadoRestore(string resultado, string mensaje, System.Drawing.Color color)
        {
            lblRestoreResultado.Text = resultado;
            lblRestoreResultado.ForeColor = color;
            lblRestoreMensaje.Text = mensaje;
        }
    }
}
