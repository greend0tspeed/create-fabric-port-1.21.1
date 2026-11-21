$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path $root
$targets = @(
    [pscustomobject]@{
        relative = 'src/main/java/com/simibubi/create/infrastructure/config/CClient.java'
        manifestPath = 'infrastructure/config/CClient.java'
        changes = @(
            [pscustomobject]@{
                from = "`tpublic final ConfigFloat filterItemRenderDistance = f(10f, 1, `"filterItemRenderDistance`", Comments.filterItemRenderDistance);"
                to = "`tpublic final ConfigFloat filterItemRenderDistance = f(10f, 1, `"filterItemRenderDistance`", Comments.filterItemRenderDistance);`n`tpublic final ConfigBool syncJeiSearch = b(true, `"syncJeiSearch`", Comments.syncJeiSearch);"
            },
            [pscustomobject]@{
                from = "`t`tstatic String rainbowDebug = `"Show kinetic debug information on blocks while the F3-Menu is open.`";"
                to = "`t`tstatic String syncJeiSearch = `"Whether to auto-update the JEI or EMI search when searching in the stock keeper UI`";`n`t`tstatic String rainbowDebug = `"Show kinetic debug information on blocks while the F3-Menu is open.`";"
            }
        )
        status = 'Original stock-keeper JEI/EMI search synchronization client option restored with its original enabled default.'
    },
    [pscustomobject]@{
        relative = 'src/main/java/com/simibubi/create/compat/Mods.java'
        manifestPath = 'compat/Mods.java'
        changes = @(
            [pscustomobject]@{
                from = "`tDYNAMICTREES,"
                to = "`tDYNAMICTREES,`n`tEMI,`n`tJEI,"
            }
        )
        status = 'Original EMI and JEI optional-mod identifiers restored through the existing FabricLoader-backed Mods enum.'
    }
)

$lockPath = Join-Path $root 'baseline-reference-lock.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$argsPath = Join-Path $root 'integration-compile.args'
$argsText = [IO.File]::ReadAllText($argsPath)

foreach ($target in $targets) {
    $baselinePath = Join-Path $workspaceRoot "source/fabric/$($target.relative)"
    $referencePath = Join-Path $root "baseline-reference/$($target.relative)"
    $sourcePath = Join-Path $root "source/fabric/$($target.relative)"
    [IO.Directory]::CreateDirectory((Split-Path -Parent $referencePath)) | Out-Null
    [IO.Directory]::CreateDirectory((Split-Path -Parent $sourcePath)) | Out-Null
    if (-not (Test-Path $referencePath)) {
        [IO.File]::WriteAllText($referencePath, [IO.File]::ReadAllText($baselinePath), [Text.UTF8Encoding]::new($false))
    }
    $text = [IO.File]::ReadAllText($referencePath)
    foreach ($change in $target.changes) {
        if (-not $text.Contains($change.from)) { throw "Missing search-compat anchor in $($target.relative): $($change.from)" }
        $text = $text.Replace($change.from, $change.to)
    }
    [IO.File]::WriteAllText($sourcePath, $text, [Text.UTF8Encoding]::new($false))

    if (-not ($lock.files | Where-Object path -eq $target.relative)) {
        $bytes = [IO.File]::ReadAllBytes($referencePath)
        $prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
        $data = New-Object byte[] ($prefix.Length + $bytes.Length)
        [Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
        [Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
        $sha = [Security.Cryptography.SHA1]::Create()
        try { $blob = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        $lock.files = @($lock.files) + [pscustomobject]@{ gitBlob = $blob; path = $target.relative }
    }
    if (-not ($manifest.files | Where-Object path -eq $target.manifestPath)) {
        $manifest.files = @($manifest.files) + [pscustomobject]@{
            path = $target.manifestPath
            sourceRoot = 'baseline-reference'
            changes = $target.changes
            status = $target.status
        }
    }
    $argument = '"' + ($sourcePath -replace '\\', '/') + '"'
    if (-not $argsText.Contains($argument)) { $argsText += "`r`n$argument`r`n" }
}

$lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
[IO.File]::WriteAllText($argsPath, $argsText, [Text.UTF8Encoding]::new($false))
Write-Output 'Restored stock-search configuration and JEI/EMI mod identifiers.'
