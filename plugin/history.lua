local wez = require "wezterm"

local history = {}

history.get_most_recent_workspace = function()
    if not wez.GLOBAL.sessionzer or not wez.GLOBAL.sessionzer.most_recent_workspace then return nil end

    local most_recent_workspace_id = wez.GLOBAL.sessionzer.most_recent_workspace.id
    return {
        name = most_recent_workspace_id,
        spawn = { cwd = most_recent_workspace_id }
    }
end

history.set_most_recent_workspace = function(workspace)
    if not wez.GLOBAL.sessionzer then
        wez.GLOBAL.sessionzer = {}
    end

    wez.GLOBAL.sessionzer.most_recent_workspace = {
        id = workspace,
        label = "Recent (" .. workspace .. ")",
    }
end


return history
