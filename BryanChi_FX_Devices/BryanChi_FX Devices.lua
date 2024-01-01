-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta11.1
-- @changelog
--  - +Added custom color tweak for RDM by user's request
--  - Fixed opening Pad when Ctrl+right clicking pad (opening menu)
--  - Fixed PLink bug when RDM is inserted
--  - Made the vertical tab scrollable by left dragging it
-- @provides
--   [effect] FXD JSFXs/*.jsfx
--   [effect] FXD JSFXs/*.jsfx-inc
--   src/FX Layouts/ValhallaDelay (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaFreqEcho (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaShimmer (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaSpaceModulator (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaSupermassive (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaVintageVerb (Valhalla DSP, LLC).ini
--   src/FX Layouts/ReaComp (Cockos).ini
--   src/Images/Attached Drawings/LED light.png
--   src/Images/Knobs/Bitwig.png
--   src/Images/Knobs/FancyRedKnob.png
--   src/Images/Analog Knob 1.png
--   src/Images/trash.png
--   src/Images/sinewave.png
--   src/Images/save.png
--   src/Images/pinned.png
--   src/Images/pin.png
--   src/Images/paste.png
--   src/Images/copy.png
--   src/Images/Knobs/FancyGreenKnob.png
--   src/Images/Knobs/FancyBlueKnob_Inverted.png
--   src/Images/Knobs/FancyBlueKnob.png
--   src/Images/Knobs/FancyLightGreenKnob.png
--   src/Images/Switches/FancyGreenCheck_2.png
--   src/LFO Shapes/*.ini
--   src/FX Layout Plugin Scripts/*.lua
--   src/IconFont1.ttf
--   [main] src/FXD - Record Last Touch.lua
--   src/Functions/*.lua
--   src/Constants.lua
--   src/FXChains/ReaDrum Machine.RfxChain
-- @about
--   Please check the forum post for info:
--   https://forum.cockos.com/showthread.php?t=263622
-- dofile("/home/antoine/Documents/Experiments/lua/debug_connect.lua")


---@type string
CurrentDirectory = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] -- GET DIRECTORY FOR REQUIRE
package.path = CurrentDirectory .. "?.lua;"

FxdCtx = require("src.state.FxdCtx")
local ThirdPartyDeps = require("src.helpers.thirdPartyDeps")
local fs_utils = require("src.Functions.Filesystem_utils")
local table_helpers = require("src.helpers.table_helpers")
if ThirdPartyDeps() then return end

function Msg(...)
    for _, v in ipairs({ ... }) do
        r.ShowConsoleMsg(tostring(v) .. "\n")
    end
end

r = reaper
require("src.Components.FilterBox")
local MenuBar = require("src.Components.MenuBar")
local state_helpers = require("src.helpers.state_helpers")
local math_helpers = require("src.helpers.math_helpers")
local fxDisplay = require("src.Components.FxDisplay")
local gui_helpers = require("src.Components.Gui_Helpers")
require("src.Functions.General Functions")

require("src.Functions.EQ functions")
require("src.Functions.Layout Editor functions")
require("src.Functions.FX Layering")
require("src.Functions.Modulation")
require("src.Functions.Theme Editor Functions")
require("src.Functions.Filesystem_utils")
require("src.Constants")


PluginScript = {} ---@class PluginScript

Os_separator = package.config:sub(1, 1)

--------------------------==  declare Initial Variables & Functions  ------------------------
VersionNumber = '1.0beta10.12'

FxdCtx.FX_LIST, FxdCtx.CAT = ReadFXFile()
if not FxdCtx.FX_LIST or not FxdCtx.CAT then
    FxdCtx.FX_LIST, FxdCtx.CAT = MakeFXFiles()
end




----------- Custom Colors-------------------
local customcolors = require("src.helpers.custom_colors")
local CustomColorsDefault = customcolors.CustomColorsDefault




----------Parameters --------------------

-----------------------------------------
-----Param Modulations
-----------------------------------------
local WaitForGmem = 0


r.gmem_attach('gmemForSpectrum')





Sel_Track = r.GetSelectedTrack(0, 0)
if Sel_Track ~= nil then Sel_Track_FX_Count = r.TrackFX_GetCount(Sel_Track) end


FxdCtx.FX_DeviceWindow_NoScroll = 0
---list of GUIDs for Each track FX
---@type string[]
FxdCtx.FXGUID = {}
FxdCtx.FirstLoop = true


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

local HSV = customcolors.HSV

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

local MacrosTable = require("src.Components.MacrosTable")




-----end of colors--------



X = 0.5

Cont_Param_Add_Mode = false
OffsetForMultipleMOD = 2








-----------------Script Testing Area---------------------------




--------------------------------Layout Editor Functions -----------------------------













------------------------------------------------------------------------------------------------------------












----------------------------End declare Initial Variables   ------------------------

--------------------------==  Before GUI (No Loop) ----------------------------


GetLTParam()

ctx = r.ImGui_CreateContext('FX Device', r.ImGui_ConfigFlags_DockingEnable())


local images_fonts = require("src.helpers.images_fonts")

require("src.helpers.init_load_states")


images_fonts.attachImagesAndFonts()

---------------------------------------------------------------
-----------Retrieve Keyboard Shortcut Settings ----------------
---------------------------------------------------------------
if CallFile('r', 'Keyboard Shortcuts.ini') then
    local file, filepath = CallFile('r', 'Keyboard Shortcuts.ini')
    if not file then return end
    Content = file:read('*a')
    local L = get_lines(filepath)
    for i, v in ipairs(L) do
        FxdCtx.KB_Shortcut[i] = v:sub(0, v:find(' =') - 1)
        FxdCtx.Command_ID[i] = v:sub(v:find(' =') + 3, nil)
    end
end





---------------------------- End For Before GUI ----------------------------

function Loop()
    GetLT_FX_Num()
    GetLTParam()
    CheckDnDType() -- Defined in Layout Editor functions

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
    FxdCtx.ProC.ChanSplit = nil





    if LT_Track then TrkClr = r.ImGui_ColorConvertNative(r.GetTrackColor(LT_Track)) end
    TrkClr = ((TrkClr or 0) << 8) | 0x66 -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_MenuBarBg(), TrkClr or 0x00000000)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), Window_BG or CustomColorsDefault.Window_BG)
    --------------------------==  BEGIN GUI----------------------------------------------------------------------------
    local visible, open = r.ImGui_Begin(ctx, 'FX Device', true,
        r.ImGui_WindowFlags_NoScrollWithMouse() + r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_MenuBar() +
        r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoNav())
    r.ImGui_PopStyleColor(ctx, 2) -- for menu  bar and window BG


    local Viewport           = r.ImGui_GetWindowViewport(ctx)
    FxdCtx.VP.w, FxdCtx.VP.h = r.ImGui_Viewport_GetSize(Viewport)
    FxdCtx.VP.x, FxdCtx.VP.y = r.ImGui_GetCursorScreenPos(ctx) -- TODO should this be marked as VP.X instead of lowercase? Other instances of the var are uppercase


    ----------------------------------------------------------------------------
    -- ImGUI Variables-----------------------------------------------------------
    ----------------------------------------------------------------------------
    Mods  = r.ImGui_GetKeyMods(ctx)
    Alt   = r.ImGui_Mod_Alt()
    Ctrl  = r.ImGui_Mod_Ctrl()
    Shift = r.ImGui_Mod_Shift()
    Apl   = r.ImGui_Mod_Super()





    if visible then
        FxdCtx.VP.w, FxdCtx.VP.h = r.ImGui_Viewport_GetSize(Viewport)
        FxdCtx.VP.FDL = FxdCtx.VP.FDL or r.ImGui_GetForegroundDrawList(ctx)
        FxdCtx.VP.X, FxdCtx.VP.Y = r.ImGui_GetCursorScreenPos(ctx)

        ----------------- Keyboard Shortcuts ---------------
        if not r.ImGui_IsAnyItemActive(ctx) then
            for i, v in pairs(FxdCtx.KB_Shortcut) do
                if not v:find('+') then --if shortcut has no modifier
                    if r.ImGui_IsKeyPressed(ctx, AllAvailableKeys[v]) and Mods == 0 then
                        --[[ local commandID = r.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND')
                        local CommandTxt =  r.CF_GetCommandText(0, commandID) -- 0 prob means arrange window, it's the section drop down from action window's top right corner
                        r.Main_OnCommand(commandID, 0) ]]
                        if FxdCtx.Command_ID[i] then
                            local Cmd_Num = r.NamedCommandLookup(FxdCtx.Command_ID[i])
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
                    local Ltr = rev:sub(1, rev:find('+') - 2)
                    local AftrLastPlus = Ltr:reverse()


                    if Mods == Mod and r.ImGui_IsKeyPressed(ctx, AllAvailableKeys[AftrLastPlus]) then
                        if FxdCtx.Command_ID[i] then
                            local Cmd_Num = r.NamedCommandLookup(FxdCtx.Command_ID[i])
                            r.Main_OnCommand(Cmd_Num, 0)
                        end
                    end
                end
            end
        end



        if LT_Track == nil then
            r.ImGui_DrawList_AddTextEx(FxdCtx.VP.FDL, Font_Andale_Mono_20_B, 20, FxdCtx.VP.X,
                FxdCtx.VP.Y + FxdCtx.VP.h / 2, 0xffffffff,
                'Select a track to start')
        else                   -- of if LT_Track
            r.gmem_write(4, 0) -- set jsfx mode to none , telling it user is not making any changes, this prevents bipolar modulation from going back to unipolar by setting modamt from 100~101 back to 0~1


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
            for i, v in ipairs(FxdCtx.AddFX.Name) do
                if v:find('FXD Gain Reduction Scope') then
                    local FxGUID = FxdCtx.ProC.GainSc_FXGUID

                    FxdCtx.FX[FxGUID] = FxdCtx.FX[FxGUID] or {}
                    FxdCtx.FX[FxGUID].ProC_ID = math.random(1000000, 9999999)
                    r.gmem_attach('CompReductionScope')
                    r.gmem_write(2002, FxdCtx.FX[FxGUID].ProC_ID)
                    r.gmem_write(FxdCtx.FX[FxGUID].ProC_ID, FxdCtx.AddFX.Pos[i])
                    r.gmem_write(2000, FxdCtx.PM.DIY_TrkID[TrkID])
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID ' .. FxGUID, FxdCtx.FX[FxGUID].ProC_ID, true)
                elseif v:find('FXD Saike BandSplitter') then
                    r.gmem_attach('FXD_BandSplit')
                    BandSplitID = BandSplitID or math.random(1000000, 9999999)
                    r.gmem_write(0, BandSplitID)
                elseif v:find('FXD Band Joiner') then

                end



                AddFX_HideWindow(LT_Track, v, -1000 - FxdCtx.AddFX.Pos[i])
                if v:find('FXD Band Joiner') then
                    local SplittrID = r.TrackFX_GetFXGUID(LT_Track, FxdCtx.AddFX.Pos[i] - 1)
                    local JoinerID = r.TrackFX_GetFXGUID(LT_Track, FxdCtx.AddFX.Pos[i])
                    FxdCtx.FX[SplittrID] = FxdCtx.FX[SplittrID] or {}
                    FxdCtx.FX[SplittrID].AttachToJoiner = JoinerID
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Splitter\'s Joiner FxID ' .. SplittrID,
                        JoinerID, true)
                elseif v:find('FXD Gain Reduction Scope') then
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FxdCtx.AddFX.Pos[i])

                    SyncAnalyzerPinWithFX(FxdCtx.AddFX.Pos[i], FxdCtx.AddFX.Pos[i] - 1, FX_Name)
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
                        if string.find(FX_Name_After, 'Pro%-C 2') == nil and not FxdCtx.AddFX.Name[1] then
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
            if FxdCtx.MovFX.FromPos[1] then
                local UndoLbl
                r.Undo_BeginBlock()
                for i, v in ipairs(FxdCtx.MovFX.FromPos) do
                    if NeedCopyFX then
                        --if v >= DropPos then offset = 1 else offset = 0 end
                        FxdCtx.MovFX.ToPos[i] = math.max(FxdCtx.MovFX.ToPos[i] - (Offset or 0), 0)
                        r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, v, false)
                    end
                end

                for i, v in ipairs(FxdCtx.MovFX.FromPos) do -- move FX
                    r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, FxdCtx.MovFX.ToPos[i], true)
                end
                r.Undo_EndBlock(FxdCtx.MovFX.Lbl[i] or (UndoLbl or 'Move' .. 'FX'), 0)
                FxdCtx.MovFX = { FromPos = {}, ToPos = {}, Lbl = {}, Copy = {} }
                NeedCopyFX = nil
                DropPos = nil
            end



            --[[  if not init then
                r.TrackFX_CopyToTrack(LT_Track, 1, LT_Track, 33554439, true)
            end
            init = true
 ]]

            --------- Don't remove this ---------
            FxdCtx.AddFX.Name         = {}
            FxdCtx.AddFX.Pos          = {}
            FxdCtx.ProC.GainSc_FXGUID = nil
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



            if FxdCtx.PM.DIY_TrkID[TrkID] == nil then
                FxdCtx.PM.DIY_TrkID[TrkID] = math.random(100000000, 999999999)
                r.SetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID,
                    FxdCtx.PM.DIY_TrkID[TrkID])
            end

            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_D()) and Mods == Shift + Alt then
                DebugMode = true
            end



            -- if user switch selected track...
            local layoutRetrieved
            if TrkID ~= TrkID_End then
                if TrkID_End ~= nil and TrkID ~= nil then
                    NumOfTotalTracks = r.CountTracks(0)
                    --[[  r.gmem_attach('TrackNameForMacro')
                    reaper .gmem_write(0,NumOfTotalTracks )]]
                end
                for P = 0, FxdCtx.Trk.Prm.Inst[TrkID] or 0, 1 do
                    for m = 1, 8, 1 do
                        r.gmem_write(1000 * m + P, 0)
                    end
                end

                RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                TREE = BuildFXTree(LT_Track)

                layoutRetrieved = true
                SyncTrkPrmVtoActualValue()
                LT_TrackNum = math.floor(r.GetMediaTrackInfo_Value(LT_Track, 'IP_TRACKNUMBER'))
            end

            -- if new fx is added
            if RepeatTimeForWindows ~= r.TrackFX_GetCount(LT_Track) and not layoutRetrieved then
                RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                --TREE = BuildFXTree(tr)
            end

            TREE = BuildFXTree(tr)

            ----Functions & Variables -------------
            FxdCtx.Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)


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
                        gui_helpers.tooltip(tostring(keynum))
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






            MenuBar.DisplayMenuBar()




            if Cont_Param_Add_Mode == true then
                --TimeAfter_ContAdd= TimeAfter_ContAdd+1

                GetLT_FX_Num()
                GetLTParam()
                gui_helpers.tooltip('Continuously Adding Last Touched Parameters..')

                local F = FxdCtx.FX[LT_FXGUID] or {}; local RptPrmFound
                if LT_FXGUID and type(F) == 'table' then
                    for i, _ in ipairs(F) do
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

            FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()


            ------------------------------
            ------Layout Editing ---------
            ------------------------------


            ------------------Help Tips-------------------




            -----------==  Create Macros (Headers)-------------
            FxdCtx.MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
            MacrosTable.DisplayMacrosTable()
            ---------------End Of header-----------------------


            if ImGUI_Time > 3 then
                CompareFXCount = r.TrackFX_GetCount(LT_Track);
                ImGUI_Time = 0
            end

            if not r.ImGui_IsPopupOpen(ctx, '##', r.ImGui_PopupFlags_AnyPopup()) then
                FX_Idx_OpenedPopup = nil
            end





            RepeatTimeForWindows = Sel_Track_FX_Count

            MaxX, MaxY = r.ImGui_GetContentRegionMax(ctx)
            Framepadding = r.ImGui_StyleVar_FramePadding()
            BorderSize = r.ImGui_StyleVar_FrameBorderSize()
            FrameRounding = r.ImGui_StyleVar_FrameRounding()
            BtnTxtAlign = r.ImGui_StyleVar_ButtonTextAlign()

            r.ImGui_PushStyleVar(ctx, Framepadding, 0, 3) --StyleVar#1 (Child Frame for all FX Devices)
            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x121212ff)


            for FX_Idx = 0, RepeatTimeForWindows - 1, 1 do
                FxdCtx.FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)

                if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
                    FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                end
            end


            if FXGUID_RackMixer ~= nil then
                FxdCtx.Lyr.FX_Ins[FXGUID_RackMixer] = 0
                for FX_Idx = 0, RepeatTimeForWindows - 1, 1 do
                    if FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx]] == FXGUID_RackMixer then
                        FxdCtx.Lyr.FX_Ins[FXGUID_RackMixer] = FxdCtx.Lyr.FX_Ins[FXGUID_RackMixer] + 1
                    end
                end
            end


            FxdCtx.Glob.WDL = r.ImGui_GetWindowDrawList(ctx)
            FxdCtx.Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)
            if FxdCtx.Dvdr.JustDroppedFX then
                if not FxdCtx.Dvdr.JustDrop.X then
                    FxdCtx.Dvdr.JustDrop.X, FxdCtx.Dvdr.JustDrop.Y = r.ImGui_GetMousePos(ctx)
                end
                local X, _ = r.ImGui_GetMousePos(ctx)

                if X > FxdCtx.Dvdr.JustDrop.X + 15 or X < FxdCtx.Dvdr.JustDrop.X - 15 then
                    FxdCtx.Dvdr.JustDroppedFX = nil
                    FxdCtx.Dvdr.JustDrop.X = nil
                    FxdCtx.Dvdr.JustDrop.Y = nil
                end
            end


            FxdCtx.Trk[TrkID] = FxdCtx.Trk[TrkID] or {}
            FxdCtx.Trk[TrkID].PreFX = FxdCtx.Trk[TrkID].PreFX or {}


            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ChildBorderSize(), 0)
            Cx_LeftEdge, Cy_BeforeFXdevices = r.ImGui_GetCursorScreenPos(ctx)
            MouseAtLeftEdge = r.ImGui_IsMouseHoveringRect(ctx, Cx_LeftEdge - 50, Cy_BeforeFXdevices, Cx_LeftEdge + 5,
                Cy_BeforeFXdevices + 220)

            if MouseAtLeftEdge and not FxdCtx.Trk[TrkID].PreFX[1] and string.len(Payload_Type) > 1 then
                Rv = r.ImGui_Button(ctx, 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                SL(nil, 0)
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, W, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)

                if Payload_Type == 'FX_Drag' then
                    Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    r.ImGui_SameLine(ctx, nil, 0)
                elseif Payload_Type == 'DND ADD FX' then
                    Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX') --
                end
            end


            if FxdCtx.Trk[TrkID].PreFX[1] then
                Rv = r.ImGui_Button(ctx,
                    (#FxdCtx.Trk[TrkID].PreFX or '') .. '\n\n' .. 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20,
                    220)
                r.ImGui_SameLine(ctx, nil, 0)
                if r.ImGui_IsItemClicked(ctx, 1) then
                    if FxdCtx.Trk[TrkID].PreFX_Hide then FxdCtx.Trk[TrkID].PreFX_Hide = false else FxdCtx.Trk[TrkID].PreFX_Hide = true end
                end
            end

            if r.ImGui_BeginDragDropTarget(ctx) then
                if Payload_Type == 'FX_Drag' then
                    Rv, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, W, H_OutlineSc, V_OutlineSc,
                        'GetItemRect', WDL)

                    if Rv then
                        if not tablefind(FxdCtx.Trk[TrkID].PreFX, FxdCtx.FXGUID[DragFX_ID]) then
                            table.insert(FxdCtx.Trk[TrkID].PreFX, FxdCtx.FXGUID[DragFX_ID])
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #FxdCtx.Trk[TrkID].PreFX,
                                FxdCtx.FXGUID[DragFX_ID], true)
                        end

                        -- move fx out of post chain
                        local IDinPost = tablefind(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID])
                        if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                        --Move FX out of layer
                        if FxdCtx.FX.InLyr[FxdCtx.FXGUID[DragFX_ID]] then
                            FxdCtx.FX.InLyr[FxdCtx.FXGUID[DragFX_ID]] = nil
                            r.SetProjExtState(0, 'FX Devices',
                                'FXLayer - ' .. 'is FX' .. FxdCtx.FXGUID[DragFX_ID] .. 'in layer',
                                '')
                        end
                        RemoveFXfromBS()
                    end
                elseif Payload_Type == 'DND ADD FX' then
                    Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX') --
                    if Dropped then
                        r.TrackFX_AddByName(LT_Track, Payload, false, -1000)
                        local FxID = r.TrackFX_GetFXGUID(LT_Track, 0)
                        table.insert(FxdCtx.Trk[TrkID].PreFX, FxID)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #FxdCtx.Trk[TrkID].PreFX, FxID, true)

                        for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                            FxdCtx.FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                        end
                    end
                end



                r.ImGui_EndDragDropTarget(ctx)
            end



            FxdCtx.Trk[TrkID].PostFX = FxdCtx.Trk[TrkID].PostFX or {}
            if ((DragDroppingFX and MouseAtRightEdge) and not FxdCtx.Trk[TrkID].PostFX[1]) then
                if FxdCtx.Trk[TrkID].PreFX[1] then MakeSpaceForPostFX = 30 else MakeSpaceForPostFX = 0 end
            elseif FxdCtx.Trk[TrkID].PostFX_Hide and FxdCtx.Trk[TrkID].PreFX[1] then
                MakeSpaceForPostFX = 20
            else
                MakeSpaceForPostFX = 0
            end



            MacroPos = r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0)
            local ReSpectrumPos = r.TrackFX_AddByName(LT_Track, 'FXD ReSpectrum', 0, 0)
            if MacroPos ~= -1 and MacroPos ~= 0 then -- if macro exists on track, and Macro is not the 1st fx
                if FxdCtx.FX.Win_Name[0] ~= 'JS: FXD Macros' then
                    r.TrackFX_CopyToTrack(LT_Track, MacroPos,
                        LT_Track, 0, true)
                end -- move it to 1st slot
            end



            if MacroPos ~= -1 or ReSpectrumPos == 0 then Offset = 0 else Offset = 1 end -- if no Macros is found


            for i, v in pairs(FxdCtx.Trk[TrkID].PreFX or {}) do
                if FxdCtx.FXGUID[i - Offset] ~= v then
                    if not FxdCtx.AddFX.Name[1] then
                        table.insert(FxdCtx.MovFX.FromPos, tablefind(FxdCtx.FXGUID, v))
                        table.insert(FxdCtx.MovFX.ToPos, i - Offset)
                        table.insert(FxdCtx.MovFX.Lbl, 'Move FX into Pre-Chain')
                    end
                end
            end
            Offset = nil
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), Window_BG or CustomColorsDefault.Window_BG)

            local spaceIfPreFX = 0
            if FxdCtx.Trk[TrkID].PreFX[1] and FxdCtx.Trk[TrkID].PostFX[1] and not FxdCtx.Trk[TrkID].PostFX_Hide then spaceIfPreFX = 20 end

            if Wheel_V ~= 0 and not DisableScroll then r.ImGui_SetNextWindowScroll(ctx, -CursorStartX + Wheel_V * 10, 0) end

            MainWin_Flg = r.ImGui_WindowFlags_HorizontalScrollbar() + FxdCtx.FX_DeviceWindow_NoScroll

            fxDisplay.displayFx(spaceIfPreFX)
            Pos_Devices_R, Pos_Devices_B = r.ImGui_GetItemRectMax(ctx)

            function MoveFX_Out_Of_Post(IDinPost)
                table.remove(FxdCtx.Trk[TrkID].PostFX,
                    IDinPost or tablefind(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID]))
                for i = 1, #FxdCtx.Trk[TrkID].PostFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, FxdCtx.Trk[TrkID].PostFX[i] or '',
                        true)
                end
            end

            function MoveFX_Out_Of_Pre(IDinPre)
                table.remove(FxdCtx.Trk[TrkID].PreFX,
                    IDinPre or tablefind(FxdCtx.Trk[TrkID].PreFX, FxdCtx.FXGUID[DragFX_ID]))
                for i = 1, #FxdCtx.Trk[TrkID].PreFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, FxdCtx.Trk[TrkID].PreFX[i] or '', true)
                end
            end

            function RemoveFXfromBS()
                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do -- check all fxs and see if it's a band splitter
                    if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].FXsInBS then
                        local FxID = tablefind(FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].FXsInBS, FxdCtx.FXGUID[DragFX_ID])
                        if FxID then
                            table.remove(FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].FXsInBS, FxID)
                            FxdCtx.FX[FxdCtx.FXGUID[DragFX_ID]].InWhichBand = nil
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: FX is in which BS' .. FxdCtx.FXGUID[DragFX_ID], '',
                                true)
                            r.GetSetMediaTrackInfo_String(LT_Track,
                                'P_EXT: FX is in which Band' .. FxdCtx.FXGUID[DragFX_ID], '',
                                true)
                        end
                    end
                end
            end

            _, Payload_Type, Payload, is_preview, Is_delivery = r.ImGui_GetDragDropPayload(ctx)
            Payload = tonumber(Payload)
            MouseAtRightEdge = r.ImGui_IsMouseHoveringRect(ctx, FxdCtx.VP.X + FxdCtx.VP.w - 25, FxdCtx.VP.y,
                FxdCtx.VP.X + FxdCtx.VP.w, FxdCtx.VP.y + FxdCtx.VP.h)

            if (Payload_Type == 'FX_Drag' or Payload_Type == 'DND ADD FX' and MouseAtRightEdge) and not FxdCtx.Trk[TrkID].PostFX[1] then
                r.ImGui_SameLine(ctx, nil, -5)
                Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                Rv               = r.ImGui_Button(ctx, 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, W, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)
                if r.ImGui_BeginDragDropTarget(ctx) then -- if drop to post fx chain
                    Drop, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, W, H_OutlineSc, V_OutlineSc,
                        'GetItemRect', WDL)

                    if Drop and not tablefind(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID]) then
                        table.insert(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID])
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #FxdCtx.Trk[TrkID].PostFX,
                            FxdCtx.FXGUID
                            [DragFX_ID], true)
                        r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)

                        local IDinPre = tablefind(FxdCtx.Trk[TrkID].PreFX, FxdCtx.FXGUID[DragFX_ID])
                        if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                    end

                    if --[[Move FX out of layer]] Drop and FxdCtx.FX.InLyr[FxdCtx.FXGUID[DragFX_ID]] then
                        FxdCtx.FX.InLyr[FxdCtx.FXGUID[DragFX_ID]] = nil
                        r.SetProjExtState(0, 'FX Devices',
                            'FXLayer - ' .. 'is FX' .. FxdCtx.FXGUID[DragFX_ID] .. 'in layer', '')
                    end

                    if Drop then
                        RemoveFXfromBS()
                        --Remove FX from BS if it's in BS
                    end



                    r.ImGui_EndDragDropTarget(ctx)
                else
                    Begindrop = false
                end
            end

            if Payload_Type == 'DND ADD FX' then
                local SpcIDinPost
                if SpcInPost then SpcIDinPost = math.max(#FxdCtx.Trk[TrkID].PostFX, 1) end
                DndAddFXfromBrowser_TARGET(Sel_Track_FX_Count, ClrLbl, SpaceIsBeforeRackMixer, SpcIDinPost) -- post fx
            end

            PostFX_Width = math.min(
                (MakeSpaceForPostFX or 0) + ((FxdCtx.Trk[TrkID].MakeSpcForPostFXchain or 0) + (PostFX_LastSpc or 0)) + 30,
                FxdCtx.VP.w / 2)



            if not FxdCtx.Trk[TrkID].PostFX[1] then
                FxdCtx.Trk[TrkID].MakeSpcForPostFXchain = 0
            end

            if FxdCtx.Trk[TrkID].PostFX[1] then
                r.ImGui_SameLine(ctx, nil, 0)
                Line_L, Line_T = r.ImGui_GetCursorScreenPos(ctx)
                Rv             = r.ImGui_Button(ctx,
                    (#FxdCtx.Trk[TrkID].PostFX or '') .. '\n\n' .. 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                if r.ImGui_IsItemClicked(ctx, 1) then
                    if FxdCtx.Trk[TrkID].PostFX_Hide then FxdCtx.Trk[TrkID].PostFX_Hide = false else FxdCtx.Trk[TrkID].PostFX_Hide = true end
                end
                if r.ImGui_BeginDragDropTarget(ctx) then -- if drop to post fx chain Btn
                    if Payload_Type == 'FX_Drag' then
                        Drop, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, W, H_OutlineSc, V_OutlineSc,
                            'GetItemRect', WDL)

                        if Drop and not tablefind(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID]) then
                            --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)
                            table.insert(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID])
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #FxdCtx.Trk[TrkID].PostFX,
                                FxdCtx.FXGUID[DragFX_ID], true)


                            local IDinPre = tablefind(FxdCtx.Trk[TrkID].PreFX, FxdCtx.FXGUID[DragFX_ID])
                            if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                        end
                    elseif Payload_Type == 'DND ADD FX' then
                        Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX')
                        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, W, H_OutlineSc, V_OutlineSc,
                            'GetItemRect', WDL)
                        if Dropped then
                            r.TrackFX_AddByName(LT_Track, Payload, false, -1000 - Sel_Track_FX_Count)
                            local FXid = r.TrackFX_GetFXGUID(LT_Track, Sel_Track_FX_Count)
                            table.insert(FxdCtx.Trk[TrkID].PostFX, FXid)
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #FxdCtx.Trk[TrkID].PostFX, FXid,
                                true)
                        end
                    end

                    r.ImGui_EndDragDropTarget(ctx)
                end

                r.ImGui_SameLine(ctx, nil, 0)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), 0xffffff11)
                local PostFX_Extend_W = 0
                if PostFX_Width == FxdCtx.VP.w / 2 then PostFX_Extend_W = 20 end
                if not FxdCtx.Trk[TrkID].PostFX_Hide then
                    if r.ImGui_BeginChild(ctx, 'Post FX chain', PostFX_Width - PostFX_Extend_W, 220) then
                        local clr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                        r.ImGui_DrawList_AddLine(FxdCtx.Glob.FDL, Line_L, Line_T - 1, Line_L + FxdCtx.VP.w, Line_T - 1,
                            clr)
                        r.ImGui_DrawList_AddLine(FxdCtx.Glob.FDL, Line_L, Line_T + 220, Line_L + FxdCtx.VP.w,
                            Line_T + 220, clr)



                        FxdCtx.Trk[TrkID].MakeSpcForPostFXchain = 0

                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then Offset = 0 else Offset = 1 end

                        for FX_Idx, V in pairs(FxdCtx.Trk[TrkID].PostFX) do
                            local I = --[[ tablefind(FXGUID, Trk[TrkID].PostFX[#Trk[TrkID].PostFX+1-FX_Idx])  ]]
                                tablefind(FxdCtx.FXGUID, V)

                            if FX_Idx == 1 and I then AddSpaceBtwnFXs(I - 1, 'SpcInPost', nil, nil, 1) end
                            if I then
                                createFXWindow(I)
                                r.ImGui_SameLine(ctx, nil, 0)

                                FxdCtx.FX[FxdCtx.FXGUID[I]].PostWin_SzX, _ = r.ImGui_GetItemRectSize(ctx)
                                FxdCtx.Trk[TrkID].MakeSpcForPostFXchain = (FxdCtx.Trk[TrkID].MakeSpcForPostFXchain or 0) +
                                    (FxdCtx.FX.WidthCollapse[FxdCtx.FXGUID[I]] or FxdCtx.FX[FxdCtx.FXGUID[I]].Width or (DefaultWidth)) +
                                    10 -- 10 is space btwn fxs

                                if FX_Idx == #FxdCtx.Trk[TrkID].PostFX then
                                    AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, #FxdCtx.Trk[TrkID].PostFX + 1)
                                else
                                    AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, FX_Idx + 1)
                                end
                                if FX_Idx == #FxdCtx.Trk[TrkID].PostFX and r.ImGui_IsItemHovered(ctx, r.ImGui_HoveredFlags_RectOnly()) then
                                    MouseAtRightEdge = true --[[ else MouseAtRightEdge = nil ]]
                                end
                            end
                        end




                        Offset = nil


                        if InsertToPost_Src then
                            table.insert(FxdCtx.Trk[TrkID].PostFX, InsertToPost_Dest, FxdCtx.FXGUID[InsertToPost_Src])
                            for i = 1, #FxdCtx.Trk[TrkID].PostFX + 1, 1 do
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i,
                                    FxdCtx.Trk[TrkID].PostFX[i] or '',
                                    true)
                            end
                            InsertToPost_Src = nil
                            InsertToPost_Dest = nil
                        end
                        r.ImGui_EndChild(ctx)
                    end
                else
                    FxdCtx.Trk[TrkID].MakeSpcForPostFXchain = 0
                end


                for FX_Idx, V in pairs(FxdCtx.Trk[TrkID].PostFX) do
                    local I = tablefind(FxdCtx.FXGUID, V)
                    local P = Sel_Track_FX_Count - #FxdCtx.Trk[TrkID].PostFX + (FX_Idx - 1)


                    if I ~= P then
                        r.Undo_BeginBlock()
                        if not FxdCtx.MovFX.FromPos[1] then
                            table.insert(FxdCtx.MovFX.FromPos, I)
                            table.insert(FxdCtx.MovFX.ToPos, P)
                            table.insert(FxdCtx.MovFX.Lbl, 'Move FX into Post-FX Chain')
                        end
                        --r.TrackFX_CopyToTrack(LT_Track, I, LT_Track, P, true)
                        r.Undo_EndBlock('Move FX out of Post-FX Chain', 0)
                    end
                end
                r.ImGui_PopStyleColor(ctx)
            end


            -- When Add or Delete Fx.....if  add fx or delete fx
            if Sel_Track_FX_Count ~= CompareFXCount then
                if FxdCtx.FX.Win_Name then
                    local _, tab = table_helpers.FindStringInTable(FxdCtx.FX.Win_Name, 'FX Devices Gain Reduction')
                    if tab then
                        for _, v in ipairs(tab) do
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

            FxdCtx.FirstLoop = false
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
                FxdCtx.DraggingFXs = {}
                FxdCtx.DraggingFXs_Idx = {}
            end
        end -- end for if LT_Track ~= nil





        r.ImGui_SetNextWindowSize(ctx, 500, 440, r.ImGui_Cond_FirstUseEver())
        if LT_Track then FXCountEndLoop = r.TrackFX_GetCount(LT_Track) end
        r.ImGui_End(ctx)
    end --end for Visible


    if open then
        r.defer(Loop)
    else --on script close
        NumOfTotalTracks = r.GetNumTracks()
        for T = 0, NumOfTotalTracks - 1, 1 do
            local track = r.GetTrack(0, T)
            local TrkID = r.GetTrackGUID(track)
            for i, _ in ipairs(FxdCtx.MacroNums) do
                if FxdCtx.Trk[TrkID].Mod[i].Val ~= nil then
                    r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID,
                        FxdCtx.Trk[TrkID].Mod[i].Val)
                end
            end
        end
    end
    Track_Fetch_At_End = r.GetLastTouchedTrack()
    WaitForGmem = WaitForGmem + 1
end --end for loop

r.defer(Loop)
