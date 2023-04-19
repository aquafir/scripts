---------------------
---- Network Log ----
---------------------
--
-- UI for viewing network messages
--
local acmessages = require("utilitybelt.acmessages")

local views = require("utilitybelt.views")
local _imgui = require("imgui")
local ImGui = _imgui.ImGui

--------------
--- config ---
--------------

-- minumum window size limit
local minWindowSize = Vector2.new(450, 250)

-- maximum window size limit
local maxWindowSize = Vector2.new(999999, 999999)

-- max messages to store
local maxMessageBufferSize = 500

-------------
--- state ---
-------------

-- message buffer to store incoming / outgoing messages
messageBuffer = {}

-- selected message, if any
selectedMessage = nil


---------------
--- helpers ---
---------------

-- renders properties for an object as a tree, recursively
-- we define the local and set to nil so we can recurse, otherwise
-- the local renderProps is not defined inside the function
local renderProps = nil
renderProps = function(obj, depth)
  ImGui.Indent(10)
  if type(obj) == "userdata" and depth < 8 then
    local props = obj.getPropertyKeys()
    if #props > 0 then
      for i, propName in ipairs(props) do
        if (propName == nil) then
          --print("Try get NIL prop", propName, "on", tostring(obj))
        else
          --print("Try get prop", propName, "on", tostring(obj))
          if type(obj[propName]) == "userdata" then
            local childProps = obj[propName].getPropertyKeys()
            if #childProps > 0 then
              ImGui.Text(string.format("%s:", propName))
              renderProps(obj[propName], depth+1)
            else
              ImGui.Text(string.format("%s  =  %s", propName, tostring(obj[propName])))
            end
          else
            ImGui.Text(string.format("%s  =  %s", propName, tostring(obj[propName])))
          end
        end
      end
    else
      ImGui.Text(tostring(obj))
    end
  else
    ImGui.Text(tostring(obj))
  end
  ImGui.Unindent(10)
end

--------------------------
--- hud event handlers ---
--------------------------

-- called before our window is registered. you can set window options here
local onPreRender = function()
  -- set minimum window size
  ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);
end

-- called during the hud window render. draw your ui here
local onRender = function()
  local colPadding = 8
  local contentPaddingWidth = ImGui.GetContentRegionAvail().X / 2 - 8;
  local contentPanelHeight = ImGui.GetContentRegionAvail().Y;
  local contentPanelSize = Vector2.new(contentPaddingWidth, contentPanelHeight);

  -- beginChild with a specified size makes the area scrollable
  -- be sure to call endChild()
  ImGui.BeginChild("messagelist", contentPanelSize)
  for i, message in pairs(messageBuffer) do
    -- putting a group here makes the later isItemClicked act on the entire row
    ImGui.BeginGroup(i)
    ImGui.Text(message.time.toString("HH:mm:ss"))
    ImGui.SameLine(0, colPadding)
    if message.direction == MessageDirection.S2C then
      ImGui.Text("In")
    else
      ImGui.Text("Out")
    end
    ImGui.SameLine(0, colPadding)
    ImGui.Text(string.format("0x%04X", message.type.toNumber()))
    ImGui.SameLine(0, colPadding)
    ImGui.Text(tostring(message.type))
    ImGui.EndGroup()
    -- check if this row was clicked and set a new selectedMessage if so
    if ImGui.IsItemClicked() then
      selectedMessage = message
    end
  end

  -- auto scroll if not scrolled to the bottom already
  if (ImGui.GetScrollY() >= ImGui.GetScrollMaxY()) then
    ImGui.SetScrollHereY(1.0);
  end

  -- end messages child
  ImGui.EndChild()

  ImGui.SameLine(0, 20)
  ImGui.BeginChild("messagedetails", contentPanelSize)
    if (selectedMessage == nil) then
      ImGui.TextWrapped("No message selected. Click on a message on the left to view its details here.");
    else
      renderProps(selectedMessage, 0)
    end
  ImGui.EndChild();
end


----------------------
--- event handlers ---
----------------------

-- called when the server sends us a network message
local onIncomingMessage = function(data)
  if (#messageBuffer >= maxMessageBufferSize) then
    table.remove(messageBuffer, 1)
  end
  messageBuffer[#messageBuffer + 1] = data
end

-- called when we send the server a network message
local onOutgoingMessage = function(data)
  if (#messageBuffer >= maxMessageBufferSize) then
    table.remove(messageBuffer, 1)
  end
  messageBuffer[#messageBuffer + 1] = data
end

------------------
--- initialize ---
------------------

-- create a new hud, set options, and register for hud events
local hud = views.Huds.CreateHud("Network Inspector")
hud.Visible = true
hud.showInBar = true
hud.OnPreRender.Add(onPreRender);
hud.OnRender.Add(onRender);

-- subscribe to every incoming / outgoing "io"
game.Messages.Incoming.Message.Add(onIncomingMessage)
game.Messages.Outgoing.Message.Add(onOutgoingMessage)

-- subscribe to scriptEnd event so we can tostring(message)
-- all subscribed to events should be ubscribed with `event.remove(handler)`
-- (since this is a `once` handler, it will automatically unsubscribe itself after being called once)
game.OnScriptEnd.Once(function()
  -- unsubscribe from any events we subscribed to
  game.Messages.Incoming.Message.Remove(onIncomingMessage)
  game.Messages.Outgoing.Message.Remove(onOutgoingMessage)
  hud.OnPreRender.Remove(onPreRender);
  hud.OnRender.Remove(onRender);

  -- destroy hud
  hud.Dispose();
end)

print("Network Inspector started")