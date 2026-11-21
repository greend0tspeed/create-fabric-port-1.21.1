$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/stockTicker/StockKeeperRequestScreen.java'
$changesPath = Join-Path $root 'port-changes.json'

$changes = @(
    [pscustomobject]@{
        from = "`t`t`tint entityX = x - 35 - entitySizeOffset;`n`t`t`tint entityY = y + windowHeight - 17;`n`t`t`tInventoryScreen.renderEntityInInventoryFollowsMouse(graphics, entityX, entityY, 50, entityX - mouseX,`n`t`t`t`tMth.clamp(entityY - mouseY, -50, 10), keeper);"
        to = "`t`t`tint entitySizeOffsetY = (int) (Math.max(0, keeper.getBoundingBox()`n`t`t`t`t.getYsize() - 1) * 25);`n`t`t`tint entityX = x - 35 - entitySizeOffset;`n`t`t`tint entityY = y + windowHeight - 47 - entitySizeOffsetY;`n`t`t`tInventoryScreen.renderEntityInInventoryFollowsMouse(graphics, entityX - 100, entityY - 100, entityX + 100,`n`t`t`t`tentityY + 100, 50, 0, mouseX, Mth.clamp(mouseY, entityY - 50, entityY + 10), keeper);"
    },
    [pscustomobject]@{
        from = '.rotateCentered(horizontalAngle + Mth.PI, Direction.UP)'
        to = '.rotateCentered(Direction.UP, horizontalAngle + Mth.PI)'
    }
)

$text = [IO.File]::ReadAllText($path)
foreach ($change in $changes) {
    if (-not $text.Contains($change.from)) { throw "Native entity-render anchor missing: $($change.from)" }
    $text = $text.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))

$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq 'content/logistics/stockTicker/StockKeeperRequestScreen.java'
if (-not $entry) { throw 'StockKeeperRequestScreen.java is not tracked' }
$entry.changes = @($entry.changes) + $changes
$entry.status = 'Original request/order behavior retained; official Create 6 Minecraft 1.21.1 keeper viewport and baseline Fabric buffer rotation signature adapted. Clipboard amount data, Blaze renderer access and optional integrations remain pending.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Adapted the official native keeper viewport and Fabric buffer rotation signature.'
