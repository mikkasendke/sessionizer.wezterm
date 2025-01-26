-- INFO: do not confuse these with wezterm.action (for now this is the name)
local actions = {}

actions.SwitchToWorkspace = require "sessionizer.actions.switch_to_workspace".SwitchToWorkspace

return actions
