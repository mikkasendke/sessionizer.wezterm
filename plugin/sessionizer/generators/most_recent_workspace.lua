local history = require "sessionizer.history"

local generator = {}

generator.MostRecentWorkspace = function()
    return function()
        return { history.peek() }
    end
end

return generator
