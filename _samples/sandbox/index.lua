
print("Hello")

--[[
local target = game.World.GetNearest("Zo")
for i,wo in ipairs(game.Character.GetInventory(ObjectClass.SpellComponent)) do
  await(wo.Give(target.Id))
end

while true do
  sleep(1000 * 60 * 60) -- sleep one hour
  game.Actions.InvokeChat("/vt opt set LootOnlyRareCorpses false")
  sleep(1000 * 60 * 5) -- sleep 5 minutes
  game.Actions.InvokeChat("/vt opt set LootOnlyRareCorpses true")
end
]]
--[[
  
local ubnet = require("ubnet")

print(game.Character.Weenie.Skills[SkillId.ManaConversion].Current)

--subscribe to a channel
ubnet.UBNet.SubscribeToChannel("sandbox:test_channel", function (channel, message)
  print("Got message on channel", channel, ":", message)
end)

--publish message to channel
ubnet.UBNet.PublishToChannel("sandbox:test_channel", "Hello World")

---An example function that runs on remote clients. This returns the count of the specified itemName
---@param itemName string -- The name of the item to check.
function GetItemCountRemote(itemName)
  return game.Character.Weenie.Name, game.Character.GetInventoryCount(itemName)
end

local res = await(ubnet.UBNet.RemoteExec(GetItemCountRemote, { "Prismatic Taper" })) 

-- res.Results is a list of remote responses.
for i,k in pairs(res.Results) do
  print(i, k.Sender, k.Response)
end

--when this char casts a spell on a target, make all clients with "combat" tag also cast that spell
local filter = ubnet.ClientFilter.new("combat")
game.Messages.Outgoing.Magic_CastTargetedSpell.Add(function (evt)
  await(ubnet.UBNet.RemoteExec(function(spellId, targetId)
    -- this is running on remote clients
    if game.Character.SpellBook.IsKnown(spellId) then
      await(game.Actions.CastSpell(spellId, targetId))
    end
  end, { evt.Data.SpellId, evt.Data.ObjectId }, filter)) 
end)

-- this makes all connected ubnet clients force buff, and only finishes
-- awaiting when all clients have finished buffing
await(ubnet.UBNet.RemoteExec(function(objectId)
  for i,k in ipairs(game.Character.SpellBook.GetSelfBuffs(10, true)) do
    await(game.Actions.CastSpell(k.Id, game.CharacterId))
  end
end))
print("Everyone is done buffing")
]]
--[[

local ubnet = require("ubnet")
local acclient = require("acclient")

local res1 = await(game.Actions.ObjectAppraise(game.World.Selected.Id))
print("res1", res1, res1.Error)

local res2 = game.Actions.ObjectAppraise(game.World.Selected.Id).Await()
print("res2", res2, res2.Error)

local res3 = ObjectAppraiseAction.new(game.World.Selected.Id)
print("res3", res3.Await(), res3.Error)

local item = game.Character.Inventory[1]


---comment
---@return { [number]: { One: number, Two: number, Three: string } }
function test()
  return {
    [1] = {1,2,"test"},
    [2] = {1,2,"test"}
  }
end



for i,k in pairs(test()) do
  
end

```lua
-- add / update a property on the current ubnet client
await(ubnet.SetProperty("combat-character", true))

-- get a list of clients we want to broadcast to
local clients = ubnet.GetClients(function (client)
  -- this function is a filter method. returning true adds the item to the results
  return client.Type == ubnet.ClientType.GameClient and client.Property["combat-character"] == true
end)

-- choose a meeting spot, and a spell / target
local spot = acclient.Movement.MyPhysicsCoordinates
local spellId = SpellId.WhirlingBlade6
local targetId = game.World.Selected.Id

-- this will broadcast a remote function that runs on all specified clients. It completes
-- complete when all clients have run the function and returned a result.
local navToRes = await(ubnet.Broadcast(clients, function (lb, x, y, z, spell, target)
  -- this function runs on the remote client. you cant use upvalues here, but you can
  -- use primitives from the parent script by passing them as extra arguments to the
  -- Broadcast action.

  -- Run to the target location
  await(acclient.Movement.RunStraightTo(acclient.Coordinates.new(lb, x, y, z)))

  -- cast a spell at the specified target (new, alternate await action syntax)
  CastSpellAction.new(spell, target).Await()

  -- the parent script can read values returned from here, but you can only return primitives.
  -- multiple return values are supported.
  return game.Character.GetInventory("Prismatic Taper"), game.Character.GetInventory("Trade Note (250,000)")
end, spot.LandCell, spot.LocalX, spot.LocalY, spot.LocalZ, spellId, targetId))

-- loop through all the client responses from the above broadcast, and check the results
for client,res in pairs(navToRes.RemoteResults) do
  if res.Error ~= ActionError.None then
    print(client.Name, "had an error:", res.Error, res.ErrorDetails)
  else
    print(client.Name, "has", res.Values[1], "Prismatic Tapers, and", res.Values[2], "MMDs")
  end
end
```
]]

--[[
```lua
local x= 123;
local res = await(ubnet.UBNet.ExecRemote(function()
  local y = 123;
  await(game.Actions.ObjectUse(x))
  return y
end))
```
```
Got MultiRemoteExecRequest: FUNCTION <sandbox/index.lua:2>
  Upvalues:
    0: _ENV : Local[1]
    1: x : Local[3]
  Locals:
    y : Local[0]
  Instructions:
    PUSHINT    123
    STORELCL   0 0 0
    POP        1
    UPVALUE    0
    INDEX      1 -4095 0
    UPVALUE    0
    INDEX      2 -4095 0
    INDEXN     3 0 0
    INDEXN     4 0 0
    UPVALUE    1
    CALL       1 0
    CALL       1 0
    POP        1
    LOCAL      0
    RET        1
    RET        0
  Source:
    local y = 123;
    await(game.Actions.ObjectUse(x))
    return y
```
]]