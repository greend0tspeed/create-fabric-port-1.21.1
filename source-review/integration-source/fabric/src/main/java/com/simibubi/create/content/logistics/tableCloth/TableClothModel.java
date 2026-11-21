package com.simibubi.create.content.logistics.tableCloth;

import java.util.List;
import java.util.function.Supplier;

import com.jozufozu.flywheel.core.PartialModel;
import com.simibubi.create.AllPartialModels;
import com.simibubi.create.foundation.block.render.SpriteShiftEntry;
import com.simibubi.create.foundation.utility.Iterate;

import net.fabricmc.fabric.api.renderer.v1.model.FabricBakedModel;
import net.fabricmc.fabric.api.renderer.v1.model.ForwardingBakedModel;
import net.fabricmc.fabric.api.renderer.v1.model.SpriteFinder;
import net.fabricmc.fabric.api.renderer.v1.render.RenderContext;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.client.resources.model.BakedModel;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.util.RandomSource;
import net.minecraft.world.inventory.InventoryMenu;
import net.minecraft.world.level.BlockAndTintGetter;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockState;

/**
 * Fabric renderer adaptation of Create 6's TableClothModel. The original corner
 * selection and UV remapping are retained; only model-data collection is
 * translated to Fabric's quad-emission API.
 */
public class TableClothModel extends ForwardingBakedModel {

	private static final List<PartialModel> CORNERS = List.of(AllPartialModels.TABLE_CLOTH_SW,
		AllPartialModels.TABLE_CLOTH_NW, AllPartialModels.TABLE_CLOTH_NE, AllPartialModels.TABLE_CLOTH_SE);

	public TableClothModel(BakedModel originalModel) {
		wrapped = originalModel;
	}

	public static void reload() {
		// Fabric resolves the partial models while emitting, so there is no quad cache to clear.
	}

	@Override
	public boolean useAmbientOcclusion() {
		return false;
	}

	@Override
	public boolean isVanillaAdapter() {
		return false;
	}

	@Override
	public void emitBlockQuads(BlockAndTintGetter world, BlockState state, BlockPos pos,
		Supplier<RandomSource> randomSupplier, RenderContext context) {
		super.emitBlockQuads(world, state, pos, randomSupplier, context);
		if (!(state.getBlock() instanceof TableClothBlock))
			return;

		TextureAtlasSprite targetSprite = wrapped.getParticleIcon();
		SpriteFinder spriteFinder = SpriteFinder.get(Minecraft.getInstance()
			.getModelManager()
			.getAtlas(InventoryMenu.BLOCK_ATLAS));

		for (Direction side : Iterate.horizontalDirections) {
			Direction adjacentSide = side.getClockWise();
			if (!Block.shouldRenderFace(state, world, pos, adjacentSide, pos.relative(adjacentSide)))
				continue;

			context.pushTransform(quad -> {
				if (quad.cullFace() != side)
					return false;
				TextureAtlasSprite originalSprite = spriteFinder.find(quad, 0);
				for (int vertex = 0; vertex < 4; vertex++) {
					float u = targetSprite.getU(SpriteShiftEntry.getUnInterpolatedU(originalSprite,
						quad.spriteU(vertex, 0)));
					float v = targetSprite.getV(SpriteShiftEntry.getUnInterpolatedV(originalSprite,
						quad.spriteV(vertex, 0)));
					quad.sprite(vertex, 0, u, v);
				}
				return true;
			});
			((FabricBakedModel) CORNERS.get(side.get2DDataValue()).get())
				.emitBlockQuads(world, state, pos, randomSupplier, context);
			context.popTransform();
		}
	}
}