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
    local entries = plugin.get_entries()

    local i = 1
    local function next()
        local processor = plugin.entry_processors[i]
        i = i + 1
        if processor then
            processor(entries, next)
        end
    end
    next()

    plugin.display_entries(entries, window, pane)
end)

plugin.get_entries = function()
    local cfg = config.get_effective_config(plugin.config)
    return require "sessionizer.entries".get_entries(cfg)
end

plugin.entry_processors = {}
plugin.use_entry_processor = function(f)
    table.insert(plugin.entry_processors, f)
end

local show_active = "sessionizer.show-active"
plugin.show_active = act.EmitEvent(show_active)
wez.on(show_active, function(window, pane)
    local active_workspaces = {}
    local current = wez.mux.get_active_workspace()
    for index, item in ipairs(wez.mux.get_workspace_names()) do
        local label = item
        if item == current then
            label = label .. " (Current)"
        end
        table.insert(active_workspaces, index, { id = item, label = label })
    end
    plugin.display_entries(active_workspaces, window, pane)
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
