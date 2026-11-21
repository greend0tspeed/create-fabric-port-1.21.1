$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

function Add-Change([string] $path, [string] $from, [string] $to, [string] $status) {
	$entry = $manifest.files | Where-Object path -eq $path
	if (-not $entry) { throw "Missing manifest entry: $path" }
	if (@($entry.changes | Where-Object { $_.from -ceq $from -and $_.to -ceq $to }).Count -eq 0) {
		$entry.changes = @($entry.changes) + [pscustomobject]@{ from = $from; to = $to }
	}
	$entry.status = $status
}

$crlf = "`r`n"
$lf = "`n"

Add-Change 'AllItems.java' `
	("import com.simibubi.create.content.equipment.armor.BacktankItem.BacktankBlockItem;${crlf}import com.simibubi.create.content.equipment.armor.DivingBootsItem;") `
	("import com.simibubi.create.content.equipment.armor.BacktankItem.BacktankBlockItem;${crlf}import com.simibubi.create.content.equipment.armor.BaseArmorItem;${lf}import com.simibubi.create.content.equipment.armor.CardboardArmorItem;${lf}import com.simibubi.create.content.equipment.armor.DivingBootsItem;") `
	'Original registry definitions restored with all published baseline cardboard-item and armor ABI; compilation clean and runtime validation active'

$itemFrom = @"
		PROPELLER = ingredient("propeller"), WHISK = ingredient("whisk"), BRASS_HAND = ingredient("brass_hand"),
		CRAFTER_SLOT_COVER = ingredient("crafter_slot_cover"), ELECTRON_TUBE = ingredient("electron_tube");

	public static final ItemEntry<SequencedAssemblyItem>
"@.Replace("`n", $crlf).TrimEnd("`r", "`n")
$itemTo = "`t`tPROPELLER = ingredient(`"propeller`"), WHISK = ingredient(`"whisk`"), BRASS_HAND = ingredient(`"brass_hand`"),${lf}" +
	"`t`tCRAFTER_SLOT_COVER = ingredient(`"crafter_slot_cover`"), ELECTRON_TUBE = ingredient(`"electron_tube`"),${lf}" +
	"`t`tTRANSMITTER = ingredient(`"transmitter`"), PULP = ingredient(`"pulp`");${lf}${lf}" +
	"`tpublic static final ItemEntry<Item> CARDBOARD = REGISTRATE.item(`"cardboard`", Item::new)${lf}" +
	"`t`t.tag(AllItemTags.CARDBOARD_PLATES.tag, PLATES.tag)${lf}" +
	"`t`t.register();${lf}${crlf}" +
	"`tpublic static final ItemEntry<SequencedAssemblyItem>"
Add-Change 'AllItems.java' $itemFrom $itemTo 'Original registry definitions restored with all published baseline cardboard-item and armor ABI; compilation clean and runtime validation active'

$armorFrom = "`t`t`t.properties(p -> p.fireResistant())${crlf}`t`t`t.tag(forgeItemTag(`"boots`"))${crlf}`t`t`t.register();${crlf}${crlf}`tpublic static final ItemEntry<SandPaperItem> SAND_PAPER"
$armorBlock = @'
	public static final ItemEntry<? extends BaseArmorItem>

		CARDBOARD_HELMET = REGISTRATE.item("cardboard_helmet", p -> new CardboardArmorItem(ArmorItem.Type.HELMET, p))
			.properties(p -> p.durability(ArmorItem.Type.HELMET.getDurability(4)))
			.tag(ItemTags.HEAD_ARMOR)
			.tag(forgeItemTag("helmets"))
			.onRegisterAfter(Registries.ITEM, v -> ItemDescription.useKey(v, "item.create.cardboard_armor"))
			.register(),

		CARDBOARD_CHESTPLATE =
			REGISTRATE.item("cardboard_chestplate", p -> new CardboardArmorItem(ArmorItem.Type.CHESTPLATE, p))
				.properties(p -> p.durability(ArmorItem.Type.CHESTPLATE.getDurability(4)))
				.tag(ItemTags.CHEST_ARMOR)
				.tag(forgeItemTag("chestplates"))
				.onRegisterAfter(Registries.ITEM, v -> ItemDescription.useKey(v, "item.create.cardboard_armor"))
				.register(),

		CARDBOARD_LEGGINGS =
			REGISTRATE.item("cardboard_leggings", p -> new CardboardArmorItem(ArmorItem.Type.LEGGINGS, p))
				.properties(p -> p.durability(ArmorItem.Type.LEGGINGS.getDurability(4)))
				.tag(ItemTags.LEG_ARMOR)
				.tag(forgeItemTag("leggings"))
				.onRegisterAfter(Registries.ITEM, v -> ItemDescription.useKey(v, "item.create.cardboard_armor"))
				.register(),

		CARDBOARD_BOOTS = REGISTRATE.item("cardboard_boots", p -> new CardboardArmorItem(ArmorItem.Type.BOOTS, p))
			.properties(p -> p.durability(ArmorItem.Type.BOOTS.getDurability(4)))
			.tag(ItemTags.FOOT_ARMOR)
			.tag(forgeItemTag("boots"))
			.onRegisterAfter(Registries.ITEM, v -> ItemDescription.useKey(v, "item.create.cardboard_armor"))
			.register();
'@.Replace("`r`n", $lf).TrimEnd("`r", "`n")
$armorTo = "`t`t`t.properties(p -> p.fireResistant())${crlf}`t`t`t.tag(forgeItemTag(`"boots`"))${crlf}`t`t`t.register();${crlf}${lf}${armorBlock}${lf}${crlf}`tpublic static final ItemEntry<SandPaperItem> SAND_PAPER"
Add-Change 'AllItems.java' $armorFrom $armorTo 'Original registry definitions restored with all published baseline cardboard-item and armor ABI; compilation clean and runtime validation active'

Add-Change 'AllPartialModels.java' `
	("import com.simibubi.create.content.fluids.FluidTransportBehaviour;${crlf}import com.simibubi.create.foundation.utility.Couple;") `
	("import com.simibubi.create.content.fluids.FluidTransportBehaviour;${crlf}import com.simibubi.create.content.logistics.box.PackageStyles;${crlf}import com.simibubi.create.content.logistics.box.PackageStyles.PackageStyle;${crlf}import com.simibubi.create.foundation.utility.Couple;") `
	'Original model registries restored with native Create package-style model population; compilation clean and runtime validation active'

$initFrom = "`tpublic static void init() {${crlf}`t`t// init static fields${crlf}`t}"
$initTo = @'
	public static void init() {
		for (PackageStyle style : PackageStyles.STYLES) {
			ResourceLocation key = style.getItemId();
			PartialModel model = new PartialModel(Create.asResource("item/" + key.getPath()));
			PACKAGES.put(key, model);
			if (!style.rare())
				PACKAGES_TO_HIDE_AS.add(model);
			PACKAGE_RIGGING.put(key, new PartialModel(style.getRiggingModel()));
		}
	}
'@.Replace("`r", '').Replace("`n", $crlf).TrimEnd("`r", "`n")
Add-Change 'AllPartialModels.java' $initFrom $initTo 'Original model registries restored with native Create package-style model population; compilation clean and runtime validation active'

Add-Change 'AllPartialModels.java' `
	("`tpublic static final Map<ResourceLocation, PartialModel> PACKAGES = new HashMap<>();${lf}${lf}`tpublic static final PartialModel") `
	("`tpublic static final Map<ResourceLocation, PartialModel> PACKAGES = new HashMap<>();${lf}${crlf}`tpublic static final List<PartialModel> PACKAGES_TO_HIDE_AS = new ArrayList<>();${crlf}${lf}`tpublic static final PartialModel") `
	'Original model registries restored with native Create package-style model population; compilation clean and runtime validation active'

$spriteFrom = "`t`tORNATE_IRON_WINDOW = vertical(`"palettes/ornate_iron_window`");"
$spriteTo = @'
		ORNATE_IRON_WINDOW = vertical("palettes/ornate_iron_window"),
		INDUSTRIAL_IRON_WINDOW = getCT(AllCTTypes.RECTANGLE, "palettes/industrial_iron_window"),
		OLD_FACTORY_WINDOW_1 = getCT(AllCTTypes.RECTANGLE, "palettes/weathered_iron_window", "palettes/weathered_iron_window_1"),
		OLD_FACTORY_WINDOW_2 = getCT(AllCTTypes.RECTANGLE, "palettes/weathered_iron_window", "palettes/weathered_iron_window_2"),
		OLD_FACTORY_WINDOW_3 = getCT(AllCTTypes.RECTANGLE, "palettes/weathered_iron_window", "palettes/weathered_iron_window_3"),
		OLD_FACTORY_WINDOW_4 = getCT(AllCTTypes.RECTANGLE, "palettes/weathered_iron_window", "palettes/weathered_iron_window_4");
'@.Replace("`r", '').Replace("`n", $crlf).TrimEnd("`r", "`n")
Add-Change 'AllSpriteShifts.java' $spriteFrom $spriteTo 'Original sprite registries restored with the published baseline industrial/weathered window ABI; compilation clean and runtime validation active'

$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
Write-Output 'Recorded exact baseline ABI restoration transformations.'
