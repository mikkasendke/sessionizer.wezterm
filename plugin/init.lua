local wez = require "wezterm"
local act = wez.action

local plugin = {}
plugin.config = { command_options = { exclude = {}, }, }


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


local function make_default_command(options)
    local command = {
        "fd",
        "-Hs",
        "^.git$",
        "-td",
        "--max-depth=" .. options.max_depth,
        "--prune",
        "--format",
        options.format,
    }
    if options.include_submodules then
        command[#command + 1] = "-tf"
    end
    if type(options.exclude) == "string" then
        options.exclude = { options.exclude }
    end

    for _, v in pairs(options.exclude) do
        command[#command + 1] = "-E"
        command[#command + 1] = v
    end

    return command
end

local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k] or false) == "table" then
            merge_tables(t1[k] or {}, t2[k] or {})
            goto continue
        end
        t1[k] = v
        ::continue::
    end
end

local function get_effective_config(config)
    local defaults = {
        paths = {},
        title = "Sessionzer",
        show_default = true,
        show_most_recent = true,
        fuzzy = true,
        additional_directories = {},
        show_additional_before_paths = false,
        command_options = {
            include_submodules = false,
            max_depth = 16,
            format = "{//}",
            exclude = { "node_modules" }
        },
        experimental_branches = false,
    }
    -- for k, v in pairs(config) do
    --     defaults[k] = v
    -- end

    merge_tables(defaults, config)

    if not defaults.command then
        defaults.command = make_default_command(defaults.command_options)
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

local function add_entry(entries, position, id, label)
    local config = get_effective_config(plugin.config)
    if config.experimental_branches then
        local list_branches_command = {
            "git",
            "-C",
            id,
            "-c",
            "pager.branch=false",
            "branch",
            "-l",
            "--format=%(refname:short)",
        }
        local success, stdout, _ = wez.run_child_process(list_branches_command)
        if not success then
            wez.log_info("Sessionzer: Could not list git repositories.")
        end

        for branch in stdout:gmatch "[^\n]+" do
            wez.log_info(branch)
            table.insert(entries, position, {
                id = id,
                label = label .. " " .. branch,
            })
        end
    end
    table.insert(entries, position, { id = id, label = label, })
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
            goto continue
        end

        for path in stdout:gmatch "[^\n]+" do
            local id = path
            local label = path
            add_entry(entries, 1, id, label)
        end
        ::continue::
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
            add_entry(entries, 1, dir, dir)
        else
            add_entry(entries, #entries + 1, dir, dir)
        end
    end

    if config.show_most_recent and
        wez.GLOBAL.sessionzer and
        wez.GLOBAL.sessionzer.most_recent_workspace then
        add_entry(entries, 1, wez.GLOBAL.sessionzer.most_recent_workspace.id,
            wez.GLOBAL.sessionzer.most_recent_workspace.label)
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
        action = wez.action_callback(function(window, pane, id, label)
            if not id then return end

            local current_workspace = wez.mux.get_active_workspace()
            if not config.experimental_branches then
                if current_workspace == id then return end
            end

            set_most_recent_workspace(current_workspace)

            if config.experimental_branches then
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
