$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/stockTicker/StockKeeperCategoryScreen.java'
$changesPath = Join-Path $root 'port-changes.json'

$changes = @(
    [pscustomobject]@{
        from = 'import net.minecraft.client.gui.components.Renderable;'
        to = "import net.minecraft.client.gui.components.Renderable;`nimport net.minecraft.client.resources.sounds.SimpleSoundInstance;`nimport net.minecraft.core.component.DataComponents;"
    },
    [pscustomobject]@{
        from = 'import net.minecraft.sounds.SoundEvents;'
        to = "import net.minecraft.sounds.SoundEvent;`nimport net.minecraft.sounds.SoundEvents;"
    },
    [pscustomobject]@{
        from = "`t`t`tstackInSlot.setHoverName(value.isBlank() ? null : Component.literal(value));"
        to = "`t`t`tif (value.isBlank())`n`t`t`t`tstackInSlot.remove(DataComponents.CUSTOM_NAME);`n`t`t`telse`n`t`t`t`tstackInSlot.set(DataComponents.CUSTOM_NAME, Component.literal(value));"
    },
    [pscustomobject]@{ from = '.hasCustomHoverName())'; to = '.has(DataComponents.CUSTOM_NAME))' },
    [pscustomobject]@{ from = 'partialTicks = minecraft.getFrameTime();'; to = 'partialTicks = minecraft.getTimer().getGameTimeDeltaPartialTick(true);' },
    [pscustomobject]@{ from = 'renderBackground(graphics);'; to = 'renderBackground(graphics, mouseX, mouseY, partialTicks);' },
    [pscustomobject]@{ from = 'editorEditBox.moveCursorToEnd();'; to = 'editorEditBox.moveCursorToEnd(false);' },
    [pscustomobject]@{
        from = 'public boolean mouseScrolled(double pMouseX, double pMouseY, double pDelta) {'
        to = 'public boolean mouseScrolled(double pMouseX, double pMouseY, double scrollX, double scrollY) {'
    },
    [pscustomobject]@{ from = 'chaseTarget -= pDelta * 12;'; to = 'chaseTarget -= scrollY * 12;' },
    [pscustomobject]@{ from = 'super.mouseScrolled(pMouseX, pMouseY, pDelta)'; to = 'super.mouseScrolled(pMouseX, pMouseY, scrollX, scrollY)' },
    [pscustomobject]@{
        from = "`tpublic Font getFont() {"
        to = "`tprivate void playUiSound(SoundEvent sound, float volume, float pitch) {`n`t`tminecraft.getSoundManager().play(SimpleSoundInstance.forUI(sound, pitch, volume));`n`t}`n`n`tpublic Font getFont() {"
    }
)

$text = [IO.File]::ReadAllText($path)
foreach ($change in $changes) {
    if (-not $text.Contains($change.from)) { throw "Category screen anchor missing: $($change.from)" }
    $text = $text.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))

$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq 'content/logistics/stockTicker/StockKeeperCategoryScreen.java'
if (-not $entry) { throw 'StockKeeperCategoryScreen.java is not tracked' }
$entry.changes = @($entry.changes) + $changes
$entry.status = 'Original category editor/order/refund/packet behavior retained; Minecraft 1.21.1 data components, timing, background rendering, scrolling and UI sound APIs adapted.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Adapted the original Stock Keeper category screen to Minecraft 1.21.1 APIs.'
