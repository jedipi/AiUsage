# TokenMeter

A agenet usage limit dashboard for Codex, Claude Code, and Rainmeter. It reads quota metadata, both coding-agent plugins keep it fresh, and a native Rainmeter skin renders five-hour and weekly usage limit.

## What is included

- Codex plugin and lifecycle hooks.
- Claude Code plugin and lifecycle hook.
- Marketplace catalogs for Codex and Claude Code.
- 2 Rainmeter skins separate, horizontal-bar and gauge.

The plugin write usage limt and reset date time for Rainmeter. Writes are atomic. Codex collection reads only `token_count` records containing `rate_limits`; it does not inspect prompts or responses. Claude collection uses the documented status-line JSON supplied by Claude Code and does not read OAuth credentials.

## Install

### Codex

Install the plugin and its GitHub marketplace catalog:

```powershell
codex plugin marketplace add jedipi/AiUsage --ref main
codex plugin add tokenmeter@tokenmeter
```

Start a new Codex session after installation so the plugin hooks and skills are loaded. The session-start hook refreshes quota data only. Codex discovers `hooks.json` at the plugin root; the first use may ask you to trust the hook.

### Claude Code

Install the plugin and its GitHub marketplace catalog:

```powershell
claude plugin marketplace add jedipi/AiUsage@main
claude plugin install tokenmeter@tokenmeter --scope user
```


Then clone the repository and run the status-line bootstrap once:

```powershell
git clone https://github.com/jedipi/AiUsage.git
Set-Location .\AiUsage
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-ClaudeStatusLine.ps1
```

Claude quota values appear after Claude Code receives its first API response. If another status line is already configured, the installer stops without changing it; merge the generated command into your existing status-line script.

See the [Claude Code marketplace documentation](https://code.claude.com/docs/en/discover-plugins) for marketplace sources, scopes, and plugin updates.

For development, load the cloned repository for the current session:

```powershell
claude --plugin-dir .
```

### Rainmeter

Marketplace installation does not run arbitrary local PowerShell post-install commands. After installing either plugin, install Rainmeter 4.5+ and run this one-time setup command from a clone of the repository. In Codex, the `$install-rainmeter-skin` skill runs the same setup script.

Run this once:

```powershell
git clone https://github.com/jedipi/AiUsage.git
Set-Location .\AiUsage
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Rainmeter.ps1
```

The skins remain independent and can be positioned or unloaded separately. The package launcher loads both once after installation. To use the gauge variant from the reference design, load `AIUsage\Codex\Gauge.ini` and/or `AIUsage\Claude\Gauge.ini` instead. Click **REFRESH** on Codex to rescan immediately; Claude updates automatically while Claude Code is active.

To rebuild the installer, run `scripts\Build-RainmeterPackage.ps1`. The builder adds Rainmeter 4.5's required 16-byte package footer; renaming a normal ZIP file to `.rmskin` is not sufficient.

## Notes

- Requires Windows PowerShell 5.1+ and Rainmeter 4.5+.
- Codex weekly data can be absent when the current session snapshot has no secondary rate-limit window.
- Claude quota status-line fields are available to Claude.ai Pro/Max accounts and may be absent before the first response.
