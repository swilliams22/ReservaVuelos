param([string]$Servidor = '.')
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$output = Join-Path $PSScriptRoot '.artifacts'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$database = 'ReservaVuelosAuthTest_' + [Guid]::NewGuid().ToString('N')
if ($database -notmatch '^ReservaVuelosAuthTest_[a-f0-9]{32}$') { throw 'Nombre de prueba inválido.' }
$schema = [IO.File]::ReadAllText((Join-Path $repo 'ReservaVuelos/SQL/ReservaVuelos.sql')).Replace('ReservaVuelosDB', $database)
$schemaPath = Join-Path $output 'schema.sql'
[IO.File]::WriteAllText($schemaPath, $schema, [Text.UTF8Encoding]::new($false))
try {
    & sqlcmd -S $Servidor -E -b -i $schemaPath -o (Join-Path $output 'schema.log')
    if ($LASTEXITCODE -ne 0) { throw "Falló el esquema. Ver tests/.artifacts/schema.log" }
    # También verifica que la migración se pueda repetir sin reponer permisos revocados.
    $migration = [IO.File]::ReadAllText((Join-Path $repo 'ReservaVuelos/SQL/MigracionPermisosComposite.sql')).Replace('ReservaVuelosDB', $database)
    $migrationPath = Join-Path $output 'migration.sql'
    [IO.File]::WriteAllText($migrationPath, $migration, [Text.UTF8Encoding]::new($false))
    & sqlcmd -S $Servidor -E -b -i $migrationPath -o (Join-Path $output 'migration.log')
    if ($LASTEXITCODE -ne 0) { throw 'Falló la reejecución de la migración.' }
    Copy-Item -LiteralPath (Join-Path $repo 'ReservaVuelos/bin/ReservaVuelos.dll') -Destination $output -Force
    $exe = Join-Path $output 'AutorizacionTests.exe'
    $assembly = Join-Path $output 'ReservaVuelos.dll'
    & "$env:WINDIR/Microsoft.NET/Framework64/v4.0.30319/csc.exe" /nologo /out:$exe /r:System.Web.dll /r:System.Web.Services.dll /r:System.Data.dll /r:System.Configuration.dll /r:$assembly (Join-Path $PSScriptRoot 'AutorizacionTests.cs')
    if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación de las pruebas.' }
    $cs = [System.Security.SecurityElement]::Escape("Data Source=$Servidor;Initial Catalog=$database;Integrated Security=True;Encrypt=False")
    $testKey = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('0123456789abcdef0123456789abcdef'))
    # Clave exclusiva del fixture; no copia secretos de la configuración de la aplicación.
    [IO.File]::WriteAllText(($exe+'.config'), '<configuration><appSettings><add key="EncryptionKey" value="'+$testKey+'" /></appSettings><connectionStrings><add name="ReservaVuelosConnectionString" connectionString="'+$cs+'" /></connectionStrings></configuration>')
    $env:AUTH_SOURCE = Join-Path $repo 'ReservaVuelos'
    & $exe
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas de autorización.' }
} finally {
    # El único DROP se dirige a la base temporal de nombre validado arriba.
    & sqlcmd -S $Servidor -E -b -Q "IF DB_ID(N'$database') IS NOT NULL BEGIN ALTER DATABASE [$database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$database]; END" -o (Join-Path $output 'cleanup.log')
    if ($LASTEXITCODE -ne 0) { Write-Warning "No se pudo eliminar la base temporal $database" }
    Remove-Item Env:AUTH_SOURCE -ErrorAction SilentlyContinue
}
