-------------General Functions ------------------------------
-- @version 1.0Beta 1

r = reaper

---General functions list

---@param str string
function GetFileExtension(str)
    return str:match("^.+(%..+)$")
end
function InvisiBtn (ctx, x, y, str, w, h )  
    if x and y then 
        r.ImGui_SetCursorScreenPos(ctx, x,y)
    end
    local rv = r.ImGui_InvisibleButton(ctx, str,w,h or w)


    return rv
end

function Curve_3pt_Bezier(startX,startY,controlX,controlY,endX,endY)
    local X , Y = {}, {}
    for t = 0, 1, 0.1 do

        local x = (1 - t) * (1 - t) * startX + 2 * (1 - t) * t * controlX + t * t * endX
        local y = (1 - t) * (1 - t) * startY + 2 * (1 - t) * t * controlY + t * t * endY
        table.insert(X, x)
        table.insert(Y, y)
    end
    return X,Y
end


function GetTrkSavedInfo(str, track, type  )

    if type=='str' then 
        local o = select(2, r.GetSetMediaTrackInfo_String(track or LT_Track , 'P_EXT: '..str, '', false))
        if o == '' then o = nil end 
        return o
    else
        return tonumber( select(2, r.GetSetMediaTrackInfo_String(track or LT_Track , 'P_EXT: '..str, '', false)))
    end
end

function getProjSavedInfo(str, type  )

    if type=='str' then 
        return select(2, r.GetProjExtState(0, 'FX Devices', str ))
    else
        return tonumber(select(2, r.GetProjExtState(0, 'FX Devices', str ))) 
    end
end



function Normalize_Val (V1, V2, ActualV ,  Bipolar)

    local Range = math.abs( (math.max(V1, V2) - math.min(V1, V2)) )
    
    local NormV = (math.min(V1, V2)+ Range - ActualV) / Range

    if Bipolar  then 
        return  -1 + (NormV  )* 2
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

---TODO do we need this function? It’s unused
---@param str string|number|nil
function ToNum(str)
    str = tonumber(str)
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
        local ID = Fx_P .. '. ' .. Id .. ' = '
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
                _, FP.Num = r.GetProjExtState(0, 'FX Devices', 'FX' .. P .. 'Num' .. FxGUID); FP.Num = tonumber(FP
                    .Num)
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
function PinIcon (PinStatus, PinStr, size, lbl, ClrBG, ClrTint )
    if PinStatus == PinStr then 
        if r.ImGui_ImageButton(ctx, '##' .. lbl, Img.Pinned, size, size, nil, nil, nil, nil, ClrBG, ClrTint) then 
            PinStatus = nil 
        end
    else 
        if r.ImGui_ImageButton(ctx, '##' .. lbl, Img.Pin, size, size, nil, nil, nil, nil, ClrBG, ClrTint) then 
            PinStatus = PinStr 
        end
    end
    
        if r.ImGui_IsItemHovered(ctx) then
            TintClr = 0xCE1A28ff
        end
    return PinStatus, TintClr
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
                               Foreground, rounding)
    if GetItemRect == 'GetItemRect' or L == 'GetItemRect' then
        L, T = r.ImGui_GetItemRectMin(ctx); R, B = r.ImGui_GetItemRectMax(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
        --Get item rect
    end
    local P = Padding; local HSC = H_OutlineSc or 4; local VSC = V_OutlineSc or 4
    if Foreground == 'Foreground' then WinDrawList = Glob.FDL else WinDrawList = Foreground end
    if not WinDrawList then WinDrawList = r.ImGui_GetWindowDrawList(ctx) end
    if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr) end

    if OutlineClr and not rounding then
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P, T + h / VSC - P, OutlineClr); r
            .ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P, T + h / VSC - P, OutlineClr)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P, B + P - h / VSC, OutlineClr); r
            .ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P, B - h / VSC + P, OutlineClr)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P + w / HSC, T - P, OutlineClr); r
            .ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P - w / HSC, T - P, OutlineClr)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P + w / HSC, B + P, OutlineClr); r
            .ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P - w / HSC, B + P, OutlineClr)
    else
        if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr, rounding) end
        if OutlineClr then r.ImGui_DrawList_AddRect(WinDrawList, L, T, R, B, OutlineClr, rounding) end
    end
    if GetItemRect == 'GetItemRect' then return L, T, R, B, w, h end
end

function Highlight_Itm(WDL, FillClr, OutlineClr )
    local L, T = r.ImGui_GetItemRectMin(ctx); 
    local R, B = r.ImGui_GetItemRectMax(ctx); 
    
    if FillClr then r.ImGui_DrawList_AddRectFilled(WDL, L, T, R, B, FillClr, rounding) end
    if OutlineClr then r.ImGui_DrawList_AddRect(WDL, L, T, R, B, OutlineClr, rounding) end
end



---@param ctx ImGui_Context
---@param time integer count in
function PopClr(ctx, time)
    r.ImGui_PopStyleColor(ctx, time)
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

    local D = Draw[FX_Name]

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
        if D.Type then
            file:write('\n========== Drawings ==========\n')
            write('Default Drawing Edge Rounding', Draw.Df_EdgeRound[FxGUID])
            file:write('\n')
        end
        write('Total Number of Drawings', #D.Type)

        for i, Type in ipairs(D.Type) do
            D[i] = D[i] or {}
            write('Type', D.Type[i], i)
            write('Left', D.L[i], i)
            write('Right', D.R[i], i)
            write('Top', D.T[i], i)
            write('Bottom', D.B[i], i)
            write('Color', D.clr[i], i)
            write('Text', D.Txt[i], i)
            write('ImagePath', D[i].FilePath, i)
            write('KeepImgRatio', tostring(D[i].KeepImgRatio), i)
            file:write('\n')
        end
    end
end

---TODO remove this duplicate of tooltip()
---@param A string text for tooltip
function ttp(A)
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_SetTooltip(ctx, A)
    r.ImGui_EndTooltip(ctx)
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
    TimeEachFrame = r.ImGui_GetDeltaTime(ctx)
    if ImGUI_Time == nil then ImGUI_Time = 0 end
    ImGUI_Time             = ImGUI_Time + TimeEachFrame
    _, TrkName             = r.GetTrackName(LT_Track)

    Wheel_V, Wheel_H       = r.ImGui_GetMouseWheel(ctx)
    LT_Track               = r.GetLastTouchedTrack()
    IsAnyMouseDown         = r.ImGui_IsAnyMouseDown(ctx)
    LBtn_MousdDownDuration = r.ImGui_GetMouseDownDuration(ctx, 0)
    LBtnRel                = r.ImGui_IsMouseReleased(ctx, 0)
    RBtnRel                = r.ImGui_IsMouseReleased(ctx, 1)
    IsLBtnClicked          = r.ImGui_IsMouseClicked(ctx, 0)
    LBtnClickCount         = r.ImGui_GetMouseClickedCount(ctx, 0)
    IsLBtnHeld             = r.ImGui_IsMouseDown(ctx, 0)
    IsRBtnHeld             = r.ImGui_IsMouseDown(ctx, 1)
    Mods                   = r.ImGui_GetKeyMods(ctx) -- Alt = 4  shift =2  ctrl = 1  Command=8
    IsRBtnClicked          = r.ImGui_IsMouseClicked(ctx, 1)
    LT_FXGUID              = r.TrackFX_GetFXGUID(LT_Track or r.GetTrack(0, 0),
        LT_FX_Number or 0)
    TrkID                  = r.GetTrackGUID(LT_Track or r.GetTrack(0, 0))
    Sel_Track_FX_Count     = r.TrackFX_GetCount(LT_Track)
    LBtnDrag               = r.ImGui_IsMouseDragging(ctx, 0)
    LBtnDC                 = r.ImGui_IsMouseDoubleClicked(ctx, 0)
end

function HideCursorTillMouseUp(MouseBtn, triggerKey)
    UserOS = r.GetOS()
    if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
        Invisi_Cursor = r.JS_Mouse_LoadCursorFromFile(r.GetResourcePath() .. '/Cursors/Empty Cursor.cur')
    end

    if MouseBtn then 
        if r.ImGui_IsMouseClicked(ctx, MouseBtn)  then
            MousePosX_WhenClick, MousePosY_WhenClick = r.GetMousePosition()
        end
    elseif triggerKey then 
        if r.ImGui_IsKeyPressed(ctx, triggerKey, false) then 
            MousePosX_WhenClick, MousePosY_WhenClick = r.GetMousePosition()
            
        end
    end

    if MousePosX_WhenClick then
        window = r.JS_Window_FromPoint(MousePosX_WhenClick, MousePosY_WhenClick  )
       
        r.JS_Mouse_SetCursor(Invisi_Cursor)

        local function Hide()
            if MouseBtn then 
                if r.ImGui_IsMouseDown(ctx, MouseBtn) then

                    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_None())
                    r.defer(Hide)
                else
                    r.JS_WindowMessage_Release(window, "WM_SETCURSOR")
                    if r.ImGui_IsMouseReleased(ctx, MouseBtn) then
                        r.JS_Mouse_SetPosition(MousePosX_WhenClick, MousePosY_WhenClick)
                    end
                end
            elseif triggerKey then 

                if r.ImGui_IsKeyDown(ctx, triggerKey) then
                    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_None())
                    r.defer(Hide)
                else
                    r.JS_WindowMessage_Release(window, "WM_SETCURSOR")
                    if r.ImGui_IsKeyReleased(ctx, triggerKey) then 
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
    MouseDelta= MouseDelta or {}
    local M = MouseDelta
    if MouseBtn then 
        if r.ImGui_IsMouseClicked(ctx, MouseBtn)  then
            M.StX, M.StY = r.GetMousePosition()
        end
    end

    if triggerKey then 
        if r.ImGui_IsKeyPressed(ctx, triggerKey, false) then 
            M.StX, M.StY = r.GetMousePosition()
        end
    end

    M.X_now, M.Y_now = r.GetMousePosition()

    if M.StX ~= M.X_now or M.StY ~= M.Y_now then 
        local outX, outY =  M.X_now-M.StX , M.StY - M.Y_now
        M.StX, M.StY = r.GetMousePosition()
        return outX, outY
    else  return 0, 0
    end


end


---@param Name string
---@param FX_Idx integer
function CreateWindowBtn_Vertical(Name, FX_Idx)
    local rv = r.ImGui_Button(ctx, Name, 25, 220) -- create window name button
    if rv and Mods == 0 then
        openFXwindow(LT_Track, FX_Idx)
    elseif rv and Mods == Shift then
        ToggleBypassFX(LT_Track, FX_Idx)
    elseif rv and Mods == Alt then
        DeleteFX(FX_Idx)
    end
    if r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
        FX.Collapse[FXGUID[FX_Idx]] = false
    end
end

function HighlightHvredItem()
    local DL = r.ImGui_GetForegroundDrawList(ctx)
    L, T = r.ImGui_GetItemRectMin(ctx)
    R, B = r.ImGui_GetItemRectMax(ctx)
    if r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) then
        r.ImGui_DrawList_AddRect(DL, L, T, R, B, 0x99999999)
        r.ImGui_DrawList_AddRectFilled(DL, L, T, R, B, 0x99999933)
        if IsLBtnClicked then
            r.ImGui_DrawList_AddRect(DL, L, T, R, B, 0x999999dd)
            r.ImGui_DrawList_AddRectFilled(DL, L, T, R, B, 0xffffff66)
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
    if WrapPosX then r.ImGui_PushTextWrapPos(ctx, WrapPosX) end

    if font then r.ImGui_PushFont(ctx, font) end
    if color then
        r.ImGui_TextColored(ctx, color, text)
    else
        r.ImGui_Text(ctx, text)
    end

    if font then r.ImGui_PopFont(ctx) end
    if WrapPosX then r.ImGui_PopTextWrapPos(ctx) end
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
    r.ImGui_SetNextItemWidth(ctx, 40)
    local radius_outer = 10
    local pos = { r.ImGui_GetCursorScreenPos(ctx) }
    local center = { pos[1] + radius_outer, pos[2] + radius_outer }
    local CircleClr
    local line_height = r.ImGui_GetTextLineHeight(ctx)
    local draw_list = r.ImGui_GetWindowDrawList(ctx)
    local item_inner_spacing = { r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) }
    local mouse_delta = { r.ImGui_GetMouseDelta(ctx) }

    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25
    local FxGUID = FXGUID[FX_Idx]


    Wet.P_Num[FX_Idx] = Wet.P_Num[FX_Idx]  or  r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet')

    r.ImGui_InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height - 10 +
        item_inner_spacing[2])

    local value_changed = false
    local is_active = r.ImGui_IsItemActive(ctx)
    local is_hovered = r.ImGui_IsItemHovered(ctx)

    if is_active and mouse_delta[2] ~= 0.0 and FX[FxGUID].DeltaP_V ~= 1 then
        local step = (v_max - v_min) / 200.0
        if Mods == Shift then step = 0.001 end
        p_value = p_value + ((-mouse_delta[2]) * step)
        if p_value < v_min then p_value = v_min end
        if p_value > v_max then p_value = v_max end
    end

    FX[FxGUID].DeltaP_V = FX[FxGUID].DeltaP_V or 0
    FX[FxGUID].DeltaP   = FX[FxGUID].DeltaP or (r.TrackFX_GetNumParams(LT_Track, LT_FXNum) - 1)


    if is_active then
        lineClr = r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrabActive())
        CircleClr = Change_Clr_A(getClr(r.ImGui_Col_SliderGrabActive()), -0.3)
        value_changed = true
        ActiveAny = true
        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num or Wet.P_Num[FX_Idx], p_value)
    elseif is_hovered or p_value ~= 1 then
        lineClr = Change_Clr_A(getClr(r.ImGui_Col_SliderGrabActive()), -0.3)
    else
        lineClr = r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBgHovered())
    end

    if ActiveAny == true then
        if IsLBtnHeld == false then ActiveAny = false end
    end

    local t = (p_value - v_min) / (v_max - v_min)
    local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
    local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
    local radius_inner = radius_outer * 0.40
    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
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
        r.ImGui_DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, CircleClr or lineClr, 16)
        r.ImGui_DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
            center[2] + angle_sin * (radius_outer - 2), lineClr, 2.0)
        r.ImGui_DrawList_AddText(draw_list, pos[1], pos[2] + radius_outer * 2 + item_inner_spacing[2],
            r.ImGui_GetColor(ctx, r.ImGui_Col_Text()), labeltoShow)
    else
        local radius_outer = radius_outer
        r.ImGui_DrawList_AddTriangleFilled(draw_list, center[1] - radius_outer, center[2] + radius_outer, center[1],
            center[2] - radius_outer, center[1] + radius_outer, center[2] + radius_outer, 0x999900ff)
        r.ImGui_DrawList_AddText(draw_list, center[1] - radius_outer / 2 + 1, center[2] - radius_outer / 2,
            0xffffffff,
            'S')
    end

    if is_active or is_hovered and FX[FxGUID].DeltaP_V ~= 1 then
        local window_padding = { r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_WindowPadding()) }
        r.ImGui_SetNextWindowPos(ctx, pos[1] - window_padding[1],
            pos[2] - line_height - item_inner_spacing[2] - window_padding[2] - 8)
        r.ImGui_BeginTooltip(ctx)
        if Mods == Shift then
            r.ImGui_Text(ctx, ('%.1f'):format(p_value * 100) .. '%')
        else
            r.ImGui_Text(ctx, ('%.0f'):format(p_value * 100) .. '%' --[[ ('%.3f'):format(p_value) ]])
        end
        r.ImGui_EndTooltip(ctx)
    end
    if is_hovered then HintMessage = 'Alt+Right-Click = Delta-Solo' end

    return ActiveAny, value_changed, p_value
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
    r.ImGui_DrawList_AddTriangleFilled(DL, Cx, Cy - S, Cx - S, Cy, Cx + S, Cy, clr or 0x77777777ff)
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
    r.ImGui_DrawList_AddTriangleFilled(DL, Cx - S, Cy, Cx, Cy + S, Cx + S, Cy, clr or 0x77777777ff)
end

---Same Line
---@param xpos? number offset_from_start_xIn
---@param pad? number spacingIn
function SL(xpos, pad)
    r.ImGui_SameLine(ctx, xpos, pad)
end

---@param w number
---@param h number
---@param icon string
---@param BGClr? number
---@param center? string
---@param Identifier? string
---@return boolean|nil
function IconBtn(w, h, icon, BGClr, center, Identifier) -- Y = wrench
    r.ImGui_PushFont(ctx, FontAwesome)
    if r.ImGui_InvisibleButton(ctx, icon .. (Identifier or ''), w, h) then
    end
    local FillClr
    if r.ImGui_IsItemActive(ctx) then
        FillClr = getClr(r.ImGui_Col_ButtonActive())
        IcnClr = getClr(r.ImGui_Col_TextDisabled())
    elseif r.ImGui_IsItemHovered(ctx) then
        FillClr = getClr(r.ImGui_Col_ButtonHovered())
        IcnClr = getClr(r.ImGui_Col_Text())
    else
        FillClr = getClr(r.ImGui_Col_Button())
        IcnClr = getClr(r.ImGui_Col_Text())
    end
    if BGClr then FillClr = BGClr end

    L, T, R, B, W, H = HighlightSelectedItem(FillClr, 0x00000000, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
        'GetItemRect', Foreground)
    TxtSzW, TxtSzH = r.ImGui_CalcTextSize(ctx, icon)
    if center == 'center' then
        r.ImGui_DrawList_AddText(WDL, L + W / 2 - TxtSzW / 2, T - H / 2 - 1, IcnClr, icon)
    else
        r.ImGui_DrawList_AddText(WDL, L + 3, T - H / 2, IcnClr, icon)
    end
    r.ImGui_PopFont(ctx)
    if r.ImGui_IsItemActivated(ctx) then return true end
end

---@param f integer
---@return integer
function getClr(f)
    return r.ImGui_GetStyleColor(ctx, f)
end

---@param CLR number
---@param HowMuch number
---@return integer
function Change_Clr_A(CLR, HowMuch)
    local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(CLR)
    local A = SetMinMax(A + HowMuch, 0, 1)
    return r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
end

---@param Clr number
function Generate_Active_And_Hvr_CLRs(Clr)
    local ActV, HvrV
    local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(Clr)
    local H, S, V = r.ImGui_ColorConvertRGBtoHSV(R, G, B)
    if V > 0.9 then
        ActV = V - 0.2
        HvrV = V - 0.1
    end
    local R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, SetMinMax(ActV or V + 0.2, 0, 1))
    local ActClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
    local R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, HvrV or V + 0.1)
    local HvrClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
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
                r.ImGui_DrawList_AddCircleFilled(FX.DL, L, T, Rad, 0x99999950)
            elseif Shape == 'Rect' then
                local L, T = r.ImGui_GetItemRectMin(ctx)
                r.ImGui_DrawList_AddRectFilled(FX.DL, L, T, R, B, 0x99999977, Rounding)
            end
        end
    end
    if Fx_P .. FxGUID == TryingToAddExistingPrm_Cont then
        local L, T = r.ImGui_GetItemRectMin(ctx)
        if Shape == 'Circle' then
            r.ImGui_DrawList_AddCircleFilled(FX.DL, L, T, Rad, 0x99999950)
        elseif Shape == 'Rect' then
            r.ImGui_DrawList_AddRectFilled(FX.DL, L, T, R, B, 0x99999977, Rounding)
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
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_SetTooltip(ctx, A)
    r.ImGui_EndTooltip(ctx)
end

---@param A string text for tooltip
function HintToolTip(A)
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_SetTooltip(ctx, A)
    r.ImGui_EndTooltip(ctx)
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
function DeleteFX(FX_Idx)
    local DelFX_Name
    r.Undo_BeginBlock()
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. (tablefind(Trk[TrkID].PreFX, FXGUID[FX_Idx]) or ''),
        '',
        true)
    --r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX '..(tablefind (Trk[TrkID].PostFX, FXGUID[FX_Idx]) or ''), '', true)

    if tablefind(Trk[TrkID].PreFX, FXGUID[FX_Idx]) then
        DelFX_Name = 'FX in Pre-FX Chain'
        table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FXGUID[FX_Idx]))
    end

    if tablefind(Trk[TrkID].PostFX, FXGUID[FX_Idx]) then
        table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FXGUID[FX_Idx]))
        for i = 1, #Trk[TrkID].PostFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
        end
    end

    if FX[FXGUID[FX_Idx]].InWhichBand then -- if FX is in band split
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            if FX[FXGUID[i]].FXsInBS then
                if tablefind(FX[FXGUID[i]].FXsInBS, FXGUID[FX_Idx]) then
                    table.remove(FX[FXGUID[i]].FXsInBS, tablefind(FX[FXGUID[i]].FXsInBS, FXGUID[FX_Idx]))
                end
            end
        end
    end

    DeleteAllParamOfFX(FXGUID[FX_Idx], TrkID)



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
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..FP.Num..".plink.active", 0)   -- 1 active, 0 inactive
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
        r.ImGui_Spacing(ctx)
    end
end
