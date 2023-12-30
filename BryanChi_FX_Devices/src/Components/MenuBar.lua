local MenuBar = {}
------------------------------
------Menu Bar---------------
------------------------------
function MenuBar.DisplayMenuBar()
            r.ImGui_BeginMenuBar(ctx)
            BarR, BarB = r.ImGui_GetItemRectMax(ctx)

            if r.ImGui_BeginMenu(ctx, 'Settings') then
                if select(2, r.ImGui_MenuItem(ctx, 'Style Editor', shoirtcutIn, p_selected, enabledIn)) then
                    OpenStyleEditor = toggle(OpenStyleEditor)
                end

                if select(2, r.ImGui_MenuItem(ctx, 'Keyboard Shortcut Editor', shoirtcutIn, p_selected, enabledIn)) then
                    OpenKBEditor = toggle(OpenKBEditor)
                end
                if r.ImGui_GetWindowDockID(ctx) ~= -1 then
                    if select(2, r.ImGui_MenuItem(ctx, 'Dock script', shoirtcutIn, p_selected, enabledIn)) then
                        Dock_Now = true
                    end
                end
                if select(2, r.ImGui_MenuItem(ctx, "Rescan Plugin List")) then
                    FxdCtx.FX_LIST, FxdCtx.CAT = MakeFXFiles()
                end


                MyText('Version : ' .. VersionNumber, font, 0x777777ff, WrapPosX)
                r.ImGui_EndMenu(ctx)
            end

            if OpenStyleEditor then ShowStyleEditor() end
            if OpenKBEditor then Show_KBShortcutEditor() end
            ------------------------------
            ------Record Last Touch---------------
            ------------------------------

            if r.ImGui_Button(ctx, 'Record Last Touch') then
                --[[ local FX_Count = r.TrackFX_GetCount(LT_Track); local RptPrmFound
                local F = FX[LT_FXGUID] or {}

                if F then
                    for i, v in ipairs(F) do
                        if FX[LT_FXGUID][i].Num == LT_ParamNum then
                            RptPrmFound = true
                            TryingToAddExistingPrm = i .. LT_FXGUID
                            TimeNow = r.time_precise()
                        end
                    end
                    if not RptPrmFound and LT_FXGUID then
                        StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,true)
                    end
                end ]]

                if not IsPrmAlreadyAdded(true) then
                    StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,
                        true)
                end
            end



            if r.ImGui_IsItemClicked(ctx, 1) then Cont_Param_Add_Mode = toggle(Cont_Param_Add_Mode) end


            if r.ImGui_Button(ctx, 'R') then
                r.Undo_BeginBlock()
                r.SetTrackAutomationMode(LT_Track, 0)
                r.Undo_EndBlock('Set track automation mode (Trim/Read)', -1)
            end
            if r.ImGui_Button(ctx, 'T') then
                r.Undo_BeginBlock()
                r.SetTrackAutomationMode(LT_Track, 2)
                r.Undo_EndBlock('Set track automation mode (Touch)', -1)
            end
            if r.ImGui_Button(ctx, 'P') then
                r.Undo_BeginBlock()
                r.SetTrackAutomationMode(LT_Track, 5)
                r.Undo_EndBlock('Set track automation mode (Latch Preview)', -1)
            end




            if FxdCtx.FX.LayEdit then
                local FxGUID = FxdCtx.FX.LayEdit

                if r.ImGui_Button(ctx, 'Grid +') then
                    FxdCtx.LE.GridSize = FxdCtx.LE.GridSize + 5
                elseif r.ImGui_Button(ctx, 'Grid -') then
                    FxdCtx.LE.GridSize = FxdCtx.LE.GridSize - 5
                end

                if #FxdCtx.LE.Sel_Items > 1 then
                    SL()
                    if r.ImGui_Button(ctx, 'Align Y-Axis') then
                        for _, v in ipairs(FxdCtx.LE.Sel_Items) do FxdCtx.FX[FxGUID][v].PosX = FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].PosX end
                    elseif r.ImGui_Button(ctx, 'Align X-Axis') then
                        for _, v in ipairs(FxdCtx.LE.Sel_Items) do FxdCtx.FX[FxGUID][v].PosY = FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].PosY end
                    end
                end
                if #FxdCtx.LE.Sel_Items > 2 then
                    if r.ImGui_Button(ctx, 'Equalize X Spacing') then
                        local Spc, max, min
                        local tab = {}
                        for _, v in ipairs(FxdCtx.LE.Sel_Items) do
                            table.insert(tab, FxdCtx.FX[FxGUID][v].PosX)
                        end

                        max = math.max(table.unpack(tab))
                        min = math.min(table.unpack(tab))
                        Spc = (max - min) / (#FxdCtx.LE.Sel_Items - 1)
                        for i, v in ipairs(FxdCtx.LE.Sel_Items) do
                            FxdCtx.FX[FxGUID][v].PosX = min + Spc * (i - 1)
                        end
                    elseif r.ImGui_Button(ctx, 'Equalize Y Spacing') then
                        local Spc, max, min
                        local tab = {}
                        for _, v in ipairs(FxdCtx.LE.Sel_Items) do
                            table.insert(tab, FxdCtx.FX[FxGUID][v].PosY)
                        end
                        max = math.max(table.unpack(tab))
                        min = math.min(table.unpack(tab))
                        Spc = (max - min) / (#FxdCtx.LE.Sel_Items - 1)
                        for i, v in ipairs(FxdCtx.LE.Sel_Items) do
                            FxdCtx.FX[FxGUID][v].PosY = min + Spc * (i - 1)
                        end
                    end
                end
            else --- only show if not in Layout edit mode
                r.ImGui_Text(ctx, TrkName)
            end
            TxtSz = r.ImGui_CalcTextSize(ctx, TrkName)
            r.ImGui_SameLine(ctx, FxdCtx.VP.w - TxtSz - 20, nil) --r.ImGui_SetCursorPosX( ctx, BarR-50)




            r.ImGui_EndMenuBar(ctx)

end
return MenuBar

