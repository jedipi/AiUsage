[CmdletBinding()]
param([string]$InputJson)

$ErrorActionPreference = 'SilentlyContinue'
if ([string]::IsNullOrWhiteSpace($InputJson) -and [Console]::IsInputRedirected) {
    $InputJson = [Console]::In.ReadToEnd()
}

if (-not [string]::IsNullOrWhiteSpace($InputJson)) {
    try {
        $payload = $InputJson | ConvertFrom-Json
        if ($null -ne $payload.quota) {
            $collector = Join-Path $PSScriptRoot 'Update-AiUsage.ps1'
            & $collector -Source AntigravityStatus -InputJson $InputJson *> $null
        }
    }
    catch { }
}

# Antigravity hooks require JSON output. The current hook payload does not
# include quota data; the status-line adapter is the authoritative refresh path.
Write-Output '{}'
