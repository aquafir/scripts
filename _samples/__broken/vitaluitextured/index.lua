--[[
  Vital Bar Replacement
]]

local ImGui = require("imgui")
local views = require("utilitybelt.views")
local im = ImGui.ImGui

local borderTexture = views.Huds.CreateTexture("border.png")
local vitals = {
  [VitalId.Health] = { Texture = views.Huds.CreateTexture("health.png") },
  [VitalId.Stamina] = {  Texture = views.Huds.CreateTexture("stamina.png") },
  [VitalId.Mana] = {  Texture = views.Huds.CreateTexture("mana.png") },
}

local hud = views.Huds.CreateHud("Vital UI Demo###VitalUIDemo4")
hud.ShowInBar = false
hud.Visible = true
hud.WindowSettings = ImGui.ImGuiWindowFlags.NoInputs.AddFlags(
  ImGui.ImGuiWindowFlags.NoBringToFrontOnFocus,
  ImGui.ImGuiWindowFlags.NoTitleBar,
  ImGui.ImGuiWindowFlags.NoBackground,
  ImGui.ImGuiWindowFlags.NoFocusOnAppearing
)

hud.OnPreRender.Add(function ()
  local centerPos = im.GetMainViewport().GetCenter() + Vector2.new(100, 0)
  local size = Vector2.new(500,300)
  im.SetNextWindowPos(centerPos - (size / 2))
  im.SetNextWindowSize(size)
end)

hud.OnRender.Add(function()
  im.InvisibleButton("rendercanvas", im.GetContentRegionAvail())
  local p0 = im.GetItemRectMin();
  local p1 = im.GetItemRectMax();
  local size = im.GetItemRectSize()

  local drawList = im.GetWindowDrawList()
  drawList.PushClipRect(p0, p1);

  local textColor = 0xffffffff

  local pos = p0
  local vitalSize = Vector2.new(100, size.Y)
  for vitalId, vital in pairs(vitals) do
    local v = game.Character.Weenie.Vitals[vitalId]
    local dstart = vitalId ~= VitalId.Health and pos or pos + vitalSize
    local dend = vitalId ~= VitalId.Health and pos + vitalSize or pos

    -- background texture
    if vitalId ~= VitalId.Health then
      drawList.PushClipRect(Vector2.new(dstart.X, dstart.Y + vitalSize.Y - vitalSize.Y * (v.Current / v.Max)), dend);
    else
      drawList.PushClipRect(Vector2.new(dend.X, dend.Y + vitalSize.Y - vitalSize.Y * (v.Current / v.Max)), dstart);
    end
    drawList.AddImage(vital.Texture.TexturePtr, dstart, dend)
    drawList.PopClipRect();

    -- border
    drawList.AddImage(borderTexture.TexturePtr, dstart, dend)

    if vitalId == VitalId.Health then
      pos = pos + Vector2.new(vitalSize.X * 2, 0)
    else 
      pos = pos + Vector2.new(vitalSize.X / 2, 0)
    end
  end

  drawList.PopClipRect();
end)