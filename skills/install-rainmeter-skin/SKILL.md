---
name: install-rainmeter-skin
description: Install and load the TokenMeter Rainmeter skins by running the plugin's one-time PowerShell setup script.
---

# Install Rainmeter

When the user asks to install or load the TokenMeter Rainmeter skins, run the installer from the plugin repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Rainmeter.ps1
```

The script copies `rainmeter\AIUsage` into the user's Rainmeter skins directory, starts Rainmeter if needed, refreshes it, and activates the launcher. If the user explicitly specifies a custom skins directory, pass it as `-SkinsDirectory <path>`.

This is a one-time setup operation. Do not use it for ordinary session refreshes; use `scripts\Update-AiUsage.ps1` for that. Report the installer output, including the warning when Rainmeter is not found.
