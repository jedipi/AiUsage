[MeasureFiveHour]
Measure=Script
MinValue=0
MaxValue=100
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=fiveHour
Field=usedPercent
UpdateDivider=15

[MeasureWeekly]
Measure=Script
MinValue=0
MaxValue=100
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=weekly
Field=usedPercent
UpdateDivider=15

[MeasureReset]
Measure=Script
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=weekly
Field=resetAt
UpdateDivider=15

[MeasureTime]
Measure=Time
Format=%H:%M

[MeterCanvas]
Meter=Shape
X=0
Y=0
Shape=Rectangle 0,0,330,350,20 | Fill Color #Card# | Stroke Color 53,65,79,180 | StrokeWidth 1

[MeterProvider]
Meter=String
X=24
Y=22
FontFace=#FontFace#
FontSize=16
FontWeight=600
FontColor=#Accent#
AntiAlias=1
Text=#ProviderTitle#

[MeterSubtitle]
Meter=String
X=24
Y=49
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=QUOTA REMAINING

[MeterTime]
Meter=String
MeasureName=MeasureTime
X=306
Y=21
StringAlign=Right
FontFace=#FontFace#
FontSize=15
FontColor=#Text#
AntiAlias=1

[MeterFiveHourLabel]
Meter=String
X=24
Y=91
FontFace=#FontFace#
FontSize=10
FontColor=#Muted#
AntiAlias=1
Text=5 HOUR

[MeterFiveHourValue]
Meter=String
MeasureName=MeasureFiveHour
X=306
Y=86
StringAlign=Right
FontFace=#FontFace#
FontSize=15
FontColor=#Text#
AntiAlias=1
Text=%1%

[MeterFiveHourTrack]
Meter=Shape
X=24
Y=122
Shape=Rectangle 0,0,282,9,4.5 | Fill Color #Track# | StrokeWidth 0

[MeterFiveHourBar]
Meter=Bar
MeasureName=MeasureFiveHour
X=24
Y=122
W=282
H=9
BarOrientation=Horizontal
BarColor=#Accent#

[MeterWeeklyLabel]
Meter=String
X=24
Y=167
FontFace=#FontFace#
FontSize=10
FontColor=#Muted#
AntiAlias=1
Text=WEEKLY

[MeterWeeklyValue]
Meter=String
MeasureName=MeasureWeekly
X=306
Y=162
StringAlign=Right
FontFace=#FontFace#
FontSize=15
FontColor=#Text#
AntiAlias=1
Text=%1%

[MeterWeeklyTrack]
Meter=Shape
X=24
Y=198
Shape=Rectangle 0,0,282,9,4.5 | Fill Color #Track# | StrokeWidth 0

[MeterWeeklyBar]
Meter=Bar
MeasureName=MeasureWeekly
X=24
Y=198
W=282
H=9
BarOrientation=Horizontal
BarColor=#Accent#

[MeterResetLabel]
Meter=String
MeasureName=MeasureReset
X=24
Y=245
W=282
ClipString=1
FontFace=#FontFace#
FontSize=10
FontColor=#Muted#
AntiAlias=1
Text=RESET  %1

[MeterDivider]
Meter=Shape
X=24
Y=294
Shape=Line 0,0,282,0 | Stroke Color 53,65,79,160 | StrokeWidth 1

[MeterRefresh]
Meter=String
X=306
Y=316
StringAlign=Right
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=REFRESH
LeftMouseUpAction=#RefreshAction#
MouseOverAction=[!SetOption MeterRefresh FontColor "236,241,247,255"][!UpdateMeter MeterRefresh][!Redraw]
MouseLeaveAction=[!SetOption MeterRefresh FontColor "130,144,163,255"][!UpdateMeter MeterRefresh][!Redraw]

[MeterStatus]
Meter=String
X=24
Y=316
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=LOCAL CACHE
