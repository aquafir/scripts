local views = require("utilitybelt.views")
local IM = require("imgui")
local ImGui = IM.ImGui
local pf = require("propfilter")

---@type PropFilter[]
local propFilters = {}
local callbackTest = pf.new(PropType.String)
---@param self PropFilter
callbackTest.Callback = function (self)
    print('callback', self:TypeName())    
end
table.insert(propFilters, callbackTest)
-- table.insert(propFilters, pf.new(PropType.String):SetFilter('', game.Character.Weenie))
-- table.insert(propFilters, pf.new(PropType.Bool):SetFilter('', game.Character.Weenie))
-- table.insert(propFilters, pf.new(PropType.Int))
-- table.insert(propFilters, pf.new(PropType.Float))
-- table.insert(propFilters, pf.new(PropType.Int64))
-- table.insert(propFilters, pf.new(PropType.DataId))
-- table.insert(propFilters, pf.new(PropType.InstanceId))
--ObjectType filtering
local otypeProps = {}
for index, value in ipairs(ObjectType.GetValues()) do table.insert(otypeProps, value) end



---@class InventoryHud
---@field Hud Hud -- The backing imgui hud
---@field FilterText string|nil -- The current filter text
---@field FilterObjectType ObjectType|nil -- Selected ObjectType filter
---@field UseFilterType boolean -- Filter by ObjectType
---@field FilterRegex Regex Regex from FilterText
---@field FilterIntId IntId|nil -- Selected IntId filter
---@field FilterIntText string|nil -- The current filter for Int properties
---@field UseFilterInt boolean -- Filter by Int
---@field FilterStringId StringId|nil --
---@field FilterStringText string|nil --
---@field UseFilterString boolean --
---@field ShowBags boolean -- If true, shows bags on the sidebar. If false, everything is in one bag
---@field ShowIcons boolean -- If true, draws an icon grid. If false, draws a table
---@field ShowExtraFilters boolean -- If true, adds more filter options
---@field IconSize Vector2 -- The size of icons to draw
---@field SelectedBag number -- The id of the currently selected bag / container
local InventoryHud = {
    FilterText = "",
    ShowBags = true,
    ShowIcons = false,
    FilterObjectType = 0,
    UseFilterType = false,
    FilterIntId = 0,
    FilterIntText = '',
    UseFilterInt = false,
    FilterStringId = 0,
    FilterStringText = '',
    UseFilterString = true,
    ShowExtraFilters = true,
    IconSize = Vector2.new(24, 24),
    SelectedBag = game.CharacterId,
    columnFlags = {
        IM.ImGuiTableColumnFlags.WidthFixed,
        IM.ImGuiTableColumnFlags.DefaultSort + IM.ImGuiTableColumnFlags.IsSorted,
        IM.ImGuiTableColumnFlags.None,
        IM.ImGuiTableColumnFlags.None
    }
}

function Sort(isAscending, a, b)
    if isAscending then
        return a < b
    else
        return a > b
    end
end

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
    local availWidth = ImGui.GetContentRegionAvail().X - ((pad * 2))
    local currentWidth = (s.DrawItemIndex * (s.IconSize.X + pad * 2)) + s.IconSize.X
    if index ~= 1 and currentWidth + pad * 2 + s.IconSize.X < availWidth then
        if true then ImGui.SameLine() end
    else
        s.DrawItemIndex = -1
    end

    local texture = GetOrCreateTexture(wo)
    ImGui.TextureButton(tostring(wo.Id), texture, s.IconSize)

    DrawItemTooltip(wo, texture, s)
    DrawItemContextMenu(wo)

    s.DrawItemIndex = s.DrawItemIndex + 1
end

---Draw a bag icon
---@param s InventoryHud
---@param wo WorldObject
function DrawBagIcon(s, wo)
    if ImGui.TextureButton(tostring(wo.Id), GetOrCreateTexture(wo), s.IconSize) then
        s.SelectedBag = wo.Id
    end
    DrawBagItemTooltip(wo)
    DrawBagContextMenu(wo)
end

---@param wo WorldObject
function DrawBagContextMenu(wo)
    if ImGui.BeginPopupContextItem() then
        if ImGui.MenuItem("Drop") then wo.Drop() end
        if ImGui.MenuItem("Give Selected") then
            if game.World.Selected ~= nil then
                wo.Give(game.World.Selected.Id)
            else
                print('Nothing selected')
            end
        end
        if ImGui.MenuItem("Give Player") then
            if game.World.Selected ~= nil and game.World.Selected.ObjectClass == ObjectClass.Player then
                wo.Give(game.World.Selected.Id)
            else
                wo.Give(game.World.GetNearest(ObjectClass.Player).Id)
            end
        end
        if ImGui.MenuItem("Give Vendor") then
            if game.World.Selected ~= nil and game.World.Selected.ObjectClass == ObjectClass.Vendor then
                wo.Give(game.World.Selected.Id)
            else
                wo.Give(game.World.GetNearest(ObjectClass.Vendor).Id)
            end
        end



        ImGui.EndPopup()
    end
end

---Draw a bag contents
---@param s InventoryHud
---@param items { [number]: WorldObject }
function DrawBagItems(s, items)
    local wos = {}
    for i, k in ipairs(items) do table.insert(wos, k) end

    if not s.ShowIcons then
        local flags = IM.ImGuiTableFlags.None + IM.ImGuiTableFlags.BordersInner + IM.ImGuiTableFlags.Resizable +
            IM.ImGuiTableFlags.RowBg + IM.ImGuiTableFlags.Reorderable + IM.ImGuiTableFlags.Hideable +
            IM.ImGuiTableFlags.ScrollY + IM.ImGuiTableFlags.Sortable
        ImGui.BeginTable("items-table", 4, flags, ImGui.GetContentRegionAvail())
        ImGui.TableSetupColumn("###Icon", s.columnFlags[1], 16)
        ImGui.TableSetupColumn("Name", s.columnFlags[2])
        ImGui.TableSetupColumn("Value", s.columnFlags[3])
        ImGui.TableSetupColumn("ObjectClass", s.columnFlags[4])
        ImGui.TableHeadersRow()

        for colIndex = 0, ImGui.TableGetColumnCount(), 1 do
            s.columnFlags[colIndex + 1] = ImGui.TableGetColumnFlags(colIndex)
        end

        local specs = ImGui.TableGetSortSpecs()
        -- todo: needs tri sort support
        if specs ~= nil and specs.SortDirection ~= IM.ImGuiSortDirection.None then
            local asc = specs.SortDirection == IM.ImGuiSortDirection.Ascending
            local cIndex = specs.ColumnIndex
            table.sort(wos, function(a, b)
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
        ImGui.BeginChild("items", ImGui.GetContentRegionAvail(), false, IM.ImGuiWindowFlags.None)
    end

    for i, item in ipairs(wos) do
        if not IsFiltered(item, s)
        then
            if s.ShowIcons then
                DrawItemIcon(s, i, item)
            else
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                local texture = GetOrCreateTexture(item)
                ImGui.TextureButton(tostring(item.Id), texture, Vector2.new(16, 16))

                DrawItemContextMenu(item)

                ImGui.TableSetColumnIndex(1)
                ImGui.Text(item.Name)
                ImGui.TableSetColumnIndex(2)
                ImGui.Text(tostring(item.Value(IntId.Value)))
                ImGui.TableSetColumnIndex(3)
                ImGui.Text(tostring(item.ObjectClass))
            end
        end
    end

    if not s.ShowIcons then
        ImGui.EndTable()
    else
        ImGui.EndChild()
    end
end

---Draws hovered details for Container
---@param wo WorldObject
function DrawBagItemTooltip(wo)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(wo.Name)
        ImGui.Text("Value: " .. tostring(wo.Value(IntId.Value)))
        ImGui.Text("Burden: " .. wo.Burden)
        local count = #wo.Items
        ImGui.Text("Capacity: " .. count .. "/" .. wo.IntValues[IntId.ItemsCapacity])
        ImGui.EndTooltip()
    end
end

---Draws hovered details for WorldObject
---@param s InventoryHud
---@param texture any
---@param wo WorldObject
function DrawItemTooltip(wo, texture, s)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.TextureButton(tostring(wo.Id) .. "-tt", texture, s.IconSize)
        ImGui.SameLine()
        ImGui.Text(wo.Name)

        ImGui.Text("Value: " .. tostring(wo.Value(IntId.Value)))
        ImGui.Text("ObjectClass: " .. tostring(wo.ObjectClass))

        ImGui.EndTooltip()
    end
end

---@param wo WorldObject
function DrawItemContextMenu(wo)
    if ImGui.BeginPopupContextItem() then
        if ImGui.MenuItem("Split?") then print('todo') end
        if ImGui.MenuItem("Select") then wo.Select() end
        if ImGui.MenuItem("Drop") then wo.Drop() end
        if ImGui.MenuItem("Use") then wo.Use() end
        if ImGui.MenuItem("Use Self") then wo.UseOn(game.CharacterId) end
        if ImGui.MenuItem("Give Selected") then
            if game.World.Selected ~= nil then
                wo.Give(game.World.Selected.Id)
            else
                print('Nothing selected')
            end
        end
        if ImGui.MenuItem("Give NPC") then
            if game.World.Selected ~= nil and game.World.Selected.ObjectClass == ObjectClass.Npc then
                wo.Give(game.World.Selected.Id)
            else
                wo.Give(game.World.GetNearest(ObjectClass.Npc).Id)
            end
        end
        if ImGui.MenuItem("Give Player") then
            if game.World.Selected ~= nil and game.World.Selected.ObjectClass == ObjectClass.Player then
                wo.Give(game.World.Selected.Id)
            else
                wo.Give(game.World.GetNearest(ObjectClass.Player).Id)
            end
        end
        -- if ImGui.MenuItem("Give Vendor") then
        --     if game.World.Selected ~= nil and game.World.Selected.ObjectClass == ObjectClass.Vendor then
        --         wo.Give(game.World.Selected.Id)
        --     else
        --         wo.Give(game.World.GetNearest(ObjectClass.Vendor).Id)
        --     end
        -- end
        if ImGui.MenuItem("Salvage") then
            --game.Actions.Salvage()
            game.Actions.SalvageAdd(wo.Id)
        end
        ImGui.EndPopup()
    end
end

---@param s InventoryHud
function DrawOptions(s)
    if ImGui.BeginMenuBar() then
        if ImGui.BeginMenu("Options") then
            if ImGui.MenuItem("Show Bags", "", s.ShowBags) then
                s.ShowBags = not s.ShowBags
            end
            if ImGui.MenuItem("Show Icons", "", s.ShowIcons) then
                s.ShowIcons = not s.ShowIcons
            end
            if ImGui.MenuItem("Show Extra Filters", "", s.ShowExtraFilters) then
                s.ShowExtraFilters = not s.ShowExtraFilters
            end
            ImGui.EndMenu()
        end
        ImGui.EndMenuBar()
    end
end

---@param s InventoryHud
function DrawFilter(s)
    --Basic name filter
    local didChange, newValue = ImGui.InputText("Filter", s.FilterText, 512)
    if didChange then 
        s.FilterText = newValue 
        s.FilterRegex = Regex.new(newValue, RegexOptions.Compiled + RegexOptions.IgnoreCase)
    end

    --Extra filter section
    if not s.ShowExtraFilters then return end

    local comboWidth = 150
    local filterWidth = 200

    for index, value in ipairs(propFilters) do
        -- ImGui.SetNextItemWidth(comboWidth)
        -- print('test', value:TypeName())
        value:DrawCombo()
    end
    --ObjectType
    ImGui.SetNextItemWidth(comboWidth)
    local didChange, newValue = ImGui.Combo("###ObjectTypeCombo", s.FilterObjectType - 1, otypeProps, #otypeProps)
    if didChange then s.FilterObjectType = newValue + 1 end
    ImGui.SameLine()
    --ImGui.SameLine(comboWidth + filterWidth + 24)
    if ImGui.Checkbox('Class', s.UseFilterType) then s.UseFilterType = not s.UseFilterType end

    -- --PropertyInt
    -- ImGui.SetNextItemWidth(comboWidth)
    -- local didChange, newValue = ImGui.Combo("###IntCombo", s.FilterIntId - 1, intProps, #intProps)
    -- if didChange then s.FilterIntId = newValue + 1 end
    -- ImGui.SetNextItemWidth(filterWidth)
    -- ImGui.SameLine()
    -- local didChange, newValue = ImGui.InputText("###IntFilter", s.FilterIntText, 512)
    -- if didChange then s.FilterIntText = newValue end
    -- ImGui.SameLine()
    -- if ImGui.Checkbox('Int', s.UseFilterInt) then s.UseFilterInt = not s.UseFilterInt end

    -- --PropertyString
    -- ImGui.SetNextItemWidth(comboWidth)
    -- local didChange, newValue = ImGui.Combo("###StringCombo", s.FilterStringId - 1, stringProps, #stringProps)
    -- if didChange then s.FilterStringId = newValue + 1 end
    -- ImGui.SetNextItemWidth(filterWidth)
    -- ImGui.SameLine()
    -- local didChange, newValue = ImGui.InputText("###StringFilter", s.FilterStringText, 512)
    -- if didChange then s.FilterStringText = newValue end
    -- ImGui.SameLine()
    -- if ImGui.Checkbox('String', s.UseFilterString) then s.UseFilterString = not s.UseFilterString end
end

---@param s InventoryHud
function DrawInventory(s)
    s.DrawItemIndex = 0

    if s.ShowBags then
        --Create a 2-column table for bags and inventory
        ImGui.BeginTable("layout", 2, IM.ImGuiTableFlags.BordersInner)
        ImGui.TableSetupColumn("bags", IM.ImGuiTableColumnFlags.NoHeaderLabel + IM.ImGuiTableColumnFlags.WidthFixed,
            s.IconSize.X)
        ImGui.TableSetupColumn("items", IM.ImGuiTableColumnFlags.NoHeaderLabel)
        ImGui.TableNextColumn()

        --Draw player and containers
        DrawBagIcon(s, game.Character.Weenie)
        for i, bag in pairs(game.Character.Containers) do
            DrawBagIcon(s, bag)
        end

        --Move to next column and render selected bag
        ImGui.TableNextColumn()
        local wo = game.World.Get(s.SelectedBag)
        ImGui.Text("Selected Container: " .. tostring(wo))

        DrawBagItems(s, wo.Items)

        ImGui.EndTable()
    else
        --Render all items
        DrawBagItems(s, game.Character.Weenie.AllItems)
    end
end

---Returns true if an object is filtered given the current options and filters
---@param wo WorldObject
---@param s InventoryHud
---@returns boolean
function IsFiltered(wo, s)
    --Filter by text
    local filterText = s.FilterText:lower()
    if filterText ~= "" and not wo.Name:lower():match(filterText) then return true end
    if filterText ~= "" and not s.FilterRegex.IsMatch(wo.Name) then return true end
    --Filter by ObjectType
    if s.ShowExtraFilters and s.UseFilterType and wo.ObjectType ~= s.FilterObjectType then return true end

    --Filter by StringProp
    if s.ShowExtraFilters and s.UseFilterString and s.FilterStringId > 0 then
        local filterText = s.FilterStringText:lower()
        if filterText ~= "" then
            --Require property if filter present
            if not wo.HasValue(stringProps[s.FilterStringId]) then return true end

            local propValue = wo.StringValues[stringProps[s.FilterStringId]]:lower()
            --print(filterText, ' - - ', propValue, filterText ~= "" and propValue:match(filterText) ~= nil)
            if filterText ~= "" and not propValue:match(filterText) then return true end
        end
    end
    --Display prop?

    return false
end

---Create a new InventoryHud instance
---@param o table -- Options
---@return InventoryHud InventoryHud -- A new InventoryHud instance
function InventoryHud:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    self.DrawItemIndex = 0

    self.Hud = views.Huds.CreateHud("Inventory UI")

    self.Hud.Visible = true
    self.Hud.WindowSettings = IM.ImGuiWindowFlags.NoScrollbar + IM.ImGuiWindowFlags.MenuBar

    self.Hud.OnPreRender.Add(function()
        ImGui.SetNextWindowSizeConstraints(Vector2.new(200, 300), Vector2.new(9999, 9999))
    end)

    self.Hud.OnRender.Add(function()
        DrawOptions(self)
        DrawFilter(self)
        DrawInventory(self)
    end)

    return o
end

local backpack = InventoryHud:new({})
