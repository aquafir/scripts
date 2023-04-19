Helpers = {}

---Returns a string split by a separator: https://stackoverflow.com/questions/1426954/split-string-in-lua
---@param input string
---@param sep string
---@return table
function split (input, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

---Returns a case-insensitive version of input pattern
function case_insensitive_pattern(pattern)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)
    if percent ~= "" or not letter:match("%a") then
      return percent .. letter
    else
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end
  end)
  return p
end

return Helpers