[MeasureFiveHour]
Measure=Script
MinValue=0
MaxValue=100
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=#PrimaryWindow#
Field=usedPercent
UpdateDivider=15

[MeasureWeekly]
Measure=Script
MinValue=0
MaxValue=100
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=#SecondaryWindow#
Field=usedPercent
UpdateDivider=15

[MeasureFiveHourReset]
Measure=Script
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=#PrimaryWindow#
Field=resetAt
UpdateDivider=15

[MeasureWeeklyReset]
Measure=Script
ScriptFile=#@#Usage.lua
Provider=#Provider#
Window=#SecondaryWindow#
Field=resetAt
UpdateDivider=15

[MeterCanvas]
Meter=Shape
X=0
Y=0
Shape=Rectangle 0,0,270,180,16 | Fill Color #Card# | Stroke Color 53,65,79,180 | StrokeWidth 1

; Keep the title bar aligned and styled like the other provider skin.
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

[MeterRefresh]
Meter=String
X=252
Y=17
StringAlign=Right
FontFace=#FontFace#
FontSize=9
FontColor=#Muted#
AntiAlias=1
Text=REFRESH
LeftMouseUpAction=#RefreshAction#
MouseOverAction=[!SetOption MeterRefresh FontColor "236,241,247,255"][!UpdateMeter MeterRefresh][!Redraw]
MouseLeaveAction=[!SetOption MeterRefresh FontColor "130,144,163,255"][!UpdateMeter MeterRefresh][!Redraw]

[MeterFiveHourCard]
Meter=Shape
X=5
Y=52
Shape=Rectangle 0,0,128,123,18 | Fill Color #GaugeCard# | StrokeWidth 0

[MeterWeeklyCard]
Meter=Shape
X=137
Y=52
Shape=Rectangle 0,0,128,123,18 | Fill Color #GaugeCard# | StrokeWidth 0

[MeterFiveHourTrack]
Meter=Roundline
X=28
Y=62
W=82
H=82
StartAngle=(Rad(135))
RotationAngle=(Rad(270))
LineStart=33
LineLength=41
LineWidth=8
LineColor=#Track#
Solid=1
AntiAlias=1

[MeterFiveHourGauge]
Meter=Roundline
MeasureName=MeasureFiveHour
X=28
Y=62
W=82
H=82
StartAngle=(Rad(135))
RotationAngle=(Rad(270))
LineStart=33
LineLength=41
LineWidth=8
LineColor=#GaugeFiveHourColor#
Solid=1
AntiAlias=1

[MeterWeeklyTrack]
Meter=Roundline
X=160
Y=62
W=82
H=82
StartAngle=(Rad(135))
RotationAngle=(Rad(270))
LineStart=33
LineLength=41
LineWidth=8
LineColor=#Track#
Solid=1
AntiAlias=1

[MeterWeeklyGauge]
Meter=Roundline
MeasureName=MeasureWeekly
X=160
Y=62
W=82
H=82
StartAngle=(Rad(135))
RotationAngle=(Rad(270))
LineStart=33
LineLength=41
LineWidth=8
LineColor=#GaugeWeeklyColor#
Solid=1
AntiAlias=1

[MeterFiveHourValue]
Meter=String
MeasureName=MeasureFiveHour
X=69
Y=90
StringAlign=Center
FontFace=#FontFace#
FontSize=18
FontWeight=600
FontColor=#GaugeFiveHourColor#
AntiAlias=1
Text=%1%

[MeterWeeklyValue]
Meter=String
MeasureName=MeasureWeekly
X=201
Y=90
StringAlign=Center
FontFace=#FontFace#
FontSize=18
FontWeight=600
FontColor=#GaugeWeeklyColor#
AntiAlias=1
Text=%1%

[MeterFiveHourLabel]
Meter=String
X=69
Y=130
StringAlign=Center
FontFace=#FontFace#
FontSize=9
FontWeight=600
FontColor=#GaugeFiveHourLabelColor#
AntiAlias=1
Text=#PrimaryLabel#

[MeterWeeklyLabel]
Meter=String
X=201
Y=130
StringAlign=Center
FontFace=#FontFace#
FontSize=9
FontWeight=600
FontColor=#GaugeWeeklyLabelColor#
AntiAlias=1
Text=#SecondaryLabel#

[MeterFiveHourReset]
Meter=String
MeasureName=MeasureFiveHourReset
X=69
Y=146
W=122
StringAlign=Center
ClipString=1
FontFace=#FontFace#
FontSize=7
FontColor=#Muted#
AntiAlias=1
Text=In %1

[MeterWeeklyReset]
Meter=String
MeasureName=MeasureWeeklyReset
X=201
Y=146
W=122
StringAlign=Center
ClipString=1
FontFace=#FontFace#
FontSize=7
FontColor=#Muted#
AntiAlias=1
Text=In %1
