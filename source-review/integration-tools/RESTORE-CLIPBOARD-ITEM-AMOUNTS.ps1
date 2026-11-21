$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$relative = 'src/main/java/com/simibubi/create/content/equipment/clipboard/ClipboardEntry.java'
$referencePath = Join-Path $root "baseline-reference/$relative"
$sourcePath = Join-Path $root "source/fabric/$relative"

$changes = @(
    [pscustomobject]@{
        from = "`tpublic ItemStack icon;"
        to = "`tpublic ItemStack icon;`n`tpublic int itemAmount;"
    },
    [pscustomobject]@{
        from = "`tpublic ClipboardEntry displayItem(ItemStack icon) {`n`t`tthis.icon = icon;`n`t`treturn this;`n`t}"
        to = "`tpublic ClipboardEntry displayItem(ItemStack icon) {`n`t`treturn displayItem(icon, icon.getCount());`n`t}`n`n`tpublic ClipboardEntry displayItem(ItemStack icon, int amount) {`n`t`tthis.icon = icon;`n`t`tthis.itemAmount = amount;`n`t`treturn this;`n`t}"
    },
    [pscustomobject]@{
        from = "`t`tnbt.put(`"Icon`", NBTSerializer.serializeNBT(icon));`n`t`treturn nbt;"
        to = "`t`tnbt.put(`"Icon`", NBTSerializer.serializeNBT(icon));`n`t`tnbt.putInt(`"ItemAmount`", itemAmount);`n`t`treturn nbt;"
    },
    [pscustomobject]@{
        from = "`t`tif (tag.contains(`"Icon`"))`n`t`t`tclipboardEntry.displayItem(ItemStack.parseOptional(Create.getRegistryAccess(), tag.getCompound(`"Icon`")));"
        to = "`t`tif (tag.contains(`"Icon`"))`n`t`t`tclipboardEntry.displayItem(ItemStack.parseOptional(Create.getRegistryAccess(), tag.getCompound(`"Icon`")),`n`t`t`t`ttag.getInt(`"ItemAmount`"));"
    }
)

$expected = [IO.File]::ReadAllText($referencePath)
foreach ($change in $changes) { $expected = $expected.Replace($change.from, $change.to) }
if ([IO.File]::ReadAllText($sourcePath) -cne $expected) { throw 'ClipboardEntry adaptation does not match its reviewed transformations' }

$lockPath = Join-Path $root 'baseline-reference-lock.json'
$lock = Get-Content $lockPath -Raw | ConvertFrom-Json
if (-not ($lock.files | Where-Object path -eq $relative)) {
    $bytes = [IO.File]::ReadAllBytes($referencePath)
    $prefix = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
    $data = New-Object byte[] ($prefix.Length + $bytes.Length)
    [Array]::Copy($prefix, 0, $data, 0, $prefix.Length)
    [Array]::Copy($bytes, 0, $data, $prefix.Length, $bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try { $blob = [BitConverter]::ToString($sha.ComputeHash($data)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    $lock.files = @($lock.files) + [pscustomobject]@{ gitBlob = $blob; path = $relative }
    $lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath -Encoding utf8
}

$manifestPath = Join-Path $root 'port-changes.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if (-not ($manifest.files | Where-Object path -eq 'content/equipment/clipboard/ClipboardEntry.java')) {
    $manifest.files = @($manifest.files) + [pscustomobject]@{
        path = 'content/equipment/clipboard/ClipboardEntry.java'
        sourceRoot = 'baseline-reference'
        changes = $changes
        status = 'Pinned Create itemAmount field and ItemAmount persistence restored on the existing Minecraft 1.21.1 clipboard component storage; one-argument ABI retained for existing callers.'
    }
    $manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding utf8
}

$argsPath = Join-Path $root 'integration-compile.args'
$argument = '"' + ($sourcePath -replace '\\', '/') + '"'
$argsText = [IO.File]::ReadAllText($argsPath)
if (-not $argsText.Contains($argument)) {
    [IO.File]::AppendAllText($argsPath, "`r`n$argument`r`n", [Text.UTF8Encoding]::new($false))
}

Write-Output 'Registered the provenance-tracked ClipboardEntry item-amount override.'
