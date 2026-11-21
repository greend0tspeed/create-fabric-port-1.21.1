$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$official="$(Split-Path $root)/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/java/com/simibubi/create"
$fabric="$(Split-Path $root)/full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create"
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$locks=@{upstream=(Get-Content "$root/upstream-lock.json" -Raw|ConvertFrom-Json);'fabric-reference'=(Get-Content "$root/fabric-reference-lock.json" -Raw|ConvertFrom-Json)}
$sources=@{
    'content/logistics/packagerLink/LogisticallyLinkedBlockItem.java'='upstream'
    'content/logistics/packagerLink/LogisticallyLinkedClientHandler.java'='upstream'
    'content/logistics/factoryBoard/FactoryPanelPosition.java'='upstream'
    'infrastructure/config/CLogistics.java'='fabric-reference'
    'content/redstone/nixieTube/NixieTubeBlockEntity.java'='fabric-reference'
    'content/redstone/nixieTube/NixieTubeBlock.java'='fabric-reference'
}
foreach($path in $sources.Keys){
    $sourceRoot=$sources[$path];$source=if($sourceRoot -eq 'upstream'){"$official/$path"}else{"$fabric/$path"}
    $rel="src/main/java/com/simibubi/create/$path";$snapshot="$root/$sourceRoot/$rel"
    New-Item -ItemType Directory (Split-Path $snapshot),(Split-Path "$root/source/fabric/$rel") -Force|Out-Null
    if(!(Test-Path -LiteralPath $snapshot)){Copy-Item -LiteralPath $source -Destination $snapshot}
    if([IO.File]::ReadAllText($source) -cne [IO.File]::ReadAllText($snapshot)){throw "Immutable source mismatch: $path"}
    $text=[IO.File]::ReadAllText($snapshot);$changes=@()
    foreach($c in @(@{from='io.github.fabricators_of_create.porting_lib.';to='io.github.fabricators_of_create.porting_lib_ufo.'},@{from='com.simibubi.create.foundation.utility.CreateLang';to='com.simibubi.create.foundation.utility.Lang'},@{from='CreateLang.';to='Lang.'},@{from='Create.LOGISTICS';to='com.simibubi.create.content.logistics.packagerLink.GlobalLogisticsManager.INSTANCE'})){
        if($text.Contains($c.from)){$text=$text.Replace($c.from,$c.to);$changes+=$c}
    }
    [IO.File]::WriteAllText("$root/source/fabric/$rel",$text,[Text.UTF8Encoding]::new($false))
    if($locks[$sourceRoot].files.path -notcontains $rel){
        $bytes=[IO.File]::ReadAllBytes($snapshot);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=[byte[]]::new($prefix.Length+$bytes.Length)
        [Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length)
        $sha=[Security.Cryptography.SHA1]::Create();try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
        $locks[$sourceRoot].files+=[pscustomobject]@{path=$rel;gitBlob=$blob}
    }
    $manifest.files=@($manifest.files|Where-Object path -NE $path)
    $manifest.files+=[pscustomobject]@{path=$path;sourceRoot=$sourceRoot;changes=$changes;status='Integration source imported; compilation/runtime pending'}
}
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
$locks.upstream|ConvertTo-Json -Depth 20|Set-Content "$root/upstream-lock.json"
$locks['fabric-reference']|ConvertTo-Json -Depth 20|Set-Content "$root/fabric-reference-lock.json"
