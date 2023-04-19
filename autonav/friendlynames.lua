require("helpers")
local fs = require("filesystem").GetScript()

---@type { [number]: string } ---Decimal - friendly name pairs from: https://docs.google.com/spreadsheets/d/122xOw3IKCezaTDjC_hggWSVzYJ_9M_zUUtGEXkwNXfs
local names = nil

function loadNames()
    names={}

    if not fs.FileExists("dungeons.csv")  then
        print("Error loading names from dungeons.csv")
        return error
    end

    local count = 0
    local timer = os.time()
    for line in fs.ReadLines("dungeons.csv") do
        local s = split(line, "\t")
            if #s == 2 then 
            names[tonumber(s[1])] = s[2]
            count = count + 1
        end
    end
    timer = math.floor(os.difftime(os.time(), timer) * 1000)
    print("Landblock names loaded (" .. timer .. " ms): " .. count )
end

local NameHelper = {}

---Returns a friendly name for a land cell or a 4-digit hex
---@param cell number
---@return string
NameHelper.friendly = function(cell)
    --Smarter ways of doing this, but tries to get the standard top bytes
    if cell > 65536 then cell = math.floor(cell / 65536) end
    if names == nil then loadNames() end

    if names[cell] ~= nil then
        return names[cell]
    else
        --print("Missing " .. tostring(cell))
        return string.format("%04X", cell)
    end
end


return NameHelper
