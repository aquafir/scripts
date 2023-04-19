---------------------
---- ID Panel ----
---------------------
--
-- UI stuff
--

local hud = require("utilitybelt.views").Huds.CreateHud("ItemInfo")
local IM = require("imgui")
local ImGui = IM.ImGui
local weenieBuffer = {}
local archive = {}

--------------
--- config ---
--------------

-- minumum window size limit
local minWindowSize = Vector2.new(300, 575)

-- maximum window size limit
local maxWindowSize = Vector2.new(999999, 999999)

---------------
--- helpers ---
---------------

function RenderWeenieProps(weenie)
  
end

--- render a melee weapon info Panel
---@param weenie WorldObject
function RenderMeleeWeapon(weenie)
  ImGui.Text(weenie.Name)
  ImGui.Text("Damage: " .. weenie.Value(IntId.Damage))
end

--- render a missile weapon info Panel
---@param weenie WorldObject
function RenderMissileWeapon(weenie)
  ImGui.Text(weenie.Name)
  ImGui.Text("Damage: " .. weenie.Value(IntId.Damage))
  ImGui.Text("Range: " .. weenie.Value(IntId.WeaponRange))
end

--- render a generic item info Panel
---@param weenie WorldObject
function RenderDefaultItem(weenie)
  ImGui.Text(weenie.Name)
  ImGui.Text("ObjectClass: " .. tostring(weenie.ObjectClass))
  ImGui.Text("ClassId: " .. tostring(weenie.ClassId))
  ImGui.Text("WeenieClassId: " .. tostring(weenie.WeenieClassId))
end

--- render a tab group of all weenie props
---@param weenie WorldObject
function RenderPropTabs(weenie)
  local propKeys = { "IntValues", "Int64Values", "StringValues", "BoolValues", "FloatValues", "InstanceValues", "DataValues" }

  ImGui.Text("All properties:")
  ImGui.BeginTabBar("weenie_props_"..tostring(weenie.Id))
  for i, propKey in ipairs(propKeys) do
    if ImGui.BeginTabItem(propKey) then
      ImGui.BeginChild(weenie.Id, ImGui.GetContentRegionAvail())
      for propId, propValue in pairs(weenie[propKey]) do
        ImGui.Text(tostring(propId) .. ": " .. tostring(propValue))
      end
      ImGui.EndChild()
      ImGui.EndTabItem()
    end
  end

  ImGui.EndTabBar()
end

function Test()
  Test()
end

--- Render a container tab
function RenderContainerTab(weenie)
  local isTabSelected, isOpen = ImGui.BeginTabItem(weenie.Name .. "###tab_" .. tostring(weenie.Id), true)
  if isTabSelected then
    ImGui.BeginChild(weenie.Id, ImGui.GetContentRegionAvail())

    if weenie.ObjectClass == ObjectClass.MeleeWeapon then
      RenderMeleeWeapon(weenie)
    elseif weenie.ObjectClass == ObjectClass.MissileWeapon then
      RenderMissileWeapon(weenie)
    else
      RenderDefaultItem(weenie)
    end

    ImGui.Separator()
    RenderPropTabs(weenie)

    ImGui.EndChild()
    ImGui.EndTabItem()
  end
  -- true when the user closed this tab
  if not isOpen then
    weenieBuffer[weenie.Id] = nil
  end
end

--------------------------
--- hud event handlers ---
--------------------------
-- called before our window is registered. you can set window options here
local onPreRender = function()
  -- set minimum window size
  ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize)
end

-- called during the hud window render. draw your ui here
local onRender = function()
  local colPadding = 8
  local contentPaddingWidth = ImGui.GetContentRegionAvail().X - 8
  local contentPanelHeight = ImGui.GetContentRegionAvail().Y
  local contentPanelSize = Vector2.new(contentPaddingWidth, contentPanelHeight)

  ImGui.BeginTabBar("weenie_bar", IM.ImGuiTabBarFlags.TabListPopupButton)
  for i,weenie in pairs(weenieBuffer) do
    RenderContainerTab(weenie)
  end
  ImGui.EndTabBar()

  -- auto scroll if not scrolled to the bottom already
  if (ImGui.GetScrollY() >= ImGui.GetScrollMaxY()) then
    ImGui.SetScrollHereY(1.0)
  end
end


----------------------
--- event handlers ---
----------------------
local Appraise = function(appraisalInfo)
    local id = appraisalInfo.Data.ObjectId
    local weenie = game.World.Get(appraisalInfo.Data.ObjectId)
    archive[id]={weenie}
    weenieBuffer[id]=weenie
end

local RequestAppraise = function(itemInfo)
    print(itemInfo.Data.ObjectId)
end

------------------
--- initialize ---
------------------

-- create a new hud, set options, and register for hud events
hud.Visible = true
hud.showInBar = true
hud.OnPreRender.Add(onPreRender);
hud.OnRender.Add(onRender);

-- subscribe to every incoming / outgoing "io"
game.Messages.Incoming.Item_SetAppraiseInfo.Add(Appraise)
game.Messages.Outgoing.Item_Appraise.Add(RequestAppraise)

-- subscribe to scriptEnd event so we can tostring(message)
-- all subscribed to events should be ubscribed with `event.remove(handler)`
-- (since this is a `once` handler, it will automatically unsubscribe itself after being called once)
game.OnScriptEnd.Once(function()
  -- unsubscribe from any events we subscribed to
  game.Messages.Incoming.Item_SetAppraiseInfo.Remove(Appraise)
  hud.OnPreRender.Remove(onPreRender);
  hud.OnRender.Remove(onRender);

  -- destroy hud
  hud.Dispose();
end)

print("IDpanel")