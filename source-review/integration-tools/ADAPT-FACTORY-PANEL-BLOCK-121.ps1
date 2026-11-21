$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$path=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/factoryBoard/FactoryPanelBlock.java';$manifestPath=Join-Path $root 'port-changes.json';$text=[IO.File]::ReadAllText($path);$nl=if($text.Contains("`r`n")){"`r`n"}else{"`n"}
$changes=@(
 [pscustomobject]@{from='import com.mojang.serialization.Codec;';to="import com.mojang.serialization.Codec;${nl}import com.mojang.serialization.MapCodec;"},
 [pscustomobject]@{from='import net.minecraft.world.InteractionResult;';to="import net.minecraft.world.InteractionResult;${nl}import net.minecraft.world.ItemInteractionResult;"},
 [pscustomobject]@{from='import net.minecraft.world.entity.LivingEntity;';to="import net.minecraft.world.entity.LivingEntity;${nl}import net.minecraft.world.entity.ai.attributes.Attributes;"},
 [pscustomobject]@{from='import io.github.fabricators_of_create.porting_lib_ufo.block.PlayerDestroyBlock;';to="import io.github.fabricators_of_create.porting_lib_ufo.block.PlayerDestroyBlock;${nl}import net.fabricmc.fabric.api.event.player.PlayerBlockBreakEvents;"},
 [pscustomobject]@{from="`tpublic static final BooleanProperty POWERED = BlockStateProperties.POWERED;";to="`tpublic static final MapCodec<FactoryPanelBlock> CODEC = simpleCodec(FactoryPanelBlock::new);${nl}${nl}`tpublic static final BooleanProperty POWERED = BlockStateProperties.POWERED;"},
 [pscustomobject]@{from="`tpublic static enum PanelSlot implements StringRepresentable {";to="`t@Override${nl}`tprotected MapCodec<? extends FaceAttachedHorizontalDirectionalBlock> codec() {${nl}`t`treturn CODEC;${nl}`t}${nl}${nl}`tpublic static enum PanelSlot implements StringRepresentable {"},
 [pscustomobject]@{from='double range = ReachUtil.reach(pPlacer);';to='double range = pPlacer.getAttributeValue(Attributes.BLOCK_INTERACTION_RANGE) + 1;'},
 [pscustomobject]@{from='IWrenchable.playRemoveSound(world, pos);';to='playRemoveSound(world, pos);'}
)
foreach($c in $changes){if(-not$text.Contains($c.from)){throw "Factory block anchor missing: $($c.from)"};$text=$text.Replace($c.from,$c.to)}
$methodStart=$text.IndexOf("`t@Override${nl}`tpublic InteractionResult use(");$bodyStart=$text.IndexOf("`t`tif (pLevel.isClientSide)",$methodStart);if($methodStart -lt 0 -or $bodyStart -lt 0){throw 'Factory use method bounds missing'};$old=$text.Substring($methodStart,$bodyStart-$methodStart)
$new="`t@Override${nl}`tprotected ItemInteractionResult useItemOn(ItemStack item, BlockState pState, Level pLevel, BlockPos pPos, Player pPlayer,${nl}`t`tInteractionHand pHand, BlockHitResult pHit) {"
if(-not$text.Contains($old)){throw 'Factory useItemOn method anchor missing'};$text=$text.Replace($old,$new)
$interactionChanges=@(
 [pscustomobject]@{from='return InteractionResult.SUCCESS;';to='return ItemInteractionResult.SUCCESS;'},
 [pscustomobject]@{from='return InteractionResult.FAIL;';to='return ItemInteractionResult.FAIL;'}
)
# Restrict result conversion to the item-use method only.
$start=$text.IndexOf($new);$end=$text.IndexOf("${nl}`t@Override${nl}`tpublic boolean onDestroyedByPlayer",$start);if($start -lt 0 -or $end -lt 0){throw 'Factory item-use method bounds missing'};$segment=$text.Substring($start,$end-$start);foreach($c in $interactionChanges){$segment=$segment.Replace($c.from,$c.to)};$text=$text.Substring(0,$start)+$segment+$text.Substring($end)
# Preserve Fabric break protection around sub-panel wrench removal.
$oldBreak="`t`t`tBlockHelper.runWithBreakEvents(world, pos, state, be, player, () -> {${nl}`t`t`t`tif (!be.removePanel(slot))${nl}`t`t`t`t`treturn;"
$newBreak="`t`t`tif (!PlayerBlockBreakEvents.BEFORE.invoker().beforeBlockBreak(world, player, pos, state, be)) {${nl}`t`t`t`tPlayerBlockBreakEvents.CANCELED.invoker().onBlockBreakCanceled(world, player, pos, state, be);${nl}`t`t`t`treturn InteractionResult.SUCCESS;${nl}`t`t`t}${nl}${nl}`t`t`tif (!be.removePanel(slot))${nl}`t`t`t`treturn InteractionResult.SUCCESS;"
if(-not$text.Contains($oldBreak)){throw 'Factory Fabric break-event anchor missing'};$text=$text.Replace($oldBreak,$newBreak)
$oldClose="`t`t`t`tif (be.activePanels() == 0)${nl}`t`t`t`t`tworld.destroyBlock(pos, false);${nl}`t`t`t});${nl}${nl}`t`t`treturn InteractionResult.SUCCESS;"
$newClose="`t`t`tif (be.activePanels() == 0)${nl}`t`t`t`tworld.destroyBlock(pos, false);${nl}${nl}`t`t`treturn InteractionResult.SUCCESS;"
if(-not$text.Contains($oldClose)){throw 'Factory break-event closure anchor missing'};$text=$text.Replace($oldClose,$newClose)
[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$manifest=Get-Content $manifestPath -Raw|ConvertFrom-Json;$entry=$manifest.files|Where-Object path -eq 'content/logistics/factoryBoard/FactoryPanelBlock.java';$entry.changes=@($entry.changes)+$changes+[pscustomobject]@{from=$old;to=$new}+$interactionChanges+[pscustomobject]@{from=$oldBreak;to=$newBreak}+[pscustomobject]@{from=$oldClose;to=$newClose};$entry.status='Original Factory Panel placement/use/removal behavior retained; Minecraft 1.21.1 codec, item interaction and reach APIs plus Fabric break-event protection adapted.';$manifest|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8;Write-Output 'Adapted Factory Panel block to Minecraft 1.21.1 interaction and codec APIs.'
