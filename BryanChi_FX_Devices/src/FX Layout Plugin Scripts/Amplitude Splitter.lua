-- @noindex

--[[
---------------------------------------------------------------------
  Transient/Sustain Signal Visualization for FX Devices
---------------------------------------------------------------------

  Instructions for Integration into Layout Files:

  1. Include this script in your layout .ini file using:
     [Code]
     Amplitude Splitter.lua
     [/Code]
  
  2. Call DrawTransientSustainButtons() in your layout:
     [Item]
     Type=Code
     Text=DrawTransientSustainButtons(200, 80) -- width, height
     [/Item]
  
  3. Make sure the Amplitude Splitter JSFX with gmem is loaded
     on the track where you're using this visualization.
  
---------------------------------------------------------------------
--]]

local FxGUID = PluginScript.Guid
local FX_Idx = PluginScript.FX_Idx
FX[FxGUID] = FX[FxGUID] or {}
local fx = FX[FxGUID]

fx.NoWindowBtn = true
fx.NoWetKnob = true
fx.Left_Padding = 0
fx.Compatible_W_regular = true
im.SetCursorPos(ctx, 0, 0)
local GMEM_NAME = "FXD_Amplitude_Splitter"
local GMEM_TRANSIENT = 2100  -- Gmem address for transient signal level
local GMEM_SUSTAIN = 2101    -- Gmem address for sustain signal level
local GMEM_ACTIVE_FLAG = 10  -- Gmem address for plugin active flag

-- Persistent variables for display
local FXD_transient_level = 0
local FXD_sustain_level = 0
local FXD_gmem_attached = false
local FXD_last_update_time = 0

-- Color transitions (minimal smoothing since JSFX is already handling most of it)
local FXD_color_transient = 0
local FXD_color_sustain = 0
local COLOR_SMOOTHING = 0.7 -- Gentler smoothing, just to avoid any potential jitter


-- Button colors - updated to match FX Devices theme
local TRANSIENT_BASE = {0, 0, 0, 0.2}  -- Darker blue base
local TRANSIENT_GLOW = {1.0, 0.4, 0.2, 1.0}    -- Brighter orange-red glow
local SUSTAIN_BASE = {0, 0, 0, 0.2}     -- Much darker green base
local SUSTAIN_GLOW = {0.4, 1.0, 0.7, 1.0}      -- Much brighter green/yellow glow


-- Apply a non-linear curve to make the response more natural
local function apply_response_curve(value)
    -- Apply power curve with gamma = 0.6 (makes low values more visible)
    local gamma_corrected = value ^ 0.6
    
    -- Mix with square root curve for even smoother response
    local sqrt_curve = math.sqrt(value)
    
    -- Blend 70% gamma curve with 30% sqrt for a nice balance
    return gamma_corrected * 0.7 + sqrt_curve * 0.3
end

-- Draw custom buttons with radial lighting effect
local function DrawRadialButton(label, width, height, base_color, glow_color, intensity)
    -- Create invisible button for interaction
    local button_pos_x, button_pos_y = im.GetCursorPos(ctx)
    local clicked = im.InvisibleButton(ctx, "##" .. label, width, height)
    local is_hovered = im.IsItemHovered(ctx)
    local is_active = im.IsItemActive(ctx)
    
    -- Get button drawing area
    local draw_list = im.GetWindowDrawList(ctx)
    local btn_min_x, btn_min_y = im.GetItemRectMin(ctx)
    local btn_max_x, btn_max_y = im.GetItemRectMax(ctx)
    local btn_width = btn_max_x - btn_min_x
    local btn_height = btn_max_y - btn_min_y
    
    -- Calculate center
    local center_x = btn_min_x + btn_width * 0.5
    local center_y = btn_min_y + btn_height * 0.5
    
    -- Determine radius of the button (use smaller dimension)
    local radius = math.min(btn_width, btn_height) * 0.5
    
    -- Adjust color based on hover/active state
    local color_multiplier = 1.0
    if is_active then color_multiplier = 0.8
    elseif is_hovered then color_multiplier = 1.2 end
    
    -- Create outer rounded rectangle (base color)
    local rounding = 6.0
    local base_r = base_color[1]
    local base_g = base_color[2]
    local base_b = base_color[3]
    local base_a = base_color[4]
    local base_color_u32 = im.ColorConvertDouble4ToU32(base_r, base_g, base_b, base_a)
    im.DrawList_AddRectFilled(draw_list, btn_min_x, btn_min_y, btn_max_x, btn_max_y, base_color_u32, rounding)
    
    -- Draw multiple circles with decreasing size and increasing brightness
    local num_circles = 8
    for i = num_circles, 1, -1 do
        local circle_radius = radius * (i / num_circles) * 0.9
        
        -- Increase intensity for inner circles more dramatically
        local circle_intensity = intensity * (1 - ((i-1) / num_circles) ^ 2) * color_multiplier * 1.5
        
        -- Calculate uncapped RGB values
        local r = base_r + (glow_color[1] - base_r) * circle_intensity
        local g = base_g + (glow_color[2] - base_g) * circle_intensity
        local b = base_b + (glow_color[3] - base_b) * circle_intensity
        
        -- Check if any value exceeds 1.0
        local max_val = math.max(r, g, b)
        if max_val > 1.0 then
            -- Scale all components proportionally to preserve hue
            local scale = 1.0 / max_val
            r = r * scale
            g = g * scale
            b = b * scale
        end
        
        -- Increase alpha for inner circles
        local a = math.min(1.0, base_a + (1.0 - base_a) * circle_intensity * 1.2)
        
        local circle_color = im.ColorConvertDouble4ToU32(r, g, b, a)
        im.DrawList_AddCircleFilled(draw_list, center_x, center_y, circle_radius, circle_color)
    end
    
    -- Add text overlay
    local text_w, text_h = im.CalcTextSize(ctx, label)
    local text_x = center_x - text_w * 0.5
    local text_y = center_y - text_h * 0.5
    
    -- Shadow for better readability
    im.DrawList_AddText(draw_list, text_x + 1, text_y + 1, 0x80000000, label)
    
    -- Text in white
    im.DrawList_AddText(draw_list, text_x, text_y, 0xFFFFFFFF, label)
    
    return clicked
end



-- Function to draw the signal buttons
function DrawTransientSustainButtons(button_width, button_height)
    button_width = button_width or 120
    button_height = button_height or 80
    local spacing = 10  -- Space between buttons
    local OutlineClr = 0x333333ff
    -- Ensure gmem is attached (only once)
    if not FXD_gmem_attached then
        r.gmem_attach(GMEM_NAME)
        FXD_gmem_attached = true
    end
    
    -- First check/create containers to ensure we have GUIDs
    local containers_exist, transient_guid, sustain_guid = DetectOrCreateSplitterContainers(FX_Idx, FxGUID)
    
    -- Update signal levels (throttled to reduce CPU usage)
    local current_time = r.time_precise()
    if current_time - FXD_last_update_time > 0.016 then -- ~60fps
        -- Check if JSFX is active
        local jsfx_active = r.gmem_read(GMEM_ACTIVE_FLAG) > 0
        
        if jsfx_active then
            -- Read values directly from gmem - these are already smoothed by the JSFX
            local new_transient = r.gmem_read(GMEM_TRANSIENT)
            local new_sustain = r.gmem_read(GMEM_SUSTAIN)
            
            
            -- Clamp between 0 and 1 for safety
            new_transient = math.max(0, math.min(1, new_transient))
            new_sustain = math.max(0, math.min(1, new_sustain))
            
            -- Apply small amount of smoothing to avoid any potential jitter
            FXD_transient_level = new_transient
            FXD_sustain_level = new_sustain
        else
            -- If JSFX not active, gradually fade out
            FXD_transient_level = FXD_transient_level * 0.95
            FXD_sustain_level = FXD_sustain_level * 0.95
        end
        
        -- Apply minimal smoothing to color values to minimize any potential jitter
        FXD_color_transient = FXD_color_transient * COLOR_SMOOTHING + FXD_transient_level * (1 - COLOR_SMOOTHING)
        FXD_color_sustain = FXD_color_sustain * COLOR_SMOOTHING + FXD_sustain_level * (1 - COLOR_SMOOTHING)
        
        FXD_last_update_time = current_time
    end
    
    -- Calculate available width
    local available_width = button_width * 2 + spacing
    
    -- Calculate button width (split available width)
    local single_button_width = (available_width - spacing) / 2
    
    -- Style the buttons
    im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 6.0)
    
    -- Transient Button
    -- Apply non-linear scaling for visual appeal using the smoothed color value
    local color_level = apply_response_curve(FXD_color_transient) * 2.5
    
    -- Transient button with radial effect
    local transient_clicked = DrawRadialButton( "Transient", single_button_width, button_height, TRANSIENT_BASE, TRANSIENT_GLOW, color_level )
    Highlight_Itm(WDL, nil , OutlineClr)
    -- Use ThemeClr for sustain if available
    local sustain_glow = SUSTAIN_GLOW
    if ThemeClr then
        local accent = ThemeClr('Accent_Clr')
        -- Convert packed color to RGBA (0-1 range)
        sustain_glow = { ((accent >> 16) & 0xFF) / 255, ((accent >> 8) & 0xFF) / 255, (accent & 0xFF) / 255, ((accent >> 24) & 0xFF) / 255 }
    end
    
    -- Add drag-drop handling for transient button
    if containers_exist then
        HandleContainerDragDrop("Transient", transient_guid)
    end
    
    AddSpacing(25)

    -- Sustain button with radial effect
    local sustain_color_level = apply_response_curve(FXD_color_sustain) * 2.0
    local sustain_clicked = DrawRadialButton( "Sustain", single_button_width, button_height, SUSTAIN_BASE, sustain_glow ,sustain_color_level  --[[ Use theme accent color sustain_color_level ]] )
    Highlight_Itm(WDL, nil , OutlineClr)
    
    -- Add drag-drop handling for sustain button
    if containers_exist then
        HandleContainerDragDrop("Sustain", sustain_guid)
    end
    
    im.PopStyleVar(ctx)


    if im.IsItemClicked(ctx, 0) and Mods == Shift + Ctrl then
        FX.LayEdit = FxGUID
    end
    return transient_clicked, sustain_clicked
end
-- Function to handle drag and drop for container buttons
function HandleContainerDragDrop(button_type, container_guid)
    local is_valid_target = false
    local drag_highlight_color = 0x66FFFFFF -- Semi-transparent white highlight
    
    -- Check if anything is being dragged
    if im.BeginDragDropTarget(ctx) then
        -- Get the button's rectangle for visual highlighting
        local draw_list = im.GetWindowDrawList(ctx)
        local min_x, min_y = im.GetItemRectMin(ctx)
        local max_x, max_y = im.GetItemRectMax(ctx)
        
        -- Highlight the drop target
        im.DrawList_AddRect(draw_list, min_x, min_y, max_x, max_y, drag_highlight_color, 6.0, nil, 2.0)
        
        -- Try both payload types - one at a time
        local dropped_add, payload_add = im.AcceptDragDropPayload(ctx, 'DND ADD FX')
        local dropped_move, payload_move = im.AcceptDragDropPayload(ctx, 'FX_Drag')
        
        -- Process the drop if it happened and no modifier keys are pressed
        if (dropped_add or dropped_move) and Mods == 0 then
            local track = LT_Track
            if track and container_guid then
                -- Find the container index by GUID
                local container_idx = -1
                for i = 0, r.TrackFX_GetCount(track) - 1 do
                    local guid = r.TrackFX_GetFXGUID(track, i)
                    if guid == container_guid then
                        container_idx = i
                        break
                    end
                end
                
                if container_idx >= 0 then
                    -- Calculate the FX_Id for insertion inside the container
                    -- This follows the pattern seen in Container.lua
                    local FX_Id = 0x2000000 + 1 * (r.TrackFX_GetCount(track) + 1) + (container_idx + 1)
                    
                    -- Get the container name for user feedback
                    local _, container_name = r.TrackFX_GetFXName(track, container_idx)
                    
                    -- Handle different actions based on payload type
                    if dropped_add then
                        -- Add new FX from browser
                        r.TrackFX_AddByName(track, payload_add, false, -1000 - FX_Id)
                        r.ShowConsoleMsg("Added " .. payload_add .. " to " .. button_type .. " container\n")
                    elseif dropped_move then
                        -- Move existing FX to container
                        -- DragFX_ID is a global that contains the ID of the FX being dragged
                        if DragFX_ID then
                            r.TrackFX_CopyToTrack(track, DragFX_ID, track, FX_Id, true)
                            r.ShowConsoleMsg("Moved FX to " .. button_type .. " container\n")
                        end
                    end
                    
                    is_valid_target = true
                end
            end
        end
        
        im.EndDragDropTarget(ctx)
    end
    
    return is_valid_target
end
-- Function to detect or create Transient/Sustain containers after amplitude splitter
function DetectOrCreateSplitterContainers(fx_idx, fxguid)
    -- Get track and basic info
    local track = LT_Track
    if not track then return false end
    
    -- Check if we've already processed this splitter to avoid multiple additions
    if FX[fxguid] and FX[fxguid].ContainersCreated then
        return true, FX[fxguid].TransientContainer, FX[fxguid].SustainContainer
    end
    
    -- Get track GUID for the containers structure
    local track_guid = r.GetTrackGUID(track)
    if not track_guid then return false end
    Trk[track_guid] = Trk[track_guid] or {}
    
    -- Check if track has enough channels (at least 4)
    local track_channels = r.GetMediaTrackInfo_Value(track, "I_NCHAN")
    if track_channels < 4 then
        -- Set track to at least 4 channels
        r.SetMediaTrackInfo_Value(track, "I_NCHAN", 4)
    end
    
    -- Check if we have containers already
    local has_transient = false
    local has_sustain = false
    local transient_idx = -1
    local sustain_idx = -1
    local transient_guid = nil
    local sustain_guid = nil
    
    -- Find the next two FX after the amplitude splitter
    local next_idx1 = fx_idx + 1
    local next_idx2 = fx_idx + 2
    
    -- Check if the containers exist - look carefully for exact match
    if next_idx1 < r.TrackFX_GetCount(track) then
        local _, name1 = r.TrackFX_GetFXName(track, next_idx1)
        if name1:find("Transient") then
            local guid1 = r.TrackFX_GetFXGUID(track, next_idx1)
            if guid1 then
                has_transient = true
                transient_idx = next_idx1
                transient_guid = guid1
                FX[guid1] = FX[guid1] or {}
                FX[guid1].IsContainer = true
                FX[guid1].HideContainer = true  -- Hide this container from container layout script
            end
        end
        
        if next_idx2 < r.TrackFX_GetCount(track) then
            local _, name2 = r.TrackFX_GetFXName(track, next_idx2)
            if name2:find("Sustain") then
                local guid2 = r.TrackFX_GetFXGUID(track, next_idx2)
                if guid2 then
                    has_sustain = true
                    sustain_idx = next_idx2
                    sustain_guid = guid2
                    FX[guid2] = FX[guid2] or {}
                    FX[guid2].IsContainer = true
                    FX[guid2].HideContainer = true  -- Hide this container from container layout script
                end
            end
        end
    end
    
    -- Mark this as a one-time operation by storing a flag and the container references
    if has_transient and has_sustain then
        FX[fxguid] = FX[fxguid] or {}
        FX[fxguid].ContainersCreated = true
        FX[fxguid].TransientContainer = transient_guid
        FX[fxguid].SustainContainer = sustain_guid
        return true, transient_guid, sustain_guid
    end
    
    -- Only do creation once, and only when explicitly requested
    if not has_transient and not has_sustain then
        -- Check for user confirmation before adding
        local confirm = r.MB("Create Transient and Sustain containers for this Amplitude Splitter?", "Create Containers", 4)
        if confirm == 7 then -- User clicked No
            return false
        end
        
        -- Create Transient container
        local container_idx = r.TrackFX_AddByName(track, "Container", false, -1)
        if container_idx >= 0 then
            r.TrackFX_SetNamedConfigParm(track, container_idx, "renamed_name", "Transient")  -- Simpler name
            transient_idx = container_idx
            transient_guid = r.TrackFX_GetFXGUID(track, container_idx)
            FX[transient_guid] = FX[transient_guid] or {}
            FX[transient_guid].IsContainer = true
            FX[transient_guid].HideContainer = true  -- Hide this container from container layout script
            
            -- Set input pins for transient (1,2)
            r.TrackFX_SetPinMappings(track, container_idx, 0, 0, 1, 0) -- Input 1 -> 1
            r.TrackFX_SetPinMappings(track, container_idx, 0, 1, 2, 0) -- Input 2 -> 2
            
            -- Reorder FX to be right after the amplitude splitter
            if container_idx ~= next_idx1 then
                r.TrackFX_CopyToTrack(track, container_idx, track, next_idx1, true)
                transient_idx = next_idx1
                transient_guid = r.TrackFX_GetFXGUID(track, next_idx1)
                FX[transient_guid] = FX[transient_guid] or {}
                FX[transient_guid].IsContainer = true
                FX[transient_guid].HideContainer = true  -- Hide this container from container layout script
            end
            
            has_transient = true
        end
        
        -- Create Sustain container in parallel
        if has_transient then
            local container_idx = r.TrackFX_AddByName(track, "Container", false, -1)
            if container_idx >= 0 then
                r.TrackFX_SetNamedConfigParm(track, container_idx, "renamed_name", "Sustain")  -- Simpler name
                sustain_idx = container_idx
                sustain_guid = r.TrackFX_GetFXGUID(track, container_idx)
                FX[sustain_guid] = FX[sustain_guid] or {}
                FX[sustain_guid].IsContainer = true
                FX[sustain_guid].HideContainer = true  -- Hide this container from container layout script
                
                -- Set input pins for sustain (3,4)
                r.TrackFX_SetPinMappings(track, container_idx, 0, 0, 4, 0) -- Input 1 -> 3
                r.TrackFX_SetPinMappings(track, container_idx, 0, 1, 8, 0) -- Input 2 -> 4
                
                -- Set up parallel processing
                if Trk[track_guid].ParallelFX == nil then
                    Trk[track_guid].ParallelFX = {}
                end
                
                -- Add to parallel FX list
                table.insert(Trk[track_guid].ParallelFX, {
                    Main = transient_guid,
                    ParallelTo = sustain_guid
                })
                
                -- Reorder FX to be right after the transient container
                if container_idx ~= transient_idx + 1 then
                    r.TrackFX_CopyToTrack(track, container_idx, track, transient_idx + 1, true)
                    sustain_idx = transient_idx + 1
                    sustain_guid = r.TrackFX_GetFXGUID(track, transient_idx + 1)
                    FX[sustain_guid] = FX[sustain_guid] or {}
                    FX[sustain_guid].IsContainer = true
                    FX[sustain_guid].HideContainer = true  -- Hide this container from container layout script
                end
                
                has_sustain = true
            end
        end
        
        -- Mark this as a one-time operation
        if has_transient and has_sustain then
            FX[fxguid] = FX[fxguid] or {}
            FX[fxguid].ContainersCreated = true
            FX[fxguid].TransientContainer = transient_guid
            FX[fxguid].SustainContainer = sustain_guid
        end
    end
    
    return has_transient and has_sustain, transient_guid, sustain_guid
end

im.PushFont(ctx, Font_Andale_Mono_11)
DrawTransientSustainButtons(50, 60)
im.PopFont(ctx)


DetectOrCreateSplitterContainers(FX_Idx, FxGUID)

-- To use this function, call it only when the user explicitly requests container creation
if FX_Name:find("Amplitude Splitter") and im.IsItemClicked(ctx, 1) then -- Right click on splitter
    local menu = "Add Transient/Sustain Containers"
    if im.BeginPopupContextItem(ctx) then
        if im.MenuItem(ctx, menu) then
            DetectOrCreateSplitterContainers(FX_Idx, FxGUID)
        end
        im.EndPopup(ctx)
    end
end

-- Add this in your container plugin script or where you display containers:
function ShouldShowContainer(fxguid)
    if FX[fxguid] and FX[fxguid].HideContainer then
        return false  -- Don't show containers marked as hidden
    end
    return true  -- Show all other containers
end



