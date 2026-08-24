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
            '3p-weekly' = @{ remaining_fraction = 0.61; reset_time = '2026-08-30T00:00:00Z' }
            'gpt-five-hour' = @{ remaining_fraction = 0.15; reset_in_seconds = 5400 }
        }
    } | ConvertTo-Json -Depth 5 -Compress

    & (Join-Path $root 'scripts\Update-AiUsage.ps1') -Source AntigravityStatus -CacheDirectory $testCache -InputJson $fixture
    $result = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.json') | ConvertFrom-Json
    if (-not $result.antigravity.available) { throw 'Antigravity should be available.' }
    if ($result.antigravity.gemini.usedPercent -ne 84) { throw "Expected the lowest Gemini weekly quota, got $($result.antigravity.gemini.usedPercent)." }
    if ($result.antigravity.claudeGpt.usedPercent -ne 61) { throw "Expected the lowest Claude/GPT weekly quota, got $($result.antigravity.claudeGpt.usedPercent)." }
    if ($result.antigravity.gemini.resetAt -notmatch '^\d{4}-\d{2}-\d{2}T') { throw 'Gemini weekly reset time was not normalized to ISO.' }
    if ($null -ne $result.antigravity.fiveHour -or $null -ne $result.antigravity.weekly) { throw 'Antigravity must not expose five-hour/weekly time-window fields.' }
    $flat = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.cache')
    if ($flat -notmatch 'antigravity\.gemini\.usedPercent=84') { throw 'Antigravity Gemini cache value is missing.' }
    if ($flat -notmatch 'antigravity\.claudeGpt\.usedPercent=61') { throw 'Antigravity Claude/GPT cache value is missing.' }
    if ($flat -match 'antigravity\.(fiveHour|weekly)\.') { throw 'Antigravity cache must not expose a five-hour row.' }

    $manifest = Get-Content -Raw -LiteralPath (Join-Path $root '.agents\plugins\tokenmeter\plugin.json') | ConvertFrom-Json
    if ($manifest.name -ne 'tokenmeter') { throw 'Antigravity plugin manifest name is incorrect.' }
    if ($manifest.'$schema' -ne 'https://antigravity.google/schemas/v1/plugin.json') { throw 'Antigravity plugin schema is incorrect.' }
    $hooks = Get-Content -Raw -LiteralPath (Join-Path $root '.agents\plugins\tokenmeter\hooks.json') | ConvertFrom-Json
    if ($null -eq $hooks.'tokenmeter-refresh'.Stop) { throw 'Antigravity Stop hook is missing.' }
    $hookCommand = [string]$hooks.'tokenmeter-refresh'.Stop[0].hooks[0].command
    $hookEncodedMatch = [regex]::Match($hookCommand, ' -EncodedCommand (?<payload>[A-Za-z0-9+/=]+)$')
    if (-not $hookEncodedMatch.Success) { throw 'Antigravity hook command must use an integrity-checked encoded command.' }
    $decodedHookCommand = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($hookEncodedMatch.Groups['payload'].Value))
    $expectedHookHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root 'scripts\AntigravityHook.ps1')).Hash
    if ($decodedHookCommand -notlike '*AntigravityHook.ps1*' -or $decodedHookCommand -notlike '*Get-FileHash*' -or $decodedHookCommand -notlike "*$expectedHookHash*") {
        throw 'Antigravity hook command must verify the installed script hash before execution.'
    }

    $env:LOCALAPPDATA = $testInstall
    & (Join-Path $root 'scripts\Install-AntigravityStatusLine.ps1') -PluginRoot $root -SettingsPath $testSettings
    $settingsBytes = [IO.File]::ReadAllBytes($testSettings)
    if ($settingsBytes.Length -ge 3 -and $settingsBytes[0] -eq 0xEF -and $settingsBytes[1] -eq 0xBB -and $settingsBytes[2] -eq 0xBF) {
        throw 'Antigravity settings must use UTF-8 without a byte-order mark.'
    }
    $settings = Get-Content -Raw -LiteralPath $testSettings | ConvertFrom-Json
    $installedDirectory = Join-Path $testInstall 'AiUsage'
    if ($settings.statusLine.stack_with_default -ne $true) { throw 'Antigravity installer must preserve the built-in status line.' }
    $encodedCommandMatch = [regex]::Match($settings.statusLine.command, ' -EncodedCommand (?<payload>[A-Za-z0-9+/=]+)$')
    if (-not $encodedCommandMatch.Success) { throw 'Antigravity status-line command must avoid quoted -File paths.' }
    $decodedCommand = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encodedCommandMatch.Groups['payload'].Value))
    if ($decodedCommand -notlike '*AntigravityStatusLine.ps1*') { throw 'Antigravity status-line command is missing.' }
    foreach ($file in @('Update-AiUsage.ps1', 'AntigravityStatusLine.ps1', 'AntigravityHook.ps1')) {
        if (-not (Test-Path -LiteralPath (Join-Path $installedDirectory $file))) { throw "Antigravity installer did not copy $file." }
    }

    $hookTokens = @($hookCommand -split ' ')
    $hookExecutable = $hookTokens[0]
    $hookArguments = @($hookTokens[1..($hookTokens.Count - 1)])
    $hookOutput = $fixture | & $hookExecutable @hookArguments
    if ($LASTEXITCODE -ne 0 -or $hookOutput -notmatch '^\{\}$') { throw 'Integrity-checked Antigravity hook command failed.' }

    $installedHook = Join-Path $installedDirectory 'AntigravityHook.ps1'
    $tamperMarker = Join-Path $installedDirectory 'tampered-hook-executed'
    @(
        "New-Item -ItemType File -Path (Join-Path `$PSScriptRoot 'tampered-hook-executed') -Force | Out-Null",
        "Write-Output '{}'"
    ) | Set-Content -LiteralPath $installedHook -Encoding utf8
    $null = '{}' | & $hookExecutable @hookArguments
    if (Test-Path -LiteralPath $tamperMarker) { throw 'Antigravity hook executed after its integrity check failed.' }
    Copy-Item -LiteralPath (Join-Path $root 'scripts\AntigravityHook.ps1') -Destination $installedHook -Force

    # Antigravity tokenizes the configured command before launching it. Literal
    # quotes therefore reach powershell.exe as part of the -File path on Windows.
    $statusLineTokens = @($settings.statusLine.command -split ' ')
    $statusLineExecutable = $statusLineTokens[0]
    $statusLineArguments = @($statusLineTokens[1..($statusLineTokens.Count - 1)])
    $statusLineOutput = $fixture | & $statusLineExecutable @statusLineArguments
    if ($LASTEXITCODE -ne 0) { throw "Antigravity status-line command exited with $LASTEXITCODE." }
    if ($statusLineOutput -notmatch 'TokenMeter: Gemini W 84% \| Claude/GPT W 61%') { throw 'Antigravity status-line adapter output is incorrect.' }
    if (-not (Test-Path -LiteralPath (Join-Path $installedDirectory 'usage.cache'))) { throw 'Antigravity status-line adapter did not refresh the cache.' }

    Write-Host 'Antigravity quota regression test passed.'
}
finally {
    $env:LOCALAPPDATA = $previousLocalAppData
    if (Test-Path -LiteralPath $testCache) { Remove-Item -LiteralPath $testCache -Recurse -Force }
    if (Test-Path -LiteralPath $testInstall) { Remove-Item -LiteralPath $testInstall -Recurse -Force }
}
