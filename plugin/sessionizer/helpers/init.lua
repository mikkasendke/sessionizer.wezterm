local actions = require "sessionizer.actions.init"

local helpers = {}

---@param f fun(entry: Entry)
helpers.for_each_entry = function(f)
    return function(entries)
        for _, entry in pairs(entries) do
            f(entry)
        end
    end
end

---@param partial_options SpecOptionsPartial
---@return SpecOptions
helpers.normalize_options = function(partial_options)
    local defaults = {
        title = "Sessionzer",
        description = "Select a workspace: ",
        always_fuzzy = true,
        callback = actions.SwitchToWorkspace,
    }

    helpers.table_utils.merge_tables(defaults, partial_options)
    return defaults
end

helpers.table_utils = require "sessionizer.helpers.table_utils"

return helpers
