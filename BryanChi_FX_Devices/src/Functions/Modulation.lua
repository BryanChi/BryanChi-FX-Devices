-- @noindex

MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
ultraschall = ultraschall

---@param Macro string|number
---@param AddIndicator boolean
---@param McroV number
---@param FxGUID string
---@param F_Tp number
---@param Sldr_Width number
---@param P_V number
---@param Vertical? "Vert"
---@param FP FX_P
---@param offset number
---@param Amt number
---@param RangeClr number
---@param IndicClr number
---@param UseCurrentVal boolean

function DrawModLines(Macro, AddIndicator, McroV, FxGUID, Sldr_Width, P_V, Vertical, FP, offset, Amt,RangeClr, IndicClr, UseCurrentVal, FX_Idx)
    local drawlist = im.GetWindowDrawList(ctx) --[[add+ here]]
    local SldrGrabPos
    local BipOfs = 0
    local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx)
    local SizeX, SizeY = im.GetItemRectSize(ctx)
    MacroModLineOffset = 0
    local UseCurrentVal = true 
    local ModAmt = Amt and Amt or FP.ModAMT[Macro]
    local  Amt = Amt or  FP.ModAMT[Macro]

   -- im.DrawListSplitter_SetCurrentChannel(FX[FxGUID].splitter,2)
    


    if FP and FP.ModAMT[Macro] then

        FP.ModBipolar = FP.ModBipolar or {}
        if FP.ModBipolar[Macro] then

            ModAmt = Amt
            BipOfs = -Amt
        end
    end

    if Vertical ~= 'Vert' then
        PosX_End_Of_Slider = (Sldr_Width) + L
        SldrGrabPos = Sldr_Width * P_V
        SliderCurPos = L + SldrGrabPos
        SliderModPos = SliderCurPos + ((ModAmt * Sldr_Width) or 0)
        SliderModPos = SetMinMax(SliderModPos, L, PosX_End_Of_Slider)
    elseif Vertical == 'Vert' then
        PosX_End_Of_Slider = T
        SldrGrabPos = (SizeY) * (P_V)
        SliderCurPos = B - SldrGrabPos
        SliderModPos = SliderCurPos - ((ModAmt * Sldr_Width) or 0)
        SliderModPos = SetMinMax(SliderModPos, T, B)
    end


    drawlist = im.GetWindowDrawList(ctx)
    -- im.DrawList_AddLine(drawlist,SliderCurPos,T,SliderModPos or 1,T, EightColors.HighSat_MidBright[Macro],3)
    local AccentClr = ThemeClr('Accent_Clr')


    local Midsat, MidBright =RangeClr or  EightColors.MidSat[Macro] or Change_Clr_A(AccentClr, -0.5)  , IndicClr or EightColors.HighSat_MidBright[Macro] or AccentClr
    if FP.ModBypass == Macro then Midsat, MidBright = 0x88888866, 0xaaaaaa66 end


    if AddIndicator and ModAmt ~= 0 then
        local ModPosWithAmt
        local M = Trk[TrkID].Mod[Macro]

        if FX[FxGUID].parent then 
            local Cont_FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent  )
            FX[Cont_FxGUID].Mc = FX[Cont_FxGUID].Mc or {}
            M  = FX[Cont_FxGUID].Mc[Macro]
        end

        if UseCurrentVal then 
            local v = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num)
            if Vertical == 'Vert' then
                ModPosWithAmt = math.max(B - (v * Sldr_Width ) --[[ - BipOfs * Sldr_Width ]] or 0, PosX_End_Of_Slider)
                im.DrawList_AddRectFilled(drawlist, L, SliderCurPos, R, ModPosWithAmt or SliderCurPos, Midsat,Rounding)
            else 
                ModPosWithAmt = math.min(L + (v * Sldr_Width ) --[[ + BipOfs * Sldr_Width ]] or 0, PosX_End_Of_Slider)
                im.DrawList_AddRectFilled(drawlist, SliderCurPos, T, (ModPosWithAmt or SliderCurPos or 0), B, Midsat,Rounding)
            end
        else 
            local MOD = McroV
            if M.Type == 'env' or M.Type == 'Step' or M.Type == 'Follower' or M.Type == 'LFO' then
                if FX[FxGUID].parent then 
                    r.gmem_attach('ContainerMacro')
                else
                    r.gmem_attach('ParamValues')
                end
                MOD = math.abs(SetMinMax(r.gmem_read(100 + Macro) / 127, -1, 1))
            end

            if MOD then
                local ModAmt = ModAmt
                if BipOfs ~= 0 then ModAmt = ModAmt * 2 end
                if Vertical == 'Vert' then
                    ModPosWithAmt = math.max(SliderCurPos - (MOD * Sldr_Width * ModAmt) - BipOfs * Sldr_Width or 0, PosX_End_Of_Slider)
                    im.DrawList_AddRectFilled(drawlist, L, SliderCurPos, R, ModPosWithAmt or SliderCurPos, Midsat,Rounding)
                else
                    ModPosWithAmt = math.min(SliderCurPos + (MOD * Sldr_Width * ModAmt) + BipOfs * Sldr_Width or 0, PosX_End_Of_Slider)
                    im.DrawList_AddRectFilled(drawlist, SliderCurPos, T, (ModPosWithAmt or SliderCurPos or 0), B, Midsat,Rounding)
                end
            end
        end
    end

    --- mod range indicator line
    if Vertical == 'Vert' then
        local SliderCurPos = SliderCurPos - BipOfs * Sldr_Width
        im.DrawList_AddRectFilled(drawlist, L - offset, SliderCurPos, L - offset, SliderModPos, MidBright, Rounding)
    else
        local SliderCurPos = SliderCurPos + BipOfs * Sldr_Width
        im.DrawList_AddLine(drawlist, SliderCurPos, T - offset, SliderModPos or 1, T - offset, MidBright, 2)
    end
end
---@param fxidx integer
---@param param_n number
---@param active number 1 active, 0 inactive
---@param scale boolean|number
---@param midibus number 0-based, 15 = Bus 16
---@param midichan number 0-based, 0 = Omni
---@param midimsg number 160 is Aftertouch
---@param midimsg2 number CC value
---@param baseline boolean|number
function ParameterMIDILink(fxidx, param_n, active, scale, midibus, midichan, midimsg, midimsg2, baseline)
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.active", tostring (active))    -- 1 active, 0 inactive
    if scale then r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.scale", scale) end
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.effect", "-100") -- -100 enables midi_msg*
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.param", "-1")    -- -1 not parameter link
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.midi_bus", midibus) -- 0 based, 15 = Bus 16
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.midi_chan", midichan) -- 0 based, 0 = Omni
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.midi_msg", midimsg)  -- 160 is Aftertouch
    r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".plink.midi_msg2", midimsg2)  -- CC value
    if baseline then r.TrackFX_SetNamedConfigParm(LT_Track, fxidx, "param." .. param_n .. ".mod.baseline", baseline) end
end

---@param TrkNum number
---@param fxid integer
---@param parmidx integer
---@param AliasName string
function SetPrmAlias(TrkNum, fxid, parmidx, AliasName)
    retval, TrackStateChunk = ultraschall.GetTrackStateChunk_Tracknumber(TrkNum)
    FXStateChunk = ultraschall.GetFXStateChunk(TrackStateChunk)
    retval, alteredFXStateChunk = ultraschall.AddParmAlias_FXStateChunk(FXStateChunk, fxid, parmidx, AliasName) --rv, alteredFXStateChunk = u.AddParmAlias_FXStateChunk( FXStateChunk, fxid, parmalias)

    _, TrackStateChunk = ultraschall.SetFXStateChunk(TrackStateChunk, alteredFXStateChunk)
    _ = ultraschall.SetTrackStateChunk_Tracknumber(TrkNum, TrackStateChunk)
end

---@param FX_Idx integer
---@param P_Num number
---@param FxGUID any ---TODO unused
function PrepareFXforModulation(FX_Idx, P_Num, FxGUID)
    local ParamValue_Modding = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    AssignMODtoFX = FX_Idx
    r.gmem_attach('ParamValues')
    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 and r.TrackFX_AddByName(LT_Track, 'Macros', 0, 0) == -1 then
        r.gmem_write(1, PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
        AddMacroJSFX()
        AssignMODtoFX = AssignMODtoFX + 1
    end


    r.gmem_write(2, PM.DIY_TrkID[TrkID]) --Sends Trk GUID for jsfx to determine track
    r.gmem_write(JSFX.P_ORIG_V + Trk.Prm.Assign, ParamValue_Modding)
end

---@param FxGUID string
---@param Fx_P integer
---@param P_Num number
---@param FX_Idx integer
function RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)
    if im.IsMouseDoubleClicked(ctx, 1) and im.IsItemClicked(ctx, 1) and Mods == 0 then
        local FP = FX[FxGUID][Fx_P]
        if FP.ModAMT or FP.Cont_ModAMT then
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.active", "0")   -- 1 active, 0 inactive
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.effect", "-100") 
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.param", "-1")   
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_bus", "0")
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_chan", "1")
            for Mc = 1, 8, 1 do
                if FP.ModAMT then
                    FP.ModAMT[Mc] = nil
                end
                if FP.Cont_ModAMT then 
                    FP.Cont_ModAMT[Mc] = nil 
                end 
            end
        end
        
    end
end

MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }

function AssignMod (FxGUID, Fx_P, FX_Idx, P_Num, p_value, trigger)
    local FP = FX[FxGUID][Fx_P]
    local RC = im.IsItemClicked(ctx, 1)

    if FP then  FP.ModBipolar = FP.ModBipolar or {} end 


    if trigger == 'No Item Trigger' then RC = im.IsMouseClicked(ctx, 1) end 
    if --[[Assign Mod]] (AssigningMacro or AssigningMidiMod) and RC then

         _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation','', false)
        if not ValBeforeMod or ValBeforeMod == '' then
            r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FX[FxGUID][Fx_P].V, true)
        end


        Trk.Prm.Assign = FP.WhichCC 
        FP.ModAMT = FP.ModAMT or {}

        --store which param has which Macros assigned
        if FP.WhichMODs == nil then -- if This prm don't have a modulation assigned yet..
            FP.WhichMODs = tostring(AssigningMacro)
            FX[FxGUID][Fx_P].ModAMT = FX[FxGUID][Fx_P].ModAMT or {}
            Trk[TrkID].ModPrmInst = (Trk[TrkID].ModPrmInst or 0) + 1
            FX[FxGUID][Fx_P].WhichCC = Trk[TrkID].ModPrmInst
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' .. P_Num, FP.WhichCC, true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ModPrmInst', Trk[TrkID].ModPrmInst, true)

            Trk.Prm.Assign = Trk[TrkID].ModPrmInst
        elseif FP.WhichMODs and string.find(FP.WhichMODs, tostring(AssigningMacro)) == nil then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            FP.WhichMODs = FP.WhichMODs .. tostring(AssigningMacro)
        end
        local CC = FP.WhichCC


        if not Trk.Prm.WhichMcros[CC .. TrkID] then
            Trk.Prm.WhichMcros[CC .. TrkID] = tostring(AssigningMacro)
        elseif Trk.Prm.WhichMcros[CC .. TrkID] and not string.find(Trk.Prm.WhichMcros[CC .. TrkID], tostring(AssigningMacro)) then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            Trk.Prm.WhichMcros[CC .. TrkID] = Trk.Prm.WhichMcros[CC .. TrkID] .. tostring(AssigningMacro)
        end
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods',FP.WhichMODs, true)


        r.gmem_write(6, CC)


        AssignToPrmNum = P_Num
        local whichMacroToJSFX  = AssigningMacro

        if AssigningMidiMod  then  whichMacroToJSFX = 0 end 

        r.gmem_write(5, whichMacroToJSFX) --tells jsfx which macro is user tweaking
        PrepareFXforModulation(FX_Idx, P_Num, FxGUID)
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.active", "1")   -- 1 active, 0 inactive
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.effect", "-100") -- -100 enables midi_msg*
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.param", "-1")   -- -1 not parameter link
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_bus", "15") -- 0 based, 15 = Bus 16
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_chan", "16") -- 0 based, 0 = Omni
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_msg", "176")   -- 176 is CC
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_msg2", CC) -- CC value
        r.gmem_write(3, Trk[TrkID].ModPrmInst)

        r.gmem_write(7, CC) --tells jsfx to rfetrieve P value

        r.gmem_write(JSFX.P_ORIG_V + CC, p_value ) -- JSFX.P_ORIG_V is a constant offset of 100000

    end
end
function If_Hvr_or_Macro_Active (FxGUID, M )
    if not FX[FxGUID].parent then return end 
    local cont_GUID = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent )
    if not cont_GUID then return end 
    if not  FX[cont_GUID].Mc then return end 
    local mc = FX[cont_GUID].Mc[M]
    local fx = FX[cont_GUID]
    if AssignContMacro == M-1 or ( fx.HvrMacro and  M == fx.HvrMacro) or mc.TweakingKnob == M then    
        return true    
    end 

    if fx.Highlight_Macro and  fx.Highlight_Macro == M then 
        return true 
    end 

end

function Find_Which_Mod_Is_Assigned(FP)
    for M, v in ipairs(MacroNums) do 
        if FP.ModAMT[M] and  FP.ModAMT[M]~= 0 then 

        end
    end
end

---@param FxGUID string
---@param Fx_P string|number
---@param FX_Idx integer
---@param P_Num number
---@param p_value number
---@param Sldr_Width number
---@param Type "Knob"|"Vert"
function MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, Type, trigger)
    local FP = FX[FxGUID][Fx_P]
    local CC = FP.WhichCC
    local RC = im.IsItemClicked(ctx, 1)
    r.gmem_attach('ParamValues')
    local Vertical = Type == 'Vert' and 'Vert' 
    if FP then  FP.ModBipolar = FP.ModBipolar or {} end 


    --if trigger == 'No Item Trigger' then RC = im.IsMouseClicked(ctx, 1) end 
    local RC = trigger == 'No Item Trigger' and im.IsMouseClicked(ctx, 1) or RC


    if --[[Link CC back when mouse is up]] Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then

        if FP.WhichCC  then
            local CC = FP.WhichCC 
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FP.V, true)
            r.gmem_write(7, CC) --tells jsfx to retrieve P value
            PM.TimeNow = r.time_precise()
            r.gmem_write(JSFX.P_ORIG_V + CC, p_value)
            ParameterMIDILink(FX_Idx, P_Num, 1, nil, 15, 16, 176, CC, nil)
        end
    end
    local function Mouse_Interaction_When_Theres_Mod_Assigned()


        if RC and FP.ModAMT and AssigningMacro == nil and (Mods == 0 or Mods == Alt) then
            for M, v in ipairs(MacroNums) do
                if FP.ModAMT[M] then
                    Trk.Prm.Assign = FP.WhichCC
                    AssigningMacro = M
                    r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                end
            end
            PM.DragOnModdedPrm = true

        elseif RC and FP.ModAMT and Mods == Shift and FP.WhichCC then

            for M, v in ipairs(MacroNums) do
               --[[  if FP.ModAMT[M] then
                    Trk.Prm.Assign = FP.WhichCC
                    BypassingMacro = M
                    r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                end ]]
            end
            --[[ DecideShortOrLongClick = FP
            Dur = im.GetMouseDownDuration(ctx, 1) ]]
        elseif RC and FP.ModAMT and Mods == Alt then
            for M, v in ipairs(MacroNums) do
                if FP.ModAMT[M] then
                    Trk.Prm.Assign = FP.WhichCC
                    AssigningMacro = M
                    r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)

                    --r.gmem_write(1000 * M + FP.WhichCC, (FP.ModAMT[M] or 0) +100 )   ---  if amount  is 100 ~ 101 then it's bipolar modulation
                end
            end
            PM.DragOnModdedPrm = true

        end


        ---- Short R-Click (+Shift) to disable mod
        if DecideShortOrLongClick == FP and Dur then
            if im.IsMouseReleased(ctx, 1) then
                if Dur < 0.14 then
                    ---- if short right click
                --[[     if FP.ModBypass then
                        r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                        r.gmem_write(6, FP.WhichCC)
                        r.gmem_write(1000 * BypassingMacro + FP.WhichCC, FP.ModAMT[BypassingMacro])
                        r.gmem_write(3, Trk[TrkID].ModPrmInst)
                        FP.ModBypass = nil
                    else
                        FP.ModBypass = BypassingMacro

                        r.gmem_write(5, BypassingMacro)                         --tells jsfx which macro is user tweaking
                        r.gmem_write(6, FP.WhichCC)
                        r.gmem_write(1000 * BypassingMacro + FP.WhichCC, 0) -- set mod amount to 0
                        r.gmem_write(3, Trk[TrkID].ModPrmInst)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', BypassingMacro, true)
                    end ]]
                else

                end


                DecideShortOrLongClick = nil
            end
            Dur = im.GetMouseDownDuration(ctx, 1)
        end

        if PM.DragOnModdedPrm == true and im.IsMouseDown(ctx, 1) ~= true then
            AssigningMacro = nil
            PM.DragOnModdedPrm = nil
        end
    end
    local function CalculateModAmt(ModAmt )
        local RightBtnDragX, RightBtnDragY = im.GetMouseDragDelta(ctx, x, y, 1); local MouseDrag 
        if Type =='Pro-Q' then RightBtnDragY = RightBtnDragY / 4 end 
        if Vertical == 'Vert' or Type == 'knob' or Type =='Pro-Q' then MouseDrag = -RightBtnDragY else MouseDrag = RightBtnDragX end

        ModAmt = ((MouseDrag / 100) or 0) + (ModAmt or 0)
       --[[  if ModAmt + p_value > 1 then ModAmt = 1 - p_value end
        if ModAmt + p_value < 0 then ModAmt = -p_value end ]]


        if Type == 'Pro-Q' then 
            local sc = (ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]  )
            local max = 0.5+ 1/sc/2
            local min = 0.5- 1/sc/2
            if ModAmt + p_value > max then ModAmt = max - p_value end
            if ModAmt + p_value < min then ModAmt = -( p_value-min) end
        end 
        im.ResetMouseDragDelta(ctx, 1)
        return ModAmt
    end 

    local function Right_Drag_To_Change_Mod_Amt ()
        if Trk.Prm.Assign and FP.WhichCC == Trk.Prm.Assign and AssigningMacro then -- assign Modulations
            local M = AssigningMacro
            local BipolarOut 

            FP.ModAMT[M] = SetMinMax( CalculateModAmt(FP.ModAMT[M]) , -1, 1 )

            if Mods == Alt and IsRBtnHeld then 
                -- FP.ModAMT[M] = math.abs( FP.ModAMT[M])
                BipolarOut =  FP.ModAMT[M]  + 100

                FP.ModBipolar[M] = true 
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar','true', true)
                r.gmem_write(4, 1)
                r.gmem_write(1000 * AssigningMacro + Trk.Prm.Assign, BipolarOut or  FP.ModAMT[M]) -- tells jsfx the param's mod amount

            elseif IsRBtnHeld and Mods == 0 then 

                FP.ModBipolar[M] = nil
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar','', true)
                r.gmem_write(4, 1)
                r.gmem_write(1000 * AssigningMacro + Trk.Prm.Assign,  FP.ModAMT[M]) -- tells jsfx the param's mod amount
            end
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Amt',FP.ModAMT[M], true)


        end
        if Trk.Prm.Assign and FP.WhichCC == Trk.Prm.Assign and AssigningMidiMod then 
            local M = AssigningMidiMod
            
            local jsfx_ofs 
            if AssigningMidiMod     == 'Velocity' then jsfx_ofs = JSFX.Velo_Mod
            elseif AssigningMidiMod == 'Random' then  jsfx_ofs = JSFX.Random1
            elseif AssigningMidiMod == 'KeyTrack' then jsfx_ofs = JSFX.KeyTrack1
            end

            Save_to_Trk('FX' .. FxGUID .. 'Prm' .. Fx_P.. ' Mod Amt for '.. AssigningMidiMod , FP.ModAMT[M]  )
            r.gmem_write(4, 1)
            r.gmem_write(5, jsfx_ofs + Trk.Prm.Assign)
            FP.ModAMT[M] = CalculateModAmt(FP.ModAMT[M])
            r.gmem_write(9, FP.ModAMT[M] ) -- tells jsfx the param's mod amount


        end




        if not IsRBtnHeld then 
            Trk.Prm.Assign = nil 
        end

    end

    local function If_User_Change_Track()

        if TrkID ~= TrkID_End then  -- if user changes track 
            r.gmem_write(3, Trk[TrkID].ModPrmInst or 0)
            if FP.ModAMT and FP.WhichCC then
                for M = 1, 8, 1 do
                    r.gmem_write(1000 * M + FP.WhichCC, FP.ModAMT[M] or 0)
                end
            end
        end
    end

    local function LOCAL_Draw_Mod_Lines()

        -- Draw Mod Lines
        if Type ~= 'knob' and Type ~= 'Pro-Q' and FP.ModAMT then
            local offset = 0
            if FP.ModAMT then 

                for M, v in pairs(FP.ModAMT) do
                    --- indicator of where the param is currently
                    FX[FxGUID][Fx_P].V = FX[FxGUID][Fx_P].V or  r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
                    local w = Sldr_Width
                    if Vertical == 'Vert' then w = ModLineDir or Sldr_Width end 
                    DrawModLines(M, true, 0, FxGUID, w,FX[FxGUID][Fx_P].V, Vertical, FP, offset, nil,nil,nil , true , FX_Idx)
                    Mc.V_Out[M] = (FP.ModAMT[M] * p_value)
                    ParamHasMod_Any = true
                    offset = offset + OffsetForMultipleMOD

                end -- of reapeat for every macro
            end

        end
    end

    local function MakeContainerModulationPossible ()
        if not FX[FxGUID].parent then return end
        local Cont_FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent )

        if AssignContMacro --[[ and Cont_FxGUID ==AssignContMacro_FxGuID ]]   then 
            
            local rv,ContID, Index = FindExactStringInTable(Trk[TrkID].Container_Id , AssignContMacro_FxGuID)
            
            Ct= FX[AssignContMacro_FxGuID]
            
            

            if  im.IsItemClicked(ctx, 1) then  -- when right click the prm
                
                Ct.ModPrm = Ct.ModPrm or  {}
                local rv, _, Cont_Mod_Prm_id = FindExactStringInTable(Ct.ModPrm , FxGUID.. ' , prm : '.. P_Num)
                if not rv  then 
                    table.insert(Ct.ModPrm,  FxGUID.. ' , prm : '.. P_Num)
                    Cont_Mod_Prm_id = #Ct.ModPrm
                end
                local CC = Cont_Mod_Prm_id
                FP.Cont_Which_CC =  CC
                FP.Cont_ModAMT = FP.Cont_ModAMT or {}
                ParameterMIDILink(FX_Idx, P_Num, 1, nil, 15+Index, 16, 176, CC, nil) -- 15+Index is midi bus
                
                r.gmem_attach('ContainerMacro')

                r.gmem_write(2, FX[Cont_FxGUID].DIY_FxGUID) --Sends Trk GUID for jsfx to determine track

                --r.gmem_write(JSFX.P_ORIG_V + Trk.Prm.Assign, ParamValue_Modding)
    
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P ..' Container Mod CC' , CC , true )
                r.gmem_write(7, CC) --tells jsfx to retrieve P value
                r.gmem_write(JSFX.P_ORIG_V + CC, p_value) -- tells jsfx the value before modulation
                AssigningCont_Prm_Mod = CC
            elseif  AssigningCont_Prm_Mod  then  -- when right dragging a prm
                local rv, _, Cont_Mod_Prm_id = FindExactStringInTable(Ct.ModPrm , FxGUID.. ' , prm : '.. P_Num)
                if AssigningCont_Prm_Mod == Cont_Mod_Prm_id then 

                    r.gmem_attach('ContainerMacro')
                    local M = AssignContMacro+1

                     r.gmem_write(4, 1) --  Gmem 4 sets jsfx's mode, mode 1 means user is assgining modulation to a param\
                    r.gmem_write(2, FX[Cont_FxGUID].DIY_FxGUID) --Sends diy FxGUID for jsfx to determine which Container


                    if Ct.ModPrm then r.gmem_write(3, #Ct.ModPrm) end  -- Tells jsfx how many modulated prms there are . (eg. if there are 5, then jsfx is sending CC1 ~ 5 and so on )
                    r.gmem_write(5, M) --tells jsfx which macro is user tweaking

                    r.gmem_write(6, AssigningCont_Prm_Mod)  -- this tells jsfx which CC (index of modulated prm in a container) is user tweaking
                    FP.Cont_ModAMT = FP.Cont_ModAMT or {}

                    FP.Cont_ModAMT[M] = CalculateModAmt(FP.Cont_ModAMT[M] )
                    r.gmem_write(1000 * M + AssigningCont_Prm_Mod,  FP.Cont_ModAMT[M]) -- tells jsfx the param's mod amount
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Container Mod Amt',FP.Cont_ModAMT[M], true)

                        -- Draw Mod Lines
                    
                    r.gmem_attach('')

                end
                
            end 

     
        end

        --Draw mod lines  CONTAINER
        if Type ~= 'knob' and Type ~= 'Pro-Q' and FP.Cont_ModAMT then
            local offset = 0
            for M, v in ipairs(MacroNums) do

                if FP.Cont_ModAMT[M] and FP.Cont_ModAMT[M] ~= 0 then--if Modulation has been assigned to params
                    --- indicator of where the param is currently
                    FP.V = FP.V or  r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
                    local clr = CustomColorsDefault.Container_Accent_Clr_Not_Focused
                    local cont_GUID = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent )
                    local mc = FX[cont_GUID].Mc[M]
                    if If_Hvr_or_Macro_Active (FxGUID, M) then 
                        clr = CustomColorsDefault.Container_Accent_Clr
                    end 

                    DrawModLines(M, true, mc.Val, FxGUID, ModLineDir or Sldr_Width,FP.V, Vertical, FP, offset, FP.Cont_ModAMT[M], clr, clr, true, FX_Idx)

                    Mc.V_Out[M] = (FP.Cont_ModAMT[M] * p_value)
                    ParamHasMod_Any = true
                    offset = offset + OffsetForMultipleMOD

                end
            end -- of reapeat for every macro
        end 

        if not IsRBtnHeld then AssigningCont_Prm_Mod = nil end 

        if --[[Link CC back when mouse is up]] FP.Cont_Which_CC and  Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then
            r.gmem_attach('ContainerMacro')

            local CC =  FP.Cont_Which_CC
            local bus_ofs = 0
            if FP.Cont_Which_CC then 
                local  guid = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent)
                    _,_, bus_ofs = FindExactStringInTable(Trk[TrkID].Container_Id , guid)
            end 
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FP.V, true)
            r.gmem_write(7, CC) --tells jsfx to retrieve P value
            PM.TimeNow = r.time_precise()
            r.gmem_write(JSFX.P_ORIG_V + CC, p_value)
            ParameterMIDILink(FX_Idx, P_Num, 1, nil, 15+(bus_ofs or 0 ), 16, 176, CC, nil)
        end
    end

    Mouse_Interaction_When_Theres_Mod_Assigned()

    if Type ~= 'Pro-Q' then 
        AssignMod (FxGUID, Fx_P, FX_Idx, P_Num, p_value, trigger)
    end

    If_User_Change_Track()

    Right_Drag_To_Change_Mod_Amt ()
    LOCAL_Draw_Mod_Lines()



    MakeContainerModulationPossible()
    
    if Tweaking == P_Num .. FxGUID and  IsLBtnHeld == false then 
        Tweaking = nil
    end 



    return Tweaking
end


    
        



function Get_LFO_Shape_From_File(filename)
    if filename then 


        local file = io.open(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes', filename), 'r')
        if file then 

            local L = get_lines(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes', filename))

            local content = file:read("a+")


            local Count = get_aftr_Equal_Num(L[1])
            local Node = {}



            for i= 1, Count or 0, 1 do 

                Node[i] = {}
                local N = Node[i] 
                --N.x = get_aftr_Equal_Num(content, i..'.x = ' )
                N.x = RecallGlobInfo(content , i..'.x = ', 'Num')

                N.y = RecallGlobInfo(content , i..'.y = ', 'Num')

                N.ctrlX = RecallGlobInfo(content , i..'.ctrlX = ' , "Num")

                N.ctrlY = RecallGlobInfo(content , i..'.ctrlY = ' , 'Num')

            end
            if Node[1] then 
                return Node
            end
        end
    end
end

function AutomateModPrm (Macro,str, jsfxMode, alias)
    Trk[TrkID].AutoPrms = Trk[TrkID].AutoPrms or {}
    if not FindExactStringInTable(Trk[TrkID].AutoPrms, 'Mod'.. Macro..str) then 
        table.insert(Trk[TrkID].AutoPrms, 'Mod'.. Macro..str)
        SetPrmAlias(LT_TrackNum, 1, 16+#Trk[TrkID].AutoPrms ,  alias)
        r.GetFXEnvelope(LT_Track, 0, 15+#Trk[TrkID].AutoPrms, true)
    end
    
    r.gmem_write(4, jsfxMode)  -- set mode to assigned mode
    r.gmem_write(5, Macro) 
    r.gmem_write(9, #Trk[TrkID].AutoPrms)
    
    for i, v in ipairs(Trk[TrkID].AutoPrms) do 
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Auto Mod'..i , v, true)
    end
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: How Many Automated Prm in Modulators' , #Trk[TrkID].AutoPrms, true)
end

function SetModulationToBipolar(Macro)
    r.gmem_write(4, 18) -- mode to set to bipolar 
    r.gmem_write(5, Macro)
end


function WhenRightClickOnModulators(Macro)
    if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
        im.CloseCurrentPopup(ctx)
        notHoverSEQ_Time = 999
        im.OpenPopup(ctx, 'Mod' .. Macro .. 'Menu')
    end
    if im.IsItemClicked(ctx, 1) and Mods == 0 then

        AssigningMacro = toggle(AssigningMacro , Macro)
        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then
            r.gmem_write(1, PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
            AddMacroJSFX()
        end
    end
    if im.IsItemClicked(ctx, 1) and Mods == Alt then
        SetModulationToBipolar(Macro)
    end


    if AssigningMacro==Macro then
        
         BlinkItem(0.3, nil, nil, 0xffffff88, EdgeNoBlink, nil, nil,nil,nil,nil,nil,0xffffff33) 

    end    
end



function When_RightClick_On_Midi_Modulators(lbl)
    if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
    elseif im.IsItemClicked(ctx, 1) and Mods == 0 then
        AssigningMidiMod = toggle(AssigningMidiMod, lbl)
    elseif im.IsItemClicked(ctx, 1) and Mods == Alt then
    end
    if AssigningMidiMod == lbl then 
        BlinkItem(0.3, nil, nil, 0xffffff88, EdgeNoBlink, nil, nil,nil,nil,nil,nil,0xffffff33) 
    end
end


function DrawLFOvalueTrail (MacroTable , x, y, Macro )
    local Pos = r.gmem_read(108+Macro)/4
    local M = MacroTable
    M.Trail = M.Trail or {}
    table.insert(M.Trail, { x = x ; y = y ; })

    if #M.Trail > 40 then table.remove(M.Trail, 1) end 



    for i, v in ipairs( M.Trail ) do 
        
        local ls = M.Trail[math.max(i-1, 1)]

        if v.x < ls.x then 
            

        elseif i > 2 then 
            local WDL = im.GetWindowDrawList(ctx)
            im.DrawList_AddLine(WDL, v.x , v.y , ls.x, ls.y, 0xffffff55, 8 - 16 / i )

        end 

    end


end

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
                Cont_Send_All_Coord()
            end
            local L, T = im.GetItemRectMin(ctx)
            local w, h = im.GetItemRectSize(ctx)
            im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff33)
            im.DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)

            Cont_DrawShape(v, L, w, h, T, 0xffffffaa)
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
end

local function get_Global_Shapes()
    local F = scandir(ConcatPath(CurrentDirectory, 'src', 'LFO Shapes'))
    local Shapes = {}
    for i, v in ipairs(F) do
        local Shape = Get_LFO_Shape_From_File(v)
        if Shape then

            Shape.Name = tostring(v):sub(0, -5)
            table.insert(Shapes, Shape)
        end
    end
    return Shapes
end
function Cont_ChangeLFO(mode, V, gmem, StrName,fx, Macro,FxGUID)

    r.gmem_attach('ContainerMacro')

    r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other

    r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
    r.gmem_write(5, Macro)    -- Tells jsfx which macro
    r.gmem_write(gmem or 9, V)

    if StrName then
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID.. 'Mod '.. Macro .. StrName, V, true)
        
    end
end

function DrawFollowerLine (mc, Macro, GmemAttach, clr)
    r.gmem_attach(GmemAttach or 'ParamValues')
    local MOD  = math.abs(SetMinMax((r.gmem_read(100 + Macro) or 0) / 127, -1, 1))
    local x , y = im.GetCursorScreenPos(ctx) 
    local x = im.GetItemRectMin (ctx)
    local _, y = im.GetItemRectMax(ctx)

    
    local SzX, SzY = im.GetItemRectSize(ctx)

    local DL = im.GetWindowDrawList(ctx )  

    local Y = y- 3 -MOD* SzY*0.9
    mc.FOL_PastY =  mc.FOL_PastY or {}
    --[[ 
        if GmemAttach then 
            x = x + SzX*0.9
        end 
    ]]


    for i, v in ipairs(mc.FOL_PastY) do 
        if i > 3 then
            im.DrawList_AddLine(DL, x+i , v, x+i - 1  ,  mc.FOL_PastY [i-1], clr or  0xffffffff, 1.5) 
        end 
    end 

    table.insert(mc.FOL_PastY, Y )
    if #mc.FOL_PastY > SzX then 
        table.remove(mc.FOL_PastY , 1 )
    end 
end     

function Add_BG_Text_For_Modulator(txt, indent)
    local X, Y = im.GetItemRectMin(ctx)

    im.DrawList_AddTextEx(WDL or im.GetWindowDrawList(ctx), _G['Arial Black'], 25, X + (indent or 0), Y, 0xffffff44, txt)

end

function Follower_Box(mc,i, sz, FxGUID, Gmem)
    if  mc.Type ~= 'Follower' then return end 
    local x , y = im.GetCursorScreenPos(ctx)
    --local sz = LFO_Box_Size
    local x = x - 10
    local I = i+1
    local WDL = WDL or im.GetWindowDrawList(ctx)
    local Gmem_Attach = Gmem
    local Popup_Pos_X , Popup_Pos_Y = im.GetCursorScreenPos(ctx)

    --im.SetCursorPosY(ctx, im.GetCursorPosY(ctx) )
   -- im.DrawList_AddRectFilled(WDL,x, y, x+sz,y+sz , 0x00000055)
    --im.DrawList_AddRect(WDL,x-1, y-1, x+sz +1 ,y+sz+1 , 0xffffff77)
    local rv = im.InvisibleButton(ctx, '## Track Follower Box'.. i.. FxGUID, sz*3,sz) 
    Add_BG_Text_For_Modulator('Follow', 20)
    
    if im.IsItemClicked(ctx,1 )then 
        mc.TweakingKnob = 2 
    elseif rv then 
        im.SetNextWindowPos(ctx, Popup_Pos_X -sz , Popup_Pos_Y - sz*1.5 )
        im.OpenPopup(ctx, 'Follower Window'..i..FxGUID)
    end 
    -- NotifyHoverState(I, im.IsItemHovered(ctx))
    local clr 
    if AssignContMacro == i and AssignContMacro_FxGuID == FxGUID then 
        if  RepeatAtInterval(0.3, nil) then
            clr = ThemeClr('Accent_Clr')
        end
    end 


    DrawFollowerLine (mc, i, Gmem_Attach, EightColors.LFO[i])

    if im.BeginPopup(ctx, 'Follower Window'..i..FxGUID)then 
        im.Text(ctx, 'Speed : ')
        SL()
        local m = Mc
        local CurX = im.GetCursorPosX(ctx)
        retval, m.Smooth = im.DragDouble(ctx, '##Smoothness', m.Smooth or 1, 1, 0, 300,'%.1f')


        if im.IsItemHovered(ctx) or im.IsItemActive(ctx) then
            HoveringSmoothness = i
        end
        local x, y = im.GetWindowPos(ctx)
        local w, h = im.GetWindowSize(ctx)


        if im.IsMouseHoveringRect(ctx, x, y, x + w, y + h) then
            notHoverFOL_Time = 0
            HoveringSmoothness = i
        end

        if retval then
            m.smooth = SetMinMax(0.1 ^ (1 - m.Smooth * 0.01), 0.1, 100)
            r.gmem_write(4, 10)       ---tells jsfx macro type = Follower, and user is adjusting smoothness
            r.gmem_write(5, i)        ---tells jsfx which macro
            r.gmem_write(9, m.smooth) -- Sets the smoothness
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Speed', m.Smooth, true)
        end

        --im.Text(ctx, ('S = ' .. (m.Smooth or '') .. 's= ' .. (m.smooth or '')))
        im.Text(ctx, 'Gain : ')
        SL(CurX)

        rv, m.Gain = im.DragDouble(ctx, '##Gain' .. i, m.Gain or 100, 1, 0, 400, '%.0f' .. '%%')
        if im.IsItemActive(ctx) then
            r.gmem_write(4, 11) ---tells jsfx macro type = Follower, and user is adjusting gain
            r.gmem_write(5, i)
            r.gmem_write(9, m.Gain / 100)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Gain',
                m.Gain,
                true)
        end

        if im.IsItemHovered(ctx) or im.IsItemActive(ctx) then HoveringSmoothness = i end


        im.EndPopup(ctx)
    end 

end 


function Cont_Send_All_Coord(fx, Macro, All_Coord, Mc, numb_of_Nodes)

    r.gmem_attach('ContainerMacro')

    for i, v in ipairs(All_Coord.X) do

        r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other
        r.gmem_write(5, Macro)
       
        r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates

        r.gmem_write(6, numb_of_Nodes or #Mc.Node * 11)
        r.gmem_write(1000 + i, v)
        r.gmem_write(2000 + i, All_Coord.Y[i])
    end

end
function Save_Shape_To_Project(Mc)
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

function Save_Shape_To_Track(Mc)
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

function Save_LFO_Dialog (Macro, x, y , Mc, FxGUID)

    local WinTitle = Macro 
    if FxGUID then -- if it's a container's LFO
        WinTitle = Macro..FxGUID 
        x, y = im.GetWindowPos(ctx)
        local sz = im.GetWindowSize(ctx)
        y = y + 50
    end 
    if LFO.OpenSaveDialog == WinTitle then
        im.OpenPopup(ctx, 'Decide Name')
        im.SetNextWindowPos(ctx, x, y)
        im.SetNextWindowFocus(ctx)

        if im.BeginPopupModal(ctx, 'Decide Name', true, im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then
            im.Text(ctx, 'Enter a name for the shape: ')
            --[[ im.Text(ctx, '(?)')
            if im.IsItemHovered(ctx) then
                tooltip('use / in file name to save into sub-directories')
            end ]]

            im.SetNextItemWidth(ctx, LFO.Def.DummyW)
            if im.IsWindowAppearing(ctx) then 
                im.SetKeyboardFocusHere(ctx)
            end
            local rv, buf = im.InputText(ctx, buf or '##Name', buf)
            im.Text(ctx,'Save to : ')
            SL()
            im.Button(ctx, 'Global (Enter)')
            if im.IsItemClicked(ctx) or ( im.IsKeyPressed(ctx, im.Key_Enter) and Mods == 0) then
                local LFO_Name = buf
                local path = ConcatPath(CurrentDirectory, 'src', 'LFO Shapes')
                local file_path = ConcatPath(path, LFO_Name .. '.ini')
                local file = io.open(file_path, 'w')


                for i, v in ipairs(Mc.Node) do
                    if i == 1 then
                        file:write('Total Number Of Nodes = ', #Mc.Node, '\n')
                    end
                    file:write(i, '.x = ', v.x, '\n')
                    file:write(i, '.y = ', v.y, '\n')
                    if v.ctrlX and v.ctrlY then
                        file:write(i, '.ctrlX = ', v.ctrlX, '\n')
                        file:write(i, '.ctrlY = ', v.ctrlY, '\n')
                    end
                    file:write('\n')
                end

                LFO.OpenSaveDialog = nil
                im.CloseCurrentPopup(ctx)
            end
            SL()
            if im.Button(ctx, 'Project') then
                Save_Shape_To_Project(Mc)
                LFO.OpenSaveDialog = nil
                im.CloseCurrentPopup(ctx)
            end
            SL()
            if im.Button(ctx, 'Track') then 
                Save_Shape_To_Track(Mc)
                LFO.OpenSaveDialog = nil
                im.CloseCurrentPopup(ctx)

            end 
            SL()
            im.Button(ctx, 'Cancel (Esc)')
            if im.IsItemClicked(ctx) or im.IsKeyPressed(ctx, im.Key_Escape) then
                im.CloseCurrentPopup(ctx)
                LFO.OpenSaveDialog = nil
            end



            im.EndPopup(ctx)
        end
    end
end
function SAVE_ALL_LFO_INFO(Node, FxGUID, Macro)
    local function SaveLFO(StrName, V)
        if StrName then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID.. 'Mod ' .. Macro .. StrName, V, true)
        end
    end
    for i, v in ipairs(Node) do


        SaveLFO('Node' .. i .. 'Ctrl X', Node[i].ctrlX  or '')
        SaveLFO('Node' .. i .. 'Ctrl Y', Node[i].ctrlY  or '')


        SaveLFO('Node ' .. i .. ' X', Node[i].x)
        SaveLFO('Node ' .. i .. ' Y', Node[i].y)
        SaveLFO('Total Number of Nodes', #Node)
    end
end

function LFO_Small_Shape_Selector(Mc, fx, macronum,FxGUID)
    local x , y  = im.GetCursorScreenPos(ctx)
    local Shapes = get_Global_Shapes()
    local Box_Sz = 50
    im.SetNextWindowPos(ctx, x - (Box_Sz)+18 , y -LFO_Box_Size- #Shapes * Box_Sz/2 )
    if im.BeginPopup(ctx, 'Small Shape Select'..macronum..FxGUID) then 
        if im.IsWindowAppearing(ctx) then
            LFO.NodeBeforePreview = Mc.Node
        end
        local AnyShapeHovered
        local Shapes = get_Global_Shapes()
        for i, v in pairs(Shapes) do
            local W = Box_Sz 
            local H = Box_Sz
            im.Button(ctx, '##' .. (v.Name or i) .. i, W, H)
            
            local L, T = im.GetItemRectMin(ctx)
            local w, h = im.GetItemRectSize(ctx)
            im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0x55555511)
            im.DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)
            v.AllCoord =  Cont_DrawShape(v, L, w, h, T, 0xffffffaa,2 , 'SaveAllCoord')
            if im.IsItemHovered(ctx) then
                Mc.Node = v
                AnyShapeHovered = true
                LFO.AnyShapeHovered = true
                Cont_Send_All_Coord(fx, macronum, v.AllCoord, Mc)
                if IsLBtnClicked then 
                    LFO.NewShapeChosen = v
                    SAVE_ALL_LFO_INFO(v, FxGUID,macronum)
                end
                --Cont_ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed',fx, macronum,FxGUID)
            end
        end
        if not im.IsWindowHovered(ctx) and not OpenSamllShapeSelect then
            im.CloseCurrentPopup(ctx)
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
        im.EndPopup(ctx)
    end 

end

        --check if there's envelope
        --[[  IsThereEnvOnMacro[i] = r.GetFXEnvelope(LT_Track, 0, i-1, false)
            Str_IsThereEnvOnMacro = tostring(IsThereEnvOnMacro[i])
            if Str_IsThereEnvOnMacro ~= 'nil'  then     --if theres env on macros, Sync Macro on Gui to Actual Values

                Mc.Val_Trk[MacroValueLBL]= r.TrackFX_GetParamNormalized( LT_Track, 0, i-1  )
                PosX_Left, PosY_Top = im.GetItemRectMin(ctx)
                Array_Parameter.PosX_Left[i]=PosX_Left
                Array_Parameter.PosY_Top[i]=PosY_Top
                drawlist=im.GetForegroundDrawList(ctx)
                MacroColor= 'Macro'..i..'Color'
                im.DrawList_AddCircleFilled(drawlist, Array_Parameter.PosX_Left[i], Array_Parameter.PosY_Top[i],4,_G[MacroColor])
            else IsThereEnvOnMacro[i]=0
            end ]]
function SetTypeToEnv(Mc, i)
    if Mc.Type  ~= 'env' then
        if im.Selectable(ctx, 'Envelope', false) then
            Mc.Type = 'env'
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'env', true)
            r.gmem_write(2,  PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 4) -- tells jsfx macro type = env
            r.gmem_write(5, i) -- tells jsfx which macro
        end
    end
end

function SetTypeToStepSEQ(Mc, i)
    if Mc.Type  ~= 'Step' then 
        if im.Selectable(ctx, 'Step Sequencer', false) then
            Mc.Type = 'Step'
            r.gmem_write(2,  PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 6) -- tells jsfx macro type = step seq
            r.gmem_write(5, i)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Step', true)
            Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
            Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
            Trk[TrkID].SEQL[i] = Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
            Trk[TrkID].SEQ_Dnom[i] = Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom

            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length',
                Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom, true)

            --if I.Name == 'Env ' .. i or I.Name == 'Macro ' .. i then I.Name = 'Step ' .. i end
        end
    end
end

function SetTypeToFollower(Mc, i)
    if Mc.Type  ~= 'Follower' then 
        if im.Selectable(ctx, 'Audio Follower', false) then
            AddMacroJSFX()
            r.gmem_write(2,  PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 9) -- tells jsfx macro type = Follower
            r.gmem_write(5, i) -- tells jsfx which macro
            Mc.Type = 'Follower'
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Follower', true)
        end
    end
end
function SetTypeToMacro(Mc, i )

    if Mc.Type  ~= 'Macro' then 
        if im.Selectable(ctx, 'Macro', false) then
            Mc.Type = 'Macro'
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Macro', true)
            r.gmem_write(2,  PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 5) -- tells jsfx macro type = Macro
            r.gmem_write(5, i) -- tells jsfx which macro
            --if I.Name == 'Env ' .. i then I.Name = 'Macro ' .. i end
        end
    end
end
function SetTypeToLFO(Mc, i)
    if Mc.Type == "LFO" then return end 
    if im.Selectable(ctx, 'LFO', false) then

        Mc.Type = 'LFO'
        AddMacroJSFX()
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod'..i .. 'Type', 'LFO', true)
        r.gmem_write(2,  PM.DIY_TrkID[TrkID])
        r.gmem_write(4, 12) -- tells jsfx macro type = LFO
        r.gmem_write(5, i)  -- tells jsfx which macro
       -- Mc.Name = 'LFO ' .. i

    end
end

function SetTypeToRandom(Mc, i)

    if Mc.Type  ~= 'Random' then 
        if im.Selectable(ctx, 'Random', false) then
            Mc.Type = 'Random'
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Random', true)
            r.gmem_write(2,  PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 27) -- tells jsfx macro type = Random
            r.gmem_write(5, i) -- tells jsfx which macro
        end
    end
end
function SetTypeToXY(Mc, i)

    if Mc.Type  ~= 'XY' then 
        if im.Selectable(ctx, 'XY', false) then
            Mc.Type = 'XY'
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'XY', true)
            r.gmem_write(2,  PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 28) -- tells jsfx macro type = XY
            r.gmem_write(5, i) -- tells jsfx which macro
        end
    end
end

function DrawLFOShape(Node, L, W, H, T, Clr, thick, SaveAllCoord, Macro )
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
                    
                    im.DrawList_AddLine(WDL or im.GetWindowDrawList(ctx), PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
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


function LFO_BOX(Mc, i, Width)
    if Mc.Type ~= 'LFO' then return end 
    local Macro = i

    local function ChangeLFO(mode, V, gmem, StrName)
        r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
        r.gmem_write(5, i)    -- Tells jsfx which macro
        r.gmem_write(gmem or 9, V)
        if StrName then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
        end
    end

    local function SaveLFO(StrName, V)
        if StrName then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
        end
    end
    local H    = Width/3
    local MOD  = math.abs(SetMinMax((r.gmem_read(100 + i) or 0) / 127, -1, 1))
    LFO.DummyH = LFO.Win.h + 20
    --LFO.DummyW  =  ( LFO.Win.w + 30) * ((Mc.LFO_leng or LFO.Def.Len)/4 )
    Mc.Freq    = Mc.Freq or 1
    Mc.Gain    = Mc.Gain or 5
    im.TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
    --[[  IsMacroSlidersEdited, I.Val = im.SliderDouble(ctx, i .. '##LFO', I.Val, Slider1Min or 0,
    Slider1Max or 1) ]]
    local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)


    --local W = (VP.w - 10) / 12 - 3 -- old W 
    local W = Width 
    local rv = im.InvisibleButton(ctx, 'LFO Button' .. i, W, H)
    Add_BG_Text_For_Modulator('LFO', 30)
    local w, h = im.GetItemRectSize(ctx)
    local L, T = im.GetItemRectMin(ctx)
    local WDL = im.GetWindowDrawList(ctx)
    local X_range = (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4)

    im.DrawList_AddRect(WDL, L, T , L + w , T + h, 0xFFFFFF22)


    if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
        im.OpenPopup(ctx, 'Macro' .. i .. 'Menu')
    elseif rv and Mods == 0 then
        if LFO.Pin == TrkID .. 'Macro = ' .. Macro then
            LFO.Pin = nil
        else
            LFO.Pin = TrkID .. 'Macro = ' .. Macro
        end
    end

    local function DrawShape(Node, L, W, H, T, Clr)
        if Node then
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

                for i, v in ipairs(PtsX) do
                    if i > 1 and PtsX[i] <= L + W then -- >1 because you need two points to draw a line
                        im.DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i], Clr or EightColors.LFO[Macro])
                    end
                end
            end
        end
    end

    --WhenRightClickOnModulators(Macro)
    local G = 1 -- Gap between Drawing Coord values retrieved from jsfx

    -- Draw Tiny Playhead
    local PlayPos = L + r.gmem_read(108 + i) / 4 * w / ((Mc.LFO_leng or LFO.Def.Len) / 4)
    im.DrawList_AddLine(WDL, PlayPos, T, PlayPos, T + h, EightColors.LFO[Macro], 1)
    im.DrawList_AddCircleFilled(WDL, PlayPos, T + h - MOD * h - 3 / 2, 3, EightColors.LFO[Macro])


    DrawLFOShape(Mc.Node, L, W, H, T,  nil, 3,nil, i )


    if rv and not LFO_DragDir and Mods == 0 then
        im.OpenPopup(ctx, 'LFO Shape Select')
        --im.SetNextWindowSize(ctx, LFO.Win.w  , LFO.Win.h+200)
    end



    function open_LFO_Win(Track, Macro)

        if LFO.EditWinOpen then return end 
        local tweaking
        local LFOWindowW
        -- im.SetNextWindowSize(ctx, LFO.Win.w +20 , LFO.Win.h + 50)
        im.SetNextWindowPos(ctx, HdrPosL, VP.Y - 385)
        if im.Begin(ctx, 'LFO Shape Edit Window' .. Macro, true, im.WindowFlags_NoDecoration + im.WindowFlags_AlwaysAutoResize) then
            local Node = Mc.Node
            local function ConverCtrlNodeY(lastY, Y)
                local Range = (math.max(lastY, Y) - math.min(lastY, Y))
                local NormV = (math.min(lastY, Y) + Range - Y) / Range
                local Bipolar = -1 + (NormV) * 2
                return NormV
            end



            --Mc.Node = Mc.Node or { x = {} , ctrlX = {}, y = {}  , ctrlY = {}}
            --[[ if not Node[i].x then
                table.insert(Node.x, L)
                table.insert(Node.x, L + 400)
                table.insert(Node.y, T + h / 2)
                table.insert(Node.y, T + h / 2)
            end ]]
            local BtnSz = 11

            LFO.Pin = PinIcon(LFO.Pin, TrkID .. 'Macro = ' .. Macro, BtnSz, 'LFO window pin' .. Macro, 0x00000000, ClrTint)
            SL()

            local WDL = im.GetWindowDrawList(ctx)
            local rv = im.Button(ctx, '## copy', 17, 17)
            DrawListButton(WDL, "0", 0x00000000, false, true, icon1_middle, false)
            TooltipUI("Copy LFO", im.HoveredFlags_Stationary)
            if rv then
                LFO.Clipboard = {}
                for i, v in ipairs(Node) do
                    LFO.Clipboard[i] = LFO.Clipboard[i] or {}
                    LFO.Clipboard[i].x = v.x
                    LFO.Clipboard[i].y = v.y
                end
            end

            SL()
            if not LFO.Clipboard then im.BeginDisabled(ctx) end
            --local rv = im.ImageButton(ctx, '## paste' .. Macro, Img.Paste, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint)
            local rv = im.Button(ctx, '## paste', 17, 17)
            DrawListButton(WDL, "1", 0x00000000, false, true, icon1_middle, false)
            TooltipUI("Paste LFO", im.HoveredFlags_Stationary)
            if rv then
                Mc.Node = LFO.Clipboard
                --[[ for i, v in ipairs(LFO.Clipboard) do
                    Mc.Node[i] = Mc.Node[i] or {}
                    Mc.Node[i].x = v.x
                    Mc.Node[i].y = v.y
                end ]]
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
                        local v = Mc.LFO_Legato and 1 or 0
                        ChangeLFO(21, v, nil, 'LFO_Legato')
                    end
                    im.SetNextItemWidth(ctx, 80)
                    local rv, low =  im.InputInt(ctx, 'Note Filter Low ', Mc.LowNoteFilter, 1 )  
                    if rv then 
                        Mc.LowNoteFilter = low 
                        ChangeLFO(22, low, 9, 'Note Filter Low')
                    end 

                    im.SetNextItemWidth(ctx, 80)
                    local rv, hi = im.InputInt(ctx, 'Note Filter High ', Mc.HighNoteFilter or 127 , 1  )  
                    if rv then 
                        ChangeLFO(22, hi, 10, 'Note Filter High')
                        
                        Mc.HighNoteFilter = hi
                    end 

                    im.EndCombo(ctx)
                end
            end


            SL(nil, 30)
            local rv = im.ImageButton(ctx, '## save' .. Macro, Img.Save, BtnSz, BtnSz, nil, nil, nil, nil,ClrBG,ClrTint)
            TooltipUI("Save LFO shape as preset", im.HoveredFlags_Stationary)
            if rv then
                LFO.OpenSaveDialog = Macro
            end

            SL()
            local rv = im.ImageButton(ctx, '## shape Preset' .. Macro, Img.Sine, BtnSz * 2, BtnSz, nil,
                nil, nil,
                nil, 0xffffff00, ClrTint)
            TooltipUI("Open Shape preset window", im.HoveredFlags_Stationary)
            if rv then
                if LFO.OpenShapeSelect then LFO.OpenShapeSelect = nil else LFO.OpenShapeSelect = Macro end
            end
            if LFO.OpenShapeSelect then Highlight_Itm(WDL, 0xffffff55) end


            im.Dummy(ctx, (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4), LFO.DummyH)
            --local old_Win_T, old_Win_B = VP.y - 320, VP.y - 20
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

            Mc.Node = Mc.Node or
                { { x = 0, y = 0 }, { x = 1, y = 1 } } -- create two default tables for first and last point
            local Node = Mc.Node


            local function GetNormV(i)
                local NormX = (Node[i].x - HdrPosL) / LFO.Win.w
                local NormY = (Win_B - Node[i].y) / h -- i think 3 is the window padding
                return NormX, NormY
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

            local Mc = Mc

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
                    Send_All_Coord()

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


            local PlayPosX = HdrPosL + r.gmem_read(108 + i) / 4 * LFO.Win.w

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
                    Send_All_Coord()
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

                function Send_All_Coord()
                    for i, v in ipairs(All_Coord.X) do
                        r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                        r.gmem_write(5, Macro)
                        r.gmem_write(6, #Mc.Node * 11)
                        r.gmem_write(1000 + i, v)
                        r.gmem_write(2000 + i, All_Coord.Y[i])
                    end
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
                Send_All_Coord()
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
            local rv, V = im.DragDouble(ctx, '##Speed', Mc.LFO_spd or 1, 0.05, 0.125, 128, 'x %.3f')
            if im.IsItemActive(ctx) or im.IsWindowAppearing(ctx) then
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



            if im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                LFO.WinHovered = Macro -- this one doesn't get cleared after unhovering, to inform script which one to stay open
                LFO.HvringWin = Macro
            else
                LFO.HvringWin = nil
                LFO.DontOpenNextFrame = true -- it's needed so the open_LFO_Win function doesn't get called twice when user 'unhover' the lfo window
            end

            if im.IsWindowAppearing(ctx) then
                Save_All_LFO_Info(Node)
            end
            if im.IsWindowAppearing(ctx) then
                Send_All_Coord()
            end
            LFOWindowW = im.GetWindowWidth(ctx)
            im.End(ctx)
        end


        if LFO.OpenShapeSelect == Macro then
            
            im.SetNextWindowPos(ctx, im.GetCursorScreenPos(ctx) +LFOWindowW , T - LFO.DummyH - 200)
            if not im.ValidatePtr(ShapeFilter, "ImGui_TextFilter*") then
                ShapeFilter = im.CreateTextFilter(Shape_Filter_Txt)
            end
            im.SetNextWindowSizeConstraints(ctx, 220, 150, 240, 700)
            if im.Begin(ctx, 'Shape Selection Popup', true, im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then
                local W, H = 150, 75
                local function DrawShapesInSelector(Shapes)
                    local AnyShapeHovered
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
                                Send_All_Coord()
                            end
                            local L, T = im.GetItemRectMin(ctx)
                            local w, h = im.GetItemRectSize(ctx)
                            im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff33)
                            im.DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)

                            DrawShape(v, L, w, h, T, 0xffffffaa)
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
                        Send_All_Coord()
                        NeedSendAllGmemLater = nil
                        timer = nil
                    end
                end

                local function Global_Shapes()
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

                    if im.TextFilter_Draw(ShapeFilter, ctx, '##PrmFilterTxt', -1) then
                        Shape_Filter_Txt = im.TextFilter_Get(ShapeFilter)
                        im.TextFilter_Set(ShapeFilter, Shape_Filter_Txt)
                    end




                    AnyShapeHovered = DrawShapesInSelector(Shapes)










                    if im.IsWindowFocused(ctx) and im.IsKeyPressed(ctx, im.Key_Escape) then
                        im.CloseCurrentPopup(ctx)
                        LFO.OpenShapeSelect = nil
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
                        Save_Shape_To_Project(Mc)
                    elseif LFO.OpenedTab == 'Track' then
                        Save_Shape_To_Track(Mc)
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


    local HvrOnBtn = im.IsItemHovered(ctx)
    local PinID = TrkID .. 'Macro = ' .. Macro
    if HvrOnBtn or LFO.HvringWin == Macro or LFO.Tweaking == Macro or LFO.Pin == PinID or LFO.OpenSaveDialog == Macro or LFO.HoveringShapeWin == Macro then
        LFO.notHvrTime = 0
        LFO.Tweaking = open_LFO_Win(Track, Macro)
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





    if not IsLBtnHeld then
        LFO_DragDir = nil
        LFO_MsX_Start, LFO_MsY_Start = nil
    end




    Save_LFO_Dialog (Macro, L, T - LFO.DummyH, Mc)

end

function XY_BOX(Mc, i, Width)
    if Mc.Type ~= 'XY' then return end 
    im.BeginGroup(ctx)
    
    --local W = (VP.w - 10) / 12 - 3 -- old W 
    local function PAD()
        local pd = 2
        local cX, cY = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, cX+ pd , cY + pd)
        local W = (Width or 60 ) / 3
        local H = (Width or 60)  /3
        local rv = im.InvisibleButton(ctx, 'LFO Button' .. i, W-pd*3, H-pd*3)
        local w, h = im.GetItemRectSize(ctx)
        local l, t = im.GetItemRectMin(ctx)
        draw_dotted_line(l+w/2 ,t, l+w/2, t+h, EightColors.LFO[i], 2, 2)
        draw_dotted_line(l ,t+h/2, l+w, t+h/2, EightColors.LFO[i], 2, 2)
        im.SetCursorPos(ctx, cX, cY)
        local WDL = im.GetWindowDrawList(ctx)

        local Sz = 3 
        local X = Sz + l+ (w-Sz*2) * (Mc.XY_Pad_X or 0) /127
        local Y = -Sz + t+h - (h-Sz*2) * (Mc.XY_Pad_Y or 0) /127
        im.DrawList_AddCircle(WDL, X , Y, Sz, EightColors.LFO[i])
        im.DrawList_AddCircleFilled(WDL, X , Y, Sz, EightColors.LFO[i])

        Highlight_Itm(WDL, nil, EightColors.LFO[i])
    end
    local function Open_Menu()
        if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
            im.OpenPopup(ctx, 'Mod' .. i .. 'Menu')
        end
    end

    local function PAD_INTERACTION()
        if im.IsItemActive(ctx) then        
            HideCursorTillMouseUp(0)
           local DtX, DtY = im.GetMouseDragDelta(ctx)
           Mc.XY_Pad_X = SetMinMax(Mc.XY_Pad_X + DtX, 0, 127)
           Mc.XY_Pad_Y = SetMinMax(Mc.XY_Pad_Y - DtY, 0, 127)  
           r.TrackFX_SetParamNormalized(LT_Track, 0, 25 + (i - 1) * 2, Mc.XY_Pad_X / 127)
           r.TrackFX_SetParamNormalized(LT_Track, 0, 26 + (i - 1) * 2, Mc.XY_Pad_Y / 127)

           if DtX ~= 0 or DtY ~= 0 then 
                im.ResetMouseDragDelta(ctx)
           end

        end
        Open_Menu()
    end
    local function Assign_Macro(X_or_Y)
        if im.IsItemClicked(ctx, 1) then

            if X_or_Y == 'X' then
                ASSIGNING_XY_PAD = 'X'
            elseif X_or_Y == 'Y' then
                ASSIGNING_XY_PAD = 'Y'
            end
        end 
        if ASSIGNING_XY_PAD then 
            if ASSIGNING_XY_PAD == 'X' then 
                r.gmem_write(9, 1 )
            elseif ASSIGNING_XY_PAD == 'Y' then 
                r.gmem_write(9, 2)
            end
        end
    end

    local function Drags()

        local flg = im.SliderFlags_NoInput
        im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, 0)
        local cX, cY = im.GetCursorPos(ctx)
        --im.Text(ctx, 'X :')
        im.SetNextItemWidth(ctx, Width/1.5)
        _, Mc.XY_Pad_X = im.DragDouble(ctx, '##X', Mc.XY_Pad_X or 0, 1, 0, 127, 'X : %.0f', flg)
        Assign_Macro('X')
        im.SetCursorPos(ctx, cX , cY + 15)
        im.SetNextItemWidth(ctx, Width/1.5)


        _, Mc.XY_Pad_Y = im.DragDouble(ctx, '##Y', Mc.XY_Pad_Y or 0, 1, 0, 127, 'Y : %.f', flg)
        Assign_Macro('Y')
        im.PopStyleVar(ctx)
        im.SetCursorPos(ctx, cX, cY)

    end

    PAD()
    PAD_INTERACTION()
    SL()
    Drags()
    im.EndGroup(ctx)
    Open_Menu()
    
end



function Create_Header_For_Track_Modulators()
    MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].Mod = Trk[TrkID].Mod or {}
    if not Trk[TrkID].ShowMOD then return end

    im.BeginTable(ctx, 'table1', 16, im.TableFlags_NoPadInnerX)
    SL()

    for m = 1, 16, 1 do
        if m == 1 or m == 3 or m == 5 or m == 7 or m == 9 or m == 11 or m == 13 or m == 15 then
            im.TableSetupColumn(ctx, '', im.TableColumnFlags_WidthStretch, 2)
        elseif m == 2 or m == 4 or m == 6 or m == 8 or m == 10 or m == 12 or m == 14 or m == 16 then
            local weight, flag
            if Trk[TrkID].Mod[m / 2] then
                if Trk[TrkID].Mod[m / 2].Type == 'Step' then
                    weight, flag = 0, im.TableColumnFlags_WidthFixed
                elseif Trk[TrkID].Mod[m / 2].Type == 'Follower' then 
                    weight, flag = 2, im.TableColumnFlags_WidthFixed
                end
            end
            im.TableSetupColumn(ctx, '', flag or im.TableColumnFlags_WidthStretch, weight or 1)
        end
    end

    im.PushStyleColor(ctx, im.Col_HeaderHovered, 0x373737ff)

    im.TableHeadersRow(ctx) --create header row
    r.gmem_attach('ParamValues')

    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].Mod = Trk[TrkID].Mod or {}


    

    if not FX_Dvs_BgDL then FX_Dvs_BgDL = im.GetWindowDrawList(ctx) end
    im.PopStyleColor(ctx, 1)
   




    for i, v in ipairs(MacroNums) do --Do 8 Times
        Mcro_Asgn_Md_Idx            = 'Macro' .. tostring(MacroNums[i])
        Trk[TrkID].Mod[i]           = Trk[TrkID].Mod[i] or {}
        local Mc                    = Trk[TrkID].Mod[i]
        local Macro                 = i

        local I, Name, CurX         = Mc, nil, im.GetCursorPosX(ctx)
        local frameBgColor          = im.ColorConvertHSVtoRGB((i - 1) / 7.0, 0.5, 0.5, 0.2)
        local frameBgHoveredColor   = im.ColorConvertHSVtoRGB((i - 1) / 7.0, 0.6, 0.5, 0.2)
        local frameBgActiveColor    = im.ColorConvertHSVtoRGB((i - 1) / 7.0, 0.7, 0.5, 0.2)
        local sliderGrabColor       = im.ColorConvertHSVtoRGB((i - 1) / 7.0, 0.9, 0.9, 0.2)
        local sliderGrabActiveColor = im.ColorConvertHSVtoRGB((i - 1) / 7.0, 0.9, 0.9, 0.8)
        im.PushID(ctx, i)
        local function PushClr(AssigningMacro)
            im.PushStyleColor(ctx, im.Col_FrameBg, EightColors.LowMidSat[i])
            im.PushStyleColor(ctx, im.Col_FrameBgHovered, EightColors.MidSat[i])
            im.PushStyleColor(ctx, im.Col_FrameBgActive, EightColors.Bright[i])
            im.PushStyleColor(ctx, im.Col_SliderGrab, EightColors.HighSat_MidBright[i])
            im.PushStyleColor(ctx, im.Col_SliderGrabActive, EightColors.Bright_HighSat[i])

            --[[ if AssigningMacro == i then
                im.PushStyleColor(ctx, im.Col_FrameBg, EightColors.HighSat_MidBright[i])
                im.PushStyleColor(ctx, im.Col_FrameBgHovered, EightColors.bgWhenAsgnModAct[i])
                PopColorTime = 2
            end ]]
            clrPop = 6

        end



        Mc.Type = Mc.Type or 'Macro'
        if Mc.Type == 'Macro' then
             PushClr(AssigningMacro)

            im.TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
            MacroX_Label = 'Macro' .. tostring(MacroNums[i])
            MacroValueLBL = TrkID .. 'Macro' .. MacroNums[i]

            im.PushItemWidth(ctx, -FLT_MIN)

            IsMacroSlidersEdited, I.Val = im.SliderDouble(ctx, i .. '##', I.Val, Slider1Min or 0, Slider1Max or 1)
            IsMacroActive = im.IsItemActive(ctx)
            if IsMacroActive then 
                Mc.AnyActive = true 
                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then
                    r.TrackFX_SetParamNormalized(LT_Track, 0, v - 1, I.Val)
                    r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID, I.Val)
                end
            end

            WhenRightClickOnModulators(i)
            

            --- Macro Label
            im.TableSetColumnIndex(ctx, MacroNums[i] * 2 - 1)
            im.PushStyleColor(ctx, im.Col_FrameBg, EightColors.LowSat[i])
            im.PushItemWidth(ctx, -FLT_MIN)
            MacroNameEdited, I.Name = im.InputText(ctx, '##', I.Name or 'Macro ' .. i)
            if MacroNameEdited then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name, true)
            end
            im.PopStyleColor(ctx, clrPop)
        elseif Mc.Type == 'env' then
            if Mods == Shift then DragSpeed = 0.0001 else DragSpeed = 0.01 end
            PushClr(AssigningMacro)
            im.TableSetColumnIndex(ctx, (i - 1) * 2)
            im.PushItemWidth(ctx, -FLT_MIN)
            im.SetNextItemWidth(ctx, 60)
            local Mc = Mc

            local atk, rel = Mc.atk, Mc.rel
            at, Mc.ATK = im.DragDouble(ctx, '## atk' .. i, Mc.ATK, DragSpeed, 0, 1, '',
                im.SliderFlags_NoInput)
            SL(nil, 0)
            RCat = im.IsItemClicked(ctx, 1)
            local L, T = im.GetItemRectMin(ctx)
            local W, H = im.GetItemRectSize(ctx)
            local R, B = L + W, T + H
            local Atk = Mc.atk
            if at then
                Mc.atk = 0.000001 ^ (1 - Mc.ATK)
                r.gmem_write(4, 2)                      -- tells jsfx user is adjusting atk
                r.gmem_write(9 + ((i - 1) * 2), Mc.atk) -- tells atk value
                r.gmem_write(5, i)                      -- tells which macro is being tweaked
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Atk', Mc.ATK, true)
            end
            if im.IsItemActive(ctx) then
                im.SetNextWindowPos(ctx, L, T - H - 10)
                im.BeginTooltip(ctx)
                local f = '%.1f'
                if Mods == Alt then f = '%.3f' end
                local num = (Mc.atk or 0.001) * 1000
                if num > 100 then f = '%.0f' end
                if num < 10 then f = '%.2f' end
                if num < 1 then f = '%.3f' end
                im.Text(ctx, (f):format(num))
                im.EndTooltip(ctx)
            end
            local WDL = im.GetWindowDrawList(ctx)
            im.DrawList_AddLine(WDL, L + W * Mc.ATK, T, R, T, 0xffffffff)
            im.DrawList_AddLine(WDL, L, B, L + W * Mc.ATK, T, 0xffffffff)

            if AssigningMacro == i then
                BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
            end

            im.SetNextItemWidth(ctx, 60)

            re, Mc.REL  = im.DragDouble(ctx, '## rel' .. i, Mc.REL, DragSpeed, 0.001, 1, '',
                im.SliderFlags_NoInput)
            local RCrel = im.IsItemClicked(ctx, 1)
            if re then
                --Mc.rel = 10^(rel or 0.001) /10
                Mc.rel = 0.001 ^ (1 - Mc.REL)
                r.gmem_write(4, 3)                       -- tells jsfx user is adjusting rel
                r.gmem_write(10 + ((i - 1) * 2), Mc.rel) -- tells rel value
                r.gmem_write(5, i)                       -- tells which macro is being tweaked
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Rel', Mc.REL, true)
            end
            if im.IsItemActive(ctx) then
                im.SetNextWindowPos(ctx, L, T - H - 30)
                im.BeginTooltip(ctx)
                im.Text(ctx, ('%.3f'):format(Mc.rel or 0.001))
                im.EndTooltip(ctx)
            end
            local L, T = im.GetItemRectMin(ctx)
            local W, H = im.GetItemRectSize(ctx)
            local R, B = L + W, T + H
            local Rel = Mc.rel or 0.001
            --im.DrawList_AddLine(Glob.FDL, L ,T,L+W*Rel,T, 0xffffffff)
            im.DrawList_AddLine(WDL, L, T, L + W * Mc.REL, B, 0xffffffff)
            
            im.TableSetColumnIndex(ctx, i * 2 - 1)
            im.PushItemWidth(ctx, -FLT_MIN)
            im.PushStyleColor(ctx, im.Col_FrameBg, EightColors.LowSat[i])
            if I.Name == 'Macro ' .. i then I.Name = 'Env ' .. i end
            MacroNameEdited, I.Name = im.InputText(ctx, '##', I.Name or 'Env ' .. i)
            if MacroNameEdited then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name,
                    true)
            end
            if (im.IsItemClicked(ctx, 1) or RCat or RCrel) and Mods == Ctrl then
                im.OpenPopup(ctx, 'Macro' .. i .. 'Menu')
            end





            if (RCat or RCrel) and not AssigningMacro and Mods == 0 then
                AssigningMacro = i
            elseif (RCat or RCrel) and AssigningMacro then
                AssigningMacro = nil
            end

            if LBtnREl then
                for i = 1, 16, 1 do
                    r.gmem_write(8 + i, 0)
                end
            end
            im.PopStyleColor(ctx, clrPop)
        elseif Mc.Type == 'Step' then
            
        elseif Mc.Type == 'Follower' then
            im.TableSetColumnIndex(ctx, (i - 1) * 2)
            im.PushItemWidth(ctx, -FLT_MIN)
            im.Button(ctx, '                       ')
            if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
                im.OpenPopup(ctx, 'Macro' .. i .. 'Menu')
            end
            WhenRightClickOnModulators(Macro)
            if im.IsItemHovered(ctx) then FolMacroHover = i end

            
            DrawFollowerLine (Mc, i)


            function openFollowerWin(Track, i)
                local HoveringSmoothness

                local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)

                im.SetNextWindowPos(ctx, HdrPosL, VP.Y - 55)
                im.SetNextWindowSize(ctx, 350, 55)
                if im.Begin(ctx, 'Follower Windowww' .. i, true, im.WindowFlags_NoResize + im.WindowFlags_NoDocking + im.WindowFlags_NoCollapse + im.WindowFlags_NoScrollbar + im.WindowFlags_NoTitleBar) then
                    im.Text(ctx, 'Speed : ')
                    SL()
                    local m = Mc
                    local CurX = im.GetCursorPosX(ctx)
                    retval, m.Smooth = im.DragDouble(ctx, '##Smoothness', m.Smooth or 1, 1, 0, 300,'%.1f')


                    if im.IsItemHovered(ctx) or im.IsItemActive(ctx) then
                        HoveringSmoothness = i
                    end
                    local x, y = im.GetWindowPos(ctx)
                    local w, h = im.GetWindowSize(ctx)


                    if im.IsMouseHoveringRect(ctx, x, y, x + w, y + h) then
                        notHoverFOL_Time = 0
                        HoveringSmoothness = i
                    end

                    if retval then
                        m.smooth = SetMinMax(0.1 ^ (1 - m.Smooth * 0.01), 0.1, 100)
                        r.gmem_write(4, 10)       ---tells jsfx macro type = Follower, and user is adjusting smoothness
                        r.gmem_write(5, i)        ---tells jsfx which macro
                        r.gmem_write(9, m.smooth) -- Sets the smoothness
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Speed',
                            m.Smooth,
                            true)
                    end

                    --im.Text(ctx, ('S = ' .. (m.Smooth or '') .. 's= ' .. (m.smooth or '')))
                    im.Text(ctx, 'Gain : ')
                    SL(CurX)

                    rv, m.Gain = im.DragDouble(ctx, '##Gain' .. i, m.Gain or 100, 1, 0, 400, '%.0f' .. '%%')
                    if im.IsItemActive(ctx) then
                        r.gmem_write(4, 11) ---tells jsfx macro type = Follower, and user is adjusting gain
                        r.gmem_write(5, i)
                        r.gmem_write(9, m.Gain / 100)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Gain',
                            m.Gain,
                            true)
                    end

                    if im.IsItemHovered(ctx) or im.IsItemActive(ctx) then HoveringSmoothness = i end

                    im.End(ctx)
                end


                return HoveringSmoothness
            end

            if HoveringSmoothness == i then
                HoveringSmoothness = openFollowerWin(Track, i)
            end

            if FolMacroHover == i and not HoveringSmoothness then
                local timeout = 20
                notHoverFOL_Time = math.min((notHoverFOL_Time or 0), timeout + 1) + 1
                if notHoverFOL_Time < timeout then
                    HoveringSmoothness = openFollowerWin(Track, i)
                else
                    HoveringSmoothness = openFollowerWin(Track, i)
                    FolMacroHover = nil
                    notHoverFOL_Time = 0
                end
            end
        elseif Mc.Type == 'LFO' then
            local function ChangeLFO(mode, V, gmem, StrName)
                r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
                r.gmem_write(5, i)    -- Tells jsfx which macro
                r.gmem_write(gmem or 9, V)
                if StrName then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
                end
            end

            local function SaveLFO(StrName, V)
                if StrName then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
                end
            end
            local H    = 20
            local MOD  = math.abs(SetMinMax((r.gmem_read(100 + i) or 0) / 127, -1, 1))
            LFO.DummyH = LFO.Win.h + 20
            --LFO.DummyW  =  ( LFO.Win.w + 30) * ((Mc.LFO_leng or LFO.Def.Len)/4 )
            Mc.Freq    = Mc.Freq or 1
            Mc.Gain    = Mc.Gain or 5
            im.TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
            --[[  IsMacroSlidersEdited, I.Val = im.SliderDouble(ctx, i .. '##LFO', I.Val, Slider1Min or 0,
            Slider1Max or 1) ]]

            local W = (VP.w - 10) / 12 - 3
            local rv = im.InvisibleButton(ctx, 'LFO Button' .. i, W, H)
            local w, h = im.GetItemRectSize(ctx)

            local L, T = im.GetItemRectMin(ctx)
            local WDL = im.GetWindowDrawList(ctx)
            local X_range = (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4)

            im.DrawList_AddRect(WDL, L, T - 2, L + w + 2, T + h, EightColors.LFO[i])



            if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
                im.OpenPopup(ctx, 'Macro' .. i .. 'Menu')
            elseif rv and Mods == 0 then
                if LFO.Pin == TrkID .. 'Macro = ' .. Macro then
                    LFO.Pin = nil
                else
                    LFO.Pin = TrkID .. 'Macro = ' .. Macro
                end
            end

            WhenRightClickOnModulators(Macro)
            local G = 1 -- Gap between Drawing Coord values retrieved from jsfx
            local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)
            

            -- Draw Tiny Playhead
            local PlayPos = L + r.gmem_read(108 + i) / 4 * w / ((Mc.LFO_leng or LFO.Def.Len) / 4)
            im.DrawList_AddLine(WDL, PlayPos, T, PlayPos, T + h, EightColors.LFO[Macro], 1)
            im.DrawList_AddCircleFilled(WDL, PlayPos, T + h - MOD * h - 3 / 2, 3, EightColors.LFO[Macro])

            DrawShape(Mc.Node, HdrPosL, w, h, T)


            if rv and not LFO_DragDir and Mods == 0 then
                im.OpenPopup(ctx, 'LFO Shape Select')
                --im.SetNextWindowSize(ctx, LFO.Win.w  , LFO.Win.h+200)
            end



            function open_LFO_Win(Track, Macro)

                if LFO.EditWinOpen then return end 
                local tweaking
                -- im.SetNextWindowSize(ctx, LFO.Win.w +20 , LFO.Win.h + 50)
                im.SetNextWindowPos(ctx, HdrPosL, VP.Y - 385)
                if im.Begin(ctx, 'LFO Shape Edit Window' .. Macro, true, im.WindowFlags_NoDecoration | im.WindowFlags_AlwaysAutoResize) then
                    local Node = Mc.Node
                    local function ConverCtrlNodeY(lastY, Y)
                        local Range = (math.max(lastY, Y) - math.min(lastY, Y))
                        local NormV = (math.min(lastY, Y) + Range - Y) / Range
                        local Bipolar = -1 + (NormV) * 2
                        return NormV
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
                        LFO.Clipboard = {}
                        for i, v in ipairs(Node) do
                            LFO.Clipboard[i] = LFO.Clipboard[i] or {}
                            LFO.Clipboard[i].x = v.x
                            LFO.Clipboard[i].y = v.y
                        end
                    end

                    SL()
                    if not LFO.Clipboard then im.BeginDisabled(ctx) end
                    --local rv = im.ImageButton(ctx, '## paste' .. Macro, Img.Paste, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint)
                    local rv = im.Button(ctx, '## paste', 17, 17)
                    DrawListButton(WDL, "1", 0x00000000, false, true, icon1_middle, false)
                    TooltipUI("Paste LFO", im.HoveredFlags_Stationary)
                    if rv then
                        Mc.Node = LFO.Clipboard
                        --[[ for i, v in ipairs(LFO.Clipboard) do
                            Mc.Node[i] = Mc.Node[i] or {}
                            Mc.Node[i].x = v.x
                            Mc.Node[i].y = v.y
                        end ]]
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
                                local v = Mc.LFO_Legato and 1 or 0
                                ChangeLFO(21, v, nil, 'LFO_Legato')
                            end
                            im.SetNextItemWidth(ctx, 80)
                            local rv, low =  im.InputInt(ctx, 'Note Filter Low ', Mc.LowNoteFilter, 1 )  
                            if rv then 
                                Mc.LowNoteFilter = low 
                                ChangeLFO(22, low, 9, 'Note Filter Low')
                            end 

                            im.SetNextItemWidth(ctx, 80)
                            local rv, hi = im.InputInt(ctx, 'Note Filter High ', Mc.HighNoteFilter or 127 , 1  )  
                            if rv then 
                                ChangeLFO(22, hi, 10, 'Note Filter High')
                                
                                Mc.HighNoteFilter = hi
                            end 

                            im.EndCombo(ctx)
                        end
                    end


                    SL(nil, 30)
                    local rv = im.ImageButton(ctx, '## save' .. Macro, Img.Save, BtnSz, BtnSz, nil, nil, nil, nil,ClrBG,ClrTint)
                    TooltipUI("Save LFO shape as preset", im.HoveredFlags_Stationary)
                    if rv then
                        LFO.OpenSaveDialog = Macro
                    end

                    SL()
                    local rv = im.ImageButton(ctx, '## shape Preset' .. Macro, Img.Sine, BtnSz * 2, BtnSz, nil, nil, nil, nil, 0xffffff00, ClrTint)
                    TooltipUI("Open Shape preset window", im.HoveredFlags_Stationary)
                    if rv then
                        if LFO.OpenShapeSelect then LFO.OpenShapeSelect = nil else LFO.OpenShapeSelect = Macro end
                    end
                    if LFO.OpenShapeSelect then Highlight_Itm(WDL, 0xffffff55) end


                    im.Dummy(ctx, (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4), LFO.DummyH)
                    --local old_Win_T, old_Win_B = VP.y - 320, VP.y - 20
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

                    Mc.Node = Mc.Node or
                        { { x = 0, y = 0 }, { x = 1, y = 1 } } -- create two default tables for first and last point
                    local Node = Mc.Node


                    local function GetNormV(i)
                        local NormX = (Node[i].x - HdrPosL) / LFO.Win.w
                        local NormY = (Win_B - Node[i].y) / h -- i think 3 is the window padding
                        return NormX, NormY
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

                    local Mc = Mc

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
                            Send_All_Coord()

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


                    local PlayPosX = HdrPosL + r.gmem_read(108 + i) / 4 * LFO.Win.w

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
                            Send_All_Coord()
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

                        function Send_All_Coord()
                            for i, v in ipairs(All_Coord.X) do
                                r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                                r.gmem_write(5, Macro)
                                r.gmem_write(6, #Mc.Node * 11)
                                r.gmem_write(1000 + i, v)
                                r.gmem_write(2000 + i, All_Coord.Y[i])
                            end
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
                        Send_All_Coord()
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
                    local rv, V = im.DragDouble(ctx, '##Speed', Mc.LFO_spd or 1, 0.05, 0.125, 128, 'x %.3f')
                    if im.IsItemActive(ctx) or im.IsWindowAppearing(ctx) then
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



                    if im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                        LFO.WinHovered = Macro -- this one doesn't get cleared after unhovering, to inform script which one to stay open
                        LFO.HvringWin = Macro
                    else
                        LFO.HvringWin = nil
                        LFO.DontOpenNextFrame = true -- it's needed so the open_LFO_Win function doesn't get called twice when user 'unhover' the lfo window
                    end

                    if im.IsWindowAppearing(ctx) then
                        Save_All_LFO_Info(Node)
                    end
                    if im.IsWindowAppearing(ctx) then
                        Send_All_Coord()
                    end
                    im.End(ctx)
                end


                if LFO.OpenShapeSelect == Macro then
                    im.SetNextWindowPos(ctx, L + LFO.DummyW + 30, T - LFO.DummyH - 200)
                    if not im.ValidatePtr(ShapeFilter, "ImGui_TextFilter*") then
                        ShapeFilter = im.CreateTextFilter(Shape_Filter_Txt)
                    end
                    im.SetNextWindowSizeConstraints(ctx, 220, 150, 240, 700)
                    if im.Begin(ctx, 'Shape Selection Popup', true, im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then
                        local W, H = 150, 75
                        local function DrawShapesInSelector(Shapes)
                            local AnyShapeHovered
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
                                        Send_All_Coord()
                                    end
                                    local L, T = im.GetItemRectMin(ctx)
                                    local w, h = im.GetItemRectSize(ctx)
                                    im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff33)
                                    im.DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)

                                    DrawShape(v, L, w, h, T, 0xffffffaa)
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
                                Send_All_Coord()
                                NeedSendAllGmemLater = nil
                                timer = nil
                            end
                        end

                        local function Global_Shapes()
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

                            if im.TextFilter_Draw(ShapeFilter, ctx, '##PrmFilterTxt', -1) then
                                Shape_Filter_Txt = im.TextFilter_Get(ShapeFilter)
                                im.TextFilter_Set(ShapeFilter, Shape_Filter_Txt)
                            end




                            AnyShapeHovered = DrawShapesInSelector(Shapes)










                            if im.IsWindowFocused(ctx) and im.IsKeyPressed(ctx, im.Key_Escape) then
                                im.CloseCurrentPopup(ctx)
                                LFO.OpenShapeSelect = nil
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
                                Save_Shape_To_Project(Mc)
                            elseif LFO.OpenedTab == 'Track' then
                                Save_Shape_To_Track(Mc)
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

            local HvrOnBtn = im.IsItemHovered(ctx)
            local PinID = TrkID .. 'Macro = ' .. Macro
            if HvrOnBtn or LFO.HvringWin == Macro or LFO.Tweaking == Macro or LFO.Pin == PinID or LFO.OpenSaveDialog == Macro or LFO.HoveringShapeWin == Macro then
                LFO.notHvrTime = 0
                LFO.Tweaking = open_LFO_Win(Track, Macro)
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





            if not IsLBtnHeld then
                LFO_DragDir = nil
                LFO_MsX_Start, LFO_MsY_Start = nil
            end



            Save_LFO_Dialog (Macro, L, T - LFO.DummyH, Mc)
        end


        local function Add_Type_Options()
            im.SeparatorText(ctx, 'Set Type to :')

            SetTypeToMacro()
            SetTypeToEnv()
            SetTypeToStepSEQ()
            SetTypeToFollower()
            SetTypeToLFO()
            SetTypeToRandom(Mc,i)
        end



        if im.BeginPopup(ctx, 'Macro' .. i .. 'Menu') then
            if im.Selectable(ctx, 'Automate', false) then
                AddMacroJSFX()
                -- Show Envelope for Morph Slider
                local env = r.GetFXEnvelope(LT_Track, 0, i - 1, false)    -- Check if envelope is on
                if env == nil then                                        -- Envelope is off
                    local env = r.GetFXEnvelope(LT_Track, 0, i - 1, true) -- true = Create envelope
                else                                                      -- Envelope is on
                    local rv, EnvelopeStateChunk = r.GetEnvelopeStateChunk(env, "", false)
                    if string.find(EnvelopeStateChunk, "VIS 1") then      -- VIS 1 = visible, VIS 0 = invisible
                        EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 1", "VIS 0")
                        r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                    else -- on but invisible
                        EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 0", "VIS 1")
                        r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                    end
                end
                SetPrmAlias(LT_TrackNum, 1, i, Mc.Name or ('Macro' .. i)) -- Change parameter name to alias
                r.TrackList_AdjustWindows(false)
                r.UpdateArrange()
            end
            Add_Type_Options()
            im.EndPopup(ctx)
        elseif im.BeginPopup(ctx, 'Env' .. i .. 'Menu') then
            Add_Type_Options()
            im.EndPopup(ctx)
        elseif im.BeginPopup(ctx, 'Step' .. i .. 'Menu') then
            Add_Type_Options()
            im.EndPopup(ctx)
        elseif im.BeginPopup(ctx, 'Follower' .. i .. 'Menu') then
            Add_Type_Options()
            im.EndPopup(ctx)
        elseif im.BeginPopup(ctx, 'LFO' .. i .. 'Menu') then
            Add_Type_Options()
            im.EndPopup(ctx)
        end


        im.PopID(ctx)
    end


    im.EndTable(ctx)


end

function MacroKnob(mc, i, Size , TB, ColumnID)
    local I = i +1
    local row = math.ceil ( I /4 )

    if mc.Type =='Macro' and ( TB and TB[1]  or TB =='Track') then 
        im.BeginGroup(ctx)
        mc.Val = mc.Val 
        local Macro_FXid = TB =='Track' and 0 or TB[1].addr_fxid
        local fx = fx or Trk[TrkID]
        local FxGUID = FxGUID or TrkID
        if TB =='Track' then
           -- im.TableSetColumnIndex(ctx, ColumnID)
        end
        local W = Size + Size*4 
        local x, y = im.GetCursorScreenPos(ctx)
        if MACRO_SZ then 
            im.DrawList_AddRectFilled(im.GetWindowDrawList(ctx), x , y , x+ MACRO_SZ[1], y + MACRO_SZ[2], ThemeClr('Track_Modulator_Individual_BG'))
        end

        local v = r.TrackFX_GetParamNormalized(LT_Track, Macro_FXid, i)
        mc.TweakingKnob , mc.Val , mc.center = AddKnob_Simple(ctx , FxGUID..'Macro'..i,  mc.Val or v, Size, -1, ThemeClr('Track_Modulator_Knob'), EightColors.LFO[i], EightColors.LFO[i] , EightColors.Bright_HighSat[i])
        if im.IsItemHovered(ctx) then 
            fx.HvrMacro =  i
            AnyMacroHovered = true 
        end
        Highlight_Itm(WDL, nil,0xffffff44)
        --im.SetNextItemWidth(ctx, Size*2.7)
        if TB =='Track' then
            SL(nil, 2)
        else
            im.SetCursorPos(ctx,35 + (Size*3 * (row-1)),  10+ (i-4*(row-1)) * (Size*2+25) + Size*1.6)
        end

        _,mc.Name =  r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod'..i..' Name', '', false)
        im.SetNextItemWidth(ctx , Size * 4)
        im.AlignTextToFramePadding(ctx)
        mc.Name = mc.Name == '' and  nil or mc.Name

        if mc.Name == '' then mc.Name = nil end 
        local rv, label = im.InputText(ctx, '##'..i, mc.Name or ( 'Mc ' .. i), im.InputTextFlags_AutoSelectAll)
        if rv then 
            mc.Name = label
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod'..i..' Name', label, true )
        end 

        if mc.TweakingKnob == 1  then 
            r.TrackFX_SetParamNormalized(LT_Track, Macro_FXid, i-1, mc.Val)
        end
        im.EndGroup(ctx)
       -- Highlight_Itm( WDL, EightColors.LFO[i], EightColors.LFO[i])
    end
end



function Random_Modulator_Box(Mc, i , Sz)
    if Mc.Type ~= 'Random' then return end
    local boxWidth, boxHeight = Sz, Sz/3
    local L, T = im.GetCursorScreenPos(ctx)
    local WinW, WinH = 100, 100 
    r.gmem_attach('ParamValues')
    local function Draw_Value_Histogram()
        local L, T = im.GetItemRectMin(ctx)
        local W, H = im.GetItemRectSize(ctx)
        
        Mc.Random_Pts = Mc.Random_Pts or  {}
        local v = r.gmem_read(100+ i)

        table.insert(Mc.Random_Pts , v )
        if #Mc.Random_Pts > W then
            table.remove(Mc.Random_Pts, 1)
        end
        local WDL = WDL or im.GetWindowDrawList(ctx)
        --- Draw Fill
        im.DrawList_PathLineTo(WDL, L, T+H)
        for i , v in ipairs(Mc.Random_Pts) do
            local x = L  + (i-1) --[[ * (W/#Mc.Random_Pts) ]]
            local y = (T+ H ) - (v * H)
            im.DrawList_PathLineTo(WDL, x, y)
        end
        if #Mc.Random_Pts < 100 then 
            im.DrawList_PathLineTo(WDL, L+#Mc.Random_Pts, T+H)
        else
            im.DrawList_PathLineTo(WDL, L+W, T+H)
        end
        im.DrawList_PathFillConcave(WDL, EightColors.HighSat_MidBright[i])
        im.DrawList_PathClear(WDL)


        -- Draw Line
        for i , v in ipairs(Mc.Random_Pts) do
            local x = L  + (i-1) --[[ * (W/#Mc.Random_Pts) ]]
            local y = (T+ H ) - (v * H)
            im.DrawList_PathLineTo(WDL, x, y)
        end
        im.DrawList_PathStroke(WDL, EightColors.LFO[i], nil, 2.5)

        im.DrawList_PathClear(WDL)
    end
    local function parameters(Open_Random_Mod)
        local function Change_Prop(mode, v )
            r.gmem_write(4, mode)
            r.gmem_write(8, v ) -- tells the value
        end
        im.SetNextWindowPos(ctx, L, T - WinH)
        if im.BeginPopup(ctx, "RandomModulatorPopup"..i, im.WindowFlags_NoDecoration | im.WindowFlags_AlwaysAutoResize) then
            
            r.gmem_write(5, i)  -- tells which modulator
            r.gmem_write(4, 27) -- tells jsfx the type is random
            im.Text(ctx, "Random Modulator Options")

            local rv , Random_Int = Drag_With_Bar(ctx, 'Interval', Mc.Random_Int or 200, 1 , 1 , 500, '%.f', flags, 0xffffff33)
            if rv then 
                Mc.Random_Int = SetMinMax(Random_Int  , 1 , 500)
                Change_Prop(27.1, Mc.Random_Int )
                Save_to_Trk('Random Interval for mod'.. i, Mc.Random_Int)
            end
            local rv , Random_Smooth = Drag_With_Bar(ctx, 'Smooth', Mc.Random_Smooth or 0, 1 , 0 , 100, '%.f %%', flags, 0xffffff33)
            if rv then 
                Mc.Random_Smooth = SetMinMax(Random_Smooth, 0 , 100)
                Change_Prop(27.2, Random_Smooth)
                Save_to_Trk('Random Smooth for mod'.. i, Mc.Random_Smooth)

            end
            local rv , Chance = Drag_With_Bar(ctx, 'Chance', Mc.Random_Chance or 100, 1 , 0 , 100, '%.f %%', flags, 0xffffff33)
            if rv then 
                Mc.Random_Chance = SetMinMax(Chance, 0 , 100)
                Change_Prop(27.3, Chance)
                Save_to_Trk('Random Chance for mod'.. i, Mc.Random_Chance)
            end

            im.EndPopup(ctx)
        end

    end
   
    im.InvisibleButton(ctx, "RandomModulatorBox", boxWidth, boxHeight)
    Add_BG_Text_For_Modulator('Random', 13)
    Draw_Value_Histogram()
    SL()
    if im.IsItemClicked(ctx, 0)then 
        im.OpenPopup(ctx, 'RandomModulatorPopup'.. i )

    end
    parameters(Open_Random_Mod)
    -- Draw a visible outline for the invisible button
    local drawList = im.GetWindowDrawList(ctx)
    im.DrawList_AddRect(drawList, L, T, L + boxWidth, T + boxHeight, 0xFFFFFF22)
end


function Create_Header_For_Track_Modulators__Squared_Modulators()
    MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].Mod = Trk[TrkID].Mod or {}
    if not Trk[TrkID].ShowMOD then return end
    local CurPosBefore = {im.GetCursorPos(ctx)}
    local LineHeight = 30
    im.PushStyleColor(ctx, im.Col_ChildBg, ThemeClr('Track_Modulator_Section_BG'))
    im.PushStyleColor(ctx, im.Col_Border, 0x555555ff)
    im.PushStyleVar( ctx, im.StyleVar_ChildBorderSize, 2)
    im.PushStyleVar( ctx, im.StyleVar_WindowPadding, 1,1)


    im.BeginChild(ctx, 'Modulation Bar', nil ,LineHeight + 5)

    local function Calc_How_Many_Columns()
        local num = 0
        for i, v in ipairs( MacroNums) do 
            local mc = Trk[TrkID].Mod[i]
            if mc.Type =='Macro' or not mc.Type then 
                num = num + 2
            else num = num + 1
            end
        end
        return num
    end
    local function SetUpColumns()
        for i, v in ipairs( MacroNums) do 
            local mc = Trk[TrkID].Mod[i]
            if mc.Type =='Macro' then 
                im.TableSetupColumn(ctx, '', im.TableColumnFlags_WidthFixed)
                im.TableSetupColumn(ctx, '', im.TableColumnFlags_WidthStretch)
            else 
                im.TableSetupColumn(ctx, '', im.TableColumnFlags_WidthStretch, 1 )
            end
        end
    end
    local function Show_Help_Msg()
        if im.IsItemHovered(ctx) then 
            HelperMsg.R = 'Set as Modulation Source'
            HelperMsg.Ctrl_R = 'Change Modulation Type'

        end
    end
    local function Show_Help_Msg_MIDI_MOD()
        if im.IsItemHovered(ctx) then 
            HelperMsg.R = 'Set as Modulation Source'
        end
    end
    local function Velo_Mod_Affect_Actual_Velocity_Option(lbl, tb)
        if  lbl ~= 'Velocity' then return end 
        im.Spacing(ctx)
        SL( ) im.Text(ctx, 'Affects Velocity Output :') SL()
        _, Trk[TrkID].Velo_Mod_Affect_Velocity = im.Checkbox(ctx, '##Affect velocity output', Trk[TrkID].Velo_Mod_Affect_Velocity)
    end

    local function Show_Midi_Modulations(lbl)
        local x, y = im.GetCursorScreenPos(ctx)
        local CurveEditorSz  = 300
        local AdditionalHeight = lbl == 'Velocity' and 20 or 0
        im.BeginGroup(ctx)
        im.Text(ctx, ' '.. lbl)
        SL()
        local click = im.ImageButton(ctx,  lbl..'Mod Icon', Img.ModulationArrow, LineHeight-3, LineHeight-3)
        im.EndGroup(ctx)
        Highlight_Itm(WDL, nil, 0xffffff77)
        HighlightHvredItem()
        Show_Help_Msg_MIDI_MOD()
        When_RightClick_On_Midi_Modulators(lbl)

        SL()
        if im.IsItemClicked(ctx) then 
            im.OpenPopup(ctx, lbl ..'option win')
            im.SetNextWindowPos(ctx, x-CurveEditorSz/3, y-CurveEditorSz - im.GetTextLineHeight(ctx) -10 -AdditionalHeight )
        end
        if im.BeginPopup(ctx, lbl..'option win', im.WindowFlags_NoMove) then
            local T = Trk[TrkID]
            T[lbl..'Curve'] = T[lbl..'Curve'] or {}
            Velo_Mod_Affect_Actual_Velocity_Option(lbl, T[lbl..'Curve'])
            local x, y = im.GetCursorScreenPos(ctx)
            T[lbl..'Curve']  = CurveEditor(CurveEditorSz,CurveEditorSz,  T[lbl..'Curve'], lbl  )
            im.EndPopup(ctx)
            
        end
    end
    local function Add_More_Modulators_Button()
        local clr = 0xffffff55
        local sz = 30
        local X, Y =  im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, X , Y + 1 )

        --[[ if im.InvisibleButton(ctx, 'add more modulator', LineHeight, LineHeight) then 

        end
        local L , T = im.GetItemRectMin(ctx)
        local W , H = im.GetItemRectSize(ctx)
        im.DrawList_AddTextEx(im.GetWindowDrawList(ctx) ,Arial_20 , 20 ,  L+W /3 , T+H/4 ,0xffffff55, '+' ) ]]

        im.PushFont(ctx, Arial_14)
        im.PushStyleColor(ctx, im.Col_Button, 0x00000000)
        im.Button(ctx, ' +'..'##Add modulator btn', sz, sz)
        im.PopStyleColor(ctx)
        im.PopFont(ctx) 
        local clr = im.IsItemHovered(ctx) and 0xffffff99 or  0xffffff55






        HighlightSelectedItem(nil, clr, nil,nil,nil,nil,nil,nil,nil)
        
    end

    for i= 1 , 8, 1 do 

        local I = i
        Trk[TrkID].Mod[I] = Trk[TrkID].Mod[I] or {}
        local mc = Trk[TrkID].Mod[I]
        local FxGUID = TrkID
        mc.TweakingKnob = nil
        mc.Type = mc.Type or r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod'.. I .. 'Type', '', false) or 'Macro'
        local Macro = i
        --[[  if not mc.Type then 
            _, mc.Type = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. I .. 'Type', '', false)

            if mc.Type == '' then mc.Type = 'Macro' end 
        end ]]

        local function If_Macro_Is_StepSEQ()
            if mc.Type~='Step' then return end 
            Macros_WDL = Macros_WDL or im.GetWindowDrawList(ctx)
            im.TableSetColumnIndex(ctx, (i - 1) * 2) --im.PushItemWidth( ctx, -FLT_MIN)
            local Mc = mc
            r.gmem_attach('ParamValues')
            local CurrentPos = r.gmem_read(108 + Macro) + 1 --  +1 because to make zero-based start on 1

    
            --im.SetNextItemWidth(ctx, 20)
            Mc.SEQ  = Mc.SEQ or {}
            local S                = Mc.SEQ
    
            Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
            Trk[TrkID].SEQ_Dnom    = Trk[TrkID].SEQ_Dnom or {}
    
            local HoverOnAnyStep
            local SmallSEQActive
            local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)
            local len = Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
            im.BeginGroup(ctx)
            for St = 1, len, 1 do -- create all steps
                local W = (VP.w - 10) / 12
                local L, T = im.GetCursorScreenPos(ctx)
                local H = LineHeight
                --[[ if St == 1 and AssigningMacro == i then
                    local W = (VP.w - 10) / 12
                    BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink, L, T, L + W, T + H, H, W)
                    --HighlightSelectedItem(0xffffff77,0xffffff33, 0, L,T,L+W,T+H,H,W, 1, 1,GetItemRect, Foreground)
                end ]]
                --_, S[St]= im.DragDouble(ctx, '##SEQ '..St ,  S[St], 0 ,0, 1, ' ',im.SliderFlags_NoInput)
                im.InvisibleButton(ctx, '##SEQ' .. St .. TrkID, W / len, H)
                local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx); local w, h =
                    im.GetItemRectSize(ctx)
                local FillClr = 0x00000000
    
    
    
                SEQ_Popup_L = SEQ_Popup_L or L
                SEQ_Popup_T = SEQ_Popup_T or T
    
                if im.IsItemHovered(ctx) and not im.IsMouseDown(ctx, 0) then
                    HoverOnAnyStep = true
                end
                if HoverOnAnyStep then WhichMacroIsHovered = i end
    
    
                if im.IsItemHovered(ctx) then FillClr = 0xffffff22 end
                HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1, GetItemRect,
                    Foreground)
    
    
    
                S[St] = SetMinMax(S[St] or 0, 0, 1)
                if im.IsItemActive(ctx) then
                    local _, v = im.GetMouseDelta(ctx, nil, nil)
    
                    if Mods == Shift then DrgSpdMod = 4 end
                    if v ~= 0 then
                        v = v * (-1)
                        if not (S[St] == 1 and v > 0) and not (S[St] == 0 and v < 0) then
                            S[St] = S[St] + v / 100
                            r.gmem_write(4, 7)                                   -- tells jsfx user is changing a step's value
                            r.gmem_write(5, i)                                   -- tells which macro user is tweaking
                            r.gmem_write(112, SetMinMax(S[St], 0, 1) * (-1) + 1) -- tells the step's value
                            r.gmem_write(113, St)                                -- tells which step
                        end
                        im.ResetMouseDragDelta(ctx)
                    end
                    SmallSEQActive = true
                elseif im.IsItemDeactivated(ctx) then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', S[St], true)
                end
               --WhenRightClickOnModulators(Macro)
    
    
    
                local W, H = im.GetItemRectSize(ctx)
                local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)
                if im.IsItemActive(ctx) then
                    Clr = EightColors.Bright_HighSat[i]
                elseif im.IsItemHovered(ctx) then
                    Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                end
    
    
                im.DrawList_AddRectFilled(Macros_WDL, L, T + H, L + W - 1, math.max(B - H * (S[St] or 0), T),
                    Clr)
                if CurrentPos == St then -- if Step SEQ 'playhead' is now on current step
                    im.DrawList_AddRect(Macros_WDL, L, T + H, L + W - 1, T, 0xffffff99)
                end
                SL(nil, 0)
            end
            im.EndGroup(ctx)
    
    
            im.SetNextWindowPos(ctx, HdrPosL, VP.Y - StepSEQ_H - 100)
            if Mc.AdjustingSteps and not im.IsMouseDown(ctx, 0) then Mc.AdjustingSteps = nil end
    
            function open_SEQ_Win(Track, i)
                
                if not HoveringSmoothness then
                    if im.Begin(ctx, 'SEQ Window' .. i, true, im.WindowFlags_NoResize + im.WindowFlags_NoDocking + im.WindowFlags_NoCollapse + im.WindowFlags_NoTitleBar + im.WindowFlags_AlwaysAutoResize) then
                        local WDL = im.GetWindowDrawList(ctx)
                        im.Text(ctx, 'Sequence Length : ')
                        local function writeSEQDNom()
                            if AddMacroJSFX() then
                                r.gmem_write(4, 8) --[[tells JSFX user is tweaking seq length or DNom]]
                                r.gmem_write(5, i) --[[tells JSFX the macro]]
                                r.gmem_write(10, Trk[TrkID].SEQ_Dnom[i])
                                r.gmem_write(9, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                                    Trk[TrkID].SEQ_Dnom[i], true)
                            end
                        end
    
                        local function writeSEQGmem()
                            if AddMacroJSFX() then
                                r.gmem_write(4, 8)
                                r.gmem_write(5, i)
                                r.gmem_write(9, Trk[TrkID].SEQL[i])
                                r.gmem_write(10, Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom)
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Length',
                                    Trk[TrkID].SEQL[i], true)
                            end
                        end
    
    
    
                        Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
                        rv, Trk[TrkID].SEQL[i] = im.SliderInt(ctx, '##' .. 'Macro' .. i .. 'SEQ Length',
                            Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 2, 64)
                        if im.IsItemActive(ctx) then writeSEQGmem() end
                        SL()
                        if im.Button(ctx, 'x2##' .. i) then
                            Trk[TrkID].SEQL[i] = math.floor((Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) * 2)
                            writeSEQGmem()
                        end
                        SL()
                        if im.Button(ctx, '/2##' .. i) then
                            Trk[TrkID].SEQL[i] = math.floor((Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) / 2)
                            writeSEQGmem()
                        end
    
                        im.Text(ctx, 'Step Length : ')
                        if im.Button(ctx, '2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 0.125
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 0.125 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        SL()
                        if im.Button(ctx, '1 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 0.25
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 0.25 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        SL()
                        if im.Button(ctx, '1/2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 0.5
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 0.5 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        SL()
                        if im.Button(ctx, '1/4 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 1
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 1 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        SL()
                        if im.Button(ctx, '1/8 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 2
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 2 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        SL()
                        if im.Button(ctx, '1/16 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 4
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 4 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        SL()
                        if im.Button(ctx, '1/32 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 8
                            writeSEQDNom()
                        end
                        SL()
                        if Trk[TrkID].SEQ_Dnom[i] == 8 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        if im.Button(ctx, '1/64 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            Trk[TrkID].SEQ_Dnom[i] = 16
                            writeSEQDNom()
                        end
                        if Trk[TrkID].SEQ_Dnom[i] == 16 then
                            HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
    
    
                        local MsX, MsY = im.GetMousePos(ctx)
                        for St = 1, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do
                            im.InvisibleButton(ctx, '##SEQ' .. St .. TrkID, StepSEQ_W, StepSEQ_H)
                            local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx); local w, h =
                                im.GetItemRectSize(ctx)
                            im.DrawList_AddText(WDL, L + StepSEQ_W / 2 / 2, B - 15, 0x999999ff, St)
                            SL(nil, 0)
                            local FillClr = 0x00000000
    
                            if im.IsItemClicked(ctx) then
                                Mc.AdjustingSteps = Macro
                            end
                            local AdjustingStep
                            if Mc.AdjustingSteps and MsX >= L and MsX < R then
                                AdjustingStep = St
                            end
    
    
                            if AdjustingStep == St then
                                --Calculate Value at Mouse pos
                                local MsX, MsY = im.GetMousePos(ctx)
    
                                S[St] = SetMinMax(((B - MsY) / StepSEQ_H), 0, 1) --[[ *(-1) ]]
                                r.gmem_write(4, 7)                        -- tells jsfx user is changing a step's value
                                r.gmem_write(5, i)                        -- tells which macro user is tweaking
                                r.gmem_write(112, SetMinMax(S[St], 0, 1)) -- tells the step's value
                                r.gmem_write(113, St)                     -- tells which step
    
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', S[St], true)
                            elseif IsRBtnHeld and im.IsMouseHoveringRect(ctx, L, T, R, B) and not SmallSEQActive then
                                SEQ_RMB_Val = 0
                                S[St] = SEQ_RMB_Val
                                r.gmem_write(4, 7)             -- tells jsfx user is changing a step's value
                                r.gmem_write(5, i)             -- tells which macro user is tweaking
                                r.gmem_write(112, SEQ_RMB_Val) -- tells the step's value
                                r.gmem_write(113, St)          -- tells which step
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', SEQ_RMB_Val, true)
                            end
                            local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)
    
                            if im.IsItemHovered(ctx, im.HoveredFlags_RectOnly) and not SmallSEQActive then
                                FillClr = 0xffffff22
                                Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                            end
                            HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1,
                                GetItemRect, Foreground)
    
    
    
                            im.DrawList_AddRectFilled(WDL, L, T + StepSEQ_H, L + StepSEQ_W - 1,
                                math.max(B - StepSEQ_H * (S[St] or 0), T), Clr)
    
                            if CurrentPos == St or (CurrentPos == 0 and St == (Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)) then -- if Step SEQ 'playhead' is now on current step
                                im.DrawList_AddRect(WDL, L, B, L + StepSEQ_W - 1, T, 0xffffff88)
                            end
                        end
    
    
    
    
                        local x, y = im.GetWindowPos(ctx)
                        local w, h = im.GetWindowSize(ctx)
    
    
                        if im.IsMouseHoveringRect(ctx, x, y, x + w, y + h) then notHoverSEQ_Time = 0 end
    
                        im.End(ctx)
                    end
                end
            end
    
            if (WhichMacroIsHovered == Macro and HoverOnAnyStep) or SmallSEQActive or Mc.AdjustingSteps then
                open_SEQ_Win(Track, Macro)
                notHoverSEQ_Time = 0
            end
    
            if WhichMacroIsHovered == i and not HoverOnAnyStep and not SmallSEQActive and not Mc.AdjustingSteps then
                notHoverSEQ_Time = math.min((notHoverSEQ_Time or 0), 11) + 1
                if notHoverSEQ_Time < 10 then
                    open_SEQ_Win(Track, i)
                else
                    WhichMacroIsHovered = nil
                    notHoverSEQ_Time = 0
                end
            end
        end

        --[[ mc.Gain = tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Gain','', false)))
        mc.Smooth =tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Speed','',false))) ]]


        --im.SetCursorPos(ctx,45 + (Size*3 * (row-1)),  10+ (i-4*(row-1) ) * (Size*2+25))
        local ItmSz=98
        MacroKnob(mc,i, LineHeight /1.85,'Track' , ColumnID)

        LFO_BOX(mc, i  , ItmSz )
        Follower_Box(mc,i , ItmSz/3, TrkID, 'ParamValues')
        Random_Modulator_Box(mc, i , ItmSz )
        XY_BOX(mc, i , ItmSz)

        If_Macro_Is_StepSEQ()
        WhenRightClickOnModulators(i) -- this has to be before step SEQ because the rightclick function is within step seq function
        Show_Help_Msg()
        --[[ LFO_Box(mc,i)
        Follower_Box(mc,i)
        StepSeq_Box(mc,i) ]]

        HighlightSelectedItem(nil, 0xffffff33 , 7 , nil,nil,nil,nil,nil,nil, 1,1,'GetItemRect', nil, 2,2)

        SL()
        im.SetNextWindowPos(ctx, im.GetCursorScreenPos(ctx))

        if im.BeginPopup(ctx, 'Mod' .. i .. 'Menu') then
            
            if mc.Type == 'Macro' then 
                if im.Selectable(ctx, 'Automate', false) then
                    AddMacroJSFX()
                    -- Show Envelope for Morph Slider
                    local env = r.GetFXEnvelope(LT_Track, 0, i - 1, false)    -- Check if envelope is on
                    if env == nil then                                        -- Envelope is off
                        local env = r.GetFXEnvelope(LT_Track, 0, i - 1, true) -- true = Create envelope
                    else                                                      -- Envelope is on
                        local rv, EnvelopeStateChunk = r.GetEnvelopeStateChunk(env, "", false)
                        if string.find(EnvelopeStateChunk, "VIS 1") then      -- VIS 1 = visible, VIS 0 = invisible
                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 1", "VIS 0")
                            r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                        else -- on but invisible
                            EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 0", "VIS 1")
                            r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                        end
                    end
                    SetPrmAlias(LT_TrackNum, 1, i, Mc.Name or ('Macro' .. i)) -- Change parameter name to alias
                    r.TrackList_AdjustWindows(false)
                    r.UpdateArrange()
                end
            end
            im.SeparatorText(ctx, 'Set Type to :')

            SetTypeToMacro(mc, i)
           -- SetTypeToEnv(mc, i)
            SetTypeToStepSEQ(mc, i)
            SetTypeToFollower(mc, i)
            SetTypeToLFO(mc, i)
            SetTypeToRandom(mc, i )
            SetTypeToXY(mc, i)
            im.EndPopup(ctx)
        end
    end

    SL()
    Add_More_Modulators_Button()
    SL()
    Show_Midi_Modulations('Velocity')
    Show_Midi_Modulations('Random')
    Show_Midi_Modulations('KeyTrack')


    im.PopStyleColor(ctx , 2 ) -- for child bg and border
    im.PopStyleVar(ctx, 2) -- for child border size
    --im.SetCursorPos(ctx, CurPosBefore[1], CurPosBefore[2]+ LineHeight)
    im.EndChild(ctx)
end 





function Create_Diy_TrkID_If_None_Exist()

    if PM.DIY_TrkID[TrkID] == nil then

        r.gmem_attach('ParamValues')
        r.gmem_write(4, 0.1 )-- tells it's inserting jsfx
        PM.DIY_TrkID[TrkID] = math.random(100000000, 999999999)
        Save_to_Trk( 'Track GUID Number for jsfx'  , PM.DIY_TrkID[TrkID] )
    end 

end


function Prm_Modulation_tooltip_Win(FP)
    if  im.IsItemHovered(ctx) then 
        if not FP.WhichCC then return end
        im.BeginTooltip(ctx)
        Simple_CurveEditor()
        im.EndTooltip(ctx)
    end
end


function Show_Modulator_Control_Panel(pos,FP)
    if not USE_MOD_CONTROL_POPUP then return end 
    if not FP.WhichCC then return end 
    if im.IsItemActive(ctx) then return end
    if (not im.IsItemHovered(ctx) and not (Mod_Control_Win_Hvr == FP.Num)  ) then return  end 
    
    local sz = 50
    local winSz = {sz, sz*1}
    local It = 0
    local Hvr_Win
    local PrmSz = {im.GetItemRectSize(ctx)}

    Mod_Control_Win_Hvr = Mod_Control_Win_Hvr or FP.Num 
    local Need_Create_Win = {}
    for i , v in ipairs(MacroNums) do 
        if FP.ModAMT and FP.ModAMT[i] then 
            table.insert(Need_Create_Win, i)
        end
    end





    for i , v in ipairs(MacroNums) do 

        if FP.ModAMT and FP.ModAMT[i] then 
            FP.Mod_Curve = FP.Mod_Curve or {}

            local xP = pos[1]+PrmSz[1]/2  +  (It)*sz   -( (#Need_Create_Win) * sz/2)

            im.SetNextWindowPos(ctx, xP , pos[2]-sz*1 - 5)
            im.SetNextWindowSize(ctx, winSz[1], winSz[2])
            im.PushStyleVar(ctx, im.StyleVar_WindowPadding, 0,0)
            im.Begin(ctx, 'Modulation Bar'..i.. 'Prm = '..FP.Num, true,  im.WindowFlags_NoDecoration)
            local Clr = EightColors.Bright_HighSat[i]
            local SzW , SzH = im.GetWindowSize(ctx)
            local WinX, WinY = im.GetWindowPos(ctx)
            local WDL = im.GetForegroundDrawList(ctx)
            local Curve_Scale = 5

            local function Show_Mod_Amt_Txt_If_Dragging()
                if SHOW_MOD_RANGE_NUMBER then 
                    local x , y = im.GetItemRectMin(ctx)
                    local w, h = im.GetItemRectSize(ctx)
                    local sz = sz/2
                    local WDL = im.GetWindowDrawList(ctx)      
                    local str = roundUp( FP.ModAMT[i] * 100 , 1)
                    local TxtSz = im.CalcTextSize(ctx, str)

                    im.DrawList_AddTextEx(WDL, _G['Arial Black'], 17,  x+w/2 - TxtSz / 2 , y+sz/1.5, 0xffffff99, str )
                end
            end
            local function Keep_Win_Open_If_Hvr_Or_Active (rv)
                local keep_open = im.IsMouseHoveringRect( ctx,WinX, WinY , WinX + SzW, WinY + SzH) 
                    or (rv and rv~= 0 )
                    or SHOW_MOD_RANGE_NUMBER 
                    or FP.Left_Dragging_Mod_Ctrl

                if keep_open  then 
                    Mod_Control_Win_Hvr = FP.Num 
                    Hvr_Win = true 
                end 
            end
            local function Show_Mod_Curve(rv)
                if SHOW_MOD_RANGE_NUMBER then return end 
                local pd = 3
                local X , nY = im.GetItemRectMin(ctx)
                local nX , Y = im.GetItemRectMax(ctx)
                local W, H = nX - X , Y - nY
                local nX = nX - W / pd
                local X = X + W / pd
                local nY = nY + H / pd
                local Y = Y - H / pd
                local clr = Clr -- Clr is modulator clr
                local clr = rv and Clr or 0xffffff99 
                local Cv = (FP.Mod_Curve[i] or 0) * (Curve_Scale/2)
                local clr =  (Cv <-0.05 and Cv>0.05)  and Change_Clr_A( Clr, -0.15 ) or clr
                Draw_Single_Curve(nX, X, nY, Y, Cv , 3 , clr, 0)
            end
            local function Knob_Interaction(rv)
                FP.Left_Dragging_Mod_Ctrl = nil 
                if rv==1  then  -- left drag to change curve of modulation
                    FP.Left_Dragging_Mod_Ctrl = true
                    local _, Dt = im.GetMouseDragDelta(ctx)
                    if Dt > 1 or Dt < -1 then 
                        FP.Mod_Curve[i] = SetMinMax ((FP.Mod_Curve[i] or 0) +  Dt/  (sz/2)    , -Curve_Scale, Curve_Scale )
                        Save_to_Trk('Mod_Curve_for_Mod'..i..'Prm ='..FP.WhichCC ,  FP.Mod_Curve[i], LT_Track)
                        local norm=  FP.Mod_Curve[i]
                        r.gmem_write( 4 , 26) -- set mode = 4, which means user is adjusting mod curve
                        r.gmem_write( 5, i) -- tells which modulator
                        r.gmem_write( 6, FP.WhichCC) -- tells which track param
                        r.gmem_write( 8 , norm) -- curve is an offset of 200000
                        im.ResetMouseDragDelta(ctx)
                    end
                    
                elseif rv == 2 then 
                    HideCursorTillMouseUp(1)
                    rv = 'Right-Dragging' 
                    AssigningMacro = i 
                    Trk.Prm.Assign = FP.WhichCC

                    SHOW_MOD_RANGE_NUMBER = true
                    r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                end
                if SHOW_MOD_RANGE_NUMBER and  not IsRBtnHeld then 
                    AssigningMacro = nil 

                    SHOW_MOD_RANGE_NUMBER = nil 
                end    

                
            end



            local RV, val , center= AddKnob_Simple(ctx, 'Mod'..i , FP.ModAMT[i] ,  sz/2 , knobSizeOfs, nil, nil, nil, Clr , 'Mod Range Control', FP)
            Show_Mod_Curve(RV)
            Show_Mod_Amt_Txt_If_Dragging()
            Knob_Interaction(RV)
            Keep_Win_Open_If_Hvr_Or_Active(RV)
            im.End(ctx)
            im.PopStyleVar(ctx)

            It = It + 1
        end
    end

    if not Hvr_Win then 

        Mod_Control_NOT_HVR_TIME = (Mod_Control_NOT_HVR_TIME or 0 )+1 
        

        if Mod_Control_NOT_HVR_TIME > 10 then
            Mod_Control_Win_Hvr = false
            Mod_Control_NOT_HVR_TIME = 0 
        end
    end

end