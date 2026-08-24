$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$testCache = Join-Path $env:TEMP ("ai-usage-antigravity-test-" + [guid]::NewGuid())
$testInstall = Join-Path $env:TEMP ("ai-usage-antigravity-install-" + [guid]::NewGuid())
$testSettings = Join-Path $testInstall 'settings.json'
$previousLocalAppData = $env:LOCALAPPDATA
try {
    New-Item -ItemType Directory -Path $testCache -Force | Out-Null
    @{
        schemaVersion = 1
        updatedAt = ''
        antigravity = @{
            available = $true
            fiveHour = @{ usedPercent = 50; resetAt = '' }
            weekly = @{ usedPercent = 50; resetAt = '' }
            updatedAt = ''
            error = ''
        }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $testCache 'usage.json') -Encoding utf8

    $fixture = @{
        product = 'antigravity'
        quota = [ordered]@{
            'gemini-five-hour' = @{ remaining_fraction = 0.72; reset_in_seconds = 7200 }
            'gemini-weekly' = @{ remaining_fraction = 0.91; reset_time = '2026-08-28T00:00:00Z' }
            'gemini-weekly-pro' = @{ remaining_fraction = 0.84; reset_in_seconds = 900000 }
            'claude-gpt-weekly' = @{ remaining_fraction = 0.76; reset_time = '2026-08-29T00:00:00Z' }
            'claude-weekly-secondary' = @{ remaining_fraction = 0.82; reset_in_seconds = 800000 }
            'gpt-five-hour' = @{ remaining_fraction = 0.15; reset_in_seconds = 5400 }
        }
    } | ConvertTo-Json -Depth 5 -Compress

    & (Join-Path $root 'scripts\Update-AiUsage.ps1') -Source AntigravityStatus -CacheDirectory $testCache -InputJson $fixture
    $result = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.json') | ConvertFrom-Json
    if (-not $result.antigravity.available) { throw 'Antigravity should be available.' }
    if ($result.antigravity.gemini.usedPercent -ne 84) { throw "Expected the lowest Gemini weekly quota, got $($result.antigravity.gemini.usedPercent)." }
    if ($result.antigravity.claudeGpt.usedPercent -ne 76) { throw "Expected the lowest Claude/GPT weekly quota, got $($result.antigravity.claudeGpt.usedPercent)." }
    if ($result.antigravity.gemini.resetAt -notmatch '^\d{4}-\d{2}-\d{2}T') { throw 'Gemini weekly reset time was not normalized to ISO.' }
    if ($null -ne $result.antigravity.fiveHour -or $null -ne $result.antigravity.weekly) { throw 'Antigravity must not expose five-hour/weekly time-window fields.' }
    $flat = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.cache')
    if ($flat -notmatch 'antigravity\.gemini\.usedPercent=84') { throw 'Antigravity Gemini cache value is missing.' }
    if ($flat -notmatch 'antigravity\.claudeGpt\.usedPercent=76') { throw 'Antigravity Claude/GPT cache value is missing.' }
    if ($flat -match 'antigravity\.(fiveHour|weekly)\.') { throw 'Antigravity cache must not expose a five-hour row.' }

    $manifest = Get-Content -Raw -LiteralPath (Join-Path $root '.agents\plugins\tokenmeter\plugin.json') | ConvertFrom-Json
    if ($manifest.name -ne 'tokenmeter') { throw 'Antigravity plugin manifest name is incorrect.' }
    if ($manifest.'$schema' -ne 'https://antigravity.google/schemas/v1/plugin.json') { throw 'Antigravity plugin schema is incorrect.' }
    $hooks = Get-Content -Raw -LiteralPath (Join-Path $root '.agents\plugins\tokenmeter\hooks.json') | ConvertFrom-Json
    if ($null -eq $hooks.'tokenmeter-refresh'.Stop) { throw 'Antigravity Stop hook is missing.' }
    if ($hooks.'tokenmeter-refresh'.Stop[0].hooks[0].command -notmatch 'AntigravityHook\.ps1') { throw 'Antigravity hook command is incorrect.' }

    $env:LOCALAPPDATA = $testInstall
    & (Join-Path $root 'scripts\Install-AntigravityStatusLine.ps1') -PluginRoot $root -SettingsPath $testSettings
    $settings = Get-Content -Raw -LiteralPath $testSettings | ConvertFrom-Json
    if ($settings.statusLine.stack_with_default -ne $true) { throw 'Antigravity installer must preserve the built-in status line.' }
    if ($settings.statusLine.command -notmatch 'AntigravityStatusLine\.ps1') { throw 'Antigravity status-line command is missing.' }
    $installedDirectory = Join-Path $testInstall 'AiUsage'
    foreach ($file in @('Update-AiUsage.ps1', 'AntigravityStatusLine.ps1', 'AntigravityHook.ps1')) {
        if (-not (Test-Path -LiteralPath (Join-Path $installedDirectory $file))) { throw "Antigravity installer did not copy $file." }
    }
    $statusLineOutput = & (Join-Path $installedDirectory 'AntigravityStatusLine.ps1') -InputJson $fixture
    if ($statusLineOutput -notmatch 'TokenMeter: Gemini W 84% \| Claude/GPT W 76%') { throw 'Antigravity status-line adapter output is incorrect.' }
    if (-not (Test-Path -LiteralPath (Join-Path $installedDirectory 'usage.cache'))) { throw 'Antigravity status-line adapter did not refresh the cache.' }

    Write-Host 'Antigravity quota regression test passed.'
}
finally {
    $env:LOCALAPPDATA = $previousLocalAppData
    if (Test-Path -LiteralPath $testCache) { Remove-Item -LiteralPath $testCache -Recurse -Force }
    if (Test-Path -LiteralPath $testInstall) { Remove-Item -LiteralPath $testInstall -Recurse -Force }
}
