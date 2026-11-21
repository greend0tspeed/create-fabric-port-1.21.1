$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$source="$project/../logistics-sandbox/source/fabric/src/main/java/com/simibubi/create/AllTags.java"
$relative='src/main/java/com/simibubi/create/AllTags.java'
$snapshot="$root/baseline-reference/$relative"
$lock=Get-Content "$root/baseline-reference-lock.json" -Raw|ConvertFrom-Json
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
New-Item -ItemType Directory (Split-Path $snapshot) -Force|Out-Null
if(!(Test-Path $snapshot)){Copy-Item $source $snapshot}
if($lock.files.path -notcontains $relative){
    $bytes=[IO.File]::ReadAllBytes($snapshot);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=[byte[]]::new($prefix.Length+$bytes.Length)
    [Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length);$sha=[Security.Cryptography.SHA1]::Create()
    try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
    $lock.files+=[pscustomobject]@{path=$relative;gitBlob=$blob}
}
Copy-Item $snapshot "$root/source/fabric/$relative"
$path='AllTags.java';$manifest.files=@($manifest.files|Where-Object path -NE $path)
$manifest.files+=[pscustomobject]@{path=$path;sourceRoot='baseline-reference';changes=@();status='Published baseline tag ABI retained; Create 6 logistics tags added; runtime validation pending'}
function Change([string]$from,[string]$to){
    $entry=$script:manifest.files|Where-Object path -EQ $script:path;$file="$root/source/fabric/src/main/java/com/simibubi/create/$script:path";$text=[IO.File]::ReadAllText($file)
    if(!$text.Contains($from)){throw "Expected AllTags source text missing: $from"};$entry.changes+=[pscustomobject]@{from=$from;to=$to}
    [IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
Change 'MOD(Create.ID, false, true), FORGE("c"), TIC("tconstruct"), QUARK("quark")' 'MOD(Create.ID, false, true), FORGE("c"), COMMON("c"), TIC("tconstruct"), QUARK("quark")'
Change 'MOVABLE_EMPTY_COLLIDER, NON_MOVABLE, ORE_OVERRIDE_STONE' 'MOVABLE_EMPTY_COLLIDER, NON_MOVABLE, NON_BREAKABLE, ORE_OVERRIDE_STONE'
Change 'PASSIVE_BOILER_HEATERS, SAFE_NBT, SEATS, TOOLBOXES,' 'PASSIVE_BOILER_HEATERS, SAFE_NBT, SEATS, POSTBOXES, TABLE_CLOTHS, TOOLBOXES,'
Change 'RELOCATION_NOT_SUPPORTED(FORGE), WG_STONE(FORGE),' 'RELOCATION_NOT_SUPPORTED(FORGE), WG_STONE(FORGE), CARDBOARD_STORAGE_BLOCKS(FORGE, "storage_blocks/cardboard"),'
Change 'SANDPAPER, SEATS, SLEEPERS, TOOLBOXES, UPRIGHT_ON_BELT, VALVE_HANDLES, VANILLA_STRIPPED_LOGS,' 'SANDPAPER, SEATS, POSTBOXES, TABLE_CLOTHS, DYED_TABLE_CLOTHS, SLEEPERS, TOOLBOXES, UPRIGHT_ON_BELT, VALVE_HANDLES, VANILLA_STRIPPED_LOGS,'
$oldItems=@'
		VANILLA_STRIPPED_WOOD,

		STRIPPED_LOGS(FORGE), STRIPPED_WOOD(FORGE), PLATES(FORGE), WRENCH(FORGE, "tools/wrenches")
'@
$newItems=@'
		VANILLA_STRIPPED_WOOD, PACKAGES, CHAIN_RIDEABLE,

		STRIPPED_LOGS(FORGE), STRIPPED_WOOD(FORGE), PLATES(FORGE), WRENCH(FORGE, "tools/wrenches"),
		CARDBOARD_PLATES(FORGE, "plates/cardboard"), CARDBOARD_STORAGE_BLOCKS(FORGE, "storage_blocks/cardboard"),
		CHOCOLATE_BUCKETS(FORGE, "buckets/chocolate"), HONEY_BUCKETS(FORGE, "buckets/honey"),
		FOODS_CHOCOLATE(FORGE, "foods/chocolate"), DRINKS_TEA(FORGE, "drinks/tea")
'@
Change $oldItems.TrimEnd("`r","`n").Replace("`n","`r`n") $newItems.TrimEnd("`r","`n").Replace("`n","`r`n")
$arg="$root/integration-compile.args";$line='"'+("$root/source/fabric/$relative").Replace('\','/')+'"';$args=[Collections.Generic.List[string]](Get-Content $arg)
if(!$args.Contains($line)){$args.Add($line);[IO.File]::WriteAllLines($arg,$args)}
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json";$lock|ConvertTo-Json -Depth 20|Set-Content "$root/baseline-reference-lock.json"
