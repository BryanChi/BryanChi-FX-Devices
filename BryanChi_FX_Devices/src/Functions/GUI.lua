-- @noindex


function Calculate_Color_Based_On_Nesting_Level(nestingLevel)
    if not nestingLevel then return  0xffffff99  end 
    local baseColor = ThemeClr('Accent_Clr')
    local hueShift = nestingLevel * 0.1 -- Shift hue by 30 degrees per level
    return HSV_Change(baseColor, hueShift, 0.5, 0.5, 0.5, true)
end






function GetCurveValue(x, p, xmin, xmax, ymin, ymax)
    -- Handle boundary conditions explicitly
    if x <= xmin then
        return ymin
    elseif x >= xmax then
        return ymax
    end

    -- Normalize x to the range [0, 1]
    local x_norm = (x - xmin) / (xmax - xmin)
    
    local y_norm
    if p == 0 then
        y_norm = x_norm  -- Linear case
    else
        local p_abs = math.abs(p)
        local scale = (math.exp(p_abs) - 1)

      if p > 0 then
        y_norm = x_norm ^ p  -- 
      else
        y_norm = 1 - (1 - x_norm) ^ p_abs
      end
    end

    
    -- Scale y_norm back to the range [ymin, ymax]
    local y = ymin + y_norm * (ymax - ymin)
    
    return y
end


function Drag_With_Bar(ctx, str, v, v_speed, v_min, v_max, format, flags, clr)
    
    local rv, v = im.DragDouble(ctx, '##'..str, v, v_speed, v_min, v_max, format, flags)
    local x, y = im.GetItemRectMin(ctx)
    local w, h = im.GetItemRectSize(ctx)
    local v_norm = v/(v_max - v_min)
    local WDL = WDL or im.GetWindowDrawList(ctx)
    im.DrawList_AddRectFilled(WDL , x, y, x+w * v_norm , y+h, clr or 0xffffff44)
    SL()
    im.Text(ctx, str)
    return rv, v 
end


function RenderChoiceButtons(v, Choices, ChoiceName)
    local Choices = Choices or v.Choices
    if not Choices then return end
    im.BeginGroup(ctx)
    local WDL = im.GetWindowDrawList(ctx)
    local btn_click 
    for i, V in ipairs(Choices) do 
        local CN = V.V_Form or (ChoiceName and ChoiceName[i]) or V.ChoiceName
        local NeedPop 
        if v.GrbClr and v.Chosen == CN then 
            im.PushStyleColor(ctx, im.Col_Button, v.GrbClr)
            im.PushStyleColor(ctx, im.Col_ButtonHovered, v.GrbClr)
            im.PushStyleColor(ctx, im.Col_ButtonActive, v.GrbClr)
            NeedPop =3 
        end
        if im.Button(ctx, (CN or '')..'##', v.Sldr_W, nil) then 
            v.Chosen = CN
            v.CurrentOps = i
            btn_click = i 
        end

        if NeedPop then 
            im.PopStyleColor(ctx,NeedPop)
        end


        if v.Chosen and v.Chosen ~= CN then 
            Highlight_Itm(WDL, 0x00000044)
        end
        if v.Is_Horizontal then 
            SL(nil, v.Spacing or 0)
        else 
            local pos = {im.GetCursorPos(ctx)}
            im.SetCursorPos(ctx, pos[1], pos[2] + (v.Spacing or 0))
            im.Dummy(ctx, 0, 0)
        end


        
    end
    im.EndGroup(ctx)
    if btn_click then return btn_click end 
end

------------- Buttons/Knobs -------------
function InvisiBtn(ctx, x, y, str, w, h)
    if x and y then
        im.SetCursorScreenPos(ctx, x, y)
    end
    local rv = im.InvisibleButton(ctx, str, w, h or w)
    return rv
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
function RoundBtn (W,H , lbl, clr, fillclr, fillsz)
    local rv = im.InvisibleButton(ctx, lbl, W, H ) 
    local L, T = im.GetItemRectMin(ctx)
    local x , y =  L + W/2 , T + H /2
    local WDL= WDL or im.GetWindowDrawList(ctx)
    im.DrawList_AddCircle(WDL ,x,y , W/2 , clr )
    if fillclr and fillsz then 
        im.DrawList_AddCircleFilled(WDL ,x,y , fillsz , fillclr )

    end
   -- im.DrawList_AddRect(WDL or im.GetWindowDrawList(ctx), L, T , L+W, T+H, clr) 
    if im.IsItemHovered(ctx) or im.IsItemActive(ctx) then 
        GLOWING_CIRCLE( {x,y}, W/2 , W/2 + 5, 0xffffff99 , 0xffffff33, WDL)
    end
    if im.IsItemActive(ctx) then  
        --im.DrawList_AddCircleFilled(WDL ,x,y , W/3 , 0x000000ff )
        im.DrawList_AddCircle(WDL ,x,y , W/1.8 , clr, nil,3 )
        local active = true
        local DtX, DtY = im.GetMouseDelta(ctx)
        return DtX, DtY, active
    end

end



function draw_dotted_line(x1, y1, x2, y2, clr, segment_length, gap)
    local ImGui = reaper.ImGui
    
    -- Calculate the total length of the line
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Normalize the direction vector
    local direction_x = dx / distance
    local direction_y = dy / distance

    -- Calculate total number of segments and gaps combined (how many steps we take)
    local total_steps = math.floor(distance / (segment_length + gap))

    -- Use a for loop to iterate over the segments
    for i = 0, total_steps do
        -- Start point of the segment
        local current_length = i * (segment_length + gap)
        local start_x = x1 + direction_x * current_length
        local start_y = y1 + direction_y * current_length
        
        -- End point of the segment
        local end_length = math.min(current_length + segment_length, distance)
        local end_x = x1 + direction_x * end_length
        local end_y = y1 + direction_y * end_length

        -- Draw the line segment
        im.DrawList_AddLine(im.GetWindowDrawList(ctx), start_x, start_y, end_x, end_y, clr or im.ColorConvertDouble4ToU32(1, 1, 1, 1)) -- white line
    end
end

--[[ 
function DrawLogCurve (x1,y1, x2, y2, clr, thick , scale)
    local rpt = x2-x1 
    local scale = scale or 2 
    local x1, y1, x2, y2 = x1, y1 , x1+1 
    for i=x1, rpt , 1 do 
        local y1 = scale*math.exp(y1)
        local y2 = scale*math.exp(y2)

        im.DrawList_AddLine(WDL, i, y1, i+1, y2, clr, 5)
    end
end
 ]]


 function TransformLinearToLogOrExp(x_start, x_end, y_start, y_end, scale_factor, num_points)
    local points = {}  -- Table to store transformed points

    for i = 0, num_points do
        -- Calculate the x value in the linear range
        local x = x_start + (x_end - x_start) * (i / num_points)
        
        -- Calculate the corresponding linear y value
        local linear_y = y_start + (y_end - y_start) * (i / num_points)
        local transformed_y

        if scale_factor > 0 then
            -- Logarithmic transformation
            if x <= 0 then
                transformed_y = y_start  -- Handle non-positive x by returning the starting y value
            else
                transformed_y = y_start + (math.log(x) / math.log(scale_factor)) * (y_end - y_start)
            end
        elseif scale_factor < 0 then
            -- Exponential transformation
            transformed_y = y_start + (-scale_factor * math.exp(x)) * (y_end - y_start)
        else
            -- No transformation
            transformed_y = linear_y
        end

        -- Store the transformed point
        table.insert(points, {x, transformed_y})
    end
    
    return points  -- Return the table of transformed points
end


function Draw_Single_Curve(nX, X, nY, Y, curve , thick , lineClr, ofs)
    local range = nX - X
    local Pts = { x = {}, y = {} }
    local inc = 0.5
    for i = X, nX, inc do
        local I = (i - X) / (nX - X)
        local y = (Y + (nY - Y) * I)
        local y = GetCurveValue(y, curve or 0, math.min(Y, nY), math.max(Y, nY), math.min(Y, nY), math.max(Y, nY))
        table.insert(Pts.y, y)
        table.insert(Pts.x, i)
    end
    local WDL = WDL or im.GetWindowDrawList(ctx)
    if nX == X then

        im.DrawList_AddLine(WDL, X + ofs, Y + ofs, nX + ofs, nY + ofs, lineClr, thick)
    end

    for i, v in ipairs(Pts.x) do
        if i ~= #Pts.x then
            local x1, y1 = v + ofs, Pts.y[i] + ofs
            im.DrawList_PathLineTo(WDL, x1, y1)
        else
            im.DrawList_PathLineTo(WDL, nX + ofs, nY + ofs)
            im.DrawList_PathStroke(WDL, lineClr, nil, thick)
        end
    end
end
function Draw_Curve (WDL, PtsTB , i , L, R, B, W, H, PtSz , lineClr, thick, zoom, center)
    local lineClr = lineClr or 0xffffff99
    local v = PtsTB[i]
    if not v or type(v)~= 'table' then return end 
    local zoom = zoom or 1
    local center = center or 0.5
    local function map_u(u)
        return ((u - center) * zoom + 0.5)
    end
    local X, Y = L + map_u(v[1]) * W , B - v[2] * H 
    if PtsTB[i+1] then 
        local n = PtsTB[i+1]
        local nX , nY = L + map_u(n[1]) * W ,  B - n[2] * H 
        local DtX, DtY
        local ofs = PtSz/2
        local x1, y1, x2, y2 = X+ofs, Y+ofs , nX+ofs ,  nY+ofs
        local mX, mY = im.GetMousePos(ctx)
        if not v[3] then 
            im.DrawList_AddLine(WDL, x1, y1, x2, y2, lineClr, thick)
        else
            Draw_Single_Curve(nX, X, nY, Y, v[3] , thick,lineClr, ofs)
        end
    end

end
function CurveEditor(W,H, PtsTB, lbl , MacroTB, IsContainer)
    local IsLFO = lbl:find('LFO') and true or false
    local gmem_space = IsContainer and 'ContainerMacro' or 'ParamValues'
    local Macro = MacroTB and MacroTB.Num
    local Mc = MacroTB
    -- Both LFO and Envelope types use the same system, so ensure IsLFO is true for both
    if Mc and (Mc.Type == 'LFO' or Mc.Type == 'Envelope' or Mc.Type == 'envelope') then
        IsLFO = true
    end
    local Pad = 15
    local PtSz = 15
    local x, y = im.GetCursorPos(ctx)
    local LBtnDC =  im.IsMouseDoubleClicked(ctx, 0 ) 
    local WDL = im.GetWindowDrawList(ctx)
    local thick = 4
    local lineClr = 0xffffff99
    local NoteOnVel = r.gmem_read(91)

    
    

    r.gmem_attach(gmem_space)
    r.gmem_write(8, 1+ Get_MidiMod_Ofs(lbl)) -- tells jsfx the curve editor is open ,and so it needs to send back velocity or random 's values'


    local function DrawGrid()
        local x, y = im.GetCursorScreenPos(ctx)
        local P = PtSz/2 
        local L , R = x + P , x + W - P
        local zoom = (IsLFO and (Mc and (Mc.Zoom or 1) or 1)) or 1
        local center = (IsLFO and (Mc and (Mc.ZoomCenter or 0.5) or 0.5)) or 0.5
        local innerW = (W - P)
        local Gd = (IsLFO and (Mc and Mc.LFO_leng)) or (LFO and LFO.Def and LFO.Def.Len) or 4
        Gd = tonumber(Gd) or 4
       

        local  Clr1 , Clr2 = 0xffffff55 , 0xffffff22
        -- Center vertical line (only for non-LFO editors)
        if not IsLFO then
            draw_dotted_line(L + W/2 ,y, L+W/2 , y+H, Clr1, 3, 2)
        end
        draw_dotted_line(L  ,y + H/2 , R , y+H/2, Clr1, 3, 2)-- center y axis

        -- Vertical grid lines based on LFO length (always Gd-1 lines)
        if IsLFO and Gd >= 1 then
            for i = 1, Gd - 1, 1 do
                local t = i / Gd
                local xLine = L + (((t - center) * zoom) + 0.5) * innerW
                draw_dotted_line(xLine, y, xLine, y + H, Clr2, 3, 2)
            end
        else
            -- Fallback quarter lines when not LFO
            draw_dotted_line(L + W/4 ,y, L+W/4 , y+H, Clr2, 3, 2)
            draw_dotted_line(L +W - W/4 ,y, L+W - W/4, y+H, Clr2, 3, 2)
        end

        draw_dotted_line(L  ,y + H/4 , R , y+H/4, Clr2, 3, 2)-- center y axis
        draw_dotted_line(L  ,y + H - H/4 , R , y+H -H/4, Clr2, 3, 2)-- center y axis



        im.DrawList_AddLine(WDL, L , y , L , y+H , 0xffffff33, 2)
        im.DrawList_AddLine(WDL, L+W, y , L+W , y+H , 0xffffff33, 2)
        im.DrawList_AddLine(WDL, L, y , L+W , y , 0xffffff33, 2)
        im.DrawList_AddLine(WDL, L, y+H , L+W , y+H , 0xffffff33, 2)


    end




    local function SaveCurve()
        for i, v in ipairs(PtsTB) do 
            Save_to_Trk(lbl..' curve pt'..i..'x', v[1]  )
            Save_to_Trk(lbl..' curve pt'..i..'y', v[2] )
        end
        Save_to_Trk(lbl.. 'Curve number of points', #PtsTB)

    end
    
    local function Show_Played_Notes_Velocity(X, nX, Y , nY ,L, B, W, H, curve, i  )
        local function AddPt(x, y )
            table.insert(Midi_Mod_Indicator , {})
            Midi_Mod_Indicator[#Midi_Mod_Indicator].x = x 
            Midi_Mod_Indicator[#Midi_Mod_Indicator].y = y
            Midi_Mod_Indicator[#Midi_Mod_Indicator].time = 0
            r.gmem_write(91, -1)
        end

        local function ConvertScreenY(y)
            return B- y * (H + PtSz /2 )
        end
        local function ConvertScreenX(x)
            local zoom = (IsLFO and (Mc and (Mc.Zoom or 1) or 1)) or 1
            local center = (IsLFO and (Mc and (Mc.ZoomCenter or 0.5) or 0.5)) or 0.5
            local function map_u(u)
                return ((u - center) * zoom + 0.5)
            end
            return  L + map_u(x) * (W) + PtSz/2
        end
        if NoteOnVel > -1  then 
            if NoteOnVel >= X and NoteOnVel <= nX then 
                --local W , H = W  , H - PtSz/2

                local x = ConvertScreenX(NoteOnVel)
                local y = ( Y + (nY-Y) * ( (NoteOnVel-X) * (1/(nX-X )))    ) 

                --[[ local I = ( i - X ) / (nX - X) 
                local y =  ( Y + (nY-Y) * I    ) ]]
                if curve then 
                    y = ConvertScreenY( GetCurveValue(y , -curve ,  math.min(Y, nY), math.max(Y, nY)  , math.min(Y, nY), math.max(Y, nY)))
                else 
                    y = ConvertScreenY(y)
                end
                --GLOWING_CIRCLE({x,y}, 3, 3, 5 , ThemeClr("Accent_Clr") ) 
                AddPt(x, y )
            --[[ elseif (NoteOnVel <= X and i == 1) or (NoteOnVel > X and i == #PtsTB) then 
                AddPt(  ConvertScreenX(NoteOnVel) , ConvertScreenY(Y)) ]]
            end
        end

        for i, v in ipairs(Midi_Mod_Indicator)  do 

            v.Opacity , v.time  , v.Complete = Anim_Update( 0.1 , 4, 1, 0 , v .time)
            local glowSz = 10

            local clr = ThemeClr("Accent_Clr")

            local lineClr = Change_Clr_A( clr, -1.2 +  v.Opacity * 0.4)
            local CircleClr =  --[[ lineClr or ]] Change_Clr_A( clr,  v.Opacity-1 )  

            local glow_in = 1
            local GlowOut = glow_in + v.Opacity*glowSz

            for i= glow_in, GlowOut, 1 do 
                local I =  (GlowOut - i)   
                local range =  GlowOut - glow_in
                local n = (range - i + glow_in  )/ range
                
                local I = glow_in - I
                local N =   (i - glow_in )/range 


                local CircleClr = Change_Clr_A( clr,   -N - 0.3 )  

                local clr = BlendColors(CircleClr   , 0xffffffff, -N + 1 )
                im.DrawList_AddCircle(WDL or Glob.FDL, v.x, v.y , i, clr)

            end
        
            im.DrawList_AddCircle(WDL or Glob.FDL, v.x, v.y , glow_in, CircleClr)



           im.DrawList_AddLine(WDL, v.x, B-H, v.x , B+PtSz , lineClr , 3*v.Opacity)
            if v.Complete then table.remove(Midi_Mod_Indicator, i) end
        end



    end
    
    
    im.Dummy(ctx,W + Pad,H + Pad)
    local CursorPosEndX, CursorPosEndY = im.GetCursorPos(ctx)

    im.SetCursorPos(ctx, x + Pad/2 , y + Pad/2 )
    -- Constrain all drawings to the curve editor rect
    local ClipL, ClipT = im.GetCursorScreenPos(ctx)
    local ClipR, ClipB = ClipL + W, ClipT + H
    im.DrawList_PushClipRect(WDL, ClipL, ClipT, ClipR, ClipB, true)
    -- Expose curve editor rect for overlays (e.g., LFO preview/animation)
    if IsLFO and Macro then
        LFO = LFO or {}
        LFO.CurveRect = LFO.CurveRect or {}
        LFO.CurveRect[Macro] = { ClipL, ClipT, ClipR, ClipB }
    end
    DrawGrid()
    -- Always show outline of editor regardless of zoom
    im.DrawList_AddRect(WDL, ClipL, ClipT, ClipR, ClipB, 0xffffff33, 0, nil, 2)
    local ClickOnBG = im.Dummy(ctx, W, H)
    -- Shift+wheel zoom handling (apply then consume)
    -- Help: Modulation curve editor background
    if im.IsItemHovered(ctx) then
        if HelperMsg.Others then
            table.insert(HelperMsg.Others, 'Double-click: Add Point')
            if IsLFO then
                table.insert(HelperMsg.Others, 'Shift + Mouse Wheel: Zoom')
            end
        end
    end
    -- Shift+wheel zoom handling (zoom towards mouse)
    if IsLFO and (Mods == Shift) and Wheel_V ~= 0 then
        Mc.Zoom = Mc.Zoom or 1
        Mc.ZoomCenter = Mc.ZoomCenter or 0.5
        local Lz, Tz = im.GetItemRectMin(ctx); local Rz, Bz = im.GetItemRectMax(ctx)
        local Wz = Rz - Lz
        local mx, _ = im.GetMousePos(ctx)
        local xNorm = SetMinMax((mx - Lz) / math.max(1, Wz), 0, 1)
        local zOld = Mc.Zoom
        local zNew = SetMinMax(zOld * (Wheel_V > 0 and 1.1 or 0.9), 1, 4)
        if zNew ~= zOld then
            local cOld = Mc.ZoomCenter
            local uUnderMouse = cOld + (xNorm - 0.5) / zOld
            local cNew = uUnderMouse - (xNorm - 0.5) / zNew
            local minC = 1 / (2 * zNew)
            local maxC = 1 - minC
            Mc.ZoomCenter = SetMinMax(cNew, minC, maxC)
            Mc.Zoom = zNew
        end
        Wheel_V = 0
    end
    -- Horizontal pan with wheel when zoomed
    if IsLFO and (Mc and (Mc.Zoom or 1) or 1) > 1 and Wheel_H and Wheel_H ~= 0 and im.IsItemHovered(ctx) then
        Mc.Zoom = Mc.Zoom or 1
        Mc.ZoomCenter = Mc.ZoomCenter or 0.5
        local minC = 1 / (2 * Mc.Zoom)
        local maxC = 1 - minC
        Mc.ZoomCenter = SetMinMax(Mc.ZoomCenter + (Wheel_H * 0.05) / Mc.Zoom, minC, maxC)
        Wheel_H = 0
    end
    -- Middle-click drag to pan when zoomed
    if IsLFO and (Mc and (Mc.Zoom or 1) or 1) > 1 and im.IsItemHovered(ctx) and im.IsMouseDown(ctx, 2) then
        local dx, _ = im.GetMouseDelta(ctx)
        if dx and dx ~= 0 then
            Mc.Zoom = Mc.Zoom or 1
            Mc.ZoomCenter = Mc.ZoomCenter or 0.5
            local Lz, _ = im.GetItemRectMin(ctx); local Rz, _ = im.GetItemRectMax(ctx)
            local Wz = Rz - Lz
            local minC = 1 / (2 * Mc.Zoom)
            local maxC = 1 - minC
            Mc.ZoomCenter = SetMinMax(Mc.ZoomCenter - (dx / math.max(1, Wz)) / Mc.Zoom, minC, maxC)
            im.ResetMouseDragDelta(ctx)
        end
    end
    local AddPt = (LBtnDC and im.IsItemClicked(ctx)) and true
    local L, T = im.GetItemRectMin(ctx)
    local R, B = im.GetItemRectMax(ctx)
    local R, B = R - PtSz, B - PtSz

    --Highlight_Itm(WDL, nil, 0xffffff33)
    PtsTB=PtsTB or { {0, 0} , {1, 1} }
    if not next(PtsTB) then 
    
        PtsTB[1]= {0, 0}
        PtsTB[2]= {1, 1}
    end

    local Hvr_Pt , Hvr_Ctrl_Pt
    local W , H = W - PtSz , H - PtSz

    r.gmem_attach(gmem_space)
    Update_Info_To_Jsfx(PtsTB, lbl , IsLFO, Macro)
    local TWEAKING 
    local function LFO_Add_Release_Node_If_None()
        if not Mc then return end 
        if not Mc.Rel_Type then return end 
        if not  Mc.Rel_Type:find('Custom Release') then return end 
        
        -- First, try to restore from Param2
        local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
        if MacFxGUID then
            local function FindFxIdxByGUID(guid)
                local cnt = r.TrackFX_GetCount(LT_Track)
                for idx = 0, cnt-1, 1 do
                    if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                end
            end
            local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
            local param2Idx = 2 + (Macro - 1) * 4 + 1 -- Param2 for this modulator
            local param2Value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, param2Idx)
            
            if param2Value and param2Value >= 0 and param2Value <= 1 and #PtsTB > 1 then
                -- Convert normalized value back to node index
                local nodeIdx = math.floor(param2Value * (#PtsTB - 1) + 1 + 0.5)
                nodeIdx = math.max(1, math.min(nodeIdx, #PtsTB))
                if PtsTB[nodeIdx] then
                    -- Clear all previous .Rel flags first
                    for idx, node in ipairs(PtsTB) do
                        node.Rel = nil
                    end
                    -- Set the restored release node
                    PtsTB[nodeIdx].Rel = true
                    -- Also sync to Mc.Node if it exists
                    if Mc and Mc.Node and Mc.Node[nodeIdx] then
                        -- Clear all previous .Rel flags in Mc.Node
                        for idx, node in ipairs(Mc.Node) do
                            node.Rel = nil
                        end
                        Mc.Node[nodeIdx].Rel = true
                    end
                    return -- Found and restored from Param2
                end
            end
        end
        
        -- Check if any node already has Rel flag
        for i, v in ipairs(PtsTB) do 
            if v.Rel then return end 
        end
        
        -- Default to second-to-last node if none found
        if #PtsTB > 1 then
            PtsTB[#PtsTB - 1].Rel = true 
        end
    end

    LFO_Add_Release_Node_If_None()
    local HoverSeg = {}
    -- per-node snap state for LFO editing
    Mc = Mc or MacroTB
    if IsLFO then Mc.SnapStates = Mc.SnapStates or {} end
    local NodeHovered, NodeActive = {}, {}
    for i, v in ipairs( PtsTB) do 
        
        local zoom = (IsLFO and ( (Mc.Zoom or 1) )) or 1
        local center = (IsLFO and ( (Mc.ZoomCenter or 0.5) )) or 0.5

        local function map_u(u)
            return ((u - center) * zoom + 0.5)
        end
        local X, Y = L + map_u(v[1]) * W , B - v[2]*H 
        im.SetCursorScreenPos(ctx, X, Y )
        local rv = im.InvisibleButton(ctx, '##LFO_Pt'..(lbl or '')..i, PtSz, PtSz)
        local Tweaking = im.IsItemActive(ctx)
        local DtX, DtY = 0, 0
        if Tweaking then DtX, DtY = im.GetMouseDragDelta(ctx) end
        if Tweaking then TWEAKING = true end  
        local lX = i>1 and PtsTB[i-1][1] or 0 
        local nX = i<#PtsTB and PtsTB[i+1][1] or 1
        local nY = i<#PtsTB and PtsTB[i+1][2] or v[2]
        local prevNormX, prevNormY = v[1], v[2]
        if DtX then
            local zoomed_u    = map_u(v[1])
            local zoomed_lX   = map_u(lX)
            local zoomed_nX   = map_u(nX)
            local new_zoomed  = SetMinMax(zoomed_u + DtX / W, zoomed_lX, zoomed_nX)
            -- optional snapping for LFO nodes (hold Shift to disable)
            if IsLFO and Mods ~= Shift then
                local Gd = (Mc and Mc.LFO_leng) or (LFO and LFO.Def and LFO.Def.Len) or 4
                Gd = tonumber(Gd) or 4
                local snap = Mc.SnapStates[i] or {}
                local new_px = L + new_zoomed * W
                local factor = 0.7
                local tol = 8 * factor
                local release = 12 * factor
                -- find nearest grid in zoomed space
                local nearest_px, nearest_zoomed
                for gi = 0, Gd, 1 do
                    local u = gi / Gd
                    local gz = map_u(u)
                    local gpx = L + gz * W
                    local d = math.abs(new_px - gpx)
                    if not nearest_px or d < math.abs(new_px - nearest_px) then
                        nearest_px = gpx; nearest_zoomed = gz
                    end
                end
                if snap.active_x then
                    if math.abs(new_px - (snap.target_x_px or 0)) <= release then
                        new_zoomed = snap.target_x_zoomed or new_zoomed
                    else
                        snap.active_x = nil; snap.target_x_px = nil; snap.target_x_zoomed = nil
                    end
                else
                    if nearest_px and math.abs(new_px - nearest_px) <= tol then
                        snap.active_x = true
                        snap.target_x_px = nearest_px
                        snap.target_x_zoomed = nearest_zoomed
                        new_zoomed = nearest_zoomed
                    end
                end
                Mc.SnapStates[i] = snap
            end
            -- convert back to normalized 0..1 after applying zoom space delta (respect current center)
            v[1] = ((new_zoomed - 0.5) / zoom) + center
        end
        if DtY then
            local new_v2 = SetMinMax(v[2]-DtY/H , 0, 1)
            if IsLFO and Mods ~= Shift then
                local snap = Mc.SnapStates[i] or {}
                local factor = 0.7
                local tol = 8 * factor
                local release = 12 * factor
                local yGrids = {0, 0.25, 0.5, 0.75, 1}
                local new_px = B - new_v2 * H
                local nearest_px, nearest_v
                for _,yg in ipairs(yGrids) do
                    local gpx = B - yg * H
                    local d = math.abs(new_px - gpx)
                    if not nearest_px or d < math.abs(new_px - nearest_px) then
                        nearest_px = gpx; nearest_v = yg
                    end
                end
                if snap.active_y then
                    if math.abs(new_px - (snap.target_y_px or 0)) <= release then
                        new_v2 = snap.target_y_val or new_v2
                    else
                        snap.active_y = nil; snap.target_y_px = nil; snap.target_y_val = nil
                    end
                else
                    if nearest_px and math.abs(new_px - nearest_px) <= tol then
                        snap.active_y = true
                        snap.target_y_px = nearest_px
                        snap.target_y_val = nearest_v
                        new_v2 = nearest_v
                    end
                end
                Mc.SnapStates[i] = snap
            end
            v[2] = new_v2
        end
        if i == 1 then 
            v[1] = 0
        elseif i == #PtsTB then 
            v[1] = 1
        end

        Hvr_Pt = im.IsItemHovered(ctx) and true  
        NodeHovered[i] = im.IsItemHovered(ctx) or false
        NodeActive[i] = Tweaking or false
        -- Help: Node handle hover actions
        if im.IsItemHovered(ctx) then
            HelperMsg.Need_Add_Mouse_Icon = 'L'
            HelperMsg.L = 'Drag to Move Point'
            if #PtsTB > 2 then
                HelperMsg.Alt_L = 'Delete Point'
            end
            if HelperMsg.Others then
                table.insert(HelperMsg.Others, 'Mouse Wheel: Adjust Segment Curvature')
            end
        end
        
        local function Send_gmem(Pt , mode )
            r.gmem_attach(gmem_space)
            local midiModOfs = Get_MidiMod_Ofs(lbl)
            r.gmem_write(4, mode or 23) -- tells jsfx user is changing the curve
            r.gmem_write(12, midiModOfs)  -- - tells which midi mod it is , velocity is (+0) , Random is (+1~3) , KeyTrack is(+4~6), LFO is 7
            r.gmem_write(11, Pt) -- tells which pt
            r.gmem_write(13, #PtsTB) -- tells how many points in total
            -- Always send Macro number for LFO/Envelope (gmem[12] == 7 means LFO/Envelope)
            if (IsLFO or midiModOfs == 7) and Macro then 
                r.gmem_write(5, Macro) 
            end
        end

        local function Wheel_To_Adjust_Curve()
            local mX, mY = im.GetMousePos(ctx)
         
            if mX > X and mX < L+ nX *W then 

                if Wheel_V and Wheel_V~=0 and not (IsLFO and Mods == Shift) then 
                    v[3] =  (v[3] or 0 ) 
                    v[3] = v[3]+ Wheel_V /10
                    if v[3] < 1 and v[3] > -1 then
                        if Wheel_V > 0 then 
                            v[3] = 1
                        else 
                            v[3] = -1
                        end
                    end
                    Send_gmem(i, 24 )
                    r.gmem_attach(gmem_space)
                    r.gmem_write(15, v[3])
                    Save_to_Trk(lbl..' point '..i..' Curve', v[3])
                    
                end
                return true
            end
        
        end

        local function Send_gmem_If_Drag_Node()
            if DtX or DtY then 
                --Send_gmem(i )
                r.gmem_attach(gmem_space)
                local midiModOfs = Get_MidiMod_Ofs(lbl)
                r.gmem_write(4, 23) -- tells jsfx user is changing the curve
                r.gmem_write(12, midiModOfs)  -- - tells which midi mod it is , velocity is (+0) , Random is (+1~3) , KeyTrack is(+4~6), LFO is 7
                r.gmem_write(11, i) -- tells which pt
                r.gmem_write(13, #PtsTB) -- tells how many points in total
                -- Always send Macro number for LFO/Envelope (gmem[12] == 7 means LFO/Envelope)
                if (IsLFO or midiModOfs == 7) and Macro then 
                    r.gmem_write(5, Macro) 
                end
                if DtX then  
                    r.gmem_write(9, v[1]) 
                end
                if DtY then  
                    r.gmem_write(10, v[2]) 
                end
                -- Send curve value
                r.gmem_write(15, v[3] or 0)

            end
        end


        local function Delete_Node_If_Alt_Click()
            if Mods ==Alt and im.IsItemClicked(ctx) and #PtsTB > 2 then
                Save_to_Trk(lbl..' point '..i..' Y', '')
                Save_to_Trk(lbl..' point '..i..' X', '')
                Save_to_Trk(lbl..' point '..i..' Curve', '')
                table.remove(PtsTB, i )

                SaveCurve()
                Update_Info_To_Jsfx(PtsTB, lbl , IsLFO, Macro)
            end
        end

        local function AddPoint_If_DoubleClick ()

            if AddPt   and not Hvr_Pt and not Hvr_Ctrl_Pt  then 
                local mX, mY = im.GetMousePos(ctx)
                local mX , mY = (mX - L ) / W  , (B-mY ) / H
                local n = PtsTB[i+1]
                local Limit = IsLFO and 50 or 10 
                if n then 
                    if mX > v[1] and mX < n[1] and #PtsTB<Limit then 
                        table.insert(PtsTB , i+1, {})
                        PtsTB[i+1][1]=mX 
                        PtsTB[i+1][2]=mY 
                        SaveCurve()
                        Update_Info_To_Jsfx(PtsTB, lbl , IsLFO, Macro)
                        Save_to_Trk(lbl..' point '.. #PtsTB..' X',mX)
                        Save_to_Trk(lbl..' point '.. #PtsTB..' Y',mY)
                        Save_to_Trk(lbl.. 'Curve number of points',  #PtsTB)
                        return 
                    end

                end
            end         
        end

        local function Draw_Playhead_If_LFO()
            if not IsLFO then return end 
            local MOD  = math.abs(SetMinMax((r.gmem_read(100 + Macro) or 0) / 127, -1, 1))
            local zoom = (Mc and (Mc.Zoom or 1) or 1)
            local center = (Mc and (Mc.ZoomCenter or 0.5) or 0.5)
            
            local function map_u(u)
                return ((u - center) * zoom + 0.5)
            end
            
            -- CurrentPos is in LFO length units (0 to LFO_Len), convert to normalized (0 to 1)
            local CurrentPos = r.gmem_read(108 + Macro) or 0
            local LFO_Len = (Mc.LFO_leng or LFO.Def.Len) or 4
            local normalizedPos = CurrentPos / LFO_Len
            local PlayPos = L + PtSz/2 + map_u(normalizedPos) * W
            
            local H = H 
            local T = T + PtSz/2
            local X = PlayPos 
            local Y = T + H - MOD * H
            im.DrawList_AddLine(WDL, X, T, X, T + H, EightColors.LFO[Macro], 1)
            --im.DrawList_AddCircleFilled(WDL, X, Y, 3, EightColors.LFO[Macro])
            GLOWING_CIRCLE({X, Y}, 0, 15, 0, EightColors.LFO[Macro], WDL)
            --[[ local function DrawValueTrail()
                local M = Mc
                local PlayPos = L + PtSz/2 + r.gmem_read(108 + Macro) / 4 * W / ((Mc.LFO_leng or LFO.Def.Len) / 4)
                M.Trail = M.Trail or {}

                -- Store previous frame's position
                local prevPlayPos = M.Trail[#M.Trail] and M.Trail[#M.Trail].x or PlayPos
                
                -- Find if we crossed any points
                local crossedPoints = {}
                for i = 1, #PtsTB do
                    local ptX = L + PtsTB[i][1] * W + PtSz/2
                    -- Check if point lies between previous and current playhead position
                    if (prevPlayPos < ptX and ptX < PlayPos) then
                        table.insert(crossedPoints, {
                            x = ptX,
                            y = T + H - PtsTB[i][2] * H
                        })
                    end
                end
                if #crossedPoints > 0 then 
                    -- Add all points in sequence
                    for _, pt in ipairs(crossedPoints) do
                        table.insert(M.Trail, pt)
                    end
                else 
                    -- Add current position
                    table.insert(M.Trail, { x = PlayPos, y = Y })
                end
                if #M.Trail > 40 then table.remove(M.Trail, 1) end
                
                -- Draw trail segments
                for i = 2, #M.Trail do
                    local v = M.Trail[i]
                    local ls = M.Trail[i-1]
                    if v.x >= ls.x then
                        local FDL = im.GetWindowDrawList(ctx)
                        local clr =  Change_Clr_A(0xffffff00, (i/#M.Trail) * 0.4 )
                        im.DrawList_AddLine(FDL, v.x, v.y, ls.x, ls.y, clr, 8 - 8 / i  )
                    end
                end
            end ]]
            -- DrawValueTrail()
            function Show_Position_Retroactively()
                Mc.Trail = Mc.Trail or {}
                table.insert(Mc.Trail, PlayPos)
                if #Mc.Trail > 40 then table.remove(Mc.Trail, 1) end
                for i = 2, #Mc.Trail do
                    local v = Mc.Trail[i]
                    local ls = Mc.Trail[i-1]
                    if v >= ls then
                        local FDL = im.GetWindowDrawList(ctx)
                        local CLR = Change_Clr_A(EightColors.LFO[Macro], -1)
                        local clr =  Change_Clr_A(CLR, (i/#Mc.Trail) * 0.02 )
                        im.DrawList_AddRectFilled(FDL, ls, T-PtSz/2, v, B+PtSz, clr  )
                    end
                end
            end
            Show_Position_Retroactively()
        end 

        local function LFO_Release_Node ()
            if not Mc then return end 
            if not Mc.LFO_Env_or_Loop then return end
            if  Mc.LFO_Env_or_Loop ~= 'Envelope' then return end

            -- Read Param1 from JSFX to determine release type (0=Latch, 0.5=Custom Release, 1=Custom Release No Jump)
            local isCustomRelease = false
            local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
            if MacFxGUID then
                local function FindFxIdxByGUID(guid)
                    local cnt = r.TrackFX_GetCount(LT_Track)
                    for idx = 0, cnt-1, 1 do
                        if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                    end
                end
                local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                local param1Idx = 2 + (Macro - 1) * 4 -- Param1 for this modulator
                local param1Value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, param1Idx)
                -- Param1 >= 0.25 means Custom Release (0.5) or Custom Release No Jump (1.0)
                if param1Value and param1Value >= 0.25 then
                    isCustomRelease = true
                end
            end

            if isCustomRelease then 

                if v.Rel  then

                    local function If_Choose_Rel(id)
                        -- Clear all previous .Rel flags first
                        for idx, node in ipairs(PtsTB) do
                            node.Rel = nil
                        end
                        -- Set the new release node
                        PtsTB[id].Rel = true
                        
                        -- Also sync to Mc.Node if it exists
                        if Mc and Mc.Node and Mc.Node[id] then
                            Mc.Node[id].Rel = true
                            -- Clear other nodes in Mc.Node
                            for idx, node in ipairs(Mc.Node) do
                                if idx ~= id then
                                    node.Rel = nil
                                end
                            end
                        end
                        
                        -- Set Param2 to release node number (normalized)
                        local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
                        if MacFxGUID then
                            local function FindFxIdxByGUID(guid)
                                local cnt = r.TrackFX_GetCount(LT_Track)
                                for idx = 0, cnt-1, 1 do
                                    if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                                end
                            end
                            local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                            local paramIdx = 2 + (Macro - 1) * 4 + 1 -- Param2 for this modulator
                            local nodeCount = #PtsTB
                            if nodeCount > 1 then
                                -- Normalize: node 1 = 0, last node = 1
                                local normalized = (id - 1) / (nodeCount - 1)
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, paramIdx, normalized)
                            end
                        end
                        -- Save release node ID to track extended data
                        Save_to_Trk('Mod ' .. Macro .. 'LFO_Rel_Node', id)
                        LFO_REL_MS_DT = nil
                        im.ResetMouseDragDelta(ctx)
                    end
                    local L =X + PtSz/2
                    --im.DrawList_AddCircle(WDL, L, T + PtSz / 2, 6, 0xffffffaa)
                    local T = T - PtSz-3
                    local B = B + PtSz
                    im.DrawList_AddLine(WDL, L, T, L, B, 0xffffff55, PtSz/3)
                    --im.DrawList_AddText(WDL, L + PtSz/2, T, 0xffffffaa, 'Release')
                    
                    -- Temporarily pop clip rect so buttons can be drawn outside curve editor bounds
                    im.DrawList_PopClipRect(WDL)
                    
                    local X, Y = im.GetCursorPos(ctx)
                    im.SetCursorScreenPos(ctx, L , T)
                    if im.ArrowButton(ctx, 'ReleaseLeft'..i, 0) then 
                        If_Choose_Rel(math.max(i-1 , 1 ) ) 
                    end
                    SL(nil,0 ) 
                    im.Button(ctx, 'R'..i ) 
                    if im.IsItemActive(ctx) then  
                        TWEAKING =true   
                        local MsX, MsY = im.GetMouseDragDelta(ctx)
                        LFO_REL_MS_DT =  (LFO_REL_MS_DT or 0 ) + MsX
                        if LFO_REL_MS_DT > 20 then 
                            If_Choose_Rel(math.min(i+1 , #PtsTB))
                        elseif LFO_REL_MS_DT < -20 then 
                            If_Choose_Rel(math.max(i-1 , 1))

                        end
                        
                    end 
                    SL(nil, 0)
                    if im.ArrowButton(ctx, 'ReleaseRight'..i, 1) then 
                        If_Choose_Rel(math.min(i+1 , #PtsTB))


                    end
                    im.SetCursorScreenPos(ctx, X, Y)
                    
                    -- Restore clip rect for rest of curve editor
                    im.DrawList_PushClipRect(WDL, ClipL, ClipT, ClipR, ClipB, true) 


                end
            end
        end


        
        
        local HoverOnCurve =   Wheel_To_Adjust_Curve()
        HoverSeg[i] = not not HoverOnCurve
        Draw_Playhead_If_LFO()
        Show_Played_Notes_Velocity(v[1] , nX, v[2] , nY,L, B, W, H, v[3], i)
        Send_gmem_If_Drag_Node()
        if Tweaking and ((DtX ~= 0) or (DtY ~= 0)) then
            local movedX = math.abs((v[1] or 0) - (prevNormX or 0)) > 0
            local movedY = math.abs((v[2] or 0) - (prevNormY or 0)) > 0
            if movedX or movedY then
                im.ResetMouseDragDelta(ctx, 0)
            end
        end
        Delete_Node_If_Alt_Click()
        AddPoint_If_DoubleClick ()
        LFO_Release_Node ()
        
    end
    -- Draw all segments after all node positions are updated to avoid one-frame lag
    do
        local zoom = (IsLFO and (Mc and (Mc.Zoom or 1) or 1)) or 1
        local center = (IsLFO and (Mc and (Mc.ZoomCenter or 0.5) or 0.5)) or 0.5
        for i = 1, #PtsTB do
            local thick = HoverSeg[i] and 6 or 4
            Draw_Curve(WDL, PtsTB, i, L, R, B, W, H, PtSz, lineClr, thick, zoom, center)
        end
    end
    -- Draw nodes after segments so they are synchronized with lines
    do
        local zoom = (IsLFO and (Mc and (Mc.Zoom or 1) or 1)) or 1
        local center = (IsLFO and (Mc and (Mc.ZoomCenter or 0.5) or 0.5)) or 0.5
        local function map_u(u)
            return ((u - center) * zoom + 0.5)
        end
        for i, v in ipairs(PtsTB) do
            local Xn, Yn = L + map_u(v[1]) * W , B - v[2]*H
            local cx, cy = Xn + PtSz/2, Yn + PtSz/2
            local isActive = NodeActive[i]
            local isHovered = NodeHovered[i]
            local baseRad = PtSz/2
            local rad = baseRad + (isActive and 1 or (isHovered and 0.5 or 0))
            local fill = isActive and (getClr and getClr(im.Col_ButtonActive) or 0xffc080ff)
                        or (isHovered and (getClr and getClr(im.Col_ButtonHovered) or 0xffffffff)
                        or (getClr and getClr(im.Col_Button) or 0xffefefff))
            -- Use a consistent grey outline for all states
            local outline = 0x999999ff
            local thick = isActive and 3 or (isHovered and 2 or 1.5)
            im.DrawList_AddCircleFilled(WDL, cx, cy, rad, fill)
            im.DrawList_AddCircle(WDL, cx, cy, rad, outline, nil, thick)
            if isActive or isHovered then
                local pct = math.floor((v[2] or 0) * 100 + 0.5)
                local label = tostring(pct) .. '%'
                local tx, ty = cx + rad + 4, cy - rad - 4
                im.DrawList_AddText(WDL, tx + 1, ty + 1, 0x000000aa, label)
                im.DrawList_AddText(WDL, tx, ty, 0xffffffff, label)
            end
        end
    end
    
    SaveCurve()
    im.DrawList_PopClipRect(WDL)
    im.SetCursorPos(ctx, CursorPosEndX, CursorPosEndY)

    return PtsTB , TWEAKING
    --[[ im.SetCursorScreenPos(ctx, R-PtSz, T)
    RoundBtn(PtSz, PtSz, 'Max', 0xffffffff) ]]

end

function Simple_CurveEditor()

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


function Draw_A_Cursor_Shape( x, y, scale, col, angle, width, concavity )
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
    local  rbx = x + width * scale ;
    local  rby = y + 3 * scale;
    local  bx = x ;
    local  by = y + (2 - concavity) * scale;  -- Adjust the bottom point based on concavity
    local  lbx = x - width * scale ;
    local  lby = y + 3 * scale ;
    local WDL = im.GetWindowDrawList(ctx)

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

function Show_Tooltip_For_Duration(text, duration , pos)
    if text then
        if Tooltip.pos and type (Tooltip.pos) =='table' then     
            im.SetNextWindowPos(ctx, Tooltip.pos[1], Tooltip.pos[2])
        end
        Tooltip.time =( Tooltip.time or 0) + 1 

        local time = Tooltip.time
        if time < duration then 
            tooltip(text, Tooltip.clr, pos)
        elseif time > duration then
            Tooltip= {}
        end
    end
end

function RemoveFXfromBS()
    for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do -- check all fxs and see if it's a band splitter
        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
        if FX[FxGUID].FXsInBS then

            local FxID = tablefind(FX[FxGUID].FXsInBS, FXGUID[DragFX_ID])
            if FxID then
                table.remove(FX[FxGUID].FXsInBS, FxID)
                FX[FxGUID].InWhichBand = nil
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FxGUID, '', true)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FxGUID, '', true)
            end
        end
    end
end
-- Function to draw text with adjustable character spacing (horizontal, vertical up or down)
-- Function to draw text with adjustable character spacing
-- Supports horizontal, vertical top-down, or vertical bottom-up text
-- Function to draw text with adjustable character spacing
-- Supports horizontal, vertical top-down, or vertical bottom-up text
-- Function to draw text with adjustable character spacing
-- Supports horizontal, vertical top-down, or vertical bottom-up text
function DrawTextWithSpacing(draw_list, text, pos_x, pos_y, color, spacing_factor, font, direction, max_length)
    if not text or text == "" then return end
    
    -- Save current font if needed
    local prev_font = nil
    if font then
        prev_font = im.GetFont(ctx)
        im.PushFont(ctx, font)
    end
    
    -- Direction options: "horizontal", "vertical_down", "vertical_up"
    local vertical = direction == "vertical_down" or direction == "vertical_up"
    local bottom_up = direction == "vertical_up"
    
    local total_length = 0
    local chars_drawn = 0
    
    -- Check if using Andale Mono font (for special 'P' handling)
    local is_andale_mono = false
    local font_name = ""
    if font then
        -- Extract font name from the font object or variable name
        font_name = tostring(font)
        is_andale_mono = font_name:find("Andale_Mono") ~= nil
    end
    
    -- Special extra spacing for 'P' in Andale Mono font when vertical
    local p_extra_spacing = 0.3  -- 12% extra spacing
    
    -- Prepare characters array
    local chars = {}
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local char_width, char_height = im.CalcTextSize(ctx, char)
        local nextchar = string.sub(text, i+1, i+1)
        
        -- Apply special P spacing for Andale Mono in vertical mode
        local char_spacing = spacing_factor
        if vertical and is_andale_mono and nextchar == "P" or nextchar == "p" then
            
            char_spacing = spacing_factor * (1 + p_extra_spacing)
        end
        
        table.insert(chars, {
            char = char,
            width = char_width,
            height = char_height,
            spacing = char_spacing  -- Store custom spacing for this character
        })
    end
    
    -- For bottom-up, we need to calculate position for each character from bottom
    if bottom_up then
        -- Calculate total height first (needed to position characters from bottom)
        local total_height = 0
        for _, char_data in ipairs(chars) do
            total_height = total_height + char_data.height * char_data.spacing
            if max_length and total_height > max_length then
                total_height = max_length
                break
            end
        end
        
        -- Set position to start from the bottom
        local curr_y = pos_y
        
        -- Place characters from bottom up
        for i = 1, #chars do
            local char_data = chars[i]
            
            -- Check if exceeding max length
            if max_length and total_length + char_data.height * char_data.spacing > max_length then
                break
            end
            
            -- Draw the character at bottom position
            im.DrawList_AddText(draw_list, pos_x, curr_y, color, char_data.char)
            chars_drawn = chars_drawn + 1
            
            -- Move upward for next character using character-specific spacing
            curr_y = curr_y - char_data.height * char_data.spacing
            total_length = total_length + char_data.height * char_data.spacing
        end
    else
        -- Horizontal or vertical downward text (normal behavior)
        local curr_x = pos_x
        local curr_y = pos_y
        
        for i = 1, #chars do
            local char_data = chars[i]
            
            -- Check if exceeding max length
            if max_length and total_length + (vertical and char_data.height or char_data.width) * char_data.spacing > max_length then
                break
            end
            
            -- Draw the character
            im.DrawList_AddText(draw_list, curr_x, curr_y, color, char_data.char)
            chars_drawn = chars_drawn + 1
            
            -- Move position for next character using character-specific spacing
            if vertical then
                curr_y = curr_y + char_data.height * char_data.spacing
                total_length = total_length + char_data.height * char_data.spacing
            else
                curr_x = curr_x + char_data.width * char_data.spacing
                total_length = total_length + char_data.width * char_data.spacing
            end
        end
    end
    
    -- Restore previous font if we pushed a new one
    if font then
        im.PopFont(ctx)
    end
    
    -- Return the final position and total length
    return bottom_up and (pos_y - total_length) or (vertical and pos_y + total_length or pos_x + total_length), 
           total_length, 
           chars_drawn
end

function Pre_FX_Chain(FX_Idx)
    if not FX_Idx then return end 
    local offset
  ------- Pre FX Chain --------------

    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local FXisInPreChain, offset = nil, 0
    if MacroPos == 0 then offset = 1 end --else offset = 0
    if Trk[TrkID].PreFX[1] then
        if Trk[TrkID].PreFX[FX_Idx + 1 - offset] == FxGUID then
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
    if FX_Idx + 1 == Sel_Track_FX_Count and not Trk[TrkID].PostFX[1] then -- add last space
        AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc')
    elseif FX_Idx + 1 == Sel_Track_FX_Count and Trk[TrkID].PostFX[1] then
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
function Add_WetDryKnob(ctx, label, labeltoShow, p_value, v_min, v_max, FX_Idx, P_Num, FxGUID)

    local radius_outer = WET_DRY_KNOB_SZ/2
    local pos = { im.GetCursorScreenPos(ctx) }
    local center = { pos[1] + radius_outer, pos[2] + radius_outer }
    local CircleClr
    local line_height = im.GetTextLineHeight(ctx)
    local draw_list = im.GetWindowDrawList(ctx)
    local item_inner_spacing = { im.GetStyleVar(ctx, im.StyleVar_ItemInnerSpacing) }
    local mouse_delta = { im.GetMouseDelta(ctx) }

    local ANGLE_MIN = 3.141592 * 0.75
    local ANGLE_MAX = 3.141592 * 2.25
    local FxGUID = FxGUID or r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local p_value = p_value or 1
    if FxGUID then
        if FX[FxGUID].NoWetDryKnob then return  end
        FX[FxGUID] = FX[FxGUID] or {}
        im.SetNextItemWidth(ctx, 40)

        if SyncWetValues then
            SyncWetValues(FX_Idx, FxGUID)
        else
            FX[FxGUID][0] = FX[FxGUID][0] or {}
            FX[FxGUID][0].Num = FX[FxGUID][0].Num or r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet')
            if FX[FxGUID][0].Num and FX[FxGUID][0].Num ~= -1 then
                FX[FxGUID][0].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FX[FxGUID][0].Num)
            end
        end
        Wet.P_Num[FX_Idx] = Wet.P_Num[FX_Idx] or r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet')

        im.InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height - 10 + item_inner_spacing[2])

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
            --im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer, 0x444444ff, 16)
            local circleClr = CircleClr or lineClr
            local lineThick = 2.0
            if is_hovered and not is_active then
                circleClr = HSV_Change(circleClr, nil, nil, 0.15)
                lineClr = HSV_Change(lineClr, nil, nil, 0.15)
                lineThick = 2.5
            end
            im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, circleClr, 16, is_hovered and not is_active and 2 or 1)
            im.DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
                center[2] + angle_sin * (radius_outer - 2), lineClr, lineThick)
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

function GLOWING_CIRCLE(Coord, glow_in, glow_out, Solid_Rad, clr, WDL , CenterClr   )
    local Coord = Coord or {im.GetItemRectMin(ctx)}
    local x, y = Coord[1], Coord[2]


    local clr = Change_Clr_A(clr, 1 )
    if Solid_Rad then 
        local clr = Change_Clr_A(clr, 1 )

        im.DrawList_AddCircleFilled(WDL or Glob.FDL, x , y , glow_in, CenterClr or  clr)
    end
    for i= glow_in, glow_out, 1 do 
        local I =  (glow_out - i)   
        local range =  glow_out - glow_in
        local n = (range - i + glow_in  )/ range
        
        local I = glow_in - I
        local clr = Change_Clr_A(clr, -1)

        if CenterClr then 
            local clr = BlendColors(clr, CenterClr, n)
            im.DrawList_AddCircle(WDL or Glob.FDL, x, y , i, Change_Clr_A(clr,n ))

        else 
            im.DrawList_AddCircle(WDL or Glob.FDL, x, y , i, Change_Clr_A(clr,n ))
        end
    end
end
function AddWindowBtn(FxGUID, FX_Idx, width, CantCollapse, CantAddPrm, isContainer, NoVert, VertBtnHeight)
    if not FX[FxGUID] then return end 


    local fx = FX[FxGUID]
    local WindowBtn 
    local DragHitL, DragHitT, DragHitR, DragHitB

    local _, orig_Name = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')
    local isContainer = orig_Name == 'Container' and true
    local Cont_Clr = isContainer and Calculate_Color_Based_On_Nesting_Level(fx.nestingLevel)

    -- If the container has no FX inside, use a neutral gray color for its folder icon/highlight
    if isContainer then
        local _, cnt = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'container_count')
        if tonumber(cnt or 0) == 0 then
            Cont_Clr = 0x777777ff -- gray
        end
    end

    local function Marquee_Selection (LC, RC)
        Trk[TrkID].Sel_FX = Trk[TrkID].Sel_FX or {}
        local Sel_FX = Trk[TrkID].Sel_FX



        if RC  and RBtnDrag then  
            MARQUEE_SELECTING_FX = true 
            local x , y = im.GetMousePos(ctx)
            Sel_FX = {x = x , y = y }
        elseif  LC and Mods == Cmd then 
            Sel_FX = Sel_FX or {}
            Sel_FX_Idx = Sel_FX_Idx or {}

            local find=  tablefind(Sel_FX , FxGUID) 
            if find then  
                table.remove(Sel_FX, find)
            else 
                table.insert(Sel_FX,  FxGUID)
            end

            local find=  tablefind(Sel_FX_Idx , FX_Idx) 
            if find then  
                table.remove(Sel_FX_Idx, find)
            else 
                table.insert(Sel_FX_Idx,  FX_Idx)
            end

        end 

        if MARQUEE_SELECTING_FX then 

            local x , y = im.GetMousePos(ctx)

            DrawList_AddRectFilled(Glob.FDL,  Sel_FX.x , Sel_FX.y , x, y , 0xffffff33)

        
        end 
    end
    local function Push_Clr()
        im.PushStyleColor(ctx, im.Col_Button, FX[FxGUID].TitleClr or ThemeClr('FX_Btn_BG_Clr'))

        if FX[FxGUID].TitleClr then
            if not FX[FxGUID].TitleClrHvr then
                FX[FxGUID].TitleClrAct, FX[FxGUID].TitleClrHvr = Generate_Active_And_Hvr_CLRs( FX[FxGUID].TitleClr)
            end
            im.PushStyleColor(ctx, im.Col_ButtonHovered, FX[FxGUID].TitleClrHvr or 0x22222233)
            im.PushStyleColor(ctx, im.Col_ButtonActive, FX[FxGUID].TitleClrAct or 0x22222233)
        else
            local Hvr, Act = Generate_Active_And_Hvr_CLRs( ThemeClr('FX_Btn_BG_Clr'))
            im.PushStyleColor(ctx, im.Col_ButtonHovered, Hvr )
            im.PushStyleColor(ctx, im.Col_ButtonActive, Act )

           
        end 
        WinbtnClrPop = 3

    end
    local Fx_Module_Menu_ID = 'Fx Module Menu##' .. FxGUID
    local function Rpt_If_Multi_Select_FX (func, ...)
        if If_Multi_Select_FX(FxGUID) then 
            for i, v in ipairs(Trk[TrkID].SelFX) do 
                local idx = Find_FxID_By_GUID(v)
                func(..., idx )
            end
            return true 
        end
    end
    local function Open_Layout_Editor()
        if FX.LayEdit == FxGUID then
            FX.LayEdit = nil
        else
            FX.LayEdit = FxGUID
        end
        RetrieveFXsSavedLayout(Sel_Track_FX_Count)

        CloseLayEdit = nil
        im.CloseCurrentPopup(ctx)
        if Draw.DrawMode then Draw.DrawMode = nil end
    end

    local function Add_Prm_Btn()
        if FX[FxGUID].Dont_Allow_Add_Prm then return end
        if im.IsItemHovered(ctx) and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
            fx.TtlHvr = true
            if not CantAddPrm then
                TtlR, TtlB = im.GetItemRectMax(ctx)
                local L, T = TtlR - WET_DRY_KNOB_SZ * 1.25 , TtlB - WET_DRY_KNOB_SZ*0.95
                local TtlB , TtlR    = TtlB - (WET_DRY_KNOB_SZ*0.05), TtlR - (WET_DRY_KNOB_SZ*0.25)
                local sz = WET_DRY_KNOB_SZ * 0.9

                if im.IsMouseHoveringRect(ctx, L, T,  TtlR ,TtlB ) then
                    im.DrawList_AddRectFilled(WDL, L, T,  TtlR ,TtlB , ThemeClr('FX_Btn_BG_Clr'))
                    im.DrawList_AddRect(WDL, L, T,  TtlR ,TtlB , getClr(im.Col_Text))
                    im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, sz, TtlR - 15, TtlB - sz, getClr(im.Col_Text), '+')
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

    local function Mouse_Interactions(R_ClickOnWindowBtn, L_ClickOnWindowBtn)
        local function Ctrl_Double_R_Click_to_Enter_Layout_Editor()
            if Mods == Ctrl + Shift and  im.IsItemClicked(ctx, 1)  then
                Open_Layout_Editor()     
            end
        end
        Ctrl_Double_R_Click_to_Enter_Layout_Editor()
        -- im.SetNextWindowSizeConstraints(ctx, AddPrmWin_W or 50, 50, 9999, 500)

    
        if not CantCollapse then
            if R_ClickOnWindowBtn and Mods == Ctrl then
                im.OpenPopup(ctx, Fx_Module_Menu_ID)
    
            elseif R_ClickOnWindowBtn and Mods == 0  then
                Long_Or_Short_FX_Idx = FX_Idx
    
            elseif R_ClickOnWindowBtn and Mods == Alt then
                -- check if all are collapsed
                BlinkFX = ToggleCollapseAll(FX_Idx)
            end
        end
        local RC =  Determine_Long_Or_Short_Click(R_ClickOnWindowBtn, IsRBtnHeld, 0.5) 
        if Long_Or_Short_FX_Idx == FX_Idx then 
            if RC == 'Short'  then 
                fx.Collapse = toggle(fx.Collapse)

                if not fx.Collapse then fx.Width_Collapse= nil end
                Animate_FX_Width= toggle(Animate_FX_Width , FxGUID)
                Anim_Time = 0
                Long_Or_Short_Click_Time_Start = nil 
    
            elseif RC =='Long'   then 
                Long_Or_Short_Click_Time_Start = nil 
    
            end
            
        end
        if FX.LayEdit ~=FxGUID then 
        
            if WindowBtn and Mods == 0 then
                if If_Multi_Select_FX(FxGUID) then
                    for i, v in ipairs(Trk[TrkID].Sel_FX) do
                        local idx = Find_FxID_By_GUID(v)
                        openFXwindow(LT_Track, idx)
                    end
                else
                    openFXwindow(LT_Track, FX_Idx)
                end
                
            elseif WindowBtn and Mods == Shift then
                if If_Multi_Select_FX(FxGUID) then
                    for i, v in ipairs(Trk[TrkID].Sel_FX) do
                        local idx = Find_FxID_By_GUID(v)
                        ToggleBypassFX(LT_Track, idx)
                    end
                else
                    ToggleBypassFX(LT_Track, FX_Idx)
                end
            elseif WindowBtn and Mods == Alt then
                if If_Multi_Select_FX(FxGUID) then
                    for i, v in ipairs(Trk[TrkID].Sel_FX) do
                        local idx = Find_FxID_By_GUID(v)
                        DeleteFX(idx, FxGUID)
                    end
                else
                    DeleteFX(FX_Idx, FxGUID)
                end
            end
        end
    end
    function Animation_When_Collapse()
        if Animate_FX_Width==FxGUID then 
       
            if fx.Collapse then  -- if user is collapsing 

                fx.Width_Before_Collapse = fx.Width_Before_Collapse or  fx.Width

                fx.Width, Anim_Time, fx.AnimComplete = Anim_Update( 0.1, 0.8, fx.Width_Before_Collapse or  fx.Width or  DefaultWidth or Default_WindowBtnWidth , COLLAPSED_FX_WIDTH, Anim_Time)

                if fx.AnimComplete  then 
                    
                    Animate_FX_Width = nil 
                    Anim_Time=nil
                    Long_Or_Short_FX_Idx = nil
                end
            else        --- if uncollapsing
               
                fx.Width,Anim_Time, fx.AnimComplete = Anim_Update( 0.1, 0.8, COLLAPSED_FX_WIDTH, fx.Width_Before_Collapse  or  DefaultWidth, Anim_Time)
    
                if fx.AnimComplete then 
                    Animate_FX_Width = nil 
                    fx.Width_Before_Collapse = nil 
                    Anim_Time=nil
                    Long_Or_Short_FX_Idx = nil
  
                end 

                
            end
        else 
            if fx.Collapse then fx.Width_Collapse = 27 
            else fx.Width_Collapse = nil
            end 
        end
    
    end
    
    local function AddPrmPopup()
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
                rv[i], CheckBox[i - 1] = im.Checkbox(ctx, (i - 1) .. '. ' .. P_Name, CheckBox[i - 1])
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
    end
    local function Handle_FX_DragDrop_Source(BeginDragDrop)
        if not BeginDragDrop then return end
        if Trk[TrkID].Sel_FX and Trk[TrkID].Sel_FX[1] and tablefind(Trk[TrkID].Sel_FX, FxGUID)  then
            for i, v in ipairs( Trk[TrkID].Sel_FX )do
                local id = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                DragFX_ID_Table = {}
                table.insert(DragFX_ID_Table , id )
            end
        else
            DragFX_ID = FX_Idx
            DragFxGuid = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
        end
        im.SetDragDropPayload(ctx, 'FX_Drag', FX_Idx)
        im.EndDragDropSource(ctx)
        DragDroppingFX = true
        if IsAnyMouseDown == false then DragDroppingFX = false end
        HighlightSelectedItem(0xffffff22, 0xffffffff, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)
        Post_DragFX_ID = tablefind(Trk[TrkID].PostFX, FxGUID_DragFX)
    end
    local function Create_Window_Btn()
        local LastWetKnobL, LastWetKnobT, LastWetKnobR, LastWetKnobB
        local function Draw_Vert_Text(nm, x_offset, max_height)
            local x, y = im.GetItemRectMin(ctx)
            local w, h = im.GetItemRectSize(ctx)
            local x_ofs = x_offset or 8 
            -- Available height: from draw start (y+h-15) upward to top of button (y); cap to prevent top poking out
            local available_height = math.max(0, h - 17)  -- 15 from bottom, 2px top padding
            local effective_max = math.min(max_height or available_height, available_height)
            DrawTextWithSpacing(im.GetWindowDrawList(ctx), nm, x+x_ofs ,y+h-15 , 0xffffffff, 0.6, Font_Andale_Mono_Vertical_13, "vertical_up", effective_max)
        end
        local function Add_WetDry_Knob_Below_Vert_Btn(Name)
            if fx.NoWetKnob then return end
            if not isContainer and FindStringInTable(SpecialLayoutFXs, Name) then return end
            local orig_name_for_wet = orig_Name
            if orig_name_for_wet and orig_name_for_wet:find('JS: ') then
                orig_name_for_wet = string.sub(orig_name_for_wet, 5)
            end
            if not isContainer and FindStringInTable(PluginScripts, orig_name_for_wet) then return end

            FX[FxGUID] = FX[FxGUID] or {}
            FX[FxGUID][0] = FX[FxGUID][0] or {}
            local wet_param = r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet')
            if wet_param == -1 then return end
            FX[FxGUID][0].V = FX[FxGUID][0].V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, wet_param)

            local CursorX, CursorY = im.GetCursorPos(ctx)
            local BtnL, BtnT = im.GetItemRectMin(ctx)
            local BtnR, BtnB = im.GetItemRectMax(ctx)
            local BtnW = BtnR - BtnL
            local KnobW = WET_DRY_KNOB_SZ
            local KnobX = BtnL + math.max((BtnW - KnobW) / 2, 0)
            local KnobY = BtnB + 2
            im.SetCursorScreenPos(ctx, KnobX, KnobY)
            Wet.ActiveAny, Wet.Active, FX[FxGUID][0].V = Add_WetDryKnob(ctx, 'a', '', FX[FxGUID][0].V, 0, 1, FX_Idx,nil,FxGUID)
            local kL, kT = im.GetItemRectMin(ctx)
            local kR, kB = im.GetItemRectMax(ctx)
            LastWetKnobL, LastWetKnobT, LastWetKnobR, LastWetKnobB = kL, kT, kR, kB
            im.SetCursorPos(ctx, CursorX, CursorY)
        end
        local function Add_Container_Mod_Icon_Below_Vert_Btn()
            if not isContainer then return end
            if not Modulation_Icon then return end
            local CursorX, CursorY = im.GetCursorPos(ctx)
            local IconSz = 20
            local baseL = LastWetKnobL or DragHitL
            local baseR = LastWetKnobR or DragHitR
            local baseB = LastWetKnobB or DragHitB
            if not baseL or not baseR or not baseB then return end
            local iconX = baseL + math.max((baseR - baseL - IconSz) / 2, 0)
            local iconY = baseB
            im.SetCursorScreenPos(ctx, iconX, iconY)
            Modulation_Icon(LT_Track, fx.LowestID or FX_Idx)
            im.SetCursorPos(ctx, CursorX, CursorY)
        end
        if fx.NoWindowBtn then return end 
        local Always_Vertical_Title_Btn = not NoVert and not width
        local Vertical_Title_Btn_Height = VertBtnHeight or fx.V_Win_Btn_Height or 220
        fx.Draw_Container_Title_Controls_In_Left_Column = nil
        if (not Always_Vertical_Title_Btn) and ((not fx.Collapse and not fx.V_Win_Btn_Height --[[ or isContainer ]]) or NoVert or width) then

            local Name = (fx.CustomTitle or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) )
            if DebugMode then Name = FxGUID end


            local WID = (width or fx.TitleWidth or DefaultWidth or Default_WindowBtnWidth)
            im.PushStyleVar(ctx, im.StyleVar_FrameRounding, FX_Title_Round)
            WindowBtn = im.Button(ctx, Name .. '## ' .. FxGUID,  WID - 38, WET_DRY_KNOB_SZ) -- create window name button
            Handle_FX_DragDrop_Source(im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect|im.DragDropFlags_AcceptNoPreviewTooltip|im.DragDropFlags_SourceAllowNullID))
            im.PopStyleVar(ctx)
            if isContainer then
                Highlight_Itm(WDL, nil, Cont_Clr)
            end

            Add_Prm_Btn()


        elseif Always_Vertical_Title_Btn or (fx.V_Win_Btn_Height  ) or (isContainer ) or fx.Collapse then -- Vertical btn
            
            local Name = (fx.CustomTitle or ChangeFX_Name(select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))) )
            local is_T_Split = Name == "Transient Split" and true or nil
            local is_Mid_Side_Split = Name == "Mid Side Split" and true or nil
    
            if isContainer and not is_T_Split and not is_Mid_Side_Split then
                fx.Draw_Container_Title_Controls_In_Left_Column = true
                local W = WET_DRY_KNOB_SZ or 20
                local clr = Cont_Clr
                local pad_L = 2
                local BaseX, BaseY = im.GetCursorPos(ctx)
                local img = fx.Cont_Collapse == 1 and Img.folder_list or (fx.Collapse or clr == 0xffffff99) and Img.Folder or Img.Folder_Open
                im.SetCursorPos(ctx, BaseX + pad_L, BaseY)
                im.PushStyleColor(ctx, im.Col_ButtonHovered, 0x00000000)
                im.PushStyleColor(ctx, im.Col_Button, 0x00000000)
                im.PushStyleColor(ctx, im.Col_ButtonActive, 0x00000000)
    
                if im.ImageButton(ctx,  'Folder_Icon', img ,W,W ,nil,nil,nil,nil, 0x00000000, clr)  then 

                    fx.Cont_Collapse = toggle(fx.Cont_Collapse, 1, 0 )
                end
                im.PopStyleColor(ctx,3)
                local CurY = im.GetCursorPosY(ctx)
                im.SetCursorPos(ctx, BaseX + pad_L, CurY)
    
                WindowBtn = im.Button(ctx,   '##' .. FxGUID, W, Vertical_Title_Btn_Height)
                Handle_FX_DragDrop_Source(im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect|im.DragDropFlags_AcceptNoPreviewTooltip|im.DragDropFlags_SourceAllowNullID))
                local HitL, HitT = im.GetItemRectMin(ctx)
                local HitW, HitH = im.GetItemRectSize(ctx)
                DragHitL, DragHitT, DragHitR, DragHitB = HitL, HitT, HitL + HitW, HitT + HitH
                Draw_Vert_Text(Name, 6, 200-W*3)    
                Add_WetDry_Knob_Below_Vert_Btn(Name)
                Add_Container_Mod_Icon_Below_Vert_Btn()
            elseif is_T_Split or is_Mid_Side_Split then
                if isContainer then
                    fx.Draw_Container_Title_Controls_In_Left_Column = true
                end
                local H =  170
                local W =  30 
                local x_ofs = fx.Collapse and 8 or 12
                WindowBtn = im.Button(ctx,  '##' .. FxGUID, 30, 170 )
                Handle_FX_DragDrop_Source(im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect|im.DragDropFlags_AcceptNoPreviewTooltip|im.DragDropFlags_SourceAllowNullID))
                local HitL, HitT = im.GetItemRectMin(ctx)
                local HitW, HitH = im.GetItemRectSize(ctx)
                DragHitL, DragHitT, DragHitR, DragHitB = HitL, HitT, HitL + HitW, HitT + HitH
                Draw_Vert_Text(Name, x_ofs )                
                Add_WetDry_Knob_Below_Vert_Btn(Name)
                Add_Container_Mod_Icon_Below_Vert_Btn()
            else

                WindowBtn = im.Button(ctx,  '##' .. FxGUID, 25, Vertical_Title_Btn_Height )
                Handle_FX_DragDrop_Source(im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect|im.DragDropFlags_AcceptNoPreviewTooltip|im.DragDropFlags_SourceAllowNullID))
                local HitL, HitT = im.GetItemRectMin(ctx)
                local HitW, HitH = im.GetItemRectSize(ctx)
                DragHitL, DragHitT, DragHitR, DragHitB = HitL, HitT, HitL + HitW, HitT + HitH
                Draw_Vert_Text(Name)
                Add_WetDry_Knob_Below_Vert_Btn(Name)
            end
    
    
        end

    end
    local function Store_Position_If_Dragging()
        if DragFX_ID == FX_Idx then
            -- Store the position of the dragged FX for the arrow
            local x, y, w, h
            if DragHitL and DragHitT and DragHitR and DragHitB then
                x, y = DragHitL, DragHitT
                w, h = DragHitR - DragHitL, DragHitB - DragHitT
            else
                x, y = im.GetItemRectMin(ctx)
                w, h = im.GetItemRectSize(ctx)
            end
            DragFX_Arrow_StartX  = x + w/2
            DragFX_Arrow_StartY = y 
           
        end
    end

    Push_Clr()

    Create_Window_Btn()
    im.PopStyleColor(ctx, WinbtnClrPop) -- win btn clr
    local Hover_Title_Btn_Area = DragHitL and DragHitT and DragHitR and DragHitB and im.IsMouseHoveringRect(ctx, DragHitL, DragHitT, DragHitR, DragHitB)
    local R_ClickOnWindowBtn = Hover_Title_Btn_Area and IsRBtnClicked
    local L_ClickOnWindowBtn = Hover_Title_Btn_Area and IsLBtnClicked
    local BgClr = not fx.Enable  and  0x00000088
    fx.Enable = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
    Store_Position_If_Dragging()
    Mouse_Interactions(R_ClickOnWindowBtn, L_ClickOnWindowBtn)

    if not fx.Collapse then fx.Width_Collapse= nil end


    Animation_When_Collapse()




    if Hover_Title_Btn_Area or im.IsItemHovered(ctx) then
        HelperMsg.L = 'Open FX Window'
        HelperMsg.R = 'Collapse'
        HelperMsg.Shift_L = 'Toggle Bypass'
        HelperMsg.Alt_L = 'Delete'
        HelperMsg.Alt_R = 'Collapse All'
        HelperMsg.Ctrl_R = 'Open Menu'
        HelperMsg.Need_separator = true 
        if HelperMsg.Others then
            table.insert(HelperMsg.Others, 'Ctrl+Shift+Right Click: Open Layout Editor')
        end
    end



    ----==  Drag and drop----
    if IsAnyMouseDown == false and DragDroppingFX == true then
        DragDroppingFX = false
    end

    ----Drag and drop END----
    Marquee_Selection(L_ClickOnWindowBtn, R_ClickOnWindowBtn)


    if R_ClickOnWindowBtn then
        return 2
    elseif L_ClickOnWindowBtn then
        return 1
    end


    AddPrmPopup()
    if im.BeginPopup(ctx, Fx_Module_Menu_ID) then
        local function Preset_Morph()
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
        end


        local function HandleParallelFX(FX_Idx)
            if FX_Idx > 0 then
                if im.Button(ctx, 'Parallel With Previous FX', -FLT_MIN) then 
                    r.TrackFX_SetNamedConfigParm(LT_Track,FX_Idx, 'parallel', '1')
                    im.CloseCurrentPopup(ctx)
                end
            end
        end

        local function HandleLayoutEditMode(FxGUID)
            -- Check if FX is in any container using TREE table
            local isInContainer = false
                        
            if TREE then
                local function checkInContainer(node)
                    if node.children then
                        for _, child in ipairs(node.children) do
                            local childGUID = r.TrackFX_GetFXGUID(LT_Track, child.addr_fxid or 0)
                            if childGUID == FxGUID then
                                isInContainer = true
                                return true
                            end
                            if child.children then
                                if checkInContainer(child) then
                                    return true
                                end
                            end
                        end
                    end
                    return false
                end
                
                for _, node in ipairs(TREE) do
                    if node.children then
                        if checkInContainer(node) then
                            break
                        end
                    end
                end
            end
            
            -- Return early if FX is in a container
            if isInContainer then
                im.TextColored(ctx, 0xFFFF0077, "Cannot edit layout for FX in container")
                return
            end
            if im.Button(ctx, 'Layout Edit mode', -FLT_MIN) then
                Open_Layout_Editor()
            end
        end

        local function SaveDefaultValues(FX_Idx, FX_Name)
            if im.Button(ctx, 'Save values as default', -FLT_MIN) then
                local dir_path = ConcatPath(CurrentDirectory, 'src', 'FX Default Values')
                r.RecursiveCreateDirectory(dir_path, 0)
                local nm = ChangeFX_Name(FX_Name)
                local file_path = ConcatPath(dir_path, nm .. '.ini')
                local file = io.open(file_path, 'w')
        
        
                if file then    
                    -- Check if it's a JSFX

                    local _, type  = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'fx_type')
                
                    local is_jsfx = type == 'JS'
                    if is_jsfx then
                        -- Simple format for JSFX: just parameter values, one per line
                        local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                        for i = 0, PrmCount - 1 do
                            local V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                            
                            file:write(V .. '\n')
                        end
                    else
                      
                        -- Original format for VST/AU plugins
                        file:write(nm, '\n')
                        local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx) - 4
                        file:write('Number of Params: ', PrmCount, '\n')
                        
                        local function write(i, name, Value)
                            file:write(i, '. ', name, ' = ', Value or '', '\n')
                        end
                        
                        for i = 0, PrmCount, 1 do
                            local V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                            local _, N = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                            write(i, N, V)
                        end
                    end
                    
                    file:write('\n')
                    file:close()
                end
                im.CloseCurrentPopup(ctx)
            end
        end

        local function HandleDefaultSliderWidth(FxGUID)
            if FX[FxGUID].DefType ~= 'Knob' then
                im.Text(ctx, 'Default Sldr Width:')
                im.SameLine(ctx)
                local SldrW_DrgSpd = Mods == Shift and 1 or LE.GridSize
                im.SetNextItemWidth(ctx, -FLT_MIN)

                local Edited
                Edited, FX.Def_Sldr_W[FxGUID] = im.DragInt(ctx, '##' .. FxGUID .. 'Default Width', 
                    FX.Def_Sldr_W[FxGUID] or 160, LE.GridSize, 50, 300)

                if Edited then
                    r.SetProjExtState(0, 'FX Devices', 'Default Slider Width for FX:' .. FxGUID, 
                        FX.Def_Sldr_W[FxGUID])
                end
            end
        end

        local function HandleDefaultParamType(FxGUID)
            im.Text(ctx, 'Default Param Type:')
            im.SameLine(ctx)
            im.SetNextItemWidth(ctx, -FLT_MIN)

            if im.BeginCombo(ctx, '## P type', FX[FxGUID].DefType or 'Slider', 
                im.ComboFlags_NoArrowButton) then
                local function Op(type)
                    if im.Selectable(ctx, type, false) then
                        FX[FxGUID].DefType = type 
                        Save_to_Trk('Default Param type for FX:', FX[FxGUID].DefType, LT_Track)
                    end
                end
                
                Op('Slider')
                Op('Drag')
                Op('Knob')
                im.EndCombo(ctx)
            end
        end

        -- Execute all functions
        Preset_Morph()
        HandleParallelFX(FX_Idx)
        HandleLayoutEditMode(FxGUID)
        SaveDefaultValues(FX_Idx, FX_Name)
        im.EndPopup(ctx)
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
    if type(f) == 'number' then
        return im.GetStyleColor(ctx, f)
    else

    end
end

function ThemeClr(str)
   return  _G[str] or CustomColorsDefault[str]
end

---@param ctx ImGui_Context
---@param time integer count in
function PopClr(ctx, time)
    im.PopStyleColor(ctx, time)
end

---@param CLR number
---@param HowMuch number
---@return integer
function Change_Clr_A(CLR, HowMuch, SetDirect)
    local R, G, B, A = im.ColorConvertU32ToDouble4(CLR)
    local A =SetDirect and SetDirect or SetMinMax(A + HowMuch, 0, 1)

    return im.ColorConvertDouble4ToU32(R, G, B, A)
end
---@param Clr number
---@param Scale number 
function Generate_Active_And_Hvr_CLRs(Clr, Scale)
    local sc = Scale or 1
    local ActV, HvrV
    local R, G, B, A = im.ColorConvertU32ToDouble4(Clr)
    local H, S, V = im.ColorConvertRGBtoHSV(R, G, B)
    if V > 0.9 then
        ActV = V - 0.2
        HvrV = V - 0.1
    end
    local R, G, B = im.ColorConvertHSVtoRGB(H, S, SetMinMax(ActV or V + 0.1* sc, 0, 1))
    local ActClr = im.ColorConvertDouble4ToU32(R, G, B, A)
    local R, G, B = im.ColorConvertHSVtoRGB(H, S, HvrV or V + 0.05* sc)
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
    if NEED_ATACH_NEW_FONT then return end 
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

---@param A string text for tooltip
function tooltip(A, clr, pos)
    if pos then
        if type(pos) == 'table' then
            im.SetNextWindowPos(ctx, pos[1], pos[2]+ (pos.SpacingY or 0) )
            if pos.SpacingY and pos.Line_From_PosY then 
                local X = pos.Line_From_PosX or pos[1]
                local Tk = 2 
                im.DrawList_AddLine(im.GetForegroundDrawList(ctx), X, pos.Line_From_PosY , X, pos.Line_From_PosY+ pos.SpacingY +Tk , 0xffffff44, Tk)
            end
        end
    end
    
    im.BeginTooltip(ctx)
    if clr then 
        im.PushStyleColor(ctx, im.Col_Text, clr)
    end
    im.Text(ctx, A)

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

function Tooltip_If_Itm_Hvr(Str, Distance)
    if im.IsItemHovered(ctx) then
        local Distance = Distance or - 15
        local text = Str
        local pos = {im.GetItemRectMin(ctx)}
        local w, h = im.GetItemRectSize(ctx)
        pos.Line_From_PosY = pos[2]
        pos.Line_From_PosX = pos[1] + w/2
        pos[2] = pos[2] - h
        pos.SpacingY = Distance
        tooltip(text, nil , pos)
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
function Highlight_Itm(WDL, FillClr, OutlineClr, rounding, padding, thick, ofs)
    local L, T = im.GetItemRectMin(ctx);
    local R, B = im.GetItemRectMax(ctx);
    local WDL = WDL or  im.GetWindowDrawList(ctx)
    if padding then 
        local p = padding/2
        L=L-p
        T=T-p
        R=R+p
        B=B+p
    end 
    if ofs and type(ofs) == 'table' then 
        L = L + ( ofs.L or 0)
        R = R + ( ofs.R or 0)
        T = T + ( ofs.T or 0)

        B = B + ( ofs.B or 0)
    end
    if FillClr then im.DrawList_AddRectFilled(WDL  , L, T, R, B, FillClr, rounding) end
    if OutlineClr then im.DrawList_AddRect(WDL, L, T, R, B, OutlineClr, rounding, nil, thick) end
end

function HighlightHvredItem( FillClr, OutlineClr , FillClrAct, OutlineClrAct, rounding, On_Release , trigger)
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
    --[[ local GetItemRect = GetItemRect or 'GetItemRect' ]]
    if GetItemRect == 'GetItemRect' or L == 'GetItemRect' or L == nil then

        L, T = im.GetItemRectMin(ctx); R, B = im.GetItemRectMax(ctx); w, h = im.GetItemRectSize(ctx)
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
function BlinkItem(dur, rpt, var, highlightEdge, EdgeNoBlink, L, T, R, B, h, w ,Clr)
    TimeBegin = TimeBegin or r.time_precise()
    local Now = r.time_precise()
    local EdgeClr = 0x00000000
    if highlightEdge then EdgeClr = highlightEdge end
    local GetItemRect = 'GetItemRect' ---@type string | nil
    if L then GetItemRect = nil end
    local Clr = Clr or 0xffffff77
    if rpt then
        for i = 0, rpt - 1, 1 do
            if Now > TimeBegin + dur * i and Now < TimeBegin + dur * (i + 0.5) then -- second blink
                HighlightSelectedItem(Clr, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
                    Foreground)
            end
        end
    else
        if Now > TimeBegin and Now < TimeBegin + dur / 2 then
            HighlightSelectedItem(Clr, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
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







function Draw_Attached_Drawings(FP,FX_Idx, pos, Prm_Val, Prm_Type, FxGUID, XY_Pad_Y_Val )
                            
    if not FP.Draw  and not FP.Link then return end

    local DrawTB = FP.Draw
    if FP.Link then 
        DrawTB = FP.Link.Draw
    end
    local prm = FP

    local GR = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'GainReduction_dB')))
    local x, y              = pos[1], pos[2]
    
    local Val =  Prm_Val or prm.V  or 0 
    if DraggingMorph == FxGUID then
        Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num) 
    end

    local function Draw(v)
        
        if v.Bypass then goto END_OF_LOOP end 
        local fill = v.Fill ==true  and 'Filled' 

        local function Repeat(rpt, va, Xgap, Ygap, func, Gap, RPTClr, CLR, CLR2, RPTClr2)
            if rpt and rpt ~= 0 then
                local RPT = rpt
                if va and va ~= 0 then RPT = rpt * Val * va end

                for i = 0, RPT - 1, 1 do

                    local Clr1 = (v.Clr_VA ) and BlendColors(CLR or 0xffffffff, v.Clr_VA,  Val) or CLR or 0xffffffff
                    local Clr2 = (v.RPT_Clr_VA ) and BlendColors(RPTClr or 0xffffffff, v.RPT_Clr_VA ,  Val) or RPTClr or  0xffffffff


                    local Clr = BlendColors(Clr1 , Clr2, i / RPT)

                    local Clr1 = (v.Clr2_VA ) and BlendColors(CLR2 or 0xffffffff, v.Clr2_VA,  Val) or CLR2 or 0xffffffff
                    local Clr2 = (v.RPT_Clr2_VA ) and BlendColors(RPTClr2 or 0xffffffff, v.RPT_Clr2_VA ,  Val) or RPTClr2 or  0xffffffff

                    local Clr2 = BlendColors(Clr1 , Clr2, i / RPT)
                    func(i * (Xgap or 0), i * (Ygap or 0), i * (Gap or 0), Clr, Clr2)
                end
            else
                func(Xgap)
            end
        end
        
        local Val_X = v.X_Offset_VA_BP and (Val - 0.5)* 2 * (v.X_Offset_VA or 0) or (Val * (v.X_Offset_VA or 0))
        local Val_Y = v.Y_Offset_VA_BP and (Val - 0.5)* 2 * ((v.Y_Offset_VA or 0)) or (Val * (v.Y_Offset_VA or 0))
        local x = x + (v.X_Offset or 0) + Val_X + ((GR or 0) * (v.X_Offset_VA_GR or 0))
        local y = y + (v.Y_Offset or 0) + Val_Y + ((GR or 0) * (v.Y_Offset_VA_GR or 0))


        if XY_Pad_Y_Val then 
            Val_Y = v.Y_Offset_VA_BP and (XY_Pad_Y_Val - 0.5)* 2 * ((v.Y_Offset_VA or 0)) or (XY_Pad_Y_Val * (v.Y_Offset_VA or 0))
            y = (v.Y_Offset or 0) + pos[2] + (v.Y_Offset_VA or 0) - Val_Y + ((GR or 0) * (v.Y_Offset_VA_GR or 0)) 
        end
        
        
        local Thick             = (v.Thick or 2)
        local Gap, X_Gap, Y_Gap = v.Gap, v.X_Gap, v.Y_Gap
        local Clr_VA = v.Clr_VA and  BlendColors(v.Clr or 0xffffffff, v.Clr_VA, Val)

        local X_Gap = (v.X_Gap_VA and v.X_Gap_VA ~= 0) and (v.X_Gap or 0) * Val * v.X_Gap_VA or (v.X_Gap or 0)
        local Y_Gap = (v.Y_Gap_VA and v.Y_Gap_VA ~= 0) and (v.Y_Gap or 0) * Val * v.Y_Gap_VA or (v.Y_Gap or 0)
        local Gap = (v.Gap_VA and v.Gap_VA ~= 0 and v.Gap) and v.Gap * Val * v.Gap_VA or v.Gap
        local Thick = (v.Thick_VA and v.Thick_VA ~= 0) and (v.Thick or 2) * (v.Thick_VA * Val) or (v.Thick or 2)

        local function Draw_Line_Or_Rect(v)
            if not  (v.Type == 'Line' or v.Type == 'Rect' or v.Type == 'Rect Filled') then return end
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
                local xMax, yMax = im.GetItemRectMax(ctx)
                y2 = math.min( y + (h or 10) * GR * (v.Height_VA_GR), yMax)
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
                local function AddRect(Xg, Yg, Gap, RptClr)
                    local G = Gap or 0
                    local X1, Y1 = x + (Xg or 0) - G , y + (Yg or 0) -G
                    local X2, Y2 = x2 + (Xg or 0) + G, y2 + (Yg or 0) +G
                    im.DrawList_AddRect(WDL, X1,Y1, X2, Y2 , RptClr or Clr_VA or v.Clr or 0xffffffff, v.Round, flag, Thick)
                end


                local function AddRectFill(Xg, Yg, Gap, RptClr)
                    im.DrawList_AddRectFilled(WDL, x + (Xg or 0), y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0), RptClr or Clr_VA or v.Clr or 0xffffffff, v.Round)
                end

                if v.Fill then 
                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddRectFill, Gap, v.RPT_Clr, v.Clr, v.Clr2, v.RPT_Clr2)
                else 
                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddRect, Gap, v.RPT_Clr, v.Clr, v.Clr2, v.RPT_Clr2)
                end
            end

            if v.AdjustingX or v.AdjustingY then
                local l = 4
                im.DrawList_AddLine(WDL, x - l, y - l, x + l, y + l, 0xffffffdd)
                im.DrawList_AddLine(WDL, x - l, y + l, x + l, y - l, 0xffffffdd)
            end

            
        end

        local function Draw_Circles(v)
            if not (v.Type == 'Circle' or v.Type == 'Circle Filled') then return end
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
                local clr = RptClr or Clr_VA or v.Clr or 0xffffffff
                im.DrawList_AddCircle(WDL, x + w / 2 + (X_Gap or 0), y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0), clr, nil,Thick)
            end
            local function AddCircleFill(X_Gap, Y_Gap, Gap, RptClr, RptClr2)
                local clr = RptClr or Clr_VA or v.Clr or 0xffffffff
                local clr2 = RptClr2 or v.Clr2 or 0xffffffff
                local X, Y = x + w / 2 + (X_Gap or 0), y + w / 2 + (Y_Gap or 0)

                if v.Special_Fill == 'Metallic' then
                   
                    DrawMetallicKnob(ctx, X, Y, Rad + (Gap or 0), v.Gradient_Start , v.Texture_Angle ,clr, clr2)
                elseif  v.Special_Fill == 'Gradient' then

                    Draw_Filled_Circle_With_Gradient_And_Angle( X, Y, Rad + (Gap or 0), clr, clr2, v.Gradient_Start , v.Texture_Angle or 0)
                else
                 
                    im.DrawList_AddCircleFilled(WDL, X, Y, Rad + (Gap or 0), clr)
                end
            end



            if v.Fill  then
                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddCircleFill, Gap, v.RPT_Clr, v.Clr,  v.Clr2, v.RPT_Clr2)
            else 
                Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddCircle, Gap, v.RPT_Clr, v.Clr, v.Clr2, v.RPT_Clr2)
            end

            if v.AdjustingX or v.AdjustingY then
                local l = 4
                local x, y = x + Rad / 2, y + Rad / 2
                im.DrawList_AddLine(WDL, x - l, y - l, x + l, y + l, 0xffffffdd)
                im.DrawList_AddLine(WDL, x - l, y + l, x + l, y - l, 0xffffffdd)
            end
        end

        local function Draw_Knob_Pointer_Or_Range_Or_Image(v)
            local types = {'Knob Pointer', 'Knob Range', 'Knob Circle Filled', 'Knob Circle', 'Knob Image', 'Knob Numbers'}
            if not tablefind(types, v.Type) then return end
            local w, h = im.GetItemRectSize(ctx)
            local h = w 
            local x, y = x + w / 2 + (v.X_Offset or 0), y + w / 2 + (v.Y_Offset or 0)
            
            local ANGLE_MIN = 3.141592 * (v.Angle_Min or 0.75)

            local ANGLE_MAX = 3.141592 * (v.Angle_Max or 2.25) + (v.Angle_Max_VA_GR or 0) * (GR or 0)


            local VV = v.Angle_Max_VA_BP and (Val-0.5 )*2 or Val 
            local t = (v.Angle_Max_VA and v.Angle_Max_VA~=0) and VV * v.Angle_Max_VA  or VV
            local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
            local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
            local IN = v.Rad_In or 0 -- modify this for the center begin point
            local OUT = v.Rad_Out or 0
            local Def_W = w / 2 
            local W = v.Width or Def_W
            
            if v.Type == 'Knob Pointer' then
               -- im.DrawList_AddLine(WDL, x + angle_cos * IN, y + angle_sin * IN, x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick), Clr_VA or v.Clr or 0x999999aa, Thick)
               
               local function Draw_Pointer (angle, angle_cos, angle_sin)
                    local function drawTrianglePointer(triangleWidth)
                        local triangleSize = (OUT - IN) * 0.6 -- Reduced size for a shorter triangle
                        local tipX, tipY = x + angle_cos * OUT, y + angle_sin * OUT
                        local baseX, baseY = x + angle_cos * IN, y + angle_sin * IN
                        local perpX, perpY = -angle_sin, angle_cos
                        local WID = triangleWidth or 0.45 -- Width of the triangle base, default to 0.45 if not provided
    
                        local leftX = baseX + perpX * triangleSize * WID
                        local leftY = baseY + perpY * triangleSize * WID
                        local rightX = baseX - perpX * triangleSize * WID
                        local rightY = baseY - perpY * triangleSize * WID
                        
                        im.DrawList_AddTriangleFilled(WDL, tipX, tipY, leftX, leftY, rightX, rightY, Clr_VA or v.Clr or 0x999999aa)
                    end

                    if not v.Pointer_Type or v.Pointer_Type == 'Line'   then
                        im.DrawList_AddLine(WDL, x + angle_cos * IN, y + angle_sin * IN, x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick), Clr_VA or v.Clr or 0x999999aa, Thick)
                    elseif v.Pointer_Type == 'Cursor' then
                    -- im.DrawList_AddLine(WDL, x + angle_cos * IN, y + angle_sin * IN, x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick), Clr_VA or v.Clr or 0x999999aa, Thick)
                        
                        local pointerSize = (OUT - IN) * 0.2
                        local pointerX = x + angle_cos * (OUT - pointerSize*2.5)
                        local pointerY = y + angle_sin * (OUT - pointerSize*2.5)  
                        local pointerColor = Clr_VA or v.Clr or 0x999999aa
                        local pointerAngle = angle + math.pi / 2 -- Adjust angle to point away from the center

                        Draw_A_Cursor_Shape(pointerX, pointerY, pointerSize, pointerColor, pointerAngle, v.Thick or 0.45, v.Shape or 0.45)
                    elseif v.Pointer_Type == 'Triangle' then
                        drawTrianglePointer((v.Thick or 0.9) / 2)
                    elseif v.Pointer_Type == 'Circle' then
                        if v.Fill then 
                            im.DrawList_AddCircleFilled(WDL, x + angle_cos * IN, y + angle_sin * IN -1 , W, v.Clr or 0x999999aa, nil)
                        else
                            im.DrawList_AddCircle(WDL, x + angle_cos * IN, y + angle_sin * IN -1 , W,  v.Clr or 0x999999aa, nil, Thick)
                        end
                    end
                end
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

                        Draw_Pointer(angle, angle_cos, angle_sin)
                    end
                else 
                    Draw_Pointer(angle, angle_cos, angle_sin)
                end



            
            elseif v.Type == 'Knob Range' or v.Type =='Knob Numbers' then
                local function AddRange(G)
                    if  v.Repeat and v.Repeat~= 0 then 
                        local rpt = (v.Repeat_VA and v.Repeat_VA~= 0) and Val * v.Repeat_VA or 1
                        local gap = (v.Gap_VA and v.Gap_VA~= 0) and Val * v.Gap* v.Gap_VA or 1   

                        if v.Type == 'Knob Numbers' then
                            
                            for i = 0, v.Repeat* (rpt ) , math.max(1*gap, 0.01) do 
                                local t = (i/v.Repeat- 0) / (1 - 0)
                                local VV = v.Angle_Max_VA_BP and (Val-0.5 )*2 or Val 
                                local VV = v.Type == 'Knob Numbers' and i or VV
                                local  ANGLE_MAX = (v.Angle_Max_VA and v.Angle_Max_VA~=0) and ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN)   * (VV * v.Angle_Max_VA) or ANGLE_MAX
                                local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                                local angle_cos, angle_sin = math.cos(angle), math.sin(angle)

                                local x1, y1 = x + angle_cos * IN,  y + angle_sin * IN
                                local x2, y2 = x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick)
                                local Clr = BlendColors(v.Clr or 0xffffffff, v.RPT_Clr or 0xffffffff, i / v.Repeat)
                                if v.Type == 'Knob Numbers' then
                                    local hi, lo = v.Value_Range_High or v.Repeat, v.Value_Range_Low or 0
                                    local val =  (i / v.Repeat) * (hi - lo) + lo
                                    local val = round(val, v.Decimal_Places or 1)
                                    local val = (v.Decimal_Places == 0 or not v.Decimal_Places) and math.floor(val) or val
                                    local TxtW, TxtH = im.CalcTextSize(ctx, tostring(val))
                                    local x1, y1 = x1-TxtW/3 , y1- TxtH/2.1
                                    
                                    im.DrawList_AddTextEx(WDL, Arial_12, 12, x1, y1, Clr or v.Clr or 0x999999aa, tostring(val))
                                else
                                    im.DrawList_AddLine(WDL, x1, y1, x2, y2, Clr or v.Clr or 0x999999aa, Thick)
                                end
                            end
                        end
                    end


                    for i = IN, OUT, (1 + (v.Gap or 0)) do
                        --local ANGLE_MIN = v.Angle_Min_VA and ANGLE_MIN \
                        local VV = v.Angle_Max_VA_BP and (Val-0.5 )*2 or Val 
                        if v.Angle_Max_VA and v.Angle_Max_VA~=0 then 
                            VV = VV * v.Angle_Max_VA
                        elseif v.Angle_Max_VA and v.Angle_Max_VA== 0 then 
                            VV = 1
                        else 
                            VV = VV
                        end 
                        
                        -- Add gain reduction effect if Angle_Max_VA_GR is set
                        if v.Angle_Max_VA_GR and v.Angle_Max_VA_GR ~= 0 and GR then
                            VV =  math.max(( (GR/12) * v.Angle_Max_VA_GR), 0 )
                        end
                        
                        local ANGLE_MAX =  ANGLE_MIN +(ANGLE_MAX - ANGLE_MIN) * VV  

        
                        -- local ANGLE_MAX = v.Angle_Max_BP and ANGLE_MIN +(ANGLE_MAX - ANGLE_MIN) * ((Val-0.5 )*2) or ANGLE_MAX
                        im.DrawList_PathArcTo(WDL, x, y, i, ANGLE_MIN,SetMinMax(ANGLE_MIN +(ANGLE_MAX - ANGLE_MIN)  ,ANGLE_MIN, ANGLE_MAX))
                        im.DrawList_PathStroke(WDL, Clr_VA or v.Clr or 0x999999aa, nil, Thick)
                        im.DrawList_PathClear(WDL)
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

                        local x1, y1 = x + angle_cos * IN,  y + angle_sin * IN
                        local x2, y2 = x + angle_cos * (OUT - Thick), y + angle_sin * (OUT - Thick)

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
        end

        local function Draw_Image(v)
            if not v.Image then return end
            local w, h = im.Image_GetSize(v.Image)
            local Def_W = Get_Default_Param_Width_By_Type(FP.Type)
            if FP.Type == 'Knob' then Def_W = Def_W * 2 end
            local w , h = FP.Sldr_W or Def_W , FP.Height or FP.Sldr_W or Def_W

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


            Repeat(v.Repeat, v.Repeat_VA, v.X_Gap or 0, v.Y_Gap or 0, AddImage, nil, v.RPT_Clr, v.Clr,v) 
        end
        local function Draw_Gain_Reduction_Text(v)
            if v.Type == 'Gain Reduction Text' and not FX[FxGUID].DontShowGR then
                local GR = round(GR, 1)
                im.DrawList_AddTextEx(WDL, Arial_12, 12, x, y, v.Clr or 0xffffffff, GR or '')
            end
        end


        Draw_Line_Or_Rect(v)    
        Draw_Circles(v)
        Draw_Knob_Pointer_Or_Range_Or_Image(v)
        Draw_Image(v)
        Draw_Line_Or_Rect(v)
        Draw_Gain_Reduction_Text(v)
        ::END_OF_LOOP::
    end
    if DrawTB then 
        for i, v in ipairs(DrawTB) do
            
            if type(v)== 'table' then 
                for I, V in ipairs(v) do 
                    if not  v.Bypass then 
                        Draw(V)
                    end
                end 
                Draw(v)
            end
        end
    end

end

function TrashIcon(size, lbl, ClrBG, ClrTint)
    local rv = im.ImageButton(ctx, '##' .. lbl, Img.Trash, size, size, nil, nil, nil, nil, ClrBG, ClrTint) 
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




function DrawMetallicKnob(ctx, centerX, centerY, radius, gradientRepeats, startAngle, startColorHex, endColorHex)
    local drawList = im.GetWindowDrawList(ctx)
    local segments = 64  -- Adjust for smoother circle
    local overlap = 0.1  -- Overlap factor
    local startAngle = startAngle or 0
    -- Create a radial gradient effect with overlapping triangles
    for i = 0, segments do
        local angle = startAngle + (i / segments) * 2 * math.pi
        local nextAngle = startAngle + ((i + 1 + overlap) / segments) * 2 * math.pi
        local x1 = centerX + math.cos(angle) * radius
        local y1 = centerY + math.sin(angle) * radius
        local x2 = centerX + math.cos(nextAngle) * radius
        local y2 = centerY + math.sin(nextAngle) * radius

        -- Repeat the gradient
        local t = (1 + math.cos(gradientRepeats * angle)) / 2
        local r1, g1, b1, a1 = ((startColorHex >> 24) & 0xFF) / 255, ((startColorHex >> 16) & 0xFF) / 255, ((startColorHex >> 8) & 0xFF) / 255, (startColorHex & 0xFF) / 255
        local r2, g2, b2, a2 = ((endColorHex >> 24) & 0xFF) / 255, ((endColorHex >> 16) & 0xFF) / 255, ((endColorHex >> 8) & 0xFF) / 255, (endColorHex & 0xFF) / 255
        local r = r1 + (r2 - r1) * t
        local g = g1 + (g2 - g1) * t
        local b = b1 + (b2 - b1) * t
        local a = a1 + (a2 - a1) * t
        local col = im.ColorConvertDouble4ToU32(r, g, b, a)
        
        im.DrawList_AddTriangleFilled(drawList, centerX, centerY, x1, y1, x2, y2, col)
    end

    -- Outer ring
    local outerRingColor = im.ColorConvertDouble4ToU32(0.1, 0.1, 0.1, 1)
    im.DrawList_AddCircle(drawList, centerX, centerY, radius, outerRingColor, segments, 1)
end
    
-- Function to draw a filled circle with lines at a certain angle and gradient color
function Draw_Filled_Circle_With_Gradient_And_Angle(centerX, centerY, radius, colorTop, colorBottom, gradientStart, angle)
    local DL = im.GetWindowDrawList(ctx)
    
    -- Convert the angle to radians for trigonometric functions
    local angleRad = math.rad(angle)
    local thickness = 1
    local gradientStart = gradientStart or 0
    -- Loop through the vertical positions (y-axis)
    for y = -radius, radius, thickness do
        -- Calculate the relative position in the circle
        local relativeY = (y + radius) / (2 * radius)

        -- Adjust t to control when the gradient starts
        local t
        if relativeY < gradientStart then
            t = 0  -- Stay fully at top color before gradient starts
        else
            -- Gradually interpolate from gradientStart to the bottom
            t = (relativeY - gradientStart) / (1 - gradientStart)
        end

        -- Interpolate color based on y position (gradient transition)
        local color = BlendColors(colorTop, colorBottom, t)

        -- Calculate the half-width (x) at this vertical position
        local x = math.sqrt(radius * radius - y * y)

        -- Rotate the line endpoints by the given angle
        local rotatedX1 = centerX + (x * math.cos(angleRad) - y * math.sin(angleRad))
        local rotatedY1 = centerY + (x * math.sin(angleRad) + y * math.cos(angleRad))
        local rotatedX2 = centerX + (-x * math.cos(angleRad) - y * math.sin(angleRad))
        local rotatedY2 = centerY + (-x * math.sin(angleRad) + y * math.cos(angleRad))

        -- Draw a rotated line from (rotatedX1, rotatedY1) to (rotatedX2, rotatedY2)
        im.DrawList_AddLine(DL, rotatedX1, rotatedY1, rotatedX2, rotatedY2, color, thickness+ thickness/5)
    end
end


function AddSpaceBtwnFXs_LAST(FX_Idx, FxGUID)
    if FX_Idx + 1 == Sel_Track_FX_Count --[[ and not Trk[TrkID].PostFX[1] ]] then -- add last space
        SL(nil, 10)
        AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc', nil,nil,nil,100, nil, true)
    elseif FX_Idx + 1 == Sel_Track_FX_Count and Trk[TrkID].PostFX[1] then
        AddSpaceBtwnFXs(Sel_Track_FX_Count - #Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
    end


end

function Show_Drag_FX_Preview_Tooltip(FxGUID, FX_Idx)
    if FX.LayEdit then return end  
    im.BeginTooltip(ctx)
    AddWindowBtn(FxGUID, FX_Idx ,nil,nil,nil,nil,true)
    im.EndTooltip(ctx)
end

function Store_Parallel_FX_Enclosure_Pos(FX_Idx, FxGUID, Parallel, PosX_before_FX_Win, DL, Clr)

    if Parallel == 'Mixer Layout - Show'  and not FX[FxGUID].Collapse then   

        local DL = DL or Glob.WDL



        local l, t  =  im.GetItemRectMin(ctx)
        local w, h = im.GetItemRectSize(ctx)
        local thick = 8
        local H = 10

        
        --[[ l = l - H/2 - Win_W ]]
        local l =PosX_before_FX_Win
       -- local l =  l + PAR_FX_MIXER_WIN_W +5


        local R = l +   (FX[FxGUID].Width_Collapse or FX[FxGUID].Width or 170)
        local B = t +225

        DRAW_PAR_ENCLOSURE = DRAW_PAR_ENCLOSURE or {}
        --DRAW_PAR_ENCLOSURE[FxGUID] =  {l =l ; t =t ; R =R ; B =B }
        DRAW_PAR_ENCLOSURE[FxGUID] = DRAW_PAR_ENCLOSURE[FxGUID] or {}
        DRAW_PAR_ENCLOSURE[FxGUID].l = l
        DRAW_PAR_ENCLOSURE[FxGUID].R= R
        DRAW_PAR_ENCLOSURE[FxGUID].t = t
        DRAW_PAR_ENCLOSURE[FxGUID].B = B


        for k, v in pairs(DRAW_PAR_ENCLOSURE) do
            if not v.t then return end
            local l = v.l
            local t = v.t - 10
            local R = v.R
            local B = v.B


        end
        --[[ im.DrawList_AddLine(DL, l , B, R, B, Clr.PAR_FX[1], thick) -- horizontal line
        local t = t - thick/2
        im.DrawList_AddLine(DL, l , t , l, t + H, Clr.PAR_FX[1], thick)
        im.DrawList_AddLine(DL, R , t , R, B, Clr.PAR_FX[1], thick) -- Vertical line on the right

        im.DrawList_AddLine(DL, R , t, R, t + H, Clr.PAR_FX[1], thick) ]]
        im.SameLine(ctx, nil, 0)   
       --[[ if FX_Idx > 0x2000000 then
            AddSpaceBtwnFXs(FX_Idx, FxGUID, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, Additional_W ,nil,nil, Clr)
       end ]]
    elseif rv and ret == '1' and not FX[FxGUID].ShowParallel and Parallel ~= 'Complex' and Parallel ~= 'Mixer Layout - Hide' then
        im.SetCursorPos(ctx, CurPos_Aftr_Create_FX_Win_SL[1], CurPos_Aftr_Create_FX_Win_SL[2]) 

    else  
        im.SameLine(ctx, nil, 0)   
        --[[ if FX_Idx > 0x2000000 then
            AddSpaceBtwnFXs(FX_Idx, FxGUID, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, Additional_W ,nil,nil, Clr)
        end ]]
        --AddSpaceBtwnFXs(FX_Idx, FxGUID, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth,nil,nil, SpaceClr)

    end

end

function Draw_Parallel_FX_Enclosure()

    if not DRAW_PAR_ENCLOSURE then return end


    local DL = Glob.WDL
    local thick = 5
    local H = 10

    for k, v in pairs(DRAW_PAR_ENCLOSURE) do
        local Parent_guid = FX[k].parent and r.TrackFX_GetFXGUID(LT_Track, FX[k].parent) or nil

        if Parent_guid and  FX[Parent_guid].Collapse then goto End_OF_LOOP end 
        local ID = v.ID or 1
        if not v.t then return end 
        local l = v.l
        local t = v.t -5
        local R = v.R
        local B = v.B

        im.DrawList_AddLine(DL, l  - thick /2 , t, R + thick / 2, t, Clr.PAR_FX[ID], thick) -- horizontal line
        --local t = t - thick/2
        im.DrawList_AddLine(DL, l , t , l, t + H, Clr.PAR_FX[ID], thick) -- vertical line
        im.DrawList_AddLine(DL, R , t , R, t + H, Clr.PAR_FX[ID], thick) -- vertical line
        ::End_OF_LOOP::
    end


end


function Highlight_selected_FX(FX_Idx)
    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

    local Sel_FX = Trk[TrkID].Sel_FX
    if Sel_FX and Sel_FX[1] then 
        local parents = {}
        for i, v in ipairs(Sel_FX) do   
            local v = Find_FxID_By_GUID (v)
            if v then 
                local rv, buf = r.TrackFX_GetNamedConfigParm( LT_Track, v, 'parent_container' )
                if tonumber(buf) then 
                    table.insert(parents,tonumber(buf))
                end
            end
        end


        if tablefind(Sel_FX, FxGUID) then 
            Highlight_Itm(Glob.WDL, nil, 0xffffffaa, 2, nil , 3, {T = -3 ; B = 3})
        elseif not tablefind(parents, FxGUID) then
            Highlight_Itm(Glob.WDL, 0x00000055)
        end
    end
end
function createFXWindow(FX_Idx, Cur_X_Ofs)

    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
    local WindowSize

    if not FxGUID then return end 
    FX[FxGUID] = FX[FxGUID] or {}
    local fx = FX[FxGUID]

    Layout_Edit_Properties_Window(fx,FX_Idx)

    fx.Enable = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)

    --local FxGUID = FXGUID[FX_Idx]
    local FxNameS = fx.ShortName
    local Hide
    local rv, orig_Name = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')
    local IsContainer = orig_Name == 'Container' and true 

   
    local enclosed_text = extract_enclosed_text(FX_Name)
    if enclosed_text then
        local rename = string.gsub(FX_Name, "%s*%[.-%]%s*", "")
        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "renamed_name", rename)
    end
    local  _, orig_name=  r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')

    local _, fx_ident = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'fx_ident') -- by default \\Plugins\\FX\\reasamplomatic.dll<1920167789 or /Applications/REAPER.app/Contents/Plugins/FX/reasamplomatic.vst.dylib<1920167789

    FX_Name = fx_ident:find("1920167789") and  'ReaSamplOmatic5000' or FX_Name
    FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
    FX_Name = string.gsub(FX_Name, '-', ' ')
    WDL = im.GetWindowDrawList(ctx)


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
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', presetname, true)
                    elseif rv and AB == 'B' then
                        FX[FxGUID].MorphB_Name = presetname
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', presetname, true)
                    end
                end
            end

            im.SetNextItemWidth(ctx, 20)
            local x, y = im.GetCursorPos(ctx)
            x = x - 2
            local SCx, SCy = im.GetCursorScreenPos(ctx)
            SCx = SCx - 2
            im.SetCursorPosX(ctx, x)

            im.PushStyleColor(ctx, im.Col_Button,DefClr_A) im.PushStyleColor(ctx, im.Col_ButtonHovered, DefClr_A_Hvr) im.PushStyleColor(ctx, im.Col_ButtonActive, DefClr_A_Act)


            if im.Button(ctx, 'A##' .. FxGUID, 20, 20) then
                StoreAllPrmVal('A', nil, FX[FxGUID].Morph_ID)
                MORPH__NEED_TO_REFRESH = 1
            end
            im.PopStyleColor(ctx,3)


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
                -- Help: Morph control hover actions
                HelperMsg.Ctrl_R = 'Open Morphing menu'
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

                        SetPrmAlias(LT_TrackNum, 1, 8 + FX[FxGUID].Morph_ID, fx.ShortName:gsub("%b()", "") .. ' - Morph AB ')
                    end
                elseif FX[FxGUID].Morph_ID or not FX[FxGUID].Unlink then
                    if im.Selectable(ctx, 'Unlink Parameters to Morph Automation', false) then
                        for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. i .. ".plink.active", 0) -- 1 active, 0 inactive
                        end
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Morph_ID' .. FxGUID, FX[FxGUID].Morph_ID, true) FX[FxGUID].Unlink = true
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', 'Unlink', true)
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
                BtnB_TxtClr = im.GetStyleColor(ctx, im.Col_TextDisabled)
            end

            if BtnB_TxtClr then
                im.PushStyleColor(ctx, im.Col_Text, im.GetStyleColor(ctx, im.Col_TextDisabled))
            end
            im.PushStyleColor(ctx, im.Col_Button, DefClr_B)
            im.PushStyleColor(ctx, im.Col_ButtonHovered, DefClr_B_Hvr)
            im.PushStyleColor(ctx, im.Col_ButtonActive, DefClr_B_Act)

            if im.Button(ctx, 'B##' .. FxGUID, 20, 20) then
                StoreAllPrmVal('B', nil, FX[FxGUID].Morph_ID)
                local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                MORPH__NEED_TO_REFRESH = 2
                if rv then FX[FxGUID].MorphB_Name = presetname end
            end
            if im.IsItemHovered(ctx) and FX[FxGUID].MorphB_Name then
                tooltip(FX[FxGUID]
                    .MorphB_Name)
            end
            im.PopStyleColor(ctx, 3)

            if BtnB_TxtClr then im.PopStyleColor(ctx) end
            if fx.Enable == false then
                im.DrawList_AddRectFilled(WDL, L, T - 10, R, B + 20, 0x00000088)
            end

            im.SetCursorPos(ctx, OrigCurX + 19, OrigCurY)
        end
    end




    function If_Parallel_FX(FX_Idx)

        local function ChangeWetVal (FxGUID, i ,wet_p_num , Val )
            r.TrackFX_SetParamNormalized(LT_Track, i, wet_p_num, Val)
            --FX[FxGUID][0].V = Val
        end 
        local Win_W  = PAR_FX_MIXER_WIN_W


        --- if Mixer Layout 
        for i , v in ipairs(PAR_FXs) do 
            local ROOT_FXGUID = v[1].guid
           



            if v[1] and FX_Idx == v[1].addr_fxid then          -- if it's the root of parallel FX , create mixer 
                local SpaceClr
                for i , v in ipairs(PAR_FXs) do  
                    if FX[v[1].guid].parent then -- if the root FX is in a container
                        local Parent_guid = r.TrackFX_GetFXGUID(LT_Track, FX[v[1].guid].parent)
        
                        SpaceClr = Calculate_Color_Based_On_Nesting_Level(FX[Parent_guid].nestingLevel )
                        SpaceClr = HSV_Change(SpaceClr, nil, nil, -0.8) 
                    end
                end
        
                --ROOT_FXGUID = FxGUID
                local function Add_Space_If_No_Chosen_FX()
                    if not FX[FxGUID].ChosenFX then 
                        local Scale = v[1].addr_fxid> 0x2000000 and v[1].scale or 1 
                        if FX_Idx > 0x2000000 then
                            AddSpaceBtwnFXs(v[#v].addr_fxid + v[1].scale , FxGUID, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth,nil,nil, SpaceClr)
                        end
                       -- 
                    end
                end

                im.PushStyleColor(ctx, im.Col_ChildBg, 0x202020ff)
                im.PushStyleVar(ctx, im.StyleVar_ScrollbarSize, 10)
                POS_X_BEFORE_MIXER = im.GetCursorScreenPos(ctx)
                if im.BeginChild(ctx, '##Parallel FX' .. FX_Idx , Win_W , 220,nil, im.WindowFlags_NoScrollWithMouse|im.WindowFlags_NoScrollbar) then
                    --[[ local l, t = im.GetCursorScreenPos(ctx)
                    im.DrawList_AddRect(WDL, l , t , l + Win_W +5 ,t + 220, 0xff22ffff) ]]
                    local pad = 2   
                    local Width = 110
                    local height = 17
                    im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 1, 1)

                    --[[ im.Button(ctx, 'Parallel FXs', Width+height*3)  

                    if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                        im.SetDragDropPayload(ctx, 'Parallel_FX_Drag', FX_Idx)
                        im.EndDragDropSource(ctx)
                    end ]]

                    if im.BeginChild(ctx, '##Parallel FX Mixer' .. FX_Idx , Win_W  , 190,nil, im.WindowFlags_NoScrollbar) then

                        for I, V in ipairs(v) do

                            local Width = 110
                            local _, Orig_Nm = r.TrackFX_GetNamedConfigParm(LT_Track, V.addr_fxid, 'original_name')
                            local Is_Cont =  Orig_Nm == 'Container' and true  
                
                            if DRAW_PAR_ENCLOSURE then 
                                if FX[v[1].guid].ChosenFX ==V.guid  then 
                                    DRAW_PAR_ENCLOSURE[V.guid ] = {}
                                    DRAW_PAR_ENCLOSURE[V.guid ].ID = I
                                end
                            end 
                            --local FX_Idx = i -1 
                            local Label =  '##DryWet' .. FX_Idx
                            local wet_p_num =  r.TrackFX_GetParamFromIdent(LT_Track, V.addr_fxid, ':wet') 
                            --local FxGUID = r.TrackFX_GetFXGUID(LT_Track, v)
                            local FxGUID = V.guid
                            FX[FxGUID] = FX[FxGUID] or {}
                            local FX_Name = FX[FxGUID].CustomTitle or  ChangeFX_Name(V.name)
                            FX[FxGUID][0] = FX[FxGUID][0] or {}

                            
                            
                            local function Solo()
                                --local FxGUID = V.guid   

                                local Solo_ClrPop = Button_Color_Change(FX[FxGUID].Solo , Layer_Solo )
                                im.PushStyleColor(ctx, im.Col_Button, Change_Clr_A (im.GetStyleColor(ctx, im.Col_Button), 1))
                                im.PushStyleColor(ctx, im.Col_ButtonHovered, Change_Clr_A (im.GetStyleColor(ctx, im.Col_ButtonHovered ), 1))
                                im.PushStyleColor(ctx, im.Col_ButtonActive, Change_Clr_A (im.GetStyleColor(ctx, im.Col_ButtonActive ), 1))

                                if im.Button(ctx, 'S##Solo'..FxGUID, height, height*2) then 
                                    FX[FxGUID].Solo = toggle(FX[FxGUID].Solo)
                                    Save_to_Trk('Parallel Solo ' .. FxGUID, FX[FxGUID].Solo )
                                    local Scale = v[1].addr_fxid> 0x2000000 and V.scale or 1 
                                    local Rpt_Limit = v[1].addr_fxid> 0x2000000 and v[1].addr_fxid +   #v * Scale - Scale or #v - 1 
                                    local Solo_Count = 0    
                                    

                                    local function Count_Solo_Count(node)
                                        local FxGUID =  r.TrackFX_GetFXGUID(LT_Track, node.addr_fxid)
                                        if FxGUID and FX[FxGUID].Solo then   
                                            Solo_Count = Solo_Count + 1 
                                        end 
                                    end 

                                    local function Do_Solo_Or_Unsolo(node)
                                        local fx_idx = node.addr_fxid
                                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, fx_idx)
                                        
                                        if FxGUID then
                                            local function Restore_Val()
                                                local V = FX[FxGUID].Wet_V_before_solo or FX[FxGUID][0].V or r.TrackFX_GetParamNormalized(LT_Track, fx_idx, FX[FxGUID][0].Num)
                                                r.TrackFX_SetParamNormalized(LT_Track, fx_idx, FX[FxGUID][0].Num, V)
                                                Save_to_Trk('Wet_V_before_solo ' .. FxGUID,'' )
                                            end
                                            
                                            if Solo_Count > 0 then 
                                                if not FX[FxGUID].Solo then 
                                                    if FX[FxGUID][0].V ~= 0 then 
                                                        FX[FxGUID].Wet_V_before_solo = FX[FxGUID][0].V 
                                                        Save_to_Trk('Wet_V_before_solo ' .. FxGUID, FX[FxGUID][0].V)
                                                    end
                                                    r.TrackFX_SetParamNormalized(LT_Track, fx_idx, FX[FxGUID][0].Num, 0)
                                                else    -- if soloed 
                                                    Restore_Val()
                                                end
                                            else    
                                                Restore_Val()
                                            end
                                            -- Update the current value
                                            FX[FxGUID][0].V = r.TrackFX_GetParamNormalized(LT_Track, fx_idx, FX[FxGUID][0].Num)
                                        end
                                        
                                    end
                                    
                                    for i , vv in ipairs(v) do 

                                        Count_Solo_Count(vv)
                                    end


                                    
                                    -- Process all nodes in the TREE
                                    for i , vv in ipairs(v) do 
                                        Do_Solo_Or_Unsolo(vv)
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

                                if im.Button(ctx, 'M##Mute'..FxGUID, height, height*2) then 
                                    FX[FxGUID].Mute = toggle(FX[FxGUID].Mute)
                                    Save_to_Trk('Parallel Mute ' .. FxGUID, FX[FxGUID].Mute )
                                    local Scale = v[1].addr_fxid> 0x2000000 and V.scale or 1 
                                    local Rpt_Limit = v[1].addr_fxid> 0x2000000 and v[1].addr_fxid +   #v * Scale - Scale or #v - 1 


                                    local Mute_Count = 0
                                    for i, vv in ipairs(v) do
                                        local FxGUID =  r.TrackFX_GetFXGUID(LT_Track, vv.addr_fxid)
                                        Mute_Count = ( FxGUID and FX[FxGUID].Mute) and Mute_Count + 1  or Mute_Count
                                    end

                                    -- Loop through all FX in the parallel chain

                                    local function Do_Mute_Or_Unmute(node)
                                        local i = node.addr_fxid
                                        local FxGUID =  r.TrackFX_GetFXGUID(LT_Track, i) 
                                        local function Restore_Val ()

                                            local V = FX[FxGUID].Wet_V_before_mute or FX[FxGUID][0].V or  r.TrackFX_GetParamNormalized(LT_Track, i, FX[FxGUID][0].Num)
                                            -- Restore previous wet value
                                            r.TrackFX_SetParamNormalized(LT_Track, i, FX[FxGUID][0].Num, V)
                                            Save_to_Trk('Wet_V_before_mute ' .. FxGUID, '')
                                        end


                                        if Mute_Count > 0 then 
                                            if FX[FxGUID].Mute then

                                                -- Store current wet value before muting
                                                if FX[FxGUID][0].V  ~= 0 then 
                                                    FX[FxGUID].Wet_V_before_mute = FX[FxGUID][0].V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FX[FxGUID][0].Num)
                                                    Save_to_Trk('Wet_V_before_mute ' .. FxGUID, FX[FxGUID].Wet_V_before_mute)    
                                                end
                                                -- Set this FX's wet value to 0 (mute it)
                                                r.TrackFX_SetParamNormalized(LT_Track, i, FX[FxGUID][0].Num, 0)

                                            else -- if muted
                                                Restore_Val ()
                                            end
                                        else 
                                            Restore_Val ()
                                        end
                                        -- Update the current value
                                        FX[FxGUID][0].V = r.TrackFX_GetParamNormalized(LT_Track, i, FX[FxGUID][0].Num)
                                    end

                                    for i , vv in ipairs(v) do 
                                        Do_Mute_Or_Unmute(vv)
                                    end
                                    

                                end
                                
                                if LyrMuteClrPop then 
                                    im.PopStyleColor(ctx, LyrMuteClrPop)
                                end 

                                im.PopStyleColor(ctx, 3 )
                            end

                            local function Add_Container_Btn()
                                local Btn_Clr = FX[V.guid].Add_Cont_Btn_Hvr and 0xffffff11 or 0x00000000
                                local x , y = im.GetCursorPos(ctx)
                                local height = im.GetTextLineHeight(ctx)
                                SL(nil,0)

                                if   Is_Cont then 
                                    im.PushStyleColor(ctx, im.Col_Button, Btn_Clr)
                                    im.PushStyleColor(ctx, im.Col_ButtonHovered, Btn_Clr)
                                    local tint = Clr.PAR_FX[I]
    
                                    local rv = im.ImageButton(ctx, 'Add Container '..V.guid, Img.Folder, height , height, nil,nil,nil,nil, nil,tint)

                                    im.PopStyleColor(ctx, 2)
                                    im.SetCursorPos(ctx, x - pad*2, y  )
                                    
                                    
                                    return 
                                end 
                                local tint = FX[V.guid].Add_Cont_Btn_Hvr and 0xffffffff or 0xffffff77

                                im.PushStyleColor(ctx, im.Col_Button, Btn_Clr)
                                im.PushStyleColor(ctx, im.Col_ButtonHovered, Btn_Clr)


                                local rv = im.ImageButton(ctx, 'Add Container '..V.guid, Img.folder_add, height , height, nil,nil,nil,nil, nil,tint)
                                if im.IsItemHovered(ctx) then 
                                    FX[V.guid].Add_Cont_Btn_Hvr = true 
                                else 
                                    FX[V.guid].Add_Cont_Btn_Hvr = nil
                                end
                                if rv then 
                                    r.Undo_BeginBlock()
                                    local FX_Idx_Before_Add = V.addr_fxid
                                    local _, ret = r.TrackFX_GetNamedConfigParm(LT_Track, V.addr_fxid, 'parallel')

                                    if ret =='0' then -- if it's the root fx , which means it's not parallel with previous fx
                                        --r.TrackFX_SetNamedConfigParm(LT_Track,  V.addr_fxid, 'parallel', '1')
                                    end

                                    local nxt , prev = GetNextAndPreviousFXID(V.addr_fxid)
                                    local cont = AddFX_HideWindow(LT_Track, 'Container', -1000 - nxt ) 

                                    if ret == '1' then 
                                        r.TrackFX_SetNamedConfigParm(LT_Track, cont, 'parallel', '1')
                                    end

                                    local rv , nm = r.TrackFX_GetFXName(LT_Track, FX_Idx_Before_Add)

                                    Put_FXs_Into_New_Container( FX_Idx_Before_Add , cont, i , V.scale)
                                    r.Undo_EndBlock('Put FX into new container', 0)

                                end
                                im.PopStyleColor(ctx, 2)
                                im.SetCursorPos(ctx, x - pad*2, y  )
                            end
                            
                            local function Input_Text_label()
                                local x , y = im.GetCursorPos(ctx)

                                local rv,  buf = im.InputText( ctx, '##Custom Title'..FX_Idx,  buf or FX_Name , im.InputTextFlags_EnterReturnsTrue)
                                
                                if rv then 
                                    --FX[FxGUID].CustomTitle = buf

                                    local fx_id = Find_FxID_By_GUID(FxGUID)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, fx_id, 'renamed_name', buf)
                                    FX[FxGUID].RenamingContainer = nil
                                end
                                if im.IsKeyPressed(ctx, im.Key_Escape) then 
                                    FX[FxGUID].RenamingContainer = nil
                                end

                                im.SetCursorPos(ctx, x - pad*2, y + height )

                            end
                            local function Label()
                                if not FX[FxGUID].RenamingContainer then 
                                    local L, T = im.GetCursorScreenPos(ctx)
                                    --local Width = FX[V.guid].Lbl_Height and Width - FX[V.guid].Lbl_Height  or Width
                                    --[[ if FX[V.guid].Lbl_Height then 
                                    end ]]  

                                    Width = Width - height / 2 - pad * 2

                                    im.PushClipRect(ctx, L, T, L+Width, T+height, true)
                                    im.DrawList_AddText(WDL, L,T, 0xffffffff, FX_Name)
                                    im.PopClipRect(ctx)
                                    local rv = im.InvisibleButton(ctx, 'InivisiBtn for Dry wet Drag'..FxGUID, Width, height)
                                    local x, y = im.GetCursorPos(ctx)
                                    im.SetCursorPos(ctx, x +10, y - height + pad )
                                    if im.IsItemHovered(ctx) then 
                                        FX[V.guid].Lbl_Height = im.GetTextLineHeight(ctx) - 8
                                    else 
                                        FX[V.guid].Lbl_Height = nil
                                    end
                                    if  HighlightHvredItem(0x00000000) and Mods == 0 then -- if click
                                        DETERMINE_IF_DRAG= FxGUID 
                                    end

                                    if rv and Mods == Ctrl then 
                                        local _, ident = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'fx_ident')
                                        if ident == '__builtin_container' then
                                            FX[FxGUID].RenamingContainer = true 
                                        end
                                    end

                                    if DETERMINE_IF_DRAG==FxGUID then
                                        local x, y = im.GetMouseDragDelta(ctx)
                                        if im.IsMouseReleased(ctx,0) then 
                                            if x < 8 and y < 8 then 
                                                if FX[ROOT_FXGUID].ChosenFX == FxGUID then FX[ROOT_FXGUID].ChosenFX = nil 
                                                else 
                                                    FX[ROOT_FXGUID].ChosenFX = FxGUID 
                                                end

                                            end
                                            DETERMINE_IF_DRAG = nil
                                        end
                                    end
                                else 
                                    Input_Text_label()


                                end
                            end
                            
                            local function Allow_FX_Drag_On_Item()
                                if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect| im.DragDropFlags_AcceptNoPreviewTooltip| im.DragDropFlags_SourceNoPreviewTooltip) then
                                    DragFX_Arrow_StartX , DragFX_Arrow_StartY = im.GetItemRectMin(ctx)
                                    DragDroppingFX = true

                                    im.SetDragDropPayload(ctx, 'FX_Drag', V.addr_fxid)
                                    DragFX_ID = V.addr_fxid
                                    DragFxGuid = FxGUID
                                  --[[   Show_Drag_FX_Preview_Tooltip(FxGUID, V.addr_fxid) ]]
                                    im.EndDragDropSource(ctx)
                                    return true 
                                end
                            end

                            local function ColorBox()
                                if im.InvisibleButton(ctx, '##color Rect'..FX_Idx, 5, height * 2) then 
                                end
                                local l,t,R,b, w,h = HighlightSelectedItem(Clr.PAR_FX[I]) 
                            end
                            
                            local function LOCAL_MoveFX(Dest ,Src, ofs, Dont_Change_Parallel)
                                table.insert(MovFX.FromPos, tonumber(Src))
                                table.insert(MovFX.ToPos, tonumber(Dest) + (ofs or 0))

                                -- if Moving to the first fx (root) of parallel fx
                                if v[1].addr_fxid ==tonumber(Dest) + (ofs or 0)  and not Dont_Change_Parallel then 
                                    MovFX.Parallel =v[1].addr_fxid
                                else
                                    MovFX.scale = V.scale
                                    MovFX.Parallel = true 
                                end
                            end

                            local function Allow_FX_Drop_On_Item(ofs)

                                if im.BeginDragDropTarget(ctx) then 
                                    local Create_Insert_FX_Preview
                                    if Payload_Type == 'FX_Drag' then
                                        local dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                                         -- move FX if it's fx,  move into container if it's container 
                                        --[[ local l, t = im.GetItemRectMin(ctx)
                                        local w, h = im.GetItemRectSize(ctx)
                                        im.DrawList_AddRectFilled(WDL, l, t, l+w, t + 5, 0xffff44ff) ]]

                                        if DragFX_ID < tonumber(V.addr_fxid) then 
                                            Create_Insert_FX_Preview =  V.addr_fxid+(V.scale or 1)
                                        else
                                            Create_Insert_FX_Preview =  V.addr_fxid
                                        end 
                                        if dropped then 

                                            local local_ofs = 0 
                                            local Dont_Change_Parallel
                                            if FX_Is_Root_Of_Parallel_Chain(V.addr_fxid) then  -- If we're moving TO the Root FX of the parallel Chain
                                                if V.addr_fxid < DragFX_ID then 
                                                    r.TrackFX_SetNamedConfigParm( LT_Track, V.addr_fxid --[[ + (V.scale or 1) ]], 'parallel', '1' )
                                                elseif V.addr_fxid == DragFX_ID + (V.scale or 1 ) then 
                                                    r.TrackFX_SetNamedConfigParm( LT_Track, V.addr_fxid  + (V.scale or 1) , 'parallel', '1' )
                                                    r.TrackFX_SetNamedConfigParm( LT_Track, DragFX_ID , 'parallel', '1' )
                                                    Dont_Change_Parallel = true 
                                                    --goto END_OF_MOVING_FX  -- skip the reordering part because FXS are already in the right place
                                                else 
                                                    r.TrackFX_SetNamedConfigParm( LT_Track, v[1].addr_fxid , 'parallel', '1' )
                                                    local_ofs =  - (V.scale or 1)
                                                end
                                            elseif FX_Is_Root_Of_Parallel_Chain(DragFX_ID) then  -- If we're moving the root FX of the parallel Chain
                                                local _, Name = r.TrackFX_GetFXName(LT_Track, DragFX_ID)
                                                r.TrackFX_SetNamedConfigParm( LT_Track, DragFX_ID , 'parallel', '1' )
                                                if DragFX_ID == v[1].addr_fxid then -- if we're moving the root into it's own Parallel Chain
                                                    r.TrackFX_SetNamedConfigParm( LT_Track, v[2].addr_fxid , 'parallel', '0' )
                                                else  -- if we're moving it into another Parallel Chain 
                                                end
                                            else 
                                               local rv =  r.TrackFX_SetNamedConfigParm( LT_Track, DragFX_ID, 'parallel', '1' )
                                               local rv, name = r.TrackFX_GetFXName(LT_Track, DragFX_ID)
                                               local rv = r.TrackFX_GetNamedConfigParm( LT_Track, DragFX_ID, 'parallel')
                                            end

                                           
                                            LOCAL_MoveFX(V.addr_fxid + local_ofs, tonumber(payload), ofs or 0, Dont_Change_Parallel)

                                            if Mods == Alt then 
                                            elseif Mods == Alt + Shift then 
                                            end
                                            ::END_OF_MOVING_FX::
                                        end
                                    end
                                    im.EndDragDropTarget(ctx)
                                end
                                return Create_Insert_FX_Preview
                            end

                            local function Add_FX_Btn ()

                                if I == #v then 
                                    local function Draw_Line_To_Menu(IsPopupOpenNow, BtnL, BtnT, BtnR, BtnB)
                                        if IsPopupOpenNow then 
                                            local X = BtnR
                                            local Y = BtnT + (BtnB - BtnT) / 2

                                            local Vert_Line_Leng = Y -  (VP.Y - 300 )

                                            im.DrawList_AddLine(Glob.FDL , X , Y, X + 16 , Y , 0xffffffff, 3 )
                                            im.DrawList_AddLine(Glob.FDL , X+15 , Y , X + 15 , Y - Vert_Line_Leng  , 0xffffffff, 3 )
                                            im.DrawList_AddRect(Glob.FDL, BtnL, BtnT, BtnR, BtnB, 0xffffffaa, 3, nil, 2)
                                            im.DrawList_AddRectFilled(Glob.FDL, BtnL, BtnT, BtnR, BtnB, 0xffffff2a, 3)

                                        end
                                    end
                                    AddSpacing(1)
                                    im.PushStyleColor(ctx, im.Col_Button, 0x00000000)
                                    im.PushFont(ctx, Arial_14)

                                    local clickBtn = im.Button(ctx, '+'..'##Add FX Button'..V.addr_fxid.. V.guid, 120 + height*2, height)
                                    local BtnL, BtnT = im.GetItemRectMin(ctx)
                                    local BtnR, BtnB = im.GetItemRectMax(ctx)

                                    im.PopFont(ctx)
                                    im.PopStyleColor(ctx)
                                    local rv = Allow_FX_Drop_On_Item(V.scale or 0)
                                    local FillClr= rv and 0xffffff33
                                    local L, T, R, B, w, h = HighlightSelectedItem(FillClr, 0xffffff77, 0, nil,nil,nil,nil, nil, nil , 1,1, 'GetItemRect', nil, nil, 2) 
                                    local scale = v[1].addr_fxid> 0x2000000 and V.scale or 1 
                                    local Popup_FX_Idx = V.addr_fxid + scale
                                    if rv then
                                        local DL = WDL or Glob.FDL or im.GetWindowDrawList(ctx)
                                        if rv == V.addr_fxid then
                                            im.DrawList_AddLine(DL, L, T, R, T, 0xffffffaa, 3)
                                        else
                                            im.DrawList_AddLine(DL, L, B, R, B, 0xffffffaa, 3)
                                        end
                                    end
                                    if clickBtn and Mods == 0 then 

                                        im.SetNextWindowPos(ctx, BtnR , VP.Y- 300)
                                        im.OpenPopup(ctx, 'Btwn FX Windows' .. Popup_FX_Idx)


                                    elseif clickBtn and Mods == Alt then 
                                        local idx = AddFX_HideWindow(LT_Track, 'Container', -1000 - FX_Idx -1)
                                        r.TrackFX_SetNamedConfigParm(LT_Track, idx, 'parallel', '1')
                                    end

                                    if im.IsItemHovered(ctx) then 
                                        HelperMsg.L = 'Add new FX'
                                        HelperMsg.Alt_L = 'Add a new Container'
                                    end
                                    local PopupOpenNow = im.IsPopupOpen(ctx, 'Btwn FX Windows' .. Popup_FX_Idx)
                                    if PopupOpenNow then
                                        im.SetNextWindowPos(ctx, BtnR , VP.Y- 300)
                                    end
                                    AddFX_Menu(Popup_FX_Idx, nil,nil, true)
                                    PopupOpenNow = PopupOpenNow or (clickBtn and Mods == 0)
                                    if (PopupOpenNow or clickBtn) and (DebugMode or true) then
                                        r.ShowConsoleMsg(string.format('[AddFX Btn] PopupID=%s PopupOpen=%s clickBtn=%s Mods=%s Draw=%s Btn=%.0f,%.0f,%.0f,%.0f Glob.FDL=%s\n',
                                            'Btwn FX Windows'..Popup_FX_Idx, tostring(PopupOpenNow), tostring(clickBtn), tostring(Mods), tostring(PopupOpenNow), BtnL or 0, BtnT or 0, BtnR or 0, BtnB or 0, tostring(Glob.FDL)))
                                    end
                                    Draw_Line_To_Menu(PopupOpenNow, BtnL, BtnT, BtnR, BtnB)

                                end

                            end

                            local function Delete_If_Alt_Click()
                                if im.IsItemClicked(ctx, 0) and Mods == Alt then 
                                    table.insert(DelFX.GUID , FxGUID)
                                    table.insert(DelFX.Pos , V.addr_fxid)

                                end
                            end

                            
                            if FX[ROOT_FXGUID].ChosenFX == FxGUID then 
                                local L, T = im.GetCursorScreenPos(ctx )
                                im.DrawList_AddRectFilled(WDL, L, T , L + Win_W , T + height*2, 0xffffff22)
                                --HighlightSelectedItem(0xffffff22, OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect )
                            end

                            local function Show_Preview_FXBtn_For_DragDrop(trigger)

                                local Hover_Insert_FX_Preview

                                if   trigger then 

                                    local rv, type, payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)
                                    
                                    if  payload~='' and type == 'FX_Drag' then 
                                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track,   tonumber(payload) )
                                        AddWindowBtn(FxGUID, tonumber(payload) , Win_W,nil,nil,nil,true)
                                        local rv =   Allow_FX_Drop_On_Item() 
                                        if rv then v[1].Create_Insert_FX_Preview = rv end 
                                        local L, T = im.GetItemRectMin(ctx)
                                        local R, B =  im.GetItemRectMax(ctx)
                                        if im.IsMouseHoveringRect(ctx, L ,T - 3, R + 10,B + 5)then 
                                            Hover_Insert_FX_Preview = true 
                                            if im.IsMouseReleased(ctx, 0) then 
                                                if not MovFX.ToPos[1] then 
                                                    table.insert(MovFX.FromPos, DragFX_ID)
                                                    table.insert(MovFX.ToPos, tonumber(FX_Idx))
                                                    LOCAL_MoveFX(V.addr_fxid, tonumber(payload), ofs or 0)
                                                end
                                            end
                                        end
                                    end
                                end
                                return Hover_Insert_FX_Preview
                            end


                            local Hover_Insert_FX_Preview = Show_Preview_FXBtn_For_DragDrop(v[1].Create_Insert_FX_Preview==V.addr_fxid)

                            im.BeginGroup(ctx)

                            im.BeginGroup(ctx)
                            --im.Text(ctx, FX_Name)
                            local Spacing = (#v < 4 and 1) or ((#v >= 4 and #v <= 5) and 0) or -1

                            im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 0, Spacing)
                            ColorBox()
                            local drag = Allow_FX_Drag_On_Item()
                            
                            SL(nil, pad * 2 )
                            im.SetNextItemWidth(ctx,Width)

                            Label()
                            local drag = Allow_FX_Drag_On_Item()

                            Add_Container_Btn()
                            
                            --local  y= im.GetCursorPosY(ctx)
                            --im.SetCursorPosY(ctx,  y + 15)
                            --im.SetCursorPos(ctx,x + 5 + pad * 2  , y - h + height )
                            FX[FxGUID][0].Num = wet_p_num

                            local fp = FX[FxGUID][0]


                            fp.V = fp.V or  r.TrackFX_GetParamNormalized( LT_Track, V.addr_fxid, FX[FxGUID][0].Num)
                            fp.Sldr_W = 120
                            fp.CustomLbl = ''
                            FX[FxGUID][0].Num = wet_p_num
                            FX[FxGUID][0].Height = 1
                            AddDrag(ctx, FxGUID, 0, V.addr_fxid)


                            im.EndGroup(ctx)
                            -- While hovering the FX item area, hint Alt+Left Click to delete this FX
                            if im.IsItemHovered(ctx) then 
                                HelperMsg.Alt_L = 'Delete FX'
                            end
                            if im.IsItemHovered(ctx) and Mods == Alt then
                                -- Visual caution outline when holding Alt to indicate deletion shortcut
                                local l, t = im.GetItemRectMin(ctx)
                                local r, b = im.GetItemRectMax(ctx)
                                local DL = WDL or Glob.FDL or im.GetWindowDrawList(ctx)
                                im.DrawList_AddRect(DL, l, t, r, b, 0xff6666aa, 2)
                            end
                            Delete_If_Alt_Click()
                            


                            local rv =   Allow_FX_Drop_On_Item() 
                            if rv then 
                                -- Draw insertion preview on this FX item while dragging
                                local l, t = im.GetItemRectMin(ctx)
                                local r, b = im.GetItemRectMax(ctx)
                                local DL = WDL or Glob.FDL or im.GetWindowDrawList(ctx)
                                -- subtle hover fill to indicate drop target
                                im.DrawList_AddRectFilled(DL, l, t, r, b, 0xffffff22)
                                local scale = V.scale or 1
                                if rv == V.addr_fxid then
                                    -- insert before: draw a line at the top edge
                                    im.DrawList_AddLine(DL, l, t, r, t, 0xffffff77, 2)
                                elseif rv == V.addr_fxid + scale then
                                    -- insert after: draw a line at the bottom edge
                                    im.DrawList_AddLine(DL, l, b, r, b, 0xffffff77, 2)
                                end
                                v[1].Create_Insert_FX_Preview = rv 
                            elseif v[1].Create_Insert_FX_Preview==V.addr_fxid and not Hover_Insert_FX_Preview then 
                                v[1].Create_Insert_FX_Preview = nil 
                            elseif i == #v and v[1].Create_Insert_FX_Preview==V.addr_fxid  + V.scale and not Hover_Insert_FX_Preview then 
                                v[1].Create_Insert_FX_Preview = nil 
                            end


                            SL(nil,1)


                            Solo()
                            SL(nil,1)
                            Mute()

                            im.EndGroup(ctx)    


                            Show_Preview_FXBtn_For_DragDrop(I == #v and  (v[1].Create_Insert_FX_Preview==  V.addr_fxid + (V.scale or 1)))

                            if drag then 
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect', WDL --[[rounding]])
                            end

                            im.PopStyleVar(ctx)
                            

                            Add_FX_Btn ()
                                
                            ::endOfLoop::

                        end

                    im.EndChild(ctx)

                    end
                    im.PopStyleVar(ctx)
                    im.EndChild(ctx)


                    SL(nil,0)
                    START_OF_PARALLEL_FX_MIXER = id


                end

                im.PopStyleVar(ctx) --- for scrollbarsize
                im.PopStyleColor(ctx)
                Add_Space_If_No_Chosen_FX()

            end
            if v[1] and v[2]and FX_Idx  then 
                if FX_Idx >= v[1].addr_fxid and FX_Idx <= v[#v].addr_fxid  then --if FX is within the Mixer 
                    if not FX[ROOT_FXGUID] then return 'Mixer Layout - Hide' end 
                    if FX[ROOT_FXGUID].ChosenFX == FxGUID then 

                        return 'Mixer Layout - Show'
                    else 

                        return 'Mixer Layout - Hide'
                    end
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
    local function If_Need_To_Hide()
        local Hide
        if FX_is_in_blacklist (FX_Name) then
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

            return    true    --im.EndGroup(ctx)
        end
    end


    local Parallel = If_Parallel_FX(FX_Idx)

    if Parallel and  Parallel == 'Mixer Layout - Hide' then return Parallel  end --- THINGS BELOW IS NOT EXECUTED IF THERES PARALLEL FX


    PresetMorph()
    

    -- FX window color

    im.PushStyleColor(ctx, im.Col_ChildBg, FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff); local poptimes = 1



    local PrmCount = Load_from_Trk('Prm Count' ,  LT_Track, 'num') or 0
    local ActualPrmCount = 0
    for _, prm in ipairs(FX[FxGUID] or {}) do
        if prm and prm.Num ~= nil then
            ActualPrmCount = ActualPrmCount + 1
        end
    end
    PrmCount = math.max(PrmCount, ActualPrmCount)

    local Def_Sldr_W = Global_Default_Sldr_W or 160
    FX.Def_Sldr_W[FxGUID] = Def_Sldr_W
    FX[FxGUID].DefType = Global_Default_Param_Type or 'Drag'

    if FX[FxGUID].DefType == 'Slider' or FX[FxGUID].DefType == 'Drag' or not FX[FxGUID].DefType then
        local DF = (FX.Def_Sldr_W[FxGUID] or Df.Sldr_W)
        local itemsPerColumn = 7
        local Ct = math.max(math.floor((PrmCount / itemsPerColumn - 0.01)) + 1, 1)

        DefaultWidth = (DF + GapBtwnPrmColumns) * Ct

    elseif FX[FxGUID].DefType == 'Knob' then
        local Ct = math.max(math.floor((PrmCount / 3) - 0.1) + 1, 1) -- need to -0.1 so flooring 3/3 -0.1 will return 0 and 3/4 -0.1 will be 1
        DefaultWidth = Df.KnobSize * Ct + GapBtwnPrmColumns
    elseif FX[FxGUID].DefType == 'V-Slider' then
        DefaultWidth = math.max(220, (17 * math.max(PrmCount - 1, 0)) + 30)
    end

    if If_Need_To_Hide() then return end
    im.BeginGroup(ctx)


    if not fx.Width_Collapse and DefaultWidth then
        fx.Width = math.max(fx.Width or 0, DefaultWidth)
    end
    local Width = fx.Width_Collapse or fx.Width or DefaultWidth or 220
    local dummyH = 220
    local  _, name=  r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'original_name')
    local isContainer = name == 'Container' and true 


    im.PushStyleVar(ctx, im.StyleVar_ScrollbarSize, 8) -- styleVar ScrollBar

    local function Make_Window()
        local WindowSize
        local Title_Btn_Column_W = 30
        local Main_Content_H = 225
        local Wet_Knob_Gap = 2
        local Mod_Icon_Sz = 20
        local Mod_Icon_Gap = 0
        local _, ItemSpacingY = im.GetStyleVar(ctx, im.StyleVar_ItemSpacing)
        local _, ItemInnerSpacingY = im.GetStyleVar(ctx, im.StyleVar_ItemInnerSpacing)
        local Wet_Knob_H = (WET_DRY_KNOB_SZ or 20) + im.GetTextLineHeight(ctx) - 10 + (ItemInnerSpacingY or 0)
        local Reserve_Below_Title = Wet_Knob_Gap + Wet_Knob_H
        if isContainer then
            local Folder_Icon_Footprint = (WET_DRY_KNOB_SZ or 20) + (ItemSpacingY or 0)
            Reserve_Below_Title = Reserve_Below_Title + Folder_Icon_Footprint
        end
        if isContainer then
            Reserve_Below_Title = Reserve_Below_Title + Mod_Icon_Sz + Mod_Icon_Gap
        end
        if isContainer then
            Reserve_Below_Title = Reserve_Below_Title + 30
        end
        local Title_Btn_H = math.max(Main_Content_H - Reserve_Below_Title, 20)
        local Main_Content_W = math.max((Width or 220), 40)
            


        PosX_before_FX_Win =  im.GetCursorScreenPos(ctx)
        WDL = im.GetWindowDrawList(ctx)
        local LeftColX, LeftColY = im.GetCursorPos(ctx)
        local LeftColScreenX, LeftColScreenY = im.GetCursorScreenPos(ctx)
        local LeftPanelClr = FX[FxGUID].TitleClr or ThemeClr('FX_Btn_BG_Clr')
        im.DrawList_AddRectFilled(WDL, LeftColScreenX, LeftColScreenY, LeftColScreenX + Title_Btn_Column_W, LeftColScreenY + Main_Content_H, LeftPanelClr, FX_Title_Round)
        AddWindowBtn(FxGUID, FX_Idx,nil,nil,nil,nil,nil,Title_Btn_H)
        im.SetCursorPos(ctx, LeftColX + Title_Btn_Column_W - 4, LeftColY)

        im.PushStyleVar(ctx, im.StyleVar_ChildRounding, FX_Title_Round or 0)
        if im.BeginChild(ctx, FX_Name .. FX_Idx, Main_Content_W, Main_Content_H, nil, im.WindowFlags_NoScrollbar | im.WindowFlags_NoScrollWithMouse) and not Hide then   ----START CHILD WINDOW------
            local fx = FX[FxGUID]

            -- Track whether this is a container
            -- Always process containers fully, or process windows that are in view
            --local shouldProcessFully = isContainer or isInView or FX_Idx == 0 or FX_Idx == Sel_Track_FX_Count - 1

            Glob.FDL = im.GetForegroundDrawList(ctx)
            WDL = im.GetWindowDrawList(ctx)

            Win_L, Win_T = im.GetItemRectMin(ctx); Win_W, Win_H = im.GetItemRectSize(ctx)
            Win_R, _ = im.GetItemRectMax(ctx); Win_B = Win_T + Main_Content_H
            local function Disable_If_LayEdit(Begin_or_End)
                if (FX.LayEdit == FxGUID or Draw.DrawMode == FxGUID) and Mods ~= Cmd then
                    if Begin_or_End =='Begin' then 
                        im.BeginDisabled(ctx)
                    elseif Begin_or_End =='End' then 
                        im.EndDisabled(ctx)

                    end
                end
            end

            local function If_LayEdit_Activated()
                    
                if FX.LayEdit == FxGUID and Draw.DrawMode ~= FxGUID and Mods ~= Cmd then -- Resize FX or title btn
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
                if FX.LayEdit == FxGUID and Draw.DrawMode ~= FxGUID then
                    im.BeginDisabled(ctx); R, T = im.GetItemRectMax(ctx)
                    local L, T = im.GetItemRectMin(ctx); local R, _ = im.GetItemRectMax( ctx); B = T + 20
                    local WinDrawList = WinDrawList or im.GetWindowDrawList(ctx)
                    im.DrawList_AddCircleFilled(WinDrawList, R, T + 10, 3, 0x999999ff)
                    im.DrawList_AddRect(WinDrawList, L, T, R, T + 20, 0x999999ff)

                    if MouseX > L and MouseX < R and MouseY > T and MouseY < B then
                        im.DrawList_AddRectFilled(WinDrawList, L, T, R, T + 20, 0x99999955)
                        if IsLBtnClicked then
                            LE.SelectedItem = 'Title'
                            LE.ChangingTitleSize = true
                            LE.MouseX_before, _ = im.GetMousePos(ctx)
                        elseif IsRBtnClicked and Mods == 0 then
                            im.OpenPopup(ctx, 'Fx Module Menu##' .. FxGUID)
                        end
                    end

                    if LE.SelectedItem == 'Title' then
                        im.DrawList_AddRect(WinDrawList, L, T, R, T + 20, 0x999999ff)
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
                                FX[FxGUID].TitleWidth = FX[FxGUID].TitleWidth + LE.GridSize; LE.MouseX_before = im.GetMousePos(ctx); LE.BeenEdited = true
                            elseif MouseDiff < -LE.GridSize then
                                FX[FxGUID].TitleWidth = FX[FxGUID].TitleWidth - LE.GridSize; LE.MouseX_before = im.GetMousePos(ctx); LE.BeenEdited = true
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
                if not OpenMorphSettings then return end 
                im.SetNextWindowSizeConstraints(ctx, 500, 500, FLT_MAX, FLT_MAX)
                Open, Oms = im.Begin(ctx, 'Preset Morph Settings ', Oms, im.WindowFlags_NoCollapse | im.WindowFlags_NoDocking)
                if not Oms then 
                    im.End(ctx)
                    OpenMorphSettings = false
                    return 
                end 
                if FxGUID ~= OpenMorphSettings then  im.End(ctx) return end 
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
                local FxNam = fx.ShortName:gsub("%b()", "")
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

                    RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track, r.TrackFX_GetNumParams(LT_Track, FX_Idx), FX_Name)
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
                        im.TableSetBgColor(ctx, 1, 0xffffff11)
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
                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                        if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                            P.FormatV_A = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphA[i], OrigV, i)
                        end


                        P.Drag_A, FX[FxGUID].MorphA[i] = im.DragDouble(ctx, '## MorphVal_A LT' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1, P.FormatV_A or '')
                        if P.Drag_A then
                            P.FormatV_A = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphA[i], OrigV, i)
                        end

                        SL()
                        --------- B --------------------
                        im.TableSetColumnIndex(ctx, 3)
                        im.Text(ctx, 'B:')
                        SL()

                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                        im.SetNextItemWidth(ctx, -FLT_MIN)
                        if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                            P.FormatV_B = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphB[i], OrigV, i)
                        end


                        P.Drag_B, FX[FxGUID].MorphB[i] = im.DragDouble(ctx, '## MorphVal_B LT' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1, P.FormatV_B)
                        if P.Drag_B then
                            P.FormatV_B = GetFormatPrmV(FX_Idx,FX[FxGUID].MorphB[i], OrigV, i)
                        end


                        if P[N].BL then im.EndDisabled(ctx) end
                        --HighlightSelectedItem( 0xffffff33 , OutlineClr, 1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect', Foreground)

                        im.PopStyleVar(ctx)
                        im.TableNextRow(ctx)
                        im.TableSetColumnIndex(ctx, 0)
                    end
                    local Load_FX_Proj_Glob
                    local _, FXsBL = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID, '', false)
                    if FXsBL == 'Has Blacklist saved to FX' then -- if there's FX-specific BL settings
                        Load_FX_Proj_Glob = 'FX'
                    else
                        local _, whether = r.GetProjExtState(0, 'FX Devices - Preset Morph', 'Whether FX has Blacklist' .. (fx.ShortName or ''))
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
                                    local _, V = r.GetSetMediaTrackInfo_String( LT_Track, 'P_EXT: Morph_BL' .. FxGUID .. i, '', false)
                                    if V == 'Blacklisted' then prm[i].BL = true end
                                end
                                --[[  elseif Load_FX_Proj_Glob== 'Proj' then
                                    local rv, BLprm  = r.GetProjExtState(0,'FX Devices - Preset Morph', fx.ShortName..' Blacklist '..i)
                                    if BLprm~='' and BLprm then  BLpm = tonumber(BLprm)
                                        if BLprm then prm[1].BL = true  end
                                    end
                                end ]]
                            end
                            if BL_All --[[BL all filtered params ]] then if P.BL then P.BL = false else P.BL = true end end
                            rv, prm[i].BL = im.Checkbox(ctx, '## BlackList' .. i, prm[i].BL)

                            im.TableSetColumnIndex(ctx, 1)
                            if P.BL then
                                im.PushStyleColor(ctx, im.Col_Text, getClr(im.Col_TextDisabled))
                            end


                            im.Text(ctx, i .. '. ' .. (P.Name or ''))



                            ------- A --------------------
                            im.TableSetColumnIndex(ctx, 2)
                            im.Text(ctx, 'A:')
                            SL()

                            local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                            im.SetNextItemWidth(ctx, -FLT_MIN)
                            if not P.FormatV_A and FX[FxGUID].MorphA[1] or MORPH__NEED_TO_REFRESH ==1 then
                                P.FormatV_A = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphA[i ], OrigV, i)
                            end


                            P.Drag_A, FX[FxGUID].MorphA[i] = im.DragDouble(ctx, '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1, P.FormatV_A or '')
                            if P.Drag_A then
                                P.FormatV_A = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphA[i], OrigV, i)
                                --[[ r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, FX[FxGUID].MorphA[i])
                                _,P.FormatV_A = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,i)
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, OrigV)  ]]
                            end

                            SL()

                            --------- B --------------------
                            im.TableSetColumnIndex(ctx, 3)
                            im.Text(ctx, 'B:')
                            SL()

                            local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                            im.SetNextItemWidth(ctx, -FLT_MIN)
                            if not P.FormatV_B and FX[FxGUID].MorphB[1] or MORPH__NEED_TO_REFRESH == 2  then
                                P.FormatV_B = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphB[i] or 0, OrigV, i)
                            end

                            P.Drag_B, FX[FxGUID].MorphB[i] = im.DragDouble(ctx, '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1, P.FormatV_B)
                            if P.Drag_B then
                                P.FormatV_B = GetFormatPrmV(FX_Idx, FX[FxGUID].MorphB[i], OrigV, i)
                            end


                            if Save_FX then
                                if P.BL then
                                    hasBL = true
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID .. i, 'Blacklisted', true)
                                else
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID .. i, '', true)
                                end
                                if hasBL then
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID, 'Has Blacklist saved to FX', true)
                                else
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Morph_BL' .. FxGUID, '', true)
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
                    MORPH__NEED_TO_REFRESH = nil

                    if Save_Proj then
                        if TheresBL[1] then
                            r.SetProjExtState(0, 'FX Devices - Preset Morph', 'Whether FX has Blacklist' .. fx.ShortName, 'Yes')
                        else
                            r.SetProjExtState(0, 'FX Devices - Preset Morph', 'Whether FX has Blacklist' .. fx.ShortName, 'No')
                        end
                        for i, V in ipairs(FX[FxGUID].MorphA) do
                            local PrmBLed
                            for I, v in ipairs(TheresBL) do
                                if i == v then PrmBLed = v end
                            end
                            if PrmBLed then
                                r.SetProjExtState(0, 'FX Devices - Preset Morph', fx.ShortName .. ' Blacklist ' .. i, PrmBLed)
                            else
                                r.SetProjExtState(0, 'FX Devices - Preset Morph', fx.ShortName .. ' Blacklist ' .. i, '')
                            end
                        end
                        --else r.SetProjExtState(0,'FX Devices - Preset Morph','Whether FX has Blacklist'..fx.ShortName, '')
                    elseif TheresBL[1] and Save_Glob then
                        file, file_path = CallFile('w', fx.ShortName .. '.ini', 'Preset Morphing')
                        if file then
                            for i, V in ipairs(TheresBL) do
                                file:write(i, ' = ', V, '\n')
                            end
                            file:close()
                        end
                    end

                    im.EndTable(ctx)
                end

                im.End(ctx)

                
            end
            
            --------------------------------
            ----Area right of window title
            --------------------------------
            function SyncWetValues(id,FxGUID )

                local id = FX_Idx or id
                local FxGUID = FxGUID or r.TrackFX_GetFXGUID(LT_Track, id)
                if not FxGUID then return end
                FX[FxGUID][0] = FX[FxGUID][0] or {}
                local FP = FX[FxGUID][0]
                if FP.WhichCC then return end -- Never sync FP.V if there's modulation on it
                --when track change
                if FP.V == nil or TrkID ~= TrkID_End or FXCountEndLoop ~= Sel_Track_FX_Count then -- if it's nil
                    Glob.SyncWetValues = true
                end

                if Glob.SyncWetValues == true then
                    FP.Num = r.TrackFX_GetParamFromIdent(LT_Track, id, ':wet')
                    FP.V = r.TrackFX_GetParamNormalized(LT_Track, id, FP.Num)
                end
                if Glob.SyncWetValues == true and id == Sel_Track_FX_Count - 1 then
                    Glob.SyncWetValues = false
                end
                if LT_ParamNum == FP.Num and FOCUSED_LT_FX_Number == id then

                    FP.V = r.TrackFX_GetParamNormalized(LT_Track, id, FP.Num)

                elseif LT_ParamNum == FP.DeltaP   then
                    FP.DeltaP_V = r.TrackFX_GetParamNormalized(LT_Track, id, FP.DeltaP)
                end
            end

            local function AddWetDryKnob_If_not_SpecialLayoutFX()
                if FX[FxGUID].NoWetKnob then return end
                local orig_name = orig_name
                if orig_name:find('JS: ') then orig_name = string.sub(orig_name, 5) end 
                if FindStringInTable(SpecialLayoutFXs, FX_Name) == false and not FindStringInTable(PluginScripts, orig_name) then -- orig_name used to be fx.ShortName , changed to orig_name to work with containers in case if user changes name
                    SyncWetValues()


                        FX[FxGUID] = FX[FxGUID] or {}
                        FX[FxGUID][0]= FX[FxGUID][0] or {}
                        FX[FxGUID][0].V  = FX[FxGUID][0].V  or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet') )
                        Wet.ActiveAny, Wet.Active, FX[FxGUID][0].V = Add_WetDryKnob(ctx, 'a', '', FX[FxGUID][0].V, 0, 1, FX_Idx,nil,FxGUID)



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
                if not FX[FxGUID].Collapse and FX_is_in_blacklist (FX_Name)~=true and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
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
                        
                    end
                end
                if FX[FxGUID].Compatible_W_regular then return true end
            end
            local function Do_PluginScripts(orig_Name)

                for i, v in pairs(PluginScripts) do
                    --local FX_Name = FX_Name

                    local function Do_Plugin_Script(name)
                        PluginScript.FX_Idx = FX_Idx
                        PluginScript.Guid = FxGUID
                        dofile(pluginScriptPath .. '/' ..  (name  or v) .. '.lua')
                    end

                    if FX_Name:find('ReaDrum Machine') then 
                        Do_Plugin_Script('ReaDrum Machine')
                    elseif FX_Name:find(v) or (orig_Name == 'Container' and v == 'Container') then

                        Do_Plugin_Script()
                        
                    end
                end
            end
            local function Wet_Dry_Knob_And_WindowBtn_Decoration_NOT_COLLAPSED(sz, gap,St)
                if FX[FxGUID].Collapse then return end
                if FX[FxGUID].NoWetKnob then return end
                if IsContainer then return end
                local clr = FX[FxGUID].TitleClr or ThemeClr('FX_Btn_BG_Clr')
                local clr_outline = FX[FxGUID].TitleClr_Outline or ThemeClr('FX_Title_Clr_Outline')
                SL( nil, gap)
                local pos ={ im.GetCursorScreenPos(ctx)}
                im.DrawList_AddRectFilled(WDL, pos[1], pos[2], pos[1] + gap, pos[2] + sz, clr, 0)
                SL( nil, 0)
                local pos ={ im.GetCursorScreenPos(ctx)}
                local ENDpos = {im.GetCursorScreenPos(ctx)}

                im.DrawList_AddRectFilled(WDL, pos[1]- gap, pos[2], ENDpos[1] + sz, ENDpos[2] + sz, clr, FX_Title_Round)
                AddWetDryKnob_If_not_SpecialLayoutFX()
                im.DrawList_AddRect(WDL, St[1]-gap/2, St[2], ENDpos[1] + sz, ENDpos[2] + sz, clr_outline, FX_Title_Round, nil,1)
            end
            local function Wet_Dry_Knob_COLLAPSED(sz, gap,pos)
                if not FX[FxGUID].Collapse then return end
                local pos = im.GetCursorPosX(ctx)
                im.SetCursorPosX(ctx, pos + 2)
                AddWetDryKnob_If_not_SpecialLayoutFX()


            end

            local function Draw_Container_Title_Panel()
                if not IsContainer then return end
                if fx.Collapse then return end
                local Title_Strip_W = 33
                local pad = 1
                local clr = FX[FxGUID].TitleClr or ThemeClr('FX_Btn_BG_Clr')
                local clr = HSV_Change(clr, nil, nil, 0.06)
                local clr_outline = FX[FxGUID].TitleClr_Outline or ThemeClr('FX_Title_Clr_Outline')
                local x1, y1 = Win_L, Win_T
                local x2, y2 = Win_L + Title_Strip_W + pad, Win_B
                im.DrawList_AddRectFilled(WDL, x1, y1, x2, y2, clr, FX_Title_Round)
                im.DrawList_AddRect(WDL, x1, y1, x2, y2, clr_outline, FX_Title_Round, nil, 1)
                im.DrawList_AddLine(WDL, x2, y1, x2, y2, ThemeClr('Accent_Clr_Dark'), 1)
            end
            local function Window_Title_Area()
                local sz= WET_DRY_KNOB_SZ

                local gap = fx.Left_Padding or 0
                SL( nil, gap)
                local St = {im.GetCursorScreenPos(ctx)}

                Draw_Container_Title_Panel()
                AddWindowBtn(FxGUID, FX_Idx )
                If_LayEdit_Activated__WindowBtn()
                If_DebugMode_Active()
                If_Open_Morph_Settings()
                Wet_Dry_Knob_And_WindowBtn_Decoration_NOT_COLLAPSED(sz, gap,St)
                Wet_Dry_Knob_COLLAPSED(sz, gap,St)

            end

            


            local FX_Idx = FX_Idx or 1

            r.gmem_attach('ParamValues')
            fx.ShortName = fx.ShortName or  ChangeFX_Name( FX_Name)

            FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
            FX_Name = string.gsub(FX_Name, '%-', ' ')



            If_Draw_Mode_Is_Active(FxGUID, Win_L, Win_T, Win_R, Win_B, FxNameS)
            Draw_Background(FxGUID)
            If_LayEdit_Activated()

            Disable_If_LayEdit('Begin')

            if Need_Create_Regular_Layout() then
      
                local WinP_X; local WinP_Y;
                local fx = FX[FxGUID]
                --im.DrawList_AddText(WDL, 100,200, 0xffffffff, 'asd')
                local function Create_Virtual_Buttons()
                    if fx.VB then 
                        local DefaultPosX = 10

                        for i,v in ipairs(fx.VB) do 
                            --local Pos_BeforeX, Pos_BeforeY = im.GetCursorPos(ctx)
                            v.Choices = v.Choices or {}
                            v.Chosen = v.Chosen or (v.Choices[1] and v.Choices[1].ChoiceName)
                            if v.Btn_Clr then 
                                local Clr = v.Btn_Clr or 0xffffff44
                                im.PushStyleColor(ctx, im.Col_Button, Clr)
                                im.PushStyleColor(ctx, im.Col_FrameBg, Clr)
                                im.PushStyleColor(ctx, im.Col_FrameBgHovered, HSV_Change(Clr, nil,nil, 0.3, 0.2, 0.2))
                                im.PushStyleColor(ctx, im.Col_ButtonHovered, HSV_Change(Clr, nil,nil, 0.3, 0.2, 0.2))
                                im.PushStyleColor(ctx, im.Col_ButtonActive, HSV_Change(Clr, nil,nil, 0.5, 0.2, 0.4))
                                im.PushStyleColor(ctx, im.Col_FrameBgActive, HSV_Change(Clr, nil,nil, 0.5, 0.2, 0.4))
                            end
                            if v.PosX and v.PosY then 
                                im.SetCursorPos(ctx, v.PosX, v.PosY )
                            else 
                                v.PosX , v.PosY = DefaultPosX , 30
                                im.SetCursorPos(ctx, DefaultPosX , 30 )
                                DefaultPosX = DefaultPosX + 70
                            end
                            im.SetNextItemWidth(ctx, v.Sldr_W or 150) 
                            v.Name = v.Name or  'Virtual Button '.. i  


                            local lbl =  (v.CustomLbl or ( 'VIRT BT '.. i ) )..'##'..i
                            if not v.Type or v.Type =='Switch' then 
                                if im.Button(ctx, lbl,  v.Sldr_W or 150 ) then 
                                    v.Is_On = toggle (v.Is_On)
                                end
                                if not v.Is_On then 
                                    Highlight_Itm(WDL, 0x00000044)
                                end
                                -- Hover help for switch virtual buttons
                                if HelperMsg and im.IsItemHovered(ctx) and not HelperMsg._switch_added then
                                    HelperMsg.Need_Add_Mouse_Icon = 'L'
                                    HelperMsg.L = 'Click: Toggle On/Off'
                                    HelperMsg.Need_separator = true
                                    HelperMsg._switch_added = true
                                end
                            elseif  v.Type =='Selection' then 

                                im.BeginGroup(ctx)
                                AddArrow_IF_NEEDED(ctx, 'Left', v, lbl, v.Chosen or '', i, FX_Idx, v.Choices, true)

                                if v.AddArrows then
                                    im.SetNextItemWidth(ctx, v.Sldr_W or 150) 
                                end
                                local flg = v.AddArrows and im.ComboFlags_NoArrowButton
                                local opened = im.BeginCombo(ctx, '##'.. lbl, v.Chosen or '', flg)
                                -- Hover help for selection combo preview
                                if HelperMsg and im.IsItemHovered(ctx) and not HelperMsg._selection_added then
                                    HelperMsg.Need_Add_Mouse_Icon = 'L'
                                    HelperMsg.L = 'Click: Open Choices'
                                    HelperMsg.Need_separator = true
                                    HelperMsg._selection_added = true
                                end
                                if opened then 
                                    for i , V in ipairs(v.Choices)do 
                                        if im.Selectable(ctx,(V.ChoiceName or '')..'##' ) then 
                                            v.Chosen = V.ChoiceName
                                            v.CurrentOps = i
                                        end 
                                    end
                                    im.EndCombo(ctx)
                                end

                                AddArrow_IF_NEEDED(ctx, 'Right', v, lbl, v.Chosen or '', i, FX_Idx, v.Choices, true)
                                im.EndGroup(ctx)

                            elseif v.Type =='Selection Btns' then 
                                RenderChoiceButtons(v)
                                -- Hover help for selection shown as buttons
                                if HelperMsg and im.IsItemHovered(ctx) and not HelperMsg._selection_added then
                                    HelperMsg.Need_Add_Mouse_Icon = 'L'
                                    HelperMsg.L = 'Click: Choose Option'
                                    HelperMsg.Need_separator = true
                                    HelperMsg._selection_added = true
                                end
                            end
                            if v.Btn_Clr then 
                                im.PopStyleColor(ctx,6)
                            end
                            local X, Y = im.GetCursorPos(ctx)
                            MakeItemEditable(FxGUID, v, v.Sldr_W, 'Sldr', v.PosX or X, v.PosY or Y)
                       
                            im.SetCursorPos(ctx,X,Y)
                        end
                    end
                end
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

                    local ID = FxGUID .. Fx_P
                    Rounding = 0.5


                    ----Default Layouts
                    if not FP.PosX and not FP.PosY then
                        local idx = Fx_P - 1
                        local topPad = im.GetTextLineHeight(ctx)
                        if FP.Type == 'Slider' or (not FP.Type and not FX[FxGUID].DefType) or FX[FxGUID].DefType == 'Slider' or FP.Type == 'Drag' or (FX[FxGUID].DefType == 'Drag' and FP.Type == nil) then
                            local itemsPerColumn = 7
                            local rowSpacing = 2
                            local rowPitch = 30 + rowSpacing
                            local row = idx % itemsPerColumn
                            local Column = math.floor(idx / itemsPerColumn)
                            local firstInColumn = Column * itemsPerColumn + 1
                            local colW = FX[FxGUID][firstInColumn] and (FX[FxGUID][firstInColumn].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160) or (FX.Def_Sldr_W[FxGUID] or 160)
                            local W = (colW + GapBtwnPrmColumns) * Column
                            local Y = topPad + (row * rowPitch)
                            im.SetCursorPos(ctx, W, Y)
                        elseif FP.Type == 'V-Slider' or (FX[FxGUID].DefType == 'V-Slider' and FP.Type == nil) then
                            im.SetCursorPos(ctx, 17 * idx, topPad)
                        elseif FP.Type == 'Knob' or (FX[FxGUID].DefType == 'Knob' and FP.Type == nil) then
                            local KSz = Df.KnobSize
                            local G = 15
                            local rowsPerColumn = 3
                            local row = idx % rowsPerColumn
                            local Column = math.floor(idx / rowsPerColumn)
                            im.SetCursorPos(ctx, KSz * Column, topPad + (KSz + G) * row)
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

                        FP.BgClrAct, FP.BgClrHvr = Generate_Active_And_Hvr_CLRs(FP.BgClr, 1)
                       
                    end


                    --- if there's condition for parameters --------
                    local CreateParam, ConditionPrms, Pass = nil, {}, {}

                    ---@param ConditionPrm "ConditionPrm"
                    ---@param ConditionPrm_PID "ConditionPrm_PID"
                    ---@param ConditionPrm_V_Norm "ConditionPrm_V_Norm"
                    ---@param ConditionPrm_V "ConditionPrm_V"
                    ---@return boolean
                    local function CheckIfCreate(ConditionPrm, ConditionPrm_PID, ConditionPrm_V_Norm, ConditionPrm_V, ConditionsTB)
                        local Pass 



                        local function Evaluate_Condition_tied_to_Other_Prms()
                            if not FP[ConditionPrm] then Pass = true return end 
                            if type(FP[ConditionPrm]) ~=  'number' then return end -- if this type is number it means the condition is set to Prms
                            if not FX[FxGUID][Fx_P][ConditionPrm_PID] then
                                for i, v in ipairs(FX[FxGUID]) do
                                    if v.Num == FX[FxGUID][Fx_P][ConditionPrm] then
                                        FX[FxGUID][Fx_P][ConditionPrm_PID] = i
                                    end
                                end
                            end
                            local PID = FP[ConditionPrm_PID]

                            if FX[FxGUID][PID].ManualValues then
                                local V = round( r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP[ConditionPrm]), 3)
                                if FP[ConditionPrm_V_Norm] then
                                    for i, v in ipairs(FP[ConditionPrm_V_Norm]) do
                                        if V == round(v, 3) then Pass = true end
                                    end
                                end
                            else
                                local _, V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, FP[ConditionPrm])
                                for i, v in ipairs(FP[ConditionPrm_V]) do

                                    if V == v then Pass = true end
                                end
                            end
                        end
                        local function Evaluate_Condition_tied_to_Virtual_Buttons()
                            if  type(FP[ConditionPrm]) ~=  'table' then return end  -- if this type is table it means the condition is set to virtual buttons
                            local VB = FP[ConditionPrm]
                            if VB.Type =='Switch' then 
                                if ConditionsTB.When_Is_Off then 
                                    Pass = not FP[ConditionPrm].Is_On
                                else 
                                    Pass = FP[ConditionPrm].Is_On
                                end
                            else
                                if ConditionsTB.VB_Val == VB.Chosen then Pass = true end

                            end
                            
                            --[[ if FP[ConditionPrm].Is_On then 
                                Pass = true 
                            end ]]

                        end

                        Evaluate_Condition_tied_to_Other_Prms()
                        Evaluate_Condition_tied_to_Virtual_Buttons()

                        return Pass
                    end

                    if FP['ConditionPrm']  then
                        local DontCretePrm
                        if FP.Conditions then 
                            for i, v in ipairs(FP.Conditions) do 
                                local I = i==1 and '' or i
                                if CheckIfCreate('ConditionPrm' .. I, 'ConditionPrm_PID' .. I, 'ConditionPrm_V_Norm' .. I, 'ConditionPrm_V' .. I, v) then
                                else
                                    DontCretePrm = true
                                end
                            end
                        end
                        if not DontCretePrm then CreateParam = true end
                        --[[ if CheckIfCreate('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V_Norm', 'ConditionPrm_V') then
                            local DontCretePrm
                            for i = 2, 5, 1 do
                                local I = i==1 and '' or i
                                if CheckIfCreate('ConditionPrm' .. I, 'ConditionPrm_PID' .. I, 'ConditionPrm_V_Norm' .. I, 'ConditionPrm_V' .. I) then
                                else
                                    DontCretePrm = true
                                end
                            end
                            if not DontCretePrm then CreateParam = true end
                        end ]]
                    end




                    if CreateParam or not FP.ConditionPrm then
                        local FP = FP

                        if FP and FxGUID then
                            Lk(FP)
                            ---!!!!!! use  drawlist  splitter here?  So that Mod Lines can be on top, or to decide what drawings take precedence
                            local function Create_Item()
                                local pos =  { im.GetCursorScreenPos(ctx) }

                                --- Add Parameter controls ---------
                                if FP.Type == 'Slider' or FX[FxGUID].DefType == 'Slider' then
                                    AddSlider(ctx, FxGUID, Fx_P, FX_Idx)
                                elseif FP.Type == 'Knob' or (FX[FxGUID].DefType == 'Knob' and FP.Type == nil) then
                                    AddKnob(ctx, FxGUID, Fx_P, FX_Idx)
                                elseif FP.Type == 'V-Slider' or (FX[FxGUID].DefType == 'V-Slider') then
                                    AddSlider(ctx, FxGUID, Fx_P, FX_Idx)
                                elseif FP.Type == 'Switch' then
                                    AddSwitch(ctx, FxGUID, Fx_P, FX_Idx)
                                elseif FP.Type == 'Drag' or (FX[FxGUID].DefType == 'Drag') then
                                    AddDrag(ctx, FxGUID, Fx_P, FX_Idx)
                                elseif FP.Type == 'Selection' then
                                    AddCombo(ctx, FxGUID, Fx_P, FX_Idx)
                                elseif FP.Type == 'XY Pad - X' then
                                    Add_XY_Pad(ctx, FxGUID, Fx_P, FX_Idx)
                                end
                                
                                return pos
                            end

                            local function Item_Interaction()
                                if im.IsItemClicked(ctx) and LBtnDC then    
                                    if Mods == 0 and FP.Type ~= 'Selection' then
                                        Set_Prm_To_Default(FX_Idx, FP)
                                    elseif Mods == Alt then
                                        if FP.Deletable then
                                            DeletePrm(FxGUID, Fx_P, FX_Idx)
                                        end
                                    end
                                end
                            end
                            local function Double_Click_To_Reset_Value()

                                if ToDef.ID and ToDef.V then
                                    r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef.V)
                                    if FP.WhichCC then

                                        local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, ToDef.ID, "param." .. ToDef.P .. ".plink.active", 0) -- 1 active, 0 inactive
                                        r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef.V)
                                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. ToDef.P .. 'Value before modulation', ToDef.V, true)
                                        r.gmem_write(7, FP.WhichCC) --tells jsfx to retrieve P value
                                        PM.TimeNow = r.time_precise()
                                        r.gmem_write(JSFX.P_ORIG_V + FP.WhichCC, ToDef.V)
                                        ParameterMIDILink(ToDef.ID, ToDef.P, 1, false, 15, 16, 176, FP.WhichCC, false)

                                    end
                                    FP.V = ToDef.V

                                    ToDef = {}
                                end
                            end

                            ------ EXECUTION -----
                            ---
                            local pos = Create_Item()
                            Show_Modulator_Control_Panel(pos, FP, FxGUID)

                            --Prm_Modulation_tooltip_Win(FP)

                            --Draw_Attached_Drawings(FP,FX_Idx, pos, p_value)
                            Item_Interaction()
                            Double_Click_To_Reset_Value()

                            -- Show contextual help for parameter interactions while hovered
                            if im.IsItemHovered(ctx) then
                                -- Right-click actions on parameter controls
                                HelperMsg.R = 'Select as Link Source'
                                HelperMsg.Shift_R = 'Toggle Parameter Link'
                                HelperMsg.Ctrl_R = 'Open Parameter Menu'
                                HelperMsg.Need_separator = true

                                -- Additional notes
                                if HelperMsg.Others then
                                    table.insert(HelperMsg.Others, 'Double-click: Reset to default')
                                    -- Mouse wheel adjustment hints (behavior handled elsewhere)
                                    if not HelperMsg._wheel_added then
                                        if Ctrl_Scroll then
                                            table.insert(HelperMsg.Others, 'Mouse Wheel: Adjust Value')
                                            table.insert(HelperMsg.Others, 'Shift + Mouse Wheel: Fine Adjust')
                                        else
                                            table.insert(HelperMsg.Others, 'Ctrl + Mouse Wheel: Adjust Value')
                                            table.insert(HelperMsg.Others, 'Ctrl+Shift + Mouse Wheel: Fine Adjust')
                                        end
                                        HelperMsg._wheel_added = true
                                    end
                                    if FP.Deletable then
                                        table.insert(HelperMsg.Others, 'Alt+Double-click: Remove Parameter')
                                    end
                                end
                            end


                        end
                        if im.IsItemClicked(ctx, 1) and Mods == 0 and not AssigningMacro then
                            local draw_list = im.GetForegroundDrawList(ctx)
                            local mouse_pos = { im.GetMousePos(ctx) }
                            local click_pos = { im.GetMouseClickedPos(ctx, 0) }
                            im.DrawList_AddLine(draw_list, click_pos[1], click_pos[2], mouse_pos[1],
                                mouse_pos[2], 0xB62424FF, 4.0) -- Draw a line between the button and the mouse cursor
                            local P_Num = FP.Num
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
                            local P_Num = FP.Num
                            local rv, bf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                "param." .. P_Num .. ".plink.midi_bus")
                            if bf == "15" then -- reset FX Devices' modulation bus/chan
                                r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. P_Num .. ".plink.midi_bus", 0)         -- reset bus and channel because it does not update automatically although in parameter linking midi_* is not available
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
                            im.OpenPopup(ctx, '##prm Context menu' .. (FP.Num or 0))
                        end
                        if im.BeginPopup(ctx, '##prm Context menu' .. (FP.Num or 0)) then
                            if im.Selectable(ctx, 'Toggle Add Parameter to Envelope', false) then
                                local env = r.GetFXEnvelope(LT_Track, FX_Idx, FP.Num, false)    -- Check if envelope is on
                                if env == nil then                                               -- Envelope is off
                                    local env = r.GetFXEnvelope(LT_Track, FX_Idx, FP.Num, true) -- true = Create envelope
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
                                local env = r.GetFXEnvelope(LT_Track, FX_Idx, FP.Num, false) -- Check if envelope is on
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
                                    "param." .. FP.Num .. ".acs.active") -- Active(true, 1), Deactivated(true, 0), UnsetYet(false)
                                if retval and buf == "1" then             -- Toggle
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num ..
                                        ".acs.active", 0)
                                else
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num ..
                                        ".acs.active", 1)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num .. ".acs.chan",
                                        1)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num ..
                                        ".acs.stereo", 1)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." ..
                                        FP.Num .. ".mod.visible", 1)
                                end
                            end
                            if im.Selectable(ctx, 'Toggle Add LFO') then
                                local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                    "param." .. FP.Num .. ".lfo.active")
                                if retval and buf == "1" then
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num ..
                                        ".lfo.active", 0)
                                else
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." .. FP.Num ..
                                        ".lfo.active", 1)
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param." ..
                                        FP.Num .. ".mod.visible", 1)
                                end
                            end
                            if im.Selectable(ctx, 'Toggle Add CC Link') then
                                local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                    "param." .. FP.Num .. ".plink.active")
                                local rv, bf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                    "param." .. FP.Num .. ".plink.midi_bus")
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
                                    ParameterMIDILink(FX_Idx, FP.Num, value, false, 0, 1, 176, retvals, false)
                                end
                            end
                            if im.Selectable(ctx, 'Toggle Open Modulation/Link Window') then
                                local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                    "param." .. FP.Num .. ".mod.visible")
                                if retval and buf == "1" then
                                    value = 0
                                else
                                    value = 1
                                end
                                local window = r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx,
                                    "param." .. FP.Num .. ".mod.visible", value)
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


                Create_Virtual_Buttons()
                
            end

            Disable_If_LayEdit('End')
            Do_PluginScripts(orig_Name)
            --Draw_Background(FxGUID)


            if fx.Enable == false then
                im.DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B+10, 0x00000088)
            end

            

            WindowSize = im.GetWindowSize(ctx)

            im.Dummy(ctx, 100, 100)
            im.EndChild(ctx)    
            im.PopStyleVar(ctx)
                
            Highlight_selected_FX(FX_Idx)
        else
            im.PopStyleVar(ctx)
        end

        -- Draw_Parallel_FX_Enclosure(FX_Idx, FxGUID, Parallel, PosX_before_FX_Win, im.GetWindowDrawList(ctx))
        Store_Parallel_FX_Enclosure_Pos(FX_Idx, FxGUID , Parallel, (POS_X_BEFORE_MIXER or 0) + PAR_FX_MIXER_WIN_W , im.GetWindowDrawList(ctx), SpaceClr)

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


    --im.SetCursorPos(ctx, CurPos_Aftr_Create_FX_Win_SL[1], CurPos_Aftr_Create_FX_Win_SL[2])
    im.PushStyleColor(ctx, im.Col_ChildBg, 0xFF000022)
    --[[ if im.BeginChild(ctx, 'TestChildWin'..FX_Idx,  30, 220 ) then 
        im.Text(ctx, 'TestChildWin'..FX_Idx)
        im.EndChild(ctx)    

    end ]]
    im.PopStyleColor(ctx)


    if Parallel and Parallel == 'Mixer Layout - Show'  then 
        
        return  'Mixer Layout - Show' 
    end
    

end --of Create fx window function

--------------==  Space between FXs--------------------
function AddSpaceBtwnFXs(FX_Idx, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container,
                         AdditionalWidth, FX_Idx_in_Container, AddPlusSign, tintClr)
    local SpcIsInPre, Hide, SpcInPost, MoveTarget
    local WinW

    local function If_Is_End_Of_Parallel__Draw_Enclosure_Line()
        if  SpaceIsBeforeRackMixer ~= 'End of Parallel' then  return end 
        local W, H = im.GetItemRectSize(ctx)
        local X, Y = im.GetItemRectMin(ctx)
        local thick = 4
        im.DrawList_AddLine(WDL, X, Y, X , Y+ H , 0xFF0000FF, thick)
    end

    local function If_No_Need_To_Proceed()
        if FX_Name and  string.find( FX_Name , 'FXD Containr Macro') then
            return true
        end 
        
    end
    if If_No_Need_To_Proceed() then return end 
    if FX_Idx == 0 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx = 1 end
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)
    


    TblIdxForSpace = FX_Idx .. tostring(SpaceIsBeforeRackMixer)
    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
   
    local ClrLbl = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')



    Dvdr.Width[TblIdxForSpace] = FX_Idx == Sel_Track_FX_Count and 15 or Dvdr.Width[TblIdxForSpace] or 0



    im.PushStyleColor(ctx, im.Col_ChildBg, 0x000000ff)

    local w = SPACE_BETWEEN_FXS_W + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0) + (AdditionalWidth or 0)
    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)

    local function Draw_Arrow_If_Dragging(X, Y)
        if DontAllowDrop then return end
        if not DragFX_ID then return end

        if HoverOnWindow == true and DragDroppingFX == true and DragFX_Arrow_StartX and DragFX_Arrow_StartY then
            -- Draw an arrow when hovering during drag
            local x, y = im.GetCursorScreenPos(ctx)
            local x , y = X or x, Y or y
            local sX, sY = DragFX_Arrow_StartX, DragFX_Arrow_StartY
            local eX, eY = x + w/2, y + 110
            local P = 13
            
            im.DrawList_AddLine(Glob.FDL, sX, sY , sX, sY-P, 0xFFFFFFFF, 2)
            im.DrawList_AddLine(Glob.FDL, sX, sY - P, eX, sY - P, 0xFFFFFFFF, 2)
            --[[ im.DrawList_AddLine(Glob.FDL, eX, sY - 20 , eX, sY , 0xFFFFFFFF, 2) ]]
            local arrowCoords = {
                startX = eX,
                startY = sY-P,
                endX = eX,
                endY = sY
            }
            DrawArrow(arrowCoords, 0xFFFFFFFF, 2, 8, nil, Glob.FDL)
        end
    end
    local function Create_Space()
        -- StyleColor For Space Btwn Fx Windows
        if  Hide then return end 

        im.PushStyleColor(ctx, im.Col_ChildBg, tintClr or 0x000000ff)
        if im.BeginChild(ctx, '##SpaceBetweenWindows' .. FX_Idx .. tostring(SpaceIsBeforeRackMixer) .. 'Last SPC in Rack = ' .. tostring(AddLastSPCinRack), w, 220, nil, im.WindowFlags_NoScrollbar) then
            --HOVER_RECT = im.IsWindowHovered(ctx,  im.HoveredFlags_RectOnly)
            HoverOnWindow = im.IsWindowHovered(ctx, im.HoveredFlags_AllowWhenBlockedByActiveItem)
            WinW          = im.GetWindowSize(ctx)
            local SpaceBtnL, SpaceBtnT, SpaceBtnR, SpaceBtnB

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

                local BtnSign = im.IsPopupOpen(ctx, 'Btwn FX Windows' .. FX_Idx)  and '' or BtnSign

                im.PushFont(ctx, Arial_30)
                im.PushStyleColor(ctx, im.Col_Button, 0x000000ff)
                local btn  = im.Button(ctx, BtnSign..'##Button between Windows', w, 220)
                im.PopStyleColor(ctx)
                im.PopFont(ctx)
                local BtnL, BtnT = im.GetItemRectMin(ctx)
                local BtnR, BtnB = im.GetItemRectMax(ctx)
                SpaceBtnL, SpaceBtnT, SpaceBtnR, SpaceBtnB = BtnL, BtnT, BtnR, BtnB

                FX_Insert_Pos = FX_Idx

                if btn then
                    im.SetNextWindowPos(ctx, BtnR, VP.Y - 300)
                    im.OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx)
                end
                im.PopStyleColor(ctx, 2)
                Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                if AddPlusSign then 
                    local L, T, R, B, w, h = HighlightSelectedItem(nil, 0xffffff77, -5, nil,nil,nil,nil, nil, nil , 4, 4, 'GetItemRect', nil, nil, 4) 
                end
            else
                Dvdr.RestoreNormWidthWait[FX_Idx] = (Dvdr.RestoreNormWidthWait[FX_Idx] or 0) + 1
                if Dvdr.RestoreNormWidthWait[FX_Idx] >= 2 then
                    Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                    Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                end
            end

            AddFX_Menu(FX_Idx, nil, nil,  SpcIDinPost)

            if im.IsPopupOpen(ctx, 'Btwn FX Windows' .. FX_Idx) then 
                ADD_FX_MENU_WIN_SZ_X, ADD_FX_MENU_WIN_SZ_Y = im.GetWindowSize(ctx)
                if SpaceBtnL and SpaceBtnR then
                    im.SetNextWindowPos(ctx, SpaceBtnR, VP.Y - 300)
                    local X = SpaceBtnR
                    local Y = SpaceBtnT + (SpaceBtnB - SpaceBtnT) / 2
                    local Vert_Line_Leng = Y - (VP.Y - 300)
                    im.DrawList_AddLine(Glob.FDL, X, Y, X + 16, Y, 0xffffffff, 3)
                    im.DrawList_AddLine(Glob.FDL, X + 15, Y, X + 15, Y - Vert_Line_Leng, 0xffffffff, 3)
                    im.DrawList_AddRect(Glob.FDL, SpaceBtnL, SpaceBtnT, SpaceBtnR, SpaceBtnB, 0xffffffaa, 3, nil, 2)
                    im.DrawList_AddRectFilled(Glob.FDL, SpaceBtnL, SpaceBtnT, SpaceBtnR, SpaceBtnB, 0xffffff2a, 3)
                end
            end

            im.EndChild(ctx)
        end
        im.PopStyleColor(ctx)


    end
    Create_Space()
    local X_before_Space, Y_before_Space = im.GetItemRectMin(ctx)
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
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
        end
        for i = 1, #Trk[TrkID].PreFX + 1, 1 do
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '', true)
        end
        if not DontMove then
            if FX_Idx ~= Sel_Track_FX_Count and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
                --[[ if ((fx.ShortNameor''):find('Pro%-Q 3') or (fx.ShortNameor''):find('Pro%-C 2')) and not tablefind (Trk[TrkID].PreFX, FXGUID[FX_Idx]) then
                    AltDestLow = FX_Idx-1
                end ]]
                local offset = 0 
                --[[ if (FX[FxGUID].ShortName or ''):find('Pro%-C 2') then
                    AltDestHigh = FX_Idx - 1
                end ]]
                FX_Idx = tonumber(FX_Idx)
                DragFX_ID = tonumber(DragFX_ID)

                if FX_Idx > DragFX_ID and FX_Idx < 0x2000000 then offset = 1 end


                table.insert(MovFX.ToPos, AltDestLow or FX_Idx - (offset or 0))
                table.insert(MovFX.FromPos, DragFX_ID)
            elseif FX_Idx == Sel_Track_FX_Count and AddLastSpace == 'LastSpc' or SpaceIsBeforeRackMixer == 'End of PreFX' then
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
        if FX_Idx ~= Sel_Track_FX_Count then
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
        if FX_Idx ~= Sel_Track_FX_Count then
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

    im.SameLine(ctx, 100, 10)
    local function Drag_Drop_FX_In_BS()
        if SpaceIsBeforeRackMixer ~= 'SpcInBS' then return end 
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
                elseif dropped and Mods == Cmd then
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
    end
    local function Drag_Drop_FX_Normal() -- if Space is not in FX Layer
        if SpaceIsBeforeRackMixer == 'SpcInBS' then return end 
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
                allowDropNext =  Mods == Cmd and true 
                FxGUID_DragFX = DragFxGuid 
                local rv, type, payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)
                local FxGUID_DragFX = FxGUID_DragFX or DragFX_ID_Table and DragFX_ID_Table[1]


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





                if (DragFX_ID + offset == FX_Idx or DragFX_ID + offset == FX_Idx - 1) and SpaceIsBeforeRackMixer ~= true  and not SpcInPost and not allowDropNext or DontAllowDrop then
                    im.SameLine(ctx, nil, 0)

                    Dvdr.Width[TblIdxForSpace] = 0
                else
                    Draw_Arrow_If_Dragging(X_before_Space, Y_before_Space)
                    Highlight_Itm(Glob.FDL, nil, 0xffffffff, 0, 0, 1, 0)
                    HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect', Foreground)

                    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width

                    dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

                    if dropped and Mods == 0 then
                        local function local_MoveFX (DragFX_ID, FX_Idx)
                            payload = tonumber(payload)
                            r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 0, 1, 0)
                            r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 1, 2, 0)

                            r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 0, 1, 0)
                            r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 1, 2, 0)

                            --[[ if FX.Win_Name_S[payload]:find('Pro%-Q 3') and not tablefind(Trk[TrkID].PostFX, FxGUID_DragFX ) and not SpcInPost and not SpcIsInPre and not tablefind(Trk[TrkID].PreFX, FxGUID_DragFX) then
                                MoveFXwith1PreFX(DragFX_ID, FX_Idx, 'Move Pro-Q 3 and it\'s analyzer')
                            else ]]
                            MoveFX(DragFX_ID, FX_Idx, true, nil)


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
                            --[[ if Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer] ] ~= nil then
                                Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer] ] = Lyr.FX_Ins
                                    [FX.InLyr[FXGUID_To_Check_If_InLayer] ] - 1
                            end
                            r.SetProjExtState(0, 'FX Devices',
                                'FXLayer - ' .. 'is FX' .. FXGUID_To_Check_If_InLayer .. 'in layer', "")
                            FX.InLyr[FXGUID_To_Check_If_InLayer] = nil ]]
                            Dvdr.JustDroppedFX = true


                            local function If_FX_Is_Parallel()
                                --if not V then return end 
                                local FX_Idx = tonumber(payload)
                                local rv , parallel = r.TrackFX_GetNamedConfigParm(LT_Track,FX_Idx, 'parallel') 

                                if parallel == '1' then 
                                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx , 'parallel', '0')
                                end

                              --[[   if Check_If_Its_Root_of_Parallel(FX_Idx) then -- if the fx we're moving is the root of a parallel chain
                                    --local nextFX, PrevFX = GetNextAndPreviousFXID(V.addr_fxid)
                                    r.TrackFX_SetNamedConfigParm( LT_Track, V.addr_fxid + (V.scale or 1), 'parallel', '0' )
                                    -- set next fx to not parallel with previous fx (Make the next fx the root of the parallel chain)
                                end ]]
                            end

                            If_FX_Is_Parallel()
                        end

                        if  Trk[TrkID].Sel_FX and Trk[TrkID].Sel_FX[1] and DragFX_ID_Table  then  -- DragFX_ID_Table will only be non-nil if user is draggin on selected fxs
                            for i, v in ipairs(Trk[TrkID].Sel_FX) do 
                                local idx = Find_FxID_By_GUID(v)
                                table.insert(MovFX.ToPos, FX_Idx)
                                table.insert(MovFX.FromFxID, v)
                            end
                        elseif DragFX_ID  then 
                            local_MoveFX (DragFX_ID, FX_Idx)
                        end
                    elseif dropped and Mods == Cmd then
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
                    Dvdr.Width[TblIdxForSpace] = 0
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
                    RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                end
                im.PopStyleColor(ctx)

            end
            im.EndDragDropTarget(ctx)
        else
            Dvdr.Width[TblIdxForSpace] = 0
            im.SameLine(ctx, nil, 0)
        end

        im.SameLine(ctx, nil, 0)
    end
    Drag_Drop_FX_In_BS()
    Drag_Drop_FX_Normal() 

    return WinW
end

function Draw_Background(FxGUID, pos, Draw_Which , IsPreviewBtn, IsForeGround)

    if not FX[FxGUID].Draw or FX[FxGUID].Collapse then return end
    local function Draw_Itm (i  , TB  )
        FX[FxGUID].Draw[i] = FX[FxGUID].Draw[i] or {}
        local D = TB[i]
        local pos = pos or {}
        local L = pos[1] or (Win_L + D.L)
        local T = pos[2] or (Win_T + D.T)
        local R = pos[3] or (Win_L + (D.R or 0))
        local B = pos[4] or (Win_T + (D.B or 0))
        local Xg, Yg = D.XGap or 0, D.YGap or 0
        local Gap = D.Gap or 0
        if IsPreviewBtn then -- if it's used for the preview button in layout editor
            local Sz = {pos[3]- pos[1] , pos[4] - pos[2]}
            local Wid =   FX[FxGUID].Width or DefaultWidth
            L = SetMinMax( pos[1] + (D.L / Wid) * Sz[1], pos[1], pos[3])
            T = SetMinMax( pos[2] + (D.T / 220) * Sz[2], pos[2], pos[4])
            R = SetMinMax( pos[1] + ((D.R or 0) / Wid) * Sz[1], pos[1], pos[3])
            B = SetMinMax( pos[2] + ((D.B or 0) / 220) * Sz[2], pos[2], pos[4])
            Xg = Xg / Wid * Sz[1]
            Yg = (Yg / 220) * Sz[2]
        end
        local Round = TB.Df_EdgeRound or 0
        local WDL = WDL or im.GetWindowDrawList(ctx)
        local function Repeat(rpt, Xgap, Ygap, func, Gap, RPTClr, CLR)
            if rpt and rpt ~= 0 then
                local RPT = rpt
                if va and va ~= 0 then RPT = rpt * Val * va end

                for i = 0, RPT - 1, 1 do

                    --[[ local Clr1 = (v.Clr_VA ) and BlendColors(CLR or 0xffffffff, v.Clr_VA,  Val) or CLR or 0xffffffff
                    local Clr2 = (v.RPT_Clr_VA ) and BlendColors(RPTClr or 0xffffffff, v.RPT_Clr_VA ,  Val) or RPTClr or  0xffffffff


                    local Clr = BlendColors(Clr1 , Clr2, i / RPT)

                    local Clr1 = (v.Clr2_VA ) and BlendColors(CLR2 or 0xffffffff, v.Clr2_VA,  Val) or CLR2 or 0xffffffff
                    local Clr2 = (v.RPT_Clr2_VA ) and BlendColors(RPTClr2 or 0xffffffff, v.RPT_Clr2_VA ,  Val) or RPTClr2 or  0xffffffff

                    local Clr2 = BlendColors(Clr1 , Clr2, i / RPT) ]]
                    local Clr , Clr2 =  D.clr, D.RepeatClr or 0xffffffff
                    local Clr = BlendColors(Clr , Clr2, i / RPT)

                    func(i * (Xgap or 0), i * (Ygap or 0), i * (Gap or 0), Clr)
                end
            else
                func(Xgap)
            end
        end
        local Clr = D.clr or 0xffffffff
        if D.Type == 'line' then

            local function Addline(Xg, Yg, none, RptClr)
                im.DrawList_AddLine(WDL, L + (Xg or 0), T + (Yg or 0), R + (Xg or 0), B + (Yg or 0), RptClr or Clr, D.Thick or 1)
            end
            
            --im.DrawList_AddLine(WDL, L, T, R, B, D.clr or 0xffffffff, D.Thick or 1)
            Repeat(D.Repeat,Xg, Yg, Addline)
        elseif D.Type == 'V-line' then
            im.DrawList_AddLine(WDL, L, T, R, B, Clr)
        elseif D.Type == 'rectangle' then

            if D.Fill then 
                local function AddRectFill (Xg, Yg, Gap , RptClr)
                    local Gap = Gap or 0
                    im.DrawList_AddRectFilled(WDL, L + (Xg or 0) - Gap, T + (Yg or 0) - Gap, R + (Xg or 0) + Gap, B + (Yg or 0) + Gap, RptClr or Clr , Round,  nil)
                end
                Repeat(D.Repeat,Xg, Yg, AddRectFill, Gap)
            else 
                
                local function AddRect (Xg, Yg, Gap, RptClr)
                    local Gap = Gap or 0
                    im.DrawList_AddRect(WDL, L + (Xg or 0) - Gap, T + (Yg or 0) - Gap, R + (Xg or 0) + Gap, B + (Yg or 0) + Gap, RptClr or Clr, Round,  nil, D.Thick or 1)
                end
                Repeat(D.Repeat,Xg, Yg, AddRect, Gap)
            end

        elseif D.Type == 'rect fill' then
            im.DrawList_AddRectFilled(WDL, L, T, R, B, Clr, Round)
        elseif D.Type == 'circle' then

            if D.Fill then 
                local function AddCircleFill (Xg, Yg, Gap, RptClr)
                    im.DrawList_AddCircleFilled(WDL, L + (Xg or 0), T + (Yg or 0),  D.R + (Gap or 0), RptClr or Clr)
                end
                Repeat(D.Repeat,Xg, Yg, AddCircleFill, Gap)
            else 
                    
                local function AddCircle (Xg, Yg, Gap, RptClr)
                    im.DrawList_AddCircle(WDL, L + (Xg or 0), T + (Yg or 0), D.R+ (Gap or 0), RptClr or Clr)
                end
                Repeat(D.Repeat,Xg, Yg, AddCircle, Gap)
            end
        elseif D.Type == 'circle fill' then
            im.DrawList_AddCircleFilled(WDL, L, T, D.R, Clr)
        elseif D.Type == 'Text' and D.Txt then
            local it = D.Font_Italic and '_Italic' or ''
            local bd = D.Font_Bold and '_Bold' or ''
            local basefont = D.Font or 'Font_Andale_Mono'
            local fontsize = D.FtSize or 13
            local str = basefont .. '_' .. fontsize .. it .. bd
            if not _G[str]    then
                Attach_New_Font_On_Next_Frame(basefont ,fontsize, D.Font_Italic, D.Font_Bold)
            else
                local Ft = (_G[str])
                im.DrawList_AddTextEx(WDL, Ft, fontsize, L, T, Clr, D.Txt)
            end
        elseif D.Type == 'Picture' then
            local function Draw_Picture(Xg, Yg, none, Clr)
                local L = L + (Xg or 0)
                local T = T + (Yg or 0)
                local R = R + (Xg or 0)
                local B = B + (Yg or 0)
                local Clr = RptClr or Clr
                if not D.Image then
                    im.DrawList_AddRectFilled(WDL, L, T, R, B, 0xffffff33, Round)
                    im.DrawList_AddTextEx(WDL, nil, 12, L, T + (B - T) / 2, 0xffffffff, 'Add Image path', R - L)
                else
                    if D.KeepImgRatio then
                        local w, h = im.Image_GetSize(D.Image)
                        local H_ratio = w / h
                        local size = R - L


                        im.DrawList_AddImage(WDL, D.Image, L, T, L + size, T + size * H_ratio, 0, 0, 1, 1, Clr)
                    else
                        im.DrawList_AddImageQuad(WDL, D.Image, L, T, R, T, R, B, L, B, _1, _2, _3, _4, _5, _6, _7, _8, Clr)
                    end
                end
            end
            Repeat(D.Repeat,Xg, Yg, Draw_Picture)
            -- ImageAngle(ctx, Image, 0, R - L, B - T, L, T)
        end
    end
    if Draw_Which then 
        Draw_Itm (Draw_Which , FX[FxGUID].Draw.Preview or FX[FxGUID].Draw )
    else 
        local TB = FX[FxGUID].Draw.Preview or FX[FxGUID].Draw 
        for i, Type in ipairs(TB) do
            Draw_Itm (i , TB  )
        end
    end

end

function AddKnob_Simple(ctx, label , p_value ,  Size , knobSizeOfs, OutClr, InClr, PointerClr, RangeClr, style, FP)
    local Size = Size or 15
    local p_value = p_value or 0
    local radius_outer = Size or Df.KnobRadius -- Radius ;
    local Knob_Click, Knob_RC



    local V_Font, Font = Arial_12, Font_Andale_Mono_12

    local Radius       = Size or  Radius or 0

    local pos          = { im.GetCursorScreenPos(ctx) }
    local center       = { pos[1] + radius_outer, pos[2] + radius_outer}
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
    local function Interaction()
        if ClickButton == im.ButtonFlags_MouseButtonLeft then                                -- left drag to adjust parameters
            if im.BeginDragDropSource(ctx, im.DragDropFlags_SourceNoPreviewTooltip) then
                im.SetDragDropPayload(ctx, 'my_type', 'my_data')
                Knob_Active  = true
                Clr_SldrGrab = getClr(im.Col_Text)
                HideCursorTillMouseUp(0)
                im.SetMouseCursor(ctx, im.MouseCursor_None)
                if  style ~= 'Mod Range Control' then 
                    if -mouse_delta[2] ~= 0.0 then
                        local stepscale = 1
                        if Mods == Shift then stepscale = 3 end
                        local step = --[[ (v_max - v_min) ]] 1 / (200.0 * stepscale)
                        p_value = p_value + (-mouse_delta[2] * step)
                        p_value = SetMinMax(p_value , 0 , 1 )
                        --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value)
                        --MvingP_Idx = F_Tp
                        --Tweaking = P_Num .. FxGUID
                    end
                end
                im.EndDragDropSource(ctx)
            end
            --[[ elseif ClickButton == im.ButtonFlags_MouseButtonRight and not AssigningMacro then -- right drag to link parameters
            DnD_PLink_SOURCE(FX_Idx, P_Num) ]]
        end
    end

    local function Draw()
            
        local radius_outer = Size + (knobSizeOfs or 0)
        local t = p_value
        local angle =  ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
        local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
        local radius_inner = radius_outer * 0.40

        if style == 'Mod Range Control' then
            local ANGLE_MIN = 3.141592 * 1.5
            local angle = (ANGLE_MIN) + (ANGLE_MAX - (ANGLE_MIN)) * t
            -- draw bg
            im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 1.2, 3.141592 * 0.75, 3.141592 * 2.25)
            im.DrawList_PathStroke(draw_list, 0xffffff22, nil, radius_outer * 0.2)
            im.DrawList_PathClear(draw_list)
            -- draw knob
            im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 1.2, ANGLE_MIN, angle)
            im.DrawList_PathStroke(draw_list, RangeClr or 0x99999922, nil, radius_outer * 0.2)
            im.DrawList_PathClear(draw_list)
            --[[ if not Knob_Active then
                HighlightHvredItem()
            end ]]
            if im.IsItemHovered(ctx) and not FP.Right_Dragging_Mod_Ctrl then 
                im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer*0.95, 0xffffff33, nil,2)
            end
        else
            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_outer, OutClr or im.GetColor(ctx, im.Col_Button))
            im.DrawList_AddLine(draw_list, center[1] + angle_cos * radius_inner, center[2] + angle_sin * radius_inner, center[1] + angle_cos * (radius_outer - 2), center[2] + angle_sin * (radius_outer - 2), PointerClr or Clr_SldrGrab, 2)
            im.DrawList_PathArcTo(draw_list, center[1], center[2], radius_outer / 2, ANGLE_MIN, angle)
            im.DrawList_PathStroke(draw_list, RangeClr or 0x99999922, nil, radius_outer * 0.7)
            im.DrawList_PathClear(draw_list)
            local clr = InClr or im.GetColor(ctx, is_active and im.Col_FrameBgActive or is_hovered and im.Col_FrameBgHovered or im.Col_FrameBg)
            im.DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_inner, clr)
        end
    end




    local Active = im.InvisibleButton(ctx, label or '##', Size*2, Size*2, ClickButton) -- ClickButton to alternate left/right dragging
     Interaction()
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


    if Knob_Active then 
        im.DrawList_AddCircle(draw_list, center[1], center[2], radius_outer* 0.95, 0xffffff88)
    end     
    Draw()
     
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
            and FX_is_in_blacklist (FX_Name) ~= true -- not blacklisted
            and string.find(FX_Name, 'RackMixer') == nil
            and FX_Idx ~= Sel_Track_FX_Count                   --not last fx
            and not FX[FxGUID].InWhichBand --[[Not in Band Split]] then

            local rv , ret = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'parallel')
            if rv and ret == '1'  then 
                return 
            end
            
            local Idx = FX_Idx
            if FX_Idx == 1 then
                local Nm = FX.Win_Name[0]
                if Nm == 'JS: FXD Macros' or FX_is_in_blacklist (Nm) then Idx = 0 end
            end
            local CurX = im.GetCursorPosX(ctx)

            local SpcW = AddSpaceBtwnFXs(Idx, 'Normal')

        
           
        elseif FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] and FXGUID[FX_Idx] then
            AddSpaceBtwnFXs(FX_Idx, true)
        elseif FX_Idx == Sel_Track_FX_Count then
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
    if Sel_Track_FX_Count ~= r.TrackFX_GetCount(LT_Track) and not layoutRetrieved then
        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
        --TREE = BuildFXTree(tr)
    end
end 

function MouseBtnIcon(lbl, img)
    im.BeginDisabled(ctx)
    im.ImageButton(ctx, lbl ..'## Mouse' , img,12,16, nil,nil,nil,nil,nil,0xffffffff)
    im.EndDisabled(ctx)
end

function Math_Aten2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    else
        return 0 -- For (0, 0) case
    end
end
function SmoothEdge(x1, y1, xc, yc, x2, y2, smoothScale, segments)
    local points = {}

    -- Adjust the control point based on the smoothScale
    local controlX = xc + (x1 - x2) * smoothScale
    local controlY = yc + (y1 - y2) * smoothScale

    for t = 0, 1, 1 / segments do


        -- Calculate the interpolated points using the quadratic Bézier formula
        local xt = (1 - t)^2 * x1 + 2 * (1 - t) * t * controlX + t^2 * x2
        local yt = (1 - t)^2 * y1 + 2 * (1 - t) * t * controlY + t^2 * y2
        table.insert(points, {x = xt, y = yt})
    end

    return points
end

-- Function to generate points for a curve with two control points
function SmoothCurve(x1, y1, xc, yc, x2, y2, smoothScale, segments)
    local points = {}
    
    -- Calculate control points based on the smoothScale
    local controlX1 = xc - smoothScale -- Control point to the left
    local controlY1 = yc + smoothScale   -- Control point to the left (height adjusted)
    
    local controlX2 = xc + smoothScale    -- Control point to the right
    local controlY2 = yc + smoothScale     -- Control point to the right (height adjusted)
    
    for t = 0, 1, 1 / segments do
        -- Calculate the interpolated points using the cubic Bezier formula
        local xt = (1 - t)^2 * x1 + 2 * (1 - t) * t * controlX1 + t^2 * x2
        local yt = (1 - t)^2 * y1 + 2 * (1 - t) * t * controlY1 + t^2 * y2

        -- Interpolate between the control points for the curve
        local curveX = (1 - t)^2 * xt + 2 * (1 - t) * t * controlX2 + t^2 * x2
        local curveY = (1 - t)^2 * yt + 2 * (1 - t) * t * controlY2 + t^2 * y2
        
        table.insert(points, {x = curveX, y = curveY})
    end

    return points
end

-- Function to generate points for a curve transitioning to a fixed logarithmic curve
function TransitionLogarithmicCurve(x1, y1, x2, y2, curveScale, segments)
    local points = {}
    local startX = math.max(0.1, x1)  -- Prevent log(0) issues

    for t = 0, 1, 1 / segments do
        local x = x1 + (x2 - x1) * t
        
        -- Linear interpolation for straight line
        local linearY = y1 + (y2 - y1) * t

        -- Fixed logarithmic calculation (natural log for simplicity)
        local logY = y1 + (y2 - y1) * (math.log(x - startX + 1))  -- Adjust based on y1

        -- Mix between linear and logarithmic based on curveScale
        local y = linearY * (1 - curveScale) + logY * curveScale
        
        -- Adjust y so that the last point matches y2
        if t == 1 then
            y = y2
        end

        table.insert(points, {x = x, y = y})
    end

    return points
end


-- Function to create a smooth curve (logarithmic or exponential) from a straight line
-- Parameters:
-- x1, y1: Start point of the line
-- x2, y2: End point of the line
-- segments: Number of points on the curve
-- scale: Determines how curved the result is (0 = straight line, positive = logarithmic, negative = exponential)
function SmoothCurveFromLine(x1, y1, x2, y2, segments, scale)
    local points = {}
    
    -- Loop through each segment to compute points
    for i = 0, segments do
        -- Normalized parameter t, goes from 0 to 1
        local t = i / segments

        -- Adjust t based on scale (logarithmic or exponential curve)
        if scale ~= 0 then
            local factor = (math.exp(scale) - 1) -- Create scaling factor
            if scale > 0 then
                -- Logarithmic-like curve
                t = (math.exp(scale * t) - 1) / factor
            else
                -- Exponential-like curve (invert the curve for negative scale)
                t = 1 - (math.exp(scale * (1 - t)) - 1) / (-factor)
            end
        end

        -- Linearly interpolate x and y using the transformed t
        local x = x1 + t * (x2 - x1)
        local y = y1 + t * (y2 - y1)
        
        -- Store the computed point
        table.insert(points, {x = x, y = y})
    end

    return points
end



function LinearToLog(value, min, max, t)
    -- Linear to logarithmic conversion
    local linearValue = min + (max - min) * value
    local logValue = math.log(linearValue + 1,t) / math.log(max + 1, t) -- Shifted for log(0) safety
    return linearValue * (1 - t) + logValue * t
end

--[[ 
function GetCurveValue(x, p)
    if p >= 1 then
        -- Exponential curve: y = x^p
        return x^p
    else
        -- Logarithmic-like curve: scaled log formula
        return math.log(1 + (math.exp(1/p) - 1) * x) / math.log(math.exp(1/p))
    end
end ]]




function Show_Helper_Message()
    if HelperMsg  then
        local WDL = im.GetWindowDrawList(ctx)
        local sz = 18


        local function Set_Help_Text(img, msg, modifier, modifier_str, dbl)
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
                    if dbl then MyText('x2') SL() end
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
                if dbl then MyText('x2') SL() end
            end
            
            MyText(': '.. msg)
            SL(nil, sz*1.5 )

            
        end
        -- Detect double-click in L/R primary messages
        local L_msg, L_dbl = HelperMsg.L, false
        if type(L_msg) == 'string' then
            local m = L_msg:match('^%s*Double%-click:%s*(.*)')
            if m then L_msg, L_dbl = m, true end
        end
        Set_Help_Text(Img.MouseL, L_msg, nil, nil, L_dbl)
        Set_Help_Text(nil, HelperMsg.Ctrl_L, 'Ctrl')
        Set_Help_Text(nil, HelperMsg.Alt_L, 'Alt')
        Set_Help_Text(nil, HelperMsg.Shift_L, 'Shift')

        if HelperMsg.Need_separator then 
            MyText('  |  ')
            SL()
        end
        local R_msg, R_dbl = HelperMsg.R, false
        if type(R_msg) == 'string' then
            local m = R_msg:match('^%s*Double%-click:%s*(.*)')
            if m then R_msg, R_dbl = m, true end
        end
        Set_Help_Text(Img.MouseR, R_msg, nil, nil, R_dbl)

        Set_Help_Text(nil, HelperMsg.Ctrl_R, 'Ctrl')
        Set_Help_Text(nil, HelperMsg.Alt_R, 'Alt')
        Set_Help_Text(nil, HelperMsg.Shift_R, 'Shift')



        Set_Help_Text(nil, HelperMsg.Apl, 'Shift')






        -- Render other hints; detect Double-click and Alt+Double-click patterns
        for i, v in ipairs(HelperMsg.Others) do 
            if type(v) == 'string' then
                local msg = v
                local mod
                -- Match patterns like 'Alt+Double-click: Message'
                local modPart, rest = v:match('^%s*([%w]+)%+Double%-click:%s*(.*)')
                if modPart and rest then
                    mod = modPart
                    msg = rest
                    -- Use left mouse icon doubled by default
                    Set_Help_Text(Img.MouseL, msg, mod, nil, true)
                else
                    -- Match plain 'Double-click: Message'
                    local plain = v:match('^%s*Double%-click:%s*(.*)')
                    if plain and #plain > 0 then
                        Set_Help_Text(Img.MouseL, plain, nil, nil, true)
                    else
                        MyText(v)
                    end
                end
            else
                -- Fallback for non-string entries
                MyText(tostring(v))
            end
        end


       
       


    end

end



function Marquee_Selection(ItmCt, TB, V , FillClr)
    local WDL = im.GetWindowDrawList(ctx)
    if  im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
        --if MouseX > L and MouseX < R - 5 and MouseY > T and MouseY < B then
        if im.IsMouseClicked(ctx,1) then 
            Marq_Start = {im.GetMousePos(ctx)}
            if Mods ~= Shift then 
                TB ={}
            end
        end 

        if im.IsMouseDown(ctx,1)  then 
            local S = Marq_Start --Start
            local N = {im.GetMousePos(ctx)} --now
            --local ItmCt ={ L+ (R-L)/2 , T+ (B-T)/2 }
            if not S then return end 
            local minX = math.min(S[1], N[1])
            local minY = math.min(S[2], N[2])
            im.DrawList_AddRectFilled(WDL, S[1], S[2], N[1], N[2], 0xffffff05)
            im.DrawList_AddCircle(WDL, ItmCt[1],ItmCt[2], 5, 0xffffff88)


            -- if marquee covers item center

            if minX+ math.abs(S[1]- N[1]) > ItmCt[1] and minX < ItmCt[1] 
                and minY+ math.abs(S[2] - N[2]) > ItmCt[2] and minY < ItmCt[2]   then 
                    if FillClr then 
                        im.DrawList_AddCircleFilled(WDL, ItmCt[1],ItmCt[2], 5, 0xffffff88)
                    end

                if not FindExactStringInTable(TB , V) then 
                    table.insert(TB , V)
                end 
            elseif FindExactStringInTable(TB , V) then
                if FillClr then 
                    im.DrawList_AddCircleFilled(WDL, ItmCt[1],ItmCt[2], 5, 0xffffff88)
                end

            end 
        else 

            Marq_Start = nil

        end 


       
        --end
    end
    return TB
end


function DrawArrow(coords, color, thickness, headSize, Y_Offset, DL)
    local thickness = thickness or 1
    local headSize = headSize or 10
    local DrawList = DL or im.GetWindowDrawList(ctx)
    local color = color or 0xffffffff
    if not coords then 
        local sX, sY = im.GetItemRectMin(ctx)
        local eX, eY = im.GetItemRectMax(ctx)
        local w, h = im.GetItemRectSize(ctx)
        coords = {
            startX = sX,
            startY = sY + h/2 + Y_Offset,
            endX = eX,
            endY = eY - h/2 + Y_Offset
        }
    elseif coords[1] then 
        coords = {
            startX = coords[1],
            startY = coords[2],
            endX = coords[3],
            endY = coords[4]
        }
    end
    -- Draw the main line
    im.DrawList_AddLine(DrawList, coords.startX, coords.startY,  coords.endX,  coords.endY, color, thickness)
    
    -- Calculate the angle of the line
    local dx = coords.endX - coords.startX
    local dy = coords.endY - coords.startY
    local angle
    
    if dx == 0 then
        angle = dy > 0 and math.pi/2 or -math.pi/2
    else
        angle = math.atan(dy/dx)
        if dx < 0 then
            angle = angle + math.pi
        end
    end
    
    -- Calculate arrow head points
    local angle1 = angle - (30 * (math.pi/180))
    local angle2 = angle + (30 * (math.pi/180))
    local arrowP1X = coords.endX - headSize * math.cos(angle1)
    local arrowP1Y = coords.endY - headSize * math.sin(angle1)
    local arrowP2X = coords.endX - headSize * math.cos(angle2)
    local arrowP2Y = coords.endY - headSize * math.sin(angle2)
    
    -- Draw arrow head
    im.DrawList_AddLine(DrawList, coords.endX, coords.endY, arrowP1X, arrowP1Y, color, thickness)
    im.DrawList_AddLine(DrawList, coords.endX, coords.endY, arrowP2X, arrowP2Y, color, thickness)
end



