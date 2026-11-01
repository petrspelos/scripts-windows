#Requires -Version 7.0
param()

$ErrorActionPreference = 'Stop'
$copyVariables = @(
    'AMNESIA_TCP_RELEASE_DIR', 'AMNESIA_MP_CLIENT_DIR', 'AMNESIA_MP_RESOURCES_DIR',
    'AMNESIA_STAGING_DIR', 'AMNESIA_GAME_DIR'
)
$shortcutVariables = @(Get-ChildItem Env: | Where-Object Name -Like 'quickcd_*' |
    Sort-Object Name | Select-Object -ExpandProperty Name)
foreach ($variableName in ($copyVariables + $shortcutVariables)) {
    $directory = [Environment]::GetEnvironmentVariable($variableName, 'Process')
    $isOutput = $variableName -in @('AMNESIA_STAGING_DIR', 'AMNESIA_GAME_DIR')
    if (-not $directory) {
        "${variableName}: missing; set an absolute directory path without surrounding quotes."
    } elseif ($directory.Contains('"') -or -not [IO.Path]::IsPathFullyQualified($directory)) {
        "${variableName}: invalid; use an absolute directory path without surrounding quotes."
    } elseif (Test-Path -LiteralPath $directory -PathType Container) {
        "${variableName}: ready ($directory)"
    } elseif ($isOutput -and -not (Test-Path -LiteralPath $directory)) {
        "${variableName}: configured output; directory will be created ($directory)"
    } else {
        "${variableName}: invalid; directory does not exist ($directory)"
    }
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
