$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$workspace = Split-Path (Split-Path (Split-Path $root))
$projectRoot = Split-Path $root
$outputRoot = Join-Path $workspace 'outputs/native-create6-port'
$javaRoot = Join-Path $workspace 'work/java21/jdk-21.0.13+9/bin'
$baseJar = Join-Path $outputRoot 'create-reforged-6.0.10-cobblemon-baseline.jar'
$namedJar = Join-Path $root 'native-create6-alpha-named.jar'
$remappedJar = Join-Path $root 'native-create6-alpha-intermediary.jar'
$remappedDirectory = Join-Path $root 'remapped-classes'
$outputJar = Join-Path $outputRoot 'create-reforged-6.0.10-native-logistics-alpha.jar'
$expectedBase = 'ac2c5c18add02941f71f6917604e24ae857f630d288814acf6f8de17b0ba2192'

& "$root/VERIFY.ps1"
& "$root/BUILD.ps1"
if ((Get-FileHash $baseJar -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedBase) {
	throw 'Baseline jar mismatch.'
}

foreach ($path in @($namedJar, $remappedJar, $outputJar)) {
	if (Test-Path $path) { Remove-Item -LiteralPath $path -Force }
}
$resolvedRoot = [IO.Path]::GetFullPath($root) + [IO.Path]::DirectorySeparatorChar
$resolvedRemappedDirectory = [IO.Path]::GetFullPath($remappedDirectory)
if (-not $resolvedRemappedDirectory.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
	throw 'Remapped class directory escaped the integration workspace.'
}
if (Test-Path $remappedDirectory) { Remove-Item -LiteralPath $remappedDirectory -Recurse -Force }

Push-Location (Join-Path $root 'compiled')
try { & "$javaRoot/jar.exe" --create --file $namedJar . }
finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { throw 'Failed to create the named class overlay.' }

$argsLines = Get-Content (Join-Path $root 'integration-compile.args')
$classpathIndex = [Array]::IndexOf($argsLines, '-classpath')
$classpath = $argsLines[$classpathIndex + 1].Trim('"') -split ';'
$tinyRemapper = Join-Path $workspace 'work/logistics-sandbox/gradle-cache/caches/modules-2/files-2.1/net.fabricmc/tiny-remapper/0.11.1/a3eb511096a6f9af615809f03c3569a1a56c381/tiny-remapper-0.11.1.jar'
$mappings = Join-Path $workspace 'work/logistics-sandbox/gradle-cache/caches/fabric-loom/1.21.1/loom.mappings.1_21_1.layered+hash.729439609-v2/mappings.tiny'
$dependencyCache = Join-Path $workspace 'work/logistics-sandbox/gradle-cache/caches/modules-2/files-2.1'
$remapperLibraries = @($tinyRemapper)
foreach ($coordinate in @('org.ow2.asm/asm/9.7.1', 'org.ow2.asm/asm-commons/9.7.1', 'org.ow2.asm/asm-tree/9.7.1', 'org.ow2.asm/asm-util/9.7.1', 'org.ow2.asm/asm-analysis/9.7.1', 'net.fabricmc/mapping-io/0.7.1')) {
	$library = Get-ChildItem (Join-Path $dependencyCache $coordinate) -Recurse -File -Filter *.jar | Select-Object -First 1
	if ($null -eq $library) { throw "Missing Tiny Remapper dependency: $coordinate" }
	$remapperLibraries += $library.FullName
}
$remapperClasspath = $remapperLibraries -join ';'
$remapArguments = @('-classpath', $remapperClasspath, 'net.fabricmc.tinyremapper.Main', $namedJar, $remappedDirectory, $mappings, 'named', 'intermediary') + $classpath
$remapArgFile = Join-Path $root 'tiny-remapper.args'
$escapedRemapArguments = $remapArguments | ForEach-Object { '"' + $_.Replace('\', '/').Replace('"', '\"') + '"' }
[IO.File]::WriteAllLines($remapArgFile, $escapedRemapArguments, [Text.UTF8Encoding]::new($false))
& "$javaRoot/java.exe" "@$remapArgFile"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $remappedDirectory)) { throw 'Tiny Remapper failed.' }
Push-Location $remappedDirectory
try { & "$javaRoot/jar.exe" --create --file $remappedJar . }
finally { Pop-Location }
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $remappedJar)) { throw 'Failed to archive remapped classes.' }

Copy-Item -LiteralPath $baseJar -Destination $outputJar
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$outputZip = [IO.Compression.ZipFile]::Open($outputJar, [IO.Compression.ZipArchiveMode]::Update)
try {
	$overlayZip = [IO.Compression.ZipFile]::OpenRead($remappedJar)
	try {
		foreach ($entry in $overlayZip.Entries) {
			if ($entry.FullName -eq 'META-INF/MANIFEST.MF' -or $entry.FullName.EndsWith('/')) { continue }
			$existing = $outputZip.GetEntry($entry.FullName)
			if ($null -ne $existing) { $existing.Delete() }
			$target = $outputZip.CreateEntry($entry.FullName, [IO.Compression.CompressionLevel]::Optimal)
			$inputStream = $entry.Open(); $outputStream = $target.Open()
			try { $inputStream.CopyTo($outputStream) }
			finally { $inputStream.Dispose(); $outputStream.Dispose() }
		}
	} finally { $overlayZip.Dispose() }

	$resourceRoots = @(
		@{ Path = (Join-Path $projectRoot 'full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/resources'); Data = $false },
		@{ Path = (Join-Path $projectRoot 'full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/generated/resources'); Data = $false },
		@{ Path = (Join-Path $projectRoot 'source/fabric/src/main/resources'); Data = $true },
		# Reviewed Fabric adaptations must win over the official NeoForge data
		# files when both provide the same recipe or tag path.
		@{ Path = (Join-Path $root 'source/fabric/src/main/resources'); Data = $true }
	)
	$nativeDataPattern = '^data/create/(?:tags/(?:block|item)/(?:postboxes|pulpifiable)|recipe/(?:mixing/cardboard_pulp|pressing/cardboard|item_application/bound_cardboard_inworld|crafting/(?:kinetics/(?:chain_conveyor|package_filter)|appliances/(?:package_filter_clear|cardboard_(?:boots|chestplate|helmet|leggings|sword))|materials/(?:transmitter|cardboard(?:_from_(?:block|bound_block)|_block)?|bound_cardboard_block)|logistics/(?:packager|package_frogport|stock_link|stock_ticker|redstone_requester|factory_gauge|repackager_from_conversion|item_hatch|(?:black|blue|brown|cyan|gray|green|light_blue|light_gray|lime|magenta|orange|pink|purple|red|white|yellow)_postbox(?:_from_other_postbox)?)))|advancement/(?:cardboard(?:_armor(?:_trim)?)?|recipes/misc/crafting/(?:materials/(?:transmitter|cardboard(?:_from_(?:block|bound_block)|_block)?|bound_cardboard_block)|appliances/cardboard_(?:boots|chestplate|helmet|leggings|sword)))|loot_table/blocks/(?:packager|repackager|package_frogport|chain_conveyor|stock_link|stock_ticker|redstone_requester|factory_gauge|item_hatch))\.json$'
	foreach ($resourceSpec in $resourceRoots) {
		$resourceRoot = $resourceSpec.Path
		if (-not (Test-Path $resourceRoot)) { continue }
		foreach ($file in Get-ChildItem -LiteralPath $resourceRoot -Recurse -File) {
			$relative = [IO.Path]::GetRelativePath($resourceRoot, $file.FullName).Replace('\', '/')
			if ($relative -ne 'create.mixins.json' -and $relative -notmatch '^assets/create/' -and -not ($resourceSpec.Data -and $relative -match '^data/create/') -and $relative -notmatch $nativeDataPattern) { continue }
			$existing = $outputZip.GetEntry($relative)
			if ($null -ne $existing) { $existing.Delete() }
			[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($outputZip, $file.FullName, $relative, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
		}
	}

	# Create 6's TrainHUD delegates its direction marker to the pinned Ponder
	# placement renderer. Repackage that exact upstream sheet in Create's GUI
	# namespace because this Fabric baseline retains Create's local texture enum.
	$ponderIndicator = Join-Path $projectRoot 'ponder-upstream/common/src/main/resources/assets/ponder/textures/gui/placement_indicator.png'
	if (-not (Test-Path -LiteralPath $ponderIndicator)) { throw 'Pinned Ponder placement indicator is missing.' }
	$indicatorTarget = 'assets/create/textures/gui/placement_indicator.png'
	$existingIndicator = $outputZip.GetEntry($indicatorTarget)
	if ($null -ne $existingIndicator) { $existingIndicator.Delete() }
	[IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
		$outputZip, $ponderIndicator, $indicatorTarget, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
} finally { $outputZip.Dispose() }

$hash = (Get-FileHash $outputJar -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "ASSEMBLED: $outputJar"
Write-Output "SHA256: $hash"
