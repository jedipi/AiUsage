local values = {}

local function quotaColor(percent)
    if percent >= 90 then return '46,204,113,255' end     -- green
    if percent >= 80 then return '154,205,50,255' end    -- lime
    if percent >= 70 then return '255,210,30,255' end    -- yellow
    if percent >= 40 then return '255,152,0,255' end     -- orange
    return '255,77,79,255'                               -- red
end

local function barMeterName(providerName, windowName)
    if windowName == 'fiveHour' or windowName == 'gemini' then return 'MeterFiveHourBar' end
    if windowName == 'weekly' or windowName == 'claudeGpt' then return 'MeterWeeklyBar' end
    return nil
end

local function gaugeMeterName(windowName)
    if windowName == 'fiveHour' or windowName == 'gemini' then return 'MeterFiveHourGauge' end
    if windowName == 'weekly' or windowName == 'claudeGpt' then return 'MeterWeeklyGauge' end
    return nil
end

local function gaugeValueMeterName(windowName)
    if windowName == 'fiveHour' or windowName == 'gemini' then return 'MeterFiveHourValue' end
    if windowName == 'weekly' or windowName == 'claudeGpt' then return 'MeterWeeklyValue' end
    return nil
end

local function setMeterOption(meterName, option, value)
    if meterName and SKIN:GetMeter(meterName) then
        SKIN:Bang('!SetOption', meterName, option, value)
        SKIN:Bang('!UpdateMeter', meterName)
    end
end

local function readCache()
    values = {}
    local base = os.getenv('LOCALAPPDATA')
    if not base then return end
    local file = io.open(base .. '\\AiUsage\\usage.cache', 'r')
    if not file then return end
    for line in file:lines() do
        local key, value = line:match('^([^=]+)=(.*)$')
        if key then values[key] = value end
    end
    file:close()
end

function Initialize()
end

function Update()
    local provider = SELF:GetOption('Provider')
    local window = SELF:GetOption('Window')
    local field = SELF:GetOption('Field')
    readCache()
    local value = values[provider .. '.' .. window .. '.' .. field]
    if field == 'usedPercent' then
        local number = tonumber(value) or 0
        local meter = barMeterName(provider, window)
        if meter then
            setMeterOption(meter, 'BarColor', quotaColor(number))
        end
        local gauge = gaugeMeterName(window)
        setMeterOption(gauge, 'LineColor', quotaColor(number))
        setMeterOption(gaugeValueMeterName(window), 'FontColor', quotaColor(number))
        return math.max(0, math.min(100, number))
    end
    if not value or value == '' then return 'NO DATA' end
    return value
end
