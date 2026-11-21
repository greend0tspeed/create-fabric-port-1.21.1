package com.simibubi.create.foundation.mixin;

import com.simibubi.create.content.kinetics.chainConveyor.ChainConveyorInteractionHandler;
import com.simibubi.create.content.logistics.packagePort.PackagePortTargetSelectionHandler;
import net.minecraft.client.Minecraft;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.phys.HitResult;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/** Restores the two official Create 6 chain/package-port use handlers. */
@Mixin(targets = "com.simibubi.create.foundation.events.InputEvents")
public class FrogportInputEventsMixin {
	@Inject(method = "onUse", at = @At("HEAD"), cancellable = true)
	private static void create$frogportOnUse(Minecraft client, HitResult hit, InteractionHand hand,
		CallbackInfoReturnable<InteractionResult> cir) {
		if (ChainConveyorInteractionHandler.onUse() || PackagePortTargetSelectionHandler.onUse())
			cir.setReturnValue(InteractionResult.SUCCESS);
	}
}
