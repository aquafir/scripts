-----------------------LIBS-------------------------
local IM             = require("imgui")
local ImGui          = IM ~= nil and IM.ImGui or {}
local views          = require("utilitybelt.views")
local hud            = nil ---@type Hud|nil

---------------------STATE-------------------------
--Gate input
local lastShown      = 0
local toggleInterval = 0

----------------------LOGIC------------------------
function CheckInput()
  --Check for first/repeat presses
  if ImGui.IsKeyPressed(IM.ImGuiKey.D, false) then
    print('D first pressed')
  end
  if ImGui.IsKeyPressed(IM.ImGuiKey.D, true) then
    print('D repeating')
  end

  --Mouse
  if ImGui.IsMouseClicked(IM.ImGuiMouseButton.Middle, false) then
    print('MiddleMouse first pressed')
    ToggleHud()
  end
  if ImGui.IsMouseClicked(IM.ImGuiMouseButton.Middle, true) then
    local pos = ImGui.GetMousePos()
    print('Mouse is at ' .. pos.X .. ', ' .. pos.Y)
  end

  --Toggle visibility of the HUD
  if ImGui.IsKeyPressed(IM.ImGuiKey.Space, false) and ImGui.IsKeyDown(IM.ImGuiKey.ModAlt) then
    ToggleHud()
  end
end

function ToggleHud()
  if os.difftime(os.time(), lastShown) > toggleInterval then
    lastShown = os.time()
    print(lastShown)
    print(hud.Visible)
    if hud.Visible ~= true then
      print("Opening HUD!")
      hud.Visible = true
    else
      print("Closing HUD!")
      hud.Visible = false
    end
  end
end

-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  ImGui.Text("Hello")

  -- ImGui.mo
end



---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("Input")
  -- True if you want it to start visible, false invisible
  hud.Visible = false
  hud.ShowInBar = false

  --Style
  hud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize -- Size to fit

  --ImGui input won't work through game events
  game.OnRender2D.Add(CheckInput)

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
