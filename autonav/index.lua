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




-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  local scaleInputChanged, scaleResult = IM.DragFloat("Scale", scale, 0.001, 0.001, 1)
  if scaleInputChanged then scale = scaleResult end

  local colorInputChanged, colorResult = IM.ColorPicker4("Color", IM.ColToVec4(color), ImGui.ImGuiColorEditFlags.AlphaBar)
  if colorInputChanged then color = IM.Vec4ToCol(colorResult) end
end

-- function OnRender2D()
-- end

-- Called before our window is registered
-- function OnPreRender()
--   ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);
-- end





---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("MyScript")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  -- Size to fit
  hud.WindowSettings = ImGui.ImGuiWindowFlags.AlwaysAutoResize
  -- Alternatively use a size range in prerender
  -- hud.OnPreRender.Add(OnPreRender)

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




local helpers = require("helpers")
local ac = require("acclient")
local vtnav = require("vtnavigation")
local namer = require("friendlynames")
local fs = require("filesystem").GetScript()

---Tries to load a nav based on landblock.
---@param force boolean Forces creation and load
function TryLoadNav(force)
  local location = namer.friendly(ac.Coordinates.Me.LandCell)
  local navName = "__" .. location
  if force then
    game.Actions.InvokeChat("/vt nav load " .. navName)
    return
  end

  --If not forced look for the nav
  local navFiles = vtnav.GetNavFiles(navName)

  if navFiles == nil then
    print("Error finding nav files")
    return
  end

  for index, value in pairs(navFiles) do
    if value:find(navName) then
      game.Actions.InvokeChat("/vt nav load " .. navName)
    end
  end
end

function IsActive()
  if not fs.FileExists("blacklist.txt") then
    print("Creating blacklistlist.txt")
    fs.WriteText("blacklist.txt", "")
  end
  -- if not fs.FileExists("whitelist.txt") then print("Creating whitelist.txt") fs.WriteText("whitelist.txt", "") end

  -- for _, value in ipairs(fs.ReadLines("blacklist.txt")) do table.insert(blacklist, case_insensitive_pattern(value)) end
  -- for _, value in ipairs(fs.ReadLines("whitelist.txt")) do table.insert(whitelist, case_insensitive_pattern(value)) end
  for _, name in ipairs(fs.ReadLines("blacklist.txt")) do
    if game.Character.Weenie.Name:find(case_insensitive_pattern(name)) then
      print("Name blacklisted by " .. name)
      return false
    end
  end
  -- for _, name in ipairs(fs.ReadLines("whitelist.txt")) do
  --   if game.Character.Weenie.Name:find(case_insensitive_pattern(name)) then
  --     print("Name whitelisted by " .. name)
  --     return true
  --   end
  -- end

  -- print(#blacklist .. " blacklisted names")
  --print(#whitelist .. " whitelisted names")
  return true
end

---@param evt EventArgs
function PortalExit(evt)
  TryLoadNav(false)
end

---comment
---@param evt ChatInputEventArgs
function OnCommand(evt)
  if evt.Text == "/autonav" then
    evt.Eat = true
    TryLoadNav(true)
  end
end

function Init()
  --Command always available
  game.World.OnChatInput.Add(ChatCommand)

  if IsActive() then
    game.Character.OnPortalSpaceExited.Add(PortalExit)
    --  else print("AutoNav not active for this character")
  end
end

function Dispose()
  if hud ~= nil then hud.Dispose() end
  game.Character.OnPortalSpaceExited.Remove(PortalExit)
  game.World.OnChatInput.Remove(ChatCommand)
end

-- listen for gamestate changes
game.OnStateChanged.Add(function(evt)
  if evt.NewState == ClientState.In_Game then
    Init()
  elseif evt.NewState == ClientState.Logging_Out then
    Dispose()
  end
end)

-- if we are ingame when the script loads, call init
if game.State == ClientState.In_Game then Init() end
