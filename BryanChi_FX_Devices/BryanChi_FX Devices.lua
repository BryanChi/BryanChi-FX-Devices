-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta14.2.3
-- @changelog
--  - Layout Editor : optimize the look of marquee selection 
-- @provides
--   [effect] FXD JSFXs/*.jsfx
--   [effect] FXD JSFXs/*.jsfx-inc
--   src/Constants.lua
--   src/Fonts/*.ttf
--   src/Functions/*.lua
--   src/FX Layout Plugin Scripts/*.lua
--   src/FX Layouts/ReaComp (Cockos).ini
--   src/FX Layouts/ValhallaDelay (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaFreqEcho (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaShimmer (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaSpaceModulator (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaSupermassive (Valhalla DSP, LLC).ini
--   src/FX Layouts/ValhallaVintageVerb (Valhalla DSP, LLC).ini
--   src/FXChains/ReaDrum Machine.RfxChain
--   src/Images/*.png
--   src/Images/Attached Drawings/LED light.png
--   src/Images/Knobs/Bitwig.png
--   src/Images/Knobs/FancyBlueKnob_Inverted.png
--   src/Images/Knobs/FancyBlueKnob.png
--   src/Images/Knobs/FancyGreenKnob.png
--   src/Images/Knobs/FancyLightGreenKnob.png
--   src/Images/Knobs/FancyRedKnob.png
--   src/Images/Switches/FancyGreenCheck_2.png
--   src/LFO Shapes/*.ini
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
im = require 'imgui' '0.9.1'
CurrentDirectory = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] -- GET DIRECTORY FOR REQUIRE
package.path = CurrentDirectory .. "?.lua;"



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


GetLTParam()


ctx = im.CreateContext('FX Devices', im.ConfigFlags_DockingEnable)
Retrieve_All_Info_Needed_Before_Main_Loop()


function loop()
    local validctx = r.ImGui_ValidatePtr(ctx,'ImGui_Context*')
    
    if ChangeFont then
        local ft =  _G[(ChangeFont_Font or 'Font_Andale_Mono') .. '_' .. (ChangeFont_Size or ChangeFont.FtSize)]
        if r.ImGui_ValidatePtr(ft, 'ImGui_Font') then 

            im.Attach(ctx, _G[(ChangeFont_Font or 'Font_Andale_Mono') .. '_' .. (ChangeFont_Size or ChangeFont.FtSize)])
            ChangeFont = nil
            ChangeFont_Size = nil
            ChangeFont_Font = nil
            ChangeFont_Var = nil
        end
    end
    --[[ if ChangeFontSize_TB then 
        for i, v in ipairs(ChangeFontSize_TB) do 
            v.FontSize = ChangeFontSize_Size
        end 
        ChangeFontSize_TB = nil
        ChangeFontSize_Size = nil 
    end  ]]    
    GetLT_FX_Num()
    GetLTParam()

    --CheckDnDType() -- Defined in Layout Editor functions
    
    local focused_window, hwnd = GetFocusedWindow()



    if Dock_Now then
        im.SetNextWindowDockID(ctx, -1)
    end
    Dock_Now = nil




    if LT_Track then TrkClr = im.ColorConvertNative(r.GetTrackColor(LT_Track)) end
    TrkClr = ((TrkClr or 0) << 8) | 0x66 -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity

    im.PushStyleColor(ctx, im.Col_MenuBarBg, TrkClr or 0x00000000)
    im.PushStyleColor(ctx, im.Col_WindowBg, Window_BG or CustomColorsDefault.Window_BG)
    --------------------------==  BEGIN GUI----------------------------------------------------------------------------
    local visible, open = im.Begin(ctx, 'FX Devices', true, im.WindowFlags_NoScrollWithMouse | im.WindowFlags_NoScrollbar | im.WindowFlags_MenuBar | im.WindowFlags_NoCollapse | im.WindowFlags_NoNav)
    im.PopStyleColor(ctx, 2) -- for menu  bar and window BG

    local Viewport = im.GetWindowViewport(ctx)
    VP.w, VP.h     = im.Viewport_GetSize(Viewport)
    VP.FDL = VP.FDL or im.GetForegroundDrawList(ctx)
    VP.X, VP.Y = im.GetCursorScreenPos(ctx)

    ----------------------------------------------------------------------------
    -- ImGUI Variables-----------------------------------------------------------
    ----------------------------------------------------------------------------
    GetAllMods( )


    if visible and LT_Track then
        
    
        r.gmem_write(4, 0) -- set jsfx mode to none , telling it user is not making any changes, this prevents bipolar modulation from going back to unipolar by setting modamt from 100~101 back to 0~1

        Execute_Keyboard_Shortcuts(ctx,KB_Shortcut,Command_ID, Mods)
        HelperMsg= {} 
        GetAllInfoNeededEachLoop()
        TREE = BuildFXTree(LT_Track)
        Add_Del_Move_FX_At_Begining_of_Loop()
        Show_Tooltip_For_Duration(Tooltip.Txt, Tooltip.Dur )


        ----- Duplicating FX to Layer -------
        if DragFX_Dest then
            MoveFX(DragFX_Src, DragFX_Src + 1, false)
            DropFXtoLayerNoMove(DroptoRack, DropToLyrID, DragFX_Src)
            MoveFX(DragFX_Src, DragFX_Dest + 1, true)
            DragFX_Src, DragFX_Dest, DropToLyrID = nil -- TODO should these be DragFX_Src, DragFX_Dest, DropToLyrID = nil, nil, nil
        end



        demo.PushStyle()

        Create_Diy_TrkID_If_None_Exist()

        r.gmem_attach('ParamValues')

        Activate_Debug_Mode()

        If_New_FX_Is_Added()




        ----Functions & Variables -------------
        Glob.FDL = im.GetForegroundDrawList(ctx)


        if IsLBtnClicked then Max_L_MouseDownDuration = nil end
        if IsLBtnHeld then
            Max_L_MouseDownDuration = math.max(LBtn_MousdDownDuration or -1, Max_L_MouseDownDuration or -1)
        end


        ----Colors & Font ------------
        --[[ im.PushStyleColor(ctx, im.Col_FrameBgHovered, 0xaaaaaa44)
            im.PushStyleColor(ctx, im.Col_FrameBg, 0x474747ff)
            im.PushStyleColor(ctx, im.Col_Text, 0x6e6e6eff) --Use Hex + FF in the end
            im.PushStyleColor(ctx, im.Col_SliderGrab, 0x808080ff)
            im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x808080ff) ]]

        --[[if Use_SystemFont then
                Font = System_Font
            else]]
        Font = Font_Andale_Mono
        --end
        im.PushFont(ctx, Font)




        ------------------------------
        ------Menu Bar---------------
        ------------------------------

        MenuBar ()

        


        ------------------------------
        ------Layout Editing ---------
        ------------------------------





        -----------==  Create Macros (Headers)-------------
        Create_Header_For_Track_Modulators()
        ---------------End Of header----------------------- 


        if ImGUI_Time > 3 then
            CompareFXCount = r.TrackFX_GetCount(LT_Track);
            ImGUI_Time = 0
        end

        if not im.IsPopupOpen(ctx, '##', im.PopupFlags_AnyPopup) then
            FX_Idx_OpenedPopup = nil
        end


        RepeatTimeForWindows = Sel_Track_FX_Count

        MaxX, MaxY = im.GetContentRegionMax(ctx)
        framepadding = im.StyleVar_FramePadding
        BorderSize = im.StyleVar_FrameBorderSize
        FrameRounding = im.StyleVar_FrameRounding
        BtnTxtAlign = im.StyleVar_ButtonTextAlign

        im.PushStyleVar(ctx, framepadding, 0, 3) --StyleVar#1 (Child Frame for all FX Devices)
        --im.PushStyleColor(ctx, im.Col_FrameBg, 0x121212ff)


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


        Glob.WDL = im.GetWindowDrawList(ctx)
        Glob.FDL = im.GetForegroundDrawList(ctx)


        if Dvdr.JustDroppedFX then
            if not Dvdr.JustDrop.X then
                Dvdr.JustDrop.X, Dvdr.JustDrop.Y = im.GetMousePos(ctx)
            end
            local X, Y = im.GetMousePos(ctx)

            if X > Dvdr.JustDrop.X + 15 or X < Dvdr.JustDrop.X - 15 then
                Dvdr.JustDroppedFX = nil
                Dvdr.JustDrop.X = nil
                Dvdr.JustDrop.Y = nil
            end
        end


        Trk[TrkID] = Trk[TrkID] or {}
        Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}


        im.PushStyleVar(ctx, im.StyleVar_ChildBorderSize, 0)
        Cx_LeftEdge, Cy_BeforeFXdevices = im.GetCursorScreenPos(ctx)
        MouseAtLeftEdge = im.IsMouseHoveringRect(ctx, Cx_LeftEdge - 50, Cy_BeforeFXdevices, Cx_LeftEdge + 5,
            Cy_BeforeFXdevices + 220)

        if MouseAtLeftEdge and not Trk[TrkID].PreFX[1] and string.len(Payload_Type) > 1 then
            rv = im.Button(ctx, 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
            SL(nil, 0)
            HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                'GetItemRect', WDL)

            if Payload_Type == 'FX_Drag' then
                dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                im.SameLine(ctx, nil, 0)
            elseif Payload_Type == 'DND ADD FX' then
                dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX') --
            end
        end


        if Trk[TrkID].PreFX[1] then
            rv = im.Button(ctx, (#Trk[TrkID].PreFX or '') .. '\n\n' .. 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20,
                220)
            im.SameLine(ctx, nil, 0)
            if im.IsItemClicked(ctx, 1) then
                if Trk[TrkID].PreFX_Hide then Trk[TrkID].PreFX_Hide = false else Trk[TrkID].PreFX_Hide = true end
            end
        end

        if im.BeginDragDropTarget(ctx) then
            if Payload_Type == 'FX_Drag' then
                rv, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)

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
            elseif Payload_Type == 'DND ADD FX' then
                dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX') --
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



            im.EndDragDropTarget(ctx)
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
        im.PushStyleColor(ctx, im.Col_ChildBg, Window_BG or CustomColorsDefault.Window_BG)

        local spaceIfPreFX = 0
        if Trk[TrkID].PreFX[1] and Trk[TrkID].PostFX[1] and not Trk[TrkID].PostFX_Hide then spaceIfPreFX = 20 end
        Scroll_Main_Window_With_Mouse_Wheel()
            

        MainWin_Flg = im.WindowFlags_HorizontalScrollbar | FX_DeviceWindow_NoScroll

        if im.BeginChild(ctx, 'fx devices', MaxX - (PostFX_Width or 0) - spaceIfPreFX, 240, nil, MainWin_Flg) then
            ------------------------------------------------------
            ----- Loop for every FX on the track -----------------
            ------------------------------------------------------





            CursorStartX = im.GetCursorStartPos(ctx)
            Glob.WinL, Glob.WinT = im.GetCursorScreenPos(ctx)
            Glob.Height = 220
            Glob.WinB = Glob.WinT + Glob.Height
            AnySplitBandHvred = false


            local ViewPort_DL = im.GetWindowDrawList(ctx)
            im.DrawList_AddLine(ViewPort_DL, 0, 0, 0, 0, Clr.Dvdr.outline) -- Needed for drawlist to be active

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


                local SpcW



                CreateSpace_first(FX_Idx, FxGUID)


                ---------------==  FX Devices--------------------

                DragFX_ID = DragFX_ID or -1000
                if DragDroppingFX == true and DragFX_ID == FX_Idx then
                    BGColor_FXWindow = FX_Window_Clr_When_Dragging
                else
                    BGColor_FXWindow = FX_Window_Clr_Default
                end
                BGColor_FXWindow = BGColor_FXWindow or 0x434343ff

              
                createFXWindow(FX_Idx)



                im.SameLine(ctx, nil, 0)

                local CurX = im.GetCursorPosX(ctx)



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
                        local R, B = im.GetItemRectMax(ctx)
                        im.DrawList_AddRect(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B,
                            im.GetColor(ctx, im.Col_Button))
                        im.DrawList_AddRectFilled(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B, 0xcccccc10)
                    end
                end
                ------------------------------------------
                if FX_Idx + 1 == RepeatTimeForWindows and not Trk[TrkID].PostFX[1] then -- add last space
                    AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc')
                elseif FX_Idx + 1 == RepeatTimeForWindows and Trk[TrkID].PostFX[1] then
                    AddSpaceBtwnFXs(Sel_Track_FX_Count - #Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
                end
            end --for repeat as many times as FX instances

            local function Detect_If_FX_Deleted()
                for i = 0, #FXGUID do
                    local FXid = r.TrackFX_GetFXGUID(LT_Track, i)

                    if FXid ~= FXGUID[i] then
                    end
                    --Detects if any FX is deleted
                    if FXid == nil then
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

            end






            Detect_If_FX_Deleted()


            When_User_Switch_Track()

            if Sel_Track_FX_Count == 0 then AddSpaceBtwnFXs(0, false, true) end




            im.EndChild(ctx)
            if HoverOnScrollItem then DisableScroll = true end

            if AnySplitBandHvred then
                HintMessage =
                'Mouse: Alt=Delete All FXs in Layer | Shift=Bypass FXs    Keys: M=mute band   Shift+M=Toggle all muted band | S=solo band  Shift+S=Toggle all solo\'d band'
            end
        end
        Pos_Devices_R, Pos_Devices_B = im.GetItemRectMax(ctx)

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

        _, Payload_Type, Payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)
        Payload = tonumber(Payload)
        MouseAtRightEdge = im.IsMouseHoveringRect(ctx, VP.X + VP.w - 25, VP.Y,
            VP.X + VP.w, VP.Y + VP.h)

        if (Payload_Type == 'FX_Drag' or Payload_Type == 'DND ADD FX' and MouseAtRightEdge) and not Trk[TrkID].PostFX[1] then
            im.SameLine(ctx, nil, -5)
            dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
            rv               = im.Button(ctx, 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
            HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                'GetItemRect', WDL)
            if im.BeginDragDropTarget(ctx) then -- if drop to post fx chain
                Drop, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
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



                im.EndDragDropTarget(ctx)
            else
                begindrop = false
            end
        end

        --[[ if Payload_Type == 'DND ADD FX' then
            local SpcIDinPost
            if SpcInPost then SpcIDinPost = math.max(#Trk[TrkID].PostFX, 1) end
            DndAddFXfromBrowser_TARGET(Sel_Track_FX_Count, ClrLbl, SpaceIsBeforeRackMixer, SpcIDinPost) -- post fx
        end ]]

        PostFX_Width = math.min(
            (MakeSpaceForPostFX or 0) + ((Trk[TrkID].MakeSpcForPostFXchain or 0) + (PostFX_LastSpc or 0)) + 30,
            VP.w / 2)



        if not Trk[TrkID].PostFX[1] then
            Trk[TrkID].MakeSpcForPostFXchain = 0
        end

        if Trk[TrkID].PostFX[1] then
            im.SameLine(ctx, nil, 0)
            Line_L, Line_T = im.GetCursorScreenPos(ctx)
            rv             = im.Button(ctx,
                (#Trk[TrkID].PostFX or '') .. '\n\n' .. 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
            if im.IsItemClicked(ctx, 1) then
                if Trk[TrkID].PostFX_Hide then Trk[TrkID].PostFX_Hide = false else Trk[TrkID].PostFX_Hide = true end
            end
            if im.BeginDragDropTarget(ctx) then -- if drop to post fx chain Btn
                if Payload_Type == 'FX_Drag' then
                    Drop, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
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
                elseif Payload_Type == 'DND ADD FX' then
                    dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX')
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

                im.EndDragDropTarget(ctx)
            end

            im.SameLine(ctx, nil, 0)
            im.PushStyleColor(ctx, im.Col_ChildBg, 0xffffff11)
            local PostFX_Extend_W = 0
            if PostFX_Width == VP.w / 2 then PostFX_Extend_W = 20 end
            if not Trk[TrkID].PostFX_Hide then
                if im.BeginChild(ctx, 'Post FX chain', PostFX_Width - PostFX_Extend_W, 220) then
                    local clr = im.GetStyleColor(ctx, im.Col_Button)
                    im.DrawList_AddLine(Glob.FDL, Line_L, Line_T - 1, Line_L + VP.w, Line_T - 1, clr)
                    im.DrawList_AddLine(Glob.FDL, Line_L, Line_T + 220, Line_L + VP.w, Line_T + 220, clr)



                    Trk[TrkID].MakeSpcForPostFXchain = 0

                    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = 0 else offset = 1 end

                    for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
                        local I = --[[ tablefind(FXGUID, Trk[TrkID].PostFX[#Trk[TrkID].PostFX+1-FX_Idx])  ]]
                            tablefind(FXGUID, V)

                        local Spc
                        if FX_Idx == 1 and I then AddSpaceBtwnFXs(I - 1, 'SpcInPost', nil, nil, 1) end
                        if I then
                            createFXWindow(I)
                            im.SameLine(ctx, nil, 0)

                            FX[FXGUID[I]].PostWin_SzX, _ = im.GetItemRectSize(ctx)
                            Trk[TrkID].MakeSpcForPostFXchain = (Trk[TrkID].MakeSpcForPostFXchain or 0) +
                                (FX.WidthCollapse[FXGUID[I]] or FX[FXGUID[I]].Width or (DefaultWidth)) +
                                10 -- 10 is space btwn fxs

                            if FX_Idx == #Trk[TrkID].PostFX then
                                AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, #Trk[TrkID].PostFX + 1)
                            else
                                AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, FX_Idx + 1)
                            end
                            if FX_Idx == #Trk[TrkID].PostFX and im.IsItemHovered(ctx, im.HoveredFlags_RectOnly) then
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
                    im.EndChild(ctx)
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
            im.PopStyleColor(ctx)
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


        im.PopStyleColor(ctx)
        --[[  im.PopStyleColor(ctx)  --  For Menu Bar Color
            im.PopStyleColor(ctx)  --  For WindowBg ]]

        im.PopStyleVar(ctx) --(Border Size for all fx devices)
        im.PopStyleVar(ctx) --StyleVar#1 (Child Frame for all FX Devices)

        im.PopFont(ctx)
        --im.PopStyleColor(ctx,Clr.poptimes)
        Track_Fetch_At_End = r.GetLastTouchedTrack()
        TrkID_End = r.GetTrackGUID(Track_Fetch_At_End)

        FirstLoop = false
        ProQ3.SpecWait = ProQ3.SpecWait + 1


        demo.PopStyle()

        --[[ HintPos = HintPost or im.GetCursorPosY(ctx)
        im.SetCursorPosY(ctx, HintPos) ]]
        

        Show_Helper_Message()
        if not IsLBtnHeld then
            DraggingFXs = {}
            DraggingFXs_Idx = {}
        end
        -- end for if LT_Track ~= nil





        im.SetNextWindowSize(ctx, 500, 440, im.Cond_FirstUseEver)
        if LT_Track then FXCountEndLoop = r.TrackFX_GetCount(LT_Track) end
    
    end 
    If_No_LT_Track()

    im.End(ctx)
    

    if open then
        PDefer(loop)
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
            Delete_All_FXD_AnalyzerFX(track)
        end
    end
    Track_Fetch_At_End = r.GetLastTouchedTrack()

end --end for loop

PDefer(loop)
