$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$codexSkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Codex\Codex.ini')
$claudeSkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Claude\Claude.ini')
$antigravitySkin = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Antigravity\Antigravity.ini')
$codexGauge = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Codex\Gauge.ini')
$claudeGauge = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Claude\Gauge.ini')
$antigravityGauge = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\Antigravity\Gauge.ini')
$provider = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Provider.inc')
$gauge = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Gauge.inc')
$lua = Get-Content -Raw -LiteralPath (Join-Path $root 'rainmeter\AIUsage\@Resources\Usage.lua')
$codexHooks = Get-Content -Raw -LiteralPath (Join-Path $root 'hooks.json')
$claudeHooks = Get-Content -Raw -LiteralPath (Join-Path $root 'hooks\hooks.json')
$rainmeterInstaller = Get-Content -Raw -LiteralPath (Join-Path $root 'scripts\Install-Rainmeter.ps1')

if ($codexSkin -notmatch '(?m)^Provider=codex$') { throw 'Codex skin must use the codex provider.' }
if ($claudeSkin -notmatch '(?m)^Provider=claude$') { throw 'Claude skin must use the claude provider.' }
if ($antigravitySkin -notmatch '(?m)^Provider=antigravity$') { throw 'Antigravity skin must use the antigravity provider.' }
if ($codexSkin -match '(?m)^(OnRefreshAction|RefreshAction)=\["powershell\.exe"') { throw 'Codex refresh must not launch a visible PowerShell console directly.' }
if ($codexSkin -notmatch 'wscript\.exe.*RefreshCodex\.vbs') { throw 'Codex refresh must use the hidden WScript launcher.' }
if ($codexGauge -notmatch '(?m)^Provider=codex$') { throw 'Codex gauge skin must use the codex provider.' }
if ($claudeGauge -notmatch '(?m)^Provider=claude$') { throw 'Claude gauge skin must use the claude provider.' }
if ($antigravityGauge -notmatch '(?m)^Provider=antigravity$') { throw 'Antigravity gauge skin must use the antigravity provider.' }
if ($codexGauge -notmatch 'wscript\.exe.*RefreshCodex\.vbs') { throw 'Codex gauge refresh must use the hidden WScript launcher.' }
if ($codexGauge -notmatch '(?m)^@Include=#@#Gauge\.inc\r?$' -or $claudeGauge -notmatch '(?m)^@Include=#@#Gauge\.inc\r?$' -or $antigravityGauge -notmatch '(?m)^@Include=#@#Gauge\.inc\r?$') { throw 'All gauge skins must use the shared gauge include.' }
if ($codexHooks -match 'InstallRainmeter|Install-Rainmeter' -or $claudeHooks -match 'InstallRainmeter|Install-Rainmeter') { throw 'Plugin session hooks must not install Rainmeter on every session.' }
if ($rainmeterInstaller -notmatch '!ActivateConfig' -or $rainmeterInstaller -notmatch 'Start-Process') { throw 'The one-time Rainmeter installer must load the launcher and start Rainmeter when needed.' }
if ($provider -notmatch 'Shape=Rectangle 0,0,270,180,16') { throw 'Provider skins must use the compact 270x180 layout.' }
if ($gauge -notmatch 'Shape=Rectangle 0,0,270,180,16') { throw 'Gauge skins must use the compact 270x180 layout.' }
if ($provider -match '(?m)^\[MeterDivider\]') { throw 'The divider must be removed.' }
if ($provider -notmatch '(?ms)^\[MeterRefresh\]\s*.*?^X=252\s*.*?^Y=17\s*$') { throw 'Refresh must be aligned to the top right.' }
if ($gauge -notmatch '(?ms)^\[MeterProvider\]\s*.*?^X=18\s*.*?^Y=17\s*.*?^FontSize=14\s*.*?^FontWeight=600\s*.*?^Text=#ProviderTitle#$') { throw 'Gauge title bar must keep the provider title styling.' }
if ($gauge -notmatch '(?ms)^\[MeterSubtitle\]\s*.*?^X=18\s*.*?^Y=40\s*.*?^FontSize=8\s*.*?^Text=QUOTA REMAINING$') { throw 'Gauge title bar must include the quota subtitle.' }
if ($gauge -notmatch '(?ms)^\[MeterRefresh\]\s*.*?^X=252\s*.*?^Y=17\s*.*?^FontSize=9\s*.*?^Text=REFRESH$') { throw 'Gauge title bar must keep the refresh styling.' }
if ($provider -notmatch '(?ms)^\[MeasureFiveHourReset\]\s*.*?^Window=#PrimaryWindow#\s*.*?^Field=resetAt\s*$') { throw 'The primary reset must read the provider primary window.' }
if ($provider -notmatch '(?ms)^\[MeasureWeeklyReset\]\s*.*?^Window=#SecondaryWindow#\s*.*?^Field=resetAt\s*$') { throw 'The secondary reset must read the provider secondary window.' }
if ($provider -notmatch '(?ms)^\[MeterFiveHourReset\]\s*.*?^MeasureName=MeasureFiveHourReset\s*.*?^X=#PrimaryResetX#\s*.*?^W=#PrimaryResetWidth#\s*$') { throw 'The primary reset layout must be provider-configurable.' }
if ($provider -notmatch '(?ms)^\[MeterWeeklyReset\]\s*.*?^MeasureName=MeasureWeeklyReset\s*.*?^X=#SecondaryResetX#\s*.*?^W=#SecondaryResetWidth#\s*$') { throw 'The secondary reset layout must be provider-configurable.' }
if ($provider -notmatch '(?m)^Text=#PrimaryLabel#$' -or $provider -notmatch '(?m)^Text=#SecondaryLabel#$') { throw 'Provider row labels must be configurable.' }
if ([regex]::Matches($provider, '(?m)^Text=In %1$').Count -ne 2) { throw 'Both reset labels must start with In.' }
if ($provider -match '(?m)^\[MeasureTime\]|^\[MeterTime\]') { throw 'The time measure and meter must be removed.' }
if ($provider -match 'LOCAL CACHE') { throw 'The LOCAL CACHE label must not be present.' }
if ($gauge -notmatch '(?ms)^\[MeasureFiveHourReset\]\s*.*?^Window=#PrimaryWindow#\s*.*?^Field=resetAt\s*$') { throw 'The gauge primary reset must read the provider primary window.' }
if ($gauge -notmatch '(?ms)^\[MeasureWeeklyReset\]\s*.*?^Window=#SecondaryWindow#\s*.*?^Field=resetAt\s*$') { throw 'The gauge secondary reset must read the provider secondary window.' }
if ($gauge -notmatch '(?ms)^\[MeterFiveHourReset\]\s*.*?^MeasureName=MeasureFiveHourReset\s*.*?^Y=146\s*$') { throw 'The five-hour gauge reset must sit below its meter.' }
if ($gauge -notmatch '(?ms)^\[MeterWeeklyReset\]\s*.*?^MeasureName=MeasureWeeklyReset\s*.*?^Y=146\s*$') { throw 'The weekly gauge reset must sit below its meter.' }
if ([regex]::Matches($gauge, '(?m)^Text=In %1$').Count -ne 2) { throw 'Both gauge meters must show their reset time.' }
if ([regex]::Matches($gauge, '(?m)^Meter=Roundline$').Count -ne 4) { throw 'Gauge variant must use four Roundline meters for the two rings.' }
if ([regex]::Matches($gauge, '(?m)^Solid=1$').Count -ne 4) { throw 'Gauge Roundline meters must use Solid=1 to render arc bands instead of radial strokes.' }
if ($gauge -notmatch '(?ms)^\[MeterFiveHourGauge\]\s*.*?^MeasureName=MeasureFiveHour\s*.*?^StartAngle=\(Rad\(135\)\)\s*.*?^RotationAngle=\(Rad\(270\)\)\s*.*?^LineWidth=8\s*$') { throw 'Five-hour gauge ring binding is incorrect.' }
if ($gauge -notmatch '(?ms)^\[MeterWeeklyGauge\]\s*.*?^MeasureName=MeasureWeekly\s*.*?^StartAngle=\(Rad\(135\)\)\s*.*?^RotationAngle=\(Rad\(270\)\)\s*.*?^LineWidth=8\s*$') { throw 'Weekly gauge ring binding is incorrect.' }
if ($gauge -notmatch '(?m)^Text=#PrimaryLabel#$' -or $gauge -notmatch '(?m)^Text=#SecondaryLabel#$') { throw 'Gauge labels must be provider-configurable.' }
if ($gauge -notmatch '(?ms)^\[MeterFiveHourValue\]\s*.*?^Y=90\s*.*?^FontSize=18\s*.*?^Text=%1%$' -or $gauge -notmatch '(?ms)^\[MeterWeeklyValue\]\s*.*?^Y=90\s*.*?^FontSize=18\s*.*?^Text=%1%$') { throw 'Gauge percentage values must use the smaller centered text size.' }
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
if ($lua -notmatch 'SKIN:GetMeter\(meterName\)' -or $lua -notmatch 'MeterFiveHourGauge' -or $lua -notmatch 'MeterWeeklyGauge') { throw 'Lua must update gauge ring colors when quota values change.' }
if ($lua -notmatch "windowName == 'gemini'" -or $lua -notmatch "windowName == 'claudeGpt'") { throw 'Lua must map Antigravity model pools to the two display slots.' }
if ($codexSkin -notmatch '(?m)^PrimaryWindow=fiveHour$' -or $codexSkin -notmatch '(?m)^SecondaryWindow=weekly$' -or $codexSkin -notmatch '(?m)^PrimaryLabel=5H$' -or $codexSkin -notmatch '(?m)^SecondaryLabel=W$') { throw 'Codex bar labels and windows changed unexpectedly.' }
if ($claudeSkin -notmatch '(?m)^PrimaryWindow=fiveHour$' -or $claudeSkin -notmatch '(?m)^SecondaryWindow=weekly$' -or $claudeSkin -notmatch '(?m)^PrimaryLabel=5H$' -or $claudeSkin -notmatch '(?m)^SecondaryLabel=W$') { throw 'Claude bar labels and windows changed unexpectedly.' }
if ($antigravitySkin -notmatch '(?m)^PrimaryWindow=gemini$' -or $antigravitySkin -notmatch '(?m)^SecondaryWindow=claudeGpt$' -or $antigravitySkin -notmatch '(?m)^PrimaryLabel=GEMINI$' -or $antigravitySkin -notmatch '(?m)^SecondaryLabel=CLAUDE/GPT$') { throw 'Antigravity bar skin must show Gemini and Claude/GPT model pools.' }
if ($antigravityGauge -notmatch '(?m)^PrimaryWindow=gemini$' -or $antigravityGauge -notmatch '(?m)^SecondaryWindow=claudeGpt$' -or $antigravityGauge -notmatch '(?m)^PrimaryLabel=GEMINI$' -or $antigravityGauge -notmatch '(?m)^SecondaryLabel=CLAUDE/GPT$') { throw 'Antigravity gauge skin must show Gemini and Claude/GPT model pools.' }
if (Test-Path -LiteralPath (Join-Path $root 'rainmeter\AIUsage\AIUsage.ini')) { throw 'The old combined skin must not be packaged.' }

if ($lua -match "gsub\('T',\s*' '\)") { throw "The reset formatter must not remove the T from weekday names such as 'Thu'." }

Write-Host 'Rainmeter split-skin binding test passed.'
