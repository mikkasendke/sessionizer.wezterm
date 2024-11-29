local wezterm = require "wezterm"
local generator = {}

-- TODO: Add option to attach (Current) to current workspace
local default_options = {
    filter_default = true,
    filter_current = true,
}

local function get_all_active_workspaces(options)
    local merged = require "sessionizer.table_helpers".deep_copy(default_options)
    require "sessionizer.table_helpers".merge_tables(
        merged,
        options
    )
    options = merged

    local workspaces = {}
    local current = wezterm.mux.get_active_workspace()
    local all = wezterm.mux.get_workspace_names()
    for _, v in ipairs(all) do
        if options.filter_current and v == current then goto continue end
        if options.filter_default and v == "default" then goto continue end
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
