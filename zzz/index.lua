-----------------------LIBS-------------------------
-- local ac = require("acclient")               -- 3d/2d graphics and coordinates
-- local fs = require("filesystem").GetScript() -- File system
local IM           = require("imgui")
local ImGui        = IM ~= nil and IM.ImGui or {}
local views        = require("utilitybelt.views")
local hud          = nil ---@type Hud|nil

--Generic EnumConst wasn't working
---@enum PropType --Types of supported Enums.
local PropType     = {
  Unknown = 0,
  Bool = 1,
  String = 2,
  Int = 3,
  Int64 = 4,
  Float = 5,
  DataId = 6,
  InstanceId = 7,
  -- ObjectType = 8,
  -- ObjectClass = 9,
}

---@class PropFilter
---@field SelectedIndex       number        Selected Property index
---@field Type                PropType      Type of Property filtered
---@field IncludeMissingProps boolean       Filter out properties not found on WorldObject if false
---@field UseRegex            boolean       Uses FilterText as a Regex when true, pattern match when false
---@field private Weenie      WorldObject   Optional WorldObject used for value checks
---@field private FilterText  string        Optional filter
---@field Regex               Regex         Regex compiled when filter text updated
---@field Properties          string[]      Populated list of Enum values
-- ---@field DrawFilter fun(s: PropFilter,  boolean)
PropFilter         = {
  --Defaults
  SelectedIndex       = 1,
  Type                = PropType.Unknown,
  FilterText          = "",
  UseRegex            = true,
  IncludeMissingProps = false,
  Properties          = {},
}
PropFilter.__index = PropFilter

---@param type PropType
---@return PropFilter
function PropFilter.new(type)
  ---@type PropFilter
  local self = setmetatable({}, PropFilter)
  self.Type = type or PropType.Unknown
  self:SetFilter(self.FilterText)

  return self
end

---@param self PropFilter
---@param filter? string   Filter text
---@param wo? WorldObject Filter by properties a WorldObject has
---@return PropFilter
function PropFilter:SetFilter(filter, wo)
  if filter ~= nil then self.FilterText = filter end
  if wo ~= nil then self.Weenie = wo end
  self.Properties = {}

  --Create regex
  if filter ~= nil and filter ~= "" then
    self.Regex = Regex.new(self.FilterText, RegexOptions.IgnoreCase) --+ RegexOptions.Compiled)
  else
    self.Regex = nil
  end

  --Handle different types of enums
  if self.Type == PropType.Bool then
    for value in BoolId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table.insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.DataId then for value in DataId.GetValues() do table.insert(self.Properties, value) end end
  if self.Type == PropType.Float then for value in FloatId.GetValues() do table.insert(self.Properties, value) end end
  if self.Type == PropType.InstanceId then for value in InstanceId.GetValues() do table.insert(self.Properties, value) end end
  if self.Type == PropType.Int then for value in IntId.GetValues() do table.insert(self.Properties, value) end end
  if self.Type == PropType.Int64 then for value in Int64Id.GetValues() do table.insert(self.Properties, value) end end
  if self.Type == PropType.String then for value in StringId.GetValues() do table.insert(self.Properties, value) end end
  -- if self.Type == PropType.ObjectClass then for value in ObjectClass.GetValues() do table.insert(self.Properties, value) end end
  -- if self.Type == PropType.ObjectType then for value in ObjectType.GetValues() do table.insert(self.Properties, value) end end
  --if self.Type == PropType.Unknown then  end
  --print(self.Type, self.FilterText, #self.Properties, self.Properties)

  return self
end

---@param self PropFilter
---@return any # Value of SelectedIndex property if Weenie has it, nil if missing
function PropFilter:Value()
  --Todo: error check?
  --Support for non PropKeys?
  if self.Weenie == nil then return nil end
  if not self.Weenie.HasValue(self.Properties[self.SelectedIndex]) then return nil end
  return self.Weenie.Value(self.Properties[self.SelectedIndex])
end

---@param self PropFilter
---@param value any         Enum property value
function PropFilter:IsFiltered(value)
  --If the filter has a WorldObject and missing props are filtered check if Weenie has the given property
  if self.Weenie ~= nil and not self.IncludeMissingProps and not self.Weenie.HasValue(value) then return true end
  -- then print(value, self.Weenie.HasValue(value)) end

  --If there's a regex
  if self.Regex ~= nil and self.UseRegex and not self.Regex.IsMatch(value) then return true end
  --   if wo ~= nil --and not wo.HasValue(self.Properties[self.Selected]) then return true end
  --   then
  --print(value)
  -- end

  --TODO
  return false
end

---@type PropFilter[]
local filters = {}
local boolFilter = PropFilter.new(PropType.Bool)
--boolFilter:SetFilter('nodraw|15day|rare', game.Character.Weenie)
boolFilter:SetFilter('', game.Character.Weenie)
print(#boolFilter.Properties)
table.insert(filters, boolFilter)
--table.insert(filters, PropFilter.new(PropType.Bool))
-- table.insert(filters, PropFilter.new(PropType.Int))
-- table.insert(filters, PropFilter.new(PropType.String))


----------------------LOGIC------------------------

-- PF.SetupFilter(type, optText, optWo) --optional WO?
-- PF.Value() -- nil / value of right type if it exists

-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  for filter in filters do
    --print(filter.Type, filter.SelectedIndex, filter.Properties, #filter.Properties)
    local changed, value = ImGui.Combo('Combo###' .. filter.Type, filter.SelectedIndex - 1, filter.Properties,
      #filter.Properties)
    if changed then
      filter.SelectedIndex = value + 1
      print(filter:Value(game.Character.Weenie))
    end
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


--return PropFilter
