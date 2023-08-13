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
_G.PropType        = PropType

---@class PropFilter
---@field Enabled             boolean       Is the filter enabled for whatever it is being used for
---@field SelectedIndex       number        Selected Property index
---@field Type                PropType      Type of Property filtered
---@field IncludeMissingProps boolean       Filter out properties not found on WorldObject if false
---@field UseRegex            boolean       Uses FilterText as a Regex when true, pattern match when false
---@field private Weenie      WorldObject   Optional WorldObject used for value checks
---@field private FilterText  string        Optional filter
---@field private LastKey     DateTime      Todo, think about how to update so it doesn't lag
---@field private Updating    boolean       Changed but not yet updated
---@field updCheck    fun()
---@field UpdateInterval      number        Limits rate of rebuilding Properties
---@field Regex               Regex         Regex compiled when filter text updated
---@field Properties          string[]      Populated list of Enum values
-----@field ComboCallback       fun()
-- ---@field DrawFilter fun(s: PropFilter,  boolean)
PropFilter         = {
  --Defaults
  Enabled             = true,
  SelectedIndex       = 1,
  Type                = PropType.Unknown,
  FilterText          = "",
  UseRegex            = true,
  IncludeMissingProps = false,
  LastKey             = DateTime.MinValue,
  Updating            = false,
  UpdateInterval      = 250,
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
    self.Regex = Regex.new(self.FilterText, RegexOptions.Compiled + RegexOptions.IgnoreCase)
  else
    self.Regex = nil
  end

  self:CheckUpdate()
  --self:BuildPropList()  --Switch from always rebuilding Properties

  return self
end

---@param self PropFilter
function PropFilter:BuildPropList()
  self.Properties = {}
  if self.Type == PropType.Bool then
    for value in BoolId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table
            .insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.DataId then
    for value in DataId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table
            .insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.Float then
    for value in FloatId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table
            .insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.InstanceId then
    for value in InstanceId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table.insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.Int then
    for value in IntId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table
            .insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.Int64 then
    for value in Int64Id.GetValues() do
      if not self:IsFiltered(value, wo) then
        table
            .insert(self.Properties, value)
      end
    end
  end
  if self.Type == PropType.String then
    for value in StringId.GetValues() do
      if not self:IsFiltered(value, wo) then
        table
            .insert(self.Properties, value)
      end
    end
  end
end

---Uses current filter to refresh Properties for other changes
---@param self PropFilter
---@return PropFilter
function PropFilter:UpdateFilter()
  self:SetFilter(self.FilterText, self.Weenie)

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
---@param wo WorldObject
---@return any # Value of SelectedIndex property if Weenie has it, nil if missing
function PropFilter:Value(wo)
  if wo == nil then return nil end
  if not wo.HasValue(self.Properties[self.SelectedIndex]) then return nil end
  return wo.Value(self.Properties[self.SelectedIndex])
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

--column options
---@param self PropFilter
---@param label? string
function PropFilter:DrawCombo(label)
  label = label or '###' .. tostring(self.Type)
  local columns = 3
  ImGui.BeginTable(label .. "table", columns, IM.ImGuiTableFlags.NoBordersInBody + IM.ImGuiTableFlags.Hideable)
  ImGui.TableSetupColumn("combo", IM.ImGuiTableColumnFlags.NoHeaderLabel + IM.ImGuiTableColumnFlags.WidthFixed, 200)
  ImGui.TableSetupColumn("filterText", IM.ImGuiTableColumnFlags.NoHeaderLabel + IM.ImGuiTableColumnFlags.WidthFixed, 200)
  ImGui.TableSetupColumn("enabled", IM.ImGuiTableColumnFlags.NoHeaderLabel + IM.ImGuiTableColumnFlags.WidthFixed, 70)

  --Todo: options for what to draw/labels
  -- print(self.Type, self.SelectedIndex, self.Properties, #self.Properties)
  ImGui.TableNextColumn()
  local changed, value = ImGui.Combo(self:TypeName() .. '=' .. #self.Properties .. label .. 'Combo',
    self.SelectedIndex - 1, self.Properties, #self.Properties)
  if changed then
    self.SelectedIndex = value + 1
    self:Callback()
  end


  --Change filter text
  ImGui.TableNextColumn()
  ImGui.SetNextItemWidth(160)
  local didChange, newValue = ImGui.InputText('Filter' .. label .. 'Filter', self.FilterText, 300)
  if didChange then self:SetFilter(newValue) end

  --Toggle missing props
  -- ImGui.TableNextColumn()
  -- if ImGui.Checkbox('Include missing' .. label  .. 'IncMiss', self.IncludeMissingProps) then
  --   self.IncludeMissingProps = not self.IncludeMissingProps
  --   self:UpdateFilter()
  -- end

  --Toggle missing props
  ImGui.TableNextColumn()
  if ImGui.Checkbox('Enabled' .. label .. 'Enabled', self.Enabled) then
    self.Enabled = not self.Enabled
    self:Callback()
  end


  --Set WorldObject to selected
  -- ImGui.SameLine()
  -- local name = 'Target'
  -- if self.Weenie ~= nil then name = self.Weenie.Name end
  -- if ImGui.Button(name .. label  .. 'Target') then
  --   if game.World.Selected ~= nil then self:SetFilter(nil, game.World.Selected)  print('Selected ', game.World.Selected.Name) end
  -- end

  ImGui.EndTable()
end

---@param self PropFilter Starts checking if its time to rebuild Properties
function PropFilter:CheckUpdate()
  -- print(self.Updating, (DateTime.UtcNow - self.LastKey).TotalSeconds)
  if not self.Updating then
    self.Updating = true

    self.updCheck = game.OnRender2D.Add(function(evt)
      if not self.Updating then return end

      if (DateTime.UtcNow - self.LastKey).Milliseconds < self.UpdateInterval then return end

      self.Updating = false
      self.LastKey = DateTime.UtcNow

      self:BuildPropList()
      game.OnRender2D.Remove(self.updCheck)

    end)
  end
end

---Invoked in Draw
function PropFilter:Callback() end

return PropFilter
