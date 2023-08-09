local views = require("utilitybelt.views")
local IM = require("imgui")
local ImGui = IM.ImGui

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
        IM.ImGuiTableColumnFlags.WidthFixed,
        IM.ImGuiTableColumnFlags.DefaultSort + IM.ImGuiTableColumnFlags.IsSorted,
        IM.ImGuiTableColumnFlags.None,
        IM.ImGuiTableColumnFlags.None
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
    local availWidth = ImGui.GetContentRegionAvail().X - ((pad * 2))
    local currentWidth = (s.DrawItemIndex * (s.IconSize.X + pad * 2)) + s.IconSize.X
    if index ~= 1 and currentWidth + pad * 2 + s.IconSize.X < availWidth then
        if true then ImGui.SameLine() end
    else
        s.DrawItemIndex = -1
    end

    local texture = GetOrCreateTexture(wo)
    ImGui.TextureButton(tostring(wo.Id), texture, s.IconSize)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.TextureButton(tostring(wo.Id) .. "-tt", texture, s.IconSize)
        ImGui.SameLine()
        ImGui.Text(wo.Name)

        ImGui.Text("Value: " .. tostring(wo.Value(IntId.Value)))
        ImGui.Text("ObjectClass: " .. tostring(wo.ObjectClass))

        ImGui.EndTooltip()
    end

    DrawContextMenu(wo)

    s.DrawItemIndex = s.DrawItemIndex + 1
end

---Draw a bag icon
---@param s InventoryHud
---@param wo WorldObject
function DrawBagIcon(s, wo)
    if ImGui.TextureButton(tostring(wo.Id), GetOrCreateTexture(wo), s.IconSize) then
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
        if filterText == "" or item.Name:lower():match(filterText) then
            if s.ShowIcons then
                DrawItemIcon(s, i, item)
            else
                ImGui.TableNextRow()
                ImGui.TableSetColumnIndex(0)
                local texture = GetOrCreateTexture(item)
                if ImGui.TextureButton(tostring(item.Id), texture, Vector2.new(16, 16)) then selected = item.Id end

                DrawContextMenu(item)

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

---@param wo WorldObject
function DrawContextMenu(wo)
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
        if ImGui.BeginMenuBar() then
            if ImGui.BeginMenu("Options") then
                if ImGui.MenuItem("Show Bags", "", self.ShowBags) then
                    self.ShowBags = not self.ShowBags
                end
                if ImGui.MenuItem("Show Icons", "", self.ShowIcons) then
                    self.ShowIcons = not self.ShowIcons
                end
                ImGui.EndMenu()
            end
            ImGui.EndMenuBar()
        end

        local didChange, newValue = ImGui.InputText("Filter", self.FilterText, 512)
        if didChange then self.FilterText = newValue end

        self.DrawItemIndex = 0

        if self.ShowBags then
            ImGui.BeginTable("layout", 2, IM.ImGuiTableFlags.BordersInner)
            ImGui.TableSetupColumn("bags", IM.ImGuiTableColumnFlags.NoHeaderLabel + IM.ImGuiTableColumnFlags.WidthFixed,
                self.IconSize.X)
            ImGui.TableSetupColumn("items", IM.ImGuiTableColumnFlags.NoHeaderLabel)
            ImGui.TableNextColumn()

            DrawBagIcon(self, game.Character.Weenie)
            for i, bag in pairs(game.Character.Containers) do
                DrawBagIcon(self, bag)
            end

            ImGui.TableNextColumn()
            local wo = game.World.Get(self.SelectedBag)
            ImGui.Text("Selected Container: " .. tostring(wo))

            DrawBag(self, wo.Items)

            ImGui.EndTable()
        else
            DrawBag(self, game.Character.Weenie.AllItems)
        end
    end)

    return o
end

local backpack = InventoryHud:new({})
