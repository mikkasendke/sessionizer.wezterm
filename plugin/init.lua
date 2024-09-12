local wez = require "wezterm"
local act = wez.action

local function get_plugin_dir()
    for _, plugin in ipairs(wez.plugin.list()) do
        if plugin.url:find "mikkasendke/sessionizer.wezterm" then return plugin.plugin_dir end
    end
    return false
end

local plugin_dir = get_plugin_dir()

local path_separator = package.config:sub(1, 1) == "\\" and "\\" or "/"
package.path = package.path
    .. ";"
    .. plugin_dir
    .. path_separator
    .. "plugin"
    .. path_separator
    .. "?.lua"

local config = require "config"


local function set_most_recent_workspace(current_workspace)
    if not wez.GLOBAL.sessionzer then
        wez.GLOBAL.sessionzer = {}
    end
    wez.GLOBAL.sessionzer.most_recent_workspace = {
        id = current_workspace,
        label = "Recent (" .. current_workspace .. ")",
    }
end

local plugin = {}
plugin.config = { command_options = { exclude = {}, }, }

local function on_selection(window, pane, id, label)
    if not id then return end
    local cfg = config.get_effective_config(plugin.config)

    local current_workspace = wez.mux.get_active_workspace()
    if not cfg.experimental_branches then
        if current_workspace == id then return end
    end

    set_most_recent_workspace(current_workspace)

    if cfg.experimental_branches then
        local count = 1
        local goto_branch = ""
        for el in label:gmatch "%S+" do
            wez.log_info("count: " .. count .. "; element: " .. el)
            if count == 2 then
                goto_branch = el
            end
            count = count + 1
        end

        local cmd = {
            "git",
            "-C",
            id,
            "switch",
            goto_branch,
        }

        wez.log_info "running:"
        wez.log_info(cmd)
        local success, stdout, _ = wez.run_child_process(cmd)
    end

    window:perform_action(
        act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }),
        pane
    )
end

local function make_input_selector(entries)
    local cfg = config.get_effective_config(plugin.config)
    return act.InputSelector {
        title = cfg.title,
        choices = entries,
        fuzzy = cfg.fuzzy,
        action = wez.action_callback(on_selection)
    }
end

plugin.apply_to_config = function(user_config, disable_default_binds)
    require "bindings".apply_binds(plugin, user_config, disable_default_binds)
end

plugin.show = wez.action_callback(function(window, pane)
    local entries = require "entries".get_entries(plugin.config)
    local input_selector = make_input_selector(entries)
    window:perform_action(input_selector, pane)
end)

plugin.switch_to_most_recent = wez.action_callback(function(window, pane)
    if not wez.GLOBAL.sessionzer or not wez.GLOBAL.sessionzer.most_recent_workspace then return end

    local most_recent_workspace_id = wez.GLOBAL.sessionzer.most_recent_workspace.id
    set_most_recent_workspace(wez.mux.get_active_workspace())
    window:perform_action(
        act.SwitchToWorkspace({
            name = most_recent_workspace_id,
            spawn = { cwd = most_recent_workspace_id }
        }),
        pane
    )
end)

return plugin
