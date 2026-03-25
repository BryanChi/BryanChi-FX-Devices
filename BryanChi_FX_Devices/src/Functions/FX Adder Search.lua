-- @noindex
-- FX add / search UI and helpers (adapted from CRS Vertical FX List)

local PATH_SEP = package.config:sub(1, 1)

function FX_Adder_CachePath()
    return (CurrentDirectory or '') .. 'src' .. PATH_SEP .. 'FX_Adder_Cache' .. PATH_SEP
end

local function FX_Adder_EnsureCacheDir()
    local d = FX_Adder_CachePath()
    if r.RecursiveCreateDirectory then
        r.RecursiveCreateDirectory(d, 0)
    end
    return d
end

function NormalizeHyphensAndSpaces(text)
    if not text then return '' end
    local result = text:gsub('-', ' '):gsub('%s+', ' ')
    return result:match('^%s*(.-)%s*$') or ''
end

function NormalizeFXName(fx_name)
    if not fx_name then return '' end
    local base = fx_name:match('^[^:]+:(.+)$') or fx_name
    base = base:gsub('%.vst3$', ''):gsub('%.vst$', ''):gsub('%.dll$', ''):gsub('%.jsfx$', ''):gsub('%.au$', '')
    base = base:match('([^/\\]+)$') or base
    return base:lower()
end

FX_CATEGORIES = FX_CATEGORIES or {}
FX_CATEGORIES_LOOKUP = FX_CATEGORIES_LOOKUP or {}
FX_LIST_TO_CATEGORIES = FX_LIST_TO_CATEGORIES or {}
FX_CATEGORY_SET = FX_CATEGORY_SET or {}
FX_Favorites = FX_Favorites or {}
FX_Favorites_Order = FX_Favorites_Order or {}
FX_Search_ActiveFilters = FX_Search_ActiveFilters or { category = nil, manufacturer = nil }
FX_Search_WindowSize = FX_Search_WindowSize or { w = 528, h = 400 }
FX_Search_WindowPos = FX_Search_WindowPos
FX_Search_Cache = FX_Search_Cache
FX_Search_Section = FX_Search_Section
PluginTypeOrder = PluginTypeOrder or { "VST3", "VST", "AU", "CLAP", "JS" }

local function LoadFXCategories()
    local resource_path = r.GetResourcePath()
    local fxtags_path = resource_path .. PATH_SEP .. "reaper-fxtags.ini"
    FX_CATEGORIES = {}
    FX_CATEGORIES_LOOKUP = {}
    FX_CATEGORY_SET = {}
    local file = io.open(fxtags_path, 'r')
    if not file then return end
    local in_category_section = false
    for line in file:lines() do
        line = line:match('^%s*(.-)%s*$') or ''
        if line == '[category]' then
            in_category_section = true
        elseif line:match('^%[') then
            in_category_section = false
        elseif in_category_section and line ~= '' and not line:match('^%s*;') then
            local fx_name, categories_str = line:match('^([^=]+)=(.+)$')
            if fx_name and categories_str then
                fx_name = fx_name:match('^%s*(.-)%s*$')
                categories_str = categories_str:match('^%s*(.-)%s*$')
                local normalized_name = NormalizeFXName(fx_name)
                local categories = {}
                for cat in categories_str:gmatch('([^|]+)') do
                    cat = cat:match('^%s*(.-)%s*$')
                    if cat ~= '' then
                        table.insert(categories, cat)
                        FX_CATEGORIES_LOOKUP[cat] = FX_CATEGORIES_LOOKUP[cat] or {}
                        table.insert(FX_CATEGORIES_LOOKUP[cat], fx_name)
                        FX_CATEGORY_SET[cat:lower()] = true
                    end
                end
                if #categories > 0 then
                    FX_CATEGORIES[fx_name] = {
                        categories = categories,
                        primary = categories[1],
                        normalized = normalized_name
                    }
                end
            end
        end
    end
    file:close()
end

local function GetCategoryCachePath()
    return FX_Adder_CachePath() .. "fx_category_cache.lua"
end

local function SaveCategoryCache()
    if not FX_LIST_TO_CATEGORIES or not next(FX_LIST_TO_CATEGORIES) then return end
    FX_Adder_EnsureCacheDir()
    local cache_path = GetCategoryCachePath()
    local file = io.open(cache_path, 'w')
    if not file then return end
    file:write('-- FX Category Cache (FX Devices)\nreturn {\n')
    local first = true
    for fx_name, cat_data in pairs(FX_LIST_TO_CATEGORIES) do
        if not first then file:write(',\n') end
        first = false
        local escaped_name = fx_name:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r')
        file:write(('  ["%s"] = {\n    categories = {'):format(escaped_name))
        local first_cat = true
        for _, cat in ipairs(cat_data.categories or {}) do
            if not first_cat then file:write(', ') end
            first_cat = false
            local escaped_cat = cat:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r')
            file:write(('"%s"'):format(escaped_cat))
        end
        file:write('},\n')
        local escaped_primary = (cat_data.primary or ''):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r')
        file:write(('    primary = "%s"\n  }'):format(escaped_primary))
    end
    file:write('\n}\n')
    file:close()
end

local function LoadCategoryCache()
    local cache_path = GetCategoryCachePath()
    local fh = io.open(cache_path, 'r')
    if not fh then return false end
    fh:close()
    local chunk, err = loadfile(cache_path)
    if not chunk then return false end
    local success, cache_data = pcall(chunk)
    if not success or type(cache_data) ~= 'table' or not next(cache_data) then return false end
    FX_LIST_TO_CATEGORIES = cache_data
    return true
end

SelectionCounts = SelectionCounts or {}

local function GetPluginCountsPath()
    return FX_Adder_CachePath() .. "plugin_select_counts.txt"
end

function SavePluginCounts()
    if not SelectionCounts or not next(SelectionCounts) then return end
    FX_Adder_EnsureCacheDir()
    local file = io.open(GetPluginCountsPath(), 'w')
    if not file then return end
    local sorted = {}
    for name, count in pairs(SelectionCounts) do
        table.insert(sorted, { name = name, count = count })
    end
    table.sort(sorted, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)
    for _, entry in ipairs(sorted) do
        file:write(entry.name .. "\t" .. tostring(entry.count) .. "\n")
    end
    file:close()
end

local function LoadPluginCounts()
    SelectionCounts = SelectionCounts or {}
    local file = io.open(GetPluginCountsPath(), 'r')
    if not file then return end
    for line in file:lines() do
        local name, count = line:match("^(.+)\t(%d+)$")
        if name and count then SelectionCounts[name] = tonumber(count) end
    end
    file:close()
end

function BuildFXListCategoryLookup()
    if not FX_LIST or #FX_LIST == 0 then return end
    FX_LIST_TO_CATEGORIES = {}
    local category_normalized = {}
    for cat_fx_name, cat_data in pairs(FX_CATEGORIES) do
        local norm = cat_data.normalized or NormalizeFXName(cat_fx_name)
        if not category_normalized[norm] then category_normalized[norm] = {} end
        table.insert(category_normalized[norm], cat_data)
        category_normalized[cat_fx_name:lower()] = category_normalized[cat_fx_name:lower()] or {}
        table.insert(category_normalized[cat_fx_name:lower()], cat_data)
    end
    for _, fx_list_name in ipairs(FX_LIST) do
        local normalized = NormalizeFXName(fx_list_name)
        local matched_cat = category_normalized[normalized]
        if not matched_cat then
            local name_without_prefix = fx_list_name:match('^[^:]+:(.+)$')
            if name_without_prefix then
                matched_cat = category_normalized[name_without_prefix:lower()]
                if not matched_cat then
                    local normalized_no_prefix = NormalizeFXName(name_without_prefix)
                    matched_cat = category_normalized[normalized_no_prefix]
                end
                if not matched_cat then
                    for cat_fx_name, cat_data in pairs(FX_CATEGORIES) do
                        local cat_normalized = cat_data.normalized or NormalizeFXName(cat_fx_name)
                        if normalized == cat_normalized
                            or (normalized ~= '' and cat_normalized ~= ''
                                and (normalized:find(cat_normalized, 1, true) or cat_normalized:find(normalized, 1, true))) then
                            matched_cat = { cat_data }
                            break
                        end
                    end
                end
                if not matched_cat then
                    local base_name = name_without_prefix:gsub('%.vst3$', ''):gsub('%.vst$', ''):gsub('%.dll$', '')
                        :gsub('%.jsfx$', ''):gsub('%.au$', ''):lower()
                    for cat_fx_name, cat_data in pairs(FX_CATEGORIES) do
                        local cat_base = cat_fx_name:gsub('%.vst3$', ''):gsub('%.vst$', ''):gsub('%.dll$', '')
                            :gsub('%.jsfx$', ''):gsub('%.au$', ''):lower()
                        if base_name == cat_base or base_name:find(cat_base, 1, true) or cat_base:find(base_name, 1, true) then
                            matched_cat = { cat_data }
                            break
                        end
                    end
                end
            else
                for cat_fx_name, cat_data in pairs(FX_CATEGORIES) do
                    local cat_normalized = cat_data.normalized or NormalizeFXName(cat_fx_name)
                    if normalized == cat_normalized then
                        matched_cat = { cat_data }
                        break
                    end
                end
            end
        end
        if matched_cat and matched_cat[1] then
            FX_LIST_TO_CATEGORIES[fx_list_name] = matched_cat[1]
        end
    end
    SaveCategoryCache()
end

function GetFXCategories(fx_name)
    if not fx_name or fx_name == '' then return nil end
    return FX_LIST_TO_CATEGORIES[fx_name]
end

local function StripParentheses(fx_name)
    if not fx_name then return '' end
    local result = fx_name:gsub('%s*%b()%s*', ' ')
    return result:gsub('%s+', ' '):match('^%s*(.-)%s*$') or ''
end

local function FilterWithCategories(filter_text, base_filtered_list)
    if not filter_text or filter_text == '' then
        return base_filtered_list
    end
    local filter_lower = filter_text:lower()
    local filter_normalized = NormalizeHyphensAndSpaces(filter_lower)
    local category_filter = nil
    if filter_lower:match('^category:') then
        category_filter = filter_lower:match('^category:(.+)$')
        if category_filter then category_filter = category_filter:match('^%s*(.-)%s*$') end
    elseif filter_lower:match('^cat:') then
        category_filter = filter_lower:match('^cat:(.+)$')
        if category_filter then category_filter = category_filter:match('^%s*(.-)%s*$') end
    end
    if category_filter and category_filter ~= '' then
        local filtered = {}
        for _, fx_name in ipairs(base_filtered_list) do
            local cat_data = FX_LIST_TO_CATEGORIES[fx_name]
            if cat_data then
                for _, cat in ipairs(cat_data.categories) do
                    if cat:lower():find(category_filter, 1, true) then
                        table.insert(filtered, fx_name)
                        break
                    end
                end
            end
        end
        return filtered
    end
    local is_category_match = false
    for cat_lower in pairs(FX_CATEGORY_SET) do
        if cat_lower:find(filter_lower, 1, true) then
            is_category_match = true
            break
        end
    end
    if is_category_match then
        local merged, seen = {}, {}
        for _, fx_name in ipairs(base_filtered_list) do
            if not seen[fx_name] then
                local fx_name_no_parens = StripParentheses(fx_name)
                local fx_normalized = NormalizeHyphensAndSpaces(fx_name_no_parens:lower())
                local all_words = true
                for word in filter_lower:gmatch("%S+") do
                    local w = NormalizeHyphensAndSpaces(word)
                    if w ~= '' and not fx_normalized:find(w, 1, true) then all_words = false break end
                end
                if all_words then
                    table.insert(merged, fx_name)
                    seen[fx_name] = true
                end
            end
        end
        for _, fx_name in ipairs(FX_LIST or {}) do
            if not seen[fx_name] then
                local cat_data = FX_LIST_TO_CATEGORIES[fx_name]
                if cat_data then
                    for _, cat in ipairs(cat_data.categories) do
                        if cat:lower():find(filter_lower, 1, true) then
                            table.insert(merged, fx_name)
                            seen[fx_name] = true
                            break
                        end
                    end
                end
            end
        end
        return merged
    end
    -- Match each search word against stripped/normalized name (same idea as Filter_actions),
    -- not the whole query as one substring — otherwise "fab filter" drops "FabFilter".
    local filtered = {}
    for _, fx_name in ipairs(base_filtered_list) do
        local fx_name_no_parens = StripParentheses(fx_name)
        local fx_normalized = NormalizeHyphensAndSpaces(fx_name_no_parens:lower())
        local all_words = true
        for word in filter_lower:gmatch("%S+") do
            local w = NormalizeHyphensAndSpaces(word)
            if w ~= '' and not fx_normalized:find(w, 1, true) then all_words = false break end
        end
        if all_words then table.insert(filtered, fx_name) end
    end
    return filtered
end

local function GetPluginTypePriority(plugin_type)
    if not plugin_type or not PluginTypeOrder then return 999 end
    local base_type = plugin_type
    if plugin_type == 'VST3i' then base_type = 'VST3'
    elseif plugin_type == 'VSTi' then base_type = 'VST'
    elseif plugin_type == 'AUi' then base_type = 'AU'
    elseif plugin_type == 'CLAPi' then base_type = 'CLAP'
    elseif plugin_type == 'LV2i' then base_type = 'LV2'
    elseif plugin_type == 'Container' then return 998
    end
    for i, type_name in ipairs(PluginTypeOrder) do
        if type_name == base_type then return i end
    end
    return 999
end

local function GetFavoritesFilePath()
    return FX_Adder_CachePath() .. 'fx_favorites.txt'
end

local function LoadFXFavorites()
    FX_Favorites = {}
    FX_Favorites_Order = {}
    local file_path = GetFavoritesFilePath()
    local file = io.open(file_path, 'r')
    if file then
        for line in file:lines() do
            line = line:match("^%s*(.-)%s*$")
            if line and line ~= '' then
                FX_Favorites[line] = true
                table.insert(FX_Favorites_Order, line)
            end
        end
        file:close()
    end
end

local function SaveFXFavorites()
    FX_Favorites_Order = FX_Favorites_Order or {}
    FX_Adder_EnsureCacheDir()
    local file = io.open(GetFavoritesFilePath(), 'w')
    if not file then return end
    for _, fx_name in ipairs(FX_Favorites_Order) do
        if FX_Favorites[fx_name] then file:write(fx_name .. '\n') end
    end
    for fx_name, is_favorite in pairs(FX_Favorites) do
        if is_favorite then
            local found = false
            for _, ordered_name in ipairs(FX_Favorites_Order) do
                if ordered_name == fx_name then found = true break end
            end
            if not found then
                file:write(fx_name .. '\n')
                table.insert(FX_Favorites_Order, fx_name)
            end
        end
    end
    file:close()
end

function FX_Adder_InitAfterFXListLoad()
    LoadFXCategories()
    if not LoadCategoryCache() then
        BuildFXListCategoryLookup()
    end
    LoadPluginCounts()
    LoadFXFavorites()
end

function FX_Adder_OnPluginListRescanned()
    BuildFXListCategoryLookup()
end

function Filter_actions(filter_text)
    filter_text = Lead_Trim_ws(filter_text or '')
    if filter_text == "" then
        local all = {}
        for i = 1, #(FX_LIST or {}) do all[i] = FX_LIST[i] end
        return all
    end
    local matches = {}
    for i = 1, #(FX_LIST or {}) do
        local action = FX_LIST[i]
        local name_norm = NormalizeHyphensAndSpaces(action:lower())
        local found = true
        for word in filter_text:gmatch("%S+") do
            local w = NormalizeHyphensAndSpaces(word:lower())
            if not name_norm:find(w, 1, true) then
                found = false
                break
            end
        end
        if found then
            local plugin_type = "Other"
            if action:find("VST3i:") then plugin_type = "VST3i"
            elseif action:find("VST3:") then plugin_type = "VST3"
            elseif action:find("VSTi:") then plugin_type = "VSTi"
            elseif action:find("VST:") then plugin_type = "VST"
            elseif action:find("CLAPi:") then plugin_type = "CLAPi"
            elseif action:find("CLAP:") then plugin_type = "CLAP"
            elseif action:find("AU:") then plugin_type = "AU"
            elseif action:find('AUi:') then plugin_type = "AUi"
            elseif action:find("JS:") then plugin_type = "JS"
            elseif action:find("LV2:") then plugin_type = "LV2"
            elseif action:find("LV2i:") then plugin_type = "LV2i"
            end
            table.insert(matches, { action = action, type = plugin_type })
        end
    end
    local type_priority = {}
    local type_map = {
        ["VST3i"] = "VST3", ["VST3"] = "VST3", ["VSTi"] = "VST", ["VST"] = "VST",
        ["CLAPi"] = "CLAP", ["CLAP"] = "CLAP", ["AU"] = "AU", ["AUi"] = "AU",
        ["JS"] = "JS", ["LV2"] = "LV2", ["LV2i"] = "LV2", ["Other"] = "Other"
    }
    local plugin_order = PluginTypeOrder or { "VST3", "VST", "AU", "CLAP", "JS" }
    for priority, plugin_type in ipairs(plugin_order) do
        type_priority[plugin_type] = priority
    end
    local max_priority = #plugin_order
    for type_name in pairs(type_map) do
        if not type_priority[type_name] then
            max_priority = max_priority + 1
            type_priority[type_name] = max_priority
        end
    end
    table.sort(matches, function(a, b)
        local ap = type_priority[type_map[a.type]] or 999
        local bp = type_priority[type_map[b.type]] or 999
        return ap < bp
    end)
    local t = {}
    for _, match in ipairs(matches) do
        table.insert(t, match.action)
    end
    return t
end

local function ParseFXForFilter(fx)
    local typ = 'Unknown'
    local name = fx
    local manufacturer = ''
    if fx:find('VST3i:') then typ = 'VST3i'; name = fx:sub(7)
    elseif fx:find('VSTi:') then typ = 'VSTi'; name = fx:sub(6)
    elseif fx:find('AUi:') then typ = 'AUi'; name = fx:sub(5)
    elseif fx:find('CLAPi:') then typ = 'CLAPi'; name = fx:sub(7)
    elseif fx:find('VST:') then typ = 'VST'; name = fx:sub(5)
    elseif fx:find('VST3:') then typ = 'VST3'; name = fx:sub(6)
    elseif fx:find('JS:') then typ = 'JS'; name = fx:sub(4)
    elseif fx:find('AU:') then typ = 'AU'; name = fx:sub(4)
    elseif fx:find('CLAP:') then typ = 'CLAP'; name = fx:sub(6)
    elseif fx:find('LV2:') then typ = 'LV2'; name = fx:sub(5)
    elseif fx:find('LV2i:') then typ = 'LV2i'; name = fx:sub(6)
    elseif fx == 'Container' then typ = 'Container'; name = 'Container'
    end
    if typ:find('VST') then
        local vst_ext = name:find('.vst')
        if vst_ext then name = name:sub(1, vst_ext - 1) end
    end
    local function isChannelInfo(text)
        return text:match("^%d+%s*%-?>?%s*%d*%s*[choutin]+") ~= nil
            or text:match("%d+%s*out") ~= nil or text:match("%d+%s*ch") ~= nil
            or text:match("%d+%s*in") ~= nil or text:match("%->") ~= nil
    end
    local paren_pairs = {}
    local pos = 1
    while true do
        local open_pos = name:find("%(", pos)
        if not open_pos then break end
        local close_pos = name:find("%)", open_pos + 1)
        if not close_pos then break end
        table.insert(paren_pairs, { start = open_pos, stop = close_pos, content = name:sub(open_pos + 1, close_pos - 1) })
        pos = close_pos + 1
    end
    if #paren_pairs > 0 then
        local last_paren = paren_pairs[#paren_pairs]
        local manufacturer_paren = last_paren
        if isChannelInfo(last_paren.content) and #paren_pairs > 1 then
            manufacturer_paren = paren_pairs[#paren_pairs - 1]
        end
        manufacturer = manufacturer_paren.content
        name = name:sub(1, manufacturer_paren.start - 1) .. name:sub(manufacturer_paren.stop + 1)
        if manufacturer_paren ~= last_paren then
            local offset = manufacturer_paren.stop - manufacturer_paren.start + 1
            local adjusted_start = last_paren.start - offset
            local adjusted_stop = last_paren.stop - offset
            name = name:sub(1, adjusted_start - 1) .. name:sub(adjusted_stop + 1)
        end
        name = name:match("^%s*(.-)%s*$") or name
    end
    return name, manufacturer, typ
end

local function TypeColor(typ)
    local cd = CustomColorsDefault or {}
    if typ == 'VST3i' then return FX_Adder_VST3 or cd.FX_Adder_VST3
    elseif typ == 'VSTi' then return FX_Adder_VST or cd.FX_Adder_VST
    elseif typ == 'AUi' then return FX_Adder_AU or cd.FX_Adder_AU
    elseif typ == 'CLAPi' then return FX_Adder_CLAP or cd.FX_Adder_CLAP
    elseif typ == 'VST' then return FX_Adder_VST or cd.FX_Adder_VST
    elseif typ == 'VST3' then return FX_Adder_VST3 or cd.FX_Adder_VST3
    elseif typ == 'JS' then return FX_Adder_JS or cd.FX_Adder_JS
    elseif typ == 'AU' then return FX_Adder_AU or cd.FX_Adder_AU
    elseif typ == 'CLAP' then return FX_Adder_CLAP or cd.FX_Adder_CLAP
    elseif typ == 'LV2' or typ == 'LV2i' then return FX_Adder_LV2 or cd.FX_Adder_LV2
    end
    return 0xffffffff
end

function FilterBox(FX_Idx, SpcType, FxGUID_Container, ParallelFX)
    local close
    if im.IsWindowAppearing(ctx) then
        ADDFX_FILTER = ''
        ADDFX_FILTER_POPUP_ID = (ADDFX_FILTER_POPUP_ID or 0) + 1
    end

    local function InsertFX(Name)
        r.TrackFX_AddByName(LT_Track, Name, false, -1000 - FX_Idx)
        local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
        if SpcType == 'SpcInBS' then
            DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx + 1, FX_Idx)
        end
        r.TrackFX_Show(LT_Track, FX_Idx, 2)
        local FXCount = r.TrackFX_GetCount(LT_Track)
        RetrieveFXsSavedLayout(FXCount)
        ADDFX_FILTER = ''
        LAST_USED_FX = Name
        SelectionCounts = SelectionCounts or {}
        SelectionCounts[Name] = (SelectionCounts[Name] or 0) + 1
        SavePluginCounts()
        TREE = BuildFXTree(LT_Track)
    end

    im.PushFont(ctx, Font_Andale_Mono_13)
    im.PushID(ctx, 'addfx_filter_' .. (ADDFX_FILTER_POPUP_ID or 0))
    im.SetNextItemWidth(ctx, 180)
    _, ADDFX_FILTER = im.InputTextWithHint(ctx, '##input', "SEARCH FX", ADDFX_FILTER or '', im.InputTextFlags_AutoSelectAll)
    im.PopID(ctx)
    if im.IsWindowAppearing(ctx) then
        im.SetKeyboardFocusHere(ctx, -1)
    end

    local filter_text = ADDFX_FILTER or ''
    local has_search_query = filter_text ~= '' and filter_text
    FX_Search_ActiveFilters = FX_Search_ActiveFilters or { category = nil, manufacturer = nil }
    local category_filter = FX_Search_ActiveFilters.category
    local manufacturer_filter = FX_Search_ActiveFilters.manufacturer
    local base_filter_text = filter_text
    if filter_text ~= '' then
        local filter_lower = filter_text:lower()
        if filter_lower:match('^category:') then
            category_filter = filter_lower:match('^category:(.+)$')
            if category_filter then
                category_filter = category_filter:match('^%s*(.-)%s*$')
                base_filter_text = ''
            end
        elseif filter_lower:match('^cat:') then
            category_filter = filter_lower:match('^cat:(.+)$')
            if category_filter then
                category_filter = category_filter:match('^%s*(.-)%s*$')
                base_filter_text = ''
            end
        end
    end

    local base_filtered_fx = Filter_actions(base_filter_text)
    local filtered_fx = FilterWithCategories(filter_text, base_filtered_fx)
    if category_filter or manufacturer_filter then
        local source_list = (filter_text == '' or filter_text == nil) and (FX_LIST or {}) or filtered_fx
        local filtered_by_active = {}
        for _, fx_name in ipairs(source_list) do
            local name, manufacturer, typ = ParseFXForFilter(fx_name)
            local fx_categories = GetFXCategories(fx_name)
            local category = (fx_categories and fx_categories.primary) or ""
            local matches = true
            if category_filter and category:lower():find(category_filter:lower(), 1, true) == nil then matches = false end
            if manufacturer_filter and manufacturer:lower():find(manufacturer_filter:lower(), 1, true) == nil then matches = false end
            if matches then table.insert(filtered_by_active, fx_name) end
        end
        filtered_fx = filtered_by_active
    end

    -- Favorites that are in the current result set (shown at top of search popup only, not in Add menu)
    local filtered_fx_set = {}
    for _, x in ipairs(filtered_fx) do filtered_fx_set[x] = true end
    local favorites_top = {}
    for _, fx_name in ipairs(FX_Favorites_Order or {}) do
        if FX_Favorites[fx_name] and filtered_fx_set[fx_name] then
            table.insert(favorites_top, fx_name)
        end
    end
    local fav_in_results = {}
    for _, fx in ipairs(favorites_top) do fav_in_results[fx] = true end
    local filtered_regular = {}
    for _, fx in ipairs(filtered_fx) do
        if not fav_in_results[fx] then table.insert(filtered_regular, fx) end
    end

    local has_active_filters = (FX_Search_ActiveFilters.category or FX_Search_ActiveFilters.manufacturer)
    if not has_search_query and not has_active_filters then
        im.PopFont(ctx)
        if im.IsKeyPressed(ctx, im.Key_Escape) then
            im.CloseCurrentPopup(ctx)
            ADDFX_FILTER = nil
        end
        return close
    end

    local filter_h = #filtered_fx == 0 and 2 or math.min(20 * 17, 17 * #filtered_fx)
    SL()
    FX_Search_WindowSize = FX_Search_WindowSize or { w = 528, h = 400 }
    local x, y = im.GetCursorScreenPos(ctx)
    if not FX_Search_WindowPos then
        FX_Search_WindowPos = { x = x, y = y - filter_h / 2 }
    end
    im.SetNextWindowPos(ctx, FX_Search_WindowPos.x, FX_Search_WindowPos.y)
    im.SetNextWindowSize(ctx, FX_Search_WindowSize.w, FX_Search_WindowSize.h)
    if im.SetNextWindowSizeConstraints then im.SetNextWindowSizeConstraints(ctx, 280, 200, 900, 700) end
    im.PushStyleVar(ctx, im.StyleVar_WindowPadding, 5, 10)

    if im.BeginPopup(ctx, "##popupp", im.WindowFlags_NoFocusOnAppearing) then
        local cw, ch = im.GetWindowSize(ctx)
        if cw and ch then FX_Search_WindowSize.w, FX_Search_WindowSize.h = cw, ch end

        if category_filter or manufacturer_filter then
            im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 4, 4)
            if category_filter then
                if im.SmallButton(ctx, 'Category: ' .. category_filter .. ' ##xcat') then
                    FX_Search_ActiveFilters.category = nil
                end
                im.SameLine(ctx)
            end
            if manufacturer_filter then
                if im.SmallButton(ctx, 'Manufacturer: ' .. manufacturer_filter .. ' ##xmfr') then
                    FX_Search_ActiveFilters.manufacturer = nil
                end
            end
            im.PopStyleVar(ctx)
            im.Spacing(ctx)
        end

        if #favorites_top > 0 then
            im.SeparatorText(ctx, 'Favorites')
        end

        local cache_key = filter_text .. '|' .. tostring(#filtered_regular) .. '|' .. tostring(#favorites_top) .. '|' .. tostring(category_filter) .. '|' .. tostring(manufacturer_filter)
        if not FX_Search_Cache or FX_Search_Cache.key ~= cache_key then
            FX_Search_Cache = { key = cache_key, rows = {} }
            for _, raw_fx in ipairs(filtered_regular) do
                local name, manufacturer, typ = ParseFXForFilter(raw_fx)
                local fx_categories = GetFXCategories(raw_fx)
                local category = (fx_categories and fx_categories.primary) or ""
                table.insert(FX_Search_Cache.rows, {
                    raw_fx = raw_fx, name = name, manufacturer = manufacturer, typ = typ,
                    category = category, color = TypeColor(typ)
                })
            end
            table.sort(FX_Search_Cache.rows, function(a, b)
                local fa = FX_Favorites[a.raw_fx] and 1 or 0
                local fb = FX_Favorites[b.raw_fx] and 1 or 0
                if fa ~= fb then return fa > fb end
                local pa, pb = GetPluginTypePriority(a.typ), GetPluginTypePriority(b.typ)
                if pa ~= pb then return pa < pb end
                return (a.name or ''):lower() < (b.name or ''):lower()
            end)
        end

        local match_row_start = 0
        local matching_categories, matching_manufacturers = {}, {}
        if filter_text ~= '' and #filter_text >= 2 then
            local filter_lower = filter_text:lower()
            local uc, um, cs, ms = {}, {}, {}, {}
            for _, row in ipairs(FX_Search_Cache.rows) do
                if row.category ~= '' and not cs[row.category] then
                    cs[row.category] = true
                    table.insert(uc, row.category)
                end
                if row.manufacturer ~= '' and not ms[row.manufacturer] then
                    ms[row.manufacturer] = true
                    table.insert(um, row.manufacturer)
                end
            end
            for _, cat in ipairs(uc) do
                if cat:lower():find(filter_lower, 1, true) then table.insert(matching_categories, cat) end
            end
            for _, mfr in ipairs(um) do
                if mfr:lower():find(filter_lower, 1, true) then table.insert(matching_manufacturers, mfr) end
            end
            match_row_start = #matching_categories + #matching_manufacturers
        end

        local fav_count = #favorites_top
        local prefix_rows = fav_count + match_row_start
        local nrows = prefix_rows + #FX_Search_Cache.rows
        ADDFX_Sel_Entry = SetMinMax(ADDFX_Sel_Entry or 1, 1, math.max(1, nrows))

        if im.BeginTable(ctx, '##fx_adder_tbl', 5, im.TableFlags_Resizable | im.TableFlags_ScrollY | im.TableFlags_BordersInnerV) then
            im.TableSetupColumn(ctx, ' ', im.TableColumnFlags_WidthFixed, 28)
            im.TableSetupColumn(ctx, 'Plugin', im.TableColumnFlags_WidthStretch)
            im.TableSetupColumn(ctx, 'Manufacturer', im.TableColumnFlags_WidthStretch)
            im.TableSetupColumn(ctx, 'Category', im.TableColumnFlags_WidthStretch)
            im.TableSetupColumn(ctx, 'Type', im.TableColumnFlags_WidthFixed, 56)
            if im.TableSetupScrollFreeze then im.TableSetupScrollFreeze(ctx, 0, 1) end
            im.TableHeadersRow(ctx)

            local row_i = 0
            for fi, raw_fx in ipairs(favorites_top) do
                row_i = row_i + 1
                local name, manufacturer, typ = ParseFXForFilter(raw_fx)
                local fx_categories = GetFXCategories(raw_fx)
                local category = (fx_categories and fx_categories.primary) or ""
                local row_color = TypeColor(typ)
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                if im.SmallButton(ctx, '★##favstar' .. fi) then
                    FX_Favorites[raw_fx] = false
                    for j = #FX_Favorites_Order, 1, -1 do
                        if FX_Favorites_Order[j] == raw_fx then table.remove(FX_Favorites_Order, j) end
                    end
                    SaveFXFavorites()
                    FX_Search_Cache = nil
                end
                im.TableNextColumn(ctx)
                local sel = row_i == ADDFX_Sel_Entry
                if im.Selectable(ctx, name .. '##favname' .. fi, sel) then
                    InsertFX(raw_fx)
                    im.CloseCurrentPopup(ctx)
                    close = true
                end
                if im.IsItemActive(ctx) and im.IsMouseDragging(ctx, 0) then
                    DndAddFX_SRC(raw_fx)
                end
                im.TableNextColumn(ctx)
                im.PushStyleColor(ctx, im.Col_Text, 0x88AAFFFF)
                im.PushID(ctx, 'favmfr' .. fi)
                if manufacturer ~= '' then
                    if im.Selectable(ctx, manufacturer .. '##favmfrcell' .. fi, false) then
                        FX_Search_ActiveFilters.manufacturer = manufacturer
                        FX_Search_Cache = nil
                    end
                end
                im.PopID(ctx)
                im.PopStyleColor(ctx)
                im.TableNextColumn(ctx)
                im.PushStyleColor(ctx, im.Col_Text, 0x88AAFFFF)
                im.PushID(ctx, 'favcat' .. fi)
                if category ~= '' then
                    if im.Selectable(ctx, category .. '##favcatcell' .. fi, false) then
                        FX_Search_ActiveFilters.category = category
                        FX_Search_Cache = nil
                    end
                end
                im.PopID(ctx)
                im.PopStyleColor(ctx)
                im.TableNextColumn(ctx)
                im.PushStyleColor(ctx, im.Col_Text, row_color)
                im.Text(ctx, typ)
                im.PopStyleColor(ctx)
            end
            for _, cat in ipairs(matching_categories) do
                row_i = row_i + 1
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.TableNextColumn(ctx)
                local sel = row_i == ADDFX_Sel_Entry
                if im.Selectable(ctx, '📁 Category: ' .. cat .. '##mc' .. row_i, sel) then
                    FX_Search_ActiveFilters.category = cat
                    ADDFX_FILTER = ''
                    FX_Search_Cache = nil
                end
                im.TableNextColumn(ctx); im.TableNextColumn(ctx); im.TableNextColumn(ctx)
            end
            for _, mfr in ipairs(matching_manufacturers) do
                row_i = row_i + 1
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                im.TableNextColumn(ctx)
                local sel = row_i == ADDFX_Sel_Entry
                if im.Selectable(ctx, '🏭 Manufacturer: ' .. mfr .. '##mm' .. row_i, sel) then
                    FX_Search_ActiveFilters.manufacturer = mfr
                    ADDFX_FILTER = ''
                    FX_Search_Cache = nil
                end
                im.TableNextColumn(ctx); im.TableNextColumn(ctx); im.TableNextColumn(ctx)
            end

            for i, row in ipairs(FX_Search_Cache.rows) do
                row_i = row_i + 1
                im.TableNextRow(ctx)
                im.TableNextColumn(ctx)
                local is_fav = FX_Favorites[row.raw_fx] == true
                if im.SmallButton(ctx, (is_fav and '★' or '☆') .. '##f' .. i) then
                    FX_Favorites[row.raw_fx] = not is_fav
                    if FX_Favorites[row.raw_fx] then
                        local found = false
                        for _, o in ipairs(FX_Favorites_Order) do if o == row.raw_fx then found = true break end end
                        if not found then table.insert(FX_Favorites_Order, row.raw_fx) end
                    else
                        for j = #FX_Favorites_Order, 1, -1 do
                            if FX_Favorites_Order[j] == row.raw_fx then table.remove(FX_Favorites_Order, j) end
                        end
                    end
                    SaveFXFavorites()
                    FX_Search_Cache = nil
                end
                im.TableNextColumn(ctx)
                local sel = row_i == ADDFX_Sel_Entry
                if im.Selectable(ctx, row.name .. '##' .. i, sel) then
                    InsertFX(row.raw_fx)
                    im.CloseCurrentPopup(ctx)
                    close = true
                end
                if im.IsItemActive(ctx) and im.IsMouseDragging(ctx, 0) then
                    DndAddFX_SRC(row.raw_fx)
                end
                im.TableNextColumn(ctx)
                im.PushStyleColor(ctx, im.Col_Text, 0x88AAFFFF)
                im.PushID(ctx, 'mfrc' .. i)
                if row.manufacturer ~= '' then
                    if im.Selectable(ctx, row.manufacturer .. '##mfrcell' .. i, false) then
                        FX_Search_ActiveFilters.manufacturer = row.manufacturer
                        FX_Search_Cache = nil
                    end
                end
                im.PopID(ctx)
                im.PopStyleColor(ctx)
                im.TableNextColumn(ctx)
                im.PushStyleColor(ctx, im.Col_Text, 0x88AAFFFF)
                im.PushID(ctx, 'catc' .. i)
                if row.category ~= '' then
                    if im.Selectable(ctx, row.category .. '##catcell' .. i, false) then
                        FX_Search_ActiveFilters.category = row.category
                        FX_Search_Cache = nil
                    end
                end
                im.PopID(ctx)
                im.PopStyleColor(ctx)
                im.TableNextColumn(ctx)
                im.PushStyleColor(ctx, im.Col_Text, row.color)
                im.Text(ctx, row.typ)
                im.PopStyleColor(ctx)
            end
            im.EndTable(ctx)
        end

        if im.IsKeyPressed(ctx, im.Key_Enter) and ADDFX_Sel_Entry then
            local e = ADDFX_Sel_Entry
            if e <= fav_count then
                local raw_fx = favorites_top[e]
                if raw_fx then
                    InsertFX(raw_fx)
                    im.CloseCurrentPopup(ctx)
                    close = true
                end
            elseif match_row_start > 0 and e <= prefix_rows then
                local e2 = e - fav_count
                if e2 <= #matching_categories then
                    FX_Search_ActiveFilters.category = matching_categories[e2]
                    ADDFX_FILTER = ''
                else
                    local mi = e2 - #matching_categories
                    FX_Search_ActiveFilters.manufacturer = matching_manufacturers[mi]
                    ADDFX_FILTER = ''
                end
                FX_Search_Cache = nil
                ADDFX_Sel_Entry = 1
            else
                local fi = e - prefix_rows
                local row = FX_Search_Cache.rows[fi]
                if row then
                    InsertFX(row.raw_fx)
                    im.CloseCurrentPopup(ctx)
                    close = true
                end
            end
        elseif im.IsKeyPressed(ctx, im.Key_UpArrow) then
            ADDFX_Sel_Entry = SetMinMax((ADDFX_Sel_Entry or 1) - 1, 1, math.max(1, nrows))
        elseif im.IsKeyPressed(ctx, im.Key_DownArrow) then
            ADDFX_Sel_Entry = SetMinMax((ADDFX_Sel_Entry or 1) + 1, 1, math.max(1, nrows))
        end

        im.EndPopup(ctx)
    end
    im.PopStyleVar(ctx)
    im.OpenPopup(ctx, "##popupp")
    im.NewLine(ctx)

    if im.IsKeyPressed(ctx, im.Key_Escape) then
        im.CloseCurrentPopup(ctx)
        ADDFX_FILTER = nil
        FX_Search_Cache = nil
        FX_Search_ActiveFilters = { category = nil, manufacturer = nil }
        FX_Search_WindowPos = nil
    end
    im.PopFont(ctx)
    return close
end
