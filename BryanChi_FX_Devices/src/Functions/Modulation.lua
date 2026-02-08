-- @noindex

MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
ultraschall = ultraschall


function Get_MidiMod_Ofs(lbl)
    if not lbl then return end 
    local ofs = 0 
    for i, v in ipairs(Midi_Mods) do 
        if lbl == v then 
            ofs = i-1
        elseif lbl:find('LFO') then 
            ofs = i-1

        end
    end
    return ofs
end

function Get_Env_Shape_From_File(filename)
    if filename then
        local file = io.open(ConcatPath(CurrentDirectory, 'src', 'Envelope Shapes', filename), 'r')
        if file then
            local L = get_lines(ConcatPath(CurrentDirectory, 'src', 'Envelope Shapes', filename))
            local content = file:read("a+")
            local Count = get_aftr_Equal_Num(L[1])
            local Node = {}
            for i = 1, Count or 0, 1 do
                Node[i] = {}
                Node[i][1] = RecallGlobInfo(content, i..'.x = ', 'Num')
                Node[i][2] = RecallGlobInfo(content, i..'.y = ', 'Num')
                Node[i][3] = RecallGlobInfo(content, i..'.Curve = ', 'Num')
            end
            if Node[1] then return Node end
        end
    end
end

function Update_Info_To_Jsfx(PtsTB, lbl , IsLFO, Macro, Update_All_Curve)
    --r.gmem_attach(IsLFO and 'ContainerMacro' or 'ParamValues')
    local midiModOfs = Get_MidiMod_Ofs(lbl)
    r.gmem_write(499, 1) -- tells jsfx to get all points info    
    r.gmem_write(12, midiModOfs)  -- tells which midi mod it is , velocity is (+0) , Random is (+1~3) , KeyTrack is(+4~6), LFO is 7
    r.gmem_write(13, #PtsTB) -- tells how many points there are in the curve so JSFX can use them
    -- Always send Macro number for LFO/Envelope (gmem[12] == 7 means LFO/Envelope)
    if (IsLFO or midiModOfs == 7) and Macro then 
        r.gmem_write(5, Macro) 
    end
    local limit = IsLFO and #PtsTB or 10 
    local start = IsLFO and 500 or 20 
    local prop = IsLFO and 50 or 10
    for i = 1 , limit  do 
        --r.gmem_write(11, i) -- tells which pt
        
        r.gmem_write(start+i, PtsTB[i] and PtsTB[i][1] or 0)

        r.gmem_write(start + prop +i, PtsTB[i] and PtsTB[i][2] or -999)
        r.gmem_write(start + prop *2 +i, PtsTB[i] and PtsTB[i][3] or 0)
    end
--[[ 
    if Update_All_Curve then
        r.gmem_write(4, 24) -- tells jsfx to get all curves info    
        for i = 1 , limit do 
            r.gmem_write(11, i) -- tells which pt
            r.gmem_write(15, PtsTB[i][3] or 0 )
        end
    end
 ]]
   --[[  for i, v in ipairs(PtsTB) do 
        r.gmem_write(11, i) -- tells which pt
        if v[1] then r.gmem_write(20+i, v[1]) end
        if  v[2] then r.gmem_write(30+i, v[2]) end
    end ]]
end

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
    


    if FP and FP.ModAMT and FP.ModAMT[Macro] then

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
            -- Retrieve modulation value based on modulator type
            if M and M.Type and (M.Type == 'env' or M.Type == 'envelope' or M.Type == 'Envelope' or M.Type == 'Step' or M.Type == 'Follower' or M.Type == 'LFO' or M.Type == 'ADSR') then
                if FX[FxGUID].parent then 
                    r.gmem_attach('ContainerMacro')
                else
                    r.gmem_attach('ParamValues')
                end
                MOD = math.abs(SetMinMax(r.gmem_read(100 + Macro) / 127, -1, 1))
            elseif M and M.Type == 'Macro' then
                -- For Macro type, use McroV (which should be passed in) or read from M.Val
                MOD = McroV or (M.Val and M.Val or 0)
            elseif M and M.Val then
                -- Fallback: use M.Val if available
                MOD = M.Val
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

        local key_vbm = 'P_EXT: FX' .. tostring(FxGUID or '') .. 'Prm' .. tostring(Fx_P or '') .. 'Value before modulation'
        _, ValBeforeMod = r.GetSetMediaTrackInfo_String(LT_Track, key_vbm, '', false)
        if not ValBeforeMod or ValBeforeMod == '' then
            local initV = FX[FxGUID] and FX[FxGUID][Fx_P] and FX[FxGUID][Fx_P].V
            r.GetSetMediaTrackInfo_String(LT_Track, key_vbm, tostring(initV or p_value or 0), true)
        end


        Trk.Prm.Assign = FP.WhichCC 
        FP.ModAMT = FP.ModAMT or {}

        --store which param has which Macros assigned
        if FP.WhichMODs == nil then -- if This prm don't have a modulation assigned yet..
            FP.WhichMODs = tostring(AssigningMacro)
            FX[FxGUID][Fx_P].ModAMT = FX[FxGUID][Fx_P].ModAMT or {}
            Trk[TrkID].ModPrmInst = (Trk[TrkID].ModPrmInst or 0) + 1
            FX[FxGUID][Fx_P].WhichCC = Trk[TrkID].ModPrmInst
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. tostring(FxGUID or '') .. 'WhichCC' .. tostring(P_Num or ''), tostring(FP.WhichCC or 0), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ModPrmInst', tostring(Trk[TrkID].ModPrmInst or 0), true)

            Trk.Prm.Assign = Trk[TrkID].ModPrmInst
        elseif FP.WhichMODs and string.find(FP.WhichMODs, tostring(AssigningMacro)) == nil then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            FP.WhichMODs = FP.WhichMODs .. tostring(AssigningMacro)
        end
        
        -- Initialize ModAMT to 0 when first assigning a macro to prevent value jump
        if AssigningMacro and (FP.ModAMT[AssigningMacro] == nil) then
            FP.ModAMT[AssigningMacro] = 0
        end
        local CC = FP.WhichCC



        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. tostring(FxGUID or '') .. 'Prm' .. tostring(Fx_P or '') .. 'Linked to which Mods', tostring(FP.WhichMODs or ''), true)


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
        
        -- Write initial modulation amount (0) to gmem to prevent value jump
        if AssigningMacro and CC then
            r.gmem_write(4, 1)
            r.gmem_write(1000 * AssigningMacro + CC, FP.ModAMT[AssigningMacro] or 0)
        end

    end
end
function If_Hvr_or_Macro_Active (FxGUID, M )
    if not M then return end
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
    -- Determine if this call is for modulator parameters first to avoid nil indexing
    local IsModulatorParam = (Type == 'ModParam' or Type == 'LFO-Param')
    local FP
    local CC
    if IsModulatorParam then
        FX[FxGUID] = FX[FxGUID] or {}
        FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
        FP = FX[FxGUID][Fx_P]
        FP.ModBipolar = FP.ModBipolar or {}
        FP.ModAMT = FP.ModAMT or {}
        FP.Num = P_Num
        -- Deterministic CC mapping for Modulator Parameters:
        -- For Mod N Param M (M=1..4), CC = 4*(N-1) + M, on bus 15 (16th), chan 14 (15th)
        local MacroIndex = math.floor((P_Num - 2) / 4) + 1
        if MacroIndex < 1 then MacroIndex = 1 end
        local ParamIndexWithinMod = ((P_Num - 2) % 4) + 1
        CC = 4 * (MacroIndex - 1) + ParamIndexWithinMod
        Trk.Prm.Assign = CC
        FP.WhichCC = CC
        if not FX_Idx or FX_Idx < 0 then
            local function FindMacrosFXIdx()
                local cnt = r.TrackFX_GetCount(LT_Track)
                for idx = 0, cnt-1, 1 do
                    local rv, name = r.TrackFX_GetFXName(LT_Track, idx, '')
                    if name and name:find('FXD Macros') then return idx end
                end
            end
            FX_Idx = FindMacrosFXIdx() or FX_Idx
        end
       
    else
        if FX[FxGUID] and FX[FxGUID][Fx_P] then
            FP = FX[FxGUID][Fx_P]
            CC = FP.WhichCC
        end
    end
    local RC = im.IsItemClicked(ctx, 1)
    r.gmem_attach('ParamValues')
    local Vertical = Type == 'Vert' and 'Vert' 
    if FP then  FP.ModBipolar = FP.ModBipolar or {} end 


    --if trigger == 'No Item Trigger' then RC = im.IsMouseClicked(ctx, 1) end 
    local RC = trigger == 'No Item Trigger' and im.IsMouseClicked(ctx, 1) or RC

    -- (Modulator-param initialization moved above to avoid nil FP)

    -- For modulator parameters, link immediately on right-click so range editing is available
    if IsModulatorParam and RC and AssigningMacro then
        local CC = Trk.Prm.Assign
        if CC then
            local link_bus = 15
            local link_chan = 14
            local baseline = p_value
            ParameterMIDILink(FX_Idx, P_Num, 1, nil, link_bus, link_chan, 176, CC, baseline)
            PM.TimeNow = r.time_precise()
            r.gmem_write(7, CC)
            r.gmem_write(JSFX.P_ORIG_V + CC, p_value)
        end
    end

    if AssigningMacro then
        local PosL, PosT = im.GetItemRectMin(ctx)
        local PosR, PosB = im.GetItemRectMax(ctx)
        local draw_list = im.GetWindowDrawList(ctx)
        im.DrawList_AddRectFilled(draw_list, PosL, PosT, PosR, PosB, EightColors.bgWhenAsgnMod[AssigningMacro] or 0xffff33ff)
    end
    if --[[Link CC back when mouse is up]] Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then
        if FP then
            local CC = Trk.Prm.Assign or FP.WhichCC
            if CC then
                local extKey = 'P_EXT: FX' .. tostring(FxGUID or '') .. 'Prm' .. tostring(Fx_P or '') .. 'Value before modulation'
                local extVal = tostring(FP.V or p_value or 0)
                r.GetSetMediaTrackInfo_String(LT_Track, extKey, extVal, true)
                r.gmem_write(7, CC) --tells jsfx to retrieve P value
                PM.TimeNow = r.time_precise()
                r.gmem_write(JSFX.P_ORIG_V + CC, p_value)
                local link_bus = IsModulatorParam and 15 or 15
                local link_chan = IsModulatorParam and 14 or 16
                local baseline = IsModulatorParam and p_value or nil
                ParameterMIDILink(FX_Idx, P_Num, 1, nil, link_bus, link_chan, 176, CC, baseline)
            end
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

        -- Only accumulate if there's actual drag movement
        if MouseDrag and MouseDrag ~= 0 then
            ModAmt = ((MouseDrag / 100) or 0) + (ModAmt or 0)
            -- Reset drag delta only after we've used it
            im.ResetMouseDragDelta(ctx, 1)
        end
        
       --[[  if ModAmt + p_value > 1 then ModAmt = 1 - p_value end
        if ModAmt + p_value < 0 then ModAmt = -p_value end ]]


        if Type == 'Pro-Q' then 
            local sc = (ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]  )
            local max = 0.5+ 1/sc/2
            local min = 0.5- 1/sc/2
            if ModAmt + p_value > max then ModAmt = max - p_value end
            if ModAmt + p_value < min then ModAmt = -( p_value-min) end
        end 
        return ModAmt
    end 

    local function Right_Drag_To_Change_Mod_Amt ()
        if Trk.Prm.Assign and FP.WhichCC == Trk.Prm.Assign and AssigningMacro then -- assign Modulations
            local M = AssigningMacro
            local BipolarOut 
            
            -- Ensure ModAMT is initialized to 0 if nil to prevent value jump
            if FP.ModAMT[M] == nil then
                FP.ModAMT[M] = 0
            end

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
            elseif AssigningMidiMod == 'Random 2' then jsfx_ofs = JSFX.Random2
            elseif AssigningMidiMod == 'Random 3' then jsfx_ofs = JSFX.Random3
            elseif AssigningMidiMod == 'KeyTrack 2' then jsfx_ofs = JSFX.KeyTrack2
            elseif AssigningMidiMod == 'KeyTrack 3' then jsfx_ofs = JSFX.KeyTrack3
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
                    -- Get the modulation value based on modulator type
                    local McroV = 0
                    if Trk[TrkID].Mod[M] and Trk[TrkID].Mod[M].Type == 'Macro' then
                        McroV = Trk[TrkID].Mod[M].Val or r.TrackFX_GetParamNormalized(LT_Track, 0, M-1)
                    elseif Trk[TrkID].Mod[M] and Trk[TrkID].Mod[M].Val then
                        McroV = Trk[TrkID].Mod[M].Val
                    end
                    DrawModLines(M, true, McroV, FxGUID, w,FX[FxGUID][Fx_P].V, Vertical, FP, offset, nil,nil,nil , true , FX_Idx)
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
            
            local Ct= FX[AssignContMacro_FxGuID]
            
            

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
                    
                    r.gmem_attach('ContainerMacro')

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
                    if FX[cont_GUID].Mc then 
                        local mc = FX[cont_GUID].Mc[M]
                        if If_Hvr_or_Macro_Active (FxGUID, M) then 
                            clr = CustomColorsDefault.Container_Accent_Clr
                        end 
                        -- Get the modulation value based on container modulator type
                        local McroV = 0
                        if mc and mc.Type == 'Macro' then
                            McroV = mc.Val or r.TrackFX_GetParamNormalized(LT_Track, 0, M-1)
                        elseif mc and (mc.Type == 'env' or mc.Type == 'envelope' or mc.Type == 'Envelope' or mc.Type == 'Step' or mc.Type == 'Follower' or mc.Type == 'LFO' or mc.Type == 'ADSR') then
                            r.gmem_attach('ContainerMacro')
                            r.gmem_write(2, FX[cont_GUID].DIY_FxGUID)
                            McroV = math.abs(SetMinMax(r.gmem_read(100 + M) / 127, -1, 1))
                        elseif mc and mc.Val then
                            McroV = mc.Val
                        end
                        DrawModLines(M, true, McroV, FxGUID, ModLineDir or Sldr_Width,FP.V, Vertical, FP, offset, FP.Cont_ModAMT[M], clr, clr, true, FX_Idx)

                        Mc.V_Out[M] = (FP.Cont_ModAMT[M] * p_value)
                        ParamHasMod_Any = true
                        offset = offset + OffsetForMultipleMOD
                    end
                end
            end -- of reapeat for every macro
        end 

        if not IsRBtnHeld then AssigningCont_Prm_Mod = nil end 
        --Link CC back when mouse is up
        if FP.Cont_Which_CC and  Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then
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
                Node[i][1] = RecallGlobInfo(content , i..'.x = ', 'Num')
                Node[i][2] = RecallGlobInfo(content , i..'.y = ', 'Num')
                Node[i][3] = RecallGlobInfo(content , i..'.Curve = ' , "Num")


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
         BlinkItem(0.3, nil, nil, 0xffffff44, EdgeNoBlink, nil, nil,nil,nil,nil,nil,0xffffff11) 

    end    
end



function When_RightClick_On_Midi_Modulators(lbl)
    if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
    elseif im.IsItemClicked(ctx, 1) and Mods == 0 then
        AssigningMidiMod = toggle(AssigningMidiMod, lbl)
    elseif im.IsItemClicked(ctx, 1) and Mods == Alt then
    end
    if AssigningMidiMod == lbl then 
        BlinkItem(0.3, nil, nil, 0xffffff44, EdgeNoBlink, nil, nil,nil,nil,nil,nil,0xffffff11) 
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

local function get_Global_Env_Shapes()
    local F = scandir(ConcatPath(CurrentDirectory, 'src', 'Envelope Shapes'))
    local Shapes = {}
    for i, v in ipairs(F) do
        local Shape = Get_Env_Shape_From_File(v)
        if Shape then
            Shape.Name = tostring(v):sub(0, -5)
            table.insert(Shapes, Shape)
        end
    end
    return Shapes
end

-- Find a default shape (one with 'Default' in the name) from Global, Project, and Track shapes
local function Find_Default_Shape(is_env)
    -- Check Global shapes first
    local Shapes = is_env and get_Global_Env_Shapes() or get_Global_Shapes()
    for i, v in ipairs(Shapes) do
        if v.Name and v.Name:lower():find('default') then
            return v
        end
    end
    
    -- Check Project shapes
    local HowManySavedShapes = getProjSavedInfo('LFO Saved Shape Count')
    for I = 1, HowManySavedShapes or 0, 1 do
        local Shape = {}
        local Ct = getProjSavedInfo('LFO Shape' .. I .. 'Node Count = ')
        for i = 1, Ct or 1, 1 do
            Shape[i] = Shape[i] or {}
            Shape[i].x = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'x = ')
            Shape[i].y = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'y = ')
            Shape[i].ctrlX = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ')
            Shape[i].ctrlY = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ')
            Shape[i][1] = tonumber(Shape[i].x) or Shape[i][1] or 0
            Shape[i][2] = tonumber(Shape[i].y) or Shape[i][2] or 0
        end
        local nm = getProjSavedInfo('LFO Shape' .. I .. ' Name', 'str')
        if nm and Shape[1] then 
            Shape.Name = nm
            if nm:lower():find('default') then
                return Shape
            end
        end
    end
    
    -- Check Track shapes
    local HowManySavedShapes = GetTrkSavedInfo('LFO Saved Shape Count')
    for I = 1, HowManySavedShapes or 0, 1 do
        local Shape = {}
        local Ct = GetTrkSavedInfo('Shape' .. I .. 'LFO Node Count = ')
        for i = 1, Ct or 1, 1 do
            Shape[i] = Shape[i] or {}
            Shape[i].x = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. ' x') or GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'x = ')
            Shape[i].y = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. ' y') or GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'y = ')
            Shape[i].ctrlX = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlX = ')
            Shape[i].ctrlY = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlY = ')
            Shape[i][1] = tonumber(Shape[i].x) or Shape[i][1] or 0
            Shape[i][2] = tonumber(Shape[i].y) or Shape[i][2] or 0
        end
        local nm = GetTrkSavedInfo('Shape' .. I .. ' Name', LT_Track, 'str')
        if nm and Shape[1] then 
            Shape.Name = nm
            if nm:lower():find('default') then
                return Shape
            end
        end
    end
    
    return nil
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

function Always_Move_Modulator_to_1st_Slot()
    MacroPos = r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0)
    if MacroPos ~= -1 and MacroPos ~= 0 then -- if macro exists on track, and Macro is not the 1st fx
        if FX.Win_Name[0] ~= 'JS: FXD Macros' then r.TrackFX_CopyToTrack(LT_Track, MacroPos, LT_Track, 0, true)
        end -- move it to 1st slot
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

function Add_BG_Text_For_Modulator(txt, indent, ftSz, Y_offset)
    local X, Y = im.GetItemRectMin(ctx)
    local R, B = im.GetItemRectMax(ctx)
    
    -- Calculate text width to ensure it fits within bounds
    local font = _G['Arial Black']
    local fontSize = ftSz or 25
    local indent_val = indent or 0
    -- If indent is nil, center horizontally; otherwise use indent
    local textX = indent and (X + indent_val) or nil -- nil means center horizontally
    
    -- Push font temporarily to calculate text size
    if im.ValidatePtr(font, 'ImGui_Font*') then
        im.PushFont(ctx, font)
        local baseW, baseH = im.CalcTextSize(ctx, txt)
        im.PopFont(ctx)
        
        -- Account for font size scaling if DrawList_AddTextEx scales by fontSize parameter
        -- Font is created at size 15, but rendered at fontSize (25 or 30)
        local fontScale = fontSize / 15
        local itemWidth = R - X
        
        -- Calculate scaled dimensions
        local scaledW = baseW * fontScale
        local textW = scaledW
        local textH = baseH * fontScale
        
        -- Auto-adjust font size if text is too long for Random or other long text
        local checkX = textX or X -- Use textX if set, otherwise X for bounds check
        if checkX + scaledW > R - 2 then
            -- Calculate needed font size to fit
            local availableWidth = itemWidth - (indent_val or 0) - 4 -- Leave margins
            if baseW > 0 then
                local neededScale = availableWidth / baseW
                fontSize = math.min(fontSize, fontSize * neededScale)
                fontScale = fontSize / 15
                textW = baseW * fontScale
            end
        end
        
        textH = baseH * fontScale
        
        -- Calculate horizontal position: center if indent is nil, otherwise use indent
        if not textX then
            -- Center horizontally
            textX = X + (itemWidth - textW) / 2
        else
            -- Use indent, but adjust if text would overflow
            if textX + textW > R then
                -- Try to fit by moving left to stay within bounds
                textX = math.max(X, R - textW - 2) -- Leave 2px margin
            end
            -- Ensure text stays within item bounds horizontally
            textX = math.max(X, math.min(textX, R - 2))
        end
        
        -- Calculate vertical position: center if Y_offset is nil, otherwise use offset
        local textY
        if Y_offset then
            textY = Y + Y_offset
        else
            -- Center vertically
            local itemHeight = B - Y
            textY = Y + (itemHeight - textH) / 2
        end
        Y = textY
    end
    
    im.DrawList_AddTextEx(WDL or im.GetWindowDrawList(ctx), font, fontSize, textX, Y , 0xffffff44, txt)

end

function Follower_Box(mc,i, sz, FxGUID, Gmem, Width)
    if  mc.Type ~= 'Follower' then return end 
    local IsContainer = Gmem == 'ContainerMacro'  and true or nil
    local x , y = im.GetCursorScreenPos(ctx)
    --local sz = LFO_Box_Size
    local x = x - 10
    local I = i+1
    local i = IsContainer and I or i
    local WDL = WDL or im.GetWindowDrawList(ctx)
    local Gmem_Attach = Gmem
    local Popup_Pos_X , Popup_Pos_Y = im.GetCursorScreenPos(ctx)

    --im.SetCursorPosY(ctx, im.GetCursorPosY(ctx) )
   -- im.DrawList_AddRectFilled(WDL,x, y, x+sz,y+sz , 0x00000055)
    --im.DrawList_AddRect(WDL,x-1, y-1, x+sz +1 ,y+sz+1 , 0xffffff77)
    local rv = im.InvisibleButton(ctx, '## Track Follower Box'.. i.. FxGUID, Width or sz*3,sz) 
    
    if im.IsItemClicked(ctx,1 )then 
        mc.TweakingKnob = 2 
    elseif rv then 
        im.SetNextWindowPos(ctx, Popup_Pos_X -sz , Popup_Pos_Y - sz*2 )
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
    if not IsContainer then 
        Add_BG_Text_For_Modulator('Follow', nil) -- nil to center horizontally

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

    r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count', tostring((HowManySavedShapes or 0) + 1))


    local I = (HowManySavedShapes or 0) + 1
    for i, v in ipairs(Mc.Node or {}) do
        if i == 1 then
            r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node Count = ', tostring(#Mc.Node or 0))
        end
        local vx = (type(v) == 'table') and (v.x or v[1]) or v
        local vy = (type(v) == 'table') and (v.y or v[2]) or nil
        local vcx = (type(v) == 'table') and (v.ctrlX) or nil
        local vcy = (type(v) == 'table') and (v.ctrlY) or nil
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'x = ', tostring(vx or ''))
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'y = ', tostring(vy or ''))
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', tostring(vcx or ''))
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', tostring(vcy or ''))
    end
end

function Save_Shape_To_Track(Mc)
    local HowManySavedShapes = GetTrkSavedInfo('LFO Saved Shape Count')
    if HowManySavedShapes then
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', tostring((HowManySavedShapes or 0) + 1), true)
    else
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', tostring(1), true)
    end
    local I = (HowManySavedShapes or 0) + 1
    for i, v in ipairs(Mc.Node or {}) do
        if i == 1 then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'LFO Node Count = ', tostring(#Mc.Node or 0), true)
        end
        local vx = (type(v) == 'table') and (v.x or v[1]) or v
        local vy = (type(v) == 'table') and (v.y or v[2]) or nil
        local vcx = (type(v) == 'table') and (v.ctrlX) or nil
        local vcy = (type(v) == 'table') and (v.ctrlY) or nil
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. 'x = ', tostring(vx or ''), true)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. 'y = ', tostring(vy or ''), true)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', tostring(vcx or ''), true)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', tostring(vcy or ''), true)
    end
end

function Save_Shape_To_Project_WithName(Mc, shapeName)
    local HowManySavedShapes = getProjSavedInfo('LFO Saved Shape Count')
    r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count', tostring((HowManySavedShapes or 0) + 1))
    local I = (HowManySavedShapes or 0) + 1
    for i, v in ipairs(Mc.Node or {}) do
        if i == 1 then
            r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node Count = ', tostring(#Mc.Node or 0))
        end
        local vx = (type(v) == 'table') and (v.x or v[1]) or v
        local vy = (type(v) == 'table') and (v.y or v[2]) or nil
        local vcx = (type(v) == 'table') and (v.ctrlX) or nil
        local vcy = (type(v) == 'table') and (v.ctrlY) or nil
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'x = ', tostring(vx or ''))
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'y = ', tostring(vy or ''))
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', tostring(vcx or ''))
        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', tostring(vcy or ''))
    end
    r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. ' Name', tostring(shapeName or ''))
end

function Save_Shape_To_Track_WithName(Mc, shapeName)
    local HowManySavedShapes = GetTrkSavedInfo('LFO Saved Shape Count')
    if HowManySavedShapes then
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', tostring((HowManySavedShapes or 0) + 1), true)
    else
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', tostring(1), true)
    end
    local I = (HowManySavedShapes or 0) + 1
    for i, v in ipairs(Mc.Node or {}) do
        if i == 1 then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'LFO Node Count = ', tostring(#Mc.Node or 0), true)
        end
        local vx = (type(v) == 'table') and (v.x or v[1]) or v
        local vy = (type(v) == 'table') and (v.y or v[2]) or nil
        local vcx = (type(v) == 'table') and (v.ctrlX) or nil
        local vcy = (type(v) == 'table') and (v.ctrlY) or nil
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. 'x = ', tostring(vx or ''), true)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. 'y = ', tostring(vy or ''), true)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', tostring(vcx or ''), true)
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', tostring(vcy or ''), true)
    end
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Shape' .. I .. ' Name', tostring(shapeName or ''), true)
end

function Save_Shape_To_Global_ByName(Mc, shapeName)
    if not shapeName or shapeName == '' then return end
    local folder = (Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and 'Envelope Shapes' or 'LFO Shapes'
    local path = ConcatPath(CurrentDirectory, 'src', folder)
    r.RecursiveCreateDirectory(path, 0)
    local file_path = ConcatPath(path, shapeName .. '.ini')
    local file = io.open(file_path, 'w')
    if not file then return end
    for i, v in ipairs(Mc.Node or {}) do
        if i == 1 then file:write('Total Number Of Nodes = ', #Mc.Node, '\n') end
        local x = v[1] or v.x
        local y = v[2] or v.y
        local curve = v[3] or v.Curve
        file:write(i, '.x = ', x or 0, '\n')
        file:write(i, '.y = ', y or 0, '\n')
        if curve then file:write(i, '.Curve = ', curve, '\n') end
        file:write('\n')
    end
    file:close()
end

function Save_LFO_Dialog (Macro, x, y , Mc, FxGUID)

    local WinTitle = 'FXGUID = '.. (FxGUID or '').. 'Macro = '.. Macro 
    if FxGUID then -- if it's a container's LFO
        --[[ WinTitle = Macro..FxGUID  ]]
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

            im.SetNextItemWidth(ctx, 300)
            if im.IsWindowAppearing(ctx) then 
                im.SetKeyboardFocusHere(ctx)
            end
            local rv, buf = im.InputText(ctx, buf or '##Name', buf)
            im.Text(ctx,'Save to : ')
            SL()
            im.Button(ctx, 'Global (Enter)')
            if im.IsItemClicked(ctx) or ( im.IsKeyPressed(ctx, im.Key_Enter) and Mods == 0) then
                local LFO_Name = buf
                local folder = (Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and 'Envelope Shapes' or 'LFO Shapes'
                local path = ConcatPath(CurrentDirectory, 'src', folder)
                r.RecursiveCreateDirectory(path, 0)
                local file_path = ConcatPath(path, LFO_Name .. '.ini')
                local file = io.open(file_path, 'w')


                for i, v in ipairs(Mc.Node) do
                    if i == 1 then
                        file:write('Total Number Of Nodes = ', #Mc.Node, '\n')
                    end
                    file:write(i, '.x = ', v[1], '\n')
                    file:write(i, '.y = ', v[2], '\n')
                    if v[3] then
                        file:write(i, '.Curve = ', v[3], '\n')
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
    local Shapes = ((Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and get_Global_Env_Shapes() or get_Global_Shapes())
    local Box_Sz = 50
    im.SetNextWindowPos(ctx, x - (Box_Sz)+18 , y -LFO_Box_Size- #Shapes * Box_Sz/2 )
    if im.BeginPopup(ctx, 'Small Shape Select'..macronum..FxGUID) then 
        if im.IsWindowAppearing(ctx) then
            LFO.NodeBeforePreview = Mc.Node
        end
        local AnyShapeHovered
        local Shapes = ((Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and get_Global_Env_Shapes() or get_Global_Shapes())
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

            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length', Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator', Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom, true)

            --if I.Name == 'Env ' .. i or I.Name == 'Macro ' .. i then I.Name = 'Step ' .. i end
        end
    end
end
function Set_Modulator_Type(Mc, i, Type, ContainerID, FxGUID)
    if Mc.Type == Type then return end 
    if im.Selectable(ctx, Type, false) then
        Mc.Type = Type
        if ContainerID then 
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. i .. 'Type', Type, true)
        else
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod'..i .. 'Type', Type, true)
        end
        
            if Type == 'LFO' or Type == 'Follower' or Type == 'Step' or Type == 'Envelope' or Type == 'Random' or Type == 'ADSR' then AddMacroJSFX() end
        local JSFX_Type = {
            LFO = 12,
            Envelope = 4,  -- JSFX expects mode 4 for Envelope (not 12)
            Follower = 9,
            Step = 6,
            Macro = 5,
            Random = 27,
            XY = 28,
            ADSR = 29,  -- New ADSR modulator type
        }
        local function Init_LFO_Params(init_type)
            local is_env = init_type == 'Envelope' or init_type == 'envelope' or init_type == 'env'
            local key_prefix = is_env and 'Env' or 'LFO'
            local default_len = is_env and 4 or 4
            local default_gain = 1.0
            local default_spd = is_env and 1/2 or 1/8
            -- Set defaults for LFO params if values don't exist previously
            -- Param indices are 0-based: base = 2 + (macro-1)*4; Param2=base+1 (Length), Param3=base+2 (Gain), Param4=base+3 (Speed)
            local function Read_LFO_Saved_Str(param_label)
                local _, saved_str1
                if FxGUID then
                    _, saved_str1 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' '..key_prefix..' '..param_label, '', false)
                end
                local _, saved_str2 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' '..key_prefix..' '..param_label, '', false)
                local saved_str = (saved_str1 and saved_str1 ~= '' and saved_str1) or (saved_str2 and saved_str2 ~= '' and saved_str2) or nil
                if (not saved_str or saved_str == '') and is_env then
                    local _, fallback1
                    if FxGUID then
                        _, fallback1 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' LFO '..param_label, '', false)
                    end
                    local _, fallback2 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' LFO '..param_label, '', false)
                    saved_str = (fallback1 and fallback1 ~= '' and fallback1) or (fallback2 and fallback2 ~= '' and fallback2) or nil
                end
                return saved_str
            end
            local function FindMacrosFXIdx()
                local cnt = r.TrackFX_GetCount(LT_Track)
                for idx = 0, cnt-1, 1 do
                    local rv, name = r.TrackFX_GetFXName(LT_Track, idx, '')
                    if name and (name:find('FXD Macros') or name:find('FXD Container Macros')) then return idx end
                end
            end
            local MacFxIdx = FindMacrosFXIdx()
            if MacFxIdx then
                local base = 2 + (i - 1) * 4
                local lenIdx  = base + 1 -- Param2
                local gainIdx = base + 2 -- Param3
                local spdIdx  = base + 3 -- Param4
                
                -- Recall saved values, or set defaults if they don't exist
                local saved_len = tonumber(Read_LFO_Saved_Str('Length') or '')
                local saved_gain = tonumber(Read_LFO_Saved_Str('Gain') or '')
                local saved_spd = tonumber(Read_LFO_Saved_Str('Speed') or '')
                
                -- Length: restore saved value or default to 4
                -- Length maps 0-1 to 1-8: (length-1)/7
                if saved_len and saved_len >= 1 and saved_len <= 8 then
                    local len_norm = (saved_len - 1) / 7
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, lenIdx, len_norm)
                    Mc.LFO_leng = saved_len
                else
                    -- Default to 4: (4-1)/7 = 3/7 ≈ 0.4286
                    local len_norm_default = (default_len - 1) / 7
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, lenIdx, len_norm_default)
                    Mc.LFO_leng = default_len
                end
                
                -- Gain: restore saved value or default to 1.0 (100%)
                if saved_gain and saved_gain >= 0 and saved_gain <= 1 then
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, gainIdx, saved_gain)
                else
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, gainIdx, default_gain)
                end
                
                -- Speed: restore saved value or default
                if saved_spd and saved_spd > 0 and saved_spd <= 1 then
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, spdIdx, saved_spd)
                    Mc.LFO_spd = saved_spd
                    -- Convert normalized speed to index for UI display (0-8)
                    local labels_count = 9
                    Mc.LFO_spd_idx = math.max(0, math.min(math.floor(saved_spd * (labels_count - 1) + 0.5), labels_count - 1))
                else
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, spdIdx, default_spd)
                    Mc.LFO_spd = default_spd
                    -- Convert normalized speed to index for UI display (0-8)
                    local labels_count = 9
                    Mc.LFO_spd_idx = math.max(0, math.min(math.floor(default_spd * (labels_count - 1) + 0.5), labels_count - 1))
                end
            end
        end
        r.gmem_write(2,  ContainerID or PM.DIY_TrkID[TrkID])
        -- Write type to JSFX immediately for most types, but defer LFO, Envelope, Random and Step until after initialization
        if Type ~= 'Random' and Type ~= 'Step' and Type ~= 'LFO' and Type ~= 'Envelope' then
            r.gmem_write(4, JSFX_Type[Type]) -- tells jsfx macro type
            r.gmem_write(5, i) -- tells jsfx which macro
        end
        

        -- If selecting Envelope, force LFO to Envelope mode (use LFO envelope instead of JSFX env)
        if Type == 'Envelope' then
            if ContainerID then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..'Mod ' .. i .. ' LFO_Env_or_Loop', 1, true)
            else
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. i .. 'LFO_Env_or_Loop', 1, true)
            end
            Mc.LFO_Env_or_Loop = 'Envelope'
            -- Mode 18 sets type to LFO and EnvOrLoop in one go
            r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 18) -- mode 18 = set EnvOrLoop (also sets type to LFO)
            r.gmem_write(5, i)
            r.gmem_write(9, 1) -- 1 = Envelope mode
            Init_LFO_Params(Type)
            
            -- Apply default shape if modulator hasn't been edited
            if not Mc.Node or #Mc.Node == 0 then
                local defaultShape = Find_Default_Shape(true) -- true for envelope
                if defaultShape then
                    Mc.Node = defaultShape
                    -- Send shape info to JSFX
                    if ContainerID then
                        r.gmem_attach('ContainerMacro')
                        -- For containers, try to generate AllCoord and use Cont_Send_All_Coord
                        local fx = FX[FxGUID] or {}
                        if Cont_DrawShape then
                            local dummyW, dummyH = 100, 50
                            local dummyL, dummyT = 0, 0
                            local AllCoord = Cont_DrawShape(defaultShape, dummyL, dummyW, dummyH, dummyT, nil, nil, 'SaveAllCoord')
                            if AllCoord then
                                Cont_Send_All_Coord(fx, i, AllCoord, Mc, #defaultShape * 11)
                            else
                                Update_Info_To_Jsfx(defaultShape, 'LFO'..i, true, i, true)
                            end
                        else
                            Update_Info_To_Jsfx(defaultShape, 'LFO'..i, true, i, true)
                        end
                        SAVE_ALL_LFO_INFO(defaultShape, FxGUID, i)
                    else
                        r.gmem_attach('ParamValues')
                        Update_Info_To_Jsfx(defaultShape, 'LFO'..i, true, i, true)
                        -- Save to track
                        local function SaveLFO(StrName, V)
                            if StrName then
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. i .. StrName, tostring(V or ''), true)
                            end
                        end
                        for j, v in ipairs(defaultShape) do
                            SaveLFO('Node' .. j .. 'Ctrl X', defaultShape[j].ctrlX or '')
                            SaveLFO('Node' .. j .. 'Ctrl Y', defaultShape[j].ctrlY or '')
                            SaveLFO('Node ' .. j .. ' X', defaultShape[j].x or defaultShape[j][1] or '')
                            SaveLFO('Node ' .. j .. ' Y', defaultShape[j].y or defaultShape[j][2] or '')
                            SaveLFO('Total Number of Nodes', #defaultShape)
                        end
                    end
                end
            end
        elseif Type == 'LFO' then
            -- Ensure LFO defaults to Loop mode
            if ContainerID then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..'Mod ' .. i .. ' LFO_Env_or_Loop', 0, true)
            else
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. i .. 'LFO_Env_or_Loop', 0, true)
            end
            Mc.LFO_Env_or_Loop = 'Loop'
            -- Mode 18 sets type to LFO and EnvOrLoop in one go
            r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 18) -- mode 18 = set EnvOrLoop (also sets type to LFO)
            r.gmem_write(5, i)
            r.gmem_write(9, 0) -- 0 = Loop mode
            Init_LFO_Params(Type)
            
            -- Apply default shape if modulator hasn't been edited
            if not Mc.Node or #Mc.Node == 0 then
                local defaultShape = Find_Default_Shape(false) -- false for LFO
                if defaultShape then
                    Mc.Node = defaultShape
                    -- Send shape info to JSFX
                    if ContainerID then
                        r.gmem_attach('ContainerMacro')
                        -- For containers, try to generate AllCoord and use Cont_Send_All_Coord
                        local fx = FX[FxGUID] or {}
                        if Cont_DrawShape then
                            local dummyW, dummyH = 100, 50
                            local dummyL, dummyT = 0, 0
                            local AllCoord = Cont_DrawShape(defaultShape, dummyL, dummyW, dummyH, dummyT, nil, nil, 'SaveAllCoord')
                            if AllCoord then
                                Cont_Send_All_Coord(fx, i, AllCoord, Mc, #defaultShape * 11)
                            else
                                Update_Info_To_Jsfx(defaultShape, 'LFO'..i, true, i, true)
                            end
                        else
                            Update_Info_To_Jsfx(defaultShape, 'LFO'..i, true, i, true)
                        end
                        SAVE_ALL_LFO_INFO(defaultShape, FxGUID, i)
                    else
                        r.gmem_attach('ParamValues')
                        Update_Info_To_Jsfx(defaultShape, 'LFO'..i, true, i, true)
                        -- Save to track
                        local function SaveLFO(StrName, V)
                            if StrName then
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. i .. StrName, tostring(V or ''), true)
                            end
                        end
                        for j, v in ipairs(defaultShape) do
                            SaveLFO('Node' .. j .. 'Ctrl X', defaultShape[j].ctrlX or '')
                            SaveLFO('Node' .. j .. 'Ctrl Y', defaultShape[j].ctrlY or '')
                            SaveLFO('Node ' .. j .. ' X', defaultShape[j].x or defaultShape[j][1] or '')
                            SaveLFO('Node ' .. j .. ' Y', defaultShape[j].y or defaultShape[j][2] or '')
                            SaveLFO('Total Number of Nodes', #defaultShape)
                        end
                    end
                end
            end

--[[             -- Clear continuous override and set musical division
            r.gmem_write(4, 30) -- clear period continuous flag
            r.gmem_write(9, 0)
            r.gmem_write(5, i)
            r.gmem_write(9, Mc.LFO_spd or (1/8))
            r.gmem_write(4, 12) -- set musical speed
            r.gmem_write(9, Mc.LFO_leng or 4)
            r.gmem_write(4, 13) -- length tweak to finalize initialization ]]
            -- Notify JSFX of type change AFTER all initialization
            --[[ r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 12) -- mode 12 = LFO type
            r.gmem_write(5, i) -- tells jsfx which macro ]]
        elseif Type == 'Random' then
            -- Initialize Random parameters to unified params
            -- Param indices are 0-based: base = 2 + (macro-1)*4; Param1=base+0 (Interval), Param2=base+1 (Smooth), Param3=base+2 (Chance)
            local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
            if MacFxGUID then
                local function FindFxIdxByGUID(guid)
                    local cnt = r.TrackFX_GetCount(LT_Track)
                    for idx = 0, cnt-1, 1 do
                        if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                    end
                end
                local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                local base = 2 + (i - 1) * 4
                local intervalIdx = base + 0 -- Param1 (Interval)
                local smoothIdx = base + 1   -- Param2 (Smooth)
                local chanceIdx = base + 2   -- Param3
                
                -- Recall saved values, or set defaults if they don't exist
                local _, saved_int_str = ContainerID and 
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' Random Interval', '', false) or
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' Random Interval', '', false)
                local _, saved_smooth_str = ContainerID and 
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' Random Smooth', '', false) or
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' Random Smooth', '', false)
                local _, saved_chance_str = ContainerID and 
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' Random Chance', '', false) or
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' Random Chance', '', false)
                local _, saved_sync_str = ContainerID and 
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' Random Sync', '', false) or
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' Random Sync', '', false)
                
                local saved_int = (saved_int_str ~= '' and saved_int_str) and tonumber(saved_int_str) or nil
                local saved_smooth = (saved_smooth_str ~= '' and saved_smooth_str) and tonumber(saved_smooth_str) or nil
                local saved_chance = (saved_chance_str ~= '' and saved_chance_str) and tonumber(saved_chance_str) or nil
                local saved_sync = (saved_sync_str ~= '' and saved_sync_str) and tonumber(saved_sync_str) or nil
                
                -- Interval: restore saved value or default to 200
                local interval_val = saved_int or (Mc.Random_Int or 200)
                Mc.Random_Int = interval_val
                -- Convert to normalized: 1-500 → (value-1)/499
                local interval_norm = (interval_val - 1) / 499
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, intervalIdx, interval_norm)
                
                -- Smooth: restore saved value or default to 0
                local smooth_val = saved_smooth or (Mc.Random_Smooth or 0)
                Mc.Random_Smooth = smooth_val
                -- Convert to normalized: 0-100 → value/100
                local smooth_norm = smooth_val / 100
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, smoothIdx, smooth_norm)
                
                -- Chance: restore saved value or default to 100
                local chance_val = saved_chance or (Mc.Random_Chance or 100)
                Mc.Random_Chance = chance_val
                -- Convert to normalized: 0-100 → value/100
                local chance_norm = chance_val / 100
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, chanceIdx, chance_norm)
                -- Sync toggle (Param4)
                local syncIdx = base + 3
                local sync_val = saved_sync or (Mc.Random_Sync or 0)
                Mc.Random_Sync = sync_val
                local sync_norm = sync_val > 0 and 1 or 0
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, syncIdx, sync_norm)
            end
            -- Always notify JSFX of type change AFTER parameter initialization
            r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 27) -- tells jsfx macro type = Random
            r.gmem_write(5, i) -- tells jsfx which macro
        elseif Type == 'Step' then
            -- Initialize Step parameters to unified params
            -- Param indices are 0-based: base = 2 + (macro-1)*4; Param1=base+0 (Length), Param2=base+1 (Denominator)
            
            -- Recall saved values, or set defaults if they don't exist
            -- Try both container and regular keys to ensure we find saved values
            local _, saved_seql_str1
            if FxGUID then
                _, saved_seql_str1 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro '..i..' SEQ Length', '', false)
            end
            local _, saved_seql_str2 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro '..i..' SEQ Length', '', false)
            local saved_seql_str = (saved_seql_str1 and saved_seql_str1 ~= '' and saved_seql_str1) or (saved_seql_str2 and saved_seql_str2 ~= '' and saved_seql_str2) or nil
            
            local _, saved_denom_str1
            if FxGUID then
                _, saved_denom_str1 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro '..i..' SEQ Denominator', '', false)
            end
            local _, saved_denom_str2 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro '..i..' SEQ Denominator', '', false)
            local saved_denom_str = (saved_denom_str1 and saved_denom_str1 ~= '' and saved_denom_str1) or (saved_denom_str2 and saved_denom_str2 ~= '' and saved_denom_str2) or nil
            
            Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
            Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
            
            -- Length: restore saved value or default to 8
            local saved_seql = (saved_seql_str ~= '' and saved_seql_str) and tonumber(saved_seql_str) or nil
            if saved_seql and saved_seql >= 2 and saved_seql <= 64 then
                Trk[TrkID].SEQL[i] = saved_seql
            else
                Trk[TrkID].SEQL[i] = 8
            end
            
            -- Denominator: restore saved value or default to 1
            local saved_denom = (saved_denom_str ~= '' and saved_denom_str) and tonumber(saved_denom_str) or nil
            if saved_denom then
                Trk[TrkID].SEQ_Dnom[i] = saved_denom
            else
                Trk[TrkID].SEQ_Dnom[i] = 1
            end
            
            local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
            if MacFxGUID then
                local function FindFxIdxByGUID(guid)
                    local cnt = r.TrackFX_GetCount(LT_Track)
                    for idx = 0, cnt-1, 1 do
                        if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                    end
                end
                local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                local base = 2 + (i - 1) * 4
                local lengthIdx = base + 0  -- Param1
                local denomIdx = base + 1   -- Param2
                
                -- Convert to normalized values (0-1)
                -- Length: 2-64 → normalized (length-2)/62
                local length_norm = (Trk[TrkID].SEQL[i] - 2) / 62
                -- Denominator: values are [0.125, 0.25, 0.5, 1, 2, 4, 8] (7 values) → normalized index/6
                -- Find index for value 1 (which is index 3, so normalized = 3/6 = 0.5)
                local denom_values = {0.125, 0.25, 0.5, 1, 2, 4, 8}
                local denom_norm = 0.5 -- default for value 1
                for idx, val in ipairs(denom_values) do
                    if math.abs(Trk[TrkID].SEQ_Dnom[i] - val) < 0.001 then
                        denom_norm = (idx - 1) / 6
                        break
                    end
                end
                
                -- Set the parameters
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, lengthIdx, length_norm)
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, denomIdx, denom_norm)
            end
            -- Always notify JSFX of type change AFTER parameter initialization
            r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 6) -- tells jsfx macro type = Step
            r.gmem_write(5, i) -- tells jsfx which macro
        elseif Type == 'ADSR' then
            -- Initialize ADSR parameters using unified param slots
            -- ADSR uses all 4 params: Param1=Attack, Param2=Decay, Param3=Sustain, Param4=Release
            local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
            if MacFxGUID then
                local function FindFxIdxByGUID(guid)
                    local cnt = r.TrackFX_GetCount(LT_Track)
                    for idx = 0, cnt-1, 1 do
                        if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                    end
                end
                local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                local base = 2 + (i - 1) * 4
                local attackIdx = base + 0  -- Param1 (Attack)
                local decayIdx = base + 1   -- Param2 (Decay)
                local sustainIdx = base + 2 -- Param3 (Sustain)
                local releaseIdx = base + 3 -- Param4 (Release)
                
                -- Recall saved values, or set defaults if they don't exist
                local function Read_ADSR_Saved_Val(param_name)
                    local _, saved_str1
                    if FxGUID then
                        _, saved_str1 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' ADSR '..param_name, '', false)
                    end
                    local _, saved_str2 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' ADSR '..param_name, '', false)
                    local saved_str = (saved_str1 and saved_str1 ~= '' and saved_str1) or (saved_str2 and saved_str2 ~= '' and saved_str2) or nil
                    return saved_str and tonumber(saved_str) or nil
                end
                
                -- Hold: restore or default to 0.0 (stored in JSFX internal memory, not in unified params)
                local hold_val = Read_ADSR_Saved_Val('Hold') or (Mc.ADSR_Hold or 0.0)
                Mc.ADSR_Hold = hold_val
                
                -- Attack: restore or default to 0.01 (10ms)
                local attack_val = Read_ADSR_Saved_Val('Attack') or (Mc.ADSR_Attack or 0.01)
                Mc.ADSR_Attack = attack_val
                -- Normalize: 0.001-2.0 seconds, logarithmic mapping
                local attack_norm = (math.log(attack_val) - math.log(0.001)) / (math.log(2.0) - math.log(0.001))
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, attackIdx, attack_norm)
                
                -- Decay: restore or default to 0.1 (100ms)
                local decay_val = Read_ADSR_Saved_Val('Decay') or (Mc.ADSR_Decay or 0.1)
                Mc.ADSR_Decay = decay_val
                -- Normalize: 0.001-2.0 seconds, logarithmic mapping
                local decay_norm = (math.log(decay_val) - math.log(0.001)) / (math.log(2.0) - math.log(0.001))
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, decayIdx, decay_norm)
                
                -- Sustain: restore or default to 0.7 (70%)
                local sustain_val = Read_ADSR_Saved_Val('Sustain') or (Mc.ADSR_Sustain or 0.7)
                Mc.ADSR_Sustain = sustain_val
                -- Normalize: 0.0-1.0, linear (it's a level, not a time)
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, sustainIdx, sustain_val)
                
                -- Release: restore or default to 0.1 (100ms)
                local release_val = Read_ADSR_Saved_Val('Release') or (Mc.ADSR_Release or 0.1)
                Mc.ADSR_Release = release_val
                -- Normalize: 0.001-2.0 seconds, logarithmic mapping
                local release_norm = (math.log(release_val) - math.log(0.001)) / (math.log(2.0) - math.log(0.001))
                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, releaseIdx, release_norm)

                -- ADSR curves: restore or default to 0 (linear)
                local curve_a_val = Read_ADSR_Saved_Val('Curve Attack') or (Mc.ADSR_Curve_Attack or 0.0)
                Mc.ADSR_Curve_Attack = curve_a_val
                local curve_d_val = Read_ADSR_Saved_Val('Curve Decay') or (Mc.ADSR_Curve_Decay or 0.0)
                Mc.ADSR_Curve_Decay = curve_d_val
                local curve_r_val = Read_ADSR_Saved_Val('Curve Release') or (Mc.ADSR_Curve_Release or 0.0)
                Mc.ADSR_Curve_Release = curve_r_val
                
                -- Hold: restore or default to 0.0 (stored in JSFX internal memory, not in unified params)
                local hold_val = Read_ADSR_Saved_Val('Hold') or (Mc.ADSR_Hold or 0.0)
                Mc.ADSR_Hold = hold_val
                -- Send Hold value to JSFX via gmem
                if ContainerID then
                    r.gmem_attach('ContainerMacro')
                else
                    r.gmem_attach('ParamValues')
                end
                r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
                r.gmem_write(4, 34) -- mode 34 = ADSR Hold parameter
                r.gmem_write(5, i) -- which modulator
                r.gmem_write(9, hold_val) -- Hold value in seconds

                r.gmem_write(4, 35) -- mode 35 = ADSR curve
                r.gmem_write(5, i) -- which modulator
                r.gmem_write(6, 1) -- Attack curve
                r.gmem_write(8, Mc.ADSR_Curve_Attack or 0.0)
                r.gmem_write(6, 2) -- Decay curve
                r.gmem_write(8, Mc.ADSR_Curve_Decay or 0.0)
                r.gmem_write(6, 3) -- Release curve
                r.gmem_write(8, Mc.ADSR_Curve_Release or 0.0)
            end
            -- Always notify JSFX of type change AFTER parameter initialization
            if ContainerID then
                r.gmem_attach('ContainerMacro')
            else
                r.gmem_attach('ParamValues')
            end
            r.gmem_write(2, ContainerID or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 29) -- tells jsfx macro type = ADSR
            r.gmem_write(5, i) -- tells jsfx which macro
        end
        return Type

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
            local WDL = WDL or im.GetWindowDrawList(ctx)
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
                    
                    im.DrawList_AddLine(WDL , PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
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

            -- Draw First line 
            if i == 1 and x > L then 
                im.DrawList_AddLine(WDL, L, y , x, y , Clr or EightColors.LFO[Macro], thick)
            end
            -- Draw Last line 
            if i == #Node and x < L+W then 
                im.DrawList_AddLine(WDL, x, y , L+W, y , Clr or EightColors.LFO[Macro], thick)
            end
        end

        
        return All_Coord
    end
end


function LFO_BOX_NEW(Mc, i, W, H, IsContainer, Track, PosForWin, FxGUID)
    if Mc.Type ~= 'LFO' and Mc.Type ~= 'Envelope' and Mc.Type ~= 'envelope' then return end 
    local Macro = i
    local Ident = 'FXGUID = '.. (FxGUID or '').. 'Macro = '.. Macro
    local fx = FX[FxGUID]
    if IsContainer then 
        r.gmem_attach('ContainerMacro')
    end
    --[[ local function ChangeLFO(mode, V, gmem, StrName)
        
        r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
        r.gmem_write(5, i)    -- Tells jsfx which macro
        r.gmem_write(gmem or 9, V)
        if StrName then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
        end
    end ]]
    local function ChangeLFO(mode, V, gmem, StrName, IsContainer, fx)

        if IsContainer then 
            r.gmem_attach('ContainerMacro')
            r.gmem_write(2, fx.DIY_FxGUID) -- tells jsfx which container macro, so multiple instances of container macros won't affect each other
        else 
            r.gmem_attach('ParamValues')
            r.gmem_write(2, PM.DIY_TrkID[TrkID]) -- ensure jsfx handles this track's macro
        end
        -- Order matters: write target + value first, then trigger mode
        r.gmem_write(5, i)    -- Tells jsfx which macro
        r.gmem_write(gmem or 9, V)
        r.gmem_write(4, mode) -- trigger processing after data is set
        if StrName then
            if IsContainer then 
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID.. 'Mod '.. Macro .. StrName, V, true)
            else
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
            end
        end
    end
    local function SaveLFO(StrName, V)
        if StrName then
            if IsContainer then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID.. 'Mod '.. Macro .. StrName, V, true)
            else
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
            end
        end
    end
    local function Get_LFO_Save_Key(param_label)
        local is_env = Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope' or Mc.Type == 'env')
        local prefix = is_env and 'Env' or 'LFO'
        if IsContainer then
            return 'Container '..FxGUID..' Mod '..Macro..' '..prefix..' '..param_label
        end
        return 'Mod '..Macro..' '..prefix..' '..param_label
    end

    local function IF_CONTIAINER_SEND_RIGHT_CLICK_INFO()
        if not IsContainer then return end
        if im.IsItemHovered(ctx,im.HoveredFlags_RectOnly) and IsRBtnClicked then 
            Mc.TweakingKnob=  2 
        end 
    end
    local Width = W 
    local H    = H or Width/3
    local MOD  = math.abs(SetMinMax((r.gmem_read(100 + i) or 0) / 127, -1, 1))

    LFO.DummyH = LFO.Win.h + 20
    --LFO.DummyW  =  ( LFO.Win.w + 30) * ((Mc.LFO_leng or LFO.Def.Len)/4 )
    Mc.Freq    = Mc.Freq or 1
    Mc.Gain    = Mc.Gain or 5
    if not IsContainer then 
    im.TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
    end
    --[[  IsMacroSlidersEdited, I.Val = im.SliderDouble(ctx, i .. '##LFO', I.Val, Slider1Min or 0,
    Slider1Max or 1) ]]
    local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)


    --local W = (VP.w - 10) / 12 - 3 -- old W 
    local rv = im.InvisibleButton(ctx, '##LFO Button' .. i ..(FxGUID or ''), W, H)
    local BG_txt_Indent = IsContainer and 5 or 30
    local BG_txt_Sz = IsContainer and 20 or 30
    local BG_txt_Ofs_Y = IsContainer and H/4 or nil
    local BG_txt = (Mc.Type == 'Envelope' or Mc.Type == 'envelope') and 'ENV' or 'LFO'
    Add_BG_Text_For_Modulator(BG_txt, nil ,BG_txt_Sz, BG_txt_Ofs_Y) -- nil indent to center horizontally
    do
        local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx)
        local div = Mc.LFO_leng or (LFO and LFO.Def and LFO.Def.Len) or 4
        if div and div > 1 then
            local WDL = WDL or im.GetWindowDrawList(ctx)
            local totalW = R - L
            for d = 1, div - 1, 1 do
                local X = L + totalW * (d / div)
                local seg, gap = 4, 3
                local y = T
                while y < B do
                    local y2 = math.min(y + seg, B)
                    im.DrawList_AddLine(WDL, X, y, X, y2, 0xffffff44, 1)
                    y = y2 + gap
                end
            end
        end
    end
    IF_CONTIAINER_SEND_RIGHT_CLICK_INFO()
    local w, h = im.GetItemRectSize(ctx)
    local L, T = im.GetItemRectMin(ctx)
    local WDL = im.GetWindowDrawList(ctx)
    local X_range = (LFO.Win.w) * ((Mc.LFO_leng or LFO.Def.Len) / 4)

    im.DrawList_AddRect(WDL, L, T , L + w , T + h, 0xFFFFFF22)


    if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
        im.OpenPopup(ctx, 'Macro' .. i .. 'Menu')
    end

    local function DrawShape(Node, L, W, H, T, Clr)
        if Node then
          --[[   for i, v in ipairs(Node) do
                local W, H = W or w, H or h
                

                local N = Node
                local L = L or HdrPosL
                local h = LFO.DummyH
                local lastX = N[math.max(i - 1, 1)][1] * W + L
                local lastY = T + H - (-N[math.max(i - 1, 1)][2] + 1) * H

                local x = N[i][1] * W + L
                local y = T + H - (-N[math.min(i, #Node)][2] + 1) * H

                local CtrlX = (N[i][3] or ((N[math.max(i - 1, 1)][1] + N[i][1]) / 2)) * W + L
                local CtrlY = T + H - (-(N[i][4] or ((N[math.max(i - 1, 1)][2] + N[i][2]) / 2)) + 1) * H

                local PtsX, PtsY = Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, x, y)

                for i, v in ipairs(PtsX) do
                    if i > 1 and PtsX[i] <= L + W then -- >1 because you need two points to draw a line
                        im.DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i], Clr or EightColors.LFO[Macro])
                    end
                end
            end ]]


            Draw_Curve (WDL, Node , i , L, L+W, L+H, W, H, 5 , 0xff22ffff, 2)
        end
    end

    --WhenRightClickOnModulators(Macro)
    local G = 1 -- Gap between Drawing Coord values retrieved from jsfx

    -- Draw Tiny Playhead
    if IsContainer then 
        r.gmem_attach('ContainerMacro')
    else 
        r.gmem_attach('ParamValues')
    end


    local PlayPos = L + r.gmem_read(108 + i) / 4 * w / ((Mc.LFO_leng or LFO.Def.Len) / 4)
    im.DrawList_AddLine(WDL, PlayPos, T, PlayPos, T + h, EightColors.LFO[Macro], 1)
    im.DrawList_AddCircleFilled(WDL, PlayPos, T + h - MOD * h , 3, EightColors.LFO[Macro])
    --DrawLFOShape(Mc.Node, L, W, H, T,  nil, 3,nil, i )
    if Mc.Node then 
        for i, v in ipairs( Mc.Node) do 
            Draw_Curve (WDL, Mc.Node, i , L, L+w, T+h, w, h, 1 , EightColors.LFO[Macro], 2)
        end
        -- If gain < 1, overlay a dotted line of the scaled curve
        local gain = Mc.LFO_Gain or 1
        if gain < 0.999 then
            local zoom = (Mc and (Mc.Zoom or 1)) or 1
            local PtSz = 1
            local ofs = PtSz/2
            local function map_u(u)
                local c = 0.5
                return ((u - c) * zoom + c)
            end
            local function draw_dotted_segment(x1, y1, x2, y2)
                draw_dotted_line(x1, y1, x2, y2, Change_Clr_A(EightColors.LFO[Macro], -0.35), 4, 3)
            end
            for i, v in ipairs(Mc.Node) do
                local x1 = L + map_u(v[1]) * w + ofs
                local y1 = (T+h) - (v[2] * gain) * h + ofs
                if Mc.Node[i+1] then
                    local n = Mc.Node[i+1]
                    local x2 = L + map_u(n[1]) * w + ofs
                    local y2 = (T+h) - (n[2] * gain) * h + ofs
                    if not v[3] then
                        draw_dotted_segment(x1, y1, x2, y2)
                    else
                        -- Curve interpolation preview with simple subdivision
                        local steps = 24
                        local lastx, lasty = x1, y1
                        for s = 1, steps do
                            local t = s/steps
                            local y_lin = (v[2] + (n[2]-v[2]) * t)
                            local y_curve = GetCurveValue(y_lin, v[3], math.min(v[2], n[2]), math.max(v[2], n[2]), math.min(v[2], n[2]), math.max(v[2], n[2]))
                            local px = x1 + (x2 - x1) * t
                            local py = (T+h) - (y_curve * gain) * h + ofs
                            draw_dotted_segment(lastx, lasty, px, py)
                            lastx, lasty = px, py
                        end
                    end
                end
            end
        end
    end
    if rv and not LFO_DragDir and Mods == 0 then
        im.OpenPopup(ctx, 'LFO Shape Select')
        --im.SetNextWindowSize(ctx, LFO.Win.w  , LFO.Win.h+200)
    end



    local function open_LFO_Win(Track, Macro, IsContainer, pos,  mc, FxGUID)
        local asFloating = (LFO and LFO.FloatingOpen and LFO.FloatingOpen[Ident]) and true or false
        if not IsContainer then 
            if LFO.EditWinOpen and not asFloating then return end 
        end
        local tweaking
        local LFOWindowW
        local HdrPosL = IsContainer and pos[1] or HdrPosL
        local Mc = mc or Mc
        
        -- Keep window content-fit but enforce a reasonable minimum size; avoids bottom empty space
        local baseCurveW = LFO.Win and LFO.Win.w or 360
        local curveLen = (Mc.LFO_leng or (LFO.Def and LFO.Def.Len) or 4)
        local fixedW = math.max(520, baseCurveW + baseCurveW * ((curveLen - 4) / 4) + 60)
        local minH = 340
        -- Lock width to fixedW plus room for shape selector; set height large enough to avoid scrollbars
        local selectorW = 180
        local popupW = fixedW + selectorW + 16
        local baseH = 20 + (LFO and LFO.Win and LFO.Win.h) or 300 
        local neededH = math.max(minH, baseH + 85)
        im.SetNextWindowSizeConstraints(ctx, popupW, neededH, popupW, 100000)
        if not asFloating then
            im.SetNextWindowPos(ctx, HdrPosL, IsContainer and pos[2] - 385 or VP.Y - 385)
        end
        local PopupLbl = (IsContainer and 'Container' or '')..'LFO Popup' .. Macro .. (FxGUID or '')

        local drawingPopup = false
        local drawingFloating = false
        local winOpen = true

        if asFloating then
            local flags = im.WindowFlags_NoDocking | im.WindowFlags_NoCollapse | im.WindowFlags_NoResize
            winOpen, LFO.FloatingOpen[Ident] = im.Begin(ctx, 'LFO Editor '.. Macro .. (FxGUID or ''), LFO.FloatingOpen[Ident], flags)
            drawingFloating = true
            if not winOpen then
                -- user closed the window
                LFO.FloatingOpen[Ident] = nil
                LFO.EditWinOpen = nil
                im.End(ctx)
                return
            end
        else
            if im.BeginPopup(ctx, PopupLbl) then
                drawingPopup = true
            end
        end

        if drawingPopup or drawingFloating then
            -- Update window rect each frame for outside-click detection
            local wx, wy = im.GetWindowPos(ctx)
            local ww, wh = im.GetWindowSize(ctx)
            LFO.WinRect = LFO.WinRect or {}
            LFO.WinRect[Ident] = { wx, wy, wx + ww, wy + wh }

            -- Begin left child for main controls
            local availW = im.GetContentRegionAvail(ctx)
            local totalW = availW
            local rightW = 200
            local leftW = math.max(10, totalW - rightW - 12)
            im.BeginChild(ctx, '##LFO_Main_'..Macro, leftW, 0, 0, im.WindowFlags_NoScrollWithMouse)

            -- Close on Esc (end child before closing popup)
            if im.IsKeyPressed(ctx, im.Key_Escape) then
                LFO.WinHovered = nil; LFO.HvringWin = nil; LFO.Tweaking = nil
                im.EndChild(ctx)
                if drawingPopup then
                    im.CloseCurrentPopup(ctx)
                    im.EndPopup(ctx)
                else
                    if LFO.FloatingOpen then LFO.FloatingOpen[Ident] = nil end
                    im.End(ctx)
                end
                return
            end
            
            local Node = Mc.Node
            local function ConverCtrlNodeY(lastY, Y)
                local Range = (math.max(lastY, Y) - math.min(lastY, Y))
                local NormV = (math.min(lastY, Y) + Range - Y) / Range
                local Bipolar = -1 + (NormV) * 2
                return NormV
            end
            local BtnSz = 11



            --Mc.Node = Mc.Node or { x = {} , ctrlX = {}, y = {}  , ctrlY = {}}
            --[[ if not Node[i].x then
                table.insert(Node.x, L)
                table.insert(Node.x, L + 400)
                table.insert(Node.y, T + h / 2)
                table.insert(Node.y, T + h / 2)
            end ]]


            local function Env_Or_Loop()
                if im.BeginCombo(ctx, '## Env_Or_Loop' .. Macro, Mc.LFO_Env_or_Loop or 'Loop') then
                    if im.Selectable(ctx, 'Loop', p_1selected, flagsIn, size_wIn, size_hIn) then
                        Mc.LFO_Env_or_Loop = 'Loop'
                        ChangeLFO(18, 0, nil, 'LFO_Env_or_Loop') -- value is 0 because loop is default
                    end
                    if im.Selectable(ctx, 'Envelope (MIDI)', p_2selected, flagsIn, size_wIn, size_hIn) then
                        Mc.LFO_Env_or_Loop = 'Envelope'
                        ChangeLFO(18, 1, nil, 'LFO_Env_or_Loop') -- 1 for envelope
                    end
                    tweaking = Ident
                    im.EndCombo(ctx)
                end

                if Mc.LFO_Env_or_Loop == 'Envelope' then
                    SL()
                    im.SetNextItemWidth(ctx, 120)
                    local ShownName
                    if Mc.Rel_Type == 'Custom Release - No Jump' then ShownName = 'Custom No Jump' end
                    if im.BeginCombo(ctx, '## ReleaseType' .. Macro, ShownName or Mc.Rel_Type or 'Latch') then
                        tweaking = Ident
                        if im.Selectable(ctx, 'Latch', p_1selected, flagsIn, size_wIn, size_hIn) then
                            Mc.Rel_Type = 'Latch'
                            -- For envelope, use Param1 for release type: 0=Latch, 0.5=Custom Release, 1=Custom Release No Jump
                            local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
                            if MacFxGUID then
                                local function FindFxIdxByGUID(guid)
                                    local cnt = r.TrackFX_GetCount(LT_Track)
                                    for idx = 0, cnt-1, 1 do
                                        if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                                    end
                                end
                                local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                                local paramIdx = 2 + (Macro - 1) * 4 -- Param1 for this modulator
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, paramIdx, 0) -- 0 = Latch
                            end
                            SaveLFO('LFO_Release_Type', '0')
                        end
                        QuestionHelpHint('Latch on to whichever value its at when midi key is released ')
                        --[[ if im.Selectable( ctx, 'Simple Release',  p_1selected,   flagsIn,   size_wIn,   size_hIn) then
                            Mc.Rel_Type = 'Simple Release'
                            ChangeLFO(19, 1 , nil, 'LFO_Release_Type') -- 1 for Simple release
                        end   ]]
                        if im.Selectable(ctx, 'Custom Release', p_1selected, flagsIn, size_wIn, size_hIn) then
                            Mc.Rel_Type = 'Custom Release'
                            -- For envelope, use Param1 for release type: 0=Latch, 0.5=Custom Release, 1=Custom Release No Jump
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
                                local param2Idx = 2 + (Macro - 1) * 4 + 1 -- Param2 for this modulator
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param1Idx, 0.5) -- 0.5 = Custom Release
                                
                                -- Restore release node from Param2 or find existing/default
                                local relNodeIdx = nil
                                local param2Value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, param2Idx)
                                if param2Value and param2Value >= 0 and param2Value <= 1 and Mc.Node and #Mc.Node > 0 then
                                    -- Convert normalized value to node index
                                    relNodeIdx = math.floor(param2Value * (#Mc.Node - 1) + 1 + 0.5)
                                    relNodeIdx = math.max(1, math.min(relNodeIdx, #Mc.Node))
                                end
                                
                                -- If not found in Param2, check existing nodes or default
                                if not relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    for idx, node in ipairs(Mc.Node) do
                                        if node.Rel then
                                            relNodeIdx = idx
                                            break
                                        end
                                    end
                                    if not relNodeIdx then
                                        relNodeIdx = #Mc.Node - 1 -- default to second-to-last
                                    end
                                end
                                
                                -- Set Param2 and restore .Rel flag
                                if relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    -- Normalize: node 1 = 0, last node = 1
                                    local normalized = (relNodeIdx - 1) / (#Mc.Node - 1)
                                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param2Idx, normalized)
                                    -- Restore the .Rel flag
                                    Mc.Node[relNodeIdx] = Mc.Node[relNodeIdx] or {}
                                    Mc.Node[relNodeIdx].Rel = true
                                end
                            end
                            SaveLFO('LFO_Release_Type', '2')
                        end
                        QuestionHelpHint('Jump to release node when midi note is released')

                        if im.Selectable(ctx, 'Custom Release - No Jump', p_1selected, flagsIn, size_wIn, size_hIn) then
                            Mc.Rel_Type = 'Custom Release - No Jump'
                            -- For envelope, use Param1 for release type: 0=Latch, 0.5=Custom Release, 1=Custom Release No Jump
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
                                local param2Idx = 2 + (Macro - 1) * 4 + 1 -- Param2 for this modulator
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param1Idx, 1.0) -- 1.0 = Custom Release No Jump
                                
                                -- Restore release node from Param2 or find existing/default
                                local relNodeIdx = nil
                                local param2Value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, param2Idx)
                                if param2Value and param2Value >= 0 and param2Value <= 1 and Mc.Node and #Mc.Node > 0 then
                                    -- Convert normalized value to node index
                                    relNodeIdx = math.floor(param2Value * (#Mc.Node - 1) + 1 + 0.5)
                                    relNodeIdx = math.max(1, math.min(relNodeIdx, #Mc.Node))
                                end
                                
                                -- If not found in Param2, check existing nodes or default
                                if not relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    for idx, node in ipairs(Mc.Node) do
                                        if node.Rel then
                                            relNodeIdx = idx
                                            break
                                        end
                                    end
                                    if not relNodeIdx then
                                        relNodeIdx = #Mc.Node - 1 -- default to second-to-last
                                    end
                                end
                                
                                -- Set Param2 and restore .Rel flag
                                if relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    -- Normalize: node 1 = 0, last node = 1
                                    local normalized = (relNodeIdx - 1) / (#Mc.Node - 1)
                                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param2Idx, normalized)
                                    -- Restore the .Rel flag
                                    Mc.Node[relNodeIdx] = Mc.Node[relNodeIdx] or {}
                                    Mc.Node[relNodeIdx].Rel = true
                                end
                            end
                            SaveLFO('LFO_Release_Type', '3')
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
            end

            local function Copy()
                local rv = im.Button(ctx, '## copy', 17, 17)
                DrawListButton(WDL, "0", 0x00000000, false, true, icon1_middle, false)
                TooltipUI("Copy LFO", im.HoveredFlags_Stationary)
                if rv then
                    LFO.Clipboard = {}
                    for i, v in ipairs(Node) do
                        for i, v in ipairs(Mc.Node) do
                            LFO.Clipboard[i] =  {}
                            LFO.Clipboard[i][1] = v[1]
                            LFO.Clipboard[i][2] = v[2]
                            LFO.Clipboard[i][3] = v[3]
    
                        end
                    end
                end
            end
            local function Paste()
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
            end
            local function Save_Shape()
                local rv = im.ImageButton(ctx, '## save' .. Macro, Img.Save, BtnSz, BtnSz, nil, nil, nil, nil,ClrBG,ClrTint)
                TooltipUI("Save LFO shape as preset", im.HoveredFlags_Stationary)
                if rv then
                    LFO.OpenSaveDialog = Ident
                end
            end
            local function Shape_Preset()
                local rv = im.ImageButton(ctx, '## shape Preset' .. Macro, Img.Sine, BtnSz * 2, BtnSz, nil, nil, nil, nil, 0xffffff00, ClrTint)
                TooltipUI("Open Shape preset window", im.HoveredFlags_Stationary)
                if rv then
                    if LFO.OpenShapeSelect then LFO.OpenShapeSelect = nil else LFO.OpenShapeSelect = Macro end
                end
                if LFO.OpenShapeSelect then Highlight_Itm(WDL, 0xffffff55) end
            end

            local function EXEC_Top_Buttons()
                
                local function ExpandToWindow()
                    local rv = im.ImageButton(ctx, '## expand' .. Macro, Img.expand, BtnSz, BtnSz)
                    TooltipUI("Open as window", im.HoveredFlags_Stationary)
                    if rv then
                        LFO.FloatingOpen = LFO.FloatingOpen or {}
                        LFO.FloatingOpen[Ident] = true
                        if not asFloating then
                            im.CloseCurrentPopup(ctx)
                        end
                    end
                end

                ExpandToWindow()
                SL()
                -- Pin icon removed
                Copy()
                local WDL = im.GetWindowDrawList(ctx)
                SL()
                Paste()
                SL()
                -- Removed Env/Loop dropdown; show a small label instead
                if Mc.Type == 'Envelope' or Mc.Type == 'envelope' then
                    im.Text(ctx, 'Envelope')
                    SL()
                    im.SetNextItemWidth(ctx, 120)
                    local shown = (Mc.Rel_Type == 'Custom Release - No Jump') and 'Custom No Jump' or Mc.Rel_Type or 'Latch'
                    if im.BeginCombo(ctx, '## ReleaseType' .. Macro, shown) then
                        tweaking = Ident
                        if im.Selectable(ctx, 'Latch', Mc.Rel_Type == 'Latch') then
                            Mc.Rel_Type = 'Latch'
                            -- For envelope, use Param1 for release type: 0=Latch, 0.5=Custom Release, 1=Custom Release No Jump
                            local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
                            if MacFxGUID then
                                local function FindFxIdxByGUID(guid)
                                    local cnt = r.TrackFX_GetCount(LT_Track)
                                    for idx = 0, cnt-1, 1 do
                                        if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                                    end
                                end
                                local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                                local paramIdx = 2 + (Macro - 1) * 4 -- Param1 for this modulator
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, paramIdx, 0) -- 0 = Latch
                            end
                            SaveLFO('LFO_Release_Type', '0')
                        end
                        if im.Selectable(ctx, 'Custom Release', Mc.Rel_Type == 'Custom Release') then
                            Mc.Rel_Type = 'Custom Release'
                            -- For envelope, use Param1 for release type: 0=Latch, 0.5=Custom Release, 1=Custom Release No Jump
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
                                local param2Idx = 2 + (Macro - 1) * 4 + 1 -- Param2 for this modulator
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param1Idx, 0.5) -- 0.5 = Custom Release
                                
                                -- Restore release node from Param2 or find existing/default
                                local relNodeIdx = nil
                                local param2Value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, param2Idx)
                                if param2Value and param2Value >= 0 and param2Value <= 1 and Mc.Node and #Mc.Node > 0 then
                                    -- Convert normalized value to node index
                                    relNodeIdx = math.floor(param2Value * (#Mc.Node - 1) + 1 + 0.5)
                                    relNodeIdx = math.max(1, math.min(relNodeIdx, #Mc.Node))
                                end
                                
                                -- If not found in Param2, check existing nodes or default
                                if not relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    for idx, node in ipairs(Mc.Node) do
                                        if node.Rel then
                                            relNodeIdx = idx
                                            break
                                        end
                                    end
                                    if not relNodeIdx then
                                        relNodeIdx = #Mc.Node - 1 -- default to second-to-last
                                    end
                                end
                                
                                -- Set Param2 and restore .Rel flag
                                if relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    -- Normalize: node 1 = 0, last node = 1
                                    local normalized = (relNodeIdx - 1) / (#Mc.Node - 1)
                                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param2Idx, normalized)
                                    -- Restore the .Rel flag
                                    Mc.Node[relNodeIdx] = Mc.Node[relNodeIdx] or {}
                                    Mc.Node[relNodeIdx].Rel = true
                                end
                            end
                            SaveLFO('LFO_Release_Type', '2')
                        end
                        if im.Selectable(ctx, 'Custom Release - No Jump', Mc.Rel_Type == 'Custom Release - No Jump') then
                            Mc.Rel_Type = 'Custom Release - No Jump'
                            -- For envelope, use Param1 for release type: 0=Latch, 0.5=Custom Release, 1=Custom Release No Jump
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
                                local param2Idx = 2 + (Macro - 1) * 4 + 1 -- Param2 for this modulator
                                r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param1Idx, 1.0) -- 1.0 = Custom Release No Jump
                                
                                -- Restore release node from Param2 or find existing/default
                                local relNodeIdx = nil
                                local param2Value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, param2Idx)
                                if param2Value and param2Value >= 0 and param2Value <= 1 and Mc.Node and #Mc.Node > 0 then
                                    -- Convert normalized value to node index
                                    relNodeIdx = math.floor(param2Value * (#Mc.Node - 1) + 1 + 0.5)
                                    relNodeIdx = math.max(1, math.min(relNodeIdx, #Mc.Node))
                                end
                                
                                -- If not found in Param2, check existing nodes or default
                                if not relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    for idx, node in ipairs(Mc.Node) do
                                        if node.Rel then
                                            relNodeIdx = idx
                                            break
                                        end
                                    end
                                    if not relNodeIdx then
                                        relNodeIdx = #Mc.Node - 1 -- default to second-to-last
                                    end
                                end
                                
                                -- Set Param2 and restore .Rel flag
                                if relNodeIdx and Mc.Node and #Mc.Node > 0 then
                                    -- Normalize: node 1 = 0, last node = 1
                                    local normalized = (relNodeIdx - 1) / (#Mc.Node - 1)
                                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, param2Idx, normalized)
                                    -- Restore the .Rel flag
                                    Mc.Node[relNodeIdx] = Mc.Node[relNodeIdx] or {}
                                    Mc.Node[relNodeIdx].Rel = true
                                end
                            end
                            SaveLFO('LFO_Release_Type', '3')
                        end
                        im.EndCombo(ctx)
                    end
                else
                    im.Text(ctx, 'LFO')
                    SL()
                    -- Inline Length (to the right of 'LFO')
                    im.Text(ctx, 'Length:')
                    SL()
                    im.SetNextItemWidth(ctx, 70)
                    local MacFxGUID2 = r.TrackFX_GetFXGUID(LT_Track, 0)
                    if MacFxGUID2 then
                        local function FindFxIdxByGUID2(guid)
                            local cnt = r.TrackFX_GetCount(LT_Track)
                            for idx = 0, cnt-1, 1 do
                                if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                            end
                        end
                        local MacFxIdx2 = FindFxIdxByGUID2(MacFxGUID2) or 0
                        local P_Num_Len = 2 + (Macro - 1) * 4 + 1    -- param 2
                        local cur_len_norm = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Len)
                        local cur_len_discrete = math.floor(1 + cur_len_norm * 7 + 0.5)
                        local rv_len_top, newLenTop = im.SliderInt(ctx, '##LFO_Len_Top'..Macro..(FxGUID or ''), cur_len_discrete, 1, 8)
                        if rv_len_top then
                            local new_norm = (newLenTop - 1) / 7
                            r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Len, new_norm)
                            Mc.LFO_leng = newLenTop
                            -- Save immediately when value changes
                            local str = Get_LFO_Save_Key('Length')
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.LFO_leng), true)
                        end
                        -- Also save on mouse release for cases where value might change via other means
                        if im.IsItemDeactivatedAfterEdit(ctx) then
                            local final_len = Mc.LFO_leng or math.floor(1 + r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Len) * 7 + 0.5)
                            local str = Get_LFO_Save_Key('Length')
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(final_len), true)
                        end
                        -- Allow other modulators to modulate Length
                        do
                            local pv = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Len)
                            MakeModulationPossible(MacFxGUID2, P_Num_Len, MacFxIdx2, P_Num_Len, pv, 70, 'ModParam')
                        end
                    end
                    SL()
                    -- Inline Gain bind: Param3=Gain
                    im.Text(ctx, 'Gain:')
                    SL()
                    im.SetNextItemWidth(ctx, 80)
                    local MacFxGUID2 = r.TrackFX_GetFXGUID(LT_Track, 0)
                    if MacFxGUID2 then
                        local function FindFxIdxByGUID2(guid)
                            local cnt = r.TrackFX_GetCount(LT_Track)
                            for idx = 0, cnt-1, 1 do
                                if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                            end
                        end
                        local MacFxIdx2 = FindFxIdxByGUID2(MacFxGUID2) or 0
                        local P_Num_Gain = 2 + (Macro - 1) * 4 + 2    -- param3
                        local gain_value = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Gain)
                        local rv_gain, new_gain = im.SliderDouble(ctx, '##LFO_Gain_Top'..Macro..(FxGUID or ''), gain_value, 0, 1, '%.2f')
                        if rv_gain then
                            r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Gain, new_gain)
                            -- Save immediately when value changes
                            local str = Get_LFO_Save_Key('Gain')
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(new_gain), true)
                        end
                        -- Also save on mouse release for cases where value might change via other means
                        if im.IsItemDeactivatedAfterEdit(ctx) then
                            local final_gain = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Gain)
                            local str = Get_LFO_Save_Key('Gain')
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(final_gain), true)
                        end
                        -- Allow other modulators to modulate Gain (using a vertical style so range drag is vertical)
                        do
                            local pv = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Gain)
                            MakeModulationPossible(MacFxGUID2, P_Num_Gain, MacFxIdx2, P_Num_Gain, pv, 80, 'ModParam')
                        end
                    end
                end
                SL(nil, 30)
                Save_Shape()
            end
            
            local function LFO_Release_Node ()


                if not Mc.Rel_Type then return end 
                if  Mc.Type ~= 'Envelope'  then return end
                if Mc.Rel_Type:find('Custom Release') then 
                        im.Spacing(ctx)

                        im.Spacing(ctx)
                        im.Spacing(ctx)
                        im.Spacing(ctx)

                end
            end


            EXEC_Top_Buttons()
            LFO_Release_Node ()
            
            -- (Length/Gain moved inline next to 'LFO' above)

            local CurveEditor_Win_W = (LFO.Win.w + LFO.Win.w * ((Mc.LFO_leng or LFO.Def.Len)-4)/4)



            local node, tweaking = CurveEditor(CurveEditor_Win_W , LFO.Win.h , Mc.Node, 'LFO'..Macro, Mc, IsContainer and true )
            Mc.Node = node 
            LFO.Tweaking = tweaking and Ident or LFO.Tweaking
            -- Overlay cues on top of curve editor
            do
                -- Prefer using the curve editor rect published by CurveEditor to avoid item changes shifting
                local edL, edT, edR, edB
                if LFO and LFO.CurveRect and LFO.CurveRect[Macro] then
                    edL, edT, edR, edB = table.unpack(LFO.CurveRect[Macro])
                else
                    edL, edT = im.GetItemRectMin(ctx)
                    local edW, edH = im.GetItemRectSize(ctx)
                    edR, edB = edL + edW, edT + edH
                end
                local edW, edH = edR - edL, edB - edT
                local WDL_cur = im.GetWindowDrawList(ctx)
                -- Show bold 'Preview' while hovering a shape (temporary preview)
                if LFO.AnyShapeHovered and not LFO.NewShapeChosen then
                    local label = 'Preview'
                    local pushedFont
                    if im.ValidatePtr(Impact, 'ImGui_Font*') then
                        -- Attach a large Impact font dynamically at 30px if needed
                        if not im.ValidatePtr(Impact_30, 'ImGui_Font*') then
                            Attach_New_Font_On_Next_Frame('Impact', 30)
                        end
                        if im.ValidatePtr(Impact_30, 'ImGui_Font*') then im.PushFont(ctx, Impact_30) pushedFont = true end
                    elseif im.ValidatePtr(Arial_30, 'ImGui_Font*') then
                        im.PushFont(ctx, Arial_30) pushedFont = true
                    end
                    local tw, th = im.CalcTextSize(ctx, label)
                    local tx = edL + (edW - tw) * 0.5
                    local ty = edT + (edH - th) * 0.5
                    local shadow = 0x000000cc
                    im.DrawList_AddText(WDL_cur, tx+1, ty, shadow, label)
                    im.DrawList_AddText(WDL_cur, tx-1, ty, shadow, label)
                    im.DrawList_AddText(WDL_cur, tx, ty+1, shadow, label)
                    im.DrawList_AddText(WDL_cur, tx, ty-1, shadow, label)
                    im.DrawList_AddText(WDL_cur, tx, ty, 0xffffffff, label)
                    if pushedFont then im.PopFont(ctx) end
                end
                -- Full-rect flash animation when a shape is applied by click
                if LFO.ShapeChangeAnimStart then
                    local elapsed = r.time_precise() - (LFO.ShapeChangeAnimStart or 0)
                    local dur = 0.6
                    if elapsed < dur then
                        local k = 1 - (elapsed / dur)
                        local alpha = 0.25 * k
                        local col = im.ColorConvertDouble4ToU32(1, 1, 1, alpha)
                        im.DrawList_AddRectFilled(WDL_cur, edL, edT, edL + edW, edT + edH, col)
                    else
                        LFO.ShapeChangeAnimStart = nil
                    end
                end
            end
         

            im.AlignTextToFramePadding(ctx)
            im.Text(ctx, 'Speed:')
            SL()
            -- Single unified musical selector mapped to Mod N Param 4
            local labels = { '2 bars', '1 bar', '1/2', '1/4', '1/8', '1/16', '1/32', '1/64', '1/128' }
            local periods = { 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125 }
            -- Ensure JSFX type/state for LFO so playback runs
            if not Mc._LFO_TypeEnsured then
                Mc._LFO_TypeEnsured = true
                ChangeLFO(18, 0, nil, 'LFO_Env_or_Loop')
                ChangeLFO(30, 0, 9, 'LFO Period Continuous')
                local normInit = (Mc.LFO_spd_idx or 1) / (#labels-1)
                ChangeLFO(12, normInit, 9, 'LFO Speed')
            end
            Mc.LFO_spd_idx = math.max(0, math.min(Mc.LFO_spd_idx or 1, #labels-1))
            -- Mode toggle: Musical vs Free
            Mc.LFO_snap = Mc.LFO_snap ~= false -- default true (musical)
            local snapLbl = Mc.LFO_snap and 'Musical' or 'Free'
            if im.SmallButton(ctx, snapLbl) then
                Mc.LFO_snap = not Mc.LFO_snap
            end
            SL()

            im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x333333ff)
            if Mc.LFO_snap then
                -- Musical with triplet/dotted options
                im.SetNextItemWidth(ctx, 140)
                
                -- Get FX GUID and index first (needed for saving)
                local MacFxGUID2 = r.TrackFX_GetFXGUID(LT_Track, 0)
                local MacFxIdx2, P_Num_Spd
                if MacFxGUID2 then
                    local function FindFxIdxByGUID2(guid)
                        local cnt = r.TrackFX_GetCount(LT_Track)
                        for idx2 = 0, cnt-1, 1 do
                            if r.TrackFX_GetFXGUID(LT_Track, idx2) == guid then return idx2 end
                        end
                    end
                    MacFxIdx2 = FindFxIdxByGUID2(MacFxGUID2) or 0
                    local base = 2 + (Macro - 1) * 4
                    P_Num_Spd = base + 3 -- Param4
                end
                
                -- Render the slider
                local changedIdx, idx = im.SliderInt(ctx, '##LFO_SpeedDiv'..Macro..(FxGUID or ''), Mc.LFO_spd_idx, 0, #labels-1, labels[(Mc.LFO_spd_idx or 0)+1])
                if changedIdx then 
                    Mc.LFO_spd_idx = idx
                    -- Recalculate norm with new index and save immediately
                    local newBasePer = periods[Mc.LFO_spd_idx + 1] or 1
                    local newMult = 1
                    if Mc.LFO_triplet then newMult = (2/3) end
                    if Mc.LFO_dotted then newMult = (3/2) end
                    local newTargetPer = newBasePer * newMult
                    local newNearestIdx, newBestDiff = 0, math.huge
                    for iP, per in ipairs(periods) do
                        local d = math.abs(per - newTargetPer)
                        if d < newBestDiff then newBestDiff = d; newNearestIdx = iP-1 end
                    end
                    local newNorm = newNearestIdx / (#labels-1)
                    if MacFxIdx2 and P_Num_Spd then
                        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd, newNorm)
                        Mc.LFO_spd = newNorm
                        -- Save immediately when value changes
                        local str = Get_LFO_Save_Key('Speed')
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(newNorm), true)
                    end
                end
                SL()
                -- Triplet / Dotted toggles (mutually exclusive)
                local wasTrip = Mc.LFO_triplet and 1 or 0
                local clickedTrip = im.Checkbox(ctx, 'Triplet', wasTrip == 1)
                if clickedTrip then
                    Mc.LFO_triplet = not Mc.LFO_triplet
                    if Mc.LFO_triplet then Mc.LFO_dotted = false end
                    -- Recalculate and save on checkbox click
                    if MacFxIdx2 and P_Num_Spd then
                        local newBasePer = periods[(Mc.LFO_spd_idx or 0)+1] or 1
                        local newMult = Mc.LFO_triplet and (2/3) or (Mc.LFO_dotted and (3/2) or 1)
                        local newTargetPer = newBasePer * newMult
                        local newNearestIdx, newBestDiff = 0, math.huge
                        for iP, per in ipairs(periods) do
                            local d = math.abs(per - newTargetPer)
                            if d < newBestDiff then newBestDiff = d; newNearestIdx = iP-1 end
                        end
                        local newNorm = newNearestIdx / (#labels-1)
                        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd, newNorm)
                        Mc.LFO_spd = newNorm
                        local str = Get_LFO_Save_Key('Speed')
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(newNorm), true)
                    end
                end
                SL()
                local wasDot = Mc.LFO_dotted and 1 or 0
                local clickedDot = im.Checkbox(ctx, 'Dotted', wasDot == 1)
                if clickedDot then
                    Mc.LFO_dotted = not Mc.LFO_dotted
                    if Mc.LFO_dotted then Mc.LFO_triplet = false end
                    -- Recalculate and save on checkbox click
                    if MacFxIdx2 and P_Num_Spd then
                        local newBasePer = periods[(Mc.LFO_spd_idx or 0)+1] or 1
                        local newMult = Mc.LFO_triplet and (2/3) or (Mc.LFO_dotted and (3/2) or 1)
                        local newTargetPer = newBasePer * newMult
                        local newNearestIdx, newBestDiff = 0, math.huge
                        for iP, per in ipairs(periods) do
                            local d = math.abs(per - newTargetPer)
                            if d < newBestDiff then newBestDiff = d; newNearestIdx = iP-1 end
                        end
                        local newNorm = newNearestIdx / (#labels-1)
                        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd, newNorm)
                        Mc.LFO_spd = newNorm
                        local str = Get_LFO_Save_Key('Speed')
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(newNorm), true)
                    end
                end
                
                -- Also save on mouse release for safety
                if MacFxIdx2 and P_Num_Spd and im.IsItemDeactivatedAfterEdit(ctx) then
                    local final_spd = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd)
                    local str = Get_LFO_Save_Key('Speed')
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(final_spd), true)
                end
            else
                -- Free: ms input -> beats -> nearest discrete Param4
                im.SetNextItemWidth(ctx, 140)
                local bpm = r.Master_GetTempo()
                local secPerBeat = 60 / math.max(1, bpm)
                local cur_ms
                do
                    local basePer = periods[(Mc.LFO_spd_idx or 0)+1] or 1
                    cur_ms = math.floor(basePer * secPerBeat * 1000 + 0.5)
                end
                local was_active_ms = im.IsItemActive(ctx)
                local rv_ms, ms = im.DragInt(ctx, '##LFO_FreeMs'..Macro..(FxGUID or ''), Mc.LFO_free_ms or cur_ms, 1, 1, 60000, '%d ms')
                if rv_ms then Mc.LFO_free_ms = ms end
                local beats = (Mc.LFO_free_ms or cur_ms) / 1000 / secPerBeat
                local nearestIdx, bestDiff = 0, math.huge
                for iP, per in ipairs(periods) do
                    local d = math.abs(per - beats)
                    if d < bestDiff then bestDiff = d; nearestIdx = iP-1 end
                end
                local norm = nearestIdx / (#labels-1)
                local MacFxGUID2 = r.TrackFX_GetFXGUID(LT_Track, 0)
                local MacFxIdx2, P_Num_Spd
                if MacFxGUID2 then
                    local function FindFxIdxByGUID2(guid)
                        local cnt = r.TrackFX_GetCount(LT_Track)
                        for idx2 = 0, cnt-1, 1 do
                            if r.TrackFX_GetFXGUID(LT_Track, idx2) == guid then return idx2 end
                        end
                    end
                    MacFxIdx2 = FindFxIdxByGUID2(MacFxGUID2) or 0
                    local base = 2 + (Macro - 1) * 4
                    P_Num_Spd = base + 3 -- Param4
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd, norm)
                    Mc.LFO_spd = norm
                end
                -- Save on mouse release
                if MacFxIdx2 and P_Num_Spd and was_active_ms and im.IsItemDeactivatedAfterEdit(ctx) then
                    local final_spd = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd)
                    local str = Get_LFO_Save_Key('Speed')
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(final_spd), true)
                end
            end
            im.PopStyleColor(ctx)

            -- Allow other modulators to modulate Speed (Param4)
            do
                local MacFxGUID2 = r.TrackFX_GetFXGUID(LT_Track, 0)
                if MacFxGUID2 then
                    local function FindFxIdxByGUID2(guid)
                        local cnt = r.TrackFX_GetCount(LT_Track)
                        for idx2 = 0, cnt-1, 1 do
                            if r.TrackFX_GetFXGUID(LT_Track, idx2) == guid then return idx2 end
                        end
                    end
                    local MacFxIdx2 = FindFxIdxByGUID2(MacFxGUID2) or 0
                    local base = 2 + (Macro - 1) * 4
                    local P_Num_Spd = base + 3 -- Param4
                    local pv = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd)
                    MakeModulationPossible(MacFxGUID2, P_Num_Spd, MacFxIdx2, P_Num_Spd, pv, 140, 'ModParam')
                end
            end
            
            if Mods == Alt and im.IsItemActivated(ctx) then
                Mc.LFO_spd_idx = 1 -- reset to 1 bar
                local norm = (Mc.LFO_spd_idx) / (#labels-1)
                local MacFxGUID2 = r.TrackFX_GetFXGUID(LT_Track, 0)
                if MacFxGUID2 then
                    local function FindFxIdxByGUID2(guid)
                        local cnt = r.TrackFX_GetCount(LT_Track)
                        for idx2 = 0, cnt-1, 1 do
                            if r.TrackFX_GetFXGUID(LT_Track, idx2) == guid then return idx2 end
                        end
                    end
                    local MacFxIdx2 = FindFxIdxByGUID2(MacFxGUID2) or 0
                    local base = 2 + (Macro - 1) * 4
                    local P_Num_Spd = base + 3 -- Param4
                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx2, P_Num_Spd, norm)
                end
                -- Ensure JSFX macro type is LFO after reset as well
                ChangeLFO(30, 0, 9, 'LFO Period Continuous')
                ChangeLFO(12, 0, 9, 'LFO Speed')
            end

            SL(nil, 30)
            -- mod line indicated by AddDrag/DrawModLines
            -- meta-mod assignment now uses standard AddDrag behavior (no per-control right-drag)



            if Mc.Changing_Rel_Node then
                Mc.Rel_Node = Mc.Changing_Rel_Node
                ChangeLFO(20, Mc.Rel_Node, nil, 'LFO_Rel_Node')
                Mc.Changing_Rel_Node = nil
            end



            if im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                LFO.WinHovered = Ident -- this one doesn't get cleared after unhovering, to inform script which one to stay open
                LFO.HvringWin = Ident
                Update_Info_To_Jsfx(Mc.Node, 'LFO'..Macro , true, Macro, true)

                -- Shift + mouse wheel to zoom horizontally
                if Mods == Shift and Wheel_V ~= 0 then
                    Mc.Zoom = Mc.Zoom or 1
                    local zstep = 1 + (Wheel_V > 0 and 0.1 or -0.1)
                    Mc.Zoom = SetMinMax(Mc.Zoom * zstep, 1, 4)
                    Wheel_V = 0 -- consume wheel so default handlers don't use it
                end

            else
                LFO.HvringWin = nil
                LFO.DontOpenNextFrame = true -- it's needed so the open_LFO_Win function doesn't get called twice when user 'unhover' the lfo window

            end
            -- End left child
            im.EndChild(ctx)

            -- Right child: embedded shape selector (with tabs)
            im.SameLine(ctx)
            -- Match the height of main content region
            local _, mainTopY = im.GetItemRectMin(ctx)
            local popupMinX, popupMinY = im.GetWindowPos(ctx)
            local _, popupH = im.GetWindowSize(ctx)
            local shapesH = popupH - (mainTopY - popupMinY) - 10
            if im.BeginChild(ctx, '##LFO_Shapes_'..Macro, rightW, shapesH, 0) then 
                if im.IsWindowAppearing(ctx) then
                    LFO.NodeBeforePreview = Mc.Node
                end
                if not im.ValidatePtr(ShapeFilter, 'ImGui_TextFilter*') then
                    ShapeFilter = im.CreateTextFilter(Shape_Filter_Txt)
                end
                local WDL = im.GetWindowDrawList(ctx)
                local W, H = 90, 45
                local anyHoveredThisFrame = false
                local function file_exists(path)
                    local f = io.open(path, 'r')
                    if f then f:close() return true end
                    return false
                end
                local function DrawShapesInSelector(Shapes)
                    local AnyShapeHovered
                    if im.BeginTable(ctx, '##shapesTable'..Macro, 2, im.TableFlags_SizingFixedFit) then
                    for i, v in ipairs(Shapes) do
                        if im.TextFilter_PassFilter(ShapeFilter, v.Name) then
                                im.TableNextColumn(ctx)
                                im.BeginGroup(ctx)
                                -- Darker preview box background
                                im.PushStyleColor(ctx, im.Col_Button, 0x222222ff)
                                im.PushStyleColor(ctx, im.Col_ButtonHovered, 0x2d2d2dff)
                                im.PushStyleColor(ctx, im.Col_ButtonActive, 0x353535ff)
                                local clicked = im.Button(ctx, '##shape' .. (v.Name or i) .. i, W, H)
                                if v.Name and im.BeginDragDropSource(ctx) then
                                    LFO.SuppressShapeClick = true
                                    im.SetDragDropPayload(ctx, 'LFO_SHAPE_NAME', v.Name)
                                    im.Text(ctx, v.Name)
                                    im.EndDragDropSource(ctx)
                                end
                                if im.BeginDragDropTarget(ctx) then
                                    local accepted, payload = im.AcceptDragDropPayload(ctx, 'LFO_SHAPE_NAME')
                                    if accepted and payload and v.Name then
                                        local srcName = tostring(payload)
                                        if srcName ~= v.Name then
                                            LFO.ShapeOrder = LFO.ShapeOrder or {}
                                            local srcIdx
                                            for oi, onm in ipairs(LFO.ShapeOrder) do if onm == srcName then srcIdx = oi break end end
                                            if srcIdx then table.remove(LFO.ShapeOrder, srcIdx) end
                                            table.insert(LFO.ShapeOrder, i, srcName)
                                            local basePath = ConcatPath(CurrentDirectory, 'src', (Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and 'Envelope Shapes' or 'LFO Shapes')
                                            local ordw = io.open(ConcatPath(basePath, '_order.txt'), 'w')
                                            if ordw then for _,name in ipairs(LFO.ShapeOrder) do ordw:write(name, '\n') end ordw:close() end
                                        end
                                    end
                                    im.EndDragDropTarget(ctx)
                                end
                                if clicked and not LFO.SuppressShapeClick then
                                    Mc.Node = v
                                    LFO.NewShapeChosen = v
                                    LFO.ShapeChangeAnimStart = r.time_precise()
                                end
                                im.PopStyleColor(ctx, 3)
                            if im.IsItemHovered(ctx) then
                                Mc.Node = v
                                AnyShapeHovered = true
                                LFO.AnyShapeHovered = true
                                Update_Info_To_Jsfx(Mc.Node, 'LFO'..Macro , true, Macro, true)
                            end
                                local Ls2, Ts2 = im.GetItemRectMin(ctx)
                                local w2, h2 = im.GetItemRectSize(ctx)
                                im.DrawList_AddRect(WDL, Ls2, Ts2, Ls2 + w2, Ts2 + h2, 0xffffff66)
                            local thick = 4
                                for ii, V in ipairs(v) do
                                    local w = w2 - thick
                                    local h = h2 - thick
                                    Draw_Curve(WDL, v, ii, Ls2, Ls2 + w, Ts2 + h, w, h, 3, 0xffffffff, thick/2)
                                end
                                -- editable name field directly under box (tight spacing)
                                LFO.ShapeNameBuf = LFO.ShapeNameBuf or {}
                                local key = (v.Name or tostring(i)) .. '_' .. tostring(i)
                                LFO.ShapeNameBuf[key] = LFO.ShapeNameBuf[key] or (v.Name or tostring(i))
                                im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 4, 2)
                                im.SetNextItemWidth(ctx, W)
                                local changed, newName = im.InputText(ctx, '##shapeName'..key, LFO.ShapeNameBuf[key])
                                if changed then LFO.ShapeNameBuf[key] = newName end
                                -- Commit rename on edit completion (Enter/tab/unfocus)
                                if im.IsItemDeactivatedAfterEdit(ctx) then
                                    local oldName = v.Name or tostring(i)
                                    local basePath = ConcatPath(CurrentDirectory, 'src', (Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and 'Envelope Shapes' or 'LFO Shapes')
                                    local oldPath = ConcatPath(basePath, oldName .. '.ini')
                                    local newPath = ConcatPath(basePath, (LFO.ShapeNameBuf[key] or '') .. '.ini')
                                    local newTrim = (LFO.ShapeNameBuf[key] or ''):gsub('^%s*(.-)%s*$', '%1')
                                    if newTrim ~= '' and oldName ~= newTrim and file_exists(oldPath) and not file_exists(newPath) then
                                        os.rename(oldPath, newPath)
                                        v.Name = newTrim
                                        LFO.ShapeNameBuf[key] = newTrim
                                        -- update persisted draw order if present
                                        if LFO.ShapeOrder then
                                            for oi, onm in ipairs(LFO.ShapeOrder) do
                                                if onm == oldName then LFO.ShapeOrder[oi] = newTrim break end
                                            end
                                            local ordw = io.open(ConcatPath(basePath, '_order.txt'), 'w')
                                            if ordw then for _,name in ipairs(LFO.ShapeOrder) do ordw:write(name, '\n') end ordw:close() end
                                        end
                                    end
                                end
                                im.PopStyleVar(ctx)
                                -- delete button region at top-right of the box
                                local gL, gT = Ls2, Ts2
                                if im.IsMouseHoveringRect(ctx, gL + W - 10, gT, gL + W, gT + 10) then
                                    SL(W - 8)
                                    if TrashIcon(8, 'delete' .. (v.Name or i), 0xffffff00) then
                                        im.OpenPopup(ctx, 'Delete shape prompt' .. i)
                                        im.SetNextWindowPos(ctx, gL + W - 60, gT + 10)
                                    end
                                end
                                im.EndGroup(ctx)
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
                        im.EndTable(ctx)
                    end
                    if LFO.SuppressShapeClick and im.IsMouseReleased(ctx, 0) then LFO.SuppressShapeClick = false end
                    return AnyShapeHovered
                end

                -- Header row: Tab bar (left) and Save controls within shapes area
                local function DrawSaveControlsEmbed(scope)
                    LFO.ShapeSaveBuf = LFO.ShapeSaveBuf or {}
                    local key = 'embed_'..scope..'_'..tostring(Macro)
                    LFO.ShapeSaveBuf[key] = LFO.ShapeSaveBuf[key] or ''
                    local avail = im.GetContentRegionAvail(ctx)
                    local saveBtnW = 18
                    local inputW = math.max(50, (avail or 180) - saveBtnW - 8)
                    im.SetNextItemWidth(ctx, inputW)
                    local _, txt = im.InputTextWithHint(ctx, '##shpname_'..key, 'enter shape name', LFO.ShapeSaveBuf[key])
                    if txt ~= nil then LFO.ShapeSaveBuf[key] = txt end
                    im.SameLine(ctx)
                    local nameTrim = (LFO.ShapeSaveBuf[key] or ''):gsub('^%s*(.-)%s*$', '%1')
                    -- For Project/Track allow empty name; for Global require name
                    local disable = (scope == 'Global' and nameTrim == '') and true or false
                    if disable then im.BeginDisabled(ctx) end
                    if im.ImageButton(ctx, '##save_shape_embed_' .. scope .. '_' .. Macro, Img.Save, 14, 14) then
                        if scope == 'Global' then
                            Save_Shape_To_Global_ByName(Mc, nameTrim)
                            LFO.ShapeSaveBuf[key] = ''
                        elseif scope == 'Project' then
                            Save_Shape_To_Project_WithName(Mc, nameTrim ~= '' and nameTrim or nil)
                            LFO.ShapeSaveBuf[key] = ''
                        elseif scope == 'Track' then
                            Save_Shape_To_Track_WithName(Mc, nameTrim ~= '' and nameTrim or nil)
                            LFO.ShapeSaveBuf[key] = ''
                        end
                    end
                    if disable then im.EndDisabled(ctx) end
                end
                if im.BeginTable(ctx, '##shapeHeader'..Macro, 2, im.TableFlags_SizingStretchProp) then
                    if im.TableSetupColumn then
                        im.TableSetupColumn(ctx, 'tabs', im.TableColumnFlags_WidthStretch)
                        im.TableSetupColumn(ctx, 'spacer', im.TableColumnFlags_WidthFixed, 1)
                    end
                    im.TableNextRow(ctx)
                    im.TableSetColumnIndex(ctx, 0)
                    if im.BeginTabBar(ctx, 'shape select tab bar') then
                        -- Global tab
                        if im.BeginTabItem(ctx, 'Global') then
                            DrawSaveControlsEmbed('Global')
                            local Shapes = {}
                            local basePath = ConcatPath(CurrentDirectory, 'src', (Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and 'Envelope Shapes' or 'LFO Shapes')
                            local F = scandir(basePath)
                            for i, v in ipairs(F) do
                                local Shape = ((Mc and (Mc.Type == 'Envelope' or Mc.Type == 'envelope')) and Get_Env_Shape_From_File or Get_LFO_Shape_From_File)(v)
                                if Shape then
                                    Shape.Name = tostring(v):sub(0, -5)
                                    table.insert(Shapes, Shape)
                                end
                            end
                            if not LFO.ShapeOrder then
                                local ordr = {}
                                local ordf = io.open(ConcatPath(basePath, '_order.txt'), 'r')
                                if ordf then
                                    for line in ordf:lines() do if line and line ~= '' then table.insert(ordr, line) end end
                                    ordf:close()
                                end
                                if #ordr == 0 then for _,sh in ipairs(Shapes) do if sh.Name then table.insert(ordr, sh.Name) end end end
                                LFO.ShapeOrder = ordr
                            end
                            local byName, included = {}, {}
                            for _,sh in ipairs(Shapes) do if sh.Name then byName[sh.Name] = sh end end
                            local OrderedShapes = {}
                            for _,nm in ipairs(LFO.ShapeOrder) do local sh = byName[nm]; if sh then table.insert(OrderedShapes, sh) included[nm] = true end end
                            for _,sh in ipairs(Shapes) do if sh.Name and not included[sh.Name] then table.insert(OrderedShapes, sh) table.insert(LFO.ShapeOrder, sh.Name) end end
                            anyHoveredThisFrame = DrawShapesInSelector(OrderedShapes) or anyHoveredThisFrame
                            im.EndTabItem(ctx)
                        end
                        -- Project tab
                        if im.BeginTabItem(ctx, 'Project') then
                            DrawSaveControlsEmbed('Project')
                            local Shapes = {}
                            local HowManySavedShapes = getProjSavedInfo('LFO Saved Shape Count')
                            for I = 1, HowManySavedShapes or 0, 1 do
                                local Shape = {}
                                    local Ct = getProjSavedInfo('LFO Shape' .. I .. 'Node Count = ')
                                for i = 1, Ct or 1, 1 do
                                    Shape[i] = Shape[i] or {}
                                    Shape[i].x = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'x = ')
                                    Shape[i].y = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'y = ')
                                    Shape[i].ctrlX = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ')
                                    Shape[i].ctrlY = getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ')
                                    -- normalize numeric indices for drawing
                                    Shape[i][1] = tonumber(Shape[i].x) or Shape[i][1] or 0
                                    Shape[i][2] = tonumber(Shape[i].y) or Shape[i][2] or 0
                                end
                                -- read saved name for project shape slot
                                local nm = getProjSavedInfo('LFO Shape' .. I .. ' Name', 'str')
                                if nm and Shape[1] then Shape.Name = nm end
                                if Shape[1] then table.insert(Shapes, Shape) end
                            end
                            anyHoveredThisFrame = DrawShapesInSelector(Shapes) or anyHoveredThisFrame
                            im.EndTabItem(ctx)
                        end
                        -- Track tab
                        if im.BeginTabItem(ctx, 'Track') then
                            DrawSaveControlsEmbed('Track')
                            local Shapes = {}
                            local HowManySavedShapes = GetTrkSavedInfo('LFO Saved Shape Count')
                            for I = 1, HowManySavedShapes or 0, 1 do
                                local Shape = {}
                                    local Ct = GetTrkSavedInfo('Shape' .. I .. 'LFO Node Count = ')
                                for i = 1, Ct or 1, 1 do
                                    Shape[i] = Shape[i] or {}
                                        Shape[i].x = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. ' x') or GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'x = ')
                                        Shape[i].y = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. ' y') or GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'y = ')
                                        Shape[i].ctrlX = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlX = ')
                                        Shape[i].ctrlY = GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlY = ')
                                        -- normalize numeric indices for drawing
                                        Shape[i][1] = tonumber(Shape[i].x) or Shape[i][1] or 0
                                        Shape[i][2] = tonumber(Shape[i].y) or Shape[i][2] or 0
                                    end
                                    -- read saved name for track shape slot
                                    local nm = GetTrkSavedInfo('Shape' .. I .. ' Name', LT_Track, 'str')
                                    if nm and Shape[1] then Shape.Name = nm end
                                    if Shape[1] then table.insert(Shapes, Shape) end
                                end
                            anyHoveredThisFrame = DrawShapesInSelector(Shapes) or anyHoveredThisFrame
                            im.EndTabItem(ctx)
                        end
                        im.EndTabBar(ctx)
                    end
                    im.EndTable(ctx)
                end
                -- Save controls now drawn per-tab above shapes
                -- Revert preview when unhovering all shapes; keep only on click
                if LFO.AnyShapeHovered and not anyHoveredThisFrame then
                    if LFO.NewShapeChosen then
                        Mc.Node = LFO.NewShapeChosen
                    else
                        Mc.Node = LFO.NodeBeforePreview
                    end
                    LFO.NodeBeforePreview = Mc.Node
                    LFO.AnyShapeHovered = nil
                    LFO.NewShapeChosen = nil
                end
                im.EndChild(ctx)
            end
            -- Close only on outside-click; ignore clicks on empty space inside the popup
            if drawingPopup then
                if not LFO.Tweaking then 
                    if im.IsMouseClicked(ctx, 0) and not im.IsAnyItemActive(ctx) then
                        -- If the current popup (including its children) is not hovered, treat as outside click
                        if not im.IsWindowHovered(ctx, im.HoveredFlags_RootAndChildWindows) then
                            LFO.WinHovered = nil; LFO.HvringWin = nil; LFO.Tweaking = nil
                            im.CloseCurrentPopup(ctx)
                            im.EndPopup(ctx)
                            return
                        end
                    end
                end
                im.EndPopup(ctx)
            else
                -- floating window
                im.End(ctx)
            end
        end


        if LFO.OpenShapeSelect == Macro then
            im.SetNextWindowPos(ctx, LFO_WIN_POS[1] + LFOWindowW  , T - LFO.DummyH - 200)
            if not im.ValidatePtr(ShapeFilter, "ImGui_TextFilter*") then
                ShapeFilter = im.CreateTextFilter(Shape_Filter_Txt)
            end
            im.SetNextWindowSizeConstraints(ctx, 220, 150, 240, 700)
            if im.Begin(ctx, 'Shape Selection Popup', true, im.WindowFlags_NoTitleBar|im.WindowFlags_AlwaysAutoResize) then
                local W, H = 160, 80
                local function DrawShapesInSelector(Shapes)
                    local AnyShapeHovered
                    for i, v in ipairs(Shapes) do
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

                            local clicked = im.Button(ctx, '##' .. (v.Name or i) .. i, W, H)
                            if v.Name and im.BeginDragDropSource(ctx) then
                                LFO.SuppressShapeClick = true
                                im.SetDragDropPayload(ctx, 'LFO_SHAPE_NAME', v.Name)
                                im.Text(ctx, v.Name)
                                im.EndDragDropSource(ctx)
                            end
                            if im.BeginDragDropTarget(ctx) then
                                local accepted, payload = im.AcceptDragDropPayload(ctx, 'LFO_SHAPE_NAME')
                                if accepted and payload and v.Name then
                                    local srcName = tostring(payload)
                                    if srcName ~= v.Name then
                                        LFO.ShapeOrder = LFO.ShapeOrder or {}
                                        local srcIdx
                                        for oi, onm in ipairs(LFO.ShapeOrder) do if onm == srcName then srcIdx = oi break end end
                                        if srcIdx then table.remove(LFO.ShapeOrder, srcIdx) end
                                        table.insert(LFO.ShapeOrder, i, srcName)
                                        local basePath = ConcatPath(CurrentDirectory, 'src', 'LFO Shapes')
                                        local ordw = io.open(ConcatPath(basePath, '_order.txt'), 'w')
                                        if ordw then for _,name in ipairs(LFO.ShapeOrder) do ordw:write(name, '\n') end ordw:close() end
                                    end
                                end
                                im.EndDragDropTarget(ctx)
                            end
                            if clicked and not LFO.SuppressShapeClick then
                                Mc.Node = v
                                LFO.NewShapeChosen = v
                                LFO.ShapeChangeAnimStart = r.time_precise()
                            end
                            if im.IsItemHovered(ctx) then
                                Mc.Node = v
                                AnyShapeHovered = true
                                LFO.AnyShapeHovered = true
                                Update_Info_To_Jsfx(Mc.Node, 'LFO'..Macro , true, Macro, true)
                            end
                            local L, T = im.GetItemRectMin(ctx)
                            local w, h = im.GetItemRectSize(ctx)
                            --im.DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff33)
                            im.DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)
                            local thick = 4
                            for ii, V in ipairs(v )do 
                                local w = w - thick 
                                local h = h - thick
                                Draw_Curve (WDL, v , ii, L, L+w  , T+h, w, h, 3 , 0xffffffff, thick/2)
                            end
                           -- DrawShape(v, L, w, h, T, 0xffffffaa)
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


                    if LFO.SuppressShapeClick and im.IsMouseReleased(ctx, 0) then LFO.SuppressShapeClick = false end
                    return AnyShapeHovered
                end

                if NeedSendAllGmemLater == Macro then
                    timer = (timer or 0) + 1
                    if timer == 2 then
                        --Send_All_Coord(All_Coord)
                        Update_Info_To_Jsfx(Mc.Node, 'LFO'..Macro , true, Macro, true)
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
                        r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count', tostring((Count or 1) - 1))
                        table.remove(Shapes, LFO.DeleteShape)

                        for I, V in ipairs(Shapes) do -- do for every shape
                            for i, v in ipairs(V) do  --- do for every node
                                if i == 1 then
                                    r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node Count = ', tostring(#V))
                                end

                                local vx = (type(v) == 'table') and (v.x or v[1]) or v
                                local vy = (type(v) == 'table') and (v.y or v[2]) or nil
                                local vcx = (type(v) == 'table') and (v.ctrlX) or nil
                                local vcy = (type(v) == 'table') and (v.ctrlY) or nil

                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'x = ', tostring(vx or ''))
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. 'y = ', tostring(vy or ''))
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', tostring(vcx or ''))
                                r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', tostring(vcy or ''))
                            end
                        end
                        LFO.DeleteShape = nil
                    end

                    DrawShapesInSelector(Shapes)
                end

                -- Header row: Tab bar (left) and Save button (right)
                
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
                    -- Save controls row for popup: input with hint + save button
                    
                        LFO.ShapeSaveBuf = LFO.ShapeSaveBuf or {}
                        local key = 'popup_'..tostring(Macro)
                        LFO.ShapeSaveBuf[key] = LFO.ShapeSaveBuf[key] or ''
                        local avail = im.GetContentRegionAvail(ctx)
                        local saveBtnW = 18
                        local inputW = math.max(50, (avail or 200) - saveBtnW - 8)
                        im.SetNextItemWidth(ctx, inputW)
                        local _, txt = im.InputTextWithHint(ctx, '##shpname_'..key, 'enter shape name', LFO.ShapeSaveBuf[key])
                        if txt ~= nil then LFO.ShapeSaveBuf[key] = txt end
                        im.SameLine(ctx)
                        local nameTrim = (LFO.ShapeSaveBuf[key] or ''):gsub('^%s*(.-)%s*$', '%1')
                        local disable = (LFO.OpenedTab == 'Global' and nameTrim == '') and true or false
                        if disable then im.BeginDisabled(ctx) end
                        if im.ImageButton(ctx, '##save_shape_popup' .. Macro, Img.Save, 14, 14) then
                            if LFO.OpenedTab == 'Global' then
                                Save_Shape_To_Global_ByName(Mc, nameTrim)
                                LFO.ShapeSaveBuf[key] = ''
                            elseif LFO.OpenedTab == 'Project' then
                                Save_Shape_To_Project_WithName(Mc, nameTrim ~= '' and nameTrim or nil)
                                LFO.ShapeSaveBuf[key] = ''
                            elseif LFO.OpenedTab == 'Track' then
                                Save_Shape_To_Track_WithName(Mc, nameTrim ~= '' and nameTrim or nil)
                                LFO.ShapeSaveBuf[key] = ''
                            end
                        end
                        if disable then im.EndDisabled(ctx) end
                    


                if im.IsWindowHovered(ctx, im.FocusedFlags_RootAndChildWindows) then
                    LFO.HoveringShapeWin = Ident
                else
                    LFO.HoveringShapeWin = nil
                end
                im.End(ctx)
            end
        end


        return tweaking, All_Coord
    end

    local HvrOnBtn = im.IsItemHovered(ctx)

    local function Open_LFO_WIN_If_Clicked()

        local PinID = TrkID .. 'Macro = ' .. Macro
        --[[ if HvrOnBtn and IsContainer then 
            r.TrackFX_GetFXGUID(Track, FX[FxGUID].parent)
        end ]]

        -- Popup label must match inside open_LFO_Win
        local PopupLbl = (IsContainer and 'Container' or '')..'LFO Popup' .. Macro .. (FxGUID or '')

        -- Open popup when clicking the modulator
        if rv and not (LFO.SuppressOpenFrames and LFO.SuppressOpenFrames > 0) then
            if LFO.WinHovered == Ident then
                -- Close if already open
                LFO.WinHovered = nil
                im.CloseCurrentPopup(ctx)
            else
            LFO.WinHovered = Ident
                im.OpenPopup(ctx, PopupLbl)
                LFO.JustOpened = true
        end
    end
        -- Cooldown to prevent immediate reopen after an outside click close
        if LFO.SuppressOpenFrames and LFO.SuppressOpenFrames > 0 then
            LFO.SuppressOpenFrames = LFO.SuppressOpenFrames - 1
        end

        -- Keep open if already opened and conditions are met
            LFO.Tweaking = open_LFO_Win(Track, Macro, IsContainer, PosForWin,Mc, FxGUID)
    end


    Open_LFO_WIN_If_Clicked()
    -- (legacy close logic removed; using rect-based close below)





    if not IsLBtnHeld then
        LFO_DragDir = nil
        LFO_MsX_Start, LFO_MsY_Start = nil
    end




    Save_LFO_Dialog (Macro, L, T - LFO.DummyH, Mc)

end



function XY_BOX(Mc, i, Width, IsContainer,TB) -- FX_Idx is for container macro
    if Mc.Type ~= 'XY' then return end 
    IsContainer = IsContainer or false
    TB = TB or 'Track'
    if IsContainer then 
        r.gmem_attach('ContainerMacro')
    end 
    local Macro_FXid
    if TB == 'Track' then
        Macro_FXid = 0
    elseif type(TB) == 'table' and TB[1] and TB[1].addr_fxid then
        Macro_FXid = TB[1].addr_fxid
    else
        Macro_FXid = 0
    end

    -- Initialize XY pad values from parameters if not already set
    if not Mc.XY_Pad_X then
        local P_Num_X, P_Num_Y
        if IsContainer then
            -- Container macros use dedicated XY pad sliders: slider26-41
            -- XY Pad M X = slider(26 + (M-1)*2) = param index 25 + (M-1)*2
            -- XY Pad M Y = slider(27 + (M-1)*2) = param index 26 + (M-1)*2
            P_Num_X = 25 + (i - 1) * 2
            P_Num_Y = 26 + (i - 1) * 2
        else
            -- Track macros use modulator parameters: X = Param 1, Y = Param 2
            P_Num_X = 2 + (i - 1) * 4
            P_Num_Y = 2 + (i - 1) * 4 + 1
        end
        Mc.XY_Pad_X = math.floor(r.TrackFX_GetParamNormalized(LT_Track, Macro_FXid, P_Num_X) * 127 + 0.5)
        Mc.XY_Pad_Y = math.floor(r.TrackFX_GetParamNormalized(LT_Track, Macro_FXid, P_Num_Y) * 127 + 0.5)
    end
    
    --local W = (VP.w - 10) / 12 - 3 -- old W 
    local function PAD()
        local pd = 2
        local cX, cY = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, cX+ pd , cY + pd)
        
        local W = (Width or 60 ) / 2.5
        local H = (Width or 60)  /2.5
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

    local function PAD_INTERACTION()
        if im.IsItemClicked(ctx, 1) and im.IsMouseDoubleClicked(ctx, 1) then 
            Assign_Macro('Y')
        elseif im.IsItemClicked(ctx, 1)  then 
            Assign_Macro('X')
        end
        if im.IsItemActive(ctx) then        
           HideCursorTillMouseUp(0)
           local DtX, DtY = im.GetMouseDragDelta(ctx)
           Mc.XY_Pad_X = Mc.XY_Pad_X or 0 
           Mc.XY_Pad_Y = Mc.XY_Pad_Y or 0
           Mc.XY_Pad_X = SetMinMax(Mc.XY_Pad_X + DtX, 0, 127)
           Mc.XY_Pad_Y = SetMinMax(Mc.XY_Pad_Y - DtY, 0, 127)  

           local P_Num_X, P_Num_Y
           if IsContainer then
               P_Num_X = 25 + (i - 1) * 2
               P_Num_Y = 26 + (i - 1) * 2
           else
               P_Num_X = 2 + (i - 1) * 4
               P_Num_Y = 2 + (i - 1) * 4 + 1
           end
           r.TrackFX_SetParamNormalized(LT_Track, Macro_FXid, P_Num_X, Mc.XY_Pad_X / 127)
           r.TrackFX_SetParamNormalized(LT_Track, Macro_FXid, P_Num_Y, Mc.XY_Pad_Y / 127)

           if DtX ~= 0 or DtY ~= 0 then 
                im.ResetMouseDragDelta(ctx)
           end

          

        end
        Open_Menu()
    end

    local function Drags()

        local flg = im.SliderFlags_NoInput
        im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, 0)
        local cX, cY = im.GetCursorPos(ctx)
        --im.Text(ctx, 'X :')
        im.SetNextItemWidth(ctx, Width/1.5)
        _, Mc.XY_Pad_X = im.DragDouble(ctx, '##X', Mc.XY_Pad_X or 0, 1, 0, 127, 'X : %.0f', flg)
        Assign_Macro('X')
        if im.IsItemActive (ctx) then 
            local P_Num_X = IsContainer and (25 + (i - 1) * 2) or (2 + (i - 1) * 4)
            r.TrackFX_SetParamNormalized(LT_Track, Macro_FXid, P_Num_X, Mc.XY_Pad_X / 127)
        end
        im.SetCursorPos(ctx, cX , cY + 15)
        im.SetNextItemWidth(ctx, Width/1.5)
        if ASSIGNING_XY_PAD == 'X' and AssigningMacro == i   then 
            Highlight_Itm(WDL, nil, EightColors.LFO[i]) 
        end
        _, Mc.XY_Pad_Y = im.DragDouble(ctx, '##Y', Mc.XY_Pad_Y or 0, 1, 0, 127, 'Y : %.f', flg)
        Assign_Macro('Y')
        if im.IsItemActive (ctx) then 
            local P_Num_Y = IsContainer and (26 + (i - 1) * 2) or (2 + (i - 1) * 4 + 1)
            r.TrackFX_SetParamNormalized(LT_Track, Macro_FXid, P_Num_Y, Mc.XY_Pad_Y / 127)
        end
        if ASSIGNING_XY_PAD == 'Y' and AssigningMacro == i   then 
            Highlight_Itm(WDL, nil, EightColors.LFO[i]) 
        end

        im.PopStyleVar(ctx)
        im.SetCursorPos(ctx, cX, cY)

    end
    im.BeginGroup(ctx)

    PAD()
    PAD_INTERACTION()
    if not IsContainer then 
        SL()
        Drags()
    end
    im.EndGroup(ctx)
    Open_Menu()
    if im.IsItemClicked(ctx, 1 ) then Mc.TweakingKnob = 2 end 

    
end

function Editable_Modulator_Label(mc,  i,  Size , IsContainer,FxGUID)

    local Type_Str = {Follower= 'Follow' ,  }
    local I = i +1

    local Save_Idx = IsContainer and 'Container '..FxGUID..' Macro '..I..' Name' or 'Mod'..i..' Name'
    mc.Name = mc.Name or  Load_from_Trk(Save_Idx, LT_Track)
    local Sz = IsContainer and Size * 2 or Size * 4
    im.SetNextItemWidth(ctx , Sz)
    im.AlignTextToFramePadding(ctx)


    local def_lbl = mc.Name or ( mc.Type .. (IsContainer and I or i))
    local font = IsContainer and Arial_11 or Arial_12
    
    im.PushFont(ctx, font)
    local TextSz = im.CalcTextSize(ctx, def_lbl)
    im.PopFont(ctx)

    if TextSz > Size then 
        im.PushFont(ctx, Arial_10)
    else 
        im.PushFont(ctx, font)
    end

    local rv, label = im.InputText(ctx, '##'..i..' FxGUID = '..FxGUID, def_lbl, im.InputTextFlags_AutoSelectAll)
    im.PopFont(ctx)
    if rv then 
        mc.Name = label
        Save_to_Trk(Save_Idx , label)
    end 
end



function MacroKnob(mc, i, Size , TB, IsContainer, FxGUID)
    local I =  i +1
    local row = math.ceil ( I /4 )

    if mc.Type =='Macro' and ( TB and TB[1]  or TB =='Track') then 
        mc.Val = mc.Val 
        local function FindMacrosFXIdx()
            local cnt = r.TrackFX_GetCount(LT_Track)
            for idx = 0, cnt-1, 1 do
                local rv, name = r.TrackFX_GetFXName(LT_Track, idx, '')
                if name and name:find('FXD Macros') then return idx end
            end
            return 0
        end
        local Macro_FXid = TB =='Track' and FindMacrosFXIdx() or TB[1].addr_fxid
        local FxGUID = FxGUID or TrkID
        local fx = FX[FxGUID] or Trk[TrkID]

        local W = Size + Size*4 
        local x, y = im.GetCursorScreenPos(ctx)
        local function Knob()
            if MACRO_SZ then 
                im.DrawList_AddRectFilled(im.GetWindowDrawList(ctx), x , y , x+ MACRO_SZ[1], y + MACRO_SZ[2], ThemeClr('Track_Modulator_Individual_BG'))
            end
            local ii = IsContainer and I or i
            local Param1Idx = 2 + (i - 1) * 4
            local v = r.TrackFX_GetParamNormalized(LT_Track, Macro_FXid, Param1Idx)
            mc.TweakingKnob , mc.Val , mc.center = AddKnob_Simple(ctx , FxGUID..'Macro'..i,  mc.Val or v, Size, -1, ThemeClr('Track_Modulator_Knob'), EightColors.LFO[ii], EightColors.LFO[ii] , EightColors.Bright_HighSat[ii])
            if im.IsItemHovered(ctx) then 
                fx.HvrMacro =  i
                AnyMacroHovered = true 
            end
            Highlight_Itm(WDL, nil,0xffffff44)
            --im.SetNextItemWidth(ctx, Size*2.7)
            if not IsContainer then
                SL(nil, 2)
           -- else
                --im.SetCursorPos(ctx,35 + (Size*3 * (row-1)),  10+ (i-4*(row-1)) * (Size*2+25) + Size*1.6)
            end

            if mc.TweakingKnob == 1  then 


                r.TrackFX_SetParamNormalized(LT_Track, Macro_FXid, Param1Idx, mc.Val)
            end
        end

        im.BeginGroup(ctx)
        
        im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 0, -1 )
        im.PushStyleVar(ctx, im.StyleVar_FramePadding ,0, 0 )
        Knob()

        Editable_Modulator_Label(mc, i, Size , IsContainer,FxGUID)
        im.PopStyleVar(ctx,2)

        im.EndGroup(ctx)
       -- Highlight_Itm( WDL, EightColors.LFO[i], EightColors.LFO[i])
    end
end



-- Sync Random modulator parameters to sliders continuously
function Sync_Random_Parameters_To_Sliders(Mc, i, IsContainer, FxGUID)
    if Mc.Type ~= 'Random' then return end
    
    local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
    if MacFxGUID then
        local function FindFxIdxByGUID(guid)
            local cnt = r.TrackFX_GetCount(LT_Track)
            for idx = 0, cnt-1, 1 do
                if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
            end
        end
        local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
        local base = 2 + (i - 1) * 4
        
        -- Sync Interval (Param1)
        local interval_val = Mc.Random_Int or 200
        local interval_norm = (interval_val - 1) / 499
        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + 0, interval_norm)
        
        -- Sync Smooth (Param2)
        local smooth_val = Mc.Random_Smooth or 0
        local smooth_norm = smooth_val / 100
        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + 1, smooth_norm)
        
        -- Sync Chance (Param3)
        local chance_val = Mc.Random_Chance or 100
        local chance_norm = chance_val / 100
        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + 2, chance_norm)
    end
end

function Random_Modulator_Box(Mc, i , Width , Height, IsContainer, FxGUID)

    if Mc.Type ~= 'Random' then return end

    local boxWidth, boxHeight = Width, Height or Width/3
    local L, T = im.GetCursorScreenPos(ctx)
    local WinW, WinH = 100, 100 
    local Gmem_Space = IsContainer and 'ContainerMacro' or 'ParamValues'
    
    r.gmem_attach(Gmem_Space)
    local function Draw_Value_Histogram()
        local L, T = im.GetItemRectMin(ctx)
        local W, H = im.GetItemRectSize(ctx)
        
        Mc.Random_Pts = Mc.Random_Pts or  {}

        local v = r.gmem_read(100+ i) / 127  -- Normalize from 0-127 to 0-1


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
        im.DrawList_PathFillConcave(WDL, EightColors.HighSat_MidBright[i] or ThemeClr('Accent_Clr'))
        im.DrawList_PathClear(WDL)


        -- Draw Line
        for i , v in ipairs(Mc.Random_Pts) do
            local x = L  + (i-1) --[[ * (W/#Mc.Random_Pts) ]]
            local y = (T+ H ) - (v * H)
            im.DrawList_PathLineTo(WDL, x, y)
        end
        im.DrawList_PathStroke(WDL, EightColors.LFO[i] or ThemeClr('Accent_Clr'), nil, 2.5)

        im.DrawList_PathClear(WDL)
    end
    local function parameters(Open_Random_Mod)
        local function Change_Prop(mode, v , str, paramIdx)
            local str = IsContainer and 'Container '..FxGUID .. str  or str
            Save_to_Trk(str , v)
            -- Update unified parameter slider (JSFX reads from sliders directly)
            if paramIdx ~= nil then
                local function FindMacrosFXIdx()
                    local cnt = r.TrackFX_GetCount(LT_Track)
                    for idx = 0, cnt-1, 1 do
                        local rv, name = r.TrackFX_GetFXName(LT_Track, idx, '')
                        if name and (name:find('FXD Macros') or name:find('FXD Container Macros')) then return idx end
                    end
                end
                local MacFxIdx = FindMacrosFXIdx()
                if MacFxIdx then
                    local base = 2 + (i - 1) * 4
                    local norm_value
                    if paramIdx == 0 then -- Interval: 1-500 → normalized (value-1)/499
                        norm_value = (v - 1) / 499
                    elseif paramIdx == 1 then -- Smooth: 0-100 → normalized value/100
                        norm_value = v / 100
                    elseif paramIdx == 2 then -- Chance: 0-100 → normalized value/100
                        norm_value = v / 100
                    elseif paramIdx == 3 then -- Sync toggle: 0 or 1
                        norm_value = (v and v>0) and 1 or 0
                    end
                    if norm_value then
                        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + paramIdx, norm_value)
                    end
                end
            end
        end
        im.SetNextWindowPos(ctx, L, T - WinH)
        if im.BeginPopup(ctx, "RandomModulatorPopup"..i, im.WindowFlags_NoDecoration | im.WindowFlags_AlwaysAutoResize) then
            
            -- Don't write mode 27 here - it triggers reinitialization in JSFX
            -- Only write mode when actually changing the type, not when opening popup
            im.Text(ctx, "Random Modulator Options")


            local was_active_int = im.IsItemActive(ctx)
            local rv , Random_Int = Drag_With_Bar(ctx, 'Interval', Mc.Random_Int or 200, 1 , 1 , 500, '%.f', flags, 0xffffff33)
            if rv then 
                Mc.Random_Int = SetMinMax(Random_Int  , 1 , 500)
                Change_Prop(27.1, Mc.Random_Int , 'Random Interval for mod'.. i , 0)
            end
            -- Save on mouse release
            if was_active_int and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' Random Interval') or ('Mod '..i..' Random Interval')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.Random_Int), true)
            end
            
            local was_active_smooth = im.IsItemActive(ctx)
            local rv , Random_Smooth = Drag_With_Bar(ctx, 'Smooth', Mc.Random_Smooth or 0, 1 , 0 , 100, '%.f %%', flags, 0xffffff33)
            if rv then 
                Mc.Random_Smooth = SetMinMax(Random_Smooth, 0 , 100)
                Change_Prop(27.2, Random_Smooth ,  'Random Smooth for mod'.. i , 1)
            end
            -- Save on mouse release
            if was_active_smooth and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' Random Smooth') or ('Mod '..i..' Random Smooth')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.Random_Smooth), true)
            end
            
            local was_active_chance = im.IsItemActive(ctx)
            local rv , Chance = Drag_With_Bar(ctx, 'Chance', Mc.Random_Chance or 100, 1 , 0 , 100, '%.f %%', flags, 0xffffff33)
            if rv then 
                Mc.Random_Chance = SetMinMax(Chance, 0 , 100)
                Change_Prop(27.3, Chance,  'Random Chance for mod'.. i, 2)
            end
            -- Save on mouse release
            if was_active_chance and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' Random Chance') or ('Mod '..i..' Random Chance')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.Random_Chance), true)
            end

            -- Sync toggle (Param4)
            local was_active_sync = im.IsItemActive(ctx)
            local clicked_sync = im.Checkbox(ctx, 'Sync to musical', (Mc.Random_Sync or 0) > 0)
            if clicked_sync ~= nil then
                -- ImGui checkbox returns boolean; normalize to 0/1
                local sync_val = clicked_sync and 1 or 0
                Mc.Random_Sync = sync_val
                Change_Prop(27.4, sync_val, ' Random Sync for mod'.. i, 3)
            end
            if was_active_sync and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' Random Sync') or ('Mod '..i..' Random Sync')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.Random_Sync or 0), true)
            end

            im.EndPopup(ctx)
        end

    end

    local BG_txt_Indent = nil -- nil to center horizontally
    local BG_txt_Sz = IsContainer and 20 or 30
    local BG_txt_Ofs_Y = IsContainer and Height/4 or nil
    local BG_txt = IsContainer and 'Rdm' or 'RDM'
    im.InvisibleButton(ctx, "RandomModulatorBox", boxWidth, boxHeight)
    Add_BG_Text_For_Modulator(BG_txt, BG_txt_Indent ,BG_txt_Sz, BG_txt_Ofs_Y)
    Draw_Value_Histogram()

    if im.IsItemClicked(ctx, 0)then 
        im.OpenPopup(ctx, 'RandomModulatorPopup'.. i )

    end
    parameters(Open_Random_Mod)
    -- Draw a visible outline for the invisible button
    local drawList = im.GetWindowDrawList(ctx)
    im.DrawList_AddRect(drawList, L, T, L + boxWidth, T + boxHeight, 0xFFFFFF22)
    if im.IsItemClicked(ctx, 1 ) then Mc.TweakingKnob = 2 end 
end


function AHDSR_Box(Mc, i, Width, Height, IsContainer, FxGUID)
    if Mc.Type ~= 'ADSR' then return end
    local LineHeight = Height or 30
    local boxWidth = Width or 98
    local boxHeight = LineHeight
    local L, T = im.GetCursorScreenPos(ctx)
    local WDL = im.GetWindowDrawList(ctx)
    local flags = 0

    local function FindMacrosFXIdx()
        local cnt = r.TrackFX_GetCount(LT_Track)
        for idx = 0, cnt-1, 1 do
            local rv, name = r.TrackFX_GetFXName(LT_Track, idx, '')
            if name and (name:find('FXD Macros') or name:find('FXD Container Macros')) then return idx end
        end
    end

    local function Update_ADSR_From_Jsfx()
        local MacFxIdx = FindMacrosFXIdx()
        if MacFxIdx then
            local base = 2 + (i - 1) * 4
            local attack_norm = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, base + 0)
            local decay_norm = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, base + 1)
            local sustain_norm = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, base + 2)
            local release_norm = r.TrackFX_GetParamNormalized(LT_Track, MacFxIdx, base + 3)
            if attack_norm then
                Mc.ADSR_Attack = math.exp(attack_norm * (math.log(2.0) - math.log(0.001)) + math.log(0.001))
            end
            if decay_norm then
                Mc.ADSR_Decay = math.exp(decay_norm * (math.log(2.0) - math.log(0.001)) + math.log(0.001))
            end
            if sustain_norm then
                Mc.ADSR_Sustain = sustain_norm
            end
            if release_norm then
                Mc.ADSR_Release = math.exp(release_norm * (math.log(2.0) - math.log(0.001)) + math.log(0.001))
            end
        end
        if IsContainer then
            r.gmem_attach('ContainerMacro')
        else
            r.gmem_attach('ParamValues')
        end
        local hold_val = r.gmem_read(180 + i)
        if hold_val then
            Mc.ADSR_Hold = hold_val
        end

        local function Read_ADSR_Saved_Val(param_name)
            local _, saved_str1
            if FxGUID then
                _, saved_str1 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod '..i..' ADSR '..param_name, '', false)
            end
            local _, saved_str2 = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod '..i..' ADSR '..param_name, '', false)
            local saved_str = (saved_str1 and saved_str1 ~= '' and saved_str1) or (saved_str2 and saved_str2 ~= '' and saved_str2) or nil
            return saved_str and tonumber(saved_str) or nil
        end

        Mc.ADSR_Curve_Attack = Read_ADSR_Saved_Val('Curve Attack') or Mc.ADSR_Curve_Attack or 0.0
        Mc.ADSR_Curve_Decay = Read_ADSR_Saved_Val('Curve Decay') or Mc.ADSR_Curve_Decay or 0.0
        Mc.ADSR_Curve_Release = Read_ADSR_Saved_Val('Curve Release') or Mc.ADSR_Curve_Release or 0.0
    end

    Update_ADSR_From_Jsfx()
    
    -- Draw envelope visualization (simple ADSR shape)
    local function Draw_ADSR_Shape()
        local A = Mc.ADSR_Attack or 0.01
        local H = Mc.ADSR_Hold or 0.0
        local D = Mc.ADSR_Decay or 0.1
        local S = Mc.ADSR_Sustain or 0.7
        local R = Mc.ADSR_Release or 0.1
        
        -- Normalize times for display (make total fit in box width)
        local totalTime = A + H + D + 0.1 + R -- add arbitrary sustain display length
        local scaleX = (boxWidth - 4) / totalTime
        
        local x1 = L + 2
        local y1 = T + boxHeight - 2
        local x2 = x1 + (A * scaleX)
        local y2 = T + 2
        local x3 = x2 + (H * scaleX) -- Hold phase
        local y3 = y2 -- Hold stays at peak
        local x4 = x3 + (D * scaleX)
        local y4 = T + 2 + ((1 - S) * (boxHeight - 4))
        local x5 = x4 + (0.1 * scaleX) -- sustain display time
        local y5 = y4
        local x6 = L + boxWidth - 2
        local y6 = y1
        
        local function Val_To_Y(v)
            return T + 2 + ((1 - v) * (boxHeight - 4))
        end

        local function Draw_Curved_Segment(xa, xb, v1, v2, curve, thick, clr)
            local ya = Val_To_Y(v1)
            local yb = Val_To_Y(v2)
            local thick = thick or 2
            local clr = clr or (EightColors.LFO[i] or 0xFFFFFFFF)
            if not curve or math.abs(curve) < 0.01 then
                im.DrawList_AddLine(WDL, xa, ya, xb, yb, clr, thick)
                return
            end
            Draw_Single_Curve(xb, xa, yb, ya, curve, thick, clr, 0)
        end

        local function Draw_Single_Curve_Partial(xa, xb, ya, yb, curve, thick, clr, targetX, targetY)
            if not targetX or not targetY then return end
            local inc = 0.5
            local vmin = math.min(ya, yb)
            local vmax = math.max(ya, yb)
            local PtsX = {}
            local PtsY = {}
            for x = xa, xb, inc do
                local I = (x - xa) / (xb - xa)
                local y = ya + (yb - ya) * I
                y = GetCurveValue(y, curve or 0, vmin, vmax, vmin, vmax)
                PtsX[#PtsX + 1] = x
                PtsY[#PtsY + 1] = y
            end
            local closest = 1
            local closest_d = nil
            for idx = 1, #PtsX do
                local dx = PtsX[idx] - targetX
                local dy = PtsY[idx] - targetY
                local d = dx * dx + dy * dy
                if not closest_d or d < closest_d then
                    closest_d = d
                    closest = idx
                end
            end
            im.DrawList_PathClear(WDL)
            for idx = 1, closest do
                im.DrawList_PathLineTo(WDL, PtsX[idx], PtsY[idx])
            end
            im.DrawList_PathStroke(WDL, clr, nil, thick)
        end

        -- Draw ADSR envelope shape
        local base_clr = EightColors.LFO[i] or 0xFFFFFFFF
        local bright_clr = HSV_Change(base_clr, 0, 0, 0.2, 0)
        Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 2, base_clr)
        im.DrawList_AddLine(WDL, x2, y2, x3, y3, base_clr, 2) -- Hold phase
        Draw_Curved_Segment(x3, x4, 1, S, Mc.ADSR_Curve_Decay, 2, base_clr)
        im.DrawList_AddLine(WDL, x4, y4, x5, y5, base_clr, 2)
        Draw_Curved_Segment(x5, x6, S, 0, Mc.ADSR_Curve_Release, 2, base_clr)

        local adsr_stage = r.gmem_read(140 + i) or 0
        local adsr_time = r.gmem_read(160 + i) or 0
        local adsr_level = (r.gmem_read(100 + i) or 0) / 127
        adsr_level = SetMinMax(adsr_level, 0, 1)
        if adsr_stage and adsr_stage > 0 then
            local play_x = nil
            local play_y = nil
            local fade_sec = 0.2
            local function Fade_Clr(alpha)
                local a = SetMinMax(alpha or 0, 0, 1)
                return Change_Clr_A(bright_clr, -(1 - a))
            end
            local now = r.time_precise()
            if Mc.ADSR_LastStage ~= adsr_stage then
                if Mc.ADSR_LastStage == 1 and adsr_stage == 2 then
                    Mc.ADSR_AttackEndTime = now
                elseif Mc.ADSR_LastStage == 3 and adsr_stage == 4 then
                    Mc.ADSR_DecayEndTime = now
                end
                Mc.ADSR_LastStage = adsr_stage
            end
            local attack_elapsed = Mc.ADSR_AttackEndTime and (now - Mc.ADSR_AttackEndTime) or 0
            local decay_elapsed = Mc.ADSR_DecayEndTime and (now - Mc.ADSR_DecayEndTime) or 0
            local attack_alpha = (adsr_stage > 1) and SetMinMax(1 - (attack_elapsed / math.max(fade_sec, 0.001)), 0, 1) or 1
            local decay_alpha = (adsr_stage > 3) and SetMinMax(1 - (decay_elapsed / math.max(fade_sec, 0.001)), 0, 1) or 1
            local attack_clr = (adsr_stage > 1) and Fade_Clr(attack_alpha) or bright_clr
            local decay_clr = (adsr_stage > 3) and Fade_Clr(decay_alpha) or bright_clr
            if adsr_stage == 1 then
                play_x = x1 + SetMinMax(adsr_time, 0, A) * scaleX
                play_y = Val_To_Y(adsr_level)
                --[[ local dot_clr = HSV_Change(base_clr, 0, 0, 0.35, 0)
                GLOWING_CIRCLE({play_x, play_y}, 0, 8, 0, base_clr, WDL)
                im.DrawList_AddCircleFilled(WDL, play_x, play_y, 2.5, dot_clr) ]]
                Draw_Single_Curve_Partial(x1, x2, y1, y2, Mc.ADSR_Curve_Attack, 3, bright_clr, play_x, play_y)
            elseif adsr_stage == 2 then
                play_x = x2 + SetMinMax(adsr_time, 0, H) * scaleX
                play_y = y2
                --[[ local dot_clr = HSV_Change(base_clr, 0, 0, 0.35, 0)
                GLOWING_CIRCLE({play_x, play_y}, 0, 8, 0, base_clr, WDL)
                im.DrawList_AddCircleFilled(WDL, play_x, play_y, 2.5, dot_clr) ]]
                Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                im.DrawList_AddLine(WDL, x2, y2, x2 + SetMinMax(adsr_time, 0, H) * scaleX, y2, bright_clr, 3)
            elseif adsr_stage == 3 then
                play_x = x3 + SetMinMax(adsr_time, 0, D) * scaleX
                Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                im.DrawList_AddLine(WDL, x2, y2, x3, y3, bright_clr, 3)
                play_y = Val_To_Y(adsr_level)
                --[[ local dot_clr = HSV_Change(base_clr, 0, 0, 0.35, 0)
                GLOWING_CIRCLE({play_x, play_y}, 0, 8, 0, base_clr, WDL)
                im.DrawList_AddCircleFilled(WDL, play_x, play_y, 2.5, dot_clr) ]]
                Draw_Single_Curve_Partial(x3, x4, y3, y4, Mc.ADSR_Curve_Decay, 3, bright_clr, play_x, play_y)
            elseif adsr_stage == 4 then
                play_x = x4 + (0.1 * scaleX)
                play_y = y4
                --[[ local dot_clr = HSV_Change(base_clr, 0, 0, 0.35, 0)
                GLOWING_CIRCLE({play_x, play_y}, 0, 8, 0, base_clr, WDL)
                im.DrawList_AddCircleFilled(WDL, play_x, play_y, 2.5, dot_clr) ]]
                if attack_alpha > 0 then
                    Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                    im.DrawList_AddLine(WDL, x2, y2, x3, y3, attack_clr, 3)
                end
                if decay_alpha > 0 then
                    Draw_Curved_Segment(x3, x4, 1, S, Mc.ADSR_Curve_Decay, 3, decay_clr)
                end
                im.DrawList_AddLine(WDL, x4, y4, x5, y5, bright_clr, 3)
            elseif adsr_stage == 5 then
                play_x = x5 + SetMinMax(adsr_time, 0, R) * scaleX
                if attack_alpha > 0 then
                    Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                    im.DrawList_AddLine(WDL, x2, y2, x3, y3, attack_clr, 3)
                end
                if decay_alpha > 0 then
                    Draw_Curved_Segment(x3, x4, 1, S, Mc.ADSR_Curve_Decay, 3, decay_clr)
                end
                -- sustain segment stays unlit
                play_y = Val_To_Y(adsr_level)
                --[[ local dot_clr = HSV_Change(base_clr, 0, 0, 0.35, 0)
                GLOWING_CIRCLE({play_x, play_y}, 0, 8, 0, base_clr, WDL)
                im.DrawList_AddCircleFilled(WDL, play_x, play_y, 2.5, dot_clr) ]]
                Draw_Single_Curve_Partial(x5, x6, y5, y6, Mc.ADSR_Curve_Release, 3, bright_clr, play_x, play_y)
            end
        end
    end
    
    local function parameters(Open_ADSR_Mod)
        local function Change_Prop(mode, v, str, paramIdx)
            local str = IsContainer and 'Container '..FxGUID .. str or str
            Save_to_Trk(str, v)
            
            -- Update unified parameter slider (JSFX reads from sliders directly)
            if paramIdx ~= nil then
                local function FindMacrosFXIdx()
                    local cnt = r.TrackFX_GetCount(LT_Track)
                    for idx = 0, cnt-1, 1 do
                        local rv, name = r.TrackFX_GetFXName(LT_Track, idx, '')
                        if name and (name:find('FXD Macros') or name:find('FXD Container Macros')) then return idx end
                    end
                end
                local MacFxIdx = FindMacrosFXIdx()
                if MacFxIdx then
                    local base = 2 + (i - 1) * 4
                    local norm_value
                    if paramIdx == 0 then -- Attack: 0.001-2.0 seconds, logarithmic
                        norm_value = (math.log(v) - math.log(0.001)) / (math.log(2.0) - math.log(0.001))
                    elseif paramIdx == 1 then -- Decay: 0.001-2.0 seconds, logarithmic
                        norm_value = (math.log(v) - math.log(0.001)) / (math.log(2.0) - math.log(0.001))
                    elseif paramIdx == 2 then -- Sustain: 0.0-1.0, linear
                        norm_value = v
                    elseif paramIdx == 3 then -- Release: 0.001-2.0 seconds, logarithmic
                        norm_value = (math.log(v) - math.log(0.001)) / (math.log(2.0) - math.log(0.001))
                    end
                    if norm_value then
                        r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + paramIdx, norm_value)
                    end
                end
            end
            
            -- Notify JSFX of parameter change
            r.gmem_write(2, IsContainer and (FX[FxGUID] and FX[FxGUID].DIY_FxGUID) or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 29) -- mode 29 = ADSR parameter change
            r.gmem_write(5, i) -- which modulator
        end

        local function Send_ADSR_Hold()
            if IsContainer then
                r.gmem_attach('ContainerMacro')
            else
                r.gmem_attach('ParamValues')
            end
            r.gmem_write(2, IsContainer and (FX[FxGUID] and FX[FxGUID].DIY_FxGUID) or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 34) -- mode 34 = ADSR Hold parameter
            r.gmem_write(5, i) -- which modulator
            r.gmem_write(9, Mc.ADSR_Hold or 0.0) -- Hold value in seconds
        end

        local function Send_ADSR_Curve(curve_id, value)
            if IsContainer then
                r.gmem_attach('ContainerMacro')
            else
                r.gmem_attach('ParamValues')
            end
            r.gmem_write(2, IsContainer and (FX[FxGUID] and FX[FxGUID].DIY_FxGUID) or PM.DIY_TrkID[TrkID])
            r.gmem_write(4, 35) -- mode 35 = ADSR curve
            r.gmem_write(5, i) -- which modulator
            r.gmem_write(6, curve_id) -- 1=Attack, 2=Decay, 3=Release
            r.gmem_write(8, value or 0.0)
        end

        local function Save_ADSR_To_PExt()
            local base = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR ') or ('Mod '..i..' ADSR ')
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Attack', tostring(Mc.ADSR_Attack), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Hold', tostring(Mc.ADSR_Hold), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Decay', tostring(Mc.ADSR_Decay), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Sustain', tostring(Mc.ADSR_Sustain), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Release', tostring(Mc.ADSR_Release), true)
        end

        local function Save_ADSR_Curves_To_PExt()
            local base = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR ') or ('Mod '..i..' ADSR ')
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Curve Attack', tostring(Mc.ADSR_Curve_Attack or 0.0), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Curve Decay', tostring(Mc.ADSR_Curve_Decay or 0.0), true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..base..'Curve Release', tostring(Mc.ADSR_Curve_Release or 0.0), true)
        end

        local function Set_ADSR_Attack(v)
            local new_v = SetMinMax(v, 0.001, 2.0)
            if new_v ~= Mc.ADSR_Attack then
                Mc.ADSR_Attack = new_v
                Change_Prop(29.1, Mc.ADSR_Attack, ' ADSR Attack for mod'..i, 0)
                return true
            end
        end

        local function Set_ADSR_Hold(v)
            local new_v = SetMinMax(v, 0.0, 2.0)
            if new_v ~= Mc.ADSR_Hold then
                Mc.ADSR_Hold = new_v
                Send_ADSR_Hold()
                return true
            end
        end

        local function Set_ADSR_Decay(v)
            local new_v = SetMinMax(v, 0.001, 2.0)
            if new_v ~= Mc.ADSR_Decay then
                Mc.ADSR_Decay = new_v
                Change_Prop(29.2, Mc.ADSR_Decay, ' ADSR Decay for mod'..i, 1)
                return true
            end
        end

        local function Set_ADSR_Sustain(v)
            local new_v = SetMinMax(v, 0.0, 1.0)
            if new_v ~= Mc.ADSR_Sustain then
                Mc.ADSR_Sustain = new_v
                Change_Prop(29.3, Mc.ADSR_Sustain, ' ADSR Sustain for mod'..i, 2)
                return true
            end
        end

        local function Set_ADSR_Release(v)
            local new_v = SetMinMax(v, 0.001, 2.0)
            if new_v ~= Mc.ADSR_Release then
                Mc.ADSR_Release = new_v
                Change_Prop(29.4, Mc.ADSR_Release, ' ADSR Release for mod'..i, 3)
                return true
            end
        end
        
        im.SetNextWindowPos(ctx, L, T - 150)
        if im.BeginPopup(ctx, "ADSRModulatorPopup"..i, im.WindowFlags_NoDecoration | im.WindowFlags_AlwaysAutoResize) then
            im.Text(ctx, "ADSR Envelope")
            im.Separator(ctx)

            local function ADSR_Graph()
                local graph_w, graph_h = 220, 110
                im.InvisibleButton(ctx, '##ADSRGraph'..i, graph_w, graph_h)
                local gL, gT = im.GetItemRectMin(ctx)
                local gR, gB = im.GetItemRectMax(ctx)
                local gW, gH = im.GetItemRectSize(ctx)
                local dl = im.GetWindowDrawList(ctx)
                local pad = 4
                im.DrawList_AddRect(dl, gL, gT, gR, gB, 0xFFFFFF22)

                local A = SetMinMax(Mc.ADSR_Attack or 0.01, 0.001, 2.0)
                local H = SetMinMax(Mc.ADSR_Hold or 0.0, 0.0, 2.0)
                local D = SetMinMax(Mc.ADSR_Decay or 0.1, 0.001, 2.0)
                local S = SetMinMax(Mc.ADSR_Sustain or 0.7, 0.0, 1.0)
                local R = SetMinMax(Mc.ADSR_Release or 0.1, 0.001, 2.0)
                local sustain_display = 0.1

                local totalTime = A + H + D + sustain_display + R
                if totalTime <= 0 then totalTime = 1 end
                local scaleX = (gW - pad * 2) / totalTime

                local x1 = gL + pad
                local y1 = gB - pad
                local x2 = x1 + (A * scaleX)
                local y2 = gT + pad
                local x3 = x2 + (H * scaleX)
                local y3 = y2
                local x4 = x3 + (D * scaleX)
                local y4 = gT + pad + ((1 - S) * (gH - pad * 2))
                local x5 = x4 + (sustain_display * scaleX)
                local y5 = y4
                local x6 = x5 + (R * scaleX)
                local y6 = y1

                local line_clr = EightColors.LFO[i] or 0xFFFFFFFF
                local function Val_To_Y(v)
                    return gT + pad + ((1 - v) * (gH - pad * 2))
                end

                local function Draw_Curved_Segment(xa, xb, v1, v2, curve, thick, clr)
                    local ya = Val_To_Y(v1)
                    local yb = Val_To_Y(v2)
                    local thick = thick or 2
                    local clr = clr or line_clr
                    if not curve or math.abs(curve) < 0.01 then
                        im.DrawList_AddLine(dl, xa, ya, xb, yb, clr, thick)
                        return
                    end
                    Draw_Single_Curve(xb, xa, yb, ya, curve, thick, clr, 0)
                end

                local function Draw_Single_Curve_Partial(xa, xb, ya, yb, curve, thick, clr, targetX, targetY)
                    if not targetX or not targetY then return end
                    local inc = 0.5
                    local vmin = math.min(ya, yb)
                    local vmax = math.max(ya, yb)
                    local PtsX = {}
                    local PtsY = {}
                    for x = xa, xb, inc do
                        local I = (x - xa) / (xb - xa)
                        local y = ya + (yb - ya) * I
                        y = GetCurveValue(y, curve or 0, vmin, vmax, vmin, vmax)
                        PtsX[#PtsX + 1] = x
                        PtsY[#PtsY + 1] = y
                    end
                    local closest = 1
                    local closest_d = nil
                    for idx = 1, #PtsX do
                        local dx = PtsX[idx] - targetX
                        local dy = PtsY[idx] - targetY
                        local d = dx * dx + dy * dy
                        if not closest_d or d < closest_d then
                            closest_d = d
                            closest = idx
                        end
                    end
                    im.DrawList_PathClear(dl)
                    for idx = 1, closest do
                        im.DrawList_PathLineTo(dl, PtsX[idx], PtsY[idx])
                    end
                    im.DrawList_PathStroke(dl, clr, nil, thick)
                end

                local function Draw_Handle(x, y, active)
                    local sz = 4
                    local clr = active and line_clr or 0xFFFFFFFF
                    im.DrawList_AddCircleFilled(dl, x, y, sz, clr)
                end

                local function Is_Near(x, y, r)
                    local mx, my = im.GetMousePos(ctx)
                    local dx, dy = mx - x, my - y
                    return (dx * dx + dy * dy) <= (r * r)
                end

                local handle_hit = nil
                local hit_r = 7
                if Is_Near(x2, y2, hit_r) then
                    handle_hit = 'A'
                elseif Is_Near(x3, y3, hit_r) then
                    handle_hit = 'H'
                elseif Is_Near(x4, y4, hit_r) then
                    handle_hit = 'D'
                elseif Is_Near(x6, y6, hit_r) then
                    handle_hit = 'R'
                end

                local function Dist_Point_Segment(px, py, ax, ay, bx, by)
                    local vx, vy = bx - ax, by - ay
                    local wx, wy = px - ax, py - ay
                    local c1 = wx * vx + wy * vy
                    if c1 <= 0 then
                        return math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay))
                    end
                    local c2 = vx * vx + vy * vy
                    if c2 <= c1 then
                        return math.sqrt((px - bx) * (px - bx) + (py - by) * (py - by))
                    end
                    local b = c1 / c2
                    local px2 = ax + b * vx
                    local py2 = ay + b * vy
                    return math.sqrt((px - px2) * (px - px2) + (py - py2) * (py - py2))
                end

                local curve_hit = nil
                if im.IsItemHovered(ctx) and not handle_hit and not Mc.ADSR_Graph_Dragging then
                    local mx, my = im.GetMousePos(ctx)
                    local dA = Dist_Point_Segment(mx, my, x1, y1, x2, y2)
                    local dD = Dist_Point_Segment(mx, my, x3, y3, x4, y4)
                    local dR = Dist_Point_Segment(mx, my, x5, y5, x6, y6)
                    local min_d = math.min(dA, dD, dR)
                    if min_d <= 10 then
                        curve_hit = (min_d == dA and 'A') or (min_d == dD and 'D') or 'R'
                    end
                end

                local bright_clr = HSV_Change(line_clr, 0, 0, 0.2, 0)
                Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, curve_hit == 'A' and 4 or 2)
                im.DrawList_AddLine(dl, x2, y2, x3, y3, line_clr, curve_hit == 'A' and 3 or 2)
                Draw_Curved_Segment(x3, x4, 1, S, Mc.ADSR_Curve_Decay, curve_hit == 'D' and 4 or 2)
                im.DrawList_AddLine(dl, x4, y4, x5, y5, line_clr, curve_hit == 'D' and 3 or 2)
                Draw_Curved_Segment(x5, x6, S, 0, Mc.ADSR_Curve_Release, curve_hit == 'R' and 4 or 2)

                local adsr_stage = r.gmem_read(140 + i) or 0
                local adsr_time = r.gmem_read(160 + i) or 0
                local adsr_level = (r.gmem_read(100 + i) or 0) / 127
                adsr_level = SetMinMax(adsr_level, 0, 1)
                if adsr_stage and adsr_stage > 0 then
                    local play_x = nil
                    local play_y = nil
                    local fade_sec = 0.2
                    local function Fade_Clr(alpha)
                        local a = SetMinMax(alpha or 0, 0, 1)
                        return Change_Clr_A(bright_clr, -(1 - a))
                    end
                    local now = r.time_precise()
                    if Mc.ADSR_LastStage ~= adsr_stage then
                        if Mc.ADSR_LastStage == 1 and adsr_stage == 2 then
                            Mc.ADSR_AttackEndTime = now
                        elseif Mc.ADSR_LastStage == 3 and adsr_stage == 4 then
                            Mc.ADSR_DecayEndTime = now
                        end
                        Mc.ADSR_LastStage = adsr_stage
                    end
                    local attack_elapsed = Mc.ADSR_AttackEndTime and (now - Mc.ADSR_AttackEndTime) or 0
                    local decay_elapsed = Mc.ADSR_DecayEndTime and (now - Mc.ADSR_DecayEndTime) or 0
                    local attack_alpha = (adsr_stage > 1) and SetMinMax(1 - (attack_elapsed / math.max(fade_sec, 0.001)), 0, 1) or 1
                    local decay_alpha = (adsr_stage > 3) and SetMinMax(1 - (decay_elapsed / math.max(fade_sec, 0.001)), 0, 1) or 1
                    local attack_clr = (adsr_stage > 1) and Fade_Clr(attack_alpha) or bright_clr
                    local decay_clr = (adsr_stage > 3) and Fade_Clr(decay_alpha) or bright_clr
                    if adsr_stage == 1 then
                        play_x = x1 + SetMinMax(adsr_time, 0, A) * scaleX
                        play_y = Val_To_Y(adsr_level)
                        --[[ local dot_clr = HSV_Change(line_clr, 0, 0, 0.35, 0)
                        GLOWING_CIRCLE({play_x, play_y}, 0, 10, 0, line_clr, dl)
                        im.DrawList_AddCircleFilled(dl, play_x, play_y, 3.5, dot_clr) ]]
                        Draw_Single_Curve_Partial(x1, x2, y1, y2, Mc.ADSR_Curve_Attack, 3, bright_clr, play_x, play_y)
                    elseif adsr_stage == 2 then
                        play_x = x2 + SetMinMax(adsr_time, 0, H) * scaleX
                        play_y = y2
                        --[[ local dot_clr = HSV_Change(line_clr, 0, 0, 0.35, 0)
                        GLOWING_CIRCLE({play_x, play_y}, 0, 10, 0, line_clr, dl)
                        im.DrawList_AddCircleFilled(dl, play_x, play_y, 3.5, dot_clr) ]]
                        Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                        im.DrawList_AddLine(dl, x2, y2, x2 + SetMinMax(adsr_time, 0, H) * scaleX, y2, bright_clr, 3)
                    elseif adsr_stage == 3 then
                        play_x = x3 + SetMinMax(adsr_time, 0, D) * scaleX
                        Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                        im.DrawList_AddLine(dl, x2, y2, x3, y3, bright_clr, 3)
                        play_y = Val_To_Y(adsr_level)
                        --[[ local dot_clr = HSV_Change(line_clr, 0, 0, 0.35, 0)
                        GLOWING_CIRCLE({play_x, play_y}, 0, 10, 0, line_clr, dl)
                        im.DrawList_AddCircleFilled(dl, play_x, play_y, 3.5, dot_clr) ]]
                        Draw_Single_Curve_Partial(x3, x4, y3, y4, Mc.ADSR_Curve_Decay, 3, bright_clr, play_x, play_y)
                    elseif adsr_stage == 4 then
                        play_x = x4 + (sustain_display * scaleX)
                        play_y = y4
                        --[[ local dot_clr = HSV_Change(line_clr, 0, 0, 0.35, 0)
                        GLOWING_CIRCLE({play_x, play_y}, 0, 10, 0, line_clr, dl)
                        im.DrawList_AddCircleFilled(dl, play_x, play_y, 3.5, dot_clr) ]]
                        if attack_alpha > 0 then
                            Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                            im.DrawList_AddLine(dl, x2, y2, x3, y3, attack_clr, 3)
                        end
                        if decay_alpha > 0 then
                            Draw_Curved_Segment(x3, x4, 1, S, Mc.ADSR_Curve_Decay, 3, decay_clr)
                        end
                        im.DrawList_AddLine(dl, x4, y4, x5, y5, bright_clr, 3)
                    elseif adsr_stage == 5 then
                        play_x = x5 + SetMinMax(adsr_time, 0, R) * scaleX
                        if attack_alpha > 0 then
                            Draw_Curved_Segment(x1, x2, 0, 1, Mc.ADSR_Curve_Attack, 3, attack_clr)
                            im.DrawList_AddLine(dl, x2, y2, x3, y3, attack_clr, 3)
                        end
                        if decay_alpha > 0 then
                            Draw_Curved_Segment(x3, x4, 1, S, Mc.ADSR_Curve_Decay, 3, decay_clr)
                        end
                        -- sustain segment stays unlit
                        play_y = Val_To_Y(adsr_level)
                        --[[ local dot_clr = HSV_Change(line_clr, 0, 0, 0.35, 0)
                        GLOWING_CIRCLE({play_x, play_y}, 0, 10, 0, line_clr, dl)
                        im.DrawList_AddCircleFilled(dl, play_x, play_y, 3.5, dot_clr) ]]
                        Draw_Single_Curve_Partial(x5, x6, y5, y6, Mc.ADSR_Curve_Release, 3, bright_clr, play_x, play_y)
                    end
                end

                Draw_Handle(x2, y2, Mc.ADSR_DragPoint == 'A')
                Draw_Handle(x3, y3, Mc.ADSR_DragPoint == 'H')
                Draw_Handle(x4, y4, Mc.ADSR_DragPoint == 'D')
                Draw_Handle(x6, y6, Mc.ADSR_DragPoint == 'R')

                if im.IsMouseClicked(ctx, 0) and handle_hit then
                    Mc.ADSR_DragPoint = handle_hit
                    Mc.ADSR_Graph_Dragging = true
                elseif im.IsMouseClicked(ctx, 0) and curve_hit then
                    Mc.ADSR_Curve_Drag = curve_hit
                end

                if Mc.ADSR_Graph_Dragging and Mc.ADSR_DragPoint and im.IsMouseDown(ctx, 0) then
                    local mx, my = im.GetMousePos(ctx)
                    local changed = false
                    if Mc.ADSR_DragPoint == 'A' then
                        local newA = (mx - x1) / scaleX
                        changed = Set_ADSR_Attack(newA) or changed
                    elseif Mc.ADSR_DragPoint == 'H' then
                        local newH = (mx - x2) / scaleX
                        changed = Set_ADSR_Hold(newH) or changed
                    elseif Mc.ADSR_DragPoint == 'D' then
                        local newD = (mx - x3) / scaleX
                        local clampedY = SetMinMax(my, gT + pad, gB - pad)
                        local newS = 1 - ((clampedY - (gT + pad)) / (gH - pad * 2))
                        changed = Set_ADSR_Decay(newD) or changed
                        changed = Set_ADSR_Sustain(newS) or changed
                    elseif Mc.ADSR_DragPoint == 'R' then
                        local newR = (mx - x5) / scaleX
                        changed = Set_ADSR_Release(newR) or changed
                    end
                    if changed then
                        Mc.ADSR_Graph_Dirty = true
                    end
                end

                if Mc.ADSR_Curve_Drag and im.IsMouseDown(ctx, 0) and not Mc.ADSR_Graph_Dragging then
                    local _, dy = im.GetMouseDragDelta(ctx)
                    if dy > 1 or dy < -1 then
                        local delta = (-dy / 80)
                        if Mc.ADSR_Curve_Drag == 'A' then
                            Mc.ADSR_Curve_Attack = SetMinMax((Mc.ADSR_Curve_Attack or 0) + delta, -4, 4)
                            if Mc.ADSR_Curve_Attack < 1 and Mc.ADSR_Curve_Attack > -1 then
                                Mc.ADSR_Curve_Attack = delta > 0 and 1 or -1
                            end
                            Send_ADSR_Curve(1, Mc.ADSR_Curve_Attack)
                        elseif Mc.ADSR_Curve_Drag == 'D' then
                            Mc.ADSR_Curve_Decay = SetMinMax((Mc.ADSR_Curve_Decay or 0) + delta, -4, 4)
                            if Mc.ADSR_Curve_Decay < 1 and Mc.ADSR_Curve_Decay > -1 then
                                Mc.ADSR_Curve_Decay = delta > 0 and 1 or -1
                            end
                            Send_ADSR_Curve(2, Mc.ADSR_Curve_Decay)
                        elseif Mc.ADSR_Curve_Drag == 'R' then
                            Mc.ADSR_Curve_Release = SetMinMax((Mc.ADSR_Curve_Release or 0) + delta, -4, 4)
                            if Mc.ADSR_Curve_Release < 1 and Mc.ADSR_Curve_Release > -1 then
                                Mc.ADSR_Curve_Release = delta > 0 and 1 or -1
                            end
                            Send_ADSR_Curve(3, Mc.ADSR_Curve_Release)
                        end
                        Mc.ADSR_Curve_Dirty = true
                        im.ResetMouseDragDelta(ctx)
                    end
                end

                if Mc.ADSR_Graph_Dragging and im.IsMouseReleased(ctx, 0) then
                    if Mc.ADSR_Graph_Dirty then
                        Save_ADSR_To_PExt()
                    end
                    Mc.ADSR_Graph_Dragging = nil
                    Mc.ADSR_Graph_Dirty = nil
                    Mc.ADSR_DragPoint = nil
                end

                if Mc.ADSR_Curve_Drag and im.IsMouseReleased(ctx, 0) then
                    if Mc.ADSR_Curve_Dirty then
                        Save_ADSR_Curves_To_PExt()
                    end
                    Mc.ADSR_Curve_Drag = nil
                    Mc.ADSR_Curve_Dirty = nil
                end
            end

            ADSR_Graph()
            im.Spacing(ctx)
            
            -- Attack
            local was_active_attack = im.IsItemActive(ctx)
            local rv, Attack = Drag_With_Bar(ctx, 'Attack', Mc.ADSR_Attack or 0.01, 0.001, 0.001, 2.0, '%.3f s', flags, 0xffffff33)
            if rv then
                Mc.ADSR_Attack = SetMinMax(Attack, 0.001, 2.0)
                Change_Prop(29.1, Mc.ADSR_Attack, ' ADSR Attack for mod'..i, 0)
            end
            if was_active_attack and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR Attack') or ('Mod '..i..' ADSR Attack')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.ADSR_Attack), true)
            end
            
            -- Hold
            local was_active_hold = im.IsItemActive(ctx)
            local rv, Hold = Drag_With_Bar(ctx, 'Hold', Mc.ADSR_Hold or 0.0, 0.001, 0.0, 2.0, '%.3f s', flags, 0xffffff33)
            if rv then
                Mc.ADSR_Hold = SetMinMax(Hold, 0.0, 2.0)
                Send_ADSR_Hold()
            end
            if was_active_hold and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR Hold') or ('Mod '..i..' ADSR Hold')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.ADSR_Hold), true)
            end
            
            -- Decay
            local was_active_decay = im.IsItemActive(ctx)
            local rv, Decay = Drag_With_Bar(ctx, 'Decay', Mc.ADSR_Decay or 0.1, 0.001, 0.001, 2.0, '%.3f s', flags, 0xffffff33)
            if rv then
                Mc.ADSR_Decay = SetMinMax(Decay, 0.001, 2.0)
                Change_Prop(29.2, Mc.ADSR_Decay, ' ADSR Decay for mod'..i, 1)
            end
            if was_active_decay and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR Decay') or ('Mod '..i..' ADSR Decay')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.ADSR_Decay), true)
            end
            
            -- Sustain
            local was_active_sustain = im.IsItemActive(ctx)
            local rv, Sustain = Drag_With_Bar(ctx, 'Sustain', Mc.ADSR_Sustain or 0.7, 0.01, 0.0, 1.0, '%.2f', flags, 0xffffff33)
            if rv then
                Mc.ADSR_Sustain = SetMinMax(Sustain, 0.0, 1.0)
                Change_Prop(29.3, Mc.ADSR_Sustain, ' ADSR Sustain for mod'..i, 2)
            end
            if was_active_sustain and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR Sustain') or ('Mod '..i..' ADSR Sustain')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.ADSR_Sustain), true)
            end
            
            -- Release
            local was_active_release = im.IsItemActive(ctx)
            local rv, Release = Drag_With_Bar(ctx, 'Release', Mc.ADSR_Release or 0.1, 0.001, 0.001, 2.0, '%.3f s', flags, 0xffffff33)
            if rv then
                Mc.ADSR_Release = SetMinMax(Release, 0.001, 2.0)
                Change_Prop(29.4, Mc.ADSR_Release, ' ADSR Release for mod'..i, 3)
            end
            if was_active_release and im.IsItemDeactivatedAfterEdit(ctx) then
                local str = IsContainer and ('Container '..FxGUID..' Mod '..i..' ADSR Release') or ('Mod '..i..' ADSR Release')
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..str, tostring(Mc.ADSR_Release), true)
            end
            
            im.EndPopup(ctx)
        end
    end
    
    local BG_txt_Indent = nil -- nil to center horizontally
    local BG_txt_Sz = IsContainer and 12 or 20
    local BG_txt_Ofs_Y = IsContainer and Height/4 or nil
    local BG_txt = 'ADSR'
    im.InvisibleButton(ctx, "ADSRModulatorBox"..i, boxWidth, boxHeight)
    Add_BG_Text_For_Modulator(BG_txt, BG_txt_Indent, BG_txt_Sz, BG_txt_Ofs_Y)
    Draw_ADSR_Shape()
    
    if im.IsItemClicked(ctx, 0) then
        im.OpenPopup(ctx, 'ADSRModulatorPopup'..i)
    end
    parameters(Open_ADSR_Mod)
    
    -- Draw a visible outline for the invisible button
    local drawList = im.GetWindowDrawList(ctx)
    im.DrawList_AddRect(drawList, L, T, L + boxWidth, T + boxHeight, 0xFFFFFF22)
    if im.IsItemClicked(ctx, 1) then Mc.TweakingKnob = 2 end
end


function Create_Header_For_Track_Modulators__Squared_Modulators()
    local SavedCt = (Trk[TrkID] and Trk[TrkID].ModulatorCount) or (GetTrkSavedInfo and GetTrkSavedInfo('Modulator Count')) or 8
    SavedCt = tonumber(SavedCt) or 8
    local MaxCt = math.min(math.max(SavedCt, 8), 24)
    MacroNums = {}
    for n = 1, MaxCt, 1 do MacroNums[#MacroNums+1] = n end
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
            HelperMsg.Alt_R = 'Set to Bipolar'
            HelperMsg.Need_separator = true

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
        if im.IsItemClicked(ctx) then 
            Save_to_Trk('Velo_Mod_Affect_Velocity', Trk[TrkID].Velo_Mod_Affect_Velocity)
            r.TrackFX_SetParamNormalized(LT_Track, 0, 41, Trk[TrkID].Velo_Mod_Affect_Velocity and 0 or 1)
        end 
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
            im.Dummy(ctx, 1,1)
            im.EndPopup(ctx)
            
        end
    end
    local function Add_More_Modulators_Button()
        local clr = 0xffffff55
        local sz = 30
        local X, Y =  im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, X , Y + 1 )

        if Trk[TrkID].ShowExtraMidiMods  then 
            for lbl, enabled in pairs(Trk[TrkID].ShowExtraMidiMods) do
                if enabled then
                    SL()
                    Show_Midi_Modulations(lbl)
                end
            end
        end

        --[[ if im.InvisibleButton(ctx, 'add more modulator', LineHeight, LineHeight) then 

        end
        local L , T = im.GetItemRectMin(ctx)
        local W , H = im.GetItemRectSize(ctx)
        im.DrawList_AddTextEx(im.GetWindowDrawList(ctx) ,Arial_20 , 20 ,  L+W /3 , T+H/4 ,0xffffff55, '+' ) ]]

        im.PushFont(ctx, Arial_14)
        im.PushStyleColor(ctx, im.Col_Button, 0x00000000)
        if im.Button(ctx, ' +'..'##Add modulator btn', sz, sz) then 
            im.OpenPopup(ctx, 'AddMoreModulatorsPopup')

        end
        im.PopStyleColor(ctx)
        im.PopFont(ctx) 
        local clr = im.IsItemHovered(ctx) and 0xffffff99 or  0xffffff55
        Trk[TrkID].ShowExtraMidiMods = Trk[TrkID].ShowExtraMidiMods or {}
        HighlightSelectedItem(nil, clr, nil,nil,nil,nil,nil,nil,nil)

        if im.BeginPopup(ctx, 'AddMoreModulatorsPopup', im.WindowFlags_AlwaysAutoResize) then
            local extraLabels = {'Random 2', 'Random 3', 'KeyTrack 2', 'KeyTrack 3'}
            for _, lbl in ipairs(extraLabels) do
                local selected = Trk[TrkID].ShowExtraMidiMods[lbl] == true
                if im.Selectable(ctx, lbl, selected) then
                    Trk[TrkID].ShowExtraMidiMods[lbl] = true

                end
            end
            im.Separator(ctx)
            local ModCt = (Trk[TrkID] and Trk[TrkID].ModulatorCount) or (GetTrkSavedInfo and GetTrkSavedInfo('Modulator Count')) or 8
            ModCt = tonumber(ModCt) or 8
            local canAdd = ModCt < 24
            if im.Selectable(ctx, '4 more modulators', false, canAdd and 0 or im.SelectableFlags_Disabled) then
                local newCt = math.min(ModCt + 4, 24)
                Trk[TrkID].ModulatorCount = newCt
                if Save_to_Trk then Save_to_Trk('Modulator Count', newCt) end
            end
            im.EndPopup(ctx)
        end

        




        
    end

    local ModCt = math.min((Trk[TrkID] and Trk[TrkID].ModulatorCount) or (GetTrkSavedInfo and GetTrkSavedInfo('Modulator Count')) or 8, 24)
    ModCt = math.max(ModCt, 8)
    for i= 1 , ModCt, 1 do 

        local I = i
        Trk[TrkID].Mod[I] = Trk[TrkID].Mod[I] or {}
        local mc = Trk[TrkID].Mod[I]
        mc.Num = mc.Num or i
        local FxGUID = TrkID
        mc.TweakingKnob = nil
        local _, savedType = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod'.. I .. 'Type', '', false)
        if savedType == '' then savedType = nil end
        mc.Type = mc.Type or savedType or 'Macro'
        local Macro = i
        --[[  if not mc.Type then 
            _, mc.Type = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID ..' Mod' .. I .. 'Type', '', false)

            if mc.Type == '' then mc.Type = 'Macro' end 
        end ]]

        local ItmSz = 98
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
           --[[  if not Trk[TrkID].SEQL then 
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length', Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, true)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator', Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom, true)
            end ]]
    
            Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
            Trk[TrkID].SEQ_Dnom    = Trk[TrkID].SEQ_Dnom or {}
            Trk[TrkID].SEQL[i] = Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
            Trk[TrkID].SEQ_Dnom[i] = Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom

    
            local HoverOnAnyStep
            local SmallSEQActive
            local HdrPosL, HdrPosT = im.GetCursorScreenPos(ctx)
            local len = Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
            local boxWidth = ItmSz or ((VP.w - 10) / 12)
            local stepWidth = boxWidth / len
            
            im.BeginGroup(ctx)
            for St = 1, len, 1 do -- create all steps
                local L, T = im.GetCursorScreenPos(ctx)
                local H = LineHeight
                --[[ if St == 1 and AssigningMacro == i then
                    local W = (VP.w - 10) / 12
                    BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink, L, T, L + W, T + H, H, W)
                    --HighlightSelectedItem(0xffffff77,0xffffff33, 0, L,T,L+W,T+H,H,W, 1, 1,GetItemRect, Foreground)
                end ]]
                --_, S[St]= im.DragDouble(ctx, '##SEQ '..St ,  S[St], 0 ,0, 1, ' ',im.SliderFlags_NoInput)
                im.InvisibleButton(ctx, '##SEQ' .. St .. TrkID, stepWidth, H)
                local L, T = im.GetItemRectMin(ctx); local R, B = im.GetItemRectMax(ctx); local w, h =
                    im.GetItemRectSize(ctx)
                local FillClr = 0x00000000
    
    
    
                SEQ_Popup_L = SEQ_Popup_L or L
                SEQ_Popup_T = SEQ_Popup_T or T
    
                if im.IsItemHovered(ctx) and not im.IsMouseDown(ctx, 0) then
                    HoverOnAnyStep = true
                end
                if HoverOnAnyStep then WhichMacroIsHovered = i end
    
    
                -- no white outline/hover fill for step seq box
    
    
    
                S[St] = SetMinMax(S[St] or 0, 0, 1)
                if im.IsItemClicked(ctx) then
                    Mc.SEQ_Open = true
                    Mc.SEQ_Open_JustOpened = true
                    WhichMacroIsHovered = i
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
                -- no white playhead rectangle
                SL(nil, 0)
            end
            im.EndGroup(ctx)
            Add_BG_Text_For_Modulator('Step', nil, 22)
    
    
            im.SetNextWindowPos(ctx, HdrPosL, VP.Y - StepSEQ_H - 100)
            if Mc.AdjustingSteps and not im.IsMouseDown(ctx, 0) then Mc.AdjustingSteps = nil end
    
            function open_SEQ_Win(Track, i)
                
                if not HoveringSmoothness then
                    if im.Begin(ctx, 'SEQ Window' .. i, true, im.WindowFlags_NoResize + im.WindowFlags_NoDocking + im.WindowFlags_NoCollapse + im.WindowFlags_NoTitleBar + im.WindowFlags_AlwaysAutoResize) then
                        local WDL = im.GetWindowDrawList(ctx)
                        im.Text(ctx, 'Sequence Length : ')
                        -- Determine if this is a container by checking if container type is saved
                        local _, containerType = r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Mod'..i..'Type', '', false)
                        local IsContainerSEQ = (containerType and containerType ~= '') and true or false
                        
                        local function writeSEQDNom()
                            if AddMacroJSFX() then
                                r.gmem_write(4, 8) --[[tells JSFX user is tweaking seq length or DNom]]
                                r.gmem_write(5, i) --[[tells JSFX the macro]]
                                r.gmem_write(10, Trk[TrkID].SEQ_Dnom[i])
                                r.gmem_write(9, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)
                                -- Save with container format if container, otherwise regular format
                                local save_str = IsContainerSEQ and ('Container '..FxGUID..' Macro '..i..' SEQ Denominator') or ('Macro '..i..' SEQ Denominator')
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..save_str, Trk[TrkID].SEQ_Dnom[i], true)
                                
                                -- Also update unified parameter (Param2 = Denominator)
                                local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
                                if MacFxGUID then
                                    local function FindFxIdxByGUID(guid)
                                        local cnt = r.TrackFX_GetCount(LT_Track)
                                        for idx = 0, cnt-1, 1 do
                                            if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                                        end
                                    end
                                    local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                                    local base = 2 + (i - 1) * 4
                                    -- Denominator: values are [0.125, 0.25, 0.5, 1, 2, 4, 8] (7 values) → normalized index/6
                                    local denom_values = {0.125, 0.25, 0.5, 1, 2, 4, 8}
                                    local denom_norm = 0.5 -- default for value 1
                                    for idx, val in ipairs(denom_values) do
                                        if math.abs(Trk[TrkID].SEQ_Dnom[i] - val) < 0.001 then
                                            denom_norm = (idx - 1) / 6
                                            break
                                        end
                                    end
                                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + 1, denom_norm)
                                end
                            end
                        end
    
                        local function writeSEQGmem()
                            if AddMacroJSFX() then
                                r.gmem_write(4, 8)
                                r.gmem_write(5, i)
                                r.gmem_write(9, Trk[TrkID].SEQL[i])
                                r.gmem_write(10, Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom)
                                -- Save with container format if container, otherwise regular format
                                local save_str = IsContainerSEQ and ('Container '..FxGUID..' Macro '..i..' SEQ Length') or ('Macro '..i..' SEQ Length')
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: '..save_str, Trk[TrkID].SEQL[i], true)
                                
                                -- Also update unified parameter (Param1 = Length)
                                local MacFxGUID = r.TrackFX_GetFXGUID(LT_Track, 0)
                                if MacFxGUID then
                                    local function FindFxIdxByGUID(guid)
                                        local cnt = r.TrackFX_GetCount(LT_Track)
                                        for idx = 0, cnt-1, 1 do
                                            if r.TrackFX_GetFXGUID(LT_Track, idx) == guid then return idx end
                                        end
                                    end
                                    local MacFxIdx = FindFxIdxByGUID(MacFxGUID) or 0
                                    local base = 2 + (i - 1) * 4
                                    -- Length: 2-64 → normalized (length-2)/62
                                    local length_norm = (Trk[TrkID].SEQL[i] - 2) / 62
                                    r.TrackFX_SetParamNormalized(LT_Track, MacFxIdx, base + 0, length_norm)
                                end
                            end
                        end
    
    
    
                        Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
                        rv, Trk[TrkID].SEQL[i] = im.SliderInt(ctx, '##' .. 'Macro' .. i .. 'SEQ Length',
                            Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 2, 64)
                        if rv then
                            -- Save immediately when value changes
                            writeSEQGmem()
                        end
                        -- Also save on mouse release
                        if im.IsItemDeactivatedAfterEdit(ctx) then
                            writeSEQGmem()
                        end
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
                        local is_window_hovered = im.IsMouseHoveringRect(ctx, x, y, x + w, y + h)
    
                        if is_window_hovered then notHoverSEQ_Time = 0 end
                        if Mc.SEQ_Open_JustOpened then
                            Mc.SEQ_Open_JustOpened = nil
                        else
                            if im.IsMouseClicked(ctx, 0) and not is_window_hovered then
                                Mc.SEQ_Open = nil
                                WhichMacroIsHovered = nil
                                notHoverSEQ_Time = 0
                            end
                        end
                        if im.IsKeyPressed(ctx, im.Key_Escape) then
                            Mc.SEQ_Open = nil
                            WhichMacroIsHovered = nil
                            notHoverSEQ_Time = 0
                        end
    
                        im.End(ctx)
                    end
                end
            end
    
            if Mc.SEQ_Open or SmallSEQActive or Mc.AdjustingSteps then
                open_SEQ_Win(Track, Macro)
                notHoverSEQ_Time = 0
            end
    
            if Mc.SEQ_Open and not HoverOnAnyStep and not SmallSEQActive and not Mc.AdjustingSteps then
                notHoverSEQ_Time = math.min((notHoverSEQ_Time or 0), 11) + 1
                if notHoverSEQ_Time >= 10 then
                    Mc.SEQ_Open = nil
                    WhichMacroIsHovered = nil
                    notHoverSEQ_Time = 0
                end
            end
        end

        --[[ mc.Gain = tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Gain','', false)))
        mc.Smooth =tonumber(select(2, r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro ' .. I .. ' Follower Speed','',false))) ]]


        --im.SetCursorPos(ctx,45 + (Size*3 * (row-1)),  10+ (i-4*(row-1) ) * (Size*2+25))
        im.PushStyleVar(ctx, im.StyleVar_WindowPadding, 20, 10)
        MacroKnob(mc,i, LineHeight /1.85,'Track' )
        LFO_BOX_NEW(mc, i  , ItmSz )
        Follower_Box(mc,i , ItmSz/3, TrkID, 'ParamValues')
        Random_Modulator_Box(mc, i , ItmSz )
        AHDSR_Box(mc, i, ItmSz)
        XY_BOX(mc, i , ItmSz)
        If_Macro_Is_StepSEQ()
        WhenRightClickOnModulators(i) -- this has to be before step SEQ because the rightclick function is within step seq function
        Show_Help_Msg()
        --[[ LFO_Box(mc,i)
        Follower_Box(mc,i)
        StepSeq_Box(mc,i) ]]
        im.PopStyleVar(ctx)

        HighlightSelectedItem(nil, 0xffffff33 , 7 , nil,nil,nil,nil,nil,nil, 1,1,'GetItemRect', nil, 2,2)

        SL()
        im.SetNextWindowPos(ctx, im.GetCursorScreenPos(ctx))

        if im.BeginPopup(ctx, 'Mod' .. i .. 'Menu') then
            
            if mc.Type == 'Macro' then 
                if im.Selectable(ctx, 'Automate', false) then
                    AddMacroJSFX()
                    -- Show Envelope for Morph Slider
                    local env = r.GetFXEnvelope(LT_Track, 0, (i <= 8 and (i - 1) or (42 + (i - 9))), false)    -- Check if envelope is on
                    if env == nil then                                        -- Envelope is off
                        local env = r.GetFXEnvelope(LT_Track, 0, (i <= 8 and (i - 1) or (42 + (i - 9))), true) -- true = Create envelope
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
                    SetPrmAlias(LT_TrackNum, 1, (i <= 8 and i or (43 + (i - 9))), Mc.Name or ('Macro' .. i)) -- Change parameter name to alias
                    r.TrackList_AdjustWindows(false)
                    r.UpdateArrange()
                end
            end
            im.SeparatorText(ctx, 'Set Type to :')

            Set_Modulator_Type(mc, i, 'LFO')
            Set_Modulator_Type(mc, i, 'Follower')
            Set_Modulator_Type(mc, i, 'Envelope')
            Set_Modulator_Type(mc, i, 'ADSR')
            Set_Modulator_Type(mc, i, 'Step')
            Set_Modulator_Type(mc, i, 'Macro')
            Set_Modulator_Type(mc, i, 'Random')
            Set_Modulator_Type(mc, i, 'XY')
            im.EndPopup(ctx)
        end
    end

    SL()
    Show_Midi_Modulations('Velocity')
    Show_Midi_Modulations('Random')
    Show_Midi_Modulations('KeyTrack')
    SL()
    Add_More_Modulators_Button()

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


function Show_Modulator_Control_Panel(pos,FP, FxGUID)
    if not USE_MOD_CONTROL_POPUP then return end 
    if not FP.WhichCC then return end 
    if im.IsItemActive(ctx) then return end
    if (not im.IsItemHovered(ctx) and not (Mod_Control_Win_Hvr == FP.Num)    ) then return  end 
    if im.IsItemHovered(ctx)  then HOVERED_PRM_FxGUID = FxGUID end 
    if HOVERED_PRM_FxGUID ~= FxGUID then return end 
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
            im.Begin(ctx, 'Modulation Bar'..i.. 'Prm = '..FP.Num .. FxGUID, true,  im.WindowFlags_NoDecoration)
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
                local function Send_curve_gmem(norm)
                    r.gmem_write( 4 , 26) -- set mode = 4, which means user is adjusting mod curve
                    r.gmem_write( 5, i) -- tells which modulator
                    r.gmem_write( 6, FP.WhichCC) -- tells which track param
                    r.gmem_write( 8 , norm *2) -- curve is an offset of 200000
                end
                FP.Left_Dragging_Mod_Ctrl = nil 
                if rv==1  then  -- left drag to change curve of modulation
                    FP.Left_Dragging_Mod_Ctrl = true
                    local _, Dt = im.GetMouseDragDelta(ctx)
                    if Dt > 1 or Dt < -1 then 
                        FP.Mod_Curve[i] = SetMinMax ((FP.Mod_Curve[i] or 0) +  Dt/  (sz/2)    , -Curve_Scale, Curve_Scale )
                        if FP.Mod_Curve[i] > -0.5 and FP.Mod_Curve[i] < 0.5 then 
                            if Dt > 1 then FP.Mod_Curve[i] = 0.5 elseif Dt < 1 then FP.Mod_Curve[i] = -0.5 end
                        end
                        Save_to_Trk('Mod_Curve_for_Mod'..i..'Prm ='..FP.WhichCC ,  FP.Mod_Curve[i], LT_Track)
                        Send_curve_gmem(FP.Mod_Curve[i])
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

                if  im.IsMouseDoubleClicked(ctx, 0) and im.IsItemClicked(ctx, 0) then 
                    FP.Mod_Curve[i]  = 0
                    Send_curve_gmem(FP.Mod_Curve[i])
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