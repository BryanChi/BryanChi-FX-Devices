-- @noindex


---General functions list
function msg(...)
    for i, v in ipairs({ ... }) do
        r.ShowConsoleMsg(tostring(v) .. "\n")
    end
end

function deepCopy(orig)
    -- Table to store already copied tables to handle cyclic references
    local copies = {}
    
    -- Internal recursive function
    local function copy(orig)
        if type(orig) ~= "table" then
            return orig  -- If it's not a table, return the value itself (base case)
        elseif copies[orig] then
            return copies[orig]  -- If the table was already copied, return the copy
        end

        local newTable = {}
        copies[orig] = newTable  -- Store reference to prevent cyclic references

        -- Recursively copy all key-value pairs
        for key, value in pairs(orig) do
            newTable[copy(key)] = copy(value)
        end

        return newTable
    end

    return copy(orig)
end


function Save_to_Trk(str,v, trk )
    r.GetSetMediaTrackInfo_String(trk or LT_Track, 'P_EXT: '..str, tostring(v), true) 
end

---@generic T
---@param v? T
---@return boolean
function toggle(v, value, value_false)

    if value_false then
        if v == value_false then v = value else v = value_false end 
    else 
        if v then v = false else v = value or true end

    end
    return v
end

function toggle2(a, b)
    if a == b then return nil else return b end
end

---@param str string | nil
---@return nil|string
function RemoveEmptyStr(str)
    if str == '' then return nil else return str end
end

---@param Rpt integer
function AddSpacing(Rpt)
    for i = 1, Rpt, 1 do
        im.Spacing(ctx)
    end
end

---@param str string
function GetFileExtension(str)
    return str:match("^.+(%..+)$")
end

--------------------------- Container Related ------------------------------

---@param tr MediaTrack
---@param idx1 number
---@return integer "fxid"
function get_fx_id_from_container_path(tr, idx1, ...)
    local sc, rv = r.TrackFX_GetCount(tr) + 1, 0x2000000 + idx1
    for i, v in ipairs({ ... }) do
        local ccok, cc = r.TrackFX_GetNamedConfigParm(tr, rv, 'container_count')
        if ccok ~= true then return nil end
        rv = rv + sc * v
        sc = sc * (1 + tonumber(cc))
    end
    return rv
end

---@param tr MediaTrack
---@param fxidx integer 0 based or something like 33554455 in container
---@return table<Index,fxslot> table
function get_container_path_from_fx_id(tr, fxidx) -- returns a list of 1-based FXIDs as a table from a fx-address, e.g. 1, 2, 4
    if fxidx & 0x2000000 then
      local ret = { }
      local n = r.TrackFX_GetCount(tr)
      local curidx = (fxidx - 0x2000000) % (n+1)
      local remain = math.floor((fxidx - 0x2000000) / (n+1))
      if curidx < 1 then return nil end -- bad address
  
      local addr, addr_sc = curidx + 0x2000000, n + 1
      while true do
        local ccok, cc = r.TrackFX_GetNamedConfigParm(tr, addr, 'container_count')
        if not ccok then return nil end -- not a container
        ret[#ret+1] = curidx
        n = tonumber(cc)
        if remain <= n then if remain > 0 then ret[#ret+1] = remain end return ret end
        curidx = remain % (n+1)
        remain = math.floor(remain / (n+1))
        if curidx < 1 then return nil end -- bad address
        addr = addr + addr_sc * curidx
        addr_sc = addr_sc * (n+1)
      end
    end
    return { fxid+1 }
end

---@param tr MediaTrack
---@param NestedPath table
---@param idx1 number
---@param target number
---@return integer "fxid"
local function GetFXIDinContainer(tr, NestedPath, idx1, target) -- 1based
    if NestedPath then -- if Container is nested
        for i, v in ipairs(NestedPath) do
            if i == 1 then
                sc, rv = r.TrackFX_GetCount(tr) + 1, 0x2000000 + v
            else
                local ccok, cc = r.TrackFX_GetNamedConfigParm(tr, rv, 'container_count')
                if ccok ~= true then return nil end
                rv = rv + sc * v
                sc = sc * (1 + tonumber(cc))
                if i == #NestedPath then
                  rv = rv + sc * target
                end
            end
        end
        path_id = rv
    else
        local sc, rv = r.TrackFX_GetCount(tr) + 1, 0x2000000 + idx1
        rv = rv + sc * target
        path_id = rv
    end
      return path_id
end

function fx_map_parameter(tr, fxidx, parmidx) -- maps a parameter to the top level parent, returns { fxidx, parmidx }
    local path = get_container_path_from_fx_id(tr, fxidx)
    if not path then return nil end
    while #path > 1 do
        fxidx = path[#path]
        table.remove(path)
        local cidx = get_fx_id_from_container_path(tr, table.unpack(path))
        if cidx == nil then return nil end
        local i, found = 0, nil
        while true do
            local rok, r = reaper.TrackFX_GetNamedConfigParm(tr, cidx,
                string.format("param.%d.container_map.fx_index", i))
            if not rok then break end
            if tonumber(r) == fxidx - 1 then
                rok, r = reaper.TrackFX_GetNamedConfigParm(tr, cidx, string.format("param.%d.container_map.fx_parm", i))
                if not rok then break end
                if tonumber(r) == parmidx then
                    found = true
                    parmidx = i
                    break
                end
            end
            i = i + 1
        end
        if not found then
            -- add a new mapping
            local rok, r = reaper.TrackFX_GetNamedConfigParm(tr, cidx, "container_map.add")
            if not rok then return nil end
            r = tonumber(r)
            reaper.TrackFX_SetNamedConfigParm(tr, cidx, string.format("param.%d.container_map.fx_index", r),
                tostring(fxidx - 1))
            reaper.TrackFX_SetNamedConfigParm(tr, cidx, string.format("param.%d.container_map.fx_parm", r),
                tostring(parmidx))
            parmidx = r
        end
    end
    return fxidx, parmidx
end

---@param FX_Idx integer
---@return integer "next_fxidx"
---@return integer "previous_fxidx"
---@return string "NextFX"
---@return string "PreviousFX"
function GetNextAndPreviousFXID(FX_Idx)
    local incontainer, parent_container = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "parent_container")
    if incontainer then
        path_table = get_container_path_from_fx_id(LT_Track, FX_Idx)
        next_fxidx = TrackFX_GetInsertPositionInContainer(parent_container, path_table[#path_table] + 1) 
        local target_pos = path_table[#path_table]
        local name_pos = path_table[#path_table] - 1
        local previous_name = TrackFX_GetInsertPositionInContainer(parent_container, name_pos)
        _, PreviousFX = r.TrackFX_GetFXName(LT_Track, previous_name)
        previous_fxidx = TrackFX_GetInsertPositionInContainer(parent_container, target_pos)
    else -- not in container
        next_fxidx = FX_Idx + 1
        if FX_Idx == 0 then -- 0 based, when the first slot is FX_Idx, there's no slot in the previous position (-1)
            previous_fxidx = FX_Idx
        else
            previous_fxidx = FX_Idx - 1
        end
        _, PreviousFX = r.TrackFX_GetFXName(LT_Track, previous_fxidx)
    end
    local _, NextFX = r.TrackFX_GetFXName(LT_Track, next_fxidx)
    return next_fxidx, previous_fxidx, NextFX, PreviousFX
end

---@param container_id integer 0 based or something like 33554455 in container
---@param target_pos number 1-based slot number where you want to add FX
---@return integer "fxid"
function TrackFX_GetInsertPositionInContainer(container_id, target_pos)
    local rv, _ = r.TrackFX_GetNamedConfigParm(LT_Track, container_id, "parent_container")
    if rv then -- Container is nested
        NestedPath = get_container_path_from_fx_id(LT_Track, tonumber(container_id))
        target_id = GetFXIDinContainer(LT_Track, NestedPath, nil, target_pos) -- parent -> #1 track, #2 child of parent
    else -- container is in root
        target_id = GetFXIDinContainer(LT_Track, nil, container_id + 1, target_pos) -- 1 based
    end
    NestedPath = nil
    return target_id
end

---@param FX_Idx integer
function GetLastFXid_in_Container(FX_Idx)
    local lastid
    local rv, parent_cont   = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'parent_container')
    if rv then -- it's in container
        local ct = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, parent_cont, 'container_count')))
        for i = 0, ct do 
            local rv, id   = r.TrackFX_GetNamedConfigParm(LT_Track, parent_cont, 'container_item.'..i)
            if tonumber(id) == FX_Idx then 
                rv, lastid = r.TrackFX_GetNamedConfigParm(LT_Track, parent_cont, 'container_item.'..i-1)
            end 
        end 
    end
    return tonumber(lastid)
end

function GetNextFXid_in_Container(FX_Idx)
    local lastid, thisid,ct
    local rv, parent_cont   = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'parent_container')

    if rv  then 

         ct = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, parent_cont, 'container_count')))
        for i=0 , ct, 1 do 

            rv, id   = r.TrackFX_GetNamedConfigParm(LT_Track, parent_cont, 'container_item.'..i)

            if tonumber(id) == FX_Idx then 

                rv, nextid = r.TrackFX_GetNamedConfigParm(LT_Track, parent_cont, 'container_item.'..i+1)
                thisid = id 
            end 
        end 
    end
    return tonumber(nextid), tonumber(thisid), tonumber(parent_cont), ct
end

------------------------------------------------------------------------------
function BuildFXTree_item(tr, fxid, scale, oldscale)
    local tr = tr or LT_Track
    local retval, buf = reaper.TrackFX_GetFXName(tr, fxid)
    local ccok, container_count = reaper.TrackFX_GetNamedConfigParm(tr, fxid, 'container_count')
    local rv , ret = r.TrackFX_GetNamedConfigParm(tr, fxid, 'parallel') 
    local parallel = ret == '1' and true 

    local ret = {
        fxname = buf,
        isopen = reaper.TrackFX_GetOpen(tr, fxid),
        GUID = reaper.TrackFX_GetFXGUID(tr, fxid),
        addr_fxid = fxid,
        scale = oldscale,
        parallel = parallel
    }
    local fxGUID = r.TrackFX_GetFXGUID(tr, fxid)
    FX = FX or {}
    FX[fxGUID] = FX[fxGUID] or {}
    FX[fxGUID].addr_fxid =  fxid



    if ccok then -- if fx in container is a container
        ret.children = {}
        local newscale = scale * (tonumber(container_count) + 1)

        for child = 1, tonumber(container_count) do
            ret.children[child] = BuildFXTree_item(tr, fxid + scale * child, newscale, scale)
        end
    end
    return ret
end





function BuildFXTree(tr)
    -- table with referencing ID tree
    local tr = tr or LT_Track
    if tr then
        tree = {}
        local cnt = reaper.TrackFX_GetCount(tr)
        for i = 1, cnt do
            tree[i] = BuildFXTree_item(tr, 0x2000000 + i, cnt + 1, cnt + 1)
        end




        local last_parallel_fx

        local NeedCheckNext 

        local function find_parallel_sequences(tree)
            local sequences = {}
            local start_index = nil
            local count = 0
        
            for i = 1, #tree do
                if tree[i].parallel then
                    if start_index == nil then
                        start_index = i -1   -- Start of a new sequence
                    end
                    count = count + 1
                else
                    if count >= 1 then
                        table.insert(sequences, {start_index, i - 1})
                    end
                    start_index = nil
                    count = 0
                end
            end
        
            -- Check if the loop ended while still in a sequence
            if count >=1 then
                table.insert(sequences, {start_index, #tree})
            end
        
            return sequences
        end



        PAR_FXs = find_parallel_sequences(tree)



        return tree
    end
end

function Check_If_Has_Children_Prioritize_Empty_Container(TB)
    local Candidate
    for i, v in ipairs(TB) do
        if v.children then
            if v.children[1] then         --if container not empty
                Candidate = v.children
            elseif not v.children[1] then -- if container empty
                local Final = v.children ~= nil and 'children' or 'candidate'
                return v.children or Candidate
            end
        end
    end
    if Candidate then
        return Candidate
    end
end

--------------------------------------------------------------------------

local tr = r.GetSelectedTrack(0, 0)
TREE = BuildFXTree(LT_Track or tr)

function EndUndoBlock(str)
    r.Undo_EndBlock("FX DEVICES: " .. str, -1)
end

function Curve_3pt_Bezier(startX, startY, controlX, controlY, endX, endY, Segment)
    local X, Y = {}, {}
    local rpt = Segment
    for t = 0, 1, 0.1 do
        local x = (1 - t) * (1 - t) * startX + 2 * (1 - t) * t * controlX + t * t * endX
        local y = (1 - t) * (1 - t) * startY + 2 * (1 - t) * t * controlY + t * t * endY
        
        table.insert(X, x)
        table.insert(Y, y)
    end
    return X, Y
end

function GetTrkSavedInfo(str, track, type)
    if type == 'str' then
        local o = select(2, r.GetSetMediaTrackInfo_String(track or LT_Track, 'P_EXT: ' .. str, '', false))
        if o == '' then o = nil end
        return o
    else
        return tonumber(select(2, r.GetSetMediaTrackInfo_String(track or LT_Track, 'P_EXT: ' .. str, '', false)))
    end
end

function getProjSavedInfo(str, type)
    if type == 'str' then
        return select(2, r.GetProjExtState(0, 'FX Devices', str))
    else
        return tonumber(select(2, r.GetProjExtState(0, 'FX Devices', str)))
    end
end

function Normalize_Val(V1, V2, ActualV, Bipolar)
    local Range = math.abs((math.max(V1, V2) - math.min(V1, V2)))

    local NormV = (math.min(V1, V2) + Range - ActualV) / Range

    if Bipolar then
        return -1 + (NormV) * 2
    else
        return NormV
    end
end

---@param FX_Name string
function ChangeFX_Name(FX_Name)
    if FX_Name then
        local FX_Name = FX_Name:gsub("%w+%:%s+",
            {
                ['AU: '] = "",
                ['JS: '] = "",
                ['VST: '] = "",
                ['VSTi: '] = "",
                ['VST3: '] = '',
                ['VST3i: '] = "",
                ['CLAP: '] = "",
                ['CLAPi: '] = ""
            })
        local FX_Name = FX_Name:gsub('[%:%[%]%/]', "_")
        return FX_Name
    end
end

function Find_FxID_By_GUID (GUID)
    --[[ for i = 0 , Sel_Track_FX_Count, 1 do 
       local guid = r.TrackFX_GetFXGUID (LT_Track, i )
       local  _, ct=  r.TrackFX_GetNamedConfigParm(LT_Track, i, 'container_count')
        if ct ~= '' then 

        end
      
       if GUID == guid then return i end 
    end ]]




    local function children(tb)
        if tb.children then 

            for i, v in ipairs(tb.children)do 

                if v.GUID == GUID then 

                    return v.addr_fxid
                end

            end
            for i, v in ipairs(tb.children)do 
                if v.children then 
                    children(v.children)
                end
            end
        end
    end

    for i , v in pairs(TREE) do 

        if v.GUID == GUID then 
            return i-1 
        end
        local out = children(v)
        if out then return out end 
    end
end


---@param enable boolean
---@param title string
function MouseCursorBusy(enable, title)
    mx, my = r.GetMousePosition()

    local hwnd = r.JS_Window_FindTop(title, true)
    local hwnd = r.JS_Window_FromPoint(mx, my)

    if enable then -- set cursor to hourglass
        r.JS_Mouse_SetCursor(Invisi_Cursor)
        -- block app from changing mouse cursor
        r.JS_WindowMessage_Intercept(hwnd, "WM_SETCURSOR", false)
    else -- set cursor to arrow
        r.JS_Mouse_SetCursor(r.JS_Mouse_LoadCursor(32512))
        -- allow app to change mouse cursor
    end
end

function ConcatPath(...)
    -- Get system dependent path separator
    local sep = package.config:sub(1, 1)
    -- Concatenate the path components
    local path = table.concat({ ... }, sep)
    -- Replace double slashes with a single slash
    path = path:gsub(sep .. sep, sep)
    return path
end

---@param Input number
---@param Min number
---@param Max number
---@return number
function SetMinMax(Input, Min, Max)
    if Input >= Max then
        Input = Max
    elseif Input <= Min then
        Input = Min
    else
        Input = Input
    end
    return Input
end

---@param str string
function get_aftr_Equal(str)
    if str then
        local o = str:sub((str:find('=') or -2) + 2)
        if o == '' or o == ' ' then o = nil end
        return o
    end
end

---@param Str string
---@param Id string
---@param Fx_P integer
---@param Type? "Num"|"Bool"
---@param untilwhere? integer
function RecallInfo(Str, Id, Fx_P, Type, untilwhere)
    if Str then



        local Out, LineChange, ID
        if not Fx_P then
             ID = Id.. ' = ' 
        else     
             ID = Fx_P .. '%. ' .. Id .. ' = '
        end
        local Start, End = Str:find(ID)


        
        if untilwhere then
            LineChange = Str:find(untilwhere, Start)
        else
            LineChange = Str:find('\n', Start)
        end
        if End and Str and LineChange then
            if Type == 'Num' then
                Out = tonumber(string.sub(Str, End + 1, LineChange - 1))
            elseif Type == 'Bool' then
                if string.sub(Str, End + 1, LineChange - 1) == 'true' then Out = true else Out = false end
            else
                Out = string.sub(Str, End + 1, LineChange - 1)
            end
        end
        if Out == '' then Out = nil end

        
        

       return Out
         
    end
end


function extractSpecificPrmProperty(Str, Fx_P, Id, Type)
    -- Create a pattern that matches the exact "Prm [prmNum]" without confusing it with larger numbers like "Prm 13"
   --[[  local pattern = "-----------------Prm%s+" .. Fx_P .. "-----------------%s+" .. Fx_P .. "%.%s+" .. Id .. "%s*=%s*([^\n]+)"
    
    -- Use string.match to find the first match of the pattern in the text
    local value = string.match(Str, pattern)

    if Type == 'Num' then
        return  tonumber(value)
    elseif Type == 'Bool' then
        if value == 'true' then return true else return  false end
        
    else
        return  value
    end ]]
    
end

function extract_prm_sections(text, Fx_P)

    local start = '-----------------Prm ' ..Fx_P.. '-----------------\n'

    local END = '-----------------Prm ' ..(Fx_P+1)..'-----------------\n'

    -- Find positions for the exact section
    local stPos, stEnd = text:find(start, 1 , true )

    if not stPos then
        return nil -- If the start is not found, return nil
    end


    local edPos, edEnd = text:find(END, stPos + #start, true)


    if not edPos then
        -- If the next Prm is not found, return till the end of the text
        return text:sub(stPos)
    end

    -- Return the exact substring between the start and the end
    return text:sub(stPos, edPos - 1)
end

---@param Str string
---@param ID string
---@param Type? "Num"|"Bool"
---@param untilwhere? integer
function RecallGlobInfo(Str, ID, Type, untilwhere)
    if Str then
        local Out, LineChange
        local Start, End = Str:find(ID)

        if untilwhere then
            LineChange = Str:find(untilwhere, Start)
        else
            LineChange = Str:find('\n', Start)
        end
        if End and Str and LineChange then
            if Type == 'Num' then
                Out = tonumber(string.sub(Str, End + 1, LineChange - 1))
            elseif Type == 'Bool' then
                if string.sub(Str, End + 1, LineChange - 1) == 'true' then Out = true else Out = false end
            else
                Out = string.sub(Str, End + 1, LineChange - 1)
            end
        end
        if Out == '' then Out = nil end
        return Out
    end
end

---@param Str string|nil
---@param Id string
---@param Fx_P integer
---@param Type? "Num"|"Bool"
---@return string[]|nil
function RecallIntoTable(Str, Id, Fx_P, Type)
    if Str then
        local _, End = Str:find(Id)
        local T = {}
        while End do
            local NextLine = Str:find('\n', End)
            local EndPos
            local NextSep = Str:find('|', End)
            if NextSep and NextLine then
                if NextSep > NextLine then
                    End = nil
                else
                    if Type == 'Num' then
                        table.insert(T, tonumber(Str:sub(End + 1, NextSep - 1)))
                    else
                        table.insert(T, Str:sub(End + 1, NextSep - 1))
                    end

                    _, NewEnd = Str:find('|%d+=', End + 1)
                    if NewEnd then
                        if NewEnd > NextLine then End = nil else End = NewEnd end
                    else
                        End = nil
                    end
                end
            else
                End = nil
            end
        end
        if T[1] then return T end
    end
end

---@param str string|nil
function get_aftr_Equal_bool(str)
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
function get_aftr_Equal_Num(str, Title)
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

---@param str string
function OnlyNum(str)
    return tonumber(str:gsub('[%D%.]', ''))
end

---@param filename string
---@return string[]
function get_lines(filename)
    local lines = {}
    -- io.lines returns an iterator, so we need to manually unpack it into an array
    for line in io.lines(filename) do
        lines[#lines + 1] = line
    end
    return lines
end

---@generic T
---@generic Index
---@param Table table<Index, T>
---@param Pos1 Index
---@param Pos2 Index
---@return table<Index,T> Table
function TableSwap(Table, Pos1, Pos2)
    Table[Pos1], Table[Pos2] = Table[Pos2], Table[Pos1]
    return Table
end

---@generic T
---@generic Index
---@param tab table<Index, T>
---@param el T
---@return Index|nil
function tablefind(tab, el)
    
    if tab and type(tab) == 'table' then
        
        for index, value in pairs(tab) do
            if value == el then
                return index
            end
        end
    end
end


function Determine_Long_Or_Short_Click(trigger, MouseBtnHeld, Dur)
    if trigger then 

        Long_Or_Short_Click_Time_Start = im.GetTime(ctx)
    end

    if not MouseBtnHeld and Long_Or_Short_Click_Time_Start  then    

        if  Long_Or_Short_Click_Time_Start + Dur < im.GetTime(ctx) then 

            return 'Long'
        elseif Long_Or_Short_Click_Time_Start + Dur > im.GetTime(ctx) then 

            return 'Short'
        else 
        end
    end
end

function SplitDrawlist(splitter, layer)
   --[[  if  im.ValidatePtr(splitter, 'ImGui_DrawListSplitter*') then  ]]
        im.DrawListSplitter_SetCurrentChannel(splitter, layer)
    --[[ end ]]
end

---@param directory string path to directory
---@return table
function scandir(directory)
    local Files = {}
    for i = 0, 999, 1 do
        local F = r.EnumerateFiles(directory, i)

        if F and F ~= '.DS_Store' then table.insert(Files, F) end

        if not F then return Files end
    end

    --return F ---TODO should this be Files instead of F ?
end

---@param str string
---@param DecimalPlaces number
function RoundPrmV(str, DecimalPlaces)
    local A = tostring('%.' .. DecimalPlaces .. 'f')
    --local num = tonumber(str:gsub('[^%d%.]', '')..str:gsub('[%d%.]',''))
    local otherthanNum = str:gsub('[%d%.]', '')
    local num = str:gsub('[^%d%.]', '')
    return string.format(A, tonumber(num) or 0) .. otherthanNum
end

---@param str string
function StrToNum(str)
    return str:gsub('[^%p%d]', '')
end


---@param num number
---@param multipleOf number
---@return number
function roundUp(num, multipleOf)
    return math.floor((num + multipleOf / 2) / multipleOf) * multipleOf;
end

---@generic T
---@param Table table<string, T>
---@param V T
---@return boolean|nil
---@return T[]|nil
function FindStringInTable(Table, V) ---TODO isn’t this a duplicate of FindExactStringInTable ?  -- this one uses string:find whereas exact uses ==
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

---@generic T
---@param Table table<string, T>
---@param V T
---@return boolean|nil
---@return T[]|nil
function FindExactStringInTable(Table, V)
    local found = nil
    local Tab = {}
    local index
    if V and Table then
        for i, val in pairs(Table) do
            if val == V then
                found = true
                table.insert(Tab, i)
                index = i 
            end
            
        end
        if found == true then return true, Tab, index else return false end
    else
        return nil
    end
end

function Vertical_FX_Name(name)
    local Name = ChangeFX_Name(name)
    local Name = Name:gsub('%S+', { ['Valhalla'] = "", ['FabFilter'] = "" })
    local Name = Name:gsub('-', '|')
    local Name_V = Name:gsub("(.)", "%1\n")
    return Name_V:gsub("%b()", "")
end

---@param num number|nil|string
---@param numDecimalPlaces number
---@return number|nil
function round(num, numDecimalPlaces)
    num = tonumber(num)
    if num then
        local mult = 10 ^ (numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end
end

StringToBool = { ['true'] = true, ['false'] = false }

---@generic T
---@param tab table<string, T>
---@param val T
---@return boolean
function has_value(tab, val)
    local found = false
    for index, value in pairs(tab) do
        if value == val then
            found = true
        end
    end
    if found == true then
        return true
    else
        return false
    end
end

---@generic T
---@param t T[]
---@return T[]|nil
function findDuplicates(t)
    local seen = {}       --keep record of elements we've seen
    local duplicated = {} --keep a record of duplicated elements
    if t then
        for i, v in ipairs(t) do
            local element = t[i]
            if seen[element] then          --check if we've seen the element before
                duplicated[element] = true --if we have then it must be a duplicate! add to a table to keep track of this
            else
                seen[element] = true       -- set the element to seen
            end
        end
        if #duplicated > 1 then
            return duplicated
        else
            return nil
        end
    end
end

--------------ImGUI Related ---------------------

---@param FX_Idx integer
---@param FxGUID string
function SaveDrawings(FX_Idx, FxGUID)
    local dir_path = ConcatPath(CurrentDirectory, 'src', 'FX Layouts')
    local FX_Name = ChangeFX_Name(FX_Name)

    local file_path = ConcatPath(dir_path, FX_Name .. '.ini')
    -- Create directory for file if it doesn't exist
    r.RecursiveCreateDirectory(dir_path, 0)
    local file = io.open(file_path, 'r+')

    local D = FX[FxGUID].Draw

    if file and D then
        local content = file:read("*a")

        if string.find(content, '========== Drawings ==========') then
            file:seek('set', string.find(content, '========== Drawings =========='))
        else
            file:seek('end')
        end
        local function write(Name, Value, ID)
            if ID then
                file:write('D' .. ID .. '. ' .. Name, ' = ', Value or '', '\n')
            else
                file:write(Name, ' = ', Value or '', '\n')
            end
        end
        if D then
            file:write('\n========== Drawings ==========\n')
            write('Default Drawing Edge Rounding', FX[FxGUID].Draw.Df_EdgeRound)
            file:write('\n')
        end
        write('Total Number of Drawings', #D)

        for i, Type in ipairs(D) do
            D[i] = D[i] or {}
            local D = FX[FxGUID].Draw[i]
            write('Type', D.Type, i)
            write('Left', D.L, i)
            write('Right', D.R, i)
            write('Top', D.T, i)
            write('Bottom', D.B, i)
            write('Color', D.clr, i)
            write('Text', D.Txt, i)
            write('ImagePath', D.BgImgFileName, i)
            write('KeepImgRatio', tostring(D.KeepImgRatio), i)
            file:write('\n')
        end
    end
end

---@param time number
function HideCursor(time)
    if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
        Invisi_Cursor = r.JS_Mouse_LoadCursorFromFile(r.GetResourcePath() .. '/Cursors/Empty Cursor.cur')
    end
    mx, my = r.GetMousePosition()
    window = r.JS_Window_FromPoint(mx, my)
    release_time = r.time_precise() + (time or 1) -- hide/freeze mouse for 3 secs.

    local function Hide()
        if r.time_precise() < release_time then
            r.JS_Mouse_SetPosition(mx, my)
            r.JS_Mouse_SetCursor(Invisi_Cursor)

            r.defer(Hide)
        else
            r.JS_WindowMessage_Release(window, "WM_SETCURSOR")
        end
    end
    --[[ r.JS_WindowMessage_Intercept(window, "WM_SETCURSOR", false)
        release_time = r.time_precise() + 3 ]]

    Hide()
end

function GetAllInfoNeededEachLoop()
    TimeEachFrame = im.GetDeltaTime(ctx)
    
    if ImGUI_Time == nil then ImGUI_Time = 0 end
    ImGUI_Time             = ImGUI_Time + TimeEachFrame
    _, TrkName             = r.GetTrackName(LT_Track)

    Wheel_V, Wheel_H       = im.GetMouseWheel(ctx)
    LT_Track               = r.GetLastTouchedTrack()
    IsAnyMouseDown         = im.IsAnyMouseDown(ctx)
    LBtn_MousdDownDuration = im.GetMouseDownDuration(ctx, 0)
    LBtnRel                = im.IsMouseReleased(ctx, 0)
    RBtnRel                = im.IsMouseReleased(ctx, 1)
    IsLBtnClicked          = im.IsMouseClicked(ctx, 0)
    LBtnClickCount         = im.GetMouseClickedCount(ctx, 0)
    IsLBtnHeld             = im.IsMouseDown(ctx, 0)
    IsRBtnHeld             = im.IsMouseDown(ctx, 1)
    Mods                   = im.GetKeyMods(ctx) -- Alt = 4  shift =2  ctrl = 1  Command=8
    IsRBtnClicked          = im.IsMouseClicked(ctx, 1)
    LT_FXGUID              = r.TrackFX_GetFXGUID(LT_Track or r.GetTrack(0, 0),
        LT_FX_Number or 0)
    TrkID                  = r.GetTrackGUID(LT_Track or r.GetTrack(0, 0))
    Sel_Track_FX_Count     = r.TrackFX_GetCount(LT_Track)
    LBtnDrag               = im.IsMouseDragging(ctx, 0)
    RBtnDrag               = im.IsMouseDragging(ctx, 1)
    LBtnDC                 = im.IsMouseDoubleClicked(ctx, 0)
end



function GetFocusedWindow()
    local hwnd = r.JS_Window_FromPoint(r.GetMousePosition())
    local focused_window = r.JS_Window_GetTitle(hwnd)
    return focused_window, hwnd
end

function HideCursorTillMouseUp(MouseBtn, triggerKey)
    if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
        Invisi_Cursor = r.JS_Mouse_LoadCursorFromFile(r.GetResourcePath() .. '/Cursors/Empty Cursor.cur')
    end

    if MouseBtn then
        if im.IsMouseClicked(ctx, MouseBtn) then
            MousePosX_WhenClick, MousePosY_WhenClick = r.GetMousePosition()
        end
    elseif triggerKey then
        if im.IsKeyPressed(ctx, triggerKey, false) then
            MousePosX_WhenClick, MousePosY_WhenClick = r.GetMousePosition()
        end
    end

    if MousePosX_WhenClick then
        window = r.JS_Window_FromPoint(MousePosX_WhenClick, MousePosY_WhenClick)

        r.JS_Mouse_SetCursor(Invisi_Cursor)

        local function Hide()
            if MouseBtn then
                if im.IsMouseDown(ctx, MouseBtn) then
                    im.SetMouseCursor(ctx, im.MouseCursor_None)
                    r.defer(Hide)
                else
                    r.JS_WindowMessage_Release(window, "WM_SETCURSOR")
                    if im.IsMouseReleased(ctx, MouseBtn) then
                        r.JS_Mouse_SetPosition(MousePosX_WhenClick, MousePosY_WhenClick)
                    end
                end
            elseif triggerKey then
                if im.IsKeyDown(ctx, triggerKey) then
                    im.SetMouseCursor(ctx, im.MouseCursor_None)
                    r.defer(Hide)
                else
                    r.JS_WindowMessage_Release(window, "WM_SETCURSOR")
                    if im.IsKeyReleased(ctx, triggerKey) then
                        r.JS_Mouse_SetPosition(MousePosX_WhenClick, MousePosY_WhenClick)
                    end
                end
            end
        end
        -- r.JS_Mouse_SetCursor(Invisi_Cursor)

        Hide()
    end
end

function GetMouseDelta(MouseBtn, triggerKey)
    MouseDelta = MouseDelta or {}
    local M = MouseDelta
    if MouseBtn then
        if im.IsMouseClicked(ctx, MouseBtn) then
            M.StX, M.StY = r.GetMousePosition()
        end
    end

    if triggerKey then
        if im.IsKeyPressed(ctx, triggerKey, false) then
            M.StX, M.StY = r.GetMousePosition()
        end
    end

    M.X_now, M.Y_now = r.GetMousePosition()


    if M.StX ~= M.X_now or M.StY ~= M.Y_now then
        local outX, outY = M.X_now - M.StX, M.StY - M.Y_now

        if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
        else
            outY = -outY
        end

        M.StX, M.StY = r.GetMousePosition()
        return outX, outY
    else
        return 0, 0
    end
end

---Same Line
---@param xpos? number offset_from_start_xIn
---@param pad? number spacingIn
function SL(xpos, pad)
    im.SameLine(ctx, xpos, pad)
end

---@param Fx_P integer fx parameter index
---@param FxGUID string
---@param Shape "Circle"|"Rect"
---@param L number p_min_x
---@param T number p_min_y
---@param R? number p_max_x
---@param B? number p_max_y
---@param Rad? number radius
function IfTryingToAddExistingPrm(Fx_P, FxGUID, Shape, L, T, R, B, Rad)
    if Fx_P .. FxGUID == TryingToAddExistingPrm then
        if r.time_precise() > TimeNow and r.time_precise() < TimeNow + 0.1 or r.time_precise() > TimeNow + 0.2 and r.time_precise() < TimeNow + 0.3 then
            if Shape == 'Circle' then
                im.DrawList_AddCircleFilled(FX.DL, L, T, Rad, 0x99999950)
            elseif Shape == 'Rect' then
                local L, T = im.GetItemRectMin(ctx)
                im.DrawList_AddRectFilled(FX.DL, L, T, R, B, 0x99999977, Rounding)
            end
        end
    end
    if Fx_P .. FxGUID == TryingToAddExistingPrm_Cont then
        local L, T = im.GetItemRectMin(ctx)
        if Shape == 'Circle' then
            im.DrawList_AddCircleFilled(FX.DL, L, T, Rad, 0x99999950)
        elseif Shape == 'Rect' then
            im.DrawList_AddRectFilled(FX.DL, L, T, R, B, 0x99999977, Rounding)
        end
    end
end

---@param FxGUID string
---@param FX_Idx integer
---@param LT_Track MediaTrack
---@param PrmCount integer
function RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track, PrmCount)
    local _, FXsBL = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID, '', false)
    rv, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
    local Nm = ChangeFX_Name(FX_Name)
    FX[FxGUID] = FX[FxGUID] or {}
    FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
    if FXsBL == 'Has Blacklist saved to FX' then -- if there's FX-specific BL settings
        --restore FX specific Blacklist settings
        for i = 0, PrmCount - 4, 1 do
            FX[FxGUID].PrmList[i] = FX[FxGUID].PrmList[i] or {}
            _, FX[FxGUID].PrmList[i].BL = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID .. i,
                '',
                false)
            if FX[FxGUID].PrmList[i].BL == 'Blacklisted' then FX[FxGUID].PrmList[i].BL = true else FX[FxGUID].PrmList[i].BL = nil end
        end
    else                         --if there's no FX-specific BL settings saved
        local _, whether = r.GetProjExtState(0, 'FX Devices - Preset Morph', 'Whether FX has Blacklist' .. (Nm or ''))
        if whether == 'Yes' then -- if there's Project-specific BL settings
            for i = 0, PrmCount - 4, 1 do
                FX[FxGUID].PrmList[i] = FX[FxGUID].PrmList[i] or {}
                ---@type integer, string|number|nil
                local rv, BLprm       = r.GetProjExtState(0, 'FX Devices - Preset Morph', Nm .. ' Blacklist ' .. i)
                if BLprm ~= '' then
                    BLprm = tonumber(BLprm)
                    FX[FxGUID].PrmList[BLprm] = FX[FxGUID].PrmList[BLprm] or {}
                    FX[FxGUID].PrmList[BLprm].BL = true
                else
                end
            end
        else -- Check if need to restore Global Blacklist settings
            file, file_path = CallFile('r', Nm .. '.ini', 'Preset Morphing')
            if file then
                local L = get_lines(file_path)
                for i, V in ipairs(L) do
                    local Num = get_aftr_Equal_Num(V)

                    FX[FxGUID].PrmList[Num] = {}
                    FX[FxGUID].PrmList[Num].BL = true
                end
                file:close()
            end
        end
    end
end

-------- FX Related --------

function AddMacroJSFX(FXname, InsertPos)
    local name = FXname or 'FXD Macros'
    local pos = InsertPos or 0

    local MacroGetLT_Track = r.GetLastTouchedTrack()
    local MacrosJSFXExist = r.TrackFX_AddByName(MacroGetLT_Track, name, 0--[[RecFX]], pos)


    ---!!!! need to write DIY trk ID ----
    if MacrosJSFXExist == -1 then
        r.gmem_attach('ParamValues')
        r.gmem_write(1, PM.DIY_TrkID[TrkID])
        r.TrackFX_AddByName(MacroGetLT_Track, name, 0, (-1000-pos))
        r.TrackFX_Show(MacroGetLT_Track, 0, 2)
        return false
    else
        return true
    end
end




function GetLTParam()
    LT_Track = r.GetLastTouchedTrack()
    retval, LT_Prm_TrackNum, LT_FXNum, LT_ParamNum = r.GetLastTouchedFX()
    --GetTrack_LT_Track = r.GetTrack(0,LT_TrackNum)

    if LT_Track ~= nil then
        retval, LT_FXName = r.TrackFX_GetFXName(LT_Track, LT_FXNum)
        retval, LT_ParamName = r.TrackFX_GetParamName(LT_Track, LT_FXNum, LT_ParamNum)
    end
end

function GetLT_FX_Num()
    retval, LT_Prm_TrackNum, LT_FX_Number, LT_ParamNum = r.GetLastTouchedFX()
    LT_Track = r.GetLastTouchedTrack()
end

---@param FxGUID string
function GetProjExt_FxNameNum(FxGUID)
    local PrmCount
    rv, PrmCount = r.GetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID)
    if PrmCount ~= '' then FX.Prm.Count[FxGUID] = tonumber(PrmCount) end
    FX[FxGUID] = FX[FxGUID] or {}

    if rv ~= 0 then
        for P = 1, FX.Prm.Count[FxGUID], 1 do
            FX[FxGUID][P] = FX[FxGUID][P] or {}
            local FP = FX[FxGUID][P]
            if FP then
                _, FP.Name = r.GetProjExtState(0, 'FX Devices', 'FX' .. P .. 'Name' .. FxGUID)
                _, FP.Num = r.GetProjExtState(0, 'FX Devices', 'FX' .. P .. 'Num' .. FxGUID); FP.Num = tonumber(FP.Num)
            end
        end
    end
end

---@param LT_Track MediaTrack
---@param FX_Idx integer
function openFXwindow(LT_Track, FX_Idx)
    FX.Win.FocusState = r.TrackFX_GetOpen(LT_Track, FX_Idx)
    if FX.Win.FocusState == false then
        r.TrackFX_Show(LT_Track, FX_Idx, 3)
    elseif FX.Win.FocusState == true then
        r.TrackFX_Show(LT_Track, FX_Idx, 2)
    end
end

---@param LT_Track MediaTrack
---@param FX_Idx integer
function ToggleBypassFX(LT_Track, FX_Idx)
    FX.Enable = FX.Enable or {}
    FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
    if FX.Enable[FX_Idx] == true then
        r.TrackFX_SetEnabled(LT_Track, FX_Idx, false)
    elseif FX.Enable[FX_Idx] == false then
        r.TrackFX_SetEnabled(LT_Track, FX_Idx, true)
    end
end


---TODO I think Position is meant to be used as «instantiate» variable, is this the intent?
---@param track MediaTrack
---@param fx_name string
---@param Position integer
function AddFX_HideWindow(track, fx_name, Position)
    local val = r.SNM_GetIntConfigVar("fxfloat_focus", 0)
    if val & 4 == 0 then
        return r.TrackFX_AddByName(track, fx_name, 0, Position)   -- add fx
    else
        r.SNM_SetIntConfigVar("fxfloat_focus", val & (~4)) -- temporarily disable Auto-float newly created FX windows
        local out = r.TrackFX_AddByName(track, fx_name, 0, Position)   -- add fx
        r.SNM_SetIntConfigVar("fxfloat_focus", val|4)      -- re-enable Auto-float
        return out
    end
end

---@param FX_Idx integer
---@return integer|nil
function ToggleCollapseAll(FX_Idx)
    -- check if all are collapsed
    local All_Collapsed
    for i = 0, Sel_Track_FX_Count - 1, 1 do
        if not FX[FXGUID[i]].Collapse then All_Collapsed = false end
    end
    if All_Collapsed == false then
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            FX[FXGUID[i]].Collapse = true
            FX[FXGUID[i]].Width_Collapse = COLLAPSED_FX_WIDTH
        end
    else -- if all is collapsed
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            FX[FXGUID[i]].Collapse = false
            FX[FXGUID[i]].Width_Collapse = nil
        end
        BlinkFX = FX_Idx
    end
    return BlinkFX
end

---@param FXGUID string
---@param FX_Idx integer

function DeleteAllParamOfFX(FXGUID, TrkID)
    for p, v in pairs(Trk.Prm.FXGUID) do
        if Trk.Prm.FXGUID[p] == FXGUID and FXGUID ~= nil then
            Trk.Prm.Inst[TrkID] = Trk.Prm.Inst[TrkID] - 1
            Prm.Num[p] = nil
            PM.HasMod[p] = nil

            r.SetProjExtState(0, 'FX Devices', 'Params fxGUID of Param Inst' .. p, '')
        elseif Trk.Prm.FXGUID[p] == nil and FXGUID == nil then

        end
    end
end
function Check_If_Its_Root_of_Parallel(FX_Idx_to_Check) -- if it is, set the next fx to no be parallel with previous fx
    for i, v in ipairs(PAR_FXs)do 

        if FX_Idx_to_Check == v[1]-1 and FX_Idx_to_Check > 0 then 
            return true 
        end

    end
end


---@param FX_Idx integer
function DeleteFX(FX_Idx, FxGUID)
    local DelFX_Name

   --[[  if Check_If_Its_Root_of_Parallel(FX_Idx) then 
        local nextFX, PrevFX = GetNextAndPreviousFXID(FX_Idx)
        r.TrackFX_SetNamedConfigParm(LT_Track, nextFX, 'parallel', '0')
    end ]]

    r.Undo_BeginBlock()
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. (tablefind(Trk[TrkID].PreFX, FxGUID) or ''), '', true)
    --r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX '..(tablefind (Trk[TrkID].PostFX, FxGUID) or ''), '', true)

    if tablefind(Trk[TrkID].PreFX, FxGUID) then
        DelFX_Name = 'FX in Pre-FX Chain'
        table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FxGUID))
    end

    if tablefind(Trk[TrkID].PostFX, FxGUID) then
        table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FxGUID))
        for i = 1, #Trk[TrkID].PostFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
        end
    end

    if FX[FxGUID].InWhichBand then -- if FX is in band split
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            if FX[FXGUID[i]].FXsInBS then
                if tablefind(FX[FXGUID[i]].FXsInBS, FxGUID) then
                    table.remove(FX[FXGUID[i]].FXsInBS, tablefind(FX[FXGUID[i]].FXsInBS, FxGUID))
                end
            end
        end
    end

    DeleteAllParamOfFX(FxGUID, TrkID)



    if FX_Name:find('Pro Q 3') ~= nil and not FXinPost and not FXinPre then
        r.TrackFX_Delete(LT_Track, FX_Idx)
        r.TrackFX_Delete(LT_Track, FX_Idx - 1)
        DelFX_Name = 'Pro Q 3'
    elseif FX_Name:find('Pro C 2') ~= nil and not FXinPost and not FXinPre then
        DelFX_Name = 'Pro C 2'
        r.TrackFX_Delete(LT_Track, FX_Idx + 1)
        r.TrackFX_Delete(LT_Track, FX_Idx)
        r.TrackFX_Delete(LT_Track, FX_Idx - 1)
    else
        r.TrackFX_Delete(LT_Track, FX_Idx)
    end
    
    if Trk[TrkID].Container_Id then 
        local rv, Tab, id   = FindExactStringInTable(Trk[TrkID].Container_Id , FxGUID)  
        if rv then 
            table.remove(Trk[TrkID].Container_Id, id)
        end
    end 


    TREE = BuildFXTree(LT_Track)
    for i, v in ipairs(PAR_FXs) do 

    end

    r.Undo_EndBlock('Delete ' .. (DelFX_Name or 'FX'), 0)
end

---@param ShowAlreadyAddedPrm boolean
---@return boolean|unknown
function IsPrmAlreadyAdded(ShowAlreadyAddedPrm)
    GetLTParam()
    local FX_Count = r.TrackFX_GetCount(LT_Track); local RptPrmFound
    local F = FX[LT_FXGUID] or {}

    if F then
        for i, v in ipairs(F) do
            if FX[LT_FXGUID][i].Num == LT_ParamNum then
                RptPrmFound = true

                if ShowAlreadyAddedPrm then
                    TryingToAddExistingPrm = i .. LT_FXGUID
                    TimeNow = r.time_precise()
                end
            end
        end
        --[[ if not RptPrmFound and LT_FXGUID then
                StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum, true )
            end ]]
    end
    return RptPrmFound
end

---@param FxGUID string
---@param Fx_P integer parameter index
---@param FX_Idx integer
function DeletePrm(FxGUID, Fx_P, FX_Idx)
    --LE.Sel_Items[1] = nil

    local FP = FX[FxGUID][Fx_P]
    for i, v in ipairs(FX[FxGUID]) do
        if v.ConditionPrm then
            v.ConditionPrm = nil
        end
    end


    if FP.WhichMODs then
        Trk[TrkID].ModPrmInst = Trk[TrkID].ModPrmInst - 1
        FX[FxGUID][Fx_P].WhichCC = nil
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' .. FP.Num, '', true)

        FX[FxGUID][Fx_P].WhichMODs = nil
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods', '',
            true)
    end
    
    for Mc = 1, 8, 1 do
        if FP.ModAMT then
            if FP.ModAMT[Mc] then
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num .. ".plink.active", 0) -- 1 active, 0 inactive
                FP.ModAMT[Mc] = nil
            end
        end
    end

    table.remove(FX[FxGUID], Fx_P)
    if Trk.Prm.Inst[TrkID] then
        Trk.Prm.Inst[TrkID] = Trk.Prm.Inst[TrkID] - 1
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Trk Prm Count', Trk.Prm.Inst[TrkID], true)
    end


    for i, v in ipairs(FX[FxGUID]) do
        r.SetProjExtState(0, 'FX Devices', 'FX' .. i .. 'Name' .. FxGUID, FX[FxGUID][i].Name)
        r.SetProjExtState(0, 'FX Devices', 'FX' .. i .. 'Num' .. FxGUID, FX[FxGUID][i].Num)
    end
    r.SetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID, #FX[FxGUID])
    -- Delete Proj Ext state data!!!!!!!!!!
end

function SyncTrkPrmVtoActualValue()
    for FX_Idx = 0, Sel_Track_FX_Count, 1 do                 ---for every selected FX in cur track
        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx) ---get FX’s GUID
        if FxGUID then
            FX[FxGUID] = FX[FxGUID] or {}                    ---create new params table for FX if it doesn’t exist
            for Fx_P = 1, #FX[FxGUID] or 0, 1 do             ---for each param
                if TrkID then
                    if not FX[FxGUID][Fx_P].WhichMODs then
                        FX[FxGUID][Fx_P].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FX[FxGUID][Fx_P].Num or 0) ---get param value
                    end
                end
            end
        end
    end
end

function DndAddFX_SRC(fx)
    if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptBeforeDelivery) then
        im.SetDragDropPayload(ctx, 'DND ADD FX', fx)
        im.Text(ctx, fx)
        im.EndDragDropSource(ctx)
    end
end

function DndAddFXfromBrowser_TARGET(Dest, ClrLbl, SpaceIsBeforeRackMixer, SpcIDinPost, FxGUID_Container)
    --if not DND_ADD_FX then return  end
    im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)
    if im.BeginDragDropTarget(ctx) then
        local dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX')


        if dropped then
            local FX_Idx = Dest
            if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end

            r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx, false)
            local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            local _, nm = r.TrackFX_GetFXName(LT_Track, FX_Idx)

            --if in layer
            if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID_RackMixer and SpaceIsBeforeRackMixer == false or AddLastSPCinRack == true then
                DropFXtoLayerNoMove(FXGUID_RackMixer, LyrID, FX_Idx)
            end
            Dvdr.Clr[ClrLbl or ''], Dvdr.Width[TblIdxForSpace or ''] = nil, 0
            if SpcIsInPre then
                if SpaceIsBeforeRackMixer == 'End of PreFX' then
                    table.insert(Trk[TrkID].PreFX, FxID)
                else
                    table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FxID)
                end
                for i, v in pairs(Trk[TrkID].PreFX) do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v,
                        true)
                end
            elseif SpcInPost then
                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
                table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
                -- InsertToPost_Src = FX_Idx + offset+2
                for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
                end
            elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
                FX[FxGUID_Container] = FX[FxGUID_Container] or {}
                DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx, Dest + 1)
            end
            FX_Idx_OpenedPopup = nil
        end
        im.EndDragDropTarget(ctx)
    end
    im.PopStyleColor(ctx)
end



---@param h number
---@param s number
---@param v number
---@param a number
function HSV(h, s, v, a)
    local r, g, b = im.ColorConvertHSVtoRGB(h, s, v)
    return im.ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end




function Execute_Keyboard_Shortcuts(ctx,KB_Shortcut,Command_ID, Mods)
    ----------------- Keyboard Shortcuts ---------------
    if not im.IsAnyItemActive(ctx) then
        for i, v in pairs(KB_Shortcut) do
            if not v:find('+') then --if shortcut has no modifier
                if im.IsKeyPressed(ctx, AllAvailableKeys[v]) and Mods == 0 then
                    --[[ local commandID = r.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND')
                    local CommandTxt =  r.CF_GetCommandText(0, commandID) -- 0 prob means arrange window, it's the section drop down from action window's top right corner
                    r.Main_OnCommand(commandID, 0) ]]
                    if Command_ID[i] then
                        local Cmd_Num = r.NamedCommandLookup(Command_ID[i])
                        r.Main_OnCommand(Cmd_Num, 0)
                    end
                end
            else
                local Mod = 0
                if v:find('Shift') then Mod = Mod + im.Mod_Shift end
                if v:find('Alt') then Mod = Mod + im.Mod_Alt end
                if v:find('Ctrl') then Mod = Mod + im.Mod_Ctrl end
                if v:find('Cmd') then Mod = Mod + im.Mod_Super end


                local rev = v:reverse()
                local lastPlus = rev:find('+')
                local Ltr = rev:sub(1, rev:find('+') - 2)
                local AftrLastPlus = Ltr:reverse()


                if Mods == Mod and im.IsKeyPressed(ctx, AllAvailableKeys[AftrLastPlus]) then
                    if Command_ID[i] then
                        local Cmd_Num = r.NamedCommandLookup(Command_ID[i])
                        r.Main_OnCommand(Cmd_Num, 0)
                    end
                end
            end
        end
    end
end



function HSV_Change(InClr, H, S, V, A)
    local R, g, b, a = im.ColorConvertU32ToDouble4(InClr)

    local h, s, v = im.ColorConvertRGBtoHSV(R, g, b)
    local h, s, v, a = (H or 0) + h, s + (S or 0), v + (V or 0), a + (A or 0)
    local R, g, b = im.ColorConvertHSVtoRGB(h, s, v)
    return im.ColorConvertDouble4ToU32(R, g, b, a)
end

function BlendColors(Clr1, Clr2, pos)
    local R1, G1, B1, A1 = im.ColorConvertU32ToDouble4(Clr1)

    local R2, G2, B2, A2 = im.ColorConvertU32ToDouble4(Clr2)

    local R3 = SetMinMax((R2 - R1) * pos + R1, 0, 1)
    local G3 = SetMinMax((G2 - G1) * pos + G1, 0, 1)
    local B3 = SetMinMax((B2 - B1) * pos + B1, 0, 1)
    local A3 = SetMinMax((A2 - A1) * pos + A1, 0, 1)

    return im.ColorConvertDouble4ToU32(R3, G3, B3, A3)
end

function GetFxGUID_by_FXid (FxGUID)
    for i = 0, r.TrackFX_GetCount(LT_Track) , 1 do 
        local fxguid = r.TrackFX_GetFXGUID(LT_Track, i)

        if fxguid == FxGUID then 
            return i 
        end
    end
end

-- EXAMPLE DRAW (NOTHING TO DO WITH PARSING ALL BELOOW)
---@param s string
function Lead_Trim_ws(s) return s:match '^%s*(.*)' end


function SetMinMax(Input, Min, Max)
   if Input >= Max then
       Input = Max
   elseif Input <= Min then
       Input = Min
   else
       Input = Input
   end
   return Input
end
function PDefer(func)
    r.defer(function()
        local status, err = xpcall(func, debug.traceback)
        if not status then
            PrintTraceback(err)
        end
    end)
end


function DrawChildMenu(tbl, path, FX_Idx)
   path = path or ""
   for i = 1, #tbl do
       if tbl[i].dir then
           if im.BeginMenu(ctx, tbl[i].dir) then
               DrawChildMenu(tbl[i], table.concat({ path, os_separator, tbl[i].dir }), FX_Idx)
               im.EndMenu(ctx)
           end
       end
       if type(tbl[i]) ~= "table" then
           if im.Selectable(ctx, tbl[i], false) then -- TODO for all calls to ImGui_Selectable, let’s pass the third argument as false instead of nil
               if TRACK then
                   r.TrackFX_AddByName(TRACK, table.concat({ path, os_separator, tbl[i] }), false,
                       -1000 - FX_Idx)
               end
           end
       end
   end
end

---@param filter_text string
function Filter_actions(filter_text)
    filter_text = Lead_Trim_ws(filter_text)
    local t = {}
    if filter_text == "" or not filter_text then return t end
    for i = 1, #FX_LIST do
        local action = FX_LIST[i]
        local name = action:lower()
        local found = true
        for word in filter_text:gmatch("%S+") do
            if not name:find(word:lower(), 1, true) then
                found = false
                break
            end
        end

        if found then t[#t + 1] = action end
    end
    return t
end

function Put_FXs_Into_New_Container(FX_Idx, cont, i ) -- i = pos in container

    --local to =  TrackFX_GetInsertPositionInContainer(cont, i  )

    local to 
    local id = FX_Idx 

    local scale = tree[id].scale

    --local cont = cont +1
    local  ct = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, cont, 'container_count')))


    if ct > 0  then 
        to = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, cont, 'container_item.'..(ct-1 )))) + scale
        
    else    -- if container is empty 
        to =  0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + FX_Idx
    end
    r.TrackFX_CopyToTrack(LT_Track, FX_Idx, LT_Track, to , true)

    TREE = BuildFXTree(LT_Track)
    --[[ table.insert( MovFX.FromPos , FX_Idx)
    table.insert( MovFX.ToPos , to ) ]]
end



function FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost, ParallelFX)
    ---@type integer|nil, boolean|nil
    local FX_Idx_For_AddFX, close
    if AddLastSPCinRack then FX_Idx_For_AddFX = FX_Idx - 1 end
    local MAX_FX_SIZE = 250
    local FxGUID = FXGUID[FX_Idx_For_AddFX or FX_Idx]
    im.SetNextItemWidth(ctx, 180)
    _, ADDFX_FILTER = im.InputTextWithHint(ctx, '##input', "SEARCH FX", ADDFX_FILTER,
        im.InputTextFlags_AutoSelectAll)

    if im.IsWindowAppearing(ctx) then
        local tb = FX_LIST
        im.SetKeyboardFocusHere(ctx, -1)
    end

    local filtered_fx = Filter_actions(ADDFX_FILTER)
    --im.SetNextWindowPos(ctx, im.GetItemRectMin(ctx), ({ im.GetItemRectMax(ctx) })[2])
    local filter_h = #filtered_fx == 0 and 2 or (#filtered_fx > 40 and 20 * 17 or (17 * #filtered_fx))
    local function InsertFX(Name)
        local FX_Idx = FX_Idx
        --- CLICK INSERT
        if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end

        r.TrackFX_AddByName(LT_Track, Name, false, -1000 - FX_Idx)

        -- if Inserted into Layer
        local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

        if FX.InLyr[FxGUID] == FXGUID_RackMixer and FX.InLyr[FxGUID] then
            DropFXtoLayerNoMove(FXGUID_RackMixer, LyrID, FX_Idx)
        end
        if SpaceIsBeforeRackMixer == 'SpcInBS' then
            DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx + 1, FX_Idx)
        end
        if SpcIsInPre then
            local inspos = FX_Idx + 1
            if SpaceIsBeforeRackMixer == 'End of PreFX' then
                table.insert(Trk[TrkID].PreFX, FxID)
            else
                table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FxID)
            end
            for i, v in pairs(Trk[TrkID].PreFX) do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v,
                    true)
            end
        elseif SpcInPost then
            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
            table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
            -- InsertToPost_Src = FX_Idx + offset+2
            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
            end
        elseif ParallelFX then 
            r.TrackFX_SetNamedConfigParm( LT_Track, FX_Idx, 'parallel', '1' )

        end

        if Name =='Container' then 
            r.TrackFX_Show(LT_Track, FX_Idx , 2)
        end

        ADDFX_FILTER = nil
    end
    if ADDFX_FILTER ~= '' and ADDFX_FILTER then
        SL()
        im.SetNextWindowSize(ctx, MAX_FX_SIZE, filter_h + 20)
        local x, y = im.GetCursorScreenPos(ctx)

        ParentWinPos_x, ParentWinPos_y = im.GetWindowPos(ctx)
        local VP_R = VP.X + VP.w
        if x + MAX_FX_SIZE > VP_R then x = ParentWinPos_x - MAX_FX_SIZE end

        im.SetNextWindowPos(ctx, x, y - filter_h / 2)
        if im.BeginPopup(ctx, "##popupp", im.WindowFlags_NoFocusOnAppearing --[[ MAX_FX_SIZE, filter_h ]]) then
            ADDFX_Sel_Entry = SetMinMax(ADDFX_Sel_Entry or 1, 1, #filtered_fx)
            for i = 1, #filtered_fx do
                local ShownName
                if filtered_fx[i]:find('VST:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(5, (fx:find('.vst') or 999) - 1)
                    local clr = FX_Adder_VST or
                        CustomColorsDefault
                        .FX_Adder_VST -- TODO I think all these FX_ADDER vars came from FX_ADDER module, which isn’t there anymore. Should we bring it back ?
                    ---if we do have to bring it back, my bad, I thought it was a duplicate of Sexan’s module
                    MyText('VST', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('VSTi:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6, (fx:find('.vsti') or 999) - 1)
                    local clr = FX_Adder_VST or CustomColorsDefault.FX_Adder_VST
                    MyText('VSTi', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('VST3:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6) .. '##vst3'
                    local clr = FX_Adder_VST3 or CustomColorsDefault.FX_Adder_VST3
                    MyText('VST3', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('VST3i:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(7) .. '##vst3i'
                    local clr = FX_Adder_VST3 or CustomColorsDefault.FX_Adder_VST3
                    MyText('VST3i', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('JS:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(4)
                    local clr = FX_Adder_JS or CustomColorsDefault.FX_Adder_JS
                    MyText('JS', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('AU:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(4)
                    local clr = FX_Adder_AU or CustomColorsDefault.FX_Adder_AU
                    MyText('AU', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('CLAP:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6)
                    local clr = FX_Adder_CLAP or CustomColorsDefault.FX_Adder_CLAP
                    MyText('CLAP', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('CLAPi:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(7)
                    local clr = FX_Adder_CLAP or CustomColorsDefault.FX_Adder_CLAP
                    MyText('CLAPi', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('LV2:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(5)
                    local clr = FX_Adder_LV2 or CustomColorsDefault.FX_Adder_LV2
                    MyText('LV2', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end

                if im.Selectable(ctx, (ShownName or filtered_fx[i]) .. '##emptyName', DRAG_FX == i) then
                    if filtered_fx[i] then
                        InsertFX(filtered_fx[i])
                        im.CloseCurrentPopup(ctx)
                        close = true
                    end
                end
                if i == ADDFX_Sel_Entry then
                    HighlightSelectedItem(0xffffff11, nil, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end
                -- DRAG AND DROP
                if im.IsItemActive(ctx) and im.IsMouseDragging(ctx, 0) then
                    -- HIGHLIGHT DRAGGED FX
                    DRAG_FX = i
                    DndAddFX_SRC(filtered_fx[i])
                    --AddFX_Drag(filtered_fx[i]) -- TODO did this come from FX_ADDER
                end
            end

            if im.IsKeyPressed(ctx, im.Key_Enter) then

                InsertFX(filtered_fx[ADDFX_Sel_Entry])
                --r.TrackFX_AddByName(LT_Track, filtered_fx[ADDFX_Sel_Entry], false, -1000 - FX_Idx)
                LAST_USED_FX = filtered_fx[filtered_fx[ADDFX_Sel_Entry]]
                ADDFX_Sel_Entry = nil
                TREE = BuildFXTree(LT_Track)

                im.CloseCurrentPopup(ctx)
                close = true

                --FILTER = ''
                --im.CloseCurrentPopup(ctx)
            elseif im.IsKeyPressed(ctx, im.Key_UpArrow) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry - 1
            elseif im.IsKeyPressed(ctx, im.Key_DownArrow) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry + 1
            end
            --im.EndChild(ctx)
            im.EndPopup(ctx)
        end


        im.OpenPopup(ctx, "##popupp")
        im.NewLine(ctx)
    end


    if im.IsKeyPressed(ctx, im.Key_Escape) then
        im.CloseCurrentPopup(ctx)
        ADDFX_FILTER = nil
    end
    return close
end

function AddFX_Menu(FX_Idx ,LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost, ParallelFX)

    local function DrawFxChains(tbl, path)
        local extension = ".RfxChain"
        path = path or ""
        for i = 1, #tbl do

            if tbl[i].dir then
                if im.BeginMenu(ctx, tbl[i].dir) then
                    DrawFxChains(tbl[i], table.concat({ path, os_separator, tbl[i].dir }))
                    im.EndMenu(ctx)
                end
            end
            if type(tbl[i]) ~= "table" then
                if im.Selectable(ctx, tbl[i]) then
                    if TRACK then
                        r.TrackFX_AddByName(TRACK, table.concat({ path, os_separator, tbl[i], extension }), false,
                            -1000 - FX_Idx)
                    end
                end
                DndAddFX_SRC(table.concat({ path, os_separator, tbl[i], extension }))
            end
        end
    end
    local function LoadTemplate(template, replace)
        local track_template_path = r.GetResourcePath() .. "/TrackTemplates" .. template
        if replace then
            local chunk = GetFileContext(track_template_path)
            r.SetTrackStateChunk(TRACK, chunk, true)
        else
            r.Main_openProject(track_template_path)
        end
    end
    local function DrawTrackTemplates(tbl, path)
        local extension = ".RTrackTemplate"
        path = path or ""
        for i = 1, #tbl do
            if tbl[i].dir then
                if im.BeginMenu(ctx, tbl[i].dir) then
                    local cur_path = table.concat({ path, os_separator, tbl[i].dir })
                    DrawTrackTemplates(tbl[i], cur_path)
                    im.EndMenu(ctx)
                end
            end
            if type(tbl[i]) ~= "table" then
                if im.Selectable(ctx, tbl[i]) then
                    local template_str = table.concat({ path, os_separator, tbl[i], extension })
                    LoadTemplate(template_str) -- ADD NEW TRACK FROM TEMPLATE
                end
            end
        end
    end

    if im.BeginPopup(ctx, 'Btwn FX Windows' .. FX_Idx) then
        local AddedFX
        FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')

        if FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost, ParallelFX) then
            AddedFX = true
            im.CloseCurrentPopup(ctx)
        end -- Add FX Window
        im.SeparatorText(ctx, "PLUGINS")
        for i = 1, #CAT do

            if im.BeginMenu(ctx, CAT[i].name) then
                if CAT[i].name == "FX CHAINS" then
                    DrawFxChains(CAT[i].list)
                elseif CAT[i].name == "TRACK TEMPLATES" then -- THIS IS MISSING
                    DrawTrackTemplates(CAT[i].list)
                else
                    for j = 1, #CAT[i].list do
                        if im.BeginMenu(ctx, CAT[i].list[j].name) then
                            for p = 1, #CAT[i].list[j].fx do
                                if CAT[i].list[j].fx[p] then
                                    if im.Selectable(ctx, CAT[i].list[j].fx[p]) then
                                        if TRACK then
                                            AddedFX = true
                                            r.TrackFX_AddByName(TRACK, CAT[i].list[j].fx[p], false, -1000 - FX_Idx)
                                            LAST_USED_FX = CAT[i].list[j].fx[p]
                                            TREE = BuildFXTree(LT_Track)
                                        end
                                    end
                                end
                            end
                            im.EndMenu(ctx)
                        end
                    end
                end
                im.EndMenu(ctx)
            end
        end
        if im.BeginMenu(ctx, "FXD INSTRUMENTS & EFFECTS") then
            if im.Selectable(ctx, "ReaDrum Machine") then
                local chain_src = "../Scripts/FX Devices/BryanChi_FX_Devices/src/FXChains/ReaDrum Machine.RfxChain"
                local found = false
                count = r.TrackFX_GetCount(TRACK)                                             -- 1 based
                for i = 0, count - 1 do
                    local rv, rename = r.TrackFX_GetNamedConfigParm(TRACK, i, 'renamed_name') -- 0 based
                    if rename == 'ReaDrum Machine' then
                        found = true
                        break
                    end
                end
                if not found then
                    r.Undo_BeginBlock()
                    r.PreventUIRefresh(1)
                    r.TrackFX_AddByName(TRACK, chain_src, false, -1000 - FX_Idx)
                    AddedFX = true
                    r.PreventUIRefresh(-1)
                    EndUndoBlock("ADD DRUM MACHINE")
                end
            end
            DndAddFX_SRC("../Scripts/FX Devices/BryanChi_FX_Devices/src/FXChains/ReaDrum Machine.RfxChain")
            im.EndMenu(ctx)
        end
        TRACK = r.GetSelectedTrack(0, 0)
        if im.Selectable(ctx, "CONTAINER") then
            r.TrackFX_AddByName(TRACK, "Container", false, -1000 - FX_Idx)
            AddedFX = true
            LAST_USED_FX = "Container"
            r.TrackFX_Show(TRACK, FX_Idx , 2)
        end
        DndAddFX_SRC("Container")
        if im.Selectable(ctx, "VIDEO PROCESSOR") then
            r.TrackFX_AddByName(TRACK, "Video processor", false, -1000 - FX_Idx)
            AddedFX = true
            LAST_USED_FX = "Video processor"
        end
        DndAddFX_SRC("Video processor")
        if LAST_USED_FX then
           
            if im.Selectable(ctx, "RECENT: " .. LAST_USED_FX) then
                r.TrackFX_AddByName(TRACK, LAST_USED_FX, false, -1000 - FX_Idx)
                AddedFX = true
            end
        end
        DndAddFX_SRC(LAST_USED_FX)
        im.SeparatorText(ctx, "UTILS")
        if im.Selectable(ctx, 'Add FX Layering', false) then
            local FX_Idx = FX_Idx
            --[[ if FX_Name:find('Pro%-C 2') then FX_Idx = FX_Idx-1 end ]]
            local val = r.SNM_GetIntConfigVar("fxfloat_focus", 0)
            if val & 4 ~= 0 then
                r.SNM_SetIntConfigVar("fxfloat_focus", val & (~4))
            end

            if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 16 then
                r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 16)
            end
            FXRack = r.TrackFX_AddByName(LT_Track, 'FXD (Mix)RackMixer', 0, -1000 - FX_Idx)
            local RackFXGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

            ChanSplitr = r.TrackFX_AddByName(LT_Track, 'FXD Split to 32 Channels', 0,
                -1000 - FX_Idx)
            local SplitrGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            Lyr.SplitrAttachTo[SplitrGUID] = RackFXGUID
            r.SetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. SplitrGUID, RackFXGUID)
            _, ChanSplitFXName = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)

            FX[RackFXGUID] = FX[RackFXGUID] or {}
            FX[RackFXGUID].LyrID = FX[RackFXGUID].LyrID or {}
            table.insert(FX[RackFXGUID].LyrID, 1)
            table.insert(FX[RackFXGUID].LyrID, 2)

            r.SetProjExtState(0, 'FX Devices', 'FX' .. RackFXGUID .. 'Layer ID 1', 1)
            r.SetProjExtState(0, 'FX Devices', 'FX' .. RackFXGUID .. 'Layer ID 2', 2)
            FX[RackFXGUID].ActiveLyrCount = 2

            FX_Layr_Inst = 0
            for F = 0, Sel_Track_FX_Count, 1 do
                local FXGUID = r.TrackFX_GetFXGUID(LT_Track, F)
                local _, FX_Name = r.TrackFX_GetFXName(LT_Track, F)
                if string.find(FX_Name, 'FXD Split to 32 Channels') ~= nil then
                    FX_Layr_Inst                       = FX_Layr_Inst + 1
                    Lyr.SpltrID[FX_Layr_Inst .. TrkID] = r.TrackFX_GetFXGUID(LT_Track,
                        FX_Idx - 1)
                end
            end

            Spltr[SplitrGUID] = Spltr[SplitrGUID] or {}
            Spltr[SplitrGUID].New = true


            if FX_Layr_Inst == 1 then
                --sets input channels to 1 and 2
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 0, 1, 0)
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 1, 2, 0)
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 2, 1, 0)
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 3, 2, 0)
                for i = 2, 16, 1 do
                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, i, 0, 0)
                end
                --sets Output to all channels
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, 0, 21845, 0)
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, 1, 43690, 0)
                for i = 2, 16, 1 do
                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, i, 0, 0)
                end
            elseif FX_Layr_Inst > 1 then

            end




            FX_Idx_OpenedPopup = nil
            im.CloseCurrentPopup(ctx)
            if val & 4 ~= 0 then
                r.SNM_SetIntConfigVar("fxfloat_focus", val|4) -- re-enable Auto-float
            end
        elseif im.Selectable(ctx, 'Add Band Split', false) then
            r.gmem_attach('FXD_BandSplit')
            table.insert(AddFX.Name, 'FXD Saike BandSplitter')
            table.insert(AddFX.Pos, FX_Idx)
            table.insert(AddFX.Name, 'FXD Band Joiner')
            table.insert(AddFX.Pos, FX_Idx + 1)
            if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 12 then -- Set track channels to 10 if it's lower than 10
                r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 12)
            end

            FX_Idx_OpenedPopup = nil
            --r.TrackFX_AddByName(LT_Track, 'FXD Bandjoiner', 0, -1000-FX_Idx)
        end
        --DndAddFX_SRC("FXD Saike BandSplitter")

        Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
        --Dvdr.Clr[ClrLbl] = 0x999999ff

        if IsLBtnClicked then FX_Idx_OpenedPopup = nil end

        if AddedFX then RetrieveFXsSavedLayout(Sel_Track_FX_Count) end



        if CloseAddFX_Popup then
            im.CloseCurrentPopup(ctx)
            CloseAddFX_Popup = nil
        end
        im.EndPopup(ctx)
    else
        Dvdr.Clr[ClrLbl or ''] = 0x131313ff
    end
end

function If_Theres_Pro_C_Analyzers(FX_Name, FX_Idx)
    local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)
    local FxGUID =  r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local FxGUID_Next =  r.TrackFX_GetFXGUID(LT_Track, next_fxidx)
    local FxGUID_Prev =  r.TrackFX_GetFXGUID(LT_Track, previous_fxidx)


    if FX_Name:find('FXD Split to 4 channels') then

        --if FX below is not Pro-C 2
        if NextFX then
            if string.find(NextFX, 'Pro%-C 2') then
                if FX.InLyr[FxGUID_Next] then -- if in layering
                    SyncAnalyzerPinWithFX(FX_Idx, next_fxidx, FX_Name)
                end
            end
        end

    elseif FX_Name:find('FXD Gain Reduction Scope') then
        r.gmem_attach('CompReductionScope')
        if FX[FxGUID_Prev] then
            r.gmem_write(FX[FxGUID_Prev].ProC_ID or 0, previous_fxidx)
        end

        --if FX above is not Pro-C 2
        FX[FxGUID].ProC_Scope_Del_Wait = (FX[FxGUID].ProC_Scope_Del_Wait or 0) + 1

        if FX[FxGUID].ProC_Scope_Del_Wait > FX_Add_Del_WaitTime + 10 then
            if string.find(PreviousFX, 'Pro%-C 2') then
                if FX.InLyr[FxGUID_Prev] then -- if in layering
                    SyncAnalyzerPinWithFX(FX_Idx, previous_fxidx, FX_Name)
                end
            end
            FX[FxGUID].ProC_Scope_Del_Wait = 0
        end

        if FX.InLyr[FxGUID_Prev] then
            FX.InLyr[FxGUID] = FX.InLyr[FxGUID_Prev]
        else
            FX.InLyr[FxGUID] = nil
        end
    end 

end 

function Delete_All_FXD_AnalyzerFX(trk)
    local ct = r.TrackFX_GetCount(trk)
    for i = 0, ct, 1 do
        local _, name = r.TrackFX_GetFXName(trk, i)

        if FindStringInTable(FX_To_Delete_At_Close, name) then
            r.TrackFX_Delete(trk, i)
        end
    end
end

---@param FX_Idx integer
---@param Target_FX_Idx integer
---@param FX_Name string
function SyncAnalyzerPinWithFX(FX_Idx, Target_FX_Idx, FX_Name)
    -- input --
    local Target_L, _ = r.TrackFX_GetPinMappings(LT_Track, Target_FX_Idx, 0, 0) -- L chan
    local Target_R, _ = r.TrackFX_GetPinMappings(LT_Track, Target_FX_Idx, 0, 1) -- R chan
    local L, _ = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)               -- L chan
    local R, _ = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 1)               -- R chan


    if L ~= Target_L then
        if not FX_Name then _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx) end

        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 0, Target_L, 0)


        if FX_Name:find('JS: FXD ReSpectrum') then
            for i = 2, 16, 1 do
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 0, 0)
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, i, 0, 0)
            end
        end


        if FX_Name == 'JS: FXD Split to 4 channels' then
            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 2, Target_R * 2, 0)
        elseif FX_Name == 'JS: FXD Gain Reduction Scope' then
            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 2, Target_R * 2, 0)
        end
    end
    if R ~= Target_R then
        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 1, Target_R, 0)
        if FX_Name == 'JS: FXD Split to 4 channels' then
            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 3, Target_R * 4, 0)
        elseif FX_Name:find('FXD Gain Reduction Scope') then
            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 3, Target_R * 4, 0)
        end
    end



    -- output --
    local Target_L, _ = r.TrackFX_GetPinMappings(LT_Track, Target_FX_Idx, 1, 0) -- L chan
    local Target_R, _ = r.TrackFX_GetPinMappings(LT_Track, Target_FX_Idx, 1, 1) -- R chan
    local L, _ = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 1, 0)               -- L chan
    local R, _ = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 1, 1)               -- R chan
    if L ~= Target_L then
        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 0, Target_L, 0)
    end
    if R ~= Target_R then
        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 1, Target_R, 0)
    end
end

function ChangeAutomationModeByWheel(track)
    if im.IsItemHovered(ctx) and im.GetKeyMods(ctx) == im.Mod_Ctrl then
      local automation_mode = r.GetTrackAutomationMode(track)
      local global_automation = r.GetGlobalAutomationOverride(track)
      window_flag = im.WindowFlags_NoScrollWithMouse
      local v, h = im.GetMouseWheel(ctx)
      if global_automation == -1 then
        automation_mode = automation_mode + v
        if 0 > automation_mode then
          automation_mode = 0
        elseif automation_mode > 5 then
          automation_mode = 5
        end
      automation_mode = round(automation_mode , 0)


        r.SetTrackAutomationMode(track, automation_mode)
      else
        global_automation = global_automation + v
        if -1 > global_automation then
          global_automation = -1
        elseif global_automation > 6 then
          global_automation = 6
        end
        r.SetGlobalAutomationOverride(global_automation)
      end
    elseif not im.IsItemHovered(ctx) then
      window_flag = nil
    end
end



function Scroll_Main_Window_With_Mouse_Wheel()

    local focused_window = r.JS_Window_GetTitle(hwnd)

    if Wheel_V ~= 0 and not DisableScroll and focused_window == 'FX Devices' then
        r.JS_Window_SetFocus(hwnd)
        if Ctrl_Scroll then

            if Mods == Ctrl then
                Horizontal_Scroll(20)
            elseif Mods == Ctrl + Shift then
                Horizontal_Scroll(10)
            elseif Mods == Shift then -- to prevent a weird behavior which is not related to Horizontal_Scroll function
                im.SetNextWindowScroll(ctx, -CursorStartX, 0)
            end
        else

            if Mods == 0 then -- 0 = not mods key
                Horizontal_Scroll(20)
            elseif Mods == Shift then
                Horizontal_Scroll(10)
            end
        end
    end
end


function tablesHaveCommonValues(t1, t2)
    local valueSet = {}

    -- Add all values from the first table into a set
    for _, value in ipairs(t1) do
        valueSet[value] = true
    end

    -- Check if any value in the second table exists in the set
    for _, value in ipairs(t2) do
        if valueSet[value] then
            return true
        end
    end

    return false
end


function If_Multi_Select_FX(FxGUID)
    if next(Trk[TrkID].Sel_FX) then 
        if tablefind(Trk[TrkID].Sel_FX, FxGUID) then
            return true 
        end
    end
end






function At_Begining_of_Loop()
    ------- Add FX ---------
    for i, v in ipairs(AddFX.Name) do
        if v:find('FXD Gain Reduction Scope') then
            local FxGUID = ProC.GainSc_FXGUID

            FX[FxGUID] = FX[FxGUID] or {}
            FX[FxGUID].ProC_ID = math.random(1000000, 9999999)
            r.gmem_attach('CompReductionScope')
            r.gmem_write(2002, FX[FxGUID].ProC_ID)
            r.gmem_write(FX[FxGUID].ProC_ID, AddFX.Pos[i])
            r.gmem_write(2000, PM.DIY_TrkID[TrkID])
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID ' .. FxGUID, FX[FxGUID].ProC_ID, true)
        elseif v:find('FXD Saike BandSplitter') then
            r.gmem_attach('FXD_BandSplit')
            BandSplitID = BandSplitID or math.random(1000000, 9999999)
            r.gmem_write(0, BandSplitID)
        elseif v:find('FXD Band Joiner') then

        end



        AddFX_HideWindow(LT_Track, v, -1000 - AddFX.Pos[i])
        if v:find('FXD Band Joiner') then
            local SplittrID = r.TrackFX_GetFXGUID(LT_Track, AddFX.Pos[i] - 1)
            local JoinerID = r.TrackFX_GetFXGUID(LT_Track, AddFX.Pos[i])
            FX[SplittrID] = FX[SplittrID] or {}
            FX[SplittrID].AttachToJoiner = JoinerID
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Splitter\'s Joiner FxID ' .. SplittrID, JoinerID, true)
        elseif v:find('FXD Gain Reduction Scope') then
            local _, FX_Name = r.TrackFX_GetFXName(LT_Track, AddFX.Pos[i])

            SyncAnalyzerPinWithFX(AddFX.Pos[i], AddFX.Pos[i] - 1, FX_Name)
        end

       --[[  if  AddFX.Parallel then 
            r.TrackFX_SetNamedConfigParm( LT_Track, AddFX.Pos[i], 'parallel', '1' )
        end ]]


        TREE = BuildFXTree(LT_Track)

    end




    ----- Del FX ------
    if Sel_Track_FX_Count then
        for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
            local function Do(FX_Idx)
                local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx or 0)
                local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)

                if FX_Name == 'JS: FXD Gain Reduction Scope' then
                    if string.find(PreviousFX, 'Pro%-C 2') == nil then
                        r.TrackFX_Delete(LT_Track, FX_Idx)
                    end
                end
                if FX_Name == 'JS: FXD Split to 4 channels' then
                    if string.find(NextFX, 'Pro%-C 2') == nil and not AddFX.Name[1] then
                        r.TrackFX_Delete(LT_Track, FX_Idx)
                    end
                    local ProC_pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx + 1, 0, 0)
                    local SplitPin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)

                    if ProC_pin ~= SplitPin then
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 0, ProC_pin, 0) -- input L
                        local R = r.TrackFX_GetPinMappings(LT_Track, FX_Idx + 1, 0, 1)
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 1, R, 0)        -- input R

                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 0, ProC_pin, 0) -- out L
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 1, R, 0)        -- out R
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 2, 2 * R, 0)    -- out L Compare
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 3, 4 * R, 0)    -- out R Compare
                    end
                end
            end

            local is_container, container_count = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                'container_count')

            if is_container then
                for i = 1, container_count, 1 do
                    local Idx = tonumber(select(2,
                        r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'container_item.' .. i)))
                    if Idx then
                        Do(Idx)
                    end
                end
            else
                Do(FX_Idx)
            end
        end
        TREE = BuildFXTree(LT_Track)

    end


    for i, v in ipairs(DelFX.GUID) do 
        DeleteFX(DelFX.Pos[i], v)
    end

    DelFX = { Pos = {},  GUID = {}}

    local function If_MovFX_FromFxID ()

        local Tb_Val = {}
        local tb_FxID = { }
        -- put fx idx into table 
        for i, v in ipairs(MovFX.FromFxID) do 

            local idx = Find_FxID_By_GUID(v)
            table.insert(Tb_Val, idx)
        end
        -- sort table by value  
        if next(Tb_Val)  then 
            table.sort(Tb_Val)
            if Tb_Val[1] > MovFX.ToPos[1]  then 
                 table.sort(Tb_Val , function(a, b) return a > b end)
            else 
                for i , v in ipairs(MovFX.ToPos) do 
                    if v < 0x2000000 then 
                        MovFX.ToPos[i] = MovFX.ToPos[i] - 1 
                    end
                 end
            end
        end
        for i, v in ipairs(Tb_Val)do 
            local id = r.TrackFX_GetFXGUID(LT_Track, v )
            table.insert(tb_FxID, id )
        end
        for i, v in ipairs(tb_FxID) do 

            local idx = Find_FxID_By_GUID(v)

            local dest = r.TrackFX_CopyToTrack(LT_Track, idx, LT_Track, MovFX.ToPos[i], true)
            TREE = BuildFXTree(LT_Track)
        end


    end
    ----- Move FX -----
    if MovFX.FromPos[1] or MovFX.FromFxID[1] then
        local UndoLbl
       -- r.Undo_BeginBlock()
        for i, v in ipairs(MovFX.FromPos) do

            if NeedCopyFX then
                --if v >= DropPos then offset = 1 else offset = 0 end
                MovFX.ToPos[i] = math.max(MovFX.ToPos[i] - (offset or 0), 0)
                r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, v, false)
            end
        end



        
        for i, v in ipairs(MovFX.FromPos) do -- move FX

            

            r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, MovFX.ToPos[i], true)
            if MovFX.Parallel then 

                if tonumber(MovFX.Parallel) then -- if type is number / if user drags fx to the root of parallel fx
                    -- Set the FX Being Dragged into not parallel
                    r.TrackFX_SetNamedConfigParm( LT_Track, MovFX.ToPos[i] , 'parallel', '0' ) 
                    r.TrackFX_SetNamedConfigParm( LT_Track, tonumber(MovFX.Parallel +1), 'parallel', '1' )

                else
                    r.TrackFX_SetNamedConfigParm( LT_Track,  MovFX.ToPos[i], 'parallel', '1' )
                end
            
            end
        end
        If_MovFX_FromFxID ()


       -- r.Undo_EndBlock(MovFX.Lbl[i] or (UndoLbl or 'Move' .. 'FX'), 0)
        MovFX = { FromPos = {}, ToPos = {}, Lbl = {}, Copy = {} , FromFxID = {} }
        NeedCopyFX = nil
        DropPos = nil

        MovFX.Parallel = MovFX.Parallel and nil 
        TREE = BuildFXTree(LT_Track)
    end



    if AddFX.Name[1] then 
        TREE = BuildFXTree(LT_Track)
    end
    AddFX.Name         = {}
    AddFX.Pos          = {}
    ProC.GainSc_FXGUID = nil 






    if Switch_Parallel_FX then 
        FX[Switch_Parallel_FX].ShowParallel = toggle(FX[Switch_Parallel_FX].ShowParallel)
        Switch_Parallel_FX =nil
    end

    local rv , ret = r.TrackFX_GetNamedConfigParm(LT_Track, 0, 'parallel') 
    if ret == '1' then 
        r.TrackFX_SetNamedConfigParm(LT_Track, 0, 'parallel', '0') 
    end



end


function quadraticEaseInOut(t)
-- Define the quadratic easing function

    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end


function Anim_Update(dt, duration,  startValue,endValue, time )

    local time = time + dt
    if time > duration then
        time = duration
    end

    -- Calculate the normalized time
    local t = time / duration
    -- Calculate the current value using the easing function
    local currentValue = quadraticEaseInOut(t) * (endValue - startValue) + startValue


    return currentValue, time,  time >=duration

end



function When_User_Switch_Track()

    -- if user switch selected track...
    local layoutRetrieved

    if TrkID ~= TrkID_End then
        if TrkID_End ~= nil and TrkID ~= nil then
            NumOfTotalTracks = r.CountTracks(0)
            --[[  r.gmem_attach('TrackNameForMacro')
            reaper .gmem_write(0,NumOfTotalTracks )]]
        end
        for P = 0, Trk.Prm.Inst[TrkID] or 0, 1 do
            for m = 1, 8, 1 do
                r.gmem_write(1000 * m + P, 0)
            end
        end

        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
        TREE = BuildFXTree(LT_Track)

        layoutRetrieved = true
        SyncTrkPrmVtoActualValue()
        LT_TrackNum = math.floor(r.GetMediaTrackInfo_Value(LT_Track, 'IP_TRACKNUMBER'))
    end
    if TrkID ~= TrkID_End and TrkID_End ~= nil and Sel_Track_FX_Count > 0 then
        Sendgmems = nil
        
        Open_Cont_LFO_Win = nil
        if Sendgmems == nil then
            r.gmem_attach('ParamValues')
            for P = 1, 100, 1 do
                r.gmem_write(1000 + P, 0)
            end

            for FX_Idx = 0, Sel_Track_FX_Count, 1 do
                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                if FxGUID then
                    for P, v in ipairs(FX[FxGUID]) do
                        local FP = FX[FxGUID][P]
                        FP.ModAMT = FP.ModAMT or {}
                        FP.ModBipolar = FP.ModBipolar or {}
                        if FP.WhichCC then
                            for m = 1, 8, 1 do
                                local Amt = FP.ModAMT[m]
                                if FP.ModBipolar[m] then Amt = FP.ModAMT[m] + 100 end

                                if FP.ModAMT[m] then r.gmem_write(1000 * m + P, Amt) end
                            end
                        end
                    end
                end
            end

            r.gmem_write(2, PM.DIY_TrkID[TrkID] or 0)

            Sendgmems = true
        end

        for i=1, 8, 1  do 
            if Trk[TrkID].Mod[i] then 
                if Trk[TrkID].Mod[i].FOL_PastY then 
                    Trk[TrkID].Mod[i].FOL_PastY = {}
                end 
            end 
        end
    end

end 



function Activate_Debug_Mode()

    if im.IsKeyPressed(ctx, im.Key_D) and Mods == Shift + Alt then
        DebugMode = true
    end
end


function PrintTraceback(err)
    local byLine = "([^\r\n]*)\r?\n?"
    local trimPath = "[\\/]([^\\/]-:%d+:.+)$"
    local stack = {}
    for line in string.gmatch(err, byLine) do
        local str = string.match(line, trimPath) or line
        stack[#stack + 1] = str
    end
    r.ShowConsoleMsg(
        "Error: " .. stack[1] .. "\n\n" ..
        "Stack traceback:\n\t" .. table.concat(stack, "\n\t", 3) .. "\n\n" ..
        "Reaper:       \t" .. r.GetAppVersion() .. "\n" ..
        "Platform:     \t" .. r.GetOS()
    )
end




function ExtractContainer(chunk, guid)
    local r_chunk = chunk:reverse()
    local r_guid = guid:reverse()
    local s1 = string.find(r_chunk, r_guid, 1, true)
    if s1 then
        local s = s1
        local indent, op, cl = nil, nil, nil
        while (not indent or indent > 0) do
            if not indent then indent = 0 end
            cl = string.find(r_chunk, ('<\n'), s + 1, true) + 1 
            op = string.find(r_chunk, ('>\n'), s + 1, true)
            if op ~= nil then
                op = op + 1
                if op <= cl then
                    indent = indent + 1
                    s = op
                else
                    indent = indent - 1
                    s = cl
                end
            else
                indent = indent - 1
                s = cl
            end 
        end
        local chain_chunk = string.sub(r_chunk, s1, cl):reverse()
        --local cont_fx_chunk = "BYPASS 0 0 0" .. chain_chunk .. "\nWAK 0 0" -- you dont need this line for your use
        local cont_fx_chunk = chain_chunk
        return cont_fx_chunk
    end
end

-- Function to replace numbers
local function Replace_Numbers_In_A_String(s)
    local newValue = replacements[index]
    index = index + 1
    return tostring(newValue)
end





local text = [[
Some other text
CONTAINER_CFG 2 2 2 34
Some more text
Another line of text
]]


function Replace_Numbers_In_String(match)
    local newValue = replacements[index]
    index = index + 1
    return tostring(newValue)
end

function number_Replacement_for_Containers(str, num1, num2, num3 , num4)
    -- Replacement values
    local replacements = {num1, num2, num3 , num4}
    local index = 1

    -- Function to replace numbers
    local function replaceNumbers(match)
        local newValue = replacements[index]
        index = index + 1
        return tostring(newValue)
    end

    -- Function to find and replace numbers in the specific line
    local function findAndReplaceNumbers(text, targetLine)
        local pattern = targetLine .. " %d+ %d+ %d+ %d+"
        local line = text:match(pattern)
        if line then
            local newLine = string.gsub(line, "%d+", replaceNumbers)
            text = string.gsub(text, line, newLine)
        end
        return text
    end


    


    -- Target line to find and modify
    local targetLine = "CONTAINER_CFG"


    -- Perform the replacement
    local newText = findAndReplaceNumbers(str, targetLine)
    return newText
end




function Put_Long_String_Into_Table(chunk)
    local chunk_lines = {}

    for s in chunk:gmatch("[^\r\n]+") do
        table.insert(chunk_lines, s)
    end
    return chunk_lines
end



function At_End_Of_Loop()
    if LBtnRel then     
        LE.ChangePos = nil 
        Long_Or_Short_Click_Time_Start = nil 
        Create_Insert_FX_Preview = nil
        DragFX_ID = nil
    end
    if RBtnRel then 
        MARQUEE_SELECTING_FX = nil
        
    end


end


function Load_Trk_Info(str, type, Track)
    local Track = Track or LT_Track
    if type == 'str' then
        local i= select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false))
        if i =='' then return nil else return i end 
    elseif type =='bool' then   
        local i= select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false))
        if i == 'true' then return true else return end 
    else
        return tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false)))
    end
end


function Get_Default_Param_Width_By_Type(type)
    local DefaultW 
    if type == 'Knob' then
        DefaultW = Df.KnobRadius
        MaxW = 80
        MinW = 7.5
    elseif type == 'Slider' or type == 'Drag' or not type then
        DefaultW = Df.Sldr_W
        MaxW = 300
        MinW = 40
    elseif type == 'Selection' then
        DefaultW = Df.Combo_W
        MaxW = 300
        MinW = 20
    elseif type == 'Switch' then
        DefaultW = Df.Switch_W
        MaxW = 300
        MinW = 15
    elseif type == 'V-Slider' then
        DefaultW = Df.V_Sldr_W
        MaxW = 60
        MinW = 7
    end
    return DefaultW, MaxW, MinW 
end

function Get_Default_Param_Height_By_Type(type)
    local DefH 
    if type == 'Knob' then
        DefH =  Df.KnobRadius
    elseif type == 'Slider' or type == 'Drag' or not type then
        DefH = Df.Sldr_H
        
    elseif type == 'Selection' then
        DefH = Df.Sldr_H
        
    elseif type == 'Switch' then
        DefH = Df.Sldr_H
        
    elseif type == 'V-Slider' then
        DefH = Df.V_Sldr_H
 
    end
    return DefH
end