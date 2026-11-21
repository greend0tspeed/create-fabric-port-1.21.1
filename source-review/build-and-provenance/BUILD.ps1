$ErrorActionPreference='Stop'
$workspace=Split-Path (Split-Path (Split-Path $PSScriptRoot))
& "$PSScriptRoot/NORMALIZE-COMPILE-CLASSPATH.ps1" -Check
$compiledDirectory = Join-Path $PSScriptRoot 'compiled'
$resolvedRoot = [IO.Path]::GetFullPath($PSScriptRoot) + [IO.Path]::DirectorySeparatorChar
$resolvedCompiledDirectory = [IO.Path]::GetFullPath($compiledDirectory)
if (-not $resolvedCompiledDirectory.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Compiler output directory escaped the integration workspace.'
}
if (Test-Path $compiledDirectory) { Remove-Item -LiteralPath $compiledDirectory -Recurse -Force }
New-Item -ItemType Directory -Path $compiledDirectory | Out-Null
$ErrorActionPreference='Continue'
& "$workspace/work/java21/jdk-21.0.13+9/bin/javac.exe" "@$PSScriptRoot/integration-compile.args" *> "$PSScriptRoot/integration-compile.log"
$javacExitCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($javacExitCode -ne 0){
    Get-Content "$PSScriptRoot/integration-compile.log" -Tail 5
    throw 'Native integration compilation failed. No release jar was produced.'
}
Write-Output 'Selected native integration source compiled. Registrations, client/server networking and callbacks still require runtime validation before release.'
