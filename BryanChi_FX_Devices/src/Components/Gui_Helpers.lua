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

return  gui_helpers 
