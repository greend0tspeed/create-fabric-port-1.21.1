package com.simibubi.create.content.logistics.tableCloth;

import java.util.List;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import com.simibubi.create.AllPartialModels;
import com.simibubi.create.content.logistics.depot.DepotRenderer;
import com.simibubi.create.foundation.blockEntity.renderer.SmartBlockEntityRenderer;

import com.jozufozu.flywheel.util.transform.TransformStack;
import com.simibubi.create.foundation.render.CachedBufferer;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider.Context;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.client.resources.model.BakedModel;
import net.minecraft.core.Direction;
import net.minecraft.util.Mth;
import net.minecraft.util.RandomSource;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.phys.Vec3;

public class TableClothRenderer extends SmartBlockEntityRenderer<TableClothBlockEntity> {

	public TableClothRenderer(Context context) {
		super(context);
	}

	@Override
	protected void renderSafe(TableClothBlockEntity blockEntity, float partialTicks, PoseStack ms,
		MultiBufferSource buffer, int light, int overlay) {
		super.renderSafe(blockEntity, partialTicks, ms, buffer, light, overlay);
		List<ItemStack> stacks = blockEntity.getItemsForRender();
		float rotationInRadians = Mth.DEG_TO_RAD * (180 - blockEntity.facing.toYRot());

		if (blockEntity.isShop()) {
			CachedBufferer
				.partial(blockEntity.sideOccluded ? AllPartialModels.TABLE_CLOTH_PRICE_TOP
					: AllPartialModels.TABLE_CLOTH_PRICE_SIDE, blockEntity.getBlockState())
				.rotateCentered(Direction.UP, rotationInRadians)
				.light(light)
				.overlay(overlay)
				.renderInto(ms, buffer.getBuffer(RenderType.cutout()));
		}

		ms.pushPose();
		TransformStack.cast(ms)
			.rotateCentered(Direction.UP, rotationInRadians);
		for (int i = 0; i < stacks.size(); i++) {
			ItemStack entry = stacks.get(i);
			ms.pushPose();
			ms.translate(0.5f, 3 / 16f, 0.5f);

			if (stacks.size() > 1) {
				ms.mulPose(Axis.YP.rotationDegrees(i * (360f / stacks.size()) + 45f));
				ms.translate(0, i % 2 == 0 ? -0.005 : 0, 5 / 16f);
				ms.mulPose(Axis.YP.rotationDegrees(-i * (360f / stacks.size()) - 45f));
			}

			BakedModel bakedModel = Minecraft.getInstance()
				.getItemRenderer()
				.getModel(entry, null, null, 0);
			boolean blockItem = bakedModel.isGui3d();
			if (!blockItem)
				TransformStack.cast(ms)
					.rotate(Direction.UP, -rotationInRadians + Mth.PI);

			DepotRenderer.renderItem(blockEntity.getLevel(), ms, buffer, light, OverlayTexture.NO_OVERLAY, entry, 0,
				RandomSource.create(blockEntity.getBlockPos().asLong()), Vec3.atCenterOf(blockEntity.getBlockPos()));
			ms.popPose();
		}

		ms.popPose();
	}

}
