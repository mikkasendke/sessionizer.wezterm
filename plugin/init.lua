-- NOTE: First we add our path to the package.path because we want to do requires easily
package.path = package.path .. ";" .. (select(2, ...):gsub("init.lua$", "?.lua"))

-- TODO: remember to get a deduplication thing at some point
-- TODO: inheritence of options

local wezterm = require "wezterm"
local act = wezterm.action
local history = require "sessionizer.history"

local plugin = {}

plugin.generators = require "sessionizer.generators.init"
plugin.helpers = require "sessionizer.helpers.init"
plugin.actions = require "sessionizer.actions.init"

plugin.config = {}

plugin.apply_to_config = function(user_config, disable_default_binds)
    require "sessionizer.bindings".apply_binds(plugin, user_config, disable_default_binds)
end


---@param processors ProcessorFunc[]
---@param entries Entry[]
---@return Entry[]
local function apply_processing(processors, entries)
    local result = plugin.helpers.table_utils.deep_copy(entries)
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
    for key, value in pairs(spec) do
        -- TODO: Consider just continue if k is a string maybe idk
        if key == "processing" or key == "options" or key == "name" then
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
                plugin.helpers.table_utils.append_each(result, sub_result)
            end
        elseif type(value) == "function" then
            -- the only function we have exposed at the top is a generator function so let's call it
            local sub_result = get_processed_entries_from_spec(value())
            plugin.helpers.table_utils.append_each(result, sub_result)
        end
        ::continue::
    end
    if spec["processing"] then
        if type(spec["processing"]) == "function" then
            result = apply_processing({ spec["processing"] }, result)
        else
            result = apply_processing(spec["processing"], result)
        end
    end
    return result
end

--- @param name string
--- @param current_spec Spec
--- @return Spec?
local function find_subspec_with_name(name, current_spec) -- TODO: maybe go breadth first (this actually might be fine because we just call the first appearence of the name that way)
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

---@param spec Spec|string|nil -- NOTE: might be a string then it is interpreted as a name on plugin.spec
---@param name string|nil
---@return unknown
plugin.show = function(spec, name)
    local unique_id = "sessionizer-show-" .. show_count
    show_count = show_count + 1

    wezterm.on(unique_id, function(window, pane)
        if type(spec) == "string" then
            name = spec
            spec = nil
        end
        spec = spec or plugin.spec

        if name then
            spec = find_subspec_with_name(name, spec)
        end

        if spec == nil then
            wezterm.log_error("sessionzer.wezterm: spec with name \"" .. name .. "\" not found.")
            return
        end

        local entries = get_processed_entries_from_spec(spec) or {}
        plugin.display_entries(entries, window, pane, spec["options"])
    end)

    return act.EmitEvent(unique_id)
end

--- Default spec
---@type Spec
plugin.spec = {
}


---@param partial_options SpecOptionsPartial
---@return SpecOptions
local function normalize_options(partial_options)
    local defaults = {
        title = "Sessionzer",
        description = "Select a workspace: ",
        always_fuzzy = true,
        callback = plugin.actions.SwitchToWorkspace
    }

    plugin.helpers.table_utils.merge_tables(defaults, partial_options)
    return defaults
end

---@param entries Entry[]
---@param window unknown
---@param pane unknown
---@param partial_options SpecOptionsPartial
plugin.display_entries = function(entries, window, pane, partial_options)
    local options = normalize_options(partial_options)
    window:perform_action(require "sessionizer.input_selector".get(options, entries), pane)
end

-- NOTE: This will eventually not really fit into the model (when we add domain extensions etc.)
-- maybe make it into a on_selection chain handler
local show_most_recent_identifier = "sessionizer.switch-to-most-recent"
plugin.switch_to_most_recent = act.EmitEvent(show_most_recent_identifier)
wezterm.on(show_most_recent_identifier, function(window, pane)
    local current = wezterm.mux.get_active_workspace()
    local next = history.pop()
    if not next then return end

    window:perform_action(act.SwitchToWorkspace(
        {
            name = next.id,
            spawn = { cwd = next.id }
        }
    ), pane)
    history.push(current)
end)

return plugin
