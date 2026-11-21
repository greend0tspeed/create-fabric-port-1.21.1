$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$mp=Join-Path $root 'port-changes.json';$m=Get-Content $mp -Raw|ConvertFrom-Json
$targets=@(
 [pscustomobject]@{rel='content/logistics/tableCloth/TableClothFilterSlot.java';changes=@(
  [pscustomobject]@{from='public Vec3 getLocalOffset(LevelAccessor level, BlockPos pos, BlockState state)';to='public Vec3 getLocalOffset(BlockState state)'},
  [pscustomobject]@{from='public void rotate(LevelAccessor level, BlockPos pos, BlockState state, PoseStack ms)';to='public void rotate(BlockState state, PoseStack ms)'},
  [pscustomobject]@{from='.rotateYDegrees(';to='.rotateY('},
  [pscustomobject]@{from='.rotateXDegrees(';to='.rotateX('}
 );status='Original Table Cloth value-box placement adapted to the Fabric baseline ValueBoxTransform and transform APIs.'},
 [pscustomobject]@{rel='compat/computercraft/implementation/peripherals/TableClothShopPeripheral.java';changes=@(
  [pscustomobject]@{from='return blockEntity.requestData.encodedTargetAdress;';to='return blockEntity.requestData.encodedTargetAddress();'},
  [pscustomobject]@{from="`t`tblockEntity.requestData.encodedTargetAdress = address;";to="`t`tAutoRequestData.Mutable mutable = new Mutable(blockEntity.requestData);`n`t`tmutable.encodedTargetAddress = address;`n`t`tblockEntity.requestData = mutable.toImmutable();"},
  [pscustomobject]@{from='List<BigItemStack> wares = blockEntity.requestData.encodedRequest.stacks();';to='List<BigItemStack> wares = blockEntity.requestData.encodedRequest().stacks();'},
  [pscustomobject]@{from="`t`tblockEntity.requestData.encodedRequest = PackageOrderWithCrafts.simple(list);";to="`t`tAutoRequestData.Mutable mutable = new Mutable(blockEntity.requestData);`n`t`tmutable.encodedRequest = PackageOrderWithCrafts.simple(list);`n`t`tblockEntity.requestData = mutable.toImmutable();"}
 );status='Official ComputerCraft Table Cloth shop peripheral adapted to immutable AutoRequestData accessors.'}
)
foreach($t in $targets){$p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$($t.rel)";$x=[IO.File]::ReadAllText($p);foreach($c in $t.changes){if(-not$x.Contains($c.from)){throw "Table Cloth anchor missing in $($t.rel): $($c.from)"};$x=$x.Replace($c.from,$c.to)};[IO.File]::WriteAllText($p,$x,[Text.UTF8Encoding]::new($false));$e=$m.files|Where-Object path -eq $t.rel;$e.changes=@($e.changes)+$t.changes;if($e.PSObject.Properties.Name -contains 'status'){$e.status=$t.status}else{$e|Add-Member -NotePropertyName status -NotePropertyValue $t.status}}
$m|ConvertTo-Json -Depth 20|Set-Content $mp -Encoding utf8;Write-Output 'Adapted native Table Cloth transforms and ComputerCraft shop data access.'
