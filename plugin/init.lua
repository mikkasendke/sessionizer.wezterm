local wez = require "wezterm"
local act = wez.action

-- NOTE: First we add our path to the package.path because we want to do requires easily
package.path = package.path .. ";" .. (select(2, ...):gsub("init.lua$", "?.lua"))

local config = require "sessionizer.config"
local history = require "sessionizer.history"


local plugin = {}

plugin.config = { command_options = { exclude = {}, }, } -- NOTE: unfortunetly necessary for now

plugin.apply_to_config = function(user_config, disable_default_binds)
    require "sessionizer.bindings".apply_binds(plugin, user_config, disable_default_binds) -- FIX: This does mutate args which is kinda bad
end

plugin.show = wez.action_callback(function(window, pane)
    local cfg = config.get_effective_config(plugin.config)
    local entries = require "sessionizer.entries".get_entries(cfg)

    window:perform_action(require "sessionizer.input_selector".get(cfg, entries), pane)
end)

plugin.switch_to_most_recent = wez.action_callback(function(window, pane)
    local previous_workspace = wez.mux.get_active_workspace()
    window:perform_action(act.SwitchToWorkspace(
        history.get_most_recent_workspace()
    ), pane)
    history.set_most_recent_workspace(previous_workspace)
end)

return plugin
