-----------------------LIBS-------------------------
-- local ac = require("acclient")               -- 3d/2d graphics and coordinates
-- local fs = require("filesystem").GetScript() -- File system
local ImGui = require("imgui")
local IM = ImGui ~= nil and ImGui.ImGui or {}
local views = require("utilitybelt.views")
local hud   = nil ---@type Hud|nil




----------------------CONFIG-----------------------
-- Window constraints
-- local minWindowSize = Vector2.new(450, 250)
-- local maxWindowSize = Vector2.new(800, 1000)





----------------------STATE------------------------
local scale = 0.05 ---@type number
local color = 0x11EECCAA ---@type number|nil (AARRGGBB)



----------------------LOGIC------------------------

local foo = 100


-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  local scaleInputChanged, scaleResult = IM.DragFloat("Scale", scale, 0.001, 0.001, 1)
  if scaleInputChanged then scale = scaleResult end

  local colorInputChanged, colorResult = IM.ColorPicker4("Color", IM.ColToVec4(color), ImGui.ImGuiColorEditFlags.AlphaBar)
  if colorInputChanged then color = IM.Vec4ToCol(colorResult) end

  --If you set an alpha in the PreRender it applies to all script windows, so reset it after rendering
  IM.PushStyleVar(ImGui.ImGuiStyleVar.Alpha, 1)
end

-- function OnRender2D()
-- end

-- Called before our window is registered
function OnPreRender()
  --Constrain resize dimensions
  -- ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);
  
  --Force a size / position in the center
  IM.SetWindowSize(Vector2.new(300, 300))
  IM.SetNextWindowPos(Vector2.new(IM.GetWindowViewport().Size.X/2-150, IM.GetWindowViewport().Size.Y/2-150))

  --Set an alpha (make sure to remove after Render)
  IM.PushStyleVar(ImGui.ImGuiStyleVar.Alpha, 0.5)
end





---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("MyScript")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  --Style
  hud.WindowSettings = ImGui.ImGuiWindowFlags.AlwaysAutoResize -- Size to fit
                    --  + ImGui.ImGuiWindowFlags.NoDecoration     -- Borderless
                    --  + ImGui.ImGuiWindowFlags.NoBackground     -- No BG

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
  if evt.NewState == ClientState.In_Game then Init()
  -- Dispose on log out
  elseif evt.NewState == ClientState.Logging_Out then Dispose() end
end)
-- ...or on script end
game.OnScriptEnd.Once(Dispose)
-- Start up if in game when the script loads
if game.State == ClientState.In_Game then Init() end
