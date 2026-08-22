$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$codexSkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Codex\Codex.ini')
$claudeSkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Claude\Claude.ini')
$provider = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Provider.inc')
$lua = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Usage.lua')

if ($codexSkin -notmatch '(?m)^Provider=codex$') { throw 'Codex skin must use the codex provider.' }
if ($claudeSkin -notmatch '(?m)^Provider=claude$') { throw 'Claude skin must use the claude provider.' }
if ($provider -notmatch '(?ms)^\[MeasureReset\]\s*.*?^Window=weekly\s*$') { throw 'The shared reset measure must read the weekly window.' }
if (Test-Path -LiteralPath (Join-Path $root 'rainmeter\AIUsage\AIUsage.ini')) { throw 'The old combined skin must not be packaged.' }

if ($lua -match "gsub\('T',\s*' '\)") { throw "The reset formatter must not remove the T from weekday names such as 'Thu'." }

Write-Host 'Rainmeter split-skin binding test passed.'
