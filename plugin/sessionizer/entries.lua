local entries = {}

---@param label string
---@param id string
---@return Entry
entries.make_entry = function(label, id)
    return { label = label, id = id }
end

return entries
