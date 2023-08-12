-----------------------LIBS-------------------------
local IM           = require("imgui")
local ImGui        = IM ~= nil and IM.ImGui or {}
local views        = require("utilitybelt.views")
local hud          = nil ---@type Hud|nil
local pf = require('propfilter')

---@type PropFilter[]
local filters = {}
table.insert(filters, pf.new(PropType.String):SetFilter('', game.Character.Weenie))
table.insert(filters, pf.new(PropType.Bool):SetFilter('', game.Character.Weenie))
table.insert(filters, pf.new(PropType.Int))
table.insert(filters, pf.new(PropType.Float))
table.insert(filters, pf.new(PropType.Int64))
table.insert(filters, pf.new(PropType.DataId))
table.insert(filters, pf.new(PropType.InstanceId))


-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  for filter in filters do
    filter:Draw()
  end
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


return PropFilter
