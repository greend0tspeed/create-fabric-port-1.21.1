$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to) {
    $entry=$script:manifest.files|Where-Object path -EQ $path
    if(!$entry){throw "Untracked source: $path"}
    $file="$root/source/fabric/src/main/java/com/simibubi/create/$path"
    $text=[IO.File]::ReadAllText($file)
    if($text.Contains($to)){return}
    if(!$text.Contains($from)){throw "Expected source text missing: $path"}
    $entry.changes+=[pscustomobject]@{from=$from;to=$to}
    [IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
$path='content/logistics/redstoneRequester/RedstoneRequesterBlockEntity.java'
Change $path 'import com.simibubi.create.AllPackets;' "import com.simibubi.create.AllPackets;`nimport com.simibubi.create.Create;"
Change $path 'import net.minecraft.nbt.CompoundTag;' "import net.minecraft.nbt.CompoundTag;`nimport net.minecraft.nbt.NbtOps;"
Change $path 'encodedRequest = PackageOrderWithCrafts.read(tag.getCompound("EncodedRequest"));' 'encodedRequest = PackageOrderWithCrafts.CODEC.parse(registries.createSerializationContext(NbtOps.INSTANCE), tag.get("EncodedRequest")).result().orElse(PackageOrderWithCrafts.empty());'
Change $path 'tag.put("EncodedRequest", encodedRequest.write());' 'tag.put("EncodedRequest", PackageOrderWithCrafts.CODEC.encodeStart(Create.getRegistryAccess().createSerializationContext(NbtOps.INSTANCE), encodedRequest).result().orElseThrow());'
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
