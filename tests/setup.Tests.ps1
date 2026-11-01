Describe 'Setup diagnostics' {
    It 'reports all copy variables and missing configuration without changing it' {
        $savedValue = $env:AMNESIA_GAME_DIR
        try {
            Remove-Item Env:AMNESIA_GAME_DIR -ErrorAction SilentlyContinue
            $report = & "$PSScriptRoot/../scripts/setup.ps1" | Out-String
            $report | Should Match 'AMNESIA_GAME_DIR: missing'
            $report | Should Match 'AMNESIA_TCP_RELEASE_DIR'
            $env:AMNESIA_GAME_DIR | Should BeNullOrEmpty
        } finally { $env:AMNESIA_GAME_DIR = $savedValue }
    }
    It 'distinguishes invalid sources from missing output directories and detects command collisions' {
        $savedSource = $env:AMNESIA_MP_RESOURCES_DIR
        $savedOutput = $env:AMNESIA_GAME_DIR
        try {
            $env:AMNESIA_MP_RESOURCES_DIR = 'relative'
            $env:AMNESIA_GAME_DIR = "$TestDrive/not-created"
            function qc { 'collision' }
            $report = & "$PSScriptRoot/../scripts/setup.ps1" | Out-String
            $report | Should Match 'AMNESIA_MP_RESOURCES_DIR: invalid'
            $report | Should Match 'AMNESIA_GAME_DIR: configured output'
            $report | Should Match 'qc command collision'
            Test-Path -LiteralPath $env:AMNESIA_GAME_DIR | Should Be $false
        } finally {
            $env:AMNESIA_MP_RESOURCES_DIR = $savedSource
            $env:AMNESIA_GAME_DIR = $savedOutput
            Remove-Item Function:qc
        }
    }
}
