[CmdletBinding()]
param([string]$InputJson)

$ErrorActionPreference = 'SilentlyContinue'

if ([string]::IsNullOrWhiteSpace($InputJson) -and [Console]::IsInputRedirected) {
    $InputJson = [Console]::In.ReadToEnd()
}
if ([string]::IsNullOrWhiteSpace($InputJson)) {
    Write-Output 'TokenMeter: Antigravity quota unavailable'
    exit 0
}

$collector = Join-Path $PSScriptRoot 'Update-AiUsage.ps1'
& $collector -Source AntigravityStatus -InputJson $InputJson *> $null

try {
    $payload = $InputJson | ConvertFrom-Json
    $quota = $payload.quota
    $pools = @{}
    foreach ($property in @($quota.PSObject.Properties)) {
        $bucketName = $property.Name.ToLowerInvariant()
        if ($bucketName -match 'five.?hour|5h') { continue }
        $poolName = if ($bucketName -match 'gemini') { 'Gemini W' } elseif ($bucketName -match 'claude|gpt|third.?party') { 'Claude/GPT W' } else { '' }
        if ([string]::IsNullOrWhiteSpace($poolName)) { continue }
        $remaining = $property.Value.remaining_fraction
        if ($null -eq $remaining) { $remaining = $property.Value.remaining_percentage }
        if ($null -eq $remaining) { $remaining = $property.Value.remaining_percent }
        if ($null -eq $remaining) { continue }
        $percent = [double]$remaining
        if ($percent -le 1) { $percent *= 100 }
        if (-not $pools.ContainsKey($poolName) -or $percent -lt $pools[$poolName]) { $pools[$poolName] = $percent }
    }
    $summary = foreach ($poolName in @('Gemini W', 'Claude/GPT W')) {
        if ($pools.ContainsKey($poolName)) { '{0} {1:0}%' -f $poolName, $pools[$poolName] }
    }
    if (@($summary).Count -gt 0) {
        Write-Output ('TokenMeter: ' + (@($summary) -join ' | '))
    }
    else {
        Write-Output 'TokenMeter: Antigravity quota unavailable'
    }
}
catch {
    Write-Output 'TokenMeter: Antigravity quota unavailable'
}
