-- NOTE: First we add our path to the package.path because we want to do requires easily
package.path = package.path .. ";" .. (select(2, ...):gsub("init.lua$", "?.lua"))

-- FIX: Needed before release
-- TODO: backwards compatibility

local wez = require "wezterm"
local act = wez.action
local history = require "sessionizer.history"
local helpers = require "sessionizer.table_helpers"

local plugin = {}

plugin.config = { command_options = { exclude = {}, }, } -- NOTE: unfortunetly necessary for now

plugin.apply_to_config = function(user_config, disable_default_binds)
    require "sessionizer.bindings".apply_binds(plugin, user_config, disable_default_binds)
end

---@param processors ProcessorFunc[]
---@param entries Entry[]
---@return Entry[]
local function apply_processing(processors, entries)
    local result = helpers.deep_copy(entries)
    local i = 1
    local function next()
        local processor = processors[i]
        i = i + 1
        if processor then
            processor(result, next)
        end
    end
    next()
    return result
end

---@param spec Spec
---@return Entry[]
local function get_processed_entries_from_spec(spec)
    ---@type Entry[]
    local result = {}
    for k, value in pairs(spec) do
        -- TODO: Consider just continue if k is a string maybe idk
        if k == "processors" or k == "processor" or k == "display_options" or k == "name" then
            goto continue
        end

        if type(value) == "string" then
            table.insert(result, require "sessionizer.entries".make_entry(value, value))
        elseif type(value) == "table" then
            -- now it is either a raw entry or previously a generator table
            if value.label then
                table.insert(result, value)
            else
                -- now if the config is right it must be a sub table so another spec so a recursive call
                local sub_result = get_processed_entries_from_spec(value)
                helpers.append_each(result, sub_result)
            end
        elseif type(value) == "function" then
            -- the only function we have exposed at the top is a generator function so let's call it
            local gen_result = value()
            helpers.append_each(result, gen_result)
        end
        ::continue::
    end
    result = apply_processing(spec["processor"] and { spec["processor"] } or {}, result)
    result = apply_processing(spec["processors"] or {}, result)
    return result
end

--- @param name string
--- @param current_spec Spec
--- @return Spec?
local function find_subspec_with_name(name, current_spec) -- TODO: maybe go breadth first
    local result = nil
    if current_spec["name"] and current_spec["name"] == name then
        return current_spec
    end

    for _, v in pairs(current_spec) do
        if type(v) == "table" then
            result = find_subspec_with_name(name, v) or result
        end
    end

    return result
end

---@type integer
local show_count = 0

---@param spec Spec|string|nil
---@return unknown
plugin.show = function(spec)
    local unique_id = "sessionizer-show-" .. show_count
    show_count = show_count + 1
    wez.on(unique_id, function(window, pane)
        if type(spec) == "string" then
            spec = find_subspec_with_name(spec, plugin.spec)
        end
        spec = spec or plugin.spec

        local entries = get_processed_entries_from_spec(spec) or {}
        plugin.display_entries(entries, window, pane, spec["display_options"])
    end)
    return act.EmitEvent(unique_id)
end

---@type Spec
plugin.spec = {
}

---@type GeneratorFunction
---@param opts FdGeneratorFuncArgs
plugin.FdSearch = function(opts)
    require "sessionizer.generators.fd".FdSearch(opts)
end

---@param partial_options DisplayOptionsPartial
---@return DisplayOptions
local function normalize_options(partial_options)
    local defaults = {
        title = "Sessionzer",
        description = "Select a workspace: ",
        show_default_workspace = true,
        show_most_recent_workspace = true,
        fuzzy = true,
    }

    helpers.merge_tables(defaults, partial_options)
    return defaults
end

---@param entries Entry[]
---@param window unknown
---@param pane unknown
---@param partial_options DisplayOptionsPartial
plugin.display_entries = function(entries, window, pane, partial_options)
    local options = normalize_options(partial_options)
    window:perform_action(require "sessionizer.input_selector".get(options, entries), pane)
end

-- NOTE: This will eventually not really fit into the model (when we add domain extensions etc.)
-- maybe make it into a on_selection chain handler
local show_most_recent_identifier = "sessionizer.switch-to-most-recent"
plugin.switch_to_most_recent = act.EmitEvent(show_most_recent_identifier)
wez.on(show_most_recent_identifier, function(window, pane)
    local previous_workspace = wez.mux.get_active_workspace()
    window:perform_action(act.SwitchToWorkspace(
        history.get_most_recent_workspace()
    ), pane)
    history.set_most_recent_workspace(previous_workspace)
end)

return plugin
