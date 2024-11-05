local wez = require "wezterm"
local helpers = require "sessionizer.table_helpers"
local generator = {}

-- TODO: figure out fd path but still allow setting
-- FIX: do before release

---@type FdOptions
local default_options = {
    "no path specified",
    fd_path = "fd",
    include_submodules = false,
    max_depth = 16,
    format = "{//}",
    exclude = { "node_modules" },
    extra_args = {}
}

---@param options FdOptionsPartial
---@return FdOptions
local function normalize_options(options)
    options = helpers.deep_copy(options)
    if type(options.exclude) == "string" then
        options.exclude = { options.exclude }
    end
    if type(options.extra_args) == "string" then
        options.extra_args = { options.exclude }
    end

    local merged = helpers.deep_copy(default_options)
    helpers.merge_tables(merged, options)

    return merged
end

---@param options FdOptions
---@return string[]
local function get_command(options)
    local command = {
        options.fd_path,
        "-Hs",
        "^.git$",
        "-td",
        "--max-depth=" .. options.max_depth,
        "--prune",
        "--format",
        options.format,
    }
    if options.include_submodules then
        command[#command + 1] = "-tf"
    end
    for _, v in ipairs(options.exclude) do
        command[#command + 1] = "-E"
        command[#command + 1] = v
    end

    command[#command + 1] = options[1]

    for _, v in ipairs(options.extra_args) do
        command[#command + 1] = v
    end

    return command
end

---@param command string[]
---@return Entry[]
local function get_results(command)
    ---@type Entry[]
    local result = {}

    ---@type boolean, string?, string?
    local success, stdout, stderr = wez.run_child_process(command)
    if not success then
        wez.log_error("Command failed: ", command)
        wez.log_error("stderr: ", stderr)
        return {}
    end

    if not stdout then
        wez.log_warn("stdout was nil in command: ", command)
        return {}
    end

    for line in stdout:gmatch "[^\n]+" do
        ---@type Entry
        local entry = require "sessionizer.entries".make_entry(line, line)
        table.insert(result, entry)
    end

    return result
end

---@param options FdGeneratorFuncArgs
---@return Entry[]
generator.search = function(options)
    if type(options) == "string" then
        options = { options }
    end
    local normalized_options = normalize_options(options)
    local command = get_command(normalized_options)
    return get_results(command)
end

---@param opts FdGeneratorFuncArgs
---@return GeneratorFunction
generator.FdSearch = function(opts)
    ---@type GeneratorFunction -- TODO: check why without this it is function|GeneratorFunction
    return function()
        local entries = generator.search(opts)
        return entries
    end
end


return generator