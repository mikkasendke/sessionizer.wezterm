local helpers = require "sessionizer.helpers.init"

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
    local options = helpers.table_utils.shallow_copy(defaults)

    helpers.table_utils.merge_tables(
        options,
        opts
    )

    ---@type GeneratorFunction
    return function()
        return { { label = "Default", id = options.name_overwrite } }
    end
end

return generator
