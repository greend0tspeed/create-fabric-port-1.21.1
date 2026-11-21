package com.simibubi.create.content.logistics.stockTicker;

import com.simibubi.create.AllSoundEvents;
import com.simibubi.create.content.logistics.packagerLink.LogisticallyLinkedBehaviour.RequestType;
import com.simibubi.create.content.logistics.packagerLink.WiFiEffectPacket;
import com.simibubi.create.content.logistics.redstoneRequester.RedstoneRequesterBlock;
import com.simibubi.create.foundation.advancement.AllAdvancements;
import com.simibubi.create.foundation.networking.BlockEntityConfigurationPacket;

import net.minecraft.core.BlockPos;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.server.level.ServerPlayer;

public class PackageOrderRequestPacket extends BlockEntityConfigurationPacket<StockTickerBlockEntity> {

	private PackageOrderWithCrafts order;
	private String address;
	private boolean encodeRequester;

	public PackageOrderRequestPacket(BlockPos pos, PackageOrderWithCrafts order, String address, boolean encodeRequester) {
		super(pos);
		this.order = order;
		this.address = address;
		this.encodeRequester = encodeRequester;
	}

	public PackageOrderRequestPacket(RegistryFriendlyByteBuf buffer) {
		super(buffer);
	}

	@Override
	protected void writeSettings(RegistryFriendlyByteBuf buffer) {
		buffer.writeUtf(address);
		PackageOrderWithCrafts.STREAM_CODEC.encode(buffer, order);
		buffer.writeBoolean(encodeRequester);
	}

	@Override
	protected void readSettings(RegistryFriendlyByteBuf buffer) {
		address = buffer.readUtf();
		order = PackageOrderWithCrafts.STREAM_CODEC.decode(buffer);
		encodeRequester = buffer.readBoolean();
	}

	@Override
	protected void applySettings(StockTickerBlockEntity be) {
	}

	@Override
	protected void applySettings(ServerPlayer player, StockTickerBlockEntity be) {
		if (encodeRequester) {
			if (!order.isEmpty())
				AllSoundEvents.CONFIRM.playOnServer(be.getLevel(), pos);
			player.closeContainer();
			RedstoneRequesterBlock.programRequester(player, be, order, address);
			return;
		}

		if (!order.isEmpty()) {
			AllSoundEvents.STOCK_TICKER_REQUEST.playOnServer(be.getLevel(), pos);
			AllAdvancements.STOCK_TICKER.awardTo(player);
			WiFiEffectPacket.send(player.level(), pos);
		}

		be.broadcastPackageRequest(RequestType.PLAYER, order, null, address);
		return;
	}

}
