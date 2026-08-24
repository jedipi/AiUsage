param([string]$PackagePath)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($PackagePath)) { $PackagePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'dist\AIUsage_0.2.17.rmskin' }
$bytes = [System.IO.File]::ReadAllBytes($PackagePath)
if ($bytes.Length -lt 16) { throw 'Package is too short to contain a Rainmeter 4.5 footer.' }

$footerOffset = $bytes.Length - 16
$archiveLength = [BitConverter]::ToUInt64($bytes, $footerOffset)
$flags = $bytes[$footerOffset + 8]
$signature = [System.Text.Encoding]::ASCII.GetString($bytes, $footerOffset + 9, 7)
if ($signature -ne "RMSKIN`0") { throw 'Missing Rainmeter RMSKIN footer signature.' }
if ($archiveLength -ne $footerOffset) { throw "Footer archive length $archiveLength does not match ZIP length $footerOffset." }
if ($flags -ne 0) { throw "Unexpected Rainmeter package flags: $flags." }

$zipSignature = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 2)
if ($zipSignature -ne 'PK') { throw 'Package payload is not a ZIP archive.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($PackagePath)
try {
    $names = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    if ($names -notcontains 'RMSKIN.ini') { throw 'RMSKIN.ini is missing from the archive root.' }
    foreach ($entry in @(
        'Skins/AIUsage/Codex/Codex.ini',
        'Skins/AIUsage/Codex/Gauge.ini',
        'Skins/AIUsage/Claude/Claude.ini',
        'Skins/AIUsage/Claude/Gauge.ini',
        'Skins/AIUsage/Antigravity/Antigravity.ini',
        'Skins/AIUsage/Antigravity/Gauge.ini',
        'Skins/AIUsage/Launcher/Launcher.ini',
        'Skins/AIUsage/@Resources/Provider.inc',
        'Skins/AIUsage/@Resources/Gauge.inc',
        'Skins/AIUsage/@Resources/RefreshCodex.vbs')) {
        if ($names -notcontains $entry) { throw "Package entry is missing: $entry" }
    }
}
finally { $archive.Dispose() }

Write-Host 'Rainmeter package format test passed.'
