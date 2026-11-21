$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$argsPath = Join-Path $root 'integration-compile.args'
$manifestPath = Join-Path $root 'port-changes.json'
$referenceLockPath = Join-Path $root 'fabric-reference-lock.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$referenceLock = Get-Content $referenceLockPath -Raw | ConvertFrom-Json
$workspaceRoot = Split-Path $root

$targets = @(
	'foundation/model/BakedQuadHelper.java',
	'content/equipment/blueprint/BlueprintOverlayRenderer.java',
	'content/trains/observer/TrackObserverBlockEntity.java',
	'content/kinetics/motor/CreativeMotorBlockEntity.java'
)

foreach ($relative in $targets) {
	$sourceRelative = "src/main/java/com/simibubi/create/$relative"
	$reference = Join-Path $root "fabric-reference/$sourceRelative"
	$donor = Join-Path $workspaceRoot "full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/$sourceRelative"
	$destination = Join-Path $root "source/fabric/$sourceRelative"
	if (-not (Test-Path $reference)) {
		if (-not (Test-Path $donor)) {
			throw "Pinned Fabric helper is missing: $sourceRelative"
		}
		[IO.Directory]::CreateDirectory((Split-Path -Parent $reference)) | Out-Null
		[IO.File]::WriteAllText($reference, [IO.File]::ReadAllText($donor), [Text.UTF8Encoding]::new($false))
		$bytes = [IO.File]::ReadAllBytes($reference)
		$prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
		$data = New-Object byte[] ($prefix.Length + $bytes.Length)
		[Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
		[Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
		$sha = [Security.Cryptography.SHA1]::Create()
		try { $blob = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
		finally { $sha.Dispose() }
		$referenceLock.files = @($referenceLock.files) + [pscustomobject]@{ gitBlob = $blob; path = $sourceRelative }
	}
	[IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
	[IO.File]::WriteAllText($destination, [IO.File]::ReadAllText($reference), [Text.UTF8Encoding]::new($false))
	if (-not ($manifest.files | Where-Object path -eq $relative)) {
		$manifest.files = @($manifest.files) + [pscustomobject]@{
			path = $relative
			sourceRoot = 'fabric-reference'
			changes = @()
			status = 'Exact pinned Fabric Create implementation restored for the final native helper cluster.'
		}
	}
	$argument = '"' + ($destination -replace '\\', '/') + '"'
	$arguments = [IO.File]::ReadAllText($argsPath)
	if (-not $arguments.Contains($argument)) {
		[IO.File]::AppendAllText($argsPath, "`r`n$argument`r`n", [Text.UTF8Encoding]::new($false))
	}
}

$computer = $manifest.files | Where-Object path -eq 'compat/computercraft/implementation/ComputerBehaviour.java'
if ($null -eq $computer) {
	throw 'ComputerBehaviour provenance entry is missing.'
}
$computer.changes = @()
$computer.status = 'Exact pinned Fabric Creative Motor behaviour access restored.'
$computerPath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/compat/computercraft/implementation/ComputerBehaviour.java'
$computerText = [IO.File]::ReadAllText($computerPath)
$computerText = $computerText.Replace('cmbe.getGeneratedSpeed()', 'cmbe.generatedSpeed')
[IO.File]::WriteAllText($computerPath, $computerText, [Text.UTF8Encoding]::new($false))

$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
$referenceLock | ConvertTo-Json -Depth 10 | Set-Content $referenceLockPath -Encoding utf8
Write-Output 'Restored the exact pinned Fabric helper, overlay, observer, and motor implementations.'
