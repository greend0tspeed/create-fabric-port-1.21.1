$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to) {
    $entry=$script:manifest.files|Where-Object path -EQ $path;if(!$entry){throw "Untracked source: $path"}
    $file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file)
    if(!$text.Contains($from)){if($text.Contains($to)){return};throw "Expected source text missing: $path"}
    $entry.changes+=[pscustomobject]@{from=$from;to=$to};[IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
$path='content/logistics/packager/InventorySummary.java'
Change $path 'import com.simibubi.create.content.logistics.BigItemStack;' "import com.simibubi.create.AllPackets;`nimport com.simibubi.create.content.logistics.BigItemStack;"
Change $path "import net.createmod.catnip.platform.CatnipServices;`n" ''
Change $path 'CatnipServices.NETWORK.sendToClient(player,' 'AllPackets.getChannel().sendToClient('
Change $path 'Collections.emptyList()));' 'Collections.emptyList()), player);'
Change $path 'new LogisticalStockResponsePacket(false, pos, currentList));' 'new LogisticalStockResponsePacket(false, pos, currentList), player);'
Change $path 'new LogisticalStockResponsePacket(true, pos, currentList));' 'new LogisticalStockResponsePacket(true, pos, currentList), player);'
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
