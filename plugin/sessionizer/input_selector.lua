local wezterm = require "wezterm"
local act = wezterm.action

local input_selector = {}

-- TODO: on_selection injecible per entry and maybe a chain like the processors

---@param window unknown
---@param pane unknown
---@param id string?
---@param label string
input_selector.on_selection_switch_workspace = function(window, pane, id, label)
    if not id then return end

    local current_workspace = wezterm.mux.get_active_workspace()

    -- require "sessionizer.history".set_most_recent_workspace({ label = label, id = id })
    require "sessionizer.history".set_most_recent_workspace({ label = current_workspace, id = current_workspace })

    window:perform_action(
        act.SwitchToWorkspace({ name = id, spawn = { cwd = id } }),
        pane
    )
end

---@param options SpecOptions
---@param entries Entry[]
input_selector.get = function(options, entries)
    return act.InputSelector {
        title = options.title,
        choices = entries,
        fuzzy = options.always_fuzzy,
        action = wez.action_callback(options.callback),
        description = options.description,
        fuzzy_description = options.description,
    }
end


return input_selector
