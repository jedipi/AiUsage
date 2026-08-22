# TokenMeter Progress

Last updated: 2026-08-23

## Current status

The project is implemented as a Windows PowerShell + Rainmeter usage monitor for Codex and Claude Code. The repository now uses a root-level layout; `ai-usage-monitor\` is no longer the source root. The active Rainmeter installation has been updated directly and currently uses two independent provider skins:

- `AIUsage\Codex\Codex.ini` and `AIUsage\Codex\Gauge.ini`
- `AIUsage\Claude\Claude.ini` and `AIUsage\Claude\Gauge.ini`

The old combined skin was preserved as `AIUsage\AIUsage.combined.ini.bak`.

## Repository layout

- `.codex-plugin\plugin.json` — Codex plugin manifest.
- `.agents\plugins\marketplace.json` — Codex GitHub marketplace catalog.
- `.claude-plugin\plugin.json` — Claude Code plugin manifest.
- `.claude-plugin\marketplace.json` — Claude Code GitHub marketplace catalog.
- `hooks.json` — root-level Codex lifecycle hooks.
- `hooks\hooks.json` — Claude Code lifecycle hooks.
- `rainmeter\AIUsage\` — shared resources, split provider skins, gauge variants, and launcher.
- `rainmeter\RMSKIN.ini` — Rainmeter package metadata.
- `scripts\` — collector, installers, and package builder.
- `tests\` — PowerShell regression and package tests.
- `skills\refresh-usage-limit\SKILL.md` — refresh-usage-limit skill instructions.
- `dist\` — generated `.rmskin` packages.
- `README.md` and `LICENSE` — repository-level documentation and license.

## Completed functionality

### Usage collection

- Codex collector scans `%USERPROFILE%\.codex\sessions` and `archived_sessions` JSONL files.
- It selects the latest `event_msg` / `token_count` record containing `payload.rate_limits`.
- Codex windows are classified by `window_minutes` rather than assuming `primary` is always the five-hour window.
- Codex Unix reset timestamps are converted to ISO timestamps in `usage.json` and readable local strings in `usage.cache`.
- Codex quota display uses remaining capacity (`100 - used_percent`) to match the Codex UI.
- Claude Code quota data is read from Claude status-line JSON and does not read OAuth credentials.
- Cache writes are atomic.

### Rainmeter UI

- Codex and Claude are separate, independently movable/unloadable skins.
- Both skins share `rainmeter\AIUsage\@Resources\Provider.inc` and `Usage.lua`.
- The compact card is currently `270 × 180`.
- Each provider also has a `Gauge.ini` variant using the shared `@Resources\Gauge.inc`; it is a compact `270 × 180` card with two side-by-side 270-degree solid quota rings matching the supplied reference image.
- The gauge variant keeps the existing provider title bar and refresh action, adds `QUOTA REMAINING`, shows `5H`/`7D` labels with their respective `In <reset date time>` values, and updates ring and percentage colors through `Usage.lua`.
- `REFRESH` is positioned in the top-right, the divider is removed, and the bottom spacing is tightened.
- Time meter was removed.
- `LOCAL CACHE` text was removed.
- Reset values are displayed on their corresponding rows:

  - `5H  In <five-hour reset time>`
  - `W   In <weekly reset time>`

- A launcher loads both skins and positions them at startup.
- Codex refresh uses `wscript.exe` + `RefreshCodex.vbs`, which starts PowerShell hidden so no console window appears.
- Claude and Codex refresh actions remain independent.

### Dynamic quota colors

The current color rules are based on the displayed remaining percentage:

| Remaining quota | Color | RGB used by Rainmeter |
|---|---|---|
| 90–100% | Green `#2ECC71` | `46,204,113,255` |
| 80–90% | Lime `#9ACD32` | `154,205,50,255` |
| 70–80% | Yellow `#FFD21E` | `255,210,30,255` |
| 40–70% | Orange `#FF9800` | `255,152,0,255` |
| 0–40% | Red `#FF4D4F` | `255,77,79,255` |

`Usage.lua` changes the corresponding bar's `BarColor`, or the gauge ring and percentage text colors, during each percentage measure update.

## Data files

The collector writes:

```text
%LOCALAPPDATA%\AiUsage\usage.json
%LOCALAPPDATA%\AiUsage\usage.cache
```

Rainmeter reads `usage.cache`. The JSON file remains the canonical structured cache.

## Important source files

- `scripts\Update-AiUsage.ps1` — shared collector.
- `scripts\Install-ClaudeStatusLine.ps1` — Claude status-line bootstrap.
- `scripts\Install-Rainmeter.ps1` — manual skin installation.
- `scripts\Build-RainmeterPackage.ps1` — valid `.rmskin` builder with Rainmeter 4.5 footer.
- `rainmeter\AIUsage\@Resources\Provider.inc` — shared compact UI.
- `rainmeter\AIUsage\@Resources\Gauge.inc` — shared gauge variant UI.
- `rainmeter\AIUsage\@Resources\Usage.lua` — cache reader and dynamic colors.
- `rainmeter\AIUsage\@Resources\RefreshCodex.vbs` — hidden Codex refresh launcher.
- `hooks.json` — Codex lifecycle hooks.
- `hooks\hooks.json` — Claude lifecycle hook.

## Current package

The latest package is:

[AIUsage_0.2.10.rmskin](../dist/AIUsage_0.2.10.rmskin)

SHA-256:

```text
FC2A5AA5667B19FFD893EF4387CC743FE23287E23E2AEF5F497A79F4430F12F8
```

The package contains the required Rainmeter footer and is validated by `Test-RainmeterPackage.ps1`.

## Validation completed

The following checks pass when run from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RainmeterBindings.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-CodexRateLimits.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Collector.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-RainmeterPackage.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RainmeterPackage.ps1
```

The tests cover split skins, gauge variants, reset-window mapping, compact dimensions, title-bar placement, hidden refresh execution, dynamic bar and ring color rules, cache parsing, atomic package footer structure, and package entries.

## Installation state

The active Rainmeter skin path is:

```text
C:\Users\jedi\Documents\Rainmeter\Skins\AIUsage
```

The current installed files were backed up to `C:\Users\jedi\Documents\Rainmeter\Skins\AIUsage.backup-20260822-150547`, updated from the current source, and refreshed through Rainmeter. Reinstalling the latest `.rmskin` is still the portable way to reproduce the setup on another machine.

## Known follow-up items

- If the Codex marketplace copy is older than the repository source, copy the latest plugin source to the personal marketplace and reinstall it with a cachebuster so Codex hooks use the latest collector.
- Claude quota values require Claude Code's status-line integration and may be unavailable until Claude receives its first response.
- Codex may expose only a weekly window; in that case the five-hour row correctly displays `NO DATA` while weekly remains populated.
