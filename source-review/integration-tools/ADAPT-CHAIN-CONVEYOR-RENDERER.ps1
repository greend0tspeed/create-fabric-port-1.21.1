$ErrorActionPreference='Stop';$root=Split-Path -Parent $PSScriptRoot;$path=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/kinetics/chainConveyor/ChainConveyorRenderer.java';$manifestPath=Join-Path $root 'port-changes.json'
$changes=@(
 [pscustomobject]@{from='new ResourceLocation("textures/block/chain.png")';to='ResourceLocation.withDefaultNamespace("textures/block/chain.png")'},
 [pscustomobject]@{from='.rotateYDegrees(';to='.rotateY('},
 [pscustomobject]@{from='.rotateXDegrees(';to='.rotateX('},
 [pscustomobject]@{from='.rotateZDegrees(';to='.rotateZ('},
 [pscustomobject]@{from='.center()';to='.centre()'},
 [pscustomobject]@{from='.uncenter()';to='.unCentre()'},
 [pscustomobject]@{from='pConsumer.vertex(pPose, pX, pY, pZ)';to='pConsumer.addVertex(pPose, pX, pY, pZ)'},
 [pscustomobject]@{from='.color(1.0f, 1.0f, 1.0f, 1.0f)';to='.setColor(1.0f, 1.0f, 1.0f, 1.0f)'},
 [pscustomobject]@{from='.uv(pU, pV)';to='.setUv(pU, pV)'},
 [pscustomobject]@{from='.overlayCoords(OverlayTexture.NO_OVERLAY)';to='.setOverlay(OverlayTexture.NO_OVERLAY)'},
 [pscustomobject]@{from='.uv2(light)';to='.setLight(light)'},
 [pscustomobject]@{from='.normal(pNormal, 0.0F, 1.0F, 0.0F)';to='.setNormal(pNormal, 0.0F, 1.0F, 0.0F)'},
 [pscustomobject]@{from="`t`t`t.endVertex();";to=''}
)
$text=[IO.File]::ReadAllText($path);foreach($c in $changes){if(-not$text.Contains($c.from)){throw "Chain renderer anchor missing: $($c.from)"};$text=$text.Replace($c.from,$c.to)};[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$m=Get-Content $manifestPath -Raw|ConvertFrom-Json;$e=$m.files|Where-Object path -eq 'content/kinetics/chainConveyor/ChainConveyorRenderer.java';$e.changes=@($e.changes)+$changes;$e.status='Original native chain, guard, package and light rendering retained; Minecraft 1.21.1 resource/vertex APIs and Fabric TransformStack method names adapted.';$m|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8;Write-Output 'Adapted native Chain Conveyor renderer APIs.'
