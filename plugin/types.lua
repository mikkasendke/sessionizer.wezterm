---@class Entry
---@field label string
---@field id string

---@class GeneratorFunction
---@field __call fun(): Entry[]

---@class ProcessorFunc
---@field _call fun(entries: Entry[], next: fun())

---@alias Spec (string|Entry|GeneratorFunction|Spec)[] and maybe a processors key in there and maybe a name key in there and a key display_options of type DisplayOptionsPartial

---@class DisplayOptions
---@field title string
---@field description string
---@field show_default_workspace boolean
---@field show_most_recent_workspace boolean
---@field fuzzy boolean

---@class DisplayOptionsPartialInner
---@field title string?
---@field description string?
---@field show_default_workspace boolean?
---@field show_most_recent_workspace boolean?
---@field fuzzy boolean?

---@alias DisplayOptionsPartial DisplayOptionsPartialInner?

---@class FdOptionsPartial
---@field [1] string -- NOTE: maybe here also later string[] perhaps
---@field fd_path string?
---@field include_submodules boolean?
---@field max_depth integer?
---@field format string?
---@field exclude string|string[]?
---@field extra_args string|string[]?

---@class FdOptions
---@field [1] string
---@field fd_path string
---@field include_submodules boolean
---@field max_depth integer
---@field format string
---@field exclude string[]
---@field extra_args string[]

---@alias FdGeneratorFuncArgs string|FdOptionsPartial -- NOTE: maybe later also string array

---@class Config
---@field title string
---@field description string
---@field show_default boolean
---@field show_most_recent boolean
---@field fuzzy boolean

---@class LegacyConfig: Config -- NOTE: those are not partial
---@field paths = string[]
