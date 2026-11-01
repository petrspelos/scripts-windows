# Use PowerShell 7 for Windows helpers

Implement terminal helpers as small PowerShell 7 scripts. PowerShell provides filesystem commands, environment configuration, and navigation in the current shell; maintaining batch equivalents would duplicate implementation and shell integration. PowerShell 7 is a prerequisite.

Put the scripts directory on PATH. Invoke qc.ps1 directly in the current PowerShell process so navigation changes the user's working directory; a profile import is unnecessary. Setup reports command collisions without changing the user's configuration.
