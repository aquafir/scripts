-----------------------LIBS-------------------------
local ac    = require("acclient") -- 3d/2d graphics and coordinates
local IM    = require("imgui")
local ImGui = IM ~= nil and IM.ImGui or {}
local views = require("utilitybelt.views")
local hud   = nil ---@type Hud|nil


----------------------CONFIG-----------------------
local animationInterval = 1000


----------------------STATE------------------------
local selected = 1
local animations = {}
for key, value in ipairs(ac.PScriptType.GetValues()) do
  animations[key]=value
end


----------------------LOGIC------------------------
function PlayAll()
  --TODO: loop through enums
  for key, value in ipairs(ac.PScriptType.GetValues()) do
    --print(key, value)
    print("Playing script ", value)
    selected = key
    ac.DecalD3D.PlayObjectScript(AnimationTarget(), key, 1)
    sleep(animationInterval)
  end
end

--Use whatever the player has selected defaulting to the player
function AnimationTarget() 
  --print(tostring(game.World.Selected))
  if game.World.Selected ~= nil then
    return game.World.Selected.Id
  end
  return game.CharacterId
end

-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  if ImGui.Button("Play All") then PlayAll() end

  local valueChanged, newValue = ImGui.Combo("Script", selected - 1, animations, #animations)
  if valueChanged then 
    selected = newValue + 1
    ac.DecalD3D.PlayObjectScript(AnimationTarget(), ac.PScriptType.PS_AttribDownYellow, 1)
    print("Playing ", animations[selected],  " -- ", selected) 
  end
end


-- Called before our window is registered
function OnPreRender()
  --Constrain resize dimensions
  -- ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);
end

---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("Script Player")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  --Style
  hud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize -- Size to fit

  -- Alternatively use a size range in prerender
  hud.OnPreRender.Add(OnPreRender)

  -- subscribe to hud events, with the handlers we defined above
  hud.OnRender.Add(OnHudRender)
end

function Dispose()
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
