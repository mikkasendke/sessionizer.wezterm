local wez = require "wezterm"
local act = wez.action
local helpers = require "sessionizer.table_helpers"

local input_selector = {}

local function on_selection(cfg, window, pane, id, label)
    if not id then return end

    local current_workspace = wez.mux.get_active_workspace()
    if not cfg.experimental_branches then
        if current_workspace == id then return end
    end

    require "sessionizer.history".set_most_recent_workspace(current_workspace)

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

    --    window:perform_action(
    --       act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }),
    --      pane
    -- )
    local name = label:match("([^/]+)$")
    local function has_value(tab, val)
        for index, value in ipairs(tab) do
            if value == val then
                return true
            end
        end

        return false
    end
    if has_value(wez.mux.get_workspace_names(), name) then
        wez.mux.set_active_workspace(name)
        return
    end

    local tab, new_pane, window = wez.mux.spawn_window({ workspace = name, cwd = label })
    wez.mux.set_active_workspace(name)
    tab:set_title(name)

    new_pane:send_text("nvim .\n")

    local gui_window = window:gui_window()

    gui_window:perform_action(
        wez.action.SpawnCommandInNewTab({
            cwd = label,
        }),
        new_pane
    )
    local tab2 = window.spawn_tab { cwd = label }
    tab2:set_title("terminals")
    window:perform_action(wez.action.SplitHorizontal { domain = "CurrentPaneDomain" })


    gui_window:perform_action(wez.action.ActivateTab(1), new_pane)
end

input_selector.get = function(cfg, entries)
    return act.InputSelector {
        title = cfg.title,
        choices = entries,
        fuzzy = cfg.fuzzy,
        action = wez.action_callback(helpers.curry1of5(on_selection)(cfg)),
        description = cfg.description,
        fuzzy_description = cfg.description,
    }
end


return input_selector
