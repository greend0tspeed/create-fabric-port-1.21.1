import com.simibubi.create.content.schematics.cannon.*;
import net.minecraft.SharedConstants;
import net.minecraft.server.Bootstrap;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;

public class CannonFuelTransferTest {
    static class FuelInventory extends SchematicannonInventory {
        FuelInventory() { super(null); }
        @Override protected void onContentsChanged(int slot) {}
        @Override public boolean isItemValid(int slot, ItemVariant variant, int count) {
            return slot == 4 && variant.isOf(Items.GUNPOWDER);
        }
    }
    public static void main(String[] args) throws Exception {
        try { run(); } catch (Throwable t) {
            try (var writer = new java.io.PrintWriter("work/native-create6-port/integration-wip/tests/cannon-fuel-test-error.log")) { t.printStackTrace(writer); }
            throw t;
        }
    }
    private static void run() throws Exception {
        SharedConstants.tryDetectVersion(); Bootstrap.bootStrap();
        var unsafeField = sun.misc.Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        var unsafe = (sun.misc.Unsafe) unsafeField.get(null);
        for (int initial : new int[]{0, 1, 32, 63, 64}) {
            var be = (SchematicannonBlockEntity) unsafe.allocateInstance(SchematicannonBlockEntity.class);
            be.inventory = new FuelInventory();
            if (initial != 0) be.inventory.setStackInSlot(4, new ItemStack(Items.GUNPOWDER, initial));
            var inventory = new Inventory(null);
            inventory.setItem(0, new ItemStack(Items.GUNPOWDER, 64));
            var menu = new SchematicannonMenu(null, 1, inventory, be);
            menu.quickMoveStack(null, 5);
            int fuel = be.inventory.getStackInSlot(4).getCount();
            int remaining = inventory.getItem(0).getCount();
            if (fuel != 64 || remaining != initial)
                throw new AssertionError("Fuel transfer mismatch: initial=" + initial + " fuel=" + fuel + " remaining=" + remaining);
        }
        System.out.println("PASS: actual SchematicannonMenu shift-transfers preserve all items and cap gunpowder at 64 for empty, partial, and full fuel slots.");
    }
}
