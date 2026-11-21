package com.simibubi.create.content.logistics.redstoneRequester;

import java.util.List;

import com.simibubi.create.AllDataComponents;
import com.simibubi.create.content.logistics.packagerLink.LogisticallyLinkedBlockItem;
import com.simibubi.create.foundation.utility.Lang;

import net.minecraft.ChatFormatting;

import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.TooltipFlag;

import net.minecraft.world.level.block.Block;

public class RedstoneRequesterBlockItem extends LogisticallyLinkedBlockItem {

	public RedstoneRequesterBlockItem(Block pBlock, Properties pProperties) {
		super(pBlock, pProperties);
	}

	@Override
	public void appendHoverText(ItemStack pStack, TooltipContext tooltipContext, List<Component> pTooltip, TooltipFlag pFlag) {
		if (!isTuned(pStack))
			return;

		if (!pStack.has(AllDataComponents.AUTO_REQUEST_DATA)) {
			super.appendHoverText(pStack, tooltipContext, pTooltip, pFlag);
			return;
		}

		Lang.translate("logistically_linked.tooltip")
			.style(ChatFormatting.GOLD)
			.addTo(pTooltip);
		RedstoneRequesterBlock.appendRequesterTooltip(pStack, pTooltip);
	}

}
