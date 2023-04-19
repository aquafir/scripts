local ac = require("acclient")
local views = require("utilitybelt.views")
local ImGui = require("imgui")
local im = ImGui.ImGui;

local myHud = nil ---@type Hud|nil

-- The left line D3DObj
local lineLeft = nil ---@type DecalD3DObj|nil
-- The right line D3DObj
local lineRight = nil ---@type DecalD3DObj|nil

-- The length of the lines (Y)
local length = 2
-- The scale of the lines (on X/Z)
local scale  = 0.05
-- Color of the lines (AARRGGBB)
local color = 0x99FF00fd
-- vertical offset angle
local verticalOffset = 0.5
-- horizontal offset angle
local horizontalOffset = 10

-- Handler for myHud.OnRender. This gets called each time this hud should render
-- its contents. We do all the drawing of controls here.
local myHud_onRender = function()
  local lineLengthInputChanged, lineLengthResult = im.DragFloat("Line Length", length, 0.1, 0.1, 100)
  if lineLengthInputChanged then length = lineLengthResult end

  local scaleInputChanged, scaleResult = im.DragFloat("Scale", scale, 0.001, 0.001, 1)
  if scaleInputChanged then scale = scaleResult end

  local verticalOffsetInputChanged, verticalOffsetResult = im.DragFloat("Vertical Offset", verticalOffset, 0, 0.01, 1.5)
  if verticalOffsetInputChanged then verticalOffset = verticalOffsetResult end

  local horizontalOffsetInputChanged, horizontalOffsetResult = im.DragFloat("Horizontal Offset", horizontalOffset, 0, 0.1, 180)
  if horizontalOffsetInputChanged then horizontalOffset = horizontalOffsetResult end

  local colorInputChanged, colorResult = im.ColorPicker4("Color", ac.DecalD3D.ColorToVec4(color), ImGui.ImGuiColorEditFlags.AlphaBar)
  if colorInputChanged then color = ac.DecalD3D.Vec4ToColor(colorResult) end
end

---Setup a DecalD3DObj line
---@param obj DecalD3DObj -- The object to setup
---@param direction number -- The direction to angle outwards from the character. -1 is left, 1 is right
function SetupLine(obj, direction)
  -- we use a cube and use scaling on different axis to change it into a 3d line
  obj.SetShape(ac.DecalD3DShape.Cube)
  UpdateLine(obj, direction)
  obj.Visible = true
end

---Update a DecalD3DObj line
---@param obj DecalD3DObj -- The object to update
---@param direction number -- The direction to angle outwards from the character. -1 is left, 1 is right
function UpdateLine(obj, direction)
  local me = ac.Coordinates.Me

  -- update properties from settings (ui may have updated them)
  obj.Color = color
  obj.ScaleX = scale
  obj.ScaleZ = scale
  obj.ScaleY = length

  local startVec = Vector3.new(me.NS, me.EW, me.Z + verticalOffset)
  local angle = (math.pi / 180) * (ac.Movement.Heading - horizontalOffset)
  if direction == 1 then
    angle = (math.pi / 180) * (ac.Movement.Heading + horizontalOffset)
  end
  local endVec = Vector3.new(me.NS + (length * math.sin(angle)), me.EW + (length * math.cos(angle)), me.Z + verticalOffset)
  local middleVec = (endVec - startVec) / 2

  -- D3DObjs are drawn centered, so we calculate the middleVec position above and anchor the object there
  obj.Anchor(game.Character.Id, verticalOffset, middleVec.x, middleVec.y, middleVec.z)

  -- orient the d3dobj to the character
  obj.OrientToObject(game.Character.Id, 0, false)
end

---OnRender3D event handler. This is called once per frame during the 3D drawing portion
function OnRender2D()
  -- make sure lines are not nil and update their display properties
  if lineLeft ~= nil then UpdateLine(lineLeft, -1) end
  if lineRight ~= nil then UpdateLine(lineRight, 1) end
end

---Initialize the script
function Init()
  -- create some new D3DObjs for our lines
  lineLeft = ac.DecalD3D.NewD3DObj()
  lineRight = ac.DecalD3D.NewD3DObj()
  
  -- setup some properties on the lines
  SetupLine(lineLeft, -1)
  SetupLine(lineRight, 1)
  
  -- subscribe to games OnRender3D event
  game.OnRender2D.Add(OnRender2D)

  -- create our hud
  myHud = views.Huds.CreateHud("Cones")
  myHud.Visible = true;
  myHud.WindowSettings = ImGui.ImGuiWindowFlags.AlwaysAutoResize

  -- subscribe to hud events, with the handlers we defined above
  myHud.OnRender.Add(myHud_onRender)
end

-- listen for gamestate changes
game.OnStateChanged.Add(function (evt)
  if evt.NewState == ClientState.In_Game then
    -- if we are now ingame, init
    Init()
  elseif evt.NewState == ClientState.Logging_Out then
    -- if we are logging out, unsubscribe from events and dispose any created D3DObjs
    game.OnRender2D.Remove(OnRender2D)
    if lineLeft ~= nil then lineLeft.Dispose() end
    if lineRight ~= nil then lineRight.Dispose() end
    lineLeft = nil
    lineRight = nil

    -- destroy hud
    if myHud ~= nil then myHud.Dispose() end
  end
end)

-- if we are ingame when the script loads, call init
if game.State == ClientState.In_Game then
  Init()
end