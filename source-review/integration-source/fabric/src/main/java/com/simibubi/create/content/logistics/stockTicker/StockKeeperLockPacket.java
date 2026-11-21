package com.simibubi.create.content.logistics.stockTicker;

import com.simibubi.create.Create;
import com.simibubi.create.content.logistics.packagerLink.LogisticsNetwork;
import com.simibubi.create.foundation.networking.BlockEntityConfigurationPacket;

import net.minecraft.core.BlockPos;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.server.level.ServerPlayer;

public class StockKeeperLockPacket extends BlockEntityConfigurationPacket<StockTickerBlockEntity> {

	private boolean lock;

	public StockKeeperLockPacket(BlockPos pos, boolean lock) {
		super(pos);
		this.lock = lock;
	}

	public StockKeeperLockPacket(RegistryFriendlyByteBuf buffer) {
		super(buffer);
	}

	@Override
	protected void writeSettings(RegistryFriendlyByteBuf buffer) {
		buffer.writeBoolean(lock);
	}

	@Override
	protected void readSettings(RegistryFriendlyByteBuf buffer) {
		lock = buffer.readBoolean();
	}

	@Override
	protected void applySettings(StockTickerBlockEntity be) {}

	@Override
	protected void applySettings(ServerPlayer player, StockTickerBlockEntity be) {
		if (!be.behaviour.mayAdministrate(player))
			return;
		LogisticsNetwork network = com.simibubi.create.content.logistics.packagerLink.GlobalLogisticsManager.INSTANCE.logisticsNetworks.get(be.behaviour.freqId);
		if (network != null) {
			network.locked = lock;
			com.simibubi.create.content.logistics.packagerLink.GlobalLogisticsManager.INSTANCE.markDirty();
		}
	}

}
