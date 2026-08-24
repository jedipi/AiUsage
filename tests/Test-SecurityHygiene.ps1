$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$gitignorePath = Join-Path $root '.gitignore'
if (-not (Test-Path -LiteralPath $gitignorePath)) { throw '.gitignore is required.' }
$gitignore = Get-Content -Raw -LiteralPath $gitignorePath
foreach ($pattern in @('.env', '*.key', '*.pem', '*.p12', '*.pfx', 'credentials*.json', 'secrets*.json', 'usage.json', 'usage.cache', '*.log')) {
    if ($gitignore -notmatch "(?m)^$([regex]::Escape($pattern))$") { throw ".gitignore must exclude $pattern." }
}

$documentationPaths = @(
    (Join-Path $root 'AGENTS.md'),
    (Join-Path $root 'README.md')
) + @(Get-ChildItem -LiteralPath (Join-Path $root 'doc') -Filter '*.md' -File | Select-Object -ExpandProperty FullName)

foreach ($path in $documentationPaths) {
    $text = Get-Content -Raw -LiteralPath $path
    if ($text -match '(?i)C:\\Users\\(?!<)[^\\\s]+\\') {
        throw "Documentation contains a concrete Windows user path: $path"
    }
    foreach ($match in [regex]::Matches($text, '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b')) {
        if ($match.Value -notmatch '(?i)@(?:example\.com|example\.org|users\.noreply\.github\.com)$') {
            throw "Documentation contains a non-placeholder email address: $path"
        }
    }
}

Write-Host 'Security hygiene test passed.'

exit 0
