local helpers = {}

---@param f fun(entry: Entry)
helpers.for_each_entry = function(f)
    return function(entries)
        for _, entry in pairs(entries) do
            f(entry)
        end
    end
end

helpers.table_utils = require "sessionizer.helpers.table_utils"

return helpers
