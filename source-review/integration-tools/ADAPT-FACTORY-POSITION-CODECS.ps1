$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Change([string]$path,[string]$from,[string]$to) {
    $entry=$script:manifest.files|Where-Object path -EQ $path
    if(!$entry){throw "Untracked source: $path"}
    $file="$root/source/fabric/src/main/java/com/simibubi/create/$path"
    $text=[IO.File]::ReadAllText($file)
    if($text.Contains($to)){return}
    if(!$text.Contains($from)){throw "Expected source text missing: $path"}
    $entry.changes+=[pscustomobject]@{from=$from;to=$to}
    [IO.File]::WriteAllText($file,$text.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
$block='content/logistics/factoryBoard/FactoryPanelBlock.java'
Change $block 'import java.util.UUID;' "import java.util.UUID;`n`nimport com.mojang.serialization.Codec;"
Change $block 'import net.minecraft.util.Mth;' "import net.minecraft.util.Mth;`nimport net.minecraft.util.StringRepresentable;`nimport io.netty.buffer.ByteBuf;`nimport net.minecraft.network.codec.ByteBufCodecs;`nimport net.minecraft.network.codec.StreamCodec;"
Change $block 'public static enum PanelSlot {' 'public static enum PanelSlot implements StringRepresentable {'
Change $block "`t`tTOP_LEFT(1, 1), TOP_RIGHT(0, 1), BOTTOM_LEFT(1, 0), BOTTOM_RIGHT(0, 0);" "`t`tTOP_LEFT(1, 1), TOP_RIGHT(0, 1), BOTTOM_LEFT(1, 0), BOTTOM_RIGHT(0, 0);`n`n`t`tpublic static final Codec<PanelSlot> CODEC = StringRepresentable.fromValues(PanelSlot::values);`n`t`tpublic static final StreamCodec<ByteBuf, PanelSlot> STREAM_CODEC = ByteBufCodecs.VAR_INT`n`t`t`t.map(index -> values()[index], PanelSlot::ordinal);"
Change $block "`t`tprivate PanelSlot(int xOffset, int yOffset) {`n`t`t`tthis.xOffset = xOffset;`n`t`t`tthis.yOffset = yOffset;`n`t`t}`n" "`t`tprivate PanelSlot(int xOffset, int yOffset) {`n`t`t`tthis.xOffset = xOffset;`n`t`t`tthis.yOffset = yOffset;`n`t`t}`n`n`t`t@Override`n`t`tpublic String getSerializedName() {`n`t`t`treturn Lang.asId(name());`n`t`t}`n"
$position='content/logistics/factoryBoard/FactoryPanelPosition.java'
Change $position 'import net.minecraft.core.BlockPos;' "import net.minecraft.core.BlockPos;`nimport net.minecraft.nbt.CompoundTag;`nimport net.minecraft.nbt.NbtOps;"
Change $position "`t);`n}" "`t);`n`n`t// Compatibility entry points for the Fabric callers collected from the older`n`t// branch. They delegate to Create 6's native codecs and therefore retain its`n`t// serialized representation.`n`tpublic void send(ByteBuf buffer) {`n`t`tSTREAM_CODEC.encode(buffer, this);`n`t}`n`n`tpublic static FactoryPanelPosition receive(ByteBuf buffer) {`n`t`treturn STREAM_CODEC.decode(buffer);`n`t}`n`n`tpublic CompoundTag write() {`n`t`treturn (CompoundTag) CODEC.encodeStart(NbtOps.INSTANCE, this).result().orElseThrow();`n`t}`n`n`tpublic static FactoryPanelPosition read(CompoundTag tag) {`n`t`treturn CODEC.parse(NbtOps.INSTANCE, tag).result().orElseThrow();`n`t}`n}"
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
