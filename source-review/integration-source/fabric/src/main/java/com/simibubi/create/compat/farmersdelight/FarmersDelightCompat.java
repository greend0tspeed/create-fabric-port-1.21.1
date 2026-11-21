package com.simibubi.create.compat.farmersdelight;

import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;

import net.minecraft.world.level.block.state.BlockState;

import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;

public class FarmersDelightCompat {
	public static boolean shouldHarvestMushroom(Level world, BlockPos pos, BlockState state) {
		return !world.getBlockState(pos.below()).is(BuiltInRegistries.BLOCK.get(ResourceLocation.fromNamespaceAndPath("farmersdelight", "rich_soil")));
	}
}
