package com.simibubi.create.content.logistics.itemHatch;

import com.mojang.blaze3d.vertex.PoseStack;
import com.jozufozu.flywheel.util.transform.TransformStack;
import com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform;
import com.simibubi.create.foundation.utility.AngleHelper;
import com.simibubi.create.foundation.utility.VecHelper;

import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;

public class HatchFilterSlot extends ValueBoxTransform {
	@Override
	public Vec3 getLocalOffset(BlockState state) {
		return VecHelper.rotateCentered(VecHelper.voxelSpace(8, 5.15, 9.5), angle(state), Direction.Axis.Y);
	}

	@Override
	public float getScale() {
		return super.getScale() * 0.965f;
	}

	public boolean testHit(BlockState state, Vec3 localHit) {
		return localHit.distanceTo(getLocalOffset(state).subtract(0, 0.125, 0)) < scale / 2;
	}

	@Override
	public void rotate(BlockState state, PoseStack ms) {
		TransformStack.cast(ms).rotateY(angle(state)).rotateX(-45);
	}

	private float angle(BlockState state) {
		return AngleHelper.horizontalAngle(state.getOptionalValue(ItemHatchBlock.FACING).orElse(Direction.NORTH));
	}
}
