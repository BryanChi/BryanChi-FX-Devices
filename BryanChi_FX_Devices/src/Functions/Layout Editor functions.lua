-- @noindex
Size_Sync_Properties= {'Width_SS', 'Rad_In_SS', 'Rad_Out_SS'}  --- used when user drag node to resize items

function Sync_Size_Height_Synced_Properties(FP, diff)
    if FP.Draw then     
        for I, V in ipairs(FP.Draw) do 
            for i, v in ipairs(Size_Sync_Properties) do 
                if V[v] then 
                    V[string.sub(v,1, -4)] =V[string.sub(v,1, -4)] + diff
                else
                end
            end 
        end 
    end 
end



function Sync_Height_Synced_Properties(FP, diff, Table)
    if FP.Draw  then  
        local rt = 2    
        if FP.Type == 'V-Slider' then
            rt = 1 
        end
        for I, V in ipairs(FP.Draw) do 
            if V.Height_SS then 
                V.Height =  V.Height + diff * rt
            end
        end
    end 
end



local function GetPayload()
    local retval, dndtype, payload = im.GetDragDropPayload(ctx)
    if retval then
        return dndtype, payload
    end
end

function Show_Value_Tooltip(trigger, x, y , V )
    if trigger then 

        local SzX, SzY = im.GetItemRectSize(ctx)
        local MsX, MsY = im.GetMousePos(ctx)

        im.SetNextWindowPos(ctx,x, y)
        im.BeginTooltip(ctx)
        im.Text(ctx, V)
        im.EndTooltip(ctx)

    end 
end

function Highlight_Prm_If_User_Use_Actual_UI_To_Tweak(draw_list, PosL, PosT, PosR, PosB, FP,FxGUID)
    if LT_ParamNum == FP.Num and focusedFXState == 1 and LT_FXGUID == FxGUID  then
        if not FP.WhichCC then 
            local LT_ParamValue = r.TrackFX_GetParamNormalized(LT_Track, LT_FX_Number, LT_ParamNum)
            FP.V = LT_ParamValue
        end

        im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosR, PosB, 0x99999922, Rounding)
        im.DrawList_AddRect(draw_list, PosL, PosT, PosR, PosB, 0x99999966, Rounding)

        for m = 1, 8, 1 do
            if AssigningMacro == m then
                im.PopStyleColor(ctx, 2)
            end
        end
    end
end

function CheckDnDType()
    local dnd_type = GetPayload()
    DND_ADD_FX = dnd_type == "DND ADD FX"
    DND_MOVE_FX = dnd_type == "DND MOVE FX"
    FX_DRAG = dnd_type == "FX_Drag"
    FX_PLINK = dnd_type == "FX PLINK"
end


function If_Draw_Mode_Is_Active(FxGUID, Win_L, Win_T, Win_R, Win_B, FxNameS)
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
end

local min, max = math.min, math.max
function IncreaseDecreaseBrightness(color, amt, no_alpha)
    function AdjustBrightness(channel, delta)
        return min(255, max(0, channel + delta))
    end

    local alpha = color & 0xFF
    local blue = (color >> 8) & 0xFF
    local green = (color >> 16) & 0xFF
    local red = (color >> 24) & 0xFF

    red = AdjustBrightness(red, amt)
    green = AdjustBrightness(green, amt)
    blue = AdjustBrightness(blue, amt)
    alpha = no_alpha and alpha or AdjustBrightness(alpha, amt)

    return (alpha) | (blue << 8) | (green << 16) | (red << 24)
end

function CalculateColor(color)
    local alpha = color & 0xFF
    local blue = (color >> 8) & 0xFF
    local green = (color >> 16) & 0xFF
    local red = (color >> 24) & 0xFF

    local luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255
    return luminance > 0.5 and (PLink_Edge_LightBG or CustomColorsDefault.PLink_Edge_LightBG) or
        (PLink_Edge_DarkBG or CustomColorsDefault.PLink_Edge_DarkBG)
end

function Align_Text_To_Center_Of_X(text, width, x_offset, y_offset)
    local CurX = im.GetCursorPosX(ctx)
    local w = im.CalcTextSize(ctx, text)
    im.SetCursorPosX(ctx, CurX - w / 2 + width / 2 + (x_offset or 0))
    if y_offset and y_offset ~= 0  then 
        local CurY = im.GetCursorPosY(ctx)
        im.SetCursorPosY(ctx, CurY+ (y_offset or 0))
    end 
    --MyText(text, _G[Font], LblClr)
end 


function ButtonDraw(color, center, radius_outer) -- for drawing to clarify which destination (target) DND goes to
    color = im.IsItemHovered(ctx) and IncreaseDecreaseBrightness(color, 30) or color
    local draw_list = im.GetWindowDrawList(ctx)
    local f_draw_list = im.GetForegroundDrawList(ctx)
    local xs, ys = im.GetItemRectMin(ctx)
    local xe, ye = im.GetItemRectMax(ctx)

    local edge_color = CalculateColor(color)

    if FX_PLINK and im.IsMouseHoveringRect(ctx, xs, ys, xe, ye) then
        if KNOB then
            im.DrawList_AddCircle(f_draw_list, center[1], center[2], radius_outer,
                im.GetColorEx(ctx, edge_color), 16, 5)
        else
            local x_offset = 2
            im.DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset,
                im.GetColorEx(ctx, edge_color), 2, nil, 5)
        end
    end
end

 function WhichClick() -- to alternate left and right click flags for InvisibleButton
    if im.IsMouseClicked(ctx, 0) then
        ClickButton = im.ButtonFlags_MouseButtonLeft
    elseif im.IsMouseClicked(ctx, 1) then
        ClickButton = im.ButtonFlags_MouseButtonRight
    end
    return ClickButton
end

---@param FX_Idx integer
---@param P_Num number
local function DnD_PLink_SOURCE(FX_Idx, P_Num)
    if im.BeginDragDropSource(ctx) and not AssigningMacro then
        local draw_list = im.GetForegroundDrawList(ctx)
        local mouse_pos = { im.GetMousePos(ctx) }
        local click_pos = { im.GetMouseClickedPos(ctx, 1) }
        im.DrawList_AddLine(draw_list, click_pos[1], click_pos[2], mouse_pos[1], mouse_pos[2],
            PLink or CustomColorsDefault.PLink, 4.0) -- Draw a line between the button and the mouse cursor
        lead_fxid = FX_Idx                                   -- storing the original fx id
        fxidx = FX_Idx                                   -- to prevent an error in layout editor function by not changing FX_Idx itself
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
        local data = lead_fxid .. "," .. lead_paramnumber
        im.SetDragDropPayload(ctx, 'FX PLINK', data)
        local _, param_name = r.TrackFX_GetParamName(LT_Track, lead_fxid, lead_paramnumber)
        local retval, fx_name = r.TrackFX_GetNamedConfigParm(LT_Track, lead_fxid, "fx_name")
        im.Text(ctx, fx_name .. " " .. param_name) -- To preview what FX + parameter we are dragging
        im.EndDragDropSource(ctx)
    end
end

---@param FxGUID string
---@param Fx_P integer
---@param FX_Idx integer
---@param P_Num number
local function DnD_PLink_TARGET(FxGUID, Fx_P, FX_Idx, P_Num)
    im.PushStyleColor(ctx, im.Col_DragDropTarget, 0) -- 0 = To disable yellow rect which is on by default
    if im.BeginDragDropTarget(ctx) then
        local rv, payload = im.AcceptDragDropPayload(ctx, 'FX PLINK')
        local lead_fxid, lead_paramnumber = payload:match("(.+),(.+)")
        if rv then
            local rv, bf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus")
            if bf == "15" then                                                                            -- reset FX Devices' modulation bus/chan
                r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 0) -- reset bus and channel because it does not update automatically although in parameter linking midi_* is not available
                r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 1)
                r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -1)
                r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 0)
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
                fxidx = FX_Idx       -- to prevent an error in layout editor function by not changing FX_Idx itself
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
                        r.TrackFX_SetNamedConfigParm(LT_Track, root_container, "param." .. buf .. ".plink.active", 0)
                        r.TrackFX_SetNamedConfigParm(LT_Track, root_container, "param." .. buf .. ".plink.effect", -1)
                        r.TrackFX_SetNamedConfigParm(LT_Track, root_container, "param." .. buf .. ".plink.param", -1)
                        local rv, container_id = r.TrackFX_GetNamedConfigParm(LT_Track, follow_fxid, "parent_container")
                        while rv do -- removing map
                            _, buf = r.TrackFX_GetNamedConfigParm(LT_Track, container_id,
                                "container_map.get." .. follow_fxid .. "." .. follow_paramnumber)
                            r.TrackFX_GetNamedConfigParm(LT_Track, container_id,
                                "param." .. buf .. ".container_map.delete")
                            rv, container_id = r.TrackFX_GetNamedConfigParm(LT_Track, container_id, "parent_container")
                        end
                    else                                                                      -- new fx and parameter
                        local rv, buf = r.TrackFX_GetNamedConfigParm(LT_Track, root_container,
                            "container_map.add." .. follow_fxid .. "." .. follow_paramnumber) -- map to the root
                        r.TrackFX_SetNamedConfigParm(LT_Track, root_container, "param." .. buf .. ".plink.active", 1)
                        r.TrackFX_SetNamedConfigParm(LT_Track, root_container, "param." .. buf .. ".plink.effect",
                            lead_fxid) -- Link (root container + new mapped container parameter) to lead FX
                        r.TrackFX_SetNamedConfigParm(LT_Track, root_container, "param." .. buf .. ".plink.param",
                            lead_paramnumber)
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
                    r.TrackFX_SetNamedConfigParm(LT_Track, follow_fxid, "param." .. follow_paramnumber .. ".plink.active",
                        value)
                    r.TrackFX_SetNamedConfigParm(LT_Track, follow_fxid, "param." .. follow_paramnumber .. ".plink.effect",
                        lead_fxid)
                    r.TrackFX_SetNamedConfigParm(LT_Track, follow_fxid, "param." .. follow_paramnumber .. ".plink.param",
                        lead_paramnumber)
                end
            end
        end
        im.EndDragDropTarget(ctx)
    end
    im.PopStyleColor(ctx)
end

local function GetSetParamValues(track, fxidx, parm, drag_delta, step)
    local p_value = r.TrackFX_GetParamNormalized(track, fxidx, parm)
    local p_value = p_value + (drag_delta * step)
    if p_value < 0 then p_value = 0 end
    if p_value > 1 then p_value = 1 end
    r.TrackFX_SetParamNormalized(track, fxidx, parm, p_value)
end

local function AdjustParamValue(LT_Track, FX_Idx, P_Num, stepscale)
    local step = (1 - 0) / (200.0 * stepscale)
    GetSetParamValues(LT_Track, FX_Idx, P_Num, (4 * Wheel_V), step)
end

local function AdjustParamWheel(LT_Track, FX_Idx, P_Num)
    if Ctrl_Scroll then
        if im.IsItemHovered(ctx) and Mods == 0 and not im.IsItemActive(ctx) then -- mousewheel to change values
            AdjustParamValue(LT_Track, FX_Idx, P_Num, 1)
            --ParameterTooltip(FX_Idx, P_Num)
        elseif im.IsItemHovered(ctx) and Mods == Shift and not im.IsItemActive(ctx) then -- mousewheel to change values slightly
            AdjustParamValue(LT_Track, FX_Idx, P_Num, 6)
        end
    else
        if im.IsItemHovered(ctx) and Mods == Ctrl and not im.IsItemActive(ctx) then -- mousewheel to change values
            AdjustParamValue(LT_Track, FX_Idx, P_Num, 1)
            --ParameterTooltip(FX_Idx, P_Num)
        elseif im.IsItemHovered(ctx) and Mods == Ctrl + Shift and not im.IsItemActive(ctx) then -- mousewheel to change values slightly
            AdjustParamValue(LT_Track, FX_Idx, P_Num, 6)
        end
    end
end


function Layout_Edit_Properties_Window(fx, FX_Idx)
    local FxGUID = r.TrackFX_GetFXGUID( LT_Track, FX_Idx)
    if FX.LayEdit == FxGUID then
        HelperMsg.R = 'Marquee Select Items'
        HelperMsg.Shift_R = 'Add Marquee to Selection'

        im.PushStyleColor(ctx, im.Col_HeaderHovered, 0xffffff00)
        im.PushStyleColor(ctx, im.Col_HeaderActive, 0xffffff00)

        local FxGUID = FXGUID[FX_Idx]

        if not CloseLayEdit and im.Begin(ctx, 'LayoutEdit Propertiess', true, im.WindowFlags_NoCollapse + im.WindowFlags_NoTitleBar + im.WindowFlags_NoDocking) then
            --if not CloseLayEdit   then    ----START CHILD WINDOW------
            DisableScroll = true



            if im.Button(ctx, 'Save') then
                SaveLayoutEditings(FX_Name, FX_Idx, FXGUID[FX_Idx])
                CloseLayEdit = true; FX.LayEdit = nil
            end
            SL()
            if im.Button(ctx, 'Exit##Lay') then
                im.OpenPopup(ctx, 'Save Editing?')
            end
            SL()

            if LE.Sel_Items[1] then
                local I = FX[FxGUID][LE.Sel_Items[1]]
                if im.Button(ctx, 'Delete') then
                    local tb = {}

                    for i, v in pairs(LE.Sel_Items) do
                        tb[i] = v
                    end
                    table.sort(tb)

                    for i = #tb, 1, -1 do
                        DeletePrm(FxGUID, tb[i], FX_Idx)
                    end

                    if not FX[FxGUID][1] then FX[FxGUID].AllPrmHasBeenDeleted = true else FX[FxGUID].AllPrmHasBeenDeleted = nil end


                    LE.Sel_Items = {}
                end

                SL(nil, 30)

                if im.Button(ctx, 'Copy Properties') then
                    CopyPrm = {}
                    CopyPrm = I
                end

                SL()
                if im.Button(ctx, 'Paste Properties') then
                    for i, v in pairs(LE.Sel_Items) do
                        local I = FX[FxGUID][v]
                        I.Type        = CopyPrm.Type
                        I.Sldr_W      = CopyPrm.Sldr_W
                        I.Style       = CopyPrm.Style
                        I.V_FontSize  = CopyPrm.V_FontSize
                        --I.CustomLbl   = CopyPrm.CustomLbl
                        I.FontSize    = CopyPrm.FontSize
                        I.Sldr_H      = CopyPrm.Sldr_H
                        I.BgClr       = CopyPrm.BgClr
                        I.GrbClr      = CopyPrm.GrbClr
                        I.Lbl_Pos     = CopyPrm.Lbl_Pos
                        I.Lbl_Pos_X   = CopyPrm.Lbl_Pos_X
                        I.Lbl_Pos_Y   = CopyPrm.Lbl_Pos_Y
                        I.V_Pos       = CopyPrm.V_Pos
                        I.Lbl_Clr     = CopyPrm.Lbl_Clr
                        I.V_Clr       = CopyPrm.V_Clr
                        I.DragDir     = CopyPrm.DragDir
                        I.Value_Thick = CopyPrm.Value_Thick
                        I.V_Pos_X     = CopyPrm.V_Pos_X
                        I.V_Pos_Y     = CopyPrm.V_Pos_Y
                        I.ImagePath   = CopyPrm.ImagePath
                        I.Height      = CopyPrm.Height
                        if CopyPrm.Draw then
                            -- use this line to pool
                            --I.Draw = CopyPrm.Draw

                            I.Draw = I.Draw or {}
                            for i, v in pairs(CopyPrm.Draw) do
                                I.Draw[i] = I.Draw[i] or {}
                                for d, v in pairs(v) do
                                    I.Draw[i][d] = v
                                end
                            end
                        end
                    end
                end
            end
            SL(nil, 30)

            if Draw.DrawMode[FxGUID] then
                if im.Button(ctx, 'Exit Background Edit') then Draw.DrawMode[FxGUID] = false end
            else
                if im.Button(ctx, 'Enter Background Edit') then
                    Draw.DrawMode[FxGUID] = true
                    if Draw[FX.Win_Name_S[FX_Idx]] == nil then
                        Draw[FX.Win_Name_S[FX_Idx]] = {
                            Rect = {},
                            clr = {},
                            ItemInst = {},
                            L = {},
                            R = {},
                            Y = {},
                            T = {},
                            B = {},
                            Type = {},
                            FxGUID = {},
                            Txt = {}
                        }
                    end
                    LE.Sel_Items = {}
                end
            end




            im.Separator(ctx)


            local ColorPaletteTop = im.GetCursorPosY




            -- Add Drawings ----
            if not LE.Sel_Items[1] then
                if Draw.DrawMode[FxGUID] ~= true then
                    im.TextWrapped(ctx, 'Select an item to start editing')
                    AddSpacing(15)
                else
                    im.Text(ctx, '(!) Hold down Left button to Draw in FX Devices')
                    AddSpacing(5)
                    im.Text(ctx, 'Type:')
                    im.SameLine(ctx)
                    im.PushStyleColor(ctx, im.Col_FrameBg, 0x99999933)
                    local D = Draw[FX.Win_Name_S[FX_Idx]]
                    FX[FxGUID].Draw = FX[FxGUID].Draw or {}
                    local D = FX[FxGUID].Draw
                    local FullWidth = -50

                    local typelbl; local It = Draw.SelItm
                    --D[It or 1] = D[It or 1] or {}


                    if Draw.SelItm then typelbl = D[It].Type end
                    if Draw.Type == nil then Draw.Type = 'line' end
                    im.SetNextItemWidth(ctx, FullWidth)
                    if im.BeginCombo(ctx, '##', typelbl or Draw.Type or 'line', im.ComboFlags_NoArrowButton) then
                        local function setType(str)
                            if im.Selectable(ctx, str, false) then
                                if It then D[It].Type = str end
                                Draw.Type = str
                            end
                        end
                        setType('Picture')
                        setType('line')
                        setType('V-line')
                        setType('rectangle')
                        setType('rect fill')
                        setType('circle')
                        setType('circle fill')
                        setType('Text')

                        im.EndCombo(ctx)
                    end

                    if It then
                        im.Text(ctx, 'Color :')
                        im.SameLine(ctx)
                        if Draw.SelItm and D[It].clr then
                            clrpick, D[It].clr = im.ColorEdit4(ctx, '##',
                                D[It].clr or 0xffffffff,
                                im.ColorEditFlags_NoInputs|
                                im.ColorEditFlags_AlphaPreviewHalf|
                                im.ColorEditFlags_AlphaBar)
                        else
                            clrpick, Draw.clr = im.ColorEdit4(ctx, '##',
                                Draw.clr or 0xffffffff,
                                im.ColorEditFlags_NoInputs|
                                im.ColorEditFlags_AlphaPreviewHalf|
                                im.ColorEditFlags_AlphaBar)
                        end
                        im.Text(ctx, 'Default edge rounding :')
                        im.SameLine(ctx)
                        im.SetNextItemWidth(ctx, 40)

                        FX[FxGUID].Draw = FX[FxGUID].Draw or {}
                        EditER, FX[FxGUID].Draw.Df_EdgeRound = im.DragDouble(ctx,
                            '##' .. FxGUID,
                            FX[FxGUID].Draw.Df_EdgeRound, 0.05, 0, 30, '%.2f')



                        if D[It].Type == 'Picture' then
                            im.Text(ctx, 'File Path:')
                            SL()
                            DragDropPics = DragDropPics or {}

                            if im.BeginChildFrame(ctx, '##drop_files', FullWidth, 40) then
                                if not D[It].FilePath then
                                    im.Text(ctx, 'Drag and drop files here...')
                                else
                                    im.Text(ctx, D[It].FilePath)

                                    if im.SmallButton(ctx, 'Clear') then

                                    end
                                end
                                if D[It].FilePath then
                                    im.Bullet(ctx)
                                    im.TextWrapped(ctx, D[It].FilePath)
                                end
                                im.EndChildFrame(ctx)
                            end


                            if im.BeginDragDropTarget(ctx) then
                                local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                                if rv then
                                    for i = 0, count - 1 do
                                        local filename
                                        rv, filename = im.GetDragDropPayloadFile(ctx, i)
                                        D[It].FilePath = filename

                                        D[It].Image = im.CreateImage(filename)
                                        im.Attach(ctx, D[It].Image)
                                    end
                                end
                                im.EndDragDropTarget(ctx)
                            end

                            rv, D[It].KeepImgRatio = im.Checkbox(ctx, 'Keep Image Ratio',
                                D[It].KeepImgRatio)
                        end

                        if Draw.SelItm then
                            im.Text(ctx, 'Start Pos X:')
                            im.SameLine(ctx)
                            local CurX = im.GetCursorPosX(ctx)
                            im.SetNextItemWidth(ctx, FullWidth)
                            _, D[It].L = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'L',
                                D[It].L,
                                1, 0, Win_W, '%.0f')
                            if D[It].Type ~= 'V-line' and D[It].Type ~= 'circle' and D[It].Type ~= 'circle fill' then
                                im.Text(ctx, 'End Pos X:')
                                im.SetNextItemWidth(ctx, FullWidth)

                                im.SameLine(ctx, CurX)
                                _, D[It].R = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                    D[It].R, 1, 0, Win_W, '%.0f')
                            end

                            if D[It].Type == 'circle' or D[It].Type == 'circle fill' then
                                im.Text(ctx, 'Radius:')
                                im.SameLine(ctx)
                                im.SetNextItemWidth(ctx, FullWidth)
                                _, D[It].R = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                    D[It].R, 1, 0, Win_W, '%.0f')
                            end


                            im.Text(ctx, 'Start Pos Y:')

                            im.SameLine(ctx)
                            im.SetNextItemWidth(ctx, FullWidth)

                            _, D[It].T = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'T',
                                D[It].T, 1, 0, Win_W, '%.0f')


                            if D[It].Type ~= 'line' and D[It].Type ~= 'circle fill' and D[It].Type ~= 'circle' then
                                im.Text(ctx, 'End Pos Y:')
                                im.SameLine(ctx, CurX)
                                im.SetNextItemWidth(ctx, FullWidth)

                                _, D[It].B = im.DragDouble(ctx, '##' .. It .. 'B', D[It].B, 1,
                                    0,
                                    Win_W, '%.0f')
                            end

                            if D[It].Type == 'Text' then
                                im.Text(ctx, 'Text:')
                                im.SameLine(ctx)

                                _, D[It].Txt = im.InputText(ctx, '##' .. It .. 'Txt',
                                    D[It].Txt)

                                SL()
                                im.Text(ctx, 'Font Size:')
                                local rv, Sz = im.InputInt(ctx, '## font size ' .. It,
                                    D[It].FtSize or 12)
                                if rv then
                                    D[It].FtSize = Sz
                                    if not _G['Font_Andale_Mono' .. '_' .. Sz] then
                                        _G['Font_Andale_Mono' .. '_' .. Sz] = im.CreateFont(
                                            'andale mono', Sz)
                                        ChangeFont = D[It]
                                    else
                                        D[It].Font = _G['Font_Andale_Mono' .. '_' .. Sz]
                                    end
                                end
                            end
                        end
                    end



                    im.PopStyleColor(ctx)
                end
            elseif LE.Sel_Items[1] then
                local ID, TypeID; local FrstSelItm = FX[FxGUID][LE.Sel_Items[1]]; local FItm = LE
                    .Sel_Items[1]
                local R_ofs = 50
                if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                    ID       = FxGUID .. LE.Sel_Items[1]
                    WidthID  = FxGUID .. LE.Sel_Items[1]
                    ClrID    = FxGUID .. LE.Sel_Items[1]
                    GrbClrID = FxGUID .. LE.Sel_Items[1]
                    TypeID   = FxGUID .. LE.Sel_Items[1]
                elseif LE.Sel_Items[2] then
                    local Diff_Types_Found, Diff_Width_Found, Diff_Clr_Found, Diff_GrbClr_Found
                    for i, v in pairs(LE.Sel_Items) do
                        local lastV
                        if i > 1 then
                            local frst = LE.Sel_Items[1]; local other = LE.Sel_Items[i];
                            if FX[FxGUID][1].Type ~= FX[FxGUID][v].Type then Diff_Types_Found = true end
                            --if FX[FxGUID][frst].Sldr_W ~= FX[FxGUID][v].Sldr_W then  Diff_Width_Found = true    end
                            --if FX[FxGUID][frst].BgClr  ~= FX[FxGUID][v].BgClr  then Diff_Clr_Found = true       end
                            --if FX[FxGUID][frst].GrbClr ~= FX[FxGUID][v].GrbClr then Diff_GrbClr_Found = true end
                        end
                    end
                    if Diff_Types_Found then
                        TypeID = 'Group'
                    else
                        TypeID = FxGUID .. LE.Sel_Items [1]
                    end
                    if Diff_Width_Found then
                        WidthID = 'Group'
                    else
                        WidthID = FxGUID .. LE.Sel_Items[1]
                    end
                    if Diff_Clr_Found then
                        ClrID = 'Group'
                    else
                        ClrID = FxGUID .. LE.Sel_Items[1]
                    end
                    if Diff_GrbClr_Found then
                        GrbClrID = 'Group'
                    else
                        GrbClrID = FxGUID .. LE.Sel_Items[1]
                    end
                    ID = FxGUID .. LE.Sel_Items[1]
                else
                    ID = FxGUID .. LE.Sel_Items[1]
                end
                local function FreeValuePosSettings()
                    if FrstSelItm.V_Pos ~= 'None' then
                        im.Text(ctx, 'X:')
                        SL()
                        im.SetNextItemWidth(ctx, 50)
                        local EditPosX, PosX = im.DragDouble(ctx,
                            ' ##EditValuePosX' .. FxGUID .. LE.Sel_Items[1],
                            FrstSelItm.V_Pos_X or 0,
                            0.25, nil, nil, '%.2f')
                        SL()
                        if EditPosX then
                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Pos_X = PosX end
                        end
                        im.Text(ctx, 'Y:')
                        SL()
                        im.SetNextItemWidth(ctx, 50)
                        local EditPosY, PosY = im.DragDouble(ctx,
                            ' ##EditValuePosY' .. FxGUID .. LE.Sel_Items[1],
                            FrstSelItm.V_Pos_Y or 0,
                            0.25, nil, nil, '%.2f')
                        SL()
                        if EditPosY then
                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Pos_Y = PosY end
                        end
                    end
                end

                local function FreeLblPosSettings()
                    if FrstSelItm.Lbl_Pos ~= 'None' then
                        im.Text(ctx, 'X:')
                        SL()
                        im.SetNextItemWidth(ctx, 50)
                        local EditPosX, PosX = im.DragDouble(ctx,
                            ' ##EditLblPosX' .. FxGUID .. LE.Sel_Items[1],
                            FrstSelItm.Lbl_Pos_X or 0,
                            0.25, nil, nil, '%.2f')
                        SL()
                        if EditPosX then
                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Pos_X = PosX end
                        end
                        im.Text(ctx, 'Y:')
                        SL()
                        im.SetNextItemWidth(ctx, 50)
                        local EditPosY, PosY = im.DragDouble(ctx,
                            ' ##EditLblPosY' .. FxGUID .. LE.Sel_Items[1],
                            FrstSelItm.Lbl_Pos_Y or 0,
                            0.25, nil, nil, '%.2f')
                        SL()
                        if EditPosY then
                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Pos_Y = PosY end
                        end
                    end
                end
                local function AddOption(Name, TargetVar, TypeCondition)
                    if FrstSelItm.Type == TypeCondition or not TypeCondition then
                        if im.Selectable(ctx, Name, false) then
                            for i, v in pairs(LE.Sel_Items) do
                                FX[FxGUID][v][TargetVar] =
                                    Name
                            end
                        end
                    end
                end

                -----Type--------

                local PrmTypeLbl

                if TypeID == 'Group' then
                    PrmTypeLbl = 'Multiple Values'
                else
                    PrmTypeLbl = FrstSelItm.Type or ''
                end
                if not FrstSelItm.Type then FrstSelItm.Type = FX.Def_Type[FxGUID] end
                im.Text(ctx, 'Type : '); im.SameLine(ctx); im.PushStyleColor(ctx,
                    im.Col_FrameBg, 0x444444aa)
                im.SetNextItemWidth(ctx, -R_ofs)
                if im.BeginCombo(ctx, '##', PrmTypeLbl, im.ComboFlags_NoArrowButton) then
                    local function SetItemType(Type)
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].Sldr_W = nil
                            FX[FxGUID][v].Type = Type
                        end
                    end

                    if im.Selectable(ctx, 'Slider', false) then
                        SetItemType('Slider')
                    elseif im.Selectable(ctx, 'Knob', false) then
                        SetItemType('Knob')
                    elseif im.Selectable(ctx, 'V-Slider', false) then
                        SetItemType('V-Slider')
                    elseif im.Selectable(ctx, 'Drag', false) then
                        SetItemType('Drag')
                    elseif im.Selectable(ctx, 'Switch', false) then
                        SetItemType('Switch')
                    elseif im.Selectable(ctx, 'Selection', false) then
                        SetItemType('Selection')
                    end
                    im.EndCombo(ctx)
                end

                ---Label    Show only when there's one item selected-----
                if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                    im.Text(ctx, 'Label: '); im.SameLine(ctx)
                    im.SetNextItemWidth(ctx, -R_ofs)
                    local LblEdited, buf = im.InputText(ctx,
                        ' ##Edit Title' .. FxGUID .. LE.Sel_Items[1],
                        FrstSelItm.CustomLbl or buf)
                    if im.IsItemActivated(ctx) then EditingPrmLbl = LE.Sel_Items[1] end
                    if im.IsItemDeactivatedAfterEdit(ctx) then FrstSelItm.CustomLbl = buf end
                end

                --Label Pos
                im.Text(ctx, 'Label Pos: '); im.SameLine(ctx); im.SetNextItemWidth(
                    ctx, 100)
                if im.BeginCombo(ctx, '## Lbl Pos' .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos or 'Default', im.ComboFlags_NoArrowButton) then
                    if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'V-Slider' then
                        AddOption('Top', 'Lbl_Pos')
                        AddOption('Bottom', 'Lbl_Pos')
                    elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' then
                        AddOption('Left', 'Lbl_Pos')
                        AddOption('Top', 'Lbl_Pos')
                        AddOption('Bottom', 'Lbl_Pos')
                    elseif FrstSelItm.Type == 'Selection' or FrstSelItm.Type == 'Switch' then
                        AddOption('Top', 'Lbl_Pos')
                        AddOption('Left', 'Lbl_Pos')
                        if FrstSelItm.Type == 'Switch' then AddOption('Within', 'Lbl_Pos') end
                        AddOption('Bottom', 'Lbl_Pos')
                        AddOption('Right', 'Lbl_Pos')
                        AddOption("None", 'Lbl_Pos')
                    end
                    AddOption('Free', 'Lbl_Pos')
                    im.EndCombo(ctx)
                end
                im.SameLine(ctx)
                FreeLblPosSettings()
                -- Label Color
                DragLbl_Clr_Edited, Lbl_V_Clr = im.ColorEdit4(ctx, '##Lbl Clr' ..
                    LE.Sel_Items[1], FrstSelItm.Lbl_Clr or im.GetColor(ctx, im.Col_Text),
                    im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                    im.ColorEditFlags_AlphaBar)
                if DragLbl_Clr_Edited then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Clr = Lbl_V_Clr end
                end


                im.Text(ctx, 'Value Pos: '); im.SameLine(ctx); im.SetNextItemWidth(
                    ctx, 100)
                if im.BeginCombo(ctx, '## V Pos' .. LE.Sel_Items[1], FrstSelItm.V_Pos or 'Default', im.ComboFlags_NoArrowButton) then
                    if FrstSelItm.Type == 'V-Slider' then
                        AddOption('Bottom', 'V_Pos')
                        AddOption('Top', 'V_Pos')
                        
                    elseif FrstSelItm.Type == 'Knob' then
                        AddOption('Bottom', 'V_Pos')
                        AddOption('Within', 'V_Pos')
                    elseif FrstSelItm.Type == 'Switch' or FrstSelItm.Type == 'Selection' then
                        AddOption('Within', 'V_Pos')
                    elseif FrstSelItm.Type == 'Drag' then
                        AddOption('Right', 'V_Pos')
                        AddOption('Within', 'V_Pos')
                    elseif FrstSelItm.Type == 'Slider' then
                        AddOption('Right', 'V_Pos')
                        AddOption('Top', 'V_Pos')

                    end
                    if FrstSelItm.Type ~= 'Selection' then AddOption('None', 'V_Pos') end

                    AddOption('Free', 'V_Pos')

                    im.EndCombo(ctx)
                end
                im.SameLine(ctx)

                FreeValuePosSettings()
                DragV_Clr_edited, Drag_V_Clr = im.ColorEdit4(ctx,
                    '##V  Clr' .. LE.Sel_Items[1],
                    FrstSelItm.V_Clr or im.GetColor(ctx, im.Col_Text),
                    im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                    im.ColorEditFlags_AlphaBar)
                if DragV_Clr_edited then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = Drag_V_Clr end
                end

                if FrstSelItm.Type == 'Drag' then
                    im.Text(ctx, 'Direction: ')
                    im.SameLine(ctx)
                    im.SetNextItemWidth(ctx, -R_ofs)
                    if im.BeginCombo(ctx, '## Drag Dir' .. LE.Sel_Items[1], FrstSelItm.DragDir or '', im.ComboFlags_NoArrowButton) then
                        if im.Selectable(ctx, 'Right', false) then
                            for i, v in pairs(LE.Sel_Items) do
                                FX[FxGUID][v].DragDir =
                                'Right'
                            end
                        elseif im.Selectable(ctx, 'Left-Right', false) then
                            for i, v in pairs(LE.Sel_Items) do
                                FX[FxGUID][v].DragDir =
                                'Left-Right'
                            end
                        elseif im.Selectable(ctx, 'Left', false) then
                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Left' end
                        end
                        im.EndCombo(ctx)
                    end
                end








                if FrstSelItm.Type == 'Switch' then
                    local Momentary, Toggle
                    if FrstSelItm.SwitchType == 'Momentary' then
                        Momentary = true
                    else
                        Toggle = true
                    end
                    EdT, Tg = im.Checkbox(ctx, 'Toggle##' .. FxGUID .. LE.Sel_Items[1],
                        Toggle)
                    im.SameLine(ctx);
                    EdM, Mt = im.Checkbox(ctx, 'Momentary##' .. FxGUID .. LE.Sel_Items[1],
                        Momentary)
                    if EdT then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].SwitchType =
                            'Toggle'
                        end
                    elseif EdM then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].SwitchType =
                            'Momentary'
                        end
                    end
                end



                -- set base and target value
                if FrstSelItm.SwitchType == 'Momentary' and FrstSelItm.Type == 'Switch' then
                    im.Text(ctx, 'Base Value: ')
                    im.SameLine(ctx); im.SetNextItemWidth(ctx, 80)
                    local Drag, Bv = im.DragDouble(ctx,
                        '##EditBaseV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                        FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV or 0, 0.05, 0, 1, '%.2f')
                    if Drag then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV = Bv
                        end
                    end
                    im.Text(ctx, 'Target Value: ')
                    im.SameLine(ctx); im.SetNextItemWidth(ctx, 80)
                    local Drag, Tv = im.DragDouble(ctx,
                        '##EditTargV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                        FX[FxGUID][LE.Sel_Items[1]].SwitchTargV or 1, 0.05, 0, 1, '%.2f')
                    if Drag then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][LE.Sel_Items[1]].SwitchTargV =
                                Tv
                        end
                    end
                end









                local FLT_MIN, FLT_MAX = im.NumericLimits_Float()
                ----Font Size-----


                im.Text(ctx, 'Label Font Size: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 50)
                local Drag, ft = im.DragDouble(ctx,
                    '##EditFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                    FrstSelItm.FontSize or Knob_DefaultFontSize, 0.25, 6, 64, '%.2f')
                if Drag then
                    local sz = roundUp(ft, 1)
                    if not _G['Font_Andale_Mono' .. '_' .. sz] then
                        _G['Font_Andale_Mono' .. '_' .. sz] = im.CreateFont('andale mono', sz)
                        ChangeFont = FrstSelItm
                        ChangeFont_Size = sz
                    end

                    ChangeFontSize_TB = {}
                    for i, v in pairs(LE.Sel_Items) do
                        table.insert(ChangeFontSize_TB, FX[FxGUID][v])
                        FX[FxGUID][v].FontSize = ft
                    end
                    ChangeFontSize_Size = ft
                end






                SL()
                im.Text(ctx, 'Value Font Size: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 50)
                local Drag, ft = im.DragDouble(ctx,'##EditV_FontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),FX[FxGUID][LE.Sel_Items[1]].V_FontSize or Knob_DefaultFontSize, 0.25, 6,64,'%.2f')
                if Drag then
                    local sz = roundUp(ft, 1)
                    if not _G['Arial' .. '_' .. sz] then
                       -- _G['Arial' .. '_' .. sz] = im.CreateFont('Arial', sz)
                        ChangeFont = FrstSelItm
                        ChangeFont_Size = sz
                        ChangeFont_Font = 'Arial'
                    end
                    --[[ for i, v in pairs(LE.Sel_Items) do
                        FX[FxGUID][v].V_FontSize = ft
                    end ]]
                    ChangeFontSize_TB = {}
                    for i, v in pairs(LE.Sel_Items) do
                        table.insert(ChangeFontSize_TB, FX[FxGUID][v])
                        FX[FxGUID][v].V_FontSize = ft
                    end
                    ChangeFontSize_Size = ft
                end








                ----Width -------
                im.Text(ctx, 'Width: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 60)
                local DefaultW, MaxW, MinW
                if FrstSelItm.Type == 'Knob' then
                    DefaultW = Df.KnobRadius
                    MaxW = 80
                    MinW = 7.5
                elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' or not FrstSelItm.Type then
                    DefaultW = Df.Sldr_W
                    MaxW = 300
                    MinW = 40
                elseif FrstSelItm.Type == 'Selection' then
                    DefaultW = FrstSelItm.Combo_W
                    MaxW = 300
                    MinW = 20
                elseif FrstSelItm.Type == 'Switch' then
                    DefaultW = FrstSelItm.Switch_W
                    MaxW = 300
                    MinW = 15
                elseif FrstSelItm.Type == 'V-Slider' then
                    DefaultW = FrstSelItm.V_Sldr_W
                    MaxW = 60
                    MinW = 7
                end
                local DragSpeed = 5

                SL()


                local _, W = im.DragDouble(ctx, '##EditWidth' .. FxGUID .. (LE.Sel_Items[1] or ''), FX[FxGUID][LE.Sel_Items[1] or ''].Sldr_W or DefaultW, LE.GridSize / 4, MinW, MaxW, '%.1f')

                if im.IsItemEdited(ctx) then
                    for i, v in pairs(LE.Sel_Items) do
                        Sync_Size_Height_Synced_Properties(FX[FxGUID][v], W - FX[FxGUID][v].Sldr_W)
                        FX[FxGUID][v].Sldr_W = W
                    end
                end


                if FrstSelItm.Type ~= 'Knob' then
                    SL()
                    im.Text(ctx, 'Height: ')
                    SL()
                    im.SetNextItemWidth(ctx, 60)
                    local max, defaultH
                    if FrstSelItm.Type == 'V-Slider' then
                        max = 200
                        defaultH = 160
                    end
                    local _, W = im.DragDouble(ctx, '##Height' .. FxGUID .. (LE.Sel_Items[1] or ''), FX[FxGUID][LE.Sel_Items[1] or ''].Height or defaultH or 3, LE.GridSize / 4, -5, max or 40, '%.1f')
                    if im.IsItemEdited(ctx) then
                        for i, v in pairs(LE.Sel_Items) do
                            local w = FX[FxGUID][LE.Sel_Items[1] or ''].Height or defaultH or 3
                            Sync_Height_Synced_Properties(FX[FxGUID][v], W-w, Height_Sync_Properties)

                            FX[FxGUID][v].Height = W


                        end
                    end
                end



                if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'Drag' or FrstSelItm.Type == 'Slider' then
                    im.Text(ctx, 'Value Decimal Places: '); im.SameLine(ctx)
                    im.SetNextItemWidth(ctx, 80)
                    if not FX[FxGUID][LE.Sel_Items[1]].V_Round then
                        local _, FormatV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                            FX[FxGUID][LE.Sel_Items[1]].Num)
                        local _, LastNum = FormatV:find('^.*()%d')
                        local dcm = FormatV:find('%.')
                        if dcm then
                            rd = LastNum - dcm
                        end
                    end

                    local Edit, rd = im.InputInt(ctx,
                        '##EditValueDecimals' .. FxGUID .. (LE.Sel_Items[1] or ''),
                        FrstSelItm.V_Round or rd, 1)
                    if Edit then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].V_Round = math.max(
                                rd, 0)
                        end
                    end
                end







                im.Text(ctx, 'Value to Note Length: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 80)
                local Edit = im.Checkbox(ctx,
                    '##Value to Note Length' .. FxGUID .. (LE.Sel_Items[1] or ''),
                    FrstSelItm.ValToNoteL or nil)
                if Edit then
                    for i, v in pairs(LE.Sel_Items) do
                        if not FX[FxGUID][v].ValToNoteL then
                            FX[FxGUID][v].ValToNoteL = true
                        else
                            FX[FxGUID][v].ValToNoteL = false
                        end
                    end
                end
                if FrstSelItm.Type == 'Selection' then --im.Text(ctx,'Edit Values Manually: ') ;im.SameLine(ctx)
                    local Itm = LE.Sel_Items[1]
                    local FP = FX[FxGUID][Itm] ---@class FX_P



                    if im.TreeNode(ctx, 'Edit Values Manually') then
                        FX[FxGUID][Itm].ManualValues = FX[FxGUID][Itm].ManualValues or {}
                        FX[FxGUID][Itm].ManualValuesFormat = FX[FxGUID][Itm]
                            .ManualValuesFormat or {}
                        if im.Button(ctx, 'Get Current Value##' .. FxGUID .. (Itm or '')) then
                            local Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP
                                .Num)
                            if not tablefind(FP.ManualValues, Val) then
                                table.insert(FX[FxGUID][Itm].ManualValues, Val)
                            end
                        end
                        for i, V in ipairs(FX[FxGUID][Itm].ManualValues) do
                            im.AlignTextToFramePadding(ctx)
                            im.Text(ctx, i .. ':' .. (round(V, 2) or 0))
                            SL()
                            --im.SetNextItemWidth(ctx, -R_ofs)
                            rv, FX[FxGUID][Itm].ManualValuesFormat[i] = im.InputText(ctx,
                                '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i,
                                FX[FxGUID][Itm].ManualValuesFormat[i])
                            SL()
                            local LH = im.GetTextLineHeight(ctx)
                            local rv = im.Button(ctx, '##%', 20, 20) -- bin icon
                            DrawListButton(WDL, '%', r.ImGui_GetColor(ctx, r.ImGui_Col_Button()), nil, true, icon1_middle, false) -- trash bin
                            if rv then
                                table.remove(FX[FxGUID][Itm].ManualValuesFormat, i)
                                table.remove(FX[FxGUID][Itm].ManualValues, i)
                            end
                        end
                        --FX[FxGUID][Itm].EditValuesManual = true
                        im.TreePop(ctx)
                    end
                end

                function ToAllSelItm(x, y)
                    for i, v in ipairs(LE.Sel_Items) do
                        FX[FxGUID][v][x] = y
                    end
                end

                local FLT_MIN, FLT_MAX = im.NumericLimits_Float()

                --- Style ------
                im.Text(ctx, 'Style: '); im.SameLine(ctx)
                w = im.CalcTextSize(ctx, 'Style: ')
                local stylename
                if FrstSelItm.Style == 'Pro C' then stylename = 'Minimalistic' end
                if im.Button(ctx, (stylename or FrstSelItm.Style or 'Choose Style') .. '##' .. (LE.Sel_Items[1] or 'Style'), 130) then
                    im.OpenPopup(ctx, 'Choose style window')
                end


                im.Text(ctx, 'Add Custom Image:')

                DragDropPics = DragDropPics or {}

                local rv, ImgTrashTint = TrashIcon(16, 'Clear', ClrBG, ImgTrashTint)
                if rv then
                    ToAllSelItm('Style', nil)
                    ToAllSelItm('ImagePath', nil)
                    ToAllSelItm('Image', nil)
                end


                SL()
                if im.BeginChild(ctx, '##drop_files', -R_ofs, 20) then
                    if not FrstSelItm.ImagePath then
                        im.Text(ctx, 'Drag and drop files here...')
                    else
                        --FrstSelItm.Style = 'Custom Image'

                        im.Text(ctx, FrstSelItm.ImagePath)
                    end

                    im.EndChild(ctx)
                end

                if im.BeginDragDropTarget(ctx) then
                    local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                    if rv then
                        for i = 0, count - 1 do
                            local rv, filename = im.GetDragDropPayloadFile(ctx, i)
                            if rv then
                                FrstSelItm.Style = 'Custom Image'
                                --[[
                                local slash = '%\\'
                                if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
                                    slash = '/'
                                end
                                local index = filename:match ('^.*()'..slash)
                                local SubFolder = ''
                                if FrstSelItm.Type == 'Knob' then
                                    SubFolder = 'Knobs'
                                end

                                local NewFileName = r.GetResourcePath() .. 'src/Images/' ..  SubFolder .. filename:sub(index)
                                CopyFile(filename, NewFileName) ]]
                                if FrstSelItm.Type == 'Knob' then
                                    AbsPath, FrstSelItm.ImagePath = CopyImageFile(filename,
                                        'Knobs')
                                elseif FrstSelItm.Type == 'Switch' then
                                    AbsPath, FrstSelItm.ImagePath = CopyImageFile(filename,
                                        'Switches')
                                end
                                ToAllSelItm('Image', im.CreateImage(AbsPath))
                            end

                            --[[  AttachImage = { Path = FrstSelItm.ImagePath, DrawItemNum = It, }
                            if AttachImage then
                                local FX_Name_Short = ChangeFX_Name(FX_Name)
                                FrstSelItm.Image = im.CreateImage(AttachImage.Path)
                                im.Attach(ctx, FrstSelItm.Image)
                                AttachImage = nil
                            end ]]
                        end
                    end
                    im.EndDragDropTarget(ctx)
                end

                --[[ if  im.BeginCombo( ctx, '##'..(LE.Sel_Items[1] or 'Style') , FrstSelItm.Style or 'Choose Style', nil) then
                        local function AddStyle (Name, Style)
                            if im.Selectable(ctx, Name) then
                                for i, v in pairs (LE.Sel_Items) do
                                    FX[FxGUID][v].Style = Style ;   im.CloseCurrentPopup(ctx)
                                end
                            end
                        end
                        local T = {Name ={}; Style = {}}
                        T.Name={'Default', 'Minimalistic', 'Analog 1'}
                        T.Style = {'Default', 'Pro C', 'Analog 1'}

                        for i, v in ipairs(T.Name) do
                            AddStyle(v, T.Style[i])
                        end

                        im.EndCombo(ctx)

                    end ]]


                if im.BeginPopup(ctx, 'Choose style window') then
                    im.BeginDisabled(ctx)

                    local function setItmStyle(Style, img, ImgPath)
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].Style = Style;
                            if img then
                                FX[FxGUID][v].Image = img
                                FX[FxGUID][v].ImagePath = ImgPath
                            else
                                FX[FxGUID][v].ImagePath = nil
                            end

                            im.CloseCurrentPopup(ctx)
                        end
                    end
                    if FrstSelItm.Type == 'Slider' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Slider') then -- if all selected itms are Sliders
                        --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize,     FrstSelItm.Lbl, 8)
                        --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize, FrstSelItm.Lbl, 8)
                    end
                    if not im.ValidatePtr(StyleWinFilter, "ImGui_TextFilter*") then
                        StyleWinFilter = im.CreateTextFilter(FilterText)
                    end
                    local function Get_Attach_Drawing_Styles()
                        if im.IsWindowAppearing(ctx) then

                            local Dir = CurrentDirectory .. 'src/Layout Editor Item Styles/'..FrstSelItm.Type
                            local files = scandir(Dir)
                            LE.DrawingStyles = LE.DrawingStyles or { [FrstSelItm.Type] = {} }

                            if files then 
                                for i, v in ipairs(files) do 
                                    local file_path = ConcatPath(Dir, v)
                                    local file = io.open(file_path, 'r')
                                    local Ct = file:read('*a')
                                    LE.DrawingStyles[FrstSelItm.Type][i] = LE.DrawingStyles[FrstSelItm.Type][i] or {}
                                    LE.DrawingStyles[FrstSelItm.Type][i].Draw = {}
                                    LE.DrawingStyles[FrstSelItm.Type][i].Name = string.sub(v, 1, -5 )
                                    LE.DrawingStyles[FrstSelItm.Type][i].Draw = Retrieve_Attached_Drawings(Ct, nil, LE.DrawingStyles[FrstSelItm.Type][i].Draw)
                                end
                            end
                           
                        end
                    end

                    local function Add_Attach_Drawing_Styles(StyleWinFilter)
                         -- add attached drawings
                         if FrstSelItm.Type == 'Knob' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Knob') then 
                            for i, v in ipairs(LE.DrawingStyles[FrstSelItm.Type])do 
                                if im.TextFilter_PassFilter(StyleWinFilter, v.Name) then
                                    im.BeginGroup(ctx)
                                    local pos = {im.GetCursorScreenPos(ctx)}
                                    AddKnob(ctx, '##' .. FrstSelItm.Name, '', FrstSelItm.V, 0, 1, FItm, FX_Idx, FrstSelItm.Num, 'Invisible', 15, 0, Disabled, 12, Lbl_Pos, V_Pos, Img)
                                    local w, h = im.GetItemRectSize(ctx)
                                    Draw_Attached_Drawings(v,FX_Idx, pos , FrstSelItm.V, FrstSelItm.Type)
                                    SL()

                                    im.Text(ctx, v.Name)
                                    im.EndGroup(ctx)
                                    if HighlightHvredItem() then --if clicked on highlighted itm
                                        for i, V in ipairs(LE.Sel_Items) do 
                                            FX[FxGUID][V].Draw = v.Draw
                                        end
                                        im.CloseCurrentPopup(ctx)
                                    end
                                    im.Separator(ctx)
                                end
                                
                            end   
                        end 
                    end

                    Get_Attach_Drawing_Styles()

                    -- if all selected itms are knobs
                    if FrstSelItm.Type == 'Knob' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Knob') then 
                        StyleWinImg = StyleWinImg or {}
                        StyleWinImgName = StyleWinImgName or {}
                        local function SetStyle(Name, Style, Img, ImagePath)
                            if im.TextFilter_PassFilter(StyleWinFilter, Name) then
                                im.BeginGroup(ctx)
                                AddKnob(ctx, '##' .. FrstSelItm.V, '', 0, 0, 1, FItm, FX_Idx, FrstSelItm.Num, Style, 15, 0, Disabled, 12, Lbl_Pos, V_Pos, Img)
                                SL()
                                im.Text(ctx, Name)
                                im.EndGroup(ctx)
                                if HighlightHvredItem() then --if clicked on highlighted itm
                                    setItmStyle(Style, Img, ImagePath)
                                    im.CloseCurrentPopup(ctx)
                                end
                                
                                im.Separator(ctx)
                            end
                        end
                        local function Add_Image_Styles()
                            local Dir = CurrentDirectory .. 'src/Images/Knobs'
                            if im.IsWindowAppearing(ctx) then
                                StyleWindowImgFiles = scandir(Dir)
                                if StyleWindowImgFiles then
                                    for i, v in ipairs(StyleWindowImgFiles) do
                                        if v ~= '.DS_Store' then
                                            StyleWinImg[i] = im.CreateImage(Dir .. '/' .. v)
                                            im.Attach(ctx, StyleWinImg[i])
                                            StyleWinImgName[i] = v
                                        end
                                    end
                                end
                            end

                            for i, v in pairs(StyleWinImg) do
                                local Dir = '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/Knobs/' 
                                SetStyle(StyleWinImgName[i], 'Custom Image', StyleWinImg[i], Dir .. StyleWinImgName[i])
                            end
                        end

                       

                        im.EndDisabled(ctx)
                        if im.TextFilter_Draw(StyleWinFilter, ctx, '##StyleWinFilterTxt', -1) then
                            FilterText = im.TextFilter_Get(StyleWinFilter)
                            im.TextFilter_Set(StyleWinFilter, FilterText)
                        end
                        if im.IsWindowAppearing(ctx) then
                            im.SetKeyboardFocusHere(ctx)
                        end

                        im.BeginDisabled(ctx)


                        SetStyle('Default', Style)
                        SetStyle('Minimalistic', 'Pro C')
                        SetStyle('Invisible', 'Invisible')
                        Add_Image_Styles()
                        Add_Attach_Drawing_Styles(StyleWinFilter)

                        
                    end

                    if FrstSelItm.Type == 'Selection' then
                        local function SetStyle(Name, Style, Width, CustomLbl)
                            AddCombo(ctx, LT_Track, FX_Idx, Name .. '##' .. FrstSelItm.Name,
                                FrstSelItm.Num, Options, Width, Style, FxGUID,
                                LE.Sel_Items[1],
                                OptionValues, 'Options', CustomLbl)
                            if HighlightHvredItem() then
                                setItmStyle(Style)
                                im.CloseCurrentPopup(ctx)
                            end
                            AddSpacing(3)
                        end
                        local w = 60
                        SetStyle('Default', nil, w, 'Default: ')

                        SetStyle('up-down arrow', 'up-down arrow', w + 20, 'up-down arrow: ')
                    end

                    im.EndDisabled(ctx)
                    im.EndPopup(ctx)
                end
                ---Pos  -------

                im.Text(ctx, 'Pos-X: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 80)
                local EditPosX, PosX = im.DragDouble(ctx, ' ##EditPosX' ..
                    FxGUID .. LE.Sel_Items[1], PosX or FrstSelItm.PosX, LE.GridSize, 0,
                    Win_W - 10,
                    '%.0f')
                if EditPosX then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosX = PosX end
                end
                SL()
                im.Text(ctx, 'Pos-Y: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 80)
                local EditPosY, PosY = im.DragDouble(ctx, ' ##EditPosY' ..
                    FxGUID .. LE.Sel_Items[1], PosY or FrstSelItm.PosY, LE.GridSize, 20, 210,
                    '%.0f')
                if EditPosY then for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosY = PosY end end

                ---Color -----

                im.Text(ctx, 'Color: ')
                im.SameLine(ctx)
                ClrEdited, PrmBgClr = im.ColorEdit4(ctx, '##Clr' .. ID,
                    FrstSelItm.BgClr or im.GetColor(ctx, im.Col_FrameBg),
                    im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                    im.ColorEditFlags_AlphaBar)
                if not FX[FxGUID][LE.Sel_Items[1]].BgClr or FX[FxGUID][LE.Sel_Items[1]] == im.GetColor(ctx, im.Col_FrameBg) then
                    HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                        'GetItemRect')
                end
                if ClrEdited then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].BgClr = PrmBgClr end
                end


                if FrstSelItm.Type ~= 'Switch' and FrstSelItm.Type ~= 'Selection' then
                    im.Text(ctx, 'Grab Color: ')
                    im.SameLine(ctx)
                    GrbClrEdited, GrbClr = im.ColorEdit4(ctx, '##GrbClr' .. ID,
                        FrstSelItm.GrbClr or im.GetColor(ctx, im.Col_SliderGrab),
                        im.ColorEditFlags_NoInputs|    r
                        .ImGui_ColorEditFlags_AlphaPreviewHalf()|
                        im.ColorEditFlags_AlphaBar)
                    if not FX[FxGUID][LE.Sel_Items[1]].GrbClr or FX[FxGUID][LE.Sel_Items[1]].GrbClr == im.GetColor(ctx, im.Col_SliderGrab) then
                        HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                            'GetItemRect')
                    end
                    if GrbClrEdited then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].GrbClr = GrbClr
                        end
                    end
                end

                if FrstSelItm.Type == 'Knob' then
                    SL()
                    im.Text(ctx, 'Thickness : ')
                    SL()
                    im.SetNextItemWidth(ctx, 40)
                    local TD, Thick = im.DragDouble(ctx,
                        '##EditValueFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                        FX[FxGUID][LE.Sel_Items[1] or ''].Value_Thick or 2, 0.1, 0.5, 8,
                        '%.1f')
                    if TD then
                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Value_Thick = Thick end
                    end
                end


                if FrstSelItm.Type == 'Selection' then
                    im.SameLine(ctx)
                    im.Text(ctx, 'Text Color: ')
                    im.SameLine(ctx)
                    local DragLbl_Clr_Edited, V_Clr = im.ColorEdit4(ctx,
                        '##V Clr' .. LE.Sel_Items[1],
                        FX[FxGUID][LE.Sel_Items[1] or ''].V_Clr or
                        im.GetColor(ctx, im.Col_Text),
                        im.ColorEditFlags_NoInputs|    r
                        .ImGui_ColorEditFlags_AlphaPreviewHalf()|im.ColorEditFlags_AlphaBar)
                    if DragLbl_Clr_Edited then
                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = V_Clr end
                    end
                elseif FrstSelItm.Type == 'Switch' then
                    SL()
                    im.Text(ctx, 'On Color: ')
                    im.SameLine(ctx)
                    local DragLbl_Clr_Edited, V_Clr = im.ColorEdit4(ctx,
                        '##Switch on Clr' .. LE.Sel_Items[1],
                        FX[FxGUID][LE.Sel_Items[1] or ''].Switch_On_Clr or 0xffffff55,
                        im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf|
                        im.ColorEditFlags_AlphaBar)
                    if DragLbl_Clr_Edited then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].Switch_On_Clr =
                                V_Clr
                        end
                    end
                end

                ----- Condition to show ------

                local P = LE.Sel_Items[1]
                local fp = FX[FxGUID][LE.Sel_Items[1]] ---@class FX_P




                ---@param ConditionPrm string "ConditionPrm"..number
                ---@param ConditionPrm_PID string "ConditionPrm_PID"..number
                ---@param ConditionPrm_V string "ConditionPrm_V"..number
                ---@param ConditionPrm_V_Norm string "ConditionPrm_V_Norm"..number
                ---@param BtnTitle string
                ---@param ShowCondition string "ShowCondition"..number
                local function Condition(ConditionPrm, ConditionPrm_PID, ConditionPrm_V,
                                         ConditionPrm_V_Norm, BtnTitle, ShowCondition)
                    if im.Button(ctx, BtnTitle) then
                        if Mods == 0 then
                            for i, v in pairs(LE.Sel_Items) do
                                if not FX[FxGUID][v][ShowCondition] then FX[FxGUID][v][ShowCondition] = true else FX[FxGUID][v][ShowCondition] = nil end
                                FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v]
                                    [ConditionPrm_V] or {}
                            end
                        elseif Mods == Alt then
                            for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                FX[FxGUID][P][ConditionPrm_V][i] = nil
                            end
                            FX[FxGUID][P][ConditionPrm] = nil
                            FrstSelItm[ShowCondition] = nil
                            DeleteAllConditionPrmV = nil
                        end
                    end

                    if im.IsItemHovered(ctx) then
                        tooltip(
                            'Alt-Click to Delete All Conditions')
                    end



                    if FrstSelItm[ShowCondition] or FX[FxGUID][P][ConditionPrm] then
                        SL()
                        if not FX[FxGUID][P][ConditionPrm_PID] then
                            for i, v in ipairs(FX[FxGUID]) do
                                if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                    FrstSelItm[ConditionPrm_PID] = i
                                end
                            end
                        end
                        local PID = FX[FxGUID][P][ConditionPrm_PID] or 1

                        if im.Button(ctx, 'Parameter:##' .. ConditionPrm) then
                            FX[FxGUID][P].ConditionPrm = LT_ParamNum
                            local found
                            for i, v in ipairs(FX[FxGUID]) do
                                if FX[FxGUID][i].Num == LT_ParamNum then
                                    FrstSelItm[ConditionPrm_PID] = i
                                    found = true

                                    fp.Sldr_W = nil
                                end
                            end
                            if not found then
                                local P = StoreNewParam(LT_FXGUID, LT_ParamName,
                                    LT_ParamNum,
                                    LT_FXNum, true --[[ , nil, #F+1  ]])
                                fp[ConditionPrm_PID] = P

                                fp[ConditionPrm] = tonumber(LT_ParamNum)
                                fp.Sldr_W = nil
                            end

                            --GetParamOptions ('get', FxGUID,FX_Idx, LE.Sel_Items[1],LT_ParamNum)
                        end
                        if im.IsItemHovered(ctx) then
                            tooltip('Click to set to last touched parameter')
                        end


                        im.SameLine(ctx)
                        im.SetNextItemWidth(ctx, 80)
                        local PrmName, PrmValue
                        if fp[ConditionPrm] then
                            _, PrmName = r.TrackFX_GetParamName(LT_Track, FX_Idx,
                                fp[ConditionPrm])
                        end

                        --[[ local Edit, Cond = im.InputInt(ctx,'##' .. ConditionPrm .. LE.Sel_Items[1] .. FxGUID, FX[FxGUID][P][ConditionPrm] or 0)

                        if FX[FxGUID][P][ConditionPrm] then
                            _, PrmName = r.TrackFX_GetParamName(
                                LT_Track, FX_Idx, FX[FxGUID][P][ConditionPrm])
                        end

                        if Edit then
                            FX[FxGUID][P][ConditionPrm] = Cond
                            for i, v in ipairs(FX[FxGUID]) do
                                if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                    FrstSelItm[ConditionPrm_PID] =i
                                end
                            end
                        end ]]

                        im.SameLine(ctx)
                        im.Text(ctx, (PrmName or ''))
                        im.AlignTextToFramePadding(ctx)
                        if PrmName then
                            im.Text(ctx, 'is at Value:')

                            im.SameLine(ctx)
                            local FP = FX[FxGUID][LE.Sel_Items[1]] ---@class FX_P
                            local CP = FX[FxGUID][P][ConditionPrm]
                            --!!!!!! LE.Sel_Items[1] = Fx_P -1 !!!!!! --
                            Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx,
                                'ConditionPrm' ..
                                FP.ConditionPrm .. (PrmName or '') .. '1## CP',
                                FX[FxGUID][P][ConditionPrm] or 0,
                                FX[FxGUID][PID].ManualValuesFormat or 'Get Options', -R_ofs,
                                Style,
                                FxGUID, PID, FX[FxGUID][PID].ManualValues,
                                FX[FxGUID][P][ConditionPrm_V][1] or 'Unassigned', nil,
                                'No Lbl')

                            if Value_Selected then
                                for i, v in pairs(LE.Sel_Items) do
                                    FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v]
                                        [ConditionPrm_V] or
                                        {}
                                    FX[FxGUID][v][ConditionPrm_V_Norm] = FX[FxGUID][v]
                                        [ConditionPrm_V_Norm] or {}
                                    FX[FxGUID][v][ConditionPrm_V][1] = V_Formatted
                                    FX[FxGUID][v][ConditionPrm_V_Norm][1] = r
                                        .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                            fp[ConditionPrm])
                                end
                            end
                            if not FX[FxGUID][P][ConditionPrm_V][1] then
                                FX[FxGUID][P][ConditionPrm_V][1] = ''
                            end

                            if FX[FxGUID][P][ConditionPrm_V] then
                                if FX[FxGUID][P][ConditionPrm_V][2] then
                                    for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                        if i > 1 then
                                            im.Text(ctx, 'or at value:')
                                            im.SameLine(ctx)
                                            local Value_Selected, V_Formatted = AddCombo(ctx,
                                                LT_Track,
                                                FX_Idx, 'CondPrmV' .. (PrmName or '') .. v ..
                                                ConditionPrm,
                                                FX[FxGUID][P][ConditionPrm] or 0,
                                                FX[FxGUID][PID].ManualValuesFormat or
                                                'Get Options',
                                                -R_ofs, Style, FxGUID, PID,
                                                FX[FxGUID][PID].ManualValues,
                                                v, nil, 'No Lbl')
                                            if Value_Selected then
                                                for I, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v][ConditionPrm_V][i] =
                                                        V_Formatted
                                                    FX[FxGUID][v][ConditionPrm_V_Norm][i] = r
                                                        .TrackFX_GetParamNormalized(LT_Track,
                                                            FX_Idx,
                                                            FX[FxGUID][P][ConditionPrm])
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            if im.Button(ctx, ' + or at value:##' .. ConditionPrm) then
                                FX[FxGUID][P][ConditionPrm_V] = FX[FxGUID][P]
                                    [ConditionPrm_V] or {}
                                table.insert(FX[FxGUID][P][ConditionPrm_V], '')
                            end
                            im.SameLine(ctx)
                            im.SetNextItemWidth(ctx, 120)
                            if im.BeginCombo(ctx, '##- delete value ' .. ConditionPrm, '- delete value', im.ComboFlags_NoArrowButton) then
                                for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                    if im.Selectable(ctx, v or '##', i) then
                                        table.remove(FX[FxGUID][P][ConditionPrm_V], i)
                                        if not FX[FxGUID][P][ConditionPrm_V][1] then
                                            FX[FxGUID][P][ConditionPrm] = nil
                                        end
                                    end
                                end
                                im.EndCombo(ctx)
                            end
                        end
                    end
                end



                if im.TreeNode(ctx, 'Conditional Parameter') then
                    Condition('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V', 'ConditionPrm_V_Norm', 'Show only if:', 'ShowCondition')
                    if FrstSelItm.ConditionPrm then
                        Condition('ConditionPrm2', 'ConditionPrm_PID2', 'ConditionPrm_V2', 'ConditionPrm_V_Norm2', 'And if:', 'ShowCondition2')
                    end
                    if FrstSelItm.ConditionPrm2 then
                        Condition('ConditionPrm3', 'ConditionPrm_PID3', 'ConditionPrm_V3', 'ConditionPrm_V_Norm3', 'And if:', 'ShowCondition3') end
                    if FrstSelItm.ConditionPrm3 then
                        Condition('ConditionPrm4', 'ConditionPrm_PID4', 'ConditionPrm_V4', 'ConditionPrm_V_Norm4', 'And if:', 'ShowCondition4')
                    end
                    if FrstSelItm.ConditionPrm4 then
                        Condition('ConditionPrm5', 'ConditionPrm_PID5', 'ConditionPrm_V5', 'ConditionPrm_V_Norm5', 'And if:', 'ShowCondition5')
                    end
                    im.TreePop(ctx)
                end



                if im.TreeNode(ctx, 'Attach Drawing') then
                    FrstSelItm.Draw = FrstSelItm.Draw or {}
                    if RemoveDraw then
                        table.remove(FrstSelItm.Draw, RemoveDraw)
                        RemoveDraw = nil
                    end

                    for i, v in ipairs(FrstSelItm.Draw)  do

                        local D = FrstSelItm.Draw[i]
                        local LBL = FxGUID .. LE.Sel_Items[1] .. i
                        local H = Glob.Height
                        local W = Win_W

                        im.AlignTextToFramePadding(ctx)
                        local function Bullet_To_Reorder()
                            im.SmallButton( ctx, '-##'..i)
                            if im.IsItemHovered(ctx) then 
                                D.HighlightBullet = true 
                            end 

                            if D.HighlightBullet then 
                                Highlight_Itm(WDL, nil, 0xffffffff)
                                if not im.IsItemHovered(ctx) then 
                                    D.HighlightBullet = nil 
                                end 
                                if im.IsItemClicked(ctx) then
                                    --im.SetDragDropPayload(ctx, 'Reorder Item attached drawings', D)
                                end

                            end 
                            if im.BeginDragDropSource(ctx) then 

                                im.SetDragDropPayload(ctx, 'Reorder Item attached drawings', i)
                                
                                Reorder_Draw_Itm_SRC = {}
                                for I, v in pairs(D) do 
                                    Reorder_Draw_Itm_SRC[I] = v
                                end
                                im.EndDragDropSource(ctx)
                            end 
                            if im.BeginDragDropTarget(ctx ) then

                                local dropped, src = im.AcceptDragDropPayload(ctx, 'Reorder Item attached drawings') --
                                if dropped then 

                                    for I, v in pairs(D) do 
                                        FrstSelItm.Draw[tonumber(src)][I] = v
                                    end

                                    for I, v in pairs(Reorder_Draw_Itm_SRC) do
                                        D[I] = v
                                    end


                                    --FrstSelItm.Draw[i] = Reorder_Draw_Itm
                                    Reorder_Draw_Itm_SRC=nil
                                end 
                                im.EndDragDropTarget(ctx)
                            end
                        end

                        Bullet_To_Reorder()
                        SL()
                        local rv = im.TreeNode(ctx, 'Drawing ' .. i)

                        SL()
                        im.Text(ctx, ' Type : ')
                        SL()
                        im.SetNextItemWidth(ctx, 100)


                        if im.BeginCombo(ctx, '## Combo type' .. LBL, D.Type or '', im.ComboFlags_NoArrowButton) then
                            local function AddOption(str)
                                if im.Selectable(ctx, str, false) then
                                    D.Type = str; D.T = str;
                                end
                            end
                            AddOption('Image')
                            AddOption('Line')
                            AddOption('Circle')
                            AddOption('Circle Filled')
                            AddOption('Knob Pointer')
                            AddOption('Knob Range')
                            AddOption('Knob Circle')
                            AddOption('Knob Circle Filled')
                            AddOption('Knob Image')
                            AddOption('Rect')
                            AddOption('Rect Filled')
                            AddOption('Gain Reduction Text')


                            im.EndCombo(ctx)
                        end

                        SL()
                        if im.Button(ctx, 'Delete##' .. i) then
                            RemoveDraw = i
                        end



                        if rv then
                            local function AddProp(ShownName, Name, width, sl, defaultV,
                                                   stepSize,
                                                   min, max, format)
                                if ShownName then
                                    im.Text(ctx, ShownName)
                                    SL()
                                end
                                if width then im.SetNextItemWidth(ctx, width) end
                                local FORMAT = format
                                if not D[Name] and not defaultV then FORMAT = '' end

                                local rv, V = im.DragDouble(ctx, '##' .. Name .. LBL,
                                    D[Name] or defaultV, stepSize or LE.GridSize, min or -W,
                                    max or W - 10, FORMAT)

                                if rv then D[Name] = V end
                                if sl then SL() end
                                return im.IsItemActive(ctx)
                            end

                            local BL_Width = { 'Knob Pointer', 'Knob Range',
                                'Gain Reduction Text' }
                            local BL_Height = { 'Knob Pointer', 'Knob Range', 'Circle',
                                'Circle Filled', 'Knob Circle', 'Knob Circle Filled', 'Knob Image',
                                'Gain Reduction Text' }
                            local Thick = { 'Knob Pointer', 'Line', 'Rect', 'Circle' }
                            local Round = { 'Rect', 'Rect Filled' }
                            local Gap = { 'Circle', 'Circle Filled'}
                            local BL_XYGap = { 'Knob Pointer', 'Knob Range', 'Knob Circle', 'Knob Circle Filled',
                                'Knob Image' }
                            local RadiusInOut = { 'Knob Pointer', 'Knob Range' }
                            local Radius = { 'Knob Circle', 'Knob Image','Knob Circle Filled' }
                            local BL_Repeat = { 'Knob Range', 'Knob Circle', 'Knob Image', 'Knob Circle Filled',
                                'Knob Pointer', 'Gain Reduction Text' }
                            local GR_Text = { 'Gain Reduction Text' }


                            local X_Gap_Shown_Name = 'X Gap:'

                            local DefW, DefH

                            local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize


                            if D.Type == 'Image' or D.Type == 'Knob Image' then
                                if im.BeginChild(ctx, '##drop_files', -R_ofs, 25) then
                                    if D.Image then
                                        if TrashIcon(13, 'Image Delete', ClrBG, ClrTint) then
                                            D.Image, D.FilePath = nil
                                        end
                                        SL()
                                    end
                                    if not D.FilePath then
                                        im.Text(ctx, 'Drag and drop files here...')
                                    else
                                        im.Text(ctx, D.FilePath)
                                    end
                                    if D.FilePath then
                                        im.Bullet(ctx)
                                        im.TextWrapped(ctx, D.FilePath)
                                    end
                                    im.EndChild(ctx)
                                end

                                if im.BeginDragDropTarget(ctx) then
                                    local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                                    if rv then
                                        for i = 0, count - 1 do
                                            local rv, filename = im.GetDragDropPayloadFile(
                                                ctx,
                                                i)


                                            path, D.FilePath = CopyImageFile(filename, 'Attached Drawings')


                                            D.Image = im.CreateImage(path)
                                            im.Attach(ctx, D.Image)
                                        end
                                    end
                                    im.EndDragDropTarget(ctx)
                                end
                            end

                            local ClrFLG = im.ColorEditFlags_NoInputs +
                                im.ColorEditFlags_AlphaPreviewHalf +
                                im.ColorEditFlags_NoLabel + im.ColorEditFlags_AlphaBar

                            im.AlignTextToFramePadding(ctx)

                            local flags = im.TableFlags_SizingStretchSame |
                                im.TableFlags_Resizable |
                                im.TableFlags_BordersOuter |
                                im.TableFlags_BordersV |
                                im.TableFlags_ContextMenuInBody|
                                im.TableFlags_RowBg



                            if im.BeginTable(ctx, 'Attached Drawing Properties', 3, flags, -R_ofs) then
                                local function SetRowName(str, notTAB, TAB)
                                    im.TableSetColumnIndex(ctx, 0)
                                    if TAB then
                                        if FindExactStringInTable(TAB, D.Type) then
                                            im.Text(ctx, str)
                                            return true
                                        end
                                    elseif notTAB then
                                        if not FindExactStringInTable(notTAB, D.Type) then
                                            im.Text(ctx, str)
                                            return true
                                        end
                                    else
                                        im.Text(ctx, str)
                                    end
                                end


                                --[[ if im.IsItemHovered(ctx) then
                                    tooltip('How much the value is affected by parameter"\"s value ')
                                end ]]
                                local WidthSyncBtnSz = 100
                                local function AddVal(Name, defaultV, stepSize, min, max, format, NextRow, WidthSyncBtn)
                                    local Column = 1
                                    if Name:find('_VA') then Column = 2 end
                                    im.TableSetColumnIndex(ctx, Column)
                                    local itmW = WidthSyncBtn and -WidthSyncBtnSz or -FLT_MIN

                                    im.PushItemWidth(ctx, itmW)


                                    local FORMAT = format
                                    if not D[Name .. '_GR'] and not D[Name] and not defaultV then
                                        FORMAT = ''
                                    end


                                    local tweak_Drag, V = im.DragDouble(ctx, '##' .. Name .. LBL, D[Name .. '_GR'] or D[Name] or defaultV, stepSize or LE.GridSize, min or -W, max or W - 10, FORMAT)

                                    if tweak_Drag and not D[Name .. '_GR'] then
                                        for I, v in ipairs ( LE.Sel_Items) do 
                                            FX[FxGUID][v].Draw[i][Name] = V
                                        end 
                                        --[[ D[Name] = V ]]
                                    elseif tweak_Drag and D[Name .. '_GR'] then
                                        D[Name .. '_GR'] = V; D[Name] = nil
                                    end

                                    if defaultV and not D[Name] then 
                                        D[Name] = V
                                    end 

                                    -- if want to show preview use this.
                                    --if im.IsItemActive(ctx) then FrstSelItm.ShowPreview = FrstSelItm.Num end



                                    if FrstSelItm.ShowPreview and im.IsItemDeactivated(ctx) then FrstSelItm.ShowPreview = nil end

                                    im.PopItemWidth(ctx)
                                    if Name:find('_VA') then
                                        if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
                                            im.OpenPopup(ctx, 'Value afftect ' .. Name)
                                        end
                                    end

                                    if im.BeginPopup(ctx, 'Value afftect ' .. Name) then
                                        local rv, GR = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'GainReduction_dB')
                                        if not rv then im.BeginDisabled(ctx) end

                                        if D[Name .. '_GR'] then D.check = true end
                                        Check, D.check = im.Checkbox(ctx, 'Affected by Gain Reduction', D.check)
                                        if Check then
                                            if D[Name .. '_GR'] then D[Name .. '_GR'] = nil else D[Name .. '_GR'] = 0 end
                                        end

                                        if not rv then im.EndDisabled(ctx) end
                                        im.EndPopup(ctx)
                                    end


                                    if WidthSyncBtn then 
                                        SL()
                                        _ , D[Name..'_SS'] = im.Checkbox(ctx, 'Size Sync ##'..Name,  D[Name..'_SS']) 


                                    end 

                                    if Name:find('_VA') or NextRow then im.TableNextRow(ctx) end

                                    return tweak_Drag
                                end


                                im.TableSetupColumn(ctx, '##')
                                im.TableSetupColumn(ctx, 'Values')
                                im.TableSetupColumn(ctx, 'Affected By Value')

                                im.TableNextRow(ctx, im.TableRowFlags_Headers)


                                local Win_W = FX[FxGUID].Width or DefaultWidth or 220


                                im.TableHeadersRow(ctx)

                                local Sz = FrstSelItm.Sldr_W or 160

                                im.TableNextRow(ctx)

                                local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize
                                if D.Type and  D.Type:find('Circle')  then
                                    WidthLBL = 'Size'; WidthStepSize = 1
                                end




                                SetRowName('X offset')
                                AddVal('X_Offset', 0, LE.GridSize, -Win_W, Win_W, nil)
                                AddVal('X_Offset_VA')
                                SetRowName('Y offset')
                                AddVal('Y_Offset', 0, LE.GridSize, -220, 220, nil)
                                AddVal('Y_Offset_VA')
                                if SetRowName(WidthLBL, BL_Width) then
                                    AddVal('Width', nil, WidthStepSize, -Win_W, Win_W, nil , nil, true)
                                    AddVal('Width_VA', 0, 0.01, -1, 1)
                                end --[[ local rv, R =  AddRatio('Width' ) if rv then D.Width = R end   ]]
                                if SetRowName('Height', BL_Height) then
                                    AddVal('Height', 0, LE.GridSize, -220, 220, nil, nil, true )
                                    AddVal('Height_VA', 0, 0.01, -1, 1)
                                end
                                if SetRowName('Repeat', BL_Repeat) then
                                    AddVal('Repeat', 0, 1, 0, 300, '%.0f')
                                    AddVal('Repeat_VA', 0, 0.01, -1, 1)
                                end

                                if SetRowName('Gap', nil, Gap) then
                                    AddVal('Gap', 0, 0.2, 0, 300, '%.1f')
                                    AddVal('Gap_VA', 0, 0.01, -1, 1)
                                end
                                if D.Type ~= 'Gain Reduction Text' then
                                    if SetRowName('X Gap', BL_XYGap) then
                                        AddVal('X_Gap', 0, 0.2, 0, 300, '%.1f')
                                        AddVal('X_Gap_VA', 0, 0.01, -1, 1)
                                    end
                                    if SetRowName('Y Gap', BL_XYGap) then
                                        AddVal('Y_Gap', 0, 0.2, 0, 300, '%.1f')
                                        AddVal('Y_Gap_VA', 0, 0.01, -1, 1)
                                    end
                                end
                                if SetRowName('Angle Min', nil, BL_XYGap) then
                                    AddVal('Angle_Min', 0.75, 0.01, 0, 3.14, '%.3f', true)
                                end
                                if SetRowName('Angle Max', nil, BL_XYGap) then
                                    AddVal('Angle_Max', 2.25, 0.01, 0, 3.14, '%.3f', true)
                                end
                                if SetRowName('Radius Inner', nil, RadiusInOut) then
                                    if AddVal('Rad_In', FrstSelItm.Sldr_W or Df.KnobRadius, 0.1, 0, 300, '%.2f', true, true) then 
                                        D.Rad_Out = math.max(D.Rad_Out, D.Rad_In+0.1)
                                    end
                                end
                                if SetRowName('Radius Outer', nil, RadiusInOut) then
                                    if AddVal( 'Rad_Out', FrstSelItm.Sldr_W or Df.KnobRadius, 0.1, 0, 300, '%.2f', true,true ) then 
                                        D.Rad_In = math.min(D.Rad_In, D.Rad_Out-0.1)
                                    end 
                                end
                                if SetRowName('Radius', nil, Radius) then
                                    AddVal('Rad_In', FrstSelItm.Sldr_W or Df.KnobRadius, 0.1, 0, 300, '%.2f', true, true )
                                end

                                if SetRowName('Thickness', nil, Thick) then
                                    AddVal('Thick', 2, 0.5, 0, 60, '%.1f', true)
                                end
                                if SetRowName('Edge Round', nil, Round) then
                                    AddVal('Round', 0, 0.1, 0, 100, '%.1f', true)
                                end
                                --[[ if SetRowName('Font Size',GR_Text ) then

                                end ]]
                                SetRowName('Color')
                                im.TableSetColumnIndex(ctx, 1)

                                
                                local rv, Clr = im.ColorEdit4(ctx, 'Color' .. LBL, D.Clr or 0xffffffff, ClrFLG)
                                if rv then D.Clr = Clr end
                                if D.Repeat and D.Repeat ~= 0 then
                                    im.AlignTextToFramePadding(ctx)
                                    SL()
                                    im.Text(ctx, 'Start')
                                    SL(nil, 20)
                                    
                                    local rv, Clr = im.ColorEdit4(ctx, 'Repeat Color' .. LBL, D.RPT_Clr or 0xffffffff, ClrFLG)
                                    if rv then D.RPT_Clr = Clr end
                                    SL()
                                    im.Text(ctx, 'End')

                                end 
                                im.TableSetColumnIndex(ctx, 2)
                                local rv, Clr_VA = im.ColorEdit4(ctx, 'Color_VA' .. LBL, D.Clr_VA or 0xffffffff, ClrFLG)
                                if rv then D.Clr_VA = Clr_VA end



                                im.TableNextRow(ctx)

                                --[[ if D.Repeat and D.Repeat ~= 0 then
                                    SetRowName('Last Repeat\'s Color')
                                    im.TableSetColumnIndex(ctx, 1)

                                    local rv, Clr = im.ColorEdit4(ctx, 'Repeat Color' .. LBL, D.RPT_Clr or 0xffffffff, ClrFLG)
                                    if rv then D.RPT_Clr = Clr end
                                    im.TableNextRow(ctx)
                                end ]]


                                im.EndTable(ctx)
                            end


                            im.TreePop(ctx)
                        end
                    end




                    if im.Button(ctx, 'attach a new drawing') then
                        table.insert(FrstSelItm.Draw, {})
                    end

                    if im.Button(ctx, 'Save as a '..FrstSelItm.Type.. ' style') then 
                        im.OpenPopup(ctx, 'Enter name for the style:')
                        local x , y = im.GetCursorScreenPos(ctx)
                        im.SetNextWindowPos(ctx, x ,y )
                        im.SetNextWindowSize(ctx, 200, 100  )

                    end
                    if im.BeginPopupModal(ctx, 'Enter name for the style:') then


                        EnterNewName, NewName = im.InputText(ctx, '## Style Name', NewName, im.InputTextFlags_EnterReturnsTrue)
                        SL()
                        if  EnterNewName then 
                            Save_Attached_Drawings_As_Style(NewName, FrstSelItm.Type, FrstSelItm)
                            im.CloseCurrentPopup(ctx)
                            Tooltip.Txt, Tooltip.Dur,  Tooltip.time = 'Saved Successfully', 60 , 0
                        end
                        if im.IsKeyPressed(ctx,im.Key_Escape)then 
                            im.CloseCurrentPopup(ctx)
                            Tooltip.Txt, Tooltip.Dur,  Tooltip.time = 'Canceled', 60 , 0

                        end
                        im.EndPopup(ctx)
                   end
                    
                    im.TreePop(ctx)
                end

                im.PopStyleColor(ctx)
            end -------------------- End of Repeat for every selected item
            if LE.SelectedItem == 'Title' then
                im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x66666688)

                im.Text(ctx, 'Edge Round:')
                im.SameLine(ctx)
                Edited, FX[FxGUID].Round = im.DragDouble(ctx, '##' .. FxGUID .. 'Round',
                    FX[FxGUID].Round, 0.01, 0, 40, '%.2f')

                im.Text(ctx, 'Grab Round:')
                im.SameLine(ctx)
                Edited, FX[FxGUID].GrbRound = im.DragDouble(ctx, '##' .. FxGUID .. 'GrbRound',
                    FX[FxGUID].GrbRound, 0.01, 0, 40, '%.2f')

                im.Text(ctx, 'Background Color:')
                im.SameLine(ctx)
                _, FX[FxGUID].BgClr = im.ColorEdit4(ctx, '##' .. FxGUID .. 'BgClr',
                    FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff,
                    im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                    im.ColorEditFlags_AlphaBar)
                if FX[FxGUID].BgClr == im.GetColor(ctx, im.Col_FrameBg) then
                    HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 1, 1,
                        'GetItemRect')
                end

                im.Text(ctx, 'FX Title Color:')
                im.SameLine(ctx)
                _, FX[FxGUID].TitleClr = im.ColorEdit4(ctx, '##' .. FxGUID .. 'Title Clr',
                    FX[FxGUID].TitleClr or 0x22222233,
                    im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                    im.ColorEditFlags_AlphaBar)

                im.Text(ctx, 'Custom Title:')
                im.SameLine(ctx)
                local _, CustomTitle = im.InputText(ctx, '##CustomTitle' .. FxGUID,
                    FX[FxGUID].CustomTitle or FX_Name)
                if im.IsItemDeactivatedAfterEdit(ctx) then
                    FX[FxGUID].CustomTitle = CustomTitle
                end

                im.PopStyleColor(ctx)
            end








            if im.BeginPopupModal(ctx, 'Save Editing?') then
                SaveEditingPopupModal = true
                im.Text(ctx, 'Would you like to save the editings?')
                if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, im.Key_N) then
                    RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                    im.CloseCurrentPopup(ctx)
                    FX.LayEdit = nil
                    LE.SelectedItem = nil
                    CloseLayEdit = true
                end
                im.SameLine(ctx)

                if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, im.Key_Y) then
                    SaveLayoutEditings(FX_Name, FX_Idx, FxGUID)
                    im.CloseCurrentPopup(ctx)
                    FX.LayEdit = nil
                    LE.SelectedItem = nil
                    CloseLayEdit = true
                end
                im.SameLine(ctx)

                if im.Button(ctx, '(c) Cancel') or im.IsKeyPressed(ctx, im.Key_C) or im.IsKeyPressed(ctx, im.Key_Escape) then
                    im.CloseCurrentPopup(ctx)
                end



                im.EndPopup(ctx)
            end


            local PalletteW = 25
            local Pad = 10
            if not CloseLayEdit then
                w, h = im.GetWindowSize(ctx)
                im.SetCursorPos(ctx, w - PalletteW - Pad, PalletteW + Pad)
            end


            for Pal = 1, NumOfColumns or 1, 1 do
                if not CloseLayEdit and im.BeginChild(ctx, 'Color Palette' .. Pal, PalletteW, h - PalletteW - Pad * 2,nil, im.WindowFlags_NoScrollbar) then
                    local NumOfPaletteClr = 9
                    if FX[FxGUID] then 
                        for i, v in ipairs(FX[FxGUID]) do

                            local function CheckClr(Clr)
                                if Clr and not im.IsPopupOpen(ctx, '', im.PopupFlags_AnyPopupId) then
                                    if not tablefind(ClrPallet, Clr) and ClrPallet then
                                        local R, G, B, A = im.ColorConvertU32ToDouble4(Clr)
                                        if A ~= 0 then
                                            table.insert(ClrPallet, Clr)
                                        end
                                    end
                                end
                            end
                            CheckClr(v.Lbl_Clr)
                            CheckClr(v.V_Clr)
                            CheckClr(v.BgClr)
                            CheckClr(v.GrbClr)
                        end
                    end

                    if FX.Win_Name_S[FX_Idx] then
                        if Draw[FX.Win_Name_S[FX_Idx]] then
                            for i, v in ipairs(Draw[FX.Win_Name_S[FX_Idx]].clr) do
                                local Clr = v
                                if Clr and not im.IsPopupOpen(ctx, '', im.PopupFlags_AnyPopupId) then
                                    if not tablefind(ClrPallet, Clr) and ClrPallet then
                                        table.insert(ClrPallet, Clr)
                                    end
                                end
                            end
                        end
                    end

                    for i, v in ipairs(ClrPallet) do
                        clrpick, LblColor1 = im.ColorEdit4(ctx, '##ClrPalette' .. Pal ..
                            i .. FxGUID, v,
                            im.ColorEditFlags_NoInputs|
                            im.ColorEditFlags_AlphaPreviewHalf|
                            im.ColorEditFlags_AlphaBar)
                        if im.IsItemClicked(ctx) and Mods == Alt then
                            table.remove(ClrPallet, tablefind(v))
                        end
                    end


                    --[[ for i=1, NumOfPaletteClr , 1 do
                        PaletteClr= 'PaletteClr'..Pal..i..FxGUID
                        local DefaultClr        = im.ColorConvertHSVtoRGB((i-0.5)*(NumOfColumns or 1) / 7.0, 0.5, 0.5, 1)
                        clrpick,  _G[PaletteClr] = im.ColorEdit4( ctx, '##ClrPalette'..Pal..i..FxGUID,  _G[PaletteClr] or  DefaultClr , im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|im.ColorEditFlags_AlphaBar)
                        if im.IsItemDeactivatedAfterEdit(ctx) and i==NumOfPaletteClr  then NumOfColumns=(NumOfColumns or 1 )   +1    end
                        if im.BeginDragDropTarget( ctx) then HighlightSelectedItem(0x00000000 ,0xffffffff, 0, L,T,R,B,h,w, 1, 1,'GetItemRect', 'Foreground') end
                    end  ]]
                    im.EndChild(ctx)
                end
                if NumOfColumns or 1 > 1 then
                    for i = 1, NumOfColumns, 1 do im.SameLine(ctx, nil, 0) end
                end
            end





            if im.BeginPopupModal(ctx, 'Save Draw Editing?') then
                im.Text(ctx, 'Would you like to save the Drawings?')
                if im.Button(ctx, '(n) No') then
                    local FxNameS = FX.Win_Name_S[FX_Idx]
                    local HowManyToDelete
                    for i, Type in pairs(Draw[FxNameS].Type) do
                        HowManyToDelete = i
                    end

                    for Del = 1, HowManyToDelete, 1 do
                        local D = Draw[FxNameS]
                        table.remove(D.Type, i)
                        table.remove(D.L, i)
                        table.remove(D.R, i)
                        table.remove(D.T, i)
                        table.remove(D.B, i)
                        if D.Txt[i] then table.remove(D.Txt, i) end
                        if D.clr[i] then table.remove(D.clr, i) end
                    end
                    RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                    im.CloseCurrentPopup(ctx)
                    Draw.DrawMode[FxGUID] = nil
                end
                im.SameLine(ctx)

                if im.Button(ctx, '(y) Yes') then
                    SaveDrawings(FX_Idx, FxGUID)
                    im.CloseCurrentPopup(ctx)
                    Draw.DrawMode[FxGUID] = nil
                end
                im.EndPopup(ctx)
            end



            if im.IsKeyPressed(ctx, im.Key_A) and (Mods == Apl or Mods == Alt) then
                for Fx_P = 1, #FX[FxGUID] or 0, 1 do table.insert(LE.Sel_Items, Fx_P) end
            end


            im.End(ctx)
            if CloseLayEdit then
                FX.LayEdit = nil
                Draw.DrawMode[FxGUID] = nil
            end
        end





        im.SameLine(ctx, nil, 0)
        --im.PushStyleVar( ctx,im.StyleVar_WindowPadding, 0,0)
        --im.PushStyleColor(ctx, im.Col_DragDropTarget, 0x00000000)



        --if ctrl+A or Command+A is pressed


        --im.EndTooltip(ctx)

        -- im.PopStyleVar(ctx)
        --im.PopStyleColor(ctx,2 )
        PopClr(ctx, 2)
    end
end


function Retrieve_Attached_Drawings(Ct, Fx_P, FP)

    local DrawNum = RecallInfo(Ct, 'Number of attached drawings', Fx_P , 'Num')

    if DrawNum then


        FP.Draw = FP.Draw or {}
        for D = 1, DrawNum, 1 do

            FP.Draw[D] = FP.Draw[D] or {}
            local d = FP.Draw[D]
         
            local function RC(name, type, omit_if_0)
                local out = RecallInfo(Ct, 'Draw Item ' .. D .. ': ' .. name, Fx_P, type)
                if omit_if_0 and out == 0 then 
                    out = nil 
                end

                return out
            end
            d.Type = RC('Type')
            d.X_Offset = RC('X Offset', 'Num', true )
            d.X_Offset_VA = RC('X Offset Value Affect', 'Num')
            d.X_Offset_VA_GR = RC('X Offset Value Affect GR', 'Num')
            d.Y_Offset = RC('Y offset', 'Num', true)
            d.Y_Offset_VA = RC('Y Offset Value Affect', 'Num')
            d.Y_Offset_VA_GR = RC('Y Offset Value Affect GR', 'Num')
            d.Width = RC('Width', 'Num')
            d.Width_SS = RC('Width SS', 'Bool')
            d.Width_VA = RC('Width Value Affect', 'Num')
            d.Width_VA_GR = RC('Width Value Affect GR', 'Num')
            d.Clr = RC('Color', 'Num')
            d.Clr_VA = RC('Color_VA', 'Num')
            d.FillClr = RC('Fill Color', 'Num')
            d.Angle_Min = RC('Angle Min', 'Num')
            d.Angle_Max = RC('Angle Max', 'Num')
            d.Rad_In = RC('Radius Inner', 'Num')
            d.Rad_In_SS = RC('Radius Inner SS', 'Bool')
            d.Rad_Out = RC('Radius Outer', 'Num')
            d.Rad_Out_SS = RC('Radius Outer SS', 'Bool')
            d.Height = RC('Height', 'Num')
            d.Height_VA = RC('Height_VA', 'Num')
            d.Height_SS = RC('Height SS', 'Bool')
            d.Height_VA_GR = RC('Height_VA GR', 'Num')
            d.Round = RC('Round', 'Num')
            d.Thick = RC('Thick', 'Num')
            d.Repeat = RC('Repeat', 'Num')
            d.Repeat_VA = RC('Repeat_VA', 'Num')
            d.Repeat_VA_GR = RC('Repeat_VA GR', 'Num')
            d.Y_Repeat = RC('Y_Repeat', 'Num')
            d.Y_Repeat_VA = RC('Y_Repeat_VA', 'Num')
            d.Y_Repeat_VA_GR = RC('Y_Repeat_VA GR', 'Num')
            d.Gap = RC('Gap', 'Num')
            d.Gap_VA = RC('Gap_VA', 'Num')
            d.Gap_VA_GR = RC('Gap_VA GR', 'Num')
            d.X_Gap = RC('X_Gap', 'Num')
            d.X_Gap_VA = RC('X_Gap_VA', 'Num')
            d.X_Gap_VA_GR = RC('X_Gap_VA GR', 'Num')
            d.Y_Gap = RC('Y_Gap', 'Num')
            d.Y_Gap_VA = RC('Y_Gap_VA', 'Num')
            d.Y_Gap_VA_GR = RC('Y_Gap_VA GR', 'Num')
            d.RPT_Clr = RC('RPT_Clr', 'Num')


            local path = RC('Image_Path')
            msg(path)
            if path and path~='nil' then
                d.FilePath = path

                d.Image = im.CreateImage(r.GetResourcePath() .. d.FilePath)
                im.Attach(ctx, d.Image)
            end
        end

        return FP.Draw
    end
end



---@param ctx ImGui_Context
---@param label string
---@param labeltoShow string
---@param p_value number
---@param v_min number
---@param v_max number
---@param Fx_P integer
---@param FX_Idx integer
---@param P_Num number
---@param Style string
---@param Radius number
---@param item_inner_spacing number[]
---@param Disabled string
---@param LblTextSize integer
---@param Lbl_Pos "Top"|"Free"|"Bottom"|"Within"|"Left"|"None"|"Right"
---@param V_Pos? "Top"|"Free"|"Bottom"|"Within"|"Left"|"None"|"Right"
---@param ImgPath? ImGui_Image
---@return boolean
---@return number
function AddKnob(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, Style, Radius,
                 item_inner_spacing, Disabled, LblTextSize, Lbl_Pos, V_Pos, ImgPath)
    if Style == 'Pro C' then r.gmem_attach('ParamValues') end
    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    if not FxGUID then return end
    FX[FxGUID] = FX[FxGUID] or {}
    FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}

    if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl then im.BeginDisabled(ctx) end
    local p_value = p_value or 0
    local radius_outer = Radius or Df.KnobRadius;

    local FP = FX[FxGUID][Fx_P]
    local V_Font, Font = Arial_12, Font_Andale_Mono_12
    if LblTextSize ~= 'No Font' then
        Font = 'Arial_' .. roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)
        V_Font = 'Arial_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)
        im.PushFont(ctx, _G[Font])
    end
    local Radius       = Radius or 0

    local pos          = { im.GetCursorScreenPos(ctx) }
    local center       = { pos[1] + radius_outer, pos[2] + radius_outer }
    local Clr_SldrGrab = Change_Clr_A(getClr(im.Col_SliderGrabActive), -0.2)
    local TextW = im.CalcTextSize(ctx, labeltoShow or FX[FxGUID][Fx_P].Name, nil, nil, true)
    local CenteredLblPos, CenteredVPos
    im.BeginGroup(ctx)
    if TextW < (Radius or 0) * 2 then
        CenteredLblPos = pos[1] + Radius - TextW / 2
    else
        CenteredLblPos = pos[1]
    end


    if DraggingMorph == FxGUID then p_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end

    local line_height = im.GetTextLineHeight(ctx)
    local draw_list = im.GetWindowDrawList(ctx)
    local f_draw_list = im.GetForegroundDrawList(ctx)
    local item_inner_spacing = { item_inner_spacing, item_inner_spacing } or
        { { im.GetStyleVar(ctx, im.StyleVar_ItemInnerSpacing) } }
    local mouse_delta = { im.GetMouseDelta(ctx) }
    local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P] or 0

    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25
    local BtnOffset

    if Lbl_Pos == 'Top' then BtnOffset = -line_height end






    WhichClick()
    im.InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height + item_inner_spacing[2] + (BtnOffset or 0), ClickButton) -- ClickButton to alternate left/right dragging

    local is_active = im.IsItemActive(ctx)
    local is_hovered = im.IsItemHovered(ctx)
    local t = (p_value - v_min) / (v_max - v_min)
    local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
    local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
    local radius_inner = radius_outer * 0.40
    local ClrBg = im.GetColor(ctx, im.Col_FrameBg)

    local BtnL, BtnT = im.GetItemRectMin(ctx)
    local BtnR, BtnB = im.GetItemRectMax(ctx)

    local function Knob_Interaction()
            
        if ClickButton == im.ButtonFlags_MouseButtonLeft then                                -- left drag to adjust parameters
            if im.BeginDragDropSource(ctx, im.DragDropFlags_SourceNoPreviewTooltip) then
                im.SetDragDropPayload(ctx, 'my_type', 'my_data')
                --[[ Knob_Active  = true ]]
                Clr_SldrGrab = getClr(im.Col_Text)
        
                HideCursorTillMouseUp(0)
                im.SetMouseCursor(ctx, im.MouseCursor_None)
                if -mouse_delta[2] ~= 0.0 then
                    local stepscale = 1
                    if Mods == Shift then stepscale = 3 end
                    local step = (v_max - v_min) / (200.0 * stepscale)
                    p_value = p_value + (-mouse_delta[2] * step)
                    if p_value < v_min then p_value = v_min end
                    if p_value > v_max then p_value = v_max end
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
                    MvingP_Idx = F_Tp
                    Tweaking = P_Num .. FxGUID
                end
                im.EndDragDropSource(ctx)
            elseif ClickButton == im.ButtonFlags_MouseButtonRight and not AssigningMacro and not AssignContMacro then -- right drag to link parameters
                DnD_PLink_SOURCE(FX_Idx, P_Num)
            end
            KNOB = true
            DnD_PLink_TARGET(FxGUID, Fx_P, FX_Idx, P_Num) 
            ButtonDraw(FX[FxGUID].BgClr or CustomColorsDefault.FX_Devices_Bg, center, radius_outer)
            local focused_window, hwnd = GetFocusedWindow()
            if focused_window == "FX Devices" then
                r.JS_Window_SetFocus(hwnd)
                AdjustParamWheel(LT_Track, FX_Idx, P_Num)
            end
        end 


        --if user turn knob on ImGui
        if Tweaking == P_Num .. FxGUID then
            FX[FxGUID][Fx_P].V = p_value
            if not FP.WhichCC and not FP.Cont_Which_CC then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            else
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 0) -- 1 active, 0 inactive
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FX[FxGUID][Fx_P].V)
            end
        end

    end

    local function ShowTooltip_if_Active()
        if (is_hovered or Tweaking == P_Num .. FxGUID) and (V_Pos == 'None' or not V_Pos) then
            local get, PV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
            if get then
                local Y_Pos
                if Lbl_Pos == 'Top' then _, Y_Pos = im.GetCursorScreenPos(ctx) end
                local window_padding = { im.GetStyleVar(ctx, im.StyleVar_WindowPadding) }
                im.SetNextWindowPos(ctx, pos[1] + radius_outer / 2,
                    Y_Pos or pos[2] - line_height - window_padding[2] - 8)
                im.BeginTooltip(ctx)
                im.Text(ctx, PV)
                im.EndTooltip(ctx)
            end
            Clr_SldrGrab = getClr(im.Col_SliderGrabActive)
        end
    end

    local function Write_Label_And_Value()

        if FP.Lbl_Pos == 'Free' then
            local Cx, Cy = im.GetCursorScreenPos(ctx)
            im.DrawList_AddTextEx(draw_list, _G[Font], FP.FontSize or LblTextSize or Knob_DefaultFontSize,
                pos[1] + (FP.Lbl_Pos_X or 0), pos[2] + (FP.Lbl_Pos_Y or 0), FP.Lbl_Clr or getClr(im.Col_Text),
                FP.CustomLbl or FP.Name)
        end


        local BtnL, BtnT = im.GetItemRectMin(ctx)
        local BtnR, BtnB = im.GetItemRectMax(ctx)

        if Lbl_Pos == 'Top' then
            
            local Y = BtnT - line_height + item_inner_spacing[2] + (FP.Lbl_Pos_Y or 0)
            local X = (CenteredLblPos or pos[1]) + (FP.Lbl_Pos_X or 0)
            im.DrawList_AddTextEx(draw_list, _G[Font], FX[FxGUID][Fx_P].FontSize or Knob_DefaultFontSize, X, Y, FP.Lbl_Clr or 0xffffffff,
                labeltoShow or FP.Name--[[ , nil, pos[1], BtnT - line_height, pos[1] + Radius * 2, BtnT + line_height ]])
        end
    end

    local function Drawings_For_Styles()
        if Style == 'Pro C' then
            local offset; local TxtClr = 0xD9D9D9ff
            if labeltoShow == 'Release' then offset = 5 else offset = nil end

            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer, FX[FxGUID][Fx_P].BgClr or 0xC7A47399)
            im.DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner, center[2] + angle_sin * radius_inner, center[1] + angle_cos * (radius_outer - 2), center[2] + angle_sin * (radius_outer - 2), FX[FxGUID][Fx_P].GrbClr or 0xDBDBDBff, FX[FxGUID][Fx_P].Value_Thick or 2.0)
            local TextW, h = im.CalcTextSize(ctx, labeltoShow, nil, nil, true)
            if Disabled == 'Pro C Ratio Disabled' then
                local CompStyle = 'CompStyle##Value'
                if _G[CompStyle] == 'Vocal' then
                    im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer, 0x000000aa)
                    TxtClr = 0x55555577
                end
            end
            --if string.find(FX_Name, 'Pro%-C 2') then
            --    im.DrawList_AddText(draw_list, center[1]-TextW/2+ (offset or 0)   , pos[2] + radius_outer * 2 + item_inner_spacing[2], TxtClr, labeltoShow)
            --end





            local txtX = center[1] - TextW / 2; local txtY = pos[2] + radius_outer * 2 + item_inner_spacing[2]

            ---@param Label string
            ---@param offset number
            ---@param Rect_offset? number
            local function AutoBtn(Label, offset, Rect_offset)
                if labeltoShow == Label then
                    MouseX, MouseY = im.GetMousePos(ctx)
                    im.DrawList_AddText(draw_list, center[1] - TextW / 2 + (offset or 0),
                        pos[2] + radius_outer * 2 + item_inner_spacing[2], 0xFFD57144, 'A')

                    if MouseX > txtX and MouseX < txtX + TextW and MouseY > txtY - 4 and MouseY < txtY + 10 then
                        im.DrawList_AddRectFilled(draw_list, txtX + (Rect_offset or 0), txtY,
                            txtX + TextW + (Rect_offset or 0), txtY + 10, 0x99999955, 3)
                        im.DrawList_AddText(draw_list, center[1] - TextW / 2 + (offset or 0),
                            pos[2] + radius_outer * 2 + item_inner_spacing[2], 0xFFD57166, 'A')
                        if IsLBtnClicked and Label == 'Release' then
                            AutoRelease = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 7)
                            if AutoRelease == 1 then
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 7, 0)
                                AutoRelease = 0
                            else
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 7, 1)
                                AutoRelease = 1
                            end
                        elseif IsLBtnClicked and Label == 'Gain' then
                            AutoGain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 14)
                            if AutoGain == 1 then
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 14, 0)
                                AutoGain = 0
                            else
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 14, 1)
                                AutoGain = 1
                            end
                        end
                    end

                    if Label == 'Release' then
                        if not AutoRelease then AutoRelease = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 7) end
                        if AutoRelease == 1 then
                            im.DrawList_AddText(draw_list, center[1] - TextW / 2 + (offset or 0),
                                pos[2] + radius_outer * 2 + item_inner_spacing[2], 0xFFD571ff, 'A')
                        end
                    end
                    if Label == 'Gain' then
                        if not AutoGain then AutoGain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 14) end
                        if AutoGain == 1 then
                            im.DrawList_AddText(draw_list, center[1] - TextW / 2 + (offset or 0),
                                pos[2] + radius_outer * 2 + item_inner_spacing[2], 0xFFD571ff, 'A')
                        end
                    end
                end
            end

            AutoBtn('Release', -8, 3)
            AutoBtn('Gain', -8)

            if is_active or is_hovered then
                if labeltoShow == 'Release' or labeltoShow == 'Gain' and MouseX > txtX and MouseX < txtX + TextW and MouseY > txtY - 4 and MouseY < txtY + 10 then
                else
                    if is_active then
                        im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer,
                            FX[FxGUID][Fx_P].BgClrAct or 0xE4B96B99)
                        im.DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner,
                            center[2] + angle_sin * radius_inner, center[1] + angle_cos * (radius_outer - 2),
                            center[2] + angle_sin * (radius_outer - 2), FP.V_Clr or 0xDBDBDBff, 2.0)
                    elseif is_hovered then
                        im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, 0xE4B96B99)
                        --im.DrawList_AddLine(draw_list, center[1] + angle_cos*radius_inner, center[2] + angle_sin*radius_inner, center[1] + angle_cos*(radius_outer-2), center[2] + angle_sin*(radius_outer-2), FP.V_Clr or  0xDBDBDBff, 2.0)
                    end
                end
            end
        elseif Style == 'FX Layering' then
            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer,
                FX[FxGUID][Fx_P].BgClr or im.GetColor(ctx, im.Col_Button), 16)
            im.DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner,
                center[2] + angle_sin * radius_inner,
                center[1] + angle_cos * (radius_outer - 2), center[2] + angle_sin * (radius_outer - 2),
                FX[FxGUID][Fx_P].GrbClr or Clr_SldrGrab, 2.0)
            im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 2, ANGLE_MAX - ANGLE_MIN, angle)
            im.DrawList_PathStroke(draw_list, 0x99999922, nil, radius_outer * 0.6)
            im.DrawList_PathClear(draw_list)

            im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 2, ANGLE_MAX + 1.35,
                ANGLE_MAX + 0.15)
            im.DrawList_PathStroke(draw_list, im.GetColor(ctx, im.Col_FrameBg), nil, radius_outer)

            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_inner,
                im.GetColor(ctx,
                    is_active and im.Col_FrameBgActive or is_hovered and im.Col_FrameBgHovered or
                    im.Col_FrameBg), 16)
        elseif Style == 'Custom Image' then
            local Image = ImgPath or FP.Image
            if Image then
                local w, h = im.Image_GetSize(Image)

                if h > w * 5 then -- It's probably a strip knob file
                    local scale = 2
                    local sz = radius_outer * scale


                    uvmin, uvmax = Calc_strip_uv(Image, FP.V or FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num))


                    im.DrawList_AddImage(WDL, Image, center[1] - sz / 2, center[2] - sz / 2, center[1] + sz / 2,
                        center[2] + sz / 2, 0, uvmin, 1, uvmax, FP.BgClr or 0xffffffff)
                else
                    local scale = 2
                    local sz = radius_outer * scale
                    ImageAngle(ctx, Image, 4 + FP.V * 4.5, sz, sz, center[1] - sz / 2, center[2] - sz / 2)
                end
            end
        elseif Style == 'Invisible' then
        else -- for all generic FXs
            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer,
                FX[FxGUID][Fx_P].BgClr or im.GetColor(ctx, im.Col_Button))
            im.DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner,
                center[2] + angle_sin * radius_inner,
                center[1] + angle_cos * (radius_outer - 2), center[2] + angle_sin * (radius_outer - 2),
                FX[FxGUID][Fx_P].GrbClr or Clr_SldrGrab, FX[FxGUID][Fx_P].Value_Thick or 2)
            im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 2, ANGLE_MIN, angle)
            im.DrawList_PathStroke(draw_list, 0x99999922, nil, radius_outer * 0.6)
            im.DrawList_PathClear(draw_list)
            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_inner,
                im.GetColor(ctx,
                    is_active and im.Col_FrameBgActive or is_hovered and im.Col_FrameBgHovered or
                    im.Col_FrameBg))
        end
    end

    local function Enable_Preset_Morph_Edit()
        if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl and FX[FxGUID].MorphA and FX[FxGUID].MorphB then
            im.EndDisabled(ctx)

            if FX[FxGUID].MorphA[P_Num] and FX[FxGUID].MorphB[P_Num] then
                im.SetCursorScreenPos(ctx, pos[1], pos[2])
                local sizeX, sizeY = im.GetItemRectSize(ctx)
                im.InvisibleButton(ctx, label, sizeX, sizeY)



                --local A = SetMinMax(PosL+ sizeX*FX[FxGUID].MorphA[P_Num],PosL, PosR)
                --local B = SetMinMax(PosL+ sizeX*FX[FxGUID].MorphB[P_Num],PosL,PosR)
                local A = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * FX[FxGUID].MorphA[P_Num]
                local B = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * FX[FxGUID].MorphB[P_Num]

                local ClrA, ClrB = Morph_A or CustomColorsDefault.Morph_A , Morph_B or CustomColorsDefault.Morph_B
                local MsX, MsY = im.GetMousePos(ctx)

                if FX[FxGUID].MorphA[P_Num] ~= FX[FxGUID].MorphB[P_Num] then
                    --im.DrawList_PathArcTo( draw_list,  center[1] , center[2],(radius_inner+ radius_outer)/2, A , B)
                    FX[FxGUID].Angle1 = angle
                    FX[FxGUID].Angle2 = angle + (ANGLE_MAX - ANGLE_MIN) * 0.5
                    local angle_cos, angle_sin = math.cos(A), math.sin(A)
                    im.DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
                        center[2] + angle_sin * (radius_outer - 2), ClrA, 2.0)
                    local angle_cos, angle_sin = math.cos(B), math.sin(B)
                    im.DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
                        center[2] + angle_sin * (radius_outer - 2), ClrB, 2.0)


                    im.DrawList_PathStroke(draw_list, ClrA, nil, radius_outer * 0.2)
                    im.DrawList_PathClear(draw_list)
                    --im.DrawList_AddRectFilledMultiColor(WDL,A,PosT,B,PosB,ClrA, ClrB, ClrB,ClrA)
                end

                local txtClr = im.GetStyleColor(ctx, im.Col_Text)

                if im.IsItemClicked(ctx) or im.IsItemClicked(ctx, 1) then
                    if IsLBtnClicked or IsRBtnClicked then
                        FP.TweakingAB_Val = P_Num
                        retval, Orig_Baseline = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline")
                    end
                    if not FP.TweakingAB_Val then
                        local offsetA, offsetB
                        --if A<B+5 and A>B-14 then offsetA=-10      offsetB = 10 end
                        --im.DrawList_AddTextEx(WDL,Font_Andale_Mono_20_B, 16, A, PosT+(offsetA or 0), txtClr,'A')
                        --im.DrawList_AddTextEx(WDL,Font_Andale_Mono_20_B, 16, B, PosT+(offsetB or 0), txtClr, 'B')
                    end
                end

                if FP.TweakingAB_Val == P_Num and not MorphingMenuOpen then
                    local X_A, X_B
                    local offsetA, offsetB
                    if IsLBtnHeld then
                        local drag = FX[FxGUID].MorphA[P_Num] + select(2, im.GetMouseDelta(ctx)) * -0.01
                        FX[FxGUID].MorphA[P_Num] = SetMinMax(drag, 0, 1)
                        if FX[FxGUID].Morph_ID then -- if Morph Sldr is linked to a CC
                            local A = (MsY - BtnT) / sizeY
                            local Scale = FX[FxGUID].MorphB[P_Num] - A
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 1)     -- 1 active, 0 inactive
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.scale", Scale)  -- Scale
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -100)  -- -100 enables midi_msg*
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.param", -1)     -- -1 not parameter link
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 15)  -- 0 based, 15 = Bus 16
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 16) -- 0 based, 0 = Omni
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg", 160) -- 160 is Aftertouch
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2",
                                FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline", A)     -- Baseline
                        end
                    elseif IsRBtnHeld then
                        local drag = FX[FxGUID].MorphB[P_Num] + select(2, im.GetMouseDelta(ctx, 1)) * -0.01
                        FX[FxGUID].MorphB[P_Num] = SetMinMax(drag, 0, 1)
                        if FX[FxGUID].Morph_ID then                                                                     -- if Morph Sldr is linked to a CC
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 1)     -- 1 active, 0 inactive
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.scale",
                                FX[FxGUID].MorphB[P_Num] - FX[FxGUID].MorphA[P_Num])                                    -- Scale
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -100)  -- -100 enables midi_msg*
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.param", -1)     -- -1 not parameter link
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 15)  -- 0 based, 15 = Bus 16
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 16) -- 0 based, 0 = Omni
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg", 160) -- 160 is Aftertouch
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2",
                                FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline",
                                Orig_Baseline)                                                                          -- Baseline
                        end
                    end
                    if IsLBtnHeld then
                        X_A = MsX
                        Y_A = MsY - 15
                        offsetA = -10
                        if MsX < B + 5 and MsX > B - 14 then offsetB = 10 end
                    elseif IsRBtnHeld then
                        X_B = MsX
                        offsetB = -10
                        if MsX < A + 5 and MsX > A - 14 then offsetA = 10 end
                    end

                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, A, BtnT + (offsetA or 0), txtClr, 'A')
                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, B, BtnT + (offsetB or 0), txtClr, 'B')
                    if LBtnRel or RBtnRel then
                        StoreAllPrmVal('A', 'Dont')
                        StoreAllPrmVal('B', 'Dont')
                        FP.TweakingAB_Val = nil
                    end
                end
            end
            im.BeginDisabled(ctx)
        end
    end

    local function Write_Bottom_Labels_And_Values()

        if Lbl_Pos == 'Bottom' then --Write Bottom Label
            local T = pos[2] + radius_outer * 2 + item_inner_spacing[2]; local R = pos[1] + radius_outer * 2; local L =pos[1]
            local X, Y = CenteredLblPos or pos[1] + (FP.Lbl_Pos_X or 0), pos[2] + radius_outer * 2 + item_inner_spacing[2] + (FP.Lbl_Pos_Y or 0 )
            local Clr = FX[FxGUID][Fx_P].Lbl_Clr or 0xffffffff
            local FontSize = FX[FxGUID][Fx_P].FontSize or Knob_DefaultFontSize

            im.DrawList_AddTextEx(draw_list, _G[Font], FX[FxGUID][Fx_P].FontSize or Knob_DefaultFontSize, X, Y, Clr,labeltoShow or FX[FxGUID][Fx_P].Name--[[ , (Radius or 20) * 2, X, Y, X + (Radius or 20) * 2, Y + FontSize * 2 ]])
        end 
        if V_Pos ~= 'None' and V_Pos then
            im.PushFont(ctx, _G[V_Font])
    
            _, FormatPV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
            if FX[FxGUID][Fx_P].ValToNoteL then
                FormatPV = StrToNum(FormatPV)
                tempo = r.Master_GetTempo()
                local num = FormatPV:gsub('[^%p%d]', '')
                noteL = num * tempo / 60000
    
    
                if noteL > 0.99 and noteL < 1.99 then
                    FormatPV = roundUp(noteL, 1) .. '/4'
                elseif noteL > 1.99 then
                    FormatPV = roundUp(noteL, 2) .. '/4'
                elseif noteL > 0.49 and noteL < 0.99 then
                    FormatPV = '1/8'
                elseif noteL > 0.24 and noteL < 0.49 then
                    FormatPV = '1/16'
                elseif noteL > 0.124 and noteL < 0.24 then
                    FormatPV = '1/32'
                elseif noteL < 0.124 then
                    FormatPV = '1/64'
                end
            end
    
            if FX[FxGUID][Fx_P].V_Round then FormatPV = RoundPrmV(FormatPV, FX[FxGUID][Fx_P].V_Round) end
    
    
            local ValueTxtW = im.CalcTextSize(ctx, FormatPV, nil, nil, true)
            if ValueTxtW < Radius * 2 then
                CenteredVPos = pos[1] + Radius - ValueTxtW / 2
            else
                CenteredVPos = pos[1]
            end
            local Y_Offset, drawlist
    
            if V_Pos == 'Within' then 
                Y_Offset = radius_outer * 1.2 
            end
            if is_active or is_hovered then drawlist = Glob.FDL else drawlist = draw_list end
            if V_Pos ~='Free' then
                Align_Text_To_Center_Of_X(FormatPV, radius_outer * 2, FP.V_Pos_X, (FP.V_Pos_Y or 0) - (Y_Offset or 0))
                MyText(FormatPV,  _G[V_Font], FX[FxGUID][Fx_P].V_Clr or 0xffffffff)
                --[[ im.DrawList_AddTextEx(draw_list, _G[V_Font], FX[FxGUID][Fx_P].V_FontSize or Knob_DefaultFontSize,
                    CenteredVPos, pos[2] + radius_outer * 2 + item_inner_spacing[2] - (Y_Offset or 0),
                    FX[FxGUID][Fx_P].V_Clr or 0xffffffff, FormatPV--[[ , (Radius or 20) * 2 ]]
            end
            im.PopFont(ctx)
        end
    
        if V_Pos == 'Free' then
            local Ox, Oy = im.GetCursorScreenPos(ctx)
            im.DrawList_AddTextEx(draw_list, _G[V_Font], FX[FxGUID][Fx_P].V_FontSize or Knob_DefaultFontSize,
                pos[1] + (FP.V_Pos_X or 0), pos[2] + (FP.V_Pos_Y or 0), FX[FxGUID][Fx_P].V_Clr or 0xffffffff, FormatPV)--,(Radius or 20) * 2)
        end
        if Lbl_Pos == 'Within' and Style == 'FX Layering' then
            local ValueTxtW = im.CalcTextSize(ctx, labeltoShow, nil, nil, true)
            CenteredVPos = pos[1] + Radius - ValueTxtW / 2 + 0.5
            Y_Offset = radius_outer * 1.3 - 1
    
            im.DrawList_AddTextEx(draw_list, _G[V_Font], 10, CenteredVPos,
                pos[2] + radius_outer * 2 + item_inner_spacing[2] - (Y_Offset or 0), FX[FxGUID][Fx_P].V_Clr or 0xffffff88,
                labeltoShow--[[ , (Radius or 20) * 2 ]])
        end
    end

    local function Modulation_related()
        if PM.TimeNow ~= nil then
            if r.time_precise() > PM.TimeNow + 1 then
                r.gmem_write(7, 0) --tells jsfx to stop retrieving P value
                r.gmem_write(8, 0)
                PM.TimeNow = nil
            end
        end

        if FP.ModAMT or FP.Cont_ModAMT then -- Draw modlines  circular
            --im.DrawListSplitter_SetCurrentChannel(FX[FxGUID].splitter,2)

            local offset = 0
            local BipOfs = 0
            FP.ModBipolar = FP.ModBipolar or {}
            local Amt = FP.ModAMT or FP.Cont_ModAMT

        

            for Macro, v in ipairs(MacroNums) do
                if Amt[Macro] then
                    local IndicClr = EightColors.bgWhenAsgnModAct[Macro]
                    local rangeClr = EightColors.bgWhenAsgnModHvr[Macro]
                    if Amt ==FP.Cont_ModAMT then 
                        IndicClr = CustomColorsDefault.Container_Accent_Clr_Not_Focused
                        rangeClr = Change_Clr_A(CustomColorsDefault.Container_Accent_Clr_Not_Focused , -0.3)

                        if If_Hvr_or_Macro_Active (FxGUID, Macro) then 
                            IndicClr = CustomColorsDefault.Container_Accent_Clr
                            rangeClr = Change_Clr_A(IndicClr , - 0.3)
                        end 
                    end
                    --if Modulation has been assigned to params
                    local P_V_Norm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

                    --- indicator of where the param is currently
                    local PosAftrMod = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * (P_V_Norm)

                    if FP.ModBipolar[Macro] then
                        BipOfs = -Amt[Macro] 
                    end

                    im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer * 0.75, angle, PosAftrMod)
                    im.DrawList_PathStroke(draw_list, rangeClr, nil, radius_outer / 2)
                    im.DrawList_PathClear(draw_list)

                    --- shows modulation range
                    local Range = SetMinMax(angle + (ANGLE_MAX - ANGLE_MIN) * Amt[Macro] , ANGLE_MIN, ANGLE_MAX)
                    local angle = angle
                    if BipOfs ~= 0 then
                        local Range = SetMinMax(angle + (ANGLE_MAX - ANGLE_MIN) * -(Amt[Macro] ), ANGLE_MIN, ANGLE_MAX)
                        im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer - 1 + offset, angle, Range)
                        im.DrawList_PathStroke(draw_list, IndicClr, nil, radius_outer * 0.1)
                        im.DrawList_PathClear(draw_list)
                    end
                    im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer - 1 + offset, angle, Range)

                    im.DrawList_PathStroke(draw_list, IndicClr, nil, radius_outer * 0.1)
                    im.DrawList_PathClear(draw_list)

                    ParamHasMod_Any = true

                    offset = offset + OffsetForMultipleMOD
                end
            end
        end -- of reapeat for every macro

        if Trk.Prm.Assign and F_Tp == Trk.Prm.Assign and AssigningMacro then
            local M = AssigningMacro

            RightBtnDragX, RightBtnDragY = im.GetMouseDragDelta(ctx, x, y, 1)

            FP.ModAMT[M] = ((-RightBtnDragY / 100) or 0) + (FP.ModAMT[M] or 0)

            if FP.ModAMT[M] + p_value > 1 then FP.ModAMT[M] = 1 - p_value end
            if FP.ModAMT[M] + p_value < 0 then FP.ModAMT[M] = -p_value end

            local BipolarOut
            if Mods == Alt then
                FP.ModAMT[M] = math.abs(FP.ModAMT[M])
                BipolarOut = FP.ModAMT[M] + 100

                FP.ModBipolar[M] = true
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar', 'True', true)
            else
                FP.ModBipolar[M] = nil
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar', '', true)
            end


            r.gmem_write(4, 1) --tells jsfx that user is changing Mod Amount
            r.gmem_write(1000 * AssigningMacro + Trk.Prm.Assign, BipolarOut or FP.ModAMT[M])
            im.ResetMouseDragDelta(ctx, 1)

            r.SetProjExtState(0, 'FX Devices', 'Param -' .. Trk.Prm.Assign .. 'Macro - ' .. AssigningMacro .. FxGUID,
                FP.ModAMT[M])
        end



        if AssigningMacro  then
            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer, EightColors.bgWhenAsgnMod[AssigningMacro], 16)
        end
    end


    local function Highlight_Prm_If_User_Use_Actual_UI_To_Tweak()
        if LT_ParamNum == P_Num and focusedFXState == 1 and LT_FXGUID == FxGUID   then
            if not FP.WhichCC then 
                local LT_ParamValue = r.TrackFX_GetParamNormalized(LT_Track, LT_FX_Number, LT_ParamNum)
                p_value = LT_ParamValue
                FP.V = p_value
            end
    
            local L, T = im.GetItemRectMin(ctx);
    
            im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, 0xffffffff, 16)
            for m = 1, 8, 1 do
                if AssigningMacro == m then
                    im.PopStyleColor(ctx, 2)
                end
            end
        end
    
    end

    Knob_Interaction()
    MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, 'knob')


    Write_Label_And_Value()
    ShowTooltip_if_Active()
    Drawings_For_Styles()
    Enable_Preset_Morph_Edit()
    RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)
    Write_Bottom_Labels_And_Values()

    Modulation_related()    
    Highlight_Prm_If_User_Use_Actual_UI_To_Tweak()





    local AlreadyAddPrm = false

    


    IfTryingToAddExistingPrm(Fx_P, FxGUID, 'Circle', center[1], center[2], nil, nil, radius_outer)



    --repeat for every param stored on track...


    if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl then im.EndDisabled(ctx) end


    if LblTextSize ~= 'No Font' then im.PopFont(ctx) end

    im.EndGroup(ctx)
end

---@param ctx ImGui_Context
---@param label string
---@param labeltoShow string
---@param p_value number
---@param v_min number
---@param v_max number
---@param Fx_P integer
---@param FX_Idx integer
---@param P_Num number
---@param SliderStyle string
---@param Sldr_Width number
---@param item_inner_spacing number
---@param Disable string | nil
---@param Vertical string
---@param GrabSize number
---@param BtmLbl string
---@param SpacingBelow number
---@param Height? number
---@return boolean value_changed
---@return number p_value
function AddSlider(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, SliderStyle, Sldr_Width,
                   item_inner_spacing, Disable, Vertical, GrabSize, BtmLbl, SpacingBelow, Height)
    local PosL, PosR, PosT, PosB
    local ClrPop = 0
    local pos = { im.GetCursorScreenPos(ctx) }

    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

    local line_height = im.GetTextLineHeight(ctx)
    local draw_list = im.GetWindowDrawList(ctx)
    local f_draw_list = im.GetForegroundDrawList(ctx)
    local _, Format_P_V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)

    local mouse_delta = { im.GetMouseDelta(ctx) }
    if not FxGUID then return end

    local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P] or 0
    FX[FxGUID] = FX[FxGUID] or {}
    FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
    local FP = FX[FxGUID][Fx_P]
    local Font = 'Font_Andale_Mono_' .. roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    local V_Font = 'Arial_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)
    if Vertical == 'Vert' then ModLineDir = Height else ModLineDir = Sldr_Width end






    if LBtnDC then  im.PushStyleVar(ctx, im.StyleVar_DisabledAlpha, 1) end
    if FX[FxGUID][Fx_P].Name then
        local CC = FP.WhichCC or -1


        if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl or LBtnDC then im.BeginDisabled(ctx) end

        if item_inner_spacing then
            im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, item_inner_spacing, item_inner_spacing)
        end

        im.BeginGroup(ctx)
        local function PushClrs()
            if SliderStyle == 'Pro C Thresh' then
                im.PushStyleColor(ctx, im.Col_FrameBg, 0x99999900); im.PushStyleColor(ctx,
                    im.Col_FrameBgActive, 0x99999922)
                im.PushStyleColor(ctx, im.Col_FrameBgHovered, 0x99999922)
                ClrPop = 3;
            elseif FX[FxGUID][Fx_P].BgClr and SliderStyle == nil then
                im.PushStyleColor(ctx, im.Col_FrameBg, FX[FxGUID][Fx_P].BgClr)
                im.PushStyleColor(ctx, im.Col_FrameBgHovered, FX[FxGUID][Fx_P].BgClrHvr)
                im.PushStyleColor(ctx, im.Col_FrameBgActive, FX[FxGUID][Fx_P].BgClrAct)
                ClrPop = 3
            else
                ClrPop = 0 --im.PushStyleColor(ctx, im.Col_FrameBg, 0x474747ff) ClrPop =1
            end
            if GrabSize then im.PushStyleVar(ctx, im.StyleVar_GrabMinSize, GrabSize) end

            if FP.GrbClr then
                local ActV
                local R, G, B, A = im.ColorConvertU32ToDouble4(FP.GrbClr)
                local H, S, V = im.ColorConvertRGBtoHSV(R, G, B)
                if V > 0.9 then ActV = V - 0.2 end
                local R, G, B = im.ColorConvertHSVtoRGB(H, S, ActV or V + 0.2)
                local ActClr = im.ColorConvertDouble4ToU32(R, G, B, A)
                im.PushStyleColor(ctx, im.Col_SliderGrab, FP.GrbClr)
                im.PushStyleColor(ctx, im.Col_SliderGrabActive, ActClr)
                ClrPop = ClrPop + 2
            end
        end

        local function Write_Label_And_Value()


            if Vertical == 'Vert' then
                if FP.Lbl_Pos == 'Top' then
                    Align_Text_To_Center_Of_X(labeltoShow or FP.Name, Sldr_Width, FP.Lbl_Pos_X, FP.Lbl_Pos_Y)
                    MyText(labeltoShow or FP.Name, _G[Font], FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
                end
                if FP.V_Pos == 'Top' then
                    local Get, Param_Value = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
                    Align_Text_To_Center_Of_X(Param_Value, Sldr_Width, FP.Lbl_Pos_X, FP.Lbl_Pos_Y)
                    if Get then MyText(Param_Value, _G[V_Font], FP.V_Clr or im.GetColor(ctx, im.Col_Text)) end
                end
            else
                if FP.Lbl_Pos == 'Top' then
                    MyText(labeltoShow or FP.Name, _G[Font], FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
                end
                if FP.V_Pos == 'Top' then
                    local Get, Param_Value = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)

                    local x = im.GetCursorPosX(ctx)
                    local TextW = im.CalcTextSize(ctx, Param_Value, nil, nil, true, -100)

                    im.SetCursorPosX(ctx, x+ Sldr_Width - TextW)
                    if Get then  MyText(Param_Value, _G[V_Font], FP.V_Clr or im.GetColor(ctx, im.Col_Text)) end 
                end
            end

            if FP.Lbl_Pos == 'Left' then
                im.PushFont(ctx, _G[Font])
                im.AlignTextToFramePadding(ctx)
                im.TextColored(ctx, FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text), labeltoShow or FP.Name)
                SL()
                im.PopFont(ctx)
            end
        end

        local function MakeSlider()
            if not Sldr_Width or Sldr_Width == '' then Sldr_Width = FX.Def_Sldr_W[FxGUID] or Def_Sldr_W or 160 end
            im.SetNextItemWidth(ctx, Sldr_Width)
            if Vertical == 'Vert' then
                _, p_value = im.VSliderDouble(ctx, label, Sldr_Width, FP.Height or Height, p_value, v_min, v_max, ' ')
            else
                _, p_value = im.SliderDouble(ctx, label, p_value, v_min, v_max, ' ', im.SliderFlags_NoInput)
            end
        end

        local function Suzukis_Work_ParamLink_And_MouseWheelAdjust()

            im.SetNextItemAllowOverlap( ctx)
            KNOB = false
            DnD_PLink_TARGET(FxGUID, Fx_P, FX_Idx, P_Num)
            ButtonDraw(FX[FxGUID].BgClr or CustomColorsDefault.FX_Devices_Bg, nil, nil)
            local focused_window, hwnd = GetFocusedWindow()
            if focused_window == "FX Devices" then
                r.JS_Window_SetFocus(hwnd)
                AdjustParamWheel(LT_Track, FX_Idx, P_Num)
            end
            --[[ im.InvisibleButton(ctx, '##plink' .. P_Num, PosR - PosL, PosB - PosT, ClickButton) -- for parameter link
            if ClickButton == im.ButtonFlags_MouseButtonRight and not AssigningMacro then    -- right drag to link parameters
                DnD_PLink_SOURCE(FX_Idx, P_Num)
            end ]]
        end

        PushClrs()
        Write_Label_And_Value()


        FP.V = FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
        if DraggingMorph == FxGUID then p_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end

        MakeSlider()
        Suzukis_Work_ParamLink_And_MouseWheelAdjust()


        if GrabSize then im.PopStyleVar(ctx) end
        im.PopStyleColor(ctx, ClrPop)

        RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)

        local SldrR, SldrB = im.GetItemRectMax(ctx)
        local SldrL, SldrT = im.GetItemRectMin(ctx)

        PosL, PosT = im.GetItemRectMin(ctx)
        PosR, PosB = im.GetItemRectMax(ctx)
        local is_active = im.IsItemActive(ctx)
        local is_hovered = im.IsItemHovered(ctx)

        local button_x, button_y = im.GetCursorPos(ctx)
        --im.SetCursorPosY(ctx, button_y - (PosB - PosT))
        --WhichClick()


        local value_changed = false

        --[[ if is_active == true then Knob_Active = true end
        if Knob_Active == true then
            if IsLBtnHeld == false then Knob_Active = false end
        end ]]

        if SliderStyle == 'Pro C' then
            SldrLength = PosR - PosL
            SldrGrbPos = SldrLength * p_value
            if is_active then
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xFFD571bb, Rounding)
            elseif is_hovered then
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xDFB973bb, Rounding)
            else
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0x888888bb, Rounding)
            end
        end

        if Disable == 'Disabled' then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0x000000cc, Rounding)
        end

        if is_active then
            p_value = SetMinMax(p_value, v_min, v_max)
            value_changed = true
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            MvingP_Idx = CC
            Tweaking = P_Num .. FxGUID
        end

        local tooltip_Tirgger = (is_active or is_hovered) and (FP.V_Pos == 'None' or not FP.V_Pos )
        local SzX, SzY = im.GetItemRectSize(ctx)
        local MsX, MsY = im.GetMousePos(ctx)
        Show_Value_Tooltip(tooltip_Tirgger, SetMinMax(MsX, pos[1], pos[1] + SzX), pos[2] - SzY - line_height + button_y , Format_P_V )

        local t            = (p_value - v_min) / (v_max - v_min)
        local Clr_SldrGrab = im.GetColor(ctx, im.Col_SliderGrabActive)
        local ClrBg        = im.GetColor(ctx, im.Col_FrameBg)




        --[[ if is_active or is_hovered then
        local window_padding = {im.GetStyleVar(ctx, im.StyleVar_WindowPadding)}
        im.SetNextWindowPos(ctx, pos[1] - window_padding[1], pos[2] - line_height - item_inner_spacing[2] - window_padding[2])
        im.BeginTooltip(ctx)
        im.Text(ctx, ('%.3f'):format(p_value))
        im.EndTooltip(ctx)
        end ]]


        --if user turn knob on ImGui
        if not P_Num then P_Num = 0 end
        if Tweaking == P_Num .. FxGUID then
            FX[FxGUID][Fx_P].V       = p_value
            local getSlider, P_Value = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
            ---!!! ONLY ACTIVATE TOOLTIP IF VALUE IS HIDDEN
            --[[ if getSlider  then
                local window_padding = {im.GetStyleVar(ctx, im.StyleVar_WindowPadding)}
                im.SetNextWindowPos(ctx, pos[1] - window_padding[1], pos[2] - line_height - window_padding[2] -8)
                im.BeginTooltip(ctx)
                im.Text(ctx, P_Value)
                im.EndTooltip(ctx)
            end  ]]
            if Trk.Prm.WhichMcros[CC .. TrkID] == nil then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            elseif Trk.Prm.WhichMcros[CC .. TrkID] ~= nil then
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, LT_FXNum, "param." .. P_Num .. ".plink.active", 0) -- 1 active, 0 inactive
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FX[FxGUID][Fx_P].V)
            end
        end


        if AssigningMacro ~= nil then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosR, PosB, EightColors.bgWhenAsgnMod[AssigningMacro])
        end

        local AlreadyAddPrm = false

        Highlight_Prm_If_User_Use_Actual_UI_To_Tweak(draw_list, PosL, PosT, PosR, PosB,FP,FxGUID)
        
        


        -- if IsLBtnHeld ==false then Tweaking= nil end

        if PM.TimeNow ~= nil then
            if r.time_precise() > PM.TimeNow + 1 then
                r.gmem_write(7, 0) --tells jsfx to stop retrieving P value
                r.gmem_write(8, 0)
                PM.TimeNow = nil
            end
        end

        if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl and FX[FxGUID].MorphA and FX[FxGUID].MorphB then
            --im.EndDisabled(ctx)
            if FX[FxGUID].MorphA[P_Num] and FX[FxGUID].MorphB[P_Num] then
                HintMessage = 'LMB : adjust A   RMB : adjust B    Alt + Ctrl : Quick Access to morph value edit mode'

                local sizeX, sizeY = im.GetItemRectSize(ctx)
                local A = SetMinMax(PosL + sizeX * FX[FxGUID].MorphA[P_Num], PosL, PosR)
                local B = SetMinMax(PosL + sizeX * FX[FxGUID].MorphB[P_Num], PosL, PosR)
                local ClrA, ClrB = Morph_A or CustomColorsDefault.Morph_A ,  Morph_B or CustomColorsDefault.Morph_B
                local MsX, MsY = im.GetMousePos(ctx)

                if FX[FxGUID].MorphA[P_Num] ~= FX[FxGUID].MorphB[P_Num] then
                    im.DrawList_AddRectFilledMultiColor(WDL, A, PosT, B, PosB, ClrA, ClrB, ClrB, ClrA)
                end

                local txtClr = im.GetStyleColor(ctx, im.Col_Text)

                if im.IsMouseHoveringRect(ctx, PosL, PosT, PosR, PosB) and not MorphingMenuOpen then
                    if IsLBtnClicked or IsRBtnClicked then
                        FP.TweakingAB_Val = P_Num
                        retval, Orig_Baseline = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline")
                    end
                    if not FP.TweakingAB_Val then
                        local offsetA, offsetB
                        if A < B + 5 and A > B - 14 then
                            offsetA = -10
                            offsetB = 10
                        end
                        im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, A, PosT + (offsetA or 0), txtClr, 'A')
                        im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, B, PosT + (offsetB or 0), txtClr, 'B')
                    end
                end

                if FP.TweakingAB_Val == P_Num and not MorphingMenuOpen then
                    local X_A, X_B
                    local offsetA, offsetB
                    if IsLBtnHeld then
                        FX[FxGUID].MorphA[P_Num] = SetMinMax((MsX - PosL) / sizeX, 0, 1)
                        if FX[FxGUID].Morph_ID then -- if Morph Sldr is linked to a CC
                            local A = (MsX - PosL) / sizeX
                            local Scale = FX[FxGUID].MorphB[P_Num] - A
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 1)     -- 1 active, 0 inactive
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.scale", Scale)  -- Scale
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -100)  -- -100 enables midi_msg*
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.param", -1)     -- -1 not parameter link
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 15)  -- 0 based, 15 = Bus 16
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 16) -- 0 based, 0 = Omni
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg", 160) -- 160 is Aftertouch
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2",
                                FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline", A)     -- Baseline
                        end
                    elseif IsRBtnHeld then
                        FX[FxGUID].MorphB[P_Num] = SetMinMax((MsX - PosL) / sizeX, 0, 1)
                        if FX[FxGUID].Morph_ID then                                                                     -- if Morph Sldr is linked to a CC
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 1)     -- 1 active, 0 inactive
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.scale",
                                FX[FxGUID].MorphB[P_Num] - FX[FxGUID].MorphA[P_Num])                                    -- Scale
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -100)  -- -100 enables midi_msg*
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.param", -1)     -- -1 not parameter link
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 15)  -- 0 based, 15 = Bus 16
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 16) -- 0 based, 0 = Omni
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg", 160) -- 160 is Aftertouch
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2",
                                FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline",
                                Orig_Baseline)                                                                          -- Baseline
                        end
                    end
                    if IsLBtnHeld then
                        X_A = MsX
                        Y_A = MsY - 15
                        offsetA = -10
                        if MsX < B + 5 and MsX > B - 14 then offsetB = 10 end
                    elseif IsRBtnHeld then
                        X_B = MsX
                        offsetB = -10
                        if MsX < A + 5 and MsX > A - 14 then offsetA = 10 end
                    end

                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, A, PosT + (offsetA or 0), txtClr, 'A')
                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, B, PosT + (offsetB or 0), txtClr, 'B')
                end
            end
            if LBtnRel or RBtnRel then
                StoreAllPrmVal('A', 'Dont')
                StoreAllPrmVal('B', 'Dont')
                FP.TweakingAB_Val = nil
            end
            --im.BeginDisabled(ctx)
        end

        IfTryingToAddExistingPrm(Fx_P, FxGUID, 'Rect', PosL, PosT, PosR, PosB)


        Tweaking = MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, Vertical)





        local TextW, h = im.CalcTextSize(ctx, labeltoShow, nil, nil, true)
        local V_Clr, LblClr
        if Disable == 'Disabled' then
            LblClr = 0x111111ff; V_Clr = 0x111111ff
        else
            LblClr = FP.Lbl_Clr or 0xD6D6D6ff; V_Clr = FP.V_Clr or 0xD6D6D6ff
        end

        local _, Format_P_V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
        im.PushFont(ctx, Arial_11)
        TextW, Texth = im.CalcTextSize(ctx, Format_P_V, nil, nil, true, -100)

        im.PopFont(ctx)

        if FX[FxGUID][Fx_P].V_Round then Format_P_V = RoundPrmV(StrToNum(Format_P_V), FX[FxGUID][Fx_P].V_Round) end

        local function Bottom_Label_or_Value()
            local Cx, Cy = im.GetCursorScreenPos(ctx)
            if Vertical ~= 'Vert' then
                
                if not FP.Lbl_Pos or FP.Lbl_Pos == 'Bottom' then
                    im.DrawList_AddTextEx(draw_list, _G[Font],FP.FontSize or LblTextSize or Knob_DefaultFontSize,Cx + (FP.Lbl_Pos_X or 0), Cy + (FP.Lbl_Pos_Y or 0), LblClr, labeltoShow or FX[FxGUID][Fx_P].Name, nil, PosL, PosT, SldrR - TextW - 3,PosB + 20)
                end
            else -- if vertical
                if FP.Lbl_Pos == 'Bottom' or not FP.Lbl_Pos then

                    Align_Text_To_Center_Of_X(labeltoShow or FP.Name, Sldr_Width, FP.Lbl_Pos_X, FP.Lbl_Pos_Y)
                    MyText(labeltoShow or FP.Name, _G[Font], FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
                end
                if FP.V_Pos == 'Bottom' then
                    Align_Text_To_Center_Of_X(Format_P_V, Sldr_Width, FP.V_Pos_X, FP.V_Pos_Y)
                    --[[ 
                    local Cx = im.GetCursorPosX(ctx)
                    local txtW = im.CalcTextSize(ctx, Format_P_V, nil, nil, true)
                    im.SetCursorPosX(ctx, Cx + Sldr_Width / 2 - txtW / 2) ]]
                    MyText(Format_P_V, _G[V_Font], FP.V_Clr or im.GetColor(ctx, im.Col_Text))
                end
            end
            if BtmLbl ~= 'No BtmLbl' then
                if FP.Lbl_Pos == 'Free' then
                    im.DrawList_AddTextEx(draw_list, _G[Font], FP.FontSize or LblTextSize or Knob_DefaultFontSize,
                        Cx + (FP.Lbl_Pos_X or 0), Cy + (FP.Lbl_Pos_Y or 0), FP.Lbl_Clr or LblClr,
                        labeltoShow or FX[FxGUID][Fx_P].Name)
                end
            end
    
            if FP.V_Pos == 'Free' then
                local Ox, Oy = im.GetCursorScreenPos(ctx)
                im.DrawList_AddTextEx(draw_list, _G[V_Font], FP.V_FontSize or Knob_DefaultFontSize,
                    Ox + Sldr_Width - TextW + (FP.V_Pos_X or 0), Oy + (FP.V_Pos_Y or 0), V_Clr,
                    Format_P_V)
            end
    
            if Vertical ~= 'Vert' and (not FP.V_Pos or FP.V_Pos == 'Right') then
                im.PushFont(ctx, Arial_11); local X, Y = im.GetCursorScreenPos(ctx)
                im.SetCursorScreenPos(ctx, SldrR - TextW, Y)
                MyText(Format_P_V, _G[V_Font], V_Clr)
    
                im.PopFont(ctx)
            end
    
        end

        Bottom_Label_or_Value()
        



        if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl or LBtnDC then im.EndDisabled(ctx) end


        im.EndGroup(ctx)
        if item_inner_spacing then im.PopStyleVar(ctx) end


        if SpacingBelow then
            for i = 1, SpacingBelow, 1 do im.Spacing(ctx) end
        else
            im.Spacing(ctx); im.Spacing(ctx); im.Spacing(ctx); im.Spacing(ctx); im.Spacing(ctx)
        end
    end

    if LBtnDC then im.PopStyleVar(ctx) end
    im.PopStyleVar(ctx)


    return value_changed, p_value
end

---@param ctx ImGui_Context
---@param LT_Track MediaTrack
---@param FX_Idx integer
---@param Label string
---@param WhichPrm integer
---@param Options? "Get Options"|string[]
---@param Width number
---@param Style Style
---@param FxGUID string
---@param Fx_P integer
---@param OptionValues? number[]
---@param LabelOveride? string|nil
---@param CustomLbl? string
---@param Lbl_Pos? Position
function AddCombo(ctx, LT_Track, FX_Idx, Label, WhichPrm, Options, Width, Style, FxGUID, Fx_P, OptionValues,
                  LabelOveride, CustomLbl, Lbl_Pos)
    LabelValue = Label .. 'Value'
    local FP
    FX[FxGUID or ''][Fx_P or ''] = FX[FxGUID or ''][Fx_P or ''] or {}
    im.BeginGroup(ctx)
    if Fx_P then FP = FX[FxGUID][Fx_P] end
    local V_Font = 'Font_Andale_Mono_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    local Font = 'Font_Andale_Mono_' .. roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)

    if Fx_P and FP then
        if (FP.Lbl_Pos == 'Left' and Lbl_Pos ~= 'No Lbl') or FP.Lbl_Pos == 'Top' then
            local name
            if not LabelOveride and not FP.CustomLbl and not CustomLbl then
                _, name = r.TrackFX_GetParamName(
                    LT_Track, FX_Idx, WhichPrm)
            end
            im.AlignTextToFramePadding(ctx)
            MyText(LabelOveride or FP.CustomLbl or CustomLbl or FP.Name, _G[Font],
                FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
            if FP.Lbl_Pos == 'Left' and Lbl_Pos ~= 'No Lbl' then
                SL()
            end
        end
        im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)
    end

    if LabelOveride then _G[LabelValue] = LabelOveride end

    local PopClr
    local MaxTextLength
    if Style == 'Pro C 2' then
        im.PushStyleColor(ctx, im.Col_FrameBg, 0x444444ff)
        im.PushStyleColor(ctx, im.Col_Text, 0xffffffff)
        PopClr = 2
        if _G[LabelValue] == 'Mastering' then _G[LabelValue] = 'Master' end
    else
        im.PushStyleColor(ctx, im.Col_FrameBg, FX[FxGUID][Fx_P].BgClr or 0x444444ff)
        im.PushStyleColor(ctx, im.Col_Text, FX[FxGUID][Fx_P].V_Clr or 0xffffffff)
        PopClr = 2
    end
    local OP = FX.Prm.Options; local OPs, V

    if Options == 'Get Options' then
        if not OP[FxGUID] then OP[FxGUID] = {} end
        if not OP[FxGUID][Fx_P] then
            OP[FxGUID][Fx_P] = {};

            OP[FxGUID][Fx_P] = { V = {} }
        end
        OPs = OP[FxGUID][Fx_P]
        V = OP[FxGUID][Fx_P].V


        if #OPs == 0 then
            local OrigPrmV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, WhichPrm)
            for i = 0, 1.01, 0.01 do
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, i)
                local _, buf = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, WhichPrm)

                if not Value then
                    Value = buf; OPs[1] = buf
                    V[1] = i
                end
                if Value ~= buf then
                    table.insert(OPs, buf)
                    table.insert(V, i)
                    local L1 = im.CalcTextSize(ctx, buf); local L2 = im.CalcTextSize(ctx, Value)
                    FX[FxGUID][Fx_P].Combo_W = math.max(L1, L2)
                    Value = buf
                end
            end
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, OrigPrmV)
        end
    end




    local ExtraW
    if Style == 'up-down arrow' then ExtraW = 20 end


    if FX[FxGUID][Fx_P].ManualValues then
        local Vn = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, WhichPrm)

        for i, V in ipairs(FP.ManualValues) do
            if Vn == V then _G[LabelValue] = FP.ManualValuesFormat[i] end
        end
    else
        _, _G[LabelValue] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, WhichPrm)
    end
    --_,_G[LabelValue]  = r.TrackFX_GetFormattedParamValue(LT_Track,FX_Idx, WhichPrm)
    local Cx, Cy
    if FP.V_Pos == 'Free' then
        Cx, Cy = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, Cx + (FP.V_Pos_X or 0), Cy + (FP.V_Pos_Y or 0))
    end

    ---@param ctx ImGui_Context
    ---@return boolean
    ---@return string
    local function begincombo(ctx)
        if FP.V_FontSize then im.PushFont(ctx, _G[V_Font]) end
        if Width or FX[FxGUID][Fx_P].Combo_W then
            im.SetNextItemWidth(ctx, Width or (FX[FxGUID][Fx_P].Combo_W + (ExtraW or 0)))
        end
        if im.BeginCombo(ctx, '## ' .. tostring(Label), LabelOveride or _G[LabelValue], im.ComboFlags_NoArrowButton) then
            -----Style--------

            im.PushStyleColor(ctx, im.Col_Header, 0x44444433)
            local AccentClr = im.GetColor(ctx, im.Col_SliderGrabActive)
            im.PushStyleColor(ctx, im.Col_HeaderHovered, AccentClr)
            im.PushStyleColor(ctx, im.Col_Text, 0xbbbbbbff)
            if Style == 'Pro C 2' then
                ProC.ChoosingStyle = true
            end
            local Options = Options
            if FX[FxGUID][Fx_P].ManualValues then Options = FP.ManualValuesFormat end



            if Options ~= 'Get Options' then
                local rv

                for i = 1, #Options, 1 do
                    if im.Selectable(ctx, Options[i], i) and WhichPrm ~= nil then
                        if OptionValues then
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, OptionValues[i])
                        else
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm,
                                (i - 1) / #Options + ((i - 1) / #Options) * 0.1) -- + options* 0.05 so the value will be slightly higher than threshold,
                        end
                        if FX[FxGUID][Fx_P].ManualValues then
                            if FX[FxGUID][Fx_P].ManualValues[i] then
                                _G[LabelValue] = FP.ManualValuesFormat[i]
                            end
                        else
                            _, _G[LabelValue] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, WhichPrm)
                        end
                        im.PopStyleColor(ctx, 3)
                        im.EndCombo(ctx)
                        return true, _G[LabelValue]
                    end
                end
                im.PopStyleColor(ctx, 3)
                im.EndCombo(ctx)
            else
                for i = 1, #OPs, 1 do
                    if OPs[i] and OPs[i]~='' then 
                        if im.Selectable(ctx, OPs[i], i) and WhichPrm ~= nil then
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, V[i])
                            _, _G[LabelValue] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, WhichPrm)
                            im.PopStyleColor(ctx, 3)
                            im.EndCombo(ctx)
                            return true, _G[LabelValue]
                        end
                    end
                end
                im.PopStyleColor(ctx, 3)
                im.EndCombo(ctx)
            end

            local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx)
            local lineheight = im.GetTextLineHeight(ctx)
            local drawlist = im.GetForegroundDrawList(ctx)

            im.DrawList_AddRectFilled(drawlist, L, T + lineheight / 8, R, B - lineheight / 8, 0x88888844,
                Rounding)
            im.DrawList_AddRect(drawlist, L, T + lineheight / 8, R, B - lineheight / 8, 0x88888877, Rounding)
        else
            if Style == 'Pro C 2' and LBtnRel then
                ProC.ChoosingStyle = false
            end
        end
        -- DnD_PLink_TARGET(FxGUID, Fx_P, FX_Idx, P_Num)
        if FP.V_FontSize then im.PopFont(ctx) end
    end

    local rv, v_format = begincombo(ctx)

    if Style == 'up-down arrow' then
        local R, B = im.GetItemRectMax(ctx)
        local lineheight = im.GetTextLineHeight(ctx)
        local drawlist = im.GetWindowDrawList(ctx)
        local m = B - lineheight / 2 - 3
        g = 2
        local X = R - ExtraW / 2
        DrawTriangle(drawlist, X, m - g, 3, clr)
        DrawDownwardTriangle(drawlist, X, m + g, 3, clr)
    end



    if FP.Lbl_Pos == 'Right' then
        SL()
        im.AlignTextToFramePadding(ctx) --[[ im.Text(ctx,FP.CustomLbl or FP.Name)  ]]
        MyText(LabelOveride or FP.CustomLbl or CustomLbl or FP.Name, _G[Font],
            FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
    elseif FP.Lbl_Pos == 'Bottom' then
        MyText(LabelOveride or FP.CustomLbl or CustomLbl or FP.Name, _G[Font],
            FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
    end
    im.PopStyleVar(ctx)
    im.EndGroup(ctx)
    im.PopStyleColor(ctx, PopClr or 0)
    if rv then return rv, v_format end
end

---@param LT_Track MediaTrack
---@param FX_Idx integer
---@param Value any
---@param P_Num number
---@param BgClr number
---@param Lbl_Type? "Use Prm Name as Lbl"
---@param Fx_P string|integer
---@param F_Tp string|integer ---TODO unused
---@param FontSize number
---@param FxGUID string
---@return integer
function AddSwitch(LT_Track, FX_Idx, Value, P_Num, BgClr, Lbl_Type, Fx_P, F_Tp, FontSize, FxGUID)
    local clr, TextW, Font
    FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
    local FP = FX[FxGUID][Fx_P]
    local V_Font = 'Font_Andale_Mono_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)

    if FontSize then
        Font = 'Font_Andale_Mono_' .. roundUp(FontSize, 1); im.PushFont(ctx, _G[Font])
    end
    if FX[FxGUID][Fx_P].Lbl_Clr then im.PushStyleColor(ctx, im.Col_Text, FX[FxGUID][Fx_P].Lbl_Clr) end
    local popClr

    im.BeginGroup(ctx)
    if FP.Lbl_Pos == 'Left' then
        im.AlignTextToFramePadding(ctx)
        im.Text(ctx, FP.CustomLbl or FP.Name)
        SL()
    elseif FP.Lbl_Pos == 'Top' then
        im.Text(ctx, FP.CustomLbl or FP.Name)
    end

    if FP.V_Pos == 'None' or FP.V_Pos == 'Free' then
        lbl = '  '
    elseif FP.V_Pos == 'Within' then
        im.PushFont(ctx, _G[V_Font])
        _, lbl = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
        TextW = im.CalcTextSize(ctx, lbl)
    elseif Lbl_Type == 'Use Prm Name as Lbl' then
        lbl = FX[FxGUID][Fx_P].Name
        TextW = im.CalcTextSize(ctx, lbl)
    elseif Lbl_Type and Lbl_Type ~= 'Use Prm Name as Lbl' then
        lbl = Lbl_Type
        TextW = im.CalcTextSize(ctx, Lbl_Type)
        FX[FxGUID][Fx_P].Switch_W = TextW
    else --Use Value As Label
        _, lbl = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
    end

    if FP.Lbl_Pos == 'Within' then lbl = FP.CustomLbl or FP.Name end




    if FX[FxGUID][Fx_P].V == nil then FX[FxGUID][Fx_P].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end


    if FX[FxGUID][Fx_P].Switch_On_Clr then
        if FX[FxGUID][Fx_P].V == 1 then
            popClr = 2
            im.PushStyleColor(ctx, im.Col_Button, FX[FxGUID][Fx_P].Switch_On_Clr)
            im.PushStyleColor(ctx, im.Col_ButtonHovered,
                Change_Clr_A(FX[FxGUID][Fx_P].Switch_On_Clr, -0.2))
        else
            popClr = 2
            im.PushStyleColor(ctx, im.Col_Button, BgClr or 0x00000000)
            im.PushStyleColor(ctx, im.Col_ButtonHovered, Change_Clr_A((BgClr or 0xffffff00), -0.2))
        end
    else
        if BgClr then
            popClr = 2
            im.PushStyleColor(ctx, im.Col_Button, BgClr or 0xffffff00)
            im.PushStyleColor(ctx, im.Col_ButtonHovered, Change_Clr_A((BgClr or 0xffffff00), -0.2))
        end
    end


    if FP.V_Clr then im.PushStyleColor(ctx, im.Col_Text, FP.V_Clr) end




    if not FP.Image then
        im.Button(ctx, lbl .. '##' .. FxGUID .. Fx_P, FX[FxGUID][Fx_P].Sldr_W or TextW)
    else -- if there's an image
        uvmin, uvmax, w, h = Calc_strip_uv(FP.Image, FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num))

        im.InvisibleButton(ctx, lbl .. '##' .. FxGUID .. Fx_P, FP.Sldr_W or 30, FP.Sldr_W or 30)
        local l, t = im.GetItemRectMin(ctx)
        local r, b = im.GetItemRectMax(ctx)
        local clr = FP.BgClr
        if FX[FxGUID][Fx_P].V == 1 then
            clr = FP.Switch_On_Clr
        end
        im.DrawList_AddImage(WDL, FP.Image, l, t , r,b, 0, uvmin, 1, uvmax, clr)
        --[[ im.ImageButton(ctx, lbl .. '##' .. FxGUID .. Fx_P, FP.Image, FP.Sldr_W or 30, FP.Sldr_W or 30, 0,
            uvmin, 1, uvmax, FP.BgClr or 0xffffff00) ]]

    end


    if im.IsItemClicked(ctx, 0) then
        if FP.SwitchType == 'Momentary' then
            FX[FxGUID][Fx_P].V = FX[FxGUID][Fx_P].SwitchTargV
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FX[FxGUID][Fx_P].SwitchTargV or 0)
            if im.IsItemDeactivated(ctx) then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FX[FxGUID][Fx_P].SwitchBaseV or 1)
            end
        else -- if it's a toggle
            local Value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
            if Value == 0 then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 1)
                FX[FxGUID][Fx_P].V = 1
            elseif Value == 1 then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0)
                FX[FxGUID][Fx_P].V = 0
            end
        end
    end






    if FP.V_Clr then im.PopStyleColor(ctx) end
    --Sync Value if user tweak plugin's actual GUI.

    if focusedFXState == 1 and LT_FXGUID == FxGUID and LT_ParamNum == P_Num and not FX[FxGUID][Fx_P].WhichCC then
        FX[FxGUID][Fx_P].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    end

    if FX[FxGUID][Fx_P].SwitchType == 'Momentary' then
        clr = 0x00000000
    else
        if FX[FxGUID][Fx_P].V == 0 then clr = 0x00000022 else clr = 0xffffff22 end
    end
    local X, Y = im.GetItemRectMin(ctx); local W, H = im.GetItemRectSize(ctx)
    local DL = im.GetWindowDrawList(ctx)

    if FP.Lbl_Pos == 'Right' then
        SL()
        im.AlignTextToFramePadding(ctx)
        im.Text(ctx, FP.CustomLbl or FP.Name)
    elseif FP.Lbl_Pos == 'Bottom' then
        im.Text(ctx, FP.CustomLbl or FP.Name)
    elseif FP.Lbl_Pos == 'Free' then
        local Cx, Cy = im.GetCursorScreenPos(ctx)
        im.DrawList_AddTextEx(DL, _G[Font], FontSize or 11, Cx + (FP.Lbl_Pos_X or 0), Cy + (FP.Lbl_Pos_Y or 0),
            FP.Lbl_Clr or getClr(im.Col_Text), FP.CustomLbl or FP.Name)
    end

    if FP.V_Pos == 'Free' then
        local Cx, Cy = im.GetCursorScreenPos(ctx)
        local _, lbl = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
        im.DrawList_AddTextEx(DL, _G[Font], FontSize or 11, Cx + (FP.V_Pos_X or 0), Cy + (FP.V_Pos_Y or 0),
            FP.Lbl_Clr or getClr(im.Col_Text), lbl)
    end
    if FP.V_Pos == 'Within' then im.PopFont(ctx) end


    im.EndGroup(ctx)

    --im.DrawList_AddRectFilled(DL, X, Y, X + W, Y + H, clr, FX.Round[FxGUID] or 0)
    im.PopStyleVar(ctx)
    if FontSize then im.PopFont(ctx) end
    if popClr then im.PopStyleColor(ctx, popClr) end
    if FX[FxGUID][Fx_P].Lbl_Clr then im.PopStyleColor(ctx) end
    if Value == 0 then return 0 else return 1 end
end


---TODO style param is not quite there yet
---some of the missing options might be:
---    | "Pro C 2"
---    | "Pro C Thresh"
---    | "Custom Image"
---    | "Invisible"
---    | "FX Layering"
---    | 'up-down arrow'
---@param ctx ImGui_Context
---@param label string
---@param labeltoShow string
---@param p_value number
---@param v_min number
---@param v_max number
---@param Fx_P any
---@param FX_Idx integer
---@param P_Num number
---@param Style "FX Layering"|"Pro C"|"Pro C Lookahead"|string
---@param Sldr_Width number
---@param item_inner_spacing number
---@param Disable? "Disabled"
---@param Lbl_Clickable? "Lbl_Clickable"
---@param Lbl_Pos Position
---@param V_Pos Position
---@param DragDir "Left"|"Right"|"Left-Right"
---@param AllowInput? "NoInput"
function AddDrag(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, Style, Sldr_Width,
                 item_inner_spacing, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, DragDir, AllowInput)
    local FxGUID = FxGUID or r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    if FxGUID then
        FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}

        --local FxGUID = FXGUID[FX_Idx]
        local FP = FX[FxGUID][Fx_P]
        im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)
        

        if FX[FxGUID].Morph_Value_Edit or (Mods == Alt + Ctrl and is_hovered) then im.BeginDisabled(ctx) end
        local radius_outer = 20.0

        local pos = { im.GetCursorScreenPos(ctx) }

        local line_height = im.GetTextLineHeight(ctx); local draw_list = im.GetWindowDrawList(ctx)

        local f_draw_list = im.GetForegroundDrawList(ctx)


        local mouse_delta = { im.GetMouseDelta(ctx) }
        local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]


        local Font = 'Font_Andale_Mono_' .. roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)


        local V_Font = 'Arial_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)

        if type(FP) ~= 'table' then
            FX[FxGUID][Fx_P] = {}
            FP = FX[FxGUID][Fx_P]
        end

        if item_inner_spacing then
            im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, item_inner_spacing, item_inner_spacing)
        end

        im.BeginGroup(ctx)
        local BgClr
        if SliderStyle == 'Pro C' or SliderStyle == 'Pro C Lookahead' then BgClr = 0x55555544 end
        im.PushStyleColor(ctx, im.Col_FrameBg, BgClr or FP.BgClr or im.GetColor(ctx, im.Col_FrameBg))
        im.PushStyleColor(ctx, im.Col_FrameBgActive, FP.BgClrAct or im.GetColor(ctx, im.Col_FrameBgActive))
        im.PushStyleColor(ctx, im.Col_FrameBgHovered, FP.BgClrHvr or im.GetColor(ctx, im.Col_FrameBgHovered))

        if Lbl_Pos == 'Left' then
            im.AlignTextToFramePadding(ctx)
            MyText(labeltoShow, _G[Font], FP.Lbl_Clr or 0xaaaaaaff)
            im.SameLine(ctx, nil, 8)
            im.AlignTextToFramePadding(ctx)
        elseif Lbl_Pos == 'Free' then
            im.DrawList_AddTextEx(WDL, _G[Font], FP.FontSize or Knob_DefaultFontSize, pos[1] + (FP.Lbl_Pos_X or 0),
                pos[2] + (FP.Lbl_Pos_Y or 0), FP.Lbl_Clr or 0xffffffff, labeltoShow)
        end
        im.SetNextItemWidth(ctx, Sldr_Width)

        local DragSpeed = 0.01
        if Mods == Shift then DragSpeed = 0.0003 end
        if DraggingMorph == FxGUID then p_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end


        local flag
        if AllowInput == 'NoInput' then flag = im.SliderFlags_NoInput end
        if Style == 'FX Layering' then im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 0) end

        _, p_value = im.DragDouble(ctx, label, p_value, DragSpeed, v_min, v_max, ' ', im.SliderFlags_NoInput)
        im.SetNextItemAllowOverlap( ctx)
        KNOB = false
        DnD_PLink_TARGET(FxGUID, Fx_P, FX_Idx, P_Num)
        ButtonDraw(FX[FxGUID].BgClr or CustomColorsDefault.FX_Devices_Bg, nil, nil)
        local focused_window, hwnd = GetFocusedWindow()
        if focused_window == "FX Devices" then
            r.JS_Window_SetFocus(hwnd)
            AdjustParamWheel(LT_Track, FX_Idx, P_Num)
        end
        if Style == 'FX Layering' then im.PopStyleVar(ctx) end

        im.PopStyleColor(ctx, 3)
        local PosL, PosT = im.GetItemRectMin(ctx); local PosR, PosB = im.GetItemRectMax(ctx)

        local value_changed = false
        local is_active = im.IsItemActive(ctx)
        local is_hovered = im.IsItemHovered(ctx)

        --[[ if is_active == true then Knob_Active = true end
        if Knob_Active == true then
            if IsLBtnHeld == false then Knob_Active = false end
        end ]]
        SldrLength = PosR - PosL

        SldrGrbPos = SldrLength * (p_value or 1)

        RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)
        ---Edit preset morph values

        if FX[FxGUID].Morph_Value_Edit or (Mods == Alt + Ctrl and is_hovered) then
            if FX[FxGUID].MorphA[P_Num] and FX[FxGUID].MorphB[P_Num] then
                local sizeX, sizeY = im.GetItemRectSize(ctx)
                local A = SetMinMax(PosL + sizeX * FX[FxGUID].MorphA[P_Num], PosL, PosR)
                local B = SetMinMax(PosL + sizeX * FX[FxGUID].MorphB[P_Num], PosL, PosR)
                local ClrA, ClrB = Morph_A or CustomColorsDefault.Morph_A,  Morph_B or CustomColorsDefault.Morph_B
                local MsX, MsY = im.GetMousePos(ctx)

                if FX[FxGUID].MorphA[P_Num] ~= FX[FxGUID].MorphB[P_Num] then
                    im.DrawList_AddRectFilledMultiColor(WDL, A, PosT, B, PosB, ClrA, ClrB, ClrB, ClrA)
                end

                local txtClr = im.GetStyleColor(ctx, im.Col_Text)

                if im.IsMouseHoveringRect(ctx, PosL, PosT, PosR, PosB) and not MorphingMenuOpen then
                    if IsLBtnClicked or IsRBtnClicked then
                        FP.TweakingAB_Val = P_Num
                        retval, Orig_Baseline = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                            "param." .. P_Num .. ".mod.baseline")
                    end
                    if not FP.TweakingAB_Val then
                        local offsetA, offsetB
                        if A < B + 5 and A > B - 14 then
                            offsetA = -10
                            offsetB = 10
                        end
                        im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, A, PosT + (offsetA or 0), txtClr, 'A')
                        im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, B, PosT + (offsetB or 0), txtClr, 'B')
                    end
                end

                if FP.TweakingAB_Val == P_Num and not MorphingMenuOpen then
                    local X_A, X_B
                    local offsetA, offsetB
                    if IsLBtnHeld then
                        FX[FxGUID].MorphA[P_Num] = SetMinMax((MsX - PosL) / sizeX, 0, 1)
                        if FX[FxGUID].Morph_ID then -- if Morph Sldr is linked to a CC
                            local A = (MsX - PosL) / sizeX
                            local Scale = FX[FxGUID].MorphB[P_Num] - A
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 1)     -- 1 active, 0 inactive
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.scale", Scale)  -- Scale
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -100)  -- -100 enables midi_msg*
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.param", -1)     -- -1 not parameter link
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 15)  -- 0 based, 15 = Bus 16
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 16) -- 0 based, 0 = Omni
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg", 160) -- 160 is Aftertouch
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2",
                                FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline", A)     -- Baseline
                        end
                    elseif IsRBtnHeld then
                        FX[FxGUID].MorphB[P_Num] = SetMinMax((MsX - PosL) / sizeX, 0, 1)
                        if FX[FxGUID].Morph_ID then                                                                     -- if Morph Sldr is linked to a CC
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 1)     -- 1 active, 0 inactive
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.scale",
                                FX[FxGUID].MorphB[P_Num] - FX[FxGUID].MorphA[P_Num])                                    -- Scale
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.effect", -100)  -- -100 enables midi_msg*
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.param", -1)     -- -1 not parameter link
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 15)  -- 0 based, 15 = Bus 16
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_chan", 16) -- 0 based, 0 = Omni
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg", 160) -- 160 is Aftertouch
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2",
                                FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline",
                                Orig_Baseline)                                                                          -- Baseline
                        end
                    end
                    if IsLBtnHeld then
                        X_A = MsX
                        Y_A = MsY - 15
                        offsetA = -10
                        if MsX < B + 5 and MsX > B - 14 then offsetB = 10 end
                    elseif IsRBtnHeld then
                        X_B = MsX
                        offsetB = -10
                        if MsX < A + 5 and MsX > A - 14 then offsetA = 10 end
                    end

                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, A, PosT + (offsetA or 0), txtClr, 'A')
                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 16, B, PosT + (offsetB or 0), txtClr, 'B')
                end
            end
            if LBtnRel or RBtnRel then
                StoreAllPrmVal('A', 'Dont')
                StoreAllPrmVal('B', 'Dont')
                FP.TweakingAB_Val = nil
            end
        end

        if FP.GrbClr and FX.LayEdit == FxGUID then
            local ActV
            local R, G, B, A = im.ColorConvertU32ToDouble4(FP.GrbClr)
            local H, S, V = im.ColorConvertRGBtoHSV(R, G, B) ---TODO I think this function only returns 3 values, not 5
            if V > 0.9 then ActV = V - 0.2 end
            local  R, G, B = im.ColorConvertHSVtoRGB(H, S, ActV or V + 0.2)
            local ActClr = im.ColorConvertDouble4ToU32(R, G, B, A)
            local R, G, B = im.ColorConvertHSVtoRGB(H, S, HvrV or V + 0.1)
            local HvrClr = im.ColorConvertDouble4ToU32(R, G, B, A)
            FP.GrbAct = ActClr
            FP.GrbHvr = HvrClr
        end

        if Style == 'FX Layering' then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosR, PosB, 0x99999910)
        end

        if not SliderStyle then
            if DragDir == 'Right' or DragDir == nil then
                if is_active then
                    im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB,
                        FP.GrbAct or 0xffffff77, Rounding)
                elseif is_hovered then
                    im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB,
                        FP.GrbHvr or 0xffffff55, Rounding)
                else
                    im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB,
                        FP.GrbClr or 0xffffff44, Rounding)
                end
            elseif DragDir == 'Left-Right' then
                local L = math.min(PosL + (PosR - PosL) / 2, PosL + SldrGrbPos); local R = math.max(
                    PosL + (PosR - PosL) / 2,
                    PosL + SldrGrbPos)
                if is_active then
                    im.DrawList_AddRectFilled(draw_list, L, PosT, R, PosB, FP.GrbAct or 0xffffff77, Rounding)
                elseif is_hovered then
                    im.DrawList_AddRectFilled(draw_list, L, PosT, R, PosB, FP.GrbHvr or 0xffffff55, Rounding)
                else
                    im.DrawList_AddRectFilled(draw_list, L, PosT, R, PosB, FP.GrbClr or 0xffffff44, Rounding)
                end
            elseif DragDir == 'Left' then
                if is_active then
                    im.DrawList_AddRectFilled(draw_list, PosR, PosT, PosL + SldrGrbPos, PosB,
                        FP.GrbAct or 0xffffff77,
                        Rounding)
                elseif is_hovered then
                    im.DrawList_AddRectFilled(draw_list, PosR, PosT, PosL + SldrGrbPos, PosB,
                        FP.GrbHvr or 0xffffff55,
                        Rounding)
                else
                    im.DrawList_AddRectFilled(draw_list, PosR, PosT, PosL + SldrGrbPos, PosB,
                        FP.GrbClr or 0xffffff44,
                        Rounding)
                end
            end
        elseif SliderStyle == 'Pro C' or SliderStyle == 'Pro C Lookahead' then
            if is_active then
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xFFD571bb, Rounding)
            elseif is_hovered then
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xDFB973bb, Rounding)
            else
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, math.max(PosL + SldrGrbPos, PosL), PosB, 0x888888bb,
                    Rounding)
            end
        end


        if Disable == 'Disabled' then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0x222222bb, Rounding)
        end

        local button_x, button_y = im.GetCursorPos(ctx)
        im.SetCursorPosY(ctx, button_y - (PosB - PosT))
        --[[ WhichClick()
        im.InvisibleButton(ctx, '##plink' .. P_Num, PosR - PosL, PosB - PosT, ClickButton) -- for parameter link
        if ClickButton == im.ButtonFlags_MouseButtonRight and not AssigningMacro then    -- right drag to link parameters
            DnD_PLink_SOURCE(FX_Idx, P_Num)
        end ]]

        if is_active then
            if p_value < v_min then p_value = v_min end
            if p_value > v_max then p_value = v_max end
            value_changed = true
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            MvingP_Idx = F_Tp

            Tweaking = P_Num .. FxGUID
        end

        local t            = (p_value - v_min) / (v_max - v_min)

        local radius_inner = radius_outer * 0.40
        local Clr_SldrGrab = im.GetColor(ctx, im.Col_SliderGrabActive)
        local ClrBg        = im.GetColor(ctx, im.Col_FrameBg)


        if (is_active or is_hovered) and (FX[FxGUID][Fx_P].V_Pos == 'None' or Style == 'Pro C' or Style == 'Pro C Lookahead') then
            local getSldr, Param_Value = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)

            local window_padding       = { im.GetStyleVar(ctx, im.StyleVar_WindowPadding) }
            im.SetNextWindowPos(ctx, pos[1] - window_padding[1], pos[2] - line_height - window_padding[2] - 8)

            im.BeginTooltip(ctx)
            im.Text(ctx, Param_Value)
            im.EndTooltip(ctx)
        end



        --if user tweak drag on ImGui
        if Tweaking == P_Num .. FxGUID then
            FX[FxGUID][Fx_P].V = p_value
            if not FP.WhichCC then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            else
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, LT_FXNum, "param." .. P_Num .. ".plink.active", 0) -- 1 active, 0 inactive
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FX[FxGUID][Fx_P].V)
            end
        end


        if AssigningMacro ~= nil then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosR, PosB,
                EightColors.bgWhenAsgnMod[AssigningMacro])
        end


        local AlreadyAddPrm = false

        Highlight_Prm_If_User_Use_Actual_UI_To_Tweak(draw_list, PosL, PosT, PosR, PosB, FP,FxGUID)
        --[[ if Tweaking == P_Num..FxGUID and IsLBtnHeld == false then
            if FP.WhichMODs  then
                r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX'..FxGUID..'Prm'..Fx_P.. 'Value before modulation' , FX[FxGUID][Fx_P].V, true    )
                r.gmem_write(7, CC) --tells jsfx to retrieve P value
                PM.TimeNow= r.time_precise()
                r.gmem_write(11000+CC , p_value)
                Link_Param_to_CC(LT_TrackNum, LT_FX_Number, P_Num, true, true, 176,MvingP_Idx) -- Use native API instead

            end

            Tweaking= nil
        end ]]

        if PM.TimeNow ~= nil then
            if r.time_precise() > PM.TimeNow + 1 then
                r.gmem_write(7, 0) --tells jsfx to stop retrieving P value
                r.gmem_write(8, 0)
                PM.TimeNow = nil
            end
        end

        IfTryingToAddExistingPrm(Fx_P, FxGUID, 'Rect', PosL, PosT, PosR, PosB)

        Tweaking = MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width)


        local TextW, h      = im.CalcTextSize(ctx, labeltoShow, nil, nil, true)
        local SldrR, SldrB  = im.GetItemRectMax(ctx)
        local SldrL, SldrT  = im.GetItemRectMin(ctx)
        local W, H          = SldrR - SldrL, SldrB - SldrT
        local _, Format_P_V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
        im.PushFont(ctx, Arial_11)
        if FX[FxGUID][Fx_P].V_Round then Format_P_V = RoundPrmV(Format_P_V, FX[FxGUID][Fx_P].V_Round) end
        TextW, Texth = im.CalcTextSize(ctx, Format_P_V, nil, nil, true, -100)
        if is_active then txtclr = 0xEEEEEEff else txtclr = 0xD6D6D6ff end

        if (V_Pos == 'Within' or Lbl_Pos == 'Left') and V_Pos ~= 'None' and V_Pos ~= 'Free' and V_Pos then
            im.DrawList_AddTextEx(draw_list, _G[V_Font], FP.V_FontSize or Knob_DefaultFontSize,
                SldrL + W / 2 - TextW / 2,
                SldrT + H / 2 - 5, FP.V_Clr or txtclr, Format_P_V)
        elseif FP.V_Pos == 'Free' then
            local X = SldrL + W / 2 - TextW / 2
            local Y = SldrT + H / 2 - 5
            local Ox, Oy = Get
            im.DrawList_AddTextEx(draw_list, _G[V_Font], FP.V_FontSize or Knob_DefaultFontSize,
                X + (FP.V_Pos_X or 0),
                Y + (FP.V_Pos_Y or 0), FP.V_Clr or 0xffffffff, Format_P_V)
        end

        if Lbl_Pos == 'Within-Left' then
            im.DrawList_AddText(draw_list, SldrL, SldrT + H / 2 - 5, FX[FxGUID][Fx_P].Lbl_Clr or txtclr, labeltoShow)
        end
        if V_Pos == 'Within-Right' then
            im.DrawList_AddText(draw_list, SldrR - TextW, SldrT + H / 2 - 5, FX[FxGUID][Fx_P].V_Clr or txtclr,
                Format_P_V)
        end

        im.PopFont(ctx)

        if not Lbl_Pos or Lbl_Pos == 'Bottom' then
            local X, Y = im.GetCursorScreenPos(ctx)
            local TxtClr = FP.Lbl_Clr or getClr(im.Col_Text)
            if Disable == 'Disabled' then TxtClr = getClr(im.Col_TextDisabled) end

            if item_inner_spacing then
                if item_inner_spacing < 0 then im.SetCursorPosY(ctx, im.GetCursorPosY(ctx) + item_inner_spacing) end
            end

            MyText(labeltoShow, _G[Font] or Font_Andale_Mono_12, TxtClr)

            if not string.find(FX.Win_Name_S[FX_Idx] or '', 'Pro%-C 2') then im.SameLine(ctx) end

            im.SetCursorScreenPos(ctx, SldrR - TextW, Y)

            if Style ~= 'Pro C Lookahead' and Style ~= 'Pro C' and (not FX[FxGUID][Fx_P].V_Pos or FX[FxGUID][Fx_P].V_Pos == 'Right') then
                MyText(Format_P_V, _G[V_Font], FP.V_Clr or getClr(im.Col_Text))
            end
        end




        if Lbl_Clickable == 'Lbl_Clickable' then
            local TextL; local TextY; local TxtSize;
            local HvrText = im.IsItemHovered(ctx)
            local ClickText = im.IsItemClicked(ctx)

            if HvrText then
                TextL, TextY = im.GetItemRectMin(ctx); TxtSize = im.CalcTextSize(ctx, labeltoShow)
                im.DrawList_AddRectFilled(draw_list, TextL - 2, TextY, TextL + TxtSize, TextY + 10, 0x99999933)
                im.DrawList_AddRect(draw_list, TextL - 2, TextY, TextL + TxtSize, TextY + 10, 0x99999955)
            end

            if ClickText then
                if Style == 'Pro C Lookahead' then
                    local OnOff;
                    if OnOff == nil then OnOff = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 41) end
                    if OnOff == 1 then
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 41, 0)
                        Lookahead = 1
                    else
                        Lookahead = 0
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 41, 1)
                    end
                end
            end
        end

        im.EndGroup(ctx)
        if item_inner_spacing then im.PopStyleVar(ctx) end
        if FX[FxGUID].Morph_Value_Edit or is_hovered and Mods == Alt + Ctrl then im.EndDisabled(ctx) end

        im.PopStyleVar(ctx)
    end
    return value_changed, p_value
end

---@param FxGUID string
---@param FX_Name string
function CheckIfLayoutEditHasBeenMade(FxGUID, FX_Name)
    if FX[FxGUID].File then
        local ChangeBeenMade
        local PrmCount = r.GetExtState('FX Devices - ' .. FX_Name, 'Param Instance')
        local Ln = FX[FxGUID].FileLine

        if FX[FxGUID].GrbRound ~= (get_aftr_Equal_Num(Ln[4]) or 0) then end
        if FX[FxGUID].Round ~= (get_aftr_Equal_Num(Ln[3]) or 0) then end
        if FX[FxGUID].BgClr ~= get_aftr_Equal_Num(Ln[5]) then end
        if FX[FxGUID].TitleWidth ~= (get_aftr_Equal_Num(Ln[7]) or 0) then end
        if FX[FxGUID].Width ~= (get_aftr_Equal_Num(Ln[6]) or 0) then end

        ChangeBeenMade = true
        --end

        for Fx_P = 1, #FX[FxGUID] or 0, 1 do
            local ID = FxGUID .. Fx_P
            local FP = FX[FxGUID][Fx_P]
            local function L(n)
                return Ln[n + (40 - 14) * (Fx_P - 1)]
            end
            if FP.Name ~= get_aftr_Equal_Num(L(14)) or
                FP.Num ~= get_aftr_Equal_Num(L(15)) or
                FP.Sldr_W ~= get_aftr_Equal_Num(L(16)) or
                FP.Type ~= get_aftr_Equal_(L(17)) or
                FP.PosX ~= get_aftr_Equal_Num(L(18)) or
                FP.PosY ~= get_aftr_Equal_Num(L(19)) or
                FP.Style ~= get_aftr_Equal(L(20)) or
                FP.V_FontSize ~= get_aftr_Equal_Num(L(21)) or
                FP.CustomLbl ~= get_aftr_Equal_Num(L(22)) or
                FP.FontSize ~= get_aftr_Equal_Num(L(23)) or
                FP.Sldr_H ~= '1' or
                FP.BgClr ~= '2' or
                FP.GrbClr ~= '3' or
                FP.Lbl_Pos ~= '4' or
                FP.V_Pos ~= '' or
                FP.Lbl_Clr ~= '4' or
                FP.V_Clr ~= '4' or
                FP.DragDir ~= '4' or
                FP.ConditionPrm ~= '4'

            then
                ChangeBeenMade = true
            end
        end


        if FX[FxGUID].AllPrmHasBeenDeleted then ChangeBeenMade = true end
        return ChangeBeenMade
    end
end

---@param FX_Idx string
function CheckIfDrawingHasBeenMade(FX_Idx)
    local D = Draw[FX.Win_Name_S[FX_Idx]], ChangeBeenMade
    for i, Type in pairs(D.Type) do
        if D.L[i] ~= tonumber(r.GetExtState('FX Devices Drawings', 'prm ' .. i .. 's L pos')) or
            D.R[i] ~= tonumber(r.GetExtState('FX Devices Drawings', 'prm ' .. i .. 's R Pos')) or
            D.T[i] ~= tonumber(r.GetExtState('FX Devices Drawings', 'prm ' .. i .. 's T Pos')) or
            D.B[i] ~= tonumber(r.GetExtState('FX Devices Drawings', 'prm ' .. i .. 's B Pos')) or
            D.Txt[i] ~= tonumber(r.GetExtState('FX Devices Drawings', 'prm ' .. i .. 's Txt')) or
            D.clr[i] ~= tonumber(r.GetExtState('FX Devices Drawings', 'prm ' .. i .. 's Clr')) then
            ChangeBeenMade = true
        end
    end
    return ChangeBeenMade
end

---@param Sel_Track_FX_Count integer
function RetrieveFXsSavedLayout(Sel_Track_FX_Count)

    if LT_Track then
        TREE = BuildFXTree(LT_Track or tr)

        for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
            local PrmInst, Line, FX_Name
            local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            
            --local file = CallFile('r', FX_Name..'.ini', 'FX Layouts')

            local function GetInfo(FxGUID, FX_Idx)
                if FxGUID then
                    FX[FxGUID] = FX[FxGUID] or {}
                    FX[FxGUID].File = file
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
                    local FX_Name = ChangeFX_Name(FX_Name)

                    if LO[FX_Name] then
                        FX[FxGUID] = FX[FxGUID] or {}
                        local T = LO[FX_Name]
                        FX[FxGUID].MorphHide = T.MorphHide
                        FX[FxGUID].Round = T.Round
                        FX[FxGUID].GrbRound = T.GrbRound
                        FX[FxGUID].BgClr = T.BgClr
                        FX[FxGUID].Width = T.Width
                        FX[FxGUID].TitleWidth = T.TitleWidth
                        FX[FxGUID].TitleClr = T.TitleClr
                        FX[FxGUID].CustomTitle = T.CustomTitle

                        for i, v in ipairs(T) do
                            FX[FxGUID][i]          = FX[FxGUID][i] or {}
                            local FP               = FX[FxGUID][i]
                            FP.Name                = v.Name
                            FP.Num                 = v.Num
                            FP.Sldr_W              = v.Sldr_W
                            FP.Type                = v.Type
                            FP.PosX                = v.PosX
                            FP.PosY                = v.PosY
                            FP.Style               = v.Style
                            FP.V_FontSize          = v.V_FontSize
                            FP.CustomLbl           = v.CustomLbl
                            FP.FontSize            = v.FontSize
                            FP.Height              = v.Height
                            FP.BgClr               = v.BgClr
                            FP.GrbClr              = v.GrbClr
                            FP.Lbl_Pos             = v.Lbl_Pos
                            FP.V_Pos               = v.V_Pos
                            FP.Lbl_Clr             = v.Lbl_Clr
                            FP.V_Clr               = v.V_Clr
                            FP.DragDir             = v.DragDir
                            FP.Value_Thick         = v.Value_Thick
                            FP.V_Pos_X             = v.V_Pos_X
                            FP.V_Pos_Y             = v.V_Pos_Y
                            FP.Lbl_Pos_X           = v.Lbl_Pos_X
                            FP.Lbl_Pos_Y           = v.Lbl_Pos_Y
                            FP.Image               = v.Image
                            FP.ImagePath           = v.ImagePath
                            FP.ConditionPrm        = v.ConditionPrm
                            FP.ConditionPrm_V      = v.ConditionPrm_V
                            FP.ConditionPrm_V_Norm = v.ConditionPrm_V_Norm
                            FP.Switch_On_Clr       = v.Switch_On_Clr
                            for i = 2, 5, 1 do
                                FP['ConditionPrm' .. i]        = v['ConditionPrm' .. i]
                                FP['ConditionPrm_V' .. i]      = v['ConditionPrm_V' .. i]
                                FP['ConditionPrm_V_Norm' .. i] = v['ConditionPrm_V_Norm' .. i]
                            end
                            FP.ManualValues = v.ManualValues
                            FP.ManualValuesFormat = v.ManualValuesFormat
                            FP.Draw = v.Draw
                        end
                        FX[FxGUID].Draw = T.Draw
                    else
                        local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'FX Devices', 'BryanChi_FX_Devices',
                            'src', 'FX Layouts')
                        local file_path = ConcatPath(dir_path, FX_Name .. '.ini')

                        -- Create directory for file if it doesn't exist
                        r.RecursiveCreateDirectory(dir_path, 0)
                        local file = io.open(file_path, 'r')

                        local PrmInst
                        LO[FX_Name] = LO[FX_Name] or {}
                        local T = LO[FX_Name]
                        if file then
                            Line = get_lines(file_path)
                            FX[FxGUID].FileLine = Line
                            Content = file:read('*a')
                            local Ct = Content



                            T.MorphHide = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph Hide' .. FxGUID,
                                'true', true)
                            T.Round = RecallGlobInfo(Ct, 'Edge Rounding = ', 'Num')
                            T.GrbRound = RecallGlobInfo(Ct, 'Grb Rounding = ', 'Num')
                            T.BgClr = RecallGlobInfo(Ct, 'BgClr = ', 'Num')
                            T.Width = RecallGlobInfo(Ct, 'Window Width = ', 'Num')
                            T.TitleWidth = RecallGlobInfo(Ct, 'Title Width = ', 'Num')
                            T.TitleClr = RecallGlobInfo(Ct, 'Title Clr = ', 'Num')
                            T.CustomTitle = RecallGlobInfo(Ct, 'Custom Title = ')
                            PrmInst = RecallGlobInfo(Ct, 'Param Instance = ', 'Num')
                        else
                            Draw[FX_Name] = nil
                        end




                        -------------------------------------Parameters -------------------------------------------------
                        function attachFont(ctx, var, ft, sz, FP)
                            if sz > 20 then
                                --ChangeFont = FP

                                CF = CF or {}

                                ChangeFont_Size = roundUp(sz, 1)
                                _G[var .. '_' .. roundUp(sz, 1)] = im.CreateFont(ft, roundUp(sz, 1))

                                im.Attach(ctx, _G[var .. '_' .. roundUp(sz, 1)])
                                ChangeFont_Font = var
                            end
                        end

                        if --[[ r.GetExtState('FX Devices - '..FX_Name, 'Param Instance') ~= ''  ]] PrmInst then
                            local Ct = Content
                            PrmCount = RecallGlobInfo(Ct, 'Param Instance = ', 'Num')

                            if PrmCount then
                                for Fx_P = 1, PrmCount or 0, 1 do
                                    local function L(n)
                                        return Line[n + (40 - 14) * (Fx_P - 1)]
                                    end
                                    FX[FxGUID]    = FX[FxGUID] or {}
                                    T[Fx_P]       = T[Fx_P] or {}

                                    local FP      = T[Fx_P]
                                    local ID      = FxGUID .. Fx_P

                                    FP.Name       = RecallInfo(Ct, 'Name', Fx_P)
                                    FP.Num        = RecallInfo(Ct, 'Num', Fx_P, 'Num')
                                    FP.Sldr_W     = RecallInfo(Ct, 'Width', Fx_P, 'Num')
                                    FP.Type       = RecallInfo(Ct, 'Type', Fx_P)
                                    FP.PosX       = RecallInfo(Ct, 'Pos X', Fx_P, 'Num')
                                    FP.PosY       = RecallInfo(Ct, 'Pos Y', Fx_P, 'Num')
                                    FP.Style      = RecallInfo(Ct, 'Style', Fx_P)
                                    FP.V_FontSize = RecallInfo(Ct, 'Value Font Size', Fx_P, 'Num')
                                    FP.CustomLbl  = RecallInfo(Ct, 'Custom Label', Fx_P)
                                    if FP.CustomLbl == '' then FP.CustomLbl = nil end
                                    FP.FontSize      = RecallInfo(Ct, 'Font Size', Fx_P, 'Num')
                                    FP.Height        = RecallInfo(Ct, 'Slider Height', Fx_P, 'Num')
                                    FP.BgClr         = RecallInfo(Ct, 'BgClr', Fx_P, 'Num')
                                    FP.GrbClr        = RecallInfo(Ct, 'GrbClr', Fx_P, 'Num')
                                    FP.Lbl_Pos       = RecallInfo(Ct, 'Label Pos', Fx_P)
                                    FP.V_Pos         = RecallInfo(Ct, 'Value Pos', Fx_P)
                                    FP.Lbl_Clr       = RecallInfo(Ct, 'Lbl Clr', Fx_P, 'Num')
                                    FP.V_Clr         = RecallInfo(Ct, 'V Clr', Fx_P, 'Num')
                                    FP.DragDir       = RecallInfo(Ct, 'Drag Direction', Fx_P)
                                    FP.Value_Thick   = RecallInfo(Ct, 'Value Thickness', Fx_P, 'Num')
                                    FP.V_Pos_X       = RecallInfo(Ct, 'Value Free Pos X', Fx_P, 'Num')
                                    FP.V_Pos_Y       = RecallInfo(Ct, 'Value Free Pos Y', Fx_P, 'Num')
                                    FP.Lbl_Pos_X     = RecallInfo(Ct, 'Label Free Pos X', Fx_P, 'Num')
                                    FP.Lbl_Pos_Y     = RecallInfo(Ct, 'Label Free Pos Y', Fx_P, 'Num')
                                    FP.Switch_On_Clr = RecallInfo(Ct, 'Switch On Clr', Fx_P, 'Num')

                                    local path       = RecallInfo(Ct, 'Custom Image', Fx_P)

                                    if path then
                                        FP.ImagePath = path
                                        FP.Style = 'Custom Image'
                                        FP.Image = im.CreateImage(r.GetResourcePath() .. path)
                                        im.Attach(ctx, FP.Image)
                                    end


                                    FP.ConditionPrm = RecallInfo(Ct, 'Condition Param', '\n' .. Fx_P, 'Num', '|')
                                    for i = 2, 5, 1 do
                                        FP['ConditionPrm' .. i] = RecallInfo(Ct, 'Condition Param' .. i, Fx_P, 'Num', '|')
                                    end
                                    FP.V_Round = RecallInfo(Ct, 'Decimal Rounding', Fx_P, 'Num')
                                    FP.ValToNoteL = RecallInfo(Ct, 'Value to Note Length', Fx_P, 'Num')
                                    FP.SwitchType = RecallInfo(Ct, 'Switch type', Fx_P, 'Num')
                                    FP.SwitchBaseV = RecallInfo(Ct, 'Switch Base Value', Fx_P, 'Num')
                                    FP.SwitchTargV = RecallInfo(Ct, 'Switch Target Value', Fx_P, 'Num')



                                    if FP.ConditionPrm then
                                        FP.ConditionPrm_V = RecallIntoTable(Ct, Fx_P .. '. Condition Param = %d+|1=',
                                            Fx_P, nil)
                                        FP.ConditionPrm_V_Norm = RecallIntoTable(Ct,
                                            Fx_P .. '. Condition Param Norm = |1=', Fx_P, 'Num')
                                    end
                                    for i = 2, 5, 1 do
                                        FP['ConditionPrm_V' .. i] = RecallIntoTable(Ct, Fx_P ..
                                            '. Condition Param' .. i .. ' = %d+|1=', Fx_P, nil)
                                        FP['ConditionPrm_V_Norm' .. i] = RecallIntoTable(Ct,
                                            Fx_P .. '. Condition Param Norm' .. i .. ' = |1=', Fx_P, 'Num')
                                    end

                                    if Prm.InstAdded[FxGUID] ~= true then
                                        StoreNewParam(FxGUID, FP.Name, FP.Num, FX_Idx, 'Not Deletable',
                                            'AddingFromExtState',
                                            Fx_P, FX_Idx, TrkID)
                                        r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added', 'true')
                                    end

                                    FP.ManualValues = RecallIntoTable(Ct, Fx_P .. '. Manual V:1=', Fx_P, 'Num')
                                    FP.ManualValuesFormat = RecallIntoTable(Ct, Fx_P .. '. Manual Val format:1=', Fx_P)
                                    
                                    Retrieve_Attached_Drawings(Ct, Fx_P, FP)

                                end
                                GetProjExt_FxNameNum(FxGUID)
                                Prm.InstAdded[FxGUID] = true
                            end
                        else ---- if no editings has been saved to extstate
                            if FX[FxGUID] then
                                for Fx_P = 1, #FX[FxGUID] or 0, 1 do
                                    local ID = FxGUID .. Fx_P
                                    local FP = FX[FxGUID][Fx_P]
                                    if FX[FxGUID][Fx_P] then
                                        FP.Name         = nil
                                        FP.Num          = nil
                                        FP.Sldr_W       = nil
                                        FP.Type         = nil
                                        FP.PosX         = nil
                                        FP.PosY         = nil
                                        FP.Style        = nil
                                        FP.V_FontSize   = nil
                                        FP.CustomLbl    = nil
                                        FP.FontSize     = nil
                                        FP.Sldr_H       = nil
                                        FP.BgClr        = nil
                                        FP.GrbClr       = nil
                                        FP.Lbl_Pos      = nil
                                        FP.V_Pos        = nil
                                        FP.Lbl_Clr      = nil
                                        FP.V_Clr        = nil
                                        FP.DragDir      = nil
                                        FP.ConditionPrm = nil
                                        FP.V_Round      = nil
                                        FP.ValToNoteL   = nil
                                        FP.SwitchType   = nil
                                        FP.SwitchBaseV  = nil
                                        FP.SwitchTargV  = nil
                                    end
                                end
                                GetProjExt_FxNameNum(FxGUID)
                            end
                        end

                        ------------------------------------- Drawings -------------------------------------------------
                        if file then
                            local All = file:read('*a')

                            local Top = tablefind(Line, '========== Drawings ==========') or nil


                            if Top then
                                local Ct = Content


                                local DrawInst = RecallGlobInfo(Ct, 'Total Number of Drawings = ', 'Num')


                                if DrawInst then
                                    if DrawInst > 0 then
                                        T.Draw = T.Draw or {}
                                        T.Draw.Df_EdgeRound = get_aftr_Equal_Num(Line[Top + 1])
                                    end
                                end
                                T.Draw = T.Draw or {}

                                for i = 1, DrawInst or 0, 1 do
                                    --D[i] = D[i] or {}
                                    local function LN(num)
                                        return Line[Top + 5 + ((i - 1) * 9) + num]
                                    end
                                    local ID = FX_Name .. i
                                    T.Draw[i] = T.Draw[i] or {}
                                    local D = T.Draw[i]

                                    D.Type = RecallInfo(Ct, 'Type', 'D' .. i, Type, untilwhere)
                                    D.L = RecallInfo(Ct, 'Left', 'D' .. i, 'Num')
                                    D.R = RecallInfo(Ct, 'Right', 'D' .. i, 'Num')
                                    D.T = RecallInfo(Ct, 'Top', 'D' .. i, 'Num')
                                    D.B = RecallInfo(Ct, 'Bottom', 'D' .. i, 'Num')
                                    D.clr = RecallInfo(Ct, 'Color', 'D' .. i, 'Num')
                                    D.Txt = RecallInfo(Ct, 'Text', 'D' .. i)
                                    D.Txt = RecallInfo(Ct, 'Text', 'D' .. i)
                                    D.FilePath = RecallInfo(Ct, 'ImagePath', 'D' .. i)
                                    D.KeepImgRatio = RecallInfo(Ct, 'KeepImgRatio', 'D' .. i, 'Bool')

                                    if D.FilePath then
                                        D.Image = im.CreateImage(D.FilePath)
                                        im.Attach(ctx, D.Image)
                                    end



                                    --[[ Draw[FX_Name].Type[i] = get_aftr_Equal(LN(1))
                                            D.L[i] =   get_aftr_Equal_Num(LN(2))
                                            D.R[i] =   get_aftr_Equal_Num(LN(3))
                                            D.T[i] =   get_aftr_Equal_Num(LN(4))
                                            D.B[i] =   get_aftr_Equal_Num(LN(5))
                                            D.clr[i] = get_aftr_Equal_Num(LN(6))
                                            D.Txt[i] = get_aftr_Equal(LN(7)) ]]
                                end
                            end
                        end
                        GetInfo(FxGUID, FX_Idx)
                    end
                end
            end




            local rv, FX_Count = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'container_count')

            if rv then -- if iterated fx is a container
                local Upcoming_Container
                if TREE[FX_Idx + 1] then
                    if TREE[FX_Idx + 1].children then
                        local function get_Container_Info()
                            for i, v in ipairs(Upcoming_Container or TREE[FX_Idx + 1].children) do
                                local FX_Id = v.addr_fxid
                                local GUID = v.GUID
                                GetInfo(GUID, FX_Id)
                                if v.children then
                                    Upcoming_Container = v.children
                                    get_Container_Info()
                                end

                            end
                        end


                        get_Container_Info()
                    end
                end
            else
                GetInfo(FxGUID, FX_Idx)
            end
        end
    end
end

---@param FxGUID string
---@param P_Name string
---@param P_Num number
---@param FX_Num number ---TODO this is unused
---@param IsDeletable boolean
---@param AddingFromExtState? "AddingFromExtState"
---@param Fx_P? integer|string ---TODO not sure about this
---@param FX_Idx? integer
---@param TrkID? string
function StoreNewParam(FxGUID, P_Name, P_Num, FX_Num, IsDeletable, AddingFromExtState, Fx_P, FX_Idx, TrkID)
    TrkID = TrkID or r.GetTrackGUID(r.GetLastTouchedTrack())
    if not FxGUID then  Tooltip={ Txt = 'No FX Present'; Dur = 100 ;time=0 ;clr = 0xD30000ff   } return end 
    --Trk.Prm.Inst[TrkID] = (Trk.Prm.Inst[TrkID] or 0 )+1
    --r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Trk Prm Count',Trk.Prm.Inst[TrkID], true )

    local P



    if AddingFromExtState == 'AddingFromExtState' then
        P = Fx_P
    else
        FX[FxGUID] = FX[FxGUID] or {}
        -- local Index = #FX[FxGUID] or 0
        table.insert(FX[FxGUID], Fx_P)
        FX.Prm.Count[FxGUID] = (FX.Prm.Count[FxGUID] or 0) + 1
        P = #FX[FxGUID] + 1
    end


    r.SetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID, P)
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Prm Count' .. FxGUID, P, true)


    FX[FxGUID][P] = FX[FxGUID][P] or {}
    FX[FxGUID][P].Num = P_Num
    FX[FxGUID][P].Name = P_Name
    FX[FxGUID][P].Deletable = IsDeletable


    r.SetProjExtState(0, 'FX Devices', 'FX' .. P .. 'Name' .. FxGUID, P_Name)
    r.SetProjExtState(0, 'FX Devices', 'FX' .. P .. 'Num' .. FxGUID, P_Num)
    table.insert(Prm.Num, P_Num)



    if AddingFromExtState == 'AddingFromExtState' then
        FX[FxGUID][P].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    else
        local rv, step, smallstep, largestep, istoggle = r.TrackFX_GetParameterStepSizes(LT_Track, LT_FX_Number, LT_ParamNum)
        if rv then --[[ if the param is a switch ]] end
        FX[FxGUID][P].V = r.TrackFX_GetParamNormalized(LT_Track, LT_FX_Number, LT_ParamNum)
    end
    return P
end

---TODO I think this is unused
---@param get? "get"
---@param FxGUID string
---@param FX_Idx integer
---@param Fx_P number
---@param WhichPrm integer
function GetParamOptions(get, FxGUID, FX_Idx, Fx_P, WhichPrm)
    local OP = FX.Prm.Options; local OPs, V

    if get == 'get' then OP[FxGUID] = nil end

    if not OP[FxGUID] then OP[FxGUID] = {} end
    if not OP[FxGUID][Fx_P] then
        OP[FxGUID][Fx_P] = {};

        OP[FxGUID][Fx_P] = { V = {} }
    end
    OPs = OP[FxGUID][Fx_P]
    V = OP[FxGUID][Fx_P].V


    local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, WhichPrm)



    if #OPs == 0 then
        for i = 0, 1, 0.01 do
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, i)
            local _, buf = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, WhichPrm)
            if not Value then
                Value = buf; OPs[1] = buf
                V[1] = i
            end
            if Value ~= buf then
                OPs[#OPs + 1]            = buf; V[#V + 1] = i;
                local L1                 = im.CalcTextSize(ctx, buf); local L2 = im.CalcTextSize(ctx, Value)
                FX[FxGUID][Fx_P].Combo_W = math.max(L1, L2)
                Value                    = buf
            end
        end
    end
    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, OrigV)
end


--im.SetNextWindowDockID(ctx, -1)   ---Dock the script
---@param ctx ImGui_Context
---@param img ImGui_Image
---@param angle any
---@param w any
---@param h any
---@param x any
---@param y any
function ImageAngle(ctx, img, angle, w, h, x, y)
    if not x and not y then x, y = im.GetCursorScreenPos(ctx) end
    local cx, cy = x + (w / 2), y + (h / 2)
    local rotate = function(x, y)
        x, y = x - cx, y - cy
        return (x * math.cos(angle) - y * math.sin(angle)) + cx,
            (x * math.sin(angle) + y * math.cos(angle)) + cy
    end
    local dl = im.GetWindowDrawList(ctx)
    local p1_x, p1_y = rotate(x, y)
    local p2_x, p2_y = rotate(x + w, y)
    local p3_x, p3_y = rotate(x + w, y + h)
    local p4_x, p4_y = rotate(x, y + h)
    im.DrawList_AddImageQuad(dl, img,
        p1_x, p1_y, p2_x, p2_y, p3_x, p3_y, p4_x, p4_y)
    --im.Dummy(ctx, w, h)
end


---@param FP table 
---@param file string
function Save_Drawings(FP, file,Fx_P)

    if FP.Draw then
        if Fx_P then 
            file:write(Fx_P.. '. Number of attached drawings = ', #FP.Draw or '', '\n')
        else
            file:write('Number of attached drawings = ', #FP.Draw or '', '\n')
        end
        for D, v in ipairs(FP.Draw) do

            local function WRITE(name, val)
                local val = tostring(val)
                if val =='nil' then val = nil end 
                if Fx_P then 
                    file:write(Fx_P..'. Draw Item ' .. D .. ': ' .. name ..' = ', val or '' ,'\n')
                else
                    file:write('Draw Item ' .. D .. ': ' .. name ..' = ', val or '' ,'\n')
                end
            end
            WRITE('Type', v.Type)
            WRITE('X Offset', v.X_Offset)
            WRITE('X Offset Value Affect', v.X_Offset_VA)
            WRITE('X Offset Value Affect GR', v.X_Offset_VA_GR)
            WRITE('Y offset', v.Y_Offset)
            WRITE('Y Offset Value Affect', v.Y_Offset_VA)
            WRITE('Y Offset Value Affect GR', v.Y_Offset_VA_GR)
            WRITE('Width', v.Width)
            WRITE('Width SS', v.Width_SS)
            WRITE('Width Value Affect', v.Width_VA)
            WRITE('Width Value Affect GR', v.Y_Offset_VA_GR)
            WRITE('Color', v.Clr)
            WRITE('Color_VA', v.Clr_VA)
            WRITE('Fill Color', v.FillClr)
            WRITE('Angle Min', v.Angle_Min)
            WRITE('Angle Max', v.Angle_Max)
            WRITE('Radius Inner', v.Rad_In)
            WRITE('Radius Inner SS', v.Rad_In_SS)
            WRITE('Radius Outer', v.Rad_Out)
            WRITE('Radius Outer SS', v.Rad_Out_SS)
            WRITE('Thick', v.Thick)
            WRITE('Height', v.Height)
            WRITE('Height SS', v.Height_SS)

            WRITE('Height_VA', v.Height_VA)
            WRITE('Height_VA GR', v.Height_VA_GR)
            WRITE('Round', v.Round)
            WRITE('Repeat', v.Repeat)
            WRITE('Repeat_VA', v.Repeat_VA)
            WRITE('Repeat_VA GR', v.Repeat_VA_GR)
            WRITE('Y_Repeat', v.Y_Repeat)
            WRITE('Y_Repeat_VA', v.Y_Repeat_VA)
            WRITE('Y_Repeat_VA GR', v.Y_Repeat_VA_GR)
            WRITE('Gap', v.Gap)
            WRITE('Gap_VA', v.Gap_VA)
            WRITE('Gap_VA GR', v.Gap_VA_GR)
            WRITE('X_Gap', v.X_Gap)
            WRITE('X_Gap_VA', v.X_Gap_VA)
            WRITE('X_Gap_VA GR', v.X_Gap_VA_GR)
            WRITE('Y_Gap', v.Y_Gap)
            WRITE('Y_Gap_VA', v.Y_Gap_VA)
            WRITE('Y_Gap_VA GR', v.Y_Gap_VA_GR)
            WRITE('RPT_Clr', v.RPT_Clr)
            WRITE('Image_Path', v.FilePath)

        end
    end
end

---@param FX_Name string
---@param ID string ---TODO this param is not used
---@param FxGUID string
function SaveLayoutEditings(FX_Name, FX_Idx, FxGUID)
    local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'FX Devices', 'BryanChi_FX_Devices', 'src', 'FX Layouts')
    --local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
    local FX_Name = ChangeFX_Name(FX_Name)
    local file_path = ConcatPath(dir_path, FX_Name .. '.ini')


    r.RecursiveCreateDirectory(dir_path, 0)

    local file = io.open(file_path, 'w')
    if file then
        local function write(Name, Value)
            file:write(Name, ' = ', Value or '', '\n')
        end


        file:write('FX global settings', '\n\n')
        write('Edge Rounding', FX[FxGUID].Round)   -- 2
        write('Grb Rounding', FX[FxGUID].GrbRound) -- 3
        write('BgClr', FX[FxGUID].BgClr)           -- 4
        write('Window Width', FX[FxGUID].Width)    -- 5
        write('Title Width', FX[FxGUID].TitleWidth)
        write('Title Clr', FX[FxGUID].TitleClr)
        write('Custom Title', FX[FxGUID].CustomTitle)

        write('Param Instance', #FX[FxGUID]) -- 6

        file:write('\nParameter Specific Settings \n\n')

        for i, v in ipairs(FX[FxGUID]) do
            local Fx_P = i
            local FP = FX[FxGUID][i]
            if type(i) ~= 'number' and i then
                i = 1; FP = {}
            end
            local function write(Name, v)
                if v then

                    if type(v)=='boolean' then 
                        v = tostring(v)
                    end 
                    file:write(i .. '. ' .. Name, ' = ', v or '', '\n')
                end
            end


            file:write('\n-----------------Prm ', i, '-----------------\n')
            write('Name', FP.Name)
            write('Num', FP.Num)
            write('Width', FP.Sldr_W)
            write('Type', FP.Type or FX.Def_Type[FxGUID] or 'Slider')
            write('Pos X', FP.PosX)
            write('Pos Y', FP.PosY)
            write('Style', FP.Style)
            write('Value Font Size', FP.V_FontSize)
            write('Custom Label', FP.CustomLbl)
            write('Font Size', FP.FontSize)
            write('Slider Height', FP.Height)
            write('BgClr', FP.BgClr)
            write('GrbClr', FP.GrbClr)
            write('Label Pos', FP.Lbl_Pos)
            write('Value Pos', FP.V_Pos)
            write('Lbl Clr', FP.Lbl_Clr)
            write('V Clr', FP.V_Clr)
            write('Switch On Clr', FP.Switch_On_Clr)
            write('Drag Direction', FP.DragDir)
            write('Value Thickness', FP.Value_Thick)
            write('Value Free Pos X', FP.V_Pos_X)
            write('Value Free Pos Y', FP.V_Pos_Y)
            write('Label Free Pos X', FP.Lbl_Pos_X)
            write('Label Free Pos Y', FP.Lbl_Pos_Y)
            write('Custom Image', FP.ImagePath)





            if FP.ConditionPrm_V then
                file:write(i .. '. Condition Param = ', FP.ConditionPrm or '')

                for i, v in pairs(FP.ConditionPrm_V) do
                    file:write('|', i, '=', v or '')
                    --write('Condition Params Value'..i, v)
                end
                file:write('|\n')
            else
                file:write('\n')
            end

            if FP.ConditionPrm_V_Norm then
                file:write(i .. '. Condition Param Norm = ')
                for i, v in ipairs(FP.ConditionPrm_V_Norm) do
                    file:write('|', i, '=', v or '')
                end
                file:write('|\n')
            else
                file:write('\n')
            end

            for I = 2, 5, 1 do
                if FP['ConditionPrm_V' .. I] then
                    file:write(i .. '. Condition Param' .. I .. ' = ', FP['ConditionPrm' .. I] or '')

                    if FP['ConditionPrm_V' .. I] then
                        for i, v in pairs(FP['ConditionPrm_V' .. I]) do
                            file:write('|', i, '=', v or '')
                            --write('Condition Params Value'..i, v)
                        end
                        file:write('|\n')
                    else
                        file:write('\n')
                    end

                    if FP['ConditionPrm_V_Norm' .. I] then
                        file:write(i .. '. Condition Param Norm' .. I .. ' = ')
                        for i, v in ipairs(FP['ConditionPrm_V_Norm' .. I]) do
                            file:write('|', i, '=', v or '')
                        end
                        file:write('|\n')
                    else
                        file:write('\n')
                    end
                end
            end

            write('Decimal Rounding', FP.V_Round)
            write('Value to Note Length', FP.ValToNoteL)
            write('Switch type', FP.SwitchType)
            write('Switch Base Value', FP.SwitchBaseV)
            write('Switch Target Value', FP.SwitchTargV)


            if FP.ManualValues then
                if FP.ManualValues[1] then
                    file:write(i .. '. Manual V:')
                    for i, V in ipairs(FP.ManualValues) do
                        file:write(i, '=', V, '|')
                    end
                    file:write('\n')
                    file:write(i .. '. Manual Val format:')
                    for i, V in ipairs(FP.ManualValuesFormat) do
                        file:write(i, '=', V, '|')
                    end
                    file:write('\n')
                end
            end

            Save_Drawings(FP, file, Fx_P)
 
        end
        file:close()
    end

    r.SetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID, #FX[FxGUID])
    --[[ for i, v in pairs (FX[FxGUID]) do
        local Fx_P=i
        local FP = FX[FxGUID][i]

        if type(i)~= 'number' and i then i = 1 ; FP={} end

        r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P ..'s Param Name', FP.Name or '', true )
        r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P ..'s Param Num', FP.Num or '', true )

        r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P ..'s Width', FP.Sldr_W or  '' , true)
        r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Type', FP.Type or '', true)


        if FP.PosX then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Pos X'   , FP.PosX, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Pos X',true) end
        if FP.PosY  then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Pos Y'   , FP.PosY, true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Pos Y',true ) end
        if FP.Style then r.SetExtState('FX Devices - '..FX_Name,  'Prm'..Fx_P..'s Style'   ,FP.Style,  true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Style', true ) end
        if FP.V_FontSize then r.SetExtState('FX Devices - '..FX_Name,  'Prm'..Fx_P..'s V_FontSize'   ,FP.V_FontSize,  true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s V_FontSize', true ) end
        if FP.CustomLbl then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Custom Label'   , FP.CustomLbl, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Custom Label', true ) end
        if FP.FontSize then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Font Size'   , FP.FontSize, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Font Size', true )  end
        if FP.Sldr_H then  r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Slider Height'   , FP.Sldr_H, true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Slider Height', true ) end
        if FP.BgClr then  r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s BgClr'   , FP.BgClr, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s BgClr', true ) end
        if FP.GrbClr then  r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s GrbClr'   , FP.GrbClr, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s GrbClr', true )        end

        if FP.Lbl_Pos then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Label Pos'   , FP.Lbl_Pos, true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Label Pos', true )    end
        if FP.V_Pos then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Value Pos'   , FP.V_Pos, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Value Pos', true )   end
        if FP.Lbl_Clr then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Lbl Clr'   , FP.Lbl_Clr, true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Lbl Clr', true )   end
        if FP.V_Clr then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s V Clr'   , FP.V_Clr, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s V Clr', true ) end
        if FP.DragDir then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Drag Direction'   , FP.DragDir, true)else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Drag Direction', true ) end
        if FP.ConditionPrm then r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Condition Param'   , FP.ConditionPrm, true) else r.DeleteExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Condition Param', true ) end
        if FP.ConditionPrm_V then
            for i, v in pairs(FP.ConditionPrm_V) do
                r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Condition Params Value'..i  , v, true)
            end
            r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Condition Params Value How Many'   , #FP.ConditionPrm_V, true)

        end
        if FP.V_Round then r. SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Decimal Rounding'   , FP.V_Round, true) end
        if FP.ValToNoteL~=nil then r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Value to Note Length'   , tostring(FP.ValToNoteL), true) end
        if FP.SwitchType then r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Switch type'   , FP.SwitchType, true) end
        if FP.SwitchBaseV then r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Switch Base Value'   , FP.SwitchBaseV, true) end
        if FP.SwitchTargV then r.SetExtState('FX Devices - '..FX_Name, 'Prm'..Fx_P..'s Switch Target Value'   , FP.SwitchTargV, true) end


    end ]]


    SaveDrawings(FX_Idx, FxGUID)
end


function Save_Attached_Drawings_As_Style(Name, Type, FP )
    local dir_path = ConcatPath(CurrentDirectory , 'src', 'Layout Editor Item Styles', Type)

    local file_path = ConcatPath(dir_path, tostring(Name) .. '.ini')

    r.RecursiveCreateDirectory(dir_path, 0)
    local file = io.open(file_path, 'w')
    if not file then return end 
    file:write('Prm type = '.. Type..'\n')
    --set size to 15, and sync all drawing size
    local orig_sz = FP.Sldr_W
    FP.Sldr_W = 15 
    Sync_Size_Height_Synced_Properties(FP, 15- orig_sz )

    Save_Drawings(FP, file)
    -- set size back to original size
    FP.Sldr_W = orig_sz
    Sync_Size_Height_Synced_Properties(FP, orig_sz- 15 )


end


---@param FxGUID string
---@param Fx_P number
---@param ItemWidth number
---@param ItemType 'V-Slider' | 'Sldr' |'Drag' |'Selection'
---@param PosX number
---@param PosY number
function MakeItemEditable(FxGUID, Fx_P, ItemWidth, ItemType, PosX, PosY)
    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true and Mods ~= Apl then
        local DeltaX, DeltaY = im.GetMouseDelta(ctx); local MouseX, MouseY = im.GetMousePos(ctx)
        local FP = FX[FxGUID][Fx_P]
        WinDrawList = im.GetWindowDrawList(ctx)
        local L, T = im.GetItemRectMin(ctx); local w, h = im.GetItemRectSize(ctx); 
        local R = L + w; 
        local B =T +h;
        im.DrawList_AddRect(WinDrawList, L, T, R, B, 0x999999ff)
        local LongClickDuration = 0.1
        local ResizeNode_sz = 5 

        local function ChangeItmPos()
            if LBtnDrag and not im.IsAnyItemActive(ctx) and not LE.ChangingTitleSize     then
                HelperMsg.Need_Add_Mouse_Icon = 'L'
                HelperMsg.Ctrl_L = 'Lock Y Axis'
                HelperMsg.Alt_L = 'Lock X Axis'
                HelperMsg.Shift_L = 'Disable grid snapping'


                local Dx, Dy = im.GetMouseDelta(ctx)
                if Mods == Ctrl or Mods == Ctrl + Shift then
                    Dx = 0
                elseif Mods == Alt or Mods == Alt + Shift then
                    Dy = 0
                end
                im.SetMouseCursor(ctx, im.MouseCursor_ResizeAll)
                FP.PosX = FP.PosX or PosX
                FP.PosY = FP.PosY or PosY
                FP.PosX = FP.PosX + Dx; FP.PosY = FP.PosY + Dy
                AddGuideLines(0xffffff44, L, T, R, B)
                
            end
        end


        local function Qunantize_Item_Pos_To_Grid(FP)
            
            if (Mods ~= Shift and Mods ~= Shift + Ctrl and Mods ~= Shift + Alt) and FP.PosX and FP.PosY then
                local X_Dif, Y_Dif = math.abs(Orig_Item_Pos_X - FP.PosX), math.abs(Orig_Item_Pos_Y - FP.PosY)
                if X_Dif > LE.GridSize*0.55 or Y_Dif > LE.GridSize*0.55 then -- if item is moved more than grid size
                    -- qunatize pos to grid 
                    FP.PosX = SetMinMax(roundUp(FP.PosX, LE.GridSize), 0,Win_W - (FP.Sldr_W or 15))
                    FP.PosY = SetMinMax(roundUp(FP.PosY, LE.GridSize), 0, 220 - 10)
                else -- move items back to original pos
                    FP.PosX = Orig_Item_Pos_X
                    FP.PosY = Orig_Item_Pos_Y
                end
            end
        end 


        local function Highlight_Selected_Itms()
            for i, v in pairs(LE.Sel_Items) do
                if Fx_P == v then
                    HighlightSelectedItem(0x66666644, 0xffffffff, 0, L, T, R, B, h, w, 5, 4)
                    LE.SelectedItemType = ItemType
                end
            end
        end

        local function Hover_On_Resize_Handle()
            local S = ResizeNode_sz
            if ItemType == 'V-Slider' or ItemType == 'Sldr' or ItemType == 'Drag' or ItemType == 'Selection' then
                if MouseX > R - S and MouseX < R + S and MouseY > T and MouseY < B then
                    im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW)
                    return true 
                end
            elseif ItemType == 'Knob' or (not ItemType and FX.Def_Type[FxGUID] == 'Knob') then
                if MouseX > R - S and MouseX < R + S and MouseY > B - S and MouseY < B + S then
                    im.SetMouseCursor(ctx, im.MouseCursor_ResizeNWSE)
                    return true 
                end
            end
        end
        local function Mouse_Interaction()
            local S = ResizeNode_sz
            --- if mouse is on an item
            if im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                if MouseX > L and MouseX < R - S and MouseY > T and MouseY < B and  not Hover_On_Resize_Handle() then

                    if IsLBtnClicked and Mods == 0 then
                        if #LE.Sel_Items > 1 then 
                        else
                        LE.Sel_Items = {Fx_P}
                        end

                    elseif IsLBtnClicked and Mods == Shift then
                        local ClickOnSelItem, ClickedItmNum
                        for i, v in pairs(LE.Sel_Items) do
                            if v == Fx_P then
                                ClickedItmNum = i
                            else
                            end
                        end
                        if ClickedItmNum then
                            table.remove(LE.Sel_Items, ClickedItmNum)
                        else
                            table.insert(LE.Sel_Items,Fx_P)
                        end
                    end

                    if IsLBtnClicked and not ChangePrmW then
                        ClickOnAnyItem = true
                        FP.PosX = PosX
                        FP.PosY = PosY

                            if #LE.Sel_Items > 1 then
                                LE.ChangePos = LE.Sel_Items
                            else
                                LE.ChangePos = Fx_P
                            end

                        Orig_Item_Pos_X, Orig_Item_Pos_Y = FP.PosX, FP.PosY

                    end

                    
                end
            end
        end

        local function Allow_Use_Keyboard_To_Edit()

            if LE.Sel_Items and not im.IsAnyItemActive(ctx) then
                if im.IsKeyPressed(ctx, im.Key_DownArrow) and Mods == 0 then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosY = FX[FxGUID][v].PosY + LE.GridSize end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_UpArrow) and Mods == 0 then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosY = FX[FxGUID][v].PosY - LE.GridSize end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_LeftArrow) and Mods == 0 then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosX = FX[FxGUID][v].PosX - LE.GridSize end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_RightArrow) and Mods == 0 then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosX = FX[FxGUID][v].PosX + LE.GridSize end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_DownArrow) and Mods == Shift then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosY = FX[FxGUID][v].PosY + 1 end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_UpArrow) and Mods == Shift then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosY = FX[FxGUID][v].PosY - 1 end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_LeftArrow) and Mods == Shift then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosX = FX[FxGUID][v].PosX - 1 end
                    end
                elseif im.IsKeyPressed(ctx, im.Key_RightArrow) and Mods == Shift then
                    for i, v in ipairs(LE.Sel_Items) do
                        if v == Fx_P then FX[FxGUID][v].PosX = FX[FxGUID][v].PosX + 1 end
                    end
                end
            end
        end


        local function Item_Resize_Handles()



            -- Right Bound
            if ItemType == 'V-Slider' or ItemType == 'Sldr' or ItemType == 'Drag' or ItemType == 'Selection' then
                im.DrawList_AddCircleFilled(WinDrawList, R, T + h / 2, 3, 0x999999dd)
                if MouseX > R - 5 and MouseX < R + 5 and MouseY > T and MouseY < B then
                    im.DrawList_AddCircleFilled(WinDrawList, R, T + h / 2, 4, 0xbbbbbbff)
                    im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW)
                    if IsLBtnClicked then
                        local ChangeSelectedItmBounds 
                        if #LE.Sel_Items > 1 then 
                            for i, v in pairs(LE.Sel_Items) do
                                if v == Fx_P then
                                    ChangeSelectedItmBounds = true
                                end
                            end
                            if ChangeSelectedItmBounds then
                                ChangePrmW = 'group'
                            end
                        else
                            ChangePrmW = Fx_P
                        end
                    end 
                end
            elseif ItemType == 'Knob' or (not ItemType and FX.Def_Type[FxGUID] == 'Knob') then
                im.DrawList_AddCircleFilled(WinDrawList, R, B, 3, 0x999999dd)
                if MouseX > R - 5 and MouseX < R + 5 and MouseY > B - 5 and MouseY < B + 3 then
                    im.SetMouseCursor(ctx, im.MouseCursor_ResizeNWSE)
                    im.DrawList_AddCircleFilled(WinDrawList, R, B, 4, 0xbbbbbbff)
                    if IsLBtnClicked then
                        local ChangeSelItmRadius
                        for i, v in pairs(LE.Sel_Items) do
                            if v == Fx_P then ChangeSelItmRadius = true end
                        end
                        if ChangeSelItmRadius then LE.ChangeRadius = 'Group' else LE.ChangeRadius = Fx_P end
                    end
                end
            end

            --[[ if Hover_On_Resize_Handle() and IsLBtnClicked then 
                local ChangeSelItmRadius
                for i, v in pairs(LE.Sel_Items) do
                    if v == Fx_P then ChangeSelItmRadius = true end
                end
                if ChangeSelItmRadius then LE.ChangeRadius = 'Group' else LE.ChangeRadius = Fx_P end

            end 
 ]]
        end



        function ChangeParamWidth(Fx_P)
            im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW)
            im.DrawList_AddCircleFilled(WinDrawList, R, T + h / 2, 3, 0x444444ff)
            local MsDragDeltaX, MsDragDeltaY = im.GetMouseDragDelta(ctx); local Dx, Dy = im.GetMouseDelta( ctx)

            if ItemWidth == nil then
                if ItemType == 'Sldr' or ItemType == 'Drag' then
                    ItemWidth = 160
                elseif ItemType == 'Selection' then
                    ItemWidth = FP.Combo_W
                elseif ItemType == 'Switch' then
                    ItemWidth = FP.Switch_W
                elseif ItemType == 'Knob' then
                    ItemWidth = Df.KnobRadius
                elseif ItemType == 'V-Slider' then
                    ItemWidth = 15
                end
            elseif ItemWidth < LE.GridSize and ItemType ~= 'V-Slider' then
                ItemWidth = LE.GridSize
            elseif ItemWidth < 5 and ItemType == 'V-Slider' then
                ItemWidth = 4
            end

            if Mods == 0 then 
                ItemWidth = ItemWidth + Dx 
                Sync_Size_Height_Synced_Properties(FP, Dx)
            end

            if ItemType == 'Sldr' or ItemType == 'V-Slider' or ItemType == 'Drag' or ItemType == 'Selection' or ItemType == 'Switch' then
                FP.Sldr_W = ItemWidth
            end
            if LBtnRel and ChangePrmW == Fx_P then
                local w = FP.Sldr_W 
                FP.Sldr_W = roundUp(FP.Sldr_W, LE .GridSize)
                local dif = FP.Sldr_W - w
                Sync_Size_Height_Synced_Properties(FP, dif)
            end
            if LBtnRel then ChangePrmW = nil end
            AdjustPrmWidth = true
        end

        function ChangeKnobRadius(Fx_P)
            im.SetMouseCursor(ctx, im.MouseCursor_ResizeNWSE)
            im.DrawList_AddCircleFilled(WinDrawList, R, B, 3, 0x444444ff)
            local Dx, Dy = im.GetMouseDelta(ctx)
            if not FP.Sldr_W then FP.Sldr_W = Df.KnobRadius end
            local DiagDrag = (Dx + Dy) / 2
            if Mods == 0 then
                FP.Sldr_W = FP.Sldr_W + DiagDrag;
                Sync_Size_Height_Synced_Properties(FP,DiagDrag)
            end
            if LBtnRel and LE.ChangeRaius == Fx_P then
                FP.Sldr_W = roundUp(FP.Sldr_W, LE.GridSize / 2)
            end
            if LBtnRel then LE.ChangeRadius = nil end
            ClickOnAnyItem = true
            FP.Sldr_W = math.max(FP.Sldr_W, 10)
        end

        local function Change_Size_or_Move()

            if LE.ChangeRadius == Fx_P then
                ChangeKnobRadius(Fx_P)
            elseif LE.ChangeRadius == 'Group' then
                for i, v in pairs(LE.Sel_Items) do
                    if v == Fx_P then
                        ChangeKnobRadius(v)
                    end
                end
            end
    
    
            if ChangePrmW == 'group' then
                for i, v in pairs(LE.Sel_Items) do
                    if v == Fx_P then
                        ChangeParamWidth(v)
                    end
                end
            elseif ChangePrmW == Fx_P then
                ChangeParamWidth(Fx_P)
            end
    
            
            if LE.ChangePos == Fx_P then
             
                ChangeItmPos()
            elseif LBtnDrag and type(LE.ChangePos) == 'table' then
                for i, v in pairs(LE.ChangePos) do
                    if v == Fx_P then
                        ChangeItmPos()
                    end
                end
            end
            local Rl = im.IsMouseReleased(ctx, 0)
            
            if Rl and LE.ChangePos == Fx_P  then 
               
                Qunantize_Item_Pos_To_Grid(FP)
    
            elseif Rl and tablefind(LE.ChangePos, Fx_P)  then  
                    
                for i, v in pairs(LE.ChangePos) do
                    Qunantize_Item_Pos_To_Grid(FX[FxGUID][v])
                
                end
            end 
            if Rl then 
                LE.ChangePos = nil
            end
        end

        local function Marquee_Select_Items()

            if  im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                --if MouseX > L and MouseX < R - 5 and MouseY > T and MouseY < B then
                if im.IsMouseClicked(ctx,1) then 
                    Marq_Start = {im.GetMousePos(ctx)}
                    if Mods ~= Shift then 
                        LE.Sel_Items ={}
                    end
                end 

                if im.IsMouseDown(ctx,1)  then 
                    local S = Marq_Start --Start
                    local N = {im.GetMousePos(ctx)} --now
                    local ItmCtX = L+ (R-L)/2
                    local ItmCtY = T+ (B-T)/2

                    local minX = math.min(S[1], N[1])
                    local minY = math.min(S[2], N[2])
                    im.DrawList_AddRectFilled(WDL, S[1], S[2], N[1], N[2], 0xffffff05)
                    im.DrawList_AddCircle(WDL, ItmCtX,ItmCtY, 5, 0xffffff88)


                    -- if marquee covers item center

                    if minX+ math.abs(S[1]- N[1]) > ItmCtX and minX < ItmCtX 
                        and minY+ math.abs(S[2] - N[2]) > ItmCtY and minY < ItmCtY   then 
                        im.DrawList_AddCircleFilled(WDL, ItmCtX,ItmCtY, 5, 0xffffff88)
                        
                        if not FindExactStringInTable(LE.Sel_Items , Fx_P) then 
                            table.insert(LE.Sel_Items , Fx_P)
                        end 
                    elseif FindExactStringInTable(LE.Sel_Items , Fx_P) then
                        im.DrawList_AddCircleFilled(WDL, ItmCtX,ItmCtY, 5, 0xffffff88)

                    end 
                else 

                    Marq_Start = nil

                end 



                --end
            end
        end







        Item_Resize_Handles()

        Highlight_Selected_Itms()
        Mouse_Interaction()
        Allow_Use_Keyboard_To_Edit()    
        Change_Size_or_Move()
        Marquee_Select_Items()



        
        

    end
end

---@param Clr any
---@param L number
---@param T number
---@param R number
---@param B number
function AddGuideLines(Clr, L, T, R, B)
    im.DrawList_AddLine(Glob.FDL, L, T, L - 9999, T, Clr)
    im.DrawList_AddLine(Glob.FDL, R, T, R + 9999, T, Clr)
    im.DrawList_AddLine(Glob.FDL, L, B, L - 9999, B, Clr)
    im.DrawList_AddLine(Glob.FDL, R, B, R + 9999, B, Clr)
    im.DrawList_AddLine(Glob.FDL, L, T, L, T - 9999, Clr)
    im.DrawList_AddLine(Glob.FDL, L, B, L, B + 9999, Clr)
    im.DrawList_AddLine(Glob.FDL, R, B, R, B + 9999, Clr)
    im.DrawList_AddLine(Glob.FDL, R, B, R, B + 9999, Clr)
    im.DrawList_AddLine(Glob.FDL, R, T, R, T - 9999, Clr)
end

---@param img ImGui_Image
---@param V number
---@return number uvmin
---@return number uvmax
---@return number w
---@return number h
function Calc_strip_uv(img, V)
    local V = V or 0
    local w, h = im.Image_GetSize(img)
    local FrameNum = h / w

    local StepizedV = (SetMinMax(math.floor(V * FrameNum), 0, FrameNum - 1) / FrameNum)

    local uvmin = (1 / FrameNum) * StepizedV * FrameNum

    local uvmax = 1 / FrameNum + (1 / FrameNum) * StepizedV * FrameNum


    return uvmin, uvmax, w, h

    --[[  if h > w * 5 then          -- It's probably a strip knob file
            local FrameNum = h / w -- 31
            local scale = 2
            local sz = radius_outer * scale

            local StepizedV = (SetMinMax(math.floor(FP.V * FrameNum), 0, FrameNum - 1) / FrameNum)

            local uvmin = (1 / FrameNum) * StepizedV * FrameNum

            local uvmax = 1 / FrameNum + (1 / FrameNum) * StepizedV * FrameNum
            im.DrawList_AddImage(WDL, FP.Image, center[1] - sz / 2, center[2] - sz / 2, center[1] + sz / 2,
                center[2] + sz / 2, 0, uvmin, 1, uvmax, FP.BgClr or 0xffffffff)
        end ]]
end
