function ToHex(num) return "0x" .. string.format("%08x", num) end

for i,armor in ipairs(game.Character.Equipment) do
  local armorMask = EquipMask.FromValue(armor.Value(IntId.CurrentWieldedLocation))
  print(armor, ToHex(armorMask.ToNumber()), armorMask)
  for i,mask in ipairs(EquipMask.GetValues()) do
    if mask ~= EquipMask.None and armorMask + mask == armorMask then
      print("  - "  .. ToHex(mask.ToNumber()) .. ":" .. tostring(mask))
    end
  end
end

--Enums are Userdata not number constants
print(IntId.AccountRequirements.ToNumber())
print(IntId.FromValue(IntId.AccountRequirements.ToNumber()))