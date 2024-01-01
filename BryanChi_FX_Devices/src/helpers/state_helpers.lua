local state_helpers = {}

function state_helpers.DeleteAllParamOfFX(FXGUID, TrkID)
    for p, _ in pairs(FxdCtx.Trk.Prm.FXGUID) do
        if FxdCtx.Trk.Prm.FXGUID[p] == FXGUID and FXGUID ~= nil then
            FxdCtx.Trk.Prm.Inst[TrkID] = FxdCtx.Trk.Prm.Inst[TrkID] - 1
            FxdCtx.Prm.Num[p] = nil
            FxdCtx.PM.HasMod[p] = nil

            r.SetProjExtState(0, 'FX Devices', 'Params fxGUID of Param Inst' .. p, '')
        elseif FxdCtx.Trk.Prm.FXGUID[p] == nil and FXGUID == nil then

        end
    end
end

---@param LT_Track MediaTrack
---@param FX_Idx integer
function state_helpers.ToggleBypassFX(LT_Track, FX_Idx)
    FxdCtx.FX.Enable = FxdCtx.FX.Enable or {}
    FxdCtx.FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
    if FxdCtx.FX.Enable[FX_Idx] == true then
        r.TrackFX_SetEnabled(LT_Track, FX_Idx, false)
    elseif FxdCtx.FX.Enable[FX_Idx] == false then
        r.TrackFX_SetEnabled(LT_Track, FX_Idx, true)
    end
end


return state_helpers
