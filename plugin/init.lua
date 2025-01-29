-- NOTE: First we add our path to the package.path because we want to do requires easily
package.path = package.path .. ";" .. (select(2, ...):gsub("init.lua$", "?.lua"))

-- TODO: remember to get a deduplication thing at some point
-- TODO: inheritence of options

local wezterm = require "wezterm"
local history = require "sessionizer.history"
local helpers = require "sessionizer.helpers.init"

local plugin = {}

plugin.generators = require "sessionizer.generators.init"
plugin.helpers = require "sessionizer.helpers.init"
plugin.actions = require "sessionizer.actions.init"

---@type Spec
plugin.spec = {}

plugin.apply_to_config = function(user_config, disable_default_binds)
    require "sessionizer.bindings".apply_binds(plugin, user_config, disable_default_binds)
end

---@param spec Spec|string|nil
---@param name string|nil
---@return Spec?
local function get_effective_spec(spec, name)
    if type(spec) == "string" then
        name = spec
        spec = nil
    end
    spec = spec or plugin.spec
    if name then spec = helpers.find_subspec_with_name_dfs(name, spec) end
    if not spec then
        wezterm.log_error("sessionizer.wezterm: spec with name \"" .. name .. "\" not found.")
        return nil
    end

    return spec
end

---@type integer
local show_count = 0

---@param spec Spec|string|nil -- NOTE: might be a string then it is interpreted as a name on plugin.spec
---@param name string|nil
---@return unknown
plugin.show = function(spec, name)
    local unique_id = "sessionizer-show-" .. show_count
    show_count = show_count + 1

    wezterm.on(unique_id, function(window, pane)
        spec = get_effective_spec(spec, name)
        if not spec then return end

        local entries = helpers.evaluate_spec(spec) or {}
        plugin.display_entries(entries, window, pane, spec["options"])
    end)

    return wezterm.action.EmitEvent(unique_id)
end

---@param entries Entry[]
---@param window unknown
---@param pane unknown
---@param partial_options SpecOptionsPartial
plugin.display_entries = function(entries, window, pane, partial_options)
    local options = helpers.normalize_options(partial_options)
    window:perform_action(require "sessionizer.input_selector".get(options, entries), pane)
end

-- NOTE: This will eventually not really fit into the model (when we add domain extensions etc.)
-- maybe make it into a on_selection chain handler
local show_most_recent_identifier = "sessionizer.switch-to-most-recent"
plugin.switch_to_most_recent = wezterm.action.EmitEvent(show_most_recent_identifier)
wezterm.on(show_most_recent_identifier, function(window, pane)
    local current = wezterm.mux.get_active_workspace()
    local next = history.pop()
    if not next then return end

    window:perform_action(wezterm.action.SwitchToWorkspace(
        {
            name = next.id,
            spawn = { cwd = next.id }
        }
    ), pane)
    history.push(current)
end)

return plugin
