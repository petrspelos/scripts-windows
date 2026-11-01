# Windows Scripts

Personal scripts and small applications for recurring Windows tasks.

## PowerShell helpers

Requires PowerShell 7. Add this repository's `scripts` directory to your user PATH,
then open a new PowerShell terminal and run `setup` to check configuration.

```powershell
qc                                      # List configured directory shortcuts
qc work                                 # Navigate to quickcd_work
copy-amnesia                            # List output options and configuration
copy-amnesia -Output staging -WhatIf     # Preview; omit WhatIf to copy and overwrite
```

See the [wiki](https://github.com/petrspelos/scripts-windows/wiki) for configuration,
copy recipes, and usage. See [CONTRIBUTING.md](CONTRIBUTING.md) for development checks.
