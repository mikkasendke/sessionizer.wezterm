local wezterm = require "wezterm"
local history = require "sessionizer.history"

-- NOTE: Right now we can't find the label that was used since we can't detect all workspace switching
local action = {}

---@param window unknown
---@param pane unknown
---@param id string?
---@param label string
action.SwitchToWorkspace = function(window, pane, id, label)
    if not id then return end

    local current_workspace = wezterm.mux.get_active_workspace()
    history.push(current_workspace)
    window:perform_action(wezterm.action.SwitchToWorkspace({ name = id, spawn = { cwd = id } }), pane)
end

return action
