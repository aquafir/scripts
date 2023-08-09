local views = require("utilitybelt.views")
local ImGui = require("imgui")
local im = ImGui.ImGui

local selected = nil

---@class InventoryHud
---@field Hud Hud -- The backing imgui hud
---@field FilterText string -- The current filter text
---@field ShowBags boolean -- If true, shows bags on the sidebar. If false, everything is in one bag
---@field ShowIcons boolean -- If true, draws an icon grid. If false, draws a table
---@field IconSize Vector2 -- The size of icons to draw
---@field SelectedBag number -- The id of the currently selected bag / container
local InventoryHud = {
  FilterText = "",
  ShowBags = true,
  ShowIcons = false,
  IconSize = Vector2.new(24, 24),
  SelectedBag = game.CharacterId,
  columnFlags = {
    ImGui.ImGuiTableColumnFlags.WidthFixed,
    ImGui.ImGuiTableColumnFlags.DefaultSort + ImGui.ImGuiTableColumnFlags.IsSorted,
    ImGui.ImGuiTableColumnFlags.None,
    ImGui.ImGuiTableColumnFlags.None
  }
}

local _woTextures = {}

---Get or create a managed texture for a world object
---@param wo WorldObject -- The WorldObject to get a texture for
function GetOrCreateTexture(wo)
  if _woTextures[wo.WeenieClassId] == nil then
    local texture ---@type ManagedTexture
    if (wo.Id == game.Character.Id) then
      texture = views.Huds.GetIconTexture(0x0600127E)
    else
      texture = views.Huds.GetIconTexture(wo.Value(DataId.Icon))
    end
    _woTextures[wo.WeenieClassId] = texture
  end

  return _woTextures[wo.WeenieClassId]
end

---Draw an item icon
---@param s InventoryHud
---@param index number
---@param wo WorldObject
function DrawItemIcon(s, index, wo)
  local pad = 4
  local availWidth = im.GetContentRegionAvail().X - ((pad * 2))
  local currentWidth = (s.DrawItemIndex * (s.IconSize.X + pad * 2)) + s.IconSize.X
  if index ~= 1 and currentWidth + pad * 2 + s.IconSize.X < availWidth then
    if true then im.SameLine() end
  else
    s.DrawItemIndex = -1
  end

  local texture = GetOrCreateTexture(wo)
  im.TextureButton(tostring(wo.Id), texture, s.IconSize)
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.TextureButton(tostring(wo.Id) .. "-tt", texture, s.IconSize)
    im.SameLine()
    im.Text(wo.Name)

    im.Text("Value: " .. tostring(wo.Value(IntId.Value)))
    im.Text("ObjectClass: " .. tostring(wo.ObjectClass))

    im.EndTooltip()
  end
  if im.BeginPopupContextItem() then
    im.MenuItem("Drop")
    im.MenuItem("Salvage")
    im.EndPopup()
  end

  s.DrawItemIndex = s.DrawItemIndex + 1
end

---Draw a bag icon
---@param s InventoryHud
---@param wo WorldObject
function DrawBagIcon(s, wo)
  if im.TextureButton(tostring(wo.Id), GetOrCreateTexture(wo), s.IconSize) then
    s.SelectedBag = wo.Id
  end
end

function Sort(isAscending, a, b)
  if isAscending then 
    return a < b
  else
    return a > b
  end
end

---Draw a bag contents
---@param s InventoryHud
---@param items { [number]: WorldObject }
function DrawBag(s, items)
  local filterText = s.FilterText:lower()

  local wos = {}
  for i,k in ipairs(items) do table.insert(wos, k) end

  if not s.ShowIcons then
    local flags = ImGui.ImGuiTableFlags.None + ImGui.ImGuiTableFlags.BordersInner + ImGui.ImGuiTableFlags.Resizable +  ImGui.ImGuiTableFlags.RowBg + ImGui.ImGuiTableFlags.Reorderable + ImGui.ImGuiTableFlags.Hideable + ImGui.ImGuiTableFlags.ScrollY + ImGui.ImGuiTableFlags.Sortable
    im.BeginTable("items-table", 4, flags, im.GetContentRegionAvail())
    im.TableSetupColumn("###Icon", s.columnFlags[1], 16)
    im.TableSetupColumn("Name", s.columnFlags[2])
    im.TableSetupColumn("Value", s.columnFlags[3])
    im.TableSetupColumn("ObjectClass", s.columnFlags[4])
    im.TableHeadersRow()

    for colIndex=0, im.TableGetColumnCount(), 1 do
      s.columnFlags[colIndex + 1] = im.TableGetColumnFlags(colIndex)
    end

    local specs = im.TableGetSortSpecs()
    -- todo: needs tri sort support
    if specs ~= nil and specs.SortDirection ~= ImGui.ImGuiSortDirection.None then
      local asc = specs.SortDirection == ImGui.ImGuiSortDirection.Ascending
      local cIndex = specs.ColumnIndex
      table.sort(wos, function (a, b)
        if cIndex == 0 then
          return Sort(asc, a.Value(DataId.Icon), b.Value(DataId.Icon))
        elseif cIndex == 1 then
          return Sort(asc, a.Name, b.Name)
        elseif cIndex == 2 then
          return Sort(asc, a.Value(IntId.Value), b.Value(IntId.Value))
        elseif cIndex == 3 then
          return Sort(asc, tostring(a.ObjectClass), tostring(b.ObjectClass))
        end
      end)
    end
  else 
    im.BeginChild("items", im.GetContentRegionAvail(), false, ImGui.ImGuiWindowFlags.None)
  end

  for i,item in ipairs(wos) do
    if filterText == "" or item.Name:lower():match(filterText) then
      if s.ShowIcons then
        DrawItemIcon(s, i, item)
      else
        im.TableNextRow()
        im.TableSetColumnIndex(0)
        local texture = GetOrCreateTexture(item)
        -- im.TextureButton(tostring(item.Id), texture, Vector2.new(16, 16)
        if im.TextureButton(tostring(item.Id), texture, Vector2.new(16, 16)) then selected = item.Id end
        im.TableSetColumnIndex(1)
        --edit
        if selected == item.Id then im.Text("**" .. item.Name .. "**") else
        im.Text(item.Name) end
        im.TableSetColumnIndex(2)
        im.Text(tostring(item.Value(IntId.Value)))
        im.TableSetColumnIndex(3)
        im.Text(tostring(item.ObjectClass))
      end
    end
  end

  if not s.ShowIcons then
    im.EndTable()
  else
    im.EndChild()
  end
end

---Create a new InventoryHud instance
---@param o table -- Options
---@return InventoryHud InventoryHud -- A new InventoryHud instance
function InventoryHud:new(o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  self.DrawItemIndex = 0

  self.Hud = views.Huds.CreateHud("Inventory UI")

  self.Hud.Visible = true
  self.Hud.WindowSettings = ImGui.ImGuiWindowFlags.NoScrollbar + ImGui.ImGuiWindowFlags.MenuBar
  
  self.Hud.OnPreRender.Add(function ()
    im.SetNextWindowSizeConstraints(Vector2.new(200, 300), Vector2.new(9999, 9999))
  end)
  
  self.Hud.OnRender.Add(function ()
    if im.BeginMenuBar() then
      if im.BeginMenu("Options") then
        if im.MenuItem("Show Bags", "", self.ShowBags) then
          self.ShowBags = not self.ShowBags
        end
        if im.MenuItem("Show Icons", "", self.ShowIcons) then
          self.ShowIcons = not self.ShowIcons
        end
        im.EndMenu()
      end
      im.EndMenuBar()
    end


    local didChange, newValue = im.InputText("Filter", self.FilterText, 512)
    if didChange then self.FilterText = newValue end

    self.DrawItemIndex = 0

    if self.ShowBags then
      im.BeginTable("layout", 2, ImGui.ImGuiTableFlags.BordersInner)
      im.TableSetupColumn("bags", ImGui.ImGuiTableColumnFlags.NoHeaderLabel + ImGui.ImGuiTableColumnFlags.WidthFixed, self.IconSize.X)
      im.TableSetupColumn("items", ImGui.ImGuiTableColumnFlags.NoHeaderLabel)
      im.TableNextColumn()

      DrawBagIcon(self, game.Character.Weenie)
      for i,bag in pairs(game.Character.Containers) do
        DrawBagIcon(self, bag)
      end

      im.TableNextColumn()
      local wo = game.World.Get(self.SelectedBag)
      im.Text("Selected Container: " .. tostring(wo))

      DrawBag(self, wo.Items)

      im.EndTable()
    else
      DrawBag(self, game.Character.Weenie.AllItems)
    end
  end)

  return o
end

local backpack = InventoryHud:new({})