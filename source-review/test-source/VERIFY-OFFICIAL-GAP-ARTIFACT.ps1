$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$workspace=Split-Path (Split-Path (Split-Path $root))
$output="$workspace/outputs/native-create6-port"
$jar="$output/create-reforged-6.0.10-native-logistics-alpha.jar"
$checkpoint="$output/create-before-official-gap-completion.jar"
$donor="$root/../full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb"
function EntryHash($entry) {
 $stream=$entry.Open()
 try {$sha=[Security.Cryptography.SHA256]::Create();[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant()}
 finally {$stream.Dispose()}
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$old=[IO.Compression.ZipFile]::OpenRead($checkpoint)
$new=[IO.Compression.ZipFile]::OpenRead($jar)
try {
 $protected=@($old.Entries|Where-Object {$_.FullName -match '^com/simibubi/create/content/(trains/|schematics/|logistics/(box/|packager/|packagePort/|factoryBoard/)|kinetics/chainConveyor/)' -and -not $_.FullName.EndsWith('/')})
 foreach($entry in $protected){$other=$new.GetEntry($entry.FullName);if(-not $other -or (EntryHash $entry) -ne (EntryHash $other)){throw "Protected class changed: $($entry.FullName)"}}
 $changes=@()
 foreach($entry in $new.Entries){if($entry.FullName.EndsWith('/')){continue};$other=$old.GetEntry($entry.FullName);if(-not $other -or (EntryHash $entry) -ne (EntryHash $other)){$changes+=$entry.FullName}}
 $assets=@($new.Entries|Where-Object {$_.FullName -match '^assets/create/ponder/high_logistics/.*\.nbt$'})
 foreach($entry in $assets){$source="$donor/src/main/resources/$($entry.FullName)";if(-not(Test-Path $source)){$source="$donor/src/generated/resources/$($entry.FullName)"};if((EntryHash $entry) -ne (Get-FileHash $source).Hash.ToLowerInvariant()){throw "Changed native asset: $($entry.FullName)"}}
 foreach($file in Get-ChildItem "$root/source/fabric/src/main/java/com/simibubi/create/infrastructure/ponder/scenes/highLogistics" -Filter *.java){
  $ported=[IO.File]::ReadAllText($file.FullName)
  $official=[IO.File]::ReadAllText("$donor/src/main/java/com/simibubi/create/infrastructure/ponder/scenes/highLogistics/$($file.Name)")
  foreach($pattern in @('\.text\("(?:[^"\\]|\\.)*"\)','\.idle\([^)]+\)','\.title\([^)]+\)')){
   if((([regex]::Matches($ported,$pattern)|ForEach-Object Value)-join "`n") -cne (([regex]::Matches($official,$pattern)|ForEach-Object Value)-join "`n")){throw "Changed official narration/timing: $($file.Name)"}
  }
 }
 $runtimeLog="$PSScriptRoot/server-official-gap-verification/official-gap-runtime.log"
 $runtime=[IO.File]::ReadAllText($runtimeLog)
 if(-not $runtime.Contains('OFFICIAL_GAP_TEST ALL PASS') -or $runtime.Contains('OFFICIAL_GAP_TEST FAILED')){throw 'Runtime tests did not pass'}
 if((Get-FileHash $jar).Hash -ne (Get-FileHash "$PSScriptRoot/server-official-gap-verification/mods/create-reforged-6.0.10-native-logistics-alpha.jar").Hash){throw 'Runtime tested a different build'}
 if(@($new.Entries|Where-Object {$_.FullName -match 'nativeport/check|OfficialGapRuntimeTest'}).Count){throw 'Test harness leaked into production jar'}
 $report=[ordered]@{
  officialCreate='6.0.10';officialCommit='ac0c444d9828da3453ae8cc65338e8de063286fb';jarSha256=(Get-FileHash $jar).Hash.ToLowerInvariant();checkpointSha256=(Get-FileHash $checkpoint).Hash.ToLowerInvariant();
  added=@('15 official logistics Ponder scenes with native registrations and High Logistics category','Native package-address display source for inventories and chains','Native harvester crop eligibility, state-preserving replant and sugar-cane tag','Optional Farmers Delight rich-soil mushroom exclusion','Native Deployer scoped block-drop capture with try/finally cleanup');
  compatibilityAdapters=@('Existing Ponder facade namespaces, controls overload and protected parrot renderer access','Fabric inventory view and transaction APIs','Pinned intermediary mixin selectors','Client-only harvester renderer methods','Optional mod registry lookup instead of NeoForge mod classes');
  protectedClassesUnchanged=$protected.Count;officialPonderAssetsMatch=$assets.Count;officialPonderTextTitlesAndTiming='Matched in all ten script/helper files';changedEntries=$changes;
  runtime='PASS in isolated Fabric dedicated server with Cobblemon 1.8.2';runtimeChecks=@($runtime -split '\r?\n'|Where-Object {$_ -match 'OFFICIAL_GAP_TEST PASS|OFFICIAL_GAP_TEST ALL PASS'});
  limitations=@('Ponder client playback not visually exercised','Farmers Delight optional case not exercised with the external mod installed','Cobblemon-specific crops not gameplay-tested','Disconnect and passenger-update crash investigations remain separate','Pre-existing cardboard advancement trigger errors still appear in server logs');
  supersedes='Missing-feature findings in remaining-feature-implementation-audit.json; no claim of whole-mod behavioral parity'
 }
 $report|ConvertTo-Json -Depth 8|Set-Content "$output/official-gap-completion.json" -Encoding utf8
 $changes|ConvertTo-Json|Set-Content "$output/official-gap-changed-entries.json" -Encoding utf8
 Copy-Item $runtimeLog "$output/official-gap-runtime-pass.log"
 Write-Output "PASS: runtime checks, $($protected.Count) protected classes, $($assets.Count) official Ponder assets, narration/timing and test-harness exclusion."
} finally {$old.Dispose();$new.Dispose()}
