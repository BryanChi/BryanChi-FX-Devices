local state_heplers = {}

function state_heplers.DeleteAllParamOfFX(FXGUID, TrkID)
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

return state_heplers
