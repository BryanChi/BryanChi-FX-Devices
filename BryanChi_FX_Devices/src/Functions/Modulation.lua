-- @noindex

MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
ultraschall = ultraschall

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
    elseif RC and FP.ModAMT and Mods == Shift then
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

                DrawModLines(M, true, Trk[TrkID].Mod[M].Val, FxGUID, ModLineDir or Sldr_Width,FX[FxGUID][Fx_P].V, Vertical, FP, offset)
                Mc.V_Out[M] = (FP.ModAMT[M] * p_value)
                ParamHasMod_Any = true
                offset = offset + OffsetForMultipleMOD
            end
        end -- of reapeat for every macro
    end


    local function MakeContainerModulationPossible ()
        if not FX[FxGUID].parent then return end
        local Cont_FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX[FxGUID].parent )

        if AssignContMacro and Cont_FxGUID ==AssignContMacro_FxGuID   then 
            
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
                ParameterMIDILink(FX_Idx, P_Num, 1, nil, 15+Index, 16, 176, CC, nil)
                
                r.gmem_attach('ContainerMacro')

                r.gmem_write(2, PM.DIY_TrkID[TrkID]) --Sends Trk GUID for jsfx to determine track
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
                    r.gmem_write(3, #Ct.ModPrm) -- tells jsfx how many modded container prm are there 
                    r.gmem_write(2, PM.DIY_TrkID[TrkID]) --Sends Trk GUID for jsfx to determine track


                    if Ct.ModPrm then r.gmem_write(3, #Ct.ModPrm) end  -- Tells jsfx how many modulated prms there are . (eg. if there are 5, then jsfx is sending CC1 ~ 5 and so on )
                    r.gmem_write(5, M) --tells jsfx which macro is user tweaking

                    r.gmem_write(6, AssigningCont_Prm_Mod)  -- this tells jsfx which CC (index of modulated prm in a container) is user tweaking
                    FP.Cont_ModAMT = FP.Cont_ModAMT or {}

                    FP.Cont_ModAMT[M] = CalculateModAmt(FP.Cont_ModAMT[M] )
                    r.gmem_write(1000 * M + AssigningCont_Prm_Mod,  FP.Cont_ModAMT[M]) -- tells jsfx the param's mod amount
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Container Mod Amt',FP.Cont_ModAMT[M], true)

                        -- Draw Mod Lines
                    if Type ~= 'knob' and Type ~= 'Pro-Q' and FP.Cont_ModAMT then
                        local offset = 0
                        for M, v in ipairs(MacroNums) do

                            if FP.Cont_ModAMT[M] and FP.Cont_ModAMT[M] ~= 0 then--if Modulation has been assigned to params

                                --- indicator of where the param is currently
                                FP.V = FP.V or  r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

                                DrawModLines(M, true, FX[AssignContMacro_FxGuID].Mc[M].Val, FxGUID, ModLineDir or Sldr_Width,FP.V, Vertical, FP, offset, FP.Cont_ModAMT[M])

                                Mc.V_Out[M] = (FP.Cont_ModAMT[M] * p_value)
                                ParamHasMod_Any = true
                                offset = offset + OffsetForMultipleMOD

                            end
                        end -- of reapeat for every macro
                    end

                end
                
            end 

            if not IsRBtnHeld then AssigningCont_Prm_Mod = nil end 
        end

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


function Draw_LFO_Trail ()



end