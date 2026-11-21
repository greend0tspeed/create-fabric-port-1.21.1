$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path $root
$upstreamRoot = Join-Path $workspaceRoot 'ponder-upstream'
$sourceRelative = 'catnip/src/main/java/net/createmod/catnip/data/Glob.java'
$licenseRelative = 'catnip/LICENSE'
$upstreamSource = Join-Path $upstreamRoot 'common/src/main/java/net/createmod/catnip/data/Glob.java'
$upstreamLicense = Join-Path $upstreamRoot 'LICENSE'
$referenceSource = Join-Path $root "dependency-reference/$sourceRelative"
$referenceLicense = Join-Path $root "dependency-reference/$licenseRelative"
$destination = Join-Path $root "source/$sourceRelative"

foreach ($pair in @(@($upstreamSource, $referenceSource), @($upstreamLicense, $referenceLicense), @($upstreamSource, $destination))) {
	[IO.Directory]::CreateDirectory((Split-Path -Parent $pair[1])) | Out-Null
	[IO.File]::WriteAllText($pair[1], [IO.File]::ReadAllText($pair[0]), [Text.UTF8Encoding]::new($false))
}

$lockPath = Join-Path $root 'dependency-reference-lock.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
foreach ($relative in @($sourceRelative, $licenseRelative)) {
	if ($lock.files | Where-Object path -eq $relative) { continue }
	$file = Join-Path $root "dependency-reference/$relative"
	$bytes = [IO.File]::ReadAllBytes($file)
	$prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
	$data = New-Object byte[] ($prefix.Length + $bytes.Length)
	[Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
	[Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
	$sha = [Security.Cryptography.SHA1]::Create()
	try { $blob = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
	finally { $sha.Dispose() }
	$lock.files = @($lock.files) + [pscustomobject]@{ gitBlob = $blob; path = $relative }
}
$lock | Add-Member -Force NoteProperty additionalSources @([pscustomobject]@{
	repository = 'Creators-of-Create/Ponder'
	commit = 'eff36cf1a4a1826178cf85f1b475af761df770ab'
	role = 'Exact Catnip Glob implementation and MIT license used by Create 6 address and ComputerCraft filtering.'
})
$lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8

$modulesPath = Join-Path $root 'module-changes.json'
$modules = Get-Content $modulesPath -Raw | ConvertFrom-Json
if (-not ($modules.files | Where-Object path -eq $sourceRelative)) {
	$modules.files = @($modules.files) + [pscustomobject]@{
		sourceRoot = 'dependency-reference'
		path = $sourceRelative
		changes = @()
		reason = 'Compile the exact pinned Catnip glob parser required by native Create 6 filtering.'
	}
}
$modules | ConvertTo-Json -Depth 20 | Set-Content $modulesPath -Encoding utf8

$argsPath = Join-Path $root 'integration-compile.args'
$argument = '"' + ($destination -replace '\\', '/') + '"'
$arguments = [IO.File]::ReadAllText($argsPath)
if (-not $arguments.Contains($argument)) {
	[IO.File]::AppendAllText($argsPath, "`r`n$argument`r`n", [Text.UTF8Encoding]::new($false))
}
Write-Output 'Imported the exact pinned Ponder/Catnip Glob source and license.'
