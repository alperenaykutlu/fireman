$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env'
if (-not (Test-Path -LiteralPath $envFile)) {
  throw 'Root .env is missing. Copy .env.example to .env and edit API_BASE_URL first.'
}

$apiLine = Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^\s*API_BASE_URL=' } | Select-Object -First 1
if (-not $apiLine) { throw 'API_BASE_URL is missing from .env.' }
$apiBaseUrl = ($apiLine -split '=', 2)[1].Trim()
if (-not $apiBaseUrl -or $apiBaseUrl -match 'YOUR_|<') { throw 'Set API_BASE_URL in .env to the PC Wi-Fi IP reachable by your phone.' }

Push-Location (Join-Path $root 'client\fireman_flutter')
try { flutter run --dart-define="API_BASE_URL=$apiBaseUrl" }
finally { Pop-Location }
