-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta9.7.1
-- @changelog
--   - Fix Theme editor saving empty entry crashes
--   - Fix Pro-C 2 crash
-- @provides
--   src/FX Layouts/ValhallaFreqEcho (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaShimmer (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaVintageVerb (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaSupermassive (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaDelay (Valhalla DSP, LLC).ini
--   src/Images/Analog Knob 1.png
--   src/Images/trash.png
--   src/FX Layout Plugin Scripts/Pro Q 3.lua
--   src/FX Layout Plugin Scripts/Pro C 2.lua
--   src/ThemeColors.ini
--   src/IconFont1.ttf
--   src/Keyboard Shortcuts.ini
--   src/FX Default Values.ini
--   src/FXD - Record Last Touch.lua
--   src/Functions/EQ functions.lua
--   src/Functions/General Functions.lua
--   src/Functions/FX Layering.lua
--   src/Functions/Layout Editor functions.lua
--   src/Functions/Modulation.lua
--   src/Functions/Theme Editor Functions.lua
--   src/Functions/Filesystem_utils.lua
--   src/Constants.lua
--   src/Helpers/Sexan_FX_Browser.lua
-- @about
--   Please check the forum post for info:
--   https://forum.cockos.com/showthread.php?t=263622-- dofile("/home/antoine/Documents/Experiments/lua/debug_connect.lua")

---@type string
CurrentDirectory = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] -- GET DIRECTORY FOR REQUIRE
package.path = CurrentDirectory .. "?.lua;"

r = reaper
require("src.Helpers.Sexan_FX_Browser")
require("src.Functions.General Functions")
require("src.Functions.EQ functions")
require("src.Functions.Layout Editor functions")
require("src.Functions.FX Layering")
require("src.Functions.Modulation")
require("src.Functions.Theme Editor Functions")
require("src.Functions.Filesystem_utils")
require("src.Constants")
PluginScript = {} ---@class PluginScript

dofile(r.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")
local os_separator = package.config:sub(1, 1)


--------------------------==  declare Initial Variables & Functions  ------------------------
VersionNumber = 'V1.0beta10.3.2 '
FX_Add_Del_WaitTime = 2






function msg(m)
    return r.ShowConsoleMsg(tostring(m) .. "\n")
end

local FX_LIST, CAT = GetFXTbl()

---@class ViewPort
VP = {} -- viewport info
-- demo = {}
app = {}
enum_cache = {}
cache = {}
Draw = {
    Rect = {},
    DrawMode = {},
    ItemInst = {},
    L = {},
    R = {},
    Y = {},
    T = {},
    B = {},
    FxGUID = {},
    Time = 0,
    Df_EdgeRound = {}
}
AddFX = { Pos = {}, Name = {}, GUID = {} }
DelFX = { Pos = {}, Name = {} }
MovFX = { ToPos = {}, FromPos = {}, Lbl = {}, Copy = {} }
LFOwin = { w = 400, h = 300 }
ClrPallet = {}
Glob = {} ---@class GLOB
Sel_Cross = {}
ToDef = {}
DraggingFXs = {}; DraggingFXs_Idx = {}
DefaultWidth = 200
GapBtwnPrmColumns = 10
--Sequencer -----
StepSEQ_W = 20
StepSEQ_H = 100
SEQ_Default_Num_of_Steps = 8
SEQ_Default_Denom = 1




----------- Custom Colors-------------------
CustomColors = { 'Window_BG', 'FX_Devices_Bg', 'FX_Layer_Container_BG', 'Space_Between_FXs', 'Morph_A', 'Morph_B',
    'Layer_Solo', 'Layer_Mute', 'FX_Adder_VST', 'FX_Adder_VST3', 'FX_Adder_JS', 'FX_Adder_AU' }
CustomColorsDefault = {
    Window_BG = 0x000000ff,
    FX_Devices_Bg = 0x151515ff,
    FX_Layer_Container_BG = 0x262626ff,
    Space_Between_FXs = 0x131313ff,
    Morph_A = 0x22222266,
    Morph_B = 0x78787877,
    Layer_Solo = 0xDADF3775,
    Layer_Mute = 0xBE01015C,
    FX_Adder_VST = 0x6FB74BFF,
    FX_Adder_VST3 = 0xC3DC5CFF,
    FX_Adder_JS = 0x9348A9FF,
    FX_Adder_AU = 0x526D97FF,
    FX_Adder_CLAP = 0xB62424FF

}



----------Parameters --------------------
Prm = {
    McroModAmt = {},
    McroModAmt_Norm = {},
    Pos_L = {},
    Pos_T = {},
    Pos_R = {},
    Pos_B = {},
    ModAngle = {},
    SldrGrabXPos = {},
    Val = {},
    NameS = {},
    FXGUID = {},
    InstAdded = {},
    Init_Val = {},
    Num = {},
    TrkID = {},
    Deletable = {},
    Name = {}
}

-----------------------------------------
-----Param Modulations
-----------------------------------------
PM = { Ins = {}, FXGUID = {}, Corres_Glob_ID = {}, HasMod = {}, Final_V = {}, DIY_TrkID = {} }
waitForGmem = 0


-----------------------------------------
-----FX layering
-----------------------------------------
Lyr = {
    Selected = {},
    title = {},
    ProgBarClick = {},
    Title = {},
    ProgBarVal = {},
    SpltrID = {},
    Count = {},
    Solo = {},
    Mute = {},
    Rename = {},
    FX_Ins = {},
    ProgBarDrag = {},
    EditingTitle = {},
    LastFXPos = {},
    FrstFXPos = {},
    SplitrAttachTo = {},
    PrevFX = {},
    TitleToShow = {},
}

Spltr = {}


LE = { GridSize = 10, Sel_Items = {}, ChangeR_Bound = {} }
----Preset Morph--------------
PresetMorph = { timer = 0 }

--- FX Chain -----------------------------
FXchain = { FxGUID = {}, wait = 0, }


----track--------------------------------
Trk = {
    GUID = {},
    Prm = { FXGUID = {}, Inst = {}, AssignWhich = {}, V = {}, O_V = {}, Num = {}, WhichMcros = {} },
    FxGUID = {},
    PreFX = {}
}

------------------Divider---------------
Dvdr = { Width = {}, Clr = {}, Spc_Hover = {}, RestoreNormWidthWait = 0, RestoreNormWidthWait = {}, JustDrop = {}, }

-----------------FX State-----------------
FX = {
    Enable = {},
    InLyr = {},
    Width = {},
    Collapse = {},
    LyrNum = {},
    Win = {},
    Win_Name = {},
    Def_Type = {},
    Win_Name_S = {},
    TitleWidth = {},
    Sldr_W = {},
    WidthCollapse = {},
    Round = {},
    GrbRound = {},
    BgClr = {},
    Def_Sldr_W = {},
    Prm = {
        V_Round = {},
        V_FontSize = {},
        ShowCondition = {},
        ConditionPrm = {},
        ConditionPrm_V = {},
        Switch_W = {},
        Combo_W = {},
        Options = {},
        BgClrHvr = {},
        BgClrAct = {},
        Lbl_Clr = {},
        V_Clr = {},
        DragDir = {},
        Lbl_Pos = {},
        V_Pos = {},
        Style = {},
        GrbClr = {},
        BgClr = {},
        Count = {},
        Name = {},
        Num = {},
        V = {},
        InitV = {},
        AssignWhichParam = {},
        ToTrkPrm = {},
        Lbl = {},
        PosX = {},
        PosY = {},
        VertSldr = {},
        Type = {},
        CustomLbl = {},
        FontSize = {},
        Sldr_H = {}
    }
}


Knob_DefaultFontSize = 10
LBL_DefaultFontSize = 10
Df = { V_Sldr_W = 15, KnobRadius = 18, KnobSize = 15 * 3, Sldr_W = 160, Dvdr_Width = 15, Dvdr_Hvr_W = 0 }


-----------ShortCut-----------

KB_Shortcut = {}
Command_ID = {}


--------Pro C ------------------------
ProC = { Width = 280, Pt = { R = { m = {}, M = {} }, L = { m = {}, M = {} } } }









-------------------Macros --------------------------
Mc = { Val_Trk = {}, V_Out = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, Name = {} }
Wet = { DragLbl = {}, Val = {}, P_Num = {} }
MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8 }

r.gmem_attach('gmemForSpectrum')

-- FXs listed here will not have a fx window in the script UI
BlackListFXs = { 'Macros', 'JS: Macros .+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'AU: AULowpass (Apple)', 'AU: AULowpass', 'VST: FabFilter Pro C 2 ', 'Pro-C 2', 'Pro C 2',
    'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope',
    'JS: FXD Saike BandSplitter', 'JS: FXD Band Joiner', 'FXD Saike BandSplitter', 'FXD Band Joiner',
    'FXD Split to 32 Channels'
}
UtilityFXs = { 'Macros', 'JS: Macros /[.+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope', 'JS: FXD Band Joiner',
    'FXD Split to 32 Channels'
}

SpecialLayoutFXs = { 'VST: FabFilter Pro C 2 ', 'Pro Q 3', 'VST: FabFilter Pro Q 3 ', 'VST3: Pro Q 3 FabFilter',
    'VST3: Pro C 2 FabFilter', 'AU: Pro C 2 FabFilter' }







Sel_Track = r.GetSelectedTrack(0, 0)
if Sel_Track ~= nil then Sel_Track_FX_Count = r.TrackFX_GetCount(Sel_Track) end


FX_DeviceWindow_NoScroll = 0
---list of GUIDs for Each track FX
---@type string[]
FXGUID = {}
FirstLoop = true



------- ==  Colors ----------

Clr = {
    SliderGrab = 0x309D89ff,
    Dvdr = {
        Active = 0x777777aa,
        In_Layer = 0x131313ff,
        outline = 0x444444ff
    }

}

CLR_BtwnFXs_Btn_Hover = 0x77777744
CLR_BtwnFXs_Btn_Active = 0x777777aa
FX_Window_Clr_When_Dragging = 0x44444433
FX_Window_Clr_Default = 0x262626ff
Btns_Hover_DefaultColor = 0x2d3b3aff

Btns_DefaultColor = 0x333333ff
Btns_ClickedColor = 0x358f8fff
BGColor_FXLayeringWindow = 0x262626ff

Macro1Color = 0xff2121ff
Macro2Color = 0xff5521ff
Macro3Color = 0xff8921ff
Macro4Color = 0xffd321ff
Macro5Color = 0xf4ff21ff
Macro6Color = 0xb9ff21ff
Macro7Color = 0x6fff21ff
Macro8Color = 0x21ff6bff

EightColors = {
    LowMidSat = {},
    LowSat = {},
    MidSat = {},
    Bright = {},
    Bright_HighSat = {},
    HighSat_MidBright = {},
    bgWhenAsgnMod = {},
    bgWhenAsgnModAct = {},
    bgWhenAsgnModHvr = {},
    LFO = {}
}

---@param h number
---@param s number
---@param v number
---@param a number
function HSV(h, s, v, a)
    local r, g, b = r.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

for a = 1, 8, 1 do
    table.insert(EightColors.LowSat, HSV(0.08 * (a - 1), 0.25, 0.33, 0.25))
    table.insert(EightColors.LowMidSat, HSV(0.08 * (a - 1), 0.25, 0.33, 0.5))
    table.insert(EightColors.MidSat, HSV(0.08 * (a - 1), 0.5, 0.5, 0.5))
    table.insert(EightColors.Bright, HSV(0.08 * (a - 1), 1, 0.5, 0.2))
    table.insert(EightColors.Bright_HighSat, HSV(0.08 * (a - 1), 1, 1, 0.9))
    table.insert(EightColors.HighSat_MidBright, HSV(0.08 * (a - 1), 1, 0.5, 0.5))
    table.insert(EightColors.bgWhenAsgnMod, HSV(0.08 * (a - 0.7), 0.7, 0.6, 0.15))
    table.insert(EightColors.bgWhenAsgnModAct, HSV(0.08 * (a - 0.7), 0.8, 0.7, 0.9))
    table.insert(EightColors.bgWhenAsgnModHvr, HSV(0.08 * (a - 0.7), 1, 0.2, 0.5))
    table.insert(EightColors.LFO, HSV(0.08 * (a - 1), 0.7, 0.5, 1))
end



function HSV_Change(InClr, H, S, V, A)
    local R, g, b, a = r.ImGui_ColorConvertU32ToDouble4(InClr)

    local h, s, v = r.ImGui_ColorConvertRGBtoHSV(R, g, b)
    local h, s, v, a = (H or 0) + h, s + (S or 0), v + (V or 0), a + (A or 0)
    local R, g, b = r.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return r.ImGui_ColorConvertDouble4ToU32(R, g, b, a)
end

function BlendColors(Clr1, Clr2, pos)
    local R1, G1, B1, A1 = r.ImGui_ColorConvertU32ToDouble4(Clr1)

    local R2, G2, B2, A2 = r.ImGui_ColorConvertU32ToDouble4(Clr2)

    local R3 = SetMinMax((R2 - R1) * pos + R1, 0, 1)
    local G3 = SetMinMax((G2 - G1) * pos + G1, 0, 1)
    local B3 = SetMinMax((B2 - B1) * pos + B1, 0, 1)
    local A3 = SetMinMax((A2 - A1) * pos + A1, 0, 1)

    return r.ImGui_ColorConvertDouble4ToU32(R3, G3, B3, A3)
end

-----end of colors--------

Array_Macro_Colors = {
    frameBgColor          = {},
    frameBgHoveredColor   = {},
    frameBgActiveColor    = {},
    sliderGrabColor       = {},
    sliderGrabActiveColor = {}
}


x = 0.5

Cont_Param_Add_Mode = false
OffsetForMultipleMOD = 2

Array = {}







-----------------Script Testing Area---------------------------
--------------------------------Layout Editor Functions -----------------------------













------------------------------------------------------------------------------------------------------------



local LAST_USED_FX




-- EXAMPLE DRAW (NOTHING TO DO WITH PARSING ALL BELOOW)
---@param s string
local function Lead_Trim_ws(s) return s:match '^%s*(.*)' end

---@param filter_text string
local function Filter_actions(filter_text)
    filter_text = Lead_Trim_ws(filter_text)
    local t = {}
    if filter_text == "" or not filter_text then return t end
    for i = 1, #FX_LIST do
        local action = FX_LIST[i]
        local name = action:lower()
        local found = true
        for word in filter_text:gmatch("%S+") do
            if not name:find(word:lower(), 1, true) then
                found = false
                break
            end
        end

        if found then t[#t + 1] = action end
    end
    return t
end

local function SetMinMax(Input, Min, Max)
    if Input >= Max then
        Input = Max
    elseif Input <= Min then
        Input = Min
    else
        Input = Input
    end
    return Input
end


function FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost)
    ---@type integer|nil, boolean|nil
    local FX_Idx_For_AddFX, close
    if AddLastSPCinRack then FX_Idx_For_AddFX = FX_Idx - 1 end
    local MAX_FX_SIZE = 250
    local FxGUID = FXGUID[FX_Idx_For_AddFX or FX_Idx]
    r.ImGui_SetNextItemWidth(ctx, 180)
    _, ADDFX_FILTER = r.ImGui_InputTextWithHint(ctx, '##input', "SEARCH FX", ADDFX_FILTER,
        r.ImGui_InputTextFlags_AutoSelectAll())

    if r.ImGui_IsWindowAppearing(ctx) then
        local tb = FX_LIST
        r.ImGui_SetKeyboardFocusHere(ctx, -1)
    end

    local filtered_fx = Filter_actions(ADDFX_FILTER)
    --r.ImGui_SetNextWindowPos(ctx, r.ImGui_GetItemRectMin(ctx), ({ r.ImGui_GetItemRectMax(ctx) })[2])
    local filter_h = #filtered_fx == 0 and 2 or (#filtered_fx > 40 and 20 * 17 or (17 * #filtered_fx))
    local function InsertFX(Name)
        local FX_Idx = FX_Idx
        --- CLICK INSERT
        if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end

        r.TrackFX_AddByName(LT_Track, Name, false, -1000 - FX_Idx)

        -- if Inserted into Layer
        local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

        if FX.InLyr[FxGUID] == FXGUID_RackMixer and FX.InLyr[FxGUID] then
            DropFXtoLayerNoMove(FXGUID_RackMixer, LyrID, FX_Idx)
        end
        if SpaceIsBeforeRackMixer == 'SpcInBS' then
            DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx + 1, FX_Idx)
        end
        if SpcIsInPre then
            local inspos = FX_Idx + 1
            if SpaceIsBeforeRackMixer == 'End of PreFX' then
                table.insert(Trk[TrkID].PreFX, FxID)
            else
                table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FxID)
            end
            for i, v in pairs(Trk[TrkID].PreFX) do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v,
                    true)
            end
        elseif SpcInPost then
            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
            table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
            -- InsertToPost_Src = FX_Idx + offset+2
            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
            end
        end

        ADDFX_FILTER = nil
    end
    if ADDFX_FILTER ~= '' and ADDFX_FILTER then
        SL()
        r.ImGui_SetNextWindowSize(ctx, MAX_FX_SIZE, filter_h + 20)
        local x, y = r.ImGui_GetCursorScreenPos(ctx)

        ParentWinPos_x, ParentWinPos_y = r.ImGui_GetWindowPos(ctx)
        local VP_R = VP.X + VP.w
        if x + MAX_FX_SIZE > VP_R then x = ParentWinPos_x - MAX_FX_SIZE end

        r.ImGui_SetNextWindowPos(ctx, x, y - filter_h / 2)
        if r.ImGui_BeginPopup(ctx, "##popupp", r.ImGui_WindowFlags_NoFocusOnAppearing() --[[ MAX_FX_SIZE, filter_h ]]) then
            ADDFX_Sel_Entry = SetMinMax(ADDFX_Sel_Entry or 1, 1, #filtered_fx)
            for i = 1, #filtered_fx do
                local ShownName
                if filtered_fx[i]:find('VST:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(5, (fx:find('.vst') or 999) - 1)
                    local clr = FX_Adder_VST or
                        CustomColorsDefault
                        .FX_Adder_VST -- TODO I think all these FX_ADDER vars came from FX_ADDER module, which isn’t there anymore. Should we bring it back ?
                    ---if we do have to bring it back, my bad, I thought it was a duplicate of Sexan’s module
                    MyText('VST', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('VST3:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6) .. '##vst3'
                    local clr = FX_Adder_VST3 or CustomColorsDefault.FX_Adder_VST3
                    MyText('VST3', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('JS:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(4)
                    local clr = FX_Adder_JS or CustomColorsDefault.FX_Adder_JS
                    MyText('JS', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('AU:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(4)
                    local clr = FX_Adder_AU or CustomColorsDefault.FX_Adder_AU
                    MyText('AU', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('CLAP:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6)
                    local clr = FX_Adder_CLAP or CustomColorsDefault.FX_Adder_CLAP
                    MyText('CLAP', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end

                if r.ImGui_Selectable(ctx, (ShownName or filtered_fx[i]) .. '##emptyName', DRAG_FX == i) then
                    if filtered_fx[i] then
                        InsertFX(filtered_fx[i])
                        r.ImGui_CloseCurrentPopup(ctx)
                        close = true
                    end
                end
                if i == ADDFX_Sel_Entry then
                    HighlightSelectedItem(0xffffff11, nil, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end
                -- DRAG AND DROP
                if r.ImGui_IsItemActive(ctx) and r.ImGui_IsMouseDragging(ctx, 0) then
                    -- HIGHLIGHT DRAGGED FX
                    DRAG_FX = i
                    AddFX_Drag(filtered_fx[i]) -- TODO did this come from FX_ADDER
                end
            end

            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) then
                r.TrackFX_AddByName(LT_Track, filtered_fx[ADDFX_Sel_Entry], false, -1000 - FX_Idx)
                LAST_USED_FX = filtered_fx[filtered_fx[ADDFX_Sel_Entry]]
                ADDFX_Sel_Entry = nil
                r.ImGui_CloseCurrentPopup(ctx)
                close = true

                --FILTER = ''
                --r.ImGui_CloseCurrentPopup(ctx)
            elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_UpArrow()) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry - 1
            elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_DownArrow()) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry + 1
            end
            --r.ImGui_EndChild(ctx)
            r.ImGui_EndPopup(ctx)
        end


        r.ImGui_OpenPopup(ctx, "##popupp")
        r.ImGui_NewLine(ctx)
    end


    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
        r.ImGui_CloseCurrentPopup(ctx)
        ADDFX_FILTER = nil
    end
    return close
end

local function DrawChildMenu(tbl, path, FX_Idx)
    path = path or ""
    for i = 1, #tbl do
        if tbl[i].dir then
            if r.ImGui_BeginMenu(ctx, tbl[i].dir) then
                DrawChildMenu(tbl[i], table.concat({ path, os_separator, tbl[i].dir }), FX_Idx)
                r.ImGui_EndMenu(ctx)
            end
        end
        if type(tbl[i]) ~= "table" then
            if r.ImGui_Selectable(ctx, tbl[i], false) then -- TODO for all calls to ImGui_Selectable, let’s pass the third argument as false instead of nil
                if TRACK then
                    r.TrackFX_AddByName(TRACK, table.concat({ path, os_separator, tbl[i] }), false,
                        -1000 - FX_Idx)
                end
            end
        end
    end
end

----------------------------End declare Initial Variables   ------------------------

--------------------------==  Before GUI (No Loop) ----------------------------


GetLTParam()

ctx = r.ImGui_CreateContext('FX Device', r.ImGui_ConfigFlags_DockingEnable())








----- Get plugin scripts path -------
local pluginScriptPath = CurrentDirectory .. 'src/FX Layout Plugin Scripts'
---List of Plugin Scripts for FXD
PluginScripts = scandir(pluginScriptPath)
for i, v in ipairs(PluginScripts) do
    if not v:find('.lua') then
        PluginScripts[i] = nil
    else
        PluginScripts[i] = v:sub(0, v:find('.lua') - 1)
    end
end



local script_folder = select(2, r.get_action_context()):match('^(.+)[\\//]')
script_folder       = script_folder .. '/src'
FontAwesome         = r.ImGui_CreateFont(script_folder .. '/IconFont1.ttf', 30)


NumOfTotalTracks = r.CountTracks(0)
-- Repeat for every track, at the beginning of script
for Track_Idx = 0, NumOfTotalTracks - 1, 1 do
    local Track = r.GetTrack(0, Track_Idx)
    local TrkID = r.GetTrackGUID(Track)

    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].Mod = {}
    Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
    Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
    for i = 1, 8, 1 do -- for every modulator
        Trk[TrkID].Mod[i] = {}
        local m = Trk[TrkID].Mod[i]
        m.ATK = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' Atk', '', false)))
        m.REL = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' Rel', '', false)))
        Trk[TrkID].SEQL[i] = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Length', '', false)))
        Trk[TrkID].SEQ_Dnom[i] = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator', '', false)))
        m.Smooth = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' Follower Speed', '', false)))

        m.Gain = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' Follower Gain', '', false)))

        Trk[TrkID].Mod[i].SEQ = Trk[TrkID].Mod[i].SEQ or {}
        --Get Seq Steps
        if Trk[TrkID].SEQL[i] then
            for St = 1, Trk[TrkID].SEQL[i], 1 do
                Trk[TrkID].Mod[i].SEQ[St] = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', '',
                        false)))
            end
        end
    end



    local FXCount = r.TrackFX_GetCount(Track)
    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}
    Trk[TrkID].PostFX = Trk[TrkID].PostFX or {}



    function attachImagesAndFonts()
        Img = { -- TODO move to constants
            Trash = r.ImGui_CreateImage(CurrentDirectory ..'/src/Images/trash.png')
        }


        for i = 6, 64, 1 do
            _G['Font_Andale_Mono_' .. i] = r.ImGui_CreateFont('andale mono', i)
        end


        Font_Andale_Mono_20_B = r.ImGui_CreateFont('andale mono', 20, r.ImGui_FontFlags_Bold()) -- TODO move to constants
        r.ImGui_Attach(ctx, Font_Andale_Mono_20_B)
        for i = 6, 64, 1 do
            r.ImGui_Attach(ctx, _G['Font_Andale_Mono_' .. i])
        end
        r.ImGui_Attach(ctx, FontAwesome)
        r.ImGui_Attach(ctx, Img.Trash)


        for i = 6, 64, 1 do
            _G['Arial_' .. i] = r.ImGui_CreateFont('Arial', i)
            r.ImGui_Attach(ctx, _G['Arial_' .. i])
        end

        Arial = r.ImGui_CreateFont('Arial', 12) -- TODO move to constants
    end

    function TrashIcon(size, lbl, ClrBG, ClrTint)
        local rv = r.ImGui_ImageButton(ctx, '##' .. lbl, Img.Trash, size, size, nil, nil, nil, nil, ClrBG, ClrTint) -- TODO weird but I can’t find anything in the official docs or the reaImGui repo about this function
        if r.ImGui_IsItemHovered(ctx) then
            TintClr = 0xCE1A28ff
            return rv, TintClr
        end
    end

    RetrieveFXsSavedLayout(FXCount)

    Trk[TrkID].ModPrmInst = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ModPrmInst', '', false)))
    for CC = 1, Trk[TrkID].ModPrmInst or 0, 1 do
        _, Trk.Prm.WhichMcros[CC .. TrkID] = r.GetSetMediaTrackInfo_String(Track,
            'P_EXT: CC Linked to which Modulation' .. CC, '', false)
    end

    _, PM.DIY_TrkID[TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID)
    PM.DIY_TrkID[TrkID] = tonumber(PM.DIY_TrkID[TrkID])

    _, Trk.Prm.Inst[TrkID] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Trk Prm Count', '', false)
    Trk.Prm.Inst[TrkID] = tonumber(Trk.Prm.Inst[TrkID])

    i = 1
    ---retrieve Pre-FX mappings?
    ---store in CurTrk.PreFX
    while i do
        local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. i, '', false)
        if rv then
            Trk[TrkID].PreFX[i] = str; i = i + 1
        else
            i = nil
        end
    end

    i = 1
    ---retrieve Post-FX mappings?
    ---store in CurTrk.PostFX
    while i do
        local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PostFX ' .. i, '', false)
        if rv then
            Trk[TrkID].PostFX[i] = str; i = i + 1
        else
            i = nil
        end
    end



    if Trk[TrkID].PreFX == {} then Trk[TrkID].PreFX = nil end
    for P = 1, Trk.Prm.Inst[TrkID] or 0, 1 do
        _, Trk.Prm.Num[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track' .. TrkID .. ' P =' .. P)
        _, Trk.Prm.WhichMcros[P .. TrkID] = r.GetProjExtState(0, 'FX Devices',
            'Prm' .. P .. 'Has Which Macro Assigned, TrkID =' .. TrkID)
        if Trk.Prm.WhichMcros[P .. TrkID] == '' then Trk.Prm.WhichMcros[P .. TrkID] = nil end

        Trk.Prm.Num[P .. TrkID] = tonumber(Trk.Prm.Num[P .. TrkID])

        for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
            local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
            _, Trk.Prm.FXGUID[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'P_Trk :' .. P .. 'Trk-' .. TrkID)
        end
    end

    for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
        local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
        local _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)




        local _, DefaultSldr_W = r.GetProjExtState(0, 'FX Devices', 'Default Slider Width for FX:' .. FxGUID)
        if DefaultSldr_W ~= '' then FX.Def_Sldr_W[FxGUID] = DefaultSldr_W end
        local _, Def_Type = r.GetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID)
        if Def_Type ~= '' then FX.Def_Type[FxGUID] = Def_Type end

        if FxGUID ~= nil then
            GetProjExt_FxNameNum(FxGUID)

            _, FX.InLyr[FxGUID]          = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' ..
                FxGUID .. 'in layer')
            --FX.InLyr[FxGUID] = StringToBool[FX.InLyr[FxGUID]]
            _, FX.LyrNum[FxGUID]         = r.GetProjExtState(0, 'FX Devices', 'FXLayer ' .. FxGUID .. 'LayerNum')
            _, FX[FxGUID].inWhichLyr     = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. FxGUID .. 'is in Layer ID')
            _, FX[FxGUID].ContainerTitle = r.GetProjExtState(0, 'FX Devices - ',
                'FX' .. FxGUID .. 'FX Layer Container Title ')
            if FX[FxGUID].ContainerTitle == '' then FX[FxGUID].ContainerTitle = nil end

            FX[FxGUID].inWhichLyr = tonumber(FX[FxGUID].inWhichLyr)
            FX.LyrNum[FxGUID] = tonumber(FX.LyrNum[FxGUID])
            _, Lyr.SplitrAttachTo[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. FxGUID)
            _, Prm.InstAdded[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added')
            if Prm.InstAdded[FxGUID] == 'true' then Prm.InstAdded[FxGUID] = true end

            if FX.InLyr[FxGUID] == "" then FX.InLyr[FxGUID] = nil end
            FX[FxGUID].Morph_ID = tonumber(select(2,
                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID, '', false)))
            _, FX[FxGUID].Unlink = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '',
                false)
            if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

            if FX[FxGUID].Morph_ID then
                Trk[TrkID].Morph_ID = Trk[TrkID].Morph_ID or {}
                Trk[TrkID].Morph_ID[FX[FxGUID].Morph_ID] = FxGUID
            end

            local rv, ProC_ID = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ProC_ID ' .. FxGUID, '', false)
            if rv then FX[FxGUID].ProC_ID = tonumber(ProC_ID) end

            if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

            for Fx_P = 1, #FX[FxGUID] or 0, 1 do
                FX[FxGUID][Fx_P].V = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                        Fx_P .. 'Value before modulation', '', false)))


                local ParamX_Value = 'Param' ..
                    tostring(FX[FxGUID][Fx_P].Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID
                ParamValue_At_Script_Start = r.TrackFX_GetParamNormalized(Track, FX_Idx, FX[FxGUID][Fx_P].Num or 0)
                _G[ParamX_Value] = ParamValue_At_Script_Start
                _, FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = r.GetProjExtState(0, 'FX Devices',
                    'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'to Trk Prm')
                FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = tonumber(FX.Prm.ToTrkPrm[FxGUID .. Fx_P])

                local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]

                _G[ParamX_Value] = FX[FxGUID][Fx_P].V or 0
                FX[FxGUID][Fx_P].WhichCC = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' ..
                        (FX[FxGUID][Fx_P].Num or 0), '', false)))
                _, FX[FxGUID][Fx_P].WhichMODs = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods', '', false)
                if FX[FxGUID][Fx_P].WhichMODs == '' then FX[FxGUID][Fx_P].WhichMODs = nil end
                FX[FxGUID][Fx_P].ModAMT = {}


                local CC = FX[FxGUID][Fx_P].WhichCC
                local HasModAmt
                for m, v in ipairs(MacroNums) do
                    local FP = FX[FxGUID][Fx_P]
                    FX[FxGUID][Fx_P].ModAMT[m] = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                            Fx_P .. 'Macro' .. m .. 'Mod Amt', '', false)))
                    if FX[FxGUID][Fx_P].ModAMT[m] then HasModAmt = true end



                    Trk[TrkID].Mod = Trk[TrkID].Mod or {}
                    Trk[TrkID].Mod[m] = Trk[TrkID].Mod[m] or {}
                    Trk[TrkID].Mod[m].Val = tonumber(select(2,
                        r.GetProjExtState(0, 'FX Devices', 'Macro' .. m .. 'Value of Track' .. TrkID)))

                    FP.ModBypass = RemoveEmptyStr(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', '',
                            false)))




                    if Prm.McroModAmt[IdM] ~= nil then
                        local width = FX.Width[FxGUID] or DefaultWidth or 270
                        Prm.McroModAmt_Norm[IdM] = Prm.McroModAmt --[[ [IdM]/(width*0.65) ]]
                    end
                end


                if not HasModAmt then FX[FxGUID][Fx_P].ModAMT = nil end
            end

            FX[FxGUID] = FX[FxGUID] or {}
            if r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. '1' .. FxGUID, '', false) then
                FX[FxGUID].MorphA = FX[FxGUID].MorphA or {}
                FX[FxGUID].MorphB = FX[FxGUID].MorphB or {}
                FX[FxGUID].PrmList = {}
                local PrmCount = r.TrackFX_GetNumParams(Track, FX_Idx)

                RestoreBlacklistSettings(FxGUID, FX_Idx, Track, PrmCount)

                for i = 0, PrmCount - 4, 1 do
                    _, FX[FxGUID].MorphA[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. i .. FxGUID, '',
                        false)
                    FX[FxGUID].MorphA[i] = tonumber(FX[FxGUID].MorphA[i])
                    _, FX[FxGUID].MorphB[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph B' .. i .. FxGUID, '',
                        false)
                    FX[FxGUID].MorphB[i] = tonumber(FX[FxGUID].MorphB[i])
                end

                _, FX[FxGUID].MorphA_Name = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', '', false)
                if FX[FxGUID].MorphA_Name == '' then FX[FxGUID].MorphA_Name = nil end
                _, FX[FxGUID].MorphB_Name = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', '', false)
                if FX[FxGUID].MorphB_Name == '' then FX[FxGUID].MorphB_Name = nil end
            end
        end

        _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
        if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
            local FXGUIDofRackMixer = r.TrackFX_GetFXGUID(Track, FX_Idx)
            FX[FXGUIDofRackMixer].LyrID = FX[FXGUIDofRackMixer].LyrID or {}
            FX[FXGUIDofRackMixer].LyrTitle = FX[FXGUIDofRackMixer].LyrTitle or {}
            FX[FXGUIDofRackMixer].ActiveLyrCount = 0

            for i = 1, 8, 1 do
                _, FX[FXGUIDofRackMixer].LyrID[i] = r.GetProjExtState(0, 'FX Devices',
                    'FX' .. FXGUIDofRackMixer .. 'Layer ID ' .. i)
                _, FX[FXGUIDofRackMixer].LyrTitle[i] = r.GetProjExtState(0, 'FX Devices - ',
                    'FX' .. FXGUIDofRackMixer .. 'Layer Title ' .. i)
                if FX[FXGUIDofRackMixer].LyrTitle[i] == '' then FX[FXGUIDofRackMixer].LyrTitle[i] = nil end
                FX[FXGUIDofRackMixer].LyrID[i] = tonumber(FX[FXGUIDofRackMixer].LyrID[i])
                if FX[FXGUIDofRackMixer].LyrID[i] ~= -1 and FX[FXGUIDofRackMixer].LyrID[i] then
                    FX[FXGUIDofRackMixer].ActiveLyrCount =
                        FX[FXGUIDofRackMixer].ActiveLyrCount + 1
                end
            end


            _, Lyr.FX_Ins[FXGUIDofRackMixer] = r.GetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FxGUID)
            if Lyr.FX_Ins[FXGUIDofRackMixer] == "" then Lyr.FX_Ins[FXGUIDofRackMixer] = nil end
            Lyr.FX_Ins[FXGUIDofRackMixer] = tonumber(Lyr.FX_Ins[FXGUIDofRackMixer])
        elseif FX_Name:find('FXD Saike BandSplitter') then
            FX[FxGUID].BandSplitID = tonumber(select(2,
                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: BandSplitterID' .. FxGUID, '', false)))
            _, FX[FxGUID].AttachToJoiner = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Splitter\'s Joiner FxID ' ..
                FxGUID, '', false)

            for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                --Restore Band Split
                local FxID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                if select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which BS' .. FxID, '', false)) == FxGUID then
                    --local _, Guid_FX_In_BS = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX is in which BS'..FxID, '', false  )
                    FX[FxID] = FX[FxID] or {}
                    FX[FxID].InWhichBand = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which Band' .. FxID, '', false)))

                    FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
                    table.insert(FX[FxGUID].FXsInBS, FxID)
                end
            end
        end



        if Track == LT_Track and string.find(FX_Name, 'Pro%-Q 3') ~= nil then
            _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 331)
            ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
            ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3.DspRange[FX_Idx])
        end
    end

    for m = 1, 8, 1 do
        _, Trk[TrkID].Mod[m].Name = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro' .. m .. 's Name' .. TrkID, '',
            false)
        if Trk[TrkID].Mod[m].Name == '' then Trk[TrkID].Mod[m].Name = nil end
        _, Trk[TrkID].Mod[m].Type = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Mod' .. m .. 'Type', '', false)
        if Trk[TrkID].Mod[m].Type == '' then Trk[TrkID].Mod[m].Type = nil end
    end
end

attachImagesAndFonts()

---------------------------------------------------------------
-----------Retrieve Keyboard Shortcut Settings ----------------
---------------------------------------------------------------
if CallFile('r', 'Keyboard Shortcuts.ini') then
    local file, filepath = CallFile('r', 'Keyboard Shortcuts.ini')
    if not file then return end
    Content = file:read('*a')
    local L = get_lines(filepath)
    for i, v in ipairs(L) do
        KB_Shortcut[i] = v:sub(0, v:find(' =') - 1)
        Command_ID[i] = v:sub(v:find(' =') + 3, nil)
    end
end





---------------------------- End For Before GUI ----------------------------

function loop()
    GetLT_FX_Num()
    GetLTParam()
    if ChangeFont then
        r.ImGui_Attach(ctx, _G
            [(ChangeFont_Font or 'Font_Andale_Mono') .. '_' .. (ChangeFont_Size or ChangeFont.FtSize)])
        ChangeFont = nil
        ChangeFont_Size = nil
        ChangeFont_Font = nil
        ChangeFont_Var = nil
    end



    if Dock_Now then
        r.ImGui_SetNextWindowDockID(ctx, -1)
    end
    Dock_Now = nil
    ProC.ChanSplit = nil





    if LT_Track then TrkClr = r.ImGui_ColorConvertNative(r.GetTrackColor(LT_Track)) end
    TrkClr = ((TrkClr or 0) << 8) | 0x66 -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_MenuBarBg(), TrkClr or 0x00000000)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), Window_BG or CustomColorsDefault.Window_BG)
    --------------------------==  BEGIN GUI----------------------------------------------------------------------------
    local visible, open = r.ImGui_Begin(ctx, 'FX Device', true,
        r.ImGui_WindowFlags_NoScrollWithMouse() + r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_MenuBar() +
        r.ImGui_WindowFlags_NoCollapse())
    r.ImGui_PopStyleColor(ctx, 2) -- for menu  bar and window BG


    local Viewport = r.ImGui_GetWindowViewport(ctx)
    VP.w, VP.h     = r.ImGui_Viewport_GetSize(Viewport)
    VP.x, VP.y     = r.ImGui_GetCursorScreenPos(ctx) -- TODO should this be marked as VP.X instead of lowercase? Other instances of the var are uppercase


    ----------------------------------------------------------------------------
    -- ImGUI Variables-----------------------------------------------------------
    ----------------------------------------------------------------------------
    Mods  = r.ImGui_GetKeyMods(ctx)
    Alt   = r.ImGui_Mod_Alt()
    Ctrl  = r.ImGui_Mod_Ctrl()
    Shift = r.ImGui_Mod_Shift()
    Apl   = r.ImGui_Mod_Super()





    if visible then
        VP.w, VP.h = r.ImGui_Viewport_GetSize(Viewport)
        VP.FDL = VP.FDL or r.ImGui_GetForegroundDrawList(ctx)
        VP.X, VP.Y = r.ImGui_GetCursorScreenPos(ctx)

        ----------------- Keyboard Shortcuts ---------------
        if not r.ImGui_IsAnyItemActive(ctx) then
            for i, v in pairs(KB_Shortcut) do
                if not v:find('+') then --if shortcut has no modifier
                    if r.ImGui_IsKeyPressed(ctx, AllAvailableKeys[v]) and Mods == 0 then
                        --[[ local commandID = r.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND')
                        local CommandTxt =  r.CF_GetCommandText(0, commandID) -- 0 prob means arrange window, it's the section drop down from action window's top right corner
                        r.Main_OnCommand(commandID, 0) ]]
                        if Command_ID[i] then
                            local Cmd_Num = r.NamedCommandLookup(Command_ID[i])
                            r.Main_OnCommand(Cmd_Num, 0)
                        end
                    end
                else
                    local Mod = 0
                    if v:find('Shift') then Mod = Mod + r.ImGui_Mod_Shift() end
                    if v:find('Alt') then Mod = Mod + r.ImGui_Mod_Alt() end
                    if v:find('Ctrl') then Mod = Mod + r.ImGui_Mod_Ctrl() end
                    if v:find('Cmd') then Mod = Mod + r.ImGui_Mod_Super() end


                    local rev = v:reverse()
                    local lastPlus = rev:find('+')
                    local Ltr = rev:sub(1, rev:find('+') - 2)
                    local AftrLastPlus = Ltr:reverse()


                    if Mods == Mod and r.ImGui_IsKeyPressed(ctx, AllAvailableKeys[AftrLastPlus]) then
                        if Command_ID[i] then
                            local Cmd_Num = r.NamedCommandLookup(Command_ID[i])
                            r.Main_OnCommand(Cmd_Num, 0)
                        end
                    end
                end
            end
        end



        if LT_Track == nil then
            local Viewport = r.ImGui_GetWindowViewport(ctx)

            r.ImGui_DrawList_AddTextEx(VP.FDL, Font_Andale_Mono_20_B, 20, VP.X, VP.Y + VP.h / 2,
                0xffffffff,
                'Select a track to start')
        else
            function GetAllInfoNeededEachLoop()
                TimeEachFrame = r.ImGui_GetDeltaTime(ctx)
                if ImGUI_Time == nil then ImGUI_Time = 0 end
                ImGUI_Time             = ImGUI_Time + TimeEachFrame
                _, TrkName             = r.GetTrackName(LT_Track)

                Wheel_V, Wheel_H       = r.ImGui_GetMouseWheel(ctx)
                LT_Track               = r.GetLastTouchedTrack()
                IsAnyMouseDown         = r.ImGui_IsAnyMouseDown(ctx)
                LBtn_MousdDownDuration = r.ImGui_GetMouseDownDuration(ctx, 0)
                LBtnRel                = r.ImGui_IsMouseReleased(ctx, 0)
                RBtnRel                = r.ImGui_IsMouseReleased(ctx, 1)
                IsLBtnClicked          = r.ImGui_IsMouseClicked(ctx, 0)
                LBtnClickCount         = r.ImGui_GetMouseClickedCount(ctx, 0)
                IsLBtnHeld             = r.ImGui_IsMouseDown(ctx, 0)
                IsRBtnHeld             = r.ImGui_IsMouseDown(ctx, 1)
                Mods                   = r.ImGui_GetKeyMods(ctx) -- Alt = 4  shift =2  ctrl = 1  Command=8
                IsRBtnClicked          = r.ImGui_IsMouseClicked(ctx, 1)
                LT_FXGUID              = r.TrackFX_GetFXGUID(LT_Track or r.GetTrack(0, 0),
                    LT_FX_Number or 0)
                TrkID                  = r.GetTrackGUID(LT_Track or r.GetTrack(0, 0))
                Sel_Track_FX_Count     = r.TrackFX_GetCount(LT_Track)
                LBtnDrag               = r.ImGui_IsMouseDragging(ctx, 0)
                LBtnDC                 = r.ImGui_IsMouseDoubleClicked(ctx, 0)
            end

            HintMessage = nil
            GetAllInfoNeededEachLoop()

            -- if action to record last touch is triggered
            if r.GetExtState('FXD', 'Record last touch') ~= '' then
                if not IsPrmAlreadyAdded(true) then
                    StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,
                        true)
                end
                r.SetExtState('FXD', 'Record last touch', '', false)
            end


            ------- Add FX ---------
            for i, v in ipairs(AddFX.Name) do
                if v:find('FXD Gain Reduction Scope') then
                    local FxGUID = ProC.GainSc_FXGUID

                    FX[FxGUID] = FX[FxGUID] or {}
                    FX[FxGUID].ProC_ID = math.random(1000000, 9999999)
                    r.gmem_attach('CompReductionScope')
                    r.gmem_write(2002, FX[FxGUID].ProC_ID)
                    r.gmem_write(FX[FxGUID].ProC_ID, AddFX.Pos[i])
                    r.gmem_write(2000, PM.DIY_TrkID[TrkID])
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID ' .. FxGUID, FX[FxGUID].ProC_ID, true)
                elseif v:find('FXD Saike BandSplitter') then
                    r.gmem_attach('FXD_BandSplit')
                    BandSplitID = BandSplitID or math.random(1000000, 9999999)
                    r.gmem_write(0, BandSplitID)
                elseif v:find('FXD Band Joiner') then

                end



                AddFX_HideWindow(LT_Track, v, -1000 - AddFX.Pos[i])
                if v:find('FXD Band Joiner') then
                    local SplittrID = r.TrackFX_GetFXGUID(LT_Track, AddFX.Pos[i] - 1)
                    local JoinerID = r.TrackFX_GetFXGUID(LT_Track, AddFX.Pos[i])
                    FX[SplittrID] = FX[SplittrID] or {}
                    FX[SplittrID].AttachToJoiner = JoinerID
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Splitter\'s Joiner FxID ' .. SplittrID,
                        JoinerID,
                        true)
                elseif v:find('FXD Gain Reduction Scope') then
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, AddFX.Pos[i])

                    SyncAnalyzerPinWithFX(AddFX.Pos[i], AddFX.Pos[i] - 1, FX_Name)
                end
            end




            ----- Del FX ------
            if Sel_Track_FX_Count then
                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx or 0)

                    if FX_Name == 'JS: FXD Gain Reduction Scope' then
                        local _, FX_Name_Before = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)
                        if string.find(FX_Name_Before, 'Pro%-C 2') == nil then
                            r.TrackFX_Delete(LT_Track, FX_Idx)
                        end
                    end
                    if FX_Name == 'JS: FXD Split to 4 channels' then
                        local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        if string.find(FX_Name_After, 'Pro%-C 2') == nil and not AddFX.Name[1] then
                            r.TrackFX_Delete(LT_Track, FX_Idx)
                        end
                        local ProC_pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx + 1, 0, 0)
                        local SplitPin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)

                        if ProC_pin ~= SplitPin then
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 0, ProC_pin, 0) -- input L
                            local R = r.TrackFX_GetPinMappings(LT_Track, FX_Idx + 1, 0, 1)
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 1, R, 0)        -- input R

                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 0, ProC_pin, 0) -- out L
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 1, R, 0)        -- out R
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 2, 2 * R, 0)    -- out L Compare
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 3, 4 * R, 0)    -- out R Compare
                        end
                    end
                end
            end

            ----- Move FX -----
            if MovFX.FromPos[1] then
                local UndoLbl
                r.Undo_BeginBlock()
                for i, v in ipairs(MovFX.FromPos) do
                    if NeedCopyFX then
                        if v >= DropPos then offset = 1 else offset = 0 end
                        MovFX.ToPos[i] = math.max(MovFX.ToPos[i] - (offset or 0), 0)
                        r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, v, false)
                    end
                end

                for i, v in ipairs(MovFX.FromPos) do
                    r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, MovFX.ToPos[i], true)
                end
                r.Undo_EndBlock(MovFX.Lbl[i] or (UndoLbl or 'Move' .. 'FX'), 0)
                MovFX = { FromPos = {}, ToPos = {}, Lbl = {}, Copy = {} }
                NeedCopyFX = nil
                DropPos = nil
                --[[  MovFX.ToPos = {}
                MovFX.Lbl = {} ]]
            end


            --------- Don't remove this ---------
            AddFX.Name         = {}
            AddFX.Pos          = {}
            ProC.GainSc_FXGUID = nil
            ----------------------------------------

            ----- Duplicating FX to Layer -------
            if DragFX_Dest then
                MoveFX(DragFX_Src, DragFX_Src + 1, false)
                DropFXtoLayerNoMove(DroptoRack, DropToLyrID, DragFX_Src)
                MoveFX(DragFX_Src, DragFX_Dest + 1, true)

                DragFX_Src, DragFX_Dest, DropToLyrID = nil -- TODO should these be DragFX_Src, DragFX_Dest, DropToLyrID = nil, nil, nil
            end






            demo.PushStyle()



            r.gmem_attach('ParamValues')



            if PM.DIY_TrkID[TrkID] == nil then
                PM.DIY_TrkID[TrkID] = math.random(100000000, 999999999)
                r.SetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID,
                    PM.DIY_TrkID[TrkID])
            end

            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_D()) and Mods == Shift + Alt then
                DebugMode = true
            end



            -- if user switch selected track...
            if TrkID ~= TrkID_End then
                if TrkID_End ~= nil and TrkID ~= nil then
                    NumOfTotalTracks = r.CountTracks(0)
                    --[[  r.gmem_attach('TrackNameForMacro')
                    reaper .gmem_write(0,NumOfTotalTracks )]]
                end
                for P = 1, Trk.Prm.Inst[TrkID] or 0, 1 do
                    for m = 1, 8, 1 do
                        r.gmem_write(1000 * m + P, 0)
                    end
                end

                RetrieveFXsSavedLayout(Sel_Track_FX_Count)

                SyncTrkPrmVtoActualValue()
                LT_TrackNum = math.floor(r.GetMediaTrackInfo_Value(LT_Track, 'IP_TRACKNUMBER'))
            end

            if RepeatTimeForWindows ~= r.TrackFX_GetCount(LT_Track) then
                RetrieveFXsSavedLayout(Sel_Track_FX_Count)
            end



            ----Functions & Variables -------------
            Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)


            if IsLBtnClicked then Max_L_MouseDownDuration = nil end
            if IsLBtnHeld then
                Max_L_MouseDownDuration = math.max(LBtn_MousdDownDuration or -1,
                    Max_L_MouseDownDuration or -1)
            end



            if r.ImGui_IsKeyDown(ctx, 49) then -- if number 1 is pressed
                ShowKeyCode = true
            end

            -- if ShowKeyCode then
            if ShowKeyCode then
                for keynum = 0, 300, 1 do --
                    KeyDown = r.ImGui_IsKeyDown(ctx, keynum)
                    if KeyDown then
                        tooltip(tostring(keynum))
                    end
                end
            end


            -- end

            ----Colors & Font ------------
            --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), 0xaaaaaa44)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x474747ff)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0x6e6e6eff) --Use Hex + FF in the end
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), 0x808080ff)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x808080ff) ]]

            r.ImGui_PushFont(ctx, Font_Andale_Mono)




            ------------------------------
            ------Menu Bar---------------
            ------------------------------



            r.ImGui_BeginMenuBar(ctx)
            BarR, BarB = r.ImGui_GetItemRectMax(ctx)

            if r.ImGui_BeginMenu(ctx, 'Settings') then
                if select(2, r.ImGui_MenuItem(ctx, 'Style Editor', shoirtcutIn, p_selected, enabledIn)) then
                    OpenStyleEditor = toggle(OpenStyleEditor)
                end

                if select(2, r.ImGui_MenuItem(ctx, 'Keyboard Shortcut Editor', shoirtcutIn, p_selected, enabledIn)) then
                    OpenKBEditor = toggle(OpenKBEditor)
                end
                if r.ImGui_GetWindowDockID(ctx) ~= -1 then
                    if select(2, r.ImGui_MenuItem(ctx, 'Dock script', shoirtcutIn, p_selected, enabledIn)) then
                        Dock_Now = true
                    end
                end

                MyText('Version : ' .. VersionNumber, font, 0x777777ff, WrapPosX)
                r.ImGui_EndMenu(ctx)
            end

            if OpenStyleEditor then ShowStyleEditor() end
            if OpenKBEditor then Show_KBShortcutEditor() end
            ------------------------------
            ------Record Last Touch---------------
            ------------------------------

            if r.ImGui_Button(ctx, 'Record Last Touch') then
                --[[ local FX_Count = r.TrackFX_GetCount(LT_Track); local RptPrmFound
                local F = FX[LT_FXGUID] or {}

                if F then
                    for i, v in ipairs(F) do
                        if FX[LT_FXGUID][i].Num == LT_ParamNum then
                            RptPrmFound = true
                            TryingToAddExistingPrm = i .. LT_FXGUID
                            TimeNow = r.time_precise()
                        end
                    end
                    if not RptPrmFound and LT_FXGUID then
                        StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,true)
                    end
                end ]]

                if not IsPrmAlreadyAdded(true) then
                    StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,
                        true)
                end
            end



            if r.ImGui_IsItemClicked(ctx, 1) then Cont_Param_Add_Mode = toggle(Cont_Param_Add_Mode) end







            if FX.LayEdit then
                local FxGUID = FX.LayEdit

                if r.ImGui_Button(ctx, 'Grid +') then
                    LE.GridSize = LE.GridSize + 5
                elseif r.ImGui_Button(ctx, 'Grid -') then
                    LE.GridSize = LE.GridSize - 5
                end

                if #LE.Sel_Items > 1 then
                    SL()
                    if r.ImGui_Button(ctx, 'Align Y-Axis') then
                        for i, v in ipairs(LE.Sel_Items) do FX[FxGUID][v].PosX = FX[FxGUID][LE.Sel_Items[1]].PosX end
                    elseif r.ImGui_Button(ctx, 'Align X-Axis') then
                        for i, v in ipairs(LE.Sel_Items) do FX[FxGUID][v].PosY = FX[FxGUID][LE.Sel_Items[1]].PosY end
                    end
                end
                if #LE.Sel_Items > 2 then
                    if r.ImGui_Button(ctx, 'Equalize X Spacing') then
                        local Spc, max, min
                        local tab = {}
                        for i, v in ipairs(LE.Sel_Items) do
                            table.insert(tab, FX[FxGUID][v].PosX)
                        end

                        max = math.max(table.unpack(tab))
                        min = math.min(table.unpack(tab))
                        Spc = (max - min) / (#LE.Sel_Items - 1)
                        for i, v in ipairs(LE.Sel_Items) do
                            FX[FxGUID][v].PosX = min + Spc * (i - 1)
                        end
                    elseif r.ImGui_Button(ctx, 'Equalize Y Spacing') then
                        local Spc, max, min
                        local tab = {}
                        for i, v in ipairs(LE.Sel_Items) do
                            table.insert(tab, FX[FxGUID][v].PosY)
                        end
                        max = math.max(table.unpack(tab))
                        min = math.min(table.unpack(tab))
                        Spc = (max - min) / (#LE.Sel_Items - 1)
                        for i, v in ipairs(LE.Sel_Items) do
                            FX[FxGUID][v].PosY = min + Spc * (i - 1)
                        end
                    end
                end
            else --- only show if not in Layout edit mode
                r.ImGui_Text(ctx, TrkName)
            end
            TxtSz = r.ImGui_CalcTextSize(ctx, TrkName)
            r.ImGui_SameLine(ctx, VP.w - TxtSz - 20, nil) --r.ImGui_SetCursorPosX( ctx, BarR-50)




            r.ImGui_EndMenuBar(ctx)




            function DeleteAllParamOfFX(FXGUID, TrkID)
                for p, v in pairs(Trk.Prm.FXGUID) do
                    if Trk.Prm.FXGUID[p] == FXGUID and FXGUID ~= nil then
                        Trk.Prm.Inst[TrkID] = Trk.Prm.Inst[TrkID] - 1
                        Prm.Num[p] = nil
                        PM.HasMod[p] = nil

                        r.SetProjExtState(0, 'FX Devices', 'Params fxGUID of Param Inst' .. p, '')
                    elseif Trk.Prm.FXGUID[p] == nil and FXGUID == nil then

                    end
                end
            end

            if Cont_Param_Add_Mode == true then
                --TimeAfter_ContAdd= TimeAfter_ContAdd+1

                GetLT_FX_Num()
                GetLTParam()
                tooltip('Continuously Adding Last Touched Parameters..')

                local F = FX[LT_FXGUID] or {}; local RptPrmFound
                if LT_FXGUID and type(F) == 'table' then
                    for i, v in ipairs(F) do
                        F[i] = F[i] or {}
                        if F[i].Num == LT_ParamNum then
                            RptPrmFound = true
                            TryingToAddExistingPrm_Cont = i .. LT_FXGUID; TryingToAddExistingPrm = nil
                            TimeNow = r.time_precise()
                        end
                    end
                    if not RptPrmFound then
                        StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,
                            true)
                    end
                end
            else
                TryingToAddExistingPrm_Cont = nil
            end

            local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

            ------------------------------
            ------Layout Editing ---------
            ------------------------------


            ------------------Help Tips-------------------




            -----------==  Create Macros (Headers)-------------
            MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
            r.ImGui_BeginTable(ctx, 'table1', 16, r.ImGui_TableFlags_NoPadInnerX())

            Trk[TrkID] = Trk[TrkID] or {}
            Trk[TrkID].Mod = Trk[TrkID].Mod or {}
            for m = 1, 16, 1 do
                if m == 1 or m == 3 or m == 5 or m == 7 or m == 9 or m == 11 or m == 13 or m == 15 then
                    r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch(), 2)
                elseif m == 2 or m == 4 or m == 6 or m == 8 or m == 10 or m == 12 or m == 14 or m == 16 then
                    local weight, flag
                    if Trk[TrkID].Mod[m / 2] then
                        if Trk[TrkID].Mod[m / 2].Type == 'Step' then
                            weight, flag = 0,
                                r.ImGui_TableColumnFlags_WidthFixed()
                        end
                    end
                    r.ImGui_TableSetupColumn(ctx, '', flag or r.ImGui_TableColumnFlags_WidthStretch(), weight or 1)
                end
            end

            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0x373737ff)

            r.ImGui_TableHeadersRow(ctx) --create header row
            r.gmem_attach('ParamValues')

            Trk[TrkID] = Trk[TrkID] or {}
            Trk[TrkID].Mod = Trk[TrkID].Mod or {}







            for i, v in ipairs(MacroNums) do --Do 8 Times
                Mcro_Asgn_Md_Idx            = 'Macro' .. tostring(MacroNums[i])

                Trk[TrkID].Mod[i]           = Trk[TrkID].Mod[i] or {}
                local I, Name, CurX         = Trk[TrkID].Mod[i], nil, r.ImGui_GetCursorPosX(ctx)
                local frameBgColor          = r.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.5, 0.5, 0.2)
                local frameBgHoveredColor   = r.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.6, 0.5, 0.2)
                local frameBgActiveColor    = r.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.7, 0.5, 0.2)
                local sliderGrabColor       = r.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.9, 0.9, 0.2)
                local sliderGrabActiveColor = r.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.9, 0.9, 0.8)
                r.ImGui_PushID(ctx, i)
                local function PushClr(AssigningMacro)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowMidSat[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), EightColors.MidSat[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), EightColors.Bright[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), EightColors.HighSat_MidBright[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrabActive(), EightColors.Bright_HighSat[i])

                    if AssigningMacro == i then
                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.HighSat_MidBright[i])
                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), EightColors.bgWhenAsgnModAct[i])
                        PopColorTime = 2
                    end
                    clrPop = 6
                    return PopColorTime
                end



                Trk[TrkID].Mod[i].Type = Trk[TrkID].Mod[i].Type or 'Macro'
                if Trk[TrkID].Mod[i].Type == 'Macro' then
                    PopColorTime = PushClr(AssigningMacro)

                    r.ImGui_TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
                    MacroX_Label = 'Macro' .. tostring(MacroNums[i])


                    MacroValueLBL = TrkID .. 'Macro' .. MacroNums[i]

                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)

                    IsMacroSlidersEdited, I.Val = r.ImGui_SliderDouble(ctx, i .. '##', I.Val, Slider1Min or 0,
                        Slider1Max or 1)
                    IsMacroActive = r.ImGui_IsItemActive(ctx)
                    if IsMacroActive == true then Mc.AnyActive = true end
                    R_ClickOnMacroSliders = r.ImGui_IsItemClicked(ctx, 1)
                    -- if r.ImGui_IsItemClicked( ctx,1) ==true and Mods==nil then R_ClickOnMacroSliders = true end
                    if r.ImGui_IsItemClicked(ctx, 1) == true and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'Macro' .. i .. 'Menu')
                    end

                    if AssigningMacro == i then
                        BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
                    end



                    --- Macro Label
                    r.ImGui_TableSetColumnIndex(ctx, MacroNums[i] * 2 - 1)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowSat[i])
                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                    MacroNameEdited, I.Name = r.ImGui_InputText(ctx, '##', I.Name or 'Macro ' .. i)
                    if MacroNameEdited then
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name,
                            true)
                    end

                    if IsMacroActive then
                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then
                            r.TrackFX_SetParamNormalized(LT_Track, 0, v - 1, I.Val)
                            r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID, I.Val)
                        end
                    else
                    end


                    if AssigningMacro == i then r.ImGui_PopStyleColor(ctx, PopColorTime) end

                    if R_ClickOnMacroSliders and AssigningMacro == nil and Mods == 0 then
                        AssigningMacro = i
                    elseif R_ClickOnMacroSliders and AssigningMacro ~= nil then
                        AssigningMacro = nil
                    end




                    r.ImGui_PopStyleColor(ctx, clrPop)
                elseif Trk[TrkID].Mod[i].Type == 'env' then
                    if Mods == Shift then DragSpeed = 0.0001 else DragSpeed = 0.01 end
                    PopColorTime = PushClr(AssigningMacro)
                    r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2)
                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                    r.ImGui_SetNextItemWidth(ctx, 60)
                    local Mc = Trk[TrkID].Mod[i]

                    local atk, rel = Mc.atk, Mc.rel
                    at, Mc.ATK = r.ImGui_DragDouble(ctx, '## atk' .. i, Mc.ATK, DragSpeed, 0, 1, '',
                        r.ImGui_SliderFlags_NoInput())
                    SL(nil, 0)
                    RCat = r.ImGui_IsItemClicked(ctx, 1)
                    local L, T = r.ImGui_GetItemRectMin(ctx)
                    local W, H = r.ImGui_GetItemRectSize(ctx)
                    local R, B = L + W, T + H
                    local Atk = Mc.atk
                    if at then
                        Mc.atk = 0.000001 ^ (1 - Mc.ATK)
                        r.gmem_write(4, 2)                      -- tells jsfx user is adjusting atk
                        r.gmem_write(9 + ((i - 1) * 2), Mc.atk) -- tells atk value
                        r.gmem_write(5, i)                      -- tells which macro is being tweaked
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Atk', Mc.ATK, true)
                    end
                    if r.ImGui_IsItemActive(ctx) then
                        r.ImGui_SetNextWindowPos(ctx, L, T - H - 10)
                        r.ImGui_BeginTooltip(ctx)
                        local f = '%.1f'
                        if Mods == Alt then f = '%.3f' end
                        local num = (Mc.atk or 0.001) * 1000
                        if num > 100 then f = '%.0f' end
                        if num < 10 then f = '%.2f' end
                        if num < 1 then f = '%.3f' end
                        r.ImGui_Text(ctx, (f):format(num))
                        r.ImGui_EndTooltip(ctx)
                    end
                    local WDL = r.ImGui_GetWindowDrawList(ctx)
                    r.ImGui_DrawList_AddLine(WDL, L + W * Mc.ATK, T, R, T, 0xffffffff)
                    r.ImGui_DrawList_AddLine(WDL, L, B, L + W * Mc.ATK, T, 0xffffffff)

                    if AssigningMacro == i then
                        BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
                    end

                    r.ImGui_SetNextItemWidth(ctx, 60)

                    re, Mc.REL  = r.ImGui_DragDouble(ctx, '## rel' .. i, Mc.REL, DragSpeed, 0.001, 1, '',
                        r.ImGui_SliderFlags_NoInput())
                    local RCrel = r.ImGui_IsItemClicked(ctx, 1)
                    if re then
                        --Mc.rel = 10^(rel or 0.001) /10
                        Mc.rel = 0.001 ^ (1 - Mc.REL)
                        r.gmem_write(4, 3)                       -- tells jsfx user is adjusting rel
                        r.gmem_write(10 + ((i - 1) * 2), Mc.rel) -- tells rel value
                        r.gmem_write(5, i)                       -- tells which macro is being tweaked
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Rel', Mc.REL, true)
                    end
                    if r.ImGui_IsItemActive(ctx) then
                        r.ImGui_SetNextWindowPos(ctx, L, T - H - 30)
                        r.ImGui_BeginTooltip(ctx)
                        r.ImGui_Text(ctx, ('%.3f'):format(Mc.rel or 0.001))
                        r.ImGui_EndTooltip(ctx)
                    end
                    local L, T = r.ImGui_GetItemRectMin(ctx)
                    local W, H = r.ImGui_GetItemRectSize(ctx)
                    local R, B = L + W, T + H
                    local Rel = Mc.rel or 0.001
                    --r.ImGui_DrawList_AddLine(Glob.FDL, L ,T,L+W*Rel,T, 0xffffffff)
                    r.ImGui_DrawList_AddLine(WDL, L, T, L + W * Mc.REL, B, 0xffffffff)
                    if AssigningMacro == i then
                        BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
                    end
                    r.ImGui_TableSetColumnIndex(ctx, i * 2 - 1)
                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowSat[i])
                    if I.Name == 'Macro ' .. i then I.Name = 'Env ' .. i end
                    MacroNameEdited, I.Name = r.ImGui_InputText(ctx, '##', I.Name or 'Env ' .. i)
                    if MacroNameEdited then
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name,
                            true)
                    end
                    if (r.ImGui_IsItemClicked(ctx, 1) or RCat or RCrel) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'Env' .. i .. 'Menu')
                    end



                    if AssigningMacro == i then r.ImGui_PopStyleColor(ctx, 2) end

                    if (RCat or RCrel) and not AssigningMacro and Mods == 0 then
                        AssigningMacro = i
                    elseif (RCat or RCrel) and AssigningMacro then
                        AssigningMacro = nil
                    end

                    if LBtnREl then
                        for i = 1, 16, 1 do
                            r.gmem_write(8 + i, 0)
                        end
                    end
                    r.ImGui_PopStyleColor(ctx, clrPop)
                elseif Trk[TrkID].Mod[i].Type == 'Step' then
                    Macros_WDL = Macros_WDL or r.ImGui_GetWindowDrawList(ctx)
                    r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2) --r.ImGui_PushItemWidth( ctx, -FLT_MIN)

                    r.gmem_attach('ParamValues')
                    local CurrentPos       = r.gmem_read(120 + i) + 1

                    --r.ImGui_SetNextItemWidth(ctx, 20)
                    Trk[TrkID].Mod[i].SEQ  = Trk[TrkID].Mod[i].SEQ or {}
                    local S                = Trk[TrkID].Mod[i].SEQ

                    Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
                    Trk[TrkID].SEQ_Dnom    = Trk[TrkID].SEQ_Dnom or {}

                    local HoverOnAnyStep
                    local SmallSEQActive
                    local HdrPosL, HdrPosT = r.ImGui_GetCursorScreenPos(ctx)
                    for St = 1, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do -- create all steps
                        local W = (VP.w - 10) / 12
                        local L, T = r.ImGui_GetCursorScreenPos(ctx)
                        if St == 1 and AssigningMacro == i then
                            local H = 20
                            local W = (VP.w - 10) / 12
                            BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink, L, T, L + W, T + H, H, W)

                            --HighlightSelectedItem(0xffffff77,0xffffff33, 0, L,T,L+W,T+H,H,W, 1, 1,GetItemRect, Foreground)
                        end
                        --_, S[St]= r.ImGui_DragDouble(ctx, '##SEQ '..St ,  S[St], 0 ,0, 1, ' ',r.ImGui_SliderFlags_NoInput())
                        r.ImGui_InvisibleButton(ctx, '##SEQ' .. St .. TrkID, W / 8, 20)
                        local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx); local w, h =
                            r.ImGui_GetItemRectSize(ctx)
                        local FillClr = 0x00000000



                        SEQ_Popup_L = SEQ_Popup_L or L
                        SEQ_Popup_T = SEQ_Popup_T or T

                        if r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) and not r.ImGui_IsMouseDown(ctx, 0) then
                            HoverOnAnyStep = true
                        end
                        if HoverOnAnyStep then WhichMacroIsHovered = i end


                        if r.ImGui_IsItemHovered(ctx) then FillClr = 0xffffff22 end
                        HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1, GetItemRect,
                            Foreground)



                        S[St] = SetMinMax(S[St] or 0, 0, 1)
                        if r.ImGui_IsItemActive(ctx) then
                            local _, v = r.ImGui_GetMouseDelta(ctx, nil, nil)

                            if Mods == Shift then DrgSpdMod = 4 end
                            if v ~= 0 then
                                v = v * (-1)
                                if not (S[St] == 1 and v > 0) and not (S[St] == 0 and v < 0) then
                                    S[St] = S[St] + v / 100
                                    r.gmem_write(4, 7)                                   -- tells jsfx user is changing a step's value
                                    r.gmem_write(5, i)                                   -- tells which macro user is tweaking
                                    r.gmem_write(112, SetMinMax(S[St], 0, 1) * (-1) + 1) -- tells the step's value
                                    r.gmem_write(113, St)                                -- tells which step
                                end
                                r.ImGui_ResetMouseDragDelta(ctx)
                            end
                            SmallSEQActive = true
                        elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                            if AssigningMacro then AssigningMacro = nil else AssigningMacro = i end
                        elseif r.ImGui_IsItemDeactivated(ctx) then
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St ..
                                ' Val', S[St], true)
                        end


                        local W, H = r.ImGui_GetItemRectSize(ctx)
                        local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)
                        if r.ImGui_IsItemActive(ctx) then
                            Clr = EightColors.Bright_HighSat[i]
                        elseif r.ImGui_IsItemHovered(ctx) then
                            Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                        end

                        r.ImGui_DrawList_AddRectFilled(Macros_WDL, L, T + H, L + W - 1, math.max(B - H * (S[St] or 0), T),
                            Clr)
                        if CurrentPos == St then -- if Step SEQ 'playhead' is now on current step
                            r.ImGui_DrawList_AddRect(Macros_WDL, L, T + H, L + W - 1, T, 0xffffff99)
                        end
                        SL(nil, 0)
                        if (r.ImGui_IsItemClicked(ctx, 1)) and Mods == Ctrl then
                            r.ImGui_OpenPopup(ctx, 'Step' .. i .. 'Menu')
                        end
                    end



                    r.ImGui_SetNextWindowPos(ctx, HdrPosL, VP.y - StepSEQ_H - 100)

                    function openSEQWin(Track, i)
                        if not HoveringSmoothness then
                            if r.ImGui_Begin(ctx, 'SEQ Window' .. i, true, r.ImGui_WindowFlags_NoResize() + r.ImGui_WindowFlags_NoDocking() + r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_AlwaysAutoResize()) then
                                local WDL = r.ImGui_GetWindowDrawList(ctx)
                                r.ImGui_Text(ctx, 'Sequence Length : ')
                                local function writeSEQDNom()
                                    if AddMacroJSFX() then
                                        r.gmem_write(4, 8) --[[tells JSFX user is tweaking seq length or DNom]]
                                        r.gmem_write(5, i) --[[tells JSFX the macro]]
                                        r.gmem_write(111, Trk[TrkID].SEQ_Dnom[i])
                                        r.gmem_write(110, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)
                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                            'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                                            Trk[TrkID].SEQ_Dnom[i], true)
                                    end
                                end

                                local function writeSEQGmem()
                                    if AddMacroJSFX() then
                                        r.gmem_write(4, 8)
                                        r.gmem_write(5, i)
                                        r.gmem_write(110, Trk[TrkID].SEQL[i])
                                        r.gmem_write(111, Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom)
                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                            'P_EXT: Macro ' .. i .. ' SEQ Length',
                                            Trk[TrkID].SEQL[i], true)
                                    end
                                end



                                Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
                                rv, Trk[TrkID].SEQL[i] = r.ImGui_SliderInt(ctx, '##' .. 'Macro' .. i .. 'SEQ Length',
                                    Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 2, 64)
                                if r.ImGui_IsItemActive(ctx) then writeSEQGmem() end
                                SL()
                                if r.ImGui_Button(ctx, 'x2##' .. i) then
                                    Trk[TrkID].SEQL[i] = math.floor((Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) * 2)
                                    writeSEQGmem()
                                end
                                SL()
                                if r.ImGui_Button(ctx, '/2##' .. i) then
                                    Trk[TrkID].SEQL[i] = math.floor((Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) / 2)
                                    writeSEQGmem()
                                end

                                r.ImGui_Text(ctx, 'Step Length : ')
                                if r.ImGui_Button(ctx, '2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 0.125
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 0.125 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                        R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                SL()
                                if r.ImGui_Button(ctx, '1 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 0.25
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 0.25 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                        R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                SL()
                                if r.ImGui_Button(ctx, '1/2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 0.5
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 0.5 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                        R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                SL()
                                if r.ImGui_Button(ctx, '1/4 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 1
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 1 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                        B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                SL()
                                if r.ImGui_Button(ctx, '1/8 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 2
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 2 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                        B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                SL()
                                if r.ImGui_Button(ctx, '1/16 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 4
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 4 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                        B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                SL()
                                if r.ImGui_Button(ctx, '1/32 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 8
                                    writeSEQDNom()
                                end
                                SL()
                                if Trk[TrkID].SEQ_Dnom[i] == 8 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                        B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end
                                if r.ImGui_Button(ctx, '1/64 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                    Trk[TrkID].SEQ_Dnom[i] = 16
                                    writeSEQDNom()
                                end
                                if Trk[TrkID].SEQ_Dnom[i] == 16 then
                                    HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                        B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                                end



                                for St = 1, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do
                                    r.ImGui_InvisibleButton(ctx, '##SEQ' .. St .. TrkID, StepSEQ_W, StepSEQ_H)
                                    local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx); local w, h =
                                        r.ImGui_GetItemRectSize(ctx)
                                    r.ImGui_DrawList_AddText(WDL, L + StepSEQ_W / 2 / 2, B - 15, 0x999999ff, St)
                                    SL(nil, 0)
                                    local FillClr = 0x00000000
                                    if IsLBtnHeld and r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) and not SmallSEQActive then
                                        --Calculate Value at Mouse pos
                                        local MsX, MsY = r.ImGui_GetMousePos(ctx)

                                        S[St] = ((B - MsY) / StepSEQ_H) --[[ *(-1) ]]
                                        r.gmem_write(4, 7)                        -- tells jsfx user is changing a step's value
                                        r.gmem_write(5, i)                        -- tells which macro user is tweaking
                                        r.gmem_write(112, SetMinMax(S[St], 0, 1)) -- tells the step's value
                                        r.gmem_write(113, St)                     -- tells which step

                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                            'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', S[St], true)
                                    elseif IsRBtnHeld and r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) and not SmallSEQActive then
                                        SEQ_RMB_Val = 0
                                        S[St] = SEQ_RMB_Val
                                        r.gmem_write(4, 7)             -- tells jsfx user is changing a step's value
                                        r.gmem_write(5, i)             -- tells which macro user is tweaking
                                        r.gmem_write(112, SEQ_RMB_Val) -- tells the step's value
                                        r.gmem_write(113, St)          -- tells which step
                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                            'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', SEQ_RMB_Val, true)
                                    end
                                    local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)

                                    if r.ImGui_IsItemHovered(ctx, r.ImGui_HoveredFlags_RectOnly()) and not SmallSEQActive then
                                        FillClr = 0xffffff22
                                        Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                                    end
                                    HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1,
                                        GetItemRect, Foreground)



                                    r.ImGui_DrawList_AddRectFilled(WDL, L, T + StepSEQ_H, L + StepSEQ_W - 1,
                                        math.max(B - StepSEQ_H * (S[St] or 0), T), Clr)

                                    if CurrentPos == St then
                                        r.ImGui_DrawList_AddRect(WDL, L, B, L + StepSEQ_W - 1, T, 0xffffff88)
                                    end
                                end




                                local x, y = r.ImGui_GetWindowPos(ctx)
                                local w, h = r.ImGui_GetWindowSize(ctx)


                                if r.ImGui_IsMouseHoveringRect(ctx, x, y, x + w, y + h) then notHoverSEQ_Time = 0 end

                                r.ImGui_End(ctx)
                            end
                        end
                    end

                    if WhichMacroIsHovered == i and HoverOnAnyStep or SmallSEQActive then
                        openSEQWin(Track, i)
                        notHoverSEQ_Time = 0
                    end

                    if WhichMacroIsHovered == i and not HoverOnAnyStep and not SmallSEQActive then
                        notHoverSEQ_Time = math.min((notHoverSEQ_Time or 0), 11) + 1
                        if notHoverSEQ_Time < 10 then
                            openSEQWin(Track, i)
                        else
                            WhichMacroIsHovered = nil
                            notHoverSEQ_Time = 0
                        end
                    end
                elseif Trk[TrkID].Mod[i].Type == 'Follower' then
                    r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2)

                    r.ImGui_Button(ctx, 'Follower     ')
                    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'Follower' .. i .. 'Menu')
                    elseif r.ImGui_IsItemClicked(ctx, 1) then
                        if not AssigningMacro then
                            AssigningMacro = i
                        else
                            AssigningMacro = nil
                        end
                    end
                    if AssigningMacro == i then
                        BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
                    end

                    if r.ImGui_IsItemHovered(ctx) then FolMacroHover = i end



                    function openFollowerWin(Track, i)
                        local HoveringSmoothness

                        local HdrPosL, HdrPosT = r.ImGui_GetCursorScreenPos(ctx)

                        r.ImGui_SetNextWindowPos(ctx, HdrPosL, VP.y - 55)
                        r.ImGui_SetNextWindowSize(ctx, 350, 55)
                        if r.ImGui_Begin(ctx, 'Follower Windowww' .. i, true, r.ImGui_WindowFlags_NoResize() + r.ImGui_WindowFlags_NoDocking() + r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_NoTitleBar()) then
                            r.ImGui_Text(ctx, 'Speed : ')
                            SL()
                            local m = Trk[TrkID].Mod[i]
                            local CurX = r.ImGui_GetCursorPosX(ctx)
                            retval, m.Smooth = r.ImGui_DragDouble(ctx, '##Smoothness', m.Smooth or 1, 1, 0, 300,
                                '%.1f')


                            if r.ImGui_IsItemHovered(ctx) or r.ImGui_IsItemActive(ctx) then
                                HoveringSmoothness = i
                            end
                            local x, y = r.ImGui_GetWindowPos(ctx)
                            local w, h = r.ImGui_GetWindowSize(ctx)


                            if r.ImGui_IsMouseHoveringRect(ctx, x, y, x + w, y + h) then
                                notHoverFOL_Time = 0
                                HoveringSmoothness = i
                            end

                            if retval then
                                m.smooth = SetMinMax(0.1 ^ (1 - m.Smooth * 0.01), 0.1, 100)
                                r.gmem_write(4, 10)       ---tells jsfx macro type = Follower, and user is adjusting smoothness
                                r.gmem_write(5, i)        ---tells jsfx which macro
                                r.gmem_write(9, m.smooth) -- Sets the smoothness
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Speed',
                                    m.Smooth,
                                    true)
                            end

                            --r.ImGui_Text(ctx, ('S = ' .. (m.Smooth or '') .. 's= ' .. (m.smooth or '')))
                            r.ImGui_Text(ctx, 'Gain : ')
                            SL(CurX)

                            rv, m.Gain = r.ImGui_DragDouble(ctx, '##Gain' .. i, m.Gain or 100, 1, 0, 400, '%.0f' .. '%%')
                            if r.ImGui_IsItemActive(ctx) then
                                r.gmem_write(4, 11) ---tells jsfx macro type = Follower, and user is adjusting gain
                                r.gmem_write(5, i)
                                r.gmem_write(9, m.Gain / 100)
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Follower Gain',
                                    m.Gain,
                                    true)
                            end

                            if r.ImGui_IsItemHovered(ctx) or r.ImGui_IsItemActive(ctx) then HoveringSmoothness = i end

                            r.ImGui_End(ctx)
                        end


                        return HoveringSmoothness
                    end

                    if HoveringSmoothness == i then
                        HoveringSmoothness = openFollowerWin(Track, i)
                    end

                    if FolMacroHover == i and not HoveringSmoothness then
                        local timeout = 20
                        notHoverFOL_Time = math.min((notHoverFOL_Time or 0), timeout + 1) + 1
                        if notHoverFOL_Time < timeout then
                            HoveringSmoothness = openFollowerWin(Track, i)
                        else
                            HoveringSmoothness = openFollowerWin(Track, i)
                            FolMacroHover = nil
                            notHoverFOL_Time = 0
                        end
                    end
                elseif Trk[TrkID].Mod[i].Type == 'LFO' then
                    local function ChangeLFO(mode, V, gmem)
                        r.gmem_write(4, mode) -- tells jsfx user is adjusting LFO Freq
                        r.gmem_write(5, i)    -- Tells jsfx which macro
                        r.gmem_write(gmem or 9, V)
                    end
                    local H = 20
                    local Mc = Trk[TrkID].Mod[i]
                    Mc.Freq = Mc.Freq or 1
                    Mc.Gain = Mc.Gain or 5
                    r.ImGui_TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
                    --[[  IsMacroSlidersEdited, I.Val = r.ImGui_SliderDouble(ctx, i .. '##LFO', I.Val, Slider1Min or 0,
                    Slider1Max or 1) ]]
                    local W = (VP.w - 10) / 12
                    local rv = r.ImGui_InvisibleButton(ctx, 'LFO Button' .. i, W, H)
                    local w, h = r.ImGui_GetItemRectSize(ctx)
                    local L, T = r.ImGui_GetItemRectMin(ctx)
                    local WDL = r.ImGui_GetWindowDrawList(ctx)
                    r.ImGui_DrawList_AddRect(WDL, L, T, L + w, T + h, EightColors.LFO[i])
                    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'LFO' .. i .. 'Menu')
                    end
                    local Y_Mid = T + H / 2
                    local G = 1
                    local HdrPosL, HdrPosT = r.ImGui_GetCursorScreenPos(ctx)

                    if rv and not LFO_DragDir and Mods == 0 then
                        r.ImGui_OpenPopup(ctx, 'LFO Shape Select')


                        r.ImGui_SetNextWindowPos(ctx, HdrPosL, VP.y - 320)
                        r.ImGui_SetNextWindowSizeConstraints(ctx, LFOwin.w, LFOwin.h, 1300, LFOwin.h)
                    end
                    if r.ImGui_BeginPopup(ctx, 'LFO Shape Select', r.ImGui_WindowFlags_NoMove()) then
                        LFO_Ctrl = LFO_Ctrl or { x = {}, y = {} }
                        LFO_Nodes = LFO_Nodes or { x = {}, y = {} }
                        r.ImGui_Dummy(ctx, LFOwin.w + 30, LFOwin.h + 20)
                        local Win_T, Win_B = VP.y - 320, VP.y - 23
                        local NodeSz = 15

                        local w, h = r.ImGui_GetItemRectSize(ctx)
                        local L, T = r.ImGui_GetItemRectMin(ctx)
                        local LineClr, CtClr = 0xffffff99, 0xffffff44
                        local function GetNormV(i)
                            local NormX = (LFO_Nodes.x[i] - HdrPosL) / LFOwin.w
                            local NormY = (Win_B - LFO_Nodes.y[i]) / (LFOwin.h - 3) -- i think 3 is the window padding
                            return NormX, NormY
                        end

                        if not r.ImGui_IsAnyItemHovered(ctx) and LBtnDC then
                            local x, y = r.ImGui_GetMousePos(ctx)
                            local InsertPos
                            for i = 1, #LFO_Nodes.x, 1 do
                                if i ~= #LFO_Nodes.x then
                                    if LFO_Nodes.x[i] < x and LFO_Nodes.x[i + 1] > x then InsertPos = i + 1 end
                                else
                                    if LFO_Nodes.x[i] < x then InsertPos = i + 1 end
                                end
                            end

                            table.insert(LFO_Nodes.x, InsertPos, SetMinMax(x, HdrPosL, HdrPosL + LFOwin.w))
                            table.insert(LFO_Nodes.y, InsertPos, SetMinMax(y, Win_T, Win_B))
                            local NormX, NormY = GetNormV(InsertPos)
                        end


                        local function AddNode(x, y, ID)
                            local w, h = 15, 15
                            InvisiBtn(ctx, x, y, '##Node' .. ID, 15)
                            local Hvred
                            local w, h = r.ImGui_GetItemRectSize(ctx)
                            local L, T = r.ImGui_GetItemRectMin(ctx)

                            if r.ImGui_IsItemHovered(ctx) then
                                LineClr, CtClr = 0xffffffbb, 0xffffff88
                                HoverNode = ID
                                Hvred = true
                            end


                            if r.ImGui_IsItemActive(ctx) then
                                HoverNode = ID
                                local MsX, MsY = r.ImGui_GetMouseDragDelta(ctx)
                                LFO_Nodes.x[ID] = SetMinMax(LFO_Nodes.x[ID] + MsX, HdrPosL, HdrPosL + 400)
                                LFO_Nodes.y[ID] = SetMinMax(LFO_Nodes.y[ID] + MsY, Win_T, Win_B)



                                if LFO_Ctrl.x[ID] then
                                    local lastX = LFO_Nodes.x[ID - 1]
                                    local lastY, Y = LFO_Nodes.y[ID - 1], LFO_Nodes.y[ID]


                                    LFO_Ctrl.x[ID] = SetMinMax(LFO_Ctrl.x[ID], lastX, LFO_Nodes.x[ID])
                                    LFO_Ctrl.y[ID] = SetMinMax(LFO_Ctrl.y[ID], math.min(lastY, Y), math.max(lastY, Y))
                                end


                                local NormX, NormY = GetNormV(ID)
                                ChangeLFO(13, NormX, 9)
                                ChangeLFO(13, NormY, 10)
                                ChangeLFO(13, ID, 11)







                                if ID ~= #LFO_Nodes.x then
                                    local this, next = LFO_Nodes.x[ID], LFO_Nodes.x[ID + 1]
                                    LFO_Ctrl.x[ID + 1] = SetMinMax(LFO_Ctrl.x[ID + 1] or (this + next) / 2, this, next)
                                    if LFO_Ctrl.x[ID + 1] == (this + next) / 2 then LFO_Ctrl.x[ID + 1] = nil end
                                end

                                r.ImGui_ResetMouseDragDelta(ctx)
                            end


                            r.ImGui_DrawList_AddCircle(WDL, L + NodeSz / 2, T + NodeSz / 2, 5, LineClr)
                            r.ImGui_DrawList_AddCircleFilled(WDL, L + NodeSz / 2, T + NodeSz / 2, 3, CtClr)
                            return Hvred
                        end

                        if not LFO_Nodes.x[1] then
                            table.insert(LFO_Nodes.x, L)
                            table.insert(LFO_Nodes.x, L + 400)
                            table.insert(LFO_Nodes.y, T + h / 2)
                            table.insert(LFO_Nodes.y, T + h / 2)
                        end


                        FDL = r.ImGui_GetForegroundDrawList(ctx)
                        table.sort(LFO_Nodes.x, function(k1, k2) return k1 < k2 end)
                        local AnyNodeHovered
                        for i, v in ipairs(LFO_Nodes.x) do
                            local lastX, lastY = LFO_Nodes.x[i - 1] or 0, LFO_Nodes.y[i - 1] or LFO_Nodes.y[i]
                            local Y = LFO_Nodes.y[i]
                            if AddNode(v, Y, i) then AnyNodeHovered = true end
                            local CtrlX, CtrlY = LFO_Ctrl.x[i] or (lastX + v) / 2, LFO_Ctrl.y[i] or (lastY + Y) / 2


                            -- Control Node
                            if (r.ImGui_IsMouseHoveringRect(ctx, lastX, Win_T, v, Win_B) or DraggingLFOctrl == i) then
                                local Sz = 6
                                ---- Draw Node
                                if not DraggingLFOctrl or DraggingLFOctrl == i then
                                    if not HoverNode then
                                        r.ImGui_DrawList_AddBezierQuadratic(FDL, lastX, lastY, CtrlX, CtrlY, v, Y,
                                            0xffffff44, 7)
                                        r.ImGui_DrawList_AddCircle(FDL, CtrlX, CtrlY, Sz, LineClr)
                                        --r.ImGui_DrawList_AddText(FDL, CtrlX, CtrlY, 0xffffffff, i)
                                    end
                                end

                                InvisiBtn(ctx, CtrlX - Sz / 2, CtrlY - Sz / 2, '##Ctrl Node' .. i, Sz)
                                if r.ImGui_IsItemActive(ctx) then
                                    DraggingLFOctrl = i
                                    local Dx, Dy    = r.ImGui_GetMouseDelta(ctx)

                                    LFO_Ctrl.x[i]   = SetMinMax(CtrlX + Dx, lastX, v)

                                    LFO_Ctrl.y[i]   = SetMinMax(CtrlY + Dy, math.min(lastY, Y), math.max(lastY, Y))
                                elseif r.ImGui_IsItemHovered(ctx) then
                                    r.ImGui_DrawList_AddCircle(FDL, CtrlX, CtrlY, Sz + 2, LineClr)
                                end
                            end

                            r.ImGui_DrawList_AddBezierQuadratic(FDL, lastX, lastY, CtrlX, CtrlY, v, Y, 0xffffffff, 3)
                        end
                        if not AnyNodeHovered then HoverNode = nil end


                        --r.ImGui_DrawList_PathStroke(FDL, 0xffffffff, nil, 2)

                        if LBtnRel then DraggingLFOctrl = nil end



                        r.ImGui_EndPopup(ctx)
                    end


                    if r.ImGui_IsItemActive(ctx) then
                        if not LFO_MsX_Start then LFO_MsX_Start, LFO_MsY_Start = r.GetMousePosition() end
                        LFO_MsX_Now, LFO_MsY_Now = r.GetMousePosition()
                        local thresh = 10
                        local DragX, DragY = LFO_MsX_Start - LFO_MsX_Now, LFO_MsY_Start - LFO_MsY_Now

                        if not LFO_DragDir then
                            if DragX > thresh or DragX < -thresh then
                                LFO_DragDir = 'H'
                            elseif DragY > thresh or DragY < -thresh then
                                LFO_DragDir = 'V'
                            end
                        end
                        local Dx, Dy = r.ImGui_GetMouseDelta(ctx)
                        local DragSpd = 0.1
                        if LFO_DragDir == 'H' then
                            Mc.Freq = SetMinMax(Mc.Freq + (Dx * DragSpd), 0.1, 20)
                            local ActualFreq = Mc.Freq * 100
                            ChangeLFO(13, ActualFreq)
                        elseif LFO_DragDir == 'V' then
                            Mc.Gain = SetMinMax(Mc.Gain - (Dy * DragSpd), 0, 6)
                            local ActualGain = Mc.Gain / 6
                            ttp(ActualGain)
                            ChangeLFO(14, ActualGain)
                        end
                    end




                    if not IsLBtnHeld then
                        LFO_DragDir = nil
                        LFO_MsX_Start, LFO_MsY_Start = nil
                    end

                    local MOD = math.abs(SetMinMax(r.gmem_read(100 + i) / 127, -1, 1)) * Mc.Gain * 4
                    Mc.StepV = Mc.StepV or {}


                    table.insert(Mc.StepV, MOD)

                    if #Mc.StepV > W then
                        table.remove(Mc.StepV, 1)
                    end
                    for s = 0, W, G do
                        local last = SetMinMax(s - 1, 0, W)
                        r.ImGui_DrawList_AddLine(WDL, L + s, T + H - (Mc.StepV[last] or 0), L + s + G,
                            T + H - (Mc.StepV[s] or 0), EightColors.LFO[i], 2)

                        --r.ImGui_DrawList_PathLineTo(WDL, L+s,  Y_Mid+math.sin(s/Mc.Freq) * Mc.Gain)
                    end
                    --r.ImGui_DrawList_PathStroke(WDL, EightColors.LFO[i] , nil, 2)
                end




                --check if there's envelope
                --[[  IsThereEnvOnMacro[i] = r.GetFXEnvelope(LT_Track, 0, i-1, false)
                    Str_IsThereEnvOnMacro = tostring(IsThereEnvOnMacro[i])
                    if Str_IsThereEnvOnMacro ~= 'nil'  then     --if theres env on macros, Sync Macro on Gui to Actual Values

                        Mc.Val_Trk[MacroValueLBL]= r.TrackFX_GetParamNormalized( LT_Track, 0, i-1  )
                        PosX_Left, PosY_Top = r.ImGui_GetItemRectMin(ctx)
                        Array_Parameter.PosX_Left[i]=PosX_Left
                        Array_Parameter.PosY_Top[i]=PosY_Top
                        drawlist=r.ImGui_GetForegroundDrawList(ctx)
                        MacroColor= 'Macro'..i..'Color'
                        r.ImGui_DrawList_AddCircleFilled(drawlist, Array_Parameter.PosX_Left[i], Array_Parameter.PosY_Top[i],4,_G[MacroColor])
                    else IsThereEnvOnMacro[i]=0
                    end ]]
                local function SetTypeToEnv()
                    if r.ImGui_Selectable(ctx, 'Set Type to Envelope', false) then
                        Trk[TrkID].Mod[i].Type = 'env'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'env', true)
                        r.gmem_write(4, 4) -- tells jsfx macro type = env
                        r.gmem_write(5, i) -- tells jsfx which macro
                    end
                end

                local function SetTypeToStepSEQ()
                    if r.ImGui_Selectable(ctx, 'Set Type to Step Sequencer', false) then
                        Trk[TrkID].Mod[i].Type = 'Step'
                        r.gmem_write(4, 6) -- tells jsfx macro type = step seq
                        r.gmem_write(5, i)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Step', true)
                        Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
                        Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
                        Trk[TrkID].SEQL[i] = Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
                        Trk[TrkID].SEQ_Dnom[i] = Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom

                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length',
                            Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, true)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                            Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom, true)

                        if I.Name == 'Env ' .. i or I.Name == 'Macro ' .. i then I.Name = 'Step ' .. i end
                    end
                end

                local function SetTypeToFollower()
                    if r.ImGui_Selectable(ctx, 'Set Type to Audio Follower', false) then
                        r.gmem_write(4, 9) -- tells jsfx macro type = Follower
                        r.gmem_write(5, i) -- tells jsfx which macro
                        Trk[TrkID].Mod[i].Type = 'Follower'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Follower', true)
                    end
                end
                local function SetTypeToMacro()
                    if r.ImGui_Selectable(ctx, 'Set Type to Macro', false) then
                        Trk[TrkID].Mod[i].Type = 'Macro'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Macro', true)
                        r.gmem_write(4, 5) -- tells jsfx macro type = Macro
                        r.gmem_write(5, i) -- tells jsfx which macro
                        if I.Name == 'Env ' .. i then I.Name = 'Macro ' .. i end
                    end
                end
                local function SetTypeToLFO()
                    if r.ImGui_Selectable(ctx, 'Set Type to LFO', false) then
                        Trk[TrkID].Mod[i].Type = 'LFO'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'LFO', true)
                        r.gmem_write(4, 12) -- tells jsfx macro type = LFO
                        r.gmem_write(5, i)  -- tells jsfx which macro
                        I.Name = 'LFO ' .. i
                    end
                end

                if r.ImGui_BeginPopup(ctx, 'Macro' .. i .. 'Menu') then
                    if r.ImGui_Selectable(ctx, 'Automate', false) then
                        AddMacroJSFX()
                        -- Show Envelope for Morph Slider
                        local env = r.GetFXEnvelope(LT_Track, 0, i - 1, true)
                        SetPrmAlias(LT_TrackNum, 1, i, Trk[TrkID].Mod[i].Name or ('Macro' .. i)) --don't know what this line does, but without it Envelope won't show....
                        local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, Tp, faderScaling =
                            r.BR_EnvGetProperties(env)
                        r.BR_EnvSetProperties(env, true, true, armed, inLane, laneHeight, defaultShape, faderScaling)
                        r.UpdateArrange()
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                    SetTypeToEnv()
                    SetTypeToStepSEQ()
                    SetTypeToFollower()
                    SetTypeToLFO()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'Env' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToStepSEQ()
                    SetTypeToFollower()
                    SetTypeToLFO()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'Step' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToEnv()
                    SetTypeToFollower()
                    SetTypeToLFO()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'Follower' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToEnv()
                    SetTypeToStepSEQ()
                    SetTypeToLFO()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'LFO' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToEnv()
                    SetTypeToStepSEQ()
                    SetTypeToFollower()
                    r.ImGui_EndPopup(ctx)
                end


                r.ImGui_PopID(ctx)
            end

            if not FX_Dvs_BgDL then FX_Dvs_BgDL = r.ImGui_GetWindowDrawList(ctx) end
            r.ImGui_PopStyleColor(ctx, 1)
            r.ImGui_EndTable(ctx)
            ---------------End Of header-----------------------


            if ImGUI_Time > 3 then
                CompareFXCount = r.TrackFX_GetCount(LT_Track);
                ImGUI_Time = 0
            end

            if not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopup()) then
                FX_Idx_OpenedPopup = nil
            end



            --------------==  Space between FXs--------------------
            function AddSpaceBtwnFXs(FX_Idx, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container,
                                     AdditionalWidth)
                local SpcIsInPre, Hide, SpcInPost, MoveTarget


                if FX_Idx == 0 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx = 1 end
                --if FX_Idx == 1 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx=FX_Idx-1 else FX_Idx =FX_Idx end
                TblIdxForSpace = FX_Idx .. tostring(SpaceIsBeforeRackMixer)
                FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                if Trk[TrkID].PreFX[1] then
                    local offset
                    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 1 else offset = 0 end
                    if SpaceIsBeforeRackMixer == 'End of PreFX' then
                        SpcIsInPre = true
                        if Trk[TrkID].PreFX_Hide then Hide = true end
                        MoveTarget = FX_Idx + 1
                    elseif FX_Idx + 1 - offset <= #Trk[TrkID].PreFX and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
                        SpcIsInPre = true; if Trk[TrkID].PreFX_Hide then Hide = true end
                    end
                end
                if SpaceIsBeforeRackMixer == 'SpcInPost' or SpaceIsBeforeRackMixer == 'SpcInPost 1st spc' then
                    SpcInPost = true
                    if PostFX_LastSpc == 30 then Dvdr.Spc_Hover[TblIdxForSpace] = 30 end
                end
                local ClrLbl = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')


                Dvdr.Clr[ClrLbl] = Space_Between_FXs
                Dvdr.Width[TblIdxForSpace] = Dvdr.Width[TblIdxForSpace] or 0
                if FX_Idx == 0 and DragDroppingFX and not SpcIsInPre then
                    if r.ImGui_IsMouseHoveringRect(ctx, Cx_LeftEdge + 10, Cy_BeforeFXdevices, Cx_LeftEdge + 25, Cy_BeforeFXdevices + 220) and DragFX_ID ~= 0 then
                        Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                    end
                end

                if FX_Idx == RepeatTimeForWindows then
                    Dvdr.Width[TblIdxForSpace] = 15
                end

                if FX_Idx_OpenedPopup == (FX_Idx or 0) .. (tostring(SpaceIsBeforeRackMixer) or '') then
                    Dvdr.Clr[ClrLbl] = Clr.Dvdr.Active
                else
                    Dvdr.Clr[ClrLbl] = Dvdr.Clr[ClrLbl] or Clr.Dvdr.In_Layer
                end

                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), Dvdr.Clr[ClrLbl])

                -- StyleColor For Space Btwn Fx Windows
                if not Hide then
                    if r.ImGui_BeginChildFrame(ctx, '##SpaceBetweenWindows' .. FX_Idx .. tostring(SpaceIsBeforeRackMixer) .. 'Last SPC in Rack = ' .. tostring(AddLastSPCinRack), 10 + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0) + (AdditionalWidth or 0), 220, r.ImGui_WindowFlags_NoScrollbar()|r.ImGui_WindowFlags_NoScrollWithMouse()|r.ImGui_WindowFlags_NoNavFocus()|r.ImGui_WindowFlags_NoNav()) then
                        --HOVER_RECT = r.ImGui_IsWindowHovered(ctx,  r.ImGui_HoveredFlags_RectOnly())
                        HoverOnWindow = r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_AllowWhenBlockedByActiveItem())

                        if HoverOnWindow == true and Dragging_TrueUntilMouseUp ~= true and DragDroppingFX ~= true and AssignWhichParam == nil and Is_ParamSliders_Active ~= true and Wet.ActiveAny ~= true and Knob_Active ~= true and not Dvdr.JustDroppedFX and LBtn_MousdDownDuration < 0.2 then
                            Dvdr.Spc_Hover[TblIdxForSpace] = Df.Dvdr_Hvr_W
                            if DebugMode then
                                tooltip('FX_Idx :' ..
                                    FX_Idx ..
                                    '\n Pre/Post/Norm : ' ..
                                    tostring(SpaceIsBeforeRackMixer) .. '\n SpcIDinPost: ' .. tostring(SpcIDinPost))
                            end
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), CLR_BtwnFXs_Btn_Hover)
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), CLR_BtwnFXs_Btn_Active)
                            local x, y = r.ImGui_GetCursorScreenPos(ctx)
                            r.ImGui_SetCursorScreenPos(ctx, x, Glob.WinT)
                            BTN_Btwn_FXWindows = r.ImGui_Button(ctx, '##Button between Windows', 99, 217)
                            FX_Insert_Pos = FX_Idx

                            if BTN_Btwn_FXWindows then
                                FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')

                                r.ImGui_OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx)
                            end
                            r.ImGui_PopStyleColor(ctx, 2)
                            Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                        else
                            Dvdr.RestoreNormWidthWait[FX_Idx] = (Dvdr.RestoreNormWidthWait[FX_Idx] or 0) + 1
                            if Dvdr.RestoreNormWidthWait[FX_Idx] >= 8 then
                                Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                                Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                            end
                        end



                        if HoverOnWindow then
                            -- tooltip ('fx idx = ' .. tostring (FX_Idx) .. 'space is before mixer- '.. tostring (SpaceIsBeforeRackMixer).. 'AddLastSPCinRack - '.. tostring(AddLastSPCinRack))
                        end

                        if r.ImGui_BeginPopup(ctx, 'Btwn FX Windows' .. FX_Idx) then
                            FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')

                            if FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost,
                                    SpcIDinPost) then
                                r.ImGui_CloseCurrentPopup(ctx)
                            end -- Add FX Window
                            if r.ImGui_BeginMenu(ctx, 'FX Browser') then
                                for i = 1, #CAT do
                                    if r.ImGui_BeginMenu(ctx, CAT[i].name) then
                                        if CAT[i].name == "FX CHAINS" then
                                            DrawChildMenu(CAT[i].list, nil, FX_Idx)
                                        end
                                        for j = 1, #CAT[i].list do
                                            if CAT[i].name ~= "FX CHAINS" then
                                                if r.ImGui_BeginMenu(ctx, CAT[i].list[j].name) then
                                                    for p = 1, #CAT[i].list[j].fx do
                                                        if CAT[i].list[j].fx[p] then
                                                            if r.ImGui_Selectable(ctx, CAT[i].list[j].fx[p], false) then
                                                                if TRACK then
                                                                    r.TrackFX_AddByName(TRACK, CAT[i].list[j].fx[p],
                                                                        false,
                                                                        -1000 - FX_Idx)
                                                                    LAST_USED_FX = CAT[i].list[j].fx[p]
                                                                end
                                                            end
                                                        end
                                                    end
                                                    r.ImGui_EndMenu(ctx)
                                                end
                                            end
                                        end
                                        r.ImGui_EndMenu(ctx)
                                    end
                                end
                                TRACK = r.GetSelectedTrack(0, 0)
                                if r.ImGui_Selectable(ctx, "CONTAINER", false) then
                                    r.TrackFX_AddByName(TRACK, "Container", false,
                                        -1000 - r.TrackFX_GetCount(TRACK))
                                    LAST_USED_FX = "Container"
                                end
                                if r.ImGui_Selectable(ctx, "VIDEO PROCESSOR", false) then
                                    r.TrackFX_AddByName(TRACK, "Video processor", false,
                                        -1000 - r.TrackFX_GetCount(TRACK))
                                    LAST_USED_FX = "Video processor"
                                end
                                if LAST_USED_FX then
                                    if r.ImGui_Selectable(ctx, "RECENT: " .. LAST_USED_FX, false) then
                                        r.TrackFX_AddByName(TRACK, LAST_USED_FX, false,
                                            -1000 - r.TrackFX_GetCount(TRACK))
                                    end
                                end
                                r.ImGui_EndMenu(ctx)
                            end
                            if r.ImGui_Selectable(ctx, 'Add FX Layering', false) then
                                local FX_Idx = FX_Idx
                                --[[ if FX_Name:find('Pro%-C 2') then FX_Idx = FX_Idx-1 end ]]
                                local val = r.SNM_GetIntConfigVar("fxfloat_focus", 0)
                                if val & 4 ~= 0 then
                                    r.SNM_SetIntConfigVar("fxfloat_focus", val & (~4))
                                end

                                if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 16 then
                                    r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 16)
                                end
                                FXRack = r.TrackFX_AddByName(LT_Track, 'FXD (Mix)RackMixer', 0, -1000 - FX_Idx)
                                local RackFXGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                                ChanSplitr = r.TrackFX_AddByName(LT_Track, 'FXD Split to 32 Channels', 0,
                                    -1000 - FX_Idx)
                                local SplitrGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                                Lyr.SplitrAttachTo[SplitrGUID] = RackFXGUID
                                r.SetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. SplitrGUID, RackFXGUID)
                                _, ChanSplitFXName = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)

                                FX[RackFXGUID] = FX[RackFXGUID] or {}
                                FX[RackFXGUID].LyrID = FX[RackFXGUID].LyrID or {}
                                table.insert(FX[RackFXGUID].LyrID, 1)
                                table.insert(FX[RackFXGUID].LyrID, 2)

                                r.SetProjExtState(0, 'FX Devices', 'FX' .. RackFXGUID .. 'Layer ID 1', 1)
                                r.SetProjExtState(0, 'FX Devices', 'FX' .. RackFXGUID .. 'Layer ID 2', 2)
                                FX[RackFXGUID].ActiveLyrCount = 2

                                FX_Layr_Inst = 0
                                for F = 0, Sel_Track_FX_Count, 1 do
                                    local FXGUID = r.TrackFX_GetFXGUID(LT_Track, F)
                                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, F)
                                    if string.find(FX_Name, 'FXD Split to 32 Channels') ~= nil then
                                        FX_Layr_Inst                       = FX_Layr_Inst + 1
                                        Lyr.SpltrID[FX_Layr_Inst .. TrkID] = r.TrackFX_GetFXGUID(LT_Track,
                                            FX_Idx - 1)
                                    end
                                end

                                Spltr[SplitrGUID] = Spltr[SplitrGUID] or {}
                                Spltr[SplitrGUID].New = true


                                if FX_Layr_Inst == 1 then
                                    --sets input channels to 1 and 2
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 0, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 1, 2, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 2, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 3, 2, 0)
                                    for i = 2, 16, 1 do
                                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, i, 0, 0)
                                    end
                                    --sets Output to all channels
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, 0, 21845, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, 1, 43690, 0)
                                    for i = 2, 16, 1 do
                                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, i, 0, 0)
                                    end
                                elseif FX_Layr_Inst > 1 then

                                end




                                FX_Idx_OpenedPopup = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                                if val & 4 ~= 0 then
                                    r.SNM_SetIntConfigVar("fxfloat_focus", val|4) -- re-enable Auto-float
                                end
                            elseif r.ImGui_Selectable(ctx, 'Add Band Split', false) then
                                r.gmem_attach('FXD_BandSplit')
                                table.insert(AddFX.Name, 'FXD Saike BandSplitter')
                                table.insert(AddFX.Pos, FX_Idx)
                                table.insert(AddFX.Name, 'FXD Band Joiner')
                                table.insert(AddFX.Pos, FX_Idx + 1)
                                if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 12 then -- Set track channels to 10 if it's lower than 10
                                    r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 12)
                                end

                                FX_Idx_OpenedPopup = nil
                                --r.TrackFX_AddByName(LT_Track, 'FXD Bandjoiner', 0, -1000-FX_Idx)
                            end


                            Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                            --Dvdr.Clr[ClrLbl] = 0x999999ff

                            if IsLBtnClicked then FX_Idx_OpenedPopup = nil end
                            if CloseAddFX_Popup then
                                r.ImGui_CloseCurrentPopup(ctx)
                                CloseAddFX_Popup = nil
                            end
                            r.ImGui_EndPopup(ctx)
                        else
                            Dvdr.Clr[ClrLbl] = 0x131313ff
                        end


                        r.ImGui_EndChildFrame(ctx)
                    end
                end
                r.ImGui_PopStyleColor(ctx)
                local FXGUID_FX_Idx = r.TrackFX_GetFXGUID(LT_Track, FX_Idx - 1)

                function MoveFX(DragFX_ID, FX_Idx, isMove, AddLastSpace)
                    local AltDest, AltDestLow, AltDestHigh, DontMove

                    if SpcInPost then SpcIsInPre = false end

                    if SpcIsInPre then
                        if not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then -- if fx is not in pre fx
                            if SpaceIsBeforeRackMixer == 'End of PreFX' then
                                local offset = 0
                                if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = -1 end

                                table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FXGUID[DragFX_ID])
                                --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Idx + 1, true)
                                DontMove = true
                            else
                                table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FXGUID[DragFX_ID])
                            end
                        else -- if fx is in pre fx
                            local offset = 0
                            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = -1 end
                            if FX_Idx < DragFX_ID then -- if drag towards left
                                table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                                table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FXGUID[DragFX_ID])
                            elseif SpaceIsBeforeRackMixer == 'End of PreFX' then
                                table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FXGUID[DragFX_ID])
                                table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                                --move fx down
                            else
                                table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FXGUID[DragFX_ID])
                                table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                            end
                        end

                        for i, v in pairs(Trk[TrkID].PreFX) do
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' ..
                                i, v, true)
                        end
                        if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                            table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                        end
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                    elseif SpcInPost then
                        local offset

                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end

                        if not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then -- if fx is not yet in post-fx chain
                            InsertToPost_Src = DragFX_ID + offset + 1

                            InsertToPost_Dest = SpcIDinPost


                            if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                                table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                            end
                        else                                -- if fx is already in post-fx chain
                            local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                            if SpcIDinPost <= IDinPost then -- if drag towards left
                                table.remove(Trk[TrkID].PostFX, IDinPost)
                                table.insert(Trk[TrkID].PostFX, SpcIDinPost, FXGUID[DragFX_ID])
                                table.insert(MovFX.ToPos, FX_Idx + 1)
                            else
                                table.insert(Trk[TrkID].PostFX, SpcIDinPost, Trk[TrkID].PostFX[IDinPost])
                                table.remove(Trk[TrkID].PostFX, IDinPost)
                                table.insert(MovFX.ToPos, FX_Idx)
                            end
                            DontMove = true
                            table.insert(MovFX.FromPos, DragFX_ID)
                        end
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                    else -- if space is not in pre or post
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. DragFX_ID, '', true)
                        if not MoveFromPostToNorm then
                            if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                                table.remove(Trk[TrkID].PreFX,
                                    tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                            end
                        end
                        if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                            table.remove(Trk[TrkID].PostFX,
                                tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                        end
                    end
                    for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                            true)
                    end
                    for i = 1, #Trk[TrkID].PreFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '',
                            true)
                    end
                    if not DontMove then
                        if FX_Idx ~= RepeatTimeForWindows and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
                            --[[ if ((FX.Win_Name_S[FX_Idx]or''):find('Pro%-Q 3') or (FX.Win_Name_S[FX_Idx]or''):find('Pro%-C 2')) and not tablefind (Trk[TrkID].PreFX, FXGUID[FX_Idx]) then
                                AltDestLow = FX_Idx-1
                            end ]]
                            if (FX.Win_Name_S[FX_Idx] or ''):find('Pro%-C 2') then
                                AltDestHigh = FX_Idx - 1
                            end
                            FX_Idx = tonumber(FX_Idx)
                            DragFX_ID = tonumber(DragFX_ID)

                            if FX_Idx > DragFX_ID then offset = 1 end


                            table.insert(MovFX.ToPos, AltDestLow or FX_Idx - (offset or 0))
                            table.insert(MovFX.FromPos, DragFX_ID)
                        elseif FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' or SpaceIsBeforeRackMixer == 'End of PreFX' then
                            local offset

                            if Trk[TrkID].PostFX[1] then offset = #Trk[TrkID].PostFX end
                            table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
                            table.insert(MovFX.FromPos, DragFX_ID)
                        else
                            table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
                            table.insert(MovFX.FromPos, DragFX_ID)
                        end
                    end
                    if isMove == false then
                        NeedCopyFX = true
                        DropPos = FX_Idx
                    end
                end

                function MoveFXwith1PreFXand1PosFX(DragFX_ID, FX_Idx, Undo_Lbl)
                    r.Undo_BeginBlock()
                    table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                    for i = 1, #Trk[TrkID].PreFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '',
                            true)
                    end
                    table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                    for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                            true)
                    end
                    if FX_Idx ~= RepeatTimeForWindows then
                        if DragFX_ID > FX_Idx then
                            table.insert(MovFX.FromPos, DragFX_ID)
                            table.insert(MovFX.ToPos, FX_Idx)
                            table.insert(MovFX.FromPos, DragFX_ID)
                            table.insert(MovFX.ToPos, FX_Idx)
                            table.insert(MovFX.FromPos, DragFX_ID + 1)
                            table.insert(MovFX.ToPos, FX_Idx + 2)


                            --[[ r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx, true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx, true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID+1, LT_Track, FX_Idx+2, true ) ]]
                        elseif FX_Idx > DragFX_ID then
                            table.insert(MovFX.FromPos, DragFX_ID)
                            table.insert(MovFX.ToPos, FX_Idx - 1)
                            table.insert(MovFX.FromPos, DragFX_ID - 1)
                            table.insert(MovFX.ToPos, FX_Idx - 2)
                            table.insert(MovFX.FromPos, DragFX_ID - 1)
                            table.insert(MovFX.ToPos, FX_Idx - 1)

                            --[[ r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx-1 , true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID-1, LT_Track, FX_Idx-2 , true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID-1, LT_Track, FX_Idx-1 , true ) ]]
                        end
                    else
                        if AddLastSpace == 'LastSpc' then
                            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Idx, true)
                            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID - 1, LT_Track, FX_Idx - 2, true)
                        end
                    end
                    r.Undo_EndBlock(Undo_Lbl, 0)
                end

                function MoveFXwith1PreFX(DragFX_ID, FX_Idx, Undo_Lbl)
                    r.Undo_BeginBlock()
                    if FX_Idx ~= RepeatTimeForWindows then
                        if payload > FX_Idx then
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                        elseif FX_Idx > payload then
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx - 1, true)
                            r.TrackFX_CopyToTrack(LT_Track, payload - 1, LT_Track, FX_Idx - 2, true)
                        end
                    else
                        if AddLastSpace == 'LastSpc' then
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                            r.TrackFX_CopyToTrack(LT_Track, payload - 1, LT_Track, FX_Idx - 2, true)
                        end
                    end
                    r.Undo_EndBlock(Undo_Lbl, 0)
                end

                ---  if the space is in FX layer
                if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID_RackMixer and SpaceIsBeforeRackMixer == false or AddLastSPCinRack == true then
                    Dvdr.Clr[ClrLbl] = Clr.Dvdr.In_Layer
                    FXGUID_of_DraggingFX = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID or 0)

                    if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
                        Dvdr.Width[TblIdxForSpace] = 0
                    else
                        if r.ImGui_BeginDragDropTarget(ctx) then
                            FxDroppingTo = FX_Idx
                            ----- Drag Drop FX -------
                            dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                            if FxGUID == FXGUID[DragFX_ID] then
                                Dvdr.Width[TblIdxForSpace] = 0
                            else
                                Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                            end

                            r.ImGui_SameLine(ctx, 100, 10)


                            if dropped and Mods == 0 then
                                DropFXtoLayer(FX_Idx, LyrID)
                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil
                            elseif dropped and Mods == Apl then
                                DragFX_Src = DragFX_ID

                                if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                                DropToLyrID = LyrID
                                DroptoRack = FXGUID_RackMixer
                                --MoveFX(DragFX_Src, DragFX_Dest ,false )

                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil
                            end
                            ----------- Add FX ---------------
                            if Payload_Type == 'AddFX_Sexan' then
                                AddFX_Sexan(nil, ClrLbl)
                            end

                            r.ImGui_EndDragDropTarget(ctx)
                        else
                            Dvdr.Width[TblIdxForSpace] = 0
                            FxDroppingTo = nil
                        end
                    end
                    r.ImGui_SameLine(ctx, 100, 10)
                elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
                    if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
                        Dvdr.Width[TblIdxForSpace] = 0
                    else
                        if r.ImGui_BeginDragDropTarget(ctx) then
                            FxDroppingTo = FX_Idx
                            dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                            if FxGUID == FXGUID[DragFX_ID] then
                                Dvdr.Width[TblIdxForSpace] = 0
                            else
                                Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                            end

                            r.ImGui_SameLine(ctx, 100, 10)
                            local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                            local InsPos = math.min(FX_Idx - ContainerIdx + 1, #FX[FxGUID_Container].FXsInBS)


                            if dropped and Mods == 0 then
                                local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                                local InsPos = SetMinMax(FX_Idx - ContainerIdx + 1, 1, #FX[FxGUID_Container].FXsInBS)



                                DropFXintoBS(FXGUID[DragFX_ID], FxGUID_Container, FX[FxGUID_Container].Sel_Band,
                                    DragFX_ID, FX_Idx, 'DontMove')
                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil

                                MoveFX(Payload, FX_Idx + 1, true)
                            elseif dropped and Mods == Apl then
                                DragFX_Src = DragFX_ID

                                if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                                DropToLyrID = LyrID
                                DroptoRack = FXGUID_RackMixer
                                --MoveFX(DragFX_Src, DragFX_Dest ,false )

                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil
                            end
                            -- Add from Sexan Add FX
                            if Payload_Type == 'AddFX_Sexan' then
                                AddFX_Sexan(FX_Idx, ClrLbl)
                            end

                            r.ImGui_EndDragDropTarget(ctx)
                        else
                            Dvdr.Width[TblIdxForSpace] = 0
                            FxDroppingTo = nil
                        end
                    end
                else -- if Space is not in FX Layer
                    function MoveFX_Out_Of_BS()
                        for i = 0, Sel_Track_FX_Count - 1, 1 do
                            if FX[FXGUID[i]].FXsInBS then -- i is Band Splitter
                                table.remove(FX[FXGUID[i]].FXsInBS, tablefind(FX[FXGUID[i]].FXsInBS, FXGUID[DragFX_ID]))
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID],
                                    '', true)
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FXGUID
                                    [DragFX_ID], '', true)
                            end
                        end
                        FX[FXGUID[DragFX_ID]].InWhichBand = nil
                    end

                    if r.ImGui_BeginDragDropTarget(ctx) then
                        if Payload_Type == 'FX_Drag' then
                            local allowDropNext, MoveFromPostToNorm, DontAllowDrop
                            local FX_Idx = FX_Idx
                            if Mods == Apl then allowDropNext = true end



                            if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) and (not SpcIsInPre or SpaceIsBeforeRackMixer == 'End of PreFX') then allowDropNext = true end
                            if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) and (not SpcInPost or AddLastSpace == 'LastSpc') then
                                allowDropNext = true; MoveFromPostToNorm = true
                            end
                            if FX[FXGUID[DragFX_ID]].InWhichBand then allowDropNext = true end
                            if not FX[FXGUID[DragFX_ID]].InWhichBand and SpaceIsBeforeRackMixer == 'SpcInBS' then allowDropNext = true end
                            --[[  if (FX.Win_Name_S[DragFX_ID]or''):find('Pro%-C 2') then
                                FX_Idx = FX_Idx-1
                                if (DragFX_ID  == FX_Idx +1) or (DragFX_ID == FX_Idx-1)  then DontAllowDrop = true end
                            end  ]]

                            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 0 else offset = 0 end

                            if (DragFX_ID + offset == FX_Idx or DragFX_ID + offset == FX_Idx - 1) and SpaceIsBeforeRackMixer ~= true and FX.InLyr[FXGUID[DragFX_ID]] == nil and not SpcInPost and not allowDropNext
                                or (Trk[TrkID].PreFX[#Trk[TrkID].PreFX] == FXGUID[DragFX_ID] and SpaceIsBeforeRackMixer == 'End of PreFX') or DontAllowDrop then
                                r.ImGui_SameLine(ctx, nil, 0)

                                Dvdr.Width[TblIdxForSpace] = 0
                                r.ImGui_EndDragDropTarget(ctx)
                            else
                                HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect',
                                    Foreground)


                                Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                                Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width

                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                                FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)
                                if dropped and Mods == 0 then
                                    payload = tonumber(payload)
                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 0, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 1, 2, 0)

                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 0, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 1, 2, 0)


                                    if FX.Win_Name_S[payload]:find('Pro%-Q 3') and not tablefind(Trk[TrkID].PostFX, FXGUID[payload]) and not SpcInPost and not SpcIsInPre and not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                                        MoveFXwith1PreFX(DragFX_ID, FX_Idx, 'Move Pro-Q 3 and it\'s analyzer')
                                        --[[ elseif FX.Win_Name_S[payload]:find('Pro%-C 2') and not tablefind(Trk[TrkID].PostFX, FXGUID[payload])and not SpcInPost and not SpcIsInPre then
                                        MoveFXwith1PreFXand1PosFX(DragFX_ID,FX_Idx, 'Move Pro-C 2 and it\'s analyzer') ]]
                                    else
                                        MoveFX(payload, FX_Idx, true, nil)
                                    end

                                    -- Move FX Out of BandSplit
                                    if FX[FXGUID[DragFX_ID]].InWhichBand then
                                        for i = 0, Sel_Track_FX_Count - 1, 1 do
                                            if FX[FXGUID[i]].FXsInBS then -- i is Band Splitter
                                                table.remove(FX[FXGUID[i]].FXsInBS,
                                                    tablefind(FX[FXGUID[i]].FXsInBS, FXGUID[DragFX_ID]))
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID], '', true)
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: FX is in which Band' .. FXGUID[DragFX_ID], '', true)
                                            end
                                        end
                                        FX[FXGUID[DragFX_ID]].InWhichBand = nil
                                    end


                                    -- Move FX Out of Layer
                                    if Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] ~= nil then
                                        Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] = Lyr.FX_Ins
                                            [FX.InLyr[FXGUID_To_Check_If_InLayer]] - 1
                                    end
                                    r.SetProjExtState(0, 'FX Devices',
                                        'FXLayer - ' .. 'is FX' .. FXGUID_To_Check_If_InLayer .. 'in layer', "")
                                    FX.InLyr[FXGUID_To_Check_If_InLayer] = nil
                                    Dvdr.JustDroppedFX = true
                                elseif dropped and Mods == Apl then
                                    local copypos = FX_Idx + 1
                                    payload = tonumber(payload)

                                    if FX_Idx == 0 then copypos = 0 end
                                    MoveFX(payload, copypos, false)
                                end
                                r.ImGui_SameLine(ctx, nil, 0)
                            end
                        elseif Payload_Type == 'FX Layer Repositioning' then -- FX Layer Repositioning
                            local FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

                            local lyrFxInst
                            if Lyr[FXGUID_RackMixer] then
                                lyrFxInst = Lyr[FXGUID_RackMixer].HowManyFX
                            else
                                lyrFxInst = 0
                            end


                            if (DragFX_ID - (math.max(lyrFxInst, 1)) <= FX_Idx and FX_Idx <= DragFX_ID + 1) or DragFX_ID - lyrFxInst == FX_Idx then
                                DontAllowDrop = true
                                r.ImGui_SameLine(ctx, nil, 0)
                                Dvdr.Width[TblIdxForSpace] = 0
                                r.ImGui_EndDragDropTarget(ctx)

                                --[[  ]]
                                Dvdr.Width[FX_Idx] = 0
                            else --if dragging to an adequate space
                                Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX Layer Repositioning')
                                Dvdr.Width[TblIdxForSpace] = 30

                                if dropped then
                                    RepositionFXsInContainer(FX_Idx)
                                    --r.Undo_EndBlock('Undo for moving FX layer',0)
                                end
                            end
                        elseif Payload_Type == 'BS_Drag' then
                            local Pl = tonumber(Payload)


                            if SpaceIsBeforeRackMixer == 'SpcInBS' or FX_Idx == Pl or Pl + (#FX[FXGUID[Pl]].FXsInBS or 0) + 2 == FX_Idx then
                                Dvdr.Width[TblIdxForSpace] = 0
                            else
                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'BS_Drag')
                                Dvdr.Width[TblIdxForSpace] = 30
                                if dropped then
                                    RepositionFXsInContainer(FX_Idx, Payload)
                                end
                            end
                        elseif Payload_Type == 'AddFX_Sexan' then
                            AddFX_Sexan(FX_Idx, ClrLbl)
                            r.ImGui_EndDragDropTarget(ctx)
                        end
                    else
                        Dvdr.Width[TblIdxForSpace] = 0
                        Dvdr.Clr[ClrLbl] = 0x131313ff
                        r.ImGui_SameLine(ctx, nil, 0)
                    end
                    r.ImGui_SameLine(ctx, nil, 0)
                end




                return 10 + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0)
            end

            RepeatTimeForWindows = Sel_Track_FX_Count

            MaxX, MaxY = r.ImGui_GetContentRegionMax(ctx)
            framepadding = r.ImGui_StyleVar_FramePadding()
            BorderSize = r.ImGui_StyleVar_FrameBorderSize()
            FrameRounding = r.ImGui_StyleVar_FrameRounding()
            BtnTxtAlign = r.ImGui_StyleVar_ButtonTextAlign()

            r.ImGui_PushStyleVar(ctx, framepadding, 0, 3) --StyleVar#1 (Child Frame for all FX Devices)
            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x121212ff)


            for FX_Idx = 0, RepeatTimeForWindows - 1, 1 do
                FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)

                if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
                    FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                end
            end


            if FXGUID_RackMixer ~= nil then
                Lyr.FX_Ins[FXGUID_RackMixer] = 0
                for FX_Idx = 0, RepeatTimeForWindows - 1, 1 do
                    if FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                        Lyr.FX_Ins[FXGUID_RackMixer] = Lyr.FX_Ins[FXGUID_RackMixer] + 1
                    end
                end
            end


            Glob.WDL = r.ImGui_GetWindowDrawList(ctx)
            Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)
            if Dvdr.JustDroppedFX then
                if not Dvdr.JustDrop.X then
                    Dvdr.JustDrop.X, Dvdr.JustDrop.Y = r.ImGui_GetMousePos(ctx)
                end
                local X, Y = r.ImGui_GetMousePos(ctx)

                if X > Dvdr.JustDrop.X + 15 or X < Dvdr.JustDrop.X - 15 then
                    Dvdr.JustDroppedFX = nil
                    Dvdr.JustDrop.X = nil
                    Dvdr.JustDrop.Y = nil
                end
            end


            Trk[TrkID] = Trk[TrkID] or {}
            Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}


            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ChildBorderSize(), 0)
            Cx_LeftEdge, Cy_BeforeFXdevices = r.ImGui_GetCursorScreenPos(ctx)
            MouseAtLeftEdge = r.ImGui_IsMouseHoveringRect(ctx, Cx_LeftEdge - 50, Cy_BeforeFXdevices, Cx_LeftEdge + 5,
                Cy_BeforeFXdevices + 220)

            if MouseAtLeftEdge and not Trk[TrkID].PreFX[1] and string.len(Payload_Type) > 1 then
                rv = r.ImGui_Button(ctx, 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                SL(nil, 0)
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)

                if Payload_Type == 'FX_Drag' then
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    r.ImGui_SameLine(ctx, nil, 0)
                elseif Payload_Type == 'AddFX_Sexan' then
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan') --
                end
            end


            if Trk[TrkID].PreFX[1] then
                rv = r.ImGui_Button(ctx, (#Trk[TrkID].PreFX or '') .. '\n\n' .. 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20,
                    220)
                r.ImGui_SameLine(ctx, nil, 0)
                if r.ImGui_IsItemClicked(ctx, 1) then
                    if Trk[TrkID].PreFX_Hide then Trk[TrkID].PreFX_Hide = false else Trk[TrkID].PreFX_Hide = true end
                end
            end

            if r.ImGui_BeginDragDropTarget(ctx) then
                if Payload_Type == 'FX_Drag' then
                    rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                        'GetItemRect', WDL)

                    if rv then
                        if not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                            table.insert(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #Trk[TrkID].PreFX,
                                FXGUID[DragFX_ID], true)
                        end

                        -- move fx out of post chain
                        local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                        if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                        --Move FX out of layer
                        if FX.InLyr[FXGUID[DragFX_ID]] then
                            FX.InLyr[FXGUID[DragFX_ID]] = nil
                            r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer',
                                '')
                        end
                        RemoveFXfromBS()
                    end
                elseif Payload_Type == 'AddFX_Sexan' then
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan') --
                    if dropped then
                        r.TrackFX_AddByName(LT_Track, payload, false, -1000)
                        local FxID = r.TrackFX_GetFXGUID(LT_Track, 0)
                        table.insert(Trk[TrkID].PreFX, FxID)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #Trk[TrkID].PreFX, FxID, true)

                        for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                            FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                        end
                    end
                end



                r.ImGui_EndDragDropTarget(ctx)
            end



            Trk[TrkID].PostFX = Trk[TrkID].PostFX or {}
            if ((DragDroppingFX and MouseAtRightEdge) and not Trk[TrkID].PostFX[1]) then
                if Trk[TrkID].PreFX[1] then MakeSpaceForPostFX = 30 else MakeSpaceForPostFX = 0 end
            elseif Trk[TrkID].PostFX_Hide and Trk[TrkID].PreFX[1] then
                MakeSpaceForPostFX = 20
            else
                MakeSpaceForPostFX = 0
            end



            MacroPos = r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0)
            local ReSpectrumPos = r.TrackFX_AddByName(LT_Track, 'FXD ReSpectrum', 0, 0)
            if MacroPos ~= -1 and MacroPos ~= 0 then -- if macro exists on track, and Macro is not the 1st fx
                if FX.Win_Name[0] ~= 'JS: FXD Macros' then
                    r.TrackFX_CopyToTrack(LT_Track, MacroPos,
                        LT_Track, 0, true)
                end -- move it to 1st slot
            end



            if MacroPos ~= -1 or ReSpectrumPos == 0 then offset = 0 else offset = 1 end -- if no Macros is found


            for i, v in pairs(Trk[TrkID].PreFX or {}) do
                if FXGUID[i - offset] ~= v then
                    if not AddFX.Name[1] then
                        table.insert(MovFX.FromPos, tablefind(FXGUID, v))
                        table.insert(MovFX.ToPos, i - offset)
                        table.insert(MovFX.Lbl, 'Move FX into Pre-Chain')
                    end
                end
            end
            offset = nil
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), Window_BG or CustomColorsDefault.Window_BG)

            local spaceIfPreFX = 0
            if Trk[TrkID].PreFX[1] and Trk[TrkID].PostFX[1] and not Trk[TrkID].PostFX_Hide then spaceIfPreFX = 20 end
            if Wheel_V ~= 0 and not DisableScroll then r.ImGui_SetNextWindowScroll(ctx, -CursorStartX + Wheel_V * 10, 0) end

            if r.ImGui_BeginChild(ctx, 'fx devices', MaxX - (PostFX_Width or 0) - spaceIfPreFX, 240, nil, r.ImGui_WindowFlags_HorizontalScrollbar() + FX_DeviceWindow_NoScroll) then
                ------------------------------------------------------
                ----- Loop for every FX on the track -----------------
                ------------------------------------------------------


                CursorStartX = r.ImGui_GetCursorStartPos(ctx)
                Glob.WinL, Glob.WinT = r.ImGui_GetCursorScreenPos(ctx)
                Glob.Height = 220
                Glob.WinB = Glob.WinT + Glob.Height
                AnySplitBandHvred = false


                local ViewPort_DL = r.ImGui_GetWindowDrawList(ctx)
                r.ImGui_DrawList_AddLine(ViewPort_DL, 0, 0, 0, 0, Clr.Dvdr.outline) -- Needed for drawlist to be active

                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                    retval, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx) --i used to be i-1
                    FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)


                    local FxGUID = FXGUID[FX_Idx]
                    FX.Win_Name[FX_Idx] = FX_Name
                    focusedFXState, trackNumOfFocusFX, _, FX_Index_FocusFX = r.GetFocusedFX2()

                    if FXGUID[FX_Idx] then
                        FX[FxGUID] = FX[FxGUID] or {}
                    end


                    function GetFormatPrmV(V, OrigV, i)
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, V)
                        local _, RV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, i)
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, OrigV)
                        return RV
                    end

                    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                    if not tablefind(Trk[TrkID].PostFX, FxGUID) and FXGUID[FX_Idx] ~= FXGUID[FX_Idx - 1] then
                        if FX.InLyr[FXGUID_To_Check_If_InLayer] == nil           --not in layer
                            and FindStringInTable(BlackListFXs, FX_Name) ~= true -- not blacklisted
                            and string.find(FX_Name, 'RackMixer') == nil
                            and FX_Idx ~= RepeatTimeForWindows                   --not last fx
                            and not FX[FxGUID].InWhichBand --[[Not in Band Split]] then
                            local Idx = FX_Idx
                            if FX_Idx == 1 then
                                local Nm = FX.Win_Name[0]
                                if Nm == 'JS: FXD Macros' or FindStringInTable(BlackListFXs, Nm) then Idx = 0 end
                            end
                            AddSpaceBtwnFXs(Idx)
                        elseif FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] and FXGUID[FX_Idx] then
                            AddSpaceBtwnFXs(FX_Idx, true)
                        elseif FX_Idx == RepeatTimeForWindows then
                        end
                    end


                    ------------END Space between FXs--------------------



                    ---------------==  FX Devices--------------------

                    DragFX_ID = DragFX_ID or -1000
                    if DragDroppingFX == true and DragFX_ID == FX_Idx then
                        BGColor_FXWindow = FX_Window_Clr_When_Dragging
                    else
                        BGColor_FXWindow = FX_Window_Clr_Default
                    end
                    BGColor_FXWindow = BGColor_FXWindow or 0x434343ff


                    function createFXWindow(FX_Idx)
                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                        if FXGUID[FX_Idx] ~= FXGUID[FX_Idx - 1] --[[  findDuplicates(FXGUID) ]] and FxGUID then
                            r.ImGui_BeginGroup(ctx)

                            FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
                            local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx); local FxGUID = FXGUID
                                [FX_Idx];
                            local FxNameS = FX.Win_Name_S[FX_Idx]
                            local Hide
                            FX.DL = r.ImGui_GetWindowDrawList(ctx)


                            FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
                            FX_Name = string.gsub(FX_Name, '-', ' ')
                            WDL = FX.DL
                            FX[FxGUID] = FX[FxGUID] or {}
                            if FX[FxGUID].MorphA and not FX[FxGUID].MorphHide then
                                local OrigCurX, OrigCurY = r.ImGui_GetCursorPos(ctx)

                                DefClr_A_Act = Morph_A or CustomColorsDefault.Morph_A
                                DefClr_A = Change_Clr_A(DefClr_A_Act, -0.2)
                                DefClr_A_Hvr = Change_Clr_A(DefClr_A_Act, -0.1)
                                DefClr_B_Act = Morph_B or CustomColorsDefault.Morph_B
                                DefClr_B = Change_Clr_A(DefClr_B_Act, -0.2)
                                DefClr_B_Hvr = Change_Clr_A(DefClr_B_Act, -0.1)


                                function StoreAllPrmVal(AB, DontStoreCurrentVal, LinkCC)
                                    local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                    for i = 0, PrmCount - 4, 1 do
                                        local _, name = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                        local Prm_Val, minval, maxval = r.TrackFX_GetParamNormalized(LT_Track,
                                            FX_Idx, i)
                                        if AB == 'A' then
                                            if DontStoreCurrentVal ~= 'Dont' then FX[FxGUID].MorphA[i] = Prm_Val end
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX Morph A' .. i .. FxGUID,
                                                FX[FxGUID].MorphA[i], true)
                                            if LinkCC then
                                                Link_Param_to_CC(LT_TrackNum, FX_Idx, i, true, true, 160,
                                                    LinkCC, Prm_Val, FX[FxGUID].MorphB[i])
                                            end
                                        else
                                            if DontStoreCurrentVal ~= 'Dont' then FX[FxGUID].MorphB[i] = Prm_Val end
                                            if FX[FxGUID].MorphB[i] then
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: FX Morph B' .. i ..
                                                    FxGUID, FX[FxGUID].MorphB[i], true)
                                                if LinkCC then
                                                    Link_Param_to_CC(LT_TrackNum, FX_Idx, i, true, true, 160,
                                                        LinkCC, FX[FxGUID].MorphA[i], Prm_Val - FX[FxGUID].MorphA[i])
                                                end
                                            end
                                        end
                                    end
                                    if DontStoreCurrentVal ~= 'Dont' then
                                        local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                                        if rv and AB == 'A' then
                                            FX[FxGUID].MorphA_Name = presetname
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', presetname, true)
                                        elseif rv and AB == 'B' then
                                            FX[FxGUID].MorphB_Name = presetname
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', presetname, true)
                                        end
                                    end
                                end

                                r.ImGui_SetNextItemWidth(ctx, 20)
                                local x, y = r.ImGui_GetCursorPos(ctx)
                                x = x - 2
                                local SCx, SCy = r.ImGui_GetCursorScreenPos(ctx)
                                SCx = SCx - 2
                                r.ImGui_SetCursorPosX(ctx, x)

                                --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),DefClr_A) r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), DefClr_A_Hvr) r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), DefClr_A_Act)

                                if r.ImGui_Button(ctx, 'A##' .. FxGUID, 20, 20) then
                                    StoreAllPrmVal('A', nil, FX[FxGUID].Morph_ID)
                                end
                                --r.ImGui_PopStyleColor(ctx,3)


                                if r.ImGui_IsItemHovered(ctx) and FX[FxGUID].MorphA_Name then
                                    if FX[FxGUID].MorphA_Name ~= '' then
                                        HintToolTip(FX[FxGUID].MorphA_Name)
                                    end
                                end

                                local H = 180
                                r.ImGui_SetCursorPos(ctx, x, y + 20)

                                r.ImGui_InvisibleButton(ctx, '##Morph' .. FxGUID, 20, H)

                                local BgClrA, isActive, V_Pos, DrgSpdMod, SldrActClr, BtnB_TxtClr, ifHvr
                                local M = PresetMorph


                                if r.ImGui_IsItemActive(ctx) then
                                    BgClr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_FrameBgActive())
                                    isActive = true
                                    BgClrA = DefClr_A_Act
                                    BgClrB =
                                        DefClr_B_Act -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity
                                elseif r.ImGui_IsItemHovered(ctx) then
                                    ifHvr = true
                                    BgClrA = DefClr_A_Hvr
                                    BgClrB = DefClr_B_Hvr
                                else
                                    BgClr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_FrameBg())
                                    BgClrA = DefClr_A
                                    BgClrB = DefClr_B
                                end
                                if --[[Ctrl + R click]] r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                                    r.ImGui_OpenPopup(ctx, 'Morphing menu' .. FX_Idx)
                                end




                                local L, T = r.ImGui_GetItemRectMin(ctx)
                                local R, B = r.ImGui_GetItemRectMax(ctx)
                                r.ImGui_DrawList_AddRectFilledMultiColor(WDL, L, T, R, B, BgClrA, BgClrA, DefClr_B,
                                    DefClr_B)

                                r.ImGui_SameLine(ctx, nil, 0)

                                if isActive then
                                    local _, v = r.ImGui_GetMouseDelta(ctx, nil, nil)
                                    if Mods == Shift then DrgSpdMod = 4 end
                                    DraggingMorph = FxGUID
                                    FX[FxGUID].MorphAB_Sldr = SetMinMax(
                                        (FX[FxGUID].MorphAB_Sldr or 0) + v / (DrgSpdMod or 2), 0, 100)
                                    SldrActClr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_SliderGrabActive())
                                    if FX[FxGUID].MorphB[1] ~= nil then
                                        local M_ID
                                        if FX[FxGUID].Morph_ID then
                                            r.TrackFX_SetParamNormalized(LT_Track, 0 --[[Macro.jsfx]],
                                                7 + FX[FxGUID].Morph_ID, FX[FxGUID].MorphAB_Sldr / 100)
                                        else
                                            for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                                                if v ~= FX[FxGUID].MorphB[i] then
                                                    if FX[FxGUID].PrmList[i] then
                                                        if FX[FxGUID].PrmList[i].BL ~= true then
                                                            Fv = v +
                                                                (FX[FxGUID].MorphB[i] - v) *
                                                                (FX[FxGUID].MorphAB_Sldr / 100)
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, Fv)
                                                        end
                                                    else
                                                        Fv = v + (FX[FxGUID].MorphB[i] - v) *
                                                            (FX[FxGUID].MorphAB_Sldr / 100)
                                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, Fv)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end

                                --[[ if ifHvr   then

                                    --r.ImGui_SetNextWindowPos(ctx,SCx+20, SCy+20)
                                    r.ImGui_OpenPopup(ctx, 'Hover On Preset Morph Drag')

                                    M.JustHvrd = true
                                end
                                if M.JustHvrd then

                                    M.JustHvrd = nil
                                end ]]

                                if r.ImGui_BeginPopup(ctx, 'Morphing menu' .. FX_Idx) then
                                    local Disable
                                    MorphingMenuOpen = true
                                    if not FX[FxGUID].MorphA[1] or not FX[FxGUID].MorphB[1] then
                                        r.ImGui_BeginDisabled(
                                            ctx)
                                    end

                                    if not FX[FxGUID].Morph_ID or FX[FxGUID].Unlink then
                                        if r.ImGui_Selectable(ctx, 'Automate', false) then
                                            r.gmem_attach('ParamValues')

                                            if not Trk[TrkID].Morph_ID then
                                                Trk[TrkID].Morph_ID = {} -- Morph_ID is the CC number jsfx sends
                                                Trk[TrkID].Morph_ID[1] = FxGUID
                                                FX[FxGUID].Morph_ID = 1
                                            else
                                                if not FX[FxGUID].Morph_ID then
                                                    table.insert(Trk[TrkID].Morph_ID, FxGUID)
                                                    FX[FxGUID].Morph_ID = tablefind(Trk[TrkID].Morph_ID, FxGUID)
                                                end
                                            end

                                            if --[[Add Macros JSFX if not found]] r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then
                                                r.gmem_write(1, PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
                                                AddMacroJSFX()
                                            end
                                            for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                                                local Scale = FX[FxGUID].MorphB[i] - v

                                                if v ~= FX[FxGUID].MorphB[i] then
                                                    local function LinkPrm()
                                                        Link_Param_to_CC(LT_TrackNum, FX_Idx, i, true, true, 160,
                                                            FX[FxGUID].Morph_ID, v, Scale)
                                                        FX[FxGUID][i] = FX[FxGUID][i] or {}
                                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                                            'P_EXT: FXs Morph_ID' .. FxGUID, FX[FxGUID].Morph_ID, true)
                                                    end

                                                    if FX[FxGUID].PrmList[i] then
                                                        if FX[FxGUID].PrmList[i].BL ~= true then
                                                            LinkPrm()
                                                        end
                                                    else
                                                        LinkPrm()
                                                    end
                                                end
                                            end


                                            -- Show Envelope for Morph Slider
                                            r.GetFXEnvelope(LT_Track, 0, 7 + FX[FxGUID].Morph_ID, true)


                                            FX[FxGUID].Unlink = false
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '', true)

                                            SetPrmAlias(LT_TrackNum, 1, 8 + FX[FxGUID].Morph_ID,
                                                FX.Win_Name_S[FX_Idx]:gsub("%b()", "") .. ' - Morph AB ')
                                        end
                                    elseif FX[FxGUID].Morph_ID or not FX[FxGUID].Unlink then
                                        if r.ImGui_Selectable(ctx, 'Unlink Parameters to Morph Automation', false) then
                                            for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                                                Unlink_Parm(LT_TrackNum, FX_Idx, i)
                                            end
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FXs Morph_ID' .. FxGUID,
                                                FX[FxGUID].Morph_ID, true)
                                            FX[FxGUID].Unlink = true
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', 'Unlink', true)
                                        end
                                    end

                                    if FX[FxGUID].Morph_Value_Edit then
                                        if r.ImGui_Selectable(ctx, 'EXIT Edit Preset Value Mode', false) then
                                            FX[FxGUID].Morph_Value_Edit = false
                                        end
                                    else
                                        if Disable then r.ImGui_BeginDisabled(ctx) end
                                        if r.ImGui_Selectable(ctx, 'ENTER Edit Preset Value Mode', false) then
                                            FX[FxGUID].Morph_Value_Edit = true
                                        end
                                    end
                                    if not FX[FxGUID].MorphA[1] or not FX[FxGUID].MorphB[1] then r.ImGui_EndDisabled(ctx) end

                                    if r.ImGui_Selectable(ctx, 'Morphing Blacklist Settings', false) then
                                        if OpenMorphSettings then
                                            OpenMorphSettings = FxGUID
                                        else
                                            OpenMorphSettings =
                                                FxGUID
                                        end
                                        local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                        FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                        for i = 0, Ct - 4, 1 do --get param names
                                            FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                                            local rv, name             = r.TrackFX_GetParamName(LT_Track, FX_Idx,
                                                i)
                                            FX[FxGUID].PrmList[i].Name = name
                                        end
                                    end

                                    if r.ImGui_Selectable(ctx, 'Hide Morph Slider', false) then
                                        FX[FxGUID].MorphHide = true
                                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph Hide' .. FxGUID,
                                            'true',
                                            true)
                                    end

                                    r.ImGui_EndPopup(ctx)
                                else
                                    MorphingMenuOpen = false
                                end




                                if not ifHvr and M.JustHvrd then
                                    M.timer = M.timer + 1
                                else
                                    M.timer = 0
                                end





                                V_Pos = T + (FX[FxGUID].MorphAB_Sldr or 0) / 100 * H * 0.95
                                r.ImGui_DrawList_AddRectFilled(WDL, L, V_Pos, R, V_Pos + 10, 0xffffff22)
                                r.ImGui_DrawList_AddRect(WDL, L, V_Pos, R, V_Pos + 10, 0xffffff44)


                                r.ImGui_SameLine(ctx)
                                r.ImGui_SetCursorPos(ctx, x, y + 200)
                                if not FX[FxGUID].MorphB[1] then
                                    BtnB_TxtClr = r.ImGui_GetStyleColor(ctx,
                                        r.ImGui_Col_TextDisabled())
                                end

                                if BtnB_TxtClr then
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),
                                        r.ImGui_GetStyleColor(ctx, r.ImGui_Col_TextDisabled()))
                                end
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), DefClr_B)
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), DefClr_B_Hvr)
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), DefClr_B_Act)

                                if r.ImGui_Button(ctx, 'B##' .. FxGUID, 20, 20) then
                                    StoreAllPrmVal('B', nil, FX[FxGUID].Morph_ID)
                                    local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                                    if rv then FX[FxGUID].MorphB_Name = presetname end
                                end
                                if r.ImGui_IsItemHovered(ctx) and FX[FxGUID].MorphB_Name then
                                    HintToolTip(FX[FxGUID]
                                        .MorphB_Name)
                                end
                                r.ImGui_PopStyleColor(ctx, 3)

                                if BtnB_TxtClr then r.ImGui_PopStyleColor(ctx) end
                                if FX.Enable[FX_Idx] == false then
                                    r.ImGui_DrawList_AddRectFilled(WDL, L, T - 20, R, B +
                                        20, 0x00000088)
                                end

                                r.ImGui_SetCursorPos(ctx, OrigCurX + 19, OrigCurY)
                            end

                            local FX_Devices_Bg = FX_Devices_Bg
                            if string.find(FX_Name, 'Pro Q 3') then FX_Devices_Bg = 0x000000ff end

                            -- FX window color

                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(),
                                FX.BgClr[FxGUID] or FX_Devices_Bg or 0x151515ff); local poptimes = 1


                            FX[FxGUID] = FX[FxGUID] or {}

                            local PrmCount = tonumber(select(2, r.GetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID))) or
                                0


                            local Def_Sldr_W = 160
                            if FX.Def_Sldr_W[FxGUID] then Def_Sldr_W = FX.Def_Sldr_W[FxGUID] end

                            if FX.Def_Type[FxGUID] == 'Slider' or FX.Def_Type[FxGUID] == 'Drag' or not FX.Def_Type[FxGUID] then
                                local DF = (FX.Def_Sldr_W[FxGUID] or Df.Sldr_W)

                                local Ct = math.max(math.floor((PrmCount / 6 - 0.01)) + 1, 1)

                                DefaultWidth = (DF + GapBtwnPrmColumns) * Ct
                            elseif FX.Def_Type[FxGUID] == 'Knob' then
                                local Ct = math.max(math.floor((PrmCount / 3) - 0.1) + 1, 1) -- need to -0.1 so flooring 3/3 -0.1 will return 0 and 3/4 -0.1 will be 1
                                DefaultWidth = Df.KnobSize * Ct + GapBtwnPrmColumns
                                --[[
                                if PrmCount <= 6 then
                                    DefaultWidth = Df.KnobSize * 3
                                elseif PrmCount > 6 and PrmCount <= 9 then
                                    DefaultWidth = Df.KnobSize * 4
                                elseif PrmCount > 9 and PrmCount <= 12 then
                                    DefaultWidth = (Df.KnobSize + 10) * 4
                                elseif PrmCount > 16 and PrmCount <= 20 then
                                    DefaultWidth = Df.KnobSize * 5
                                elseif PrmCount > 20 and PrmCount <= 24 then
                                    DefaultWidth = Df.KnobSize * 6
                                else
                                    DefaultWidth = Df.Sldr_W + 10
                                end ]]
                            end

                            if string.find(FX_Name, 'Pro Q 3') then
                                FX.Width[FxGUID] = 340
                            elseif string.find(FX_Name, 'Pro C 2') then
                                FX.Width[FxGUID] = ProC.Width
                            elseif FindStringInTable(BlackListFXs, FX_Name) then
                                Hide = true
                            elseif FX.Width[FxGUID] == 340 then
                                FX.Width[FxGUID] = nil
                            end

                            if Trk[TrkID].PreFX_Hide then
                                if FindStringInTable(Trk[TrkID].PreFX, FxGUID) then
                                    Hide = true
                                end
                                if Trk[TrkID].PreFX[FX_Idx + 1] == FxGUID then
                                    Hide = true
                                end
                            end
                            if not Hide then
                                local CurPosX
                                if FxGUID == FXGUID[(tablefind(Trk[TrkID].PostFX, FxGUID) or 0) - 1] then
                                    --[[ CurPosX = r.ImGui_GetCursorPosX(ctx)
                                    r.ImGui_SetCursorPosX(ctx,VP.X+VP.w- (FX[FxGUID].PostWin_SzX or 0)) ]]
                                end
                                if r.ImGui_BeginChild(ctx, FX_Name .. FX_Idx, FX.WidthCollapse[FxGUID] or FX.Width[FXGUID[FX_Idx]] or DefaultWidth or 220, 220, nil, r.ImGui_WindowFlags_NoScrollWithMouse() + r.ImGui_WindowFlags_NoScrollbar()) and not Hide then ----START CHILD WINDOW------
                                    if Draw[FxNameS] ~= nil then
                                        local D = Draw[FxNameS]
                                    end


                                    Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)

                                    WDL = r.ImGui_GetWindowDrawList(ctx)
                                    Win_L, Win_T = r.ImGui_GetItemRectMin(ctx); Win_W, Win_H = r.ImGui_GetItemRectSize(
                                        ctx)
                                    Win_R, _ = r.ImGui_GetItemRectMax(ctx); Win_B = Win_T + 220

                                    if Draw.DrawMode[FxGUID] == true then
                                        local D = Draw[FxNameS]
                                        r.ImGui_DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B, 0x00000033)
                                        for i = 0, 220, LE.GridSize do
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_L,
                                                Win_T + i, Win_R, Win_T + i, 0x44444411)
                                        end
                                        for i = 0, FX.Width[FXGUID[FX_Idx]] or DefaultWidth, LE.GridSize do
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B,
                                                0x44444411)
                                        end
                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil and not Draw.SelItm and Draw.Time == 0 then
                                            if Draw.Type == 'Text' then
                                                r.ImGui_SetMouseCursor(ctx,
                                                    r.ImGui_MouseCursor_TextInput())
                                            end
                                            if r.ImGui_IsMouseClicked(ctx, 0) and Mods == 0 then
                                                Draw.CurrentylDrawing = true
                                                MsX_Start, MsY_Start = r.ImGui_GetMousePos(ctx);
                                                CurX, CurY = r.ImGui_GetCursorScreenPos(ctx)
                                                Win_MsX_Start = MsX_Start - CurX; Win_MsY_Start = MsY_Start - CurY + 3
                                            end

                                            if Draw.CurrentylDrawing then
                                                if IsLBtnHeld and Mods == 0 and MsX_Start then
                                                    MsX, MsY   = r.ImGui_GetMousePos(ctx)
                                                    CurX, CurY = r.ImGui_GetCursorScreenPos(ctx)
                                                    Win_MsX    = MsX - CurX; Win_MsY = MsY - CurY

                                                    Rad        = MsX - MsX_Start
                                                    if Rad < 0 then Rad = Rad * (-1) end
                                                    if Draw.Type == 'line' then
                                                        r.ImGui_DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX,
                                                            MsY_Start,
                                                            Draw.clr)
                                                    elseif Draw.Type == 'V-line' then
                                                        r.ImGui_DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX_Start,
                                                            MsY, Draw.clr)
                                                    elseif Draw.Type == 'rectangle' then
                                                        r.ImGui_DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY,
                                                            Draw.clr, Draw.Df_EdgeRound[FxGUID] or 0)
                                                    elseif Draw.Type == 'Picture' then
                                                        r.ImGui_DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY,
                                                            Draw.clr, Draw.Df_EdgeRound[FxGUID] or 0)
                                                    elseif Draw.Type == 'rect fill' then
                                                        r.ImGui_DrawList_AddRectFilled(WDL, MsX_Start, MsY_Start, MsX,
                                                            MsY,
                                                            Draw.clr, Draw.Df_EdgeRound[FxGUID] or 0)
                                                    elseif Draw.Type == 'circle' then
                                                        r.ImGui_DrawList_AddCircle(WDL, MsX_Start, MsY_Start, Rad,
                                                            Draw.clr)
                                                    elseif Draw.Type == 'circle fill' then
                                                        r.ImGui_DrawList_AddCircleFilled(WDL, MsX_Start, MsY_Start, Rad,
                                                            Draw.clr)
                                                    elseif Draw.Type == 'Text' then
                                                        --r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20, 20 , MsX, MsY  , Draw.clr, D.Txt)
                                                        r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_TextInput())
                                                    end
                                                end

                                                if r.ImGui_IsMouseReleased(ctx, 0) and Mods == 0 and Draw.Type ~= 'Text' then
                                                    local D = Draw[FxNameS]
                                                    LE.BeenEdited = true
                                                    --find the next available slot in table

                                                    if Draw.Type == 'circle' or Draw.Type == 'circle fill' then
                                                        table.insert(D.R, Rad)
                                                    else
                                                        table.insert(D.R, Win_MsX)
                                                    end

                                                    table.insert(D.L, Win_MsX_Start);
                                                    table.insert(D.T, Win_MsY_Start);;
                                                    table.insert(D.Type, Draw.Type)
                                                    table.insert(D.B, Win_MsY)
                                                    table.insert(D.clr, Draw.clr or 0xffffffff)
                                                    if not Draw.SelItm then Draw.SelItm = #D.Type end
                                                end




                                                if Draw.Type == 'Text' and IsLBtnClicked and Mods == 0 then
                                                    AddText = #D
                                                        .Type + 1
                                                end
                                            end
                                        end
                                        HvringItmSelector = nil
                                        if AddText then
                                            r.ImGui_OpenPopup(ctx, 'Drawlist Add Text Menu')
                                        end

                                        if r.ImGui_BeginPopup(ctx, 'Drawlist Add Text Menu') then
                                            r.ImGui_SetKeyboardFocusHere(ctx)

                                            enter, NewDrawTxt = r.ImGui_InputText(ctx, '##' .. 'DrawTxt', NewDrawTxt)
                                            --r.ImGui_SetItemDefaultFocus( ctx)

                                            if r.ImGui_IsWindowAppearing(ctx) then
                                                table.insert(D.L, Win_MsX_Start);
                                                table.insert(D.T, Win_MsY_Start);;
                                                table.insert(D.Type, Draw.Type)
                                                table.insert(D.B, Win_MsY)
                                                table.insert(D.clr, Draw.clr)
                                            end


                                            if AddText then
                                                D.Txt[AddText] = NewDrawTxt
                                            end

                                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                                D.Txt[#D.Txt] = NewDrawTxt
                                                AddText = nil;
                                                NewDrawTxt = nil



                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end

                                            r.ImGui_SetItemDefaultFocus(ctx)



                                            r.ImGui_EndPopup(ctx)
                                        end
                                        if LBtnRel then Draw.CurrentylDrawing = nil end

                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil then
                                            if IsLBtnClicked then
                                                Draw.SelItm = nil
                                                Draw.Time = 1
                                            end
                                        end
                                        if Draw.Time > 0 then Draw.Time = Draw.Time + 1 end
                                        if Draw.Time > 6 then Draw.Time = 0 end

                                        if Draw[FxNameS] then
                                            for i, Type in pairs(D.Type) do
                                                local ID = FX_Name .. i
                                                local CircleX, CircleY = Win_L + D.L[i], Win_T + D.T[i]
                                                local FDL = r.ImGui_GetForegroundDrawList(ctx)
                                                r.ImGui_DrawList_AddCircle(FDL, CircleX, CircleY, 7, 0x99999999)
                                                r.ImGui_DrawList_AddText(FDL, Win_L + D.L[i] - 2, Win_T + D.T[i] - 7,
                                                    0x999999ff, i)


                                                if Draw.SelItm == i then
                                                    r.ImGui_DrawList_AddCircleFilled(WDL, CircleX,
                                                        CircleY, 7, 0x99999955)
                                                end


                                                --if hover on item node ...
                                                if r.ImGui_IsMouseHoveringRect(ctx, CircleX - 5, CircleY - 5, CircleX + 5, CircleY + 10) then
                                                    HvringItmSelector = true
                                                    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeAll())
                                                    if DragItm == nil then
                                                        r.ImGui_DrawList_AddCircle(WDL, CircleX, CircleY, 9, 0x999999ff)
                                                    end
                                                    if IsLBtnClicked and Mods == 0 then
                                                        Draw.SelItm = i
                                                        DragItm = i
                                                    end


                                                    if IsLBtnClicked and Mods == Alt then
                                                        table.remove(D.Type, i)
                                                        table.remove(D.L, i)
                                                        table.remove(D.R, i)
                                                        table.remove(D.T, i)
                                                        table.remove(D.B, i)
                                                        if D.Txt[i] then table.remove(D.Txt, SetMinMax(i, 1, #D.Txt)) end
                                                        if D.clr[i] then table.remove(D.clr, SetMinMax(i, 1, #D.clr)) end
                                                        if r.ImGui_BeginPopup(ctx, 'Drawlist Add Text Menu') then
                                                            r.ImGui_CloseCurrentPopup(ctx)
                                                            r.ImGui_EndPopup(ctx)
                                                        end
                                                    end
                                                end

                                                if not IsLBtnHeld then DragItm = nil end
                                                if LBtnDrag and DragItm == i then --- Drag node to reposition
                                                    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeAll())
                                                    r.ImGui_DrawList_AddCircleFilled(WDL, CircleX, CircleY, 7, 0x00000033)
                                                    local Dx, Dy = r.ImGui_GetMouseDelta(ctx)
                                                    if D.Type[DragItm] ~= 'circle' and D.Type[DragItm] ~= 'circle fill' then
                                                        D.R[i] = D.R[i] + Dx -- this is circle's radius
                                                    end
                                                    D.L[i] = D.L[i] + Dx
                                                    D.T[i] = D.T[i] + Dy
                                                    D.B[i] = D.B[i] + Dy
                                                end
                                            end
                                        end
                                    end

                                    if Draw[FX.Win_Name_S[FX_Idx]] and not FX[FxGUID].Collapse then
                                        local D = Draw[FX.Win_Name_S[FX_Idx]]
                                        for i, Type in pairs(D.Type) do
                                            D[i] = D[i] or {}
                                            local L = Win_L + D.L[i]
                                            local T = Win_T + D.T[i]
                                            local R = Win_L + (D.R[i] or 0)
                                            local B = Win_T + D.B[i]
                                            local Round = Draw.Df_EdgeRound[FxGUID] or 0

                                            if D.Type[i] == 'line' then
                                                r.ImGui_DrawList_AddLine(WDL, L, T, R, T, D.clr[i] or 0xffffffff)
                                            elseif D.Type[i] == 'V-line' then
                                                r.ImGui_DrawList_AddLine(WDL, Win_L + D.L[i], Win_T + D.T[i],
                                                    Win_L + D.L[i], Win_T + D.B[i], D.clr[i] or 0xffffffff)
                                            elseif D.Type[i] == 'rectangle' then
                                                r.ImGui_DrawList_AddRect(WDL, L, T, R, B, D.clr[i] or 0xffffffff, Round)
                                            elseif D.Type[i] == 'rect fill' then
                                                r.ImGui_DrawList_AddRectFilled(WDL, L, T, R, B, D.clr[i] or 0xffffffff,
                                                    Round)
                                            elseif D.Type[i] == 'circle' then
                                                r.ImGui_DrawList_AddCircle(WDL, L, T, D.R[i], D.clr[i] or 0xffffffff)
                                            elseif D.Type[i] == 'circle fill' then
                                                r.ImGui_DrawList_AddCircleFilled(WDL, L, T, D.R[i],
                                                    D.clr[i] or 0xffffffff)
                                            elseif D.Type[i] == 'Text' and D.Txt[i] then
                                                r.ImGui_DrawList_AddTextEx(WDL, D[i].Font or Font_Andale_Mono_13,
                                                    D[i].FtSize or 13, L, T, D.clr[i] or 0xffffffff, D.Txt[i])
                                            elseif D.Type[i] == 'Picture' then
                                                if not D[i].Image then
                                                    r.ImGui_DrawList_AddRectFilled(WDL, L, T, R, B, 0xffffff33, Round)
                                                    r.ImGui_DrawList_AddTextEx(WDL, nil, 12, L, T + (B - T) / 2,
                                                        0xffffffff, 'Add Image path', R - L)
                                                else
                                                    if D[i].KeepImgRatio then
                                                        local w, h = r.ImGui_Image_GetSize(D[i].Image)

                                                        local H_ratio = w / h
                                                        local size = R - L


                                                        r.ImGui_DrawList_AddImage(WDL, D[i].Image, L, T, L + size,
                                                            T + size * H_ratio, 0, 0, 1, 1, D.clr[i] or 0xffffffff)
                                                    else
                                                        r.ImGui_DrawList_AddImageQuad(WDL, D[i].Image, L, T, R, T, R, B,
                                                            L, B,
                                                            _1, _2, _3, _4, _5, _6, _7, _8, D.clr[i] or 0xffffffff)
                                                    end
                                                end
                                                -- ImageAngle(ctx, Image, 0, R - L, B - T, L, T)
                                            end
                                        end
                                    end



                                    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true and Mods ~= Apl then -- Resize FX or title btn
                                        MouseX, MouseY = r.ImGui_GetMousePos(ctx)
                                        Win_L, Win_T = r.ImGui_GetItemRectMin(ctx)
                                        Win_R, _ = r.ImGui_GetItemRectMax(ctx); Win_B = Win_T + 220
                                        WinDrawList = r.ImGui_GetWindowDrawList(ctx)
                                        r.ImGui_DrawList_AddRectFilled(WinDrawList, Win_L or 0, Win_T or 0, Win_R or 0,
                                            Win_B, 0x00000055)
                                        --draw grid

                                        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Equal()) then
                                            LE.GridSize = LE.GridSize + 5
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Minus()) then
                                            LE.GridSize = LE.GridSize - 5
                                        end

                                        for i = 0, FX.Width[FXGUID[FX_Idx]] or DefaultWidth, LE.GridSize do
                                            r
                                                .ImGui_DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B,
                                                    0x44444455)
                                        end
                                        for i = 0, 220, LE.GridSize do
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_L,
                                                Win_T + i, Win_R, Win_T + i, 0x44444455)
                                        end

                                        r.ImGui_DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B,
                                            0x66666677, 1)


                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_R - 5, Win_T, Win_R + 5, Win_B) then
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B,
                                                0xffffffff, 3)
                                            r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())

                                            if IsLBtnClicked then
                                                LE.ResizingFX = FX_Idx --@Todo change fxidx to fxguid
                                            end
                                        end


                                        if LE.ResizingFX == FX_Idx and IsLBtnHeld then
                                            r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())

                                            r.ImGui_DrawList_AddRectFilled(WinDrawList, Win_L or 0, Win_T or 0,
                                                Win_R or 0, Win_B, 0x00000055)
                                            local MsDragDeltaX, MsDragDeltaY = r.ImGui_GetMouseDragDelta(ctx); local Dx, Dy =
                                                r.ImGui_GetMouseDelta(ctx)
                                            if not FX.Width[FXGUID[FX_Idx]] then FX.Width[FXGUID[FX_Idx]] = DefaultWidth end
                                            FX.Width[FXGUID[FX_Idx]] = FX.Width[FXGUID[FX_Idx]] + Dx; LE.BeenEdited = true
                                        end
                                        if not IsLBtnHeld then LE.ResizingFX = nil end
                                    end


                                    if FX.Enable[FX_Idx] == nil then
                                        FX.Enable[FX_Idx] = r.TrackFX_GetEnabled(LT_Track, FX_Idx)
                                    end

                                    r.ImGui_SameLine(ctx, nil, 0)
                                    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                                        r.ImGui_BeginDisabled(ctx); R, T = r.ImGui_GetItemRectMax(ctx)
                                    end

                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), FX[FxGUID].TitleClr or 0x22222233)
                                    if FX[FxGUID].TitleClr then
                                        WinbtnClrPop = 3
                                        if not FX[FxGUID].TitleClrHvr then
                                            FX[FxGUID].TitleClrAct, FX[FxGUID].TitleClrHvr = Generate_Active_And_Hvr_CLRs(
                                                FX[FxGUID].TitleClr)
                                        end
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(),
                                            FX[FxGUID].TitleClrHvr or 0x22222233)
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),
                                            FX[FxGUID].TitleClrAct or 0x22222233)
                                    else
                                        WinbtnClrPop = 1
                                    end



                                    local WindowBtn
                                    --[[ r.ImGui_PushStyleColor(ctx, ) ]]
                                    if FX[FxGUID].Collapse ~= true then
                                        if string.find(FX_Name, 'Pro Q 3') ~= nil then
                                            WindowBtn = r.ImGui_Button(ctx, 'Pro-Q 3' .. '##', 60, 20) -- create window name button
                                            ProQ_TitlePosX_L, ProQ_TitlePosY_T = r.ImGui_GetItemRectMin(ctx)
                                            ProQ_TitlePosX_R, ProQ_TitlePosY_B = r.ImGui_GetItemRectMax(ctx)
                                        elseif string.find(FX_Name, 'Pro C 2') ~= nil then
                                            WindowBtn = r.ImGui_Button(ctx, 'Pro-C 2' .. '##', 60, 20) -- create window name button
                                        else
                                            if DebugMode then
                                                FX.Win_Name[FX_Idx] = FxGUID
                                                WindowBtn = r.ImGui_Button(ctx, FxGUID .. '## ',
                                                    FX.TitleWidth[FxGUID] or DefaultWidth - 30, 20) -- create window name button
                                            else
                                                WindowBtn = r.ImGui_Button(ctx,
                                                    (FX[FxGUID].CustomTitle or FX.Win_Name[FX_Idx] or '') .. '## ',
                                                    FX.TitleWidth[FxGUID] or DefaultWidth - 30, 20) -- create window name button
                                            end
                                        end
                                        if r.ImGui_IsItemHovered(ctx) and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                                            FX[FxGUID].TtlHvr = true
                                            TtlR, TtlB = r.ImGui_GetItemRectMax(ctx)
                                            if r.ImGui_IsMouseHoveringRect(ctx, TtlR - 20, TtlB - 20, TtlR, TtlB) then
                                                r.ImGui_DrawList_AddRectFilled(WDL, TtlR, TtlB, TtlR - 20, TtlB - 20,
                                                    getClr(r.ImGui_Col_ButtonHovered()))
                                                r.ImGui_DrawList_AddRect(WDL, TtlR, TtlB, TtlR - 20, TtlB - 19,
                                                    getClr(r.ImGui_Col_Text()))
                                                r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 20, TtlR - 15,
                                                    TtlB - 20, getClr(r.ImGui_Col_Text()), '+')
                                                if IsLBtnClicked then
                                                    r.ImGui_OpenPopup(ctx, 'Add Parameter' .. FxGUID)
                                                    r.ImGui_SetNextWindowPos(ctx, TtlR, TtlB)
                                                    AddPrmPopupOpen = FxGUID
                                                end
                                            end
                                        else
                                            FX[FxGUID].TtlHvr = nil
                                        end
                                    else -- if collapsed
                                        FX.WidthCollapse[FxGUID] = 27

                                        local Name = ChangeFX_Name(FX_Name)

                                        local Name = Name:gsub('%S+', { ['Valhalla'] = "", ['FabFilter'] = "" })
                                        local Name = Name:gsub('-', '|')
                                        --if Name:find('FabFilter Pro%-C 2')  then Name = 'Pro|C 2' end
                                        local Name_V = Name:gsub("(.)", "%1\n")
                                        local Name_V_NoManuFacturer = Name_V:gsub("%b()", "")
                                        r.ImGui_PushStyleVar(ctx, BtnTxtAlign, 0.5, 0.2) --StyleVar#3
                                        r.ImGui_SameLine(ctx, nil, 0)

                                        WindowBtn = r.ImGui_Button(ctx, Name_V_NoManuFacturer, 25, 220)


                                        r.ImGui_PopStyleVar(ctx)             --StyleVar#3 POP
                                    end
                                    r.ImGui_PopStyleColor(ctx, WinbtnClrPop) -- win btn clr
                                    HighlightSelectedItem(nil, 0xffffff11, -1, L, T, R, B, h, w, 1, 1, 'GetItemRect', WDL,
                                        FX.Round[FxGUID] --[[rounding]])


                                    r.ImGui_SetNextWindowSizeConstraints(ctx, AddPrmWin_W or 50, 50, 9999, 500)
                                    local R_ClickOnWindowBtn = r.ImGui_IsItemClicked(ctx, 1)
                                    local L_ClickOnWindowBtn = r.ImGui_IsItemClicked(ctx)

                                    if R_ClickOnWindowBtn and Mods == Ctrl then
                                        r.ImGui_OpenPopup(ctx, 'Fx Module Menu')
                                    elseif R_ClickOnWindowBtn and Mods == 0 then
                                        FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
                                        if not FX[FxGUID].Collapse then FX.WidthCollapse[FxGUID] = nil end
                                    elseif R_ClickOnWindowBtn and Mods == Alt then
                                        -- check if all are collapsed


                                        BlinkFX = ToggleCollapseAll(FX_Idx)
                                    elseif WindowBtn and Mods == 0 then
                                        openFXwindow(LT_Track, FX_Idx)
                                    elseif WindowBtn and Mods == Shift then
                                        ToggleBypassFX(LT_Track, FX_Idx)
                                    elseif WindowBtn and Mods == Alt then
                                        DeleteFX(FX_Idx)
                                    end

                                    if r.ImGui_IsItemHovered(ctx) then
                                        HintMessage =
                                        'Mouse: L=Open FX Window | Shift+L = Toggle Bypass | Alt+L = Delete | R = Collapse | Alt+R = Collapse All'
                                    end


                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Border(), getClr(r.ImGui_Col_FrameBg()))


                                    -- Add Prm popup
                                    PrmFilter = r.ImGui_CreateTextFilter(PrmFilterTxt)
                                    if r.ImGui_BeginPopup(ctx, 'Add Parameter' .. FxGUID, r.ImGui_WindowFlags_AlwaysVerticalScrollbar()) then
                                        local CheckBox, rv = {}, {}
                                        if r.ImGui_Button(ctx, 'Add all parameters', -1) then
                                            for i = 0, r.TrackFX_GetNumParams(LT_Track, FX_Idx) - 1, 1 do
                                                local P_Name = select(2, r.TrackFX_GetParamName(LT_Track, FX_Idx, i))

                                                if not FX[FxGUID][i + 1] then
                                                    StoreNewParam(FxGUID, P_Name, i, FX_Idx, true)
                                                else
                                                    local RptPrmFound
                                                    for I = 1, #FX[FxGUID], 1 do
                                                        if FX[FxGUID][I].Num == i then RptPrmFound = true end
                                                    end

                                                    if not RptPrmFound then
                                                        StoreNewParam(FxGUID, P_Name, i, FX_Idx, true)
                                                        SyncTrkPrmVtoActualValue()
                                                    end
                                                end
                                            end
                                        end


                                        AddPrmPopupOpen = FxGUID
                                        if not PrmFilterTxt then AddPrmWin_W, AddPrmWin_H = r.ImGui_GetWindowSize(ctx) end
                                        r.ImGui_SetWindowSize(ctx, 500, 500, condIn)

                                        local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)


                                        r.ImGui_SetNextItemWidth(ctx, 60)

                                        if not FX[FxGUID].NotFirstOpenPrmWin then
                                            r.ImGui_SetKeyboardFocusHere(ctx, offsetIn)
                                        end

                                        if r.ImGui_TextFilter_Draw(PrmFilter, ctx, '##PrmFilterTxt', -1 - (SpaceForBtn or 0)) then
                                            PrmFilterTxt = r.ImGui_TextFilter_Get(PrmFilter)
                                            r.ImGui_TextFilter_Set(PrmFilter, PrmFilterTxt)
                                        end

                                        for i = 1, Ct, 1 do
                                            if FX[FxGUID][i] then
                                                CheckBox[FX[FxGUID][i].Num] = true
                                            end
                                        end

                                        for i = 1, Ct, 1 do
                                            local P_Name = select(2,
                                                r.TrackFX_GetParamName(LT_Track, FX_Idx, i - 1))
                                            if r.ImGui_TextFilter_PassFilter(PrmFilter, P_Name) then
                                                rv[i], CheckBox[i - 1] = r.ImGui_Checkbox(ctx, (i - 1) .. '. ' .. P_Name,
                                                    CheckBox[i - 1])
                                                if rv[i] then
                                                    local RepeatPrmFound

                                                    for I = 1, Ct, 1 do
                                                        if FX[FxGUID][I] then
                                                            if FX[FxGUID][I].Num == i - 1 then RepeatPrmFound = I end
                                                        end
                                                    end
                                                    if RepeatPrmFound then
                                                        DeletePrm(FxGUID, RepeatPrmFound, FX_Idx)
                                                    else
                                                        StoreNewParam(FxGUID, P_Name, i - 1, FX_Idx, true)
                                                        SyncTrkPrmVtoActualValue()
                                                    end
                                                end
                                            end
                                        end
                                        FX[FxGUID].NotFirstOpenPrmWin = true
                                        r.ImGui_EndPopup(ctx)
                                    elseif AddPrmPopupOpen == FxGUID then
                                        PrmFilterTxt = nil
                                        FX[FxGUID].NotFirstOpenPrmWin = nil
                                    end


                                    r.ImGui_PopStyleColor(ctx)


                                    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                                        local L, T = r.ImGui_GetItemRectMin(ctx); local R, _ = r.ImGui_GetItemRectMax(
                                            ctx); B = T + 20
                                        r.ImGui_DrawList_AddCircleFilled(WinDrawList, R, T + 10, 3, 0x999999ff)
                                        r.ImGui_DrawList_AddRect(WinDrawList, L, T, R, T + 20, 0x999999ff)

                                        if MouseX > L and MouseX < R and MouseY > T and MouseY < B then
                                            r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, T + 20, 0x99999955)
                                            if IsLBtnClicked then
                                                LE.SelectedItem = 'Title'
                                                LE.ChangingTitleSize = true
                                                LE.MouseX_before, _ = r.ImGui_GetMousePos(ctx)
                                            elseif IsRBtnClicked then
                                                r.ImGui_OpenPopup(ctx, 'Fx Module Menu')
                                            end
                                        end

                                        if LE.SelectedItem == 'Title' then
                                            r.ImGui_DrawList_AddRect(WinDrawList, L, T, R,
                                                T + 20, 0x999999ff)
                                        end

                                        if MouseX > R - 5 and MouseX < R + 5 and MouseY > T and MouseY < B then --if hover on right edge
                                            if IsLBtnClicked then LE.ChangingTitleSize = true end
                                        end

                                        if LBtnDrag and LE.ChangingTitleSize then
                                            r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())
                                            DeltaX, DeltaY = r.ImGui_GetMouseDelta(ctx)
                                            local AddedDelta = AddedDelta or 0 + DeltaX
                                            LE.MouseX_after, _ = r.ImGui_GetMousePos(ctx)
                                            local MouseDiff = LE.MouseX_after - LE.MouseX_before

                                            if FX.TitleWidth[FxGUID] == nil then
                                                FX.TitleWidth[FxGUID] = DefaultWidth -
                                                    30
                                            end
                                            if Mods == 0 then
                                                if MouseDiff > LE.GridSize then
                                                    FX.TitleWidth[FxGUID] = FX.TitleWidth[FxGUID] + LE.GridSize; LE.MouseX_before =
                                                        r.ImGui_GetMousePos(ctx); LE.BeenEdited = true
                                                elseif MouseDiff < -LE.GridSize then
                                                    FX.TitleWidth[FxGUID] = FX.TitleWidth[FxGUID] - LE.GridSize; LE.MouseX_before =
                                                        r.ImGui_GetMousePos(ctx); LE.BeenEdited = true
                                                end
                                            end
                                            if Mods == Shift then
                                                FX.TitleWidth[FxGUID] = FX.TitleWidth[FxGUID] + DeltaX; LE.BeenEdited = true
                                            end
                                        end
                                        if IsLBtnHeld == false then LE.ChangingTitleSize = nil end

                                        r.ImGui_EndDisabled(ctx)
                                    end








                                    if DebugMode and r.ImGui_IsItemHovered(ctx) then tooltip(FX_Idx) end
                                    if DebugMode and r.ImGui_IsKeyDown(ctx, 84) then tooltip(TrkID) end





                                    --r.Undo_OnStateChangeEx(string descchange, integer whichStates, integer trackparm) -- @todo Detect FX deletion






                                    if r.ImGui_BeginPopup(ctx, 'Fx Module Menu') then
                                        if not FX[FxGUID].MorphA then
                                            if r.ImGui_Button(ctx, 'Preset Morphing', 160) then
                                                FX[FxGUID].MorphA = {}
                                                FX[FxGUID].MorphB = {}
                                                local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                                for i = 0, PrmCount - 4, 1 do
                                                    local Prm_Val, minval, maxval = r.TrackFX_GetParamNormalized(
                                                        LT_Track, FX_Idx, i)
                                                    FX[FxGUID].MorphA[i] = Prm_Val
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX Morph A' .. i .. FxGUID, Prm_Val, true)
                                                end
                                                RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track, PrmCount)
                                                --[[ r.SetProjExtState(r0oj, 'FX Devices', string key, string value) ]]

                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                        else
                                            if not FX[FxGUID].MorphHide then
                                                if r.ImGui_Button(ctx, 'Hide Morph Slider', 160) then
                                                    FX[FxGUID].MorphHide = true
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX Morph Hide' .. FxGUID, 'true', true)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                            else
                                                if r.ImGui_Button(ctx, 'Show Morph Slider', 160) then
                                                    FX[FxGUID].MorphHide = nil
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                            end
                                        end

                                        r.ImGui_SameLine(ctx)
                                        if not FX[FxGUID].MorphA then
                                            r.ImGui_BeginDisabled(ctx)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),
                                                getClr(r.ImGui_Col_TextDisabled()))
                                        end
                                        if IconBtn(20, 20, 'Y') then -- settings icon
                                            if OpenMorphSettings then
                                                OpenMorphSettings = FxGUID
                                            else
                                                OpenMorphSettings =
                                                    FxGUID
                                            end
                                            local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                            FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                            for i = 0, Ct - 4, 1 do --get param names
                                                FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                                                local rv, name             = r.TrackFX_GetParamName(LT_Track,
                                                    FX_Idx, i)
                                                FX[FxGUID].PrmList[i].Name = name
                                            end
                                            r.ImGui_CloseCurrentPopup(ctx)
                                        end
                                        if not FX[FxGUID].MorphA then
                                            r.ImGui_EndDisabled(ctx)
                                            r.ImGui_PopStyleColor(ctx)
                                        end



                                        if r.ImGui_Button(ctx, 'Layout Edit mode', -FLT_MIN) then
                                            if not FX.LayEdit then
                                                FX.LayEdit = FxGUID
                                            else
                                                FX.LayEdit = false
                                            end
                                            CloseLayEdit = nil
                                            r.ImGui_CloseCurrentPopup(ctx)
                                            if Draw.DrawMode[FxGUID] then Draw.DrawMode[FxGUID] = nil end
                                        end


                                        if r.ImGui_Button(ctx, 'Save all values as default', -FLT_MIN) then
                                            local dir_path = CurrentDirectory .. 'src'
                                            local file_path = ConcatPath(dir_path, 'FX Default Values.ini')
                                            local file = io.open(file_path, 'a+')

                                            if file then
                                                local FX_Name = ChangeFX_Name(FX_Name)
                                                Content = file:read('*a')
                                                local Ct = Content

                                                local pos = Ct:find(FX_Name)
                                                if pos then
                                                    file:seek('set', pos - 1)
                                                else
                                                    file:seek('end')
                                                end

                                                file:write(FX_Name, '\n')
                                                local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                                PrmCount = PrmCount - 4
                                                file:write('Number of Params: ', PrmCount, '\n')

                                                local function write(i, name, Value)
                                                    file:write(i, '. ', name, ' = ', Value or '', '\n')
                                                end

                                                for i = 0, PrmCount, 1 do
                                                    local V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                                    local _, N = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                                    write(i, N, V)
                                                end

                                                file:write('\n')


                                                file:close()
                                            end
                                            r.ImGui_CloseCurrentPopup(ctx)
                                        end



                                        if FX.Def_Type[FxGUID] ~= 'Knob' then
                                            r.ImGui_Text(ctx, 'Default Sldr Width:')
                                            r.ImGui_SameLine(ctx)
                                            local SldrW_DrgSpd
                                            if Mods == Shift then SldrW_DrgSpd = 1 else SldrW_DrgSpd = LE.GridSize end
                                            r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)


                                            Edited, FX.Def_Sldr_W[FxGUID] = r.ImGui_DragInt(ctx,
                                                '##' .. FxGUID .. 'Default Width', FX.Def_Sldr_W[FxGUID] or 160,
                                                LE.GridSize, 50, 300)


                                            if Edited then
                                                r.SetProjExtState(0, 'FX Devices',
                                                    'Default Slider Width for FX:' .. FxGUID, FX.Def_Sldr_W[FxGUID])
                                            end
                                        end



                                        r.ImGui_Text(ctx, 'Default Param Type:')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)


                                        if r.ImGui_BeginCombo(ctx, '## P type', FX.Def_Type[FxGUID] or 'Slider', r.ImGui_ComboFlags_NoArrowButton()) then
                                            if r.ImGui_Selectable(ctx, 'Slider', false) then
                                                FX.Def_Type[FxGUID] = 'Slider'
                                                r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                                    FX.Def_Type[FxGUID])
                                            elseif r.ImGui_Selectable(ctx, 'Knob', false) then
                                                FX.Def_Type[FxGUID] = 'Knob'
                                                r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                                    FX.Def_Type[FxGUID])
                                            elseif r.ImGui_Selectable(ctx, 'Drag', false) then
                                                FX.Def_Type[FxGUID] = 'Drag'
                                                r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                                    FX.Def_Type[FxGUID])
                                            end
                                            r.ImGui_EndCombo(ctx)
                                        end
                                        r.ImGui_EndPopup(ctx)
                                    end
                                    FXModuleMenu_W, FXModuleMenu_H = r.ImGui_GetItemRectSize(ctx)


                                    if OpenMorphSettings then
                                        Open, Oms = r.ImGui_Begin(ctx, 'Preset Morph Settings ', Oms,
                                            r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoDocking())
                                        if Oms then
                                            if FxGUID == OpenMorphSettings then
                                                r.ImGui_Text(ctx, 'Set blacklist parameters here: ')
                                                local SpaceForBtn
                                                Filter = r.ImGui_CreateTextFilter(FilterTxt)
                                                r.ImGui_Text(ctx, 'Filter :')
                                                r.ImGui_SameLine(ctx)
                                                if FilterTxt then SpaceForBtn = 170 end
                                                if r.ImGui_TextFilter_Draw(Filter, ctx, '##', -1 - (SpaceForBtn or 0)) then
                                                    FilterTxt = r.ImGui_TextFilter_Get(Filter)
                                                    r.ImGui_TextFilter_Set(Filter, Txt)
                                                end
                                                if FilterTxt then
                                                    SL()
                                                    BL_All = r.ImGui_Button(ctx, 'Blacklist all results')
                                                end

                                                r.ImGui_Text(ctx, 'Save morphing settings to : ')
                                                SL()
                                                local Save_FX = r.ImGui_Button(ctx, 'FX Instance', 80)
                                                SL()
                                                local Save_Proj = r.ImGui_Button(ctx, 'Project', 80)
                                                SL()
                                                local Save_Glob = r.ImGui_Button(ctx, 'Global', 80)
                                                SL()
                                                local FxNam = FX.Win_Name_S[FX_Idx]:gsub("%b()", "")
                                                demo.HelpMarker(
                                                    'FX Instance: \nBlacklist will only apply to the current instance of' ..
                                                    FxNam ..
                                                    '\n\nProject:\nBlacklist will apply to all instances of ' ..
                                                    FxNam ..
                                                    'in the current project\n\nGlobal:\nBlacklist will be applied to all instances of ' ..
                                                    FxNam ..
                                                    ' across all projects.\n\nOrder of precedence goes from: FX Instance -> Project -> Global')



                                                if Save_FX or Save_Proj or Save_Glob then
                                                    Tooltip_Timer = r.time_precise()
                                                    TTP_x, TTP_y = r.ImGui_GetMousePos(ctx)
                                                    r.ImGui_OpenPopup(ctx, '## Successfully saved preset morph')
                                                end

                                                if Tooltip_Timer then
                                                    if r.ImGui_BeginPopupModal(ctx, '## Successfully saved preset morph', nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                                                        r.ImGui_Text(ctx, 'Successfully saved ')
                                                        if r.ImGui_IsMouseClicked(ctx, 0) then
                                                            r.ImGui_CloseCurrentPopup(
                                                                ctx)
                                                        end
                                                        r.ImGui_EndPopup(ctx)
                                                    end

                                                    if Tooltip_Timer + 3 < r.time_precise() then
                                                        Tooltip_Timer = nil
                                                        TTP_x = nil
                                                        TTP_y = nil
                                                    end
                                                end

                                                --


                                                if not FX[FxGUID].PrmList[1].Name then
                                                    FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                                    --[[ local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                                    for i=0, Ct-4, 1 do
                                                        FX[FxGUID].PrmList[i]=FX[FxGUID].PrmList[i] or {}
                                                        local rv, name = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                                        FX[FxGUID].PrmList[i].Name  = name
                                                    end ]]

                                                    RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track,
                                                        r.TrackFX_GetNumParams(LT_Track, FX_Idx), FX_Name)
                                                else
                                                    r.ImGui_BeginTable(ctx, 'Parameter List', 5,
                                                        r.ImGui_TableFlags_Resizable())
                                                    --r.ImGui_TableSetupColumn( ctx, 'BL',  flagsIn, 20,  user_idIn)

                                                    r.ImGui_TableHeadersRow(ctx)
                                                    r.ImGui_SetNextItemWidth(ctx, 20)
                                                    r.ImGui_TableSetColumnIndex(ctx, 0)

                                                    IconBtn(20, 20, 'M', 0x00000000)

                                                    r.ImGui_TableSetColumnIndex(ctx, 1)
                                                    r.ImGui_AlignTextToFramePadding(ctx)
                                                    r.ImGui_Text(ctx, 'Parameter Name ')
                                                    r.ImGui_TableSetColumnIndex(ctx, 2)
                                                    r.ImGui_AlignTextToFramePadding(ctx)
                                                    r.ImGui_Text(ctx, 'A')
                                                    r.ImGui_TableSetColumnIndex(ctx, 3)
                                                    r.ImGui_AlignTextToFramePadding(ctx)
                                                    r.ImGui_Text(ctx, 'B')
                                                    r.ImGui_TableNextRow(ctx)
                                                    r.ImGui_TableSetColumnIndex(ctx, 0)




                                                    if --[[Last Touch]] LT_ParamNum and LT_FXGUID == FxGUID then
                                                        local P = FX[FxGUID].PrmList
                                                        local N = math.max(LT_ParamNum, 1)
                                                        r.ImGui_TableSetBgColor(ctx, 1,
                                                            getClr(r.ImGui_Col_TabUnfocused()))
                                                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, 9)

                                                        rv, P[N].BL = r.ImGui_Checkbox(ctx, '##' .. N, P[N].BL)
                                                        if P[N].BL then r.ImGui_BeginDisabled(ctx) end

                                                        r.ImGui_TableSetColumnIndex(ctx, 1)
                                                        r.ImGui_Text(ctx, N .. '. ' .. (P[N].Name or ''))


                                                        ------- A --------------------
                                                        r.ImGui_TableSetColumnIndex(ctx, 2)
                                                        r.ImGui_Text(ctx, 'A:')
                                                        SL()
                                                        r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)

                                                        local i = LT_ParamNum or 0
                                                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                                            FX_Idx, i)
                                                        if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                                                            P.FormatV_A =
                                                                GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV, i)
                                                        end


                                                        P.Drag_A, FX[FxGUID].MorphA[i] = r.ImGui_DragDouble(ctx,
                                                            '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1,
                                                            P.FormatV_A or '')
                                                        if P.Drag_A then
                                                            P.FormatV_A = GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV, i)
                                                        end

                                                        SL()
                                                        --------- B --------------------
                                                        r.ImGui_TableSetColumnIndex(ctx, 3)
                                                        r.ImGui_Text(ctx, 'B:')
                                                        SL()

                                                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                                            FX_Idx, i)
                                                        r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                                                        if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                                                            P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV, i)
                                                        end


                                                        P.Drag_B, FX[FxGUID].MorphB[i] = r.ImGui_DragDouble(ctx,
                                                            '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1,
                                                            P.FormatV_B)
                                                        if P.Drag_B then
                                                            P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV, i)
                                                        end


                                                        if P[N].BL then r.ImGui_EndDisabled(ctx) end
                                                        --HighlightSelectedItem( 0xffffff33 , OutlineClr, 1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect', Foreground)

                                                        r.ImGui_PopStyleVar(ctx)
                                                        r.ImGui_TableNextRow(ctx)
                                                        r.ImGui_TableSetColumnIndex(ctx, 0)
                                                    end
                                                    local Load_FX_Proj_Glob
                                                    local _, FXsBL = r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: Morph_BL' .. FxGUID, '', false)
                                                    if FXsBL == 'Has Blacklist saved to FX' then -- if there's FX-specific BL settings
                                                        Load_FX_Proj_Glob = 'FX'
                                                    else
                                                        local _, whether = r.GetProjExtState(0,
                                                            'FX Devices - Preset Morph',
                                                            'Whether FX has Blacklist' .. (FX.Win_Name_S[FX_Idx] or ''))
                                                        if whether == 'Yes' then Load_FX_Proj_Glob = 'Proj' end
                                                    end

                                                    local TheresBL = TheresBL or {}
                                                    local hasBL
                                                    for i, v in ipairs(FX[FxGUID].PrmList) do
                                                        local P = FX[FxGUID].PrmList[i - 1]
                                                        local prm = FX[FxGUID].PrmList

                                                        if r.ImGui_TextFilter_PassFilter(Filter, P.Name) --[[ and (i~=LT_ParamNum and LT_FXGUID==FxGUID) ]] then
                                                            i = i - 1
                                                            if prm[i].BL == nil then
                                                                if Load_FX_Proj_Glob == 'FX' then
                                                                    local _, V = r.GetSetMediaTrackInfo_String(
                                                                        LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID .. i, '', false)
                                                                    if V == 'Blacklisted' then prm[i].BL = true end
                                                                end
                                                                --[[  elseif Load_FX_Proj_Glob== 'Proj' then
                                                                    local rv, BLprm  = r.GetProjExtState(0,'FX Devices - Preset Morph', FX.Win_Name_S[FX_Idx]..' Blacklist '..i)
                                                                    if BLprm~='' and BLprm then  BLpm = tonumber(BLprm)
                                                                        if BLprm then prm[1].BL = true  end
                                                                    end
                                                                end ]]
                                                            end
                                                            if BL_All --[[BL all filtered params ]] then if P.BL then P.BL = false else P.BL = true end end
                                                            rv, prm[i].BL = r.ImGui_Checkbox(ctx, '## BlackList' .. i,
                                                                prm[i].BL)

                                                            r.ImGui_TableSetColumnIndex(ctx, 1)
                                                            if P.BL then
                                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),
                                                                    getClr(r.ImGui_Col_TextDisabled()))
                                                            end


                                                            r.ImGui_Text(ctx, i .. '. ' .. (P.Name or ''))



                                                            ------- A --------------------
                                                            r.ImGui_TableSetColumnIndex(ctx, 2)
                                                            r.ImGui_Text(ctx, 'A:')
                                                            SL()

                                                            local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                                                FX_Idx,
                                                                i)
                                                            r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                                                            if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                                                                P.FormatV_A =
                                                                    GetFormatPrmV(FX[FxGUID].MorphA[i + 1], OrigV, i)
                                                            end


                                                            P.Drag_A, FX[FxGUID].MorphA[i] = r.ImGui_DragDouble(ctx,
                                                                '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1,
                                                                P.FormatV_A or '')
                                                            if P.Drag_A then
                                                                P.FormatV_A = GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV,
                                                                    i)
                                                                --[[ r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, FX[FxGUID].MorphA[i])
                                                                _,P.FormatV_A = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,i)
                                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, OrigV)  ]]
                                                            end

                                                            SL()

                                                            --------- B --------------------
                                                            r.ImGui_TableSetColumnIndex(ctx, 3)
                                                            r.ImGui_Text(ctx, 'B:')
                                                            SL()

                                                            local OrigV = r.TrackFX_GetParamNormalized(LT_Track,
                                                                FX_Idx,
                                                                i)
                                                            r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                                                            if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                                                                P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i] or 0,
                                                                    OrigV, i)
                                                            end

                                                            P.Drag_B, FX[FxGUID].MorphB[i] = r.ImGui_DragDouble(ctx,
                                                                '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1,
                                                                P.FormatV_B)
                                                            if P.Drag_B then
                                                                P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV,
                                                                    i)
                                                            end


                                                            if Save_FX then
                                                                if P.BL then
                                                                    hasBL = true
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID .. i, 'Blacklisted',
                                                                        true)
                                                                else
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID .. i, '', true)
                                                                end
                                                                if hasBL then
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID,
                                                                        'Has Blacklist saved to FX', true)
                                                                else
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID, '', true)
                                                                end
                                                            elseif Save_Proj then
                                                                if P.BL then table.insert(TheresBL, i) end
                                                            elseif Save_Glob then
                                                                if P.BL then table.insert(TheresBL, i) end
                                                            end

                                                            r.ImGui_SetNextItemWidth(ctx, -1)

                                                            if P.BL then r.ImGui_PopStyleColor(ctx) end

                                                            r.ImGui_TableNextRow(ctx)
                                                            r.ImGui_TableSetColumnIndex(ctx, 0)
                                                        end
                                                    end

                                                    if Save_Proj then
                                                        if TheresBL[1] then
                                                            r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                'Whether FX has Blacklist' .. FX.Win_Name_S[FX_Idx],
                                                                'Yes')
                                                        else
                                                            r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                'Whether FX has Blacklist' .. FX.Win_Name_S[FX_Idx], 'No')
                                                        end
                                                        for i, V in ipairs(FX[FxGUID].MorphA) do
                                                            local PrmBLed
                                                            for I, v in ipairs(TheresBL) do
                                                                if i == v then PrmBLed = v end
                                                            end
                                                            if PrmBLed then
                                                                r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                    FX.Win_Name_S[FX_Idx] .. ' Blacklist ' .. i, PrmBLed)
                                                            else
                                                                r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                    FX.Win_Name_S[FX_Idx] .. ' Blacklist ' .. i, '')
                                                            end
                                                        end
                                                        --else r.SetProjExtState(0,'FX Devices - Preset Morph','Whether FX has Blacklist'..FX.Win_Name_S[FX_Idx], '')
                                                    elseif TheresBL[1] and Save_Glob then
                                                        file, file_path = CallFile('w', FX.Win_Name_S[FX_Idx] .. '.ini',
                                                            'Preset Morphing')
                                                        if file then
                                                            for i, V in ipairs(TheresBL) do
                                                                file:write(i, ' = ', V, '\n')
                                                            end
                                                            file:close()
                                                        end
                                                    end

                                                    r.ImGui_EndTable(ctx)
                                                end
                                            end
                                            r.ImGui_End(ctx)
                                        else
                                            r.ImGui_End(ctx)
                                            OpenMorphSettings = false
                                        end
                                    end

                                    ------------------------------------------
                                    ------ Collapse Window
                                    ------------------------------------------

                                    FX_Idx = FX_Idx or 1


                                    if R_Click_WindowBtnVertical then
                                        FX[FXGUID[FX_Idx]].Collapse = false
                                    end



                                    r.gmem_attach('ParamValues')
                                    FX.Win_Name_S[FX_Idx] = ChangeFX_Name(FX.Win_Name[FX_Idx])

                                    FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
                                    FX_Name = string.gsub(FX_Name, '%-', ' ')





                                    ----==  Drag and drop----
                                    if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                                        DragFX_ID = FX_Idx
                                        r.ImGui_SetDragDropPayload(ctx, 'FX_Drag', FX_Idx)
                                        r.ImGui_EndDragDropSource(ctx)

                                        DragDroppingFX = true
                                        if IsAnyMouseDown == false then DragDroppingFX = false end
                                        HighlightSelectedItem(0xffffff22, 0xffffffff, 0, L, T, R, B, h, w, H_OutlineSc,
                                            V_OutlineSc, 'GetItemRect', WDL)
                                        Post_DragFX_ID = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                                    end

                                    if IsAnyMouseDown == false and DragDroppingFX == true then
                                        DragDroppingFX = false
                                    end

                                    ----Drag and drop END----

                                    r.ImGui_SameLine(ctx)

                                    --------------------------------
                                    ----Area right of window title
                                    --------------------------------
                                    function SyncWetValues()
                                        --when track change
                                        if Wet.Val[FX_Idx] == nil or TrkID ~= TrkID_End or FXCountEndLoop ~= Sel_Track_FX_Count then -- if it's nil
                                            SyncWetValues = true
                                        end

                                        if SyncWetValues == true then
                                            Wet.P_Num[FX_Idx] = r.TrackFX_GetParamFromIdent(LT_Track, FX_Idx,
                                                ':wet')
                                            Wet.Get = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                Wet.P_Num[FX_Idx])
                                            Wet.Val[FX_Idx] = Wet.Get
                                        end
                                        if SyncWetValues == true and FX_Idx == Sel_Track_FX_Count - 1 then
                                            SyncWetValues = false
                                        end
                                        if LT_ParamNum == Wet.P_Num[FX_Idx] and focusedFXState == 1 then
                                            Wet.Get = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                Wet.P_Num[FX_Idx])
                                            Wet.Val[FX_Idx] = Wet.Get
                                        elseif LT_ParamNum == FX[FxGUID].DeltaP then
                                            FX[FxGUID].DeltaP_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                FX[FxGUID].DeltaP)
                                        end
                                    end

                                    if FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                                        SyncWetValues()

                                        if FX[FXGUID[FX_Idx]].Collapse ~= true then
                                            Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '',
                                                Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)
                                        end

                                        if r.ImGui_BeginDragDropTarget(ctx) then
                                            rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                                            if rv then
                                            end
                                            r.ImGui_EndDragDropTarget(ctx)
                                        end
                                    end
                                    -- r.ImGui_PopStyleVar(ctx) --StyleVar#4  POP (Things in the header of FX window)

                                    ------------------------------------------
                                    ------ Generic FX's knobs and sliders area
                                    ------------------------------------------
                                    if not FX[FXGUID[FX_Idx]].Collapse and FindStringInTable(BlackListFXs, FX_Name) ~= true and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                                        local WinP_X; local WinP_Y;
                                        --_, foo = AddKnob(ctx, 'test', foo or 0  , 0, 100 )
                                        if FX.Enable[FX_Idx] == true then
                                            -- Params Colors-----
                                            --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x32403aff)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x44444488)

                                            times = 2 ]]
                                        else
                                            --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x17171744)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0x66666644)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), 0x66666644)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x66666622)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), 0x44444422)
                                            times = 5 ]]
                                        end

                                        if FX.Round[FxGUID] then
                                            r.ImGui_PushStyleVar(ctx,
                                                r.ImGui_StyleVar_FrameRounding(), FX.Round[FxGUID])
                                        end
                                        if FX.GrbRound[FxGUID] then
                                            r.ImGui_PushStyleVar(ctx,
                                                r.ImGui_StyleVar_GrabRounding(), FX.GrbRound[FxGUID])
                                        end

                                        if (FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true) and Mods ~= Apl then
                                            r.ImGui_BeginDisabled(ctx, true)
                                        end
                                        if FX.LayEdit then
                                            LE.DragX, LE.DragY = r.ImGui_GetMouseDragDelta(ctx, 0)
                                        end

                                        ------------------------------------------------------
                                        -- Repeat as many times as stored Param on FX -------------
                                        ------------------------------------------------------
                                        --[[ for Fx_P, v in ipairs(FX[FxGUID])    do
                                            if not FX[FxGUID][Fx_P].Name then table.remove(FX[FxGUID],Fx_P) end
                                        end ]]
                                        for Fx_P, v in ipairs(FX[FxGUID]) do --parameter faders
                                            --FX[FxGUID][Fx_P]= FX[FxGUID][Fx_P] or {}

                                            local FP = FX[FxGUID][Fx_P] ---@class FX_P

                                            local F_Tp = FX.Prm.ToTrkPrm[FXGUID[FX_Idx] .. Fx_P]; local ID = FxGUID ..
                                                Fx_P
                                            Rounding = 0.5

                                            ParamX_Value = 'Param' ..
                                                tostring(FP.Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID

                                            ----Default Layouts
                                            if not FP.PosX and not FP.PosY then
                                                if FP.Type == 'Slider' or (not FP.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' or FP.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag' and FP.Type == nil) then
                                                    local Column = math.floor((Fx_P / 6) - 0.01)
                                                    local W = ((FX[FxGUID][Fx_P - Column * 6].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160) + GapBtwnPrmColumns) *
                                                        Column
                                                    local Y = 30 * (Fx_P - (Column * 6))
                                                    r.ImGui_SetCursorPos(ctx, W, Y)
                                                elseif FP.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider' and FP.Type == nil) then
                                                    r.ImGui_SetCursorPos(ctx, 17 * (Fx_P - 1), 30)
                                                elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and FP.Type == nil) then
                                                    local KSz = Df.KnobSize
                                                    local G = 15
                                                    local Column = math.floor(Fx_P / 3 - 0.1)

                                                    r.ImGui_SetCursorPos(ctx, KSz * (Column),
                                                        26 + (KSz + G) * (Fx_P - (Column * 3) - 1))
                                                end
                                            end

                                            if FP.PosX then r.ImGui_SetCursorPosX(ctx, FP.PosX) end
                                            if FP.PosY then r.ImGui_SetCursorPosY(ctx, FP.PosY) end

                                            rectminX, RectMinY = r.ImGui_GetItemRectMin(ctx)
                                            curX, CurY = r.ImGui_GetCursorPos(ctx)
                                            if CurY > 210 then
                                                r.ImGui_SetCursorPosY(ctx, 210)
                                                CurY = 210
                                            end
                                            if curX < 0 then
                                                r.ImGui_SetCursorPosX(ctx, 0)
                                            elseif curX > (FX.Width[FxGUID] or DefaultWidth) then
                                                r.ImGui_SetCursorPosX(ctx, (FX.Width[FxGUID] or DefaultWidth) - 10)
                                            end

                                            -- if prm has clr set, calculate colors for active and hvr clrs
                                            if FP.BgClr then
                                                local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(FP.BgClr)
                                                local H, S, V = r.ImGui_ColorConvertRGBtoHSV(R, G, B)
                                                local HvrV, ActV
                                                if V > 0.9 then
                                                    HvrV = V - 0.1
                                                    ActV = V - 0.5
                                                end
                                                local R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, HvrV or V +
                                                    0.1)
                                                local HvrClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
                                                local R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, ActV or V + 0.2)
                                                local ActClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
                                                FP.BgClrHvr = HvrClr
                                                FP.BgClrAct = ActClr
                                            end


                                            --- if there's condition for parameters --------
                                            local CreateParam, ConditionPrms, Pass = nil, {}, {}

                                            ---@param ConditionPrm "ConditionPrm"
                                            ---@param ConditionPrm_PID "ConditionPrm_PID"
                                            ---@param ConditionPrm_V_Norm "ConditionPrm_V_Norm"
                                            ---@param ConditionPrm_V "ConditionPrm_V"
                                            ---@return boolean
                                            local function CheckIfCreate(ConditionPrm, ConditionPrm_PID,
                                                                         ConditionPrm_V_Norm, ConditionPrm_V)
                                                local Pass -- TODO should this be initialized to false?
                                                if FP[ConditionPrm] then
                                                    if not FX[FxGUID][Fx_P][ConditionPrm_PID] then
                                                        for i, v in ipairs(FX[FxGUID]) do
                                                            if v.Num == FX[FxGUID][Fx_P][ConditionPrm] then
                                                                FX[FxGUID][Fx_P][ConditionPrm_PID] =
                                                                    i
                                                            end
                                                        end
                                                    end
                                                    local PID = FP[ConditionPrm_PID]

                                                    if FX[FxGUID][PID].ManualValues then
                                                        local V = round(
                                                            r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                FP[ConditionPrm]),
                                                            3)
                                                        if FP[ConditionPrm_V_Norm] then
                                                            for i, v in ipairs(FP[ConditionPrm_V_Norm]) do
                                                                if V == round(v, 3) then Pass = true end
                                                            end
                                                        end
                                                    else
                                                        local _, V = r.TrackFX_GetFormattedParamValue(LT_Track,
                                                            FX_Idx,
                                                            FP[ConditionPrm])
                                                        for i, v in ipairs(FP[ConditionPrm_V]) do
                                                            if V == v then Pass = true end
                                                        end
                                                    end
                                                else
                                                    Pass = true
                                                end
                                                return Pass
                                            end

                                            if FP['ConditionPrm'] then
                                                if CheckIfCreate('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V_Norm', 'ConditionPrm_V') then
                                                    local DontCretePrm
                                                    for i = 2, 5, 1 do
                                                        if CheckIfCreate('ConditionPrm' .. i, 'ConditionPrm_PID' .. i, 'ConditionPrm_V_Norm' .. i, 'ConditionPrm_V' .. i) then
                                                        else
                                                            DontCretePrm = true
                                                        end
                                                    end
                                                    if not DontCretePrm then CreateParam = true end
                                                end
                                            end




                                            if CreateParam or not FP.ConditionPrm then
                                                local Prm = FP
                                                local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]




                                                if Prm then
                                                    DL_SPLITER = r.ImGui_CreateDrawListSplitter(WDL)
                                                    r.ImGui_DrawListSplitter_Split(DL_SPLITER, 2)
                                                    r.ImGui_DrawListSplitter_SetCurrentChannel(DL_SPLITER, 1)

                                                    --Prm.V = Prm.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Prm.Num)
                                                    --- Add Parameter controls ---------
                                                    if Prm.Type == 'Slider' or (not Prm.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' then
                                                        AddSlider(ctx, '##' .. (Prm.Name or Fx_P), Prm.CustomLbl,
                                                            Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Style,
                                                            Prm.Sldr_W or FX.Def_Sldr_W[FxGUID], 0, Disable, Vertical,
                                                            GrabSize, Prm.Lbl, 8)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Sldr', curX, CurY)
                                                    elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and Prm.Type == nil) then
                                                        AddKnob(ctx, '##' .. Prm.Name, Prm.CustomLbl, Prm.V, 0, 1, Fx_P,
                                                            FX_Idx, Prm.Num, Prm.Style, Prm.Sldr_W or Df.KnobRadius, 0,
                                                            Disabled, Prm.FontSize, Prm.Lbl_Pos or 'Bottom', Prm.V_Pos)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Knob', curX, CurY)
                                                    elseif Prm.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider') then
                                                        AddSlider(ctx, '##' .. Prm.Name, Prm.CustomLbl, Prm.V or 0, 0, 1,
                                                            Fx_P, FX_Idx, Prm.Num, Style, Prm.Sldr_W or 15, 0, Disable,
                                                            'Vert', GrabSize, Prm.Lbl, nil, Prm.Sldr_H or 160)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'V-Slider', curX, CurY)
                                                    elseif Prm.Type == 'Switch' then
                                                        AddSwitch(LT_Track, FX_Idx, Prm.V or 0, Prm.Num, Prm
                                                            .BgClr,
                                                            Prm.CustomLbl or 'Use Prm Name as Lbl', Fx_P, F_Tp,
                                                            Prm.FontSize, FxGUID)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Switch', curX, CurY)
                                                    elseif Prm.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag') then
                                                        AddDrag(ctx, '##' .. Prm.Name, Prm.CustomLbl or Prm.Name,
                                                            Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Prm.Style,
                                                            Prm.Sldr_W or FX.Def_Sldr_W[FxGUID] or Df.Sldr_W, -1, Disable,
                                                            Lbl_Clickable, Prm.Lbl_Pos, Prm.V_Pos, Prm.DragDir)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Drag', curX, CurY)
                                                    elseif Prm.Type == 'Selection' then
                                                        AddCombo(ctx, LT_Track, FX_Idx,
                                                            Prm.Name .. FxGUID .. '## actual',
                                                            Prm.Num,
                                                            FP.ManualValuesFormat or 'Get Options', Prm.Sldr_W, Prm
                                                            .Style, FxGUID, Fx_P, FP.ManualValues)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Selection', curX,
                                                            CurY)
                                                    end

                                                    if r.ImGui_IsItemClicked(ctx) and LBtnDC then
                                                        if Mods == 0 then
                                                            local dir_path = CurrentDirectory .. 'src'
                                                            local file_path = ConcatPath(dir_path,
                                                                'FX Default Values.ini')
                                                            local file = io.open(file_path, 'r')

                                                            if file then
                                                                local FX_Name = ChangeFX_Name(FX_Name)
                                                                Content = file:read('*a')
                                                                local Ct = Content
                                                                local P_Num = Prm.Num
                                                                local _, P_Nm = r.TrackFX_GetParamName(LT_Track,
                                                                    FX_Idx,
                                                                    P_Num)
                                                                local Df = RecallGlobInfo(Ct,
                                                                    P_Num .. '. ' .. P_Nm .. ' = ', 'Num')
                                                                if Df then
                                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                        P_Num,
                                                                        Df)
                                                                    ToDef = { ID = FX_Idx, P = P_Num, V = Df }
                                                                end
                                                            end
                                                        elseif Mods == Alt then
                                                            if Prm.Deletable then
                                                                DeletePrm(FxGUID, Fx_P, FX_Idx)
                                                            end
                                                        end
                                                    end

                                                    if ToDef.ID and ToDef.V then
                                                        r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P,
                                                            ToDef
                                                            .V)
                                                        if Prm.WhichCC then
                                                            if Trk.Prm.WhichMcros[Prm.WhichCC .. TrkID] then
                                                                Unlink_Parm(LT_TrackNum, ToDef.ID, ToDef.P)
                                                                r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID,
                                                                    ToDef.P,
                                                                    ToDef.V)
                                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                                    'P_EXT: FX' ..
                                                                    FxGUID ..
                                                                    'Prm' .. ToDef.P .. 'Value before modulation',
                                                                    ToDef.V, true)
                                                                r.gmem_write(7, Prm.WhichCC) --tells jsfx to retrieve P value
                                                                PM.TimeNow = r.time_precise()
                                                                r.gmem_write(11000 + Prm.WhichCC, ToDef.V)
                                                                Link_Param_to_CC(LT_TrackNum, ToDef.ID, ToDef.P, true,
                                                                    true, 176, Prm.WhichCC)
                                                            end
                                                        end
                                                        Prm.V = ToDef.V

                                                        ToDef = {}
                                                    end


                                                    if FP.Draw then
                                                        r.ImGui_DrawListSplitter_SetCurrentChannel(DL_SPLITER, 0)

                                                        local function Repeat(rpt, va, Xgap, Ygap, func, Gap, RPTClr, CLR)
                                                            if rpt and rpt ~= 0 then
                                                                local RPT = rpt
                                                                if va and va ~= 0 then RPT = rpt * Prm.V * va end
                                                                for i = 0, RPT - 1, 1 do
                                                                    local Clr = BlendColors(CLR or 0xffffffff,
                                                                        RPTClr or 0xffffffff, i / RPT)

                                                                    func(i * (Xgap or 0), i * (Ygap or 0), i * (Gap or 0),
                                                                        Clr)
                                                                end
                                                            else
                                                                func(Xgap)
                                                            end
                                                        end






                                                        for i, v in ipairs(FP.Draw) do
                                                            local x, y              = r.ImGui_GetItemRectMin(ctx)
                                                            local x                 = x + (v.X_Offset or 0) +
                                                                (Prm.V * (v.X_Offset_VA or 0))
                                                            local y                 = y + (v.Y_Offset or 0) +
                                                                (Prm.V * (v.Y_Offset_VA or 0))
                                                            local Thick             = (v.Thick or 2)
                                                            local Gap, X_Gap, Y_Gap = v.Gap, v.X_Gap, v.Y_Gap
                                                            local Clr_VA
                                                            if v.Clr_VA then
                                                                Clr_VA = BlendColors(v.Clr or 0xffffffff,
                                                                    v.Clr_VA, Prm.V)
                                                            end



                                                            if v.X_Gap_VA and v.X_Gap_VA ~= 0 then
                                                                X_Gap = (v.X_Gap or 0) *
                                                                    Prm.V * v.X_Gap_VA
                                                            end
                                                            if v.Y_Gap_VA and v.Y_Gap_VA ~= 0 then
                                                                Y_Gap = (v.Y_Gap or 0) *
                                                                    Prm.V * v.Y_Gap_VA
                                                            end

                                                            if v.Gap_VA and v.Gap_VA ~= 0 then
                                                                Gap = v.Gap * Prm.V *
                                                                    v.Gap_VA
                                                            end

                                                            if v.Thick_VA then
                                                                Thick = (v.Thick or 2) *
                                                                    (v.Thick_VA * Prm.V)
                                                            end

                                                            if v.Type == 'Line' or v.Type == 'Rect' or v.Type == 'Rect Filled' then
                                                                local w = v.Width or r.ImGui_GetItemRectSize(ctx)
                                                                local h = v.Height or
                                                                    select(2, r.ImGui_GetItemRectSize(ctx))

                                                                local x2 = x + w
                                                                local y2 = y + h

                                                                if v.Width_VA and v.Width_VA ~= 0 then
                                                                    x2 = x +
                                                                        (w or 10) * Prm.V * (v.Width_VA)
                                                                end
                                                                if v.Height_VA and v.Height_VA ~= 0 then
                                                                    y2 = y +
                                                                        (h or 10) * Prm.V * (v.Height_VA)
                                                                end


                                                                TESTCLR = HSV_Change(0xff00ff, 0, 0, 0.7)

                                                                if v.Type == 'Line' then
                                                                    if Prm.Type == 'Slider' or Prm.Type == 'Drag' or (not Prm.Type) then
                                                                        v.Height = v.Height or 0; v.Width = v.Width or w
                                                                        h        = v.Height or 0; w = v.Width or w
                                                                    elseif Prm.Type == 'V-Slider' then
                                                                        v.Height = v.Height or h; v.Width = v.Width or 0
                                                                        h = v.Height or h; w = v.Width or 0
                                                                    end


                                                                    local function Addline(Xg, Yg, none, RptClr)
                                                                        r.ImGui_DrawList_AddLine(WDL, x + (Xg or 0),
                                                                            y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0),
                                                                            RptClr or Clr_VA or v.Clr or 0xffffffff,
                                                                            Thick)
                                                                    end

                                                                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, Addline,
                                                                        nil, v.RPT_Clr, v.Clr)
                                                                elseif v.Type == 'Rect' then
                                                                    local function AddRect(Xg, Yg, none, RptClr)
                                                                        r.ImGui_DrawList_AddRect(WDL, x + (Xg or 0),
                                                                            y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0),
                                                                            RptClr or Clr_VA or v.Clr or 0xffffffff,
                                                                            v.Round, flag, Thick)
                                                                    end
                                                                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddRect,
                                                                        nil, v.RPT_Clr, v.Clr)
                                                                elseif v.Type == 'Rect Filled' then
                                                                    local function AddRectFill(Xg, Yg, none, RptClr)
                                                                        r.ImGui_DrawList_AddRectFilled(WDL, x + (Xg or 0),
                                                                            y + (Yg or 0), x2 + (Xg or 0), y2 + (Yg or 0),
                                                                            RptClr or Clr_VA or v.Clr or 0xffffffff,
                                                                            v.Round)
                                                                    end
                                                                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap,
                                                                        AddRectFill, nil, v.RPT_Clr, v.Clr)
                                                                end

                                                                if v.AdjustingX or v.AdjustingY then
                                                                    local l = 4
                                                                    r.ImGui_DrawList_AddLine(WDL, x - l, y - l, x + l,
                                                                        y + l, 0xffffffdd)
                                                                    r.ImGui_DrawList_AddLine(WDL, x - l, y + l, x + l,
                                                                        y - l, 0xffffffdd)
                                                                end
                                                            elseif v.Type == 'Circle' or v.Type == 'Circle Filled' then
                                                                local w, h = 10
                                                                if Prm.Type == 'Knob' then
                                                                    w, h = r
                                                                        .ImGui_GetItemRectSize(ctx)
                                                                else
                                                                    v.Width = v.Width or
                                                                        10
                                                                end
                                                                local Rad = v.Width or w
                                                                if v.Width_VA and v.Width_VA ~= 0 then
                                                                    Rad = Rad * Prm.V *
                                                                        v.Width_VA
                                                                end

                                                                local function AddCircle(X_Gap, Y_Gap, Gap, RptClr)
                                                                    r.ImGui_DrawList_AddCircle(WDL,
                                                                        x + w / 2 + (X_Gap or 0),
                                                                        y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0),
                                                                        RptClr or Clr_VA or v.Clr or 0xffffffff, nil,
                                                                        Thick)
                                                                end
                                                                local function AddCircleFill(X_Gap, Y_Gap, Gap, RptClr)
                                                                    r.ImGui_DrawList_AddCircleFilled(WDL,
                                                                        x + w / 2 + (X_Gap or 0),
                                                                        y + w / 2 + (Y_Gap or 0), Rad + (Gap or 0),
                                                                        RptClr or Clr_VA or v.Clr or 0xffffffff)
                                                                end


                                                                if v.Type == 'Circle' then
                                                                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap, AddCircle,
                                                                        Gap, v.RPT_Clr, v.Clr)
                                                                elseif v.Type == 'Circle Filled' then
                                                                    Repeat(v.Repeat, v.Repeat_VA, X_Gap, Y_Gap,
                                                                        AddCircleFill, Gap, v.RPT_Clr, v.Clr)
                                                                end

                                                                if v.AdjustingX or v.AdjustingY then
                                                                    local l = 4
                                                                    local x, y = x + Rad / 2, y + Rad / 2
                                                                    r.ImGui_DrawList_AddLine(WDL, x - l, y - l, x + l,
                                                                        y + l, 0xffffffdd)
                                                                    r.ImGui_DrawList_AddLine(WDL, x - l, y + l, x + l,
                                                                        y - l, 0xffffffdd)
                                                                end
                                                            elseif v.Type == 'Knob Pointer' or v.Type == 'Knob Range' or v.Type == 'Knob Image' or v.Type == 'Knob Circle' then
                                                                local w, h = r.ImGui_GetItemRectSize(ctx)
                                                                local x, y = x + w / 2 + (v.X_Offset or 0),
                                                                    y + h / 2 + (v.Y_Offset or 0)
                                                                local ANGLE_MIN = 3.141592 * (v.Angle_Min or 0.75)
                                                                local ANGLE_MAX = 3.141592 * (v.Angle_Max or 2.25)
                                                                local t = (Prm.V - 0) / (1 - 0)
                                                                local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
                                                                local angle_cos, angle_sin = math.cos(angle),
                                                                    math.sin(angle)
                                                                local IN = v.Rad_In or
                                                                    0 -- modify this for the center begin point
                                                                local OUT = v.Rad_Out or 30

                                                                if v.Type == 'Knob Pointer' then
                                                                    r.ImGui_DrawList_AddLine(WDL, x + angle_cos * IN,
                                                                        y + angle_sin * IN, x + angle_cos * (OUT - Thick),
                                                                        y + angle_sin * (OUT - Thick),
                                                                        Clr_VA or v.Clr or 0x999999aa, Thick)
                                                                elseif v.Type == 'Knob Range' then
                                                                    local function AddRange(G)
                                                                        for i = IN, OUT, (1 + (v.Gap or 0)) do
                                                                            r.ImGui_DrawList_PathArcTo(WDL, x, y, i,
                                                                                ANGLE_MIN,
                                                                                SetMinMax(
                                                                                    ANGLE_MIN +
                                                                                    (ANGLE_MAX - ANGLE_MIN) * Prm.V,
                                                                                    ANGLE_MIN, ANGLE_MAX))
                                                                            r.ImGui_DrawList_PathStroke(WDL,
                                                                                Clr_VA or v.Clr or 0x999999aa, nil, Thick)
                                                                            r.ImGui_DrawList_PathClear(WDL)
                                                                        end
                                                                    end


                                                                    Repeat(1, 0, X_Gap, X_Gap, AddRange)
                                                                elseif v.Type == 'Knob Circle' then
                                                                    r.ImGui_DrawList_AddCircle(WDL, x + angle_cos * IN,
                                                                        y + angle_sin * IN, v.Width,
                                                                        Clr_VA or v.Clr or 0x999999aa, nil, Thick)
                                                                elseif v.Type == 'Knob Image' and v.Image then
                                                                    local X, Y = x + angle_cos * IN, y + angle_sin * IN
                                                                    r.ImGui_DrawList_AddImage(WDL, v.Image, X, Y,
                                                                        X + v.Width, Y + v.Width, nil, nil, nil, nil,
                                                                        Clr_VA or v.Clr or 0x999999aa)
                                                                end



                                                                if v.AdjustingX or v.AdjustingY then
                                                                    local l = 4

                                                                    r.ImGui_DrawList_AddLine(WDL, x - l, y - l, x + l,
                                                                        y + l, 0xffffffdd)
                                                                    r.ImGui_DrawList_AddLine(WDL, x - l, y + l, x + l,
                                                                        y - l, 0xffffffdd)
                                                                end
                                                            elseif v.Type == 'Image' and v.Image then
                                                                local w, h = r.ImGui_Image_GetSize(v.Image)
                                                                local w, h = (v.Width or w), (v.Height or h)
                                                                if v.Width_VA and v.Width_VA ~= 0 then
                                                                    w = (v.Width or w) *
                                                                        v.Width_VA * Prm.V
                                                                end
                                                                if v.Height_VA and v.Height_VA ~= 0 then
                                                                    h = (v.Height or h) *
                                                                        v.Height_VA * Prm.V
                                                                end
                                                                local function AddImage(X_Gap, Y_Gap, none, RptClr)
                                                                    r.ImGui_DrawList_AddImage(WDL, v.Image, x + X_Gap,
                                                                        y + (Y_Gap or 0), x + w + X_Gap,
                                                                        y + h + (Y_Gap or 0), 0, 0, 1, 1,
                                                                        RptClr or Clr_VA or v.Clr)
                                                                end


                                                                Repeat(v.Repeat, v.Repeat_VA, v.X_Gap or 0, v.Y_Gap or 0,
                                                                    AddImage, nil, v.RPT_Clr, v.Clr)
                                                            end
                                                        end
                                                    end
                                                    r.ImGui_DrawListSplitter_Merge(DL_SPLITER)
                                                    --Try another method: use undo history to detect if user has changed a preset, if so, unlink all params
                                                    --[[ if r.TrackFX_GetOpen(LT_Track, FX_Idx) and focusedFXState==1 and FX_Index_FocusFX==FX_Idx then

                                                        if FX[FxGUID].Morph_ID and not FP.UnlinkedModTable then
                                                            _,TrackStateChunk, FXStateChunk, FP.UnlinkedModTable= GetParmModTable(LT_TrackNum, FX_Idx, Prm.Num, TableIndex_Str)
                                                            Unlink_Parm (trackNumOfFocusFX, FX_Idx, Prm.Num )
                                                            FocusedFX = FX_Idx
                                                        end
                                                    elseif focusedFXState==0 and UnlinkedModTable then

                                                    end --FX_Index_FocusFX
                                                    if FP.UnlinkedModTable then
                                                        if not r.TrackFX_GetOpen(LT_Track, FocusedFX) then -- if the fx is closed
                                                            Link_Param_to_CC(LT_TrackNum, FocusedFX, Prm.Num, true, true, 160, FX[FxGUID].Morph_ID, UnlinkedModTable['PARAMOD_BASELINE'], UnlinkedModTable['PARMLINK_SCALE'])
                                                            FocusedFX=nil      FP.UnlinkedModTable = nil
                                                        end
                                                    end ]]
                                                end

                                                if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                                                    r.ImGui_OpenPopup(ctx, '##prm Context menu' .. FP.Num)
                                                end
                                                if r.ImGui_BeginPopup(ctx, '##prm Context menu' .. FP.Num) then
                                                    if r.ImGui_Selectable(ctx, 'Add Parameter to Envelope', false) then
                                                        local env = r.GetFXEnvelope(LT_Track, 0, FP.Num, true)
                                                        local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, Tp, faderScaling =
                                                            r.BR_EnvGetProperties(env)

                                                        r.BR_EnvSetProperties(env, true, true, armed, inLane, laneHeight,
                                                            defaultShape, faderScaling)
                                                        r.UpdateArrange()
                                                    end
                                                    r.ImGui_BeginPopupContextItem(ctx, 'optional string str_idIn')
                                                    r.ImGui_EndPopup(ctx)
                                                end
                                            end
                                        end -- Rpt for every param


                                        if FX.LayEdit then
                                            if LE.DragY > LE.GridSize or LE.DragX > LE.GridSize or LE.DragY < -LE.GridSize or LE.DragX < -LE.GridSize then
                                                r.ImGui_ResetMouseDragDelta(ctx)
                                            end
                                        end


                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and
                                            r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_RootAndChildWindows())
                                        then
                                            if ClickOnAnyItem == nil and LBtnRel and AdjustPrmWidth ~= true and Mods == 0 then
                                                LE.Sel_Items = {};
                                            elseif ClickOnAnyItem and LBtnRel then
                                                ClickOnAnyItem = nil
                                            elseif AdjustPrmWidth == true then
                                                AdjustPrmWidth = nil
                                            end
                                        end




                                        if FX.Round[FxGUID] then r.ImGui_PopStyleVar(ctx) end
                                        if FX.GrbRound[FxGUID] then r.ImGui_PopStyleVar(ctx) end



                                        if (FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true) and Mods ~= Apl then
                                            r.ImGui_EndDisabled(ctx)
                                        end
                                    end




                                    for i, v in pairs(PluginScripts) do
                                        if FX_Name:find(v) then
                                            r.SetExtState('FXD', 'Plugin Script FX_Id', FX_Idx, false)
                                            PluginScript.FX_Idx = FX_Idx
                                            PluginScript.Guid = FXGUID[FX_Idx]
                                            if Prm.InstAdded[FXGUID[FX_Idx]] ~= true and FX.Win_Name[FX_Idx]:find('Pro%-C 2') then
                                                --- number in green represents FX Prm Index
                                            end
                                            dofile(pluginScriptPath .. '/' .. v .. '.lua')
                                        end
                                    end
                                    --PluginScript.FX_Idx = FX_Idx
                                    -- PluginScript.Guid = FXGUID[FX_Idx]
                                    --require("src.FX Layout Plugin Scripts.Pro C 2")
                                    -- require("src.FX Layout Plugin Scripts.Pro Q 3")



                                    if FX.Enable[FX_Idx] == false then
                                        r.ImGui_DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B, 0x00000088)
                                    end

                                    if r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_RootAndChildWindows()) then DisableScroll = nil else DisableScroll = true end

                                    r.ImGui_Dummy(ctx, FX.Width[FXGUID[FX_Idx]] or DefaultWidth, 220)
                                    r.ImGui_EndChild(ctx)
                                end
                            end


                            --------------------------------------------------------------------------------------
                            --------------------------------------Draw Mode --------------------------------------
                            --------------------------------------------------------------------------------------

                            --------------------FX Devices--------------------

                            r.ImGui_PopStyleColor(ctx, poptimes) -- -- PopColor #1 FX Window
                            r.ImGui_SameLine(ctx, nil, 0)








                            r.ImGui_EndGroup(ctx)
                        end
                        if BlinkFX == FX_Idx then BlinkFX = BlinkItem(0.2, 2, BlinkFX) end
                    end --of Create fx window function

                    if --[[Normal Window]] (not string.find(FX_Name, 'FXD %(Mix%)RackMixer')) and FX.InLyr[FXGUID[FX_Idx]] == nil and FX_Idx ~= RepeatTimeForWindows and FindStringInTable(BlackListFXs, FX_Name) ~= true then
                        --FX_IdxREAL =  FX_Idx+Lyr.FX_Ins[FXGUID[FX_Idx]]

                        if not tablefind(Trk[TrkID].PostFX, FxGUID) and not FX[FxGUID].InWhichBand then
                            createFXWindow(FX_Idx)
                            local rv, inputPins, outputPins = r.TrackFX_GetIOSize(LT_Track, FX_Idx)
                        end
                        if FX.LayEdit == FXGUID[FX_Idx] then
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0xffffff00)
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderActive(), 0xffffff00)

                            --if not ctx then ctx = r.ImGui_CreateContext('Layout Editor') end
                            --r.ImGui_BeginTooltip( ctx)

                            --attachfonts(ctx)

                            --[[ rv, LayEdProp_Open = r.ImGui_Begin(ctx, 'LayoutEdit Propertiess', true,
                                r.ImGui_WindowFlags_MenuBar() + r.ImGui_WindowFlags_NoCollapse() +
                                r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_NoDocking()) ]]
                            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x191919ff ) ;
                            local FxGUID = FXGUID[FX_Idx]

                            if not CloseLayEdit and r.ImGui_Begin(ctx, 'LayoutEdit Propertiess', true, r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_NoDocking()) then
                                --if not CloseLayEdit   then    ----START CHILD WINDOW------
                                DisableScroll = true



                                if r.ImGui_Button(ctx, 'Save') then
                                    SaveLayoutEditings(FX_Name, ID or 1, FXGUID[FX_Idx])
                                    CloseLayEdit = true; FX.LayEdit = nil
                                end
                                SL()
                                if r.ImGui_Button(ctx, 'Exit##Lay') then
                                    r.ImGui_OpenPopup(ctx, 'Save Editing?')
                                end
                                SL()

                                if LE.Sel_Items[1] then
                                    local I = FX[FxGUID][LE.Sel_Items[1]]
                                    if r.ImGui_Button(ctx, 'Delete') then
                                        local tb = {}

                                        for i, v in pairs(LE.Sel_Items) do
                                            tb[i] = v
                                        end
                                        table.sort(tb)

                                        for i = #tb, 1, -1 do
                                            DeletePrm(FxGUID, tb[i])
                                        end

                                        if not FX[FxGUID][1] then FX[FxGUID].AllPrmHasBeenDeleted = true else FX[FxGUID].AllPrmHasBeenDeleted = nil end


                                        LE.Sel_Items = {}
                                    end

                                    SL(nil, 30)

                                    if r.ImGui_Button(ctx, 'Copy Properties') then
                                        CopyPrm = {}
                                        CopyPrm = I

                                        for i, v in pairs(LE.Sel_Items) do

                                        end
                                    end

                                    SL()
                                    if r.ImGui_Button(ctx, 'Paste Properties') then
                                        for i, v in pairs(LE.Sel_Items) do
                                            I.Type        = CopyPrm.Type
                                            I.Sldr_W      = CopyPrm.Sldr_W
                                            I.Style       = CopyPrm.Style
                                            I.V_FontSize  = CopyPrm.V_FontSize
                                            I.CustomLbl   = CopyPrm.CustomLbl
                                            I.FontSize    = CopyPrm.FontSize
                                            I.Sldr_H      = CopyPrm.Sldr_H
                                            I.BgClr       = CopyPrm.BgClr
                                            I.GrbClr      = CopyPrm.GrbClr
                                            I.Lbl_Pos     = CopyPrm.Lbl_Pos
                                            I.V_Pos       = CopyPrm.V_Pos
                                            I.Lbl_Clr     = CopyPrm.Lbl_Clr
                                            I.V_Clr       = CopyPrm.V_Clr
                                            I.DragDir     = CopyPrm.DragDir
                                            I.Value_Thick = CopyPrm.Value_Thick
                                            I.V_Pos_X     = CopyPrm.V_Pos_X
                                            I.V_Pos_Y     = CopyPrm.V_Pos_Y
                                            I.ImagePath   = CopyPrm.ImagePath
                                            if CopyPrm.Draw then
                                                -- use this line to pool
                                                --I.Draw = CopyPrm.Draw

                                                I.Draw = I.Draw or {}
                                                for i, v in pairs(CopyPrm.Draw) do
                                                    I.Draw[i] = I.Draw[i] or {}
                                                    for d, v in pairs(v) do
                                                        I.Draw[i][d] = v
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                SL(nil, 30)

                                if Draw.DrawMode[FxGUID] then
                                    if r.ImGui_Button(ctx, 'Exit Background Edit') then Draw.DrawMode[FxGUID] = false end
                                else
                                    if r.ImGui_Button(ctx, 'Enter Background Edit') then
                                        Draw.DrawMode[FxGUID] = true
                                        if Draw[FX.Win_Name_S[FX_Idx]] == nil then
                                            Draw[FX.Win_Name_S[FX_Idx]] = {
                                                Rect = {},
                                                clr = {},
                                                ItemInst = {},
                                                L = {},
                                                R = {},
                                                Y = {},
                                                T = {},
                                                B = {},
                                                Type = {},
                                                FxGUID = {},
                                                Txt = {}
                                            }
                                        end
                                        LE.Sel_Items = {}
                                    end
                                end




                                r.ImGui_Separator(ctx)


                                local ColorPaletteTop = r.ImGui_GetCursorPosY




                                -- Add Drawings ----
                                if not LE.Sel_Items[1] then
                                    if Draw.DrawMode[FxGUID] ~= true then
                                        r.ImGui_TextWrapped(ctx, 'Select an item to start editing')
                                        AddSpacing(15)
                                    else
                                        r.ImGui_Text(ctx, '(!) Hold down Left button to Draw in FX Devices')
                                        AddSpacing(5)
                                        r.ImGui_Text(ctx, 'Type:')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x99999933)
                                        local D = Draw[FX.Win_Name_S[FX_Idx]]
                                        local FullWidth = -50

                                        local typelbl; local It = Draw.SelItm
                                        D[It or 1] = D[It or 1] or {}

                                        if Draw.SelItm then typelbl = D.Type[Draw.SelItm] end
                                        if Draw.Type == nil then Draw.Type = 'line' end
                                        r.ImGui_SetNextItemWidth(ctx, FullWidth)
                                        if r.ImGui_BeginCombo(ctx, '##', typelbl or Draw.Type or 'line', r.ImGui_ComboFlags_NoArrowButton()) then
                                            local function setType(str)
                                                if r.ImGui_Selectable(ctx, str, false) then
                                                    if It then D.Type[It] = str end
                                                    Draw.Type = str
                                                end
                                            end
                                            setType('Picture')
                                            setType('line')
                                            setType('V-line')
                                            setType('rectangle')
                                            setType('rect fill')
                                            setType('circle')
                                            setType('circle fill')
                                            setType('Text')

                                            r.ImGui_EndCombo(ctx)
                                        end
                                        r.ImGui_Text(ctx, 'Color :')
                                        r.ImGui_SameLine(ctx)
                                        if Draw.SelItm and D.clr[Draw.SelItm] then
                                            clrpick, D.clr[Draw.SelItm] = r.ImGui_ColorEdit4(ctx, '##',
                                                D.clr[Draw.SelItm] or 0xffffffff,
                                                r.ImGui_ColorEditFlags_NoInputs()|
                                                r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                r.ImGui_ColorEditFlags_AlphaBar())
                                        else
                                            clrpick, Draw.clr = r.ImGui_ColorEdit4(ctx, '##', Draw.clr or 0xffffffff,
                                                r.ImGui_ColorEditFlags_NoInputs()|
                                                r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                r.ImGui_ColorEditFlags_AlphaBar())
                                        end
                                        r.ImGui_Text(ctx, 'Default edge rounding :')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, 40)
                                        EditER, Draw.Df_EdgeRound[FxGUID] = r.ImGui_DragDouble(ctx, '##' .. FxGUID,
                                            Draw.Df_EdgeRound[FxGUID], 0.05, 0, 30, '%.2f')



                                        if D.Type[It] == 'Picture' then
                                            r.ImGui_Text(ctx, 'File Path:')
                                            SL()
                                            DragDropPics = DragDropPics or {}

                                            if r.ImGui_BeginChildFrame(ctx, '##drop_files', FullWidth, 40) then
                                                if not D[It].FilePath then
                                                    r.ImGui_Text(ctx, 'Drag and drop files here...')
                                                else
                                                    r.ImGui_Text(ctx, D[It].FilePath)

                                                    if r.ImGui_SmallButton(ctx, 'Clear') then

                                                    end
                                                end
                                                if D[It].FilePath then
                                                    r.ImGui_Bullet(ctx)
                                                    r.ImGui_TextWrapped(ctx, D[It].FilePath)
                                                end
                                                r.ImGui_EndChildFrame(ctx)
                                            end


                                            if r.ImGui_BeginDragDropTarget(ctx) then
                                                local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
                                                if rv then
                                                    for i = 0, count - 1 do
                                                        local filename
                                                        rv, filename = r.ImGui_GetDragDropPayloadFile(ctx, i)
                                                        D[It].FilePath = filename

                                                        D[It].Image = r.ImGui_CreateImage(filename)
                                                        r.ImGui_Attach(ctx, D[It].Image)
                                                    end
                                                end
                                                r.ImGui_EndDragDropTarget(ctx)
                                            end

                                            rv, D[It].KeepImgRatio = r.ImGui_Checkbox(ctx, 'Keep Image Ratio',
                                                D[It].KeepImgRatio)
                                        end

                                        if Draw.SelItm then
                                            r.ImGui_Text(ctx, 'Start Pos X:')
                                            r.ImGui_SameLine(ctx)
                                            local CurX = r.ImGui_GetCursorPosX(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, FullWidth)
                                            _, D.L[It] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'L',
                                                D.L[Draw.SelItm], 1, 0, Win_W, '%.0f')
                                            if D.Type[It] ~= 'V-line' and D.Type[It] ~= 'circle' and D.Type[It] ~= 'circle fill' then
                                                r.ImGui_Text(ctx, 'End Pos X:')
                                                r.ImGui_SetNextItemWidth(ctx, FullWidth)

                                                r.ImGui_SameLine(ctx, CurX)
                                                _, D.R[It] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                                    D.R[Draw.SelItm], 1, 0, Win_W, '%.0f')
                                            end

                                            if D.Type[It] == 'circle' or D.Type[It] == 'circle fill' then
                                                r.ImGui_Text(ctx, 'Radius:')
                                                r.ImGui_SameLine(ctx)
                                                r.ImGui_SetNextItemWidth(ctx, FullWidth)
                                                _, D.R[It] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                                    D.R[Draw.SelItm], 1, 0, Win_W, '%.0f')
                                            end


                                            r.ImGui_Text(ctx, 'Start Pos Y:')

                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, FullWidth)

                                            _, D.T[Draw.SelItm] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'T',
                                                D.T[Draw.SelItm], 1, 0, Win_W, '%.0f')


                                            if D.Type[It] ~= 'line' and D.Type[It] ~= 'circle fill' and D.Type[It] ~= 'circle' then
                                                r.ImGui_Text(ctx, 'End Pos Y:')
                                                r.ImGui_SameLine(ctx, CurX)
                                                r.ImGui_SetNextItemWidth(ctx, FullWidth)

                                                _, D.B[It] = r.ImGui_DragDouble(ctx, '##' .. It .. 'B', D.B[It], 1, 0,
                                                    Win_W, '%.0f')
                                            end

                                            if D.Type[It] == 'Text' then
                                                r.ImGui_Text(ctx, 'Text:')
                                                r.ImGui_SameLine(ctx)

                                                _, D.Txt[It] = r.ImGui_InputText(ctx, '##' .. It .. 'Txt', D.Txt[It])

                                                SL()
                                                r.ImGui_Text(ctx, 'Font Size:')
                                                local rv, Sz = r.ImGui_InputInt(ctx, '## font size ' .. It,
                                                    D[It].FtSize or 12)
                                                if rv then
                                                    D[It].FtSize = Sz
                                                    if not _G['Font_Andale_Mono' .. '_' .. Sz] then
                                                        _G['Font_Andale_Mono' .. '_' .. Sz] = r.ImGui_CreateFont(
                                                            'andale mono', Sz)
                                                        ChangeFont = D[It]
                                                    else
                                                        D[It].Font = _G['Font_Andale_Mono' .. '_' .. Sz]
                                                    end
                                                end
                                            end
                                        end



                                        r.ImGui_PopStyleColor(ctx)
                                    end
                                elseif LE.Sel_Items[1] then
                                    local ID, TypeID; local FrstSelItm = FX[FxGUID][LE.Sel_Items[1]]; local FItm = LE
                                        .Sel_Items[1]
                                    local R_ofs = 50
                                    if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                                        ID       = FxGUID .. LE.Sel_Items[1]
                                        WidthID  = FxGUID .. LE.Sel_Items[1]
                                        ClrID    = FxGUID .. LE.Sel_Items[1]
                                        GrbClrID = FxGUID .. LE.Sel_Items[1]
                                        TypeID   = FxGUID .. LE.Sel_Items[1]
                                    elseif LE.Sel_Items[2] then
                                        local Diff_Types_Found, Diff_Width_Found, Diff_Clr_Found, Diff_GrbClr_Found
                                        for i, v in pairs(LE.Sel_Items) do
                                            local lastV
                                            if i > 1 then
                                                local frst = LE.Sel_Items[1]; local other = LE.Sel_Items[i];
                                                if FX[FxGUID][1].Type ~= FX[FxGUID][v].Type then Diff_Types_Found = true end
                                                --if FX[FxGUID][frst].Sldr_W ~= FX[FxGUID][v].Sldr_W then  Diff_Width_Found = true    end
                                                --if FX[FxGUID][frst].BgClr  ~= FX[FxGUID][v].BgClr  then Diff_Clr_Found = true       end
                                                --if FX[FxGUID][frst].GrbClr ~= FX[FxGUID][v].GrbClr then Diff_GrbClr_Found = true end
                                            end
                                        end
                                        if Diff_Types_Found then
                                            TypeID = 'Group'
                                        else
                                            TypeID = FxGUID .. LE.Sel_Items
                                                [1]
                                        end
                                        if Diff_Width_Found then
                                            WidthID = 'Group'
                                        else
                                            WidthID = FxGUID ..
                                                LE.Sel_Items[1]
                                        end
                                        if Diff_Clr_Found then ClrID = 'Group' else ClrID = FxGUID .. LE.Sel_Items[1] end
                                        if Diff_GrbClr_Found then
                                            GrbClrID = 'Group'
                                        else
                                            GrbClrID = FxGUID ..
                                                LE.Sel_Items[1]
                                        end
                                        ID = FxGUID .. LE.Sel_Items[1]
                                    else
                                        ID = FxGUID .. LE.Sel_Items[1]
                                    end
                                    local function FreeValuePosSettings()
                                        if FrstSelItm.V_Pos == 'Free' then
                                            r.ImGui_Text(ctx, 'X:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosX, PosX = r.ImGui_DragDouble(ctx,
                                                ' ##EditValuePosX' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.V_Pos_X or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosX then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.V_Pos_X = PosX end
                                            end
                                            r.ImGui_Text(ctx, 'Y:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosY, PosY = r.ImGui_DragDouble(ctx,
                                                ' ##EditValuePosY' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.V_Pos_Y or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosY then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.V_Pos_Y = PosY end
                                            end
                                        end
                                    end
                                    local function FreeLblPosSettings()
                                        if FrstSelItm.Lbl_Pos == 'Free' then
                                            r.ImGui_Text(ctx, 'X:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosX, PosX = r.ImGui_DragDouble(ctx,
                                                ' ##EditLblPosX' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos_X or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosX then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.Lbl_Pos_X = PosX end
                                            end
                                            r.ImGui_Text(ctx, 'Y:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosY, PosY = r.ImGui_DragDouble(ctx,
                                                ' ##EditLblPosY' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos_Y or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosY then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.Lbl_Pos_Y = PosY end
                                            end
                                        end
                                    end
                                    local function AddOption(Name, TargetVar, TypeCondition)
                                        if FrstSelItm.Type == TypeCondition or not TypeCondition then
                                            if r.ImGui_Selectable(ctx, Name, false) then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v][TargetVar] = Name end
                                            end
                                        end
                                    end

                                    -----Type--------

                                    local PrmTypeLbl

                                    if TypeID == 'Group' then
                                        PrmTypeLbl = 'Multiple Values'
                                    else
                                        PrmTypeLbl = FrstSelItm.Type or ''
                                    end
                                    if not FrstSelItm.Type then FrstSelItm.Type = FX.Def_Type[FxGUID] end
                                    r.ImGui_Text(ctx, 'Type : '); r.ImGui_SameLine(ctx); r.ImGui_PushStyleColor(ctx,
                                        r.ImGui_Col_FrameBg(), 0x444444aa)
                                    r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                    if r.ImGui_BeginCombo(ctx, '##', PrmTypeLbl, r.ImGui_ComboFlags_NoArrowButton()) then
                                        local function SetItemType(Type)
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].Sldr_W = nil
                                                FX[FxGUID][v].Type = Type
                                            end
                                        end

                                        if r.ImGui_Selectable(ctx, 'Slider', false) then
                                            SetItemType('Slider')
                                        elseif r.ImGui_Selectable(ctx, 'Knob', false) then
                                            SetItemType('Knob')
                                        elseif r.ImGui_Selectable(ctx, 'V-Slider', false) then
                                            SetItemType('V-Slider')
                                        elseif r.ImGui_Selectable(ctx, 'Drag', false) then
                                            SetItemType('Drag')
                                        elseif r.ImGui_Selectable(ctx, 'Switch', false) then
                                            SetItemType('Switch')
                                        elseif r.ImGui_Selectable(ctx, 'Selection', false) then
                                            SetItemType('Selection')
                                        end
                                        r.ImGui_EndCombo(ctx)
                                    end

                                    ---Label    Show only when there's one item selected-----
                                    if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                                        r.ImGui_Text(ctx, 'Label: '); r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                        local LblEdited, buf = r.ImGui_InputText(ctx,
                                            ' ##Edit Title' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.CustomLbl or buf)
                                        if r.ImGui_IsItemActivated(ctx) then EditingPrmLbl = LE.Sel_Items[1] end
                                        if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then FrstSelItm.CustomLbl = buf end
                                    end

                                    --Label Pos
                                    r.ImGui_Text(ctx, 'Label Pos: '); r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(
                                        ctx, 100)
                                    if r.ImGui_BeginCombo(ctx, '## Lbl Pos' .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos or 'Default', r.ImGui_ComboFlags_NoArrowButton()) then
                                        if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'V-Slider' then
                                            AddOption('Top', 'Lbl_Pos')
                                            AddOption('Bottom', 'Lbl_Pos')
                                        elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' then
                                            AddOption('Left', 'Lbl_Pos')
                                            AddOption('Bottom', 'Lbl_Pos')
                                        elseif FrstSelItm.Type == 'Selection' or FrstSelItm.Type == 'Switch' then
                                            AddOption('Top', 'Lbl_Pos')
                                            AddOption('Left', 'Lbl_Pos')
                                            if FrstSelItm.Type == 'Switch' then AddOption('Within', 'Lbl_Pos') end
                                            AddOption('Bottom', 'Lbl_Pos')
                                            AddOption('Right', 'Lbl_Pos')
                                            AddOption("None", 'Lbl_Pos')
                                        end
                                        AddOption('Free', 'Lbl_Pos')
                                        r.ImGui_EndCombo(ctx)
                                    end
                                    r.ImGui_SameLine(ctx)
                                    FreeLblPosSettings()
                                    -- Label Color
                                    DragLbl_Clr_Edited, Lbl_V_Clr = r.ImGui_ColorEdit4(ctx, '##Lbl Clr' ..
                                        LE.Sel_Items[1], FrstSelItm.Lbl_Clr or r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if DragLbl_Clr_Edited then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Clr = Lbl_V_Clr end
                                    end


                                    r.ImGui_Text(ctx, 'Value Pos: '); r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(
                                        ctx, 100)
                                    if r.ImGui_BeginCombo(ctx, '## V Pos' .. LE.Sel_Items[1], FrstSelItm.V_Pos or 'Default', r.ImGui_ComboFlags_NoArrowButton()) then
                                        if FrstSelItm.Type == 'V-Slider' then
                                            AddOption('Bottom', 'V_Pos')
                                            AddOption('Top', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Knob' then
                                            AddOption('Bottom', 'V_Pos')
                                            AddOption('Within', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Switch' or FrstSelItm.Type == 'Selection' then
                                            AddOption('Within', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Drag' then
                                            AddOption('Right', 'V_Pos')
                                            AddOption('Within', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Slider' then
                                            AddOption('Right', 'V_Pos')
                                        end
                                        if FrstSelItm.Type ~= 'Selection' then AddOption('None', 'V_Pos') end

                                        AddOption('Free', 'V_Pos')

                                        r.ImGui_EndCombo(ctx)
                                    end
                                    r.ImGui_SameLine(ctx)

                                    FreeValuePosSettings()
                                    DragV_Clr_edited, Drag_V_Clr = r.ImGui_ColorEdit4(ctx, '##V  Clr' .. LE.Sel_Items[1],
                                        FrstSelItm.V_Clr or r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if DragV_Clr_edited then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = Drag_V_Clr end
                                    end

                                    if FrstSelItm.Type == 'Drag' then
                                        r.ImGui_Text(ctx, 'Direction: ')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                        if r.ImGui_BeginCombo(ctx, '## Drag Dir' .. LE.Sel_Items[1], FrstSelItm.DragDir or '', r.ImGui_ComboFlags_NoArrowButton()) then
                                            if r.ImGui_Selectable(ctx, 'Right', false) then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Right' end
                                            elseif r.ImGui_Selectable(ctx, 'Left-Right', false) then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Left-Right' end
                                            elseif r.ImGui_Selectable(ctx, 'Left', false) then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Left' end
                                            end
                                            r.ImGui_EndCombo(ctx)
                                        end
                                    end








                                    if FrstSelItm.Type == 'Switch' then
                                        local Momentary, Toggle
                                        if FrstSelItm.SwitchType == 'Momentary' then
                                            Momentary = true
                                        else
                                            Toggle = true
                                        end
                                        EdT, Tg = r.ImGui_Checkbox(ctx, 'Toggle##' .. FxGUID .. LE.Sel_Items[1], Toggle)
                                        r.ImGui_SameLine(ctx);
                                        EdM, Mt = r.ImGui_Checkbox(ctx, 'Momentary##' .. FxGUID .. LE.Sel_Items[1],
                                            Momentary)
                                        if EdT then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].SwitchType = 'Toggle' end
                                        elseif EdM then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].SwitchType = 'Momentary' end
                                        end
                                    end



                                    -- set base and target value
                                    if FrstSelItm.SwitchType == 'Momentary' and FrstSelItm.Type == 'Switch' then
                                        r.ImGui_Text(ctx, 'Base Value: ')
                                        r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 80)
                                        local Drag, Bv = r.ImGui_DragDouble(ctx,
                                            '##EditBaseV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV or 0, 0.05, 0, 1, '%.2f')
                                        if Drag then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV = Bv
                                            end
                                        end
                                        r.ImGui_Text(ctx, 'Target Value: ')
                                        r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 80)
                                        local Drag, Tv = r.ImGui_DragDouble(ctx,
                                            '##EditTargV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1]].SwitchTargV or 1, 0.05, 0, 1, '%.2f')
                                        if Drag then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][LE.Sel_Items[1]].SwitchTargV =
                                                    Tv
                                            end
                                        end
                                    end









                                    local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()
                                    ----Font Size-----


                                    r.ImGui_Text(ctx, 'Label Font Size: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local Drag, ft = r.ImGui_DragDouble(ctx,
                                        '##EditFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FrstSelItm.FontSize or Knob_DefaultFontSize, 0.25, 6, 64, '%.2f')
                                    if Drag then
                                        local sz = roundUp(ft, 1)
                                        if not _G['Font_Andale_Mono' .. '_' .. sz] then
                                            _G['Font_Andale_Mono' .. '_' .. sz] = r.ImGui_CreateFont('andale mono', sz)
                                            ChangeFont = FrstSelItm
                                            ChangeFont_Size = sz
                                        end

                                        for i, v in pairs(LE.Sel_Items) do
                                            FX[FxGUID][v].FontSize = ft
                                        end
                                    end






                                    SL()
                                    r.ImGui_Text(ctx, 'Value Font Size: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local Drag, ft = r.ImGui_DragDouble(ctx,
                                        '##EditV_FontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FX[FxGUID][LE.Sel_Items[1]].V_FontSize or Knob_DefaultFontSize, 0.25, 6, 64,
                                        '%.2f')
                                    if Drag then
                                        local sz = roundUp(ft, 1)
                                        if not _G['Arial' .. '_' .. sz] then
                                            _G['Arial' .. '_' .. sz] = r.ImGui_CreateFont('Arial', sz)
                                            ChangeFont = FrstSelItm
                                            ChangeFont_Size = sz
                                            ChangeFont_Font = 'Arial'
                                        end
                                        for i, v in pairs(LE.Sel_Items) do
                                            FX[FxGUID][v].V_FontSize = ft
                                        end
                                    end








                                    ----Width -------
                                    r.ImGui_Text(ctx, 'Width: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                    local DefaultW, MaxW, MinW
                                    if FrstSelItm.Type == 'Knob' then
                                        DefaultW = Df.KnobRadius
                                        MaxW = 80
                                        MinW = 7.5
                                    elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' or not FrstSelItm.Type then
                                        DefaultW = Df.Sldr_W
                                        MaxW = 300
                                        MinW = 40
                                    elseif FrstSelItm.Type == 'Selection' then
                                        DefaultW = FrstSelItm.Combo_W
                                        MaxW = 300
                                        MinW = 20
                                    elseif FrstSelItm.Type == 'Switch' then
                                        DefaultW = FrstSelItm.Switch_W
                                        MaxW = 300
                                        MinW = 15
                                    elseif FrstSelItm.Type == 'V-Slider' then
                                        DefaultW = FrstSelItm.V_Sldr_W
                                        MaxW = 60
                                        MinW = 7
                                    end
                                    local DragSpeed = 5



                                    local _, W = r.ImGui_DragDouble(ctx,
                                        '##EditWidth' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FX[FxGUID][LE.Sel_Items[1] or ''].Sldr_W or DefaultW, LE.GridSize / 4, MinW, MaxW,
                                        '%.1f')

                                    if r.ImGui_IsItemEdited(ctx) then
                                        for i, v in pairs(LE.Sel_Items) do
                                            FX[FxGUID][v].Sldr_W = W
                                        end
                                    end

                                    if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'Drag' or FrstSelItm.Type == 'Slider' then
                                        r.ImGui_Text(ctx, 'Value Decimal Places: '); r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, 80)
                                        if not FX[FxGUID][LE.Sel_Items[1]].V_Round then
                                            local _, FormatV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                FX[FxGUID][LE.Sel_Items[1]].Num)
                                            local _, LastNum = FormatV:find('^.*()%d')
                                            local dcm = FormatV:find('%.')
                                            if dcm then
                                                rd = LastNum - dcm
                                            end
                                        end

                                        local Edit, rd = r.ImGui_InputInt(ctx,
                                            '##EditValueDecimals' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FrstSelItm.V_Round or rd, 1)
                                        if Edit then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].V_Round = math.max(
                                                    rd, 0)
                                            end
                                        end
                                    end

                                    r.ImGui_Text(ctx, 'Value to Note Length: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local Edit = r.ImGui_Checkbox(ctx,
                                        '##Value to Note Length' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FrstSelItm.ValToNoteL or nil)
                                    if Edit then
                                        for i, v in pairs(LE.Sel_Items) do
                                            if not FX[FxGUID][v].ValToNoteL then
                                                FX[FxGUID][v].ValToNoteL = true
                                            else
                                                FX[FxGUID][v].ValToNoteL = false
                                            end
                                        end
                                    end
                                    if FrstSelItm.Type == 'Selection' then --r.ImGui_Text(ctx,'Edit Values Manually: ') ;r.ImGui_SameLine(ctx)
                                        local Itm = LE.Sel_Items[1]
                                        local FP = FX[FxGUID][Itm] ---@class FX_P



                                        if r.ImGui_TreeNode(ctx, 'Edit Values Manually') then
                                            FX[FxGUID][Itm].ManualValues = FX[FxGUID][Itm].ManualValues or {}
                                            FX[FxGUID][Itm].ManualValuesFormat = FX[FxGUID][Itm].ManualValuesFormat or {}
                                            if r.ImGui_Button(ctx, 'Get Current Value##' .. FxGUID .. (Itm or '')) then
                                                local Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num)
                                                if not tablefind(FP.ManualValues, Val) then
                                                    table.insert(FX[FxGUID][Itm].ManualValues, Val)
                                                end
                                            end
                                            for i, V in ipairs(FX[FxGUID][Itm].ManualValues) do
                                                r.ImGui_AlignTextToFramePadding(ctx)
                                                r.ImGui_Text(ctx, i .. ':' .. (round(V, 2) or 0))
                                                SL()
                                                --r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                                rv, FX[FxGUID][Itm].ManualValuesFormat[i] = r.ImGui_InputText(ctx,
                                                    '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i,
                                                    FX[FxGUID][Itm].ManualValuesFormat[i])
                                                SL()
                                                local LH = r.ImGui_GetTextLineHeight(ctx)
                                                if IconBtn(20, 20, 'T', BgClr, 'center', '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i) then
                                                    table.remove(FX[FxGUID][Itm].ManualValuesFormat, i)
                                                    table.remove(FX[FxGUID][Itm].ManualValues, i)
                                                end
                                            end
                                            --FX[FxGUID][Itm].EditValuesManual = true
                                            r.ImGui_TreePop(ctx)
                                        end
                                    end

                                    function ToAllSelItm(x, y)
                                        for i, v in ipairs(LE.Sel_Items) do
                                            FX[FxGUID][v][x] = y
                                        end
                                    end

                                    local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

                                    --- Style ------
                                    r.ImGui_Text(ctx, 'Style: '); r.ImGui_SameLine(ctx)
                                    w = r.ImGui_CalcTextSize(ctx, 'Style: ')
                                    local stylename
                                    if FrstSelItm.Style == 'Pro C' then stylename = 'Minimalistic' end
                                    if r.ImGui_Button(ctx, (stylename or FrstSelItm.Style or 'Choose Style') .. '##' .. (LE.Sel_Items[1] or 'Style'), 130) then
                                        r.ImGui_OpenPopup(ctx, 'Choose style window')
                                    end


                                    r.ImGui_Text(ctx, 'Add Custom Image:')

                                    DragDropPics = DragDropPics or {}

                                    rv, ImgTrashTint = TrashIcon(16, 'Clear', ClrBG, ImgTrashTint)
                                    if rv then
                                        ToAllSelItm('Style', nil)
                                        ToAllSelItm('ImagePath', nil)
                                        ToAllSelItm('Image', nil)
                                    end


                                    SL()
                                    if r.ImGui_BeginChildFrame(ctx, '##drop_files', -R_ofs, 20) then
                                        if not FrstSelItm.ImagePath then
                                            r.ImGui_Text(ctx, 'Drag and drop files here...')
                                        else
                                            --FrstSelItm.Style = 'Custom Image'

                                            r.ImGui_Text(ctx, FrstSelItm.ImagePath)
                                        end

                                        r.ImGui_EndChildFrame(ctx)
                                    end

                                    if r.ImGui_BeginDragDropTarget(ctx) then
                                        local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
                                        if rv then
                                            for i = 0, count - 1 do
                                                local rv, filename = r.ImGui_GetDragDropPayloadFile(ctx, i)
                                                if rv then
                                                    FrstSelItm.Style = 'Custom Image'
                                                    --[[  local UserOS = r.GetOS()
                                                    local slash = '%\\'
                                                    if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
                                                        slash = '/'
                                                    end
                                                    local index = filename:match ('^.*()'..slash)
                                                    local SubFolder = ''
                                                    if FrstSelItm.Type == 'Knob' then
                                                        SubFolder = 'Knobs'
                                                    end

                                                    local NewFileName = r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/src/Images/' ..  SubFolder .. filename:sub(index)
                                                    CopyFile(filename, NewFileName) ]]

                                                    AbsPath, FrstSelItm.ImagePath = CopyImageFile(filename, 'Knobs')
                                                    ToAllSelItm('Image', r.ImGui_CreateImage(AbsPath))
                                                end

                                                --[[  AttachImage = { Path = FrstSelItm.ImagePath, DrawItemNum = It, }
                                                if AttachImage then
                                                    local FX_Name_Short = ChangeFX_Name(FX_Name)
                                                    FrstSelItm.Image = r.ImGui_CreateImage(AttachImage.Path)
                                                    r.ImGui_Attach(ctx, FrstSelItm.Image)
                                                    AttachImage = nil
                                                end ]]
                                            end
                                        end
                                        r.ImGui_EndDragDropTarget(ctx)
                                    end

                                    --[[ if  r.ImGui_BeginCombo( ctx, '##'..(LE.Sel_Items[1] or 'Style') , FrstSelItm.Style or 'Choose Style', nil) then
                                            local function AddStyle (Name, Style)
                                                if r.ImGui_Selectable(ctx, Name) then
                                                    for i, v in pairs (LE.Sel_Items) do
                                                        FX[FxGUID][v].Style = Style ;   r.ImGui_CloseCurrentPopup(ctx)
                                                    end
                                                end
                                            end
                                            local T = {Name ={}; Style = {}}
                                            T.Name={'Default', 'Minimalistic', 'Analog 1'}
                                            T.Style = {'Default', 'Pro C', 'Analog 1'}

                                            for i, v in ipairs(T.Name) do
                                                AddStyle(v, T.Style[i])
                                            end

                                            r.ImGui_EndCombo(ctx)

                                        end ]]


                                    if r.ImGui_BeginPopup(ctx, 'Choose style window') then
                                        r.ImGui_BeginDisabled(ctx)

                                        local function setItmStyle(Style, img, ImgPath)
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].Style = Style;
                                                if img then
                                                    FX[FxGUID][v].Image = img
                                                    FX[FxGUID][v].ImagePath = ImgPath
                                                else
                                                    FX[FxGUID][v].ImagePath = nil
                                                end

                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                        end
                                        if FrstSelItm.Type == 'Slider' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Slider') then -- if all selected itms are Sliders
                                            --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize,     FrstSelItm.Lbl, 8)
                                            --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize, FrstSelItm.Lbl, 8)
                                        end
                                        StyleWinFilter = r.ImGui_CreateTextFilter(FilterText)
                                        if FrstSelItm.Type == 'Knob' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Knob') then -- if all selected itms are knobs
                                            StyleWinImg = StyleWinImg or {}
                                            StyleWinImgName = StyleWinImgName or {}
                                            local function SetStyle(Name, Style, Img, ImagePath)
                                                if r.ImGui_TextFilter_PassFilter(StyleWinFilter, Name) then
                                                    r.ImGui_Text(ctx, Name)
                                                    AddKnob(ctx, '##' .. FrstSelItm.Name, '', 0, 0, 1, FItm, FX_Idx,
                                                        FrstSelItm.Num, Style, 15, 0, Disabled, 12, Lbl_Pos, V_Pos, Img)
                                                    if HighlightHvredItem() then --if clicked on highlighted itm
                                                        setItmStyle(Style, Img, ImagePath)
                                                        r.ImGui_CloseCurrentPopup(ctx)
                                                    end
                                                    AddSpacing(6)
                                                end
                                            end


                                            r.ImGui_EndDisabled(ctx)
                                            if r.ImGui_TextFilter_Draw(StyleWinFilter, ctx, '##StyleWinFilterTxt', -1) then
                                                FilterText = r.ImGui_TextFilter_Get(StyleWinFilter)
                                                r.ImGui_TextFilter_Set(StyleWinFilter, FilterText)
                                            end
                                            if r.ImGui_IsWindowAppearing(ctx) then
                                                r.ImGui_SetKeyboardFocusHere(ctx)
                                            end

                                            r.ImGui_BeginDisabled(ctx)


                                            SetStyle('Default', Style)
                                            SetStyle('Minimalistic', 'Pro C')
                                            SetStyle('Invisible', 'Invisible')
                                            local Dir = r.GetResourcePath() ..
                                                CurrentDirectory .. '/src/Images/Knobs' 

                                            if r.ImGui_IsWindowAppearing(ctx) then
                                                StyleWindowImgFiles = scandir(Dir)
                                                if StyleWindowImgFiles then
                                                    for i, v in ipairs(StyleWindowImgFiles) do
                                                        if v ~= '.DS_Store' then
                                                            StyleWinImg[i] = r.ImGui_CreateImage(Dir .. '/' .. v)
                                                            r.ImGui_Attach(ctx, StyleWinImg[i])
                                                            StyleWinImgName[i] = v
                                                        end
                                                    end
                                                end
                                            end

                                            for i, v in pairs(StyleWinImg) do
                                                SetStyle(StyleWinImgName[i], 'Custom Image', StyleWinImg[i],
                                                    Dir .. '/' .. StyleWinImgName[i])
                                            end
                                        end

                                        if FrstSelItm.Type == 'Selection' then
                                            local function SetStyle(Name, Style, Width, CustomLbl)
                                                AddCombo(ctx, LT_Track, FX_Idx, Name .. '##' .. FrstSelItm.Name,
                                                    FrstSelItm.Num, Options, Width, Style, FxGUID, LE.Sel_Items[1],
                                                    OptionValues, 'Options', CustomLbl)
                                                if HighlightHvredItem() then
                                                    setItmStyle(Style)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                AddSpacing(3)
                                            end
                                            local w = 60
                                            SetStyle('Default', nil, w, 'Default: ')

                                            SetStyle('up-down arrow', 'up-down arrow', w + 20, 'up-down arrow: ')
                                        end

                                        r.ImGui_EndDisabled(ctx)
                                        r.ImGui_EndPopup(ctx)
                                    end
                                    ---Pos  -------

                                    r.ImGui_Text(ctx, 'Pos-X: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local EditPosX, PosX = r.ImGui_DragDouble(ctx, ' ##EditPosX' ..
                                        FxGUID .. LE.Sel_Items[1], PosX or FrstSelItm.PosX, LE.GridSize, 0, Win_W - 10,
                                        '%.0f')
                                    if EditPosX then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosX = PosX end
                                    end
                                    SL()
                                    r.ImGui_Text(ctx, 'Pos-Y: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local EditPosY, PosY = r.ImGui_DragDouble(ctx, ' ##EditPosY' ..
                                        FxGUID .. LE.Sel_Items[1], PosY or FrstSelItm.PosY, LE.GridSize, 20, 210, '%.0f')
                                    if EditPosY then for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosY = PosY end end

                                    ---Color -----

                                    r.ImGui_Text(ctx, 'Color: ')
                                    r.ImGui_SameLine(ctx)
                                    ClrEdited, PrmBgClr = r.ImGui_ColorEdit4(ctx, '##Clr' .. ID,
                                        FrstSelItm.BgClr or r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()),
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if not FX[FxGUID][LE.Sel_Items[1]].BgClr or FX[FxGUID][LE.Sel_Items[1]] == r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()) then
                                        HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect')
                                    end
                                    if ClrEdited then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].BgClr = PrmBgClr end
                                    end


                                    if FrstSelItm.Type ~= 'Switch' and FrstSelItm.Type ~= 'Selection' then
                                        r.ImGui_Text(ctx, 'Grab Color: ')
                                        r.ImGui_SameLine(ctx)
                                        GrbClrEdited, GrbClr = r.ImGui_ColorEdit4(ctx, '##GrbClr' .. ID,
                                            FrstSelItm.GrbClr or r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrab()),
                                            r.ImGui_ColorEditFlags_NoInputs()|    r
                                            .ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                            r.ImGui_ColorEditFlags_AlphaBar())
                                        if not FX[FxGUID][LE.Sel_Items[1]].GrbClr or FX[FxGUID][LE.Sel_Items[1]].GrbClr == r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrab()) then
                                            HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                                                'GetItemRect')
                                        end
                                        if GrbClrEdited then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].GrbClr =
                                                    GrbClr
                                            end
                                        end
                                    end

                                    if FrstSelItm.Type == 'Knob' then
                                        SL()
                                        r.ImGui_Text(ctx, 'Thickness : ')
                                        SL()
                                        r.ImGui_SetNextItemWidth(ctx, 40)
                                        local TD, Thick = r.ImGui_DragDouble(ctx,
                                            '##EditValueFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1] or ''].Value_Thick or 2, 0.1, 0.5, 8, '%.1f')
                                        if TD then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Value_Thick = Thick end
                                        end
                                    end


                                    if FrstSelItm.Type == 'Selection' then
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_Text(ctx, 'Text Color: ')
                                        r.ImGui_SameLine(ctx)
                                        local DragLbl_Clr_Edited, V_Clr = r.ImGui_ColorEdit4(ctx,
                                            '##V Clr' .. LE.Sel_Items[1],
                                            FX[FxGUID][LE.Sel_Items[1] or ''].V_Clr or
                                            r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                            r.ImGui_ColorEditFlags_NoInputs()|    r
                                            .ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                        if DragLbl_Clr_Edited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = V_Clr end
                                        end
                                    elseif FrstSelItm.Type == 'Switch' then
                                        SL()
                                        r.ImGui_Text(ctx, 'On Color: ')
                                        r.ImGui_SameLine(ctx)
                                        local DragLbl_Clr_Edited, V_Clr = r.ImGui_ColorEdit4(ctx,
                                            '##Switch on Clr' .. LE.Sel_Items[1],
                                            FX[FxGUID][LE.Sel_Items[1] or ''].Switch_On_Clr or
                                            0xffffff55,
                                            r.ImGui_ColorEditFlags_NoInputs()|    r
                                            .ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                        if DragLbl_Clr_Edited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Switch_On_Clr = V_Clr end
                                        end
                                    end

                                    ----- Condition to show ------

                                    local P = LE.Sel_Items[1]
                                    local fp = FX[FxGUID][LE.Sel_Items[1]] ---@class FX_P




                                    ---@param ConditionPrm string "ConditionPrm"..number
                                    ---@param ConditionPrm_PID string "ConditionPrm_PID"..number
                                    ---@param ConditionPrm_V string "ConditionPrm_V"..number
                                    ---@param ConditionPrm_V_Norm string "ConditionPrm_V_Norm"..number
                                    ---@param BtnTitle string
                                    ---@param ShowCondition string "ShowCondition"..number
                                    local function Condition(ConditionPrm, ConditionPrm_PID, ConditionPrm_V,
                                                             ConditionPrm_V_Norm, BtnTitle, ShowCondition)
                                        if r.ImGui_Button(ctx, BtnTitle) then
                                            if Mods == 0 then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    if not FX[FxGUID][v][ShowCondition] then FX[FxGUID][v][ShowCondition] = true else FX[FxGUID][v][ShowCondition] = nil end
                                                    FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v][ConditionPrm_V] or {}
                                                end
                                            elseif Mods == Alt then
                                                for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                    FX[FxGUID][P][ConditionPrm_V][i] = nil
                                                end
                                                FX[FxGUID][P][ConditionPrm] = nil
                                                FrstSelItm[ShowCondition] = nil
                                                DeleteAllConditionPrmV = nil
                                            end
                                        end

                                        if r.ImGui_IsItemHovered(ctx) then
                                            HintToolTip(
                                                'Alt-Click to Delete All Conditions')
                                        end



                                        if FrstSelItm[ShowCondition] or FX[FxGUID][P][ConditionPrm] then
                                            SL()
                                            if not FX[FxGUID][P][ConditionPrm_PID] then
                                                for i, v in ipairs(FX[FxGUID]) do
                                                    if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                                        FrstSelItm[ConditionPrm_PID] = i
                                                    end
                                                end
                                            end
                                            local PID = FX[FxGUID][P][ConditionPrm_PID] or 1

                                            if r.ImGui_Button(ctx, 'Parameter:##' .. ConditionPrm) then
                                                FX[FxGUID][P].ConditionPrm = LT_ParamNum
                                                local found
                                                for i, v in ipairs(FX[FxGUID]) do
                                                    if FX[FxGUID][i].Num == LT_ParamNum then
                                                        FrstSelItm[ConditionPrm_PID] = i
                                                        found = true

                                                        fp.Sldr_W = nil
                                                    end
                                                end
                                                if not found then
                                                    local P = StoreNewParam(LT_FXGUID, LT_ParamName,
                                                        LT_ParamNum,
                                                        LT_FXNum, true --[[ , nil, #F+1  ]])
                                                    fp[ConditionPrm_PID] = P

                                                    fp[ConditionPrm] = tonumber(LT_ParamNum)
                                                    fp.Sldr_W = nil
                                                end

                                                --GetParamOptions ('get', FxGUID,FX_Idx, LE.Sel_Items[1],LT_ParamNum)
                                            end
                                            if r.ImGui_IsItemHovered(ctx) then
                                                tooltip('Click to set to last touched parameter')
                                            end


                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, 80)
                                            local PrmName, PrmValue
                                            if fp[ConditionPrm] then
                                                _, PrmName = r.TrackFX_GetParamName(LT_Track, FX_Idx,
                                                    fp[ConditionPrm])
                                            end

                                            --[[ local Edit, Cond = r.ImGui_InputInt(ctx,'##' .. ConditionPrm .. LE.Sel_Items[1] .. FxGUID, FX[FxGUID][P][ConditionPrm] or 0)

                                            if FX[FxGUID][P][ConditionPrm] then
                                                _, PrmName = r.TrackFX_GetParamName(
                                                    LT_Track, FX_Idx, FX[FxGUID][P][ConditionPrm])
                                            end

                                            if Edit then
                                                FX[FxGUID][P][ConditionPrm] = Cond
                                                for i, v in ipairs(FX[FxGUID]) do
                                                    if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                                        FrstSelItm[ConditionPrm_PID] =i
                                                    end
                                                end
                                            end ]]

                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_Text(ctx, (PrmName or ''))
                                            r.ImGui_AlignTextToFramePadding(ctx)
                                            if PrmName then
                                                r.ImGui_Text(ctx, 'is at Value:')

                                                r.ImGui_SameLine(ctx)
                                                local FP = FX[FxGUID][LE.Sel_Items[1]] ---@class FX_P
                                                local CP = FX[FxGUID][P][ConditionPrm]
                                                --!!!!!! LE.Sel_Items[1] = Fx_P -1 !!!!!! --
                                                Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx,
                                                    'ConditionPrm' .. FP.ConditionPrm .. (PrmName or '') .. '1## CP',
                                                    FX[FxGUID][P][ConditionPrm] or 0,
                                                    FX[FxGUID][PID].ManualValuesFormat or 'Get Options', -R_ofs, Style,
                                                    FxGUID, PID, FX[FxGUID][PID].ManualValues,
                                                    FX[FxGUID][P][ConditionPrm_V][1] or 'Unassigned', nil, 'No Lbl')

                                                if Value_Selected then
                                                    for i, v in pairs(LE.Sel_Items) do
                                                        FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v][ConditionPrm_V] or
                                                            {}
                                                        FX[FxGUID][v][ConditionPrm_V_Norm] = FX[FxGUID][v]
                                                            [ConditionPrm_V_Norm] or {}
                                                        FX[FxGUID][v][ConditionPrm_V][1] = V_Formatted
                                                        FX[FxGUID][v][ConditionPrm_V_Norm][1] = r
                                                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                fp[ConditionPrm])
                                                    end
                                                end
                                                if not FX[FxGUID][P][ConditionPrm_V][1] then
                                                    FX[FxGUID][P][ConditionPrm_V][1] = ''
                                                end

                                                if FX[FxGUID][P][ConditionPrm_V] then
                                                    if FX[FxGUID][P][ConditionPrm_V][2] then
                                                        for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                            if i > 1 then
                                                                r.ImGui_Text(ctx, 'or at value:')
                                                                r.ImGui_SameLine(ctx)
                                                                local Value_Selected, V_Formatted = AddCombo(ctx,
                                                                    LT_Track,
                                                                    FX_Idx, 'CondPrmV' .. (PrmName or '') .. v ..
                                                                    ConditionPrm, FX[FxGUID][P][ConditionPrm] or 0,
                                                                    FX[FxGUID][PID].ManualValuesFormat or 'Get Options',
                                                                    -R_ofs, Style, FxGUID, PID,
                                                                    FX[FxGUID][PID].ManualValues,
                                                                    v, nil, 'No Lbl')
                                                                if Value_Selected then
                                                                    for I, v in pairs(LE.Sel_Items) do
                                                                        FX[FxGUID][v][ConditionPrm_V][i] = V_Formatted
                                                                        FX[FxGUID][v][ConditionPrm_V_Norm][i] = r
                                                                            .TrackFX_GetParamNormalized(LT_Track,
                                                                                FX_Idx,
                                                                                FX[FxGUID][P][ConditionPrm])
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                if r.ImGui_Button(ctx, ' + or at value:##' .. ConditionPrm) then
                                                    FX[FxGUID][P][ConditionPrm_V] = FX[FxGUID][P][ConditionPrm_V] or {}
                                                    table.insert(FX[FxGUID][P][ConditionPrm_V], '')
                                                end
                                                r.ImGui_SameLine(ctx)
                                                r.ImGui_SetNextItemWidth(ctx, 120)
                                                if r.ImGui_BeginCombo(ctx, '##- delete value ' .. ConditionPrm, '- delete value', r.ImGui_ComboFlags_NoArrowButton()) then
                                                    for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                        if r.ImGui_Selectable(ctx, v or '##', i) then
                                                            table.remove(FX[FxGUID][P][ConditionPrm_V], i)
                                                            if not FX[FxGUID][P][ConditionPrm_V][1] then
                                                                FX[FxGUID][P][ConditionPrm] = nil
                                                            end
                                                        end
                                                    end
                                                    r.ImGui_EndCombo(ctx)
                                                end
                                            end
                                        end
                                    end



                                    if r.ImGui_TreeNode(ctx, 'Conditional Parameter') then
                                        Condition('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V',
                                            'ConditionPrm_V_Norm',
                                            'Show only if:', 'ShowCondition')
                                        if FrstSelItm.ConditionPrm then
                                            Condition('ConditionPrm2', 'ConditionPrm_PID2',
                                                'ConditionPrm_V2', 'ConditionPrm_V_Norm2', 'And if:', 'ShowCondition2')
                                        end
                                        if FrstSelItm.ConditionPrm2 then
                                            Condition('ConditionPrm3', 'ConditionPrm_PID3',
                                                'ConditionPrm_V3', 'ConditionPrm_V_Norm3', 'And if:', 'ShowCondition3')
                                        end
                                        if FrstSelItm.ConditionPrm3 then
                                            Condition('ConditionPrm4', 'ConditionPrm_PID4',
                                                'ConditionPrm_V4', 'ConditionPrm_V_Norm4', 'And if:', 'ShowCondition4')
                                        end
                                        if FrstSelItm.ConditionPrm4 then
                                            Condition('ConditionPrm5', 'ConditionPrm_PID5',
                                                'ConditionPrm_V5', 'ConditionPrm_V_Norm5', 'And if:', 'ShowCondition5')
                                        end
                                        r.ImGui_TreePop(ctx)
                                    end





                                    if r.ImGui_TreeNode(ctx, 'Attach Drawing') then
                                        FrstSelItm.Draw = FrstSelItm.Draw or {}
                                        if RemoveDraw then
                                            table.remove(FrstSelItm.Draw, RemoveDraw)
                                            RemoveDraw = nil
                                        end

                                        for i = 1, #FrstSelItm.Draw, 1 do
                                            r.ImGui_AlignTextToFramePadding(ctx)
                                            local rv = r.ImGui_TreeNode(ctx, 'Drawing ' .. i)

                                            SL()
                                            r.ImGui_Text(ctx, ' Type : ')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 100)


                                            local D = FrstSelItm.Draw[i]
                                            local LBL = FxGUID .. LE.Sel_Items[1] .. i
                                            local H = Glob.Height
                                            local W = Win_W
                                            if r.ImGui_BeginCombo(ctx, '## Combo type' .. LBL, D.Type or '', r.ImGui_ComboFlags_NoArrowButton()) then
                                                local function AddOption(str)
                                                    if r.ImGui_Selectable(ctx, str, false) then
                                                        D.Type = str; D.T = str;
                                                    end
                                                end
                                                AddOption('Image')
                                                AddOption('Line')
                                                AddOption('Circle')
                                                AddOption('Circle Filled')
                                                AddOption('Knob Pointer')
                                                AddOption('Knob Range')
                                                AddOption('Knob Circle')
                                                AddOption('Knob Image')
                                                AddOption('Rect')
                                                AddOption('Rect Filled')


                                                r.ImGui_EndCombo(ctx)
                                            end

                                            SL()
                                            if r.ImGui_Button(ctx, 'Delete##' .. i) then
                                                RemoveDraw = i
                                            end



                                            if rv then
                                                local function AddProp(ShownName, Name, width, sl, defaultV, stepSize,
                                                                       min, max, format)
                                                    if ShownName then
                                                        r.ImGui_Text(ctx, ShownName)
                                                        SL()
                                                    end
                                                    if width then r.ImGui_SetNextItemWidth(ctx, width) end
                                                    local FORMAT = format
                                                    if not D[Name] and not defaultV then FORMAT = '' end

                                                    local rv, V = r.ImGui_DragDouble(ctx, '##' .. Name .. LBL,
                                                        D[Name] or defaultV, stepSize or LE.GridSize, min or -W,
                                                        max or W - 10, FORMAT)

                                                    if rv then D[Name] = V end
                                                    if sl then SL() end
                                                    return r.ImGui_IsItemActive(ctx)
                                                end

                                                local BL_Width = { 'Knob Pointer', 'Knob Range' }
                                                local BL_Height = { 'Knob Pointer', 'Knob Range', 'Circle',
                                                    'Circle Filled', 'Knob Circle', 'Knob Image' }
                                                local Thick = { 'Knob Pointer', 'Line', 'Rect', 'Circle' }
                                                local Round = { 'Rect', 'Rect Filled' }
                                                local Gap = { 'Circle', 'Circle Filled', 'Knob Range' }
                                                local BL_XYGap = { 'Knob Pointer', 'Knob Range', 'Knob Circle',
                                                    'Knob Image' }
                                                local RadiusInOut = { 'Knob Pointer', 'Knob Range' }
                                                local Radius = { 'Knob Circle', 'Knob Image' }
                                                local BL_Repeat = { 'Knob Range', 'Knob Circle', 'Knob Image',
                                                    'Knob Pointer' }



                                                local X_Gap_Shown_Name = 'X Gap:'

                                                local DefW, DefH

                                                local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize


                                                if D.Type == 'Image' or D.Type == 'Knob Image' then
                                                    if r.ImGui_BeginChildFrame(ctx, '##drop_files', -R_ofs, 25) then
                                                        if D.Image then
                                                            if TrashIcon(13, 'Image Delete', ClrBG, ClrTint) then
                                                                D.Image, D.FilePath = nil
                                                            end
                                                            SL()
                                                        end
                                                        if not D.FilePath then
                                                            r.ImGui_Text(ctx, 'Drag and drop files here...')
                                                        else
                                                            r.ImGui_Text(ctx, D.FilePath)
                                                        end
                                                        if D.FilePath then
                                                            r.ImGui_Bullet(ctx)
                                                            r.ImGui_TextWrapped(ctx, D.FilePath)
                                                        end
                                                        r.ImGui_EndChildFrame(ctx)
                                                    end

                                                    if r.ImGui_BeginDragDropTarget(ctx) then
                                                        local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
                                                        if rv then
                                                            for i = 0, count - 1 do
                                                                local rv, filename = r.ImGui_GetDragDropPayloadFile(ctx,
                                                                    i)


                                                                path, D.FilePath = CopyImageFile(filename,
                                                                    'Attached Drawings')


                                                                D.Image = r.ImGui_CreateImage(path)
                                                                r.ImGui_Attach(ctx, D.Image)
                                                            end
                                                        end
                                                        r.ImGui_EndDragDropTarget(ctx)
                                                    end
                                                end

                                                local ClrFLG = r.ImGui_ColorEditFlags_NoInputs() +
                                                    r.ImGui_ColorEditFlags_AlphaPreviewHalf() +
                                                    r.ImGui_ColorEditFlags_NoLabel() + r.ImGui_ColorEditFlags_AlphaBar()

                                                r.ImGui_AlignTextToFramePadding(ctx)

                                                local flags = r.ImGui_TableFlags_SizingStretchSame() |
                                                    r.ImGui_TableFlags_Resizable() |
                                                    r.ImGui_TableFlags_BordersOuter() |
                                                    r.ImGui_TableFlags_BordersV() |
                                                    r.ImGui_TableFlags_ContextMenuInBody()|
                                                    r.ImGui_TableFlags_RowBg()



                                                if r.ImGui_BeginTable(ctx, 'testtable', 3, flags, -R_ofs) then
                                                    local function SetRowName(str, notTAB, TAB)
                                                        r.ImGui_TableSetColumnIndex(ctx, 0)
                                                        if TAB then
                                                            if FindExactStringInTable(TAB, D.Type) then
                                                                r.ImGui_Text(ctx, str)
                                                                return true
                                                            end
                                                        elseif notTAB then
                                                            if not FindExactStringInTable(notTAB, D.Type) then
                                                                r.ImGui_Text(ctx, str)
                                                                return true
                                                            end
                                                        else
                                                            r.ImGui_Text(ctx, str)
                                                        end
                                                    end


                                                    --[[ if r.ImGui_IsItemHovered(ctx) then
                                                        tooltip('How much the value is affected by parameter"\"s value ')
                                                    end ]]

                                                    local function AddVal(Name, defaultV, stepSize, min, max, format,
                                                                          NextRow)
                                                        local Column = 1
                                                        if Name:find('_VA') then Column = 2 end
                                                        r.ImGui_TableSetColumnIndex(ctx, Column)

                                                        r.ImGui_PushItemWidth(ctx, -FLT_MIN)

                                                        local FORMAT = format
                                                        if not D[Name] and not defaultV then FORMAT = '' end

                                                        rv, V = r.ImGui_DragDouble(ctx, '##' .. Name .. LBL,
                                                            D[Name] or defaultV, stepSize or LE.GridSize, min or -W,
                                                            max or W - 10, FORMAT)

                                                        if rv then D[Name] = V end

                                                        -- if want to show preview use this.
                                                        --if r.ImGui_IsItemActive(ctx) then FrstSelItm.ShowPreview = FrstSelItm.Num end



                                                        if FrstSelItm.ShowPreview and r.ImGui_IsItemDeactivated(ctx) then FrstSelItm.ShowPreview = nil end

                                                        r.ImGui_PopItemWidth(ctx)
                                                        if Name:find('_VA') or NextRow then r.ImGui_TableNextRow(ctx) end

                                                        return r.ImGui_IsItemActive(ctx)
                                                    end

                                                    local function AddRatio(Name)
                                                        r.ImGui_TableSetColumnIndex(ctx, 3)
                                                        r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                                                        local v = (D[Name] or 1) / (FrstSelItm.Sldr_W or 160)
                                                        local rv, V = r.ImGui_DragDouble(ctx, '##' .. Name .. ' ratio', v,
                                                            0.001, 0, 100, '%.2f')
                                                        r.ImGui_TableNextRow(ctx)
                                                        if rv then return rv, V * (FrstSelItm.Sldr_W or 160) end
                                                    end

                                                    r.ImGui_TableSetupColumn(ctx, '##')
                                                    r.ImGui_TableSetupColumn(ctx, 'Values')
                                                    r.ImGui_TableSetupColumn(ctx, 'Affected Amount')
                                                    r.ImGui_TableNextRow(ctx, r.ImGui_TableRowFlags_Headers())





                                                    r.ImGui_TableHeadersRow(ctx)

                                                    local Sz = FrstSelItm.Sldr_W or 160

                                                    r.ImGui_TableNextRow(ctx)

                                                    local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize
                                                    if D.Type == 'Circle' or D.Type == 'Cicle Filled' then
                                                        WidthLBL = 'Size'; WidthStepSize = 1
                                                    end




                                                    SetRowName('X offset')
                                                    AddVal('X_Offset', 0, LE.GridSize, min, max, nil)
                                                    AddVal('X_Offset_VA')
                                                    SetRowName('Y offset')
                                                    AddVal('Y_Offset', 0, LE.GridSize, -220, 220, nil)
                                                    AddVal('Y_Offset_VA')
                                                    if SetRowName(WidthLBL, BL_Width) then
                                                        AddVal('Width', nil, WidthStepSize, min, max, nil)
                                                        AddVal('Width_VA', 0, 0.01, -1, 1)
                                                    end --[[ local rv, R =  AddRatio('Width' ) if rv then D.Width = R end   ]]
                                                    if SetRowName('Height', BL_Height) then
                                                        AddVal('Height', 0, LE.GridSize, -220, 220, nil)
                                                        AddVal('Height_VA', 0, 0.01, -1, 1)
                                                    end
                                                    if SetRowName('Repeat', BL_Repeat) then
                                                        AddVal('Repeat', 0, 1, 0, 300, '%.0f')
                                                        AddVal('Repeat_VA', 0, 0.01, -1, 1)
                                                    end

                                                    if SetRowName('Gap', nil, Gap) then
                                                        AddVal('Gap', 0, 0.2, 0, 300, '%.1f')
                                                        AddVal('Gap_VA', 0, 0.01, -1, 1)
                                                    end
                                                    if SetRowName('X Gap', BL_XYGap) then
                                                        AddVal('X_Gap', 0, 0.2, 0, 300, '%.1f')
                                                        AddVal('X_Gap_VA', 0, 0.01, -1, 1)
                                                    end
                                                    if SetRowName('Y Gap', BL_XYGap) then
                                                        AddVal('Y_Gap', 0, 0.2, 0, 300, '%.1f')
                                                        AddVal('Y_Gap_VA', 0, 0.01, -1, 1)
                                                    end
                                                    if SetRowName('Angle Min', nil, BL_XYGap) then
                                                        AddVal('Angle_Min',
                                                            0.75, 0.01, 0, 3.14, '%.3f', true)
                                                    end
                                                    if SetRowName('Angle Max', nil, BL_XYGap) then
                                                        AddVal('Angle_Max',
                                                            2.25, 0.01, 0, 3.14, '%.3f', true)
                                                    end
                                                    if SetRowName('Radius Inner', nil, RadiusInOut) then
                                                        AddVal('Rad_In',
                                                            0, 0.1, 0, 300, '%.3f', true)
                                                    end
                                                    if SetRowName('Radius Outer', nil, RadiusInOut) then
                                                        AddVal(
                                                            'Rad_Out', 30, 0.1, 0, 300, '%.3f', true)
                                                    end
                                                    if SetRowName('Radius', nil, Radius) then
                                                        AddVal('Rad_In', 0, 0.1, 0,
                                                            300, '%.3f', true)
                                                    end

                                                    if SetRowName('Thickness', nil, Thick) then
                                                        AddVal('Thick', 2, 0.5, 0,
                                                            60, '%.1f', true)
                                                    end
                                                    if SetRowName('Edge Round', nil, Round) then
                                                        AddVal('Round', 0, 0.1,
                                                            0, 100, '%.1f', true)
                                                    end
                                                    SetRowName('Color')
                                                    r.ImGui_TableSetColumnIndex(ctx, 1)

                                                    local rv, Clr = r.ImGui_ColorEdit4(ctx, 'Color' .. LBL,
                                                        D.Clr or 0xffffffff, ClrFLG)
                                                    if rv then D.Clr = Clr end

                                                    r.ImGui_TableSetColumnIndex(ctx, 2)
                                                    local rv, Clr_VA = r.ImGui_ColorEdit4(ctx, 'Color_VA' .. LBL,
                                                        D.Clr_VA or 0xffffffff, ClrFLG)
                                                    if rv then D.Clr_VA = Clr_VA end


                                                    r.ImGui_TableNextRow(ctx)

                                                    if D.Repeat and D.Repeat ~= 0 then
                                                        SetRowName('Last Repeat\'s Color')
                                                        r.ImGui_TableSetColumnIndex(ctx, 1)

                                                        local rv, Clr = r.ImGui_ColorEdit4(ctx, 'Repeat Color' .. LBL,
                                                            D.RPT_Clr or 0xffffffff, ClrFLG)
                                                        if rv then D.RPT_Clr = Clr end
                                                        r.ImGui_TableNextRow(ctx)
                                                    end


                                                    r.ImGui_EndTable(ctx)
                                                end


                                                r.ImGui_TreePop(ctx)
                                            end
                                        end




                                        if r.ImGui_Button(ctx, 'attach a new drawing') then
                                            table.insert(FrstSelItm.Draw, {})
                                        end


                                        r.ImGui_TreePop(ctx)
                                    end

                                    r.ImGui_PopStyleColor(ctx)
                                end -------------------- End of Repeat for every selected item
                                if LE.SelectedItem == 'Title' then
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x66666688)

                                    r.ImGui_Text(ctx, 'Edge Round:')
                                    r.ImGui_SameLine(ctx)
                                    Edited, FX.Round[FxGUID] = r.ImGui_DragDouble(ctx, '##' .. FxGUID .. 'Round',
                                        FX.Round[FxGUID], 0.01, 0, 40, '%.2f')

                                    r.ImGui_Text(ctx, 'Grab Round:')
                                    r.ImGui_SameLine(ctx)
                                    Edited, FX.GrbRound[FxGUID] = r.ImGui_DragDouble(ctx, '##' .. FxGUID .. 'GrbRound',
                                        FX.GrbRound[FxGUID], 0.01, 0, 40, '%.2f')

                                    r.ImGui_Text(ctx, 'Background Color:')
                                    r.ImGui_SameLine(ctx)
                                    _, FX.BgClr[FxGUID] = r.ImGui_ColorEdit4(ctx, '##' .. FxGUID .. 'BgClr',
                                        FX.BgClr[FxGUID] or FX_Devices_Bg or 0x151515ff,
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if FX.BgClr[FxGUID] == r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()) then
                                        HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                                    end

                                    r.ImGui_Text(ctx, 'FX Title Color:')
                                    r.ImGui_SameLine(ctx)
                                    _, FX[FxGUID].TitleClr = r.ImGui_ColorEdit4(ctx, '##' .. FxGUID .. 'Title Clr',
                                        FX[FxGUID].TitleClr or 0x22222233,
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())

                                    r.ImGui_Text(ctx, 'Custom Title:')
                                    r.ImGui_SameLine(ctx)
                                    local _, CustomTitle = r.ImGui_InputText(ctx, '##CustomTitle' .. FxGUID,
                                        FX[FxGUID].CustomTitle or FX_Name)
                                    if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                        FX[FxGUID].CustomTitle = CustomTitle
                                    end

                                    r.ImGui_PopStyleColor(ctx)
                                end








                                if r.ImGui_BeginPopupModal(ctx, 'Save Editing?') then
                                    SaveEditingPopupModal = true
                                    r.ImGui_Text(ctx, 'Would you like to save the editings?')
                                    if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        FX.LayEdit = nil
                                        LE.SelectedItem = nil
                                        CloseLayEdit = true
                                    end
                                    r.ImGui_SameLine(ctx)

                                    if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                        SaveLayoutEditings(FX_Name, ID, FXGUID[FX_Idx])
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        FX.LayEdit = nil
                                        LE.SelectedItem = nil
                                        CloseLayEdit = true
                                    end
                                    r.ImGui_SameLine(ctx)

                                    if r.ImGui_Button(ctx, '(c) Cancel') or r.ImGui_IsKeyPressed(ctx, 67) or r.ImGui_IsKeyPressed(ctx, 27) then
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end



                                    r.ImGui_EndPopup(ctx)
                                end


                                local PalletteW = 25
                                local Pad = 10
                                if not CloseLayEdit then
                                    w, h = r.ImGui_GetWindowSize(ctx)
                                    r.ImGui_SetCursorPos(ctx, w - PalletteW - Pad, PalletteW + Pad)
                                end




                                for Pal = 1, NumOfColumns or 1, 1 do
                                    if not CloseLayEdit and r.ImGui_BeginChildFrame(ctx, 'Color Palette' .. Pal, PalletteW, h - PalletteW - Pad * 2, r.ImGui_WindowFlags_NoScrollbar()) then
                                        local NumOfPaletteClr = 9

                                        for i, v in ipairs(FX[FxGUID]) do
                                            local function CheckClr(Clr)
                                                if Clr and not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId()) then
                                                    if not tablefind(ClrPallet, Clr) and ClrPallet then
                                                        local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(Clr)
                                                        if A ~= 0 then
                                                            table.insert(ClrPallet, Clr)
                                                        end
                                                    end
                                                end
                                            end
                                            CheckClr(v.Lbl_Clr)
                                            CheckClr(v.V_Clr)
                                            CheckClr(v.BgClr)
                                            CheckClr(v.GrbClr)
                                        end

                                        if FX.Win_Name_S[FX_Idx] then
                                            if Draw[FX.Win_Name_S[FX_Idx]] then
                                                for i, v in ipairs(Draw[FX.Win_Name_S[FX_Idx]].clr) do
                                                    local Clr = v
                                                    if Clr and not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId()) then
                                                        if not tablefind(ClrPallet, Clr) and ClrPallet then
                                                            table.insert(ClrPallet, Clr)
                                                        end
                                                    end
                                                end
                                            end
                                        end

                                        for i, v in ipairs(ClrPallet) do
                                            clrpick, LblColor1 = r.ImGui_ColorEdit4(ctx, '##ClrPalette' .. Pal ..
                                                i .. FxGUID, v,
                                                r.ImGui_ColorEditFlags_NoInputs()|
                                                r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                r.ImGui_ColorEditFlags_AlphaBar())
                                            if r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                                table.remove(ClrPallet, tablefind(v))
                                            end
                                        end


                                        --[[ for i=1, NumOfPaletteClr , 1 do
                                            PaletteClr= 'PaletteClr'..Pal..i..FxGUID
                                            local DefaultClr        = r.ImGui_ColorConvertHSVtoRGB((i-0.5)*(NumOfColumns or 1) / 7.0, 0.5, 0.5, 1)
                                            clrpick,  _G[PaletteClr] = r.ImGui_ColorEdit4( ctx, '##ClrPalette'..Pal..i..FxGUID,  _G[PaletteClr] or  DefaultClr , r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) and i==NumOfPaletteClr  then NumOfColumns=(NumOfColumns or 1 )   +1    end
                                            if r.ImGui_BeginDragDropTarget( ctx) then HighlightSelectedItem(0x00000000 ,0xffffffff, 0, L,T,R,B,h,w, 1, 1,'GetItemRect', 'Foreground') end
                                        end  ]]
                                        r.ImGui_EndChildFrame(ctx)
                                    end
                                    if NumOfColumns or 1 > 1 then
                                        for i = 1, NumOfColumns, 1 do r.ImGui_SameLine(ctx, nil, 0) end
                                    end
                                end





                                if r.ImGui_BeginPopupModal(ctx, 'Save Draw Editing?') then
                                    r.ImGui_Text(ctx, 'Would you like to save the Drawings?')
                                    if r.ImGui_Button(ctx, '(n) No') then
                                        local FxNameS = FX.Win_Name_S[FX_Idx]
                                        local HowManyToDelete
                                        for i, Type in pairs(Draw[FxNameS].Type) do
                                            HowManyToDelete = i
                                        end

                                        for Del = 1, HowManyToDelete, 1 do
                                            local D = Draw[FxNameS]
                                            table.remove(D.Type, i)
                                            table.remove(D.L, i)
                                            table.remove(D.R, i)
                                            table.remove(D.T, i)
                                            table.remove(D.B, i)
                                            if D.Txt[i] then table.remove(D.Txt, i) end
                                            if D.clr[i] then table.remove(D.clr, i) end
                                        end
                                        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        Draw.DrawMode[FxGUID] = nil
                                    end
                                    r.ImGui_SameLine(ctx)

                                    if r.ImGui_Button(ctx, '(y) Yes') then
                                        SaveDrawings(FX_Idx, FxGUID)
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        Draw.DrawMode[FxGUID] = nil
                                    end
                                    r.ImGui_EndPopup(ctx)
                                end



                                if r.ImGui_IsKeyPressed(ctx, 65) and (Mods == Apl or Mods == Alt) then
                                    for Fx_P = 1, #FX[FxGUID] or 0, 1 do table.insert(LE.Sel_Items, Fx_P) end
                                end


                                r.ImGui_End(ctx)
                                if CloseLayEdit then
                                    FX.LayEdit = nil
                                    Draw.DrawMode[FxGUID] = nil
                                end
                            end





                            r.ImGui_SameLine(ctx, nil, 0)
                            --r.ImGui_PushStyleVar( ctx,r.ImGui_StyleVar_WindowPadding(), 0,0)
                            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0x00000000)



                            --if ctrl+A or Command+A is pressed


                            --r.ImGui_EndTooltip(ctx)

                            -- r.ImGui_PopStyleVar(ctx)
                            --r.ImGui_PopStyleColor(ctx,2 )
                            PopClr(ctx, 2)
                        end

                        if AdjustDrawRectPos and IsLBtnHeld then
                            local DtX, DtY = r.ImGui_GetMouseDelta(ctx)
                            Mx, My = r.ImGui_GetMousePos(ctx)
                            FDL = r.ImGui_GetForegroundDrawList(ctx)

                            r.ImGui_DrawList_AddRectFilled(FDL, Draw.Rect.L, Draw.Rect.T, Draw.Rect.R, Draw.Rect.B,
                                0xbbbbbb66)
                        else
                            AdjustDrawRectPos = nil
                        end

                        if Draw.Rect.L then
                            r.ImGui_DrawList_AddRectFilled(FDL, Draw.Rect.L, Draw.Rect.T, Draw.Rect.R,
                                Draw.Rect.B, 0xbbbbbb66, Draw.Df_EdgeRound[FxGUID] or 0)
                        end
                    elseif --[[FX Layer Window ]] string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then --!!!!  FX Layer Window
                        if not FX[FxGUID].Collapse then
                            FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                            r.TrackFX_Show(LT_Track, FX_Idx, 2)

                            r.ImGui_SameLine(ctx, nil, 0)
                            --Gives the index of the specific MixRack
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(),
                                FX_Layer_Container_BG or BGColor_FXLayeringWindow)
                            FXLayeringWin_X = 240; local Pad = 3
                            if r.ImGui_BeginChildFrame(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, FXLayeringWin_X + Pad, 220, r.ImGui_WindowFlags_NoScrollbar()) then
                                local WDL = r.ImGui_GetWindowDrawList(ctx)
                                FXLayerFrame_PosX_L, FXLayerFrame_PosY_T = r.ImGui_GetItemRectMin(ctx)
                                FXLayerFrame_PosX_R, FXLayerFrame_PosY_B = r.ImGui_GetItemRectMax(ctx); FXLayerFrame_PosY_B =
                                    FXLayerFrame_PosY_B + 220

                                local clrhdrhvr = r.ImGui_GetColor(ctx, r.ImGui_Col_ButtonHovered())
                                local clrhdrAct = r.ImGui_GetColor(ctx, r.ImGui_Col_ButtonActive())

                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), clrhdrhvr)
                                local clrhdr = r.ImGui_GetColor(ctx, r.ImGui_Col_Button())
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TableHeaderBg(), clrhdr)

                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, 0)


                                r.ImGui_BeginTable(ctx, '##FX Layer' .. FX_Idx, 1)
                                r.ImGui_TableHeadersRow(ctx)


                                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                                    DragFX_ID = FX_Idx
                                    r.ImGui_SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                                    r.ImGui_EndDragDropSource(ctx)
                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end
                                if r.ImGui_IsItemClicked(ctx, 0) and Mods == Alt then
                                    FX[FxGUID].DeleteFXLayer = true
                                elseif r.ImGui_IsItemClicked(ctx, 1) then
                                    FX[FxGUID].Collapse = true
                                    FX[FxGUID].CollapseWidth = 27
                                elseif r.ImGui_IsItemClicked(ctx) and Mods == Shift then
                                    local Spltr, FX_Inst
                                    if FX[FxGUID].LyrDisable == nil then FX[FxGUID].LyrDisable = false end
                                    FX[FxGUID].AldreadyBPdFXs = FX[FxGUID].AldreadyBPdFXs or {}





                                    for i = 0, Sel_Track_FX_Count, 1 do
                                        if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                                            if not FX[FxGUID].LyrDisable then
                                                if r.TrackFX_GetEnabled(LT_Track, i) == false then
                                                    if FX[FxGUID].AldreadyBPdFXs == {} then
                                                        table.insert(FX[FxGUID].AldreadyBPdFXs,
                                                            r.TrackFX_GetFXGUID(LT_Track, i))
                                                    elseif not FindStringInTable(FX[FxGUID].AldreadyBPdFXs, r.TrackFX_GetFXGUID(LT_Track, i)) then
                                                        table.insert(FX[FxGUID].AldreadyBPdFXs,
                                                            r.TrackFX_GetFXGUID(LT_Track, i))
                                                    end
                                                else
                                                end
                                                r.TrackFX_SetEnabled(LT_Track, i, false)
                                            else
                                                r.TrackFX_SetEnabled(LT_Track, i, true)
                                            end

                                            for ii, v in pairs(FX[FxGUID].AldreadyBPdFXs) do
                                                if v == FXGUID[i] then r.TrackFX_SetEnabled(LT_Track, i, false) end
                                            end
                                        end
                                    end


                                    if not FX[FxGUID].LyrDisable then
                                        r.TrackFX_SetEnabled(LT_Track, FX_Idx, false)
                                    else
                                        r.TrackFX_SetEnabled(LT_Track, FX_Idx, true)
                                        FX[FxGUID].AldreadyBPdFXs = {}
                                    end

                                    if FX[FxGUID].LyrDisable then FX[FxGUID].LyrDisable = false else FX[FxGUID].LyrDisable = true end
                                end


                                if not FXLayerRenaming then
                                    if LBtnClickCount == 2 and r.ImGui_IsItemActivated(ctx) then
                                        FX[FxGUID].RenameFXLayering = true
                                    elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                                        BlinkFX = ToggleCollapseAll(FX_Idx)
                                    end
                                end


                                r.ImGui_SameLine(ctx)
                                r.ImGui_AlignTextToFramePadding(ctx)
                                if not FX[FxGUID].RenameFXLayering then
                                    r.ImGui_SetNextItemWidth(ctx, 10)
                                    local TitleShort
                                    if string.len(FX[FxGUID].ContainerTitle or '') > 27 then
                                        TitleShort = string.sub(FX[FxGUID].ContainerTitle, 1, 27)
                                    end
                                    r.ImGui_Text(ctx, TitleShort or FX[FxGUID].ContainerTitle or 'FX Layering')
                                else -- If Renaming
                                    local Flag
                                    r.ImGui_SetNextItemWidth(ctx, 180)
                                    if FX[FxGUID].ContainerTitle == 'FX Layering' then
                                        Flag = r
                                            .ImGui_InputTextFlags_AutoSelectAll()
                                    end
                                    _, FX[FxGUID].ContainerTitle = r.ImGui_InputText(ctx, '##' .. FxGUID,
                                        FX[FxGUID].ContainerTitle or 'FX Layering', Flag)

                                    r.ImGui_SetItemDefaultFocus(ctx)
                                    r.ImGui_SetKeyboardFocusHere(ctx, -1)

                                    if r.ImGui_IsItemDeactivated(ctx) then
                                        FX[FxGUID].RenameFXLayering = nil
                                        r.SetProjExtState(0, 'FX Devices - ', 'FX' .. FxGUID ..
                                            'FX Layer Container Title ', FX[FxGUID].ContainerTitle)
                                    end
                                end

                                --r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(), 0xffffff10)

                                r.ImGui_SameLine(ctx, FXLayeringWin_X - 25, 0)
                                r.ImGui_AlignTextToFramePadding(ctx)
                                if not FX[FxGUID].SumMode then
                                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)
                                end
                                local Lbl
                                if FX[FxGUID].SumMode == 0 then Lbl = 'Avg' else Lbl = 'Sum' end
                                if r.ImGui_Button(ctx, (Lbl or '') .. '##FX Lyr Mode' .. FxGUID, 30, r.ImGui_GetTextLineHeight(ctx)) then
                                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)

                                    if FX[FxGUID].SumMode == 0 then
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 1)
                                        FX[FxGUID].SumMode = 1
                                    else
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 0)
                                        FX[FxGUID].SumMode = 0
                                    end
                                end

                                --r.ImGui_PopStyleColor(ctx)
                                r.ImGui_PopStyleVar(ctx)

                                r.ImGui_EndTable(ctx)
                                r.ImGui_PopStyleColor(ctx, 2) --Header Clr
                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 0)
                                --r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgActive(), 0x99999999)
                                local StyleVarPop = 1
                                local StyleClrPop = 1


                                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)



                                local MaxChars

                                if FX[FxGUID].ActiveLyrCount <= 4 then
                                    LineH = 4; Spacing = 0; Inner_Spacing = 2; BtnSizeManual = 34; MaxChars = 15
                                elseif FX[FxGUID].ActiveLyrCount == 5 then
                                    LineH, Spacing, Inner_Spacing = 3, -5, 0; BtnSizeManual = 30; MaxChars = 18
                                elseif FX[FxGUID].ActiveLyrCount == 6 then
                                    LineH, Spacing, Inner_Spacing = 5.5, -5, -8; BtnSizeManual = 24; MaxChars = 20
                                elseif FX[FxGUID].ActiveLyrCount >= 7 then
                                    LineH, Spacing, Inner_Spacing = 3, -5, -8; BtnSizeManual = 19; MaxChars = 23
                                end



                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 1, Spacing)
                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4, LineH)

                                local BtnSize, AnySoloChan
                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                        FX[FxGUID].AnySoloChan = true
                                        AnySoloChan = true
                                    end
                                end
                                if not AnySoloChan then FX[FxGUID].AnySoloChan = nil end


                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    if Lyr.Solo[LyrID .. FxGUID] == nil then
                                        Lyr.Solo[LyrID .. FxGUID] = reaper
                                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)))
                                    end
                                    if Lyr.Solo[LyrID .. FxGUID] == 1 then FX[FxGUID].AnySoloChan = true end
                                    if Lyr.Mute[LyrID .. FxGUID] == nil then
                                        Lyr.Mute[LyrID .. FxGUID] = reaper
                                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                                    end
                                    if Lyr.Mute[LyrID .. FxGUID] == 1 then FX[FxGUID].AnyMuteChan = true end

                                    if Lyr.ProgBarVal[LyrID .. FxGUID] == nil then
                                        Layer1Vol = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                                        Lyr.ProgBarVal[LyrID .. FxGUID] = Layer1Vol
                                    end

                                    LyrFX_Inst = math.max(LyrFX_Inst or 0, LyrID)
                                    local HowManyFXinLyr = 0
                                    for i = 0, Sel_Track_FX_Count, 1 do
                                        if FX.InLyr[FXGUID[i]] == FXGUID_RackMixer and FX[FXGUID[i]].inWhichLyr == LyrID then
                                            HowManyFXinLyr = HowManyFXinLyr + 1
                                        end
                                    end


                                    local Fx_P = (LyrID * 2) - 1

                                    local CurY = r.ImGui_GetCursorPosY(ctx)
                                    if FX[FxGUID][Fx_P] then
                                        LyrCurX, LyrCurY = r.ImGui_GetCursorScreenPos(ctx)

                                        if Lyr.Rename[LyrID .. FxGUID] ~= true and Fx_P then
                                            --r.ImGui_ProgressBar(ctx, Lyr.ProgBarVal[LyrID..FxGUID], FXLayeringWin_X-60, 30, '##Layer'.. LyrID)
                                            local P_Num = 1 + (5 * (LyrID - 1))
                                            local ID = LyrID
                                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}

                                            local labeltoShow = FX[FxGUID].LyrTitle[ID] or LyrID

                                            if string.len(labeltoShow or '') > MaxChars then
                                                labeltoShow = string.sub(FX[FxGUID].LyrTitle[ID], 1, MaxChars)
                                            end
                                            local Fx_P = LyrID * 2 - 1
                                            local Label = '##' .. LyrID .. FxGUID
                                            FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
                                            FX[FxGUID][Fx_P].V = FX[FxGUID][Fx_P].V or 0.5
                                            local p_value = FX[FxGUID][Fx_P].V or 0
                                            --[[ r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, BtnSizeManual/3) ]]
                                            --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), getClr(r.ImGui_Col_Button())) ]]
                                            SliderStyle = nil; Rounding = 0
                                            local CurY = r.ImGui_GetCursorPosY(ctx)
                                            AddDrag(ctx, Label, labeltoShow, p_value, 0, 1, Fx_P, FX_Idx, P_Num,
                                                'FX Layering', FXLayeringWin_X - BtnSizeManual * 3 - 23, Inner_Spacing,
                                                Disable, Lbl_Clickable, 'Bottom', 'Bottom', DragDir, 'NoInput')
                                            --[[ r.ImGui_PopStyleColor(ctx)  r.ImGui_PopStyleVar(ctx) ]]

                                            local L, T = r.ImGui_GetItemRectMin(ctx); B = T + BtnSizeManual
                                            BtnSize = B - T
                                            r.ImGui_SameLine(ctx, nil, 10)
                                            r.ImGui_SetCursorPosY(ctx, CurY)

                                            if Lyr.Selected[FXGUID_RackMixer] == LyrID then
                                                local R = L + FXLayeringWin_X
                                                r.ImGui_DrawList_AddLine(WDL, L, T - 2, R - 2 + Pad, T - 2, 0x99999999)
                                                r.ImGui_DrawList_AddLine(WDL, L, B, R - 2 + Pad, B, 0x99999999)
                                                r.ImGui_DrawList_AddRectFilled(WDL, L, T - 2, R + Pad, B, 0xffffff09)
                                                FX[FxGUID].TheresFXinLyr = nil
                                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]] then
                                                        if FX[FXGUID[FX_Idx]].inWhichLyr == LyrID and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                            r.ImGui_DrawList_AddLine(WDL, R - 2 + Pad, T, R - 2 + Pad,
                                                                FXLayerFrame_PosY_T, 0x99999999)
                                                            r.ImGui_DrawList_AddLine(WDL, R - 2 + Pad, B, R - 2 + Pad,
                                                                FXLayerFrame_PosY_B, 0x99999999)
                                                            FX[FxGUID].TheresFXinLyr = true
                                                        end
                                                    end
                                                end
                                                if not FX[FxGUID].TheresFXinLyr then
                                                    r.ImGui_DrawList_AddLine(WDL, R, T, R, B, 0x99999999)
                                                else
                                                end
                                            end

                                            if r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                                local TheresFXinLyr
                                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                        TheresFXinLyr = true
                                                    end
                                                end

                                                FX_Idx_RackMixer = FX_Idx
                                                function DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                                    FX[FxGUID].LyrID[LyrID] = -1
                                                    FX[FxGUID].LyrTitle[LyrID] = nil
                                                    FX[FxGUID].ActiveLyrCount = math.max(FX[FxGUID].ActiveLyrCount - 1, 1)
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1), 0) -- turn channel power off
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        1 + (5 * (LyrID - 1) + 1),
                                                        0.5) -- set pan to center
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 1 + (5 * (LyrID - 1)),
                                                        0.5) -- set Vol to 0
                                                    r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID ..
                                                        'Layer ID ' .. LyrID, '-1')
                                                    r.SetProjExtState(0, 'FX Devices - ',
                                                        'FX' .. FxGUID .. 'Layer Title ' .. LyrID, '')
                                                end

                                                if not TheresFXinLyr then
                                                    DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                                else
                                                    local Modalw, Modalh = 225, 70
                                                    r.ImGui_SetNextWindowPos(ctx,
                                                        VP.x + VP.w / 2 - Modalw / 2,
                                                        VP.y + VP.h / 2 - Modalh / 2)
                                                    r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                                    r.ImGui_OpenPopup(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' ..
                                                        FxGUID)
                                                end
                                            elseif r.ImGui_IsItemClicked(ctx) and LBtnDC then
                                                FX[FxGUID][Fx_P].V = 0.5
                                                local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num,
                                                    0.5)
                                            elseif r.ImGui_IsItemClicked(ctx) and Mods == Ctrl and not FXLayerRenaming then
                                                Lyr.Rename[LyrID .. FxGUID] = true
                                            elseif r.ImGui_IsItemClicked(ctx) and Mods == 0 then
                                                Lyr.Selected[FXGUID_RackMixer] = LyrID
                                            end
                                        elseif Lyr.Rename[LyrID .. FxGUID] == true then
                                            for i = 1, 8, 1 do -- set all other layer's rename to false
                                                if LyrID ~= i then Lyr.Rename[i .. FxGUID] = false end
                                            end
                                            FXLayerRenaming = true
                                            r.ImGui_SetKeyboardFocusHere(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, FXLayeringWin_X - BtnSizeManual * 3 - 23)
                                            local ID = FX[FxGUID].LyrID[LyrID]
                                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}
                                            _, FX[FxGUID].LyrTitle[ID] = r.ImGui_InputText(ctx, '##' .. LyrID,
                                                FX[FxGUID].LyrTitle[ID])

                                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                                Lyr.Rename[LyrID .. FxGUID] = false
                                                FXLayerRenaming = nil
                                                r.SetProjExtState(0, 'FX Devices - ', 'FX' ..
                                                    FxGUID .. 'Layer Title ' .. LyrID, FX[FxGUID].LyrTitle[ID])
                                            elseif r.ImGui_IsItemDeactivated(ctx) then
                                                Lyr.Rename[LyrID .. FxGUID] = false
                                                FXLayerRenaming = nil
                                            end
                                            SL(nil, 10)
                                        end

                                        ------------ Confirm delete layer ---------------------
                                        if r.ImGui_BeginPopupModal(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' .. FxGUID, true, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                                            r.ImGui_Text(ctx, 'Delete all FXs in layer ' .. LyrID .. '?')
                                            r.ImGui_Text(ctx, ' ')

                                            if r.ImGui_Button(ctx, '(n) No (or Esc)') or r.ImGui_IsKeyPressed(ctx, 78) or r.ImGui_IsKeyPressed(ctx, 27) then
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                            r.ImGui_SameLine(ctx, nil, 20)
                                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                                r.Undo_BeginBlock()
                                                local L, H, HowMany = 999, 0, 0

                                                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                        HowMany = HowMany + 1
                                                        L = math.min(FX_Idx, L)
                                                        H = math.max(FX_Idx, H)
                                                    end
                                                end

                                                for i = 1, HowMany, 1 do
                                                    if FX[FXGUID[L]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[L]] == FXGUID_RackMixer then
                                                        r.TrackFX_Delete(LT_Track, L)
                                                    end
                                                end
                                                DeleteOneLayer(LyrID, FXGUID_RackMixer, FX_Idx_RackMixer, LT_Track)

                                                diff = H - L + 1
                                                r.Undo_EndBlock('Delete Layer ' .. LyrID, 0)
                                            end
                                            r.ImGui_EndPopup(ctx)
                                        end




                                        ProgBar_Pos_L, ProgBar_PosY_T = r.ImGui_GetItemRectMin(ctx)
                                        ProgBar_Pos_R, ProgBar_PosY_B = r.ImGui_GetItemRectMax(ctx)





                                        if Lyr.Selected[FXGUID_RackMixer] == LyrID and Lyr.Rename[LyrID .. FxGUID] ~= true then
                                            r.ImGui_DrawList_AddRect(drawlist, ProgBar_Pos_L, ProgBar_PosY_T,
                                                FXLayerFrame_PosX_R, ProgBar_PosY_B, 0xffffffff)
                                        end

                                        drawlistInFXLayering = r.ImGui_GetForegroundDrawList(ctx)


                                        if r.ImGui_BeginDragDropTarget(ctx) then
                                            dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag') --

                                            if dropped and Mods == 0 then
                                                DropFXtoLayer(FX_Idx, LayerNum)
                                            elseif dropped and Mods == Apl then
                                                DragFX_Src = DragFX_ID
                                                if DragFX_ID > FX_Idx then
                                                    DragFX_Dest = FX_Idx - 1
                                                else
                                                    DragFX_Dest =
                                                        FX_Idx
                                                end
                                                DropToLyrID = LyrID
                                                DroptoRack = FXGUID_RackMixer
                                            end
                                            if Payload_Type == 'AddFX_Sexan' then
                                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan') --
                                                if dropped then
                                                    r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx)

                                                    DropFXtoLayer(FX_Idx, LyrID)
                                                end
                                            end

                                            HighlightSelectedItem(0x88888844, 0xffffffff, 0, L, T, R, B, h, w,
                                                H_OutlineSc, V_OutlineSc, 'GetItemRect')
                                            r.ImGui_EndDragDropTarget(ctx)
                                        end

                                        local Label = '##Pan' .. LyrID .. FxGUID

                                        local P_Num = 1 + (5 * (LyrID - 1) + 1)
                                        local Fx_P_Knob = LyrID * 2
                                        local Label = '## Pan' .. LyrID .. FxGUID
                                        local p_value_Knob = FX[FxGUID][Fx_P_Knob].V
                                        local labeltoShow = HowManyFXinLyr



                                        AddKnob(ctx, Label, labeltoShow, p_value_Knob, 0, 1, Fx_P_Knob, FX_Idx, P_Num,
                                            'FX Layering', BtnSizeManual / 2, 0, Disabled, 9, 'Within', 'None')
                                        r.ImGui_SameLine(ctx, nil, 10)

                                        if LBtnDC and r.ImGui_IsItemClicked(ctx, 0) then
                                            FX[FxGUID][Fx_P_Knob].V = 0.5
                                            local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0.5)
                                        end

                                        r.ImGui_SetCursorPosY(ctx, CurY)

                                        if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                            local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Act)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Hvr)

                                            SoloBtnClrPop = 3
                                        end

                                        ClickOnSolo = r.ImGui_Button(ctx, 'S##' .. LyrID, BtnSizeManual, BtnSizeManual) -- ==  lyr solo

                                        if Lyr.Solo[LyrID .. FxGUID] == 1 then r.ImGui_PopStyleColor(ctx, SoloBtnClrPop) end


                                        if ClickOnSolo then
                                            Lyr.Solo[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                                LT_Track,
                                                FX_Idx, 4 + (5 * (LyrID - 1)))
                                            if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                                Lyr.Solo[LyrID .. FxGUID] = 0
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                    4 + (5 * (LyrID - 1)),
                                                    Lyr.Solo[LyrID .. FxGUID])
                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x9ed9d3ff)
                                                r.ImGui_PopStyleColor(ctx)
                                            elseif Lyr.Solo[LyrID .. FxGUID] == 0 then
                                                Lyr.Solo[LyrID .. FxGUID] = 1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                    4 + (5 * (LyrID - 1)),
                                                    Lyr.Solo[LyrID .. FxGUID])
                                            end
                                        end
                                        if Lyr.Solo[LyrID .. FxGUID] == nil then
                                            Lyr.Solo[LyrID .. FxGUID] = reaper
                                                .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                    4 + (5 * (LyrID - 1)))
                                        end

                                        r.ImGui_SameLine(ctx, nil, 3)
                                        r.ImGui_SetCursorPosY(ctx, CurY)
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                                            local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Act)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Hvr)
                                            LyrMuteClrPop = 3
                                        end
                                        ClickOnMute = r.ImGui_Button(ctx, 'M##' .. LyrID, BtnSizeManual, BtnSizeManual)
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then r.ImGui_PopStyleColor(ctx, LyrMuteClrPop) end



                                        if Lyr.Mute[LyrID .. FxGUID] == nil then
                                            Lyr.Mute[LyrID .. FxGUID] = reaper
                                                .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                                        end

                                        if ClickOnMute then
                                            Lyr.Mute[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                                LT_Track,
                                                FX_Idx, 5 * (LyrID - 1))
                                            if Lyr.Mute[LyrID .. FxGUID] == 1 then
                                                Lyr.Mute[LyrID .. FxGUID] = 0
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                    5 * (LyrID - 1),
                                                    Lyr.Mute[LyrID .. FxGUID])
                                            elseif Lyr.Mute[LyrID .. FxGUID] == 0 then
                                                Lyr.Mute[LyrID .. FxGUID] = 1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1),
                                                    Lyr.Mute[LyrID .. FxGUID])
                                            end
                                        end




                                        MuteBtnR, MuteBtnB = r.ImGui_GetItemRectMax(ctx)

                                        if FX[FxGUID].AnySoloChan then
                                            if Lyr.Solo[LyrID .. FxGUID] ~= 1 then
                                                r.ImGui_DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                                    0x00000088)
                                            end
                                        end
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                                            r.ImGui_DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                                0x00000088)
                                        end
                                    end
                                end




                                if FX[FxGUID].ActiveLyrCount ~= 8 then
                                    AddNewLayer = r.ImGui_Button(ctx, '+', FXLayeringWin_X, 25)
                                    if AddNewLayer then
                                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                                        if FX[FxGUID].ActiveLyrCount <= 8 then
                                            local EmptyChan, chan1, chan2, chan3; local lastnum = 0
                                            for i, v in ipairs(FX[FxGUID].LyrID) do
                                                if not EmptyChan then
                                                    if v == -1 then EmptyChan = i end
                                                end
                                            end

                                            if not EmptyChan then EmptyChan = FX[FxGUID].ActiveLyrCount + 1 end
                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (EmptyChan - 1), 1)
                                            FX[FxGUID].ActiveLyrCount = math.min(FX[FxGUID].ActiveLyrCount + 1, 8)
                                            FX[FxGUID][EmptyChan * 2 - 1].V = 0.5 -- init val for Vol
                                            FX[FxGUID][EmptyChan * 2].V = 0.5     -- init val for Pan

                                            FX[FxGUID].LyrID[EmptyChan] = EmptyChan

                                            r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Layer ID ' .. EmptyChan,
                                                EmptyChan)
                                        end
                                    end
                                end
                                r.ImGui_PopStyleVar(ctx, StyleVarPop)
                                r.ImGui_PopStyleVar(ctx, 2)

                                r.ImGui_EndChildFrame(ctx)
                            end
                            r.ImGui_PopStyleColor(ctx, StyleClrPop)
                        else -- if collapsed
                            if r.ImGui_BeginChildFrame(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, 27, 220, r.ImGui_WindowFlags_NoScrollbar()) then
                                L, T = r.ImGui_GetItemRectMin(ctx)
                                local DL = r.ImGui_GetWindowDrawList(ctx)
                                local title = (FX[FxGUID].ContainerTitle or 'FX Layering'):gsub("(.)", "%1\n")

                                WindowBtnVertical = r.ImGui_Button(ctx, title .. '##Vertical', 25, 220) -- create window name button
                                if WindowBtnVertical and Mods == 0 then
                                elseif WindowBtnVertical == true and Mods == Shift then
                                    ToggleBypassFX()
                                elseif r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                    FX[FxGUID].DeleteFXLayer = true
                                elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                                    FX[FxGUID].Collapse = nil
                                elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                                    BlinkFX = ToggleCollapseAll(FX_Idx)
                                end

                                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_None()) then
                                    DragFX_ID = FX_Idx
                                    r.ImGui_SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                                    r.ImGui_EndDragDropSource(ctx)
                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end

                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                                r.ImGui_DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)


                                r.ImGui_EndChildFrame(ctx)
                            end
                        end

                        FX[FxGUID].DontShowTilNextFullLoop = true

                        if not FX[FxGUID].Collapse then --Create FX windows inside rack
                            local Sel_LyrID
                            drawlist = r.ImGui_GetBackgroundDrawList(ctx)


                            Lyr.FrstFXPos[FXGUID_RackMixer] = nil
                            local HowManyFXinLyr = 0
                            for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                                local FXisInLyr

                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)

                                    if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] then --if fx is in rack mixer
                                        if FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then end

                                        if Lyr.Selected[FXGUID_RackMixer] == nil then Lyr.Selected[FXGUID_RackMixer] = 1 end
                                        local FXGUID_LayerCheck = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                                        if FX[FXGUID[FX_Idx_InLayer]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and LyrID == Lyr.Selected[FXGUID_RackMixer] and not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                                            r.ImGui_SameLine(ctx, nil, 0)

                                            AddSpaceBtwnFXs(FX_Idx_InLayer, false, nil, LyrID)
                                            Xpos_Left, Ypos_Top = r.ImGui_GetItemRectMin(ctx)
                                            r.ImGui_SameLine(ctx, nil, 0)
                                            if not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                                                createFXWindow(FX_Idx_InLayer)
                                            else
                                            end
                                            Sel_LyrID = LyrID

                                            Xpos_Right, Ypos_Btm = r.ImGui_GetItemRectMax(ctx)

                                            r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right,
                                                Ypos_Top, Clr.Dvdr.outline)
                                            r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right,
                                                Ypos_Btm, Clr.Dvdr.outline)
                                        end
                                        FXisInLyr = true
                                    end
                                end
                                if FXisInLyr == true then HowManyFXinLyr = HowManyFXinLyr + 1 end

                                if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] then
                                    if Lyr.FrstFXPos[FXGUID_RackMixer] == nil then
                                        Lyr.FrstFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                                    else
                                        Lyr.FrstFXPos[FXGUID_RackMixer] = math.min(Lyr.FrstFXPos[FXGUID_RackMixer],
                                            FX_Idx_InLayer)
                                    end
                                    Lyr.LastFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                                end

                                r.ImGui_SameLine(ctx, nil, 0)
                            end


                            Lyr[FXGUID_RackMixer] = Lyr[FXGUID_RackMixer] or {}
                            Lyr[FXGUID_RackMixer].HowManyFX = HowManyFXinLyr



                            if HowManyFXinLyr > 0 and FX[FxGUID].TheresFXinLyr then -- ==  Add and theres fx in selected layer
                                --if there's fx in the rack

                                AddLastSPCinRack = true

                                AddSpaceBtwnFXs(FX_Idx, nil, nil, Sel_LyrID)
                                AddLastSPCinRack = false
                                Xpos_Right, Ypos_Btm = r.ImGui_GetItemRectMax(ctx)
                                Xpos_Left, Ypos_Top = r.ImGui_GetItemRectMin(ctx)


                                local TheresFXinLyr
                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                    if FX[FXGUID[FX_Idx]] then
                                        if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[Lyr.Selected[FXGUID_RackMixer]] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                            TheresFXinLyr = true
                                        end
                                    end
                                end


                                if TheresFXinLyr then --==  lines to enclose fx layering
                                    r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right, Ypos_Top,
                                        Clr.Dvdr.outline)
                                    r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right, Ypos_Btm,
                                        Clr.Dvdr.outline)
                                    r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Right, Ypos_Top, Xpos_Right, Ypos_Btm,
                                        Clr.Dvdr.outline, 14)
                                end
                            end
                        end







                        if FX[FxGUID].DeleteFXLayer then
                            local FXinRack = 0
                            --count number of fxs in layer
                            for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                                    if FX.InLyr[GUID] == FXGUID[FX_Idx] then
                                        FXinRack = FXinRack + 1
                                    end
                                end
                            end

                            if FXinRack == 0 then -- if no fx just delete
                                r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                                r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                                FX[FxGUID].DeleteFXLayer = nil
                            else -- else prompt user
                                local Modalw, Modalh = 270, 55
                                r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                    VP.y + VP.h / 2 - Modalh / 2)
                                r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                r.ImGui_OpenPopup(ctx, 'Delete FX Layer? ##' .. FxGUID)
                            end
                        end

                        if r.ImGui_BeginPopupModal(ctx, 'Delete FX Layer? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                            r.ImGui_Text(ctx, 'Delete the FXs in layers altogether?')
                            if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                                        --sets input channel
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                                        --sets Output
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)
                                        FX.InLyr[FXGUID[i]] = nil
                                        r.SetProjExtState(0, 'FX Devices',
                                            'FXLayer - ' .. 'is FX' .. FXGUID[i] .. 'in layer', "")
                                    end
                                end

                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FXGUID[FX_Idx] == Lyr.SplitrAttachTo[FXGUID[i]] then
                                        r.TrackFX_Delete(LT_Track, FX_Idx)
                                        r.TrackFX_Delete(LT_Track, i)
                                    end
                                end

                                FX[FxGUID].DeleteFXLayer = nil
                            end
                            r.ImGui_SameLine(ctx)

                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                local Spltr, FX_Inst
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FXGUID[FX_Idx] == Lyr.SplitrAttachTo[FXGUID[i]] then
                                        Spltr = i
                                    end
                                end
                                r.Undo_BeginBlock()

                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                                        FX_Inst = (FX_Inst or 0) + 1
                                        r.SetProjExtState(0, 'FX Devices',
                                            'FXLayer - ' .. 'is FX' .. FXGUID[i] .. 'in layer', "")
                                    end
                                end

                                for i = 0, FX_Inst, 1 do
                                    r.TrackFX_Delete(LT_Track, Spltr)
                                end



                                FX[FxGUID].DeleteFXLayer = nil
                                r.Undo_EndBlock('Delete Layer Container', 0)
                            end
                            r.ImGui_SameLine(ctx)

                            if r.ImGui_Button(ctx, '(c) Cancel  (or Esc)') or r.ImGui_IsKeyPressed(ctx, 67) or r.ImGui_IsKeyPressed(ctx, 27) then
                                FX[FxGUID].DeleteFXLayer = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                            end
                            r.ImGui_SameLine(ctx)

                            r.ImGui_EndPopup(ctx)
                        end

                        r.ImGui_SameLine(ctx, nil, 0)
                        FX[FXGUID[FX_Idx]].DontShowTilNextFullLoop = true
                    elseif FX_Name:find('FXD ReSpectrum') then
                        local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        --if FX below is not Pro-Q 3
                        if string.find(FX_Name_After, 'Pro%-Q 3') == nil then
                            ProQ3.SpectrumDeleteWait = (ProQ3.SpectrumDeleteWait or 0) + 1
                            if ProQ3.SpectrumDeleteWait > FX_Add_Del_WaitTime then
                                if FX_Idx == Sel_Track_FX_Count then
                                    r.TrackFX_Delete(LT_Track, FX_Idx)
                                else
                                    r.TrackFX_Delete(LT_Track, FX_Idx)
                                end
                                ProQ3.SpectrumDeleteWait = 0
                            end
                        else
                            if FX.InLyr[FXGUID[FX_Idx + 1]] then -- if in layering
                                SyncAnalyzerPinWithFX(FX_Idx, FX_Idx + 1, FX.Win_Name[math.max(FX_Idx - 1, 0)])
                                FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx + 1]]
                            else
                                FX.InLyr[FxGUID] = nil
                            end
                        end
                    elseif FX_Name:find('FXD Split to 4 channels') then
                        local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        --if FX below is not Pro-C 2
                        if FX_Name_After then
                            if string.find(FX_Name_After, 'Pro%-C 2') then
                                if FX.InLyr[FXGUID[FX_Idx + 1]] then -- if in layering
                                    SyncAnalyzerPinWithFX(FX_Idx, FX_Idx + 1, FX_Name)
                                end
                            end
                        end
                    elseif FX_Name:find('FXD Gain Reduction Scope') then
                        r.gmem_attach('CompReductionScope')
                        if FX[FXGUID[FX_Idx - 1]] then
                            r.gmem_write(FX[FXGUID[FX_Idx - 1]].ProC_ID or 0, FX_Idx - 1)
                        end
                        local _, FX_Name_Before = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)


                        --if FX above is not Pro-C 2
                        FX[FxGUID].ProC_Scope_Del_Wait = (FX[FxGUID].ProC_Scope_Del_Wait or 0) + 1

                        if FX[FxGUID].ProC_Scope_Del_Wait > FX_Add_Del_WaitTime + 10 then
                            if string.find(FX_Name_Before, 'Pro%-C 2') then
                                if FX.InLyr[FXGUID[FX_Idx - 1]] then -- if in layering
                                    SyncAnalyzerPinWithFX(FX_Idx, FX_Idx - 1, FX_Name)
                                end
                            end
                            FX[FxGUID].ProC_Scope_Del_Wait = 0
                        end

                        if FX.InLyr[FXGUID[FX_Idx - 1]] then
                            FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx - 1]]
                        else
                            FX.InLyr[FxGUID] = nil
                        end
                    elseif string.find(FX_Name, 'FXD Split to 32 Channels') ~= nil then
                        r.TrackFX_Show(LT_Track, FX_Idx, 2)
                        AddSpaceBtwnFXs(FX_Idx, true)
                        Spltr[FxGUID] = Spltr[FxGUID] or {}
                        Lyr[Lyr.SplitrAttachTo[FxGUID]] = Lyr[Lyr.SplitrAttachTo[FxGUID]] or {}
                        if Lyr[Lyr.SplitrAttachTo[FxGUID]].HowManyFX == 0 then
                            if FXGUID[FX_Idx + 1] ~= Lyr.SplitrAttachTo[FxGUID] then
                                for i = 0, Sel_Track_FX_Count - 1, 1 do
                                    if FXGUID[i] == Lyr.SplitrAttachTo[FxGUID] then
                                        r.TrackFX_CopyToTrack(LT_Track, FX_Idx, LT_Track, i - 1, true)
                                    end
                                end
                            end
                        end

                        if Spltr[FxGUID].New == true then
                            for i = 0, 16, 2 do
                                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 1, 0)
                            end

                            for i = 1, 16, 2 do
                                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 2, 0)
                            end

                            local FxGUID_Rack = Lyr.SplitrAttachTo[FxGUID]
                            for i = 1, 8, 1 do
                                local P_Num = 1 + (5 * (i - 1))
                                local Fx_P = i * 2 - 1
                                local P_Name = 'Chan ' .. i .. ' Vol'
                                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState', Fx_P,
                                    FX_Idx) -- Vol
                                local P_Num = 1 + (5 * (i - 1) + 1)
                                local Fx_P_Pan = i * 2
                                local P_Name = 'Chan ' .. i .. ' Pan'
                                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState',
                                    Fx_P_Pan, FX_Idx) -- Pan
                            end
                            Spltr[FxGUID].New = false
                        end

                        if FX.InLyr[FXGUID[FX_Idx + 1] or ''] then
                            FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx + 1]]
                        else
                            FX.InLyr[FxGUID] = nil
                        end

                        pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)
                    elseif FX_Name:find('FXD Saike BandSplitter') then
                        local Width, BtnWidth = 65, 25
                        local WinL, WinT, H, WinR
                        local WDL = WDL or r.ImGui_GetWindowDrawList(ctx)

                        if BandSplitID and not FX[FxGUID].BandSplitID then
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: BandSplitterID' .. FxGUID, BandSplitID,
                                true)
                            FX[FxGUID].BandSplitID = BandSplitID
                            BandSplitID = nil
                        end
                        FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
                        local JoinerID
                        for i, v in ipairs(FXGUID) do
                            if FX[FxGUID].AttachToJoiner == v then JoinerID = i end
                        end
                        local BsID = FX[FxGUID].BandSplitID
                        if FX[FxGUID].Collapse then Width = 35 end


                        if r.ImGui_BeginChild(ctx, 'FXD Saike BandSplitter' .. FxGUID, Width, 220) then
                            local SpcW = AddSpaceBtwnFXs(FX_Idx, 'SpaceBeforeBS', nil, nil, 1, FxGUID)
                            SL(nil, 0)

                            local btnTitle = string.gsub('Band Split', "(.)", "%1\n")
                            local btn = r.ImGui_Button(ctx, btnTitle .. '##Vertical', BtnWidth, 220) -- create window name button   Band Split button


                            if btn and Mods == 0 then
                                openFXwindow(LT_Track, FX_Idx)
                            elseif btn and Mods == Shift then
                                ToggleBypassFX(LT_Track, FX_Idx)
                            elseif btn and Mods == Alt then
                                FX[FxGUID].DeleteBandSplitter = true
                            elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                                FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
                            elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then -- check if all are collapsed
                                local All_Collapsed
                                for i = 0, Sel_Track_FX_Count - 1, 1 do
                                    if not FX[FXGUID[i]].Collapse then All_Collapsed = false end
                                end
                                if All_Collapsed == false then
                                    for i = 0, Sel_Track_FX_Count - 1, 1 do
                                        FX[FXGUID[i]].Collapse = true
                                    end
                                else -- if all is collapsed
                                    for i = 0, Sel_Track_FX_Count - 1, 1 do
                                        FX[FXGUID[i]].Collapse = false
                                        FX.WidthCollapse[FXGUID[i]] = nil
                                    end
                                    BlinkFX = FX_Idx
                                end
                            elseif r.ImGui_IsItemActive(ctx) then
                                DraggingFX_L_Pos = r.ImGui_GetCursorScreenPos(ctx) + 10
                                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                                    --DragFX_ID = FX_Idx
                                    r.ImGui_SetDragDropPayload(ctx, 'BS_Drag', FX_Idx)
                                    r.ImGui_EndDragDropSource(ctx)

                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end

                                --HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect',WDL )
                            end
                            SL(nil, 0)
                            r.gmem_attach('FXD_BandSplit')




                            --r.gmem_write(1,0) --[[1 is MouseR Click Position]]
                            --r.gmem_write(2,0)--[[tells if user R-Click BETWEEN a band]]
                            --r.gmem_write(3,0)--[[tells if user R-Click ON a band]]


                            local function f_trafo(freq)
                                return math.exp((1 - freq) * math.log(20 / 22050))
                            end
                            FX[FxGUID].Cross = FX[FxGUID].Cross or {}
                            local Cuts = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 0)
                            FX[FxGUID].Cross.Cuts = Cuts
                            WinL, WinT = r.ImGui_GetCursorScreenPos(ctx)
                            H, WinR = 220, WinL + Width - BtnWidth - SpcW


                            if FX[FxGUID].Collapse then
                                local L, T = WinL - BtnWidth, WinT
                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                                r.ImGui_DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)
                            else
                                for i = 1, Cuts * 4, 1 do ----------[Repeat for Bands]----------
                                    local TxtClr = getClr(r.ImGui_Col_Text())
                                    FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {}
                                    local X = FX[FxGUID].Cross[i]
                                    -- r.gmem_attach('FXD_BandSplit')
                                    local WDL = r.ImGui_GetWindowDrawList(ctx)
                                    local BsID = BsID or 0

                                    X.Val = r.gmem_read(BsID + i)
                                    X.NxtVal = r.gmem_read(BsID + i + 1)
                                    X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)


                                    --FX[FxGUID].Cross[i].Val = r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)

                                    local Cross_Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                                    local NxtCrossPos = SetMinMax(WinT + H - H * X.NxtVal, WinT, WinT + H)


                                    if --[[Hovering over a band]] r.ImGui_IsMouseHoveringRect(ctx, WinL, Cross_Pos - 3, WinR, Cross_Pos + 3) then
                                        FX[FxGUID].Cross.HoveringBand = i
                                        FX[FxGUID].Cross.HoveringBandPos = Cross_Pos

                                        if IsLBtnClicked then
                                            table.insert(Sel_Cross, i)
                                            Sel_Cross.FxID = FxGUID
                                        elseif IsRBtnClicked then
                                            --[[ if Cuts * 4 == i then  -- if deleting the top band
                                                r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, 0, math.max(Cuts-0.25,0)) --simply delete top band only, leave others untouched.
                                            else ]]
                                            --delete band
                                            local Rpt = Cuts * 4 - i
                                            local Bd = i + 1
                                            if FX[FxGUID].Sel_Band == i then FX[FxGUID].Sel_Band = nil end

                                            local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Bd)
                                            local _, Name = r.TrackFX_GetParamName(LT_Track, FX_Idx, Bd)
                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0,
                                                math.max(Cuts - 0.25, 0)) -- Delete Band
                                            for T = 1, Rpt, 1 do
                                                local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                    i + T)

                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i - 1 + T, NxtBd_V) --adjust band Freq
                                            end
                                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                                if FX[v].InWhichBand >= i then
                                                    FX[v].InWhichBand = FX[v].InWhichBand - 1

                                                    local Fx = tablefind(FXGUID, v)
                                                    --sets input channel
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 1), 0)
                                                    --sets Output +1
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 1), 0)
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which Band' .. v, FX[v].InWhichBand, true)
                                                end
                                            end
                                        end
                                        --[[ if not IsLBtnHeld then
                                            r.ImGui_SetNextWindowPos(ctx,WinR, FX[FxGUID].Cross[i].Pos -14)
                                            r.ImGui_BeginTooltip(ctx)
                                            r.ImGui_Text(ctx, roundUp(r.gmem_read(BsID+4+i),1)..' Hz')
                                            r.ImGui_EndTooltip(ctx)
                                        end  ]]
                                    end

                                    BD1 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                                    BD2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2)
                                    BD3 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3)
                                    BD4 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4)
                                    --ttp('BD1='..BD1..'\nBD2='..BD2..'\nBD3='..BD3..'\nBD4='..BD4)
                                    if --[[Mouse is between bands]] r.ImGui_IsMouseHoveringRect(ctx, WinL, X.Pos, WinR, NxtCrossPos) then
                                        if Payload_Type == 'FX_Drag' then

                                        end
                                    end



                                    if r.ImGui_IsMouseHoveringRect(ctx, WinL, WinT, WinR, WinT + H) and IsRBtnClicked then

                                    end

                                    if Sel_Cross[1] == i and Sel_Cross.FxID == FxGUID then
                                        if IsLBtnHeld then
                                            FX[FxGUID].Cross.DraggingBand = i
                                            local PrmV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                            DragDeltaX, DragDeltaY = r.ImGui_GetMouseDragDelta(ctx)
                                            if DragDeltaY > 0 or DragDeltaY < 0 then
                                                local B = Sel_Cross.TweakingBand
                                                if #Sel_Cross > 1 then
                                                    if DragDeltaY > 0 then -- if drag upward
                                                        B = math.min(Sel_Cross[1], Sel_Cross[2])
                                                        table.remove(Sel_Cross,
                                                            tablefind(Sel_Cross, math.max(Sel_Cross[1], Sel_Cross[2])))
                                                    else
                                                        B = math.max(Sel_Cross[1], Sel_Cross[2])
                                                        table.remove(Sel_Cross,
                                                            tablefind(Sel_Cross, math.min(Sel_Cross[1], Sel_Cross[2])))
                                                    end
                                                else
                                                    B = Sel_Cross[1]
                                                end
                                                local LowestV = 0.02
                                                --r.gmem_write(100, B)
                                                --r.gmem_write(101, -DragDeltaY*10)
                                                --if B==1 and B==i then  -- if B ==1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B,
                                                    PrmV - DragDeltaY / 250 --[[Val of moving Freq]])

                                                for i = 1, 4 - B, 1 do
                                                    if PrmV - DragDeltaY / 250 > r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, B + i) then
                                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B + i,
                                                            PrmV - DragDeltaY / 250 --[[Val of moving Freq]])
                                                    end
                                                end

                                                --local PrmV_New= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)
                                                --[[ local NextF = r.gmem_read(111+B)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B+1, SetMinMax( (NextF - PrmV_New) /(1-PrmV_New) ,LowestV,1) ) ]]

                                                --elseif B <4 and B >1 and B==i then --if B == 2~4

                                                --end

                                                --[[ if B <4 and B >0 and B==i then
                                                    local PrmV_New= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)
                                                    --local PrmV_NextB= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i+1)
                                                    local ThisF = r.gmem_read(110+B)




                                                    local NextF = r.gmem_read(111+B)
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B+1, SetMinMax( (NextF - PrmV_New) /(1-PrmV_New) ,LowestV,1) )
                                                end ]]
                                                --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, MovingBand+2, r.gmem_read(112)--[[Val of moving Freq + 1]] )


                                                --r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, i, math.max(PrmV-DragDeltaY/250,0.02))
                                                r.ImGui_ResetMouseDragDelta(ctx)
                                                --r.gmem_write(101,0)
                                            end
                                            if Sel_Cross[1] == i then
                                                r.ImGui_SetNextWindowPos(ctx, WinR, FX[FxGUID].Cross[i].Pos - 14)
                                                r.ImGui_BeginTooltip(ctx)
                                                r.ImGui_Text(ctx, roundUp(r.gmem_read(BsID + 4 + i), 1) .. ' Hz')
                                                r.ImGui_EndTooltip(ctx)
                                                --r.ImGui_DrawList_AddText(Glob.FDL, WinL, Cross_Pos, getClr(r.ImGui_Col_Text()) , roundUp(r.gmem_read(10+i),1)..' Hz')
                                            end
                                        else
                                            Sel_Cross = {} --r.gmem_write(100, 0)
                                        end
                                    else
                                    end


                                    --[[ -- Draw Bands
                                    r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos , WinR, X.Pos, TxtClr )
                                    r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr , roundUp(r.gmem_read(BsID+4+i),1)) ]]
                                end


                                function DropFXintoBS(FxID, FxGUID_BS, Band, Pl, DropDest, DontMove) --Pl is payload    --!!!! Correct drop dest!!!!
                                    FX[FxID] = FX[FxID] or {}

                                    if FX.InLyr[FxID] then --- move fx out of Layer
                                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                                        r.SetProjExtState(0, 'FX Devices',
                                            'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer', '')
                                    end



                                    if FX[FxID].InWhichBand then
                                        table.remove(FX[FxGUID_BS].FXsInBS, tablefind(FX[FxGUID_BS].FXsInBS, FxID))
                                    end



                                    if TABinsertPos then
                                        table.insert(FX[FxGUID_BS].FXsInBS, TABinsertPos, FxID)
                                    else
                                        table.insert(FX[FxGUID_BS].FXsInBS, FxID)
                                    end

                                    FX[FxID].InWhichBand = Band

                                    if not DontMove then
                                        local DropDest = DropDest
                                        table.insert(MovFX.FromPos, Pl)
                                        if Pl > FX_Idx and not DropDest then DropDest = FX_Idx + 1 end


                                        if Pl < DropDest then
                                            DropDest = DropDest - 1
                                        end



                                        table.insert(MovFX.ToPos, DropDest or FX_Idx)

                                        table.insert(MovFX.Lbl, 'Move FX into Band ' .. Band)
                                    end



                                    local function Set_In_Out(FX, Band, ChanL, ChanR)
                                        r.TrackFX_SetPinMappings(LT_Track, FX, 0, ChanL or 0,
                                            2 ^ ((Band + 1) * 2 - 2), 0) -- inputs
                                        r.TrackFX_SetPinMappings(LT_Track, FX, 0, ChanR or 1,
                                            2 ^ ((Band + 1) * 2 - 1), 0)

                                        r.TrackFX_SetPinMappings(LT_Track, FX, 1, ChanL or 0,
                                            2 ^ ((Band + 1) * 2 - 2), 0) --outputs
                                        r.TrackFX_SetPinMappings(LT_Track, FX, 1, ChanR or 1,
                                            2 ^ ((Band + 1) * 2 - 1), 0)
                                    end

                                    Set_In_Out(Pl, Band)

                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FxID,
                                        FxGUID_BS,
                                        true)
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FxID,
                                        Band,
                                        true)



                                    --- account for fxs with analyzers
                                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, Pl)
                                    if FX_Name:find('Pro%-C 2') then
                                        --Set_In_Out(Pl+1, Band+1, 2,3)
                                        --r.TrackFX_SetPinMappings(LT_Track, Pl+1, 0, 2, 2^((Band+1)*2-2)*2, 0) -- inputs 3
                                        --[[ r.TrackFX_SetPinMappings(LT_Track, Pl+1, 0, 3, 2^((Band+1)*2-2)*2, 0) -- inputs 4 ]]
                                    end

                                    local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                                    if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                                    local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                                    if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                                end

                                -- Count numbeer of FXs in bands
                                local FXCountForBand = {}
                                FX[FxGUID].FXCheckWait = (FX[FxGUID].FXCheckWait or 0) + 1
                                if FX[FxGUID].FXCheckWait > 10 then
                                    for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                        if not tablefind(FXGUID, v) then
                                            table.remove(FX[FxGUID].FXsInBS, tablefind(FX[FxGUID].FXsInBS, v))
                                        end
                                    end
                                    FX[FxGUID].FXCheckWait = 0
                                end

                                for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                    if FX[v].InWhichBand == 0 then
                                        FXCountForBand[0] = (FXCountForBand[0] or 0) + 1
                                    elseif FX[v].InWhichBand == 1 then
                                        FXCountForBand[1] = (FXCountForBand[1] or 0) + 1
                                    elseif FX[v].InWhichBand == 2 then
                                        FXCountForBand[2] = (FXCountForBand[2] or 0) + 1
                                    elseif FX[v].InWhichBand == 3 then
                                        FXCountForBand[3] = (FXCountForBand[3] or 0) + 1
                                    elseif FX[v].InWhichBand == 4 then
                                        FXCountForBand[4] = (FXCountForBand[4] or 0) + 1
                                    end
                                end

                                for i = 0, 5, 1 do FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {} end
                                for i = 0, Cuts * 4, 1 do ------- Rpt for Spaces between band splits
                                    local CrossPos, Nxt_CrossPos
                                    local Pl = tonumber(Payload)

                                    if i == 0 then
                                        CrossPos = WinT + H
                                    else
                                        CrossPos = FX[FxGUID].Cross[math.min(i, 4)]
                                            .Pos
                                    end
                                    if i == Cuts * 4 then
                                        Nxt_CrossPos = WinT
                                    else
                                        Nxt_CrossPos = FX[FxGUID].Cross[i + 1]
                                            .Pos
                                    end
                                    local HvrOnBand = r.ImGui_IsMouseHoveringRect(ctx, WinL, CrossPos - 3, WinR,
                                        CrossPos + 3)
                                    local HvrOnNxtBand = r.ImGui_IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos - 3, WinR,
                                        Nxt_CrossPos + 3)

                                    if --[[Hovering over a band]] r.ImGui_IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos, WinR, CrossPos) and not (HvrOnBand or HvrOnNxtBand) then
                                        local function Find_InsPos()
                                            local InsPos
                                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                                if FX[v].InWhichBand == i then InsPos = tablefind(FXGUID, v) end
                                            end
                                            Pl = Pl or InsPos
                                            if not InsPos then
                                                InsPos = FX_Idx
                                            elseif Pl > FX_Idx then
                                                InsPos = InsPos or (FX_Idx)
                                            elseif Pl < FX_Idx then
                                                InsPos = (InsPos or (FX_Idx - 1)) - 1
                                            end
                                            return InsPos
                                        end

                                        if Payload_Type == 'FX_Drag' then --Drop fx into a band
                                            if FX[FXGUID[Pl]].InWhichBand ~= i then
                                                r.ImGui_DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                                    0xffffff66)
                                                if r.ImGui_IsMouseReleased(ctx, 0) then
                                                    local DropDest = FX_Idx
                                                    local InsPos = Find_InsPos()
                                                    DropFXintoBS(FXGUID[Pl], FxGUID, i, Pl, InsPos + 1)
                                                end
                                            end
                                        elseif Payload_Type == 'AddFX_Sexan' then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                                0xffffff66)

                                            if r.ImGui_IsMouseReleased(ctx, 0) then
                                                local InsPos = Find_InsPos()
                                                local rv, type, payload, is_preview, is_delivery = r
                                                    .ImGui_GetDragDropPayload(ctx)
                                                r.TrackFX_AddByName(LT_Track, payload, false, -1000 - InsPos - 1)
                                                local FXid = r.TrackFX_GetFXGUID(LT_Track, InsPos + 1)
                                                DropFXintoBS(FXid, FxGUID, i, InsPos, FX_Idx, 'DontMove')
                                            end
                                        end
                                        AnySplitBandHvred = true
                                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}
                                        FX[FxGUID].PreviouslySolodBand = FX[FxGUID].PreviouslySolodBand or {}

                                        --Mute Band
                                        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_M()) and Mods == 0 then
                                            local Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                                4 + 5 * i)
                                            if Solo == 0 then
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                                    5 * i)
                                                local V
                                                if OnOff == 1 then V = 0 else V = 1 end
                                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, V)
                                                FX[FxGUID].PreviouslyMutedBand = {}
                                            end
                                            --Solo Band
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_S()) and Mods == 0 then
                                            local Mute = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)
                                            if Mute == 1 then
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                                    4 + 5 * i)
                                                local V
                                                if OnOff == 1 then V = 0 else V = 1 end
                                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, V)
                                                FX[FxGUID].PreviouslySolodBand = {}
                                            end
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_M()) and Mods == Shift then
                                            local AnyMutedBand

                                            for i = 0, Cuts * 4, 1 do
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                                    5 * i)

                                                if OnOff == 0 then AnyMutedBand = true end
                                                if OnOff == 0 then table.insert(FX[FxGUID].PreviouslyMutedBand, i) end
                                                if tablefind(FX[FxGUID].PreviouslyMutedBand, i) and OnOff == 1 then
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 0)
                                                else
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 1)
                                                end
                                            end

                                            if not AnyMutedBand then FX[FxGUID].PreviouslyMutedBand = {} end
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_S()) and Mods == Shift then
                                            local AnySolodBand

                                            for i = 0, Cuts * 4, 1 do
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                                    4 + 5 * i)

                                                if OnOff == 1 then AnySolodBand = true end
                                                if OnOff == 1 then table.insert(FX[FxGUID].PreviouslySolodBand, i) end
                                                if tablefind(FX[FxGUID].PreviouslySolodBand, i) and OnOff == 0 then
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 1)
                                                else
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 0)
                                                end
                                            end

                                            if not AnySolodBand then FX[FxGUID].PreviouslySolodBand = {} end
                                        end
                                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}



                                        if IsLBtnClicked and (Mods == 0 or Mods == Apl) then
                                            FX[FxGUID].Sel_Band = i
                                            FX[FxGUID].StartCount = true
                                        elseif IsRBtnClicked and Cuts ~= 1 then
                                            local _, ClickPos = r.ImGui_GetMousePos(ctx, 1)
                                            local H = 213
                                            local Norm_V = (WinT - ClickPos + 3) / H + 1


                                            local X = FX[FxGUID].Cross

                                            local Seg -- determine which band it's clicked

                                            X[1].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1);
                                            X[2].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2);
                                            X[3].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3);
                                            X[4].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4);

                                            if Norm_V < X[1].Val then
                                                Seg = 1
                                            elseif Norm_V > X[4].Val and Cuts == 0.75 then
                                                Seg = 5
                                            elseif Norm_V > X[1].Val and Norm_V < X[2].Val then
                                                Seg = 2
                                            elseif Norm_V > X[2].Val and Norm_V < X[3].Val then
                                                Seg = 3
                                            elseif Norm_V > X[3].Val and Norm_V < X[4].Val then
                                                Seg = 4
                                            end


                                            if Cuts == 0.75 then
                                                if Norm_V > X[3].Val then Seg = 5 end
                                            elseif Cuts == 0.5 then
                                                if Norm_V > X[2].Val then Seg = 5 end
                                            elseif Cuts == 0.25 then
                                                if Norm_V > X[1].Val then Seg = 5 end
                                            end





                                            if Seg == 5 then
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, Cuts + 0.25)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)
                                            elseif Seg < 5 then
                                                local BandFreq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                    i + 1)
                                                local BandFreq2
                                                if Seg == 1 then
                                                    BandFreq2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                        i + 2)
                                                end

                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, Cuts + 0.25)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)

                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 2, BandFreq)

                                                if Seg == 1 then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 3,
                                                        BandFreq2)
                                                end


                                                --[[ for T=1, Cuts*4-Seg+1, 1 do
                                                end ]]
                                            end
                                        elseif IsLBtnClicked and Mods == Alt then
                                            if FXCountForBand[i] or 0 > 0 then
                                                FX[FxGUID].PromptDeleteBand = i
                                                local Modalw, Modalh = 270, 55
                                                r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                                    VP.y + VP.h / 2 - Modalh / 2)
                                                r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                                r.ImGui_OpenPopup(ctx, 'Delete Band' .. i .. '? ##' .. FxGUID)
                                            end
                                        elseif LBtn_MousdDownDuration > 0.06 and (Mods == 0 or Mods == Apl) and not DraggingFXs.SrcBand and FX[FxGUID].StartCount then
                                            --Drag FXs to different bands
                                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                                if FX[v].InWhichBand == i then
                                                    table.insert(DraggingFXs, v)
                                                    table.insert(DraggingFXs_Idx, tablefind(FXGUID, v))
                                                end
                                            end
                                            DraggingFXs.SrcBand = i
                                            DraggingFXs.SrcFxID = FxGUID
                                        elseif DraggingFXs.SrcBand and DraggingFXs[1] and IsLBtnHeld or Payload_Type == 'FX_Drag' then
                                            FX[FxGUID].Sel_Band = i
                                        end



                                        if DraggingFXs[1] and DraggingFXs.SrcBand ~= i then
                                            HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                                                Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1,
                                                NoGetItemRect, NoForeground, NOrounding)
                                            if not IsLBtnHeld and Mods == 0 then -- if Dropped FXs
                                                for I, v in ipairs(DraggingFXs) do
                                                    FX[v].InWhichBand = i
                                                    local Fx = tablefind(FXGUID, v)
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which Band' .. v, i, true)
                                                    --sets input channel
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0,
                                                        2 ^ ((i + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1,
                                                        2 ^ ((i + 1) * 2 - 1), 0)
                                                    --sets Output +1
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0,
                                                        2 ^ ((i + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1,
                                                        2 ^ ((i + 1) * 2 - 1), 0)
                                                end
                                            elseif not IsLBtnHeld and Mods == Apl then
                                                local Ofs = 0
                                                for I, v in ipairs(DraggingFXs) do
                                                    local offset
                                                    local srcFX = DraggingFXs_Idx[I] + Ofs
                                                    local TrgFX = srcFX + #DraggingFXs
                                                    if not FXCountForBand[i] then -- if theres no fx in the band
                                                    elseif FXCountForBand[i] > 0 then
                                                        for FxInB, v in ipairs(FX[FxGUID].FXsInBS) do
                                                            if FX[v].InWhichBand == i and tablefind(FXGUID, v) then
                                                                offset =
                                                                    tablefind(FXGUID, v)
                                                            end
                                                        end
                                                        TrgFX = offset + I
                                                    end


                                                    if srcFX >= TrgFX then Ofs = I end


                                                    r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, TrgFX,
                                                        false)
                                                    local ID = r.TrackFX_GetFXGUID(LT_Track, TrgFX)

                                                    if not tablefind(FX[FxGUID].FXsInBS, ID) then
                                                        table.insert(
                                                            FX[FxGUID].FXsInBS, ID)
                                                    end
                                                    FX[ID] = FX[ID] or {}
                                                    FX[ID].InWhichBand = i
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which Band' .. ID, i, true)
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which BS' .. ID, FxGUID, true)


                                                    --sets input channel
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 0, 0,
                                                        2 ^ ((i + 1) * 2 - 2),
                                                        0)
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 0, 1,
                                                        2 ^ ((i + 1) * 2 - 1),
                                                        0)
                                                    --sets Output +1
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 1, 0,
                                                        2 ^ ((i + 1) * 2 - 2),
                                                        0)
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 1, 1,
                                                        2 ^ ((i + 1) * 2 - 1),
                                                        0)
                                                end


                                                --[[ for I, v in ipairs(DraggingFXs) do
                                                    local srcFX = tablefind(FXGUID, v)
                                                    r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, )
                                                end  ]]
                                            end
                                        end



                                        WDL = WDL or r.ImGui_GetWindowDrawList(ctx)
                                        -- Highligh Hovered Band
                                        if not IsLBtnHeld then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR, CrossPos,
                                                0xffffff19)
                                        end
                                    end
                                    if FX[FxGUID].Sel_Band == i then
                                        HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                                            Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1, NoGetItemRect,
                                            NoForeground, NOrounding)
                                    end


                                    local Solo, Pwr
                                    if JoinerID then
                                        Pwr = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)

                                        local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                        if Pwr == 0 then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                                CrossPos, Clr)
                                        end

                                        Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)
                                        local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                        if Solo == 1 then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                                CrossPos, Clr)
                                        end
                                    end
                                end

                                if r.ImGui_BeginPopupModal(ctx, 'Delete Band' .. (FX[FxGUID].PromptDeleteBand or '') .. '? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                                    r.ImGui_Text(ctx, 'Delete the FXs in band ' .. FX[FxGUID].PromptDeleteBand .. '?')
                                    if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                        r.Undo_BeginBlock()
                                        for i = 0, Sel_Track_FX_Count, 1 do
                                            if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                                            end
                                        end
                                        local DelFX = {}
                                        for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                            if FX[v].InWhichBand == FX[FxGUID].PromptDeleteBand then
                                                table.insert(DelFX, v)
                                                --delete FXs
                                            end
                                        end
                                        for i, v in ipairs(DelFX) do
                                            r.TrackFX_Delete(LT_Track, tablefind(FXGUID, v) - i + 1)
                                        end


                                        r.Undo_EndBlock('Delete all FXs in Band ' .. FX[FxGUID].PromptDeleteBand, 0)
                                        FX[FxGUID].PromptDeleteBand = nil
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                    SL()
                                    if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                    r.ImGui_EndPopup(ctx)
                                end






                                -- draw bands

                                for i = 1, Cuts * 4, 1 do
                                    local X = FX[FxGUID].Cross[i]
                                    if IsRBtnHeld then
                                        X.Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i);

                                        X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                                    end
                                    local BsID = FX[FxGUID].BandSplitID
                                    local TxtClr = getClr(r.ImGui_Col_Text())

                                    r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos, WinR, X.Pos, TxtClr)
                                    if FX[FxGUID].Cross.DraggingBand ~= i then
                                        r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                            roundUp(r.gmem_read(BsID + 4 + i), 1))
                                    end
                                    if FX[FxGUID].Cross.HoveringBand == i or FX[FxGUID].Cross.DraggingBand == i then
                                        if not FX[FxGUID].Cross.DraggingBand == i then
                                            r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                                roundUp(r.gmem_read(BsID + 4 + i), 1))
                                        end
                                        r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos + 1, WinR, X.Pos, TxtClr)

                                        if not r.ImGui_IsMouseHoveringRect(ctx, WinL, FX[FxGUID].Cross.HoveringBandPos - 3, WinR, FX[FxGUID].Cross.HoveringBandPos + 3)
                                            or (FX[FxGUID].Cross.DraggingBand == i and not IsLBtnHeld) then
                                            FX[FxGUID].Cross.HoveringBandPos = 0
                                            FX[FxGUID].Cross.HoveringBand = nil
                                            FX[FxGUID].Cross.DraggingBand = nil
                                        end
                                    end
                                end

                                -- Display Number of FXs in Band
                                for i = 0, Cuts * 4, 1 do
                                    if FXCountForBand[i] or 0 > 0 then
                                        local This_B_Pos, nxt_X_Pos
                                        if i == 4 or (i == 3 and Cuts == 0.75) or (i == 2 and Cuts == 0.5) or (i == 1 and Cuts == 0.25) then
                                            nxt_X_Pos = WinT
                                            This_B_Pos = FX[FxGUID].Cross[i].Pos
                                        elseif i == 0 then
                                            This_B_Pos = WinT + H
                                            nxt_X_Pos = FX[FxGUID].Cross[1].Pos
                                        else
                                            nxt_X_Pos = FX[FxGUID].Cross[i + 1].Pos or 0
                                            This_B_Pos = FX[FxGUID].Cross[i].Pos
                                        end


                                        if This_B_Pos - nxt_X_Pos > 28 and not DraggingFXs[1] then
                                            r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                                nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                                FXCountForBand[i] or '')
                                        elseif DraggingFXs[1] then
                                            if DraggingFXs.SrcBand == i then
                                                MsX, MsY = r.ImGui_GetMousePos(ctx)
                                                r.ImGui_DrawList_AddLine(Glob.FDL, MsX, MsY, WinL + 15,
                                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff99)
                                            else
                                                r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                                    FXCountForBand[i] or '')
                                            end
                                        end
                                    end
                                end

                                -- Draw Background
                                r.ImGui_DrawList_AddRectFilled(WDL, WinL, Glob.WinT, WinR, Glob.WinB, 0xffffff33)

                                local Copy

                                if DraggingFXs[1] and FXCountForBand[DraggingFXs.SrcBand] then
                                    local MsX, MsY = r.ImGui_GetMousePos(ctx)
                                    if Mods == Apl then Copy = 'Copy' end
                                    r.ImGui_DrawList_AddTextEx(Glob.FDL, Font_Andale_Mono_20_B, 14, MsX + 20, MsY,
                                        0xffffffaa, (Copy or '') .. ' ' .. FXCountForBand[DraggingFXs.SrcBand] .. ' FXs')
                                end
                            end


                            if not IsLBtnHeld then FX[FxGUID].StartCount = nil end


                            r.ImGui_EndChild(ctx)
                        end

                        if not FX[FxGUID].Collapse then
                            local LastFX_XPos
                            local FrstFX
                            local ofs = 0



                            for FX_ID = 0, Sel_Track_FX_Count, 1 do
                                for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                    local _, FxName = r.TrackFX_GetFXName(LT_Track, FX_ID)

                                    if FXGUID[FX_ID] == v and FX[FxGUID].Sel_Band == FX[v].InWhichBand then
                                        if FxName:find('FXD ReSpectrum') then ofs = ofs + 1 end

                                        if not FrstFX then
                                            SL(nil, 0)
                                            AddSpaceBtwnFXs(FX_ID - 1, 'SpcInBS', nil, nil, nil, FxGUID)
                                            FrstFX = true
                                        end
                                        --if i == 1 then  SL(nil,0)  AddSpaceBtwnFXs(FX_Idx,'SpcInBS',nil,nil,1, FxGUID) end
                                        SL(nil, 0)

                                        I = tablefind(FXGUID, v)
                                        if I then
                                            createFXWindow(I)
                                            SL(nil, 0)
                                            AddSpaceBtwnFXs(I - ofs, 'SpcInBS', nil, nil, nil, FxGUID)
                                            SL(nil, 0)
                                            --[[ if i == #FX[FxGUID].FXsInBS then  ]]
                                            LastFX_XPos = r.ImGui_GetCursorScreenPos(ctx)
                                        end
                                    end
                                end
                            end


                            if LastFX_XPos then
                                local Sel_B_Pos, NxtB_Pos, AddTopLine
                                local Cuts = FX[FxGUID].Cross.Cuts
                                FX[FxGUID].Sel_Band = FX[FxGUID].Sel_Band or 0
                                if FX[FxGUID].Sel_Band == 0 then
                                    Sel_B_Pos = WinT + H
                                else
                                    Sel_B_Pos = FX[FxGUID].Cross[FX[FxGUID].Sel_Band].Pos
                                end


                                if FX[FxGUID].Sel_Band == 4
                                    or (FX[FxGUID].Sel_Band == 3 and Cuts == 0.75)
                                    or (FX[FxGUID].Sel_Band == 2 and Cuts == 0.5)
                                    or (FX[FxGUID].Sel_Band == 1 and Cuts == 0.25)
                                then
                                    NxtB_Pos = WinT
                                    AddTopLine = true
                                else
                                    NxtB_Pos = FX[FxGUID].Cross[FX[FxGUID].Sel_Band + 1].Pos or 0
                                end

                                local Clr = getClr(r.ImGui_Col_Text())
                                WinT = Glob.WinT
                                H = Glob.Height or 0
                                WinR = WinR or 0
                                NxtB_Pos = NxtB_Pos or 0
                                WinL = WinL or 0
                                r.ImGui_DrawList_AddLine(WDL, WinR, WinT + H, LastFX_XPos, WinT + H, Clr)
                                r.ImGui_DrawList_AddLine(WDL, WinR, Sel_B_Pos, WinR, WinT + H, Clr)

                                r.ImGui_DrawList_AddLine(WDL, WinR, NxtB_Pos, WinR, WinT, Clr)
                                r.ImGui_DrawList_AddLine(WDL, WinR, WinT, LastFX_XPos, WinT, Clr)
                                r.ImGui_DrawList_AddLine(WDL, LastFX_XPos - 1, WinT, LastFX_XPos - 1, WinT + H, Clr)
                                if AddTopLine then r.ImGui_DrawList_AddLine(WDL, WinL, WinT, WinR, WinT, Clr) end
                                if FX[FxGUID].Sel_Band == 0 then
                                    r.ImGui_DrawList_AddLine(WDL, WinL, WinT + H, WinR,
                                        WinT + H, Clr)
                                end

                                if DraggingFX_L_Pos then
                                    local W = LastFX_XPos - DraggingFX_L_Pos
                                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT, LastFX_XPos,
                                        WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect, WDL)
                                    if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                                end
                            else
                                if DraggingFX_L_Pos then
                                    local W = Width - 10
                                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT,
                                        DraggingFX_L_Pos + W, WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect,
                                        WDL)
                                    if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                                end
                            end
                        end
                        if FX[FxGUID].DeleteBandSplitter then
                            if #FX[FxGUID].FXsInBS == 0 then
                                r.TrackFX_Delete(LT_Track, FX_Idx + 1)
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                FX[FxGUID].DeleteBandSplitter = nil
                            else
                                local Modalw, Modalh = 320, 55
                                r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                    VP.y + VP.h / 2 - Modalh / 2)
                                r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                r.ImGui_OpenPopup(ctx, 'Delete Band Splitter? ##' .. FxGUID)
                            end
                        end

                        if r.ImGui_BeginPopupModal(ctx, 'Delete Band Splitter? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                            r.ImGui_Text(ctx, 'Delete the FXs in band splitter altogether?')
                            if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                r.Undo_BeginBlock()
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                r.TrackFX_Delete(LT_Track, FX_Idx + #FX[FxGUID].FXsInBS)
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                                        --sets input channel
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                                        --sets Output
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)

                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                            'P_EXT: FX is in which BS' .. FXGUID[i],
                                            '', true)
                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                            'P_EXT: FX is in which Band' .. FXGUID
                                            [i], '', true)
                                        FX[FXGUID[i]].InWhichBand = nil
                                    end
                                end
                                FX[FxGUID].FXsInBS = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                                FX[FxGUID].DeleteBandSplitter = nil
                                r.Undo_EndBlock('Delete Band Split and put enclosed FXs back into channel one', 0)
                            end
                            SL()

                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                r.Undo_BeginBlock()
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                r.TrackFX_Delete(LT_Track, FX_Idx + #FX[FxGUID].FXsInBS)
                                local DelFX = {}
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                                        table.insert(DelFX, FXGUID[i])
                                    end
                                end

                                for i, v in ipairs(DelFX) do
                                    FX[v].InWhichBand = nil
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. v, '',
                                        true)
                                    r.TrackFX_Delete(LT_Track, tablefind(FXGUID, v) - i)
                                end


                                r.Undo_EndBlock('Delete Band Split and all enclosed FXs', 0)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '(esc) Cancel') or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
                                FX[FxGUID].DeleteBandSplitter = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                            end
                            r.ImGui_EndPopup(ctx)
                        end
                    end --  for if FX_Name ~='JS: FXD (Mix)RackMixer'
                    r.ImGui_SameLine(ctx, nil, 0)






                    ------- Pre FX Chain --------------
                    local FXisInPreChain, offset = nil, 0
                    if MacroPos == 0 then offset = 1 end --else offset = 0
                    if Trk[TrkID].PreFX[1] then
                        if Trk[TrkID].PreFX[FX_Idx + 1 - offset] == FXGUID[FX_Idx] then
                            FXisInPreChain = true
                        end
                    end

                    if Trk[TrkID].PreFX[1] and not Trk[TrkID].PreFX_Hide and FX_Idx == #Trk[TrkID].PreFX - 1 + offset then
                        AddSpaceBtwnFXs(FX_Idx, 'End of PreFX', nil)
                    end

                    if FXisInPreChain then
                        if FX_Idx + 1 - offset == #Trk[TrkID].PreFX and not Trk[TrkID].PreFX_Hide then
                            local R, B = r.ImGui_GetItemRectMax(ctx)
                            r.ImGui_DrawList_AddRect(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B,
                                r.ImGui_GetColor(ctx, r.ImGui_Col_Button()))
                            r.ImGui_DrawList_AddRectFilled(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B, 0xcccccc10)
                        end
                    end
                    ------------------------------------------
                    if FX_Idx + 1 == RepeatTimeForWindows and not Trk[TrkID].PostFX[1] then -- add last space
                        AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc')
                    elseif FX_Idx + 1 == RepeatTimeForWindows and Trk[TrkID].PostFX[1] then
                        AddSpaceBtwnFXs(Sel_Track_FX_Count - #Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
                    end
                end --for repeat as many times as FX instances


                for i = 0, #FXGUID do
                    local FXid = r.TrackFX_GetFXGUID(LT_Track, i)

                    if FXid ~= FXGUID[i] then
                    end
                    --Detects if any FX is deleted
                    if FXid == nil then
                        --Deleted_FXGUID = FXGUID[i]

                        --DeleteAllParamOfFX(Deleted_FXGUID, TrkID)
                        FXGUID[i] = nil
                    else
                    end
                end

                if Sel_Track_FX_Count == 0 and DeletePrms == nil then --if it's the only fx
                    DeleteAllParamOfFX(FXGUID[0], TrkID, 0)
                    FXGUID[0] = nil
                    DeletePrms = true
                elseif Sel_Track_FX_Count ~= 0 then
                    DeletePrms = nil
                end


                if Sel_Track_FX_Count == 0 then AddSpaceBtwnFXs(0, false, true) end



                --when user switch selected track...
                if TrkID ~= TrkID_End and TrkID_End ~= nil and Sel_Track_FX_Count > 0 then
                    Sendgmems = nil
                    waitForGmem = 0

                    if Sendgmems == nil then
                        r.gmem_attach('ParamValues')
                        for P = 1, 100, 1 do
                            r.gmem_write(1000 + P, 0)
                        end
                        --[[ if Trk[TrkID].ModPrmInst then
                            for P=1, Trk[TrkID].ModPrmInst , 1 do
                                for m =1 , 8, 1 do

                                    local ParamMacroMod_Label= 'Param:'..P..'Macro:'..m


                                    if Prm.McroModAmt[ParamMacroMod_Label] ~= nil then
                                        r.gmem_write( 1000*m+P  ,Prm.McroModAmt[ParamMacroMod_Label])
                                    end

                                end
                            end
                        end ]]

                        for FX_Idx = 0, Sel_Track_FX_Count, 1 do
                            local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                            if FxGUID then
                                for P, v in ipairs(FX[FxGUID]) do
                                    local FP = FX[FxGUID][P]
                                    FP.ModAMT = FP.ModAMT or {}
                                    if FP.WhichCC then
                                        for m = 1, 8, 1 do
                                            if FP.ModAMT[m] then r.gmem_write(1000 * m + P, FP.ModAMT[m]) end
                                        end
                                    end
                                end
                            end
                        end




                        r.gmem_write(2, PM.DIY_TrkID[TrkID] or 0)

                        Sendgmems = true
                    end
                end



                r.ImGui_EndChild(ctx)
                if HoverOnScrollItem then DisableScroll = true end

                if AnySplitBandHvred then
                    HintMessage =
                    'Mouse: Alt=Delete All FXs in Layer | Shift=Bypass FXs    Keys: M=mute band   Shift+M=Toggle all muted band | S=solo band  Shift+S=Toggle all solo\'d band'
                end
            end
            Pos_Devices_R, Pos_Devices_B = r.ImGui_GetItemRectMax(ctx)

            function MoveFX_Out_Of_Post(IDinPost)
                table.remove(Trk[TrkID].PostFX, IDinPost or tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                        true)
                end
            end

            function MoveFX_Out_Of_Pre(IDinPre)
                table.remove(Trk[TrkID].PreFX, IDinPre or tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                for i = 1, #Trk[TrkID].PreFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '', true)
                end
            end

            function RemoveFXfromBS()
                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do -- check all fxs and see if it's a band splitter
                    if FX[FXGUID[FX_Idx]].FXsInBS then
                        local FxID = tablefind(FX[FXGUID[FX_Idx]].FXsInBS, FXGUID[DragFX_ID])
                        if FxID then
                            table.remove(FX[FXGUID[FX_Idx]].FXsInBS, FxID)
                            FX[FXGUID[DragFX_ID]].InWhichBand = nil
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID], '',
                                true)
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: FX is in which Band' .. FXGUID[DragFX_ID], '',
                                true)
                        end
                    end
                end
            end

            _, Payload_Type, Payload, is_preview, is_delivery = r.ImGui_GetDragDropPayload(ctx)
            Payload = tonumber(Payload)
            MouseAtRightEdge = r.ImGui_IsMouseHoveringRect(ctx, VP.X + VP.w - 25, VP.y,
                VP.X + VP.w, VP.y + VP.h)

            if (Payload_Type == 'FX_Drag' or Payload_Type == 'AddFX_Sexan' and MouseAtRightEdge) and not Trk[TrkID].PostFX[1] then
                r.ImGui_SameLine(ctx, nil, -5)
                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                rv               = r.ImGui_Button(ctx, 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)
                if r.ImGui_BeginDragDropTarget(ctx) then -- if drop to post fx chain
                    Drop, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                        'GetItemRect', WDL)

                    if Drop and not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                        table.insert(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX, FXGUID
                            [DragFX_ID], true)
                        r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)

                        local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                        if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                    end

                    if --[[Move FX out of layer]] Drop and FX.InLyr[FXGUID[DragFX_ID]] then
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                        r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer', '')
                    end

                    if Drop then
                        RemoveFXfromBS()
                        --Remove FX from BS if it's in BS
                    end



                    r.ImGui_EndDragDropTarget(ctx)
                else
                    begindrop = false
                end
            end

            if Payload_Type == 'AddFX_Sexan' then
                local SpcIDinPost
                if SpcInPost then SpcIDinPost = math.max(#Trk[TrkID].PostFX, 1) end
                AddFX_Sexan(Sel_Track_FX_Count, ClrLbl, SpaceIsBeforeRackMixer, SpcIDinPost)
            end

            PostFX_Width = math.min(
                (MakeSpaceForPostFX or 0) + ((Trk[TrkID].MakeSpcForPostFXchain or 0) + (PostFX_LastSpc or 0)) + 30,
                VP.w / 2)

            --ttp('PostFX_Width = '..PostFX_Width..'\n MakeSpaceForPostFX = '.. (MakeSpaceForPostFX or 0 )..'\n   MakeSpcForPostFXchain = '.. (Trk[TrkID].MakeSpcForPostFXchain or  0 ).. '\n  PostFX_LastSpc = '.. (PostFX_LastSpc or 0))


            if not Trk[TrkID].PostFX[1] then
                Trk[TrkID].MakeSpcForPostFXchain = 0
            end

            if Trk[TrkID].PostFX[1] then
                r.ImGui_SameLine(ctx, nil, 0)
                Line_L, Line_T = r.ImGui_GetCursorScreenPos(ctx)
                rv             = r.ImGui_Button(ctx,
                    (#Trk[TrkID].PostFX or '') .. '\n\n' .. 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                if r.ImGui_IsItemClicked(ctx, 1) then
                    if Trk[TrkID].PostFX_Hide then Trk[TrkID].PostFX_Hide = false else Trk[TrkID].PostFX_Hide = true end
                end
                if r.ImGui_BeginDragDropTarget(ctx) then -- if drop to post fx chain Btn
                    if Payload_Type == 'FX_Drag' then
                        Drop, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                            'GetItemRect', WDL)

                        if Drop and not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                            --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)
                            table.insert(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX,
                                FXGUID[DragFX_ID], true)


                            local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                            if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                        end
                    elseif Payload_Type == 'AddFX_Sexan' then
                        dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan')
                        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                            'GetItemRect', WDL)
                        if dropped then
                            r.TrackFX_AddByName(LT_Track, payload, false, -1000 - Sel_Track_FX_Count)
                            local FXid = r.TrackFX_GetFXGUID(LT_Track, Sel_Track_FX_Count)
                            local _, Name = r.TrackFX_GetFXName(LT_Track, Sel_Track_FX_Count)
                            table.insert(Trk[TrkID].PostFX, FXid)
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX, FXid,
                                true)
                        end
                    end

                    r.ImGui_EndDragDropTarget(ctx)
                end

                r.ImGui_SameLine(ctx, nil, 0)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), 0xffffff11)
                local PostFX_Extend_W = 0
                if PostFX_Width == VP.w / 2 then PostFX_Extend_W = 20 end
                if not Trk[TrkID].PostFX_Hide then
                    if r.ImGui_BeginChild(ctx, 'Post FX chain', PostFX_Width - PostFX_Extend_W, 220) then
                        local clr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                        r.ImGui_DrawList_AddLine(Glob.FDL, Line_L, Line_T - 1, Line_L + VP.w, Line_T - 1, clr)
                        r.ImGui_DrawList_AddLine(Glob.FDL, Line_L, Line_T + 220, Line_L + VP.w, Line_T + 220, clr)



                        Trk[TrkID].MakeSpcForPostFXchain = 0

                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = 0 else offset = 1 end

                        for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
                            local I = --[[ tablefind(FXGUID, Trk[TrkID].PostFX[#Trk[TrkID].PostFX+1-FX_Idx])  ]]
                                tablefind(FXGUID, V)

                            local Spc
                            if FX_Idx == 1 and I then AddSpaceBtwnFXs(I - 1, 'SpcInPost', nil, nil, 1) end
                            if I then
                                createFXWindow(I)
                                r.ImGui_SameLine(ctx, nil, 0)

                                FX[FXGUID[I]].PostWin_SzX, _ = r.ImGui_GetItemRectSize(ctx)
                                Trk[TrkID].MakeSpcForPostFXchain = (Trk[TrkID].MakeSpcForPostFXchain or 0) +
                                    (FX.WidthCollapse[FXGUID[I]] or FX.Width[FXGUID[I]] or (DefaultWidth)) +
                                    10 -- 10 is space btwn fxs

                                if FX_Idx == #Trk[TrkID].PostFX then
                                    AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, #Trk[TrkID].PostFX + 1)
                                else
                                    AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, FX_Idx + 1)
                                end
                                if FX_Idx == #Trk[TrkID].PostFX and r.ImGui_IsItemHovered(ctx, r.ImGui_HoveredFlags_RectOnly()) then
                                    MouseAtRightEdge = true --[[ else MouseAtRightEdge = nil ]]
                                end
                            end
                        end




                        offset = nil


                        if InsertToPost_Src then
                            table.insert(Trk[TrkID].PostFX, InsertToPost_Dest, FXGUID[InsertToPost_Src])
                            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i,
                                    Trk[TrkID].PostFX[i] or '',
                                    true)
                            end
                            InsertToPost_Src = nil
                            InsertToPost_Dest = nil
                        end
                        r.ImGui_EndChild(ctx)
                    end
                else
                    Trk[TrkID].MakeSpcForPostFXchain = 0
                end


                for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
                    local I = tablefind(FXGUID, V)
                    local P = Sel_Track_FX_Count - #Trk[TrkID].PostFX + (FX_Idx - 1)


                    if I ~= P then
                        r.Undo_BeginBlock()
                        if not MovFX.FromPos[1] then
                            table.insert(MovFX.FromPos, I)
                            table.insert(MovFX.ToPos, P)
                            table.insert(MovFX.Lbl, 'Move FX into Post-FX Chain')
                        end
                        --r.TrackFX_CopyToTrack(LT_Track, I, LT_Track, P, true)
                        r.Undo_EndBlock('Move FX out of Post-FX Chain', 0)
                    end
                end
                r.ImGui_PopStyleColor(ctx)
            end


            -- When Add or Delete Fx.....if  add fx or delete fx
            if Sel_Track_FX_Count ~= CompareFXCount then
                for i in ipairs(FX.Win_Name) do

                end
                if FX.Win_Name then
                    local rv, tab = FindStringInTable(FX.Win_Name, 'FX Devices Gain Reduction')
                    if tab then
                        for i, v in ipairs(tab) do
                            r.gmem_attach('CompReductionScope')
                            r.gmem_write(2001, v - 1)
                        end
                    end
                end

                CompareFXCount = Sel_Track_FX_Count
            end


            r.ImGui_PopStyleColor(ctx)
            --[[  r.ImGui_PopStyleColor(ctx)  --  For Menu Bar Color
                r.ImGui_PopStyleColor(ctx)  --  For WindowBg ]]

            r.ImGui_PopStyleVar(ctx) --(Border Size for all fx devices)
            r.ImGui_PopStyleVar(ctx) --StyleVar#1 (Child Frame for all FX Devices)

            r.ImGui_PopFont(ctx)
            --r.ImGui_PopStyleColor(ctx,Clr.poptimes)
            Track_Fetch_At_End = r.GetLastTouchedTrack()
            TrkID_End = r.GetTrackGUID(Track_Fetch_At_End)

            FirstLoop = false
            ProQ3.SpecWait = ProQ3.SpecWait + 1


            demo.PopStyle()

            --[[ HintPos = HintPost or r.ImGui_GetCursorPosY(ctx)
            r.ImGui_SetCursorPosY(ctx, HintPos) ]]
            if HintMessage then
                r.ImGui_Text(ctx, ' !')
                SL()
                MyText(HintMessage, Font_Andale_Mono_13, 0xffffff88)
            end
            if not IsLBtnHeld then
                DraggingFXs = {}
                DraggingFXs_Idx = {}
            end
        end -- end for if LT_Track ~= nil





        r.ImGui_SetNextWindowSize(ctx, 500, 440, r.ImGui_Cond_FirstUseEver())
        if LT_Track then FXCountEndLoop = r.TrackFX_GetCount(LT_Track) end
        r.ImGui_End(ctx)
    end --end for Visible


    if open then
        r.defer(loop)
    else --on script close
        NumOfTotalTracks = r.GetNumTracks()
        for T = 0, NumOfTotalTracks - 1, 1 do
            local track = r.GetTrack(0, T)
            local TrkID = r.GetTrackGUID(track)
            for i, v in ipairs(MacroNums) do
                if Trk[TrkID].Mod[i].Val ~= nil then
                    r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID, Trk[TrkID].Mod[i].Val)
                end
            end
        end
    end
    Track_Fetch_At_End = r.GetLastTouchedTrack()
    waitForGmem = waitForGmem + 1
end --end for loop

r.defer(loop)
