# sessionizer.wezterm

A flexible sessionizer for WezTerm allwoing you to define custom menus to switch workspaces, open projects, or trigger other actions. It was originally inspired by [ThePrimeagen's tmux-sessionizer](https://github.com/theprimeagen/tmux-sessionizer).

> [!NOTE]
> If you're using the old version of this plugin you might want to read the sections below and/or have a look at the migration example down below under [Advanced Examples](#advanced-examples). If you need the old version now it is available under https://github.com/mikkasendke/sessionizer-legacy and replace the url of `wezterm.plugin.require`.

https://github.com/user-attachments/assets/e99b29ec-39f4-4066-8aca-b89fdae3994c

## Installation

#### 1. Install Dependencies (Optional but reccommended)
   Install [`fd`](https://github.com/sharkdp/fd): Only needed if you want to use the `FdSearch` _generator_ (This is usually used to get the paths to git repositories).

#### 2. Add to WezTerm Config
   Add the following to your `wezterm.lua` file:

   ```lua
   local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
   ```

#### 3. Define a _Schema_
   Create a table (called a Schema) defining the menu you want to see:

   ```lua
   local my_schema = {
     { label = "Some project", id = "~/dev/project" }, -- Custom entry, label is what you see. By default id is used as the path for a workspace.
     "Workspace 1",  -- Simple string entry, expands to { label = "Workspace 1", id = "Workspace 1" }
     sessionizer.DefaultWorkspace {},
     sessionizer.AllActiveWorkspaces {},
     sessionizer.FdSearch "~/my_projects", -- Searches for git repos in ~/my_projects
   }
   ```

#### 4. Add a Keybinding
Insert something like this into your config.keys table.
   ```lua
   config.keys = {
     { key = "S", mods = "ALT", action = sessionizer.show(my_schema) },
     -- ... other keybindings ...
   }
   ```

See [Advanced Examples](#advanced-examples) for more complex use cases.

## Understanding Schemas

A schema is a Lua table that defines what appears in your sessionizer menu and how it behaves. It tells the plugin what to display and what to do when an entry was selected.

A schema can contain the following elements:

1. **`options` (Table, Optional):** Controls the appearance and behavior of the menu. These are its fields:

    | Name           | Type      | Default                        | Description                                                                                                                    |
    | -------------- | --------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
    | `title`        | `string`  | `"Sessionizer"`                | The **window** title when the sessionizer is open.                                                                             |
    | `prompt`       | `string`  | `"Select entry: "`             | The prompt text shown in the input area.                                                                                       |
    | `always_fuzzy` | `boolean` | `true`                         | Whether to enable fuzzy finding always or only after typing /.                                                                 |
    | `callback`     | `function`| `sessionizer.DefaultCallback`  | Function called when an entry is selected. Signature: `function(window, pane, id, label)`. Default switches to workspace `id` and creates one in the directory `id` if it does not already exist. |

2. **Entries (Array Elements):** Define the items that appear in the menu. These can be a mix of:
    * **String:** Shorthand for `{ label = value, id = value }`.
        ```lua
        "My Workspace"
        ```
    * **Table (Entry):** A table with `label` and `id` fields.
        ```lua
        { label = "WezTerm Config", id = "~/.config/wezterm" }
        ```
    * **Table (Schema):** Another schema table can be nested inside and its entries will be included (its `options` will be ignored though).
    * **Function (Generator):** A function that returns a Schema. For example:
        ```lua
        function exampleGenerator()
            local schema = {}
            for i=1,10 do
                table.insert(schema, { label = "Workspace " .. i, id = "this is workspace " .. i })
            end
            return schema
        end
        -- or this:
        -- sessionizer.AllActiveWorkspaces is a function that returns a generator,
        -- it's useful to provide some options.
        sessionizer.AllActiveWorkspaces { filter_default = true } 
        ```
        See [Built-in Generators](#built-in-generators) for some built-in generators and see [List of plugins that provide features
](#list-of-plugins-that-provide-features) for other plugins that provide generators or integrate in another way.

3. **`processing` (Table | Function, Optional):** Function(s) to modify entries before they are used/displayed.
    * Can be a function or table of functions.
    * Each function modifies the `entries` array in-place.
    * Useful for styling, filtering, or formatting entries.
    * Example using the helper:  
        ```lua
        -- prepends 📁 to each entry
        processing = sessionizer.for_each_entry(function(entry)
          entry.label = "📁 " .. entry.label
        end)

        -- or:
        processing = {
            sessionizer.for_each_entry(function(entry) -- recolors labels and replaces the absolute path to the home directory with ~
                entry.label = wezterm.format {
                    { Foreground = { Color = "#cc99ff" } },
                    { Text = entry.label:gsub(wezterm.home_dir, "~") },
                }
            end),
            sessionizer.for_each_entry(function(entry) -- same as above
              entry.label = "📁 " .. entry.label
            end)
        }
        ```
        See [Processing Entries](#processing-entries) for more info.
## Built-in Generators

Generators create entries dynamically each time you open the sessionizer. They provide up-to-date lists of choices like current workspaces or project folders.
Some commonly used ones are already built-in via functions that return a generator when passed options, we can call them generator factories.

### `sessionizer.DefaultWorkspace(opts)`
Creates an entry for your default or home workspace.

- **Options:** `{ label_overwrite, id_overwrite }`
  - `label_overwrite` (string): Custom label for the entry (default: `"Default"`).
  - `id_overwrite` (string): Custom id for the entry (default: `"default"`).

_Example usage:_
```lua
sessionizer.DefaultWorkspace { label_overwrite = "🏠 Home", id_overwrite = "home_ws" }
-- The id typically matches config.default_workspace in your wezterm config
```

### `sessionizer.AllActiveWorkspaces(opts)`
Lists all currently active WezTerm workspaces.

- **Options:** `{ filter_default, filter_current }`
  - `filter_default` (boolean): Exclude the "default" workspace (default: `true`).
  - `filter_current` (boolean): Exclude the currently active workspace (default: `true`).

_Example usage:_
```lua
sessionizer.AllActiveWorkspaces {} -- Use defaults
sessionizer.AllActiveWorkspaces { filter_default = false } -- Include "default"
```

### `sessionizer.FdSearch(opts | path_string)`
Searches for directories (like projects) using `fd`. Requires the `fd` binary to be installed.

- **Options:** Either a string (the path to search) or a table for advanced options.
  - As a string: The search path.
  - As a table:
    - `[1]` (string, required): The base path to search within.
    - `fd_path` (string): Path to the `fd` binary (auto-detected if omitted, use it for troubleshooting).
    - `include_submodules` (boolean): Search git submodules too (default: `false`).
    - `max_depth` (number): Maximum search depth (default: `16`).
    - `format` (string): fd output format (default: `{//}`).
    - `exclude` (table): List of patterns to exclude (default: `{ "node_modules" }`).
    - `extra_args` (table): Additional raw arguments for `fd`.

_Example usage:_
```lua
sessionizer.FdSearch(wezterm.home_dir .. "/dev") -- Simple path string
sessionizer.FdSearch { -- Advanced options
  wezterm.home_dir .. "/projects",
  max_depth = 32,
  include_submodules = true,
  exclude = { "target" },
}
```

## Processing Entries

Use the `processing` key to modify entries after generation but before display. This is useful for formatting, filtering, or sorting entries.

Example of shortening home directory paths:

```lua
local my_schema = {
  sessionizer.FdSearch(wezterm.home_dir .. "/dev"),
  
  -- Make paths more readable by replacing home directory with ~
  processing = sessionizer.for_each_entry(function(entry)
    entry.label = entry.label:gsub(wezterm.home_dir, "~")
  end)
}
```

You can also use multiple processing functions:

```lua
processing = {
  -- First processor: Shorten paths
  sessionizer.for_each_entry(function(entry)
    entry.label = entry.label:gsub(wezterm.home_dir, "~")
  end),
  
  -- Second processor: Add icons to entries
  sessionizer.for_each_entry(function(entry)
    entry.label = "📁 " .. entry.label
  end)
}
```

## Advanced Examples

1. How I use it:
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
local history = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer-history"

local schema = {
    options = { callback = history.Wrapper(sessionizer.DefaultCallback) },
    sessionizer.DefaultWorkspace {},
    history.MostRecentWorkspace {},

    wezterm.home_dir .. "/dev",
    wezterm.home_dir .. "/.nixos-config",
    wezterm.home_dir .. "/.config/wezterm",
    wezterm.home_dir .. "/.config/nvim",
    wezterm.home_dir .. "/.config/sway",
    wezterm.home_dir .. "/.config/waybar",
    wezterm.home_dir .. "/.config/ags",
    wezterm.home_dir .. "/Uni",

    sessionizer.FdSearch(wezterm.home_dir .. "/dev"),
    sessionizer.FdSearch(wezterm.home_dir .. "/Uni"),

    processing = sessionizer.for_each_entry(function(entry)
        entry.label = entry.label:gsub(wezterm.home_dir, "~")
    end)
}

table.insert(config.keys, {
    key = "s",
    mods = "ALT",
    action = sessionizer.show(schema)
})
table.insert(config.keys, {
    key = "m",
    mods = "ALT",
    action = history.switch_to_most_recent_workspace
})
```
3. A replica of [smart_workspace_switcher.wezterm](https://github.com/MLFlexer/smart_workspace_switcher.wezterm):
```lua
local history = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer-history.git"

local smart_workspace_switcher_replica = {
    options = {
        prompt = "Workspace to switch: ",
        callback = history.Wrapper(sessionizer.DefaultCallback)
    },
    {
        sessionizer.AllActiveWorkspaces { filter_current = false, filter_default = false },
        processing = sessionizer.for_each_entry(function(entry)
            entry.label = wezterm.format {
                { Text = "󱂬 : " .. entry.label },
            }
        end)
    },
    wezterm.plugin.require "https://github.com/mikkasendke/sessionizer-zoxide.git".Zoxide {},
    processing = sessionizer.for_each_entry(function(entry)
        entry.label = entry.label:gsub(wezterm.home_dir, "~")
    end),
}

table.insert(config.keys, {
    key = "e",
    mods = "ALT",
    action = sessionizer.show(smart_workspace_switcher_replica)
})
table.insert(config.keys, {
    key = "m",
    mods = "ALT",
    action = history.switch_to_most_recent_workspace
})
 ```
3. Migrating a legacy config:
Here is an example of a config in the old style and what it turns into:
Old:
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
sessionizer.apply_to_config(config) -- this is not needed anymore (no default binds)
local home_dir = wezterm.home_dir
local config_path = home_dir .. ("/.config")
sessionizer.config.paths = { -- for these you will want a sessionizer.FdSerach for each of the paths
    home_dir .. "/dev",
    home_dir .. "/other"
}
sessionizer.config.title = "My title" -- this moves to the options field
sessionizer.config.fuzzy = false -- in options field now renamed to always_fuzzy
sessionizer.config.show_additional_before_paths = true -- not needed as order matters in a schema table
command_options = { include_submodules = true } -- these options can now be passed to sessionizer.FdSearch individually
sessionizer.config.additional_directories = { -- these can be put in the schema by themselves
    config_path .. "/wezterm",
    config_path .. "/nvim",
    config_path,
    home_dir .. "/.nixos-config",
    home_dir .. "/dev",
}
```
Migrated version:
```lua
local sessionizer = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer.wezterm"
local history = wezterm.plugin.require "https://github.com/mikkasendke/sessionizer-history.git" -- the most recent functionality moved to another plugin

local home_dir = wezterm.home_dir
local config_path = home_dir .. ("/.config")

local schema = {
   options = {
      title = "My title",
      always_fuzzy = false,
      callback = history.Wrapper(sessionizer.DefaultCallback), -- tell history that we changed to another workspace
   },
   config_path .. "/wezterm",
   config_path .. "/nvim",
   config_path,
   home_dir .. "/.nixos-config",
   home_dir .. "/dev",
   sessionizer.FdSearch { home_dir .. "/dev", include_submodules = true },
   sessionizer.FdSearch { home_dir .. "/dev", include_submodules = true },
}
-- Now you need to call sessionizer.show with this schema on a keypress yourself.
-- you could for example do:
config.keys = {
   { key = "s", mods = "ALT", action = sessionizer.show(schema) },
   { key = "m", mods = "ALT", action = history.switch_to_most_recent_workspace },
}
```

## List of plugins that provide features

* [sessionizer-history](https://github.com/mikkasendke/sessionizer-history): provides a generator and callback wrapper for getting the most recent workspace
* [sessionizer-zoxide](https://github.com/mikkasendke/sessionizer-zoxide): provides a generator for results from zoxide

_Feel free to make a pr if you have another plugin that integrates with sessionizer.wezterm._

## Contributing

Contributions, issues, and pull requests are welcome!
Especially now with the new version released any issue reports are very welcome :)
