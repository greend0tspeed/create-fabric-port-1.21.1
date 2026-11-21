param([switch]$Check)
$ErrorActionPreference = 'Stop'
$lock = Get-Content "$PSScriptRoot/compiler-dependencies.json" -Raw | ConvertFrom-Json
$workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot))
$canonical = Join-Path $workspace $lock.datafixerupper.cachePath
$runtime = Join-Path $workspace $lock.datafixerupper.runtimePath
foreach ($path in @($canonical, $runtime)) {
    if ((Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -ne $lock.datafixerupper.sha256) {
        throw "Compiler/runtime dependency hash mismatch: $path"
    }
}
$canonical = $canonical.Replace('\','/')
$checked = 0
$changed = 0
foreach ($file in Get-ChildItem $PSScriptRoot -Filter *.args) {
    $lines = @(Get-Content -LiteralPath $file.FullName)
    $index = [Array]::IndexOf($lines, '-classpath')
    if ($index -lt 0) { continue }
    $paths = $lines[$index + 1].Trim('"').Split(';')
    $dependencies = @($paths | Where-Object { $_ -match '/(?:com\.mojang|com/mojang)/datafixerupper/' })
    if ($dependencies.Count -eq 0) { continue }
    $checked++
    $valid = $dependencies.Count -eq 1 -and $dependencies[0] -eq $canonical
    if ($Check) {
        if (!$valid) { throw "Mixed or unpinned DataFixerUpper in $($file.Name); run NORMALIZE-COMPILE-CLASSPATH.ps1" }
    } elseif (!$valid) {
        $remaining = @($paths | Where-Object { $_ -notmatch '/(?:com\.mojang|com/mojang)/datafixerupper/' })
        $lines[$index + 1] = '"' + ((@($canonical) + $remaining) -join ';') + '"'
        [IO.File]::WriteAllLines($file.FullName, $lines, [Text.UTF8Encoding]::new($false))
        $changed++
    }
}
if ($checked -eq 0) { throw 'No compiler dependency classpaths found' }
Write-Output "PASS: $checked active classpaths use the pinned Minecraft 1.21.1 DataFixerUpper; $changed updated. Compiler and runtime hashes match."
