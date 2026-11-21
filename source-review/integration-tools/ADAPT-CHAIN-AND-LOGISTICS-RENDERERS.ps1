$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$mp=Join-Path $root 'port-changes.json';$m=Get-Content $mp -Raw|ConvertFrom-Json
$targets=@(
 [pscustomobject]@{rel='content/kinetics/chainConveyor/ChainConveyorBlock.java';changes=@(
  [pscustomobject]@{from='import net.minecraft.world.InteractionResult;';to="import net.minecraft.world.InteractionResult;`nimport net.minecraft.world.ItemInteractionResult;"},
  [pscustomobject]@{from="public InteractionResult use(BlockState pState, Level pLevel, BlockPos pPos, Player pPlayer, InteractionHand pHand,`n`t`tBlockHitResult pHit) {`n`t`tif (!pLevel.isClientSide() && pPlayer != null && pPlayer.getItemInHand(pHand)`n`t`t`t.is(Items.CHAIN))`n`t`t`treturn InteractionResult.SUCCESS;`n`t`tif (pPlayer != null && AllBlocks.PACKAGE_FROGPORT.isIn(pPlayer.getItemInHand(pHand)))`n`t`t`treturn InteractionResult.SUCCESS;`n`t`treturn InteractionResult.PASS;`n`t}";to="protected ItemInteractionResult useItemOn(ItemStack stack, BlockState pState, Level pLevel, BlockPos pPos, Player pPlayer, InteractionHand pHand,`n`t`tBlockHitResult pHit) {`n`t`tif (!pLevel.isClientSide() && stack.is(Items.CHAIN))`n`t`t`treturn ItemInteractionResult.SUCCESS;`n`t`tif (AllBlocks.PACKAGE_FROGPORT.isIn(stack))`n`t`t`treturn ItemInteractionResult.SUCCESS;`n`t`treturn ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;`n`t}"},
  [pscustomobject]@{from="public void playerWillDestroy(Level pLevel, BlockPos pPos, BlockState pState, Player pPlayer) {`n`t`tsuper.playerWillDestroy(pLevel, pPos, pState, pPlayer);`n`t`tif (pLevel.isClientSide())`n`t`t`treturn;`n`t`tif (!pPlayer.isCreative())`n`t`t`treturn;`n`t`twithBlockEntityDo(pLevel, pPos, be -> be.cancelDrops = true);`n`t}";to="public BlockState playerWillDestroy(Level pLevel, BlockPos pPos, BlockState pState, Player pPlayer) {`n`t`tsuper.playerWillDestroy(pLevel, pPos, pState, pPlayer);`n`t`tif (pLevel.isClientSide())`n`t`t`treturn pState;`n`t`tif (!pPlayer.isCreative())`n`t`t`treturn pState;`n`t`twithBlockEntityDo(pLevel, pPos, be -> be.cancelDrops = true);`n`t`treturn pState;`n`t}"}
 );status='Original Chain Conveyor interaction and creative-drop handling adapted to Minecraft 1.21.1 block APIs.'},
 [pscustomobject]@{rel='content/kinetics/chainConveyor/ChainConveyorConnectionHandler.java';changes=@(
  [pscustomobject]@{from='import com.simibubi.create.AllSoundEvents;';to="import com.simibubi.create.AllSoundEvents;`nimport com.simibubi.create.CreateClient;"},
  [pscustomobject]@{from='import com.simibubi.create.foundation.outliner.Outliner;';to=''},
  [pscustomobject]@{from='Outliner.getInstance()';to='CreateClient.OUTLINER'}
 );status='Original chain connection previews retained through the Fabric baseline client outliner.'},
 [pscustomobject]@{rel='content/logistics/packagePort/postbox/PostboxRenderer.java';changes=@(
  [pscustomobject]@{from='import net.minecraft.network.chat.Component;';to="import net.minecraft.network.chat.Component;`nimport net.minecraft.core.Direction;"},
  [pscustomobject]@{from='.rotateCentered(Mth.DEG_TO_RAD * (180 - blockEntity.getBlockState()';to='.rotateCentered(Direction.UP, Mth.DEG_TO_RAD * (180 - blockEntity.getBlockState()'},
  [pscustomobject]@{from='flag.rotateXDegrees(';to='flag.rotateX('}
 );status='Original Postbox flag and hover-label renderer adapted to Fabric Flywheel transforms.'},
 [pscustomobject]@{rel='content/logistics/tableCloth/TableClothRenderer.java';changes=@(
  [pscustomobject]@{from='CachedBuffers';to='CachedBufferer'},
  [pscustomobject]@{from='.rotateCentered(rotationInRadians, Direction.UP)';to='.rotateCentered(Direction.UP, rotationInRadians)'},
  [pscustomobject]@{from='.rotate(-rotationInRadians + Mth.PI, Direction.UP)';to='.rotate(Direction.UP, -rotationInRadians + Mth.PI)'},
  [pscustomobject]@{from="`t`t`tDepotRenderer.renderItem(blockEntity.getLevel(), ms, buffer, light, OverlayTexture.NO_OVERLAY, entry, 0,`n`t`t`t`tnull, Vec3.atCenterOf(blockEntity.getBlockPos()), true);";to="`t`t`tDepotRenderer.renderItem(blockEntity.getLevel(), ms, buffer, light, OverlayTexture.NO_OVERLAY, entry, 0,`n`t`t`t`tnull, Vec3.atCenterOf(blockEntity.getBlockPos()));"}
 );status='Original Table Cloth shop/item renderer adapted to Fabric cached buffers, transforms, and Depot renderer signature.'}
)
foreach($t in $targets){$p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$($t.rel)";$x=[IO.File]::ReadAllText($p);foreach($c in $t.changes){if(-not$x.Contains($c.from)){throw "Chain/renderer anchor missing in $($t.rel): $($c.from)"};$x=$x.Replace($c.from,$c.to)};[IO.File]::WriteAllText($p,$x,[Text.UTF8Encoding]::new($false));$e=$m.files|Where-Object path -eq $t.rel;$e.changes=@($e.changes)+$t.changes;if($e.PSObject.Properties.Name -contains 'status'){$e.status=$t.status}else{$e|Add-Member -NotePropertyName status -NotePropertyValue $t.status}}
$m|ConvertTo-Json -Depth 20|Set-Content $mp -Encoding utf8;Write-Output 'Adapted native chain interactions and logistics renderers.'
