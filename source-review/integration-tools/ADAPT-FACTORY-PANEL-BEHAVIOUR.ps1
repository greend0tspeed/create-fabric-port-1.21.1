$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to){$entry=$script:manifest.files|Where-Object path -EQ $path;if(!$entry){throw "Untracked source: $path"};$file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file);if(!$text.Contains($from)){if($to.Length -gt 0 -and $text.Contains($to)){return};throw "Expected source missing: $path :: $from"};$entry.changes+=[pscustomobject]@{from=$from;to=$to};[IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))}
$entity='content/logistics/factoryBoard/FactoryPanelBlockEntity.java'
$anchor="`t@Override`n`tpublic void lazyTick() {"
$wrapper="`tpublic void attachPanelBehaviourLate(BlockEntityBehaviour behaviour) {`n`t`tattachBehaviourLate(behaviour);`n`t}`n`n`t@Override`n`tpublic void lazyTick() {"
$entityText=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$entity")
if(!$entityText.Contains('public void attachPanelBehaviourLate(BlockEntityBehaviour behaviour)')) { Change $entity $anchor $wrapper }
$path='content/logistics/factoryBoard/FactoryPanelBehaviour.java'
Change $path 'fpbe.attachBehaviourLate(this);' 'fpbe.attachPanelBehaviourLate(this);'
Change $path 'fpbe.attachBehaviourLate(newBehaviour);' 'fpbe.attachPanelBehaviourLate(newBehaviour);'
Change $path 'public void onShortInteract(Player player, InteractionHand hand, Direction side, BlockHitResult hitResult)' 'public void onShortInteract(Player player, InteractionHand hand, Direction side)'
Change $path 'super.onShortInteract(player, hand, side, hitResult);' 'super.onShortInteract(player, hand, side);'
Change $path "`t@Override`n`tpublic void writeSafe(CompoundTag nbt)" "`tpublic void writeSafe(CompoundTag nbt)"
Change $path 'restockerPromises.write()' 'restockerPromises.write(Create.getRegistryAccess())'
$oldRead=@'
		active = true;
		filter = FilterItemStack.of(panelTag.getCompound("Filter"));
		count = panelTag.getInt("FilterAmount");
		upTo = panelTag.getBoolean("UpTo");
'@
$newRead=@'
		active = true;
		super.read(panelTag, clientPacket);
'@
Change $path $oldRead.TrimEnd("`r","`n") $newRead.TrimEnd("`r","`n")
Change $path 'RequestPromiseQueue.read(panelTag.getCompound("Promises"), () -> {' 'RequestPromiseQueue.read(panelTag.getCompound("Promises"), Create.getRegistryAccess(), () -> {'
$oldSet=@'
		this.filter = FilterItemStack.of(filter);
		blockEntity.setChanged();
		blockEntity.sendData();
		return true;
'@
$newSet=@'
		return super.setFilter(filter);
'@
Change $path $oldSet.TrimEnd("`r","`n") $newSet.TrimEnd("`r","`n")
Change $path 'return CreateLang' 'return Lang'
Change $path 'filter.isEmpty()' 'getFilter().isEmpty()'
Change $path "`t@Override`n`tpublic float getRenderDistance()" "`tpublic float getRenderDistance()"
Change $path "`t@Override`n`tpublic MutableComponent getTip()" "`tpublic MutableComponent getTip()"
Change $path "`t@Override`n`tpublic MutableComponent getCountLabelForValueBox()" "`tpublic MutableComponent getCountLabelForValueBox()"
Change $path "`t@Override`n`tpublic int netId()" "`tpublic int netId()"
Change $path "`t@Override`n`tpublic boolean canShortInteract(ItemStack toApply)" "`tpublic boolean canShortInteract(ItemStack toApply)"
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
