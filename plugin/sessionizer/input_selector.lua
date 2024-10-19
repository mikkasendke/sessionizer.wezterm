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

    window:perform_action(
        act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }),
        pane
    )
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
