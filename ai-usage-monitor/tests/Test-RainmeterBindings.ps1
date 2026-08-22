$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$codexSkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Codex\Codex.ini')
$claudeSkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Claude\Claude.ini')
$provider = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Provider.inc')
$lua = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Usage.lua')

if ($codexSkin -notmatch '(?m)^Provider=codex$') { throw 'Codex skin must use the codex provider.' }
if ($claudeSkin -notmatch '(?m)^Provider=claude$') { throw 'Claude skin must use the claude provider.' }
if ($codexSkin -match '(?m)^(OnRefreshAction|RefreshAction)=\["powershell\.exe"') { throw 'Codex refresh must not launch a visible PowerShell console directly.' }
if ($codexSkin -notmatch 'wscript\.exe.*RefreshCodex\.vbs') { throw 'Codex refresh must use the hidden WScript launcher.' }
if ($provider -notmatch 'Shape=Rectangle 0,0,270,220,16') { throw 'Provider skins must use the compact 270x220 layout.' }
if ($provider -notmatch '(?ms)^\[MeterDivider\]\s*.*?^Y=180\s*$') { throw 'The divider must sit close below the weekly bar.' }
if ($provider -notmatch '(?ms)^\[MeasureFiveHourReset\]\s*.*?^Window=fiveHour\s*.*?^Field=resetAt\s*$') { throw 'The five-hour reset must read the five-hour window.' }
if ($provider -notmatch '(?ms)^\[MeasureWeeklyReset\]\s*.*?^Window=weekly\s*.*?^Field=resetAt\s*$') { throw 'The weekly reset must read the weekly window.' }
if ($provider -notmatch '(?ms)^\[MeterFiveHourReset\]\s*.*?^MeasureName=MeasureFiveHourReset\s*$') { throw 'The five-hour reset must be placed on the five-hour row.' }
if ($provider -notmatch '(?ms)^\[MeterWeeklyReset\]\s*.*?^MeasureName=MeasureWeeklyReset\s*$') { throw 'The weekly reset must be placed on the weekly row.' }
if ($provider -notmatch '(?m)^Text=5H$') { throw 'The five-hour label must be 5H.' }
if ($provider -notmatch '(?m)^Text=W$') { throw 'The weekly label must be W.' }
if ([regex]::Matches($provider, '(?m)^Text=In %1$').Count -ne 2) { throw 'Both reset labels must start with In.' }
if ($provider -match '(?m)^\[MeasureTime\]|^\[MeterTime\]') { throw 'The time measure and meter must be removed.' }
if ($provider -match 'LOCAL CACHE') { throw 'The LOCAL CACHE label must not be present.' }
foreach ($color in @('255,77,79,255', '255,152,0,255', '255,210,30,255', '154,205,50,255', '46,204,113,255')) {
    if ($lua -notmatch [regex]::Escape($color)) { throw "Missing quota color $color." }
}
$colorRules = @(
    "if percent >= 90 then return '46,204,113,255'",
    "if percent >= 80 then return '154,205,50,255'",
    "if percent >= 70 then return '255,210,30,255'",
    "if percent >= 40 then return '255,152,0,255'",
    "return '255,77,79,255'"
)
foreach ($rule in $colorRules) {
    if ($lua -notmatch [regex]::Escape($rule)) { throw "Unexpected quota color rule: $rule" }
}
if (Test-Path -LiteralPath (Join-Path $root 'rainmeter\AIUsage\AIUsage.ini')) { throw 'The old combined skin must not be packaged.' }

if ($lua -match "gsub\('T',\s*' '\)") { throw "The reset formatter must not remove the T from weekday names such as 'Thu'." }

Write-Host 'Rainmeter split-skin binding test passed.'
