-- --TODO: 3d/2d


---Spinning texture
  local centerPos = Vector2.new(500, 500) -- The center position of the Rubik's Cube
  local cubeRotation = 0 -- The current rotation of the Rubik's Cube
  local cubeTexture = views.Huds.CreateTexture("cube.jpg") -- The texture for the Rubik's Cube

  local hud = views.Huds.CreateHud("Rubik's Cube###RubiksCube")
  hud.ShowInBar = false
  hud.Visible = true

  function Rotate(v, cos_a, sin_a) 
      return Vector2.new(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a);
  end

  function DrawImageRotated(texturePtr, center, size, angle)
    angle = angle * (math.pi / 180.0)
    local cos_a = math.cos(angle);
    local sin_a = math.sin(angle);
    local p1 = center + Rotate(Vector2.new(-size.X * 0.5, -size.Y * 0.5), cos_a, sin_a)
    local p2 = center + Rotate(Vector2.new(size.X * 0.5, -size.Y * 0.5), cos_a, sin_a)
    local p3 = center + Rotate(Vector2.new(size.X * 0.5, size.Y * 0.5), cos_a, sin_a)
    local p4 = center + Rotate(Vector2.new(-size.X * 0.5, size.Y * 0.5), cos_a, sin_a)
    im.GetWindowDrawList().AddImageQuad(texturePtr, p1, p2, p3, p4)
  end

  hud.OnPreRender.Add(function ()
      local size = Vector2.new(400, 400) -- The size of the window containing the Rubik's Cube
      im.SetNextWindowPos(centerPos - (size / 2))
      im.SetNextWindowSize(size)
  end)

  hud.OnRender.Add(function()
      im.InvisibleButton("rendercanvas", im.GetContentRegionAvail())
      local p0 = im.GetItemRectMin()
      local p1 = im.GetItemRectMax()

      local drawList = im.GetWindowDrawList()
      drawList.PushClipRect(p0, p1)

      -- Rotate the cube
      cubeRotation = cubeRotation + 1
      if cubeRotation > 360 then
          cubeRotation = cubeRotation - 360
      end

      -- Draw the Rubik's Cube
      local cubeSize = Vector2.new(200, 200)
      local cubeCenter = p0 + cubeSize / 2
      
      DrawImageRotated(cubeTexture.TexturePtr, cubeCenter, cubeSize, cubeRotation)
      drawList:PopClipRect()
  end)