# TokenMeter Progress

Last updated: 2026-08-24

## Current status

The project is implemented as a Windows PowerShell + Rainmeter usage monitor for Codex, Claude Code, and Google Antigravity. The repository now uses a root-level layout; `ai-usage-monitor\` is no longer the source root. The repository defines three independent provider skins; the active Rainmeter installation remains on the previously installed Codex and Claude skins until the new package is installed.

The source skin layout is:

- `AIUsage\Codex\Codex.ini` and `AIUsage\Codex\Gauge.ini`
- `AIUsage\Claude\Claude.ini` and `AIUsage\Claude\Gauge.ini`
- `AIUsage\Antigravity\Antigravity.ini` and `AIUsage\Antigravity\Gauge.ini`

The old combined skin was preserved as `AIUsage\AIUsage.combined.ini.bak`.

## Repository layout

- `.codex-plugin\plugin.json` — Codex plugin manifest.
- `.agents\plugins\tokenmeter\plugin.json` — Google Antigravity plugin manifest.
- `.agents\plugins\tokenmeter\hooks.json` — Google Antigravity lifecycle hook.
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
- `skills\install-rainmeter-skin\SKILL.md` — one-time Rainmeter setup skill instructions.
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
- Google Antigravity quota data is read from its documented status-line `quota` object, grouped into weekly Gemini and Claude/GPT model pools, and does not read credentials, prompts, responses, or transcripts.
- Antigravity's abbreviated `3p-weekly` bucket is mapped to the Claude/GPT pool alongside explicit Claude, GPT, and third-party bucket names.
- The Antigravity status-line installer writes BOM-free UTF-8 settings and uses an encoded PowerShell command, avoiding both Antigravity's strict JSON parser and its Windows argument-tokenization issue with quoted `-File` paths.
- The Antigravity lifecycle hook verifies the installed hook script's SHA-256 before executing it from `%LOCALAPPDATA%`.
- Cache writes are atomic.

### Rainmeter UI

- Codex, Claude, and Antigravity are separate, independently movable/unloadable skins.
- All three skins share `rainmeter\AIUsage\@Resources\Provider.inc` and `Usage.lua`.
- The compact card is currently `270 × 180`.
- Each provider also has a `Gauge.ini` variant using the shared `@Resources\Gauge.inc`; it is a compact `270 × 180` card with two side-by-side 270-degree solid quota rings matching the supplied reference image.
- The gauge variant keeps the existing provider title bar and refresh action, adds `QUOTA REMAINING`, uses provider-specific labels, and updates ring and percentage colors through `Usage.lua`.
- `REFRESH` is positioned in the top-right, the divider is removed, and the bottom spacing is tightened.
- Time meter was removed.
- `LOCAL CACHE` text was removed.
- Reset values are displayed on their corresponding rows:

  - `5H  In <five-hour reset time>`
  - `W   In <weekly reset time>`
  - Antigravity: `GEMINI  In <weekly reset time>` and `CLAUDE/GPT  In <weekly reset time>`

- A launcher loads all three skins and positions them at startup.
- Rainmeter installation/loading is a one-time post-plugin setup command; Codex and Claude lifecycle hooks refresh quota data, while Antigravity's status-line adapter is the authoritative refresh path.
- Codex refresh uses `wscript.exe` + `RefreshCodex.vbs`, which starts PowerShell hidden so no console window appears.
- Claude, Codex, and Antigravity refresh actions remain independent.

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

The cache includes an `antigravity` provider with `gemini` and `claudeGpt` weekly model pools. Five-hour Antigravity bucket IDs are ignored; when multiple weekly buckets map to one model pool, the lowest remaining quota is displayed.

## Important source files

- `scripts\Update-AiUsage.ps1` — shared collector.
- `scripts\Install-ClaudeStatusLine.ps1` — Claude status-line bootstrap.
- `scripts\Install-AntigravityStatusLine.ps1` — one-time Antigravity status-line setup.
- `scripts\AntigravityStatusLine.ps1` — Antigravity quota status-line adapter.
- `scripts\Install-Rainmeter.ps1` — one-time Rainmeter setup and manual reload.
- `scripts\Build-RainmeterPackage.ps1` — valid `.rmskin` builder with Rainmeter 4.5 footer.
- `rainmeter\AIUsage\@Resources\Provider.inc` — shared compact UI.
- `rainmeter\AIUsage\@Resources\Gauge.inc` — shared gauge variant UI.
- `rainmeter\AIUsage\@Resources\Usage.lua` — cache reader and dynamic colors.
- `rainmeter\AIUsage\@Resources\RefreshCodex.vbs` — hidden Codex refresh launcher.
- `hooks.json` — Codex lifecycle hooks.
- `hooks\hooks.json` — Claude lifecycle hook.

## Current package

The latest package is:

[AIUsage_0.2.18.rmskin](../dist/AIUsage_0.2.18.rmskin)

SHA-256:

```text
65E9C835FC6EFC037F578748BF8EEA95081D8A7A47D871B937084EA7CB399A08
```

The package contains the required Rainmeter footer and is validated by `Test-RainmeterPackage.ps1`.

## Validation completed

The following checks pass when run from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RainmeterBindings.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-CodexRateLimits.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Antigravity.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Collector.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-SecurityHygiene.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-RainmeterPackage.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RainmeterPackage.ps1
```

The tests cover split skins, gauge variants, reset-window mapping, Antigravity weekly model-pool parsing and cache migration, compact dimensions, title-bar placement, hidden refresh execution, dynamic bar and ring color rules, cache parsing, atomic package footer structure, and package entries.

## Installation state

The active Rainmeter skin path is:

```text
%USERPROFILE%\Documents\Rainmeter\Skins\AIUsage
```

The current installed files were backed up to `%USERPROFILE%\Documents\Rainmeter\Skins\AIUsage.backup-<timestamp>`, updated from the current source, and refreshed through Rainmeter. Reinstalling the latest `.rmskin` is still the portable way to reproduce the setup on another machine.

## Known follow-up items

- If the Codex marketplace copy is older than the repository source, copy the latest plugin source to the personal marketplace and reinstall it with a cachebuster so Codex hooks use the latest collector.
- Claude quota values require Claude Code's status-line integration and may be unavailable until Claude receives its first response.
- Codex may expose only a weekly window; in that case the five-hour row correctly displays `NO DATA` while weekly remains populated.
- Antigravity quota values require the one-time status-line installer and may be unavailable until Antigravity emits a payload containing `quota`.
