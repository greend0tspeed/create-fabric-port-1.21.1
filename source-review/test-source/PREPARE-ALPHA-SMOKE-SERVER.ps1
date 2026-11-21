$ErrorActionPreference = 'Stop'
$integrationRoot = Split-Path $PSScriptRoot
$projectRoot = Split-Path $integrationRoot
$workspace = Split-Path (Split-Path (Split-Path $integrationRoot))
$oldServer = Join-Path $workspace 'work/logistics-sandbox/preflight-server-0.3.0'
$server = Join-Path $PSScriptRoot 'server-alpha-smoke'
$alphaJar = Join-Path $workspace 'outputs/native-create6-port/create-reforged-6.0.10-native-logistics-alpha.jar'

if (Test-Path $server) { throw "Smoke server already exists; refusing to overwrite: $server" }
[IO.Directory]::CreateDirectory($server) | Out-Null
foreach ($directory in @('libraries', 'versions', '.fabric')) {
	Copy-Item -LiteralPath (Join-Path $oldServer $directory) -Destination $server -Recurse
}
Copy-Item -LiteralPath (Join-Path $oldServer 'fabric-server-launch.jar') -Destination $server
[IO.Directory]::CreateDirectory((Join-Path $server 'mods')) | Out-Null
Get-ChildItem (Join-Path $oldServer 'mods') -Filter *.jar |
	Where-Object Name -NotMatch '^(create-|preflight-)' |
	Copy-Item -Destination (Join-Path $server 'mods')
Copy-Item -LiteralPath $alphaJar -Destination (Join-Path $server 'mods')
[IO.File]::WriteAllText((Join-Path $server 'eula.txt'), "eula=true`r`n", [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $server 'server.properties'), "online-mode=false`r`nserver-port=25579`r`nlevel-name=alpha-smoke-world`r`nmax-tick-time=120000`r`n", [Text.UTF8Encoding]::new($false))
Write-Output "Prepared isolated alpha smoke server: $server"
