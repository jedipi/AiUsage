$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$testCache = Join-Path $env:TEMP ("ai-usage-codex-test-" + [guid]::NewGuid())
try {
    $fixture = '{"limit_id":"codex","primary":{"used_percent":83.0,"window_minutes":10080,"resets_at":1787810695},"secondary":null,"plan_type":"plus"}'
    & (Join-Path $root 'scripts\Update-AiUsage.ps1') -Source Codex -CacheDirectory $testCache -CodexRateLimitsJson $fixture
    $result = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.json') | ConvertFrom-Json
    if (-not $result.codex.available) { throw 'Codex should be available.' }
    if ($result.codex.fiveHour.usedPercent -ne 0) { throw 'A weekly window must not be displayed as five-hour usage.' }
    if ($result.codex.weekly.usedPercent -ne 17) { throw "Expected 17% remaining, got $($result.codex.weekly.usedPercent)." }
    if ($result.codex.weekly.resetAt -notmatch '^\d{4}-\d{2}-\d{2}T') { throw "Expected an ISO reset time, got $($result.codex.weekly.resetAt)." }
    $flat = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.cache')
    if ($flat -match 'resetAt=1787810695') { throw 'Rainmeter cache still contains the raw Unix timestamp.' }
    if ($flat -notmatch 'codex\.weekly\.resetAt=\w{3} ') { throw 'Rainmeter cache reset time is not human-readable.' }
    Write-Host 'Codex rate-limit regression test passed.'
}
finally {
    if (Test-Path -LiteralPath $testCache) { Remove-Item -LiteralPath $testCache -Recurse -Force }
}
