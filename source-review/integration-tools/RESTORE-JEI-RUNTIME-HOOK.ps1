$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path $root
$relative = 'src/main/java/com/simibubi/create/compat/jei/CreateJEI.java'
$baselinePath = Join-Path $workspaceRoot "source/fabric/$relative"
$referencePath = Join-Path $root "baseline-reference/$relative"
$sourcePath = Join-Path $root "source/fabric/$relative"
[IO.Directory]::CreateDirectory((Split-Path -Parent $referencePath)) | Out-Null
[IO.Directory]::CreateDirectory((Split-Path -Parent $sourcePath)) | Out-Null
if (-not (Test-Path $referencePath)) {
    [IO.File]::WriteAllText($referencePath, [IO.File]::ReadAllText($baselinePath), [Text.UTF8Encoding]::new($false))
}

$changes = @(
    [pscustomobject]@{
        from = 'import mezz.jei.api.runtime.IIngredientManager;'
        to = "import mezz.jei.api.runtime.IIngredientManager;`nimport mezz.jei.api.runtime.IJeiRuntime;"
    },
    [pscustomobject]@{
        from = "`tprivate static final ResourceLocation ID = Create.asResource(`"jei_plugin`");"
        to = "`tprivate static final ResourceLocation ID = Create.asResource(`"jei_plugin`");`n`tpublic static IJeiRuntime runtime;"
    },
    [pscustomobject]@{
        from = "`tpublic static List<Recipe<?>> getTypedRecipesExcluding(RecipeType<?> type, Predicate<Recipe<?>> exclusionPred) {"
        to = "`t@Override`n`tpublic void onRuntimeAvailable(IJeiRuntime runtime) {`n`t`tCreateJEI.runtime = runtime;`n`t}`n`n`tpublic static List<Recipe<?>> getTypedRecipesExcluding(RecipeType<?> type, Predicate<Recipe<?>> exclusionPred) {"
    }
)

$text = [IO.File]::ReadAllText($referencePath)
foreach ($change in $changes) {
    if (-not $text.Contains($change.from)) { throw "JEI runtime anchor missing: $($change.from)" }
    $text = $text.Replace($change.from, $change.to)
}
[IO.File]::WriteAllText($sourcePath, $text, [Text.UTF8Encoding]::new($false))

$lockPath = Join-Path $root 'baseline-reference-lock.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
if (-not ($lock.files | Where-Object path -eq $relative)) {
    $bytes = [IO.File]::ReadAllBytes($referencePath)
    $prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
    $data = New-Object byte[] ($prefix.Length + $bytes.Length)
    [Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
    [Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try { $blob = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    $lock.files = @($lock.files) + [pscustomobject]@{ gitBlob = $blob; path = $relative }
    $lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
}

$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if (-not ($manifest.files | Where-Object path -eq 'compat/jei/CreateJEI.java')) {
    $manifest.files = @($manifest.files) + [pscustomobject]@{
        path = 'compat/jei/CreateJEI.java'
        sourceRoot = 'baseline-reference'
        changes = $changes
        status = 'Pinned Fabric donor JEI runtime capture restored in the existing 1.21.1 Create JEI plugin for native Stock Keeper search synchronization.'
    }
    $manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
}

$argsPath = Join-Path $root 'integration-compile.args'
$argument = '"' + ($sourcePath -replace '\\', '/') + '"'
$argsText = [IO.File]::ReadAllText($argsPath)
if (-not $argsText.Contains($argument)) {
    [IO.File]::AppendAllText($argsPath, "`r`n$argument`r`n", [Text.UTF8Encoding]::new($false))
}
Write-Output 'Restored Create JEI runtime capture for Stock Keeper search synchronization.'
