local images_fonts = require("src.helpers.images_fonts")
local gui_helpers = {}
---@param A string text for tooltip
function gui_helpers.tooltip(A)
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_SetTooltip(ctx, A)
    r.ImGui_EndTooltip(ctx)
end

---This is a duplicate of General Function's getClr.
--I'm having to leave it in here to avoid circular dependencies.
---@param f integer
---@return integer
function gui_helpers.getClr(f)
    return r.ImGui_GetStyleColor(ctx, f)
end

---@param A string text for tooltip
function gui_helpers.HintToolTip(A)
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_SetTooltip(ctx, A)
    r.ImGui_EndTooltip(ctx)
end

function gui_helpers.InvisiBtn(ctx, x, y, str, w, h)
    if x and y then
        r.ImGui_SetCursorScreenPos(ctx, x, y)
    end
    local rv = r.ImGui_InvisibleButton(ctx, str, w, h or w)


    return rv
end

---@param text string
---@param font? ImGui_Font
---@param color? number rgba
---@param WrapPosX? number
function gui_helpers.MyText(text, font, color, WrapPosX)
    if WrapPosX then r.ImGui_PushTextWrapPos(ctx, WrapPosX) end

    if font then r.ImGui_PushFont(ctx, font) end
    if color then
        r.ImGui_TextColored(ctx, color, text)
    else
        r.ImGui_Text(ctx, text)
    end

    if font then r.ImGui_PopFont(ctx) end
    if WrapPosX then r.ImGui_PopTextWrapPos(ctx) end
end

---Same Line
---@param xpos? number offset_from_start_xIn
---@param pad? number spacingIn
function gui_helpers.SL(xpos, pad)
    r.ImGui_SameLine(ctx, xpos, pad)
end

---@param FillClr number
---@param OutlineClr number
---@param Padding number
---@param L number
---@param T number
---@param R number
---@param B number
---@param h number
---@param w number
---@param H_OutlineSc any
---@param V_OutlineSc any
---@param GetItemRect "GetItemRect"|nil
---@param Foreground? ImGui_DrawList
---@param rounding? number
---@return number|nil L
---@return number|nil T
---@return number|nil R
---@return number|nil B
---@return number|nil w
---@return number|nil h
function gui_helpers.HighlightSelectedItem(FillClr, OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                                           GetItemRect,
                                           Foreground, rounding, thick)
    if GetItemRect == 'GetItemRect' or L == 'GetItemRect' then
        L, T = r.ImGui_GetItemRectMin(ctx)
        R, B = r.ImGui_GetItemRectMax(ctx)
        w, h = r.ImGui_GetItemRectSize(ctx)
        --Get item rect
    end
    local P = Padding or 0
    local HSC = H_OutlineSc or 4
    local VSC = V_OutlineSc or 4
    if Foreground == 'Foreground' then WinDrawList = FxdCtx.Glob.FDL else WinDrawList = Foreground end
    if not WinDrawList then WinDrawList = r.ImGui_GetWindowDrawList(ctx) end
    if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr) end

    local h = h or B - T
    local w = w or R - L

    if OutlineClr and not rounding then
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P, T + h / VSC - P, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P, T + h / VSC - P, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P, B + P - h / VSC, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P, B - h / VSC + P, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P + w / HSC, T - P, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P - w / HSC, T - P, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P + w / HSC, B + P, OutlineClr, thick)
        r.ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P - w / HSC, B + P, OutlineClr, thick)
    else
        if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr, rounding) end
        if OutlineClr then r.ImGui_DrawList_AddRect(WinDrawList, L, T, R, B, OutlineClr, rounding) end
    end
    if GetItemRect == 'GetItemRect' then return L, T, R, B, w, h end
end

function gui_helpers.DndAddFX_SRC(fx)
    if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptBeforeDelivery()) then
        r.ImGui_SetDragDropPayload(ctx, 'DND ADD FX', fx)
        r.ImGui_Text(ctx, fx)
        r.ImGui_EndDragDropSource(ctx)
    end
end

function gui_helpers.QuestionHelpHint(Str)
    if r.ImGui_IsItemHovered(ctx) then
        gui_helpers.SL()
        r.ImGui_TextColored(ctx, 0x99999977, '(?)')
        if r.ImGui_IsItemHovered(ctx) then
            gui_helpers.HintToolTip(Str)
        end
    end
end

function gui_helpers.Highlight_Itm(WDL, FillClr, OutlineClr)
    local L, T = r.ImGui_GetItemRectMin(ctx)

    local R, B = r.ImGui_GetItemRectMax(ctx)

    if FillClr then r.ImGui_DrawList_AddRectFilled(WDL, L, T, R, B, FillClr, rounding) end
    if OutlineClr then r.ImGui_DrawList_AddRect(WDL, L, T, R, B, OutlineClr, rounding) end
end

---@param dur number
---@param rpt integer
---@param var integer | nil
---@param highlightEdge? any -- TODO is this a number?
---@param EdgeNoBlink? "EdgeNoBlink"
---@param L number
---@param T number
---@param R number
---@param B number
---@param h number
---@param w number
---@return nil|integer var
---@return string|nil "Stop"
function gui_helpers.BlinkItem(dur, rpt, var, highlightEdge, EdgeNoBlink, L, T, R, B, h, w)
    TimeBegin = TimeBegin or r.time_precise()
    local Now = r.time_precise()
    local EdgeClr = 0x00000000
    if highlightEdge then EdgeClr = highlightEdge end
    local GetItemRect = 'GetItemRect' ---@type string | nil
    if L then GetItemRect = nil end

    if rpt then
        for i = 0, rpt - 1, 1 do
            if Now > TimeBegin + dur * i and Now < TimeBegin + dur * (i + 0.5) then -- second blink
                gui_helpers.HighlightSelectedItem(0xffffff77, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    GetItemRect,
                    Foreground)
            end
        end
    else
        if Now > TimeBegin and Now < TimeBegin + dur / 2 then
            gui_helpers.HighlightSelectedItem(0xffffff77, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                GetItemRect,
                Foreground)
        elseif Now > TimeBegin + dur / 2 + dur then
            TimeBegin = r.time_precise()
        end
    end

    if EdgeNoBlink == 'EdgeNoBlink' then
        if Now < TimeBegin + dur * (rpt - 0.95) then
            gui_helpers.HighlightSelectedItem(0xffffff00, EdgeClr, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                GetItemRect,
                Foreground)
        end
    end

    if rpt then
        if Now > TimeBegin + dur * (rpt - 0.95) then
            TimeBegin = nil
            return nil, 'Stop'
        else
            return var, nil
        end
    end
end

---@param w number
---@param h number
---@param icon string
---@param BGClr? number
---@param center? string
---@param Identifier? string
---@return boolean|nil
function gui_helpers.IconBtn(w, h, icon, BGClr, center, Identifier) -- Y = wrench
    r.ImGui_PushFont(ctx, images_fonts.FontAwesome)
    if r.ImGui_InvisibleButton(ctx, icon .. (Identifier or ''), w, h) then
    end
    local FillClr
    local IcnClr
    if r.ImGui_IsItemActive(ctx) then
        FillClr = gui_helpers.getClr(r.ImGui_Col_ButtonActive())
        IcnClr = gui_helpers.getClr(r.ImGui_Col_TextDisabled())
    elseif r.ImGui_IsItemHovered(ctx) then
        FillClr = gui_helpers.getClr(r.ImGui_Col_ButtonHovered())
        IcnClr = gui_helpers.getClr(r.ImGui_Col_Text())
    else
        FillClr = gui_helpers.getClr(r.ImGui_Col_Button())
        IcnClr = gui_helpers.getClr(r.ImGui_Col_Text())
    end
    if BGClr then FillClr = BGClr end

    L, T, R, B, W, H = gui_helpers.HighlightSelectedItem(FillClr, 0x00000000, 0, L, T, R, B, h, w, H_OutlineSc,
        V_OutlineSc,
        'GetItemRect', Foreground)
    TxtSzW, TxtSzH = r.ImGui_CalcTextSize(ctx, icon)
    if center == 'center' then
        r.ImGui_DrawList_AddText(WDL, L + W / 2 - TxtSzW / 2, T - H / 2 - 1, IcnClr, icon)
    else
        r.ImGui_DrawList_AddText(WDL, L + 3, T - H / 2, IcnClr, icon)
    end
    r.ImGui_PopFont(ctx)
    if r.ImGui_IsItemActivated(ctx) then return true end
end

return gui_helpers
