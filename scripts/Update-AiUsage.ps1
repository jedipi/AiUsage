[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Codex', 'ClaudeStatus')]
    [string]$Source = 'Auto',
    [string]$CacheDirectory = (Join-Path $env:LOCALAPPDATA 'AiUsage'),
    [string]$InputJson,
    [string]$CodexRateLimitsJson
)

$ErrorActionPreference = 'Stop'

function New-Window([double]$used = 0, [string]$resetAt = '') {
    [ordered]@{ usedPercent = [math]::Min(100, [math]::Max(0, $used)); resetAt = $resetAt }
}

function New-Provider {
    [ordered]@{ available = $false; fiveHour = (New-Window); weekly = (New-Window); updatedAt = ''; error = '' }
}

function Get-Property($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Convert-RateWindow($Window) {
    if ($null -eq $Window) { return New-Window }
    $used = Get-Property $Window 'used_percent'
    if ($null -eq $used) { $used = Get-Property $Window 'used_percentage' }
    if ($null -eq $used) { $used = Get-Property $Window 'utilization' }
    $reset = Get-Property $Window 'resets_at'
    if ($null -ne $reset) {
        $epoch = 0L
        if ([Int64]::TryParse([string]$reset, [ref]$epoch) -and $epoch -ge 1000000000) {
            $reset = [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToString('o')
        }
    }
    if ($null -eq $reset) {
        $seconds = Get-Property $Window 'resets_in_seconds'
        if ($null -ne $seconds) { $reset = [DateTimeOffset]::UtcNow.AddSeconds([double]$seconds).ToString('o') }
    }
    if ($null -eq $used) { $used = 0 }
    if ($null -eq $reset) { $reset = '' }
    New-Window ([double]$used) ([string]$reset)
}

function Convert-CodexWindow($Window) {
    $converted = Convert-RateWindow $Window
    # Codex's UI presents quota remaining. Match that display even though the
    # rollout payload retains the historical `used_percent` field name.
    $converted.usedPercent = [math]::Min(100, [math]::Max(0, 100 - [double]$converted.usedPercent))
    return $converted
}

function Format-ResetForDisplay([string]$ResetAt) {
    if ([string]::IsNullOrWhiteSpace($ResetAt)) { return '' }
    try {
        return ([DateTimeOffset]::Parse($ResetAt)).ToLocalTime().ToString(
            'ddd d MMM, h:mm tt',
            [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch { return $ResetAt }
}

function Read-Cache([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        try { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json }
        catch { }
    }
    [ordered]@{ schemaVersion = 1; updatedAt = ''; codex = (New-Provider); claude = (New-Provider) }
}

function Update-Codex($Cache) {
    if (-not [string]::IsNullOrWhiteSpace($CodexRateLimitsJson)) {
        try { $fixtureLimits = $CodexRateLimitsJson | ConvertFrom-Json }
        catch { throw 'CodexRateLimitsJson is not valid JSON.' }
        $snapshot = [pscustomobject]@{
            timestamp = [DateTimeOffset]::UtcNow.ToString('o')
            payload = [pscustomobject]@{ rate_limits = $fixtureLimits }
        }
    }
    else {
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    $roots = @((Join-Path $codexHome 'sessions'), (Join-Path $codexHome 'archived_sessions'))
    $files = foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) { Get-ChildItem -LiteralPath $root -Filter '*.jsonl' -File -Recurse -ErrorAction SilentlyContinue }
    }
    $snapshot = $null
    foreach ($file in ($files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 40)) {
        $lines = @(Get-Content -LiteralPath $file.FullName -Tail 3000 -ErrorAction SilentlyContinue)
        for ($index = $lines.Count - 1; $index -ge 0; $index--) {
            if ($lines[$index] -notmatch '"rate_limits"') { continue }
            try { $record = $lines[$index] | ConvertFrom-Json } catch { continue }
            if ($record.type -eq 'event_msg' -and $record.payload.type -eq 'token_count' -and $null -ne $record.payload.rate_limits) {
                $snapshot = $record
                break
            }
        }
        if ($null -ne $snapshot) { break }
    }
    }
    if ($null -eq $snapshot) {
        $Cache.codex.error = 'No Codex rate-limit snapshot found'
        return
    }
    $limits = $snapshot.payload.rate_limits
    $fiveHour = New-Window
    $weekly = New-Window
    foreach ($name in @('primary', 'secondary')) {
        $window = Get-Property $limits $name
        if ($null -eq $window) { continue }
        $minutes = Get-Property $window 'window_minutes'
        $converted = Convert-CodexWindow $window
        if ($null -ne $minutes -and [double]$minutes -ge 1440) { $weekly = $converted }
        elseif ($null -ne $minutes -and [double]$minutes -le 360) { $fiveHour = $converted }
        elseif ($fiveHour.usedPercent -eq 0) { $fiveHour = $converted }
        else { $weekly = $converted }
    }
    $snapshotTime = [string]$snapshot.timestamp
    try { $snapshotTime = ([DateTimeOffset]$snapshot.timestamp).ToString('o') } catch { }
    $Cache.codex = [ordered]@{
        available = $true
        fiveHour = $fiveHour
        weekly = $weekly
        updatedAt = $snapshotTime
        error = ''
    }
}

function Update-Claude($Cache, [string]$Json) {
    if ([string]::IsNullOrWhiteSpace($Json)) { return }
    try { $payload = $Json | ConvertFrom-Json } catch {
        $Cache.claude.error = 'Invalid Claude status-line JSON'
        return
    }
    $limits = Get-Property $payload 'rate_limits'
    if ($null -eq $limits) {
        $Cache.claude.error = 'Claude rate limits are not present yet'
        return
    }
    $Cache.claude = [ordered]@{
        available = $true
        fiveHour = Convert-RateWindow (Get-Property $limits 'five_hour')
        weekly = Convert-RateWindow (Get-Property $limits 'seven_day')
        updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
        error = ''
    }
}

New-Item -ItemType Directory -Path $CacheDirectory -Force | Out-Null
$jsonPath = Join-Path $CacheDirectory 'usage.json'
$cache = Read-Cache $jsonPath
if ($Source -in @('Auto', 'Codex')) { Update-Codex $cache }
if ($Source -eq 'ClaudeStatus') {
    $statusJson = $InputJson
    if ([string]::IsNullOrWhiteSpace($statusJson) -and [Console]::IsInputRedirected) { $statusJson = [Console]::In.ReadToEnd() }
    Update-Claude $cache $statusJson
}
$cache.updatedAt = [DateTimeOffset]::UtcNow.ToString('o')

$jsonTemp = "$jsonPath.tmp"
$cache | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonTemp -Encoding utf8
Move-Item -LiteralPath $jsonTemp -Destination $jsonPath -Force

$flatPath = Join-Path $CacheDirectory 'usage.cache'
$flatTemp = "$flatPath.tmp"
$lines = @(
    "updatedAt=$($cache.updatedAt)",
    "codex.available=$($cache.codex.available.ToString().ToLowerInvariant())",
    "codex.fiveHour.usedPercent=$($cache.codex.fiveHour.usedPercent)",
    "codex.fiveHour.resetAt=$(Format-ResetForDisplay ([string]$cache.codex.fiveHour.resetAt))",
    "codex.weekly.usedPercent=$($cache.codex.weekly.usedPercent)",
    "codex.weekly.resetAt=$(Format-ResetForDisplay ([string]$cache.codex.weekly.resetAt))",
    "claude.available=$($cache.claude.available.ToString().ToLowerInvariant())",
    "claude.fiveHour.usedPercent=$($cache.claude.fiveHour.usedPercent)",
    "claude.fiveHour.resetAt=$(Format-ResetForDisplay ([string]$cache.claude.fiveHour.resetAt))",
    "claude.weekly.usedPercent=$($cache.claude.weekly.usedPercent)",
    "claude.weekly.resetAt=$(Format-ResetForDisplay ([string]$cache.claude.weekly.resetAt))"
)
$lines | Set-Content -LiteralPath $flatTemp -Encoding utf8
Move-Item -LiteralPath $flatTemp -Destination $flatPath -Force
