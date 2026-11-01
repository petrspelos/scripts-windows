# Contributing

Keep PowerShell helpers small, with explicit parameters, descriptive names,
literal paths, terminating failures, and no interactive closing pauses.
Use four-space indentation, opening braces on the same line, camelCase local
variables, PascalCase parameters, and spelled-out command names.
Comments explain reasons or surprising behavior. Share helpers when actual reuse warrants it.

Test through the public scripts with temporary directories. Pester is a development
dependency; normal usage requires only PowerShell 7. Run `Invoke-Pester ./tests -EnableExit`
with Pester 3.4 or 4.10.1 before submitting changes. Copy tests use child PowerShell
processes to check exit codes. Update the [wiki](https://github.com/petrspelos/scripts-windows/wiki)
when command usage changes.
