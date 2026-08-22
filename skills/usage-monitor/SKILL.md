---
name: usage-monitor
description: Set up or troubleshoot the AI Usage Monitor cache and companion Rainmeter skin.
---

# AI Usage Monitor

Run `scripts/Update-AiUsage.ps1 -Source Codex` to refresh Codex quota data. Claude quota data is supplied by Claude Code's status-line JSON and requires running `scripts/Install-ClaudeStatusLine.ps1` once.

The shared cache is `%LOCALAPPDATA%\AiUsage\usage.json`. Do not print or copy authentication files; this plugin does not need their contents.
