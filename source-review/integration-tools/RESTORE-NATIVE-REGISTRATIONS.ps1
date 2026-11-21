$ErrorActionPreference = 'Stop'
$root=Split-Path $PSScriptRoot
$donor="$(Split-Path $root)/full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create"
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$lock=Get-Content "$root/baseline-reference-lock.json" -Raw|ConvertFrom-Json
$fabricLock=Get-Content "$root/fabric-reference-lock.json" -Raw|ConvertFrom-Json
function Blob($path) {
    $bytes=[IO.File]::ReadAllBytes($path);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
    $data=[byte[]]::new($prefix.Length+$bytes.Length);[Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length)
    $sha=[Security.Cryptography.SHA1]::Create();try{return [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
}
function Terminator([string]$text,[int]$start,[char[]]$delimiters) {
    $paren=0;$brace=0;$square=0;$quote=[char]0
    for($i=$start;$i -lt $text.Length;$i++) {
        $c=$text[$i]
        if($quote -ne [char]0){if($c -eq '\'){$i++;continue};if($c -eq $quote){$quote=[char]0};continue}
        if($c -eq '"' -or $c -eq "'"){$quote=$c;continue}
        if($c -eq '/' -and $i+1 -lt $text.Length){
            if($text[$i+1] -eq '/'){$end=$text.IndexOf("`n",$i);if($end -lt 0){break};$i=$end;continue}
            if($text[$i+1] -eq '*'){$end=$text.IndexOf('*/',$i+2);if($end -lt 0){throw 'Unclosed comment'};$i=$end+1;continue}
        }
        if($paren -eq 0 -and $brace -eq 0 -and $square -eq 0 -and $delimiters -contains $c){return $i}
        switch($c){'('{$paren++};')'{$paren--};'{'{$brace++};'}'{$brace--};'['{$square++};']'{$square--}}
    }
    throw 'Declaration delimiter not found'
}
function Record($entry,[string]$from,[string]$to,[ref]$text){
    if(!$text.Value.Contains($from)){throw "Missing registration anchor in $($entry.path)"}
    $entry.changes+=[pscustomobject]@{from=$from;to=$to}
    $text.Value=$text.Value.Replace($from,$to)
}
$wanted=@{}
foreach($entry in $manifest.files){
    $text=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$($entry.path)")
    foreach($match in [regex]::Matches($text,'\b(All[A-Z]\w*)\.([A-Z][A-Z0-9_]+)\b')){
        $owner=$match.Groups[1].Value;$field=$match.Groups[2].Value
        if(!$wanted.ContainsKey($owner)){$wanted[$owner]=[Collections.Generic.HashSet[string]]::new()};[void]$wanted[$owner].Add($field)
    }
    foreach($match in [regex]::Matches($text,'import static [\w.]+\.(All[A-Z]\w*)\.([A-Z][A-Z0-9_]+);')){
        $owner=$match.Groups[1].Value;$field=$match.Groups[2].Value
        if(!$wanted.ContainsKey($owner)){$wanted[$owner]=[Collections.Generic.HashSet[string]]::new()};[void]$wanted[$owner].Add($field)
    }
}
$added=0
foreach($owner in $wanted.Keys){
    if($owner -in @('AllBlockTags','AllItemTags')){continue}
    $file=Get-ChildItem $donor -Recurse -Filter "$owner.java"|Select-Object -First 1
    if(!$file){continue}
    $path=[IO.Path]::GetRelativePath($donor,$file.FullName).Replace('\','/')
    $target="$root/source/fabric/src/main/java/com/simibubi/create/$path"
    if(!(Test-Path -LiteralPath $target)){continue}
    $text=[IO.File]::ReadAllText($target);$native=[IO.File]::ReadAllText($file.FullName)
    $missing=@($wanted[$owner]|Where-Object{![regex]::IsMatch($text,'\b'+[regex]::Escape($_)+'\s*(?:=(?!=)|\()')})
    if(!$missing.Count){continue}
    $entry=$manifest.files|Where-Object path -EQ $path
    $rel="src/main/java/com/simibubi/create/$path"
    if(!$entry){
        $snapshot="$root/baseline-reference/$rel";New-Item -ItemType Directory (Split-Path $snapshot) -Force|Out-Null
        Copy-Item -LiteralPath $target -Destination $snapshot
        $lock.files+=[pscustomobject]@{path=$rel;gitBlob=(Blob $snapshot);remotePath="fabric/$rel"}
        $entry=[pscustomobject]@{path=$path;sourceRoot='baseline-reference';changes=@();status='Original registry definitions restored; compilation/runtime pending'}
        $manifest.files+=$entry
    }
    $snapshot="$root/fabric-reference/$rel";New-Item -ItemType Directory (Split-Path $snapshot) -Force|Out-Null
    if(!(Test-Path -LiteralPath $snapshot)){Copy-Item -LiteralPath $file.FullName -Destination $snapshot}
    if($fabricLock.files.path -notcontains $rel){$fabricLock.files+=[pscustomobject]@{path=$rel;gitBlob=(Blob $snapshot)}}
    $isEnum=[regex]::IsMatch($native,'public enum '+$owner+'\b')
    foreach($field in $missing){
        $match=[regex]::Match($native,'\b'+[regex]::Escape($field)+'\s*(?:=(?!=)|\()')
        if(!$match.Success){continue}
        $end=Terminator $native $match.Index @(',',';')
        $expression=$native.Substring($match.Index,$end-$match.Index)
        if($isEnum){
            $start=$text.IndexOf('{',$text.IndexOf("public enum $owner"))+1
            $enumEnd=Terminator $text $start @(';')
            $anchor=$text.Substring([Math]::Max($start,$enumEnd-50),$enumEnd-[Math]::Max($start,$enumEnd-50)+1)
            Record $entry $anchor ($anchor.Substring(0,$anchor.Length-1)+",`n`t"+$expression+';') ([ref]$text)
        } else {
            $prefixAt=$native.LastIndexOf('public static final',$match.Index)
            if($prefixAt -lt 0){continue}
            $prefixTail=$native.Substring($prefixAt)
            $firstName=[regex]::Match($prefixTail,'\b([A-Z][A-Z0-9_]+)\s*=(?!=)')
            if(!$firstName.Success){continue}
            $prefix=$prefixTail.Substring(0,$firstName.Index)
            $definition=$prefix+$expression+';'
            # Rendering uses the original BER fallback on this Flywheel baseline.
            $definition=[regex]::Replace($definition,'\s*\.visual\([^\n]+\)','')
            $anchor=$text.Substring([Math]::Max(0,$text.Length-80))
            $close=$anchor.LastIndexOf('}')
            Record $entry $anchor ($anchor.Insert($close,"`n`t"+$definition+"`n")) ([ref]$text)
        }
        foreach($import in [regex]::Matches($native,'(?m)^import (?:static )?[^;]+;')){
            $simple=([regex]::Match($import.Value,'([\w]+);$')).Groups[1].Value
            if($simple -and [regex]::IsMatch($expression,'\b'+[regex]::Escape($simple)+'\b') -and !$text.Contains($import.Value)){
                $anchor="package com.simibubi.create"; $packageEnd=$text.IndexOf(';',$text.IndexOf($anchor))+1
                $package=$text.Substring(0,$packageEnd)
                Record $entry $package ($package+"`n"+$import.Value) ([ref]$text)
            }
        }
        $added++
    }
    [IO.File]::WriteAllText($target,$text,[Text.UTF8Encoding]::new($false))
}
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
$lock|ConvertTo-Json -Depth 20|Set-Content "$root/baseline-reference-lock.json"
$fabricLock|ConvertTo-Json -Depth 20|Set-Content "$root/fabric-reference-lock.json"
Write-Output "Restored $added original referenced registry definitions; pending compile/ABI/runtime checks."
