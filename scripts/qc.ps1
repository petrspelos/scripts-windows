#Requires -Version 7.0
param([string]$Key)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/helper-configuration.ps1"
if (-not $Key) {
    Get-ChildItem Env: | Where-Object Name -Like 'quickcd_*' |
        Sort-Object Name | ForEach-Object { '{0}: {1}' -f $_.Name.Substring(8), $_.Value }
    return
}

$variableName = "quickcd_$Key"
$directory = [Environment]::GetEnvironmentVariable($variableName, 'Process')
if (-not $directory) {
    throw "Unknown directory shortcut '$Key'. Set $variableName to an absolute directory path without surrounding quotes."
}
try {
    $directory = Get-ConfiguredDirectory -Name $variableName
} catch {
    throw "$variableName must be an existing absolute directory path without surrounding quotes. $($_.Exception.Message)"
}
Set-Location -LiteralPath $directory
