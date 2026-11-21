$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$official="$project/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/java/com/simibubi/create"
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$lock=Get-Content "$root/upstream-lock.json" -Raw|ConvertFrom-Json
New-Item -ItemType Directory "$root/checkpoints" -Force|Out-Null
if(!(Test-Path "$root/checkpoints/before-packet-codecs.json")){Copy-Item "$root/port-changes.json" "$root/checkpoints/before-packet-codecs.json"}
function Change([string]$path,[string]$from,[string]$to) {
    $entry=$script:manifest.files|Where-Object path -EQ $path
    if(!$entry){throw "Untracked source: $path"}
    $file="$root/source/fabric/src/main/java/com/simibubi/create/$path"
    $text=[IO.File]::ReadAllText($file)
    if(!$text.Contains($from)){return}
    $entry.changes+=[pscustomobject]@{from=$from;to=$to}
    [IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
foreach($name in @('PackageOrder','PackageOrderWithCrafts')) {
    $path="content/logistics/stockTicker/$name.java"
    $rel="src/main/java/com/simibubi/create/$path"
    $snapshot="$root/upstream/$rel"
    New-Item -ItemType Directory (Split-Path $snapshot) -Force|Out-Null
    if(!(Test-Path -LiteralPath $snapshot)){Copy-Item -LiteralPath "$official/$path" -Destination $snapshot}
    if($lock.files.path -notcontains $rel){
        $bytes=[IO.File]::ReadAllBytes($snapshot);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=[byte[]]::new($prefix.Length+$bytes.Length)
        [Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length)
        $sha=[Security.Cryptography.SHA1]::Create();try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
        $lock.files+=[pscustomobject]@{path=$rel;gitBlob=$blob}
    }
    Copy-Item -LiteralPath $snapshot -Destination "$root/source/fabric/$rel"
    $manifest.files=@($manifest.files|Where-Object path -NE $path)
    $manifest.files+=[pscustomobject]@{path=$path;sourceRoot='upstream';changes=@();status='Official 6.0.10 record/codecs restored; combined integration pending'}
    Change $path 'import net.createmod.catnip.codecs.stream.CatnipStreamCodecBuilders;' 'import net.minecraft.network.codec.ByteBufCodecs;'
    Change $path 'CatnipStreamCodecBuilders.list(BigItemStack.STREAM_CODEC)' 'BigItemStack.STREAM_CODEC.apply(ByteBufCodecs.list())'
    Change $path 'CatnipStreamCodecBuilders.list(CraftingEntry.STREAM_CODEC)' 'CraftingEntry.STREAM_CODEC.apply(ByteBufCodecs.list())'
    Change $path "import net.minecraft.network.codec.ByteBufCodecs;`nimport net.minecraft.network.codec.StreamCodec;" "import net.minecraft.network.codec.StreamCodec;"
}
# Preserve the existing Fabric packet framing, using the same optional item
# codec as the official 1.21.1 packets. Empty crafting slots must survive.
foreach($entry in @($manifest.files|Where-Object path -Match 'Packet\.java$')) {
    $path=$entry.path
    $text=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$path")
    foreach($match in [regex]::Matches($text,'\b(\w+)\.readItem\(\)')) {
        Change $path $match.Value ('net.minecraft.world.item.ItemStack.OPTIONAL_STREAM_CODEC.decode('+$match.Groups[1].Value+')')
    }
    foreach($match in [regex]::Matches($text,'\b(\w+)::writeItem')) {
        Change $path $match.Value ('stack -> net.minecraft.world.item.ItemStack.OPTIONAL_STREAM_CODEC.encode('+$match.Groups[1].Value+', stack)')
    }
    foreach($match in [regex]::Matches($text,'\b(\w+)\.writeItem\(([^;\r\n]+)\);')) {
        Change $path $match.Value ('net.minecraft.world.item.ItemStack.OPTIONAL_STREAM_CODEC.encode('+$match.Groups[1].Value+', '+$match.Groups[2].Value+');')
    }
    Change $path 'BigItemStack.receive(buffer)' 'BigItemStack.STREAM_CODEC.decode(buffer)'
}
Change 'content/logistics/stockTicker/LogisticalStockResponsePacket.java' 'items.forEach(stack -> stack.send(buffer));' 'items.forEach(stack -> BigItemStack.STREAM_CODEC.encode(buffer, stack));'
Change 'content/logistics/stockTicker/PackageOrderRequestPacket.java' 'order.write(buffer);' 'PackageOrderWithCrafts.STREAM_CODEC.encode(buffer, order);'
Change 'content/logistics/stockTicker/PackageOrderRequestPacket.java' 'PackageOrderWithCrafts.read(buffer)' 'PackageOrderWithCrafts.STREAM_CODEC.decode(buffer)'
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
$lock|ConvertTo-Json -Depth 20|Set-Content "$root/upstream-lock.json"
