Describe 'Copy outputs' {
    BeforeEach {
        $copyScript = "$PSScriptRoot/../scripts/copy-amnesia.ps1"
        $savedEnvironment = @{}
        foreach ($name in @('AMNESIA_TCP_RELEASE_DIR','AMNESIA_MP_CLIENT_DIR','AMNESIA_MP_RESOURCES_DIR','AMNESIA_STAGING_DIR','AMNESIA_GAME_DIR')) {
            $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
            [Environment]::SetEnvironmentVariable($name, $null)
        }
        $env:AMNESIA_MP_RESOURCES_DIR = New-Item -ItemType Directory -Path "$TestDrive/resources" -Force
        $env:AMNESIA_GAME_DIR = "$TestDrive/game"
        Set-Content -LiteralPath "$env:AMNESIA_MP_RESOURCES_DIR/resource.txt" -Value 'resource'
    }
    AfterEach {
        foreach ($name in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name]) }
        Remove-Item -LiteralPath "$TestDrive/game" -Recurse -Force -ErrorAction SilentlyContinue
    }
    It 'lists choices without copying and copies installed-game with only its configuration' {
        $report = & pwsh -NoProfile -File $copyScript 2>&1 | Out-String
        $LASTEXITCODE | Should Be 0
        $report | Should Match 'staging'
        $report | Should Match 'installed-game'
        Test-Path -LiteralPath $env:AMNESIA_GAME_DIR | Should Be $false
        & pwsh -NoProfile -File $copyScript -Output installed-game
        $LASTEXITCODE | Should Be 0
        Get-Content -LiteralPath "$env:AMNESIA_GAME_DIR/resource.txt" | Should Be 'resource'
    }
    It 'previews without creating output directories' {
        & pwsh -NoProfile -File $copyScript -Output installed-game -WhatIf
        $LASTEXITCODE | Should Be 0
        Test-Path -LiteralPath $env:AMNESIA_GAME_DIR | Should Be $false
    }
    It 'aggregates configuration failures before any writes' {
        $report = & pwsh -NoProfile -File $copyScript -Output staging 2>&1 | Out-String
        $LASTEXITCODE | Should Be 1
        $report | Should Match 'AMNESIA_TCP_RELEASE_DIR'
        $report | Should Match 'AMNESIA_MP_CLIENT_DIR'
        $report | Should Match 'AMNESIA_STAGING_DIR'
        Test-Path -LiteralPath $env:AMNESIA_GAME_DIR | Should Be $false
    }
    It 'rejects a destination inside the resources source' {
        $env:AMNESIA_GAME_DIR = "$env:AMNESIA_MP_RESOURCES_DIR/nested"
        $report = & pwsh -NoProfile -File $copyScript -Output installed-game 2>&1 | Out-String
        $LASTEXITCODE | Should Be 1
        $report | Should Match 'overlap'
        Test-Path -LiteralPath $env:AMNESIA_GAME_DIR | Should Be $false
    }
    It 'merges resources, overwrites matching files, and preserves destination-only files' {
        New-Item -ItemType Directory -Path $env:AMNESIA_GAME_DIR -Force | Out-Null
        Set-Content -LiteralPath "$env:AMNESIA_GAME_DIR/resource.txt" -Value 'old'
        Set-Content -LiteralPath "$env:AMNESIA_GAME_DIR/preserved.txt" -Value 'keep'
        New-Item -ItemType Directory -Path "$env:AMNESIA_MP_RESOURCES_DIR/empty [folder]" -Force | Out-Null
        & pwsh -NoProfile -File $copyScript -Output installed-game
        $LASTEXITCODE | Should Be 0
        Get-Content -LiteralPath "$env:AMNESIA_GAME_DIR/resource.txt" | Should Be 'resource'
        Get-Content -LiteralPath "$env:AMNESIA_GAME_DIR/preserved.txt" | Should Be 'keep'
        Test-Path -LiteralPath "$env:AMNESIA_GAME_DIR/empty [folder]" -PathType Container | Should Be $true
    }
    It 'reports a filesystem failure with a nonzero exit code and partial-copy warning' {
        New-Item -ItemType Directory -Path "$env:AMNESIA_GAME_DIR/resource.txt" -Force | Out-Null
        # A file cannot replace this directory; Copy-Item must not silently copy into it.
        $report = & pwsh -NoProfile -File $copyScript -Output installed-game 2>&1 | Out-String
        $LASTEXITCODE | Should Be 1
        $report | Should Match 'Failed operation'
        $report | Should Match 'Earlier copies may have completed'
    }
    It 'copies both selected recipes and filters client files' {
        $env:AMNESIA_TCP_RELEASE_DIR = New-Item -ItemType Directory -Path "$TestDrive/release" -Force
        $env:AMNESIA_MP_CLIENT_DIR = New-Item -ItemType Directory -Path "$TestDrive/client" -Force
        $env:AMNESIA_STAGING_DIR = "$TestDrive/staging [output]"
        Set-Content -LiteralPath "$env:AMNESIA_TCP_RELEASE_DIR/Amnesia.exe" -Value 'game'
        foreach ($name in @('client.dll', 'client.exe', 'client.json', 'excluded.pdb')) {
            Set-Content -LiteralPath "$env:AMNESIA_MP_CLIENT_DIR/$name" -Value $name
        }
        & pwsh -NoProfile -Command "& '$copyScript' -Output staging,installed-game"
        $LASTEXITCODE | Should Be 0
        Get-Content -LiteralPath "$env:AMNESIA_STAGING_DIR/Amnesia.exe" | Should Be 'game'
        foreach ($name in @('client.dll', 'client.exe', 'client.json')) {
            Get-Content -LiteralPath "$env:AMNESIA_STAGING_DIR/multimnesia.client/$name" | Should Be $name
        }
        Test-Path -LiteralPath "$env:AMNESIA_STAGING_DIR/multimnesia.client/excluded.pdb" | Should Be $false
        Get-Content -LiteralPath "$env:AMNESIA_STAGING_DIR/resource.txt" | Should Be 'resource'
        Get-Content -LiteralPath "$env:AMNESIA_GAME_DIR/resource.txt" | Should Be 'resource'
    }
    It 'rejects overlapping selected outputs and missing staging artifacts before writing' {
        $env:AMNESIA_TCP_RELEASE_DIR = New-Item -ItemType Directory -Path "$TestDrive/missing-release" -Force
        $env:AMNESIA_MP_CLIENT_DIR = New-Item -ItemType Directory -Path "$TestDrive/missing-client" -Force
        $env:AMNESIA_STAGING_DIR = "$env:AMNESIA_GAME_DIR/nested"
        $report = & pwsh -NoProfile -Command "& '$copyScript' -Output staging,installed-game" 2>&1 | Out-String
        $LASTEXITCODE | Should Be 1
        $report | Should Match 'Amnesia.exe'
        $report | Should Match 'at least one client'
        $report | Should Match 'overlap'
        Test-Path -LiteralPath $env:AMNESIA_GAME_DIR | Should Be $false
    }
    It 'accepts empty resources and rejects quoted and relative paths' {
        Remove-Item -LiteralPath "$env:AMNESIA_MP_RESOURCES_DIR/resource.txt"
        & pwsh -NoProfile -File $copyScript -Output installed-game
        $LASTEXITCODE | Should Be 0
        Test-Path -LiteralPath $env:AMNESIA_GAME_DIR -PathType Container | Should Be $true
        $env:AMNESIA_GAME_DIR = 'relative-output'
        $env:AMNESIA_MP_RESOURCES_DIR = '"C:\quoted"'
        $report = & pwsh -NoProfile -File $copyScript -Output installed-game 2>&1 | Out-String
        $LASTEXITCODE | Should Be 1
        $report | Should Match 'AMNESIA_GAME_DIR'
        $report | Should Match 'AMNESIA_MP_RESOURCES_DIR'
    }
}
