$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$baselineLock=Get-Content "$root/baseline-reference-lock.json" -Raw|ConvertFrom-Json
$upstreamLock=Get-Content "$root/upstream-lock.json" -Raw|ConvertFrom-Json
function GitBlob([string]$file){$bytes=[IO.File]::ReadAllBytes($file);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=[byte[]]::new($prefix.Length+$bytes.Length);[Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length);$sha=[Security.Cryptography.SHA1]::Create();try{[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
function Snapshot([string]$source,[string]$name,[string]$relative,[object]$lock){$target="$root/$name/$relative";New-Item -ItemType Directory (Split-Path $target) -Force|Out-Null;if(!(Test-Path $target)){Copy-Item $source $target};if($lock.files.path -notcontains $relative){$lock.files+=[pscustomobject]@{path=$relative;gitBlob=(GitBlob $target)}}}
function SetEntry([string]$path,[string]$sourceRoot){$script:manifest.files=@($script:manifest.files|Where-Object path -NE $path);$script:manifest.files+=[pscustomobject]@{path=$path;sourceRoot=$sourceRoot;changes=@();status='Original Shopping List component integration pending complete build/runtime validation'}}
function Change([string]$path,[string]$from,[string]$to){$entry=$script:manifest.files|Where-Object path -EQ $path;$file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file);if(!$text.Contains($from)){if($to.Length -gt 0 -and $text.Contains($to)){return};throw "Expected source missing: $path :: $from"};$entry.changes+=[pscustomobject]@{from=$from;to=$to};[IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))}
$intPath='foundation/utility/IntAttached.java'
$intRel="src/main/java/com/simibubi/create/$intPath"
$baseline="$project/../logistics-sandbox/source/fabric/src/main/java/com/simibubi/create/$intPath"
Snapshot $baseline 'baseline-reference' $intRel $baselineLock
Copy-Item "$root/baseline-reference/$intRel" "$root/source/fabric/$intRel"
SetEntry $intPath 'baseline-reference'
Change $intPath 'import java.util.function.Function;' "import java.util.function.Function;`n`nimport com.mojang.serialization.Codec;`nimport com.mojang.serialization.codecs.RecordCodecBuilder;`n`nimport io.netty.buffer.ByteBuf;`nimport net.minecraft.network.codec.ByteBufCodecs;`nimport net.minecraft.network.codec.StreamCodec;"
$codecMethods=@'

	public static <T> Codec<IntAttached<T>> codec(Codec<T> codec) {
		return RecordCodecBuilder.create(instance -> instance.group(
			Codec.INT.fieldOf("first").forGetter(IntAttached::getFirst),
			codec.fieldOf("second").forGetter(IntAttached::getSecond)
		).apply(instance, IntAttached::new));
	}

	public static <B extends ByteBuf, T> StreamCodec<B, IntAttached<T>> streamCodec(StreamCodec<? super B, T> codec) {
		return StreamCodec.composite(
			ByteBufCodecs.INT, Pair::getFirst,
			codec, Pair::getSecond,
			IntAttached::new
		);
	}
'@
Change $intPath "`r`n}`r`n" ($codecMethods.Replace("`n","`r`n")+"}`r`n")
$shopPath='content/logistics/tableCloth/ShoppingListItem.java'
$shopRel="src/main/java/com/simibubi/create/$shopPath"
$official="$project/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/java/com/simibubi/create/$shopPath"
Snapshot $official 'upstream' $shopRel $upstreamLock
Copy-Item "$root/upstream/$shopRel" "$root/source/fabric/$shopRel"
SetEntry $shopPath 'upstream'
Change $shopPath 'com.simibubi.create.foundation.utility.CreateLang' 'com.simibubi.create.foundation.utility.Lang'
Change $shopPath 'CreateLang' 'Lang'
Change $shopPath 'net.createmod.catnip.data.Couple' 'com.simibubi.create.foundation.utility.Couple'
Change $shopPath 'net.createmod.catnip.data.IntAttached' 'com.simibubi.create.foundation.utility.IntAttached'
Change $shopPath 'import net.createmod.catnip.codecs.stream.CatnipStreamCodecBuilders;' 'import net.minecraft.network.codec.ByteBufCodecs;'
Change $shopPath 'CatnipStreamCodecBuilders.list(IntAttached.streamCodec(BlockPos.STREAM_CODEC))' 'IntAttached.streamCodec(BlockPos.STREAM_CODEC).apply(ByteBufCodecs.list())'
$be='content/logistics/tableCloth/TableClothBlockEntity.java'
Change $be 'ShoppingList prevList = ShoppingListItem.getList(prevListItem);' 'ShoppingList prevList = ShoppingListItem.getList(prevListItem).duplicate();'
Change $be "`t`t`tlist.addPurchases(worldPosition, 1);" "`t`t`tShoppingList.Mutable mutable = new ShoppingList.Mutable(list);`n`t`t`tmutable.addPurchases(worldPosition, 1);`n`t`t`tlist = mutable.toImmutable();"
$item='content/logistics/tableCloth/TableClothBlockItem.java'
Change $item 'import com.simibubi.create.content.logistics.redstoneRequester.RedstoneRequesterBlock;' "import com.simibubi.create.AllDataComponents;`nimport com.simibubi.create.content.logistics.redstoneRequester.RedstoneRequesterBlock;"
Change $item "import net.minecraft.nbt.CompoundTag;`n" ''
Change $item "import net.minecraft.world.level.Level;`n" ''
$oldFoil=@'
		CompoundTag tag = pStack.getTag();
		return tag != null && tag.contains("TargetOffset");
'@
Change $item $oldFoil.TrimEnd("`r","`n") "`t`treturn pStack.has(AllDataComponents.AUTO_REQUEST_DATA);"
Change $item 'public void appendHoverText(ItemStack pStack, Level pLevel, List<Component> pTooltip, TooltipFlag pFlag)' 'public void appendHoverText(ItemStack pStack, TooltipContext tooltipContext, List<Component> pTooltip, TooltipFlag pFlag)'
Change $item 'super.appendHoverText(pStack, pLevel, pTooltip, pFlag);' 'super.appendHoverText(pStack, tooltipContext, pTooltip, pFlag);'
$args=[Collections.Generic.List[string]](Get-Content "$root/integration-compile.args")
$line='"'+("$root/source/fabric/$intRel").Replace('\','/')+'"'
if(!$args.Contains($line)){$args.Add($line);[IO.File]::WriteAllLines("$root/integration-compile.args",$args)}
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
$baselineLock|ConvertTo-Json -Depth 20|Set-Content "$root/baseline-reference-lock.json"
$upstreamLock|ConvertTo-Json -Depth 20|Set-Content "$root/upstream-lock.json"
