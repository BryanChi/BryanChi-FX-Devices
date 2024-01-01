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

function state_helpers.GetTrkSavedInfo(str, track, type)
    if type == 'str' then
        local o = select(2, r.GetSetMediaTrackInfo_String(track or LT_Track, 'P_EXT: ' .. str, '', false))
        if o == '' then o = nil end
        return o
    else
        return tonumber(select(2, r.GetSetMediaTrackInfo_String(track or LT_Track, 'P_EXT: ' .. str, '', false)))
    end
end

function state_helpers.getProjSavedInfo(str, type)
    if type == 'str' then
        return select(2, r.GetProjExtState(0, 'FX Devices', str))
    else
        return tonumber(select(2, r.GetProjExtState(0, 'FX Devices', str)))
    end
end

function state_helpers.GetLTParam()
    LT_Track = r.GetLastTouchedTrack()
    Retval, LT_Prm_TrackNum, LT_FXNum, LT_ParamNum = r.GetLastTouchedFX()
    --GetTrack_LT_Track = r.GetTrack(0,LT_TrackNum)

    if LT_Track ~= nil then
        Retval, LT_FXName = r.TrackFX_GetFXName(LT_Track, LT_FXNum)
        Retval, LT_ParamName = r.TrackFX_GetParamName(LT_Track, LT_FXNum, LT_ParamNum)
    end
end

function state_helpers.GetLT_FX_Num()
    Retval, LT_Prm_TrackNum, LT_FX_Number, LT_ParamNum = r.GetLastTouchedFX()
    LT_Track = r.GetLastTouchedTrack()
end

---@generic T
---@param v? T
---@return boolean
function state_helpers.toggle(v)
    if v then v = false else v = true end
    return v
end

function state_helpers.toggle2(a, b)
    if a == b then return nil else return b end
end

---@param FX_Idx integer
---@return integer|nil
function state_helpers.ToggleCollapseAll(FX_Idx)
    -- check if all are collapsed
    local All_Collapsed
    for i = 0, Sel_Track_FX_Count - 1, 1 do
        if not FxdCtx.FX[FxdCtx.FXGUID[i]].Collapse then All_Collapsed = false end
    end
    if All_Collapsed == false then
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            FxdCtx.FX[FxdCtx.FXGUID[i]].Collapse = true
        end
    else -- if all is collapsed
        for i = 0, Sel_Track_FX_Count - 1, 1 do
            FxdCtx.FX[FxdCtx.FXGUID[i]].Collapse = false
            FxdCtx.FX.WidthCollapse[FxdCtx.FXGUID[i]] = nil
        end
        BlinkFX = FX_Idx
    end
    return BlinkFX
end

return state_helpers
