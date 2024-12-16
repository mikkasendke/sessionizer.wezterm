# sessionizer.wezterm
A simple sessionizer for wezterm inspired by a discussion started by [@keturiosakys](https://github.com/keturiosakys) at https://github.com/wez/wezterm/discussions/4796 and originally inspired by ThePrimeagen's tmux-sessionizer. It helps you switch between wezterm workspaces (especially git repositories) more easily.

## Requirements
To use the default command [`fd`](https://github.com/sharkdp/fd) is required.

## Usage
### Installation
> [!WARNING]
> This is a WIP and not very fleshed out yet, so things might change

To install `sessionizer.wezterm` just add the following two lines __after your config.keys__ to your wezterm.lua
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.apply_to_config(config)
```

This will enable the following key binds:
 * `ALT+s` show the sessionizer
 * `ALT+m` switch to the most recently selected workspace

Now you need to add the path(s) you want the sessionizer to operate on. You can do this
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
> [!NOTE]
> The config is shown more in-depth further down.



> [!IMPORTANT]
> If you are on macOS and installed fd via homebrew you might have to set `sessionizer.config.command_options.fd_path` to the output of `which fd`
> You have to have something like the following in your configuration for the snippet above to work.
> ```lua
> local wezterm = require "wezterm"
> 
> local config = {}
> 
> if wezterm.config_builder then
>     config = wezterm.config_builder()
> end
> 
> -- HERE YOUR CONFIG (FOR EXAMPLE THE TWO LINE CONFIG FOR sessionizer.wezterm ABOVE)
> 
> return config
> ```

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

sessionizer.config.paths = "/home/myuser/projects"

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
        -- this is populated based on command_options it (Note that if you set this command_options will be ignored)
        -- effectively looks like the following
        -- "fd",
        -- "-Hs",
        -- "^.git$",
        -- "-td",
        -- "--max-depth=" .. command_options.max_depth,
        -- "--prune",
        -- "--format",
        -- command_options.format,
        -- Here any number of excludes for example
        -- -E node_modules
        -- -E another_directory_to_exclude
    },
    title = "Sessionzer",
    show_default = true,
    show_most_recent = true,
    fuzzy = true,
    additional_directories = {},
    show_additional_before_paths = false,
    command_options = { -- ignored if command is set
        include_submodules = false,
        max_depth = 16,
        format = "{//}",
        exclude = { "node_modules" } -- Note that this can also just be a string
    },
    experimental_branches = false,
}
```
Right now the directory to search is just appended to the command that is listed found in `sessionizer.config.command`
