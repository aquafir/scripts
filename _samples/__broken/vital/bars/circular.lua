local ImGui = require("imgui")
local views = require("utilitybelt.views")
local im = ImGui.ImGui

local borderTexture = views.Huds.CreateTexture("border.png")
local backgroundTexture = views.Huds.CreateTexture("background.png")

local uv_min = Vector2.new(0,0)
local uv_max = Vector2.new(1,1)
local maxHeight = 0
local maxWidth = 0

---@type VitalBar
CircularVitals = {}


--- Get a default profile
---@returns SettingsProfile
function CircularVitals.GetDefaultProfile()
  return {
    OffsetX = 0,
    OffsetY = 0,
    Vitals = {
      Health = {
        FGTint = 0xffffffff,
        BGTint = 0xcc0000ff,
        BorderTint = 0xcc000088,
        Width = 50,
        Height = 200,
        OffsetX = 100,
        OffsetY = 0,
        DamageTint = 0xcc666666,
        HealTint = 0xcc0000aa
      },
      Stamina = {
        FGTint = 0xffffffff,
        BGTint = 0xcc00ffff,
        BorderTint = 0xcc008888,
        Width = 30,
        Height = 300,
        OffsetX = 185,
        OffsetY = 0,
        DamageTint = 0xcc666666,
        HealTint = 0xcc00aaaa
      },
      Mana = {
        FGTint = 0xffffffff,
        BGTint = 0xccff0000,
        BorderTint = 0xcc880000,
        Width = 30,
        Height = 300,
        OffsetX = 204,
        OffsetY = 0,
        DamageTint = 0xcc666666,
        HealTint = 0xccaa0000
      }
    }
  }
end

---@param settings SettingsProfile
function CircularVitals.PreRender(settings)
  maxHeight = 0
  maxWidth = 0
  for i,v in pairs(settings.Vitals) do
    if v.Height + v.OffsetY > maxHeight then
      maxHeight = v.Height + (math.abs(v.OffsetY) * 2)
    end
    if v.Width + v.OffsetX > maxWidth then
      maxWidth = v.Width + v.OffsetX
    end
  end

  local centerPos = im.GetMainViewport().GetCenter() + Vector2.new(settings.OffsetX, settings.OffsetY)
  local size = Vector2.new(maxWidth * 2 + 60, maxHeight + 20)
  im.SetNextWindowPos(centerPos - (size / 2))
  im.SetNextWindowSize(size)
end

---@param settings SettingsProfile
function CircularVitals.Render(settings)
  im.InvisibleButton("rendercanvas", im.GetContentRegionAvail())
  local p0 = im.GetItemRectMin();
  local p1 = im.GetItemRectMax();
  local veryTopCenter = Vector2.new(p0.X + (p1.X - p0.X) / 2, p0.Y)

  local drawList = im.GetWindowDrawList()
  drawList.PushClipRect(p0, p1);

  for vitalId, vital in pairs(game.Character.Weenie.Vitals) do
    local vitalConfig = settings.Vitals[tostring(vitalId)]
    local topCenter = Vector2.new(veryTopCenter.X, veryTopCenter.Y + (maxHeight - vitalConfig.Height) / 2)
    local rightStart = topCenter + Vector2.new(vitalConfig.OffsetX, vitalConfig.OffsetY)
    local leftStart = topCenter - Vector2.new(vitalConfig.OffsetX, -vitalConfig.OffsetY) - Vector2.new(vitalConfig.Width, 0)

    -- right side
    CircularVitals.DrawVitalBar(drawList, vitalConfig, vital, rightStart)
    -- left side
    CircularVitals.DrawVitalBar(drawList, vitalConfig, vital, leftStart, true)
  end

  drawList.PopClipRect()
end

---comment
---@param drawList ImDrawListPtr
---@param vitalConfig any
---@param vital Vital
---@param topLeft Vector2
---@param invert? boolean
function CircularVitals.DrawVitalBar(drawList, vitalConfig, vital, topLeft, invert)
  local bottomRight = topLeft + Vector2.new(vitalConfig.Width, vitalConfig.Height)
  local h = vitalConfig.Height - vitalConfig.Height * (vital.Current / vital.Max)
  local textPos = topLeft

  drawList.PushClipRect(Vector2.new(topLeft.X, topLeft.Y), bottomRight)
  drawList.PushClipRect(Vector2.new(topLeft.X, topLeft.Y + h), bottomRight)
  if invert then
    bottomRight = topLeft + Vector2.new(0, vitalConfig.Height)
    topLeft = topLeft + Vector2.new(vitalConfig.Width, 0)
  end
  
  drawList.AddImage(backgroundTexture.TexturePtr, topLeft, bottomRight, uv_min, uv_max, vitalConfig.BGTint)
  drawList.PopClipRect()
  drawList.AddImage(borderTexture.TexturePtr, topLeft, bottomRight, uv_min, uv_max, vitalConfig.BorderTint)
  -- vital text
  drawList.PopClipRect()
  local text = tostring(vital.Current) .. " / " .. tostring(vital.Max)
  drawList.AddText(textPos, vitalConfig.FGTint, text)
end

return CircularVitals