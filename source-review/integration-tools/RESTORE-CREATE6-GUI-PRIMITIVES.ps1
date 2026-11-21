$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$donorRoot = Join-Path (Split-Path $root) 'full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create'

function Get-GitBlobHash([string]$path) {
    $bytes = [IO.File]::ReadAllBytes($path)
    $prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
    $data = New-Object byte[] ($prefix.Length + $bytes.Length)
    [Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
    [Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

$changesPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$lockPath = Join-Path $root 'fabric-reference-lock.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json

$texturesPath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/foundation/gui/AllGuiTextures.java'
$textureChanges = @(
    [pscustomobject]@{
        from = 'BUTTON("widgets", 18, 18), BUTTON_HOVER("widgets", 18, 0, 18, 18), BUTTON_DOWN("widgets", 36, 0, 18, 18),'
        to = 'BUTTON("widgets", 18, 18), BUTTON_HOVER("widgets", 18, 0, 18, 18), BUTTON_DOWN("widgets", 36, 0, 18, 18), BUTTON_GREEN("widgets", 72, 0, 18, 18), BUTTON_DISABLED("widgets", 90, 0, 18, 18),'
    },
    [pscustomobject]@{
        from = "`t@Environment(EnvType.CLIENT)`r`n`tpublic void bind() {"
        to = "`tpublic int getStartX() { return startX; }`r`n`tpublic int getStartY() { return startY; }`r`n`tpublic int getWidth() { return width; }`r`n`tpublic int getHeight() { return height; }`r`n`r`n`t@Environment(EnvType.CLIENT)`r`n`tpublic void bind() {"
    }
)
$textureText = [IO.File]::ReadAllText($texturesPath)
foreach ($change in $textureChanges) {
    if (-not $textureText.Contains($change.from)) { throw "AllGuiTextures anchor missing: $($change.from)" }
    $textureText = $textureText.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($texturesPath, $textureText, [Text.UTF8Encoding]::new($false))
$textureEntry = $manifest.files | Where-Object path -eq 'foundation/gui/AllGuiTextures.java'
$textureEntry.changes = @($textureEntry.changes) + $textureChanges
$textureEntry.status = 'Original Create 6 logistics textures retained; official dimension accessors and green/disabled widget regions restored for GUI compatibility.'

$iconPath = 'foundation/gui/widget/IconButton.java'
$relative = "src/main/java/com/simibubi/create/$iconPath"
$donor = Join-Path $donorRoot $iconPath
$reference = Join-Path $root "fabric-reference/$relative"
$source = Join-Path $root "source/fabric/$relative"
New-Item -ItemType Directory -Force (Split-Path $reference) | Out-Null
New-Item -ItemType Directory -Force (Split-Path $source) | Out-Null
Copy-Item $donor $reference
$iconChanges = @(
    [pscustomobject]@{ from = 'net.createmod.catnip.gui.element.ScreenElement'; to = 'com.simibubi.create.foundation.gui.element.ScreenElement' },
    [pscustomobject]@{ from = 'net.createmod.catnip.gui.widget.AbstractSimiWidget'; to = 'com.simibubi.create.foundation.gui.widget.AbstractSimiWidget' }
)
$iconText = [IO.File]::ReadAllText($reference)
foreach ($change in $iconChanges) {
    if (-not $iconText.Contains($change.from)) { throw "IconButton anchor missing: $($change.from)" }
    $iconText = $iconText.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($source, $iconText, [Text.UTF8Encoding]::new($false))
if (-not ($lock.files | Where-Object path -eq $relative)) {
    $lock.files = @($lock.files) + [pscustomobject]@{ path = $relative; gitBlob = Get-GitBlobHash $reference }
}
if (-not ($manifest.files | Where-Object path -eq $iconPath)) {
    $manifest.files = @($manifest.files) + [pscustomobject]@{ path = $iconPath; sourceRoot = 'fabric-reference'; changes = $iconChanges; status = 'Original Create 6 green/disabled/pressed IconButton behavior restored; Catnip GUI types mapped to the Fabric baseline equivalents.' }
}
$argument = '"' + $source.Replace('\', '/') + '"'
$argsPath = Join-Path $root 'integration-compile.args'
$argsText = [IO.File]::ReadAllText($argsPath)
if (-not $argsText.Contains($argument)) { [IO.File]::AppendAllText($argsPath, "`r`n$argument", [Text.UTF8Encoding]::new($false)) }

$requesterPath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/redstoneRequester/RedstoneRequesterScreen.java'
$requesterChanges = @(
    [pscustomobject]@{ from = 'private EditBox addressBox;'; to = 'private AddressEditBox addressBox;' },
    [pscustomobject]@{
        from = "public boolean mouseScrolled(double mouseX, double mouseY, double pDelta) {"
        to = "public boolean mouseScrolled(double mouseX, double mouseY, double scrollX, double scrollY) {"
    },
    [pscustomobject]@{ from = 'addressBox.mouseScrolled(mouseX, mouseY, pDelta)'; to = 'addressBox.mouseScrolled(mouseX, mouseY, scrollX, scrollY)' },
    [pscustomobject]@{ from = 'Math.signum(pDelta)'; to = 'Math.signum(scrollY)' },
    [pscustomobject]@{ from = 'super.mouseScrolled(mouseX, mouseY, pDelta)'; to = 'super.mouseScrolled(mouseX, mouseY, scrollX, scrollY)' }
)
$requesterText = [IO.File]::ReadAllText($requesterPath)
foreach ($change in $requesterChanges) {
    if (-not $requesterText.Contains($change.from)) { throw "Requester screen anchor missing: $($change.from)" }
    $requesterText = $requesterText.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($requesterPath, $requesterText, [Text.UTF8Encoding]::new($false))
$requesterEntry = $manifest.files | Where-Object path -eq 'content/logistics/redstoneRequester/RedstoneRequesterScreen.java'
$requesterEntry.changes = @($requesterEntry.changes) + $requesterChanges
$requesterEntry.status = 'Original requester layout, amount scrolling, address editing and partial-request state retained; shared Create 6 widgets restored and Minecraft 1.21.1 scroll signature adapted.'

$lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Restored Create 6 GUI texture/button primitives and adapted requester scrolling.'
