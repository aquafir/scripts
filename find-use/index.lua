-----------------------LIBS-------------------------
-- local ac = require("acclient")               -- 3d/2d graphics and coordinates
-- local fs = require("filesystem").GetScript() -- File system
local ImGui = require("imgui")
local IM    = ImGui ~= nil and ImGui.ImGui or {}
local views = require("utilitybelt.views")
local hud   = nil ---@type Hud|nil




----------------------CONFIG-----------------------
---@type string[]
local find = { "Hieroglyph of ", "Ideograph of ", "Rune of " }
---@type WorldObject[]
local found = {}




----------------------STATE------------------------



----------------------LOGIC------------------------
---comment
---@param matchList string[]
---@param wo WorldObject
local IsMatch = function(matchList, wo)
  for key, value in pairs(matchList) do
    --print("Testing " .. tostring(key) .. ": " .. tostring(value))
    if wo.Name:find(value) then return true end
  end
  return false
end

local GetMatches = function()
  print("Searching...")
  found = {}

  --Removing pairs like below loses code hints, not sure that matters
  --for wo in game.Character.Inventory do
  for _, wo in pairs(game.Character.Inventory) do
    if IsMatch(find, wo) then
      print("Adding: " .. wo.Name)
      table.insert(found, wo)
    else
      print("Skipping: " .. wo.Name)
    end
  end
end

-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  if IM.Button("Find") then GetMatches() end
  IM.SameLine()
  if IM.Button("Use Found") then
    for _, wo in pairs(found) do
    -- for _, wo in pairs(game.Character.Inventory) do
      wo.Use()
      -- game.Actions.VendorAddToSellList(wo.Id)
      game.Actions.InvokeChat("/ub use " .. wo.Name)
      sleep(200)
    end
  end

  for _, wo in pairs(found) do
    IM.Text(wo.Name)
  end
end


---Automatically handle confirmation prompts
---@param evt ConfirmationRequestEventArgs
function Autoconfirm(evt)
  --print("Got Confirmation Popup: ", evt.Type, evt.Text)
  evt.ClickYes = true
end

---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("MyScript")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  -- Size to fit
  hud.WindowSettings = ImGui.ImGuiWindowFlags.AlwaysAutoResize
  -- Alternatively use a size range in prerender
  -- hud.OnPreRender.Add(OnPreRender)

  GetMatches()

  -- subscribe to events
  game.World.OnConfirmationRequest.Add(Autoconfirm)

  -- subscribe to hud events, with the handlers we defined above
  hud.OnRender.Add(OnHudRender)
end

function Dispose()
  -- Unsubscribe from events
  -- game.OnRender2D.Remove(OnRender2D)
  -- hud.OnPreRender.Remove(OnPreRender)
  game.World.OnConfirmationRequest.Remove(Autoconfirm)

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
