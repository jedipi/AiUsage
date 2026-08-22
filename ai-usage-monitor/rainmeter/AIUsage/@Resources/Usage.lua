local values = {}

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
    provider = SELF:GetOption('Provider')
    window = SELF:GetOption('Window')
    field = SELF:GetOption('Field')
end

function Update()
    readCache()
    local value = values[provider .. '.' .. window .. '.' .. field]
    if field == 'usedPercent' then
        local number = tonumber(value) or 0
        return math.max(0, math.min(100, number))
    end
    if not value or value == '' then return 'NO DATA' end
    return value
end
