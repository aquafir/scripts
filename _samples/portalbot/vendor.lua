---@class PBConsumable -- Represents a consumable the bot wants to track for vendoring purposes
---@field ClassId number -- The class id of the item
---@field Name string -- The name of the item
---@field BuyCount number -- How many you want to buy when vendoring
---@field LowCount number -- How many you have left before wanting to vendor

---@class PBVendor
---@field Consumables { [number]: PBConsumable }
local PBVendor = {
  Consumables = {}
}

---Set consumables bot should track
---@param consumables { [number]: PBConsumable }
function PBVendor:SetConsumables(consumables)
  self.Consumables = consumables
end

---Check if we are low on consumables and need to vendor
---@return boolean -- true if we need to go vendor
function PBVendor:NeedsVendoring()
  local isLow = false
  for i,consumable in ipairs(self.Consumables) do
    local consumableCount = game.Character.GetInventoryCount(function(wo)
      return wo.ClassId == consumable.ClassId
    end)
    if consumableCount <= consumable.LowCount then
      isLow = true
      print("I am low on" .. consumable.Name .. ". I have (" .. consumableCount .. "/" .. consumable.LowCount .. "/" .. consumable.BuyCount .. ")")
    else
      print("I am fine on" .. consumable.Name .. ". I have (" .. consumableCount .. "/" .. consumable.LowCount .. "/" .. consumable.BuyCount .. ")")
    end
  end

  return isLow
end

local getVendorPrice = function(objectId)
  for i,k in ipairs(game.World.Vendor.Items) do
    if k.ObjectID == objectId or k.WeenieDesc.WeenieClassId == objectId then
      return k.WeenieDesc.Value
    end
  end
  print("Could not find vendor price for", objectId)

  return 0
end

---comment
---@param s PBVendor
---@param objectId number
---@param wantedAmount number
local buy = function(s, objectId, wantedAmount)
  for i,k in ipairs(game.World.Vendor.Items) do
    if k.ObjectID == objectId or k.WeenieDesc.WeenieClassId == objectId then
      print("Buy:", k.WeenieDesc.Name, "x" .. wantedAmount)
      await(game.Actions.VendorClearBuyList())
      await(game.Actions.VendorAddToBuyList(k.ObjectID, wantedAmount))
      await(game.Actions.VendorBuyAll())
      do return end
    end
  end
end

local sellNotes = function()
  local tradeNote = nil ---@type WorldObject
  for i,wo in ipairs(game.Character.Inventory) do
    if wo.Name:match("Trade Note") then
      if wo.Value(IntId.StackSize) == 1 then
        tradeNote = wo
      elseif tradeNote == nil or tradeNote.Value(IntId.StackSize) > wo.Value(IntId.StackSize) then
        tradeNote = wo
      end
    end
  end

  if tradeNote == nil then
    print("No trade notes!")
    return false
  else
    if tradeNote.Value(IntId.StackSize) ~= 1 then
      local res = await(game.Actions.ObjectSplit(tradeNote.Id, game.CharacterId, 1))
      tradeNote = game.World.Get(res.NewStackObjectId)
    end

    print("Selling Note:", tradeNote)
    await(game.Actions.VendorAddToSellList(tradeNote.Id))
    await(game.Actions.VendorSellAll())
    return true
  end
end

function PBVendor:GoVendor(callback)
  local lastres
  local portalGem = game.Character.GetFirstInventory("Celdiseth's Portal Gem")
  lastres = await(portalGem.Use())
  if not lastres.Success then return callback(lastres) end

  local summonedPortal = game.World.Get(lastres.SummonedPortalId)
  await(summonedPortal.Use())

  local door = game.World.GetNearest("Door")

  repeat
    lastres = await(door.Use())
    if not lastres.Success then return callback(lastres) end
  until door.Value(IntId.PhysicsState)/4%2 >= 1

  local vendor = game.World.GetNearest("Master Celdiseth the Archmage")
  lastres = await(vendor.Use())
  if not lastres.Success then return callback(lastres) end

  for i,consumable in ipairs(self.Consumables) do
    local consumableCount = game.Character.GetInventoryCount(function(wo)
      return wo.ClassId == consumable.ClassId
    end)
    if consumableCount <= consumable.BuyCount then
      local wantedAmount = (consumable.BuyCount - consumableCount)
      local price = (getVendorPrice(consumable.ClassId) * wantedAmount)

      while game.Character.GetInventoryCount("Pyreal") < price do
        if not sellNotes() then
          return { Success = false, Error = ActionError.SourceItemNotInInventory, ErrorDetails = "No notes to sell" }
        end
      end

      buy(self, consumable.ClassId, wantedAmount)
    end
  end

  callback(lastres);
end

return PBVendor