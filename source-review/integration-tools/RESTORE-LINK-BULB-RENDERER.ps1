$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$workspaceRoot=Split-Path $root
$relative='src/main/java/com/simibubi/create/content/redstone/displayLink/LinkBulbRenderer.java'
$official=Join-Path $workspaceRoot "full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/$relative"
$ref=Join-Path $root "upstream/$relative"
$src=Join-Path $root "source/fabric/$relative"
[IO.Directory]::CreateDirectory((Split-Path -Parent $ref))|Out-Null
[IO.Directory]::CreateDirectory((Split-Path -Parent $src))|Out-Null
if(-not(Test-Path $ref)){[IO.File]::WriteAllText($ref,[IO.File]::ReadAllText($official),[Text.UTF8Encoding]::new($false))}
$changes=@(
 [pscustomobject]@{from='dev.engine_room.flywheel.lib.transform.TransformStack';to='com.jozufozu.flywheel.util.transform.TransformStack'},
 [pscustomobject]@{from='net.createmod.catnip.render.CachedBuffers';to='com.simibubi.create.foundation.render.CachedBufferer'},
 [pscustomobject]@{from='net.createmod.catnip.math.AngleHelper';to='com.simibubi.create.foundation.utility.AngleHelper'},
 [pscustomobject]@{from='TransformStack.of(ms)';to='TransformStack.cast(ms)'},
 [pscustomobject]@{from='.center()';to='.centre()'},
 [pscustomobject]@{from='.uncenter()';to='.unCentre()'},
 [pscustomobject]@{from='.rotateYDegrees(';to='.rotateY('},
 [pscustomobject]@{from='.rotateXDegrees(';to='.rotateX('},
 [pscustomobject]@{from='CachedBuffers.partial(';to='CachedBufferer.partial('},
 [pscustomobject]@{from='RenderTypes.additive()';to='RenderTypes.getAdditive()'}
)
$text=[IO.File]::ReadAllText($ref)
foreach($c in $changes){if(-not$text.Contains($c.from)){throw "Link bulb adaptation anchor missing: $($c.from)"};$text=$text.Replace($c.from,$c.to)}
[IO.File]::WriteAllText($src,$text,[Text.UTF8Encoding]::new($false))
$lockPath=Join-Path $root 'upstream-lock.json';$lock=Get-Content $lockPath -Raw|ConvertFrom-Json
if(-not($lock.files|Where-Object path -eq $relative)){
 $bytes=[IO.File]::ReadAllBytes($ref);$prefix=[Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0");$data=New-Object byte[]($prefix.Length+$bytes.Length);[Array]::Copy($prefix,0,$data,0,$prefix.Length);[Array]::Copy($bytes,0,$data,$prefix.Length,$bytes.Length);$sha=[Security.Cryptography.SHA1]::Create();try{$blob=[BitConverter]::ToString($sha.ComputeHash($data)).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()};$lock.files=@($lock.files)+[pscustomobject]@{gitBlob=$blob;path=$relative};$lock|ConvertTo-Json -Depth 10|Set-Content $lockPath -Encoding utf8
}
$manifestPath=Join-Path $root 'port-changes.json';$m=Get-Content $manifestPath -Raw|ConvertFrom-Json
if(-not($m.files|Where-Object path -eq 'content/redstone/displayLink/LinkBulbRenderer.java')){$m.files=@($m.files)+[pscustomobject]@{path='content/redstone/displayLink/LinkBulbRenderer.java';changes=$changes;status='Official Create 6 display-link bulb renderer restored and adapted to Fabric Flywheel/render APIs.'};$m|ConvertTo-Json -Depth 20|Set-Content $manifestPath -Encoding utf8}
$argsPath=Join-Path $root 'integration-compile.args';$arg='"'+($src-replace '\\','/')+'"';$args=[IO.File]::ReadAllText($argsPath);if(-not$args.Contains($arg)){[IO.File]::AppendAllText($argsPath,"`r`n$arg`r`n",[Text.UTF8Encoding]::new($false))}
Write-Output 'Restored and adapted the official Link Bulb renderer.'
