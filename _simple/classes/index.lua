--Define the class with its properties and methods
--Lua doesn't have built-in class constructs but you can simulate classes using tables and metatables
Person = {
  age = 20, --Default value for instances uses this for their construction
}
Person.__index = Person

function Person.new(name, age)
  local self = setmetatable({}, Person)
  self.name = name or "Bob" --Default
  self.age = age
  return self
end

function Person:info()
  return "Name: " .. self.name .. ", Age: " .. self.age
end

-- Create instances
local person1 = Person.new("Alice", 30) --Alice 30
local person2 = Person.new()            --Bob   20
local person3 = Person.new(nil, 50)     --Bob   50

-- Access instance methods and properties
print(person1:info()) 
print(person2:info()) 
print(person3:info()) 
