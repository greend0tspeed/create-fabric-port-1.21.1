$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$donor = Join-Path (Split-Path $root) 'full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create/content/redstone/displayLink/source/FactoryGaugeDisplaySource.java'
$relative = 'src/main/java/com/simibubi/create/content/redstone/displayLink/source/FactoryGaugeDisplaySource.java'
$reference = Join-Path $root "fabric-reference/$relative"
$source = Join-Path $root "source/fabric/$relative"

New-Item -ItemType Directory -Force (Split-Path $reference) | Out-Null
New-Item -ItemType Directory -Force (Split-Path $source) | Out-Null
Copy-Item -LiteralPath $donor -Destination $reference

$text = [IO.File]::ReadAllText($reference)
$adaptations = @(
    [pscustomobject]@{
        from = "import net.createmod.catnip.data.IntAttached;`n"
        to = ''
    },
    [pscustomobject]@{
        from = 'import net.createmod.catnip.data.LongAttached;'
        to = "import com.simibubi.create.foundation.blockEntity.behaviour.BlockEntityBehaviour;`nimport com.simibubi.create.content.logistics.factoryBoard.FactoryPanelSupportBehaviour;`nimport com.simibubi.create.foundation.utility.LongAttached;"
    },
    [pscustomobject]@{
        from = 'List<FactoryPanelPosition> panels = context.blockEntity().factoryPanelSupport.getLinkedPanels();'
        to = "FactoryPanelSupportBehaviour support = BlockEntityBehaviour.get(context.level(),`n`t`t`tcontext.blockEntity().getBlockPos(), FactoryPanelSupportBehaviour.TYPE);`n`t`tif (support == null)`n`t`t`treturn Stream.empty();`n`t`tList<FactoryPanelPosition> panels = support.getLinkedPanels();"
    }
)
foreach ($adaptation in $adaptations) {
    if (-not $text.Contains($adaptation.from)) { throw "Factory gauge source anchor missing: $($adaptation.from)" }
    $text = $text.Replace($adaptation.from, $adaptation.to)
}
[IO.File]::WriteAllText($source, $text, [Text.UTF8Encoding]::new($false))

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

$lockPath = Join-Path $root 'fabric-reference-lock.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
if (-not ($lock.files | Where-Object path -eq $relative)) {
    $lock.files = @($lock.files) + [pscustomobject]@{ path = $relative; gitBlob = Get-GitBlobHash $reference }
    $lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
}

$changesPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
if (-not ($manifest.files | Where-Object path -eq 'content/redstone/displayLink/source/FactoryGaugeDisplaySource.java')) {
    $manifest.files = @($manifest.files) + [pscustomobject]@{
        path = 'content/redstone/displayLink/source/FactoryGaugeDisplaySource.java'
        sourceRoot = 'fabric-reference'
        changes = $adaptations
        status = 'Original Create 6 factory-gauge display source restored; support behaviour lookup adapted to the Fabric baseline block-entity API.'
    }
}

$allBlocks = $manifest.files | Where-Object path -eq 'AllBlocks.java'
$blockChanges = @(
    [pscustomobject]@{
        from = 'import com.simibubi.create.content.logistics.factoryBoard.FactoryPanelModel;'
        to = "import com.simibubi.create.content.logistics.factoryBoard.FactoryPanelModel;`nimport com.simibubi.create.content.redstone.displayLink.source.FactoryGaugeDisplaySource;"
    },
    [pscustomobject]@{
        from = '.transform(displaySource(AllDisplaySources.GAUGE_STATUS))'
        to = '.onRegister(assignDataBehaviour(new FactoryGaugeDisplaySource(), "gauge_status"))'
    }
)
$allBlocksPath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/AllBlocks.java'
$allBlocksText = [IO.File]::ReadAllText($allBlocksPath)
foreach ($adaptation in $blockChanges) {
    if (-not $allBlocksText.Contains($adaptation.from)) { throw "AllBlocks display source anchor missing: $($adaptation.from)" }
    $allBlocksText = $allBlocksText.Replace($adaptation.from, $adaptation.to)
}
[IO.File]::WriteAllText($allBlocksPath, $allBlocksText, [Text.UTF8Encoding]::new($false))
$allBlocks.changes = @($allBlocks.changes) + $blockChanges
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8

$argument = '"' + ($source.Replace('\', '/')) + '"'
$argsPath = Join-Path $root 'integration-compile.args'
$argsText = [IO.File]::ReadAllText($argsPath)
if (-not $argsText.Contains($argument)) {
    [IO.File]::AppendAllText($argsPath, "`r`n$argument", [Text.UTF8Encoding]::new($false))
}

Write-Output 'Restored and tracked the original factory-gauge display source.'
