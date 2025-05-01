local helpers = {}

helpers.append_each = function(source, destination)
    for _, value in ipairs(source) do
        table.insert(destination, value)
    end
end

helpers.merge_tables = function(t1, t2)
    if (not t2) then return end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            helpers.merge_tables(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
end

helpers.for_each_entry = function(f)
    return function(entries)
        for _, entry in ipairs(entries) do
            f(entry)
        end
    end
end

return helpers
