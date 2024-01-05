local GF = require("src.Functions.General Functions")
local state_helpers = require('src.helpers.state_helpers')
local gui_helpers = require("src.Components.Gui_Helpers")
local fs_utils = require("src.Functions.Filesystem_utils")
local math_helpers = require("src.helpers.math_helpers")
local table_helpers = require("src.helpers.table_helpers")
local MacrosTable = {}


function MacrosTable.DisplayMacrosTable()
    r.ImGui_BeginTable(ctx, 'table1', 16, r.ImGui_TableFlags_NoPadInnerX())

    FxdCtx.Trk[TrkID] = FxdCtx.Trk[TrkID] or {}
    FxdCtx.Trk[TrkID].Mod = FxdCtx.Trk[TrkID].Mod or {}
    for m = 1, 16, 1 do
        if m == 1 or m == 3 or m == 5 or m == 7 or m == 9 or m == 11 or m == 13 or m == 15 then
            r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch(), 2)
        elseif m == 2 or m == 4 or m == 6 or m == 8 or m == 10 or m == 12 or m == 14 or m == 16 then
            local weight, flag
            if FxdCtx.Trk[TrkID].Mod[m / 2] then
                if FxdCtx.Trk[TrkID].Mod[m / 2].Type == 'Step' then
                    weight, flag = 0,
                        r.ImGui_TableColumnFlags_WidthFixed()
                end
            end
            r.ImGui_TableSetupColumn(ctx, '', flag or r.ImGui_TableColumnFlags_WidthStretch(), weight or 1)
        end
    end

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0x373737ff)

    r.ImGui_TableHeadersRow(ctx) --create header row
    r.gmem_attach('ParamValues')

    FxdCtx.Trk[TrkID] = FxdCtx.Trk[TrkID] or {}
    FxdCtx.Trk[TrkID].Mod = FxdCtx.Trk[TrkID].Mod or {}







    for i, v in ipairs(FxdCtx.MacroNums) do --Do 8 Times
        Mcro_Asgn_Md_Idx         = 'Macro' .. tostring(FxdCtx.MacroNums[i])
        FxdCtx.Trk[TrkID].Mod[i] = FxdCtx.Trk[TrkID].Mod[i] or {}
        local Mc                 = FxdCtx.Trk[TrkID].Mod[i]
        local Macro              = i

        local I, _, _            = FxdCtx.Trk[TrkID].Mod[i], nil, r.ImGui_GetCursorPosX(ctx)
        r.ImGui_PushID(ctx, i)


        local function PushClr(AssigningMacro)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowMidSat[i])
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), EightColors.MidSat[i])
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), EightColors.Bright[i])
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), EightColors.HighSat_MidBright[i])
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrabActive(), EightColors.Bright_HighSat[i])

            if AssigningMacro == i then
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.HighSat_MidBright[i])
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), EightColors.bgWhenAsgnModAct[i])
                PopColorTime = 2
            end
            ClrPop = 6
            return PopColorTime
        end

        FxdCtx.Trk[TrkID].Mod[i].Type = FxdCtx.Trk[TrkID].Mod[i].Type or 'Macro'
        if FxdCtx.Trk[TrkID].Mod[i].Type == 'Macro' then
            PopColorTime = PushClr(AssigningMacro)

            r.ImGui_TableSetColumnIndex(ctx, (FxdCtx.MacroNums[i] - 1) * 2)
            MacroX_Label = 'Macro' .. tostring(FxdCtx.MacroNums[i])


            MacroValueLBL = TrkID .. 'Macro' .. FxdCtx.MacroNums[i]

            r.ImGui_PushItemWidth(ctx, -FLT_MIN)

            IsMacroSlidersEdited, I.Val = r.ImGui_SliderDouble(ctx, i .. '##', I.Val, Slider1Min or 0,
                Slider1Max or 1)
            IsMacroActive = r.ImGui_IsItemActive(ctx)
            if IsMacroActive == true then Mc.AnyActive = true end
            R_ClickOnMacroSliders = r.ImGui_IsItemClicked(ctx, 1)
            -- if r.ImGui_IsItemClicked( ctx,1) ==true and Mods==nil then R_ClickOnMacroSliders = true end
            if r.ImGui_IsItemClicked(ctx, 1) == true and Mods == Ctrl then
                r.ImGui_OpenPopup(ctx, 'Macro' .. i .. 'Menu')
            end

            if AssigningMacro == i then
                gui_helpers.BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
            end



            --- Macro Label
            r.ImGui_TableSetColumnIndex(ctx, FxdCtx.MacroNums[i] * 2 - 1)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowSat[i])
            r.ImGui_PushItemWidth(ctx, -FLT_MIN)
            MacroNameEdited, I.Name = r.ImGui_InputText(ctx, '##', I.Name or 'Macro ' .. i)
            if MacroNameEdited then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name,
                    true)
            end

            if IsMacroActive then
                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then
                    r.TrackFX_SetParamNormalized(LT_Track, 0, v - 1, I.Val)
                    r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID, I.Val)
                end
            else
            end


            if AssigningMacro == i then r.ImGui_PopStyleColor(ctx, PopColorTime) end

            if R_ClickOnMacroSliders and AssigningMacro == nil and Mods == 0 then
                AssigningMacro = i
            elseif R_ClickOnMacroSliders and AssigningMacro ~= nil then
                AssigningMacro = nil
            end




            r.ImGui_PopStyleColor(ctx, ClrPop)
        elseif FxdCtx.Trk[TrkID].Mod[i].Type == 'env' then
            if Mods == Shift then DragSpeed = 0.0001 else DragSpeed = 0.01 end
            PopColorTime = PushClr(AssigningMacro)
            r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2)
            r.ImGui_PushItemWidth(ctx, -FLT_MIN)
            r.ImGui_SetNextItemWidth(ctx, 60)
            local Mc = FxdCtx.Trk[TrkID].Mod[i]

            At, Mc.ATK = r.ImGui_DragDouble(ctx, '## atk' .. i, Mc.ATK, DragSpeed, 0, 1, '',
                r.ImGui_SliderFlags_NoInput())
            gui_helpers.SL(nil, 0)
            RCat = r.ImGui_IsItemClicked(ctx, 1)
            local L, T = r.ImGui_GetItemRectMin(ctx)
            local W, H = r.ImGui_GetItemRectSize(ctx)
            local R, B = L + W, T + H
            if At then
                Mc.atk = 0.000001 ^ (1 - Mc.ATK)
                r.gmem_write(4, 2)                      -- tells jsfx user is adjusting atk
                r.gmem_write(9 + ((i - 1) * 2), Mc.atk) -- tells atk value
                r.gmem_write(5, i)                      -- tells which macro is being tweaked
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Atk', Mc.ATK, true)
            end
            if r.ImGui_IsItemActive(ctx) then
                r.ImGui_SetNextWindowPos(ctx, L, T - H - 10)
                r.ImGui_BeginTooltip(ctx)
                local f = '%.1f'
                if Mods == Alt then f = '%.3f' end
                local num = (Mc.atk or 0.001) * 1000
                if num > 100 then f = '%.0f' end
                if num < 10 then f = '%.2f' end
                if num < 1 then f = '%.3f' end
                r.ImGui_Text(ctx, (f):format(num))
                r.ImGui_EndTooltip(ctx)
            end
            local WDL = r.ImGui_GetWindowDrawList(ctx)
            r.ImGui_DrawList_AddLine(WDL, L + W * Mc.ATK, T, R, T, 0xffffffff)
            r.ImGui_DrawList_AddLine(WDL, L, B, L + W * Mc.ATK, T, 0xffffffff)

            if AssigningMacro == i then
                gui_helpers.BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
            end

            r.ImGui_SetNextItemWidth(ctx, 60)

            Re, Mc.REL  = r.ImGui_DragDouble(ctx, '## rel' .. i, Mc.REL, DragSpeed, 0.001, 1, '',
                r.ImGui_SliderFlags_NoInput())
            local RCrel = r.ImGui_IsItemClicked(ctx, 1)
            if Re then
                --Mc.rel = 10^(rel or 0.001) /10
                Mc.rel = 0.001 ^ (1 - Mc.REL)
                r.gmem_write(4, 3)                       -- tells jsfx user is adjusting rel
                r.gmem_write(10 + ((i - 1) * 2), Mc.rel) -- tells rel value
                r.gmem_write(5, i)                       -- tells which macro is being tweaked
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Rel', Mc.REL, true)
            end
            if r.ImGui_IsItemActive(ctx) then
                r.ImGui_SetNextWindowPos(ctx, L, T - H - 30)
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_Text(ctx, ('%.3f'):format(Mc.rel or 0.001))
                r.ImGui_EndTooltip(ctx)
            end
            local L, T = r.ImGui_GetItemRectMin(ctx)
            local W, H = r.ImGui_GetItemRectSize(ctx)
            local _, B = L + W, T + H
            --r.ImGui_DrawList_AddLine(Glob.FDL, L ,T,L+W*Rel,T, 0xffffffff)
            r.ImGui_DrawList_AddLine(WDL, L, T, L + W * Mc.REL, B, 0xffffffff)
            if AssigningMacro == i then
                gui_helpers.BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
            end
            r.ImGui_TableSetColumnIndex(ctx, i * 2 - 1)
            r.ImGui_PushItemWidth(ctx, -FLT_MIN)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowSat[i])
            if I.Name == 'Macro ' .. i then I.Name = 'Env ' .. i end
            MacroNameEdited, I.Name = r.ImGui_InputText(ctx, '##', I.Name or 'Env ' .. i)
            if MacroNameEdited then
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name,
                    true)
            end
            if (r.ImGui_IsItemClicked(ctx, 1) or RCat or RCrel) and Mods == Ctrl then
                r.ImGui_OpenPopup(ctx, 'Env' .. i .. 'Menu')
            end



            if AssigningMacro == i then r.ImGui_PopStyleColor(ctx, 2) end

            if (RCat or RCrel) and not AssigningMacro and Mods == 0 then
                AssigningMacro = i
            elseif (RCat or RCrel) and AssigningMacro then
                AssigningMacro = nil
            end

            if LBtnREl then
                for i = 1, 16, 1 do
                    r.gmem_write(8 + i, 0)
                end
            end
            r.ImGui_PopStyleColor(ctx, ClrPop)
        elseif FxdCtx.Trk[TrkID].Mod[i].Type == 'Step' then
            Macros_WDL = Macros_WDL or r.ImGui_GetWindowDrawList(ctx)
            r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2) --r.ImGui_PushItemWidth( ctx, -FLT_MIN)
            local Mc = FxdCtx.Trk[TrkID].Mod[i]
            r.gmem_attach('ParamValues')
            local CurrentPos = r.gmem_read(108 + Macro) + 1 --  +1 because to make zero-based start on 1


            --r.ImGui_SetNextItemWidth(ctx, 20)
            FxdCtx.Trk[TrkID].Mod[i].SEQ = FxdCtx.Trk[TrkID].Mod[i].SEQ or {}
            local S                      = FxdCtx.Trk[TrkID].Mod[i].SEQ

            FxdCtx.Trk[TrkID].SEQL       = FxdCtx.Trk[TrkID].SEQL or {}
            FxdCtx.Trk[TrkID].SEQ_Dnom   = FxdCtx.Trk[TrkID].SEQ_Dnom or {}

            local HoverOnAnyStep
            local SmallSEQActive
            local HdrPosL, _             = r.ImGui_GetCursorScreenPos(ctx)
            for St = 1, FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do -- create all steps
                local W = (FxdCtx.VP.w - 10) / 12
                local L, T = r.ImGui_GetCursorScreenPos(ctx)
                if St == 1 and AssigningMacro == i then
                    local H = 20
                    local W = (FxdCtx.VP.w - 10) / 12
                    gui_helpers.BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink, L, T, L + W, T + H, H, W)

                    --HighlightSelectedItem(0xffffff77,0xffffff33, 0, L,T,L+W,T+H,H,W, 1, 1,GetItemRect, Foreground)
                end
                --_, S[St]= r.ImGui_DragDouble(ctx, '##SEQ '..St ,  S[St], 0 ,0, 1, ' ',r.ImGui_SliderFlags_NoInput())
                r.ImGui_InvisibleButton(ctx, '##SEQ' .. St .. TrkID, W / 8, 20)
                local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx); local w, h =
                    r.ImGui_GetItemRectSize(ctx)
                local FillClr = 0x00000000



                SEQ_Popup_L = SEQ_Popup_L or L
                SEQ_Popup_T = SEQ_Popup_T or T

                if r.ImGui_IsItemHovered(ctx) and not r.ImGui_IsMouseDown(ctx, 0) then
                    HoverOnAnyStep = true
                end
                if HoverOnAnyStep then WhichMacroIsHovered = i end


                if r.ImGui_IsItemHovered(ctx) then FillClr = 0xffffff22 end
                gui_helpers.HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1, GetItemRect,
                    Foreground)



                S[St] = math_helpers.SetMinMax(S[St] or 0, 0, 1)
                if r.ImGui_IsItemActive(ctx) then
                    local _, v = r.ImGui_GetMouseDelta(ctx, nil, nil)

                    if Mods == Shift then DrgSpdMod = 4 end
                    if v ~= 0 then
                        v = v * (-1)
                        if not (S[St] == 1 and v > 0) and not (S[St] == 0 and v < 0) then
                            S[St] = S[St] + v / 100
                            r.gmem_write(4, 7)                                                -- tells jsfx user is changing a step's value
                            r.gmem_write(5, i)                                                -- tells which macro user is tweaking
                            r.gmem_write(112, math_helpers.SetMinMax(S[St], 0, 1) * (-1) + 1) -- tells the step's value
                            r.gmem_write(113, St)                                             -- tells which step
                        end
                        r.ImGui_ResetMouseDragDelta(ctx)
                    end
                    SmallSEQActive = true
                elseif r.ImGui_IsItemDeactivated(ctx) then
                    r.GetSetMediaTrackInfo_String(LT_Track,
                        'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St ..
                        ' Val', S[St], true)
                end
                WhenRightClickOnModulators(Macro)



                local W, H = r.ImGui_GetItemRectSize(ctx)
                local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)
                if r.ImGui_IsItemActive(ctx) then
                    Clr = EightColors.Bright_HighSat[i]
                elseif r.ImGui_IsItemHovered(ctx) then
                    Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                end


                r.ImGui_DrawList_AddRectFilled(Macros_WDL, L, T + H, L + W - 1, math.max(B - H * (S[St] or 0), T),
                    Clr)
                if CurrentPos == St then -- if Step SEQ 'playhead' is now on current step
                    r.ImGui_DrawList_AddRect(Macros_WDL, L, T + H, L + W - 1, T, 0xffffff99)
                end
                gui_helpers.SL(nil, 0)
            end



            r.ImGui_SetNextWindowPos(ctx, HdrPosL, FxdCtx.VP.y - StepSEQ_H - 100)
            if Mc.AdjustingSteps and not r.ImGui_IsMouseDown(ctx, 0) then Mc.AdjustingSteps = nil end

            function Open_SEQ_Win(i)
                if not HoveringSmoothness then
                    if r.ImGui_Begin(ctx, 'SEQ Window' .. i, true, r.ImGui_WindowFlags_NoResize() + r.ImGui_WindowFlags_NoDocking() + r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_AlwaysAutoResize()) then
                        local WDL = r.ImGui_GetWindowDrawList(ctx)
                        r.ImGui_Text(ctx, 'Sequence Length : ')
                        local function writeSEQDNom()
                            if GF.AddMacroJSFX() then
                                r.gmem_write(4, 8) --[[tells JSFX user is tweaking seq length or DNom]]
                                r.gmem_write(5, i) --[[tells JSFX the macro]]
                                r.gmem_write(10, FxdCtx.Trk[TrkID].SEQ_Dnom[i])
                                r.gmem_write(9, FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                                    FxdCtx.Trk[TrkID].SEQ_Dnom[i], true)
                            end
                        end

                        local function writeSEQGmem()
                            if GF.AddMacroJSFX() then
                                r.gmem_write(4, 8)
                                r.gmem_write(5, i)
                                r.gmem_write(9, FxdCtx.Trk[TrkID].SEQL[i])
                                r.gmem_write(10, FxdCtx.Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom)
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Length',
                                    FxdCtx.Trk[TrkID].SEQL[i], true)
                            end
                        end



                        FxdCtx.Trk[TrkID].SEQL        = FxdCtx.Trk[TrkID].SEQL or {}
                        Rv, FxdCtx.Trk[TrkID].SEQL[i] = r.ImGui_SliderInt(ctx,
                            '##' .. 'Macro' .. i .. 'SEQ Length',
                            FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 2, 64)
                        if r.ImGui_IsItemActive(ctx) then writeSEQGmem() end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, 'x2##' .. i) then
                            FxdCtx.Trk[TrkID].SEQL[i] = math.floor((FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) *
                                2)
                            writeSEQGmem()
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '/2##' .. i) then
                            FxdCtx.Trk[TrkID].SEQL[i] = math.floor((FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) /
                                2)
                            writeSEQGmem()
                        end

                        r.ImGui_Text(ctx, 'Step Length : ')
                        if r.ImGui_Button(ctx, '2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 0.125
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 0.125 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                R, B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '1 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 0.25
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 0.25 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                R, B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '1/2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 0.5
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 0.5 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                R, B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '1/4 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 1
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 1 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '1/8 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 2
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 2 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '1/16 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 4
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 4 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, '1/32 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 8
                            writeSEQDNom()
                        end
                        gui_helpers.SL()
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 8 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end
                        if r.ImGui_Button(ctx, '1/64 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                            FxdCtx.Trk[TrkID].SEQ_Dnom[i] = 16
                            writeSEQDNom()
                        end
                        if FxdCtx.Trk[TrkID].SEQ_Dnom[i] == 16 then
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                B, h, W, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                        end


                        local MsX, _ = r.ImGui_GetMousePos(ctx)
                        for St = 1, FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do
                            r.ImGui_InvisibleButton(ctx, '##SEQ' .. St .. TrkID, StepSEQ_W, StepSEQ_H)
                            local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx); local w, h =
                                r.ImGui_GetItemRectSize(ctx)
                            r.ImGui_DrawList_AddText(WDL, L + StepSEQ_W / 2 / 2, B - 15, 0x999999ff, St)
                            gui_helpers.SL(nil, 0)
                            local FillClr = 0x00000000

                            if r.ImGui_IsItemClicked(ctx) then
                                Mc.AdjustingSteps = Macro
                            end
                            local AdjustingStep
                            if Mc.AdjustingSteps and MsX >= L and MsX < R then
                                AdjustingStep = St
                            end


                            if AdjustingStep == St then
                                --Calculate Value at Mouse pos
                                local _, MsY = r.ImGui_GetMousePos(ctx)

                                S[St] = math_helpers.SetMinMax(((B - MsY) / StepSEQ_H), 0, 1) --[[ *(-1) ]]
                                r.gmem_write(4, 7)                                     -- tells jsfx user is changing a step's value
                                r.gmem_write(5, i)                                     -- tells which macro user is tweaking
                                r.gmem_write(112, math_helpers.SetMinMax(S[St], 0, 1)) -- tells the step's value
                                r.gmem_write(113, St)                                  -- tells which step

                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', S[St], true)
                            elseif IsRBtnHeld and r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) and not SmallSEQActive then
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

                            if r.ImGui_IsItemHovered(ctx, r.ImGui_HoveredFlags_RectOnly()) and not SmallSEQActive then
                                FillClr = 0xffffff22
                                Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                            end
                            gui_helpers.HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1,
                                GetItemRect, Foreground)



                            r.ImGui_DrawList_AddRectFilled(WDL, L, T + StepSEQ_H, L + StepSEQ_W - 1,
                                math.max(B - StepSEQ_H * (S[St] or 0), T), Clr)

                            if CurrentPos == St or (CurrentPos == 0 and St == (FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)) then -- if Step SEQ 'playhead' is now on current step
                                r.ImGui_DrawList_AddRect(WDL, L, B, L + StepSEQ_W - 1, T, 0xffffff88)
                            end
                        end




                        local x, y = r.ImGui_GetWindowPos(ctx)
                        local w, h = r.ImGui_GetWindowSize(ctx)


                        if r.ImGui_IsMouseHoveringRect(ctx, x, y, x + w, y + h) then NotHoverSEQ_Time = 0 end

                        r.ImGui_End(ctx)
                    end
                end
            end

            if (WhichMacroIsHovered == Macro and HoverOnAnyStep) or SmallSEQActive or Mc.AdjustingSteps then
                Open_SEQ_Win(Macro)
                NotHoverSEQ_Time = 0
            end

            if WhichMacroIsHovered == i and not HoverOnAnyStep and not SmallSEQActive and not Mc.AdjustingSteps then
                NotHoverSEQ_Time = math.min((NotHoverSEQ_Time or 0), 11) + 1
                if NotHoverSEQ_Time < 10 then
                    Open_SEQ_Win(i)
                else
                    WhichMacroIsHovered = nil
                    NotHoverSEQ_Time = 0
                end
            end
        elseif FxdCtx.Trk[TrkID].Mod[i].Type == 'Follower' then
            r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2)

            r.ImGui_Button(ctx, 'Follower     ')
            if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                r.ImGui_OpenPopup(ctx, 'Follower' .. i .. 'Menu')
            end
            WhenRightClickOnModulators(Macro)
            if r.ImGui_IsItemHovered(ctx) then FolMacroHover = i end



            function OpnFollowerWin(i)
                local HoveringSmoothness

                local HdrPosL, _ = r.ImGui_GetCursorScreenPos(ctx)

                r.ImGui_SetNextWindowPos(ctx, HdrPosL, FxdCtx.VP.y - 55)
                r.ImGui_SetNextWindowSize(ctx, 350, 55)
                if r.ImGui_Begin(ctx, 'Follower Windowww' .. i, true, r.ImGui_WindowFlags_NoResize() + r.ImGui_WindowFlags_NoDocking() + r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_NoTitleBar()) then
                    r.ImGui_Text(ctx, 'Speed : ')
                    gui_helpers.SL()
                    local m = FxdCtx.Trk[TrkID].Mod[i]
                    local CurX = r.ImGui_GetCursorPosX(ctx)
                    Retval, m.Smooth = r.ImGui_DragDouble(ctx, '##Smoothness', m.Smooth or 1, 1, 0, 300,
                        '%.1f')


                    if r.ImGui_IsItemHovered(ctx) or r.ImGui_IsItemActive(ctx) then
                        HoveringSmoothness = i
                    end
                    local x, y = r.ImGui_GetWindowPos(ctx)
                    local w, h = r.ImGui_GetWindowSize(ctx)


                    if r.ImGui_IsMouseHoveringRect(ctx, x, y, x + w, y + h) then
                        NotHoverFOL_Time = 0
                        HoveringSmoothness = i
                    end

                    if Retval then
                        m.smooth = math_helpers.SetMinMax(0.1 ^ (1 - m.Smooth * 0.01), 0.1, 100)
                        r.gmem_write(4, 10)       ---tells jsfx macro type = Follower, and user is adjusting smoothness
                        r.gmem_write(5, i)        ---tells jsfx which macro
                        r.gmem_write(9, m.smooth) -- Sets the smoothness
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Speed',
                            m.Smooth,
                            true)
                    end

                    --r.ImGui_Text(ctx, ('S = ' .. (m.Smooth or '') .. 's= ' .. (m.smooth or '')))
                    r.ImGui_Text(ctx, 'Gain : ')
                    gui_helpers.SL(CurX)

                    Rv, m.Gain = r.ImGui_DragDouble(ctx, '##Gain' .. i, m.Gain or 100, 1, 0, 400, '%.0f' .. '%%')
                    if r.ImGui_IsItemActive(ctx) then
                        r.gmem_write(4, 11) ---tells jsfx macro type = Follower, and user is adjusting gain
                        r.gmem_write(5, i)
                        r.gmem_write(9, m.Gain / 100)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Gain',
                            m.Gain,
                            true)
                    end

                    if r.ImGui_IsItemHovered(ctx) or r.ImGui_IsItemActive(ctx) then HoveringSmoothness = i end

                    r.ImGui_End(ctx)
                end


                return HoveringSmoothness
            end

            if HoveringSmoothness == i then
                HoveringSmoothness = OpnFollowerWin(i)
            end

            if FolMacroHover == i and not HoveringSmoothness then
                local timeout = 20
                NotHoverFOL_Time = math.min((NotHoverFOL_Time or 0), timeout + 1) + 1
                if NotHoverFOL_Time < timeout then
                    HoveringSmoothness = OpnFollowerWin(i)
                else
                    HoveringSmoothness = OpnFollowerWin(i)
                    FolMacroHover = nil
                    NotHoverFOL_Time = 0
                end
            end
        elseif FxdCtx.Trk[TrkID].Mod[i].Type == 'LFO' then
            local function ChangeLFO(mode, V, gmem, StrName)
                r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
                r.gmem_write(5, i)    -- Tells jsfx which macro
                r.gmem_write(gmem or 9, V)
                if StrName then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
                end
            end

            local function SaveLFO(StrName, V)
                if StrName then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod ' .. Macro .. StrName, V, true)
                end
            end
            local H           = 20
            local MOD         = math.abs(math_helpers.SetMinMax((r.gmem_read(100 + i) or 0) / 127, -1, 1))
            FxdCtx.LFO.DummyH = FxdCtx.LFO.Win.h + 20
            --LFO.DummyW  =  ( LFO.Win.w + 30) * ((Mc.LFO_leng or LFO.Def.Len)/4 )
            Mc.Freq           = Mc.Freq or 1
            Mc.Gain           = Mc.Gain or 5
            r.ImGui_TableSetColumnIndex(ctx, (FxdCtx.MacroNums[i] - 1) * 2)
            --[[  IsMacroSlidersEdited, I.Val = r.ImGui_SliderDouble(ctx, i .. '##LFO', I.Val, Slider1Min or 0,
                    Slider1Max or 1) ]]

            local W = (FxdCtx.VP.w - 10) / 12 - 3
            local rv = r.ImGui_InvisibleButton(ctx, 'LFO Button' .. i, W, H)
            local w, h = r.ImGui_GetItemRectSize(ctx)

            local L, T = r.ImGui_GetItemRectMin(ctx)
            local WDL = r.ImGui_GetWindowDrawList(ctx)
            local X_range = (FxdCtx.LFO.Win.w) * ((Mc.LFO_leng or FxdCtx.LFO.Def.Len) / 4)

            r.ImGui_DrawList_AddRect(WDL, L, T - 2, L + w + 2, T + h, EightColors.LFO[i])



            if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                r.ImGui_OpenPopup(ctx, 'LFO' .. i .. 'Menu')
            elseif rv and Mods == 0 then
                if FxdCtx.LFO.Pin == TrkID .. 'Macro = ' .. Macro then
                    FxdCtx.LFO.Pin = nil
                else
                    FxdCtx.LFO.Pin = TrkID .. 'Macro = ' .. Macro
                end
            end

            WhenRightClickOnModulators(Macro)
            local HdrPosL, _ = r.ImGui_GetCursorScreenPos(ctx)
            function DrawShape(Node, L, W, H, T, Clr)
                if Node then
                    for i, _ in ipairs(Node) do
                        local W, H = W or w, H or h


                        local N = Node
                        local L = L or HdrPosL
                        local lastX = N[math.max(i - 1, 1)].x * W + L
                        local lastY = T + H - (-N[math.max(i - 1, 1)].y + 1) * H

                        local x = N[i].x * W + L
                        local y = T + H - (-N[math.min(i, #Node)].y + 1) * H

                        local CtrlX = (N[i].ctrlX or ((N[math.max(i - 1, 1)].x + N[i].x) / 2)) * W + L
                        local CtrlY = T + H - (-(N[i].ctrlY or ((N[math.max(i - 1, 1)].y + N[i].y) / 2)) + 1) * H

                        local PtsX, PtsY = math_helpers.Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, x, y)

                        for i, _ in ipairs(PtsX) do
                            if i > 1 and PtsX[i] <= L + W then -- >1 because you need two points to draw a line
                                r.ImGui_DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
                                    Clr or EightColors.LFO[Macro])
                            end
                        end
                    end
                end
            end

            -- Draw Tiny Playhead
            local PlayPos = L + r.gmem_read(108 + i) / 4 * w / ((Mc.LFO_leng or FxdCtx.LFO.Def.Len) / 4)
            r.ImGui_DrawList_AddLine(WDL, PlayPos, T, PlayPos, T + h, EightColors.LFO[Macro], 1)
            r.ImGui_DrawList_AddCircleFilled(WDL, PlayPos, T + h - MOD * h - 3 / 2, 3, EightColors.LFO[Macro])

            DrawShape(Mc.Node, HdrPosL, w, h, T)


            if rv and not LFO_DragDir and Mods == 0 then
                r.ImGui_OpenPopup(ctx, 'LFO Shape Select')
                --r.ImGui_SetNextWindowSize(ctx, LFO.Win.w  , LFO.Win.h+200)
            end



            function Open_LFO_Win(Track, Macro)
                local tweaking
                -- r.ImGui_SetNextWindowSize(ctx, LFO.Win.w +20 , LFO.Win.h + 50)
                r.ImGui_SetNextWindowPos(ctx, HdrPosL, FxdCtx.VP.y - 385)
                if r.ImGui_Begin(ctx, 'LFO Shape Edit Window' .. Macro, true, r.ImGui_WindowFlags_NoDecoration() + r.ImGui_WindowFlags_AlwaysAutoResize()) then
                    local Node = FxdCtx.Trk[TrkID].Mod[i].Node



                    --Mc.Node = Mc.Node or { x = {} , ctrlX = {}, y = {}  , ctrlY = {}}
                    --[[ if not Node[i].x then
                                table.insert(Node.x, L)
                                table.insert(Node.x, L + 400)
                                table.insert(Node.y, T + h / 2)
                                table.insert(Node.y, T + h / 2)
                            end ]]
                    local BtnSz = 11

                    FxdCtx.LFO.Pin = GF.PinIcon(FxdCtx.LFO.Pin, TrkID .. 'Macro = ' .. Macro, BtnSz,
                        'LFO window pin' .. Macro,
                        0x00000000, ClrTint)
                    gui_helpers.SL()


                    if r.ImGui_ImageButton(ctx, '## copy' .. Macro, Img.Copy, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint) then
                        FxdCtx.LFO.Clipboard = {}
                        for i, v in ipairs(Node) do
                            FxdCtx.LFO.Clipboard[i] = FxdCtx.LFO.Clipboard[i] or {}
                            FxdCtx.LFO.Clipboard[i].x = v.x
                            FxdCtx.LFO.Clipboard[i].y = v.y
                        end
                    end

                    gui_helpers.SL()
                    if not FxdCtx.LFO.Clipboard then r.ImGui_BeginDisabled(ctx) end
                    if r.ImGui_ImageButton(ctx, '## paste' .. Macro, Img.Paste, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint) then
                        for i, v in ipairs(FxdCtx.LFO.Clipboard) do
                            Mc.Node[i] = Mc.Node[i] or {}
                            Mc.Node[i].x = v.x
                            Mc.Node[i].y = v.y
                        end
                    end
                    if not FxdCtx.LFO.Clipboard then r.ImGui_EndDisabled(ctx) end

                    gui_helpers.SL()
                    r.ImGui_SetNextItemWidth(ctx, 100)
                    if r.ImGui_BeginCombo(ctx, '## Env_Or_Loop' .. Macro, Mc.LFO_Env_or_Loop or 'Loop') then
                        if r.ImGui_Selectable(ctx, 'Loop', p_1selected, flagsIn, size_wIn, size_hIn) then
                            Mc.LFO_Env_or_Loop = 'Loop'
                            ChangeLFO(18, 0, nil, 'LFO_Env_or_Loop') -- value is 0 because loop is default
                        end
                        if r.ImGui_Selectable(ctx, 'Envelope (MIDI)', p_2selected, flagsIn, size_wIn, size_hIn) then
                            Mc.LFO_Env_or_Loop = 'Envelope'
                            ChangeLFO(18, 1, nil, 'LFO_Env_or_Loop') -- 1 for envelope
                        end
                        tweaking = Macro
                        r.ImGui_EndCombo(ctx)
                    end

                    if Mc.LFO_Env_or_Loop == 'Envelope' then
                        gui_helpers.SL()
                        r.ImGui_SetNextItemWidth(ctx, 120)
                        local ShownName
                        if Mc.Rel_Type == 'Custom Release - No Jump' then ShownName = 'Custom No Jump' end
                        if r.ImGui_BeginCombo(ctx, '## ReleaseType' .. Macro, ShownName or Mc.Rel_Type or 'Latch') then
                            tweaking = Macro
                            if r.ImGui_Selectable(ctx, 'Latch', p_1selected, flagsIn, size_wIn, size_hIn) then
                                Mc.Rel_Type = 'Latch'
                                ChangeLFO(19, 0, nil, 'LFO_Release_Type') -- 1 for latch
                            end
                            gui_helpers.QuestionHelpHint('Latch on to whichever value its at when midi key is released ')
                            --[[ if r.ImGui_Selectable( ctx, 'Simple Release',  p_1selected,   flagsIn,   size_wIn,   size_hIn) then
                                        Mc.Rel_Type = 'Simple Release'
                                        ChangeLFO(19, 1 , nil, 'LFO_Release_Type') -- 1 for Simple release
                                    end   ]]
                            if r.ImGui_Selectable(ctx, 'Custom Release', p_1selected, flagsIn, size_wIn, size_hIn) then
                                Mc.Rel_Type = 'Custom Release'
                                ChangeLFO(19, 2, nil, 'LFO_Release_Type') -- 2 for Custom release
                            end
                            gui_helpers.QuestionHelpHint('Jump to release node when midi note is released')

                            if r.ImGui_Selectable(ctx, 'Custom Release - No Jump', p_1selected, flagsIn, size_wIn, size_hIn) then
                                Mc.Rel_Type = 'Custom Release - No Jump'
                                ChangeLFO(19, 3, nil, 'LFO_Release_Type') -- 3 for Custom release no jump
                            end
                            gui_helpers.QuestionHelpHint(
                                'Custom release, but will prevent values jumping by scaling the part after the release node to fit value when midi key was released')

                            if r.ImGui_Checkbox(ctx, 'Legato', Mc.LFO_Legato) then
                                Mc.LFO_Legato = state_helpers.toggle(Mc.LFO_Legato)
                                ChangeLFO(21, 1, nil, 'LFO_Legato')
                            end

                            r.ImGui_EndCombo(ctx)
                        end
                    end


                    gui_helpers.SL(nil, 30)
                    if r.ImGui_ImageButton(ctx, '## save' .. Macro, Img.Save, BtnSz, BtnSz, nil, nil, nil, nil, ClrBG, ClrTint) then
                        FxdCtx.LFO.OpenSaveDialog = Macro
                    end

                    gui_helpers.SL()


                    if r.ImGui_ImageButton(ctx, '## shape Preset' .. Macro, Img.Sine, BtnSz * 2, BtnSz, nil, nil, nil, nil, 0xffffff00, ClrTint) then
                        if FxdCtx.LFO.OpenShapeSelect then
                            FxdCtx.LFO.OpenShapeSelect = nil
                        else
                            FxdCtx.LFO.OpenShapeSelect =
                                Macro
                        end
                    end
                    if FxdCtx.LFO.OpenShapeSelect then gui_helpers.Highlight_Itm(WDL, 0xffffff55) end


                    r.ImGui_Dummy(ctx, (FxdCtx.LFO.Win.w) * ((Mc.LFO_leng or FxdCtx.LFO.Def.Len) / 4),
                        FxdCtx.LFO.DummyH)
                    --local old_Win_T, old_Win_B = VP.y - 320, VP.y - 20
                    local NodeSz = 15
                    local w, h = r.ImGui_GetItemRectSize(ctx)
                    FxdCtx.LFO.Def.DummyW = (FxdCtx.LFO.Win.w) * (FxdCtx.LFO.Def.Len / 4)
                    FxdCtx.LFO.DummyW = w
                    local L, T = r.ImGui_GetItemRectMin(ctx)
                    local Win_T, Win_B = T, T + h -- 7 is prob the window padding
                    local Win_L = L
                    r.ImGui_DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff22)
                    gui_helpers.SL()
                    r.ImGui_Dummy(ctx, 10, 10)


                    FxdCtx.LFO.Win.L, FxdCtx.LFO.Win.R = L, L + X_range
                    local LineClr, CtClr = 0xffffff99, 0xffffff44

                    Mc.Node = Mc.Node or
                        { { x = 0, y = 0 }, { x = 1, y = 1 } } -- create two default tables for first and last point
                    local Node = Mc.Node



                    local function Save_All_LFO_Info(Node)
                        for i, v in ipairs(Node) do
                            if v.ctrlX then
                                SaveLFO('Node' .. i .. 'Ctrl X', Node[i].ctrlX)
                                SaveLFO('Node' .. i .. 'Ctrl Y', Node[i].ctrlY)
                            end

                            SaveLFO('Node ' .. i .. ' X', Node[i].x)
                            SaveLFO('Node ' .. i .. ' Y', Node[i].y)
                            SaveLFO('Total Number of Nodes', #Node)
                        end
                    end

                    local Mc = FxdCtx.Trk[TrkID].Mod[i]

                    Mc.NodeNeedConvert = Mc.NodeNeedConvert or nil

                    --[[ if Mc.NodeNeedConvert then

                                for N=1, (Mc.LFO_NodeCt or 0) , 1 do

                                        Node[N] = Node[N] or {}
                                    if Node[N].x then
                                        Node[N].x = Node[N].x * LFO.Win.w + HdrPosL
                                        Node[N].y = T +  (-Node[N].y+1) * h
                                    end
                                    if Node[N].ctrlX and Node[N].ctrlY then
                                        Node[N].ctrlX = Node[N].ctrlX* (LFO.Win.w) + LFO.Win.L
                                        Node[N].ctrlY = Win_T + (-Node[N].ctrlY+1) * LFO.Win.h
                                    end
                                end
                                Mc.NodeNeedConvert=nil
                            end ]]


                    if not r.ImGui_IsAnyItemHovered(ctx) and LBtnDC then -- Add new node if double click
                        local x, y = r.ImGui_GetMousePos(ctx)
                        local InsertPos
                        local x = (x - L) / FxdCtx.LFO.DummyW
                        local y = (y - T) / FxdCtx.LFO.DummyH


                        for i = 1, #Node, 1 do
                            if i ~= #Node then
                                if Node[i].x < x and Node[i + 1].x > x then InsertPos = i + 1 end
                            elseif not InsertPos then
                                if Node[1].x > x then
                                    InsertPos = 1 -- if it's before the first node
                                    --[[ table.insert(Node.ctrlX, InsertPos, HdrPosL + (x-HdrPosL)/2)
                                            table.insert(Node.ctrlY, InsertPos, y) ]]
                                elseif Node[i].x < x then
                                    InsertPos = i + 1
                                elseif Node[i].x > x then
                                    InsertPos = i
                                end
                            end
                        end

                        table.insert(Node, InsertPos, {
                            x = math_helpers.SetMinMax(x, 0, 1),
                            y = math_helpers.SetMinMax(y, 0, 1),
                        })

                        Save_All_LFO_Info(Node)
                    end


                    local function AddNode(x, y, ID)
                        gui_helpers.InvisiBtn(ctx, x, y, '##Node' .. ID, 15)
                        local Hvred
                        local L, T = r.ImGui_GetItemRectMin(ctx)

                        local function ClampCtrlNode(ID)
                            Node[ID] = Node[ID] or {}

                            if Node[ID].ctrlX then
                                local lastX = Node[ID - 1].x or 0
                                local lastY, Y = Node[ID - 1].y or Node[ID].y, Node[ID].y


                                -- Segment Before the tweaking point
                                if Node[ID].ctrlX and Node[ID].ctrlY then
                                    Node[ID].ctrlX = math_helpers.SetMinMax(Node[ID].ctrlX, lastX, Node[ID].x)
                                    Node[ID].ctrlY = math_helpers.SetMinMax(Node[ID].ctrlY, math.min(lastY, Y),
                                        math.max(lastY, Y))

                                    SaveLFO('Node' .. ID .. 'Ctrl X', Node[ID].ctrlX)
                                    SaveLFO('Node' .. ID .. 'Ctrl Y', Node[ID].ctrlY)
                                end
                            end
                        end
                        function FindRelNode()
                            for i, v in ipairs(Mc.Node) do
                                if v.Rel == true then return i end
                            end
                        end

                        if (Mc.Rel_Type or ''):find('Custom Release') then
                            if not FindRelNode() then
                                Node[#Mc.Node].Rel = true
                                ChangeLFO(20, #Mc.Node, nil, 'LFO_Rel_Node')
                            end

                            if r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                                Mc.Node[FindRelNode() or 1].Rel = nil
                                Mc.Node[ID].Rel = true
                                ChangeLFO(20, ID, nil, 'LFO_Rel_Node')
                            end
                            if Mc.Node[ID].Rel then
                                local L = L + NodeSz / 2
                                r.ImGui_DrawList_AddCircle(WDL, L, T + NodeSz / 2, 6, 0xffffffaa)
                                r.ImGui_DrawList_AddLine(WDL, L, Win_T, L, Win_B, 0xffffff55, 3)
                                r.ImGui_DrawList_AddText(WDL, math.min(L, Win_L + FxdCtx.LFO.DummyW - 50), Win_T,
                                    0xffffffaa, 'Release')
                            end
                        end



                        if r.ImGui_IsItemHovered(ctx) then
                            LineClr, CtClr = 0xffffffbb, 0xffffff88
                            HoverNode = ID
                            Hvred = true
                        end

                        if MouseClosestNode == ID and r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_X(), false) then
                            DraggingNode = ID
                            tweaking = Macro
                        elseif r.ImGui_IsKeyReleased(ctx, r.ImGui_Key_X()) then
                            DraggingNode = nil
                        end

                        -- if moving node
                        if (r.ImGui_IsItemActive(ctx) and Mods == 0) or DraggingNode == ID then
                            tweaking = Macro
                            GF.HideCursorTillMouseUp(nil, r.ImGui_Key_X())
                            GF.HideCursorTillMouseUp(0)
                            HoverNode = ID
                            Send_All_Coord()

                            local lastX = Node[math.max(ID - 1, 1)].x
                            local nextX = Node[math.min(ID + 1, #Node)].x
                            if ID == 1 then lastX = 0 end
                            if ID == #Node then nextX = 1 end

                            local MsX, MsY = GF.GetMouseDelta(0, r.ImGui_Key_X())
                            local MsX = MsX / FxdCtx.LFO.DummyW
                            local MsY = MsY / FxdCtx.LFO.DummyH


                            Node[ID].x = math_helpers.SetMinMax(Node[ID].x + MsX, lastX, nextX)
                            Node[ID].y = math_helpers.SetMinMax(Node[ID].y + MsY, 0, 1)


                            if ID == 1 then
                                ClampCtrlNode(ID - 1)
                            end

                            ClampCtrlNode(ID)
                            ClampCtrlNode(math.min(ID + 1, #Node))


                            --[[ ChangeLFO(13, NormX, 9, 'Node '..ID..' X')
                                    ChangeLFO(13, NormY, 10, 'Node '..ID..' Y')
                                    ChangeLFO(13, ID, 11)   -- tells jsfx which node user is adjusting
                                    ChangeLFO(13, #Node.x, 12, 'Total Number of Nodes' ) ]]

                            SaveLFO('Node ' .. ID .. ' X', Node[ID].x)
                            SaveLFO('Node ' .. ID .. ' Y', Node[ID].y)
                            SaveLFO('Total Number of Nodes', #Node)


                            if ID ~= #Node then
                                local this, next = Node[ID].x, Node[ID + 1].x or 1
                                Node[ID + 1].ctrlX = math_helpers.SetMinMax(Node[ID + 1].ctrlX or (this + next) / 2, this,
                                    next)
                                if Node[ID + 1].ctrlX == (this + next) / 2 then Node[ID + 1].ctrlX = nil end
                            end

                            r.ImGui_ResetMouseDragDelta(ctx)
                        elseif r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                            FxdCtx.LFO.DeleteNode = ID
                        end


                        r.ImGui_DrawList_AddCircle(WDL, L + NodeSz / 2, T + NodeSz / 2, 5, LineClr)
                        r.ImGui_DrawList_AddCircleFilled(WDL, L + NodeSz / 2, T + NodeSz / 2, 3, CtClr)
                        return Hvred
                    end
                    local Node = Mc.Node



                    local FDL = r.ImGui_GetForegroundDrawList(ctx)
                    --table.sort(Node.x, function(k1, k2) return k1 < k2 end)
                    local AnyNodeHovered
                    if r.ImGui_IsKeyReleased(ctx, r.ImGui_Key_C()) or LBtnRel then
                        DraggingLFOctrl = nil
                        Save_All_LFO_Info(Node)
                    end

                    All_Coord = { X = {}, Y = {} }

                    if FxdCtx.LFO.DeleteNode then
                        table.remove(Mc.Node, FxdCtx.LFO.DeleteNode)
                        Mc.NeedSendAllCoord = true
                        Save_All_LFO_Info(Node)
                        FxdCtx.LFO.DeleteNode = nil
                    end


                    local PlayPosX = HdrPosL + r.gmem_read(108 + i) / 4 * FxdCtx.LFO.Win.w

                    for i = 1, #Mc.Node, 1 do --- Rpt for every node
                        local last = math.max(i - 1, 1)
                        local lastX, lastY = L + (Node[last].x or 0) * FxdCtx.LFO.DummyW,
                            T + (Node[last].y or Node[i].y) * FxdCtx.LFO.DummyH
                        local X, Y = L + Node[i].x * FxdCtx.LFO.DummyW, T + Node[i].y * FxdCtx.LFO.DummyH




                        if AddNode(X - 15 / 2, Y - 15 / 2, i) then AnyNodeHovered = true end
                        local CtrlX, CtrlY =
                            L + (Node[i].ctrlX or (Node[last].x + Node[i].x) / 2) * FxdCtx.LFO.DummyW,
                            T + (Node[i].ctrlY or (Node[last].y + Node[i].y) / 2) * FxdCtx.LFO.DummyH


                        -- Control Node
                        if (r.ImGui_IsMouseHoveringRect(ctx, lastX, Win_T, X, Win_B) or DraggingLFOctrl == i) then
                            local Sz = FxdCtx.LFO.CtrlNodeSz

                            ---- Draw Node
                            if not DraggingLFOctrl or DraggingLFOctrl == i then
                                if not HoverNode and not DraggingNode then
                                    r.ImGui_DrawList_AddBezierQuadratic(WDL, lastX, lastY, CtrlX, CtrlY, X, Y,
                                        0xffffff44, 7)
                                    r.ImGui_DrawList_AddCircle(WDL, CtrlX, CtrlY, Sz, LineClr)
                                    --r.ImGui_DrawList_AddText(FDL, CtrlX, CtrlY, 0xffffffff, i)
                                end
                            end

                            gui_helpers.InvisiBtn(ctx, CtrlX - Sz / 2, CtrlY - Sz / 2, '##Ctrl Node' .. i, Sz)
                            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_C(), false) or r.ImGui_IsItemActivated(ctx) then
                                DraggingLFOctrl = i
                            end

                            if r.ImGui_IsItemHovered(ctx) then
                                r.ImGui_DrawList_AddCircle(WDL, CtrlX, CtrlY, Sz + 2, LineClr)
                            end
                        end

                        -- decide which node is mouse closest to
                        local Range = X - lastX
                        if r.ImGui_IsMouseHoveringRect(ctx, lastX, Win_T, lastX + Range / 2, Win_B) and not tweaking and not DraggingNode then
                            r.ImGui_DrawList_AddCircle(WDL, lastX, lastY, FxdCtx.LFO.NodeSz + 2, LineClr)
                            MouseClosestNode = last
                        elseif r.ImGui_IsMouseHoveringRect(ctx, lastX + Range / 2, Win_T, X, Win_B) and not tweaking and not DraggingNode then
                            r.ImGui_DrawList_AddCircle(WDL, X, Y, FxdCtx.LFO.NodeSz + 2, LineClr)

                            MouseClosestNode = i
                        end

                        --- changing control point
                        if DraggingLFOctrl == i then
                            tweaking           = Macro
                            local Dx, Dy       = GF.GetMouseDelta(0, r.ImGui_Key_C())
                            local Dx, Dy       = Dx / FxdCtx.LFO.DummyW, Dy / FxdCtx.LFO.DummyH
                            local CtrlX, CtrlY = Node[i].ctrlX or (Node[last].x + Node[i].x) / 2,
                                Node[i].ctrlY or (Node[last].y + Node[i].y) / 2

                            Node[i].ctrlX      = math_helpers.SetMinMax(CtrlX + Dx, Node[last].x, Node[i].x)
                            Node[i].ctrlY      = math_helpers.SetMinMax(CtrlY + Dy, math.min(Node[last].y, Node[i].y),
                                math.max(Node[last].y, Node[i].y))

                            SaveLFO('Node' .. i .. 'Ctrl X', Node[i].ctrlX)
                            SaveLFO('Node' .. i .. 'Ctrl Y', Node[i].ctrlY)
                            Send_All_Coord()
                        end





                        if (Mc.LFO_Gain or 1) ~= 1 then
                            local B = T + FxdCtx.LFO.DummyH
                            local y = -Node[i].y + 1
                            local Y = B - y * FxdCtx.LFO.DummyH * Mc.LFO_Gain
                            local lastY = B -
                                (-(Node[last].y or Node[i].y) + 1) * FxdCtx.LFO.DummyH * Mc.LFO_Gain
                            local CtrlY = B -
                                (-(Node[i].ctrlY or (Node[last].y + Node[i].y) / 2) + 1) * FxdCtx.LFO.DummyH *
                                Mc.LFO_Gain
                            local PtsX, PtsY = math_helpers.Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, X, Y)

                            for i = 1, #PtsX, 2 do
                                if i > 1 then -- >1 because you need two points to draw a line
                                    r.ImGui_DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
                                        0xffffffff)
                                end
                            end
                        end

                        PtsX = {}
                        PtsY = {}

                        PtsX, PtsY = math_helpers.Curve_3pt_Bezier(lastX, lastY, CtrlX, CtrlY, X, Y)

                        if Wheel_V ~= 0 then Sqr = (Sqr or 0) + Wheel_V / 100 end


                        --r.ImGui_DrawList_AddLine(FDL, p.x, p.y, 0xffffffff)



                        local CurrentPlayPos
                        for i, _ in ipairs(PtsX) do
                            if i > 1 then -- >1 because you need two points to draw a line
                                if PlayPosX > PtsX[i - 1] and PlayPosX < PtsX[i] then
                                    CurrentPlayPos = i
                                end
                                r.ImGui_DrawList_AddLine(WDL, PtsX[i - 1], PtsY[i - 1], PtsX[i], PtsY[i],
                                    0xffffffff)
                            end
                            ----- things below don't need >1 because jsfx needs all points to draw lines



                            --- normalize values
                            local NormX = (PtsX[i] - HdrPosL) / FxdCtx.LFO.Win.w
                            local NormY = (Win_B - PtsY[i]) /
                                (FxdCtx.LFO.DummyH) -- i think 3 is the window padding



                            --[[ r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                                    r.gmem_write(5, Macro) ]]
                            --[[
                                    r.gmem_write(1000+i*N, NormX) -- gmem 1000 ~ 1999 = X coordinates
                                    r.gmem_write(2000+i*N, NormY) -- gmem 2000 ~ 2999 = Y coordinates ]]
                            table.insert(All_Coord.X, NormX or 0)
                            table.insert(All_Coord.Y, NormY or 0)
                        end

                        function Send_All_Coord()
                            for i, v in ipairs(All_Coord.X) do
                                r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                                r.gmem_write(5, Macro)
                                r.gmem_write(6, #Mc.Node * 11)
                                r.gmem_write(1000 + i, v)
                                r.gmem_write(2000 + i, All_Coord.Y[i])
                            end
                        end

                        if CurrentPlayPos and (Mc.LFO_spd or 1) >= 2 then
                            for i = 1, CurrentPlayPos, 1 do
                                local pos = CurrentPlayPos - 1
                                local L = math.max(pos - i, 1)
                                --if PtsX[pos] > PtsX[i] -30  then  -- if playhead is 60 pixels right to current point
                                r.ImGui_DrawList_AddLine(FDL, PtsX[L + 1], PtsY[L + 1], PtsX[L], PtsY[L],
                                    0xffffff88, 7 - 7 * (i * 0.1))
                                -- end
                                --r.ImGui_DrawList_AddText(FDL, PtsX[i] ,PtsY[i], 0xffffffff, i)


                                -- calculate how far X and last x
                                local Ly, Lx

                                TestTB = {}

                                for i = 0, (PlayPosX - PtsX[pos]), (PlayPosX - PtsX[pos]) / 4 do
                                    local n = math.min(pos + 1, #PtsX)
                                    local x2 = PtsX[pos] + i
                                    local y2 = PtsY[pos] +
                                        (PtsY[CurrentPlayPos] - PtsY[pos]) * (i / (PtsX[n] - PtsX[pos]))

                                    r.ImGui_DrawList_AddLine(FDL, Lx or x2, Ly or y2, x2, y2,
                                        Change_Clr_A(0xffffff00, (i / (PlayPosX - PtsX[pos])) * 0.3), 7)
                                    Ly = y2
                                    Lx = x2

                                    table.insert(TestTB, (i / (PlayPosX - PtsX[pos])))
                                end
                            end
                        end



                        r.gmem_write(6, #Node * 11)

                        --r.ImGui_DrawList_AddBezierQuadratic(FDL, lastX, lastY, CtrlX, CtrlY, v, Y, 0xffffffff, 3)
                    end

                    if (Mc.LFO_spd or 1) < 2 then
                        DrawLFOvalueTrail(Mc, PlayPosX, Win_B - MOD * FxdCtx.LFO.DummyH, Macro)
                    end


                    for i, v in ipairs(All_Coord.X) do
                        r.gmem_write(1000 + i, v)
                        r.gmem_write(2000 + i, All_Coord.Y[i])
                    end


                    if DraggingLFOctrl then
                        GF.HideCursorTillMouseUp(nil, r.ImGui_Key_C())
                        GF.HideCursorTillMouseUp(0)
                    end


                    if not AnyNodeHovered then HoverNode = nil end


                    --r.ImGui_DrawList_PathStroke(FDL, 0xffffffff, nil, 2)

                    --- Draw Playhead

                    r.ImGui_DrawList_AddLine(WDL, PlayPosX, Win_T, PlayPosX, Win_B, 0xffffff99, 4)
                    r.ImGui_DrawList_AddCircleFilled(WDL, PlayPosX, Win_B - MOD * FxdCtx.LFO.DummyH, 5,
                        0xffffffcc)

                    --- Draw animated Trail for modulated value
                    --[[ Mc.LFO_Trail = Mc.LFO_Trail or {}
                            table.insert(Mc.LFO_Trail , Win_B - MOD * LFO.DummyH)
                            if # Mc.LFO_Trail > 100 then table.remove(Mc.LFO_Trail, 1) end
                            for i, v in ipairs( Mc.LFO_Trail) do

                            end ]]


                    if Mc.NeedSendAllCoord then
                        Send_All_Coord()
                        Mc.NeedSendAllCoord = nil
                    end

                    -- Draw Grid

                    local function DrawGridLine_V(division)
                        local Pad_L = 5
                        for i = 0, division, 1 do
                            local W = (X_range / division)
                            local X = Pad_L + HdrPosL + W * i
                            r.ImGui_DrawList_AddLine(WDL, X, Win_T, X, Win_B, 0xffffff55, 2)
                        end
                    end
                    DrawGridLine_V(Mc.LFO_leng or FxdCtx.LFO.Def.Len)


                    r.ImGui_SetCursorPos(ctx, 10, FxdCtx.LFO.Win.h + 55)
                    r.ImGui_AlignTextToFramePadding(ctx)
                    r.ImGui_Text(ctx, 'Speed:')
                    gui_helpers.SL()
                    r.ImGui_SetNextItemWidth(ctx, 50)
                    local _, V = r.ImGui_DragDouble(ctx, '##Speed', Mc.LFO_spd or 1, 0.05, 0.125, 128, 'x %.3f')
                    if r.ImGui_IsItemActive(ctx) then
                        ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed')
                        tweaking = Macro
                        Mc.LFO_spd = V
                    end
                    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, '##LFO Speed menu' .. Macro)
                    end
                    if r.ImGui_BeginPopup(ctx, '##LFO Speed menu' .. Macro) then
                        tweaking = Macro
                        if r.ImGui_Selectable(ctx, 'Add Parameter to Envelope', false) then
                            AutomateModPrm(Macro, 'LFO Speed', 17, 'LFO ' .. Macro .. ' Speed')
                            r.TrackList_AdjustWindows(false)
                            r.UpdateArrange()
                        end

                        r.ImGui_EndPopup(ctx)
                    end
                    if Mods == Alt and r.ImGui_IsItemActivated(ctx) then Mc.LFO_spd = 1 end
                    if r.ImGui_IsItemHovered(ctx) then
                        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_DownArrow(), false) then
                            Mc.LFO_spd = (Mc.LFO_spd or 1) / 2
                            ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed')
                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_UpArrow(), false) then
                            Mc.LFO_spd = (Mc.LFO_spd or 1) * 2
                            ChangeLFO(12, Mc.LFO_spd or 1, 9, 'LFO Speed')
                        end
                    end
                    gui_helpers.SL(nil, 30)


                    ---- Add Length slider
                    r.ImGui_Text(ctx, 'Length:')
                    gui_helpers.SL()
                    r.ImGui_SetNextItemWidth(ctx, 80)
                    local LengthBefore = Mc.LFO_leng
                    _, Mc.LFO_leng = r.ImGui_SliderInt(ctx, '##' .. 'Macro' .. i .. 'LFO Length',
                        Mc.LFO_leng or FxdCtx.LFO.Def.Len, 1, 8)
                    if r.ImGui_IsItemActive(ctx) then
                        tweaking = Macro
                        ChangeLFO(13, Mc.LFO_leng or FxdCtx.LFO.Def.Len, 9, 'LFO Length')
                    end
                    if r.ImGui_IsItemEdited(ctx) then
                        local Change = Mc.LFO_leng - LengthBefore

                        for i, _ in ipairs(Node) do
                            Node[i].x = Node[i].x / ((LengthBefore + Change) / LengthBefore)
                            if Node[i].ctrlX then
                                Node[i].ctrlX = Node[i].ctrlX / ((LengthBefore + Change) / LengthBefore)
                            end
                        end
                        LengthBefore = Mc.LFO_leng
                    end


                    ------ Add LFO Gain
                    gui_helpers.SL()
                    r.ImGui_Text(ctx, 'Gain')
                    gui_helpers.SL()
                    r.ImGui_SetNextItemWidth(ctx, 80)
                    local ShownV = math.floor((Mc.LFO_Gain or 0) * 100)

                    -- check if prm has been assigned automation
                    local AutoPrmIdx = table_helpers.tablefind(FxdCtx.Trk[TrkID].AutoPrms, 'Mod' .. Macro .. 'LFO Gain')


                    _, Mc.LFO_Gain = r.ImGui_DragDouble(ctx, '##' .. 'Macro' .. i .. 'LFO Gain',
                        Mc.LFO_Gain or 1, 0.01, 0, 1, ShownV .. '%%')
                    if r.ImGui_IsItemActive(ctx) then
                        tweaking = Macro
                        ChangeLFO(14, Mc.LFO_Gain, 9, 'LFO Gain')
                        if AutoPrmIdx then
                            r.TrackFX_SetParamNormalized(LT_Track, 0, 15 + AutoPrmIdx, Mc.LFO_Gain)
                        end
                    else
                        if AutoPrmIdx then
                            Mc.LFO_Gain = r.TrackFX_GetParamNormalized(LT_Track, 0, 15 + AutoPrmIdx)
                        end
                    end
                    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, '##LFO Gain menu' .. Macro)
                    end
                    if r.ImGui_BeginPopup(ctx, '##LFO Gain menu' .. Macro) then
                        tweaking = Macro
                        if r.ImGui_Selectable(ctx, 'Add Parameter to Envelope', false) then
                            AutomateModPrm(Macro, 'LFO Gain', 16, 'LFO ' .. Macro .. ' Gain')
                            r.TrackList_AdjustWindows(false)
                            r.UpdateArrange()
                        end

                        r.ImGui_EndPopup(ctx)
                    end



                    if Mc.Changing_Rel_Node then
                        Mc.Rel_Node = Mc.Changing_Rel_Node
                        ChangeLFO(20, Mc.Rel_Node, nil, 'LFO_Rel_Node')
                        Mc.Changing_Rel_Node = nil
                    end



                    if r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_RootAndChildWindows()) then
                        FxdCtx.LFO.WinHovered =
                            Macro -- this one doesn't get cleared after unhovering, to inform script which one to stay open
                        FxdCtx.LFO.HvringWin = Macro
                    else
                        FxdCtx.LFO.HvringWin = nil
                        FxdCtx.LFO.DontOpenNextFrame = true -- it's needed so the open_LFO_Win function doesn't get called twice when user 'unhover' the lfo window
                    end

                    if r.ImGui_IsWindowAppearing(ctx) then
                        Save_All_LFO_Info(Node)
                    end
                    if r.ImGui_IsWindowAppearing(ctx) then
                        Send_All_Coord()
                    end
                    r.ImGui_End(ctx)
                end


                if FxdCtx.LFO.OpenShapeSelect == Macro then
                    r.ImGui_SetNextWindowPos(ctx, L + FxdCtx.LFO.DummyW + 30, T - FxdCtx.LFO.DummyH - 200)
                    ShapeFilter = r.ImGui_CreateTextFilter(Shape_Filter_Txt)
                    r.ImGui_SetNextWindowSizeConstraints(ctx, 220, 150, 240, 700)
                    if r.ImGui_Begin(ctx, 'Shape Selection Popup', true, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_AlwaysAutoResize()) then
                        local W, H = 150, 75
                        local function DrawShapesInSelector(Shapes)
                            local AnyShapeHovered
                            for i, v in pairs(Shapes) do
                                --InvisiBtn(ctx, nil,nil, 'Shape'..i,  W, H)

                                if r.ImGui_TextFilter_PassFilter(ShapeFilter, v.Name) then
                                    r.ImGui_Text(ctx, v.Name or i)

                                    --reaper.ImGui_SetCursorPosX( ctx, - 15 )
                                    local L, T = r.ImGui_GetItemRectMin(ctx)
                                    if r.ImGui_IsMouseHoveringRect(ctx, L, T, L + 200, T + 10) then
                                        gui_helpers.SL(W - 8)

                                        if images_fonts.TrashIcon(8, 'delete' .. (v.Name or i), 0xffffff00) then
                                            r.ImGui_OpenPopup(ctx, 'Delete shape prompt' .. i)
                                            r.ImGui_SetNextWindowPos(ctx, L, T)
                                        end
                                    end

                                    if r.ImGui_Button(ctx, '##' .. (v.Name or i) .. i, W, H) then
                                        Mc.Node = v
                                        FxdCtx.LFO.NewShapeChosen = v
                                    end
                                    if r.ImGui_IsItemHovered(ctx) then
                                        Mc.Node = v
                                        AnyShapeHovered = true
                                        FxdCtx.LFO.AnyShapeHovered = true
                                        Send_All_Coord()
                                    end
                                    local L, T = r.ImGui_GetItemRectMin(ctx)
                                    local w, h = r.ImGui_GetItemRectSize(ctx)
                                    r.ImGui_DrawList_AddRectFilled(WDL, L, T, L + w, T + h, 0xffffff33)
                                    r.ImGui_DrawList_AddRect(WDL, L, T, L + w, T + h, 0xffffff66)

                                    DrawShape(v, L, w, h, T, 0xffffffaa)
                                end
                                if r.ImGui_BeginPopupModal(ctx, 'Delete shape prompt' .. i, true, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()|r.ImGui_WindowFlags_AlwaysAutoResize()) then
                                    r.ImGui_Text(ctx, 'Confirm deleting this shape:')
                                    if r.ImGui_Button(ctx, 'yes') or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Y()) or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) then
                                        FxdCtx.LFO.DeleteShape = i
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                    gui_helpers.SL()
                                    if r.ImGui_Button(ctx, 'No') or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_N()) or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                    r.ImGui_EndPopup(ctx)
                                end
                            end
                            if FxdCtx.LFO.AnyShapeHovered then -- if any shape was hovered
                                if not AnyShapeHovered then    -- if 'unhovered'
                                    if FxdCtx.LFO.NewShapeChosen then
                                        local V = FxdCtx.LFO.NewShapeChosen
                                        Mc.Node = V                            ---keep newly selected shape
                                    else
                                        Mc.Node = FxdCtx.LFO.NodeBeforePreview -- restore original shape
                                        NeedSendAllGmemLater = Macro
                                    end
                                    FxdCtx.LFO.NodeBeforePreview = Mc.Node
                                    FxdCtx.LFO.AnyShapeHovered = nil
                                    FxdCtx.LFO.NewShapeChosen = nil
                                end
                            end


                            return AnyShapeHovered
                        end

                        if NeedSendAllGmemLater == Macro then
                            Timer = (Timer or 0) + 1
                            if Timer == 2 then
                                Send_All_Coord()
                                NeedSendAllGmemLater = nil
                                Timer = nil
                            end
                        end

                        local function Global_Shapes()
                            if r.ImGui_IsWindowAppearing(ctx) then
                                FxdCtx.LFO.NodeBeforePreview = Mc.Node
                            end

                            Shapes = {}



                            local F = fs_utils.scandir(fs_utils.ConcatPath(CurrentDirectory, 'src', 'LFO Shapes'))


                            for _, v in ipairs(F) do
                                local Shape = Get_LFO_Shape_From_File(v)
                                if Shape then
                                    Shape.Name = tostring(v):sub(0, -5)
                                    table.insert(Shapes, Shape)
                                end
                            end


                            if FxdCtx.LFO.DeleteShape then
                                os.remove(fs_utils.ConcatPath(CurrentDirectory, 'src', 'LFO Shapes',
                                    Shapes[FxdCtx.LFO.DeleteShape].Name .. '.ini'))
                                table.remove(Shapes, FxdCtx.LFO.DeleteShape)
                                FxdCtx.LFO.DeleteShape = nil
                            end

                            if r.ImGui_TextFilter_Draw(ShapeFilter, ctx, '##PrmFilterTxt', -1) then
                                Shape_Filter_Txt = r.ImGui_TextFilter_Get(ShapeFilter)
                                r.ImGui_TextFilter_Set(ShapeFilter, Shape_Filter_Txt)
                            end




                            AnyShapeHovered = DrawShapesInSelector(Shapes)










                            if r.ImGui_IsWindowFocused(ctx) and r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
                                r.ImGui_CloseCurrentPopup(ctx)
                                FxdCtx.LFO.OpenShapeSelect = nil
                            end
                        end


                        local function Save_Shape_To_Track()
                            local HowManySavedShapes = state_helpers.GetTrkSavedInfo('LFO Saved Shape Count')

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
                        local function Save_Shape_To_Project()
                            local HowManySavedShapes = state_helpers.getProjSavedInfo('LFO Saved Shape Count')

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

                        local function Track_Shapes()
                            local Shapes = {}
                            local HowManySavedShapes = state_helpers.GetTrkSavedInfo('LFO Saved Shape Count')


                            for I = 1, HowManySavedShapes or 0, 1 do
                                local Shape = {}
                                local Ct = state_helpers.GetTrkSavedInfo('Shape' .. I .. 'LFO Node Count = ')

                                for i = 1, Ct or 1, 1 do
                                    Shape[i] = Shape[i] or {}
                                    Shape[i].x = state_helpers.GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'x = ')
                                    Shape[i].y = state_helpers.GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. 'y = ')
                                    Shape[i].ctrlX = state_helpers.GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlX = ')
                                    Shape[i].ctrlY = state_helpers.GetTrkSavedInfo('Shape' .. I .. 'Node ' .. i .. '.ctrlY = ')
                                end
                                if Shape[1] then
                                    table.insert(Shapes, Shape)
                                end
                            end

                            if FxdCtx.LFO.DeleteShape then
                                local Count = state_helpers.GetTrkSavedInfo('LFO Saved Shape Count')
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: LFO Saved Shape Count', Count - 1,
                                    true)
                                table.remove(Shapes, FxdCtx.LFO.DeleteShape)

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
                                FxdCtx.LFO.DeleteShape = nil
                            end

                            DrawShapesInSelector(Shapes)
                        end
                        local function Proj_Shapes()
                            local Shapes = {}
                            local HowManySavedShapes = state_helpers.getProjSavedInfo('LFO Saved Shape Count')

                            for I = 1, HowManySavedShapes or 0, 1 do
                                local Shape = {}
                                local Ct = state_helpers.getProjSavedInfo('LFO Shape' .. I .. 'Node Count = ')
                                for i = 1, Ct or 1, 1 do
                                    Shape[i] = Shape[i] or {}
                                    Shape[i].x = state_helpers.getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'x = ')
                                    Shape[i].y = state_helpers.getProjSavedInfo('LFO Shape' .. I .. 'Node ' .. i .. 'y = ')
                                    Shape[i].ctrlX = state_helpers.getProjSavedInfo('LFO Shape' .. I ..
                                        'Node ' .. i .. '.ctrlX = ')
                                    Shape[i].ctrlY = state_helpers.getProjSavedInfo('LFO Shape' .. I ..
                                        'Node ' .. i .. '.ctrlY = ')
                                end
                                if Shape[1] then
                                    table.insert(Shapes, Shape)
                                end
                            end

                            if FxdCtx.LFO.DeleteShape then
                                local Count = state_helpers.getProjSavedInfo('LFO Saved Shape Count')
                                r.SetProjExtState(0, 'FX Devices', 'LFO Saved Shape Count', Count - 1)
                                table.remove(Shapes, FxdCtx.LFO.DeleteShape)

                                for I, V in ipairs(Shapes) do -- do for every shape
                                    for i, v in ipairs(V) do  --- do for every node
                                        if i == 1 then
                                            r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I ..
                                                'Node Count = ', #V)
                                        end

                                        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I ..
                                            'Node ' .. i .. 'x = ', v.x or '')
                                        r.SetProjExtState(0, 'FX Devices', 'LFO Shape' .. I ..
                                            'Node ' .. i .. 'y = ', v.y or '')

                                        r.SetProjExtState(0, 'FX Devices',
                                            'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlX = ', v.ctrlX or '')
                                        r.SetProjExtState(0, 'FX Devices',
                                            'LFO Shape' .. I .. 'Node ' .. i .. '.ctrlY = ', v.ctrlY or '')
                                    end
                                end
                                FxdCtx.LFO.DeleteShape = nil
                            end

                            DrawShapesInSelector(Shapes)
                        end

                        if r.ImGui_ImageButton(ctx, '## save' .. Macro, Img.Save, 12, 12, nil, nil, nil, nil, ClrBG, ClrTint) then
                            if FxdCtx.LFO.OpenedTab == 'Global' then
                                FxdCtx.LFO.OpenSaveDialog = Macro
                            elseif FxdCtx.LFO.OpenedTab == 'Project' then
                                Save_Shape_To_Project()
                            elseif FxdCtx.LFO.OpenedTab == 'Track' then
                                Save_Shape_To_Track()
                            end
                        end
                        gui_helpers.SL()
                        r.ImGui_AlignTextToFramePadding(ctx)


                        if r.ImGui_BeginTabBar(ctx, 'shape select tab bar') then
                            if r.ImGui_BeginTabItem(ctx, 'Global') then
                                Global_Shapes()
                                FxdCtx.LFO.OpenedTab = 'Global'
                                r.ImGui_EndTabItem(ctx)
                            end

                            if r.ImGui_BeginTabItem(ctx, 'Project') then
                                Proj_Shapes()
                                FxdCtx.LFO.OpenedTab = 'Project'
                                r.ImGui_EndTabItem(ctx)
                            end

                            if r.ImGui_BeginTabItem(ctx, 'Track') then
                                Track_Shapes()
                                FxdCtx.LFO.OpenedTab = 'Track'
                                r.ImGui_EndTabItem(ctx)
                            end

                            r.ImGui_EndTabBar(ctx)
                        end

                        if r.ImGui_IsWindowHovered(ctx, r.ImGui_FocusedFlags_RootAndChildWindows()) then
                            FxdCtx.LFO.HoveringShapeWin = Macro
                        else
                            FxdCtx.LFO.HoveringShapeWin = nil
                        end
                        r.ImGui_End(ctx)
                    end
                end






                return tweaking, All_Coord
            end

            local HvrOnBtn = r.ImGui_IsItemHovered(ctx)
            local PinID = TrkID .. 'Macro = ' .. Macro
            if HvrOnBtn or FxdCtx.LFO.HvringWin == Macro or FxdCtx.LFO.Tweaking == Macro or FxdCtx.LFO.Pin == PinID or FxdCtx.LFO.OpenSaveDialog == Macro or FxdCtx.LFO.HoveringShapeWin == Macro then
                FxdCtx.LFO.notHvrTime = 0
                FxdCtx.LFO.Tweaking = Open_LFO_Win(Track, Macro)
                FxdCtx.LFO.WinHovered = Macro
            end

            --- open window for 10 more frames after mouse left window or btn
            if FxdCtx.LFO.WinHovered == Macro and not HvrOnBtn and not FxdCtx.LFO.HvringWin and not FxdCtx.LFO.Tweaking and not FxdCtx.LFO.DontOpenNextFrame then
                FxdCtx.LFO.notHvrTime = FxdCtx.LFO.notHvrTime + 1

                if FxdCtx.LFO.notHvrTime > 0 and FxdCtx.LFO.notHvrTime < 10 then
                    Open_LFO_Win(Track, Macro)
                else
                    FxdCtx.LFO.notHvrTime = 0
                    FxdCtx.LFO.WinHovered = nil
                end
            end
            FxdCtx.LFO.DontOpenNextFrame = nil





            if not IsLBtnHeld then
                LFO_DragDir = nil
                LFO_MsX_Start, LFO_MsY_Start = nil
            end

            --[[ if Mc.All_Coord then
                        if TrkID ~= TrkID_End and TrkID_End ~= nil and Sel_Track_FX_Count > 0 then
                            for i  , v in ipairs(Mc.All_Coord.X) do
                                msg(i)
                                r.gmem_write(4, 15) -- mode 15 tells jsfx to retrieve all coordinates
                                r.gmem_write(5, Macro)
                                r.gmem_write(6, #Mc.Node*11)
                                r.gmem_write(1000+i, v)
                                r.gmem_write(2000+i, Mc.All_Coord.Y[i])
                            end
                        end
                    end ]]



            ---- this part draws modulation histogram (Deprecated)
            --[[  local MOD = math.abs(SetMinMax(r.gmem_read(100 + i) / 127, -1, 1))
                    Mc.StepV = Mc.StepV or {}
                    table.insert(Mc.StepV, MOD* Mc.Gain * 4)

                    if #Mc.StepV > W then
                        table.remove(Mc.StepV, 1)
                    end
                    for s = 0, W, G do
                        local last = SetMinMax(s - 1, 0, W)
                        r.ImGui_DrawList_AddLine(WDL, L + s, T + H - (Mc.StepV[last] or 0), L + s + G,
                            T + H - (Mc.StepV[s] or 0), EightColors.LFO[i], 2)
                        --r.ImGui_DrawList_PathLineTo(WDL, L+s,  Y_Mid+math.sin(s/Mc.Freq) * Mc.Gain)
                    end ]]
            if FxdCtx.LFO.OpenSaveDialog == Macro then
                r.ImGui_OpenPopup(ctx, 'Decide Name')
                r.ImGui_SetNextWindowPos(ctx, L, T - FxdCtx.LFO.DummyH)
                r.ImGui_SetNextWindowFocus(ctx)

                if r.ImGui_BeginPopupModal(ctx, 'Decide Name', true, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_AlwaysAutoResize()) then
                    r.ImGui_Text(ctx, 'Enter a name for the shape: ')
                    --[[ r.ImGui_Text(ctx, '(?)')
                            if r.ImGui_IsItemHovered(ctx) then
                                tooltip('use / in file name to save into sub-directories')
                            end ]]

                    r.ImGui_SetNextItemWidth(ctx, FxdCtx.LFO.Def.DummyW)
                    r.ImGui_SetKeyboardFocusHere(ctx)
                    local _, buf = r.ImGui_InputText(ctx, buf or '##Name', buf)
                    r.ImGui_Button(ctx, 'Enter')
                    if r.ImGui_IsItemClicked(ctx) or (r.ImGui_IsItemFocused(ctx) and r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) and Mods == 0) then
                        local LFO_Name = buf
                        local path = fs_utils.ConcatPath(CurrentDirectory, 'src', 'LFO Shapes')
                        local file_path = fs_utils.ConcatPath(path, LFO_Name .. '.ini')
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

                        FxdCtx.LFO.OpenSaveDialog = nil
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                    gui_helpers.SL()
                    r.ImGui_Button(ctx, 'Cancel (Esc)')
                    if r.ImGui_IsItemClicked(ctx) or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
                        r.ImGui_CloseCurrentPopup(ctx)
                        FxdCtx.LFO.OpenSaveDialog = nil
                    end



                    r.ImGui_EndPopup(ctx)
                end
            end
        end




        --check if there's envelope
        --[[  IsThereEnvOnMacro[i] = r.GetFXEnvelope(LT_Track, 0, i-1, false)
                    Str_IsThereEnvOnMacro = tostring(IsThereEnvOnMacro[i])
                    if Str_IsThereEnvOnMacro ~= 'nil'  then     --if theres env on macros, Sync Macro on Gui to Actual Values

                        Mc.Val_Trk[MacroValueLBL]= r.TrackFX_GetParamNormalized( LT_Track, 0, i-1  )
                        PosX_Left, PosY_Top = r.ImGui_GetItemRectMin(ctx)
                        Array_Parameter.PosX_Left[i]=PosX_Left
                        Array_Parameter.PosY_Top[i]=PosY_Top
                        drawlist=r.ImGui_GetForegroundDrawList(ctx)
                        MacroColor= 'Macro'..i..'Color'
                        r.ImGui_DrawList_AddCircleFilled(drawlist, Array_Parameter.PosX_Left[i], Array_Parameter.PosY_Top[i],4,_G[MacroColor])
                    else IsThereEnvOnMacro[i]=0
                    end ]]
        local function SetTypeToEnv()
            if r.ImGui_Selectable(ctx, 'Set Type to Envelope', false) then
                FxdCtx.Trk[TrkID].Mod[i].Type = 'env'
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'env', true)
                r.gmem_write(4, 4) -- tells jsfx macro type = env
                r.gmem_write(5, i) -- tells jsfx which macro
            end
        end

        local function SetTypeToStepSEQ()
            if r.ImGui_Selectable(ctx, 'Set Type to Step Sequencer', false) then
                FxdCtx.Trk[TrkID].Mod[i].Type = 'Step'
                r.gmem_write(4, 6) -- tells jsfx macro type = step seq
                r.gmem_write(5, i)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Step', true)
                FxdCtx.Trk[TrkID].SEQL = FxdCtx.Trk[TrkID].SEQL or {}
                FxdCtx.Trk[TrkID].SEQ_Dnom = FxdCtx.Trk[TrkID].SEQ_Dnom or {}
                FxdCtx.Trk[TrkID].SEQL[i] = FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
                FxdCtx.Trk[TrkID].SEQ_Dnom[i] = FxdCtx.Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom

                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length',
                    FxdCtx.Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, true)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                    FxdCtx.Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom, true)

                if I.Name == 'Env ' .. i or I.Name == 'Macro ' .. i then I.Name = 'Step ' .. i end
            end
        end

        local function SetTypeToFollower()
            if r.ImGui_Selectable(ctx, 'Set Type to Audio Follower', false) then
                r.gmem_write(4, 9) -- tells jsfx macro type = Follower
                r.gmem_write(5, i) -- tells jsfx which macro
                FxdCtx.Trk[TrkID].Mod[i].Type = 'Follower'
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Follower', true)
            end
        end
        local function SetTypeToMacro()
            if r.ImGui_Selectable(ctx, 'Set Type to Macro', false) then
                FxdCtx.Trk[TrkID].Mod[i].Type = 'Macro'
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Macro', true)
                r.gmem_write(4, 5) -- tells jsfx macro type = Macro
                r.gmem_write(5, i) -- tells jsfx which macro
                if I.Name == 'Env ' .. i then I.Name = 'Macro ' .. i end
            end
        end
        local function SetTypeToLFO()
            if r.ImGui_Selectable(ctx, 'Set Type to LFO', false) then
                FxdCtx.Trk[TrkID].Mod[i].Type = 'LFO'
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'LFO', true)
                r.gmem_write(4, 12) -- tells jsfx macro type = LFO
                r.gmem_write(5, i)  -- tells jsfx which macro
                I.Name = 'LFO ' .. i
            end
        end

        if r.ImGui_BeginPopup(ctx, 'Macro' .. i .. 'Menu') then
            if r.ImGui_Selectable(ctx, 'Automate', false) then
                GF.AddMacroJSFX()
                -- Show Envelope for Morph Slider
                local env = r.GetFXEnvelope(LT_Track, 0, i - 1, false)  -- Check if envelope is on
                if env == nil then                                      -- Envelope is off
                    local _ = r.GetFXEnvelope(LT_Track, 0, i - 1, true) -- true = Create envelope
                else                                                    -- Envelope is on
                    local _, EnvelopeStateChunk = r.GetEnvelopeStateChunk(env, "", false)
                    if string.find(EnvelopeStateChunk, "VIS 1") then    -- VIS 1 = visible, VIS 0 = invisible
                        EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 1", "VIS 0")
                        r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                    else -- on but invisible
                        EnvelopeStateChunk = string.gsub(EnvelopeStateChunk, "VIS 0", "VIS 1")
                        r.SetEnvelopeStateChunk(env, EnvelopeStateChunk, false)
                    end
                end
                SetPrmAlias(LT_TrackNum, 1, i, FxdCtx.Trk[TrkID].Mod[i].Name or ('Macro' .. i)) -- Change parameter name to alias
                r.TrackList_AdjustWindows(false)
                r.UpdateArrange()
            end
            SetTypeToEnv()
            SetTypeToStepSEQ()
            SetTypeToFollower()
            SetTypeToLFO()
            r.ImGui_EndPopup(ctx)
        elseif r.ImGui_BeginPopup(ctx, 'Env' .. i .. 'Menu') then
            SetTypeToMacro()
            SetTypeToStepSEQ()
            SetTypeToFollower()
            SetTypeToLFO()
            r.ImGui_EndPopup(ctx)
        elseif r.ImGui_BeginPopup(ctx, 'Step' .. i .. 'Menu') then
            SetTypeToMacro()
            SetTypeToEnv()
            SetTypeToFollower()
            SetTypeToLFO()
            r.ImGui_EndPopup(ctx)
        elseif r.ImGui_BeginPopup(ctx, 'Follower' .. i .. 'Menu') then
            SetTypeToMacro()
            SetTypeToEnv()
            SetTypeToStepSEQ()
            SetTypeToLFO()
            r.ImGui_EndPopup(ctx)
        elseif r.ImGui_BeginPopup(ctx, 'LFO' .. i .. 'Menu') then
            SetTypeToMacro()
            SetTypeToEnv()
            SetTypeToStepSEQ()
            SetTypeToFollower()
            r.ImGui_EndPopup(ctx)
        end


        r.ImGui_PopID(ctx)
    end

    if not FX_Dvs_BgDL then FX_Dvs_BgDL = r.ImGui_GetWindowDrawList(ctx) end
    r.ImGui_PopStyleColor(ctx, 1)
    r.ImGui_EndTable(ctx)
end

return MacrosTable
