<#
.SYNOPSIS
  Servidor HTTP local para pre-visualizar dashboards iso3d e salvar exportacoes.
.DESCRIPTION
  - GET  /<arquivo>                 serve arquivos da pasta -Root.
  - POST /save?name=<arquivo>       grava o corpo da requisicao em -Root\<arquivo>.
    So aceita nomes simples terminados em .drawio, .json ou .svg (sem pastas).
  So escuta em localhost.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File serve.ps1 -Root C:\pop -Port 8765
  # no navegador (console ou ferramenta de JS):
  # await fetch('/save?name=pop.drawio', { method: 'POST', body: IsoDash.exportDrawio() })
#>
param([string]$Root = (Get-Location).Path, [int]$Port = 8765)
$Root = (Resolve-Path $Root).Path
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Host "serving $Root on http://localhost:$Port/"
$types = @{ '.html' = 'text/html; charset=utf-8'; '.json' = 'application/json; charset=utf-8'; '.js' = 'text/javascript'; '.svg' = 'image/svg+xml'; '.drawio' = 'application/xml' }
while ($l.IsListening) {
  $ctx = $l.GetContext(); $req = $ctx.Request; $res = $ctx.Response
  try {
    if ($req.HttpMethod -eq 'POST' -and $req.Url.AbsolutePath -eq '/save') {
      $name = $req.QueryString['name']
      if ($name -notmatch '^[\w.\-]+\.(drawio|json|svg)$') { $res.StatusCode = 400 }
      else {
        $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
        $body = $sr.ReadToEnd(); $sr.Close()
        [System.IO.File]::WriteAllText((Join-Path $Root $name), $body, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "saved $name ($($body.Length) chars)"
        $res.StatusCode = 200
      }
    } else {
      $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
      $f = [System.IO.Path]::GetFullPath((Join-Path $Root $path))
      if ($f.StartsWith($Root) -and (Test-Path $f -PathType Leaf)) {
        $b = [System.IO.File]::ReadAllBytes($f)
        $ext = [System.IO.Path]::GetExtension($f).ToLower()
        $res.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
        $res.OutputStream.Write($b, 0, $b.Length)
      } else { $res.StatusCode = 404 }
    }
  } catch { $res.StatusCode = 500 }
  $res.Close()
}
