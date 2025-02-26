-- @noindex
Size_Sync_Properties= {'Width_SS', 'Rad_In_SS', 'Rad_Out_SS'}  --- used when user drag node to resize items

function Sync_Size_Height_Synced_Properties(FP, diff)
    if not FP.Draw then return end     

    local function Main (V)
        for i, v in ipairs(Size_Sync_Properties) do 
            if V[v] then 
                V[string.sub(v,1, -4)] =V[string.sub(v,1, -4)] + diff
            else
            end
        end 
        if FP.Type == 'Knob' then 
            
            if V.Width_SS then 
                V.Height = (V.Height or Get_Default_Param_Height_By_Type(FP.Type) ) + diff
            end
        end
    end
    
    for I, V in ipairs(FP.Draw) do 
        if V[1] then 
            for i, tb in ipairs(V) do 
                Main(tb)
            end
        else
            Main(V)
        end
    end 
end

function Drag_Drop_Image_Module(ImgFileName, TB, width, SUBFOLDER)
    if ImgFileName then
        SL() 
        local rv , hvr =  TrashIcon(13, 'Image Delete', nil, TB.TrashImgTint) 
        if rv then 
            TB.Image, ImgFileName = nil
        end
        TB.TrashImgTint = hvr
       
    end
    SL()
    if im.BeginChild(ctx, '##drop_files', width, im.GetTextLineHeight(ctx)) then
        if not ImgFileName then
            im.Text(ctx, 'Drag and drop files here...')
        else
            
            im.Text(ctx, ImgFileName)

        end
        
   
        im.EndChild(ctx)
    end

    


    if im.BeginDragDropTarget(ctx) then
        local rv, count = im.AcceptDragDropPayloadFiles(ctx)
        if rv then
            for i = 0, count - 1 do
                local filename
                local rv, filename = im.GetDragDropPayloadFile(ctx, i)

                local filepath, filename = CopyImageFile(filename, SUBFOLDER)

                ImgFileName = filename

                TB.Image = im.CreateImage(filepath)
                im.Attach(ctx, TB.Image)
            end
        end
        im.EndDragDropTarget(ctx)
    end 
    return ImgFileName
end




function Draw_Drop_Image_Module_With_Combo(TB, SUBFOLDER)
    if ImgFileName then
        SL() 
        local rv , hvr =  TrashIcon(13, 'Image Delete', nil, TB.TrashImgTint) 
        if rv then 
            TB.Image, ImgFileName = nil
        end
        TB.TrashImgTint = hvr
       
    end
    SL()
    --[[ if im.BeginChild(ctx, '##drop_files', width, im.GetTextLineHeight(ctx)) then
        if not ImgFileName then
            im.Text(ctx, 'Drag and drop files here...')
        else
            
            im.Text(ctx, ImgFileName)

        end
        
   
        im.EndChild(ctx)
    end ]]
    local function Add_Image_Styles(type, func, ...)

        local Dir = CurrentDirectory .. 'src/Images/'..type
        if im.IsWindowAppearing(ctx) then 
            AtchDrawingImg = {}
            AtchDrawingImg.Name = {}
            AtchDrawingImg.File = scandir(Dir)
            if AtchDrawingImg.File then
                for i, v in ipairs(AtchDrawingImg.File) do

                    if not AtchDrawingImg[i] then 
                        AtchDrawingImg[i] = im.CreateImage(Dir .. '/' .. v)
                        AtchDrawingImg.Name[i] = v
                        --[[ if im.ValidatePtr(AtchDrawingImg[i], 'ImGui_Image') then 
                            im.Attach(ctx, AtchDrawingImg[i])
                            AtchDrawingImg.Name[i] = v

                        else 
                            table.remove(AtchDrawingImg.File, i)

                        end ]]
                    end
                    --[[ func(AtchDrawingImg[i] , ...) ]]
                  
                end
            end
        end

        if not func then return end 
        func(AtchDrawingImg[i] , ...)
        
    end

    if im.BeginCombo(ctx, '##Choose Attached drawing image', TB.AtchImgFileNm or 'Drag and drop image here', im.ComboFlags_HeightLarge) then 
        local function addInvisibleButton(Image, sz)
            for i, v in ipairs(AtchDrawingImg) do
                if (i-1) % 3 ~= 0 and i ~= 1  then 
                    SL(nil, 20 )
                end
                im.InvisibleButton(ctx, 'attach drawing img'..i,sz,sz)
                min = {im.GetItemRectMin(ctx)}
                im.DrawList_AddImage(WDL, v, min[1],  min[2], min[1] +sz , min[2] +sz, 0, 0, 1, 1, 0xffffffff)
                if im.IsItemHovered(ctx) then 
                    im.BeginTooltip(ctx)
                    im.Text(ctx, AtchDrawingImg.Name[i])
                    im.EndTooltip(ctx)
                end
                if HighlightHvredItem() then --if clicked on highlighted itm

                    ImgFileName = AtchDrawingImg.Name[i]


                    TB.Image  = v  
                end
            end
        end
        Add_Image_Styles('Attached Drawings' , addInvisibleButton , 50)
        im.EndCombo(ctx)

    end
    


    if im.BeginDragDropTarget(ctx) then
        local rv, count = im.AcceptDragDropPayloadFiles(ctx)
        if rv then
            for i = 0, count - 1 do
                local filename
                local rv, filename = im.GetDragDropPayloadFile(ctx, i)

                local filepath, filename = CopyImageFile(filename, SUBFOLDER)

                ImgFileName = filename

                TB.Image = im.CreateImage(filepath)
                im.Attach(ctx, TB.Image)
            end
        end
        im.EndDragDropTarget(ctx)
    end 
    return  TB.Image, ImgFileName
end

function Sync_Height_Synced_Properties(FP, diff)
    if not FP.Draw  then  return end 
    local rt = FP.Type == 'V-Slider' and 1 or  2    

    for I, V in ipairs(FP.Draw) do 
        if V.Height_SS then 
            V.Height =  V.Height + diff * rt
        end
        if V.Y_Offset_SS then 
            V.Y_Offset =  V.Y_Offset + diff * rt
        end
        if V[1] then 
            for i, v in ipairs(V) do 
                if v.Height_SS then 
                    v.Height =  v.Height + diff * rt
                end
                
            end
        end
    end

end


function Write_Label_And_Value_All_Types(FP, pos, draw_list, label ,  CenteredLblPos, Font, V_Font , FormatPV, Lbl_Pos)
    if not FP then return end   
    if NEED_ATACH_NEW_FONT then return end
    local Lbl_Clr = FP.Lbl_Clr_At_Full and BlendColors(FP.Lbl_Clr, FP.Lbl_Clr_At_Full, FP.V) or FP.Lbl_Clr or getClr(im.Col_Text)
    local V_Clr = FP.V_Clr_At_Full and BlendColors(FP.V_Clr, FP.V_Clr_At_Full, FP.V) or FP.V_Clr or getClr(im.Col_Text)
    if FP.Lbl_Pos == 'Free' or Lbl_Pos == 'Free' then
        local Cx, Cy = im.GetCursorScreenPos(ctx)
        im.DrawList_AddTextEx(draw_list, _G[Font], FP.FontSize or LblTextSize or Knob_DefaultFontSize, pos[1] + (FP.Lbl_Pos_X or 0), pos[2] + (FP.Lbl_Pos_Y or 0), Lbl_Clr, FP.CustomLbl or FP.Name)
    end


    local BtnL, BtnT = im.GetItemRectMin(ctx)
    local BtnR, BtnB = im.GetItemRectMax(ctx)
    if FP.Lbl_Pos == 'Top' or Lbl_Pos == 'Top' then
        im.PushFont(ctx, _G[Font])
        local line_height = im.GetTextLineHeight(ctx)
        im.PopFont(ctx)

        local Y = BtnT - line_height  + (FP.Lbl_Pos_Y or 0) 
        local X = (CenteredLblPos or pos[1]) + (FP.Lbl_Pos_X or 0)
        im.DrawList_AddTextEx(draw_list, _G[Font], FP.FontSize or Knob_DefaultFontSize, X, Y, Lbl_Clr, label--[[ , nil, pos[1], BtnT - line_height, pos[1] + Radius * 2, BtnT + line_height ]])
    end

    if FP.V_Pos == 'Free' then
        local Ox, Oy = im.GetCursorScreenPos(ctx)

        im.DrawList_AddTextEx(draw_list, _G[V_Font], FP.V_FontSize or Knob_DefaultFontSize, pos[1] + (FP.V_Pos_X or 0), pos[2] + (FP.V_Pos_Y or 0), V_Clr, FormatPV)--,(Radius or 20) * 2)
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
function Set_To_All_Draw_Items(str, v, D )
    if Draw.SelItms then
        for i, V in ipairs(Draw.SelItms) do
            D[V][str] = v
        end
    end
end



function If_Draw_Mode_Is_Active(FxGUID, Win_L, Win_T, Win_R, Win_B, FxNameS)
    if Draw.DrawMode ~= FxGUID then return end 
    local WinDrawList = WinDrawList or im.GetWindowDrawList(ctx)
    FX[FxGUID].Draw = FX[FxGUID].Draw or {}
    local D = FX[FxGUID].Draw
    im.DrawList_AddRectFilled(WinDrawList, Win_L, Win_T, Win_R, Win_B, 0x00000033)
    
    local function Draw_Grid()
        -- add horizontal grid
        for i = 0, 220, LE.GridSize do
            im.DrawList_AddLine(WinDrawList, Win_L, Win_T + i, Win_R, Win_T + i, 0x44444411)
        end
        -- add vertical grid
        for i = 0, FX[FxGUID].Width or DefaultWidth, LE.GridSize do
            im.DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B, 0x44444411)
        end
    end

    
    local function Add_Drawing_If_Hold_Mouse_Down()
        if im.IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil and not Draw.SelItms[1] and Draw.Time == 0 then
            if Draw.Type == 'Text' then
                im.SetMouseCursor(ctx, im.MouseCursor_TextInput)
            end
            if im.IsMouseClicked(ctx, 0) and Mods == 0 then
                Draw.CurrentlyDrawing = true
                MsX_Start, MsY_Start = im.GetMousePos(ctx);
                CurX, CurY = im.GetCursorScreenPos(ctx)
                Win_MsX_Start = MsX_Start - Win_L; Win_MsY_Start = MsY_Start - Win_T
            end

            if Draw.CurrentlyDrawing then


                local MsX, MsY   = im.GetMousePos(ctx)
                local CurX, CurY = im.GetCursorScreenPos(ctx)
                local Win_MsX    = MsX - Win_L
                local Win_MsY = MsY - Win_T
                local Rad        = MsX - MsX_Start
                if IsLBtnHeld and MsX_Start then

                    local WDL = im.GetWindowDrawList(ctx)
                    local Clr  = Draw.clr or 0xffffffff
                    if Rad < 0 then Rad = Rad * (-1) end
                    if Draw.Type == 'line' then
                        MsX = Mods == Ctrl and MsX_Start or MsX
                        MsY = Mods == Shift and MsY_Start or MsY
                        HelperMsg.Need_Add_Mouse_Icon = 'L'
                        HelperMsg.Ctrl_L = 'Lock Y Axis'
                        HelperMsg.Shift_L = 'Lock X Axis'
                        im.DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX, MsY , Clr)

                    elseif Draw.Type == 'rectangle' then
                        im.DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY, Clr, FX[FxGUID].Draw.Df_EdgeRound or 0)
                        
                    elseif Draw.Type == 'Picture' then
                        im.DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY, Clr, FX[FxGUID].Draw.Df_EdgeRound or 0)
                    elseif Draw.Type == 'rect fill' then
                        im.DrawList_AddRectFilled(WDL, MsX_Start, MsY_Start, MsX, MsY, Clr, FX[FxGUID].Draw.Df_EdgeRound or 0) 
                    elseif Draw.Type == 'circle' then
                        im.DrawList_AddCircle(WDL, MsX_Start, MsY_Start, Rad, Clr)
                    elseif Draw.Type == 'circle fill' then
                        im.DrawList_AddCircleFilled(WDL, MsX_Start, MsY_Start, Rad, Clr)
                    elseif Draw.Type == 'Text' then
                        im.SetMouseCursor(ctx, im.MouseCursor_TextInput)
                    end
                end

                if im.IsMouseReleased(ctx, 0)  and Draw.Type ~= 'Text' then
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

                    if Draw.Type == 'line' then
                        D.R = Mods == Ctrl and Win_MsX_Start or Win_MsX
                        D.B = Mods == Shift and Win_MsY_Start or Win_MsY
                    end
                    --if not Draw.SelItms then Draw.SelItms = #D.Type end
                end




                if Draw.Type == 'Text' and IsLBtnClicked and Mods == 0 then
                    AddText = D and  (#D + 1 ) or 1
                end
            end
        end
        HvringItmSelector = nil
        if AddText then
            im.OpenPopup(ctx, 'Drawlist Add Text Menu')
        end

        if im.BeginPopup(ctx, 'Drawlist Add Text Menu') then
            im.SetKeyboardFocusHere(ctx)

            local enter, NewDrawTxt = im.InputText(ctx, '##' .. 'DrawTxt', NewDrawTxt)
            --im.SetItemDefaultFocus( ctx)
            D[AddText] = D[AddText] or {}
            local D = D[AddText]
            if im.IsWindowAppearing(ctx) then
                
                --[[ local MsX_Start, MsY_Start = im.GetMousePos(ctx);
                local CurX, CurY = im.GetCursorScreenPos(ctx)
                local Win_MsX_Start = MsX_Start - CurX; 
                local Win_MsY_Start = MsY_Start - CurY + 3 ]]

                D.L =  Win_MsX_Start
                D.T =  Win_MsY_Start
                D.Type =  Draw.Type
                D.B =  Win_MsY
                D.clr =  Draw.clr

            end


            if enter then
        
                D.Txt  = NewDrawTxt
            end

            if im.IsItemDeactivatedAfterEdit(ctx) then
                D.Txt = NewDrawTxt
                AddText = nil;
                NewDrawTxt = nil



                im.CloseCurrentPopup(ctx)
            end

            im.SetItemDefaultFocus(ctx)
            im.EndPopup(ctx)
        end
        if LBtnRel then Draw.CurrentlyDrawing = nil end

        if im.IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil then
            if IsLBtnClicked and Mods == 0 then
                --Draw.SelItms = {}
                Draw.Time = 1
            end
        end
        if Draw.Time > 0 then Draw.Time = Draw.Time + 1 end
        if Draw.Time > 6 then Draw.Time = 0 end
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
                if not S then return end 
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
    local function Draw_Nodes()
        if not FX[FxGUID].Draw or Mods == Cmd or FX[FxGUID].Draw.Preview then return end 

        for i, D in ipairs(FX[FxGUID].Draw) do
            local ID = FX_Name .. i
            local CircleX, CircleY = Win_L + D.L, Win_T + D.T
            local FDL = im.GetForegroundDrawList(ctx)
            if tablefind(Draw.SelItms, i )   then 
                im.DrawList_AddCircle(FDL, CircleX, CircleY, 8, ThemeClr('Accent_Clr'))
            end
            im.DrawList_AddCircle(FDL, CircleX, CircleY, 7, 0x99999999)
            im.DrawList_AddText(FDL, Win_L + D.L - 2, Win_T + D.T - 7, 0x999999ff, i)
            Draw.SelItms = Marquee_Selection({CircleX, CircleY}, Draw.SelItms,i)
            
            if tablefind(Draw.SelItms, i) then
                im.DrawList_AddCircleFilled(WDL, CircleX, CircleY, 7, 0x99999955)
            end


            --if hover on item node ...
            if im.IsMouseHoveringRect(ctx, CircleX - 5, CircleY - 5, CircleX + 5, CircleY + 10) then
                HvringItmSelector = true
                im.SetMouseCursor(ctx, im.MouseCursor_ResizeAll)
                if DragItm == nil then
                    im.DrawList_AddCircle(WDL, CircleX, CircleY, 9, 0x999999ff)
                end
                if IsLBtnClicked then
                    if Mods == 0 then 
                        if Draw.SelItms == {} then
                            Draw.SelItms = {i}
                        elseif tablefind(Draw.SelItms, i) then
                        else
                            Draw.SelItms = {i}
                        end
                    elseif Mods == Shift then 
                        if not tablefind(Draw.SelItms, i) then 
                            table.insert(Draw.SelItms , i)
                        else 
                            table.remove(Draw.SelItms, tablefind(Draw.SelItms, i))
                        end
                    end
                    local UndoLBL = #Draw.SelItms > 1 and 'Reposition '..#Draw.SelItms..' Drawing' or 'Reposition Drawing'..i
                    Create_Undo_Point(UndoLBL, FxGUID)

                    DragItm = i
                end


                if IsLBtnClicked and Mods == Alt then
                    table.remove(FX[FxGUID].Draw , i)
                    if im.BeginPopup(ctx, 'Drawlist Add Text Menu') then
                        im.CloseCurrentPopup(ctx)
                        im.EndPopup(ctx)
                    end
                end
            end

            if not IsLBtnHeld then DragItm = nil end
            local function Set_To_All_Draw_Items(str, v , diff )
                if not diff then return end 
                if Draw.SelItms then
                    for i, V in ipairs(Draw.SelItms) do
                        if FX[FxGUID].Draw[V][str] then 
                            FX[FxGUID].Draw[V][str] = FX[FxGUID].Draw[V][str] + diff
                        end
                    end
                end
            end
            
            if LBtnDrag and DragItm == i then --- Drag node to reposition
                im.SetMouseCursor(ctx, im.MouseCursor_ResizeAll)
                im.DrawList_AddCircleFilled(WDL, CircleX, CircleY, 7, 0x00000033)
                local Dx, Dy = im.GetMouseDelta(ctx)
                if D.Type ~= 'circle' and D.Type ~= 'circle fill' and D.Type ~= 'Text' then
                    --D.R = D.R + Dx -- this is circle's radius
                    Set_To_All_Draw_Items('R', D.R , Dx)

                end
               --[[  D.L = D.L + Dx
                D.T = D.T + Dy
                D.B = D.B + Dy ]]
                Set_To_All_Draw_Items('L', D.L , Dx)
                Set_To_All_Draw_Items('T', D.T , Dy)
                Set_To_All_Draw_Items('B', D.B , Dy)
                LE.BeenEdited = true
            end
        end
    end



    Draw_Grid()
    Add_Drawing_If_Hold_Mouse_Down()

    Draw_Nodes()
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

function ToAllSelItm(idx, Val, FxGUID)
    for i, v in ipairs(LE.Sel_Items) do
        FX[FxGUID][v][idx] = Val
    end
end

function Layout_Edit_Properties_Window(fx, FX_Idx)
    local Color_Palette_Width = 25
    local FxGUID = r.TrackFX_GetFXGUID( LT_Track, FX_Idx)
    if FX.LayEdit ~= FxGUID then return end
    if not Draw.CurrentlyDrawing then 
        HelperMsg.R = 'Marquee Select Items'
        HelperMsg.Shift_R = 'Add Marquee to Selection'
        HelperMsg.Others[1] = OS:find('OSX') and '| Hold Command to hide grid' or '| Hold Ctrl to hide grid'
    end
    im.PushStyleColor(ctx, im.Col_HeaderHovered, 0xffffff00)
    im.PushStyleColor(ctx, im.Col_HeaderActive, 0xffffff00)

    local FxGUID = FXGUID[FX_Idx]


    if CloseLayEdit then return end 
    if not im.Begin(ctx, 'LayoutEdit Properties', true, im.WindowFlags_NoCollapse + im.WindowFlags_NoTitleBar + im.WindowFlags_NoDocking) then return end 




    local function Save_Layout_Edit_Popup()
    
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

    end

    local function Color_Palette()

        local PalletteW = Color_Palette_Width
        local Pad = 8
        if not CloseLayEdit then
            w, h = im.GetWindowSize(ctx)
            im.SetCursorPos(ctx, w - PalletteW - Pad, PalletteW + Pad)
        end







        if not CloseLayEdit and im.BeginChild(ctx, 'Color Palette' , PalletteW, h - PalletteW - Pad * 2,nil, im.WindowFlags_NoScrollbar) then
            local function CheckClr(TB, Clr)
                if Clr and not im.IsPopupOpen(ctx, '', im.PopupFlags_AnyPopupId) then
                    if not tablefind(TB, Clr) and TB then
                        local R, G, B, A = im.ColorConvertU32ToDouble4(Clr)
                        if A ~= 0 then
                            table.insert(TB, Clr)
                        end
                        
                    end
                end
            end
           

            local function Get_ALL_Used_Colors()
                if FX[FxGUID] then 
                    local Plt = {}

                    for i, v in ipairs(FX[FxGUID]) do
                        --[[ local Is_Selected
                        for I, v in ipairs(LE.Sel_Items) do 
                            if v == i then 
                                Is_Selected = true 
                            end
                        end ]]

                        CheckClr(Plt, v.Lbl_Clr)
                        CheckClr(Plt, v.V_Clr)
                        CheckClr(Plt, v.BgClr)
                        CheckClr(Plt, v.GrbClr)
                        if v.Draw then 
                            for i, D in ipairs(v.Draw) do 
                                CheckClr(Plt, D.Clr)
                                CheckClr(Plt, D.Clr_VA)
                                CheckClr(Plt, D.RPT_Clr)
                            end
                        end


                    end
                    if FX[FxGUID].Draw then 
                        for i, v in ipairs(FX[FxGUID].Draw) do 
                            CheckClr(Plt, v.clr)
                        end
                    end
                    return Plt
                end
            end



            ClrPallet = Get_ALL_Used_Colors()
            

            

            for i, v in ipairs(ClrPallet) do
                clrpick, LblColor1 = im.ColorEdit4(ctx, '##ClrPalette' ..i .. FxGUID, v, im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                if im.IsItemClicked(ctx) and Mods == Alt then
                    table.remove(ClrPallet, tablefind(v))
                end
            end


            
            im.EndChild(ctx)
        end
        
    end

    local function Save_Drawing_Popup()
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
                Draw.DrawMode = nil
            end
            im.SameLine(ctx)

            if im.Button(ctx, '(y) Yes') then
                SaveDrawings(FX_Idx, FxGUID)
                im.CloseCurrentPopup(ctx)
                Draw.DrawMode = nil
            end
            im.EndPopup(ctx)
        end
    end

    local function Top_Bar()

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
            if CopyPrm  then 
                if im.Button(ctx, 'Paste Properties') then
                    for i, v in pairs(LE.Sel_Items) do
                        local I = FX[FxGUID][v]
                        I.Type        = CopyPrm.Type
                        I.Sldr_W      = CopyPrm.Sldr_W
                        I.Style       = CopyPrm.Style
                        I.V_FontSize  = CopyPrm.V_FontSize
                        --I.CustomLbl   = CopyPrm.CustomLbl
                        I.Image       = CopyPrm.Image
                        I.AtchImgFileNm = CopyPrm.AtchImgFileNm
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
                        I.ImgFilesName   = CopyPrm.ImgFilesName
                        I.Height      = CopyPrm.Height
                        I.Invisible = CopyPrm.Invisible
                        if CopyPrm.Draw then
                            -- use this line to pool
                            --I.Draw = CopyPrm.Draw

                            I.Draw = I.Draw or {}
                            for i, v in pairs(CopyPrm.Draw) do
                                I.Draw[i] = {}
                                for d, v in pairs(v) do
                                    I.Draw[i][d] = v
                                end
                            end
                        end
                    end
                end
            end
        end
        SL(nil, 30)

        if Draw.DrawMode == FxGUID then
            if im.Button(ctx, 'Exit Background Edit') then Draw.DrawMode = nil end
        else
            if im.Button(ctx, 'Enter Background Edit') then
                Draw.DrawMode = FxGUID
                LE.Sel_Items = {}
            end
        end
        im.Separator(ctx)

    end
    local function Background_Edit_Properties()
        if LE.Sel_Items[1]  then return end 
        if Draw.DrawMode ~= FxGUID then
            im.TextWrapped(ctx, 'Select an item to start editing')
            AddSpacing(15)
            return 
        end

        local typelbl; 
        FX[FxGUID].Draw = FX[FxGUID].Draw or {}
        local D = FX[FxGUID].Draw
        local FullWidth = -50
        
        local function Show_Selected_Drawing_Btns()
            local sz = 100
            im.BeginChild(ctx, 'Drawings Preview', FullWidth, sz)
            SL()
            Draw.SelItms = Draw.SelItms or {}
            for i, v in ipairs(D) do 
                
                local pos = {im.GetCursorScreenPos(ctx)}

                if im.Button(ctx, '##'..i..'\n'..D[i].Type ..' Drawing Selection', sz,sz) then 
                    if Mods == 0 then
                        if tablefind(Draw.SelItms, i) then 
                            if #Draw.SelItms == 1 then 
                                Draw.SelItms = {} 
                            else 
                                Draw.SelItms = {i}
                            end
                        else 
                            Draw.SelItms = {i}
                        end
                    elseif Mods == Shift then 
                        
                        if tablefind(Draw.SelItms, i) then 
                            table.remove(Draw.SelItms, tablefind(Draw.SelItms, i))
                        else
                            table.insert(Draw.SelItms, i)
                        end
                    end
                end
                pos[3], pos[4] =  im.GetItemRectMax(ctx)
                pos[1], pos[2] = pos[1]+2, pos[2]+2
                pos[3], pos[4] = pos[3]-2, pos[4]-2
                if Draw.SelItms == i then 
                    Highlight_Itm(WDL, nil, ThemeClr('Accent_Clr'),nil, nil , 2 )
                elseif tablefind(Draw.SelItms, i) then 
                    Highlight_Itm(WDL, nil, ThemeClr('Accent_Clr'), nil, nil , 2 )
                end 

                im.PushClipRect(ctx, pos[1], pos[2], pos[3], pos[4], 1)
                Draw_Background(FxGUID, pos, i, true)
                im.DrawList_AddText(WDL, pos[1], pos[2], 0x999999ff, i..'\n'..D[i].Type )
                im.PopClipRect(ctx)
                SL(nil, 2) 
            end
            im.EndChild(ctx)
        end


        Show_Selected_Drawing_Btns()
        local It = Draw.SelItms[1]
        if not It then 
            im.Text(ctx, '(!) Hold down Left button to Draw in FX Devices')
        end
        AddSpacing(5)
      
        --im.PushStyleColor(ctx, im.Col_FrameBg, 0x99999933)

        local function Set_To_All_Draw_Items(str, v, D )
            if Draw.SelItms then
                for i, V in ipairs(Draw.SelItms) do
                    D[V][str] = v
                end
            end
        end
        
        local function Type ()
            im.Text(ctx, 'Type:')
            im.SameLine(ctx)
            --if Draw.SelItms then typelbl = D[It].Type end
            Draw.Type = Draw.Type or 'line'
            im.SetNextItemWidth(ctx, FullWidth)
            if im.BeginCombo(ctx, '## Draw Type', typelbl or Draw.Type or 'line', im.ComboFlags_NoArrowButton) then
                local function setType(str)
                    if im.Selectable(ctx, str, false) then
                        if It then D[It].Type = str end
                        Draw.Type = str
                        Set_To_All_Draw_Items('Type', str , D)
                    end
                end
                setType('Picture')
                setType('line')
                setType('rectangle')
                setType('circle')
                setType('Text')

                im.EndCombo(ctx)
            end
        end

        local function TEXT()
            if not Draw.SelItms or not It then return end 
            if D[It].Type ~= 'Text' then return end

            if  im.BeginTable(ctx, "TxtProperties", 2, im.TableFlags_BordersOuter | im.TableFlags_BordersInner, -Color_Palette_Width-5) then  
                im.TableSetupColumn(ctx, "Property", im.TableColumnFlags_WidthFixed, 150)
                im.TableSetupColumn(ctx, "Value", im.TableColumnFlags_WidthStretch)
    
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.Text(ctx, "Text:")
                im.TableNextColumn(ctx)
                im.SetNextItemWidth(ctx, -FLT_MIN)
                _, D[It].Txt = im.InputText(ctx, '##' .. It .. 'Txt', D[It].Txt)
                Set_To_All_Draw_Items('Txt', D[It].Txt, D)

                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.Text(ctx, "Font Size:")
                im.TableNextColumn(ctx)
                local rv, Sz = im.InputInt(ctx, '## font size ' .. It, D[It].FtSize or 12)
                if rv then
                    D[It].FtSize = Sz
                    Set_To_All_Draw_Items('FtSize', D[It].FtSize, D)

                end
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.Text(ctx, "Font:")
                im.TableNextColumn(ctx)
                im.SetNextItemWidth(ctx, -FLT_MIN)
                local FONT = (D[It].Font or 'Andale_Mono')
                im.PushItemWidth(ctx,  300)
                local rv, FONT = im.BeginCombo(ctx, '## font ' .. It,  FONT , 0)
                if rv then
                    for i , v in ipairs(FONT_CHOICES) do
                        if im.Selectable(ctx, v) then
                            D[It].Font = v
                            Set_To_All_Draw_Items('Font', D[It].Font, D)

                        end
                    end
                    im.EndCombo(ctx)
                end

                SL()
                im.SetNextItemWidth(ctx, 150)
                local ft = D[It].Font or 'Andale_Mono'

                local rv, bold = im.Checkbox(ctx, "Bold", D[It].Font_Bold)
                if rv then
                    D[It].Font_Bold = toggle(D[It].Font_Bold)
                    Set_To_All_Draw_Items('Font_Bold', D[It].Font_Bold, D)

                end
                SL()

                local rv, italic = im.Checkbox(ctx, "Italic", D[It].Font_Italic)
                if rv then
                    D[It].Font_Italic = toggle(D[It].Font_Italic)
                    Set_To_All_Draw_Items('Font_Italic', D[It].Font_Italic, D)
                end
                im.EndTable(ctx)
            end
        end


        Type ()
        TEXT()

        local function  Drawing_Properties()
            if not It or not D or not D[It] then  return end 
            if not im.BeginTable(ctx, "DrawProperties", 4, im.TableFlags_BordersOuter | im.TableFlags_BordersInner, -Color_Palette_Width-5) then return end 


            local function Add_Val(str, index, v, step, min, max, fmt , NextRow, Width, WhiteList, BlackList)
                if WhiteList then 
                    if not tablefind(WhiteList, D[It].Type) then return end
                end
                if BlackList then 
                    if tablefind(BlackList, D[It].Type) then return end
                end
                if NextRow then 
                    im.TableNextRow(ctx) 
                    im.TableNextColumn(ctx)
                else 
                    im.TableNextColumn(ctx)
                end
                im.Text(ctx, str)
                if not NextRow then 
                    im.TableNextColumn(ctx)

                else
                    im.TableNextColumn(ctx)
                end

                im.SetNextItemWidth(ctx, Width or -FLT_MIN)

                _, D[It][index] = im.DragDouble(ctx, '##' .. str, D[It][index] or v, step, min, max, fmt or '%.2f')
                if im.IsItemActive(ctx) then 
                    Set_To_All_Draw_Items(index, D[It][index], D)
                end
                return v
            end


            local function Fill()
                if D[It].Type ~= 'rectangle' and D[It].Type ~= 'circle' then return end
                im.TableNextColumn(ctx)
                im.Text(ctx, "Fill ")
                im.TableNextColumn(ctx)
                local    clrpick, Clr = im.Checkbox(ctx, '##Drawing Color Fill', D[It].Fill)

                if clrpick then 
                    Set_To_All_Draw_Items('Fill', Clr, D)
                end
            end
            local function Colors()

                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.Text(ctx, "Color:")
                im.TableNextColumn(ctx)
                if Draw.SelItms and D[It].clr then
                    clrpick, D[It].clr = im.ColorEdit4(ctx, '##', D[It].clr or 0xffffffff, im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                else
                    clrpick, Draw.clr = im.ColorEdit4(ctx, '##', Draw.clr or 0xffffffff, im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                end
                if clrpick then 
                    Set_To_All_Draw_Items('clr', D[It].clr, D)
                end
            end
            local function Repeat_Clr()
                if D[It].Repeat == 0 then return end
                im.TableNextColumn(ctx)
                im.Text(ctx, "Repeat Color:")
                im.TableNextColumn(ctx)

                local rv, CLR =  im.ColorEdit4(ctx, '##Repeat Clr', D[It].RepeatClr or 0xffffffff, im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar) 
                if rv then 
                    Set_To_All_Draw_Items('RepeatClr', CLR, D)
                end
            end
            im.TableSetupColumn(ctx, "Property", im.TableColumnFlags_WidthFixed, 150)
            im.TableSetupColumn(ctx, "Value", im.TableColumnFlags_WidthStretch)
            im.TableSetupColumn(ctx, "Property2", im.TableColumnFlags_WidthFixed, 150)
            im.TableSetupColumn(ctx, "Value2", im.TableColumnFlags_WidthStretch)

            Colors()

            --Add_Val('Default edge rounding:', 'Df_EdgeRound', FX[FxGUID].Draw.Df_EdgeRound, 0.05, 0, 30, '%.2f', true)

            if D[It].Type == 'Picture' then
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.Text(ctx, "File Name:")
                im.TableNextColumn(ctx)
                DragDropPics = DragDropPics or {}
                D[It].BgImgFileName = Drag_Drop_Image_Module(D[It].BgImgFileName, D[It], -FLT_MIN, 'Backgrounds')
                
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.Text(ctx, "Keep Image Ratio:")
                im.TableNextColumn(ctx)
                rv, D[It].KeepImgRatio = im.Checkbox(ctx, '##KeepImgRatio', D[It].KeepImgRatio)
            end

            if Draw.SelItms then
               
                local EndPosX_LBL = D[It].Type == 'circle' and 'Radius:' or 'End Pos X:'
                if D[It].Type ~= 'Text' then

                    Fill()
                    Add_Val('Start Pos X:' , 'L', D[It].L, 1, -fx.Width, fx.Width*2, '%.0f', true)
                    Add_Val(EndPosX_LBL,'R', D[It].R, 1, -fx.Width, fx.Width*2, '%.0f', nil)
                    Add_Val('Start Pos Y:', 'T', D[It].T, 1, -Win_H, Win_H*2, '%.0f', true)
                    Add_Val('End Pos Y:', 'B', D[It].B, 1, -Win_H, Win_H*2, '%.0f', nil)
                    Add_Val('Thickness:', 'Thick', D[It].Thick, 0.1, 0, 40, '%.1f', true)
                    Add_Val('Repeat:', 'Repeat', D[It].Repeat, 1, 0, 300, '%.0f', true)
                    Repeat_Clr()
                    Add_Val('X Gap:', 'XGap', D[It].XGap, 0.2, 0, 300, '%.1f', true)
                    Add_Val('Y Gap:', 'YGap', D[It].YGap, 0.2, 0, 300, '%.1f', nil)
                    Add_Val('Size Gap:', 'Gap', D[It].Gap, 0.2, 0, 300, '%.1f', true)
                end

                
            end
            im.EndTable(ctx)
        end

        Drawing_Properties()

    
    end
    
    local function FX_Title_Properties()
        if LE.SelectedItem == 'Title' and not LE.Sel_Items[1] and  Draw.DrawMode~= FxGUID then
            im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x66666688)

            im.Text(ctx, 'Edge Round:')
            im.SameLine(ctx)
            Edited, FX[FxGUID].Round = im.DragDouble(ctx, '##' .. FxGUID .. 'Round',
                FX[FxGUID].Round, 0.01, 0, 40, '%.2f')

            im.Text(ctx, 'Grab Round:')
            im.SameLine(ctx)
            Edited, FX[FxGUID].GrbRound = im.DragDouble(ctx, '##' .. FxGUID .. 'GrbRound',
                FX[FxGUID].GrbRound, 0.01, 0, 40, '%.2f')
            im.BeginGroup(ctx)
            im.Text(ctx, 'Background Color:')
            im.SetNextItemWidth(ctx, 200)
            _, FX[FxGUID].BgClr = im.ColorPicker4(ctx, '##' .. FxGUID .. 'BgClr', FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff, im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
            if FX[FxGUID].BgClr == im.GetColor(ctx, im.Col_FrameBg) then
                HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
            end
            im.EndGroup(ctx)
            SL()
            im.BeginGroup(ctx)

            im.Text(ctx, 'FX Title Color:')
            im.SetNextItemWidth(ctx, 200)
            _, FX[FxGUID].TitleClr = im.ColorPicker4(ctx, '##' .. FxGUID .. 'Title Clr', FX[FxGUID].TitleClr or ThemeClr('FX_Title_Clr'), im.ColorEditFlags_NoInputs)
            FX[FxGUID].TitleClr = Change_Clr_A(FX[FxGUID].TitleClr, nil, 1)
            im.EndGroup(ctx)


            im.Text(ctx, 'Custom Title:')
            im.SameLine(ctx)
            local _, CustomTitle = im.InputText(ctx, '##CustomTitle' .. FxGUID,
                FX[FxGUID].CustomTitle or FX_Name)
            if im.IsItemDeactivatedAfterEdit(ctx) then
                FX[FxGUID].CustomTitle = CustomTitle
            end

            im.PopStyleColor(ctx)
        end
    end
    local function Parameter_Properties()
        if not LE.Sel_Items[1] then return end 
        local FS  = FX[FxGUID][LE.Sel_Items[1]]
        local ID, TypeID; local FrstSelItm = FX[FxGUID][LE.Sel_Items[1]]; local FItm = LE.Sel_Items[1]
        local R_ofs = 50
        local FLT_MIN, FLT_MAX = im.NumericLimits_Float()


        local flags = im.TableFlags_BordersOuter |
        im.TableFlags_BordersV |
        im.TableFlags_ContextMenuInBody|
        im.TableFlags_RowBg
        
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



        local function AddOption(Name, TargetVar, TypeCondition)
            if FS.Type == TypeCondition or not TypeCondition then
                if im.Selectable(ctx, Name, false) then
                    for i, v in pairs(LE.Sel_Items) do
                        FX[FxGUID][v][TargetVar] = Name
                    end
                end
            end
        end
        
        local function Type()
            local PrmTypeLbl = TypeID == 'Group' and 'Multiple Values' or (FS.Type or FX[FxGUID].DefType )
            FS.Type = FS.Type or FX[FxGUID].DefType or 'Slider'

            im.AlignTextToFramePadding(ctx)

            FS.Type = FS.Type or FX[FxGUID].DefType

            im.Text(ctx, 'Type : '); im.SameLine(ctx); im.PushStyleColor(ctx,
                im.Col_FrameBg, 0x444444aa)
            im.SetNextItemWidth(ctx, 200)
            if im.BeginCombo(ctx, '##', PrmTypeLbl, im.ComboFlags_NoArrowButton) then
                local function SetItemType(Type)
                    for i, v in pairs(LE.Sel_Items) do
                        FX[FxGUID][v].Sldr_W = nil
                        FX[FxGUID][v].Height = nil
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
                elseif im.Selectable(ctx, 'XY Pad', false) then
                    SetItemType('XY Pad')
                end
                im.EndCombo(ctx)
            end
        end
        

        local function Label_Name()
            SL()
            ---Label    Show only when there's one item selected-----
            if LE.Sel_Items[1] then
                im.Text(ctx, 'Label: '); im.SameLine(ctx)
                im.SetNextItemWidth(ctx, 200)
                local LblEdited, buf = im.InputText(ctx, ' ##Edit Title' .. FxGUID .. LE.Sel_Items[1], FS.CustomLbl or buf)
                --if im.IsItemActivated(ctx) then EditingPrmLbl = LE.Sel_Items[1] end
                if im.IsItemDeactivatedAfterEdit(ctx) then ToAllSelItm('CustomLbl', buf)  end



            end
        end
        
        local function Label_and_Value_Table()



            local function Value_Pos_X()
                if FS.V_Pos ~= 'None' then

                    im.SetNextItemWidth(ctx, 40)
                    local EditPosX, PosX = im.DragDouble(ctx, ' ##EditValuePosX' .. FxGUID .. LE.Sel_Items[1], FS.V_Pos_X or 0, 0.25, nil, nil, '%.2f')
                    if EditPosX then
                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Pos_X = PosX end
                    end


                end
            end
            local function Value_Pos_Y()
                if FS.V_Pos ~= 'None' then
                    im.SetNextItemWidth(ctx, 40)
                    local EditPosY, PosY = im.DragDouble(ctx, ' ##EditValuePosY' .. FxGUID .. LE.Sel_Items[1], FS.V_Pos_Y or 0, 0.25, nil, nil, '%.2f')
                    if EditPosY then
                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Pos_Y = PosY end
                    end
                end
            end


            local function Value_Pos()
                im.SetNextItemWidth(ctx, 110)

                if im.BeginCombo(ctx, '## V Pos' .. LE.Sel_Items[1], FS.V_Pos or 'Default', im.ComboFlags_NoArrowButton) then
                    AddOption('Free', 'V_Pos')
                    AddOption('Only When Active', 'V_Pos')
                    if FS.Type ~= 'Selection' then AddOption('None', 'V_Pos') end
                    im.Separator(ctx)

                    if FS.Type == 'V-Slider' then
                        AddOption('Bottom', 'V_Pos')
                        AddOption('Top', 'V_Pos')
                        
                    elseif FS.Type == 'Knob' then
                        AddOption('Top', 'V_Pos')
                        AddOption('Bottom', 'V_Pos')
                        AddOption('Within', 'V_Pos')
                    elseif FS.Type == 'Switch' or FS.Type == 'Selection' then
                        AddOption('Within', 'V_Pos')
                    
                    elseif FS.Type == 'Slider' or FS.Type == 'Drag' then
                        AddOption('Top', 'V_Pos')
                        AddOption('Right', 'V_Pos')
                        AddOption('Within', 'V_Pos')
                        AddOption('Within-Right', 'V_Pos')
                        AddOption('Bottom', 'V_Pos')
                        AddOption('Bottom-Right', 'V_Pos')
                        AddOption('Bottom-Left', 'V_Pos')
                    end



                    im.EndCombo(ctx)
                end


            end
            local function Label_Pos()
                im.SetNextItemWidth(ctx, -FLT_MIN)
                if im.BeginCombo(ctx, '## Lbl Pos' .. LE.Sel_Items[1], FS.Lbl_Pos or 'Default', im.ComboFlags_NoArrowButton) then
                    AddOption('Free', 'Lbl_Pos')
                    AddOption("None", 'Lbl_Pos')

                    im.Separator(ctx)
                    if FS.Type == 'Knob' or FS.Type == 'V-Slider' then
                        AddOption('Top', 'Lbl_Pos')
                        AddOption('Bottom', 'Lbl_Pos')
                    elseif FS.Type == 'Slider' or FS.Type == 'Drag' then
                        AddOption('Left', 'Lbl_Pos')
                        AddOption('Within-Top-Left', 'Lbl_Pos')
                        AddOption('Within-Left', 'Lbl_Pos')
                        AddOption('Top', 'Lbl_Pos')
                        AddOption('Bottom-Left', 'Lbl_Pos')
                        AddOption('Bottom-Center', 'Lbl_Pos')

                    elseif FS.Type == 'Selection' or FS.Type == 'Switch' then
                        AddOption('Top', 'Lbl_Pos')
                        AddOption('Left', 'Lbl_Pos')
                        if FS.Type == 'Switch' then AddOption('Within', 'Lbl_Pos') end
                        AddOption('Bottom', 'Lbl_Pos')
                        AddOption('Right', 'Lbl_Pos')
                    end

                    im.EndCombo(ctx)
                end
            end


            local function Label_Color()
                -- Label Color
                local  DragLbl_Clr_Edited, Lbl_V_Clr = im.ColorEdit4(ctx, '##Lbl Clr' .. LE.Sel_Items[1], FS.Lbl_Clr or im.GetColor(ctx, im.Col_Text), im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                if DragLbl_Clr_Edited then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Clr = Lbl_V_Clr end
                end
            end

            local function ColorChooser(LBL, var, isClr2)

                local Rv, Clr2 = im.ColorEdit4(ctx, LBL.. LE.Sel_Items[1], FS[var] or im.GetColor(ctx, im.Col_Text), im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                if Rv then 
                    for i, v in pairs(LE.Sel_Items) do 
                        FX[FxGUID][v][var] = Clr2 
                        FX[FxGUID][v].Lbl_Clr = FX[FxGUID][v].Lbl_Clr or im.GetColor(ctx, im.Col_Text)
                        FX[FxGUID][v].V_Clr = FX[FxGUID][v].V_Clr or im.GetColor(ctx, im.Col_Text)
                    end
                end
                if isClr2 then 
                    if im.IsItemHovered(ctx) then 

                        tooltip('Color when Param value is at 100%')
                    end
                    if not FS[var] then Cross_Out() end 
                    SL()
                    if  FS[var] then 
                        local Clr_Delete , hvr =  TrashIcon(13, 'Image Delete', nil, FS[var..'TrashImgTint']) 
                        if Clr_Delete then 
                            ToAllSelItm(tostring(var), nil, FxGUID)
                        end
                        FS[var..'TrashImgTint'] = hvr
                    end
                end
            end


            local function Label_X_Pos()
                im.SetNextItemWidth(ctx, 40)
                local EditPosX, PosX = im.DragDouble(ctx, ' ##EditLblPosX' .. FxGUID .. LE.Sel_Items[1], FS.Lbl_Pos_X or 0, 0.25, nil, nil, '%.2f')
                if EditPosX then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Pos_X = PosX end
                end
            end
            local function Label_Y_Pos()
                im.SetNextItemWidth(ctx, 40)
                local EditPosY, PosY = im.DragDouble(ctx, ' ##EditLblPosY' .. FxGUID .. LE.Sel_Items[1], FS.Lbl_Pos_Y or 0, 0.25, nil, nil, '%.2f')
                if EditPosY then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Pos_Y = PosY end
                end
            end
            local function Label_Font_Size()
                im.SetNextItemWidth(ctx, 40)
                local Drag, ft = im.DragDouble(ctx, '##EditFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''), FS.FontSize or Knob_DefaultFontSize, 0.25, 6, 64, '%.2f')
                if Drag then
                    local sz = roundUp(ft, 1)
                    for i, v in pairs(LE.Sel_Items) do
                        GetFonts(FX[FxGUID][v]) 
                        FX[FxGUID][v].FontSize = ft
                    end

                end
            end

            local function Value_Font_Size()
                im.SetNextItemWidth(ctx, 40)
                local Drag, ft = im.DragDouble(ctx,'##EditV_FontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),FX[FxGUID][LE.Sel_Items[1]].V_FontSize or Knob_DefaultFontSize, 0.25, 6,64,'%.2f')
                if Drag then
                    local sz = roundUp(ft, 1)

                    for i, v in pairs(LE.Sel_Items) do
                        GetFonts(FX[FxGUID][v]) 
                        FX[FxGUID][v].V_FontSize = ft
                    end
                end
            end
            local function Value_Decimal_Places ()


                if FS.Type == 'Knob' or FS.Type == 'Drag' or FS.Type == 'Slider' then

                    if not FX[FxGUID][LE.Sel_Items[1]].V_Round then
                        local _, FormatV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                            FX[FxGUID][LE.Sel_Items[1]].Num)
                        local _, LastNum = FormatV:find('^.*()%d')
                        local dcm = FormatV:find('%.')
                        if dcm then
                            rd = LastNum - dcm
                        end
                    end 
                    im.SetNextItemWidth(ctx, 80)
                    local Edit, rd = im.InputInt(ctx, '##EditValueDecimals' .. FxGUID .. (LE.Sel_Items[1] or ''), FS.V_Round or rd, 1)
                    if Edit then
                        for i, v in pairs(LE.Sel_Items) do
                            FX[FxGUID][v].V_Round = math.max( rd, 0)
                        end
                    end
                end
            end
            local function Font_Choice (Var, Italic, Bold)

                im.SetNextItemWidth(ctx, 100)
                if im.BeginCombo(ctx, '##' ..Var .. LE.Sel_Items[1], FS[Var]) then 
                    for I, V in ipairs(FONT_CHOICES) do
                        im.PushFont(ctx, _G[V])
                        if im.Selectable(ctx, V) then
                            ToAllSelItm(Var, V, FxGUID)
                            
                        end
                        im.PopFont(ctx)
                    end
                    im.EndCombo(ctx)
                end

            end

            local function Italic_or_Bold(Var, Font, which)
                if im.Checkbox(ctx, '##'..Var .. LE.Sel_Items[1], FS[Var]) then 
                    ToAllSelItm(Var, toggle(FS[Var]), FxGUID)
                end
            end

            local function Value_Clr()

                local DragV_Clr_edited, Drag_V_Clr = im.ColorEdit4(ctx, '##V  Clr' .. LE.Sel_Items[1], FS.V_Clr or im.GetColor(ctx, im.Col_Text), im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                if DragV_Clr_edited then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = Drag_V_Clr end
                end

            end



            im.NewLine(ctx)
            if im.BeginTable(ctx, 'Labels and Values', 11,flags, -R_ofs) then 
                im.TableSetupColumn(ctx, '', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Pos',im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'X', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Y', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Color', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Color 2', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Size', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Font')
                im.TableSetupColumn(ctx, 'Italic',im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Bold',im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, 'Decimal')
                im.TableHeadersRow(ctx)
                im.TableNextRow(ctx)

                im.TableSetColumnIndex(ctx, 0 ) 
                im.Text(ctx, 'Label')
                im.TableSetColumnIndex(ctx, 1 )
                Label_Pos()
                im.TableSetColumnIndex(ctx, 2 )
                Label_X_Pos()
                im.TableSetColumnIndex(ctx, 3 )
                Label_Y_Pos()
                im.TableSetColumnIndex(ctx, 4 )
                ColorChooser('##Lbl Clr', 'Lbl_Clr')
                im.TableSetColumnIndex(ctx, 5 )
                ColorChooser('##Lbl Clr  at full', 'Lbl_Clr_At_Full', true )
                im.TableSetColumnIndex(ctx, 6 )
                Label_Font_Size()
                im.TableSetColumnIndex(ctx, 7 )
                Font_Choice ('Lbl_FONT','Lbl_Italic', 'Lbl_Bold')
                im.TableSetColumnIndex(ctx, 8 )
                Italic_or_Bold('Lbl_Italic', 'Lbl_FONT')
                im.TableSetColumnIndex(ctx, 9 )
                Italic_or_Bold('Lbl_Bold', 'Lbl_FONT')


                im.TableNextRow(ctx)
                im.TableSetColumnIndex(ctx, 0 ) 
                im.Text(ctx, 'Value')
                im.TableSetColumnIndex(ctx,1 ) 
                Value_Pos()
                im.TableSetColumnIndex(ctx,2 ) 
                Value_Pos_X()
                im.TableSetColumnIndex(ctx,3 ) 
                Value_Pos_Y()   

                im.TableSetColumnIndex(ctx,4)
                ColorChooser('##Value Clr', 'V_Clr')
                im.TableSetColumnIndex(ctx,5)
                ColorChooser('##Value Clr at full', 'V_Clr_At_Full', true)


                im.TableSetColumnIndex(ctx, 6 )
                Value_Font_Size()
                im.TableSetColumnIndex(ctx, 7 )
                Font_Choice ('Val_FONT', 'Val_Italic', 'Val_Bold')
                im.TableSetColumnIndex(ctx, 8 )
                Italic_or_Bold('Val_Italic')
                im.TableSetColumnIndex(ctx, 9 )
                Italic_or_Bold('Val_Bold')


                im.TableSetColumnIndex(ctx, 10 )

                Value_Decimal_Places ()
                im.EndTable(ctx)
            end
        end

        local function Width_Height_PosX_PosY_Table()
                

            local function Width ()
                im.SetNextItemWidth(ctx, -FLT_MIN)

                local DefaultW, MaxW, MinW = Get_Default_Param_Width_By_Type(FS.Type)
                local DragSpeed = 5
                local _, W = im.DragDouble(ctx, '##EditWidth' .. FxGUID .. (LE.Sel_Items[1] or ''), FX[FxGUID][LE.Sel_Items[1] or ''].Sldr_W or DefaultW, LE.GridSize / 4, MinW, MaxW, '%.1f')

                if im.IsItemEdited(ctx) then
                    for i, v in pairs(LE.Sel_Items) do
                        Sync_Size_Height_Synced_Properties(FX[FxGUID][v], W - (FX[FxGUID][v].Sldr_W or 0))
                        FX[FxGUID][v].Sldr_W = W
                    end
                end
            end
            local function Height()

                if FS.Type ~= 'Knob' then

                    local max, defaultH
                    if FS.Type == 'V-Slider' then
                        max = 200
                        defaultH = Df.V_Sldr_H
                    end
                    im.SetNextItemWidth(ctx, -FLT_MIN)
                    local _, W = im.DragDouble(ctx, '##Height' .. FxGUID .. (LE.Sel_Items[1] or ''), FX[FxGUID][LE.Sel_Items[1] or ''].Height or Df.Sldr_H , LE.GridSize / 4, -5, max or 40, '%.1f')
                    if im.IsItemEdited(ctx) then
                        for i, v in pairs(LE.Sel_Items) do
                            local w = FX[FxGUID][LE.Sel_Items[1] or ''].Height or defaultH or Df.Sldr_H
                            Sync_Height_Synced_Properties(FX[FxGUID][v], W-w)

                            FX[FxGUID][v].Height = W


                        end
                    end
                end
            end

                
            local function Pos_X()
                im.SetNextItemWidth(ctx, -FLT_MIN)

                local EditPosX, PosX = im.DragDouble(ctx, ' ##EditPosX' .. FxGUID .. LE.Sel_Items[1], PosX or FS.PosX, LE.GridSize, 0, Win_W - 10, '%.0f')
                if EditPosX then
                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosX = PosX end
                end
            end
            local function Pos_Y ()
                im.SetNextItemWidth(ctx, -FLT_MIN)
                
                local EditPosY, PosY = im.DragDouble(ctx, ' ##EditPosY' .. FxGUID .. LE.Sel_Items[1], PosY or FS.PosY, LE.GridSize, 20, 210, '%.0f')
                if EditPosY then for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosY = PosY end end
            end
            


            if im.BeginTable(ctx, 'Width Height and Pos', 4,flags, -R_ofs) then
                im.TableSetupColumn(ctx, 'Width')
                im.TableSetupColumn(ctx, 'Height')
                im.TableSetupColumn(ctx, 'X Pos')
                im.TableSetupColumn(ctx, 'Y Pos')
            

                im.TableHeadersRow(ctx)
                im.TableNextRow(ctx)
                im.TableSetColumnIndex(ctx, 0 ) 
                Width()
                im.TableSetColumnIndex(ctx, 1) 
                Height()
                im.TableSetColumnIndex(ctx, 2) 

                Pos_X()
                im.TableSetColumnIndex(ctx, 3) 
                Pos_Y()



                im.EndTable(ctx)
            end

        end
        


        local function Switch_Type()


            if FS.Type == 'Switch' then
                local Momentary, Toggle
                if FS.SwitchType == 'Momentary' then
                    Momentary = true
                else
                    Toggle = true
                end
                EdT, Tg = im.Checkbox(ctx, 'Toggle##' .. FxGUID .. LE.Sel_Items[1],
                    Toggle)
                SL(nil, 20)
                EdM, Mt = im.Checkbox(ctx, 'Momentary##' .. FxGUID .. LE.Sel_Items[1],Momentary)
                if EdT then
                    for i, v in pairs(LE.Sel_Items) do
                        FX[FxGUID][v].SwitchType = 'Toggle'
                    end
                elseif EdM then
                    for i, v in pairs(LE.Sel_Items) do
                        FX[FxGUID][v].SwitchType =
                        'Momentary'
                    end
                end
                SL(nil, 30)
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
                SL()
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
        end


        local function Drag_Direction()
            if FS.Type == 'Drag' then
                
                if im.BeginCombo(ctx, '## Drag Dir' .. LE.Sel_Items[1], FS.DragDir or '', im.ComboFlags_NoArrowButton) then
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
        end

    

        local function Manual_Values()
            if FS.Type == 'Selection' then --im.Text(ctx,'Edit Values Manually: ') ;im.SameLine(ctx)
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
        end
        

        function ToAllSelItm(idx, Val)
            for i, v in ipairs(LE.Sel_Items) do
                FX[FxGUID][v][idx] = Val
            end
        end

        function Style_Search_Bar(filter, filterTxt)
            im.AlignTextToFramePadding(ctx)

            im.Text(ctx, 'Search : ')SL()


            if im.TextFilter_Draw(filter , ctx, '##StyleWinFilterTxt', 300 ) then
                filterTxt = im.TextFilter_Get(filter)
                im.TextFilter_Set(filter, filterTxt)
            end
            if im.IsWindowAppearing(ctx) then
                im.SetKeyboardFocusHere(ctx)
            end
            SL()
            im.InvisibleButton(ctx, 'dummy' , 20,20)
            
            im.Separator(ctx)

        end
        function Get_Attach_Drawing_Styles()
            local type = FS.Type or FX[FxGUID].DefType or 'Slider'

            if im.IsWindowAppearing(ctx) and type then

                local Dir = CurrentDirectory .. 'src/Layout Editor Item Styles/'..(type)
                local files = scandir(Dir)
                LE.DrawingStyles =  { [type] = {} }

                if files then 
                    for i, v in ipairs(files) do 

                        local file_path = ConcatPath(Dir, v)
                        local file = io.open(file_path, 'r')
                        local Ct = file:read('*a')

                        if LE.DrawingStyles then 
                            LE.DrawingStyles[type][i] = LE.DrawingStyles[type][i] or {}
                            LE.DrawingStyles[type][i].Draw = {}
                            LE.DrawingStyles[type][i].Name = string.sub(v, 1, -5 )
                            LE.DrawingStyles[type][i].Draw = Retrieve_Attached_Drawings(Ct, nil, LE.DrawingStyles[type][i].Draw)
                        end
                    end
                end
            end
        end

        function Add_Attach_Drawing_Styles(StyleWinFilter)


            local function Size_Synced_Properties(FP,DrawingStylesTB, func)
                if FP.Type == 'Knob' or (not FP.Type and FX[FxGUID].DefType == 'Knob') then 
                    --set size to 15, and sync all drawing size
                    local orig_sz = (FP.Sldr_W and FP.Sldr_W~= Df.KnobRadius) and  FP.Sldr_W 
                    FP.Sldr_W = Df.KnobRadius

                    func()
                    -- set size back to original size
                    FP.Sldr_W = orig_sz
                    if orig_sz then 
                        Sync_Size_Height_Synced_Properties(FP, orig_sz- Df.KnobRadius )
                    end
                    FP.Chosen_Atch_Draw_Preset = DrawingStylesTB.Name
                else

                    local DfH =  FP.Type == 'V-Slider'  and Df.V_Sldr_H or Df.Sldr_H
                    local DfW =  FP.Type == 'V-Slider'  and Df.V_Sldr_W or Df.Sldr_W
                        

                    local orig_h = FP.Height or DfH
                    local orig_sz = FP.Sldr_W or DfW

                    FP.Height = DfH
                    FP.Sldr_W = DfW

                    func()

                    FP.Sldr_W = orig_sz
                    FP.Height = orig_h
                    Sync_Height_Synced_Properties(FP, orig_h - DfH)

                    if FP.Type == 'V-Slider' then
                        Sync_Size_Height_Synced_Properties(FP, orig_sz - Df.V_Sldr_W)
                    else
                        Sync_Size_Height_Synced_Properties(FP, orig_sz - Df.Sldr_W)
                    end
                    
                    FP.Chosen_Atch_Draw_Preset = DrawingStylesTB.Name
                end
            end

            local function Set_Style_To_Selected_Itm (Sel_Itms,DrawingStylesTB)
                if HighlightHvredItem() then
                    for i, V in ipairs(Sel_Itms) do 
                        local FP = FX[FxGUID][V]
                        local function SyncTB()
                            FP.Draw = DrawingStylesTB.Draw
                        end
                        Size_Synced_Properties(FP,DrawingStylesTB, SyncTB)
                    end
                    ToAllSelItm('Invisible', true)
                    im.CloseCurrentPopup(ctx)
                end
            end

            local function Add_Default_Selection_Styles()
                if FS.Type == 'Selection' then
                    local function SetStyle(Name, Style, Width, CustomLbl)
                        AddCombo(ctx, LT_Track, FX_Idx, Name .. '##' .. FS.Name, FS.Num, Options, Width, Style, FxGUID, 0, OptionValues, 'Options', CustomLbl)
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
            end

            local function Add_Plus_Button(i, H, TB, FxGUID,Sel_Itms)
                local WinSz = im.GetWindowSize(ctx)
                local CurX = im.GetCursorPosX(ctx)
                SL(CurX + WinSz - H *2.5)
                im.PushFont(ctx, Font_Andale_Mono_20_B)
                if im.Button(ctx, '+##'..i, H,H) then 
                    
                    for i, V in ipairs(Sel_Itms) do 
                        local FP = FX[FxGUID][V]
                        FP.Draw = FP.Draw or {}
                        local function Append()
                            table.insert(FP.Draw, TB.Draw)
                            FP.Draw[#FP.Draw].Belong_To_Preset = TB.Name
                        end
                        Size_Synced_Properties(FP,TB, Append)
                    end
                end
                im.PopFont(ctx)
            end

            local function Add_Trash_Button(i, H, TB, type)
                SL()
                local rv, Clr = TrashIcon(H-5, '##Delete Drawing Picture File'..i , nil,_G['Delete Drawing Icon'..i])
                _G['Delete Drawing Icon'..i] = Clr 


                if rv then 
                    im.OpenPopup(ctx, 'Confirm Deleting '.. TB.Name)
                    local x, y = im.GetMousePos(ctx)
                    im.SetNextWindowPos(ctx,x,y)
                end      
                

            end
            local function Confirm_Delete_Preset(TB, type,i)

                
                if im.BeginPopupModal(ctx, 'Confirm Deleting '.. TB.Name , true , im.WindowFlags_NoDecoration|im.WindowFlags_AlwaysAutoResize) then
                    im.Text(ctx, 'Are you sure you want to Delete ' )
                    SL()
                    MyText(TB.Name,nil, ThemeClr('Accent_Clr'))
                    SL()
                    im.Text(ctx, '?' )
                    im.Separator(ctx)
                    MyText('!!', nil, 0xEC0000ff) SL()
                    MyText( 'This Action CANNOT be undone',nil, 0xEC000099) SL()
                    MyText('!!', nil, 0xEC0000ff) 
                    im.Separator(ctx)


                    if im.Button(ctx,'Yes (Enter)') or im.IsKeyPressed(ctx,im.Key_Enter) then 
                        local path = ConcatPath(CurrentDirectory , 'src', 'Layout Editor Item Styles',  type , TB.Name..'.ini')
                        os.remove(path)    
                        table.remove(LE.DrawingStyles[FS.Type], i)
                        im.CloseCurrentPopup(ctx)
                    end
                    SL(nil,20)
                    if im.Button(ctx, 'No (Esc)') or im.IsKeyPressed(ctx,im.Key_Escape) then  
            
                        im.CloseCurrentPopup(ctx)
                    end 
                    im.EndPopup(ctx)
                end

            end

            local function Add_Default_Knob_Styles()

                -- add attached drawings
                if FS.Type == 'Knob' or (not FS.Type and FX[FxGUID].DefType == 'Knob') then 
                    
                    for i, v in ipairs(LE.DrawingStyles[FS.Type])do 
                        if im.TextFilter_PassFilter(StyleWinFilter, v.Name) then
                            im.BeginGroup(ctx)
                            local pos = {im.GetCursorScreenPos(ctx)}
                            AddKnob(ctx, '##' .. FS.Name, '', FS.V, 0, 1, 0, FX_Idx, FS.Num, 'Invisible', 15, 0, Disabled, 12, Lbl_Pos, V_Pos, Img)
                            local w, h = im.GetItemRectSize(ctx)
                            Draw_Attached_Drawings(v,FX_Idx, pos , FS.V, FS.Type, FxGUID)
                            SL(nil, 50)

                            im.Text(ctx, v.Name)
                            im.EndGroup(ctx)
                            Set_Style_To_Selected_Itm (LE.Sel_Items,v)
                            Add_Plus_Button(i, h, v, FxGUID,LE.Sel_Items)
                            Add_Trash_Button(i, h, v, FS.Type)
                            im.Separator(ctx)
                            
                        end
                        Confirm_Delete_Preset(v, FS.Type,i)
                    end   
                end 
            end
            local function Add_Style_Previews(func, width, spacing, BtnSz)
                if not LE.DrawingStyles then return end 
                if not LE.DrawingStyles[FS.Type] then return end 
                for i, v in ipairs(LE.DrawingStyles[FS.Type])do 
                    if im.TextFilter_PassFilter(StyleWinFilter, v.Name) then
                        im.BeginGroup(ctx)
                        AddSpacing(spacing or 5)   

                        local pos = {im.GetCursorScreenPos(ctx)}
                        im.BeginDisabled(ctx)
                        func()
                        im.EndDisabled(ctx)
                        local w, h = im.GetItemRectSize(ctx)
                        Draw_Attached_Drawings(v,FX_Idx, pos , FS.V, FS.Type, FxGUID)
                        SL(nil, (width or 50) )
                        im.AlignTextToFramePadding(ctx)

                        im.Text(ctx, v.Name)

                        im.EndGroup(ctx)

                        Set_Style_To_Selected_Itm (LE.Sel_Items,v)
                        local W,H = im.GetItemRectSize(ctx)
                        local sz = BtnSz and BtnSz or H
                        Add_Plus_Button(i, sz, v, FxGUID,LE.Sel_Items)
                        Add_Trash_Button(i, sz, v, FS.Type)
                        im.Separator(ctx)
                        --AddSpacing(spacing or 5)
                    end
                    Confirm_Delete_Preset(v,FS.Type,i)
                end
            end
            

            Add_Default_Selection_Styles()
            Add_Default_Knob_Styles()
            if FS.Type == 'Drag' or (not FS.Type and FX[FxGUID].DefType == 'Drag') then 
                local function Add_Drag()
                    AddDrag(ctx, '##' , FS.Name, FS.V, 0, 1, FItm, FX_Idx, FS.Num, nil, Df.Sldr_W,0, nil,nil,FS.Lbl_Pos,FS.V_Pos ,nil,nil,Df.Sldr_H)
                end

                Add_Style_Previews(Add_Drag)
            elseif  FS.Type == 'V-Slider' or (not FS.Type and FX[FxGUID].DefType == 'V-Slider') then 
                local function Add_V_Slider()
                    local sliderHeight = FS.Height or Df.V_Sldr_H
                    im.InvisibleButton(ctx, 'V-Slider Test ', Df.V_Sldr_W , sliderHeight)
                end
                Add_Style_Previews(Add_V_Slider,100,nil, 30)
            elseif FS.Type == 'Slider' or (not FS.Type and FX[FxGUID].DefType == 'Slider') then 
                local function Add_Slider()
                    im.InvisibleButton(ctx, 'Slider Test ', Df.Sldr_W , Df.Sldr_H)
                end
                Add_Style_Previews(Add_Slider, 0, 2)
            elseif FS.Type =='Switch' then 
                local function Switch()
                    AddSwitch(LT_Track, FX_Idx, FS.V, FS.Num, FS.Clr, nil,FItm, nil,nil,FxGUID)
                end
                Add_Style_Previews(Switch)

            elseif FS.Type =='Selection' then 
                local function Combo()
                    AddCombo(ctx, LT_Track, FX_Idx, FS.Name, FS.Num, nil, nil, nil, FxGUID, 0)
                end
                Add_Style_Previews(Combo)

            end 
        end


        local function Style()
            --- Style ------
            --[[ im.Text(ctx, 'Style: '); im.SameLine(ctx)
            w = im.CalcTextSize(ctx, 'Style: ') ]]
            local stylename  = FS.Style == 'Pro C'  and    'Minimalistic'  or FS.Style
            local stylename = stylename == '' and 'Default' or stylename
            if not (FS.Type == 'Knob' or FS.Type =='Switch') then im.BeginDisabled(ctx)end 

            if im.Button(ctx, (stylename or 'Choose Style') .. '##' .. (LE.Sel_Items[1] or 'Style'), 130) then
                im.OpenPopup(ctx, 'Choose style window')
            end
            if not (FS.Type == 'Knob' or FS.Type =='Switch') then im.EndDisabled(ctx)end 


            if not im.BeginPopup(ctx, 'Choose style window') then return end 
            --local StyleWinImg, StyleWinImgName = StyleWinImg or {} , StyleWinImgName or {}
            local FS = FS

            local function setItmStyle(Style, img, ImgPath)
                for i, v in pairs(LE.Sel_Items) do
                    FX[FxGUID][v].Style = Style;
                    if img then
                        FX[FxGUID][v].Image = img

                        FX[FxGUID][v].ImgFilesName = TruncatePath(ImgPath)
                    else
                        FX[FxGUID][v].ImgFilesName = nil
                    end

                    im.CloseCurrentPopup(ctx)
                end
            end

            if not im.ValidatePtr(StyleWinFilter, "ImGui_TextFilter*") then
                StyleWinFilter = im.CreateTextFilter(FilterText)
            end
            


            local function SetStyle(Name, Style, Img, ImgFilesName, func, ...)
                if im.TextFilter_PassFilter(StyleWinFilter, Name) then
                    im.BeginGroup(ctx)

                    func(...)
                    SL()
                    im.Text(ctx, Name)
                    im.EndGroup(ctx)
                    if HighlightHvredItem() then --if clicked on highlighted itm
                        setItmStyle(Style, Img, ImgFilesName)
                        im.CloseCurrentPopup(ctx)
                    end
                    
                    im.Separator(ctx)
                end
            end
            local function Add_Image_Styles(type, func)

                local Dir = CurrentDirectory .. 'src/Images/'..type
                if im.IsWindowAppearing(ctx) then 
                    StyleWinImg = {}
                    StyleWinImgName = {}
                    StyleWindowImgFiles = scandir(Dir)
                    if StyleWindowImgFiles then
                        for i, v in ipairs(StyleWindowImgFiles) do
                            if v ~= '.DS_Store' then
                                
                                if not StyleWinImg[i] then 
                                    StyleWinImg[i] = im.CreateImage(Dir .. '/' .. v)
                                    im.Attach(ctx, StyleWinImg[i])
                                    StyleWinImgName[i] = v
                                end
                            end
                        end
                    end
                end

                func()
                
            end

            local function Styles_For_Knobs()
                    -- if all selected itms are knobs
                if FS.Type == 'Knob' or (not FS.Type and FX[FxGUID].DefType == 'Knob') then 


                    im.BeginDisabled(ctx)
                    im.SeparatorText(ctx, 'Native')

                    SetStyle('Default', '',nil,nil, AddKnob, ctx, '##' .. FS.V, '', 0, 0, 1, 0, FX_Idx, FS.Num, 'Default', 15, 0, Disabled, 12, Lbl_Pos, V_Pos)
                    SetStyle('Minimalistic', 'Pro C', nil,nil, AddKnob, ctx, '##' .. FS.V, '', 0, 0, 1, 0, FX_Idx, FS.Num, 'Pro C', 15, 0, Disabled, 12, Lbl_Pos, V_Pos)

                    local function Add_Image_STYLE ()
                        im.SeparatorText(ctx, 'Images')

                        for i, v in pairs(StyleWinImg) do
                            local Dir = '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/Knobs/' 
                            SetStyle(StyleWinImgName[i], 'Custom Image', v, Dir .. StyleWinImgName[i], AddKnob, ctx, '##' .. FS.V, '', 0, 0, 1, 0, FX_Idx, FS.Num, 'Custom Image', 15, 0, Disabled, 12, Lbl_Pos, V_Pos, v)
                        end
                    end

                    Add_Image_Styles('Knobs',Add_Image_STYLE)
                    im.EndDisabled(ctx)
                    
                end
            end

            local function Image_Styles_For_Switches()
                if FS.Type == 'Switch' or (not FS.Type and FX[FxGUID].DefType == 'Switch') then 
                    local function Add_Image_STYLE ()
                        im.SeparatorText(ctx, 'Images')
                        for i, v in pairs(StyleWinImg) do
                            local Dir = '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/Switches/' 

                            SetStyle(StyleWinImgName[i], 'Custom Image', v, Dir .. StyleWinImgName[i], AddSwitch, LT_Track, FX_Idx, FS.V, FS.Num, FS.Clr, nil, 0, nil,nil,FxGUID, v)
                        end
                    end
                    Add_Image_Styles ('Switches', Add_Image_STYLE)
                end
            end

            --Get_Attach_Drawing_Styles()
            Style_Search_Bar(StyleWinFilter, FilterText)
            im.BeginChild(ctx,'Main', 500, 500)

            Styles_For_Knobs()
            Image_Styles_For_Switches()

            im.EndChild(ctx)
            im.EndPopup(ctx)

        end
        
        local function Invisible()
            local Edit = im.Checkbox(ctx, '##Invisible' .. FxGUID .. (LE.Sel_Items[1] or ''), FS.Invisible or nil)
            if Edit then
                for i, v in pairs(LE.Sel_Items) do
                    FX[FxGUID][v].Invisible = toggle(FX[FxGUID][v].Invisible)
                end
            end
        end
        


        local function Custom_Image()
            
            if FS.Type ~= 'Knob' and FS.Type ~= 'Switch' then return end 
            local function Angle_Settings()

                if not FS.Image or not FS.Type =='Knob' then return end 
                local w, h = im.Image_GetSize(FS.Image)

                if  (h > w * 5) then return end -- if it's a single image and not a strip 
                if im.Checkbox(ctx, 'Dont Rotate with value', FS.DontRotateImg) then 
                    ToAllSelItm('DontRotateImg', toggle(FS.DontRotateImg))
                end
                SL(nil, 30 )
                im.SetNextItemWidth(ctx, 70)
                _, FS.ImgAngleMinOfs = im.DragDouble(ctx, 'angle min offset', FS.ImgAngleMinOfs or 0 , 0.01, 0, 6.28 )
            
            end
            local rv
            DragDropPics = DragDropPics or {}
            if FS.ImgFilesName then 
                local rv, hvr = TrashIcon(16, 'Clear', ClrBG, FS.ImgTrashTint)
                FS.ImgTrashTint = hvr

                if rv then
                    ToAllSelItm('Style', nil)
                    ToAllSelItm('ImgFilesName', nil)
                    ToAllSelItm('Image', nil)
                end
            end
            
            SL()
            im.Text(ctx, 'Image Path: ') SL()

            if im.BeginChild(ctx, '##drop_files', -R_ofs, 20) then
                if not FS.ImgFilesName then
                    im.TextColored(ctx , 0xffffff88,'Drag and drop files here...')
                else
                    --FS.Style = 'Custom Image'
                    
                    im.Text(ctx, TruncatePath( FS.ImgFilesName))
                end

                im.EndChild(ctx)
            end

            if im.BeginDragDropTarget(ctx) then
                local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                if rv then
                    for i = 0, count - 1 do
                        local rv, filename = im.GetDragDropPayloadFile(ctx, i)
                        if rv then
                            ToAllSelItm('Style', 'Custom Image')


                            if FS.Type == 'Knob' then
                                AbsPath, FS.ImgFilesName = CopyImageFile(filename, 'Knobs')
                            elseif FS.Type == 'Switch' then
                                AbsPath, FS.ImgFilesName = CopyImageFile(filename, 'Switches')
                            elseif FS.Type then 
                                AbsPath, FS.ImgFilesName = CopyImageFile(filename, FS.Type)
                            end
                            ToAllSelItm('Image', im.CreateImage(AbsPath))
                        end

                    end
                end
                im.EndDragDropTarget(ctx)
            end
        

            Angle_Settings()
        end


        

        
        local function Colors()

            ClrEdited, PrmBgClr = im.ColorEdit4(ctx, '##Clr' .. ID,
                FS.BgClr or im.GetColor(ctx, im.Col_FrameBg),
                im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                im.ColorEditFlags_AlphaBar)
            if not FX[FxGUID][LE.Sel_Items[1]].BgClr or FX[FxGUID][LE.Sel_Items[1]] == im.GetColor(ctx, im.Col_FrameBg) then
                HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                    'GetItemRect')
            end
            if ClrEdited then
                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].BgClr = PrmBgClr end
            end


        end


        local function Value_Colors()

            if FS.Type ~= 'Switch' and FS.Type ~= 'Selection' then

                GrbClrEdited, GrbClr = im.ColorEdit4(ctx, '##GrbClr' .. ID, FS.GrbClr or im.GetColor(ctx, im.Col_SliderGrab), im.ColorEditFlags_NoInputs|    r .ImGui_ColorEditFlags_AlphaPreviewHalf()| im.ColorEditFlags_AlphaBar)
                if not FX[FxGUID][LE.Sel_Items[1]].GrbClr or FX[FxGUID][LE.Sel_Items[1]].GrbClr == im.GetColor(ctx, im.Col_SliderGrab) then
                    HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect')
                end
                if GrbClrEdited then
                    for i, v in pairs(LE.Sel_Items) do
                        FX[FxGUID][v].GrbClr = GrbClr
                    end
                end
            end

        end




        local function Conditional_Prms()
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
                        FS[ShowCondition] = nil
                        DeleteAllConditionPrmV = nil
                    end
                end

                if im.IsItemHovered(ctx) then
                    tooltip( 'Alt-Click to Delete All Conditions')
                end



                if FS[ShowCondition] or FX[FxGUID][P][ConditionPrm] then
                    SL()
                    if not FX[FxGUID][P][ConditionPrm_PID] then
                        for i, v in ipairs(FX[FxGUID]) do
                            if FX[FxGUID][i].Num == FS[ConditionPrm] then
                                FS[ConditionPrm_PID] = i
                            end
                        end
                    end
                    local PID = FX[FxGUID][P][ConditionPrm_PID] or 1

                    if im.Button(ctx, 'Parameter:##' .. ConditionPrm) then
                        FX[FxGUID][P].ConditionPrm = LT_ParamNum
                        local found
                        for i, v in ipairs(FX[FxGUID]) do
                            if FX[FxGUID][i].Num == LT_ParamNum then
                                FS[ConditionPrm_PID] = i
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
                            if FX[FxGUID][i].Num == FS[ConditionPrm] then
                                FS[ConditionPrm_PID] =i
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
                        Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx, 'ConditionPrm' .. FP.ConditionPrm .. (PrmName or '') .. '1## CP', FX[FxGUID][P][ConditionPrm] or 0, FX[FxGUID][PID].ManualValuesFormat or 'Get Options', -R_ofs, Style, FxGUID, PID, FX[FxGUID][PID].ManualValues, FX[FxGUID][P][ConditionPrm_V][1] or 'Unassigned', nil, 'No Lbl')

                        if Value_Selected then
                            for i, v in pairs(LE.Sel_Items) do
                                FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v] [ConditionPrm_V] or {}
                                FX[FxGUID][v][ConditionPrm_V_Norm] = FX[FxGUID][v] [ConditionPrm_V_Norm] or {}
                                FX[FxGUID][v][ConditionPrm_V][1] = V_Formatted
                                FX[FxGUID][v][ConditionPrm_V_Norm][1] = r .TrackFX_GetParamNormalized(LT_Track, FX_Idx, fp[ConditionPrm])
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
                                        local Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx, 'CondPrmV' .. (PrmName or '') .. v .. ConditionPrm, FX[FxGUID][P][ConditionPrm] or 0, FX[FxGUID][PID].ManualValuesFormat or 'Get Options', -R_ofs, Style, FxGUID, PID, FX[FxGUID][PID].ManualValues, v, nil, 'No Lbl')
                                        if Value_Selected then
                                            for I, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v][ConditionPrm_V][i] = V_Formatted
                                                FX[FxGUID][v][ConditionPrm_V_Norm][i] = r .TrackFX_GetParamNormalized(LT_Track, FX_Idx, FX[FxGUID][P][ConditionPrm])
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if im.Button(ctx, ' + or at value:##' .. ConditionPrm) then
                            FX[FxGUID][P][ConditionPrm_V] = FX[FxGUID][P] [ConditionPrm_V] or {}
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
                if FS.ConditionPrm then
                    Condition('ConditionPrm2', 'ConditionPrm_PID2', 'ConditionPrm_V2', 'ConditionPrm_V_Norm2', 'And if:', 'ShowCondition2')
                end
                if FS.ConditionPrm2 then
                    Condition('ConditionPrm3', 'ConditionPrm_PID3', 'ConditionPrm_V3', 'ConditionPrm_V_Norm3', 'And if:', 'ShowCondition3') end
                if FS.ConditionPrm3 then
                    Condition('ConditionPrm4', 'ConditionPrm_PID4', 'ConditionPrm_V4', 'ConditionPrm_V_Norm4', 'And if:', 'ShowCondition4')
                end
                if FS.ConditionPrm4 then
                    Condition('ConditionPrm5', 'ConditionPrm_PID5', 'ConditionPrm_V5', 'ConditionPrm_V_Norm5', 'And if:', 'ShowCondition5')
                end
                im.TreePop(ctx)
            end
        end


        local function Attach_Drawings()

            local function Preset()
                SL(nil, 40)
                im.Text(ctx,'Preset: ')SL()
                im.SetNextItemWidth(ctx, 180)
                if im.BeginCombo(ctx, '##atttached drawings preset', FS.Chosen_Atch_Draw_Preset or 'Choose Preset', im.ComboFlags_HeightLarge)then 
                    if not im.ValidatePtr(AtchDraw_Preset_Filter, "ImGui_TextFilter*") then
                        AtchDraw_Preset_Filter = im.CreateTextFilter(AtchDraw_Preset_FilterTxt)
                    end
                    Style_Search_Bar(AtchDraw_Preset_Filter)
                    Get_Attach_Drawing_Styles()
                    Add_Attach_Drawing_Styles(AtchDraw_Preset_Filter)
                    im.EndCombo(ctx)
                end 
            end 

            local function Attach_New_Drawing_Btn()
                if im.Button(ctx, 'attach a new drawing') then
                    table.insert(FS.Draw, {})
                end
            end

            local function Save_As_Style_Btn()
                if im.Button(ctx, 'Save as a '..(FS.Type or ' ').. ' style') then 
                    im.OpenPopup(ctx, 'Enter name for the style:')
                    local x , y = im.GetCursorScreenPos(ctx)
                    im.SetNextWindowPos(ctx, x ,y )
                    im.SetNextWindowSize(ctx, 200, 100  )
                end
            end


            local openTree = im.TreeNode(ctx, 'Attach Drawing')

            Preset()
            if FS.Draw and #FS.Draw >0 then 
                SL()
                MyText('('..#FS.Draw ..' Drawings )', nil, ThemeClr('Accent_Clr'))
            end

            if im.BeginPopupModal(ctx, 'Enter name for the style:') then
                EnterNewName, NewName = im.InputText(ctx, '## Style Name', NewName, im.InputTextFlags_EnterReturnsTrue)
                SL()
                if  EnterNewName then 
                    Save_Attached_Drawings_As_Style(NewName, FS.Type, FS)
                    im.CloseCurrentPopup(ctx)
                    Tooltip.Txt, Tooltip.Dur,  Tooltip.time = 'Saved Successfully', 60 , 0
                end
                if im.IsKeyPressed(ctx,im.Key_Escape)then 
                    im.CloseCurrentPopup(ctx)
                    Tooltip.Txt, Tooltip.Dur,  Tooltip.time = 'Canceled', 60 , 0

                end
                im.EndPopup(ctx)
            end
            if  openTree then 

                Attach_New_Drawing_Btn() SL(nil, 30)
                Save_As_Style_Btn()
                local BeganChild = im.BeginChild(ctx, 'Attached Drawings',nil,nil,im.ChildFlags_AutoResizeY)
                FS.Draw = FS.Draw or {}
                --[[ if RemoveDraw then
                    table.remove(FS.Draw, RemoveDraw)
                    RemoveDraw = nil
                end ]]
                local ClrFLG = im.ColorEditFlags_NoInputs + im.ColorEditFlags_AlphaPreviewHalf + im.ColorEditFlags_NoLabel + im.ColorEditFlags_AlphaBar
                local function BypassBtn(D, i)
                    SL()
                    if im.Checkbox(ctx, 'Bypass##' .. i,D.Bypass) then
                        D.Bypass = toggle(D.Bypass)
                    end
                end
                local function DeleteBtn(i)
                    if im.Button(ctx, 'Delete##' .. i) then
                        table.remove(FS.Draw, i)
                    end
                end

                local function Allow_Drag_To_Reorder(i, D)
                    --[[ im.SmallButton( ctx, '-##'..i)
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

                    end  ]]

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
                            table.remove ( FS.Draw, tonumber(src))

                            table.insert(FS.Draw,  i, Reorder_Draw_Itm_SRC)
                            --[[ for I, v in pairs(Reorder_Draw_Itm_SRC) do
                                --D[I] = v
                                table.insert(D,I, v)
                            end ]]


                            --FS.Draw[i] = Reorder_Draw_Itm
                            Reorder_Draw_Itm_SRC=nil
                        end 
                        im.EndDragDropTarget(ctx)
                        return true
                    end
                end

                local function Drawing_Properties(v, i, Additional_LBL)


                    local D = v or FS.Draw[i]
                    local LBL =  FxGUID .. LE.Sel_Items[1] .. i .. (Additional_LBL or '')
                    local H = Glob.Height
                    local W = Win_W

                    im.AlignTextToFramePadding(ctx)

                    local function Enclose_In_Preset()
                        local last_item_in_preset = nil
                        for j = #FS.Draw, 1, -1 do
                            if FS.Draw[j].Belong_To_Preset == LAST_PRESET then
                                last_item_in_preset = j
                                break
                            end
                        end

                        --[[ if D.Belong_To_Preset and D.Belong_To_Preset ~= LAST_PRESET then 
                            
                            if im.TreeNode(ctx, 'Preset: ' .. D.Belong_To_Preset) then 
                                return true , D.Belong_To_Preset, last_item_in_preset
                            else 
                                return nil, D.Belong_To_Preset, last_item_in_preset
                            end
                        elseif D.Belong_To_Preset and  D.Belong_To_Preset == LAST_PRESET then 

                            return true, LAST_PRESET, last_item_in_preset

                        end ]]
                    end



                    local function Set_Property (prop, val, trigger)
                        if trigger then 
                            for I, v in ipairs(LE.Sel_Items) do 
                                D[prop] = val
                            end
                        end
                    end
                    local function ShowClrBtn()
                        SL(nil, 10)

                        local rv, Clr = im.ColorEdit4(ctx, 'Color' .. LBL, D.Clr or 0xffffffff, ClrFLG)
                        Set_Property ('Clr', Clr, rv)
                    end 

                    local function Duplicate_Btn()
                        if im.Button(ctx, 'Duplicate##' .. i) then
                            for I, v in ipairs(LE.Sel_Items) do 
                                local copy = deepCopy(D)
                                table.insert(FX[FxGUID][v].Draw, copy)
                            end
                        end
                    end

                    im.SetNextItemWidth(ctx, -FLT_MIN - Color_Palette_Width)
                    local Drawing_Tree = im.TreeNode(ctx, 'Drawing ' .. i.. ' - ## asdnjkasdn')
                    local Drop_Hover = Allow_Drag_To_Reorder(i, D)


                    ShowClrBtn()
                    SL()
                    im.SetNextItemWidth(ctx, 100)


                    if im.BeginCombo(ctx, '## Combo type' .. LBL, D.Type or '', im.ComboFlags_NoArrowButton) then
                        local function AddOption(str)
                            if im.Selectable(ctx, str, false) then
                                D.Type = str; D.T = str;
                            end
                        end
                        AddOption('Line')
                        AddOption('Rect')
                        AddOption('Circle')
                        AddOption('Image')

                        AddOption('Knob Pointer')
                        AddOption('Knob Range')
                        AddOption('Knob Circle')
                        AddOption('Knob Numbers')

                        AddOption('Knob Image')

                        AddOption('Gain Reduction Text')


                        im.EndCombo(ctx)
                    end
                    SL()


                    BypassBtn(D, i)

                    SL(nil, 10)
                    DeleteBtn( i )
                    SL(nil, 10)

                    Duplicate_Btn()

                    
                    if Drawing_Tree then
                        local function AddProp(ShownName, Name, width, sl, defaultV, stepSize, min, max, format)
                            if ShownName then
                                im.Text(ctx, ShownName)
                                SL()
                            end
                            if width then im.SetNextItemWidth(ctx, width) end
                            local FORMAT = format
                            if not D[Name] and not defaultV then FORMAT = '' end

                            local rv, V = im.DragDouble(ctx, '##' .. Name .. LBL, D[Name] or defaultV, stepSize or LE.GridSize, min or -W, max or W - 10, FORMAT)

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
                        local Gap = { 'Circle', 'Circle Filled', 'Knob Range', 'Rect'}
                        local BL_XYGap = { 'Knob Pointer', 'Knob Range', 'Knob Circle', 'Knob Circle Filled', 'Knob Image', 'Knob Numbers' }
                        local RadiusInOut = { 'Knob Pointer', 'Knob Range'}
                        local Radius = { 'Knob Circle', 'Knob Image','Knob Circle Filled' ,'Knob Numbers' } -- this = radius IN
                        local BL_Repeat = {  'Knob Image', 'Knob Pointer', 'Gain Reduction Text' }
                        local GR_Text = { 'Gain Reduction Text' }
                        local Fill = {'Circle', 'Knob Circle', 'Rect'}


                        local X_Gap_Shown_Name = 'X Gap:'
                        local DefW, DefH

                        local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize
                        local function Set_Property (prop, val, trigger)
                            if trigger then 
                                for I, v in ipairs(LE.Sel_Items) do 
                                    D[prop] = val
                                end
                            end
                        end

                        if D.Type == 'Image' or D.Type == 'Knob Image' then
                            local img, name =  Draw_Drop_Image_Module_With_Combo(D, 'Attached Drawings')
                            if img then 
                                for I, v in ipairs(LE.Sel_Items) do 
                                    FX[FxGUID][v].Draw[i].AtchImgFileNm = name
                                    FX[FxGUID][v].Draw[i].Image = img
                                end
                            --[[  Set_Property ('AtchImgFileNm', name, true)
                                Set_Property ('Image', img, true) ]]
--[[ 
                                D.AtchImgFileNm = name
                                D.Image = img ]]
                            end
                        end

                    

                        im.AlignTextToFramePadding(ctx)

                        local flags = im.TableFlags_SizingStretchProp |
                            im.TableFlags_Resizable |
                            im.TableFlags_BordersOuter |
                            im.TableFlags_BordersV |
                            im.TableFlags_ContextMenuInBody|
                            im.TableFlags_RowBg




                        if im.BeginTable(ctx, 'Attached Drawing Properties ##'.. i , 3, flags, -R_ofs) then
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
                            local BipolarSz = 100


                        
                            local function AddVal(Name, defaultV, stepSize, min, max, format, NextRow, WidthSyncBtn, Bipolar, Sz)
                                local Column = 1
                                if Name:find('_VA') then Column = 2 end
                                im.TableSetColumnIndex(ctx, Column)
                                local itmW = WidthSyncBtn and -WidthSyncBtnSz or Bipolar and BipolarSz or Sz or  -FLT_MIN

                                im.PushItemWidth(ctx, itmW)


                                local FORMAT = format
                                if not D[Name .. '_GR'] and not D[Name] and not defaultV then
                                    FORMAT = ''
                                end

                                local FORMAT = format =='percent' and  tostring((math.ceil(( D[Name] or defaultV )*100) )..' %%')   or FORMAT
                                local tweak_Drag, V = im.DragDouble(ctx, '##' .. Name .. LBL, D[Name .. '_GR'] or D[Name] or defaultV, stepSize or LE.GridSize, min or -W, max or W - 10, FORMAT)

                                im.PopItemWidth(ctx)

                                if tweak_Drag and not D[Name .. '_GR'] then
                                    for I, v in ipairs ( LE.Sel_Items) do 
                                        D[Name] =  V
                                    end 
                                    --[[ D[Name] = V ]]
                                elseif tweak_Drag and D[Name .. '_GR'] then
                                    D[Name .. '_GR'] = V; D[Name] = nil
                                end

                                if defaultV and not D[Name] then 
                                    D[Name] = V
                                end 

                                -- if want to show preview use this.
                                --if im.IsItemActive(ctx) then FS.ShowPreview = FS.Num end



                                if FS.ShowPreview and im.IsItemDeactivated(ctx) then FS.ShowPreview = nil end

                                if Name:find('_VA') then
                                    if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
                                        im.OpenPopup(ctx, 'Value afftect ' .. Name)
                                    end
                                end
                                if im.BeginPopup(ctx, 'Value afftect ' .. Name) then

                                    if im.Selectable(ctx, 'Set to Parameter width') then 
                                        for I, V in ipairs(LE.Sel_Items) do 

                                            W =FX[FxGUID][V].Sldr_W or Get_Default_Param_Width_By_Type(FX[FxGUID][V].Type)
                                            D[Name]= FX[FxGUID][V].Sldr_W

                                        end
                                    end


                                    
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

                                if Bipolar  then 
                                    SL()

                                    _ , D[Name..'_BP'] = im.Checkbox(ctx, 'Bipolar ##'..Name,  D[Name..'_BP'] or false) 
                                end

                                if Name:find('_VA') or NextRow then im.TableNextRow(ctx) end

                                return tweak_Drag
                            end
                            local function Special_Fill ()
                                if not D.Special_Fill or not D.Fill then return end
                                im.TableNextRow(ctx)
                                local AngleLBL = D.Special_Fill == 'Gradient' and 'Gradient Angle' or 'Texture Angle'
                                local GradientMax = D.Special_Fill == 'Gradient' and 1 or 15
                                if SetRowName(AngleLBL, nil, {'Circle'}) then
                                    AddVal('Texture_Angle', 0, 1, 0, 360, '%.f', true)
                                    
                                end

                                if SetRowName('Gradient Start', nil, {'Circle'}) then
                                    D.Gradient_Start = D.Gradient_Start or D.Special_Fill == 'Gradient' and 0 or 2.05
                                    AddVal('Gradient_Start', 0, 0.1, -1, GradientMax, '%.2f', true)
                                end

                                if SetRowName('Special Fill', nil, {'Circle'}) then

                                    im.TableSetColumnIndex(ctx, 1)
                                    D.Clr2 = D.Clr2 or 0x888888ff
                                    local rv, Clr2 = im.ColorEdit4(ctx, 'Color2' .. LBL, D.Clr2 or 0xffffffff, ClrFLG)
                                    Set_Property ('Clr2', Clr2, rv)

                                    if D.Repeat and D.Repeat ~= 0  then
                                        SL()
                                        im.Text(ctx, 'Start')
                                        SL(nil, 20)
                                        local rv, RptClr2 = im.ColorEdit4(ctx, 'Repeat Color2' .. LBL, D.RPT_Clr2 or 0xffffffff, ClrFLG)
                                        Set_Property ('RPT_Clr2', RptClr2, rv)
                                        SL()
                                        im.Text(ctx, 'End')
                                        SL()
                                        im.TableNextRow(ctx)

                                    end




                                    


                                    im.TableNextRow(ctx)

                                end
                            end

                            im.TableSetupColumn(ctx, '##')
                            im.TableSetupColumn(ctx, 'Values')
                            im.TableSetupColumn(ctx, 'Affected By Value')

                            im.TableNextRow(ctx, im.TableRowFlags_Headers)


                            local Win_W = FX[FxGUID].Width or DefaultWidth or 220


                            im.TableHeadersRow(ctx)

                            local Sz = FS.Sldr_W or 160

                            im.TableNextRow(ctx)

                            local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize
                            if D.Type and  D.Type:find('Circle')  then
                                WidthLBL = 'Size'; WidthStepSize = 1
                            end




                            SetRowName('X offset')
                            AddVal('X_Offset', 0, LE.GridSize, -Win_W, Win_W, nil)
                            TableColumn1W = im.GetItemRectSize(ctx)

                            AddVal('X_Offset_VA', nil,nil,nil,nil,nil,nil,nil, true)
                            SetRowName('Y offset')
                            AddVal('Y_Offset', 0, LE.GridSize, -220, 220, nil, nil, true)
                            AddVal('Y_Offset_VA', nil,nil,nil,nil,nil,nil,nil, true)
                            if SetRowName(WidthLBL, BL_Width) then

                                local Def_W = Get_Default_Param_Width_By_Type(FS.Type)
                                if FS.Type == 'Knob' then Def_W =( FS.Sldr_W or Def_W) * 2 
                                else Def_W = ( FS.Sldr_W or Def_W) 
                                end
                                AddVal('Width', Def_W, WidthStepSize, -Win_W, Win_W, nil , nil, true)
                                AddVal('Width_VA', 0, 0.01, -1, 1 ,'percent')
                            end --[[ local rv, R =  AddRatio('Width' ) if rv then D.Width = R end   ]]
                            if SetRowName('Height', BL_Height) then
                                local Def_H =Get_Default_Param_Height_By_Type(FS.Type)
                                if FS.Type == 'Knob' then Def_H =( FS.Height or Def_H) * 2 
                                else Def_H = ( FS.Height or Def_H) 
                                end


                                AddVal('Height', Def_H, LE.GridSize, -220, 220, nil, nil, true )
                                AddVal('Height_VA', 0, 0.01, -1, 1,'percent')
                            end
                            if SetRowName('Repeat', BL_Repeat) then
                                AddVal('Repeat', 0, 1, 0, 300, '%.0f')
                                AddVal('Repeat_VA', 0, 0.01, -1, 1,'percent')
                            end

                            if SetRowName('Gap', nil, Gap) then
                                AddVal('Gap', 0, 0.2, 0, 300, '%.1f')
                                AddVal('Gap_VA', 0, 0.01, -1, 1,'percent')
                            end
                            if D.Type ~= 'Gain Reduction Text' then
                                if SetRowName('X Gap', BL_XYGap) then
                                    AddVal('X_Gap', 0, 0.2, 0, 300, '%.1f')
                                    AddVal('X_Gap_VA', 0, 0.01, -1, 1,'percent')
                                end
                                if SetRowName('Y Gap', BL_XYGap) then
                                    AddVal('Y_Gap', 0, 0.2, 0, 300, '%.1f')
                                    AddVal('Y_Gap_VA', 0, 0.01, -1, 1,'percent'   )
                                end
                                --[[ if SetRowName('Size Gap',nil, {'Rect'}) then
                                    AddVal('Size_Gap', 0, 0.2, 0, 300, '%.1f')
                                    AddVal('Size_Gap_VA', 0, 0.01, -1, 1,'percent'   )
                                end ]]
                            end
                            if SetRowName('Angle Min', nil, BL_XYGap) then
                                AddVal('Angle_Min', 0.75, 0.01, 0, 3.14, '%.3f',true)
                                --AddVal('Angle_Min_VA', nil, 0.01, -1, 1,  '%.3f', true )

                            end
                            if SetRowName('Angle Max', nil, BL_XYGap) then
                                AddVal('Angle_Max', 2.25, 0.01, 0, 3.14, '%.3f' )
                                AddVal('Angle_Max_VA', 1, 0.01, -1, 1,  '%.3f', true , nil , true )

                            end
                            if SetRowName('Radius Inner', nil, RadiusInOut) then
                                if AddVal('Rad_In', (FS.Sldr_W or Df.KnobRadius) /2, 0.1, 0, 300, '%.2f', true, true) then 
                                    D.Rad_Out = math.max(D.Rad_Out, D.Rad_In+0.1)
                                end
                            end
                            if SetRowName('Radius Outer', nil, RadiusInOut) then
                                if AddVal( 'Rad_Out', FS.Sldr_W or Df.KnobRadius, 0.1, 0, 300, '%.2f', true,true ) then 
                                    D.Rad_In = math.min(D.Rad_In, D.Rad_Out-0.1)
                                end 
                            end
                            if SetRowName('Radius', nil, Radius) then
                                AddVal('Rad_In', FS.Sldr_W or Df.KnobRadius, 0.1, 0, 300, '%.2f', true, true )
                            end
                            if SetRowName('Value Range', nil, {'Knob Numbers'}) then
                                im.TableSetColumnIndex(ctx, 1)
                                im.Text(ctx,'Low: ') SL()
                                AddVal('Value_Range_Low', 0, 1, -1000, 1000, '%.1f', nil, nil, nil, 40 )
                                SL(nil, 20)
                                im.Text(ctx,'High: ') SL()
                                AddVal('Value_Range_High', 10, 1,  -1000, 1000, '%.1f' ,true, nil, nil, 40)
                            end
                            if SetRowName('Decimal Places', nil, {'Knob Numbers'}) then
                                AddVal('Decimal_Places', 0, 1, 0, 10, '%.0f', true)
                            end

                            if SetRowName('Thickness', nil, Thick) then
                                local stepSize = (D.Pointer_Type and (D.Pointer_Type == 'Kite' or D.Pointer_Type == 'Triangle')) and 0.1 or 0.5
                                AddVal('Thick', 2, stepSize, 0, 60, '%.1f', true)
                            end
                            if SetRowName('Pointer type', nil, {'Knob Pointer'}) then
                                im.TableSetColumnIndex(ctx, 1)
                                local WIDTH = (D.Pointer_Type and  D.Pointer_Type == 'Cursor' ) and 120 or -FLT_MIN
                                im.SetNextItemWidth(ctx, WIDTH)
                                if im.BeginCombo(ctx, '##Pointer type' .. LBL, D.Pointer_Type or 'Line') then
                                    if im.Selectable(ctx, 'Line') then D.Pointer_Type = 'Line' end
                                    if im.Selectable(ctx, 'Triangle') then D.Pointer_Type = 'Triangle' end
                                    if im.Selectable(ctx, 'Cursor') then D.Pointer_Type = 'Cursor' end
                                    im.EndCombo(ctx)
                                end
                                if D.Pointer_Type and  D.Pointer_Type == 'Cursor' then
                                    SL(nil, 15)
                                    im.Text(ctx, 'Shape: ')
                                    im.SameLine(ctx)
                                    im.SetNextItemWidth(ctx, 100)
                                    AddVal('Shape', 0, 0.05, -10, 10, '%.2f', true)
                                end
                                im.TableNextRow(ctx)
                            end




                            if SetRowName('Edge Round', nil, Round) then
                                AddVal('Round', 0, 0.1, 0, 100, '%.1f', true)
                            end
                            if SetRowName('Fill', nil, Fill) then

                                im.TableSetColumnIndex(ctx, 1)
                                if D.Type ~= 'Circle' then
                                    SL(nil, TableColumn1W / 2 - 20 )
                                end

                                _, D.Fill = im.Checkbox(ctx, '##Filled'.. LBL,D.Fill)
                                if not D.Fill then Cross_Out() end
                                if D.Type == 'Circle' then
                                    SL(nil, 15)
                                    im.Text(ctx, 'Special: ')
                                    im.SameLine(ctx)
                                    im.SetNextItemWidth(ctx, 100)

                                    if im.BeginCombo(ctx, '## Special Fill'.. LBL, D.Special_Fill) then
                                        if im.Selectable(ctx, 'Metallic') then 
                                            D.Special_Fill = 'Metallic' 
                                            D.Gradient_Start = 2.05
                                            D.Fill = true 
                                        end
                                        if im.Selectable(ctx, 'Gradient') then 
                                            D.Special_Fill = 'Gradient' 
                                            D.Gradient_Start = 0
                                            D.Fill = true 
                                        end
                                        if im.Selectable(ctx, 'None') then D.Special_Fill = nil end

                                        im.EndCombo(ctx)
                                    end

                                end
                                im.TableNextRow(ctx)

                            end

                            Special_Fill ()



                            --[[ if SetRowName('Font Size',GR_Text ) then

                            end ]]
                            
                            SetRowName('Color')
                            im.TableSetColumnIndex(ctx, 1)

                            
                            local rv, Clr = im.ColorEdit4(ctx, 'Color' .. LBL, D.Clr or 0xffffffff, ClrFLG)

                            Set_Property ('Clr', Clr, rv)
                            
                            
                            if D.Repeat and D.Repeat ~= 0 and not FindExactStringInTable(BL_Repeat, D.Type) then
                                im.AlignTextToFramePadding(ctx)
                                SL()
                                im.Text(ctx, 'Start')
                                SL(nil, 20)
                                
                                local rv, Clr = im.ColorEdit4(ctx, 'Repeat Color' .. LBL, D.RPT_Clr or 0xffffffff, ClrFLG)
                                Set_Property ('RPT_Clr', Clr, rv)
                                SL()
                                im.Text(ctx, 'End')

                            end 
                            im.TableSetColumnIndex(ctx, 2)

                            local rv, Clr_VA = im.ColorEdit4(ctx, 'Color_VA' .. LBL, D.Clr_VA  or nil, ClrFLG)
                            if not D.Clr_VA then
                                Cross_Out()
                                -- im.EndDisabled(ctx) 
                            end
                            if rv then D.Clr_VA = Clr_VA end
                            if D.Repeat and D.Repeat ~= 0 and not FindExactStringInTable(BL_Repeat, D.Type) then
                                im.AlignTextToFramePadding(ctx)
                                SL(nil,-3)
                                if im.Button(ctx, 'Start##'..LBL) then
                                    D.Clr_VA = toggle(D.Clr_VA,Clr_VA )
                                end

                                SL(nil, 10)
                                if not D.RPT_Clr_VA then  im.BeginDisabled(ctx) end
                                local rv, Clr = im.ColorEdit4(ctx, 'Repeat Color VA' .. LBL, D.RPT_Clr_VA or 0xffffffff, ClrFLG)
                                if rv then D.RPT_Clr_VA = Clr end
                                if not D.RPT_Clr_VA then
                                    Cross_Out()
                                    im.EndDisabled(ctx) 
                                end
                                SL(nil,-3)
                                if im.Button(ctx, 'End##'..LBL) then
                                    D.RPT_Clr_VA = toggle(D.RPT_Clr_VA,Clr )
                                end

                            end 


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

                local function Preset_Properties(v, i)
                    im.Separator(ctx)

                    local Clr = (v[#v].Clr  ) and Change_Clr_A( (v[#v].Clr or 0x22222233) , 0.1, 0.3) or 0x22222233
                    im.PushStyleColor(ctx, im.Col_ChildBg, Clr)
                    local BC = im.BeginChild(ctx, 'Preset Properties'..i, -FLT_MIN - Color_Palette_Width, nil,  im.ChildFlags_AutoResizeY)

                    local OpenPresetTree =  im.TreeNode(ctx, (v.Belong_To_Preset or '') .. '##'..i) 
                    local Drop_Hover = Allow_Drag_To_Reorder(i, v)

                    SL(nil, 15 )
                    BypassBtn(v, i)
                    SL(nil, 15 )
                    DeleteBtn(i)
                    if OpenPresetTree then 
                        
                        for I, V in ipairs(v) do 
                            Drawing_Properties(V, I, v.Belong_To_Preset )
                        end
                        im.TreePop(ctx)
                    end
                    im.PopStyleColor(ctx)

                    if BC then
                        im.EndChild(ctx)
                    end

                end

                for i, v in ipairs(FS.Draw)  do
                    if v[1] then  -- if this is a recalled preset
                        Preset_Properties(v, i)
                    else 
                        Drawing_Properties(v, i)
                    end
                end



            
                if BeganChild then
                    im.EndChild(ctx)
                end

                if openTree then
                    im.TreePop(ctx)
                end
            
            end


            
        end

        local function Colors_Table()
            local function ThirdColoumn()

                if FS.Type == 'Knob' then
                    local TD, Thick = im.DragDouble(ctx, '##EditValueFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''), FX[FxGUID][LE.Sel_Items[1] or ''].Value_Thick or 2, 0.1, 0.5, 8, '%.1f')
                    if TD then
                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Value_Thick = Thick end
                    end
                end


                if FS.Type == 'Selection' then

                    local DragLbl_Clr_Edited, V_Clr = im.ColorEdit4(ctx, '##V Clr' .. LE.Sel_Items[1], FX[FxGUID][LE.Sel_Items[1] or ''].V_Clr or im.GetColor(ctx, im.Col_Text), im.ColorEditFlags_NoInputs|    r .ImGui_ColorEditFlags_AlphaPreviewHalf()|im.ColorEditFlags_AlphaBar)
                    if DragLbl_Clr_Edited then
                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = V_Clr end
                    end
                elseif FS.Type == 'Switch' then

                    local DragLbl_Clr_Edited, V_Clr = im.ColorEdit4(ctx, '##Switch on Clr' .. LE.Sel_Items[1], FX[FxGUID][LE.Sel_Items[1] or ''].Switch_On_Clr or 0xffffff55, im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf| im.ColorEditFlags_AlphaBar)
                    if DragLbl_Clr_Edited then 
                        for i, v in pairs(LE.Sel_Items) do 
                            FX[FxGUID][v].Switch_On_Clr = V_Clr
                        end
                    end
                elseif FS.Type == 'Drag' then
                    Drag_Direction()
                end
            end
            if im.BeginTable(ctx, 'Colors Settings table', 4, flags, -R_ofs) then 
                local C3Name =''
                if FS.Type == 'Knob' then C3Name = 'Thickness'
                elseif FS.Type == 'Selection' then  C3Name = 'Text Color'
                elseif FS.Type == 'Switch'  then C3Name = 'On Color'
                elseif FS.Type == 'Drag' then C3Name ='Direction'
                end
                im.TableSetupColumn(ctx, 'Color')
                im.TableSetupColumn(ctx, 'Value Color')
                im.TableSetupColumn(ctx, C3Name)
                im.TableSetupColumn(ctx, 'Invisible')


                --[[ im.TableHeadersRow(ctx) ]]

                im.TableNextRow(ctx)
                im.TableSetColumnIndex(ctx, 0 ) 
                im.AlignTextToFramePadding(ctx)
                im.Text(ctx,'Color: ') SL()
                Colors()

                im.TableSetColumnIndex(ctx, 1 ) 
                im.Text(ctx,'Value Color: ')   SL()

                Value_Colors()

                im.TableSetColumnIndex(ctx, 2 ) 
                im.Text(ctx, C3Name)  SL()
                ThirdColoumn()
                im.TableSetColumnIndex(ctx, 3) 
                im.Text(ctx,'Invisible: ')   SL()

                Invisible()


                im.EndTable(ctx)
            end

        end

        local function XY_Pad_Properties ()


            --[[ local function Belong_To_Which_Pad()
                FX[FxGUID].XY_Pad_TB  = FX[FxGUID].XY_Pad_TB or {}
                if not FX[FxGUID].XY_Pad_TB[1] then FX[FxGUID].XY_Pad_TB[1] = 'XY_Pad 1' end
                if im.BeginCombo(ctx, '##Belong_To_Which_Pad', FS.XY_Pad or 'None') then 
                    --im.Selectable(ctx, 'XY_Pad 1')
                    for i, v in ipairs(FX[FxGUID].XY_Pad_TB) do 
                        local Lbl = v.name or 'XY_Pad '..i
                        if LE.Renaming_XY_Pad == i then 
                            local rv, nm = im.InputText(ctx, '##Rename XY Pad', Lbl, r.ImGui_InputTextFlags_EnterReturnsTrue())
                            if rv then 
                                FX[FxGUID].XY_Pad_TB[i].name = nm
                                LE.Renaming_XY_Pad = nil 
                            end
                        else
                            if im.Button(ctx, Lbl) then 
                                FS.XY_Pad = Lbl
                            end
                        end
                        SL()
                        if im.Button(ctx, 'R') then 
                            LE.Renaming_XY_Pad = i 
                        end
                    end
                    if im.Button(ctx, 'Add New') then 
                        table.insert(FX[FxGUID].XY_Pad_TB, 'XY_Pad ' .. #FX[FxGUID].XY_Pad_TB + 1)
                    end
                    im.EndCombo(ctx)
                end
            end ]]

            local function Set_Selected_Prms_As_XY_Pad()
                if #LE.Sel_Items == 2 then 
                    if im.Button(ctx, 'Set Parameters as XY Pad') then 

    
                        FX[FxGUID][LE.Sel_Items[1]].Type = 'XY Pad - X'
                        FX[FxGUID][LE.Sel_Items[1]].XY_Pad_Y_PNum = FX[FxGUID][LE.Sel_Items[2]].Num

                        FX[FxGUID][LE.Sel_Items[2]].Type = 'XY Pad - Y'
    
                        --[[ for i, v in ipairs(LE.Sel_Items) do 
                            FX[FxGUID][v].XY_Pad = #TB
                        end ]]
                    end
                end
            end


            Set_Selected_Prms_As_XY_Pad()

            if FS.Type ~= 'XY Pad' then return end  
            if im.BeginTable(ctx, 'XY Pad Properties', 5, flags, -R_ofs) then 
                im.TableSetupColumn(ctx, 'Belong to')
                im.TableSetupColumn(ctx, 'X')
                im.TableSetupColumn(ctx, 'Y')
                im.TableSetupColumn(ctx, 'Width')
                im.TableSetupColumn(ctx, 'Height')
                im.TableHeadersRow(ctx)
                im.TableNextRow(ctx)
                im.TableSetColumnIndex(ctx, 0) 
                Belong_To_Which_Pad()

                im.TableSetColumnIndex(ctx, 1) 
                im.Button(ctx, 'Set as X')
                im.TableSetColumnIndex(ctx, 2) 
                im.Button(ctx, 'Set as Y')
                im.TableSetColumnIndex(ctx, 3) 
                im.Text(ctx, 'Width:') SL()
                im.TableSetColumnIndex(ctx, 4) 
                im.Text(ctx, 'Height:') SL()
                im.EndTable(ctx)
            end
        end

        im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 4, 6)

        im.SeparatorText( ctx, 'Text')
        Type()      

        Label_Name()                            --[[ AddSpacing(2) ]]
        Switch_Type()
        XY_Pad_Properties ()
        Label_and_Value_Table()                 --[[ AddSpacing(2) ]]


        AddSpacing(3)
        im.SeparatorText( ctx, 'Size and Position')

        Width_Height_PosX_PosY_Table()          --[[ AddSpacing(2) ]]
        
        Manual_Values()
        AddSpacing(3)

        im.SeparatorText( ctx, 'Appearance')
        Style()       SL()
        Custom_Image()                          --[[ AddSpacing(2) ]]
        Colors_Table()
        Attach_Drawings()
        Conditional_Prms()
        im.PopStyleVar(ctx)

        im.PopStyleColor(ctx)


    

    end

    local function Shortcut_for_Select_All()

        if im.IsKeyPressed(ctx, im.Key_A) and (Mods == Cmd or Mods == Alt) then
            for Fx_P = 1, #FX[FxGUID] or 0, 1 do table.insert(LE.Sel_Items, Fx_P) end
        end
    end

    --if not CloseLayEdit   then    ----START CHILD WINDOW------
    DisableScroll = true



    Top_Bar()
    Background_Edit_Properties()
    FX_Title_Properties()
    Parameter_Properties()
    Save_Layout_Edit_Popup()
    Color_Palette()
    Save_Drawing_Popup()
    Shortcut_for_Select_All()


    im.End(ctx)
    if CloseLayEdit then
        FX.LayEdit = nil
        Draw.DrawMode = nil
    end


    im.SameLine(ctx, nil, 0)
    --im.PushStyleVar( ctx,im.StyleVar_WindowPadding, 0,0)
    --im.PushStyleColor(ctx, im.Col_DragDropTarget, 0x00000000)
    --im.EndTooltip(ctx)
    -- im.PopStyleVar(ctx)
    --im.PopStyleColor(ctx,2 )
    PopClr(ctx, 2)

end
--[[ function Alt_Click_To_Set_To_Nil (var, tb, FxGUID)
    if tb then 
        for i, v in ipairs(tb) do 
            if im.IsItemClicked(ctx) and Mods == Alt then 
                FX[FxGUID][v][var]= nil
            end
        end

    end
end ]]

function Retrieve_Attached_Drawings(Ct, Fx_P, FP)

    local DrawNum = RecallInfo(Ct, 'Number of attached drawings', Fx_P , 'Num')

    if not DrawNum then return end


    FP.Draw = FP.Draw or {}
    local Child_Draw_ID = 0
    local Parent_Draw_ID = 1
    for D = 1, DrawNum, 1 do
        local function RC(name, type, omit_if_0, index)

            local out = RecallInfo(Ct, 'Draw Item ' .. (index or D) .. ': ' .. name, Fx_P, type)
            if omit_if_0 and out == 0 then 
                out = nil 
            end

            return out
        end
        FP.Draw[Parent_Draw_ID] = FP.Draw[Parent_Draw_ID] or {}
        local d = FP.Draw[Parent_Draw_ID]

        d.Belong_To_Preset = RC('Under Preset')

        local PDID = Parent_Draw_ID
        


        local Belong_To_Preset = RC('Under Preset')
        if Belong_To_Preset then 
            local last_Preset =  RC('Under Preset',nil,nil, D-1)
            
            if last_Preset and last_Preset == Belong_To_Preset then 
                if d[1] then 


                    table.insert(d, {})

                    d = d[#d]
                    Next_Preset = RC('Under Preset',nil,nil, D+1)
                    if Next_Preset and Next_Preset ~= Belong_To_Preset then 
                        Parent_Draw_ID = Parent_Draw_ID + 1
                    end
                end
            else

                table.insert(d, {})
                d = d[#d]
                Next_Preset = RC('Under Preset',nil,nil, D+1)
                if Next_Preset and Next_Preset ~= Belong_To_Preset then 
                    Parent_Draw_ID = Parent_Draw_ID + 1
                end
                
            end
        else 
            Parent_Draw_ID = Parent_Draw_ID + 1
        end


        d.Type = RC('Type')
        d.X_Offset = RC('X Offset', 'Num', true )
        d.X_Offset_VA = RC('X Offset Value Affect', 'Num')
        d.X_Offset_VA_BP = RC('X Offset Value Affect BP', 'Bool')

        d.X_Offset_VA_GR = RC('X Offset Value Affect GR', 'Num')
        d.Y_Offset = RC('Y offset', 'Num', true)
        d.Y_Offset_SS = RC('Y offset Size Sync', 'Bool')

        d.Y_Offset_VA = RC('Y Offset Value Affect', 'Num')
        d.Y_Offset_VA_BP = RC('Y Offset Value Affect BP', 'Num')

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
        d.Angle_Max_VA = RC('Angle Max VA', 'Num')

        d.Angle_Max_VA_BP = RC('Angle Max VA BP', 'Bool')
        d.Value_Range_Low = RC('Value Range Low', 'Num')
        d.Value_Range_High = RC('Value Range High', 'Num')
        d.Decimal_Places = RC('Decimal Places', 'Num')
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
        d.RPT_Clr_VA = RC('RPT_Clr_VA', 'Num')
        d.Fill = RC('Fill', 'Bool')
        d.Texture_Angle = RC('Texture_Angle', 'Num')
        d.Gradient_Start = RC('Gradient_Start', 'Num')
        d.Special_Fill = RC('Special_Fill')
        d.Clr2 = RC('Color2', 'Num')
        d.RPT_Clr2 = RC('RPT_Clr2', 'Num')
        d.Pointer_Type = RC('Pointer_Type')
        d.Shape = RC('Shape', 'number')


        if d.Type and  d.Type:find('Filled') then 
            d.Fill = true 
        end


        local path = RC('Image_Path')

        if path and path~='nil' then
            d.AtchImgFileNm = path
            d.AtchImgFileNm = TruncatePath(path)

            local dir_path = ConcatPath(CurrentDirectory , 'src', 'Images', 'Attached Drawings',d.AtchImgFileNm )
            

            d.Image = im.CreateImage(dir_path)
            im.Attach(ctx, d.Image)
        end
    end

    return FP.Draw

end

function Before_Main__Write_Label_And_Value_For_Sldr_and_Drag(labeltoShow, Font,V_Font, Format_P_V, FP, Lbl_Pos, V_Pos)
    local Lbl_Clr = FP.Lbl_Clr_At_Full and BlendColors(FP.Lbl_Clr, FP.Lbl_Clr_At_Full, FP.V) or FP.Lbl_Clr or getClr(im.Col_Text)

    if Lbl_Pos == 'Left' then


        MyText(labeltoShow, _G[Font], Lbl_Clr or 0xaaaaaaff)
        --im.Text(ctx, labeltoShow)

        im.SameLine(ctx, nil, 8)

        --[[ im.SliderDouble(ctx, '##ansdjknas', FP.V or 0, FP.V_Round or 1, 0, 1)
        im.AlignTextToFramePadding(ctx) ]]
    end
    if Lbl_Pos == 'Within-Left' then
        local x , y = im.GetCursorPos(ctx)
        im.AlignTextToFramePadding(ctx)
        MyText(labeltoShow, _G[Font] or Font_Andale_Mono_12, Lbl_Clr)
        im.SetCursorPos(ctx,x,y)
        --im.DrawList_AddText(draw_list, SldrL, SldrT + H / 3 , FP.Lbl_Clr or txtclr, labeltoShow)
    end

    if _G[Font] then 
        local H = im.GetTextLineHeight(ctx)
        im.PushFont(ctx, _G[Font])
        local w, h = im.CalcTextSize(ctx, labeltoShow)

        
        im.SetCursorPosY(ctx, im.GetCursorPosY(ctx) + (h-H)/2 --[[ + h / 4 ]])
        im.PopFont(ctx)
    end
end

function If_V_Pos_Is_Only_When_Active(FP, is_active, Format_P_V)
    if is_active then
        if FP.V_Pos=='Only When Active' then 

            FP.Orig_Custom_Lbl =  FP.Orig_Custom_Lbl or FP.CustomLbl or FP.Name
            FP.CustomLbl = Format_P_V 


        end
    elseif not is_active and FP.Orig_Custom_Lbl then 
        FP.CustomLbl = FP.Orig_Custom_Lbl 
        FP.Orig_Custom_Lbl = nil
    end
end


function After_Main__Write_Label_And_Value_For_Sldr_and_Drag(labeltoShow, Font,V_Font, Format_P_V, FP, Lbl_Pos, V_Pos)
    if NEED_ATACH_NEW_FONT then return end
    local TextW, h      = im.CalcTextSize(ctx, labeltoShow, nil, nil, true)
    local SldrR, SldrB  = im.GetItemRectMax(ctx)
    local SldrL, SldrT  = im.GetItemRectMin(ctx)
    local W, H          = SldrR - SldrL, SldrB - SldrT
    local draw_list = draw_list or im.GetWindowDrawList(ctx)
    im.PushFont(ctx, _G[V_Font] or Arial_11)
    if FP.V_Round then Format_P_V = RoundPrmV(Format_P_V, FP.V_Round) end
    TextW, Texth = im.CalcTextSize(ctx, Format_P_V, nil, nil, true, -100)
    --if is_active then txtclr = 0xEEEEEEff else txtclr = 0xD6D6D6ff end
    local V_Clr = FP.V_Clr_At_Full and BlendColors(FP.V_Clr, FP.V_Clr_At_Full, FP.V)    or FP.V_Clr or getClr(im.Col_Text)
    local Lbl_Clr = FP.Lbl_Clr_At_Full and BlendColors(FP.Lbl_Clr, FP.Lbl_Clr_At_Full, FP.V) or FP.Lbl_Clr or getClr(im.Col_Text)

    im.PopFont(ctx)
    local Centered_H = SldrT + H / 2 - 5
    local Centered_W = SldrL + W / 2 - TextW / 2
    local FontSz = FP.V_FontSize or Knob_DefaultFontSize
    local p1, p2 


    if V_Pos and (V_Pos == 'Within' or Lbl_Pos == 'Left') and V_Pos ~= 'None' and V_Pos ~= 'Free'  then
        p1 , p2 = Centered_W, Centered_H
    elseif V_Pos == 'Within-Right' then
        p1, p2 = SldrR - TextW, Centered_H
    elseif V_Pos == 'Right' then
        p1, p2 =SldrR + 5, Centered_H
    elseif V_Pos =='Bottom-Right' then 
        p1, p2 =SldrR - TextW -5, SldrT + H
    elseif V_Pos =='Bottom-Left' then 
        p1, p2 = SldrL, SldrT + H
    elseif V_Pos == 'Bottom' then 
        p1, p2 = Centered_W , SldrT + H
    elseif V_Pos == 'Top' then 
        p1, p2 =Centered_W , SldrT -Texth
    end
    if p1 then 
        local p1 , p2  =  p1 + (FP.V_Pos_X or 0) , p2 + (FP.V_Pos_Y or 0)
        im.DrawList_AddTextEx(draw_list, _G[V_Font], FontSz, p1 , p2 , V_Clr, Format_P_V)
    end

    local x, y = im.GetCursorPos(ctx)
    im.SetCursorPos(ctx, x + (FP.Lbl_Pos_X or 0) , y - (SldrB - SldrT) + (FP.Lbl_Pos_Y or 0))
   



    if not Lbl_Pos or Lbl_Pos == 'Within-Top-Left' then
        local X, Y = im.GetCursorPos(ctx)

        if Disable == 'Disabled' then TxtClr = getClr(im.Col_TextDisabled) end

        if item_inner_spacing then
            if item_inner_spacing < 0 then im.SetCursorPosY(ctx, im.GetCursorPosY(ctx) + item_inner_spacing) end
        end

        MyText(labeltoShow, _G[Font] or Font_Andale_Mono_12, Lbl_Clr)
       
        --im.SetCursorPos(ctx, SldrR - TextW, Y)

    elseif Lbl_Pos =='Bottom-Left' or Lbl_Pos == 'Bottom' then 
           
        local X, Y = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, X , Y + H)
        MyText(labeltoShow, _G[Font] or Font_Andale_Mono_12, Lbl_Clr)
    elseif Lbl_Pos =='Bottom-Center' then
        

        local X, Y = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, X + W/2, Y + H)
        MyText(labeltoShow, _G[Font] or Font_Andale_Mono_12, Lbl_Clr,nil, 'Center' )
    end
    im.Dummy(ctx,1,1)
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
    local FP = FX[FxGUID][Fx_P]

    if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl then im.BeginDisabled(ctx) end

    local p_value = (FP.WhichCC or Tweaking == P_Num .. FxGUID) and FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)  or 0
    local radius_outer = Radius or Df.KnobRadius;
    --[[ 
    local Font = 'Arial_' .. roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    local V_Font = 'Arial_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1) ]]
    local Font, V_Font = GetFonts(FP)


    im.PushFont(ctx, _G[Font])



    local Radius       = Radius or 0

    local pos          = { im.GetCursorScreenPos(ctx) }
    local center       = { pos[1] + radius_outer, pos[2] + radius_outer }
    local Clr_SldrGrab = Change_Clr_A(getClr(im.Col_SliderGrabActive), -0.2)
    local TextW = im.CalcTextSize(ctx, labeltoShow or FX[FxGUID][Fx_P].Name, nil, nil, true)
    local CenteredVPos
    im.BeginGroup(ctx)

    local CenteredLblPos = --[[ TextW < (Radius or 0) * 2 and ]] pos[1] + Radius - TextW / 2 --[[ or pos[1] ]]

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
    local _, FormatPV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)





    WhichClick()
    local is_active = im.InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height + item_inner_spacing[2] + (BtnOffset or 0), im.ButtonFlags_MouseButtonLeft) -- ClickButton to alternate left/right dragging
    MakeItemEditable(FxGUID, Fx_P, FP.Sldr_W, 'Knob', curX, CurY)

     local is_active = im.IsItemActive(ctx)
    local is_hovered = im.IsItemHovered(ctx)
    local t = (p_value - v_min) / (v_max - v_min)
    local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
    local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
    local radius_inner = radius_outer * 0.40
    local ClrBg = im.GetColor(ctx, im.Col_FrameBg)

    local BtnL, BtnT = im.GetItemRectMin(ctx)
    local BtnR, BtnB = im.GetItemRectMax(ctx)
    local V_Clr = FP.V_Clr_At_Full and BlendColors(FP.V_Clr, FP.V_Clr_At_Full, FP.V)    or FP.V_Clr or getClr(im.Col_Text)


    local function Knob_Interaction() -- CURRENTLY NOT USED
            
        if ClickButton == im.ButtonFlags_MouseButtonLeft then                                -- left drag to adjust parameters
            if im.BeginDragDropSource(ctx, im.DragDropFlags_SourceNoPreviewTooltip) then
                im.SetDragDropPayload(ctx, 'my_type', 'my_data')
              
                Clr_SldrGrab = getClr(im.Col_Text)

                HideCursorTillMouseUp(0)
                im.SetMouseCursor(ctx, im.MouseCursor_None)
                if -mouse_delta[2] ~= 0.0 then
                    local stepscale = 1
                    if Mods == Shift then stepscale = 3 end
                    local step = (v_max - v_min) / (200.0 * stepscale)
                    --local _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation','', false)
                    local ValBeforeMod = Load_from_Trk( 'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation')                    
                    p_value = (ValBeforeMod or p_value) + (-mouse_delta[2] * step)
                    if p_value < v_min then p_value = v_min end
                    if p_value > v_max then p_value = v_max end
                    if ValBeforeMod then Save_to_Trk( 'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation',p_value) end 
                    --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
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
            if not FP.WhichCC and not FP.Cont_Which_CC then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            FX[FxGUID][Fx_P].V = p_value

            else
                local _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation','', false)
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 0) -- 1 active, 0 inactive
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FX[FxGUID][Fx_P].V)
            end
        end

    end

    local function if_Drag_Knob()
        if not is_active then  return end 
        HideCursorTillMouseUp(0)
        im.SetMouseCursor(ctx, im.MouseCursor_None)
        if -mouse_delta[2] ~= 0.0 then
            local stepscale = 1
            if Mods == Shift then stepscale = 3 end
            local step = (v_max - v_min) / (200.0 * stepscale)
            --local _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation','', false)
            local ValBeforeMod = Load_from_Trk( 'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation')                    

            p_value = (ValBeforeMod or p_value) + (-mouse_delta[2] * step)

            if p_value < v_min then p_value = v_min end
            if p_value > v_max then p_value = v_max end
            if ValBeforeMod then Save_to_Trk( 'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation',p_value) end 
            --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            MvingP_Idx = F_Tp
            Tweaking = P_Num .. FxGUID

            
        end


        --if user turn knob on ImGui
        if Tweaking == P_Num .. FxGUID then


            if not FP.WhichCC and not FP.Cont_Which_CC then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)

            else
                local _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation','', false)
                local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.active", 0) -- 1 active, 0 inactive
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
                --msg('FX[FxGUID][Fx_P].V = ' .. FX[FxGUID][Fx_P].V)
            end
            FX[FxGUID][Fx_P].V = p_value
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
                    uvmin, uvmax = Calc_strip_uv(Image, p_value or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num))
                    im.DrawList_AddImage(WDL, Image, center[1] - sz / 2, center[2] - sz / 2, center[1] + sz / 2, center[2] + sz / 2, 0, uvmin, 1, uvmax, FP.BgClr or 0xffffffff)
                else
                    local scale = 2
                    local sz = radius_outer * scale

                    local angle = FP.DontRotateImg and 4 + (FP.ImgAngleMinOfs or 0) or (4 + (FP.ImgAngleMinOfs or 0) + p_value  * 4.5) 
                    ImageAngle(ctx, Image, angle, sz, sz, center[1] - sz / 2, center[2] - sz / 2)
                end
            end
        elseif Style == 'Invisible' or FP.Invisible then
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
     
        if (FX[FxGUID].Morph_Value_Edit or Mods == Ctrl + Alt) and FX[FxGUID].MorphA and FX[FxGUID].MorphB then
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
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_msg2", FX[FxGUID].Morph_ID)                                                                    -- CC value
                            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".mod.baseline", Orig_Baseline)                                                                          -- Baseline
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
            local X, Y = (CenteredLblPos or pos[1] )+ (FP.Lbl_Pos_X or 0), pos[2] + radius_outer * 2 + item_inner_spacing[2] + (FP.Lbl_Pos_Y or 0 )
            local Clr = FX[FxGUID][Fx_P].Lbl_Clr or 0xffffffff
            local FontSize = FX[FxGUID][Fx_P].FontSize or Knob_DefaultFontSize

            im.DrawList_AddTextEx(draw_list, _G[Font], FX[FxGUID][Fx_P].FontSize or Knob_DefaultFontSize, X, Y, Clr,labeltoShow or FX[FxGUID][Fx_P].Name--[[ , (Radius or 20) * 2, X, Y, X + (Radius or 20) * 2, Y + FontSize * 2 ]])
        end 
        if V_Pos ~= 'None' and V_Pos then
            im.PushFont(ctx, _G[V_Font])
    
            FormatPV = FP.V_Round and RoundPrmV(FormatPV, FP.V_Round) or FormatPV
            local ValueTxtW = im.CalcTextSize(ctx, FormatPV, nil, nil, true)

            local Y_Offset, drawlist
            local CenteredVPos = pos[1] + Radius - ValueTxtW / 2
            local pX = CenteredVPos+ (FP.V_Pos_X or 0)
            local FtSz = FP.V_FontSize or Knob_DefaultFontSize

            if is_active or is_hovered then drawlist = Glob.FDL else drawlist = draw_list end


            if V_Pos == 'Within' then 
                Y_Offset = radius_outer * 1.2 
            elseif V_Pos =='Top' then 

                local SldrL, SldrT  = im.GetItemRectMin(ctx)
                local TextW, h      = im.CalcTextSize(ctx, FormatPV, nil, nil, true)
                local p2 = SldrT -h + item_inner_spacing[2] - (Y_Offset or 0) + (FP.V_Pos_Y or 0)
                im.DrawList_AddTextEx(draw_list, _G[V_Font], FtSz,pX ,p2 , V_Clr, FormatPV)

            elseif V_Pos =='Bottom' then

                im.DrawList_AddTextEx(draw_list, _G[V_Font], FtSz, pX, pos[2] + radius_outer * 2 + item_inner_spacing[2] - (Y_Offset or 0) + (FP.V_Pos_Y or 0), V_Clr, FormatPV)
            elseif V_Pos == 'Within' then 
                im.DrawList_AddTextEx(draw_list, _G[V_Font], FtSz, pX, pos[2] + radius_outer * 2 + item_inner_spacing[2] - radius_outer * 1.2   + (FP.V_Pos_Y or 0), V_Clr, FormatPV)
            end
            im.PopFont(ctx)
        end
    
        --[[ if V_Pos == 'Free' then
            local Ox, Oy = im.GetCursorScreenPos(ctx)
            im.DrawList_AddTextEx(draw_list, _G[V_Font], FP.V_FontSize or Knob_DefaultFontSize,
                pos[1] + (FP.V_Pos_X or 0), pos[2] + (FP.V_Pos_Y or 0), FX[FxGUID][Fx_P].V_Clr or 0xffffffff, FormatPV)--,(Radius or 20) * 2)
        end ]]
        if Lbl_Pos == 'Within' and Style == 'FX Layering' then
            local ValueTxtW = im.CalcTextSize(ctx, labeltoShow, nil, nil, true)
            local CenteredVPos = pos[1] + Radius - ValueTxtW / 2 + 0.5
            local Y_Offset = radius_outer * 1.3 - 1
    
            im.DrawList_AddTextEx(draw_list, _G[V_Font], 10, CenteredVPos, pos[2] + radius_outer * 2 + item_inner_spacing[2] - (Y_Offset or 0), FX[FxGUID][Fx_P].V_Clr or 0xffffff88, labeltoShow--[[ , (Radius or 20) * 2 ]])
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
            local function Show_Mod_Range(Amt, IndicClr, rangeClr)
                if not Amt or Amt == 0 then return end
                 --if Modulation has been assigned to params
                 local P_V_Norm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

                 
                 --- indicator of where the param is currently
                 local PosAftrMod = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * (P_V_Norm)


                 if Amt ==FP.Cont_ModAMT or not rangeClr then 
                    IndicClr = ThemeClr ('Accent_Clr_Not_Focused')
                    rangeClr = Change_Clr_A(IndicClr , -0.3)
                end

                if If_Hvr_or_Macro_Active (FxGUID, Macro) then 
                    IndicClr = Change_Clr_A(IndicClr , 1)
                    rangeClr = Change_Clr_A(IndicClr , - 0.3)
                end 

                if FP.ModBipolar[Macro] then
                    BipOfs = -Amt[Macro] 
                end
                --- shows modulation range
                --- 
                FP.V = FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
                local t = (FP.V - v_min) / (v_max - v_min)
                local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                local Range = SetMinMax(angle + (ANGLE_MAX - ANGLE_MIN) * Amt , ANGLE_MIN, ANGLE_MAX)

            
                if BipOfs ~= 0 then
                    local Range = SetMinMax(angle + (ANGLE_MAX - ANGLE_MIN) * -(Amt ), ANGLE_MIN, ANGLE_MAX)
                    im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer - 1 + offset, angle, Range)
                    im.DrawList_PathStroke(draw_list, IndicClr, nil, radius_outer * 0.1)
                    im.DrawList_PathClear(draw_list)
                end
                im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer - 1 + offset, angle, Range)

                im.DrawList_PathStroke(draw_list, IndicClr, nil, radius_outer * 0.1)
                im.DrawList_PathClear(draw_list)

                --Show current value pos with range
                im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer * 0.75, angle, PosAftrMod)
                im.DrawList_PathStroke(draw_list, rangeClr, nil, radius_outer / 2)

                im.DrawList_PathClear(draw_list)
                --[[ 
                -- Show current value pos with range but more visible
                im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer * 0.75, angle, PosAftrMod)
                im.DrawList_PathStroke(draw_list, Change_Clr_A(IndicClr , 1), nil, radius_outer/10)
                im.DrawList_PathClear(draw_list) ]]

            end

        

            for Macro, v in ipairs(MacroNums) do
                if Amt[Macro] then
                    local IndicClr = EightColors.bgWhenAsgnModAct[Macro]
                    local rangeClr = EightColors.bgWhenAsgnModHvr[Macro]
                    Show_Mod_Range(Amt[Macro], IndicClr, rangeClr)
                   

                    ParamHasMod_Any = true

                    offset = offset + OffsetForMultipleMOD
                end
            end
            for M, v in ipairs(Midi_Mods) do 

                Show_Mod_Range(Amt[v] ,  ThemeClr('Accent_Clr'))
            end
        end -- of reapeat for every macro



        if Trk.Prm.Assign and F_Tp == Trk.Prm.Assign and AssigningMacro and FP.ModAMT and  FP.ModAMT[1] then
            local M = AssigningMacro

            RightBtnDragX, RightBtnDragY = im.GetMouseDragDelta(ctx, x, y, 1)

            FP.ModAMT[M] = ((-RightBtnDragY / 100) or 0) + (FP.ModAMT[M] or 0)
            
           --[[  if FP.ModAMT[M] + p_value > 1 then FP.ModAMT[M] = 1 - p_value end
            if FP.ModAMT[M] + p_value < 0 then FP.ModAMT[M] = -p_value end ]]
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

            r.SetProjExtState(0, 'FX Devices', 'Param -' .. Trk.Prm.Assign .. 'Macro - ' .. AssigningMacro .. FxGUID, FP.ModAMT[M])
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

    if_Drag_Knob()

    Write_Label_And_Value_All_Types(FP, pos, draw_list, labeltoShow or FP.Name, CenteredLblPos, Font,V_Font, FormatPV, Lbl_Pos)

    If_V_Pos_Is_Only_When_Active( FP, is_active, FormatPV)
    --Knob_Interaction()
    MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, 'knob')
    ShowTooltip_if_Active()
    
    Drawings_For_Styles()
    Draw_Attached_Drawings(FP,FX_Idx, pos,p_value,nil, FxGUID)
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


function Add_XY_Pad(ctx, FP, FxGUID,FX_Idx)
    local TB = FX[FxGUID].XY_Pad_TB
    local P_Num_Y = FP.XY_Pad_Y_PNum

    im.Button(ctx, '   ##XY Pad '..FP.Num, 20, 20)
    local V_Y = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num_Y)
    FP.V = FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num)

    if im.IsItemActive(ctx) then
        local Ms_Delta_X, Ms_Delta_Y = im.GetMouseDragDelta(ctx, x, y, 0)
        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, FP.Num, FP.V + Ms_Delta_X)
        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num_Y, V_Y + Ms_Delta_Y)
        if Ms_Delta_X ~= 0 or Ms_Delta_Y ~= 0 then
            im.ResetMouseDragDelta(ctx, 0)
        end 
    end
end

function GetFonts (FP)
    local FtSz = roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    local Font = 'Font_Andale_Mono_' .. FtSz
    if FP.Lbl_FONT then 
        Font = FP.Lbl_FONT.. '_' .. FtSz ..(FP.Lbl_Italic and '_Italic' or '') .. (FP.Lbl_Bold and '_Bold' or '')
    end

    if not r.ImGui_ValidatePtr(_G[Font], 'ImGui_Font*') then 
        Attach_New_Font_On_Next_Frame(FP.Lbl_FONT or 'Font_Andale_Mono', FtSz, FP.Lbl_Italic, FP.Lbl_Bold)
        return 
    end




    local FtSz = roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1 )
    local V_Font = 'Arial_' .. FtSz
    if FP.Val_FONT then 
        V_Font = FP.Val_FONT.. '_' .. FtSz 
        V_Font = FP.Val_FONT.. '_' .. FtSz ..(FP.Val_Italic and '_Italic' or '') .. (FP.Val_Bold and '_Bold' or '')
    end
    if not r.ImGui_ValidatePtr(_G[V_Font], 'ImGui_Font*') then 
        Attach_New_Font_On_Next_Frame(FP.Val_FONT or 'Arial', FtSz, FP.Val_Italic, FP.Val_Bold)
        return 
    end

    return Font, V_Font
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
    if not FxGUID or not P_Num then return end


    local line_height = im.GetTextLineHeight(ctx)
    local draw_list = im.GetWindowDrawList(ctx)
    local f_draw_list = im.GetForegroundDrawList(ctx)


    local mouse_delta = { im.GetMouseDelta(ctx) }
    local _, Format_P_V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)


    local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P] or 0
    FX[FxGUID] = FX[FxGUID] or {}
    FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
    local FP = FX[FxGUID][Fx_P]

    local Font, V_Font = GetFonts (FP)
    
    local _, FormatPV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
    if Vertical == 'Vert' then ModLineDir = Height else ModLineDir = Sldr_Width end

    labeltoShow = labeltoShow or select(2, r.TrackFX_GetParamName( LT_Track,FX_Idx, P_Num))

    




    if not FP.Name then return end 
    local CC = FP.WhichCC or -1


    if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl or LBtnDC then im.BeginDisabled(ctx) end

    --[[ if item_inner_spacing then
        im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, item_inner_spacing, item_inner_spacing)
    end ]]

    local function PushClrs()
 

        if FP.Invisible then
            local Clr = 0x00000000 
            im.PushStyleColor(ctx, im.Col_SliderGrab, Clr)
            im.PushStyleColor(ctx, im.Col_SliderGrabActive, Clr)
            im.PushStyleColor(ctx, im.Col_FrameBg, Clr)
            im.PushStyleColor(ctx, im.Col_FrameBgHovered, Clr)
            im.PushStyleColor(ctx, im.Col_FrameBgActive, 0xffffff11)
            ClrPop = 5
        else 
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
    
            if FP.GrbClr  then
                
                local ActV
                local R, G, B, A = im.ColorConvertU32ToDouble4(FP.GrbClr)
                local H, S, V = im.ColorConvertRGBtoHSV(R, G, B)
                if V > 0.9 then ActV = V - 0.2 end
                local R, G, B = im.ColorConvertHSVtoRGB(H, S, ActV or V + 0.2)
    
                local ActClr =  im.ColorConvertDouble4ToU32(R, G, B, A)
                im.PushStyleColor(ctx, im.Col_SliderGrab, FP.GrbClr)
                im.PushStyleColor(ctx, im.Col_SliderGrabActive, ActClr)
                ClrPop = ClrPop + 2
            end

        end


    end

    local function Write_Label_And_Value_If_Vert()


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
            --[[ if FP.Lbl_Pos == 'Top' then
                MyText(labeltoShow or FP.Name, _G[Font], FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text))
            end
            if FP.V_Pos == 'Top' then
                local Get, Param_Value = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)

                local x = im.GetCursorPosX(ctx)
                local TextW = im.CalcTextSize(ctx, Param_Value, nil, nil, true, -100)

                im.SetCursorPosX(ctx, x+ Sldr_Width - TextW)
                if Get then  MyText(Param_Value, _G[V_Font], FP.V_Clr or im.GetColor(ctx, im.Col_Text)) end 
            end ]]
        end

        --[[ if FP.Lbl_Pos == 'Left' then
            im.PushFont(ctx, _G[Font])
            im.AlignTextToFramePadding(ctx)
            im.TextColored(ctx, FP.Lbl_Clr or im.GetColor(ctx, im.Col_Text), labeltoShow or FP.Name)
            SL()
            im.PopFont(ctx)
        end ]]
    end

    local function MakeSlider()
        im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)
        if GrabSize then im.PushStyleVar(ctx, im.StyleVar_GrabMinSize, GrabSize) end

        if not Sldr_Width or Sldr_Width == '' then Sldr_Width = FX.Def_Sldr_W[FxGUID] or Def_Sldr_W or 160 end
        im.SetNextItemWidth(ctx, Sldr_Width)
        if Vertical == 'Vert' then
            _, p_value = im.VSliderDouble(ctx, label, Sldr_Width, FP.Height or Height or 160, p_value, v_min, v_max, ' ')
            MakeItemEditable(FxGUID, Fx_P, FP.Sldr_W, 'V-Slider', curX, CurY)
        else
            _, p_value = im.SliderDouble(ctx, label, p_value, v_min, v_max, ' ', im.SliderFlags_NoInput)
            local PosL, PosT = im.GetItemRectMin(ctx)
            local PosR, PosB = im.GetItemRectMax(ctx)
            if im.IsMouseHoveringRect(ctx, PosL, PosT, PosR, PosB) and im.IsMouseDoubleClicked(ctx, 0)    then   
                Set_Prm_To_Default(FX_Idx, FP)
            end
            MakeItemEditable(FxGUID, Fx_P, FP.Sldr_W, 'Sldr', curX, CurY)
        end

        if GrabSize then im.PopStyleVar(ctx) end
        im.PopStyleVar(ctx)

        
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
        --[[ im.InvisibleButton(ctx, '##plink' .. P_Num, PosR - PosL, PosB - PosT, ClickButton) -- for parameter linken    -- right drag to link parameters
            DnD_PLink_SOURCE(FX_Idx, P_Num)
        end ]]
        
    end

    PushClrs()
    

    FP.V = FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    if DraggingMorph == FxGUID then p_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end
    Before_Main__Write_Label_And_Value_For_Sldr_and_Drag(labeltoShow, Font, V_Font, Format_P_V, FP, FP.Lbl_Pos, FP.V_Pos)
    im.BeginGroup(ctx)

    MakeSlider()

    

    local is_active = im.IsItemActive(ctx)
    local is_hovered = im.IsItemHovered(ctx)
    Draw_Attached_Drawings(FP,FX_Idx, pos, cur_value ,nil,  FxGUID)

    After_Main__Write_Label_And_Value_For_Sldr_and_Drag(labeltoShow, Font,V_Font, Format_P_V, FP, FP.Lbl_Pos, FP.V_Pos)
    Write_Label_And_Value_All_Types(FP, pos, draw_list, labeltoShow ,  CenteredLblPos, Font, V_Font , FormatPV, Lbl_Pos) 
    --[[ Write_Label_And_Value_If_Vert()
    Write_Label_And_Value_All_Types(FP, pos, draw_list, labeltoShow ,  CenteredLblPos, Font, V_Font , FormatPV, Lbl_Pos) ]]
    local cur_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    im.PopStyleColor(ctx, ClrPop)
    im.EndGroup(ctx)

    
    Suzukis_Work_ParamLink_And_MouseWheelAdjust()
    

    --@@todo add double click to reset to default


    RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)

    local SldrR, SldrB = im.GetItemRectMax(ctx)
    local SldrL, SldrT = im.GetItemRectMin(ctx)

    PosL, PosT = im.GetItemRectMin(ctx)
    PosR, PosB = im.GetItemRectMax(ctx)
    

    local button_x, button_y = im.GetCursorPos(ctx)
    --im.SetCursorPosY(ctx, button_y - (PosB - PosT))
    --WhichClick()


    local value_changed = false

    --[[ if is_active == true then Knob_Active = true end
    if Knob_Active == true then
        if IsLBtnHeld == false then Knob_Active = false end
    end ]]

    --[[ if SliderStyle == 'Pro C' then
        SldrLength = PosR - PosL
        SldrGrbPos = SldrLength * p_value
        if is_active then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xFFD571bb, Rounding)
        elseif is_hovered then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xDFB973bb, Rounding)
        else
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0x888888bb, Rounding)
        end
    end ]]

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
    If_V_Pos_Is_Only_When_Active(FP, is_active, Format_P_V)

    local tooltip_Tirgger = (is_active or is_hovered) and (FP.V_Pos == 'None' or not FP.V_Pos )
    local SzX, SzY = im.GetItemRectSize(ctx)
    local MsX, MsY = im.GetMousePos(ctx)
    local PosY = FP.Type =='V-Slider' and pos[2]-line_height or pos[2] - SzY - line_height --[[ + button_y ]]
    Show_Value_Tooltip(tooltip_Tirgger, SetMinMax(MsX, pos[1], pos[1] + SzX), PosY , Format_P_V )

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


    if AssigningMacro then
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





    if FX[FxGUID].Morph_Value_Edit or Mods == Alt + Ctrl or LBtnDC then im.EndDisabled(ctx) end

--[[ 
    if item_inner_spacing then im.PopStyleVar(ctx) end ]]

    if SpacingBelow then
        for i = 1, SpacingBelow, 1 do im.Spacing(ctx) end
    else
        im.Spacing(ctx); im.Spacing(ctx); im.Spacing(ctx); im.Spacing(ctx); im.Spacing(ctx)
    end

    



    


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
    local FP = Fx_P and FX[FxGUID][Fx_P]
    FX[FxGUID or ''][Fx_P or ''] = FX[FxGUID or ''][Fx_P or ''] or {}
    if not FP then return end 

    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)

    im.BeginGroup(ctx)
    --local V_Font = 'Font_Andale_Mono_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    --local Font = 'Font_Andale_Mono_' .. roundUp(FP.FontSize or LblTextSize or Knob_DefaultFontSize, 1)
    local Font, V_Font = GetFonts(FP)

    local V_Norm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num)
    local Lbl_Clr = FP.Lbl_Clr_At_Full and BlendColors(FP.Lbl_Clr, FP.Lbl_Clr_At_Full, V_Norm) or FP.Lbl_Clr or getClr(im.Col_Text)
    local V_Norm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, WhichPrm)
    local V_Clr = FP.V_Clr_At_Full and BlendColors(FP.V_Clr, FP.V_Clr_At_Full, V_Norm)    or FP.V_Clr or getClr(im.Col_Text)


    local pos = {im.GetCursorScreenPos(ctx)}


    local function Draw_Native_Styles()
        local ExtraW

        if Style == 'up-down arrow' then
            ExtraW = 20
            local R, B = im.GetItemRectMax(ctx)
            local lineheight = im.GetTextLineHeight(ctx)
            local drawlist = im.GetWindowDrawList(ctx)
            local m = B - lineheight / 2 - 3
            g = 2
            local X = R - ExtraW / 2
            DrawTriangle(drawlist, X, m - g, 3, clr)
            DrawDownwardTriangle(drawlist, X, m + g, 3, clr)
        end
        return ExtraW
    end


    if Fx_P and FP then
        if (FP.Lbl_Pos == 'Left' and Lbl_Pos ~= 'No Lbl') or FP.Lbl_Pos == 'Top' then

            local nm = LabelOveride or FP.CustomLbl or CustomLbl or FP.Name or select(2, r.TrackFX_GetParamName( LT_Track, FX_Idx, WhichPrm))
            im.AlignTextToFramePadding(ctx)
            MyText(nm, _G[Font], Lbl_Clr)
            if FP.Lbl_Pos == 'Left' and Lbl_Pos ~= 'No Lbl' then
                SL()
            end
        end
    end

    if LabelOveride then _G[LabelValue] = LabelOveride end


    local MaxTextLength

    im.PushStyleColor(ctx, im.Col_FrameBg, FX[FxGUID][Fx_P].BgClr or 0x444444ff)
    im.PushStyleColor(ctx, im.Col_Text, V_Clr)
    local PopClr = 2

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
    local function EndCOMBO()
        im.PopStyleColor(ctx, 3)

        im.EndCombo(ctx)

    end

    ---@param ctx ImGui_Context
    ---@return boolean
    ---@return string
    local function begincombo(ctx)
        if FP.V_FontSize then im.PushFont(ctx, _G[V_Font]) end
        if Width or FX[FxGUID][Fx_P].Combo_W then
            im.SetNextItemWidth(ctx, Width or (FX[FxGUID][Fx_P].Combo_W + (ExtraW or 0)))
        else 
            local sz = im.CalcTextSize(ctx, LabelOveride or _G[LabelValue])
            im.SetNextItemWidth(ctx, sz+ (ExtraW or 0))
        end
        im.PushStyleColor(ctx, im.Col_Text, V_Clr)
        local rv = im.BeginCombo(ctx, '## ' .. tostring(Label), LabelOveride or _G[LabelValue], im.ComboFlags_NoArrowButton)
        MakeItemEditable(FxGUID, Fx_P, FP.Sldr_W, 'Selection', curX, CurY)
        
        if FP.V_FontSize then im.PopFont(ctx) end

        im.PopStyleColor(ctx)
        if rv  then
            -----Style--------
            im.PushStyleColor(ctx, im.Col_Header, 0x44444433)
            local AccentClr = im.GetColor(ctx, im.Col_SliderGrabActive)
            im.PushStyleColor(ctx, im.Col_HeaderHovered, AccentClr)
            im.PushStyleColor(ctx, im.Col_Text, 0xffffffff)
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
                        EndCOMBO()
                        return true, _G[LabelValue]
                    end
                end
                EndCOMBO()
            else
                for i = 1, #OPs, 1 do
                    if OPs[i] and OPs[i]~='' then 
                        if im.Selectable(ctx, OPs[i], i) and WhichPrm ~= nil then
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, WhichPrm, V[i])
                            _, _G[LabelValue] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, WhichPrm)
                            EndCOMBO()
                            return true, _G[LabelValue]
                        end
                    end
                end
                EndCOMBO()
            end

            local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx)
            local lineheight = im.GetTextLineHeight(ctx)
            local drawlist = im.GetForegroundDrawList(ctx)

            im.DrawList_AddRectFilled(drawlist, L, T + lineheight / 8, R, B - lineheight / 8, 0x88888844, Rounding)
            im.DrawList_AddRect(drawlist, L, T + lineheight / 8, R, B - lineheight / 8, 0x88888877, Rounding)
        else
            if Style == 'Pro C 2' and LBtnRel then
                ProC.ChoosingStyle = false
            end
        end
        -- DnD_PLink_TARGET(FxGUID, Fx_P, FX_Idx, P_Num)
    end

    local rv, v_format = begincombo(ctx)

    local ExtraW = Draw_Native_Styles()

    Draw_Attached_Drawings(FP,FX_Idx, pos,FP.V,nil, FxGUID)

    if FP.Lbl_Pos == 'Right' then
        SL()
        im.AlignTextToFramePadding(ctx) --[[ im.Text(ctx,FP.CustomLbl or FP.Name)  ]]
        MyText(LabelOveride or FP.CustomLbl or CustomLbl or FP.Name, _G[Font], Lbl_Clr)
    elseif FP.Lbl_Pos == 'Bottom' then
        MyText(LabelOveride or FP.CustomLbl or CustomLbl or FP.Name, _G[Font], Lbl_Clr)
    end

    --im.PopStyleVar(ctx)
    im.EndGroup(ctx)
    im.PopStyleVar(ctx)
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
function AddSwitch(LT_Track, FX_Idx, Value, P_Num, BgClr, Lbl_Type, Fx_P, F_Tp, FontSize, FxGUID, image)
    local clr, TextW, Font
    FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
    local FP = FX[FxGUID][Fx_P]
    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, FP.Height or 3)
    local pos = {im.GetCursorScreenPos(ctx)}
    local V_Clr = FP.V_Clr_At_Full and BlendColors(FP.V_Clr, FP.V_Clr_At_Full, FP.V)    or FP.V_Clr or getClr(im.Col_Text)
    local Lbl_Clr = FP.Lbl_Clr_At_Full and BlendColors(FP.Lbl_Clr, FP.Lbl_Clr_At_Full, FP.V) or FP.Lbl_Clr or getClr(im.Col_Text)
    --local V_Font = 'Arial_' .. roundUp(FP.V_FontSize or LblTextSize or Knob_DefaultFontSize, 1)

    --local Font = FontSize and 'Arial_' .. roundUp(FontSize, 1)
    
    local Font, V_Font = GetFonts(FP)

    --[[ if FontSize then
        Font = 'Arial_' .. roundUp(FontSize, 1); im.PushFont(ctx, _G[Font])
    end ]]
    local popClr

    local function Write_Lable()
        local txt = FP.CustomLbl or FP.Name
        if FP.Lbl_Pos == 'Top' then

    
            MyText(txt, _G[Font], Lbl_Clr)
        end
    end
    local function pushClr()

        if FP.V_Pos =='Within' then 
            im.PushStyleColor(ctx, im.Col_Text, V_Clr) 
            return 1
        else

        end
    end

    local function Calc_Text_Size_And_Lbl()
        local lbl
        if FP.V_Pos == 'None' or FP.V_Pos == 'Free' then
            lbl = ' '
        elseif FP.V_Pos == 'Within' then
    
            im.PushFont(ctx, _G[V_Font])
            _, lbl = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
            TextW = im.CalcTextSize(ctx, lbl)
        elseif Lbl_Type == 'Use Prm Name as Lbl' then
            lbl = FP.Name
            TextW = im.CalcTextSize(ctx, lbl)
        elseif Lbl_Type and Lbl_Type ~= 'Use Prm Name as Lbl' then
            lbl = Lbl_Type
            TextW = im.CalcTextSize(ctx, Lbl_Type)
            FP.Switch_W = TextW
        else --Use Value As Label
            _, lbl = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
        end
        if FP.Lbl_Pos == 'Within' then 
            lbl = FP.CustomLbl or FP.Name 
            im.PushFont(ctx,  _G[Font])
        end

        return lbl, TextW
    end
    local function applyButtonColors()
        if FP.Switch_On_Clr then
            if FP.V == (FP.SwitchTargV or 1) then
                popClr = 2
                im.PushStyleColor(ctx, im.Col_Button, FP.Switch_On_Clr)
                im.PushStyleColor(ctx, im.Col_ButtonHovered, Change_Clr_A(FP.Switch_On_Clr, -0.2))
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
    end

    im.BeginGroup(ctx)

    local txt = FP.CustomLbl or FP.Name
    local FormatPV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)
    Before_Main__Write_Label_And_Value_For_Sldr_and_Drag(txt, Font,V_Font, FormatPV, FP, FP.Lbl_Pos, FP.V_Pos)
    Write_Lable()
    local lbl, TextW =  Calc_Text_Size_And_Lbl()




    FP.V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) 
    
    applyButtonColors()


    local PopClr_Value =   pushClr()

    if not FP.Image and not image then

        im.Button(ctx, lbl .. '##' .. FxGUID .. Fx_P, FP.Sldr_W or TextW)
    else -- if there's an image
        local img = FP.Image or image

        uvmin, uvmax, w, h = Calc_strip_uv(img, FP.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num))

        im.InvisibleButton(ctx, lbl .. '##' .. FxGUID .. Fx_P, FP.Sldr_W or 30, FP.Sldr_W or 30)
        local l, t = im.GetItemRectMin(ctx)
        local r, b = im.GetItemRectMax(ctx)
        local clr = FP.BgClr
        if FP.V == 1 then
            clr = FP.Switch_On_Clr
        end
        im.DrawList_AddImage(WDL, img, l, t , r,b, 0, uvmin, 1, uvmax, clr)
        --[[ im.ImageButton(ctx, lbl .. '##' .. FxGUID .. Fx_P, FP.Image, FP.Sldr_W or 30, FP.Sldr_W or 30, 0,
            uvmin, 1, uvmax, FP.BgClr or 0xffffff00) ]]

    end
    MakeItemEditable(FxGUID, Fx_P, FP.Sldr_W, 'Switch', curX, CurY)



    if im.IsItemClicked(ctx, 0) then
        if FP.SwitchType == 'Momentary' then
            FP.V = FP.SwitchTargV
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FP.SwitchTargV or 0)
            if im.IsItemDeactivated(ctx) then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, FP.SwitchBaseV or 1)
            end
        else -- if it's a toggle
            local Value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
            if Value == 0 then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 1)
                FP.V = 1
            elseif Value == 1 then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0)
                FP.V = 0
            end
        end
    end


    Draw_Attached_Drawings(FP,FX_Idx, pos, FP.V,nil, FxGUID)



    --Sync Value if user tweak plugin's actual GUI.

    if focusedFXState == 1 and LT_FXGUID == FxGUID and LT_ParamNum == P_Num and not FP.WhichCC then
        FP.V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    end

    if FP.SwitchType == 'Momentary' then
        clr = 0x00000000
    else
        if FP.V == 0 then clr = 0x00000022 else clr = 0xffffff22 end
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
            FP.V_Clr or getClr(im.Col_Text), lbl)
    end
    if FP.V_Pos == 'Within' then im.PopFont(ctx) end
    if FP.Lbl_Pos == 'Within' then im.PopFont(ctx) end

    im.EndGroup(ctx)


    im.PopStyleVar(ctx)
    --if FontSize then im.PopFont(ctx) end
    if popClr then im.PopStyleColor(ctx, popClr) end
    if PopClr_Value then im.PopStyleColor(ctx, PopClr_Value) end 
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
                 item_inner_spacing, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, DragDir, AllowInput, Height)
    local FxGUID = FxGUID or r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    if not FxGUID then return end
    FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}

    --local FxGUID = FXGUID[FX_Idx]
    local FP = FX[FxGUID][Fx_P]
    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, Height or FP.Height or Df.Sldr_H)
    

    if FX[FxGUID].Morph_Value_Edit or (Mods == Alt + Ctrl and is_hovered) then im.BeginDisabled(ctx) end
    local radius_outer = 20.0

    local pos = { im.GetCursorScreenPos(ctx) }

    local line_height = im.GetTextLineHeight(ctx); local draw_list = im.GetWindowDrawList(ctx)

    local f_draw_list = im.GetForegroundDrawList(ctx)
    local _, Format_P_V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, P_Num)


    local mouse_delta = { im.GetMouseDelta(ctx) }
    local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]

    local Font, V_Font = GetFonts(FP)


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
    BgClr = FP.Invisible and INVISI_CLR or BgClr
    im.PushStyleColor(ctx, im.Col_FrameBg, BgClr or FP.BgClr or im.GetColor(ctx, im.Col_FrameBg))
    im.PushStyleColor(ctx, im.Col_FrameBgActive, FP.BgClrAct or im.GetColor(ctx, im.Col_FrameBgActive))
    im.PushStyleColor(ctx, im.Col_FrameBgHovered, FP.BgClrHvr or im.GetColor(ctx, im.Col_FrameBgHovered))




    Before_Main__Write_Label_And_Value_For_Sldr_and_Drag(labeltoShow, Font,V_Font, Format_P_V, FP, Lbl_Pos, V_Pos)
    im.SetNextItemWidth(ctx, Sldr_Width)
    local DragSpeed = 0.01
    if Mods == Shift then DragSpeed = 0.0003 end
    if DraggingMorph == FxGUID then p_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end


    local flag
    if AllowInput == 'NoInput' then flag = im.SliderFlags_NoInput end
    if Style == 'FX Layering' then im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 0) end



    _, p_value = im.DragDouble(ctx, label, p_value, DragSpeed, v_min, v_max, ' ', im.SliderFlags_NoInput)
    MakeItemEditable(FxGUID, Fx_P, FP.Sldr_W, 'Drag', curX, CurY)

    

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
    If_V_Pos_Is_Only_When_Active(FP, is_active, Format_P_V)

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

    if not SliderStyle and not FP.Invisible then
        if DragDir == 'Right' or DragDir == nil then
            if is_active then
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, FP.GrbAct or 0xffffff77, Rounding)
            elseif is_hovered then
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, FP.GrbHvr or 0xffffff55, Rounding)
            else
                im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, FP.GrbClr or 0xffffff44, Rounding)
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
                im.DrawList_AddRectFilled(draw_list, PosR, PosT, PosL + SldrGrbPos, PosB, FP.GrbAct or 0xffffff77, Rounding)
            elseif is_hovered then
                im.DrawList_AddRectFilled(draw_list, PosR, PosT, PosL + SldrGrbPos, PosB, FP.GrbHvr or 0xffffff55, Rounding)
            else
                im.DrawList_AddRectFilled(draw_list, PosR, PosT, PosL + SldrGrbPos, PosB, FP.GrbClr or 0xffffff44, Rounding)
            end
        end
    elseif SliderStyle == 'Pro C' or SliderStyle == 'Pro C Lookahead' then
        if is_active then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xFFD571bb, Rounding)
        elseif is_hovered then
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0xDFB973bb, Rounding)
        else
            im.DrawList_AddRectFilled(draw_list, PosL, PosT, math.max(PosL + SldrGrbPos, PosL), PosB, 0x888888bb, Rounding)
        end
    end


    if Disable == 'Disabled' then
        im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosL + SldrGrbPos, PosB, 0x222222bb, Rounding)
    end
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
    local cur_value = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

    local tooltip_Tirgger = (is_active or is_hovered) and (FP.V_Pos == 'None' or not FP.V_Pos or Style == 'Pro C' or Style == 'Pro C Lookahead')

    local SzX, SzY = im.GetItemRectSize(ctx)
    local MsX, MsY = im.GetMousePos(ctx)
    Show_Value_Tooltip(tooltip_Tirgger, SetMinMax(MsX, pos[1], pos[1] + SzX), pos[2] - SzY - line_height --[[ + button_y ]] , Format_P_V )



    --if user tweak drag on ImGui
    if Tweaking == P_Num .. FxGUID then
        if not FP.WhichCC then
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
            FX[FxGUID][Fx_P].V = p_value

        else
            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, LT_FXNum, "param." .. P_Num .. ".plink.active", 0) -- 1 active, 0 inactive
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
        end
    end


    if AssigningMacro then

        im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosR, PosB, EightColors.bgWhenAsgnMod[AssigningMacro] or 0xffff33ff)
    end


    local AlreadyAddPrm = false

    Highlight_Prm_If_User_Use_Actual_UI_To_Tweak(draw_list, PosL, PosT, PosR, PosB, FP,FxGUID)
    --[[ if Tweaking == P_Num..FxGUID and IsLBtnHeld == false then
        if FP.WhichMODs  then
            r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX'..FxGUID..'Prm'..Fx_P.. 'Value before modulation' , FX[FxGUID][Fx_P].V, true    )
            r.gmem_write(7, CC) --tells jsfx to retrieve P value
            PM.TimeNow= r.time_precise()
            r.gmem_write(JSFX.P_ORIG_V+CC , p_value)
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

    Write_Label_And_Value_All_Types(FP, pos, draw_list, labeltoShow ,  CenteredLblPos, Font, V_Font , Format_P_V, Lbl_Pos)

    After_Main__Write_Label_And_Value_For_Sldr_and_Drag(labeltoShow, Font,V_Font, Format_P_V, FP, Lbl_Pos, V_Pos)

    Draw_Attached_Drawings(FP,FX_Idx, pos, cur_value,nil, FxGUID)
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
    im.Dummy(ctx,10,10)
    im.EndGroup(ctx)
    if item_inner_spacing then im.PopStyleVar(ctx) end
    if FX[FxGUID].Morph_Value_Edit or is_hovered and Mods == Alt + Ctrl then im.EndDisabled(ctx) end

    im.PopStyleVar(ctx)
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

    if not LT_Track then return end
    TREE = BuildFXTree(LT_Track or tr)

    for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
        local PrmInst, Line, FX_Name
        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
        
        --local file = CallFile('r', FX_Name..'.ini', 'FX Layouts')

        local function GetInfo(FxGUID, FX_Idx)
            if not FxGUID then return end
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
                    FP.Lbl_FONT            = v.Lbl_FONT
                    FP.Val_FONT            = v.Val_FONT
                    FP.Lbl_Italic          = v.Lbl_Italic
                    FP.Val_Italic          = v.Val_Italic
                    FP.Lbl_Bold            = v.Lbl_Bold
                    FP.Val_Bold            = v.Val_Bold
                    FP.Image               = v.Image
                    FP.ImgFilesName        = v.ImgFilesName
                    FP.ConditionPrm        = v.ConditionPrm
                    FP.ConditionPrm_V      = v.ConditionPrm_V
                    FP.ConditionPrm_V_Norm = v.ConditionPrm_V_Norm
                    FP.Switch_On_Clr       = v.Switch_On_Clr
                    FP.Invisible           = v.Invisible
                    FP.ImgAngleMinOfs      = v.ImgAngleMinOfs
                    FP.DontRotateImg       = v.DontRotateImg
                    FP.V_Clr_At_Full     = v.V_Clr_At_Full
                    FP.Lbl_Clr_At_Full   = v.Lbl_Clr_At_Full
                    FP.XY_Pad_Y_PNum     = v.XY_Pad_Y_PNum
                    
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
                local dir_path = ConcatPath(CurrentDirectory, 'src', 'FX Layouts')
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



                    T.MorphHide = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph Hide' .. FxGUID, 'true', true)
                    T.Round = RecallGlobInfo(Ct, 'Edge Rounding = ', 'Num')
                    T.GrbRound = RecallGlobInfo(Ct, 'Grb Rounding = ', 'Num')
                    T.BgClr = RecallGlobInfo(Ct, 'BgClr = ', 'Num')
                    T.Width = RecallGlobInfo(Ct, 'Window Width = ', 'Num')
                    T.TitleWidth = RecallGlobInfo(Ct, 'Title Width = ', 'Num')
                    T.TitleClr = RecallGlobInfo(Ct, 'Title Clr = ', 'Num')
                    T.CustomTitle = RecallGlobInfo(Ct, 'Custom Title = ')
                    PrmInst = RecallGlobInfo(Ct, 'Param Instance = ', 'Num')
                    FX[FxGUID].FileLine = nil 
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

                            local Ct = extract_prm_sections(Ct, Fx_P)

                            
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
                            FP.Lbl_FONT      = RecallInfo(Ct, 'Label Font', Fx_P)
                            FP.Val_FONT      = RecallInfo(Ct, 'Value Font', Fx_P)
                            FP.Lbl_Italic      = RecallInfo(Ct, 'Label Font Italic', Fx_P, 'Bool')
                            FP.Lbl_Bold      = RecallInfo(Ct, 'Label Font Bold', Fx_P, 'Bool')
                            FP.Val_Italic      = RecallInfo(Ct, 'Value Font Italic', Fx_P, 'Bool')
                            FP.Val_Bold      = RecallInfo(Ct, 'Value Font Bold', Fx_P, 'Bool')


                            FP.Invisible     = RecallInfo(Ct, 'Invisible', Fx_P, 'Bool')
                            FP.DontRotateImg       = RecallInfo(Ct, 'DontRotateImg', Fx_P, 'Bool')
                            FP.ImgAngleMinOfs      = RecallInfo(Ct, 'ImgAngleMinOfs', Fx_P, 'Num')
                            FP.V_Clr_At_Full        = RecallInfo(Ct, 'V_Clr_At_Full', Fx_P, 'Num')
                            FP.Lbl_Clr_At_Full      = RecallInfo(Ct, 'Lbl_Clr_At_Full', Fx_P, 'Num')

                            local FileName       = RecallInfo(Ct, 'Custom Image', Fx_P)

                            if FileName then
                                local FileName = TruncatePath(FileName)
                                FP.ImgFilesName = FileName
                                FP.Style = 'Custom Image'
                                local SUBFOLDER 
                                if FP.Type =='Knob' then SUBFOLDER = 'Knobs'
                                elseif FP.Type == 'Switch' then SUBFOLDER = 'Switches' 
                                end
                                if SUBFOLDER then 
                                    local dir_path = ConcatPath(CurrentDirectory , 'src', 'Images', SUBFOLDER, FileName)
                                    FP.Image = im.CreateImage(dir_path)
                                    im.Attach(ctx, FP.Image)
                                end
                            end


                            FP.ConditionPrm = RecallInfo(Ct, 'Condition Param', '\n' .. Fx_P, 'Num', '|')
                            for i = 2, 5, 1 do
                                FP['ConditionPrm' .. i] = RecallInfo(Ct, 'Condition Param' .. i, Fx_P, 'Num', '|')
                            end
                            FP.V_Round = RecallInfo(Ct, 'Decimal Rounding', Fx_P, 'Num')
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
                                StoreNewParam(FxGUID, FP.Name, FP.Num, FX_Idx, 'Not Deletable', 'AddingFromExtState', Fx_P, FX_Idx, TrkID)
                                r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added', 'true')
                            end

                            FP.ManualValues = RecallIntoTable(Ct, Fx_P .. '. Manual V:1=', Fx_P, 'Num')
                            FP.ManualValuesFormat = RecallIntoTable(Ct, Fx_P .. '. Manual Val format:1=', Fx_P)
                            
                            Retrieve_Attached_Drawings(Ct, Fx_P, FP)

                        end
                        GetProjExt_FxNameNum(FxGUID, LT_Track)
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
                                FP.SwitchType   = nil
                                FP.SwitchBaseV  = nil
                                FP.SwitchTargV  = nil
                                FP.V_Clr_At_Full = nil
                                FP.Lbl_Clr_At_Full = nil
                                FP.Invisible    = nil
                                FP.ImgAngleMinOfs = nil
                                FP.DontRotateImg = nil
                                FP.Lbl_Clr_At_Full = nil
                                for i = 2, 5, 1 do
                                    FP['ConditionPrm' .. i] = nil
                                    FP['ConditionPrm_V' .. i] = nil
                                    FP['ConditionPrm_V_Norm' .. i] = nil
                                end
                                FP.ManualValues = nil

                            end
                        end
                        GetProjExt_FxNameNum(FxGUID, LT_Track)
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
                            D.BgImgFileName = RecallInfo(Ct, 'ImagePath', 'D' .. i)
                            D.KeepImgRatio = RecallInfo(Ct, 'KeepImgRatio', 'D' .. i, 'Bool')
                            D.Font = RecallInfo(Ct,'Font' ,'D' .. i)
                            D.FtSize = RecallInfo(Ct,'FontSize', 'D' .. i, 'Num')
                            D.Font_Bold = RecallInfo(Ct,'FontBold', 'D' .. i, 'Bool')
                            D.Font_Italic = RecallInfo(Ct,'FontItalic','D' .. i, 'Bool')
                            D.Fill = RecallInfo(Ct,'Fill', 'D' .. i, 'Bool')
                            D.Repeat = RecallInfo(Ct,'Repeat', 'D' .. i, 'Num')
                            D.RepeatClr = RecallInfo(Ct,'RepeatClr', 'D' .. i, 'Num')
                            D.XGap = RecallInfo(Ct,'XGap', 'D' .. i, 'Num')
                            D.YGap = RecallInfo(Ct,'YGap', 'D' .. i, 'Num')
                            D.Gap = RecallInfo(Ct,'Gap', 'D' .. i, 'Num')
                            D.Thick = RecallInfo(Ct,'Thick', 'D' .. i, 'Num')
                            if D.BgImgFileName then
                                
                                local dir_path = ConcatPath(CurrentDirectory , 'src', 'Images', 'Backgrounds', D.BgImgFileName)
                                D.Image = im.CreateImage(dir_path)
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
    if FX[FxGUID][P] and FX[FxGUID][P].Num then return end 

    local P



    if AddingFromExtState == 'AddingFromExtState' then
        P = Fx_P
    else
        FX[FxGUID] = FX[FxGUID] or {}
        -- local Index = #FX[FxGUID] or 0
        table.insert(FX[FxGUID], Fx_P)
        FX[FxGUID].PrmCount = (FX[FxGUID].PrmCount or 0) + 1

        P = #FX[FxGUID] + 1
    end

    Save_to_Trk('Prm Count'..FxGUID,P, LT_Track)



    FX[FxGUID][P] = FX[FxGUID][P] or {}
    FX[FxGUID][P].Num = P_Num
    FX[FxGUID][P].Name = P_Name
    FX[FxGUID][P].Deletable = IsDeletable

    if not P_Name then return end 
    Save_to_Trk('FX'..P..'Name'..FxGUID, P_Name, LT_Track)
    Save_to_Trk('FX'..P..'Num'..FxGUID, P_Num, LT_Track)
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
function Save_Attached_Drawings(FP, file,Fx_P)

    if FP.Draw then
        local function Save_total_number_of_drawings()
            local Index = 0
            for D, v in ipairs(FP.Draw) do
                if v[1] then 
                    for I, V in ipairs(v) do 
                        Index = Index + 1 
                    end
                else 
                    Index = Index + 1 
                end
            end

            if Fx_P then 
                file:write(Fx_P.. '. Number of attached drawings = ', Index or '', '\n')
            else
                file:write('Number of attached drawings = ', Index or '', '\n')
            end
        end

        Save_total_number_of_drawings()         
        local Index = 1 
        for D, v in ipairs(FP.Draw) do
            
            
            local function Save_All_Info(Index, V )
                local D = Index and Index or D 

                local v = V or v
                local function WRITE(name, val, Index)
                    local D = Index and Index or D 
    
                    local val = tostring(val)
                    if val =='nil' then val = nil end 

                    if not val or val ==false or val == 0 or val == '0.0' or val =='false' then return end 
    
                    if Fx_P then 
                        file:write(Fx_P..'. Draw Item ' .. D .. ': ' .. name ..' = ', val or '' ,'\n')
                    else
                        file:write('Draw Item ' .. D .. ': ' .. name ..' = ', val or '' ,'\n')
                    end
                end



                WRITE('Type', v.Type)
                WRITE('X Offset', v.X_Offset)
                WRITE('X Offset Value Affect', v.X_Offset_VA)
                WRITE('X Offset Value Affect BP', v.X_Offset_VA_BP) 

                WRITE('X Offset Value Affect GR', v.X_Offset_VA_GR)
                WRITE('Y offset', v.Y_Offset)
                WRITE('Y offset Size Sync', v.Y_Offset_SS)

                WRITE('Y Offset Value Affect', v.Y_Offset_VA)
                WRITE('Y Offset Value Affect BP', v.Y_Offset_VA_BP)

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
                WRITE('Angle Max VA', v.Angle_Max_VA)
                WRITE('Angle Max VA BP', v.Angle_Max_VA_BP)

                WRITE('Radius Inner', v.Rad_In)
                WRITE('Radius Inner SS', v.Rad_In_SS)
                WRITE('Radius Outer', v.Rad_Out)
                WRITE('Radius Outer SS', v.Rad_Out_SS)
                WRITE('Value Range Low', v.Value_Range_Low)
                WRITE('Value Range High', v.Value_Range_High)
                WRITE('Decimal Places', v.Decimal_Places)
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
                WRITE('RPT_Clr_VA', v.RPT_Clr_VA)
                WRITE('Image_Path', v.AtchImgFileNm)
                WRITE('Fill', v.Fill)
                WRITE('Pointer_Type', v.Pointer_Type)
                WRITE('Shape', v.Shape)
                if v.Type=='Circle' then 
                    WRITE('RPT_Clr2', v.RPT_Clr2)
                    WRITE('Color2', v.Clr2)
                    WRITE('Special_Fill', v.Special_Fill)
                    WRITE('Texture_Angle', v.Texture_Angle)
                    WRITE('Gradient_Start', v.Gradient_Start)
                end
            end


            if v[1] then 
                for I, V in ipairs(v) do 
                    file:write(Fx_P..'. Draw Item ' .. Index .. ': ' .. 'Under Preset' ..' = ', v.Belong_To_Preset or '' ,'\n')

                    Save_All_Info(Index, V)
                    Index = Index + 1 

                end
            else 
                Save_All_Info(Index)
                Index = Index + 1 

            end
        end
    end
end

---@param FX_Name string
---@param ID string ---TODO this param is not used
---@param FxGUID string
function SaveLayoutEditings(FX_Name, FX_Idx, FxGUID)

    local dir_path = ConcatPath(CurrentDirectory, 'src', 'FX Layouts')
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
            write('Type', FP.Type or FX[FxGUID].DefType or 'Slider')
            write('Pos X', FP.PosX)
            write('Pos Y', FP.PosY)
            write('Style', FP.Style)
            write('Value Font Size', FP.V_FontSize)
            write('Custom Label', FP.CustomLbl)
            write('Font Size', FP.FontSize)
            write('Label Font', FP.Lbl_FONT)
            write('Value Font', FP.Val_FONT)
            write('Label Font Italic', FP.Lbl_Italic)
            write('Label Font Bold', FP.Lbl_Bold)
            write('Value Font Italic', FP.Val_Italic)
            write('Value Font Bold', FP.Val_Bold)

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
            write('Custom Image', FP.ImgFilesName)
            write('Invisible', FP.Invisible)
            write('DontRotateImg', FP.DontRotateImg)
            write('ImgAngleMinOfs', FP.ImgAngleMinOfs)

            write('V_Clr_At_Full', FP.V_Clr_At_Full)
            write('Lbl_Clr_At_Full', FP.Lbl_Clr_At_Full)
            write('XY_Pad_Y_PNum', FP.XY_Pad_Y_PNum)




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

            Save_Attached_Drawings(FP, file, Fx_P)
 
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
    local orig_h,orig_sz
    local DfKnobRD = 15

    --set size to 15, and sync all drawing size
    if FP.Sldr_W  then 
        orig_sz = FP.Sldr_W
        if FP.Type == 'Knob' then
            FP.Sldr_W = DfKnobRD
        elseif FP.Type == 'V-Slider' then
            FP.Sldr_W = Df.V_Sldr_W
        end
        
        Sync_Size_Height_Synced_Properties(FP, FP.Sldr_W- orig_sz )
    end
    
    if FP.Height then 
        orig_h = FP.Height
        if FP.Type == 'V-Slider' then
            FP.Height = Df.V_Sldr_H
        else
            FP.Height = Df.Sldr_H
        end
        Sync_Height_Synced_Properties(FP, FP.Height - orig_h)
    end


    Save_Attached_Drawings(FP, file)

    if FP.Sldr_W then 
        -- set size back to original size
        FP.Sldr_W = orig_sz

        local DfSz = FP.Type == 'Knob' and DfKnobRD or Df.Sldr_W

        Sync_Size_Height_Synced_Properties(FP, orig_sz- DfSz )
    end

    if FP.Height then 
        FP.Height =  orig_h 
        local DfH = FP.Type == 'V-Slider' and Df.V_Sldr_H or Df.Sldr_H
        Sync_Height_Synced_Properties(FP, orig_h - DfH )
    end





end


---@param FxGUID string
---@param Fx_P number
---@param ItemWidth number
---@param ItemType 'V-Slider' | 'Sldr' |'Drag' |'Selection'
---@param PosX number
---@param PosY number
function MakeItemEditable(FxGUID, Fx_P, ItemWidth, ItemType, PosX, PosY)
    if FX.LayEdit == FxGUID and Draw.DrawMode~= FxGUID and Mods ~= Cmd  then
        local DeltaX, DeltaY = im.GetMouseDelta(ctx); local MouseX, MouseY = im.GetMousePos(ctx)
        local FP = FX[FxGUID][Fx_P]
        local WinDrawList = im.GetWindowDrawList(ctx)
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
                    -- quantize pos to grid 
                    local diff_X =  roundUp(FP.PosX, LE.GridSize) - FP.PosX 
                    local diff_Y = FP.PosY - roundUp(FP.PosY, LE.GridSize) 
                    FP.PosX = SetMinMax(roundUp(FP.PosX, LE.GridSize), 0,Win_W - (FP.Sldr_W or 15))
                    FP.PosY = SetMinMax(roundUp(FP.PosY, LE.GridSize), 0, 220 - 10)
                    return diff_X, diff_Y
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
            elseif ItemType == 'Knob' or (not ItemType and FX[FxGUID].DefType == 'Knob') then
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
                    if tablefind(LE.Sel_Items, Fx_P) then

                        if IsLBtnClicked and not ChangePrmW then
                            ClickOnAnyItem = true
                            FP.PosX = PosX
                            FP.PosY = PosY
                            local Undo_LBL = #LE.Sel_Items > 1 and 'Change '..#LE.Sel_Items..' Items Position' or 'Change '..FP.Name..' Position'
                            Create_Undo_Point(Undo_LBL , FxGUID)
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
                        local Undo_LBL = #LE.Sel_Items > 1 and 'Resize '..#LE.Sel_Items..' Items' or 'Resize '..FP.Name
                        Create_Undo_Point(Undo_LBL, FxGUID)
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
            elseif ItemType == 'Knob' or (not ItemType and FX[FxGUID].DefType == 'Knob') then
                im.DrawList_AddCircleFilled(WinDrawList, R, B, 3, 0x999999dd)
                if MouseX > R - 5 and MouseX < R + 5 and MouseY > B - 5 and MouseY < B + 3 then
                    im.SetMouseCursor(ctx, im.MouseCursor_ResizeNWSE)
                    im.DrawList_AddCircleFilled(WinDrawList, R, B, 4, 0xbbbbbbff)
                    if IsLBtnClicked then
                        local Undo_LBL = #LE.Sel_Items > 1 and 'Resize '..#LE.Sel_Items..' Items' or 'Resize '..FP.Name
                        Create_Undo_Point(Undo_LBL, FxGUID)
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
            im.DrawList_AddCircleFilled(WinDrawList or im.GetWindowDrawList(ctx), R, T + h / 2, 3, 0x444444ff)
            local MsDragDeltaX, MsDragDeltaY = im.GetMouseDragDelta(ctx); local Dx, Dy = im.GetMouseDelta( ctx)

            if ItemWidth == nil then
                if ItemType == 'Sldr' or ItemType == 'Drag' then
                    ItemWidth = 160
                elseif ItemType == 'Selection' then
                    ItemWidth = FP.Combo_W  or 100
                elseif ItemType == 'Switch' then
                    ItemWidth = FP.Switch_W or 100
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

        local function ChangeKnobRadius(Fx_P)
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


            if LBtnRel and LE.ChangePos == Fx_P  then 

                Qunantize_Item_Pos_To_Grid(FP)
    
            elseif LBtnRel and tablefind(LE.ChangePos, Fx_P)  then  
                local function Quantize()
                    local diff_X, diff_Y = Qunantize_Item_Pos_To_Grid(FX[FxGUID][LE.ChangePos[1]])
                    for i, v in pairs(LE.ChangePos) do
                        if i ~= 1 then
                            FX[FxGUID][v].PosX = FX[FxGUID][v].PosX + (diff_X or 0)
                            FX[FxGUID][v].PosY = FX[FxGUID][v].PosY - (diff_Y or 0)
                        end
                    end
                end
                --Quantize()
            end 
            
        end











        Item_Resize_Handles()

        Highlight_Selected_Itms()
        Mouse_Interaction()
        Allow_Use_Keyboard_To_Edit()    
        Change_Size_or_Move()
        --Marquee_Select_Items()
        LE.Sel_Items = Marquee_Selection({ L+ (R-L)/2 , T+ (B-T)/2}, LE.Sel_Items, Fx_P, 0xffffff88)



        
        

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



function Create_Undo_Point(str , FxGUID)
    LE.Undo_Points = LE.Undo_Points or {}
    FX[FxGUID].Draw =  FX[FxGUID].Draw or {}
    FX[FxGUID].Draw.Preview = nil 
    table.insert(LE.Undo_Points, deepCopy(FX[FxGUID]))
    LE.Undo_Points[#LE.Undo_Points].Undo_Pt_Name = str
end
