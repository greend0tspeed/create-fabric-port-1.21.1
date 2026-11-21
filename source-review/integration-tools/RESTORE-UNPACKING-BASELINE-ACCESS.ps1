$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$workspaceRoot=Split-Path $root
$manifestPath=Join-Path $root 'port-changes.json'
$lockPath=Join-Path $root 'baseline-reference-lock.json'
$argsPath=Join-Path $root 'integration-compile.args'
$m=Get-Content $manifestPath -Raw|ConvertFrom-Json
$lock=Get-Content $lockPath -Raw|ConvertFrom-Json
$targets=@(
 [pscustomobject]@{rel='content/processing/basin/BasinInventory.java';changes=@(
  [pscustomobject]@{from="`tprivate BasinBlockEntity blockEntity;";to="`tprivate BasinBlockEntity blockEntity;`n`n`tpublic boolean packagerMode;"},
  [pscustomobject]@{from="`t`tif (!insertionAllowed)`n`t`t`treturn 0;`n`t`t// Only insert";to="`t`tif (!insertionAllowed)`n`t`t`treturn 0;`n`t`tif (packagerMode)`n`t`t`treturn super.insert(resource, maxAmount, transaction);`n`t`t// Only insert"}
 );status='Pinned Fabric Basin package-insertion mode restored for native package unpacking.'},
 [pscustomobject]@{rel='content/kinetics/crafter/MechanicalCrafterBlockEntity.java';changes=@(
  [pscustomobject]@{from='protected void checkCompletedRecipe(boolean poweredStart)';to='public void checkCompletedRecipe(boolean poweredStart)'},
  [pscustomobject]@{from="`tpublic Inventory getInventory() {`n`t`treturn inventory;`n`t}";to="`tpublic Inventory getInventory() {`n`t`treturn inventory;`n`t}`n`n`tpublic ConnectedInput getInput() {`n`t`treturn input;`n`t}"}
 );status='Pinned Fabric Mechanical Crafter input and completion access restored for native package recipe unpacking.'},
 [pscustomobject]@{rel='content/kinetics/crafter/ConnectedInputHandler.java';changes=@();status='Pinned Fabric ordered Crafter inventory access restored for native package recipe unpacking.'}
)
$donor=Join-Path $workspaceRoot 'full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/src/main/java/com/simibubi/create/content/kinetics/crafter/ConnectedInputHandler.java'
$dt=[IO.File]::ReadAllText($donor);$s=$dt.IndexOf("`t`tpublic List<Inventory> getInventories");$e=$dt.IndexOf("`t`tpublic void write",$s);if($s-lt0-or$e-lt0){throw 'Donor Crafter inventory method missing'};$method=$dt.Substring($s,$e-$s);$targets[2].changes=@([pscustomobject]@{from="`t`tpublic void write(CompoundTag nbt)";to=$method+"`t`tpublic void write(CompoundTag nbt)"})
foreach($t in $targets){
 $relative="src/main/java/com/simibubi/create/$($t.rel)";$base=Join-Path $workspaceRoot "source/fabric/$relative";$ref=Join-Path $root "baseline-reference/$relative";$src=Join-Path $root "source/fabric/$relative";[IO.Directory]::CreateDirectory((Split-Path -Parent $ref))|Out-Null;[IO.Directory]::CreateDirectory((Split-Path -Parent $src))|Out-Null;if(-not(Test-Path $ref)){[IO.File]::WriteAllText($ref,[IO.File]::ReadAllText($base),[Text.UTF8Encoding]::new($false))};$x=[IO.File]::ReadAllText($ref);$nl=if($x.Contains("`r`n")){"`r`n"}else{"`n"};foreach($c in $t.changes){$c.from=$c.from.Replace("`n",$nl);$c.to=$c.to.Replace("`n",$nl);if(-not$x.Contains($c.from)){throw "Unpacking baseline anchor missing in $($t.rel): $($c.from)"};$x=$x.Replace($c.from,$c.to)};[IO.File]::WriteAllText($src,$x,[Text.UTF8Encoding]::new($false));if(-not($lock.files|Where-Object path -eq $relative)){$bytes=[IO.File]::ReadAllBytes($ref);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=New-Object byte[]($prefix.Length+$bytes.Length);[Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length);$sha=[Security.Cryptography.SHA1]::Create();try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$lock.files=@($lock.files)+[pscustomobject]@{gitBlob=$blob;path=$relative}};if(-not($m.files|Where-Object path -eq $t.rel)){$m.files=@($m.files)+[pscustomobject]@{path=$t.rel;sourceRoot='baseline-reference';changes=$t.changes;status=$t.status}};$arg='"'+($src-replace '\\','/')+'"';$args=[IO.File]::ReadAllText($argsPath);if(-not$args.Contains($arg)){[IO.File]::AppendAllText($argsPath,"`r`n$arg`r`n",[Text.UTF8Encoding]::new($false))}
}
$lock|ConvertTo-Json -Depth 10|Set-Content $lockPath -Encoding utf8;$m|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8;Write-Output 'Restored native unpacking access from pinned Fabric sources.'
