$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$donorRoot = Join-Path (Split-Path $root) 'full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create'
$lockPath = Join-Path $root 'fabric-reference-lock.json'
$changesPath = Join-Path $root 'port-changes.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json

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

function Restore-AdaptedSource([string]$path, [object[]]$adaptations, [string]$status) {
    $relative = "src/main/java/com/simibubi/create/$path"
    $donor = Join-Path $donorRoot $path
    $reference = Join-Path $root "fabric-reference/$relative"
    $source = Join-Path $root "source/fabric/$relative"
    New-Item -ItemType Directory -Force (Split-Path $reference) | Out-Null
    New-Item -ItemType Directory -Force (Split-Path $source) | Out-Null
    Copy-Item -LiteralPath $donor -Destination $reference
    $text = [IO.File]::ReadAllText($reference)
    foreach ($adaptation in $adaptations) {
        if (-not $text.Contains($adaptation.from)) { throw "$path anchor missing: $($adaptation.from)" }
        $text = $text.Replace($adaptation.from, $adaptation.to)
    }
    [IO.File]::WriteAllText($source, $text, [Text.UTF8Encoding]::new($false))
    if (-not ($lock.files | Where-Object path -eq $relative)) {
        $lock.files = @($lock.files) + [pscustomobject]@{ path = $relative; gitBlob = Get-GitBlobHash $reference }
    }
    if (-not ($manifest.files | Where-Object path -eq $path)) {
        $manifest.files = @($manifest.files) + [pscustomobject]@{ path = $path; sourceRoot = 'fabric-reference'; changes = $adaptations; status = $status }
    }
    $argument = '"' + ($source.Replace('\', '/')) + '"'
    $argsPath = Join-Path $root 'integration-compile.args'
    $argsText = [IO.File]::ReadAllText($argsPath)
    if (-not $argsText.Contains($argument)) {
        [IO.File]::AppendAllText($argsPath, "`r`n$argument", [Text.UTF8Encoding]::new($false))
    }
}

$destinationChanges = @(
    [pscustomobject]@{ from = 'net.createmod.catnip.data.IntAttached'; to = 'com.simibubi.create.foundation.utility.IntAttached' },
    [pscustomobject]@{ from = 'io.github.fabricators_of_create.porting_lib.mixin.accessors.client.accessor.'; to = 'io.github.fabricators_of_create.porting_lib_ufo.mixin.accessors.client.accessor.' }
)
Restore-AdaptedSource 'content/trains/schedule/DestinationSuggestions.java' $destinationChanges 'Original Create 6 address suggestion matching, cursor handling, anchoring and empty-state API restored; utility/accessor namespaces adapted to the Fabric baseline.'

$helperChanges = @(
    [pscustomobject]@{ from = 'net.createmod.catnip.data.IntAttached'; to = 'com.simibubi.create.foundation.utility.IntAttached' }
)
Restore-AdaptedSource 'content/logistics/AddressEditBoxHelper.java' $helperChanges 'Original Create 6 nearby/player Clipboard address collection restored; IntAttached namespace adapted to the Fabric baseline.'

$addressPath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/AddressEditBox.java'
$addressChanges = @(
    [pscustomobject]@{ from = 'moveCursorToEnd();'; to = 'moveCursorToEnd(false);' },
    [pscustomobject]@{
        from = "public boolean mouseScrolled(double pMouseX, double pMouseY, double pDelta) {`n`t`tif (destinationSuggestions.mouseScrolled(Mth.clamp(pDelta, -1.0D, 1.0D)))`n`t`t`treturn true;`n`t`treturn super.mouseScrolled(pMouseX, pMouseY, pDelta);"
        to = "public boolean mouseScrolled(double pMouseX, double pMouseY, double pScrollX, double pScrollY) {`n`t`tif (destinationSuggestions.mouseScrolled(Mth.clamp(pScrollY, -1.0D, 1.0D)))`n`t`t`treturn true;`n`t`treturn super.mouseScrolled(pMouseX, pMouseY, pScrollX, pScrollY);"
    },
    [pscustomobject]@{ from = "`t@Override`n`tpublic void tick() {`n`t`tsuper.tick();"; to = "`tpublic void tick() {" }
)
$addressText = [IO.File]::ReadAllText($addressPath)
foreach ($adaptation in $addressChanges) {
    if (-not $addressText.Contains($adaptation.from)) { throw "AddressEditBox anchor missing: $($adaptation.from)" }
    $addressText = $addressText.Replace($adaptation.from, $adaptation.to)
}
[IO.File]::WriteAllText($addressPath, $addressText, [Text.UTF8Encoding]::new($false))
$addressEntry = $manifest.files | Where-Object path -eq 'content/logistics/AddressEditBox.java'
$addressEntry.changes = @($addressEntry.changes) + $addressChanges
$addressEntry.status = 'Original Create 6 address field and suggestion behavior retained; Minecraft 1.21.1 cursor, scroll and widget-tick API changes adapted.'

$lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8
Write-Output 'Restored address suggestion dependencies and adapted AddressEditBox to Minecraft 1.21.1.'
