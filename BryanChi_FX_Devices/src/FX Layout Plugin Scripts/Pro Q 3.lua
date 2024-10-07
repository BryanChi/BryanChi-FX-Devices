-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid    ----!!!  is this the problem?
--local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
--local _, FX_Name = r.TrackFX_GetFXName(LT_Track,FX_Idx)


FX[FxGUID].CustomTitle = 'Pro-Q 3'
FX[FxGUID].TitleWidth= 100
FX[FxGUID].BgClr  = 0x000000ff
FX[FxGUID].Width = 340




-------- Add params-----------
if Prm.InstAdded[FxGUID] ~= true and FX_Name:find('Pro%-Q 3') then
    
    for Band = 1, 24, 1 do
        local gain_P_num =  ((Band - 1) * 13) + 3
        local freq_P_num =  ((Band - 1) * 13) + 2

        local Fx_P_Freq = 24+Band

        StoreNewParam(FxGUID, 'Band '.. Band..'Gain', gain_P_num, FX_Idx, false, 'AddingFromExtState', Band, FX_Idx)  -- Bands gain
        StoreNewParam(FxGUID, 'Band '.. Band..'Frequency', freq_P_num, FX_Idx, false, 'AddingFromExtState',Fx_P_Freq, FX_Idx)  -- Bands gain
    end

   -- FX.Prm.Count[FxGUID]= 28
    --- number in green represents FX Prm Index

    Prm.InstAdded[FxGUID] = true
    r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added','true')
end


---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------


if BandColor == nil then BandColor = 0x69B45D55 end
_, _, color = determineBandColor(ProQ3.LT_EQBand[FxGUID])
if color == nil then color = 0xffffffff end
im.PushStyleColor(ctx, im.Col_Text, color)

if ProQ3.LT_EQBand[FxGUID] ~= nil then
    Freq_LTBandNorm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
        13 * (ProQ3.LT_EQBand[FxGUID] - 1) + 2)
    Freq_LTBand = math.floor(x_to_freq(Freq_LTBandNorm * 340)) -- width
    ProQ3['Freq_LTBand - ' .. FxGUID] = Freq_LTBand
    local Gain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
        13 * (ProQ3.LT_EQBand[FxGUID] - 1) + 3)
    --Gain = tonumber(Gain)
    Gain = -30 + Gain * 60
    FreqValueDrag[FX_Idx] = Freq_LTBandNorm
    if Gain ~= nil then
        ProQ3['Gain_LTBand - ' .. FxGUID] = round(Gain, 1)
    end
end



im.SetNextItemWidth(ctx, 60)
if ProQ3['Freq_LTBand - ' .. FxGUID] ~= nil and ProQ3['Freq_LTBand - ' .. FxGUID] < 1000 then
    FreqLbl = ProQ3['Freq_LTBand - ' .. FxGUID] .. ' Hz'
elseif ProQ3['Freq_LTBand - ' .. FxGUID] ~= nil and ProQ3['Freq_LTBand - ' .. FxGUID] > 1000 then
    FreqLbl = round(ProQ3['Freq_LTBand - ' .. FxGUID] / 1000, 2) ..
        ' kHz'
end


im.SameLine(ctx)
im.SetNextItemWidth(ctx, 60)

if ProQ3['Gain_LTBand - ' .. FxGUID] ~= nil then
    _, ProQ3.GainDrag[FX_Idx] = im.DragDouble(ctx, '##GainDrag',
        ProQ3.GainDrag[FX_Idx] or 0, 0.01, 0, 1,
        ProQ3['Gain_LTBand - ' .. FxGUID] .. 'dB')
    ProQ3.GainDragging = im.IsItemActive(ctx)
end
SL(120)
im.SetNextItemWidth(ctx, 60)
if ProQ3['Freq_LTBand - ' .. FxGUID] ~= nil then
    local freq
    _, freq =  im.DragDouble(ctx, '##FreqDrag', freq or 0, 0.01, 0, 1, FreqLbl)
    ProQ3.FreqDragging = im.IsItemActive(ctx)
end

im.SameLine(ctx, 340 - 130)
im.SetNextItemWidth(ctx, 50)
if ProQ3['scaleLabel' .. ' ID' .. FxGUID] ~= nil then
    DispRangeBtnClicked = im.Button(ctx,
        '±' .. ProQ3['scaleLabel' .. ' ID' .. FxGUID] .. 'dB##' ..
        FX_Idx, 50, 20)
end
if DispRangeBtnClicked then
    im.OpenPopup(ctx, 'ProQ Display Range ##' .. FX_Idx)
    local L, T = im.GetItemRectMin(ctx)
    local W, H = im.GetItemRectSize(ctx)
    im.SetNextWindowPos(ctx, L, T + H)
    im.SetNextWindowSize(ctx, W, H)
end

if focusedFXState == 1 and FX_Index_FocusFX == FX_Idx and LT_ParamNum == 331 then
    _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
        331)
    ProQ3.DspRange[FX_Idx] = ProQ3.DspRange[FX_Idx]:gsub('dB', '')
    ProQ3.DspRange[FX_Idx] = tonumber(ProQ3.DspRange[FX_Idx])
    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
    ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3
        .DspRange[FX_Idx])
end



if im.BeginPopup(ctx, 'ProQ Display Range ##' .. FX_Idx) then
    if im.Selectable(ctx, '±30dB') then
        ProQ3['scale' .. ' ID' .. FxGUID] = 1
        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 331, 1)
        im.CloseCurrentPopup(ctx)
    end
    if im.Selectable(ctx, '±12dB') then
        ProQ3['scale' .. ' ID' .. FxGUID] = 2.5
        r.TrackFX_SetParam(LT_Track, FX_Idx, 331, 0.7)
        im.CloseCurrentPopup(ctx)
    end
    if im.Selectable(ctx, '±6 dB') then
        ProQ3['scale' .. ' ID' .. FxGUID] = 5
        r.TrackFX_SetParam(LT_Track, FX_Idx, 331, 0.3)
        im.CloseCurrentPopup(ctx)
    end
    if im.Selectable(ctx, '±3 dB') then
        ProQ3['scale' .. ' ID' .. FxGUID] = 10
        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 331, 0)
        im.CloseCurrentPopup(ctx)
    end

    im.EndPopup(ctx)
end
if ProQ3['scale' .. ' ID' .. FxGUID] == 1 then
    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = 30
elseif ProQ3['scale' .. ' ID' .. FxGUID] == 2.5 then
    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = 12
elseif ProQ3['scale' .. ' ID' .. FxGUID] == 5 then
    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = 6
elseif ProQ3['scale' .. ' ID' .. FxGUID] == 10 then
    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = 3
else
    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = 12
end

SL(340 - 60)
-- Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '',Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx, 314)
local GainScale = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 314)
FX.Round[FxGUID] = 100


Rounding = 10
im.PushStyleVar(ctx, im.StyleVar_FrameRounding, Rounding)
AddDrag(ctx, '##GainScale' .. FxGUID, '', GainScale, 0, 1, 0 --[[FX_P]], FX_Idx, 314, 'Pro C', 60,
    item_inner_spacing, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, DragDir, AllowInput)

if im.IsItemActivated(ctx) and im.IsMouseDoubleClicked(ctx, 0) then
    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 314, 0.5)
end
im.PopStyleVar(ctx)

im.PopStyleColor(ctx)
















---------------------------------------------
---------Body--------------------------------
---------------------------------------------















if not FX[FxGUID].Collapse then
    r.gmem_attach('gmemReEQ_Spectrum')




    if FirstLoop == true then
        _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
            331)
        ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
        ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3
            .DspRange[FX_Idx])
    end

    _, ProQ3.Format = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'fx_type')

    im.PushStyleColor(ctx, im.Col_FrameBg, 0x090909ff)

    ProQ3.H = 200
    local L , T = im.GetCursorScreenPos(ctx)

    im.SetNextWindowPos(ctx, L, T)


    if im.BeginChild(ctx, '##EQ Spectrum' .. FX_Idx, ProQ3.Width, ProQ3.H, nil) then
        if ProQ3['scale' .. ' ID' .. FxGUID] == nil then ProQ3['scale' .. ' ID' .. FxGUID] = 2.5 end
        if ProQ3['scale' .. ' ID' .. FxGUID] == 10 then
            ProQ3['DragGainScale' .. ' ID' .. FxGUID] = 100
        elseif ProQ3['scale' .. ' ID' .. FxGUID] == 5 then
            ProQ3['DragGainScale' .. ' ID' .. FxGUID] = 20
        elseif ProQ3['scale' .. ' ID' .. FxGUID] == 2.5 then
            ProQ3['DragGainScale' .. ' ID' .. FxGUID] = 5
        elseif ProQ3['scale' .. ' ID' .. FxGUID] == 1 then
            ProQ3['DragGainScale' .. ' ID' .. FxGUID] = 1
        end
        --   10 = 3dB | 5 = 6dB | 2.5 = 12 dB | 1 = 30 dB

        --DragGain
        ---THIS SETS THE SCALE
        --- Need to also scale nodes dragging
        local ShelfGain_Node = 0
        local Q_Node = {}
        local E = 2.71828182845904523
        ProQ_Xpos_L, ProQ_Ypos_T = im.GetItemRectMin(ctx)
        ProQ_Xpos_R, ProQ_Ypos_B = im.GetItemRectMax(ctx)
        --ProQ_Ypos_B= ProQ_Ypos_T+340
        local B = ProQ_Ypos_B + 340
        floor = -80; ly = 0; lx = -1;

        sc = (ProQ3.Width - 20) * 20 /
            (floor * math.log(10)) --      200 = width of window
        Foreground = im.GetWindowDrawList(ctx)
        SpectrumX = 0
        SpectrumY = 0
        r.gmem_attach('gmemReEQ_Spectrum')
        if FX[FxGUID].ProQ_ID then
            if FX_Idx > 0x2000000 then 
                r.gmem_write(FX[FxGUID].ProQ_ID, FX_Idx - 0x2000000 )

            else 
                r.gmem_write(FX[FxGUID].ProQ_ID, FX_Idx)
            end 
        end

        ----Get spectrum info
        -- attach a DIYFXGUID to each PRO Q and use that for spectrums'
    
        local  X_gmem_slot, Y_gmem_slot  
        if FX_Idx > 0x2000000 then 
            X_gmem_slot =  (FX_Idx - 0x2000000  + 1) * 1000
            Y_gmem_slot =  300 + (FX_Idx - 0x2000000  + 1) * 1000

        else 
            X_gmem_slot =  (FX_Idx + 1) * 1000
            Y_gmem_slot =  300 + (FX_Idx + 1) * 1000
        end  -- accounts for in containers

        

        if TrkID ~= TrkID_End then
            
            for i = 2, 249, 1 do
                r.gmem_write( i + X_gmem_slot, 0)
                r.gmem_write( i + Y_gmem_slot, 0)
            end
        end



        for i = 2, 249, 1 do
            BinY = r.gmem_read( i + X_gmem_slot)
            tx = r.gmem_read( i + Y_gmem_slot)

            if tx then 

                tx = freq_to_x_MyOwn(tx)

                ty = spectrum1_to_y(BinY)
                ty = ProQ_Ypos_T + ty

                tx = tx + ProQ_Xpos_L
                if lx == nil then lx = tx end

                tx = round(tx, 0)


                if lx ~= tx and i ~= 2 then
                    im.DrawList_AddQuadFilled(Foreground, lx, B, lx, ly, tx, ty, tx,
                        B, 0x003535ff)
                elseif i == 2 then
                    im.DrawList_AddQuadFilled(Foreground, lx, B, lx, ty, tx, ty, tx,
                        B, 0x003535ff)
                end

                lx = tx; ly = ty;
            end
        end



        Freq = {}
        Gain = {}
        Q = {}
        Slope = {}
        Band_Used = {}
        pts = {}

        local Band_Enabled = {}
        local Y_Mid = ProQ_Ypos_B + ProQ3.H / 2
        local y = Y_Mid


        FXGUID_ProQ = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

        for Band = 1, 24, 1 do
            paramOfUsed = 13 * (Band - 1)
            paramOfEnabled = 13 * (Band - 1) + 1
            if FXGUID_ProQ == nil then FXGUID_ProQ = 0 end
            ProQ3.Band_UseState[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, paramOfUsed)
            Band_Enabled[Band .. FXGUID_ProQ] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, paramOfEnabled)
            local x = ProQ_Xpos_L
            local y = Y_Mid
            if ProQ3.Band_UseState[Band] == 1 then
                Freq[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                    paramOfUsed + 2)
                Slope[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                    9 + 13 * (Band - 1))
                Gain[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                    paramOfUsed + 3)
                _, ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] = r
                    .TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, paramOfUsed + 8)
                NodeFreq['B-' .. Band .. 'GUID-' .. FXGUID_ProQ] = x_to_freq(Freq
                    [Band] * ProQ3.Width)
                if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Shelf' or ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Shelf' then
                    Gain[Band] = -30 + Gain[Band] * 60
                    ShelfGain_Node = Gain[Band] * 1.3


                    Gain[Band] = db_to_gain(Gain[Band])
                else
                    Gain[Band] = -30 + Gain[Band] * 60
                end
                FreqToActualFreq = x_to_freq((Freq[Band] * ProQ3.Width))



                if ProQ3.Format == 'AU' then
                    Q[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                        paramOfUsed + 7)
                else
                    if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' or ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                        _, Q[Band] = r.TrackFX_GetFormattedParamValue(LT_Track,
                            FX_Idx, paramOfUsed + 7)
                    else
                        Q[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                            paramOfUsed + 7)
                    end
                end

                Q_Node[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                    paramOfUsed + 7)
                Q_Node[Band] = (-1 + Q_Node[Band] * 2) * 50

                if Q_Node[Band] > 37 then
                    Q_Node[Band] = 37
                elseif Q_Node[Band] < -37 then
                    Q_Node[Band] = -37
                end
            end

            function FillClr_LT_Band(iteration, y1)
                if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                    X2 = x + 2
                    BandColor = determineBandColor(ProQ3.LT_EQBand[FXGUID_ProQ])
                    i = iteration
                    if i ~= 1 then
                        im.DrawList_AddLine(Foreground, x, y1, X2,Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ], BandColor,1.7)
                    end
                    x = X2
                end
            end

            function TiltShelf(Minimum_Q, Maximum_Q, Q_range, Q_Value)
                Min_Q = Minimum_Q
                Max_Q = Maximum_Q
                Q[Band] = per_to_q(Q[Band] * Q_range, 100)
                --local Gain = db_to_gain(Gain[Band] )
                local gain = Gain[Band]
                if Q_Value ~= nil then Q[Band] = Q_Value end

                svf_st(FreqToActualFreq, Q[Band], gain)

                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 1 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag
                    end
                end

                --[[  local Gain2 = 10^(-(gain) / 21);
                local Gain2 = 1 ]]

                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 2 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = ((pts[i .. 'B-' .. Band .. FXGUID_ProQ] + mag) / 2) *
                            ProQ3['scale' .. ' ID' .. FxGUID]
                        FillClr_LT_Band(i, y)
                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            X2 = x + 2
                            BandColor = determineBandColor(ProQ3.LT_EQBand
                                [FXGUID_ProQ])
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x,
                                    Y_Mid, X2, Y_Mid -
                                    pts[i .. 'B-' .. Band .. FXGUID_ProQ], BandColor,1.7)
                            end
                            x = X2
                        end
                    end
                end
            end

            ---------------------
            -- BELL
            ---------------------
            if ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Bell' then
                Freq_Math = Freq[Band] * ProQ3.Width
                Gain_Math = (Gain[Band] * (ProQ3.H / 2)) / 30

                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 2 do
                        local xscale                          = 800 /
                            (ProQ3.Width - 4);
                        Q_Math                                = ((Q[Band] ^ 3.2) * 0.55) /
                            2 + 0.005
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = (Gain_Math * Euler ^ -(Q_Math * (i - Freq_Math)) ^ 2) *
                            ProQ3['scale' .. ' ID' .. FxGUID]

                        FillClr_LT_Band(i, Y_Mid)
                    end

                    im.DrawList_PathFillConvex(Foreground, 0xffffffff)
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                if Slope[Band] < 0.2 then
                    MIN_Q = 0.1; MAX_Q = 200
                elseif Slope[Band] > 0.2 and Slope[Band] < 0.3 then
                    MIN_Q = 0.1; MAX_Q = 120
                elseif Slope[Band] > 0.3 and Slope[Band] < 0.4 then
                    MIN_Q = 0.1; MAX_Q = 40
                elseif Slope[Band] > 0.4 and Slope[Band] < 0.5 then
                    MIN_Q = 0.1; MAX_Q = 21
                elseif Slope[Band] > 0.5 and Slope[Band] < 0.6 then
                    MIN_Q = 0.26; MAX_Q = 7
                elseif Slope[Band] > 0.6 and Slope[Band] < 0.7 then
                    MIN_Q = 0.3; MAX_Q = 5
                elseif Slope[Band] > 0.7 and Slope[Band] < 0.8 then
                    MIN_Q = 0.5; MAX_Q = 2.6
                elseif Slope[Band] > 0.8 and Slope[Band] < 0.9 then
                    MIN_Q = 0.4; MAX_Q = 2.7
                elseif Slope[Band] == 1 then
                    MIN_Q = 0.7; MAX_Q = 0.7
                end
                Slope_HighCut = Slope[Band] * 20

                Q[Band]       = Q[Band] * 100
                Q_HC          = per_to_q(Q[Band], 100)

                if ProQ3.Format == 'VST' or ProQ3.Format == 'VST3' then
                    Q_HC = Q[Band] / 100 / 1.4
                else
                end

                local x = ProQ_Xpos_L
                local y = Y_Mid


                zdf_lp(FreqToActualFreq, Q_HC, Slope_HighCut)

                for i = 1, ProQ3.Width, 2 do -- do 340 times
                    iToFreq = x_to_freq(i)
                    local mag = zdf_magnitude(iToFreq)

                    mag = 20 * math.log(mag, 10)
                    mag = db_to_y(mag)

                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                        if Slope[Band] ~= 1 then
                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                ProQ3['scale' .. ' ID' .. FxGUID]
                        elseif Slope[Band] == 1 then --if Slope = brickwall
                            if iToFreq > FreqToActualFreq then
                                magForBrickwall = db_to_y(-100)
                            elseif iToFreq < FreqToActualFreq then
                                magForBrickwall = db_to_y(0)
                            end
                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = magForBrickwall
                        end

                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            BandColor = determineBandColor(ProQ3.LT_EQBand
                                [FXGUID_ProQ])
                            local X2 = x + 2
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x,
                                    Y_Mid + 100, X2,
                                    Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ],
                                    BandColor, 2)
                            end
                            x = X2
                        end
                    end
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' then
                if Slope[Band] < 0.2 then
                    MIN_Q = 0.1; MAX_Q = 200
                elseif Slope[Band] > 0.2 and Slope[Band] < 0.3 then
                    MIN_Q = 0.1; MAX_Q = 120
                elseif Slope[Band] > 0.3 and Slope[Band] < 0.4 then
                    MIN_Q = 0.1; MAX_Q = 40
                elseif Slope[Band] > 0.4 and Slope[Band] < 0.5 then
                    MIN_Q = 0.1; MAX_Q = 21
                elseif Slope[Band] > 0.5 and Slope[Band] < 0.6 then
                    MIN_Q = 0.26; MAX_Q = 7
                elseif Slope[Band] > 0.6 and Slope[Band] < 0.7 then
                    MIN_Q = 0.3; MAX_Q = 6
                elseif Slope[Band] > 0.7 and Slope[Band] < 0.8 then
                    MIN_Q = 0.5; MAX_Q = 2.6
                elseif Slope[Band] > 0.8 and Slope[Band] < 0.9 then
                    MIN_Q = 0.4; MAX_Q = 2.7
                elseif Slope[Band] == 1 then
                    MIN_Q = 0.7; MAX_Q = 0.7
                end



                Q[Band] = Q[Band] * 100
                if ProQ3.Format == 'VST' or ProQ3.Format == 'VST3' then
                    Q_LC = Q[Band] / 100 / 1.4
                elseif ProQ3.Format == 'AU' then
                    Q_LC = per_to_q(Q[Band], 100)
                end


                ProQ3['Slope' .. ' FXID-' .. FxGUID] = Slope[Band] * 20
                svf_hp(FreqToActualFreq, Q_LC,
                    ProQ3['Slope' .. ' FXID-' .. FxGUID])

                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 1 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        local mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)

                        if Slope[Band] ~= 1 then
                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                ProQ3['scale' .. ' ID' .. FxGUID]
                        elseif Slope[Band] == 1 then --if Slope = brickwall
                            local magForBrickwall;
                            if iToFreq > FreqToActualFreq then
                                magForBrickwall = db_to_y(0)
                            elseif iToFreq < FreqToActualFreq then
                                magForBrickwall = db_to_y(-100)
                            end
                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = magForBrickwall
                        end

                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            BandColor = determineBandColor(ProQ3.LT_EQBand
                                [FXGUID_ProQ])
                            local X2 = x + 1
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x,
                                    Y_Mid + 100, X2,
                                    Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ],
                                    BandColor, 2)
                            end
                            x = X2
                        end
                    end
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Shelf' then --@todo Pro Q -- No support for different slopes
                MIN_Q = 0.1; MAX_Q = 100
                Q[Band] = per_to_q(Q[Band] * 100, 100)



                svf_ls(FreqToActualFreq, Q[Band], Gain[Band])
                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 1 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                            ProQ3['scale' .. ' ID' .. FxGUID]

                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            local X2 = x + 1
                            BandColor = determineBandColor(ProQ3.LT_EQBand
                                [FXGUID_ProQ])
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x, y,
                                    X2, Y_Mid - pts
                                    [i .. 'B-' .. Band .. FXGUID_ProQ],
                                    BandColor)
                            end
                            x = X2
                        end
                    end
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Shelf' then
                MIN_Q = 0.1; MAX_Q = 100
                Q[Band] = per_to_q(Q[Band] * 100, 100)

                svf_hs(FreqToActualFreq, Q[Band], Gain[Band])
                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 1 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                            ProQ3['scale' .. ' ID' .. FxGUID]
                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            local X2 = x + 1
                            BandColor = determineBandColor(ProQ3.LT_EQBand
                                [FXGUID_ProQ])
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x, y,
                                    X2, Y_Mid - pts
                                    [i .. 'B-' .. Band .. FXGUID_ProQ],
                                    BandColor)
                            end
                            x = X2
                        end
                    end
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Band Pass' then
                MIN_Q = 0.04; MAX_Q = 3000
                Q[Band] = per_to_q(Q[Band] * 100, 100)
                svf_bp(FreqToActualFreq, Q[Band])
                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 1 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                            ProQ3['scale' .. ' ID' .. FxGUID]
                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            local X2 = x + 1
                            BandColor = determineBandColor(ProQ3.LT_EQBand
                                [FXGUID_ProQ])
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x,
                                    Y_Mid + 100, X2,
                                    Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ],
                                    BandColor)
                            end
                            x = X2
                        end
                    end
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Notch' then
                MIN_Q = 0.005; MAX_Q = 400
                Q[Band] = per_to_q(Q[Band] * 100, 100)
                svf_bs(FreqToActualFreq, Q[Band])
                local x = ProQ_Xpos_L
                local y = Y_Mid
                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    for i = 1, ProQ3.Width, 2 do -- do 340 times
                        iToFreq = x_to_freq(i)
                        mag = zdf_magnitude(iToFreq)
                        mag = 20 * math.log(mag, 10)
                        mag = db_to_y(mag)
                        pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                            ProQ3['scale' .. ' ID' .. FxGUID]
                        if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                            local X2 = x + 2
                            BandColor = determineBandColor(ProQ3.LT_EQBand[FXGUID_ProQ])
                            if i ~= 1 then
                                im.DrawList_AddLine(Foreground, x, y,
                                    X2, Y_Mid - pts
                                    [i .. 'B-' .. Band .. FXGUID_ProQ],
                                    BandColor)
                            end
                            x = X2
                        end
                    end
                end
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Tilt Shelf' then
                TiltShelf(0.1, 100, 77)
            elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Flat Tilt' then
                TiltShelf(0.000001, 0.0001, 100, 0.08)
            end
        end



        ----------------------
        --==Draw Sum of all EQ
        ----------------------
        local x = ProQ_Xpos_L
        for i = 1, ProQ3.Width, 2 do
            pts[i .. FXGUID_ProQ] = 0
            for Band = 1, 24, 1 do --Add up the sum of all eq
                if ProQ3.Band_UseState[Band] == 1 then
                    if pts[i .. 'B-' .. Band .. FXGUID_ProQ] and Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                        pts[i .. FXGUID_ProQ] = pts[i .. FXGUID_ProQ] + pts[i .. 'B-' .. Band .. FXGUID_ProQ]
                    end
                    
                end
            end
            pts[i .. FXGUID_ProQ] = pts[i .. FXGUID_ProQ]
            local X2 = x + 2
            if i ~= 1 then
                local y1 = Y_Mid - pts[(math.max(i - 2, 3)) .. FXGUID_ProQ] * (GainScale * 2)
                local y2 = Y_Mid - pts[i .. FXGUID_ProQ] * (GainScale * 2)

                im.DrawList_AddLine(Foreground, x, y1, X2, y2, 0xFFC43488, 2.5)
            end


            local Y_Mid = (ProQ_Ypos_T + ProQ3.H / 2)
            y = Y_Mid - pts[i .. FXGUID_ProQ]
            x = X2
        end



        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos50 - 3, Y_Mid + 86, 0x78787899, '50')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos100 - 5, Y_Mid + 86, 0x78787899, '100')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos200 - 5, Y_Mid + 86, 0x78787899, '200')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos500 - 5, Y_Mid + 86, 0x78787899, '500')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos1k - 5, Y_Mid + 86, 0x78787899, '1k')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos2k - 5, Y_Mid + 86, 0x78787899, '2k')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos5k - 5, Y_Mid + 86, 0x78787899, '5k')
        im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
            ProQ_Xpos_L + iPos10k - 5, Y_Mid + 86, 0x78787899, '10k')

        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos50, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos50, ProQ_Ypos_T + 300, 0x78787822)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos100, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos100, ProQ_Ypos_T + 300, 0x78787844)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos200, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos200, ProQ_Ypos_T + 300, 0x78787822)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos500, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos500, ProQ_Ypos_T + 300, 0x78787822)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos1k, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos1k, ProQ_Ypos_T + 300, 0x78787844)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos2k, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos2k, ProQ_Ypos_T + 300, 0x78787822)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos5k, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos5k, ProQ_Ypos_T + 300, 0x78787822)
        im.DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos10k, ProQ_Ypos_B,
            ProQ_Xpos_L + iPos10k, ProQ_Ypos_T + 300, 0x78787844)

        im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid, ProQ_Xpos_R, Y_Mid,
            0x78787844)

        if ProQ3['scaleLabel' .. ' ID' .. FxGUID] == 30 or ProQ3['scaleLabel' .. ' ID' .. FxGUID] == 3 then
            local Gain10 = Y_Mid + (ProQ_Ypos_T - Y_Mid) / 3
            local Gain20 = Y_Mid + ((ProQ_Ypos_T - Y_Mid) / 3) * 2
            local GainMinus10 = Y_Mid - (ProQ_Ypos_T - Y_Mid) / 3
            local GainMinus20 = Y_Mid - ((ProQ_Ypos_T - Y_Mid) / 3) * 2

            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Gain10, ProQ_Xpos_R,
                Gain10, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Gain20, ProQ_Xpos_R,
                Gain20, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, GainMinus10,
                ProQ_Xpos_R, GainMinus10, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, GainMinus20,
                ProQ_Xpos_R, GainMinus20, 0x78787822)
        elseif ProQ3['scaleLabel' .. ' ID' .. FxGUID] == 12 then
            local Gain3 = (ProQ_Ypos_T - Y_Mid) / 4
            local Gain6 = ((ProQ_Ypos_T - Y_Mid) / 4) * 2
            local Gain9 = ((ProQ_Ypos_T - Y_Mid) / 4) * 3

            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain3,
                ProQ_Xpos_R, Y_Mid + Gain3, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain6,
                ProQ_Xpos_R, Y_Mid + Gain6, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain9,
                ProQ_Xpos_R, Y_Mid + Gain9, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain3,
                ProQ_Xpos_R, Y_Mid - Gain3, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain6,
                ProQ_Xpos_R, Y_Mid - Gain6, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain9,
                ProQ_Xpos_R, Y_Mid - Gain9, 0x78787822)
        elseif ProQ3['scaleLabel' .. ' ID' .. FxGUID] == 6 then
            local Gain1 = (ProQ_Ypos_T - Y_Mid) / 6
            local Gain2 = Gain1 * 2
            local Gain3 = Gain1 * 3
            local Gain4 = Gain1 * 4
            local Gain5 = Gain1 * 5

            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain1,
                ProQ_Xpos_R, Y_Mid + Gain1, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain2,
                ProQ_Xpos_R, Y_Mid + Gain2, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain3,
                ProQ_Xpos_R, Y_Mid + Gain3, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain4,
                ProQ_Xpos_R, Y_Mid + Gain4, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain5,
                ProQ_Xpos_R, Y_Mid + Gain5, 0x78787822)


            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain1,
                ProQ_Xpos_R, Y_Mid - Gain1, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain2,
                ProQ_Xpos_R, Y_Mid - Gain2, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain3,
                ProQ_Xpos_R, Y_Mid - Gain3, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain4,
                ProQ_Xpos_R, Y_Mid - Gain4, 0x78787822)
            im.DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain5,
                ProQ_Xpos_R, Y_Mid - Gain5, 0x78787822)
        end


        ----------------------
        --Draw Nodes
        ----------------------
        NodeY_Pos = {}
        NodeHvr = {}
        NodeHasbeenHovered = nil
        MousePosX, MousePosY = im.GetMousePos(ctx)


        for Band = 1, 24, 1 do
            local gain_P_num =  ((Band - 1) * 13) + 3
            local freq_P_num =  ((Band - 1) * 13) + 2
            
            --FX[FxGUID][Gain] = FX[FxGUID][gain_P_num] or {}
            local FP_gain = FX[FxGUID][Band]
            FX[FxGUID][Band] = FX[FxGUID][Band] or {}

            
            
            --FX[FxGUID][Band].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, gain_P_num)
            if ProQ3.Band_UseState[Band] == 1 then
                NodeFreq['B-' .. Band .. 'GUID-' .. FXGUID_ProQ] = x_to_freq(Freq[Band] * ProQ3.Width)
                XposNode[Band] = freq_to_scx(NodeFreq['B-' .. Band .. 'GUID-' .. FXGUID_ProQ])_, ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,8 + 13 * (Band - 1))


                ----- Draw Modulation indicator 
                if FP_gain.WhichCC then 
                    for M, v in ipairs(MacroNums) do

                        if FP_gain.ModAMT[M] and  FP_gain.ModAMT[M] ~= 0 then 
                            local X = ProQ_Xpos_L + XposNode[Band] 

                            local gain = -30 + FP_gain.V * 60
                            local Y = Y_Mid - (gain * 3.2) * ProQ3['scale' .. ' ID' .. FxGUID];
                            local MOD = Trk[TrkID].Mod[M].Val
                            if Trk[TrkID].Mod[M].Type~='Macro' then
                                r.gmem_attach('ParamValues')
                                MOD = math.abs(SetMinMax(r.gmem_read(100 + M) / 127, -1, 1))
                            end
                            --ttp(FP_gain.ModAMT[M])

                            im.DrawList_AddLine(Foreground, X, Y , X, Y - FP_gain.ModAMT[M] * 500    , EightColors.Bright_HighSat[M] )
                            im.DrawList_AddCircleFilled(Foreground,X+0.5, Y - FP_gain.ModAMT[M] * 500   , 4, EightColors.Bright_HighSat[M])
                            im.DrawList_AddCircleFilled(Foreground,X+0.5, Y , 4, EightColors.Bright_HighSat[M])

                        end
                    end
                end





                determineBandColor(Band)
                if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Bell' then
                    NodeY_Pos[Band] = Y_Mid - (Gain[Band] * 3.2) * ProQ3['scale' .. ' ID' .. FxGUID];
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' then
                    NodeY_Pos[Band] = Y_Mid -
                        (Q_Node[Band]) * ProQ3['scale' .. ' ID' .. FxGUID]
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                    NodeY_Pos[Band] = Y_Mid -
                        (Q_Node[Band]) * ProQ3['scale' .. ' ID' .. FxGUID]
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Shelf' then
                    NodeY_Pos[Band] = Y_Mid -
                        (ShelfGain_Node) * ProQ3['scale' .. ' ID' .. FxGUID]
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Shelf' then
                    NodeY_Pos[Band] = Y_Mid -
                        (ShelfGain_Node) * ProQ3['scale' .. ' ID' .. FxGUID]
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Band Pass' then
                    NodeY_Pos[Band] = Y_Mid
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Notch' then
                    NodeY_Pos[Band] = Y_Mid
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Tilt Shelf' then
                    NodeY_Pos[Band] = Y_Mid -
                        (Gain[Band] * 1.4) *
                        ProQ3['scale' .. ' ID' .. FxGUID]
                elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Flat Tilt' then
                    NodeY_Pos[Band] = Y_Mid -(0.08 * 1.4) * ProQ3['scale' .. ' ID' .. FxGUID]
                end


                if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                    im.DrawList_AddCircleFilled(Foreground,
                        ProQ_Xpos_L + XposNode[Band], NodeY_Pos[Band], 6,
                        Clr_FullAlpha)
                else
                    im.DrawList_AddCircleFilled(Foreground,
                        ProQ_Xpos_L + (XposNode[Band] or 0), NodeY_Pos[Band] or 0, 6,
                        Clr_HalfAlpha)
                end
                if ProQ_Xpos_L and XposNode[Band] and NodeY_Pos[Band] then
                    if Band <= 9 then
                        im.DrawList_AddTextEx(Foreground,
                            Font_Andale_Mono, 12, ProQ_Xpos_L + XposNode[Band] - 2.5,
                            NodeY_Pos[Band] - 4.5, 0x000000ff, Band)
                    end
                    if Band > 9 then
                        im.DrawList_AddTextEx(Foreground,
                            Font_Andale_Mono, 10, ProQ_Xpos_L + XposNode[Band] - 5,
                            NodeY_Pos[Band] - 4, 0x000000ff, Band)
                    end
                end

                local NodeHoverArea = 10
                if MousePosX > ProQ_Xpos_L + XposNode[Band] - NodeHoverArea and MousePosX < ProQ_Xpos_L + XposNode[Band] + NodeHoverArea and MousePosY > NodeY_Pos[Band] - NodeHoverArea and MousePosY < NodeY_Pos[Band] + NodeHoverArea then
                    ProQ3['NodeHvr' .. Band .. 'FXID-' .. FxGUID] = true
                    HvringNode = Band
                else
                    ProQ3['NodeHvr' .. Band .. 'FXID-' .. FxGUID] = false
                end

                if ProQ3['NodeHvr' .. Band .. 'FXID-' .. FxGUID] == true then
                    NodeHasbeenHovered = true
                    FX_DeviceWindow_NoScroll = im.WindowFlags_NoScrollWithMouse
                    im.DrawList_AddCircle(Foreground, ProQ_Xpos_L +
                        XposNode[Band], NodeY_Pos[Band], 7.7, 0xf0f0f0ff)
                    if IsLBtnHeld then
                        im.DrawList_AddCircleFilled(Foreground,
                            ProQ_Xpos_L + XposNode[Band], NodeY_Pos[Band], 7.7,
                            Clr_HalfAlpha)
                        if IsLBtnClicked then ProQ3['NodeDrag' .. Band .. ' ID-' .. FxGUID] = true end
                    end

                    local QQ = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                        ((Band - 1) * 13) + 7)
                    if Wheel_V ~= 0 then --if wheel is moved
                        HoverOnScrollItem = true
                        MousePosX_AdjustingQ, Y = r.GetMousePosition()
                        ProQ3['AdjustingQ' .. FxGUID] = true
                        BandforQadjusting = Band
                    end
                    if IsLBtnClicked and Mods == Alt then -- delete node
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, ((Band - 1) * 13),0)
                        ProQ3['NodeHvr' .. Band .. 'FXID-' .. FxGUID] = false
                        HvringNode = nil
                    end

                    if LBtnClickCount == 2 then
                        local OnOff = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                            ((Band - 1) * 13) + 1)

                        if OnOff == 1 then
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                ((Band - 1) * 13) + 1, 0)
                        else
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                ((Band - 1) * 13) + 1, 1)
                        end
                    end
                    if IsRBtnClicked == true and Mods == Ctrl then
                        im.OpenPopup(ctx, 'Pro-Q R Click')
                    end
                    FX[FxGUID][gain_P_num] = FX[FxGUID][gain_P_num] or {}
                    AssignMod(FxGUID, Band, FX_Idx, gain_P_num, FX[FxGUID][gain_P_num].V, Sldr_Width, 'Pro-Q', 'No Item Trigger')
                
                
                
                else
                    FX_DeviceWindow_NoScroll = 0
                end




                if ProQ3['AdjustingQ' .. FxGUID] then
                    local MousePosX_AdjustingQ_CheckXpos, Y = reaper
                        .GetMousePosition()
                    if Mods == Shift then
                        WheelQFineAdj = 20
                    else
                        WheelQFineAdj = 1
                    end
                    if MousePosX_AdjustingQ_CheckXpos < MousePosX_AdjustingQ + 7 and MousePosX_AdjustingQ_CheckXpos > MousePosX_AdjustingQ - 7 then
                        local QQ = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                            ((BandforQadjusting - 1) * 13) + 7)

                        Q_Output = SetMinMax(QQ - ((Wheel_V / 50) / WheelQFineAdj), 0,1)

                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                            ((BandforQadjusting - 1) * 13) + 7, Q_Output)
                    else
                        ProQ3['AdjustingQ' .. FxGUID] = false
                    end
                end


                if ProQ3['NodeDrag' .. Band .. ' ID-' .. FxGUID] == true then
                    MouseDeltaX, MouseDeltaY = im.GetMouseDelta(ctx)
                    local Freq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,((Band - 1) * 13) + 2)
                    local Gain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, gain_P_num)
                    local Q = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, ((Band - 1) * 13) + 7)
                    ProQ3.LT_EQBand[FxGUID] = Band

                    if IsLBtnHeld == false then
                        ProQ3['NodeDrag' .. Band .. ' ID-' .. FxGUID] = false
                    end
                    -- finetune if shift is held
                    if Mods == Shift then
                        HorizDragScale = 1000
                    else
                        HorizDragScale = 400
                    end
                    if Mods == Shift then
                        QDragScale = 400
                    else
                        QDragScale = 120
                    end

                    if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' or ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                        Q_Output = Q +
                            (-MouseDeltaY / QDragScale) *
                            (ProQ3['scale' .. ' ID' .. FxGUID] / ProQ3['DragGainScale' .. ' ID' .. FxGUID])
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                            ((Band - 1) * 13) + 7, Q_Output)

                        if Freq > 1 and MouseDeltaX > 0 then
                            FreqOutput = 1
                        elseif Freq < 0 and MouseDeltaX < 0 then
                            FreqOutput = 0
                        else
                            FreqOutput = Freq + MouseDeltaX / HorizDragScale
                        end
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, ((Band - 1) * 13) + 2, FreqOutput)
                    else
                        if Gain > 1 and MouseDeltaY < 0 then
                            GainOutput = 1
                        elseif Gain < 0 and MouseDeltaY > 0 then
                            GainOutput = 0
                        else
                            GainOutput = Gain +(-MouseDeltaY / 270) *(ProQ3['scale' .. ' ID' .. FxGUID] / ProQ3['DragGainScale' .. ' ID' .. FxGUID])
                        end

                        if not FP_gain.WhichCC then
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, gain_P_num,GainOutput)
                        elseif FP_gain.WhichCC then 
                            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, LT_FXNum, "param."..gain_P_num..".plink.active", 0)   -- 1 active, 0 inactive
                            FP_gain.V = GainOutput
                            for M, v in ipairs(MacroNums) do
                                local MOD = Trk[TrkID].Mod[M].Val
                                if Trk[TrkID].Mod[M].Type~='Macro' then
                                    r.gmem_attach('ParamValues')
                                    MOD = math.abs(SetMinMax(r.gmem_read(100 + M) / 127, -1, 1))
                                    
                                end
                                if MOD~=0 and MOD then 
                                    FP_gain.V = GainOutput - FP_gain.ModAMT[M] *MOD
                                end
                            end
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, gain_P_num, FP_gain.V)
                            Tweaking = gain_P_num .. FxGUID
                        end

                        if Freq > 1 and MouseDeltaX > 0 then
                            FreqOutput = 1
                        elseif Freq < 0 and MouseDeltaX < 0 then
                            FreqOutput = 0
                        else
                            FreqOutput = Freq + MouseDeltaX / HorizDragScale
                        end

                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, ((Band - 1) * 13) + 2, FreqOutput)
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, gain_P_num, GainOutput)
                    end
                end




               




                -- if i == iPos10k then im.DrawList_AddTextEx(Foreground, Font_Andale_Mono, 12, ProQ_Xpos_L+XposNode[Band],  Y_Mid- (Gain[B]*3.2)  , 0x78787899, '10K') end
                if LT_ParamNum ~= nil then
                    local m = m;
                    _, tracknumber, fxnumber, paramnumber = r.GetLastTouchedFX()
                    proQ_LT_GUID = r.TrackFX_GetFXGUID(LT_Track, fxnumber)


                    for i = 1, RepeatTimeForWindows, 1 do
                        GUIDtoCompare = r.TrackFX_GetFXGUID(LT_Track, fxnumber)
                        if proQ_LT_GUID == GUIDtoCompare and proQ_LT_GUID ~= nil then
                            for i = 1, 24, 1 do
                                if LT_ParamNum > 13 * (i - 1) and LT_ParamNum < 13 * i then
                                    ProQ3.LT_EQBand[proQ_LT_GUID] = i
                                end
                            end
                        end
                    end
                    if ProQ3.GainDragging == true then
                        MouseDeltaX, MouseDeltaY = im.GetMouseDelta(ctx)


                        local Gain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                            ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 3)

                        if Gain > 1 and MouseDeltaY < 0 then
                            GainOutput = 1
                        elseif Gain < 0 and MouseDeltaY > 0 then
                            GainOutput = 0
                        else
                            GainOutput = Gain +
                                (-MouseDeltaY / 270) *
                                (ProQ3['scale' .. ' ID' .. FxGUID] / ProQ3['DragGainScale' .. ' ID' .. FxGUID])
                        end
                        
                        if not FP_gain.WhichCC then
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 3,GainOutput)
                        elseif FP_gain.WhichCC then 
                            local unsetcc = r.TrackFX_SetNamedConfigParm(LT_Track, LT_FXNum, "param."..gain_P_num..".plink.active", 0)   -- 1 active, 0 inactive
                            FP_gain.V = GainOutput
                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, gain_P_num, FP_gain.V)
                            Tweaking = gain_P_num .. FxGUID
                        end
                    end
                    if ProQ3.FreqDragging == true then

                        MouseDeltaX, MouseDeltaY = im.GetMouseDelta(ctx)
                        if Mods == Shift then
                            HorizDragScale = 1300
                        else
                            HorizDragScale = 400
                        end
                        local Freq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                            ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 2)

                        if Freq > 1 and MouseDeltaX > 0 then
                            FreqOutput = 1
                        elseif Freq < 0 and MouseDeltaX < 0 then
                            FreqOutput = 0
                        else
                            FreqOutput = Freq + MouseDeltaX / HorizDragScale
                        end
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                            ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 2,FreqOutput)
                    end
                end




                
                TweakingNodeGain = MakeModulationPossible(FxGUID, Band, FX_Idx, gain_P_num, FX[FxGUID][Band].V, 10, 'Pro-Q', 'No Item Trigger')

            end --end for repeat every active  band






        end     --end for repeat every band
        if NodeHasbeenHovered then HoverOnScrollItem = true end



        if im.BeginPopup(ctx, 'Pro-Q R Click') then
            local LTBand = ProQ3.LT_EQBand[FxGUID]
            if im.Button(ctx, 'Bell') then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,0)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'Low Shelf') then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                    0.11)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'Low Cut') then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                    0.22)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'High Shelf') then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                    0.33)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'High Cut') then
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                    0.44)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'Notch') then
                r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 0.60)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'Band Pass') then
                r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 0.72)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'Tilt Shelf') then
                r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 0.86)
                im.CloseCurrentPopup(ctx)
            end
            if im.Button(ctx, 'Flat Tilt') then
                r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 1)
                im.CloseCurrentPopup(ctx)
            end
            im.EndPopup(ctx)
        end


        ------------------------------------------
        --Add new node by double click
        ------------------------------------------

        if ProQ3['HvrGUI' .. FxGUID] and LBtnClickCount == 2 then
            if HvringNode == nil or ProQ3['NodeHvr' .. HvringNode .. 'FXID-' .. FxGUID] ~= true then
                UnusedBandFound = false
                local Band = 1
                while (UnusedBandFound == false) do
                    if ProQ3.Band_UseState[Band] ~= 1 then
                        UnusedBandFound = true
                        BandNotInUse = Band
                    end
                    Band = Band + 1
                end
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                    13 * (BandNotInUse - 1), 1)
                MouseX_AddNode, MouseY_AddNode = im.GetMousePos(ctx)

                local FreqToAddNode = (MouseX_AddNode - ProQ_Xpos_L) / ProQ3.Width
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                    13 * (BandNotInUse - 1) + 2, FreqToAddNode)
                local GainToAddNode = ((((Y_Mid - MouseY_AddNode) - 100) / 100 + 1) / ProQ3['scale' .. ' ID' .. FxGUID] + 1) /
                    2
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                    13 * (BandNotInUse - 1) + 3, GainToAddNode)
                if FreqToAddNode > 0.9 then
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                        13 * (BandNotInUse - 1) + 8, 0.5)
                elseif FreqToAddNode < 0.1 then
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                        13 * (BandNotInUse - 1) + 8, 0.25)
                else
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                        13 * (BandNotInUse - 1) + 8, 0.02)
                end
            end
        end

        stopp = true

        step = ProQ3.Width / 200

        im.DrawList_PathStroke(Foreground, 0x99999988, nil, 3)



        im.EndChild(ctx)
    end ---- End of if begin pro-Q frame then

    ProQ3['HvrGUI' .. FxGUID] = im.IsItemHovered(ctx)
    --if ProQ3['HvrGUI'..FxGUID] then FX_DeviceWindow_NoScroll= 0--[[ im.WindowFlags_NoScrollWithMouse ]] end

    im.PopStyleColor(ctx, 1)

    if FX.Enable[FX_Idx] == false then
        local drawlist = im.GetForegroundDrawList(ctx)
        im.DrawList_AddRectFilled(drawlist, ProQ_Xpos_L, ProQ_Ypos_T - 20,
            ProQ_Xpos_L + ProQ3.Width, ProQ_Ypos_T + ProQ3.H, 0x00000077)
    end

    if ProQ.Analyzer then   -- if it's using analyzer

        local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)
        
        if PreviousFX:find('FXD ReSpectrum') then
            r.TrackFX_Show(LT_Track, previous_fxidx, 2)
            if tablefind(Trk[TrkID].PreFX, FxGUID) then
                r.TrackFX_Delete(LT_Track,previous_fxidx)
            end

            SyncAnalyzerPinWithFX(previous_fxidx, FX_Idx, PreviousFX)
        else -- if no spectrum is before pro-Q 3

            FX[FxGUID].AddEQSpectrumWait = (FX[FxGUID].AddEQSpectrumWait or 0) + 1
            if FX[FxGUID].AddEQSpectrumWait > FX_Add_Del_WaitTime then
                local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)


                r.gmem_attach('gmemReEQ_Spectrum')
                r.gmem_write(1, PM.DIY_TrkID[TrkID])
                FX[FxGUID].ProQ_ID = FX[FxGUID].ProQ_ID or math.random(1000000, 9999999)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProQ_ID ' .. FxGUID,
                    FX[FxGUID].ProQ_ID, true)
                r.gmem_write(2, FX[FxGUID].ProQ_ID)
                local AnyPopupOpen
                if im.IsPopupOpen(ctx, 'Delete FX Layer ', im.PopupFlags_AnyPopupId + im.PopupFlags_AnyPopupLevel) then AnyPopupOpen = true end

                if not tablefind(Trk[TrkID].PostFX, FxGUID) and not tablefind(Trk[TrkID].PreFX, FxGUID) and not AnyPopupOpen then

                    r.gmem_attach('gmemReEQ_Spectrum')
                    r.gmem_write(1, PM.DIY_TrkID[TrkID])
                    FX[FxGUID].ProQ_ID = FX[FxGUID].ProQ_ID or
                        math.random(1000000, 9999999)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProQ_ID ' .. FxGUID,
                        FX[FxGUID].ProQ_ID, true)
                    r.gmem_write(2, FX[FxGUID].ProQ_ID)
                    rv = r.TrackFX_AddByName(LT_Track, 'FXD ReSpectrum', 0, -1000 - FX_Idx)
                    --[[ table.insert(AddFX.Pos, FX_Idx)
                    table.insert(AddFX.Name, 'FXD ReSpectrum') ]]
                end
                FX[FxGUID].AddEQSpectrumWait = 0
                local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(previous_fxidx)


                if FX_Idx == 0 then previous_fxidx = -1 end 
                r.TrackFX_Show(LT_Track, previous_fxidx , 2)
                for i = 0, 16, 1 do
                    --r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i,0,0)
                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, i, 0, 0)
                end
            end
        end



        r.gmem_attach('gmemReEQ_Spectrum')
        r.gmem_write(1, PM.DIY_TrkID[TrkID])
    end
    --  r.gmem_write(0, FX_Idx)
end
