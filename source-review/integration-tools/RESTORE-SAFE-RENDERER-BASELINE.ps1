$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$workspaceRoot=Split-Path $root
$relative='src/main/java/com/simibubi/create/foundation/blockEntity/renderer/SafeBlockEntityRenderer.java'
$base=Join-Path $workspaceRoot "source/fabric/$relative"
$ref=Join-Path $root "baseline-reference/$relative"
$src=Join-Path $root "source/fabric/$relative"
[IO.Directory]::CreateDirectory((Split-Path -Parent $ref))|Out-Null
[IO.Directory]::CreateDirectory((Split-Path -Parent $src))|Out-Null
if(-not(Test-Path $ref)){[IO.File]::WriteAllText($ref,[IO.File]::ReadAllText($base),[Text.UTF8Encoding]::new($false))}
[IO.File]::WriteAllText($src,[IO.File]::ReadAllText($ref),[Text.UTF8Encoding]::new($false))
$lockPath=Join-Path $root 'baseline-reference-lock.json';$lock=Get-Content $lockPath -Raw|ConvertFrom-Json
if(-not($lock.files|Where-Object path -eq $relative)){$bytes=[IO.File]::ReadAllBytes($ref);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=New-Object byte[]($prefix.Length+$bytes.Length);[Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length);$sha=[Security.Cryptography.SHA1]::Create();try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$lock.files=@($lock.files)+[pscustomobject]@{gitBlob=$blob;path=$relative};$lock|ConvertTo-Json -Depth 10|Set-Content $lockPath -Encoding utf8}
$manifestPath=Join-Path $root 'port-changes.json';$m=Get-Content $manifestPath -Raw|ConvertFrom-Json
if(-not($m.files|Where-Object path -eq 'foundation/blockEntity/renderer/SafeBlockEntityRenderer.java')){$m.files=@($m.files)+[pscustomobject]@{path='foundation/blockEntity/renderer/SafeBlockEntityRenderer.java';sourceRoot='baseline-reference';changes=@();status='Fabric baseline safe renderer included so native Create renderers bind to the 1.21.1 render interface.'};$m|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8}
$argsPath=Join-Path $root 'integration-compile.args';$arg='"'+($src-replace '\\','/')+'"';$args=[IO.File]::ReadAllText($argsPath);if(-not$args.Contains($arg)){[IO.File]::AppendAllText($argsPath,"`r`n$arg`r`n",[Text.UTF8Encoding]::new($false))}
Write-Output 'Included the pinned Fabric baseline SafeBlockEntityRenderer.'
