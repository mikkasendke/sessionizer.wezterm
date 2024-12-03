local wezterm = require "wezterm"

local generator = {}

generator.Zoxide = function()
    local res = {}
    local success, stdout, stderr = wezterm.run_child_process {
        "zoxide",
        "query",
        "-l",
    }
    for line in stdout:gmatch "[^\n]+" do
        table.insert(res, require "sessionizer.entries".make_entry(line, line))
    end
    return res
end

return generator
