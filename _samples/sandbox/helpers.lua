---@class Helpers
local Helpers = {}

local _metaCallbacks = {}
local _nextCallbackId = 1

---Don't use directly... used by the meta expression callback system
---@param callbackId number
---@param result string
function __MetaCBHandler(callbackId, result)
  if _metaCallbacks[callbackId] ~= nil then
    _metaCallbacks[callbackId](result)
    _metaCallbacks[callbackId] = nil
  end
end

---Calls an expression, then calls the passed callback with the results
---@param expression string -- The expression to run
---@param callback fun(res: string): nil -- The callback to be called with the results
function Helpers.DoExpression(expression, callback)
  local callbackId = _nextCallbackId
  _nextCallbackId = _nextCallbackId + 1
  _metaCallbacks[callbackId] = callback
  -- todo: need a way to get current script name
  game.Actions.InvokeChat("/ub mexec chatbox[`/ub lexecs sandbox __MetaCBHandler(" .. tostring(callbackId) .. ", \"`+cstr[" .. expression .. "]+`\")`]")
end

-- need to expose the callback handler as a global...
_G["__MetaCBHandler"] = __MetaCBHandler

return Helpers