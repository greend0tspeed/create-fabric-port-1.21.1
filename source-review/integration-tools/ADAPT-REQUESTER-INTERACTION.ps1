$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to) {
    $entry=$script:manifest.files|Where-Object path -EQ $path;if(!$entry){throw "Untracked source: $path"}
    $file="$root/source/fabric/src/main/java/com/simibubi/create/$path";$text=[IO.File]::ReadAllText($file)
    if(!$text.Contains($from)){if($to.Length -gt 0 -and $text.Contains($to)){return};throw "Expected source text missing: $path"}
    $entry.changes+=[pscustomobject]@{from=$from;to=$to};[IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
$be='content/logistics/redstoneRequester/RedstoneRequesterBlockEntity.java'
Change $be 'import net.minecraft.world.InteractionResult;' 'import net.minecraft.world.ItemInteractionResult;'
Change $be 'public InteractionResult use(Player player)' 'public ItemInteractionResult use(Player player)'
Change $be 'return InteractionResult.PASS;' 'return ItemInteractionResult.PASS_TO_DEFAULT_BLOCK_INTERACTION;'
Change $be 'return InteractionResult.SUCCESS;' 'return ItemInteractionResult.SUCCESS;'
$block='content/logistics/redstoneRequester/RedstoneRequesterBlock.java'
$old=@'
	@Override
	public InteractionResult use(BlockState pState, Level pLevel, BlockPos pPos, Player pPlayer, InteractionHand pHand,
		BlockHitResult pHit) {
		return onBlockEntityUse(pLevel, pPos, be -> be.use(pPlayer));
	}
'@
$new=@'
	@Override
	protected InteractionResult useWithoutItem(BlockState state, Level level, BlockPos pos, Player player,
		BlockHitResult hitResult) {
		return getBlockEntityOptional(level, pos).map(be -> be.use(player).result()).orElse(InteractionResult.PASS);
	}
'@
Change $block $old.TrimEnd("`r","`n") $new.TrimEnd("`r","`n")
$oldPath=@'
	@Override
	public boolean isPathfindable(BlockState pState, BlockGetter pLevel, BlockPos pPos, PathComputationType pType) {
		return false;
	}
'@
$newPath=@'
	@Override
	protected boolean isPathfindable(BlockState state, PathComputationType pathComputationType) {
		return false;
	}
'@
Change $block $oldPath.TrimEnd("`r","`n") $newPath.TrimEnd("`r","`n")
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
