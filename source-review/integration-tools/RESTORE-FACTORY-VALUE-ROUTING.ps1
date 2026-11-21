$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$m=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Pin($rel,$text) {
 $p="$root/source/fabric/src/main/java/com/simibubi/create/$rel"
 [IO.Directory]::CreateDirectory((Split-Path $p))|Out-Null
 [IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))
 $script:m.files=@($script:m.files|Where-Object path -ne $rel)+[pscustomobject]@{path=$rel;verificationPath="source/fabric/src/main/java/com/simibubi/create/$rel";verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant();status='Official Create behavior-index routing adapted to baseline Fabric value settings APIs; old constructors retained.'}
 $arg='"'+$p.Replace('\','/')+'"';$ap="$root/integration-compile.args"
 if(-not ([IO.File]::ReadAllText($ap).Contains($arg))){[IO.File]::AppendAllText($ap,"`r`n$arg`r`n")}
}
$rel='foundation/blockEntity/behaviour/ValueSettingsPacket.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('private int row;',"private int row;`r`n`tprivate int behaviourIndex;")
$anchor='public ValueSettingsPacket(RegistryFriendlyByteBuf buffer) {'
$ctor=@'
public ValueSettingsPacket(BlockPos pos, int row, int value, @Nullable InteractionHand interactHand, Direction side, boolean ctrlDown, int behaviourIndex) {
        this(pos, row, value, interactHand, side, ctrlDown);
        this.behaviourIndex = behaviourIndex;
    }

    public ValueSettingsPacket(RegistryFriendlyByteBuf buffer) {
'@
$t=$t.Replace($anchor,$ctor).Replace('buffer.writeBoolean(ctrlDown);',"buffer.writeBoolean(ctrlDown);`r`n`t`tbuffer.writeVarInt(behaviourIndex);").Replace('ctrlDown = buffer.readBoolean();',"ctrlDown = buffer.readBoolean();`r`n`t`tbehaviourIndex = buffer.readVarInt();")
$anchor='if (!valueSettingsBehaviour.acceptsValueSettings())'
$insert=@'
int netId = valueSettingsBehaviour instanceof com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBehaviour panel ? panel.netId() : 0;
            if (behaviourIndex != netId)
                continue;
            if (!valueSettingsBehaviour.acceptsValueSettings())
'@
if(-not $t.Contains($anchor)){throw 'Packet selection anchor missing'}
Pin $rel ($t.Replace($anchor,$insert))
$rel='foundation/blockEntity/behaviour/ValueSettingsScreen.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('private BlockPos pos;',"private BlockPos pos;`r`n`tprivate int behaviourIndex;")
if(-not $t.Contains('private int behaviourIndex;')) {
 $t=$t.Replace('public class ValueSettingsScreen extends AbstractSimiScreen {',"public class ValueSettingsScreen extends AbstractSimiScreen {`r`n`tprivate int behaviourIndex;")
}
if(-not $t.Contains('private int behaviourIndex;')){throw 'Screen class anchor missing'}
$anchor="`t@Override`r`n`tprotected void init()"
$ctor=@'
    public ValueSettingsScreen(BlockPos pos, ValueSettingsBoard board, ValueSettings valueSettings, Consumer<ValueSettings> onHover, int behaviourIndex) {
        this(pos, board, valueSettings, onHover);
        this.behaviourIndex = behaviourIndex;
    }

'@
if(-not $t.Contains($anchor)){throw 'Screen init anchor missing'}
$t=$t.Replace($anchor,$ctor+"`r`n"+$anchor).Replace('AllKeys.ctrlDown()));','AllKeys.ctrlDown(), behaviourIndex));')
Pin $rel $t
$rel='foundation/blockEntity/behaviour/ValueSettingsClient.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('interactHeldHand, interactHeldFace, false));','interactHeldHand, interactHeldFace, false, valueSettingBehaviour instanceof com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBehaviour panel ? panel.netId() : 0));')
$t=$t.Replace('valueSettingBehaviour.getValueSettings(), valueSettingBehaviour::newSettingHovered));','valueSettingBehaviour.getValueSettings(), valueSettingBehaviour::newSettingHovered, valueSettingBehaviour instanceof com.simibubi.create.content.logistics.factoryBoard.FactoryPanelBehaviour panel ? panel.netId() : 0));')
Pin $rel $t
($m.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
