$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$workspace=Split-Path (Split-Path (Split-Path $root))
$cache="$workspace/work/logistics-sandbox"
$named="$PSScriptRoot/official-gap-test-named"
$mapped="$PSScriptRoot/official-gap-test-mapped"
$server="$PSScriptRoot/server-official-gap-verification"
New-Item -ItemType Directory $named,$mapped,$server -Force|Out-Null
$argsLines=Get-Content "$root/integration-compile.args"
$cp=$argsLines[[Array]::IndexOf($argsLines,'-classpath')+1].Trim('"')
$cp="$root/compiled;$cp"
$compileArgs=@('-proc:none','-classpath',('"'+$cp.Replace('\','/')+'"'),'-d',('"'+$named.Replace('\','/')+'"'),('"'+("$PSScriptRoot/OfficialGapRuntimeTest.java").Replace('\','/')+'"'))
[IO.File]::WriteAllLines("$PSScriptRoot/official-gap-test-compile.args",$compileArgs)
& "$workspace/work/java21/jdk-21.0.13+9/bin/javac.exe" "@$PSScriptRoot/official-gap-test-compile.args"
if($LASTEXITCODE -ne 0){throw 'Test harness compilation failed'}
[IO.File]::WriteAllLines("$PSScriptRoot/official-gap-test-cp.txt",$cp.Split(';'))
$jars=@(Get-ChildItem "$cache/gradle-cache/caches/modules-2/files-2.1/net.fabricmc/tiny-remapper" -Recurse -Filter *.jar
Get-ChildItem "$cache/gradle-cache/caches/modules-2/files-2.1/net.fabricmc/mapping-io" -Recurse -Filter *.jar
Get-ChildItem "$cache/gradle-cache/caches/modules-2/files-2.1/org.ow2.asm" -Recurse -Filter *.jar)
& "$workspace/work/java21/jdk-21.0.13+9/bin/java.exe" -Xmx2G -cp ($jars.FullName -join ';') "$cache/upstream-port/RemapNamespace.java" "$cache/gradle-cache/caches/fabric-loom/1.21.1/loom.mappings.1_21_1.layered+hash.729439609-v2/mappings.tiny" $named $mapped "$PSScriptRoot/official-gap-test-cp.txt" named intermediary
if($LASTEXITCODE -ne 0){throw 'Test harness remapping failed'}
$oldServer="$PSScriptRoot/server-alpha-smoke"
if(-not(Test-Path "$server/fabric-server-launch.jar")) {
 foreach($dir in @('libraries','versions','.fabric')){Copy-Item "$oldServer/$dir" $server -Recurse}
 Copy-Item "$oldServer/fabric-server-launch.jar" $server
 New-Item -ItemType Directory "$server/mods" -Force|Out-Null
 Get-ChildItem "$oldServer/mods" -Filter *.jar|Where-Object Name -NotMatch '^create-'|Copy-Item -Destination "$server/mods"
 [IO.File]::WriteAllText("$server/eula.txt","eula=true`n")
 [IO.File]::WriteAllText("$server/server.properties","online-mode=false`nserver-ip=127.0.0.1`nserver-port=0`nlevel-name=official-gap-test-world`nlevel-type=minecraft:flat`ngenerate-structures=false`nmax-tick-time=120000`n")
}
Copy-Item "$workspace/outputs/native-create6-port/create-reforged-6.0.10-native-logistics-alpha.jar" "$server/mods/create-reforged-6.0.10-native-logistics-alpha.jar"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$testJar="$server/mods/official-gap-test-TEST-ONLY.jar"
if(Test-Path $testJar){Remove-Item -LiteralPath $testJar}
$zip=[IO.Compression.ZipFile]::Open($testJar,[IO.Compression.ZipArchiveMode]::Create)
try {
 Get-ChildItem $mapped -Recurse -Filter *.class|ForEach-Object{[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$_.FullName,[IO.Path]::GetRelativePath($mapped,$_.FullName).Replace('\','/'))|Out-Null}
 $writer=[IO.StreamWriter]::new($zip.CreateEntry('fabric.mod.json').Open())
 try{$writer.Write('{"schemaVersion":1,"id":"official_gap_test","version":"1.0","environment":"server","entrypoints":{"main":["nativeport.check.OfficialGapRuntimeTest"]},"depends":{"create":"*","fabric-api":"*"}}')}finally{$writer.Dispose()}
}finally{$zip.Dispose()}
Write-Output "Prepared isolated runtime tests: $server"
