import java.lang.reflect.Field;
import java.util.EnumMap;
import sun.misc.Unsafe;
import com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBlock;
import com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBlockEntity;
import com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBehaviour;
public class FactoryGaugeRenderStateTest {
 public static void main(String[] args) throws Exception {
  Field uf=Unsafe.class.getDeclaredField("theUnsafe"); uf.setAccessible(true); Unsafe u=(Unsafe)uf.get(null);
  var be=(FactoryPanelBlockEntity)u.allocateInstance(FactoryPanelBlockEntity.class);
  var panels=new EnumMap<FactoryPanelBlock.PanelSlot,FactoryPanelBehaviour>(FactoryPanelBlock.PanelSlot.class);
  Field pf=FactoryPanelBlockEntity.class.getDeclaredField("panels");pf.setAccessible(true);pf.set(be,panels);
  Field af=FactoryPanelBehaviour.class.getDeclaredField("active");af.setAccessible(true);
  for(var slot:FactoryPanelBlock.PanelSlot.values()) {
   var panel=(FactoryPanelBehaviour)u.allocateInstance(FactoryPanelBehaviour.class);
   af.setBoolean(panel,true);panels.put(slot,panel);
  }
  int checks=0;
  for(boolean restocker:new boolean[]{false,true}) {
   be.restocker=restocker;
   for(int count:new int[]{0,1,64}) {
    for(var panel:panels.values())panel.count=count;
    var data=(FactoryPanelBlockEntity.RenderData)be.getRenderData();
    if(data.type()!=(restocker?FactoryPanelBlock.PanelType.PACKAGER:FactoryPanelBlock.PanelType.NETWORK))throw new AssertionError("type");
    for(var slot:FactoryPanelBlock.PanelSlot.values()) {
     var expected=count==0?FactoryPanelBlock.PanelState.PASSIVE:FactoryPanelBlock.PanelState.ACTIVE;
     if(data.states().get(slot)!=expected)throw new AssertionError(slot+" count="+count);
     checks++;
    }
   }
  }
  for(var panel:panels.values())af.setBoolean(panel,false);
  if(!((FactoryPanelBlockEntity.RenderData)be.getRenderData()).states().isEmpty())throw new AssertionError("inactive panels drawn");
  System.out.println("PASS: "+checks+" active-panel model states plus inactive exclusion; zero targets passive, positive targets active, both gauge modes. This isolates render-state mapping, not game initialization or persistence.");
 }
}