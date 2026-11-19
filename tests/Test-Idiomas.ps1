param([string]$Servidor = '.')
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$output = Join-Path $PSScriptRoot '.artifacts'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$assembly = Join-Path $repo 'ReservaVuelos\bin\ReservaVuelos.dll'
Copy-Item -LiteralPath $assembly -Destination (Join-Path $output 'ReservaVuelos.dll') -Force
$exe = Join-Path $output 'IdiomasTests.exe'
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /out:$exe /r:System.Web.dll /r:System.Data.dll /r:$assembly (Join-Path $PSScriptRoot 'IdiomasTests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación de las pruebas.' }
$cs = [System.Security.SecurityElement]::Escape("Data Source=$Servidor;Initial Catalog=ReservaVuelosDB;Integrated Security=True;Encrypt=False")
[IO.File]::WriteAllText(($exe+'.config'), '<configuration><connectionStrings><add name="ReservaVuelosConnectionString" connectionString="'+$cs+'" /></connectionStrings></configuration>')
& $exe
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas de idiomas.' }
