local helpers = require "sessionizer.helpers"

local schema_processor = {}

---@param schema Schema
---@return Entry[]
schema_processor.evaluate_schema = function(schema)
    schema = schema_processor.complete_schema(schema) -- PERF: this wastes a lot of resources filling in options for each schema
    local result = {}                                 -- eventhough we only care about top level options

    for key, value in pairs(schema) do
        if key == "processing" or key == "options" then goto continue end

        if type(value) == "string" then -- string i.e. shorthand for entry
            helpers.append_each({ { label = value, id = value } }, result)
        elseif type(value) == "table" then
            if value.label and value.id then -- raw entry
                helpers.append_each({ value }, result)
            else                             -- has to be another schema
                helpers.append_each(schema_processor.evaluate_schema(value), result)
            end
        elseif type(value) == "function" then -- so it is a generator
            helpers.append_each(schema_processor.evaluate_schema(value()), result)
        end

        ::continue::
    end

    for _, processor in ipairs(schema.processing) do
        processor(result)
    end

    return result
end

---@param schema Schema
---@return Schema
schema_processor.complete_schema = function(schema)
    if type(schema.processing) == "function" then schema.processing = { schema.processing } end

    local defaults = {
        options = {
            title = "Sessionizer",
            prompt = "Select entry: ",
            always_fuzzy = true,
            callback = schema_processor.DefaultCallback,
        },

        processing = {},
    }
    helpers.merge_tables(defaults, schema)
    schema = defaults
    return schema
end

schema_processor.DefaultCallback = function(window, pane, id, label)
    if not id then return end
    window:perform_action(require "wezterm".action.SwitchToWorkspace({ name = id, spawn = { cwd = id } }), pane)
end

return schema_processor
