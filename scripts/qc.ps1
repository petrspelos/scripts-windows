#Requires -Version 7.0
param([string]$Key)

$ErrorActionPreference = 'Stop'
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
if ($directory.Contains('"') -or -not [IO.Path]::IsPathFullyQualified($directory) -or
    -not (Test-Path -LiteralPath $directory -PathType Container)) {
    throw "$variableName must be an existing absolute directory path without surrounding quotes: $directory"
}
Set-Location -LiteralPath $directory
