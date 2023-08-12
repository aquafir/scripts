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
}
_G.PropType = PropType

---@class PropFilter
---@field SelectedIndex       number        Selected Property index
---@field Type                PropType      Type of Property filtered
---@field IncludeMissingProps boolean       Filter out properties not found on WorldObject if false
---@field UseRegex            boolean       Uses FilterText as a Regex when true, pattern match when false
---@field private Weenie      WorldObject   Optional WorldObject used for value checks
---@field private FilterText  string        Optional filter
---@field private LastKey     DateTime      Todo, think about how to update so it doesn't lag
---@field private Updating    boolean       Changed but not yet updated
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
  LastKey             = DateTime.MinValue,
  Updating            = false,
  Properties          = {},
}
PropFilter.__index = PropFilter

---@param type PropType
---@return PropFilter
function PropFilter.new(type)
  ---@type PropFilter
  local self = setmetatable({}, PropFilter)
  self.Type = type or PropType.Unknown
  print('Constructed ', self.Type)
  self:SetFilter(self.FilterText)

  return self
end

---@param self PropFilter
---@param filter? string    Filter text
---@param wo? WorldObject   Filter by properties a WorldObject has
-- ---@param update? boolean   Builds properties unless false
---@return PropFilter
function PropFilter:SetFilter(filter, wo)
  if filter ~= nil then self.FilterText = filter end
  if wo ~= nil then self.Weenie = wo end
  --Create regex
  if filter ~= nil and filter ~= "" then
    self.Regex = Regex.new(self.FilterText, RegexOptions.IgnoreCase) --+ RegexOptions.Compiled)
  else
    self.Regex = nil
  end

  --Todo: do this more better
  ---@type TimeSpan
  -- local lapsed = DateTime.UtcNow - self.LastKey
  -- if lapsed.Milliseconds < 500 then return self end
  -- --if lapsed.Milliseconds > 500 or self.Updating then return self end
  -- -- self.Updating = true
  -- self.LastKey = DateTime.UtcNow
  -- print('Updating after ', lapsed.Milliseconds)
  self:BuildPropList()
  
  return self
end

---@param self PropFilter
function PropFilter:BuildPropList()
  self.Properties = {}
  print(self.Type)
  -- print('b')
  if self.Type == PropType.Bool then for value in BoolId.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
  if self.Type == PropType.DataId then for value in DataId.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
  if self.Type == PropType.Float then for value in FloatId.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
  if self.Type == PropType.InstanceId then for value in InstanceId.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
  if self.Type == PropType.Int then for value in IntId.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
  if self.Type == PropType.Int64 then for value in Int64Id.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
  if self.Type == PropType.String then for value in StringId.GetValues() do if not self:IsFiltered(value, wo) then table.insert(self.Properties, value) end end end
end


---Uses current filter to refresh Properties for other changes
---@param self PropFilter
---@return PropFilter
function PropFilter:UpdateFilter()
  self:SetFilter(self.FilterText,self.Weenie)

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
  
  --Regex match (todo: pattern matching)
  if self.Regex ~= nil and self.UseRegex and not self.Regex.IsMatch(value) then return true end
  
  return false
end

---@param self PropFilter
---@returns string  # Friendly name of PropType
function PropFilter:TypeName()
  if self.Type == PropType.Bool then return 'Bool' end
  if self.Type == PropType.DataId then return 'DataId' end
  if self.Type == PropType.Float then return 'Float' end
  if self.Type == PropType.InstanceId then return 'InstanceId' end
  if self.Type == PropType.Int then return 'Int' end
  if self.Type == PropType.Int64 then return 'Int64' end
  if self.Type == PropType.String then return 'String' end
  if self.Type == PropType.Unknown then return 'Unknown' end
    
  return 'ERROR'
end

---@param self PropFilter
function PropFilter:DrawCombo(label)
  label = label or '###' .. tostring(self.Type)
  --Todo: options for what to draw/labels
  --print(self.Type, self.SelectedIndex, self.Properties, #self.Properties)
  local changed, value = ImGui.Combo(self:TypeName() .. '=' .. #self.Properties .. label .. 'Combo', self.SelectedIndex - 1, self.Properties, #self.Properties)
  if changed then 
    self.SelectedIndex = value + 1
    --Todo: callback
    print(self:Value())
    -- print(tostring(self:Value()))
  end

  --Change filter text
  ImGui.SetNextItemWidth(200)
  ImGui.SameLine()
  local didChange, newValue = ImGui.InputText(label .. 'Filter', self.FilterText, 256)
  if didChange then self:SetFilter(newValue) end

  --Toggle missing props
  ImGui.SameLine()
  if ImGui.Checkbox('Include missing' .. label  .. 'IncMiss', self.IncludeMissingProps) then 
    self.IncludeMissingProps = not self.IncludeMissingProps 
    self:UpdateFilter()
  end

  --Set WorldObject to selected
  ImGui.SameLine()
  local name = 'Target'
  if self.Weenie ~= nil then name = self.Weenie.Name end
  if ImGui.Button(name .. label  .. 'Target') then 
    if game.World.Selected ~= nil then self:SetFilter(nil, game.World.Selected)  print('Selected ', game.World.Selected.Name) end
  end

end

return PropFilter
