-- @noindex
-- @version 1.0Beta 1

function If_FX_is_ReSpectrum(FX_Idx, FX_Name)
    if not FX_Name:find('FXD ReSpectrum') then return end
    --local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
    local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)

    --if FX below is not Pro-Q 3
    if string.find(NextFX, 'Pro%-Q 3') == nil and string.find(NextFX, 'Pro%-Q 4') == nil then
        ProQ3.SpectrumDeleteWait = (ProQ3.SpectrumDeleteWait or 0) + 1
        if ProQ3.SpectrumDeleteWait > FX_Add_Del_WaitTime then
            if FX_Idx == Sel_Track_FX_Count then
                r.TrackFX_Delete(LT_Track, FX_Idx)
            else
                r.TrackFX_Delete(LT_Track, FX_Idx)
            end
            ProQ3.SpectrumDeleteWait = 0
        end
    end
end

function If_FX_Is_BandSplitter(FX_Idx, FX_Name)
    if not FX_Name:find('FXD Saike BandSplitter') then return end
    local Width, BtnWidth = 65, 25
    local WinL, WinT, H, WinR
    local WDL = WDL or im.GetWindowDrawList(ctx)
    local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

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



                    if IsLBtnClicked and (Mods == 0 or Mods == Ctrl) then
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
                    elseif LBtn_MousdDownDuration > 0.06 and (Mods == 0 or Mods == Ctrl) and not DraggingFXs.SrcBand and FX[FxGUID].StartCount then
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
                        elseif not IsLBtnHeld and Mods == Ctrl then
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
                if Mods == Ctrl then Copy = 'Copy' end
                im.DrawList_AddTextEx(Glob.FDL, Font_Andale_Mono_20_B, 14, MsX + 20, MsY,
                    0xffffffaa,
                    (Copy or '') .. ' ' .. FXCountForBand[DraggingFXs.SrcBand] .. ' FXs')
            end
        end

        local function Put_Fxs_Inside_Into_Container()
            local track = LT_Track
            local fx_idx = Find_FxID_By_GUID(PluginScript.Guid)
            if not fx_idx then return end
            -- Get the parent container by checking if this FX has a container index
            local parent_container = tonumber(  select(2, r.TrackFX_GetNamedConfigParm(track, fx_idx, "parent_container")))
            if parent_container then
                local rv, Name = r.TrackFX_GetNamedConfigParm(track, fx_idx, "renamed_name")
                if Name == "Band Split" then
                    return parent_container
                end
            end

        
        end

        Put_Fxs_Inside_Into_Container()
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
            if VP.X then
                local Modalw, Modalh = 320, 55
                im.SetNextWindowPos(ctx, VP.X + VP.w / 2 - Modalw / 2, VP.Y + VP.h / 2 - Modalh / 2)
                im.SetNextWindowSize(ctx, Modalw, Modalh)
                im.OpenPopup(ctx, 'Delete Band Splitter? ##' .. FxGUID)
            end
        end
    end

    if im.BeginPopupModal(ctx, 'Delete Band Splitter? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
        im.Text(ctx, 'Delete the FXs in band splitter altogether?')
        if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, im.Key_N) then
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

        if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, im.Key_Y)or im.IsKeyPressed(ctx, im.Key_Enter) then
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
end -- 


function If_FX_Is_Layering_FX(FX_Idx) -- currently not used
    if --[[FX Layer Window ]] string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then --!!!!  FX Layer Window
        if not FX[FxGUID].Collapse then
            FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            r.TrackFX_Show(LT_Track, FX_Idx, 2)

            im.SameLine(ctx, nil, 0)
            --Gives the index of the specific MixRack
            im.PushStyleColor(ctx, im.Col_FrameBg, FX_Layer_Container_BG or BGColor_FXLayeringWindow)
            FXLayeringWin_X = 240; local Pad = 3
            if im.BeginChild(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, FXLayeringWin_X + Pad, 220, im.WindowFlags_NoScrollbar) then
                local WDL = im.GetWindowDrawList(ctx)
                FXLayerFrame_PosX_L, FXLayerFrame_PosY_T = im.GetItemRectMin(ctx)
                FXLayerFrame_PosX_R, FXLayerFrame_PosY_B = im.GetItemRectMax(ctx); FXLayerFrame_PosY_B =
                    FXLayerFrame_PosY_B + 220

                local clrhdrhvr = im.GetColor(ctx, im.Col_ButtonHovered)
                local clrhdrAct = im.GetColor(ctx, im.Col_ButtonActive)

                im.PushStyleColor(ctx, im.Col_HeaderHovered, clrhdrhvr)
                local clrhdr = im.GetColor(ctx, im.Col_Button)
                im.PushStyleColor(ctx, im.Col_TableHeaderBg, clrhdr)

                im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, 0)


                im.BeginTable(ctx, '##FX Layer' .. FX_Idx, 1)
                im.TableHeadersRow(ctx)


                if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                    DragFX_ID = FX_Idx
                    im.SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                    im.EndDragDropSource(ctx)
                    DragDroppingFX = true
                    if IsAnyMouseDown == false then DragDroppingFX = false end
                end
                if im.IsItemClicked(ctx, 0) and Mods == Alt then
                    FX[FxGUID].DeleteFXLayer = true
                elseif im.IsItemClicked(ctx, 1) then
                    FX[FxGUID].Collapse = true


                elseif im.IsItemClicked(ctx) and Mods == Shift then
                    local Spltr, FX_Inst
                    if FX[FxGUID].LyrDisable == nil then FX[FxGUID].LyrDisable = false end
                    FX[FxGUID].AldreadyBPdFXs = FX[FxGUID].AldreadyBPdFXs or {}





                    for i = 0, Sel_Track_FX_Count, 1 do
                        if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                            if not FX[FxGUID].LyrDisable then
                                if r.TrackFX_GetEnabled(LT_Track, i) == false then
                                    if FX[FxGUID].AldreadyBPdFXs == {} then
                                        table.insert(FX[FxGUID].AldreadyBPdFXs,
                                            r.TrackFX_GetFXGUID(LT_Track, i))
                                    elseif not FindStringInTable(FX[FxGUID].AldreadyBPdFXs, r.TrackFX_GetFXGUID(LT_Track, i)) then
                                        table.insert(FX[FxGUID].AldreadyBPdFXs,
                                            r.TrackFX_GetFXGUID(LT_Track, i))
                                    end
                                else
                                end
                                r.TrackFX_SetEnabled(LT_Track, i, false)
                            else
                                r.TrackFX_SetEnabled(LT_Track, i, true)
                            end

                            for ii, v in pairs(FX[FxGUID].AldreadyBPdFXs) do
                                if v == FXGUID[i] then r.TrackFX_SetEnabled(LT_Track, i, false) end
                            end
                        end
                    end


                    if not FX[FxGUID].LyrDisable then
                        r.TrackFX_SetEnabled(LT_Track, FX_Idx, false)
                    else
                        r.TrackFX_SetEnabled(LT_Track, FX_Idx, true)
                        FX[FxGUID].AldreadyBPdFXs = {}
                    end

                    if FX[FxGUID].LyrDisable then FX[FxGUID].LyrDisable = false else FX[FxGUID].LyrDisable = true end
                end


                if not FXLayerRenaming then
                    if LBtnClickCount == 2 and im.IsItemActivated(ctx) then
                        FX[FxGUID].RenameFXLayering = true
                    elseif im.IsItemClicked(ctx, 1) and Mods == Alt then
                        BlinkFX = ToggleCollapseAll(FX_Idx)
                    end
                end


                im.SameLine(ctx)
                im.AlignTextToFramePadding(ctx)
                if not FX[FxGUID].RenameFXLayering then
                    im.SetNextItemWidth(ctx, 10)
                    local TitleShort
                    if string.len(FX[FxGUID].ContainerTitle or '') > 27 then
                        TitleShort = string.sub(FX[FxGUID].ContainerTitle, 1, 27)
                    end
                    im.Text(ctx, TitleShort or FX[FxGUID].ContainerTitle or 'FX Layering')
                else -- If Renaming
                    local Flag
                    im.SetNextItemWidth(ctx, 180)
                    if FX[FxGUID].ContainerTitle == 'FX Layering' then
                        Flag = r.ImGui_InputTextFlags_AutoSelectAll()
                    end
                    _, FX[FxGUID].ContainerTitle = im.InputText(ctx, '##' .. FxGUID,
                        FX[FxGUID].ContainerTitle or 'FX Layering', Flag)

                    im.SetItemDefaultFocus(ctx)
                    im.SetKeyboardFocusHere(ctx, -1)

                    if im.IsItemDeactivated(ctx) then
                        FX[FxGUID].RenameFXLayering = nil
                        r.SetProjExtState(0, 'FX Devices - ', 'FX' .. FxGUID ..
                            'FX Layer Container Title ', FX[FxGUID].ContainerTitle)
                    end
                end

                --im.PushStyleColor(ctx,im.Col_Button, 0xffffff10)

                im.SameLine(ctx, FXLayeringWin_X - 25, 0)
                im.AlignTextToFramePadding(ctx)
                if not FX[FxGUID].SumMode then
                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)
                end
                local Lbl
                if FX[FxGUID].SumMode == 0 then Lbl = 'Avg' else Lbl = 'Sum' end
                if im.Button(ctx, (Lbl or '') .. '##FX Lyr Mode' .. FxGUID, 30, im.GetTextLineHeight(ctx)) then
                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)

                    if FX[FxGUID].SumMode == 0 then
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 1)
                        FX[FxGUID].SumMode = 1
                    else
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 0)
                        FX[FxGUID].SumMode = 0
                    end
                end

                --im.PopStyleColor(ctx)
                im.PopStyleVar(ctx)

                im.EndTable(ctx)
                im.PopStyleColor(ctx, 2) --Header Clr
                im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 0)
                --im.PushStyleColor(ctx,im.Col_FrameBgActive, 0x99999999)
                local StyleVarPop = 1
                local StyleClrPop = 1


                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)



                local MaxChars

                if FX[FxGUID].ActiveLyrCount <= 4 then
                    LineH = 4; Spacing = 0; Inner_Spacing = 2; BtnSizeManual = 34; MaxChars = 15
                elseif FX[FxGUID].ActiveLyrCount == 5 then
                    LineH, Spacing, Inner_Spacing = 3, -5, 0; BtnSizeManual = 30; MaxChars = 18
                elseif FX[FxGUID].ActiveLyrCount == 6 then
                    LineH, Spacing, Inner_Spacing = 5.5, -5, -8; BtnSizeManual = 24; MaxChars = 20
                elseif FX[FxGUID].ActiveLyrCount >= 7 then
                    LineH, Spacing, Inner_Spacing = 3, -5, -8; BtnSizeManual = 19; MaxChars = 23
                end



                im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 1, Spacing)
                im.PushStyleVar(ctx, im.StyleVar_FramePadding, 4, LineH)

                local BtnSize, AnySoloChan
                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                    if Lyr.Solo[LyrID .. FxGUID] == 1 then
                        FX[FxGUID].AnySoloChan = true
                        AnySoloChan = true
                    end
                end
                if not AnySoloChan then FX[FxGUID].AnySoloChan = nil end


                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                    if Lyr.Solo[LyrID .. FxGUID] == nil then
                        Lyr.Solo[LyrID .. FxGUID] = reaper
                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)))
                    end
                    if Lyr.Solo[LyrID .. FxGUID] == 1 then FX[FxGUID].AnySoloChan = true end
                    if Lyr.Mute[LyrID .. FxGUID] == nil then
                        Lyr.Mute[LyrID .. FxGUID] = reaper
                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                    end
                    if Lyr.Mute[LyrID .. FxGUID] == 1 then FX[FxGUID].AnyMuteChan = true end

                    if Lyr.ProgBarVal[LyrID .. FxGUID] == nil then
                        Layer1Vol = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                        Lyr.ProgBarVal[LyrID .. FxGUID] = Layer1Vol
                    end

                    LyrFX_Inst = math.max(LyrFX_Inst or 0, LyrID)
                    local HowManyFXinLyr = 0
                    for i = 0, Sel_Track_FX_Count, 1 do
                        if FX.InLyr[FXGUID[i]] == FXGUID_RackMixer and FX[FXGUID[i]].inWhichLyr == LyrID then
                            HowManyFXinLyr = HowManyFXinLyr + 1
                        end
                    end


                    local Fx_P = (LyrID * 2) - 1

                    local CurY = im.GetCursorPosY(ctx)
                    if FX[FxGUID][Fx_P] then
                        LyrCurX, LyrCurY = im.GetCursorScreenPos(ctx)

                        if Lyr.Rename[LyrID .. FxGUID] ~= true and Fx_P then
                            --im.ProgressBar(ctx, Lyr.ProgBarVal[LyrID..FxGUID], FXLayeringWin_X-60, 30, '##Layer'.. LyrID)
                            local P_Num = 1 + (5 * (LyrID - 1))
                            local ID = LyrID
                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}

                            local labeltoShow = FX[FxGUID].LyrTitle[ID] or LyrID

                            if string.len(labeltoShow or '') > MaxChars then
                                labeltoShow = string.sub(FX[FxGUID].LyrTitle[ID], 1, MaxChars)
                            end
                            local Fx_P = LyrID * 2 - 1
                            local Label = '##' .. LyrID .. FxGUID
                            FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
                            FX[FxGUID][Fx_P].V = FX[FxGUID][Fx_P].V or 0.5
                            local p_value = FX[FxGUID][Fx_P].V or 0
                            --[[ im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, BtnSizeManual/3) ]]
                            --[[ im.PushStyleColor(ctx, im.Col_FrameBg, getClr(im.Col_Button)) ]]
                            SliderStyle = nil; Rounding = 0
                            local CurY = im.GetCursorPosY(ctx)
                            AddDrag(ctx, Label, labeltoShow, p_value, 0, 1, Fx_P, FX_Idx, P_Num, 'FX Layering', FXLayeringWin_X - BtnSizeManual * 3 - 23, Inner_Spacing, Disable, Lbl_Clickable, 'Bottom', 'Bottom', DragDir, 'NoInput')
                            --[[ im.PopStyleColor(ctx)  im.PopStyleVar(ctx) ]]

                            local L, T = im.GetItemRectMin(ctx); B = T + BtnSizeManual
                            BtnSize = B - T
                            im.SameLine(ctx, nil, 10)
                            im.SetCursorPosY(ctx, CurY)

                            if Lyr.Selected[FXGUID_RackMixer] == LyrID then
                                local R = L + FXLayeringWin_X
                                im.DrawList_AddLine(WDL, L, T - 2, R - 2 + Pad, T - 2, 0x99999999)
                                im.DrawList_AddLine(WDL, L, B, R - 2 + Pad, B, 0x99999999)
                                im.DrawList_AddRectFilled(WDL, L, T - 2, R + Pad, B, 0xffffff09)
                                FX[FxGUID].TheresFXinLyr = nil
                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                    if FX[FXGUID[FX_Idx]] then
                                        if FX[FXGUID[FX_Idx]].inWhichLyr == LyrID and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                            im.DrawList_AddLine(WDL, R - 2 + Pad, T, R - 2 + Pad,
                                                FXLayerFrame_PosY_T, 0x99999999)
                                            im.DrawList_AddLine(WDL, R - 2 + Pad, B, R - 2 + Pad,
                                                FXLayerFrame_PosY_B, 0x99999999)
                                            FX[FxGUID].TheresFXinLyr = true
                                        end
                                    end
                                end
                                if not FX[FxGUID].TheresFXinLyr then
                                    im.DrawList_AddLine(WDL, R, T, R, B, 0x99999999)
                                else
                                end
                            end

                            if im.IsItemClicked(ctx) and Mods == Alt then
                                local TheresFXinLyr
                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                    if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                        TheresFXinLyr = true
                                    end
                                end

                                FX_Idx_RackMixer = FX_Idx
                                function DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                    FX[FxGUID].LyrID[LyrID] = -1
                                    FX[FxGUID].LyrTitle[LyrID] = nil
                                    FX[FxGUID].ActiveLyrCount = math.max(
                                        FX[FxGUID].ActiveLyrCount - 1, 1)
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1), 0) -- turn channel power off
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                        1 + (5 * (LyrID - 1) + 1),
                                        0.5) -- set pan to center
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                        1 + (5 * (LyrID - 1)),
                                        0.5) -- set Vol to 0
                                    r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID ..
                                        'Layer ID ' .. LyrID, '-1')
                                    r.SetProjExtState(0, 'FX Devices - ',
                                        'FX' .. FxGUID .. 'Layer Title ' .. LyrID, '')
                                end

                                if not TheresFXinLyr then
                                    DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                else
                                    local Modalw, Modalh = 225, 70
                                    im.SetNextWindowPos(ctx,
                                        VP.x + VP.w / 2 - Modalw / 2,
                                        VP.y + VP.h / 2 - Modalh / 2)
                                    im.SetNextWindowSize(ctx, Modalw, Modalh)
                                    im.OpenPopup(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' ..
                                        FxGUID)
                                end
                            elseif im.IsItemClicked(ctx) and LBtnDC then
                                FX[FxGUID][Fx_P].V = 0.5
                                local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num,
                                    0.5)
                            elseif im.IsItemClicked(ctx) and Mods == Cmd and not FXLayerRenaming then
                                Lyr.Rename[LyrID .. FxGUID] = true
                            elseif im.IsItemClicked(ctx) and Mods == 0 then
                                Lyr.Selected[FXGUID_RackMixer] = LyrID
                            end
                        elseif Lyr.Rename[LyrID .. FxGUID] == true then
                            for i = 1, 8, 1 do -- set all other layer's rename to false
                                if LyrID ~= i then Lyr.Rename[i .. FxGUID] = false end
                            end
                            FXLayerRenaming = true
                            im.SetKeyboardFocusHere(ctx)
                            im.SetNextItemWidth(ctx, FXLayeringWin_X - BtnSizeManual * 3 - 23)
                            local ID = FX[FxGUID].LyrID[LyrID]
                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}
                            _, FX[FxGUID].LyrTitle[ID] = im.InputText(ctx, '##' .. LyrID,
                                FX[FxGUID].LyrTitle[ID])

                            if im.IsItemDeactivatedAfterEdit(ctx) then
                                Lyr.Rename[LyrID .. FxGUID] = false
                                FXLayerRenaming = nil
                                r.SetProjExtState(0, 'FX Devices - ', 'FX' ..
                                    FxGUID .. 'Layer Title ' .. LyrID, FX[FxGUID].LyrTitle[ID])
                            elseif im.IsItemDeactivated(ctx) then
                                Lyr.Rename[LyrID .. FxGUID] = false
                                FXLayerRenaming = nil
                            end
                            SL(nil, 10)
                        end

                        ------------ Confirm delete layer ---------------------
                        if im.BeginPopupModal(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' .. FxGUID, true, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                            im.Text(ctx, 'Delete all FXs in layer ' .. LyrID .. '?')
                            im.Text(ctx, ' ')

                            if im.Button(ctx, '(n) No (or Esc)') or im.IsKeyPressed(ctx, 78) or im.IsKeyPressed(ctx, 27) then
                                im.CloseCurrentPopup(ctx)
                            end
                            im.SameLine(ctx, nil, 20)
                            if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, 89) then
                                r.Undo_BeginBlock()
                                local L, H, HowMany = 999, 0, 0

                                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                                    if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                        HowMany = HowMany + 1
                                        L = math.min(FX_Idx, L)
                                        H = math.max(FX_Idx, H)
                                    end
                                end

                                for i = 1, HowMany, 1 do
                                    if FX[FXGUID[L]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[L]] == FXGUID_RackMixer then
                                        r.TrackFX_Delete(LT_Track, L)
                                    end
                                end
                                DeleteOneLayer(LyrID, FXGUID_RackMixer, FX_Idx_RackMixer, LT_Track)

                                diff = H - L + 1
                                r.Undo_EndBlock('Delete Layer ' .. LyrID, 0)
                            end
                            im.EndPopup(ctx)
                        end




                        ProgBar_Pos_L, ProgBar_PosY_T = im.GetItemRectMin(ctx)
                        ProgBar_Pos_R, ProgBar_PosY_B = im.GetItemRectMax(ctx)





                        if Lyr.Selected[FXGUID_RackMixer] == LyrID and Lyr.Rename[LyrID .. FxGUID] ~= true then
                            im.DrawList_AddRect(drawlist, ProgBar_Pos_L, ProgBar_PosY_T,
                                FXLayerFrame_PosX_R, ProgBar_PosY_B, 0xffffffff)
                        end

                        drawlistInFXLayering = im.GetForegroundDrawList(ctx)


                        if im.BeginDragDropTarget(ctx) then
                            dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag') --

                            if dropped and Mods == 0 then
                                DropFXtoLayer(FX_Idx, LayerNum)
                            elseif dropped and Mods == Ctrl then
                                DragFX_Src = DragFX_ID
                                if DragFX_ID > FX_Idx then
                                    DragFX_Dest = FX_Idx - 1
                                else
                                    DragFX_Dest =
                                        FX_Idx
                                end
                                DropToLyrID = LyrID
                                DroptoRack = FXGUID_RackMixer
                            end
                            if Payload_Type == 'DND ADD FX' then
                                dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX') --
                                if dropped then
                                    r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx)

                                    DropFXtoLayer(FX_Idx, LyrID)
                                end
                            end

                            HighlightSelectedItem(0x88888844, 0xffffffff, 0, L, T, R, B, h, w,
                                H_OutlineSc, V_OutlineSc, 'GetItemRect')
                            im.EndDragDropTarget(ctx)
                        end

                        local Label = '##Pan' .. LyrID .. FxGUID

                        local P_Num = 1 + (5 * (LyrID - 1) + 1)
                        local Fx_P_Knob = LyrID * 2
                        local Label = '## Pan' .. LyrID .. FxGUID
                        local p_value_Knob = FX[FxGUID][Fx_P_Knob].V
                        local labeltoShow = HowManyFXinLyr



                        AddKnob(ctx, Label, labeltoShow, p_value_Knob, 0, 1, Fx_P_Knob, FX_Idx, P_Num,
                            'FX Layering', BtnSizeManual / 2, 0, Disabled, 9, 'Within', 'None')
                        im.SameLine(ctx, nil, 10)

                        if LBtnDC and im.IsItemClicked(ctx, 0) then
                            FX[FxGUID][Fx_P_Knob].V = 0.5
                            local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0.5)
                        end

                        im.SetCursorPosY(ctx, CurY)
                        SoloBtnClrPop = Button_Color_Change(Lyr.Solo[LyrID .. FxGUID] == 1 , Layer_Solo )
                        --[[ if Lyr.Solo[LyrID .. FxGUID] == 1 then
                            local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                            im.PushStyleColor(ctx, im.Col_Button, Clr)
                            im.PushStyleColor(ctx, im.Col_ButtonActive, Act)
                            im.PushStyleColor(ctx, im.Col_ButtonHovered, Hvr)

                            SoloBtnClrPop = 3
                        end ]]

                        ClickOnSolo = im.Button(ctx, 'S##' .. LyrID, BtnSizeManual, BtnSizeManual) -- ==  lyr solo

                        if Lyr.Solo[LyrID .. FxGUID] == 1 then im.PopStyleColor(ctx, SoloBtnClrPop) end


                        if ClickOnSolo then
                            Lyr.Solo[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                LT_Track,
                                FX_Idx, 4 + (5 * (LyrID - 1)))
                            if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                Lyr.Solo[LyrID .. FxGUID] = 0
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                    4 + (5 * (LyrID - 1)),
                                    Lyr.Solo[LyrID .. FxGUID])
                                im.PushStyleColor(ctx, im.Col_Button, 0x9ed9d3ff)
                                im.PopStyleColor(ctx)
                            elseif Lyr.Solo[LyrID .. FxGUID] == 0 then
                                Lyr.Solo[LyrID .. FxGUID] = 1
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                    4 + (5 * (LyrID - 1)),
                                    Lyr.Solo[LyrID .. FxGUID])
                            end
                        end
                        if Lyr.Solo[LyrID .. FxGUID] == nil then
                            Lyr.Solo[LyrID .. FxGUID] = reaper
                                .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                    4 + (5 * (LyrID - 1)))
                        end

                        im.SameLine(ctx, nil, 3)
                        im.SetCursorPosY(ctx, CurY)
                        --[[ if Lyr.Mute[LyrID .. FxGUID] == 0 then
                            local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                            im.PushStyleColor(ctx, im.Col_Button, Clr)
                            im.PushStyleColor(ctx, im.Col_ButtonActive, Act)
                            im.PushStyleColor(ctx, im.Col_ButtonHovered, Hvr)
                            LyrMuteClrPop = 3
                        end ]]

                        LyrMuteClrPop = Button_Color_Change(Lyr.Mute[LyrID .. FxGUID] == 0 , Layer_Mute )



                        ClickOnMute = im.Button(ctx, 'M##' .. LyrID, BtnSizeManual, BtnSizeManual)
                        if Lyr.Mute[LyrID .. FxGUID] == 0 then im.PopStyleColor(ctx, LyrMuteClrPop) end



                        if Lyr.Mute[LyrID .. FxGUID] == nil then
                            Lyr.Mute[LyrID .. FxGUID] = reaper
                                .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                        end

                        if ClickOnMute then
                            Lyr.Mute[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                LT_Track,
                                FX_Idx, 5 * (LyrID - 1))
                            if Lyr.Mute[LyrID .. FxGUID] == 1 then
                                Lyr.Mute[LyrID .. FxGUID] = 0
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                    5 * (LyrID - 1),
                                    Lyr.Mute[LyrID .. FxGUID])
                            elseif Lyr.Mute[LyrID .. FxGUID] == 0 then
                                Lyr.Mute[LyrID .. FxGUID] = 1
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1),
                                    Lyr.Mute[LyrID .. FxGUID])
                            end
                        end




                        MuteBtnR, MuteBtnB = im.GetItemRectMax(ctx)

                        if FX[FxGUID].AnySoloChan then
                            if Lyr.Solo[LyrID .. FxGUID] ~= 1 then
                                im.DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                    0x00000088)
                            end
                        end
                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                            im.DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                0x00000088)
                        end
                    end
                end




                if FX[FxGUID].ActiveLyrCount ~= 8 then
                    AddNewLayer = im.Button(ctx, '+', FXLayeringWin_X, 25)
                    if AddNewLayer then
                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                        if FX[FxGUID].ActiveLyrCount <= 8 then
                            local EmptyChan, chan1, chan2, chan3; local lastnum = 0
                            for i, v in ipairs(FX[FxGUID].LyrID) do
                                if not EmptyChan then
                                    if v == -1 then EmptyChan = i end
                                end
                            end

                            if not EmptyChan then EmptyChan = FX[FxGUID].ActiveLyrCount + 1 end
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (EmptyChan - 1), 1)
                            FX[FxGUID].ActiveLyrCount = math.min(FX[FxGUID].ActiveLyrCount + 1, 8)
                            FX[FxGUID][EmptyChan * 2 - 1].V = 0.5 -- init val for Vol
                            FX[FxGUID][EmptyChan * 2].V = 0.5     -- init val for Pan

                            FX[FxGUID].LyrID[EmptyChan] = EmptyChan

                            r.SetProjExtState(0, 'FX Devices',
                                'FX' .. FxGUID .. 'Layer ID ' .. EmptyChan,
                                EmptyChan)
                        end
                    end
                end
                im.PopStyleVar(ctx, StyleVarPop)
                im.PopStyleVar(ctx, 2)

                im.EndChild(ctx)
            end
            im.PopStyleColor(ctx, StyleClrPop)
        else -- if collapsed
            if im.BeginChild(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, 27, 220, im.WindowFlags_NoScrollbar) then
                L, T = im.GetItemRectMin(ctx)
                local DL = im.GetWindowDrawList(ctx)
                local title = (FX[FxGUID].ContainerTitle or 'FX Layering'):gsub("(.)", "%1\n")

                WindowBtnVertical = im.Button(ctx, title .. '##Vertical', 25, 220) -- create window name button
                if WindowBtnVertical and Mods == 0 then
                elseif WindowBtnVertical == true and Mods == Shift then
                    ToggleBypassFX()
                elseif im.IsItemClicked(ctx) and Mods == Alt then
                    FX[FxGUID].DeleteFXLayer = true
                elseif im.IsItemClicked(ctx, 1) and Mods == 0 then
                    FX[FxGUID].Collapse = nil
                elseif im.IsItemClicked(ctx, 1) and Mods == Alt then
                    BlinkFX = ToggleCollapseAll(FX_Idx)
                end

                if im.BeginDragDropSource(ctx, im.DragDropFlags_None) then
                    DragFX_ID = FX_Idx
                    im.SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                    im.EndDragDropSource(ctx)
                    DragDroppingFX = true
                    if IsAnyMouseDown == false then DragDroppingFX = false end
                end

                im.DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                im.DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                im.DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)


                im.EndChild(ctx)
            end
        end

        FX[FxGUID].DontShowTilNextFullLoop = true

        if not FX[FxGUID].Collapse then --Create FX windows inside rack
            local Sel_LyrID
            drawlist = im.GetBackgroundDrawList(ctx)


            Lyr.FrstFXPos[FXGUID_RackMixer] = nil
            local HowManyFXinLyr = 0
            for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                local FXisInLyr

                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)

                    if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] then --if fx is in rack mixer
                        if FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then end

                        if Lyr.Selected[FXGUID_RackMixer] == nil then Lyr.Selected[FXGUID_RackMixer] = 1 end
                        local FXGUID_LayerCheck = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                        if FX[FXGUID[FX_Idx_InLayer]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and LyrID == Lyr.Selected[FXGUID_RackMixer] and not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                            im.SameLine(ctx, nil, 0)

                            AddSpaceBtwnFXs(FX_Idx_InLayer, false, nil, LyrID)
                            Xpos_Left, Ypos_Top = im.GetItemRectMin(ctx)
                            im.SameLine(ctx, nil, 0)
                            if not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                                createFXWindow(FX_Idx_InLayer)
                            else
                            end
                            Sel_LyrID = LyrID

                            Xpos_Right, Ypos_Btm = im.GetItemRectMax(ctx)

                            im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right, Ypos_Top, Clr.Dvdr.outline)
                            im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right, Ypos_Btm, Clr.Dvdr.outline)
                        end
                        FXisInLyr = true
                    end
                end
                if FXisInLyr == true then HowManyFXinLyr = HowManyFXinLyr + 1 end

                if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] then
                    if Lyr.FrstFXPos[FXGUID_RackMixer] == nil then
                        Lyr.FrstFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                    else
                        Lyr.FrstFXPos[FXGUID_RackMixer] = math.min(Lyr.FrstFXPos[FXGUID_RackMixer],
                            FX_Idx_InLayer)
                    end
                    Lyr.LastFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                end

                im.SameLine(ctx, nil, 0)
            end


            Lyr[FXGUID_RackMixer] = Lyr[FXGUID_RackMixer] or {}
            Lyr[FXGUID_RackMixer].HowManyFX = HowManyFXinLyr



            if HowManyFXinLyr > 0 and FX[FxGUID].TheresFXinLyr then -- ==  Add and theres fx in selected layer
                --if there's fx in the rack

                AddLastSPCinRack = true

                AddSpaceBtwnFXs(FX_Idx, nil, nil, Sel_LyrID)
                AddLastSPCinRack = false
                Xpos_Right, Ypos_Btm = im.GetItemRectMax(ctx)
                Xpos_Left, Ypos_Top = im.GetItemRectMin(ctx)


                local TheresFXinLyr
                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                    if FX[FXGUID[FX_Idx]] then
                        if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[Lyr.Selected[FXGUID_RackMixer]] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                            TheresFXinLyr = true
                        end
                    end
                end


                if TheresFXinLyr then --==  lines to enclose fx layering
                    im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right, Ypos_Top,
                        Clr.Dvdr.outline)
                    im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right, Ypos_Btm,
                        Clr.Dvdr.outline)
                    im.DrawList_AddLine(ViewPort_DL, Xpos_Right, Ypos_Top, Xpos_Right, Ypos_Btm,
                        Clr.Dvdr.outline, 14)
                end
            end
        end







        if FX[FxGUID].DeleteFXLayer then
            local FXinRack = 0
            --count number of fxs in layer
            for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                    local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                    if FX.InLyr[GUID] == FXGUID[FX_Idx] then
                        FXinRack = FXinRack + 1
                    end
                end
            end

            if FXinRack == 0 then -- if no fx just delete
                r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                FX[FxGUID].DeleteFXLayer = nil
            else -- else prompt user
                local Modalw, Modalh = 270, 55
                im.SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                    VP.y + VP.h / 2 - Modalh / 2)
                im.SetNextWindowSize(ctx, Modalw, Modalh)
                im.OpenPopup(ctx, 'Delete FX Layer? ##' .. FxGUID)
            end
        end

        if im.BeginPopupModal(ctx, 'Delete FX Layer? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
            im.Text(ctx, 'Delete the FXs in layers altogether?')
            if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, 78) then
                for i = 0, Sel_Track_FX_Count, 1 do
                    if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                        --sets input channel
                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                        --sets Output
                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)
                        FX.InLyr[FXGUID[i]] = nil
                        r.SetProjExtState(0, 'FX Devices',
                            'FXLayer - ' .. 'is FX' .. FXGUID[i] .. 'in layer', "")
                    end
                end

                for i = 0, Sel_Track_FX_Count, 1 do
                    if FXGUID[FX_Idx] == Lyr.SplitrAttachTo[FXGUID[i]] then
                        r.TrackFX_Delete(LT_Track, FX_Idx)
                        r.TrackFX_Delete(LT_Track, i)
                    end
                end

                FX[FxGUID].DeleteFXLayer = nil
            end
            im.SameLine(ctx)

            if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, 89) then
                local Spltr, FX_Inst
                for i = 0, Sel_Track_FX_Count, 1 do
                    if FXGUID[FX_Idx] == Lyr.SplitrAttachTo[FXGUID[i]] then
                        Spltr = i
                    end
                end
                r.Undo_BeginBlock()

                for i = 0, Sel_Track_FX_Count, 1 do
                    if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                        FX_Inst = (FX_Inst or 0) + 1
                        r.SetProjExtState(0, 'FX Devices',
                            'FXLayer - ' .. 'is FX' .. FXGUID[i] .. 'in layer', "")
                    end
                end

                for i = 0, FX_Inst, 1 do
                    r.TrackFX_Delete(LT_Track, Spltr)
                end



                FX[FxGUID].DeleteFXLayer = nil
                r.Undo_EndBlock('Delete Layer Container', 0)
            end
            im.SameLine(ctx)

            if im.Button(ctx, '(c) Cancel  (or Esc)') or im.IsKeyPressed(ctx, 67) or im.IsKeyPressed(ctx, 27) then
                FX[FxGUID].DeleteFXLayer = nil
                im.CloseCurrentPopup(ctx)
            end
            im.SameLine(ctx)

            im.EndPopup(ctx)
        end

        im.SameLine(ctx, nil, 0)
        FX[FXGUID[FX_Idx]].DontShowTilNextFullLoop = true
    end
end

function If_FX_is_Split_to_32_Channels(FX_Idx, FX_Name)
    if string.find(FX_Name, 'FXD Split to 32 Channels')  then
        r.TrackFX_Show(LT_Track, FX_Idx, 2)
        AddSpaceBtwnFXs(FX_Idx, true)
        Spltr[FxGUID] = Spltr[FxGUID] or {}
        Lyr[Lyr.SplitrAttachTo[FxGUID]] = Lyr[Lyr.SplitrAttachTo[FxGUID]] or {}
        if Lyr[Lyr.SplitrAttachTo[FxGUID]].HowManyFX == 0 then
            if FXGUID[FX_Idx + 1] ~= Lyr.SplitrAttachTo[FxGUID] then
                for i = 0, Sel_Track_FX_Count - 1, 1 do
                    if FXGUID[i] == Lyr.SplitrAttachTo[FxGUID] then
                        r.TrackFX_CopyToTrack(LT_Track, FX_Idx, LT_Track, i - 1, true)
                    end
                end
            end
        end

        if Spltr[FxGUID].New == true then
            for i = 0, 16, 2 do
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 1, 0)
            end

            for i = 1, 16, 2 do
                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 2, 0)
            end

            local FxGUID_Rack = Lyr.SplitrAttachTo[FxGUID]
            for i = 1, 8, 1 do
                local P_Num = 1 + (5 * (i - 1))
                local Fx_P = i * 2 - 1
                local P_Name = 'Chan ' .. i .. ' Vol'
                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState', Fx_P, FX_Idx) -- Vol
                local P_Num = 1 + (5 * (i - 1) + 1)
                local Fx_P_Pan = i * 2
                local P_Name = 'Chan ' .. i .. ' Pan'
                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState', Fx_P_Pan, FX_Idx) -- Pan
            end
            Spltr[FxGUID].New = false
        end

        if FX.InLyr[FXGUID[FX_Idx + 1] or ''] then
            FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx + 1]]
        else
            FX.InLyr[FxGUID] = nil
        end

        pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)
    end
end

function If_FX_Count_Changed__Refresh_Comp_Reduction_Scope()     -- When Add or Delete Fx.....if  add fx or delete fx
    if Sel_Track_FX_Count ~= CompareFXCount then
        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
        if FX.Win_Name then
            local rv, tab = FindStringInTable(FX.Win_Name, 'FX Devices Gain Reduction')
            if tab then
                for i, v in ipairs(tab) do
                    r.gmem_attach('CompReductionScope')
                    r.gmem_write(2001, v - 1)
                end
            end
        end

        CompareFXCount = Sel_Track_FX_Count
    end
end