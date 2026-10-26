param([switch]$UsePostgres)

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env'
if (-not (Test-Path -LiteralPath $envFile)) {
  throw 'Root .env is missing. Copy .env.example to .env and edit the values first.'
}

foreach ($line in Get-Content -LiteralPath $envFile) {
  if ($line -match '^\s*#' -or $line -notmatch '^\s*([^=]+)=(.*)$') { continue }
  $name = $Matches[1].Trim()
  $value = $Matches[2].Trim()
  if ($name -eq 'API_BASE_URL' -or $name -like 'POSTGRES_*') { continue }
  [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}
if ($UsePostgres) { $env:Persistence__Provider = 'Postgres' }

Push-Location (Join-Path $root 'server\Fireman.Api')
try { dotnet run --no-launch-profile }
finally { Pop-Location }
