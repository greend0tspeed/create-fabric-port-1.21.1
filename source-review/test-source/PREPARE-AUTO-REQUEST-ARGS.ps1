$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$args=[Collections.Generic.List[string]](Get-Content "$root/order-codec-compile.args")
$args[6]='"'+("$PSScriptRoot/auto-request-compiled").Replace('\','/')+'"'
foreach($relative in @(
    'AllTags.java',
    'content/logistics/redstoneRequester/AutoRequestData.java',
    'AllDataComponents.java'
)) {
    $line='"'+("$root/source/fabric/src/main/java/com/simibubi/create/$relative").Replace('\','/')+'"'
    if(!$args.Contains($line)){$args.Add($line)}
}
[IO.File]::WriteAllLines("$root/auto-request-compile.args",$args)
