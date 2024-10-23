local wez = require "wezterm"

local config = require "sessionizer.config"
local helpers = require "sessionizer.table_helpers"

local function add_entry(cfg, entries, position, id, label)
    if cfg.experimental_branches then
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

local function apply_configured(current_entries, cfg)
    local custom_dirs = cfg.additional_directories
    if type(custom_dirs) == "string" then
        custom_dirs = { custom_dirs }
    end

    for _, dir in pairs(custom_dirs) do
        if cfg.show_additional_before_paths then
            add_entry(cfg, current_entries, 1, dir, dir)
        else
            add_entry(cfg, current_entries, #current_entries + 1, dir, dir)
        end
    end

    if cfg.show_most_recent and
        wez.GLOBAL.sessionzer and
        wez.GLOBAL.sessionzer.most_recent_workspace then
        table.insert(current_entries, 1, wez.GLOBAL.sessionzer.most_recent_workspace)
    end
    if cfg.show_default then
        table.insert(current_entries, 1, { id = "default", label = "Default", })
    end

    return current_entries
end

local function apply_commands(current_entries, cfg)
    local paths = cfg.paths
    if type(paths) == "string" then
        paths = { paths }
    end

    for _, dir in pairs(paths) do
        local command = helpers.shallow_copy(cfg.command)
        command[#command + 1] = dir

        local success, stdout, stderr = wez.run_child_process(command)
        if not success then
            wez.log_info("Sessionzer: error while running specified command: " .. stderr)
            goto continue
        end

        for path in stdout:gmatch "[^\n]+" do
            local id = path
            local label = path
            add_entry(cfg, current_entries, 1, id, label)
        end
        ::continue::
    end

    return current_entries
end

local entries = {}

entries.get_entries = function(cfg)
    return apply_configured(apply_commands({}, cfg), cfg)
end

return entries
