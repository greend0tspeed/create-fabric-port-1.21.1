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
$rel='content/schematics/client/SchematicHandler.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$old="`t`tboolean present = activeSchematicItem != null;`r`n`t`tif (!active && !present)"
$new="`t`tif (!active)`r`n`t`t`treturn;`r`n`t`tboolean present = activeSchematicItem != null;`r`n`t`tif (!present)"
if(-not $t.Contains($old)){throw 'Preview guard anchor missing'}
Pin $rel ($t.Replace($old,$new)) 'Official Create active/present render guards restored; retain baseline Fabric schematic component and world renderer adapters.'
$rel='content/schematics/cannon/SchematicannonMenu.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$old='addSlot(new SlotItemHandler(contentHolder.inventory, 4, x + 15, y + 19));'
$new=@'
addSlot(new SlotItemHandler(contentHolder.inventory, 4, x + 15, y + 19) {
            @Override
            public int getMaxStackSize(ItemStack stack) {
                return Math.min(stack.getMaxStackSize(), contentHolder.inventory.getSlotLimit(4));
            }

            @Override
            public int getMaxStackSize() {
                return Math.min(net.minecraft.world.item.Items.GUNPOWDER.getDefaultMaxStackSize(), contentHolder.inventory.getSlotLimit(4));
            }
        });
'@
if(-not $t.Contains($old)){throw 'Fuel slot anchor missing'}
$t=$t.Replace($old,$new).Replace('moveItemStackTo(stack, 5, slots.size(), false);','moveItemStackTo(stack, 5, slots.size(), true);')
Pin $rel $t 'Official menu reverse player-inventory shift routing and NeoForge SlotItemHandler item/slot capacity semantics adapted specifically to Fabric cannon fuel slot.'
$rel='content/schematics/cannon/SchematicannonScreen.java'
$t=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
$t=$t.Replace('y + 86, AllIcons.', 'y + 85, AllIcons.').Replace('x + 180, y + 117','x + 180, y + 111').Replace('x + 9, y + 117','x + 8, y + 111').Replace('x + 33 + i * 18, y + 117','x + 33 + i * 18, y + 111').Replace('x + 111, y + 117','x + 111, y + 111').Replace('x + 129, y + 117','x + 135, y + 111')
$t=$t.Replace('graphics.drawCenteredString(font, title, x + (BG_TOP.width - 8) / 2, y + 3, 0xFFFFFF);','graphics.drawString(font, title, x + (BG_TOP.width - 8 - font.width(title)) / 2, y + 2, 0x505050, false);')
Pin $rel $t 'Official Create cannon control positions and title placement ported; firing/fuel-consumption logic unchanged.'
($m.verifiedSources|Where-Object path -eq 'integration-compile.args').sha256=(Get-FileHash "$root/integration-compile.args").Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
