-- EXAMPLE DRAW (NOTHING TO DO WITH PARSING ALL BELOOW)
---@param s string
local function Lead_Trim_ws(s) return s:match '^%s*(.*)' end

---@param filter_text string
local function Filter_actions(filter_text)
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

function FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost)
    ---@type integer|nil, boolean|nil
    local FX_Idx_For_AddFX, close
    if AddLastSPCinRack then FX_Idx_For_AddFX = FX_Idx - 1 end
    local MAX_FX_SIZE = 250
    local FxGUID = FXGUID[FX_Idx_For_AddFX or FX_Idx]
    reaper.ImGui_SetNextItemWidth(ctx, 180)
    _, ADDFX_FILTER = reaper.ImGui_InputTextWithHint(ctx, '##input', "SEARCH FX", ADDFX_FILTER,
        reaper.ImGui_InputTextFlags_AutoSelectAll())

    if reaper.ImGui_IsWindowAppearing(ctx) then
        local tb = FX_LIST
        reaper.ImGui_SetKeyboardFocusHere(ctx, -1)
    end

    local filtered_fx = Filter_actions(ADDFX_FILTER)
    --reaper.ImGui_SetNextWindowPos(ctx, r.ImGui_GetItemRectMin(ctx), ({ r.ImGui_GetItemRectMax(ctx) })[2])
    local filter_h = #filtered_fx == 0 and 2 or (#filtered_fx > 40 and 20 * 17 or (17 * #filtered_fx))
    local function InsertFX(Name)
        local FX_Idx = FX_Idx
        --- CLICK INSERT
        if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end

        reaper.TrackFX_AddByName(LT_Track, Name, false, -1000 - FX_Idx)

        -- if Inserted into Layer
        local FxID = reaper.TrackFX_GetFXGUID(LT_Track, FX_Idx)

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
                reaper.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v,
                    true)
            end
        elseif SpcInPost then
            if reaper.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
            table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
            -- InsertToPost_Src = FX_Idx + offset+2
            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                reaper.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
            end
        end

        ADDFX_FILTER = nil
    end
    if ADDFX_FILTER ~= '' and ADDFX_FILTER then
        SL()
        reaper.ImGui_SetNextWindowSize(ctx, MAX_FX_SIZE, filter_h + 20)
        local x, y = reaper.ImGui_GetCursorScreenPos(ctx)

        ParentWinPos_x, ParentWinPos_y = reaper.ImGui_GetWindowPos(ctx)
        local VP_R = VP.X + VP.w
        if x + MAX_FX_SIZE > VP_R then x = ParentWinPos_x - MAX_FX_SIZE end

        reaper.ImGui_SetNextWindowPos(ctx, x, y - filter_h / 2)
        if reaper.ImGui_BeginPopup(ctx, "##popupp", r.ImGui_WindowFlags_NoFocusOnAppearing() --[[ MAX_FX_SIZE, filter_h ]]) then
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
                elseif filtered_fx[i]:find('VST3:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6) .. '##vst3'
                    local clr = FX_Adder_VST3 or CustomColorsDefault.FX_Adder_VST3
                    MyText('VST3', nil, clr)
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
                elseif filtered_fx[i]:find('LV2:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(5)
                    local clr = FX_Adder_LV2 or CustomColorsDefault.FX_Adder_LV2
                    MyText('LV2', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end

                if reaper.ImGui_Selectable(ctx, (ShownName or filtered_fx[i]) .. '##emptyName', DRAG_FX == i) then
                    if filtered_fx[i] then
                        InsertFX(filtered_fx[i])
                        reaper.ImGui_CloseCurrentPopup(ctx)
                        close = true
                    end
                end
                if i == ADDFX_Sel_Entry then
                    HighlightSelectedItem(0xffffff11, nil, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end
                -- DRAG AND DROP
                if reaper.ImGui_IsItemActive(ctx) and r.ImGui_IsMouseDragging(ctx, 0) then
                    -- HIGHLIGHT DRAGGED FX
                    DRAG_FX = i
                    DndAddFX_SRC(filtered_fx[i])
                    --AddFX_Drag(filtered_fx[i]) -- TODO did this come from FX_ADDER
                end
            end

            if reaper.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) then
                reaper.TrackFX_AddByName(LT_Track, filtered_fx[ADDFX_Sel_Entry], false, -1000 - FX_Idx)
                LAST_USED_FX = filtered_fx[filtered_fx[ADDFX_Sel_Entry]]
                ADDFX_Sel_Entry = nil
                reaper.ImGui_CloseCurrentPopup(ctx)
                close = true

                --FILTER = ''
                --reaper.ImGui_CloseCurrentPopup(ctx)
            elseif reaper.ImGui_IsKeyPressed(ctx, r.ImGui_Key_UpArrow()) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry - 1
            elseif reaper.ImGui_IsKeyPressed(ctx, r.ImGui_Key_DownArrow()) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry + 1
            end
            --reaper.ImGui_EndChild(ctx)
            reaper.ImGui_EndPopup(ctx)
        end


        reaper.ImGui_OpenPopup(ctx, "##popupp")
        reaper.ImGui_NewLine(ctx)
    end


    if reaper.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
        reaper.ImGui_CloseCurrentPopup(ctx)
        ADDFX_FILTER = nil
    end
    return close
end
