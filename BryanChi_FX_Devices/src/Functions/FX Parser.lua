-- @description FX Parser Module
-- @author Optimized Version
-- @license GPL v3
-- @version 2.0
-- @changelog
--  Refactored for better maintainability

local reaper_api = r or reaper
local system_os = reaper_api.GetOS()
local path_sep = package.config:sub(1, 1)
local current_script_dir = debug.getinfo(1, "S").source:match [[^@?(.*[\\/])[^\\/]-$]]

local PLUGIN_DATA_FILE = current_script_dir .. "FX_LIST.txt"
local CATEGORY_DATA_FILE = current_script_dir .. "FX_CAT_FILE.txt"
local DEV_DATA_FILE = current_script_dir .. "FX_DEV_LIST_FILE.txt"

local CATEGORIES = {}
local DEV_NAMES = { " (Waves)" }
local ALL_PLUGINS = {}
local INST_PLUGINS = {}
local VST_DATA, VST_PLUGINS, VST_INST, VST3_PLUGINS, VST3_INST = {}, {}, {}, {}, {}
local JS_DATA, JS_PLUGINS = {}, {}
local AU_DATA, AU_PLUGINS, AU_INST = {}, {}, {}
local CLAP_DATA, CLAP_PLUGINS, CLAP_INST = {}, {}, {}
local LV2_DATA, LV2_PLUGINS, LV2_INST = {}, {}, {}

local function ClearAllTables()
    CATEGORIES = {}
    DEV_NAMES = { " (Waves)" }
    ALL_PLUGINS = {}
    INST_PLUGINS = {}
    VST_DATA, VST_PLUGINS, VST_INST, VST3_PLUGINS, VST3_INST = {}, {}, {}, {}, {}
    JS_DATA, JS_PLUGINS = {}, {}
    AU_DATA, AU_PLUGINS, AU_INST = {}, {}, {}
    CLAP_DATA, CLAP_PLUGINS, CLAP_INST = {}, {}, {}
    LV2_DATA, LV2_PLUGINS, LV2_INST = {}, {}, {}
end

function CreatePluginFiles()
    LoadPluginDatabase()
    local plugin_data_serialized = ConvertTableToString(ALL_PLUGINS)
    SaveToFile(PLUGIN_DATA_FILE, plugin_data_serialized)

    local category_data_serialized = ConvertTableToString(CATEGORIES)
    SaveToFile(CATEGORY_DATA_FILE, category_data_serialized)

    local dev_data_serialized = ConvertTableToString(DEV_NAMES)
    SaveToFile(DEV_DATA_FILE, dev_data_serialized)

    return ALL_PLUGINS, CATEGORIES, DEV_NAMES
end

function LoadPluginFiles()
    local plugin_file = io.open(PLUGIN_DATA_FILE, "r")
    if plugin_file then
        ALL_PLUGINS = {}
        local plugin_content = plugin_file:read("*all")
        plugin_file:close()
        ALL_PLUGINS = ConvertStringToTable(plugin_content)
    end

    local category_file = io.open(CATEGORY_DATA_FILE, "r")
    if category_file then
        CATEGORIES = {}
        local category_content = category_file:read("*all")
        category_file:close()
        CATEGORIES = ConvertStringToTable(category_content)
    end

    local dev_file = io.open(DEV_DATA_FILE, "r")
    if dev_file then
        DEV_NAMES = {}
        local dev_content = dev_file:read("*all")
        dev_file:close()
        DEV_NAMES = ConvertStringToTable(dev_content)
    end

    return ALL_PLUGINS, CATEGORIES, DEV_NAMES
end

function SaveToFile(file_path, content)
    local file_handle = io.open(file_path, "w")
    if file_handle then
        file_handle:write(content)
        file_handle:close()
    end
end

function SerializeValue(input_val, key_name, compact_mode, indent_level)
    compact_mode = compact_mode or false
    indent_level = indent_level or 0
    local indent_str = string.rep(" ", indent_level)

    if key_name then
        if type(key_name) == "number" and math.floor(key_name) == key_name then
            key_name = "[" .. key_name .. "]"
        elseif not string.match(key_name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
            key_name = string.gsub(key_name, "'", "\\'")
            key_name = "['" .. key_name .. "']"
        end
        indent_str = indent_str .. key_name .. " = "
    end

    local val_type = type(input_val)
    if val_type == "table" then
        indent_str = indent_str .. "{" .. (not compact_mode and "\n" or "")
        for k, v in pairs(input_val) do
            indent_str = indent_str .. SerializeValue(v, k, compact_mode, indent_level + 1) .. "," .. (not compact_mode and "\n" or "")
        end
        indent_str = indent_str .. string.rep(" ", indent_level) .. "}"
    elseif val_type == "number" then
        indent_str = indent_str .. tostring(input_val)
    elseif val_type == "string" then
        indent_str = indent_str .. string.format("%q", input_val)
    elseif val_type == "boolean" then
        indent_str = indent_str .. (input_val and "true" or "false")
    else
        -- POINTERS GET RECALCULATED ON RUN SO WE NIL HERE (MEDIATRACKS, MEDIAITEMS...)
        indent_str = indent_str .. "nil"
    end
    return indent_str
end

function ConvertStringToTable(input_str)
    local compiled_func, error_msg = load("return " .. input_str)
    return compiled_func and compiled_func() or nil
end

function ConvertTableToString(input_table) return SerializeValue(input_table) end

function EscapePatternChars(input_str)
    return input_str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(char) return "%" .. char end)
end

function ReadFileContents(file_path)
    local content = "\n"
    if not file_path then return content end
    local file_handle = io.open(file_path, 'r')
    if file_handle then
        content = file_handle:read('a')
        file_handle:close()
    end
    return content
end

local function ScanDirectoryRecursive(directory, results_table, file_extension)
    for dir_index = 0, math.huge do
        local subdir_path = reaper_api.EnumerateSubdirectories(directory, dir_index)
        if not subdir_path then break end
        results_table[#results_table + 1] = { dir = subdir_path, {} }
        ScanDirectoryRecursive(directory .. path_sep .. subdir_path, results_table[#results_table], file_extension)
    end

    for file_index = 0, math.huge do
        local file_name = reaper_api.EnumerateFiles(directory, file_index)
        if not file_name then break end
        if file_name:find(file_extension, nil, true) then
            results_table[#results_table + 1] = file_name:gsub(file_extension, "")
        end
    end
end

local function LocateCategory(category_name)
    for i = 1, #CATEGORIES do
        if CATEGORIES[i].name == category_name then return CATEGORIES[i].list end
    end
end

local function FindPluginByID(plugin_table, plugin_id, is_js_plugin)
    for i = 1, #plugin_table do
        local plugin_entry = plugin_table[i]
        if is_js_plugin then
            -- JS plugins can have only part of identifier in the string
            if plugin_entry.id:find(plugin_id) then return plugin_entry.name end
        elseif plugin_entry.id == plugin_id then
            return plugin_entry.name
        end
    end
end

function FindInTable(search_table, search_value)
    for i = 1, #search_table do
        if search_table[i].name == search_value then return search_table[i].fx end
    end
end

function AddDeveloperName(developer_name)
    local formatted_name = " (" .. developer_name .. ")"
    for i = 1, #DEV_NAMES do
        if DEV_NAMES[i] == formatted_name then return end
    end
    DEV_NAMES[#DEV_NAMES + 1] = formatted_name
end

local function ProcessVSTPlugin(plugin_name, plugin_ident)
    if not plugin_name:match("^VST") then return end

    local is_instrument_type = false
    if plugin_name:match("VST: ") then
        VST_PLUGINS[#VST_PLUGINS + 1] = plugin_name
    elseif plugin_name:match("VSTi: ") then
        VST_INST[#VST_INST + 1] = plugin_name
        is_instrument_type = true
    elseif plugin_name:match("VST3: ") then
        VST3_PLUGINS[#VST3_PLUGINS + 1] = plugin_name
    elseif plugin_name:match("VST3i: ") then
        VST3_INST[#VST3_INST + 1] = plugin_name
        is_instrument_type = true
    end

    if is_instrument_type then
        INST_PLUGINS[#INST_PLUGINS + 1] = plugin_name
    end

    -- Extract only DLL without path - reverse for easier match to first "/" after DLL
    plugin_ident = system_os:match("Win") and plugin_ident:reverse():match("(.-)\\") or plugin_ident:reverse():match("(.-)/")
    -- Replace whitespaces and dash with underscore (as in VST INI file)
    plugin_ident = plugin_ident:reverse():gsub(" ", "_"):gsub("-", "_")
    VST_DATA[#VST_DATA + 1] = { id = plugin_ident, name = plugin_name }
    ALL_PLUGINS[#ALL_PLUGINS + 1] = plugin_name
end

local function ProcessJSPlugin(plugin_name, plugin_ident)
    if not plugin_name:match("^JS:") then return end
    JS_PLUGINS[#JS_PLUGINS + 1] = plugin_name
    JS_DATA[#JS_DATA + 1] = { id = plugin_ident, name = plugin_name }
    ALL_PLUGINS[#ALL_PLUGINS + 1] = plugin_name
end

local function ProcessAUPlugin(plugin_name, plugin_ident)
    if not plugin_name:match("^AU") then return end

    local is_instrument_type = plugin_name:match("AUi: ")
    if is_instrument_type then
        AU_INST[#AU_INST + 1] = plugin_name
        INST_PLUGINS[#INST_PLUGINS + 1] = plugin_name
    else
        AU_PLUGINS[#AU_PLUGINS + 1] = plugin_name
    end
    AU_DATA[#AU_DATA + 1] = { id = plugin_ident, name = plugin_name }
    ALL_PLUGINS[#ALL_PLUGINS + 1] = plugin_name
end

local function ProcessCLAPPlugin(plugin_name, plugin_ident)
    if not plugin_name:match("^CLAP") then return end

    local is_instrument_type = plugin_name:match("CLAPi: ")
    if is_instrument_type then
        CLAP_INST[#CLAP_INST + 1] = plugin_name
        INST_PLUGINS[#INST_PLUGINS + 1] = plugin_name
    else
        CLAP_PLUGINS[#CLAP_PLUGINS + 1] = plugin_name
    end
    CLAP_DATA[#CLAP_DATA + 1] = { id = plugin_ident, name = plugin_name }
    ALL_PLUGINS[#ALL_PLUGINS + 1] = plugin_name
end

local function ProcessLV2Plugin(plugin_name, plugin_ident)
    if not plugin_name:match("^LV2") then return end

    local is_instrument_type = plugin_name:match("LV2i: ")
    if is_instrument_type then
        LV2_INST[#LV2_INST + 1] = plugin_name
        INST_PLUGINS[#INST_PLUGINS + 1] = plugin_name
    else
        LV2_PLUGINS[#LV2_PLUGINS + 1] = plugin_name
    end
    LV2_DATA[#LV2_DATA + 1] = { id = plugin_ident, name = plugin_name }
    ALL_PLUGINS[#ALL_PLUGINS + 1] = plugin_name
end

local function PluginExistsInList(plugin_list, plugin_name)
    for i = 1, #plugin_list do
        if plugin_list[i] == plugin_name then return true end
    end
    return false
end

local function ProcessFXTags()
    local tags_file_path = reaper_api.GetResourcePath() .. path_sep .. "reaper-fxtags.ini"
    local tags_content = ReadFileContents(tags_file_path)
    local is_developer_section = true

    for line_content in tags_content:gmatch('[^\r\n]+') do
        local category_name = line_content:match("^%[(.+)%]")
        if category_name then
            if category_name == "category" then
                is_developer_section = false
            end
            CATEGORIES[#CATEGORIES + 1] = { name = category_name:upper(), list = {} }
        else
            -- PLUGIN FOUND
            local plugin_id, category_info = line_content:match("(.+)=(.+)")
            if category_info then
                category_info = category_info:gsub("[%[%]]", "")
                if is_developer_section then AddDeveloperName(category_info) end

                local plugin_name = FindPluginByID(VST_DATA, plugin_id) or
                                   FindPluginByID(AU_DATA, plugin_id) or
                                   FindPluginByID(CLAP_DATA, plugin_id) or
                                   FindPluginByID(JS_DATA, plugin_id, "JS") or
                                   FindPluginByID(LV2_DATA, plugin_id)

                if plugin_name then
                    -- Split multiple categories at |
                    for category_type in category_info:gmatch('[^%|]+') do
                        local category_table = FindInTable(CATEGORIES[#CATEGORIES].list, category_type)
                        if not category_table then
                            table.insert(CATEGORIES[#CATEGORIES].list, { name = category_type, fx = { plugin_name } })
                        elseif not PluginExistsInList(category_table, plugin_name) then
                            table.insert(category_table, plugin_name)
                        end
                    end
                end
            end
        end
    end
end

local function ProcessCustomCategories()
    local favorites_file_path = reaper_api.GetResourcePath() .. path_sep .. "reaper-fxfolders.ini"
    local favorites_content = ReadFileContents(favorites_file_path)
    local current_category_table

    for line_content in favorites_content:gmatch('[^\r\n]+') do
        local category_name = line_content:match("%[(.-)%]")
        if category_name then
            current_category_table = (category_name == "category" or category_name == "developer") and
                                    LocateCategory(category_name:upper()) or nil
        elseif current_category_table then
            local plugin_id, category_list = line_content:match("(.+)=(.+)")
            if category_list then
                local plugin_name = FindPluginByID(VST_DATA, plugin_id) or
                                   FindPluginByID(AU_DATA, plugin_id) or
                                   FindPluginByID(CLAP_DATA, plugin_id) or
                                   FindPluginByID(JS_DATA, plugin_id, "JS") or
                                   FindPluginByID(LV2_DATA, plugin_id)

                if plugin_name then
                    for category_type in category_list:gmatch('([^+-%|]+)') do
                        local category_table = FindInTable(current_category_table, category_type)
                        if not category_table then
                            table.insert(current_category_table, { name = category_type, fx = { plugin_name } })
                        elseif not PluginExistsInList(category_table, plugin_name) then
                            table.insert(category_table, plugin_name)
                        end
                    end
                end
            end
        end
    end
end

local function OrganizeFoldersINI(favorites_content)
    local folder_collection = {}
    local should_add_content

    for line_content in favorites_content:gmatch('[^\r\n]+') do
        local section_name = line_content:match("^%[(.-)%]")
        if section_name then
            if section_name:find("Folder", nil, true) then
                should_add_content = true
                folder_collection[#folder_collection + 1] = { name = section_name }
            else
                should_add_content = false
            end
        elseif folder_collection[#folder_collection] and should_add_content then
            folder_collection[#folder_collection][#folder_collection[#folder_collection] + 1] = line_content .. "\n"
        end
    end

    local main_folders_section
    for i = #folder_collection, 1, -1 do
        table.sort(folder_collection[i])
        table.insert(folder_collection[i], 1, "[" .. folder_collection[i].name .. "]" .. "\n")
        if folder_collection[i].name == "Folders" then
            main_folders_section = table.remove(folder_collection, i)
        end
    end
    if main_folders_section then
        folder_collection[#folder_collection + 1] = main_folders_section
    end

    local organized_content_parts = {}
    for i = 1, #folder_collection do
        folder_collection[i].name = nil
        organized_content_parts[i] = table.concat(folder_collection[i])
    end

    return table.concat(organized_content_parts)
end

local search_operators = {
    ["not"] = { ' and ', ' not %s:find("%s") ' },
    ["or"] = { ' or ', ' %s:find("%s") ' },
    ["and"] = { ' and ', '%s:find("%s") ' },
}

local function ProcessSmartFolder(search_query)
    local search_patterns = {}
    local matching_plugins = {}

    -- Tag quoted words for later pattern matching
    for quoted_text in search_query:gmatch '"(.-)"' do
        search_query = search_query:gsub(quoted_text, '_schwa_magic_' .. quoted_text:gsub(' ', '|||'))
    end

    search_query = search_query:gsub('"', '')

    -- Separate filter by whitespace
    for pattern_term in search_query:gmatch("([^%s]+)") do
        pattern_term = pattern_term:lower():gsub('[%(%)%.%+%-%*%?%[%]%^%$%%]', '%%%1')
        if pattern_term:find('_schwa_magic_') then
            pattern_term = pattern_term:gsub('_schwa_magic_', '')
            if pattern_term:find('|||') then
                -- exact match multiple words as single pattern
                pattern_term = '(' .. pattern_term:gsub('|||', ' ') .. ')'
            else
                -- exact match single word
                pattern_term = '%A' .. pattern_term .. '%A'
            end
        end
        search_patterns[#search_patterns + 1] = pattern_term
    end

    local code_segments = {
        "for i = 1, #ALL_PLUGINS do\nlocal search_target = ALL_PLUGINS[i]:lower()",
        ""
    }

    local operator_handler
    for i = 1, #search_patterns do
        local current_pattern = search_patterns[i]
        if search_operators[current_pattern] then
            operator_handler = i > 1 and (search_operators[current_pattern][1] .. search_operators[current_pattern][2]) or search_operators[current_pattern][2]
        else
            if operator_handler then
                code_segments[2] = code_segments[2] .. operator_handler:format("search_target", current_pattern)
                operator_handler = nil
            else
                local search_condition = (' %s:find("%s")'):format("search_target", current_pattern)
                code_segments[2] = i > 1 and code_segments[2] .. " and " .. search_condition or code_segments[2] .. search_condition
            end
        end
    end

    code_segments[2] = 'if ' .. code_segments[2] .. ' then'
    code_segments[3] = 'matching_plugins[#matching_plugins+1] = ALL_PLUGINS[i]\nend\nend\n'

    local generated_code = table.concat(code_segments, "\n")

    local execution_environment = {
        matching_plugins = matching_plugins,
        ALL_PLUGINS = ALL_PLUGINS,
        string = string,
    }

    local compiled_function, error_message = load(generated_code, "ScriptRun", "t", execution_environment)

    if compiled_function then
        local success, runtime_error = pcall(compiled_function)
    end
    return matching_plugins
end

local function ProcessFavorites()
    local favorites_path = reaper_api.GetResourcePath() .. path_sep .. "reaper-fxfolders.ini"
    local favorites_data = ReadFileContents(favorites_path)
    favorites_data = OrganizeFoldersINI(favorites_data)
    CATEGORIES[#CATEGORIES + 1] = { name = "FOLDERS", list = {} }
    local item_registry = {}
    local active_folder

    for line_data in favorites_data:gmatch('[^\r\n]+') do
        local folder_name = line_data:match("^%[(Folder%d+)%]")
        if folder_name then
            active_folder = folder_name
        elseif line_data:match("Item%d+") then
            local item_index, item_value = line_data:match("Item(%d+)=(.+)")
            local item_entry = "R_ITEM_" .. item_value
            item_registry[item_index] = item_value

            local category_table = FindInTable(CATEGORIES[#CATEGORIES].list, active_folder)
            if not category_table then
                table.insert(CATEGORIES[#CATEGORIES].list, {
                    name = active_folder,
                    fx = { item_entry },
                    order = active_folder:match("Folder(%d+)")
                })
            else
                table.insert(category_table, item_entry)
            end
        elseif line_data:match("Type%d+") then
            local item_index, plugin_type = line_data:match("(%d+)=(%d+)")
            local folder_item = item_registry[item_index]
            if folder_item then
                local item_name = folder_item:gsub("R_ITEM_", "", 1)
                local resolved_plugin

                if plugin_type == "3" then -- VST
                    local plugin_id = system_os:match("Win") and item_name:reverse():match("(.-)\\") or item_name:reverse():match("(.-)/")
                    if plugin_id then
                        plugin_id = plugin_id:reverse():gsub(" ", "_"):gsub("-", "_")
                        resolved_plugin = FindPluginByID(VST_DATA, plugin_id)
                    end
                elseif plugin_type == "2" then -- JSFX
                    resolved_plugin = FindPluginByID(JS_DATA, item_name)
                elseif plugin_type == "7" then -- CLAP
                    resolved_plugin = FindPluginByID(CLAP_DATA, item_name)
                elseif plugin_type == "1" then -- LV2
                    resolved_plugin = FindPluginByID(LV2_DATA, item_name)
                elseif plugin_type == "5" then -- AU
                    resolved_plugin = FindPluginByID(AU_DATA, item_name)
                elseif plugin_type == "1048576" then -- SMART FOLDER
                    CATEGORIES[#CATEGORIES].list[#CATEGORIES[#CATEGORIES].list].smart = true
                    CATEGORIES[#CATEGORIES].list[#CATEGORIES[#CATEGORIES].list].fx = ProcessSmartFolder(item_name)
                elseif plugin_type == "1000" then -- FX CHAIN
                    table.insert(CATEGORIES[#CATEGORIES].list[#CATEGORIES[#CATEGORIES].list].fx, item_name .. ".RfxChain")
                end

                if resolved_plugin then
                    table.insert(CATEGORIES[#CATEGORIES].list[#CATEGORIES[#CATEGORIES].list].fx, resolved_plugin)
                end
            end
        elseif line_data:match("Name%d+=(.+)") then
            local folder_display_name = line_data:match("Name%d+=(.+)")
            local folder_id = line_data:match("(%d+)=")

            for i = 1, #CATEGORIES[#CATEGORIES].list do
                if CATEGORIES[#CATEGORIES].list[i].name == "Folder" .. folder_id then
                    CATEGORIES[#CATEGORIES].list[i].name = folder_display_name
                    break
                end
            end
        end
    end

    table.sort(CATEGORIES[#CATEGORIES].list, function(a, b) return tonumber(a.order) < tonumber(b.order) end)

    -- Remove R_ITEM_ entries
    for i = 1, #CATEGORIES do
        for j = #CATEGORIES[i].list, 1, -1 do
            local plugin_list = CATEGORIES[i].list[j] and CATEGORIES[i].list[j].fx
            if plugin_list then
                for f = #plugin_list, 1, -1 do
                    if plugin_list[f]:find("R_ITEM_") then
                        table.remove(plugin_list, f)
                    end
                end
            end
        end
    end
end

local function LoadFXChains()
    local fx_chains_collection = {}
    ScanDirectoryRecursive(reaper_api.GetResourcePath() .. path_sep .. "FXChains", fx_chains_collection, ".RfxChain")
    return fx_chains_collection
end

local function LoadTrackTemplates()
    local track_templates_collection = {}
    ScanDirectoryRecursive(reaper_api.GetResourcePath() .. path_sep .. "TrackTemplates", track_templates_collection, ".RTrackTemplate")
    return track_templates_collection
end

local function CreateAllPluginsCategory()
    local complete_plugins_category = { name = "ALL PLUGINS", list = {} }
    local plugin_type_definitions = {
        { name = "JS", fx = JS_PLUGINS },
        { name = "AU", fx = AU_PLUGINS },
        { name = "AUi", fx = AU_INST },
        { name = "CLAP", fx = CLAP_PLUGINS },
        { name = "CLAPi", fx = CLAP_INST },
        { name = "VST", fx = VST_PLUGINS },
        { name = "VSTi", fx = VST_INST },
        { name = "VST3", fx = VST3_PLUGINS },
        { name = "VST3i", fx = VST3_INST },
        { name = "LV2", fx = LV2_PLUGINS },
        { name = "LV2i", fx = LV2_INST },
        { name = "INSTRUMENTS", fx = INST_PLUGINS }
    }

    for _, plugin_type in ipairs(plugin_type_definitions) do
        if #plugin_type.fx > 0 then
            table.insert(complete_plugins_category.list, plugin_type)
        end
    end

    CATEGORIES[#CATEGORIES + 1] = complete_plugins_category

    -- Sort everything alphabetically
    local excluded_from_sorting = { FOLDERS = true, ["FX CHAINS"] = true, ["TRACK TEMPLATES"] = true }
    for i = 1, #CATEGORIES do
        if not excluded_from_sorting[CATEGORIES[i].name] then
            table.sort(CATEGORIES[i].list, function(a, b)
                return a.name and b.name and a.name:lower() < b.name:lower()
            end)
        end
        for j = 1, #CATEGORIES[i].list do
            local plugin_list = CATEGORIES[i].list[j].fx
            if plugin_list then
                table.sort(plugin_list, function(a, b) return a and b and a:lower() < b:lower() end)
            end
        end
    end

    table.sort(CATEGORIES, function(a, b)
        return a.name and b.name and a.name:lower() < b.name:lower()
    end)
end

function BuildPluginList()
    ALL_PLUGINS[#ALL_PLUGINS + 1] = "Container"
    ALL_PLUGINS[#ALL_PLUGINS + 1] = "Video processor"

    local plugin_processors = { ProcessVSTPlugin, ProcessJSPlugin, ProcessAUPlugin, ProcessCLAPPlugin, ProcessLV2Plugin }
    for i = 0, math.huge do
        local success, plugin_name, plugin_id = reaper_api.EnumInstalledFX(i)
        if not success then break end
        for _, processor in ipairs(plugin_processors) do
            processor(plugin_name, plugin_id)
        end
    end

    ProcessFXTags()
    ProcessCustomCategories()
    ProcessFavorites()

    local fx_chains_data = LoadFXChains()
    if #fx_chains_data > 0 then
        CATEGORIES[#CATEGORIES + 1] = { name = "FX CHAINS", list = fx_chains_data }
    end

    local track_templates_data = LoadTrackTemplates()
    if #track_templates_data > 0 then
        CATEGORIES[#CATEGORIES + 1] = { name = "TRACK TEMPLATES", list = track_templates_data }
    end

    CreateAllPluginsCategory()
    return ALL_PLUGINS
end

function CleanPluginName(plugin_name, remove_prefix, remove_suffix)
    if not DEV_NAMES then return plugin_name end

    if remove_suffix then
        for i = 1, #DEV_NAMES do
            local start_pos = plugin_name:find(DEV_NAMES[i], nil, true)
            if start_pos then
                plugin_name = plugin_name:sub(1, start_pos - 1)
                break
            end
        end
    end

    if remove_prefix then
        local prefix_start, prefix_end = plugin_name:find("(%S+: )")
        if prefix_start then
            plugin_name = plugin_name:sub(prefix_end + 1)
        end
    end

    return plugin_name
end

function LoadPluginDatabase()
    ClearAllTables()
    return BuildPluginList(), CATEGORIES, DEV_NAMES
end

function RefreshChainsAndTemplates(category_table)
    if not category_table then return end

    local fx_chains_data = LoadFXChains()
    local track_templates_data = LoadTrackTemplates()
    local chains_found, templates_found

    for i = 1, #category_table do
        if category_table[i].name == "FX CHAINS" then
            category_table[i].list = fx_chains_data
            chains_found = true
        elseif category_table[i].name == "TRACK TEMPLATES" then
            category_table[i].list = track_templates_data
            templates_found = true
        end
    end

    if not chains_found and #fx_chains_data > 0 then
        category_table[#category_table + 1] = { name = "FX CHAINS", list = fx_chains_data }
    end
    if not templates_found and #track_templates_data > 0 then
        category_table[#category_table + 1] = { name = "TRACK TEMPLATES", list = track_templates_data }
    end
end

-- Public API aliases (maintain compatibility with existing scripts)
MakeFXFiles = CreatePluginFiles
ReadFXFile = LoadPluginFiles
WriteToFile = SaveToFile
SerializeToFile = SerializeValue
StringToTable = ConvertStringToTable
TableToString = ConvertTableToString
Literalize = EscapePatternChars
GetFileContext = ReadFileContents
InTbl = FindInTable
AddDevList = AddDeveloperName
GenerateFxList = BuildPluginList
Stripname = CleanPluginName
GetFXTbl = LoadPluginDatabase
UpdateChainsTrackTemplates = RefreshChainsAndTemplates


