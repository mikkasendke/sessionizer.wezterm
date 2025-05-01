local wezterm = require "wezterm"

local input_selector = {}

---@param options SchemaOptions
---@param choices Entry[]
---@return unknown
input_selector.get_input_selector = function(options, choices)
    return wezterm.action.InputSelector {
        title = options.title,
        description = options.prompt,
        fuzzy_description = options.prompt,
        fuzzy = options.always_fuzzy,
        choices = choices,
        action = wezterm.action_callback(options.callback),
    }
end

return input_selector
