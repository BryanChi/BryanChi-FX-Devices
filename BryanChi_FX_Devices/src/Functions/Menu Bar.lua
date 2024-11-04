
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
            if Sel_FX[2] then 
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


    if FX.LayEdit then
        local FxGUID = FX.LayEdit

        if im.Button(ctx, 'Grid +') then
            LE.GridSize = LE.GridSize + 5
        elseif im.Button(ctx, 'Grid -') then
            LE.GridSize = LE.GridSize - 5
        end

        if #LE.Sel_Items > 1 then
            SL()
            if im.Button(ctx, 'Align Y-Axis') then
                for i, v in ipairs(LE.Sel_Items) do FX[FxGUID][v].PosX = FX[FxGUID][LE.Sel_Items[1]].PosX end
            elseif im.Button(ctx, 'Align X-Axis') then
                for i, v in ipairs(LE.Sel_Items) do FX[FxGUID][v].PosY = FX[FxGUID][LE.Sel_Items[1]].PosY end
            end
        end
        if #LE.Sel_Items > 2 then
            if im.Button(ctx, 'Equalize X Spacing') then
                local Spc, max, min
                local tab = {}
                for i, v in ipairs(LE.Sel_Items) do
                    table.insert(tab, FX[FxGUID][v].PosX)
                end

                max = math.max(table.unpack(tab))
                min = math.min(table.unpack(tab))
                Spc = (max - min) / (#LE.Sel_Items - 1)
                for i, v in ipairs(LE.Sel_Items) do
                    FX[FxGUID][v].PosX = min + Spc * (i - 1)
                end
            elseif im.Button(ctx, 'Equalize Y Spacing') then
                local Spc, max, min
                local tab = {}
                for i, v in ipairs(LE.Sel_Items) do
                    table.insert(tab, FX[FxGUID][v].PosY)
                end
                max = math.max(table.unpack(tab))
                min = math.min(table.unpack(tab))
                Spc = (max - min) / (#LE.Sel_Items - 1)
                for i, v in ipairs(LE.Sel_Items) do
                    FX[FxGUID][v].PosY = min + Spc * (i - 1)
                end
            end
        end
        im.Separator(ctx)
    end
end 


function ShowTrackName(Condition)
    if Condition then 
        im.Text(ctx, TrkName)
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
    Layout_Edit_MenuBar_Buttons()
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