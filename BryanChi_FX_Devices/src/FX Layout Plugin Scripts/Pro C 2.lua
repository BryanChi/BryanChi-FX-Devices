-- @noindex

local FX_Idx = PluginScript.FX_Idx

local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
local fx = FX[FxGUID]
local path_table = {}
if not fx then return   end
fx.Compatible_W_regular = true

fx.CustomTitle = 'Pro-C 2'
fx.TitleWidth = 100
fx.Width = fx.Width or  280
fx.ProC_GR = fx.ProC_GR or {}
fx.ProC_GR_Idx = fx.ProC_GR_Idx or 1




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



 local function Meter(PosX, PosY, Top, SpX)
    local Drawlist = im.GetWindowDrawList(ctx)
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
            im.DrawList_AddLine( Drawlist, SpX - 15, MtrB - SegL, SpX - 15, MtrB - SegL - 1, MtrClr, MtrW)
        end
        if MtrT - (20 * MtrPreR) < MtrB - SegL then
            im.DrawList_AddLine( Drawlist, SpX - 15 + MtrW + 2, MtrB - SegL, SpX - 15 + MtrW + 2, MtrB - SegL - 1, MtrClr, MtrW) end
        if MtrT - (20 * MtrPoL) < MtrB - SegL then
            im.DrawList_AddLine( Drawlist, SpX + 250, MtrB - SegL, SpX + 250, MtrB - SegL - 1, MtrClr, MtrW)
        end
        if MtrT - (20 * MtrPoR) < MtrB - SegL then
            im.DrawList_AddLine( Drawlist, SpX + 250 + MtrW + 2, MtrB - SegL, SpX + 250 + MtrW + 2, MtrB - SegL - 1, MtrClr, MtrW)
        end

        im.DrawList_AddLine(Drawlist, SpX - 15, MtrB - SegL, SpX - 15, MtrB - SegL - 1, MtrClrDim, MtrW)
        im.DrawList_AddLine(Drawlist, SpX - 15 + MtrW + 2, MtrB - SegL, SpX - 15 + MtrW + 2, MtrB - SegL - 1, MtrClrDim, MtrW)
        im.DrawList_AddLine(Drawlist, SpX + 250, MtrB - SegL, SpX + 250, MtrB - SegL - 1, MtrClrDim, MtrW)
        im.DrawList_AddLine(Drawlist, SpX + 250 + MtrW + 2, MtrB - SegL, SpX + 250 + MtrW + 2, MtrB - SegL - 1, MtrClrDim, MtrW)
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
        im.DrawList_AddRectFilled(Drawlist, SpX - 16, MtrT - 2, SpX - 13, MtrT + 3, 0xf20000ff)
    end
    if PreRPeak then
        im.DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW + 2, MtrT - 2, SpX + 250 + MtrW + 5, MtrT + 3, 0xf20000ff)
    end
    if PoLPeak then
        im.DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW * 3 + 12, MtrT - 2, SpX + 250 + MtrW * 3 + 15, MtrT + 3, 0xf20000ff)
    end
    if PoRPeak then
        im.DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW * 4 + 14, MtrT - 2, SpX + 250 + MtrW * 4 + 17, MtrT + 3, 0xf20000ff)
    end



    if PreLPeak or PreRPeak or PoLPeak or PoRPeak then
        if r.GetPlayState() == 0 then StoppedPlyaing = true end
        if StoppedPlyaing and r.GetPlayState() ~= 0 then
            PreLPeak = nil; PreRPeak = nil; PoLPeak = nil; PoRPeak = nil; StoppedPlyaing = nil;
        end
    end
    -------- End of Meter
end


---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------









---------------------------------------------
---------Body--------------------------------
---------------------------------------------










local FXname = select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx))


local lastFXName = select(2, r.TrackFX_GetFXName(LT_Track, FX_Idx-1))





if not fx.Collapse then

    

    Rounding = 3

    IIS = 2
    r.gmem_attach('CompReductionScope')
    im.SetCursorPos(ctx, 30, 35)
    local SpX, SpY = im.GetCursorScreenPos(ctx)
    local ThreshX, ThreshY = im.GetCursorPos(ctx)
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
    im.SetNextItemWidth(ctx, 45)
    im.SetCursorPos(ctx, 90, 0)
   
    if im.BeginCombo(ctx, '##' .. 'Histogram Scale', ScaleLbl, im.ComboFlags_NoArrowButton) then
        im.PushStyleColor(ctx, im.Col_Header, 0x44444433)
        local AccentClr = im.GetColor(ctx, im.Col_SliderGrabActive)
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
        Lookahead = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 41)
    end



    MousePosX, MousePosY = im.GetMousePos(ctx)

    if ProC.GR_NATIVE then 
            
        local  rv, GR = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "GainReduction_dB");
        if rv then 
            local GR_UI = Top+50 - GR / (Sel_Scale *3 ) * 100 
            local GR_Pts = GR / (Sel_Scale *3 ) * 100 
            -- Store GR value into table 
            local TB = fx.ProC_GR
            if fx.ProC_GR_Idx  > 180 then fx.ProC_GR_Idx  = 1  end 
            local Idx = fx.ProC_GR_Idx 
            TB[Idx] = GR_UI
                

            fx.ProC_GR_Idx  = fx.ProC_GR_Idx  + 1 

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
        im.DrawList_AddRectFilled(Drawlist, SpX, Top, SpX + 180, Top + 100, 0x88888810, nil)
        local AnyActive = im.IsAnyItemActive(ctx)

        if IsLBtnClicked and AnyActive == false and not ProC.ChoosingStyle then
            im.DrawList_AddRectFilled(Drawlist, SpX, Top, SpX + 180, Top + 100, 0x88888866, nil)
            ShowDpRange = true
            TimeNow = r.time_precise()
            Sel_Scale = math.max(Sel_Scale - 1, 1)
        end
        if IsRBtnClicked then
            im.DrawList_AddRectFilled(Drawlist, SpX, Top, SpX + 180, Top + 100, 0x88888866, nil)
            ShowDpRange = true
            TimeNow = r.time_precise()
            Sel_Scale = math.min(Sel_Scale + 1, 3)
        end


        if Wheel_V ~= 0 then
            HoverOnScrollItem = true
            im.SetScrollX(ctx, 0)
            local OV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx + 1, 0)
            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx + 1, 0, OV + Wheel_V / 50)
            TimeNow = r.time_precise()
            fx.ShowMsecRange = true
            fx.MsecRange = tonumber(select(2,
                r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx + 1, 0)))
            if fx.MsecRange then
                if fx.MsecRange > 999 then
                    fx.MsecRange = round((fx.MsecRange / 1000), 2) .. 's'
                else
                    fx.MsecRange = math.floor(fx.MsecRange) .. 'ms'
                end
            end
        end
    end
    if ShowDpRange then
        TimeAfter = r.time_precise()
        if TimeAfter < TimeNow + 0.5 then
            im.DrawList_AddTextEx(Drawlist, Font_Andale_Mono_20_B, 20, SpX + 90, Top + 40, 0xffffffff, '±' .. Sel_Scale * 3)
        else
            ShowDpRange = false
        end
    elseif fx.ShowMsecRange then
        TimeAfter = r.time_precise()
        if TimeAfter < TimeNow + 0.5 then
            im.DrawList_AddTextEx(Drawlist, Font_Andale_Mono_20_B, 20, SpX + 70, Top + 40, 0xffffffff, fx.MsecRange)
        else
            fx.ShowMsecRange = false
        end
    end


    -- Draw Grid
    im.DrawList_AddLine(Drawlist, SpX, Top + 95, SpX + 180, Top + 95, 0x99999955, 1) --- -3dB
    im.DrawList_AddText(Drawlist, SpX + 185, Top + 90, 0x999999bb, '-' .. 3 * Sel_Scale)
    im.DrawList_AddLine(Drawlist, SpX, Top + 72, SpX + 180, Top + 72, 0x99999933, 1) --- -1.5dB
    im.DrawList_AddText(Drawlist, SpX + 185, Top + 70, 0x999999aa, '-' .. 1.5 * Sel_Scale)

    im.DrawList_AddLine(Drawlist, SpX, Top + 50, SpX + 180, Top + 50, 0x99999955, 1) --- 0dB
    im.DrawList_AddText(Drawlist, SpX + 185, Top + 45, 0x999999bb, ' 0')
    im.DrawList_AddLine(Drawlist, SpX, Top + 27, SpX + 180, Top + 27, 0x99999933, 1) --- -1.5dB
    im.DrawList_AddText(Drawlist, SpX + 185, Top + 20, 0x999999aa, '+' .. 1.5 * Sel_Scale)

    im.DrawList_AddLine(Drawlist, SpX, Top + 4, SpX + 180, Top + 4, 0x99999955, 1) --- +3dB
    im.DrawList_AddText(Drawlist, SpX + 185, Top - 5, 0x999999bb, '+' .. 3 * Sel_Scale)

    -- im.DrawList_PathStroke(Drawlist,0xFF8181cc)


    im.SameLine(ctx)




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
                fx = fx or {}
                fx.ProC_ID =  math.random(1000000, 9999999 )
                r.gmem_attach('CompReductionScope')
                r.gmem_write(2002, fx.ProC_ID)
                r.gmem_write(fx.ProC_ID, FX_Idx)
                r.gmem_write(2000, PM.DIY_TrkID[TrkID])
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID '..FxGUID, fx.ProC_ID, true)
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

