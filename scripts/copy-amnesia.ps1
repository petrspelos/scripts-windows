#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('staging', 'installed-game')][string[]]$Output)

$ErrorActionPreference = 'Stop'

# Keep recipes explicit: each option documents exactly which configuration it needs.
$recipes = [ordered]@{
    staging = @{
        Description = 'Amnesia.exe, client .dll/.exe/.json in multimnesia.client, and resources'
        Variables = @('AMNESIA_TCP_RELEASE_DIR', 'AMNESIA_MP_CLIENT_DIR', 'AMNESIA_MP_RESOURCES_DIR', 'AMNESIA_STAGING_DIR')
        Destination = 'AMNESIA_STAGING_DIR'
    }
    'installed-game' = @{
        Description = 'Resources merged into the installed game'
        Variables = @('AMNESIA_MP_RESOURCES_DIR', 'AMNESIA_GAME_DIR')
        Destination = 'AMNESIA_GAME_DIR'
    }
}
if (-not $Output) {
    foreach ($option in $recipes.Keys) {
        "${option}: $($recipes[$option].Description)"
        foreach ($variableName in $recipes[$option].Variables) {
            $value = [Environment]::GetEnvironmentVariable($variableName, 'Process')
            $status = if (-not $value) { 'missing' }
                elseif ($value.Contains('"') -or -not [IO.Path]::IsPathFullyQualified($value)) { 'invalid path' }
                elseif (Test-Path -LiteralPath $value -PathType Container) { 'ready' }
                elseif ($variableName -eq $recipes[$option].Destination -and -not (Test-Path -LiteralPath $value)) { 'configured; will be created' }
                else { 'invalid directory' }
            "  ${variableName}: $status"
        }
    }
    exit 0
}

$preflightErrors = [Collections.Generic.List[string]]::new()
$paths = @{}
$selectedOptions = @($Output | Select-Object -Unique)
$requiredVariables = @($selectedOptions | ForEach-Object { $recipes[$_].Variables } | Select-Object -Unique)
foreach ($variableName in $requiredVariables) {
    $value = [Environment]::GetEnvironmentVariable($variableName, 'Process')
    if (-not $value) {
        $preflightErrors.Add("$variableName is missing; set an absolute directory path without surrounding quotes.")
        continue
    }
    try {
        if ($value.Contains('"') -or -not [IO.Path]::IsPathFullyQualified($value)) {
            throw 'Use an absolute directory path without surrounding quotes.'
        }
        $directory = [IO.Path]::GetFullPath($value)
        if ($directory -ne [IO.Path]::GetPathRoot($directory)) {
            $directory = $directory.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        }
        # Inspect ancestors too: lexical overlap checks cannot protect junction targets.
        $ancestor = [IO.Path]::GetFullPath($value)
        while ($ancestor) {
            if (Test-Path -LiteralPath $ancestor) {
                $item = Get-Item -LiteralPath $ancestor -Force
                if (-not $item.PSIsContainer) { throw "Not a directory: $ancestor" }
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked directories are unsupported: $ancestor" }
            }
            $ancestor = [IO.Path]::GetDirectoryName($ancestor.TrimEnd([IO.Path]::DirectorySeparatorChar))
        }
        $isDestination = $variableName -in @('AMNESIA_STAGING_DIR', 'AMNESIA_GAME_DIR')
        if (-not $isDestination -and -not (Test-Path -LiteralPath $value -PathType Container)) {
            throw 'Source directory does not exist.'
        }
        $paths[$variableName] = $directory
    } catch { $preflightErrors.Add("${variableName}: $($_.Exception.Message)") }
}

$operations = [Collections.Generic.List[object]]::new()
if ('staging' -in $selectedOptions) {
    if ($paths.ContainsKey('AMNESIA_TCP_RELEASE_DIR')) {
        $executable = Join-Path $paths.AMNESIA_TCP_RELEASE_DIR 'Amnesia.exe'
        if (Test-Path -LiteralPath $executable -PathType Leaf) {
            $operations.Add(@{ Source = $executable; Option = 'staging'; Relative = 'Amnesia.exe' })
        } else { $preflightErrors.Add("Required source file is missing: $executable") }
    }
    if ($paths.ContainsKey('AMNESIA_MP_CLIENT_DIR')) {
        try {
            $clientFiles = @(Get-ChildItem -LiteralPath $paths.AMNESIA_MP_CLIENT_DIR -File -Force |
                Where-Object Extension -In @('.dll', '.exe', '.json'))
            if (-not $clientFiles.Count) { $preflightErrors.Add('Staging requires at least one client .dll, .exe, or .json file.') }
            foreach ($file in $clientFiles) {
                $operations.Add(@{ Source = $file.FullName; Option = 'staging'; Relative = "multimnesia.client/$($file.Name)" })
            }
        } catch { $preflightErrors.Add("Cannot read client files: $($_.Exception.Message)") }
    }
}
if ($paths.ContainsKey('AMNESIA_MP_RESOURCES_DIR')) {
    try {
        $resourceFiles = @(Get-ChildItem -LiteralPath $paths.AMNESIA_MP_RESOURCES_DIR -Recurse -Force)
        foreach ($option in $selectedOptions) {
            foreach ($file in $resourceFiles) {
                $operations.Add(@{ Source = $file.FullName; Option = $option
                    Relative = [IO.Path]::GetRelativePath($paths.AMNESIA_MP_RESOURCES_DIR, $file.FullName)
                    Directory = $file.PSIsContainer })
            }
        }
    } catch { $preflightErrors.Add("Cannot read resources: $($_.Exception.Message)") }
}
foreach ($operation in $operations) {
    try {
        if ((Get-Item -LiteralPath $operation.Source -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $preflightErrors.Add("Linked sources are unsupported: $($operation.Source)")
        }
    } catch { $preflightErrors.Add("Cannot inspect source '$($operation.Source)': $($_.Exception.Message)") }
}

function Test-PathOverlap([string]$First, [string]$Second) {
    $comparison = [StringComparison]::OrdinalIgnoreCase
    $First = $First.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $Second = $Second.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    return $First.Equals($Second, $comparison) -or
        $First.StartsWith("$Second$([IO.Path]::DirectorySeparatorChar)", $comparison) -or
        $Second.StartsWith("$First$([IO.Path]::DirectorySeparatorChar)", $comparison)
}
$destinations = @($selectedOptions | ForEach-Object { $paths[$recipes[$_].Destination] } | Where-Object { $_ })
$sources = @($paths.Keys | Where-Object { $_ -notin @('AMNESIA_STAGING_DIR', 'AMNESIA_GAME_DIR') } | ForEach-Object { $paths[$_] })
for ($index = 0; $index -lt $destinations.Count; $index++) {
    foreach ($otherPath in ($sources + @($destinations | Select-Object -Skip ($index + 1)))) {
        if (Test-PathOverlap $destinations[$index] $otherPath) {
            $preflightErrors.Add("Paths overlap: $($destinations[$index]) and $otherPath")
        }
    }
    if (Test-Path -LiteralPath $destinations[$index]) {
        try {
            foreach ($item in Get-ChildItem -LiteralPath $destinations[$index] -Recurse -Force) {
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    $preflightErrors.Add("Linked destination entries are unsupported: $($item.FullName)")
                }
            }
        } catch { $preflightErrors.Add("Cannot inspect destination: $($_.Exception.Message)") }
    }
}
if ($preflightErrors.Count) {
    Write-Error -Message ("Preflight failed; nothing was copied:`n" + ($preflightErrors -join "`n")) -ErrorAction Continue
    exit 1
}

$currentOperation = 'creating output directories'
try {
    foreach ($destination in $destinations) {
        $currentOperation = "Create directory '$destination'"
        if ($PSCmdlet.ShouldProcess($destination, 'Create output directory')) {
            [IO.Directory]::CreateDirectory($destination) | Out-Null
        }
    }
    foreach ($operation in $operations) {
        $target = Join-Path $paths[$recipes[$operation.Option].Destination] $operation.Relative
        $currentOperation = "Copy '$($operation.Source)' to '$target'"
        if ($PSCmdlet.ShouldProcess($target, "Copy from $($operation.Source)")) {
            if ($operation.Directory) { [IO.Directory]::CreateDirectory($target) | Out-Null }
            else {
                [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
                [IO.File]::Copy($operation.Source, $target, $true)
            }
        }
    }
} catch {
    Write-Error -Message ("Failed operation: $currentOperation. $($_.Exception.Message) Earlier copies may have completed.") -ErrorAction Continue
    exit 1
}
exit 0


