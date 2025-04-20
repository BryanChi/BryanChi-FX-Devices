-- @noindex

--[[
---------------------------------------------------------------------
  Signal Visualization Buttons for FX Devices Amplitude Splitter
---------------------------------------------------------------------

  Instructions for Integration:
  
  1. Include this file in your main script:
     `dofile(reaper.GetResourcePath() .. "/Scripts/ReaTeam Scripts/FX/Bryan FX Devices GITHUB/BryanChi_FX_Devices/src/FX Layout Plugin Scripts/Transient Sustain Buttons.lua")`
  
  2. Call the DrawSignalButtons() function in your ImGui drawing loop:
     `DrawSignalButtons(ctx, button_width, button_height)`
     
  3. Make sure to have the Amplitude Splitter JSFX loaded in your project
     with gmem properly configured.
  
---------------------------------------------------------------------
--]]

local r = reaper
local im = r.ImGui

-- Initialize variables for signal visualization
local GMEM_NAME = "FXD_Amplitude_Splitter"
local GMEM_TRANSIENT = 2100  -- Gmem address for transient signal
local GMEM_SUSTAIN = 2101    -- Gmem address for sustain signal
local GMEM_ACTIVE_FLAG = 10  -- Gmem address for plugin active flag

-- Persistent variables for signal smoothing
local transient_level = 0
local sustain_level = 0
local gmem_attached = false
local last_update_time = 0

-- Signal level decay rates (slower than JSFX for visual appeal)
local DECAY_RATE = 0.95  -- Slow decay for visual persistence

-- Function to draw the signal buttons
function DrawSignalButtons(ctx, width, height)
    -- Ensure gmem is attached 
    if not gmem_attached then
        r.gmem_attach(GMEM_NAME)
        gmem_attached = true
    end
    
    -- Default size if not provided
    local button_width = width or 120
    local button_height = height or 80
    local spacing = 10  -- Space between buttons
    
    -- Update signal levels (throttled to reduce CPU usage)
    local current_time = r.time_precise()
    if current_time - last_update_time > 0.016 then -- ~60fps
        -- Check if JSFX is active by reading flag
        local jsfx_active = r.gmem_read(GMEM_ACTIVE_FLAG) > 0
        
        if jsfx_active then
            -- Read current signal levels from gmem
            local new_transient = r.gmem_read(GMEM_TRANSIENT)
            local new_sustain = r.gmem_read(GMEM_SUSTAIN)
            
            -- Clamp between 0 and 1 for safety
            new_transient = math.max(0, math.min(1, new_transient))
            new_sustain = math.max(0, math.min(1, new_sustain))
            
            -- Update with peak detection
            transient_level = math.max(new_transient, transient_level * DECAY_RATE)
            sustain_level = math.max(new_sustain, sustain_level * DECAY_RATE)
        else
            -- If JSFX not active, gradually fade levels
            transient_level = transient_level * DECAY_RATE
            sustain_level = sustain_level * DECAY_RATE
        end
        
        last_update_time = current_time
    end
    
    -- Draw Transient Button
    local transient_base_color = {0.2, 0.7, 0.9, 1.0} -- Base color (blue)
    local transient_glow_color = {0.0, 0.9, 1.0, 1.0} -- Glow color (cyan)
    
    -- Create the buttons
    im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 6.0)
    
    -- Calculate transient button colors (lerp between base and glow based on level)
    local t_r = transient_base_color[1] + (transient_glow_color[1] - transient_base_color[1]) * transient_level
    local t_g = transient_base_color[2] + (transient_glow_color[2] - transient_base_color[2]) * transient_level
    local t_b = transient_base_color[3] + (transient_glow_color[3] - transient_base_color[3]) * transient_level
    
    -- Brighten color based on level (0.2-1.0 range for base)
    local t_brightness = 0.2 + transient_level * 0.8
    
    -- Set button colors
    im.PushStyleColor(ctx, im.Col_Button, im.ColorConvertDouble4ToU32(t_r * t_brightness, t_g * t_brightness, t_b * t_brightness, 1.0))
    im.PushStyleColor(ctx, im.Col_ButtonHovered, im.ColorConvertDouble4ToU32(t_r * t_brightness * 1.1, t_g * t_brightness * 1.1, t_b * t_brightness * 1.1, 1.0))
    im.PushStyleColor(ctx, im.Col_ButtonActive, im.ColorConvertDouble4ToU32(t_r * t_brightness * 0.9, t_g * t_brightness * 0.9, t_b * t_brightness * 0.9, 1.0))
    
    local transient_clicked = im.Button(ctx, "Transient", button_width, button_height)
    
    im.PopStyleColor(ctx, 3)
    
    -- Same layout for the Sustain button
    im.SameLine(ctx)
    im.Dummy(ctx, spacing, 1) -- Add space between buttons
    im.SameLine(ctx)
    
    -- Calculate sustain button colors (green/yellow range)
    local sustain_base_color = {0.2, 0.8, 0.2, 1.0} -- Base color (green)
    local sustain_glow_color = {0.8, 0.9, 0.0, 1.0} -- Glow color (yellow)
    
    local s_r = sustain_base_color[1] + (sustain_glow_color[1] - sustain_base_color[1]) * sustain_level
    local s_g = sustain_base_color[2] + (sustain_glow_color[2] - sustain_base_color[2]) * sustain_level
    local s_b = sustain_base_color[3] + (sustain_glow_color[3] - sustain_base_color[3]) * sustain_level
    
    -- Brighten color based on level
    local s_brightness = 0.2 + sustain_level * 0.8
    
    im.PushStyleColor(ctx, im.Col_Button, im.ColorConvertDouble4ToU32(s_r * s_brightness, s_g * s_brightness, s_b * s_brightness, 1.0))
    im.PushStyleColor(ctx, im.Col_ButtonHovered, im.ColorConvertDouble4ToU32(s_r * s_brightness * 1.1, s_g * s_brightness * 1.1, s_b * s_brightness * 1.1, 1.0))
    im.PushStyleColor(ctx, im.Col_ButtonActive, im.ColorConvertDouble4ToU32(s_r * s_brightness * 0.9, s_g * s_brightness * 0.9, s_b * s_brightness * 0.9, 1.0))
    
    local sustain_clicked = im.Button(ctx, "Sustain", button_width, button_height)
    
    im.PopStyleColor(ctx, 3)
    im.PopStyleVar(ctx)
    
    -- Optional: Draw level indicators
    if im.TreeNode(ctx, "Levels") then
        im.Text(ctx, string.format("Transient: %.2f", transient_level))
        im.Text(ctx, string.format("Sustain: %.2f", sustain_level))
        im.TreePop(ctx)
    end
    
    return transient_clicked, sustain_clicked
end

-- Helper function for easy cleanup
function DetachGmem()
    if gmem_attached then
        r.gmem_detach(GMEM_NAME)
        gmem_attached = false
    end
end

-- Return DrawSignalButtons as the main function from this module
return DrawSignalButtons 