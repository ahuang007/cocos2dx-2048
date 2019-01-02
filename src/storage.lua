
local Storage = {}
local json = require "json"

local userDefault = cc.UserDefault:getInstance()

local function checkKey(key)
    if not key or key == "" then
        return false
    end
    return true
end

-- table->json
function Storage.setTable(key, val)
    Storage.putString(key, json.encode(val))
end 

function Storage.getTable(key, defVal)
    defVal = defVal or {}
    return json.decode(Storage.getString(key, json.encode(defVal)))
end    

-- string
function Storage.setString(key, val)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    userDefault:setStringForKey(key, val)
    userDefault:flush()
end

function Storage.getString(key, defVal)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    defVal = defVal or ""
    return userDefault:getStringForKey(key, defVal) -- 第二个参数为默认值 
end

-- int
function Storage.setInt(key, val)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    userDefault:setIntegerForKey(key, val)
    userDefault:flush()
end

function Storage.getInt(key, defVal)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    defVal = defVal or 0
    return userDefault:getIntegerForKey(key, defVal)
end

-- float
function Storage.setFloat(key, val)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    userDefault:setFloatForKey(key, val)
    userDefault:flush()
end

function Storage.getFloat(key, defVal)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    defVal = defVal or 0
    return userDefault:getFloatForKey(key, defVal)
end

-- bool
function Storage.setBool(key, val)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    userDefault:setBoolForKey(key, val)
    userDefault:flush()
end

function Storage.getBool(key, defVal)
    if not checkKey(key) then
        error("PublicStorage, error key!")
    end

    defVal = defVal or false
    return userDefault:getBoolForKey(key, defVal)
end

return Storage
