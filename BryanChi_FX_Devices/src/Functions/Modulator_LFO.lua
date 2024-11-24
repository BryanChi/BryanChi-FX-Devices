-- @noindex

--[[ local function ChangeLFO(mode, V, gmem, StrName)
    r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
    r.gmem_write(5, i)    -- Tells jsfx which macro
    r.gmem_write(gmem or 9, V)
    if StrName then 
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro..StrName , V, true)
    end
end

local function SaveLFO(StrName,  V)
    if StrName then 
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro..StrName , V, true)
    end
end
local H = 20

local MOD = math.abs(SetMinMax((r.gmem_read(100 + i) or 0) / 127, -1, 1)) 
LFO.DummyH  =  LFO.Win.h + 20
--LFO.DummyW  =  ( LFO.Win.w + 30) * ((Mc.LFO_leng or LFO.Def.Len)/4 ) 
Mc.Freq = Mc.Freq or 1
Mc.Gain = Mc.Gain or 5
im.TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
--[[  IsMacroSlidersEdited, I.Val = im.SliderDouble(ctx, i .. '##LFO', I.Val, Slider1Min or 0,
Slider1Max or 1) ]]

local W = (VP.w - 10) / 12 -3
local rv = im.InvisibleButton(ctx, 'LFO Button' .. i, W, H)
local w, h = im.GetItemRectSize(ctx)

local L, T = im.GetItemRectMin(ctx)
local WDL = im.GetWindowDrawList(ctx)
local X_range =  (LFO.Win.w ) * ((Mc.LFO_leng or LFO.Def.Len)/4 )

im.DrawList_AddRect(WDL, L, T-2, L + w +2, T + h, EightColors.LFO[i])



if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
    im.OpenPopup(ctx, 'LFO' .. i .. 'Menu')
end

WhenRightClickOnModulators(Macro)
local G = 1  -- Gap between Drawing Coord values retrieved from jsfx
local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)
function DrawShape (Node, L, W, H, T, Clr )
    if Node then 
        for i, v  in ipairs(Node) do 
            local W, H = W or  w , H or h
            
            local N = Node
            local L = L or HdrPosL 
            local h =LFO.DummyH
            local lastX =  N[math.max(i-1,1)].x * W +L
            local lastY = T +H - (-N[math.max(i-1,1)].y + 1)  * H 

            local x =  N[i].x  *W + L
            local y = T + H- (-N[math.min(i, #Node)].y+1)  *H 

            local CtrlX =   (N[i].ctrlX or ((N[math.max(i-1,1)].x  + N[i].x) / 2)) * W + L
            local CtrlY =   T + H - (- (N[i].ctrlY or ((N[math.max(i-1,1)].y + N[i].y) / 2))+1) *H 

            local PtsX, PtsY =  Curve_3pt_Bezier(lastX,lastY,CtrlX,CtrlY,x,y)

            for i, v in ipairs(PtsX) do  
                if i > 1 and PtsX[i] <= L+W then      -- >1 because you need two points to draw a line
                    im.DrawList_AddLine(WDL, PtsX[i-1] ,PtsY[i-1], PtsX[i],PtsY[i], Clr or EightColors.LFO[Macro])
                end
            end
        end
    end
end
-- Draw Tiny Playhead
local PlayPos = L + r.gmem_read(108+i)/4 * w / ((Mc.LFO_leng or LFO.Def.Len)/4 )
im.DrawList_AddLine(WDL ,PlayPos , T ,PlayPos, T+h , EightColors.LFO[Macro], 1 )
im.DrawList_AddCircleFilled(WDL,PlayPos, T+ h -  MOD * h - 3/2 , 3, EightColors.LFO[Macro])

DrawShape(Mc.Node, HdrPosL, w, h, T)

if rv and not LFO_DragDir and Mods == 0 then
    im.OpenPopup(ctx, 'LFO Shape Select')
    --im.SetNextWindowSize(ctx, LFO.Win.w  , LFO.Win.h+200)
end


    
function open_LFO_Win(Track, Macro)
    local tweaking
    -- im.SetNextWindowSize(ctx, LFO.Win.w +20 , LFO.Win.h + 50)
    im.SetNextWindowPos(ctx, HdrPosL, VP.Y - 385)
    if im.Begin(ctx, 'LFO Shape Edit Window'..Macro, true , im.WindowFlags_NoDecoration+ im.WindowFlags_AlwaysAutoResize) then

        
        local function ConverCtrlNodeY (lastY, Y) 
            local Range = (math.max(lastY, Y) - math.min(lastY, Y)) 
            local NormV = (math.min(lastY, Y)+ Range - Y) / Range
            local Bipolar = -1 + (NormV  )* 2
            return NormV
        end



        --Mc.Node = Mc.Node or { x = {} , ctrlX = {}, y = {}  , ctrlY = {}}
        --[[ if not Node[i].x then
            table.insert(Node.x, L)
            table.insert(Node.x, L + 400)
            table.insert(Node.y, T + h / 2)
            table.insert(Node.y, T + h / 2)
        end ]]
        local BtnSz=11

        LFO.Pin = PinIcon (LFO.Pin,TrkID..'Macro = '..Macro  ,BtnSz, 'LFO window pin'..Macro, 0x00000000, ClrTint)
        SL()
        if im.ImageButton(ctx, '## copy' .. Macro, Img.Copy, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint) then 
            LFO.Clipboard = Mc.Node
        end
        SL()
        if im.ImageButton(ctx, '## paste' .. Macro, Img.Paste, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint) then 
            Mc.Node = LFO.Clipboard
        end

        SL(nil, 30)
        if im.ImageButton(ctx, '## save' .. Macro, Img.Save, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint) then 
                LFO.OpenSaveDialog= Macro 
        end

        
        SL()

        if im.ImageButton(ctx, '## shape Preset' .. Macro, Img.Sine, BtnSz*2, BtnSz, nil, nil, nil, nil, 0xffffff00, ClrTint) then 
            if LFO.OpenShapeSelect then LFO.OpenShapeSelect = nil else LFO.OpenShapeSelect = Macro end 
        end 
        if LFO.OpenShapeSelect then Highlight_Itm(WDL, 0xffffff55 ) end 


        im.Dummy(ctx, (LFO.Win.w ) * ((Mc.LFO_leng or LFO.Def.Len)/4 ) ,  LFO.DummyH)
        --local old_Win_T, old_Win_B = VP.y - 320, VP.y - 20
        local NodeSz = 15
        local w, h = im.GetItemRectSize(ctx)
        LFO.Def.DummyW = (LFO.Win.w ) * (LFO.Def.Len/4)
        LFO.DummyW = w
        local L, T = im.GetItemRectMin(ctx)
        local Win_T, Win_B = T  , T+h     -- 7 is prob the window padding
        im.DrawList_AddRectFilled(WDL , L, T, L+w, T+h , 0xffffff22)   
        SL()
        im.Dummy(ctx, 10,  10)


        LFO.Win.L, LFO.Win.R = L , L + X_range
        local LineClr, CtClr = 0xffffff99, 0xffffff44

        Mc.Node = Mc.Node or {{x=0 , y = 0 },{x=1, y = 1 } } -- create two default tables for first and last point
        local Node = Mc.Node


        local function GetNormV(i)
            local NormX = (Node[i].x - HdrPosL) / LFO.Win.w
            local NormY = (Win_B - Node[i].y) / h -- i think 3 is the window padding
            return NormX, NormY
        end

        local function Save_All_LFO_Info(Node) 
            for i, v in ipairs( Node) do 
                if v.ctrlX  then 
                    SaveLFO('Node'..i..'Ctrl X', Node[i].ctrlX)
                    SaveLFO('Node'..i..'Ctrl Y', Node[i].ctrlY)
                end

                SaveLFO('Node '..i..' X', Node[i].x)
                SaveLFO('Node '..i..' Y',Node[i].y)
                SaveLFO('Total Number of Nodes', #Node )
            end
        end

        local Mc = Trk[TrkID].Mod[i]

        Mc.NodeNeedConvert = Mc.NodeNeedConvert or nil

        --[[ if Mc.NodeNeedConvert then 

            for N=1, (Mc.LFO_NodeCt or 0) , 1 do 

                    Node[N] = Node[N] or {}
                if Node[N].x then 
                    Node[N].x = Node[N].x * LFO.Win.w + HdrPosL
                    Node[N].y = T +  (-Node[N].y+1) * h
                end
                if Node[N].ctrlX and Node[N].ctrlY then 
                    Node[N].ctrlX = Node[N].ctrlX* (LFO.Win.w) + LFO.Win.L  
                    Node[N].ctrlY = Win_T + (-Node[N].ctrlY+1) * LFO.Win.h 
                end
            end
            Mc.NodeNeedConvert=nil
        end ]]


        if not im.IsAnyItemHovered(ctx) and LBtnDC then -- Add new node if double click
            local x, y = im.GetMousePos(ctx)
            local InsertPos
            local x = (x - L)/ LFO.DummyW
            local y = (y - T)/ LFO.DummyH


            for i = 1, #Node, 1 do
                if i ~= #Node then
                    if Node[i].x < x and Node[i+1].x > x then InsertPos = i + 1 end
                elseif not InsertPos then 
                    if Node[1].x > x  then InsertPos = 1           -- if it's before the first node
                        --[[ table.insert(Node.ctrlX, InsertPos, HdrPosL + (x-HdrPosL)/2)
                        table.insert(Node.ctrlY, InsertPos, y) ]]


                    elseif Node[i].x < x then InsertPos = i + 1

                    elseif Node[i].x > x then InsertPos  = i 
                    end
                end

            
            end

            table.insert(Node, InsertPos, {
                x= SetMinMax(x, 0, 1);
                y= SetMinMax(y, 0, 1);
            })
            Save_All_LFO_Info(Node) 
        end

        
        local function AddNode(x, y, ID)
            local w, h = 15, 15
            InvisiBtn(ctx, x, y, '##Node' .. ID, 15)
            local Hvred
            local w, h = im.GetItemRectSize(ctx)
            local L, T = im.GetItemRectMin(ctx)

            local function ClampCtrlNode (ID)
                Node[ID] = Node[ID]  or {}

                if Node[ID].ctrlX then
                    local lastX = Node[ID-1].x or 0
                    local lastY, Y = Node[ID-1].y or Node[ID].y , Node[ID].y


                    -- Segment Before the tweaking point
                    if Node[ID].ctrlX and Node[ID].ctrlY then 
                        Node[ID].ctrlX = SetMinMax(Node[ID].ctrlX, lastX , Node[ID].x)
                        Node[ID].ctrlY = SetMinMax(Node[ID].ctrlY, math.min(lastY, Y), math.max(lastY, Y))

                        SaveLFO('Node'..ID..'Ctrl X',Node[ID].ctrlX)
                        SaveLFO('Node'..ID..'Ctrl Y', Node[ID].ctrlY)
                    end
                end
            end

            if im.IsItemHovered(ctx) then
                LineClr, CtClr = 0xffffffbb, 0xffffff88
                HoverNode = ID
                Hvred = true
            end

            if MouseClosestNode==ID and im.IsKeyPressed(ctx,im.Key_X,false) then 
                DraggingNode = ID
                tweaking = Macro 
            elseif im.IsKeyReleased(ctx,im.Key_X)  then 
                DraggingNode=nil
            end 

            -- if moving node
            if (im.IsItemActive(ctx) and Mods == 0)  or DraggingNode == ID then 
                tweaking = Macro
                HideCursorTillMouseUp(nil, im.Key_X )
                HideCursorTillMouseUp(0)
                HoverNode = ID

                local lastX = Node[math.max (ID-1, 1)].x 
                local nextX = Node[math.min (ID+1, #Node)].x
                if ID ==1 then lastX = 0 end 
                if ID == #Node then nextX = 1 end 

                local MsX, MsY =  GetMouseDelta(0, im.Key_X)
                local MsX = MsX / LFO.DummyW
                local MsY = MsY / LFO.DummyH


                Node[ID].x = SetMinMax(Node[ID].x + MsX,  lastX, nextX)
                Node[ID].y = SetMinMax(Node[ID].y + MsY, 0, 1)


                if ID == 1 then 
                    ClampCtrlNode (ID-1) 
                end

                ClampCtrlNode (ID)
                ClampCtrlNode (math.min (ID+1, #Node))
                

                --[[ ChangeLFO(13, NormX, 9, 'Node '..ID..' X')
                ChangeLFO(13, NormY, 10, 'Node '..ID..' Y')
                ChangeLFO(13, ID, 11)   -- tells jsfx which node user is adjusting
                ChangeLFO(13, #Node.x, 12, 'Total Number of Nodes' ) ]]
                local NormX, NormY = GetNormV(ID)

                SaveLFO('Node '..ID..' X', Node[ID].x)
                SaveLFO('Node '..ID..' Y',Node[ID].y)
                SaveLFO('Total Number of Nodes', #Node )


                if ID ~= #Node then
                    local this, next = Node[ID].x, Node[ID+1].x or 1
                    Node[ID+1].ctrlX = SetMinMax(Node[ID+1].ctrlX or (this + next) / 2, this, next)
                    if Node[ID+1].ctrlX == (this + next) / 2 then Node[ID+1].ctrlX = nil end
                end

                im.ResetMouseDragDelta(ctx)
            elseif im.IsItemClicked(ctx) and Mods == Alt then 

                LFO.DeleteNode = ID 
            end


            im.DrawList_AddCircle(WDL, L + NodeSz / 2, T + NodeSz / 2, 5, LineClr)
            im.DrawList_AddCircleFilled(WDL, L + NodeSz / 2, T + NodeSz / 2, 3, CtClr)
            return Hvred
        end
        local Node = Mc.Node
        


        local FDL = im.GetForegroundDrawList(ctx)
        --table.sort(Node.x, function(k1, k2) return k1 < k2 end)
        local AnyNodeHovered
        if  im.IsKeyReleased(ctx, im.Key_C  ) or LBtnRel  then 

            DraggingLFOctrl = nil 
            Save_All_LFO_Info(Node) 
        end

        All_Coord  = {X={};Y={}}

        if LFO.DeleteNode then 
            table.remove(Mc.Node, LFO.DeleteNode)
            Save_All_LFO_Info(Node) 
            LFO.DeleteNode = nil 
        end

        for i = 1 ,#Mc.Node, 1 do --- Rpt for every node   

            local last = math.max(i-1 , 1)
            local lastX, lastY = L+ (Node[last].x or 0) * LFO.DummyW, T+ (Node[last].y or Node[i].y)* LFO.DummyH
            local X , Y = L+ Node[i].x * LFO.DummyW , T+  Node[i].y * LFO.DummyH


            if AddNode(X -15/2 , Y -15 /2, i) then AnyNodeHovered = true end
            local CtrlX, CtrlY  = L+ (Node[i].ctrlX or (Node[last].x + Node[i].x) / 2)* LFO.DummyW, T+ (Node[i].ctrlY or (Node[last].y + Node[i].y) / 2)*LFO.DummyH


            -- Control Node
            if (im.IsMouseHoveringRect(ctx, lastX, Win_T, X, Win_B) or DraggingLFOctrl == i) then
                local Sz = LFO.CtrlNodeSz

                ---- Draw Node
                if not DraggingLFOctrl or DraggingLFOctrl == i  then
                    if not HoverNode and not DraggingNode then
                        im.DrawList_AddBezierQuadratic(FDL, lastX, lastY, CtrlX, CtrlY, X, Y, 0xffffff44, 7)
                        im.DrawList_AddCircle(FDL, CtrlX, CtrlY, Sz, LineClr)
                        --im.DrawList_AddText(FDL, CtrlX, CtrlY, 0xffffffff, i)
                    end
                end

                InvisiBtn(ctx, CtrlX - Sz / 2, CtrlY - Sz / 2, '##Ctrl Node' .. i, Sz)
                if im.IsKeyPressed(ctx, im.Key_C , false )  or im.IsItemActivated(ctx) then 
                    DraggingLFOctrl = i
                end
                
                if im.IsItemHovered(ctx) then
                    im.DrawList_AddCircle(FDL, CtrlX, CtrlY, Sz + 2, LineClr)
                end
            end

            -- decide which node is mouse closest to 
            local Range = X - lastX
            if im.IsMouseHoveringRect(ctx, lastX, Win_T, lastX + Range/2, Win_B) and not tweaking and not DraggingNode  then 
                im.DrawList_AddCircle(FDL, lastX, lastY, LFO.NodeSz+2, LineClr)
                MouseClosestNode = last

            elseif im.IsMouseHoveringRect(ctx, lastX + Range/2, Win_T, X, Win_B) and not tweaking and not DraggingNode  then 
                im.DrawList_AddCircle(FDL, X, Y, LFO.NodeSz+2, LineClr)

                MouseClosestNode = i 
            end

            --- changing control point
            if DraggingLFOctrl==i then

                tweaking = Macro
                local Dx, Dy =  GetMouseDelta(0, im.Key_C)
                local Dx , Dy = Dx / LFO.DummyW, Dy / LFO.DummyH
                local CtrlX, CtrlY  =  Node[i].ctrlX or (Node[last].x + Node[i].x)/ 2,  Node[i].ctrlY or (Node[last].y + Node[i].y) / 2

                Node[i].ctrlX   = SetMinMax(CtrlX + Dx, Node[last].x , Node[i].x)
                Node[i].ctrlY   = SetMinMax(CtrlY + Dy, math.min(Node[last].y , Node[i].y), math.max(Node[last].y , Node[i].y))

                ChangeLFO(14, last, 11 )  -- Tells jsfx which ctrl node is adjusted 
                ChangeLFO(14,  Node[i].ctrlX  , 9,'Node'..i..'Ctrl X')


                ChangeLFO(14,  Node[i].ctrlY , 10, 'Node'..i..'Ctrl Y')
                
            end
            
            PtsX = {}
            PtsY = {}
            
            PtsX, PtsY = Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, X, Y)

            if Wheel_V~=0 then Sqr = ( Sqr or 0 ) + Wheel_V / 100 end 
        
            --im.DrawList_AddLine(FDL, p.x, p.y, 0xffffffff)

            local N = i
            for i, v in ipairs(PtsX) do  
                if i > 1 then      -- >1 because you need two points to draw a line
                    im.DrawList_AddLine(FDL, PtsX[i-1] ,PtsY[i-1], PtsX[i],PtsY[i], 0xffffffff)
                end
                ----- things below don't need >1 because jsfx needs all points to draw lines

                --- normalize values
                local NormX = (PtsX[i] - HdrPosL) / LFO.Win.w
                local NormY = (Win_B - PtsY[i]) / (LFO.DummyH) -- i think 3 is the window padding



                r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                r.gmem_write(5, Macro)

                table.insert(All_Coord.X,  NormX or 0)
                table.insert(All_Coord.Y,  NormY or 0)

            end
            r.gmem_write(6, #Node*11)
        end


        for i, v in ipairs(All_Coord.X) do 
            r.gmem_write(1000+i, v)
            r.gmem_write(2000+i, All_Coord.Y[i])

        end


        if DraggingLFOctrl then 

            HideCursorTillMouseUp(nil, im.Key_C )
            HideCursorTillMouseUp(0)
            
        end
        

        if not AnyNodeHovered then HoverNode = nil end


        --im.DrawList_PathStroke(FDL, 0xffffffff, nil, 2)

        --- Draw Playhead 

        local PlayPos = HdrPosL + r.gmem_read(108+i)/4 * LFO.Win.w
        im.DrawList_AddLine(WDL ,PlayPos , Win_T,PlayPos, Win_B , 0xffffff99, 4 )
        im.DrawList_AddCircleFilled(WDL,PlayPos, Win_B - MOD * LFO.DummyH , 5, 0xffffffcc)

        -- Draw Grid 

        local function DrawGridLine_V (division)
            local Pad_L = 5
            for i= 0, division, 1 do 
                local W = (X_range/division)
                local R = HdrPosL + X_range
                local X = Pad_L +HdrPosL +  W * i
                im.DrawList_AddLine(WDL ,X, Win_T,X, Win_B , 0xffffff55, 2 )
            end
        end
        DrawGridLine_V(Mc.LFO_leng or LFO.Def.Len )


        im.SetCursorPos(ctx, 10,  LFO.Win.h + 55)
        im.AlignTextToFramePadding(ctx)
        im.Text(ctx,'Speed:') SL()
        im.SetNextItemWidth(ctx, 50)
        local rv, V =  im.DragDouble(ctx, '##Speed', Mc.LFO_spd or 1, 0.05, 0.125, 128, 'x %.3f' )
        if im.IsItemActive(ctx) then 
            ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed' )
            tweaking = Macro 
            Mc.LFO_spd = V
            
        end
        if Mods == Alt and im.IsItemActivated(ctx) then Mc.LFO_spd = 1 end 
        if im.IsItemHovered(ctx) then 
            if im.IsKeyPressed(ctx,im.Key_DownArrow, false) then 
                Mc.LFO_spd = (Mc.LFO_spd or 1 )/2 
                ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed' )
            elseif im.IsKeyPressed(ctx,im.Key_UpArrow, false) then 
                Mc.LFO_spd = (Mc.LFO_spd or 1) * 2
                ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed' )
            end
        end
        SL(nil, 30)

        im.Text(ctx, 'Length:') SL()
        im.SetNextItemWidth(ctx, 80)

        rv, Mc.LFO_leng = im.SliderInt(ctx, '##' .. 'Macro' .. i .. 'LFO Length', Mc.LFO_leng or LFO.Def.Len, 1, 8)
        if im.IsItemActivated(ctx) then LengthBefore = Mc.LFO_leng end 
        if im.IsItemActive(ctx ) then 
            tweaking=Macro  
            ChangeLFO(13, Mc.LFO_leng or LFO.Def.Len, 9, 'LFO Length' )
        end 
        if im.IsItemEdited(ctx) then 
            local Change =   Mc.LFO_leng - LengthBefore 
            for i, v in ipairs( Node) do 
                Node[i].x =  Node[i].x / ((LengthBefore+Change) / LengthBefore )
                if Node[i].ctrlX then 
                    Node[i].ctrlX = Node[i].ctrlX / ((LengthBefore+Change) / LengthBefore )
                end
            end
            LengthBefore = Mc.LFO_leng
        end 






        if  im.IsWindowHovered(ctx,im.HoveredFlags_RootAndChildWindows) then 
            LFO.WinHovered = Macro  -- this one doesn't get cleared after unhovering, to inform script which one to stay open
            LFO.HvringWin= Macro      
        else LFO.HvringWin = nil 
            LFO.DontOpenNextFrame = true   -- it's needed so the open_LFO_Win function doesn't get called twice when user 'unhover' the lfo window
        end
        
        if im.IsWindowAppearing(ctx) then 
            Save_All_LFO_Info(Node) 
        end

        im.End(ctx)
    end


    if LFO.OpenShapeSelect == Macro then 

        im.SetNextWindowPos(ctx, L+LFO.DummyW + 30  ,T-LFO.DummyH - 200)
        if not im.ValidatePtr(ShapeFilter, "ImGui_TextFilter*") then
            ShapeFilter = im.CreateTextFilter(Shape_Filter_Txt)
        end
        im.SetNextWindowSizeConstraints( ctx, 220, 150, 240, 700)
        if im.Begin(ctx, 'Shape Selection Popup',true,  im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then 
            local W, H = 150, 75
            local function DrawShapesInSelector(Shapes)
                local AnyShapeHovered
                for i,v in pairs(Shapes) do 
                    --InvisiBtn(ctx, nil,nil, 'Shape'..i,  W, H)

                    if im.TextFilter_PassFilter(ShapeFilter, v.Name) then
                        im.Text(ctx, v.Name or i)
                        
                        --im.SetCursorPosX( ctx, - 15 )
                        local L, T = im.GetItemRectMin(ctx)
                        if im.IsMouseHoveringRect( ctx, L,T, L+ 200, T + 10 ) then 
                            SL( W-8)

                            if TrashIcon(8, 'delete'..(v.Name or i), 0xffffff00) then 
                                im.OpenPopup(ctx, 'Delete shape prompt'..i)
                                im.SetNextWindowPos(ctx,L, T)
                            end
                        end
                        
                        if im.Button(ctx,'##'..(v.Name or i)..i, W, H ) then 
                            Mc.Node = v 
                            LFO.NewShapeChosen = v
                        end
                        if im.IsItemHovered(ctx) then
                            Mc.Node = v
                            AnyShapeHovered = true 
                            LFO.AnyShapeHovered = true 
                        end
                        local L, T = im.GetItemRectMin(ctx)
                        local w, h = im.GetItemRectSize(ctx)
                        im.DrawList_AddRectFilled(WDL, L,T,L+w, T+h , 0xffffff33)
                        im.DrawList_AddRect(WDL, L,T,L+w, T+h , 0xffffff66)

                        DrawShape (v , L,  w, h, T , 0xffffffaa)
                    end
                    if im.BeginPopupModal(ctx, 'Delete shape prompt'..i, true ,  im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize|im.WindowFlags_AlwaysAutoResize) then 
                        im.Text(ctx, 'Confirm deleting this shape:')
                        if  im.Button(ctx, 'yes') or im.IsKeyPressed(ctx, im.Key_Y) or im.IsKeyPressed(ctx, im.Key_Enter) then 
                            LFO.DeleteShape = i 
                            im.CloseCurrentPopup(ctx)

                        end
                        SL()
                        if im.Button(ctx, 'No') or  im.IsKeyPressed(ctx, im.Key_N) or im.IsKeyPressed(ctx, im.Key_Escape) then 
                            im.CloseCurrentPopup(ctx)
                        end
                        im.EndPopup(ctx)
                    end
                end
                if LFO.AnyShapeHovered  then  -- if any shape was hovered
                    if not AnyShapeHovered then   -- if 'unhovered'
                        if  LFO.NewShapeChosen then 
                            local V = LFO.NewShapeChosen
                            Mc.Node = V   ---keep newly selected shape
                        else
                            Mc.Node = LFO.NodeBeforePreview     -- restore original shape
                        end
                        LFO.NodeBeforePreview = Mc.Node
                        LFO.AnyShapeHovered = nil 
                        LFO.NewShapeChosen = nil 
                    end
                end 

                
                return AnyShapeHovered
            end


            local function  Global_Shapes()
                
                if im.IsWindowAppearing(ctx) then  
                    LFO.NodeBeforePreview = Mc.Node
                end
                
                Shapes =  {}



                local F = scandir(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes'))
                

                for i, v in ipairs(F ) do 

                    local Shape = Get_LFO_Shape_From_File(v)
                    if Shape then 
                        Shape.Name = tostring(v):sub(0, -5) 
                        table.insert( Shapes, Shape )
                    end 
                end


                if LFO.DeleteShape then
                    os.remove(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes', Shapes[LFO.DeleteShape].Name..'.ini' ))
                    table.remove(Shapes, LFO.DeleteShape)
                    LFO.DeleteShape = nil 
                end

                if im.TextFilter_Draw(ShapeFilter, ctx, '##PrmFilterTxt', -1 ) then
                    Shape_Filter_Txt = im.TextFilter_Get(ShapeFilter)
                    im.TextFilter_Set(ShapeFilter, Shape_Filter_Txt)
                end




                AnyShapeHovered = DrawShapesInSelector(Shapes)

                

                
                


                


                if im.IsWindowFocused( ctx) and im.IsKeyPressed(ctx, im.Key_Escape) then 
                    
                    im.CloseCurrentPopup(ctx)
                    LFO.OpenShapeSelect = nil
                end
            end


            local function Save_Shape_To_Track()
                local HowManySavedShapes = GetTrkSavedInfo ('LFO Saved Shape Count')

                if HowManySavedShapes then 
                    r.GetSetMediaTrackInfo_String(LT_Track,  'P_EXT: LFO Saved Shape Count', (HowManySavedShapes or 0)+1, true )
                else r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', 1, true )
                end
                local I  = (HowManySavedShapes or 0 )+1
                for i, v in ipairs(Mc.Node) do 
                    if i ==1 then 
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'LFO Node Count = ', #Mc.Node, true)
                    end
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. 'x = ', v.x, true)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. 'y = ', v.y, true)

                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. '.ctrlX = ' , v.ctrlX or '',true)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. '.ctrlY = ' , v.ctrlY or '',true)

                end
                
            end
            local function Save_Shape_To_Project()

                local HowManySavedShapes = getProjSavedInfo('LFO Saved Shape Count' )

                r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count' , (HowManySavedShapes or 0)+1 )


                local I  = (HowManySavedShapes or 0 )+1
                for i, v in ipairs(Mc.Node) do 
                    if i ==1 then 
                        r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node Count = ' ,  #Mc.Node )
                    end
                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. 'x = ', v.x)
                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. 'y = ', v.y)

                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. '.ctrlX = ' , v.ctrlX or '' )
                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. '.ctrlY = ' , v.ctrlY or '' )
                end
            end

            local function Track_Shapes()
                local Shapes = {}
                local HowManySavedShapes = GetTrkSavedInfo ('LFO Saved Shape Count')
                

                for I=1, HowManySavedShapes or 0, 1 do 
                    local Shape = {}
                    local Ct = GetTrkSavedInfo ('Shape'..I..'LFO Node Count = ')

                    for i=1, Ct or 1  , 1 do 
                        Shape[i] =  Shape[i] or {}
                        Shape[i].x =     GetTrkSavedInfo ('Shape'..I..'Node '..i.. 'x = ')
                        Shape[i].y =     GetTrkSavedInfo ('Shape'..I..'Node '..i.. 'y = ')
                        Shape[i].ctrlX = GetTrkSavedInfo ('Shape'..I..'Node '..i.. '.ctrlX = ' )
                        Shape[i].ctrlY = GetTrkSavedInfo ('Shape'..I..'Node '..i.. '.ctrlY = ' )
                    end
                    if Shape[1] then 
                        table.insert(Shapes, Shape)
                    end
                end

                if LFO.DeleteShape then
                    local Count = GetTrkSavedInfo ('LFO Saved Shape Count')
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count' , Count-1 , true ) 
                    table.remove(Shapes, LFO.DeleteShape)
                    
                    for  I, V in ipairs(Shapes) do -- do for every shape
                        for i, v in ipairs(V) do  --- do for every node
                            if i ==1 then 
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'LFO Node Count = ', #V, true)
                            end

                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. 'x = ', v.x or '', true)
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. 'y = ', v.y or '', true)

                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. '.ctrlX = ' , v.ctrlX or '' ,true)
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape'..I..'Node '..i.. '.ctrlY = ' , v.ctrlY or '' ,true)

                        end
                    end
                    LFO.DeleteShape = nil 
                end
                
                DrawShapesInSelector(Shapes)

            end
            local function Proj_Shapes()
                local Shapes = {}
                local HowManySavedShapes = getProjSavedInfo ('LFO Saved Shape Count')

                for I=1, HowManySavedShapes or 0, 1 do 
                    local Shape = {}
                    local Ct = getProjSavedInfo ('LFO Shape'..I..'Node Count = ')
                    for i=1, Ct or 1  , 1 do 
                        Shape[i] =  Shape[i] or {}
                        Shape[i].x =     getProjSavedInfo ('LFO Shape'..I..'Node '..i.. 'x = ')
                        Shape[i].y =     getProjSavedInfo ('LFO Shape'..I..'Node '..i.. 'y = ')
                        Shape[i].ctrlX = getProjSavedInfo ('LFO Shape'..I..'Node '..i.. '.ctrlX = ' )
                        Shape[i].ctrlY = getProjSavedInfo ('LFO Shape'..I..'Node '..i.. '.ctrlY = ' )
                    end
                    if Shape[1] then 
                        table.insert(Shapes, Shape)
                    end
                end

                if LFO.DeleteShape then
                    local Count = getProjSavedInfo ('LFO Saved Shape Count')
                    r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count' , Count-1  ) 
                    table.remove(Shapes, LFO.DeleteShape)
                    
                    for  I, V in ipairs(Shapes) do -- do for every shape
                        for i, v in ipairs(V) do  --- do for every node
                            if i ==1 then 
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node Count = ', #V)
                            end

                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. 'x = ', v.x or '')
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. 'y = ', v.y or '')

                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. '.ctrlX = ' , v.ctrlX or '' )
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape'..I..'Node '..i.. '.ctrlY = ' , v.ctrlY or '' )

                        end
                    end
                    LFO.DeleteShape = nil 
                end
                
                DrawShapesInSelector(Shapes)

            end 

            if im.ImageButton(ctx, '## save' .. Macro, Img.Save, 12, 12, nil, nil, nil, nil, ClrBG, ClrTint) then 
                if LFO.OpenedTab == 'Global' then 
                    LFO.OpenSaveDialog= Macro 
                elseif LFO.OpenedTab == 'Project' then 
                    Save_Shape_To_Project()
                elseif LFO.OpenedTab == 'Track' then
                    Save_Shape_To_Track()
                end
            end
            SL()
            im.AlignTextToFramePadding(ctx)


            if im.BeginTabBar(ctx, 'shape select tab bar') then 
                
                if im.BeginTabItem(ctx, 'Global') then 
                    Global_Shapes ()
                    LFO.OpenedTab = 'Global'
                    im.EndTabItem(ctx)
                end

                if im.BeginTabItem(ctx, 'Project') then 
                    Proj_Shapes()
                    LFO.OpenedTab = 'Project'
                    im.EndTabItem(ctx)
                end

                if im.BeginTabItem(ctx, 'Track') then 
                    Track_Shapes()
                    LFO.OpenedTab = 'Track'
                    im.EndTabItem(ctx)
                end

                im.EndTabBar(ctx)
            end

            if im.IsWindowHovered(ctx,im.FocusedFlags_RootAndChildWindows) then 
                LFO.HoveringShapeWin = Macro 
            else LFO.HoveringShapeWin = nil 
            end
            im.End(ctx)
        end
    end






    return tweaking, All_Coord
    
    
end



local HvrOnBtn = im.IsItemHovered(ctx) 
local PinID = TrkID..'Macro = '..Macro
if HvrOnBtn or LFO.HvringWin == Macro or LFO.Tweaking == Macro or LFO.Pin == PinID or LFO.OpenSaveDialog==Macro or LFO.HoveringShapeWin ==Macro  then  
    LFO.notHvrTime = 0
    LFO.Tweaking, Mc.All_Coord =  open_LFO_Win(Track, Macro)
    LFO.WinHovered = Macro
end

--- open window for 10 more frames after mouse left window or btn
if LFO.WinHovered == Macro and not HvrOnBtn and not LFO.HvringWin and not LFO.Tweaking and not LFO.DontOpenNextFrame then  
    
    LFO.notHvrTime = LFO.notHvrTime + 1
    
    if LFO.notHvrTime > 0 and LFO.notHvrTime < 10 then 
        open_LFO_Win(Track, Macro)
    else 
        LFO.notHvrTime = 0
        LFO.WinHovered = nil     
    end
end
LFO.DontOpenNextFrame = nil 



if im.IsItemActive(ctx) then
    open_LFO_Win(Track, Macro)
    if not LFO_MsX_Start then LFO_MsX_Start, LFO_MsY_Start = r.GetMousePosition() end
    LFO_MsX_Now, LFO_MsY_Now = r.GetMousePosition()
    local thresh = 10
    local DragX, DragY = LFO_MsX_Start - LFO_MsX_Now, LFO_MsY_Start - LFO_MsY_Now

    if not LFO_DragDir then
        if DragX > thresh or DragX < -thresh then
            LFO_DragDir = 'H'
        elseif DragY > thresh or DragY < -thresh then
            LFO_DragDir = 'V'
        end
    end
    local Dx, Dy = im.GetMouseDelta(ctx)
    local DragSpd = 0.1
    if LFO_DragDir == 'H' then
        Mc.Freq = SetMinMax(Mc.Freq + (Dx * DragSpd), 0.1, 20)
        local ActualFreq = Mc.Freq * 100
        ChangeLFO(13, ActualFreq)
    elseif LFO_DragDir == 'V' then
        Mc.Gain = SetMinMax(Mc.Gain - (Dy * DragSpd), 0, 6)
        local ActualGain = Mc.Gain / 6

        ChangeLFO(14, ActualGain)
    end
end 




if not IsLBtnHeld then
    LFO_DragDir = nil
    LFO_MsX_Start, LFO_MsY_Start = nil
end

if Mc.All_Coord then 
    if TrkID ~= TrkID_End and TrkID_End ~= nil and Sel_Track_FX_Count > 0 then
        for i  , v in ipairs(Mc.All_Coord.X) do 
            r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
            r.gmem_write(5, Macro)
            r.gmem_write(6, #Mc.Node*11)
            r.gmem_write(1000+i, v)
            r.gmem_write(2000+i, Mc.All_Coord.Y[i])
        end
    end
end



---- this part draws modulation histogram (Deprecated)
--[[  local MOD = math.abs(SetMinMax(r.gmem_read(100 + i) / 127, -1, 1)) 
Mc.StepV = Mc.StepV or {}
table.insert(Mc.StepV, MOD* Mc.Gain * 4)

if #Mc.StepV > W then
    table.remove(Mc.StepV, 1)
end
for s = 0, W, G do
    local last = SetMinMax(s - 1, 0, W)
    im.DrawList_AddLine(WDL, L + s, T + H - (Mc.StepV[last] or 0), L + s + G,
        T + H - (Mc.StepV[s] or 0), EightColors.LFO[i], 2)
    --im.DrawList_PathLineTo(WDL, L+s,  Y_Mid+math.sin(s/Mc.Freq) * Mc.Gain)
end ]]
if LFO.OpenSaveDialog==Macro then 
    im.OpenPopup(ctx,  'Decide Name')
    im.SetNextWindowPos(ctx, L  ,T-LFO.DummyH)
    im.SetNextWindowFocus( ctx)

    if im.BeginPopupModal( ctx, 'Decide Name',  true ,im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then 
        im.Text(ctx, 'Enter a name for the shape: ')
        --[[ im.Text(ctx, '(?)')
        if im.IsItemHovered(ctx) then 
            tooltip('use / in file name to save into sub-directories')
        end ]]

        im.SetNextItemWidth(ctx, LFO.Def.DummyW)  
            im.SetKeyboardFocusHere(ctx)  
        local rv, buf =  im.InputText(ctx, buf or '##Name' ,buf)

        if  (im.IsItemFocused( ctx)  and im.IsKeyPressed(ctx, im.Key_Enter) and Mods == 0) or im.Button(ctx,'Enter') then 
            local LFO_Name = buf 
            local path = ConcatPath(CurrentDirectory, 'src', 'LFO Shapes')
            local file_path = ConcatPath(path, LFO_Name..'.ini')
            local file = io.open(file_path, 'w')
            
            
            for i, v in ipairs(Mc.Node) do 
                if i ==1 then 
                    file:write('Total Number Of Nodes = ', #Mc.Node, '\n')
                end
                file:write(i , '.x = ' , v.x , '\n') 
                file:write(i , '.y = ' , v.y , '\n') 
                if v.ctrlX and v.ctrlY then 
                    file:write(i , '.ctrlX = ' , v.ctrlX , '\n') 
                    file:write(i , '.ctrlY = ' , v.ctrlY , '\n') 

                end
                file:write( '\n')

            end

            LFO.OpenSaveDialog = nil 
            im.CloseCurrentPopup(ctx)
        end
        SL()
        if im.Button(ctx,'Cancel (Esc)') or im.IsKeyPressed(ctx, im.Key_Escape) then 
            im.CloseCurrentPopup(ctx)
            LFO.OpenSaveDialog = nil 
        end

        

        im.EndPopup(ctx)

    end
end
    


