$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$relative = 'content/equipment/blueprint/BlueprintOverlayRenderer.java'
$reference = Join-Path $root "baseline-reference/src/main/java/com/simibubi/create/$relative"
$destination = Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$relative"
$text = [IO.File]::ReadAllText($reference)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$changes = [Collections.Generic.List[object]]::new()

function Change([string] $from, [string] $to) {
	$from = $from.Replace("`n", $script:newline)
	$to = $to.Replace("`n", $script:newline)
	if (-not $script:text.Contains($from)) { throw "Blueprint fidelity anchor missing: $from" }
	$script:text = $script:text.Replace($from, $to)
	$script:changes.Add([pscustomobject]@{ from = $from; to = $to })
}

Change 'import com.simibubi.create.content.logistics.filter.AttributeFilterMenu.WhitelistMode;' "import com.simibubi.create.content.logistics.BigItemStack;`nimport com.simibubi.create.content.logistics.filter.AttributeFilterMenu.WhitelistMode;`nimport com.simibubi.create.content.logistics.packager.InventorySummary;`nimport com.simibubi.create.content.logistics.tableCloth.BlueprintOverlayShopContext;`nimport com.simibubi.create.content.logistics.tableCloth.ShoppingListItem.ShoppingList;`nimport com.simibubi.create.content.logistics.tableCloth.TableClothBlockEntity;"
Change 'import com.simibubi.create.foundation.utility.AnimationTickHolder;' "import com.simibubi.create.foundation.utility.AnimationTickHolder;`nimport com.simibubi.create.foundation.utility.Couple;`nimport com.simibubi.create.foundation.utility.Iterate;"
Change 'import net.minecraft.client.gui.GuiGraphics;' "import net.minecraft.client.gui.GuiGraphics;`nimport net.minecraft.client.gui.screens.inventory.tooltip.TooltipRenderUtil;"
Change 'import net.minecraft.nbt.ListTag;' "import net.minecraft.nbt.ListTag;`nimport net.minecraft.network.chat.Component;`nimport net.minecraft.world.entity.player.Player;"
Change 'import net.minecraft.world.item.Item;' "import net.minecraft.world.item.Item;`nimport net.minecraft.world.item.Item.TooltipContext;"
Change 'import net.minecraft.world.item.Items;' "import net.minecraft.world.item.Items;`nimport net.minecraft.world.item.TooltipFlag;"

Change "`tstatic BlueprintSection lastTargetedSection;" "`tstatic BlueprintSection lastTargetedSection;`n`tstatic BlueprintOverlayShopContext shopContext;"
Change "`tstatic ItemStack result = ItemStack.EMPTY;" "`tstatic List<ItemStack> results = new ArrayList<>();"
Change "`t`tnoOutput = false;" "`t`tnoOutput = false;`n`t`tshopContext = null;"

$displayStart = $text.IndexOf("`tpublic static void displayTrackRequirements")
$rebuildStart = $text.IndexOf("`tpublic static void rebuild", $displayStart)
if ($displayStart -lt 0 -or $rebuildStart -lt 0) { throw 'Blueprint display section missing.' }
$oldDisplay = $text.Substring($displayStart, $rebuildStart - $displayStart)
$newDisplay = @'
	public static void displayTrackRequirements(PlacementInfo info, ItemStack pavementItem) {
		if (active)
			return;
		prepareCustomOverlay();

		int tracks = info.requiredTracks;
		while (tracks > 0) {
			ingredients.add(
				Pair.of(new ItemStack(info.trackMaterial.getBlock(), Math.min(64, tracks)), info.hasRequiredTracks));
			tracks -= 64;
		}

		int pavement = info.requiredPavement;
		while (pavement > 0) {
			ingredients.add(Pair.of(ItemHandlerHelper.copyStackWithSize(pavementItem, Math.min(64, pavement)),
				info.hasRequiredPavement));
			pavement -= 64;
		}
	}

	public static void displayChainRequirements(Item chainItem, int count, boolean fulfilled) {
		if (active)
			return;
		prepareCustomOverlay();

		int chains = count;
		while (chains > 0) {
			ingredients.add(Pair.of(new ItemStack(chainItem, Math.min(64, chains)), fulfilled));
			chains -= 64;
		}
	}

	public static void displayClothShop(TableClothBlockEntity dce, int alreadyPurchased, ShoppingList list) {
		if (active)
			return;
		prepareCustomOverlay();
		noOutput = false;

		shopContext = new BlueprintOverlayShopContext(false, dce.getStockLevelForTrade(list), alreadyPurchased);

		ingredients.add(Pair.of(dce.getPaymentItem()
				.copyWithCount(dce.getPaymentAmount()),
			!dce.getPaymentItem()
				.isEmpty() && shopContext.stockLevel() > shopContext.purchases()));
		for (BigItemStack entry : dce.requestData.encodedRequest().stacks())
			results.add(entry.stack.copyWithCount(entry.count));
	}

	public static void displayShoppingList(Couple<InventorySummary> bakedList) {
		if (active || bakedList == null)
			return;
		Minecraft mc = Minecraft.getInstance();
		prepareCustomOverlay();
		noOutput = false;

		shopContext = new BlueprintOverlayShopContext(true, 1, 0);

		for (BigItemStack entry : bakedList.getSecond()
			.getStacksByCount()) {
			ingredients.add(Pair.of(entry.stack.copyWithCount(entry.count), canAfford(mc.player, entry)));
		}

		for (BigItemStack entry : bakedList.getFirst()
			.getStacksByCount())
			results.add(entry.stack.copyWithCount(entry.count));
	}

	private static boolean canAfford(Player player, BigItemStack entry) {
		int itemsPresent = 0;
		for (int i = 0; i < player.getInventory().items.size(); i++) {
			ItemStack item = player.getInventory()
				.getItem(i);
			if (item.isEmpty() || !ItemStack.isSameItemSameComponents(item, entry.stack))
				continue;
			itemsPresent += item.getCount();
		}
		return itemsPresent >= entry.count;
	}

	private static void prepareCustomOverlay() {
		active = true;
		empty = false;
		noOutput = true;
		ingredients.clear();
		results.clear();
		shopContext = null;
	}

'@.Replace("`n", $newline)
if (-not $text.Contains($oldDisplay)) { throw 'Blueprint display block changed unexpectedly.' }
$text = $text.Replace($oldDisplay, $newDisplay)
$changes.Add([pscustomobject]@{ from = $oldDisplay; to = $newDisplay })

Change 'BlueprintOverlayRenderer.result = ItemStack.EMPTY;' 'BlueprintOverlayRenderer.results.clear();'
Change "`t`t`t`t`t`tif (result.isEmpty())`n`t`t`t`t`t`t`tresult = resultFromRecipe.copy();`n`t`t`t`t`t`telse`n`t`t`t`t`t`t`tresult.grow(resultFromRecipe.getCount());" "`t`t`t`t`t`tif (results.isEmpty())`n`t`t`t`t`t`t`tresults.add(resultFromRecipe.copy());`n`t`t`t`t`t`telse`n`t`t`t`t`t`t`tresults.get(0).grow(resultFromRecipe.getCount());"
Change 'result = invalid ? ItemStack.EMPTY : items.getStackInSlot(9);' "results.clear();`n`t`t`t`t`tif (!invalid)`n`t`t`t`t`t`tresults.add(items.getStackInSlot(9));"

$renderStart = $text.IndexOf("`tpublic static void renderOverlay")
$drawStart = $text.IndexOf("`tpublic static void drawItemStack", $renderStart)
if ($renderStart -lt 0 -or $drawStart -lt 0) { throw 'Blueprint render section missing.' }
$oldRender = $text.Substring($renderStart, $drawStart - $renderStart)
$newRender = @'
	public static void renderOverlay(GuiGraphics graphics, float partialTicks, Window window) {
		Minecraft mc = Minecraft.getInstance();
		if (mc.options.hideGui || mc.screen != null)
			return;
		if (!active || empty)
			return;

		boolean invalidShop = shopContext != null && (ingredients.isEmpty() || ingredients.get(0)
			.getFirst()
			.isEmpty() || shopContext.stockLevel() == 0);

		int w = 21 * ingredients.size();
		if (!noOutput) {
			w += 21 * results.size();
			w += 30;
		}

		int x = (window.getGuiScaledWidth() - w) / 2;
		int y = window.getGuiScaledHeight() - 100;

		if (shopContext != null) {
			TooltipRenderUtil.renderTooltipBackground(graphics, x - 2, y + 1, w + 4, 19, 0);
			AllGuiTextures.TRADE_OVERLAY.render(graphics, window.getGuiScaledWidth() / 2 - 48, y - 19);
			if (shopContext.purchases() > 0) {
				graphics.renderItem(AllItems.SHOPPING_LIST.asStack(), window.getGuiScaledWidth() / 2 + 20, y - 20);
				graphics.drawString(mc.font, Component.literal("x" + shopContext.purchases()), window.getGuiScaledWidth() / 2 + 36,
					y - 16, 0xff_eeeeee, true);
			}
		}

		for (Pair<ItemStack, Boolean> pair : ingredients) {
			RenderSystem.enableBlend();
			(pair.getSecond() ? AllGuiTextures.HOTSLOT_ACTIVE : AllGuiTextures.HOTSLOT).render(graphics, x, y);
			ItemStack itemStack = pair.getFirst();
			String count = shopContext != null && !shopContext.checkout() || pair.getSecond() ? null
				: ChatFormatting.GOLD.toString() + itemStack.getCount();
			drawItemStack(graphics, mc, x, y, itemStack, count);
			x += 21;
		}

		if (noOutput)
			return;

		x += 5;
		RenderSystem.enableBlend();
		(invalidShop ? AllGuiTextures.HOTSLOT_ARROW_BAD : AllGuiTextures.HOTSLOT_ARROW).render(graphics, x, y + 4);
		x += 25;

		if (results.isEmpty()) {
			AllGuiTextures.HOTSLOT.render(graphics, x, y);
			GuiGameElement.of(Items.BARRIER).at(x + 3, y + 3).render(graphics);
		} else {
			for (ItemStack result : results) {
				AllGuiTextures slot = resultCraftable ? AllGuiTextures.HOTSLOT_SUPER_ACTIVE : AllGuiTextures.HOTSLOT;
				if (!invalidShop && shopContext != null && shopContext.stockLevel() > shopContext.purchases())
					slot = AllGuiTextures.HOTSLOT_ACTIVE;
				slot.render(graphics, resultCraftable ? x - 1 : x, resultCraftable ? y - 1 : y);
				drawItemStack(graphics, mc, x, y, result, null);
				x += 21;
			}
		}

		if (shopContext != null && !shopContext.checkout()) {
			int cycle = 0;
			for (boolean count : Iterate.trueAndFalse)
				for (int i = 0; i < results.size(); i++) {
					ItemStack result = results.get(i);
					List<Component> tooltipLines = result.getTooltipLines(TooltipContext.of(mc.level), mc.player, TooltipFlag.NORMAL);
					if (tooltipLines.size() <= 1)
						continue;
					if (count) {
						cycle++;
						continue;
					}
					if ((mc.gui.getGuiTicks() / 40) % cycle != i)
						continue;
					graphics.renderComponentTooltip(mc.gui.getFont(), tooltipLines, window.getGuiScaledWidth(), window.getGuiScaledHeight());
				}
		}
		RenderSystem.disableBlend();
	}

'@.Replace("`n", $newline)
if (-not $text.Contains($oldRender)) { throw 'Blueprint render block changed unexpectedly.' }
$text = $text.Replace($oldRender, $newRender)
$changes.Add([pscustomobject]@{ from = $oldRender; to = $newRender })

[IO.File]::WriteAllText($destination, $text, [Text.UTF8Encoding]::new($false))
$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$entry = $manifest.files | Where-Object path -eq $relative
$entry.sourceRoot = 'baseline-reference'
$entry.changes = @($changes)
$entry.status = 'Complete native Create 6 chain, shop, shopping-list, affordability, multi-output and tooltip overlay logic restored on the compatible Fabric renderer.'
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
Write-Output 'Restored complete native Blueprint logistics overlay behavior.'
