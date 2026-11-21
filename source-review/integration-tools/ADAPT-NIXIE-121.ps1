$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$mp=Join-Path $root 'port-changes.json'
$m=Get-Content $mp -Raw|ConvertFrom-Json
$targets=@(
 [pscustomobject]@{rel='content/redstone/nixieTube/NixieTubeBlock.java';changes=@(
  [pscustomobject]@{from='import com.simibubi.create.foundation.utility.AdventureUtil;';to='import com.simibubi.create.foundation.utility.Iterate;'},
  [pscustomobject]@{from="import net.createmod.catnip.data.Iterate;`n";to=''},
  [pscustomobject]@{from="import net.minecraft.nbt.CompoundTag;`nimport net.minecraft.nbt.Tag;";to='import net.minecraft.core.component.DataComponents;'},
  [pscustomobject]@{from='import net.minecraft.world.InteractionResult;';to='import net.minecraft.world.ItemInteractionResult;'},
  [pscustomobject]@{from='import net.minecraft.world.level.LevelReader;';to='import net.minecraft.world.level.LevelReader;'},
  [pscustomobject]@{from="public InteractionResult use(BlockState state, Level world, BlockPos pos, Player player, InteractionHand hand,`n`t`tBlockHitResult ray) {`n`n`t`tif (player.isShiftKeyDown() || AdventureUtil.isAdventure(player))`n`t`t`treturn InteractionResult.PASS;`n`n`t`tItemStack heldItem = player.getItemInHand(hand);";to="protected ItemInteractionResult useItemOn(ItemStack heldItem, BlockState state, Level world, BlockPos pos, Player player, InteractionHand hand,`n`t`tBlockHitResult ray) {`n`n`t`tif (player.isShiftKeyDown())`n`t`t`treturn ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;"},
  [pscustomobject]@{from='return InteractionResult.PASS;';to='return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;'},
  [pscustomobject]@{from='return InteractionResult.SUCCESS;';to='return ItemInteractionResult.SUCCESS;'},
  [pscustomobject]@{from='heldItem.getItem() == Items.NAME_TAG && heldItem.hasCustomHoverName() || AllBlocks.CLIPBOARD.isIn(heldItem);';to='heldItem.getItem() == Items.NAME_TAG && heldItem.has(DataComponents.CUSTOM_NAME) || AllBlocks.CLIPBOARD.isIn(heldItem);'},
  [pscustomobject]@{from="`t`tCompoundTag tag = heldItem.getTagElement(`"display`");`n`t`tString tagElement = tag != null && tag.contains(`"Name`", Tag.TAG_STRING) ? tag.getString(`"Name`") : null;";to="`t`tComponent component = heldItem.getOrDefault(DataComponents.CUSTOM_NAME, Component.empty());"},
  [pscustomobject]@{from="`t`t`tfor (int i = 0; i < entries.size();) {`n`t`t`t`ttagElement = Component.Serializer.toJson(entries.get(i).text);`n`t`t`t`tbreak;`n`t`t`t}";to="`t`t`tif (!entries.isEmpty())`n`t`t`t`tcomponent = entries.getFirst().text;"},
  [pscustomobject]@{from="`t`tString tagUsed = tagElement;";to="`t`tString tagUsed = Component.Serializer.toJson(component, world.registryAccess());"},
  [pscustomobject]@{from='public ItemStack getCloneItemStack(BlockGetter p_185473_1_, BlockPos p_185473_2_, BlockState p_185473_3_)';to='public ItemStack getCloneItemStack(LevelReader pLevel, BlockPos pPos, BlockState pState)'},
  [pscustomobject]@{from='public boolean isPathfindable(BlockState state, BlockGetter reader, BlockPos pos, PathComputationType type)';to='protected boolean isPathfindable(BlockState state, PathComputationType type)'}
 );status='Original Nixie interaction and display logic adapted to Minecraft 1.21.1 item components and block signatures.'},
 [pscustomobject]@{rel='content/redstone/nixieTube/NixieTubeBlockEntity.java';changes=@(
  [pscustomobject]@{from='import net.createmod.catnip.data.Couple;';to='import com.simibubi.create.foundation.utility.Couple;'},
  [pscustomobject]@{from='private static final String EMPTY_COMPONENT_JSON = Component.Serializer.toJson(Component.literal(""));';to='private static final String EMPTY_COMPONENT_JSON = "\\\"\\\""; // Same as Component.literal("")'}
 );status='Original Nixie block entity adapted to the Fabric utility package and registry-independent empty component JSON.'},
 [pscustomobject]@{rel='content/kinetics/chainConveyor/ChainConveyorShape.java';changes=@(
  [pscustomobject]@{from='.rotateXDegrees(';to='.rotateX('}
 );status='Original chain hitbox geometry fully adapted to the Fabric transform API.'}
)
foreach($t in $targets){
 $p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$($t.rel)"
 $x=[IO.File]::ReadAllText($p)
 foreach($c in $t.changes){
  if($c.from -eq $c.to){continue}
  if(-not $x.Contains($c.from)){throw "Nixie adaptation anchor missing in $($t.rel): $($c.from)"}
  $x=$x.Replace($c.from,$c.to)
 }
 [IO.File]::WriteAllText($p,$x,[Text.UTF8Encoding]::new($false))
 $e=$m.files|Where-Object path -eq $t.rel
 $e.changes=@($e.changes)+@($t.changes|Where-Object {$_.from -ne $_.to})
 $e.status=$t.status
}
$m|ConvertTo-Json -Depth 20|Set-Content $mp -Encoding utf8
Write-Output 'Adapted native Nixie logic and the remaining chain shape transform.'
