package.path = package.path .. ";" .. ({ ... })[2]:gsub("init.lua$", "?.lua")

local wezterm = require "wezterm"
local schema_processor = require "sessionizer.schema_processor"
local input_selector = require "sessionizer.input_selector"
local uniqueEventCount = 0

return {
    apply_to_config = function(config) end,
    show = function(schema)
        local uniqueEventId = "sessionizer-show-" .. uniqueEventCount
        uniqueEventCount = uniqueEventCount + 1

        wezterm.on(uniqueEventId, function(window, pane)
            local entries = schema_processor.evaluate_schema(schema)
            local options = schema_processor.complete_schema(schema).options
            window:perform_action(input_selector.get_input_selector(options, entries), pane)
        end)
        return wezterm.action.EmitEvent(uniqueEventId)
    end,
    DefaultWorkspace = require "sessionizer.generators.default_workspace".DefaultWorkspace,
    AllActiveWorkspaces = require "sessionizer.generators.all_active_workspaces".AllActiveWorkspaces,
    FdSearch = require "sessionizer.generators.fd_search".FdSearch,

    for_each_entry = require "sessionizer.helpers".for_each_entry,
    DefaultCallback = require "sessionizer.schema_processor".DefaultCallback, -- NOTE: maybe relocate this
}

---@alias Schema SchemaScope|(PrimitiveElement)[]

---@class SchemaScope
---@field options SchemaOptions
---@field processing (fun(schema: Entry[]): Entry[])[]
---@field [integer] Schema

---@class SchemaOptions
---@field title string
---@field prompt string
---@field always_fuzzy boolean
---@field callback fun(window, pane, id, label)

---@alias PrimitiveElement Entry|string

---@class Entry
---@field id string
---@field label string
