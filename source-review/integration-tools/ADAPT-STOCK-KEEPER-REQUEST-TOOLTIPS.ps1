$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/stockTicker/StockKeeperRequestScreen.java'
$changesPath = Join-Path $root 'port-changes.json'

$changes = @(
    [pscustomobject]@{
        from = 'import net.minecraft.world.item.ItemStack;'
        to = "import net.minecraft.world.item.Item;`nimport net.minecraft.world.item.ItemStack;"
    },
    [pscustomobject]@{
        from = 'entry.stack.getTooltipLines(minecraft.player, TooltipFlag.NORMAL)'
        to = 'entry.stack.getTooltipLines(Item.TooltipContext.of(minecraft.player.level()), minecraft.player, TooltipFlag.NORMAL)'
    },
    [pscustomobject]@{ from = 'return CreateLang'; to = 'return Lang' }
)

$text = [IO.File]::ReadAllText($path)
foreach ($change in $changes) {
    if (-not $text.Contains($change.from)) { throw "Request tooltip anchor missing: $($change.from)" }
    $text = $text.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))

$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq 'content/logistics/stockTicker/StockKeeperRequestScreen.java'
if (-not $entry) { throw 'StockKeeperRequestScreen.java is not tracked' }
$entry.changes = @($entry.changes) + $changes
$entry.status = 'Original request/order behavior retained; shared Minecraft 1.21.1 UI and tooltip APIs adapted. Clipboard amount data, specialized renderer and optional integration compatibility remain pending.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Adapted Stock Keeper request-screen tooltip and translation APIs.'
