# sessionizer.wezterm
A sessionizer plugin for WezTerm inspired by a discussion started by [@keturiosakys](https://github.com/keturiosakys) over at https://github.com/wez/wezterm/discussions/4796 and originally inspired by ThePrimeagen's tmux-sessionizer. It helps you switch between (by default) WezTerm workspaces more easily.
> [!WARNING]
> Backwards compatability might be broken (this might impact you if you delete/update your plugins)

## Optional dependencies (recommended)
* There is a built-in `generator` that uses [`fd`](https://github.com/sharkdp/fd)
* There is a built-in `generator` that uses [`zoxide`]([zoxide](https://github.com/ajeetdsouza/zoxide))

> [!NOTE]
> A `generator` is a function that _generates_ options for you to choose from

## Installation
To install `sessionizer.wezterm`, add the following two lines __after__ `config.keys` to your wezterm.lua
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.apply_to_config(config)
```
You now have the following two keybinds (custom binding further down) LINK
 * `ALT+s` show the sessionizer
 * `ALT+m` switch to the most recently selected workspace

But when you press `ALT+s` the list of options is still empty. Let's fix that!

Things that give us options to choose from get put into a thing called a `spec`. It is really just a group (a table) of things for you to choose from.

By default `ALT+s` shows the sessionizer for the spec assigned to `sessionizer.spec` which right now is an empty table, so let's change that
```lua
sessionizer.spec = {
    sessionizer.builtin.DefaultWorkspace {},
    -- The things that go here produce entries an Entry has a label and an id, by default the id is assumed to be a path.
    { label = "This is my home directory", id = wezterm.home_dir },
    -- You can also just put a string and the label will be the same as the path.
    "/home/mikka", -- this gives us { label = "/home/mikka", id = "/home/mikka" }

    -- You can also put so called generator functions here they return a table of entries
    -- There are some built-in generators like sessionizer.FdSearch
    sessionizer.builtin.FdSearch "/home/mikka/dev", -- This will search for git repositories in the specified directory
    -- But you can also put your own generator functions
    function()
        local entries = {}
        for i = 1, 10, 1 do
            table.insert(entries, { label = "Stub #" .. i, id = i } -- Note that i as the path for the workspace won't work 
        end
    end,
    sessionizer.builtin.Zoxide, -- this exists too
}
```
This is a basic example, there are more things you can do with a spec, we will explore them properly further down.

Here is a list of what you can put in a spec:
* Another spec (good for grouping processing/styiling)
* An Entry (like above this is a table with a label and an id)
* A string (this will be a Entry with label and id set to the string)
* A `generator` which is a function that returns a table of entries so Entry[]
* A name which can be used to find a spec inside another spec (explained further down) FOOT NODE ONLY ONCE
* options which is a table that sets things like the title and description etc. (also explained further down) FOOT NODE ONLY ONCE
* processor which is a function used to mutate the entries generated (useful for styling, explained further down) FOOT NODE ONLY ONCE
* processors which is a table of functions like processor

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

## Styling
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
