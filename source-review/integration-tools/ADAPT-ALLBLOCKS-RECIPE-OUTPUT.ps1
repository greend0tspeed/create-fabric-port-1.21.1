$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/AllBlocks.java'
$changesPath = Join-Path $root 'port-changes.json'
$from = '.save(p, Create.asResource('
$to = '.save(p.getCallback(), Create.asResource('

$text = [IO.File]::ReadAllText($sourcePath)
$count = ([regex]::Matches($text, [regex]::Escape($from))).Count
if ($count -ne 5) { throw "Expected five Create 6 logistics recipe output calls, found $count" }
[IO.File]::WriteAllText($sourcePath, $text.Replace($from, $to), [Text.UTF8Encoding]::new($false))

$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object { $_.path -eq 'AllBlocks.java' }
$entry.changes = @($entry.changes) + [pscustomobject]@{ from = $from; to = $to }
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Adapted five logistics recipes to the 1.21.1 Registrate RecipeOutput callback.'
