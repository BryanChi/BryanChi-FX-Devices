-- @noindex

demo = {}
--- add a doc/helper tooltip
---@param desc string
function demo.HelpMarker(desc)
    ImGui.TextDisabled(ctx, '(?)')
    if ImGui.IsItemHovered(ctx) then
        ImGui.BeginTooltip(ctx)
        ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
        ImGui.Text(ctx, desc)
        ImGui.PopTextWrapPos(ctx)
        ImGui.EndTooltip(ctx)
    end
end

function demo.PopStyle()
    if app.style_editor and app.style_editor.push_count > 0 then
        app.style_editor.push_count = app.style_editor.push_count - 1
        ImGui.PopStyleColor(ctx, #cache['Col'])
        --ImGui.PopStyleVar(ctx, #cache['StyleVar'])
    elseif NeedtoPopStyle then
        for i in demo.EachEnum('Col') do
            ImGui.PopStyleColor(ctx)
        end
    elseif DefaultThemeActive then
        ImGui.PopStyleColor(ctx, DefaultStylePop)
    end
end

function demo.PushStyle()
    if app.style_editor then
        app.style_editor.push_count = app.style_editor.push_count + 1
        --[[ for i, value in pairs(app.style_editor.style.vars) do
                    if type(value) == 'table' then
                        ImGui.PushStyleVar(ctx, i, table.unpack(value))
                    else
                        ImGui.PushStyleVar(ctx, i, value)
                    end
            end ]]
        for i, value in pairs(app.style_editor.style.colors) do
            ImGui.PushStyleColor(ctx, i, value)
        end
    else
        local file_path = ConcatPath(r.GetResourcePath(), 'Scripts', 'FX Devices', 'BryanChi_FX_Devices',
            'src', 'ThemeColors.ini')
        local file = io.open(file_path, 'r')



        if file then
            local content = file:read("a+")




            for i, v in pairs(CustomColors) do
                _G[v] = RecallGlobInfo(content, v .. ' = ', 'Num')
            end
        end
        DefaultThemeActive = true
        ------------------- Default Color Theme --------------------
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x48484837)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x49494966)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0x3F3F3FAB)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x57575786)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x6F6F6F86)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0x90909086)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0x57575786)
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, 0x616161FF)
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, 0xD1D1D1AC)
        DefaultStylePop = 9
    end
end

---@param enum string
---@return function
function demo.EachEnum(enum)
    local enum_cache = cache[enum]
    if not enum_cache then
        enum_cache = {}
        cache[enum] = enum_cache

        for func_name, func in pairs(reaper) do
            local enum_name = func_name:match(('^ImGui_%s_(.+)$'):format(enum))
            if enum_name then
                table.insert(enum_cache, { func(), enum_name })
            end
        end
        table.sort(enum_cache, function(a, b) return a[1] < b[1] end)
    end

    local i = 0
    return function()
        i = i + 1
        if not enum_cache[i] then return end
        return table.unpack(enum_cache[i])
    end
end

---@param mode openmode
---@param filename string
---@param folder? string
---@return file*?
---@return string
function CallFile(mode, filename, folder)
    local dir_path
    if folder then
        dir_path = ConcatPath(CurrentDirectory, 'src', folder)
    else
        dir_path = ConcatPath(CurrentDirectory, 'src')
    end
    local file_path = ConcatPath(dir_path, filename)

    -- Create directory for file if it doesn't exist
    r.RecursiveCreateDirectory(dir_path, 0)
    local file = io.open(file_path, mode)
    return file, file_path
end

function PushStyle_AtScriptStart()
    local file, file_path = CallFile('r', 'ThemeColors.ini')
    if file then
        local Lines = get_lines(file_path)
        for i in demo.EachEnum('Col') do
            ImGui.PushStyleColor(ctx, 1, 0x372837ff)
        end
    else
        ----- Default Color theme ---------------
    end
end

--PushStyle_AtScriptStart()



function demo.GetStyleData()
    local data = { vars = {}, colors = {} }
    local vec2 = {
        'ButtonTextAlign', 'SelectableTextAlign', 'CellPadding', 'ItemSpacing',
        'ItemInnerSpacing', 'FramePadding', 'WindowPadding', 'WindowMinSize',
        'WindowTitleAlign', 'SeparatorTextAlign', 'SeparatorTextPadding'
    }

    for i, name in demo.EachEnum('StyleVar') do
        local rv = { ImGui.GetStyleVar(ctx, i) }
        local is_vec2 = false
        for _, vec2_name in ipairs(vec2) do
            if vec2_name == name then
                is_vec2 = true
                break
            end
        end
        data.vars[i] = is_vec2 and rv or rv[1]
    end
    for i in demo.EachEnum('Col') do
        data.colors[i] = ImGui.GetStyleColor(ctx, i)
    end
    return data
end

function demo.CopyStyleData(source, target)
    for i, value in pairs(source.vars) do
        if type(value) == 'table' then
            target.vars[i] = { table.unpack(value) }
        else
            target.vars[i] = value
        end
    end
    for i, value in pairs(source.colors) do
        target.colors[i] = value
    end
end

function ShowStyleEditor()
    local rv


    if not ctx then ctx = ImGui.CreateContext('Style Editor 2') end
    if not styleEditorIsOpen then ImGui.SetNextWindowSize(ctx, 500, 800) end
    open, OpenStyleEditor = ImGui.Begin(ctx, 'FX Devices Style Editor', OpenStyleEditor,
        ImGui.WindowFlags_TopMost + ImGui.WindowFlags_NoCollapse +
        ImGui.WindowFlags_NoDocking --[[ +ImGui.WindowFlags_AlwaysAutoResize ]])


    if open then
        styleEditorIsOpen = true
        if not app.style_editor then
            app.style_editor = {
                style                = demo.GetStyleData(),
                ref                  = demo.GetStyleData(),
                output_dest          = 0,
                output_only_modified = false,
                push_count           = 0,
            }
        end

        ImGui.PushItemWidth(ctx, ImGui.GetWindowWidth(ctx) * 0.50)

        local FrameRounding, GrabRounding = ImGui.StyleVar_FrameRounding,
            ImGui.StyleVar_GrabRounding
        --[[ rv,app.style_editor.style.vars[FrameRounding] = ImGui.SliderDouble(ctx, 'FrameRounding', app.style_editor.style.vars[FrameRounding], 0.0, 12.0, '%.0f')
            if rv then
            app.style_editor.style.vars[GrabRounding] = app.style_editor.style.vars[FrameRounding] -- Make GrabRounding always the same value as FrameRounding
            end ]]

        ImGui.PushItemWidth(ctx, ImGui.GetFontSize(ctx) * 8)

        local Alpha, DisabledAlpha = ImGui.StyleVar_Alpha, ImGui.StyleVar_DisabledAlpha
        rv, app.style_editor.style.vars[Alpha] = ImGui.DragDouble(ctx, 'Global Alpha',
            app.style_editor.style.vars[Alpha], 0.005, 0.20, 1.0, '%.2f') -- Not exposing zero here so user doesn't "lose" the UI (zero alpha clips all widgets). But application code could have a toggle to switch between zero and non-zero.
        ImGui.SameLine(ctx)
        rv, app.style_editor.style.vars[DisabledAlpha] = ImGui.DragDouble(ctx, 'Disabled Alpha',
            app.style_editor.style.vars[DisabledAlpha], 0.005, 0.0, 1.0, '%.2f'); ImGui.SameLine(ctx); demo
            .HelpMarker('Additional alpha multiplier for disabled items (multiply over current value of Alpha).')
        ImGui.PopItemWidth(ctx)







        local borders = { 'WindowBorder', 'FrameBorder', 'PopupBorder' }
        for i, name in ipairs(borders) do
            local var = r[('ImGui_StyleVar_%sSize'):format(name)]()
            local enable = app.style_editor.style.vars[var] > 0
            if i > 1 then ImGui.SameLine(ctx) end
            rv, enable = ImGui.Checkbox(ctx, name, enable)
            if rv then app.style_editor.style.vars[var] = enable and 1 or 0 end
        end

        -- Save/Revert button
        --[[ if ImGui.Button(ctx, 'Save Ref') then
            demo.CopyStyleData(app.style_editor.style, app.style_editor.ref)
            end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, 'Revert Ref') then
            demo.CopyStyleData(app.style_editor.ref, app.style_editor.style)
            end
            ImGui.SameLine(ctx) ]]

        --[[ ImGui.SameLine(ctx)
            demo.HelpMarker(
            'Save/Revert in local non-persistent storage. Default Colors definition are not affected. \z
            Use "Export" below to save them somewhere.')
            ImGui.SameLine(ctx)
            ]]

        --[[ if ImGui.Button(ctx, 'Factory Reset Color Theme') then
                DltClrTheme = true
            end
            if DltClrTheme then

                local file, file_path = CallFile('a', 'ThemeColors.ini')
                if ImGui.BeginPopup( ctx, 'You Sure you want to delete color theme?',ImGui.WindowFlags_NoTitleBar|ImGui.WindowFlags_NoResize ) then

                    if ImGui.Button(ctx, 'No') then DltClrTheme = false  ImGui.CloseCurrentPopup(ctx)    end
                    if ImGui.Button(ctx, 'Yes') then file:close() file:remove(file_path) DltClrTheme=false  end
                    ImGui.EndPopup(ctx)
                end
            end  ]]

        local export = function(enumName, funcSuffix, curTable, refTable, isEqual, formatValue)
            local lines, name_maxlen = {}, 0
            for i, name in demo.EachEnum(enumName) do
                if not app.style_editor.output_only_modified or not isEqual(curTable[i], refTable[i]) then
                    table.insert(lines, { name, curTable[i] })
                    name_maxlen = math.max(name_maxlen, name:len())
                end
            end

            if app.style_editor.output_dest == 0 then
                ImGui.LogToClipboard(ctx)
            else
                ImGui.LogToTTY(ctx)
            end
            for _, line in ipairs(lines) do
                local pad = string.rep('\x20', name_maxlen - line[1]:len())
                ImGui.LogText(ctx, ('ImGui.Push%s(ctx, ImGui.%s_%s(),%s %s)\n')
                    :format(funcSuffix, enumName, line[1], pad, formatValue(line[2])))
            end
            if #lines == 1 then
                ImGui.LogText(ctx, ('\nImGui.Pop%s(ctx)\n'):format(funcSuffix))
            elseif #lines > 1 then
                ImGui.LogText(ctx, ('\nImGui.Pop%s(ctx, %d)\n'):format(funcSuffix, #lines))
            end
            ImGui.LogFinish(ctx)
        end

        --[[  if ImGui.Button(ctx, 'Export Vars') then
                --- for enum
                export('StyleVar', 'StyleVar', app.style_editor.style.vars, app.style_editor.ref.vars,
                function(a, b) if type(a) == 'table' then return a[1] == b[1] and a[2] == b[2] else return a == b end end,
                function(val) if type(val) == 'table' then return ('%g, %g'):format(table.unpack(val)) else return ('%g'):format(val) end end)
            end
            ImGui.SameLine(ctx) ]]
        if ImGui.Button(ctx, 'Save Color Settings') then
            -- for each enum
            local file = CallFile('w', 'ThemeColors.ini')

            if file then
                --[[ for i, name in demo.EachEnum('Col') do
                        if ImGui.TextFilter_PassFilter(app.style_editor.colors.filter.inst, name) then
                            file:write(name, ' - ', ImGui.GetStyleColor(ctx, )'\n')
                        end
                    end ]]

                for i, value in pairs(app.style_editor.style.colors) do
                    --[[ if i == 0 then
                            file:write(55, ' = ', ImGui.GetStyleColor(ctx,ImGui.Col_ModalWindowDimBg ),'\n')
                        elseif i > 0 then
                            file:write(i, ' = ', app.style_editor.style.colors[i-1],'\n')
                        end ]]
                end
                --[[ for i, name in demo.EachEnum('Col') do
                        file:write(name..' = '.. ImGui.GetStyleColor(ctx,ImGui.Col_ModalWindowDimBg ))
                    end  ]]





                for i, v in pairs(CustomColors) do
                    file:write(v, ' = ', _G[v], '\n')
                end
            end
            --[[ export('Col', 'StyleColor', app.style_editor.style.colors, app.style_editor.ref.colors, ]]
            --[[ function(a, b) return a == b end, function(val) return ('0x%08X'):format(val & 0xffffffff) end) ]]
        end








        ImGui.Separator(ctx)

        --if ImGui.BeginTabBar(ctx, '##tabs', ImGui.TabBarFlags_None) then
        --[[  if ImGui.BeginTabItem(ctx, 'Sizes') then
                local slider = function(varname, min, max, format)
                local func = r['ImGui_StyleVar_' .. varname]
                assert(func, ('%s is not exposed as a StyleVar'):format(varname))
                local var = func()
                if type(app.style_editor.style.vars[var]) == 'table' then
                    local rv,val1,val2 = ImGui.SliderDouble2(ctx, varname, app.style_editor.style.vars[var][1], app.style_editor.style.vars[var][2], min, max, format)
                    if rv then app.style_editor.style.vars[var] = { val1, val2 } end
                else
                    local rv,val = ImGui.SliderDouble(ctx, varname, app.style_editor.style.vars[var], min, max, format)
                    if rv then app.style_editor.style.vars[var] = val end
                end
                end

                ImGui.Text(ctx, 'Main')
                slider('WindowPadding',     0.0, 20.0, '%.0f')
                slider('FramePadding',      0.0, 20.0, '%.0f')
                slider('CellPadding',       0.0, 20.0, '%.0f')
                slider('ItemSpacing',       0.0, 20.0, '%.0f')
                slider('ItemInnerSpacing',  0.0, 20.0, '%.0f')
                -- slider('TouchExtraPadding', 0.0, 10.0, '%.0f')
                slider('IndentSpacing',     0.0, 30.0, '%.0f')
                slider('ScrollbarSize',     1.0, 20.0, '%.0f')
                slider('GrabMinSize',       1.0, 20.0, '%.0f')
                ImGui.Text(ctx, 'Borders')
                slider('WindowBorderSize', 0.0, 1.0, '%.0f')
                slider('ChildBorderSize',  0.0, 1.0, '%.0f')
                slider('PopupBorderSize',  0.0, 1.0, '%.0f')
                slider('FrameBorderSize',  0.0, 1.0, '%.0f')
                -- slider('TabBorderSize',    0.0, 1.0, '%.0f')
                ImGui.Text(ctx, 'Rounding')
                slider('WindowRounding',    0.0, 12.0, '%.0f')
                slider('ChildRounding',     0.0, 12.0, '%.0f')
                slider('FrameRounding',     0.0, 12.0, '%.0f')
                slider('PopupRounding',     0.0, 12.0, '%.0f')
                slider('ScrollbarRounding', 0.0, 12.0, '%.0f')
                slider('GrabRounding',      0.0, 12.0, '%.0f')
                -- slider('LogSliderDeadzone', 0.0, 12.0, '%.0f')
                slider('TabRounding',       0.0, 12.0, '%.0f')
                ImGui.Text(ctx, 'Alignment')
                slider('WindowTitleAlign', 0.0, 1.0, '%.2f')
                -- int window_menu_button_position = app.style_editor.style.WindowMenuButtonPosition + 1
                -- if (ctx, ImGui.Combo(ctx, 'WindowMenuButtonPosition', (ctx, int*)&window_menu_button_position, "None\0Left\0Right\0"))
                --     app.style_editor.style.WindowMenuButtonPosition = window_menu_button_position - 1
                -- ImGui.Combo(ctx, 'ColorButtonPosition', (ctx, int*)&app.style_editor.style.ColorButtonPosition, "Left\0Right\0")
                slider('ButtonTextAlign', 0.0, 1.0, '%.2f')
                ImGui.SameLine(ctx); demo.HelpMarker('Alignment applies when a button is larger than its text content.')
                slider('SelectableTextAlign', 0.0, 1.0, '%.2f')
                ImGui.SameLine(ctx); demo.HelpMarker('Alignment applies when a selectable is larger than its text content.')
                -- ImGui.Text(ctx, 'Safe Area Padding')
                -- ImGui.SameLine(ctx); demo.HelpMarker('Adjust if you cannot see the edges of your screen (ctx, e.g. on a TV where scaling has not been configured).')
                -- slider('DisplaySafeAreaPadding', 0.0, 30.0, '%.0f')
                ImGui.EndTabItem(ctx)
            end ]]

        --[[ if ImGui.BeginTabItem(ctx, 'Colors') then ]]
        if not app.style_editor.colors then
            app.style_editor.colors = {
                filter = { inst = nil, text = '' },
                alpha_flags = ImGui.ColorEditFlags_AlphaPreviewHalf,
            }
        end





        -- the filter object is destroyed once unused for one or more frames
        if not ImGui.ValidatePtr(app.style_editor.colors.filter.inst, 'ImGui_TextFilter*') then
            app.style_editor.colors.filter.inst = ImGui.CreateTextFilter(app.style_editor.colors.filter.text)
        end

        if ImGui.TextFilter_Draw(app.style_editor.colors.filter.inst, ctx, 'Filter colors', ImGui.GetFontSize(ctx) * 16) then
            app.style_editor.colors.filter.text = ImGui.TextFilter_Get(app.style_editor.colors.filter.inst)
        end

        if ImGui.RadioButton(ctx, 'Opaque', app.style_editor.colors.alpha_flags == ImGui.ColorEditFlags_None) then
            app.style_editor.colors.alpha_flags = ImGui.ColorEditFlags_None
        end
        ImGui.SameLine(ctx)
        if ImGui.RadioButton(ctx, 'Alpha', app.style_editor.colors.alpha_flags == ImGui.ColorEditFlags_AlphaPreview) then
            app.style_editor.colors.alpha_flags = ImGui.ColorEditFlags_AlphaPreview
        end
        ImGui.SameLine(ctx)
        if ImGui.RadioButton(ctx, 'Both', app.style_editor.colors.alpha_flags == ImGui.ColorEditFlags_AlphaPreviewHalf) then
            app.style_editor.colors.alpha_flags = ImGui.ColorEditFlags_AlphaPreviewHalf
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker(
            'In the color list:\n\z
                Left-click on color square to open color picker,\n\z
                Right-click to open edit options menu.')

        if ImGui.BeginChild(ctx, '##colors', 0, 0, ImGui.ChildFlags_Border,
                ImGui.WindowFlags_AlwaysVerticalScrollbar   |

                -- ImGui.WindowFlags_NavFlattened()) TODO: BETA/INTERNAL, not exposed yet
                0) then
            ImGui.PushItemWidth(ctx, -160)
            local inner_spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing)

            -- @todo  add custom colors here
            function addClr(str)
                rv, _G[str] = ImGui.ColorEdit4(ctx, '##' .. str, _G[str],
                    ImGui.ColorEditFlags_AlphaBar | app.style_editor.colors.alpha_flags)
                ImGui.SameLine(ctx, 0.0, inner_spacing)
                ImGui.Text(ctx, str)
            end

            ImGui.Text(ctx, 'Specific Colors')
            AddSpacing(2)

            for i, v in pairs(CustomColors) do
                if ImGui.TextFilter_PassFilter(app.style_editor.colors.filter.inst, v) then
                    rv, _G[v] = ImGui.ColorEdit4(ctx, '##' .. v, _G[v] or CustomColorsDefault[v],
                        ImGui.ColorEditFlags_AlphaBar | app.style_editor.colors.alpha_flags)
                    ImGui.SameLine(ctx, 0.0, inner_spacing)
                    local name = string.gsub(v, '_', ' ')
                    ImGui.Text(ctx, name)
                end
            end




            --[[ for i, name in demo.EachEnum('Col') do
                        if ImGui.TextFilter_PassFilter(app.style_editor.colors.filter.inst, name) then
                            ImGui.PushID(ctx, i)
                            rv, app.style_editor.style.colors[i] = ImGui.ColorEdit4(ctx, '##color', app.style_editor.style.colors[i], ImGui.ColorEditFlags_AlphaBar | app.style_editor.colors.alpha_flags)
                            if app.style_editor.style.colors[i] ~= app.style_editor.ref.colors[i] then
                                -- Tips: in a real user application, you may want to merge and use an icon font into the main font,
                                -- so instead of "Save"/"Revert" you'd use icons!
                                -- Read the FAQ and docs/FONTS.md about using icon fonts. It's really easy and super convenient!
                                ImGui.SameLine(ctx, 0.0, inner_spacing)
                                if ImGui.Button(ctx, 'Save') then
                                app.style_editor.ref.colors[i] = app.style_editor.style.colors[i]
                                end
                                ImGui.SameLine(ctx, 0.0, inner_spacing)
                                if ImGui.Button(ctx, 'Revert') then
                                app.style_editor.style.colors[i] = app.style_editor.ref.colors[i]
                                end
                            end
                            ImGui.SameLine(ctx, 0.0, inner_spacing)
                            ImGui.Text(ctx, name)
                            ImGui.PopID(ctx)
                        end
                    end ]]





            ImGui.PopItemWidth(ctx)
            ImGui.EndChild(ctx)
        end

        --ImGui.EndTabItem(ctx)
        --[[ end ]]



        --ImGui.EndTabBar(ctx)
        --end

        ImGui.PopItemWidth(ctx)
        ImGui.End(ctx)
    else
        styleEditorIsOpen = false
    end
end

function Show_KBShortcutEditor()
    local rv

    if not ctx then ctx = ImGui.CreateContext('Shortcut Editor') end
    if not KBEditorIsOpen then ImGui.SetNextWindowSize(ctx, 500, 800) end
    open, OpenKBEditor = ImGui.Begin(ctx, 'FX Devices Shortcut Editor', OpenKBEditor,
        ImGui.WindowFlags_NoCollapse +
        ImGui.WindowFlags_NoDocking --[[ +ImGui.WindowFlags_AlwaysAutoResize ]])


    if open then
        KBEditorIsOpen = true
        --[[ rv = ImGui.BeginTable(ctx, 'Keyboard Shortcut Table',  1 ,nil  ,  outer_size_w ,  outer_size_h, inner_width )
            ImGui.Text(ctx, 'adfafd')
            ImGui.EndTable(ctx) ]]

        local HoverKeyTime = HoverKeyTime or 0

        if ImGui.Button(ctx, '+') then
            local x, y = ImGui.GetWindowPos(ctx)
            local w, h = ImGui.GetWindowSize(ctx)

            ImGui.SetNextWindowPos(ctx, x + w / 3.5, y + h / 2)
            ImGui.OpenPopup(ctx, '##Type Key Popup')
        end
        SL()

        if ImGui.Button(ctx, 'Save') then
            local file = CallFile('w', 'Keyboard Shortcuts.ini')
            for i, v in pairs(KB_Shortcut) do
                file:write(v, ' = ', Command_ID[i], '\n')
            end
        end


        SL()
        MyText('(?)', nil, 0xffffff66)
        if ImGui.IsItemHovered(ctx) then
            HintToolTip(
                'Start by click on the + and entering a key or key combination \nLeft click on a shortcut key to swap assigned actions \nAlt+Left click to remove shortcut')
        end


        if ImGui.BeginPopupModal(ctx, '##Type Key Popup', nil, ImGui.WindowFlags_NoTitleBar|ImGui.WindowFlags_AlwaysAutoResize) then
            ImGui.Text(ctx, 'Type Key or mouse-click to cancel')

            for i, v in pairs(AllAvailableKeys) do
                if ImGui.IsKeyPressed(ctx, v) then
                    local function GetFinalTxt(i)
                        local txt
                        if Mods == 0 then
                            txt = i
                        elseif Mods == Alt then
                            txt = 'Alt + ' .. i
                        elseif Mods == Ctrl then
                            txt = 'Ctrl + ' .. i
                        elseif Mods == Shift then
                            txt = 'Shift + ' .. i
                        elseif Mods == Apl then
                            txt = 'Cmd + ' .. i
                        elseif Mods == Alt + Ctrl then
                            txt = 'Alt + Ctrl + ' .. i
                        elseif Mods == Ctrl + Shift then
                            txt = 'Ctrl + Shift + ' .. i
                        elseif Mods == Alt + Shift then
                            txt = 'Alt + Shift + ' .. i
                        elseif Mods == Alt + Apl then
                            txt = 'Alt + Cmd + ' .. i
                        elseif Mods == Shift + Apl then
                            txt = 'Shift + Cmd + ' .. i
                        elseif Mods == Ctrl + Apl then
                            txt = 'Ctrl + Cmd' .. i
                        end
                        return txt
                    end

                    if ShortCutKeyToSwitch then
                        if not tablefind(KB_Shortcut, GetFinalTxt(i)) then
                            KB_Shortcut[ShortCutKeyIndex] = GetFinalTxt(i)
                        end

                        AlreadyAddedKey = GetFinalTxt(i)

                        ShortCutKeyToSwitch = nil
                        ShortCutKeyIndex = nil
                    elseif not tablefind(KB_Shortcut, GetFinalTxt(i)) then
                        table.insert(KB_Shortcut, GetFinalTxt(i))
                    end



                    ImGui.CloseCurrentPopup(ctx)
                end
            end

            if ImGui.IsMouseClicked(ctx, 0) then
                ImGui.CloseCurrentPopup(ctx)
            end

            ImGui.EndPopup(ctx)
        end


        for i, v in ipairs(KB_Shortcut) do
            if ImGui.Button(ctx, v) then
                ShortCutKeyToSwitch = v
                ShortCutKeyIndex = i
                ImGui.OpenPopup(ctx, '##Type Key Popup')
            end

            if ImGui.IsItemClicked(ctx) and Mods == Alt then
                table.remove(KB_Shortcut, i)
            end


            if AlreadyAddedKey == v then
                ImGui.SetScrollHereY(ctx)
                _, stop = BlinkItem(0.3, 3.5)
                if stop == 'Stop' then AlreadyAddedKey = nil end
            end

            SL()
            ImGui.Text(ctx, ' : ')
            SL()
            local CmdTxt, commandID


            if Command_ID[i] then
                commandID = r.NamedCommandLookup(Command_ID[i])
                CmdTxt = r.CF_GetCommandText(0, commandID)
            end
            if CmtTxt == '' then CmdTxt = nil end

            if ImGui.Button(ctx, (CmdTxt or ' Click to Paste Command ID') .. '##' .. i) then
                Command_ID[i] = ImGui.GetClipboardText(ctx)
            end

            if AlreadyAddedKey == v then
                _, stop = BlinkItem(0.3, 3.5)
            end



            --rv, Command_ID[i] = ImGui.InputText(ctx, '##'..i , Command_ID[i] or 'Paste Command ID Here...', ImGui.InputTextFlags_AutoSelectAll)

            ImGui.Separator(ctx)
        end







        ImGui.End(ctx)
    else
        KBEditorIsOpen = false
    end
end
