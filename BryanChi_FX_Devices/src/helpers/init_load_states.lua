local state_helpers = require('src.helpers.state_helpers')
local GF = require("src.Functions.General Functions")
---@param str string
---@param type? string
---@param Track MediaTrack
---@return number
local RC =function (str, type, Track)
    if type == 'str' then
        return select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false))
    else
        return tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false)))
    end
end

-- Repeat for every track, at the beginning of script
NumOfTotalTracks = r.CountTracks(0)
for Track_Idx = 0, NumOfTotalTracks - 1, 1 do
    local Track = r.GetTrack(0, Track_Idx)
    local TrkID = r.GetTrackGUID(Track)

    FxdCtx.Trk[TrkID] = FxdCtx.Trk[TrkID] or {}
    FxdCtx.Trk[TrkID].Mod = {}
    FxdCtx.Trk[TrkID].SEQL = FxdCtx.Trk[TrkID].SEQL or {}
    FxdCtx.Trk[TrkID].SEQ_Dnom = FxdCtx.Trk[TrkID].SEQ_Dnom or {}
    local AutoPrmCount = state_helpers.GetTrkSavedInfo('How Many Automated Prm in Modulators', Track)
    FxdCtx.Trk[TrkID].AutoPrms = FxdCtx.Trk[TrkID].AutoPrms or {}
    for i = 1, (AutoPrmCount or 0) + 1, 1 do
        FxdCtx.Trk[TrkID].AutoPrms[i] = state_helpers.GetTrkSavedInfo('Auto Mod' .. i, Track, 'str')
    end


    for i = 1, 8, 1 do -- for every modulator
        FxdCtx.Trk[TrkID].Mod[i] = {}
        local m = FxdCtx.Trk[TrkID].Mod[i]

        m.ATK = RC('Macro ' .. i .. ' Atk', nil, Track)
        m.REL = RC('Macro ' .. i .. ' Rel', nil, Track)
        FxdCtx.Trk[TrkID].SEQL[i] = RC('Macro ' .. i .. ' SEQ Length', nil, Track)
        FxdCtx.Trk[TrkID].SEQ_Dnom[i] = RC('Macro ' .. i .. ' SEQ Denominator', nil, Track)
        m.Smooth = RC('Macro ' .. i .. ' Follower Speed', nil, Track)
        m.Gain = RC('Macro ' .. i .. ' Follower Gain', nil, Track)

        m.LFO_NodeCt = RC('Mod ' .. i .. 'Total Number of Nodes', nil, Track)
        m.LFO_spd = RC('Mod ' .. i .. 'LFO Speed', nil, Track)
        m.LFO_leng = RC('Mod ' .. i .. 'LFO Length', nil, Track)
        m.LFO_Env_or_Loop = RC('Mod ' .. i .. 'LFO_Env_or_Loop', nil, Track)
        m.Rel_Type = RC('Mod ' .. i .. 'LFO_Release_Type', nil, Track)
        if m.Rel_Type == 0 then
            m.Rel_Type = 'Latch'
        elseif m.Rel_Type == 1 then
            m.Rel_Type = 'Simple Release'
        elseif m.Rel_Type == 2 then
            m.Rel_Type = 'Custom Release'
        elseif m.Rel_Type == 3 then
            m.Rel_Type = 'Custom Release - No Jump'
        end

        if m.LFO_Env_or_Loop == 1 then m.LFO_Env_or_Loop = 'Envelope' else m.LFO_Env_or_Loop = nil end



        for N = 1, (m.LFO_NodeCt or 0), 1 do
            m.Node = m.Node or {}
            m.Node[N] = m.Node[N] or {}
            m.Node[N].x = RC('Mod ' .. i .. 'Node ' .. N .. ' X', nil, Track)


            m.Node[N].y       = RC('Mod ' .. i .. 'Node ' .. N .. ' Y', nil, Track)
            m.Node[N].ctrlX   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl X', nil, Track)

            m.Node[N].ctrlY   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl Y', nil, Track)
            m.NodeNeedConvert = true
        end
        if RC('Mod ' .. i .. 'LFO_Rel_Node', nil, Track) then
            local ID = RC('Mod ' .. i .. 'LFO_Rel_Node', nil, Track)
            m.Node[ID] = m.Node[ID] or {}
            m.Node[ID].Rel = true
        end



        FxdCtx.Trk[TrkID].Mod[i].SEQ = FxdCtx.Trk[TrkID].Mod[i].SEQ or {}
        --Get Seq Steps
        if FxdCtx.Trk[TrkID].SEQL[i] then
            for St = 1, FxdCtx.Trk[TrkID].SEQL[i], 1 do
                FxdCtx.Trk[TrkID].Mod[i].SEQ[St] = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', '',
                        false)))
            end
        end
    end



    local FXCount = r.TrackFX_GetCount(Track)
    FxdCtx.Trk[TrkID] = FxdCtx.Trk[TrkID] or {}
    FxdCtx.Trk[TrkID].PreFX = FxdCtx.Trk[TrkID].PreFX or {}
    FxdCtx.Trk[TrkID].PostFX = FxdCtx.Trk[TrkID].PostFX or {}






    RetrieveFXsSavedLayout(FXCount)

    FxdCtx.Trk[TrkID].ModPrmInst = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ModPrmInst', '', false)))
    for CC = 1, FxdCtx.Trk[TrkID].ModPrmInst or 0, 1 do
        _, FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID] = r.GetSetMediaTrackInfo_String(Track,
            'P_EXT: CC Linked to which Modulation' .. CC, '', false)
    end

    _, FxdCtx.PM.DIY_TrkID[TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID)
    FxdCtx.PM.DIY_TrkID[TrkID] = tonumber(FxdCtx.PM.DIY_TrkID[TrkID])

    _, FxdCtx.Trk.Prm.Inst[TrkID] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Trk Prm Count', '', false)
    FxdCtx.Trk.Prm.Inst[TrkID] = tonumber(FxdCtx.Trk.Prm.Inst[TrkID])

    i = 1
    ---retrieve Pre-FX mappings?
    ---store in CurTrk.PreFX
    while i do
        local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. i, '', false)
        if rv then
            FxdCtx.Trk[TrkID].PreFX[i] = str; i = i + 1
        else
            i = nil
        end
    end

    i = 1
    ---retrieve Post-FX mappings?
    ---store in CurTrk.PostFX
    while i do
        local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PostFX ' .. i, '', false)
        if rv then
            FxdCtx.Trk[TrkID].PostFX[i] = str; i = i + 1
        else
            i = nil
        end
    end



    if FxdCtx.Trk[TrkID].PreFX == {} then FxdCtx.Trk[TrkID].PreFX = nil end
    for P = 1, FxdCtx.Trk.Prm.Inst[TrkID] or 0, 1 do
        _, FxdCtx.Trk.Prm.Num[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track' .. TrkID .. ' P =' .. P)
        _, FxdCtx.Trk.Prm.WhichMcros[P .. TrkID] = r.GetProjExtState(0, 'FX Devices',
            'Prm' .. P .. 'Has Which Macro Assigned, TrkID =' .. TrkID)
        if FxdCtx.Trk.Prm.WhichMcros[P .. TrkID] == '' then FxdCtx.Trk.Prm.WhichMcros[P .. TrkID] = nil end

        FxdCtx.Trk.Prm.Num[P .. TrkID] = tonumber(FxdCtx.Trk.Prm.Num[P .. TrkID])

        for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
            local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
            _, FxdCtx.Trk.Prm.FXGUID[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'P_Trk :' .. P .. 'Trk-' .. TrkID)
        end
    end




    for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
        local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
        local _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)




        local _, DefaultSldr_W = r.GetProjExtState(0, 'FX Devices', 'Default Slider Width for FX:' .. FxGUID)
        if DefaultSldr_W ~= '' then FxdCtx.FX.Def_Sldr_W[FxGUID] = DefaultSldr_W end
        local _, Def_Type = r.GetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID)
        if Def_Type ~= '' then FxdCtx.FX.Def_Type[FxGUID] = Def_Type end

        if FxGUID ~= nil then
            GF.GetProjExt_FxNameNum(FxGUID)

            _, FxdCtx.FX.InLyr[FxGUID]          = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' ..
                FxGUID .. 'in layer')
            --FX.InLyr[FxGUID] = StringToBool[FX.InLyr[FxGUID]]
            _, FxdCtx.FX.LyrNum[FxGUID]         = r.GetProjExtState(0, 'FX Devices', 'FXLayer ' .. FxGUID .. 'LayerNum')
            _, FxdCtx.FX[FxGUID].inWhichLyr     = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. FxGUID .. 'is in Layer ID')
            _, FxdCtx.FX[FxGUID].ContainerTitle = r.GetProjExtState(0, 'FX Devices - ',
                'FX' .. FxGUID .. 'FX Layer Container Title ')
            if FxdCtx.FX[FxGUID].ContainerTitle == '' then FxdCtx.FX[FxGUID].ContainerTitle = nil end

            FxdCtx.FX[FxGUID].inWhichLyr = tonumber(FxdCtx.FX[FxGUID].inWhichLyr)
            FxdCtx.FX.LyrNum[FxGUID] = tonumber(FxdCtx.FX.LyrNum[FxGUID])
            _, FxdCtx.Lyr.SplitrAttachTo[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. FxGUID)
            _, FxdCtx.Prm.InstAdded[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added')
            if FxdCtx.Prm.InstAdded[FxGUID] == 'true' then FxdCtx.Prm.InstAdded[FxGUID] = true end

            if FxdCtx.FX.InLyr[FxGUID] == "" then FxdCtx.FX.InLyr[FxGUID] = nil end
            FxdCtx.FX[FxGUID].Morph_ID = tonumber(select(2,
                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID, '', false)))
            _, FxdCtx.FX[FxGUID].Unlink = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '',
                false)
            if FxdCtx.FX[FxGUID].Unlink == 'Unlink' then FxdCtx.FX[FxGUID].Unlink = true elseif FxdCtx.FX[FxGUID].Unlink == '' then FxdCtx.FX[FxGUID].Unlink = nil end

            if FxdCtx.FX[FxGUID].Morph_ID then
                FxdCtx.Trk[TrkID].Morph_ID = FxdCtx.Trk[TrkID].Morph_ID or {}
                FxdCtx.Trk[TrkID].Morph_ID[FxdCtx.FX[FxGUID].Morph_ID] = FxGUID
            end

            local rv, ProC_ID = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ProC_ID ' .. FxGUID, '', false)
            if rv then FxdCtx.FX[FxGUID].ProC_ID = tonumber(ProC_ID) end

            if FxdCtx.FX[FxGUID].Unlink == 'Unlink' then FxdCtx.FX[FxGUID].Unlink = true elseif FxdCtx.FX[FxGUID].Unlink == '' then FxdCtx.FX[FxGUID].Unlink = nil end

            for Fx_P = 1, #FxdCtx.FX[FxGUID] or 0, 1 do
                FxdCtx.FX[FxGUID][Fx_P].V = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                        Fx_P .. 'Value before modulation', '', false)))


                local ParamX_Value = 'Param' ..
                    tostring(FxdCtx.FX[FxGUID][Fx_P].Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID
                ParamValue_At_Script_Start = r.TrackFX_GetParamNormalized(Track, FX_Idx, FxdCtx.FX[FxGUID][Fx_P].Num or 0)
                _G[ParamX_Value] = ParamValue_At_Script_Start
                _, FxdCtx.FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = r.GetProjExtState(0, 'FX Devices',
                    'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'to Trk Prm')
                FxdCtx.FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = tonumber(FxdCtx.FX.Prm.ToTrkPrm[FxGUID .. Fx_P])

                local F_Tp = FxdCtx.FX.Prm.ToTrkPrm[FxGUID .. Fx_P]

                _G[ParamX_Value] = FxdCtx.FX[FxGUID][Fx_P].V or 0
                FxdCtx.FX[FxGUID][Fx_P].WhichCC = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' ..
                        (FxdCtx.FX[FxGUID][Fx_P].Num or 0), '', false)))
                _, FxdCtx.FX[FxGUID][Fx_P].WhichMODs = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods', '', false)
                if FxdCtx.FX[FxGUID][Fx_P].WhichMODs == '' then FxdCtx.FX[FxGUID][Fx_P].WhichMODs = nil end
                FxdCtx.FX[FxGUID][Fx_P].ModAMT = {}


                local CC = FxdCtx.FX[FxGUID][Fx_P].WhichCC
                local HasModAmt
                for m, v in ipairs(FxdCtx.MacroNums) do
                    local FP = FxdCtx.FX[FxGUID][Fx_P]
                    FxdCtx.FX[FxGUID][Fx_P].ModAMT[m] = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                            Fx_P .. 'Macro' .. m .. 'Mod Amt', '', false)))
                    if FxdCtx.FX[FxGUID][Fx_P].ModAMT[m] then HasModAmt = true end



                    FxdCtx.Trk[TrkID].Mod = FxdCtx.Trk[TrkID].Mod or {}
                    FxdCtx.Trk[TrkID].Mod[m] = FxdCtx.Trk[TrkID].Mod[m] or {}
                    FxdCtx.Trk[TrkID].Mod[m].Val = tonumber(select(2,
                        r.GetProjExtState(0, 'FX Devices', 'Macro' .. m .. 'Value of Track' .. TrkID)))

                    FP.ModBypass = GF.RemoveEmptyStr(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', '',
                            false)))

                    FP.ModBipolar = FP.ModBipolar or {}
                    FP.ModBipolar[m] = FxdCtx.StringToBool
                        [select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. m .. 'Mod Bipolar', '', false))]

                    if FxdCtx.Prm.McroModAmt[IdM] ~= nil then
                        local width = FxdCtx.FX[FxGUID].Width or DefaultWidth or 270
                        FxdCtx.Prm.McroModAmt_Norm[IdM] = FxdCtx.Prm.McroModAmt --[[ [IdM]/(width*0.65) ]]
                    end
                end


                if not HasModAmt then FxdCtx.FX[FxGUID][Fx_P].ModAMT = nil end
            end

            FxdCtx.FX[FxGUID] = FxdCtx.FX[FxGUID] or {}
            if r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. '1' .. FxGUID, '', false) then
                FxdCtx.FX[FxGUID].MorphA = FxdCtx.FX[FxGUID].MorphA or {}
                FxdCtx.FX[FxGUID].MorphB = FxdCtx.FX[FxGUID].MorphB or {}
                FxdCtx.FX[FxGUID].PrmList = {}
                local PrmCount = r.TrackFX_GetNumParams(Track, FX_Idx)

                GF.RestoreBlacklistSettings(FxGUID, FX_Idx, Track, PrmCount)

                for i = 0, PrmCount - 4, 1 do
                    _, FxdCtx.FX[FxGUID].MorphA[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. i .. FxGUID, '',
                        false)
                    FxdCtx.FX[FxGUID].MorphA[i] = tonumber(FxdCtx.FX[FxGUID].MorphA[i])
                    _, FxdCtx.FX[FxGUID].MorphB[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph B' .. i .. FxGUID, '',
                        false)
                    FxdCtx.FX[FxGUID].MorphB[i] = tonumber(FxdCtx.FX[FxGUID].MorphB[i])
                end

                _, FxdCtx.FX[FxGUID].MorphA_Name = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', '', false)
                if FxdCtx.FX[FxGUID].MorphA_Name == '' then FxdCtx.FX[FxGUID].MorphA_Name = nil end
                _, FxdCtx.FX[FxGUID].MorphB_Name = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', '', false)
                if FxdCtx.FX[FxGUID].MorphB_Name == '' then FxdCtx.FX[FxGUID].MorphB_Name = nil end
            end
        end

        _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
        if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
            local FXGUIDofRackMixer = r.TrackFX_GetFXGUID(Track, FX_Idx)
            FxdCtx.FX[FXGUIDofRackMixer].LyrID = FxdCtx.FX[FXGUIDofRackMixer].LyrID or {}
            FxdCtx.FX[FXGUIDofRackMixer].LyrTitle = FxdCtx.FX[FXGUIDofRackMixer].LyrTitle or {}
            FxdCtx.FX[FXGUIDofRackMixer].ActiveLyrCount = 0

            for i = 1, 8, 1 do
                _, FxdCtx.FX[FXGUIDofRackMixer].LyrID[i] = r.GetProjExtState(0, 'FX Devices',
                    'FX' .. FXGUIDofRackMixer .. 'Layer ID ' .. i)
                _, FxdCtx.FX[FXGUIDofRackMixer].LyrTitle[i] = r.GetProjExtState(0, 'FX Devices - ',
                    'FX' .. FXGUIDofRackMixer .. 'Layer Title ' .. i)
                if FxdCtx.FX[FXGUIDofRackMixer].LyrTitle[i] == '' then FxdCtx.FX[FXGUIDofRackMixer].LyrTitle[i] = nil end
                FxdCtx.FX[FXGUIDofRackMixer].LyrID[i] = tonumber(FxdCtx.FX[FXGUIDofRackMixer].LyrID[i])
                if FxdCtx.FX[FXGUIDofRackMixer].LyrID[i] ~= -1 and FxdCtx.FX[FXGUIDofRackMixer].LyrID[i] then
                    FxdCtx.FX[FXGUIDofRackMixer].ActiveLyrCount =
                        FxdCtx.FX[FXGUIDofRackMixer].ActiveLyrCount + 1
                end
            end


            _, FxdCtx.Lyr.FX_Ins[FXGUIDofRackMixer] = r.GetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FxGUID)
            if FxdCtx.Lyr.FX_Ins[FXGUIDofRackMixer] == "" then FxdCtx.Lyr.FX_Ins[FXGUIDofRackMixer] = nil end
            FxdCtx.Lyr.FX_Ins[FXGUIDofRackMixer] = tonumber(FxdCtx.Lyr.FX_Ins[FXGUIDofRackMixer])
        elseif FX_Name:find('FXD Saike BandSplitter') then
            FxdCtx.FX[FxGUID].BandSplitID = tonumber(select(2,
                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: BandSplitterID' .. FxGUID, '', false)))
            _, FxdCtx.FX[FxGUID].AttachToJoiner = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Splitter\'s Joiner FxID ' ..
                FxGUID, '', false)

            for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                --Restore Band Split
                local FxID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                if select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which BS' .. FxID, '', false)) == FxGUID then
                    --local _, Guid_FX_In_BS = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX is in which BS'..FxID, '', false  )
                    FxdCtx.FX[FxID] = FxdCtx.FX[FxID] or {}
                    FxdCtx.FX[FxID].InWhichBand = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which Band' .. FxID, '', false)))

                    FxdCtx.FX[FxGUID].FXsInBS = FxdCtx.FX[FxGUID].FXsInBS or {}
                    table.insert(FxdCtx.FX[FxGUID].FXsInBS, FxID)
                end
            end
        end



        if Track == LT_Track and string.find(FX_Name, 'Pro%-Q 3') ~= nil then
            _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 331)
            ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
            ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3.DspRange[FX_Idx])
        end
    end

    for m = 1, 8, 1 do
        _, FxdCtx.Trk[TrkID].Mod[m].Name = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro' .. m .. 's Name' .. TrkID, '',
            false)
        if FxdCtx.Trk[TrkID].Mod[m].Name == '' then FxdCtx.Trk[TrkID].Mod[m].Name = nil end
        _, FxdCtx.Trk[TrkID].Mod[m].Type = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Mod' .. m .. 'Type', '', false)
        if FxdCtx.Trk[TrkID].Mod[m].Type == '' then FxdCtx.Trk[TrkID].Mod[m].Type = nil end
    end
end
