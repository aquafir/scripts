function GetMaxEncumberance()
  --http://acpedia.org/wiki/Burden
  local augs = 1 / 3 -- factoring in 3x for to show overburdened
  return game.Character.Weenie.Attributes[AttributeId.Strength].Current * 450 * augs
end

function GetEncumberance()
  --return game.Character.Weenie.Burden
  return game.Character.Weenie.IntValues[IntId.EncumbranceVal] / GetMaxEncumberance()
end

function GetPyreals()
  return game.Character.Weenie.IntValues[IntId.CoinValue]
end

function GetBuyableMMDs()
  if (game.World.Vendor.IsOpen) then
    -- print("Buyrate = " .. game.World.Vendor.SellPriceModifier)
    return math.floor(GetPyreals() / 250000 / game.World.Vendor.SellPriceModifier)
  end
  --Default to 1.15?
  return math.floor(GetPyreals() / 250000 / 1.15)
end

function BuyMMDs(mmdID)
  if (mmd == nil) then mmdID = GetMMDsObjectID() end

  if (mmdID ~= nil) then
    local count = GetBuyableMMDs()
    print(game.Character.Weenie.Name .. " can buy " .. count)
    await(game.Actions.VendorAddToBuyList(mmdID, count))
    await(game.Actions.VendorBuyAll())
    --print("Didn't buy?", res.Error, res.ErrorDetails)
  end
end

function GetMMDsObjectID()
  for i, j in ipairs(game.World.Vendor.Items) do
    -- print("Item: " .. j.WeenieDesc.Name .. " #" .. j.Amount .. " ID=" .. j.ObjectID)
    if (j.WeenieDesc.WeenieClassId == 20630) then
      -- print("MMD ID is " .. j.ObjectID)
      return j.ObjectID
    end
  end
  -- print("No MMDs at Vendor")
  return nil
end

---@param wo WorldObject
function Sellable(wo)
  if (wo.ObjectClass == ObjectClass.TradeNote) then return 0, false end
  if (wo.ObjectClass == ObjectClass.Money) then return false end
  if (wo.BoolValues[BoolId.IsSellable] == false) then return false end
  return true
end

function SellIndividual()
  local inv = game.Character.GetInventory(function(wo) return Sellable(wo) end)
  for i, j in pairs(inv) do
    print("Test " .. j.Name)
    if (Sellable(j)) then
      print("Sell " .. j.Name)
      game.Actions.VendorAddToSellList(j.Id)
    end
  end
end

function SellUninscribed()
  -- print("0 - Main Pack")
  await(game.Actions.VendorAddToSellList(game.CharacterId))

  for i, j in ipairs(game.Character.Containers) do
    --print(i .. " - " .. j.Name)
    if (j.StringValues[StringId.Inscription] == nil and j.Burden > 100) then
      print("Selling " .. i)
      game.Actions.VendorAddToSellList(j.Id)
    end
  end
end

---@param start number
---@param stop number
function SellBags(start, stop)
  print("0 - Main Pack")
  await(game.Actions.VendorAddToSellList(game.CharacterId))

  for start, stop in pairs(game.Character.Inventory) do
    print("Test " .. j.Name)
    if (Sellable(j)) then
      print("Sell " .. j.Name)
      game.Actions.VendorAddToSellList(j.Id)
    end
  end
end

function SellBag()
end

function SellAll()
  --SellIndividual()
  SellUninscribed()
  --SellBags(1, 8)
end

function SellRoutine()
  --Get ID to buy trade notes
  local mmdID = GetMMDsObjectID()

  --Handle selling packs.  Faster than per-item?
  print("Move MMDs to last pack")
  MoveMMDs()

  SellAll()
  SellAll()
  --await(game.Actions.VendorSellAll())

  -- -- sleep(500)
  if (mmd ~= nil) then
    BuyMMDs(mmdID)

    MoveMMDs()    
  else print("Missing MMD ID?") 
  end
end

function MoveMMDs()
  local notes = game.Character.GetInventory(ObjectClass.TradeNote)
  -- local lastPack = game.Character.Containers[#game.Character.Containers]
  -- print("Last pack: " .. lastPack .. " -- " .. lastPack.StringValues[StringId.Inscription])
  local lastPack = game.Character.Containers[game.Character.Weenie.IntValues[IntId.ContainersCapacity]]
  -- print("Last pack: " .. lastPack.Id .. " -- " .. lastPack.StringValues[StringId.Inscription])

  for i, j in ipairs(notes) do
    await(j.Move(lastPack.Id))
  end

  local salvage = game.Character.GetInventory(ObjectClass.Salvage)
  for i, j in ipairs(salvage) do
    await(j.Move(lastPack.Id))
  end
end