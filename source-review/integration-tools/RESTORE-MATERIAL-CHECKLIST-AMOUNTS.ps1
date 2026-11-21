$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path $root
$relative = 'src/main/java/com/simibubi/create/content/schematics/cannon/MaterialChecklist.java'
$baselinePath = Join-Path $workspaceRoot "source/fabric/$relative"
$referencePath = Join-Path $root "baseline-reference/$relative"
$sourcePath = Join-Path $root "source/fabric/$relative"

$referenceDir = Split-Path -Parent $referencePath
$sourceDir = Split-Path -Parent $sourcePath
[IO.Directory]::CreateDirectory($referenceDir) | Out-Null
[IO.Directory]::CreateDirectory($sourceDir) | Out-Null
if (-not (Test-Path $referencePath)) {
    [IO.File]::WriteAllText($referencePath, [IO.File]::ReadAllText($baselinePath), [Text.UTF8Encoding]::new($false))
}

$changes = @(
    [pscustomobject]@{
        from = '.displayItem(new ItemStack(item)));'
        to = '.displayItem(new ItemStack(item), amount));'
    },
    [pscustomobject]@{
        from = ".displayItem(new ItemStack(item)));`n`t`t}`n`n`t`tpages.add(currentPage);"
        to = ".displayItem(new ItemStack(item), getRequiredAmount(item)));`n`t`t}`n`n`t`tpages.add(currentPage);"
    }
)

$text = [IO.File]::ReadAllText($referencePath)
# The first textual form occurs twice, so adapt the incomplete-entry occurrence explicitly.
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$firstAnchor = "new ClipboardEntry(false, entry(new ItemStack(item), amount, true, false))${newline}`t`t`t`t.displayItem(new ItemStack(item)));"
$firstReplacement = "new ClipboardEntry(false, entry(new ItemStack(item), amount, true, false))${newline}`t`t`t`t.displayItem(new ItemStack(item), amount));"
$secondAnchor = "new ClipboardEntry(true, entry(new ItemStack(item), getRequiredAmount(item), false, false))${newline}`t`t`t`t.displayItem(new ItemStack(item)));"
$secondReplacement = "new ClipboardEntry(true, entry(new ItemStack(item), getRequiredAmount(item), false, false))${newline}`t`t`t`t.displayItem(new ItemStack(item), getRequiredAmount(item)));"
if (-not $text.Contains($firstAnchor)) { throw 'Incomplete material entry anchor missing' }
if (-not $text.Contains($secondAnchor)) { throw 'Completed material entry anchor missing' }
$text = $text.Replace($firstAnchor, $firstReplacement).Replace($secondAnchor, $secondReplacement)
[IO.File]::WriteAllText($sourcePath, $text, [Text.UTF8Encoding]::new($false))

$reviewedChanges = @(
    [pscustomobject]@{ from = $firstAnchor; to = $firstReplacement },
    [pscustomobject]@{ from = $secondAnchor; to = $secondReplacement }
)

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
if (-not ($manifest.files | Where-Object path -eq 'content/schematics/cannon/MaterialChecklist.java')) {
    $manifest.files = @($manifest.files) + [pscustomobject]@{
        path = 'content/schematics/cannon/MaterialChecklist.java'
        sourceRoot = 'baseline-reference'
        changes = $reviewedChanges
        status = 'Original required and completed material quantities now pass through the restored Create itemAmount clipboard API.'
    }
    $manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
}

$argsPath = Join-Path $root 'integration-compile.args'
$argument = '"' + ($sourcePath -replace '\\', '/') + '"'
$argsText = [IO.File]::ReadAllText($argsPath)
if (-not $argsText.Contains($argument)) {
    [IO.File]::AppendAllText($argsPath, "`r`n$argument`r`n", [Text.UTF8Encoding]::new($false))
}

Write-Output 'Restored real material quantities in generated clipboard entries.'
