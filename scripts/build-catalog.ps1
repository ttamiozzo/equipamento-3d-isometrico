<#
.SYNOPSIS
  Monta um catalogo (dashboard iso3d) com todos os modelos de uma ou mais pastas.
.DESCRIPTION
  Cada modelo vira um equipamento solto (sem rack), em grade de 4 colunas, com as placas de
  chassis modulares instaladas em todos os slots compativeis. O HTML gerado serve para conferir
  a biblioteca e para exportar a biblioteca do draw.io (botao "Baixar biblioteca" ou
  IsoDash.exportDrawioLibrary()).
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File build-catalog.ps1 -Out C:\pop\catalogo.html -ModelsDir C:\pop\models
#>
param(
  [Parameter(Mandatory = $true)][string]$Out,
  [string[]]$ModelsDir = @(),
  [string]$Title = 'Catálogo de modelos'
)
$ErrorActionPreference = 'Stop'
$skill = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$dirs = @($ModelsDir | ForEach-Object { (Resolve-Path $_).Path }) + @(Join-Path $skill 'assets\models')
$models = [ordered]@{}
foreach ($d in $dirs) {
  Get-ChildItem (Join-Path $d '*.json') | Sort-Object Name | ForEach-Object {
    $m = [System.IO.File]::ReadAllText($_.FullName, $utf8) | ConvertFrom-Json
    if ($m.id -and $m.size -and -not $models.Contains($m.id)) { $models[$m.id] = $m }
  }
}
$devices = @(); $i = 0; $x = 0; $y = 0; $rowH = 0
foreach ($id in $models.Keys) {
  $m = $models[$id]
  if ($i -gt 0 -and $i % 4 -eq 0) { $x = 0; $y += $rowH + 160; $rowH = 0 }
  $cards = [ordered]@{}
  if ($m.cards -and $m.slots) {
    foreach ($sl in $m.slots) {
      foreach ($cp in $m.cards.PSObject.Properties) {
        $acc = @($sl.accepts)
        if (-not $sl.accepts -or $acc -contains $cp.Value.role -or $acc -contains $cp.Name) { $cards["$($sl.id)"] = $cp.Name; break }
      }
    }
  }
  $devices += [ordered]@{ id = "m$i"; model = $id; name = $m.name; pos = @{ x = $x; y = $y; z = 0 }; cards = $cards }
  $x += [double]$m.size.w + 180
  if ([double]$m.size.h -gt $rowH) { $rowH = [double]$m.size.h }
  $i++
}
$dash = [ordered]@{ schema = 'iso3d/dashboard@1'; title = $Title; subtitle = "$($models.Count) modelos"; models = $models; racks = @(); devices = $devices; links = @() }
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("iso3d-catalogo-" + [guid]::NewGuid().ToString('N') + '.json')
[System.IO.File]::WriteAllText($tmp, ($dash | ConvertTo-Json -Depth 100), $utf8)
try { & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build.ps1') -Dashboard $tmp -Out $Out }
finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
Write-Host "modelos no catalogo: $($models.Count)"
