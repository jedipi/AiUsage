$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$testCache = Join-Path $env:TEMP ("ai-usage-test-" + [guid]::NewGuid())
try {
    $inputJson = '{"rate_limits":{"five_hour":{"used_percentage":42,"resets_at":"2026-08-21T04:00:00Z"},"seven_day":{"used_percentage":73,"resets_at":"2026-08-27T00:00:00Z"}}}'
    & (Join-Path $root 'scripts\Update-AiUsage.ps1') -Source ClaudeStatus -CacheDirectory $testCache -InputJson $inputJson
    $result = Get-Content -Raw -LiteralPath (Join-Path $testCache 'usage.json') | ConvertFrom-Json
    if (-not $result.claude.available) { throw 'Claude should be available' }
    if ($result.claude.fiveHour.usedPercent -ne 42) { throw 'Five-hour usage mismatch' }
    if ($result.claude.weekly.usedPercent -ne 73) { throw 'Weekly usage mismatch' }
    if (-not (Test-Path -LiteralPath (Join-Path $testCache 'usage.cache'))) { throw 'Rainmeter cache was not written' }
    Write-Host 'Collector test passed.'
}
finally {
    if (Test-Path -LiteralPath $testCache) { Remove-Item -LiteralPath $testCache -Recurse -Force }
}
