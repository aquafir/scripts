-----------------------LIBS-------------------------
-- local ac = require("acclient")               -- 3d/2d graphics and coordinates
-- local fs = require("filesystem").GetScript() -- File system
-- local json = require("json")
-- json.encode()
local IM     = require("imgui")
local ImGui  = IM ~= nil and IM.ImGui or {}
local views  = require("utilitybelt.views")
local hud    = nil ---@type Hud|nil
local ltable = require('lua_table')



----------------------CONFIG-----------------------
-- Window constraints
local minWindowSize = Vector2.new(600, 675)
local maxWindowSize = Vector2.new(1400, 900)





----------------------STATE------------------------
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


---------------
--- helpers ---
---------------
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
function RenderDefaultItem()
  if selected.Id > 0 then
    ImGui.Text(tostring(selected.Name))
    ImGui.Text("ObjectClass: " .. tostring(selected.ObjectClass))
    ImGui.SameLine(200)
    ImGui.Text("ClassId: " .. tostring(selected.ClassId))
    ImGui.SameLine(400)
    ImGui.Text("WeenieClassId: " .. tostring(selected.WeenieClassId))
  end
end

--- render a tab group of all weenie props
function RenderPropTabs()
  --IM.Text("All properties:")
  ImGui.BeginTabBar("weenie_props_" .. tostring(selected.Id))

  --Special handling for some object classes?
  -- if weenie.ObjectClass == ObjectClass.Player then RenderPlayerTabs(weenie) end

  local size = ImGui.GetContentRegionAvail()
  size.Y = size.Y - 30

  for propKey, i in propTypes do
    -- for i, propKey in ipairs(propTypes) do
    --Properties of a type
    if ImGui.BeginTabItem(propKey) then
      ImGui.BeginChild(selected.Id, size)
      if selected.Id > 0 then
        RenderPropTable(propKey)
      end
      ImGui.EndChild()
      ImGui.EndTabItem()
    end
  end
  ImGui.EndTabBar()
end

---Draws table for the table corresponding to the property type in the edited WorldObject
---@param propType string
function RenderPropTable(propType)
  --Setup
  local tableFlags = IM.ImGuiTableFlags.Resizable
  local colFlags = IM.ImGuiTableColumnFlags.PreferSortAscending
  ImGui.BeginTable(propType, 2, tableFlags)
  --Header
  ImGui.TableSetupColumn("Key", colFlags, 200, 1);
  ImGui.TableSetupColumn("Value", colFlags, 200, 2);
  ImGui.TableHeadersRow();

  for propKey, propValue in pairsByKeys(edit[propType]) do
    -- for propKey, propValue in pairs(edit[propType]) do
    ImGui.PushID(tostring(propKey))

    ImGui.TableNextColumn()
    ImGui.Text(tostring(propKey))

    ImGui.TableNextColumn()
    RenderKeyInput(propType, propKey, propValue)

    ImGui.TableNextRow()
    ImGui.PopID()
  end
  ImGui.EndTable()
end

---Creates input corresponding to a type of property (and maybe key?)
---@param propType string
---@param propKey string
---@param propValue any
function RenderKeyInput(propType, propKey, propValue)
  -- { "IntValues", "Int64Values", "StringValues", "BoolValues", "FloatValues", "InstanceValues", "DataValues" }
  local changed, newAmount
  if propType:find("Int") then
    changed, newAmount = ImGui.InputInt("", propValue)
  elseif propType:find("Float") then
    changed, newAmount = ImGui.InputFloat("", propValue)
  elseif propType:find("String") then
    changed, newAmount = ImGui.InputText("", propValue, 1000)
  elseif propType:find("Bool") then
    --    if v == true then print("!!") else print("??") end
    changed, newAmount = ImGui.Checkbox("", propValue)
  else
    changed, newAmount = ImGui.Text(tostring(propValue))
  end

  if changed then
    print("Changed from " .. tostring(propValue) .. " to " .. tostring(newAmount))
    edit[propType][propKey] = newAmount
  end
end

--- todo
function RenderFilters()
  local inputFlags = IM.ImGuiInputTextFlags.AutoSelectAll or IM.ImGuiInputTextFlags.AllowTabInput
  ImGui.BeginChild("Filters", Vector2.new(ImGui.GetWindowWidth(), 40), true, IM.ImGuiWindowFlags.AlwaysAutoResize)
  local filterTextChanged, newFilterText = ImGui.InputText("Key", keyFilter, 500, inputFlags)
  if filterTextChanged then
    keyFilter = newFilterText
    ApplyFilter()
  end
  ImGui.SameLine(250)
  filterTextChanged, newFilterText = ImGui.InputText("Value", valueFilter, 500, inputFlags)
  if filterTextChanged then
    valueFilter = newFilterText
    ApplyFilter()
  end
  ImGui.EndChild()
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
  if selected == nil then
    IM.Text("Nothing selected...")
  else
    weenie = selected
    -- IM.Begin(weenie.Name .. "###tab_" .. tostring(weenie.Id))
    --print("Render " .. weenie.Name)
    -- IM.BeginChild(weenie.Id, IM.GetContentRegionAvail())

    -- if weenie ~= nil then print(tostring(weenie.ObjectClass)) end

    RenderDefaultItem()

    ImGui.Separator()
    RenderFilters()

    ImGui.Separator()
    RenderPropTabs()

    -- ImGui.Separator()
    -- RenderButtons()

    -- IM.EndChild()
    -- IM.End()
  end
end

---todo
function RenderPlayerTabs()
  if ImGui.BeginTabItem("Attributes") then
    ImGui.BeginChild(selected.Id, ImGui.GetContentRegionAvail())
    for propId, propValue in pairs(selected.Attributes) do
      ImGui.Text(tostring(propId) .. ": " .. propValue.Base .. " - " .. propValue.Current .. " - " .. propValue
      .InitLevel)
    end
    for propId, propValue in pairs(selected.Vitals) do
      ImGui.Text(tostring(propId) .. ": " .. propValue.Base .. " - " .. propValue.Current .. " - " .. propValue
      .InitLevel)
    end
    ImGui.EndChild()
    ImGui.EndTabItem()
  end

  if ImGui.BeginTabItem("Skills") then
    ImGui.BeginChild(selected.Id, ImGui.GetContentRegionAvail())
    for propId, propValue in pairs(selected.Skills) do
      ImGui.Text(tostring(propId) ..
        ": " .. tostring(propValue.SkillState) .. " - " .. propValue.Current .. " - " .. propValue.Base)
    end
    ImGui.EndChild()
    ImGui.EndTabItem()
  end
end

---todo
function RenderButtons()
  --Commit changes
  if ImGui.Button("Save") then ApplyChanges() end
  ImGui.SameLine(50)
  if ImGui.Button("Edit") then EditSelected() end
  ImGui.SameLine(100)
  if ImGui.Button("Reset") then edit = CopyWorldObject(selected) end
  ImGui.SameLine(150)
  -- if IM.Button("Test") then
  --   for i, j in pairsByKeys(edit["StringValues"]) do
  --     print(tostring(i) .. ": " .. tostring(j))
  --   end
  -- end

  ImGui.BeginCombo("Test")

  ImGui.EndCombo()
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

-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  if game.State == ClientState.In_Game then
    -- if views ~= nil and hud == nil then
    --   hud = views.Huds.CreateHud("Inspector", 100686697)
    --   hud.Visible = true
    -- end

    RenderSelected(selected)
  else
    hud.Visible = false
  end
  --If you set an alpha in the PreRender it applies to all script windows, so reset it after rendering
  -- ImGui.PushStyleVar(IM.ImGuiStyleVar.Alpha, 1)
end

-- function OnRender2D()
-- end

-- Called before our window is registered
function OnPreRender()
  --Constrain resize dimensions
  ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);

  --Force a size / position in the center
  -- ImGui.SetWindowSize(Vector2.new(300, 300))
  -- ImGui.SetNextWindowPos(Vector2.new(ImGui.GetWindowViewport().Size.X/2-150, ImGui.GetWindowViewport().Size.Y/2-150))

  --Set an alpha (make sure to remove after Render)
  -- ImGui.PushStyleVar(IM.ImGuiStyleVar.Alpha, 0.5)
end

----------------------
--- event handlers ---
----------------------
---When an object is selected create a copy of it's properties
---@param e ObjectSelectedEventArgs
function OnSelect(e)
  -- If the selected object isn't the same as the last selected...
  if selected ~= nil and selected.Id ~= e.ObjectId then
    -- Make sure it is appraised?
    local result = await(game.Actions.ObjectAppraise(e.ObjectId).Await())
    print("Selected " .. e.ObjectId)
    -- Create partial copy of selection to edit
    local weenie = game.World.Get(e.ObjectId)
    selected = CopyWorldObject(weenie)
  end
end

local Appraise = function(e)
  local result = game.Actions.ObjectAppraise(e.ObjectId)
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


---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("MyScript")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  --Style
  hud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize -- Size to fit
  --  + IM.ImGuiWindowFlags.NoDecoration     -- Borderless
  --  + IM.ImGuiWindowFlags.NoBackground     -- No BG

  -- subscribe to events
  game.World.OnObjectSelected.Add(OnSelect)

  -- subscribe to hud events, with the handlers we defined above
  hud.OnPreRender.Add(OnPreRender)
  hud.OnRender.Add(OnHudRender)
end

function Dispose()
  -- Unsubscribe from events
  game.World.OnObjectSelected.Remove(OnSelect)

  hud.OnPreRender.Remove(OnPreRender)

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
