-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta19.1.2
-- @changelog
--   - Layout Editor : Added link feature to pool parameter properties to other parameters.
--   - Layout Editor : Added option to show buttons for selection type.
--   - Revamped fancy layout for Fresh Air.
--   - new Khs layout for phaser and compressor.
--   - fix Container enclosure display still showing when track selection has changed.
--   - fix Value tooltip still shows even when values are shwon in the Layout.
-- @provides
--   [effect] FXD JSFXs/*.jsfx
--   [effect] FXD JSFXs/*.jsfx-inc
--   [effect] FXD JSFXs/cookdsp/*.jsfx-inc
--   src/Constants.lua
--   src/Fonts/*.ttf
--   src/Functions/*.lua
--   src/FX Layout Plugin Scripts/*.lua
--   src/FX Layouts/*.ini
--   src/FXChains/ReaDrum Machine.RfxChain
--   src/Images/*.png
--   src/Images/Backgrounds/*.png
--   src/Images/Switches/*.png
--   src/Images/Attached Drawings/LED light.png
--   src/Images/Knobs/*.png
--   src/LFO Shapes/*.ini
--   src/Layout Editor Item Styles/V-Slider/*.ini
--   src/Layout Editor Item Styles/Switch/*.ini
--   src/Layout Editor Item Styles/Slider/*.ini
--   src/Layout Editor Item Styles/Drag/*.ini
--   src/Layout Editor Item Styles/Knob/*.ini
--   src/Layout Editor Item Styles/Selection/*.ini
--   [main] src/FXD - Record Last Touch.lua
-- @about
--   Please check the forum post for info:
--   https://forum.cockos.com/showthread.php?t=263622


r = reaper
OS = r.GetOS()

if not r.ImGui_GetBuiltinPath then
    r.ShowMessageBox("ReaImGui v0.9+ is required.\nPlease install or update it in the next window", "MISSING DEPENDENCIES", 0)
    return r.ReaPack_BrowsePackages('dear imgui')
end

---@type string
package.path = r.ImGui_GetBuiltinPath() .. '/?.lua'
im = require 'imgui' '0.9.3'
CurrentDirectory = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] -- GET DIRECTORY FOR REQUIRE
package.path = CurrentDirectory .. "?.lua;"
--DEBUGGER = dofile("/Users/b/.cursor/extensions/antoinebalaine.reascript-docs-0.1.12/debugger/LoadDebug.lua")


require("src.Constants")
require("src.Functions.EQ functions")
require("src.Functions.Filesystem_utils")
require("src.Functions.FX Layering")
require("src.Functions.General Functions")
require("src.Functions.GUI")
require("src.Functions.Layout Editor functions")
require("src.Functions.Modulation")
require("src.Functions.Theme Editor Functions")
require("src.Functions.Execute Before Loop")
require("src.Functions.Menu Bar")
require("src.Functions.SpecialFXs")
require("src.Functions.Pre_FX")
require("src.Functions.Post_FX")



GetLTParam()
local CommanID = r.NamedCommandLookup('_RSfc35279165adeb0f3708a5921116cc0fee7a78f6')

ctx = im.CreateContext('FX Devices', im.ConfigFlags_DockingEnable)

Retrieve_All_Info_Needed_Before_Main_Loop()
r.SetToggleCommandState(0, CommanID, 1)

 


function Main_Loop()
    If_New_Font()
    If_Change_Font()

    GetLT_FX_Num()
    GetLTParam()

    --CheckDnDType() -- Defined in Layout Editor functions

    if Dock_Now then
        im.SetNextWindowDockID(ctx, -1)
    end
    Dock_Now = nil




    if LT_Track then TrkClr = im.ColorConvertNative(r.GetTrackColor(LT_Track)) end
    TrkClr = ((TrkClr or 0) << 8) | 0x66 -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity

    im.PushStyleColor(ctx, im.Col_MenuBarBg, TrkClr or 0x00000000)
    im.PushStyleColor(ctx, im.Col_WindowBg, Window_BG or CustomColorsDefault.Window_BG)
    --------------------------==  BEGIN GUI----------------------------------------------------------------------------
    local visible, OpenMainWIN = im.Begin(ctx, 'FX Devices', true, im.WindowFlags_NoScrollWithMouse | im.WindowFlags_NoScrollbar | im.WindowFlags_MenuBar | im.WindowFlags_NoCollapse | im.WindowFlags_NoNav)
    im.PopStyleColor(ctx, 2) -- for menu  bar and window BG

    local Viewport = im.GetWindowViewport(ctx)
    VP.w, VP.h     = im.Viewport_GetSize(Viewport)
    VP.FDL = VP.FDL or im.GetForegroundDrawList(ctx)
    VP.X, VP.Y = im.GetCursorScreenPos(ctx)

    GetAllMods( )


    if visible and LT_Track and OpenMainWIN then

    
        r.gmem_write(4, 0) -- set jsfx mode to none , telling it user is not making any changes, this prevents bipolar modulation from going back to unipolar by setting modamt from 100~101 back to 0~1
        Execute_Keyboard_Shortcuts(ctx,KB_Shortcut,Command_ID, Mods)
        HelperMsg= {}    HelperMsg.Others = {}
        GetAllInfoNeededEachLoop()
        TREE = BuildFXTree(LT_Track)
        At_Begining_of_Loop()
        Show_Tooltip_For_Duration(Tooltip.txt, Tooltip.dur, Tooltip.pos )
        POP_STYLE_VAR = Push_Style_Var()

        demo.PushStyle()
        Create_Diy_TrkID_If_None_Exist()
        r.gmem_attach('ParamValues')
        Activate_Debug_Mode()
        Trk[TrkID] = Trk[TrkID] or {}


        ----Functions & Variables -------------
        Glob.FDL = im.GetForegroundDrawList(ctx)
        Glob.WDL = im.GetWindowDrawList(ctx)


        Font = Font_Andale_Mono_13
        im.PushFont(ctx, Font)

        MenuBar ()



        -----------==  Create Macros (Headers)-------------
        Create_Header_For_Track_Modulators__Squared_Modulators()
        ---------------End Of header----------------------- 

        im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, 3) --StyleVar#1 (Child Frame for all FX Devices)


        local spaceIfPreFX = Add_Btn_To_Drop_On_If_Mouse_Is_At_Left_Edge(Trk[TrkID])

        im.PushStyleVar(ctx, im.StyleVar_ChildBorderSize, 0) --  styleVar#2 Child Border size
        im.PushStyleColor(ctx, im.Col_ChildBg, Window_BG or CustomColorsDefault.Window_BG)

        Scroll_Main_Window_With_Mouse_Wheel()
            
        MainWin_Flg = im.WindowFlags_HorizontalScrollbar | FX_DeviceWindow_NoScroll
        local MaxX, MaxY = im.GetContentRegionMax(ctx)
        if im.BeginChild(ctx, 'fx devices', MaxX - (PostFX_Width or 0) - spaceIfPreFX, 260, nil, MainWin_Flg) then
            local X , Y = im.GetCursorScreenPos(ctx)

            Draw_Parallel_FX_Enclosure(FxGUID)
            
            AddSpacing(2)

            CursorStartX = im.GetCursorStartPos(ctx)
            Glob.WinL, Glob.WinT = im.GetCursorScreenPos(ctx)
            Glob.Height = 220
            Glob.WinB = Glob.WinT + Glob.Height
            AnySplitBandHvred = false


            local ViewPort_DL = im.GetWindowDrawList(ctx)
            im.DrawList_AddLine(ViewPort_DL, 0, 0, 0, 0, Clr.Dvdr.outline) -- Needed for drawlist to be active
            When_User_Switch_Track_Beginning_Of_Loop()
            FOCUSED_FX_STATE, trackNumOfFocusFX, _, FX_Index_FocusFX = r.GetFocusedFX2()

            for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx) --i used to be i-1
                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                FXGUID[FX_Idx] = FxGUID
                if not FxGUID then goto end_of_current_fx end 
                FX[FxGUID] = FX[FxGUID] or {}
                local fx = FX[FxGUID]

                local function Create_FX_Window(FX_Idx)
                    local Parallel

                    if --[[Normal Window]] (not string.find(FX_Name, 'FXD %(Mix%)RackMixer')) and FX.InLyr[FxGUID] == nil  and FindStringInTable(BlackListFXs, FX_Name) ~= true then
                        Tab_Collapse_Win = false

                        if not tablefind(Trk[TrkID].PostFX, FxGUID) and not FX[FxGUID].InWhichBand then

                            Parallel = createFXWindow(FX_Idx)
                        end
                    end

                    If_FX_is_ReSpectrum(FX_Idx, FX_Name)
                    If_FX_Is_BandSplitter(FX_Idx, FX_Name)
                    If_Theres_Pro_C_Analyzers(FX_Name, FX_Idx)
                    return Parallel
                end


                FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                AddSpaceBtwnFXs_FIRST(FX_Idx, FxGUID)


                ---------------==  FX Devices--------------------

                DragFX_ID = DragFX_ID or -1000


                local Parallel =  Create_FX_Window(FX_Idx) 
               
                AddSpaceBtwnFXs_LAST(FX_Idx, FxGUID)

                SL(nil,0)
                 ::end_of_current_fx::

                
            end --for repeat as many times as FX instances

            Pre_FX_Chain(FX_Idx)
            Detect_If_FX_Deleted()
            When_User_Switch_Track()

            if Sel_Track_FX_Count == 0 then AddSpaceBtwnFXs(0, false, true,nil,nil,nil, 300,nil,true)  end




            im.EndChild(ctx)
            if HoverOnScrollItem then DisableScroll = true end


        end
        Pos_Devices_R, Pos_Devices_B = im.GetItemRectMax(ctx)

        _, Payload_Type, Payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)
        Payload = tonumber(Payload)
        If_Drag_FX_to_Right_Edge(Payload_Type, Trk[TrkID])

        Post_FX_Chain (Trk[TrkID], Payload_Type)
        If_FX_Count_Changed__Refresh_Comp_Reduction_Scope() 

        im.PopStyleColor(ctx)
        im.PopStyleVar(ctx) -- styleVar#2 (Border Size for all fx devices)
        im.PopStyleVar(ctx) --StyleVar#1 (Child Frame for all FX Devices)
        im.PopFont(ctx)
        Track_Fetch_At_End = r.GetLastTouchedTrack()
        TrkID_End = r.GetTrackGUID(Track_Fetch_At_End)

        ProQ3.SpecWait = ProQ3.SpecWait + 1
        demo.PopStyle()


        Show_Helper_Message()
        if not IsLBtnHeld then
            DraggingFXs = {}
            DraggingFXs_Idx = {}
        end
        -- end for if LT_Track ~= nil




        im.PopStyleVar(ctx, POP_STYLE_VAR)
        im.SetNextWindowSize(ctx, 500, 440, im.Cond_FirstUseEver)
        if LT_Track then FXCountEndLoop = r.TrackFX_GetCount(LT_Track) end
        
    end 
    If_No_LT_Track()
    At_End_Of_Loop()

    if OpenMainWIN and visible then
        im.End(ctx)
    end

    if OpenMainWIN  then
        PDefer(Main_Loop)
    else --on script close
        At_Script_Close(CommanID)
    end
end --end for loop

PDefer(Main_Loop)
