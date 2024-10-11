-- NOTE: First we add our path to the package.path because we want to do requires easily
package.path = package.path .. ";" .. (select(2, ...):gsub("init.lua$", "?.lua"))

local wez = require "wezterm"
local act = wez.action
local config = require "sessionizer.config"
local history = require "sessionizer.history"

local plugin = {}

plugin.config = { command_options = { exclude = {}, }, } -- NOTE: unfortunetly necessary for now

plugin.apply_to_config = function(user_config, disable_default_binds)
    require "sessionizer.bindings".apply_binds(plugin, user_config, disable_default_binds)
end

local show_identifier = "sessionizer.show"
plugin.show = act.EmitEvent(show_identifier)
wez.on(show_identifier, function(window, pane)
    local cfg = config.get_effective_config(plugin.config)
    local entries = require "sessionizer.entries".get_entries(cfg)

    plugin.display_entries(entries, window, pane)
end)

---@param entries { id: string, label: string }
plugin.display_entries = function(entries, window, pane)
    local cfg = config.get_effective_config(plugin.config)
    window:perform_action(require "sessionizer.input_selector".get(cfg, entries), pane)
end

local show_most_recent_identifier = "sessionizer.switch-to-most-recent"
plugin.switch_to_most_recent = act.EmitEvent(show_most_recent_identifier)
wez.on(show_most_recent_identifier, function(window, pane)
    local previous_workspace = wez.mux.get_active_workspace()
    window:perform_action(act.SwitchToWorkspace(
        history.get_most_recent_workspace()
    ), pane)
    history.set_most_recent_workspace(previous_workspace)
end)

return plugin
