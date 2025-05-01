local wezterm = require "wezterm"
local helpers = require "sessionizer.helpers"

local generator = {}

local fd_path = nil
local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"

---@return string|nil
local function get_fd_path_auto()
    local command = {}
    if is_windows then
        command[#command + 1] = "where.exe"
    else
        command[#command + 1] = "which"
    end
    command[#command + 1] = "fd"

    -- TODO: make error handling better (honestly for all run_child_process, I think they can panic)
    local success, stdout, stderr = wezterm.run_child_process(command)
    if not success then
        wezterm.log_error("sessionizer.wezterm: failed to run command to find fd binary; command: ", command)
        return
    end

    return stdout:gsub("\n$", "")
end

local function normalize_options(opts)
    local default_options = {
        "no_path_specified",
        fd_path = fd_path,
        include_submodules = false,
        max_depth = 16,
        format = "{//}",
        exclude = { "node_modules" },
        extra_args = {},
    }

    if not default_options.fd_path then
        default_options.fd_path = get_fd_path_auto() or "fd_not_found"
    end

    helpers.merge_tables(default_options, opts)
    return default_options
end

local function get_command(opts)
    local command = {
        opts.fd_path,
        "-Hs",
        "^.git$",
        "-td",
        "--max-depth=" .. opts.max_depth,
        "--prune",
        "--format",
        opts.format,
    }
    if opts.include_submodules then
        command[#command + 1] = "-tf"
    end
    for _, v in ipairs(opts.exclude) do
        command[#command + 1] = "-E"
        command[#command + 1] = v
    end

    command[#command + 1] = opts[1]

    for _, v in ipairs(opts.extra_args) do
        command[#command + 1] = v
    end

    return command
end

local function get_results(command)
    local result = {}

    ---@type boolean, string?, string?
    local success, stdout, stderr = wezterm.run_child_process(command)
    if not success then
        wezterm.log_error("Command failed: ", command)
        wezterm.log_error("stderr: ", stderr)
        return {}
    end

    if not stdout then
        wezterm.log_warn("stdout was nil in command: ", command)
        return {}
    end

    for line in stdout:gmatch "[^\n]+" do
        local entry = { label = line, id = line }
        table.insert(result, entry)
    end

    return result
end


local function find(opts)
    if type(opts) == "string" then
        opts = { opts }
    end

    local normalized_options = normalize_options(opts)
    local command = get_command(normalized_options)

    return get_results(command)
end

generator.FdSearch = function(opts)
    return function()
        local entries = find(opts)
        return entries
    end
end


return generator
