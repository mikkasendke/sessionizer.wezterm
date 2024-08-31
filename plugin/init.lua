local wez = require "wezterm"
local act = wez.action

local plugin = {}
plugin.config = {
    paths = {},
    command = {
        "fd",
        "-HI",
        "-td",
        "^.git$",
        "--max-depth=16",
        "--prune",
        "--format",
        "{//}"
    },
    title = "Sessionzer",
    show_default = true,
    show_most_recent = true,
    fuzzy = true,
    additional_directories = {},
    show_additional_before_paths = false,
}


local function add_bind(config, bind)
    config.keys[#config.keys + 1] = bind
end

plugin.apply_to_config = function(config, disable_default_binds)
    if config.keys == nil then
        config.keys = {}
    end

    if not disable_default_binds then
        add_bind(config, {
            key = "s",
            mods = "ALT",
            action = plugin.show
        })
        add_bind(config, {
            key = "m",
            mods = "ALT",
            action = plugin.switch_to_most_recent
        })
    end
end

local function get_effective_config(config)
    local defaults = {
        paths = {},
        command = {
            "fd",
            "-HI",
            "-td",
            "^.git$",
            "--max-depth=16",
            "--prune",
            "--format",
            "{//}"
        },
        title = "Sessionzer",
        show_default = true,
        show_most_recent = true,
        fuzzy = true,
        additional_directories = {},
        show_additional_before_paths = false,
    }
    for k, v in pairs(config) do
        defaults[k] = v
    end
    return defaults
end

local function shallow_copy(t)
    local dest = {}
    for k, v in pairs(t) do
        dest[k] = v
    end
    return dest
end

local function apply_commands(entries)
    local config = get_effective_config(plugin.config)
    local paths = config.paths
    if type(paths) == "string" then
        paths = { paths }
    end

    for _, dir in pairs(paths) do
        local command = shallow_copy(config.command)
        command[#command + 1] = dir

        local success, stdout, _ = wez.run_child_process(command)
        if not success then
            wez.log_info("Sessionzer: error while running specified command.")
            return
        end

        for path in stdout:gmatch "[^\n]+" do
            local id = path
            local label = path
            table.insert(entries, { id = id, label = label })
        end
    end
    return entries
end

local function apply_configured(entries)
    local config = get_effective_config(plugin.config)

    local custom_dirs = config.additional_directories
    if type(custom_dirs) == "string" then
        custom_dirs = { custom_dirs }
    end

    for _, dir in pairs(custom_dirs) do
        if config.show_additional_before_paths then
            table.insert(entries, 1, { id = dir, label = dir, })
        else
            table.insert(entries, #entries + 1, { id = dir, label = dir, })
        end
    end

    if config.show_most_recent and
        wez.GLOBAL.sessionzer and
        wez.GLOBAL.sessionzer.most_recent_workspace then
        table.insert(entries, 1, wez.GLOBAL.sessionzer.most_recent_workspace)
    end
    if config.show_default then
        table.insert(entries, 1, { id = "default", label = "Default", })
    end
    return entries
end

local function get_entries()
    return apply_configured(apply_commands({})) -- this function is basically only for readability
end

local function set_most_recent_workspace(current_workspace)
    if not wez.GLOBAL.sessionzer then
        wez.GLOBAL.sessionzer = {}
    end
    wez.GLOBAL.sessionzer.most_recent_workspace = {
        id = current_workspace,
        label = "Recent (" .. current_workspace .. ")",
    }
end

local function make_input_selector(entries)
    local config = get_effective_config(plugin.config)
    return act.InputSelector {
        title = config.title,
        choices = entries,
        fuzzy = config.fuzzy,
        action = wez.action_callback(function(window, pane, id, _)
            if not id then return end

            local current_workspace = wez.mux.get_active_workspace()
            if current_workspace == id then return end

            set_most_recent_workspace(current_workspace)
            window:perform_action(
                act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }),
                pane
            )
        end)
    }
end

plugin.show = wez.action_callback(function(window, pane)
    local entries = get_entries()
    window:perform_action(make_input_selector(entries), pane)
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
