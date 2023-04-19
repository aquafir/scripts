local views = require("utilitybelt.views")
local ImGui = require("imgui")

local hud = views.Huds.CreateHud("Testing Icon", "icon.png")
local icon = views.Huds.CreateTexture("icon.png")
local acIcon = nil
local lastSelected = 0;

hud.Visible = true

hud.OnRender.Add(function ()
  if game.World ~= nil and game.World.Selected ~= nil and game.World.Selected.Id ~= lastSelected then
    if acIcon ~= nil then
      acIcon.Dispose()
      acIcon = nil
    end
    acIcon = views.Huds.GetIconTexture(game.World.Selected.Value(DataId.Icon))
    lastSelected = game.World.Selected.Id
  end

  if acIcon ~= nil then
    ImGui.ImGui.Image(acIcon.TexturePtr, Vector2.new(32, 32))
  end

  ImGui.ImGui.Image(icon.TexturePtr, Vector2.new(200, 200))
end)