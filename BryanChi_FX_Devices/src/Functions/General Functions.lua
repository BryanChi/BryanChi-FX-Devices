-------------General Functions ------------------------------
-- @version 1.0Beta 1

---General functions list
function msg(...)
    for i, v in ipairs({ ... }) do
        r.ShowConsoleMsg(tostring(v) .. "\n")
    end
end
---@param str string
function GetFileExtension(str)
    return str:match("^.+(%..+)$")
end

function InvisiBtn(ctx, x, y, str, w, h)
    if x and y then
        im.SetCursorScreenPos(ctx, x, y)
    end
    local rv = im.InvisibleButton(ctx, str, w, h or w)


    return rv
end

function Delete_All_FXD_AnalyzerFX(trk)
    local ct = r.TrackFX_GetCount(trk)
    for i = 0, ct, 1 do
        local rv, name = r.TrackFX_GetFXName(trk, i)

        if FindStringInTable(FX_To_Delete_At_Close, name) then
            r.TrackFX_Delete(trk, i)
        end
    end
end
--------------------------- Container Related ------------------------------
---@param tr MediaTrack
---@param idx1 number
---@return integer "fxid"
function get_fx_id_from_container_path(tr, idx1, ...)
    local sc, rv = reaper.TrackFX_GetCount(tr) + 1, 0x2000000 + idx1
    for i, v in ipairs({ ... }) do
        local ccok, cc = reaper.TrackFX_GetNamedConfigParm(tr, rv, 'container_count')
        if ccok ~= true then return nil end
        rv = rv + sc * v
        sc = sc * (1 + tonumber(cc))
    end
    return rv
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

---@return integer
---@return integer
---@return string
---@return string
function GetNextAndPreviousFXID(FX_Idx )

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

---@param tr MediaTrack
---@param fxidx integer 0 based or something like 33554455 in container
---@return table<Index,fxslot> table
function get_container_path_from_fx_id(tr, fxidx) -- returns a list of 1-based FXIDs as a table from a fx-address, e.g. 1, 2, 4
    if fxidx & 0x2000000 then
      local ret = { }
      local n = reaper.TrackFX_GetCount(tr)
      local curidx = (fxidx - 0x2000000) % (n+1)
      local remain = math.floor((fxidx - 0x2000000) / (n+1))
      if curidx < 1 then return nil end -- bad address
  
      local addr, addr_sc = curidx + 0x2000000, n + 1
      while true do
        local ccok, cc = reaper.TrackFX_GetNamedConfigParm(tr, addr, 'container_count')
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

    local ret = {
        fxname = buf,
        isopen = reaper.TrackFX_GetOpen(tr, fxid),
        GUID = reaper.TrackFX_GetFXGUID(tr, fxid),
        addr_fxid = fxid,
        scale = oldscale
    }

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
--------------------------------------------------------------------------

local tr = reaper.GetSelectedTrack(0, 0)
TREE = BuildFXTree(LT_Track or tr)

function EndUndoBlock(str)
    r.Undo_EndBlock("ReaDrum Machine: " .. str, -1)
end

function Curve_3pt_Bezier(startX, startY, controlX, controlY, endX, endY)
    local X, Y = {}, {}
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

function AddMacroJSFX()
    local MacroGetLT_Track = r.GetLastTouchedTrack()
    MacrosJSFXExist = r.TrackFX_AddByName(MacroGetLT_Track, 'FXD Macros', 0, 0)
    if MacrosJSFXExist == -1 then
        r.TrackFX_AddByName(MacroGetLT_Track, 'FXD Macros', 0, -1000)
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
    return table.concat({ ... }, sep)
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

---@generic T
---@param v? T
---@return boolean
function toggle(v)
    if v then v = false else v = true end
    return v
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
        local Out, LineChange
        local ID = Fx_P .. '%. ' .. Id .. ' = '
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
    if tab then
        for index, value in pairs(tab) do
            if value == el then
                return index
            end
        end
    end
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

---TODO I think Position is meant to be used as «instantiate» variable, is this the intent?
---@param track MediaTrack
---@param fx_name string
---@param Position integer
function AddFX_HideWindow(track, fx_name, Position)
    local val = r.SNM_GetIntConfigVar("fxfloat_focus", 0)
    if val & 4 == 0 then
        r.TrackFX_AddByName(track, fx_name, 0, Position)   -- add fx
    else
        r.SNM_SetIntConfigVar("fxfloat_focus", val & (~4)) -- temporarily disable Auto-float newly created FX windows
        r.TrackFX_AddByName(track, fx_name, 0, Position)   -- add fx
        r.SNM_SetIntConfigVar("fxfloat_focus", val|4)      -- re-enable Auto-float
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
        end
    else -- if all is collapsed
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            FX[FXGUID[i]].Collapse = false
            FX.WidthCollapse[FXGUID[i]] = nil
        end
        BlinkFX = FX_Idx
    end
    return BlinkFX
end

function toggle2(a, b)
    if a == b then return nil else return b end
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

---@param num number
---@param multipleOf number
---@return number
function roundUp(num, multipleOf)
    return math.floor((num + multipleOf / 2) / multipleOf) * multipleOf;
end

---@param FX_P integer
---@param FxGUID string
---@return unknown
function F_Tp(FX_P, FxGUID) ---TODO this is a duplicate function, and it’s not used anywhere
    return FX.Prm.ToTrkPrm[FxGUID .. FX_P]
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

function Vertical_FX_Name(name)
    local Name = ChangeFX_Name(name)
    local Name = Name:gsub('%S+', { ['Valhalla'] = "", ['FabFilter'] = "" })
    local Name = Name:gsub('-', '|')
    local Name_V = Name:gsub("(.)", "%1\n")
    return Name_V:gsub("%b()", "")
end

---@generic T
---@param Table table<string, T>
---@param V T
---@return boolean|nil
---@return T[]|nil
function FindExactStringInTable(Table, V)
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
function PinIcon(PinStatus, PinStr, size, lbl, ClrBG, ClrTint)
    if PinStatus == PinStr then
        if im.ImageButton(ctx, '##' .. lbl, Img.Pinned, size, size, nil, nil, nil, nil, ClrBG, ClrTint) then
            PinStatus = nil
        end
    else
        if im.ImageButton(ctx, '##' .. lbl, Img.Pin, size, size, nil, nil, nil, nil, ClrBG, ClrTint) then
            PinStatus = PinStr
        end
    end

    if im.IsItemHovered(ctx) then
        TintClr = 0xCE1A28ff
    end
    return PinStatus, TintClr
end

function QuestionHelpHint(Str)
    if im.IsItemHovered(ctx) then
        SL()
        im.TextColored(ctx, 0x99999977, '(?)')
        if im.IsItemHovered(ctx) then
            tooltip(Str)
        end
    end
end

---@param FillClr number
---@param OutlineClr number
---@param Padding number
---@param L number
---@param T number
---@param R number
---@param B number
---@param h number
---@param w number
---@param H_OutlineSc any
---@param V_OutlineSc any
---@param GetItemRect "GetItemRect"|nil
---@param Foreground? ImGui_DrawList
---@param rounding? number
---@return number|nil L
---@return number|nil T
---@return number|nil R
---@return number|nil B
---@return number|nil w
---@return number|nil h
function HighlightSelectedItem(FillClr, OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
                               Foreground, rounding, thick)
    if GetItemRect == 'GetItemRect' or L == 'GetItemRect' then
        L, T = im.GetItemRectMin(ctx); R, B = im.GetItemRectMax(ctx); w, h = im.GetItemRectSize(ctx)
        --Get item rect
    end
    local P = Padding or 0; local HSC = H_OutlineSc or 4; local VSC = V_OutlineSc or 4
    if Foreground == 'Foreground' then WinDrawList = Glob.FDL else WinDrawList = Foreground end
    if not WinDrawList then WinDrawList = im.GetWindowDrawList(ctx) end
    if FillClr then im.DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr) end

    local h = h or B - T
    local w = w or R - L

    if OutlineClr and not rounding then
        im.DrawList_AddLine(WinDrawList, L - P, T - P, L - P, T + h / VSC - P, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, R + P, T - P, R + P, T + h / VSC - P, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, L - P, B + P, L - P, B + P - h / VSC, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, R + P, B + P, R + P, B - h / VSC + P, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, L - P, T - P, L - P + w / HSC, T - P, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, R + P, T - P, R + P - w / HSC, T - P, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, L - P, B + P, L - P + w / HSC, B + P, OutlineClr, thick)
        im.DrawList_AddLine(WinDrawList, R + P, B + P, R + P - w / HSC, B + P, OutlineClr, thick)
    else
        if FillClr then im.DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr, rounding) end
        if OutlineClr then im.DrawList_AddRect(WinDrawList, L, T, R, B, OutlineClr, rounding) end
    end
    if GetItemRect == 'GetItemRect' then return L, T, R, B, w, h end
end

function Highlight_Itm(WDL, FillClr, OutlineClr)
    local L, T = im.GetItemRectMin(ctx);
    local R, B = im.GetItemRectMax(ctx);

    if FillClr then im.DrawList_AddRectFilled(WDL, L, T, R, B, FillClr, rounding) end
    if OutlineClr then im.DrawList_AddRect(WDL, L, T, R, B, OutlineClr, rounding) end
end

---@param ctx ImGui_Context
---@param time integer count in
function PopClr(ctx, time)
    im.PopStyleColor(ctx, time)
end

---@param FX_Idx integer
---@param FxGUID string
function SaveDrawings(FX_Idx, FxGUID)
    local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'FX Devices', 'BryanChi_FX_Devices', 'src', 'FX Layouts')
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
            write('ImagePath', D.FilePath, i)
            write('KeepImgRatio', tostring(D.KeepImgRatio), i)
            file:write('\n')
        end
    end
end

---TODO remove this duplicate of tooltip()
---@param A string text for tooltip
function ttp(A)
    im.BeginTooltip(ctx)
    im.SetTooltip(ctx, A)
    im.EndTooltip(ctx)
end

---@param time number
function HideCursor(time)
    UserOS = r.GetOS()
    if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
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
    LBtnDC                 = im.IsMouseDoubleClicked(ctx, 0)
end

function GetFocusedWindow()
    local hwnd = r.JS_Window_FromPoint(r.GetMousePosition())
    local focused_window = r.JS_Window_GetTitle(hwnd)
    return focused_window, hwnd
end

function HideCursorTillMouseUp(MouseBtn, triggerKey)
    UserOS = r.GetOS()
    if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
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
        local UserOS = r.GetOS()

        if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
        else
            outY = -outY
        end

        M.StX, M.StY = r.GetMousePosition()
        return outX, outY
    else
        return 0, 0
    end
end

---@param Name string
---@param FX_Idx integer
function CreateWindowBtn_Vertical(Name, FX_Idx)
    local rv = im.Button(ctx, Name, 25, 220) -- create window name button
    if rv and Mods == 0 then
        openFXwindow(LT_Track, FX_Idx)
    elseif rv and Mods == Shift then
        ToggleBypassFX(LT_Track, FX_Idx)
    elseif rv and Mods == Alt then
        DeleteFX(FX_Idx)
    end
    if im.IsItemClicked(ctx, 1) and Mods == 0 then
        FX.Collapse[FXGUID[FX_Idx]] = false
    end
end

function HighlightHvredItem()
    local DL = im.GetForegroundDrawList(ctx)
    L, T = im.GetItemRectMin(ctx)
    R, B = im.GetItemRectMax(ctx)
    if im.IsMouseHoveringRect(ctx, L, T, R, B) then
        im.DrawList_AddRect(DL, L, T, R, B, 0x99999999)
        im.DrawList_AddRectFilled(DL, L, T, R, B, 0x99999933)
        if IsLBtnClicked then
            im.DrawList_AddRect(DL, L, T, R, B, 0x999999dd)
            im.DrawList_AddRectFilled(DL, L, T, R, B, 0xffffff66)
            return true
        end
    end
end

---@param dur number
---@param rpt integer
---@param var integer | nil
---@param highlightEdge? any -- TODO is this a number?
---@param EdgeNoBlink? "EdgeNoBlink"
---@param L number
---@param T number
---@param R number
---@param B number
---@param h number
---@param w number
---@return nil|integer var
---@return string "Stop"
function BlinkItem(dur, rpt, var, highlightEdge, EdgeNoBlink, L, T, R, B, h, w)
    TimeBegin = TimeBegin or r.time_precise()
    local Now = r.time_precise()
    local EdgeClr = 0x00000000
    if highlightEdge then EdgeClr = highlightEdge end
    local GetItemRect = 'GetItemRect' ---@type string | nil
    if L then GetItemRect = nil end

    if rpt then
        for i = 0, rpt - 1, 1 do
            if Now > TimeBegin + dur * i and Now < TimeBegin + dur * (i + 0.5) then -- second blink
                HighlightSelectedItem(0xffffff77, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
                    Foreground)
            end
        end
    else
        if Now > TimeBegin and Now < TimeBegin + dur / 2 then
            HighlightSelectedItem(0xffffff77, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
                Foreground)
        elseif Now > TimeBegin + dur / 2 + dur then
            TimeBegin = r.time_precise()
        end
    end

    if EdgeNoBlink == 'EdgeNoBlink' then
        if Now < TimeBegin + dur * (rpt - 0.95) then
            HighlightSelectedItem(0xffffff00, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
                Foreground)
        end
    end

    if rpt then
        if Now > TimeBegin + dur * (rpt - 0.95) then
            TimeBegin = nil
            return nil, 'Stop'
        else
            return var
        end
    end
end

---@param text string
---@param font? ImGui_Font
---@param color? number rgba
---@param WrapPosX? number
function MyText(text, font, color, WrapPosX)
    if WrapPosX then im.PushTextWrapPos(ctx, WrapPosX) end

    if font then im.PushFont(ctx, font) end
    if color then
        im.TextColored(ctx, color, text)
    else
        im.Text(ctx, text)
    end

    if font then im.PopFont(ctx) end
    if WrapPosX then im.PopTextWrapPos(ctx) end
end

---@param ctx ImGui_Context
---@param label string
---@param labeltoShow string
---@param p_value integer
---@param v_min number
---@param v_max number
---@param FX_Idx number
---@param P_Num? number
---@return boolean ActiveAny
---@return boolean ValueChanged
---@return integer p_value
function Add_WetDryKnob(ctx, label, labeltoShow, p_value, v_min, v_max, FX_Idx, P_Num)
    im.SetNextItemWidth(ctx, 40)
    local radius_outer = 10
    local pos = { im.GetCursorScreenPos(ctx) }
    local center = { pos[1] + radius_outer, pos[2] + radius_outer }
    local CircleClr
    local line_height = im.GetTextLineHeight(ctx)
    local draw_list = im.GetWindowDrawList(ctx)
    local item_inner_spacing = { im.GetStyleVar(ctx, im.StyleVar_ItemInnerSpacing) }
    local mouse_delta = { im.GetMouseDelta(ctx) }

    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25
    local FxGUID = FXGUID[FX_Idx] or r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local p_value = p_value or 1
    if FxGUID then
        FX[FxGUID] = FX[FxGUID] or {}


        Wet.P_Num[FX_Idx] = Wet.P_Num[FX_Idx] or r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet')

        im.InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height - 10 +
            item_inner_spacing[2])

        local value_changed = false
        local is_active = im.IsItemActive(ctx)
        local is_hovered = im.IsItemHovered(ctx)

        if is_active and mouse_delta[2] ~= 0.0 and FX[FxGUID].DeltaP_V ~= 1 then
            local step = (v_max - v_min) / 200.0
            if Mods == Shift then step = 0.001 end
            p_value = p_value + ((-mouse_delta[2]) * step)
            if p_value < v_min then p_value = v_min end
            if p_value > v_max then p_value = v_max end
        end

        FX[FxGUID].DeltaP_V = FX[FxGUID].DeltaP_V or 0
        FX[FxGUID].DeltaP   = FX[FxGUID].DeltaP or (r.TrackFX_GetNumParams(LT_Track, LT_FXNum) - 1)


        local ClrOverRide, ClrOverRide_Act
        if FX[FxGUID].BgClr == 0x258551ff then
            ClrOverRide = 0xffffff88
            ClrOverRide_Act = 0xffffffcc
        end


        if is_active then
            lineClr = ClrOverRide or im.GetColor(ctx, im.Col_SliderGrabActive)
            CircleClr = ClrOverRide_Act or Change_Clr_A(getClr(im.Col_SliderGrabActive), -0.3)

            value_changed = true
            ActiveAny = true
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num or Wet.P_Num[FX_Idx], p_value)
        elseif is_hovered or p_value ~= 1 then
            lineClr = ClrOverRide_Act or Change_Clr_A(getClr(im.Col_SliderGrabActive), -0.3)
        else
            lineClr = ClrOverRide or im.GetColor(ctx, im.Col_FrameBgHovered)
        end




        if ActiveAny == true then
            if IsLBtnHeld == false then ActiveAny = false end
        end

        local t = (p_value - v_min) / (v_max - v_min)
        local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
        local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
        local radius_inner = radius_outer * 0.40
        if im.IsItemClicked(ctx, 1) and Mods == Alt then
            local Total_P = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
            local P = Total_P - 1
            local DeltaV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P)
            if DeltaV == 1 then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P, 0)
                FX[FxGUID].DeltaP_V = 0
            else
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P, 1)
                FX[FxGUID].DeltaP_V = 1
            end
            FX[FxGUID].DeltaP = P
        end



        if FX[FxGUID].DeltaP_V ~= 1 then
            im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, CircleClr or lineClr, 16)
            im.DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
                center[2] + angle_sin * (radius_outer - 2), lineClr, 2.0)
            im.DrawList_AddText(draw_list, pos[1], pos[2] + radius_outer * 2 + item_inner_spacing[2],
                im.GetColor(ctx, im.Col_Text), labeltoShow)
        else
            local radius_outer = radius_outer
            im.DrawList_AddTriangleFilled(draw_list, center[1] - radius_outer, center[2] + radius_outer, center[1],
                center[2] - radius_outer, center[1] + radius_outer, center[2] + radius_outer, 0x999900ff)
            im.DrawList_AddText(draw_list, center[1] - radius_outer / 2 + 1, center[2] - radius_outer / 2,
                0xffffffff, 'S')
        end

        --[[ if is_active or is_hovered and FX[FxGUID].DeltaP_V ~= 1 then
            local window_padding = { im.GetStyleVar(ctx, im.StyleVar_WindowPadding) }
            im.SetNextWindowPos(ctx, pos[1] - window_padding[1],
                pos[2] - line_height - item_inner_spacing[2] - window_padding[2] - 8)
            im.BeginTooltip(ctx)
            if Mods == Shift then
                im.Text(ctx, ('%.1f'):format(p_value * 100) .. '%')
            else
                im.Text(ctx, ('%.0f'):format(p_value * 100) .. '%')
            end
            im.EndTooltip(ctx)
        end ]]
        if is_hovered then HintMessage = 'Alt+Right-Click = Delta-Solo' end

        return ActiveAny, value_changed, p_value
    end
end

---@param DL ImGui_DrawList
---@param CenterX number
---@param CenterY number
---@param size number
---@param clr number rgba color
function DrawTriangle(DL, CenterX, CenterY, size, clr)
    local Cx = CenterX
    local Cy = CenterY
    local S = size
    im.DrawList_AddTriangleFilled(DL, Cx, Cy - S, Cx - S, Cy, Cx + S, Cy, clr or 0x77777777ff)
end

---@param DL ImGui_DrawList
---@param CenterX number
---@param CenterY number
---@param size number
---@param clr number rgba color
function DrawDownwardTriangle(DL, CenterX, CenterY, size, clr)
    local Cx = CenterX
    local Cy = CenterY
    local S = size
    im.DrawList_AddTriangleFilled(DL, Cx - S, Cy, Cx, Cy + S, Cx + S, Cy, clr or 0x77777777ff)
end

---Same Line
---@param xpos? number offset_from_start_xIn
---@param pad? number spacingIn
function SL(xpos, pad)
    im.SameLine(ctx, xpos, pad)
end

---@param w number
---@param h number
---@param icon string
---@param BGClr? number
---@param center? string
---@param Identifier? string
---@return boolean|nil
function IconBtn(w, h, icon, BGClr, center, Identifier)
    im.PushFont(ctx, icon1)
    if im.InvisibleButton(ctx, icon .. (Identifier or ''), w, h) then
    end
    local FillClr
    if im.IsItemActive(ctx) then
        FillClr = getClr(im.Col_ButtonActive)
        IcnClr = getClr(im.Col_TextDisabled)
    elseif im.IsItemHovered(ctx) then
        FillClr = getClr(im.Col_ButtonHovered)
        IcnClr = getClr(im.Col_Text)
    else
        FillClr = getClr(im.Col_Button)
        IcnClr = getClr(im.Col_Text)
    end
    if BGClr then FillClr = BGClr end

    L, T, R, B, W, H = HighlightSelectedItem(FillClr, 0x00000000, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
        'GetItemRect', Foreground)
    TxtSzW, TxtSzH = im.CalcTextSize(ctx, icon)
    if center == 'center' then
        im.DrawList_AddText(WDL, L + W / 2 - TxtSzW / 2, T - H / 2 - 1, IcnClr, icon)
    else
        im.DrawList_AddText(WDL, L + 3, T - H / 2, IcnClr, icon)
    end
    im.PopFont(ctx)
    if im.IsItemActivated(ctx) then return true end
end

dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/Drawing.lua") -- DrawListButton function

---@param drawlist ImGui_DrawList
---@param name string
---@param color integer
---@param round_side boolean
---@param icon boolean
---@param iconfile string
---@param edging boolean
---@param hover boolean
---@param offset boolean
function DrawListButton(drawlist, name, color, round_side, icon, iconfile, edging, hover, offset)
    local multi_color = IS_DRAGGING_RIGHT_CANVAS and color or ColorToHex(color, hover and 50 or 0)
    local xs, ys = im.GetItemRectMin(ctx)
    local xe, ye = im.GetItemRectMax(ctx)
    local w = xe - xs
    local h = ye - ys
  
    local round_flag = round_side and ROUND_FLAG[round_side] or nil
    local round_amt = round_flag and ROUND_CORNER or 0
  
    im.DrawList_AddRectFilled(drawlist, xs, ys, xe, ye, im.GetColorEx(ctx, multi_color), round_amt,
      round_flag)
    if im.IsItemActive(ctx) and edging then
        im.DrawList_AddRect(drawlist, xs - 2, ys - 2, xe + 2, ye + 2, 0x22FF44FF, 3, nil, 2)
    end
  
    if icon then im.PushFont(ctx, iconfile) end
  
    local label_size = im.CalcTextSize(ctx, name)
    local font_size = im.GetFontSize(ctx)
    local font_color = CalculateFontColor(color)
  
    im.DrawList_AddTextEx(drawlist, nil, font_size, xs + (w / 2) - (label_size / 2) + (offset or 0),
      ys + ((h / 2)) - font_size / 2, im.GetColorEx(ctx, font_color), name)
    if icon then im.PopFont(ctx) end
end

---@param f integer
---@return integer
function getClr(f)
    return im.GetStyleColor(ctx, f)
end

---@param CLR number
---@param HowMuch number
---@return integer
function Change_Clr_A(CLR, HowMuch)
    local R, G, B, A = im.ColorConvertU32ToDouble4(CLR)
    local A = SetMinMax(A + HowMuch, 0, 1)
    return im.ColorConvertDouble4ToU32(R, G, B, A)
end

---@param Clr number
function Generate_Active_And_Hvr_CLRs(Clr)
    local ActV, HvrV
    local R, G, B, A = im.ColorConvertU32ToDouble4(Clr)
    local H, S, V = im.ColorConvertRGBtoHSV(R, G, B)
    if V > 0.9 then
        ActV = V - 0.2
        HvrV = V - 0.1
    end
    local R, G, B = im.ColorConvertHSVtoRGB(H, S, SetMinMax(ActV or V + 0.2, 0, 1))
    local ActClr = im.ColorConvertDouble4ToU32(R, G, B, A)
    local R, G, B = im.ColorConvertHSVtoRGB(H, S, HvrV or V + 0.1)
    local HvrClr = im.ColorConvertDouble4ToU32(R, G, B, A)
    return ActClr, HvrClr
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

---@param A string text for tooltip
function tooltip(A)
    im.BeginTooltip(ctx)
    im.SetTooltip(ctx, A)
    im.EndTooltip(ctx)
end

---@param str string text for tooltip
---@param flags string flags (delayshort, delaynormal, stationary, etc) for tooltip
function TooltipUI(str, flags)
    if r.ImGui_IsItemHovered(ctx, flags) then
        r.ImGui_BeginTooltip(ctx)
        r.ImGui_PushFont(ctx, Font)
        r.ImGui_Text(ctx, str)
        r.ImGui_PopFont(ctx)
        r.ImGui_EndTooltip(ctx)
    end
end

---@param str string text for tooltip
---@param flags string flags (delayshort, delaynormal, stationary, etc) for tooltip
function QuestionHelpObject(str, flags)
    im.TextColored(ctx, 0x99999977, '(?)')
    if im.IsItemHovered(ctx) then
        TooltipUI(str, flags)
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

---@param FX_Idx integer
function DeleteFX(FX_Idx, FxGUID)
    local DelFX_Name
    r.Undo_BeginBlock()
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. (tablefind(Trk[TrkID].PreFX, FxGUID) or ''),
        '',
        true)
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



    r.Undo_EndBlock('Delete ' .. (DelFX_Name or 'FX'), 0)
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

-------------General Functions ------------------------------



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

---@param str string | nil
---@return nil|string
function RemoveEmptyStr(str)
    if str == '' then return nil else return str end
end

---@param T table
---@return integer
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

---@param Rpt integer
function AddSpacing(Rpt)
    for i = 1, Rpt, 1 do
        im.Spacing(ctx)
    end
end

function AddWindowBtn(FxGUID, FX_Idx, width, CantCollapse, CantAddPrm, isContainer)
    if FX[FxGUID] then
        if FX[FxGUID].TitleClr then
            WinbtnClrPop = 3
            if not FX[FxGUID].TitleClrHvr then
                FX[FxGUID].TitleClrAct, FX[FxGUID].TitleClrHvr = Generate_Active_And_Hvr_CLRs(
                    FX[FxGUID].TitleClr)
            end
            im.PushStyleColor(ctx, im.Col_ButtonHovered,
                FX[FxGUID].TitleClrHvr or 0x22222233)
            im.PushStyleColor(ctx, im.Col_ButtonActive,
                FX[FxGUID].TitleClrAct or 0x22222233)
        else
            WinbtnClrPop = 1
        end
        im.PushStyleColor(ctx, im.Col_Button, FX[FxGUID].TitleClr or 0x22222233)
        local WindowBtn



        if not FX[FxGUID].Collapse and not FX[FxGUID].V_Win_Btn_Height or isContainer then
            if not FX[FxGUID].NoWindowBtn then
                local Name = (FX[FxGUID].CustomTitle or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) .. '## ')
                if DebugMode then Name = FxGUID end
                WindowBtn = im.Button(ctx, Name .. '## ' .. FxGUID,
                    width or FX[FxGUID].TitleWidth or DefaultWidth - 38, 20) -- create window name button


                if im.IsItemHovered(ctx) and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                    FX[FxGUID].TtlHvr = true
                    if not CantAddPrm then
                        TtlR, TtlB = im.GetItemRectMax(ctx)
                        if im.IsMouseHoveringRect(ctx, TtlR - 20, TtlB - 20, TtlR, TtlB) then
                            im.DrawList_AddRectFilled(WDL, TtlR, TtlB, TtlR - 20, TtlB - 20,
                                getClr(im.Col_ButtonHovered))
                            im.DrawList_AddRect(WDL, TtlR, TtlB, TtlR - 20, TtlB - 19,
                                getClr(im.Col_Text))
                            im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 20, TtlR - 15,
                                TtlB - 20, getClr(im.Col_Text), '+')
                            if IsLBtnClicked then
                                im.OpenPopup(ctx, 'Add Parameter' .. FxGUID)
                                im.SetNextWindowPos(ctx, TtlR, TtlB)
                                AddPrmPopupOpen = FxGUID
                            end
                        end
                    end
                else
                    FX[FxGUID].TtlHvr = nil
                end
            end
        elseif FX[FxGUID].V_Win_Btn_Height and not FX[FxGUID].Collapse then
            local Name = (FX[FxGUID].CustomTitle or FX.Win_Name_S[FX_Idx] or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) .. '## ')

            local Name_V_NoManuFacturer = Vertical_FX_Name(Name)
            -- im.PushStyleVar(ctx, BtnTxtAlign, 0.5, 0.2) --StyleVar#3
            --im.SameLine(ctx, nil, 0)

            WindowBtn = im.Button(ctx, Name_V_NoManuFacturer .. '##' .. FxGUID, 25, FX[FxGUID].V_Win_Btn_Height)

            -- im.PopStyleVar(ctx)             --StyleVar#3 POP
        else -- if collapsed
            FX.WidthCollapse[FxGUID] = 27
            local Name = (FX[FxGUID].CustomTitle or FX.Win_Name_S[FX_Idx] or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) .. '## ')

            local Name_V_NoManuFacturer = Vertical_FX_Name(Name)
            im.PushStyleVar(ctx, BtnTxtAlign, 0.5, 0.2) --StyleVar#3
            --im.SameLine(ctx, nil, 0)

            WindowBtn = im.Button(ctx, Name_V_NoManuFacturer .. '##' .. FxGUID, 25, 220)
            im.PopStyleVar(ctx)             --StyleVar#3 POP
        end
        im.PopStyleColor(ctx, WinbtnClrPop) -- win btn clr

        local BgClr
        FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)

        if not FX.Enable[FX_Idx] then
            --im.DrawList_AddRectFilled(WDL, L, T - 20, R, B +20, 0x00000088)
            BgClr = 0x00000088
        end
        HighlightSelectedItem(BgClr, 0xffffff11, -1, L, T, R, B, h, w, 1, 1, 'GetItemRect', WDL,
            FX[FxGUID].Round --[[rounding]])


        -- im.SetNextWindowSizeConstraints(ctx, AddPrmWin_W or 50, 50, 9999, 500)
        local R_ClickOnWindowBtn = im.IsItemClicked(ctx, 1)
        local L_ClickOnWindowBtn = im.IsItemClicked(ctx)

        if not CantCollapse then
            if R_ClickOnWindowBtn and Mods == Ctrl then
                im.OpenPopup(ctx, 'Fx Module Menu')
            elseif R_ClickOnWindowBtn and Mods == 0 then
                FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
                if not FX[FxGUID].Collapse then FX.WidthCollapse[FxGUID] = nil end
            elseif R_ClickOnWindowBtn and Mods == Alt then
                -- check if all are collapsed
                BlinkFX = ToggleCollapseAll(FX_Idx)
            end
        end


        if WindowBtn and Mods == 0 then
            openFXwindow(LT_Track, FX_Idx)
        elseif WindowBtn and Mods == Shift then
            ToggleBypassFX(LT_Track, FX_Idx)
        elseif WindowBtn and Mods == Alt then
            DeleteFX(FX_Idx, FxGUID)
        end

        if im.IsItemHovered(ctx) then
            HintMessage =
            'Mouse: L=Open FX Window | Shift+L = Toggle Bypass | Alt+L = Delete | R = Collapse | Alt+R = Collapse All'
        end


        ----==  Drag and drop----
        if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
            DragFX_ID = FX_Idx
            DragFxGuid = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            im.SetDragDropPayload(ctx, 'FX_Drag', FX_Idx)
            im.EndDragDropSource(ctx)

            DragDroppingFX = true
            if IsAnyMouseDown == false then DragDroppingFX = false end
            HighlightSelectedItem(0xffffff22, 0xffffffff, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect',
                WDL)
            Post_DragFX_ID = tablefind(Trk[TrkID].PostFX, FxGUID_DragFX)
        end

        if IsAnyMouseDown == false and DragDroppingFX == true then
            DragDroppingFX = false
        end

        ----Drag and drop END----



        if R_ClickOnWindowBtn then
            return 2
        elseif L_ClickOnWindowBtn then
            return 1
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

function AddFX_Menu(FX_Idx ,LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost)
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

        if FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost) then
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

function createFXWindow(FX_Idx, Cur_X_Ofs)
    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local HoverWindow

    if --[[ FXGUID[FX_Idx] ~= FXGUID[FX_Idx - 1] and ]] FxGUID then
        FX[FxGUID] = FX[FxGUID] or {}
        im.BeginGroup(ctx)

        FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
        local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
        --local FxGUID = FXGUID[FX_Idx]
        local FxNameS = FX.Win_Name_S[FX_Idx]
        local Hide
        FX.DL = im.GetWindowDrawList(ctx)


        if FX_Name == 'Container' --[[ and FX_Idx < 0x2000000 ]] then
            ContainerX, ContainerY = im.GetCursorScreenPos(ctx)
        end

        local _, fx_ident = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'fx_ident') -- by default \\Plugins\\FX\\reasamplomatic.dll<1920167789 or /Applications/REAPER.app/Contents/Plugins/FX/reasamplomatic.vst.dylib<1920167789
        if fx_ident:find("1920167789") then
            FX_Name = 'ReaSamplOmatic5000'
        end

        FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
        FX_Name = string.gsub(FX_Name, '-', ' ')
        WDL = FX.DL
        FX[FxGUID] = FX[FxGUID] or {}
        if FX[FxGUID].MorphA and not FX[FxGUID].MorphHide then
            local OrigCurX, OrigCurY = im.GetCursorPos(ctx)

            DefClr_A_Act = Morph_A or CustomColorsDefault.Morph_A
            DefClr_A = Change_Clr_A(DefClr_A_Act, -0.2)
            DefClr_A_Hvr = Change_Clr_A(DefClr_A_Act, -0.1)
            DefClr_B_Act = Morph_B or CustomColorsDefault.Morph_B
            DefClr_B = Change_Clr_A(DefClr_B_Act, -0.2)
            DefClr_B_Hvr = Change_Clr_A(DefClr_B_Act, -0.1)


            function StoreAllPrmVal(AB, DontStoreCurrentVal, LinkCC)
                local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                for i = 0, PrmCount - 4, 1 do
                    local _, name = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                    local Prm_Val, minval, maxval = r.TrackFX_GetParamNormalized(LT_Track,
                        FX_Idx, i)
                    if AB == 'A' then
                        if DontStoreCurrentVal ~= 'Dont' then FX[FxGUID].MorphA[i] = Prm_Val end
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX Morph A' .. i .. FxGUID,
                            FX[FxGUID].MorphA[i], true)
                        if LinkCC then
                            ParameterMIDILink(FX_Idx, i, 1, FX[FxGUID].MorphB[i], 15, 16, 160, LinkCC, Prm_Val)
                        end
                    else
                        if DontStoreCurrentVal ~= 'Dont' then FX[FxGUID].MorphB[i] = Prm_Val end
                        if FX[FxGUID].MorphB[i] then
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: FX Morph B' .. i ..
                                FxGUID, FX[FxGUID].MorphB[i], true)
                            if LinkCC then
                                ParameterMIDILink(FX_Idx, i, 1, Prm_Val - FX[FxGUID].MorphA[i], 15, 16, 160, LinkCC, FX[FxGUID].MorphA[i])
                            end
                        end
                    end
                end
                if DontStoreCurrentVal ~= 'Dont' then
                    local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                    if rv and AB == 'A' then
                        FX[FxGUID].MorphA_Name = presetname
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', presetname, true)
                    elseif rv and AB == 'B' then
                        FX[FxGUID].MorphB_Name = presetname
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', presetname, true)
                    end
                end
            end

            im.SetNextItemWidth(ctx, 20)
            local x, y = im.GetCursorPos(ctx)
            x = x - 2
            local SCx, SCy = im.GetCursorScreenPos(ctx)
            SCx = SCx - 2
            im.SetCursorPosX(ctx, x)

            --im.PushStyleColor(ctx, im.Col_Button,DefClr_A) im.PushStyleColor(ctx, im.Col_ButtonHovered, DefClr_A_Hvr) im.PushStyleColor(ctx, im.Col_ButtonActive, DefClr_A_Act)

            if im.Button(ctx, 'A##' .. FxGUID, 20, 20) then
                StoreAllPrmVal('A', nil, FX[FxGUID].Morph_ID)
            end
            --im.PopStyleColor(ctx,3)


            if im.IsItemHovered(ctx) and FX[FxGUID].MorphA_Name then
                if FX[FxGUID].MorphA_Name ~= '' then
                    tooltip(FX[FxGUID].MorphA_Name)
                end
            end

            local H = 180
            im.SetCursorPos(ctx, x, y + 20)

            im.InvisibleButton(ctx, '##Morph' .. FxGUID, 20, H)

            local BgClrA, isActive, V_Pos, DrgSpdMod, SldrActClr, BtnB_TxtClr, ifHvr
            local M = PresetMorph


            if im.IsItemActive(ctx) then
                BgClr = im.GetStyleColor(ctx, im.Col_FrameBgActive)
                isActive = true
                BgClrA = DefClr_A_Act
                BgClrB =
                    DefClr_B_Act -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity
            elseif im.IsItemHovered(ctx) then
                ifHvr = true
                BgClrA = DefClr_A_Hvr
                BgClrB = DefClr_B_Hvr
            else
                BgClr = im.GetStyleColor(ctx, im.Col_FrameBg)
                BgClrA = DefClr_A
                BgClrB = DefClr_B
            end
            if --[[Ctrl + R click]] im.IsItemClicked(ctx, 1) and Mods == Ctrl then
                im.OpenPopup(ctx, 'Morphing menu' .. FX_Idx)
            end

            local L, T = im.GetItemRectMin(ctx)
            local R, B = im.GetItemRectMax(ctx)
            im.DrawList_AddRectFilledMultiColor(WDL, L, T, R, B, BgClrA, BgClrA, DefClr_B,
                DefClr_B)

            im.SameLine(ctx, nil, 0)

            if isActive then
                local _, v = im.GetMouseDelta(ctx, nil, nil)
                if Mods == Shift then DrgSpdMod = 4 end
                DraggingMorph = FxGUID
                FX[FxGUID].MorphAB_Sldr = SetMinMax(
                    (FX[FxGUID].MorphAB_Sldr or 0) + v / (DrgSpdMod or 2), 0, 100)
                SldrActClr = im.GetStyleColor(ctx, im.Col_SliderGrabActive)
                if FX[FxGUID].MorphB[1] ~= nil then
                    local M_ID
                    if FX[FxGUID].Morph_ID then
                        r.TrackFX_SetParamNormalized(LT_Track, 0 --[[Macro.jsfx]],
                            7 + FX[FxGUID].Morph_ID, FX[FxGUID].MorphAB_Sldr / 100)
                    else
                        for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                            if v ~= FX[FxGUID].MorphB[i] then
                                if FX[FxGUID].PrmList[i] then
                                    if FX[FxGUID].PrmList[i].BL ~= true then
                                        Fv = v +
                                            (FX[FxGUID].MorphB[i] - v) *
                                            (FX[FxGUID].MorphAB_Sldr / 100)
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, Fv)
                                    end
                                else
                                    Fv = v + (FX[FxGUID].MorphB[i] - v) *
                                        (FX[FxGUID].MorphAB_Sldr / 100)
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, Fv)
                                end
                            end
                        end
                    end
                end
            end

            --[[ if ifHvr   then

                --im.SetNextWindowPos(ctx,SCx+20, SCy+20)
                im.OpenPopup(ctx, 'Hover On Preset Morph Drag')

                M.JustHvrd = true
            end
            if M.JustHvrd then

                M.JustHvrd = nil
            end ]]

            if im.BeginPopup(ctx, 'Morphing menu' .. FX_Idx) then
                local Disable
                MorphingMenuOpen = true
                if not FX[FxGUID].MorphA[1] or not FX[FxGUID].MorphB[1] then
                    im.BeginDisabled(ctx)
                end

                if not FX[FxGUID].Morph_ID or FX[FxGUID].Unlink then
                    if im.Selectable(ctx, 'Automate', false) then
                        r.gmem_attach('ParamValues')

                        if not Trk[TrkID].Morph_ID then
                            Trk[TrkID].Morph_ID = {} -- Morph_ID is the CC number jsfx sends
                            Trk[TrkID].Morph_ID[1] = FxGUID
                            FX[FxGUID].Morph_ID = 1
                        else
                            if not FX[FxGUID].Morph_ID then
                                table.insert(Trk[TrkID].Morph_ID, FxGUID)
                                FX[FxGUID].Morph_ID = tablefind(Trk[TrkID].Morph_ID, FxGUID)
                            end
                        end

                        if --[[Add Macros JSFX if not found]] r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then
                            r.gmem_write(1, PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
                            AddMacroJSFX()
                        end
                        for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                            local Scale = FX[FxGUID].MorphB[i] - v

                            if v ~= FX[FxGUID].MorphB[i] then
                                ParameterMIDILink(FX_Idx, i, 1, Scale, 15, 16, 160, FX[FxGUID].Morph_ID, v)
                                FX[FxGUID][i] = FX[FxGUID][i] or {}
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Morph_ID' .. FxGUID, FX[FxGUID].Morph_ID, true)
                                if FX[FxGUID].PrmList[i] then
                                    if FX[FxGUID].PrmList[i].BL ~= true then
                                        ParameterMIDILink(FX_Idx, i, 1, Scale, 15, 16, 160, FX[FxGUID].Morph_ID, v)
                                        FX[FxGUID][i] = FX[FxGUID][i] or {}
                                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Morph_ID' .. FxGUID, FX[FxGUID].Morph_ID, true)
                                    end
                                else
                                    ParameterMIDILink(FX_Idx, i, 1, Scale, 15, 16, 160, FX[FxGUID].Morph_ID, v)
                                    FX[FxGUID][i] = FX[FxGUID][i] or {}
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Morph_ID' .. FxGUID, FX[FxGUID].Morph_ID, true)
                                end
                            end
                        end


                        -- Show Envelope for Morph Slider
                        local env = r.GetFXEnvelope(LT_Track, 0, 7 + FX[FxGUID].Morph_ID, false)    -- Check if envelope is on
                        if env == nil then                                                          -- Envelope is off
                            local env = r.GetFXEnvelope(LT_Track, 0, 7 + FX[FxGUID].Morph_ID, true) -- true = Create envelope
                        else                                                                        -- Envelope is on but invisible
                            local rv, EnvelopeStateChunk = r.GetEnvelopeStateChunk(env, "", false)
                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 0", "VIS 1")
                            r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                        end
                        r.TrackList_AdjustWindows(false)
                        r.UpdateArrange()

                        FX[FxGUID].Unlink = false
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '', true)

                        SetPrmAlias(LT_TrackNum, 1, 8 + FX[FxGUID].Morph_ID,
                            FX.Win_Name_S[FX_Idx]:gsub("%b()", "") .. ' - Morph AB ')
                    end
                elseif FX[FxGUID].Morph_ID or not FX[FxGUID].Unlink then
                    if im.Selectable(ctx, 'Unlink Parameters to Morph Automation', false) then
                        for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. i ..
                                ".plink.active", 0) -- 1 active, 0 inactive
                        end
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FXs Morph_ID' .. FxGUID,
                            FX[FxGUID].Morph_ID, true)
                        FX[FxGUID].Unlink = true
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', 'Unlink', true)
                    end
                end

                if FX[FxGUID].Morph_Value_Edit then
                    if im.Selectable(ctx, 'EXIT Edit Preset Value Mode', false) then
                        FX[FxGUID].Morph_Value_Edit = false
                    end
                else
                    if Disable then im.BeginDisabled(ctx) end
                    if im.Selectable(ctx, 'ENTER Edit Preset Value Mode', false) then
                        FX[FxGUID].Morph_Value_Edit = true
                    end
                end
                if not FX[FxGUID].MorphA[1] or not FX[FxGUID].MorphB[1] then im.EndDisabled(ctx) end

                if im.Selectable(ctx, 'Morphing Blacklist Settings', false) then
                    if OpenMorphSettings then
                        OpenMorphSettings = FxGUID
                    else
                        OpenMorphSettings =
                            FxGUID
                    end
                    local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                    FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                    for i = 0, Ct - 4, 1 do --get param names
                        FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                        local rv, name             = r.TrackFX_GetParamName(LT_Track, FX_Idx,
                            i)
                        FX[FxGUID].PrmList[i].Name = name
                    end
                end

                if im.Selectable(ctx, 'Hide Morph Slider', false) then
                    FX[FxGUID].MorphHide = true
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph Hide' .. FxGUID,
                        'true', true)
                end

                im.EndPopup(ctx)
            else
                MorphingMenuOpen = false
            end




            if not ifHvr and M.JustHvrd then
                M.timer = M.timer + 1
            else
                M.timer = 0
            end





            V_Pos = T + (FX[FxGUID].MorphAB_Sldr or 0) / 100 * H * 0.95
            im.DrawList_AddRectFilled(WDL, L, V_Pos, R, V_Pos + 10, 0xffffff22)
            im.DrawList_AddRect(WDL, L, V_Pos, R, V_Pos + 10, 0xffffff44)


            im.SameLine(ctx)
            im.SetCursorPos(ctx, x, y + 200)
            if not FX[FxGUID].MorphB[1] then
                BtnB_TxtClr = im.GetStyleColor(ctx,
                    im.Col_TextDisabled)
            end

            if BtnB_TxtClr then
                im.PushStyleColor(ctx, im.Col_Text,
                    im.GetStyleColor(ctx, im.Col_TextDisabled))
            end
            im.PushStyleColor(ctx, im.Col_Button, DefClr_B)
            im.PushStyleColor(ctx, im.Col_ButtonHovered, DefClr_B_Hvr)
            im.PushStyleColor(ctx, im.Col_ButtonActive, DefClr_B_Act)

            if im.Button(ctx, 'B##' .. FxGUID, 20, 20) then
                StoreAllPrmVal('B', nil, FX[FxGUID].Morph_ID)
                local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                if rv then FX[FxGUID].MorphB_Name = presetname end
            end
            if im.IsItemHovered(ctx) and FX[FxGUID].MorphB_Name then
                tooltip(FX[FxGUID]
                    .MorphB_Name)
            end
            im.PopStyleColor(ctx, 3)

            if BtnB_TxtClr then im.PopStyleColor(ctx) end
            if FX.Enable[FX_Idx] == false then
                im.DrawList_AddRectFilled(WDL, L, T - 20, R, B + 20, 0x00000088)
            end

            im.SetCursorPos(ctx, OrigCurX + 19, OrigCurY)
        end

        local FX_Devices_Bg = FX_Devices_Bg

        -- FX window color

        im.PushStyleColor(ctx, im.Col_ChildBg, FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff); local poptimes = 1


        FX[FxGUID] = FX[FxGUID] or {}

        local PrmCount = tonumber(select(2, r.GetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID))) or 0
        local Def_Sldr_W = 160
        if FX.Def_Sldr_W[FxGUID] then Def_Sldr_W = FX.Def_Sldr_W[FxGUID] end

        if FX.Def_Type[FxGUID] == 'Slider' or FX.Def_Type[FxGUID] == 'Drag' or not FX.Def_Type[FxGUID] then
            local DF = (FX.Def_Sldr_W[FxGUID] or Df.Sldr_W)

            local Ct = math.max(math.floor((PrmCount / 6 - 0.01)) + 1, 1)

            DefaultWidth = (DF + GapBtwnPrmColumns) * Ct

        elseif FX.Def_Type[FxGUID] == 'Knob' then
            local Ct = math.max(math.floor((PrmCount / 3) - 0.1) + 1, 1) -- need to -0.1 so flooring 3/3 -0.1 will return 0 and 3/4 -0.1 will be 1
            DefaultWidth = Df.KnobSize * Ct + GapBtwnPrmColumns
        end

        if FindStringInTable(BlackListFXs, FX_Name) then
            Hide = true
        end



        if Trk[TrkID].PreFX_Hide then
            if FindStringInTable(Trk[TrkID].PreFX, FxGUID) then
                Hide = true
            end
            if Trk[TrkID].PreFX[FX_Idx + 1] == FxGUID then
                Hide = true
            end
        end
        
        if not Hide then
            local CurPosX
            if FxGUID == FXGUID[(tablefind(Trk[TrkID].PostFX, FxGUID) or 0) - 1] then
                --[[ CurPosX = im.GetCursorPosX(ctx)
                im.SetCursorPosX(ctx,VP.X+VP.w- (FX[FxGUID].PostWin_SzX or 0)) ]]
            end
            local Width = FX.WidthCollapse[FxGUID] or FX[FxGUID].Width or DefaultWidth or 220
           -- local winFlg = im.ChildFlags_NoScrollWithMouse + im.ChildFlags_NoScrollbar

            local dummyH = 220
            if FX_Name == 'Container' then
                winFlg = FX[FxGUID].NoScroll or im.ChildFlags_AlwaysAutoResize
                dummyH = 0
            end
            im.PushStyleVar(ctx, im.StyleVar_ScrollbarSize, 8) -- styleVar ScrollBar




            if im.BeginChild(ctx, FX_Name .. FX_Idx, Width, 220, nil, im.WindowFlags_NoScrollbar | im.WindowFlags_NoScrollWithMouse) and not Hide then ----START CHILD WINDOW------
                if Draw[FxNameS] ~= nil then
                    local D = Draw[FxNameS]
                end


                Glob.FDL = im.GetForegroundDrawList(ctx)

                WDL = im.GetWindowDrawList(ctx)
                --if not SPLITTER then  SPLITTER = im.CreateDrawListSplitter(WDL) end 
        
        

                Win_L, Win_T = im.GetItemRectMin(ctx); Win_W, Win_H = im.GetItemRectSize(ctx)
                Win_R, _ = im.GetItemRectMax(ctx); Win_B = Win_T + 220

                if Draw.DrawMode[FxGUID] == true then
                    local D = Draw[FxNameS]
                    im.DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B, 0x00000033)
                    -- add horizontal grid
                    for i = 0, 220, LE.GridSize do
                        im.DrawList_AddLine(WinDrawList, Win_L, Win_T + i, Win_R, Win_T + i, 0x44444411)
                    end
                    -- add vertical grid
                    for i = 0, FX[FxGUID].Width or DefaultWidth, LE.GridSize do
                        im.DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B, 0x44444411)
                    end
                    if im.IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil and not Draw.SelItm and Draw.Time == 0 then
                        if Draw.Type == 'Text' then
                            im.SetMouseCursor(ctx, im.MouseCursor_TextInput)
                        end
                        if im.IsMouseClicked(ctx, 0) and Mods == 0 then
                            Draw.CurrentylDrawing = true
                            MsX_Start, MsY_Start = im.GetMousePos(ctx);
                            CurX, CurY = im.GetCursorScreenPos(ctx)
                            Win_MsX_Start = MsX_Start - CurX; Win_MsY_Start = MsY_Start - CurY + 3
                        end

                        if Draw.CurrentylDrawing then
                            if IsLBtnHeld and Mods == 0 and MsX_Start then
                                MsX, MsY   = im.GetMousePos(ctx)
                                CurX, CurY = im.GetCursorScreenPos(ctx)
                                Win_MsX    = MsX - CurX; Win_MsY = MsY - CurY

                                Rad        = MsX - MsX_Start
                                local Clr  = Draw.clr or 0xffffffff
                                if Rad < 0 then Rad = Rad * (-1) end
                                if Draw.Type == 'line' then
                                    im.DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX, MsY_Start, Clr)
                                elseif Draw.Type == 'V-line' then
                                    im.DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX_Start, MsY, Clr)
                                elseif Draw.Type == 'rectangle' then
                                    im.DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY, Clr,
                                        FX[FxGUID].Draw.Df_EdgeRound or 0)
                                elseif Draw.Type == 'Picture' then
                                    im.DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY, Clr,
                                        FX[FxGUID].Draw.Df_EdgeRound or 0)
                                elseif Draw.Type == 'rect fill' then
                                    im.DrawList_AddRectFilled(WDL, MsX_Start, MsY_Start, MsX, MsY, Clr,
                                        FX[FxGUID].Draw.Df_EdgeRound or 0)
                                elseif Draw.Type == 'circle' then
                                    im.DrawList_AddCircle(WDL, MsX_Start, MsY_Start, Rad, Clr)
                                elseif Draw.Type == 'circle fill' then
                                    im.DrawList_AddCircleFilled(WDL, MsX_Start, MsY_Start, Rad, Clr)
                                elseif Draw.Type == 'Text' then
                                    im.SetMouseCursor(ctx, im.MouseCursor_TextInput)
                                end
                            end

                            if im.IsMouseReleased(ctx, 0) and Mods == 0 and Draw.Type ~= 'Text' then
                                FX[FxGUID].Draw[(#FX[FxGUID].Draw or 0) + 1] = {}
                                local D = FX[FxGUID].Draw[(#FX[FxGUID].Draw or 1)]


                                LE.BeenEdited = true
                                --find the next available slot in table

                                if Draw.Type == 'circle' or Draw.Type == 'circle fill' then
                                    D.R = Rad
                                else
                                    D.R = Win_MsX
                                end

                                D.L = Win_MsX_Start
                                D.T = Win_MsY_Start
                                D.Type = Draw.Type
                                D.B = Win_MsY
                                D.clr = Draw.clr or 0xffffffff
                                --if not Draw.SelItm then Draw.SelItm = #D.Type end
                            end




                            if Draw.Type == 'Text' and IsLBtnClicked and Mods == 0 then
                                AddText = #D.Type + 1
                            end
                        end
                    end
                    HvringItmSelector = nil
                    if AddText then
                        im.OpenPopup(ctx, 'Drawlist Add Text Menu')
                    end

                    if im.BeginPopup(ctx, 'Drawlist Add Text Menu') then
                        im.SetKeyboardFocusHere(ctx)

                        enter, NewDrawTxt = im.InputText(ctx, '##' .. 'DrawTxt', NewDrawTxt)
                        --im.SetItemDefaultFocus( ctx)

                        if im.IsWindowAppearing(ctx) then
                            table.insert(D.L, Win_MsX_Start);
                            table.insert(D.T, Win_MsY_Start);;
                            table.insert(D.Type, Draw.Type)
                            table.insert(D.B, Win_MsY)
                            table.insert(D.clr, Draw.clr)
                        end


                        if AddText then
                            D.Txt[AddText] = NewDrawTxt
                        end

                        if im.IsItemDeactivatedAfterEdit(ctx) then
                            D.Txt[#D.Txt] = NewDrawTxt
                            AddText = nil;
                            NewDrawTxt = nil



                            im.CloseCurrentPopup(ctx)
                        end

                        im.SetItemDefaultFocus(ctx)



                        im.EndPopup(ctx)
                    end
                    if LBtnRel then Draw.CurrentylDrawing = nil end

                    if im.IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil then
                        if IsLBtnClicked then
                            Draw.SelItm = nil
                            Draw.Time = 1
                        end
                    end
                    if Draw.Time > 0 then Draw.Time = Draw.Time + 1 end
                    if Draw.Time > 6 then Draw.Time = 0 end

                    if FX[FxGUID].Draw then
                        for i, D in ipairs(FX[FxGUID].Draw) do
                            local ID = FX_Name .. i
                            local CircleX, CircleY = Win_L + D.L, Win_T + D.T
                            local FDL = im.GetForegroundDrawList(ctx)
                            im.DrawList_AddCircle(FDL, CircleX, CircleY, 7, 0x99999999)
                            im.DrawList_AddText(FDL, Win_L + D.L - 2, Win_T + D.T - 7, 0x999999ff, i)


                            if Draw.SelItm == i then
                                im.DrawList_AddCircleFilled(WDL, CircleX, CircleY, 7, 0x99999955)
                            end


                            --if hover on item node ...
                            if im.IsMouseHoveringRect(ctx, CircleX - 5, CircleY - 5, CircleX + 5, CircleY + 10) then
                                HvringItmSelector = true
                                im.SetMouseCursor(ctx, im.MouseCursor_ResizeAll)
                                if DragItm == nil then
                                    im.DrawList_AddCircle(WDL, CircleX, CircleY, 9, 0x999999ff)
                                end
                                if IsLBtnClicked and Mods == 0 then
                                    Draw.SelItm = i
                                    DragItm = i
                                end


                                if IsLBtnClicked and Mods == Alt then
                                    table.remove(D.Type, i)
                                    table.remove(D.L, i)
                                    table.remove(D.R, i)
                                    table.remove(D.T, i)
                                    table.remove(D.B, i)
                                    if D.Txt then table.remove(D.Txt, SetMinMax(i, 1, #D.Txt)) end
                                    if D.clr then table.remove(D.clr, SetMinMax(i, 1, #D.clr)) end
                                    if im.BeginPopup(ctx, 'Drawlist Add Text Menu') then
                                        im.CloseCurrentPopup(ctx)
                                        im.EndPopup(ctx)
                                    end
                                end
                            end

                            if not IsLBtnHeld then DragItm = nil end
                            if LBtnDrag and DragItm == i then --- Drag node to reposition
                                im.SetMouseCursor(ctx, im.MouseCursor_ResizeAll)
                                im.DrawList_AddCircleFilled(WDL, CircleX, CircleY, 7, 0x00000033)
                                local Dx, Dy = im.GetMouseDelta(ctx)
                                if D.Type[DragItm] ~= 'circle' and D.Type[DragItm] ~= 'circle fill' then
                                    D.R = D.R + Dx -- this is circle's radius
                                end
                                D.L = D.L + Dx
                                D.T = D.T + Dy
                                D.B = D.B + Dy
                            end
                        end
                    end
                end --- end of if draw mode is active

                if FX[FxGUID].Draw and not FX[FxGUID].Collapse then
                    for i, Type in ipairs(FX[FxGUID].Draw) do
                        FX[FxGUID].Draw[i] = FX[FxGUID].Draw[i] or {}
                        local D = FX[FxGUID].Draw[i]
                        local L = Win_L + D.L
                        local T = Win_T + D.T
                        local R = Win_L + (D.R or 0)
                        local B = Win_T + D.B
                        local Round = FX[FxGUID].Draw.Df_EdgeRound or 0

                        if D.Type == 'line' then
                            im.DrawList_AddLine(WDL, L, T, R, T, D.clr or 0xffffffff)
                        elseif D.Type == 'V-line' then
                            im.DrawList_AddLine(WDL, Win_L + D.L, Win_T + D.T,
                                Win_L + D.L, Win_T + D.B, D.clr or 0xffffffff)
                        elseif D.Type == 'rectangle' then
                            im.DrawList_AddRect(WDL, L, T, R, B, D.clr or 0xffffffff, Round)
                        elseif D.Type == 'rect fill' then
                            im.DrawList_AddRectFilled(WDL, L, T, R, B, D.clr or 0xffffffff,
                                Round)
                        elseif D.Type == 'circle' then
                            im.DrawList_AddCircle(WDL, L, T, D.R, D.clr or 0xffffffff)
                        elseif D.Type == 'circle fill' then
                            im.DrawList_AddCircleFilled(WDL, L, T, D.R,
                                D.clr or 0xffffffff)
                        elseif D.Type == 'Text' and D.Txt then
                            im.DrawList_AddTextEx(WDL, D.Font or Font_Andale_Mono_13,
                                D.FtSize or 13, L, T, D.clr or 0xffffffff, D.Txt)
                        elseif D.Type == 'Picture' then
                            if not D.Image then
                                im.DrawList_AddRectFilled(WDL, L, T, R, B, 0xffffff33, Round)
                                im.DrawList_AddTextEx(WDL, nil, 12, L, T + (B - T) / 2,
                                    0xffffffff, 'Add Image path', R - L)
                            else
                                if D.KeepImgRatio then
                                    local w, h = im.Image_GetSize(D.Image)

                                    local H_ratio = w / h
                                    local size = R - L


                                    im.DrawList_AddImage(WDL, D.Image, L, T, L + size,
                                        T + size * H_ratio, 0, 0, 1, 1, D.clr or 0xffffffff)
                                else
                                    im.DrawList_AddImageQuad(WDL, D.Image, L, T, R, T, R, B,
                                        L, B,
                                        _1, _2, _3, _4, _5, _6, _7, _8, D.clr or 0xffffffff)
                                end
                            end
                            -- ImageAngle(ctx, Image, 0, R - L, B - T, L, T)
                        end
                    end
                end

                if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true and Mods ~= Apl then -- Resize FX or title btn
                    MouseX, MouseY = im.GetMousePos(ctx)
                    Win_L, Win_T = im.GetItemRectMin(ctx)
                    Win_R, _ = im.GetItemRectMax(ctx); Win_B = Win_T + 220
                    WinDrawList = im.GetWindowDrawList(ctx)
                    im.DrawList_AddRectFilled(WinDrawList, Win_L or 0, Win_T or 0, Win_R or 0,
                        Win_B, 0x00000055)
                    --draw grid

                    if im.IsKeyPressed(ctx, im.Key_Equal) then
                        LE.GridSize = LE.GridSize + 5
                    elseif im.IsKeyPressed(ctx, im.Key_Minus) then
                        LE.GridSize = LE.GridSize - 5
                    end

                    for i = 0, FX[FXGUID[FX_Idx]].Width or DefaultWidth, LE.GridSize do
                        im.DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B, 0x44444455)
                    end
                    for i = 0, 220, LE.GridSize do
                        im.DrawList_AddLine(WinDrawList, Win_L,
                            Win_T + i, Win_R, Win_T + i, 0x44444455)
                    end

                    im.DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B,
                        0x66666677, 1)


                    if im.IsMouseHoveringRect(ctx, Win_R - 5, Win_T, Win_R + 5, Win_B) then
                        im.DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B,
                            0xffffffff, 3)
                        im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW)

                        if IsLBtnClicked then
                            LE.ResizingFX = FX_Idx --@Todo change fxidx to fxguid
                        end
                    end


                    if LE.ResizingFX == FX_Idx and IsLBtnHeld then
                        im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW)

                        im.DrawList_AddRectFilled(WinDrawList, Win_L or 0, Win_T or 0,
                            Win_R or 0, Win_B, 0x00000055)
                        local MsDragDeltaX, MsDragDeltaY = im.GetMouseDragDelta(ctx); local Dx, Dy =
                            im.GetMouseDelta(ctx)
                        if not FX[FxGUID].Width then FX[FxGUID].Width = DefaultWidth end
                        FX[FxGUID].Width = FX[FxGUID].Width + Dx; LE.BeenEdited = true
                    end
                    if not IsLBtnHeld then LE.ResizingFX = nil end
                end


                if FX.Enable[FX_Idx] == nil then
                    FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
                end

                im.SameLine(ctx, nil, 0)
                if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                    im.BeginDisabled(ctx); R, T = im.GetItemRectMax(ctx)
                end





                AddWindowBtn(FxGUID, FX_Idx )


                im.PushStyleColor(ctx, im.Col_Border, getClr(im.Col_FrameBg))


                -- Add Prm popup
                if im.BeginPopup(ctx, 'Add Parameter' .. FxGUID, im.WindowFlags_AlwaysVerticalScrollbar) then
                    local CheckBox, rv = {}, {}
                    if im.Button(ctx, 'Add all parameters', -1) then
                        for i = 0, r.TrackFX_GetNumParams(LT_Track, FX_Idx) - 1, 1 do
                            local P_Name = select(2, r.TrackFX_GetParamName(LT_Track, FX_Idx, i))

                            if not FX[FxGUID][i + 1] then
                                StoreNewParam(FxGUID, P_Name, i, FX_Idx, true)
                            else
                                local RptPrmFound
                                for I = 1, #FX[FxGUID], 1 do
                                    if FX[FxGUID][I].Num == i then RptPrmFound = true end
                                end

                                if not RptPrmFound then
                                    StoreNewParam(FxGUID, P_Name, i, FX_Idx, true)
                                    SyncTrkPrmVtoActualValue()
                                end
                            end
                        end
                    end


                    AddPrmPopupOpen = FxGUID
                    if not PrmFilterTxt then AddPrmWin_W, AddPrmWin_H = im.GetWindowSize(ctx) end
                    im.SetWindowSize(ctx, 500, 500, condIn)

                    local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                    if not im.ValidatePtr(PrmFilter, "ImGui_TextFilter*") then PrmFilter = im.CreateTextFilter(PrmFilterTxt) end 




                    im.SetNextItemWidth(ctx, 60)

                    if not FX[FxGUID].NotFirstOpenPrmWin then
                        im.SetKeyboardFocusHere(ctx, offsetIn)
                    end

                    if im.TextFilter_Draw(PrmFilter, ctx, '##PrmFilterTxt', -1 - (SpaceForBtn or 0)) then
                        PrmFilterTxt = im.TextFilter_Get(PrmFilter)
                        im.TextFilter_Set(PrmFilter, PrmFilterTxt)
                    end

                    for i = 1, Ct, 1 do
                        if FX[FxGUID][i] then
                            CheckBox[FX[FxGUID][i].Num] = true
                        end
                    end

                    for i = 1, Ct, 1 do
                        local P_Name = select(2,
                            r.TrackFX_GetParamName(LT_Track, FX_Idx, i - 1))
                        if im.TextFilter_PassFilter(PrmFilter, P_Name) then
                            rv[i], CheckBox[i - 1] = im.Checkbox(ctx, (i - 1) .. '. ' .. P_Name,
                                CheckBox[i - 1])
                            if rv[i] then
                                local RepeatPrmFound

                                for I = 1, Ct, 1 do
                                    if FX[FxGUID][I] then
                                        if FX[FxGUID][I].Num == i - 1 then RepeatPrmFound = I end
                                    end
                                end
                                if RepeatPrmFound then
                                    DeletePrm(FxGUID, RepeatPrmFound, FX_Idx)
                                else
                                    StoreNewParam(FxGUID, P_Name, i - 1, FX_Idx, true)
                                    SyncTrkPrmVtoActualValue()
                                end
                            end
                        end
                    end
                    FX[FxGUID].NotFirstOpenPrmWin = true
                    im.EndPopup(ctx)
                elseif AddPrmPopupOpen == FxGUID then
                    PrmFilterTxt = nil
                    FX[FxGUID].NotFirstOpenPrmWin = nil
                end


                im.PopStyleColor(ctx)


                if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                    local L, T = im.GetItemRectMin(ctx); local R, _ = im.GetItemRectMax(
                        ctx); B = T + 20
                    im.DrawList_AddCircleFilled(WinDrawList, R, T + 10, 3, 0x999999ff)
                    im.DrawList_AddRect(WinDrawList, L, T, R, T + 20, 0x999999ff)

                    if MouseX > L and MouseX < R and MouseY > T and MouseY < B then
                        im.DrawList_AddRectFilled(WinDrawList, L, T, R, T + 20, 0x99999955)
                        if IsLBtnClicked then
                            LE.SelectedItem = 'Title'
                            LE.ChangingTitleSize = true
                            LE.MouseX_before, _ = im.GetMousePos(ctx)
                        elseif IsRBtnClicked then
                            im.OpenPopup(ctx, 'Fx Module Menu')
                        end
                    end

                    if LE.SelectedItem == 'Title' then
                        im.DrawList_AddRect(WinDrawList, L, T, R,
                            T + 20, 0x999999ff)
                    end

                    if MouseX > R - 5 and MouseX < R + 5 and MouseY > T and MouseY < B then --if hover on right edge
                        if IsLBtnClicked then LE.ChangingTitleSize = true end
                    end

                    if LBtnDrag and LE.ChangingTitleSize then
                        im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW)
                        DeltaX, DeltaY = im.GetMouseDelta(ctx)
                        local AddedDelta = AddedDelta or 0 + DeltaX
                        LE.MouseX_after, _ = im.GetMousePos(ctx)
                        local MouseDiff = LE.MouseX_after - LE.MouseX_before

                        if FX[FxGUID].TitleWidth == nil then
                            FX[FxGUID].TitleWidth = DefaultWidth - 30
                        end
                        if Mods == 0 then
                            if MouseDiff > LE.GridSize then
                                FX[FxGUID].TitleWidth = FX[FxGUID].TitleWidth + LE.GridSize; LE.MouseX_before =
                                    im.GetMousePos(ctx); LE.BeenEdited = true
                            elseif MouseDiff < -LE.GridSize then
                                FX[FxGUID].TitleWidth = FX[FxGUID].TitleWidth - LE.GridSize; LE.MouseX_before =
                                    im.GetMousePos(ctx); LE.BeenEdited = true
                            end
                        end
                        if Mods == Shift then
                            FX[FxGUID].TitleWidth = FX[FxGUID].TitleWidth + DeltaX; LE.BeenEdited = true
                        end
                    end
                    if IsLBtnHeld == false then LE.ChangingTitleSize = nil end

                    im.EndDisabled(ctx)
                end








                if DebugMode and im.IsItemHovered(ctx) then tooltip('FX_Idx = ' .. FX_Idx) end
                if DebugMode and im.IsKeyDown(ctx, 84) then tooltip(TrkID) end





                --r.Undo_OnStateChangeEx(string descchange, integer whichStates, integer trackparm) -- @todo Detect FX deletion






                if im.BeginPopup(ctx, 'Fx Module Menu') then
                    if not FX[FxGUID].MorphA then
                        if im.Button(ctx, 'Preset Morphing', 160) then
                            FX[FxGUID].MorphA = {}
                            FX[FxGUID].MorphB = {}
                            local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                            for i = 0, PrmCount - 4, 1 do
                                local Prm_Val, minval, maxval = r.TrackFX_GetParamNormalized(
                                    LT_Track, FX_Idx, i)
                                FX[FxGUID].MorphA[i] = Prm_Val
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: FX Morph A' .. i .. FxGUID, Prm_Val, true)
                            end
                            RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track, PrmCount)
                            --[[ r.SetProjExtState(r0oj, 'FX Devices', string key, string value) ]]
                            FX[FxGUID].MorphHide = nil
                            im.CloseCurrentPopup(ctx)
                        end
                    else
                        if not FX[FxGUID].MorphHide then
                            if im.Button(ctx, 'Hide Morph Slider', 160) then
                                FX[FxGUID].MorphHide = true
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: FX Morph Hide' .. FxGUID, 'true', true)
                                im.CloseCurrentPopup(ctx)
                            end
                        else
                            if im.Button(ctx, 'Show Morph Slider', 160) then
                                FX[FxGUID].MorphHide = nil
                                im.CloseCurrentPopup(ctx)
                            end
                        end
                    end

                    im.SameLine(ctx)
                    if not FX[FxGUID].MorphA then
                        im.BeginDisabled(ctx)
                        im.PushStyleColor(ctx, im.Col_Text,
                            getClr(im.Col_TextDisabled))
                    end
                    local rv = im.Button(ctx, '##g', 20, 20) -- settings icon
                    DrawListButton(WDL, 'g', r.ImGui_GetColor(ctx, r.ImGui_Col_Button()), nil, true, icon1_middle, false) -- wrench
                    TooltipUI("Open Preset Morph settings window", im.HoveredFlags_Stationary)
                    if rv then 
                        if OpenMorphSettings then
                            OpenMorphSettings = FxGUID
                        else
                            OpenMorphSettings =
                                FxGUID
                        end
                        local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                        FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                        for i = 0, Ct - 4, 1 do --get param names
                            FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                            local rv, name             = r.TrackFX_GetParamName(LT_Track,
                                FX_Idx, i)
                            FX[FxGUID].PrmList[i].Name = name
                        end
                        im.CloseCurrentPopup(ctx)
                    end
                    if not FX[FxGUID].MorphA then
                        im.EndDisabled(ctx)
                        im.PopStyleColor(ctx)
                    end



                    if im.Button(ctx, 'Layout Edit mode', -FLT_MIN) then
                        if not FX.LayEdit then
                            FX.LayEdit = FxGUID
                        else
                            FX.LayEdit = false
                        end
                        CloseLayEdit = nil
                        im.CloseCurrentPopup(ctx)
                        if Draw.DrawMode[FxGUID] then Draw.DrawMode[FxGUID] = nil end
                    end


                    if im.Button(ctx, 'Save all values as default', -FLT_MIN) then
                        local dir_path = CurrentDirectory .. 'src'
                        local file_path = ConcatPath(dir_path, 'FX Default Values.ini')
                        local file = io.open(file_path, 'a+')

                        if file then
                            local FX_Name = ChangeFX_Name(FX_Name)
                            Content = file:read('*a')
                            local Ct = Content

                            local pos = Ct:find(FX_Name)
                            if pos then
                                file:seek('set', pos - 1)
                            else
                                file:seek('end')
                            end

                            file:write(FX_Name, '\n')
                            local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                            PrmCount = PrmCount - 4
                            file:write('Number of Params: ', PrmCount, '\n')

                            local function write(i, name, Value)
                                file:write(i, '. ', name, ' = ', Value or '', '\n')
                            end

                            for i = 0, PrmCount, 1 do
                                local V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                local _, N = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                write(i, N, V)
                            end

                            file:write('\n')


                            file:close()
                        end
                        im.CloseCurrentPopup(ctx)
                    end



                    if FX.Def_Type[FxGUID] ~= 'Knob' then
                        im.Text(ctx, 'Default Sldr Width:')
                        im.SameLine(ctx)
                        local SldrW_DrgSpd
                        if Mods == Shift then SldrW_DrgSpd = 1 else SldrW_DrgSpd = LE.GridSize end
                        im.SetNextItemWidth(ctx, -FLT_MIN)


                        Edited, FX.Def_Sldr_W[FxGUID] = im.DragInt(ctx,
                            '##' .. FxGUID .. 'Default Width', FX.Def_Sldr_W[FxGUID] or 160,
                            LE.GridSize, 50, 300)


                        if Edited then
                            r.SetProjExtState(0, 'FX Devices',
                                'Default Slider Width for FX:' .. FxGUID, FX.Def_Sldr_W[FxGUID])
                        end
                    end



                    im.Text(ctx, 'Default Param Type:')
                    im.SameLine(ctx)
                    im.SetNextItemWidth(ctx, -FLT_MIN)


                    if im.BeginCombo(ctx, '## P type', FX.Def_Type[FxGUID] or 'Slider', im.ComboFlags_NoArrowButton) then
                        if im.Selectable(ctx, 'Slider', false) then
                            FX.Def_Type[FxGUID] = 'Slider'
                            r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                FX.Def_Type[FxGUID])
                        elseif im.Selectable(ctx, 'Knob', false) then
                            FX.Def_Type[FxGUID] = 'Knob'
                            r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                FX.Def_Type[FxGUID])
                        elseif im.Selectable(ctx, 'Drag', false) then
                            FX.Def_Type[FxGUID] = 'Drag'
                            r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                FX.Def_Type[FxGUID])
                        end
                        im.EndCombo(ctx)
                    end
                    im.EndPopup(ctx)
                end

                if OpenMorphSettings then
                    im.SetNextWindowSizeConstraints(ctx, 500, 500, FLT_MAX, FLT_MAX)
                    Open, Oms = im.Begin(ctx, 'Preset Morph Settings ', Oms,
                        im.WindowFlags_NoCollapse | im.WindowFlags_NoDocking)
                    if Oms then
                        if FxGUID == OpenMorphSettings then
                            im.Text(ctx, 'Set blacklist parameters here: ')
                            local SpaceForBtn
                            if not im.ValidatePtr(Filter, "ImGui_TextFilter*") then
                                Filter = im.CreateTextFilter(FilterTxt)
                            end
                            im.Text(ctx, 'Filter :')
                            im.SameLine(ctx)
                            if FilterTxt then SpaceForBtn = 170 end
                            if im.TextFilter_Draw(Filter, ctx, '##', -1 - (SpaceForBtn or 0)) then
                                FilterTxt = im.TextFilter_Get(Filter)
                                im.TextFilter_Set(Filter, Txt)
                            end
                            if FilterTxt then
                                SL()
                                BL_All = im.Button(ctx, 'Blacklist all results')
                            end

                            im.Text(ctx, 'Save morphing settings to : ')
                            SL()
                            local Save_FX = im.Button(ctx, 'FX Instance', 80)
                            SL()
                            local Save_Proj = im.Button(ctx, 'Project', 80)
                            SL()
                            local Save_Glob = im.Button(ctx, 'Global', 80)
                            SL()
                            local FxNam = FX.Win_Name_S[FX_Idx]:gsub("%b()", "")
                            demo.HelpMarker(
                                'FX Instance: \nBlacklist will only apply to the current instance of ' ..
                                FxNam ..
                                '\n\nProject:\nBlacklist will apply to all instances of ' ..
                                FxNam ..
                                'in the current project\n\nGlobal:\nBlacklist will be applied to all instances of ' ..
                                FxNam ..
                                'across all projects.\n\nOrder of precedence goes from: FX Instance -> Project -> Global')



                            if Save_FX or Save_Proj or Save_Glob then
                                Tooltip_Timer = r.time_precise()
                                TTP_x, TTP_y = im.GetMousePos(ctx)
                                im.OpenPopup(ctx, '## Successfully saved preset morph')
                            end

                            if Tooltip_Timer then
                                if im.BeginPopupModal(ctx, '## Successfully saved preset morph', nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                                    im.Text(ctx, 'Successfully saved ')
                                    if im.IsMouseClicked(ctx, 0) then
                                        im.CloseCurrentPopup(
                                            ctx)
                                    end
                                    im.EndPopup(ctx)
                                end

                                if Tooltip_Timer + 3 < r.time_precise() then
                                    Tooltip_Timer = nil
                                    TTP_x = nil
                                    TTP_y = nil
                                end
                            end

                            --


                            if not FX[FxGUID].PrmList[1].Name then
                                FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                --[[ local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                for i=0, Ct-4, 1 do
                                    FX[FxGUID].PrmList[i]=FX[FxGUID].PrmList[i] or {}
                                    local rv, name = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                    FX[FxGUID].PrmList[i].Name  = name
                                end ]]

                                RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track,
                                    r.TrackFX_GetNumParams(LT_Track, FX_Idx), FX_Name)
                            else
                                im.BeginTable(ctx, 'Parameter List', 5, im.TableFlags_Resizable)
                                --im.TableSetupColumn( ctx, 'BL',  flagsIn, 20,  user_idIn)

                                im.TableHeadersRow(ctx)
                                im.SetNextItemWidth(ctx, 20)
                                im.TableSetColumnIndex(ctx, 0)

                                local rv = im.InvisibleButton(ctx, '##M', 20, 20) -- (/) icon
                                DrawListButton(WDL, 'M', 0x00000000, nil, true, icon1_middle, false)
                                im.TableSetColumnIndex(ctx, 1)
                                im.AlignTextToFramePadding(ctx)
                                im.Text(ctx, 'Parameter Name ')
                                im.TableSetColumnIndex(ctx, 2)
                                im.AlignTextToFramePadding(ctx)
                                im.Text(ctx, 'A')
                                im.TableSetColumnIndex(ctx, 3)
                                im.AlignTextToFramePadding(ctx)
                                im.Text(ctx, 'B')
                                im.TableNextRow(ctx)
                                im.TableSetColumnIndex(ctx, 0)




                                if --[[Last Touch]] LT_ParamNum and LT_FXGUID == FxGUID then
                                    local P = FX[FxGUID].PrmList
                                    local N = math.max(LT_ParamNum, 1)
                                    im.TableSetBgColor(ctx, 1,
                                        getClr(im.Col_TabUnfocused))
                                    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, 9)

                                    rv, P[N].BL = im.Checkbox(ctx, '##' .. N, P[N].BL)
                                    if P[N].BL then im.BeginDisabled(ctx) end

                                    im.TableSetColumnIndex(ctx, 1)
                                    im.Text(ctx, N .. '. ' .. (P[N].Name or ''))


                                    ------- A --------------------
                                    im.TableSetColumnIndex(ctx, 2)
                                    im.Text(ctx, 'A:')
                                    SL()
                                    im.SetNextItemWidth(ctx, -FLT_MIN)

                                    local i = LT_ParamNum or 0
                                    local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                        FX_Idx, i)
                                    if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                                        P.FormatV_A =
                                            GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV, i)
                                    end


                                    P.Drag_A, FX[FxGUID].MorphA[i] = im.DragDouble(ctx,
                                        '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1,
                                        P.FormatV_A or '')
                                    if P.Drag_A then
                                        P.FormatV_A = GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV, i)
                                    end

                                    SL()
                                    --------- B --------------------
                                    im.TableSetColumnIndex(ctx, 3)
                                    im.Text(ctx, 'B:')
                                    SL()

                                    local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                        FX_Idx, i)
                                    im.SetNextItemWidth(ctx, -FLT_MIN)
                                    if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                                        P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV, i)
                                    end


                                    P.Drag_B, FX[FxGUID].MorphB[i] = im.DragDouble(ctx,
                                        '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1,
                                        P.FormatV_B)
                                    if P.Drag_B then
                                        P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV, i)
                                    end


                                    if P[N].BL then im.EndDisabled(ctx) end
                                    --HighlightSelectedItem( 0xffffff33 , OutlineClr, 1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect', Foreground)

                                    im.PopStyleVar(ctx)
                                    im.TableNextRow(ctx)
                                    im.TableSetColumnIndex(ctx, 0)
                                end
                                local Load_FX_Proj_Glob
                                local _, FXsBL = r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Morph_BL' .. FxGUID, '', false)
                                if FXsBL == 'Has Blacklist saved to FX' then -- if there's FX-specific BL settings
                                    Load_FX_Proj_Glob = 'FX'
                                else
                                    local _, whether = r.GetProjExtState(0,
                                        'FX Devices - Preset Morph',
                                        'Whether FX has Blacklist' .. (FX.Win_Name_S[FX_Idx] or ''))
                                    if whether == 'Yes' then Load_FX_Proj_Glob = 'Proj' end
                                end

                                local TheresBL = TheresBL or {}
                                local hasBL
                                for i, v in ipairs(FX[FxGUID].PrmList) do
                                    local P = FX[FxGUID].PrmList[i - 1]
                                    local prm = FX[FxGUID].PrmList

                                    if im.TextFilter_PassFilter(Filter, P.Name) --[[ and (i~=LT_ParamNum and LT_FXGUID==FxGUID) ]] then
                                        i = i - 1
                                        if prm[i].BL == nil then
                                            if Load_FX_Proj_Glob == 'FX' then
                                                local _, V = r.GetSetMediaTrackInfo_String(
                                                    LT_Track,
                                                    'P_EXT: Morph_BL' .. FxGUID .. i, '', false)
                                                if V == 'Blacklisted' then prm[i].BL = true end
                                            end
                                            --[[  elseif Load_FX_Proj_Glob== 'Proj' then
                                                local rv, BLprm  = r.GetProjExtState(0,'FX Devices - Preset Morph', FX.Win_Name_S[FX_Idx]..' Blacklist '..i)
                                                if BLprm~='' and BLprm then  BLpm = tonumber(BLprm)
                                                    if BLprm then prm[1].BL = true  end
                                                end
                                            end ]]
                                        end
                                        if BL_All --[[BL all filtered params ]] then if P.BL then P.BL = false else P.BL = true end end
                                        rv, prm[i].BL = im.Checkbox(ctx, '## BlackList' .. i,
                                            prm[i].BL)

                                        im.TableSetColumnIndex(ctx, 1)
                                        if P.BL then
                                            im.PushStyleColor(ctx, im.Col_Text,
                                                getClr(im.Col_TextDisabled))
                                        end


                                        im.Text(ctx, i .. '. ' .. (P.Name or ''))



                                        ------- A --------------------
                                        im.TableSetColumnIndex(ctx, 2)
                                        im.Text(ctx, 'A:')
                                        SL()

                                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                            FX_Idx,
                                            i)
                                        im.SetNextItemWidth(ctx, -FLT_MIN)
                                        if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                                            P.FormatV_A =
                                                GetFormatPrmV(FX[FxGUID].MorphA[i + 1], OrigV, i)
                                        end


                                        P.Drag_A, FX[FxGUID].MorphA[i] = im.DragDouble(ctx,
                                            '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1,
                                            P.FormatV_A or '')
                                        if P.Drag_A then
                                            P.FormatV_A = GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV,
                                                i)
                                            --[[ r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, FX[FxGUID].MorphA[i])
                                            _,P.FormatV_A = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,i)
                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, OrigV)  ]]
                                        end

                                        SL()

                                        --------- B --------------------
                                        im.TableSetColumnIndex(ctx, 3)
                                        im.Text(ctx, 'B:')
                                        SL()

                                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                            FX_Idx,
                                            i)
                                        im.SetNextItemWidth(ctx, -FLT_MIN)
                                        if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                                            P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i] or 0,
                                                OrigV, i)
                                        end

                                        P.Drag_B, FX[FxGUID].MorphB[i] = im.DragDouble(ctx,
                                            '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1,
                                            P.FormatV_B)
                                        if P.Drag_B then
                                            P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV,
                                                i)
                                        end


                                        if Save_FX then
                                            if P.BL then
                                                hasBL = true
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: Morph_BL' .. FxGUID .. i, 'Blacklisted',
                                                    true)
                                            else
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: Morph_BL' .. FxGUID .. i, '', true)
                                            end
                                            if hasBL then
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: Morph_BL' .. FxGUID,
                                                    'Has Blacklist saved to FX', true)
                                            else
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: Morph_BL' .. FxGUID, '', true)
                                            end
                                        elseif Save_Proj then
                                            if P.BL then table.insert(TheresBL, i) end
                                        elseif Save_Glob then
                                            if P.BL then table.insert(TheresBL, i) end
                                        end

                                        im.SetNextItemWidth(ctx, -1)

                                        if P.BL then im.PopStyleColor(ctx) end

                                        im.TableNextRow(ctx)
                                        im.TableSetColumnIndex(ctx, 0)
                                    end
                                end

                                if Save_Proj then
                                    if TheresBL[1] then
                                        r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                            'Whether FX has Blacklist' .. FX.Win_Name_S[FX_Idx],
                                            'Yes')
                                    else
                                        r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                            'Whether FX has Blacklist' .. FX.Win_Name_S[FX_Idx], 'No')
                                    end
                                    for i, V in ipairs(FX[FxGUID].MorphA) do
                                        local PrmBLed
                                        for I, v in ipairs(TheresBL) do
                                            if i == v then PrmBLed = v end
                                        end
                                        if PrmBLed then
                                            r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                FX.Win_Name_S[FX_Idx] .. ' Blacklist ' .. i, PrmBLed)
                                        else
                                            r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                FX.Win_Name_S[FX_Idx] .. ' Blacklist ' .. i, '')
                                        end
                                    end
                                    --else r.SetProjExtState(0,'FX Devices - Preset Morph','Whether FX has Blacklist'..FX.Win_Name_S[FX_Idx], '')
                                elseif TheresBL[1] and Save_Glob then
                                    file, file_path = CallFile('w', FX.Win_Name_S[FX_Idx] .. '.ini',
                                        'Preset Morphing')
                                    if file then
                                        for i, V in ipairs(TheresBL) do
                                            file:write(i, ' = ', V, '\n')
                                        end
                                        file:close()
                                    end
                                end

                                im.EndTable(ctx)
                            end
                        end
                        im.End(ctx)
                    else
                        im.End(ctx)
                        OpenMorphSettings = false
                    end
                end

                ------------------------------------------
                ------ Collapse Window
                ------------------------------------------

                local FX_Idx = FX_Idx or 1



                r.gmem_attach('ParamValues')
                FX.Win_Name_S[FX_Idx] = ChangeFX_Name(FX.Win_Name[FX_Idx] or FX_Name)

                FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
                FX_Name = string.gsub(FX_Name, '%-', ' ')






                im.SameLine(ctx)

                --------------------------------
                ----Area right of window title
                --------------------------------
                function SyncWetValues(id)
                    local id = FX_Idx or id
                    --when track change
                    if Wet.Val[id] == nil or TrkID ~= TrkID_End or FXCountEndLoop ~= Sel_Track_FX_Count then -- if it's nil
                        Glob.SyncWetValues = true
                    end

                    if Glob.SyncWetValues == true then
                        Wet.P_Num[id] = r.TrackFX_GetParamFromIdent(LT_Track, id, ':wet')
                        Wet.Get = r.TrackFX_GetParamNormalized(LT_Track, id,
                            Wet.P_Num[id])
                        Wet.Val[id] = Wet.Get
                    end
                    if Glob.SyncWetValues == true and id == Sel_Track_FX_Count - 1 then
                        Glob.SyncWetValues = false
                    end
                    if LT_ParamNum == Wet.P_Num[id] and focusedFXState == 1 then
                        Wet.Get = r.TrackFX_GetParamNormalized(LT_Track, id,
                            Wet.P_Num[id])
                        Wet.Val[id] = Wet.Get
                    elseif LT_ParamNum == FX[FxGUID].DeltaP then
                        FX[FxGUID].DeltaP_V = r.TrackFX_GetParamNormalized(LT_Track, id,
                            FX[FxGUID].DeltaP)
                    end
                end

                if FindStringInTable(SpecialLayoutFXs, FX_Name) == false and not FindStringInTable(PluginScripts, FX.Win_Name_S[FX_Idx]) then
                    SyncWetValues()

                    if FX[FxGUID].Collapse ~= true then
                        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 1, 0,
                            1, FX_Idx)
                    end

                    if im.BeginDragDropTarget(ctx) then
                        rv, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                        if rv then
                        end
                        im.EndDragDropTarget(ctx)
                    end
                end
                -- im.PopStyleVar(ctx) --StyleVar#4  POP (Things in the header of FX window)

                ------------------------------------------
                ------ Generic FX's knobs and sliders area
                ------------------------------------------


                local function Decide_If_Create_Regular_Layout()
                    if not FX[FxGUID].Collapse and FindStringInTable(BlackListFXs, FX_Name) ~= true and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                        local FX_has_Plugin
                        for i, v in pairs(PluginScripts) do
                            if FX_Name:find(v) then
                                FX_has_Plugin = true
                            end
                        end

                        if not FX_has_Plugin then
                            return true
                        else
                            if FX[FxGUID].Compatible_W_regular then return true end
                        end
                    end
                end

                if Decide_If_Create_Regular_Layout() then
                    local WinP_X; local WinP_Y;
                    --_, foo = AddKnob(ctx, 'test', foo or 0  , 0, 100 )
                    if FX.Enable[FX_Idx] == true then
                        -- Params Colors-----
                        --[[ im.PushStyleColor(ctx, im.Col_FrameBg, 0x32403aff)
                        im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x44444488)

                        times = 2 ]]
                    else
                        --[[ im.PushStyleColor(ctx, im.Col_FrameBg, 0x17171744)
                        im.PushStyleColor(ctx, im.Col_Text, 0x66666644)
                        im.PushStyleColor(ctx, im.Col_SliderGrab, 0x66666644)
                        im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x66666622)
                        im.PushStyleColor(ctx, im.Col_FrameBgHovered, 0x44444422)
                        times = 5 ]]
                    end

                    if FX[FxGUID].Round then
                        im.PushStyleVar(ctx,
                            im.StyleVar_FrameRounding, FX[FxGUID].Round)
                    end
                    if FX[FxGUID].GrbRound then
                        im.PushStyleVar(ctx,
                            im.StyleVar_GrabRounding, FX[FxGUID].GrbRound)
                    end

                    if (FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true) and Mods ~= Apl then
                        im.BeginDisabled(ctx, true)
                    end
                    if FX.LayEdit then
                        LE.DragX, LE.DragY = im.GetMouseDragDelta(ctx, 0)
                    end

                    ------------------------------------------------------
                    -- Repeat as many times as stored Param on FX -------------
                    ------------------------------------------------------
                    --[[ for Fx_P, v in ipairs(FX[FxGUID])    do
                        if not FX[FxGUID][Fx_P].Name then table.remove(FX[FxGUID],Fx_P) end
                    end ]]
                    for Fx_P, v in ipairs(FX[FxGUID]) do --parameter faders
                        --FX[FxGUID][Fx_P]= FX[FxGUID][Fx_P] or {}



                        local FP = FX[FxGUID][Fx_P] ---@class FX_P

                        local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P];
                        local ID = FxGUID .. Fx_P
                        Rounding = 0.5

                        ParamX_Value = 'Param' ..
                            tostring(FP.Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID

                        ----Default Layouts
                        if not FP.PosX and not FP.PosY then
                            if FP.Type == 'Slider' or (not FP.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' or FP.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag' and FP.Type == nil) then
                                local Column = math.floor((Fx_P / 6) - 0.01)
                                local W = ((FX[FxGUID][Fx_P - Column * 6].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160) + GapBtwnPrmColumns) *
                                    Column
                                local Y = 30 * (Fx_P - (Column * 6))
                                im.SetCursorPos(ctx, W, Y)
                            elseif FP.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider' and FP.Type == nil) then
                                im.SetCursorPos(ctx, 17 * (Fx_P - 1), 30)
                            elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and FP.Type == nil) then
                                local KSz = Df.KnobSize
                                local G = 15
                                local Column = math.floor(Fx_P / 3 - 0.1)

                                im.SetCursorPos(ctx, KSz * (Column),
                                    26 + (KSz + G) * (Fx_P - (Column * 3) - 1))
                            end
                        end

                        if FP.PosX then im.SetCursorPosX(ctx, FP.PosX) end
                        if FP.PosY then im.SetCursorPosY(ctx, FP.PosY) end

                        rectminX, RectMinY = im.GetItemRectMin(ctx)
                        curX, CurY = im.GetCursorPos(ctx)
                        if CurY > 210 then
                            im.SetCursorPosY(ctx, 210)
                            CurY = 210
                        end
                        if curX < 0 then
                            im.SetCursorPosX(ctx, 0)
                        elseif curX > (FX[FxGUID].Width or DefaultWidth) then
                            im.SetCursorPosX(ctx, (FX[FxGUID].Width or DefaultWidth) - 10)
                        end

                        -- if prm has clr set, calculate colors for active and hvr clrs
                        if FP.BgClr then
                            local R, G, B, A = im.ColorConvertU32ToDouble4(FP.BgClr)
                            local H, S, V = im.ColorConvertRGBtoHSV(R, G, B)
                            local HvrV, ActV
                            if V > 0.9 then
                                HvrV = V - 0.1
                                ActV = V - 0.5
                            end
                            local R, G, B = im.ColorConvertHSVtoRGB(H, S, HvrV or V +
                                0.1)
                            local HvrClr = im.ColorConvertDouble4ToU32(R, G, B, A)
                            local R, G, B = im.ColorConvertHSVtoRGB(H, S, ActV or V + 0.2)
                            local ActClr = im.ColorConvertDouble4ToU32(R, G, B, A)
                            FP.BgClrHvr = HvrClr
                            FP.BgClrAct = ActClr
                        end


                        --- if there's condition for parameters --------
                        local CreateParam, ConditionPrms, Pass = nil, {}, {}

                        ---@param ConditionPrm "ConditionPrm"
                        ---@param ConditionPrm_PID "ConditionPrm_PID"
                        ---@param ConditionPrm_V_Norm "ConditionPrm_V_Norm"
                        ---@param ConditionPrm_V "ConditionPrm_V"
                        ---@return boolean
                        local function CheckIfCreate(ConditionPrm, ConditionPrm_PID,
                                                     ConditionPrm_V_Norm, ConditionPrm_V)
                            local Pass -- TODO should this be initialized to false?
                            if FP[ConditionPrm] then
                                if not FX[FxGUID][Fx_P][ConditionPrm_PID] then
                                    for i, v in ipairs(FX[FxGUID]) do
                                        if v.Num == FX[FxGUID][Fx_P][ConditionPrm] then
                                            FX[FxGUID][Fx_P][ConditionPrm_PID] =
                                                i
                                        end
                                    end
                                end
                                local PID = FP[ConditionPrm_PID]

                                if FX[FxGUID][PID].ManualValues then
                                    local V = round(
                                        r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                            FP[ConditionPrm]),
                                        3)
                                    if FP[ConditionPrm_V_Norm] then
                                        for i, v in ipairs(FP[ConditionPrm_V_Norm]) do
                                            if V == round(v, 3) then Pass = true end
                                        end
                                    end
                                else
                                    local _, V = r.TrackFX_GetFormattedParamValue(LT_Track,
                                        FX_Idx,
                                        FP[ConditionPrm])
                                    for i, v in ipairs(FP[ConditionPrm_V]) do
                                        if V == v then Pass = true end
                                    end
                                end
                            else
                                Pass = true
                            end
                            return Pass
                        end

                        if FP['ConditionPrm'] then
                            if CheckIfCreate('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V_Norm', 'ConditionPrm_V') then
                                local DontCretePrm
                                for i = 2, 5, 1 do
                                    if CheckIfCreate('ConditionPrm' .. i, 'ConditionPrm_PID' .. i, 'ConditionPrm_V_Norm' .. i, 'ConditionPrm_V' .. i) then
                                    else
                                        DontCretePrm = true
                                    end
                                end
                                if not DontCretePrm then CreateParam = true end
                            end
                        end




                        if CreateParam or not FP.ConditionPrm then
                            local Prm = FP
                            local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]




                            if Prm and FxGUID then

                                --[[ if not im.ValidatePtr(FX[FxGUID].DL_SPLITER, 'ImGui_DrawListSplitter*') then
                                    FX[FxGUID].DL_SPLITER = im.CreateDrawListSplitter(WDL)
                                end
                                --local FX[FxGUID].DL_SPLITER = im.CreateDrawListSplitter(WDL)


                                im.DrawListSplitter_Split(FX[FxGUID].DL_SPLITER, 2)
                                im.DrawListSplitter_SetCurrentChannel(FX[FxGUID].DL_SPLITER, 1) ]]
                                --Prm.V = Prm.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Prm.Num)
                                --- Add Parameter controls ---------
                                if Prm.Type == 'Slider' or (not Prm.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' then
                                    AddSlider(ctx, '##' .. (Prm.Name or Fx_P) .. FX_Name, Prm.CustomLbl,
                                        Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Style,
                                        Prm.Sldr_W or FX.Def_Sldr_W[FxGUID], 0, Disable, Vertical,
                                        GrabSize, Prm.Lbl, 8)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Sldr', curX, CurY)
                                elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and Prm.Type == nil) then
                                    AddKnob(ctx, '##' .. Prm.Name .. FX_Name, Prm.CustomLbl, Prm.V, 0, 1, Fx_P,
                                        FX_Idx, Prm.Num, Prm.Style, Prm.Sldr_W or Df.KnobRadius, 0,
                                        Disabled, Prm.FontSize, Prm.Lbl_Pos or 'Bottom', Prm.V_Pos)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Knob', curX, CurY)
                                elseif Prm.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider') then
                                    AddSlider(ctx, '##' .. Prm.Name .. FX_Name, Prm.CustomLbl, Prm.V or 0, 0, 1,
                                        Fx_P, FX_Idx, Prm.Num, Style, Prm.Sldr_W or 15, 0, Disable,
                                        'Vert', GrabSize, Prm.Lbl, nil, Prm.Sldr_H or 160)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'V-Slider', curX, CurY)
                                elseif Prm.Type == 'Switch' then
                                    AddSwitch(LT_Track, FX_Idx, Prm.V or 0, Prm.Num, Prm.BgClr,
                                        Prm.CustomLbl or 'Use Prm Name as Lbl', Fx_P, F_Tp,
                                        Prm.FontSize, FxGUID)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Switch', curX, CurY)
                                elseif Prm.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag') then
                                    AddDrag(ctx, '##' .. Prm.Name .. FX_Name, Prm.CustomLbl or Prm.Name,
                                        Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Prm.Style,
                                        Prm.Sldr_W or FX.Def_Sldr_W[FxGUID] or Df.Sldr_W, -1, Disable,
                                        Lbl_Clickable, Prm.Lbl_Pos, Prm.V_Pos, Prm.DragDir)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Drag', curX, CurY)
                                elseif Prm.Type == 'Selection' then
                                    AddCombo(ctx, LT_Track, FX_Idx,
                                        Prm.Name .. FxGUID .. '## actual', Prm.Num,
                                        FP.ManualValuesFormat or 'Get Options', Prm.Sldr_W, Prm.Style, FxGUID, Fx_P,
                                        FP.ManualValues)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Selection', curX,
                                        CurY)
                                end

                                if im.IsItemClicked(ctx) and LBtnDC then
                                    if Mods == 0 then
                                        local dir_path = CurrentDirectory .. 'src'
                                        local file_path = ConcatPath(dir_path,
                                            'FX Default Values.ini')
                                        local file = io.open(file_path, 'r')

                                        if file then
                                            local FX_Name = ChangeFX_Name(FX_Name)
                                            Content = file:read('*a')
                                            local Ct = Content
                                            local P_Num = Prm.Num
                                            local _, P_Nm = r.TrackFX_GetParamName(LT_Track,
                                                FX_Idx,
                                                P_Num)
                                            local Df = RecallGlobInfo(Ct,
                                                P_Num .. '. ' .. P_Nm .. ' = ', 'Num')
                                            if Df then
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                    P_Num,
                                                    Df)
                                                ToDef = { ID = FX_Idx, P = P_Num, V = Df }
                                            end
                                        end
                                    elseif Mods == Alt then
                                        if Prm.Deletable then
                                            DeletePrm(FxGUID, Fx_P, FX_Idx)
                                        end
                                    end
                                end

                                if ToDef.ID and ToDef.V then
                                    r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef.V)
                                    if Prm.WhichCC then
                                        if Trk.Prm.WhichMcros[Prm.WhichCC .. TrkID] then
                                            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, ToDef.ID,
                                                "param." .. ToDef.P .. ".plink.active", 0) -- 1 active, 0 inactive
                                            r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef.V)
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX' ..
                                                FxGUID ..
                                                'Prm' .. ToDef.P .. 'Value before modulation',
                                                ToDef.V, true)
                                            r.gmem_write(7, Prm.WhichCC) --tells jsfx to retrieve P value
                                            PM.TimeNow = r.time_precise()
                                            r.gmem_write(11000 + Prm.WhichCC, ToDef.V)
                                            ParameterMIDILink(ToDef.ID, ToDef.P, 1, false, 15, 16, 176, Prm.WhichCC, false)
                                        end
                                    end
                                    Prm.V = ToDef.V

                                    ToDef = {}
                                end


                                if FP.Draw then
                                    --im.DrawListSplitter_SetCurrentChannel(FX[FxGUID].DL_SPLITER, 0)

                                    local function Repeat(rpt, va, Xgap, Ygap, func, Gap, RPTClr, CLR)
                                        if rpt and rpt ~= 0 then
                                            local RPT = rpt
                                            if va and va ~= 0 then RPT = rpt * Prm.V * va end
                                            for i = 0, RPT - 1, 1 do
                                                local Clr = BlendColors(CLR or 0xffffffff,
                                                    RPTClr or 0xffffffff, i / RPT)

                                                func(i * (Xgap or 0), i * (Ygap or 0), i * (Gap or 0),
                                                    Clr)
                                            end
                                        else
                                            func(Xgap)
                                        end
                                    end




                                    local GR = tonumber(select(2,
                                        r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'GainReduction_dB')))

                                    for i, v in ipairs(FP.Draw) do
                                        local x, y              = im.GetItemRectMin(ctx)
                                        Prm.V                   = Prm.V or 0
                                        local x                 = x + (v.X_Offset or 0) + (Prm.V * (v.X_Offset_VA or 0)) +
                                            ((GR or 0) * (v.X_Offset_VA_GR or 0))
                                        local y                 = y + (v.Y_Offset or 0) + (Prm.V * (v.Y_Offset_VA or 0)) +
                                            ((GR or 0) * (v.Y_Offset_VA_GR or 0))
                                        local Thick             = (v.Thick or 2)
                                        local Gap, X_Gap, Y_Gap = v.Gap, v.X_Gap, v.Y_Gap
                                        local Clr_VA
                                        if v.Clr_VA then
                                            Clr_VA = BlendColors(v.Clr or 0xffffffff,
                                                v.Clr_VA, Prm.V)
                                        end



                                        if v.X_Gap_VA and v.X_Gap_VA ~= 0 then
                                            X_Gap = (v.X_Gap or 0) * Prm.V * v.X_Gap_VA
                                        end
                                        if v.Y_Gap_VA and v.Y_Gap_VA ~= 0 then
                                            Y_Gap = (v.Y_Gap or 0) * Prm.V * v.Y_Gap_VA
                                        end

                                        if v.Gap_VA and v.Gap_VA ~= 0 and v.Gap then
                                            Gap = v.Gap * Prm.V * v.Gap_VA
                                        end

                                        if v.Thick_VA then
                                            Thick = (v.Thick or 2) * (v.Thick_VA * Prm.V)
                                        end

                                        if v.Type == 'Line' or v.Type == 'Rect' or v.Type == 'Rect Filled' then
                                            local w = v.Width or im.GetItemRectSize(ctx)
                                            local h = v.Height or select(2, im.GetItemRectSize(ctx))

                                            local x2 = x + w
                                            local y2 = y + h
                                            local GR = GR or 0

                                            if v.Width_VA and v.Width_VA ~= 0 then
                                                x2 = x + (w or 10) * Prm.V * (v.Width_VA)
                                            end
                                            if v.Width_VA_GR then
                                                x2 = x + (w or 10) * (GR * (v.Width_VA_GR or 0))
                                            end

                                            if v.Height_VA and v.Height_VA ~= 0 then
                                                y2 = y + (h or 10) * Prm.V * (v.Height_VA)
                                            end
                                            if v.Height_VA_GR and v.Height_VA_GR ~= 0 then
                                                y2 = y + (h or 10) * GR * (v.Height_VA_GR)
                                            end



                                            if v.Type == 'Line' then
                                                if Prm.Type == 'Slider' or Prm.Type == 'Drag' or (not Prm.Type) then
                                                    v.Height = v.Height or 0; v.Width = v.Width or w
                                                    h        = v.Height or 0; w = v.Width or w
                                                elseif Prm.Type == 'V-Slider' then
                                                    v.Height = v.Height or h; v.Width = v.Width or 0
                                                    h = v.Height or h; w = v.Width or 0
                                                end


                                                local function Addline(Xg, Yg, none, RptClr)
                                                    im.DrawList_AddLine(WDL, x + (Xg or 0),
                                                        y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0),
                                                        RptClr or Clr_VA or v.Clr or 0xffffffff,
                                                        Thick)
                                                end

                                                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, Addline,
                                                    nil, v.RPT_Clr, v.Clr)
                                            elseif v.Type == 'Rect' then
                                                local function AddRect(Xg, Yg, none, RptClr)
                                                    im.DrawList_AddRect(WDL, x + (Xg or 0),
                                                        y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0),
                                                        RptClr or Clr_VA or v.Clr or 0xffffffff,
                                                        v.Round, flag, Thick)
                                                end
                                                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddRect,
                                                    nil, v.RPT_Clr, v.Clr)
                                            elseif v.Type == 'Rect Filled' then
                                                local function AddRectFill(Xg, Yg, none, RptClr)
                                                    im.DrawList_AddRectFilled(WDL, x + (Xg or 0),
                                                        y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0),
                                                        RptClr or Clr_VA or v.Clr or 0xffffffff,
                                                        v.Round)
                                                end
                                                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap,
                                                    AddRectFill, nil, v.RPT_Clr, v.Clr)
                                            end

                                            if v.AdjustingX or v.AdjustingY then
                                                local l = 4
                                                im.DrawList_AddLine(WDL, x - l, y - l, x + l,
                                                    y + l, 0xffffffdd)
                                                im.DrawList_AddLine(WDL, x - l, y + l, x + l,
                                                    y - l, 0xffffffdd)
                                            end
                                        elseif v.Type == 'Circle' or v.Type == 'Circle Filled' then
                                            local w, h = 10
                                            if Prm.Type == 'Knob' then
                                                w, h = r
                                                    .ImGui_GetItemRectSize(ctx)
                                            else
                                                v.Width = v.Width or
                                                    10
                                            end
                                            local Rad = v.Width or w
                                            if v.Width_VA and v.Width_VA ~= 0 then
                                                Rad = Rad * Prm.V *
                                                    v.Width_VA
                                            end

                                            local function AddCircle(X_Gap, Y_Gap, Gap, RptClr)
                                                im.DrawList_AddCircle(WDL,
                                                    x + w / 2 + (X_Gap or 0),
                                                    y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0),
                                                    RptClr or Clr_VA or v.Clr or 0xffffffff, nil,
                                                    Thick)
                                            end
                                            local function AddCircleFill(X_Gap, Y_Gap, Gap, RptClr)
                                                im.DrawList_AddCircleFilled(WDL,
                                                    x + w / 2 + (X_Gap or 0),
                                                    y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0),
                                                    RptClr or Clr_VA or v.Clr or 0xffffffff)
                                            end


                                            if v.Type == 'Circle' then
                                                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddCircle,
                                                    Gap, v.RPT_Clr, v.Clr)
                                            elseif v.Type == 'Circle Filled' then
                                                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap,
                                                    AddCircleFill, Gap, v.RPT_Clr, v.Clr)
                                            end

                                            if v.AdjustingX or v.AdjustingY then
                                                local l = 4
                                                local x, y = x + Rad / 2, y + Rad / 2
                                                im.DrawList_AddLine(WDL, x - l, y - l, x + l,
                                                    y + l, 0xffffffdd)
                                                im.DrawList_AddLine(WDL, x - l, y + l, x + l,
                                                    y - l, 0xffffffdd)
                                            end
                                        elseif v.Type == 'Knob Pointer' or v.Type == 'Knob Range' or v.Type == 'Knob Image' or v.Type == 'Knob Circle' then
                                            local w, h = im.GetItemRectSize(ctx)
                                            local x, y = x + w / 2 + (v.X_Offset or 0),
                                                y + h / 2 + (v.Y_Offset or 0)
                                            local ANGLE_MIN = 3.141592 * (v.Angle_Min or 0.75)
                                            local ANGLE_MAX = 3.141592 * (v.Angle_Max or 2.25)
                                            local t = (Prm.V - 0) / (1 - 0)
                                            local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                                            local angle_cos, angle_sin = math.cos(angle),
                                                math.sin(angle)
                                            local IN = v.Rad_In or
                                                0 -- modify this for the center begin point
                                            local OUT = v.Rad_Out or 30

                                            if v.Type == 'Knob Pointer' then
                                                im.DrawList_AddLine(WDL, x + angle_cos * IN,
                                                    y + angle_sin * IN, x + angle_cos * (OUT - Thick),
                                                    y + angle_sin * (OUT - Thick),
                                                    Clr_VA or v.Clr or 0x999999aa, Thick)
                                            elseif v.Type == 'Knob Range' then
                                                local function AddRange(G)
                                                    for i = IN, OUT, (1 + (v.Gap or 0)) do
                                                        im.DrawList_PathArcTo(WDL, x, y, i,
                                                            ANGLE_MIN,
                                                            SetMinMax(
                                                                ANGLE_MIN +
                                                                (ANGLE_MAX - ANGLE_MIN) * Prm.V,
                                                                ANGLE_MIN, ANGLE_MAX))
                                                        im.DrawList_PathStroke(WDL,
                                                            Clr_VA or v.Clr or 0x999999aa, nil, Thick)
                                                        im.DrawList_PathClear(WDL)
                                                    end
                                                end


                                                Repeat(1, 0, X_Gap, X_Gap, AddRange)
                                            elseif v.Type == 'Knob Circle' then
                                                im.DrawList_AddCircle(WDL, x + angle_cos * IN,
                                                    y + angle_sin * IN, v.Width,
                                                    Clr_VA or v.Clr or 0x999999aa, nil, Thick)
                                            elseif v.Type == 'Knob Image' and v.Image then
                                                local X, Y = x + angle_cos * IN, y + angle_sin * IN
                                                im.DrawList_AddImage(WDL, v.Image, X, Y,
                                                    X + v.Width, Y + v.Width, nil, nil, nil, nil,
                                                    Clr_VA or v.Clr or 0x999999aa)
                                            end



                                            if v.AdjustingX or v.AdjustingY then
                                                local l = 4

                                                im.DrawList_AddLine(WDL, x - l, y - l, x + l,
                                                    y + l, 0xffffffdd)
                                                im.DrawList_AddLine(WDL, x - l, y + l, x + l,
                                                    y - l, 0xffffffdd)
                                            end
                                        elseif v.Type == 'Image' and v.Image then
                                            local w, h = im.Image_GetSize(v.Image)
                                            local w, h = (v.Width or w), (v.Height or h)
                                            if v.Width_VA and v.Width_VA ~= 0 then
                                                w = (v.Width or w) *
                                                    v.Width_VA * Prm.V
                                            end
                                            if v.Height_VA and v.Height_VA ~= 0 then
                                                h = (v.Height or h) *
                                                    v.Height_VA * Prm.V
                                            end
                                            local function AddImage(X_Gap, Y_Gap, none, RptClr)
                                                im.DrawList_AddImage(WDL, v.Image, x + X_Gap,
                                                    y + (Y_Gap or 0), x + w + X_Gap,
                                                    y + h + (Y_Gap or 0), 0, 0, 1, 1,
                                                    RptClr or Clr_VA or v.Clr)
                                            end


                                            Repeat(v.Repeat, v.Repeat_VA, v.X_Gap or 0, v.Y_Gap or 0,
                                                AddImage, nil, v.RPT_Clr, v.Clr)
                                        elseif v.Type == 'Gain Reduction Text' and not FX[FxGUID].DontShowGR then
                                            local GR = round(GR, 1)
                                            im.DrawList_AddTextEx(WDL, Arial_12, 12, x, y, v.Clr or 0xffffffff,
                                                GR or '')
                                        end
                                    end
                                end
                                --im.DrawListSplitter_Merge(FX[FxGUID].DL_SPLITER)
                                --Try another method: use undo history to detect if user has changed a preset, if so, unlink all params
                                --[[ if r.TrackFX_GetOpen(LT_Track, FX_Idx) and focusedFXState==1 and FX_Index_FocusFX==FX_Idx then

                                    if FX[FxGUID].Morph_ID and not FP.UnlinkedModTable then
                                        _,TrackStateChunk, FXStateChunk, FP.UnlinkedModTable= GetParmModTable(LT_TrackNum, FX_Idx, Prm.Num, TableIndex_Str)
                                        Unlink_Parm (trackNumOfFocusFX, FX_Idx, Prm.Num ) -- Use native API instead
                                        FocusedFX = FX_Idx
                                    end
                                elseif focusedFXState==0 and UnlinkedModTable then

                                end --FX_Index_FocusFX
                                if FP.UnlinkedModTable then
                                    if not r.TrackFX_GetOpen(LT_Track, FocusedFX) then -- if the fx is closed
                                        Link_Param_to_CC(LT_TrackNum, FocusedFX, Prm.Num, true, true, -101, nil, -1, 160, FX[FxGUID].Morph_ID, UnlinkedModTable['PARAMOD_BASELINE'], UnlinkedModTable['PARMLINK_SCALE']) Use native r.TrackFX_SetNamedConfigParm instead
                                        FocusedFX=nil      FP.UnlinkedModTable = nil
                                    end
                                end ]]
                            end
                            if im.IsItemClicked(ctx, 1) and Mods == 0 and not AssigningMacro then
                                local draw_list = im.GetForegroundDrawList(ctx)
                                local mouse_pos = { im.GetMousePos(ctx) }
                                local click_pos = { im.GetMouseClickedPos(ctx, 0) }
                                im.DrawList_AddLine(draw_list, click_pos[1], click_pos[2], mouse_pos[1],
                                    mouse_pos[2], 0xB62424FF, 4.0) -- Draw a line between the button and the mouse cursor
                                local P_Num = Prm.Num
                                lead_fxid =
                                FX_Idx                             -- storing the original fx id
                                fxidx =
                                    FX_Idx                         -- to prevent an error in layout editor function by not changing FX_Idx itself
                                lead_paramnumber = P_Num
                                local ret, _ = r.TrackFX_GetNamedConfigParm(LT_Track, lead_fxid, "parent_container")
                                local rev = ret
                                while rev do -- to get root parent container id
                                    root_container = fxidx
                                    rev, fxidx = r.TrackFX_GetNamedConfigParm(LT_Track, fxidx, "parent_container")
                                end
                                if ret then -- new fx and parameter
                                    local rv, buf = r.TrackFX_GetNamedConfigParm(LT_Track, root_container,
                                        "container_map.add." .. lead_fxid .. "." .. lead_paramnumber)
                                    lead_fxid = root_container
                                    lead_paramnumber = buf
                                end
                            end
                            if im.IsItemClicked(ctx, 1) and Mods == Shift then
                                local P_Num = Prm.Num
                                local rv, bf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                    "param." .. P_Num .. ".plink.midi_bus")
                                if bf == "15" then -- reset FX Devices' modulation bus/chan
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus",
                                        0)         -- reset bus and channel because it does not update automatically although in parameter linking midi_* is not available
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num ..
                                        ".plink.midi_chan", 1)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect",
                                        -1)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active",
                                        0)
                                    if FX[FxGUID][Fx_P].ModAMT then
                                        for Mc = 1, 8, 1 do
                                            if FX[FxGUID][Fx_P].ModAMT[Mc] then
                                                FX[FxGUID][Fx_P].ModAMT[Mc] = 0
                                            end
                                        end
                                    end
                                end
                                if lead_fxid ~= nil then
                                    follow_fxid = FX_Idx -- storing the original fx id
                                    fxidx =
                                        FX_Idx           -- to prevent an error in layout editor function by not changing FX_Idx itself
                                    follow_paramnumber = P_Num
                                    ret, _ = r.TrackFX_GetNamedConfigParm(LT_Track, follow_fxid, "parent_container")
                                    local rev = ret
                                    while rev do -- to get root parent container id
                                        root_container = fxidx
                                        rev, fxidx = r.TrackFX_GetNamedConfigParm(LT_Track, fxidx, "parent_container")
                                    end
                                    if ret then -- fx inside container
                                        local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, root_container,
                                            "container_map.get." .. follow_fxid .. "." .. follow_paramnumber)
                                        if retval then -- toggle off and remove map
                                            r.TrackFX_SetNamedConfigParm(LT_Track, root_container,
                                                "param." .. buf .. ".plink.active", 0)
                                            r.TrackFX_SetNamedConfigParm(LT_Track, root_container,
                                                "param." .. buf .. ".plink.effect", -1)
                                            r.TrackFX_SetNamedConfigParm(LT_Track, root_container,
                                                "param." .. buf .. ".plink.param", -1)
                                            local rv, container_id = r.TrackFX_GetNamedConfigParm(LT_Track, follow_fxid,
                                                "parent_container")
                                            while rv do -- removing map
                                                _, buf = r.TrackFX_GetNamedConfigParm(LT_Track, container_id,
                                                    "container_map.get." .. follow_fxid .. "." .. follow_paramnumber)
                                                r.TrackFX_GetNamedConfigParm(LT_Track, container_id,
                                                    "param." .. buf .. ".container_map.delete")
                                                rv, container_id = r.TrackFX_GetNamedConfigParm(LT_Track, container_id,
                                                    "parent_container")
                                            end
                                        else                                                                      -- new fx and parameter
                                            local rv, buf = r.TrackFX_GetNamedConfigParm(LT_Track, root_container,
                                                "container_map.add." .. follow_fxid .. "." .. follow_paramnumber) -- map to the root
                                            r.TrackFX_SetNamedConfigParm(LT_Track, root_container,
                                                "param." .. buf .. ".plink.active", 1)
                                            r.TrackFX_SetNamedConfigParm(LT_Track, root_container,
                                                "param." .. buf .. ".plink.effect", lead_fxid)
                                            r.TrackFX_SetNamedConfigParm(LT_Track, root_container,
                                                "param." .. buf .. ".plink.param", lead_paramnumber)
                                        end
                                    else                                                       -- not inside container
                                        local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, follow_fxid,
                                            "param." .. follow_paramnumber .. ".plink.active") -- Active(true, 1), Deactivated(true, 0), UnsetYet(false)
                                        if retval and buf == "1" then                          -- toggle off
                                            value = 0
                                            lead_fxid = -1
                                            lead_paramnumber = -1
                                        else
                                            value = 1
                                        end
                                        r.TrackFX_SetNamedConfigParm(LT_Track, follow_fxid,
                                            "param." .. follow_paramnumber .. ".plink.active", value)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, follow_fxid,
                                            "param." .. follow_paramnumber .. ".plink.effect", lead_fxid)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, follow_fxid,
                                            "param." .. follow_paramnumber .. ".plink.param", lead_paramnumber)
                                    end
                                end
                            end
                            if im.IsItemClicked(ctx, 1) and Mods == Ctrl and not AssigningMacro then
                                im.OpenPopup(ctx, '##prm Context menu' .. FP.Num)
                            end
                            if im.BeginPopup(ctx, '##prm Context menu' .. (FP.Num or 0)) then
                                if im.Selectable(ctx, 'Toggle Add Parameter to Envelope', false) then
                                    local env = r.GetFXEnvelope(LT_Track, FX_Idx, Prm.Num, false)    -- Check if envelope is on
                                    if env == nil then                                               -- Envelope is off
                                        local env = r.GetFXEnvelope(LT_Track, FX_Idx, Prm.Num, true) -- true = Create envelope
                                    else                                                             -- Envelope is on
                                        local rv, EnvelopeStateChunk = r.GetEnvelopeStateChunk(env, "", false)
                                        if string.find(EnvelopeStateChunk, "VIS 1") then             -- VIS 1 = visible, VIS 0 = invisible
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 1", "VIS 0")
                                            r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                                        else -- on but invisible
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "ACT 0", "ACT 1")
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 0", "VIS 1")
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "ARM 0", "ARM 1")
                                            r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                                        end
                                    end
                                    r.TrackList_AdjustWindows(false)
                                    r.UpdateArrange()
                                end
                                if im.Selectable(ctx, 'Remove Envelope', false) then
                                    local env = r.GetFXEnvelope(LT_Track, FX_Idx, Prm.Num, false) -- Check if envelope is on
                                    if env == nil then                                            -- Envelope is off
                                        local nothing
                                    else                                                          -- Envelope is on
                                        local rv, EnvelopeStateChunk = r.GetEnvelopeStateChunk(env, "", false)
                                        if string.find(EnvelopeStateChunk, "ACT 1") then
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "ACT 1", "ACT 0")
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 1", "VIS 0")
                                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "ARM 1", "ARM 0")
                                            r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                                        end
                                    end
                                    r.TrackList_AdjustWindows(false)
                                    r.UpdateArrange()
                                end
                                if im.Selectable(ctx, 'Toggle Add Audio Control Signal (Sidechain)') then
                                    local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                        "param." .. Prm.Num .. ".acs.active") -- Active(true, 1), Deactivated(true, 0), UnsetYet(false)
                                    if retval and buf == "1" then             -- Toggle
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. Prm.Num ..
                                            ".acs.active", 0)
                                    else
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. Prm.Num ..
                                            ".acs.active", 1)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. Prm.Num .. ".acs.chan",
                                            1)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. Prm.Num ..
                                            ".acs.stereo", 1)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." ..
                                            Prm.Num .. ".mod.visible", 1)
                                    end
                                end
                                if im.Selectable(ctx, 'Toggle Add LFO') then
                                    local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                        "param." .. Prm.Num .. ".lfo.active")
                                    if retval and buf == "1" then
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. Prm.Num ..
                                            ".lfo.active", 0)
                                    else
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. Prm.Num ..
                                            ".lfo.active", 1)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." ..
                                            Prm.Num .. ".mod.visible", 1)
                                    end
                                end
                                if im.Selectable(ctx, 'Toggle Add CC Link') then
                                    local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                        "param." .. Prm.Num .. ".plink.active")
                                    local rv, bf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                        "param." .. Prm.Num .. ".plink.midi_bus")
                                    if bf == "15" then
                                        value = 1
                                        local retval, retvals_csv = r.GetUserInputs('Set CC value', 2,
                                            'CC value(CC=0_119/14bit=0_31),14bit (yes=1/no=0)', '0,0') -- For 14 bit, 128 + CC# is plink.midi_msg2 value, e.g. 02/34 become 130 (128-159)
                                        local input1val, input2val = retvals_csv:match("([^,]+),([^,]+)")
                                        if input2val == nil then
                                            retvals = nil -- To make global retvals nil, when users choose cancel or close the window
                                        end
                                        if input2val ~= nil then
                                            if type(input1val) == "string" then
                                                local input1check = tonumber(input1val)
                                                local input2check = tonumber(input2val)
                                                if input1check and input2check then
                                                    input1val = input1check
                                                    input2val = input2check
                                                else
                                                    error('Only enter a number')
                                                end
                                            end
                                            local input1val = tonumber(input1val)
                                            local input2val = tonumber(input2val)
                                            if input2val < 0 then
                                                input2val = 0
                                            elseif input2val > 1 then
                                                input2val = 1
                                            end
                                            if input1val < 0 then
                                                input1val = 0
                                            elseif input2val == 0 and input1val > 119 then
                                                input1val = 119
                                            elseif input2val == 1 and input1val > 31 then
                                                input1val = 31
                                            end
                                            input2val = input2val * 128
                                            retvals = input1val + input2val
                                        end
                                        if FX[FxGUID][Fx_P].ModAMT and retvals ~= nil then
                                            for Mc = 1, 8, 1 do
                                                if FX[FxGUID][Fx_P].ModAMT[Mc] then
                                                    FX[FxGUID][Fx_P].ModAMT[Mc] = 0
                                                end
                                            end
                                        end
                                    elseif retval and buf == "1" then
                                        value = 0
                                    else
                                        value = 1
                                        local retval, retvals_csv = r.GetUserInputs('Set CC value', 2,
                                            'CC value(CC=0_119/14bit=0_31),14bit (yes=1/no=0)', '0,0') -- retvals_csv returns "input1,input2"
                                        local input1val, input2val = retvals_csv:match("([^,]+),([^,]+)")
                                        if input2val == nil then
                                            retvals = nil -- To make global retvals nil, when users choose cancel or close the window
                                        end
                                        if input2val ~= nil then
                                            if type(input1val) == "string" then
                                                local input1check = tonumber(input1val)
                                                local input2check = tonumber(input2val)
                                                if input1check and input2check then
                                                    input1val = input1check
                                                    input2val = input2check
                                                else
                                                    error('Only enter a number')
                                                end
                                            end
                                            local input1val = tonumber(input1val)
                                            local input2val = tonumber(input2val)
                                            if input2val < 0 then
                                                input2val = 0
                                            elseif input2val > 1 then
                                                input2val = 1
                                            end
                                            if input1val < 0 then
                                                input1val = 0
                                            elseif input2val == 0 and input1val > 119 then
                                                input1val = 119
                                            elseif input2val == 1 and input1val > 31 then
                                                input1val = 31
                                            end
                                            input2val = input2val * 128
                                            retvals = input1val + input2val
                                        end
                                    end
                                    if retvals ~= nil then
                                        ParameterMIDILink(FX_Idx, Prm.Num, value, false, 0, 1, 176, retvals, false)
                                    end
                                end
                                if im.Selectable(ctx, 'Toggle Open Modulation/Link Window') then
                                    local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                        "param." .. Prm.Num .. ".mod.visible")
                                    if retval and buf == "1" then
                                        value = 0
                                    else
                                        value = 1
                                    end
                                    local window = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx,
                                        "param." .. Prm.Num .. ".mod.visible", value)
                                end
                                im.EndPopup(ctx)
                            end
                        end
                    end -- Rpt for every param


                    if FX.LayEdit then
                        if LE.DragY > LE.GridSize or LE.DragX > LE.GridSize or LE.DragY < -LE.GridSize or LE.DragX < -LE.GridSize then
                            im.ResetMouseDragDelta(ctx)
                        end
                    end


                    if im.IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and
                        im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows)
                    then
                        if ClickOnAnyItem == nil and LBtnRel and AdjustPrmWidth ~= true and Mods == 0 then
                            LE.Sel_Items = {};
                        elseif ClickOnAnyItem and LBtnRel then
                            ClickOnAnyItem = nil
                        elseif AdjustPrmWidth == true then
                            AdjustPrmWidth = nil
                        end
                    end




                    if FX[FxGUID].Round then im.PopStyleVar(ctx) end
                    if FX[FxGUID].GrbRound then im.PopStyleVar(ctx) end



                    if (FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true) and Mods ~= Apl then
                        im.EndDisabled(ctx)
                    end
                end




                for i, v in pairs(PluginScripts) do
                    local FX_Name = FX_Name


                    if FX_Name:find(v) then
                        r.SetExtState('FXD', 'Plugin Script FX_Id', FX_Idx, false)
                        PluginScript.FX_Idx = FX_Idx
                        PluginScript.Guid = FxGUID
                        dofile(pluginScriptPath .. '/' .. v .. '.lua')
                    end
                end
                --PluginScript.FX_Idx = FX_Idx
                -- PluginScript.Guid = FXGUID[FX_Idx]
                --require("src.FX Layout Plugin Scripts.Pro C 2")
                -- require("src.FX Layout Plugin Scripts.Pro Q 3")



                if FX.Enable[FX_Idx] == false then
                    im.DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B, 0x00000088)
                end

                --[[ if im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                    DisableScroll = nil
                else DisableScroll = true
                end ]]

                --im.Dummy(ctx, 0, dummyH)
                if im.IsWindowHovered(ctx, im.HoveredFlags_ChildWindows) then
                    if FX_Name == 'Container' --[[ and FX_Idx < 0x2000000 ]] and not Tab_Collapse_Win then
                        if im.IsKeyPressed(ctx, im.Key_Tab) then
                            CollapseIfTab(FxGUID, FX_Idx)
                            Tab_Collapse_Win = true
                            NeedRetrieveLayout = true
                        end
                    end
                end

                HoverWindow = im.GetWindowSize(ctx)
                im.Dummy(ctx, 100, 100)
                im.EndChild(ctx)
            end



            im.PopStyleVar(ctx) -- styleVar ScrollBar
        end


        --------------------------------------------------------------------------------------
        --------------------------------------Draw Mode --------------------------------------
        --------------------------------------------------------------------------------------

        --------------------FX Devices--------------------

        im.PopStyleColor(ctx, poptimes) -- -- PopColor #1 FX Window
        im.SameLine(ctx, nil, 0)








        im.EndGroup(ctx)
    end
    if BlinkFX == FX_Idx then BlinkFX = BlinkItem(0.2, 2, BlinkFX) end

    return HoverWindow
end --of Create fx window function

function get_fx_id_from_container_path(tr, idx1, ...)
    local sc, rv = reaper.TrackFX_GetCount(tr) + 1, 0x2000000 + idx1
    for i, v in ipairs({ ... }) do
        local ccok, cc = reaper.TrackFX_GetNamedConfigParm(tr, rv, 'container_count')
        if ccok ~= true then return nil end
        rv = rv + sc * v
        sc = sc * (1 + tonumber(cc))
    end
    return rv
end

function get_container_path_from_fx_id(tr, fxidx) -- returns a list of 1-based IDs from a fx-address
    if fxidx & 0x2000000 then
        local ret = {}
        local n = reaper.TrackFX_GetCount(tr)
        local curidx = (fxidx - 0x2000000) % (n + 1)
        local remain = math.floor((fxidx - 0x2000000) / (n + 1))
        if curidx < 1 then return nil end -- bad address

        local addr, addr_sc = curidx + 0x2000000, n + 1
        while true do
            local ccok, cc = reaper.TrackFX_GetNamedConfigParm(tr, addr, 'container_count')
            if not ccok then return nil end -- not a container
            ret[#ret + 1] = curidx
            n = tonumber(cc)
            if remain <= n then
                if remain > 0 then ret[#ret + 1] = remain end
                return ret
            end
            curidx = remain % (n + 1)
            remain = math.floor(remain / (n + 1))
            if curidx < 1 then return nil end -- bad address
            addr = addr + addr_sc * curidx
            addr_sc = addr_sc * (n + 1)
        end
    end
    return { fxid + 1 }
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

--------------==  Space between FXs--------------------
function AddSpaceBtwnFXs(FX_Idx, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container,
                         AdditionalWidth, FX_Idx_in_Container)
    local SpcIsInPre, Hide, SpcInPost, MoveTarget
    local WinW

    if FX_Idx == 0 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx = 1 end

    --[[ local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx_in_Container or FX_Idx)
    if FindStringInTable(BlackListFXs, FX_Name) then
        Hide = true
    end
    ]]
    TblIdxForSpace = FX_Idx .. tostring(SpaceIsBeforeRackMixer)
    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    if Trk[TrkID].PreFX[1] then
        local offset
        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 1 else offset = 0 end
        if SpaceIsBeforeRackMixer == 'End of PreFX' then
            SpcIsInPre = true
            if Trk[TrkID].PreFX_Hide then Hide = true end
            MoveTarget = FX_Idx + 1
        elseif FX_Idx + 1 - offset <= #Trk[TrkID].PreFX and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
            SpcIsInPre = true; if Trk[TrkID].PreFX_Hide then Hide = true end
        end
    end
    --[[ if SpaceIsBeforeRackMixer == 'SpcInPost' or SpaceIsBeforeRackMixer == 'SpcInPost 1st spc' then
        SpcInPost = true
        if PostFX_LastSpc == 30 then Dvdr.Spc_Hover[TblIdxForSpace] = 30 end
    end ]]
    local ClrLbl = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')


    Dvdr.Clr[ClrLbl] = Space_Between_FXs
    Dvdr.Width[TblIdxForSpace] = Dvdr.Width[TblIdxForSpace] or 0
    if FX_Idx == 0 and DragDroppingFX and not SpcIsInPre then
        if im.IsMouseHoveringRect(ctx, Cx_LeftEdge + 10, Cy_BeforeFXdevices, Cx_LeftEdge + 25, Cy_BeforeFXdevices + 220) and DragFX_ID ~= 0 then
            Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
        end
    end

    if FX_Idx == RepeatTimeForWindows then
        Dvdr.Width[TblIdxForSpace] = 15
    end

    if FX_Idx_OpenedPopup == (FX_Idx or 0) .. (tostring(SpaceIsBeforeRackMixer) or '') then
        Dvdr.Clr[ClrLbl] = Clr.Dvdr.Active
    else
        Dvdr.Clr[ClrLbl] = Dvdr.Clr[ClrLbl] or Clr.Dvdr.In_Layer
    end

    im.PushStyleColor(ctx, im.Col_FrameBg, Dvdr.Clr[ClrLbl])

    local w = 10 + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0) + (AdditionalWidth or 0)
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)



    -- StyleColor For Space Btwn Fx Windows
    if not Hide then
        if im.BeginChild(ctx, '##SpaceBetweenWindows' .. FX_Idx .. tostring(SpaceIsBeforeRackMixer) .. 'Last SPC in Rack = ' .. tostring(AddLastSPCinRack), 10, 220) then
            --HOVER_RECT = im.IsWindowHovered(ctx,  im.HoveredFlags_RectOnly)
            HoverOnWindow = im.IsWindowHovered(ctx, im.HoveredFlags_AllowWhenBlockedByActiveItem)
            WinW          = im.GetWindowSize(ctx)


            if HoverOnWindow == true and Dragging_TrueUntilMouseUp ~= true and DragDroppingFX ~= true and AssignWhichParam == nil and Is_ParamSliders_Active ~= true and Wet.ActiveAny ~= true and Knob_Active ~= true and not Dvdr.JustDroppedFX and LBtn_MousdDownDuration < 0.2 then
                Dvdr.Spc_Hover[TblIdxForSpace] = Df.Dvdr_Hvr_W
                if DebugMode then
                    tooltip('FX_Idx :' .. FX_Idx .. '\n Pre/Post/Norm : ' ..
                        tostring(SpaceIsBeforeRackMixer) ..
                        '\n SpcIDinPost: ' ..
                        tostring(SpcIDinPost) ..
                        '\n AddLastSpace = ' ..
                        (AddLastSpace or 'nil') .. '\n AdditionalWidth = ' .. (AdditionalWidth or 'nil'))
                end
                im.PushStyleColor(ctx, im.Col_ButtonHovered, CLR_BtwnFXs_Btn_Hover)
                im.PushStyleColor(ctx, im.Col_ButtonActive, CLR_BtwnFXs_Btn_Active)

                local x, y = im.GetCursorScreenPos(ctx)
                im.SetCursorScreenPos(ctx, x, Glob.WinT)
                BTN_Btwn_FXWindows = im.Button(ctx, '##Button between Windows', 99, 217)
                FX_Insert_Pos = FX_Idx

                if BTN_Btwn_FXWindows then
                    FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')
                    im.OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx)
                end
                im.PopStyleColor(ctx, 2)
                Dvdr.RestoreNormWidthWait[FX_Idx] = 0
            else
                Dvdr.RestoreNormWidthWait[FX_Idx] = (Dvdr.RestoreNormWidthWait[FX_Idx] or 0) + 1
                if Dvdr.RestoreNormWidthWait[FX_Idx] >= 8 then
                    Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                    Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                end
            end



            AddFX_Menu(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost)


            im.EndChild(ctx)
        end
    end
    im.PopStyleColor(ctx)
    local FXGUID_FX_Idx = r.TrackFX_GetFXGUID(LT_Track, FX_Idx - 1)


    function MoveFX(DragFX_ID, FX_Idx, isMove, AddLastSpace)

        if not DragFX_ID then return end 
        local FxGUID_DragFX = FXGUID[DragFX_ID] or r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

        local AltDest, AltDestLow, AltDestHigh, DontMove

        if SpcInPost then SpcIsInPre = false end

        if SpcIsInPre then
            if not tablefind(Trk[TrkID].PreFX, FxGUID_DragFX) then -- if fx is not in pre fx
                if SpaceIsBeforeRackMixer == 'End of PreFX' then
                    local offset = 0
                    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = -1 end

                    table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FxGUID_DragFX)
                    --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Idx + 1, true)
                    DontMove = true
                else
                    table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FxGUID_DragFX)
                end
            else -- if fx is in pre fx
                local offset = 0
                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = -1 end
                if FX_Idx < DragFX_ID then -- if drag towards left
                    table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                    table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FxGUID_DragFX)
                elseif SpaceIsBeforeRackMixer == 'End of PreFX' then
                    table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FxGUID_DragFX)
                    table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                    --move fx down
                else
                    table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FxGUID_DragFX)
                    table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                end
            end

            for i, v in pairs(Trk[TrkID].PreFX) do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' ..
                    i, v, true)
            end
            if tablefind(Trk[TrkID].PostFX, FxGUID_DragFX) then
                table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FxGUID_DragFX))
            end
            FX.InLyr[FxGUID_DragFX] = nil
        elseif SpcInPost then
            local offset

            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end

            if not tablefind(Trk[TrkID].PostFX, FxGUID_DragFX) then -- if fx is not yet in post-fx chain
                InsertToPost_Src = DragFX_ID + offset + 1

                InsertToPost_Dest = SpcIDinPost


                if tablefind(Trk[TrkID].PreFX, FxGUID_DragFX) then
                    table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FxGUID_DragFX))
                end
            else                                -- if fx is already in post-fx chain
                local IDinPost = tablefind(Trk[TrkID].PostFX, FxGUID_DragFX)
                if SpcIDinPost <= IDinPost then -- if drag towards left
                    table.remove(Trk[TrkID].PostFX, IDinPost)
                    table.insert(Trk[TrkID].PostFX, SpcIDinPost, FxGUID_DragFX)
                    table.insert(MovFX.ToPos, FX_Idx + 1)
                else
                    table.insert(Trk[TrkID].PostFX, SpcIDinPost, Trk[TrkID].PostFX[IDinPost])
                    table.remove(Trk[TrkID].PostFX, IDinPost)
                    table.insert(MovFX.ToPos, FX_Idx)
                end
                DontMove = true
                table.insert(MovFX.FromPos, DragFX_ID)
            end
            FX.InLyr[FxGUID_DragFX] = nil
        else -- if space is not in pre or post
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. DragFX_ID, '', true)
            if not MoveFromPostToNorm then
                if tablefind(Trk[TrkID].PreFX, FxGUID_DragFX) then
                    table.remove(Trk[TrkID].PreFX,
                        tablefind(Trk[TrkID].PreFX, FxGUID_DragFX))
                end
            end
            if tablefind(Trk[TrkID].PostFX, FxGUID_DragFX) then
                table.remove(Trk[TrkID].PostFX,
                    tablefind(Trk[TrkID].PostFX, FxGUID_DragFX))
            end
        end
        for i = 1, #Trk[TrkID].PostFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                true)
        end
        for i = 1, #Trk[TrkID].PreFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '',
                true)
        end
        if not DontMove then
            if FX_Idx ~= RepeatTimeForWindows and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
                --[[ if ((FX.Win_Name_S[FX_Idx]or''):find('Pro%-Q 3') or (FX.Win_Name_S[FX_Idx]or''):find('Pro%-C 2')) and not tablefind (Trk[TrkID].PreFX, FXGUID[FX_Idx]) then
                    AltDestLow = FX_Idx-1
                end ]]
                if (FX.Win_Name_S[FX_Idx] or ''):find('Pro%-C 2') then
                    AltDestHigh = FX_Idx - 1
                end
                FX_Idx = tonumber(FX_Idx)
                DragFX_ID = tonumber(DragFX_ID)

                if FX_Idx > DragFX_ID and FX_Idx < 0x2000000 then offset = 1 end


                table.insert(MovFX.ToPos, AltDestLow or FX_Idx - (offset or 0))
                table.insert(MovFX.FromPos, DragFX_ID)
            elseif FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' or SpaceIsBeforeRackMixer == 'End of PreFX' then
                local offset

                if Trk[TrkID].PostFX[1] then offset = #Trk[TrkID].PostFX end
                table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
                table.insert(MovFX.FromPos, DragFX_ID)
            else
                table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
                table.insert(MovFX.FromPos, DragFX_ID)
            end
        end
        if isMove == false then
            NeedCopyFX = true
            DropPos = FX_Idx
        end
    end

    function MoveFXwith1PreFXand1PosFX(DragFX_ID, FX_Idx, Undo_Lbl)
        r.Undo_BeginBlock()
        table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FxGUID_DragFX))
        for i = 1, #Trk[TrkID].PreFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '',
                true)
        end
        table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FxGUID_DragFX))
        for i = 1, #Trk[TrkID].PostFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                true)
        end
        if FX_Idx ~= RepeatTimeForWindows then
            if DragFX_ID > FX_Idx then
                table.insert(MovFX.FromPos, DragFX_ID)
                table.insert(MovFX.ToPos, FX_Idx)
                table.insert(MovFX.FromPos, DragFX_ID)
                table.insert(MovFX.ToPos, FX_Idx)
                table.insert(MovFX.FromPos, DragFX_ID + 1)
                table.insert(MovFX.ToPos, FX_Idx + 2)


                --[[ r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx, true )
                r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx, true )
                r.TrackFX_CopyToTrack( LT_Track, DragFX_ID+1, LT_Track, FX_Idx+2, true ) ]]
            elseif FX_Idx > DragFX_ID then
                table.insert(MovFX.FromPos, DragFX_ID)
                table.insert(MovFX.ToPos, FX_Idx - 1)
                table.insert(MovFX.FromPos, DragFX_ID - 1)
                table.insert(MovFX.ToPos, FX_Idx - 2)
                table.insert(MovFX.FromPos, DragFX_ID - 1)
                table.insert(MovFX.ToPos, FX_Idx - 1)

                --[[ r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx-1 , true )
                r.TrackFX_CopyToTrack( LT_Track, DragFX_ID-1, LT_Track, FX_Idx-2 , true )
                r.TrackFX_CopyToTrack( LT_Track, DragFX_ID-1, LT_Track, FX_Idx-1 , true ) ]]
            end
        else
            if AddLastSpace == 'LastSpc' then
                r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Idx, true)
                r.TrackFX_CopyToTrack(LT_Track, DragFX_ID - 1, LT_Track, FX_Idx - 2, true)
            end
        end
        r.Undo_EndBlock(Undo_Lbl, 0)
    end

    function MoveFXwith1PreFX(DragFX_ID, FX_Idx, Undo_Lbl)
        r.Undo_BeginBlock()
        if FX_Idx ~= RepeatTimeForWindows then
            if payload > FX_Idx then
                r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
            elseif FX_Idx > payload then
                r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx - 1, true)
                r.TrackFX_CopyToTrack(LT_Track, payload - 1, LT_Track, FX_Idx - 2, true)
            end
        else
            if AddLastSpace == 'LastSpc' then
                r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                r.TrackFX_CopyToTrack(LT_Track, payload - 1, LT_Track, FX_Idx - 2, true)
            end
        end
        r.Undo_EndBlock(Undo_Lbl, 0)
    end

    ---  if the space is in FX layer
    if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID_RackMixer and SpaceIsBeforeRackMixer == false or AddLastSPCinRack == true then
        Dvdr.Clr[ClrLbl] = Clr.Dvdr.In_Layer
        FXGUID_of_DraggingFX = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID or 0)

        if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
            Dvdr.Width[TblIdxForSpace] = 0
        else
            if im.BeginDragDropTarget(ctx) then
                FxDroppingTo = FX_Idx
                ----- Drag Drop FX -------
                dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                if FxGUID == FxGUID_DragFX then
                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                end

                im.SameLine(ctx, 100, 10)


                if dropped and Mods == 0 then
                    DropFXtoLayer(FX_Idx, LyrID)
                    Dvdr.Width[TblIdxForSpace] = 0
                    FxDroppingTo = nil
                elseif dropped and Mods == Apl then
                    DragFX_Src = DragFX_ID

                    if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                    DropToLyrID = LyrID
                    DroptoRack = FXGUID_RackMixer
                    --MoveFX(DragFX_Src, DragFX_Dest ,false )

                    Dvdr.Width[TblIdxForSpace] = 0
                    FxDroppingTo = nil
                end
                ----------- Add FX ---------------
                



                im.EndDragDropTarget(ctx)
            else
                Dvdr.Width[TblIdxForSpace] = 0
                FxDroppingTo = nil
            end
        end
        if Payload_Type == 'DND ADD FX' then
            DndAddFXfromBrowser_TARGET(FX_Idx, ClrLbl) -- fx layer
        end
        im.SameLine(ctx, 100, 10)
    elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
        if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
            Dvdr.Width[TblIdxForSpace] = 0
        else
            if im.BeginDragDropTarget(ctx) then
                FxDroppingTo = FX_Idx
                dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                if FxGUID == FxGUID_DragFX then
                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                end
                
                HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect', Foreground)

                im.SameLine(ctx, 100, 10)
                local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                local InsPos = math.min(FX_Idx - ContainerIdx + 1, #FX[FxGUID_Container].FXsInBS)


                if dropped and Mods == 0 then
                    local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                    local InsPos = SetMinMax(FX_Idx - ContainerIdx + 1, 1, #FX[FxGUID_Container].FXsInBS)



                    DropFXintoBS(FxGUID_DragFX, FxGUID_Container, FX[FxGUID_Container].Sel_Band,
                        DragFX_ID, FX_Idx, 'DontMove')
                    Dvdr.Width[TblIdxForSpace] = 0
                    FxDroppingTo = nil

                    MoveFX(Payload, FX_Idx + 1, true)
                elseif dropped and Mods == Apl then
                    DragFX_Src = DragFX_ID

                    if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                    DropToLyrID = LyrID
                    DroptoRack = FXGUID_RackMixer
                    --MoveFX(DragFX_Src, DragFX_Dest ,false )
                    Dvdr.Width[TblIdxForSpace] = 0
                    FxDroppingTo = nil
                end
                im.EndDragDropTarget(ctx)
                
            else
                Dvdr.Width[TblIdxForSpace] = 0
                FxDroppingTo = nil
            end

            -- Add from Sexan Add FX
            if Payload_Type == 'DND ADD FX' then
                DndAddFXfromBrowser_TARGET(FX_Idx, ClrLbl,  'SpcInBS', nil ,FxGUID_Container) -- band split
            end

        end
    else -- if Space is not in FX Layer
        function MoveFX_Out_Of_BS()
            for i = 0, Sel_Track_FX_Count - 1, 1 do
                if FX[FXGUID[i]].FXsInBS then -- i is Band Splitter
                    table.remove(FX[FXGUID[i]].FXsInBS, tablefind(FX[FXGUID[i]].FXsInBS, FxGUID_DragFX))
                    r.GetSetMediaTrackInfo_String(LT_Track,
                        'P_EXT: FX is in which BS' .. FxGUID_DragFX, '', true)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FXGUID
                        [DragFX_ID], '', true)
                end
            end
            FX[FxGUID_DragFX].InWhichBand = nil
        end

        if im.BeginDragDropTarget(ctx) then
            if Payload_Type == 'FX_Drag' then
                local allowDropNext, MoveFromPostToNorm, DontAllowDrop
                local FX_Idx = FX_Idx
                if Mods == Apl then allowDropNext = true end
                 FxGUID_DragFX = DragFxGuid 
                local rv, type, payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)


                if tablefind(Trk[TrkID].PreFX, FxGUID_DragFX) and (not SpcIsInPre or SpaceIsBeforeRackMixer == 'End of PreFX') then allowDropNext = true end
                if tablefind(Trk[TrkID].PostFX, FxGUID_DragFX) and (not SpcInPost or AddLastSpace == 'LastSpc') then
                    allowDropNext = true; MoveFromPostToNorm = true
                end
                if FX[FxGUID_DragFX].InWhichBand then allowDropNext = true end
                if not FX[FxGUID_DragFX].InWhichBand and SpaceIsBeforeRackMixer == 'SpcInBS' then allowDropNext = true end
                --[[  if (FX.Win_Name_S[DragFX_ID]or''):find('Pro%-C 2') then
                    FX_Idx = FX_Idx-1
                    if (DragFX_ID  == FX_Idx +1) or (DragFX_ID == FX_Idx-1)  then DontAllowDrop = true end
                end  ]]

                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 0 else offset = 0 end

                if (DragFX_ID + offset == FX_Idx or DragFX_ID + offset == FX_Idx - 1) and SpaceIsBeforeRackMixer ~= true and FX.InLyr[FxGUID_DragFX] == nil and not SpcInPost and not allowDropNext
                    or (Trk[TrkID].PreFX[#Trk[TrkID].PreFX] == FxGUID_DragFX and SpaceIsBeforeRackMixer == 'End of PreFX') or DontAllowDrop then
                    im.SameLine(ctx, nil, 0)

                    Dvdr.Width[TblIdxForSpace] = 0
                    im.EndDragDropTarget(ctx)
                else
                    HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect', Foreground)

                    Dvdr.Clr[ClrLbl] = im.GetStyleColor(ctx, im.Col_Button)
                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width

                    dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)
                    if dropped and Mods == 0 then
                        payload = tonumber(payload)
                        r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 0, 1, 0)
                        r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 1, 2, 0)

                        r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 0, 1, 0)
                        r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 1, 2, 0)

                        --[[ if FX.Win_Name_S[payload]:find('Pro%-Q 3') and not tablefind(Trk[TrkID].PostFX, FxGUID_DragFX ) and not SpcInPost and not SpcIsInPre and not tablefind(Trk[TrkID].PreFX, FxGUID_DragFX) then
                            MoveFXwith1PreFX(DragFX_ID, FX_Idx, 'Move Pro-Q 3 and it\'s analyzer')
                        else ]]
                        MoveFX(payload, FX_Idx, true, nil)


                        -- Move FX Out of BandSplit
                        if FX[FxGUID_DragFX].InWhichBand then

                            for i = 0, Sel_Track_FX_Count - 1, 1 do
                                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, i)
                                if FX[FxGUID].FXsInBS then -- i is Band Splitter
                                    table.remove(FX[FxGUID].FXsInBS, tablefind(FX[FxGUID].FXsInBS, FxGUID_DragFX))
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FxGUID_DragFX, '', true)
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FxGUID_DragFX, '', true)
                                end
                            end
                            FX[FxGUID_DragFX].InWhichBand = nil 
                        end


                        -- Move FX Out of Layer
                        if Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] ~= nil then
                            Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] = Lyr.FX_Ins
                                [FX.InLyr[FXGUID_To_Check_If_InLayer]] - 1
                        end
                        r.SetProjExtState(0, 'FX Devices',
                            'FXLayer - ' .. 'is FX' .. FXGUID_To_Check_If_InLayer .. 'in layer', "")
                        FX.InLyr[FXGUID_To_Check_If_InLayer] = nil
                        Dvdr.JustDroppedFX = true
                    elseif dropped and Mods == Apl then
                        local copypos = FX_Idx + 1
                        payload = tonumber(payload)

                        if FX_Idx == 0 then copypos = 0 end
                        MoveFX(payload, copypos, false)
                    end
                    im.SameLine(ctx, nil, 0)
                end
            elseif Payload_Type == 'FX Layer Repositioning' then -- FX Layer Repositioning
                local FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

                local lyrFxInst
                if Lyr[FXGUID_RackMixer] then
                    lyrFxInst = Lyr[FXGUID_RackMixer].HowManyFX
                else
                    lyrFxInst = 0
                end


                if (DragFX_ID - (math.max(lyrFxInst, 1)) <= FX_Idx and FX_Idx <= DragFX_ID + 1) or DragFX_ID - lyrFxInst == FX_Idx then
                    DontAllowDrop = true
                    im.SameLine(ctx, nil, 0)
                    Dvdr.Width[TblIdxForSpace] = 0
                    im.EndDragDropTarget(ctx)

                    --[[  ]]
                    Dvdr.Width[FX_Idx] = 0
                else --if dragging to an adequate space
                    Dvdr.Clr[ClrLbl] = im.GetStyleColor(ctx, im.Col_Button)
                    dropped, payload = im.AcceptDragDropPayload(ctx, 'FX Layer Repositioning')
                    Dvdr.Width[TblIdxForSpace] = 30

                    if dropped then
                        RepositionFXsInContainer(FX_Idx)
                        --r.Undo_EndBlock('Undo for moving FX layer',0)
                    end
                end
            elseif Payload_Type == 'BS_Drag' then
                local Pl = tonumber(Payload)


                if SpaceIsBeforeRackMixer == 'SpcInBS' or FX_Idx == Pl or Pl + (#FX[FXGUID[Pl]].FXsInBS or 0) + 2 == FX_Idx then
                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    dropped, payload = im.AcceptDragDropPayload(ctx, 'BS_Drag')
                    Dvdr.Width[TblIdxForSpace] = 30
                    if dropped then
                        RepositionFXsInContainer(FX_Idx, Payload)
                    end
                end
            elseif Payload_Type == 'DND ADD FX' then
                im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)

                local dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX')
                HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect', Foreground)

                if dropped then
                    local FX_Idx = FX_Idx
                    if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end

                    r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx, false)
                    local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                    local _, nm = r.TrackFX_GetFXName(LT_Track, FX_Idx)

                    --if in layer
                    if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID_RackMixer and SpaceIsBeforeRackMixer == false or AddLastSPCinRack == true then
                        DropFXtoLayerNoMove(FXGUID_RackMixer, LyrID, FX_Idx)
                    end
                    Dvdr.Clr[ClrLbl], Dvdr.Width[TblIdxForSpace] = nil, 0
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
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                                true)
                        end
                    elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
                        DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx, Dest + 1)
                    end
                    FX_Idx_OpenedPopup = nil
                    RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                end
                im.PopStyleColor(ctx)

                im.EndDragDropTarget(ctx)
            end
        else
            Dvdr.Width[TblIdxForSpace] = 0
            Dvdr.Clr[ClrLbl] = 0x131313ff
            im.SameLine(ctx, nil, 0)
        end




        im.SameLine(ctx, nil, 0)
    end




    return WinW
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