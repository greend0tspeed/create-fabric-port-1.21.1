package com.simibubi.create.foundation.gui.menu;

import com.simibubi.create.content.logistics.filter.FilterItem;
import com.simibubi.create.content.logistics.stockTicker.StockKeeperCategoryMenu;
import com.simibubi.create.foundation.networking.SimplePacketBase;

import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.item.ItemStack;

public class GhostItemSubmitPacket extends SimplePacketBase {
	private final ItemStack item;
	private final int slot;

	public GhostItemSubmitPacket(ItemStack item, int slot) {
		this.item = item;
		this.slot = slot;
	}

	public GhostItemSubmitPacket(RegistryFriendlyByteBuf buffer) {
		item = ItemStack.OPTIONAL_STREAM_CODEC.decode(buffer);
		slot = buffer.readInt();
	}

	@Override
	public void write(RegistryFriendlyByteBuf buffer) {
		ItemStack.OPTIONAL_STREAM_CODEC.encode(buffer, item);
		buffer.writeInt(slot);
	}

	@Override
	public boolean handle(Context context) {
		context.enqueueWork(() -> {
			ServerPlayer player = context.getSender();
			if (player == null)
				return;
			if (player.containerMenu instanceof GhostItemMenu<?> menu) {
				menu.ghostInventory.setStackInSlot(slot, item);
				menu.getSlot(36 + slot).setChanged();
			}
			if (player.containerMenu instanceof StockKeeperCategoryMenu menu
				&& (item.isEmpty() || item.getItem() instanceof FilterItem)) {
				menu.proxyInventory.setStackInSlot(slot, item);
				menu.getSlot(36 + slot).setChanged();
			}
		});
		return true;
	}
}
