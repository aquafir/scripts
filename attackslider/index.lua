local views = require("utilitybelt.views")
local ImGui = require("imgui")
local im = ImGui.ImGui
local acclient = require("acclient")
local hud = views.Huds.CreateHud("Attack Power")

hud.Visible = true

hud.OnRender.Add(function ()
  local changed, newValue = im.SliderFloat("Attack Power", acclient.Combat.AttackPower, 0, 1)
  if changed then acclient.Combat.AttackPower = newValue end
end)