local helpers = require "sessionizer.helpers"

local generator = {}

local function find(opts)
    local default_options = {
        id_overwrite = "default",
        label_overwrite = "Default",
    }

    helpers.merge_tables(default_options, opts)
    opts = default_options

    return { { label = opts.label_overwrite, id = opts.id_overwrite } }
end

generator.DefaultWorkspace = function(opts)
    return function()
        return find(opts)
    end
end

return generator
