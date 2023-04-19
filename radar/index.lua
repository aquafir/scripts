-- local ac = require("acclient")
-- local ImGui = require("imgui")
-- local IM = ImGui ~= nil and ImGui.ImGui or {}
-- local views = require("utilitybelt.views")
-- local hud = views.Huds.CreateHud("Radar")


local last = os.time()
local looting = false
function TryLoot()
    local t = game.World.GetLandscape(function(wo) return wo.Name == "Boosted Lottery Ticket" end)
    local closest = nil
    local oldDist = 99999999
    for key, value in pairs(t) do
        local distance = game.Character.Weenie.DistanceTo2D(value)
        if closest == nil or distance < oldDist then 
            closest = value
            oldDist = distance
        end
    end

    if (closest == nil or oldDist > 5) and looting then
        print("Finished looting")
        looting = false
        game.Actions.InvokeChat("/vt opt set EnableNav TRUE")        
    end

    if closest ~= nil and oldDist < 3 and os.difftime(os.time(), last) > 1 then
        if not looting then
            print("Looting")
            looting = true
            game.Actions.InvokeChat("/vt opt set EnableNav FALSE")
        end
        last = os.time()
        closest.Move(game.CharacterId)
        return
    end
end


while true do
    TryLoot()
--    print(os.time())
    sleep(150)
end

-- --Gate commands by time
-- local last = os.time()
-- -- min/max window size
-- local minWindowSize = Vector2.new(200, 400)
-- local maxWindowSize = Vector2.new(999999, 999999)

-- function Render()
--     IM.BeginChild("Radar", IM.GetContentRegionAvail())
--     -- local t = game.World.GetLandscape(function(wo) return wo.Name == "Colored Egg" end)
--     local t = game.World.GetLandscape(function(wo) return wo.Name == "Boosted Lottery Ticket" end)

--     --Got lazy and didn't try sorting
--     for key, value in pairs(t) do
--         local distance = game.Character.Weenie.DistanceTo2D(value)
--         if distance < 240 then
--             local heading = ac.Coordinates.Me.HeadingTo(ac.Movement.GetPhysicsCoordinates(value.Id))
--             local mark = ac.DecalD3D.MarkObjectWith3DText(value.Id, "Egg!", "Helvetica", 11111111)
--             mark.Scale(5)
--             --ac.DecalD3D.MarkObjectWithShape(value.Id, ac.DecalD3DShape.HorizontalArrow, 0x11991111)
--             -- print(tostring(key) .. ": " .. tostring(value))
--             if IM.Button("Select") then
--                 if distance < 3 then
--                     print("Manual loot")
--                     value.Move(game.CharacterId)
--                 else
--                     value.Select()
--                 end
--             end
--             if distance < 1 then
--                 if os.difftime(os.time(), last) > 1 then
--                     last = os.time()
--                     value.Move(game.CharacterId)
--                 end
--             end

--             IM.SameLine(60)
--             if IM.Button("Face - " .. tostring(distance) .. " @ " .. tostring(heading)) then ac.Movement.SetHeading(
--                 heading) end
--         end
--     end

--     IM.EndChild()
-- end

-- -- called before our window is registered. you can set window options here
-- local onPreRender = function()
--     -- set minimum window size
--     IM.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize)
-- end
-- -- called during the hud window render. draw your ui here
-- local onRender = function()
--     if game.State == ClientState.In_Game then
--         Render()
--     end
-- end

-- -- create a new hud, set options, and register for hud events
-- hud.Visible = true
-- hud.showInBar = true
-- hud.OnPreRender.Add(onPreRender)
-- hud.OnRender.Add(onRender)
-- -- subscribe to scriptEnd event so we can tostring(message)
-- -- (since this is a `once` handler, it will automatically unsubscribe itself after being called once)
-- game.OnScriptEnd.Once(function()
--     hud.OnPreRender.Remove(onPreRender)
--     hud.OnRender.Remove(onRender)
--     -- destroy hud
--     --hud.Visible = false
--     hud.Dispose()
-- end)
