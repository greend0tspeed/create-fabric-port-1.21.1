$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$baselineSource="$project/../logistics-sandbox/source/fabric/src/main/java/com/simibubi/create/AllDataComponents.java"
$officialRoot="$project/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/java/com/simibubi/create"
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$baselineLock=Get-Content "$root/baseline-reference-lock.json" -Raw|ConvertFrom-Json
$upstreamLock=Get-Content "$root/upstream-lock.json" -Raw|ConvertFrom-Json
function GitBlob([string]$file) {
    $bytes=[IO.File]::ReadAllBytes($file);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
    $data=[byte[]]::new($prefix.Length+$bytes.Length);[Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length)
    $sha=[Security.Cryptography.SHA1]::Create();try{return [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
}
function TrackSnapshot([string]$source,[string]$rootName,[string]$relative,[object]$lock) {
    $target="$root/$rootName/$relative";New-Item -ItemType Directory (Split-Path $target) -Force|Out-Null
    if(!(Test-Path $target)){Copy-Item $source $target}
    if($lock.files.path -notcontains $relative){$lock.files+=[pscustomobject]@{path=$relative;gitBlob=(GitBlob $target)}}
}
function SetEntry([string]$path,[string]$sourceRoot) {
    $script:manifest.files=@($script:manifest.files|Where-Object path -NE $path)
    $script:manifest.files+=[pscustomobject]@{path=$path;sourceRoot=$sourceRoot;changes=@();status='Create 6 data component integration pending complete build/runtime validation'}
}
function Change([string]$path,[string]$from,[string]$to) {
    $entry=$script:manifest.files|Where-Object path -EQ $path;if(!$entry){throw "Untracked source: $path"}
    $file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file)
    $recorded=@($entry.changes|Where-Object {$_.from -ceq $from -and $_.to -ceq $to}).Count -gt 0
    if($to.Length -gt 0 -and $text.Contains($to) -and !$text.Contains($from)) {
        if(!$recorded){$entry.changes+=[pscustomobject]@{from=$from;to=$to}}
        return
    }
    if($to.Length -eq 0 -and !$text.Contains($from)) {
        if(!$recorded){$entry.changes+=[pscustomobject]@{from=$from;to=$to}}
        return
    }
    if(!$text.Contains($from)){throw "Expected source text missing: $path :: $from"}
    if(!$recorded){$entry.changes+=[pscustomobject]@{from=$from;to=$to}}
    [IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
$relative='src/main/java/com/simibubi/create/AllDataComponents.java'
TrackSnapshot $baselineSource 'baseline-reference' $relative $baselineLock
Copy-Item "$root/baseline-reference/$relative" "$root/source/fabric/$relative"
SetEntry 'AllDataComponents.java' 'baseline-reference'
Change 'AllDataComponents.java' 'import com.mojang.serialization.Codec;' "import com.mojang.serialization.Codec;`nimport com.simibubi.create.content.logistics.box.PackageItem.PackageOrderData;`nimport com.simibubi.create.content.logistics.redstoneRequester.AutoRequestData;`nimport com.simibubi.create.content.logistics.stockTicker.PackageOrderWithCrafts;`nimport com.simibubi.create.content.logistics.tableCloth.ShoppingListItem.ShoppingList;"
Change 'AllDataComponents.java' 'import net.minecraft.network.codec.ByteBufCodecs;' "import net.minecraft.network.codec.ByteBufCodecs;`nimport net.minecraft.world.item.component.ItemContainerContents;"
Change 'AllDataComponents.java' 'public static DataComponentType<Integer> COLLECTING_LIGHT = null;' "public static DataComponentType<Integer> COLLECTING_LIGHT = null;`n`tpublic static DataComponentType<String> PACKAGE_ADDRESS = null;`n`tpublic static DataComponentType<ItemContainerContents> PACKAGE_CONTENTS = null;`n`tpublic static DataComponentType<PackageOrderData> PACKAGE_ORDER_DATA = null;`n`tpublic static DataComponentType<PackageOrderWithCrafts> PACKAGE_ORDER_CONTEXT = null;`n`tpublic static DataComponentType<AutoRequestData> AUTO_REQUEST_DATA = null;`n`tpublic static DataComponentType<ShoppingList> SHOPPING_LIST = null;`n`tpublic static DataComponentType<String> SHOPPING_LIST_ADDRESS = null;"
$oldRegistrationTail=@'
		COLLECTING_LIGHT = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:collecting_light", 
				(new DataComponentType.Builder<Integer>())
					.persistent(Codec.INT)
					.networkSynchronized(ByteBufCodecs.INT)
					.cacheEncoding()
					.build());
	}
'@
$newRegistrationTail=@'
		COLLECTING_LIGHT = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:collecting_light", 
				(new DataComponentType.Builder<Integer>())
					.persistent(Codec.INT)
					.networkSynchronized(ByteBufCodecs.INT)
					.cacheEncoding()
					.build());
		PACKAGE_ADDRESS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_address",
			(new DataComponentType.Builder<String>()).persistent(Codec.STRING).networkSynchronized(ByteBufCodecs.STRING_UTF8).cacheEncoding().build());
		PACKAGE_CONTENTS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_contents",
			(new DataComponentType.Builder<ItemContainerContents>()).persistent(ItemContainerContents.CODEC).networkSynchronized(ItemContainerContents.STREAM_CODEC).cacheEncoding().build());
		PACKAGE_ORDER_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_order_data",
			(new DataComponentType.Builder<PackageOrderData>()).persistent(PackageOrderData.CODEC).networkSynchronized(PackageOrderData.STREAM_CODEC).cacheEncoding().build());
		PACKAGE_ORDER_CONTEXT = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:package_order_context",
			(new DataComponentType.Builder<PackageOrderWithCrafts>()).persistent(PackageOrderWithCrafts.CODEC).networkSynchronized(PackageOrderWithCrafts.STREAM_CODEC).cacheEncoding().build());
		AUTO_REQUEST_DATA = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:auto_request_data",
			(new DataComponentType.Builder<AutoRequestData>()).persistent(AutoRequestData.CODEC).networkSynchronized(AutoRequestData.STREAM_CODEC).cacheEncoding().build());
		SHOPPING_LIST = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:shopping_list",
			(new DataComponentType.Builder<ShoppingList>()).persistent(ShoppingList.CODEC).networkSynchronized(ShoppingList.STREAM_CODEC).cacheEncoding().build());
		SHOPPING_LIST_ADDRESS = Registry.register(BuiltInRegistries.DATA_COMPONENT_TYPE, "create:shopping_list_address",
			(new DataComponentType.Builder<String>()).persistent(Codec.STRING).networkSynchronized(ByteBufCodecs.STRING_UTF8).cacheEncoding().build());
	}
'@
$oldRegistrationTail=$oldRegistrationTail.TrimEnd("`r","`n").Replace("`n","`r`n")
$newRegistrationTail=$newRegistrationTail.TrimEnd("`r","`n").Replace("`n","`r`n")
Change 'AllDataComponents.java' $oldRegistrationTail $newRegistrationTail
$autoPath='content/logistics/redstoneRequester/AutoRequestData.java';$autoRel="src/main/java/com/simibubi/create/$autoPath"
TrackSnapshot "$officialRoot/$autoPath" 'upstream' $autoRel $upstreamLock
Copy-Item "$root/upstream/$autoRel" "$root/source/fabric/$autoRel";SetEntry $autoPath 'upstream'
Change $autoPath 'com.simibubi.create.foundation.utility.CreateLang' 'com.simibubi.create.foundation.utility.Lang'
Change $autoPath 'CreateLang' 'Lang'
$block='content/logistics/redstoneRequester/RedstoneRequesterBlock.java'
Copy-Item "$root/fabric-reference/src/main/java/com/simibubi/create/$block" "$root/source/fabric/src/main/java/com/simibubi/create/$block"
SetEntry $block 'fabric-reference'
Change $block 'io.github.fabricators_of_create.porting_lib.' 'io.github.fabricators_of_create.porting_lib_ufo.'
Change $block 'com.simibubi.create.foundation.utility.CreateLang' 'com.simibubi.create.foundation.utility.Lang'
Change $block 'CreateLang.' 'Lang.'
Change $block 'import com.simibubi.create.AllBlocks;' "import com.simibubi.create.AllBlocks;`nimport com.simibubi.create.AllDataComponents;"
Change $block 'import com.simibubi.create.content.logistics.stockTicker.PackageOrder;' ''
Change $block "import net.minecraft.nbt.CompoundTag;`nimport net.minecraft.nbt.Tag;" "import net.minecraft.core.component.DataComponents;`nimport net.minecraft.world.item.component.CustomData;"
Change $block 'import net.minecraft.world.item.BlockItem;' ''
Change $block "`t`tAutoRequestData autoRequestData = new AutoRequestData();`n`t`tautoRequestData.encodedRequest = order;`n`t`tautoRequestData.encodedTargetAdress = address;`n`t`tautoRequestData.targetOffset = be.getBlockPos();`n`t`tautoRequestData.targetDim = player.level()`n`t`t`t.dimension()`n`t`t`t.location()`n`t`t`t.toString();" "`t`tString targetDim = player.level()`n`t`t`t.dimension()`n`t`t`t.location()`n`t`t`t.toString();`n`t`tAutoRequestData autoRequestData = new AutoRequestData(order, address, be.getBlockPos(), targetDim, false);"
Change $block 'CompoundTag stackTag = stack.getTag();' 'CustomData blockEntityData = stack.getOrDefault(DataComponents.BLOCK_ENTITY_DATA, CustomData.EMPTY);'
Change $block 'CompoundTag beTag = stackTag.getCompound(BlockItem.BLOCK_ENTITY_TAG);' 'stack.set(DataComponents.BLOCK_ENTITY_DATA, blockEntityData.update(tag -> tag.putUUID("Freq", be.behaviour.freqId)));'
Change $block ('`t`t`tbeTag.putUUID("Freq", be.behaviour.freqId);`n'.Replace('`t',"`t").Replace('`n',"`n")) ''
Change $block '`t`t`tstackTag.put(BlockItem.BLOCK_ENTITY_TAG, beTag);`n'.Replace('`t',"`t").Replace('`n',"`n") ''
$oldTooltip=@'
		if (!pStack.hasTag())
			return;

		CompoundTag compoundnbt = pStack.getTag();
		if (!compoundnbt.contains("EncodedRequest", Tag.TAG_COMPOUND))
			return;

		PackageOrder contents = PackageOrder.read(compoundnbt.getCompound("EncodedRequest"));
		for (BigItemStack entry : contents.stacks()) {
'@
$newTooltip=@'
		AutoRequestData data = pStack.get(AllDataComponents.AUTO_REQUEST_DATA);
		if (data == null)
			return;

		for (BigItemStack entry : data.encodedRequest().stacks()) {
'@
Change $block $oldTooltip.TrimEnd("`r","`n") $newTooltip.TrimEnd("`r","`n")
Change $block 'rrbe.encodedRequest = data.encodedRequest;' 'rrbe.encodedRequest = data.encodedRequest();'
Change $block 'rrbe.encodedTargetAdress = data.encodedTargetAdress;' 'rrbe.encodedTargetAdress = data.encodedTargetAddress();'
$item='content/logistics/redstoneRequester/RedstoneRequesterBlockItem.java'
Copy-Item "$root/fabric-reference/src/main/java/com/simibubi/create/$item" "$root/source/fabric/src/main/java/com/simibubi/create/$item"
SetEntry $item 'fabric-reference'
Change $item 'com.simibubi.create.foundation.utility.CreateLang' 'com.simibubi.create.foundation.utility.Lang'
Change $item 'CreateLang.' 'Lang.'
Change $item 'import com.simibubi.create.content.logistics.packagerLink.LogisticallyLinkedBlockItem;' "import com.simibubi.create.AllDataComponents;`nimport com.simibubi.create.content.logistics.packagerLink.LogisticallyLinkedBlockItem;"
Change $item 'import net.minecraft.nbt.Tag;' ''
Change $item 'import net.minecraft.world.level.Level;' ''
Change $item "public void appendHoverText(ItemStack pStack, Level pLevel, List<Component> pTooltip, TooltipFlag pFlag)" 'public void appendHoverText(ItemStack pStack, TooltipContext tooltipContext, List<Component> pTooltip, TooltipFlag pFlag)'
$oldHover=@'
		if (!pStack.getTag()
			.contains("EncodedRequest", Tag.TAG_COMPOUND)) {
			super.appendHoverText(pStack, pLevel, pTooltip, pFlag);
'@
$newHover=@'
		if (!pStack.has(AllDataComponents.AUTO_REQUEST_DATA)) {
			super.appendHoverText(pStack, tooltipContext, pTooltip, pFlag);
'@
Change $item $oldHover.TrimEnd("`r","`n") $newHover.TrimEnd("`r","`n")
$arg="$root/integration-compile.args";$sourceLine='"'+("$root/source/fabric/$relative").Replace('\','/')+'"'
$args=[Collections.Generic.List[string]](Get-Content $arg);if(!$args.Contains($sourceLine)){$args.Add($sourceLine);[IO.File]::WriteAllLines($arg,$args)}
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json";$baselineLock|ConvertTo-Json -Depth 20|Set-Content "$root/baseline-reference-lock.json";$upstreamLock|ConvertTo-Json -Depth 20|Set-Content "$root/upstream-lock.json"
