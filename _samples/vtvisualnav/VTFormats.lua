local ac = require("acclient")

---@enum WaypointType
local WaypointType = {
  Point = 0,
  Portal = 1,
  Recall = 2,
  Pause = 3,
  ChatCommand = 4,
  OpenVendor = 5,
  Portal2 = 6,
  UseNPC = 7,
  Checkpoint = 8,
  Jump = 9,
  Other = 99
}

---@enum NavType
local NavType = {
  Linear = 2,
  Circular = 1,
  Target = 3,
  Once = 4
}

---@class VTWaypoint
---@field Type WaypointType -- The type of waypoint
---@field NorthSouth number
---@field EastWest number
---@field Z number
local VTWaypoint = {}
VTWaypoint.__index = VTWaypoint

---Create a new VTWaypoints
---@param type WaypointType
---@param ns number
---@param ew number
---@param z number
---@return VTWaypoint
function VTWaypoint:create(type, ns, ew, z)
  local waypoint = {} ---@type VTWaypoint
  setmetatable(waypoint, VTWaypoint)
  waypoint.Type = type
  waypoint.NorthSouth = ns
  waypoint.EastWest = ew
  waypoint.Z = z
  return waypoint
end

function pow(num, p)
  return num * num
end

function VTWaypoint:DistanceTo(waypoint)
  return math.abs(math.sqrt(pow(waypoint.NorthSouth - self.NorthSouth, 2) + pow(waypoint.EastWest - self.EastWest, 2) + pow(waypoint.Z - self.Z, 2))) * 240;
end

---@class VTNavRoute
---@field NavFile string -- The nav file this route was loaded from
---@field Type NavType -- The type of nav
---@field FollowId number|nil -- The id of the object to follow, only applicable for follow routes
---@field FollowName string|nil -- The name of the object to follow, only applicable for follow routes
---@field Waypoints { [number]: VTWaypoint } -- list of waypoints
local VTNavRoute = {}
VTNavRoute.__index = VTNavRoute

---Create a new VTNavRoute instance
---@param file string -- nav file
---@return VTNavRoute -- A new VTNavRoute instance
function VTNavRoute:create(file)
   local navRoute = {} ---@type VTNavRoute
   navRoute.Waypoints = {}
   setmetatable(navRoute, VTNavRoute)
   navRoute.NavFile = file
   navRoute.Type = NavType.Circular
   navRoute.FollowId = nil
   navRoute.FollowName = nil
   return navRoute
end

---Parse VT Nav file lines
---@param lines { [number]: string } -- the lines of the vt nav file
---@return string|nil -- the error with parsing, if any
function VTNavRoute:parse(lines)
  if #lines == 0 then return "File ended prematurely" end

  -- check header
  local headerLine = table.remove(lines, 1)
  if headerLine ~= "uTank2 NAV 1.2" then
    return "Invalid VTNavFile Header: Expected: \"uTank2 NAV 1.2\", Got: \"" .. headerLine .. "\""
  end

  if #lines == 0 then return "File ended prematurely" end

  -- nav type
  local navType, navTypeError = self:tryParseNumber(lines)
  if navTypeError ~= nil then return "Invalid NavType: " .. navTypeError end
  self.Type = navType

  if #lines == 0 then return "File ended prematurely" end

  if self.Type == NavType.Target then
    return self:parseTarget(lines)    
  elseif self.Type == NavType.Circular or self.Type == NavType.Linear then
    return self:parseCircularLinear(lines)
  end
end

---Parse a follow target route file body
---@private
---@param lines { [number]: string } -- the nav route body
function VTNavRoute:parseTarget(lines)
  self.FollowName = table.remove(lines, 1)

  if #lines == 0 then return "File ended prematurely" end

  -- follow object id
  local followId, followIdError = self:tryParseNumber(lines)
  if followIdError ~= nil then return "Invalid Follow Target Id: " .. followIdError end
  self.FollowId = followId
end

---Parse a circular / linear nav route body
---@private
---@param lines { [number]: string } -- the nav route body
function VTNavRoute:parseCircularLinear(lines)
  -- record count
  local recordCount, recordCountError = self:tryParseNumber(lines)
  if recordCountError ~= nil then return "Invalid Record Count: " .. recordCountError end

  for i=1, recordCount, 1 do
    -- record type
    local recordType, recordTypeError = self:tryParseNumber(lines)
    if recordTypeError ~= nil then return "Invalid Record Type: " .. recordTypeError end
    
    if recordType == WaypointType.Point then
      local ns, ew, z, coordsError = self:tryParseCoords(lines)
      if coordsError ~= nil then return "Invalid coordinates: " .. coordsError end
      table.insert(self.Waypoints, VTWaypoint:create(WaypointType.Point, ns, ew, z))
    end
  end
end

---Try and parse coordinates from nav file
---@private
---@param lines {[number]: string} -- The nav file lines
---@return number
---@return number
---@return number
---@return string|nil
function VTNavRoute:tryParseCoords(lines)
  local northSouth, northSouthError = self:tryParseNumber(lines)
  if northSouthError ~= nil then return 0,0,0, "Invalid NorthSouth Coordinate: " .. northSouthError end

  local eastWest, eastWestError = self:tryParseNumber(lines)
  if eastWestError ~= nil then return 0,0,0,"Invalid EastWest Coordinate: " .. eastWestError end

  local z, zError = self:tryParseNumber(lines)
  if zError ~= nil then return 0,0,0, "Invalid Z Coordinate: " .. zError end

  -- extra 0 at end of coords, not sure what it is...
  table.remove(lines, 1)

  return northSouth, eastWest, z, nil
end

---Try and parse a number from nav file lines
---@private
---@param lines {[number]: string} -- The nav file lines
---@return number -- The parsed number, if able to be parsed
---@return string|nil -- The error, if any
function VTNavRoute:tryParseNumber(lines)
  if #lines == 0 then return 0, "File ended prematurely" end
  
  local numberLine = table.remove(lines, 1)
  local parsedNumber = tonumber(numberLine)
  if parsedNumber == nil then
    return 0, "Could not parse number: " .. numberLine
  end

  return parsedNumber, nil
end

return {
  WaypointType = WaypointType,
  VTNavRoute = VTNavRoute,
  NavType = NavType
}