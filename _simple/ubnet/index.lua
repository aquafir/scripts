local ubnet = require("ubnet")

---Connected clients
    if ubnet.UBNet.IsConnected then print("Connected to UBNet")
    else print ("Not connected to UBNet") end

    local clients = ubnet.UBNet.GetClients()
    --for key, value in ipairs(ubnet.UBNet.GetClients()) do
    for key, value in pairs(clients) do
        print(key, value.Id, value.Name)
        print("Tags: ")
        for k, v in pairs(value.Tags) do
            print("   " .. v)
        end
    end

---Pub/Sub (broken?)
    -- --subscribe to a channel, with handler method
    -- ubnet.UBNet.SubscribeToChannel("sandbox:test_channel", function (channel, message)
    -- print("Got message on channel", channel, ":", message)
    -- end)

    -- --publish message to channel
    -- ubnet.UBNet.PublishToChannel("sandbox:test_channel", "Hello World")


---Count Items    
    ---An example function that runs on remote clients. This returns the remote character name, and the count of the specified itemName
    ---@param itemName string -- The name of the item to check.
    function GetItemCountRemote(itemName)
    -- this function runs on the remote client. No upvalue usage allowed here.
    -- you can use await here, as well as return multiple values
    -- returned values must be primitives / tables containing only primitives (anything that can be serialized properly with json.serialize() specifically)
    return game.Character.Weenie.Name, game.Character.GetInventoryCount(itemName)
    end

    local res = await(ubnet.UBNet.RemoteExec(GetItemCountRemote, { "Prismatic Taper" })) 

    -- res.Results is a list of remote responses.
    for i,k in pairs(res.Results) do
    -- k.Sender is the remote UBNet client, k.Response is the value
    -- returned from GetItemCountRemote
    print(i, k.Sender, k.Response)
    end

---ClientFilter (broken)
    --when this char casts a spell on a target, make all clients with "combat" tag also cast that spell
    -- local filter = ubnet.ClientFilter.new("combat")
    -- game.Messages.Outgoing.Magic_CastTargetedSpell.Add(function (evt)
    -- await(ubnet.UBNet.RemoteExec(function(spellId, targetId)
    --     -- this is running on remote clients
    --     if game.Character.SpellBook.IsKnown(spellId) then
    --     await(game.Actions.CastSpell(spellId, targetId))
    --     end
    -- end, { evt.Data.SpellId, evt.Data.ObjectId }, nil)) 
    -- end)