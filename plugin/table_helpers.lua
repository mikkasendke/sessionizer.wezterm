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

return helpers
