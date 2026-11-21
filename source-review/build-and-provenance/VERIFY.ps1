$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
& "$root/NORMALIZE-COMPILE-CLASSPATH.ps1" -Check
$verifiedFiles = 0
foreach ($inputSource in @(@{name='upstream';manifest='upstream-lock.json'},@{name='fabric-reference';manifest='fabric-reference-lock.json'},@{name='baseline-reference';manifest='baseline-reference-lock.json'},@{name='dependency-reference';manifest='dependency-reference-lock.json'})) {
$lock = Get-Content (Join-Path $root $inputSource.manifest) -Raw | ConvertFrom-Json
foreach ($file in $lock.files) {
    $bytes = [IO.File]::ReadAllBytes((Join-Path (Join-Path $root $inputSource.name) $file.path))
    $prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
    $data = New-Object byte[] ($prefix.Length + $bytes.Length)
    [Array]::Copy($prefix,0,$data,0,$prefix.Length)
    [Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try { $actual = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
    if ($actual -ne $file.gitBlob) { throw "Upstream source mismatch: $($file.path)" }
    $verifiedFiles++
}
}
$changes = Get-Content "$root/port-changes.json" -Raw | ConvertFrom-Json
foreach ($source in $changes.verifiedSources) {
	$target = [IO.Path]::GetFullPath((Join-Path $root $source.path))
	$verifiedWorkspace = [IO.Path]::GetFullPath((Split-Path $root)) + [IO.Path]::DirectorySeparatorChar
	if (-not $target.StartsWith($verifiedWorkspace, [StringComparison]::OrdinalIgnoreCase)) {
		throw "Verified source escaped the native port workspace: $($source.path)"
	}
	$actualHash = (Get-FileHash $target -Algorithm SHA256).Hash.ToLowerInvariant()
	if ($actualHash -ne $source.sha256) {
		throw "Verified compatibility source changed: $($source.path)"
	}
}
foreach ($file in $changes.files) {
	if ($file.verificationPath) {
		$target = [IO.Path]::GetFullPath((Join-Path $root $file.verificationPath))
		$resolvedRoot = [IO.Path]::GetFullPath($root) + [IO.Path]::DirectorySeparatorChar
		if (-not $target.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
			throw "Verification target escaped the integration workspace: $($file.path)"
		}
		$actualHash = (Get-FileHash $target -Algorithm SHA256).Hash.ToLowerInvariant()
		if ($actualHash -ne $file.verificationSha256) {
			throw "Pinned integration source changed: $($file.path)"
		}
		continue
	}
    $relative = "src/main/java/com/simibubi/create/$($file.path)"
    $sourceRoot = if ($file.sourceRoot) { $file.sourceRoot } else { 'upstream' }
    $expected = [IO.File]::ReadAllText((Join-Path (Join-Path $root $sourceRoot) $relative))
    foreach ($change in $file.changes) { $expected = $expected.Replace($change.from,$change.to) }
    $actual = [IO.File]::ReadAllText((Join-Path "$root/source/fabric" $relative))
    if ($actual -cne $expected) { throw "Unreviewed adaptation: $($file.path)" }
}
$baseline = Get-Content "$root/baseline-lock.json" -Raw | ConvertFrom-Json
foreach ($file in (Get-Content "$root/resource-changes.json" -Raw | ConvertFrom-Json).files) {
    $expected = [IO.File]::ReadAllText("$root/$($file.sourceRoot)/$($file.sourcePath)")
    foreach ($change in $file.changes) { $expected = $expected.Replace($change.from, $change.to) }
    if ([IO.File]::ReadAllText("$root/source/$($file.path)") -cne $expected) {
        throw "Unreviewed resource adaptation: $($file.path)"
    }
}
foreach ($file in (Get-Content "$root/module-changes.json" -Raw | ConvertFrom-Json).files) {
    $expected = [IO.File]::ReadAllText("$root/$($file.sourceRoot)/$($file.path)")
    foreach ($change in $file.changes) { $expected = $expected.Replace($change.from, $change.to) }
    if ([IO.File]::ReadAllText("$root/source/$($file.path)") -cne $expected) {
        throw "Unreviewed dependency adaptation: $($file.path)"
    }
}
foreach ($entry in $baseline.compatibilitySourceHashes.PSObject.Properties) {
    if ((Get-FileHash (Join-Path "$root/source" $entry.Name)).Hash.ToLowerInvariant() -ne $entry.Value) {
        throw "Compatibility patch mismatch: $($entry.Name)"
    }
}
if (Test-Path "$root/source/logistics_sandbox") { throw 'Sandbox module leaked into native source fork' }
if ((Get-Content "$root/source/settings.gradle" -Raw) -match 'logistics_sandbox') { throw 'Sandbox build inclusion found' }
Write-Output "PASS: $verifiedFiles upstream code/license/reference hashes, $($changes.files.Count) reviewed source adaptations, all baseline source patches, and sandbox exclusion."
