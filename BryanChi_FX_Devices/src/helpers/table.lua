

---TODO empty function
function TableMaxVal()
end

---TODO this is a duplicate, it’s unused and can’t you use #table instead?
---@param T table
---@return integer
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end



---@param T table
---@return integer
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end
