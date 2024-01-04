local GF = require("src.Functions.General Functions")
---I'm moving all unused functions to this file.
---This is just to make sure I'm not deleting anything we might need later.
local deadCode = {}

function deadCode.DrawChildMenu(tbl, path, FX_Idx)
    path = path or ""
    for i = 1, #tbl do
        if tbl[i].dir then
            if r.ImGui_BeginMenu(ctx, tbl[i].dir) then
                deadCode.DrawChildMenu(tbl[i], table.concat({ path, Os_separator, tbl[i].dir }), FX_Idx)
                r.ImGui_EndMenu(ctx)
            end
        end
        if type(tbl[i]) ~= "table" then
            if r.ImGui_Selectable(ctx, tbl[i], false) then -- TODO for all calls to ImGui_Selectable, let’s pass the third argument as false instead of nil
                if TRACK then
                    r.TrackFX_AddByName(TRACK, table.concat({ path, Os_separator, tbl[i] }), false,
                        -1000 - FX_Idx)
                end
            end
        end
    end
end

function deadCode.ConverCtrlNodeY(lastY, Y)
    local Range = (math.max(lastY, Y) - math.min(lastY, Y))
    local NormV = (math.min(lastY, Y) + Range - Y) / Range
    local Bipolar = -1 + (NormV) * 2
    return NormV
end

function deadCode.AddProp(ShownName, Name, width, sl, defaultV, stepSize,
                          min, max, format)
    if ShownName then
        r.ImGui_Text(ctx, ShownName)
        GF.SL()
    end
    if width then r.ImGui_SetNextItemWidth(ctx, width) end
    local FORMAT = format
    if not D[Name] and not defaultV then FORMAT = '' end

    local rv, V = r.ImGui_DragDouble(ctx, '##' .. Name .. LBL,
        D[Name] or defaultV, stepSize or FxdCtx.LE.GridSize, min or -W,
        max or W - 10, FORMAT)

    if rv then D[Name] = V end
    if sl then GF.SL() end
    return r.ImGui_IsItemActive(ctx)
end

function deadCode.AddRatio(Name)
    r.ImGui_TableSetColumnIndex(ctx, 3)
    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
    local v = (D[Name] or 1) / (FrstSelItm.Sldr_W or 160)
    local rv, V = r.ImGui_DragDouble(ctx, '##' .. Name .. ' ratio', v,
        0.001, 0, 100, '%.2f')
    r.ImGui_TableNextRow(ctx)
    if rv then return rv, V * (FrstSelItm.Sldr_W or 160) end
end

function deadCode.f_trafo(freq)
    return math.exp((1 - freq) * math.log(20 / 22050))
end

return deadCode
