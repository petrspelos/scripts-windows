# Windows Scripts

This repository contains all sorts of scripts and small application I have written for my own personal use.

## PowerShell helpers

Requires PowerShell 7. Add this repository's `scripts` directory to your user
PATH in Windows Environment Variables, then open a new PowerShell terminal.
Run `setup` to diagnose configuration and check that `qc` resolves to this repository.
Setup never changes environment variables, PATH, aliases, or your profile.

Set paths without surrounding quotes in their values. All paths must be absolute.
Commands read the current process environment, so temporary overrides work:

```powershell
$env:quickcd_work = 'C:\work'
qc                         # List directory shortcuts
qc work                    # Navigate in this PowerShell session
```

For persistent configuration, use Windows Environment Variables or, for example:

```powershell
[Environment]::SetEnvironmentVariable('quickcd_work', 'C:\work', 'User')
```

Open a new terminal after persistent environment or PATH changes.

| Variable | Directory |
| --- | --- |
| `AMNESIA_TCP_RELEASE_DIR` | Source containing `Amnesia.exe` |
| `AMNESIA_MP_CLIENT_DIR` | Source containing client `.dll`, `.exe`, and `.json` files |
| `AMNESIA_MP_RESOURCES_DIR` | Source resources tree (may be empty) |
| `AMNESIA_STAGING_DIR` | Staging output; created if missing |
| `AMNESIA_GAME_DIR` | Installed game output; created if missing |
| `quickcd_<key>` | Existing directory for `qc <key>` |

```powershell
copy-amnesia                                      # List options and configuration; copy nothing
copy-amnesia -Output staging
copy-amnesia -Output installed-game
copy-amnesia -Output staging,installed-game -WhatIf
```

`staging` requires the first four copy variables, `Amnesia.exe`, and at least one
matching client file. It copies the executable into the output root, matching
top-level client files into `multimnesia.client`, and the resources tree into the
output root. `installed-game` requires only the resources and game variables and
copies resources into the game directory. Hidden files and empty directories are included.

Every invocation must select its outputs. All selected configuration and sources
are checked before writing; discovered preflight errors are reported together.
Source/output overlap and overlap between selected outputs are rejected.
Linked files, junctions, and symbolic links in configured paths or copied trees
are rejected so they cannot bypass overlap protection.
Copies merge into existing directories, overwrite matching files, and preserve
destination-only files. `-WhatIf` validates and previews without writing.
Failures return a nonzero exit code; filesystem failures stop immediately and
may leave earlier copies completed. Successful copies return zero.

## Development verification

Pester is needed only for development (tests support Pester 3.4 and 4):

```powershell
Install-Module Pester -RequiredVersion 4.10.1 -Scope CurrentUser
Import-Module Pester -RequiredVersion 4.10.1
Invoke-Pester ./tests -EnableExit
```

Tests use temporary directories and invoke copy commands in child PowerShell
processes to verify exit codes. See [the helper design](docs/helper-design.md)
and [the PowerShell ADR](docs/adr/0001-powershell-helpers.md).
