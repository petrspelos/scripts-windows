# Helper command design

Agreed behavior from the completed design interview. Implementation is tracked separately.

## Configuration and setup

Machine-specific source and destination paths come from environment variables. Setup diagnoses missing or invalid configuration, explains what to set, and can be run repeatedly without changing configuration. Users make persistent configuration and PATH changes themselves.

Read configuration from the current process environment, permitting temporary overrides. Explain that persistent changes may require a new terminal. Paths must be absolute and values must omit surrounding quotes. Setup reports all supported variables, distinguishing missing configuration from invalid paths; commands validate only configuration needed by the selected task. Missing output directories are valid when their paths are configured.

Copy variables:

- AMNESIA_TCP_RELEASE_DIR
- AMNESIA_MP_CLIENT_DIR
- AMNESIA_MP_RESOURCES_DIR
- AMNESIA_STAGING_DIR
- AMNESIA_GAME_DIR

Directory shortcuts are discovered from quickcd_<key> variables. qc tdd-tcp uses quickcd_tdd-tcp. With no key, list shortcuts; unknown keys and nonexistent directories produce clear errors. Setup checks whether Get-Command qc resolves to this repository's qc.ps1 and explains collisions. No alias, function registration, or profile import is required.

## Copy behavior

Maintain an explicit list of output options in the copy script, documenting each recipe and required variables. With no output options selected, list available options and configuration status and copy nothing. Every invocation must explicitly select its destinations; several may be selected together.

Validate all selected configuration and required sources before writing. Create missing configured output directories. Merge into existing destinations, overwrite matching files, and preserve destination-only files. Filesystem failures may leave partial copies and must be reported clearly. Support -WhatIf.

Reject source/destination overlap and overlapping selected destinations. Report all discovered preflight configuration errors together. Stop at the first filesystem failure, identify the failed operation, and explain that earlier copies may have completed. Copy failures return a nonzero exit code; successful copies return zero.

Initial recipes:

- Staging: copy Amnesia.exe into the output root, multiplayer client .dll/.exe/.json files into multimnesia.client, and resources into the output root.
- Installed game: copy resources into the configured game directory.

Staging requires Amnesia.exe, at least one matching client file, and an existing resources directory. An empty resources directory is valid. Installed-game output requires only the resources source and game destination.

## Public commands

Place setup.ps1, qc.ps1, and copy-amnesia.ps1 on PATH. Invoke directly from PowerShell 7:

```powershell
setup
qc
qc tdd-tcp
copy-amnesia
copy-amnesia -Output staging
copy-amnesia -Output staging,installed-game -WhatIf
```

Bare copy-amnesia lists options and performs no copy. Bare qc lists directory shortcuts.

## Code conventions

Use small scripts and functions, explicit parameters, descriptive names, literal path handling, terminating failures, and short usage examples. Spell out command names in implementation code. Extract abstractions when repeated use justifies them. Commands must support automation and omit interactive closing pauses.

Use four-space indentation, opening braces on the same line, descriptive camelCase local variables, and PascalCase parameters. Comments explain reasons or surprising behavior. Keep functions local until actual reuse warrants a shared file.

## Verification

Use focused Pester tests with temporary directories for navigation, preflight, destination selection, and copying. Pester is a development dependency; normal usage requires only PowerShell 7. Initially omit mandatory formatting tools, build systems, and pre-commit hooks.
