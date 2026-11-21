$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$workspace=Split-Path (Split-Path $project)
$output="$workspace/outputs/native-create6-port/modrinth-release-prep"
$snapshot="$output/source-review-snapshot.zip"
$manifest=[Collections.Generic.List[object]]::new()
Add-Type -AssemblyName System.IO.Compression.FileSystem
if(Test-Path $snapshot){Remove-Item -LiteralPath $snapshot}
$zip=[IO.Compression.ZipFile]::Open($snapshot,[IO.Compression.ZipArchiveMode]::Create)
function AddReviewFile($path,$entry) {
 [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($script:zip,$path,$entry,[IO.Compression.CompressionLevel]::Optimal)|Out-Null
 $script:manifest.Add([pscustomobject]@{path=$entry;sha256=(Get-FileHash $path).Hash.ToLowerInvariant()})
}
try {
 foreach($spec in @(@{path="$project/source";prefix='baseline-source'},@{path="$root/source";prefix='integration-source'})) {
  $files=& rg --files --hidden $spec.path
  foreach($file in $files){
   $relative=[IO.Path]::GetRelativePath($spec.path,$file).Replace('\','/')
   if($relative -match '(^|/)(assets|build|\.gradle|\.git|logs|saves|crash-reports|node_modules|\.codex|logistics_sandbox)(/|$)'){continue}
   if($relative -notmatch '\.(java|gradle|kts|properties|json|accesswidener)$|(^|/)(LICENSE[^/]*|NOTICE[^/]*|COPYING[^/]*|gradlew|gradlew\.bat)$'){continue}
   AddReviewFile ([IO.Path]::GetFullPath($file)) ($spec.prefix+'/'+$relative)
  }
 }
 foreach($file in Get-ChildItem "$root/tools" -File -Filter *.ps1){AddReviewFile $file.FullName ('integration-tools/'+$file.Name)}
 foreach($file in Get-ChildItem "$root/tests" -File|Where-Object Extension -in @('.java','.ps1')){AddReviewFile $file.FullName ('test-source/'+$file.Name)}
 foreach($name in @('ASSEMBLE-ALPHA.ps1','BUILD.ps1','VERIFY.ps1','NORMALIZE-COMPILE-CLASSPATH.ps1','port-changes.json','module-changes.json','resource-changes.json','upstream-lock.json','fabric-reference-lock.json','baseline-reference-lock.json','dependency-reference-lock.json','baseline-lock.json','archive-provenance.json','compiler-dependencies.json')){AddReviewFile "$root/$name" ('build-and-provenance/'+$name)}
 foreach($file in Get-ChildItem "$output/licenses" -File){AddReviewFile $file.FullName ('licenses/'+$file.Name)}
 AddReviewFile "$output/README.md" 'REVIEW-STATUS.md'
} finally {$zip.Dispose()}
$manifest|ConvertTo-Json -Depth 4|Set-Content "$output/audit/source-review-files.json" -Encoding utf8
$status=[ordered]@{purpose='Source review only; not certified corresponding source or a turnkey public build';files=$manifest.Count;sha256=(Get-FileHash $snapshot).Hash.ToLowerInvariant();excluded=@('All asset directories','Binaries and jar dependencies','Build outputs and caches','Installed profiles, worlds, logs and crash reports','Git history, Codex state and environment files','Machine-specific compiler argument files');limitations=@('Selected overlays compile against a pinned baseline; full source compilation is unverified','Locked donor source copies and full dependency recovery are not all embedded here','Verify corresponding source for each LGPL/MPL binary before publication');baselineSourceCommit='ee22ed23ccbe034ce6644a29a68f5f5e7a7a4e09';officialSourceCommit='ac0c444d9828da3453ae8cc65338e8de063286fb'}
$status|ConvertTo-Json -Depth 5|Set-Content "$output/audit/source-review-status.json" -Encoding utf8
Write-Output "Prepared $($manifest.Count) code/provenance/license files for review; no assets or runtime jar included."
