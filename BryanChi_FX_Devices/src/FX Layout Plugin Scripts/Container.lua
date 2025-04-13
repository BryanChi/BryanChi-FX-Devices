-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid
local fx = FX[FxGUID]

fx.TitleWidth  = 0
--fx.CustomTitle = fx.Name
fx.Width = 35 +10
fx.V_Win_Btn_Height = fx.V_Win_Btn_Height or  130 
fx.Cont_Collapse = fx.Cont_Collapse or 0

local Title_Width = 33
local AnyMacroHovered
local ModIconSz = 20
local Top_Spacing = 0
local Modulator_Outline_Clr = 0xffffff22
LFO_Box_Size = 38
local Root_ID = 0
if FX_Idx < 0x2000000 then Root_ID = FX_Idx   Root_FxGuid = FxGUID end 

DEBUG_W = DEBUG_W or {}
local Add_FX_Btn_Xpos

local rv, FX_Count = r.TrackFX_GetNamedConfigParm( LT_Track, FX_Idx, 'container_count')
local WinW = 0 
local AllW = 0


local function Add_Width(Parallel, FxGUID, FX_Id, FX_Name)

    if  FX_Name:find('FXD Containr Macro') then return end 
    -- Add the width for parallel Mixer if haven't done so 
    --[[ if not fx.Added_Parallel_Mixer_Width then
        fx.Width = (fx.Width or 0) + PAR_FX_MIXER_WIN_W + SPACE_BETWEEN_FXS_W
        fx.Added_Parallel_Mixer_Width = true
    end ]]
    for I,V in ipairs(PAR_FXs) do
        for ii, vv in ipairs(V) do 

            if ii== 1 and  vv.addr_fxid == FX_Id then 
                fx.Width = (fx.Width or 0) + PAR_FX_MIXER_WIN_W + SPACE_BETWEEN_FXS_W
                fx.Added_Parallel_Mixer_Width = true
            end 
        end
    end 
    if Parallel then 
        if Parallel ~= 'Mixer Layout - Show' then return end 
    end

    local W = FX[FxGUID].Width_Collapse or FX[FxGUID].Width or 170
    
    fx.Width = ( fx.Width or 0) + (W or 0) +( LastSpc or 0)
end




local function Container_CollapseIfTab(FxGUID, FX_Idx)
    if FX[FxGUID].Collapse then return end
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

    if not fx.DIY_FxGUID then 
                
        local rv , diyFxGUID = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' DIY FxGUID', '', false)
        if rv and diyFxGUID ~= '' then 
            fx.DIY_FxGUID = diyFxGUID 
        else
            fx.DIY_FxGUID = math.random(100000000, 999999999)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' DIY FxGUID', fx.DIY_FxGUID, true)
        end
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
    if im.ImageButton(ctx, '##', Img.ModIconHollow, ModIconSz , ModIconSz, nil, nil, nil, nil, 0x00000000, clr) then 
        fx.MacroPageActive = toggle (fx.MacroPageActive)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID of '..FxGUID..'Macro Active' , tostring(fx.MacroPageActive), true )

        Trk[TrkID].Container_Id = Trk[TrkID].Container_Id or {}

        
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID of '..FxGUID , #Trk[TrkID].Container_Id , true )
        if not slot then slot  = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1)end 
        local _, FirstFX = r.TrackFX_GetFXName(LT_Track, slot)

        if not string.find(FirstFX, 'FXD Containr Macro') then 

            r.gmem_attach('ContainerMacro')
            r.gmem_write(0, Cont_ID ) -- use to be Cont_ID , but I think it's wrong?
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
                Set_Midi_Output_To_Bus1()

            end 
            
        end 


        fx.ModSlots = fx.ModSlots or 4  
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container Active Mod Slots '..FxGUID , fx.ModSlots  , true )



    end 
    im.PopStyleColor(ctx)
end

local function titleBar()
    --if not fx.Collapse then
        local W = 33
        SyncWetValues(FX_Idx)
        local x, y = im.GetCursorPos(ctx)
        
        -- Get the window draw list instead of foreground draw list
        local WDL = im.GetWindowDrawList(ctx)
        
        -- Draw background FIRST
        im.DrawList_AddRectFilled(WDL, x, y, x+W, y + 220, ThemeClr('Accent_Clr'), 5)

        local Pad_L = fx.Collapse and 3 or 6
        -- Position other elements AFTER drawing the icon
        im.SetCursorPosX(ctx, Pad_L)
        SyncWetValues(FX_Idx)
        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 1, 0, 1, FX_Idx,nil,FxGUID)
        local X, Y = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, X+ Pad_L, Y - 10)
        
        --im.SetCursorPos(ctx, 7, 165)
        Modulation_Icon(LT_Track, fx.LowestID)
        
        im.Dummy(ctx, W, 10)
        im.SetCursorPos(ctx, W, 0)
   -- end
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


local function RC(str, type)
    if type == 'str' then
        return select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID .. str, '', false))
    else
        return tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID .. str, '', false)))
    end
end


local function recall_LFO_Data(mc,i)

    if mc.Type ~= 'LFO' then return end
    if mc.Node then return end

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
    --local x = x - 10
    local I = i+1
    im.DrawList_AddRectFilled(WDL,x, y, x+sz,y+sz , 0x00000055)
    --im.DrawList_AddRect(WDL,x-1, y-1, x+sz  ,y+sz+1 , 0xffffff77)
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
    im.Dummy(ctx, 10, 10)

    fx.IsContainer = true 

    for i = 0 , fx.ModSlots - 1 , 1 do
        local I = i +1
        local mc = fx.Mc[I]
        mc.Num = I
        local row = math.ceil ( I /4 )
        mc.TweakingKnob = nil
        if not mc.Type then 
            _, mc.Type = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. I .. 'Type', '', false)
            if mc.Type == '' then mc.Type = 'Macro' end 
        end

        mc.Gain = tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Gain','', false)))
        mc.Smooth =tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Speed','',false)))

        local function Bottom_Label()

        end

        mc.Random_Int = mc.Random_Int or  RC('Random Interval for mod'..  I )
        mc.Random_Smooth = mc.Random_Smooth or RC('Random Smooth for mod'.. I)
        mc.Random_Chance = mc.Random_Chance or RC('Random Chance for mod'.. I)

        im.SetCursorPos(ctx, 45 + (Size*3 * (row-1)) - 5,  5+ (i-4*(row-1) ) * (Size*2+25))
        local X , Y= im.GetCursorPos(ctx)

        MacroKnob(mc,i, LFO_Box_Size/2 ,TB, true, FxGUID)
        local Sz = LFO_Box_Size
        recall_LFO_Data(mc,i+1)
        LFO_BOX_NEW(mc, i+1, Sz, Sz, true, LT_Track, {im.GetCursorScreenPos(ctx)} , FxGUID) -- true is IsContainer
        Follower_Box(mc,i, Sz, FxGUID, 'ContainerMacro', Sz)
        StepSeq_Box(mc,i)
        Random_Modulator_Box(mc, i+1 , Sz, Sz, true, FxGUID)

        XY_BOX(mc, i+1, Sz *2.5, true, TB )
        if mc.Type ~= 'Macro' then


            im.SetCursorPos(ctx,X, Y + LFO_Box_Size)
            im.PushStyleVar(ctx, im.StyleVar_FramePadding ,0, 0 )
            Highlight_Itm(WDL, nil, Modulator_Outline_Clr)
            im.SetCursorPosX(ctx, X)
            Editable_Modulator_Label(mc,  i,  LFO_Box_Size/2 , true,FxGUID)
            im.PopStyleVar(ctx)
    
        end
        
        
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


            Set_Modulator_Type(mc, I, 'Macro' , fx.DIY_FxGUID, FxGUID)
            if Set_Modulator_Type(mc, I, 'LFO' , fx.DIY_FxGUID, FxGUID) =='LFO' then 
                Mc.NeedSendAllCoord = true 
            end
            Set_Modulator_Type(mc, I, 'Step' , fx.DIY_FxGUID, FxGUID)
            Set_Modulator_Type(mc, I, 'Follower' , fx.DIY_FxGUID, FxGUID)
            Set_Modulator_Type(mc, I, 'XY' , fx.DIY_FxGUID, FxGUID)
            Set_Modulator_Type(mc, I, 'Random' , fx.DIY_FxGUID, FxGUID)


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
    if fx.MacroPageActive and fx.Collapse then 
        fx.Width_Collapse = 27+ Size  *3.3 * lastrow  + 5
    else 
        fx.Width_Collapse= nil
    end  


    im.SetCursorPos(ctx,  x_before +  (Size*3 * lastrow)  , y_before)

    if not AnyMacroHovered then fx.HvrMacro = nil end 
end  




function AddTitleBgClr ()

    local x , y = im.GetCursorScreenPos(ctx)
    local y = VP.Y
    local WDL = im.GetWindowDrawList(ctx)
    local W  = Title_Width -3
    local Pad = 3

    im.DrawList_AddRectFilled(WDL, x-W, y , x +W+Pad , y + 999, 0x77777722 --[[ ThemeClr('Accent_Clr_Not_Focused') ]] --[[ 0x49CC8544 ]])
    im.DrawList_AddLine(WDL, x+W + Pad , y , x+W + Pad, y+999,  ThemeClr('Accent_Clr_Dark'))

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

local function DndFXtoContainer_TARGET(action_type)
    -- Only push style color for ADD action
    if action_type == 'ADD' then
        im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)
    end

    
    if im.BeginDragDropTarget(ctx) then

        -- Accept different payload types based on action
        local payload_type = action_type == 'ADD' and 'DND ADD FX' or 'FX_Drag'
        local dropped, payload = im.AcceptDragDropPayload(ctx, payload_type)
        im.EndDragDropTarget(ctx)

        -- Highlight only for MOVE action
        if action_type == 'MOVE' then
            Highlight_Itm(WDL, 0xffffff33)

        end
        
        if dropped and Mods == 0 then
            local FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) -- root containder  

            if FxGUID ~= Root_FxGuid then 
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1
                
                local function Get_Fx_Ct(TB, base_FX_Ct)
                    local C = Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct(C, Nxt_Lyr_FX_Ct)
                    end

                    return Final_FX_Ct
                end

                local FX_Ct = Get_Fx_Ct(TREE, Rt_FX_Ct)
                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1)
                FX_Id = Empty_Cont_Fx_Id
            end
            
            -- Perform different actions based on type
            if action_type == 'ADD' then
                r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Id)
            else -- MOVE
                r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Id, true)
            end
        end
    end
    
    -- Pop style color for ADD action
    if action_type == 'ADD' then
        im.PopStyleColor(ctx)
    end
end



local function Render_Collapsed ( v ,  CollapseXPos , FX_Id, CollapseYPos,i ,GUID,TB)
    local Hv
    fx.BgClr=nil



    im.SetCursorPosX(ctx, tonumber( CollapseXPos))
    --local FX_Id = 0x2000000 + i*(r.TrackFX_GetCount(LT_Track)+1) + (FX_Idx+1)
    local GUID =  r.TrackFX_GetFXGUID(LT_Track, FX_Id)

    if fx.MacroPageActive then fx.Width = fx.Width+ 70
    else fx.Width = 50 + 160
    end
    if GUID then 
        im.PushStyleVar(ctx, im.StyleVar_ItemSpacing,1 , -3)

        FX[GUID] = FX[GUID]  or {}
        local Click = AddWindowBtn (GUID, FX_Id, 170, true , true , true ) 

        
        SL()
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

        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Id] = Add_WetDryKnob(ctx, 'a'..FX_Id, '', Wet.Val[FX_Id] or 1, 0, 1, FX_Id,nil,GUID)
        
        


        im.PopStyleVar(ctx)
        if Hover then 
            local FX_Count = r.TrackFX_GetCount(LT_Track)
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

local function Create_FX_Window_FOR_Chosen_FX_IF_Collapse ()
    if fx.Cont_Collapse == 1   and fx.Sel_Preview then 
            
        SL()
        --Add_FX_Btn_Ypos = im.GetCursorPosY(ctx) + 24
        --im.SetCursorPosY(ctx,tonumber( CollapseYPos)  )

         createFXWindow(fx.Sel_Preview)
        --if Hv then PreviewW = Hv end 

        if fx.Sel_Preview then 
            local guid = r.TrackFX_GetFXGUID(LT_Track,fx.Sel_Preview)
            fx.Width = 50 + 155 + (FX[guid].Width or 170) + 10

        end
    end
end

local function If_Container_Is_Empty()
    if tonumber( FX_Count) == 0 then 
        local X, Y = im.GetCursorPos(ctx, X, Y)
        im.SetCursorPos(ctx, X-50 , Y)
        im.InvisibleButton(ctx, 'DropDest'..FxGUID , 90 , 210) 
        --second_layer_container_id = first_layer_container_id + (first_layer_fx_count * second_layer_container_pos)

        DndFXtoContainer_TARGET('ADD')
        DndFXtoContainer_TARGET('MOVE')
    end
end

local function Main(TB, X, Y)
    if FX_Count == 0 then return end
    local CollapseXPos, CollapseYPos  = im.GetCursorPos(ctx)
     CollapseXPos_screen = im.GetCursorScreenPos(ctx)
    local PreviewW , LastSpc 
    im.SetCursorPosY(ctx, Top_Spacing )



    if TB    then -- if there's an upcoming container
        fx.processed_containers = fx.processed_containers or {}
        fx.Added_Parallel_Mixer_Width = nil

        for i, v in ipairs(TB) do 

            if i == 1 then 
                fx.LowestID =  v.addr_fxid
            end 
            local FX_Id = v.addr_fxid
            local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)

            if GUID and not fx.processed_containers[GUID] then
                fx.processed_containers[GUID] = true
                local SpaceClr = Calculate_Color_Based_On_Nesting_Level(fx.nestingLevel)
                local SpaceClr = HSV_Change(SpaceClr, nil, nil, -0.8)
                
                if  fx.Cont_Collapse == 1   then 
                    
                    SL()
                    if i == 1 then 
                        Add_FX_Btn_Xpos = im.GetCursorPosX(ctx)  
                    end
                    if im.BeginChild(ctx, 'Collapse'..FxGUID, 155, 220, nil) then 
                    
                        local W  = Render_Collapsed(v,CollapseXPos,FX_Id, CollapseYPos,i,GUID, TB)
                        if W then PreviewW = W end 
                        if i == #TB then 
                            fx.Add_FX_Btn_Ypos = im.GetCursorPosY(ctx)
                            fx.Add_FX_Btn_Xpos = im.GetCursorPosX(ctx)  
                        end
                        im.EndChild(ctx)
                    end
                    --fx.BgClr = 0xffffff44

                else       -- if not collapsed
                    --fx.BgClr = 0xff22ff44

                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Id)

                    local function Render_Normal()
                        if fx.Collapse then return end 
                    
                        local diff, Cur_X_ofs  
                        if i == 1 then 
                            SL(nil,0)
                            im.SetCursorPosY(ctx, Top_Spacing)
                    
                            local Wid = AddSpaceBtwnFXs(FX_Id, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth,nil,nil, SpaceClr)
                            SL(nil,0)

                            if not FX_Name:find('FXD Containr Macro') then  
                                fx.Width = fx.Width + (Wid or 15)  
                            end
                        end
                    
                        --If_Theres_Pro_C_Analyzers(FX_Name, FX_Id)
                        im.SetCursorPosY(ctx, Top_Spacing)
                    
                        -- Store the current container state before rendering child
                        local previous_container = Upcoming_Container
                        local previous_parent = Upcoming_Container_Parent

                        -- Only set upcoming container if we're not already processing it
                        -- This prevents infinite recursion
                        if v.children and not fx.processing_container then
                            Upcoming_Container = v.children
                            Upcoming_Container_Parent = v
                            -- Set the parent reference to track nesting
                            v.parent = previous_parent
                            -- Mark that we're processing this container to prevent recursion
                            fx.processing_container = true
                        end
                        
                        local Parallel = createFXWindow(FX_Id)
                        
                        -- Reset the processing flag after rendering
                        fx.processing_container = false
                        
                        if v.scale and GUID then 
                            FX[GUID] = FX[GUID] or {}   
                            FX[GUID].parent = v.addr_fxid - v.scale * i   
                        end 
                        
                        local TB = Upcoming_Container or TREE[Root_ID+1].children
                        local FX_Id_next = FX_Id + (v.scale or 0)
                        SL(nil,0)
                        if im.IsItemHovered(ctx) then Hover = true end 
                        im.SetCursorPosY(ctx, 0)
                        if not Parallel or i == #TB then 
                            local Wid = AddSpaceBtwnFXs(FX_Id_next, nil, nil, nil, nil, nil, nil, FX_Id,nil, SpaceClr)
                            fx.Width = fx.Width + (Wid or 15)  
                        end    
                        if Hover then DisableScroll = false end
                        
                        -- Restore the previous container state
                        Upcoming_Container = previous_container
                        Upcoming_Container_Parent = previous_parent
                        return Parallel
                    end
                    local Parallel = Render_Normal()

                    
                    Add_Width(Parallel, GUID, FX_Id, FX_Name)

                end

                if Upcoming_Container and tonumber(i) == (#Upcoming_Container or #TREE[Root_ID+1].children) then 
                    Upcoming_Container = nil
                end
            end
        end
        fx.processed_containers= {}
    end


    local Add_FX_Btn_Ypos  = fx.Add_FX_Btn_Ypos or nil
    Create_FX_Window_FOR_Chosen_FX_IF_Collapse ()


    if Upcoming_Container  then 
        if not Upcoming_Container[1] then 
            Upcoming_Container =nil
        end

    else 
    
    end
    
    local function Enclose_With_Brackets()
        local WDL = im.GetWindowDrawList(ctx)
        -- Draw main container bracket
        local Thick = 4
        -- Calculate nesting level based on container hierarchy
        local nestingLevel = 0
        if Upcoming_Container_Parent then
            -- If we have a parent, we're at least one level deep
            nestingLevel = 1
            
            -- Check if parent has a parent (deeper nesting)
            local parent = Upcoming_Container_Parent
            while parent and parent.parent do
                nestingLevel = nestingLevel + 1
                parent = parent.parent
            end
        end
        fx.nestingLevel = nestingLevel
        local bracketColor = Calculate_Color_Based_On_Nesting_Level(nestingLevel)
        local l = X - 33

        if not fx.Collapse then 
            --im.DrawList_AddRect(WDL ,XX - 33, YY, XX+fx.Width -35, YY+220, 0xffffffff)
            local r = X+ (fx.Width or 190)  -35
        -- HighlightSelectedItem(nil, ThemeClr('Accent_Clr_Dark'), 2, l, Y, r , Y+220, h, w, 0.1, 2, 'no', Foreground, 4, 4)
            local WDL = im.GetWindowDrawList(ctx)
            --im.DrawList_AddRect(WDL ,XX - 33, YY, XX+fx.Width -35, YY+220, 0xffffffff)
        -- HighlightSelectedItem(nil, ThemeClr('Accent_Clr_Dark'), 2, X - 33, Y, X+ (fx.Width or 190)  -35 , Y+220, h, w, 1, 0.2, 'no', Foreground, 4, 4)
            
            
            
            -- Shift hue based on container nesting level
            -- Left bracket
            im.DrawList_AddLine(WDL, l, Y, l, Y + 220, bracketColor, Thick) -- Vertical line
            im.DrawList_AddLine(WDL, l, Y, X - 21, Y, bracketColor, Thick) -- Top horizontal
            im.DrawList_AddLine(WDL, l, Y + 220, X - 21, Y + 220, bracketColor, Thick) -- Bottom horizontal
            
            -- Right bracket
            local rightX = X + (fx.Width or 190) - 35
            im.DrawList_AddLine(WDL, rightX, Y, rightX, Y + 220, bracketColor, Thick) -- Vertical line
            im.DrawList_AddLine(WDL, rightX, Y, rightX - 12, Y, bracketColor, Thick) -- Top horizontal
            im.DrawList_AddLine(WDL, rightX, Y + 220, rightX - 12, Y + 220, bracketColor, Thick) -- Bottom horizontal
        else  -- if Collapsed
           im.DrawList_AddRect(WDL, l, Y, l+ (fx.Width_Collapse or 27), Y + 220, bracketColor)
        end 
    end
    Enclose_With_Brackets()


    --im.DrawList_AddRectFilled(WDL, 0, 0 , 0 + 15 , 165, 0xfffffff)

end

--AddTitleBgClr ()

titleBar()
fx.BgClr = nil


---------------------------------------------
---------Body--------------------------------
---------------------------------------------


local X , Y = im.GetCursorScreenPos(ctx)
local TB = Upcoming_Container 
if not Upcoming_Container and TREE[Root_ID+1]  then 

    TB = TREE[Root_ID+1].children
    if TB and not TB[1] then TB = TREE[Root_ID+1]end
end 


macroPage(TB)
im.Dummy(ctx, 5,10)


If_Container_Is_Empty()
Main(TB , X, Y)
Container_CollapseIfTab(FxGUID, FX_Idx)
