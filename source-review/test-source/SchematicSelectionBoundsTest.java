import com.simibubi.create.content.schematics.client.SchematicAndQuillHandler;
import net.minecraft.core.BlockPos;
import net.minecraft.world.phys.AABB;

public class SchematicSelectionBoundsTest {
    public static void main(String[] args) throws Exception {
        var handler = new SchematicAndQuillHandler();
        var selected = SchematicAndQuillHandler.class.getDeclaredField("selectedPos");
        var bounds = SchematicAndQuillHandler.class.getDeclaredMethod("getCurrentSelectionBox");
        selected.setAccessible(true); bounds.setAccessible(true);
        int tests = 0;
        for (var first : new BlockPos[]{BlockPos.ZERO, new BlockPos(12, 70, 33), new BlockPos(-21, -59, -20)}) {
            handler.firstPos = null; handler.secondPos = null; selected.set(handler, first);
            check((AABB) bounds.invoke(handler), first, first); tests++;
            handler.firstPos = first;
            check((AABB) bounds.invoke(handler), first, first); tests++;
            for (var second : new BlockPos[]{first, first.offset(2, 3, 4), first.offset(-4, -2, -3)}) {
                selected.set(handler, second); handler.secondPos = null;
                check((AABB) bounds.invoke(handler), first, second); tests++;
                handler.secondPos = second;
                check((AABB) bounds.invoke(handler), first, second); tests++;
            }
        }
        System.out.println("PASS: " + tests + " selection bounds checks, including first-click stability, expansion in either direction, and negative coordinates.");
    }
    private static void check(AABB box, BlockPos a, BlockPos b) {
        if (box.minX != Math.min(a.getX(), b.getX()) || box.minY != Math.min(a.getY(), b.getY())
            || box.minZ != Math.min(a.getZ(), b.getZ()) || box.maxX != Math.max(a.getX(), b.getX()) + 1
            || box.maxY != Math.max(a.getY(), b.getY()) + 1 || box.maxZ != Math.max(a.getZ(), b.getZ()) + 1)
            throw new AssertionError("Incorrect selection bounds: " + box + " for " + a + " / " + b);
    }
}
