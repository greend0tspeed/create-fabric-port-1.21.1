$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/stockTicker/StockKeeperRequestScreen.java'
$changesPath = Join-Path $root 'port-changes.json'

$changes = @(
    [pscustomobject]@{
        from = 'import net.minecraft.client.renderer.LightTexture;'
        to = "import net.minecraft.client.renderer.LightTexture;`nimport net.minecraft.client.resources.sounds.SimpleSoundInstance;"
    },
    [pscustomobject]@{
        from = 'import net.minecraft.sounds.SoundEvents;'
        to = "import net.minecraft.sounds.SoundEvent;`nimport net.minecraft.sounds.SoundEvents;"
    },
    [pscustomobject]@{ from = 'menu.player.closeContainer();'; to = 'minecraft.player.closeContainer();' },
    [pscustomobject]@{
        from = "`tpublic void renderBackground(GuiGraphics graphics) {"
        to = "`tpublic void renderBackground(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {"
    },
    [pscustomobject]@{
        from = "`t`tsuper.renderBackground(graphics);"
        to = "`t`tsuper.renderBackground(graphics, mouseX, mouseY, partialTick);"
    },
    [pscustomobject]@{
        from = 'public boolean mouseScrolled(double mouseX, double mouseY, double delta) {'
        to = 'public boolean mouseScrolled(double mouseX, double mouseY, double scrollX, double scrollY) {'
    },
    [pscustomobject]@{ from = 'addressBox.mouseScrolled(mouseX, mouseY, delta)'; to = 'addressBox.mouseScrolled(mouseX, mouseY, scrollX, scrollY)' },
    [pscustomobject]@{ from = 'Math.ceil(Math.abs(delta)) * -Math.signum(delta)'; to = 'Math.ceil(Math.abs(scrollY)) * -Math.signum(scrollY)' },
    [pscustomobject]@{ from = 'boolean remove = delta < 0;'; to = 'boolean remove = scrollY < 0;' },
    [pscustomobject]@{ from = 'Mth.ceil(Math.abs(delta)) * (hasControlDown() ? 10 : 1)'; to = 'Mth.ceil(Math.abs(scrollY)) * (hasControlDown() ? 10 : 1)' },
    [pscustomobject]@{
        from = "`tprivate void syncJEI() {"
        to = "`tprivate void playUiSound(SoundEvent sound, float volume, float pitch) {`n`t`tminecraft.getSoundManager().play(SimpleSoundInstance.forUI(sound, pitch, volume));`n`t}`n`n`tprivate void syncJEI() {"
    }
)

$text = [IO.File]::ReadAllText($path)
foreach ($change in $changes) {
    if (-not $text.Contains($change.from)) { throw "Request screen anchor missing: $($change.from)" }
    $text = $text.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))

$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq 'content/logistics/stockTicker/StockKeeperRequestScreen.java'
if (-not $entry) { throw 'StockKeeperRequestScreen.java is not tracked' }
$entry.changes = @($entry.changes) + $changes
$entry.status = 'Original request/order behavior retained; shared Minecraft 1.21.1 UI sound, background rendering, menu close and scrolling APIs adapted. Specialized renderer and optional integration compatibility remain pending.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Adapted shared Stock Keeper request-screen APIs to Minecraft 1.21.1.'
