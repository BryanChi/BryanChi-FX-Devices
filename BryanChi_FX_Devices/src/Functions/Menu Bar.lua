
function StoreSettings()
    local data = tableToString(
        {
            reverse_scroll = Reverse_Scroll,
            ctrl_scroll = Ctrl_Scroll,
            proc_gr_native = ProC.GR_NATIVE,
            proq_analyzer = ProQ.Analyzer,
            USE_MOD_CONTROL_POPUP = USE_MOD_CONTROL_POPUP
            --use_systemfont = Use_SystemFont
        }
    )
    r.SetExtState("FXDEVICES", "Settings", data, true)
end

function If_Theres_Selected_FX()
    local Sel_FX = TrkID and Trk[TrkID] and  Trk[TrkID].Sel_FX
    if Sel_FX and Sel_FX[1] then  
        Sel_FxGUID = {}
        table.sort(Sel_FX)
        local function Put_FXs_Into_Container()
        
            if im.Button(ctx, 'Put FXs into Container') then 
                for i, v in ipairs(Sel_FX) do 
                    local v = Find_FxID_By_GUID (v)
                    local _, Name = r.TrackFX_GetFXName(LT_Track, v )
                    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, v)
                    table.insert(Sel_FxGUID, FxGUID)
                end
                local firstSlot =  Find_FxID_By_GUID (Sel_FX[1])

                local cont = AddFX_HideWindow(LT_Track, 'Container', -1000 - firstSlot)
                local ContFxGUID = r.TrackFX_GetFXGUID(LT_Track, cont)
                TREE = BuildFXTree(LT_Track)

                for i, v in ipairs(Sel_FX) do 
                    local cont = Find_FxID_By_GUID (ContFxGUID)
                    local id = Find_FxID_By_GUID (v)

                    --[[ if cont <= v then v = v + 1 end ]]
                    Put_FXs_Into_New_Container(id, cont, i )
                end
                Sel_FX = nil 
                Sel_FxGUID= nil
            end 
        end

        local function Put_FXs_Into_Parallel_Chain()
            if Sel_FX and Sel_FX[2] then 
                if im.Button(ctx, 'Put FXs into Parallel') then 

                    for i, v in ipairs(Sel_FX) do 
                        if i ~= 1 then 
                            local idx = Find_FxID_By_GUID (v)
                            r.TrackFX_SetNamedConfigParm(LT_Track, idx, 'parallel', '1')
                            
                        end
                    end
                    Sel_FX = {}
                end
            end
        end






        Put_FXs_Into_Container()
        Put_FXs_Into_Parallel_Chain()



    end
end

function Settings()

    if im.BeginMenu(ctx, 'Settings') then
        if select(2, im.MenuItem(ctx, 'Style Editor', shoirtcutIn, p_selected, enabledIn)) then
            OpenStyleEditor = toggle(OpenStyleEditor)
        end

        if select(2, im.MenuItem(ctx, 'Keyboard Shortcut Editor', shoirtcutIn, p_selected, enabledIn)) then
            OpenKBEditor = toggle(OpenKBEditor)
        end
        if im.GetWindowDockID(ctx) ~= -1 then
            if select(2, im.MenuItem(ctx, 'Dock script', shoirtcutIn, p_selected, enabledIn)) then
                Dock_Now = true
            end
        end
        if im.BeginMenu(ctx, "General Behavior") then
            _, Reverse_Scroll = im.Checkbox(ctx, "Reverse Scroll", Reverse_Scroll)
            SL()
            QuestionHelpObject('Make horizontal scroll behavior reversed', im.HoveredFlags_Stationary)
            _, Ctrl_Scroll = im.Checkbox(ctx, "Ctrl Scroll", Ctrl_Scroll)
            SL()
            QuestionHelpObject('Use ctrl + scroll to scroll horizontally and scroll to adjust parameters.',
                im.HoveredFlags_Stationary)
            _, ProC.GR_NATIVE = im.Checkbox(ctx, 'Use Native Gain Reduction for Pro-C', ProC.GR_NATIVE)
            _, ProQ.Analyzer = im.Checkbox(ctx, 'Use analyzer for Pro-Q', ProQ.Analyzer)
            --_, Use_SystemFont = im.Checkbox(ctx, 'Use System Font', Use_SystemFont)
            _, USE_MOD_CONTROL_POPUP = im.Checkbox(ctx, 'Modulation Control Popup on Mouse Hover', USE_MOD_CONTROL_POPUP)
            StoreSettings()
            im.EndMenu(ctx)
        end
        if select(2, im.MenuItem(ctx, "Rescan Plugin List")) then
            FX_LIST, CAT = MakeFXFiles()
        end

        MyText('Version : ' .. VersionNumber, font, 0x777777ff, WrapPosX)
        im.EndMenu(ctx)
    end

    if OpenStyleEditor then OpenStyleEditor = ShowStyleEditor(OpenStyleEditor) end
    if OpenKBEditor then OpenKBEditor =  Show_KBShortcutEditor(OpenKBEditor) end     
end   


function Record_Last_Touch_Btn()

    if im.ImageButton(ctx, 'Record Last Touch', Img.AddList , 20, 20, 0 , 0.2, nil, nil, nil, RecordLT_CLR) then
        if not IsPrmAlreadyAdded(true) then
            StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum, true)
        end
    end

    if im.IsItemClicked(ctx, 1) then Cont_Param_Add_Mode = toggle(Cont_Param_Add_Mode) end

    if Cont_Param_Add_Mode == true then
        --TimeAfter_ContAdd= TimeAfter_ContAdd+1
        RecordLT_CLR =   BlinkItem(0.3, nil, ThemeClr("Accent_Clr") , nil, true, nil, nil,nil,nil,nil,nil,0xffffff33)   


        GetLT_FX_Num()
        GetLTParam()
        tooltip('Continuously Adding Last Touched Parameters..')

        local F = FX[LT_FXGUID] or {}; local RptPrmFound
        if LT_FXGUID and type(F) == 'table' then
            for i, v in ipairs(F) do
                F[i] = F[i] or {}
                if F[i].Num == LT_ParamNum then
                    RptPrmFound = true
                    TryingToAddExistingPrm_Cont = i .. LT_FXGUID; TryingToAddExistingPrm = nil
                    TimeNow = r.time_precise()
                end
            end
            if not RptPrmFound then
                StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,
                    true)
            end
        end
    else
        TryingToAddExistingPrm_Cont = nil
    end


     -- if action to record last touch is triggered
     if r.GetExtState('FXD', 'Record last touch') ~= '' then
        if not IsPrmAlreadyAdded(true) then
            StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum, true)
        end
        r.SetExtState('FXD', 'Record last touch', '', false)
    end
end 

function Envelope_Btn()

    local drawlist = im.GetWindowDrawList(ctx)
    local env_color = GetEnvelopeColor(LT_Track)
    local rv = HoverHighlightButton(0x00, "##Automation", 20, 20)
    DrawListButton(drawlist, "E", env_color, false, true, icon1_middle)
    ChangeAutomationModeByWheel(LT_Track)
    if rv then
        AutomationMode = { "Trim/Read", "Read", "Touch", "Write", "Latch", "Latch Preview" }
        im.OpenPopup(ctx, 'automation_popup')
    end


    if im.BeginPopup(ctx, 'automation_popup') then
        for k, v in ipairs(AutomationMode) do
            if im.Selectable(ctx, v) then
                r.SetTrackAutomationMode(LT_Track, k - 1)
            end
        end
        im.EndPopup(ctx)
    end
end 



function Layout_Edit_MenuBar_Buttons()


    if not FX.LayEdit then return end 
    local FxGUID = FX.LayEdit

    local function Grid_Adjust_Btns()
        if im.Button(ctx, 'Grid +') then
            LE.GridSize = LE.GridSize + 5
        elseif im.Button(ctx, 'Grid -') then
            LE.GridSize = LE.GridSize - 5
        end
    end
    local function Swap_Btns()
        if #LE.Sel_Items == 2 then
            if im.Button(ctx, 'Swap Positions') then
                Create_Undo_Point('Swap Positions', FxGUID)
                FX[FxGUID][LE.Sel_Items[1]].PosX, FX[FxGUID][LE.Sel_Items[2]].PosX = FX[FxGUID][LE.Sel_Items[2]].PosX, FX[FxGUID][LE.Sel_Items[1]].PosX
                FX[FxGUID][LE.Sel_Items[1]].PosY, FX[FxGUID][LE.Sel_Items[2]].PosY = FX[FxGUID][LE.Sel_Items[2]].PosY, FX[FxGUID][LE.Sel_Items[1]].PosY
            end
        end
    end
    local function Align_Btns()

        if #LE.Sel_Items > 1 then
            SL()
            im.Text(ctx, 'Align :')
            SL()


            if im.Button(ctx, 'Left') then
                Create_Undo_Point('Align Left', FxGUID)
                Align(LE.Sel_Items, FX[FxGUID], 'PosX', 'Min')
            end
            if im.Button(ctx, 'Top') then
                Create_Undo_Point('Align Top', FxGUID)
                Align(LE.Sel_Items, FX[FxGUID], 'PosY', 'Min')
            end
            if im.Button(ctx, 'Right') then
                Create_Undo_Point('Align Right', FxGUID)
                Align(LE.Sel_Items, FX[FxGUID], 'PosX', 'Max')
            end
            if im.Button(ctx, 'Bottom') then
                Create_Undo_Point('Align Bottom', FxGUID)
                Align(LE.Sel_Items, FX[FxGUID], 'PosY', 'Max')
            end
            im.Separator(ctx)

        end
    end
    local function Equalize_Btns()
        if #LE.Sel_Items > 2 then
            im.Text(ctx,'Equalize :')
            SL()
            if im.Button(ctx,'X Spacing') then
                Create_Undo_Point('Equalize X Spacing', FxGUID)
                Equalize_Spacing(LE.Sel_Items, FX[FxGUID], 'PosX')
            elseif im.Button(ctx, 'Y Spacing') then
                Create_Undo_Point('Equalize Y Spacing', FxGUID)
                Equalize_Spacing(LE.Sel_Items, FX[FxGUID], 'PosY')
            end
        end
    end

    
    Grid_Adjust_Btns()
    Align_Btns()
    Equalize_Btns()
    Swap_Btns()

    im.Separator(ctx)

end 
    
function Equalize_Spacing(Sel_Itms, TB, index)
    local tb = {}
    for i, v in ipairs(Sel_Itms) do 
        table.insert(tb, TB[v][index])
    end
    local min = math.min(table.unpack(tb))
    local max = math.max(table.unpack(tb))
    local Spc = (max - min) / (#Sel_Itms - 1)
    for i, v in ipairs(Sel_Itms) do TB[v][index] = min + Spc * (i - 1) end
end

function Align(Sel_Itms, TB, index, Min_or_Max)
    local tb = {}
    for i, v in ipairs(Sel_Itms) do 
        table.insert(tb, TB[v][index])
    end
    local min = math.min(table.unpack(tb))
    local max = math.max(table.unpack(tb))
    for i, v in ipairs(Sel_Itms) do
        if Min_or_Max == 'Max' then
            TB[v][index] = max
        elseif Min_or_Max == 'Min' then
            TB[v][index] = min
        end
    end
end

function Backrgound_Edit_MenuBar_Buttons()
    if not Draw.DrawMode then return end 
    local FxGUID = Draw.DrawMode
    if not FX[FxGUID] then return end
    --local Draw = FX[FxGUID].Draw
    Draw.SelItms = Draw.SelItms or {}
    if #Draw.SelItms >1 then 
        local D = FX[FxGUID].Draw

        local function Preview(preview_str, func, ...)
            if im.IsItemHovered(ctx) then 
                if not FX[FxGUID].Draw.Preview then
                    FX[FxGUID].Draw.Preview = deepCopy(FX[FxGUID].Draw)
                else 
                    func(...)
                    Draw.Preview = preview_str
                    tooltip('Previewing ' .. preview_str)
                    
                end
            else 

                if preview_str == Draw.Preview then 
                    FX[FxGUID].Draw.Preview= nil 
                    Draw.Preview = nil 
                end
            end
        end

        im.Text(ctx,'Equalize :')
        SL()
        if im.Button(ctx, 'X Spacing') then
            Create_Undo_Point( 'Equalize X Spacing' , FxGUID)
            Equalize_Spacing(Draw.SelItms, D, 'L')
        end    
        Preview('Equalize X Spacing', Equalize_Spacing, Draw.SelItms, FX[FxGUID].Draw.Preview, 'L')

        if im.Button(ctx, 'Y Spacing') then
            Create_Undo_Point( 'Equalize Y Spacing' , FxGUID)
            Equalize_Spacing(Draw.SelItms, D, 'T')
        end
        Preview('Equalize Y Spacing', Equalize_Spacing, Draw.SelItms, FX[FxGUID].Draw.Preview, 'T')

        im.Separator(ctx)
        im.Text(ctx,'Align :')
        SL()

        if im.Button(ctx, 'Top') then
            Create_Undo_Point( 'Align Top' , FxGUID)
            Align(Draw.SelItms, D, 'T', 'Min')
        end
        Preview('Align Top', Align, Draw.SelItms, FX[FxGUID].Draw.Preview, 'T', 'Min')
    
        if im.Button(ctx, 'Left') then
            Create_Undo_Point( 'Align Left' , FxGUID)   
            Align(Draw.SelItms, D, 'L', 'Min')
        end
        Preview('Align Left', Align, Draw.SelItms, FX[FxGUID].Draw.Preview, 'L', 'Min')

        if im.Button(ctx , 'Right') then
            Create_Undo_Point( 'Align Right' , FxGUID)
            Align(Draw.SelItms, D, 'L', 'Max')
        end
        Preview('Align Right', Align, Draw.SelItms, FX[FxGUID].Draw.Preview, 'L', 'Max')

        if im.Button(ctx, 'Bottom') then
            Create_Undo_Point( 'Align Bottom' , FxGUID)
            Align(Draw.SelItms, D, 'T', 'Max')
        end
        Preview('Align Bottom', Align, Draw.SelItms, FX[FxGUID].Draw.Preview, 'T', 'Max')
        im.Separator(ctx)
        
        if #Draw.SelItms == 2 then
            if im.Button(ctx, 'Swap Positions') then
                Create_Undo_Point('Swap Positions', FxGUID)
                D[Draw.SelItms[1]].L, D[Draw.SelItms[2]].L = D[Draw.SelItms[2]].L, D[Draw.SelItms[1]].L
                D[Draw.SelItms[1]].T, D[Draw.SelItms[2]].T = D[Draw.SelItms[2]].T, D[Draw.SelItms[1]].T
            end
        end

        
    end
    if #Draw.SelItms > 0 then
        if im.Button(ctx, 'Deselect All') then 
            Draw.SelItms = {}
        end
    end
end

function ShowTrackName(Condition)
    if Condition then 
        im.Text(ctx, TrkName)
    end
end 

function LayEdit_and_Backrgound_Edit_Undo_Button()
    if Draw.DrawMode or FX.LayEdit then
        LE.Undo_Points = LE.Undo_Points or {}
        if #LE.Undo_Points > 0 then
            if im.Button(ctx, ( 'Undo ' .. LE.Undo_Points[#LE.Undo_Points].Undo_Pt_Name)) then

                    FX[FX.LayEdit] = deepCopy (LE.Undo_Points[#LE.Undo_Points])
                    table.remove(LE.Undo_Points, #LE.Undo_Points)

            end
        end
    end
end




local function Modulation_Btn()
    local y = im.GetCursorPosY(ctx)
    im.SetCursorPosY(ctx, y + 3)
    local ModIconSz = 20
    if not TrkID then return end 
    Trk[TrkID] = Trk[TrkID] or {}
    local clr =  Trk[TrkID].ShowMOD and ThemeClr('Accent_Clr') or 0xffffffff

    im.PushStyleColor(ctx, im.Col_Button, 0x00000000)


    if im.ImageButton(ctx, '##', Img.ModIconHollow, ModIconSz , ModIconSz*0.46, nil, nil, nil, nil, 0x00000000, clr) then 
        Trk[TrkID].ShowMOD= toggle( Trk[TrkID].ShowMOD)
        AddMacroJSFX()
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Show Modulations' ,'true', true)
    end
    im.PopStyleColor(ctx)
    im.SetCursorPosY(ctx, y)



end
function MenuBar ()

    im.BeginMenuBar(ctx)
    im.PushStyleColor(ctx, im.Col_Button, 0x00000033)
    im.PushStyleColor(ctx, im.Col_Border, ThemeClr('Accent_Clr_Dark'))

    im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 4)
    im.PushStyleVar(ctx, im.StyleVar_FrameBorderSize, 2)
    LayEdit_and_Backrgound_Edit_Undo_Button()

    Layout_Edit_MenuBar_Buttons()
    Backrgound_Edit_MenuBar_Buttons()
    im.PopStyleVar(ctx,2)
    im.PopStyleColor(ctx,2)
    Record_Last_Touch_Btn()
    Modulation_Btn()
    Envelope_Btn()

    If_Theres_Selected_FX()
    im.Separator(ctx)
    SL()


    ShowTrackName(not FX.LayEdit)

    SL(VP.w - 100)
    Settings()
    SL(nil, 40)
    im.EndMenuBar(ctx)
end 