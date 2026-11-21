package com.simibubi.create.foundation.mixin;

import java.util.List;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;

import com.llamalad7.mixinextras.injector.v2.WrapWithCondition;
import com.simibubi.create.content.kinetics.deployer.DeployerHandler;

import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;

@Mixin(Block.class)
public class BlockMixin {
	@WrapWithCondition(method = "method_36993(Lnet/minecraft/class_1937;Ljava/util/function/Supplier;Lnet/minecraft/class_1799;)V", at = @At(value = "INVOKE", target = "Lnet/minecraft/class_1937;method_8649(Lnet/minecraft/class_1297;)Z", remap = false), remap = false)
	private static boolean create$handlePopResource(Level instance, Entity entity) {
		List<ItemEntity> list = DeployerHandler.CAPTURED_BLOCK_DROPS_VIEW.get(entity.blockPosition());
		if (list != null) {
			list.add((ItemEntity) entity);
			return false;
		}
		return true;
	}
}
