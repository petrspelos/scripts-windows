# Shared by the helper commands; values are read from the process on each call.
function Get-AmnesiaVariables {
    [ordered]@{
        Release = @{ Name = 'AMNESIA_TCP_RELEASE_DIR'; IsOutput = $false }
        Client = @{ Name = 'AMNESIA_MP_CLIENT_DIR'; IsOutput = $false }
        Resources = @{ Name = 'AMNESIA_MP_RESOURCES_DIR'; IsOutput = $false }
        Staging = @{ Name = 'AMNESIA_STAGING_DIR'; IsOutput = $true }
        Game = @{ Name = 'AMNESIA_GAME_DIR'; IsOutput = $true }
    }
}

function Get-ConfiguredDirectory {
    param([string]$Name, [switch]$AllowMissing)

    $directory = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if (-not $directory) { throw "${Name}: missing; set an absolute directory path without surrounding quotes." }
    if ($directory.Contains('"') -or -not [IO.Path]::IsPathFullyQualified($directory)) {
        throw "${Name}: invalid; use an absolute directory path without surrounding quotes."
    }
    if (-not (Test-Path -LiteralPath $directory -PathType Container) -and
        (-not $AllowMissing -or (Test-Path -LiteralPath $directory))) {
        throw "${Name}: invalid; directory does not exist or the path is a file ($directory)."
    }
    [IO.Path]::GetFullPath($directory)
}

function Get-DirectoryConfigurationStatus {
    param([string]$Name, [switch]$AllowMissing)

    try {
        $directory = Get-ConfiguredDirectory -Name $Name -AllowMissing:$AllowMissing
        if (Test-Path -LiteralPath $directory -PathType Container) { "${Name}: ready ($directory)" }
        else { "${Name}: configured output; directory will be created ($directory)" }
    } catch { $_.Exception.Message }
}
