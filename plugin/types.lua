---@class Entry
---@field label string
---@field id string

---@class GeneratorFunction
---@field __call fun(): Spec

---@class ProcessorFunc
---@field _call fun(entries: Entry[], next: fun())

---@alias Spec (string|Entry|GeneratorFunction|Spec)[] and maybe a processors key in there and maybe a name key in there and a key options of type SpecOptionsPartial

---@class SpecOptions
---@field title string
---@field description string
---@field always_fuzzy boolean
---@field callback weztermActionIdk

---@class SpecOptionsPartialInner
---@field title string?
---@field description string?
---@field always_fuzzy boolean?
---@field callback weztermActionIdk?

---@alias SpecOptionsPartial SpecOptionsPartialInner?

---@class FdOptionsPartial
---@field [1] string -- NOTE: maybe here also later string[] perhaps
---@field fd_path string?
---@field include_submodules boolean?
---@field max_depth integer?
---@field format string?
---@field exclude string|string[]?
---@field extra_args string|string[]?
---@field overwrite string[]?

---@class FdOptions
---@field [1] string
---@field fd_path string
---@field include_submodules boolean
---@field max_depth integer
---@field format string
---@field exclude string[]
---@field extra_args string[]
---@field overwrite string[]

---@alias FdGeneratorFuncArgs string|FdOptionsPartial -- NOTE: maybe later also string array

---@class LegacySessionizer --  NOTE: contains only relevant fields
---@field config LegacyConfig?
---@field entry_processors LegacyEntryProcessorFunc[]?

---@class LegacyEntryProcessorFunc
---@field __call fun(entries: Entry[], next: LegacyEntryProcessorFunc)

---@class LegacyConfig
---@field paths string[]?
---@field additional_directories string[]?
---@field show_additional_before_paths boolean?
---@field title string?
---@field show_default boolean?
---@field show_most_recent boolean?
---@field fuzzy boolean?
---@field command string[]?
---@field command_options LegacyCommandOptions?
---@field experimental_branches boolean?

---@class LegacyCommandOptions
---@field fd_path string?
---@field include_submodules boolean?
---@field max_depth integer?
---@field format string?
---@field exclude string[]?
