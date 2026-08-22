[CmdletBinding()]
param([string]$OutputDirectory)

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $root 'dist' }
$staging = Join-Path $env:TEMP ("ai-usage-rmskin-" + [guid]::NewGuid())
try {
    $skinDestination = Join-Path $staging 'Skins\AIUsage'
    New-Item -ItemType Directory -Path $skinDestination -Force | Out-Null
    Copy-Item -Path (Join-Path $root 'rainmeter\AIUsage\*') -Destination $skinDestination -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $root 'scripts\Update-AiUsage.ps1') -Destination (Join-Path $skinDestination '@Resources\Update-AiUsage.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $root 'rainmeter\RMSKIN.ini') -Destination (Join-Path $staging 'RMSKIN.ini')
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $zipPath = Join-Path $OutputDirectory 'AIUsage_0.2.9.zip'
    $packagePath = Join-Path $OutputDirectory 'AIUsage_0.2.9.rmskin'
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    if (Test-Path -LiteralPath $packagePath) { Remove-Item -LiteralPath $packagePath -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath -CompressionLevel Optimal

    # Rainmeter 4.5 PackageFooter is exactly 16 bytes: the original ZIP size
    # as a little-endian 64-bit integer, one flags byte, then "RMSKIN\0".
    $zipLength = (Get-Item -LiteralPath $zipPath).Length
    $stream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $writer = New-Object System.IO.BinaryWriter($stream, [System.Text.Encoding]::ASCII, $true)
        try {
            $writer.Write([UInt64]$zipLength)
            $writer.Write([byte]0)
            $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RMSKIN`0"))
        }
        finally { $writer.Dispose() }
    }
    finally { $stream.Dispose() }
    Move-Item -LiteralPath $zipPath -Destination $packagePath
    Write-Host "Created $packagePath"
}
finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
