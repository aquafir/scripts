local helpers = require("helpers")
local ac = require("acclient")
local vtnav = require("vtnavigation")
local namer = require("friendlynames")
local fs = require("filesystem").GetScript()

---Tries to load a nav based on landblock.
---@param force boolean Forces creation and load
function TryLoadNav(force)
  local location = namer.friendly(ac.Coordinates.Me.LandCell)
  local navName = "__" .. location
  if force then
    game.Actions.InvokeChat("/vt nav load " .. navName)
    return
  end

  --If not forced look for the nav
  local navFiles = vtnav.GetNavFiles(navName)

  if navFiles == nil then
    print("Error finding nav files")
    return
  end

  for index, value in pairs(navFiles) do
    if value:find(navName) then
      game.Actions.InvokeChat("/vt nav load " .. navName)
    end
  end
end

function IsActive()
  if not fs.FileExists("blacklist.txt") then
    print("Creating blacklistlist.txt")
    fs.WriteText("blacklist.txt", "")
  end
  -- if not fs.FileExists("whitelist.txt") then print("Creating whitelist.txt") fs.WriteText("whitelist.txt", "") end

  -- for _, value in ipairs(fs.ReadLines("blacklist.txt")) do table.insert(blacklist, case_insensitive_pattern(value)) end
  -- for _, value in ipairs(fs.ReadLines("whitelist.txt")) do table.insert(whitelist, case_insensitive_pattern(value)) end
  for _, name in ipairs(fs.ReadLines("blacklist.txt")) do
    if game.Character.Weenie.Name:find(case_insensitive_pattern(name)) then
      print("Name blacklisted by " .. name)
      return false
    end
  end
  -- for _, name in ipairs(fs.ReadLines("whitelist.txt")) do
  --   if game.Character.Weenie.Name:find(case_insensitive_pattern(name)) then
  --     print("Name whitelisted by " .. name)
  --     return true
  --   end
  -- end

  -- print(#blacklist .. " blacklisted names")
  --print(#whitelist .. " whitelisted names")
  return true
end

---@param evt EventArgs
function PortalExit(evt)
  TryLoadNav(false)
end

---comment
---@param evt ChatInputEventArgs
function OnCommand(evt)
  if evt.Text == "/autonav" then
    evt.Eat = true
    TryLoadNav(true)
  end
end

function Init()
  --Command always available
  game.World.OnChatInput.Add(ChatCommand)

  if IsActive() then
    game.Character.OnPortalSpaceExited.Add(PortalExit)
    --  else print("AutoNav not active for this character")
  end
end

function Dispose()
  if hud ~= nil then hud.Dispose() end
  game.Character.OnPortalSpaceExited.Remove(PortalExit)
  game.World.OnChatInput.Remove(ChatCommand)
end

-- listen for gamestate changes
game.OnStateChanged.Add(function(evt)
  if evt.NewState == ClientState.In_Game then
    Init()
  elseif evt.NewState == ClientState.Logging_Out then
    Dispose()
  end
end)

-- if we are ingame when the script loads, call init
if game.State == ClientState.In_Game then Init() end
