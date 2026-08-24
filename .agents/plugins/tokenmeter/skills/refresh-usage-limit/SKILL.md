---
name: refresh-usage-limit
description: Refresh and troubleshoot Google Antigravity quota data in the TokenMeter cache.
---

# Refresh Usage Limit

Antigravity sends quota metadata to its configured custom status-line command. Run `scripts/Install-AntigravityStatusLine.ps1` once from the TokenMeter repository to install the adapter and preserve the built-in Antigravity status line.

The adapter writes `%LOCALAPPDATA%\AiUsage\usage.json` and `usage.cache` atomically. It reads only the documented `quota` fields from the status-line payload and does not read credentials, prompts, responses, or transcript files.
