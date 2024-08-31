# sessionizer.wezterm
Simple sessionizer for wezterm inspired by a discussion started by @keturiosakys at https://github.com/wez/wezterm/discussions/4796 and originally inspired by ThePrimeagen's tmux-sessionizer.

## Requirements
To use the default command `fd` is required

## Usage
To install `sessionizer.wezterm` just add the following two lines to your wezterm.lua
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.apply_to_config(config)
```

This will enable the following key binds:
 * `ALT+s` show the sessionizer
 * `ALT+m` switch to the most recently selected workspace

Now you need to at least add the path(s) you want the sessionizer to operate on. You can do this
by adding your path(s) to `sessionizer.config` like so
```lua
sessionizer.config = {
    paths = "/path/to/my/directory" -- this could for example be "/home/<your_username>/dev"
}

-- you can also list multiple paths
sessionizer.config = {
    paths = {
        "/this/is/path/one",
        "/this/is/another/path",
    }
}
```
The config is shown more in-depth further down


NOTE: you have to have something like the following in your configuration so the above snippet will work.
```lua
local wezterm = require "wezterm"

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- HERE YOUR CONFIG (FOR EXAMPLE THE TWO LINE CONFIG FOR sessionizer.wezterm ABOVE)

return config
```

### Customization
You can disable the default bindings by passing an additional true to the `apply_to_config` function like so
```lua
sessionizer.apply_to_config(config, true)
```

You can bind the functions `sessionizer.wezterm` provides in your normal configuration. Here is an
example:

```lua
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
        action = sessionizer.switch_to_most_recent,
    },
}

return config
```

To customize further there is `sessionizer.config` the following is the default configuration:
```lua
{
    paths = {},
    command = {
        "fd",
        "-HI",
        "-td",
        "^.git$",
        "--max-depth=16",
        "--prune",
        "--format",
        "{//}"
    },
    title = "Sessionzer",
    show_default = true,
    show_most_recent = true,
    fuzzy = true,
}
```
Right now the directory to search is just appended to the command that is listed found in `sessionizer.config.command`
