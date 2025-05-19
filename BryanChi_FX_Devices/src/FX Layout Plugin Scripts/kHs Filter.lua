-- @noindex




local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid
local fx = FX[FxGUID]
FX[FxGUID].Compatible_W_regular = true   -- set to true to use layout editor along with script 
local Freq = fx[2].V
local Res = fx[3].V
fx.Gain = fx[4].V
fx.FilterType = fx[5].V or 0 -- Default to 0 if not set
fx.Slope = fx[6].V or 0 -- Default to 0 if not set

ttp(fx[5].V)
-- Shorthand function for SameLine
local function SL(offset)
    im.SameLine(ctx, offset)
end

---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------

function ExampleSimpleHighCutDemo(ctx, W, H )
    im.SetCursorPos(ctx, 5, 40)
    im.InvisibleButton(ctx, 'Filter ',W, H)
    local FX_Win_L, FX_Win_T= im.GetItemRectMin(ctx)
    local FX_Win_R, FX_Win_B = im.GetItemRectMax(ctx)
    local fx = FX[FxGUID]
    
    -- Initialize FX data structure if not already done
    fx[1] = fx[1] or {}
    
    -- Normalized to actual conversion for cutoff frequency (logarithmic)
    -- Frequency is in the range of 20Hz to 20kHz
    local min_freq = 20
    local max_freq = 20000
    
    -- Convert from normalized 0-1 to actual frequency (if value exists)
    if Freq ~= nil then
        -- Logarithmic conversion from normalized value to actual frequency
        fx.Cutoff = min_freq * ((max_freq / min_freq) ^ fx[2].V)
    end
    
    -- Filter Parameters with default values if not set
    fx.Cutoff = fx.Cutoff or 1000
    fx.Resonance = Res or 0.5
    fx.Slope = fx.Slope or 0.5
    fx.Gain = fx.Gain or 0.5  -- For shelving and bell filters (normalized 0-1)
    
    -- Ensure FilterType is normalized 0-1 and update fx[5].V
    if fx.FilterType > 1 then
        -- Convert old numeric type to normalized
        fx.FilterType = fx.FilterType / 6
    end
    
    -- Make sure to update parameter values for automation
    if fx[4] then
        fx[4].V = fx.Gain
    end
    if fx[5] then
        fx[5].V = fx.FilterType
    end
    if fx[6] then
        fx[6].V = fx.Slope
    end
    
    -- Convert back to normalized value for parameter automation
    -- Logarithmic conversion from actual frequency to normalized value
    fx[2].V = math.log(fx.Cutoff / min_freq) / math.log(max_freq / min_freq)
    
    -- Create a background for the filter display
    local drawlist = im.GetWindowDrawList(ctx)
    im.DrawList_AddRectFilled(drawlist, FX_Win_L, FX_Win_T, FX_Win_R, FX_Win_B, 0x222222FF)
    im.DrawList_AddRect(drawlist, FX_Win_L, FX_Win_T, FX_Win_R, FX_Win_B, 0x444444FF, 0, 0, 1)
    
    -- Draw grid lines and frequency labels
    local gridColor = 0x444444AA
    local textColor = 0xAAAAAAFF
    
    -- Draw horizontal grid lines
    local gridLines = 5
    for i = 0, gridLines do
        local y = FX_Win_T + (FX_Win_B - FX_Win_T) * i / gridLines
        im.DrawList_AddLine(drawlist, FX_Win_L, y, FX_Win_R, y, gridColor)
        
        -- Add dB labels on the left
        local db = (gridLines/2 - i) * 12 -- Range from +30 to -30 dB
        --im.DrawList_AddText(drawlist, FX_Win_L + 5, y - 7, textColor, db .. " dB")
    end
    
    -- Center line (0 dB)
    local centerY = FX_Win_T + (FX_Win_B - FX_Win_T) / 2
    im.DrawList_AddLine(drawlist, FX_Win_L, centerY, FX_Win_R, centerY, 0x888888FF)
    
    -- Draw the appropriate filter curve based on filter type
    local width = FX_Win_R - FX_Win_L
    local height = FX_Win_B - FX_Win_T
    
    -- Set up clipping rect to ensure drawing stays within the invisible button bounds
    im.DrawList_PushClipRect(drawlist, FX_Win_L, FX_Win_T, FX_Win_R, FX_Win_B, true)
    
    
    -- Calculate filter type based on normalized value
    local filterTypeIndex = (fx.FilterType * 7) + 1 

    if filterTypeIndex > 7 then filterTypeIndex = 7 end
    
    local filterColor =  0xffffffff
    
    -- Whether to use stepped mode for slope changes (true) or continuous (false)
    local useSteppedMode = true
    
    -- Draw the selected filter type based on normalized value
    if filterTypeIndex >= 1 and filterTypeIndex <2 then -- LP (Low Pass)
        DrawHighCutFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, fx.Resonance, fx.Slope, filterColor, 2)
    elseif filterTypeIndex >= 2 and filterTypeIndex <3 then -- BP (Bandpass)
        -- Apply a stronger resonance factor to make the bandpass steeper
        local enhancedResonance = math.min(fx.Resonance * 1.5, 1.0)  -- Boost resonance but keep it within valid range
        DrawBandpassFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, enhancedResonance, fx.Slope, filterColor, 2, useSteppedMode)
    elseif filterTypeIndex >= 3 and filterTypeIndex <4 then -- HP (High Pass)
        DrawLowCutFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, fx.Resonance, fx.Slope, filterColor, 2)
    elseif filterTypeIndex >= 4 and filterTypeIndex <5 then -- Notch
        -- Apply slope to notch width/depth
        local enhancedResonance = math.min(fx.Resonance * (1 + fx.Slope), 1.0)  -- Slope affects notch Q
        DrawNotchFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, enhancedResonance, filterColor, 2)
    elseif filterTypeIndex >= 5 and filterTypeIndex <6 then -- Low Shelf
        -- Apply slope to shelf steepness
        local enhancedResonance = math.min(fx.Resonance * (1 + fx.Slope), 1.0)  -- Slope affects shelf steepness
        DrawLowShelfFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, enhancedResonance, fx.Gain, filterColor, 2)
    elseif filterTypeIndex >= 6 and filterTypeIndex <7 then -- Peak (Bell)
        -- Apply slope to bell width
        local enhancedResonance = math.min(fx.Resonance * (1 + fx.Slope), 1.0)  -- Slope affects bell Q/width
        DrawBellFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, enhancedResonance, fx.Gain, filterColor, 2)
    elseif filterTypeIndex >= 7 and filterTypeIndex <8 then -- High Shelf
        -- Apply slope to shelf steepness
        local enhancedResonance = math.min(fx.Resonance * (1 + fx.Slope), 1.0)  -- Slope affects shelf steepness
        DrawHighShelfFilter(ctx, drawlist, FX_Win_L, centerY, width, height, fx.Cutoff, enhancedResonance, fx.Gain, filterColor, 2)
    end
    
    im.DrawList_PopClipRect(drawlist)
    
    -- Draw filter cutoff indicator (also clipped to ensure it stays within bounds)
    local logCutoff = math.log(fx.Cutoff / min_freq) / math.log(max_freq / min_freq)
    local cutoffX = FX_Win_L + logCutoff * width
    im.DrawList_PushClipRect(drawlist, FX_Win_L, FX_Win_T, FX_Win_R, FX_Win_B, true)
    im.DrawList_AddLine(drawlist, cutoffX, FX_Win_T, cutoffX, FX_Win_B, 0xFFFFFF55, 1)
    im.DrawList_PopClipRect(drawlist)


end

ExampleSimpleHighCutDemo(ctx, 310, 100)