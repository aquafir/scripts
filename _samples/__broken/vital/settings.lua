local views = require("utilitybelt.views")
local ImGui = require("imgui")
local fs = require("filesystem")
local im = ImGui ~= nil and ImGui.ImGui or {}

-- Vital Settings
---@class VitalSettings
---@field BGTint integer -- The background tint color for this vital
---@field FGTint integer -- The foreground tint color for this vital
---@field BorderTint integer -- The border tint color for this vital
---@field DamageTint integer -- The lagging damage tint color for this vital
---@field HealTint integer -- The lagging healing tint color for this vital
---@field Width integer -- The width this vital should display at, if applicable
---@field Height integer -- The height this vital should display at, if applicable
---@field OffsetX integer -- The X offset this vital should be drawn at, if applicable
---@field OffsetY integer -- The Y offset this vital should be drawn at, if applicable

-- Settings Profile
---@class SettingsProfile
---@field OffsetX integer - The overall X Offset the hud should draw
---@field OffsetY integer - The overall Y Offset the hud should draw
---@field Vitals { [string]: VitalSettings }

local Settings = {}

-- The last loaded profile for each VitalBar
---@type { [string]: string }
Settings.VitalBarLoadedProfiles = {}

-- The currently loaded vital bar
---@type VitalBar
local currentVitalBar = nil

---@type SettingsProfile
local currentProfile = nil

local profileHasChanges = false
local saveAsValue = ""

-- The name of the currently loaded vital bar
---@type string
Settings.CurrentVitalBarName = nil

---Gets the instance of the currently loaded VitalBar
---@return VitalBar -- The currently loaded vital bar
function Settings.GetCurrentVitalBar()
  return currentVitalBar
end

---Gets the currently loaded profile
---@return SettingsProfile -- The currently loaded profile
function Settings.GetCurrentProfile()
  return currentProfile
end

---Gets a list of all available profiles for the currently loaded VitalBar
---@return string[] -- List of bar profile names
function Settings.GetAvailableBarProfiles()
  local barProfiles = {}
  local profileFiles = fs.GetFiles("profiles/" .. Settings.CurrentVitalBarName .. "/") --[[@as List<string>]]
  for i, fileName in ipairs(profileFiles) do
    if string.match(fileName, "%.json$") then
      local profileName = string.gsub(fileName, "%.json$", "")
      table.insert(barProfiles, profileName)
    end
  end

  if #barProfiles == 0 then
    return { "default" }
  end

  return barProfiles
end

---Gets a list of all available bar type files
---@return string[] -- List of bar names
function Settings.GetAvailableBars()
  local bars = {}
  local files, error = fs.GetFiles("bars")
  if error ~= nil then
    print("Error loading available bars...", error)
  else
    for i, fileName in ipairs(files --[[@as List<string>]]) do
      if string.match(fileName, "%.lua$") then
        local name = string.gsub(fileName, "%.lua$", "")
        table.insert(bars, name)
      end
    end
  end
  return bars
end

---Save settings to disk
function Settings.Save()
  fs.WriteText("settings.json", json.serialize(Settings))
end

---Load a bar profile
---@param name string
function Settings.LoadBarProfile(name)
  local profileFile = "profiles/" .. Settings.CurrentVitalBarName .. "/" .. name .. ".json"
  print("LoaDBarProfile:", name)

  print(Settings.GetCurrentVitalBar().GetDefaultProfile())

  if fs.FileExists(profileFile) then
    currentProfile = json.parse(fs.ReadText(profileFile))
  else
    currentProfile = Settings.GetCurrentVitalBar().GetDefaultProfile()
  end

  -- ensure profile has good values...
  if currentProfile.OffsetX == nil then currentProfile.OffsetX = 0 end
  if currentProfile.OffsetY == nil then currentProfile.OffsetY = 0 end
  if currentProfile.Vitals == nil then currentProfile.Vitals = {} end

  local defaultVitalTemplate = {
    FGTint = 0xffffffff,
    BGTint = 0xcc0000ff,
    BorderTint = 0xcc000088,
    Width = 50,
    Height = 200,
    OffsetX = 100,
    OffsetY = 0,
    DamageTint = 0xcc666666,
    HealTint = 0xcc0000aa
  }

  for k in { "Health", "Stamina", "Mana" } do
    if currentProfile.Vitals[k] == nil then
      currentProfile.Vitals[k] = {}
    end
    for key,value in pairs(defaultVitalTemplate) do
      if currentProfile.Vitals[k][key] == nil then
        currentProfile.Vitals[k][key] = value
      end
    end
  end

  Settings.VitalBarLoadedProfiles[Settings.CurrentVitalBarName] = name
  Settings.Save()

  profileHasChanges = false
  saveAsValue = name
end

---Load a VitalBar
---@param name string -- The name of the vital bar
function Settings.LoadBar(name)
  if currentVitalBar ~= nil and currentVitalBar.Shutdown ~= nil then
    currentVitalBar.Shutdown(currentProfile)
  end

  currentVitalBar = require("bars/" .. name .. ".lua")--[[@as VitalBar]]
  Settings.CurrentVitalBarName = name

  if Settings.VitalBarLoadedProfiles[name] ~= nil then
    Settings.LoadBarProfile(Settings.VitalBarLoadedProfiles[name])
  else
    Settings.LoadBarProfile("default")
  end

  if currentVitalBar ~= nil and currentVitalBar.Startup ~= nil then
    currentVitalBar.Startup(currentProfile)
  end

  Settings.Save()
end

local SettingsInit = function()
  if fs.FileExists("settings.json") then
    local settings = json.parse(fs.ReadText("settings.json"))
    if settings.CurrentVitalBarName ~= nil then Settings.CurrentVitalBarName = settings.CurrentVitalBarName end
    if settings.VitalBarLoadedProfiles ~= nil then Settings.VitalBarLoadedProfiles = settings.VitalBarLoadedProfiles end
  else
    Settings.CurrentVitalBarName = Settings.GetAvailableBars()[1]
    Settings.VitalBarLoadedProfiles = {}
  end

  Settings.LoadBar(Settings.CurrentVitalBarName)
end

SettingsInit()

local indexOf = function(array, value)
  for i, v in ipairs(array) do
      if v == value then
          return i
      end
  end
  return nil
end


-- Settings Hud
---@type Hud|nil
local settingsHud = nil

local CreateSettingsHud = function()
  settingsHud = views.Huds.CreateHud("Vital Hud Settings")
  settingsHud.ShowInBar = false
  settingsHud.Visible = true
  settingsHud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize

  settingsHud.OnHide.Add(function()
    settingsHud.Dispose()
    settingsHud = nil
  end)

  settingsHud.OnPreRender.Add(function ()
    
  end)

  settingsHud.OnRender.Add(function ()
    -- bar style dropdown
    local availableBars = Settings.GetAvailableBars()
    local selectedIndex = indexOf(availableBars, Settings.CurrentVitalBarName) or 1
    local didChangeCurrentStyle, newStyle = im.Combo("Bar Style", selectedIndex - 1, availableBars, #availableBars)
    if didChangeCurrentStyle then
      Settings.LoadBar(availableBars[newStyle + 1])
    end

    -- bar profile dropdown
    local availableProfiles = Settings.GetAvailableBarProfiles()
    local selectedBarProfileIndex = indexOf(availableProfiles, Settings.VitalBarLoadedProfiles[Settings.CurrentVitalBarName]) or 1
    local didChangeBarProfile, newBarProfile = im.Combo("Bar Profile", selectedBarProfileIndex - 1, availableProfiles, #availableProfiles)
    if didChangeBarProfile then
      Settings.LoadBarProfile(availableProfiles[newBarProfile + 1])
    end

    -- Save As
    if (im.Button("Save As")) then
      local success, error = fs.WriteText("profiles/" .. Settings.CurrentVitalBarName .. "/" .. saveAsValue .. ".json", json.serialize(currentProfile))
      if error then
        print("Error saving profile:", error)
      else
        Settings.LoadBarProfile(saveAsValue)
      end
    end
    im.SameLine()
    local saveAsChanged, newSaveAsValue = im.InputText("", saveAsValue, 100)
    if saveAsChanged then
      saveAsValue = newSaveAsValue
    end

    im.Spacing() im.Separator() im.Spacing()
  
    local colorFlags = ImGui.ImGuiColorEditFlags.NoInputs.AddFlags(
      ImGui.ImGuiColorEditFlags.AlphaBar
    )

    im.Text("Global:")
    local didChangeGlobalOffsetX, newGlobalOffsetX = im.DragInt("OffsetX", currentProfile.OffsetX)
    if didChangeGlobalOffsetX then currentProfile.OffsetX = newGlobalOffsetX end

    local didChangeGlobalOffsetY, newGlobalOffsetY = im.DragInt("OffsetY", currentProfile.OffsetY)
    if didChangeGlobalOffsetY then currentProfile.OffsetY = newGlobalOffsetY end
  
    im.Spacing() im.Separator() im.Spacing()

    for k, v in pairs(currentProfile.Vitals) do
      im.PushID(tostring(k))
      im.Text(tostring(k) .. ":")
  
      local didChangeWidth, newWidth = im.DragInt("Width", v.Width)
      if didChangeWidth then v.Width = newWidth end
  
      local didChangeHeight, newHeight = im.DragInt("Height", v.Height)
      if didChangeHeight then v.Height = newHeight end
  
      local didChangeOffsetX, newOffsetX = im.DragInt("OffsetX", v.OffsetX)
      if didChangeOffsetX then v.OffsetX = newOffsetX end
      
      local didChangeOffsetY, newOffsetY = im.DragInt("OffsetY", v.OffsetY)
      if didChangeOffsetY then v.OffsetY = newOffsetY end
  
      local didChangeFGTint, newFGTint = im.ColorEdit4("FG Tint", im.ColToVec4(v.FGTint), colorFlags)
      if didChangeFGTint then
        v.FGTint = im.Vec4ToCol(newFGTint)
      end
      im.SameLine()
      local didChangeBGTintColor, newBGTintColor = im.ColorEdit4("BG Tint", im.ColToVec4(v.BGTint), colorFlags)
      if didChangeBGTintColor then
        v.BGTint = im.Vec4ToCol(newBGTintColor)
      end
      im.SameLine()
      local didChangeBorderTintColor, newBorderTintColor = im.ColorEdit4("Border Tint", im.ColToVec4(v.BorderTint), colorFlags)
      if didChangeBorderTintColor then
        v.BorderTint = im.Vec4ToCol(newBorderTintColor)
      end
  
      local didChangeDamageTint, newDamageTint = im.ColorEdit4("Damage Tint", im.ColToVec4(v.DamageTint), colorFlags)
      if didChangeDamageTint then
        v.DamageTint = im.Vec4ToCol(newDamageTint)
      end
      im.SameLine()
      local didChangeHealTint, newHealTint = im.ColorEdit4("Heal Tint", im.ColToVec4(v.HealTint), colorFlags)
      if didChangeHealTint then
        v.HealTint = im.Vec4ToCol(newHealTint)
      end
      if tostring(k) ~= "Mana" then
        im.Spacing() im.Spacing()
        im.Separator()
        im.Spacing() im.Spacing()
        im.PopID()
      end
    end
  end)
end

views.Huds.OnHudBarContextRender.Add(function()
  if im.MenuItem("Vital Hud Settings") then
    if settingsHud == nil then
      CreateSettingsHud()
    else
      settingsHud.Dispose()
      settingsHud = nil
    end
  end
end)

return Settings