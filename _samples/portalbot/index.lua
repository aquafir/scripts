local ac = require("acclient")

print("hello")

--[[

local vendor = require("vendor")

vendor:SetConsumables({
  { Name = "Prismatic Taper", ClassId = 20631, BuyCount = 2000, LowCount = 100 },
  { Name = "Celdiseth's Portal Gem", ClassId = 8974, BuyCount = 100, LowCount = 10 },
})

if vendor:NeedsVendoring() then
  vendor:GoVendor(function()
    game.Actions.InvokeChat("/mp")
    print(await(ac.Movement.RunStraightTo(0x016C01BD, 53.29, -44.51, 0, 0.2)).Success)
    print(await(ac.Movement.SetHeading(0)).Success)
    print("All done.") 
  end)
end
]]