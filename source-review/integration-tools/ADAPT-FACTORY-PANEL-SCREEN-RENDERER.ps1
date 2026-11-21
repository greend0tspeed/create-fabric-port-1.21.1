$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$manifestPath=Join-Path $root 'port-changes.json'
$manifest=Get-Content $manifestPath -Raw|ConvertFrom-Json

$screenPath=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/factoryBoard/FactoryPanelScreen.java'
$screenChanges=@(
 [pscustomobject]@{from="`t`taddressBox.tick();`n";to=''},
 [pscustomobject]@{from='CreateLang';to='Lang'},
 [pscustomobject]@{from='public boolean mouseScrolled(double mouseX, double mouseY, double pDelta) {';to='public boolean mouseScrolled(double mouseX, double mouseY, double scrollX, double scrollY) {'},
 [pscustomobject]@{from='addressBox.mouseScrolled(mouseX, mouseY, pDelta)';to='addressBox.mouseScrolled(mouseX, mouseY, scrollX, scrollY)'},
 [pscustomobject]@{from='super.mouseScrolled(mouseX, mouseY, pDelta)';to='super.mouseScrolled(mouseX, mouseY, scrollX, scrollY)'},
 [pscustomobject]@{from='Math.signum(pDelta)';to='Math.signum(scrollY)'},
 [pscustomobject]@{from='r.getResultItem(level.registryAccess())';to='r.value().getResultItem(level.registryAccess())'},
 [pscustomobject]@{from='AllRecipeTypes.shouldIgnoreInAutomation(r)';to='AllRecipeTypes.shouldIgnoreInAutomation(r.value())'},
 [pscustomobject]@{from='r.getIngredients()';to='r.value().getIngredients()'},
 [pscustomobject]@{from="`t`t`t.findAny()`n`t`t`t.orElse(null);";to="`t`t`t.findAny()`n`t`t`t.map(r -> r.value())`n`t`t`t.orElse(null);"}
)
$text=[IO.File]::ReadAllText($screenPath)
foreach($c in $screenChanges){if(-not$text.Contains($c.from)){ $alt=$c.from.Replace("`n","`r`n"); if($text.Contains($alt)){$c.from=$alt;$c.to=$c.to.Replace("`n","`r`n")}else{throw "Factory screen anchor missing: $($c.from)"}};$text=$text.Replace($c.from,$c.to)}
[IO.File]::WriteAllText($screenPath,$text,[Text.UTF8Encoding]::new($false))
$entry=$manifest.files|Where-Object path -eq 'content/logistics/factoryBoard/FactoryPanelScreen.java';$entry.changes=@($entry.changes)+$screenChanges;$entry.status='Original Factory Panel configuration and recipe selection retained; Minecraft 1.21.1 edit-box, scrolling, recipe-holder and Lang APIs adapted.'

$rendererPath=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/logistics/factoryBoard/FactoryPanelRenderer.java'
$rendererChanges=@(
 [pscustomobject]@{from='.rotateCentered(yRot, Direction.UP)';to='.rotateCentered(Direction.UP, yRot)'},
 [pscustomobject]@{from='.rotateCentered(xRot, Direction.EAST)';to='.rotateCentered(Direction.EAST, xRot)'},
 [pscustomobject]@{from='.rotateCentered(Mth.PI, Direction.UP)';to='.rotateCentered(Direction.UP, Mth.PI)'},
 [pscustomobject]@{from='RenderTypes.additive()';to='RenderTypes.getAdditive()'}
)
$text=[IO.File]::ReadAllText($rendererPath)
foreach($c in $rendererChanges){if(-not$text.Contains($c.from)){throw "Factory renderer anchor missing: $($c.from)"};$text=$text.Replace($c.from,$c.to)}
[IO.File]::WriteAllText($rendererPath,$text,[Text.UTF8Encoding]::new($false))
$entry=$manifest.files|Where-Object path -eq 'content/logistics/factoryBoard/FactoryPanelRenderer.java';$entry.changes=@($entry.changes)+$rendererChanges;$entry.status='Original Factory Panel light/path rendering retained; Fabric cached-buffer rotation order and additive render-type getter adapted.'
$manifest|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8
Write-Output 'Adapted Factory Panel screen and renderer APIs.'
