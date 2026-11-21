package com.simibubi.create.foundation.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import com.simibubi.create.content.kinetics.belt.BeltBlock;
import com.simibubi.create.content.kinetics.belt.BeltBlockEntity;
import com.simibubi.create.content.kinetics.belt.BeltHelper;
import com.simibubi.create.content.kinetics.belt.transport.BeltTunnelInteractionHandler;
import com.simibubi.create.content.logistics.box.PackageEntity;
import com.simibubi.create.foundation.utility.VecHelper;

import io.github.fabricators_of_create.porting_lib_ufo.transfer.TransferUtil;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.fabricmc.fabric.api.transfer.v1.storage.Storage;
import net.fabricmc.fabric.api.transfer.v1.transaction.Transaction;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;

@Mixin(BeltBlock.class)
public abstract class PackageEntityBeltInsertionMixin {

	@Inject(method = "method_9548", at = @At("HEAD"), cancellable = true, remap = false)
	private void create$insertPackageEntity(BlockState state, Level level, BlockPos pos, Entity entity,
		CallbackInfo ci) {
		if (!(entity instanceof PackageEntity packageEntity) || !BeltBlock.canTransportObjects(state))
			return;

		BeltBlockEntity belt = BeltHelper.getSegmentBE(level, pos);
		if (belt == null)
			return;

		ci.cancel();
		if (level.isClientSide || entity.getDeltaMovement().y > 0)
			return;

		Vec3 targetLocation = VecHelper.getCenterOf(pos)
			.add(0, 5 / 16f, 0);
		if (!PackageEntity.centerPackage(packageEntity, targetLocation))
			return;
		if (BeltTunnelInteractionHandler.getTunnelOnPosition(level, pos) != null)
			return;

		ItemStack packageStack = packageEntity.getBox();
		Storage<ItemVariant> handler = belt.getItemStorage(null);
		if (handler == null)
			return;

		ItemVariant packageVariant = ItemVariant.of(packageStack);
		try (Transaction transaction = TransferUtil.getTransaction()) {
			if (handler.insert(packageVariant, packageStack.getCount(), transaction) != packageStack.getCount())
				return;
			transaction.commit();
			packageEntity.discard();
		}
	}
}
