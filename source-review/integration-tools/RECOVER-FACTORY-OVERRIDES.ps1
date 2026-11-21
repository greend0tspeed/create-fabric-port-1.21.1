$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot;$manifest=Get-Content "$root/port-changes.json" -Raw|ConvertFrom-Json
$path='content/logistics/factoryBoard/FactoryPanelBehaviour.java';$entry=$manifest.files|Where-Object path -EQ $path
$entry.changes=@($entry.changes|Where-Object {$_.from -cne "`t@Override`n`tpublic " -or $_.to -cne "`tpublic "})
$relative="src/main/java/com/simibubi/create/$path";$expected=[IO.File]::ReadAllText("$root/$($entry.sourceRoot)/$relative")
foreach($change in $entry.changes){$expected=$expected.Replace($change.from,$change.to)}
[IO.File]::WriteAllText("$root/source/fabric/$relative",$expected,[Text.UTF8Encoding]::new($false))
$manifest|ConvertTo-Json -Depth 30|Set-Content "$root/port-changes.json"
