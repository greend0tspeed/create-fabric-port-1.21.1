package com.simibubi.create.content.logistics.itemHatch;

import com.mojang.serialization.MapCodec;
import com.simibubi.create.AllBlockEntityTypes;
import com.simibubi.create.AllShapes;
import com.simibubi.create.AllSoundEvents;
import com.simibubi.create.AllTags.AllItemTags;
import com.simibubi.create.content.equipment.wrench.IWrenchable;
import com.simibubi.create.content.logistics.box.PackageItem;
import com.simibubi.create.foundation.block.IBE;
import com.simibubi.create.foundation.block.ProperWaterloggedBlock;
import com.simibubi.create.foundation.blockEntity.behaviour.BlockEntityBehaviour;
import com.simibubi.create.foundation.blockEntity.behaviour.filtering.FilteringBehaviour;
import com.simibubi.create.foundation.utility.Lang;

import io.github.fabricators_of_create.porting_lib_ufo.transfer.TransferUtil;
import net.fabricmc.fabric.api.entity.FakePlayer;
import net.fabricmc.fabric.api.transfer.v1.item.ItemStorage;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;
import net.fabricmc.fabric.api.transfer.v1.storage.Storage;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.ItemInteractionResult;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.HorizontalDirectionalBlock;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition.Builder;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.level.pathfinder.PathComputationType;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.VoxelShape;

public class ItemHatchBlock extends HorizontalDirectionalBlock
	implements IBE<ItemHatchBlockEntity>, IWrenchable, ProperWaterloggedBlock {
	public static final MapCodec<ItemHatchBlock> CODEC = simpleCodec(ItemHatchBlock::new);
	public static final BooleanProperty OPEN = BooleanProperty.create("open");

	public ItemHatchBlock(Properties properties) {
		super(properties);
		registerDefaultState(defaultBlockState().setValue(OPEN, false).setValue(WATERLOGGED, false));
	}

	@Override
	protected void createBlockStateDefinition(Builder<Block, BlockState> builder) {
		super.createBlockStateDefinition(builder.add(OPEN, FACING, WATERLOGGED));
	}

	@Override
	public BlockState getStateForPlacement(BlockPlaceContext context) {
		BlockState state = super.getStateForPlacement(context);
		if (state == null || context.getClickedFace().getAxis().isVertical())
			return null;
		return withWater(state.setValue(FACING, context.getClickedFace().getOpposite()).setValue(OPEN, false), context);
	}

	@Override
	public FluidState getFluidState(BlockState state) {
		return fluidState(state);
	}

	@Override
	public BlockState updateShape(BlockState state, Direction direction, BlockState neighbour, LevelAccessor level,
		BlockPos pos, BlockPos neighbourPos) {
		updateWater(level, state, pos);
		return state;
	}

	@Override
	protected ItemInteractionResult useItemOn(ItemStack stack, BlockState state, Level level, BlockPos pos,
		Player player, InteractionHand hand, BlockHitResult hit) {
		if (level.isClientSide() || player instanceof FakePlayer)
			return ItemInteractionResult.SUCCESS;

		Direction facing = state.getValue(FACING);
		BlockPos targetPos = pos.relative(facing);
		Storage<ItemVariant> storage = ItemStorage.SIDED.find(level, targetPos, facing.getOpposite());
		if (storage == null)
			return ItemInteractionResult.FAIL;

		FilteringBehaviour filter = BlockEntityBehaviour.get(level, pos, FilteringBehaviour.TYPE);
		if (filter == null)
			return ItemInteractionResult.FAIL;

		Inventory inventory = player.getInventory();
		boolean anyInserted = false;
		boolean depositItemInHand = !player.isShiftKeyDown();
		if (!depositItemInHand && AllItemTags.WRENCH.matches(stack))
			return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;

		for (int i = 0; i < inventory.items.size(); i++) {
			if (Inventory.isHotbarSlot(i) != depositItemInHand || depositItemInHand && i != inventory.selected)
				continue;
			ItemStack item = inventory.getItem(i);
			if (item.isEmpty() || !item.getItem().canFitInsideContainerItems() && !PackageItem.isPackage(item))
				continue;
			if (!filter.getFilter().isEmpty() && !filter.test(item))
				continue;
			long inserted = TransferUtil.insertItem(storage, item);
			if (inserted <= 0)
				continue;
			anyInserted = true;
			int remaining = TransferUtil.truncateLong(item.getCount() - inserted);
			inventory.setItem(i, remaining <= 0 ? ItemStack.EMPTY : item.copyWithCount(remaining));
		}

		if (!anyInserted)
			return ItemInteractionResult.SUCCESS;
		AllSoundEvents.ITEM_HATCH.playOnServer(level, pos);
		level.setBlockAndUpdate(pos, state.setValue(OPEN, true));
		level.scheduleTick(pos, this, 10);
		Lang.translate(depositItemInHand ? "item_hatch.deposit_item" : "item_hatch.deposit_inventory")
			.sendStatus(player);
		return ItemInteractionResult.SUCCESS;
	}

	@Override
	public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext context) {
		return AllShapes.ITEM_HATCH.get(state.getValue(FACING).getOpposite());
	}

	@Override
	public void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
		if (state.getValue(OPEN))
			level.setBlockAndUpdate(pos, state.setValue(OPEN, false));
	}

	@Override
	public void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean movedByPiston) {
		IBE.onRemove(state, level, pos, newState);
	}

	@Override public Class<ItemHatchBlockEntity> getBlockEntityClass() { return ItemHatchBlockEntity.class; }
	@Override public BlockEntityType<? extends ItemHatchBlockEntity> getBlockEntityType() { return AllBlockEntityTypes.ITEM_HATCH.get(); }
	@Override protected boolean isPathfindable(BlockState state, PathComputationType type) { return false; }
	@Override protected MapCodec<? extends HorizontalDirectionalBlock> codec() { return CODEC; }
}
