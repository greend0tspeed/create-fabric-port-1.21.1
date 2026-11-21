package com.simibubi.create.foundation.mixin.client;

import com.simibubi.create.foundation.render.PlayerSkyhookRenderer;
import net.minecraft.client.model.HumanoidModel;
import net.minecraft.client.player.AbstractClientPlayer;
import net.minecraft.world.entity.LivingEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Official Create 6 hanging-player pose hooks. */
@Mixin(HumanoidModel.class)
public class HumanoidModelMixin<T extends LivingEntity> {
	@Inject(method = "method_17087", at = @At("RETURN"))
	private void create$afterSetupAnim(T entity, float limbSwing, float limbSwingAmount, float ageInTicks,
		float netHeadYaw, float headPitch, CallbackInfo ci) {
		if (entity instanceof AbstractClientPlayer player)
			PlayerSkyhookRenderer.afterSetupAnim(player, (HumanoidModel<?>) (Object) this);
	}

	@Inject(method = "method_17087", at = @At("HEAD"))
	private void create$beforeSetupAnim(T entity, float limbSwing, float limbSwingAmount, float ageInTicks,
		float netHeadYaw, float headPitch, CallbackInfo ci) {
		if (entity instanceof AbstractClientPlayer player)
			PlayerSkyhookRenderer.beforeSetupAnim(player, (HumanoidModel<?>) (Object) this);
	}
}
