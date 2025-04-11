-- @noindex

---@param FXGUID_RackMixer string
---@param LayerNum integer
---@param DragFX_ID integer
function DropFXtoLayerNoMove(FXGUID_RackMixer, LayerNum, DragFX_ID)
    DragFX_ID = math.max(DragFX_ID, 0)
    local function SetPinMappings(i)
        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 2 ^ (LayerNum * 2 - 2), 0) --sets input channel
        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2 ^ (LayerNum * 2 - 1), 0)
        --sets Output
        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 2 ^ (LayerNum * 2 - 2), 0)
        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2 ^ (LayerNum * 2 - 1), 0)
    end
    if Lyr.FX_Ins[FXGUID_RackMixer] == nil then Lyr.FX_Ins[FXGUID_RackMixer] = 0 end
    local guid = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

    if FX.InLyr[guid] ~= FXGUID_RackMixer then
        Lyr.FX_Ins[FXGUID_RackMixer] = Lyr.FX_Ins[FXGUID_RackMixer] + 1
    elseif FX.InLyr[guid] == FXGUID_RackMixer then
    end

    FX.InLyr[guid] = FXGUID_RackMixer
    r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. guid .. 'in layer', FXGUID_RackMixer)
    FX.LyrNum[guid] = LayerNum
    r.SetProjExtState(0, 'FX Devices', 'FXLayer ' .. guid .. 'LayerNum', LayerNum)

    FX[guid] = FX[guid] or {}
    FX[guid].inWhichLyr = FX[FXGUID_RackMixer].LyrID[LayerNum]
    r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. guid .. 'is in Layer ID', FX[FXGUID_RackMixer].LyrID
        [LayerNum])



    --@todo if this is the 2nd + FX in Layer, receive from layer channels (layer 2 = 3-4, layer 3 = 5-6 etc)


    r.SetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FXGUID_RackMixer, Lyr.FX_Ins[FXGUID_RackMixer])
    for i = 1, Sel_Track_FX_Count, 1 do
        local FXGUID = r.TrackFX_GetFXGUID(LT_Track, i)
        if FX.LyrNum[FXGUID] == LayerNum and FX.InLyr[FXGUID] == FXGUID_RackMixer then
            _, FXName = r.TrackFX_GetFXName(LT_Track, i)
            SetPinMappings(i)

            local rv, inputPins, outputPins = r.TrackFX_GetIOSize(LT_Track, i)
            if outputPins > 2 then
                for P = 2, outputPins, 1 do
                    r.TrackFX_SetPinMappings(LT_Track, i, 1 --[[IsOutput]], P, 0, 0)
                end
            end
            if inputPins > 2 then
                for P = 2, inputPins, 1 do
                    r.TrackFX_SetPinMappings(LT_Track, i, 0 --[[IsOutput]], P, 0, 0)
                end
            end
        end
    end
end

---@param FX_Idx integer the position in chain it's dropped to
---@param LayerNum integer
---@param AltDragSrc? integer
function DropFXtoLayer(FX_Idx, LayerNum, AltDragSrc)
    DragFX_ID = DragFX_ID or AltDragSrc or FX_Idx
    ---@param i integer
    local function SetPinMappings(i)
        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 2 ^ (LayerNum * 2 - 2), 0) --sets input channel
        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2 ^ (LayerNum * 2 - 1), 0)
        --sets Output
        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 2 ^ (LayerNum * 2 - 2), 0)
        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2 ^ (LayerNum * 2 - 1), 0)
    end

    if Lyr.FX_Ins[FXGUID_RackMixer] == nil then Lyr.FX_Ins[FXGUID_RackMixer] = 0 end
    local guid
    if Payload_Type == 'DND ADD FX' then
        guid = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
        FX[guid] = FX[guid] or {}
    else
        guid = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)
    end

    --if FX[FXGUID[DragFX_ID]].InWhichBand then -- cause of error
    --    MoveFX_Out_Of_BS()
    --end

    if FX.InLyr[guid] ~= FXGUID_RackMixer then
        Lyr.FX_Ins[FXGUID_RackMixer] = Lyr.FX_Ins[FXGUID_RackMixer] + 1
    elseif FX.InLyr[guid] == FXGUID_RackMixer then
    end

    FX.InLyr[guid] = FXGUID_RackMixer
    r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. guid .. 'in layer', FXGUID_RackMixer)
    FX.LyrNum[guid] = LayerNum
    r.SetProjExtState(0, 'FX Devices', 'FXLayer ' .. guid .. 'LayerNum', LayerNum)


    FX[guid].inWhichLyr = FX[FXGUID_RackMixer].LyrID[LayerNum]
    r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. guid .. 'is in Layer ID', FX[FXGUID_RackMixer].LyrID
        [LayerNum])



    --@todo if this is the 2nd + FX in Layer, receive from layer channels (layer 2 = 3-4, layer 3 = 5-6 etc)


    r.SetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FXGUID_RackMixer, Lyr.FX_Ins[FXGUID_RackMixer])


    MoveFX(DragFX_ID, FX_Idx, true)




    --[[ for i=1,  RepeatTimeForWindows,1 do
                local FXGUID = r.TrackFX_GetFXGUID( LT_Track, i )
                ]]
    if FX.LyrNum[guid] == LayerNum and FX.InLyr[guid] == FXGUID_RackMixer then
        local FX_Idx
        --_, FXName  = r.TrackFX_GetFXName( LT_Track, i )
        for i = 1, Sel_Track_FX_Count, 1 do
            local FXGUID = r.TrackFX_GetFXGUID(LT_Track, i)
            if FXGUID == guid then FX_Idx = i end
        end

        SetPinMappings(DragFX_ID)

        local rv, inputPins, outputPins = r.TrackFX_GetIOSize(LT_Track, DragFX_ID)
        if outputPins > 2 then
            for P = 2, outputPins, 1 do
                r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1 --[[IsOutput]], P, 0, 0)
            end
        end
        if inputPins > 2 then
            for P = 2, inputPins, 1 do
                r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0 --[[IsOutput]], P, 0, 0)
            end
        end
    end
    --[[ end ]]
end

---@param FX_Idx integer
function RepositionFXsInContainer(FX_Idx)
    r.Undo_BeginBlock()
    local FX_Idx = FX_Idx
    local FX_Count = r.TrackFX_GetCount(LT_Track)
    if AddLastSpace == 'LastSpc' and Trk[TrkID].PostFX[1] then
        FX_Idx = FX_Idx - #Trk[TrkID].PostFX
    end


    -- Move the Head of Container
    if FX_Idx > Glob.Payload or (FX_Idx == Sel_Track_FX_Count and AddLastSpace == 'LastSpc') then
        --table.insert(MovFX.FromPos,DragFX_ID) table.insert(MovFX.ToPos, FX_Idx-1)
        r.TrackFX_CopyToTrack(LT_Track, Glob.Payload, LT_Track, FX_Idx - 1, true)
    elseif Glob.Payload > FX_Idx and FX_Idx ~= Sel_Track_FX_Count then
        r.TrackFX_CopyToTrack(LT_Track, Glob.Payload, LT_Track, FX_Idx, true)
        --table.insert(MovFX.FromPos,DragFX_ID) table.insert(MovFX.ToPos, FX_Idx)
    end



    -- Move all FXs inside
    if Payload_Type == 'FX Layer Repositioning' then
        local DropDest = nil
        for i = 0, FX_Count, 1 do
            if DragFX_ID < FX_Idx then
                if DropDest == nil then DropDest = 0 end
                local ID = r.TrackFX_GetFXGUID(LT_Track, DropDest)

                if FX.InLyr[ID] == FXGUID_RackMixer or tablefind(FX[FXGUID[Glob.Payload]].FXsInBS, ID) then
                    if FX_Idx > DropDest and FX_Idx ~= Sel_Track_FX_Count or (FX_Idx == Sel_Track_FX_Count and AddLastSpace == 'LastSpc') then
                        r.TrackFX_CopyToTrack(LT_Track, DropDest, LT_Track, FX_Idx - 2, true)
                        --table.insert(MovFX.FromPos,DropDest) table.insert(MovFX.ToPos, FX_Idx-2)
                    elseif DropDest > FX_Idx and FX_Idx ~= Sel_Track_FX_Count then
                        r.TrackFX_CopyToTrack(LT_Track, DropDest, LT_Track, FX_Idx, true)
                        --table.insert(MovFX.FromPos,DropDest) table.insert(MovFX.ToPos, FX_Idx)
                    end
                else
                    DropDest = DropDest + 1
                end
            elseif DragFX_ID > FX_Idx then
                if DropDest == nil then DropDest = 1 end
                local ID = r.TrackFX_GetFXGUID(LT_Track, DropDest)
                if FX.InLyr[ID] == FXGUID_RackMixer or tablefind(FX[FXGUID[Glob.Payload]].FXsInBS, ID) then
                    r.TrackFX_CopyToTrack(LT_Track, DropDest, LT_Track, FX_Idx, true)
                    --table.insert(MovFX.FromPos,DropDest) table.insert(MovFX.ToPos, FX_Idx)

                    DropDest = DropDest + 1
                else
                    DropDest = DropDest + 1
                end
            end
        end
    elseif Payload_Type == 'BS_Drag' then
        for i, v in ipairs(FX[FXGUID[Glob.Payload]].FXsInBS) do
            if FX_Idx > Glob.Payload or (FX_Idx == Sel_Track_FX_Count and AddLastSpace == 'LastSpc') then
                r.TrackFX_CopyToTrack(LT_Track, Glob.Payload, LT_Track, FX_Idx - 1, true)
            elseif Glob.Payload > FX_Idx and FX_Idx ~= Sel_Track_FX_Count then
                r.TrackFX_CopyToTrack(LT_Track, Glob.Payload + i, LT_Track, FX_Idx + i, true)
            end
        end

        --Move Joiner
        if FX_Idx > Glob.Payload or (FX_Idx == Sel_Track_FX_Count and AddLastSpace == 'LastSpc') then
            r.TrackFX_CopyToTrack(LT_Track, Glob.Payload, LT_Track, FX_Idx - 1, true)
        elseif Glob.Payload > FX_Idx and FX_Idx ~= Sel_Track_FX_Count then
            r.TrackFX_CopyToTrack(LT_Track, Glob.Payload + #FX[FXGUID[Glob.Payload]].FXsInBS + 1, LT_Track,
                FX_Idx + #FX[FXGUID[Glob.Payload]].FXsInBS + 1, true)
        end
    end
    if Payload_Type == 'FX Layer Repositioning' then
        for i = 0, FX_Count, 1 do -- Move Splitter
            local FXGUID = r.TrackFX_GetFXGUID(LT_Track, i)

            if Lyr.SplitrAttachTo[FXGUID] == FXGUID_RackMixer then
                SplitrGUID = FXGUID
                if FX_Idx == 0 then
                    r.TrackFX_CopyToTrack(LT_Track, i, LT_Track, 0, true)
                elseif i > FX_Idx then -- FX_Idx = drop to fx position
                    if Lyr.FrstFXPos[FXGUID_RackMixer] ~= nil then
                        r.TrackFX_CopyToTrack(LT_Track, i, LT_Track, FX_Idx, true)
                        -- table.insert(MovFX.FromPos,i) table.insert(MovFX.ToPos, FX_Idx)
                    end
                elseif i < FX_Idx then
                    --table.insert(MovFX.FromPos,i) table.insert(MovFX.ToPos, FX_Idx)

                    r.TrackFX_CopyToTrack(LT_Track, i, LT_Track, DropDest or FX_Idx, true)
                end
            end
        end
    end

    local UndoName
    if Payload_Type == 'BS_Drag' then
        UndoName = 'Move Band Split and all contained FXs'
    elseif Payload_Type == 'FX Layer Repositioning' then
        UndoName = 'Move FX Layer and all contained FXs'
    end

    r.Undo_EndBlock(UndoName or 'Undo', 0)
end

function If_Saike_Band_Splitter(FxGUID, FX_Idx, FX_Name)
    if FX_Name:find('FXD Saike BandSplitter') then
        local Width, BtnWidth = 65, 25
        local WinL, WinT, H, WinR
        local WDL = WDL or im.GetWindowDrawList(ctx)

        if BandSplitID and not FX[FxGUID].BandSplitID then
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: BandSplitterID' .. FxGUID, BandSplitID, true)
            FX[FxGUID].BandSplitID = BandSplitID
            BandSplitID = nil
        end
        FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
        local JoinerID
        for i, v in ipairs(FXGUID) do
            if FX[FxGUID].AttachToJoiner == v then JoinerID = i end
        end
        local BsID = FX[FxGUID].BandSplitID
        if FX[FxGUID].Collapse then Width = 35 end


        if im.BeginChild(ctx, 'FXD Saike BandSplitter' .. FxGUID, Width, 220) then
            local SpcW = AddSpaceBtwnFXs(FX_Idx, 'SpaceBefoeBS', nil, nil, 1, FxGUID)
            SL(nil, 0)

            local btnTitle = string.gsub('Band Split', "(.)", "%1\n")
            local btn = im.Button(ctx, btnTitle .. '##Vertical', BtnWidth, 220) -- create window name button   Band Split button


            if btn and Mods == 0 then
                openFXwindow(LT_Track, FX_Idx)
            elseif btn and Mods == Shift then
                ToggleBypassFX(LT_Track, FX_Idx)
            elseif btn and Mods == Alt then
                FX[FxGUID].DeleteBandSplitter = true
            elseif im.IsItemClicked(ctx, 1) and Mods == 0 then
                FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
            elseif im.IsItemClicked(ctx, 1) and Mods == Alt then -- check if all are collapsed
                local All_Collapsed
                for i = 0, Sel_Track_FX_Count - 1, 1 do
                    if not FX[FXGUID[i]].Collapse then All_Collapsed = false end
                end
                if All_Collapsed == false then
                    for i = 0, Sel_Track_FX_Count - 1, 1 do
                        FX[FXGUID[i]].Collapse = true
                    end
                else -- if all is collapsed
                    for i = 0, Sel_Track_FX_Count - 1, 1 do
                        FX[FXGUID[i]].Collapse = false
                        FX.WidthCollapse[FXGUID[i]] = nil
                    end
                    BlinkFX = FX_Idx
                end
            elseif im.IsItemActive(ctx) then
                DraggingFX_L_Pos = im.GetCursorScreenPos(ctx) + 10
                if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                    --DragFX_ID = FX_Idx
                    im.SetDragDropPayload(ctx, 'BS_Drag', FX_Idx)
                    im.EndDragDropSource(ctx)

                    DragDroppingFX = true
                    if IsAnyMouseDown == false then DragDroppingFX = false end
                end

                --HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect',WDL )
            end
            SL(nil, 0)
            r.gmem_attach('FXD_BandSplit')




            --r.gmem_write(1,0) --[[1 is MouseR Click Position]]
            --r.gmem_write(2,0)--[[tells if user R-Click BETWEEN a band]]
            --r.gmem_write(3,0)--[[tells if user R-Click ON a band]]


            local function f_trafo(freq)
                return math.exp((1 - freq) * math.log(20 / 22050))
            end
            FX[FxGUID].Cross = FX[FxGUID].Cross or {}
            local Cuts = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 0)
            FX[FxGUID].Cross.Cuts = Cuts
            WinL, WinT = im.GetCursorScreenPos(ctx)
            H, WinR = 220, WinL + Width - BtnWidth - SpcW


            if FX[FxGUID].Collapse then
                local L, T = WinL - BtnWidth, WinT
                im.DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                im.DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                im.DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)
            else
                for i = 1, Cuts * 4, 1 do ----------[Repeat for Bands]----------
                    local TxtClr = getClr(im.Col_Text)
                    FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {}
                    local X = FX[FxGUID].Cross[i]
                    -- r.gmem_attach('FXD_BandSplit')
                    local WDL = im.GetWindowDrawList(ctx)
                    local BsID = BsID or 0

                    X.Val = r.gmem_read(BsID + i)
                    X.NxtVal = r.gmem_read(BsID + i + 1)
                    X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)


                    --FX[FxGUID].Cross[i].Val = r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)

                    local Cross_Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                    local NxtCrossPos = SetMinMax(WinT + H - H * X.NxtVal, WinT, WinT + H)


                    if --[[Hovering over a band]] im.IsMouseHoveringRect(ctx, WinL, Cross_Pos - 3, WinR, Cross_Pos + 3) then
                        FX[FxGUID].Cross.HoveringBand = i
                        FX[FxGUID].Cross.HoveringBandPos = Cross_Pos

                        if IsLBtnClicked then
                            table.insert(Sel_Cross, i)
                            Sel_Cross.FxID = FxGUID
                        elseif IsRBtnClicked then
                            --[[ if Cuts * 4 == i then  -- if deleting the top band
                                r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, 0, math.max(Cuts-0.25,0)) --simply delete top band only, leave others untouched.
                            else ]]
                            --delete band
                            local Rpt = Cuts * 4 - i
                            local Bd = i + 1
                            if FX[FxGUID].Sel_Band == i then FX[FxGUID].Sel_Band = nil end

                            local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Bd)
                            local _, Name = r.TrackFX_GetParamName(LT_Track, FX_Idx, Bd)
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0,
                                math.max(Cuts - 0.25, 0)) -- Delete Band
                            for T = 1, Rpt, 1 do
                                local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                    i + T)

                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i - 1 + T, NxtBd_V) --adjust band Freq
                            end
                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                if FX[v].InWhichBand >= i then
                                    FX[v].InWhichBand = FX[v].InWhichBand - 1

                                    local Fx = tablefind(FXGUID, v)
                                    --sets input channel
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0,
                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 2), 0)
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1,
                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 1), 0)
                                    --sets Output +1
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0,
                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 2), 0)
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1,
                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 1), 0)
                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                        'P_EXT: FX is in which Band' .. v, FX[v].InWhichBand, true)
                                end
                            end
                        end
                        --[[ if not IsLBtnHeld then
                            im.SetNextWindowPos(ctx,WinR, FX[FxGUID].Cross[i].Pos -14)
                            im.BeginTooltip(ctx)
                            im.Text(ctx, roundUp(r.gmem_read(BsID+4+i),1)..' Hz')
                            im.EndTooltip(ctx)
                        end  ]]
                    end

                    BD1 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                    BD2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2)
                    BD3 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3)
                    BD4 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4)

                    if --[[Mouse is between bands]] im.IsMouseHoveringRect(ctx, WinL, X.Pos, WinR, NxtCrossPos) then
                        if Payload_Type == 'FX_Drag' then

                        end
                    end



                    if im.IsMouseHoveringRect(ctx, WinL, WinT, WinR, WinT + H) and IsRBtnClicked then

                    end

                    if Sel_Cross[1] == i and Sel_Cross.FxID == FxGUID then
                        if IsLBtnHeld then
                            FX[FxGUID].Cross.DraggingBand = i
                            local PrmV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                            DragDeltaX, DragDeltaY = im.GetMouseDragDelta(ctx)
                            if DragDeltaY > 0 or DragDeltaY < 0 then
                                local B = Sel_Cross.TweakingBand
                                if #Sel_Cross > 1 then
                                    if DragDeltaY > 0 then -- if drag upward
                                        B = math.min(Sel_Cross[1], Sel_Cross[2])
                                        table.remove(Sel_Cross,
                                            tablefind(Sel_Cross, math.max(Sel_Cross[1], Sel_Cross[2])))
                                    else
                                        B = math.max(Sel_Cross[1], Sel_Cross[2])
                                        table.remove(Sel_Cross,
                                            tablefind(Sel_Cross, math.min(Sel_Cross[1], Sel_Cross[2])))
                                    end
                                else
                                    B = Sel_Cross[1]
                                end
                                local LowestV = 0.02
                                --r.gmem_write(100, B)
                                --r.gmem_write(101, -DragDeltaY*10)
                                --if B==1 and B==i then  -- if B ==1
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B,
                                    PrmV - DragDeltaY / 250 --[[Val of moving Freq]])

                                for i = 1, 4 - B, 1 do
                                    if PrmV - DragDeltaY / 250 > r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, B + i) then
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B + i,
                                            PrmV - DragDeltaY / 250 --[[Val of moving Freq]])
                                    end
                                end

                                --local PrmV_New= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)
                                --[[ local NextF = r.gmem_read(111+B)
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B+1, SetMinMax( (NextF - PrmV_New) /(1-PrmV_New) ,LowestV,1) ) ]]

                                --elseif B <4 and B >1 and B==i then --if B == 2~4

                                --end

                                --[[ if B <4 and B >0 and B==i then
                                    local PrmV_New= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)
                                    --local PrmV_NextB= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i+1)
                                    local ThisF = r.gmem_read(110+B)




                                    local NextF = r.gmem_read(111+B)
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B+1, SetMinMax( (NextF - PrmV_New) /(1-PrmV_New) ,LowestV,1) )
                                end ]]
                                --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, MovingBand+2, r.gmem_read(112)--[[Val of moving Freq + 1]] )


                                --r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, i, math.max(PrmV-DragDeltaY/250,0.02))
                                im.ResetMouseDragDelta(ctx)
                                --r.gmem_write(101,0)
                            end
                            if Sel_Cross[1] == i then
                                im.SetNextWindowPos(ctx, WinR, FX[FxGUID].Cross[i].Pos - 14)
                                im.BeginTooltip(ctx)
                                im.Text(ctx, roundUp(r.gmem_read(BsID + 4 + i), 1) .. ' Hz')
                                im.EndTooltip(ctx)
                                --im.DrawList_AddText(Glob.FDL, WinL, Cross_Pos, getClr(im.Col_Text) , roundUp(r.gmem_read(10+i),1)..' Hz')
                            end
                        else
                            Sel_Cross = {} --r.gmem_write(100, 0)
                        end
                    else
                    end


                    --[[ -- Draw Bands
                    im.DrawList_AddLine(WDL, WinL, X.Pos , WinR, X.Pos, TxtClr )
                    im.DrawList_AddText(WDL, WinL, X.Pos, TxtClr , roundUp(r.gmem_read(BsID+4+i),1)) ]]
                end


                function DropFXintoBS(FxID, FxGUID_BS, Band, Pl, DropDest, DontMove) --Pl is payload    --!!!! Correct drop dest!!!!
                    if not FxID then return end
                    FX[FxID] = FX[FxID] or {}

                    if FX.InLyr[FxID] then --- move fx out of Layer
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                        r.SetProjExtState(0, 'FX Devices',
                            'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer', '')
                    end



                    if FX[FxID].InWhichBand then
                        table.remove(FX[FxGUID_BS].FXsInBS, tablefind(FX[FxGUID_BS].FXsInBS, FxID))
                    end



                    if TABinsertPos then
                        table.insert(FX[FxGUID_BS].FXsInBS, TABinsertPos, FxID)
                    else
                        table.insert(FX[FxGUID_BS].FXsInBS, FxID)
                    end

                    FX[FxID].InWhichBand = Band

                    if not DontMove then
                        local DropDest = DropDest
                        table.insert(MovFX.FromPos, Pl)
                        if Pl > FX_Idx and not DropDest then DropDest = FX_Idx + 1 end


                        if Pl < DropDest then
                            DropDest = DropDest - 1
                        end



                        table.insert(MovFX.ToPos, DropDest or FX_Idx)

                        table.insert(MovFX.Lbl, 'Move FX into Band ' .. Band)
                    end



                    local function Set_In_Out(FX, Band, ChanL, ChanR)
                        r.TrackFX_SetPinMappings(LT_Track, FX, 0, ChanL or 0,
                            2 ^ ((Band + 1) * 2 - 2), 0) -- inputs
                        r.TrackFX_SetPinMappings(LT_Track, FX, 0, ChanR or 1,
                            2 ^ ((Band + 1) * 2 - 1), 0)

                        r.TrackFX_SetPinMappings(LT_Track, FX, 1, ChanL or 0,
                            2 ^ ((Band + 1) * 2 - 2), 0) --outputs
                        r.TrackFX_SetPinMappings(LT_Track, FX, 1, ChanR or 1,
                            2 ^ ((Band + 1) * 2 - 1), 0)
                    end

                    Set_In_Out(Pl, Band)

                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FxID,
                        FxGUID_BS,
                        true)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FxID,
                        Band,
                        true)



                    --- account for fxs with analyzers
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, Pl)
                    if FX_Name:find('Pro%-C 2') then
                        --Set_In_Out(Pl+1, Band+1, 2,3)
                        --r.TrackFX_SetPinMappings(LT_Track, Pl+1, 0, 2, 2^((Band+1)*2-2)*2, 0) -- inputs 3
                        --[[ r.TrackFX_SetPinMappings(LT_Track, Pl+1, 0, 3, 2^((Band+1)*2-2)*2, 0) -- inputs 4 ]]
                    end

                    local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                    if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                    local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                    if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                end

                -- Count numbeer of FXs in bands
                local FXCountForBand = {}
                FX[FxGUID].FXCheckWait = (FX[FxGUID].FXCheckWait or 0) + 1
                if FX[FxGUID].FXCheckWait > 10 then
                    for i, v in ipairs(FX[FxGUID].FXsInBS) do
                        if not tablefind(FXGUID, v) then
                            table.remove(FX[FxGUID].FXsInBS, tablefind(FX[FxGUID].FXsInBS, v))
                        end
                    end
                    FX[FxGUID].FXCheckWait = 0
                end

                for i, v in ipairs(FX[FxGUID].FXsInBS) do
                    if FX[v].InWhichBand == 0 then
                        FXCountForBand[0] = (FXCountForBand[0] or 0) + 1
                    elseif FX[v].InWhichBand == 1 then
                        FXCountForBand[1] = (FXCountForBand[1] or 0) + 1
                    elseif FX[v].InWhichBand == 2 then
                        FXCountForBand[2] = (FXCountForBand[2] or 0) + 1
                    elseif FX[v].InWhichBand == 3 then
                        FXCountForBand[3] = (FXCountForBand[3] or 0) + 1
                    elseif FX[v].InWhichBand == 4 then
                        FXCountForBand[4] = (FXCountForBand[4] or 0) + 1
                    end
                end

                for i = 0, 5, 1 do FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {} end
                for i = 0, Cuts * 4, 1 do ------- Rpt for Spaces between band splits
                    local CrossPos, Nxt_CrossPos
                    local Pl = tonumber(Payload)

                    if i == 0 then
                        CrossPos = WinT + H
                    else
                        CrossPos = FX[FxGUID].Cross[math.min(i, 4)]
                            .Pos
                    end
                    if i == Cuts * 4 then
                        Nxt_CrossPos = WinT
                    else
                        Nxt_CrossPos = FX[FxGUID].Cross[i + 1]
                            .Pos
                    end
                    local HvrOnBand = im.IsMouseHoveringRect(ctx, WinL, CrossPos - 3, WinR,
                        CrossPos + 3)
                    local HvrOnNxtBand = im.IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos - 3, WinR,
                        Nxt_CrossPos + 3)

                    if --[[Hovering over a band]] im.IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos, WinR, CrossPos) and not (HvrOnBand or HvrOnNxtBand) then
                        local function Find_InsPos()
                            local InsPos
                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                if FX[v].InWhichBand == i then InsPos = tablefind(FXGUID, v) end
                            end
                            Pl = Pl or InsPos
                            if not InsPos then
                                InsPos = FX_Idx
                            elseif Pl > FX_Idx then
                                InsPos = InsPos or (FX_Idx)
                            elseif Pl < FX_Idx then
                                InsPos = (InsPos or (FX_Idx - 1)) - 1
                            end
                            return InsPos
                        end

                        if Payload_Type == 'FX_Drag' then --Drop fx into a band
                            if FX[FXGUID[Pl]].InWhichBand ~= i then
                                im.DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                    0xffffff66)
                                if im.IsMouseReleased(ctx, 0) then
                                    local DropDest = FX_Idx
                                    local InsPos = Find_InsPos()
                                    DropFXintoBS(FXGUID[Pl], FxGUID, i, Pl, InsPos + 1)
                                end
                            end
                        elseif Payload_Type == 'DND ADD FX' then
                            im.DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                0xffffff66)

                            if im.IsMouseReleased(ctx, 0) then
                                local InsPos = Find_InsPos()
                                local rv, type, payload, is_preview, is_delivery = r
                                    .ImGui_GetDragDropPayload(ctx)
                                local id = r.TrackFX_AddByName(LT_Track, payload, false,
                                    -1000 - InsPos - 1)
                                local FXid = r.TrackFX_GetFXGUID(LT_Track, id)
                                DropFXintoBS(FXid, FxGUID, i, id, FX_Idx, 'DontMove')
                            end
                        end
                        AnySplitBandHvred = true
                        if AnySplitBandHvred then
                            HintMessage =
                            'Mouse: Alt=Delete All FXs in Layer | Shift=Bypass FXs    Keys: M=mute band   Shift+M=Toggle all muted band | S=solo band  Shift+S=Toggle all solo\'d band'
                        end
                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}
                        FX[FxGUID].PreviouslySolodBand = FX[FxGUID].PreviouslySolodBand or {}

                        --Mute Band
                        if im.IsKeyPressed(ctx, im.Key_M) and Mods == 0 then
                            local Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                4 + 5 * i)
                            if Solo == 0 then
                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                    5 * i)
                                local V
                                if OnOff == 1 then V = 0 else V = 1 end
                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, V)
                                FX[FxGUID].PreviouslyMutedBand = {}
                            end
                            --Solo Band
                        elseif im.IsKeyPressed(ctx, im.Key_S) and Mods == 0 then
                            local Mute = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)
                            if Mute == 1 then
                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                    4 + 5 * i)
                                local V
                                if OnOff == 1 then V = 0 else V = 1 end
                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, V)
                                FX[FxGUID].PreviouslySolodBand = {}
                            end
                        elseif im.IsKeyPressed(ctx, im.Key_M) and Mods == Shift then
                            local AnyMutedBand

                            for i = 0, Cuts * 4, 1 do
                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                    5 * i)

                                if OnOff == 0 then AnyMutedBand = true end
                                if OnOff == 0 then table.insert(FX[FxGUID].PreviouslyMutedBand, i) end
                                if tablefind(FX[FxGUID].PreviouslyMutedBand, i) and OnOff == 1 then
                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 0)
                                else
                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 1)
                                end
                            end

                            if not AnyMutedBand then FX[FxGUID].PreviouslyMutedBand = {} end
                        elseif im.IsKeyPressed(ctx, im.Key_S) and Mods == Shift then
                            local AnySolodBand

                            for i = 0, Cuts * 4, 1 do
                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                    4 + 5 * i)

                                if OnOff == 1 then AnySolodBand = true end
                                if OnOff == 1 then table.insert(FX[FxGUID].PreviouslySolodBand, i) end
                                if tablefind(FX[FxGUID].PreviouslySolodBand, i) and OnOff == 0 then
                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 1)
                                else
                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 0)
                                end
                            end

                            if not AnySolodBand then FX[FxGUID].PreviouslySolodBand = {} end
                        end
                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}



                        if IsLBtnClicked and (Mods == 0 or Mods == Cmd) then
                            FX[FxGUID].Sel_Band = i
                            FX[FxGUID].StartCount = true
                        elseif IsRBtnClicked and Cuts ~= 1 then
                            local _, ClickPos = im.GetMousePos(ctx, 1)
                            local H = 213
                            local Norm_V = (WinT - ClickPos + 3) / H + 1


                            local X = FX[FxGUID].Cross

                            local Seg -- determine which band it's clicked

                            X[1].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1);
                            X[2].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2);
                            X[3].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3);
                            X[4].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4);

                            if Norm_V < X[1].Val then
                                Seg = 1
                            elseif Norm_V > X[4].Val and Cuts == 0.75 then
                                Seg = 5
                            elseif Norm_V > X[1].Val and Norm_V < X[2].Val then
                                Seg = 2
                            elseif Norm_V > X[2].Val and Norm_V < X[3].Val then
                                Seg = 3
                            elseif Norm_V > X[3].Val and Norm_V < X[4].Val then
                                Seg = 4
                            end


                            if Cuts == 0.75 then
                                if Norm_V > X[3].Val then Seg = 5 end
                            elseif Cuts == 0.5 then
                                if Norm_V > X[2].Val then Seg = 5 end
                            elseif Cuts == 0.25 then
                                if Norm_V > X[1].Val then Seg = 5 end
                            end





                            if Seg == 5 then
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, Cuts + 0.25)
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)
                            elseif Seg < 5 then
                                local BandFreq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                    i + 1)
                                local BandFreq2
                                if Seg == 1 then
                                    BandFreq2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                        i + 2)
                                end

                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, Cuts + 0.25)
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)

                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 2, BandFreq)

                                if Seg == 1 then
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 3,
                                        BandFreq2)
                                end


                                --[[ for T=1, Cuts*4-Seg+1, 1 do
                                end ]]
                            end
                        elseif IsLBtnClicked and Mods == Alt then
                            if FXCountForBand[i] or 0 > 0 then
                                FX[FxGUID].PromptDeleteBand = i
                                local Modalw, Modalh = 270, 55
                                im.SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                    VP.y + VP.h / 2 - Modalh / 2)
                                im.SetNextWindowSize(ctx, Modalw, Modalh)
                                im.OpenPopup(ctx, 'Delete Band' .. i .. '? ##' .. FxGUID)
                            end
                        elseif LBtn_MousdDownDuration > 0.06 and (Mods == 0 or Mods == Cmd) and not DraggingFXs.SrcBand and FX[FxGUID].StartCount then
                            --Drag FXs to different bands
                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                if FX[v].InWhichBand == i then
                                    table.insert(DraggingFXs, v)
                                    table.insert(DraggingFXs_Idx, tablefind(FXGUID, v))
                                end
                            end
                            DraggingFXs.SrcBand = i
                            DraggingFXs.SrcFxID = FxGUID
                        elseif DraggingFXs.SrcBand and DraggingFXs[1] and IsLBtnHeld or Payload_Type == 'FX_Drag' then
                            FX[FxGUID].Sel_Band = i
                        end



                        if DraggingFXs[1] and DraggingFXs.SrcBand ~= i then
                            HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1,
                                WinR - 1,
                                Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1,
                                NoGetItemRect, NoForeground, NOrounding)
                            if not IsLBtnHeld and Mods == 0 then -- if Dropped FXs
                                for I, v in ipairs(DraggingFXs) do
                                    FX[v].InWhichBand = i
                                    local Fx = tablefind(FXGUID, v)
                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                        'P_EXT: FX is in which Band' .. v, i, true)
                                    --sets input channel
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0,
                                        2 ^ ((i + 1) * 2 - 2), 0)
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1,
                                        2 ^ ((i + 1) * 2 - 1), 0)
                                    --sets Output +1
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0,
                                        2 ^ ((i + 1) * 2 - 2), 0)
                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1,
                                        2 ^ ((i + 1) * 2 - 1), 0)
                                end
                            elseif not IsLBtnHeld and Mods == Cmd then
                                local Ofs = 0
                                for I, v in ipairs(DraggingFXs) do
                                    local offset
                                    local srcFX = DraggingFXs_Idx[I] + Ofs
                                    local TrgFX = srcFX + #DraggingFXs
                                    if not FXCountForBand[i] then -- if theres no fx in the band
                                    elseif FXCountForBand[i] > 0 then
                                        for FxInB, v in ipairs(FX[FxGUID].FXsInBS) do
                                            if FX[v].InWhichBand == i and tablefind(FXGUID, v) then
                                                offset =
                                                    tablefind(FXGUID, v)
                                            end
                                        end
                                        TrgFX = offset + I
                                    end


                                    if srcFX >= TrgFX then Ofs = I end


                                    r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, TrgFX,
                                        false)
                                    local ID = r.TrackFX_GetFXGUID(LT_Track, TrgFX)

                                    if not tablefind(FX[FxGUID].FXsInBS, ID) then
                                        table.insert(
                                            FX[FxGUID].FXsInBS, ID)
                                    end
                                    FX[ID] = FX[ID] or {}
                                    FX[ID].InWhichBand = i
                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                        'P_EXT: FX is in which Band' .. ID, i, true)
                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                        'P_EXT: FX is in which BS' .. ID, FxGUID, true)


                                    --sets input channel
                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 0, 0,
                                        2 ^ ((i + 1) * 2 - 2),
                                        0)
                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 0, 1,
                                        2 ^ ((i + 1) * 2 - 1),
                                        0)
                                    --sets Output +1
                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 1, 0,
                                        2 ^ ((i + 1) * 2 - 2),
                                        0)
                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 1, 1,
                                        2 ^ ((i + 1) * 2 - 1),
                                        0)
                                end


                                --[[ for I, v in ipairs(DraggingFXs) do
                                    local srcFX = tablefind(FXGUID, v)
                                    r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, )
                                end  ]]
                            end
                        end



                        WDL = WDL or im.GetWindowDrawList(ctx)
                        -- Highligh Hovered Band
                        if not IsLBtnHeld then
                            im.DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR, CrossPos,
                                0xffffff19)
                        end
                    end
                    if FX[FxGUID].Sel_Band == i then
                        HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                            Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1,
                            NoGetItemRect,
                            NoForeground, NOrounding)
                    end


                    local Solo, Pwr
                    if JoinerID then
                        Pwr = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)

                        local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                        if Pwr == 0 then
                            im.DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                CrossPos, Clr)
                        end

                        Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)
                        local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                        if Solo == 1 then
                            im.DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                CrossPos, Clr)
                        end
                    end
                end

                if im.BeginPopupModal(ctx, 'Delete Band' .. (FX[FxGUID].PromptDeleteBand or '') .. '? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                    im.Text(ctx, 'Delete the FXs in band ' .. FX[FxGUID].PromptDeleteBand .. '?')
                    if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, im.Key_Y) then
                        r.Undo_BeginBlock()
                        for i = 0, Sel_Track_FX_Count, 1 do
                            if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                            end
                        end
                        local DelFX = {}
                        for i, v in ipairs(FX[FxGUID].FXsInBS) do
                            if FX[v].InWhichBand == FX[FxGUID].PromptDeleteBand then
                                table.insert(DelFX, v)
                                --delete FXs
                            end
                        end
                        for i, v in ipairs(DelFX) do
                            r.TrackFX_Delete(LT_Track, tablefind(FXGUID, v) - i + 1)
                        end


                        r.Undo_EndBlock('Delete all FXs in Band ' .. FX[FxGUID].PromptDeleteBand, 0)
                        FX[FxGUID].PromptDeleteBand = nil
                        im.CloseCurrentPopup(ctx)
                    end
                    SL()
                    if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, im.Key_N) then
                        im.CloseCurrentPopup(ctx)
                    end
                    im.EndPopup(ctx)
                end






                -- draw bands

                for i = 1, Cuts * 4, 1 do
                    local X = FX[FxGUID].Cross[i]
                    if IsRBtnHeld then
                        X.Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i);

                        X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                    end
                    local BsID = FX[FxGUID].BandSplitID
                    local TxtClr = getClr(im.Col_Text)

                    im.DrawList_AddLine(WDL, WinL, X.Pos, WinR, X.Pos, TxtClr)
                    if FX[FxGUID].Cross.DraggingBand ~= i then
                        im.DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                            roundUp(r.gmem_read(BsID + 4 + i), 1))
                    end
                    if FX[FxGUID].Cross.HoveringBand == i or FX[FxGUID].Cross.DraggingBand == i then
                        if not FX[FxGUID].Cross.DraggingBand == i then
                            im.DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                roundUp(r.gmem_read(BsID + 4 + i), 1))
                        end
                        im.DrawList_AddLine(WDL, WinL, X.Pos + 1, WinR, X.Pos, TxtClr)

                        if not im.IsMouseHoveringRect(ctx, WinL, FX[FxGUID].Cross.HoveringBandPos - 3, WinR, FX[FxGUID].Cross.HoveringBandPos + 3)
                            or (FX[FxGUID].Cross.DraggingBand == i and not IsLBtnHeld) then
                            FX[FxGUID].Cross.HoveringBandPos = 0
                            FX[FxGUID].Cross.HoveringBand = nil
                            FX[FxGUID].Cross.DraggingBand = nil
                        end
                    end
                end

                -- Display Number of FXs in Band
                for i = 0, Cuts * 4, 1 do
                    if FXCountForBand[i] or 0 > 0 then
                        local This_B_Pos, nxt_X_Pos
                        if i == 4 or (i == 3 and Cuts == 0.75) or (i == 2 and Cuts == 0.5) or (i == 1 and Cuts == 0.25) then
                            nxt_X_Pos = WinT
                            This_B_Pos = FX[FxGUID].Cross[i].Pos
                        elseif i == 0 then
                            This_B_Pos = WinT + H
                            nxt_X_Pos = FX[FxGUID].Cross[1].Pos
                        else
                            nxt_X_Pos = FX[FxGUID].Cross[i + 1].Pos or 0
                            This_B_Pos = FX[FxGUID].Cross[i].Pos
                        end


                        if This_B_Pos - nxt_X_Pos > 28 and not DraggingFXs[1] then
                            im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                FXCountForBand[i] or '')
                        elseif DraggingFXs[1] then
                            if DraggingFXs.SrcBand == i then
                                MsX, MsY = im.GetMousePos(ctx)
                                im.DrawList_AddLine(Glob.FDL, MsX, MsY, WinL + 15,
                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff99)
                            else
                                im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                    FXCountForBand[i] or '')
                            end
                        end
                    end
                end

                -- Draw Background
                im.DrawList_AddRectFilled(WDL, WinL, Glob.WinT, WinR, Glob.WinB, 0xffffff33)

                local Copy

                if DraggingFXs[1] and FXCountForBand[DraggingFXs.SrcBand] then
                    local MsX, MsY = im.GetMousePos(ctx)
                    if Mods == Cmd then Copy = 'Copy' end
                    im.DrawList_AddTextEx(Glob.FDL, Font_Andale_Mono_20_B, 14, MsX + 20, MsY,
                        0xffffffaa,
                        (Copy or '') .. ' ' .. FXCountForBand[DraggingFXs.SrcBand] .. ' FXs')
                end
            end


            if not IsLBtnHeld then FX[FxGUID].StartCount = nil end


            im.EndChild(ctx)
        end

        if not FX[FxGUID].Collapse then
            local LastFX_XPos
            local FrstFX
            local ofs = 0



            for FX_ID = 0, Sel_Track_FX_Count, 1 do
                for i, v in ipairs(FX[FxGUID].FXsInBS) do
                    local _, FxName = r.TrackFX_GetFXName(LT_Track, FX_ID)

                    if FXGUID[FX_ID] == v and FX[FxGUID].Sel_Band == FX[v].InWhichBand then
                        if FxName:find('FXD ReSpectrum') then ofs = ofs + 1 end

                        if not FrstFX then
                            SL(nil, 0)
                            AddSpaceBtwnFXs(FX_ID - 1, 'SpcInBS', nil, nil, nil, FxGUID)
                            FrstFX = true
                        end
                        --if i == 1 then  SL(nil,0)  AddSpaceBtwnFXs(FX_Idx,'SpcInBS',nil,nil,1, FxGUID) end
                        SL(nil, 0)

                        I = tablefind(FXGUID, v)
                        if I then
                            createFXWindow(I)
                            SL(nil, 0)
                            AddSpaceBtwnFXs(I - ofs, 'SpcInBS', nil, nil, nil, FxGUID)
                            SL(nil, 0)
                            --[[ if i == #FX[FxGUID].FXsInBS then  ]]
                            LastFX_XPos = im.GetCursorScreenPos(ctx)
                        end
                    end
                end
            end


            if LastFX_XPos then
                local Sel_B_Pos, NxtB_Pos, AddTopLine
                local Cuts = FX[FxGUID].Cross.Cuts
                FX[FxGUID].Sel_Band = FX[FxGUID].Sel_Band or 0
                if FX[FxGUID].Sel_Band == 0 then
                    Sel_B_Pos = WinT + H
                else
                    Sel_B_Pos = FX[FxGUID].Cross[FX[FxGUID].Sel_Band].Pos
                end


                if FX[FxGUID].Sel_Band == 4
                    or (FX[FxGUID].Sel_Band == 3 and Cuts == 0.75)
                    or (FX[FxGUID].Sel_Band == 2 and Cuts == 0.5)
                    or (FX[FxGUID].Sel_Band == 1 and Cuts == 0.25)
                then
                    NxtB_Pos = WinT
                    AddTopLine = true
                else
                    NxtB_Pos = FX[FxGUID].Cross[FX[FxGUID].Sel_Band + 1].Pos or 0
                end

                local Clr = getClr(im.Col_Text)
                WinT = Glob.WinT
                H = Glob.Height or 0
                WinR = WinR or 0
                NxtB_Pos = NxtB_Pos or 0
                WinL = WinL or 0
                im.DrawList_AddLine(WDL, WinR, WinT + H, LastFX_XPos, WinT + H, Clr)
                im.DrawList_AddLine(WDL, WinR, Sel_B_Pos, WinR, WinT + H, Clr)

                im.DrawList_AddLine(WDL, WinR, NxtB_Pos, WinR, WinT, Clr)
                im.DrawList_AddLine(WDL, WinR, WinT, LastFX_XPos, WinT, Clr)
                im.DrawList_AddLine(WDL, LastFX_XPos - 1, WinT, LastFX_XPos - 1, WinT + H, Clr)
                if AddTopLine then im.DrawList_AddLine(WDL, WinL, WinT, WinR, WinT, Clr) end
                if FX[FxGUID].Sel_Band == 0 then
                    im.DrawList_AddLine(WDL, WinL, WinT + H, WinR,
                        WinT + H, Clr)
                end

                if DraggingFX_L_Pos then
                    local W = LastFX_XPos - DraggingFX_L_Pos
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT,
                        LastFX_XPos,
                        WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect, WDL)
                    if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                end
            else
                if DraggingFX_L_Pos then
                    local W = Width - 10
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT,
                        DraggingFX_L_Pos + W, WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect,
                        WDL)
                    if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                end
            end
        end
        if FX[FxGUID].DeleteBandSplitter then
            if #FX[FxGUID].FXsInBS == 0 then
                r.TrackFX_Delete(LT_Track, FX_Idx + 1)
                r.TrackFX_Delete(LT_Track, FX_Idx)
                FX[FxGUID].DeleteBandSplitter = nil
            else
                local Modalw, Modalh = 320, 55
                im.SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                    VP.y + VP.h / 2 - Modalh / 2)
                im.SetNextWindowSize(ctx, Modalw, Modalh)
                im.OpenPopup(ctx, 'Delete Band Splitter? ##' .. FxGUID)
            end
        end

        if im.BeginPopupModal(ctx, 'Delete Band Splitter? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
            im.Text(ctx, 'Delete the FXs in band splitter altogether?')
            if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, 78) then
                r.Undo_BeginBlock()
                r.TrackFX_Delete(LT_Track, FX_Idx)
                r.TrackFX_Delete(LT_Track, FX_Idx + #FX[FxGUID].FXsInBS)
                for i = 0, Sel_Track_FX_Count, 1 do
                    if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                        --sets input channel
                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                        --sets Output
                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)

                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX is in which BS' .. FXGUID[i],
                            '', true)
                        r.GetSetMediaTrackInfo_String(LT_Track,
                            'P_EXT: FX is in which Band' .. FXGUID
                            [i], '', true)
                        FX[FXGUID[i]].InWhichBand = nil
                    end
                end
                FX[FxGUID].FXsInBS = nil
                im.CloseCurrentPopup(ctx)
                FX[FxGUID].DeleteBandSplitter = nil
                r.Undo_EndBlock('Delete Band Split and put enclosed FXs back into channel one', 0)
            end
            SL()

            if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, 89) then
                r.Undo_BeginBlock()
                r.TrackFX_Delete(LT_Track, FX_Idx)
                r.TrackFX_Delete(LT_Track, FX_Idx + #FX[FxGUID].FXsInBS)
                local DelFX = {}
                for i = 0, Sel_Track_FX_Count, 1 do
                    if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                        table.insert(DelFX, FXGUID[i])
                    end
                end

                for i, v in ipairs(DelFX) do
                    FX[v].InWhichBand = nil
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. v, '',
                        true)
                    r.TrackFX_Delete(LT_Track, tablefind(FXGUID, v) - i)
                end


                r.Undo_EndBlock('Delete Band Split and all enclosed FXs', 0)
            end
            SL()
            if im.Button(ctx, '(esc) Cancel') or im.IsKeyPressed(ctx, im.Key_Escape) then
                FX[FxGUID].DeleteBandSplitter = nil
                im.CloseCurrentPopup(ctx)
            end
            im.EndPopup(ctx)
        end

        return true 
    end 
end