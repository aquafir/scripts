-----------------------LIBS-------------------------
-- local ac = require("acclient")               -- 3d/2d graphics and coordinates
-- local fs = require("filesystem").GetScript() -- File system
local IM    = require("imgui")
local ImGui = IM ~= nil and IM.ImGui or {}
local views = require("utilitybelt.views")
local hud   = nil ---@type Hud|nil




----------------------CONFIG-----------------------




----------------------STATE------------------------
local typeProps = {}
for index, value in ipairs(ObjectType.GetValues()) do table.insert(typeProps, value) end
local intProps = {}
for index, value in ipairs(IntId.GetValues()) do table.insert(intProps, value) end
local stringProps = {}
for index, value in ipairs(StringId.GetValues()) do table.insert(stringProps, value) end

---@enum PropType
local PropType = {
  Bool = 1,
  String = 2,
  Int = 3,
  Int64 = 4,
  Float = 5,
  DataId = 6,
  InstanceId = 7,
  ObjectType = 8,
  ObjectClass = 9,
}
game.Character.Weenie.HasValue()
---@class PropertyFilter
---@field Type PropType --
---@field FilterText string
---@field FilteredProperties string[]
local PropertyFilter = {
  --Defaults
  Type = PropType.Bool,
  FilterText = "",
  FilteredProperties = {}
}
---@return PropertyFilter PropertyFilter -- A new PropertyFilter instance
function PropertyFilter:new(o)
  o = o or {} -- create object if user doesn't provide
  setmetatable(o, self)
  self.__index = self

  return o
end

local test = PropertyFilter:new()


print(tostring(test.Type))
----------------------LOGIC------------------------




-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  --ImGui.Combo
end
-- Called before our window is registered
function OnPreRender()
end

---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("MyScript")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  --Style
  hud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize -- Size to fit
  --  + IM.ImGuiWindowFlags.NoDecoration     -- Borderless
  --  + IM.ImGuiWindowFlags.NoBackground     -- No BG

  -- Alternatively use a size range in prerender
  hud.OnPreRender.Add(OnPreRender)
  -- subscribe to events
  -- game.OnRender2D.Add(OnRender2D)

  -- subscribe to hud events, with the handlers we defined above
  hud.OnRender.Add(OnHudRender)
end

function Dispose()
  -- Unsubscribe from events
  -- game.OnRender2D.Remove(OnRender2D)
  -- hud.OnPreRender.Remove(OnPreRender)

  -- Dispose of things like D3DObjs
  -- if renderedObj ~= nil then renderedObj.Dispose() end
  -- renderedObj = nil

  -- Destroy hud
  if hud ~= nil then hud.Dispose() end
end

-------------------------START------------------------------
game.OnStateChanged.Add(function(evt)
  -- Start on login
  if evt.NewState == ClientState.In_Game then
    Init()
    -- Dispose on log out
  elseif evt.NewState == ClientState.Logging_Out then
    Dispose()
  end
end)
-- ...or on script end
game.OnScriptEnd.Once(Dispose)
-- Start up if in game when the script loads
if game.State == ClientState.In_Game then Init() end
