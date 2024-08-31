-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta14.5
-- @changelog
--  - fix Saike Band Split and FX layering not working 
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


        im.PushStyleVar(ctx, im.StyleVar_ChildBorderSize, 0) --  styleVar#2 Child Border size
        Cx_LeftEdge, Cy_BeforeFXdevices = im.GetCursorScreenPos(ctx)
        MouseAtLeftEdge = im.IsMouseHoveringRect(ctx, Cx_LeftEdge - 50, Cy_BeforeFXdevices, Cx_LeftEdge + 5, Cy_BeforeFXdevices + 220)

        if MouseAtLeftEdge and not Trk[TrkID].PreFX[1] and string.len(Payload_Type) > 1 then
            rv = im.Button(ctx, 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
            SL(nil, 0)
            HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)

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

        if im.BeginChild(ctx, 'fx devices', MaxX - (PostFX_Width or 0) - spaceIfPreFX, 260, nil, MainWin_Flg) then
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

                local function Create_FX_Window()
                    if --[[Normal Window]] (not string.find(FX_Name, 'FXD %(Mix%)RackMixer')) and FX.InLyr[FXGUID[FX_Idx]] == nil and FX_Idx ~= RepeatTimeForWindows and FindStringInTable(BlackListFXs, FX_Name) ~= true then
                        --FX_IdxREAL =  FX_Idx+Lyr.FX_Ins[FXGUID[FX_Idx]]
                        Tab_Collapse_Win = false

                        if not tablefind(Trk[TrkID].PostFX, FxGUID) and not FX[FxGUID].InWhichBand then
                            createFXWindow(FX_Idx)
                            local rv, inputPins, outputPins = r.TrackFX_GetIOSize(LT_Track, FX_Idx)
                        end

                        local function Layout_Edit()
                            if FX.LayEdit == FXGUID[FX_Idx] then
                                im.PushStyleColor(ctx, im.Col_HeaderHovered, 0xffffff00)
                                im.PushStyleColor(ctx, im.Col_HeaderActive, 0xffffff00)

                                local FxGUID = FXGUID[FX_Idx]

                                if not CloseLayEdit and im.Begin(ctx, 'LayoutEdit Propertiess', true, im.WindowFlags_NoCollapse + im.WindowFlags_NoTitleBar + im.WindowFlags_NoDocking) then
                                    --if not CloseLayEdit   then    ----START CHILD WINDOW------
                                    DisableScroll = true



                                    if im.Button(ctx, 'Save') then
                                        SaveLayoutEditings(FX_Name, FX_Idx, FXGUID[FX_Idx])
                                        CloseLayEdit = true; FX.LayEdit = nil
                                    end
                                    SL()
                                    if im.Button(ctx, 'Exit##Lay') then
                                        im.OpenPopup(ctx, 'Save Editing?')
                                    end
                                    SL()

                                    if LE.Sel_Items[1] then
                                        local I = FX[FxGUID][LE.Sel_Items[1]]
                                        if im.Button(ctx, 'Delete') then
                                            local tb = {}

                                            for i, v in pairs(LE.Sel_Items) do
                                                tb[i] = v
                                            end
                                            table.sort(tb)

                                            for i = #tb, 1, -1 do
                                                DeletePrm(FxGUID, tb[i], FX_Idx)
                                            end

                                            if not FX[FxGUID][1] then FX[FxGUID].AllPrmHasBeenDeleted = true else FX[FxGUID].AllPrmHasBeenDeleted = nil end


                                            LE.Sel_Items = {}
                                        end

                                        SL(nil, 30)

                                        if im.Button(ctx, 'Copy Properties') then
                                            CopyPrm = {}
                                            CopyPrm = I
                                        end

                                        SL()
                                        if im.Button(ctx, 'Paste Properties') then
                                            for i, v in pairs(LE.Sel_Items) do
                                                local I = FX[FxGUID][v]
                                                I.Type        = CopyPrm.Type
                                                I.Sldr_W      = CopyPrm.Sldr_W
                                                I.Style       = CopyPrm.Style
                                                I.V_FontSize  = CopyPrm.V_FontSize
                                                --I.CustomLbl   = CopyPrm.CustomLbl
                                                I.FontSize    = CopyPrm.FontSize
                                                I.Sldr_H      = CopyPrm.Sldr_H
                                                I.BgClr       = CopyPrm.BgClr
                                                I.GrbClr      = CopyPrm.GrbClr
                                                I.Lbl_Pos     = CopyPrm.Lbl_Pos
                                                I.Lbl_Pos_X   = CopyPrm.Lbl_Pos_X
                                                I.Lbl_Pos_Y   = CopyPrm.Lbl_Pos_Y
                                                I.V_Pos       = CopyPrm.V_Pos
                                                I.Lbl_Clr     = CopyPrm.Lbl_Clr
                                                I.V_Clr       = CopyPrm.V_Clr
                                                I.DragDir     = CopyPrm.DragDir
                                                I.Value_Thick = CopyPrm.Value_Thick
                                                I.V_Pos_X     = CopyPrm.V_Pos_X
                                                I.V_Pos_Y     = CopyPrm.V_Pos_Y
                                                I.ImagePath   = CopyPrm.ImagePath
                                                I.Height = CopyPrm.Height
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
                                        if im.Button(ctx, 'Exit Background Edit') then Draw.DrawMode[FxGUID] = false end
                                    else
                                        if im.Button(ctx, 'Enter Background Edit') then
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




                                    im.Separator(ctx)


                                    local ColorPaletteTop = im.GetCursorPosY




                                    -- Add Drawings ----
                                    if not LE.Sel_Items[1] then
                                        if Draw.DrawMode[FxGUID] ~= true then
                                            im.TextWrapped(ctx, 'Select an item to start editing')
                                            AddSpacing(15)
                                        else
                                            im.Text(ctx, '(!) Hold down Left button to Draw in FX Devices')
                                            AddSpacing(5)
                                            im.Text(ctx, 'Type:')
                                            im.SameLine(ctx)
                                            im.PushStyleColor(ctx, im.Col_FrameBg, 0x99999933)
                                            local D = Draw[FX.Win_Name_S[FX_Idx]]
                                            FX[FxGUID].Draw = FX[FxGUID].Draw or {}
                                            local D = FX[FxGUID].Draw
                                            local FullWidth = -50

                                            local typelbl; local It = Draw.SelItm
                                            --D[It or 1] = D[It or 1] or {}


                                            if Draw.SelItm then typelbl = D[It].Type end
                                            if Draw.Type == nil then Draw.Type = 'line' end
                                            im.SetNextItemWidth(ctx, FullWidth)
                                            if im.BeginCombo(ctx, '##', typelbl or Draw.Type or 'line', im.ComboFlags_NoArrowButton) then
                                                local function setType(str)
                                                    if im.Selectable(ctx, str, false) then
                                                        if It then D[It].Type = str end
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

                                                im.EndCombo(ctx)
                                            end

                                            if It then
                                                im.Text(ctx, 'Color :')
                                                im.SameLine(ctx)
                                                if Draw.SelItm and D[It].clr then
                                                    clrpick, D[It].clr = im.ColorEdit4(ctx, '##',
                                                        D[It].clr or 0xffffffff,
                                                        im.ColorEditFlags_NoInputs|
                                                        im.ColorEditFlags_AlphaPreviewHalf|
                                                        im.ColorEditFlags_AlphaBar)
                                                else
                                                    clrpick, Draw.clr = im.ColorEdit4(ctx, '##',
                                                        Draw.clr or 0xffffffff,
                                                        im.ColorEditFlags_NoInputs|
                                                        im.ColorEditFlags_AlphaPreviewHalf|
                                                        im.ColorEditFlags_AlphaBar)
                                                end
                                                im.Text(ctx, 'Default edge rounding :')
                                                im.SameLine(ctx)
                                                im.SetNextItemWidth(ctx, 40)

                                                FX[FxGUID].Draw = FX[FxGUID].Draw or {}
                                                EditER, FX[FxGUID].Draw.Df_EdgeRound = im.DragDouble(ctx,
                                                    '##' .. FxGUID,
                                                    FX[FxGUID].Draw.Df_EdgeRound, 0.05, 0, 30, '%.2f')



                                                if D[It].Type == 'Picture' then
                                                    im.Text(ctx, 'File Path:')
                                                    SL()
                                                    DragDropPics = DragDropPics or {}

                                                    if im.BeginChildFrame(ctx, '##drop_files', FullWidth, 40) then
                                                        if not D[It].FilePath then
                                                            im.Text(ctx, 'Drag and drop files here...')
                                                        else
                                                            im.Text(ctx, D[It].FilePath)

                                                            if im.SmallButton(ctx, 'Clear') then

                                                            end
                                                        end
                                                        if D[It].FilePath then
                                                            im.Bullet(ctx)
                                                            im.TextWrapped(ctx, D[It].FilePath)
                                                        end
                                                        im.EndChildFrame(ctx)
                                                    end


                                                    if im.BeginDragDropTarget(ctx) then
                                                        local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                                                        if rv then
                                                            for i = 0, count - 1 do
                                                                local filename
                                                                rv, filename = im.GetDragDropPayloadFile(ctx, i)
                                                                D[It].FilePath = filename

                                                                D[It].Image = im.CreateImage(filename)
                                                                im.Attach(ctx, D[It].Image)
                                                            end
                                                        end
                                                        im.EndDragDropTarget(ctx)
                                                    end

                                                    rv, D[It].KeepImgRatio = im.Checkbox(ctx, 'Keep Image Ratio',
                                                        D[It].KeepImgRatio)
                                                end

                                                if Draw.SelItm then
                                                    im.Text(ctx, 'Start Pos X:')
                                                    im.SameLine(ctx)
                                                    local CurX = im.GetCursorPosX(ctx)
                                                    im.SetNextItemWidth(ctx, FullWidth)
                                                    _, D[It].L = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'L',
                                                        D[It].L,
                                                        1, 0, Win_W, '%.0f')
                                                    if D[It].Type ~= 'V-line' and D[It].Type ~= 'circle' and D[It].Type ~= 'circle fill' then
                                                        im.Text(ctx, 'End Pos X:')
                                                        im.SetNextItemWidth(ctx, FullWidth)

                                                        im.SameLine(ctx, CurX)
                                                        _, D[It].R = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                                            D[It].R, 1, 0, Win_W, '%.0f')
                                                    end

                                                    if D[It].Type == 'circle' or D[It].Type == 'circle fill' then
                                                        im.Text(ctx, 'Radius:')
                                                        im.SameLine(ctx)
                                                        im.SetNextItemWidth(ctx, FullWidth)
                                                        _, D[It].R = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                                            D[It].R, 1, 0, Win_W, '%.0f')
                                                    end


                                                    im.Text(ctx, 'Start Pos Y:')

                                                    im.SameLine(ctx)
                                                    im.SetNextItemWidth(ctx, FullWidth)

                                                    _, D[It].T = im.DragDouble(ctx, '##' .. Draw.SelItm .. 'T',
                                                        D[It].T, 1, 0, Win_W, '%.0f')


                                                    if D[It].Type ~= 'line' and D[It].Type ~= 'circle fill' and D[It].Type ~= 'circle' then
                                                        im.Text(ctx, 'End Pos Y:')
                                                        im.SameLine(ctx, CurX)
                                                        im.SetNextItemWidth(ctx, FullWidth)

                                                        _, D[It].B = im.DragDouble(ctx, '##' .. It .. 'B', D[It].B, 1,
                                                            0,
                                                            Win_W, '%.0f')
                                                    end

                                                    if D[It].Type == 'Text' then
                                                        im.Text(ctx, 'Text:')
                                                        im.SameLine(ctx)

                                                        _, D[It].Txt = im.InputText(ctx, '##' .. It .. 'Txt',
                                                            D[It].Txt)

                                                        SL()
                                                        im.Text(ctx, 'Font Size:')
                                                        local rv, Sz = im.InputInt(ctx, '## font size ' .. It,
                                                            D[It].FtSize or 12)
                                                        if rv then
                                                            D[It].FtSize = Sz
                                                            if not _G['Font_Andale_Mono' .. '_' .. Sz] then
                                                                _G['Font_Andale_Mono' .. '_' .. Sz] = im.CreateFont(
                                                                    'andale mono', Sz)
                                                                ChangeFont = D[It]
                                                            else
                                                                D[It].Font = _G['Font_Andale_Mono' .. '_' .. Sz]
                                                            end
                                                        end
                                                    end
                                                end
                                            end



                                            im.PopStyleColor(ctx)
                                        end
                                    elseif LE.Sel_Items[1] then
                                        local ID, TypeID; local FrstSelItm = FX[FxGUID][LE.Sel_Items[1]]; local FItm =
                                            LE
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
                                            if Diff_Clr_Found then
                                                ClrID = 'Group'
                                            else
                                                ClrID = FxGUID ..
                                                    LE.Sel_Items[1]
                                            end
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
                                            if FrstSelItm.V_Pos ~= 'None' then
                                                im.Text(ctx, 'X:')
                                                SL()
                                                im.SetNextItemWidth(ctx, 50)
                                                local EditPosX, PosX = im.DragDouble(ctx,
                                                    ' ##EditValuePosX' .. FxGUID .. LE.Sel_Items[1],
                                                    FrstSelItm.V_Pos_X or 0,
                                                    0.25, nil, nil, '%.2f')
                                                SL()
                                                if EditPosX then
                                                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Pos_X = PosX end
                                                end
                                                im.Text(ctx, 'Y:')
                                                SL()
                                                im.SetNextItemWidth(ctx, 50)
                                                local EditPosY, PosY = im.DragDouble(ctx,
                                                    ' ##EditValuePosY' .. FxGUID .. LE.Sel_Items[1],
                                                    FrstSelItm.V_Pos_Y or 0,
                                                    0.25, nil, nil, '%.2f')
                                                SL()
                                                if EditPosY then
                                                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Pos_Y = PosY end
                                                end
                                            end
                                        end

                                        local function FreeLblPosSettings()
                                            if FrstSelItm.Lbl_Pos ~= 'None' then
                                                im.Text(ctx, 'X:')
                                                SL()
                                                im.SetNextItemWidth(ctx, 50)
                                                local EditPosX, PosX = im.DragDouble(ctx,
                                                    ' ##EditLblPosX' .. FxGUID .. LE.Sel_Items[1],
                                                    FrstSelItm.Lbl_Pos_X or 0,
                                                    0.25, nil, nil, '%.2f')
                                                SL()
                                                if EditPosX then
                                                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Pos_X = PosX end
                                                end
                                                im.Text(ctx, 'Y:')
                                                SL()
                                                im.SetNextItemWidth(ctx, 50)
                                                local EditPosY, PosY = im.DragDouble(ctx,
                                                    ' ##EditLblPosY' .. FxGUID .. LE.Sel_Items[1],
                                                    FrstSelItm.Lbl_Pos_Y or 0,
                                                    0.25, nil, nil, '%.2f')
                                                SL()
                                                if EditPosY then
                                                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Pos_Y = PosY end
                                                end
                                            end
                                        end
                                        local function AddOption(Name, TargetVar, TypeCondition)
                                            if FrstSelItm.Type == TypeCondition or not TypeCondition then
                                                if im.Selectable(ctx, Name, false) then
                                                    for i, v in pairs(LE.Sel_Items) do
                                                        FX[FxGUID][v][TargetVar] =
                                                            Name
                                                    end
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
                                        im.Text(ctx, 'Type : '); im.SameLine(ctx); im.PushStyleColor(ctx,
                                            im.Col_FrameBg, 0x444444aa)
                                        im.SetNextItemWidth(ctx, -R_ofs)
                                        if im.BeginCombo(ctx, '##', PrmTypeLbl, im.ComboFlags_NoArrowButton) then
                                            local function SetItemType(Type)
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].Sldr_W = nil
                                                    FX[FxGUID][v].Type = Type
                                                end
                                            end

                                            if im.Selectable(ctx, 'Slider', false) then
                                                SetItemType('Slider')
                                            elseif im.Selectable(ctx, 'Knob', false) then
                                                SetItemType('Knob')
                                            elseif im.Selectable(ctx, 'V-Slider', false) then
                                                SetItemType('V-Slider')
                                            elseif im.Selectable(ctx, 'Drag', false) then
                                                SetItemType('Drag')
                                            elseif im.Selectable(ctx, 'Switch', false) then
                                                SetItemType('Switch')
                                            elseif im.Selectable(ctx, 'Selection', false) then
                                                SetItemType('Selection')
                                            end
                                            im.EndCombo(ctx)
                                        end

                                        ---Label    Show only when there's one item selected-----
                                        if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                                            im.Text(ctx, 'Label: '); im.SameLine(ctx)
                                            im.SetNextItemWidth(ctx, -R_ofs)
                                            local LblEdited, buf = im.InputText(ctx,
                                                ' ##Edit Title' .. FxGUID .. LE.Sel_Items[1],
                                                FrstSelItm.CustomLbl or buf)
                                            if im.IsItemActivated(ctx) then EditingPrmLbl = LE.Sel_Items[1] end
                                            if im.IsItemDeactivatedAfterEdit(ctx) then FrstSelItm.CustomLbl = buf end
                                        end

                                        --Label Pos
                                        im.Text(ctx, 'Label Pos: '); im.SameLine(ctx); im.SetNextItemWidth(
                                            ctx, 100)
                                        if im.BeginCombo(ctx, '## Lbl Pos' .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos or 'Default', im.ComboFlags_NoArrowButton) then
                                            if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'V-Slider' then
                                                AddOption('Top', 'Lbl_Pos')
                                                AddOption('Bottom', 'Lbl_Pos')
                                            elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' then
                                                AddOption('Left', 'Lbl_Pos')
                                                AddOption('Top', 'Lbl_Pos')
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
                                            im.EndCombo(ctx)
                                        end
                                        im.SameLine(ctx)
                                        FreeLblPosSettings()
                                        -- Label Color
                                        DragLbl_Clr_Edited, Lbl_V_Clr = im.ColorEdit4(ctx, '##Lbl Clr' ..
                                            LE.Sel_Items[1], FrstSelItm.Lbl_Clr or im.GetColor(ctx, im.Col_Text),
                                            im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                                            im.ColorEditFlags_AlphaBar)
                                        if DragLbl_Clr_Edited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Clr = Lbl_V_Clr end
                                        end


                                        im.Text(ctx, 'Value Pos: '); im.SameLine(ctx); im.SetNextItemWidth(
                                            ctx, 100)
                                        if im.BeginCombo(ctx, '## V Pos' .. LE.Sel_Items[1], FrstSelItm.V_Pos or 'Default', im.ComboFlags_NoArrowButton) then
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
                                                AddOption('Top', 'V_Pos')

                                            end
                                            if FrstSelItm.Type ~= 'Selection' then AddOption('None', 'V_Pos') end

                                            AddOption('Free', 'V_Pos')

                                            im.EndCombo(ctx)
                                        end
                                        im.SameLine(ctx)

                                        FreeValuePosSettings()
                                        DragV_Clr_edited, Drag_V_Clr = im.ColorEdit4(ctx,
                                            '##V  Clr' .. LE.Sel_Items[1],
                                            FrstSelItm.V_Clr or im.GetColor(ctx, im.Col_Text),
                                            im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                                            im.ColorEditFlags_AlphaBar)
                                        if DragV_Clr_edited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = Drag_V_Clr end
                                        end

                                        if FrstSelItm.Type == 'Drag' then
                                            im.Text(ctx, 'Direction: ')
                                            im.SameLine(ctx)
                                            im.SetNextItemWidth(ctx, -R_ofs)
                                            if im.BeginCombo(ctx, '## Drag Dir' .. LE.Sel_Items[1], FrstSelItm.DragDir or '', im.ComboFlags_NoArrowButton) then
                                                if im.Selectable(ctx, 'Right', false) then
                                                    for i, v in pairs(LE.Sel_Items) do
                                                        FX[FxGUID][v].DragDir =
                                                        'Right'
                                                    end
                                                elseif im.Selectable(ctx, 'Left-Right', false) then
                                                    for i, v in pairs(LE.Sel_Items) do
                                                        FX[FxGUID][v].DragDir =
                                                        'Left-Right'
                                                    end
                                                elseif im.Selectable(ctx, 'Left', false) then
                                                    for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Left' end
                                                end
                                                im.EndCombo(ctx)
                                            end
                                        end








                                        if FrstSelItm.Type == 'Switch' then
                                            local Momentary, Toggle
                                            if FrstSelItm.SwitchType == 'Momentary' then
                                                Momentary = true
                                            else
                                                Toggle = true
                                            end
                                            EdT, Tg = im.Checkbox(ctx, 'Toggle##' .. FxGUID .. LE.Sel_Items[1],
                                                Toggle)
                                            im.SameLine(ctx);
                                            EdM, Mt = im.Checkbox(ctx, 'Momentary##' .. FxGUID .. LE.Sel_Items[1],
                                                Momentary)
                                            if EdT then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].SwitchType =
                                                    'Toggle'
                                                end
                                            elseif EdM then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].SwitchType =
                                                    'Momentary'
                                                end
                                            end
                                        end



                                        -- set base and target value
                                        if FrstSelItm.SwitchType == 'Momentary' and FrstSelItm.Type == 'Switch' then
                                            im.Text(ctx, 'Base Value: ')
                                            im.SameLine(ctx); im.SetNextItemWidth(ctx, 80)
                                            local Drag, Bv = im.DragDouble(ctx,
                                                '##EditBaseV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                                FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV or 0, 0.05, 0, 1, '%.2f')
                                            if Drag then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV = Bv
                                                end
                                            end
                                            im.Text(ctx, 'Target Value: ')
                                            im.SameLine(ctx); im.SetNextItemWidth(ctx, 80)
                                            local Drag, Tv = im.DragDouble(ctx,
                                                '##EditTargV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                                FX[FxGUID][LE.Sel_Items[1]].SwitchTargV or 1, 0.05, 0, 1, '%.2f')
                                            if Drag then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][LE.Sel_Items[1]].SwitchTargV =
                                                        Tv
                                                end
                                            end
                                        end









                                        local FLT_MIN, FLT_MAX = im.NumericLimits_Float()
                                        ----Font Size-----


                                        im.Text(ctx, 'Label Font Size: '); im.SameLine(ctx)
                                        im.SetNextItemWidth(ctx, 50)
                                        local Drag, ft = im.DragDouble(ctx,
                                            '##EditFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FrstSelItm.FontSize or Knob_DefaultFontSize, 0.25, 6, 64, '%.2f')
                                        if Drag then
                                            local sz = roundUp(ft, 1)
                                            if not _G['Font_Andale_Mono' .. '_' .. sz] then
                                                _G['Font_Andale_Mono' .. '_' .. sz] = im.CreateFont('andale mono', sz)
                                                ChangeFont = FrstSelItm
                                                ChangeFont_Size = sz
                                            end

                                            ChangeFontSize_TB = {}
                                            for i, v in pairs(LE.Sel_Items) do
                                                table.insert(ChangeFontSize_TB, FX[FxGUID][v])
                                                FX[FxGUID][v].FontSize = ft
                                            end
                                            ChangeFontSize_Size = ft
                                        end






                                        SL()
                                        im.Text(ctx, 'Value Font Size: '); im.SameLine(ctx)
                                        im.SetNextItemWidth(ctx, 50)
                                        local Drag, ft = im.DragDouble(ctx,'##EditV_FontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),FX[FxGUID][LE.Sel_Items[1]].V_FontSize or Knob_DefaultFontSize, 0.25, 6,64,'%.2f')
                                        if Drag then
                                            local sz = roundUp(ft, 1)
                                            if not _G['Arial' .. '_' .. sz] then
                                               -- _G['Arial' .. '_' .. sz] = im.CreateFont('Arial', sz)
                                                ChangeFont = FrstSelItm
                                                ChangeFont_Size = sz
                                                ChangeFont_Font = 'Arial'
                                            end
                                            --[[ for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].V_FontSize = ft
                                            end ]]
                                            ChangeFontSize_TB = {}
                                            for i, v in pairs(LE.Sel_Items) do
                                                table.insert(ChangeFontSize_TB, FX[FxGUID][v])
                                                FX[FxGUID][v].V_FontSize = ft
                                            end
                                            ChangeFontSize_Size = ft
                                        end








                                        ----Width -------
                                        im.Text(ctx, 'Width: '); im.SameLine(ctx)
                                        im.SetNextItemWidth(ctx, 60)
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

                                        SL()


                                        local _, W = im.DragDouble(ctx,
                                            '##EditWidth' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1] or ''].Sldr_W or DefaultW, LE.GridSize / 4,
                                            MinW, MaxW,
                                            '%.1f')

                                        if im.IsItemEdited(ctx) then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].Sldr_W = W
                                            end
                                        end


                                        if FrstSelItm.Type ~= 'Knob' then
                                            SL()
                                            im.Text(ctx, 'Height: ')
                                            SL()
                                            im.SetNextItemWidth(ctx, 60)
                                            local max, defaultH
                                            if FrstSelItm.Type == 'V-Slider' then
                                                max = 200
                                                defaultH = 160
                                            end
                                            local _, W = im.DragDouble(ctx,
                                                '##Height' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                                FX[FxGUID][LE.Sel_Items[1] or ''].Height or defaultH or 3,
                                                LE.GridSize / 4,
                                                -5, max or 40, '%.1f')
                                            if im.IsItemEdited(ctx) then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].Height = W
                                                end
                                            end
                                        end



                                        if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'Drag' or FrstSelItm.Type == 'Slider' then
                                            im.Text(ctx, 'Value Decimal Places: '); im.SameLine(ctx)
                                            im.SetNextItemWidth(ctx, 80)
                                            if not FX[FxGUID][LE.Sel_Items[1]].V_Round then
                                                local _, FormatV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                    FX[FxGUID][LE.Sel_Items[1]].Num)
                                                local _, LastNum = FormatV:find('^.*()%d')
                                                local dcm = FormatV:find('%.')
                                                if dcm then
                                                    rd = LastNum - dcm
                                                end
                                            end

                                            local Edit, rd = im.InputInt(ctx,
                                                '##EditValueDecimals' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                                FrstSelItm.V_Round or rd, 1)
                                            if Edit then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].V_Round = math.max(
                                                        rd, 0)
                                                end
                                            end
                                        end







                                        im.Text(ctx, 'Value to Note Length: '); im.SameLine(ctx)
                                        im.SetNextItemWidth(ctx, 80)
                                        local Edit = im.Checkbox(ctx,
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
                                        if FrstSelItm.Type == 'Selection' then --im.Text(ctx,'Edit Values Manually: ') ;im.SameLine(ctx)
                                            local Itm = LE.Sel_Items[1]
                                            local FP = FX[FxGUID][Itm] ---@class FX_P



                                            if im.TreeNode(ctx, 'Edit Values Manually') then
                                                FX[FxGUID][Itm].ManualValues = FX[FxGUID][Itm].ManualValues or {}
                                                FX[FxGUID][Itm].ManualValuesFormat = FX[FxGUID][Itm]
                                                    .ManualValuesFormat or {}
                                                if im.Button(ctx, 'Get Current Value##' .. FxGUID .. (Itm or '')) then
                                                    local Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP
                                                        .Num)
                                                    if not tablefind(FP.ManualValues, Val) then
                                                        table.insert(FX[FxGUID][Itm].ManualValues, Val)
                                                    end
                                                end
                                                for i, V in ipairs(FX[FxGUID][Itm].ManualValues) do
                                                    im.AlignTextToFramePadding(ctx)
                                                    im.Text(ctx, i .. ':' .. (round(V, 2) or 0))
                                                    SL()
                                                    --im.SetNextItemWidth(ctx, -R_ofs)
                                                    rv, FX[FxGUID][Itm].ManualValuesFormat[i] = im.InputText(ctx,
                                                        '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i,
                                                        FX[FxGUID][Itm].ManualValuesFormat[i])
                                                    SL()
                                                    local LH = im.GetTextLineHeight(ctx)
                                                    local rv = im.Button(ctx, '##%', 20, 20) -- bin icon
                                                    DrawListButton(WDL, '%',
                                                        r.ImGui_GetColor(ctx, r.ImGui_Col_Button()), nil,
                                                        true, icon1_middle, false) -- trash bin
                                                    if rv then
                                                        table.remove(FX[FxGUID][Itm].ManualValuesFormat, i)
                                                        table.remove(FX[FxGUID][Itm].ManualValues, i)
                                                    end
                                                end
                                                --FX[FxGUID][Itm].EditValuesManual = true
                                                im.TreePop(ctx)
                                            end
                                        end

                                        function ToAllSelItm(x, y)
                                            for i, v in ipairs(LE.Sel_Items) do
                                                FX[FxGUID][v][x] = y
                                            end
                                        end

                                        local FLT_MIN, FLT_MAX = im.NumericLimits_Float()

                                        --- Style ------
                                        im.Text(ctx, 'Style: '); im.SameLine(ctx)
                                        w = im.CalcTextSize(ctx, 'Style: ')
                                        local stylename
                                        if FrstSelItm.Style == 'Pro C' then stylename = 'Minimalistic' end
                                        if im.Button(ctx, (stylename or FrstSelItm.Style or 'Choose Style') .. '##' .. (LE.Sel_Items[1] or 'Style'), 130) then
                                            im.OpenPopup(ctx, 'Choose style window')
                                        end


                                        im.Text(ctx, 'Add Custom Image:')

                                        DragDropPics = DragDropPics or {}

                                        local rv, ImgTrashTint = TrashIcon(16, 'Clear', ClrBG, ImgTrashTint)
                                        if rv then
                                            ToAllSelItm('Style', nil)
                                            ToAllSelItm('ImagePath', nil)
                                            ToAllSelItm('Image', nil)
                                        end


                                        SL()
                                        if im.BeginChild(ctx, '##drop_files', -R_ofs, 20) then
                                            if not FrstSelItm.ImagePath then
                                                im.Text(ctx, 'Drag and drop files here...')
                                            else
                                                --FrstSelItm.Style = 'Custom Image'

                                                im.Text(ctx, FrstSelItm.ImagePath)
                                            end

                                            im.EndChild(ctx)
                                        end

                                        if im.BeginDragDropTarget(ctx) then
                                            local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                                            if rv then
                                                for i = 0, count - 1 do
                                                    local rv, filename = im.GetDragDropPayloadFile(ctx, i)
                                                    if rv then
                                                        FrstSelItm.Style = 'Custom Image'
                                                        --[[
                                                        local slash = '%\\'
                                                        if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
                                                            slash = '/'
                                                        end
                                                        local index = filename:match ('^.*()'..slash)
                                                        local SubFolder = ''
                                                        if FrstSelItm.Type == 'Knob' then
                                                            SubFolder = 'Knobs'
                                                        end

                                                        local NewFileName = r.GetResourcePath() .. 'src/Images/' ..  SubFolder .. filename:sub(index)
                                                        CopyFile(filename, NewFileName) ]]
                                                        if FrstSelItm.Type == 'Knob' then
                                                            AbsPath, FrstSelItm.ImagePath = CopyImageFile(filename,
                                                                'Knobs')
                                                        elseif FrstSelItm.Type == 'Switch' then
                                                            AbsPath, FrstSelItm.ImagePath = CopyImageFile(filename,
                                                                'Switches')
                                                        end
                                                        ToAllSelItm('Image', im.CreateImage(AbsPath))
                                                    end

                                                    --[[  AttachImage = { Path = FrstSelItm.ImagePath, DrawItemNum = It, }
                                                    if AttachImage then
                                                        local FX_Name_Short = ChangeFX_Name(FX_Name)
                                                        FrstSelItm.Image = im.CreateImage(AttachImage.Path)
                                                        im.Attach(ctx, FrstSelItm.Image)
                                                        AttachImage = nil
                                                    end ]]
                                                end
                                            end
                                            im.EndDragDropTarget(ctx)
                                        end

                                        --[[ if  im.BeginCombo( ctx, '##'..(LE.Sel_Items[1] or 'Style') , FrstSelItm.Style or 'Choose Style', nil) then
                                                local function AddStyle (Name, Style)
                                                    if im.Selectable(ctx, Name) then
                                                        for i, v in pairs (LE.Sel_Items) do
                                                            FX[FxGUID][v].Style = Style ;   im.CloseCurrentPopup(ctx)
                                                        end
                                                    end
                                                end
                                                local T = {Name ={}; Style = {}}
                                                T.Name={'Default', 'Minimalistic', 'Analog 1'}
                                                T.Style = {'Default', 'Pro C', 'Analog 1'}

                                                for i, v in ipairs(T.Name) do
                                                    AddStyle(v, T.Style[i])
                                                end

                                                im.EndCombo(ctx)

                                            end ]]


                                        if im.BeginPopup(ctx, 'Choose style window') then
                                            im.BeginDisabled(ctx)

                                            local function setItmStyle(Style, img, ImgPath)
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].Style = Style;
                                                    if img then
                                                        FX[FxGUID][v].Image = img
                                                        FX[FxGUID][v].ImagePath = ImgPath
                                                    else
                                                        FX[FxGUID][v].ImagePath = nil
                                                    end

                                                    im.CloseCurrentPopup(ctx)
                                                end
                                            end
                                            if FrstSelItm.Type == 'Slider' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Slider') then -- if all selected itms are Sliders
                                                --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize,     FrstSelItm.Lbl, 8)
                                                --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize, FrstSelItm.Lbl, 8)
                                            end
                                            if not im.ValidatePtr(StyleWinFilter, "ImGui_TextFilter*") then
                                                StyleWinFilter = im.CreateTextFilter(FilterText)
                                            end
                                            if FrstSelItm.Type == 'Knob' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Knob') then -- if all selected itms are knobs
                                                StyleWinImg = StyleWinImg or {}
                                                StyleWinImgName = StyleWinImgName or {}
                                                local function SetStyle(Name, Style, Img, ImagePath)
                                                    if im.TextFilter_PassFilter(StyleWinFilter, Name) then
                                                        im.Text(ctx, Name)
                                                        AddKnob(ctx, '##' .. FrstSelItm.Name, '', 0, 0, 1, FItm,
                                                            FX_Idx,
                                                            FrstSelItm.Num, Style, 15, 0, Disabled, 12, Lbl_Pos,
                                                            V_Pos, Img)
                                                        if HighlightHvredItem() then --if clicked on highlighted itm
                                                            setItmStyle(Style, Img, ImagePath)
                                                            im.CloseCurrentPopup(ctx)
                                                        end
                                                        AddSpacing(6)
                                                    end
                                                end


                                                im.EndDisabled(ctx)
                                                if im.TextFilter_Draw(StyleWinFilter, ctx, '##StyleWinFilterTxt', -1) then
                                                    FilterText = im.TextFilter_Get(StyleWinFilter)
                                                    im.TextFilter_Set(StyleWinFilter, FilterText)
                                                end
                                                if im.IsWindowAppearing(ctx) then
                                                    im.SetKeyboardFocusHere(ctx)
                                                end

                                                im.BeginDisabled(ctx)


                                                SetStyle('Default', Style)
                                                SetStyle('Minimalistic', 'Pro C')
                                                SetStyle('Invisible', 'Invisible')
                                                local Dir = CurrentDirectory .. 'src/Images/Knobs'
                                                if im.IsWindowAppearing(ctx) then
                                                    StyleWindowImgFiles = scandir(Dir)
                                                    if StyleWindowImgFiles then
                                                        for i, v in ipairs(StyleWindowImgFiles) do
                                                            if v ~= '.DS_Store' then
                                                                StyleWinImg[i] = im.CreateImage(Dir .. '/' .. v)
                                                                im.Attach(ctx, StyleWinImg[i])
                                                                StyleWinImgName[i] = v
                                                            end
                                                        end
                                                    end
                                                end

                                                for i, v in pairs(StyleWinImg) do
                                                    local Dir =
                                                    '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/Knobs/'
                                                    SetStyle(StyleWinImgName[i], 'Custom Image', StyleWinImg[i],
                                                        Dir .. StyleWinImgName[i])
                                                end
                                            end

                                            if FrstSelItm.Type == 'Selection' then
                                                local function SetStyle(Name, Style, Width, CustomLbl)
                                                    AddCombo(ctx, LT_Track, FX_Idx, Name .. '##' .. FrstSelItm.Name,
                                                        FrstSelItm.Num, Options, Width, Style, FxGUID,
                                                        LE.Sel_Items[1],
                                                        OptionValues, 'Options', CustomLbl)
                                                    if HighlightHvredItem() then
                                                        setItmStyle(Style)
                                                        im.CloseCurrentPopup(ctx)
                                                    end
                                                    AddSpacing(3)
                                                end
                                                local w = 60
                                                SetStyle('Default', nil, w, 'Default: ')

                                                SetStyle('up-down arrow', 'up-down arrow', w + 20, 'up-down arrow: ')
                                            end

                                            im.EndDisabled(ctx)
                                            im.EndPopup(ctx)
                                        end
                                        ---Pos  -------

                                        im.Text(ctx, 'Pos-X: '); im.SameLine(ctx)
                                        im.SetNextItemWidth(ctx, 80)
                                        local EditPosX, PosX = im.DragDouble(ctx, ' ##EditPosX' ..
                                            FxGUID .. LE.Sel_Items[1], PosX or FrstSelItm.PosX, LE.GridSize, 0,
                                            Win_W - 10,
                                            '%.0f')
                                        if EditPosX then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosX = PosX end
                                        end
                                        SL()
                                        im.Text(ctx, 'Pos-Y: '); im.SameLine(ctx)
                                        im.SetNextItemWidth(ctx, 80)
                                        local EditPosY, PosY = im.DragDouble(ctx, ' ##EditPosY' ..
                                            FxGUID .. LE.Sel_Items[1], PosY or FrstSelItm.PosY, LE.GridSize, 20, 210,
                                            '%.0f')
                                        if EditPosY then for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosY = PosY end end

                                        ---Color -----

                                        im.Text(ctx, 'Color: ')
                                        im.SameLine(ctx)
                                        ClrEdited, PrmBgClr = im.ColorEdit4(ctx, '##Clr' .. ID,
                                            FrstSelItm.BgClr or im.GetColor(ctx, im.Col_FrameBg),
                                            im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                                            im.ColorEditFlags_AlphaBar)
                                        if not FX[FxGUID][LE.Sel_Items[1]].BgClr or FX[FxGUID][LE.Sel_Items[1]] == im.GetColor(ctx, im.Col_FrameBg) then
                                            HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                                                'GetItemRect')
                                        end
                                        if ClrEdited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].BgClr = PrmBgClr end
                                        end


                                        if FrstSelItm.Type ~= 'Switch' and FrstSelItm.Type ~= 'Selection' then
                                            im.Text(ctx, 'Grab Color: ')
                                            im.SameLine(ctx)
                                            GrbClrEdited, GrbClr = im.ColorEdit4(ctx, '##GrbClr' .. ID,
                                                FrstSelItm.GrbClr or im.GetColor(ctx, im.Col_SliderGrab),
                                                im.ColorEditFlags_NoInputs|    r
                                                .ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                im.ColorEditFlags_AlphaBar)
                                            if not FX[FxGUID][LE.Sel_Items[1]].GrbClr or FX[FxGUID][LE.Sel_Items[1]].GrbClr == im.GetColor(ctx, im.Col_SliderGrab) then
                                                HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                                                    'GetItemRect')
                                            end
                                            if GrbClrEdited then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].GrbClr = GrbClr
                                                end
                                            end
                                        end

                                        if FrstSelItm.Type == 'Knob' then
                                            SL()
                                            im.Text(ctx, 'Thickness : ')
                                            SL()
                                            im.SetNextItemWidth(ctx, 40)
                                            local TD, Thick = im.DragDouble(ctx,
                                                '##EditValueFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                                FX[FxGUID][LE.Sel_Items[1] or ''].Value_Thick or 2, 0.1, 0.5, 8,
                                                '%.1f')
                                            if TD then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Value_Thick = Thick end
                                            end
                                        end


                                        if FrstSelItm.Type == 'Selection' then
                                            im.SameLine(ctx)
                                            im.Text(ctx, 'Text Color: ')
                                            im.SameLine(ctx)
                                            local DragLbl_Clr_Edited, V_Clr = im.ColorEdit4(ctx,
                                                '##V Clr' .. LE.Sel_Items[1],
                                                FX[FxGUID][LE.Sel_Items[1] or ''].V_Clr or
                                                im.GetColor(ctx, im.Col_Text),
                                                im.ColorEditFlags_NoInputs|    r
                                                .ImGui_ColorEditFlags_AlphaPreviewHalf()|im.ColorEditFlags_AlphaBar)
                                            if DragLbl_Clr_Edited then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = V_Clr end
                                            end
                                        elseif FrstSelItm.Type == 'Switch' then
                                            SL()
                                            im.Text(ctx, 'On Color: ')
                                            im.SameLine(ctx)
                                            local DragLbl_Clr_Edited, V_Clr = im.ColorEdit4(ctx,
                                                '##Switch on Clr' .. LE.Sel_Items[1],
                                                FX[FxGUID][LE.Sel_Items[1] or ''].Switch_On_Clr or 0xffffff55,
                                                im.ColorEditFlags_NoInputs| im.ColorEditFlags_AlphaPreviewHalf|
                                                im.ColorEditFlags_AlphaBar)
                                            if DragLbl_Clr_Edited then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v].Switch_On_Clr =
                                                        V_Clr
                                                end
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
                                            if im.Button(ctx, BtnTitle) then
                                                if Mods == 0 then
                                                    for i, v in pairs(LE.Sel_Items) do
                                                        if not FX[FxGUID][v][ShowCondition] then FX[FxGUID][v][ShowCondition] = true else FX[FxGUID][v][ShowCondition] = nil end
                                                        FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v]
                                                            [ConditionPrm_V] or {}
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

                                            if im.IsItemHovered(ctx) then
                                                tooltip(
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

                                                if im.Button(ctx, 'Parameter:##' .. ConditionPrm) then
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
                                                if im.IsItemHovered(ctx) then
                                                    tooltip('Click to set to last touched parameter')
                                                end


                                                im.SameLine(ctx)
                                                im.SetNextItemWidth(ctx, 80)
                                                local PrmName, PrmValue
                                                if fp[ConditionPrm] then
                                                    _, PrmName = r.TrackFX_GetParamName(LT_Track, FX_Idx,
                                                        fp[ConditionPrm])
                                                end

                                                --[[ local Edit, Cond = im.InputInt(ctx,'##' .. ConditionPrm .. LE.Sel_Items[1] .. FxGUID, FX[FxGUID][P][ConditionPrm] or 0)

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

                                                im.SameLine(ctx)
                                                im.Text(ctx, (PrmName or ''))
                                                im.AlignTextToFramePadding(ctx)
                                                if PrmName then
                                                    im.Text(ctx, 'is at Value:')

                                                    im.SameLine(ctx)
                                                    local FP = FX[FxGUID][LE.Sel_Items[1]] ---@class FX_P
                                                    local CP = FX[FxGUID][P][ConditionPrm]
                                                    --!!!!!! LE.Sel_Items[1] = Fx_P -1 !!!!!! --
                                                    Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx,
                                                        'ConditionPrm' ..
                                                        FP.ConditionPrm .. (PrmName or '') .. '1## CP',
                                                        FX[FxGUID][P][ConditionPrm] or 0,
                                                        FX[FxGUID][PID].ManualValuesFormat or 'Get Options', -R_ofs,
                                                        Style,
                                                        FxGUID, PID, FX[FxGUID][PID].ManualValues,
                                                        FX[FxGUID][P][ConditionPrm_V][1] or 'Unassigned', nil,
                                                        'No Lbl')

                                                    if Value_Selected then
                                                        for i, v in pairs(LE.Sel_Items) do
                                                            FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v]
                                                                [ConditionPrm_V] or
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
                                                                    im.Text(ctx, 'or at value:')
                                                                    im.SameLine(ctx)
                                                                    local Value_Selected, V_Formatted = AddCombo(ctx,
                                                                        LT_Track,
                                                                        FX_Idx, 'CondPrmV' .. (PrmName or '') .. v ..
                                                                        ConditionPrm,
                                                                        FX[FxGUID][P][ConditionPrm] or 0,
                                                                        FX[FxGUID][PID].ManualValuesFormat or
                                                                        'Get Options',
                                                                        -R_ofs, Style, FxGUID, PID,
                                                                        FX[FxGUID][PID].ManualValues,
                                                                        v, nil, 'No Lbl')
                                                                    if Value_Selected then
                                                                        for I, v in pairs(LE.Sel_Items) do
                                                                            FX[FxGUID][v][ConditionPrm_V][i] =
                                                                                V_Formatted
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
                                                    if im.Button(ctx, ' + or at value:##' .. ConditionPrm) then
                                                        FX[FxGUID][P][ConditionPrm_V] = FX[FxGUID][P]
                                                            [ConditionPrm_V] or {}
                                                        table.insert(FX[FxGUID][P][ConditionPrm_V], '')
                                                    end
                                                    im.SameLine(ctx)
                                                    im.SetNextItemWidth(ctx, 120)
                                                    if im.BeginCombo(ctx, '##- delete value ' .. ConditionPrm, '- delete value', im.ComboFlags_NoArrowButton) then
                                                        for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                            if im.Selectable(ctx, v or '##', i) then
                                                                table.remove(FX[FxGUID][P][ConditionPrm_V], i)
                                                                if not FX[FxGUID][P][ConditionPrm_V][1] then
                                                                    FX[FxGUID][P][ConditionPrm] = nil
                                                                end
                                                            end
                                                        end
                                                        im.EndCombo(ctx)
                                                    end
                                                end
                                            end
                                        end



                                        if im.TreeNode(ctx, 'Conditional Parameter') then
                                            Condition('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V',
                                                'ConditionPrm_V_Norm',
                                                'Show only if:', 'ShowCondition')
                                            if FrstSelItm.ConditionPrm then
                                                Condition('ConditionPrm2', 'ConditionPrm_PID2',
                                                    'ConditionPrm_V2', 'ConditionPrm_V_Norm2', 'And if:',
                                                    'ShowCondition2')
                                            end
                                            if FrstSelItm.ConditionPrm2 then
                                                Condition('ConditionPrm3', 'ConditionPrm_PID3',
                                                    'ConditionPrm_V3', 'ConditionPrm_V_Norm3', 'And if:',
                                                    'ShowCondition3')
                                            end
                                            if FrstSelItm.ConditionPrm3 then
                                                Condition('ConditionPrm4', 'ConditionPrm_PID4',
                                                    'ConditionPrm_V4', 'ConditionPrm_V_Norm4', 'And if:',
                                                    'ShowCondition4')
                                            end
                                            if FrstSelItm.ConditionPrm4 then
                                                Condition('ConditionPrm5', 'ConditionPrm_PID5',
                                                    'ConditionPrm_V5', 'ConditionPrm_V_Norm5', 'And if:',
                                                    'ShowCondition5')
                                            end
                                            im.TreePop(ctx)
                                        end





                                        if im.TreeNode(ctx, 'Attach Drawing') then
                                            FrstSelItm.Draw = FrstSelItm.Draw or {}
                                            if RemoveDraw then
                                                table.remove(FrstSelItm.Draw, RemoveDraw)
                                                RemoveDraw = nil
                                            end

                                            for i = 1, #FrstSelItm.Draw, 1 do
                                                im.AlignTextToFramePadding(ctx)
                                                local rv = im.TreeNode(ctx, 'Drawing ' .. i)

                                                SL()
                                                im.Text(ctx, ' Type : ')
                                                SL()
                                                im.SetNextItemWidth(ctx, 100)


                                                local D = FrstSelItm.Draw[i]
                                                local LBL = FxGUID .. LE.Sel_Items[1] .. i
                                                local H = Glob.Height
                                                local W = Win_W
                                                if im.BeginCombo(ctx, '## Combo type' .. LBL, D.Type or '', im.ComboFlags_NoArrowButton) then
                                                    local function AddOption(str)
                                                        if im.Selectable(ctx, str, false) then
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
                                                    AddOption('Gain Reduction Text')


                                                    im.EndCombo(ctx)
                                                end

                                                SL()
                                                if im.Button(ctx, 'Delete##' .. i) then
                                                    RemoveDraw = i
                                                end



                                                if rv then
                                                    local function AddProp(ShownName, Name, width, sl, defaultV,
                                                                           stepSize,
                                                                           min, max, format)
                                                        if ShownName then
                                                            im.Text(ctx, ShownName)
                                                            SL()
                                                        end
                                                        if width then im.SetNextItemWidth(ctx, width) end
                                                        local FORMAT = format
                                                        if not D[Name] and not defaultV then FORMAT = '' end

                                                        local rv, V = im.DragDouble(ctx, '##' .. Name .. LBL,
                                                            D[Name] or defaultV, stepSize or LE.GridSize, min or -W,
                                                            max or W - 10, FORMAT)

                                                        if rv then D[Name] = V end
                                                        if sl then SL() end
                                                        return im.IsItemActive(ctx)
                                                    end

                                                    local BL_Width = { 'Knob Pointer', 'Knob Range',
                                                        'Gain Reduction Text' }
                                                    local BL_Height = { 'Knob Pointer', 'Knob Range', 'Circle',
                                                        'Circle Filled', 'Knob Circle', 'Knob Image',
                                                        'Gain Reduction Text' }
                                                    local Thick = { 'Knob Pointer', 'Line', 'Rect', 'Circle' }
                                                    local Round = { 'Rect', 'Rect Filled' }
                                                    local Gap = { 'Circle', 'Circle Filled', 'Knob Range' }
                                                    local BL_XYGap = { 'Knob Pointer', 'Knob Range', 'Knob Circle',
                                                        'Knob Image' }
                                                    local RadiusInOut = { 'Knob Pointer', 'Knob Range' }
                                                    local Radius = { 'Knob Circle', 'Knob Image' }
                                                    local BL_Repeat = { 'Knob Range', 'Knob Circle', 'Knob Image',
                                                        'Knob Pointer', 'Gain Reduction Text' }
                                                    local GR_Text = { 'Gain Reduction Text' }


                                                    local X_Gap_Shown_Name = 'X Gap:'

                                                    local DefW, DefH

                                                    local WidthLBL, WidthStepSize = 'Width: ', LE.GridSize


                                                    if D.Type == 'Image' or D.Type == 'Knob Image' then
                                                        if im.BeginChild(ctx, '##drop_files', -R_ofs, 25) then
                                                            if D.Image then
                                                                if TrashIcon(13, 'Image Delete', ClrBG, ClrTint) then
                                                                    D.Image, D.FilePath = nil
                                                                end
                                                                SL()
                                                            end
                                                            if not D.FilePath then
                                                                im.Text(ctx, 'Drag and drop files here...')
                                                            else
                                                                im.Text(ctx, D.FilePath)
                                                            end
                                                            if D.FilePath then
                                                                im.Bullet(ctx)
                                                                im.TextWrapped(ctx, D.FilePath)
                                                            end
                                                            im.EndChild(ctx)
                                                        end

                                                        if im.BeginDragDropTarget(ctx) then
                                                            local rv, count = im.AcceptDragDropPayloadFiles(ctx)
                                                            if rv then
                                                                for i = 0, count - 1 do
                                                                    local rv, filename = im.GetDragDropPayloadFile(
                                                                        ctx,
                                                                        i)


                                                                    path, D.FilePath = CopyImageFile(filename,
                                                                        'Attached Drawings')


                                                                    D.Image = im.CreateImage(path)
                                                                    im.Attach(ctx, D.Image)
                                                                end
                                                            end
                                                            im.EndDragDropTarget(ctx)
                                                        end
                                                    end

                                                    local ClrFLG = im.ColorEditFlags_NoInputs +
                                                        im.ColorEditFlags_AlphaPreviewHalf +
                                                        im.ColorEditFlags_NoLabel + im.ColorEditFlags_AlphaBar

                                                    im.AlignTextToFramePadding(ctx)

                                                    local flags = im.TableFlags_SizingStretchSame |
                                                        im.TableFlags_Resizable |
                                                        im.TableFlags_BordersOuter |
                                                        im.TableFlags_BordersV |
                                                        im.TableFlags_ContextMenuInBody|
                                                        im.TableFlags_RowBg



                                                    if im.BeginTable(ctx, 'Attached Drawing Properties', 3, flags, -R_ofs) then
                                                        local function SetRowName(str, notTAB, TAB)
                                                            im.TableSetColumnIndex(ctx, 0)
                                                            if TAB then
                                                                if FindExactStringInTable(TAB, D.Type) then
                                                                    im.Text(ctx, str)
                                                                    return true
                                                                end
                                                            elseif notTAB then
                                                                if not FindExactStringInTable(notTAB, D.Type) then
                                                                    im.Text(ctx, str)
                                                                    return true
                                                                end
                                                            else
                                                                im.Text(ctx, str)
                                                            end
                                                        end


                                                        --[[ if im.IsItemHovered(ctx) then
                                                            tooltip('How much the value is affected by parameter"\"s value ')
                                                        end ]]

                                                        local function AddVal(Name, defaultV, stepSize, min, max,
                                                                              format,
                                                                              NextRow)
                                                            local Column = 1
                                                            if Name:find('_VA') then Column = 2 end
                                                            im.TableSetColumnIndex(ctx, Column)

                                                            im.PushItemWidth(ctx, -FLT_MIN)

                                                            local FORMAT = format
                                                            if not D[Name .. '_GR'] and not D[Name] and not defaultV then
                                                                FORMAT =
                                                                ''
                                                            end

                                                            local rv, V = im.DragDouble(ctx, '##' .. Name .. LBL,
                                                                D[Name .. '_GR'] or D[Name] or defaultV,
                                                                stepSize or LE.GridSize, min or -W,
                                                                max or W - 10, FORMAT)

                                                            if rv and not D[Name .. '_GR'] then
                                                                D[Name] = V
                                                            elseif rv and D[Name .. '_GR'] then
                                                                D[Name .. '_GR'] = V; D[Name] = nil
                                                            end

                                                            -- if want to show preview use this.
                                                            --if im.IsItemActive(ctx) then FrstSelItm.ShowPreview = FrstSelItm.Num end



                                                            if FrstSelItm.ShowPreview and im.IsItemDeactivated(ctx) then FrstSelItm.ShowPreview = nil end

                                                            im.PopItemWidth(ctx)
                                                            if Name:find('_VA') then
                                                                if im.IsItemClicked(ctx, 1) and Mods == Ctrl then
                                                                    im.OpenPopup(ctx, 'Value afftect ' .. Name)
                                                                end
                                                            end

                                                            if im.BeginPopup(ctx, 'Value afftect ' .. Name) then
                                                                local rv, GR = r.TrackFX_GetNamedConfigParm(LT_Track,
                                                                    FX_Idx,
                                                                    'GainReduction_dB')
                                                                if not rv then im.BeginDisabled(ctx) end

                                                                if D[Name .. '_GR'] then D.check = true end
                                                                Check, D.check = im.Checkbox(ctx,
                                                                    'Affected by Gain Reduction', D.check)
                                                                if Check then
                                                                    if D[Name .. '_GR'] then D[Name .. '_GR'] = nil else D[Name .. '_GR'] = 0 end
                                                                end
                                                                if D.VA_by_GR then

                                                                end
                                                                if not rv then im.EndDisabled(ctx) end
                                                                im.EndPopup(ctx)
                                                            end

                                                            if Name:find('_VA') or NextRow then im.TableNextRow(ctx) end

                                                            return im.IsItemActive(ctx)
                                                        end

                                                        local function AddRatio(Name)
                                                            im.TableSetColumnIndex(ctx, 3)
                                                            im.PushItemWidth(ctx, -FLT_MIN)
                                                            local v = (D[Name] or 1) / (FrstSelItm.Sldr_W or 160)
                                                            local rv, V = im.DragDouble(ctx, '##' .. Name .. ' ratio',
                                                                v,
                                                                0.001, 0, 100, '%.2f')
                                                            im.TableNextRow(ctx)
                                                            if rv then return rv, V * (FrstSelItm.Sldr_W or 160) end
                                                        end

                                                        im.TableSetupColumn(ctx, '##')
                                                        im.TableSetupColumn(ctx, 'Values')
                                                        im.TableSetupColumn(ctx, 'Affected Amount')
                                                        im.TableNextRow(ctx, im.TableRowFlags_Headers)





                                                        im.TableHeadersRow(ctx)

                                                        local Sz = FrstSelItm.Sldr_W or 160

                                                        im.TableNextRow(ctx)

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
                                                        if D.Type ~= 'Gain Reduction Text' then
                                                            if SetRowName('X Gap', BL_XYGap) then
                                                                AddVal('X_Gap', 0, 0.2, 0, 300, '%.1f')
                                                                AddVal('X_Gap_VA', 0, 0.01, -1, 1)
                                                            end
                                                            if SetRowName('Y Gap', BL_XYGap) then
                                                                AddVal('Y_Gap', 0, 0.2, 0, 300, '%.1f')
                                                                AddVal('Y_Gap_VA', 0, 0.01, -1, 1)
                                                            end
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
                                                            AddVal('Round', 0, 0.1, 0, 100, '%.1f', true)
                                                        end
                                                        --[[ if SetRowName('Font Size',GR_Text ) then

                                                        end ]]
                                                        SetRowName('Color')
                                                        im.TableSetColumnIndex(ctx, 1)

                                                        local rv, Clr = im.ColorEdit4(ctx, 'Color' .. LBL,
                                                            D.Clr or 0xffffffff, ClrFLG)
                                                        if rv then D.Clr = Clr end

                                                        im.TableSetColumnIndex(ctx, 2)
                                                        local rv, Clr_VA = im.ColorEdit4(ctx, 'Color_VA' .. LBL,
                                                            D.Clr_VA or 0xffffffff, ClrFLG)
                                                        if rv then D.Clr_VA = Clr_VA end


                                                        im.TableNextRow(ctx)

                                                        if D.Repeat and D.Repeat ~= 0 then
                                                            SetRowName('Last Repeat\'s Color')
                                                            im.TableSetColumnIndex(ctx, 1)

                                                            local rv, Clr = im.ColorEdit4(ctx, 'Repeat Color' .. LBL,
                                                                D.RPT_Clr or 0xffffffff, ClrFLG)
                                                            if rv then D.RPT_Clr = Clr end
                                                            im.TableNextRow(ctx)
                                                        end


                                                        im.EndTable(ctx)
                                                    end


                                                    im.TreePop(ctx)
                                                end
                                            end




                                            if im.Button(ctx, 'attach a new drawing') then
                                                table.insert(FrstSelItm.Draw, {})
                                            end


                                            im.TreePop(ctx)
                                        end

                                        im.PopStyleColor(ctx)
                                    end -------------------- End of Repeat for every selected item
                                    if LE.SelectedItem == 'Title' then
                                        im.PushStyleColor(ctx, im.Col_FrameBgActive, 0x66666688)

                                        im.Text(ctx, 'Edge Round:')
                                        im.SameLine(ctx)
                                        Edited, FX[FxGUID].Round = im.DragDouble(ctx, '##' .. FxGUID .. 'Round',
                                            FX[FxGUID].Round, 0.01, 0, 40, '%.2f')

                                        im.Text(ctx, 'Grab Round:')
                                        im.SameLine(ctx)
                                        Edited, FX[FxGUID].GrbRound = im.DragDouble(ctx, '##' .. FxGUID .. 'GrbRound',
                                            FX[FxGUID].GrbRound, 0.01, 0, 40, '%.2f')

                                        im.Text(ctx, 'Background Color:')
                                        im.SameLine(ctx)
                                        _, FX[FxGUID].BgClr = im.ColorEdit4(ctx, '##' .. FxGUID .. 'BgClr',
                                            FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff,
                                            im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                                            im.ColorEditFlags_AlphaBar)
                                        if FX[FxGUID].BgClr == im.GetColor(ctx, im.Col_FrameBg) then
                                            HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 1, 1,
                                                'GetItemRect')
                                        end

                                        im.Text(ctx, 'FX Title Color:')
                                        im.SameLine(ctx)
                                        _, FX[FxGUID].TitleClr = im.ColorEdit4(ctx, '##' .. FxGUID .. 'Title Clr',
                                            FX[FxGUID].TitleClr or 0x22222233,
                                            im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|
                                            im.ColorEditFlags_AlphaBar)

                                        im.Text(ctx, 'Custom Title:')
                                        im.SameLine(ctx)
                                        local _, CustomTitle = im.InputText(ctx, '##CustomTitle' .. FxGUID,
                                            FX[FxGUID].CustomTitle or FX_Name)
                                        if im.IsItemDeactivatedAfterEdit(ctx) then
                                            FX[FxGUID].CustomTitle = CustomTitle
                                        end

                                        im.PopStyleColor(ctx)
                                    end








                                    if im.BeginPopupModal(ctx, 'Save Editing?') then
                                        SaveEditingPopupModal = true
                                        im.Text(ctx, 'Would you like to save the editings?')
                                        if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, im.Key_N) then
                                            RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                                            im.CloseCurrentPopup(ctx)
                                            FX.LayEdit = nil
                                            LE.SelectedItem = nil
                                            CloseLayEdit = true
                                        end
                                        im.SameLine(ctx)

                                        if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, im.Key_Y) then
                                            SaveLayoutEditings(FX_Name, FX_Idx, FxGUID)
                                            im.CloseCurrentPopup(ctx)
                                            FX.LayEdit = nil
                                            LE.SelectedItem = nil
                                            CloseLayEdit = true
                                        end
                                        im.SameLine(ctx)

                                        if im.Button(ctx, '(c) Cancel') or im.IsKeyPressed(ctx, im.Key_C) or im.IsKeyPressed(ctx, im.Key_Escape) then
                                            im.CloseCurrentPopup(ctx)
                                        end



                                        im.EndPopup(ctx)
                                    end


                                    local PalletteW = 25
                                    local Pad = 10
                                    if not CloseLayEdit then
                                        w, h = im.GetWindowSize(ctx)
                                        im.SetCursorPos(ctx, w - PalletteW - Pad, PalletteW + Pad)
                                    end




                                    for Pal = 1, NumOfColumns or 1, 1 do
                                        if not CloseLayEdit and im.BeginChild(ctx, 'Color Palette' .. Pal, PalletteW, h - PalletteW - Pad * 2,nil, im.WindowFlags_NoScrollbar) then
                                            local NumOfPaletteClr = 9

                                            for i, v in ipairs(FX[FxGUID]) do
                                                local function CheckClr(Clr)
                                                    if Clr and not im.IsPopupOpen(ctx, '', im.PopupFlags_AnyPopupId) then
                                                        if not tablefind(ClrPallet, Clr) and ClrPallet then
                                                            local R, G, B, A = im.ColorConvertU32ToDouble4(Clr)
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
                                                        if Clr and not im.IsPopupOpen(ctx, '', im.PopupFlags_AnyPopupId) then
                                                            if not tablefind(ClrPallet, Clr) and ClrPallet then
                                                                table.insert(ClrPallet, Clr)
                                                            end
                                                        end
                                                    end
                                                end
                                            end

                                            for i, v in ipairs(ClrPallet) do
                                                clrpick, LblColor1 = im.ColorEdit4(ctx, '##ClrPalette' .. Pal ..
                                                    i .. FxGUID, v,
                                                    im.ColorEditFlags_NoInputs|
                                                    im.ColorEditFlags_AlphaPreviewHalf|
                                                    im.ColorEditFlags_AlphaBar)
                                                if im.IsItemClicked(ctx) and Mods == Alt then
                                                    table.remove(ClrPallet, tablefind(v))
                                                end
                                            end


                                            --[[ for i=1, NumOfPaletteClr , 1 do
                                                PaletteClr= 'PaletteClr'..Pal..i..FxGUID
                                                local DefaultClr        = im.ColorConvertHSVtoRGB((i-0.5)*(NumOfColumns or 1) / 7.0, 0.5, 0.5, 1)
                                                clrpick,  _G[PaletteClr] = im.ColorEdit4( ctx, '##ClrPalette'..Pal..i..FxGUID,  _G[PaletteClr] or  DefaultClr , im.ColorEditFlags_NoInputs|    im.ColorEditFlags_AlphaPreviewHalf|im.ColorEditFlags_AlphaBar)
                                                if im.IsItemDeactivatedAfterEdit(ctx) and i==NumOfPaletteClr  then NumOfColumns=(NumOfColumns or 1 )   +1    end
                                                if im.BeginDragDropTarget( ctx) then HighlightSelectedItem(0x00000000 ,0xffffffff, 0, L,T,R,B,h,w, 1, 1,'GetItemRect', 'Foreground') end
                                            end  ]]
                                            im.EndChild(ctx)
                                        end
                                        if NumOfColumns or 1 > 1 then
                                            for i = 1, NumOfColumns, 1 do im.SameLine(ctx, nil, 0) end
                                        end
                                    end





                                    if im.BeginPopupModal(ctx, 'Save Draw Editing?') then
                                        im.Text(ctx, 'Would you like to save the Drawings?')
                                        if im.Button(ctx, '(n) No') then
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
                                            im.CloseCurrentPopup(ctx)
                                            Draw.DrawMode[FxGUID] = nil
                                        end
                                        im.SameLine(ctx)

                                        if im.Button(ctx, '(y) Yes') then
                                            SaveDrawings(FX_Idx, FxGUID)
                                            im.CloseCurrentPopup(ctx)
                                            Draw.DrawMode[FxGUID] = nil
                                        end
                                        im.EndPopup(ctx)
                                    end



                                    if im.IsKeyPressed(ctx, im.Key_A) and (Mods == Apl or Mods == Alt) then
                                        for Fx_P = 1, #FX[FxGUID] or 0, 1 do table.insert(LE.Sel_Items, Fx_P) end
                                    end


                                    im.End(ctx)
                                    if CloseLayEdit then
                                        FX.LayEdit = nil
                                        Draw.DrawMode[FxGUID] = nil
                                    end
                                end





                                im.SameLine(ctx, nil, 0)
                                --im.PushStyleVar( ctx,im.StyleVar_WindowPadding, 0,0)
                                --im.PushStyleColor(ctx, im.Col_DragDropTarget, 0x00000000)



                                --if ctrl+A or Command+A is pressed


                                --im.EndTooltip(ctx)

                                -- im.PopStyleVar(ctx)
                                --im.PopStyleColor(ctx,2 )
                                PopClr(ctx, 2)
                            end
                        end

                        Layout_Edit()
                    end


                    if --[[FX Layer Window ]] string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then --!!!!  FX Layer Window
                        if not FX[FxGUID].Collapse then
                            FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                            r.TrackFX_Show(LT_Track, FX_Idx, 2)

                            im.SameLine(ctx, nil, 0)
                            --Gives the index of the specific MixRack
                            im.PushStyleColor(ctx, im.Col_FrameBg,
                                FX_Layer_Container_BG or BGColor_FXLayeringWindow)
                            FXLayeringWin_X = 240; local Pad = 3
                            if im.BeginChild(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, FXLayeringWin_X + Pad, 220, im.WindowFlags_NoScrollbar) then
                                local WDL = im.GetWindowDrawList(ctx)
                                FXLayerFrame_PosX_L, FXLayerFrame_PosY_T = im.GetItemRectMin(ctx)
                                FXLayerFrame_PosX_R, FXLayerFrame_PosY_B = im.GetItemRectMax(ctx); FXLayerFrame_PosY_B =
                                    FXLayerFrame_PosY_B + 220

                                local clrhdrhvr = im.GetColor(ctx, im.Col_ButtonHovered)
                                local clrhdrAct = im.GetColor(ctx, im.Col_ButtonActive)

                                im.PushStyleColor(ctx, im.Col_HeaderHovered, clrhdrhvr)
                                local clrhdr = im.GetColor(ctx, im.Col_Button)
                                im.PushStyleColor(ctx, im.Col_TableHeaderBg, clrhdr)

                                im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, 0)


                                im.BeginTable(ctx, '##FX Layer' .. FX_Idx, 1)
                                im.TableHeadersRow(ctx)


                                if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                                    DragFX_ID = FX_Idx
                                    im.SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                                    im.EndDragDropSource(ctx)
                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end
                                if im.IsItemClicked(ctx, 0) and Mods == Alt then
                                    FX[FxGUID].DeleteFXLayer = true
                                elseif im.IsItemClicked(ctx, 1) then
                                    FX[FxGUID].Collapse = true
                                    FX[FxGUID].CollapseWidth = 27
                                elseif im.IsItemClicked(ctx) and Mods == Shift then
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
                                    if LBtnClickCount == 2 and im.IsItemActivated(ctx) then
                                        FX[FxGUID].RenameFXLayering = true
                                    elseif im.IsItemClicked(ctx, 1) and Mods == Alt then
                                        BlinkFX = ToggleCollapseAll(FX_Idx)
                                    end
                                end


                                im.SameLine(ctx)
                                im.AlignTextToFramePadding(ctx)
                                if not FX[FxGUID].RenameFXLayering then
                                    im.SetNextItemWidth(ctx, 10)
                                    local TitleShort
                                    if string.len(FX[FxGUID].ContainerTitle or '') > 27 then
                                        TitleShort = string.sub(FX[FxGUID].ContainerTitle, 1, 27)
                                    end
                                    im.Text(ctx, TitleShort or FX[FxGUID].ContainerTitle or 'FX Layering')
                                else -- If Renaming
                                    local Flag
                                    im.SetNextItemWidth(ctx, 180)
                                    if FX[FxGUID].ContainerTitle == 'FX Layering' then
                                        Flag = r
                                            .ImGui_InputTextFlags_AutoSelectAll()
                                    end
                                    _, FX[FxGUID].ContainerTitle = im.InputText(ctx, '##' .. FxGUID,
                                        FX[FxGUID].ContainerTitle or 'FX Layering', Flag)

                                    im.SetItemDefaultFocus(ctx)
                                    im.SetKeyboardFocusHere(ctx, -1)

                                    if im.IsItemDeactivated(ctx) then
                                        FX[FxGUID].RenameFXLayering = nil
                                        r.SetProjExtState(0, 'FX Devices - ', 'FX' .. FxGUID ..
                                            'FX Layer Container Title ', FX[FxGUID].ContainerTitle)
                                    end
                                end

                                --im.PushStyleColor(ctx,im.Col_Button, 0xffffff10)

                                im.SameLine(ctx, FXLayeringWin_X - 25, 0)
                                im.AlignTextToFramePadding(ctx)
                                if not FX[FxGUID].SumMode then
                                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)
                                end
                                local Lbl
                                if FX[FxGUID].SumMode == 0 then Lbl = 'Avg' else Lbl = 'Sum' end
                                if im.Button(ctx, (Lbl or '') .. '##FX Lyr Mode' .. FxGUID, 30, im.GetTextLineHeight(ctx)) then
                                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)

                                    if FX[FxGUID].SumMode == 0 then
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 1)
                                        FX[FxGUID].SumMode = 1
                                    else
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 0)
                                        FX[FxGUID].SumMode = 0
                                    end
                                end

                                --im.PopStyleColor(ctx)
                                im.PopStyleVar(ctx)

                                im.EndTable(ctx)
                                im.PopStyleColor(ctx, 2) --Header Clr
                                im.PushStyleVar(ctx, im.StyleVar_FrameRounding, 0)
                                --im.PushStyleColor(ctx,im.Col_FrameBgActive, 0x99999999)
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



                                im.PushStyleVar(ctx, im.StyleVar_ItemSpacing, 1, Spacing)
                                im.PushStyleVar(ctx, im.StyleVar_FramePadding, 4, LineH)

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

                                    local CurY = im.GetCursorPosY(ctx)
                                    if FX[FxGUID][Fx_P] then
                                        LyrCurX, LyrCurY = im.GetCursorScreenPos(ctx)

                                        if Lyr.Rename[LyrID .. FxGUID] ~= true and Fx_P then
                                            --im.ProgressBar(ctx, Lyr.ProgBarVal[LyrID..FxGUID], FXLayeringWin_X-60, 30, '##Layer'.. LyrID)
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
                                            --[[ im.PushStyleVar(ctx, im.StyleVar_FramePadding, 0, BtnSizeManual/3) ]]
                                            --[[ im.PushStyleColor(ctx, im.Col_FrameBg, getClr(im.Col_Button)) ]]
                                            SliderStyle = nil; Rounding = 0
                                            local CurY = im.GetCursorPosY(ctx)
                                            AddDrag(ctx, Label, labeltoShow, p_value, 0, 1, Fx_P, FX_Idx, P_Num,
                                                'FX Layering', FXLayeringWin_X - BtnSizeManual * 3 - 23,
                                                Inner_Spacing,
                                                Disable, Lbl_Clickable, 'Bottom', 'Bottom', DragDir, 'NoInput')
                                            --[[ im.PopStyleColor(ctx)  im.PopStyleVar(ctx) ]]

                                            local L, T = im.GetItemRectMin(ctx); B = T + BtnSizeManual
                                            BtnSize = B - T
                                            im.SameLine(ctx, nil, 10)
                                            im.SetCursorPosY(ctx, CurY)

                                            if Lyr.Selected[FXGUID_RackMixer] == LyrID then
                                                local R = L + FXLayeringWin_X
                                                im.DrawList_AddLine(WDL, L, T - 2, R - 2 + Pad, T - 2, 0x99999999)
                                                im.DrawList_AddLine(WDL, L, B, R - 2 + Pad, B, 0x99999999)
                                                im.DrawList_AddRectFilled(WDL, L, T - 2, R + Pad, B, 0xffffff09)
                                                FX[FxGUID].TheresFXinLyr = nil
                                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]] then
                                                        if FX[FXGUID[FX_Idx]].inWhichLyr == LyrID and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                            im.DrawList_AddLine(WDL, R - 2 + Pad, T, R - 2 + Pad,
                                                                FXLayerFrame_PosY_T, 0x99999999)
                                                            im.DrawList_AddLine(WDL, R - 2 + Pad, B, R - 2 + Pad,
                                                                FXLayerFrame_PosY_B, 0x99999999)
                                                            FX[FxGUID].TheresFXinLyr = true
                                                        end
                                                    end
                                                end
                                                if not FX[FxGUID].TheresFXinLyr then
                                                    im.DrawList_AddLine(WDL, R, T, R, B, 0x99999999)
                                                else
                                                end
                                            end

                                            if im.IsItemClicked(ctx) and Mods == Alt then
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
                                                    FX[FxGUID].ActiveLyrCount = math.max(
                                                        FX[FxGUID].ActiveLyrCount - 1, 1)
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1), 0) -- turn channel power off
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        1 + (5 * (LyrID - 1) + 1),
                                                        0.5) -- set pan to center
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        1 + (5 * (LyrID - 1)),
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
                                                    im.SetNextWindowPos(ctx,
                                                        VP.x + VP.w / 2 - Modalw / 2,
                                                        VP.y + VP.h / 2 - Modalh / 2)
                                                    im.SetNextWindowSize(ctx, Modalw, Modalh)
                                                    im.OpenPopup(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' ..
                                                        FxGUID)
                                                end
                                            elseif im.IsItemClicked(ctx) and LBtnDC then
                                                FX[FxGUID][Fx_P].V = 0.5
                                                local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num,
                                                    0.5)
                                            elseif im.IsItemClicked(ctx) and Mods == Ctrl and not FXLayerRenaming then
                                                Lyr.Rename[LyrID .. FxGUID] = true
                                            elseif im.IsItemClicked(ctx) and Mods == 0 then
                                                Lyr.Selected[FXGUID_RackMixer] = LyrID
                                            end
                                        elseif Lyr.Rename[LyrID .. FxGUID] == true then
                                            for i = 1, 8, 1 do -- set all other layer's rename to false
                                                if LyrID ~= i then Lyr.Rename[i .. FxGUID] = false end
                                            end
                                            FXLayerRenaming = true
                                            im.SetKeyboardFocusHere(ctx)
                                            im.SetNextItemWidth(ctx, FXLayeringWin_X - BtnSizeManual * 3 - 23)
                                            local ID = FX[FxGUID].LyrID[LyrID]
                                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}
                                            _, FX[FxGUID].LyrTitle[ID] = im.InputText(ctx, '##' .. LyrID,
                                                FX[FxGUID].LyrTitle[ID])

                                            if im.IsItemDeactivatedAfterEdit(ctx) then
                                                Lyr.Rename[LyrID .. FxGUID] = false
                                                FXLayerRenaming = nil
                                                r.SetProjExtState(0, 'FX Devices - ', 'FX' ..
                                                    FxGUID .. 'Layer Title ' .. LyrID, FX[FxGUID].LyrTitle[ID])
                                            elseif im.IsItemDeactivated(ctx) then
                                                Lyr.Rename[LyrID .. FxGUID] = false
                                                FXLayerRenaming = nil
                                            end
                                            SL(nil, 10)
                                        end

                                        ------------ Confirm delete layer ---------------------
                                        if im.BeginPopupModal(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' .. FxGUID, true, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                                            im.Text(ctx, 'Delete all FXs in layer ' .. LyrID .. '?')
                                            im.Text(ctx, ' ')

                                            if im.Button(ctx, '(n) No (or Esc)') or im.IsKeyPressed(ctx, 78) or im.IsKeyPressed(ctx, 27) then
                                                im.CloseCurrentPopup(ctx)
                                            end
                                            im.SameLine(ctx, nil, 20)
                                            if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, 89) then
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
                                            im.EndPopup(ctx)
                                        end




                                        ProgBar_Pos_L, ProgBar_PosY_T = im.GetItemRectMin(ctx)
                                        ProgBar_Pos_R, ProgBar_PosY_B = im.GetItemRectMax(ctx)





                                        if Lyr.Selected[FXGUID_RackMixer] == LyrID and Lyr.Rename[LyrID .. FxGUID] ~= true then
                                            im.DrawList_AddRect(drawlist, ProgBar_Pos_L, ProgBar_PosY_T,
                                                FXLayerFrame_PosX_R, ProgBar_PosY_B, 0xffffffff)
                                        end

                                        drawlistInFXLayering = im.GetForegroundDrawList(ctx)


                                        if im.BeginDragDropTarget(ctx) then
                                            dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag') --

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
                                            if Payload_Type == 'DND ADD FX' then
                                                dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX') --
                                                if dropped then
                                                    r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx)

                                                    DropFXtoLayer(FX_Idx, LyrID)
                                                end
                                            end

                                            HighlightSelectedItem(0x88888844, 0xffffffff, 0, L, T, R, B, h, w,
                                                H_OutlineSc, V_OutlineSc, 'GetItemRect')
                                            im.EndDragDropTarget(ctx)
                                        end

                                        local Label = '##Pan' .. LyrID .. FxGUID

                                        local P_Num = 1 + (5 * (LyrID - 1) + 1)
                                        local Fx_P_Knob = LyrID * 2
                                        local Label = '## Pan' .. LyrID .. FxGUID
                                        local p_value_Knob = FX[FxGUID][Fx_P_Knob].V
                                        local labeltoShow = HowManyFXinLyr



                                        AddKnob(ctx, Label, labeltoShow, p_value_Knob, 0, 1, Fx_P_Knob, FX_Idx, P_Num,
                                            'FX Layering', BtnSizeManual / 2, 0, Disabled, 9, 'Within', 'None')
                                        im.SameLine(ctx, nil, 10)

                                        if LBtnDC and im.IsItemClicked(ctx, 0) then
                                            FX[FxGUID][Fx_P_Knob].V = 0.5
                                            local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0.5)
                                        end

                                        im.SetCursorPosY(ctx, CurY)

                                        if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                            local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                                            im.PushStyleColor(ctx, im.Col_Button, Clr)
                                            im.PushStyleColor(ctx, im.Col_ButtonActive, Act)
                                            im.PushStyleColor(ctx, im.Col_ButtonHovered, Hvr)

                                            SoloBtnClrPop = 3
                                        end

                                        ClickOnSolo = im.Button(ctx, 'S##' .. LyrID, BtnSizeManual, BtnSizeManual) -- ==  lyr solo

                                        if Lyr.Solo[LyrID .. FxGUID] == 1 then im.PopStyleColor(ctx, SoloBtnClrPop) end


                                        if ClickOnSolo then
                                            Lyr.Solo[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                                LT_Track,
                                                FX_Idx, 4 + (5 * (LyrID - 1)))
                                            if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                                Lyr.Solo[LyrID .. FxGUID] = 0
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                    4 + (5 * (LyrID - 1)),
                                                    Lyr.Solo[LyrID .. FxGUID])
                                                im.PushStyleColor(ctx, im.Col_Button, 0x9ed9d3ff)
                                                im.PopStyleColor(ctx)
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

                                        im.SameLine(ctx, nil, 3)
                                        im.SetCursorPosY(ctx, CurY)
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                                            local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                                            im.PushStyleColor(ctx, im.Col_Button, Clr)
                                            im.PushStyleColor(ctx, im.Col_ButtonActive, Act)
                                            im.PushStyleColor(ctx, im.Col_ButtonHovered, Hvr)
                                            LyrMuteClrPop = 3
                                        end
                                        ClickOnMute = im.Button(ctx, 'M##' .. LyrID, BtnSizeManual, BtnSizeManual)
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then im.PopStyleColor(ctx, LyrMuteClrPop) end



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




                                        MuteBtnR, MuteBtnB = im.GetItemRectMax(ctx)

                                        if FX[FxGUID].AnySoloChan then
                                            if Lyr.Solo[LyrID .. FxGUID] ~= 1 then
                                                im.DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                                    0x00000088)
                                            end
                                        end
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                                            im.DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                                0x00000088)
                                        end
                                    end
                                end




                                if FX[FxGUID].ActiveLyrCount ~= 8 then
                                    AddNewLayer = im.Button(ctx, '+', FXLayeringWin_X, 25)
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

                                            r.SetProjExtState(0, 'FX Devices',
                                                'FX' .. FxGUID .. 'Layer ID ' .. EmptyChan,
                                                EmptyChan)
                                        end
                                    end
                                end
                                im.PopStyleVar(ctx, StyleVarPop)
                                im.PopStyleVar(ctx, 2)

                                im.EndChild(ctx)
                            end
                            im.PopStyleColor(ctx, StyleClrPop)
                        else -- if collapsed
                            if im.BeginChildFrame(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, 27, 220, im.WindowFlags_NoScrollbar) then
                                L, T = im.GetItemRectMin(ctx)
                                local DL = im.GetWindowDrawList(ctx)
                                local title = (FX[FxGUID].ContainerTitle or 'FX Layering'):gsub("(.)", "%1\n")

                                WindowBtnVertical = im.Button(ctx, title .. '##Vertical', 25, 220) -- create window name button
                                if WindowBtnVertical and Mods == 0 then
                                elseif WindowBtnVertical == true and Mods == Shift then
                                    ToggleBypassFX()
                                elseif im.IsItemClicked(ctx) and Mods == Alt then
                                    FX[FxGUID].DeleteFXLayer = true
                                elseif im.IsItemClicked(ctx, 1) and Mods == 0 then
                                    FX[FxGUID].Collapse = nil
                                elseif im.IsItemClicked(ctx, 1) and Mods == Alt then
                                    BlinkFX = ToggleCollapseAll(FX_Idx)
                                end

                                if im.BeginDragDropSource(ctx, im.DragDropFlags_None) then
                                    DragFX_ID = FX_Idx
                                    im.SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                                    im.EndDragDropSource(ctx)
                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end

                                im.DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                                im.DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                                im.DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)


                                im.EndChildFrame(ctx)
                            end
                        end

                        FX[FxGUID].DontShowTilNextFullLoop = true

                        if not FX[FxGUID].Collapse then --Create FX windows inside rack
                            local Sel_LyrID
                            drawlist = im.GetBackgroundDrawList(ctx)


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
                                            im.SameLine(ctx, nil, 0)

                                            AddSpaceBtwnFXs(FX_Idx_InLayer, false, nil, LyrID)
                                            Xpos_Left, Ypos_Top = im.GetItemRectMin(ctx)
                                            im.SameLine(ctx, nil, 0)
                                            if not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                                                createFXWindow(FX_Idx_InLayer)
                                            else
                                            end
                                            Sel_LyrID = LyrID

                                            Xpos_Right, Ypos_Btm = im.GetItemRectMax(ctx)

                                            im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right,
                                                Ypos_Top, Clr.Dvdr.outline)
                                            im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right,
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

                                im.SameLine(ctx, nil, 0)
                            end


                            Lyr[FXGUID_RackMixer] = Lyr[FXGUID_RackMixer] or {}
                            Lyr[FXGUID_RackMixer].HowManyFX = HowManyFXinLyr



                            if HowManyFXinLyr > 0 and FX[FxGUID].TheresFXinLyr then -- ==  Add and theres fx in selected layer
                                --if there's fx in the rack

                                AddLastSPCinRack = true

                                AddSpaceBtwnFXs(FX_Idx, nil, nil, Sel_LyrID)
                                AddLastSPCinRack = false
                                Xpos_Right, Ypos_Btm = im.GetItemRectMax(ctx)
                                Xpos_Left, Ypos_Top = im.GetItemRectMin(ctx)


                                local TheresFXinLyr
                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                    if FX[FXGUID[FX_Idx]] then
                                        if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[Lyr.Selected[FXGUID_RackMixer]] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                            TheresFXinLyr = true
                                        end
                                    end
                                end


                                if TheresFXinLyr then --==  lines to enclose fx layering
                                    im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right, Ypos_Top,
                                        Clr.Dvdr.outline)
                                    im.DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right, Ypos_Btm,
                                        Clr.Dvdr.outline)
                                    im.DrawList_AddLine(ViewPort_DL, Xpos_Right, Ypos_Top, Xpos_Right, Ypos_Btm,
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
                                im.SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                    VP.y + VP.h / 2 - Modalh / 2)
                                im.SetNextWindowSize(ctx, Modalw, Modalh)
                                im.OpenPopup(ctx, 'Delete FX Layer? ##' .. FxGUID)
                            end
                        end

                        if im.BeginPopupModal(ctx, 'Delete FX Layer? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                            im.Text(ctx, 'Delete the FXs in layers altogether?')
                            if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, 78) then
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
                            im.SameLine(ctx)

                            if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, 89) then
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
                            im.SameLine(ctx)

                            if im.Button(ctx, '(c) Cancel  (or Esc)') or im.IsKeyPressed(ctx, 67) or im.IsKeyPressed(ctx, 27) then
                                FX[FxGUID].DeleteFXLayer = nil
                                im.CloseCurrentPopup(ctx)
                            end
                            im.SameLine(ctx)

                            im.EndPopup(ctx)
                        end

                        im.SameLine(ctx, nil, 0)
                        FX[FXGUID[FX_Idx]].DontShowTilNextFullLoop = true
                    elseif FX_Name:find('FXD ReSpectrum') then
                        --local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        local next_fxidx, previous_fxidx, NextFX, PreviousFX = GetNextAndPreviousFXID(FX_Idx)

                        --if FX below is not Pro-Q 3
                        if string.find(NextFX, 'Pro%-Q 3') == nil then
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
                                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState',
                                    Fx_P,
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
                        local WDL = WDL or im.GetWindowDrawList(ctx)

                        if BandSplitID and not FX[FxGUID].BandSplitID then
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: BandSplitterID' .. FxGUID, BandSplitID, true)
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


                        if im.BeginChild(ctx, 'FXD Saike BandSplitter' .. FxGUID, Width, 220) then
                            local SpcW = AddSpaceBtwnFXs(FX_Idx, 'SpaceBefoeBS', nil, nil, 1, FxGUID)
                            SL(nil, 0)

                            local btnTitle = string.gsub('Band Split', "(.)", "%1\n")
                            local btn = im.Button(ctx, btnTitle .. '##Vertical', BtnWidth, 220) -- create window name button   Band Split button


                            if btn and Mods == 0 then
                                openFXwindow(LT_Track, FX_Idx)
                            elseif btn and Mods == Shift then
                                ToggleBypassFX(LT_Track, FX_Idx)
                            elseif btn and Mods == Alt then
                                FX[FxGUID].DeleteBandSplitter = true
                            elseif im.IsItemClicked(ctx, 1) and Mods == 0 then
                                FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
                            elseif im.IsItemClicked(ctx, 1) and Mods == Alt then -- check if all are collapsed
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
                            elseif im.IsItemActive(ctx) then
                                DraggingFX_L_Pos = im.GetCursorScreenPos(ctx) + 10
                                if im.BeginDragDropSource(ctx, im.DragDropFlags_AcceptNoDrawDefaultRect) then
                                    --DragFX_ID = FX_Idx
                                    im.SetDragDropPayload(ctx, 'BS_Drag', FX_Idx)
                                    im.EndDragDropSource(ctx)

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
                            WinL, WinT = im.GetCursorScreenPos(ctx)
                            H, WinR = 220, WinL + Width - BtnWidth - SpcW


                            if FX[FxGUID].Collapse then
                                local L, T = WinL - BtnWidth, WinT
                                im.DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                                im.DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                                im.DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)
                            else
                                for i = 1, Cuts * 4, 1 do ----------[Repeat for Bands]----------
                                    local TxtClr = getClr(im.Col_Text)
                                    FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {}
                                    local X = FX[FxGUID].Cross[i]
                                    -- r.gmem_attach('FXD_BandSplit')
                                    local WDL = im.GetWindowDrawList(ctx)
                                    local BsID = BsID or 0

                                    X.Val = r.gmem_read(BsID + i)
                                    X.NxtVal = r.gmem_read(BsID + i + 1)
                                    X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)


                                    --FX[FxGUID].Cross[i].Val = r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)

                                    local Cross_Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                                    local NxtCrossPos = SetMinMax(WinT + H - H * X.NxtVal, WinT, WinT + H)


                                    if --[[Hovering over a band]] im.IsMouseHoveringRect(ctx, WinL, Cross_Pos - 3, WinR, Cross_Pos + 3) then
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
                                            im.SetNextWindowPos(ctx,WinR, FX[FxGUID].Cross[i].Pos -14)
                                            im.BeginTooltip(ctx)
                                            im.Text(ctx, roundUp(r.gmem_read(BsID+4+i),1)..' Hz')
                                            im.EndTooltip(ctx)
                                        end  ]]
                                    end

                                    BD1 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                                    BD2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2)
                                    BD3 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3)
                                    BD4 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4)

                                    if --[[Mouse is between bands]] im.IsMouseHoveringRect(ctx, WinL, X.Pos, WinR, NxtCrossPos) then
                                        if Payload_Type == 'FX_Drag' then

                                        end
                                    end



                                    if im.IsMouseHoveringRect(ctx, WinL, WinT, WinR, WinT + H) and IsRBtnClicked then

                                    end

                                    if Sel_Cross[1] == i and Sel_Cross.FxID == FxGUID then
                                        if IsLBtnHeld then
                                            FX[FxGUID].Cross.DraggingBand = i
                                            local PrmV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                            DragDeltaX, DragDeltaY = im.GetMouseDragDelta(ctx)
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
                                                im.ResetMouseDragDelta(ctx)
                                                --r.gmem_write(101,0)
                                            end
                                            if Sel_Cross[1] == i then
                                                im.SetNextWindowPos(ctx, WinR, FX[FxGUID].Cross[i].Pos - 14)
                                                im.BeginTooltip(ctx)
                                                im.Text(ctx, roundUp(r.gmem_read(BsID + 4 + i), 1) .. ' Hz')
                                                im.EndTooltip(ctx)
                                                --im.DrawList_AddText(Glob.FDL, WinL, Cross_Pos, getClr(im.Col_Text) , roundUp(r.gmem_read(10+i),1)..' Hz')
                                            end
                                        else
                                            Sel_Cross = {} --r.gmem_write(100, 0)
                                        end
                                    else
                                    end


                                    --[[ -- Draw Bands
                                    im.DrawList_AddLine(WDL, WinL, X.Pos , WinR, X.Pos, TxtClr )
                                    im.DrawList_AddText(WDL, WinL, X.Pos, TxtClr , roundUp(r.gmem_read(BsID+4+i),1)) ]]
                                end


                                function DropFXintoBS(FxID, FxGUID_BS, Band, Pl, DropDest, DontMove) --Pl is payload    --!!!! Correct drop dest!!!!
                                    if not FxID then return end
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
                                    local HvrOnBand = im.IsMouseHoveringRect(ctx, WinL, CrossPos - 3, WinR,
                                        CrossPos + 3)
                                    local HvrOnNxtBand = im.IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos - 3, WinR,
                                        Nxt_CrossPos + 3)

                                    if --[[Hovering over a band]] im.IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos, WinR, CrossPos) and not (HvrOnBand or HvrOnNxtBand) then
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
                                                im.DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                                    0xffffff66)
                                                if im.IsMouseReleased(ctx, 0) then
                                                    local DropDest = FX_Idx
                                                    local InsPos = Find_InsPos()
                                                    DropFXintoBS(FXGUID[Pl], FxGUID, i, Pl, InsPos + 1)
                                                end
                                            end
                                        elseif Payload_Type == 'DND ADD FX' then
                                            im.DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                                0xffffff66)

                                            if im.IsMouseReleased(ctx, 0) then
                                                local InsPos = Find_InsPos()
                                                local rv, type, payload, is_preview, is_delivery = r
                                                    .ImGui_GetDragDropPayload(ctx)
                                                local id = r.TrackFX_AddByName(LT_Track, payload, false,
                                                    -1000 - InsPos - 1)
                                                local FXid = r.TrackFX_GetFXGUID(LT_Track, id)
                                                DropFXintoBS(FXid, FxGUID, i, id, FX_Idx, 'DontMove')
                                            end
                                        end
                                        AnySplitBandHvred = true
                                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}
                                        FX[FxGUID].PreviouslySolodBand = FX[FxGUID].PreviouslySolodBand or {}

                                        --Mute Band
                                        if im.IsKeyPressed(ctx, im.Key_M) and Mods == 0 then
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
                                        elseif im.IsKeyPressed(ctx, im.Key_S) and Mods == 0 then
                                            local Mute = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)
                                            if Mute == 1 then
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                                    4 + 5 * i)
                                                local V
                                                if OnOff == 1 then V = 0 else V = 1 end
                                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, V)
                                                FX[FxGUID].PreviouslySolodBand = {}
                                            end
                                        elseif im.IsKeyPressed(ctx, im.Key_M) and Mods == Shift then
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
                                        elseif im.IsKeyPressed(ctx, im.Key_S) and Mods == Shift then
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
                                            local _, ClickPos = im.GetMousePos(ctx, 1)
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
                                                im.SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                                    VP.y + VP.h / 2 - Modalh / 2)
                                                im.SetNextWindowSize(ctx, Modalw, Modalh)
                                                im.OpenPopup(ctx, 'Delete Band' .. i .. '? ##' .. FxGUID)
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
                                            HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1,
                                                WinR - 1,
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



                                        WDL = WDL or im.GetWindowDrawList(ctx)
                                        -- Highligh Hovered Band
                                        if not IsLBtnHeld then
                                            im.DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR, CrossPos,
                                                0xffffff19)
                                        end
                                    end
                                    if FX[FxGUID].Sel_Band == i then
                                        HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                                            Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1,
                                            NoGetItemRect,
                                            NoForeground, NOrounding)
                                    end


                                    local Solo, Pwr
                                    if JoinerID then
                                        Pwr = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)

                                        local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                        if Pwr == 0 then
                                            im.DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                                CrossPos, Clr)
                                        end

                                        Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)
                                        local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                        if Solo == 1 then
                                            im.DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                                CrossPos, Clr)
                                        end
                                    end
                                end

                                if im.BeginPopupModal(ctx, 'Delete Band' .. (FX[FxGUID].PromptDeleteBand or '') .. '? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                                    im.Text(ctx, 'Delete the FXs in band ' .. FX[FxGUID].PromptDeleteBand .. '?')
                                    if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, im.Key_Y) then
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
                                        im.CloseCurrentPopup(ctx)
                                    end
                                    SL()
                                    if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, im.Key_N) then
                                        im.CloseCurrentPopup(ctx)
                                    end
                                    im.EndPopup(ctx)
                                end






                                -- draw bands

                                for i = 1, Cuts * 4, 1 do
                                    local X = FX[FxGUID].Cross[i]
                                    if IsRBtnHeld then
                                        X.Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i);

                                        X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                                    end
                                    local BsID = FX[FxGUID].BandSplitID
                                    local TxtClr = getClr(im.Col_Text)

                                    im.DrawList_AddLine(WDL, WinL, X.Pos, WinR, X.Pos, TxtClr)
                                    if FX[FxGUID].Cross.DraggingBand ~= i then
                                        im.DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                            roundUp(r.gmem_read(BsID + 4 + i), 1))
                                    end
                                    if FX[FxGUID].Cross.HoveringBand == i or FX[FxGUID].Cross.DraggingBand == i then
                                        if not FX[FxGUID].Cross.DraggingBand == i then
                                            im.DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                                roundUp(r.gmem_read(BsID + 4 + i), 1))
                                        end
                                        im.DrawList_AddLine(WDL, WinL, X.Pos + 1, WinR, X.Pos, TxtClr)

                                        if not im.IsMouseHoveringRect(ctx, WinL, FX[FxGUID].Cross.HoveringBandPos - 3, WinR, FX[FxGUID].Cross.HoveringBandPos + 3)
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
                                            im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                                nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                                FXCountForBand[i] or '')
                                        elseif DraggingFXs[1] then
                                            if DraggingFXs.SrcBand == i then
                                                MsX, MsY = im.GetMousePos(ctx)
                                                im.DrawList_AddLine(Glob.FDL, MsX, MsY, WinL + 15,
                                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff99)
                                            else
                                                im.DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                                    FXCountForBand[i] or '')
                                            end
                                        end
                                    end
                                end

                                -- Draw Background
                                im.DrawList_AddRectFilled(WDL, WinL, Glob.WinT, WinR, Glob.WinB, 0xffffff33)

                                local Copy

                                if DraggingFXs[1] and FXCountForBand[DraggingFXs.SrcBand] then
                                    local MsX, MsY = im.GetMousePos(ctx)
                                    if Mods == Apl then Copy = 'Copy' end
                                    im.DrawList_AddTextEx(Glob.FDL, Font_Andale_Mono_20_B, 14, MsX + 20, MsY,
                                        0xffffffaa,
                                        (Copy or '') .. ' ' .. FXCountForBand[DraggingFXs.SrcBand] .. ' FXs')
                                end
                            end


                            if not IsLBtnHeld then FX[FxGUID].StartCount = nil end


                            im.EndChild(ctx)
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
                                            LastFX_XPos = im.GetCursorScreenPos(ctx)
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

                                local Clr = getClr(im.Col_Text)
                                WinT = Glob.WinT
                                H = Glob.Height or 0
                                WinR = WinR or 0
                                NxtB_Pos = NxtB_Pos or 0
                                WinL = WinL or 0
                                im.DrawList_AddLine(WDL, WinR, WinT + H, LastFX_XPos, WinT + H, Clr)
                                im.DrawList_AddLine(WDL, WinR, Sel_B_Pos, WinR, WinT + H, Clr)

                                im.DrawList_AddLine(WDL, WinR, NxtB_Pos, WinR, WinT, Clr)
                                im.DrawList_AddLine(WDL, WinR, WinT, LastFX_XPos, WinT, Clr)
                                im.DrawList_AddLine(WDL, LastFX_XPos - 1, WinT, LastFX_XPos - 1, WinT + H, Clr)
                                if AddTopLine then im.DrawList_AddLine(WDL, WinL, WinT, WinR, WinT, Clr) end
                                if FX[FxGUID].Sel_Band == 0 then
                                    im.DrawList_AddLine(WDL, WinL, WinT + H, WinR,
                                        WinT + H, Clr)
                                end

                                if DraggingFX_L_Pos then
                                    local W = LastFX_XPos - DraggingFX_L_Pos
                                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT,
                                        LastFX_XPos,
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
                                im.SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                    VP.y + VP.h / 2 - Modalh / 2)
                                im.SetNextWindowSize(ctx, Modalw, Modalh)
                                im.OpenPopup(ctx, 'Delete Band Splitter? ##' .. FxGUID)
                            end
                        end

                        if im.BeginPopupModal(ctx, 'Delete Band Splitter? ##' .. FxGUID, nil, im.WindowFlags_NoTitleBar|im.WindowFlags_NoResize) then
                            im.Text(ctx, 'Delete the FXs in band splitter altogether?')
                            if im.Button(ctx, '(n) No') or im.IsKeyPressed(ctx, 78) then
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
                                im.CloseCurrentPopup(ctx)
                                FX[FxGUID].DeleteBandSplitter = nil
                                r.Undo_EndBlock('Delete Band Split and put enclosed FXs back into channel one', 0)
                            end
                            SL()

                            if im.Button(ctx, '(y) Yes') or im.IsKeyPressed(ctx, 89) then
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
                            if im.Button(ctx, '(esc) Cancel') or im.IsKeyPressed(ctx, im.Key_Escape) then
                                FX[FxGUID].DeleteBandSplitter = nil
                                im.CloseCurrentPopup(ctx)
                            end
                            im.EndPopup(ctx)
                        end
                    end --  for if FX_Name ~='JS: FXD (Mix)RackMixer'

                    If_Theres_Pro_C_Analyzers(FX_Name, FX_Idx)
                end
                


                function GetFormatPrmV(V, OrigV, i)
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, V)
                    local _, RV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, i)
                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, OrigV)
                    return RV
                end

                FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)


                local SpcW



                AddSpaceBtwnFXs_FIRST(FX_Idx, FxGUID)


                ---------------==  FX Devices--------------------

                DragFX_ID = DragFX_ID or -1000
                if DragDroppingFX == true and DragFX_ID == FX_Idx then
                    BGColor_FXWindow = FX_Window_Clr_When_Dragging
                else
                    BGColor_FXWindow = FX_Window_Clr_Default
                end
                BGColor_FXWindow = BGColor_FXWindow or 0x434343ff

                Create_FX_Window()
                im.SameLine(ctx, nil, 0)

                local CurX = im.GetCursorPosX(ctx)

                AddSpaceBtwnFXs_LAST(FX_Idx, FxGUID)

              
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




            Pre_FX_Chain(FX_Idx)

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



        _, Payload_Type, Payload, is_preview, is_delivery = im.GetDragDropPayload(ctx)
        Payload = tonumber(Payload)
        MouseAtRightEdge = im.IsMouseHoveringRect(ctx, VP.X + VP.w - 25, VP.Y, VP.X + VP.w, VP.Y + VP.h)

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

        PostFX_Width = math.min( (MakeSpaceForPostFX or 0) + ((Trk[TrkID].MakeSpcForPostFXchain or 0) + (PostFX_LastSpc or 0)) + 30, VP.w / 2)



        if not Trk[TrkID].PostFX[1] then
            Trk[TrkID].MakeSpcForPostFXchain = 0
        end 

        Post_FX_Chain ()


        -- When Add or Delete Fx.....if  add fx or delete fx
        if Sel_Track_FX_Count ~= CompareFXCount then
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

        im.PopStyleVar(ctx) -- styleVar#2 (Border Size for all fx devices)
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
