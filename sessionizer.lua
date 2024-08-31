local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

local fd_cmd = "fd"

local project_path_trimming_strategies = {
    none = 0,
    home = 1,
    just_project = 2,
}

local project_path_trimming_strategy = project_path_trimming_strategies.none

local custom_entries_at_top = false

local home_dir = os.getenv("HOME")
if not home_dir then
    wezterm.log_error("HOME is not set")
end

-- The root path to search for projects
local project_root_path = home_dir .. ("/dev/")

local base_projects = {}
table.insert(base_projects, { label = "Default", id = "default" })

local function add_entry(label, path)
    table.insert(base_projects, { label = label, id = path })
end

local function add_path(path)
    table.insert(base_projects, { label = path, id = path })
end


-- Add some custom paths
local config_path = home_dir .. ("/.config")
add_path(config_path)
add_path(config_path .. "/wezterm")
add_path(config_path .. "/nvim")
add_path(config_path .. "/sway")
add_path(config_path .. "/waybar")

module.toggle = function(window, pane)
    local currentWorkspace = wezterm.mux.get_active_workspace()

    local projects = {}
    table.append_table(projects, base_projects)

    local content = wezterm.GLOBAL.most_recent_workspace
    if content then
        table.insert(projects, 2, { label = "Recent (" .. content .. ")", id = content })
    end

   local success, stdout, stderr = wezterm.run_child_process({
        fd_cmd,
        "-HI",
        "-td",
        "^.git$",
        "--max-depth=16",
        "--prune",
        project_root_path,
    })

    if not success then
        wezterm.log_error("Failed to run fd: " .. stderr)
        return
    end

    for line in stdout:gmatch("([^\n]*)\n?") do
        local project_path = line:sub(1, - #"/.git/" - 1)

        local id = project_path
        local label = project_path

        if project_path_trimming_strategy == project_path_trimming_strategies.none then
        elseif project_path_trimming_strategy == project_path_trimming_strategies.home then
            label = project_path:sub(#home_dir + 1)
        elseif project_path_trimming_strategy == project_path_trimming_strategies.just_project then
            label = project_path:gsub(".*/", "")
        else
            wezterm.log_error("Tried using unknown trim_path_strategy: " .. project_path_trimming_strategy)
        end

        if project_path ~= "" then
            if custom_entries_at_top then
                table.insert(projects, { label = label, id = id })
            else
                local insert_id = (wezterm.GLOBAL.most_recent_workspace and 3 or 2)
                table.insert(projects, insert_id, { label = label, id = id })
            end
        end
    end


    wezterm.log_info(projects);
    window:perform_action(
        act.InputSelector({
            action = wezterm.action_callback(function(win, _, id, label)
                if not id and not label then
                    wezterm.log_info("Cancelled")
                else
                    wezterm.log_info("Selected " .. label)
                    if currentWorkspace == id then
                        wezterm.log_info("Already in workspace " .. id)
                        return
                    end
                    wezterm.log_info("Setting most_recent_workspace to " .. currentWorkspace)
                    wezterm.GLOBAL.most_recent_workspace = currentWorkspace
                    win:perform_action(
                        act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }),
                        pane
                    )
                end
            end),
            fuzzy = true,
            title = "Select project",
            choices = projects,
        }),
        pane
    )
end

module.goto_most_recent = function(window, pane)
    if not wezterm.GLOBAL.most_recent_workspace then
        return
    end
    local currentWorkspace = wezterm.mux.get_active_workspace()
    window:perform_action(
        act.SwitchToWorkspace({
            name = wezterm.GLOBAL.most_recent_workspace,
            spawn = { cwd = wezterm.GLOBAL.most_recent_workspace },
        }),
        pane
    )
    wezterm.GLOBAL.most_recent_workspace = currentWorkspace
end

function table.append_table(t1, t2)
    for i = 1, #t2 do
        table.insert(t1, t2[i])
    end
    return t1
end

return module
