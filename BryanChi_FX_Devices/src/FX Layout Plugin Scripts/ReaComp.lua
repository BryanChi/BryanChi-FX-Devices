-- @noindex



r = reaper

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid

FX[FxGUID].Compatible_W_regular = true   -- set to true to use layout editor along with script 

FX[FxGUID].CustomTitle = 'ReaComp'

---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------

local GR = tonumber(select(2, r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'GainReduction_dB')))

if FX[FxGUID][1] then 
    if GR and GR ~= 0 then 
        FX[FxGUID][1].CustomLbl = '  '
        FX[FxGUID].DontShowGR = nil
    elseif GR and GR == 0 then 
        FX[FxGUID][1].CustomLbl = 'Threshold'
        FX[FxGUID].DontShowGR = true 
    end
end