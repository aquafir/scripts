local ImGui = require("imgui")
local views = require("utilitybelt.views")
local im = ImGui.ImGui

---@type VitalBar
local SimpleVitals = {}
local lastTick = 0
local maxHeight = 0
local maxWidth = 0

--- Get a default profile
---@returns SettingsProfile
function SimpleVitals.GetDefaultProfile()
  return {
    OffsetX = 0,
    OffsetY = 0,
    Vitals = {
      Health = {
        FGTint = 0xffffffff,
        BGTint = 0xcc0000ff,
        BorderTint = 0xcc000088,
        Width = 200,
        Height = 20,
        OffsetX = 0,
        OffsetY = 0,
        DamageTint = 0xcc666666,
        HealTint = 0xcc0000aa
      },
      Stamina = {
        FGTint = 0xff000000,
        BGTint = 0xcc00ffff,
        BorderTint = 0xcc008888,
        Width = 200,
        Height = 20,
        OffsetX = 0,
        OffsetY = 20,
        DamageTint = 0xcc666666,
        HealTint = 0xcc00aaaa
      },
      Mana = {
        FGTint = 0xffffffff,
        BGTint = 0xccff0000,
        BorderTint = 0xcc880000,
        Width = 200,
        Height = 20,
        OffsetX = 0,
        OffsetY = 40,
        DamageTint = 0xcc666666,
        HealTint = 0xccaa0000
      }
    }
  }
end

---@param settings SettingsProfile
function SimpleVitals.PreRender(settings)
  local minX = 0
  local minY = 0
  local maxX = 0
  local maxY = 0
  for i,v in pairs(settings.Vitals) do
    if v.OffsetY < minY then minY = v.OffsetY end
    if v.OffsetX < minX then minX = v.OffsetX end
    if v.Height + v.OffsetY > maxY then maxY = v.Height + v.OffsetY end
    if v.Width + v.OffsetX > maxX then maxX = v.Width + v.OffsetX end
  end

  maxWidth = maxX - minX
  maxHeight = maxY - minY

  local centerPos = im.GetMainViewport().GetCenter() - Vector2.new(0, im.GetMainViewport().WorkSize.Y / 2) + Vector2.new(settings.OffsetX, settings.OffsetY)
  local size = Vector2.new(maxWidth + 20, maxHeight + 20)
  im.SetNextWindowPos(Vector2.new(centerPos.X - (size.X / 2), centerPos.Y))
  im.SetNextWindowSize(size)
end

---@param settings SettingsProfile
function SimpleVitals.Render(settings)
  im.InvisibleButton("rendercanvas", im.GetContentRegionAvail())
  local p0 = im.GetItemRectMin();
  local p1 = im.GetItemRectMax();
  local size = im.GetItemRectSize()

  local drawList = im.GetWindowDrawList()
  drawList.PushClipRect(p0, p1);

  for vitalId, vital in pairs(game.Character.Weenie.Vitals) do
    local vitalConfig = settings.Vitals[tostring(vitalId)]
    local pos = p0 + Vector2.new(vitalConfig.OffsetX, vitalConfig.OffsetY)
    local vitalSize = Vector2.new(vitalConfig.Width, vitalConfig.Height)

    -- border
    drawList.AddRect(pos, pos + vitalSize, vitalConfig.BorderTint)

    -- current vital
    drawList.AddRectFilled(pos, pos + Vector2.new(vitalSize.X * (vital.Current / vital.Max), vitalSize.Y), vitalConfig.BGTint)

    -- vital text
    local text = string.format("%-10s", tostring(vitalId)..":") .. tostring(vital.Current) .. " / " .. tostring(vital.Max)
    drawList.AddText(pos + Vector2.new(2, 2), vitalConfig.FGTint, text)
  end

  drawList.PopClipRect();
end

return SimpleVitals