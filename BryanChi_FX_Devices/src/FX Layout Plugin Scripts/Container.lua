-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid
local fx = FX[FxGUID]

fx.TitleWidth  = 0
--fx.CustomTitle = fx.Name
fx.Width = 35
fx.V_Win_Btn_Height = fx.V_Win_Btn_Height or  130 
fx.Cont_Collapse = fx.Cont_Collapse or 0


local AnyMacroHovered
local ModIconSz = 18 
local Top_Spacing = 0
LFO_Box_Size = 38
local Root_ID = 0
if FX_Idx < 0x2000000 then Root_ID = FX_Idx   Root_FxGuid = FxGUID end 

DEBUG_W = DEBUG_W or {}








local function NotifyHoverState(I,Condition)
    if Condition then 
        fx.HvrMacro = I
        AnyMacroHovered = true 
    elseif Condition == nil then 
        fx.HvrMacro = I
        AnyMacroHovered = true 
    end
end 


local function GetAll_Container_Data()

    local rv , diyFxGUID = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' DIY FxGUID', '', false)
    if rv then fx.DIY_FxGUID = diyFxGUID end
    if not fx.DIY_FxGUID then 
        fx.DIY_FxGUID = math.random(100000000, 999999999)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' DIY FxGUID', fx.DIY_FxGUID, true)
    end


    Trk[TrkID].Container_Id = Trk[TrkID].Container_Id or {}
    local rv, _, _ = FindExactStringInTable(Trk[TrkID].Container_Id , FxGUID)
    if not rv  then 
        table.insert(Trk[TrkID].Container_Id , FxGUID)
            rv, _, Cont_ID = FindExactStringInTable(Trk[TrkID].Container_Id , FxGUID)
    end



    return Cont_ID
end
local Cont_ID = GetAll_Container_Data()

local Accent_Clr = Container_Accent_Clr or CustomColorsDefault.Container_Accent_Clr
local function SaveAll_Container_IDs ()
    for i , v in ipairs(Trk[TrkID].Container_Id) do 
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID slot '..i , #Trk[TrkID].Container_Id , true )
    end 
end 



local function SetTypeToEnv(type, i)
    if type  ~= 'env' then
        if im.Selectable(ctx, 'Set Type to Envelope', false) then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. i .. 'Type', 'env', true)
            r.gmem_write(4, 4) -- tells jsfx macro type = env
            r.gmem_write(5, i) -- tells jsfx which macro
            r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other
            return true 
        end
    end
end

local function SetTypeToStepSEQ(type, i , mc)
    if type  ~= 'Step' then 
        if im.Selectable(ctx, 'Step Sequencer', false) then
            r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other

            r.gmem_write(4, 6)   -- tells jsfx macro type = step seq
            r.gmem_write(5, i)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. i .. 'Type', 'Step', true)

            --[[ Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
            Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
            mc.SeqL = mc.SeqL or SEQ_Default_Num_of_Steps ]]
            mc.Dnom = mc.Dnom or SEQ_Default_Denom

            --[[ r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length', mc.SeqL or SEQ_Default_Num_of_Steps, true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator', mc.Dnom or SEQ_Default_Denom, true) ]]

            --if I.Name == 'Env ' .. i or I.Name == 'Macro ' .. i then I.Name = 'Step ' .. i end
            return true 
        end
    end
end

local function SetTypeToFollower(type,i)
    if type  ~= 'Follower' then 
        if im.Selectable(ctx, 'Audio Follower', false) then
            r.gmem_write(2,  fx.DIY_FxGUID)
            r.gmem_write(4, 9) -- tells jsfx macro type = Follower
    
            r.gmem_write(5, i) -- tells jsfx which macro
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. i .. 'Type', 'Follower', true)
            return true
        end
        
    end
end
local function SetTypeToMacro(type,i)
    if type  == 'Macro' then  return end 
    if im.Selectable(ctx, 'Macro', false) then

        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. i .. 'Type', 'Macro', true)
        r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other

        r.gmem_write(4, 5) -- tells jsfx macro type = Macro
        r.gmem_write(5, i) -- tells jsfx which macro
        return  true 
    end
end
local function SetTypeToLFO(type,i)

    if type == "LFO" then return end 
    if im.Selectable(ctx, 'LFO', false) then

        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. i .. 'Type', 'LFO', true)
        r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other

        r.gmem_write(4, 12) -- tells jsfx macro type = LFO
        r.gmem_write(5, i)  -- tells jsfx which macro

        Cont_ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed',fx, i,FxGUID)
       -- CONT_Send_All_Coord(I)
        return true 
    end
end
local function Set_Midi_Output_To_Bus1() --sets to 'Merge Container Bus1 to parent bus 1'
    local rv, CHUNK = r.GetTrackStateChunk(LT_Track, "", false)
    local FXStateChunk, int = ultraschall.GetFXStateChunk(CHUNK,FX_Idx)
    local tb =  Put_Long_String_Into_Table(FXStateChunk)
    tb[7] = number_Replacement_for_Containers(tb[7], 2, 2, 2 , 64)
    local tb = table.concat(tb, '\n')

    if  ultraschall.IsValidFXStateChunk(tb) then 
        local rv,  alteredStateChunk = ultraschall.SetFXStateChunk(CHUNK, tb )
        r.SetTrackStateChunk( LT_Track, alteredStateChunk, false )
    end
end

local function Modulation_Icon(LT_Track, slot)
    im.PushStyleColor ( ctx, im.Col_Button, 0x000000000)
    local clr = 0xD3D3D399
    if fx.MacroPageActive then clr = Accent_Clr end 
    if im.ImageButton(ctx, '##', Img.ModIconHollow, ModIconSz , ModIconSz*0.46, nil, nil, nil, nil, 0x00000000, clr) then 
        fx.MacroPageActive = toggle (fx.MacroPageActive)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID of '..FxGUID..'Macro Active' , tostring(fx.MacroPageActive), true )

        Trk[TrkID].Container_Id = Trk[TrkID].Container_Id or {}

        
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID of '..FxGUID , #Trk[TrkID].Container_Id , true )
        if not slot then slot  = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1)end 
        local _, FirstFX = r.TrackFX_GetFXName(LT_Track, slot)
        

        if not string.find(FirstFX, 'FXD Containr Macro') then 

            r.gmem_attach('ContainerMacro')
            r.gmem_write(0, Cont_ID )
            r.gmem_write(1, fx.DIY_FxGUID)

            --- !!! gmem has to be sent before inserting jsfx , for the right gmem to be read in the @init section
            local hide = AddMacroJSFX('JS: FXD Container Macros', slot)


            if hide then

                local pos  = r.TrackFX_AddByName(LT_Track, 'JS: FXD Container Macros', 0, 0 --[[to query the pos]])
                TREE = BuildFXTree(LT_Track)
                local id = FX_Idx +1
                if TREE[id] and  TREE[id].children then 
                    r.TrackFX_Show(LT_Track, TREE[id].children[1].addr_fxid , 2)
                end
            end 
            
        end 


        fx.ModSlots = fx.ModSlots or 4  
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container Active Mod Slots '..FxGUID , fx.ModSlots  , true )
        Set_Midi_Output_To_Bus1()


    end 
    im.PopStyleColor(ctx)
end

local function titleBar()


    if not fx.Collapse then

        SyncWetValues(FX_Idx)
        local x, y = im.GetCursorPos(ctx)

        im.SetCursorPos(ctx, 3, 165)

        Modulation_Icon(LT_Track, fx.LowestID)

        im.SetCursorPos(ctx, 3, 135)
        SyncWetValues(FX_Idx)
        

        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 1, 0, 1, FX_Idx)
        

        im.SetCursorPos(ctx,33,0)
        local FDL = im.GetForegroundDrawList(ctx)
    end
end
function Cont_DrawShape(Node, L, W, H, T, Clr, thick, SaveAllCoord )
    if Node then
        local All_Coord = { X = {}; Y = {}}
        
        for i, v in ipairs(Node) do
            local W, H = W or w, H or h
            

            local N = Node
            local L = L or HdrPosL
            local h = LFO.DummyH
            local lastX = N[math.max(i - 1, 1)].x * W + L
            local lastY = T + H - (-N[math.max(i - 1, 1)].y + 1) * H

            local x = N[i].x * W + L
            local y = T + H - (-N[math.min(i, #Node)].y + 1) * H

            local CtrlX = (N[i].ctrlX or ((N[math.max(i - 1, 1)].x + N[i].x) / 2)) * W + L
            local CtrlY = T + H - (-(N[i].ctrlY or ((N[math.max(i - 1, 1)].y + N[i].y) / 2)) + 1) * H

            local PtsX, PtsY = Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, x, y)

            --[[ for i, v in ipairs(PtsX) do
                PtsX[i] = L+( L - PtsX[i]) * 0.9
            end ]]

            for i, v in ipairs(PtsX) do

                if i > 1 then -- >1 because you need two points to draw a line
                    
                    im.DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
                        Clr or EightColors.LFO[Macro], thick)
                end
            end

            if SaveAllCoord == 'SaveAllCoord' then 

                for i, v in ipairs(PtsX) do 

                    local NormX = (PtsX[i] - L) / W
                    local NormY = (T+H - PtsY[i]) / (H) -- i think 3 is the window padding
                    table.insert(All_Coord.X, NormX or 0)
                    table.insert(All_Coord.Y, NormY or 0)
                end

            end 
        end
        
        return All_Coord
    end
end
function Global_Shapes()
    if im.IsWindowAppearing(ctx) then
        LFO.NodeBeforePreview = Mc.Node
    end

    Shapes = {}



    local F = scandir(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes'))

    for i, v in ipairs(F) do
        local Shape = Get_LFO_Shape_From_File(v)
        if Shape then

            Shape.Name = tostring(v):sub(0, -5)
            table.insert(Shapes, Shape)
        end
    end


    if LFO.DeleteShape then
        os.remove(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes',
            Shapes[LFO.DeleteShape].Name .. '.ini'))
        table.remove(Shapes, LFO.DeleteShape)
        LFO.DeleteShape = nil
    end

    if ShapeFilter and  im.TextFilter_Draw(ShapeFilter, ctx, '##PrmFilterTxt', -1) then
        Shape_Filter_Txt = im.TextFilter_Get(ShapeFilter)
        im.TextFilter_Set(ShapeFilter, Shape_Filter_Txt)
    end

    AnyShapeHovered = DrawShapesInSelector(Shapes)

    if im.IsWindowFocused(ctx) and im.IsKeyPressed(ctx, im.Key_Escape) then
        im.CloseCurrentPopup(ctx)
        LFO.OpenShapeSelect = nil
    end
end

local function Cont_open_LFO_Win(Track, Macro, x , y , mc )
    local HdrPosL = x 
    local tweaking

    -- im.SetNextWindowSize(ctx, LFO.Win.w +20 , LFO.Win.h + 50)
    im.SetNextWindowPos(ctx, HdrPosL, y - 385)
    if im.Begin(ctx, 'Container LFO Shape Edit Window' .. Macro..FxGUID, true, im.WindowFlags_NoDecoration + im.WindowFlags_AlwaysAutoResize) then
        local Mc = mc
        mc.Node = mc.Node or { { x = 0, y = 0 }, { x = 1, y = 1 } } -- create two default tables for first and last point
        r.gmem_attach('ContainerMacro')
        local Nodes = mc.Node
        local function ConverCtrlNodeY(lastY, Y)
            local Range = (math.max(lastY, Y) - math.min(lastY, Y))
            local NormV = (math.min(lastY, Y) + Range - Y) / Range
            local Bipolar = -1 + (NormV) * 2
            return NormV
        end
        function CONT_Send_All_Coord(m)

            local M = m or Macro
            local All_Coord =  All_Coord or mc.All_Coord
            for i, v in ipairs(All_Coord.X) do

                r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other

                r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                r.gmem_write(5, M)
                r.gmem_write(6, #Mc.Node * 11)

                r.gmem_write(1000 + i, v)
                r.gmem_write(2000 + i, All_Coord.Y[i])
            end
        end
        local i = Macro
        local function ChangeLFO(mode, V, gmem, StrName)
            r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other

            r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
            r.gmem_write(5, i)    -- Tells jsfx which macro
            r.gmem_write(gmem or 9, V)

            if StrName then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID.. 'Mod '.. Macro .. StrName, V, true)
                
            end
        end
        

        --Mc.Node = Mc.Node or { x = {} , ctrlX = {}, y = {}  , ctrlY = {}}
        --[[ if not Node[i].x then
            table.insert(Node.x, L)
            table.insert(Node.x, L + 400)
            table.insert(Node.y, T + h / 2)
            table.insert(Node.y, T + h / 2)
        end ]]
        local BtnSz = 11

        LFO.Pin = PinIcon(LFO.Pin, TrkID .. 'Macro = ' .. Macro, BtnSz, 'LFO window pin' .. Macro,
            0x00000000, ClrTint)
        SL()

        --local rv = im.ImageButton(ctx, '## copy' .. Macro, Img.Copy, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint)
        local WDL = im.GetWindowDrawList(ctx)
        local rv = im.Button(ctx, '## copy', 17, 17)
        DrawListButton(WDL, "0", 0x00000000, false, true, icon1_middle, false)
        TooltipUI("Copy LFO", im.HoveredFlags_Stationary)
        if rv then
            LFO.Clipboard = Mc.Node
        end

        SL()
        if not LFO.Clipboard then im.BeginDisabled(ctx) end
        --local rv = im.ImageButton(ctx, '## paste' .. Macro, Img.Paste, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint)
        local rv = im.Button(ctx, '## paste', 17, 17)
        DrawListButton(WDL, "1", 0x00000000, false, true, icon1_middle, false)
        TooltipUI("Paste LFO", im.HoveredFlags_Stationary)
        if rv then
            for i, v in ipairs(LFO.Clipboard) do
                Mc.Node[i] = Mc.Node[i] or {}
                Mc.Node[i].x = v.x
                Mc.Node[i].y = v.y
            end
        end
        if not LFO.Clipboard then im.EndDisabled(ctx) end

        SL()
        im.SetNextItemWidth(ctx, 100)
        if im.BeginCombo(ctx, '## Env_Or_Loop' .. Macro, Mc.LFO_Env_or_Loop or 'Loop') then
            if im.Selectable(ctx, 'Loop', p_1selected, flagsIn, size_wIn, size_hIn) then
                Mc.LFO_Env_or_Loop = 'Loop'
                ChangeLFO(18, 0, nil, 'LFO_Env_or_Loop') -- value is 0 because loop is default
            end
            if im.Selectable(ctx, 'Envelope (MIDI)', p_2selected, flagsIn, size_wIn, size_hIn) then
                Mc.LFO_Env_or_Loop = 'Envelope'
                ChangeLFO(18, 1, nil, 'LFO_Env_or_Loop') -- 1 for envelope
            end
            tweaking = Macro
            im.EndCombo(ctx)
        end

        if Mc.LFO_Env_or_Loop == 'Envelope' then
            SL()
            im.SetNextItemWidth(ctx, 120)
            local ShownName
            if Mc.Rel_Type == 'Custom Release - No Jump' then ShownName = 'Custom No Jump' end
            if im.BeginCombo(ctx, '## ReleaseType' .. Macro, ShownName or Mc.Rel_Type or 'Latch') then
                tweaking = Macro
                if im.Selectable(ctx, 'Latch', p_1selected, flagsIn, size_wIn, size_hIn) then
                    Mc.Rel_Type = 'Latch'
                    ChangeLFO(19, 0, nil, 'LFO_Release_Type') -- 1 for latch
                end
                QuestionHelpHint('Latch on to whichever value its at when midi key is released ')
                --[[ if im.Selectable( ctx, 'Simple Release',  p_1selected,   flagsIn,   size_wIn,   size_hIn) then
                    Mc.Rel_Type = 'Simple Release'
                    ChangeLFO(19, 1 , nil, 'LFO_Release_Type') -- 1 for Simple release
                end   ]]
                if im.Selectable(ctx, 'Custom Release', p_1selected, flagsIn, size_wIn, size_hIn) then
                    Mc.Rel_Type = 'Custom Release'
                    ChangeLFO(19, 2, nil, 'LFO_Release_Type') -- 2 for Custom release
                end
                QuestionHelpHint('Jump to release node when midi note is released')

                if im.Selectable(ctx, 'Custom Release - No Jump', p_1selected, flagsIn, size_wIn, size_hIn) then
                    Mc.Rel_Type = 'Custom Release - No Jump'
                    ChangeLFO(19, 3, nil, 'LFO_Release_Type') -- 3 for Custom release no jump
                end
                QuestionHelpHint(
                    'Custom release, but will prevent values jumping by scaling the part after the release node to fit value when midi key was released')

                if im.Checkbox(ctx, 'Legato', Mc.LFO_Legato) then
                    Mc.LFO_Legato = toggle(Mc.LFO_Legato)
                    ChangeLFO(21, 1, nil, 'LFO_Legato')
                end

                im.EndCombo(ctx)
            end
        end


        SL(nil, 30)
        local rv = im.ImageButton(ctx, '## save' .. Macro, Img.Save, BtnSz, BtnSz, nil, nil, nil, nil,
            ClrBG,ClrTint)
        TooltipUI("Save LFO shape as preset", im.HoveredFlags_Stationary)
        if rv then
            LFO.OpenSaveDialog = Macro..FxGUID
        end

        Save_LFO_Dialog(Macro, x, y , mc, FxGUID)
        SL()
        local rv = im.ImageButton(ctx, '## shape Preset' .. Macro, Img.Sine, BtnSz * 2, BtnSz, nil,
            nil, nil, nil, 0xffffff00, ClrTint)
        TooltipUI("Open Shape preset window", im.HoveredFlags_Stationary)
        if rv then
            if LFO.OpenShapeSelect then LFO.OpenShapeSelect = nil else LFO.OpenShapeSelect = Macro end
        end
        if LFO.OpenShapeSelect then Highlight_Itm(WDL, 0xffffff55) end

        local X_range = (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4)
        LFO.DummyH = LFO.Win.h + 20
        im.Dummy(ctx, (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4), LFO.DummyH)
        local NodeSz = 15
        local w, h = im.GetItemRectSize(ctx)
        LFO.Def.DummyW = (LFO.Win.w) * (LFO.Def.Len / 4)
        LFO.DummyW = w
        local L, T = im.GetItemRectMin(ctx)
        local Win_T, Win_B = T, T + h -- 7 is prob the window padding
        local Win_L = L
        im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff22)
        SL()
        im.Dummy(ctx, 10, 10)


        LFO.Win.L, LFO.Win.R = L, L + X_range
        local LineClr, CtClr = 0xffffff99, 0xffffff44

        local Node = Mc.Node


        local function GetNormV(i)
            local NormX = (Node[i].x - HdrPosL) / LFO.Win.w
            local NormY = (Win_B - Node[i].y) / h -- i think 3 is the window padding
            return NormX, NormY
        end
        local function SaveLFO(StrName, V)
            if StrName then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID.. 'Mod ' .. Macro .. StrName, V, true)
            end
        end
        local function Save_All_LFO_Info(Node)
            for i, v in ipairs(Node) do
                if v.ctrlX then
                    SaveLFO('Node' .. i .. 'Ctrl X', Node[i].ctrlX)
                    SaveLFO('Node' .. i .. 'Ctrl Y', Node[i].ctrlY)
                end

                SaveLFO('Node ' .. i .. ' X', Node[i].x)
                SaveLFO('Node ' .. i .. ' Y', Node[i].y)
                SaveLFO('Total Number of Nodes', #Node)
            end
        end

        local Mc = mc

        mc.NodeNeedConvert = mc.NodeNeedConvert or nil

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
            local x = (x - L) / LFO.DummyW
            local y = (y - T) / LFO.DummyH


            for i = 1, #Node, 1 do

                if i ~= #Node then
                    if Node[i].x < x and Node[i + 1].x > x then InsertPos = i + 1 end
                elseif not InsertPos then
                    if Node[1].x > x then
                        InsertPos = 1 -- if it's before the first node
                        --[[ table.insert(Node.ctrlX, InsertPos, HdrPosL + (x-HdrPosL)/2)
                        table.insert(Node.ctrlY, InsertPos, y) ]]
                    elseif Node[i].x < x then
                        InsertPos = i + 1
                    elseif Node[i].x > x then
                        InsertPos = i
                    end
                end
            end

            table.insert(Node, InsertPos, {
                x = SetMinMax(x, 0, 1),
                y = SetMinMax(y, 0, 1),
            })

            Save_All_LFO_Info(Node)
        end


        local function AddNode(x, y, ID)
            local w, h = 15, 15
            InvisiBtn(ctx, x, y, '##Node' .. ID, 15)
            local Hvred
            local w, h = im.GetItemRectSize(ctx)
            local L, T = im.GetItemRectMin(ctx)

            local function ClampCtrlNode(ID)
                Node[ID] = Node[ID] or {}

                if Node[ID].ctrlX then
                    local lastX = Node[ID - 1].x or 0
                    local lastY, Y = Node[ID - 1].y or Node[ID].y, Node[ID].y


                    -- Segment Before the tweaking point
                    if Node[ID].ctrlX and Node[ID].ctrlY then
                        Node[ID].ctrlX = SetMinMax(Node[ID].ctrlX, lastX, Node[ID].x)
                        Node[ID].ctrlY = SetMinMax(Node[ID].ctrlY, math.min(lastY, Y),
                            math.max(lastY, Y))

                        SaveLFO('Node' .. ID .. 'Ctrl X', Node[ID].ctrlX)
                        SaveLFO('Node' .. ID .. 'Ctrl Y', Node[ID].ctrlY)
                    end
                end
            end
            function findRelNode()
                for i, v in ipairs(Mc.Node) do
                    if v.Rel == true then return i end
                end
            end

            if (Mc.Rel_Type or ''):find('Custom Release') then
                if not findRelNode() then
                    Node[#Mc.Node].Rel = true
                    ChangeLFO(20, #Mc.Node, nil, 'LFO_Rel_Node')
                end

                if im.IsItemClicked(ctx, 1) and Mods == Alt then
                    Mc.Node[findRelNode() or 1].Rel = nil
                    Mc.Node[ID].Rel = true
                    ChangeLFO(20, ID, nil, 'LFO_Rel_Node')
                end
                if Mc.Node[ID].Rel then
                    local L = L + NodeSz / 2
                    im.DrawList_AddCircle(WDL, L, T + NodeSz / 2, 6, 0xffffffaa)
                    im.DrawList_AddLine(WDL, L, Win_T, L, Win_B, 0xffffff55, 3)
                    im.DrawList_AddText(WDL, math.min(L, Win_L + LFO.DummyW - 50), Win_T,
                        0xffffffaa, 'Release')
                end
            end



            if im.IsItemHovered(ctx) then
                LineClr, CtClr = 0xffffffbb, 0xffffff88
                HoverNode = ID
                Hvred = true
            end

            if MouseClosestNode == ID and im.IsKeyPressed(ctx, im.Key_X, false) then
                DraggingNode = ID
                tweaking = Macro
            elseif im.IsKeyReleased(ctx, im.Key_X) then
                DraggingNode = nil
            end

            -- if moving node
            if (im.IsItemActive(ctx) and Mods == 0) or DraggingNode == ID then
                tweaking = Macro
                HideCursorTillMouseUp(nil, im.Key_X)
                HideCursorTillMouseUp(0)
                HoverNode = ID
                CONT_Send_All_Coord()

                local lastX = Node[math.max(ID - 1, 1)].x
                local nextX = Node[math.min(ID + 1, #Node)].x
                if ID == 1 then lastX = 0 end
                if ID == #Node then nextX = 1 end

                local MsX, MsY = GetMouseDelta(0, im.Key_X)
                local MsX = MsX / LFO.DummyW
                local MsY = MsY / LFO.DummyH


                Node[ID].x = SetMinMax(Node[ID].x + MsX, lastX, nextX)
                Node[ID].y = SetMinMax(Node[ID].y + MsY, 0, 1)


                if ID == 1 then
                    ClampCtrlNode(ID - 1)
                end

                ClampCtrlNode(ID)
                ClampCtrlNode(math.min(ID + 1, #Node))


                --[[ ChangeLFO(13, NormX, 9, 'Node '..ID..' X')
                ChangeLFO(13, NormY, 10, 'Node '..ID..' Y')
                ChangeLFO(13, ID, 11)   -- tells jsfx which node user is adjusting
                ChangeLFO(13, #Node.x, 12, 'Total Number of Nodes' ) ]]
                local NormX, NormY = GetNormV(ID)

                SaveLFO('Node ' .. ID .. ' X', Node[ID].x)
                SaveLFO('Node ' .. ID .. ' Y', Node[ID].y)
                SaveLFO('Total Number of Nodes', #Node)


                if ID ~= #Node then
                    local this, next = Node[ID].x, Node[ID + 1].x or 1
                    Node[ID + 1].ctrlX = SetMinMax(Node[ID + 1].ctrlX or (this + next) / 2, this,
                        next)
                    if Node[ID + 1].ctrlX == (this + next) / 2 then Node[ID + 1].ctrlX = nil end
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
        if im.IsKeyReleased(ctx, im.Key_C) or LBtnRel then
            DraggingLFOctrl = nil
            Save_All_LFO_Info(Node)
        end

        All_Coord = { X = {}, Y = {} }

        if LFO.DeleteNode then
            table.remove(Mc.Node, LFO.DeleteNode)
            Mc.NeedSendAllCoord = true
            Save_All_LFO_Info(Node)
            LFO.DeleteNode = nil
        end
        

        local PlayPosX = HdrPosL + r.gmem_read(108 + Macro) / 4 * LFO.Win.w

        for i = 1, #Mc.Node, 1 do --- Rpt for every node
            local last = math.max(i - 1, 1)
            local lastX, lastY = L + (Node[last].x or 0) * LFO.DummyW,
                T + (Node[last].y or Node[i].y) * LFO.DummyH
            local X, Y = L + Node[i].x * LFO.DummyW, T + Node[i].y * LFO.DummyH
           



            if AddNode(X - 15 / 2, Y - 15 / 2, i) then AnyNodeHovered = true end
            local CtrlX, CtrlY = L + (Node[i].ctrlX or (Node[last].x + Node[i].x) / 2) * LFO.DummyW,
                T + (Node[i].ctrlY or (Node[last].y + Node[i].y) / 2) * LFO.DummyH


            -- Control Node
            if (im.IsMouseHoveringRect(ctx, lastX, Win_T, X, Win_B) or DraggingLFOctrl == i) then
                local Sz = LFO.CtrlNodeSz

                ---- Draw Node
                if not DraggingLFOctrl or DraggingLFOctrl == i then
                    if not HoverNode and not DraggingNode then
                        im.DrawList_AddBezierQuadratic(WDL, lastX, lastY, CtrlX, CtrlY, X, Y,
                            0xffffff44, 7)
                        im.DrawList_AddCircle(WDL, CtrlX, CtrlY, Sz, LineClr)
                        --im.DrawList_AddText(FDL, CtrlX, CtrlY, 0xffffffff, i)
                    end
                end

                InvisiBtn(ctx, CtrlX - Sz / 2, CtrlY - Sz / 2, '##Ctrl Node' .. i, Sz)
                if im.IsKeyPressed(ctx, im.Key_C, false) or im.IsItemActivated(ctx) then
                    DraggingLFOctrl = i
                end

                if im.IsItemHovered(ctx) then
                    im.DrawList_AddCircle(WDL, CtrlX, CtrlY, Sz + 2, LineClr)
                end
            end

            -- decide which node is mouse closest to
            local Range = X - lastX
            if im.IsMouseHoveringRect(ctx, lastX, Win_T, lastX + Range / 2, Win_B) and not tweaking and not DraggingNode then
                im.DrawList_AddCircle(WDL, lastX, lastY, LFO.NodeSz + 2, LineClr)
                MouseClosestNode = last
            elseif im.IsMouseHoveringRect(ctx, lastX + Range / 2, Win_T, X, Win_B) and not tweaking and not DraggingNode then
                im.DrawList_AddCircle(WDL, X, Y, LFO.NodeSz + 2, LineClr)

                MouseClosestNode = i
            end

            --- changing control point
            if DraggingLFOctrl == i then
                tweaking           = Macro
                local Dx, Dy       = GetMouseDelta(0, im.Key_C)
                local Dx, Dy       = Dx / LFO.DummyW, Dy / LFO.DummyH
                local CtrlX, CtrlY = Node[i].ctrlX or (Node[last].x + Node[i].x) / 2,
                    Node[i].ctrlY or (Node[last].y + Node[i].y) / 2

                Node[i].ctrlX      = SetMinMax(CtrlX + Dx, Node[last].x, Node[i].x)
                Node[i].ctrlY      = SetMinMax(CtrlY + Dy, math.min(Node[last].y, Node[i].y),
                    math.max(Node[last].y, Node[i].y))

                SaveLFO('Node' .. i .. 'Ctrl X', Node[i].ctrlX)
                SaveLFO('Node' .. i .. 'Ctrl Y', Node[i].ctrlY)
                CONT_Send_All_Coord()
            end





            if (Mc.LFO_Gain or 1) ~= 1 then
                local B = T + LFO.DummyH
                local y = -Node[i].y + 1
                local Y = B - y * LFO.DummyH * Mc.LFO_Gain
                local lastY = B - (-(Node[last].y or Node[i].y) + 1) * LFO.DummyH * Mc.LFO_Gain
                local CtrlY = B -
                    (-(Node[i].ctrlY or (Node[last].y + Node[i].y) / 2) + 1) * LFO.DummyH *
                    Mc.LFO_Gain
                local PtsX = {}
                local PtsY = {}
                local PtsX, PtsY = Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, X, Y)

                for i = 1, #PtsX, 2 do
                    if i > 1 then -- >1 because you need two points to draw a line
                        im.DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
                            0xffffffff)
                    end
                end
            end

            PtsX = {}
            PtsY = {}

            PtsX, PtsY = Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, X, Y)

            if Wheel_V ~= 0 then Sqr = (Sqr or 0) + Wheel_V / 100 end


            --im.DrawList_AddLine(FDL, p.x, p.y, 0xffffffff)



            local N = i
            local CurrentPlayPos
            for i, v in ipairs(PtsX) do
                if i > 1 then -- >1 because you need two points to draw a line
                    local n = math.min(i + 1, #PtsX)

                    if PlayPosX > PtsX[i - 1] and PlayPosX < PtsX[i] then
                        CurrentPlayPos = i
                    end
                    im.DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
                        0xffffffff)
                end
                ----- things below don't need >1 because jsfx needs all points to draw lines



                --- normalize values
                local NormX = (PtsX[i] - HdrPosL) / LFO.Win.w
                local NormY = (Win_B - PtsY[i]) / (LFO.DummyH) -- i think 3 is the window padding



                --[[ r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                r.gmem_write(5, Macro) ]]
                --[[
                r.gmem_write(1000+i*N, NormX) -- gmem 1000 ~ 1999 = X coordinates
                r.gmem_write(2000+i*N, NormY) -- gmem 2000 ~ 2999 = Y coordinates ]]
                table.insert(All_Coord.X, NormX or 0)
                table.insert(All_Coord.Y, NormY or 0)
            end

            

            if CurrentPlayPos and (Mc.LFO_spd or 1) >= 2 then
                for i = 1, CurrentPlayPos, 1 do
                    local pos = CurrentPlayPos - 1
                    local L = math.max(pos - i, 1)
                    --if PtsX[pos] > PtsX[i] -30  then  -- if playhead is 60 pixels right to current point
                    im.DrawList_AddLine(FDL, PtsX[L + 1], PtsY[L + 1], PtsX[L], PtsY[L],
                        0xffffff88, 7 - 7 * (i * 0.1))
                    -- end
                    --im.DrawList_AddText(FDL, PtsX[i] ,PtsY[i], 0xffffffff, i)


                    -- calculate how far X and last x
                    local Ly, Lx

                    testTB = {}

                    for i = 0, (PlayPosX - PtsX[pos]), (PlayPosX - PtsX[pos]) / 4 do
                        local n = math.min(pos + 1, #PtsX)
                        local x2 = PtsX[pos] + i
                        local y2 = PtsY[pos] +
                            (PtsY[CurrentPlayPos] - PtsY[pos]) * (i / (PtsX[n] - PtsX[pos]))

                        im.DrawList_AddLine(FDL, Lx or x2, Ly or y2, x2, y2,
                            Change_Clr_A(0xffffff00, (i / (PlayPosX - PtsX[pos])) * 0.3), 7)
                        Ly = y2
                        Lx = x2

                        table.insert(testTB, (i / (PlayPosX - PtsX[pos])))
                    end
                end
            end



            r.gmem_write(6, #Node * 11)

            --im.DrawList_AddBezierQuadratic(FDL, lastX, lastY, CtrlX, CtrlY, v, Y, 0xffffffff, 3)
        end
        local MOD  = math.abs(SetMinMax((r.gmem_read(100 + Macro) or 0) / 127, -1, 1))

        if (Mc.LFO_spd or 1) < 2 then
            DrawLFOvalueTrail(Mc, PlayPosX, Win_B - MOD * LFO.DummyH, Macro)
        end


        for i, v in ipairs(All_Coord.X) do
            r.gmem_write(1000 + i, v)
            r.gmem_write(2000 + i, All_Coord.Y[i])
        end


        if DraggingLFOctrl then
            HideCursorTillMouseUp(nil, im.Key_C)
            HideCursorTillMouseUp(0)
        end


        if not AnyNodeHovered then HoverNode = nil end


        --im.DrawList_PathStroke(FDL, 0xffffffff, nil, 2)

        --- Draw Playhead

        im.DrawList_AddLine(WDL, PlayPosX, Win_T, PlayPosX, Win_B, 0xffffff99, 4)
        im.DrawList_AddCircleFilled(WDL, PlayPosX, Win_B - MOD * LFO.DummyH, 5, 0xffffffcc)

        --- Draw animated Trail for modulated value
        --[[ Mc.LFO_Trail = Mc.LFO_Trail or {}
        table.insert(Mc.LFO_Trail , Win_B - MOD * LFO.DummyH)
        if # Mc.LFO_Trail > 100 then table.remove(Mc.LFO_Trail, 1) end
        for i, v in ipairs( Mc.LFO_Trail) do

        end ]]


        if Mc.NeedSendAllCoord then
            CONT_Send_All_Coord()

            Mc.NeedSendAllCoord = nil
        end

        -- Draw Grid

        local function DrawGridLine_V(division)
            local Pad_L = 5
            for i = 0, division, 1 do
                local W = (X_range / division)
                local R = HdrPosL + X_range
                local X = Pad_L + HdrPosL + W * i
                im.DrawList_AddLine(WDL, X, Win_T, X, Win_B, 0xffffff55, 2)
            end
        end
        DrawGridLine_V(Mc.LFO_leng or LFO.Def.Len)


        im.SetCursorPos(ctx, 10, LFO.Win.h + 55)
        im.AlignTextToFramePadding(ctx)
        im.Text(ctx, 'Speed:')
        SL()
        im.SetNextItemWidth(ctx, 50)

        local rv, V = im.DragDouble(ctx, '##Speed', mc.LFO_spd or 1, 0.05, 0.125, 128, 'x %.3f')
        if im.IsItemActive(ctx) then
            ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed')
            tweaking = Macro
            Mc.LFO_spd = V
        end
        if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
            im.OpenPopup(ctx, '##LFO Speed menu' .. Macro)
        end
        if im.BeginPopup(ctx, '##LFO Speed menu' .. Macro) then
            tweaking = Macro
            if im.Selectable(ctx, 'Add Parameter to Envelope', false) then
                AutomateModPrm(Macro, 'LFO Speed', 17, 'LFO ' .. Macro .. ' Speed')
                r.TrackList_AdjustWindows(false)
                r.UpdateArrange()
            end

            im.EndPopup(ctx)
        end
        if Mods == Alt and im.IsItemActivated(ctx) then Mc.LFO_spd = 1 end
        if im.IsItemHovered(ctx) then
            if im.IsKeyPressed(ctx, im.Key_DownArrow, false) then
                Mc.LFO_spd = (Mc.LFO_spd or 1) / 2
                ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed')
            elseif im.IsKeyPressed(ctx, im.Key_UpArrow, false) then
                Mc.LFO_spd = (Mc.LFO_spd or 1) * 2
                ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed')
            end
        end
        SL(nil, 30)


        ---- Add Length slider
        im.Text(ctx, 'Length:')
        SL()
        im.SetNextItemWidth(ctx, 80)
        local LengthBefore = Mc.LFO_leng

        rv, Mc.LFO_leng = im.SliderInt(ctx, '##' .. 'Macro' .. i .. 'LFO Length',
            Mc.LFO_leng or LFO.Def.Len, 1, 8)
        if im.IsItemActive(ctx) then
            tweaking = Macro
            ChangeLFO(13, Mc.LFO_leng or LFO.Def.Len, 9, 'LFO Length')
        end
        if im.IsItemEdited(ctx) then
            local Change = Mc.LFO_leng - LengthBefore

            for i, v in ipairs(Node) do
                Node[i].x = Node[i].x / ((LengthBefore + Change) / LengthBefore)
                if Node[i].ctrlX then
                    Node[i].ctrlX = Node[i].ctrlX / ((LengthBefore + Change) / LengthBefore)
                end
            end
            LengthBefore = Mc.LFO_leng
        end


        ------ Add LFO Gain
        SL()
        im.Text(ctx, 'Gain')
        SL()
        im.SetNextItemWidth(ctx, 80)
        local ShownV = math.floor((Mc.LFO_Gain or 0) * 100)

        -- check if prm has been assigned automation
        local AutoPrmIdx = tablefind(Trk[TrkID].AutoPrms, 'Mod' .. Macro .. 'LFO Gain')


        rv, Mc.LFO_Gain = im.DragDouble(ctx, '##' .. 'Macro' .. i .. 'LFO Gain',
            Mc.LFO_Gain or 1, 0.01, 0, 1, ShownV .. '%%')
        if im.IsItemActive(ctx) then
            tweaking = Macro
            ChangeLFO(14, Mc.LFO_Gain, 9, 'LFO Gain')
            if AutoPrmIdx then
                r.TrackFX_SetParamNormalized(LT_Track, 0, 15 + AutoPrmIdx, Mc.LFO_Gain)
            end
        else
            if AutoPrmIdx then
                Mc.LFO_Gain = r.TrackFX_GetParamNormalized(LT_Track, 0, 15 + AutoPrmIdx)
            end
        end
        if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
            im.OpenPopup(ctx, '##LFO Gain menu' .. Macro)
        end
        if im.BeginPopup(ctx, '##LFO Gain menu' .. Macro) then
            tweaking = Macro
            if im.Selectable(ctx, 'Add Parameter to Envelope', false) then
                AutomateModPrm(Macro, 'LFO Gain', 16, 'LFO ' .. Macro .. ' Gain')
                r.TrackList_AdjustWindows(false)
                r.UpdateArrange()
            end

            im.EndPopup(ctx)
        end



        if Mc.Changing_Rel_Node then
            Mc.Rel_Node = Mc.Changing_Rel_Node
            ChangeLFO(20, Mc.Rel_Node, nil, 'LFO_Rel_Node')
            Mc.Changing_Rel_Node = nil
        end

        

        --[[ 
        if im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
            LFO.WinHovered =
                Macro -- this one doesn't get cleared after unhovering, to inform script which one to stay open
            LFO.HvringWin = Macro
        else
            LFO.HvringWin = nil
            LFO.DontOpenNextFrame = true -- it's needed so the open_LFO_Win function doesn't get called twice when user 'unhover' the lfo window
        end ]]

        if im.IsWindowAppearing(ctx) then
            Save_All_LFO_Info(Node)
        end
        if im.IsWindowAppearing(ctx) then
            CONT_Send_All_Coord()
        end
        im.End(ctx)
    end


    if LFO.OpenShapeSelect == Macro then
        local L = HdrPosL local T = y
        im.SetNextWindowPos(ctx, L + LFO.DummyW + 30, T - LFO.DummyH - 200)
        if not im.ValidatePtr(ShapeFilter, "ImGui_TextFilter*") then
            ShapeFilter = im.CreateTextFilter(Shape_Filter_Txt)
        end
        im.SetNextWindowSizeConstraints(ctx, 220, 150, 240, 700)
        if im.Begin(ctx, 'Shape Selection Popup', true, im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then
            local W, H = 150, 75
             function DrawShapesInSelector(Shapes)
                local AnyShapeHovered
                local Mc = mc
                for i, v in pairs(Shapes) do
                    --InvisiBtn(ctx, nil,nil, 'Shape'..i,  W, H)

                    if im.TextFilter_PassFilter(ShapeFilter, v.Name) then
                        im.Text(ctx, v.Name or i)

                        --im.SetCursorPosX( ctx, - 15 )
                        local L, T = im.GetItemRectMin(ctx)
                        if im.IsMouseHoveringRect(ctx, L, T, L + 200, T + 10) then
                            SL(W - 8)

                            if TrashIcon(8, 'delete' .. (v.Name or i), 0xffffff00) then
                                im.OpenPopup(ctx, 'Delete shape prompt' .. i)
                                im.SetNextWindowPos(ctx, L, T)
                            end
                        end

                        if im.Button(ctx, '##' .. (v.Name or i) .. i, W, H) then
                            Mc.Node = v
                            LFO.NewShapeChosen = v
                        end
                        if im.IsItemHovered(ctx) then
                            Mc.Node = v
                            AnyShapeHovered = true
                            LFO.AnyShapeHovered = true
                            CONT_Send_All_Coord()
                        end
                        local L, T = im.GetItemRectMin(ctx)
                        local w, h = im.GetItemRectSize(ctx)
                        im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff33)
                        im.DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)

                        v.AllCoord = Cont_DrawShape(v, L, w, h, T, 0xffffffaa)
                    end
                    if im.BeginPopupModal(ctx, 'Delete shape prompt' .. i, true, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize|im.WindowFlags_AlwaysAutoResize) then
                        im.Text(ctx, 'Confirm deleting this shape:')
                        if im.Button(ctx, 'yes') or im.IsKeyPressed(ctx, im.Key_Y) or im.IsKeyPressed(ctx, im.Key_Enter) then
                            LFO.DeleteShape = i
                            im.CloseCurrentPopup(ctx)
                        end
                        SL()
                        if im.Button(ctx, 'No') or im.IsKeyPressed(ctx, im.Key_N) or im.IsKeyPressed(ctx, im.Key_Escape) then
                            im.CloseCurrentPopup(ctx)
                        end
                        im.EndPopup(ctx)
                    end
                end
                if LFO.AnyShapeHovered then     -- if any shape was hovered
                    if not AnyShapeHovered then -- if 'unhovered'
                        if LFO.NewShapeChosen then
                            local V = LFO.NewShapeChosen
                            Mc.Node = V                     ---keep newly selected shape
                        else
                            Mc.Node = LFO.NodeBeforePreview -- restore original shape
                            NeedSendAllGmemLater = Macro
                        end
                        LFO.NodeBeforePreview = Mc.Node
                        LFO.AnyShapeHovered = nil
                        LFO.NewShapeChosen = nil
                    end
                end


                return AnyShapeHovered
            end

            if NeedSendAllGmemLater == Macro then
                timer = (timer or 0) + 1
                if timer == 2 then
                    CONT_Send_All_Coord()
                    NeedSendAllGmemLater = nil
                    timer = nil
                end
            end

            


            local function Save_Shape_To_Track()
                local HowManySavedShapes = GetTrkSavedInfo('LFO Saved Shape Count')

                if HowManySavedShapes then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count',
                        (HowManySavedShapes or 0) + 1, true)
                else
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', 1, true)
                end
                local I = (HowManySavedShapes or 0) + 1
                for i, v in ipairs(Mc.Node) do
                    if i == 1 then
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: Shape' .. I .. 'LFO Node Count = ', #Mc.Node, true)
                    end
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I ..
                        'Node ' .. i .. 'x = ', v.x, true)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I ..
                        'Node ' .. i .. 'y = ', v.y, true)

                    r.GetSetMediaTrackInfo_String(LT_Track,
                        'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', v.ctrlX or '', true)
                    r.GetSetMediaTrackInfo_String(LT_Track,
                        'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', v.ctrlY or '', true)
                end
            end
            local function Save_Shape_To_Project()
                local HowManySavedShapes = getProjSavedInfo('LFO Saved Shape Count')

                r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count',
                    (HowManySavedShapes or 0) + 1)


                local I = (HowManySavedShapes or 0) + 1
                for i, v in ipairs(Mc.Node) do
                    if i == 1 then
                        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node Count = ',
                            #Mc.Node)
                    end
                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'x = ',
                        v.x)
                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'y = ',
                        v.y)

                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i ..
                        '.ctrlX = ', v.ctrlX or '')
                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i ..
                        '.ctrlY = ', v.ctrlY or '')
                end
            end

            local function Track_Shapes()
                local Shapes = {}
                local HowManySavedShapes = GetTrkSavedInfo('LFO Saved Shape Count')


                for I = 1, HowManySavedShapes or 0, 1 do
                    local Shape = {}
                    local Ct = GetTrkSavedInfo('Shape' .. I .. 'LFO Node Count = ')

                    for i = 1, Ct or 1, 1 do
                        Shape[i] = Shape[i] or {}
                        Shape[i].x = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'x = ')
                        Shape[i].y = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'y = ')
                        Shape[i].ctrlX = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlX = ')
                        Shape[i].ctrlY = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlY = ')
                    end
                    if Shape[1] then
                        table.insert(Shapes, Shape)
                    end
                end

                if LFO.DeleteShape then
                    local Count = GetTrkSavedInfo('LFO Saved Shape Count')
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', Count - 1,
                        true)
                    table.remove(Shapes, LFO.DeleteShape)

                    for I, V in ipairs(Shapes) do -- do for every shape
                        for i, v in ipairs(V) do  --- do for every node
                            if i == 1 then
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Shape' .. I .. 'LFO Node Count = ', #V, true)
                            end

                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: Shape' .. I .. 'Node ' .. i .. 'x = ', v.x or '', true)
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: Shape' .. I .. 'Node ' .. i .. 'y = ', v.y or '', true)

                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', v.ctrlX or '',
                                true)
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', v.ctrlY or '',
                                true)
                        end
                    end
                    LFO.DeleteShape = nil
                end

                DrawShapesInSelector(Shapes)
            end
            local function Proj_Shapes()
                local Shapes = {}
                local HowManySavedShapes = getProjSavedInfo('LFO Saved Shape Count')

                for I = 1, HowManySavedShapes or 0, 1 do
                    local Shape = {}
                    local Ct = getProjSavedInfo('LFO Shape' .. I .. 'Node Count = ')
                    for i = 1, Ct or 1, 1 do
                        Shape[i] = Shape[i] or {}
                        Shape[i].x = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'x = ')
                        Shape[i].y = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'y = ')
                        Shape[i].ctrlX = getProjSavedInfo('LFO Shape' .. I ..
                            'Node ' .. i .. '.ctrlX = ')
                        Shape[i].ctrlY = getProjSavedInfo('LFO Shape' .. I ..
                            'Node ' .. i .. '.ctrlY = ')
                    end
                    if Shape[1] then
                        table.insert(Shapes, Shape)
                    end
                end

                if LFO.DeleteShape then
                    local Count = getProjSavedInfo('LFO Saved Shape Count')
                    r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count', Count - 1)
                    table.remove(Shapes, LFO.DeleteShape)

                    for I, V in ipairs(Shapes) do -- do for every shape
                        for i, v in ipairs(V) do  --- do for every node
                            if i == 1 then
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I ..
                                    'Node Count = ', #V)
                            end

                            r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I ..
                                'Node ' .. i .. 'x = ', v.x or '')
                            r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I ..
                                'Node ' .. i .. 'y = ', v.y or '')

                            r.SetProjExtState(0, 'FX Devices',
                                'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', v.ctrlX or '')
                            r.SetProjExtState(0, 'FX Devices',
                                'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', v.ctrlY or '')
                        end
                    end
                    LFO.DeleteShape = nil
                end

                DrawShapesInSelector(Shapes)
            end

            if im.ImageButton(ctx, '## save' .. Macro, Img.Save, 12, 12, nil, nil, nil, nil, ClrBG, ClrTint) then
                if LFO.OpenedTab == 'Global' then
                    LFO.OpenSaveDialog = Macro
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
                    Global_Shapes()
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

            if im.IsWindowHovered(ctx, im.FocusedFlags_RootAndChildWindows) then
                LFO.HoveringShapeWin = Macro
            else
                LFO.HoveringShapeWin = nil
            end
            im.End(ctx)
        end
    end






    return tweaking, All_Coord
end

local function RC(str, type)
    if type == 'str' then
        return select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID .. str, '', false))
    else
        return tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID .. str, '', false)))
    end
end
local function recall_LFO_Data(mc,i)



        local m = mc

        m.LFO_NodeCt = RC('Mod ' .. i .. 'Total Number of Nodes')
        mc.LFO_spd = RC('Mod ' .. i .. 'LFO Speed')
        m.LFO_leng = RC('Mod ' .. i .. 'LFO Length')
        m.LFO_Env_or_Loop = RC('Mod ' .. i .. 'LFO_Env_or_Loop')
        m.Rel_Type = RC('Mod ' .. i .. 'LFO_Release_Type')
        if m.Rel_Type == 0 then
            m.Rel_Type = 'Latch'
        elseif m.Rel_Type == 1 then
            m.Rel_Type = 'Simple Release'
        elseif m.Rel_Type == 2 then
            m.Rel_Type = 'Custom Release'
        elseif m.Rel_Type == 3 then
            m.Rel_Type = 'Custom Release - No Jump'
        end

        for N = 1, (m.LFO_NodeCt or 0), 1 do
            m.Node = m.Node or {}
            m.Node[N] = m.Node[N] or {}
            m.Node[N].x = RC('Mod ' .. i .. 'Node ' .. N .. ' X')


            m.Node[N].y       = RC('Mod ' .. i .. 'Node ' .. N .. ' Y')
            m.Node[N].ctrlX   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl X')
        

            m.Node[N].ctrlY   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl Y')
            m.NodeNeedConvert = true
        end

end

local function LFO_Box(mc, i )
    if mc.Type =='LFO' then  
        if not mc.Node then 

            recall_LFO_Data(mc,i+1)

        end 
        local x , y = im.GetCursorScreenPos(ctx)
        local sz = LFO_Box_Size
        local x = x - 10
        im.DrawList_AddRectFilled(WDL,x, y, x+sz,y+sz , 0x00000055)
        im.DrawList_AddRect(WDL,x-1, y-1, x+sz +1 ,y+sz+1 , 0xffffff77)

        local clr = 0xffffffff
        if AssignContMacro == i and AssignContMacro_FxGuID == FxGUID then 
            if  RepeatAtInterval(0.3, nil) then
                clr = Accent_Clr
            end
        end
        mc.Node = mc.Node or { { x = 0, y = 1 }, { x = 1, y = 1 } } -- create two default tables for first and last point

        mc.All_Coord = Cont_DrawShape(mc.Node, x, sz, sz, y, clr , 1.5, 'SaveAllCoord')


        if IsLBtnClicked and im.IsItemHovered(ctx,im.HoveredFlags_RectOnly) and im.IsPopupOpen(ctx, 'Small Shape Select') then 
            --[[ im.CloseCurrentPopup(ctx)
            LFO.EditWinOpen = toggle (LFO.EditWinOpen)
            Open_Cont_LFO_Win = toggle(Open_Cont_LFO_Win , FxGUID)  ]]

        end 

        if  im.InvisibleButton(ctx, 'Cont LFO Btn'.. i.. FxGUID, sz,sz) then 
            Open_Cont_LFO_Win = toggle(Open_Cont_LFO_Win , FxGUID..i) 
            LFO.EditWinOpen = toggle (LFO.EditWinOpen)
        end 
       
        if im.IsItemHovered(ctx,im.HoveredFlags_RectOnly) and IsRBtnClicked then 
            mc.TweakingKnob=  2 
        end 

        if im.IsItemHovered(ctx) and not LFO.EditWinOpen and not mc.JustClosedLFO then 
            OpenSamllShapeSelect = FxGUID..i
        end

        if OpenSamllShapeSelect == FxGUID..i then 
            if not im.IsItemHovered(ctx,im.HoveredFlags_RectOnly) then  
                OpenSamllShapeSelect_unhoverTime = (OpenSamllShapeSelect_unhoverTime or 0) + 1
                if OpenSamllShapeSelect_unhoverTime > 5 then 

                    OpenSamllShapeSelect = nil 
                    OpenSamllShapeSelect_unhoverTime = 0
                end
            elseif im.IsItemHovered(ctx,im.HoveredFlags_RectOnly) and IsLBtnClicked  then  
                im.CloseCurrentPopup(ctx)
                if Open_Cont_LFO_Win then 

                    mc.JustClosedLFO = true
                    OpenSamllShapeSelect=nil
                end
                LFO.EditWinOpen = toggle (LFO.EditWinOpen)
                Open_Cont_LFO_Win = toggle(Open_Cont_LFO_Win , FxGUID..i)
            end
            NotifyHoverState(i+1)

        end 


        if im.IsItemHovered(ctx,im.HoveredFlags_RectOnly) and IsLBtnClicked and mc.JustClosedLFO then 
            Open_Cont_LFO_Win = toggle(Open_Cont_LFO_Win , FxGUID..i) 
            LFO.EditWinOpen = toggle (LFO.EditWinOpen)
        end 
        if mc.JustClosedLFO and not im.IsItemHovered(ctx, im.HoveredFlags_RectOnly) then 
            mc.JustClosedLFO = nil 
        end 
        
        if im.IsItemHovered(ctx) and not im.IsPopupOpen(ctx, 'Small Shape Select') and not LFO.EditWinOpen then 
            im.OpenPopup(ctx, 'Small Shape Select'..(i+1)..FxGUID)
        end
        
        LFO_Small_Shape_Selector(mc,fx,i+1, FxGUID)

        

        


        if Open_Cont_LFO_Win and Open_Cont_LFO_Win == FxGUID..i then 

            Cont_open_LFO_Win(LT_Track, i+1 , x , y, mc)
        end
        if Mc.NeedSendAllCoord and mc.All_Coord  and mc.Node then

            Cont_Send_All_Coord(fx, i+1, mc.All_Coord, mc, #mc.Node)
            Mc.NeedSendAllCoord = nil
        end
    end 

    
end

local function Follower_Box(mc,i)
    if  mc.Type ~= 'Follower' then return end 
    local x , y = im.GetCursorScreenPos(ctx)
    local sz = LFO_Box_Size
    local x = x - 10
    local I = i+1
    im.DrawList_AddRectFilled(WDL,x, y, x+sz,y+sz , 0x00000055)
    im.DrawList_AddRect(WDL,x-1, y-1, x+sz +1 ,y+sz+1 , 0xffffff77)
    im.SetCursorScreenPos(ctx, x-1, y-1)
    local rv = im.InvisibleButton(ctx, 'Follower Box'.. i.. FxGUID, sz,sz)  
    if im.IsItemClicked(ctx,1 )then 
        mc.TweakingKnob = 2 
    elseif rv then 
        local x , y = im.GetCursorScreenPos(ctx)
        im.SetNextWindowPos(ctx, x -sz , y - sz*2.75 )
        im.OpenPopup(ctx, 'Follower Window'..i..FxGUID)
    end 
    NotifyHoverState(I, im.IsItemHovered(ctx))
    local clr 
    if AssignContMacro == i and AssignContMacro_FxGuID == FxGUID then 
        if  RepeatAtInterval(0.3, nil) then
            clr = Accent_Clr
        end
    end
    DrawFollowerLine (mc, I, 'ContainerMacro', clr)

    if im.BeginPopup(ctx, 'Follower Window'..i..FxGUID)then 
        im.Text(ctx, 'Speed : ')
        SL()
        local m = mc
        local CurX = im.GetCursorPosX(ctx)
        im.SetNextItemWidth(ctx, 80)
        retval, m.Smooth = im.DragDouble(ctx, '##Smoothness', m.Smooth or 1, 1, 0, 300,'%.1f')
        


        local x, y = im.GetWindowPos(ctx)
        local w, h = im.GetWindowSize(ctx)

        if retval then
            r.gmem_attach('ContainerMacro')
            m.smooth = SetMinMax(0.1 ^ (1 - m.Smooth * 0.01), 0.1, 100)
            r.gmem_write(4, 10)       ---tells jsfx macro type = Follower, and user is adjusting smoothness
            r.gmem_write(5, I)        ---tells jsfx which macro
            r.gmem_write(9, m.smooth) -- Sets the smoothness
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Speed',m.Smooth,true)
        end

        --im.Text(ctx, ('S = ' .. (m.Smooth or '') .. 's= ' .. (m.smooth or '')))
        im.Text(ctx, 'Gain : ')
        SL(CurX)
        im.SetNextItemWidth(ctx, 80)

        rv, m.Gain = im.DragDouble(ctx, '##Gain' .. I, m.Gain or 100, 1, 0, 400, '%.0f' .. '%%')
        if im.IsItemActive(ctx) then
            r.gmem_attach('ContainerMacro')

            r.gmem_write(4, 11) ---tells jsfx macro type = Follower, and user is adjusting gain
            r.gmem_write(5, I)
            r.gmem_write(9, m.Gain / 100)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Gain',m.Gain, true)
        end

        im.EndPopup(ctx)
    end 

end 

local function Cont_Open_SEQ_Win(MacroNum,FxGUID, mc, x, y )
    local i = MacroNum
    im.SetNextWindowPos(ctx, x , y - 200)
    if im.BeginPopup(ctx, 'SEQ Window' .. i..FxGUID, im.WindowFlags_NoResize + im.WindowFlags_NoDocking  + im.WindowFlags_AlwaysAutoResize) then
        local WDL = im.GetWindowDrawList(ctx)
        local function writeSEQDNom()
            if AddMacroJSFX() then
                r.gmem_write(4, 8) --[[tells JSFX user is tweaking seq length or DNom]]
                r.gmem_write(5, i) --[[tells JSFX the macro]]
                r.gmem_write(10, mc.Dnom)
                r.gmem_write(9, mc.SeqL or SEQ_Default_Num_of_Steps)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator',mc.Dnom, true)
            end
        end

        local function writeSEQGmem()
            if AddMacroJSFX() then
                r.gmem_write(4, 8)
                r.gmem_write(5, i)
                r.gmem_write(9, mc.SeqL)
                r.gmem_write(10, mc.Dnom or SEQ_Default_Denom)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length', mc.SeqL, true)
            end
        end
        local function Btns ()


            im.Text(ctx, 'Sequence Length : ')

            rv, mc.SeqL = im.SliderInt(ctx, '##' .. 'Macro' .. i .. 'SEQ Length',mc.SeqL or SEQ_Default_Num_of_Steps, 2, 64)
            if im.IsItemActive(ctx) then writeSEQGmem() end
            SL()
            if im.Button(ctx, 'x2##' .. i) then
                mc.SeqL = math.floor((mc.SeqL or SEQ_Default_Num_of_Steps) * 2)
                writeSEQGmem()
            end
            SL()
            if im.Button(ctx, '/2##' .. i) then
                mc.SeqL = math.floor((mc.SeqL or SEQ_Default_Num_of_Steps) / 2)
                writeSEQGmem()
            end

            im.Text(ctx, 'Step Length : ')
            if im.Button(ctx, '2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 0.125
                writeSEQDNom()
            end
            if mc.Dnom == 0.125 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            SL()
            if im.Button(ctx, '1 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 0.25
                writeSEQDNom()
            end
            if mc.Dnom == 0.25 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                    R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            SL()
            if im.Button(ctx, '1/2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 0.5
                writeSEQDNom()
            end
            if mc.Dnom == 0.5 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                    R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            SL()
            if im.Button(ctx, '1/4 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 1
                writeSEQDNom()
            end
            if mc.Dnom == 1 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            SL()
            if im.Button(ctx, '1/8 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 2
                writeSEQDNom()
            end
            if mc.Dnom == 2 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            SL()
            if im.Button(ctx, '1/16 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 4
                writeSEQDNom()
            end
            if mc.Dnom == 4 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            SL()
            if im.Button(ctx, '1/32 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 8
                writeSEQDNom()
            end
            SL()
            if mc.Dnom == 8 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end
            if im.Button(ctx, '1/64 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                mc.Dnom = 16
                writeSEQDNom()
            end
            if mc.Dnom == 16 then
                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
            end

        end

        local function Steps()
            local MsX, MsY = im.GetMousePos(ctx)
            for St = 1, mc.SeqL or SEQ_Default_Num_of_Steps, 1 do
                im.InvisibleButton(ctx, '##SEQ' .. St .. TrkID, StepSEQ_W, StepSEQ_H)
                local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx); local w, h =
                    im.GetItemRectSize(ctx)
                im.DrawList_AddText(WDL, L + StepSEQ_W / 2 / 2, B - 15, 0x999999ff, St)
                SL(nil, 0)
                local FillClr = 0x00000000

                if im.IsItemClicked(ctx) then
                    Mc.AdjustingSteps = true 
                elseif Mc.AdjustingSteps and not IsLBtnHeld then 
                    Mc.AdjustingSteps = nil
                end
                local AdjustingStep
                if Mc.AdjustingSteps and MsX >= L and MsX < R then
                    AdjustingStep = St
                end
                local S = mc.SEQ


                if AdjustingStep == St then
                    --Calculate Value at Mouse pos
                    local MsX, MsY = im.GetMousePos(ctx)

                    S[St] = SetMinMax(((B - MsY) / StepSEQ_H), 0, 1) --[[ *(-1) ]]
                    r.gmem_write(4, 7)                        -- tells jsfx user is changing a step's value
                    r.gmem_write(5, i)                        -- tells which macro user is tweaking
                    r.gmem_write(112, SetMinMax(S[St], 0, 1)) -- tells the step's value
                    r.gmem_write(113, St)                     -- tells which step

                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', S[St], true)
                elseif IsRBtnHeld and im.IsMouseHoveringRect(ctx, L, T, R, B)  then
                    SEQ_RMB_Val = 0
                    S[St] = SEQ_RMB_Val
                    r.gmem_write(4, 7)             -- tells jsfx user is changing a step's value
                    r.gmem_write(5, i)             -- tells which macro user is tweaking
                    r.gmem_write(112, SEQ_RMB_Val) -- tells the step's value
                    r.gmem_write(113, St)          -- tells which step
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', SEQ_RMB_Val, true)
                end
                local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)

                if im.IsItemHovered(ctx, im.HoveredFlags_RectOnly)  then
                    FillClr = 0xffffff22
                    Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                end
                HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1, GetItemRect, Foreground)

                im.DrawList_AddRectFilled(WDL, L, T + StepSEQ_H, L + StepSEQ_W - 1, math.max(B - StepSEQ_H * (mc.SEQ[St] or 0), T), Clr)

                if CurrentPos == St or (CurrentPos == 0 and St == (mc.SeqL or SEQ_Default_Num_of_Steps)) then -- if Step SEQ 'playhead' is now on current step
                    im.DrawList_AddRect(WDL, L, B, L + StepSEQ_W - 1, T, 0xffffff88)
                end
            end
        end

        Btns ()
        Steps()

        local x, y = im.GetWindowPos(ctx)
        local w, h = im.GetWindowSize(ctx)


        if im.IsMouseHoveringRect(ctx, x, y, x + w, y + h) then 
            notHoverSEQ_Time = 0 
          
        end
        FX[FxGUID].Highlight_Macro = i
        im.EndPopup(ctx)
      
    end

    if FX[FxGUID].Highlight_Macro then 
        if not im.IsPopupOpen(ctx, 'SEQ Window' .. i..FxGUID) then 
            FX[FxGUID].Highlight_Macro =nil 
        end 
    end 

end

local function StepSeq_Box(mc,i)
    if  mc.Type ~= 'Step' then return end 
    local x , y = im.GetCursorScreenPos(ctx)
    local sz = LFO_Box_Size
    local x = x - 10
    local I = i+1
    im.DrawList_AddRectFilled(WDL,x, y, x+sz,y+sz , 0x00000055)
    im.DrawList_AddRect(WDL,x-1, y-1, x+sz +1 ,y+sz+1 , 0xffffff77)
    if  im.InvisibleButton(ctx, 'Step Seq Box'.. i.. FxGUID, sz,sz)  then 
        im.OpenPopup(ctx, 'SEQ Window' .. I..FxGUID)
    end 
    if im.IsItemClicked(ctx,1) then 
        mc.TweakingKnob=2
    end 
    NotifyHoverState(I,im.IsItemHovered(ctx))
    Cont_Open_SEQ_Win(I,FxGUID, mc , x , y )
    mc.SeqL = mc.SeqL or SEQ_Default_Num_of_Steps
    mc.SEQ = mc.SEQ or {}
    local S = mc.SEQ
    local clr = 0xffffffff
    if AssignContMacro == i and AssignContMacro_FxGuID == FxGUID then 
        if  RepeatAtInterval(0.3, nil) then
            clr = Accent_Clr
        end
    end
    for St = 1, mc.SeqL, 1 do -- create all steps
        local W =  sz/mc.SeqL
        im.DrawList_AddRectFilled(WDL, x+W*(St-1) , y+sz, x+W*St-1 , y +sz -  sz * ((S[St] or 0 )),clr)
    end 
end


local function MacroKnob(mc, i, Size , TB, fxidx)
    local I = i +1
    local row = math.ceil ( I /4 )

    if mc.Type =='Macro' and TB and TB[1] then 



        mc.Val = mc.Val 
        local Macro_FXid = TB[1].addr_fxid
        if fxidx then  Macro_FXid = fxidx end 
        im.SetCursorPos(ctx, im.GetCursorPosX(ctx) - 5, im.GetCursorPosY(ctx) - 5)
        local v = r.TrackFX_GetParamNormalized(LT_Track, Macro_FXid, i)
        mc.TweakingKnob , mc.Val , mc.center = AddKnob_Simple(ctx , FxGUID..'Macro'..i,  mc.Val or v, Size)
        if im.IsItemHovered(ctx) then 
            fx.HvrMacro =  i
            AnyMacroHovered = true 
        end
        im.SetNextItemWidth(ctx, Size*2.7)
        im.SetCursorPos(ctx,35 + (Size*3 * (row-1)),  10+(i-4*(row-1)) * (Size*2+25) + Size*1.8)

        --im.InputText(ctx,'##Label'..i)

        _,mc.Name =  r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro '..I..' Name', '', false)
        local rv, label = im.InputText(ctx, '##'..i, mc.Name or ( 'Mc ' .. I), im.InputTextFlags_AutoSelectAll)
        if rv then 
            mc.Name = label
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro '..I..' Name', label, true )
        end 

        if mc.TweakingKnob == 1  then 
            r.TrackFX_SetParamNormalized(LT_Track, fx.LowestID, i, mc.Val)
        end



    end
end

local function  macroPage(TB)
    if not fx.MacroPageActive then return end 

    local Size = 15 
    for i = 1 , 8 , 1 do 
        fx.Mc = fx.Mc or {}
        fx.Mc[i] = fx.Mc[i] or {}
    end 
    r.gmem_attach('ContainerMacro')
    --r.gmem_write(2, fx.DIY_FxGUID)
    local x_before , y_before = im.GetCursorPos(ctx)

    for i = 0 , fx.ModSlots - 1 , 1 do
        local I = i +1
        local mc = fx.Mc[I]
        local row = math.ceil ( I /4 )
        mc.TweakingKnob = nil
        if not mc.Type then 

            _, mc.Type = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. I .. 'Type', '', false)

            if mc.Type == '' then mc.Type = 'Macro' end 
        end

        mc.Gain = tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Gain','', false)))
        mc.Smooth =tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Speed','',false)))



        im.SetCursorPos(ctx,45 + (Size*3 * (row-1)),  10+ (i-4*(row-1) ) * (Size*2+25))

        MacroKnob(mc,i, Size,TB)
        LFO_Box(mc,i)
        Follower_Box(mc,i)
        StepSeq_Box(mc,i)
        
        if mc.TweakingKnob == 2   then  -- if right click on  knob 

            if Mods == 0 then 

                if not AssignContMacro then 
                    
                    AssignContMacro = i
                    AssignContMacro_FxGuID = FxGUID

                else AssignContMacro = nil 
                end 
                if I == 4 then 
                    fx.ModSlots = 8  
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container Active Mod Slots '..FxGUID , fx.ModSlots  , true )
                end 
            elseif Mods == Ctrl then 
                im.OpenPopup(ctx,'Container Macro' .. I .. 'Menu')
                
            end

        end 
        if im.BeginPopup(ctx, 'Container Macro' .. I .. 'Menu') then
            im.SeparatorText(ctx, 'Set Type to :')

            if SetTypeToMacro(mc.Type,I) then mc.Type = 'Macro' end    
            --if SetTypeToEnv(mc.Type,I) then mc.Type = 'env'    end
            if SetTypeToStepSEQ(mc.Type,I, mc) then mc.Type = 'Step'    end
            if SetTypeToFollower(mc.Type,I) then mc.Type = 'Follower'   end
            if SetTypeToLFO(mc.Type,I) then 
                mc.Type = 'LFO'     
                Mc.NeedSendAllCoord = true 

               --[[  if mc.All_Coord.X then 
                    CONT_Send_All_Coord(fx, I , mc.All_Coord, mc)
                end ]]
            end
            im.EndPopup(ctx)
            
        end 


        if AssignContMacro == i and AssignContMacro_FxGuID == FxGUID then 
            
            if  RepeatAtInterval(0.3, nil) then
                if mc.Type == 'Macro' then  
                    Draw_Simple_Knobs_Arc (mc.center, Accent_Clr, Size)
                --[[ elseif mc.Type == 'LFO' or mc.Type == 'Follower' then 
                    local sz = LFO_Box_Size
                    im.DrawList_AddRectFilled(WDL, mc.LFOx , mc.LFOy , mc.LFOx + sz, mc.LFOy+sz, 0xffffff11) ]]
                end 
            end 
        end 
    end 
    local lastrow = math.ceil ( fx.ModSlots /4 )
    fx.Width = fx.Width + Size  *3.3 * lastrow

    im.SetCursorPos(ctx,  x_before +  (Size*3 * lastrow)  , y_before)

    if not AnyMacroHovered then fx.HvrMacro = nil end 
end  




function AddTitleBgClr ()

    local x , y = im.GetCursorScreenPos(ctx)
    local X = x
    local WDL = im.GetWindowDrawList(ctx)

    im.DrawList_AddRectFilled(WDL, X-30, y , X - 10, y + 220, 0x77777755 --[[ 0x49CC8544 ]])

end


local function DragDropToCollapseView (FX_Id,Xpos, GUID, v)
    if  (Payload_Type == 'FX_Drag' or Payload_Type == 'DND ADD FX') then 
        
        local W, H = 130, 20
        local L,T = im.GetCursorScreenPos(ctx)
        local L = Xpos
        --if FX_Id ~= fx.LastSpc then  L = L-135  end 

        if im.IsMouseHoveringRect(ctx, L, T-H/2, L+W, T+H/2 )  then 
            im.DrawList_AddLine(Glob.FDL, L, T, L+W , T, Accent_Clr, 3)
            if im.IsMouseReleased(ctx, 0) then 

                local Drag_GUID = r.TrackFX_GetFXGUID(LT_Track, Payload)
                local ofs  = 0 
                if fx.parent == FX[Drag_GUID].parent then -- if they're in the same container
                    if Payload < FX_Id then 
                        if v then ofs = v.scale end 
                            
                    end
                end 

                table.insert(MovFX.FromPos, Payload )
                table.insert(MovFX.ToPos,   FX_Id - ofs)
                if Mods == Cmd then  NeedCopyFX=true   DropPos = FX_Id end 
            end
        end
        --im.DrawList_AddRect(WDL, L , T-H/2, L+W, T+H/(Last or 2), 0xff77ffff)
    end 
end

local function DndAddFXtoContainer_TARGET()
    im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)
    if im.BeginDragDropTarget(ctx) then
        local dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX')
        im.EndDragDropTarget(ctx)
        if dropped and Mods == 0  then
            local FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) -- root containder  

            if FxGUID ~= Root_FxGuid then 
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1) 
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1
                
                local function Get_Fx_Ct (TB, base_FX_Ct )
                    local C =  Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                        
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct (C , Nxt_Lyr_FX_Ct )
                    end

                    return Final_FX_Ct
                end

                local FX_Ct =  Get_Fx_Ct (TREE, Rt_FX_Ct )

                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1) 
                
                FX_Id =   Empty_Cont_Fx_Id
            end
            r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Id)
        end
    end
    im.PopStyleColor(ctx)
end

local function DndMoveFXtoContainer_TARGET()
    if im.BeginDragDropTarget(ctx) then
        local rv, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
        im.EndDragDropTarget(ctx)
        Highlight_Itm(WDL, 0xffffff33)
        if rv and Mods == 0 then 
            local FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) -- root containder  

            if FxGUID ~= Root_FxGuid then 
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1) 
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1
                
                local function Get_Fx_Ct (TB, base_FX_Ct )
                    local C =  Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                        
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct (C , Nxt_Lyr_FX_Ct )
                    end

                    return Final_FX_Ct
                end

                local FX_Ct =  Get_Fx_Ct (TREE, Rt_FX_Ct )

                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1) 
                
                FX_Id =   Empty_Cont_Fx_Id

            end
            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Id, true )
        end
    end    
end

local function Render_Collapsed ( v ,  CollapseXPos , FX_Id, CollapseYPos,i ,GUID,TB)
    local Hv
    fx.BgClr=nil



    im.SetCursorPosX(ctx, tonumber( CollapseXPos))
    --local FX_Id = 0x2000000 + i*(r.TrackFX_GetCount(LT_Track)+1) + (FX_Idx+1)
    local GUID =  r.TrackFX_GetFXGUID(LT_Track, FX_Id)

    if fx.MacroPageActive then fx.Width = fx.Width+ 70
    else fx.Width = 50 + 150
    end
    if GUID then 
        im.PushStyleVar(ctx, im.StyleVar_ItemSpacing,1 , -3)

        FX[GUID] = FX[GUID]  or {}
        local Click = AddWindowBtn (GUID, FX_Id, 170, true , true , true ) 

        
        SL(165)
        DragDropToCollapseView (FX_Id, CollapseXPos_screen, GUID, v )

        
        --SyncWetValues(FX_Id)
        if Click == 2  then 
            if fx.Sel_Preview ~= FX_Id then 
                fx.Sel_Preview = FX_Id
            else 
                fx.Sel_Preview = nil
            end
        end
        if fx.Sel_Preview == FX_Id then 
            HighlightSelectedItem(nil,Accent_Clr,nil,nil,nil,nil,nil,nil,nil,1,1,'GetItemRect')
        end
        SyncWetValues(FX_Id)

        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Id] = Add_WetDryKnob(ctx, 'a'..FX_Id, '', Wet.Val[FX_Id] or 1, 0, 1, FX_Id)
        
        


        im.PopStyleVar(ctx)
        if Hover then 
            if tonumber(FX_Count) > 9  then 
                --FX_DeviceWindow_NoScroll = im.WindowFlags_NoScrollWithMouse
                DisableScroll = true 
                fx.NoScroll = nil 

            else 
                FX_DeviceWindow_NoScroll = 0
                DisableScroll = false 
                --fx.NoScroll =  im.WindowFlags_NoScrollWithMouse  +  im.WindowFlags_NoScrollbar +  im.WindowFlags_AlwaysAutoResize

            end
        end

        
        --[[ + (    Hv or 0) ]]

        if fx.Cont_Collapse ==1 then 

            fx.LastSpc = FX_Id + (v.scale or 0)

        end
        
        if Hv then  return Hv end 
    end
    
end

AddTitleBgClr ()

titleBar()
fx.BgClr = nil


---------------------------------------------
---------Body--------------------------------
---------------------------------------------

rv, FX_Count = r.TrackFX_GetNamedConfigParm( LT_Track, FX_Idx, 'container_count')
local WinW = 0 
local AllW = 0

local X , Y = im.GetCursorScreenPos(ctx)
local TB = Upcoming_Container 
if not Upcoming_Container and TREE[Root_ID+1]  then 
    TB = TREE[Root_ID+1].children
end 

macroPage(TB)



if tonumber( FX_Count) == 0 then 

    im.SetCursorScreenPos(ctx, X-50 , Y)
    im.InvisibleButton(ctx, 'DropDest'..FxGUID , 60 , 210)

    --second_layer_container_id = first_layer_container_id + (first_layer_fx_count * second_layer_container_pos)

    DndMoveFXtoContainer_TARGET()
    DndAddFXtoContainer_TARGET()
else
    local CollapseXPos, CollapseYPos  = im.GetCursorPos(ctx)
     CollapseXPos_screen = im.GetCursorScreenPos(ctx)
    local PreviewW , LastSpc 
    im.SetCursorPosY(ctx, Top_Spacing )
    if TB then 
        for i, v in ipairs(TB) do 
            if i == 1 then 
                fx.LowestID =  v.addr_fxid
            end 
            local FX_Id = v.addr_fxid
            local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)

            if  fx.Cont_Collapse == 1  then 


                local W  = Render_Collapsed(v,CollapseXPos,FX_Id, CollapseYPos,i,GUID, TB)
                if W then PreviewW = W end 
                --fx.BgClr = 0xffffff44

            else       -- if not collapsed
                --fx.BgClr = 0xff22ff44
                local function Render_Normal()
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Id)
                    
                    local  diff, Cur_X_ofs
                    if i == 1 then 
                        SL(nil,0)
                        im.SetCursorPosY(ctx, Top_Spacing )

                        AddSpaceBtwnFXs(FX_Id  , SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth)
                        SL(nil,0)

                    end

                    

                    If_Theres_Pro_C_Analyzers(FX_Name, FX_Id)
                    im.SetCursorPosY(ctx,Top_Spacing)
                
                    if v.children then 
                        Upcoming_Container = v.children
                        Upcoming_Container_Parent = v 
                    end

                    
                    local Win_W = createFXWindow(FX_Id)

                    
                    if v.scale and GUID  then 
                        FX[GUID] = FX[GUID] or {}   
                        FX[GUID].parent =  v.addr_fxid - v.scale * i   
                    end 
                
                    local w = im.GetItemRectSize(ctx)

                    local TB = Upcoming_Container or TREE[Root_ID+1].children
                    local FX_Id_next = FX_Id + (v.scale or 0)
                    SL(nil,0)
                    if im.IsItemHovered(ctx) then Hover = true end 
                    im.SetCursorPosY(ctx, 0 )
                    LastSpc = AddSpaceBtwnFXs(FX_Id_next , nil, nil, nil, nil, nil, nil, FX_Id)

                    fx.Width = (fx.Width or 0) + (Win_W or 0) +( LastSpc or 0)
                    
                    if Hover then  DisableScroll = false  end 
                end
                local W= Render_Normal()

            end

            if Upcoming_Container and tonumber(i) == (#Upcoming_Container or #TREE[Root_ID+1].children) then 
                Upcoming_Container = nil
            end
        end
    end


    local Add_FX_Btn_Ypos
    if fx.Cont_Collapse == 1   and fx.Sel_Preview then 
        SL()
        Add_FX_Btn_Ypos = im.GetCursorPosY(ctx) + 24
        im.SetCursorPosY(ctx,tonumber( CollapseYPos)  )

        Hv = createFXWindow(fx.Sel_Preview)
        if Hv then PreviewW = Hv end 
        if PreviewW then fx.Width = 50 + 150 + PreviewW end
    end
    if fx.Cont_Collapse == 1 then
        if Add_FX_Btn_Ypos then im.SetCursorPosY(ctx,tonumber( Add_FX_Btn_Ypos)  ) end 
        im.SetCursorPosX(ctx,tonumber( CollapseXPos)  )
        DragDropToCollapseView (fx.LastSpc, CollapseXPos_screen)
        if im.Button(ctx,'+' , 130) then 
            im.OpenPopup(ctx, 'Btwn FX Windows' .. fx.LastSpc)
        end 
        AddFX_Menu(fx.LastSpc)
    end

    if Upcoming_Container  then 
        if not Upcoming_Container[1] then 
            Upcoming_Container =nil
        end

    else 
    
    end
                            
   --[[  if NeedRetrieveLayout then 
        RetrieveFXsSavedLayout(Sel_Track_FX_Count) 
        NeedRetrieveLayout = nil 
    end  ]]


    
    if not fx.Collapse then 
        local WDL = im.GetWindowDrawList(ctx)
        --im.DrawList_AddRect(WDL ,XX - 33, YY, XX+fx.Width -35, YY+220, 0xffffffff)
        HighlightSelectedItem(nil, Accent_Clr, 2, X - 33, Y, X+ (fx.Width or 190)  -35 , Y+220, h, w, 1, 0.2, 'no', Foreground, 4, 4)
    end 


    im.DrawList_AddRectFilled(WDL, 0, 0 , 0 + 15 , 165, 0xfffffff)

end

