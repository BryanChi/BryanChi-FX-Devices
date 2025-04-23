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
fx.Width = 50

fx.NoWindowBtn = true
fx.NoWetKnob = true
fx.Left_Padding = 0
fx.Compatible_W_regular = true
im.SetCursorPos(ctx, 0, 0)
local track = LT_Track
local Wet_Dry_Drag_Height = -2
local Transient_Color = 0xFF6632AA
local Sustain_Color = 0xFF66FFAA
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

-- Function to count FX inside a container (Uses standard REAPER API, not ReaImGui)


-- Function to draw FX indicators on a button (Uses ReaImGui DrawList API)
function DrawFXIndicators(container_idx, btn_min_x, btn_min_y, btn_max_x, btn_max_y, color_u32)
    local ok, count = r.TrackFX_GetNamedConfigParm(track, container_idx, "container_count")
    local count = tonumber(count) or 0
    local draw_list = WDL or im.GetWindowDrawList(ctx)
    if count <= 0 then return end 

    
    -- Calculate indicator area (bottom portion of button)
    local button_height = btn_max_y - btn_min_y
    local indicator_y_start = btn_min_y + button_height * 0.7  -- Start 70% down
    local indicator_height = button_height * 0.15 -- Simple height calculation
    local indicator_y = indicator_y_start + button_height * 0.1 -- Position within bottom area
    
    local max_indicators = math.min(count, 8) -- Limit to 8 visible indicators
    local button_width = btn_max_x - btn_min_x
    
    -- Simple width calculation
    local indicator_width = button_width * 0.1 -- 10% of button width
    local spacing = button_width * 0.02 -- 2% of button width
    local total_width = (indicator_width + spacing) * max_indicators - spacing
    local start_x = btn_min_x + (button_width - total_width) / 2 -- Center horizontally
    
    -- Just use the provided color directly
    local indicator_rounding = 2.0
    
    -- Draw indicator rectangles
    for i = 1, max_indicators do
        local current_x = start_x + (i - 1) * (indicator_width + spacing)
        
        im.DrawList_AddRectFilled(
            draw_list,
            current_x,
            indicator_y,
            current_x + indicator_width,
            indicator_y + indicator_height,
            color_u32,
            indicator_rounding
        )
    end
    
    -- If there are more FX than we can show, add a "+" text indicator
    if count > max_indicators then
        local text = "+"
        local text_size_x, text_size_y = im.CalcTextSize(ctx, text)
        local text_x = btn_max_x - text_size_x - 5
        local text_y = indicator_y + (indicator_height - text_size_y) / 2
        
        im.DrawList_AddText(draw_list, text_x, text_y, 0xFFFFFFFF, text)
    end
end

-- Function to draw a ">" symbol using polylines
function DrawArrowSymbol(draw_list, center_x, center_y, size, color, is_hovered, is_active)
    -- Adjust color based on hover/active state
    local r, g, b, a = im.ColorConvertU32ToDouble4(color)
    
    -- Make semi-transparent when not interacted with
    if not (is_hovered or is_active) then
        a = a * 0.5 -- 50% opacity when not hovered/clicked
    end
    
    if is_active then
        -- Brighten more when clicked
        r, g, b = math.min(r * 1.5, 1.0), math.min(g * 1.5, 1.0), math.min(b * 1.5, 1.0)
        a = 1.0 -- Full opacity when clicked
    elseif is_hovered then
        -- Brighten slightly when hovered
        r, g, b = math.min(r * 1.3, 1.0), math.min(g * 1.3, 1.0), math.min(b * 1.3, 1.0)
        a = 0.9 -- Almost full opacity when hovered
    end
    
    -- Create final color
    local arrow_color = im.ColorConvertDouble4ToU32(r, g, b, a)
    
    -- Calculate dimensions for ">" symbol
    local width = size * 0.6
    local height = size * 1.0
    local thickness = size * 0.15 -- Line thickness
    
    -- Calculate points for ">" symbol (using lines)
    local top_x = center_x - width/2
    local top_y = center_y - height/2
    local mid_x = center_x + width/2
    local mid_y = center_y
    local bottom_x = center_x - width/2
    local bottom_y = center_y + height/2
    
    -- Draw the two lines of the ">" symbol
    im.DrawList_AddLine(draw_list, top_x, top_y, mid_x, mid_y, arrow_color, thickness)
    im.DrawList_AddLine(draw_list, mid_x, mid_y, bottom_x, bottom_y, arrow_color, thickness)
end

-- Function to draw a "+" symbol using lines
function DrawPlusSymbol(draw_list, center_x, center_y, size, color, is_hovered, is_active)
    -- Adjust color based on hover/active state
    local r, g, b, a = im.ColorConvertU32ToDouble4(color)
    
    -- Make semi-transparent when not interacted with
    if not (is_hovered or is_active) then
        a = a * 0.5
    end
    
    if is_active then
        r, g, b = math.min(r * 1.5, 1.0), math.min(g * 1.5, 1.0), math.min(b * 1.5, 1.0)
        a = 1.0
    elseif is_hovered then
        r, g, b = math.min(r * 1.3, 1.0), math.min(g * 1.3, 1.0), math.min(b * 1.3, 1.0)
        a = 0.9
    end
    
    local plus_color = im.ColorConvertDouble4ToU32(r, g, b, a)
    
    -- Calculate dimensions for "+" symbol
    local line_length = size * 0.8
    local thickness = size * 0.15
    
    -- Draw horizontal line
    im.DrawList_AddLine(draw_list,
        center_x - line_length/2, center_y,
        center_x + line_length/2, center_y,
        plus_color, thickness)
    
    -- Draw vertical line
    im.DrawList_AddLine(draw_list,
        center_x, center_y - line_length/2,
        center_x, center_y + line_length/2,
        plus_color, thickness)
end

-- Function to add a small wet/dry slider for containers
function AddContainerWetDrySlider(container_guid, container_idx, x_pos, y_pos, width, height, is_bottom)
    if not container_guid then return end
    
    
 
    if not container_idx then return end
    -- Get the current wet value (wet is always the last parameter in REAPER FX)
    local wet_param_idx = r.TrackFX_GetParamFromIdent(track, container_idx, ':wet')
    local wet_value = r.TrackFX_GetParamNormalized(track, container_idx, wet_param_idx)
    
    -- Store the current cursor position to restore later
    local orig_x, orig_y = im.GetCursorPos(ctx)
    
    -- Set the position for our slider
    im.SetCursorPos(ctx, x_pos, y_pos)
    
    -- Create a unique ID for each slider
    local slider_id = "##WetSlider" .. container_guid
    
    -- Push styling to make the slider smaller and more compact
    im.PushStyleVar(ctx, im.StyleVar_FramePadding, 2, height/4)
    im.PushStyleVar(ctx, im.StyleVar_GrabMinSize, 8)
    
    -- Set slider color based on position
    if is_bottom then
        im.PushStyleColor(ctx, im.Col_SliderGrab, Transient_Color) -- Orange for Transient
        im.PushStyleColor(ctx, im.Col_FrameBg, 0x80332255) -- Darker orange background
    else
        im.PushStyleColor(ctx, im.Col_SliderGrab, 0xFF66FFAA) -- Green for Sustain
        im.PushStyleColor(ctx, im.Col_FrameBg, 0x8022AA44) -- Darker green background
    end
    
    im.SetNextItemWidth(ctx, width)
   -- Add the drag control
   local changed, new_wet = im.DragDouble(ctx, slider_id, wet_value, 0.01, 0.0, 1.0, "%.2f", im.SliderFlags_NoInput)
   -- Draw the actual slider
   local draw_list = im.GetWindowDrawList(ctx)
   local pos_l, pos_t = im.GetItemRectMin(ctx)
   local pos_r, pos_b = im.GetItemRectMax(ctx)
   local width = pos_r - pos_l
   local height = pos_b - pos_t

   -- Draw background
   im.DrawList_AddRectFilled(draw_list, pos_l, pos_t, pos_r, pos_b, 0x80222222, 2.0)

   -- Draw value bar
   local value_width = width * wet_value
   local value_color = is_bottom and Transient_Color or 0xFF66FFAA -- Orange for Transient, Green for Sustain
   local value_color_dim = is_bottom and 0x80AA4422 or 0x8022AA44 -- Darker versions for background

   -- Draw the filled portion
   im.DrawList_AddRectFilled(draw_list, pos_l, pos_t, pos_l + value_width, pos_b, value_color_dim, 2.0)

   -- If the item is active or hovered, make the value bar brighter
   if im.IsItemActive(ctx) or im.IsItemHovered(ctx) then
       im.DrawList_AddRectFilled(draw_list, pos_l, pos_t, pos_l + value_width, pos_b, value_color, 2.0)
   end    
    -- Pop all stylings
    im.PopStyleColor(ctx, 2)
    im.PopStyleVar(ctx, 2)
    
    -- If slider value changed, update the container's wet parameter
    if changed then
        r.TrackFX_SetParamNormalized(track, container_idx, wet_param_idx, new_wet)
        
        -- Store the value in our FX table for persistence
        FX[container_guid] = FX[container_guid] or {}
        FX[container_guid].WetValue = new_wet
    end
    
    
    -- Restore the original cursor position
    im.SetCursorPos(ctx, orig_x, orig_y)
    
    return changed, new_wet
end

function find_container_in_tree(TREE, container_guid)
    -- First find the container in the TREE
    local function search_container(items, guid)

        for i, item in ipairs(items) do
            if item.GUID == guid then
                return item.addr_fxid
            end
            -- If this item has children, recursively search them
            if item.children then
                local found = search_container(item.children, guid)
                if found then
                    return found
                end
            end
        end
    end
    return  search_container(TREE, container_guid)
    
end

-- Updated DrawRadialButton to correctly call DrawFXIndicators
local function DrawRadialButton(label, width, height, base_color, glow_color, intensity, container_guid, container_idx)
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
      -- Push font scaling if needed
    im.PushFont(ctx, Font_Andale_Mono_10) -- Use a slightly smaller font
   
    -- Add text overlay - Positioned at the top inside the button
    local text_padding_top = 5.0 -- Adjust as needed
    local text_w, text_h = im.CalcTextSize(ctx, label)
    
    -- Calculate maximum allowed text width (80% of button width to leave some padding)
    local max_text_width = btn_width * 0.8
    
    -- If text is too wide, calculate a scale factor to make it fit
    local text_scale = 1.0
    if text_w > max_text_width then
        text_scale = max_text_width / text_w
    end
    
    -- Calculate scaled text position

    local scaled_text_w = text_w * text_scale
    local text_x = center_x - (scaled_text_w *( label == 'Transient' and 0.57 or  0.5))  -- Center horizontally
    local text_y = btn_min_y + text_padding_top -- Position near the top edge
    
  
    
    -- Shadow for better readability
    im.DrawList_AddText(draw_list, text_x + 1, text_y + 1, 0x90000000, label)
    -- Text in white
    im.DrawList_AddText(draw_list, text_x, text_y, 0xFFFFFFFF, label)
    

    im.PopFont(ctx)

    
    -- Convert glow color to U32 for the arrow
    local glow_color_u32 = im.ColorConvertDouble4ToU32( glow_color[1], glow_color[2], glow_color[3], 1.0)
    
    -- Check if container is empty before drawing the symbol
    local is_empty 
    if container_guid and container_idx then
        local ok, count = r.TrackFX_GetNamedConfigParm(track, container_idx, "container_count")
        is_empty = tonumber(count) == 0
        if is_empty and fx.ChosenContainer == label then 
            fx.ChosenContainer = nil
        end
    end
    
    -- Draw the appropriate symbol based on container state
    local symbol_size = math.min(btn_width, btn_height) * 0.25
    if is_empty then
        DrawPlusSymbol(draw_list, center_x, center_y, symbol_size, glow_color_u32, is_hovered, is_active)
        local targ_pos = TrackFX_GetInsertPositionInContainer(container_idx, 1)

        if im.IsItemClicked(ctx, 0) then -- Left click on the "+" icon
            -- Store the menu position before any container content is drawn
            local menu_x, menu_y = im.GetCursorScreenPos(ctx)
            menu_x = menu_x + 60
            menu_y = VP.Y - 285
            
            -- Store the position for later use
            fx.MenuPosition = {x = menu_x, y = menu_y}
            
            FX_Adder_Idx = targ_pos
            im.OpenPopup(ctx, 'Btwn FX Windows' .. targ_pos)
        end

        -- Draw line to menu and outline when menu is open
        if im.IsPopupOpen(ctx, 'Btwn FX Windows' .. targ_pos) then
            -- Draw line from button to menu
            local btn_max_x, btn_max_y = im.GetItemRectMax(ctx)
            local btn_w, btn_h = im.GetItemRectSize(ctx)
            local btn_center_y = btn_max_y - btn_h/2
            draw_list = im.GetForegroundDrawList(ctx)
            -- Draw horizontal line from button
            im.DrawList_AddLine(draw_list, btn_max_x, btn_center_y, btn_max_x + 16, btn_center_y, glow_color_u32, 3)
            
            -- Draw vertical line to menu
            local menu_y = VP.Y - 285
            im.DrawList_AddLine(draw_list, btn_max_x + 15, btn_center_y, btn_max_x + 15, menu_y, glow_color_u32, 3)
            
            -- Draw outline around radial button
            local btn_min_x, btn_min_y = im.GetItemRectMin(ctx)
            im.DrawList_AddRect(draw_list, btn_min_x, btn_min_y, btn_max_x, btn_max_y, glow_color_u32, 0, 0, 1)
        end
    else
        DrawArrowSymbol(draw_list, center_x, center_y, symbol_size, glow_color_u32, is_hovered, is_active)
        -- Set chosen container when clicked
        if clicked then 
            if fx.ChosenContainer == label then 
                fx.ChosenContainer = nil 
            else 
                fx.ChosenContainer = label 
            end
        end
        if container_idx then
            DrawFXIndicators( container_idx, btn_min_x, btn_min_y, btn_max_x, btn_max_y, glow_color_u32 )
        end
    end
    
    return clicked, is_hovered, is_active, draw_list, btn_min_x, btn_min_y, btn_max_x, btn_max_y
end


-- Function to draw the signal buttons
function DrawTransientSustainButtons(button_width, button_height, transient_guid, sustain_guid)
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

    local transient_idx = find_container_in_tree(TREE, transient_guid)
    local sustain_idx = find_container_in_tree(TREE, sustain_guid)
    
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
    

    local Trans_Btn_scrnPos = { im.GetCursorScreenPos(ctx)}

    local transient_clicked, is_hovered, is_active, draw_list, btn_min_x, btn_min_y, btn_max_x, btn_max_y = DrawRadialButton( "Transient", single_button_width, button_height, TRANSIENT_BASE, TRANSIENT_GLOW, color_level, transient_guid, transient_idx )
    -- Use ThemeClr for sustain if available
    local sustain_glow = SUSTAIN_GLOW
    if ThemeClr then
        local accent = ThemeClr('Accent_Clr')
        -- Convert packed color to RGBA (0-1 range)
        sustain_glow = { ((accent >> 16) & 0xFF) / 255, ((accent >> 8) & 0xFF) / 255, (accent & 0xFF) / 255, ((accent >> 24) & 0xFF) / 255 }
    end
    
    -- Add drag-drop handling for transient button
        
    HandleContainerDragDrop("Transient", transient_guid, transient_idx)
    local Sldr_posX , Sldr_posY = im.GetCursorPos(ctx)
    AddContainerWetDrySlider(transient_guid, transient_idx, Sldr_posX, Sldr_posY-5, single_button_width, Wet_Dry_Drag_Height, true)
    local R, B = im.GetItemRectMax(ctx)
    HighlightSelectedItem( nil , fx.ChosenContainer == 'Transient' and  Transient_Color or  OutlineClr, 0, Trans_Btn_scrnPos[1], Trans_Btn_scrnPos[2], R-1, B, nil,nil, 1,1,nil,nil,nil, 1)

    
    AddSpacing(25)
    local Sldr_scr_pos= {im.GetCursorScreenPos(ctx)}
    local Sldr_posX , Sldr_posY = im.GetCursorPos(ctx)
    AddContainerWetDrySlider(sustain_guid, sustain_idx, Sldr_posX, Sldr_posY-10, single_button_width, Wet_Dry_Drag_Height, nil)
    -- Sustain button with radial effect
    local sustain_color_level = apply_response_curve(FXD_color_sustain) * 2.0
    local sustain_clicked, is_hovered, is_active, draw_list, btn_min_x, btn_min_y, btn_max_x, btn_max_y = DrawRadialButton( "Sustain", single_button_width, button_height, SUSTAIN_BASE, sustain_glow ,sustain_color_level, sustain_guid, sustain_idx )
    local R, B = im.GetItemRectMax(ctx)
    HighlightSelectedItem(nil , fx.ChosenContainer == 'Sustain' and  Sustain_Color or  OutlineClr ,0 , Sldr_scr_pos[1], Sldr_scr_pos[2]-10, R-2, B, nil,nil, 1,1,nil,nil,nil, 1)
    -- Add drag-drop handling for sustain button
 
    HandleContainerDragDrop("Sustain", sustain_guid, sustain_idx)
 
    im.PopStyleVar(ctx)


    if im.IsItemClicked(ctx, 0) and Mods == Shift + Ctrl then
        FX.LayEdit = FxGUID
    end

    -- Function to draw a custom bracket/enclosure for container FX
    function DrawCustomContainerEnclosure(draw_list, start_x, start_y, end_x, end_y, color, thickness, title)
        -- Calculate dimensions
        local width = end_x - start_x
        local height = end_y - start_y
        local bracket_width = 10  -- Width of the bracket extensions
        local rounding = 5       -- Rounded corners
        local fg = im.GetForegroundDrawList(ctx)
        
       --[[  -- Create a semi-transparent background for the container area
        local bg_color = im.ColorConvertDouble4ToU32(0.2, 0.2, 0.2, 0.3)  -- Slight darkening
        im.DrawList_AddRectFilled(draw_list, 
            start_x, start_y, 
            end_x, end_y, 
            bg_color, rounding) ]]
        
        -- Draw the left bracket ([) with distinctive style
        -- Top segment
        im.DrawList_AddLine(draw_list,
            start_x, start_y,
            start_x + bracket_width, start_y,
            color, thickness)
        
        -- Vertical segment - dotted/dashed line for distinction
        local dash_count = math.floor(height / 10)
        for i = 0, dash_count do
            local y_pos = start_y + i * 10
            if y_pos < end_y then
                im.DrawList_AddLine(draw_list,
                    start_x, y_pos,
                    start_x, math.min(y_pos + 5, end_y),
                    color, thickness)
            end
        end
        
        -- Bottom segment
        im.DrawList_AddLine(draw_list,
            start_x, end_y,
            start_x + bracket_width, end_y,
            color, thickness)
        
        -- Draw the right bracket (]) with distinctive style
        -- Top segment
        im.DrawList_AddLine(draw_list,
            end_x - bracket_width, start_y,
            end_x, start_y,
            color, thickness)
        
        -- Vertical segment - dotted/dashed line for distinction
        for i = 0, dash_count do
            local y_pos = start_y + i * 10
            if y_pos < end_y then
                im.DrawList_AddLine(draw_list,
                    end_x, y_pos,
                    end_x, math.min(y_pos + 5, end_y),
                    color, thickness)
            end
        end
        
        -- Bottom segment
        im.DrawList_AddLine(draw_list,
            end_x - bracket_width, end_y,
            end_x, end_y,
            color, thickness)
        -- Add a title to the top of the enclosure
        if title then
            local text_width, text_height = im.CalcTextSize(ctx, title)
            local text_x = start_x + (width - text_width) / 2  -- Center text
            local text_y = start_y - text_height - 5  -- Position above the enclosure
            
            -- Draw shadow for readability
            im.DrawList_AddText(fg, text_x + 1, text_y + 1, 0x80000000, title)
            -- Draw text
            im.DrawList_AddText(fg, text_x, text_y, color, title)
        end
        
        -- Add a subtle decorative element for distinction - small diagonal lines at corners
        local diag_len = 8  -- Length of diagonal lines
        

    end

    -- Update DrawContainerContents to include the enclosure
    function DrawContainerContents()
        -- Only proceed if a container is selected
        if not fx.ChosenContainer then return end

        -- Get the correct container GUID based on selection
        local container_guid = nil
        if fx.ChosenContainer == "Transient" then
            container_guid = FX[FxGUID].TransientContainer
        elseif fx.ChosenContainer == "Sustain" then
            container_guid = FX[FxGUID].SustainContainer
        end
        
        if not container_guid then return end

        -- Store the initial cursor position
        local initial_x, initial_y = im.GetCursorScreenPos(ctx)
        local initial_cursor_x, initial_cursor_y = im.GetCursorPos(ctx)

        local container_idx = find_container_in_tree(TREE, container_guid)
        if not container_idx then return end
        
        -- Get container FX count
        local ok, count = r.TrackFX_GetNamedConfigParm(track, container_idx, "container_count")
        if not ok or tonumber(count) <= 0 then return end
        
        local count_num = tonumber(count)
        
        -- Get the FX ID before the first FX in container
        local previous_fx_id = GetLastFXid_in_Container(container_idx)
        
        local enclosure_start_x, enclosure_start_y = nil, nil
        local tint_color = nil
        if fx.ChosenContainer == "Transient" then
            tint_color = Change_Clr_A(Transient_Color, -0.5)
        elseif fx.ChosenContainer == "Sustain" then
            tint_color = Change_Clr_A(Sustain_Color,-0.5)
        end
        -- Iterate through the FX in the container
        for i = 0, count_num - 1 do
            local ok, fx_idx_str = r.TrackFX_GetNamedConfigParm(track, container_idx, "container_item." .. i)
            if ok and fx_idx_str then
                local fx_id = tonumber(fx_idx_str)
                SL(nil,5)
                im.SetCursorPosY(ctx, 0)
                if i == 0 then
                    enclosure_start_x, enclosure_start_y = im.GetCursorScreenPos(ctx)
                end

                if fx_id then
                    local fx_guid = r.TrackFX_GetFXGUID(track, fx_id)
                    local _, fx_name = r.TrackFX_GetFXName(track, fx_id)
                    
                    -- Get the appropriate tint color based on container type
                   
                    
                    -- Pass the tint color to AddSpaceBtwnFXs
                    AddSpaceBtwnFXs(fx_id, nil, nil, nil, nil, nil, nil, nil, nil, tint_color)
                    im.SetCursorPosY(ctx, 0)
                    createFXWindow(fx_id)
                    SL(nil, 0)

                    local fx_W = FX[fx_guid] and FX[fx_guid].Width or Df.Default_FX_Width or 170
                    fx.Width = fx.Width + fx_W + Df.Dvdr_Width
                end
            end
        end
        
        -- Add space at the end of the container
        local end_position_id = TrackFX_GetInsertPositionInContainer(container_idx, count_num + 1)
        if end_position_id then
            im.SetCursorPosY(ctx, 0)
            AddSpaceBtwnFXs(end_position_id, nil, nil, nil, nil, nil, nil, nil, nil, tint_color)
            fx.Width = fx.Width + Df.Dvdr_Width
        end

        im.SetCursorPosY(ctx, 0)
        local enclosure_end_x = im.GetCursorScreenPos(ctx)
        local enclosure_end_y = enclosure_start_y + 224

        -- Draw the enclosure if we have valid coordinates
        if enclosure_start_x and enclosure_start_y and enclosure_end_x and enclosure_end_y then
            local _, container_name = r.TrackFX_GetFXName(track, container_idx)
            local enclosure_color = 0xFF66AAFF
            if fx.ChosenContainer == "Transient" then
                enclosure_color = Transient_Color
            elseif fx.ChosenContainer == "Sustain" then
                enclosure_color = Sustain_Color
            end
            
            local draw_list = im.GetWindowDrawList(ctx)
            DrawCustomContainerEnclosure(
                draw_list,
                enclosure_start_x,
                enclosure_start_y,
                enclosure_end_x,
                enclosure_end_y,
                enclosure_color,
                3.0,
                container_name
            )
        end

        -- Restore cursor position to where it was before drawing container contents
        im.SetCursorPos(ctx, initial_cursor_x, initial_cursor_y)
    end

    -- Leave space for container contents, if any are shown
    if fx.ChosenContainer then
        im.SameLine(ctx, nil, 20) -- Add spacing after buttons
        DrawContainerContents() -- Draw the selected container's contents
    end

    return transient_clicked, sustain_clicked
end

-- Function to handle drag and drop for container buttons
function HandleContainerDragDrop(button_type, container_guid, container_idx)
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
            if track and container_guid then
                
                if container_idx >= 0 then
                  
                    -- Calculate the FX_Id for insertion inside the container
                    -- This follows the pattern seen in Container.lua
                    local rv, container_count = r.TrackFX_GetNamedConfigParm(track, container_idx, 'container_count')
                    local targ_pos = TrackFX_GetInsertPositionInContainer(container_idx, tonumber(container_count) + 1)

                    
                    -- Get the container name for user feedback
                    local _, container_name = r.TrackFX_GetFXName(track, container_idx)
                    
                    -- Handle different actions based on payload type
                    if dropped_add then
                        -- Add new FX from browser
                        r.TrackFX_AddByName(track, payload_add, false, -1000 - targ_pos)
                    elseif dropped_move then
                        -- Move existing FX to container
                        -- DragFX_ID is a global that contains the ID of the FX being dragged
                        if DragFX_ID then
                            r.TrackFX_CopyToTrack(track, DragFX_ID, track, targ_pos, true)
                        end

                    end
                    BuildFXTree(track)
                    is_valid_target = true
                end
            end
        end
        
        im.EndDragDropTarget(ctx)
    end
    
    return is_valid_target
end
function MoveFX_BetweenContainers_Away(container_idx)
    -- Get the next FX indices using the proper container-aware function
    local next_idx1, next_idx2, next_idx3
    local fx_idx = container_idx
    next_idx1= GetNextAndPreviousFXID(fx_idx)
    next_idx2= GetNextAndPreviousFXID(next_idx1)
    next_idx3 = GetNextAndPreviousFXID(next_idx2)


    -- Check for any FX between the splitter and where containers should be
    
    
    if next_idx1 then
        local _, fx_name = r.TrackFX_GetFXName(track, next_idx1)
        local rv, renamed_name = r.TrackFX_GetNamedConfigParm(track, next_idx1, "renamed_name")
        if not (rv and renamed_name == "Transient") then
            MovFX.FromPos[1] = next_idx1
            MovFX.Lbl[1] = fx_name
            MovFX.ToPos[1] = next_idx3
        end
    end
    
    -- Check for FX between first and second container position

    if next_idx2 then
        local _, fx_name = r.TrackFX_GetFXName(track, next_idx2)
        local rv, renamed_name = r.TrackFX_GetNamedConfigParm(track, next_idx2, "renamed_name")
        if not (rv and renamed_name == "Sustain") and not MovFX.FromPos[1] then
            table.insert(MovFX.FromPos, next_idx2)
            table.insert(MovFX.Lbl, fx_name)
            table.insert(MovFX.ToPos, FX_Idx)
        end
    end


end
-- Function to detect or create Transient/Sustain containers after amplitude splitter
function DetectOrCreateSplitterContainers(fx_idx, fxguid)

    -- Try to load existing container GUIDs first
    local transient_guid, sustain_guid = LoadContainerGUIDsFromTrack(track, fxguid)
    
    -- If we have both GUIDs and they're valid, we can return early
    if transient_guid and sustain_guid then
        -- Verify the GUIDs still exist in the track

        local next_idx1= GetNextAndPreviousFXID_NEW(fx_idx)
        local guid1 = r.TrackFX_GetFXGUID(track, next_idx1)
    
        local transient_exists = guid1 == transient_guid and true or nil

        local next_idx2= GetNextAndPreviousFXID_NEW(next_idx1)
        local guid2 = r.TrackFX_GetFXGUID(track, next_idx2)
        local sustain_exists = guid2 == sustain_guid and true or nil

        
        if transient_exists and sustain_exists then
            return true, transient_guid, sustain_guid
        --[[ else 
            local transient_guid = find_container_in_tree(TREE, guid1)
            

            local sustain_guid = find_container_in_tree(TREE, guid2) ]]
        end
        
    end
    
    -- Check if track has enough channels (at least 4)
    local track_channels = r.GetMediaTrackInfo_Value(track, "I_NCHAN")
    if track_channels < 4 then
        r.SetMediaTrackInfo_Value(track, "I_NCHAN", 4)
    end
    
    -- Check if we have containers already
    local has_transient = false
    local has_sustain = false
    local transient_idx = -1
    local sustain_idx = -1
    local now = r.time_precise()

    -- Get the next FX indices using the proper container-aware function

    local next_idx1= GetNextAndPreviousFXID_NEW(fx_idx)

    
    -- Check if the containers exist - look carefully for exact match
    if next_idx1  then
        -- Check specifically for container named "Transient"
        local rv, renamed_name = r.TrackFX_GetNamedConfigParm(track, next_idx1, "renamed_name")
        if rv and renamed_name == "Transient" then
            local guid1 = r.TrackFX_GetFXGUID(track, next_idx1)
            if guid1 then
               
                has_transient = true
                transient_idx = next_idx1
                transient_guid = guid1
                FX[guid1] = FX[guid1] or {}
                FX[guid1].IsContainer = true
                FX[guid1].HideContainer = true
            end
        end
        if not has_transient then
            local container_idx = r.TrackFX_AddByName(track, "Container", false, -1)
            if container_idx >= 0 then
                r.TrackFX_Show(track, container_idx, 2)  -- Hide the FX window (2 = hide)
                r.TrackFX_SetNamedConfigParm(track, container_idx, "renamed_name", "Transient")
                transient_idx = container_idx
                transient_guid = r.TrackFX_GetFXGUID(track, container_idx)
                if transient_guid then
                    -- Set up container properties
                    FX[transient_guid] = FX[transient_guid] or {}
                    FX[transient_guid].IsContainer = true
                    FX[transient_guid].HideContainer = true
                    FX[transient_guid].Idx = container_idx
                    
                    -- Set input pins for transient (1,2)
                    r.TrackFX_SetPinMappings(track, container_idx, 0, 0, 1, 0)  -- input L
                    r.TrackFX_SetPinMappings(track, container_idx, 0, 1, 2, 0)  -- input R
                    
                   --[[  -- Move to correct position if needed
                    if container_idx ~= next_idx1 then
                        r.TrackFX_CopyToTrack(track, container_idx, track, next_idx1, true)
                        transient_idx = next_idx1
                        transient_guid = r.TrackFX_GetFXGUID(track, next_idx1)
                        r.TrackFX_Show(track, next_idx1, 2)  -- Hide the FX window after moving
                    end ]]
                    
                    has_transient = true
                end
            end
            local next_idx2= GetNextAndPreviousFXID_NEW(next_idx1)

            if next_idx2 then
            
                -- Check specifically for container named "Sustain"
                local rv, renamed_name = r.TrackFX_GetNamedConfigParm(track, next_idx2, "renamed_name")
                if rv and renamed_name == "Sustain" then
                    local guid2 = r.TrackFX_GetFXGUID(track, next_idx2)
                    if guid2 then
                        has_sustain = true
                        sustain_idx = next_idx2
                        sustain_guid = guid2
                        FX[guid2] = FX[guid2] or {}
                        FX[guid2].IsContainer = true
                        FX[guid2].HideContainer = true
                    end
                end
                
                -- Create Sustain container if needed
                if not has_sustain then
                    local container_idx = r.TrackFX_AddByName(track, "Container", false, -1)
                    if container_idx >= 0 then
                        r.TrackFX_Show(track, container_idx, 2)  -- Hide the FX window (2 = hide)
                        r.TrackFX_SetNamedConfigParm(track, container_idx, "renamed_name", "Sustain")
                        r.TrackFX_SetNamedConfigParm(track, container_idx, "parallel", "1")
                        sustain_idx = container_idx
                        sustain_guid = r.TrackFX_GetFXGUID(track, container_idx)
                        if sustain_guid then
                            -- Set up container properties
                            FX[sustain_guid] = FX[sustain_guid] or {}
                            FX[sustain_guid].IsContainer = true
                            FX[sustain_guid].HideContainer = true
                            FX[sustain_guid].Idx = container_idx
                            
                            -- Set input pins for sustain (3,4)
                            r.TrackFX_SetPinMappings(track, container_idx, 0, 0, 4, 0)  -- input L
                            r.TrackFX_SetPinMappings(track, container_idx, 0, 1, 8, 0)  -- input R
                            
                            --[[   -- Move to correct position if needed
                            if container_idx ~= next_idx2 then
                                r.TrackFX_CopyToTrack(track, container_idx, track, next_idx2, true)
                                sustain_idx = next_idx2
                                sustain_guid = r.TrackFX_GetFXGUID(track, next_idx2)
                                r.TrackFX_Show(track, next_idx2, 2)  -- Hide the FX window after moving
                            end ]]
                            
                            has_sustain = true
                        end
                    end
                end
            end
            -- After creating containers, save their GUIDs
            if has_transient and has_sustain then
                FX[fxguid] = FX[fxguid] or {}
                FX[fxguid].ContainersCreated = true
                FX[fxguid].TransientContainer = transient_guid
                FX[fxguid].SustainContainer = sustain_guid
                SaveContainerGUIDsToTrack(track, fxguid)
            end
        end

     
    end




        
 

    
    -- After checking for existing containers, create them if they don't exist

    -- Create Transient container if needed
    


    
    
    return has_transient and has_sustain, transient_guid, sustain_guid
end

function Put_All_In_Container(fx_idx)
    if fx.DonePuttingInContainer then return end 

    -- Function to check if Amplitude Splitter is in a container and create one if needed
    local track = LT_Track

    local fx_idx = Find_FxID_By_GUID(PluginScript.Guid)
    if not fx_idx then return end
    -- Get the parent container by checking if this FX has a container index
    local parent_container = tonumber(  select(2, r.TrackFX_GetNamedConfigParm(track, fx_idx, "parent_container")))
    if parent_container then
        local rv, Name = r.TrackFX_GetNamedConfigParm(track, fx_idx, "renamed_name")
        if Name == "Transient Split" then
            return parent_container
        end
    end
    -- If not in a container, create one and move the Amplitude Splitter into it
    if not parent_container   then
        

        -- Create a new container
        local container_idx = r.TrackFX_AddByName(track, "Container", false, -1000 -fx_idx)
        
        -- Rename the container to "Transient Split"
        r.TrackFX_SetNamedConfigParm(track, container_idx, "renamed_name", "Transient Split")
        
        -- Get the GUIDs we need
        local transient_guid = FX[FxGUID].TransientContainer
        local sustain_guid = FX[FxGUID].SustainContainer
        
        -- Move the Amplitude Splitter into the container at position 0
        local insert_pos = TrackFX_GetInsertPositionInContainer(container_idx, 1)
        local fx_idx = fx_idx + 1
        r.TrackFX_CopyToTrack(track, fx_idx, track, insert_pos, true)
     
        
        -- Find the indices for the transient and sustain containers
        local transient_idx
        local sustain_idx 

        local next_idx1= GetNextAndPreviousFXID(fx_idx)

        
        for i = 0, r.TrackFX_GetCount(track) - 1 do
            local guid = r.TrackFX_GetFXGUID(track, i)
            if guid == transient_guid then
                transient_idx = i
            elseif guid == sustain_guid then
                sustain_idx = i
            end
        end
        
        -- Move the Transient container into the new container at position 1
        if transient_idx >= 0 then
            local insert_pos = TrackFX_GetInsertPositionInContainer(container_idx, 2)
            r.TrackFX_CopyToTrack(track, transient_idx, track, insert_pos, true)
        end
        
        -- Move the Sustain container into the new container at position 2

        local insert_pos = TrackFX_GetInsertPositionInContainer(container_idx, 3)
        r.TrackFX_CopyToTrack(track, sustain_idx-1, track, insert_pos, true)
       
        fx.DonePuttingInContainer = true
        -- Return the new container index for further operations
        return container_idx

    end
    
    return parent_container
end

-- Add this function to save container GUIDs to track data
function SaveContainerGUIDsToTrack(track, fxguid)
    if not track or not fxguid then return end
    
    local fx_data = FX[fxguid]
    if not fx_data then return end
    
    -- Save Transient container GUID
    if fx_data.TransientContainer then
        r.GetSetMediaTrackInfo_String(track, 'P_EXT: AmplitudeSplitter_' .. fxguid .. '_TransientContainer', fx_data.TransientContainer, true)
    end
    
    -- Save Sustain container GUID
    if fx_data.SustainContainer then
        r.GetSetMediaTrackInfo_String(track, 'P_EXT: AmplitudeSplitter_' .. fxguid .. '_SustainContainer', fx_data.SustainContainer, true)
    end
end

-- Add this function to load container GUIDs from track data
function LoadContainerGUIDsFromTrack(track, fxguid)
    if not track or not fxguid then return end
    
    FX[fxguid] = FX[fxguid] or {}
    
    -- Load Transient container GUID
    local rv, transient_guid = r.GetSetMediaTrackInfo_String(track, 'P_EXT: AmplitudeSplitter_' .. fxguid .. '_TransientContainer', '', false)
    if rv and transient_guid ~= '' then
        FX[fxguid].TransientContainer = transient_guid
    end
    
    -- Load Sustain container GUID
    local rv, sustain_guid = r.GetSetMediaTrackInfo_String(track, 'P_EXT: AmplitudeSplitter_' .. fxguid .. '_SustainContainer', '', false)
    if rv and sustain_guid ~= '' then
        FX[fxguid].SustainContainer = sustain_guid
    end
    
    return FX[fxguid].TransientContainer, FX[fxguid].SustainContainer
end

local _, transient_guid, sustain_guid = DetectOrCreateSplitterContainers(FX_Idx, FxGUID)
im.PushFont(ctx, Font_Andale_Mono_11)
DrawTransientSustainButtons(50, 60,  transient_guid, sustain_guid)
im.PopFont(ctx)

if FX_Adder_Idx then 
    if fx.MenuPosition then
        im.SetNextWindowPos(ctx, fx.MenuPosition.x, fx.MenuPosition.y)
    end
    AddFX_Menu(FX_Adder_Idx)  end
MoveFX_BetweenContainers_Away(FX_Idx)
Put_All_In_Container(FX_Idx)

-- Add this in your container plugin script or where you display containers:
function ShouldShowContainer(fxguid)
    if FX[fxguid] and FX[fxguid].HideContainer then
        return false  -- Don't show containers marked as hidden
    end
    return true  -- Show all other containers
end




