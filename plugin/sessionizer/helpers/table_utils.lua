local helpers = {};

---@param t table
---@return table
helpers.shallow_copy = function(t)
    local dest = {}
    for k, v in pairs(t) do
        dest[k] = v
    end
    return dest
end

helpers.deep_copy = function(t)
    local orig_type = type(t)
    local copy
    if orig_type == 'table' then
        copy = {}
        setmetatable(copy, helpers.deep_copy(getmetatable(t)))
        for tk, tv in next, t, nil do
            copy[helpers.deep_copy(tk)] = helpers.deep_copy(tv)
        end
    else
        copy = t
    end
    return copy
end

---@param t1 table
---@param t2 table|nil
helpers.merge_tables = function(t1, t2)
    if (not t2) then return end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            helpers.merge_tables(t1[k], t2[k])
            goto continue
        end
        t1[k] = v
        ::continue::
    end
end

---@param target table
---@param source table
helpers.append_each = function(target, source)
    for _, value in pairs(source) do
        table.insert(target, value)
    end
end


return helpers
