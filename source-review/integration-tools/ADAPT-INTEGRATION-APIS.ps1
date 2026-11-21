$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$manifest = Get-Content "$root/port-changes.json" -Raw | ConvertFrom-Json
function Change($entry,[string]$from,[string]$to) {
    $path="$root/source/fabric/src/main/java/com/simibubi/create/$($entry.path)"
    $text=[IO.File]::ReadAllText($path)
    if (!$text.Contains($from)) { return }
    $entry.changes+= [pscustomobject]@{from=$from;to=$to}
    [IO.File]::WriteAllText($path,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
foreach($entry in $manifest.files) {
    if ($entry.status -notlike 'Integration source imported*') { continue }
    Change $entry 'dev.engine_room.flywheel.lib.transform.TransformStack' 'com.jozufozu.flywheel.util.transform.TransformStack'
    Change $entry 'dev.engine_room.flywheel.lib.transform.Transform;' 'com.jozufozu.flywheel.util.transform.Transform;'
    Change $entry 'dev.engine_room.flywheel.lib.model.baked.PartialModel' 'com.jozufozu.flywheel.core.PartialModel'
    Change $entry 'net.createmod.ponder.api.level.PonderLevel' 'com.simibubi.create.foundation.ponder.PonderWorld'
    Change $entry 'PonderLevel' 'PonderWorld'
    Change $entry 'net.createmod.catnip.render.CachedBuffers' 'com.simibubi.create.foundation.render.CachedBufferer'
    Change $entry 'CachedBuffers.' 'CachedBufferer.'
    Change $entry 'TransformStack.of(' 'TransformStack.cast('
    Change $entry 'PartialModel.of(' 'new PartialModel('
    Change $entry 'ItemStack.isSameItemSameTags(' 'ItemStack.isSameItemSameComponents('
    # Use the existing complete original non-instanced renderer on this old
    # Flywheel baseline. No replacement Visual classes or fake backend are used.
    Change $entry "import dev.engine_room.flywheel.api.visualization.VisualizationManager;`n" ''
    Change $entry 'if (!VisualizationManager.supportsVisualization(level))' ''
    Change $entry 'if (!VisualizationManager.supportsVisualization(be.getLevel()))' ''
    Change $entry "if (VisualizationManager.supportsVisualization(be.getLevel()))`n`t`t`treturn;" ''
    Change $entry "if (VisualizationManager.supportsVisualization(be.getLevel()))`n`t`treturn;" ''
    Change $entry "if (VisualizationManager.supportsVisualization(level))`n`t`t`treturn;" ''
    $text=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$($entry.path)")
    foreach($match in [regex]::Matches($text,'protected void read\(CompoundTag (\w+), boolean (\w+)\)')) {
        $tag=$match.Groups[1].Value; $client=$match.Groups[2].Value
        Change $entry $match.Value "protected void read(CompoundTag $tag, net.minecraft.core.HolderLookup.Provider registries, boolean $client)"
        Change $entry "super.read($tag, $client);" "super.read($tag, registries, $client);"
    }
    foreach($match in [regex]::Matches($text,'NbtUtils\.readBlockPos\((\w+)\.getCompound\("([^"]+)"\)\)')) {
        Change $entry $match.Value ('NbtUtils.readBlockPos('+ $match.Groups[1].Value +', "'+$match.Groups[2].Value+'").orElseThrow()')
    }
}
$manifest | ConvertTo-Json -Depth 30 | Set-Content "$root/port-changes.json"
