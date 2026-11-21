package nativeport.check;

import java.lang.reflect.Method;
import java.util.List;
import com.simibubi.create.AllBlocks;
import com.simibubi.create.content.contraptions.actors.harvester.HarvesterMovementBehaviour;
import com.simibubi.create.content.kinetics.deployer.DeployerFakePlayer;
import com.simibubi.create.content.kinetics.deployer.DeployerHandler;
import com.simibubi.create.content.logistics.box.PackageItem;
import com.simibubi.create.content.redstone.displayLink.AllDisplayBehaviours;
import com.simibubi.create.content.redstone.displayLink.DisplayLinkContext;
import com.simibubi.create.content.redstone.displayLink.source.PackageAddressDisplaySource;
import com.simibubi.create.content.redstone.displayLink.target.DisplayTargetStats;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.CropBlock;
import net.minecraft.world.level.block.LeverBlock;
import net.minecraft.world.level.block.BeehiveBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;

/** TEST ONLY: executed in an isolated Fabric server, never packaged in the mod. */
public final class OfficialGapRuntimeTest implements ModInitializer {
    private Block throwingBlock;
    private StatefulCrop crop;
    static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }
    public void onInitialize() {
        throwingBlock = net.minecraft.core.Registry.register(net.minecraft.core.registries.BuiltInRegistries.BLOCK,
            ResourceLocation.fromNamespaceAndPath("official_gap_test", "throwing"), new Block(BlockBehaviour.Properties.of()) {
                @Override public InteractionResult useWithoutItem(BlockState state, Level level, BlockPos at,
                        net.minecraft.world.entity.player.Player actor, BlockHitResult ray) {
                    throw new IllegalStateException("expected test exception");
                }
            });
        crop = net.minecraft.core.Registry.register(net.minecraft.core.registries.BuiltInRegistries.BLOCK,
            ResourceLocation.fromNamespaceAndPath("official_gap_test", "stateful_crop"), new StatefulCrop());
        ServerLifecycleEvents.SERVER_STARTED.register(server -> {
            try {
                var world = server.overworld();
                var pos = new BlockPos(0, 100, 0);
                world.getChunkAt(pos);
                world.setBlockAndUpdate(pos.below(), Blocks.STONE.defaultBlockState());
                world.setBlockAndUpdate(pos, Blocks.LEVER.defaultBlockState());
                var player = new DeployerFakePlayer(world, null);
                var hit = new BlockHitResult(Vec3.atCenterOf(pos), Direction.UP, pos, false);
                for (boolean expected : new boolean[]{true, false}) {
                    DeployerHandler.safeOnUse(world.getBlockState(pos), world, pos, player, InteractionHand.MAIN_HAND, hit);
                    check(world.getBlockState(pos).getValue(LeverBlock.POWERED) == expected, "lever failed to toggle " + expected);
                    check(DeployerHandler.CAPTURED_BLOCK_DROPS_VIEW.isEmpty(), "capture map leaked after lever");
                }
                world.setBlockAndUpdate(pos, Blocks.BEEHIVE.defaultBlockState().setValue(BeehiveBlock.HONEY_LEVEL, 5));
                player.setItemInHand(InteractionHand.MAIN_HAND, new ItemStack(Items.SHEARS));
                DeployerHandler.safeOnUse(world.getBlockState(pos), world, pos, player, InteractionHand.MAIN_HAND, hit);
                int honey = 0;
                for (var stack : player.getInventory().items) if (stack.is(Items.HONEYCOMB)) honey += stack.getCount();
                check(honey == 3, "expected three captured honeycomb, got " + honey);
                check(world.getBlockState(pos).getValue(BeehiveBlock.HONEY_LEVEL) == 0, "hive did not reset");
                check(DeployerHandler.CAPTURED_BLOCK_DROPS_VIEW.isEmpty(), "capture map leaked after hive");
                player.setItemInHand(InteractionHand.MAIN_HAND, ItemStack.EMPTY);
                try {
                    DeployerHandler.safeOnUse(throwingBlock.defaultBlockState(), world, pos, player, InteractionHand.MAIN_HAND, hit);
                    throw new AssertionError("expected exception missing");
                } catch (IllegalStateException expected) {
                    check(expected.getMessage().equals("expected test exception"), "unexpected exception");
                }
                check(DeployerHandler.CAPTURED_BLOCK_DROPS_VIEW.isEmpty(), "capture map leaked after exception");
                System.out.println("OFFICIAL_GAP_TEST PASS deployer: lever on/off, hive drop capture, exception cleanup");

                var harvester = new HarvesterMovementBehaviour();
                check(harvester.isValidCrop(world, pos, Blocks.WHEAT.defaultBlockState().setValue(CropBlock.AGE, 7)), "ripe wheat rejected");
                check(!harvester.isValidCrop(world, pos, Blocks.WHEAT.defaultBlockState()), "immature wheat accepted");
                var ripe = crop.defaultBlockState().setValue(CropBlock.AGE, 7).setValue(StatefulCrop.MARKED, true);
                Method cut = HarvesterMovementBehaviour.class.getDeclaredMethod("cutCrop", Level.class, BlockPos.class, BlockState.class);
                cut.setAccessible(true);
                var replanted = (BlockState) cut.invoke(harvester, world, pos, ripe);
                check(replanted.getValue(CropBlock.AGE) == 0 && replanted.getValue(StatefulCrop.MARKED), "replant lost crop state");
                check(com.simibubi.create.AllTags.AllBlockTags.SUGAR_CANE_VARIANTS.matches(Blocks.SUGAR_CANE), "native sugar cane tag not loaded");
                System.out.println("OFFICIAL_GAP_TEST PASS harvester: maturity, state-preserving replant, sugar-cane tag");

                var observerPos = pos.offset(4, 0, 0);
                world.setBlockAndUpdate(observerPos, AllBlocks.SMART_OBSERVER.getDefaultState());
                var observer = world.getBlockEntity(observerPos);
                var context = new DisplayLinkContext(world, null) {
                    @Override public BlockEntity getSourceBlockEntity() { return observer; }
                    @Override public BlockPos getSourcePos() { return observerPos; }
                    @Override public CompoundTag sourceConfig() { return new CompoundTag(); }
                };
                check(AllDisplayBehaviours.GATHERER_BEHAVIOURS.get(ResourceLocation.fromNamespaceAndPath("create", "read_package_address")) instanceof PackageAddressDisplaySource,
                    "display source registration missing");
                var source = new PackageAddressDisplaySource();
                check(source.provideText(context, new DisplayTargetStats(1, 100, null)).get(0).getString().isEmpty(), "empty observer should have no address");
                var targetPos = observerPos.relative(com.simibubi.create.content.redstone.smartObserver.SmartObserverBlock.getTargetDirection(world.getBlockState(observerPos)));
                world.setBlockAndUpdate(targetPos, Blocks.CHEST.defaultBlockState());
                var chest = (net.minecraft.world.level.block.entity.ChestBlockEntity)world.getBlockEntity(targetPos);
                var box = PackageItem.containing(List.of(new ItemStack(Items.IRON_INGOT, 32)));
                PackageItem.addAddress(box, "Warehouse A");
                chest.setItem(0, box);
                var smart = (com.simibubi.create.content.redstone.smartObserver.SmartObserverBlockEntity)observer;
                var inventory = smart.getBehaviour(com.simibubi.create.foundation.blockEntity.behaviour.inventory.InvManipulationBehaviour.TYPE);
                var filter = smart.getBehaviour(com.simibubi.create.foundation.blockEntity.behaviour.filtering.FilteringBehaviour.TYPE);
                inventory.findNewCapability();
                var stats = new DisplayTargetStats(1, 100, null);
                check(source.provideText(context, stats).get(0).getString().equals("Warehouse A"), "inventory package address not read");
                check(chest.getItem(0).getCount() == 1 && PackageItem.getAddress(chest.getItem(0)).equals("Warehouse A"), "display consumed or changed package");
                filter.setFilter(new ItemStack(Items.DIAMOND));
                check(source.provideText(context, stats).get(0).getString().isEmpty(), "display ignored observer filter");
                filter.setFilter(ItemStack.EMPTY);
                var chainBox = chest.getItem(0).copy();
                world.setBlockAndUpdate(targetPos, AllBlocks.CHAIN_CONVEYOR.getDefaultState());
                var chain = (com.simibubi.create.content.kinetics.chainConveyor.ChainConveyorBlockEntity)world.getBlockEntity(targetPos);
                chain.getLoopingPackages().add(new com.simibubi.create.content.kinetics.chainConveyor.ChainConveyorPackage(0, chainBox));
                inventory.findNewCapability();
                check(source.provideText(context, stats).get(0).getString().equals("Warehouse A"), "chain package address not read");
                check(chain.getLoopingPackages().size() == 1, "display consumed chain package");
                System.out.println("OFFICIAL_GAP_TEST PASS display: registration, inventory and chain addresses, filtering, no consumption");
                System.out.println("OFFICIAL_GAP_TEST ALL PASS");
            } catch (Throwable failure) {
                System.out.println("OFFICIAL_GAP_TEST FAILED");
                failure.printStackTrace();
            } finally { server.halt(false); }
        });
    }
    static final class StatefulCrop extends CropBlock {
        static final BooleanProperty MARKED = BooleanProperty.create("marked");
        StatefulCrop() {
            super(BlockBehaviour.Properties.of());
            registerDefaultState(stateDefinition.any().setValue(AGE, 0).setValue(MARKED, false));
        }
        @Override protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
            super.createBlockStateDefinition(builder);
            builder.add(MARKED);
        }
    }
}
