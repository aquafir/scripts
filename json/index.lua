-----------------------LIBS-------------------------
local fs = require("filesystem").GetScript() -- File system
local json = require("json.lua")
local encoded = json.encode({ 1, 2, 3, { x = 10 } }) -- Returns '[1,2,3,{"x":10}]'
fs.WriteText("out.json", encoded)

local decoded = json.decode('[1,2,3,{"x":10}]')

for index, value in ipairs(decoded) do
  print(index, value)  
end

