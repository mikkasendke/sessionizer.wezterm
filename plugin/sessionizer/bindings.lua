local function add_bind(config, bind)
    config.keys[#config.keys + 1] = bind
end

local bindings = {}

bindings.apply_binds = function(plugin, config)
    config.keys = config.keys or {}

    add_bind(config, {
        key = "s",
        mods = "ALT",
        action = plugin.show()
    })
    add_bind(config, {
        key = "m",
        mods = "ALT",
        action = plugin.switch_to_most_recent
    })
end

return bindings
