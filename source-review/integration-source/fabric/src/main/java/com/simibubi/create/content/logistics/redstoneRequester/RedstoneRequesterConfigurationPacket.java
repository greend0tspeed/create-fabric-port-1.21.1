package com.simibubi.create.content.logistics.redstoneRequester;

import java.util.ArrayList;
import java.util.List;

import com.simibubi.create.content.logistics.BigItemStack;
import com.simibubi.create.content.logistics.stockTicker.PackageOrderWithCrafts;
import com.simibubi.create.content.logistics.stockTicker.PackageOrder;
import com.simibubi.create.foundation.networking.BlockEntityConfigurationPacket;

import net.minecraft.core.BlockPos;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.world.item.ItemStack;
import net.minecraft.server.level.ServerPlayer;
import io.github.fabricators_of_create.porting_lib_ufo.transfer.item.ItemStackHandler;

public class RedstoneRequesterConfigurationPacket extends BlockEntityConfigurationPacket<RedstoneRequesterBlockEntity> {

	private String address;
	private boolean allowPartial;
	private List<Integer> amounts;
	private List<ItemStack> items;

	public RedstoneRequesterConfigurationPacket(BlockPos pos, String address, boolean allowPartial,
		List<Integer> amounts, ItemStackHandler inventory) {
		super(pos);
		this.address = address;
		this.allowPartial = allowPartial;
		this.amounts = amounts;
		this.items = new ArrayList<>();
		for (int i = 0; i < inventory.getSlotCount(); i++)
			items.add(inventory.getStackInSlot(i).copy());
	}

	public RedstoneRequesterConfigurationPacket(RegistryFriendlyByteBuf buffer) {
		super(buffer);
	}

	@Override
	protected void writeSettings(RegistryFriendlyByteBuf buffer) {
		buffer.writeUtf(address);
		buffer.writeBoolean(allowPartial);
		buffer.writeVarInt(amounts.size());
		amounts.forEach(buffer::writeVarInt);
		buffer.writeVarInt(items.size());
		items.forEach(item -> ItemStack.OPTIONAL_STREAM_CODEC.encode(buffer, item));
	}

	@Override
	protected void readSettings(RegistryFriendlyByteBuf buffer) {
		address = buffer.readUtf();
		allowPartial = buffer.readBoolean();
		int size = buffer.readVarInt();
		amounts = new ArrayList<>();
		for (int i = 0; i < size; i++)
			amounts.add(buffer.readVarInt());
		int itemCount = buffer.readVarInt();
		if (itemCount != 9 || size != 9)
			throw new IllegalArgumentException("Invalid requester slot count");
		items = new ArrayList<>();
		for (int i = 0; i < itemCount; i++)
			items.add(ItemStack.OPTIONAL_STREAM_CODEC.decode(buffer));
	}

	@Override
	protected void applySettings(ServerPlayer player, RedstoneRequesterBlockEntity be) {
		if (!be.behaviour.mayInteract(player))
			return;
		applySettings(be);
	}

	@Override
	protected void applySettings(RedstoneRequesterBlockEntity be) {
		be.encodedTargetAdress = address;
		List<BigItemStack> stacks = new ArrayList<>();
		for (int i = 0; i < items.size(); i++) {
			if (items.get(i).isEmpty())
				continue;
			stacks.add(new BigItemStack(items.get(i).copyWithCount(1), Math.max(1, Math.min(256, amounts.get(i)))));
		}
		PackageOrderWithCrafts request = new PackageOrderWithCrafts(new PackageOrder(stacks), be.encodedRequest.orderedCrafts());
		be.encodedRequest = request.orderedStacksMatchOrderedRecipes() ? request : PackageOrderWithCrafts.simple(stacks);
		be.allowPartialRequests = allowPartial;
	}

}
