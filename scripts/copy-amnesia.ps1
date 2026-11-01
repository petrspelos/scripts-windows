#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('staging', 'installed-game')][string[]]$Output)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/helper-configuration.ps1"
$variables = Get-AmnesiaVariables
$recipes = [ordered]@{
    staging = @{ Keys = @('Release', 'Client', 'Resources', 'Staging'); Destination = 'Staging'
        Description = 'Amnesia.exe, client .dll/.exe/.json in multimnesia.client, and resources' }
    'installed-game' = @{ Keys = @('Resources', 'Game'); Destination = 'Game'
        Description = 'Resources merged into the installed game' }
}
if (-not $Output) {
    foreach ($option in $recipes.Keys) {
        "${option}: $($recipes[$option].Description)"
        foreach ($key in $recipes[$option].Keys) {
            Get-DirectoryConfigurationStatus -Name $variables[$key].Name -AllowMissing:$variables[$key].IsOutput
        }
    }
    exit 0
}

function Copy-Entry {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source, [string]$Destination)

    $sourceItem = Get-Item -LiteralPath $Source -Force
    # Snapshot the tree before creating output directories.
    $entries = @($sourceItem)
    if ($sourceItem.PSIsContainer) { $entries += @(Get-ChildItem -LiteralPath $Source -Recurse -Force) }
    foreach ($entry in $entries) {
        $target = if ($entry.FullName -eq $sourceItem.FullName) { $Destination }
            else { Join-Path $Destination ([IO.Path]::GetRelativePath($Source, $entry.FullName)) }
        if ($PSCmdlet.ShouldProcess($target, "Copy from $($entry.FullName)")) {
            if ($entry.PSIsContainer) { [IO.Directory]::CreateDirectory($target) | Out-Null }
            else {
                [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
                # An existing directory at the file's target must fail, rather than absorb the file.
                [IO.File]::Copy($entry.FullName, $target, $true)
            }
        }
    }
}

$operation = 'Check required configuration and sources'
try {
    $selectedOptions = @($Output | Select-Object -Unique)
    $paths = @{}
    foreach ($key in ($selectedOptions | ForEach-Object { $recipes[$_].Keys } | Select-Object -Unique)) {
        $paths[$key] = Get-ConfiguredDirectory -Name $variables[$key].Name -AllowMissing:$variables[$key].IsOutput
    }
    if ('staging' -in $selectedOptions) {
        $executable = Join-Path $paths.Release 'Amnesia.exe'
        if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Required source file is missing: $executable" }
        $clientFiles = @(Get-ChildItem -LiteralPath $paths.Client -File -Force |
            Where-Object Extension -In @('.dll', '.exe', '.json'))
        if (-not $clientFiles.Count) { throw 'Staging requires at least one client .dll, .exe, or .json file.' }
        $operation = "Copy staging executable and client files to '$($paths.Staging)'"
        Copy-Entry -Source $executable -Destination (Join-Path $paths.Staging 'Amnesia.exe')
        foreach ($file in $clientFiles) {
            Copy-Entry -Source $file.FullName -Destination (Join-Path $paths.Staging "multimnesia.client/$($file.Name)")
        }
    }
    foreach ($option in $selectedOptions) {
        $destination = $paths[$recipes[$option].Destination]
        $operation = "Copy resources from '$($paths.Resources)' to '$destination'"
        Copy-Entry -Source $paths.Resources -Destination $destination
    }
} catch {
    Write-Error "Failed operation: $operation. $($_.Exception.Message) Earlier copies may have completed." -ErrorAction Continue
    exit 1
}
exit 0
