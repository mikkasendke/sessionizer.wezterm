local M = {}

---@param sessionizer LegacySessionizer
---@return Spec
M.convert_to_spec = function(sessionizer)
    ---@type Spec
    local spec = {}

    if sessionizer.config then
        ---@type LegacyConfig
        local config = sessionizer.config

        ---@type SpecOptions
        local options = {}

        options.title = config.title or "Sessionzer"
        options.description = config.description or "Select a workspace: "
        options.always_fuzzy = config.fuzzy == nil and true or
            config
            .fuzzy                                                                                  -- NOTE: here the second config.fuzzy can not be nil
        options.show_default_workspace = config.show_default == nil and true or config.show_default -- TODO: FIX THAT
        options.show_most_recent_workspace = config.show_most_recent == nil and true or config.show_most_recent

        spec.options = options

        ---@type FdOptions
        local fd_options = {}
        fd_options.fd_path = config.command_options and config.command_options.fd_path or "fd"
        fd_options.include_submodules = config.command_options and config.command_options.include_submodules or false
        fd_options.max_depth = config.command_options and config.command_options.max_depth or 16
        fd_options.format = config.command_options and config.command_options.format or "{//}"
        fd_options.exclude = config.command_options and config.command_options.exclude or { "node_modules" }
        fd_options.overwrite = config.command

        if config.paths then
            for _, v in pairs(config.paths) do
                local opts = require "sessionizer.table_helpers".deep_copy(fd_options)
                opts[1] = v
                local f = require "sessionizer.generators.fd".FdSearch(opts)
                table.insert(spec, f)
            end
        end
        if config.additional_directories then
            if config.show_additional_before_paths then
                for _, v in pairs(config.additional_directories) do
                    table.insert(spec, 1, v)
                end
            else
                for _, v in pairs(config.additional_directories) do
                    table.insert(spec, v)
                end
            end
        end
    end
    local processors = {}
    for _, v in pairs(sessionizer.entry_processors) do
        table.insert(processors, v)
    end
    spec.processors = processors
    return spec
end

return M
