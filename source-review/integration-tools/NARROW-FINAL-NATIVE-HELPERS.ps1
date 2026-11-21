$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path $root
$manifestPath = Join-Path $root 'port-changes.json'
$lockPath = Join-Path $root 'baseline-reference-lock.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json

function Add-BaselineOverride([string] $relative, [object[]] $changes, [string] $status) {
	$sourceRelative = "src/main/java/com/simibubi/create/$relative"
	$baseline = Join-Path $workspaceRoot "source/fabric/$sourceRelative"
	$reference = Join-Path $root "baseline-reference/$sourceRelative"
	$destination = Join-Path $root "source/fabric/$sourceRelative"
	[IO.Directory]::CreateDirectory((Split-Path -Parent $reference)) | Out-Null
	[IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
	if (-not (Test-Path $reference)) {
		[IO.File]::WriteAllText($reference, [IO.File]::ReadAllText($baseline), [Text.UTF8Encoding]::new($false))
	}
	$text = [IO.File]::ReadAllText($reference)
	$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
	foreach ($change in $changes) {
		$change.from = $change.from.Replace("`n", $newline)
		$change.to = $change.to.Replace("`n", $newline)
		if (-not $text.Contains($change.from)) { throw "Missing helper anchor in $relative" }
		$text = $text.Replace($change.from, $change.to)
	}
	[IO.File]::WriteAllText($destination, $text, [Text.UTF8Encoding]::new($false))
	if (-not ($lock.files | Where-Object path -eq $sourceRelative)) {
		$bytes = [IO.File]::ReadAllBytes($reference)
		$prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
		$data = New-Object byte[] ($prefix.Length + $bytes.Length)
		[Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
		[Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
		$sha = [Security.Cryptography.SHA1]::Create()
		try { $blob = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
		finally { $sha.Dispose() }
		$lock.files = @($lock.files) + [pscustomobject]@{ gitBlob = $blob; path = $sourceRelative }
	}
	$entry = $manifest.files | Where-Object path -eq $relative
	if ($null -eq $entry) {
		$manifest.files = @($manifest.files) + [pscustomobject]@{ path = $relative; sourceRoot = 'baseline-reference'; changes = $changes; status = $status }
	} else {
		$entry.sourceRoot = 'baseline-reference'
		$entry.changes = $changes
		$entry.status = $status
	}
}

Add-BaselineOverride 'foundation/model/BakedQuadHelper.java' @(
	[pscustomobject]@{ from = "import net.minecraft.client.renderer.block.model.BakedQuad;"; to = "import net.minecraft.client.renderer.block.model.BakedQuad;`nimport net.minecraft.util.Mth;" },
	[pscustomobject]@{ from = "`tpublic static float getU(int[] vertexData, int vertex) {"; to = "`tpublic static Vec3 getNormalXYZ(int[] vertexData, int vertex) {`n`t`tint data = vertexData[vertex * VERTEX_STRIDE + NORMAL_OFFSET];`n`t`tfloat x = (byte) (data >> 24 & 0xFF) / 127f;`n`t`tfloat y = (byte) (data >> 16 & 0xFF) / 127f;`n`t`tfloat z = (byte) (data >> 8 & 0xFF) / 127f;`n`t`treturn new Vec3(x, y, z);`n`t}`n`n`tpublic static void setNormalXYZ(int[] vertexData, int vertex, Vec3 xyz) {`n`t`tint x = Byte.toUnsignedInt((byte) (Mth.clamp(xyz.x, -1.0f, 1.0f) * 127));`n`t`tint y = Byte.toUnsignedInt((byte) (Mth.clamp(xyz.y, -1.0f, 1.0f) * 127));`n`t`tint z = Byte.toUnsignedInt((byte) (Mth.clamp(xyz.z, -1.0f, 1.0f) * 127));`n`t`tint data = (x << 24) | (y << 16) | (z << 8);`n`t`tvertexData[vertex * VERTEX_STRIDE + NORMAL_OFFSET] = data;`n`t}`n`n`tpublic static float getU(int[] vertexData, int vertex) {" }
) 'Pinned Create normal-vector helpers restored without replacing the compatible renderer utility.'

Add-BaselineOverride 'content/kinetics/motor/CreativeMotorBlockEntity.java' @(
	[pscustomobject]@{ from = "`tprotected ScrollValueBehaviour generatedSpeed;"; to = "`tpublic ScrollValueBehaviour generatedSpeed;" }
) 'Pinned Create Creative Motor behaviour exposed to its native ComputerCraft peripheral.'

Add-BaselineOverride 'content/trains/observer/TrackObserverBlockEntity.java' @(
	[pscustomobject]@{ from = "import java.util.List;"; to = "import java.util.List;`nimport java.util.UUID;" },
	[pscustomobject]@{ from = "`tprivate FilteringBehaviour filtering;"; to = "`tprivate FilteringBehaviour filtering;`n`n`tpublic UUID passingTrainUUID;" }
) 'Pinned Create observer train identity state restored for its native peripheral queries.'

$blueprintChanges = @(
	[pscustomobject]@{ from = "import com.simibubi.create.content.logistics.filter.AttributeFilterMenu.WhitelistMode;"; to = "import com.simibubi.create.content.logistics.BigItemStack;`nimport com.simibubi.create.content.logistics.filter.AttributeFilterMenu.WhitelistMode;`nimport com.simibubi.create.content.logistics.packager.InventorySummary;`nimport com.simibubi.create.content.logistics.tableCloth.ShoppingListItem.ShoppingList;`nimport com.simibubi.create.content.logistics.tableCloth.TableClothBlockEntity;" },
	[pscustomobject]@{ from = "import com.simibubi.create.foundation.utility.AnimationTickHolder;"; to = "import com.simibubi.create.foundation.utility.AnimationTickHolder;`nimport com.simibubi.create.foundation.utility.Couple;" },
	[pscustomobject]@{ from = "`tpublic static void rebuild(BlueprintSection sectionAt, boolean sneak) {"; to = "`tpublic static void displayChainRequirements(Item chainItem, int count, boolean fulfilled) {`n`t`tif (active)`n`t`t`treturn;`n`t`tactive = true;`n`t`tempty = false;`n`t`tnoOutput = true;`n`t`tingredients.clear();`n`t`tint chains = count;`n`t`twhile (chains > 0) {`n`t`t`tingredients.add(Pair.of(new ItemStack(chainItem, Math.min(64, chains)), fulfilled));`n`t`t`tchains -= 64;`n`t`t}`n`t}`n`n`tpublic static void displayClothShop(TableClothBlockEntity dce, int alreadyPurchased, ShoppingList list) {`n`t`tif (active)`n`t`t`treturn;`n`t`tactive = true;`n`t`tempty = false;`n`t`tnoOutput = false;`n`t`tingredients.clear();`n`t`tingredients.add(Pair.of(dce.getPaymentItem().copyWithCount(dce.getPaymentAmount()),`n`t`t`t!dce.getPaymentItem().isEmpty() && dce.getStockLevelForTrade(list) > alreadyPurchased));`n`t`tresult = ItemStack.EMPTY;`n`t`tfor (BigItemStack entry : dce.requestData.encodedRequest().stacks()) {`n`t`t`tresult = entry.stack.copyWithCount(entry.count);`n`t`t`tbreak;`n`t`t}`n`t}`n`n`tpublic static void displayShoppingList(Couple<InventorySummary> bakedList) {`n`t`tif (active || bakedList == null)`n`t`t`treturn;`n`t`tactive = true;`n`t`tempty = false;`n`t`tnoOutput = false;`n`t`tingredients.clear();`n`t`tfor (BigItemStack entry : bakedList.getSecond().getStacksByCount())`n`t`t`tingredients.add(Pair.of(entry.stack.copyWithCount(entry.count), false));`n`t`tresult = ItemStack.EMPTY;`n`t`tfor (BigItemStack entry : bakedList.getFirst().getStacksByCount()) {`n`t`t`tresult = entry.stack.copyWithCount(entry.count);`n`t`t`tbreak;`n`t`t}`n`t}`n`n`tpublic static void rebuild(BlueprintSection sectionAt, boolean sneak) {" }
)
Add-BaselineOverride 'content/equipment/blueprint/BlueprintOverlayRenderer.java' $blueprintChanges 'Pinned Create shop and shopping-list overlay entry points adapted onto the compatible baseline renderer.'

$computer = $manifest.files | Where-Object path -eq 'compat/computercraft/implementation/ComputerBehaviour.java'
$computer.changes = @()
$computer.status = 'Exact pinned Fabric Creative Motor behaviour access restored.'
$computerPath = Join-Path $root 'source/fabric/src/main/java/com/simibubi/create/compat/computercraft/implementation/ComputerBehaviour.java'
$computerText = [IO.File]::ReadAllText((Join-Path $root 'fabric-reference/src/main/java/com/simibubi/create/compat/computercraft/implementation/ComputerBehaviour.java'))
[IO.File]::WriteAllText($computerPath, $computerText, [Text.UTF8Encoding]::new($false))

$lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
Write-Output 'Narrowed the final native helpers to compatible pinned adaptations.'
