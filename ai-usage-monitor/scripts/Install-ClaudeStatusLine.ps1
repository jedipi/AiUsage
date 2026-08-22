[CmdletBinding()]
param([string]$PluginRoot)

if ([string]::IsNullOrWhiteSpace($PluginRoot)) { $PluginRoot = Split-Path -Parent $PSScriptRoot }

$settingsPath = Join-Path $HOME '.claude\settings.json'
$settingsDirectory = Split-Path -Parent $settingsPath
New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
$settings = if (Test-Path -LiteralPath $settingsPath) { Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json } else { [pscustomobject]@{} }
$installedScript = Join-Path $env:LOCALAPPDATA 'AiUsage\Update-AiUsage.ps1'
New-Item -ItemType Directory -Path (Split-Path -Parent $installedScript) -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PluginRoot 'scripts\Update-AiUsage.ps1') -Destination $installedScript -Force
$statusLine = [pscustomobject]@{
    type = 'command'
    command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$($installedScript.Replace('\', '/'))`" -Source ClaudeStatus"
    padding = 0
}
if ($null -ne $settings.PSObject.Properties['statusLine'] -and $settings.statusLine.command -notlike '*Update-AiUsage.ps1*') {
    throw 'A different Claude statusLine is already configured. Merge it manually to avoid replacing your existing status line.'
}
if ($null -eq $settings.PSObject.Properties['statusLine']) { $settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine }
else { $settings.statusLine = $statusLine }
$temp = "$settingsPath.tmp"
$settings | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temp -Encoding utf8
Move-Item -LiteralPath $temp -Destination $settingsPath -Force
Write-Host "Claude status line installed in $settingsPath"
