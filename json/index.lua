-----------------------LIBS-------------------------
local fs = require("filesystem").GetScript()
local json = require("json.lua")

--Create settings
local settings = {}
settings.On = true
settings['Name'] = "MyName"
settings.Level = 123

--Save settings
local encoded = json.encode(settings)
fs.WriteText("out.json", encoded)
sleep(1000)

--Load settings back in
print('Loading serialized settings...')
local serialized = fs.ReadText("out.json")
print(serialized)

--Decode / print
print('Decoding serialized settings...')
local decoded = json.decode(serialized)

for index, value in pairs(decoded) do
  print(index, value)  
end

