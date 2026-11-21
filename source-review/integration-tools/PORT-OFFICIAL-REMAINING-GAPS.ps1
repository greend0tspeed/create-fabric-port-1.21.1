$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$project = Split-Path $root
$donor = "$project/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb"
$java = 'src/main/java/com/simibubi/create'
$manifest = Get-Content "$root/port-changes.json" -Raw | ConvertFrom-Json
function Pin($rel, $text, $reason) {
    $path = "$root/source/fabric/$java/$rel"
    New-Item -ItemType Directory (Split-Path $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $text)
    $script:manifest.files = @($script:manifest.files | Where-Object path -ne $rel) + [pscustomobject]@{
        path=$rel; verificationPath="source/fabric/$java/$rel";
        verificationSha256=(Get-FileHash $path).Hash.ToLowerInvariant(); status=$reason
    }
    $arg='"'+$path.Replace('\','/')+'"'
    $argsPath="$root/integration-compile.args"
    if (-not ([IO.File]::ReadAllText($argsPath).Contains($arg))) {
        [IO.File]::AppendAllText($argsPath,"`r`n$arg`r`n")
    }
}
function Official($rel) { [IO.File]::ReadAllText("$donor/$java/$rel") }
function Baseline($rel) { [IO.File]::ReadAllText("$project/source/fabric/$java/$rel") }

# Native address selection, with only inventory access translated to Fabric views.
$rel='content/redstone/displayLink/source/PackageAddressDisplaySource.java'
$t=Official $rel
$t=$t.Replace('import net.neoforged.neoforge.items.IItemHandler;', 'import net.fabricmc.fabric.api.transfer.v1.item.ItemVariant;'+"`n"+'import net.fabricmc.fabric.api.transfer.v1.storage.Storage;'+"`n"+'import net.fabricmc.fabric.api.transfer.v1.storage.StorageView;')
$t=$t.Replace('IItemHandler handler = invManipulationBehaviour.getInventory();','Storage<ItemVariant> handler = invManipulationBehaviour.getInventory();')
$t=$t.Replace('for (int i = 0; i < handler.getSlots(); i++) {', 'for (StorageView<ItemVariant> view : handler.nonEmptyViews()) {')
$t=$t.Replace('ItemStack stack = handler.getStackInSlot(i);','ItemStack stack = view.getResource().toStack();')
Pin $rel $t 'Official package-address Display Link source; native inventory iteration translated to Fabric storage views.'
$rel='content/redstone/displayLink/AllDisplayBehaviours.java'
$t=Baseline $rel
$anchor='public static void registerDefaults() {'
$t=$t.Replace($anchor,$anchor+"`n"+'        assignBlock(register(Create.asResource("smart_observer_source_read_package_address"), new com.simibubi.create.content.redstone.displayLink.source.PackageAddressDisplaySource()), com.simibubi.create.AllBlocks.SMART_OBSERVER.get());')
Pin $rel $t 'Register the official package-address display source on Smart Observers alongside existing display behaviours.'

# Retain the working deployer; replace only safeOnUse with upstream drop capture.
$rel='content/kinetics/deployer/DeployerHandler.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/$java/$rel")
$start=$t.IndexOf("`tpublic static InteractionResult safeOnUse(")
$end=$t.IndexOf("`tprotected static InteractionResult safeOnBeehiveUse(",$start)
if($start -lt 0 -or $end -lt 0){throw 'Deployer use anchors missing'}
$native=Official $rel
$ns=$native.IndexOf("`tpublic static InteractionResult safeOnUse(")
$part=$native.Substring($ns)
$part=$part.Substring(0,$part.LastIndexOf('}'))
# Keep the already working 1.21 default-use dispatch, identical to BlockHelper.invokeUse.
$part=$part.Replace('BlockHelper.invokeUse(state, world, player, hand, ray)','invokeDefaultBlockUse(state, world, player, hand, ray)')
$t=$t.Substring(0,$start)+$part+$t.Substring($end)
$t=$t.Replace('public class DeployerHandler {',@'
public class DeployerHandler {
    private static final java.util.Map<BlockPos, List<ItemEntity>> CAPTURED_BLOCK_DROPS = new java.util.HashMap<>();
    public static final java.util.Map<BlockPos, List<ItemEntity>> CAPTURED_BLOCK_DROPS_VIEW = java.util.Collections.unmodifiableMap(CAPTURED_BLOCK_DROPS);
'@)
$helper=Official 'foundation/utility/BlockHelper.java'
$hs=$helper.IndexOf("`tpublic static InteractionResult invokeUse(")
$helper=$helper.Substring($hs); $helper=$helper.Substring(0,$helper.LastIndexOf('}'))
$helper=$helper.Replace('public static InteractionResult invokeUse(', 'private static InteractionResult invokeDefaultBlockUse(').Replace('ItemInteractionResult','net.minecraft.world.ItemInteractionResult')
$last=$t.LastIndexOf('}');$t=$t.Insert($last,$helper)
Pin $rel $t 'Official scoped drop-capture map and try/finally cleanup; exact upstream default-block-use dispatcher, preserving all other deployed functionality.'
Pin 'foundation/mixin/BlockMixin.java' (Official 'foundation/mixin/BlockMixin.java') 'Exact official Block.popResource drop-capture hook; active only within a Deployer capture scope.'
Pin 'foundation/mixin/accessor/CropBlockAccessor.java' (Official 'foundation/mixin/accessor/CropBlockAccessor.java') 'Exact official crop age-property accessor for preserving modded crop state when replanting.'

$rel='content/contraptions/actors/harvester/HarvesterMovementBehaviour.java'
$t=Baseline $rel
$native=Official $rel
# Replace crop detection and reset only. Preserve the baseline movement/render ABI.
$s=$t.IndexOf("`tpublic boolean isValidCrop("); $e=$t.IndexOf("`tprivate BlockState cutCrop(",$s)
$ns=$native.IndexOf("`tpublic boolean isValidCrop("); $ne=$native.IndexOf("`t@Override`n`tpublic boolean disableBlockEntityRendering()",$ns)
if($ne -lt 0){$ne=$native.IndexOf("`t@Override`r`n`tpublic boolean disableBlockEntityRendering()",$ns)}
if($s -lt 0 -or $e -lt 0 -or $ns -lt 0 -or $ne -lt 0){throw 'Harvester anchors missing'}
$part=$native.Substring($ns,$ne-$ns)
$part=$part.Replace('Mods.FARMERSDELIGHT.isLoaded()','net.fabricmc.loader.api.FabricLoader.getInstance().isModLoaded("farmersdelight")')
$part=$part.Replace('state.getBlock() instanceof SpecialPlantable','state.getBlock() instanceof IPlantable')
$t=$t.Substring(0,$s)+$part+"`n}"
$t=$t.Replace('import javax.annotation.Nullable;',@'
import javax.annotation.Nullable;
import com.simibubi.create.AllTags.AllBlockTags;
import com.simibubi.create.compat.farmersdelight.FarmersDelightCompat;
import com.simibubi.create.foundation.mixin.accessor.CropBlockAccessor;
import net.minecraft.world.level.block.MushroomBlock;
import net.minecraft.world.level.block.BushBlock;
'@)
Pin $rel $t 'Official crop eligibility and state-preserving replant/reset algorithms; baseline actor ABI retained and optional-mod detection uses Fabric.'
$rel='compat/farmersdelight/FarmersDelightCompat.java'
$t=Official $rel
$t=$t.Replace('import vectorwing.farmersdelight.common.registry.ModBlocks;', 'import net.minecraft.core.registries.BuiltInRegistries;'+"`n"+'import net.minecraft.resources.ResourceLocation;')
$t=$t.Replace('ModBlocks.RICH_SOIL.get()', 'BuiltInRegistries.BLOCK.get(ResourceLocation.fromNamespaceAndPath("farmersdelight", "rich_soil"))')
Pin $rel $t 'Official mushroom-on-rich-soil exclusion; optional Fabric registry lookup avoids linking NeoForge-only mod classes.'
$rel='AllTags.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/$java/$rel")
$t=$t.Replace('SAFE_NBT, SEATS, POSTBOXES, TABLE_CLOTHS, TOOLBOXES,','SAFE_NBT, SEATS, POSTBOXES, TABLE_CLOTHS, TOOLBOXES, SUGAR_CANE_VARIANTS,')
Pin $rel $t 'Add the official sugar-cane variant block tag consumed by native harvester reset logic.'
$resource="$root/source/fabric/src/main/resources/data/create/tags/block/sugar_cane_variants.json"
New-Item -ItemType Directory (Split-Path $resource) -Force|Out-Null
Copy-Item "$donor/src/generated/resources/data/create/tags/block/sugar_cane_variants.json" $resource

# Mixin config is an overlay; do not change the established mixin registrations.
$mix=Get-Content "$project/source/fabric/src/main/resources/create.mixins.json" -Raw|ConvertFrom-Json
$mix.mixins=@($mix.mixins)+@('BlockMixin','accessor.CropBlockAccessor')
$resource="$root/source/fabric/src/main/resources/create.mixins.json"
$mix|ConvertTo-Json -Depth 12|Set-Content $resource -Encoding utf8

($manifest.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
