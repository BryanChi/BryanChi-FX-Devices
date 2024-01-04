local gui_helpers = {}
--
---@param A string text for tooltip
function gui_helpers.tooltip(A)
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_SetTooltip(ctx, A)
    r.ImGui_EndTooltip(ctx)
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


return gui_helpers
