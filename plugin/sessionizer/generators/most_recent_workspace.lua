local history = require "sessionizer.history"

local generator = {}

generator.MostRecentWorkspace = function()
    return function()
        return { history.get_most_recent_workspace() }
    end
end

return generator
