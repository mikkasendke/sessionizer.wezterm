local wezterm = require "wezterm"

local history = {}

history.get_most_recent_workspace = function()
    if not wezterm.GLOBAL.sessionzer or not wezterm.GLOBAL.sessionzer.most_recent_workspace then return nil end
    return wezterm.GLOBAL.sessionzer.most_recent_workspace
    -- return {
    --     name = most_recent_workspace_id,
    --     spawn = { cwd = most_recent_workspace_id }
    -- }
end

---@param workspace Entry
history.set_most_recent_workspace = function(workspace)
    if not wezterm.GLOBAL.sessionzer then
        wezterm.GLOBAL.sessionzer = {}
    end

    wezterm.GLOBAL.sessionzer.most_recent_workspace = {
        label = "Recent (" .. workspace.label .. ")",
        id = workspace.id,
    }
end


return history
