$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$project=Split-Path $root
$m=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Pin($rel,$text,$status) {
 $p="$root/source/fabric/src/main/java/com/simibubi/create/$rel"
 [IO.Directory]::CreateDirectory((Split-Path $p))|Out-Null
 [IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))
 $script:m.files=@($script:m.files|Where-Object path -ne $rel)+[pscustomobject]@{path=$rel;verificationPath="source/fabric/src/main/java/com/simibubi/create/$rel";verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant();status=$status}
 $arg='"'+$p.Replace('\','/')+'"';$ap="$root/integration-compile.args"
 if(-not ([IO.File]::ReadAllText($ap).Contains($arg))){[IO.File]::AppendAllText($ap,"`r`n$arg`r`n")}
}
$rel='content/logistics/stockTicker/StockTickerBlockEntity.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('implements IHaveHoveringInformation, SidedStorageBlockEntity','implements IHaveHoveringInformation, com.simibubi.create.content.equipment.goggles.IHaveHoveringInformation, SidedStorageBlockEntity')
Pin $rel $t 'Expose official Stock Ticker payments hover callback through baseline Fabric hovering interface.'
$rel='foundation/blockEntity/behaviour/ValueBox.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace("`t`tboolean upTo;","`t`tboolean upTo;`r`n`t`tComponent countLabel;")
$anchor="`t`t@Override`r`n`t`tpublic AllIcons getOutline()"
$ctor=@'
        public ItemValueBox(Component label, AABB bb, BlockPos pos, ItemStack stack, Component countLabel) {
            this(label, bb, pos, stack, -1, false);
            this.countLabel = countLabel;
        }

'@
if(-not $t.Contains($anchor)){throw 'ValueBox anchor missing'}
$t=$t.Replace($anchor,$ctor+"`r`n"+$anchor).Replace('if (count == -1)','if (count == -1 && countLabel == null)')
$t=$t.Replace('boolean wildcard = count == 0 || upTo && count >= stack.getMaxStackSize();','boolean wildcard = countLabel == null && (count == 0 || upTo && count >= stack.getMaxStackSize());')
$t=$t.Replace('Component countString = Components.literal(wildcard ? "*" : count + "");','Component countString = countLabel != null ? countLabel : Components.literal(wildcard ? "*" : count + "");')
Pin $rel $t 'Support official component-based item count readouts while retaining all baseline ValueBox constructors and rendering.'
$rel='content/logistics/factoryBoard/FactoryPanelRenderer.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$method=@'
    public static void tickHover() {
        net.minecraft.client.Minecraft mc = net.minecraft.client.Minecraft.getInstance();
        if (!(mc.hitResult instanceof net.minecraft.world.phys.BlockHitResult result) || mc.player.isShiftKeyDown())
            return;
        if (!(mc.level.getBlockEntity(result.getBlockPos()) instanceof FactoryPanelBlockEntity be))
            return;
        net.minecraft.world.level.block.state.BlockState state = be.getBlockState();
        net.minecraft.world.item.ItemStack held = mc.player.getMainHandItem();
        for (FactoryPanelBehaviour behaviour : be.panels.values()) {
            if (!behaviour.isActive())
                continue;
            com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform slot = behaviour.getSlotPositioning();
            if (!slot.shouldRender(state))
                continue;
            boolean hit = slot.testHit(state, result.getLocation().subtract(net.minecraft.world.phys.Vec3.atLowerCornerOf(be.getBlockPos())));
            net.minecraft.network.chat.Component label = behaviour.getLabel();
            net.minecraft.world.phys.AABB bb = new net.minecraft.world.phys.AABB(net.minecraft.world.phys.Vec3.ZERO, net.minecraft.world.phys.Vec3.ZERO).inflate(.25f);
            com.simibubi.create.foundation.blockEntity.behaviour.ValueBox box =
                new com.simibubi.create.foundation.blockEntity.behaviour.ValueBox.ItemValueBox(label, bb, be.getBlockPos(), behaviour.getFilter(), behaviour.getCountLabelForValueBox());
            box.passive(!hit || com.simibubi.create.AllBlocks.CLIPBOARD.isIn(held));
            com.simibubi.create.CreateClient.OUTLINER.showValueBox(com.simibubi.create.foundation.utility.Pair.of("filter" + behaviour.netId(), be.getBlockPos()), box.transform(slot))
                .lineWidth(1 / 64f)
                .withFaceTexture(hit ? com.simibubi.create.AllSpecialTextures.THIN_CHECKERED : null)
                .highlightFace(result.getDirection());
            if (!hit)
                continue;
            java.util.List<net.minecraft.network.chat.MutableComponent> tip = new java.util.ArrayList<>();
            tip.add(label.copy());
            tip.add(behaviour.getTip());
            if (behaviour.isCountVisible())
                tip.add(behaviour.getAmountTip());
            com.simibubi.create.CreateClient.VALUE_SETTINGS_HANDLER.showHoverTip(tip);
        }
    }

'@
$anchor="`tpublic static void renderBulb("
if(-not $t.Contains($anchor)){throw 'Factory renderer anchor missing'}
Pin $rel ($t.Replace($anchor,$method+"`r`n"+$anchor)) 'Official FilteringRenderer hover loop and panel count components adapted specifically for Factory Panels on baseline Fabric APIs.'
$p="$project/source/fabric/src/main/java/com/simibubi/create/CreateClient.java";$t=[IO.File]::ReadAllText($p)
$anchor='com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConnectionHandler.clientTick();'
$t=$t.Replace($anchor,$anchor+"`r`n`t`t`tcom.simibubi.create.content.logistics.factoryBoard.FactoryPanelRenderer.tickHover();")
[IO.File]::WriteAllText($p,$t)
($m.verifiedSources|Where-Object path -eq '../source/fabric/src/main/java/com/simibubi/create/CreateClient.java').sha256=(Get-FileHash $p).Hash.ToLowerInvariant()
($m.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
