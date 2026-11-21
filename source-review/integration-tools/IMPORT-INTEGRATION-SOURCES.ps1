$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$donor = "$(Split-Path $root)/full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create"
$workspace = Split-Path (Split-Path (Split-Path $root))
$baseline = "$workspace/work/logistics-sandbox/upstream-port/reforged-named"
$manifest = Get-Content "$root/port-changes.json" -Raw | ConvertFrom-Json
$lock = Get-Content "$root/fabric-reference-lock.json" -Raw | ConvertFrom-Json
$existing = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($entry in $manifest.files) { [void]$existing.Add($entry.path) }
$pending = [Collections.Generic.Queue[string]]::new()
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($package in @('content/logistics/factoryBoard','content/logistics/packagerLink','content/logistics/stockTicker','content/logistics/packagePort','content/logistics/packager','content/logistics/redstoneRequester','content/logistics/tableCloth','content/kinetics/chainConveyor','compat/computercraft')) {
    foreach ($file in Get-ChildItem "$donor/$package" -Recurse -Filter *.java) {
        if ($file.Name -notmatch 'Visual\.java$') { $pending.Enqueue([IO.Path]::GetRelativePath($donor,$file.FullName).Replace('\','/')) }
    }
}
$pending.Enqueue('content/trains/station/StationBlockEntity.java')
$utilityMap = @{}
foreach ($file in Get-ChildItem "$baseline/com/simibubi/create/foundation" -Recurse -Filter *.class) {
    if ($file.Name -notmatch '\$') {
        $name = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        if (!$utilityMap.ContainsKey($name)) { $utilityMap[$name]=[IO.Path]::GetRelativePath($baseline,$file.FullName).Replace('\','.').Replace('/','.').Replace('.class','') }
    }
}
$added = 0
while ($pending.Count -gt 0) {
    $path=$pending.Dequeue()
    if (!$seen.Add($path) -or $existing.Contains($path)) { continue }
    $file="$donor/$path"
    if (!(Test-Path -LiteralPath $file)) { continue }
    $text=[IO.File]::ReadAllText($file)
    $changes=[Collections.Generic.List[object]]::new()
    $changes.Add(@{from='io.github.fabricators_of_create.porting_lib.';to='io.github.fabricators_of_create.porting_lib_ufo.'})
    $changes.Add(@{from='com.simibubi.create.foundation.utility.CreateLang';to='com.simibubi.create.foundation.utility.Lang'})
    $changes.Add(@{from='CreateLang.';to='Lang.'})
    $changes.Add(@{from='Create.LOGISTICS';to='com.simibubi.create.content.logistics.packagerLink.GlobalLogisticsManager.INSTANCE'})
    $changes.Add(@{from='FriendlyByteBuf';to='RegistryFriendlyByteBuf'})
    foreach ($match in [regex]::Matches($text,'import (net\.createmod\.catnip\.[\w.]+);')) {
        $type=$match.Groups[1].Value
        $name=($type -split '\.')[-1]
        if ($utilityMap.ContainsKey($name)) { $changes.Add(@{from=$type;to=$utilityMap[$name]}) }
    }
    $used=@()
    foreach ($change in $changes) {
        if ($text.Contains($change.from)) { $text=$text.Replace($change.from,$change.to);$used+=$change }
    }
    $relative="src/main/java/com/simibubi/create/$path"
    $snapshot="$root/fabric-reference/$relative"
    New-Item -ItemType Directory (Split-Path $snapshot),(Split-Path "$root/source/fabric/$relative") -Force | Out-Null
    if (!(Test-Path -LiteralPath $snapshot)) { Copy-Item -LiteralPath $file -Destination $snapshot }
    if ([IO.File]::ReadAllText($snapshot) -cne [IO.File]::ReadAllText($file)) { throw "Immutable donor mismatch: $path" }
    if ($lock.files.path -notcontains $relative) {
        $bytes=[IO.File]::ReadAllBytes($snapshot)
        $prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
        $data=[byte[]]::new($prefix.Length+$bytes.Length)
        [Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length)
        $hash=[Security.Cryptography.SHA1]::Create()
        try { $blob=[BitConverter]::ToString($hash.ComputeHash($data)).Replace('-','').ToLowerInvariant() } finally { $hash.Dispose() }
        $lock.files+=[pscustomobject]@{path=$relative;gitBlob=$blob}
    }
    [IO.File]::WriteAllText("$root/source/fabric/$relative",$text,[Text.UTF8Encoding]::new($false))
    $manifest.files+=[pscustomobject]@{path=$path;sourceRoot='fabric-reference';changes=@($used);status='Integration source imported; compilation and runtime validation pending'}
    [void]$existing.Add($path)
    $added++
    foreach ($match in [regex]::Matches($text,'import (?:static )?com\.simibubi\.create\.([\w.]+);')) {
        $parts=$match.Groups[1].Value -split '\.'
        for($i=$parts.Length;$i -gt 0;$i--) {
            $dependency=($parts[0..($i-1)] -join '/')+'.java'
            if (Test-Path -LiteralPath "$donor/$dependency") {
                $class=$dependency.Replace('.java','.class')
                if (!(Test-Path -LiteralPath "$baseline/com/simibubi/create/$class")) { $pending.Enqueue($dependency) }
                break
            }
        }
    }
}
$manifest | ConvertTo-Json -Depth 30 | Set-Content "$root/port-changes.json"
$lock | ConvertTo-Json -Depth 20 | Set-Content "$root/fabric-reference-lock.json"
Write-Output "Imported $added original donor sources. This is dependency collection, not successful compilation."
