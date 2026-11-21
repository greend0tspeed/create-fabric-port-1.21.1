$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$mp=Join-Path $root 'port-changes.json';$m=Get-Content $mp -Raw|ConvertFrom-Json
$rel='content/trains/station/StationBlockEntity.java';$changes=@(
 [pscustomobject]@{from='Component.Serializer.fromJson(tag.getString("PrevTrainName"))';to='Component.Serializer.fromJson(tag.getString("PrevTrainName"), registries)'},
 [pscustomobject]@{from='Component.Serializer.toJson(lastDisassembledTrainName)';to='Component.Serializer.toJson(lastDisassembledTrainName, level.registryAccess())'},
 [pscustomobject]@{from='train.runtime.startCurrentInstruction(level)';to='train.runtime.startCurrentInstruction()'},
 [pscustomobject]@{from='new AABB(worldPosition, edgePoint.getGlobalPosition()).inflate(2)';to='new AABB(Vec3.atLowerCornerOf(worldPosition), Vec3.atLowerCornerOf(edgePoint.getGlobalPosition())).inflate(2)'},
 [pscustomobject]@{from='edgePoint.transform(be, transform);';to='edgePoint.transform(transform);'}
)
$p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$rel";$x=[IO.File]::ReadAllText($p);foreach($c in $changes){if(-not$x.Contains($c.from)){throw "Station core anchor missing: $($c.from)"};$x=$x.Replace($c.from,$c.to)};[IO.File]::WriteAllText($p,$x,[Text.UTF8Encoding]::new($false));$e=$m.files|Where-Object path -eq $rel;$e.changes=@($e.changes)+$changes;$status='Native station serialization, schedule start, bounds and schematic transform adapted to Minecraft 1.21.1/baseline APIs.';if($e.PSObject.Properties.Name -contains 'status'){$e.status=$status}else{$e|Add-Member -NotePropertyName status -NotePropertyValue $status};$m|ConvertTo-Json -Depth 20|Set-Content $mp -Encoding utf8;Write-Output 'Adapted the first native Station core API cluster.'
