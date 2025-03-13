
# sessionizer.wezterm

A sessionizer plugin for WezTerm inspired by a discussion started by [@keturiosakys](https://github.com/keturiosakys) over at https://github.com/wez/wezterm/discussions/4796 and originally inspired by ThePrimeagen's tmux-sessionizer. It helps you switch between (by default) WezTerm workspaces more easily.

## Optional dependencies (recommended)
* There is a built-in `generator` that uses [`fd`](https://github.com/sharkdp/fd)

> [!NOTE]
> A `generator` is a function that _generates_ options for you to choose from

## Installation
To install `sessionizer.wezterm`, add the following two lines __after__ `config.keys` to your wezterm.lua
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.apply_to_config(config)
```
You now have the following two keybinds, custom binds are expained further down.
 * `ALT+s` show sessionizer
 * `ALT+m` switch to the most recently selected workspace

But when you press `ALT+s` the list of options is still empty. Let's fix that!

## Just works tm config

```lua
local my_spec = {
    sessionizer.generators.DefaultWorkspace {},
    sessionizer.generators.FdSearch wezterm.home_dir .. "/dev", -- NOTE: HERE YOUR PATH TO YOUR GIT REPOS
    processing = sessionizer.helpers.for_each_entry(function(entry)
        entry.label = entry.label:gsub(wezterm.home_dir, "~") -- this shortens paths
end)
```
Now either using default ALT+S binds
```lua
sessionizer.spec = my_spec
```
OR
assign it yourself like this (or just in your config.keys table):

```lua
table.insert(config.keys, {
    key = "e" -- for example,
    mods = "ALT",
    action = sessionizer.show(my_spec)
}
```

## Understanding Specs

We call a table of options we can choose from a `spec`.

By default `ALT+s` shows the sessionizer for the spec assigned to `sessionizer.spec` which right now is an empty table, so we set `sessionizer.spec` to something different.
```lua
sessionizer.spec = {
    sessionizer.generators.DefaultWorkspace {},
    -- The things that go here produce entries an Entry has a label and an id, by default the id is assumed to be a path.
    { label = "This is my home directory", id = wezterm.home_dir },
    -- You can also just put a string and the label will be the same as the path.
    "/home/mikka", -- this gives us { label = "/home/mikka", id = "/home/mikka" }

    -- You can also put so called generator functions here they return a table of entries
    -- There are some built-in generators like the return value of sessionizer.generators.FdSearch
    sessionizer.generators.FdSearch "/home/mikka/dev", -- This will search for git repositories in the specified directory
    -- But you can also put your own generator functions
    function()
        local entries = {}
        for i = 1, 10, 1 do
            table.insert(entries, { label = "Stub #" .. i, id = i }) -- Note that i as the path for the workspace won't work 
        end
        return entries -- Don't forget to return the entries!
    end,
}
```

A spec can contain:
* Multiple Entries (like above this is a table with a label and an id)
* A string (this will be a Entry with label and id set to the string after evaluation)
* Another spec (good for grouping processing/styling)
* A generator which is a function that returns a spec
* A name which is a string that can be used to find a spec inside another spec
* options which is a table that sets things like the title and description etc.
* processors which is a function or table of functions that takes a table of entries and can modify them

## Built-in Generators

The plugin comes with several built-in generators:

### DefaultWorkspace
Creates an entry for the default workspace:

```lua
sessionizer.generators.DefaultWorkspace {
    name_overwrite = "default" -- Optional, defaults to "default"
}
```

### MostRecentWorkspace
Creates an entry for the most recently used workspace:

```lua
sessionizer.generators.MostRecentWorkspace {}
```

### AllActiveWorkspaces
Creates entries for all active workspaces:

```lua
sessionizer.generators.AllActiveWorkspaces {
    filter_default = true, -- Optional, excludes the default workspace if true
    filter_current = true, -- Optional, excludes the current workspace if true
}
```

### FdSearch
Uses the `fd` command to search for directories:

```lua
sessionizer.generators.FdSearch {
    "/path/to/search", -- Required, the path to search in
    fd_path = "", -- Optional, path to fd binary (auto-detected by default)
    include_submodules = false, -- Optional, include git submodules
    max_depth = 16, -- Optional, maximum depth to search
    format = "{//}", -- Optional, fd format string
    exclude = { "node_modules" }, -- Optional, patterns to exclude
    extra_args = {}, -- Optional, additional arguments to fd
    overwrite = {} -- Optional, completely override the fd command
}
```
Note that if you just use the search path the following works as well:
```lua
sessionizer.generators.FdSearch "/path/to/search"
```

## Customization

### Options

You can set options for any spec using the `options` key:

```lua
sessionizer.spec = {
    options = {
        title = "My Sessionizer", -- The title shown in the selection UI
        description = "Select a workspace:", -- The description shown in the selection UI
        always_fuzzy = true, -- Whether to always use fuzzy search
        callback = sessionizer.actions.SwitchToWorkspace -- The action to perform when an entry is selected
    },
    -- Other spec entries...
}
```

### Styling with Processors

A spec is best styled by using processors and `wezterm.format`. A processor takes an array/table of Entry and can modify them.

If you need just one processor use `<any spec>.processing` if you need multiple you can put them into a table inside the `processing` field.

The entry array you will get contains all entries generated by the spec you are in minus the entries a processor might have removed before.

For example:

```lua
sessionizer.spec = {
    {
        sessionizer.generators.AllActiveWorkspaces { show_current_workspace = true, show_default_workspace = false, },
        processing = {
            function(entries, next) -- Using the next callback to chain processors (optional but can be done to influence order)
                for _, entry in pairs(entries) do
                    entry.label = wezterm.format {
                        { Foreground = { Color = "#77ee88" } },
                        { Text = entry.label }
                    }
                end
                next()
            end,
            sessionizer.helpers.for_each_entry(function(entry) entry.label = "active: " .. entry.label end),
        },
    },
    "/home/user/.config",
    processing = sessionizer.helpers.for_each_entry(function(entry) entry.label = entry.label:gsub(wezterm.home_dir, "~") end)
}
```

### Helper Functions

The plugin includes helper functions to make working with entries easier:

```lua
-- Apply a function to each entry in a spec
sessionizer.helpers.for_each_entry(function(entry) 
    -- Modify entry here
    entry.label = "Modified: " .. entry.label
end)
```

### Named Specs

You can name specs and reference them later:

```lua
sessionizer.spec = {
    {
        name = "dev-projects",
        options = {
            title = "Development Projects",
            description = "Select a development project:"
        },
        sessionizer.generators.FdSearch "/home/user/dev"
    },
    {
        name = "config-files",
        options = {
            title = "Config Files",
            description = "Select a config file to edit:"
        },
        "/home/user/.config/nvim",
        "/home/user/.config/wezterm",
        "/home/user/.nixos-config"
    }
}

-- Later, you can show a specific named spec
sessionizer.show("dev-projects")
```

### Key Binds

You can disable the default bindings by passing an additional true to the `apply_to_config` function:

```lua
sessionizer.apply_to_config(config, true)
```

To add custom bindings:

```lua
config.keys = config.keys or {}

table.insert(config.keys, {
    key = "p",
    mods = "ALT",
    action = sessionizer.show("dev-projects")
})

table.insert(config.keys, {
    key = "c",
    mods = "ALT",
    action = sessionizer.show("config-files")
})
```

## Advanced Usage Examples

### Customized Workspace Switcher

```lua
local workspace_switcher = {
    options = {
        title = "Workspaces",
    },
    sessionizer.generators.DefaultWorkspace {},
    {
        sessionizer.generators.AllActiveWorkspaces {},
        processing = sessionizer.helpers.for_each_entry(function(entry)
            entry.label = wezterm.format {
                { Foreground = { Color = "#44cc88" } },
                { Text = "active: " .. entry.label }
            }
        end)
    },
    {
        sessionizer.generators.FdSearch "/home/mikka/dev",
        processing = sessionizer.helpers.for_each_entry(function(entry)
            entry.label = wezterm.format {
                { Foreground = { Color = "orange" } },
                { Text = " " .. entry.label }
            }
        end)
    },
    processing = sessionizer.helpers.for_each_entry(function(entry)
        entry.label = entry.label:gsub(wezterm.home_dir, "~")
    end)
}

table.insert(config.keys, {
    key = "w",
    mods = "ALT",
    action = sessionizer.show(workspace_switcher)
})
```

### Using Zoxide Integration

If you have the zoxide plugin installed:

```lua
table.insert(config.keys, {
    key = "z",
    mods = "ALT"
    action = sessionizer.show {
+        options = {
            title = "Zoxide Directories",
            description = "Select a recent directory:"
        },
        wezterm.plugin.require "https://github.com/mikkasendke/sessionizer-zoxide".Zoxide,
        processing = sessionizer.helpers.for_each_entry(function(e) 
            e.label = "ZOXIDE: " .. e.label 
        end)
    }
)
    
```

or something like smart workspace switcher
```lua
local smart_workspace_switcher = {
    {
        sessionizer.generators.AllActiveWorkspaces { show_current_workspace = true, show_default_workspace = false, },
        processing = function(entries)
            for _, entry in pairs(entries) do
                entry.label = wezterm.format {
                    { Foreground = { Color = "#77ee88" } },
                    { Text = entry.label }
                }
            end
        end
    },
    sessionizer.generators.Zoxide {},
    processing = sessionizer.helpers.for_each_entry(function(entry) entry.label = entry.label:gsub(wezterm.home_dir, "~") end)
}
```

## Reference

### Main Functions

- `sessionizer.show(spec, name)`: Shows a selection menu for the given spec or named spec
- `sessionizer.switch_to_most_recent`: Switches to the most recently used workspace
- `sessionizer.apply_to_config(config, disable_defaults)`: Applies the plugin to the WezTerm config

### Helpers

- `sessionizer.helpers.for_each_entry(func)`: Creates a processor that applies func to each entry
- `sessionizer.helpers.evaluate_spec(spec)`: Evaluates a spec to produce entries

## Contributing

Contributions are welcome! Please feel free to submit prs and/or issues.
