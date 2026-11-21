$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$mp=Join-Path $root 'port-changes.json';$m=Get-Content $mp -Raw|ConvertFrom-Json
$targets=@(
 [pscustomobject]@{rel='content/redstone/nixieTube/NixieTubeBlock.java';changes=@([pscustomobject]@{from='import net.minecraft.world.level.LevelAccessor;';to="import net.minecraft.world.level.LevelAccessor;`nimport net.minecraft.world.level.LevelReader;"});status='Original Nixie logic adapted to Minecraft 1.21.1 item components and block signatures.'},
 [pscustomobject]@{rel='content/logistics/factoryBoard/FactoryPanelBlockItem.java';changes=@(
  [pscustomobject]@{from='import com.simibubi.create.foundation.utility.Lang;';to="import com.simibubi.create.foundation.block.IBE;`nimport com.simibubi.create.foundation.utility.Lang;"},
  [pscustomobject]@{from='import net.minecraft.core.BlockPos;';to="import net.minecraft.core.BlockPos;`nimport net.minecraft.core.component.DataComponents;"},
  [pscustomobject]@{from='import net.minecraft.world.item.ItemStack;';to="import net.minecraft.world.item.BlockItem;`nimport net.minecraft.world.item.ItemStack;`nimport net.minecraft.world.item.component.CustomData;"},
  [pscustomobject]@{from='import net.minecraft.world.level.block.Block;';to="import net.minecraft.world.level.block.Block;`nimport net.minecraft.world.level.block.entity.BlockEntity;"},
  [pscustomobject]@{from='CompoundTag bet = stack.getTagElement(BLOCK_ENTITY_TAG);';to='CompoundTag bet = stack.getOrDefault(DataComponents.BLOCK_ENTITY_DATA, CustomData.EMPTY).copyTag();'},
  [pscustomobject]@{from='stack.getTag().put(BLOCK_ENTITY_TAG, bet);';to="BlockEntity.addEntityType(bet, ((IBE<?>) ((BlockItem) stack.getItem()).getBlock()).getBlockEntityType());`n`t`t`tstack.set(DataComponents.BLOCK_ENTITY_DATA, CustomData.of(bet));"}
 );status='Original Factory Panel ctrl-copy repair adapted to Minecraft 1.21.1 block-entity data components.'},
 [pscustomobject]@{rel='content/logistics/factoryBoard/FactoryPanelConnectionHandler.java';changes=@(
  [pscustomobject]@{from='import com.simibubi.create.AllSoundEvents;';to="import com.simibubi.create.AllSoundEvents;`nimport com.simibubi.create.CreateClient;"},
  [pscustomobject]@{from='import com.simibubi.create.foundation.utility.Lang;';to="import com.simibubi.create.foundation.utility.CreateLang;`nimport com.simibubi.create.foundation.utility.Lang;"},
  [pscustomobject]@{from='import com.simibubi.create.foundation.outliner.Outliner;';to=''},
  [pscustomobject]@{from='Outliner.getInstance()';to='CreateClient.OUTLINER'}
 );status='Original Factory Panel connection interaction retained through baseline client outliner and Create language helper.'},
 [pscustomobject]@{rel='content/logistics/packager/PackagerBlockEntity.java';changes=@(
  [pscustomobject]@{from='List<ItemStack> items = ItemHelper.getNonEmptyStacks(contents);';to="List<ItemStack> items = new ArrayList<>();`n`t`tfor (int slot = 0; slot < contents.getSlots(); slot++) {`n`t`t`tItemStack stack = contents.getStackInSlot(slot);`n`t`t`tif (!stack.isEmpty())`n`t`t`t`titems.add(stack);`n`t`t}"}
 );status='Original package unwrapping retained with the Fabric ItemStackHandler slot API.'}
)
foreach($t in $targets){$p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$($t.rel)";$x=[IO.File]::ReadAllText($p);foreach($c in $t.changes){if($x.Contains($c.from)){$x=$x.Replace($c.from,$c.to)}elseif(-not$x.Contains($c.to)){throw "Component/client anchor missing in $($t.rel): $($c.from)"}};[IO.File]::WriteAllText($p,$x,[Text.UTF8Encoding]::new($false));$e=$m.files|Where-Object path -eq $t.rel;foreach($c in $t.changes){if(-not(@($e.changes)|Where-Object {$_.from -eq $c.from -and $_.to -eq $c.to})){$e.changes=@($e.changes)+$c}};if($e.PSObject.Properties.Name -contains 'status'){$e.status=$t.status}else{$e|Add-Member -NotePropertyName status -NotePropertyValue $t.status}}
$m|ConvertTo-Json -Depth 20|Set-Content $mp -Encoding utf8;Write-Output 'Adapted native components, client helpers, and package slot access.'
