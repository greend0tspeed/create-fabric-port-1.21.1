$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$project=Split-Path $root
$m=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
function Pin($rel,$text,$status) {
 $p="$root/source/fabric/src/main/java/com/simibubi/create/$rel"
 [IO.Directory]::CreateDirectory((Split-Path $p))|Out-Null
 [IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))
 $script:m.files=@($script:m.files|Where-Object path -ne $rel)+[pscustomobject]@{path=$rel;verificationPath="source/fabric/src/main/java/com/simibubi/create/$rel";verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant();status=$status}
 $arg='"'+$p.Replace('\','/')+'"';$ap="$root/integration-compile.args"
 if(-not ([IO.File]::ReadAllText($ap).Contains($arg))){[IO.File]::AppendAllText($ap,"`r`n$arg`r`n")}
}
$rel='content/schematics/client/SchematicAndQuillHandler.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('firstPos.getCenter()', 'Vec3.atLowerCornerOf(firstPos)').Replace('secondPos.getCenter()', 'Vec3.atLowerCornerOf(secondPos)').Replace('selectedPos.getCenter()', 'Vec3.atLowerCornerOf(selectedPos)')
$old=@'
		int x = (int) (vec.getX() * delta);
		int y = (int) (vec.getY() * delta);
		int z = (int) (vec.getZ() * delta);
'@
$new=@'
		int intDelta = (int) (delta > 0 ? Math.ceil(delta) : Math.floor(delta));
		int x = vec.getX() * intDelta;
		int y = vec.getY() * intDelta;
		int z = vec.getZ() * intDelta;
'@
$t=$t.Replace("`r`n","`n")
if(-not $t.Contains($old.Replace("`r`n","`n"))){throw 'Selection scroll anchor missing'}
Pin $rel ($t.Replace($old.Replace("`r`n","`n"),$new)) 'Official Create 6 lower-corner selection AABBs and scroll rounding restored; Fabric export/network adapters retained.'
$rel='foundation/blockEntity/behaviour/ValueBox.java'
$t=[IO.File]::ReadAllText("$root/source/fabric/src/main/java/com/simibubi/create/$rel")
$anchor="`t`t`tif (count == -1 && countLabel == null)"
$insert=@'
            if (countLabel != null) {
                renderOfficialCount(ms, buffer);
                return;
            }
'@
if(-not $t.Contains($anchor)){throw 'Count rendering anchor missing'}
$t=$t.Replace($anchor,$insert+"`r`n"+$anchor)
$anchor="`tpublic static class TextValueBox extends ValueBox {"
# Port the official ItemValueBox.renderContents implementation as the component
# count path; retain baseline integer-count callers unchanged.
$helper=@'
        private void renderOfficialCount(PoseStack ms, MultiBufferSource buffer) {
            Font font = Minecraft.getInstance().font;
            ms.translate(17.5, -5, 7);
            boolean isFilter = stack.getItem() instanceof FilterItem;
            boolean isEmpty = stack.isEmpty();
            ItemRenderer itemRenderer = Minecraft.getInstance().getItemRenderer();
            BakedModel modelWithOverrides = itemRenderer.getModel(stack, null, null, 0);
            boolean blockItem = modelWithOverrides.isGui3d();
            float scale = 1.5f;
            ms.translate(-font.width(countLabel), 0, 0);
            if (isFilter) {
                ms.translate(-5, 8, 0);
            } else if (isEmpty) {
                ms.translate(-15, -1, -2.75);
                scale = 1.65f;
            } else {
                ms.translate(-7, 10, blockItem ? 10 + 1 / 4f : 0);
            }
            if (countLabel.getString().equals("*"))
                ms.translate(-1, 3, 0);
            ms.scale(scale, scale, scale);
            Minecraft.getInstance().font.drawInBatch8xOutline(countLabel.getVisualOrderText(), 0, 0,
                isFilter ? 0xFFFFFF : 0xEDEDED, 0xff333333, ms.last().pose(), buffer, LightTexture.FULL_BRIGHT);
        }

'@
# Insert inside ItemValueBox, immediately before its closing brace.
$boundary="`t}`r`n`r`n"+$anchor
if(-not $t.Contains($boundary)){throw 'ItemValueBox boundary missing'}
$t=$t.Replace($boundary,$helper+"`r`n"+$boundary)
Pin $rel $t 'Official Create 6 outlined component-count rendering ported; baseline integer counts retained.'
($m.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
