param([ValidatePattern('^[a-z0-9-]*$')][string]$Label = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot
& "$projectRoot/NORMALIZE-COMPILE-CLASSPATH.ps1" -Check
$workspace = Split-Path (Split-Path (Split-Path $projectRoot))
$cacheRoot = Join-Path $workspace 'work/logistics-sandbox'
$java = Join-Path $workspace 'work/java21/jdk-21.0.13+9/bin/java.exe'
$javac = Join-Path $workspace 'work/java21/jdk-21.0.13+9/bin/javac.exe'
$suffix = if ($Label) { "-$Label" } else { '' }
$named = Join-Path $PSScriptRoot "packet-codec-named$suffix"
$mapped = Join-Path $PSScriptRoot "packet-codec-mapped$suffix"
$server = Join-Path $PSScriptRoot "server-native-packet-codec$suffix"
New-Item -ItemType Directory $named,$mapped,$server -Force | Out-Null
& "$PSScriptRoot/PREPARE-AUTO-REQUEST-ARGS.ps1"
$arguments = @(Get-Content "$projectRoot/auto-request-compile.args")
$arguments[6] = '"' + $named.Replace('\','/') + '"'
$arguments += '"' + (Join-Path $PSScriptRoot 'NativePacketCodecPreflight.java').Replace('\','/') + '"'
$argfile = Join-Path $PSScriptRoot "packet-codec-test-compile$suffix.args"
[IO.File]::WriteAllLines($argfile,$arguments)
& $javac "@$argfile"
if ($LASTEXITCODE -ne 0) { throw 'Native packet-codec compilation failed' }
$remapClasspath = Join-Path $PSScriptRoot "packet-codec-remap-classpath$suffix.txt"
[IO.File]::WriteAllLines($remapClasspath,$arguments[4].Trim('"').Split(';'))
$jars = @(Get-ChildItem "$cacheRoot/gradle-cache/caches/modules-2/files-2.1/net.fabricmc/tiny-remapper" -Recurse -Filter *.jar
    Get-ChildItem "$cacheRoot/gradle-cache/caches/modules-2/files-2.1/net.fabricmc/mapping-io" -Recurse -Filter *.jar
    Get-ChildItem "$cacheRoot/gradle-cache/caches/modules-2/files-2.1/org.ow2.asm" -Recurse -Filter *.jar)
$cp = $jars.FullName -join ';'
& $java -Xmx2G -cp $cp "$cacheRoot/upstream-port/RemapNamespace.java" "$cacheRoot/gradle-cache/caches/fabric-loom/1.21.1/loom.mappings.1_21_1.layered+hash.729439609-v2/mappings.tiny" $named $mapped $remapClasspath named intermediary
if ($LASTEXITCODE -ne 0) { throw 'PacketCodec remapping failed' }
$oldServer = Join-Path $cacheRoot 'preflight-server-0.3.0'
foreach ($dir in @('libraries','versions','.fabric')) { Copy-Item -LiteralPath "$oldServer/$dir" -Destination $server -Recurse }
Copy-Item -LiteralPath "$oldServer/fabric-server-launch.jar" -Destination $server
New-Item -ItemType Directory "$server/mods","$server/resourcepacks" -Force | Out-Null
Get-ChildItem "$oldServer/mods" -Filter *.jar | Where-Object Name -NotMatch '^(create-|preflight-)' | Copy-Item -Destination "$server/mods"
Copy-Item -LiteralPath (Join-Path $workspace 'work/create6/create-1.21.1-6.0.10-assets.jar') -Destination "$server/resourcepacks/create-1.21.1-6.0.10.jar"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$production = @(Get-ChildItem $mapped -Recurse -Filter *.class | Where-Object FullName -NotMatch 'nativeport[\\/]check')
$replacementNames = @($production | ForEach-Object {$_.FullName.Substring($mapped.Length + 1).Replace('\','/')})
$baseline = Join-Path $workspace 'outputs/native-create6-port/create-reforged-6.0.10-cobblemon-baseline.jar'
$inputZip = [IO.Compression.ZipFile]::OpenRead($baseline)
$outputZip = [IO.Compression.ZipFile]::Open("$server/mods/create-native-packet-codec-test.jar",[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $inputZip.Entries) {
        if ($replacementNames -contains $entry.FullName) { continue }
        $target = $outputZip.CreateEntry($entry.FullName)
        $inputStream = $entry.Open(); $outputStream = $target.Open()
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
    }
    foreach ($file in $production) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($outputZip,$file.FullName,$file.FullName.Substring($mapped.Length + 1).Replace('\','/')) | Out-Null
    }
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($outputZip,"$projectRoot/fabric-reference/LICENSE.md",'LICENSE-native-packet-codec-port.md') | Out-Null
} finally { $inputZip.Dispose(); $outputZip.Dispose() }
$testZip = [IO.Compression.ZipFile]::Open("$server/mods/native-packet-codec-preflight-TEST-ONLY.jar",[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem "$mapped/nativeport/check" -Recurse -Filter *.class) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($testZip,$file.FullName,$file.FullName.Substring($mapped.Length + 1).Replace('\','/')) | Out-Null
    }
    $writer = [IO.StreamWriter]::new($testZip.CreateEntry('fabric.mod.json').Open())
    try { $writer.Write('{"schemaVersion":1,"id":"native_packet_codec_preflight","version":"1.0","environment":"server","entrypoints":{"main":["nativeport.check.NativePacketCodecPreflight"]},"depends":{"create":">=6.0.10","fabric-api":"*"}}') } finally { $writer.Dispose() }
} finally { $testZip.Dispose() }
Write-Output "Prepared isolated TEST ONLY packet-codec runtime: $server"

