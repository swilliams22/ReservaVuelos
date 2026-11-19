param([string]$Servidor = '.', [ValidateRange(10,3600)][int]$TiempoMaximoSegundos = 300)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$localPath = Join-Path $PSScriptRoot 'local\tde'
New-Item -ItemType Directory -Force -Path $localPath | Out-Null

function Nueva-Clave {
    $bytes = New-Object byte[] 48
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return ([Convert]::ToBase64String($bytes) + 'aA1!')
}
function Consultar([string]$Sql) {
    $cmd = $conexion.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = $TiempoMaximoSegundos
    try {
        $tabla = New-Object System.Data.DataTable
        $reader = $cmd.ExecuteReader()
        try { $tabla.Load($reader) } finally { $reader.Dispose() }
        return ,$tabla
    } finally { $cmd.Dispose() }
}
function Contexto([string]$Clave, $Valor) {
    $cmd = $conexion.CreateCommand()
    $cmd.CommandText = 'EXEC sys.sp_set_session_context @key=@Clave, @value=@Valor;'
    [void]$cmd.Parameters.AddWithValue('@Clave', $Clave)
    [void]$cmd.Parameters.AddWithValue('@Valor', $Valor)
    try { [void]$cmd.ExecuteNonQuery() } finally { $cmd.Dispose() }
}

$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $Servidor
$builder['Initial Catalog'] = 'master'
$builder['Integrated Security'] = $true
$builder['Encrypt'] = $false
$conexion = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
try {
    $conexion.Open()
    $info = Consultar @'
SELECT CONVERT(int,SERVERPROPERTY('EngineEdition')) AS Edicion,
 CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) AS Version,
 CONVERT(nvarchar(4000),SERVERPROPERTY('InstanceDefaultBackupPath')) AS Carpeta,
 DB_ID(N'ReservaVuelosDB') AS Base,
 (SELECT encryption_state FROM sys.dm_database_encryption_keys WHERE database_id=DB_ID(N'ReservaVuelosDB')) AS Estado,
 (SELECT key_algorithm FROM sys.dm_database_encryption_keys WHERE database_id=DB_ID(N'ReservaVuelosDB')) AS Algoritmo,
 (SELECT key_length FROM sys.dm_database_encryption_keys WHERE database_id=DB_ID(N'ReservaVuelosDB')) AS Bits,
 CASE WHEN EXISTS(SELECT 1 FROM sys.symmetric_keys WHERE name=N'##MS_DatabaseMasterKey##') THEN 1 ELSE 0 END AS TieneMaestra;
'@
    $fila = $info.Rows[0]
    if ($fila.Base -is [DBNull]) { throw 'No existe ReservaVuelosDB. Instalar la base primero.' }
    if (-not ($fila.Edicion -eq 3 -or ($fila.Edicion -eq 2 -and $fila.Version -ge 15))) { throw 'La edicion de SQL Server no admite este flujo TDE.' }
    if ($fila.Estado -isnot [DBNull] -and ($fila.Algoritmo -ne 'AES' -or $fila.Bits -ne 256)) { throw 'La clave existente no es AES-256; revisar su configuracion.' }

    if ($fila.Estado -is [DBNull] -or $fila.Estado -eq 1) {
        $carpeta = [string]$fila.Carpeta
        if ([string]::IsNullOrWhiteSpace($carpeta)) { throw 'SQL Server no informo su carpeta de backups.' }
        $id = [Guid]::NewGuid().ToString('N')
        $certificado = $carpeta.TrimEnd('\') + '\ReservaVuelosTDE_' + $id + '.cer'
        $privada = $carpeta.TrimEnd('\') + '\ReservaVuelosTDE_' + $id + '.pvk'
        $claveMaestra = Nueva-Clave
        $claveRespaldo = Nueva-Clave
        $credenciales = [pscustomobject]@{
            Servidor = $Servidor
            Base = 'ReservaVuelosDB'
            Certificado = $certificado
            ClavePrivada = $privada
            ClaveMaestraCreadaPorEsteProceso = ($fila.TieneMaestra -eq 0)
            ClaveMaestraProtegida = (ConvertTo-SecureString $claveMaestra -AsPlainText -Force | ConvertFrom-SecureString)
            ClaveRespaldoProtegida = (ConvertTo-SecureString $claveRespaldo -AsPlainText -Force | ConvertFrom-SecureString)
        }
        # Guardar antes de crear claves. DPAPI protege las contrasenas para este usuario de Windows.
        $archivoCredenciales = Join-Path $localPath ($id + '.json')
        $credenciales | ConvertTo-Json | Set-Content -LiteralPath $archivoCredenciales -Encoding UTF8
        Contexto 'ReservaVuelos.ActivarTDE' 1
        Contexto 'ReservaVuelos.RespaldarTDE' 1
        Contexto 'ReservaVuelos.ClaveMaestraTDE' $claveMaestra
        Contexto 'ReservaVuelos.ClaveRespaldoTDE' $claveRespaldo
        Contexto 'ReservaVuelos.RutaCertificadoTDE' $certificado
        Contexto 'ReservaVuelos.RutaPrivadaTDE' $privada
        $sql = [IO.File]::ReadAllText((Join-Path $repo 'ReservaVuelos\SQL\ActivarTDE.sql'))
        foreach ($lote in [regex]::Split($sql, '(?im)^\s*GO\s*$')) {
            if ([string]::IsNullOrWhiteSpace($lote)) { continue }
            $cmd = $conexion.CreateCommand()
            $cmd.CommandText = $lote
            $cmd.CommandTimeout = $TiempoMaximoSegundos
            try { [void]$cmd.ExecuteNonQuery() } finally { $cmd.Dispose() }
        }
        Write-Host "Respaldo certificado: $certificado"
        Write-Host "Respaldo clave privada: $privada"
        Write-Host "Credenciales protegidas con DPAPI: $archivoCredenciales"
    }

    $reloj = [Diagnostics.Stopwatch]::StartNew()
    do {
        $estado = Consultar "SELECT DB_NAME(database_id) AS Base,encryption_state AS Estado,key_algorithm AS Algoritmo,key_length AS Bits,percent_complete AS Porcentaje FROM sys.dm_database_encryption_keys WHERE database_id=DB_ID(N'ReservaVuelosDB');"
        if ($estado.Rows.Count -ne 1) { throw 'No se encuentra la clave de cifrado de ReservaVuelosDB.' }
        $actual = $estado.Rows[0]
        if ($actual.Estado -eq 3) {
            Write-Host 'ReservaVuelosDB: CIFRADO COMPLETO (TDE AES-256, estado 3).'
            $estado | Format-Table -AutoSize
            break
        }
        if ($actual.Estado -notin @(2,4,6)) { throw "Estado de cifrado inesperado: $($actual.Estado)." }
        if ($reloj.Elapsed.TotalSeconds -ge $TiempoMaximoSegundos) { throw 'Se agoto la espera. SQL Server sigue procesando TDE; volver a ejecutar para consultar el resultado.' }
        Write-Host "Cifrando: $($actual.Porcentaje)%"
        Start-Sleep -Seconds 2
    } while ($true)
} finally {
    $conexion.Dispose()
    $claveMaestra = $null
    $claveRespaldo = $null
}

<#
-- CONSULTA PARA DEMOSTRAR EL CIFRADO TDE (copiar y ejecutar en SSMS).
-- Se deja comentada: no se ejecuta con el script.
SELECT
    DB_NAME(database_id) AS BaseDeDatos,
    CASE encryption_state
        WHEN 2 THEN 'Cifrado en curso'
        WHEN 3 THEN 'Cifrado completo'
        ELSE 'Otro estado'
    END AS Estado,
    key_algorithm AS Algoritmo,
    key_length AS Bits
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID(N'ReservaVuelosDB');
-- Resultado esperado: ReservaVuelosDB | Cifrado completo | AES | 256.
#>
