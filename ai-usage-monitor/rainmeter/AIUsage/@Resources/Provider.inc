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

[MeasureFiveHourReset]
Measure=Script
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=fiveHour
Field=resetAt
UpdateDivider=15

[MeasureWeeklyReset]
Measure=Script
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=weekly
Field=resetAt
UpdateDivider=15

[MeterCanvas]
Meter=Shape
X=0
Y=0
Shape=Rectangle 0,0,270,220,16 | Fill Color #Card# | Stroke Color 53,65,79,180 | StrokeWidth 1

[MeterProvider]
Meter=String
X=18
Y=17
FontFace=#FontFace#
FontSize=14
FontWeight=600
FontColor=#Accent#
AntiAlias=1
Text=#ProviderTitle#

[MeterSubtitle]
Meter=String
X=18
Y=40
FontFace=#FontFace#
FontSize=8
FontColor=#Muted#
AntiAlias=1
Text=QUOTA REMAINING

[MeterFiveHourLabel]
Meter=String
X=18
Y=69
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=5H

[MeterFiveHourReset]
Meter=String
MeasureName=MeasureFiveHourReset
X=46
Y=69
W=142
ClipString=1
FontFace=#FontFace#
FontSize=8
FontColor=#Muted#
AntiAlias=1
Text=In %1

[MeterFiveHourValue]
Meter=String
MeasureName=MeasureFiveHour
X=252
Y=65
StringAlign=Right
FontFace=#FontFace#
FontSize=13
FontColor=#Text#
AntiAlias=1
Text=%1%

[MeterFiveHourTrack]
Meter=Shape
X=18
Y=96
Shape=Rectangle 0,0,234,7,3.5 | Fill Color #Track# | StrokeWidth 0

[MeterFiveHourBar]
Meter=Bar
MeasureName=MeasureFiveHour
X=18
Y=96
W=234
H=7
BarOrientation=Horizontal
BarColor=#Accent#

[MeterWeeklyLabel]
Meter=String
X=18
Y=130
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=W

[MeterWeeklyReset]
Meter=String
MeasureName=MeasureWeeklyReset
X=38
Y=130
W=142
ClipString=1
FontFace=#FontFace#
FontSize=8
FontColor=#Muted#
AntiAlias=1
Text=In %1

[MeterWeeklyValue]
Meter=String
MeasureName=MeasureWeekly
X=252
Y=126
StringAlign=Right
FontFace=#FontFace#
FontSize=13
FontColor=#Text#
AntiAlias=1
Text=%1%

[MeterWeeklyTrack]
Meter=Shape
X=18
Y=157
Shape=Rectangle 0,0,234,7,3.5 | Fill Color #Track# | StrokeWidth 0

[MeterWeeklyBar]
Meter=Bar
MeasureName=MeasureWeekly
X=18
Y=157
W=234
H=7
BarOrientation=Horizontal
BarColor=#Accent#

[MeterDivider]
Meter=Shape
X=18
Y=180
Shape=Line 0,0,234,0 | Stroke Color 53,65,79,160 | StrokeWidth 1

[MeterRefresh]
Meter=String
X=252
Y=198
StringAlign=Right
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=REFRESH
LeftMouseUpAction=#RefreshAction#
MouseOverAction=[!SetOption MeterRefresh FontColor "236,241,247,255"][!UpdateMeter MeterRefresh][!Redraw]
MouseLeaveAction=[!SetOption MeterRefresh FontColor "130,144,163,255"][!UpdateMeter MeterRefresh][!Redraw]
