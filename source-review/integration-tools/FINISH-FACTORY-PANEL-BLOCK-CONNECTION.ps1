$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$manifestPath=Join-Path $root 'port-changes.json';$manifest=Get-Content $manifestPath -Raw|ConvertFrom-Json
$path=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/factoryBoard/FactoryPanelBlock.java';$text=[IO.File]::ReadAllText($path);$nl=if($text.Contains("`r`n")){"`r`n"}else{"`n"}
$changes=@(
 [pscustomobject]@{from="`t`treturn onBlockEntityUse(world, pos, be -> {";to="`t`treturn onBlockEntityUse(world, pos, be -> {"},
 [pscustomobject]@{from="`t`t`tif (behaviour == null || !behaviour.isActive())${nl}`t`t`t`treturn InteractionResult.SUCCESS;";to="`t`t`tif (behaviour == null || !behaviour.isActive())${nl}`t`t`t`treturn ItemInteractionResult.SUCCESS;"},
 [pscustomobject]@{from="`t`t`t`treturn InteractionResult.SUCCESS;${nl}`t`t`t}";to="`t`t`t`treturn ItemInteractionResult.SUCCESS;${nl}`t`t`t}"},
 [pscustomobject]@{from="`t`t`tif (!be.removePanel(slot))${nl}`t`t`t`treturn InteractionResult.SUCCESS;";to="`t`t`tif (!be.removePanel(slot))${nl}`t`t`t`treturn ItemInteractionResult.SUCCESS;"},
 [pscustomobject]@{from="`t`t`treturn InteractionResult.SUCCESS;${nl}`t`t});";to="`t`t`treturn ItemInteractionResult.SUCCESS;${nl}`t`t}).result();"},
 [pscustomobject]@{from='return InteractionResult.SUCCESS == onBlockEntityUse(level, pos, fpbe -> {';to='return ItemInteractionResult.SUCCESS == onBlockEntityUse(level, pos, fpbe -> {'},
 [pscustomobject]@{from="`t`t`t`treturn InteractionResult.FAIL;";to="`t`t`t`treturn ItemInteractionResult.FAIL;"},
 [pscustomobject]@{from="`t`t`treturn InteractionResult.SUCCESS;${nl}`t`t});${nl}`t}";to="`t`t`treturn ItemInteractionResult.SUCCESS;${nl}`t`t});${nl}`t}"}
)
# Drop no-op marker used only to retain grouping.
$changes=$changes|Where-Object {$_.from -cne $_.to}
foreach($c in $changes){if(-not$text.Contains($c.from)){throw "Factory completion anchor missing: $($c.from)"};$text=$text.Replace($c.from,$c.to)};[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$entry=$manifest.files|Where-Object path -eq 'content/logistics/factoryBoard/FactoryPanelBlock.java';$entry.changes=@($entry.changes)+$changes;$entry.status='Factory Panel block compiles against Minecraft 1.21.1 codec/item-interaction APIs with Fabric break protection and original panel behavior retained.'
$connectionPath=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/factoryBoard/FactoryPanelConnection.java';$connectionChange=[pscustomobject]@{from='.getLocalOffset(level, to.pos(), state)';to='.getLocalOffset(state)'};$ct=[IO.File]::ReadAllText($connectionPath);if(-not$ct.Contains($connectionChange.from)){throw 'Factory connection offset anchor missing'};$ct=$ct.Replace($connectionChange.from,$connectionChange.to);[IO.File]::WriteAllText($connectionPath,$ct,[Text.UTF8Encoding]::new($false));$entry=$manifest.files|Where-Object path -eq 'content/logistics/factoryBoard/FactoryPanelConnection.java';$entry.changes=@($entry.changes)+$connectionChange;$entry.status='Original Factory Panel path calculation retained; current ValueBoxTransform local-offset signature adapted.'
$manifest|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8;Write-Output 'Finished Factory Panel block result and connection-offset migrations.'
