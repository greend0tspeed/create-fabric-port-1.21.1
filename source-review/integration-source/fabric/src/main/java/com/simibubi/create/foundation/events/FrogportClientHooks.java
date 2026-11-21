package com.simibubi.create.foundation.events;

import com.simibubi.create.content.kinetics.chainConveyor.ChainConveyorInteractionHandler;
import com.simibubi.create.content.kinetics.chainConveyor.ChainConveyorRidingHandler;
import com.simibubi.create.content.logistics.packagePort.PackagePortTargetSelectionHandler;
import io.github.fabricators_of_create.porting_lib_ufo.event.client.DrawSelectionEvents;
import net.fabricmc.fabric.api.client.rendering.v1.WorldRenderEvents;
import net.minecraft.client.Minecraft;

public final class FrogportClientHooks {
	private static boolean registered;

	private FrogportClientHooks() {}

	public static void tick(Minecraft client) {
		if (client.level == null || client.player == null)
			return;
		ChainConveyorInteractionHandler.clientTick();
		ChainConveyorRidingHandler.clientTick();
		PackagePortTargetSelectionHandler.tick();
	}

	public static void register() {
		if (registered)
			return;
		registered = true;
		DrawSelectionEvents.BLOCK.register(ChainConveyorInteractionHandler::drawCustomBlockSelection);
		WorldRenderEvents.BEFORE_BLOCK_OUTLINE.register(ChainConveyorInteractionHandler::hideVanillaBlockSelection);
	}
}
