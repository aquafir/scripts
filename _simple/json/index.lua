local fs = require("filesystem").GetScript()

--You can use your own JSON library or the default MoonSharp one: https://www.moonsharp.org/additions.html
-- json.parse(jsonString) : Returns a table with the contents of the specified json string.
-- json.serialize(table) : Returns a json string with the contents of the specified table.
-- json.isNull(val) : Returns true if the value specified is a null read from a json
-- json.null() : Returns a special value which is a representation of a null in a json

--Create settings with annotations: https://github.com/LuaLS/lua-language-server/wiki/Annotations
---@class Settings
---@field On boolean
---@field Name string|nil
---@field Level number
local settings = {}
settings.On = true
settings['Name'] = "MyName"
settings.Level = 123

--Save settings
local encoded = json.serialize(settings)
fs.WriteText("out.json", encoded)
sleep(1000)

--Load settings back in
print('Loading serialized settings...')
local serialized = fs.ReadText("out.json")
print(serialized)

--Decode / print
print('Decoding serialized settings...')
---@type Settings
local decoded = json.parse(serialized)

print('Name: ' .. decoded.Name .. '  On: ' .. tostring(decoded.On) .. '  Level: ' .. decoded.Level)

