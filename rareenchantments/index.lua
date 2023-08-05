
local views = require("utilitybelt.views")
local _ImGui = require("imgui")
local ImGui = _ImGui.ImGui

local hud = views.Huds.CreateHud("Rare Timers", 100676543)

hud.WindowSettings = _ImGui.ImGuiWindowFlags.AlwaysAutoResize
  + _ImGui.ImGuiWindowFlags.NoDecoration;

---@type { [number]: Enchantment }
local _rareEnchantments = {}

---get a list of active rare enchantments
---@return { [number]: Enchantment }
function GetRareEnchantments()
  print("Updating rare enchantments...")
  local rareEnchantments = {}

  for enchantment in game.Character.ActiveEnchantments() do
    local spell = game.Character.SpellBook.Get(enchantment.SpellId)
    if spell ~= nil and spell.Name:find("Prodigal", 1, true) == 1 then
      print("Found", spell.Name)
      table.insert(rareEnchantments, enchantment) 
    end 
  end

  if #rareEnchantments == 0 then
    hud.Visible = false
  else
    hud.Visible = true
  end

  return rareEnchantments
end

---format double digit time number
---@param t number
---@return string
function FormatTime(t)
  local s = tostring(math.floor(t))
  if #s < 2 then s = "0" .. s end
  return s
end

if  game.State == ClientState.In_Game then
  _rareEnchantments = GetRareEnchantments()
  game.Character.OnEnchantmentsChanged.Add(function (evt)
    _rareEnchantments = GetRareEnchantments()
  end)
end

game.OnStateChanged.Add(function (evt)
  if evt.NewState == ClientState.In_Game then
    _rareEnchantments = GetRareEnchantments()
    game.Character.OnEnchantmentsChanged.Add(function (evt)
      _rareEnchantments = GetRareEnchantments()
    end)
  end
end)
 
hud.OnPreRender.Add(function ()
  ImGui.PushStyleVar(_ImGui.ImGuiStyleVar.Alpha, 0.7)
end)

hud.OnRender.Add(function()
  if game.State == ClientState.In_Game then
    if #_rareEnchantments > 0 then
      ImGui.BeginTable("Rares", 2)
      for i, enchantment in ipairs(_rareEnchantments) do
        local spell = game.Character.SpellBook.Get(enchantment.SpellId)
        ImGui.TableNextColumn()
        ImGui.Text(spell.Name)
        ImGui.TableNextColumn()

        local endTime = enchantment.ClientReceivedAt + TimeSpan.FromSeconds(enchantment.Duration - enchantment.StartTime)
        local ts = (endTime - DateTime.UtcNow).TotalSeconds
        local x = FormatTime(ts / 60) .. ":" .. FormatTime(ts % 60)
        ImGui.Text(x)
      end
      ImGui.EndTable()
    else
      ImGui.Text("No Rares in use...")
    end
  else
    ImGui.Text("Not logged in...")
  end
end)
