---
name: refresh-usage-limit
description: Refresh and troubleshoot TokenMeter usage limits in the local cache and companion Rainmeter skin.
---

# Refresh Usage Limit

Run `scripts/Update-AiUsage.ps1 -Source Codex` to refresh Codex quota data. Claude quota data is supplied by Claude Code's status-line JSON and requires running `scripts/Install-ClaudeStatusLine.ps1` once. Google Antigravity quota data is supplied by its documented status-line JSON and requires running `scripts/Install-AntigravityStatusLine.ps1` once.

The shared cache is `%LOCALAPPDATA%\AiUsage\usage.json`. The Antigravity adapter reads only `quota` fields and does not read authentication files, prompts, responses, or transcripts.
