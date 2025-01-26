local wezterm = require "wezterm"

local input_selector = {}

---@param options SpecOptions
---@param entries Entry[]
input_selector.get = function(options, entries)
    return wezterm.action.InputSelector {
        title = options.title,
        choices = entries,
        fuzzy = options.always_fuzzy,
        action = wezterm.action_callback(options.callback),
        description = options.description,
        fuzzy_description = options.description,
    }
end

return input_selector
