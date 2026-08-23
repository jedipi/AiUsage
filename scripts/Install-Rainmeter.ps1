[CmdletBinding()]
param([string]$SkinsDirectory = (Join-Path $HOME 'Documents\Rainmeter\Skins'))

$ErrorActionPreference = 'Stop'
$source = Join-Path (Split-Path -Parent $PSScriptRoot) 'rainmeter\AIUsage'
$destination = Join-Path $SkinsDirectory 'AIUsage'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Update-AiUsage.ps1') -Destination (Join-Path $destination '@Resources\Update-AiUsage.ps1') -Force

$rainmeterProcess = Get-Process -Name Rainmeter -ErrorAction SilentlyContinue | Select-Object -First 1
$rainmeterPath = $null
if ($rainmeterProcess) {
    try { $rainmeterPath = $rainmeterProcess.Path } catch { $rainmeterPath = $null }
}

if (-not $rainmeterPath) {
    $rainmeterCandidates = @()
    if ($env:ProgramFiles) { $rainmeterCandidates += Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe' }
    if (${env:ProgramFiles(x86)}) { $rainmeterCandidates += Join-Path ${env:ProgramFiles(x86)} 'Rainmeter\Rainmeter.exe' }
    $rainmeterCandidates += 'D:\Program Files\Rainmeter\Rainmeter.exe'
    $rainmeterPath = $rainmeterCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $rainmeterPath) {
    Write-Warning "TokenMeter skins were installed to $destination, but Rainmeter was not found."
    return
}

if (-not $rainmeterProcess) {
    Start-Process -FilePath $rainmeterPath | Out-Null
    Start-Sleep -Milliseconds 1000
}

$null = & $rainmeterPath '!RefreshApp'
$null = & $rainmeterPath '!ActivateConfig' 'AIUsage\Launcher' 'Launcher.ini'
Write-Host "TokenMeter Rainmeter skins installed and loaded from $destination."
