Describe 'Copy link safety' {
    It 'rejects a junction that would redirect an output into the source' {
        $copyScript = "$PSScriptRoot/../scripts/copy-amnesia.ps1"
        $savedSource = $env:AMNESIA_MP_RESOURCES_DIR
        $savedOutput = $env:AMNESIA_GAME_DIR
        try {
            $env:AMNESIA_MP_RESOURCES_DIR = New-Item -ItemType Directory -Path "$TestDrive/link-source"
            $env:AMNESIA_GAME_DIR = "$TestDrive/linked-output"
            New-Item -ItemType Junction -Path $env:AMNESIA_GAME_DIR -Target $env:AMNESIA_MP_RESOURCES_DIR | Out-Null
            $report = & pwsh -NoProfile -File $copyScript -Output installed-game 2>&1 | Out-String
            $LASTEXITCODE | Should Be 1
            $report | Should Match 'Linked directories are unsupported'
        } finally {
            $env:AMNESIA_MP_RESOURCES_DIR = $savedSource
            $env:AMNESIA_GAME_DIR = $savedOutput
        }
    }
}
