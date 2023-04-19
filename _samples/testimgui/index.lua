local views = require("utilitybelt.views")
local ImGui = require("imgui")
local im = ImGui.ImGui;

-- some hud configuration
local minWindowSize = Vector2.new(300, 120)
local maxWindowSize = Vector2.new(800, 1000)

-- this will store our text from the ui
local myText = ""

-- create our hud
local myHud = views.Huds.CreateHud("My Input")
myHud.Visible = true;

-- Handler for myHud.onPreRender. This gets called before the hud is rendered.
-- We can use it to set our window constraints, or window position for example.
local myHud_onPreRender = function()
  -- give our hud some window size constraints
  im.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize)
end

-- Handler for myHud.OnRender. This gets called each time this hud should render
-- its contents. We do all the drawing of controls here.
local myHud_onRender = function()
  -- display our current text value
  im.Text("Current Text: " .. myText)

  -- ImGui::TableNextColumn(); ImGui::Checkbox("No titlebar", &no_titlebar);
  local no_titlebar = false; im.TableNextColumn(); im.Checkbox("No titlebar", no_titlebar);

  -- display a text input, inputChaged is a bool that tells us if the input
  -- value has changed, and textResult is the new value it was set to. 500
  -- is the max length this input accepts
  local inputChanged, textResult = im.InputText("myText Input", myText, 500)

  if inputChanged then
    myText = textResult
    print("myText was changed to:", myText)
  end

  -- display a button to print myText to chat
  -- ImGui.Button returns true if the button was clicked
  if im.Button("Print myText to chat") then
    print("myText is", myText)
  end
end

-- subscribe to hud events, with the handlers we defined above
myHud.OnPreRender.Add(myHud_onPreRender)
myHud.OnRender.Add(myHud_onRender)

-- subscribe to the onScriptEnd event and clean up our hud
game.OnScriptEnd.Once(function()
  -- unsubscribe from hud events
  myHud.OnPreRender.Remove(myHud_onPreRender)
  myHud.OnRender.Remove(myHud_onRender)

  -- destroy the hud
  myHud.Dispose()
end)