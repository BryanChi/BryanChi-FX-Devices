---I'm moving all unused functions to this file.
---This is just to make sure I'm not deleting anything we might need later.
local deadCode = {}

function deadCode.DrawChildMenu(tbl, path, FX_Idx)
    path = path or ""
    for i = 1, #tbl do
        if tbl[i].dir then
            if r.ImGui_BeginMenu(ctx, tbl[i].dir) then
                deadCode.DrawChildMenu(tbl[i], table.concat({ path, os_separator, tbl[i].dir }), FX_Idx)
                r.ImGui_EndMenu(ctx)
            end
        end
        if type(tbl[i]) ~= "table" then
            if r.ImGui_Selectable(ctx, tbl[i], false) then -- TODO for all calls to ImGui_Selectable, let’s pass the third argument as false instead of nil
                if TRACK then
                    r.TrackFX_AddByName(TRACK, table.concat({ path, os_separator, tbl[i] }), false,
                        -1000 - FX_Idx)
                end
            end
        end
    end
end

return deadCode
