[CmdletBinding()]
param(
    [string]$PluginRoot,
    [string]$SettingsPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($PluginRoot)) { $PluginRoot = Split-Path -Parent $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($SettingsPath)) { $SettingsPath = Join-Path $HOME '.gemini\antigravity-cli\settings.json' }

$settingsDirectory = Split-Path -Parent $SettingsPath
New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
$settings = if (Test-Path -LiteralPath $SettingsPath) {
    Get-Content -Raw -LiteralPath $SettingsPath | ConvertFrom-Json
}
else {
    [pscustomobject]@{}
}

$installedDirectory = Join-Path $env:LOCALAPPDATA 'AiUsage'
New-Item -ItemType Directory -Path $installedDirectory -Force | Out-Null
foreach ($file in @('Update-AiUsage.ps1', 'AntigravityStatusLine.ps1', 'AntigravityHook.ps1')) {
    Copy-Item -LiteralPath (Join-Path $PluginRoot "scripts\$file") -Destination (Join-Path $installedDirectory $file) -Force
}

$installedScript = Join-Path $installedDirectory 'AntigravityStatusLine.ps1'
$statusLine = [pscustomobject]@{
    type = 'command'
    command = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$($installedScript.Replace('\', '/'))`""
    padding = 0
    stack_with_default = $true
}

$statusLineProperty = $settings.PSObject.Properties['statusLine']
if ($null -ne $statusLineProperty) {
    $existingCommand = [string]$settings.statusLine.command
    if (-not [string]::IsNullOrWhiteSpace($existingCommand) -and $existingCommand -notlike '*AntigravityStatusLine.ps1*') {
        throw 'A different Antigravity statusLine is already configured. Merge the generated command manually to avoid replacing your existing status line.'
    }
    $settings.statusLine = $statusLine
}
else {
    $settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine
}

$temp = "$SettingsPath.tmp"
$settings | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temp -Encoding utf8
Move-Item -LiteralPath $temp -Destination $SettingsPath -Force
Write-Host "Antigravity status line installed in $SettingsPath"
