local wez = require "wezterm"

local history = {}

history.get_most_recent_workspace = function()
    if not wez.GLOBAL.sessionzer or not wez.GLOBAL.sessionzer.most_recent_workspace then return nil end
    return wez.GLOBAL.sessionzer.most_recent_workspace
    -- return {
    --     name = most_recent_workspace_id,
    --     spawn = { cwd = most_recent_workspace_id }
    -- }
end

---@param workspace Entry
history.set_most_recent_workspace = function(workspace)
    if not wez.GLOBAL.sessionzer then
        wez.GLOBAL.sessionzer = {}
    end

    wez.GLOBAL.sessionzer.most_recent_workspace = {
        label = "Recent (" .. workspace.label .. ")",
        id = workspace.id,
    }
end


return history
