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
    local SldrGrabPos,ModAmt
    local BipOfs = 0
    local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx)
    local SizeX, SizeY = im.GetItemRectSize(ctx)
    MacroModLineOffset = 0

   -- im.DrawListSplitter_SetCurrentChannel(FX[FxGUID].splitter,2)


    if Amt then ModAmt = Amt 
    else ModAmt =  FP.ModAMT[Macro]
    end 

    if FP and Amt then
        FP.ModBipolar = FP.ModBipolar or {}
        if FP.ModBipolar[Macro] then
            ModAmt = Amt
            BipOfs = -Amt
        end
    end

    if Vertical ~= 'Vert' then
        PosX_End_Of_Slider = (Sldr_Width) + L
        SldrGrabPos = SizeX * P_V
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


    local Midsat, MidBright =RangeClr or  EightColors.MidSat[Macro], IndicClr or EightColors.HighSat_MidBright[Macro]
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
                ModPosWithAmt = math.max(B - (v * Sldr_Width ) - BipOfs * Sldr_Width or 0, PosX_End_Of_Slider)
                im.DrawList_AddRectFilled(drawlist, L, SliderCurPos, R, ModPosWithAmt or SliderCurPos, Midsat,Rounding)
            else 
                ModPosWithAmt = math.min(L + (v * Sldr_Width ) + BipOfs * Sldr_Width or 0, PosX_End_Of_Slider)
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
    r.gmem_write(11000 + Trk.Prm.Assign, ParamValue_Modding)
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

function AssignMod (FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, Type, trigger)
    local FP = FX[FxGUID][Fx_P]
    local RC = im.IsItemClicked(ctx, 1)
    if FP then  FP.ModBipolar = FP.ModBipolar or {} end 


    if trigger == 'No Item Trigger' then RC = im.IsMouseClicked(ctx, 1) end 
    if --[[Assign Mod]] AssigningMacro and RC then
        local _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation','', false)
        if not ValBeforeMod then
            r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FX[FxGUID][Fx_P].V, true)
        end


        Trk.Prm.Assign = FP.WhichCC 



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

        --r.SetProjExtState(0, 'FX Devices', 'Prm'..F_Tp..'Has Which Macro Assigned, TrkID ='..TrkID, Trk.Prm.WhichMcros[F_Tp..TrkID])
        --[[ r.gmem_write(7, CC) --tells jsfx to retrieve P value
        r.gmem_write(11000 + CC, p_value) ]]

        r.gmem_write(6, CC)


        AssignToPrmNum = P_Num

        r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
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

        if FP.ModBipolar[M] then  --if it's bipolar 
            r.gmem_write(11000 + CC, p_value )  -- sends parameter's value before being modulated
        else            -- if not bipolar 
            r.gmem_write(11000 + CC, p_value)
        end 
    end
end
function If_Hvr_or_Macro_Active (FxGUID, M )
    if not FX[FxGUID].parent then return end 
    local cont_GUID = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent )
    if not cont_GUID then return end 
    local mc = FX[cont_GUID].Mc[M]
    local fx = FX[cont_GUID]
    if AssignContMacro == M-1 or ( fx.HvrMacro and  M == fx.HvrMacro) or mc.TweakingKnob == M then    
        return true    
    end 

    if fx.Highlight_Macro and  fx.Highlight_Macro == M then 
        return true 
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

    if trigger == 'No Item Trigger' then RC = im.IsMouseClicked(ctx, 1) end 

    if --[[Link CC back when mouse is up]] Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then

        if FP.WhichCC  then
            local CC = FP.WhichCC 
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FP.V, true)
            r.gmem_write(7, CC) --tells jsfx to retrieve P value
            PM.TimeNow = r.time_precise()
            r.gmem_write(11000 + CC, p_value)
            ParameterMIDILink(FX_Idx, P_Num, 1, nil, 15, 16, 176, CC, nil)
        end
    end


    if RC and FP.ModAMT and AssigningMacro == nil and (Mods == 0 or Mods == Alt) then
        for M, v in ipairs(MacroNums) do
            if FP.ModAMT[M] then
                Trk.Prm.Assign = FP.WhichCC
                AssigningMacro = M
                r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
                r.gmem_write(6, FP.WhichCC)
            end
            PM.DragOnModdedPrm = true
        end
    elseif RC and FP.ModAMT and Mods == Shift and FP.WhichCC then

        for M, v in ipairs(MacroNums) do
            if FP.ModAMT[M] then
                Trk.Prm.Assign = FP.WhichCC
                BypassingMacro = M
                r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                r.gmem_write(6, FP.WhichCC)
            end
        end
        DecideShortOrLongClick = FP
        Dur = im.GetMouseDownDuration(ctx, 1)
    --[[ elseif RC and FP.ModAMT and Mods == Alt then
        r.gmem_write(1000 * AssigningMacro + FP.WhichCC, (FP.ModAMT[M] or 0) +100 ) ]]  ---  if amount  is 100 ~ 101 then it's bipolar modulation
    end

    if DecideShortOrLongClick == FP and Dur then
        if im.IsMouseReleased(ctx, 1) then
            if Dur < 0.14 then
                ---- if short right click
                if FP.ModBypass then
                    r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                    r.gmem_write(1000 * BypassingMacro + Trk.Prm.Assign, FP.ModAMT[BypassingMacro])
                    r.gmem_write(3, Trk[TrkID].ModPrmInst)
                    FP.ModBypass = nil
                else
                    FP.ModBypass = BypassingMacro
                    r.gmem_write(5, BypassingMacro)                         --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                    r.gmem_write(1000 * BypassingMacro + Trk.Prm.Assign, 0) -- set mod amount to 0
                    r.gmem_write(3, Trk[TrkID].ModPrmInst)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', BypassingMacro, true)
                end
            else

            end


            DecideShortOrLongClick = nil
        end
        Dur = im.GetMouseDownDuration(ctx, 1)
    end


    if Type ~= 'Pro-Q' then 
        AssignMod (FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, Type, trigger)
    end


    if PM.DragOnModdedPrm == true and im.IsMouseDown(ctx, 1) ~= true then
        AssigningMacro = nil
        PM.DragOnModdedPrm = nil
    end

    if TrkID ~= TrkID_End then  -- if user changes track ? 
        r.gmem_write(3, Trk[TrkID].ModPrmInst or 0)
        if FP.ModAMT and FP.WhichCC then
            for M = 1, 8, 1 do
                r.gmem_write(1000 * M + FP.WhichCC, FP.ModAMT[M] or 0)
            end
        end
    end
    local function CalculateModAmt(ModAmt )
        local RightBtnDragX, RightBtnDragY = im.GetMouseDragDelta(ctx, x, y, 1); local MouseDrag 
        if Type =='Pro-Q' then RightBtnDragY = RightBtnDragY / 4 end 
        if Vertical == 'Vert' or Type == 'knob' or Type =='Pro-Q' then MouseDrag = -RightBtnDragY else MouseDrag = RightBtnDragX end

        ModAmt = ((MouseDrag / 100) or 0) + (ModAmt or 0)
        if ModAmt + p_value > 1 then ModAmt = 1 - p_value end
        if ModAmt + p_value < 0 then ModAmt = -p_value end
        

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
    local Vertical
    if Type == 'Vert' then Vertical = 'Vert' end
    if FP then  FP.ModBipolar = FP.ModBipolar or {} end 
    if --[[Right Dragging to adjust Mod Amt]] Trk.Prm.Assign and FP.WhichCC == Trk.Prm.Assign and AssigningMacro then
        local Id = FxGUID .. Trk.Prm.Assign
        local M = AssigningMacro
        local IdM = 'Param:' .. tostring(Trk.Prm.Assign) .. 'Macro:' .. AssigningMacro

        --[[ function Show_Mod_Range_Value() 
            if FP.ModAMT and  FP.ModAMT[M] then 
                if RC then 

                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.active", "0") 
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0  )
                    _, V_Before = r.TrackFX_GetFormattedParamValue(LT_Track,FX_Idx, P_Num)
                    --r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.active", "1") 
                end 

                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, p_value+FP.ModAMT[M] )

                local rv, V_After = r.TrackFX_GetFormattedParamValue(LT_Track,FX_Idx, P_Num)
                
                im.BeginTooltip(ctx)
                im.SetTooltip(ctx, (V_Before or '' ).. ' ~ '.. (V_After or ''))
                im.EndTooltip(ctx)

            end 
        end 
        Show_Mod_Range_Value()  ]]


        local sizeX, sizeY = im.GetItemRectSize(ctx)


        FP.ModAMT[M] = CalculateModAmt(FP.ModAMT[M])
         


        local BipolarOut 
        if Mods == Alt and IsRBtnHeld then 
            FP.ModAMT[M] = math.abs( FP.ModAMT[M])
            BipolarOut = FP.ModAMT[M]  + 100

            FP.ModBipolar[M] = true 
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar','true', true)
            r.gmem_write(4, 1)
            r.gmem_write(1000 * AssigningMacro + Trk.Prm.Assign, BipolarOut or  FP.ModAMT[M]) -- tells jsfx the param's mod amount

        elseif IsRBtnHeld and Mods == 0 then 
            FP.ModBipolar[M] = nil
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar','', true)
            r.gmem_write(4, 1)
            r.gmem_write(1000 * AssigningMacro + Trk.Prm.Assign,  FP.ModAMT[M]) -- tells jsfx the param's mod amount
        elseif not IsRBtnHeld then 
            Trk.Prm.Assign = nil 
       
        end


        --if not IsLBtnHeld then r.gmem_write(4, 1) end --tells jsfx that user is changing Macro Mod Amount
        

        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Amt',FP.ModAMT[M], true)
    end


    -- Draw Mod Lines
    if Type ~= 'knob' and Type ~= 'Pro-Q' and FP.ModAMT then
        local offset = 0
        for M, v in ipairs(MacroNums) do
            if FP.ModAMT[M] and FP.ModAMT[M] ~= 0 then--if Modulation has been assigned to params

                --- indicator of where the param is currently
                FX[FxGUID][Fx_P].V = FX[FxGUID][Fx_P].V or  r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

               local w = Sldr_Width
               if Vertical == 'Vert' then w = ModLineDir or Sldr_Width end 
                DrawModLines(M, true, Trk[TrkID].Mod[M].Val, FxGUID, w,FX[FxGUID][Fx_P].V, Vertical, FP, offset, nil,nil,nil,true , FX_Idx)
                Mc.V_Out[M] = (FP.ModAMT[M] * p_value)
                ParamHasMod_Any = true
                offset = offset + OffsetForMultipleMOD
            end
        end -- of reapeat for every macro
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

                --r.gmem_write(11000 + Trk.Prm.Assign, ParamValue_Modding)
    
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P ..' Container Mod CC' , CC , true )
                r.gmem_write(7, CC) --tells jsfx to retrieve P value
                r.gmem_write(11000 + CC, p_value) -- tells jsfx the value before modulation
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

                    DrawModLines(M, true, mc.Val, FxGUID, ModLineDir or Sldr_Width,FP.V, Vertical, FP, offset, FP.Cont_ModAMT[M], clr, clr, true,FX_Idx)

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
            r.gmem_write(11000 + CC, p_value)
            ParameterMIDILink(FX_Idx, P_Num, 1, nil, 15+(bus_ofs or 0 ), 16, 176, CC, nil)
        end
    end
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
        im.OpenPopup(ctx, Trk[TrkID].Mod[Macro].Type .. Macro .. 'Menu')
    end
    if im.IsItemClicked(ctx, 1) and Mods == 0 then
        if not AssigningMacro then AssigningMacro = Macro
        else AssigningMacro = nil
        end
    end
    if im.IsItemClicked(ctx, 1) and Mods == Alt then
        SetModulationToBipolar(Macro)
    end
    if AssigningMacro==Macro then BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink) end 
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
    local DL = im.GetWindowDrawList(ctx )  
    local SzX, SzY = im.GetItemRectSize(ctx)
    local Y = y- 3 -MOD*SzY
    mc.FOL_PastY =  mc.FOL_PastY or {}

    if GmemAttach then 
        x = x + SzX*0.9
    end 



    for i, v in ipairs(mc.FOL_PastY) do 
        if i > 3 then 
            im.DrawList_AddLine(DL, x+i ,  v, x+i - 1  ,  mc.FOL_PastY [i-1], clr or  0xffffffff, 1.5) 
        end 
    end 

    table.insert(mc.FOL_PastY, Y )
    if #mc.FOL_PastY > SzX then 
        table.remove(mc.FOL_PastY , 1 )
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