$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$project=Split-Path $root
$donor="$project/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb"
$java='src/main/java/com/simibubi/create'
$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Pin($rel,$t,$reason) {
 $p="$root/source/fabric/$java/$rel";New-Item -ItemType Directory (Split-Path $p) -Force|Out-Null
 [IO.File]::WriteAllText($p,$t)
 $script:manifest.files=@($script:manifest.files|Where-Object path -ne $rel)+[pscustomobject]@{path=$rel;verificationPath="source/fabric/$java/$rel";verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant();status=$reason}
 $arg='"'+$p.Replace('\','/')+'"';$ap="$root/integration-compile.args"
 if(-not ([IO.File]::ReadAllText($ap).Contains($arg))){[IO.File]::AppendAllText($ap,"`r`n$arg`r`n")}
}
$dir="$donor/$java/infrastructure/ponder/scenes/highLogistics"
foreach($f in Get-ChildItem $dir -Filter *.java) {
 $t=[IO.File]::ReadAllText($f.FullName)
 $t=$t.Replace('import com.simibubi.create.foundation.ponder.CreateSceneBuilder;','')
 $t=$t.Replace('CreateSceneBuilder scene = new CreateSceneBuilder(builder);','SceneBuilder scene = builder;')
 $t=$t.Replace('CreateSceneBuilder','SceneBuilder')
 $t=$t.Replace('net.createmod.ponder.api.scene.','com.simibubi.create.foundation.ponder.')
 $t=$t.Replace('net.createmod.ponder.api.PonderPalette','com.simibubi.create.foundation.ponder.PonderPalette')
 $t=$t.Replace('net.createmod.ponder.api.element.ElementLink','com.simibubi.create.foundation.ponder.ElementLink')
 $t=$t.Replace('net.createmod.ponder.api.element.ParrotPose','com.simibubi.create.foundation.ponder.element.ParrotElement')
 $t=$t.Replace('net.createmod.ponder.api.element.','com.simibubi.create.foundation.ponder.element.')
 $t=$t.Replace('net.createmod.ponder.api.level.PonderLevel','com.simibubi.create.foundation.ponder.PonderWorld')
 $t=$t.Replace('PonderLevel','PonderWorld')
 $t=$t.Replace('net.createmod.ponder.foundation.element.ElementLinkImpl','com.simibubi.create.foundation.ponder.ElementLink')
 $t=$t.Replace('net.createmod.ponder.foundation.element.ParrotElementImpl','com.simibubi.create.foundation.ponder.element.ParrotElement')
 $t=$t.Replace('net.createmod.ponder.foundation.instruction.','com.simibubi.create.foundation.ponder.instruction.')
 $t=$t.Replace('ElementLinkImpl','ElementLink').Replace('ParrotElementImpl','ParrotElement')
 $t=$t.Replace('net.createmod.catnip.math.','com.simibubi.create.foundation.utility.')
 $t=$t.Replace('net.createmod.catnip.nbt.','com.simibubi.create.foundation.utility.')
 foreach($field in @('world','overlay','effects','special','debug')){$t=$t.Replace("scene.$field()","scene.$field")}
 foreach($field in @('select','grid','vector')){$t=$t.Replace("util.$field()","util.$field")}
 # PonderHilo only used the extended scene builder in its parameter types.
 if($f.Name -eq 'PonderHilo.java'){$t=$t.Replace('package com.simibubi.create.infrastructure.ponder.scenes.highLogistics;','package com.simibubi.create.infrastructure.ponder.scenes.highLogistics;'+"`n"+'import com.simibubi.create.foundation.ponder.SceneBuilder;')}
 Pin "infrastructure/ponder/scenes/highLogistics/$($f.Name)" $t 'Official Create 6.0.10 logistics Ponder script; only Ponder namespace and instruction-facade API adapted to retained Fabric Ponder engine.'
}
$rel='foundation/ponder/SceneBuilder.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/$java/$rel")
$anchor="`t`tpublic void showControls(InputWindowElement element, int duration) {"
$overload=@'
        public InputWindowElement showControls(Vec3 position, com.simibubi.create.foundation.utility.Pointing pointing, int duration) {
            InputWindowElement element = new InputWindowElement(position, pointing);
            addInstruction(new ShowInputInstruction(element, duration));
            return element;
        }

'@
if(-not $t.Contains($anchor)){throw 'Ponder controls anchor absent'}
Pin $rel ($t.Replace($anchor,$overload+$anchor)) 'Bridge official fluent controls instruction creation to baseline ShowInputInstruction; existing overload and scenes unchanged.'
$rel='infrastructure/ponder/PonderIndex.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/$java/$rel")
$native=[IO.File]::ReadAllText("$donor/$java/infrastructure/ponder/AllCreatePonderScenes.java")
$start=$native.IndexOf("`t`t// Hilo");$end=$native.IndexOf("`t`t// Trains",$start)
$t=$t.Replace('public static void register() {',"public static void register() {`n"+$native.Substring($start,$end-$start))
$t=$t.Replace('import com.simibubi.create.AllBlocks;','import com.simibubi.create.AllBlocks;'+"`n"+'import com.simibubi.create.infrastructure.ponder.scenes.highLogistics.*;')
Pin $rel $t 'Exact official logistics storyboard registrations appended without changing existing Ponder registrations.'
($manifest.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
