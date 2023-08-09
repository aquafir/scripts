--[[
Rare Exchanger

Used to exchange rares at the casino.
--]]


local views = require("utilitybelt.views")
local ImGui = require("imgui")
local fs = require("filesystem")
local im = ImGui ~= nil and ImGui.ImGui or {}


-----------------------
--- SQL / JSON data ---
-----------------------

--[[
ACE SQL:
select 
    w.`class_Id` as `classId`,
    ws.`value` as `name`,
    wd.`value` as `desc`,
    di.`value` as `icon`,
    dio.`value` as `icon_overlay`
FROM `weenie` w
LEFT JOIN `weenie_properties_string` ws ON w.`class_Id` = ws.`object_Id`
LEFT JOIN `weenie_properties_string` wd ON w.`class_Id` = wd.`object_Id`
LEFT JOIN `weenie_properties_d_i_d` di ON w.`class_Id` = di.`object_Id`
LEFT JOIN `weenie_properties_d_i_d` dio ON w.`class_Id` = dio.`object_Id`
WHERE
        ws.`type` = 1 /* name string key*/
    AND
        wd.`type` = 16 /* desc string key*/
    AND
        di.`type` = 8 /* icon did key*/
    AND
        dio.`type` = 50 /* icon overlay did key*/
    AND
        (ws.`value` LIKE "%'s Crystal" OR ws.`value` LIKE "Pearl of %" OR ws.`value` LIKE "%'s Jewel" or ws.`value` LIKE "%'s Pearl")
ORDER BY ws.`value` LIMIT 200
]]

local raredata = json.parse([[
  [
    {"classId":"30234","name":"Lich's Pearl","desc":"Using this gem will increase your Self by 250 for 15 minutes.","icon":"100686698","icon_overlay":"100686682"},
    {"classId":"30240","name":"Lugian's Pearl","desc":"Using this gem will increase your Strength by 250 for 15 minutes.","icon":"100686698","icon_overlay":"100686688"},
    {"classId":"30206","name":"Magus's Pearl","desc":"Using this gem will increase your Focus by 250 for 15 minutes.","icon":"100686698","icon_overlay":"100686652"},
    {"classId":"30232","name":"Sprinter's Pearl","desc":"Using this gem will increase your Quickness by 250 for 15 minutes.","icon":"100686698","icon_overlay":"100686680"},
    {"classId":"30202","name":"Ursuin's Pearl","desc":"Using this gem will increase your Endurance by 250 for 15 minutes.","icon":"100686698","icon_overlay":"100686648"},
    {"classId":"30196","name":"Wayfarer's Pearl","desc":"Using this gem will increase your Coordination by 250 for 15 minutes.","icon":"100686698","icon_overlay":"100686641"},
    {"classId":"30181","name":"Pearl of Acid Baning","desc":"Using this gem will increase the resistance to Acid Damage for all equipped armor and clothing by 500%% for 15 minutes.","icon":"100686695","icon_overlay":"100686623"},
    {"classId":"30190","name":"Pearl of Blade Baning","desc":"Using this gem will increase the resistance to Blade Damage for all equipped armor and clothing by 500%% for 15 minutes.","icon":"100686695","icon_overlay":"100686634"},
    {"classId":"30191","name":"Pearl of Blood Drinking","desc":"Using this gem will increase your equipped melee or missle weapon's damage by 50 for 15 minutes.","icon":"100686695","icon_overlay":"100686635"},
    {"classId":"30192","name":"Pearl of Bludgeon Baning","desc":"Using this gem will increase the resistance to Bludgeon Damage for all equipped armor and clothing by 500%% for 15 minutes.","icon":"100686695","icon_overlay":"100686636"},
    {"classId":"30201","name":"Pearl of Defending","desc":"Using this gem will confer a 25%% Melee Defense bonus upon your equipped melee weapon, missile weapon, or magic caster for 15 minutes.","icon":"100686695","icon_overlay":"100686646"},
    {"classId":"30204","name":"Pearl of Flame Baning","desc":"Using this gem will increase the resistance to Flame Damage for all equipped armor and clothing by 500%% for 15 minutes.","icon":"100686695","icon_overlay":"100686650"},
    {"classId":"30207","name":"Pearl of Frost Baning","desc":"Using this gem will increase the resistance to Frost Damage for all equipped armor and clothing by 500%% for 15 minutes.","icon":"100686695","icon_overlay":"100686653"},
    {"classId":"30211","name":"Pearl of Heart Seeking","desc":"Using this gem will confer a 25%% attack bonus upon your equipped melee weapon for 15 minutes.","icon":"100686695","icon_overlay":"100686657"},
    {"classId":"30212","name":"Pearl of Hermetic Linking","desc":"Using this gem will confer upon an equipped casting device a 100 percent Mana Conversion bonus for 15 minutes.","icon":"100686695","icon_overlay":"100686658"},
    {"classId":"30213","name":"Pearl of Impenetrability","desc":"Using this gem will increase the Armor Level of all equipped armor and clothing by 1000 for 15 minutes.","icon":"100686695","icon_overlay":"100686659"},
    {"classId":"30219","name":"Pearl of Lightning Baning","desc":"Using this gem will increase the resistance to Lightning Damage for all equipped armor and clothing by 500%% for 15 minutes.","icon":"100686695","icon_overlay":"100686666"},
    {"classId":"30230","name":"Pearl of Pierce Baning","desc":"Using this gem will increase the resistance to Piercing damage for all equipped armor and clothing by 500 percent for 15 minutes.","icon":"100686695","icon_overlay":"100686677"},
    {"classId":"30237","name":"Pearl of Spirit Drinking","desc":"Using this gem will confer a 15 percent elemental damage bonus upon your equipped casting device for 15 minutes.","icon":"100686695","icon_overlay":"100686685"},
    {"classId":"30241","name":"Pearl of Swift Killing","desc":"Using this gem will quicken the attack speed on your equipped melee or missile weapon by 1000 points for 15 minutes.","icon":"100686695","icon_overlay":"100686689"}
    {"classId":"30222","name":"Adherent's Crystal","desc":"Using this gem will increase your Loyalty skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686669"},
    {"classId":"30183","name":"Alchemist's Crystal","desc":"Using this gem will increase your Alchemy skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686627"},
    {"classId":"30231","name":"Archer's Jewel","desc":"Using this gem will increase your natural resistance to Piercing damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686678"},
    {"classId":"30214","name":"Artificer's Crystal","desc":"Using this gem will increase your Item Enchantment skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686660"},
    {"classId":"30246","name":"Artist's Crystal","desc":"Using this gem will increase your Weapon Tinkering skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686694"},
    {"classId":"30220","name":"Astyrrian's Jewel","desc":"Using this gem will increase your natural resistance to Electric damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686667"},
    {"classId":"30242","name":"Ben Ten's Crystal","desc":"Using this gem will increase your Heavy Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692248"},
    {"classId":"45368","name":"Berzerker's Crystal","desc":"Using this gem will increase your Recklessness skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686633"},
    {"classId":"45366","name":"Brawler's Crystal","desc":"Using this gem will increase your Dirty Fighting skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692244"},
    {"classId":"30195","name":"Chef's Crystal","desc":"Using this gem will increase your Cooking skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686639"},
    {"classId":"30226","name":"Converter's Crystal","desc":"Using this gem will increase your Mana Conversion skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686673"},
    {"classId":"43407","name":"Corruptor's Crystal","desc":"Using this gem will increase your Void Magic skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100691567"},
    {"classId":"30200","name":"Deceiver's Crystal","desc":"Using this gem will increase your Deception skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686645"},
    {"classId":"30229","name":"Dodger's Crystal","desc":"Using this gem will increase your Missle Defense skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686676"},
    {"classId":"30235","name":"Duelist's Jewel","desc":"Using this gem will increase your natural resistance to Slashing damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686683"},
    {"classId":"30194","name":"Elysa's Crystal","desc":"Using this gem will increase your Missile Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686638"},
    {"classId":"30198","name":"Elysa's Crystal","desc":"Using this gem will increase your Missile Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686638"},
    {"classId":"30243","name":"Elysa's Crystal","desc":"Using this gem will increase your Missile Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686638"},
    {"classId":"30197","name":"Enchanter's Crystal","desc":"Using this gem will increase your Creature Enchantment skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686642"},
    {"classId":"30228","name":"Evader's Crystal","desc":"Using this gem will increase your Melee Defense skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686675"},
    {"classId":"30185","name":"Executor's Jewel","desc":"Using this gem will increase your natural armor by 1000 for 15 minutes.","icon":"100686696","icon_overlay":"100686629"},
    {"classId":"30205","name":"Fletcher's Crystal","desc":"Using this gem will increase your Fletching skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686651"},
    {"classId":"30208","name":"Gelid's Jewel","desc":"Using this gem will increase your natural resistance to Cold damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686654"},
    {"classId":"30245","name":"Hieromancer's Crystal","desc":"Using this gem will increase your War Magic skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686693"},
    {"classId":"30187","name":"Hunter's Crystal","desc":"Using this gem will increase your Assess Creature skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686631"},
    {"classId":"30225","name":"Imbuer's Crystal","desc":"Using this gem will increase your Magic Item Tinkering skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686672"},
    {"classId":"30203","name":"Inferno's Jewel","desc":"Using this gem will increase your natural resistance to Fire damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686649"},
    {"classId":"45369","name":"Knight's Crystal","desc":"Using this gem will increase your Shield skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692246"},
    {"classId":"30218","name":"Life Giver's Crystal","desc":"Using this gem will increase your Life Magic skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686664"},
    {"classId":"30227","name":"Mage's Jewel","desc":"Using this gem will increase your Mana Regeneration by 1000%% for 15 minutes.","icon":"100686696","icon_overlay":"100686674"},
    {"classId":"30239","name":"Melee's Jewel","desc":"Using this gem will increase your Stamina Regeneration by 1000%% for 15 minutes.","icon":"100686696","icon_overlay":"100686687"},
    {"classId":"30217","name":"Monarch's Crystal","desc":"Using this gem will increase your Leadership skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686663"},
    {"classId":"30188","name":"Observer's Crystal","desc":"Using this gem will increase your Assess Person skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686632"},
    {"classId":"30182","name":"Olthoi's Jewel","desc":"Using this gem will increase your natural resistance to Acid damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686625"},
    {"classId":"30199","name":"Oswald's Crystal","desc":"Using this gem will increase your Finesse Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692243"},
    {"classId":"30209","name":"Physician's Crystal","desc":"Using this gem will increase your Healing skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686655"},
    {"classId":"30224","name":"Resister's Crystal","desc":"Using this gem will increase your Magic Defense skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686671"},
    {"classId":"45360","name":"Rogue's Crystal","desc":"Using this gem will increase your Sneak Attack skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692247"},
    {"classId":"30184","name":"Scholar's Crystal","desc":"Using this gem will increase your Arcane Lore skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686628"},
    {"classId":"30186","name":"Smithy's Crystal","desc":"Using this gem will increase your Armor Tinkering skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686630"},
    {"classId":"41257","name":"T'ing's Crystal","desc":"Using this gem will increase your Two Handed Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100690691"},
    {"classId":"30221","name":"Thief's Crystal","desc":"Using this gem will increase your Lockpick skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686668"},
    {"classId":"30189","name":"Thorsten's Crystal","desc":"Using this gem will increase your Light Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692242"},
    {"classId":"30223","name":"Thorsten's Crystal","desc":"Using this gem will increase your Light Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692242"},
    {"classId":"30236","name":"Thorsten's Crystal","desc":"Using this gem will increase your Light Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692242"},
    {"classId":"30238","name":"Thorsten's Crystal","desc":"Using this gem will increase your Light Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692242"},
    {"classId":"30244","name":"Thorsten's Crystal","desc":"Using this gem will increase your Light Weapon skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692242"},
    {"classId":"30215","name":"Tinker's Crystal","desc":"Using this gem will increase your Item Tinkering skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686661"},
    {"classId":"30193","name":"Tusker's Jewel","desc":"Using this gem will increase your natural resistance to Bludgeoning damage by 99.9%% for 15 minutes.","icon":"100686696","icon_overlay":"100686637"},
    {"classId":"30216","name":"Vaulter's Crystal","desc":"Using this gem will increase your Jump skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686662"},
    {"classId":"45367","name":"Warrior's Crystal","desc":"Using this gem will increase your Dual Wield skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100692245"},
    {"classId":"30210","name":"Warrior's Jewel","desc":"Using this gem will increase your Health Regeneration by 1000%% for 15 minutes.","icon":"100686696","icon_overlay":"100686656"},
    {"classId":"30233","name":"Zefir's Crystal","desc":"Using this gem will increase your Run skill by 250 for 15 minutes.","icon":"100686697","icon_overlay":"100686681"},
    {"classId":"52033","name":"Exquisite Casino Key","desc":"A large golden key that opens the Exquisite Casino Chest.","icon":"8223"}
  ]
]])

-----------------------
--- Type definitions --
-----------------------

---represents a rare that can be exchanged with the rare exchanger
---@class Rare
---@field Name string -- The name of the rare
---@field Description string -- The item description
---@field Icon integer -- The item icon
---@field IconOverlay integer -- The item icon overlay
---@field ClassIds integer[] -- valid class ids for this item
---@field IconTexture ManagedTexture|nil
---@field IconOverlayTexture ManagedTexture|nil

---Collection of exchange rare data. Key is the item name
---@class Rares: { [string]: Rare }
local Rares = {}

---Rare specific settings
---@class RareSetting
---@field Enabled boolean -- If this item is enabled for exchanging
---@field KeepAmount integer -- The amount to keep. any extras will be exchanged. Use -1 to keep them all

---@class SettingsProfile: { [string]: RareSetting }

--- Settings
---@class Settings2
---@field LastProfile string -- the last loaded profile
local Settings = { }

-----------------------
--- Rare Data ---------
-----------------------
-- populate rare datas from json
for i,v in ipairs(raredata) do
  if Rares[v.name] == nil then
    local icon_overlay = tonumber(v.icon_overlay)
    local icon = tonumber(v.icon)
    Rares[v.name] = {
      Name = v.name,
      Description = v.desc,
      Icon = v.icon,
      IconOverlay = v.icon_overlay,
      ClassIds = {},
      IconTexture = icon ~= nil and views.Huds.GetIconTexture(icon) or nil,
      IconOverlayTexture = icon_overlay ~= nil and views.Huds.GetIconTexture(icon_overlay) or nil
    }
  end
  table.insert(Rares[v.name].ClassIds, v.classId)
end

-----------------------
--- State -------------
-----------------------
local isRunning = false
local filterText = ""
local profileHasChanges = false
---@type SettingsProfile
local loadedProfile = nil

-----------------------
--- Settings / Profiles
-----------------------

--- Get a default profile
---@returns SettingsProfile
function GetDefaultProfile()
  local defaultProfile = {
    ["Artist's Crystal"] = { Enabled = true, KeepAmount = -1 },
    ["Astyrrian's Jewel"] = { Enabled = true, KeepAmount = 20 }
  }

  return defaultProfile
end

  -- populate blank defaults to the loaded profile
function EnsureLoadedProfileDefaults()
  for i,v in pairs(Rares) do
    if loadedProfile[v.Name] == nil then
      loadedProfile[v.Name] = { Enabled = false, KeepAmount = 0 }
    end
  end
end

-- Save settings
function SaveSettings()
  if Settings == nil then
    Settings = {}
  end
  fs.WriteText("settings.json", json.serialize(Settings))
end

-- make sure profiles dir exists
if not fs.DirectoryExists("profiles") then
  fs.CreateDirectory("profiles")
end

-- load settings file if it exists
if (fs.FileExists("settings.json")) then
  Settings = json.parse(fs.ReadText("settings.json"))
  if Settings == nil then Settings = { LastProfile = "" } end
end

local profileFiles = fs.GetFiles("profiles")

-- attempt to load profile
local foundProfile = false
if Settings.LastProfile ~= "" and Settings.LastProfile ~= nil then
  for i,v in ipairs(profileFiles) do
    if Settings.LastProfile == "profiles/" .. v .. ".json" then
      foundProfile = true
    end
  end
end

if not foundProfile and #profileFiles > 0 then
  Settings.LastProfile = "profiles/" .. profileFiles[1]
  SaveSettings()
elseif not foundProfile then
  Settings.LastProfile = "profiles/default.json"
  local res, error = fs.WriteText(Settings.LastProfile, json.serialize(GetDefaultProfile()))
  if not res then print("Error writing default profile:", error) end
  SaveSettings()
end

local profileToLoad = Settings.LastProfile .. (fs.FileExists(Settings.LastProfile .. ".swp") and ".swp" or "")
local profileJson, error = fs.ReadText(profileToLoad)
if not profileJson then print("Error reading profile:", profileToLoad, error) end

---@type SettingsProfile
loadedProfile = json.parse(profileJson)

EnsureLoadedProfileDefaults()

if string.match(profileToLoad, ".swp") then
  profileHasChanges = true
  fs.DeleteFile(profileToLoad)
end

game.OnScriptEnd.Once(function (evt)
  if profileHasChanges then
    fs.WriteText(Settings.LastProfile .. ".swp", json.serialize(loadedProfile))
  end
end)


-----------------------
--- Main Logic --------
-----------------------

---@type WorldObject
local rareExchangerNpc = nil
---@type { [string]: integer }
local rareCounts = {}
local spentMMDs = 0
local startTime = 0
local stopTime = 0
local stopReason = ""

-- items the exchanger doesn't like
---@type { [integer]: boolean }
local blacklist = {}

local handleNewInventoryItem = function(evt)
  --[[@type ObjectCreatedEventArgs]]
  local x = evt;
  local wo = game.World.Get(x.ObjectId)
  local container = wo.Container or {}

  local opts = ActionOptions.new()
  opts.MaxRetryCount = 1

  if container.Id == game.Character.Id or container.ContainerId == game.Character.Id and wo.Value(IntId.MaxStackSize) > 0 then
    for k,item in pairs(game.Character.Inventory) do
      if item.Id ~= wo.Id and item.ClassId == wo.ClassId and item.Value(IntId.StackSize) < item.Value(IntId.MaxStackSize) then
        wo.Move(item.ContainerId, 0, true, opts)
        return
      end
    end
  end
end

--- Start running
function Start()
  stopReason = ""
  spentMMDs = 0
  startTime = os.clock()
  
  local me = game.Character.Weenie
  for k,npc in pairs(game.World.GetLandscape(ObjectClass.Npc)) do
    if npc.Name == "Rare Exchanger" and (rareExchangerNpc == nil or me.DistanceTo3D(npc) < me.DistanceTo3D(rareExchangerNpc)) then
      rareExchangerNpc = npc
    end
  end

  if rareExchangerNpc == nil then
    print("Error: Unable to find Rare Exchanger NPC!")
    return
  end

  isRunning = true
  print("Using Rare Exchanger:", rareExchangerNpc)

  game.World.OnObjectCreated.Add(handleNewInventoryItem)
  DoNextExchange()
end

--- Stop running
---@param reason string -- the reason for stopping
function Stop(reason)
  game.World.OnObjectCreated.Remove(handleNewInventoryItem)
  stopReason = reason
  isRunning = false
  stopTime = os.clock()
end

---Get's the next rare in your inventory that should be exchanged
---@return WorldObject|nil -- The rare, or nil if none found
function GetNextRare()
  for k,v in pairs(loadedProfile) do
    if v.Enabled and v.KeepAmount >= 0 and rareCounts[k] > v.KeepAmount and k ~= "Exquisite Casino Key" then
      for i,wo in pairs(game.Character.Inventory) do
        if blacklist[wo.Id] ~= true and wo.Name == k then
          return wo
        end
      end
    end
  end

  return nil
end

---Check if we have all the rares we would want to exchange for
---@return boolean true if there are no more rares we want
function HasAllWantedRares()
  for k,v in pairs(loadedProfile) do
    if v.Enabled and (v.KeepAmount < 0 and rareCounts[k] < v.KeepAmount) then
      return true
    end
  end
  return false
end

---Get's an MMD world object with stack size of at least two
---@return WorldObject|nil -- The rare, or nil if none found
function GetMMD()
  for i,wo in pairs(game.Character.Inventory) do
    if wo.Name == "Trade Note (250,000)" and wo.Value(IntId.StackSize, 0) >= 2 then
      return wo
    end
  end
end

function DoNextExchange()
  --print("DoNextExchange")
  if not isRunning then return end

  local mmd = GetMMD()

  if mmd == nil then
    Stop("Ran out of mmds!")
    return
  end

  local nextRare = GetNextRare()

  if nextRare == nil then
    Stop("Ran out of exchangeable rares!")
    return
  end

  if HasAllWantedRares() then
    Stop("Fulfilled all wanted rare counts")
    return
  end
  mmd.Give(rareExchangerNpc.Id, nil, function(res)
    game.World.OnChatText.Until(function(evt)
      if evt.SenderName == "Rare Exchanger" then
        nextRare.Give(rareExchangerNpc.Id, nil, function(res)
          -- this actually means the exchanger wont accept this item
          if res.Error == ActionError.NPCDoesntKnowWhatToDoWithThat then
            print("Blacklisting item:", nextRare)
            blacklist[nextRare.Id] = true
            DoNextExchange()
            return
          end
          game.World.OnChatText.Until(function(evt)
            if string.match(evt.Message, "Rare Exchanger gives you") then
              spentMMDs = spentMMDs + 2
              DoNextExchange()
              return true
            end
          end)
        end)
        return true
      end
    end)
  end)
end

function UpdateRareCounts()
  rareCounts = {}
  for k,wo in pairs(game.Character.Inventory) do
    if Rares[wo.Name] ~= nil then
      rareCounts[wo.Name] = (rareCounts[wo.Name] or 0) + wo.Value(IntId.StackSize, 0)
    end
  end

  for k,v in pairs(loadedProfile) do
    if rareCounts[k] == nil then
      rareCounts[k] = 0
    end
  end
end

-----------------------
--- UI ----------------
-----------------------

-- we only create ui if imgui / views are available
if ImGui ~= nil and views ~= nil then
  local saveAsInputValue = ""
  --- create hud
  local hud = views.Huds.CreateHud("RareExchanger", 100686697)
  hud.Visible = true
  hud.WindowSettings = IM.ImGuiWindowFlags.MenuBar

  --- show a tooltip if the previous ui item is IsItemHovered
  ---@param content string -- Tooltip text
  function Tooltip(content)
    if im.IsItemHovered() then
      im.SetTooltip(content)
    end
  end

  hud.OnPreRender.Add(function()
    im.SetNextWindowSizeConstraints(Vector2.new(450, 200), Vector2.new(9999, 9999));
    hud.Title = "RareExchanger - " .. Settings.LastProfile
    if profileHasChanges then
      hud.WindowSettings = IM.ImGuiWindowFlags.MenuBar.AddFlags(IM.ImGuiWindowFlags.UnsavedDocument)
    else
      hud.WindowSettings = IM.ImGuiWindowFlags.MenuBar
    end
  end)

  hud.OnRender.Add(function()
    UpdateRareCounts()
    if im.BeginMenuBar() then
      if im.BeginMenu("File") then
        if im.BeginMenu("New..") then
          local inputChanged, newValue = im.InputText("Profile Name", saveAsInputValue, 50)
          if inputChanged then
            saveAsInputValue = newValue
          end
          local newFile = "profiles/" .. saveAsInputValue .. ".json"
          if im.Button("Create " .. newFile) then
            local isValidPath, fileNameError = fs.IsValidFilePath(newFile)
            if saveAsInputValue == "" then
              isValidPath = false
              fileNameError = "Profile Name is required."
            end
            if isValidPath then
              if fs.FileExists(newFile) then
                print("File already exists!", newFile)
              else
                Settings.LastProfile = newFile
                loadedProfile = GetDefaultProfile()
                EnsureLoadedProfileDefaults()
                profileHasChanges = true
                saveAsInputValue = ""
                print("New file:", Settings.LastProfile)
              end
            else
              print("Error:", saveAsInputValue, fileNameError)
            end
          end
          im.EndMenu()
        end
        if im.BeginMenu("Open") then
          for i, profileFile in pairs(fs.GetFiles("profiles")) do
            if im.MenuItem(string.gsub(profileFile, ".json", ""), true) then
              Settings.LastProfile = "profiles/" .. profileFile
              SaveSettings()
              loadedProfile = json.parse(fs.ReadText(Settings.LastProfile))
              EnsureLoadedProfileDefaults()
              profileHasChanges = false
            end
          end
          im.EndMenu()
        end
        if im.MenuItem("Save") then
          fs.WriteText(Settings.LastProfile, json.serialize(loadedProfile))
          profileHasChanges = false
          print("Saved", Settings.LastProfile)
        end
        if im.BeginMenu("Save as..") then
          local inputChanged, newValue = im.InputText("Profile Name", saveAsInputValue, 50)
          if inputChanged then
            saveAsInputValue = newValue
          end
          local newFile = "profiles/" .. saveAsInputValue .. ".json"
          if im.Button("Save as " .. newFile) then
            local isValidPath, fileNameError = fs.IsValidFilePath(newFile)
            if saveAsInputValue == "" then
              isValidPath = false
              fileNameError = "Profile Name is required."
            end
            if isValidPath then
              Settings.LastProfile = newFile
              fs.WriteText(Settings.LastProfile, json.serialize(loadedProfile))
              profileHasChanges = false
              saveAsInputValue = ""
              print("Saved as:", Settings.LastProfile)
            else
              print("Error saving as", newFile, fileNameError)
            end
          end
          im.EndMenu()
        end
        im.EndMenu()
      end
      im.EndMenuBar()
    end

    if not isRunning and im.Button("Start") then
      Start()
    elseif isRunning and im.Button("Stop") then
      Stop("Stopped by user")
    end

    im.SameLine(0, 10)
    -- todo: stats
    if isRunning then
      im.Text("Running for " .. string.format("%.2f", os.clock() - startTime) .. "s.");
    else
      im.Text("Ran for " .. string.format("%.2f", stopTime - startTime) .. "s.");
    end
    im.SameLine()
    im.Text("Spent " .. tostring(spentMMDs) .. " MMDs.");

    if not isRunning and #stopReason > 0 then
      im.SameLine()
      im.TextWrapped("Stopped Because: " .. stopReason)
    end

    im.Separator()
    
    local filterTextChanged, newFilterText = im.InputText("Filter", filterText, 500)
    if filterTextChanged then
      filterText = newFilterText
    end

    im.BeginChild("ProfileSettings", im.GetContentRegionAvail())
    local tableFlags = ImGui.ImGuiTableFlags.Borders.AddFlags(ImGui.ImGuiTableFlags.Resizable)
    if im.BeginTable("ProfileSettings", 4, tableFlags) then
      im.TableSetupColumn("Enabled", ImGui.ImGuiTableColumnFlags.WidthFixed, 50);
      im.TableSetupColumn("Name");
      im.TableSetupColumn("Amount", ImGui.ImGuiTableColumnFlags.WidthFixed, 50);
      im.TableSetupColumn("Keep #", ImGui.ImGuiTableColumnFlags.WidthFixed, 150);
      im.TableHeadersRow();

      for k,v in pairs(Rares) do
        im.PushID(k);

        local lowerFilter = string.lower(filterText)

        if filterText == "" or string.match(string.lower(v.Name), lowerFilter) or string.match(string.lower(v.Description), lowerFilter) then
          im.TableNextColumn();
          local enabledChanged, newEnabled = im.Checkbox("###Enabled", loadedProfile[k].Enabled)
          if enabledChanged then
            loadedProfile[k].Enabled = newEnabled
            profileHasChanges = true
          end
          Tooltip("Setting Enabled to false will prevent exchanging this rare.")

          im.TableNextColumn();
          local pos = im.GetCursorPos()
          im.Image(v.IconTexture.TexturePtr, Vector2.new(22, 22))
          if v.IconOverlay ~= nil then
            im.SetCursorPos(pos)
            im.Image(v.IconOverlayTexture.TexturePtr, Vector2.new(22, 22))
            Tooltip(v.Description)
          end
          im.SameLine()
          im.AlignTextToFramePadding()
          im.Text(v.Name)
          Tooltip(v.Description)

          im.TableNextColumn();
          im.Text(tostring(rareCounts[v.Name] or 0))

          im.TableNextColumn();
          local keepAmountChanged, newKeepAmount = im.InputInt("###KeepAmount", loadedProfile[k].KeepAmount, 1, 50)
          if keepAmountChanged then
            loadedProfile[k].KeepAmount = newKeepAmount
            profileHasChanges = true
          end
          Tooltip("Setting this to a negative number will keep ALL of this item.")

          im.PopID();
          
        end
      end

      im.EndTable()
    end
    im.EndChild()
  end)
end