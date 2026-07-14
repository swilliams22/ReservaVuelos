using ReservaVuelos.BE;
using ReservaVuelos.DAL;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web;

namespace ReservaVuelos.Servicios
{
    public class IntegrityService
    {
        private static readonly object StartupLock = new object();
        private static bool startupValidationExecuted;

        private static readonly string[] CriticalTables =
        {
            "Usuarios",
            "Clientes",
            "Pasajeros",
            "Vuelos",
            "ReservaCabecera",
            "ReservaDetalle",
            "ReservaPasajero",
            "Bitacora"
        };

        private static readonly int[] Primes =
        {
            2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
            31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
            73, 79, 83, 89, 97
        };

        public int CalculateDVH(string normalizedValue)
        {
            if (normalizedValue == null) normalizedValue = string.Empty;

            long total = 0;
            for (int i = 0; i < normalizedValue.Length; i++)
            {
                int position = i + 1;
                int prime = Primes[i % Primes.Length];
                total += (long)normalizedValue[i] * prime * position;
            }

            return (int)(total % 251);
        }

        public int CalculateUsuarioDVH(Usuario usuario)
        {
            return CalculateDVH(JoinFields(
                usuario.IdUsuario,
                usuario.Nombre,
                usuario.Email,
                usuario.Rol,
                usuario.Activo,
                usuario.FechaAlta));
        }

        public int CalculateClienteDVH(Cliente cliente)
        {
            return CalculateDVH(JoinFields(
                cliente.IdCliente,
                cliente.IdUsuario,
                cliente.Nombre,
                cliente.Email,
                cliente.Documento,
                cliente.Telefono,
                cliente.Direccion,
                cliente.FechaAlta,
                cliente.FechaActualizacion));
        }

        public int CalculateVueloDVH(Vuelo vuelo)
        {
            return CalculateDVH(JoinFields(
                vuelo.IdVuelo,
                vuelo.Origen,
                vuelo.Destino,
                vuelo.FechaSalida.Date,
                vuelo.HoraSalida,
                vuelo.Precio,
                vuelo.CuposDisponibles,
                vuelo.Activo,
                vuelo.FechaCreacion,
                vuelo.FechaActualizacion));
        }

        public int CalculateReservaCabeceraDVH(ReservaCabecera reserva)
        {
            return CalculateDVH(JoinFields(
                reserva.IdReservaCabecera,
                reserva.IdCliente,
                reserva.IdUsuarioCreador,
                reserva.FechaReserva,
                reserva.Estado,
                reserva.MontoTotal,
                reserva.FechaCreacion,
                reserva.FechaActualizacion,
                reserva.FechaCancelacion,
                reserva.IdUsuarioCancela));
        }

        public int CalculateReservaDetalleDVH(ReservaDetalle detalle)
        {
            return CalculateDVH(JoinFields(
                detalle.IdReservaDetalle,
                detalle.IdReservaCabecera,
                detalle.IdVuelo,
                detalle.Cantidad,
                detalle.PrecioUnitario,
                detalle.SubTotal,
                detalle.Estado));
        }

        public void EnsureStartupValidation()
        {
            if (startupValidationExecuted) return;

            lock (StartupLock)
            {
                if (startupValidationExecuted) return;

                try
                {
                    EnsureInfrastructure();
                    if (!HasAnyDVV() || !HasAnySnapshot())
                    {
                        RecalculateAll(null, "Inicializacion controlada de integridad");
                    }
                    else
                    {
                        ValidateAllAndPersist();
                    }
                }
                catch (Exception ex)
                {
                    SafeLog("Sistema", "Falla grave de validacion de integridad al iniciar: " + ex.Message, 4);
                    try { SetContingency(true, "Falla grave de validacion de integridad al iniciar."); } catch { }
                }
                finally
                {
                    startupValidationExecuted = true;
                }
            }
        }

        public ConfiguracionSistema GetConfiguracion()
        {
            EnsureInfrastructure();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT TOP 1 * FROM ConfiguracionSistema WHERE IdConfiguracion = 1", cn))
            {
                cn.Open();
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        return new ConfiguracionSistema
                        {
                            IdConfiguracion = Convert.ToInt32(rdr["IdConfiguracion"]),
                            ModoContingencia = Convert.ToBoolean(rdr["ModoContingencia"]),
                            FechaUltimaValidacion = rdr["FechaUltimaValidacion"] != DBNull.Value ? Convert.ToDateTime(rdr["FechaUltimaValidacion"]) : (DateTime?)null,
                            MotivoContingencia = rdr["MotivoContingencia"] != DBNull.Value ? rdr["MotivoContingencia"].ToString() : null
                        };
                    }
                }
            }

            return new ConfiguracionSistema { IdConfiguracion = 1 };
        }

        public bool IsContingencyMode()
        {
            return GetConfiguracion().ModoContingencia;
        }

        public List<IntegridadError> GetErrors(bool activeOnly)
        {
            EnsureInfrastructure();
            var errors = new List<IntegridadError>();
            using (var cn = ConexionDAL.GetConnection())
            {
                var sql = "SELECT * FROM IntegridadError";
                if (activeOnly) sql += " WHERE Estado = @Estado";
                sql += " ORDER BY Fecha DESC";

                using (var cmd = new SqlCommand(sql, cn))
                {
                    if (activeOnly) cmd.Parameters.AddWithValue("@Estado", "Activo");
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read()) errors.Add(MapError(rdr));
                    }
                }
            }

            return errors;
        }

        public IntegrityValidationResult ValidateTable(string tableName)
        {
            EnsureInfrastructure();
            var result = new IntegrityValidationResult { TableName = tableName };
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                ValidateTable(cn, null, tableName, result);
                UpdateLastValidation(cn, null);
            }

            if (!result.IsValid)
            {
                PersistValidationErrors(result.Errors);
                SetContingency(true, "Se detectaron inconsistencias de integridad en " + tableName + ".");
            }
            return result;
        }

        public void EnsureTableIsValid(string tableName)
        {
            var result = ValidateTable(tableName);
            if (!result.IsValid)
            {
                SetContingency(true, "Se detectaron inconsistencias de integridad en " + tableName + ".");
                throw new InvalidOperationException("La aplicacion se encuentra temporalmente en mantenimiento debido a una verificacion de integridad.");
            }
        }

        public void EnsureAllTablesAreValid()
        {
            var result = ValidateAllAndPersist();
            if (!result.IsValid)
                throw new InvalidOperationException("La aplicacion se encuentra temporalmente en mantenimiento debido a una verificacion de integridad.");
        }

        public IntegrityValidationResult ValidateAll()
        {
            EnsureInfrastructure();
            var result = new IntegrityValidationResult();
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                foreach (var table in CriticalTables)
                {
                    ValidateTable(cn, null, table, result);
                }
                UpdateLastValidation(cn, null);
            }

            return result;
        }

        public IntegrityValidationResult ValidateAllAndPersist()
        {
            SafeLog("Sistema", "Inicio de validacion general de integridad.", 1);
            var result = ValidateAll();
            if (result.IsValid)
            {
                SafeLog("Sistema", "Validacion de integridad correcta.", 1);
                return result;
            }

            PersistValidationErrors(result.Errors);
            SetContingency(true, "Se detectaron inconsistencias de integridad.");
            SafeLog("Sistema", "Activacion del modo de contingencia por inconsistencias de integridad.", 4);
            return result;
        }

        public void RecalculateAll(int? adminUserId, string action)
        {
            EnsureInfrastructure();
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                using (var tran = cn.BeginTransaction())
                {
                    try
                    {
                        foreach (var table in CriticalTables)
                        {
                            RecalculateTable(cn, tran, table);
                        }

                        UpdateLastValidation(cn, tran);
                        tran.Commit();
                    }
                    catch
                    {
                        try { tran.Rollback(); } catch { }
                        SetContingency(true, "Error durante el recalculo de digitos verificadores.");
                        SafeLog("Sistema", "Falla grave durante recalculo de integridad.", 4);
                        throw;
                    }
                }
            }

            SafeLog("Sistema", "Recalculo correcto de DVH y DVV.", 1);
            TryResolveAfterValidation(adminUserId, action);
        }

        public IntegrityValidationResult TryResolveAfterValidation(int? adminUserId, string action)
        {
            var result = ValidateAll();
            if (!result.IsValid)
            {
                PersistValidationErrors(result.Errors);
                SetContingency(true, "Persisten inconsistencias de integridad.");
                return result;
            }

            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"UPDATE IntegridadError
SET Estado = @EstadoResuelto,
    IdUsuarioAdministrador = @IdUsuarioAdministrador,
    AccionTomada = @AccionTomada
WHERE Estado = @EstadoActivo", cn))
            {
                cmd.Parameters.AddWithValue("@EstadoResuelto", "Resuelto");
                cmd.Parameters.AddWithValue("@IdUsuarioAdministrador", adminUserId.HasValue ? (object)adminUserId.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@AccionTomada", string.IsNullOrWhiteSpace(action) ? "Validacion correcta" : action);
                cmd.Parameters.AddWithValue("@EstadoActivo", "Activo");
                cn.Open();
                cmd.ExecuteNonQuery();
            }

            SetContingency(false, null);
            SafeLog("Sistema", "Salida del modo de contingencia luego de validacion correcta.", 1);
            return result;
        }

        public void UpdateRecordAndTableDVV(SqlConnection cn, SqlTransaction tran, string tableName, int id)
        {
            UpdateRecordDVH(cn, tran, tableName, id);
            UpdateTableDVV(cn, tran, tableName);
        }

        public void UpdateTableDVV(SqlConnection cn, SqlTransaction tran, string tableName)
        {
            using (var cmd = new SqlCommand(@"MERGE IntegridadDVV AS target
USING (SELECT @NombreTabla AS NombreTabla, ISNULL(SUM(CONVERT(BIGINT, DVH)), 0) AS ValorDVV FROM " + tableName + @") AS source
ON target.NombreTabla = source.NombreTabla
WHEN MATCHED THEN UPDATE SET ValorDVV = source.ValorDVV, FechaCalculo = @FechaCalculo
WHEN NOT MATCHED THEN INSERT (NombreTabla, ValorDVV, FechaCalculo) VALUES (source.NombreTabla, source.ValorDVV, @FechaCalculo);", cn, tran))
            {
                cmd.Parameters.AddWithValue("@NombreTabla", tableName);
                cmd.Parameters.AddWithValue("@FechaCalculo", DateTime.Now);
                cmd.ExecuteNonQuery();
            }
        }

        public void UpdateRecordDVH(SqlConnection cn, SqlTransaction tran, string tableName, int id)
        {
            var dvh = CalculateStoredRowDVH(cn, tran, tableName, id);
            using (var cmd = new SqlCommand("UPDATE " + tableName + " SET DVH = @DVH WHERE " + GetPk(tableName) + " = @Id", cn, tran))
            {
                cmd.Parameters.AddWithValue("@DVH", dvh);
                cmd.Parameters.AddWithValue("@Id", id);
                cmd.ExecuteNonQuery();
            }

            UpdateRecordSnapshot(cn, tran, tableName, id, dvh);
        }

        private void UpdateRecordSnapshot(SqlConnection cn, SqlTransaction tran, string tableName, int id, int dvh)
        {
            using (var cmd = new SqlCommand(@"MERGE IntegridadRegistro AS target
USING (SELECT @NombreTabla AS NombreTabla, @IdRegistro AS IdRegistro) AS source
ON target.NombreTabla = source.NombreTabla AND target.IdRegistro = source.IdRegistro
WHEN MATCHED THEN UPDATE SET ValorDVH = @ValorDVH, FechaCalculo = @FechaCalculo
WHEN NOT MATCHED THEN INSERT (NombreTabla, IdRegistro, ValorDVH, FechaCalculo) VALUES (@NombreTabla, @IdRegistro, @ValorDVH, @FechaCalculo);", cn, tran))
            {
                cmd.Parameters.AddWithValue("@NombreTabla", tableName);
                cmd.Parameters.AddWithValue("@IdRegistro", id.ToString(CultureInfo.InvariantCulture));
                cmd.Parameters.AddWithValue("@ValorDVH", dvh);
                cmd.Parameters.AddWithValue("@FechaCalculo", DateTime.Now);
                cmd.ExecuteNonQuery();
            }
        }

        public void EnsureInfrastructure()
        {
            using (var cn = ConexionDAL.GetConnection())
            {
                cn.Open();
                EnsureInfrastructure(cn, null);
            }
        }

        public bool CanAccessDuringContingency(string pageName, Usuario user)
        {
            if (!IsContingencyMode()) return true;

            pageName = NormalizePageName(pageName);
            var allowedForAll = new[] { "Login.aspx", "Logout.aspx", "Mantenimiento.aspx" };
            if (allowedForAll.Any(p => string.Equals(p, pageName, StringComparison.OrdinalIgnoreCase))) return true;

            if (user != null && string.Equals(user.Rol, "Administrador", StringComparison.OrdinalIgnoreCase))
            {
                var allowedAdmin = new[] { "GestionIntegridad.aspx", "Backup.aspx", "Bitacora.aspx" };
                return allowedAdmin.Any(p => string.Equals(p, pageName, StringComparison.OrdinalIgnoreCase));
            }

            return false;
        }

        public string NormalizePageName(string pageName)
        {
            if (string.IsNullOrWhiteSpace(pageName)) return string.Empty;

            pageName = pageName.Replace("\\", "/").Trim();
            var slashIndex = pageName.LastIndexOf('/');
            if (slashIndex >= 0) pageName = pageName.Substring(slashIndex + 1);
            if (pageName.StartsWith("~", StringComparison.Ordinal)) pageName = pageName.Substring(1);
            if (pageName.StartsWith("/", StringComparison.Ordinal)) pageName = pageName.Substring(1);
            if (pageName.Length > 0 && pageName.IndexOf(".", StringComparison.Ordinal) < 0) pageName += ".aspx";
            return pageName;
        }

        public bool RedirectIfContingencyActive(Usuario user)
        {
            if (!IsContingencyMode()) return false;

            var context = HttpContext.Current;
            if (context == null) return false;

            var target = user != null && string.Equals(user.Rol, "Administrador", StringComparison.OrdinalIgnoreCase)
                ? "~/GestionIntegridad.aspx"
                : "~/Mantenimiento.aspx";

            context.Response.Redirect(target, false);
            context.ApplicationInstance.CompleteRequest();
            return true;
        }

        private void ValidateTable(SqlConnection cn, SqlTransaction tran, string tableName, IntegrityValidationResult result)
        {
            string pk = GetPk(tableName);
            var actualRows = new Dictionary<string, Tuple<int, int>>();
            using (var cmd = new SqlCommand("SELECT * FROM " + tableName, cn, tran))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    int id = Convert.ToInt32(rdr[pk]);
                    int stored = rdr["DVH"] != DBNull.Value ? Convert.ToInt32(rdr["DVH"]) : -1;
                    int calculated = CalculateDVHFromReader(tableName, rdr);
                    actualRows[id.ToString(CultureInfo.InvariantCulture)] = Tuple.Create(stored, calculated);
                }
            }

            var expectedRows = GetExpectedRows(cn, tran, tableName);
            bool hasRecordErrors = false;
            foreach (var actual in actualRows)
            {
                int expectedDvh;
                var stored = actual.Value.Item1;
                var calculated = actual.Value.Item2;
                if (!expectedRows.TryGetValue(actual.Key, out expectedDvh))
                {
                    hasRecordErrors = true;
                    AddIntegrityError(result, tableName, actual.Key, "INSERT", string.Empty, calculated.ToString(CultureInfo.InvariantCulture));
                }
                else if (expectedDvh != calculated || stored != calculated)
                {
                    hasRecordErrors = true;
                    AddIntegrityError(result, tableName, actual.Key, "UPDATE", expectedDvh.ToString(CultureInfo.InvariantCulture), calculated.ToString(CultureInfo.InvariantCulture));
                }
            }

            foreach (var expected in expectedRows)
            {
                if (!actualRows.ContainsKey(expected.Key))
                {
                    hasRecordErrors = true;
                    AddIntegrityError(result, tableName, expected.Key, "DELETE", expected.Value.ToString(CultureInfo.InvariantCulture), string.Empty);
                }
            }

            long storedDvv = 0;
            using (var cmd = new SqlCommand("SELECT ValorDVV FROM IntegridadDVV WHERE NombreTabla = @NombreTabla", cn, tran))
            {
                cmd.Parameters.AddWithValue("@NombreTabla", tableName);
                var value = cmd.ExecuteScalar();
                storedDvv = value != null && value != DBNull.Value ? Convert.ToInt64(value) : long.MinValue;
            }

            long calculatedDvv;
            using (var cmd = new SqlCommand("SELECT ISNULL(SUM(CONVERT(BIGINT, DVH)), 0) FROM " + tableName, cn, tran))
            {
                calculatedDvv = Convert.ToInt64(cmd.ExecuteScalar());
            }

            if (storedDvv != calculatedDvv && !hasRecordErrors)
            {
                result.Errors.Add(new IntegridadError
                {
                    Fecha = DateTime.Now,
                    TipoError = "DVV",
                    TipoOperacion = "UPDATE",
                    NombreTabla = tableName,
                    IdRegistroAfectado = null,
                    ValorEsperado = storedDvv == long.MinValue ? string.Empty : storedDvv.ToString(CultureInfo.InvariantCulture),
                    ValorCalculado = calculatedDvv.ToString(CultureInfo.InvariantCulture),
                    Estado = "Activo"
                });
            }
        }

        private Dictionary<string, int> GetExpectedRows(SqlConnection cn, SqlTransaction tran, string tableName)
        {
            var rows = new Dictionary<string, int>();
            using (var cmd = new SqlCommand(@"SELECT IdRegistro, ValorDVH
FROM IntegridadRegistro
WHERE NombreTabla = @NombreTabla", cn, tran))
            {
                cmd.Parameters.AddWithValue("@NombreTabla", tableName);
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        rows[rdr["IdRegistro"].ToString()] = Convert.ToInt32(rdr["ValorDVH"]);
                    }
                }
            }

            return rows;
        }

        private void AddIntegrityError(IntegrityValidationResult result, string tableName, string idRegistro, string tipoOperacion, string valorEsperado, string valorCalculado)
        {
            result.Errors.Add(new IntegridadError
            {
                Fecha = DateTime.Now,
                TipoError = "DVH",
                TipoOperacion = tipoOperacion,
                NombreTabla = tableName,
                IdRegistroAfectado = idRegistro,
                ValorEsperado = valorEsperado,
                ValorCalculado = valorCalculado,
                Estado = "Activo"
            });
        }

        private void RecalculateTable(SqlConnection cn, SqlTransaction tran, string tableName)
        {
            var ids = new List<int>();
            using (var cmd = new SqlCommand("SELECT " + GetPk(tableName) + " FROM " + tableName, cn, tran))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read()) ids.Add(Convert.ToInt32(rdr[0]));
            }

            foreach (var id in ids)
            {
                UpdateRecordDVH(cn, tran, tableName, id);
            }

            UpdateTableDVV(cn, tran, tableName);
            using (var cmd = new SqlCommand(@"DELETE FROM IntegridadRegistro
WHERE NombreTabla = @NombreTabla
  AND IdRegistro NOT IN (SELECT CONVERT(NVARCHAR(100), " + GetPk(tableName) + @") FROM " + tableName + @")", cn, tran))
            {
                cmd.Parameters.AddWithValue("@NombreTabla", tableName);
                cmd.ExecuteNonQuery();
            }
        }

        private int CalculateStoredRowDVH(SqlConnection cn, SqlTransaction tran, string tableName, int id)
        {
            using (var cmd = new SqlCommand("SELECT * FROM " + tableName + " WHERE " + GetPk(tableName) + " = @Id", cn, tran))
            {
                cmd.Parameters.AddWithValue("@Id", id);
                using (var rdr = cmd.ExecuteReader())
                {
                    if (!rdr.Read()) throw new InvalidOperationException("No se encontro el registro para calcular DVH.");
                    return CalculateDVHFromReader(tableName, rdr);
                }
            }
        }

        private int CalculateDVHFromReader(string tableName, SqlDataReader rdr)
        {
            switch (tableName)
            {
                case "Usuarios":
                    return CalculateDVH(JoinFields(rdr["IdUsuario"], rdr["Nombre"], rdr["Email"], rdr["Rol"], rdr["Activo"], rdr["FechaAlta"]));
                case "Clientes":
                    return CalculateDVH(JoinFields(rdr["IdCliente"], rdr["IdUsuario"], rdr["Nombre"], rdr["Email"], rdr["Documento"], rdr["Telefono"], rdr["Direccion"], rdr["FechaAlta"], rdr["FechaActualizacion"]));
                case "Pasajeros":
                    return CalculateDVH(JoinFields(rdr["IdPasajero"], rdr["IdUsuario"], rdr["Nombre"], rdr["Apellido"], rdr["Email"], rdr["Documento"], rdr["Nacionalidad"], rdr["FechaNacimiento"], rdr["FechaAlta"], rdr["FechaActualizacion"]));
                case "Vuelos":
                    return CalculateDVH(JoinFields(rdr["IdVuelo"], rdr["Origen"], rdr["Destino"], rdr["FechaSalida"], rdr["HoraSalida"], rdr["Precio"], rdr["CuposDisponibles"], rdr["Activo"], rdr["FechaCreacion"], rdr["FechaActualizacion"]));
                case "ReservaCabecera":
                    return CalculateDVH(JoinFields(rdr["IdReservaCabecera"], rdr["IdCliente"], rdr["IdUsuarioCreador"], rdr["FechaReserva"], rdr["Estado"], rdr["MontoTotal"], rdr["FechaCreacion"], rdr["FechaActualizacion"], rdr["FechaCancelacion"], rdr["IdUsuarioCancela"]));
                case "ReservaDetalle":
                    return CalculateDVH(JoinFields(rdr["IdReservaDetalle"], rdr["IdReservaCabecera"], rdr["IdVuelo"], rdr["Cantidad"], rdr["PrecioUnitario"], rdr["SubTotal"], rdr["Estado"]));
                case "ReservaPasajero":
                    return CalculateDVH(JoinFields(rdr["IdReservaPasajero"], rdr["IdReservaCabecera"], rdr["IdPasajero"]));
                case "Bitacora":
                    return CalculateDVH(JoinFields(rdr["IdBitacora"], rdr["Fecha"], rdr["Usuario"], rdr["Accion"], rdr["Criticidad"], rdr["Pantalla"]));
                default:
                    throw new ArgumentException("Tabla no protegida: " + tableName);
            }
        }

        private void PersistValidationErrors(List<IntegridadError> errors)
        {
            foreach (var error in errors)
            {
                using (var cn = ConexionDAL.GetConnection())
                {
                    cn.Open();
                    if (ActiveErrorExists(cn, null, error)) continue;

                    using (var cmd = new SqlCommand(@"INSERT INTO IntegridadError
(Fecha, TipoError, TipoOperacion, NombreTabla, IdRegistroAfectado, ValorEsperado, ValorCalculado, Estado)
VALUES (@Fecha, @TipoError, @TipoOperacion, @NombreTabla, @IdRegistroAfectado, @ValorEsperado, @ValorCalculado, @Estado)", cn))
                    {
                        cmd.Parameters.AddWithValue("@Fecha", DateTime.Now);
                        cmd.Parameters.AddWithValue("@TipoError", error.TipoError);
                        cmd.Parameters.AddWithValue("@TipoOperacion", string.IsNullOrEmpty(error.TipoOperacion) ? (object)DBNull.Value : error.TipoOperacion);
                        cmd.Parameters.AddWithValue("@NombreTabla", error.NombreTabla);
                        cmd.Parameters.AddWithValue("@IdRegistroAfectado", string.IsNullOrEmpty(error.IdRegistroAfectado) ? (object)DBNull.Value : error.IdRegistroAfectado);
                        cmd.Parameters.AddWithValue("@ValorEsperado", string.IsNullOrEmpty(error.ValorEsperado) ? (object)DBNull.Value : error.ValorEsperado);
                        cmd.Parameters.AddWithValue("@ValorCalculado", string.IsNullOrEmpty(error.ValorCalculado) ? (object)DBNull.Value : error.ValorCalculado);
                        cmd.Parameters.AddWithValue("@Estado", "Activo");
                        cmd.ExecuteNonQuery();
                    }
                }

                var row = string.IsNullOrWhiteSpace(error.IdRegistroAfectado) ? "sin registro especifico" : "registro " + error.IdRegistroAfectado;
                SafeLog("Sistema", string.Format("Se detecto una inconsistencia {0} en la tabla {1}, {2}.", error.TipoError, error.NombreTabla, row), 4);
            }
        }

        private bool ActiveErrorExists(SqlConnection cn, SqlTransaction tran, IntegridadError error)
        {
            using (var cmd = new SqlCommand(@"SELECT COUNT(1) FROM IntegridadError
WHERE Estado = @Estado
  AND TipoError = @TipoError
  AND ISNULL(TipoOperacion, '') = ISNULL(@TipoOperacion, '')
  AND NombreTabla = @NombreTabla
  AND ISNULL(IdRegistroAfectado, '') = ISNULL(@IdRegistroAfectado, '')", cn, tran))
            {
                cmd.Parameters.AddWithValue("@Estado", "Activo");
                cmd.Parameters.AddWithValue("@TipoError", error.TipoError);
                cmd.Parameters.AddWithValue("@TipoOperacion", string.IsNullOrEmpty(error.TipoOperacion) ? (object)DBNull.Value : error.TipoOperacion);
                cmd.Parameters.AddWithValue("@NombreTabla", error.NombreTabla);
                cmd.Parameters.AddWithValue("@IdRegistroAfectado", string.IsNullOrEmpty(error.IdRegistroAfectado) ? (object)DBNull.Value : error.IdRegistroAfectado);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private void SetContingency(bool enabled, string reason)
        {
            EnsureInfrastructure();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand(@"UPDATE ConfiguracionSistema
SET ModoContingencia = @ModoContingencia,
    MotivoContingencia = @MotivoContingencia
WHERE IdConfiguracion = 1", cn))
            {
                cmd.Parameters.AddWithValue("@ModoContingencia", enabled);
                cmd.Parameters.AddWithValue("@MotivoContingencia", string.IsNullOrWhiteSpace(reason) ? (object)DBNull.Value : reason);
                cn.Open();
                cmd.ExecuteNonQuery();
            }
        }

        private bool HasAnyDVV()
        {
            EnsureInfrastructure();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM IntegridadDVV", cn))
            {
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private bool HasAnySnapshot()
        {
            EnsureInfrastructure();
            using (var cn = ConexionDAL.GetConnection())
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM IntegridadRegistro", cn))
            {
                cn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }

        private void UpdateLastValidation(SqlConnection cn, SqlTransaction tran)
        {
            using (var cmd = new SqlCommand(@"UPDATE ConfiguracionSistema
SET FechaUltimaValidacion = @FechaUltimaValidacion
WHERE IdConfiguracion = 1", cn, tran))
            {
                cmd.Parameters.AddWithValue("@FechaUltimaValidacion", DateTime.Now);
                cmd.ExecuteNonQuery();
            }
        }

        private void EnsureInfrastructure(SqlConnection cn, SqlTransaction tran)
        {
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('Usuarios', 'DVH') IS NULL ALTER TABLE Usuarios ADD DVH INT NOT NULL CONSTRAINT DF_Usuarios_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('Clientes', 'DVH') IS NULL ALTER TABLE Clientes ADD DVH INT NOT NULL CONSTRAINT DF_Clientes_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('Pasajeros', 'DVH') IS NULL ALTER TABLE Pasajeros ADD DVH INT NOT NULL CONSTRAINT DF_Pasajeros_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('Vuelos', 'DVH') IS NULL ALTER TABLE Vuelos ADD DVH INT NOT NULL CONSTRAINT DF_Vuelos_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('ReservaCabecera', 'DVH') IS NULL ALTER TABLE ReservaCabecera ADD DVH INT NOT NULL CONSTRAINT DF_ReservaCabecera_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('ReservaDetalle', 'DVH') IS NULL ALTER TABLE ReservaDetalle ADD DVH INT NOT NULL CONSTRAINT DF_ReservaDetalle_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('ReservaPasajero', 'DVH') IS NULL ALTER TABLE ReservaPasajero ADD DVH INT NOT NULL CONSTRAINT DF_ReservaPasajero_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('Bitacora', 'DVH') IS NULL ALTER TABLE Bitacora ADD DVH INT NOT NULL CONSTRAINT DF_Bitacora_DVH DEFAULT (0)");
            ExecuteNonQuery(cn, tran, @"IF OBJECT_ID('IntegridadDVV', 'U') IS NULL
CREATE TABLE IntegridadDVV
(
    IdIntegridadDVV INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreTabla NVARCHAR(100) NOT NULL UNIQUE,
    ValorDVV BIGINT NOT NULL,
    FechaCalculo DATETIME2(0) NOT NULL
)");
            ExecuteNonQuery(cn, tran, @"IF OBJECT_ID('IntegridadRegistro', 'U') IS NULL
CREATE TABLE IntegridadRegistro
(
    IdIntegridadRegistro INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreTabla NVARCHAR(100) NOT NULL,
    IdRegistro NVARCHAR(100) NOT NULL,
    ValorDVH INT NOT NULL,
    FechaCalculo DATETIME2(0) NOT NULL,
    CONSTRAINT UQ_IntegridadRegistro_TablaRegistro UNIQUE (NombreTabla, IdRegistro)
)");
            ExecuteNonQuery(cn, tran, @"IF OBJECT_ID('IntegridadError', 'U') IS NULL
CREATE TABLE IntegridadError
(
    IdError INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Fecha DATETIME2(0) NOT NULL,
    TipoError NVARCHAR(10) NOT NULL,
    TipoOperacion NVARCHAR(20) NULL,
    NombreTabla NVARCHAR(100) NOT NULL,
    IdRegistroAfectado NVARCHAR(100) NULL,
    ValorEsperado NVARCHAR(100) NULL,
    ValorCalculado NVARCHAR(100) NULL,
    Estado NVARCHAR(20) NOT NULL,
    IdUsuarioAdministrador INT NULL,
    AccionTomada NVARCHAR(500) NULL
)");
            ExecuteNonQuery(cn, tran, @"IF COL_LENGTH('IntegridadError', 'TipoOperacion') IS NULL ALTER TABLE IntegridadError ADD TipoOperacion NVARCHAR(20) NULL");
            ExecuteNonQuery(cn, tran, @"IF OBJECT_ID('ConfiguracionSistema', 'U') IS NULL
CREATE TABLE ConfiguracionSistema
(
    IdConfiguracion INT NOT NULL PRIMARY KEY,
    ModoContingencia BIT NOT NULL,
    FechaUltimaValidacion DATETIME2(0) NULL,
    MotivoContingencia NVARCHAR(500) NULL
)");
            ExecuteNonQuery(cn, tran, @"IF NOT EXISTS (SELECT 1 FROM ConfiguracionSistema WHERE IdConfiguracion = 1)
INSERT INTO ConfiguracionSistema (IdConfiguracion, ModoContingencia, FechaUltimaValidacion, MotivoContingencia)
VALUES (1, 0, NULL, NULL)");
        }

        private void ExecuteNonQuery(SqlConnection cn, SqlTransaction tran, string sql)
        {
            using (var cmd = new SqlCommand(sql, cn, tran))
            {
                cmd.ExecuteNonQuery();
            }
        }

        private string GetPk(string tableName)
        {
            switch (tableName)
            {
                case "Usuarios": return "IdUsuario";
                case "Clientes": return "IdCliente";
                case "Pasajeros": return "IdPasajero";
                case "Vuelos": return "IdVuelo";
                case "ReservaCabecera": return "IdReservaCabecera";
                case "ReservaDetalle": return "IdReservaDetalle";
                case "ReservaPasajero": return "IdReservaPasajero";
                case "Bitacora": return "IdBitacora";
                default: throw new ArgumentException("Tabla no protegida: " + tableName);
            }
        }

        private IntegridadError MapError(SqlDataReader rdr)
        {
            return new IntegridadError
            {
                IdError = Convert.ToInt32(rdr["IdError"]),
                Fecha = Convert.ToDateTime(rdr["Fecha"]),
                TipoError = rdr["TipoError"].ToString(),
                TipoOperacion = rdr["TipoOperacion"] != DBNull.Value ? rdr["TipoOperacion"].ToString() : null,
                NombreTabla = rdr["NombreTabla"].ToString(),
                IdRegistroAfectado = rdr["IdRegistroAfectado"] != DBNull.Value ? rdr["IdRegistroAfectado"].ToString() : null,
                ValorEsperado = rdr["ValorEsperado"] != DBNull.Value ? rdr["ValorEsperado"].ToString() : null,
                ValorCalculado = rdr["ValorCalculado"] != DBNull.Value ? rdr["ValorCalculado"].ToString() : null,
                Estado = rdr["Estado"].ToString(),
                IdUsuarioAdministrador = rdr["IdUsuarioAdministrador"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuarioAdministrador"]) : (int?)null,
                AccionTomada = rdr["AccionTomada"] != DBNull.Value ? rdr["AccionTomada"].ToString() : null
            };
        }

        private string JoinFields(params object[] values)
        {
            return string.Join("|", values.Select(Normalize));
        }

        private string Normalize(object value)
        {
            if (value == null || value == DBNull.Value) return string.Empty;
            if (value is bool) return (bool)value ? "1" : "0";
            if (value is DateTime) return ((DateTime)value).ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture);
            if (value is TimeSpan) return ((TimeSpan)value).ToString(@"hh\:mm\:ss", CultureInfo.InvariantCulture);
            if (value is decimal) return ((decimal)value).ToString(CultureInfo.InvariantCulture);
            if (value is double) return ((double)value).ToString(CultureInfo.InvariantCulture);
            if (value is float) return ((float)value).ToString(CultureInfo.InvariantCulture);
            if (value is int || value is long || value is short || value is byte) return Convert.ToString(value, CultureInfo.InvariantCulture);
            return value.ToString().Trim();
        }

        private void SafeLog(string user, string action, int criticality)
        {
            try
            {
                using (var cn = ConexionDAL.GetConnection())
                {
                    cn.Open();
                    using (var tran = cn.BeginTransaction())
                    {
                        try
                        {
                            int id;
                            using (var cmd = new SqlCommand(@"INSERT INTO Bitacora (Fecha, Usuario, Accion, Criticidad, Pantalla, DVH)
VALUES (@Fecha, @Usuario, @Accion, @Criticidad, @Pantalla, 0);
SELECT SCOPE_IDENTITY();", cn, tran))
                            {
                                cmd.Parameters.AddWithValue("@Fecha", DateTime.Now);
                                cmd.Parameters.AddWithValue("@Usuario", user ?? "Sistema");
                                cmd.Parameters.AddWithValue("@Accion", action ?? string.Empty);
                                cmd.Parameters.AddWithValue("@Criticidad", criticality);
                                cmd.Parameters.AddWithValue("@Pantalla", "Control de Integridad");
                                id = Convert.ToInt32(cmd.ExecuteScalar());
                            }

                            UpdateRecordAndTableDVV(cn, tran, "Bitacora", id);
                            tran.Commit();
                        }
                        catch
                        {
                            try { tran.Rollback(); } catch { }
                            throw;
                        }
                    }
                }
            }
            catch
            {
                // Evita recursividad si la bitacora no esta disponible.
            }
        }
    }
}
