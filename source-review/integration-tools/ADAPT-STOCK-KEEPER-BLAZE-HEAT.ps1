$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/stockTicker/StockKeeperRequestScreen.java'
$changesPath = Join-Path $root 'port-changes.json'
$change = [pscustomobject]@{
    from = 'HeatLevel heatLevel = keeperBE.getHeatLevelForRender();'
    to = 'HeatLevel heatLevel = keeperBE.getHeatLevelFromBlock();'
}
$text = [IO.File]::ReadAllText($path)
if (-not $text.Contains($change.from)) { throw 'Blaze heat-level anchor missing' }
$text = $text.Replace($change.from, $change.to)
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq 'content/logistics/stockTicker/StockKeeperRequestScreen.java'
$entry.changes = @($entry.changes) + $change
$entry.status = 'Original request/order behavior retained; Blaze heat state uses the Fabric baseline renderer-equivalent public accessor. Protected animation/goggle access and logistics-hat rendering remain pending.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Adapted Stock Keeper Blaze heat lookup to the Fabric renderer-equivalent accessor.'
