-- @description FX Devices Transient/Sustain Buttons Example
-- @author Bryan Chi/AI
-- @version 1.0
-- @changelog Initial release
-- @about
--   # FX Devices Transient/Sustain Buttons Example
--   This script demonstrates how to use the Transient/Sustain glowing buttons
--   with the modified Amplitude Splitter JSFX.

local r = reaper
local script_path = r.GetResourcePath() .. "/Scripts/ReaTeam Scripts/FX/Bryan FX Devices GITHUB/BryanChi_FX_Devices"

-- Import the Transient/Sustain buttons module
package.path = script_path .. "/?.lua;" .. package.path
local DrawSignalButtons = dofile(script_path .. "/src/FX Layout Plugin Scripts/Transient Sustain Buttons.lua")

-- UI variables
local ctx = r.ImGui_CreateContext('Transient/Sustain Example')
local WINDOW_FLAGS = r.ImGui_WindowFlags_None()
local open = true
local last_time = 0
local font_size = 14

-- Check if JSFX is in the Reaper FX path
local function checkJSFXInstalled()
    local jsfx_path = r.GetResourcePath() .. "/Effects/FX Devices/BryanChi_FX_Devices/lewloiwc's Splitter Suite/FXD lewloiwc_amplitude_splitter_transient.jsfx"
    local file = io.open(jsfx_path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Main function to open the JSFX on the selected track
local function addFXToSelectedTrack()
    local track = r.GetSelectedTrack(0, 0)
    if not track then
        r.ShowMessageBox("Please select a track first.", "No Track Selected", 0)
        return false
    end
    
    -- Add the FX to the selected track
    local fx_name = "FXD - Amplitude Splitter - Transient w/ Gmem Signal Output (lewloiwc)"
    local fx_idx = r.TrackFX_GetByName(track, fx_name, false)
    
    if fx_idx == -1 then
        -- FX not found, add it
        fx_idx = r.TrackFX_AddByName(track, fx_name, false, -1)
        if fx_idx == -1 then
            r.ShowMessageBox("Failed to add the Amplitude Splitter JSFX. Make sure it's installed correctly.", "FX Error", 0)
            return false
        end
    end
    
    -- Show the FX UI
    r.TrackFX_Show(track, fx_idx, 3)
    return true
end

-- UI Drawing function
local function loop()
    local current_time = r.time_precise()
    if current_time - last_time >= 1/60 then
        last_time = current_time
        
        r.ImGui_SetNextWindowSize(ctx, 380, 300, r.ImGui_Cond_FirstUseEver())
        open, WINDOW_FLAGS = r.ImGui_Begin(ctx, 'Transient/Sustain Buttons Example', open, WINDOW_FLAGS)
        
        if open then
            -- Info section
            r.ImGui_TextWrapped(ctx, "This example demonstrates the Transient/Sustain buttons that respond to signal levels from the Amplitude Splitter JSFX.")
            r.ImGui_Spacing(ctx)
            r.ImGui_Separator(ctx)
            r.ImGui_Spacing(ctx)
            
            -- Check if JSFX is installed
            local jsfx_installed = checkJSFXInstalled()
            if not jsfx_installed then
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0xFF0000FF)
                r.ImGui_TextWrapped(ctx, "WARNING: The Amplitude Splitter JSFX was not found. Please make sure it's installed correctly.")
                r.ImGui_PopStyleColor(ctx)
                r.ImGui_Spacing(ctx)
            end
            
            -- Add FX button
            if r.ImGui_Button(ctx, "Add Amplitude Splitter to Selected Track", -1, 0) then
                addFXToSelectedTrack()
            end
            
            r.ImGui_Spacing(ctx)
            r.ImGui_Separator(ctx)
            r.ImGui_Spacing(ctx)
            
            -- Draw the transient/sustain buttons with equal width
            r.ImGui_Text(ctx, "Signal Monitor:")
            r.ImGui_Spacing(ctx)
            
            -- Get available width for the buttons
            local avail_width = r.ImGui_GetContentRegionAvail(ctx)
            local button_width = (avail_width - 20) / 2  -- 20 is space between buttons
            
            -- Draw the buttons
            local transient_clicked, sustain_clicked = DrawSignalButtons(ctx, button_width, 80)
            
            -- Check if buttons were clicked
            if transient_clicked then
                r.ShowConsoleMsg("Transient button clicked!\n")
            end
            if sustain_clicked then
                r.ShowConsoleMsg("Sustain button clicked!\n")
            end
            
            r.ImGui_Spacing(ctx)
            r.ImGui_Separator(ctx)
            r.ImGui_Spacing(ctx)
            
            -- Instructions
            r.ImGui_TextWrapped(ctx, "1. Add the Amplitude Splitter to a track with audio")
            r.ImGui_TextWrapped(ctx, "2. Play your project to see the buttons react to transient and sustain signals")
            r.ImGui_TextWrapped(ctx, "3. Adjust the JSFX parameters to change the splitting behavior")
        end
        
        r.ImGui_End(ctx)
    end
    
    if open then
        r.defer(loop)
    else
        -- Clean up when closing
        r.ImGui_DestroyContext(ctx)
    end
end

-- Start the script
r.defer(loop) 