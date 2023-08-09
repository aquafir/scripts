-----------------------LIBS-------------------------
local fs = require("filesystem").GetScript() -- File system
local sd = require("levenshtein")
local IM = require("imgui")
local ImGui = IM ~= nil and IM.ImGui or {}
local views = require("utilitybelt.views")
local hud   = nil ---@type Hud|nil


----------------------CONFIG-----------------------
local maxMatches = 5



----------------------STATE------------------------
---@type string[]
local commandText = fs.ReadLines("Commands.txt")
print("Loaded commands: ", #commandText)

---@type string|nil Text input narrowing down commands
local commandFilter = ""

---@type string[]
local matches = {}

----------------------LOGIC------------------------
-- Returns the Levenshtein distance between the two given strings
function levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0
	
        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
	
        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
	
        -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end
			
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	
        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end

function LevenshteinCompare(a, b)
--  return sd.lev_iter(commandFilter, a) < sd.lev_iter(commandFilter, b)
  return levenshtein(commandFilter, a) < levenshtein(commandFilter, b)
end

---Finds matches for commandFilter
function ApplyFilter()
  -- Case-insensitive searches such so one field to store desired text and the other a case-insensitive pattern
  local filter = case_insensitive_pattern(commandFilter)
  local matchCount = 1
  matches = {}

  print(levenshtein('abcD','abc'))
  table.sort(commandText, LevenshteinCompare)
  print('b')


  for index, value in ipairs(commandText) do
    print(index, ": ", value)    
  end

  for c, i in commandText do
    matches[matchCount] = c
    matchCount = matchCount + 1
    if matchCount >= maxMatches then return end
  end

  -- for c, i in commandText do
  --     if (commandFilter == "" or tostring(c):find(filter)) then
  --       --print("Accepting: " .. tostring(c))
  --       matches[matchCount] = c
  --       matchCount = matchCount + 1

  --       if matchCount >= maxMatches then return end
  --     end
  -- end
end

---Returns a case-insensitive version of input pattern
---@param pattern string
---@return string
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
-----------------RENDER COMPONENTS-----------------
function RenderFilters()
  local inputFlags = IM.ImGuiInputTextFlags.AutoSelectAll 
  + IM.ImGuiInputTextFlags.AllowTabInput 
  --+ IM.ImGuiInputTextFlags.EnterReturnsTrue
  --ImGui.BeginChild("Filters", Vector2.new(ImGui.GetWindowWidth(), 40), true, IM.ImGuiWindowFlags.AlwaysAutoResize)
  local filterTextChanged, newFilterText = ImGui.InputText("", commandFilter, 500, inputFlags)
  if filterTextChanged then
    commandFilter = newFilterText
    ApplyFilter()
    print(newFilterText)
    -- if(newFilterText == true) then print("True!") end
  end

  --ImGui.SameLine(250)
  --ImGui.EndChild()
end

function RenderCommands()
  for key, value in pairs(matches) do
    ImGui.Text(key .. ": " .. value)    
  end
end

-------------------RENDER EVENTS--------------------
-- Called each time this hud should render.  Render controls here
local OnHudRender = function()
  RenderFilters()
  RenderCommands()

  --if(ImGui.IsKeyPressed(IM.ImGuiKey.ModAlt))
  if(ImGui.IsKeyPressed(IM.ImGuiKey.Enter)) then print("Enter!") end
  --If you set an alpha in the PreRender it applies to all script windows, so reset it after rendering
  ImGui.PushStyleVar(IM.ImGuiStyleVar.Alpha, 1)
end

-- function OnRender2D()
-- end

-- Called before our window is registered
function OnPreRender()
  --Constrain resize dimensions
  -- ImGui.SetNextWindowSizeConstraints(minWindowSize, maxWindowSize);
  
  --Force a size / position in the center
  ImGui.SetWindowSize(Vector2.new(300, 300))
  ImGui.SetNextWindowPos(Vector2.new(ImGui.GetWindowViewport().Size.X/2-150, ImGui.GetWindowViewport().Size.Y/2-150))

  --Set an alpha (make sure to remove after Render)
  ImGui.PushStyleVar(IM.ImGuiStyleVar.Alpha, 0.8)
end





---------------------INIT/DISPOSE------------------------
function Init()
  hud = views.Huds.CreateHud("MyScript")
  -- True if you want it to start visible, false invisible
  hud.Visible = true

  --Style
  hud.WindowSettings = IM.ImGuiWindowFlags.AlwaysAutoResize -- Size to fit
                     + IM.ImGuiWindowFlags.NoDecoration     -- Borderless
                    --  + IM.ImGuiWindowFlags.NoBackground     -- No BG

  -- Alternatively use a size range in prerender
  hud.OnPreRender.Add(OnPreRender)
  -- subscribe to events
  -- game.OnRender2D.Add(OnRender2D)

  -- subscribe to hud events, with the handlers we defined above
  hud.OnRender.Add(OnHudRender)
end

function Dispose()
  -- Unsubscribe from events
  -- game.OnRender2D.Remove(OnRender2D)
  -- hud.OnPreRender.Remove(OnPreRender)

  -- Dispose of things like D3DObjs
  -- if renderedObj ~= nil then renderedObj.Dispose() end
  -- renderedObj = nil

  -- Destroy hud
  if hud ~= nil then hud.Dispose() end
end



-------------------------START------------------------------
game.OnStateChanged.Add(function(evt)
  -- Start on login
  if evt.NewState == ClientState.In_Game then Init()
  -- Dispose on log out
  elseif evt.NewState == ClientState.Logging_Out then Dispose() end
end)
-- ...or on script end
game.OnScriptEnd.Once(Dispose)
-- Start up if in game when the script loads
if game.State == ClientState.In_Game then Init() end
