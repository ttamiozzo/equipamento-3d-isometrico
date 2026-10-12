<#
.SYNOPSIS
  Monta um dashboard iso3d (HTML unico) a partir de um JSON de dashboard.
.DESCRIPTION
  - Le o dashboard (schema iso3d/dashboard@1).
  - Para cada equipamento cujo modelo nao esta em "models", procura <id>.json, nesta ordem:
    pastas de -ModelsDir (relativas a pasta atual ou a pasta do dashboard), <pasta do dashboard>\models,
    e assets\models da skill.
  - Se faltar algum modelo, para com erro e nao grava o HTML.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File build.ps1 -Dashboard C:\pop\pop.json -Out C:\pop\pop.html
#>
param(
  [Parameter(Mandatory = $true)][string]$Dashboard,
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$ModelsDir = @()
)
$ErrorActionPreference = 'Stop'
$skill = Split-Path -Parent $PSScriptRoot
$dashPath = (Resolve-Path $Dashboard).Path
$dashDir = Split-Path -Parent $dashPath
$dirs = @()
foreach ($m in $ModelsDir) {
  if ([System.IO.Path]::IsPathRooted($m)) { $dirs += $m }
  else { $dirs += (Join-Path (Get-Location) $m); $dirs += (Join-Path $dashDir $m) }
}
$dirs += (Join-Path $dashDir 'models')
$dirs += (Join-Path $skill 'assets\models')
$utf8 = New-Object System.Text.UTF8Encoding($false)

$data = [System.IO.File]::ReadAllText($dashPath, $utf8) | ConvertFrom-Json
if (-not $data.models) { $data | Add-Member -NotePropertyName models -NotePropertyValue ([pscustomobject]@{}) -Force }
$missing = @()
foreach ($dev in @($data.devices)) {
  $id = $dev.model
  if (-not $id -or $data.models.PSObject.Properties[$id]) { continue }
  $found = $null
  foreach ($d in $dirs) { $f = Join-Path $d "$id.json"; if (Test-Path $f) { $found = (Resolve-Path $f).Path; break } }
  if ($found) {
    $m = [System.IO.File]::ReadAllText($found, $utf8) | ConvertFrom-Json
    $data.models | Add-Member -NotePropertyName $id -NotePropertyValue $m
    Write-Host "model embedded: $id <- $found"
  } else { $missing += $id }
}
if ($missing.Count) {
  Write-Host ("ERROR: models not found: " + (($missing | Select-Object -Unique) -join ', '))
  Write-Host ("searched in: " + ($dirs -join ' | '))
  exit 1
}

$json = $data | ConvertTo-Json -Depth 100 -Compress
$json = $json.Replace('</', '<\/')
$tpl = [System.IO.File]::ReadAllText((Join-Path $skill 'assets\template.html'), $utf8)
$title = if ($data.title) { [System.Net.WebUtility]::HtmlEncode([string]$data.title) } else { 'Mapa de Equipamentos' }
$html = $tpl.Replace('__ISO3D_DATA__', $json).Replace('<title>Mapa de Equipamentos</title>', "<title>$title</title>")
$outPath = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out)) }
[System.IO.File]::WriteAllText($outPath, $html, $utf8)
Write-Host "built: $outPath ($([math]::Round($html.Length / 1kb)) KB)"
