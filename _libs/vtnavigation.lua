local vtfs = require("filesystem").GetCustom("C:\\Games\\VirindiPlugins\\VirindiTank\\", "Used to read and run VTank nav files")
local ac = require("acclient")
local VTFormats = require("VTFormats")



local files = {} ---@type { [number]: string }
local filesError
local navRoute = nil ---@type VTNavRoute|nil

local d3dObjs = {} ---@type {[number]: DecalD3DObj}

---@class VTNavigation
---@field Enabled boolean -- enabled
---@field HasAccess boolean -- Wether or not we have fs access to the vtank directory
---@field CurrentNavFile string|nil -- currently loaded nav file
---@field VTFS FileSystemAccess -- filesystem access to vt nav directory
local VTNavigation = {
  Enabled = false,
  HasAccess = vtfs.IsApproved,
  CurrentNav = nil,
  VTFS = vtfs
}

---refreshes the list of vtank nav files
---@return string|nil -- error, if any
function VTNavigation.RefreshNavFiles()
  local _files, error = vtfs.GetFiles("")
  if error then return error end

  local navFiles = {}
  for _, file in ipairs(_files) do
    if file:sub(1, 2) ~= "--" and file:sub(-4) == ".nav" then
      table.insert(navFiles, file)
    end
  end

  files = navFiles

  return nil
end

---Gets a list of vtank nav files
---@return { [number]: string } -- list of nav files
---@return string|nil -- error, if any
function VTNavigation.GetNavFiles()
  return files, filesError
end

---Load a vtank nav file
---@param file string -- file to load
---@return boolean -- wether or not the file was loaded successfully
function VTNavigation.Load(file)
  VTNavigation.CurrentNavFile = file
  print("Load nav:", file)

  navRoute = VTFormats.VTNavRoute:create(file)
  local navLines, navLinesError = vtfs.ReadLines(file)
  if navLinesError == nil then
    local error = navRoute:parse(navLines)

    if error ~= nil then
      print("Error parsing nav file:", error)
      return false
    end
  else
    print(navLinesError)
    return false
  end

  return true
end

---Draw the currently loaded nav route
function VTNavigation.Draw()
  for i, d3dObj in ipairs(d3dObjs) do
    d3dObj.Dispose()
  end
  d3dObjs = {}

  if navRoute == nil then return end

  local prevPoint = nil ---@type VTWaypoint|nil
  for i, waypoint in ipairs(navRoute.Waypoints) do
    if waypoint.Type == VTFormats.WaypointType.Point then
      if prevPoint == nil then
        prevPoint = waypoint
      else
        local obj = ac.DecalD3D.NewD3DObj()

        obj.Visible = false;
        obj.Color = 0xAA55ff55
        obj.SetShape(ac.DecalD3DShape.Cube)
        obj.Anchor((prevPoint.EastWest + waypoint.EastWest) / 2, (prevPoint.NorthSouth + waypoint.NorthSouth) / 2, (prevPoint.Z + waypoint.Z) * 120 + 0.05);
        obj.OrientToCoords(waypoint.EastWest, waypoint.NorthSouth, waypoint.Z * 240 + 0.05, true);
        obj.ScaleX = 0.25;
        obj.ScaleZ = 0.25;
        obj.ScaleY = waypoint:DistanceTo(prevPoint)
        obj.Visible = true;
        table.insert(d3dObjs, obj)
        
        prevPoint = waypoint
      end
    end
  end
end

local init = function ()
  if vtfs.IsApproved then
    VTNavigation.HasAccess = true
    VTNavigation.RefreshNavFiles()
  else
    vtfs.OnAccessChanged.Add(function (evt)
      VTNavigation.HasAccess = evt.AccessGranted
      if evt.AccessGranted then
        VTNavigation.RefreshNavFiles()
      end
    end)
  end
end

-- listen for gamestate changes
game.OnStateChanged.Add(function (evt)
  if evt.NewState == ClientState.In_Game then
    -- if we are now ingame, init
    init()
  end
end)

-- if we are ingame when the script loads, call init
if game.State == ClientState.In_Game then
  init()
end

return VTNavigation;