-- @noindex

------------- Buttons/Knobs -------------
function InvisiBtn(ctx, x, y, str, w, h)
    if x and y then
        im.SetCursorScreenPos(ctx, x, y)
    end
    local rv = im.InvisibleButton(ctx, str, w, h or w)
    return rv
end
function Container_CollapseIfTab(FxGUID, FX_Idx)
    if r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_ChildWindows()) then 

        local _ , name = r.TrackFX_GetNamedConfigParm(LT_Track,FX_Idx,'original_name')
        if name == 'Container' and not Tab_Collapse_Win then 
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Tab())  then
                if FX[FxGUID].Cont_Collapse == 0 then FX[FxGUID].Cont_Collapse= 1
                elseif FX[FxGUID].Cont_Collapse==1 then FX[FxGUID].Cont_Collapse= 0 end 
                Tab_Collapse_Win = true 
                NeedRetrieveLayout = true 
            end
        end
    end

end
function Cross_Out( clr, thick , DL )
    local WDL = DL or WDL 
    local clr = clr or 0xD30000ff
    local thick = thick or 2 
    local l, t = im.GetItemRectMin(ctx)
    local r, b = im.GetItemRectMax(ctx)
    im.DrawList_AddLine(WDL, l, t, r, b ,clr, thick)
    im.DrawList_AddLine(WDL, r,t,l ,b ,clr, thick)


end


function Button_Color_Change(trigger, color )
    if trigger then
        local Clr = color or CustomColorsDefault[color]
        local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
        im.PushStyleColor(ctx, im.Col_Button, Clr)
        im.PushStyleColor(ctx, im.Col_ButtonActive, Act)
        im.PushStyleColor(ctx, im.Col_ButtonHovered, Hvr)
        return 3 
    end

end


function Draw_A_Cursor_Shape( x, y, scale, col, angle )
    local function rotatePoint(x, y, center_x, center_y, theta)
        local cos_theta = math.cos(theta)
        local sin_theta = math.sin(theta)
    
        -- Translate the point relative to the center
        local translated_x = x - center_x
        local translated_y = y - center_y
    
        -- Perform the rotation
        local rotated_x = translated_x * cos_theta - translated_y * sin_theta
        local rotated_y = translated_x * sin_theta + translated_y * cos_theta
    
        -- Translate the point back to the original position
        return rotated_x + center_x, rotated_y + center_y
    end

    local  tx = x    ;
    local  ty = y -2.5 * scale ;
    local  rbx = x + 2 * scale ;
    local  rby = y + 3 * scale;
    local  bx = x ;
    local  by = y + 2 * scale;
    local  lbx = x - 2 * scale ;
    local  lby = y + 3 * scale ;
    local WDL = im.GetForegroundDrawList(ctx)

     -- Rotate each point around the center (x, y) by theta
    local tx, ty = rotatePoint(tx, ty, x, y, angle)
    local rbx, rby = rotatePoint(rbx, rby, x, y, angle)
    local bx, by = rotatePoint(bx, by, x, y, angle)
    local lbx, lby = rotatePoint(lbx, lby, x, y, angle)

    im.DrawList_PathLineTo(WDL, tx, ty)
    im.DrawList_PathLineTo(WDL, rbx, rby)
    im.DrawList_PathLineTo(WDL, bx, by)
    im.DrawList_PathLineTo(WDL, lbx, lby)


    im.DrawList_PathFillConvex(WDL, col)


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

function Show_Tooltip_For_Duration(text, duration )
    if text then 
        Tooltip.time =( Tooltip.time or 0) + 1 

        local time = Tooltip.time
        if time < duration then 

            tooltip(text, Tooltip.clr)
        elseif time > duration then
            Tooltip.Txt = nil 
            Tooltip.Dur = nil 
        end
    end
end

function RemoveFXfromBS()
    for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do -- check all fxs and see if it's a band splitter
        if FX[FXGUID[FX_Idx]].FXsInBS then
            local FxID = tablefind(FX[FXGUID[FX_Idx]].FXsInBS, FXGUID[DragFX_ID])
            if FxID then
                table.remove(FX[FXGUID[FX_Idx]].FXsInBS, FxID)
                FX[FXGUID[DragFX_ID]].InWhichBand = nil
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID], '', true)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FXGUID[DragFX_ID], '', true)
            end
        end
    end
end
function Pre_FX_Chain(FX_Idx)
    if not FX_Idx then return end 
  ------- Pre FX Chain --------------
    local FXisInPreChain, offset = nil, 0
    if MacroPos == 0 then offset = 1 end --else offset = 0
    if Trk[TrkID].PreFX[1] then
        if Trk[TrkID].PreFX[FX_Idx + 1 - offset] == FXGUID[FX_Idx] then
            FXisInPreChain = true
        end
    end

    if Trk[TrkID].PreFX[1] and not Trk[TrkID].PreFX_Hide and FX_Idx == #Trk[TrkID].PreFX - 1 + offset then
        AddSpaceBtwnFXs(FX_Idx, 'End of PreFX', nil)
    end

    if FXisInPreChain then
        if FX_Idx + 1 - offset == #Trk[TrkID].PreFX and not Trk[TrkID].PreFX_Hide then
            local R, B = im.GetItemRectMax(ctx)
            im.DrawList_AddRect(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B,
                im.GetColor(ctx, im.Col_Button))
            im.DrawList_AddRectFilled(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B, 0xcccccc10)
        end
    end
    ------------------------------------------
    if FX_Idx + 1 == RepeatTimeForWindows and not Trk[TrkID].PostFX[1] then -- add last space
        AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc')
    elseif FX_Idx + 1 == RepeatTimeForWindows and Trk[TrkID].PostFX[1] then
        AddSpaceBtwnFXs(Sel_Track_FX_Count - #Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
    end
end


function HoverHighlightButton(color, label, size_w, size_y)
    im.PushStyleColor(ctx, im.Col_Button, color)
    im.PushStyleColor(ctx, im.Col_ButtonHovered, 0x9999993c)
    im.PushStyleColor(ctx, im.Col_ButtonActive, 0x99999912)
    local rv = im.Button(ctx, label, size_w, size_y)
    im.PopStyleColor(ctx, 3)
    return rv
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
        FX[FxGUID].DeltaP   = FX[FxGUID].DeltaP or r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':delta')

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
            lineClr = ClrOverRide or im.GetColor(ctx, im.Col_SliderGrab)
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
        elseif FX[FxGUID].DeltaP_V == 1 then 
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
        if is_hovered then 
            HelperMsg.Alt_R = 'Delta-Solo' 
            HelperMsg.Need_Add_Mouse_Icon = 'R'
        end

        return ActiveAny, value_changed, p_value
    end
end

function AddWindowBtn(FxGUID, FX_Idx, width, CantCollapse, CantAddPrm, isContainer, NoVert)
    if FX[FxGUID] then
        local fx = FX[FxGUID]
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



        if (not fx.Collapse and not fx.V_Win_Btn_Height or isContainer) or NoVert then
            if not fx.NoWindowBtn then
                local Name = (fx.CustomTitle or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) .. '## ')
                if DebugMode then Name = FxGUID end
                WindowBtn = im.Button(ctx, Name .. '## ' .. FxGUID,
                    (width or fx.TitleWidth or DefaultWidth or Default_WindowBtnWidth)  - 38, 20) -- create window name button


                if im.IsItemHovered(ctx) and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                    fx.TtlHvr = true
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
                    fx.TtlHvr = nil
                end
            end
        elseif (fx.V_Win_Btn_Height and not fx.Collapse) then
            local Name = (fx.CustomTitle or FX.Win_Name_S[FX_Idx] or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) .. '## ')
            local Name_V_NoManuFacturer = Vertical_FX_Name(Name)
            -- im.PushStyleVar(ctx, BtnTxtAlign, 0.5, 0.2) --StyleVar#3
            --im.SameLine(ctx, nil, 0)
            WindowBtn = im.Button(ctx, Name_V_NoManuFacturer .. '##' .. FxGUID, 25, fx.V_Win_Btn_Height)

            -- im.PopStyleVar(ctx)             --StyleVar#3 POP
        else -- if collapsed
            --[[ fx.Width_Collapse= 27 ]]
            local Name = (fx.CustomTitle or FX.Win_Name_S[FX_Idx] or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) .. '## ')
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
            BgClr = 0x00000088
        end
        HighlightSelectedItem(BgClr, 0xffffff11, -1, L, T, R, B, h, w, 1, 1, 'GetItemRect', WDL, fx.Round --[[rounding]])

        -- im.SetNextWindowSizeConstraints(ctx, AddPrmWin_W or 50, 50, 9999, 500)
        local R_ClickOnWindowBtn = im.IsItemClicked(ctx, 1)
        local L_ClickOnWindowBtn = im.IsItemClicked(ctx)

        if not CantCollapse then
            if R_ClickOnWindowBtn and Mods == Ctrl then
                im.OpenPopup(ctx, 'Fx Module Menu')
            elseif R_ClickOnWindowBtn and Mods == 0 then
                fx.Collapse = toggle(fx.Collapse)
                
                if not fx.Collapse then fx.Width_Collapse= nil end
                Animate_FX_Width= toggle(Animate_FX_Width , FxGUID)
                Anim_Time = 0
            elseif R_ClickOnWindowBtn and Mods == Alt then
                -- check if all are collapsed
                BlinkFX = ToggleCollapseAll(FX_Idx)
            end
        end
        if Animate_FX_Width==FxGUID then 
            
            if fx.Collapse then  -- if user is collapsing 

                fx.Width_Before_Collapse = fx.Width_Before_Collapse or  fx.Width
                fx.Width, Anim_Time, fx.AnimComplete = Anim_Update( 0.1, 0.8,  fx.Width or  DefaultWidth , COLLAPSED_FX_WIDTH, Anim_Time)

                if fx.AnimComplete  then 

                    Animate_FX_Width = nil 
                    Anim_Time=nil
                end
            else        --- if uncollapsing

                fx.Width,Anim_Time, fx.AnimComplete = Anim_Update( 0.1, 0.8, COLLAPSED_FX_WIDTH, fx.Width_Before_Collapse  or  DefaultWidth, Anim_Time)

                if fx.AnimComplete then 
                    Animate_FX_Width = nil 
                    fx.Width_Before_Collapse = nil 
                    Anim_Time=nil
                end 
            end
        end

        if FX.LayEdit ~=FxGUID then 
            
            if WindowBtn and Mods == 0 then
               
                openFXwindow(LT_Track, FX_Idx)
            elseif WindowBtn and Mods == Shift then
                ToggleBypassFX(LT_Track, FX_Idx)
            elseif WindowBtn and Mods == Alt then
                DeleteFX(FX_Idx, FxGUID)
            end
        end

        if im.IsItemHovered(ctx) then
            HelperMsg.L = 'Open FX Window'
            HelperMsg.R = 'Collapse'
            HelperMsg.Shift_L = 'Toggle Bypass'
            HelperMsg.Alt_L = 'Delete'
            HelperMsg.Alt_R = 'Collapse All'
            HelperMsg.Ctrl_R = 'Open Menu'
            HelperMsg.Need_separator = true 
        end


        ----==  Drag and drop----
        if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect|im.DragDropFlags_AcceptNoPreviewTooltip) then
            DragFX_ID = FX_Idx
            DragFxGuid = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            im.SetDragDropPayload(ctx, 'FX_Drag', FX_Idx)
            im.EndDragDropSource(ctx)
            Show_Drag_FX_Preview_Tooltip(FxGUID, FX_Idx)

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

        -- Add Prm popup
        if im.BeginPopup(ctx, 'Add Parameter' .. FxGUID, im.WindowFlags_AlwaysVerticalScrollbar) then
            local CheckBox, rv = {}, {}
            if im.Button(ctx, 'Add all parameters', -1) then
                for i = 0, r.TrackFX_GetNumParams(LT_Track, FX_Idx) - 1, 1 do
                    local P_Name = select(2, r.TrackFX_GetParamName(LT_Track, FX_Idx, i))

                    if not fx[i + 1] then
                        StoreNewParam(FxGUID, P_Name, i, FX_Idx, true)
                    else
                        local RptPrmFound
                        for I = 1, #fx, 1 do
                            if fx[I].Num == i then RptPrmFound = true end
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

            if not fx.NotFirstOpenPrmWin then
                im.SetKeyboardFocusHere(ctx, offsetIn)
            end

            if im.TextFilter_Draw(PrmFilter, ctx, '##PrmFilterTxt', -1 - (SpaceForBtn or 0)) then
                PrmFilterTxt = im.TextFilter_Get(PrmFilter)
                im.TextFilter_Set(PrmFilter, PrmFilterTxt)
            end

            for i = 1, Ct, 1 do
                if fx[i] and fx[i].Num  then
                    CheckBox[fx[i].Num] = true
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
                            if fx[I] then
                                if fx[I].Num == i - 1 then RepeatPrmFound = I end
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
            fx.NotFirstOpenPrmWin = true
            im.EndPopup(ctx)
        elseif AddPrmPopupOpen == FxGUID then
            PrmFilterTxt = nil
            fx.NotFirstOpenPrmWin = nil
        end
        

        if im.BeginPopup(ctx, 'Fx Module Menu') then
            if not fx.MorphA then
                if im.Button(ctx, 'Preset Morphing', 160) then
                    fx.MorphA = {}
                    fx.MorphB = {}
                    local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                    for i = 0, PrmCount - 4, 1 do
                        local Prm_Val, minval, maxval = r.TrackFX_GetParamNormalized(
                            LT_Track, FX_Idx, i)
                        fx.MorphA[i] = Prm_Val
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX Morph A' .. i .. FxGUID, Prm_Val, true)
                    end
                    RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track, PrmCount)
                    --[[ r.SetProjExtState(r0oj, 'FX Devices', string key, string value) ]]
                    fx.MorphHide = nil
                    im.CloseCurrentPopup(ctx)
                end
            else
                if not fx.MorphHide then
                    if im.Button(ctx, 'Hide Morph Slider', 160) then
                        fx.MorphHide = true
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX Morph Hide' .. FxGUID, 'true', true)
                        im.CloseCurrentPopup(ctx)
                    end
                else
                    if im.Button(ctx, 'Show Morph Slider', 160) then
                        fx.MorphHide = nil
                        im.CloseCurrentPopup(ctx)
                    end
                end
            end

            im.SameLine(ctx)
            if not fx.MorphA then
               
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
                fx.PrmList = fx.PrmList or {}
                for i = 0, Ct - 4, 1 do --get param names
                    fx.PrmList[i]      = fx.PrmList[i] or {}
                    local rv, name             = r.TrackFX_GetParamName(LT_Track,
                        FX_Idx, i)
                    fx.PrmList[i].Name = name
                end
                im.CloseCurrentPopup(ctx)
            end
            if not fx.MorphA then
                im.EndDisabled(ctx)
                im.PopStyleColor(ctx)
            end

            if im.Button(ctx, 'Parallel With Previous FX', -FLT_MIN) then 
                r.TrackFX_SetNamedConfigParm(LT_Track,FX_Idx, 'parallel', '1')
                im.CloseCurrentPopup(ctx)
            
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

    end

end

------------- Primitives -------------
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

------------- Color -------------
---@param f integer
---@return integer
function getClr(f)
    return im.GetStyleColor(ctx, f)
end

---@param ctx ImGui_Context
---@param time integer count in
function PopClr(ctx, time)
    im.PopStyleColor(ctx, time)
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

function GetEnvelopeColor(track)
    local automation_mode = r.GetTrackAutomationMode(track)
    local global_automation = r.GetGlobalAutomationOverride(track)
    if global_automation == -1 then
      if automation_mode == 0 then -- Trim/Read
        env_color = 0x00
      elseif automation_mode == 1 then -- Read
        env_color = 0x00f529ff
      elseif automation_mode == 2 then -- Touch
        env_color = 0xffff00ff
      elseif automation_mode == 3 then -- Write 
        env_color = 0xeb1c24ff
      elseif automation_mode == 4 then -- Latch
        env_color = 0xba85faff
      elseif automation_mode == 5 then -- Latch Preview
        env_color = 0x0467ffff
      end
    elseif global_automation == 0 then -- Trim/Read
      env_color = 0x00
    elseif global_automation == 1 then -- Read
      env_color = 0x00f529ff
    elseif global_automation == 2 then -- Touch
      env_color = 0xffff00ff
    elseif global_automation == 3 then -- Write 
      env_color = 0xeb1c24ff
    elseif global_automation == 4 then -- Latch
      env_color = 0xba85faff
    elseif global_automation == 5 then -- Latch Preview
      env_color = 0x0467ffff
    elseif global_automation == 6 then -- Bypass
      env_color = 0xffffffff
    end
    return env_color
end

------------- Text/Tooltips -------------
---@param text string
---@param font? ImGui_Font
---@param color? number rgba
---@param WrapPosX? number
function MyText(text, font, color, WrapPosX, center)
    if WrapPosX then im.PushTextWrapPos(ctx, WrapPosX) end

   
    if font then im.PushFont(ctx, font) end
    if center then 
        local W, h = im.CalcTextSize(ctx, text, nil, nil, true)
        local X = im.GetCursorPosX(ctx)
        im.SetCursorPosX(ctx ,X - W /2)
    
    end
    if color then
        im.TextColored(ctx, color, text)
    else
        im.Text(ctx, text)
    end

    if font then im.PopFont(ctx) end
    if WrapPosX then im.PopTextWrapPos(ctx) end
end

---TODO remove this duplicate of tooltip()
---@param A string text for tooltip
function tooltip(A, clr)
    im.BeginTooltip(ctx)
    if clr then 
        im.PushStyleColor(ctx, im.Col_Text, clr)
    end
    im.SetTooltip(ctx, A)
    if clr then 
        im.PopStyleColor(ctx)
    end
    im.EndTooltip(ctx)
end

---@param A string text for tooltip
function ttp(A)
    im.BeginTooltip(ctx)
    im.SetTooltip(ctx, A)
    im.EndTooltip(ctx)
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

---------- Highlight --------------
function Highlight_Itm(WDL, FillClr, OutlineClr, rounding, padding)
    local L, T = im.GetItemRectMin(ctx);
    local R, B = im.GetItemRectMax(ctx);
    if padding then 
        local p = padding/2
        L=L-p
        T=T-p
        R=R+p
        B=B+p
    end 
    if FillClr then im.DrawList_AddRectFilled(WDL, L, T, R, B, FillClr, rounding) end
    if OutlineClr then im.DrawList_AddRect(WDL, L, T, R, B, OutlineClr, rounding) end
end

function HighlightHvredItem( FillClr, OutlineClr , FillClrAct, OutlineClrAct, rounding, On_Release )
    local DL = im.GetForegroundDrawList(ctx)
    L, T = im.GetItemRectMin(ctx)
    R, B = im.GetItemRectMax(ctx)
    if im.IsMouseHoveringRect(ctx, L, T, R, B) then
        im.DrawList_AddRect(DL, L, T, R, B, OutlineClr or  0x99999999   , rounding)
        im.DrawList_AddRectFilled(DL, L, T, R, B,  FillClr or 0x99999933, rounding)
        if On_Release then 

            if im.IsMouseReleased(ctx,0) then 

                return true
            end
        else
            if  IsLBtnClicked then
                im.DrawList_AddRect(DL, L, T, R, B, FillClrAct or 0x000000dd, rounding)
                im.DrawList_AddRectFilled(DL, L, T, R, B, OutlineClrAct or 0x00000066, rounding)
                return true 
            end
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
local GetItemRect = GetItemRect or 'GetItemRect'
if GetItemRect == 'GetItemRect' or L == 'GetItemRect' then
L, T = im.GetItemRectMin(ctx); R, B = im.GetItemRectMax(ctx); w, h = im.GetItemRectSize(ctx)
--Get item rect
end
local P = Padding or 0; local HSC = H_OutlineSc or 4; local VSC = V_OutlineSc or 4
if Foreground == 'Foreground' then WinDrawList = Glob.FDL elseif Foreground then WinDrawList = Foreground  else WinDrawList = Foreground end
local WinDrawList = WinDrawList or  im.GetWindowDrawList(ctx)
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


function RepeatAtInterval(dur, rpt, FUNCTION)
    TimeBegin = TimeBegin or r.time_precise()
    local Now = r.time_precise()
    if rpt then
        for i = 0, rpt - 1, 1 do
            if Now > TimeBegin + dur * i and Now < TimeBegin + dur * (i + 0.5) then -- second blink
                return true 
            end
        end
    else
        if Now > TimeBegin and Now < TimeBegin + dur / 2 then
            return true 
        elseif Now > TimeBegin + dur / 2 + dur then
            TimeBegin = r.time_precise()
        end
    end
end

local function extract_enclosed_text(input_string)
    local start, finish, enclosed_text = string.find(input_string, "%[(.-)%]")
    if start then
        return enclosed_text
    else
        return nil
    end
end







function Draw_Attached_Drawings(FP,FX_Idx, pos, Prm_Val, Prm_Type )
                            
    if FP.Draw then
        local prm = FP
        
        local GR = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'GainReduction_dB')))
        local x, y              = pos[1], pos[2]
        
        local Val = prm.V  or Prm_Val or 0
        if DraggingMorph == FXGUID[FX_Idx] then
            Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num) 
        end

        

        
        for i, v in ipairs(FP.Draw) do
            local fill = v.Fill ==true  and 'Filled' 

            local function Repeat(rpt, va, Xgap, Ygap, func, Gap, RPTClr, CLR)
                if rpt and rpt ~= 0 then
                    local RPT = rpt
                    if va and va ~= 0 then RPT = rpt * Val * va end

                    for i = 0, RPT - 1, 1 do
    
                        local Clr1 = (v.Clr_VA ) and BlendColors(CLR or 0xffffffff, v.Clr_VA,  Val) or CLR or 0xffffffff
                        local Clr2 = (v.RPT_Clr_VA ) and BlendColors(RPTClr or 0xffffffff, v.RPT_Clr_VA ,  Val) or RPTClr or  0xffffffff
    
    
                        local Clr = BlendColors(Clr1 , Clr2, i / RPT)
    
                        func(i * (Xgap or 0), i * (Ygap or 0), i * (Gap or 0), Clr)
                    end
                else
                    func(Xgap)
                end
            end

            local x                 = x + (v.X_Offset or 0) + (Val * (v.X_Offset_VA or 0)) + ((GR or 0) * (v.X_Offset_VA_GR or 0))
            local y                 = y + (v.Y_Offset or 0) + (Val * (v.Y_Offset_VA or 0)) + ((GR or 0) * (v.Y_Offset_VA_GR or 0))
            
          
            local Thick             = (v.Thick or 2)
            local Gap, X_Gap, Y_Gap = v.Gap, v.X_Gap, v.Y_Gap
            local Clr_VA
            if v.Clr_VA then
                Clr_VA = BlendColors(v.Clr or 0xffffffff, v.Clr_VA, Val)
            end

            if v.X_Gap_VA and v.X_Gap_VA ~= 0 then
                X_Gap = (v.X_Gap or 0) * Val * v.X_Gap_VA
            end
            if v.Y_Gap_VA and v.Y_Gap_VA ~= 0 then
                Y_Gap = (v.Y_Gap or 0) * Val * v.Y_Gap_VA
            end

            if v.Gap_VA and v.Gap_VA ~= 0 and v.Gap then
                Gap = v.Gap * Val * v.Gap_VA
            end

            if v.Thick_VA then
                Thick = (v.Thick or 2) * (v.Thick_VA * Val)
            end

            if v.Type == 'Line' or v.Type == 'Rect' or v.Type == 'Rect Filled' then
                if   v.Type == 'Rect' or v.Type == 'Rect Filled' then
                    v.Width, v.Height =v.Width or im.GetItemRectSize(ctx), v.Height or select(2, im.GetItemRectSize(ctx))
                elseif v.Type == 'Line'  then
                    v.Width = v.Width or im.GetItemRectSize(ctx)
                    v.Height = v.Height or 0
                end
                local w = v.Width or im.GetItemRectSize(ctx)
                local h = v.Height or select(2, im.GetItemRectSize(ctx))

                
                local x2 = x + w
                local y2 = y + h
                local GR = GR or 0

                if v.Width_VA and v.Width_VA ~= 0 then
                    x2 = x + (w or 10) * Val * (v.Width_VA)
                end
                if v.Width_VA_GR then
                    x2 = x + (w or 10) * (GR * (v.Width_VA_GR or 0))
                end

                if v.Height_VA and v.Height_VA ~= 0 then
                    y2 = y + (h or 10) * Val * (v.Height_VA)
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
                        im.DrawList_AddLine(WDL, x + (Xg or 0), y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0), RptClr or Clr_VA or v.Clr or 0xffffffff, Thick)
                    end

                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, Addline, nil, v.RPT_Clr, v.Clr, v)
                else
                    local function AddRect(Xg, Yg, none, RptClr)
                        im.DrawList_AddRect(WDL, x + (Xg or 0), y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0), RptClr or Clr_VA or v.Clr or 0xffffffff, v.Round, flag, Thick)
                    end


                    local function AddRectFill(Xg, Yg, none, RptClr)
                        im.DrawList_AddRectFilled(WDL, x + (Xg or 0), y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0), RptClr or Clr_VA or v.Clr or 0xffffffff, v.Round)
                    end

                    if v.Fill then 
                        Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddRectFill, nil, v.RPT_Clr, v.Clr, v)
                    else 
                        Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddRect, nil, v.RPT_Clr, v.Clr, v)
                    end
                end

                if v.AdjustingX or v.AdjustingY then
                    local l = 4
                    im.DrawList_AddLine(WDL, x - l, y - l, x + l, y + l, 0xffffffdd)
                    im.DrawList_AddLine(WDL, x - l, y + l, x + l, y - l, 0xffffffdd)
                end
            elseif v.Type == 'Circle' or v.Type == 'Circle Filled' then
                local w, h = 10
                if FP.Type == 'Knob' or Prm_Type =='Knob' then
                  
                    w, h = r .ImGui_GetItemRectSize(ctx)
                else
                    v.Width = v.Width or 10
                    w, h = v.Width, v.Width
                end
                local Rad = v.Width or w
                if v.Width_VA and v.Width_VA ~= 0 then
                    Rad = Rad * Val * v.Width_VA
                end
                   

                local function AddCircle(X_Gap, Y_Gap, Gap, RptClr)
                    im.DrawList_AddCircle(WDL, x + w / 2 + (X_Gap or 0), y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0), RptClr or Clr_VA or v.Clr or 0xffffffff, nil,Thick)
                end
                local function AddCircleFill(X_Gap, Y_Gap, Gap, RptClr)
                    im.DrawList_AddCircleFilled(WDL, x + w / 2 + (X_Gap or 0), y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0), RptClr or Clr_VA or v.Clr or 0xffffffff)
                end



                if v.Fill  then
                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddCircleFill, Gap, v.RPT_Clr, v.Clr, v)
                else 
                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddCircle, Gap, v.RPT_Clr, v.Clr, v)
                end

                if v.AdjustingX or v.AdjustingY then
                    local l = 4
                    local x, y = x + Rad / 2, y + Rad / 2
                    im.DrawList_AddLine(WDL, x - l, y - l, x + l, y + l, 0xffffffdd)
                    im.DrawList_AddLine(WDL, x - l, y + l, x + l, y - l, 0xffffffdd)
                end
            elseif v.Type == 'Knob Pointer' or v.Type == 'Knob Range' or v.Type == 'Knob Image' or v.Type == 'Knob Circle'or v.Type == 'Knob Circle Filled' then
                local w, h = im.GetItemRectSize(ctx)
                local h = w 
                local x, y = x + w / 2 + (v.X_Offset or 0), y + w / 2 + (v.Y_Offset or 0)
               
                local ANGLE_MIN = 3.141592 * (v.Angle_Min or 0.75)
                local ANGLE_MAX = 3.141592 * (v.Angle_Max or 2.25)
                local t = (Val- 0) / (1 - 0)
                local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
                local IN = v.Rad_In or 0 -- modify this for the center begin point
                local OUT = v.Rad_Out or 0
                local Def_W = w / 2 
                local W = v.Width or Def_W

                if v.Type == 'Knob Pointer' then
                    im.DrawList_AddLine(WDL, x + angle_cos * IN, y + angle_sin * IN, x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick), Clr_VA or v.Clr or 0x999999aa, Thick)
                elseif v.Type == 'Knob Range' then
                    local function AddRange(G)
                        if  v.Repeat then 
                            local rpt = (v.Repeat_VA~= 0) and Val * v.Repeat_VA or 1
                            local gap = (v.Gap_VA~= 0) and Val * v.Gap* v.Gap_VA or 1

                            for i = 0, v.Repeat* (rpt ) , math.max(1*gap, 0.01) do 
                                local t = (i/v.Repeat- 0) / (1 - 0)
                                local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                                local angle_cos, angle_sin = math.cos(angle), math.sin(angle)

                                local x1, y1 = x + angle_cos * IN,  y + angle_sin * IN
                                local x2, y2 = x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick)
                                local Clr = BlendColors(v.Clr or 0xffffffff, v.RPT_Clr or 0xff33ffff, i / v.Repeat)

                                im.DrawList_AddLine(WDL, x1, y1, x2, y2, Clr or v.Clr or 0x999999aa, Thick)


                            end
                        else
                            for i = IN, OUT, (1 + (v.Gap or 0)) do
                                im.DrawList_PathArcTo(WDL, x, y, i, ANGLE_MIN,SetMinMax(ANGLE_MIN +(ANGLE_MAX - ANGLE_MIN) * Val,ANGLE_MIN, ANGLE_MAX))
                                im.DrawList_PathStroke(WDL, Clr_VA or v.Clr or 0x999999aa, nil, Thick)
                                im.DrawList_PathClear(WDL)
                            end
                        end
                        --[[ for i = ANGLE_MIN, SetMinMax(ANGLE_MIN +(ANGLE_MAX - ANGLE_MIN) * Val,ANGLE_MIN, ANGLE_MAX), (0.01  + (v.Gap or 0) * 0.01) do
                            im.DrawList_PathArcTo(WDL, x, y, OUT + (OUT-IN)/2 , i, SetMinMax( i+ (v.Gap or 0) * 0.01,ANGLE_MIN, ANGLE_MAX))
                            im.DrawList_PathStroke(WDL, Clr_VA or v.Clr or 0x999999aa, nil, (OUT-IN))
                            im.DrawList_PathClear(WDL)
                        end ]]
                    end



                    Repeat(1, 0, X_Gap, X_Gap, AddRange)

                elseif v.Type == 'Knob Circle Filled' or v.Type == 'Knob Circle' then
                    if v.Repeat and v.Repeat ~= 0 then 
                        local rpt = (v.Repeat_VA and v.Repeat_VA ~= 0) and Val * v.Repeat_VA or 1
                        --local gap = (v.Gap_VA~= 0) and Val * (v.Gap or 1 )* (v.Gap_VA or 1)
                        



                        for i = 0, v.Repeat* (rpt ) , math.max(1, 0.01) do 

                            local t = (i/v.Repeat- 0) / (1 - 0)
                            local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                            local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
                            local x1, y1 = x + angle_cos * IN,  y + angle_sin * IN
                            local x2, y2 = x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick)
                            local Clr1 = (v.Clr_VA ) and BlendColors(v.Clr or 0xffffffff, v.Clr_VA,  Val) or v.Clr or  0xffffffff
                            local Clr2 = (v.RPT_Clr_VA ) and BlendColors(v.RPT_Clr or 0xffffffff, v.RPT_Clr_VA ,  Val) or v.RPT_Clr or 0xffffffff

                            local Clr = BlendColors(Clr1 , Clr2, i / v.Repeat)

                            if v.Fill then 
                                im.DrawList_AddCircleFilled(WDL, x + angle_cos * IN, y + angle_sin * IN -1 , W, Clr or v.Clr or 0x999999aa, nil)
                            else
                                im.DrawList_AddCircle(WDL, x + angle_cos * IN, y + angle_sin * IN -1 , W, Clr or v.Clr or 0x999999aa, nil, Thick)
                            end
                        end
                    elseif not v.Repeat or v.Repeat == 0 then 
                            local t = (Val- 0) / (1 - 0)
                            local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                            local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
                            local x1, y1 = x + angle_cos * IN,  y + angle_sin * IN
                            local x2, y2 = x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick)
                            --[[ local Clr1 = (v.Clr_VA ) and BlendColors(v.Clr or 0xffffffff, v.Clr_VA,  Val) or v.Clr or  0xffffffff
                            local Clr2 = (v.RPT_Clr_VA ) and BlendColors(v.RPT_Clr or 0xffffffff, v.RPT_Clr_VA ,  Val) or v.RPT_Clr or 0xffffffff

                            local Clr = BlendColors(Clr1 , Clr2, i / v.Repeat) ]]


                        if v.Fill then 
                            im.DrawList_AddCircleFilled(WDL, x + angle_cos * IN, y + angle_sin * IN -1 , W, v.Clr or 0x999999aa, nil)
                        else
                            im.DrawList_AddCircle(WDL, x + angle_cos * IN, y + angle_sin * IN -1 , W,  v.Clr or 0x999999aa, nil, Thick)
                        end
                    end

                elseif v.Type == 'Knob Image' and v.Image then
                    local X, Y = x + angle_cos * IN, y + angle_sin * IN
                    im.DrawList_AddImage(WDL, v.Image, X, Y, X + W, Y + W, nil, nil, nil, nil, Clr_VA or v.Clr or 0x999999aa)
                end



                if v.AdjustingX or v.AdjustingY then
                    local l = 4

                    im.DrawList_AddLine(WDL, x - l, y - l, x + l, y + l, 0xffffffdd)
                    im.DrawList_AddLine(WDL, x - l, y + l, x + l, y - l, 0xffffffdd)
                end
            elseif v.Type == 'Image' and v.Image then
                local w, h = im.Image_GetSize(v.Image)
                local w, h = (v.Width or w), (v.Height or h)
                if v.Width_VA and v.Width_VA ~= 0 then
                    w = (v.Width or w) * v.Width_VA * Val
                end
                if v.Height_VA and v.Height_VA ~= 0 then
                    h = (v.Height or h) * v.Height_VA * Val
                end
                local function AddImage(X_Gap, Y_Gap, none, RptClr)
                    im.DrawList_AddImage(WDL, v.Image, x + X_Gap, y + (Y_Gap or 0), x + w + X_Gap, y + h + (Y_Gap or 0), 0, 0, 1, 1, RptClr or Clr_VA or v.Clr)
                end


                Repeat(v.Repeat, v.Repeat_VA, v.X_Gap or 0, v.Y_Gap or 0, AddImage, nil, v.RPT_Clr, v.Clr,v) elseif v.Type == 'Gain Reduction Text' and not FX[FxGUID].DontShowGR then
                local GR = round(GR, 1)
                im.DrawList_AddTextEx(WDL, Arial_12, 12, x, y, v.Clr or 0xffffffff, GR or '')
            end
        end
    end
end

function TrashIcon(size, lbl, ClrBG, ClrTint)
    local rv = im.ImageButton(ctx, '##' .. lbl, Img.Trash, size, size, nil, nil, nil, nil, ClrBG, ClrTint) -- TODO weird but I can’t find anything in the official docs or the reaImGui repo about this function
    if im.IsItemHovered(ctx) then
        TintClr = 0xCE1A28ff
        return rv, TintClr
    end
end

function Horizontal_Scroll(value)
    if Reverse_Scroll then
        Scroll_V = -Wheel_V
    else
        Scroll_V = Wheel_V
    end
    if -CursorStartX + Scroll_V * value < value then
        im.SetNextWindowScroll(ctx, 0, 0)                                -- scroll to the left side when scroll value is bigger than the rest space value
    else
        im.SetNextWindowScroll(ctx, -CursorStartX + Scroll_V * value, 0) -- scroll horizontally
    end
end

function Post_FX_Chain ()
    if Trk[TrkID].PostFX[1] then
        im.SameLine(ctx, nil, 0)
        Line_L, Line_T = im.GetCursorScreenPos(ctx)
        rv             = im.Button(ctx,
            (#Trk[TrkID].PostFX or '') .. '\n\n' .. 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
        if im.IsItemClicked(ctx, 1) then
            if Trk[TrkID].PostFX_Hide then Trk[TrkID].PostFX_Hide = false else Trk[TrkID].PostFX_Hide = true end
        end
        if im.BeginDragDropTarget(ctx) then -- if drop to post fx chain Btn
            if Payload_Type == 'FX_Drag' then
                Drop, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)

                if Drop and not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                    --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)
                    table.insert(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX,
                        FXGUID[DragFX_ID], true)


                    local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                    if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                end
            elseif Payload_Type == 'DND ADD FX' then
                dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX')
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)
                if dropped then
                    r.TrackFX_AddByName(LT_Track, payload, false, -1000 - Sel_Track_FX_Count)
                    local FXid = r.TrackFX_GetFXGUID(LT_Track, Sel_Track_FX_Count)
                    local _, Name = r.TrackFX_GetFXName(LT_Track, Sel_Track_FX_Count)
                    table.insert(Trk[TrkID].PostFX, FXid)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX, FXid,
                        true)
                end
            end

            im.EndDragDropTarget(ctx)
        end

        im.SameLine(ctx, nil, 0)
        im.PushStyleColor(ctx, im.Col_ChildBg, 0xffffff11)
        local PostFX_Extend_W = 0
        if PostFX_Width == VP.w / 2 then PostFX_Extend_W = 20 end
        if not Trk[TrkID].PostFX_Hide then
            if im.BeginChild(ctx, 'Post FX chain', PostFX_Width - PostFX_Extend_W, 220) then
                local clr = im.GetStyleColor(ctx, im.Col_Button)
                im.DrawList_AddLine(Glob.FDL, Line_L, Line_T - 1, Line_L + VP.w, Line_T - 1, clr)
                im.DrawList_AddLine(Glob.FDL, Line_L, Line_T + 220, Line_L + VP.w, Line_T + 220, clr)



                Trk[TrkID].MakeSpcForPostFXchain = 0

                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = 0 else offset = 1 end

                for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
                    local I = --[[ tablefind(FXGUID, Trk[TrkID].PostFX[#Trk[TrkID].PostFX+1-FX_Idx])  ]]
                        tablefind(FXGUID, V)

                    local Spc
                    if FX_Idx == 1 and I then AddSpaceBtwnFXs(I - 1, 'SpcInPost', nil, nil, 1) end
                    if I then
                        createFXWindow(I)
                        im.SameLine(ctx, nil, 0)

                        FX[FXGUID[I]].PostWin_SzX, _ = im.GetItemRectSize(ctx)
                        Trk[TrkID].MakeSpcForPostFXchain = (Trk[TrkID].MakeSpcForPostFXchain or 0) +
                            (FX.WidthCollapse[FXGUID[I]] or FX[FXGUID[I]].Width or (DefaultWidth)) +
                            10 -- 10 is space btwn fxs

                        if FX_Idx == #Trk[TrkID].PostFX then
                            AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, #Trk[TrkID].PostFX + 1)
                        else
                            AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, FX_Idx + 1)
                        end
                        if FX_Idx == #Trk[TrkID].PostFX and im.IsItemHovered(ctx, im.HoveredFlags_RectOnly) then
                            MouseAtRightEdge = true --[[ else MouseAtRightEdge = nil ]]
                        end
                    end
                end




                offset = nil


                if InsertToPost_Src then
                    table.insert(Trk[TrkID].PostFX, InsertToPost_Dest, FXGUID[InsertToPost_Src])
                    for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i,
                            Trk[TrkID].PostFX[i] or '',
                            true)
                    end
                    InsertToPost_Src = nil
                    InsertToPost_Dest = nil
                end
                im.EndChild(ctx)
            end
        else
            Trk[TrkID].MakeSpcForPostFXchain = 0
        end


        for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
            local I = tablefind(FXGUID, V)
            local P = Sel_Track_FX_Count - #Trk[TrkID].PostFX + (FX_Idx - 1)


            if I ~= P then
                r.Undo_BeginBlock()
                if not MovFX.FromPos[1] then
                    table.insert(MovFX.FromPos, I)
                    table.insert(MovFX.ToPos, P)
                    table.insert(MovFX.Lbl, 'Move FX into Post-FX Chain')
                end
                --r.TrackFX_CopyToTrack(LT_Track, I, LT_Track, P, true)
                r.Undo_EndBlock('Move FX out of Post-FX Chain', 0)
            end
        end
        im.PopStyleColor(ctx)
    end
end

function AddSpaceBtwnFXs_LAST(FX_Idx, FxGUID)
    if FX_Idx + 1 == RepeatTimeForWindows and not Trk[TrkID].PostFX[1] then -- add last space
        SL(nil, 10)
        AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc', nil,nil,nil,100, nil, true)
    elseif FX_Idx + 1 == RepeatTimeForWindows and Trk[TrkID].PostFX[1] then
        AddSpaceBtwnFXs(Sel_Track_FX_Count - #Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
    end
end

function Show_Drag_FX_Preview_Tooltip(FxGUID, FX_Idx)
    if FX.LayEdit then return end  
    im.BeginTooltip(ctx)
    AddWindowBtn(FxGUID, FX_Idx ,nil,nil,nil,nil,true)
    im.EndTooltip(ctx)
end


function createFXWindow(FX_Idx, Cur_X_Ofs)
    
    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local WindowSize

    if not FxGUID then return end 
    FX[FxGUID] = FX[FxGUID] or {}
    local fx = FX[FxGUID]
    Layout_Edit_Properties_Window(fx,FX_Idx)

    FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
    --local FxGUID = FXGUID[FX_Idx]
    local FxNameS = FX.Win_Name_S[FX_Idx]
    local Hide
    FX.DL = im.GetWindowDrawList(ctx)
   
    local enclosed_text = extract_enclosed_text(FX_Name)
    if enclosed_text then
        local rename = string.gsub(FX_Name, "%s*%[.-%]%s*", "")
        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "renamed_name", rename)
    end
    local  _, orig_name=  r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')
    if orig_name == 'Container' --[[ and FX_Idx < 0x2000000 ]] then
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
    local function PresetMorph()
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
            --local M = PresetMorph


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
                        OpenMorphSettings = FxGUID
                    end
                    local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                    FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                    for i = 0, Ct - 4, 1 do --get param names
                        FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                        local rv, name             = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                        FX[FxGUID].PrmList[i].Name = name
                    end
                end

                if im.Selectable(ctx, 'Hide Morph Slider', false) then
                    FX[FxGUID].MorphHide = true
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph Hide' .. FxGUID, 'true', true)
                end

                im.EndPopup(ctx)
            else
                MorphingMenuOpen = false
            end




            --[[ if M and not ifHvr and M.JustHvrd then
                M.timer = M.timer + 1
            else
                M.timer = 0
            end ]]





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
    end


    local id = FX_Idx+1
    local nextfx = tree[id+1] and FX[tree[id+1].GUID] or nil
    local tree_this = tree[id]
    local tree_next = tree[id+1]
    local tree_last = tree[id]

    local function If_Parallel_FX()

        local function ChangeWetVal (FxGUID, i ,wet_p_num , Val )
            r.TrackFX_SetParamNormalized(LT_Track, i, wet_p_num, Val)
            --FX[FxGUID][0].V = Val
        end 
        local Win_W  = 170


        --- if Mixer Layout 
        for i , v in ipairs(PAR_FXs) do 

            if id == v[1] then          -- if it's the FX before the first parallel FX
                ROOT_FXGUID = FxGUID
                im.PushStyleColor(ctx, im.Col_ChildBg, 0x202020ff)
                im.PushStyleVar(ctx, im.StyleVar_ScrollbarSize, 10)
                if im.BeginChild(ctx, '##Parallel FX' .. FX_Idx , Win_W + 5 , 220, im.WindowFlags_NoScrollWithMouse) then
                    --[[ local l, t = im.GetCursorScreenPos(ctx)
                    im.DrawList_AddRect(WDL, l , t , l + Win_W +5 ,t + 220, 0xff22ffff) ]]
                    local pad = 2   
                    local Width = 110
                    local height = 19
                    AddSpacing(pad/2)
                    if im.Button(ctx, 'Parallel FXs', Width+height*3) then 

                    end
                    if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                        im.SetDragDropPayload(ctx, 'Parallel_FX_Drag', FX_Idx)
                        im.EndDragDropSource(ctx)
                    end

                    if im.BeginChild(ctx, '##Parallel FX Mixer' .. FX_Idx , Win_W  , 190, nil--[[ im.WindowFlags_NoScrollbar ]]) then
                        local rpt = v[1]+ v[2]-v[1] 
                        for i= v[1], rpt, 1 do 

                            local FX_Idx = i -1 
                            local Label =  '##DryWet' .. FX_Idx
                            local wet_p_num =  r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet') 
                            local FxGUID = tree[i].GUID
                            local FX_Name = FX[FxGUID].CustomTitle or  ChangeFX_Name(tree[i].fxname)
                            FX[FxGUID][0] = FX[FxGUID][0] or {}

                            
                            local function Solo()
                                local Solo_ClrPop = Button_Color_Change(FX[FxGUID].Solo , Layer_Solo )
                                im.PushStyleColor(ctx, im.Col_Button, Change_Clr_A (im.GetStyleColor(ctx, im.Col_Button), 1))
                                im.PushStyleColor(ctx, im.Col_ButtonHovered, Change_Clr_A (im.GetStyleColor(ctx, im.Col_ButtonHovered ), 1))
                                im.PushStyleColor(ctx, im.Col_ButtonActive, Change_Clr_A (im.GetStyleColor(ctx, im.Col_ButtonActive ), 1))



                                if im.Button(ctx, 'S##Solo'..FX_Idx, height, height*2) then 
                                    FX[FxGUID].Solo = toggle(FX[FxGUID].Solo)


                                    Save_to_Trk('Parallel Solo ' .. FxGUID, FX[FxGUID].Solo )

                                    local Solo_Count = 0 
                                    for i= v[1], rpt, 1 do  
                                        local wet_p_num =  r.TrackFX_GetParamFromIdent(LT_Track, i-1, ':wet') 
                                        local FxGUID = tree[i].GUID

                                        if FX[FxGUID].Solo then   
                                            Solo_Count = Solo_Count + 1 
                                        end 
                                        --FX[FxGUID].Wet_V_before_solo = FX[FxGUID][0].V or r.TrackFX_GetParamNormalized(LT_Track, i-1, wet_p_num)

                                    end

                                    
                                    for i= v[1], rpt, 1 do  
                                        local FxGUID = tree[i].GUID
                                        local wet_p_num =  r.TrackFX_GetParamFromIdent(LT_Track, i-1, ':wet') 

                                        if Solo_Count > 0 then 

                                            if not FX[FxGUID].Solo then 
                                                if FX[FxGUID][0].V  ~= 0 then 
                                                    FX[FxGUID].Wet_V_before_solo = FX[FxGUID][0].V 
                                                    Save_to_Trk('Wet_V_before_solo ' .. FxGUID, FX[FxGUID][0].V  )

                                                end

                                                ChangeWetVal (FxGUID, i-1  ,wet_p_num , 0)
                                            else    -- if soloed 
                                                local V = FX[FxGUID].Wet_V_before_solo or FX[FxGUID][0].V or r.TrackFX_GetParamNormalized(LT_Track, i-1, wet_p_num)

                                                
                                                ChangeWetVal (FxGUID, i-1  ,wet_p_num , V)
                                                Save_to_Trk('Wet_V_before_solo ' .. FxGUID,'' )


                                            end
                                        else    

                                            ChangeWetVal (FxGUID, i-1  ,wet_p_num , FX[FxGUID].Wet_V_before_solo or FX[FxGUID][0].V or 0.3)
                                            Save_to_Trk('Wet_V_before_solo ' .. FxGUID, '')

                                        end
                                    end
                                end
                                if Solo_ClrPop then 
                                    im.PopStyleColor(ctx, Solo_ClrPop)
                                end

                                im.PopStyleColor(ctx, 3 )
                            end

                            local function Mute()
                                im.PushStyleColor(ctx, im.Col_Button, Change_Clr_A (im.GetStyleColor(ctx, im.Col_Button), 1))
                                im.PushStyleColor(ctx, im.Col_ButtonHovered, Change_Clr_A (im.GetStyleColor(ctx, im.Col_ButtonHovered ), 1))
                                im.PushStyleColor(ctx, im.Col_ButtonActive, Change_Clr_A (im.GetStyleColor(ctx, im.Col_ButtonActive ), 1))


                                local LyrMuteClrPop = Button_Color_Change(FX[FxGUID].Mute , Layer_Mute )

                                if im.Button(ctx, 'M##Mute'..FX_Idx, height, height*2) then 
                                    FX[FxGUID].Mute = toggle(FX[FxGUID].Mute)
                                    Save_to_Trk('Parallel Mute ' .. FxGUID, FX[FxGUID].Mute )

                                    if not FX[FxGUID].Mute  then --if muted 
                                        --ChangeWetVal(FxGUID, i-1  ,wet_p_num, FX[FxGUID].Wet_V_before_mute or FX[FxGUID][0].V or 0)

                                        --r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, wet_p_num, FX[FxGUID].Wet_V_before_mute or FX[FxGUID][0].V or 0)
                                        --

                                        ChangeWetVal(FxGUID, i-1  ,wet_p_num, FX[FxGUID].Wet_V_before_mute or FX[FxGUID][0].V or 0)
                                        Save_to_Trk('Wet_V_before_mute ' .. FxGUID, '' )
                                    else    

                                        FX[FxGUID].Wet_V_before_mute = FX[FxGUID][0].V or r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, wet_p_num)
                                        Save_to_Trk('Wet_V_before_mute ' .. FxGUID, FX[FxGUID].Wet_V_before_mute )
                                        ChangeWetVal(FxGUID, i-1  ,wet_p_num, 0)
                                    end 
                                    FX[FxGUID].V = r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, wet_p_num)
                                end
                                if LyrMuteClrPop then 
                                    im.PopStyleColor(ctx, LyrMuteClrPop)
                                end 

                                im.PopStyleColor(ctx, 3 )

                            end
                            local function Label()
                                local L, T = im.GetCursorScreenPos(ctx)
                                im.PushClipRect(ctx, L, T, L+Width, T+height, true)
                                im.DrawList_AddText(WDL, L,T, 0xffffffff, FX_Name)
                                im.PopClipRect(ctx)
                                local rv = im.InvisibleButton(ctx, 'InivisiBtn for Dry wet Drag'..FxGUID, Width, height)


                                local x, y = im.GetCursorPos(ctx)

                                im.SetCursorPos(ctx, x +5, y - height - pad)


                                if  HighlightHvredItem(0x00000000) then 
                                    DETERMINE_IF_DRAG= FxGUID 

                                end



                                if DETERMINE_IF_DRAG==FxGUID then
                                    local x, y = im.GetMouseDragDelta(ctx)
                                    if im.IsMouseReleased(ctx,0) then 
                                        if x < 8 and y < 8 then 
                                            if FX[ROOT_FXGUID].ChosenFX == FxGUID then FX[ROOT_FXGUID].ChosenFX = nil 
                                            else FX[ROOT_FXGUID].ChosenFX = FxGUID 
                                            end

                                        end
                                        DETERMINE_IF_DRAG = nil
                                    end
                                end
                            end

                            local function Input_Text_label()

                                local rv,  buf = im.InputText( ctx, '##Dry wet'..FX_Idx,  buf or FX_Name, im.InputTextFlags_ReadOnly)
                                --[[ local l, t =  im.GetItemRectMin(ctx)
                                local w, h =  im.GetItemRectSize(ctx)
                                im.SetCursorPos(ctx, l, t)
                                im.InvisibleButton(ctx, 'InivisiBtn for Dry wet Drag', w, h ) ]]
                                if rv then 
                                    FX[FxGUID].CustomTitle = buf
                                end
                            end
                            local function Allow_FX_Drag_On_Item()
                                if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                                    im.SetDragDropPayload(ctx, 'FX_Drag', FX_Idx)
                                    DragFX_ID = FX_Idx
                                    DragFxGuid = FxGUID
                                    Show_Drag_FX_Preview_Tooltip(FxGUID, FX_Idx)
                                    im.EndDragDropSource(ctx)
                                end
                            end

                            local function ColorBox()
                                if im.InvisibleButton(ctx, '##color Rect'..FX_Idx, 5, height * 2) then 
                                end
                                local l,t,R,b, w,h = HighlightSelectedItem(Clr.PAR_FX[1]) 
                            end
                            
                            local function MoveFX(payload, ofs)
                                table.insert(MovFX.FromPos, tonumber(payload))
                                table.insert(MovFX.ToPos, tonumber(FX_Idx) + (ofs or 0))

                                -- if Moving to the first fx (root) of parallel fx
                                if v[1] -1 ==tonumber(FX_Idx) + (ofs or 0) then 
                                    MovFX.Parallel = v[1]-1
                                else
                                    MovFX.Parallel = true 
                                end
                            end

                            local function Allow_FX_Drop_On_Item(ofs)
                                local Create_Insert_FX_Preview
                                if im.BeginDragDropTarget(ctx) then 

                                    if Payload_Type == 'FX_Drag' then
                                        local dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                                         -- move FX if it's fx,  move into container if it's container 
                                        --[[ local l, t = im.GetItemRectMin(ctx)
                                        local w, h = im.GetItemRectSize(ctx)
                                        im.DrawList_AddRectFilled(WDL, l, t, l+w, t + 5, 0xffff44ff) ]]


                                        if DragFX_ID < tonumber(FX_Idx) then 
                                            Create_Insert_FX_Preview =  FX_Idx+1
                                        else
                                            Create_Insert_FX_Preview =  FX_Idx
                                        end 
                                        if dropped then 
                                            MoveFX(payload, ofs)
                                        end
                                    end
                                    im.EndDragDropTarget(ctx)
                                end
                                return Create_Insert_FX_Preview
                            end

                            local function Add_FX_Btn ()
                                if i == rpt then 
                                    AddSpacing(1)
                                    im.PushStyleColor(ctx, im.Col_Button, 0x00000000)

                                    im.PushFont(ctx, Arial_14)

                                    local clickBtn = im.Button(ctx, '+'..'##Add FX Button'..FxGUID, Width + height*2.5, height*0.9)
                                    im.PopFont(ctx)
                                    im.PopStyleColor(ctx)
                                    local rv = Allow_FX_Drop_On_Item(1)
                                    local FillClr= rv and 0xffffff33
                                    local L, T, R, B, w, h = HighlightSelectedItem(FillClr, 0xffffff77, 0, nil,nil,nil,nil, nil, nil , 1,1, 'GetItemRect', nil, nil, 2) 

                                    if clickBtn then 

                                        im.OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx+1)
                                    end

                                end
                                AddFX_Menu(FX_Idx+1, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost, true)

                            end


                            
                            if FX[ROOT_FXGUID].ChosenFX == FxGUID then 
                                local L, T = im.GetCursorScreenPos(ctx )
                                im.DrawList_AddRectFilled(WDL, L, T , L + Win_W , T + height*2, 0xffffff22)
                                --HighlightSelectedItem(0xffffff22, OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect )
                            end

                            local Hover_Insert_FX_Preview

                            if Create_Insert_FX_Preview==FX_Idx then 

                                local rv, type, payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)
                                
                                if  payload~='' and type == 'FX_Drag' then 
                                    local FxGUID = r.TrackFX_GetFXGUID(LT_Track,   tonumber(payload) )
                                    AddWindowBtn(FxGUID, tonumber(payload) , Win_W,nil,nil,nil,true)
                                    local rv =   Allow_FX_Drop_On_Item() 
                                    if rv then Create_Insert_FX_Preview = rv end 
                                    local L, T = im.GetItemRectMin(ctx)
                                    local R, B =  im.GetItemRectMax(ctx)
                                    if im.IsMouseHoveringRect(ctx, L ,T - 3, R + 10,B + 5)then 
                                        Hover_Insert_FX_Preview = true 
                                        if im.IsMouseReleased(ctx, 0) then 
                                            if not MovFX.ToPos[1] then 
                                                table.insert(MovFX.FromPos, DragFX_ID)
                                                table.insert(MovFX.ToPos, tonumber(FX_Idx))
                                                MoveFX(payload, ofs)
                                            end
                                        end
                                    end
                                end
                            end



                            im.BeginGroup(ctx)
                            --im.Text(ctx, FX_Name)
                            im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 0, 1)
                            ColorBox()
                            Allow_FX_Drag_On_Item()
                            
                            SL(nil, pad * 2 )
                            im.SetNextItemWidth(ctx,Width)
                            
                            Label()
                            
                            Allow_FX_Drag_On_Item()
                            --local  y= im.GetCursorPosY(ctx)
                            --im.SetCursorPosY(ctx,  y + 15)
                            --im.SetCursorPos(ctx,x + 5 + pad * 2  , y - h + height )

                            FX[FxGUID][0].V = FX[FxGUID][0].V  or r.TrackFX_GetParamNormalized( LT_Track, FX_Idx, wet_p_num)
                            AddDrag(ctx, '##DryWet' .. FX_Idx, FX_Name, FX[FxGUID][0].V , 0, 1, 0,  FX_Idx, wet_p_num, 'FX Layering', Width, nil, nil, nil , 'none', 'Within',  nil, nil, nil)


                            im.EndGroup(ctx)
                            
                            im.PopStyleVar(ctx)
                            



                            local rv =   Allow_FX_Drop_On_Item() 
                            if rv then 
                                Create_Insert_FX_Preview = rv 
                            elseif Create_Insert_FX_Preview==FX_Idx and not Hover_Insert_FX_Preview then 
                                Create_Insert_FX_Preview = nil 
                            end


                            SL(nil,1)


                            Solo()
                            SL(nil,1)
                            Mute()




                            Add_FX_Btn ()
                            
                            
                        end

                    im.EndChild(ctx)

                    end

                    im.EndChild(ctx)
                    SL(nil,0)
                    START_OF_PARALLEL_FX_MIXER = id
                end
                im.PopStyleVar(ctx) --- for scrollbarsize
                im.PopStyleColor(ctx)
            end
            if id >= v[1] and id <= v[2] then --if FX is within the Mixer 

                if FX[ROOT_FXGUID].ChosenFX == FxGUID then 
                    return 'Mixer Layout - Show'
                else 
                    return 'Mixer Layout - Hide'
                end
            end
        end






        --if tree_last and  tree_last.parallel then return 'Complex' end 

        --[[ if  tree_this.parallel  and not fx.ShowParallel   then 
            local FX_Name = ChangeFX_Name(FX_Name)
            im.SetCursorPos(ctx, CurPos_Aftr_Create_FX_Win[1], CurPos_Aftr_Create_FX_Win[2])

            if im.Button(ctx,FX_Name, Win_W) then 
                Switch_Parallel_FX = FxGUID
            end

            return  true 
        end
        if nextfx and nextfx.ShowParallel then 
            im.SetCursorPosY(ctx,220)
            POS_NEXT_PARALLEL = im.GetCursorPosX(ctx)
            local FX_Name = ChangeFX_Name(FX_Name)
            if im.Button(ctx,FX_Name,Win_W) then

                --nextfx.ShowParallel = toggle(nextfx.ShowParallel )
                Switch_Parallel_FX = tree[math.min(FX_Idx+2, Sel_Track_FX_Count)].GUID   -- next fx's guid
            end
            im.SetCursorPosY(ctx,0)

            return 'Next_Parallel' 
        end 
 ]]

    end
    

    local Parallel = If_Parallel_FX()

    if Parallel  then   
        
        if Parallel == 'Mixer Layout - Hide' then 

            return Parallel
        elseif not fx.ShowParallel then 
            --return Parallel
        end
    end --- THINGS BELOW IS NOT EXECUTED IF THERES PARALLEL FX

    --if FX[tree[FX_Idx].GUID].ShowNextParallel then return end






    PresetMorph()
    
    local FX_Devices_Bg = FX_Devices_Bg

    -- FX window color

    im.PushStyleColor(ctx, im.Col_ChildBg, FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff); local poptimes = 1


    FX[FxGUID] = FX[FxGUID] or {}
    local fx = FX[FxGUID]

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
    
    if Hide then 
        im.PopStyleColor(ctx, poptimes) -- -- PopColor #1 FX Window
        im.SameLine(ctx, nil, 0)

        im.Dummy(ctx, 0, 0)
        im.SameLine(ctx, nil, 0)

        return        --im.EndGroup(ctx)
    end
    im.BeginGroup(ctx)

    local CurPosX
    if FxGUID == FXGUID[(tablefind(Trk[TrkID].PostFX, FxGUID) or 0) - 1] then
        --[[ CurPosX = im.GetCursorPosX(ctx)
        im.SetCursorPosX(ctx,VP.X+VP.w- (FX[FxGUID].PostWin_SzX or 0)) ]]
    end
    local Width = fx.Width_Collapse or FX[FxGUID].Width or DefaultWidth or 220
    -- local winFlg = im.ChildFlags_NoScrollWithMouse + im.ChildFlags_NoScrollbar

    local dummyH = 220
    local  _, name=  r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')

    if name == 'Container' then
        winFlg = FX[FxGUID].NoScroll or im.ChildFlags_AlwaysAutoResize
        dummyH = 0
    end
    im.PushStyleVar(ctx, im.StyleVar_ScrollbarSize, 8) -- styleVar ScrollBar

    local function Make_Window()
       
        if im.BeginChild(ctx, FX_Name .. FX_Idx, Width, 220, nil, im.WindowFlags_NoScrollbar | im.WindowFlags_NoScrollWithMouse) and not Hide then ----START CHILD WINDOW------


            local fx = FX[FxGUID]

            Glob.FDL = im.GetForegroundDrawList(ctx)

            WDL = im.GetWindowDrawList(ctx)

            Win_L, Win_T = im.GetItemRectMin(ctx); Win_W, Win_H = im.GetItemRectSize(ctx)
            Win_R, _ = im.GetItemRectMax(ctx); Win_B = Win_T + 220
            local function Disable_If_LayEdit(Begin_or_End)
                if (FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true) and Mods ~= Apl then
                    if Begin_or_End =='Begin' then 
                        im.BeginDisabled(ctx)
                    elseif Begin_or_End =='End' then 
                        im.EndDisabled(ctx)

                    end
                end
            end

            local function If_LayEdit_Activated()
                    
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
                        LE.GridSize = math.max(LE.GridSize - 5, 5)
                    end

                    for i = 0, FX[FXGUID[FX_Idx]].Width or DefaultWidth, LE.GridSize do
                        im.DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B, 0x44444455)
                    end
                    for i = 0, 220, LE.GridSize do
                        im.DrawList_AddLine(WinDrawList, Win_L,
                            Win_T + i, Win_R, Win_T + i, 0x44444455)
                    end

                    im.DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B, 0x66666677, 1)


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
                        FX[FxGUID].Width = FX[FxGUID].Width or  DefaultWidth
                        FX[FxGUID].Width = FX[FxGUID].Width + Dx; LE.BeenEdited = true
                    end
                    if not IsLBtnHeld then LE.ResizingFX = nil end
                end
                
            end
            local function If_LayEdit_Activated__WindowBtn()
                local MouseX, MouseY = im.GetMousePos(ctx)
                if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                    im.BeginDisabled(ctx); R, T = im.GetItemRectMax(ctx)
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
            end
            local function If_DebugMode_Active()
                if DebugMode and im.IsItemHovered(ctx) then tooltip('FX_Idx = ' .. FX_Idx) end
                if DebugMode and im.IsKeyDown(ctx, im.Key_D) then tooltip(TrkID) end
            end
            local function If_Open_Morph_Settings()
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
            end
            
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
                elseif LT_ParamNum == FX[FxGUID].DeltaP   then

                    FX[FxGUID].DeltaP_V = r.TrackFX_GetParamNormalized(LT_Track, id,
                        FX[FxGUID].DeltaP)
                end
            end

            local function AddWetDryKnob_If_not_SpecialLayoutFX()
                local orig_name = orig_name
                if orig_name:find('JS: ') then orig_name = string.sub(orig_name, 5) end 
                if FindStringInTable(SpecialLayoutFXs, FX_Name) == false and not FindStringInTable(PluginScripts, orig_name) then -- orig_name used to be FX.Win_Name_S[FX_Idx] , changed to orig_name to work with containers in case if user changes name
                    SyncWetValues()

                    if FX[FxGUID].Collapse ~= true then
                        FX[FxGUID] = FX[FxGUID] or {}
                        FX[FxGUID][0]= FX[FxGUID][0] or {}
                        FX[FxGUID][0].V  = FX[FxGUID][0].V  or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet') )
                        Wet.ActiveAny, Wet.Active, FX[FxGUID][0].V = Add_WetDryKnob(ctx, 'a', '', FX[FxGUID][0].V, 0, 1, FX_Idx)
                    end

                    if im.BeginDragDropTarget(ctx) then
                        rv, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                        im.EndDragDropTarget(ctx)
                    end
                end
            end
            -- im.PopStyleVar(ctx) --StyleVar#4  POP (Things in the header of FX window)

            ------------------------------------------
            ------ Generic FX's knobs and sliders area
            ------------------------------------------


            local function Need_Create_Regular_Layout()
                if not FX[FxGUID].Collapse and FindStringInTable(BlackListFXs, FX_Name) ~= true and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                    local FX_has_Plugin
                    for i, v in pairs(PluginScripts) do

                        if FX_Name:find(v) then
                            FX_has_Plugin = true
                        end
                        local rv, name = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')
                        
                        if name:find(v) then 
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
            local function Do_PluginScripts()

                for i, v in pairs(PluginScripts) do
                    --local FX_Name = FX_Name
                    local rv, orig_Name = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')

                    if FX_Name:find(v) or (orig_Name == 'Container' and v == 'Container') then
                        r.SetExtState('FXD', 'Plugin Script FX_Id', FX_Idx, false)
                        PluginScript.FX_Idx = FX_Idx
                        PluginScript.Guid = FxGUID

                        dofile(pluginScriptPath .. '/' .. v .. '.lua')
                    end
                end
            end

            


            local FX_Idx = FX_Idx or 1

            r.gmem_attach('ParamValues')
            FX.Win_Name_S[FX_Idx] = ChangeFX_Name(FX.Win_Name[FX_Idx] or FX_Name)

            FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
            FX_Name = string.gsub(FX_Name, '%-', ' ')



            If_Draw_Mode_Is_Active(FxGUID, Win_L, Win_T, Win_R, Win_B, FxNameS)
            Draw_Background(FxGUID)
            If_LayEdit_Activated()

            im.SameLine(ctx, nil, 0)
            
            AddWindowBtn(FxGUID, FX_Idx )

            If_LayEdit_Activated__WindowBtn()



            If_DebugMode_Active()

            If_Open_Morph_Settings()


            im.SameLine(ctx)
            AddWetDryKnob_If_not_SpecialLayoutFX()
            Disable_If_LayEdit('Begin')

            if Need_Create_Regular_Layout() then
                local WinP_X; local WinP_Y;
                local fx = FX[FxGUID]
                --im.DrawList_AddText(WDL, 100,200, 0xffffffff, 'asd')

                if FX[FxGUID].Round then
                    im.PushStyleVar(ctx, im.StyleVar_FrameRounding, FX[FxGUID].Round)
                end
                if FX[FxGUID].GrbRound then
                    im.PushStyleVar(ctx, im.StyleVar_GrabRounding, FX[FxGUID].GrbRound)
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

                    ParamX_Value = 'Param' .. tostring(FP.Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID

                    ----Default Layouts
                    if not FP.PosX and not FP.PosY then
                        if FP.Type == 'Slider' or (not FP.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' or FP.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag' and FP.Type == nil) then
                            local Column = math.floor((Fx_P / 6) - 0.01)
                            local W = ((FX[FxGUID][Fx_P - Column * 6].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160) + GapBtwnPrmColumns) * Column
                            local Y = 30 * (Fx_P - (Column * 6))
                            im.SetCursorPos(ctx, W, Y)
                        elseif FP.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider' and FP.Type == nil) then
                            im.SetCursorPos(ctx, 17 * (Fx_P - 1), 30)
                        elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and FP.Type == nil) then
                            local KSz = Df.KnobSize
                            local G = 15
                            local Column = math.floor(Fx_P / 3 - 0.1)

                            im.SetCursorPos(ctx, KSz * (Column), 26 + (KSz + G) * (Fx_P - (Column * 3) - 1))
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

                            ---!!!!!! use  drawlist  splitter here?  So that Mod Lines can be on top, or to decide what drawings take precedence
                            local function Create_Item()
                                local pos =  { im.GetCursorScreenPos(ctx) }

                                --- Add Parameter controls ---------
                                if Prm.Type == 'Slider' or (not Prm.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' then
                                    AddSlider(ctx, '##' .. (Prm.Name or Fx_P) .. FX_Name, Prm.CustomLbl, Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Style, Prm.Sldr_W or FX.Def_Sldr_W[FxGUID], 0, Disable, Vertical, GrabSize, Prm.Lbl, 8)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Sldr', curX, CurY)
                                elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and Prm.Type == nil) then
                                    AddKnob(ctx, '##' .. Prm.Name .. FX_Name, Prm.CustomLbl, Prm.V, 0, 1, Fx_P, FX_Idx, Prm.Num, Prm.Style, Prm.Sldr_W or Df.KnobRadius, 0, Disabled, Prm.FontSize, Prm.Lbl_Pos or 'Bottom', Prm.V_Pos)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Knob', curX, CurY)
                                elseif Prm.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider') then
                                    AddSlider(ctx, '##' .. Prm.Name .. FX_Name, Prm.CustomLbl, Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Style, Prm.Sldr_W or 15, 0, Disable, 'Vert', GrabSize, Prm.Lbl, nil, Prm.Sldr_H or 160)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'V-Slider', curX, CurY)
                                elseif Prm.Type == 'Switch' then
                                    AddSwitch(LT_Track, FX_Idx, Prm.V or 0, Prm.Num, Prm.BgClr, Prm.CustomLbl or 'Use Prm Name as Lbl', Fx_P, F_Tp, Prm.FontSize, FxGUID)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Switch', curX, CurY)
                                elseif Prm.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag') then
                                    AddDrag(ctx, '##' .. Prm.Name .. FX_Name, Prm.CustomLbl or Prm.Name, Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Prm.Style, Prm.Sldr_W or FX.Def_Sldr_W[FxGUID] or Df.Sldr_W, -1, Disable, Lbl_Clickable, Prm.Lbl_Pos, Prm.V_Pos, Prm.DragDir)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Drag', curX, CurY)
                                elseif Prm.Type == 'Selection' then
                                    AddCombo(ctx, LT_Track, FX_Idx, Prm.Name .. FxGUID .. '## actual', Prm.Num, FP.ManualValuesFormat or 'Get Options', Prm.Sldr_W, Prm.Style, FxGUID, Fx_P, FP.ManualValues)
                                    MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Selection', curX, CurY)
                                end
                                return pos
                            end

                            local function Item_Interaction()
                                if im.IsItemClicked(ctx) and LBtnDC then
                                    if Mods == 0 then
                                        local dir_path = CurrentDirectory .. 'src'
                                        local file_path = ConcatPath(dir_path, 'FX Default Values.ini')
                                        local file = io.open(file_path, 'r')

                                        if file then
                                            local FX_Name = ChangeFX_Name(FX_Name)
                                            Content = file:read('*a')
                                            local Ct = Content
                                            local P_Num = Prm.Num
                                            local _, P_Nm = r.TrackFX_GetParamName(LT_Track, FX_Idx, P_Num)
                                            local Df = RecallGlobInfo(Ct, P_Num .. '. ' .. P_Nm .. ' = ', 'Num')
                                            if Df then
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, Df)
                                                ToDef = { ID = FX_Idx, P = P_Num, V = Df }
                                            end
                                        end
                                    elseif Mods == Alt then
                                        if Prm.Deletable then
                                            DeletePrm(FxGUID, Fx_P, FX_Idx)
                                        end

                                    end


                                end
                            end
                            local function Double_Click_To_Reset_Value()
                                if ToDef.ID and ToDef.V then
                                    r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef.V)
                                    if Prm.WhichCC then
                                        if Trk.Prm.WhichMcros[Prm.WhichCC .. TrkID] then
                                            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, ToDef.ID,
                                                "param." .. ToDef.P .. ".plink.active", 0) -- 1 active, 0 inactive
                                            r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef.V)
                                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. ToDef.P .. 'Value before modulation', ToDef.V, true)
                                            r.gmem_write(7, Prm.WhichCC) --tells jsfx to retrieve P value
                                            PM.TimeNow = r.time_precise()
                                            r.gmem_write(11000 + Prm.WhichCC, ToDef.V)
                                            ParameterMIDILink(ToDef.ID, ToDef.P, 1, false, 15, 16, 176, Prm.WhichCC, false)
                                        end
                                    end
                                    Prm.V = ToDef.V

                                    ToDef = {}
                                end
                            end

                            ------ EXECUTION -----
                            local pos = Create_Item()
                            


                            --Draw_Attached_Drawings(FP,FX_Idx, pos)
                            Item_Interaction()
                            Double_Click_To_Reset_Value()


                        end
                        if im.IsItemClicked(ctx, 1) and Mods == 0 and not AssigningMacro then
                            local draw_list = im.GetForegroundDrawList(ctx)
                            local mouse_pos = { im.GetMousePos(ctx) }
                            local click_pos = { im.GetMouseClickedPos(ctx, 0) }
                            im.DrawList_AddLine(draw_list, click_pos[1], click_pos[2], mouse_pos[1],
                                mouse_pos[2], 0xB62424FF, 4.0) -- Draw a line between the button and the mouse cursor
                            local P_Num = Prm.Num
                            lead_fxid = FX_Idx                             -- storing the original fx id
                            fxidx = FX_Idx                         -- to prevent an error in layout editor function by not changing FX_Idx itself
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



                
            end

            Disable_If_LayEdit('End')
            Do_PluginScripts()


            if FX.Enable[FX_Idx] == false then
                im.DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B, 0x00000088)
            end

            Container_CollapseIfTab(FxGUID, FX_Idx)
            

            WindowSize = im.GetWindowSize(ctx)

            im.Dummy(ctx, 100, 100)
            im.EndChild(ctx)
            
        end

    end



    Make_Window()

    im.PopStyleVar(ctx) -- styleVar ScrollBar


    --------------------FX Devices--------------------
    CurPos_Aftr_Create_FX_Win = {im.GetCursorPos(ctx)}
    

    im.PopStyleColor(ctx, poptimes) -- -- PopColor #1 FX Window
    im.SameLine(ctx, nil, 0)
    CurPos_Aftr_Create_FX_Win_SL = {im.GetCursorPos(ctx)}


    im.SameLine(ctx, nil, 0)


    im.EndGroup(ctx)
    SL(nil,0)
    im.Dummy(ctx, 0, 0)
    if BlinkFX == FX_Idx then BlinkFX = BlinkItem(0.2, 2, BlinkFX) end

    if Parallel and Parallel == 'Mixer Layout - Show'  then 
        return Parallel
    end
    
    return WindowSize
end --of Create fx window function

--------------==  Space between FXs--------------------
function AddSpaceBtwnFXs(FX_Idx, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container,
                         AdditionalWidth, FX_Idx_in_Container, AddPlusSign)
    local SpcIsInPre, Hide, SpcInPost, MoveTarget
    local WinW


    if FX_Idx == 0 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx = 1 end
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
    if string.find( FX_Name , 'FXD Containr Macro') then

        return nil
    end 

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
        if im.BeginChild(ctx, '##SpaceBetweenWindows' .. FX_Idx .. tostring(SpaceIsBeforeRackMixer) .. 'Last SPC in Rack = ' .. tostring(AddLastSPCinRack), w, 220) then
            --HOVER_RECT = im.IsWindowHovered(ctx,  im.HoveredFlags_RectOnly)
            HoverOnWindow = im.IsWindowHovered(ctx, im.HoveredFlags_AllowWhenBlockedByActiveItem)
            WinW          = im.GetWindowSize(ctx)


            if HoverOnWindow == true and Dragging_TrueUntilMouseUp ~= true and DragDroppingFX ~= true and AssignWhichParam == nil and Is_ParamSliders_Active ~= true and Wet.ActiveAny ~= true and Knob_Active ~= true and not Dvdr.JustDroppedFX and LBtn_MousdDownDuration < 0.2 
                or Sel_Track_FX_Count == 0 or AddLastSpace  then
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
                local BtnSign =  AddPlusSign and '+' or ''
                im.PushFont(ctx, Arial_30)
                im.PushStyleColor(ctx, im.Col_Button, 0x00000000)
                BTN_Btwn_FXWindows = im.Button(ctx, BtnSign..'##Button between Windows', w, 220)
                im.PopStyleColor(ctx)
                im.PopFont(ctx)
                local l ,t = im.GetItemRectMin(ctx)

                FX_Insert_Pos = FX_Idx

                if BTN_Btwn_FXWindows then
                    FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')
                    local x, y = im.GetCursorScreenPos(ctx)
                    im.SetNextWindowPos(ctx, x+10 , y - 230)
                    im.OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx)
                end
                im.PopStyleColor(ctx, 2)
                Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                if AddPlusSign then 
                    local L, T, R, B, w, h = HighlightSelectedItem(nil, 0xffffff77, 0, nil,nil,nil,nil, nil, nil , 4, 4, 'GetItemRect', nil, nil, 4) 
                end
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

                
                local function If_FX_Is_Parallel()

                    local FX_Idx = tonumber(payload)
                    local rv , ret = r.TrackFX_GetNamedConfigParm(LT_Track,FX_Idx, 'parallel') 
                    if rv and ret == '1' then return true 
                    end
                end

                if If_FX_Is_Parallel() then allowDropNext = true  end 

                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 0 else offset = 0 end





                if (DragFX_ID + offset == FX_Idx or DragFX_ID + offset == FX_Idx - 1) and SpaceIsBeforeRackMixer ~= true and FX.InLyr[FxGUID_DragFX] == nil and not SpcInPost and not allowDropNext
                    or (Trk[TrkID].PreFX[#Trk[TrkID].PreFX] == FxGUID_DragFX and SpaceIsBeforeRackMixer == 'End of PreFX') or DontAllowDrop then
                    im.SameLine(ctx, nil, 0)

                    Dvdr.Width[TblIdxForSpace] = 0
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


                        local function If_FX_Is_Parallel()

                            local FX_Idx = tonumber(payload)
                            local rv , ret = r.TrackFX_GetNamedConfigParm(LT_Track,FX_Idx, 'parallel') 
                            local parallel = ret == '1' and true 
                            
                            if parallel then 
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx , 'parallel', '0')
                            end
                        end

                        If_FX_Is_Parallel()


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

            end
            im.EndDragDropTarget(ctx)
        else
            Dvdr.Width[TblIdxForSpace] = 0
            Dvdr.Clr[ClrLbl] = 0x131313ff
            im.SameLine(ctx, nil, 0)
        end




        im.SameLine(ctx, nil, 0)
    end




    return WinW
end

function Draw_Background(FxGUID)

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
end

function AddKnob_Simple(ctx, label , p_value ,  Size)
    local Size = Size or 15
    local p_value = p_value or 0
    local radius_outer = Radius or Df.KnobRadius;
    local Knob_Click, Knob_RC



    local V_Font, Font = Arial_12, Font_Andale_Mono_12

    local Radius       = Radius or 0

    local pos          = { im.GetCursorScreenPos(ctx) }
    local center       = { pos[1] + radius_outer/2, pos[2] + radius_outer/2 }
    local Clr_SldrGrab = Change_Clr_A(getClr(im.Col_SliderGrabActive), -0.2)


    ClickButton = WhichClick()
    local CenteredLblPos, CenteredVPos




    local line_height = im.GetTextLineHeight(ctx)
    local draw_list = im.GetWindowDrawList(ctx)
    local f_draw_list = im.GetForegroundDrawList(ctx)

    local item_inner_spacing = { item_inner_spacing, item_inner_spacing } or
        { { im.GetStyleVar(ctx, im.StyleVar_ItemInnerSpacing) } }
    local mouse_delta = { im.GetMouseDelta(ctx) }


    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25
    local BtnOffset
    local Knob_Active



    local Active = im.InvisibleButton(ctx, label or '##', Size*2, Size*2, ClickButton) -- ClickButton to alternate left/right dragging

    if ClickButton == im.ButtonFlags_MouseButtonLeft then                                -- left drag to adjust parameters
        if im.BeginDragDropSource(ctx, im.DragDropFlags_SourceNoPreviewTooltip) then
            im.SetDragDropPayload(ctx, 'my_type', 'my_data')
            Knob_Active  = true
            Clr_SldrGrab = getClr(im.Col_Text)

            HideCursorTillMouseUp(0)
            im.SetMouseCursor(ctx, im.MouseCursor_None)
            if -mouse_delta[2] ~= 0.0 then
                local stepscale = 1
                if Mods == Shift then stepscale = 3 end
                local step = --[[ (v_max - v_min) ]] 1 / (200.0 * stepscale)
                p_value = p_value + (-mouse_delta[2] * step)

                p_value = SetMinMax(p_value , 0 , 1 )

                value_changed = true
                --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
                --MvingP_Idx = F_Tp
                --Tweaking = P_Num .. FxGUID
            end
            im.EndDragDropSource(ctx)
        end
        --[[ elseif ClickButton == im.ButtonFlags_MouseButtonRight and not AssigningMacro then -- right drag to link parameters
        DnD_PLink_SOURCE(FX_Idx, P_Num) ]]
    end
     
    if im.IsItemClicked(ctx, 1 ) then 
        Knob_Click = 2 
    end 

    if Knob_Active then Knob_Click = 1 end 
    KNOB = true

    --ButtonDraw(FX[FxGUID].BgClr or CustomColorsDefault.FX_Devices_Bg, center, radius_outer)
    --[[ local focused_window, hwnd = GetFocusedWindow()
    if focused_window == "FX Devices" then
        r.JS_Window_SetFocus(hwnd)
        AdjustParamWheel(LT_Track, FX_Idx, P_Num)
    end ]]


    local radius_outer = Size
    local t = p_value
    local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
    local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
    local radius_inner = radius_outer * 0.40
    if Active then 
        im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, 0xffffff88)
    end     

        im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer,im.GetColor(ctx, im.Col_Button))
        im.DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner,
            center[2] + angle_sin * radius_inner,
            center[1] + angle_cos * (radius_outer - 2), center[2] + angle_sin * (radius_outer - 2), Clr_SldrGrab,  2)
        im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 2, ANGLE_MIN, angle)
        im.DrawList_PathStroke(draw_list, 0x99999922, nil, radius_outer * 0.6)
        im.DrawList_PathClear(draw_list)
        im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_inner,
            im.GetColor(ctx,
                is_active and im.Col_FrameBgActive or is_hovered and im.Col_FrameBgHovered or
                im.Col_FrameBg))

     
    return Knob_Click, p_value, center
end

function Draw_Simple_Knobs_Arc (center, clr, radius)
    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25
    local draw_list = im.GetWindowDrawList(ctx)

    im.DrawList_PathArcTo(draw_list, center[1], center[2], radius / 2, ANGLE_MIN, ANGLE_MAX)
    im.DrawList_PathStroke(draw_list, clr, nil, radius * 0.6)
    im.DrawList_PathClear(draw_list)
end 


function AddSpaceBtwnFXs_FIRST(FX_Idx, FxGUID)
    if not tablefind(Trk[TrkID].PostFX, FxGUID) and FXGUID[FX_Idx] ~= FXGUID[FX_Idx - 1] then
        if FX.InLyr[FXGUID_To_Check_If_InLayer] == nil           --not in layer
            and FindStringInTable(BlackListFXs, FX_Name) ~= true -- not blacklisted
            and string.find(FX_Name, 'RackMixer') == nil
            and FX_Idx ~= RepeatTimeForWindows                   --not last fx
            and not FX[FxGUID].InWhichBand --[[Not in Band Split]] then

            local rv , ret = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'parallel')
            if rv and ret == '1'  then 
                return 
            end
            
            local Idx = FX_Idx
            if FX_Idx == 1 then
                local Nm = FX.Win_Name[0]
                if Nm == 'JS: FXD Macros' or FindStringInTable(BlackListFXs, Nm) then Idx = 0 end
            end
            local CurX = im.GetCursorPosX(ctx)

            local SpcW = AddSpaceBtwnFXs(Idx)
        elseif FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] and FXGUID[FX_Idx] then
            AddSpaceBtwnFXs(FX_Idx, true)
        elseif FX_Idx == RepeatTimeForWindows then
        end
    end
end



function If_No_LT_Track()

    if  LT_Track == nil then
        local Viewport = im.GetWindowViewport(ctx)
        im.DrawList_AddTextEx(VP.FDL, Font_Andale_Mono_20_B, 20, VP.X, VP.Y + VP.h / 2, 0xffffffff, 'Select a track to start')
    end 

end 


function If_New_FX_Is_Added()


        -- if new fx is added
    if RepeatTimeForWindows ~= r.TrackFX_GetCount(LT_Track) and not layoutRetrieved then
        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
        --TREE = BuildFXTree(tr)
    end
end 

function MouseBtnIcon(lbl, img)
    im.BeginDisabled(ctx)
    im.ImageButton(ctx, lbl ..'## Mouse' , img,12,16, nil,nil,nil,nil,nil,0xffffffff)
    im.EndDisabled(ctx)
end



function Show_Helper_Message()
    if HelperMsg  then
        local WDL = im.GetWindowDrawList(ctx)
        local sz = 18


        local function Set_Help_Text(img, msg, modifier, modifier_str)
            if not msg then  return end
            local function AddImg(img)
                local x , y = im.GetCursorScreenPos(ctx)
                local y = y - sz/3
                im.Dummy(ctx, sz,sz*1.4)
                local w, h = im.GetItemRectSize(ctx)
                im.DrawList_AddImage(WDL,img  , x, y, x+w, y + h , nil,nil,nil,nil,0xffffffff) --1.4 is the mouse button's x y ratio
                SL()
            end
            if modifier then    
                if HelperMsg.Need_Add_Mouse_Icon then 
                    AddImg(Img['Mouse'..HelperMsg.Need_Add_Mouse_Icon])
                end 
                MyText('+') SL()
                MyText( modifier)
                Highlight_Itm(WDL , nil, im.GetColor(ctx,im.Col_Text), 1, 2)

                SL()
                --[[ MyText(' : ')
                SL() ]]
            end
            
            if img then 
                AddImg(img)
            end
            
            MyText(': '.. msg)
            SL(nil, sz*1.5 )

            
        end
        Set_Help_Text(Img.MouseL, HelperMsg.L)
        Set_Help_Text(nil, HelperMsg.Ctrl_L, 'Ctrl')
        Set_Help_Text(nil, HelperMsg.Alt_L, 'Alt')
        Set_Help_Text(nil, HelperMsg.Shift_L, 'Shift')

        if HelperMsg.Need_separator then 
            MyText('  |  ')
            SL()
        end
        Set_Help_Text(Img.MouseR, HelperMsg.R)

        Set_Help_Text(nil, HelperMsg.Ctrl_R, 'Ctrl')
        Set_Help_Text(nil, HelperMsg.Alt_R, 'Alt')
        Set_Help_Text(nil, HelperMsg.Shift_R, 'Shift')







            --[[ if HelperMsg.L  then 
                local x , y = im.GetCursorScreenPos(ctx)
                local y = y - sz/2
                im.Dummy(ctx, sz,sz*1.4)
                local w, h = im.GetItemRectSize(ctx)
                im.DrawList_AddImage(WDL,Img.MouseL  , x, y, x+w, y + h , nil,nil,nil,nil,0xffffffff) --1.4 is the mouse button's x y ratio
                SL()
                
                MyText(': '.. HelperMsg.L)
                SL(nil,sz *2)
            end 
            if HelperMsg.R then 
                local x , y = im.GetCursorScreenPos(ctx)
                local y = y - sz/2
                im.Dummy(ctx, sz,sz*1.4)
                local w, h = im.GetItemRectSize(ctx)
                im.DrawList_AddImage(WDL,Img.MouseR  , x, y, x+w, y + h , nil,nil,nil,nil,0xffffffff) --1.4 is the mouse button's x y ratio
                SL()
                
                MyText(': '.. HelperMsg.R)
                SL(nil,sz *2)
            end ]]



       
       


    end

    end