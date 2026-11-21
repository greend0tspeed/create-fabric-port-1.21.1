$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$project=Split-Path $root
$donor="$project/full-official-donor/Create-ac0c444d9828da3453ae8cc65338e8de063286fb/src/main/java/com/simibubi/create"
$m=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$rel='content/schematics/cannon/SchematicannonScreen.java'
$t=[IO.File]::ReadAllText("$donor/$rel")
$baseline=[IO.File]::ReadAllText("$project/source/fabric/src/main/java/com/simibubi/create/$rel")
# Keep the exact existing fuel tooltip formula; the retained cannon backend uses
# fractional fuel rather than upstream's integer remainingFuel field.
$start=$baseline.IndexOf('protected List<Component> getFuelLevelTooltip(')
$end=$baseline.IndexOf('protected void sendOptionUpdate(', $start)
$fuelTooltip=$baseline.Substring($start,$end-$start)
$start=$t.IndexOf('protected List<Component> getFuelLevelTooltip(')
$end=$t.IndexOf('protected void sendOptionUpdate(', $start)
$t=$t.Substring(0,$start)+$fuelTooltip+$t.Substring($end)
$t=$t.Replace('import net.createmod.catnip.platform.CatnipServices;', 'import com.simibubi.create.AllPackets;')
$t=$t.Replace('com.simibubi.create.foundation.utility.CreateLang','com.simibubi.create.foundation.utility.Lang').Replace('CreateLang.','Lang.')
$t=$t.Replace('net.createmod.catnip.gui.element.GuiGameElement','com.simibubi.create.foundation.gui.element.GuiGameElement')
$t=$t.Replace('net.createmod.catnip.lang.FontHelper.Palette','com.simibubi.create.foundation.item.TooltipHelper.Palette')
$t=$t.Replace('import net.minecraft.ChatFormatting;',"import net.minecraft.ChatFormatting;`r`nimport com.simibubi.create.foundation.utility.Components;")
$t=$t.Replace('CatnipServices.NETWORK.sendToServer(', 'AllPackets.getChannel().sendToServer(')
$t=$t.Replace('float amount = be.remainingFuel / (float) be.getShotsPerGunpowder();','float amount = be.fuelLevel;')
# Use the official button implementation within this screen, preserving other
# already-tested screens that use the older baseline IconButton class.
$t=$t.Replace('IconButton','CannonIconButton').Replace('import com.simibubi.create.foundation.gui.widget.CannonIconButton;', '')
$button=@'
    private static class CannonIconButton extends com.simibubi.create.foundation.gui.widget.IconButton {
        public boolean green;
        public CannonIconButton(int x, int y, com.simibubi.create.foundation.gui.element.ScreenElement icon) {
            super(x, y, icon);
        }
        @Override
        public void doRender(GuiGraphics graphics, int mouseX, int mouseY, float partialTicks) {
            if (visible) {
                isHovered = mouseX >= getX() && mouseY >= getY() && mouseX < getX() + width && mouseY < getY() + height;
                AllGuiTextures button = !active ? AllGuiTextures.BUTTON_DISABLED
                    : isHovered && com.simibubi.create.AllKeys.isMouseButtonDown(0) ? AllGuiTextures.BUTTON_DOWN
                    : isHovered ? AllGuiTextures.BUTTON_HOVER
                    : green ? AllGuiTextures.BUTTON_GREEN : AllGuiTextures.BUTTON;
                com.mojang.blaze3d.systems.RenderSystem.setShaderColor(1.0F, 1.0F, 1.0F, 1.0F);
                drawBg(graphics, button);
                icon.render(graphics, getX() + 1, getY() + 1);
            }
        }
    }
'@
$end=$t.LastIndexOf('}')
$t=$t.Substring(0,$end)+$button+"`r`n}"+$t.Substring($end+1)
$p="$root/source/fabric/src/main/java/com/simibubi/create/$rel"
[IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false))
$entry=$m.files|Where-Object path -eq $rel
$entry.verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant()
$entry.status='Full official Create 6 cannon screen port; official green-button rendering scoped to cannon; baseline fractional fuel formula and Fabric networking APIs retained.'
$p="$root/source/fabric/src/main/java/com/simibubi/create/foundation/gui/AllGuiTextures.java"
$t=[IO.File]::ReadAllText($p)
if(-not $t.Contains('SCHEMATIC_TITLE(')){$t=$t.Replace('SCHEMATIC_PROMPT(', 'SCHEMATIC_TITLE("schematics_2", 205, 15), SCHEMATIC_PROMPT(')}
[IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false))
($m.files|Where-Object path -eq 'foundation/gui/AllGuiTextures.java').verificationSha256=(Get-FileHash $p).Hash.ToLowerInvariant()
$m|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json" -Encoding utf8
