#Requires -Version 7.0
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/helper-configuration.ps1"
$variables = Get-AmnesiaVariables
$shortcutVariables = @(Get-ChildItem Env: | Where-Object Name -Like 'quickcd_*' |
    Sort-Object Name | Select-Object -ExpandProperty Name)
foreach ($variable in $variables.Values) {
    Get-DirectoryConfigurationStatus -Name $variable.Name -AllowMissing:$variable.IsOutput
}
foreach ($variableName in $shortcutVariables) {
    Get-DirectoryConfigurationStatus -Name $variableName
}
if (-not $shortcutVariables.Count) { 'No directory shortcuts configured. Set quickcd_<key> to an existing absolute directory.' }
$expectedCommand = Join-Path $PSScriptRoot 'qc.ps1'
$resolvedCommand = Get-Command qc -ErrorAction SilentlyContinue
if ($resolvedCommand -and $resolvedCommand.CommandType -eq 'ExternalScript' -and
    $resolvedCommand.Path -eq $expectedCommand) {
    'qc resolves to this repository.'
} elseif ($resolvedCommand) {
    "qc command collision: $($resolvedCommand.CommandType) $($resolvedCommand.Definition). Expected $expectedCommand. Adjust PATH or remove the conflicting command yourself."
} else {
    "qc is not on PATH. Add $PSScriptRoot to your user PATH."
}
'Configuration is read from the current process environment. Set persistent variables and PATH manually; then open a new terminal.'
"Example: [Environment]::SetEnvironmentVariable('quickcd_work', 'C:\work', 'User')"
