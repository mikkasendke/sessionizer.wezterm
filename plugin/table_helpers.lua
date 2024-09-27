local helpers = {};

helpers.shallow_copy = function(t)
    local dest = {}
    for k, v in pairs(t) do
        dest[k] = v
    end
    return dest
end

helpers.merge_tables = function(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            helpers.merge_tables(t1[k], t2[k])
            goto continue
        end
        t1[k] = v
        ::continue::
    end
end

helpers.curry1of5 = function(f)
    return function(a)
        return function(b, c, d, e)
            return f(a, b, c, d, e)
        end
    end
end

local function auto_table(table, key)
    return setmetatable({}, {
        __index = auto_table,
        __newindex = function(t, k, v)
            -- if v == nil then return end
            local prev_mt = getmetatable(t)
            prev_mt.parent[prev_mt.key] = t
            setmetatable(t, { __index = auto_table })

            t[k] = type(v) == "table" and v or { v }
        end,
        parent = table,
        key = key,
    })
end

helpers.automagic_table = function()
    return setmetatable({}, {
        __index = auto_table,
        __newindex = function(t, k, v) rawset(t, k, type(v) == "table" and v or { v }) end
    })
end


return helpers
