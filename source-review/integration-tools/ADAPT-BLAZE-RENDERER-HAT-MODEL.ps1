$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path $root
$relative = 'src/main/java/com/simibubi/create/content/processing/burner/BlazeBurnerRenderer.java'
$baselinePath = Join-Path $workspaceRoot "source/fabric/$relative"
$referencePath = Join-Path $root "baseline-reference/$relative"
$sourcePath = Join-Path $root "source/fabric/$relative"
[IO.Directory]::CreateDirectory((Split-Path -Parent $referencePath)) | Out-Null
[IO.Directory]::CreateDirectory((Split-Path -Parent $sourcePath)) | Out-Null
if (-not (Test-Path $referencePath)) { [IO.File]::WriteAllText($referencePath, [IO.File]::ReadAllText($baselinePath), [Text.UTF8Encoding]::new($false)) }
$referenceText = [IO.File]::ReadAllText($referencePath)
$newline = if ($referenceText.Contains("`r`n")) { "`r`n" } else { "`n" }
$changes = @(
    [pscustomobject]@{
        from = "`tprivate static void renderShared(PoseStack ms, @Nullable PoseStack modelTransform, MultiBufferSource bufferSource,${newline}`t`tLevel level, BlockState blockState, HeatLevel heatLevel, float animation, float horizontalAngle,${newline}`t`tboolean canDrawFlame, boolean drawGoggles, boolean drawHat, int hashCode) {"
        to = "`tpublic static void renderShared(PoseStack ms, @Nullable PoseStack modelTransform, MultiBufferSource bufferSource,${newline}`t`tLevel level, BlockState blockState, HeatLevel heatLevel, float animation, float horizontalAngle,${newline}`t`tboolean canDrawFlame, boolean drawGoggles, boolean drawHat, int hashCode) {${newline}`t`trenderShared(ms, modelTransform, bufferSource, level, blockState, heatLevel, animation, horizontalAngle,${newline}`t`t`tcanDrawFlame, drawGoggles, drawHat ? AllPartialModels.TRAIN_HAT : null, hashCode);${newline}`t}${newline}${newline}`tpublic static void renderShared(PoseStack ms, @Nullable PoseStack modelTransform, MultiBufferSource bufferSource,${newline}`t`tLevel level, BlockState blockState, HeatLevel heatLevel, float animation, float horizontalAngle,${newline}`t`tboolean canDrawFlame, boolean drawGoggles, @Nullable PartialModel drawHat, int hashCode) {"
    },
    [pscustomobject]@{ from = 'if (drawHat) {'; to = 'if (drawHat != null) {' },
    [pscustomobject]@{ from = 'CachedBufferer.partial(AllPartialModels.TRAIN_HAT, blockState)'; to = 'CachedBufferer.partial(drawHat, blockState)' }
)
$text = $referenceText
foreach ($change in $changes) { if (-not $text.Contains($change.from)) { throw "Blaze renderer anchor missing: $($change.from)" }; $text = $text.Replace($change.from, $change.to) }
[IO.File]::WriteAllText($sourcePath, $text, [Text.UTF8Encoding]::new($false))

$lockPath = Join-Path $root 'baseline-reference-lock.json'; $lock = Get-Content $lockPath -Raw | ConvertFrom-Json
if (-not ($lock.files | Where-Object path -eq $relative)) {
 $bytes=[IO.File]::ReadAllBytes($referencePath); $prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0"); $data=New-Object byte[] ($prefix.Length+$bytes.Length); [Array]::Copy($prefix,0,$data,0,$prefix.Length); [Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length); $sha=[Security.Cryptography.SHA1]::Create(); try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}; $lock.files=@($lock.files)+[pscustomobject]@{gitBlob=$blob;path=$relative}; $lock|ConvertTo-Json -Depth 10|Set-Content $lockPath -Encoding utf8
}
$manifestPath=Join-Path $root 'port-changes.json'; $manifest=Get-Content $manifestPath -Raw|ConvertFrom-Json
if(-not($manifest.files|Where-Object path -eq 'content/processing/burner/BlazeBurnerRenderer.java')){$manifest.files=@($manifest.files)+[pscustomobject]@{path='content/processing/burner/BlazeBurnerRenderer.java';sourceRoot='baseline-reference';changes=$changes;status='Native Create 6 PartialModel hat rendering restored while retaining the Fabric baseline boolean train-hat ABI.'};$manifest|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8}
$argsPath=Join-Path $root 'integration-compile.args';$argument='"'+($sourcePath-replace '\\','/')+'"';$argsText=[IO.File]::ReadAllText($argsPath);if(-not $argsText.Contains($argument)){[IO.File]::AppendAllText($argsPath,"`r`n$argument`r`n",[Text.UTF8Encoding]::new($false))}
Write-Output 'Restored model-aware Blaze hat rendering with baseline ABI compatibility.'
