-----------------------LIBS-------------------------
-- local ac = require("acclient")               -- 3d/2d graphics and coordinates
local fs     = require("filesystem").GetScript() -- File system
local IM  = require("imgui")
local ImGui     = IM.ImGui;
local views  = require("utilitybelt.views")
local hud    = nil ---@type Hud|nil
local ltable = require("lua_table")
require('lua_table').patch(table, ltable)
local h = require("helpers")

----------------------CONFIG-----------------------
local TIMEOUT = 15000    --Seconds between transactions
local autoDeposit = true --Automatically deposit pyreals over threshold
local autoDepositThreshold = 500000
local test = false       --Print transaction instead of invoking
local coinMode = false   --Withdraw in increments sub MMD

----------------------STATE------------------------

---@type {[string]: string}
local accounts = {} ---@type {[number]: string }  List of account numbers and their corresponding player name
--Because combos suck, this maps to accounts
local accountCombo = {}
local selectedAccount = 1
local balance = { AshCoin = 0, Luminance = 0, MMD = 0 }
local carried = { AshCoin = 0, Luminance = 0, MMD = 0 }
local transaction = { AshCoin = 0, Luminance = 0, MMD = 0 }


------------------HELPERS--------------------------
---@param name string Account name
---@param number number Account number
function LoadAccounts()
    if not fs.FileExists("accounts.txt") then
        print("Creating accounts.txt")
        fs.WriteText("accounts.txt", "")
    else
        print("Loading accounts...")
    end

    for _, line in ipairs(fs.ReadLines("accounts.txt")) do
        local acct = split(line, ",")
        if #acct == 2 then
            print(acct[1] .. ": " .. acct[2])
            accounts[acct[1]] = acct[2]
        end
    end
    accountCombo = ltable.keys(accounts)
end

function Refresh()
    --Get account balance
    game.Actions.InvokeChat("/bank account")

    --Carried
    if game.Character.Weenie.Int64Values[Int64Id.AvailableLuminance] ~= nil then
        carried.Luminance = game.Character.Weenie.Int64Values[Int64Id.AvailableLuminance]
    end
    carried.MMD = MMDs()
    print(tostring(carried.MMD))
    carried.AshCoin = game.Character.GetInventoryCount("AshCoin")
end

function MMDs()
    --Can't deposit MMDs as pyreals
    return --game.Character.GetInventoryCount(function(wo) return wo.Name == "Trade Note (250,000)" end) +
        math.floor(game.Character.Weenie.IntValues[IntId.CoinValue] / 250000)
end

function ResetTransaction()
    transaction = { AshCoin = 0, Luminance = 0, MMD = 0 }
end

-------------------RENDER EVENTS--------------------
-- Called before our window is registered
function OnPreRender()
    IM.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);
end

---Select account from combo
function RenderAccounts()
    local valueChanged, newValue = ImGui.Combo("Accounts", selectedAccount - 1, accountCombo, #accountCombo)
    if valueChanged then
        selectedAccount = newValue + 1 --Lua why you do this :( stick with a starting index
        -- print("Selected " .. selectedAccount)
    end
end

---Display controls for bank transactions
function RenderTransaction()
    for key, value in pairs(balance) do
        --Slider
        local changed, newAmount = ImGui.SliderInt(tostring(key), transaction[key], carried[key] * -1, value)
        if changed then
            transaction[key] = clamp(newAmount, carried[key] * -1, value)
        end
        --Input/Buttons
        local changed, newAmount = ImGui.InputInt(tostring(key) .. "(" .. carried[key] * -1 .. " to " .. value .. ")",
        transaction[key])
        if changed then transaction[key] = clamp(newAmount, carried[key] * -1, value) end
    end
end

---Buttons for transactions
function RenderButtons()
    local selfSelected = accountCombo[selectedAccount] == game.Character.Weenie.Name
    local label = "Done"
    if not selfSelected then label = "Send" end
    if ImGui.Button(label) then
        -- print(tostring(accountCombo[selectedAccount]))
        -- Self
        if selfSelected then
            for key, value in pairs(transaction) do
                value = tonumber(value)
                -- print(key .. ": " .. value)
                --/bank withdraw thing #amt
                if value > 0 then
                    if key == "MMD" then --MMDs handled to convert as pyreals
                        if test then
                            print("/bank withdraw pyreals " .. value * 250000)
                            --Get it in change
                        elseif coinMode then
                            value = value * 250000
                            for i = 1, value / 250000, 1 do
                                game.Actions.InvokeChat("/bank withdraw pyreals 249999")
                                sleep(TIMEOUT)
                            end
                            game.Actions.InvokeChat("/bank withdraw pyreals " .. value % 249999)
                        else
                            game.Actions.InvokeChat("/bank withdraw pyreals " .. value * 250000)
                        end
                    else
                        if test then
                            print("/bank withdraw " .. key .. " " .. value)
                        else
                            game.Actions.InvokeChat("/bank withdraw " .. key .. " " .. value)
                        end
                    end
                    --/bank deposit thing #amt
                elseif value < 0 then
                    if key == "MMD" then --MMDs handled to convert as pyreals
                        if test then
                            print("/bank deposit pyreals " .. value * 250000 * -1)
                        else
                            game.Actions.InvokeChat("/bank deposit pyreals " .. value * 250000 * -1)
                        end
                    else
                        if test then
                            print("/bank deposit " .. key .. " " .. value * -1)
                        else
                            game.Actions.InvokeChat("/bank deposit " .. key .. " " .. value * -1)
                        end
                    end
                end
            end
            --Other account
        else
            local recipientNum = accounts[accountCombo[selectedAccount]]
            for key, value in pairs(transaction) do
                value = tonumber(value)
                --/bank send # thing #amt
                if value > 0 then
                    if key == "MMD" then --MMDs handled to convert as pyreals
                        if test then
                            print("/bank send " .. recipientNum .. " pyreals " .. value * 250000)
                        else
                            game.Actions.InvokeChat("/bank send " .. recipientNum .. " pyreals " .. value * 250000)
                        end
                    else
                        if test then
                            print("/bank send " .. recipientNum .. " " .. key .. " " .. value)
                        else
                            game.Actions.InvokeChat("/bank send " .. recipientNum .. " " .. key .. " " .. value)
                        end
                    end
                end
            end
        end
    end
    ImGui.SameLine()
    if ImGui.Button("All") then game.Actions.InvokeChat("/bank deposit all") end
    ImGui.SameLine()
    if ImGui.Button("Reset") then
        Refresh()
        ResetTransaction()
    end
    local changed, newAmount = ImGui.InputInt("Threshold", autoDepositThreshold)
    if changed then autoDepositThreshold = newAmount end
    --IM.SameLine()
    if ImGui.Checkbox("AutoDeposit", autoDeposit) then autoDeposit = not autoDeposit end
    ImGui.SameLine()
    if ImGui.Checkbox("Coins", coinMode) then coinMode = not coinMode end
    ImGui.SameLine()
    if ImGui.Checkbox("Test", test) then test = not test end
end

-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
    RenderAccounts()
    RenderTransaction()
    RenderButtons()
end

local OnShow = function()
    Refresh()
end

----------------------EVENTS----------------------------
local slowTick = os.time()
function AutoDeposit()
    local diff = os.difftime(os.time(), slowTick)
    if diff < 10 then return end
    slowTick = os.time()
    if game.Character.Weenie.IntValues[IntId.CoinValue] > autoDepositThreshold then
        game.Actions.InvokeChat("/bank deposit pyreals " .. game.Character.Weenie.IntValues[IntId.CoinValue])
    end
end

local OnChat = function(evt)
    --Only pay attention to messages with a bank prefix
    if (evt.Message:sub(0, 2) == "[B") then
        --Parse the balance
        --[BANK] Account Number: (%d+)

        --Look for accounts
        local match = evt.Message:match("Account Number: (%d+)")
        if accounts[game.Character.Weenie.Name] == nil and match ~= nil then
            --[BANK] Account Balances: 260,020 Pyreals || 0 Luminance || 0 AshCoin
            local acct = game.Character.Weenie.Name .. "," .. tostring(match)
            print("Adding: " .. acct)
            accounts[game.Character.Weenie.Name] = tostring(match)
            fs.AppendText("accounts.txt", "\n" .. game.Character.Weenie.Name .. "," .. tostring(match))
            accountCombo = ltable.keys(accounts)
        end
        --Strip commas cause parsing numbers sucks
        local msg = string.gsub(evt.Message, ",", "")
        match = msg:match("(%d+) Pyreals")
        if match ~= nil then
            balance.MMD = math.floor(tonumber(match / 250000))
            print("MMDs parsed: " .. balance.MMD)
        end
        match = msg:match("(%d+) Luminance ||")
        if match ~= nil then
            balance.Luminance = tonumber(match)
            print("Luminance parsed: " .. balance.Luminance)
        end
        match = msg:match("(%d+) AshCoin")
        if match ~= nil then
            balance.AshCoin = tonumber(match)
            print("AshCoin parsed: " .. balance.AshCoin)
        end
    end --
end

---Shows the HUD on /bank
---@param evt ChatInputEventArgs
function OnCommand(evt)
    if evt.Text == "/bank" then
        evt.Eat = false
        Refresh()
        hud.Visible = true
    end
end

---------------------INIT/DISPOSE------------------------
function Init()
    LoadAccounts()

    hud = views.Huds.CreateHud("Bank")
    -- True if you want it to start visible, false invisible
    -- hud.Visible = false
    Refresh()
    hud.Visible = true
    hud.OnRender.Add(OnHudRender)
    hud.OnShow.Add(OnShow)

    game.World.OnChatText.Add(OnChat)
    game.World.OnChatInput.Add(OnCommand)
    if autoDeposit then game.World.OnTick.Add(AutoDeposit) end

    -- Size to fit
    hud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize
    -- Alternatively use a size range in prerender
    hud.OnPreRender.Add(OnPreRender)
end

function Dispose()
    -- Unsubscribe from events
    game.World.OnChatText.Remove(OnChat)
    game.World.OnTick.Remove(AutoDeposit)
    game.World.OnChatInput.Remove(OnCommand)
    game.World.OnTick.Remove(AutoDeposit)

    -- Destroy hud
    if hud ~= nil then
        hud.OnRender.Remove(OnHudRender)
        hud.OnShow.Remove(OnShow)
        hud.OnPreRender.Remove(OnPreRender)
        hud.Dispose()
    end
end

-------------------------START------------------------------
game.OnStateChanged.Add(function(evt)
    -- Start on login
    if evt.NewState == ClientState.In_Game then
        Init()
        -- Dispose on log out
    elseif evt.NewState == ClientState.Logging_Out then
        Dispose()
    end
end)
-- ...or on script end
game.OnScriptEnd.Once(Dispose)
-- Start up if in game when the script loads
if game.State == ClientState.In_Game then Init() end
