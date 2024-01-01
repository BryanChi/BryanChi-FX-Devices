local INI_parser = {}

---Get anything after the `=` sign in a string
---@param str string
function INI_parser.get_aftr_Equal(str)
    if str then
        local o = str:sub((str:find('=') or -2) + 2)
        if o == '' or o == ' ' then o = nil end
        return o
    end
end

---@param str string|nil
function INI_parser.get_aftr_Equal_bool(str)
    if str then
        local o = str:sub(str:find('=') + 2) ---@type string |boolean | nil
        if o == '' or o == ' ' or 0 == 'nil' then
            o = nil
        elseif o == 'true' then
            o = true
        elseif o == 'false' then
            o = false
        else
            o = nil
        end
        return o
    end
end

---@param str string|nil
function INI_parser.get_aftr_Equal_Num(str, Title)
    if str then
        if not Title then
            if str:find('=') then
                return tonumber(str:sub(str:find('=') + 2))
            end
        else
            if str:find(Title) then
                return tonumber(str:sub(str:find(Title) + 2))
            end
        end
    else
        return nil
    end
end

return INI_parser
