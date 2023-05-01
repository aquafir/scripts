local ImGui = require("imgui")
local IM = ImGui ~= nil and ImGui.ImGui or {}
local views = require("utilitybelt.views")
local hud = views.Huds.CreateHud("Inspector")
local ltable = require('lua_table')
--ltable.patch(table, ltable)
--ltable.patch(_G, ltable) --environment

local json = require("json")

json.encode()
---------------------
---- State ----
---------------------
---The most recently appraised WorldObject
---@type WorldObject
local selected = {}
selected.Id = 0;
---An editable/filtered copy of the most recently appraised WorldObject
---@type WorldObject
local edit = {}
edit.Id = 0;

---@type boolean
local allProps

---Filters properties by key.
local keyFilter = ""
---Filters properties by value
local valueFilter = ""
---Mapping of ACE and WO properties
local propTypes = {
  PropertyInt = "IntValues",
  PropertyInt64 = "Int64Values",
  PropertyString = "StringValues",
  PropertyBool = "BoolValues",
  PropertyFloat = "FloatValues",
  PropertyInstanceID = "InstanceValues",
  PropertyDataID = "DataValues"
}

--------------
--- config ---
--------------

-- minumum window size limit
local minWindowSize = Vector2.new(600, 675)

-- maximum window size limit
local maxWindowSize = Vector2.new(999999, 999999)

---------------
--- helpers ---
---------------
--- render a melee weapon info Panel
---@param weenie WorldObject
function RenderMeleeWeapon(weenie)
  IM.Text(weenie.Name)
  IM.Text("Damage: " .. weenie.Value(IntId.Damage))
end

--- render a missile weapon info Panel
---@param weenie WorldObject
function RenderMissileWeapon(weenie)
  IM.Text(weenie.Name)
  IM.Text("Damage: " .. weenie.Value(IntId.Damage))
  IM.Text("Range: " .. weenie.Value(IntId.WeaponRange))
end

--- render a generic item info Panel
function RenderDefaultItem()
  if selected.Id > 0 then
    IM.Text(tostring(selected.Name))
    IM.Text("ObjectClass: " .. tostring(selected.ObjectClass))
    IM.SameLine(200)
    IM.Text("ClassId: " .. tostring(selected.ClassId))
    IM.SameLine(400)
    IM.Text("WeenieClassId: " .. tostring(selected.WeenieClassId))
  end
end

--- render a tab group of all weenie props
function RenderPropTabs()
  --IM.Text("All properties:")
  IM.BeginTabBar("weenie_props_" .. tostring(selected.Id))

  --Special handling for some object classes?
  -- if weenie.ObjectClass == ObjectClass.Player then RenderPlayerTabs(weenie) end

  local size = IM.GetContentRegionAvail()
  size.Y = size.Y - 30

  for propKey, i in propTypes do
    -- for i, propKey in ipairs(propTypes) do
    --Properties of a type
    if IM.BeginTabItem(propKey) then
      IM.BeginChild(selected.Id, size)
      if selected.Id > 0 then
        RenderPropTable(propKey)
      end
      IM.EndChild()
      IM.EndTabItem()
    end
  end
  IM.EndTabBar()
end

---Draws table for the table corresponding to the property type in the edited WorldObject
---@param propType string
function RenderPropTable(propType)
  --Setup
  local tableFlags = ImGui.ImGuiTableFlags.Resizable
  local colFlags = ImGui.ImGuiTableColumnFlags.PreferSortAscending
  IM.BeginTable(propType, 2, tableFlags)
  --Header
  IM.TableSetupColumn("Key", colFlags, 200, 1);
  IM.TableSetupColumn("Value", colFlags, 200, 2);
  IM.TableHeadersRow();

  for propKey, propValue in pairsByKeys(edit[propType]) do
    -- for propKey, propValue in pairs(edit[propType]) do
    IM.PushID(tostring(propKey))

    IM.TableNextColumn()
    IM.Text(tostring(propKey))

    IM.TableNextColumn()
    RenderKeyInput(propType, propKey, propValue)

    IM.TableNextRow()
    IM.PopID()
  end
  IM.EndTable()
end

---Creates input corresponding to a type of property (and maybe key?)
---@param propType string
---@param propKey string
---@param propValue any
function RenderKeyInput(propType, propKey, propValue)
  -- { "IntValues", "Int64Values", "StringValues", "BoolValues", "FloatValues", "InstanceValues", "DataValues" }
  local changed, newAmount
  if propType:find("Int") then
    changed, newAmount = IM.InputInt("", propValue)
  elseif propType:find("Float") then
    changed, newAmount = IM.InputFloat("", propValue)
  elseif propType:find("String") then
    changed, newAmount = IM.InputText("", propValue, 1000)
  elseif propType:find("Bool") then
    --    if v == true then print("!!") else print("??") end
    changed, newAmount = IM.Checkbox("", propValue)
  else
    changed, newAmount = IM.Text(tostring(propValue))
  end

  if changed then
    print("Changed from " .. tostring(propValue) .. " to " .. tostring(newAmount))
    edit[propType][propKey] = newAmount
  end
end

--- todo
function RenderFilters()
  local inputFlags = ImGui.ImGuiInputTextFlags.AutoSelectAll or ImGui.ImGuiInputTextFlags.AllowTabInput
  IM.BeginChild("Filters", Vector2.new(IM.GetWindowWidth(), 40), true, ImGui.ImGuiWindowFlags.AlwaysAutoResize)
  local filterTextChanged, newFilterText = IM.InputText("Key", keyFilter, 500, inputFlags)
  if filterTextChanged then
    keyFilter = newFilterText
    ApplyFilter()
  end
  IM.SameLine(250)
  filterTextChanged, newFilterText = IM.InputText("Value", valueFilter, 500, inputFlags)
  if filterTextChanged then
    valueFilter = newFilterText
    ApplyFilter()
  end
  IM.EndChild()
end

function ApplyFilter()
  -- Case-insensitive searches such so one field to store desired text and the other a case-insensitive pattern
  local vf = case_insensitive_pattern(valueFilter)
  local kf = case_insensitive_pattern(keyFilter)

  for propKey, i in propTypes do
    -- for i, propKey in ipairs(propTypes) do
    print("Clearing " .. tostring(propKey))
    edit[propKey] = {}
    for propId, propValue in pairs(selected[propKey]) do
      if (valueFilter == "" or tostring(propValue):find(vf)) and
          (keyFilter == "" or tostring(propId):find(kf)) then
        print("Accepting: " .. tostring(propId) .. " - " .. tostring(propValue))
        edit[propKey][propId] = propValue
      end
    end
  end
end

function ApplyChanges()
  --game.Actions.InvokeChat("/clear")
  local result = await(game.Actions.ObjectAppraise(selected.Id))
  print(tostring(result.Success))

  for propKey, aceKey in propTypes do
    -- for i, propKey in ipairs(propTypes) do
    --    print(tostring(propKey) .. "::")
    for val, key in edit[propKey] do
      local orig = selected[propKey][key]
      if val ~= orig then
        local command = "/setproperty " .. tostring(aceKey) .. "." .. tostring(key) .. " " .. tostring(val)
        -- print(tostring(propKey) .. "." .. tostring(key) .. ": " ..
        --   tostring(orig) .. "-->" .. tostring(val))
        print("       " .. command)
        game.Actions.InvokeChat(command)
      end
    end
  end
end

function EditSelected()
  print(tostring(game.World.Selected) .. " - " .. tostring(selected))
  print("Sel: " .. tostring(selected))
  if game.World.Selected == nil then
    print("Select an object to begin editing.")
  elseif selected.Id ~= game.World.Selected.Id then
    print("Editing " .. tostring(selected.Name))
    selected = CopyWorldObject(game.World.Selected)
    edit = CopyWorldObject(selected)
  else
    print("Already editing " .. tostring(selected.Name))
  end
end

---UI for editing selected item
function RenderSelected(weenie)
  -- if weenie == nil then
  --   IM.Text("Nothing selected...")
  -- else
  -- IM.Begin(weenie.Name .. "###tab_" .. tostring(weenie.Id))
  -- --print("Render " .. weenie.Name)
  -- IM.BeginChild(weenie.Id, IM.GetContentRegionAvail())

  --if weenie ~= nil then print(tostring(weenie.ObjectClass)) end

  RenderDefaultItem()

  IM.Separator()
  RenderFilters()

  IM.Separator()
  RenderPropTabs()

  IM.Separator()
  RenderButtons()

  --   IM.EndChild()
  -- IM.End()
  -- end
end

---todo
function RenderPlayerTabs()
  if IM.BeginTabItem("Attributes") then
    IM.BeginChild(selected.Id, IM.GetContentRegionAvail())
    for propId, propValue in pairs(selected.Attributes) do
      IM.Text(tostring(propId) .. ": " .. propValue.Base .. " - " .. propValue.Current .. " - " .. propValue.InitLevel)
    end
    for propId, propValue in pairs(selected.Vitals) do
      IM.Text(tostring(propId) .. ": " .. propValue.Base .. " - " .. propValue.Current .. " - " .. propValue.InitLevel)
    end
    IM.EndChild()
    IM.EndTabItem()
  end

  if IM.BeginTabItem("Skills") then
    IM.BeginChild(selected.Id, IM.GetContentRegionAvail())
    for propId, propValue in pairs(selected.Skills) do
      IM.Text(tostring(propId) ..
        ": " .. tostring(propValue.SkillState) .. " - " .. propValue.Current .. " - " .. propValue.Base)
    end
    IM.EndChild()
    IM.EndTabItem()
  end
end

---todo
function RenderButtons()
  --Commit changes
  if IM.Button("Save") then ApplyChanges() end
  IM.SameLine(50)
  if IM.Button("Edit") then EditSelected() end
  IM.SameLine(100)
  if IM.Button("Reset") then edit = CopyWorldObject(selected) end
  IM.SameLine(150)
  -- if IM.Button("Test") then
  --   for i, j in pairsByKeys(edit["StringValues"]) do
  --     print(tostring(i) .. ": " .. tostring(j))
  --   end
  -- end

  IM.BeginCombo("Test")

  IM.EndCombo()
end

---Creates a partial copy of the properties of a WorldObject eligible for modification
---@param orig WorldObject
---@return WorldObject
function CopyWorldObject(orig)
  ---@type WorldObject
  local copy = {}
  --Non-collections
  copy.Name = orig.Name
  copy.Id = orig.Id
  copy.ObjectClass = orig.ObjectClass
  copy.ClassId = orig.ClassId
  copy.WeenieClassId = orig.WeenieClassId
  --Creature specific
  copy.Attributes = ltable.copy(orig.Attributes)
  copy.Vitals = ltable.copy(orig.Vitals)
  --Props
  copy.BoolValues = ltable.copy(orig.BoolValues)
  copy.DataValues = ltable.copy(orig.DataValues)
  copy.FloatValues = ltable.copy(orig.FloatValues)
  copy.IntValues = ltable.copy(orig.IntValues)
  copy.Int64Values = ltable.copy(orig.Int64Values)
  copy.StringValues = ltable.copy(orig.StringValues)

  for index, value in ipairs(copy.IntValues) do
    print(tostring(index) .. ": " .. tostring(value))
  end

  return copy
end

---@param str string
---@return boolean
function toboolean(str)
  return str == "true"
end

---Returns a case-insensitive version of input pattern
function case_insensitive_pattern(pattern)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)
    if percent ~= "" or not letter:match("%a") then
      return percent .. letter
    else
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end
  end)
  return p
end

---Traverse a table by order of key: https://www.lua.org/pil/19.3.html
function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  -- for n in t do table.insert(a, n) end
  table.sort(a, f)
  local i = 0             -- iterator variable
  local iter = function() -- iterator function
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

--------------------------
--- hud event handlers ---
--------------------------
-- called before our window is registered. you can set window options here
local onPreRender = function()
  -- set minimum window size
  -- IM.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize)
end

-- called during the hud window render. draw your ui here
local onRender = function()
  if game.State == ClientState.In_Game then
    -- if views ~= nil and hud == nil then
    --   hud = views.Huds.CreateHud("Inspector", 100686697)
    --   hud.Visible = true
    -- end

    RenderSelected(selected)
  else
    hud.Visible = false
  end
end


----------------------
--- event handlers ---
----------------------
---When an object is selected create a copy of it's properties
---@param e ObjectSelectedEventArgs
local OnSelect = function(e)
  -- If the selected object isn't the same as the last selected...
  if selected ~= nil and selected.Id ~= e.ObjectId then
    -- Make sure it is appraised?
    local result = await(game.Actions.ObjectAppraise(e.ObjectId))

    --print("Selected " .. e.ObjectId)
    -- Create partial copy of selection to edit
    -- local weenie = game.World.Get(e.ObjectId)
    -- selected = CopyWorldObject(weenie)
  end
end

local Appraise = function(e)
  local result = await(game.Actions.ObjectAppraise(e.ObjectId))
  if selected == nil and selected.Id == e.Data.ObjectId then
    print("Editing " .. e.Data.ObjectId)
    local weenie = game.World.Get(e.Data.ObjectId)
    selected = CopyWorldObject(weenie)
  else
    print("Skip " .. e.Data.ObjectId)
  end
end

-- local RequestAppraise = function(itemInfo)
--   print(itemInfo.Data.ObjectId)
-- end

------------------
--- initialize ---
------------------
-- create a new hud, set options, and register for hud events
--hud.Visible = false
hud.showInBar = true
hud.OnPreRender.Add(onPreRender);
hud.OnRender.Add(onRender);
hud.WindowSettings = ImGui.ImGuiWindowFlags.AlwaysAutoResize

-- subscribe to every incoming / outgoing "io"
--game.World.OnObjectSelected.Add(OnSelect)
-- game.Messages.Incoming.Item_SetAppraiseInfo.Add(Appraise)
-- game.Messages.Outgoing.Item_Appraise.Add(RequestAppraise)

-- subscribe to scriptEnd event so we can tostring(message)
-- all subscribed to events should be ubscribed with `event.remove(handler)`
-- (since this is a `once` handler, it will automatically unsubscribe itself after being called once)
game.OnScriptEnd.Once(function()
  -- unsubscribe from any events we subscribed to
  -- game.World.OnObjectSelected.Remove(OnSelect)
  -- game.Messages.Incoming.Item_SetAppraiseInfo.Remove(Appraise)
  --  game.Messages.Outgoing.Item_Appraise.Remove(RequestAppraise)
  hud.OnPreRender.Remove(onPreRender);
  hud.OnRender.Remove(onRender);

  -- destroy hud
  hud.Dispose();
end)
