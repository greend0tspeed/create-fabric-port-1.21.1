$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$path=Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/content/processing/burner/BlazeBurnerRenderer.java'
$manifestPath=Join-Path $root 'port-changes.json'
$from="`t@Override`n`tprotected void renderSafe(BlazeBurnerBlockEntity be, float partialTicks, PoseStack ms, MultiBufferSource bufferSource,"
$to="`t@Override`n`tpublic void render(BlazeBurnerBlockEntity be, float partialTicks, PoseStack ms, MultiBufferSource bufferSource,`n`t`tint light, int overlay) {`n`t`trenderSafe(be, partialTicks, ms, bufferSource, light, overlay);`n`t}`n`n`tprotected void renderSafe(BlazeBurnerBlockEntity be, float partialTicks, PoseStack ms, MultiBufferSource bufferSource,"
$text=[IO.File]::ReadAllText($path)
if(-not $text.Contains($from)){$from=$from.Replace("`n","`r`n");$to=$to.Replace("`n","`r`n")}
if(-not $text.Contains($from)){throw 'Blaze renderer entrypoint anchor missing'}
$text=$text.Replace($from,$to);[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))
$manifest=Get-Content $manifestPath -Raw|ConvertFrom-Json;$entry=$manifest.files|Where-Object path -eq 'content/processing/burner/BlazeBurnerRenderer.java';$entry.changes=@($entry.changes)+[pscustomobject]@{from=$from;to=$to};$entry.status='Native Create 6 model-aware hat rendering restored; explicit Minecraft 1.21.1 renderer entrypoint delegates to the existing renderSafe implementation while the baseline boolean ABI remains available.';$manifest|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8
Write-Output 'Added the Minecraft 1.21.1 Blaze renderer entrypoint bridge.'
