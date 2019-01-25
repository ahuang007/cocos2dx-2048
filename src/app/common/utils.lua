local utils = {}

function utils.var_dump(data, max_level, prefix)
    if type(prefix) ~= "string" then
        prefix = ""
    end
    if type(data) ~= "table" then
        print(prefix .. tostring(data))
    else
        print(data)
        if max_level ~= 0 then
            local prefix_next = prefix .. "    "
            print(prefix .. "{")
            for k, v in pairs(data) do
                io.stdout:write(prefix_next .. k .. " = ")
                if type(v) ~= "table" or (type(max_level) == "number" and max_level <= 1) then
                    print(v, ",")
                else
                    if max_level == nil then
                        utils.var_dump(v, nil, prefix_next)
                    else
                        utils.var_dump(v, max_level - 1, prefix_next)
                    end
                end
            end
            print(prefix .. "}")
        end
    end
end

function utils.get_random_sublist(array, n)
    assert(n >= 1 and n <= #array)
    local r = {}
    local t = {}
    local len = # array
    for i = 1, n do
        while true do
            local ri = math.random(len)
            if not t[ri] then
                t[ri] = true
                table.insert(r, array[ri])
                break
            end
        end
    end
    return r
end

function utils.split(str, split)
    local list = {}
    local pos = 1
    if string.find("", split, 1) then -- this would result in endless loops
		error("split matches empty string!")
    end
    while true do
        local first, last = string.find(str, split, pos)
        if first then
            table.insert(list, string.sub(str, pos, first - 1))
            pos = last + 1
        else
            table.insert(list, string.sub(str, pos))
            break
        end
    end
    return list
end

function utils.elem(arr, e)
    local exist = false
    for i, v in ipairs(arr) do 
        if v == e then 
            exist = true 
        end     
    end     
    return exist
end    

return utils