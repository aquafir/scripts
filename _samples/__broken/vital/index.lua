--[[
  Vital Bar Replacement
]]

local ImGui = require("imgui")
local views = require("utilitybelt.views")
local Settings = require("settings")
local ACClient = require("acclient")
local im = ImGui.ImGui

---@class VitalBar
---@field GetDefaultProfile fun(): SettingsProfile -- return default settings profile for this VitalBar
---@field PreRender fun(profile: SettingsProfile): nil -- PreRender the hud
---@field Render fun(profile: SettingsProfile): nil -- Render the hud
---@field Startup fun(profile: SettingsProfile): nil -- Called when bar is loaded
---@field Shutdown fun(profile: SettingsProfile): nil -- Called when bar is unloaded

ACClient.ToggleUIElement(ACClient.UIElementType.Vitals, false)
game.OnScriptEnd.Add(function (evt)
  ACClient.ToggleUIElement(ACClient.UIElementType.Vitals, true)
end)

local vitalHud = views.Huds.CreateHud("Vital UI###VitalUI")
vitalHud.ShowInBar = false
vitalHud.Visible = true
vitalHud.WindowSettings = IM.ImGuiWindowFlags.NoInputs.AddFlags(
  IM.ImGuiWindowFlags.NoBringToFrontOnFocus,
  IM.ImGuiWindowFlags.NoTitleBar,
  IM.ImGuiWindowFlags.NoBackground,
  IM.ImGuiWindowFlags.NoFocusOnAppearing,
  IM.ImGuiWindowFlags.NoScrollbar
)

vitalHud.OnPreRender.Add(function ()
  Settings.GetCurrentVitalBar().PreRender(Settings.GetCurrentProfile())
end)

vitalHud.OnRender.Add(function()
  Settings.GetCurrentVitalBar().Render(Settings.GetCurrentProfile())
end)