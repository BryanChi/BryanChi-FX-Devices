local table_helpers = {}

---TODO empty function
function table_helpers.TableMaxVal()
end

---@param T table
---@return integer
function table_helpers.tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

---@generic T
---@param Table table<string, T>
---@param V T
---@return boolean|nil
---@return T[]|nil
function table_helpers.FindExactStringInTable(Table, V)
    local found = nil
    local Tab = {}
    if V then
        for i, val in pairs(Table) do
            if val == V then
                found = true
                table.insert(Tab, i)
            end
        end
        if found == true then return true, Tab else return false end
    else
        return nil
    end
end

---@generic T
---@param Table table<string, T>
---@param V T
---@return boolean|nil
---@return T[]|nil
function table_helpers.FindStringInTable(Table, V) ---TODO isn’t this a duplicate of FindExactStringInTable ?  -- this one uses string:find whereas exact uses ==
    local found = nil
    local Tab = {}
    if V then
        for i, val in pairs(Table) do
            if string.find(val, V) ~= nil then
                found = true
                table.insert(Tab, i)
            end
        end
        if found == true then return true, Tab else return false end
    else
        return nil
    end
end



return table_helpers
