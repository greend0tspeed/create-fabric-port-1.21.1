$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to){$entry=$script:manifest.files|Where-Object path -EQ $path;$file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file);if(!$text.Contains($from)){if($to.Length -gt 0 -and $text.Contains($to)){return};throw "Expected source missing: $path :: $from"};$entry.changes+=[pscustomobject]@{from=$from;to=$to};[IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))}
$shopping='content/logistics/tableCloth/ShoppingListItem.java'
Change $shopping 'import net.minecraft.ChatFormatting;' "import net.minecraft.ChatFormatting;`nimport net.minecraft.client.Minecraft;"
Change $shopping 'list.bakeEntries(context.level(), null)' 'list.bakeEntries(Minecraft.getInstance().level, null)'
$be='content/logistics/tableCloth/TableClothBlockEntity.java'
$oldTarget=@'
		return priceTag != null && priceTag.mayInteract(player) && priceTag.getSlotPositioning()
			.testHit(level, worldPosition, getBlockState(), ray.getLocation()
				.subtract(Vec3.atLowerCornerOf(worldPosition)));
'@
$newTarget=@'
		return priceTag instanceof TableClothFilteringBehaviour tableFilter
			&& tableFilter.mayInteract(player)
			&& priceTag.testHit(ray.getLocation());
'@
Change $be $oldTarget.TrimEnd("`r","`n") $newTarget.TrimEnd("`r","`n")
$filter='content/logistics/tableCloth/TableClothFilteringBehaviour.java'
Change $filter 'public void onShortInteract(Player player, InteractionHand hand, Direction side, BlockHitResult hitResult)' 'public void onShortInteract(Player player, InteractionHand hand, Direction side)'
Change $filter 'super.onShortInteract(player, hand, side, hitResult);' 'super.onShortInteract(player, hand, side);'
Change $filter "`t@Override`n`tpublic float getRenderDistance()" "`tpublic float getRenderDistance()"
Change $filter "`t@Override`n`tpublic boolean mayInteract(Player player)" "`tpublic boolean mayInteract(Player player)"
Change $filter 'return !filter.isEmpty();' 'return !getFilter().isEmpty();'
Change $filter "`t@Override`n`tpublic MutableComponent getCountLabelForValueBox()" "`tpublic MutableComponent getCountLabelForValueBox()"
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
