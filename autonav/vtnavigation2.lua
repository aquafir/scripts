local vtfs = require("filesystem").GetCustom("C:\\Games\\VirindiPlugins\\VirindiTank\\",
  "Used to read and run VTank nav files")

VTNav = {}

---Gets a list of vtank nav files matching a filter
---@param include string|nil Files to include if present
---@param exclude string|nil Files to ignore if present
---@return { [number]: string }|nil -- list of nav files
VTNav.GetNavFiles = function(include, exclude)
  local _files, error = vtfs.GetFiles("")
  if error then return nil end

  local navFiles = {}
  for _, file in ipairs(_files) do
    if file:sub(1,2) ~= "--" and file:sub(-4) == ".nav" then
      if (include == nil or file:match(include)) and (exclude == nil or not file:match(exclude)) then
        -- print("Adding " .. file)
        table.insert(navFiles, file)
      -- else print("Not loading " .. file) 
      end
    end
  end

  return navFiles
end


return VTNav
