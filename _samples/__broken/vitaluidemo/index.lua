--[[
  Vital Bar Replacement
]]

local ImGui = require("imgui")
local views = require("utilitybelt.views")
local im = ImGui.ImGui

local vitals = {
  [VitalId.Health] = { Current = 0, Max = 0, LaggedCurrent = 0, Color = 0x770000ff, LaggedColor = 0x77000099 },
  [VitalId.Stamina] = { Current = 0, Max = 0, LaggedCurrent = 0, Color = 0x7700aaaa, LaggedColor = 0x77009999 },
  [VitalId.Mana] = { Current = 0, Max = 0, LaggedCurrent = 0, Color = 0x77ff0000, LaggedColor = 0x77990000 },
}

local lastTick = os.clock()
local hud = views.Huds.CreateHud("Vital UI Demo###VitalUIDemo2")
hud.ShowInBar = false
hud.Visible = true
hud.WindowSettings = ImGui.ImGuiWindowFlags.NoInputs.AddFlags(
  ImGui.ImGuiWindowFlags.NoBringToFrontOnFocus,
  ImGui.ImGuiWindowFlags.NoTitleBar,
  ImGui.ImGuiWindowFlags.NoBackground,
  ImGui.ImGuiWindowFlags.NoFocusOnAppearing
)

hud.OnPreRender.Add(function ()
  for i,vitalId in ipairs({ VitalId.Health, VitalId.Stamina, VitalId.Mana }) do
    local changed = vitals[vitalId].Current - game.Character.Weenie.Vitals[vitalId].Current
    vitals[vitalId].Current = game.Character.Weenie.Vitals[vitalId].Current
    vitals[vitalId].Max = game.Character.Weenie.Vitals[vitalId].Max
    vitals[vitalId].LaggedCurrent = vitals[vitalId].LaggedCurrent + changed
    if vitals[vitalId].Current > vitals[vitalId].LaggedCurrent then
      vitals[vitalId].LaggedCurrent = vitals[vitalId].Current
    end
  end
  PreRenderSimpleVitals()
end)

hud.OnRender.Add(function()
  local delta = os.clock() - lastTick
  lastTick = os.clock()
  RenderSimpleVitals(delta)
end)

function PreRenderSimpleVitals()
  local centerPos = im.GetMainViewport().GetCenter()
  local size = Vector2.new(300,60)
  im.SetNextWindowPos(centerPos - (size / 2))
  im.SetNextWindowSize(size)
end

function RenderSimpleVitals(delta)

  im.InvisibleButton("rendercanvas", im.GetContentRegionAvail())
  local p0 = im.GetItemRectMin();
  local p1 = im.GetItemRectMax();
  local size = im.GetItemRectSize()

  local drawList = im.GetWindowDrawList()
  drawList.PushClipRect(p0, p1);

  local borderColor = 0x77ffffff
  local textColor = 0xffffffff
  local lagDamageColor = 0x77777777

  local pos = p0
  local vitalSize = Vector2.new(size.X, size.Y / 3)
  for vitalId, vital in pairs(vitals) do
    -- border
    drawList.AddRect(pos, pos + vitalSize, borderColor)

    -- current vital
    drawList.AddRectFilled(pos, pos + Vector2.new(vitalSize.X * (vital.Current / vital.Max), vitalSize.Y), vital.Color)

    -- draw a "lagging" bar, to show recent damage taken
    local diff = vital.LaggedCurrent - vital.Current
    if diff > 0 then
      local lagStart = pos + Vector2.new(vitalSize.X * (vital.Current / vital.Max), 0)
      local lagEnd = lagStart + Vector2.new(vitalSize.X * (diff / vital.Max) / 2, vitalSize.Y)
      drawList.AddRectFilled(lagStart, lagEnd, 0xffff00ff)
      vital.LaggedCurrent = vital.LaggedCurrent - delta * 35
    end

    -- vital text
    local text = string.format("%-10s", tostring(vitalId)..":") .. tostring(vital.Current) .. " / " .. tostring(vital.Max)
    drawList.AddText(pos + Vector2.new(2, 2), textColor, text)

    pos = pos + Vector2.new(0, vitalSize.Y)
  end

  drawList.PopClipRect();
end