local wezterm = require "wezterm"

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.apply_to_config(config, true) -- disable default binds (right now you can also just not call this)

config.keys = {
    {
        key = "w",
        mods = "ALT|SHIFT",
        action = sessionizer.show,
    },
    {
        key = "r",
        mods = "ALT|SHIFT",
        action = sessionizer.show,
    },
}

return config
