$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$relative = 'foundation/gui/AllGuiTextures.java'
$path = Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$relative"
$text = [IO.File]::ReadAllText($path)
$from = 'HOTSLOT_ARROW("widgets", 24, 51, 20, 12), HOTSLOT("widgets", 0, 68, 22, 22),'
$to = 'HOTSLOT_ARROW("widgets", 24, 51, 20, 12), HOTSLOT_ARROW_BAD("widgets", 52, 51, 20, 15), HOTSLOT("widgets", 0, 68, 22, 22),'
if (-not $text.Contains($from)) { throw 'Hot-slot texture anchor missing.' }
$text = $text.Replace($from, $to)
$fromTrade = 'TRAIN_PROMPT("widgets", 0, 230, 256, 16),'
$toTrade = 'TRAIN_PROMPT("widgets", 0, 230, 256, 16), TRADE_OVERLAY("widgets", 128, 98, 96, 46),'
if (-not $text.Contains($fromTrade)) { throw 'Trade texture anchor missing.' }
$text = $text.Replace($fromTrade, $toTrade)
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq $relative
$entry.changes = @($entry.changes) + [pscustomobject]@{ from = $from; to = $to }, [pscustomobject]@{ from = $fromTrade; to = $toTrade }
$entry.status = 'Original Create 6 logistics textures and overlay regions retained with compatible GUI accessors.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
Write-Output 'Restored native logistics overlay texture regions.'
