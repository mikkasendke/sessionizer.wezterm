local wez = require "wezterm"
local generator = {}

local default_options = {
    show_current_workspace = true,
    show_default_workspace = true,
}

local function get_all_active_workspaces(options)
    local merged = require "sessionizer.table_helpers".deep_copy(default_options)
    require "sessionizer.table_helpers".merge_tables(
        merged,
        options
    )
    options = merged

    local workspaces = {}
    local current = wez.mux.get_active_workspace()
    local all = wez.mux.get_workspace_names()
    for i, v in ipairs(all) do
        if not options.show_current_workspace and v == current then goto continue end
        if not options.show_default_workspace then goto continue end
        table.insert(workspaces, { label = v, id = v })
        ::continue::
    end
    return workspaces
end

generator.AllActiveWorkspaces = function(opts)
    return function() -- NOTE: needed if we have options
        return get_all_active_workspaces(opts)
    end
end

return generator
