local helpers = require "sessionizer.table_helpers"

local function get_command(command_options)
    local command = {
        command_options.fd_path,
        "-Hs",
        "^.git$",
        "-td",
        "--max-depth=" .. command_options.max_depth,
        "--prune",
        "--format",
        command_options.format,
    }

    if command_options.include_submodules then
        command[#command + 1] = "-tf"
    end

    if type(command_options.exclude) == "string" then
        command_options.exclude = { command_options.exclude }
    end

    for _, v in ipairs(command_options.exclude) do
        command[#command + 1] = "-E"
        command[#command + 1] = v -- v must be a string
    end

    return command
end

local config = {}

config.default_config = {
    paths = {},
    title = "Sessionzer",
    show_default = true,
    show_most_recent = true,
    fuzzy = true,
    additional_directories = {},
    show_additional_before_paths = false,
    description = "Select a workspace: ",
    command_options = {
        fd_path = "fd",
        include_submodules = false,
        max_depth = 16,
        format = "{//}",
        exclude = { "node_modules" }
    },
    experimental_branches = false,
}

---@return LegacyConfig
config.get_effective_config = function(user_config)
    -- require "wezterm".log_info("User: ", user_config)
    local merged = helpers.shallow_copy(config.default_config)
    helpers.merge_tables(merged, user_config)
    if merged.command then return merged end

    local command = get_command(merged.command_options)
    merged.command = command

    return merged
end

return config
