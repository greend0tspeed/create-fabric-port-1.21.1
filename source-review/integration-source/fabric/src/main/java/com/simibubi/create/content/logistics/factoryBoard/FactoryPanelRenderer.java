package com.simibubi.create.content.logistics.factoryBoard;

import java.util.List;

import com.mojang.blaze3d.vertex.PoseStack;
import com.simibubi.create.AllPartialModels;
import com.simibubi.create.AllSpriteShifts;
import com.simibubi.create.content.redstone.displayLink.DisplayLinkBlockEntity;
import com.simibubi.create.content.redstone.link.RedstoneLinkBlockEntity;
import com.simibubi.create.foundation.blockEntity.renderer.SmartBlockEntityRenderer;
import com.simibubi.create.foundation.render.RenderTypes;

import com.jozufozu.flywheel.core.PartialModel;
import com.simibubi.create.foundation.render.CachedBufferer;
import com.simibubi.create.foundation.render.SuperByteBuffer;
import com.simibubi.create.foundation.utility.Color;
import net.minecraft.client.renderer.LightTexture;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider.Context;
import net.minecraft.core.Direction;
import net.minecraft.util.Mth;
import net.minecraft.world.level.block.state.BlockState;

public class FactoryPanelRenderer extends SmartBlockEntityRenderer<FactoryPanelBlockEntity> {

	public FactoryPanelRenderer(Context context) {
		super(context);
	}

	@Override
	protected void renderSafe(FactoryPanelBlockEntity be, float partialTicks, PoseStack ms, MultiBufferSource buffer,
		int light, int overlay) {
		super.renderSafe(be, partialTicks, ms, buffer, light, overlay);
		for (FactoryPanelBehaviour behaviour : be.panels.values()) {
			if (!behaviour.isActive())
				continue;
            if (!behaviour.getFilter().isEmpty()) {
                com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform slotPositioning = behaviour.getSlotPositioning();
                if (slotPositioning.shouldRender(be.getBlockState())) {
                    ms.pushPose();
                    slotPositioning.transform(be.getBlockState(), ms);
                    com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxRenderer.renderItemIntoValueBox(behaviour.getFilter(), ms, buffer, light, overlay);
                    ms.popPose();
                }
            }
			if (behaviour.getAmount() > 0)
				renderBulb(behaviour, partialTicks, ms, buffer, light, overlay);
			for (FactoryPanelConnection connection : behaviour.targetedBy.values())
				renderPath(behaviour, connection, partialTicks, ms, buffer, light, overlay);
			for (FactoryPanelConnection connection : behaviour.targetedByLinks.values())
				renderPath(behaviour, connection, partialTicks, ms, buffer, light, overlay);
		}
	}

    public static void tickHover() {
        net.minecraft.client.Minecraft mc = net.minecraft.client.Minecraft.getInstance();
        if (!(mc.hitResult instanceof net.minecraft.world.phys.BlockHitResult result) || mc.player.isShiftKeyDown())
            return;
        if (!(mc.level.getBlockEntity(result.getBlockPos()) instanceof FactoryPanelBlockEntity be))
            return;
        net.minecraft.world.level.block.state.BlockState state = be.getBlockState();
        net.minecraft.world.item.ItemStack held = mc.player.getMainHandItem();
        for (FactoryPanelBehaviour behaviour : be.panels.values()) {
            if (!behaviour.isActive())
                continue;
            com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform slot = behaviour.getSlotPositioning();
            if (!slot.shouldRender(state))
                continue;
            boolean hit = slot.testHit(state, result.getLocation().subtract(net.minecraft.world.phys.Vec3.atLowerCornerOf(be.getBlockPos())));
            net.minecraft.network.chat.Component label = behaviour.getLabel();
            net.minecraft.world.phys.AABB bb = new net.minecraft.world.phys.AABB(net.minecraft.world.phys.Vec3.ZERO, net.minecraft.world.phys.Vec3.ZERO).inflate(.25f);
            com.simibubi.create.foundation.blockEntity.behaviour.ValueBox box =
                new com.simibubi.create.foundation.blockEntity.behaviour.ValueBox.ItemValueBox(label, bb, be.getBlockPos(), behaviour.getFilter(), behaviour.getCountLabelForValueBox());
            box.passive(!hit || com.simibubi.create.AllBlocks.CLIPBOARD.isIn(held));
            com.simibubi.create.CreateClient.OUTLINER.showValueBox(com.simibubi.create.foundation.utility.Pair.of("filter" + behaviour.netId(), be.getBlockPos()), box.transform(slot))
                .lineWidth(1 / 64f)
                .withFaceTexture(hit ? com.simibubi.create.AllSpecialTextures.THIN_CHECKERED : null)
                .highlightFace(result.getDirection());
            if (!hit)
                continue;
            java.util.List<net.minecraft.network.chat.MutableComponent> tip = new java.util.ArrayList<>();
            tip.add(label.copy());
            tip.add(behaviour.getTip());
            if (behaviour.isCountVisible())
                tip.add(behaviour.getAmountTip());
            com.simibubi.create.CreateClient.VALUE_SETTINGS_HANDLER.showHoverTip(tip);
        }
    }

	public static void renderBulb(FactoryPanelBehaviour behaviour, float partialTicks, PoseStack ms,
		MultiBufferSource buffer, int light, int overlay) {
		BlockState blockState = behaviour.blockEntity.getBlockState();

		float xRot = FactoryPanelBlock.getXRot(blockState) + Mth.PI / 2;
		float yRot = FactoryPanelBlock.getYRot(blockState);
		float glow = behaviour.bulb.getValue(partialTicks);

		boolean missingAddress = behaviour.isMissingAddress();
		PartialModel partial = behaviour.redstonePowered || missingAddress ? AllPartialModels.FACTORY_PANEL_RED_LIGHT
			: AllPartialModels.FACTORY_PANEL_LIGHT;

		CachedBufferer.partial(partial, blockState)
			.rotateCentered(Direction.UP, yRot)
			.rotateCentered(Direction.EAST, xRot)
			.rotateCentered(Direction.UP, Mth.PI)
			.translate(behaviour.slot.xOffset * .5, 0, behaviour.slot.yOffset * .5)
			.light(glow > 0.125f ? LightTexture.FULL_BRIGHT : light)
			.overlay(overlay)
			.renderInto(ms, buffer.getBuffer(RenderType.translucent()));

		if (glow < .125f)
			return;

		glow = (float) (1 - (2 * Math.pow(glow - .75f, 2)));
		glow = Mth.clamp(glow, -1, 1);
		int color = (int) (200 * glow);

		CachedBufferer.partial(partial, blockState)
			.rotateCentered(Direction.UP, yRot)
			.rotateCentered(Direction.EAST, xRot)
			.rotateCentered(Direction.UP, Mth.PI)
			.translate(behaviour.slot.xOffset * .5, 0, behaviour.slot.yOffset * .5)
			.light(LightTexture.FULL_BRIGHT)
			.color(color, color, color, 255)
			.overlay(overlay)
			.renderInto(ms, buffer.getBuffer(RenderTypes.getAdditive()));
	}

	public static void renderPath(FactoryPanelBehaviour behaviour, FactoryPanelConnection connection,
		float partialTicks, PoseStack ms, MultiBufferSource buffer, int light, int overlay) {
		BlockState blockState = behaviour.blockEntity.getBlockState();
		List<Direction> path = connection.getPath(behaviour.getWorld(), blockState, behaviour.getPanelPosition());

		float xRot = FactoryPanelBlock.getXRot(blockState) + Mth.PI / 2;
		float yRot = FactoryPanelBlock.getYRot(blockState);
		float glow = behaviour.bulb.getValue(partialTicks);

		FactoryPanelSupportBehaviour sbe = FactoryPanelBehaviour.linkAt(behaviour.getWorld(), connection);
		boolean displayLinkMode = sbe != null && sbe.blockEntity instanceof DisplayLinkBlockEntity;
		boolean redstoneLinkMode = sbe != null && sbe.blockEntity instanceof RedstoneLinkBlockEntity;
		boolean pathReversed = sbe != null && !sbe.isOutput();

		int color = 0;
		float yOffset = 0;
		boolean success = connection.success;
		boolean dots = false;

		if (displayLinkMode) {
			// Display status
			color = 0x3C9852;
			dots = true;

		} else if (redstoneLinkMode) {
			// Link status
			color = pathReversed ? (behaviour.count == 0 ? 0x888898 : behaviour.satisfied ? 0xEF0000 : 0x580101)
				: (behaviour.redstonePowered ? 0xEF0000 : 0x580101);
			yOffset = 0.5f;

		} else {
			// Regular ingredient status
			color = behaviour.getIngredientStatusColor();

			yOffset = 1;
			yOffset += behaviour.promisedSatisfied ? 1 : behaviour.satisfied ? 0 : 2;

			if (!behaviour.redstonePowered && !behaviour.waitingForNetwork && glow > 0 && !behaviour.satisfied) {
				float p = (1 - (1 - glow) * (1 - glow));
				color = Color.mixColors(color, success ? 0xEAF2EC : 0xE5654B, p);
				if (!behaviour.satisfied && !behaviour.promisedSatisfied)
					yOffset += (success ? 1 : 2) * p;
			}
		}

		float currentX = 0;
		float currentZ = 0;

		for (int i = 0; i < path.size(); i++) {
			Direction direction = path.get(i);

			if (!pathReversed) {
				currentX += direction.getStepX() * .5;
				currentZ += direction.getStepZ() * .5;
			}

			boolean isArrowSegment = pathReversed ? i == path.size() - 1 : i == 0;
			PartialModel partial = (dots ? AllPartialModels.FACTORY_PANEL_DOTTED
				: isArrowSegment ? AllPartialModels.FACTORY_PANEL_ARROWS : AllPartialModels.FACTORY_PANEL_LINES)
					.get(pathReversed ? direction : direction.getOpposite());
			SuperByteBuffer connectionSprite = CachedBufferer.partial(partial, blockState)
				.rotateCentered(Direction.UP, yRot)
				.rotateCentered(Direction.EAST, xRot)
				.rotateCentered(Direction.UP, Mth.PI)
				.translate(behaviour.slot.xOffset * .5 + .25, 0, behaviour.slot.yOffset * .5 + .25)
				.translate(currentX, (yOffset + (direction.get2DDataValue() % 2) * 0.125f) / 512f, currentZ);

			if (!displayLinkMode && !redstoneLinkMode && !behaviour.isMissingAddress() && !behaviour.waitingForNetwork
				&& !behaviour.satisfied && !behaviour.redstonePowered)
				connectionSprite.shiftUV(AllSpriteShifts.FACTORY_PANEL_CONNECTIONS);

			connectionSprite.color(color)
				.light(light)
				.overlay(overlay)
				.renderInto(ms, buffer.getBuffer(RenderType.cutoutMipped()));

			if (pathReversed) {
				currentX += direction.getStepX() * .5;
				currentZ += direction.getStepZ() * .5;
			}
		}
	}

}
