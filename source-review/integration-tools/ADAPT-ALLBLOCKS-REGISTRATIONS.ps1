$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$relative = 'src/main/java/com/simibubi/create/AllBlocks.java'
$sourcePath = Join-Path $root "source/fabric/$relative"
$changesPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $changesPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object { $_.path -eq 'AllBlocks.java' }
if (-not $entry) { throw 'AllBlocks.java is not tracked in port-changes.json' }

$adaptations = @(
    [pscustomobject]@{
        from = "import com.simibubi.create.foundation.data.recipe.CommonMetal;`n"
        to = ''
    },
    [pscustomobject]@{
        from = "import static com.simibubi.create.api.behaviour.display.DisplaySource.displaySource;`n"
        to = ''
    },
    [pscustomobject]@{
        from = "import com.simibubi.create.infrastructure.config.CStress;`n"
        to = ''
    },
    [pscustomobject]@{
        from = "import com.simibubi.create.content.logistics.tableCloth.TableClothBlock;"
        to = "import com.simibubi.create.content.logistics.tableCloth.TableClothBlock;`nimport com.simibubi.create.content.logistics.tableCloth.TableClothBlockItem;`nimport com.simibubi.create.content.logistics.tableCloth.TableClothModel;`nimport com.simibubi.create.content.logistics.packager.PackagerGenerator;"
    },
    [pscustomobject]@{
        from = "import com.tterrag.registrate.providers.RegistrateRecipeProvider;"
        to = "import com.tterrag.registrate.builders.BlockBuilder;`r`nimport com.tterrag.registrate.builders.ItemBuilder;`r`nimport com.tterrag.registrate.providers.RegistrateRecipeProvider;"
    },
    [pscustomobject]@{
        from = "import com.tterrag.registrate.util.entry.BlockEntry;"
        to = "import com.tterrag.registrate.util.entry.BlockEntry;`r`nimport com.tterrag.registrate.util.nullness.NonNullSupplier;`r`nimport com.tterrag.registrate.util.nullness.NonNullUnaryOperator;"
    },
    [pscustomobject]@{
        from = "`t`t`t.transform(CStress.setImpact(1))`n`t`t`t.transform(CStress.setImpact(1))"
        to = "`t`t`t.transform(BlockStressDefaults.setImpact(1))"
    },
    [pscustomobject]@{
        from = 'BuilderTransformers.packager()'
        to = 'nativePackager()'
    },
    [pscustomobject]@{
        from = 'BuilderTransformers.tableCloth('
        to = 'nativeTableCloth('
    },
    [pscustomobject]@{
        from = 'colour.getTag()'
        to = 'AllTags.forgeItemTag("dyes/" + colourName)'
    },
    [pscustomobject]@{
        from = 'CommonMetal.BRASS.ingots'
        to = 'AllTags.forgeItemTag("ingots/brass")'
    },
    [pscustomobject]@{
        from = 'CommonMetal.COPPER.ingots'
        to = 'AllTags.forgeItemTag("ingots/copper")'
    },
    [pscustomobject]@{
        from = "`t`t`t.lang(`"Copper Table Cover`")`n`t`t`t.register();`n}"
        to = @"
			.lang("Copper Table Cover")
			.register();

	// Create 6's original BuilderTransformers methods are kept here until the
	// complete 1.21.1 Fabric BuilderTransformers source replaces the baseline binary.
	private static <B extends Block, P> NonNullUnaryOperator<BlockBuilder<B, P>> nativePackager() {
		return b -> b.initialProperties(SharedProperties::softMetal)
			.properties(p -> p.noOcclusion())
			.properties(p -> p.isRedstoneConductor((state, level, pos) -> false))
			.properties(p -> p.mapColor(MapColor.TERRACOTTA_BLUE)
				.sound(SoundType.NETHERITE_BLOCK))
			.transform(pickaxeOnly())
			.addLayer(() -> RenderType::cutoutMipped)
			.blockstate(new PackagerGenerator()::generate)
			.item()
			.model(AssetLookup::customItemModel)
			.build();
	}

	private static <B extends Block, P> NonNullUnaryOperator<BlockBuilder<B, P>> nativeTableCloth(String name,
		NonNullSupplier<? extends Block> initialProps, boolean dyed) {
		return b -> {
			var soundTag = dyed ? BlockTags.COMBINATION_STEP_SOUND_BLOCKS : BlockTags.INSIDE_STEP_SOUND_BLOCKS;
			ItemBuilder<TableClothBlockItem, BlockBuilder<B, P>> item = b.initialProperties(initialProps)
				.addLayer(() -> RenderType::cutoutMipped)
				.blockstate((c, p) -> p.simpleBlock(c.get(), p.models()
					.withExistingParent(name + "_table_cloth", p.modLoc("block/table_cloth/block"))
					.texture("0", p.modLoc("block/table_cloth/" + name))))
				.onRegister(CreateRegistrate.blockModel(() -> TableClothModel::new))
				.tag(AllBlockTags.TABLE_CLOTHS.tag, soundTag)
				.onRegisterAfter(Registries.ITEM, v -> ItemDescription.useKey(v, "block.create.table_cloth"))
				.item(TableClothBlockItem::new);

			if (dyed)
				item.tag(AllItemTags.DYED_TABLE_CLOTHS.tag);

			return item.model((c, p) -> p.withExistingParent(name + "_table_cloth", p.modLoc("block/table_cloth/item"))
					.texture("0", p.modLoc("block/table_cloth/" + name)))
				.tag(AllItemTags.TABLE_CLOTHS.tag)
				.recipe((c, p) -> ShapelessRecipeBuilder.shapeless(RecipeCategory.MISC, c.get())
					.requires(c.get())
					.unlockedBy("has_" + c.getName(), RegistrateRecipeProvider.has(c.get()))
					.save(p, Create.asResource("crafting/logistics/" + c.getName() + "_clear")))
				.build();
		};
	}
}
"@
    }
)

$text = [IO.File]::ReadAllText($sourcePath)
foreach ($adaptation in $adaptations) {
    if (-not $text.Contains($adaptation.from)) {
        throw "AllBlocks adaptation anchor not found: $($adaptation.from.Substring(0, [Math]::Min(80, $adaptation.from.Length)))"
    }
    $text = $text.Replace($adaptation.from, $adaptation.to)
}
[IO.File]::WriteAllText($sourcePath, $text, [Text.UTF8Encoding]::new($false))

$entry.changes = @($entry.changes) + $adaptations
$entry.status = 'Original Create 6 logistics registrations retained; 1.21.1 Fabric stress/tag APIs adapted and original packager/table-cloth builder transforms restored locally pending the full BuilderTransformers source port.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $changesPath -Encoding utf8

Write-Output "Adapted AllBlocks registrations with $($adaptations.Count) reviewed replacements."
