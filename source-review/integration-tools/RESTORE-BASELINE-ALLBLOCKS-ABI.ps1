$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$relative = 'AllBlocks.java'
$path = Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$relative"
$text = [IO.File]::ReadAllText($path)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$changes = [Collections.Generic.List[object]]::new()
function Change([string] $from, [string] $to) {
	$from = $from.Replace("`n", $script:newline); $to = $to.Replace("`n", $script:newline)
	if (-not $script:text.Contains($from)) { throw "AllBlocks ABI anchor missing: $from" }
	$script:text = $script:text.Replace($from, $to)
	$script:changes.Add([pscustomobject]@{ from = $from; to = $to })
}

Change 'import com.simibubi.create.content.decoration.MetalLadderBlock;' "import com.simibubi.create.content.decoration.CardboardBlock;`nimport com.simibubi.create.content.decoration.MetalLadderBlock;"
Change 'import com.simibubi.create.foundation.item.ItemDescription;' "import com.simibubi.create.foundation.item.ItemDescription;`nimport com.simibubi.create.foundation.mixin.accessor.BlockLootSubProviderAccessor;"
Change "`tpublic static final BlockEntry<Block> BRASS_BLOCK" "`tpublic static final BlockEntry<Block> WEATHERED_IRON_BLOCK = REGISTRATE.block(`"weathered_iron_block`", Block::new)`n`t`t.transform(BuilderTransformers.palettesIronBlock())`n`t`t.lang(`"Block of Weathered Iron`")`n`t`t.register();`n`n`tpublic static final BlockEntry<Block> BRASS_BLOCK"

$cardboard = @'
	public static final BlockEntry<CardboardBlock> CARDBOARD_BLOCK =
		REGISTRATE.block("cardboard_block", CardboardBlock::new)
			.initialProperties(() -> Blocks.MUSHROOM_STEM)
			.properties(p -> p.mapColor(MapColor.COLOR_BROWN)
				.sound(SoundType.CHISELED_BOOKSHELF)
				.ignitedByLava())
			.transform(axeOnly())
			.blockstate(BlockStateGen.horizontalAxisBlockProvider(false))
			.tag(AllBlockTags.CARDBOARD_STORAGE_BLOCKS.tag)
			.item()
			.tag(AllItemTags.CARDBOARD_STORAGE_BLOCKS.tag)
			.build()
			.lang("Block of Cardboard")
			.register();

	public static final BlockEntry<CardboardBlock> BOUND_CARDBOARD_BLOCK =
		REGISTRATE.block("bound_cardboard_block", CardboardBlock::new)
			.initialProperties(() -> Blocks.MUSHROOM_STEM)
			.properties(p -> p.mapColor(MapColor.COLOR_BROWN)
				.sound(SoundType.CHISELED_BOOKSHELF)
				.ignitedByLava())
			.transform(axeOnly())
			.blockstate(BlockStateGen.horizontalAxisBlockProvider(false))
			.loot((r, b) -> r.add(b, LootTable.lootTable()
				.withPool(LootPool.lootPool()
					.setRolls(ConstantValue.exactly(1.0F))
					.add(LootItem.lootTableItem(b)
						.when(((BlockLootSubProviderAccessor) r).create$hasSilkTouch())
						.otherwise(r.applyExplosionCondition(b, LootItem.lootTableItem(Items.STRING)))))
				.withPool(r.applyExplosionCondition(b, LootPool.lootPool()
					.setRolls(ConstantValue.exactly(1.0F))
					.add(LootItem.lootTableItem(AllBlocks.CARDBOARD_BLOCK.asItem()))
					.when(((BlockLootSubProviderAccessor) r).create$hasSilkTouch().invert())))))
			.item()
			.build()
			.lang("Bound Block of Cardboard")
			.register();

'@
Change "`tpublic static final CopperBlockSet COPPER_SHINGLES" ($cardboard.Replace("`n", $newline) + "`tpublic static final CopperBlockSet COPPER_SHINGLES")
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))

$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq $relative
$entry.changes = @($entry.changes) + @($changes)
$entry.status = 'Original Create 6 logistics registrations retained together with the published baseline weathered-iron and cardboard ABI.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
Write-Output 'Restored retained AllBlocks weathered-iron and cardboard ABI.'
