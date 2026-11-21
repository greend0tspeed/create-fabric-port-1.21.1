$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$workspace=Split-Path (Split-Path (Split-Path $root))
$output="$workspace/outputs/native-create6-port/modrinth-release-prep"
$jar="$workspace/outputs/native-create6-port/create-reforged-6.0.10-native-logistics-alpha.jar"
New-Item -ItemType Directory "$output/audit","$output/licenses" -Force|Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
function ReadEntry($entry) { $reader=[IO.StreamReader]::new($entry.Open());try{$reader.ReadToEnd()}finally{$reader.Dispose()} }
function EntryHash($entry) { $stream=$entry.Open();try{$sha=[Security.Cryptography.SHA256]::Create();[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant()}finally{$stream.Dispose()} }
$components=[Collections.Generic.List[object]]::new()
function AuditZip($zip,$path,$depth) {
 $meta=$null
 if($zip.GetEntry('fabric.mod.json')){$meta=(ReadEntry $zip.GetEntry('fabric.mod.json'))|ConvertFrom-Json}
 $licenseEntries=@($zip.Entries|Where-Object {$_.FullName -match '(?i)(^|/)(LICENSE[^/]*|NOTICE[^/]*|COPYING[^/]*)$' -and -not $_.FullName.EndsWith('/')})
 $id=if($meta){$meta.id}else{[IO.Path]::GetFileNameWithoutExtension($path)}
 $component=[ordered]@{archive=$path;id=$id;version=if($meta){$meta.version}else{$null};declaredLicense=if($meta){$meta.license}else{$null};contact=if($meta){$meta.contact}else{$null};authors=if($meta){$meta.authors}else{$null};licenseFiles=@($licenseEntries|ForEach-Object FullName);licenseTextPresent=($licenseEntries.Count -gt 0);depth=$depth}
 $script:components.Add([pscustomobject]$component)
 foreach($entry in $licenseEntries){$name=($path+'__'+$entry.FullName)-replace '[^a-zA-Z0-9._-]','_';[IO.File]::WriteAllText("$output/licenses/$name",(ReadEntry $entry))}
 foreach($entry in $zip.Entries|Where-Object {$_.FullName -match '^META-INF/(?:jars|jarjar)/.*\.jar$'}){
  $buffer=[IO.MemoryStream]::new();$stream=$entry.Open();try{$stream.CopyTo($buffer)}finally{$stream.Dispose()};$buffer.Position=0
  $nested=[IO.Compression.ZipArchive]::new($buffer,[IO.Compression.ZipArchiveMode]::Read,$true)
  try{AuditZip $nested ($path+'!/'+$entry.FullName) ($depth+1)}finally{$nested.Dispose();$buffer.Dispose()}
 }
}
$zip=[IO.Compression.ZipFile]::OpenRead($jar)
try {
 AuditZip $zip ([IO.Path]::GetFileName($jar)) 0
 $meta=(ReadEntry $zip.GetEntry('fabric.mod.json'))|ConvertFrom-Json
 $meta|ConvertTo-Json -Depth 20|Set-Content "$output/audit/current-fabric.mod.json" -Encoding utf8
 $protectedRoot="$root/../full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/resources"
 $protectedAssets=@()
 foreach($file in Get-ChildItem "$protectedRoot/assets" -Recurse -File){
  $relative=[IO.Path]::GetRelativePath($protectedRoot,$file.FullName).Replace('\','/')
  $entry=$zip.GetEntry($relative)
  if($entry){$protectedAssets+=[pscustomobject]@{path=$relative;jarSha256=(EntryHash $entry);officialSha256=(Get-FileHash $file.FullName).Hash.ToLowerInvariant();license='All Rights Reserved under pinned Create LICENSE.md';permissionEvidence='NOT FOUND IN AUDITED PROJECT FILES'}}
 }
 $protectedAssets|ConvertTo-Json -Depth 6|Set-Content "$output/audit/reserved-assets-present.json" -Encoding utf8
 $suspicious=@($zip.Entries|Where-Object {$_.FullName -match '(^|/)(\.env(?:\..*)?|id_rsa|credentials|token[^/]*\.txt)$|(^|/)(logs|crash-reports|saves)/|nativeport/check/|create_logistics_sandbox' }|ForEach-Object FullName)
 $components|ConvertTo-Json -Depth 12|Set-Content "$output/audit/components.json" -Encoding utf8
 $meta.PSObject.Properties.Remove('contact')
 $meta.PSObject.Properties.Remove('icon')
 $meta.name='Create Fabric Logistics (Unofficial)'
 $meta.version='6.0.10+fabric.1.21.1.compat-alpha.1'
 $meta.description='Unofficial Fabric 1.21.1 compatibility fork with Create 6 logistics. Experimental; not endorsed by upstream projects.'
 $meta.authors=@('Compatibility fork maintainers (identity pending)','Creators of Create (upstream)','Fabricators of Create (Fabric upstream)','sanufsoii (Create Reforged baseline)')
 $meta.license=@('MIT','LicenseRef-Create-Assets-All-Rights-Reserved')
 $meta.depends|Add-Member -NotePropertyName java -NotePropertyValue '>=21' -Force
 $meta|ConvertTo-Json -Depth 20|Set-Content "$output/audit/fabric.mod.json.PROPOSED-NOT-APPLIED" -Encoding utf8
 $report=[ordered]@{
  auditDate='2026-11-20';publicReleaseReady=$false;published=$false;workingJarModified=$false;jar=[IO.Path]::GetFileName($jar);jarSha256=(Get-FileHash $jar).Hash.ToLowerInvariant();
  assetsInCreateNamespace=@($zip.Entries|Where-Object {$_.FullName -match '^assets/create/'}).Count;
  protectedSourceAssetsPresent=$protectedAssets.Count;
  componentCount=$components.Count;componentsWithoutLicenseText=@($components|Where-Object {-not $_.licenseTextPresent}|ForEach-Object archive);suspiciousEntryNames=$suspicious;
  blockers=@('Create reserved-asset redistribution authorization not established','Modrinth AI-fork publication eligibility requires platform determination; substantial Codex-authored adaptations cannot be described as merely spelling checks','Distinct project identity and maintainers source/issue URLs not finalized','Root jar only advertises MIT and omits full current split-license notice','Bundled license texts and exact corresponding-source obligations need resolution','Public matching source and reproducible dependency/build distribution not yet established');
  scope='Artifact metadata, license/provenance files, reserved asset path matching and entry-name scan. Not a malware certification or a legal opinion.';
  alternatives=@('Obtain documented reserved-asset redistribution permission before full-asset release','Evaluate a separately tested code-only artifact using the existing local official-asset loader; do not assume deleting assets preserves every rendering fix');
  policySources=@('https://support.modrinth.com/en/articles/16551575-disclosure-and-usage-of-ai','https://support.modrinth.com/en/articles/16567675-content-disclosures','https://modrinth.com/legal/rules','https://github.com/Creators-of-Create/Create/blob/ac0c444d9828da3453ae8cc65338e8de063286fb/LICENSE.md')
 }
 $report|ConvertTo-Json -Depth 10|Set-Content "$output/audit/release-audit.json" -Encoding utf8
} finally {$zip.Dispose()}
Copy-Item "$root/../full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/LICENSE.md" "$output/licenses/Create-6.0.10-LICENSE.md"
Copy-Item "$root/../full-fabric-donor/Create-4c3fe779d135d592548e4cb09da04d742d2637b7/LICENSE.md" "$output/licenses/Create-Fabric-donor-LICENSE.md"
Copy-Item "$workspace/work/Create-UfoPort/LICENSE" "$output/licenses/Create-UfoPort-LICENSE.txt"
Copy-Item "$root/../ponder-upstream/LICENSE" "$output/licenses/Ponder-LICENSE.txt"
Copy-Item "$root/dependency-reference/catnip/LICENSE" "$output/licenses/Catnip-LICENSE.txt"
Write-Output "Audit saved. Reserved-source assets present: $($report.protectedSourceAssetsPresent). Components: $($report.componentCount). PUBLIC RELEASE NOT CLEARED."
