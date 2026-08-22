# AI Usage Monitor

A dependency-free Windows usage dashboard for Codex, Claude Code, and Rainmeter. PowerShell collects quota metadata, both coding-agent plugins keep it fresh, and a native Rainmeter skin renders five-hour and weekly usage.

## What is included

- `.codex-plugin/` and root `hooks.json`: Codex plugin and lifecycle hooks.
- `.claude-plugin/` and `hooks/hooks.json`: Claude Code plugin and lifecycle hook.
- `scripts/Update-AiUsage.ps1`: shared, read-only collector.
- `rainmeter/AIUsage/`: 680 × 390 dark dashboard skin.

The collector writes `%LOCALAPPDATA%\AiUsage\usage.json` plus a simple `usage.cache` bridge for Rainmeter. Writes are atomic. Codex collection reads only `token_count` records containing `rate_limits`; it does not inspect prompts or responses. Claude collection uses the documented status-line JSON supplied by Claude Code and does not read OAuth credentials.

## Install

### Codex

Install this folder as a local Codex plugin using your normal marketplace/plugin workflow. Codex discovers `hooks.json` at the plugin root. The first use may ask you to trust the hook.

For development, keep this repository path as the plugin source and validate it with the bundled plugin validator.

### Claude Code

Load or install this folder as a Claude Code plugin, then run the status-line bootstrap once:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-ClaudeStatusLine.ps1
```

Claude quota values appear after Claude Code receives its first API response. If another status line is already configured, the installer stops without changing it; merge the generated command into your existing status-line script.

For development:

```powershell
claude --plugin-dir .\ai-usage-monitor
```

### Rainmeter

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Rainmeter.ps1
```

Refresh Rainmeter and load `AIUsage\Codex\Codex.ini` and `AIUsage\Claude\Claude.ini`. They are independent skins and can be positioned or unloaded separately. The package launcher loads both once after installation. Click **REFRESH** on Codex to rescan immediately; Claude updates automatically while Claude Code is active.

To rebuild the installer, run `scripts\Build-RainmeterPackage.ps1`. The builder adds Rainmeter 4.5's required 16-byte package footer; renaming a normal ZIP file to `.rmskin` is not sufficient.

## Data contract

`usage.json` uses schema version 1:

```json
{
  "schemaVersion": 1,
  "updatedAt": "2026-08-21T00:00:00Z",
  "codex": {
    "available": true,
    "fiveHour": { "usedPercent": 46, "resetAt": "2026-08-21T04:00:00Z" },
    "weekly": { "usedPercent": 82, "resetAt": "2026-08-25T00:00:00Z" }
  },
  "claude": {
    "available": true,
    "fiveHour": { "usedPercent": 12, "resetAt": "2026-08-21T05:00:00Z" },
    "weekly": { "usedPercent": 34, "resetAt": "2026-08-27T00:00:00Z" }
  }
}
```

Missing data displays as zero / `NO DATA`, while the last good provider values remain cached.

## Notes

- Requires Windows PowerShell 5.1+ and Rainmeter 4.5+.
- Codex weekly data can be absent when the current session snapshot has no secondary rate-limit window.
- Claude quota status-line fields are available to Claude.ai Pro/Max accounts and may be absent before the first response.
