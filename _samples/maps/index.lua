local views = require("utilitybelt.views")
local fs = require("filesystem")
local ImGui = require("imgui")
local im = ImGui.ImGui

local v0 = Vector2.new(0,0)
local v1 = Vector2.new(1,1)

-- Measure the time it takes to load textures
local startTextureLoad = os.clock()
local mapTexture = views.Huds.CreateTexture("resources/landscapemap.png")
print("Loaded textures in", math.floor((os.clock() - startTextureLoad) * 1000) / 1000, "seconds")

local hud = views.Huds.CreateHud("Maps")
hud.Visible = true

-- These values are updated every render event:
  --- The size of the available content drawing area.
  local contentSize = Vector2.new(0,0)
  --- The upper left coordinates of the content drawing area.
  local upperLeft = Vector2.new(0,0)
  --- The lower right coorindates of the content drawing area.
  local lowerRight = Vector2.new(0,0)
  --- The aspect ratio of the window. contentSize.X / contentSize.Y
  local windowAspectRatio = 1

--- The current zoom
local zoom =1
--- Wether or not the user is dragging/panning the map
local isDragging = false
--- The start coordinates of the last drag / pan
local dragStart = Vector2.new(0,0)
--- The pan offset the map should be drawn at
local panOffset = Vector2.new(0,0)

--- Transform a max aka lower right rect coordinates by an aspect ratio. This assumes upper left is 0,0
---@param aspectRatio number -- The aspect ratio to transform by
---@param max Vector2 -- The lower right / maximum coordinates
---@return Vector2 -- The transformed max
function TransformRectByAspectRatio(aspectRatio, max)
  local uv_max = Vector2.new(max.X, max.Y)
  
  if windowAspectRatio >= 1 then
    uv_max.X = max.X * (contentSize.X / windowAspectRatio) / contentSize.X
  else
    uv_max.Y = max.Y * (contentSize.Y * windowAspectRatio) / contentSize.Y
  end

  return uv_max
end

hud.OnPreRender.Add(function ()
  im.SetNextWindowSizeConstraints(Vector2.new(200, 200), Vector2.new(9999, 9999))
end)

hud.OnRender.Add(function ()
  im.InvisibleButton("rendercanvas", im.GetContentRegionAvail())
  upperLeft = im.GetItemRectMin();
  lowerRight = im.GetItemRectMax();
  contentSize = im.GetItemRectSize()
  windowAspectRatio = contentSize.X / contentSize.Y

  local dragOffset --[[@as Vector2]]

  if im.IsItemHovered() then
    local startZoom = zoom
    zoom = zoom + im.GetIO().MouseWheel * 0.1
    zoom = math.min(10, math.max(1, zoom))

    if startZoom ~= zoom then
      -- how to adjust pan offset...
    end
  end

  if im.IsItemActive() and im.IsMouseDragging(ImGui.ImGuiMouseButton.Left) then
    if not isDragging then
      dragStart = im.GetMousePos()
    end
    isDragging = true
  else
    if isDragging then
      panOffset = panOffset + im.GetMousePos() - dragStart
      isDragging = false
    end
  end

  local drawList = im.GetWindowDrawList()
  drawList.PushClipRect(upperLeft, lowerRight);
  drawList.AddRectFilled(upperLeft, lowerRight, 0xff)

  local uv_max = Vector2.new(v1.X, v1.Y)
  if windowAspectRatio >= 1 then
    uv_max.X = (contentSize.X / windowAspectRatio) / contentSize.X
  else
    uv_max.Y = (contentSize.Y * windowAspectRatio) / contentSize.Y
  end
  local lowerRight = Vector2.new(math.min(contentSize.X, contentSize.Y), math.min(contentSize.X, contentSize.Y))
  local dragOffset = isDragging and ((im.GetMousePos() - dragStart) * zoom) or v0

  local imageMin = panOffset + dragOffset + upperLeft
  local imageMax = panOffset + dragOffset + upperLeft + (lowerRight)

  drawList.AddImage(mapTexture.TexturePtr, imageMin, imageMax, v0 + ((zoom - 1) * v1), v1 - ((zoom - 1) * v1))
  

  drawList.AddRectFilled(upperLeft, upperLeft + Vector2.new(contentSize.X, 48), 0x88000000)
  drawList.AddText(upperLeft, 0xffffffff, "p_max: " .. tostring(lowerRight) .. ", uv_max: " .. tostring(uv_max))
  drawList.AddText(upperLeft + Vector2.new(0, 16), 0xffffffff, "Cursor: " .. tostring(im.GetMousePos()) .. " Start: " .. tostring(dragStart) .. " Offset: " .. (isDragging and tostring(dragOffset) or "NotDragging"))
  drawList.AddText(upperLeft + Vector2.new(0,32), 0xffffffff, "Zoom: " .. zoom)

  drawList.PopClipRect();
end)