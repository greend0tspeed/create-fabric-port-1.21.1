package com.simibubi.create.foundation.mixin;

import com.simibubi.create.foundation.events.FrogportClientHooks;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(targets = "com.simibubi.create.foundation.events.ClientEvents")
public class FrogportClientEventsMixin {
	@Inject(method = "onTick", at = @At("TAIL"))
	private static void create$frogportTick(Minecraft client, CallbackInfo ci) {
		FrogportClientHooks.tick(client);
	}

	@Inject(method = "onLoadWorld", at = @At("TAIL"))
	private static void create$frogportRegister(Minecraft client, ClientLevel world, CallbackInfo ci) {
		FrogportClientHooks.register();
	}
}
