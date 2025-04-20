r=reaper
CurrentDirectory = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] -- GET DIRECTORY FOR REQUIRE

Added={}
Rslt ={}
KeyWord={}
DontFocusKeyword = 0



package.path = CurrentDirectory .. "?.lua;"
require("Functions.General Functions")
require("Functions.Initial Stuff")



if ThirdPartyDeps() then return end
package.path = r.ImGui_GetBuiltinPath() .. '/?.lua'
im = require 'imgui' '0.9'









function BuildDataBase(PATH)
    found_dirs,  dirs_array, found_files, files_array = ultraschall.GetAllRecursiveFilesAndSubdirectories( PATH, dir_filter,  dir_case_sensitive, file_filter,  file_case_sensitive )

    -- get selected items
    Sel_Itms = {}
    for i= 1 , r.CountSelectedMediaItems(0) , 1 do 
        Sel_Itms[i]= Sel_Itms[i] or {}
        Sel_Itms[i].it , Sel_Itms[i].tk, Sel_Itms[i].src = GetSelectedMediaItemInfo(i-1)
        Sel_Itms[i].FileName = r.GetMediaSourceFileName(Sel_Itms[i].src)
    end
    local File_Name_No_Path = {}
    
    for i, v in pairs(files_array) do 
        local Name = Remove_Dir_path (v)
        for i, V in ipairs(Sel_Itms) do 

            if V.FileName == v then 
                Rslt[v]= Rslt[v] or {}
                Rslt[v] = Sel_Itms[i]
                Rslt[v].Added = true 
            end 
        end     


        table.insert(File_Name_No_Path, Name )
    end 
    return files_array, File_Name_No_Path
end





CreateFont(im)

ctx = r.ImGui_CreateContext('Sample Stacker', r.ImGui_ConfigFlags_DockingEnable())
package.path = CurrentDirectory .. "?.lua;"
require("Functions.General Functions")


function Random_Button_For_Selected_Samples()
    if #Sel_Samples>1 then 


    end 
end

function Show_AddedSamples (MatchedFiles)
    function Added_Samples_Number_Box(i, sz)
        im.Button( ctx, i, sz,sz)
    end
    
    function Added_Samples_Volume_Drag(i, tb)
        if not tb or not tb.it   then return end 
        im.SetNextItemWidth(ctx, 50)
        local Vol = r.GetMediaItemInfo_Value( tb.it, 'D_VOL' )
       -- local v =   10^(Vol/20)
    
        local Vol_dB = dBFromVal(Vol)
    
    
        im.SetNextItemWidth(ctx, 40)
        local rv, Vol_dB = im.DragDouble( ctx, '## Vol'..i, Vol_dB,  0.2, -120, 24, ('%.1f'):format(Vol_dB))
        SL(nil,0)
        im.Text(ctx, 'dB')
        SL(nil, 10 )
    
        if rv then
            --[[ local x, y = ImGui.GetMouseDelta( ctx)
            r.SetMediaItemInfo_Value( tb.it, 'D_VOL' , Vol + y/20 ) ]]
            r.SetMediaItemInfo_Value( tb.it, 'D_VOL' ,  ValFromdB(  Vol_dB ))
            r.UpdateArrange()
            HideCursorTillMouseUp(0)
            --ImGui.ResetMouseDragDelta(ctx)
            
        end
    
        Add_Pan_Knob(tb, '## Pan'..i, '', 0, 1)
    
        
    end
    function Added_Samples_Selection(i)
        local x, y , w , h , WDL    
        w, h = im.GetWindowSize( ctx)
        x, y = im.GetWindowPos( ctx)
        WDL  = im.GetWindowDrawList(ctx)

        if im.IsWindowHovered(ctx, im.HoveredFlags_ChildWindows) then 
            

            if MODS==im.Mod_Alt then  
                im.DrawList_AddRectFilled(WDL, x, y , x+w, y+h , 0x93222266)
            else    
                im.DrawList_AddRectFilled(WDL, x, y , x+w, y+h , 0xffffff11)
            end 
            if im.IsMouseClicked(ctx,0) and MODS==0   then 
                im.DrawList_AddRectFilled(WDL, x, y , x+w, y+h , 0xffffff55)
                Sel_Samples= {}
                
                Sel_Samples[1]=i

                PreviewSample_Solo(Added[i].it)
            elseif im.IsMouseClicked(ctx,0) and MODS==im.Mod_Super then 
                im.DrawList_AddRectFilled(WDL, x, y , x+w, y+h , 0xffffff55)
                if tablefind(Sel_Samples,i) then 
                    table.remove(Sel_Samples, tablefind(Sel_Samples,i))
                else
                    table.insert(Sel_Samples, i)
                end 

                PreviewSample_Solo(Added[i].it, Sel_Samples, Added)
            elseif im.IsMouseClicked(ctx,0) and MODS==im.Mod_Alt then 
                
                --table.remove(Added, i)
                table.insert(Delete_Itm,  i)

            end
        end 
        if FindExactStringInTable(Sel_Samples, i) then 
            im.DrawList_AddRect(WDL, x, y , x+w, y+h , 0xffffff55)
            im.DrawList_AddRectFilled(WDL, x, y , x+w, y+h , 0xffffff0f)
    
        end
    end

    function Solo_State_Controls()
        if Solo_Playing_Itm then 

            if im.IsKeyPressed(ctx, im.Key_Space) then 

                --r.SetMediaItemInfo_Value(it, 'B_UISEL', 1)  --select item 
                r.Main_OnCommand(41560,0) -- unsolo
            end 
        end 
        if #Sel_Samples >1 then --- if there are more than one samples selected 
            if im.IsKeyPressed(ctx, im.Key_Space) then 
                r.Main_OnCommand(41558, 0 ) -- solo item 

            end 
        end 

    end

    function RandomButton_For_Added_Sample(i)
        SL()
        local sz = Added_Saamples_Name_Height
        --ImGui.Button(ctx, 'Random',  sz,sz)
        if DiceButton ('Dice'..i, 3, sz,sz , nil,nil,'No Fill', im.GetStyleColor(ctx,im.Col_Text)) then 
            local tb = FilterFileType (files_array, File_Types_To_Show )


            local matched = MatchFilesFromKeyWords(Added[i].KeyWord, tb)


            BUILD_PEAK = {}

            if Added[i].it then 
                SwapSample(Added[i], matched)
            else 
                AddRandomSample(1, i)
            end

            PreviewSample_Solo(Added[i].it, nil , Added)


        end 
    end

    local function ShowSampleName(v)
        if v.src then 
            local filenamebuf = r.GetMediaSourceFileName(v.src)
    
            local Name = filenamebuf:sub(string.find(filenamebuf, "/[^/]*$")+1)
    
            im.Text(ctx, Name)
        end
    end


    

    for i, v in ipairs(Added) do 
        local W = Added_Saamples_Name_Width
        local H = Added_Saamples_Name_Height
        im.BeginChild(ctx, '##Sample'..i, W, H, nil,im.WindowFlags_NoScrollbar)
        Added_Samples_Number_Box(i,H)
        SL()
        --ImGui.AlignTextToFramePadding( ctx)
        --ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 20 )
        --local x , y = ImGui.GetCursorPos(ctx)

        ShowSampleName(v)
        Show_Added_Samples_KeyWord(v, H + 5, H/2, i)
        im.SetCursorPos(ctx, 10, 10 )
        Added_Samples_Selection(i)
        
        Solo_State_Controls()

        --ImGui.PopStyleVar(ctx)
        
        im.EndChild(ctx)
        RandomButton_For_Added_Sample(i)
        SL()
        Added_Samples_Volume_Drag(i,v )
        im.Separator(ctx)

    end 
end

function Show_Added_Samples_KeyWord(tb, x, y , i )
    im.SetCursorPos(ctx, x, y )
    for i, v in ipairs(tb.KeyWord) do 
        im.SetCursorPosY(ctx, y )
        if im.Button(ctx, v) then 
            table.remove(tb.KeyWord, i )
        end 
        SL()
    end
    if AddNewKeyWord~=i then 
        im.SetCursorPosY(ctx, y )
        if im.Button(ctx, '+##' ) then 
            AddNewKeyWord = i
            
        end 
    elseif AddNewKeyWord==i then 
        im.SetKeyboardFocusHere(ctx)
        im.SetNextItemWidth(ctx, 60)
        local rv, txt =  im.InputText(ctx, '##NewKeyWord'..i, txt) 
        if r.ImGui_IsItemDeactivatedAfterEdit( ctx) and txt  then 
           table.insert(  Added[i].KeyWord ,  txt)
           AddNewKeyWord=nil
        end
    end 


end

function Show_MatchedSamples(MatchedFiles)
    if not MatchedFiles then return end 
    im.BeginChild(ctx, 'Matched Samples')
    for i, v in pairs( MatchedFiles) do 
        Rslt[v]= Rslt[v] or {}
        if  not Rslt[v].Added  then 
            local Name = v:sub(string.find(v, "/[^/]*$")+1)
            rv , Rslt[v].Added = im.Checkbox( ctx, Name..'##'..v, Rslt[v].Added)
            if rv  then 
                InsertSample(v)

                Rslt[v].it, Rslt[v].tk , Rslt[v].src = GetSelectedMediaItemInfo(0)
                table.insert(Added, {})
                Added[#Added]= Rslt[v]
                Added[#Added].KeyWord = {}
                if SearchTxt~='' then 
                    table.insert(Added[#Added].KeyWord, SearchTxt)
                end
                for i, v in ipairs(KeyWord) do 
                    table.insert(Added[#Added].KeyWord, v)
                end 
            end
        end
    end
    im.EndChild(ctx)
end


AttachFont(ctx, im)

function SearchBar()
    im.PushFont(ctx, Arial_20)
    if FirstLoop then im.SetKeyboardFocusHere(ctx) end 
    rv, SearchTxt = r.ImGui_InputText( ctx, '##', SearchTxt--[[ ImGui.InputTextFlags_EnterReturnsTrue ]])
    im.PopFont(ctx)


    if im.IsItemDeactivatedAfterEdit(ctx) then 
        if  SearchTxt~=''   then
            table.insert(KeyWord, SearchTxt)
            SearchTxt = nil 
            im.SetKeyboardFocusHere( ctx,   -1)
        end
    end 
    if im.IsItemActive (ctx) then 
        if SearchTxt=='' and KeyWord[1] and im.IsKeyPressed(ctx, im.Key_Backspace) and DontFocusKeyword ==0  then 
            ConfirmDeleteKeyWord = #KeyWord
        end 
        if SearchTxt~= '' then 
            ConfirmDeleteKeyWord = nil 
        end 
    end 

    
    local rv, MatchedFiles  = FindStringInTable(files_array, SearchTxt, true ) 
    if not MatchedFiles then return end 
    --[[ for i, v in ipairs(MatchedFiles) do 
        if  not FilterFileType (v, File_Types_To_Show )then 
            --table.remove(MatchedFiles, i)
            MatchedFiles[i]=nil
        end 
    end  ]]

    MatchedFiles = FilterFileType(MatchedFiles, File_Types_To_Show)


    if KeyWord[1] then 
        for i , v in ipairs(KeyWord) do 
            rv, MatchedFiles  = FindStringInTable(MatchedFiles or files_array, v, true)
        end 
    end 
    return MatchedFiles

end

function ToolBar()
    local function Save()

        if im.Button(ctx,'Save Search Set')then 
            Save_Search_Set = true 
            im.OpenPopup(ctx, 'Search Set Save Window')
        end
        if Save_Search_Set then 
            local x , y = im.GetCursorScreenPos(ctx)
            im.SetNextWindowPos(ctx, x, y - 20 )


            if im.BeginPopupModal( ctx, 'Search Set Save Window',  true , im.WindowFlags_AlwaysAutoResize+ im.WindowFlags_NoDecoration) then 
                im.SetKeyboardFocusHere(ctx)
                im.Text(ctx ,  'Search Set Name:')
                local rv, Search_Set_Name = im.InputText(ctx, '## Enter Search Set Name', Search_Set_Name , im.InputTextFlags_EnterReturnsTrue)
                if rv then 
                    Save_Search_set_Into_File(Search_Set_Name)
                    Save_Search_Set = nil
                end 

                im.EndPopup(ctx)
            end 
        end

    end
    local function Load()
        local function Load_Files()
            local path, file
            local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'ReaTeam Scripts', 'FX', 'Bryan FX Devices GITHUB', 'Sample Stacker','Search Sets')
            
            local F = scandir(dir_path)
            --local file_path = ConcatPath(dir_path, 'Search Sets.ini')
            r.RecursiveCreateDirectory(dir_path, 0)
            --[[ for i , v in ipairs(F) do 
                file_path = ConcatPath(dir_path, v)

                file = io.open(file_path, 'r')
            end  ]]
            
            return F
        end

        local function load_file_info(F)
            if F then 
                local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'ReaTeam Scripts', 'FX', 'Bryan FX Devices GITHUB', 'Sample Stacker','Search Sets')

                local file_path = ConcatPath(dir_path, F)
                local file = io.open(file_path, 'r')

                local c = file:read("*a")

                local HowManySamp =  RecallGlobInfo(c, 'How Many Samples = ', "Num")

                --S = RecallGlobInfo(c, 'Sample No%. ')
                for i = 1 , HowManySamp , 1 do 
                    Added[i] = Added[i] or {} 
                    Added[i].KeyWord = Added[i].KeyWord or {}
                    local C = c:sub(c:find('Sample No.'.. i ..'\n') , -1)
                    local HowManyKeyword = RecallGlobInfo(C, 'How Many Keywords = ', 'Num')

                    for I = 1 , HowManyKeyword , 1 do

                        Added[i].KeyWord[I] = RecallGlobInfo(C, 'KeyWord '..I.. ' = ')

                    end
                end     

            end
        end
        SL()
        if im.Button(ctx,'Load Search Set')then
            Search_Set_Files = Load_Files()
            Load_Srch_Set_Win_Open = true 
            im.OpenPopup(ctx, 'Load Search Set Window')
            ShapeFilter =  r.ImGui_CreateTextFilter(Shape_Filter_Txt)
        end

        if im.BeginPopup(ctx, 'Load Search Set Window') then 
            
            im.SetNextItemWidth(ctx, 300)
            if r.ImGui_TextFilter_Draw(ShapeFilter, ctx, '##PrmFilterTxt', 200 ) then
                Shape_Filter_Txt = r.ImGui_TextFilter_Get(ShapeFilter)
                r.ImGui_TextFilter_Set(ShapeFilter, Shape_Filter_Txt)
            end
            for i, v in ipairs(Search_Set_Files) do 
                if r.ImGui_TextFilter_PassFilter(ShapeFilter, v) then

                    if im.Selectable(ctx,v) then 

                        load_file_info(v)
                    end
                end

            end
            im.EndPopup(ctx)

        end
        SL()
    end
    Load()

    Save()

end 

function ShowKeyWords(ctx)
    im.PushFont(ctx, Arial_20)

    for i , v in ipairs(KeyWord) do 
        
        if im.Button(ctx, v) then 
            table.remove(KeyWord, i)
        end 

        if ConfirmDeleteKeyWord==i then 
            Highlight_Itm(ctx, nil, nil,0x992299ff)
            if im.IsKeyPressed(ctx, im.Key_Backspace) then  
                table.remove(KeyWord, ConfirmDeleteKeyWord)
                ConfirmDeleteKeyWord = nil
                DontFocusKeyword= 1
            end 
        end 
       SL()
    end 
    if DontFocusKeyword  > 0 then 
        DontFocusKeyword = DontFocusKeyword + 1 
    end
    if DontFocusKeyword> 5 then 
        DontFocusKeyword= 0 
    end 
    SL()
    
    im.PopFont(ctx)

end


function GlobalKeyboardShortcut()
    if im.IsKeyPressed(ctx, im.Key_Space) then 
        if not im.IsAnyItemActive( ctx) then 
            r.Main_OnCommand(40044,0) --- Unselect ALL
        end
    end 
    MODS = im.GetKeyMods(ctx)
end

function At_beginning_of_Each_Loop()
    for i, v in ipairs(Delete_Itm) do 
        if Added[v].it then 
            r.DeleteTrackMediaItem(r.GetLastTouchedTrack(), Added[v].it)
        end
        table.remove(Added,v )

    end
    r.UpdateArrange()


    Delete_Itm={}
end 

function RandomButtons(MatchedFiles, Mode)
    if not MatchedFiles then return end 
    local sz = 24
    
    for i= 1 , 6 , 1  do 
        if Mode == 'Swap and add' then 
            if DiceButton('Random'..i, i , sz,sz) then 
                BUILD_PEAK = {}
                for I, v in ipairs(Added) do 
                    if I<= i then 

                        SwapSample(v, MatchedFiles)
                        Add_KeyWord_To_Itm_tb(v.KeyWord, I )

                    end 
                end

                local HowManyFilesTo_Add = i - #Added 

                for i = 1 ,  HowManyFilesTo_Add, 1 do 
                    local filename = MatchedFiles[math.random(1, #MatchedFiles)]
                    local rv = InsertSample(filename)
                    table.insert(Added, {})
                    local TB = Added[#Added]
                    TB.it, TB.tk, TB.src = GetSelectedMediaItemInfo(0)
                    TB.KeyWord = {}
                    Add_KeyWord_To_Itm_tb(TB.KeyWord, #Added)
                    Match_Itm_Len_and_Src_Len(TB.src, TB.it, TB.tk)
                end 

            end 
        elseif Mode =='Add' then 
            if DiceButton('Random'..i, i , sz,sz) then
                AddRandomSample(i)
            end

        end 
    if i ~= 6 then SL() end 
    end


    if BUILD_PEAK then 
        HowManyDone = {}
        for i, v in ipairs(BUILD_PEAK) do 
            local prog = r.PCM_Source_BuildPeaks(v, 0)
            if prog == 0 then 
              

                r.PCM_Source_BuildPeaks(v,2) 

                r.UpdateArrange()
                --BUILD_PEAK[i] = nil
                table.insert(HowManyDone, i)
            else
                local prog = r.PCM_Source_BuildPeaks(v,1) 
                r.UpdateArrange()
                if prog == 0 then 
                    r.PCM_Source_BuildPeaks(v,2) 
                    r.UpdateArrange()
                    table.insert(HowManyDone, i)
                end

            end 
        end 



        if BUILD_PEAK and  #HowManyDone == #BUILD_PEAK then 
            BUILD_PEAK = nil 
            HowManyDone=nil

        end 

    end 
    im.Separator(ctx)

end


files_array, File_Name_No_Path= BuildDataBase('/Volumes/4TB Crucial/Sound Collections')


function Main_Loop()
    GlobalKeyboardShortcut()
    At_beginning_of_Each_Loop()
    local visible, open = im.Begin(ctx,'Sample Stacker', nil,im.WindowFlags_NoTitleBar)
    ShowKeyWords(ctx)
    Mods = im.GetKeyMods(ctx)
    MatchedFiles = SearchBar()
    Random_Button_For_Selected_Samples()
    SL()
    RandomButtons(MatchedFiles, 'Add')
    ToolBar()

    Show_AddedSamples (MatchedFiles)


    if SearchTxt~='' or KeyWord[1] then  
        Show_MatchedSamples(MatchedFiles)
    end


    if visible then 
        r.ImGui_End(ctx)
    end
    if open then
        r.defer(Main_Loop)
    end
    FirstLoop = nil
end
r.defer(Main_Loop)
