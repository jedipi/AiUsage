[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Codex', 'ClaudeStatus', 'AntigravityStatus')]
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

function New-AntigravityProvider {
    [ordered]@{ available = $false; gemini = (New-Window); claudeGpt = (New-Window); updatedAt = ''; error = '' }
}

function Ensure-Provider($Cache, [string]$Name) {
    $newProvider = if ($Name -eq 'antigravity') { New-AntigravityProvider } else { New-Provider }
    if ($Cache -is [System.Collections.IDictionary]) {
        if (-not $Cache.Contains($Name)) { $Cache[$Name] = $newProvider }
        return
    }
    if ($null -eq (Get-Property $Cache $Name)) {
        $Cache | Add-Member -NotePropertyName $Name -NotePropertyValue $newProvider
    }
}

function Ensure-AntigravityPools($Cache) {
    $provider = if ($Cache -is [System.Collections.IDictionary]) { $Cache['antigravity'] } else { Get-Property $Cache 'antigravity' }
    if ($provider -is [System.Collections.IDictionary]) {
        if (-not $provider.Contains('gemini')) { $provider['gemini'] = New-Window }
        if (-not $provider.Contains('claudeGpt')) { $provider['claudeGpt'] = New-Window }
        return
    }
    if ($null -eq (Get-Property $provider 'gemini')) {
        $provider | Add-Member -NotePropertyName gemini -NotePropertyValue (New-Window)
    }
    if ($null -eq (Get-Property $provider 'claudeGpt')) {
        $provider | Add-Member -NotePropertyName claudeGpt -NotePropertyValue (New-Window)
    }
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

function Convert-AntigravityReset($Window) {
    $reset = Get-Property $Window 'reset_time'
    $resetInSeconds = Get-Property $Window 'reset_in_seconds'
    $epoch = 0L
    if ($null -ne $reset -and [Int64]::TryParse([string]$reset, [ref]$epoch) -and $epoch -ge 1000000000) {
        $reset = [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToString('o')
    }
    if ($null -eq $reset -and $null -ne $resetInSeconds) {
        $reset = [DateTimeOffset]::UtcNow.AddSeconds([double]$resetInSeconds).ToString('o')
    }
    if ($null -ne $reset -and [string]::IsNullOrWhiteSpace([string]$reset) -eq $false) {
        try {
            $parsed = [DateTimeOffset]::Parse([string]$reset)
            $reset = $parsed.ToUniversalTime().ToString('o')
            if ($null -eq $resetInSeconds) {
                $resetInSeconds = ($parsed.ToUniversalTime() - [DateTimeOffset]::UtcNow).TotalSeconds
            }
        }
        catch { }
    }
    if ($null -eq $reset) { $reset = '' }
    [pscustomobject]@{
        resetAt = [string]$reset
        resetInSeconds = if ($null -ne $resetInSeconds) { [double]$resetInSeconds } else { 0 }
    }
}

function Convert-AntigravityWindow($Window) {
    if ($null -eq $Window) { return $null }
    $remaining = Get-Property $Window 'remaining_fraction'
    if ($null -eq $remaining) { $remaining = Get-Property $Window 'remaining_percentage' }
    if ($null -eq $remaining) { $remaining = Get-Property $Window 'remaining_percent' }
    if ($null -eq $remaining) { return $null }
    $remaining = [double]$remaining
    if ($remaining -gt 1) { $remaining = $remaining / 100 }
    New-Window ([math]::Min(100, [math]::Max(0, $remaining * 100)))
}

function Get-AntigravityPoolName([string]$BucketName) {
    $name = $BucketName.ToLowerInvariant()
    if ($name -match 'five.?hour|5h') { return '' }
    if ($name -match 'gemini') { return 'gemini' }
    if ($name -match 'claude|gpt|third.?party|(^|[-_.])3p($|[-_.])') { return 'claudeGpt' }
    return ''
}

function Read-Cache([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        try { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json }
        catch { }
    }
    [ordered]@{ schemaVersion = 1; updatedAt = ''; codex = (New-Provider); claude = (New-Provider); antigravity = (New-AntigravityProvider) }
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

function Update-Antigravity($Cache, [string]$Json) {
    try { $payload = $Json | ConvertFrom-Json } catch {
        $Cache.antigravity.error = 'Invalid Antigravity status-line JSON'
        return
    }
    $quota = Get-Property $payload 'quota'
    if ($null -eq $quota) {
        $Cache.antigravity.error = 'Antigravity quota is not present yet'
        return
    }

    $gemini = New-Window
    $claudeGpt = New-Window
    $hasGemini = $false
    $hasClaudeGpt = $false
    foreach ($property in @($quota.PSObject.Properties)) {
        $converted = Convert-AntigravityWindow $property.Value
        if ($null -eq $converted) { continue }
        $reset = Convert-AntigravityReset $property.Value
        $poolName = Get-AntigravityPoolName $property.Name
        if ([string]::IsNullOrWhiteSpace($poolName)) { continue }
        $candidate = [ordered]@{ usedPercent = $converted.usedPercent; resetAt = $reset.resetAt }
        if ($poolName -eq 'gemini' -and (-not $hasGemini -or $candidate.usedPercent -lt $gemini.usedPercent)) {
            $gemini = $candidate
            $hasGemini = $true
        }
        if ($poolName -eq 'claudeGpt' -and (-not $hasClaudeGpt -or $candidate.usedPercent -lt $claudeGpt.usedPercent)) {
            $claudeGpt = $candidate
            $hasClaudeGpt = $true
        }
    }
    if (-not $hasGemini -and -not $hasClaudeGpt) {
        $Cache.antigravity.error = 'No Antigravity model quota pool found'
        return
    }
    $Cache.antigravity = [ordered]@{
        available = $true
        gemini = $gemini
        claudeGpt = $claudeGpt
        updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
        error = ''
    }
}

New-Item -ItemType Directory -Path $CacheDirectory -Force | Out-Null
$jsonPath = Join-Path $CacheDirectory 'usage.json'
$cache = Read-Cache $jsonPath
Ensure-Provider $cache 'codex'
Ensure-Provider $cache 'claude'
Ensure-Provider $cache 'antigravity'
Ensure-AntigravityPools $cache
if ($Source -in @('Auto', 'Codex')) { Update-Codex $cache }
if ($Source -eq 'ClaudeStatus') {
    $statusJson = $InputJson
    if ([string]::IsNullOrWhiteSpace($statusJson) -and [Console]::IsInputRedirected) { $statusJson = [Console]::In.ReadToEnd() }
    Update-Claude $cache $statusJson
}
if ($Source -eq 'AntigravityStatus') {
    $statusJson = $InputJson
    if ([string]::IsNullOrWhiteSpace($statusJson) -and [Console]::IsInputRedirected) { $statusJson = [Console]::In.ReadToEnd() }
    Update-Antigravity $cache $statusJson
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
    "claude.weekly.resetAt=$(Format-ResetForDisplay ([string]$cache.claude.weekly.resetAt))",
    "antigravity.available=$($cache.antigravity.available.ToString().ToLowerInvariant())",
    "antigravity.gemini.usedPercent=$($cache.antigravity.gemini.usedPercent)",
    "antigravity.gemini.resetAt=$(Format-ResetForDisplay ([string]$cache.antigravity.gemini.resetAt))",
    "antigravity.claudeGpt.usedPercent=$($cache.antigravity.claudeGpt.usedPercent)",
    "antigravity.claudeGpt.resetAt=$(Format-ResetForDisplay ([string]$cache.antigravity.claudeGpt.resetAt))"
)
$lines | Set-Content -LiteralPath $flatTemp -Encoding utf8
Move-Item -LiteralPath $flatTemp -Destination $flatPath -Force
