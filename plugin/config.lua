local helpers = require "table_helpers"

local function get_command(config)
    local command = {
        "fd",
        "-Hs",
        "^.git$",
        "-td",
        "--max-depth=" .. config.max_depth[1],
        "--prune",
        "--format",
        config.format[1],
    }

    if config.include_submodules[1] then
        command[#command + 1] = "-tf"
    end

    for _, v in ipairs(config.exclude) do
        command[#command + 1] = "-E"
        command[#command + 1] = v -- v must be a string
    end

    return command
end

local config = {}

config.default_config = {
    paths = {},
    title = { "Sessionzer" },
    show_default = { true },
    show_most_recent = { true },
    fuzzy = { true },
    additional_directories = {},
    show_additional_before_paths = { false },
    command_options = {
        include_submodules = { false },
        max_depth = { 16 },
        format = { "{//}" },
        exclude = { "node_modules" }
    },
    experimental_branches = { false },
}

config.get_effective_config = function(user_config)
    local merged = helpers.shallow_copy(config.default_config)
    helpers.merge_tables(merged, user_config)
    if merged.command then return merged end

    local command = get_command(merged.command_options)
    merged.command = command

    return merged
end

return config
