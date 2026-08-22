# AI Usage Monitor — Agent Instructions

## Scope

These instructions apply to the entire repository. This project is a Windows PowerShell collector, a Codex plugin, a Claude Code plugin, and two compact Rainmeter skins.

For historical decisions, current installation state, package hashes, and the full change record, read [doc/progress.md](doc/progress.md) when the task involves maintenance, troubleshooting, packaging, or UI evolution.

## Project layout

- `ai-usage-monitor/.codex-plugin/plugin.json` — Codex manifest.
- `ai-usage-monitor/.claude-plugin/plugin.json` — Claude Code manifest.
- `ai-usage-monitor/hooks.json` — root-level Codex lifecycle hooks.
- `ai-usage-monitor/hooks/hooks.json` — Claude Code lifecycle hooks.
- `ai-usage-monitor/scripts/Update-AiUsage.ps1` — shared collector and cache writer.
- `ai-usage-monitor/rainmeter/AIUsage/Codex/Codex.ini` — Codex skin.
- `ai-usage-monitor/rainmeter/AIUsage/Claude/Claude.ini` — Claude skin.
- `ai-usage-monitor/rainmeter/AIUsage/Launcher/Launcher.ini` — one-time launcher for both skins.
- `ai-usage-monitor/rainmeter/AIUsage/@Resources/Provider.inc` — shared Rainmeter layout.
- `ai-usage-monitor/rainmeter/AIUsage/@Resources/Usage.lua` — cache reader and dynamic bar colors.
- `ai-usage-monitor/rainmeter/AIUsage/@Resources/RefreshCodex.vbs` — hidden Codex refresh launcher.
- `ai-usage-monitor/tests/` — PowerShell regression and packaging tests.
- `ai-usage-monitor/dist/` — generated `.rmskin` packages.

## Data contract

The collector writes these files atomically:

```text
%LOCALAPPDATA%\AiUsage\usage.json
%LOCALAPPDATA%\AiUsage\usage.cache
```

Rainmeter reads `usage.cache`; `usage.json` is the structured canonical cache.

Codex data is obtained from the latest local JSONL `event_msg` / `token_count` record containing `payload.rate_limits`. Read quota metadata only; conversation prompts and responses are outside this feature.

Codex windows are selected by `window_minutes`:

- approximately 300 minutes → `fiveHour`;
- approximately 10,080 minutes or other multi-day windows → `weekly`.

Codex’s payload uses the legacy `used_percent` field, but the dashboard displays remaining quota as `100 - used_percent`. Preserve this behavior unless the user explicitly requests a semantic change, and update labels/tests if changing it.

Codex `resets_at` values may be Unix seconds. Convert them to ISO in JSON and a readable local string in `usage.cache`.

Claude quota data comes from Claude Code status-line JSON. The collector must not read or print OAuth credentials.

## Rainmeter UI contract

Keep Codex and Claude as separate skins with shared implementation in `Provider.inc` and `Usage.lua`.

Current compact layout contract:

- card size: `270 × 220`;
- row labels: `5H` and `W`;
- reset text: `In <reset time>` immediately after the corresponding row label;
- no time meter;
- no `LOCAL CACHE` label;
- Codex refresh uses `wscript.exe RefreshCodex.vbs` so PowerShell does not flash a console window;
- the launcher positions Codex and Claude separately.

Dynamic bar colors are based on displayed remaining percentage:

| Remaining | Rainmeter RGBA | Hex |
|---|---|---|
| 90–100% | `46,204,113,255` | `#2ECC71` |
| 80–90% | `154,205,50,255` | `#9ACD32` |
| 70–80% | `255,210,30,255` | `#FFD21E` |
| 40–70% | `255,152,0,255` | `#FF9800` |
| 0–40% | `255,77,79,255` | `#FF4D4F` |

Implement color changes in `Usage.lua` through `!SetOption` / `!UpdateMeter`, not by duplicating provider-specific UI logic.

## Change workflow

1. Inspect the existing shared include, Lua reader, collector, and relevant tests before editing.
2. Keep provider-independent UI in `Provider.inc`; keep data interpretation in `Update-AiUsage.ps1`; keep runtime display behavior in `Usage.lua`.
3. Add or update a focused regression test for every data or layout rule changed.
4. Bump the package/plugin version when the distributable behavior changes.
5. Build with `scripts\Build-RainmeterPackage.ps1`; do not rename a normal ZIP to `.rmskin`. The builder adds Rainmeter’s required footer.
6. If the user asks to apply changes locally, update `C:\Users\jedi\Documents\Rainmeter\Skins\AIUsage` and refresh the affected configurations. Preserve recoverable backups for obsolete user-installed files.

### Valid Rainmeter package rule

Every `.rmskin` delivered from this repository must be produced by the Rainmeter Skin Packager-compatible flow in `scripts\Build-RainmeterPackage.ps1` (or by Rainmeter’s own Skin Packager tool). The package must contain a root-level `RMSKIN.ini`, a `Skins\AIUsage\...` tree, and Rainmeter’s exact 16-byte footer: the original ZIP length as a little-endian 64-bit value, one flags byte, and the seven-byte `RMSKIN\0` signature. Run `tests\Test-RainmeterPackage.ps1` against the final artifact before handing it off. A plain ZIP, a renamed ZIP, or an archive missing this footer is not a distributable `.rmskin` and will trigger Rainmeter’s `Invalid package — The Skin Packager tool must be used to create valid .rmskin packages` error.

## Required validation

Run these from `ai-usage-monitor` after changes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RainmeterBindings.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-CodexRateLimits.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Collector.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-RainmeterPackage.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RainmeterPackage.ps1
```

Completion requires all applicable tests to pass, the package to contain both `Skins/AIUsage/Codex/Codex.ini` and `Skins/AIUsage/Claude/Claude.ini`, and the generated package to have a valid Rainmeter footer.

## Plugin rules

- Keep the Codex manifest at `.codex-plugin/plugin.json`.
- Keep Codex hooks in the root `hooks.json`; do not add an unsupported `hooks` field to the Codex manifest.
- Keep Claude hooks in `hooks/hooks.json` and use `${CLAUDE_PLUGIN_ROOT}` in hook commands.
- A Codex marketplace reinstall may require a cachebuster and a new Codex task before updated hooks are loaded.
- Do not silently replace a user’s unrelated Claude `statusLine`; the installer must preserve it or stop for manual merging.

## Safe maintenance boundaries

- Preserve the existing cache schema unless a migration is explicitly designed and tested.
- Do not expose authentication files, access tokens, or conversation content in logs or documentation.
- Treat generated files under `dist/` as rebuildable artifacts.
- Prefer moving obsolete installed skin files to a `.bak` backup rather than deleting them.
- Keep README and progress documentation aligned with the actual split-skin layout when a public-facing behavior changes.
