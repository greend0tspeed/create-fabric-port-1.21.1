$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$m=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Write-Pinned($relative,$text,$status) {
 $p=Join-Path $root "source/fabric/src/main/java/com/simibubi/create/$relative"
 [IO.Directory]::CreateDirectory((Split-Path $p))|Out-Null
 [IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))
 $script:m.files=@($script:m.files|Where-Object path -ne $relative)+[pscustomobject]@{path=$relative;verificationPath="source/fabric/src/main/java/com/simibubi/create/$relative";verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant();status=$status}
 $arg='"'+$p.Replace('\','/')+'"'
 $ap="$root/integration-compile.args"
 if(-not ([IO.File]::ReadAllText($ap).Contains($arg))){[IO.File]::AppendAllText($ap,"`r`n$arg`r`n")}
}
# Append the already-ported official packets, preserving all existing channel IDs.
$p="$project/source/fabric/src/main/java/com/simibubi/create/AllPackets.java"
$t=[IO.File]::ReadAllText($p)
$anchor="`t;"
$insert=@'
,
 CONNECT_FACTORY_PANEL(com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConnectionPacket.class, com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConnectionPacket::new, PLAY_TO_SERVER),
 CONFIGURE_FACTORY_PANEL(com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConfigurationPacket.class, com.simibubi.create.content.logistics.factoryBoard.FactoryPanelConfigurationPacket::new, PLAY_TO_SERVER),
 FACTORY_PANEL_EFFECT(com.simibubi.create.content.logistics.factoryBoard.FactoryPanelEffectPacket.class, com.simibubi.create.content.logistics.factoryBoard.FactoryPanelEffectPacket::new, PLAY_TO_CLIENT),
 SHOP_UPDATE(com.simibubi.create.content.logistics.tableCloth.ShopUpdatePacket.class, com.simibubi.create.content.logistics.tableCloth.ShopUpdatePacket::new, PLAY_TO_CLIENT)
'@
if($t.Contains('CONFIGURE_FACTORY_PANEL(')){throw 'Factory packets already registered'}
if(-not $t.Contains($anchor)){throw 'Packet enum anchor missing'}
[IO.File]::WriteAllText($p,$t.Replace($anchor,$insert+"`r`n"+$anchor))
foreach($s in $m.verifiedSources){if($s.path -eq '../source/fabric/src/main/java/com/simibubi/create/AllPackets.java'){$s.sha256=(Get-FileHash $p).Hash.ToLowerInvariant()}}
# The official generic FilteringRenderer loops over all behaviours. The baseline
# only handles FilteringBehaviour.TYPE; render the remaining Factory Panel filters here.
$rel='content/logistics/factoryBoard/FactoryPanelRenderer.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$anchor="`t`t`tif (behaviour.getAmount() > 0)"
$insert=@'
            if (!behaviour.getFilter().isEmpty()) {
                com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxTransform slotPositioning = behaviour.getSlotPositioning();
                if (slotPositioning.shouldRender(be.getBlockState())) {
                    ms.pushPose();
                    slotPositioning.transform(be.getBlockState(), ms);
                    com.simibubi.create.foundation.blockEntity.behaviour.ValueBoxRenderer.renderItemIntoValueBox(behaviour.getFilter(), ms, buffer, light, overlay);
                    ms.popPose();
                }
            }
'@
if(-not $t.Contains($anchor)){throw 'Panel rendering anchor missing'}
Write-Pinned $rel ($t.Replace($anchor,$insert+"`r`n"+$anchor)) 'Official FilteringRenderer item-render path applied to each Factory Panel on the older Fabric renderer.'
# Official BigOutlines searches vertical neighbours for blocks whose outline
# extends outside their cell. Apply that search to Tablecloths; preserve the
# baseline track/door selection and do not change Chain Conveyor targeting.
$rel='foundation/block/BigOutlines.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('for (int z = -1; z <= 1; z++) {',"for (int y = -1; y <= 1; y++) {`r`n`t`t`t`tfor (int z = -1; z <= 1; z++) {")
$t=$t.Replace('pos.getY(), pos.getZ() + z','pos.getY() + y, pos.getZ() + z')
$old=@'
if (!(blockState.getBlock() instanceof TrackBlock)
						&& !(blockState.getBlock() instanceof SlidingDoorBlock))
'@
$new=@'
if (!(blockState.getBlock() instanceof com.simibubi.create.content.logistics.tableCloth.TableClothBlock)
                        && (y != 0 || (!(blockState.getBlock() instanceof TrackBlock)
                        && !(blockState.getBlock() instanceof SlidingDoorBlock))))
'@
$t=$t.Replace("`r`n","`n");$old=$old.Replace("`r`n","`n")
if(-not $t.Contains($old)){throw 'Big outline selection anchor missing'}
$t=$t.Replace($old,$new)
$t=$t.Replace('if (interactionDist >= maxRange)','if (interactionDist >= maxRange + (blockState.getBlock() instanceof com.simibubi.create.content.logistics.tableCloth.TableClothBlock ? 0.5 : 0))')
$anchor="`n`t`t`treturn result != null;"
if(-not $t.Contains($anchor)){throw 'Outline loop anchor missing'}
$t=$t.Replace($anchor,"`n            }`n"+$anchor)
Write-Pinned $rel $t 'Official vertical-neighbour big-outline algorithm enabled for Tablecloths; baseline other targeting retained.'
# Use the event hit, as official ValueSettingsInputHandler does, rather than
# recasting through the supporting block and losing the Tablecloth target.
$rel='foundation/blockEntity/behaviour/ValueSettingsInputHandler.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$old='BlockHitResult ray = RaycastHelper.rayTraceRange(world, player, 10);'
$new='BlockHitResult ray = world.getBlockState(pos).getBlock() instanceof com.simibubi.create.content.logistics.tableCloth.TableClothBlock ? hit : RaycastHelper.rayTraceRange(world, player, 10);'
if(-not $t.Contains($old)){throw 'Input ray anchor missing'}
Write-Pinned $rel ($t.Replace($old,$new)) 'Use official event hit for Tablecloth value settings after extended-outline targeting.'
($m.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
