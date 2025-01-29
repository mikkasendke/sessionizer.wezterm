local actions = require "sessionizer.actions.init"

local helpers = {}

---@param f fun(entry: Entry)
helpers.for_each_entry = function(f)
    return function(entries)
        for _, entry in pairs(entries) do
            f(entry)
        end
    end
end

---@param partial_options SpecOptionsPartial
---@return SpecOptions
helpers.normalize_options = function(partial_options)
    local defaults = {
        title = "Sessionzer",
        description = "Select a workspace: ",
        always_fuzzy = true,
        callback = actions.SwitchToWorkspace,
    }

    helpers.table_utils.merge_tables(defaults, partial_options)
    return defaults
end

---@param processors ProcessorFunc[]
---@param entries Entry[]
---@return Entry[]
local function apply_processing(processors, entries)
    local result = helpers.table_utils.deep_copy(entries)
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
helpers.evaluate_spec = function(spec)
    ---@type Entry[]
    local result = {}
    for key, value in pairs(spec) do
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
                local sub_result = helpers.evaluate_spec(value)
                helpers.table_utils.append_each(result, sub_result)
            end
        elseif type(value) == "function" then
            -- the only function we have exposed at the top is a generator function so let's call it
            local sub_result = helpers.evaluate_spec(value())
            helpers.table_utils.append_each(result, sub_result)
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
helpers.find_subspec_with_name_dfs = function(name, current_spec)
    local result = nil
    if current_spec["name"] and current_spec["name"] == name then
        return current_spec
    end

    for _, v in pairs(current_spec) do
        if type(v) == "table" then
            result = helpers.find_subspec_with_name_dfs(name, v) or result
        end
    end

    return result
end

helpers.table_utils = require "sessionizer.helpers.table_utils"

return helpers
