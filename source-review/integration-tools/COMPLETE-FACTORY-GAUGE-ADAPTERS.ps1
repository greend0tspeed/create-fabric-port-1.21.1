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
$rel='foundation/blockEntity/behaviour/filtering/FilteringBehaviour.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('private FilterItemStack filter;', 'protected FilterItemStack filter;')
Pin $rel $t 'Match upstream protected filter visibility so Factory Panels can use their native assignment; no generic filter algorithm changes.'
$rel='content/logistics/factoryBoard/FactoryPanelBehaviour.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace("`r`n","`n").Replace("`n","`r`n")
$t=$t.Replace('return super.setFilter(filter);',"this.filter = FilterItemStack.of(filter);`r`n`t`tblockEntity.setChanged();`r`n`t`tblockEntity.sendData();`r`n`t`treturn true;")
$t=$t.Replace('super.read(panelTag, clientPacket);',"filter = FilterItemStack.of(panelTag.getCompound(""Filter""));`r`n`t`tcount = panelTag.getInt(""FilterAmount"");`r`n`t`tupTo = panelTag.getBoolean(""UpTo"");")
$old="`t`tItemStack filter = getFilter();`r`n`t`tint inStorage = getLevelInStorage();"
$new=@'
		ItemStack filter = getFilter();
		int unloadedLinkCount = getUnloadedLinks();
		FactoryPanelBlockEntity panelBE = panelBE();
		if (!panelBE.restocker && unloadedLinkCount == 0 && lastReportedUnloadedLinks != 0)
			com.simibubi.create.content.logistics.packagerLink.LogisticsManager.SUMMARIES.invalidate(network);
		int inStorage = getLevelInStorage();
'@
if(-not $t.Contains('LogisticsManager.SUMMARIES.invalidate(network)')) {
if(-not $t.Contains($old)){throw 'Storage monitor anchor missing'}
$t=$t.Replace($old,$new)
# Remove the later duplicate declaration only from tickStorageMonitor.
$start=$t.IndexOf('private void tickStorageMonitor()');$end=$t.IndexOf('private void tickRequests()', $start)
$part=$t.Substring($start,$end-$start)
$first=$part.IndexOf('int unloadedLinkCount = getUnloadedLinks();');$second=$part.IndexOf('int unloadedLinkCount = getUnloadedLinks();',$first+1)
if($second -lt 0){throw 'Expected duplicate storage variable absent'}
$part=$part.Remove($second,'int unloadedLinkCount = getUnloadedLinks();'.Length)
$t=$t.Substring(0,$start)+$part+$t.Substring($end)
}
$t=$t.Replace('panelTag.putInt("FilterAmount", count);', 'panelTag.putInt("FilterAmount", count);')
# Restore native safe-copy fields in the Factory Panel's own writer.
$start=$t.IndexOf('public void writeSafe(');$end=$t.IndexOf('public void write(CompoundTag',$start)
$part=$t.Substring($start,$end-$start)
if(-not $part.Contains('panelTag.putBoolean("UpTo", upTo);')) {
$part=$part.Replace('panelTag.putInt("FilterAmount", count);',"panelTag.putInt(""FilterAmount"", count);`r`n`t`tpanelTag.putBoolean(""UpTo"", upTo);")
$part=$part.Replace('nbt.put(Lang.asId(slot.name()), panelTag);',"if (panelBE().restocker)`r`n`t`t`tpanelTag.put(""Promises"", restockerPromises.write(Create.getRegistryAccess()));`r`n`t`tnbt.put(Lang.asId(slot.name()), panelTag);")
}
$t=$t.Substring(0,$start)+$part+$t.Substring($end)
Pin $rel $t 'Restore native Factory Panel zero-target persistence, direct filter assignment, link-load cache invalidation and safe-copy fields.'
$rel='content/logistics/factoryBoard/FactoryPanelBlockEntity.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace("`r`n","`n").Replace("`n","`r`n")
$anchor="`t@Override`r`n`tprotected void write(CompoundTag tag, boolean clientPacket)"
$insert=@'
    @Override
    public void writeSafe(CompoundTag tag) {
        super.writeSafe(tag);
        for (FactoryPanelBehaviour panel : panels.values())
            panel.writeSafe(tag);
    }

'@
if(-not $t.Contains($anchor)){throw 'Panel BE safe write anchor missing'}
Pin $rel ($t.Replace($anchor,$insert+"`r`n"+$anchor)) 'Bridge upstream per-behaviour safe serialization into the baseline SmartBlockEntity safe-write API for Factory Gauges.'
$rel='content/redstone/link/RedstoneLinkBlockEntity.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('private boolean transmitter;',"private boolean transmitter;`r`n`tpublic com.simibubi.create.content.logistics.factoryBoard.FactoryPanelSupportBehaviour panelSupport;")
$old="public void addBehaviours(List<BlockEntityBehaviour> behaviours) {`r`n`t}"
$new=@'
public void addBehaviours(List<BlockEntityBehaviour> behaviours) {
        behaviours.add(panelSupport = new com.simibubi.create.content.logistics.factoryBoard.FactoryPanelSupportBehaviour(this,
            () -> link != null && link.isListening(), () -> receivedSignal > 0,
            () -> AllBlocks.REDSTONE_LINK.get().updateTransmittedSignal(getBlockState(), level, worldPosition)));
    }
'@
if(-not $t.Contains($old)){throw 'Redstone behaviours anchor missing'}
$t=$t.Replace($old,$new).Replace('receivedSignalChanged = false;',"receivedSignalChanged = false;`r`n`t`t`tpanelSupport.notifyPanels();")
Pin $rel $t 'Official Factory Panel redstone support behaviour and receiver-change notification ported onto baseline link lifecycle.'
$rel='content/redstone/link/RedstoneLinkBlock.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$old='int power = getPower(worldIn, pos);'
$new=@'
int power = getPower(worldIn, pos);
        int powerFromPanels = getBlockEntityOptional(worldIn, pos).map(be -> {
            if (be.panelSupport == null)
                return 0;
            Boolean tri = be.panelSupport.shouldBePoweredTristate();
            if (tri == null)
                return -1;
            return tri ? 15 : 0;
        }).orElse(0);
        if (powerFromPanels == -1)
            return;
        power = Math.max(power, powerFromPanels);
'@
if(-not $t.Contains($old)){throw 'Redstone power anchor missing'}
Pin $rel ($t.Replace($old,$new)) 'Official Factory Panel redstone transmitter power merge and unloaded-panel suppression ported.'
$rel='content/redstone/displayLink/DisplayLinkBlockEntity.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('public int refreshTicks;',"public int refreshTicks;`r`n`tpublic com.simibubi.create.content.logistics.factoryBoard.FactoryPanelSupportBehaviour factoryPanelSupport;")
$anchor='public void addBehaviours(List<BlockEntityBehaviour> behaviours) {'
$t=$t.Replace($anchor,$anchor+"`r`n`t`tbehaviours.add(factoryPanelSupport = new com.simibubi.create.content.logistics.factoryBoard.FactoryPanelSupportBehaviour(this, () -> false, () -> false, () -> updateGatheredData()));")
$t=$t.Replace('return worldPosition.relative(getDirection());',"for (com.simibubi.create.content.logistics.factoryBoard.FactoryPanelPosition position : factoryPanelSupport.getLinkedPanels())`r`n`t`t`treturn position.pos();`r`n`t`treturn worldPosition.relative(getDirection());")
Pin $rel $t 'Official Factory Panel Display Link support and linked-gauge source selection ported; baseline display implementation retained.'
($m.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
