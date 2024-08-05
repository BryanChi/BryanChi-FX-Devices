-------------General Functions ------------------------------

-- @noindex
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

function ThirdPartyDeps()
    local ultraschall_path = reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua"
    local readrum_machine = reaper.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Suzuki_ReaDrum_Machine_Instruments_Rack.lua"

    local version = tonumber (string.sub( reaper.GetAppVersion() ,  0, 4))
    --reaper.ShowConsoleMsg((version))

    local fx_browser_path
    local n,arch = reaper.GetAppVersion():match("(.+)/(.+)")
    local fx_browser_v6_path
    
    if n:match("^7%.") then
        fx_browser = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"
        fx_browser_reapack = 'sexan fx browser parser v7' 
    else
        fx_browser= reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"  
        fx_browser_v6_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
       fx_browser_reapack = 'sexan fx browser parser v6'

    end
    --local fx_browser_v6_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
    --local fx_browser_v7_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"
    
    local reapack_process
    local repos = {
      {name = "Sexan_Scripts", url = 'https://github.com/GoranKovac/ReaScripts/raw/master/index.xml'},
      {name = "Ultraschall-API", url = 'https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/raw/master/ultraschall_api_index.xml'},
      {name = "Suzuki Scripts", url = 'https://github.com/Suzuki-Re/Suzuki-Scripts/raw/master/index.xml'},
    }
    
    for i = 1, #repos do
      local retinfo, url, enabled, autoInstall = reaper.ReaPack_GetRepositoryInfo( repos[i].name )
      if not retinfo then
        retval, error = reaper.ReaPack_AddSetRepository( repos[i].name, repos[i].url, true, 0 )
        reapack_process = true
      end
    end
   
    -- ADD NEEDED REPOSITORIES
    if reapack_process then
      reaper.ShowMessageBox("Added Third-Party ReaPack Repositories", "ADDING REPACK REPOSITORIES", 0)
      reaper.ReaPack_ProcessQueue(true)
      reapack_process = nil
    end
    
    if not reapack_process then
      -- ULTRASCHALL
      if reaper.file_exists(ultraschall_path) then
          dofile(ultraschall_path)
      else
          reaper.ShowMessageBox("Ultraschall API is needed.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
          reaper.ReaPack_BrowsePackages('ultraschall')
          return 'error ultraschall'
      end
      -- FX BROWSER
      if reaper.file_exists(fx_browser) then
          dofile(fx_browser)
      else
         reaper.ShowMessageBox("Sexan FX BROWSER is needed.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
         reaper.ReaPack_BrowsePackages(fx_browser_reapack)
         return 'error Sexan FX BROWSER'
      end
      -- ReaDrum Machine
      if reaper.file_exists(readrum_machine) then
        local found_readrum_machine = true
      else
      reaper.ShowMessageBox("ReaDrum Machine is needed.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
      reaper.ReaPack_BrowsePackages('readrum machine')
      return 'error Suzuki ReaDrum Machine'
      end
    end
end
function msg(a)
    r.ShowConsoleMsg(a)
end

function AddRandomSample(howmany, SampleSlot)
    
    for I = 1, howmany , 1 do 
        local filename = MatchedFiles[math.random(1, #MatchedFiles)]
        local rv = InsertSample(filename)
        local TB
        if SampleSlot then 
            TB= Added[SampleSlot]
        else
            table.insert(Added, {})
            TB = Added[#Added]
        end
        TB.it, TB.tk, TB.src = GetSelectedMediaItemInfo(0)
        TB.KeyWord = TB.KeyWord or  {}
        Add_KeyWord_To_Itm_tb(TB.KeyWord, #Added)
        Match_Itm_Len_and_Src_Len(TB.src, TB.it, TB.tk)
    end

end





function SwapSample( Itm,  MatchedFiles)
    if #MatchedFiles <=1 then return end 

    local filename = MatchedFiles[math.random(1, #MatchedFiles)]
    r.BR_SetTakeSourceFromFile(Itm.tk, filename, true )
    Itm.src = r.GetMediaItemTake_Source(Itm.tk)
    table.insert(BUILD_PEAK, Itm.src )
    --BUILD_PEAK = r.PCM_Source_BuildPeaks(v.src, 0)
    local nm = Remove_Dir_path (filename)
    retval,  stringNeedBig = r.GetSetMediaItemTakeInfo_String(Itm.tk, 'P_NAME', nm, true )
    Match_Itm_Len_and_Src_Len(Itm.src, Itm.it, Itm.tk)
    r.UpdateArrange()

end


function Add_KeyWord_To_Itm_tb(keywordTB, idx)
    Added[idx].KeyWord={}
    if SearchTxt~='' then 
        table.insert(Added[idx].KeyWord, SearchTxt)
    end
    for i, v in ipairs(KeyWord) do 
        if not FindStringInTable(Added[idx].KeyWord, v ) then 
            table.insert(Added[idx].KeyWord, v)
        end 
    end 
end

function Delete_All_FXD_AnalyzerFX(trk)
    local  ct = r.TrackFX_GetCount(trk)
    for i= 0 , ct,  1 do 
        local rv, name =  r.TrackFX_GetFXName(trk, i )

        if FindStringInTable(FX_To_Delete_At_Close, name) then 
            r.TrackFX_Delete(trk, i )
        end
    end 
end

------------------------------------------------------------------------------
function BuildFXTree_item(tr, fxid, scale, oldscale)
    local tr = tr or LT_Track 
    local retval, buf = reaper.TrackFX_GetFXName( tr, fxid )
    local ccok, container_count = reaper.TrackFX_GetNamedConfigParm( tr, fxid, 'container_count')

    local ret = {
        fxname = buf,
        isopen = reaper.TrackFX_GetOpen( tr, fxid ),
        GUID = reaper.TrackFX_GetFXGUID( tr, fxid ),
        addr_fxid = fxid,
        scale = oldscale
      }

    if ccok then  -- if fx in container is a container
      ret.children = { }
      local newscale = scale * (tonumber(container_count)+1)

      for child = 1, tonumber(container_count) do
        ret.children[child] = BuildFXTree_item(tr, fxid + scale * child, newscale, scale)
      end
    end
    return ret
end
--------------------------------------------------------------------------
function BuildFXTree(tr)
    -- table with referencing ID tree
    local tr = tr or LT_Track 
    if tr then 
        tree = {}
        local cnt = reaper.TrackFX_GetCount(tr)
        for i = 1, cnt do
            tree[i] = BuildFXTree_item(tr, 0x2000000+i, cnt+1, cnt+1)
        end
        return tree
    end
end

function Check_If_Has_Children_Prioritize_Empty_Container(TB)
    local Candidate
    for i, v in ipairs( TB)  do 
        if v.children then     
            if v.children[1] then --if container not empty 
                Candidate =  v.children 
            elseif not v.children[1] then   -- if container empty

                local Final = v.children ~=nil and 'children' or 'candidate'
                return v.children or Candidate
            end
        end
    end
    if  Candidate then 
        return  Candidate
    end
end

local tr = reaper.GetSelectedTrack(0,0)
TREE = BuildFXTree(LT_Track or tr)

function EndUndoBlock(str)
    r.Undo_EndBlock("ReaDrum Machine: " .. str, -1)
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

function toggle2(a,b)
    if a == b then return nil  else return  b end 
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
function FindStringInTable(Table, V, Not_Case_Sensitive) ---TODO isn’t this a duplicate of FindExactStringInTable ?  -- this one uses string:find whereas exact uses ==
    local found = nil
    local Tab = {}
    if V then
        for i, val in pairs(Table) do
            if Not_Case_Sensitive then 
                val_low = string.lower(val) 
                V_low  = string.lower(V) 
            end

            if val_low and string.find(val_low, V_low) ~= nil then
                found = true
                table.insert(Tab, val)
            end

        end
        if found == true then return true, Tab, V else return false end
    else
        return nil
    end
end

function Vertical_FX_Name (name)
    local Name = ChangeFX_Name(name)
    local Name = Name:gsub('%S+', { ['Valhalla'] = "", ['FabFilter'] = "" })
    local Name = Name:gsub('-', '|')
    local Name_V = Name:gsub("(.)", "%1\n")
    return   Name_V:gsub("%b()", "") 
end


function PreviewSample_Solo(it, tb , Added)
    if not (it and tb) then  return end 

    r.Main_OnCommand(40769,0) --- Unselect ALL
    if tb and Added then 
        for i, v in ipairs(tb) do 
            r.SetMediaItemInfo_Value(Added[v].it, 'B_UISEL', 1)  --select item 
        end 
    else 
        r.SetMediaItemInfo_Value(it, 'B_UISEL', 1)  --select item 
    end 

    r.Main_OnCommand(41173,0) -- move cursor to start of item

    r.Main_OnCommand(41558, 0 ) -- solo item 
    r.Main_OnCommand(1007,0) --play 
    Solo_Playing_Itm = true 

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

function dBFromVal(val) return 20*math.log(val, 10) end
function ValFromdB(dB_val) return 10^(dB_val/20) end

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

function QuestionHelpHint (Str)
    if r.ImGui_IsItemHovered(ctx) then 
        SL()
        r.ImGui_TextColored(ctx, 0x99999977, '(?)')
        if r.ImGui_IsItemHovered(ctx) then 
            HintToolTip(Str)
        end
    end
end

function GetSelectedMediaItemInfo(which)
    it = r.GetSelectedMediaItem(0, which)
    tk = r.GetMediaItemTake(it, 0)
    src = r.GetMediaItemTake_Source(tk )

    return it, tk, src
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
        L, T = r.ImGui_GetItemRectMin(ctx); R, B = r.ImGui_GetItemRectMax(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
        --Get item rect
    end
    local P = Padding or 0 ; local HSC = H_OutlineSc or 4; local VSC = V_OutlineSc or 4
    if Foreground == 'Foreground' then WinDrawList = Glob.FDL else WinDrawList = Foreground end
    if not WinDrawList then WinDrawList = r.ImGui_GetWindowDrawList(ctx) end
    if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr) end

    local h = h or B-T 
    local w = w or R-L

    if OutlineClr and not rounding then
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P, T + h / VSC - P, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P, T + h / VSC - P, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P, B + P - h / VSC, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P, B - h / VSC + P, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P + w / HSC, T - P, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P - w / HSC, T - P, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P + w / HSC, B + P, OutlineClr,thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P - w / HSC, B + P, OutlineClr,thick)
    else
        if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr, rounding) end
        if OutlineClr then r.ImGui_DrawList_AddRect(WinDrawList, L, T, R, B, OutlineClr, rounding) end
    end
    if GetItemRect == 'GetItemRect' then return L, T, R, B, w, h end
end

function Highlight_Itm(ctx, WDL, FillClr, OutlineClr )
    if not WDL then WDL = ImGui.GetWindowDrawList(ctx) end 
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


function Save_Search_set_Into_File(Search_Set_Name)

    local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'ReaTeam Scripts', 'FX', 'Bryan FX Devices GITHUB', 'Sample Stacker', 'Search Sets')
    local file_path = ConcatPath(dir_path, Search_Set_Name..'.ini')
    r.RecursiveCreateDirectory(dir_path, 0)
    local file = io.open(file_path, 'w')
    if file then 
        local content = file:read("*a")
        file:write('How Many Samples = '..#Added..'\n')
        for i, v in ipairs(Added) do 
            if #v.KeyWord>0 then 
                file:write( 'Sample No.'.. i ..'\n')
                file:write( 'How Many Keywords = '..#v.KeyWord..'\n' )

                for i, v in ipairs(v.KeyWord) do 
                    file:write( 'KeyWord '.. i .. ' = '.. v  ..'\n')
                end 
            end
        end 
    end 
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
    ImGui.BeginTooltip(ctx)
    ImGui.SetTooltip(ctx, A)
    ImGui.EndTooltip(ctx)
end


function Convert_Val2Fader(rea_val)
    if not rea_val then return end
    local rea_val = SetMinMax(rea_val, 0, 4)
    local val
    local gfx_c, coeff = 0.8, 50      -- use coeff to adjust curve
    local real_dB = 20 * math.log(rea_val, 10)
    local lin2 = 10 ^ (real_dB / coeff)
    if lin2 <= 1 then val = lin2 * gfx_c else val = gfx_c + (real_dB / 12) * (1 - gfx_c) end
    if val > 1 then val = 1 end
    return SetMinMax(val, 0.0001, 1)
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
        if r.ImGui_IsMouseDown(ctx, MouseBtn) and not MousePosX_WhenClick then
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
            if MouseBtn and MousePosX_WhenClick then 
                if r.ImGui_IsMouseDown(ctx, MouseBtn) then

                    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_None())
                    r.defer(Hide)
                else
                    r.JS_WindowMessage_Release(window, "WM_SETCURSOR")
                    if r.ImGui_IsMouseReleased(ctx, MouseBtn) then
                        r.JS_Mouse_SetPosition(MousePosX_WhenClick, MousePosY_WhenClick)
                        MousePosX_WhenClick=nil
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


function DiceButton (label, number, w, h, clr, clr2 , fill, outlineClr)
    local WDL = WDL or ImGui.GetWindowDrawList(ctx)
    local x, y = ImGui.GetCursorScreenPos(ctx)
    local Cx, Cy = x + w/2, y+h/2

    local clr = clr or ImGui.GetStyleColor(ctx,ImGui.Col_Button)
    local clr2 = clr2 or ImGui.GetStyleColor(ctx,ImGui.Col_Text)
    local act = ImGui.InvisibleButton(ctx,label, w, h   )
    ImGui.DrawList_AddRectFilled(WDL, x, y, x+w,y+h , clr, 3 )

    local circle = ImGui.DrawList_AddCircleFilled
    if fill == 'No Fill' then 
        circle = ImGui.DrawList_AddCircle
    end
    if outlineClr then 
        ImGui.DrawList_AddRect(WDL, x, y, x+w,y+h , outlineClr, 3 )
    end

    if number == 1 then 
        circle(WDL, Cx ,Cy,  w/6, clr2)
    elseif number == 2 then 
        circle(WDL, Cx ,Cy - w/4,  w/8, clr2)
        circle(WDL, Cx ,Cy+ w/4,  w/8, clr2)
    elseif number == 3 then 
        circle(WDL, Cx- w/4, Cy- w/4, w/8, clr2)
        circle(WDL, Cx+ w/4, Cy+ w/4, w/8, clr2)
        circle(WDL, Cx, Cy   , w/8, clr2)
    elseif number == 4 then 
        circle(WDL, Cx- w/4, Cy- w/4, w/8, clr2)
        circle(WDL, Cx+ w/4, Cy+ w/4, w/8, clr2)
        circle(WDL, Cx- w/4, Cy+ w/4 , w/8, clr2)
        circle(WDL, Cx+ w/4, Cy- w/4 , w/8, clr2)
    elseif number ==5 then 
        circle(WDL, Cx- w/4, Cy- w/4, w/8, clr2)
        circle(WDL, Cx+ w/4, Cy+ w/4, w/8, clr2)
        circle(WDL, Cx- w/4, Cy+ w/4 , w/8, clr2)
        circle(WDL, Cx+ w/4, Cy- w/4 , w/8, clr2)
        circle(WDL, Cx, Cy   , w/8, clr2)
    elseif number ==6 then 
        circle(WDL, Cx- w/4, Cy- w/4, w/9, clr2)
        circle(WDL, Cx+ w/4, Cy     , w/9, clr2)
        circle(WDL, Cx+ w/4, Cy+ w/4, w/9, clr2)
        circle(WDL, Cx- w/4, Cy+ w/4, w/9, clr2)
        circle(WDL, Cx+ w/4, Cy- w/4, w/9, clr2)
        circle(WDL, Cx- w/4, Cy, w/9, clr2)
    end 
    if ImGui.IsItemActive(ctx) then 
        local act  = Generate_Active_And_Hvr_CLRs(clr)
        ImGui.DrawList_AddRectFilled(WDL, x, y, x+w,y+h , act, 3 )
    end 
    if act then 
        return act
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
        local UserOS = r.GetOS()

        if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
        else  outY = -outY
        end

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


function InsertSample(v)
    r.Main_OnCommand(40769,0) --- Unselect ALL
    r.Main_OnCommand(r.NamedCommandLookup('_BR_SAVE_CURSOR_POS_SLOT_16'), 0 )
    local rv = r.InsertMedia(v, 0) --0 is add to current track, 1=add new track, 3=add to selected items as takes
    r.Main_OnCommand(r.NamedCommandLookup('_BR_RESTORE_CURSOR_POS_SLOT_16'), 0)
    return rv 
end 

function Match_Itm_Len_and_Src_Len(src, itm, tk)
    len = r.GetMediaSourceLength(src)
    retval,  section,  start,  len,  fade,  reverse = r.BR_GetMediaSourceProperties(tk)
    rv, rv, len = r.PCM_Source_GetSectionInfo(src)

    r.SetMediaItemInfo_Value(itm, 'D_LENGTH', len)
    r.UpdateArrange()
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

function Remove_Dir_path (v)
    if not v then return end 
    local id = string.find(v, "/[^/]*$")
    return v:sub((id or 0 )+1)
end 


function FilterFileType (a, tb )
    local T ={}
    for i, file in pairs(a) do 
        local found 

            local id = (string.find(file, "%.[^%.]*$") or 0 )  + 1
            
            if  FindExactStringInTable(tb, file:sub(id )) then
                found = true 
            end

                
        if found then table.insert(T, file) end 
    end
    return T
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
function Add_Pan_Knob(tb, label, labeltoShow, v_min,v_max)
    --r.ImGui_SetNextItemWidth(ctx, 17)
    local radius_outer = 17
    local pos = { r.ImGui_GetCursorScreenPos(ctx) }
    local center = { pos[1] + radius_outer, pos[2] + radius_outer }
    local CircleClr
    local line_height = r.ImGui_GetTextLineHeight(ctx)
    local draw_list = r.ImGui_GetWindowDrawList(ctx)
    local item_inner_spacing = { r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing()) }
    local mouse_delta = { ImGui.GetMouseDelta(ctx) }

    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25

    local pan_V =   r.GetMediaItemTakeInfo_Value(tb.tk, "D_PAN")
    local p_value =  (pan_V + 1) / 2  

    r.ImGui_InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height - 10 + item_inner_spacing[2])

    local value_changed = false
    local is_active = r.ImGui_IsItemActive(ctx)
    local is_hovered = r.ImGui_IsItemHovered(ctx)

    if is_active and mouse_delta[2] ~= 0.0  then
        local step = (v_max - v_min) / 100
        --if Mods == Shift then step = 0.001 end
        local out  = ((pan_V + (-(mouse_delta[2])*step ))) 

        out = SetMinMax(out, -1, 1)
        r.SetMediaItemTakeInfo_Value(tb.tk, "D_PAN", out   )
        r.UpdateArrange()
        
    end
    if is_active and ImGui.IsMouseDoubleClicked(ctx,0) then 
        r.SetMediaItemTakeInfo_Value(tb.tk, "D_PAN", 0   )

    end 
    

    local ClrOverRide , ClrOverRide_Act


    if is_active then
        HideCursorTillMouseUp(0)
        lineClr =  ClrOverRide or r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrabActive())
        CircleClr = ClrOverRide_Act or Change_Clr_A(  getClr(r.ImGui_Col_SliderGrabActive()), -0.3)
    elseif is_hovered  then
        lineClr = ClrOverRide_Act or Change_Clr_A( getClr(r.ImGui_Col_SliderGrabActive()), -0.3)
    else
        lineClr = ClrOverRide or  r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBgHovered())
    end




    if ActiveAny == true then
        if IsLBtnHeld == false then ActiveAny = false end
    end

    local t = (p_value - v_min) / (v_max - v_min)
    local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
    local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
    local radius_inner = radius_outer * 0.40
    



    
    local radius_outer = radius_outer
    
    r.ImGui_DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, CircleClr or lineClr, 16)
    r.ImGui_DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
        center[2] + angle_sin * (radius_outer - 2), lineClr, 2.0)
    r.ImGui_DrawList_AddText(draw_list, pos[1], pos[2] + radius_outer * 2 + item_inner_spacing[2],
        reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_Text()), labeltoShow)


    if is_active or is_hovered --[[ and FX[FxGUID].DeltaP_V ~= 1 ]] then
        local window_padding = { r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_WindowPadding()) }
        r.ImGui_SetNextWindowPos(ctx, pos[1] - window_padding[1],
            pos[2] - line_height - item_inner_spacing[2] - window_padding[2] - 8)
        ImGui.SetNextWindowSize(ctx, 60, 30)
        r.ImGui_BeginTooltip(ctx)
        local L_or_R 
        if pan_V > 0 then L_or_R = 'R' elseif pan_V < 0 then  L_or_R = 'L' else L_or_R = '' end 


        if Mods == Shift then
            r.ImGui_Text(ctx, ('%.1f'):format(math.abs( (pan_V * 100))).. '% '..L_or_R)
        else
            r.ImGui_Text(ctx, ('%.0f'):format(math.abs( (pan_V * 100))).. '% '..L_or_R)
        end
        r.ImGui_EndTooltip(ctx)
    end
    if is_hovered then HelperMsg.Alt_R = 'Delta-Solo' end
    
    return 

end


function MatchFilesFromKeyWords(words, tb)
    local outTB ={}

    

    for i, v in ipairs(tb) do 
        local not_found 
        for I,V in ipairs(words) do 

            if not  string.lower(v):find(string.lower(V)) then 
                not_found = true 
            end 
        end 

        if not not_found then
            table.insert(outTB, v)
        end


    end 

    return outTB
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


function DndAddFX_SRC(fx)
    if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptBeforeDelivery()) then
      r.ImGui_SetDragDropPayload(ctx, 'DND ADD FX', fx)
      r.ImGui_Text(ctx, fx)
      r.ImGui_EndDragDropSource(ctx)
    end
end

function DndAddFXfromBrowser_TARGET(Dest, ClrLbl, SpaceIsBeforeRackMixer, SpcIDinPost)

    --if not DND_ADD_FX then return  end
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0)
    if r.ImGui_BeginDragDropTarget(ctx) then
        local dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX')
        
        
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
                for i, v in pairs(Trk[TrkID].PreFX) do r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v,
                    true) end
            elseif SpcInPost then
                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
                table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
                -- InsertToPost_Src = FX_Idx + offset+2
                for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
                end
            elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
                DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx, Dest + 1)
            end
            FX_Idx_OpenedPopup = nil

        end

    end
    r.ImGui_PopStyleColor(ctx)
end

function AddFX_Menu(FX_Idx)
    local function DrawFxChains(tbl, path)
        local extension = ".RfxChain"
        path = path or ""
        for i = 1, #tbl do
            if tbl[i].dir then
                if r.ImGui_BeginMenu(ctx, tbl[i].dir) then
                    DrawFxChains(tbl[i], table.concat({ path, os_separator, tbl[i].dir }))
                    r.ImGui_EndMenu(ctx)
                end
            end
            if type(tbl[i]) ~= "table" then
                if r.ImGui_Selectable(ctx, tbl[i]) then
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
            r.SetTrackStateChunk( TRACK, chunk, true )
        else
            r.Main_openProject( track_template_path )
        end
    end
    local function DrawTrackTemplates(tbl, path)
        local extension = ".RTrackTemplate"
        path = path or ""
        for i = 1, #tbl do
            if tbl[i].dir then
                if r.ImGui_BeginMenu(ctx, tbl[i].dir) then
                    local cur_path = table.concat({ path, os_separator, tbl[i].dir })
                    DrawTrackTemplates(tbl[i], cur_path)
                    r.ImGui_EndMenu(ctx)
                end
            end
            if type(tbl[i]) ~= "table" then
                if r.ImGui_Selectable(ctx, tbl[i]) then
                    local template_str = table.concat({ path, os_separator, tbl[i], extension })
                    LoadTemplate(template_str) -- ADD NEW TRACK FROM TEMPLATE
                end
            end
        end
    end

    if r.ImGui_BeginPopup(ctx, 'Btwn FX Windows' .. FX_Idx) then
        local AddedFX
        FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')

        if FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost,SpcIDinPost) then
            AddedFX=true 
            r.ImGui_CloseCurrentPopup(ctx)
        end -- Add FX Window
        r.ImGui_SeparatorText(ctx, "PLUGINS")
        for i = 1, #CAT do
            if r.ImGui_BeginMenu(ctx, CAT[i].name) then
                if CAT[i].name == "FX CHAINS" then
                    DrawFxChains(CAT[i].list)
                elseif CAT[i].name == "TRACK TEMPLATES" then -- THIS IS MISSING
                    DrawTrackTemplates(CAT[i].list)                        
                else
                    for j = 1, #CAT[i].list do
                        if r.ImGui_BeginMenu(ctx, CAT[i].list[j].name ) then
                            for p = 1, #CAT[i].list[j].fx do
                                if CAT[i].list[j].fx[p] then
                                    if r.ImGui_Selectable(ctx, CAT[i].list[j].fx[p]) then
                                        if TRACK then
                                            AddedFX = true 
                                            r.TrackFX_AddByName(TRACK, CAT[i].list[j].fx[p], false,-1000 - FX_Idx)
                                            LAST_USED_FX = CAT[i].list[j].fx[p]
                                        end
                                    end
                                end
                            end
                            r.ImGui_EndMenu(ctx)
                        end
                    end
                end
                r.ImGui_EndMenu(ctx)
            end
        end
        if r.ImGui_BeginMenu(ctx, "FXD INSTRUMENTS & EFFECTS") then
            if r.ImGui_Selectable(ctx, "ReaDrum Machine") then
                local chain_src = "../Scripts/FX Devices/BryanChi_FX_Devices/src/FXChains/ReaDrum Machine.RfxChain"
                local found = false
                count = r.TrackFX_GetCount(TRACK) -- 1 based
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
                AddedFX=true
                r.PreventUIRefresh(-1)
                EndUndoBlock("ADD DRUM MACHINE")
                end
            end
            DndAddFX_SRC("../Scripts/FX Devices/BryanChi_FX_Devices/src/FXChains/ReaDrum Machine.RfxChain")
            r.ImGui_EndMenu(ctx)
        end
        TRACK = r.GetSelectedTrack(0, 0)
        if r.ImGui_Selectable(ctx, "CONTAINER") then
            r.TrackFX_AddByName(TRACK, "Container", false, -1000 - FX_Idx)
            AddedFX=true
            LAST_USED_FX = "Container"
        end
        DndAddFX_SRC("Container")
        if r.ImGui_Selectable(ctx, "VIDEO PROCESSOR") then
            r.TrackFX_AddByName(TRACK, "Video processor", false, -1000 - FX_Idx)
            AddedFX=true
            LAST_USED_FX = "Video processor"
        end
        DndAddFX_SRC("Video processor")
        if LAST_USED_FX then
            if r.ImGui_Selectable(ctx, "RECENT: " .. LAST_USED_FX) then
                r.TrackFX_AddByName(TRACK, LAST_USED_FX, false, -1000 - FX_Idx)
                AddedFX=true
            end
        end
        DndAddFX_SRC(LAST_USED_FX)
        r.ImGui_SeparatorText(ctx, "UTILS")
        if r.ImGui_Selectable(ctx, 'Add FX Layering', false) then
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
            r.ImGui_CloseCurrentPopup(ctx)
            if val & 4 ~= 0 then
                r.SNM_SetIntConfigVar("fxfloat_focus", val|4) -- re-enable Auto-float
            end
        elseif r.ImGui_Selectable(ctx, 'Add Band Split', false) then
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

        if AddedFX then  RetrieveFXsSavedLayout(Sel_Track_FX_Count) end 



        if CloseAddFX_Popup then
            r.ImGui_CloseCurrentPopup(ctx)
            CloseAddFX_Popup = nil
        end
        r.ImGui_EndPopup(ctx)
    else
        Dvdr.Clr[ClrLbl or ''] = 0x131313ff
    end

end

--[[ function HideCursorTillMouseUp(MouseBtn, ifneedctx)
    if ifneedctx then ctx = ifneedctx end
    UserOS = r.GetOS()
    if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
        Invisi_Cursor = reaper.JS_Mouse_LoadCursorFromFile(r.GetResourcePath() .. '/Cursors/Empty Cursor.cur')
    end

    if r.ImGui_IsMouseClicked(ctx, MouseBtn) then
        MousePosX_WhenClick, MousePosY_WhenClick = r.GetMousePosition()
    end

    if MousePosX_WhenClick then
        window = r.JS_Window_FromPoint(MousePosX_WhenClick, MousePosY_WhenClick)

        local function Hide()
            if r.ImGui_IsMouseDown(ctx, MouseBtn) then
                r.JS_Mouse_SetCursor(Invisi_Cursor)
                r.defer(Hide)
            else
                reaper.JS_WindowMessage_Release(window, "WM_SETCURSOR")
                if r.ImGui_IsMouseReleased(ctx, MouseBtn) then
                    r.JS_Mouse_SetPosition(MousePosX_WhenClick, MousePosY_WhenClick)
                end
            end
        end
        Hide()
    end
end ]]




function get_fx_id_from_container_path(tr, idx1, ...)
    local sc,rv = reaper.TrackFX_GetCount(tr)+1, 0x2000000 + idx1
    for i,v in ipairs({...}) do
      local ccok, cc = reaper.TrackFX_GetNamedConfigParm(tr, rv, 'container_count')
      if ccok ~= true then return nil end
      rv = rv + sc * v
      sc = sc * (1+tonumber(cc))
    end
    return rv
end

function get_container_path_from_fx_id(tr, fxidx) -- returns a list of 1-based IDs from a fx-address
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

function fx_map_parameter(tr, fxidx, parmidx) -- maps a parameter to the top level parent, returns { fxidx, parmidx }
    local path = get_container_path_from_fx_id(tr, fxidx)
    if not path then return nil end
    while #path > 1 do
      fxidx = path[#path]
      table.remove(path)
      local cidx = get_fx_id_from_container_path(tr,table.unpack(path))
      if cidx == nil then return nil end
      local i, found = 0, nil
      while true do
        local rok, r = reaper.TrackFX_GetNamedConfigParm(tr,cidx,string.format("param.%d.container_map.fx_index",i))
        if not rok then break end
        if tonumber(r) == fxidx - 1 then
          rok, r = reaper.TrackFX_GetNamedConfigParm(tr,cidx,string.format("param.%d.container_map.fx_parm",i))
          if not rok then break end
          if tonumber(r) == parmidx then found = true parmidx = i break end
        end
        i = i + 1
      end
      if not found then
        -- add a new mapping
        local rok, r = reaper.TrackFX_GetNamedConfigParm(tr,cidx,"container_map.add")
        if not rok then return nil end
        r = tonumber(r)
        reaper.TrackFX_SetNamedConfigParm(tr,cidx,string.format("param.%d.container_map.fx_index",r),tostring(fxidx - 1))
        reaper.TrackFX_SetNamedConfigParm(tr,cidx,string.format("param.%d.container_map.fx_parm",r),tostring(parmidx))
        parmidx = r
      end
    end
    return fxidx, parmidx
end

--------------==  Space between FXs--------------------
function AddSpaceBtwnFXs(FX_Idx, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth, FX_Idx_in_Container)

    local SpcIsInPre, Hide, SpcInPost, MoveTarget
    local WinW

    if FX_Idx == 0 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx = 1 end

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
        if r.ImGui_IsMouseHoveringRect(ctx, Cx_LeftEdge + 10, Cy_BeforeFXdevices, Cx_LeftEdge + 25, Cy_BeforeFXdevices + 220) and DragFX_ID ~= 0 then
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

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(),  Dvdr.Clr[ClrLbl])

    local w = 10 + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0) + (AdditionalWidth or 0)
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)



    -- StyleColor For Space Btwn Fx Windows
    if not Hide then
        if r.ImGui_BeginChildFrame(ctx, '##SpaceBetweenWindows' .. FX_Idx .. tostring(SpaceIsBeforeRackMixer) .. 'Last SPC in Rack = ' .. tostring(AddLastSPCinRack), 10, 220, r.ImGui_WindowFlags_NoScrollbar()+r.ImGui_WindowFlags_NoScrollWithMouse()+r.ImGui_WindowFlags_NoNavFocus()+r.ImGui_WindowFlags_NoNav()) then
            --HOVER_RECT = r.ImGui_IsWindowHovered(ctx,  r.ImGui_HoveredFlags_RectOnly())
            HoverOnWindow = r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_AllowWhenBlockedByActiveItem())
            WinW  = r.ImGui_GetWindowSize(ctx)


            if HoverOnWindow == true and Dragging_TrueUntilMouseUp ~= true and DragDroppingFX ~= true and AssignWhichParam == nil and Is_ParamSliders_Active ~= true and Wet.ActiveAny ~= true and Knob_Active ~= true and not Dvdr.JustDroppedFX and LBtn_MousdDownDuration < 0.2 then
                Dvdr.Spc_Hover[TblIdxForSpace] = Df.Dvdr_Hvr_W
                if DebugMode then
                    tooltip('FX_Idx :' .. FX_Idx ..'\n Pre/Post/Norm : ' ..
                        tostring(SpaceIsBeforeRackMixer) .. '\n SpcIDinPost: ' .. tostring(SpcIDinPost).. '\n AddLastSpace = '..(AddLastSpace or 'nil') ..'\n AdditionalWidth = '..(AdditionalWidth or 'nil') )
                end
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), CLR_BtwnFXs_Btn_Hover)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), CLR_BtwnFXs_Btn_Active)

                local x, y = r.ImGui_GetCursorScreenPos(ctx)
                r.ImGui_SetCursorScreenPos(ctx, x, Glob.WinT)
                BTN_Btwn_FXWindows = r.ImGui_Button(ctx, '##Button between Windows', 99, 217)
                FX_Insert_Pos = FX_Idx

                if BTN_Btwn_FXWindows then
                    FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')
                    r.ImGui_OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx)
                end
                r.ImGui_PopStyleColor(ctx, 2)
                Dvdr.RestoreNormWidthWait[FX_Idx] = 0
            else
                Dvdr.RestoreNormWidthWait[FX_Idx] = (Dvdr.RestoreNormWidthWait[FX_Idx] or 0) + 1
                if Dvdr.RestoreNormWidthWait[FX_Idx] >= 8 then
                    Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                    Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                end
            end



            AddFX_Menu(FX_Idx)
            

            r.ImGui_EndChildFrame(ctx)
        end
    end
    r.ImGui_PopStyleColor(ctx)
    local FXGUID_FX_Idx = r.TrackFX_GetFXGUID(LT_Track, FX_Idx - 1)


    function MoveFX(DragFX_ID, FX_Idx, isMove, AddLastSpace)
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
            if r.ImGui_BeginDragDropTarget(ctx) then
                FxDroppingTo = FX_Idx
                ----- Drag Drop FX -------
                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                if FxGUID == FxGUID_DragFX then
                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                end

                r.ImGui_SameLine(ctx, 100, 10)


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
                if Payload_Type == 'DND ADD FX' then
                    DndAddFXfromBrowser_TARGET(FX_Idx, ClrLbl) -- fx layer
                end

                

                r.ImGui_EndDragDropTarget(ctx)
            else
                Dvdr.Width[TblIdxForSpace] = 0
                FxDroppingTo = nil
            end
        end
        r.ImGui_SameLine(ctx, 100, 10)
    elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
        if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
            Dvdr.Width[TblIdxForSpace] = 0
        else
            if r.ImGui_BeginDragDropTarget(ctx) then
                FxDroppingTo = FX_Idx
                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                if FxGUID == FxGUID_DragFX then
                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                end

                r.ImGui_SameLine(ctx, 100, 10)
                local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                local InsPos = math.min(FX_Idx - ContainerIdx + 1, #FX[FxGUID_Container].FXsInBS)


                if dropped and Mods == 0 then
                    local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                    local InsPos = SetMinMax(FX_Idx - ContainerIdx + 1, 1, #FX[FxGUID_Container].FXsInBS)



                    DropFXintoBS(FxGUID_DragFX, FxGUID_Container, FX[FxGUID_Container].Sel_Band,
                        DragFX_ID, FX_Idx, 'DontMove')
                    Dvdr.Width[TblIdxForSpace] = 0
                    FxDroppingTo = nil

                    MoveFX(Glob.Payload, FX_Idx + 1, true)
                elseif dropped and Mods == Apl then
                    DragFX_Src = DragFX_ID

                    if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                    DropToLyrID = LyrID
                    DroptoRack = FXGUID_RackMixer
                    --MoveFX(DragFX_Src, DragFX_Dest ,false )

                    Dvdr.Width[TblIdxForSpace] = 0
                    FxDroppingTo = nil
                end
                -- Add from Sexan Add FX
                if Payload_Type == 'DND ADD FX' then
                    DndAddFXfromBrowser_TARGET(FX_Idx, ClrLbl)  -- band split
                end

                r.ImGui_EndDragDropTarget(ctx)
            else
                Dvdr.Width[TblIdxForSpace] = 0
                FxDroppingTo = nil
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

        if r.ImGui_BeginDragDropTarget(ctx) then

            if Payload_Type == 'FX_Drag' then


                local allowDropNext, MoveFromPostToNorm, DontAllowDrop
                local FX_Idx = FX_Idx
                if Mods == Apl then allowDropNext = true end
                if not FxGUID_DragFX then FxGUID_DragFX =DragFxGuid end 
                local rv, type, payload, is_preview, is_delivery = r.ImGui_GetDragDropPayload( ctx)


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
                    r.ImGui_SameLine(ctx, nil, 0)

                    Dvdr.Width[TblIdxForSpace] = 0
                    r.ImGui_EndDragDropTarget(ctx)
                else
                    HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect', Foreground)

                    Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width

                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
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
                        --[[ end ]]

                        -- Move FX Out of BandSplit
                        if FX[FxGUID_DragFX].InWhichBand then
                            for i = 0, Sel_Track_FX_Count - 1, 1 do
                                if FX[FXGUID[i]].FXsInBS then -- i is Band Splitter
                                    table.remove(FX[FXGUID[i]].FXsInBS,
                                        tablefind(FX[FXGUID[i]].FXsInBS, FxGUID_DragFX))
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FxGUID_DragFX, '', true)
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FxGUID_DragFX, '', true)
                                end
                            end
                            FX[FxGUID_DragFX].InWhichBand = nil
                        end


                        -- Move FX Out of Layer
                        if Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] ~= nil then
                            Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] = Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] - 1
                        end
                        r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FXGUID_To_Check_If_InLayer .. 'in layer', "")
                        FX.InLyr[FXGUID_To_Check_If_InLayer] = nil
                        Dvdr.JustDroppedFX = true
                    elseif dropped and Mods == Apl then
                        local copypos = FX_Idx + 1
                        payload = tonumber(payload)

                        if FX_Idx == 0 then copypos = 0 end
                        MoveFX(payload, copypos, false)
                    end
                    r.ImGui_SameLine(ctx, nil, 0)

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
                    r.ImGui_SameLine(ctx, nil, 0)
                    Dvdr.Width[TblIdxForSpace] = 0
                    r.ImGui_EndDragDropTarget(ctx)

                    --[[  ]]
                    Dvdr.Width[FX_Idx] = 0
                else --if dragging to an adequate space
                    Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX Layer Repositioning')
                    Dvdr.Width[TblIdxForSpace] = 30

                    if dropped then
                        RepositionFXsInContainer(FX_Idx)
                        --r.Undo_EndBlock('Undo for moving FX layer',0)
                    end
                end
            elseif Payload_Type == 'BS_Drag' then
                local Pl = tonumber(Glob.Payload)


                if SpaceIsBeforeRackMixer == 'SpcInBS' or FX_Idx == Pl or Pl + (#FX[FXGUID[Pl]].FXsInBS or 0) + 2 == FX_Idx then
                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'BS_Drag')
                    Dvdr.Width[TblIdxForSpace] = 30
                    if dropped then
                        RepositionFXsInContainer(FX_Idx, Glob.Payload)
                    end
                end
            elseif Payload_Type == 'DND ADD FX' then

                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0)

                local dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX')
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
                        for i, v in pairs(Trk[TrkID].PreFX) do r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v,
                            true) end
                    elseif SpcInPost then
                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
                        table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
                        -- InsertToPost_Src = FX_Idx + offset+2
                        for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
                        end
                    elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
                        DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx, Dest + 1)
                    end
                    FX_Idx_OpenedPopup = nil
                    
                end
                r.ImGui_PopStyleColor(ctx)

                r.ImGui_EndDragDropTarget(ctx)
            end

            
        else
            
            Dvdr.Width[TblIdxForSpace] = 0
            Dvdr.Clr[ClrLbl] = 0x131313ff
            r.ImGui_SameLine(ctx, nil, 0)
        end


        
        
        r.ImGui_SameLine(ctx, nil, 0)
    end




    return WinW
end


