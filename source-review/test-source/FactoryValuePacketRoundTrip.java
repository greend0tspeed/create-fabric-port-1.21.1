import com.simibubi.create.foundation.blockEntity.behaviour.ValueSettingsPacket;
import io.netty.buffer.Unpooled;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.RegistryAccess;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.world.InteractionHand;

public class FactoryValuePacketRoundTrip {
    public static void main(String[] args) throws Exception {
        var index = ValueSettingsPacket.class.getDeclaredField("behaviourIndex");
        var value = ValueSettingsPacket.class.getDeclaredField("value");
        var hand = ValueSettingsPacket.class.getDeclaredField("interactHand");
        index.setAccessible(true); value.setAccessible(true); hand.setAccessible(true);
        for (int id : new int[]{0, 2, 3, 4, 5}) {
            for (boolean shortClick : new boolean[]{false, true}) {
                var buffer = new RegistryFriendlyByteBuf(Unpooled.buffer(), RegistryAccess.EMPTY);
                try {
                    var original = new ValueSettingsPacket(new BlockPos(-12, 70, 33), 1, 91,
                        shortClick ? InteractionHand.MAIN_HAND : null, Direction.NORTH, true, id);
                    original.write(buffer);
                    buffer.writeInt(0x13572468);
                    var decoded = new ValueSettingsPacket(buffer);
                    if (index.getInt(decoded) != id || value.getInt(decoded) != 91
                        || (hand.get(decoded) != null) != shortClick || buffer.readInt() != 0x13572468
                        || buffer.isReadable()) throw new AssertionError("Packet mismatch: " + id);
                } finally { buffer.release(); }
            }
        }
        var resetField = com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConfigurationPacket.class.getDeclaredField("reset");
        var slotField = com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConfigurationPacket.class.getDeclaredField("slot");
        resetField.setAccessible(true); slotField.setAccessible(true);
        for (var slot : com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBlock.PanelSlot.values()) {
            var buffer = new RegistryFriendlyByteBuf(Unpooled.buffer(), RegistryAccess.EMPTY);
            try {
                var pos = new com.simibubi.create.content.logistics.factoryBoard.FactoryPanelPosition(new BlockPos(-12, 70, 33), slot);
                var original = new com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConfigurationPacket(
                    pos, "shop", java.util.Map.of(), java.util.List.of(), 1, -1, null, false, true, false);
                original.write(buffer);
                buffer.writeInt(0x13572468);
                var decoded = new com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConfigurationPacket(buffer);
                if (!resetField.getBoolean(decoded) || slotField.get(decoded) != slot
                    || buffer.readInt() != 0x13572468 || buffer.isReadable()) throw new AssertionError("Reset packet mismatch: " + slot);
            } finally { buffer.release(); }
        }
        System.out.println("PASS: default and all four Factory Panel IDs round-trip with short clicks, slider values, reset flags, and intact packet framing.");
    }
}
