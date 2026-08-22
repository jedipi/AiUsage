[CmdletBinding()]
param([string]$SkinsDirectory = (Join-Path $HOME 'Documents\Rainmeter\Skins'))

$source = Join-Path (Split-Path -Parent $PSScriptRoot) 'rainmeter\AIUsage'
$destination = Join-Path $SkinsDirectory 'AIUsage'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Update-AiUsage.ps1') -Destination (Join-Path $destination '@Resources\Update-AiUsage.ps1') -Force
Write-Host "Rainmeter skin installed to $destination. Refresh Rainmeter, then load AIUsage\AIUsage.ini."
