package nativeport.check;

import java.util.List;
import com.simibubi.create.AllDataComponents;
import com.simibubi.create.AllTags.AllBlockTags;
import com.simibubi.create.AllTags.AllItemTags;
import com.simibubi.create.content.logistics.BigItemStack;
import com.simibubi.create.content.logistics.redstoneRequester.AutoRequestData;
import com.simibubi.create.content.logistics.stockTicker.PackageOrder;
import com.simibubi.create.content.logistics.stockTicker.PackageOrderWithCrafts;
import io.netty.buffer.Unpooled;
import net.fabricmc.api.ModInitializer;
import net.minecraft.core.RegistryAccess;
import net.minecraft.core.component.DataComponents;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.NbtOps;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;

/** Isolated test harness, never included in a playable artifact. */
public final class NativePacketCodecPreflight implements ModInitializer {
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    @Override public void onInitialize() {
        try {
            var registries = RegistryAccess.fromRegistryOfRegistries(BuiltInRegistries.REGISTRY);
            var named = new ItemStack(Items.DIAMOND_PICKAXE);
            named.setDamageValue(17);
            named.set(DataComponents.CUSTOM_NAME, Component.literal("Logistics component test"));
            var stacks = List.of(ItemStack.EMPTY, new ItemStack(Items.IRON_INGOT, 32), named);
            check(AllDataComponents.AUTO_REQUEST_DATA != null, "auto request component was not registered");
            check(AllBlockTags.POSTBOXES.tag.location().toString().equals("create:postboxes"), "postbox block tag changed");
            check(AllBlockTags.TABLE_CLOTHS.tag.location().toString().equals("create:table_cloths"), "table cloth block tag changed");
            check(AllItemTags.POSTBOXES.tag.location().toString().equals("create:postboxes"), "postbox item tag changed");
            check(AllItemTags.TABLE_CLOTHS.tag.location().toString().equals("create:table_cloths"), "table cloth item tag changed");
            check(AllItemTags.DYED_TABLE_CLOTHS.tag.location().toString().equals("create:dyed_table_cloths"), "dyed table cloth tag changed");
            var componentStack = new ItemStack(Items.STONE);
            var component = new AutoRequestData(
                PackageOrderWithCrafts.simple(List.of(new BigItemStack(named, 4096))),
                "frog destination", new net.minecraft.core.BlockPos(-12, 70, 33), "minecraft:overworld", false);
            componentStack.set(AllDataComponents.AUTO_REQUEST_DATA, component);
            var itemTag = ItemStack.CODEC.encodeStart(registries.createSerializationContext(NbtOps.INSTANCE), componentStack).getOrThrow();
            var restoredStack = ItemStack.CODEC.parse(registries.createSerializationContext(NbtOps.INSTANCE), itemTag).getOrThrow();
            var restoredComponent = restoredStack.get(AllDataComponents.AUTO_REQUEST_DATA);
            check(restoredComponent != null, "auto request component was lost during item serialization");
            check(restoredComponent.encodedTargetAddress().equals("frog destination"), "request address changed");
            check(restoredComponent.targetOffset().equals(new net.minecraft.core.BlockPos(-12, 70, 33)), "request target changed");
            check(restoredComponent.encodedRequest().stacks().get(0).count == 4096, "component order count changed");
            var buffer = new RegistryFriendlyByteBuf(Unpooled.buffer(), registries);
            try {
                // Existing Fabric collection framing with the native 1.21 optional item codec.
                buffer.writeVarInt(stacks.size());
                stacks.forEach(stack -> ItemStack.OPTIONAL_STREAM_CODEC.encode(buffer, stack));
                buffer.writeInt(0x13572468);
                var decoded = ItemStack.OPTIONAL_LIST_STREAM_CODEC.decode(buffer);
                check(decoded.size() == 3 && decoded.get(0).isEmpty(), "empty recipe slot lost");
                for (int i = 0; i < stacks.size(); i++)
                    check(ItemStack.matches(stacks.get(i), decoded.get(i)), "item components/count changed: " + i);
                check(buffer.readInt() == 0x13572468 && !buffer.isReadable(), "item codec changed packet framing");

                buffer.clear();
                var order = new PackageOrder(List.of(new BigItemStack(named, 4096)));
                PackageOrder.STREAM_CODEC.encode(buffer, order);
                buffer.writeBoolean(true);
                var restored = PackageOrder.STREAM_CODEC.decode(buffer);
                check(restored.stacks().get(0).count == 4096, "large order count truncated");
                check(ItemStack.matches(named, restored.stacks().get(0).stack), "order components changed");
                check(buffer.readBoolean() && !buffer.isReadable(), "order codec changed trailing field");
                var ops = registries.createSerializationContext(NbtOps.INSTANCE);
                var tag = PackageOrder.CODEC.encodeStart(ops, order).getOrThrow();
                var persisted = PackageOrder.CODEC.parse(ops, tag).getOrThrow();
                check(persisted.stacks().get(0).count == 4096, "persisted order count changed");
                check(ItemStack.matches(named, persisted.stacks().get(0).stack), "persisted components changed");
                buffer.clear();
                PackageOrder.STREAM_CODEC.encode(buffer, PackageOrder.empty());
                check(PackageOrder.STREAM_CODEC.decode(buffer).isEmpty(), "empty order failed");
            } finally { buffer.release(); }
            System.out.println("NATIVE_PACKET_CODEC_PREFLIGHT_PASS: empty recipe slots, item components, framing, large order counts, NBT round trips, and registered auto-request item data. Machine networking not tested.");
            System.exit(0);
        } catch (Throwable failure) { failure.printStackTrace(); System.exit(1); }
    }
}
