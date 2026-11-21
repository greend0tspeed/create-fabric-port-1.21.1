package com.simibubi.create.content.kinetics.chainConveyor;

import java.util.Collection;
import java.util.UUID;

import com.simibubi.create.foundation.networking.SimplePacketBase;
import com.simibubi.create.foundation.render.PlayerSkyhookRenderer;

import net.minecraft.network.RegistryFriendlyByteBuf;

public class ClientboundChainConveyorRidingPacket extends SimplePacketBase {

	private final Collection<UUID> uuids;

	public ClientboundChainConveyorRidingPacket(Collection<UUID> uuids) {
		this.uuids = uuids;
	}

	public ClientboundChainConveyorRidingPacket(RegistryFriendlyByteBuf buffer) {
		this.uuids = buffer.readList(RegistryFriendlyByteBuf::readUUID);
	}

	@Override
	public void write(RegistryFriendlyByteBuf buffer) {
		buffer.writeCollection(uuids, RegistryFriendlyByteBuf::writeUUID);
	}

	@Override
	public boolean handle(Context context) {
		context.enqueueWork(() -> {
			PlayerSkyhookRenderer.updatePlayerList(this.uuids);
		});
		return true;
	}
}
