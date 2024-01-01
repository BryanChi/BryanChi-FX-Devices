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

return gui_helpers
