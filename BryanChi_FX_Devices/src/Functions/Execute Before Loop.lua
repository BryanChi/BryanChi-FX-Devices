function Retrieve_All_Saved_Data_Of_Project()

    NumOfTotalTracks = r.CountTracks(0)
        -- Repeat for every track, at the beginning of script
    for Track_Idx = 0, NumOfTotalTracks - 1, 1 do
        local Track = r.GetTrack(0, Track_Idx)
        local TrkID = r.GetTrackGUID(Track)
        local TREE = BuildFXTree(Track)


        Trk[TrkID] = Trk[TrkID] or {}
        Trk[TrkID].Container_Id = {}

        Trk[TrkID].Mod = {}
        Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
        Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
        local AutoPrmCount = GetTrkSavedInfo('How Many Automated Prm in Modulators', Track)
        Trk[TrkID].AutoPrms = Trk[TrkID].AutoPrms or {}
        for i = 1, (AutoPrmCount or 0) + 1, 1 do
            Trk[TrkID].AutoPrms[i] = GetTrkSavedInfo('Auto Mod' .. i, Track, 'str')
        end
    -- Trk[TrkID].Container_Id    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID slot '..i , #Trk[TrkID].Container_Id , true )


        local function RC(str, type)
            if type == 'str' then
                local i= select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false))
                if i =='' then return nil else return i end 
            else
                return tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false)))
            end
        end

        for i = 1, 8, 1 do -- for every modulator
            Trk[TrkID].Mod[i] = {}
            local m = Trk[TrkID].Mod[i]

            m.ATK = RC('Macro ' .. i .. ' Atk')
            m.REL = RC('Macro ' .. i .. ' Rel')
            Trk[TrkID].SEQL[i] = RC('Macro ' .. i .. ' SEQ Length')
            Trk[TrkID].SEQ_Dnom[i] = RC('Macro ' .. i .. ' SEQ Denominator')
            m.Smooth = RC('Macro ' .. i .. ' Follower Speed')
            m.Gain = RC('Macro ' .. i .. ' Follower Gain')

            m.LFO_NodeCt = RC('Mod ' .. i .. 'Total Number of Nodes')
            m.LFO_spd = RC('Mod ' .. i .. 'LFO Speed')
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

            if m.LFO_Env_or_Loop == 1 then m.LFO_Env_or_Loop = 'Envelope' else m.LFO_Env_or_Loop = nil end



            for N = 1, (m.LFO_NodeCt or 0), 1 do
                m.Node = m.Node or {}
                m.Node[N] = m.Node[N] or {}
                m.Node[N].x = RC('Mod ' .. i .. 'Node ' .. N .. ' X')


                m.Node[N].y       = RC('Mod ' .. i .. 'Node ' .. N .. ' Y')
                m.Node[N].ctrlX   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl X')

                m.Node[N].ctrlY   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl Y')
                m.NodeNeedConvert = true
            end
            if RC('Mod ' .. i .. 'LFO_Rel_Node') then
                local ID = RC('Mod ' .. i .. 'LFO_Rel_Node')
                m.Node[ID] = m.Node[ID] or {}
                m.Node[ID].Rel = true
            end



            Trk[TrkID].Mod[i].SEQ = Trk[TrkID].Mod[i].SEQ or {}
            --Get Seq Steps
            if Trk[TrkID].SEQL[i] then
                for St = 1, Trk[TrkID].SEQL[i], 1 do
                    Trk[TrkID].Mod[i].SEQ[St] = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', '',
                            false)))
                end
            end
        end
    
        
        local FXCount = r.TrackFX_GetCount(Track)
        Trk[TrkID] = Trk[TrkID] or {}
        Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}
        Trk[TrkID].PostFX = Trk[TrkID].PostFX or {}

        RetrieveFXsSavedLayout(FXCount)

        Trk[TrkID].ModPrmInst = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ModPrmInst', '', false)))
        for CC = 1, Trk[TrkID].ModPrmInst or 0, 1 do
            _, Trk.Prm.WhichMcros[CC .. TrkID] = r.GetSetMediaTrackInfo_String(Track,
                'P_EXT: CC Linked to which Modulation' .. CC, '', false)
        end

        _, PM.DIY_TrkID[TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID)
        PM.DIY_TrkID[TrkID] = tonumber(PM.DIY_TrkID[TrkID])

        _, Trk.Prm.Inst[TrkID] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Trk Prm Count', '', false)
        Trk.Prm.Inst[TrkID] = tonumber(Trk.Prm.Inst[TrkID])

        i = 1
        ---retrieve Pre-FX mappings?
        ---store in CurTrk.PreFX
        while i do
            local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. i, '', false)
            if rv then
                Trk[TrkID].PreFX[i] = str; i = i + 1
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
                Trk[TrkID].PostFX[i] = str; i = i + 1
            else
                i = nil
            end
        end



        if Trk[TrkID].PreFX == {} then Trk[TrkID].PreFX = nil end
        for P = 1, Trk.Prm.Inst[TrkID] or 0, 1 do
            _, Trk.Prm.Num[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track' .. TrkID .. ' P =' .. P)
            _, Trk.Prm.WhichMcros[P .. TrkID] = r.GetProjExtState(0, 'FX Devices',
                'Prm' .. P .. 'Has Which Macro Assigned, TrkID =' .. TrkID)
            if Trk.Prm.WhichMcros[P .. TrkID] == '' then Trk.Prm.WhichMcros[P .. TrkID] = nil end

            Trk.Prm.Num[P .. TrkID] = tonumber(Trk.Prm.Num[P .. TrkID])

            for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                _, Trk.Prm.FXGUID[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'P_Trk :' .. P .. 'Trk-' .. TrkID)
            end
        end 



        function Get_FX_Data (TB)
            for i, v in ipairs(TB) do 
            
                local FX_Idx = v.addr_fxid or  i - 1
                local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                local _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
                --local _, FX[FxGUID].   r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID of '..FxGUID , '' , false )
                Trk[TrkID].Container_Id = Trk[TrkID].Container_Id or {}
                if not FxGUID then return end 
                
                if v.children then  -- if it's a container
                    
                    Get_FX_Data (v.children)
                    local id =  RC('Container ID of '..FxGUID)



                end 


                FX[FxGUID] = FX[FxGUID] or {}
                FX[FxGUID].ModSlots = tonumber( select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Container Active Mod Slots '..FxGUID , '', false )))
                FX[FxGUID].MacroPageActive = StringToBool[ select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Container ID of '..FxGUID..'Macro Active' , '',false ))]



                local _, DefaultSldr_W = r.GetProjExtState(0, 'FX Devices', 'Default Slider Width for FX:' .. FxGUID)
                if DefaultSldr_W ~= '' then FX.Def_Sldr_W[FxGUID] = DefaultSldr_W end
                local _, Def_Type = r.GetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID)
                if Def_Type ~= '' then FX.Def_Type[FxGUID] = Def_Type end


                GetProjExt_FxNameNum(FxGUID)

                _, FX.InLyr[FxGUID]          = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' ..
                    FxGUID .. 'in layer')
                --FX.InLyr[FxGUID] = StringToBool[FX.InLyr[FxGUID]]
                _, FX.LyrNum[FxGUID]         = r.GetProjExtState(0, 'FX Devices', 'FXLayer ' .. FxGUID .. 'LayerNum')
                _, FX[FxGUID].inWhichLyr     = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. FxGUID .. 'is in Layer ID')
                _, FX[FxGUID].ContainerTitle = r.GetProjExtState(0, 'FX Devices - ',
                    'FX' .. FxGUID .. 'FX Layer Container Title ')
                if FX[FxGUID].ContainerTitle == '' then FX[FxGUID].ContainerTitle = nil end

                FX[FxGUID].inWhichLyr = tonumber(FX[FxGUID].inWhichLyr)
                FX.LyrNum[FxGUID] = tonumber(FX.LyrNum[FxGUID])
                _, Lyr.SplitrAttachTo[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. FxGUID)
                _, Prm.InstAdded[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added')
                if Prm.InstAdded[FxGUID] == 'true' then Prm.InstAdded[FxGUID] = true end

                if FX.InLyr[FxGUID] == "" then FX.InLyr[FxGUID] = nil end
                FX[FxGUID].Morph_ID = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID, '', false)))
                _, FX[FxGUID].Unlink = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '',
                    false)
                if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

                if FX[FxGUID].Morph_ID then
                    Trk[TrkID].Morph_ID = Trk[TrkID].Morph_ID or {}
                    Trk[TrkID].Morph_ID[FX[FxGUID].Morph_ID] = FxGUID
                end

                local rv, ProC_ID = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ProC_ID ' .. FxGUID, '', false)
                if rv then FX[FxGUID].ProC_ID = tonumber(ProC_ID) end

                if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

                --for Fx_P = 1, #FX[FxGUID] or 0, 1 do
                for Fx_P in ipairs(FX[FxGUID]) do
                    local rv, V_before = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', '', false)

                    if rv then FX[FxGUID][Fx_P].V = tonumber(V_before) end

                    local ParamX_Value = 'Param' ..
                        tostring(FX[FxGUID][Fx_P].Name) ..
                        'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID
                    ParamValue_At_Script_Start = r.TrackFX_GetParamNormalized(Track, FX_Idx, FX[FxGUID][Fx_P].Num or 0)
                    _G[ParamX_Value] = ParamValue_At_Script_Start
                    _, FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = r.GetProjExtState(0, 'FX Devices',
                        'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'to Trk Prm')
                    FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = tonumber(FX.Prm.ToTrkPrm[FxGUID .. Fx_P])

                    local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]
                    local FP = FX[FxGUID][Fx_P]
                    _G[ParamX_Value] = FX[FxGUID][Fx_P].V or 0
                    FP.WhichCC = tonumber(select(2,r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' ..(FP.Num or 0), '', false)))

                    _, FP.WhichMODs = r.GetSetMediaTrackInfo_String(Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods', '', false)
                    if FP.WhichMODs == '' then FP.WhichMODs = nil end
                    FP.ModAMT = {}
                    
                    FP.Cont_Which_CC = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P ..' Container Mod CC' , '' , false)))
                    FP.Cont_ModAMT = {}
                    if FP.Cont_Which_CC then
                        local rv , parent = r.TrackFX_GetNamedConfigParm(Track, FX_Idx, 'parent_container')
                        if parent ~= '' then 
                            local parent_FxGUID =  r.TrackFX_GetFXGUID(Track, parent)
                            FX[parent_FxGUID] = FX[parent_FxGUID] or {}
                            local Ct = FX[parent_FxGUID]
                            Ct.ModPrm = Ct.ModPrm or {}
                            table.insert(Ct.ModPrm,  FxGUID.. ' , prm : '.. FP.Num)
                        end
                    end


                    local CC = FX[FxGUID][Fx_P].WhichCC
                    local HasModAmt, HasContModAmt
                    for m, v in ipairs(MacroNums) do

                        FP.ModAMT[m] = tonumber(select(2,
                            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                                Fx_P .. 'Macro' .. m .. 'Mod Amt', '', false)))
                        if FP.ModAMT[m] then HasModAmt = true end



                        Trk[TrkID].Mod = Trk[TrkID].Mod or {}
                        Trk[TrkID].Mod[m] = Trk[TrkID].Mod[m] or {}
                        Trk[TrkID].Mod[m].Val = tonumber(select(2,
                            r.GetProjExtState(0, 'FX Devices', 'Macro' .. m .. 'Value of Track' .. TrkID)))

                        FP.ModBypass = RemoveEmptyStr(select(2,
                            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', '',
                                false)))

                        FP.ModBipolar = FP.ModBipolar or {}
                        FP.ModBipolar[m] = StringToBool[select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. m .. 'Mod Bipolar', '', false))]

                        FP.Cont_ModAMT[m] = tonumber(select(2,r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. m .. 'Container Mod Amt', '', false)))

                        if FP.Cont_ModAMT[m] then HasContModAmt = true end 
                    
                    
                    end


                    if not HasModAmt then FP.ModAMT = nil end
                    if not HasContModAmt then FP.Cont_ModAMT = nil end 
                end

                FX[FxGUID] = FX[FxGUID] or {}
                if r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. '1' .. FxGUID, '', false) then
                    FX[FxGUID].MorphA = FX[FxGUID].MorphA or {}
                    FX[FxGUID].MorphB = FX[FxGUID].MorphB or {}
                    FX[FxGUID].PrmList = {}
                    local PrmCount = r.TrackFX_GetNumParams(Track, FX_Idx)

                    RestoreBlacklistSettings(FxGUID, FX_Idx, Track, PrmCount)

                    for i = 0, PrmCount - 4, 1 do
                        _, FX[FxGUID].MorphA[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. i .. FxGUID, '',
                            false)
                        FX[FxGUID].MorphA[i] = tonumber(FX[FxGUID].MorphA[i])
                        _, FX[FxGUID].MorphB[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph B' .. i .. FxGUID, '',
                            false)
                        FX[FxGUID].MorphB[i] = tonumber(FX[FxGUID].MorphB[i])
                    end

                    _, FX[FxGUID].MorphA_Name = r.GetSetMediaTrackInfo_String(Track,
                        'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', '', false)
                    if FX[FxGUID].MorphA_Name == '' then FX[FxGUID].MorphA_Name = nil end
                    _, FX[FxGUID].MorphB_Name = r.GetSetMediaTrackInfo_String(Track,
                        'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', '', false)
                    if FX[FxGUID].MorphB_Name == '' then FX[FxGUID].MorphB_Name = nil end
                end


                _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
                if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
                    local FXGUIDofRackMixer = r.TrackFX_GetFXGUID(Track, FX_Idx)
                    FX[FXGUIDofRackMixer].LyrID = FX[FXGUIDofRackMixer].LyrID or {}
                    FX[FXGUIDofRackMixer].LyrTitle = FX[FXGUIDofRackMixer].LyrTitle or {}
                    FX[FXGUIDofRackMixer].ActiveLyrCount = 0

                    for i = 1, 8, 1 do
                        _, FX[FXGUIDofRackMixer].LyrID[i] = r.GetProjExtState(0, 'FX Devices',
                            'FX' .. FXGUIDofRackMixer .. 'Layer ID ' .. i)
                        _, FX[FXGUIDofRackMixer].LyrTitle[i] = r.GetProjExtState(0, 'FX Devices - ',
                            'FX' .. FXGUIDofRackMixer .. 'Layer Title ' .. i)
                        if FX[FXGUIDofRackMixer].LyrTitle[i] == '' then FX[FXGUIDofRackMixer].LyrTitle[i] = nil end
                        FX[FXGUIDofRackMixer].LyrID[i] = tonumber(FX[FXGUIDofRackMixer].LyrID[i])
                        if FX[FXGUIDofRackMixer].LyrID[i] ~= -1 and FX[FXGUIDofRackMixer].LyrID[i] then
                            FX[FXGUIDofRackMixer].ActiveLyrCount =
                                FX[FXGUIDofRackMixer].ActiveLyrCount + 1
                        end
                    end


                    _, Lyr.FX_Ins[FXGUIDofRackMixer] = r.GetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FxGUID)
                    if Lyr.FX_Ins[FXGUIDofRackMixer] == "" then Lyr.FX_Ins[FXGUIDofRackMixer] = nil end
                    Lyr.FX_Ins[FXGUIDofRackMixer] = tonumber(Lyr.FX_Ins[FXGUIDofRackMixer])
                elseif FX_Name:find('FXD Saike BandSplitter') then
                    FX[FxGUID].BandSplitID = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: BandSplitterID' .. FxGUID, '', false)))
                    _, FX[FxGUID].AttachToJoiner = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Splitter\'s Joiner FxID ' ..
                        FxGUID, '', false)

                    for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                        --Restore Band Split
                        local FxID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                        if select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which BS' .. FxID, '', false)) == FxGUID then
                            --local _, Guid_FX_In_BS = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX is in which BS'..FxID, '', false  )
                            FX[FxID] = FX[FxID] or {}
                            FX[FxID].InWhichBand = tonumber(select(2,
                                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which Band' .. FxID, '', false)))

                            FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
                            table.insert(FX[FxGUID].FXsInBS, FxID)
                        end
                    end
                end



                if Track == LT_Track and string.find(FX_Name, 'Pro%-Q 3') ~= nil then
                    _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 331)
                    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
                    ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3.DspRange[FX_Idx])
                end

            end
        end 

        for m = 1, 8, 1 do
            Trk[TrkID].Mod[m].Name = RC('Macro' .. m .. 's Name' .. TrkID, 'str')
        
            Trk[TrkID].Mod[m].Type = RC('Mod' .. m .. 'Type', 'str')

        end
        Get_FX_Data (TREE)
        if not Trk[TrkID].Container_Id [1] then Trk[TrkID].Container_Id = nil end 

    end
end


function attachImagesAndFonts()

    local script_folder = select(2, r.get_action_context()):match('^(.+)[\\//]')
    script_folder       = script_folder .. '/src'
    icon1               = im.CreateFont(script_folder .. '/Fonts/IconFont1.ttf', 30)
    icon1_middle        = im.CreateFont(script_folder .. '/Fonts/IconFont1.ttf', 15)
    icon1_small         = im.CreateFont(script_folder .. '/Fonts/IconFont1.ttf', 10)
    Img = {
        Trash  = im.CreateImage(CurrentDirectory .. '/src/Images/trash.png'),
        Pin    = im.CreateImage(CurrentDirectory .. '/src/Images/pin.png'),
        Pinned = im.CreateImage(CurrentDirectory .. '/src/Images/pinned.png'),
        Copy   = im.CreateImage(CurrentDirectory .. '/src/Images/copy.png'),
        Paste  = im.CreateImage(CurrentDirectory .. '/src/Images/paste.png'),
        Save   = im.CreateImage(CurrentDirectory .. '/src/Images/save.png'),
        Sine   = im.CreateImage(CurrentDirectory .. '/src/Images/sinewave.png'),
        ModIcon = im.CreateImage(CurrentDirectory .. '/src/Images/Modulation Icon.png'),
        ModIconHollow = im.CreateImage(CurrentDirectory .. '/src/Images/Modulation Icon hollow.png')
    }
    for i = 6, 30, 1 do
        _G['Font_Andale_Mono_' .. i] = im.CreateFont('andale mono', i)
        im.Attach(ctx, _G['Font_Andale_Mono_' .. i])
    end
    for i = 6, 30, 1 do
        _G['Arial_' .. i] = im.CreateFont('Arial', i)
        im.Attach(ctx, _G['Arial_' .. i])
    end

    System_Font = im.CreateFont('sans-serif', 14)
    im.Attach(ctx, System_Font)
    Font_Andale_Mono_20_B = im.CreateFont('andale mono', 20, im.FontFlags_Bold) -- TODO move to constants
    im.Attach(ctx, Font_Andale_Mono_20_B)

    im.Attach(ctx, icon1)
    im.Attach(ctx, icon1_middle)
    im.Attach(ctx, icon1_small)
    for i, v in pairs(Img) do
        im.Attach(ctx, v)
    end

    --[[ for i = 6, 64, 1 do
        _G['Arial_' .. i] = im.CreateFont('Arial', i)
        im.Attach(ctx, _G['Arial_' .. i])
    end ]]

    --Arial = im.CreateFont('Arial', 12) -- TODO move to constants
end



function Retrieve_Keyboard_Shortcut_Settings()
    local KB_Shortcut , Command_ID = {},{}
    if CallFile('r', 'Keyboard Shortcuts.ini') then
 
        local file, filepath = CallFile('r', 'Keyboard Shortcuts.ini')
        if not file then return end
        Content = file:read('*a')
        local L = get_lines(filepath)
        for i, v in ipairs(L) do
         
            KB_Shortcut[i] = v:sub(0, v:find(' =') - 1)
            Command_ID[i] = v:sub(v:find(' =') + 3, nil)
        end
        return KB_Shortcut, Command_ID
    end
end