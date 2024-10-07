-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = FxGUID
local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
local path_table = {}



FX[FxGUID].CustomTitle = 'Pro-C 2'
FX[FxGUID].TitleWidth = 100
FX[FxGUID].Width = 280
FX[FxGUID].ProC_GR = FX[FxGUID].ProC_GR or {}
FX[FxGUID].ProC_GR_Idx = FX[FxGUID].ProC_GR_Idx or 1




--[[ local function Enclose_with_Container(fxid)
    local container_id = r.TrackFX_AddByName(LT_Track, 'Container', false, fxid )
    local target_pos =  TrackFX_GetInsertPositionInContainer(container_id, 1)
    local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(container_id)
    local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(previous_fxidx)
    MoveFX(previous_fxidx, target_pos)
    local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(previous_fxidx)

    MoveFX(next_fxidx, target_pos)

    r.TrackFX_SetNamedConfigParm(LT_Track, container_id, 'renamed_name', 'Pro-C 2')

    --r.TrackFX_CopyToTrack(LT_Track, previous_fxidx, LT_Track, target_pos,true )

end 
 ]]



---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------



Rounding = 3
im.PushStyleVar(ctx, im.StyleVar_FrameRounding, Rounding)
if not FX[FxGUID].Collapse then
    if not OverSampleValue then
        _, OverSampleValue = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 40)
    end
    im.SetNextItemWidth(ctx, 10)
    im.PushFont(ctx, Font_Andale_Mono_10)
    MyText('Over:', nil, 0x818181ff)


    im.SameLine(ctx, 210, nil)
    im.SetNextItemWidth(ctx, 27)
    local Oversampling_Options = { 'Off', '2x', '4x' }
    local OS_V = { 0, 0.5, 1 }
    AddCombo(ctx, LT_Track, FX_Idx, 'OverSample##', 40, Oversampling_Options, 18,'Pro C 2', FxGUID, Fx_P or 1, OS_V)
    --im.SameLine(ctx)
    --AddDrag(ctx,'##'..12,  Trk.Prm.V[F_Tp(12,FxGUID)..TrkID] or '', Trk.Prm.V[F_Tp(12,FxGUID)..TrkID] or 0, 0, 1, 12,FX_Idx, 34, 'style', 10)

    im.PopFont(ctx)
    im.SameLine(ctx, ProC.Width - 25)

    SyncWetValues()
    Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '',
        Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)
end
im.PopStyleVar(ctx)





---------------------------------------------
---------Body--------------------------------
---------------------------------------------










local FXname = select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))


local lastFXName = select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx-1))





if not FX[FxGUID].Collapse then
    if Prm.InstAdded[FxGUID] ~= true and FXname:find('Pro%-C 2') then
        --- number in green represents FX Prm Index
        StoreNewParam(FxGUID, 'Knee', 3, FX_Idx, false, 'AddingFromExtState',
            1, FX_Idx)                       --1. Knee
        StoreNewParam(FxGUID, 'Range', 4, FX_Idx, false, 'AddingFromExtState',
            2, FX_Idx)                       --2. Range
        StoreNewParam(FxGUID, 'Lookahead', 8, FX_Idx, false,
            'AddingFromExtState', 3, FX_Idx) --3. Lookahead
        StoreNewParam(FxGUID, 'Hold', 9, FX_Idx, false, 'AddingFromExtState',
            4, FX_Idx)                       --4. Hold

        StoreNewParam(FxGUID, 'Ratio', 2, FX_Idx, false, 'AddingFromExtState',
            5, FX_Idx)                       --5. Ratio
        StoreNewParam(FxGUID, 'Attack', 5, FX_Idx, false,
            'AddingFromExtState', 6, FX_Idx) --6. Attack
        StoreNewParam(FxGUID, 'Release', 6, FX_Idx, false,
            'AddingFromExtState', 7, FX_Idx) --7. release

        StoreNewParam(FxGUID, 'Gain', 10, FX_Idx, false, 'AddingFromExtState',
            8, FX_Idx)                        --8. Gain
        StoreNewParam(FxGUID, 'Dry', 12, FX_Idx, false, 'AddingFromExtState',
            9, FX_Idx)                        --9. Dry Gain
        StoreNewParam(FxGUID, 'Thresh', 1, FX_Idx, false,
            'AddingFromExtState', 10, FX_Idx) -- 10. Thresh

        StoreNewParam(FxGUID, 'Mix', 34, FX_Idx, false, 'AddingFromExtState',
            11, FX_Idx)                       -- 11. Mix
        StoreNewParam(FxGUID, 'Input Gain', 35, FX_Idx, false,
            'AddingFromExtState', 12, FX_Idx) -- 12. Input Gain
        StoreNewParam(FxGUID, 'Output Gain', 37, FX_Idx, false,
            'AddingFromExtState', 13, FX_Idx) -- 13. Output Gain



        Prm.InstAdded[FxGUID] = true
        r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added',
            'true')
    end
    function F_Tp(FX_P)
        return FX.Prm.ToTrkPrm[FxGUID .. FX_P]
    end

    if FX[FxGUID][1].Num and FX[FxGUID][8] then
        im.Indent(ctx, 20)

        Rounding = 3
        im.PushStyleVar(ctx, im.StyleVar_FrameRounding, Rounding)
        im.PushStyleVar(ctx, im.StyleVar_GrabMinSize, 0)
        im.PushFont(ctx, Font_Andale_Mono_10)
        IIS = 2
        r.gmem_attach('CompReductionScope')
        local SpX, SpY = im.GetCursorScreenPos(ctx)
        local Top = SpY - 9; local C = Top + 50; local B = Top + 100

        local Drawlist = im.GetWindowDrawList(ctx)
        DspScale = { 2, 4, 6 }; --2=3dB, 4=6dB, 6=9dB, 8=12dB
        --
        if Sel_Scale == 1 then
            ScaleLbl = '± 3dB'
        elseif Sel_Scale == 2 then
            ScaleLbl = '± 6dB'
        elseif Sel_Scale == 3 then
            ScaleLbl = '± 9dB'
        end

        im.PushStyleColor(ctx, im.Col_FrameBg, 0x444444ff)
        im.PushStyleColor(ctx, im.Col_Text, 0xffffffff)
        im.SetNextItemWidth(ctx, 30)
        if im.BeginCombo(ctx, '##' .. tostring(Label), ScaleLbl, im.ComboFlags_NoArrowButton) then
            im.PushStyleColor(ctx, im.Col_Header, 0x44444433)
            local AccentClr = im.GetColor(ctx,
                im.Col_SliderGrabActive)
            im.PushStyleColor(ctx, im.Col_HeaderHovered, AccentClr)
            im.PushStyleColor(ctx, im.Col_Text, 0xbbbbbbff)


            if im.Selectable(ctx, '± 3dB', i) then
                Sel_Scale = 1
            end
            if im.Selectable(ctx, '± 6dB', i) then
                Sel_Scale = 2
            end
            if im.Selectable(ctx, '± 9dB', i) then
                Sel_Scale = 3
            end



            im.PopStyleColor(ctx, 3)

            ScaleActive = true
            im.EndCombo(ctx)
            local L, T = im.GetItemRectMin(ctx); local R, B = r
                .ImGui_GetItemRectMax(ctx)
            local lineheight = im.GetTextLineHeight(ctx)
            local drawlist = im.GetForegroundDrawList(ctx)

            im.DrawList_AddRectFilled(drawlist, L, T + lineheight / 8, R,
                B - lineheight / 8, 0x88888844, Rounding)
            im.DrawList_AddRect(drawlist, L, T + lineheight / 8, R,
                B - lineheight / 8, 0x88888877, Rounding)
        else
            ScaleActive = nil
        end
        im.PopStyleColor(ctx, 2)
        local HvrOnScale = im.IsItemHovered(ctx)

        if not Sel_Scale then Sel_Scale = 3 end

        if LT_ParamNum == 41 then
            Lookahead = r.TrackFX_GetParamNormalized(LT_Track,
                FX_Idx, 41)
        end



        MousePosX, MousePosY = im.GetMousePos(ctx)

        if ProC.GR_NATIVE then 
                
            local  rv, GR = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "GainReduction_dB");
            if rv then 
                local GR_UI = Top+50 - GR / (Sel_Scale *3 ) * 100 
                local GR_Pts = GR / (Sel_Scale *3 ) * 100 
                -- Store GR value into table 
                local TB = FX[FxGUID].ProC_GR
                if FX[FxGUID].ProC_GR_Idx  > 180 then FX[FxGUID].ProC_GR_Idx  = 1  end 
                local Idx = FX[FxGUID].ProC_GR_Idx 
                TB[Idx] = GR_UI
                    

                FX[FxGUID].ProC_GR_Idx  = FX[FxGUID].ProC_GR_Idx  + 1 

                for i = 1, 180, 1 do -- do once for each pixel
                    if TB[i] and TB[i-1] then 
                        im.DrawList_AddLine(Drawlist, SpX + i, SetMinMax(TB[i], Top, B), SpX + i + 1, SetMinMax(TB[i-1], Top, B), 0xFF8181cc, 2)
                        if B - TB[i] + (Top+50) <= Top or B - TB[i] + (Top+50) >= B then
                            im.DrawList_AddLine(Drawlist, SpX + i, B, SpX + i + 1, B, 0xff4517cc, 2)
                        end
                    end
                end
            end
        else 
            ---Gain Reduction Spectrum------
            for i = 1, 180, 1 do -- do once for each pixel
                local Clr = 0xFF8181cc
                ProC.Pt.L.m[i] = r.gmem_read(i)
                ProC.Pt.L.M[i] = r.gmem_read(i + 200 + 10000 * FX_Idx)

                ProC.Pt.L.M[i + 1] = r.gmem_read(i + 201 + 10000 * FX_Idx)
                local Min = ProC.Pt.L.m[i]
                local Max = (ProC.Pt.L.M[i] - 347) / DspScale[Sel_Scale] + 50
                local MaxNext = (ProC.Pt.L.M[i + 1] - 347) / DspScale[Sel_Scale] + 50




                im.DrawList_AddLine(Drawlist, SpX + i, SetMinMax(B- Max, Top, B), SpX + i + 1, SetMinMax(B-MaxNext, Top, B), 0xFF8181cc, 2)
                if B - Max <= Top or B - Max >= B then
                    im.DrawList_AddLine(Drawlist, SpX + i, math.min(math.max(B - Max, Top), B), SpX + i + 1, math.min(math.max(B - MaxNext, Top), B), 0xff4517cc, 2)
                end

            end

        end 

 
        im.SameLine(ctx)

        




        

        -- Change Display scale if mouseclick on spectrum

        MouseX, MouseY = im.GetMousePos(ctx)

        if MouseX > SpX and MouseX < SpX + 180 and MouseY > Top and MouseY < Top + 100 and not HvrOnScale and not ScaleActive then
            im.DrawList_AddRectFilled(Drawlist, SpX, Top, SpX + 180, Top + 100,
                0x88888810, nil)
            local AnyActive = im.IsAnyItemActive(ctx)

            if IsLBtnClicked and AnyActive == false and not ProC.ChoosingStyle then
                im.DrawList_AddRectFilled(Drawlist, SpX, Top, SpX + 180, Top +
                    100, 0x88888866, nil)
                ShowDpRange = true
                TimeNow = r.time_precise()
                Sel_Scale = math.max(Sel_Scale - 1, 1)
            end
            if IsRBtnClicked then
                im.DrawList_AddRectFilled(Drawlist, SpX, Top, SpX + 180, Top +
                    100, 0x88888866, nil)
                ShowDpRange = true
                TimeNow = r.time_precise()
                Sel_Scale = math.min(Sel_Scale + 1, 3)
            end


            if Wheel_V ~= 0 then
                HoverOnScrollItem = true
                im.SetScrollX(ctx, 0)
                local OV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx + 1, 0)
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx + 1, 0, OV + Wheel_V /
                    50)
                TimeNow = r.time_precise()
                FX[FxGUID].ShowMsecRange = true
                FX[FxGUID].MsecRange = tonumber(select(2,
                    r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx + 1, 0)))
                if FX[FxGUID].MsecRange then
                    if FX[FxGUID].MsecRange > 999 then
                        FX[FxGUID].MsecRange = round((FX[FxGUID].MsecRange / 1000), 2) ..
                            's'
                    else
                        FX[FxGUID].MsecRange = math.floor(FX[FxGUID].MsecRange) ..
                            'ms'
                    end
                end
            end
        end
        if ShowDpRange then
            TimeAfter = r.time_precise()
            if TimeAfter < TimeNow + 0.5 then
                im.DrawList_AddTextEx(Drawlist, Font_Andale_Mono_20_B, 20,
                    SpX + 90, Top + 40, 0xffffffff, '±' .. Sel_Scale * 3)
            else
                ShowDpRange = false
            end
        elseif FX[FxGUID].ShowMsecRange then
            TimeAfter = r.time_precise()
            if TimeAfter < TimeNow + 0.5 then
                im.DrawList_AddTextEx(Drawlist, Font_Andale_Mono_20_B, 20,
                    SpX + 70, Top + 40, 0xffffffff, FX[FxGUID].MsecRange)
            else
                FX[FxGUID].ShowMsecRange = false
            end
        end


        -- Draw Grid
        im.DrawList_AddLine(Drawlist, SpX, Top + 95, SpX + 180, Top + 95,
            0x99999955, 1) --- -3dB
        im.DrawList_AddText(Drawlist, SpX + 185, Top + 90, 0x999999bb,
            '-' .. 3 * Sel_Scale)
        im.DrawList_AddLine(Drawlist, SpX, Top + 72, SpX + 180, Top + 72,
            0x99999933, 1) --- -1.5dB
        im.DrawList_AddText(Drawlist, SpX + 185, Top + 70, 0x999999aa,
            '-' .. 1.5 * Sel_Scale)

        im.DrawList_AddLine(Drawlist, SpX, Top + 50, SpX + 180, Top + 50,
            0x99999955, 1) --- 0dB
        im.DrawList_AddText(Drawlist, SpX + 185, Top + 45, 0x999999bb, ' 0')

        im.DrawList_AddLine(Drawlist, SpX, Top + 27, SpX + 180, Top + 27,
            0x99999933, 1) --- -1.5dB
        im.DrawList_AddText(Drawlist, SpX + 185, Top + 20, 0x999999aa,
            '+' .. 1.5 * Sel_Scale)

        im.DrawList_AddLine(Drawlist, SpX, Top + 4, SpX + 180, Top + 4,
            0x99999955, 1) --- +3dB
        im.DrawList_AddText(Drawlist, SpX + 185, Top - 5, 0x999999bb,
            '+' .. 3 * Sel_Scale)

        -- im.DrawList_PathStroke(Drawlist,0xFF8181cc)


        im.SameLine(ctx)



        local Fx_P = 1
        --for i=1, 13, 1 do FX[FxGUID][i]=FX[FxGUID][i] or {} end


        im.Indent(ctx, 210)
        AddKnob(ctx, '##Gain', 'Gain', FX[FxGUID][8].V or 0, 0, 1, 8, FX_Idx, 10,
            'Pro C', 15, IIS, Disabled, LblTextSize, 'Bottom')
        AddKnob(ctx, '##Dry', 'Dry', FX[FxGUID][9].V or 0, 0, 1, 9, FX_Idx, 12,
            'Pro C', 15, IIS, Disabled, LblTextSize, 'Bottom')
        local OrigPosX, OrigPosY = im.GetCursorPos(ctx)
        im.SetCursorScreenPos(ctx, SpX - 20, Top + 20)
        AddSlider(ctx, '##Threshold', ' ', FX[FxGUID][10].V or 0, 0, 1, 10, FX_Idx, 1,
            'Pro C Thresh', 18, IIS, nil, 'Vert', 4, nil, nil, 180)
        im.SetCursorPos(ctx, OrigPosX, OrigPosY)

        ---Meter on the right-----
        r.gmem_attach('CompReductionScope')

        local MtrPreL = r.gmem_read(1002); if not MtrPreL then MtrPreL = 0 end
        local MtrPreR = r.gmem_read(1003); if not MtrPreR then MtrPreR = 0 end
        local MtrPoL = r.gmem_read(1001); if not MtrPoL then MtrPoL = 0 end
        local MtrPoR = r.gmem_read(1000); if not MtrPoR then MtrPoR = 0 end
        local MtrB = Top + 190; local MtrT = Top + 20
        local SegL = 0 * ((MtrB - MtrT) / 30)
        local MtrW = 5;

        --im.DrawList_AddRectFilled(Drawlist, SpX+249, MtrT, SpX+267, MtrB , 0x55555544)

        local HowManySeg = 63
        for i = 0, HowManySeg, 1 do --do once for every pixel so you can get different color
            local SegL = i * ((MtrB - MtrT) / HowManySeg); local Clr

            local RR, GG, BB = im.ColorConvertHSVtoRGB(0.4 - (0.3 / HowManySeg) * i, 0.6, 0.5)
            local MtrClr = im.ColorConvertDouble4ToU32(RR, GG, BB, 1)
            local MtrClrDim = im.ColorConvertDouble4ToU32(RR, GG, BB, 0.4)

            if MtrT - (20 * MtrPreL) < MtrB - SegL then
                im.DrawList_AddLine(
                    Drawlist, SpX - 15, MtrB - SegL, SpX - 15, MtrB - SegL - 1,
                    MtrClr,
                    MtrW)
            end
            if MtrT - (20 * MtrPreR) < MtrB - SegL then
                im.DrawList_AddLine(
                    Drawlist, SpX - 15 + MtrW + 2, MtrB - SegL, SpX - 15 + MtrW + 2,
                    MtrB - SegL - 1, MtrClr, MtrW)
            end
            if MtrT - (20 * MtrPoL) < MtrB - SegL then
                im.DrawList_AddLine(
                    Drawlist, SpX + 250, MtrB - SegL, SpX + 250, MtrB - SegL - 1,
                    MtrClr,
                    MtrW)
            end
            if MtrT - (20 * MtrPoR) < MtrB - SegL then
                im.DrawList_AddLine(
                    Drawlist, SpX + 250 + MtrW + 2, MtrB - SegL, SpX + 250 + MtrW + 2,
                    MtrB - SegL - 1, MtrClr, MtrW)
            end

            im.DrawList_AddLine(Drawlist, SpX - 15, MtrB - SegL, SpX - 15,
                MtrB - SegL - 1, MtrClrDim, MtrW)
            im.DrawList_AddLine(Drawlist, SpX - 15 + MtrW + 2, MtrB - SegL,
                SpX - 15 + MtrW + 2, MtrB - SegL - 1, MtrClrDim, MtrW)
            im.DrawList_AddLine(Drawlist, SpX + 250, MtrB - SegL, SpX + 250,
                MtrB - SegL - 1, MtrClrDim, MtrW)
            im.DrawList_AddLine(Drawlist, SpX + 250 + MtrW + 2, MtrB - SegL,
                SpX + 250 + MtrW + 2, MtrB - SegL - 1, MtrClrDim, MtrW)
        end

        if MtrPreL > 0 then
            PreLPeak = true; PlayStateWhenPeak = r.GetPlayState()
        end
        if MtrPreR > 0 then
            PreRPeak = true; PlayStateWhenPeak = r.GetPlayState()
        end
        if MtrPoL > 0 then
            PoLPeak = true; PlayStateWhenPeak = r.GetPlayState()
        end
        if MtrPoR > 0 then
            PoRPeak = true; PlayStateWhenPeak = r.GetPlayState()
        end

        if PreLPeak then
            im.DrawList_AddRectFilled(Drawlist, SpX - 16, MtrT - 2,
                SpX - 13, MtrT + 3, 0xf20000ff)
        end
        if PreRPeak then
            im.DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW +
                2, MtrT - 2, SpX + 250 + MtrW + 5, MtrT + 3, 0xf20000ff)
        end
        if PoLPeak then
            im.DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW * 3 +
                12, MtrT - 2, SpX + 250 + MtrW * 3 + 15, MtrT + 3, 0xf20000ff)
        end
        if PoRPeak then
            im.DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW * 4 +
                14, MtrT - 2, SpX + 250 + MtrW * 4 + 17, MtrT + 3, 0xf20000ff)
        end



        if PreLPeak or PreRPeak or PoLPeak or PoRPeak then
            if r.GetPlayState() == 0 then StoppedPlyaing = true end
            if StoppedPlyaing and r.GetPlayState() ~= 0 then
                PreLPeak = nil; PreRPeak = nil; PoLPeak = nil; PoRPeak = nil; StoppedPlyaing = nil;
            end
        end
        -------- End of Meter





        im.Unindent(ctx, 210)
        im.Indent(ctx, 5)


        AddKnob(ctx, '##Ratio', 'RATIO', FX[FxGUID][5].V or 0, 0, 1, 5, FX_Idx, 2,
            'Pro C', 20, IIS, 'Pro C Ratio Disabled', LblTextSize, 'Bottom')
        local KneePosX, KneePosY = im.GetCursorPos(ctx)

        im.SameLine(ctx)
        local X, Y = im.GetCursorPos(ctx)

        StyleOptions = { 'Clean', 'Classic', 'Opto', 'Vocal', 'Master', 'Bus',
            'Punch', 'Pump' }
        im.SetCursorPos(ctx, X + 25, Y + 15)

        AddCombo(ctx, LT_Track, FX_Idx, 'CompStyle##', 0, StyleOptions, 40, 'Pro C 2',
            FxGUID, Fx_P)
        im.SetCursorPos(ctx, X + 25, Y + 35)

        MyText('STYLE', nil, 0xbbbbbbff)


        im.SetCursorPos(ctx, X + 90, Y)


        AddKnob(ctx, 'Attack##Attack', 'Attack', FX[FxGUID][6].V or 0, 0, 1, 6,
            FX_Idx, 5, 'Pro C', 20, IIS, Disabled, LblTextSize, 'Bottom')


        im.SetCursorPos(ctx, X + 145, Y)
        AddKnob(ctx, '##Release', 'Release', FX[FxGUID][7].V or 0, 0, 1, 7, FX_Idx, 6,
            'Pro C', 20, IIS, Disabled, 2, 'Bottom')



        im.SetCursorPos(ctx, KneePosX - 3, KneePosY + 4)
        for Fx_p = 1, 4, 1 do
            im.SetCursorPosY(ctx, KneePosY + 4)
            local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_p]
            local P_Num = FX[FxGUID][Fx_p].Num
            SliderStyle = 'Pro C'
            if FX[FxGUID][Fx_P].V == nil then
                FX[FxGUID][Fx_P].V = r
                    .TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
            end

            if P_Num == 8 then
                if Lookahead == 0 then
                    AddDrag(ctx, '##' .. Fx_p, FX[FxGUID][3].Name,
                        FX[FxGUID][Fx_p].V or 0, 0, 1, Fx_p, FX_Idx, P_Num,
                        'Pro C Lookahead', (ProC.Width - 60) / 4, IIS, 'Disabled',
                        'Lbl_Clickable')
                else
                    AddDrag(ctx, '##' .. Fx_p, FX[FxGUID][3].Name,
                        FX[FxGUID][Fx_p].V or 0, 0, 1, Fx_p, FX_Idx, P_Num,
                        'Pro C Lookahead', (ProC.Width - 60) / 4, IIS, nil,
                        'Lbl_Clickable')
                end
            else
                AddDrag(ctx, '##' .. Fx_p, FX[FxGUID][Fx_p].Name,
                    FX[FxGUID][Fx_p].V or 0, 0, 1, Fx_p, FX_Idx, P_Num, 'Pro C',
                    (ProC.Width - 60) / 4, IIS, nil)
                --im.SameLine(ctx)
            end
            im.SameLine(ctx)
        end
        im.PopFont(ctx)
        im.PopStyleVar(ctx, 2)

        if not ProC.GR_NATIVE then 
            local lastFXname
            local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)
           --[[if FX_Idx > 0x2000000 then 
                local lastfx =  GetLastFXid_in_Container(FX_Idx)
                if lastfx then 
                    lastFXName = select(2, r.TrackFX_GetFXName(LT_Track, GetLastFXid_in_Container(FX_Idx)))
                end
            else 
                lastFXName = select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx-1))
            end 

            -- r.TrackFX_Show( LT_Track, FX_Idx-1, 2 ) --hide fx window

            local _, NextFX = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
            local NextFX_id = FX_Idx + 1
            if FX_Idx > 0x2000000 then -- if in container 
                local next, this, parent_cont, cont_fx_count = GetNextFXid_in_Container(FX_Idx)
                if not next then NextFX = 'no next fx' 
                else r.TrackFX_GetFXName(LT_Track, next)
                end 
               
                NextFX_id =  -1000 - FX_Id
            end ]]--

            if not NextFX:find('JS: FXD Gain Reduction Scope') and not tablefind(Trk[TrkID].PreFX, FxGUID) and not tablefind(Trk[TrkID].PostFX, FxGUID) then -- insert next FX first because inserting previous FX changes FX_Idx (Pro-C) and the next FX id
                table.insert(AddFX.Pos, next_fxidx)
                table.insert(AddFX.Name, 'FXD Gain Reduction Scope')
                ProC.GainSc_FXGUID = FxGUID
                if path_table[#path_table] then
                    path_table[#path_table] = path_table[#path_table] + 1
                end

                function WriteGmemToGainReductionScope(FxGUID)

                end

                if not GainReductionWait then GainReductionWait = 0 end
                GainReductionWait = GainReductionWait + 1
                --[[ if GainReductionWait> FX_Add_Del_WaitTime then
                    FX[FxGUID] = FX[FxGUID] or {}
                    FX[FxGUID].ProC_ID =  math.random(1000000, 9999999 )
                    r.gmem_attach('CompReductionScope')
                    r.gmem_write(2002, FX[FxGUID].ProC_ID)
                    r.gmem_write(FX[FxGUID].ProC_ID, FX_Idx)
                    r.gmem_write(2000, PM.DIY_TrkID[TrkID])
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID '..FxGUID, FX[FxGUID].ProC_ID, true)
                    AddFX_HideWindow(LT_Track,'FXD Gain Reduction Scope.jsfx',-1000-FX_Idx-1)

                    GainReductionWait = nil
                end ]]
            else
                r.TrackFX_Show(LT_Track, FX_Idx + 1, 2)
                SyncAnalyzerPinWithFX(FX_Idx + 1, FX_Idx)
            end

            if not PreviousFX:find('JS: FXD Split to 4 channels') and not tablefind(Trk[TrkID].PreFX, FxGUID) and not tablefind(Trk[TrkID].PostFX, FxGUID) then
                table.insert(AddFX.Pos, FX_Idx)
                table.insert(AddFX.Name, 'FXD Split to 4 channels')
                if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 4 then
                    rv = r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 4)
                end
            else
                r.TrackFX_Show(LT_Track, FX_Idx - 1, 2)
            end


            --[[ if PreviousFX:find('JS: FXD Split to 4 channels') and NextFX:find('JS: FXD Gain Reduction Scope') then 
                if not Cont_Added then 
                    Enclose_with_Container(next_fxidx)
                    Cont_Added = true 
                end 

            end 
            ]]


            
            r.gmem_attach('CompReductionScope'); r.gmem_write(2000, PM.DIY_TrkID[TrkID])

        end
    end
end
