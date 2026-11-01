# Use PowerShell 7 for Windows helpers

Implement helpers as small PowerShell 7 scripts for terminal users who can edit configuration without knowing scripting. PowerShell fits the existing Amnesia copy workflow and directory navigation; maintaining batch equivalents would add another implementation and shell integration. Installing PowerShell 7 is an accepted prerequisite.

Put the scripts directory on PATH. Invoke qc.ps1 directly in the current PowerShell process so navigation changes the user's working directory; a profile import is unnecessary. Setup reports command collisions without changing the user's configuration.
