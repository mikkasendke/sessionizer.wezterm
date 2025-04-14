local wezterm = require "wezterm"
local helpers = require "sessionizer.helpers"

local generator = {}

local function find(opts)
    local default_options = {
        filter_default = true,
        filter_current = true,
    }

    helpers.merge_tables(default_options, opts)
    opts = default_options

    local entries = {}

    local current = nil
    if opts.filter_default then
        current = wezterm.mux.get_active_workspace()
    end

    local all_workspaces = wezterm.mux.get_workspace_names()
    for _, v in ipairs(all_workspaces) do
        if opts.filter_current and v == current then goto continue end
        if opts.filter_default and v == "default" then goto continue end

        table.insert(entries, { label = v, id = v })
        ::continue::
    end
    return entries
end

generator.AllActiveWorkspaces = function(opts)
    return function()
        return find(opts)
    end
end

return generator
