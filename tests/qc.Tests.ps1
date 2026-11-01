Describe 'Directory shortcuts' {
    It 'navigates to a literal configured directory in the current session' {
        $originalLocation = Get-Location
        $env:quickcd_helpertest = New-Item -ItemType Directory -Path "$TestDrive/shortcut [one]"
        try {
            & "$PSScriptRoot/../scripts/qc.ps1" helpertest
            (Get-Location).Path | Should Be $env:quickcd_helpertest
        } finally {
            Set-Location -LiteralPath $originalLocation.Path
            Remove-Item Env:quickcd_helpertest
        }
    }
    It 'lists shortcuts and reports unknown keys and missing directories' {
        $env:quickcd_helpertest = "$TestDrive/missing"
        try {
            (& "$PSScriptRoot/../scripts/qc.ps1" | Out-String) | Should Match 'helpertest:'
            { & "$PSScriptRoot/../scripts/qc.ps1" helpertest } | Should Throw 'existing absolute directory'
            { & "$PSScriptRoot/../scripts/qc.ps1" helpertest_unknown } | Should Throw 'Unknown directory shortcut'
        } finally { Remove-Item Env:quickcd_helpertest }
    }
}
