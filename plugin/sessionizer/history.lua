local wezterm = require "wezterm"

-- HACK: this right now does not work with integer indexing therefore no stack here
local history = {}

history.push = function(value)
    if not wezterm.GLOBAL.sessionzer then
        wezterm.GLOBAL.sessionzer = {}
    end
    if not wezterm.GLOBAL.sessionzer.history then
        wezterm.GLOBAL.sessionzer.history = {}
    end
    wezterm.GLOBAL.sessionzer.history["recent"] = {
        label = value,
        id = value,
    }
end

---@return Entry | nil
history.peek = function()
    if not wezterm.GLOBAL.sessionzer
        or not wezterm.GLOBAL.sessionzer.history
    -- or #wezterm.GLOBAL.sessionzer.history == 0
    then
        return nil
    end
    -- return wezterm.GLOBAL.sessionzer.history[#wezterm.GLOBAL.sessionzer.history]
    return wezterm.GLOBAL.sessionzer.history["recent"]
end

---@return Entry | nil
history.pop = function()
    if true then return history.peek() end -- HACK: as above
    if not wezterm.GLOBAL.sessionzer
        or not wezterm.GLOBAL.sessionzer.history
    -- or #wezterm.GLOBAL.sessionzer.history == 0
    then
        return nil
    end
    return table.remove(wezterm.GLOBAL.sessionzer.history, #wezterm.GLOBAL.sessionzer.history)
end

return history
