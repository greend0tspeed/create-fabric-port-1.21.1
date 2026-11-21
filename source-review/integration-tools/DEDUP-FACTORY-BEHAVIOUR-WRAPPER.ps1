$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$path='content/logistics/factoryBoard/FactoryPanelBlockEntity.java';$entry=$manifest.files|Where-Object path -EQ $path
$from="`t@Override`n`tpublic void lazyTick() {";$matching=@($entry.changes|Where-Object {$_.from -ceq $from})
if($matching.Count -gt 1){$kept=$false;$entry.changes=@($entry.changes|Where-Object {if($_.from -cne $from){$true}elseif(!$kept){$kept=$true;$true}else{$false}})}
$relative="src/main/java/com/simibubi/create/$path";$expected=[IO.File]::ReadAllText("$root/$($entry.sourceRoot)/$relative");foreach($change in $entry.changes){$expected=$expected.Replace($change.from,$change.to)}
[IO.File]::WriteAllText("$root/source/fabric/$relative",$expected,[Text.UTF8Encoding]::new($false));$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
