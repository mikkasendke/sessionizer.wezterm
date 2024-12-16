local generator = {}

---@class DefaultWorkspaceOptions
---@field name_overwrite string
---
---@class DefaultWorkspaceOptionsPartial
---@field name_overwrite string?


---@type DefaultWorkspaceOptions
local defaults = {
    name_overwrite = "default"
}

---@param opts DefaultWorkspaceOptionsPartial
---@return GeneratorFunction
generator.DefaultWorkspace = function(opts)
    ---@type DefaultWorkspaceOptions
    local options = require "sessionizer.table_helpers".shallow_copy(defaults)

    require "sessionizer.table_helpers".merge_tables(
        options,
        opts
    )

    return function()
        return { { label = "Default", id = options.name_overwrite } }
    end
end

return generator
