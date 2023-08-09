local ac = require("acclient")
local vtnav = require("vtnavigation")
local views = require("utilitybelt.views")
local ImGui = require("imgui")
local im = ImGui.ImGui;

local myHud = nil ---@type Hud|nil
local selectedNavFile = nil

---find the index of a value inside an array. 1 based indexes
---@param array table -- array to check
---@param value any -- value to check for
---@return integer|nil -- index, or nil of not found
local indexOf = function(array, value)
  for i, v in ipairs(array) do
      if v == value then
          return i
      end
  end
  return nil
end

-- Handler for myHud.OnRender. This gets called each time this hud should render
-- its contents. We do all the drawing of controls here.
local myHud_onRender = function()
  -- nav file dropdown
  local navFiles, navFilesErr = vtnav.GetNavFiles()
  if navFilesErr == nil then
    local selectedNavFileIndex = indexOf(navFiles, selectedNavFile) or 1
    local didChangeSelectedNavFile, newNavFile = im.Combo("Nav Route", selectedNavFileIndex - 1, navFiles, #navFiles)
    if didChangeSelectedNavFile then
      selectedNavFile = navFiles[newNavFile + 1]
      if vtnav.Load(selectedNavFile) then
        vtnav.Draw()
      end
    end
  else
    -- print(navFilesErr)
  end
end

---Initialize the script
function Init()
  -- create our hud
  myHud = views.Huds.CreateHud("Hunting")
  myHud.Visible = true;
  myHud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize

  -- subscribe to hud events, with the handlers we defined above
  myHud.OnRender.Add(myHud_onRender)
end

-- listen for gamestate changes
game.OnStateChanged.Add(function (evt)
  if evt.NewState == ClientState.In_Game then
    -- if we are now ingame, init
    Init()
  elseif evt.NewState == ClientState.Logging_Out then
    -- destroy hud
    if myHud ~= nil then myHud.Dispose() end
  end
end)

-- if we are ingame when the script loads, call init
if game.State == ClientState.In_Game then
  Init()
end