$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$mp=Join-Path $root 'port-changes.json';$m=Get-Content $mp -Raw|ConvertFrom-Json;$rel='content/trains/station/GlobalStation.java'
$changes=@(
 [pscustomobject]@{from='import net.createmod.catnip.nbt.NBTHelper;';to='import com.simibubi.create.foundation.utility.NBTHelper;'},
 [pscustomobject]@{from='io.github.fabricators_of_create.porting_lib.transfer.TransferUtil';to='io.github.fabricators_of_create.porting_lib_ufo.transfer.TransferUtil'},
 [pscustomobject]@{from='io.github.fabricators_of_create.porting_lib.transfer.item.ItemStackHandler';to='io.github.fabricators_of_create.porting_lib_ufo.transfer.item.ItemStackHandler'},
 [pscustomobject]@{from='io.github.fabricators_of_create.porting_lib.util.ServerLifecycleHooks';to='io.github.fabricators_of_create.porting_lib_ufo.util.ServerLifecycleHooks'},
 [pscustomobject]@{from='carriage.storage.getAllItems()';to='carriage.storage.getItems()'},
 [pscustomobject]@{from='PackageItem.isPackage(resource)';to='PackageItem.isPackage(resource.toStack())'},
 [pscustomobject]@{from='PackageItem.matchAddress(resource, port.address)';to='PackageItem.matchAddress(resource.toStack(), port.address)'}
)
$p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$rel";$x=[IO.File]::ReadAllText($p);foreach($c in $changes){if(-not$x.Contains($c.from)){throw "GlobalStation mail anchor missing: $($c.from)"};$x=$x.Replace($c.from,$c.to)};[IO.File]::WriteAllText($p,$x,[Text.UTF8Encoding]::new($false));$e=$m.files|Where-Object path -eq $rel;$e.changes=@($e.changes)+$changes;$e.status='Native Fabric GlobalStation package-port persistence and mail-transfer logic restored and adapted to pinned Fabric utility/transfer APIs.';$m|ConvertTo-Json -Depth 20|Set-Content $mp -Encoding utf8;Write-Output 'Adapted native GlobalStation mail logistics.'
