local GF = require("src.Functions.General Functions")
local gui_helpers = require("src.Components.Gui_Helpers")
local table_helpers = require("src.helpers.table_helpers")
local state_helpers = require("src.helpers.state_helpers")
local fxModels = require("src.helpers.fxModels")
local images_fonts = require("src.helpers.images_fonts")
local math_helpers = require("src.helpers.math_helpers")
local BlackListFXs = fxModels.BlackListFXs
local fxDisplay = {}
---@param spaceIfPreFX number
function fxDisplay.displayFx(spaceIfPreFX)
    if r.ImGui_BeginChild(ctx, 'fx devices', MaxX - (PostFX_Width or 0) - spaceIfPreFX, 240, nil, MainWin_Flg) then
        ------------------------------------------------------
        ----- Loop for every FX on the track -----------------
        ------------------------------------------------------





        CursorStartX = r.ImGui_GetCursorStartPos(ctx)
        FxdCtx.Glob.WinL, FxdCtx.Glob.WinT = r.ImGui_GetCursorScreenPos(ctx)
        FxdCtx.Glob.Height = 220
        FxdCtx.Glob.WinB = FxdCtx.Glob.WinT + FxdCtx.Glob.Height
        AnySplitBandHvred = false


        local ViewPort_DL = r.ImGui_GetWindowDrawList(ctx)
        r.ImGui_DrawList_AddLine(ViewPort_DL, 0, 0, 0, 0, Clr.Dvdr.outline) -- Needed for drawlist to be active

        for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
            Retval, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx) --i used to be i-1
            FxdCtx.FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)


            local FxGUID = FxdCtx.FXGUID[FX_Idx]
            FxdCtx.FX.Win_Name[FX_Idx] = FX_Name
            FocusedFXState, trackNumOfFocusFX, _, FX_Index_FocusFX = r.GetFocusedFX2()

            if FxdCtx.FXGUID[FX_Idx] then
                FxdCtx.FX[FxGUID] = FxdCtx.FX[FxGUID] or {}
            end


            function GetFormatPrmV(V, OrigV, i)
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, V)
                local _, RV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, i)
                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, OrigV)
                return RV
            end

            FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            if not table_helpers.tablefind(FxdCtx.Trk[TrkID].PostFX, FxGUID) and FxdCtx.FXGUID[FX_Idx] ~= FxdCtx.FXGUID[FX_Idx - 1] then
                if FxdCtx.FX.InLyr[FXGUID_To_Check_If_InLayer] == nil    --not in layer
                    and table_helpers.FindStringInTable(BlackListFXs, FX_Name) ~= true -- not blacklisted
                    and string.find(FX_Name, 'RackMixer') == nil
                    and FX_Idx ~= RepeatTimeForWindows                   --not last fx
                    and not FxdCtx.FX[FxGUID].InWhichBand --[[Not in Band Split]] then
                    local Idx = FX_Idx
                    if FX_Idx == 1 then
                        local Nm = FxdCtx.FX.Win_Name[0]
                        if Nm == 'JS: FXD Macros' or table_helpers.FindStringInTable(BlackListFXs, Nm) then Idx = 0 end
                    end
                elseif FxdCtx.FX.InLyr[FXGUID_To_Check_If_InLayer] == FxdCtx.FXGUID[FX_Idx] and FxdCtx.FXGUID[FX_Idx] then
                    GF.AddSpaceBtwnFXs(FX_Idx, true)
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


            if --[[Normal Window]] (not string.find(FX_Name, 'FXD %(Mix%)RackMixer')) and FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx]] == nil and FX_Idx ~= RepeatTimeForWindows and table_helpers.FindStringInTable(BlackListFXs, FX_Name) ~= true then
                --FX_IdxREAL =  FX_Idx+Lyr.FX_Ins[FXGUID[FX_Idx]]
                Tab_Collapse_Win = false

                if not table_helpers.tablefind(FxdCtx.Trk[TrkID].PostFX, FxGUID) and not FxdCtx.FX[FxGUID].InWhichBand then
                    GF.createFXWindow(FX_Idx)
                    local _, _, _ = r.TrackFX_GetIOSize(LT_Track, FX_Idx)
                end
                if FxdCtx.FX.LayEdit == FxdCtx.FXGUID[FX_Idx] then
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0xffffff00)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderActive(), 0xffffff00)

                    --if not ctx then ctx = r.ImGui_CreateContext('Layout Editor') end
                    --r.ImGui_BeginTooltip( ctx)

                    --attachfonts(ctx)

                    --[[ rv, LayEdProp_Open = r.ImGui_Begin(ctx, 'LayoutEdit Propertiess', true,
                                r.ImGui_WindowFlags_MenuBar() + r.ImGui_WindowFlags_NoCollapse() +
                                r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_NoDocking()) ]]
                    --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x191919ff ) ;
                    local FxGUID = FxdCtx.FXGUID[FX_Idx]

                    if not CloseLayEdit and r.ImGui_Begin(ctx, 'LayoutEdit Propertiess', true, r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_NoDocking()) then
                        --if not CloseLayEdit   then    ----START CHILD WINDOW------
                        DisableScroll = true



                        if r.ImGui_Button(ctx, 'Save') then
                            SaveLayoutEditings(FX_Name, FX_Idx, FxdCtx.FXGUID[FX_Idx])
                            CloseLayEdit = true; FxdCtx.FX.LayEdit = nil
                        end
                        gui_helpers.SL()
                        if r.ImGui_Button(ctx, 'Exit##Lay') then
                            r.ImGui_OpenPopup(ctx, 'Save Editing?')
                        end
                        gui_helpers.SL()

                        if FxdCtx.LE.Sel_Items[1] then
                            local I = FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]]
                            if r.ImGui_Button(ctx, 'Delete') then
                                local tb = {}

                                for i, v in pairs(FxdCtx.LE.Sel_Items) do
                                    tb[i] = v
                                end
                                table.sort(tb)

                                for i = #tb, 1, -1 do
                                    GF.DeletePrm(FxGUID, tb[i])
                                end

                                if not FxdCtx.FX[FxGUID][1] then FxdCtx.FX[FxGUID].AllPrmHasBeenDeleted = true else FxdCtx.FX[FxGUID].AllPrmHasBeenDeleted = nil end


                                FxdCtx.LE.Sel_Items = {}
                            end

                            gui_helpers.SL(nil, 30)

                            if r.ImGui_Button(ctx, 'Copy Properties') then
                                CopyPrm = {}
                                CopyPrm = I
                            end

                            gui_helpers.SL()
                            if r.ImGui_Button(ctx, 'Paste Properties') then
                                for _, _ in pairs(FxdCtx.LE.Sel_Items) do
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
                        gui_helpers.SL(nil, 30)

                        if FxdCtx.Draw.DrawMode[FxGUID] then
                            if r.ImGui_Button(ctx, 'Exit Background Edit') then FxdCtx.Draw.DrawMode[FxGUID] = false end
                        else
                            if r.ImGui_Button(ctx, 'Enter Background Edit') then
                                FxdCtx.Draw.DrawMode[FxGUID] = true
                                if FxdCtx.Draw[FxdCtx.FX.Win_Name_S[FX_Idx]] == nil then
                                    FxdCtx.Draw[FxdCtx.FX.Win_Name_S[FX_Idx]] = {
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
                                FxdCtx.LE.Sel_Items = {}
                            end
                        end




                        r.ImGui_Separator(ctx)






                        -- Add Drawings ----
                        if not FxdCtx.LE.Sel_Items[1] then
                            if FxdCtx.Draw.DrawMode[FxGUID] ~= true then
                                r.ImGui_TextWrapped(ctx, 'Select an item to start editing')
                                GF.AddSpacing(15)
                            else
                                r.ImGui_Text(ctx, '(!) Hold down Left button to Draw in FX Devices')
                                GF.AddSpacing(5)
                                r.ImGui_Text(ctx, 'Type:')
                                r.ImGui_SameLine(ctx)
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x99999933)
                                FxdCtx.FX[FxGUID].Draw = FxdCtx.FX[FxGUID].Draw or {}
                                local D = FxdCtx.FX[FxGUID].Draw
                                local FullWidth = -50

                                local typelbl; local It = FxdCtx.Draw.SelItm
                                --D[It or 1] = D[It or 1] or {}


                                if FxdCtx.Draw.SelItm then typelbl = D[It].Type end
                                if FxdCtx.Draw.Type == nil then FxdCtx.Draw.Type = 'line' end
                                r.ImGui_SetNextItemWidth(ctx, FullWidth)
                                if r.ImGui_BeginCombo(ctx, '##', typelbl or FxdCtx.Draw.Type or 'line', r.ImGui_ComboFlags_NoArrowButton()) then
                                    local function setType(str)
                                        if r.ImGui_Selectable(ctx, str, false) then
                                            if It then D[It].Type = str end
                                            FxdCtx.Draw.Type = str
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

                                if It then
                                    r.ImGui_Text(ctx, 'Color :')
                                    r.ImGui_SameLine(ctx)
                                    if FxdCtx.Draw.SelItm and D[It].clr then
                                        Clrpick, D[It].clr = r.ImGui_ColorEdit4(ctx, '##',
                                            D[It].clr or 0xffffffff,
                                            r.ImGui_ColorEditFlags_NoInputs()|
                                            r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                            r.ImGui_ColorEditFlags_AlphaBar())
                                    else
                                        Clrpick, FxdCtx.Draw.clr = r.ImGui_ColorEdit4(ctx, '##',
                                            FxdCtx.Draw.clr or 0xffffffff,
                                            r.ImGui_ColorEditFlags_NoInputs()|
                                            r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                            r.ImGui_ColorEditFlags_AlphaBar())
                                    end
                                    r.ImGui_Text(ctx, 'Default edge rounding :')
                                    r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 40)

                                    FxdCtx.FX[FxGUID].Draw = FxdCtx.FX[FxGUID].Draw or {}
                                    EditER, FxdCtx.FX[FxGUID].Draw.Df_EdgeRound = r.ImGui_DragDouble(ctx,
                                        '##' .. FxGUID,
                                        FxdCtx.FX[FxGUID].Draw.Df_EdgeRound, 0.05, 0, 30, '%.2f')



                                    if D[It].Type == 'Picture' then
                                        r.ImGui_Text(ctx, 'File Path:')
                                        gui_helpers.SL()
                                        DragDropPics = DragDropPics or {}

                                        if r.ImGui_BeginChildFrame(ctx, '##drop_files', FullWidth, 40) then
                                            if not D[It].FilePath then
                                                r.ImGui_Text(ctx, 'Drag and drop files here...')
                                            else
                                                r.ImGui_Text(ctx, D[It].FilePath)
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

                                        Rv, D[It].KeepImgRatio = r.ImGui_Checkbox(ctx, 'Keep Image Ratio',
                                            D[It].KeepImgRatio)
                                    end

                                    if FxdCtx.Draw.SelItm then
                                        r.ImGui_Text(ctx, 'Start Pos X:')
                                        r.ImGui_SameLine(ctx)
                                        local CurX = r.ImGui_GetCursorPosX(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, FullWidth)
                                        _, D[It].L = r.ImGui_DragDouble(ctx, '##' .. FxdCtx.Draw.SelItm .. 'L',
                                            D[It].L,
                                            1, 0, Win_W, '%.0f')
                                        if D[It].Type ~= 'V-line' and D[It].Type ~= 'circle' and D[It].Type ~= 'circle fill' then
                                            r.ImGui_Text(ctx, 'End Pos X:')
                                            r.ImGui_SetNextItemWidth(ctx, FullWidth)

                                            r.ImGui_SameLine(ctx, CurX)
                                            _, D[It].R = r.ImGui_DragDouble(ctx,
                                                '##' .. FxdCtx.Draw.SelItm .. 'R',
                                                D[It].R, 1, 0, Win_W, '%.0f')
                                        end

                                        if D[It].Type == 'circle' or D[It].Type == 'circle fill' then
                                            r.ImGui_Text(ctx, 'Radius:')
                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, FullWidth)
                                            _, D[It].R = r.ImGui_DragDouble(ctx,
                                                '##' .. FxdCtx.Draw.SelItm .. 'R',
                                                D[It].R, 1, 0, Win_W, '%.0f')
                                        end


                                        r.ImGui_Text(ctx, 'Start Pos Y:')

                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, FullWidth)

                                        _, D[It].T = r.ImGui_DragDouble(ctx, '##' .. FxdCtx.Draw.SelItm .. 'T',
                                            D[It].T, 1, 0, Win_W, '%.0f')


                                        if D[It].Type ~= 'line' and D[It].Type ~= 'circle fill' and D[It].Type ~= 'circle' then
                                            r.ImGui_Text(ctx, 'End Pos Y:')
                                            r.ImGui_SameLine(ctx, CurX)
                                            r.ImGui_SetNextItemWidth(ctx, FullWidth)

                                            _, D[It].B = r.ImGui_DragDouble(ctx, '##' .. It .. 'B', D[It].B, 1, 0,
                                                Win_W, '%.0f')
                                        end

                                        if D[It].Type == 'Text' then
                                            r.ImGui_Text(ctx, 'Text:')
                                            r.ImGui_SameLine(ctx)

                                            _, D[It].Txt = r.ImGui_InputText(ctx, '##' .. It .. 'Txt', D[It].Txt)

                                            gui_helpers.SL()
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
                                end



                                r.ImGui_PopStyleColor(ctx)
                            end
                        elseif FxdCtx.LE.Sel_Items[1] then
                            local ID, TypeID; local FrstSelItm = FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]]; local FItm =
                                FxdCtx.LE
                                .Sel_Items[1]
                            local R_ofs = 50
                            if FxdCtx.LE.Sel_Items[1] and not FxdCtx.LE.Sel_Items[2] then
                                ID       = FxGUID .. FxdCtx.LE.Sel_Items[1]
                                WidthID  = FxGUID .. FxdCtx.LE.Sel_Items[1]
                                ClrID    = FxGUID .. FxdCtx.LE.Sel_Items[1]
                                GrbClrID = FxGUID .. FxdCtx.LE.Sel_Items[1]
                                TypeID   = FxGUID .. FxdCtx.LE.Sel_Items[1]
                            elseif FxdCtx.LE.Sel_Items[2] then
                                local Diff_Types_Found, Diff_Width_Found, Diff_Clr_Found, Diff_GrbClr_Found
                                for i, v in pairs(FxdCtx.LE.Sel_Items) do
                                    if i > 1 then
                                        if FxdCtx.FX[FxGUID][1].Type ~= FxdCtx.FX[FxGUID][v].Type then Diff_Types_Found = true end
                                        --if FX[FxGUID][frst].Sldr_W ~= FX[FxGUID][v].Sldr_W then  Diff_Width_Found = true    end
                                        --if FX[FxGUID][frst].BgClr  ~= FX[FxGUID][v].BgClr  then Diff_Clr_Found = true       end
                                        --if FX[FxGUID][frst].GrbClr ~= FX[FxGUID][v].GrbClr then Diff_GrbClr_Found = true end
                                    end
                                end
                                if Diff_Types_Found then
                                    TypeID = 'Group'
                                else
                                    TypeID = FxGUID .. FxdCtx.LE.Sel_Items
                                        [1]
                                end
                                if Diff_Width_Found then
                                    WidthID = 'Group'
                                else
                                    WidthID = FxGUID ..
                                        FxdCtx.LE.Sel_Items[1]
                                end
                                if Diff_Clr_Found then
                                    ClrID = 'Group'
                                else
                                    ClrID = FxGUID ..
                                        FxdCtx.LE.Sel_Items[1]
                                end
                                if Diff_GrbClr_Found then
                                    GrbClrID = 'Group'
                                else
                                    GrbClrID = FxGUID ..
                                        FxdCtx.LE.Sel_Items[1]
                                end
                                ID = FxGUID .. FxdCtx.LE.Sel_Items[1]
                            else
                                ID = FxGUID .. FxdCtx.LE.Sel_Items[1]
                            end
                            local function FreeValuePosSettings()
                                if FrstSelItm.V_Pos == 'Free' then
                                    r.ImGui_Text(ctx, 'X:')
                                    gui_helpers.SL()
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local EditPosX, PosX = r.ImGui_DragDouble(ctx,
                                        ' ##EditValuePosX' .. FxGUID .. FxdCtx.LE.Sel_Items[1],
                                        FrstSelItm.V_Pos_X or 0,
                                        0.25, nil, nil, '%.2f')
                                    gui_helpers.SL()
                                    if EditPosX then
                                        for _, _ in pairs(FxdCtx.LE.Sel_Items) do FrstSelItm.V_Pos_X = PosX end
                                    end
                                    r.ImGui_Text(ctx, 'Y:')
                                    gui_helpers.SL()
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local EditPosY, PosY = r.ImGui_DragDouble(ctx,
                                        ' ##EditValuePosY' .. FxGUID .. FxdCtx.LE.Sel_Items[1],
                                        FrstSelItm.V_Pos_Y or 0,
                                        0.25, nil, nil, '%.2f')
                                    gui_helpers.SL()
                                    if EditPosY then
                                        for _, _ in pairs(FxdCtx.LE.Sel_Items) do FrstSelItm.V_Pos_Y = PosY end
                                    end
                                end
                            end
                            local function FreeLblPosSettings()
                                if FrstSelItm.Lbl_Pos == 'Free' then
                                    r.ImGui_Text(ctx, 'X:')
                                    gui_helpers.SL()
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local EditPosX, PosX = r.ImGui_DragDouble(ctx,
                                        ' ##EditLblPosX' .. FxGUID .. FxdCtx.LE.Sel_Items[1],
                                        FrstSelItm.Lbl_Pos_X or 0,
                                        0.25, nil, nil, '%.2f')
                                    gui_helpers.SL()
                                    if EditPosX then
                                        for _, _ in pairs(FxdCtx.LE.Sel_Items) do FrstSelItm.Lbl_Pos_X = PosX end
                                    end
                                    r.ImGui_Text(ctx, 'Y:')
                                    gui_helpers.SL()
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local EditPosY, PosY = r.ImGui_DragDouble(ctx,
                                        ' ##EditLblPosY' .. FxGUID .. FxdCtx.LE.Sel_Items[1],
                                        FrstSelItm.Lbl_Pos_Y or 0,
                                        0.25, nil, nil, '%.2f')
                                    gui_helpers.SL()
                                    if EditPosY then
                                        for _, _ in pairs(FxdCtx.LE.Sel_Items) do FrstSelItm.Lbl_Pos_Y = PosY end
                                    end
                                end
                            end
                            local function AddOption(Name, TargetVar, TypeCondition)
                                if FrstSelItm.Type == TypeCondition or not TypeCondition then
                                    if r.ImGui_Selectable(ctx, Name, false) then
                                        for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                            FxdCtx.FX[FxGUID][v][TargetVar] =
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
                            if not FrstSelItm.Type then FrstSelItm.Type = FxdCtx.FX.Def_Type[FxGUID] end
                            r.ImGui_Text(ctx, 'Type : '); r.ImGui_SameLine(ctx); r.ImGui_PushStyleColor(ctx,
                                r.ImGui_Col_FrameBg(), 0x444444aa)
                            r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                            if r.ImGui_BeginCombo(ctx, '##', PrmTypeLbl, r.ImGui_ComboFlags_NoArrowButton()) then
                                local function SetItemType(Type)
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].Sldr_W = nil
                                        FxdCtx.FX[FxGUID][v].Type = Type
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
                            if FxdCtx.LE.Sel_Items[1] and not FxdCtx.LE.Sel_Items[2] then
                                r.ImGui_Text(ctx, 'Label: '); r.ImGui_SameLine(ctx)
                                r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                local _, buf = r.ImGui_InputText(ctx,
                                    ' ##Edit Title' .. FxGUID .. FxdCtx.LE.Sel_Items[1],
                                    FrstSelItm.CustomLbl or buf)
                                if r.ImGui_IsItemActivated(ctx) then EditingPrmLbl = FxdCtx.LE.Sel_Items[1] end
                                if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then FrstSelItm.CustomLbl = buf end
                            end

                            --Label Pos
                            r.ImGui_Text(ctx, 'Label Pos: '); r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(
                                ctx, 100)
                            if r.ImGui_BeginCombo(ctx, '## Lbl Pos' .. FxdCtx.LE.Sel_Items[1], FrstSelItm.Lbl_Pos or 'Default', r.ImGui_ComboFlags_NoArrowButton()) then
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
                                FxdCtx.LE.Sel_Items[1],
                                FrstSelItm.Lbl_Clr or r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                r.ImGui_ColorEditFlags_AlphaBar())
                            if DragLbl_Clr_Edited then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                    FxdCtx.FX[FxGUID][v].Lbl_Clr =
                                        Lbl_V_Clr
                                end
                            end


                            r.ImGui_Text(ctx, 'Value Pos: '); r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(
                                ctx, 100)
                            if r.ImGui_BeginCombo(ctx, '## V Pos' .. FxdCtx.LE.Sel_Items[1], FrstSelItm.V_Pos or 'Default', r.ImGui_ComboFlags_NoArrowButton()) then
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
                            DragV_Clr_edited, Drag_V_Clr = r.ImGui_ColorEdit4(ctx,
                                '##V  Clr' .. FxdCtx.LE.Sel_Items[1],
                                FrstSelItm.V_Clr or r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                r.ImGui_ColorEditFlags_AlphaBar())
                            if DragV_Clr_edited then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do FxdCtx.FX[FxGUID][v].V_Clr = Drag_V_Clr end
                            end

                            if FrstSelItm.Type == 'Drag' then
                                r.ImGui_Text(ctx, 'Direction: ')
                                r.ImGui_SameLine(ctx)
                                r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                if r.ImGui_BeginCombo(ctx, '## Drag Dir' .. FxdCtx.LE.Sel_Items[1], FrstSelItm.DragDir or '', r.ImGui_ComboFlags_NoArrowButton()) then
                                    if r.ImGui_Selectable(ctx, 'Right', false) then
                                        for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                            FxdCtx.FX[FxGUID][v].DragDir =
                                            'Right'
                                        end
                                    elseif r.ImGui_Selectable(ctx, 'Left-Right', false) then
                                        for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                            FxdCtx.FX[FxGUID][v].DragDir =
                                            'Left-Right'
                                        end
                                    elseif r.ImGui_Selectable(ctx, 'Left', false) then
                                        for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                            FxdCtx.FX[FxGUID][v].DragDir =
                                            'Left'
                                        end
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
                                EdT, Tg = r.ImGui_Checkbox(ctx, 'Toggle##' .. FxGUID .. FxdCtx.LE.Sel_Items[1],
                                    Toggle)
                                r.ImGui_SameLine(ctx);
                                EdM, Mt = r.ImGui_Checkbox(ctx, 'Momentary##' .. FxGUID .. FxdCtx.LE.Sel_Items
                                    [1],
                                    Momentary)
                                if EdT then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].SwitchType =
                                        'Toggle'
                                    end
                                elseif EdM then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].SwitchType =
                                        'Momentary'
                                    end
                                end
                            end



                            -- set base and target value
                            if FrstSelItm.SwitchType == 'Momentary' and FrstSelItm.Type == 'Switch' then
                                r.ImGui_Text(ctx, 'Base Value: ')
                                r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 80)
                                local Drag, Bv = r.ImGui_DragDouble(ctx,
                                    '##EditBaseV' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                    FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].SwitchBaseV or 0, 0.05, 0, 1,
                                    '%.2f')
                                if Drag then
                                    for _, _ in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].SwitchBaseV = Bv
                                    end
                                end
                                r.ImGui_Text(ctx, 'Target Value: ')
                                r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 80)
                                local Drag, Tv = r.ImGui_DragDouble(ctx,
                                    '##EditTargV' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                    FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].SwitchTargV or 1, 0.05, 0, 1,
                                    '%.2f')
                                if Drag then
                                    for _, _ in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].SwitchTargV =
                                            Tv
                                    end
                                end
                            end









                            ----Font Size-----


                            r.ImGui_Text(ctx, 'Label Font Size: '); r.ImGui_SameLine(ctx)
                            r.ImGui_SetNextItemWidth(ctx, 50)
                            local Drag, ft = r.ImGui_DragDouble(ctx,
                                '##EditFontSize' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                FrstSelItm.FontSize or Knob_DefaultFontSize, 0.25, 6, 64, '%.2f')
                            if Drag then
                                local sz = math_helpers.roundUp(ft, 1)
                                if not _G['Font_Andale_Mono' .. '_' .. sz] then
                                    _G['Font_Andale_Mono' .. '_' .. sz] = r.ImGui_CreateFont('andale mono', sz)
                                    ChangeFont = FrstSelItm
                                    ChangeFont_Size = sz
                                end

                                for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                    FxdCtx.FX[FxGUID][v].FontSize = ft
                                end
                            end






                            gui_helpers.SL()
                            r.ImGui_Text(ctx, 'Value Font Size: '); r.ImGui_SameLine(ctx)
                            r.ImGui_SetNextItemWidth(ctx, 50)
                            local Drag, ft = r.ImGui_DragDouble(ctx,
                                '##EditV_FontSize' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].V_FontSize or Knob_DefaultFontSize,
                                0.25, 6, 64,
                                '%.2f')
                            if Drag then
                                local sz = math_helpers.roundUp(ft, 1)
                                if not _G['Arial' .. '_' .. sz] then
                                    _G['Arial' .. '_' .. sz] = r.ImGui_CreateFont('Arial', sz)
                                    ChangeFont = FrstSelItm
                                    ChangeFont_Size = sz
                                    ChangeFont_Font = 'Arial'
                                end
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                    FxdCtx.FX[FxGUID][v].V_FontSize = ft
                                end
                            end








                            ----Width -------
                            r.ImGui_Text(ctx, 'Width: '); r.ImGui_SameLine(ctx)
                            r.ImGui_SetNextItemWidth(ctx, 60)
                            local DefaultW, MaxW, MinW
                            if FrstSelItm.Type == 'Knob' then
                                DefaultW = FxdCtx.Df.KnobRadius
                                MaxW = 80
                                MinW = 7.5
                            elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' or not FrstSelItm.Type then
                                DefaultW = FxdCtx.Df.Sldr_W
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

                            gui_helpers.SL()


                            local _, W = r.ImGui_DragDouble(ctx,
                                '##EditWidth' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1] or ''].Sldr_W or DefaultW,
                                FxdCtx.LE.GridSize / 4, MinW, MaxW,
                                '%.1f')

                            if r.ImGui_IsItemEdited(ctx) then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                    FxdCtx.FX[FxGUID][v].Sldr_W = W
                                end
                            end


                            if FrstSelItm.Type ~= 'Knob' then
                                gui_helpers.SL()
                                r.ImGui_Text(ctx, 'Height: ')
                                gui_helpers.SL()
                                r.ImGui_SetNextItemWidth(ctx, 60)
                                local max, defaultH
                                if FrstSelItm.Type == 'V-Slider' then
                                    max = 200
                                    defaultH = 160
                                end
                                local _, W = r.ImGui_DragDouble(ctx,
                                    '##Height' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                    FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1] or ''].Height or defaultH or 3,
                                    FxdCtx.LE.GridSize / 4,
                                    -5, max or 40, '%.1f')
                                if r.ImGui_IsItemEdited(ctx) then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].Height = W
                                    end
                                end
                            end



                            if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'Drag' or FrstSelItm.Type == 'Slider' then
                                r.ImGui_Text(ctx, 'Value Decimal Places: '); r.ImGui_SameLine(ctx)
                                r.ImGui_SetNextItemWidth(ctx, 80)
                                if not FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].V_Round then
                                    local _, FormatV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                        FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].Num)
                                    local _, LastNum = FormatV:find('^.*()%d')
                                    local dcm = FormatV:find('%.')
                                    if dcm then
                                        Rd = LastNum - dcm
                                    end
                                end

                                local Edit, rd = r.ImGui_InputInt(ctx,
                                    '##EditValueDecimals' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                    FrstSelItm.V_Round or Rd, 1)
                                if Edit then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].V_Round = math.max(
                                            rd, 0)
                                    end
                                end
                            end







                            r.ImGui_Text(ctx, 'Value to Note Length: '); r.ImGui_SameLine(ctx)
                            r.ImGui_SetNextItemWidth(ctx, 80)
                            local Edit = r.ImGui_Checkbox(ctx,
                                '##Value to Note Length' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                FrstSelItm.ValToNoteL or nil)
                            if Edit then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                    if not FxdCtx.FX[FxGUID][v].ValToNoteL then
                                        FxdCtx.FX[FxGUID][v].ValToNoteL = true
                                    else
                                        FxdCtx.FX[FxGUID][v].ValToNoteL = false
                                    end
                                end
                            end
                            if FrstSelItm.Type == 'Selection' then --r.ImGui_Text(ctx,'Edit Values Manually: ') ;r.ImGui_SameLine(ctx)
                                local Itm = FxdCtx.LE.Sel_Items[1]
                                local FP = FxdCtx.FX[FxGUID][Itm] ---@class FX_P



                                if r.ImGui_TreeNode(ctx, 'Edit Values Manually') then
                                    FxdCtx.FX[FxGUID][Itm].ManualValues = FxdCtx.FX[FxGUID][Itm].ManualValues or
                                        {}
                                    FxdCtx.FX[FxGUID][Itm].ManualValuesFormat = FxdCtx.FX[FxGUID][Itm]
                                        .ManualValuesFormat or {}
                                    if r.ImGui_Button(ctx, 'Get Current Value##' .. FxGUID .. (Itm or '')) then
                                        local Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num)
                                        if not table_helpers.tablefind(FP.ManualValues, Val) then
                                            table.insert(FxdCtx.FX[FxGUID][Itm].ManualValues, Val)
                                        end
                                    end
                                    for i, V in ipairs(FxdCtx.FX[FxGUID][Itm].ManualValues) do
                                        r.ImGui_AlignTextToFramePadding(ctx)
                                        r.ImGui_Text(ctx, i .. ':' .. (math_helpers.round(V, 2) or 0))
                                        gui_helpers.SL()
                                        --r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                        Rv, FxdCtx.FX[FxGUID][Itm].ManualValuesFormat[i] = r.ImGui_InputText(ctx,
                                            '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i,
                                            FxdCtx.FX[FxGUID][Itm].ManualValuesFormat[i])
                                        gui_helpers.SL()
                                        if gui_helpers.IconBtn(20, 20, 'T', BgClr, 'center', '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i) then
                                            table.remove(FxdCtx.FX[FxGUID][Itm].ManualValuesFormat, i)
                                            table.remove(FxdCtx.FX[FxGUID][Itm].ManualValues, i)
                                        end
                                    end
                                    --FX[FxGUID][Itm].EditValuesManual = true
                                    r.ImGui_TreePop(ctx)
                                end
                            end

                            function ToAllSelItm(x, y)
                                for _, v in ipairs(FxdCtx.LE.Sel_Items) do
                                    FxdCtx.FX[FxGUID][v][x] = y
                                end
                            end

                            local FLT_MIN, _ = r.ImGui_NumericLimits_Float()

                            --- Style ------
                            r.ImGui_Text(ctx, 'Style: '); r.ImGui_SameLine(ctx)
                            W = r.ImGui_CalcTextSize(ctx, 'Style: ')
                            local stylename
                            if FrstSelItm.Style == 'Pro C' then stylename = 'Minimalistic' end
                            if r.ImGui_Button(ctx, (stylename or FrstSelItm.Style or 'Choose Style') .. '##' .. (FxdCtx.LE.Sel_Items[1] or 'Style'), 130) then
                                r.ImGui_OpenPopup(ctx, 'Choose style window')
                            end


                            r.ImGui_Text(ctx, 'Add Custom Image:')

                            DragDropPics = DragDropPics or {}

                            local rv, _ = images_fonts.TrashIcon(16, 'Clear', ClrBG, ImgTrashTint)
                            if rv then
                                ToAllSelItm('Style', nil)
                                ToAllSelItm('ImagePath', nil)
                                ToAllSelItm('Image', nil)
                            end


                            gui_helpers.SL()
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

                                                    local NewFileName = r.GetResourcePath() .. 'src/Images/' ..  SubFolder .. filename:sub(index)
                                                    fs_utils.CopyFile(filename, NewFileName) ]]
                                            if FrstSelItm.Type == 'Knob' then
                                                AbsPath, FrstSelItm.ImagePath = fs_utils.CopyImageFile(filename,
                                                    'Knobs')
                                            elseif FrstSelItm.Type == 'Switch' then
                                                AbsPath, FrstSelItm.ImagePath = fs_utils.CopyImageFile(filename,
                                                    'Switches')
                                            end
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
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].Style = Style;
                                        if img then
                                            FxdCtx.FX[FxGUID][v].Image = img
                                            FxdCtx.FX[FxGUID][v].ImagePath = ImgPath
                                        else
                                            FxdCtx.FX[FxGUID][v].ImagePath = nil
                                        end

                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                end
                                StyleWinFilter = r.ImGui_CreateTextFilter(FilterText)
                                if FrstSelItm.Type == 'Knob' or (not FrstSelItm.Type and FxdCtx.FX.Def_Type[FxGUID] == 'Knob') then -- if all selected itms are knobs
                                    StyleWinImg = StyleWinImg or {}
                                    StyleWinImgName = StyleWinImgName or {}
                                    local function SetStyle(Name, Style, Img, ImagePath)
                                        if r.ImGui_TextFilter_PassFilter(StyleWinFilter, Name) then
                                            r.ImGui_Text(ctx, Name)
                                            AddKnob(ctx, '##' .. FrstSelItm.Name, '', 0, 0, 1, FItm, FX_Idx,
                                                FrstSelItm.Num, Style, 15, 0, Disabled, 12, Lbl_Pos, V_Pos, Img)
                                            if GF.HighlightHvredItem() then --if clicked on highlighted itm
                                                setItmStyle(Style, Img, ImagePath)
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                            GF.AddSpacing(6)
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
                                    local Dir = CurrentDirectory .. 'src/Images/Knobs'
                                    if r.ImGui_IsWindowAppearing(ctx) then
                                        StyleWindowImgFiles = fs_utils.scandir(Dir)
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

                                    for i, _ in pairs(StyleWinImg) do
                                        local Dir = '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/Knobs/'
                                        SetStyle(StyleWinImgName[i], 'Custom Image', StyleWinImg[i],
                                            Dir .. StyleWinImgName[i])
                                    end
                                end

                                if FrstSelItm.Type == 'Selection' then
                                    local function SetStyle(Name, Style, Width, CustomLbl)
                                        AddCombo(ctx, LT_Track, FX_Idx, Name .. '##' .. FrstSelItm.Name,
                                            FrstSelItm.Num, Options, Width, Style, FxGUID, FxdCtx.LE.Sel_Items
                                            [1],
                                            OptionValues, 'Options', CustomLbl)
                                        if GF.HighlightHvredItem() then
                                            setItmStyle(Style)
                                            r.ImGui_CloseCurrentPopup(ctx)
                                        end
                                        GF.AddSpacing(3)
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
                                FxGUID .. FxdCtx.LE.Sel_Items[1], PosX or FrstSelItm.PosX, FxdCtx.LE.GridSize, 0,
                                Win_W - 10,
                                '%.0f')
                            if EditPosX then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do FxdCtx.FX[FxGUID][v].PosX = PosX end
                            end
                            gui_helpers.SL()
                            r.ImGui_Text(ctx, 'Pos-Y: '); r.ImGui_SameLine(ctx)
                            r.ImGui_SetNextItemWidth(ctx, 80)
                            local EditPosY, PosY = r.ImGui_DragDouble(ctx, ' ##EditPosY' ..
                                FxGUID .. FxdCtx.LE.Sel_Items[1], PosY or FrstSelItm.PosY, FxdCtx.LE.GridSize, 20,
                                210, '%.0f')
                            if EditPosY then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                    FxdCtx.FX[FxGUID][v].PosY =
                                        PosY
                                end
                            end

                            ---Color -----

                            r.ImGui_Text(ctx, 'Color: ')
                            r.ImGui_SameLine(ctx)
                            ClrEdited, PrmBgClr = r.ImGui_ColorEdit4(ctx, '##Clr' .. ID,
                                FrstSelItm.BgClr or r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()),
                                r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                r.ImGui_ColorEditFlags_AlphaBar())
                            if not FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].BgClr or FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]] == r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()) then
                                gui_helpers.HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, W, 0, 0, 'GetItemRect')
                            end
                            if ClrEdited then
                                for _, v in pairs(FxdCtx.LE.Sel_Items) do FxdCtx.FX[FxGUID][v].BgClr = PrmBgClr end
                            end


                            if FrstSelItm.Type ~= 'Switch' and FrstSelItm.Type ~= 'Selection' then
                                r.ImGui_Text(ctx, 'Grab Color: ')
                                r.ImGui_SameLine(ctx)
                                GrbClrEdited, GrbClr = r.ImGui_ColorEdit4(ctx, '##GrbClr' .. ID,
                                    FrstSelItm.GrbClr or r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrab()),
                                    r.ImGui_ColorEditFlags_NoInputs()|    r
                                    .ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                    r.ImGui_ColorEditFlags_AlphaBar())
                                if not FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].GrbClr or FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]].GrbClr == r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrab()) then
                                    gui_helpers.HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, W, 0, 0,
                                        'GetItemRect')
                                end
                                if GrbClrEdited then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].GrbClr = GrbClr
                                    end
                                end
                            end

                            if FrstSelItm.Type == 'Knob' then
                                gui_helpers.SL()
                                r.ImGui_Text(ctx, 'Thickness : ')
                                gui_helpers.SL()
                                r.ImGui_SetNextItemWidth(ctx, 40)
                                local TD, Thick = r.ImGui_DragDouble(ctx,
                                    '##EditValueFontSize' .. FxGUID .. (FxdCtx.LE.Sel_Items[1] or ''),
                                    FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1] or ''].Value_Thick or 2, 0.1, 0.5, 8,
                                    '%.1f')
                                if TD then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].Value_Thick =
                                            Thick
                                    end
                                end
                            end


                            if FrstSelItm.Type == 'Selection' then
                                r.ImGui_SameLine(ctx)
                                r.ImGui_Text(ctx, 'Text Color: ')
                                r.ImGui_SameLine(ctx)
                                local DragLbl_Clr_Edited, V_Clr = r.ImGui_ColorEdit4(ctx,
                                    '##V Clr' .. FxdCtx.LE.Sel_Items[1],
                                    FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1] or ''].V_Clr or
                                    r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                    r.ImGui_ColorEditFlags_NoInputs()|    r
                                    .ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                if DragLbl_Clr_Edited then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do FxdCtx.FX[FxGUID][v].V_Clr = V_Clr end
                                end
                            elseif FrstSelItm.Type == 'Switch' then
                                gui_helpers.SL()
                                r.ImGui_Text(ctx, 'On Color: ')
                                r.ImGui_SameLine(ctx)
                                local DragLbl_Clr_Edited, V_Clr = r.ImGui_ColorEdit4(ctx,
                                    '##Switch on Clr' .. FxdCtx.LE.Sel_Items[1],
                                    FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1] or ''].Switch_On_Clr or 0xffffff55,
                                    r.ImGui_ColorEditFlags_NoInputs()| r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                    r.ImGui_ColorEditFlags_AlphaBar())
                                if DragLbl_Clr_Edited then
                                    for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                        FxdCtx.FX[FxGUID][v].Switch_On_Clr =
                                            V_Clr
                                    end
                                end
                            end

                            ----- Condition to show ------

                            local P = FxdCtx.LE.Sel_Items[1]
                            local fp = FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]] ---@class FX_P




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
                                        for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                            if not FxdCtx.FX[FxGUID][v][ShowCondition] then FxdCtx.FX[FxGUID][v][ShowCondition] = true else FxdCtx.FX[FxGUID][v][ShowCondition] = nil end
                                            FxdCtx.FX[FxGUID][v][ConditionPrm_V] = FxdCtx.FX[FxGUID][v]
                                                [ConditionPrm_V] or {}
                                        end
                                    elseif Mods == Alt then
                                        for i, _ in pairs(FxdCtx.FX[FxGUID][P][ConditionPrm_V]) do
                                            FxdCtx.FX[FxGUID][P][ConditionPrm_V][i] = nil
                                        end
                                        FxdCtx.FX[FxGUID][P][ConditionPrm] = nil
                                        FrstSelItm[ShowCondition] = nil
                                        DeleteAllConditionPrmV = nil
                                    end
                                end

                                if r.ImGui_IsItemHovered(ctx) then
                                    gui_helpers.HintToolTip(
                                        'Alt-Click to Delete All Conditions')
                                end



                                if FrstSelItm[ShowCondition] or FxdCtx.FX[FxGUID][P][ConditionPrm] then
                                    gui_helpers.SL()
                                    if not FxdCtx.FX[FxGUID][P][ConditionPrm_PID] then
                                        for i, _ in ipairs(FxdCtx.FX[FxGUID]) do
                                            if FxdCtx.FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                                FrstSelItm[ConditionPrm_PID] = i
                                            end
                                        end
                                    end
                                    local PID = FxdCtx.FX[FxGUID][P][ConditionPrm_PID] or 1

                                    if r.ImGui_Button(ctx, 'Parameter:##' .. ConditionPrm) then
                                        FxdCtx.FX[FxGUID][P].ConditionPrm = LT_ParamNum
                                        local found
                                        for i, _ in ipairs(FxdCtx.FX[FxGUID]) do
                                            if FxdCtx.FX[FxGUID][i].Num == LT_ParamNum then
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
                                        gui_helpers.tooltip('Click to set to last touched parameter')
                                    end


                                    r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local PrmName, _
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
                                        local FP = FxdCtx.FX[FxGUID][FxdCtx.LE.Sel_Items[1]] ---@class FX_P
                                        --!!!!!! LE.Sel_Items[1] = Fx_P -1 !!!!!! --
                                        Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx,
                                            'ConditionPrm' .. FP.ConditionPrm .. (PrmName or '') .. '1## CP',
                                            FxdCtx.FX[FxGUID][P][ConditionPrm] or 0,
                                            FxdCtx.FX[FxGUID][PID].ManualValuesFormat or 'Get Options', -R_ofs,
                                            Style,
                                            FxGUID, PID, FxdCtx.FX[FxGUID][PID].ManualValues,
                                            FxdCtx.FX[FxGUID][P][ConditionPrm_V][1] or 'Unassigned', nil,
                                            'No Lbl')

                                        if Value_Selected then
                                            for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                                FxdCtx.FX[FxGUID][v][ConditionPrm_V] = FxdCtx.FX[FxGUID][v]
                                                    [ConditionPrm_V] or
                                                    {}
                                                FxdCtx.FX[FxGUID][v][ConditionPrm_V_Norm] = FxdCtx.FX[FxGUID][v]
                                                    [ConditionPrm_V_Norm] or {}
                                                FxdCtx.FX[FxGUID][v][ConditionPrm_V][1] = V_Formatted
                                                FxdCtx.FX[FxGUID][v][ConditionPrm_V_Norm][1] = r
                                                    .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                        fp[ConditionPrm])
                                            end
                                        end
                                        if not FxdCtx.FX[FxGUID][P][ConditionPrm_V][1] then
                                            FxdCtx.FX[FxGUID][P][ConditionPrm_V][1] = ''
                                        end

                                        if FxdCtx.FX[FxGUID][P][ConditionPrm_V] then
                                            if FxdCtx.FX[FxGUID][P][ConditionPrm_V][2] then
                                                for i, v in pairs(FxdCtx.FX[FxGUID][P][ConditionPrm_V]) do
                                                    if i > 1 then
                                                        r.ImGui_Text(ctx, 'or at value:')
                                                        r.ImGui_SameLine(ctx)
                                                        local Value_Selected, V_Formatted = AddCombo(ctx,
                                                            LT_Track,
                                                            FX_Idx, 'CondPrmV' .. (PrmName or '') .. v ..
                                                            ConditionPrm, FxdCtx.FX[FxGUID][P][ConditionPrm] or 0,
                                                            FxdCtx.FX[FxGUID][PID].ManualValuesFormat or
                                                            'Get Options',
                                                            -R_ofs, Style, FxGUID, PID,
                                                            FxdCtx.FX[FxGUID][PID].ManualValues,
                                                            v, nil, 'No Lbl')
                                                        if Value_Selected then
                                                            for _, v in pairs(FxdCtx.LE.Sel_Items) do
                                                                FxdCtx.FX[FxGUID][v][ConditionPrm_V][i] =
                                                                    V_Formatted
                                                                FxdCtx.FX[FxGUID][v][ConditionPrm_V_Norm][i] = r
                                                                    .TrackFX_GetParamNormalized(LT_Track,
                                                                        FX_Idx,
                                                                        FxdCtx.FX[FxGUID][P][ConditionPrm])
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        if r.ImGui_Button(ctx, ' + or at value:##' .. ConditionPrm) then
                                            FxdCtx.FX[FxGUID][P][ConditionPrm_V] = FxdCtx.FX[FxGUID][P]
                                                [ConditionPrm_V] or {}
                                            table.insert(FxdCtx.FX[FxGUID][P][ConditionPrm_V], '')
                                        end
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, 120)
                                        if r.ImGui_BeginCombo(ctx, '##- delete value ' .. ConditionPrm, '- delete value', r.ImGui_ComboFlags_NoArrowButton()) then
                                            for i, v in pairs(FxdCtx.FX[FxGUID][P][ConditionPrm_V]) do
                                                if r.ImGui_Selectable(ctx, v or '##', i) then
                                                    table.remove(FxdCtx.FX[FxGUID][P][ConditionPrm_V], i)
                                                    if not FxdCtx.FX[FxGUID][P][ConditionPrm_V][1] then
                                                        FxdCtx.FX[FxGUID][P][ConditionPrm] = nil
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

                                    gui_helpers.SL()
                                    r.ImGui_Text(ctx, ' Type : ')
                                    gui_helpers.SL()
                                    r.ImGui_SetNextItemWidth(ctx, 100)


                                    local D = FrstSelItm.Draw[i]
                                    local LBL = FxGUID .. FxdCtx.LE.Sel_Items[1] .. i
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
                                        AddOption('Gain Reduction Text')


                                        r.ImGui_EndCombo(ctx)
                                    end

                                    gui_helpers.SL()
                                    if r.ImGui_Button(ctx, 'Delete##' .. i) then
                                        RemoveDraw = i
                                    end



                                    if rv then
                                        local BL_Width = { 'Knob Pointer', 'Knob Range', 'Gain Reduction Text' }
                                        local BL_Height = { 'Knob Pointer', 'Knob Range', 'Circle',
                                            'Circle Filled', 'Knob Circle', 'Knob Image', 'Gain Reduction Text' }
                                        local Thick = { 'Knob Pointer', 'Line', 'Rect', 'Circle' }
                                        local Round = { 'Rect', 'Rect Filled' }
                                        local Gap = { 'Circle', 'Circle Filled', 'Knob Range' }
                                        local BL_XYGap = { 'Knob Pointer', 'Knob Range', 'Knob Circle',
                                            'Knob Image' }
                                        local RadiusInOut = { 'Knob Pointer', 'Knob Range' }
                                        local Radius = { 'Knob Circle', 'Knob Image' }
                                        local BL_Repeat = { 'Knob Range', 'Knob Circle', 'Knob Image',
                                            'Knob Pointer', 'Gain Reduction Text' }





                                        if D.Type == 'Image' or D.Type == 'Knob Image' then
                                            if r.ImGui_BeginChildFrame(ctx, '##drop_files', -R_ofs, 25) then
                                                if D.Image then
                                                    if images_fonts.TrashIcon(13, 'Image Delete', ClrBG, ClrTint) then
                                                        D.Image, D.FilePath = nil
                                                    end
                                                    gui_helpers.SL()
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
                                                        local _, filename = r.ImGui_GetDragDropPayloadFile(ctx,
                                                            i)


                                                        path, D.FilePath = fs_utils.CopyImageFile(filename,
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



                                        if r.ImGui_BeginTable(ctx, 'Attached Drawing Properties', 3, flags, -R_ofs) then
                                            local function SetRowName(str, notTAB, TAB)
                                                r.ImGui_TableSetColumnIndex(ctx, 0)
                                                if TAB then
                                                    if table_helpers.FindExactStringInTable(TAB, D.Type) then
                                                        r.ImGui_Text(ctx, str)
                                                        return true
                                                    end
                                                elseif notTAB then
                                                    if not table_helpers.FindExactStringInTable(notTAB, D.Type) then
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
                                                if not D[Name .. '_GR'] and not D[Name] and not defaultV then
                                                    FORMAT =
                                                    ''
                                                end

                                                local rv, V = r.ImGui_DragDouble(ctx, '##' .. Name .. LBL,
                                                    D[Name .. '_GR'] or D[Name] or defaultV,
                                                    stepSize or FxdCtx.LE.GridSize, min or -W,
                                                    max or W - 10, FORMAT)

                                                if rv and not D[Name .. '_GR'] then
                                                    D[Name] = V
                                                elseif rv and D[Name .. '_GR'] then
                                                    D[Name .. '_GR'] = V; D[Name] = nil
                                                end

                                                -- if want to show preview use this.
                                                --if r.ImGui_IsItemActive(ctx) then FrstSelItm.ShowPreview = FrstSelItm.Num end



                                                if FrstSelItm.ShowPreview and r.ImGui_IsItemDeactivated(ctx) then FrstSelItm.ShowPreview = nil end

                                                r.ImGui_PopItemWidth(ctx)
                                                if Name:find('_VA') then
                                                    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                                                        r.ImGui_OpenPopup(ctx, 'Value afftect ' .. Name)
                                                    end
                                                end

                                                if r.ImGui_BeginPopup(ctx, 'Value afftect ' .. Name) then
                                                    local rv, _ = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx,
                                                        'GainReduction_dB')
                                                    if not rv then r.ImGui_BeginDisabled(ctx) end

                                                    if D[Name .. '_GR'] then D.check = true end
                                                    Check, D.check = r.ImGui_Checkbox(ctx,
                                                        'Affected by Gain Reduction', D.check)
                                                    if Check then
                                                        if D[Name .. '_GR'] then D[Name .. '_GR'] = nil else D[Name .. '_GR'] = 0 end
                                                    end
                                                    if not rv then r.ImGui_EndDisabled(ctx) end
                                                    r.ImGui_EndPopup(ctx)
                                                end

                                                if Name:find('_VA') or NextRow then r.ImGui_TableNextRow(ctx) end

                                                return r.ImGui_IsItemActive(ctx)
                                            end


                                            r.ImGui_TableSetupColumn(ctx, '##')
                                            r.ImGui_TableSetupColumn(ctx, 'Values')
                                            r.ImGui_TableSetupColumn(ctx, 'Affected Amount')
                                            r.ImGui_TableNextRow(ctx, r.ImGui_TableRowFlags_Headers())





                                            r.ImGui_TableHeadersRow(ctx)


                                            r.ImGui_TableNextRow(ctx)

                                            local WidthLBL, WidthStepSize = 'Width: ', FxdCtx.LE.GridSize
                                            if D.Type == 'Circle' or D.Type == 'Cicle Filled' then
                                                WidthLBL = 'Size'; WidthStepSize = 1
                                            end




                                            SetRowName('X offset')
                                            AddVal('X_Offset', 0, FxdCtx.LE.GridSize, min, max, nil)
                                            AddVal('X_Offset_VA')
                                            SetRowName('Y offset')
                                            AddVal('Y_Offset', 0, FxdCtx.LE.GridSize, -220, 220, nil)
                                            AddVal('Y_Offset_VA')
                                            if SetRowName(WidthLBL, BL_Width) then
                                                AddVal('Width', nil, WidthStepSize, min, max, nil)
                                                AddVal('Width_VA', 0, 0.01, -1, 1)
                                            end --[[ local rv, R =  AddRatio('Width' ) if rv then D.Width = R end   ]]
                                            if SetRowName('Height', BL_Height) then
                                                AddVal('Height', 0, FxdCtx.LE.GridSize, -220, 220, nil)
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
                        if FxdCtx.LE.SelectedItem == 'Title' then
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x66666688)

                            r.ImGui_Text(ctx, 'Edge Round:')
                            r.ImGui_SameLine(ctx)
                            Edited, FxdCtx.FX[FxGUID].Round = r.ImGui_DragDouble(ctx, '##' .. FxGUID .. 'Round',
                                FxdCtx.FX[FxGUID].Round, 0.01, 0, 40, '%.2f')

                            r.ImGui_Text(ctx, 'Grab Round:')
                            r.ImGui_SameLine(ctx)
                            Edited, FxdCtx.FX[FxGUID].GrbRound = r.ImGui_DragDouble(ctx,
                                '##' .. FxGUID .. 'GrbRound',
                                FxdCtx.FX[FxGUID].GrbRound, 0.01, 0, 40, '%.2f')

                            r.ImGui_Text(ctx, 'Background Color:')
                            r.ImGui_SameLine(ctx)
                            _, FxdCtx.FX[FxGUID].BgClr = r.ImGui_ColorEdit4(ctx, '##' .. FxGUID .. 'BgClr',
                                FxdCtx.FX[FxGUID].BgClr or FX_Devices_Bg or 0x151515ff,
                                r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                r.ImGui_ColorEditFlags_AlphaBar())
                            if FxdCtx.FX[FxGUID].BgClr == r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()) then
                                gui_helpers.HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, W, 1, 1, 'GetItemRect')
                            end

                            r.ImGui_Text(ctx, 'FX Title Color:')
                            r.ImGui_SameLine(ctx)
                            _, FxdCtx.FX[FxGUID].TitleClr = r.ImGui_ColorEdit4(ctx, '##' .. FxGUID .. 'Title Clr',
                                FxdCtx.FX[FxGUID].TitleClr or 0x22222233,
                                r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                r.ImGui_ColorEditFlags_AlphaBar())

                            r.ImGui_Text(ctx, 'Custom Title:')
                            r.ImGui_SameLine(ctx)
                            local _, CustomTitle = r.ImGui_InputText(ctx, '##CustomTitle' .. FxGUID,
                                FxdCtx.FX[FxGUID].CustomTitle or FX_Name)
                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                FxdCtx.FX[FxGUID].CustomTitle = CustomTitle
                            end

                            r.ImGui_PopStyleColor(ctx)
                        end








                        if r.ImGui_BeginPopupModal(ctx, 'Save Editing?') then
                            SaveEditingPopupModal = true
                            r.ImGui_Text(ctx, 'Would you like to save the editings?')
                            if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                                r.ImGui_CloseCurrentPopup(ctx)
                                FxdCtx.FX.LayEdit = nil
                                FxdCtx.LE.SelectedItem = nil
                                CloseLayEdit = true
                            end
                            r.ImGui_SameLine(ctx)

                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                SaveLayoutEditings(FX_Name, FX_Idx, FxGUID)
                                r.ImGui_CloseCurrentPopup(ctx)
                                FxdCtx.FX.LayEdit = nil
                                FxdCtx.LE.SelectedItem = nil
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
                            W, h = r.ImGui_GetWindowSize(ctx)
                            r.ImGui_SetCursorPos(ctx, W - PalletteW - Pad, PalletteW + Pad)
                        end




                        for Pal = 1, NumOfColumns or 1, 1 do
                            if not CloseLayEdit and r.ImGui_BeginChildFrame(ctx, 'Color Palette' .. Pal, PalletteW, h - PalletteW - Pad * 2, r.ImGui_WindowFlags_NoScrollbar()) then
                                for _, v in ipairs(FxdCtx.FX[FxGUID]) do
                                    local function CheckClr(Clr)
                                        if Clr and not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId()) then
                                            if not table_helpers.tablefind(FxdCtx.ClrPallet, Clr) and FxdCtx.ClrPallet then
                                                local _, _, _, A = r.ImGui_ColorConvertU32ToDouble4(Clr)
                                                if A ~= 0 then
                                                    table.insert(FxdCtx.ClrPallet, Clr)
                                                end
                                            end
                                        end
                                    end
                                    CheckClr(v.Lbl_Clr)
                                    CheckClr(v.V_Clr)
                                    CheckClr(v.BgClr)
                                    CheckClr(v.GrbClr)
                                end

                                if FxdCtx.FX.Win_Name_S[FX_Idx] then
                                    if FxdCtx.Draw[FxdCtx.FX.Win_Name_S[FX_Idx]] then
                                        for _, v in ipairs(FxdCtx.Draw[FxdCtx.FX.Win_Name_S[FX_Idx]].clr) do
                                            local Clr = v
                                            if Clr and not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId()) then
                                                if not table_helpers.tablefind(FxdCtx.ClrPallet, Clr) and FxdCtx.ClrPallet then
                                                    table.insert(FxdCtx.ClrPallet, Clr)
                                                end
                                            end
                                        end
                                    end
                                end

                                for i, v in ipairs(FxdCtx.ClrPallet) do
                                    Clrpick, LblColor1 = r.ImGui_ColorEdit4(ctx, '##ClrPalette' .. Pal ..
                                        i .. FxGUID, v,
                                        r.ImGui_ColorEditFlags_NoInputs()|
                                        r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                        table.remove(FxdCtx.ClrPallet, table_helpers.tablefind(v))
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
                                for _ = 1, NumOfColumns, 1 do r.ImGui_SameLine(ctx, nil, 0) end
                            end
                        end





                        if r.ImGui_BeginPopupModal(ctx, 'Save Draw Editing?') then
                            r.ImGui_Text(ctx, 'Would you like to save the Drawings?')
                            if r.ImGui_Button(ctx, '(n) No') then
                                local FxNameS = FxdCtx.FX.Win_Name_S[FX_Idx]
                                local HowManyToDelete
                                for i, _ in pairs(FxdCtx.Draw[FxNameS].Type) do
                                    HowManyToDelete = i
                                end

                                for _ = 1, HowManyToDelete, 1 do
                                    local D = FxdCtx.Draw[FxNameS]
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
                                FxdCtx.Draw.DrawMode[FxGUID] = nil
                            end
                            r.ImGui_SameLine(ctx)

                            if r.ImGui_Button(ctx, '(y) Yes') then
                                GF.SaveDrawings(FX_Idx, FxGUID)
                                r.ImGui_CloseCurrentPopup(ctx)
                                FxdCtx.Draw.DrawMode[FxGUID] = nil
                            end
                            r.ImGui_EndPopup(ctx)
                        end



                        if r.ImGui_IsKeyPressed(ctx, 65) and (Mods == Apl or Mods == Alt) then
                            for Fx_P = 1, #FxdCtx.FX[FxGUID] or 0, 1 do table.insert(FxdCtx.LE.Sel_Items, Fx_P) end
                        end


                        r.ImGui_End(ctx)
                        if CloseLayEdit then
                            FxdCtx.FX.LayEdit = nil
                            FxdCtx.Draw.DrawMode[FxGUID] = nil
                        end
                    end





                    r.ImGui_SameLine(ctx, nil, 0)
                    --r.ImGui_PushStyleVar( ctx,r.ImGui_StyleVar_WindowPadding(), 0,0)
                    --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0x00000000)



                    --if ctrl+A or Command+A is pressed


                    --r.ImGui_EndTooltip(ctx)

                    -- r.ImGui_PopStyleVar(ctx)
                    --r.ImGui_PopStyleColor(ctx,2 )
                    GF.PopClr(ctx, 2)
                end

                if AdjustDrawRectPos and IsLBtnHeld then
                    Mx, My = r.ImGui_GetMousePos(ctx)
                    FDL = r.ImGui_GetForegroundDrawList(ctx)

                    r.ImGui_DrawList_AddRectFilled(FDL, FxdCtx.Draw.Rect.L, FxdCtx.Draw.Rect.T,
                        FxdCtx.Draw.Rect.R, FxdCtx.Draw.Rect.B,
                        0xbbbbbb66)
                else
                    AdjustDrawRectPos = nil
                end

                if FxdCtx.Draw.Rect.L then
                    r.ImGui_DrawList_AddRectFilled(FDL, FxdCtx.Draw.Rect.L, FxdCtx.Draw.Rect.T,
                        FxdCtx.Draw.Rect.R,
                        FxdCtx.Draw.Rect.B, 0xbbbbbb66, FxdCtx.FX[FxGUID].Draw.Df_EdgeRound or 0)
                end
            elseif --[[FX Layer Window ]] string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then --!!!!  FX Layer Window
                if not FxdCtx.FX[FxGUID].Collapse then
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
                            FxdCtx.FX[FxGUID].DeleteFXLayer = true
                        elseif r.ImGui_IsItemClicked(ctx, 1) then
                            FxdCtx.FX[FxGUID].Collapse = true
                            FxdCtx.FX[FxGUID].CollapseWidth = 27
                        elseif r.ImGui_IsItemClicked(ctx) and Mods == Shift then
                            if FxdCtx.FX[FxGUID].LyrDisable == nil then FxdCtx.FX[FxGUID].LyrDisable = false end
                            FxdCtx.FX[FxGUID].AldreadyBPdFXs = FxdCtx.FX[FxGUID].AldreadyBPdFXs or {}





                            for i = 0, Sel_Track_FX_Count, 1 do
                                if FxdCtx.FX.InLyr[FxdCtx.FXGUID[i]] == FxdCtx.FXGUID[FX_Idx] then
                                    if not FxdCtx.FX[FxGUID].LyrDisable then
                                        if r.TrackFX_GetEnabled(LT_Track, i) == false then
                                            if FxdCtx.FX[FxGUID].AldreadyBPdFXs == {} then
                                                table.insert(FxdCtx.FX[FxGUID].AldreadyBPdFXs,
                                                    r.TrackFX_GetFXGUID(LT_Track, i))
                                            elseif not table_helpers.FindStringInTable(FxdCtx.FX[FxGUID].AldreadyBPdFXs, r.TrackFX_GetFXGUID(LT_Track, i)) then
                                                table.insert(FxdCtx.FX[FxGUID].AldreadyBPdFXs,
                                                    r.TrackFX_GetFXGUID(LT_Track, i))
                                            end
                                        else
                                        end
                                        r.TrackFX_SetEnabled(LT_Track, i, false)
                                    else
                                        r.TrackFX_SetEnabled(LT_Track, i, true)
                                    end

                                    for _, v in pairs(FxdCtx.FX[FxGUID].AldreadyBPdFXs) do
                                        if v == FxdCtx.FXGUID[i] then r.TrackFX_SetEnabled(LT_Track, i, false) end
                                    end
                                end
                            end


                            if not FxdCtx.FX[FxGUID].LyrDisable then
                                r.TrackFX_SetEnabled(LT_Track, FX_Idx, false)
                            else
                                r.TrackFX_SetEnabled(LT_Track, FX_Idx, true)
                                FxdCtx.FX[FxGUID].AldreadyBPdFXs = {}
                            end

                            if FxdCtx.FX[FxGUID].LyrDisable then FxdCtx.FX[FxGUID].LyrDisable = false else FxdCtx.FX[FxGUID].LyrDisable = true end
                        end


                        if not FXLayerRenaming then
                            if LBtnClickCount == 2 and r.ImGui_IsItemActivated(ctx) then
                                FxdCtx.FX[FxGUID].RenameFXLayering = true
                            elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                                BlinkFX = state_helpers.ToggleCollapseAll(FX_Idx)
                            end
                        end


                        r.ImGui_SameLine(ctx)
                        r.ImGui_AlignTextToFramePadding(ctx)
                        if not FxdCtx.FX[FxGUID].RenameFXLayering then
                            r.ImGui_SetNextItemWidth(ctx, 10)
                            local TitleShort
                            if string.len(FxdCtx.FX[FxGUID].ContainerTitle or '') > 27 then
                                TitleShort = string.sub(FxdCtx.FX[FxGUID].ContainerTitle, 1, 27)
                            end
                            r.ImGui_Text(ctx, TitleShort or FxdCtx.FX[FxGUID].ContainerTitle or 'FX Layering')
                        else -- If Renaming
                            local Flag
                            r.ImGui_SetNextItemWidth(ctx, 180)
                            if FxdCtx.FX[FxGUID].ContainerTitle == 'FX Layering' then
                                Flag = r
                                    .ImGui_InputTextFlags_AutoSelectAll()
                            end
                            _, FxdCtx.FX[FxGUID].ContainerTitle = r.ImGui_InputText(ctx, '##' .. FxGUID,
                                FxdCtx.FX[FxGUID].ContainerTitle or 'FX Layering', Flag)

                            r.ImGui_SetItemDefaultFocus(ctx)
                            r.ImGui_SetKeyboardFocusHere(ctx, -1)

                            if r.ImGui_IsItemDeactivated(ctx) then
                                FxdCtx.FX[FxGUID].RenameFXLayering = nil
                                r.SetProjExtState(0, 'FX Devices - ', 'FX' .. FxGUID ..
                                    'FX Layer Container Title ', FxdCtx.FX[FxGUID].ContainerTitle)
                            end
                        end

                        --r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(), 0xffffff10)

                        r.ImGui_SameLine(ctx, FXLayeringWin_X - 25, 0)
                        r.ImGui_AlignTextToFramePadding(ctx)
                        if not FxdCtx.FX[FxGUID].SumMode then
                            FxdCtx.FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)
                        end
                        local Lbl
                        if FxdCtx.FX[FxGUID].SumMode == 0 then Lbl = 'Avg' else Lbl = 'Sum' end
                        if r.ImGui_Button(ctx, (Lbl or '') .. '##FX Lyr Mode' .. FxGUID, 30, r.ImGui_GetTextLineHeight(ctx)) then
                            FxdCtx.FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)

                            if FxdCtx.FX[FxGUID].SumMode == 0 then
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 1)
                                FxdCtx.FX[FxGUID].SumMode = 1
                            else
                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 0)
                                FxdCtx.FX[FxGUID].SumMode = 0
                            end
                        end

                        --r.ImGui_PopStyleColor(ctx)
                        r.ImGui_PopStyleVar(ctx)

                        r.ImGui_EndTable(ctx)
                        r.ImGui_PopStyleColor(ctx, 2) --Header Clr
                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 0)
                        --r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgActive(), 0x99999999)
                        local StyleVarPop = 1


                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)



                        local MaxChars

                        if FxdCtx.FX[FxGUID].ActiveLyrCount <= 4 then
                            LineH = 4; Spacing = 0; Inner_Spacing = 2; BtnSizeManual = 34; MaxChars = 15
                        elseif FxdCtx.FX[FxGUID].ActiveLyrCount == 5 then
                            LineH, Spacing, Inner_Spacing = 3, -5, 0; BtnSizeManual = 30; MaxChars = 18
                        elseif FxdCtx.FX[FxGUID].ActiveLyrCount == 6 then
                            LineH, Spacing, Inner_Spacing = 5.5, -5, -8; BtnSizeManual = 24; MaxChars = 20
                        elseif FxdCtx.FX[FxGUID].ActiveLyrCount >= 7 then
                            LineH, Spacing, Inner_Spacing = 3, -5, -8; BtnSizeManual = 19; MaxChars = 23
                        end



                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 1, Spacing)
                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4, LineH)

                        local _, AnySoloChan
                        for _, LyrID in pairs(FxdCtx.FX[FxGUID].LyrID) do
                            if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == 1 then
                                FxdCtx.FX[FxGUID].AnySoloChan = true
                                AnySoloChan = true
                            end
                        end
                        if not AnySoloChan then FxdCtx.FX[FxGUID].AnySoloChan = nil end


                        for LayerNum, LyrID in pairs(FxdCtx.FX[FxGUID].LyrID) do
                            if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == nil then
                                FxdCtx.Lyr.Solo[LyrID .. FxGUID] = reaper
                                    .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)))
                            end
                            if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == 1 then FxdCtx.FX[FxGUID].AnySoloChan = true end
                            if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == nil then
                                FxdCtx.Lyr.Mute[LyrID .. FxGUID] = reaper
                                    .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                            end
                            if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == 1 then FxdCtx.FX[FxGUID].AnyMuteChan = true end

                            if FxdCtx.Lyr.ProgBarVal[LyrID .. FxGUID] == nil then
                                Layer1Vol = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                                FxdCtx.Lyr.ProgBarVal[LyrID .. FxGUID] = Layer1Vol
                            end

                            LyrFX_Inst = math.max(LyrFX_Inst or 0, LyrID)
                            local HowManyFXinLyr = 0
                            for i = 0, Sel_Track_FX_Count, 1 do
                                if FxdCtx.FX.InLyr[FxdCtx.FXGUID[i]] == FXGUID_RackMixer and FxdCtx.FX[FxdCtx.FXGUID[i]].inWhichLyr == LyrID then
                                    HowManyFXinLyr = HowManyFXinLyr + 1
                                end
                            end


                            local Fx_P = (LyrID * 2) - 1

                            local CurY = r.ImGui_GetCursorPosY(ctx)
                            if FxdCtx.FX[FxGUID][Fx_P] then
                                LyrCurX, LyrCurY = r.ImGui_GetCursorScreenPos(ctx)

                                if FxdCtx.Lyr.Rename[LyrID .. FxGUID] ~= true and Fx_P then
                                    --r.ImGui_ProgressBar(ctx, Lyr.ProgBarVal[LyrID..FxGUID], FXLayeringWin_X-60, 30, '##Layer'.. LyrID)
                                    local P_Num = 1 + (5 * (LyrID - 1))
                                    local ID = LyrID
                                    FxdCtx.FX[FxGUID].LyrTitle = FxdCtx.FX[FxGUID].LyrTitle or {}

                                    local labeltoShow = FxdCtx.FX[FxGUID].LyrTitle[ID] or LyrID

                                    if string.len(labeltoShow or '') > MaxChars then
                                        labeltoShow = string.sub(FxdCtx.FX[FxGUID].LyrTitle[ID], 1, MaxChars)
                                    end
                                    local Fx_P = LyrID * 2 - 1
                                    local Label = '##' .. LyrID .. FxGUID
                                    FxdCtx.FX[FxGUID][Fx_P] = FxdCtx.FX[FxGUID][Fx_P] or {}
                                    FxdCtx.FX[FxGUID][Fx_P].V = FxdCtx.FX[FxGUID][Fx_P].V or 0.5
                                    local p_value = FxdCtx.FX[FxGUID][Fx_P].V or 0
                                    --[[ r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, BtnSizeManual/3) ]]
                                    --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), getClr(r.ImGui_Col_Button())) ]]
                                    SliderStyle = nil; Rounding = 0
                                    local CurY = r.ImGui_GetCursorPosY(ctx)
                                    AddDrag(ctx, Label, labeltoShow, p_value, 0, 1, Fx_P, FX_Idx, P_Num,
                                        'FX Layering', FXLayeringWin_X - BtnSizeManual * 3 - 23, Inner_Spacing,
                                        Disable, Lbl_Clickable, 'Bottom', 'Bottom', DragDir, 'NoInput')
                                    --[[ r.ImGui_PopStyleColor(ctx)  r.ImGui_PopStyleVar(ctx) ]]

                                    local L, T = r.ImGui_GetItemRectMin(ctx); B = T + BtnSizeManual
                                    r.ImGui_SameLine(ctx, nil, 10)
                                    r.ImGui_SetCursorPosY(ctx, CurY)

                                    if FxdCtx.Lyr.Selected[FXGUID_RackMixer] == LyrID then
                                        local R = L + FXLayeringWin_X
                                        r.ImGui_DrawList_AddLine(WDL, L, T - 2, R - 2 + Pad, T - 2, 0x99999999)
                                        r.ImGui_DrawList_AddLine(WDL, L, B, R - 2 + Pad, B, 0x99999999)
                                        r.ImGui_DrawList_AddRectFilled(WDL, L, T - 2, R + Pad, B, 0xffffff09)
                                        FxdCtx.FX[FxGUID].TheresFXinLyr = nil
                                        for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                            if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]] then
                                                if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].inWhichLyr == LyrID and FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                    r.ImGui_DrawList_AddLine(WDL, R - 2 + Pad, T, R - 2 + Pad,
                                                        FXLayerFrame_PosY_T, 0x99999999)
                                                    r.ImGui_DrawList_AddLine(WDL, R - 2 + Pad, B, R - 2 + Pad,
                                                        FXLayerFrame_PosY_B, 0x99999999)
                                                    FxdCtx.FX[FxGUID].TheresFXinLyr = true
                                                end
                                            end
                                        end
                                        if not FxdCtx.FX[FxGUID].TheresFXinLyr then
                                            r.ImGui_DrawList_AddLine(WDL, R, T, R, B, 0x99999999)
                                        else
                                        end
                                    end

                                    if r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                        local TheresFXinLyr
                                        for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                            if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].inWhichLyr == FxdCtx.FX[FXGUID_RackMixer].LyrID[LyrID] and FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                TheresFXinLyr = true
                                            end
                                        end

                                        FX_Idx_RackMixer = FX_Idx
                                        function DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                            FxdCtx.FX[FxGUID].LyrID[LyrID] = -1
                                            FxdCtx.FX[FxGUID].LyrTitle[LyrID] = nil
                                            FxdCtx.FX[FxGUID].ActiveLyrCount = math.max(
                                                FxdCtx.FX[FxGUID].ActiveLyrCount - 1, 1)
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
                                                FxdCtx.VP.x + FxdCtx.VP.w / 2 - Modalw / 2,
                                                FxdCtx.VP.y + FxdCtx.VP.h / 2 - Modalh / 2)
                                            r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                            r.ImGui_OpenPopup(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' ..
                                                FxGUID)
                                        end
                                    elseif r.ImGui_IsItemClicked(ctx) and LBtnDC then
                                        FxdCtx.FX[FxGUID][Fx_P].V = 0.5
                                        local _ = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num,
                                            0.5)
                                    elseif r.ImGui_IsItemClicked(ctx) and Mods == Ctrl and not FXLayerRenaming then
                                        FxdCtx.Lyr.Rename[LyrID .. FxGUID] = true
                                    elseif r.ImGui_IsItemClicked(ctx) and Mods == 0 then
                                        FxdCtx.Lyr.Selected[FXGUID_RackMixer] = LyrID
                                    end
                                elseif FxdCtx.Lyr.Rename[LyrID .. FxGUID] == true then
                                    for i = 1, 8, 1 do -- set all other layer's rename to false
                                        if LyrID ~= i then FxdCtx.Lyr.Rename[i .. FxGUID] = false end
                                    end
                                    FXLayerRenaming = true
                                    r.ImGui_SetKeyboardFocusHere(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, FXLayeringWin_X - BtnSizeManual * 3 - 23)
                                    local ID = FxdCtx.FX[FxGUID].LyrID[LyrID]
                                    FxdCtx.FX[FxGUID].LyrTitle = FxdCtx.FX[FxGUID].LyrTitle or {}
                                    _, FxdCtx.FX[FxGUID].LyrTitle[ID] = r.ImGui_InputText(ctx, '##' .. LyrID,
                                        FxdCtx.FX[FxGUID].LyrTitle[ID])

                                    if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                        FxdCtx.Lyr.Rename[LyrID .. FxGUID] = false
                                        FXLayerRenaming = nil
                                        r.SetProjExtState(0, 'FX Devices - ', 'FX' ..
                                            FxGUID .. 'Layer Title ' .. LyrID, FxdCtx.FX[FxGUID].LyrTitle[ID])
                                    elseif r.ImGui_IsItemDeactivated(ctx) then
                                        FxdCtx.Lyr.Rename[LyrID .. FxGUID] = false
                                        FXLayerRenaming = nil
                                    end
                                    gui_helpers.SL(nil, 10)
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
                                            if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].inWhichLyr == FxdCtx.FX[FXGUID_RackMixer].LyrID[LyrID] and FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                HowMany = HowMany + 1
                                                L = math.min(FX_Idx, L)
                                                H = math.max(FX_Idx, H)
                                            end
                                        end

                                        for _ = 1, HowMany, 1 do
                                            if FxdCtx.FX[FxdCtx.FXGUID[L]].inWhichLyr == FxdCtx.FX[FXGUID_RackMixer].LyrID[LyrID] and FxdCtx.FX.InLyr[FxdCtx.FXGUID[L]] == FXGUID_RackMixer then
                                                r.TrackFX_Delete(LT_Track, L)
                                            end
                                        end
                                        DeleteOneLayer(LyrID, FXGUID_RackMixer, FX_Idx_RackMixer, LT_Track)

                                        Diff = H - L + 1
                                        r.Undo_EndBlock('Delete Layer ' .. LyrID, 0)
                                    end
                                    r.ImGui_EndPopup(ctx)
                                end




                                ProgBar_Pos_L, ProgBar_PosY_T = r.ImGui_GetItemRectMin(ctx)
                                ProgBar_Pos_R, ProgBar_PosY_B = r.ImGui_GetItemRectMax(ctx)





                                if FxdCtx.Lyr.Selected[FXGUID_RackMixer] == LyrID and FxdCtx.Lyr.Rename[LyrID .. FxGUID] ~= true then
                                    r.ImGui_DrawList_AddRect(Drawlist, ProgBar_Pos_L, ProgBar_PosY_T,
                                        FXLayerFrame_PosX_R, ProgBar_PosY_B, 0xffffffff)
                                end

                                DrawlistInFXLayering = r.ImGui_GetForegroundDrawList(ctx)


                                if r.ImGui_BeginDragDropTarget(ctx) then
                                    Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag') --

                                    if Dropped and Mods == 0 then
                                        DropFXtoLayer(FX_Idx, LayerNum)
                                    elseif Dropped and Mods == Apl then
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
                                        Dropped, Payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX') --
                                        if Dropped then
                                            r.TrackFX_AddByName(LT_Track, Payload, false, -1000 - FX_Idx)

                                            DropFXtoLayer(FX_Idx, LyrID)
                                        end
                                    end

                                    gui_helpers.HighlightSelectedItem(0x88888844, 0xffffffff, 0, L, T, R, B, h, W,
                                        H_OutlineSc, V_OutlineSc, 'GetItemRect')
                                    r.ImGui_EndDragDropTarget(ctx)
                                end


                                local P_Num = 1 + (5 * (LyrID - 1) + 1)
                                local Fx_P_Knob = LyrID * 2
                                local Label = '## Pan' .. LyrID .. FxGUID
                                local p_value_Knob = FxdCtx.FX[FxGUID][Fx_P_Knob].V
                                local labeltoShow = HowManyFXinLyr



                                AddKnob(ctx, Label, labeltoShow, p_value_Knob, 0, 1, Fx_P_Knob, FX_Idx, P_Num,
                                    'FX Layering', BtnSizeManual / 2, 0, Disabled, 9, 'Within', 'None')
                                r.ImGui_SameLine(ctx, nil, 10)

                                if LBtnDC and r.ImGui_IsItemClicked(ctx, 0) then
                                    FxdCtx.FX[FxGUID][Fx_P_Knob].V = 0.5
                                    local _ = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0.5)
                                end

                                r.ImGui_SetCursorPosY(ctx, CurY)

                                if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == 1 then
                                    local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                    local Act, Hvr = GF.Generate_Active_And_Hvr_CLRs(Clr)
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Clr)
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Act)
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Hvr)

                                    SoloBtnClrPop = 3
                                end

                                ClickOnSolo = r.ImGui_Button(ctx, 'S##' .. LyrID, BtnSizeManual, BtnSizeManual) -- ==  lyr solo

                                if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == 1 then
                                    r.ImGui_PopStyleColor(ctx,
                                        SoloBtnClrPop)
                                end


                                if ClickOnSolo then
                                    FxdCtx.Lyr.Solo[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                        LT_Track,
                                        FX_Idx, 4 + (5 * (LyrID - 1)))
                                    if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == 1 then
                                        FxdCtx.Lyr.Solo[LyrID .. FxGUID] = 0
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                            4 + (5 * (LyrID - 1)),
                                            FxdCtx.Lyr.Solo[LyrID .. FxGUID])
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x9ed9d3ff)
                                        r.ImGui_PopStyleColor(ctx)
                                    elseif FxdCtx.Lyr.Solo[LyrID .. FxGUID] == 0 then
                                        FxdCtx.Lyr.Solo[LyrID .. FxGUID] = 1
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                            4 + (5 * (LyrID - 1)),
                                            FxdCtx.Lyr.Solo[LyrID .. FxGUID])
                                    end
                                end
                                if FxdCtx.Lyr.Solo[LyrID .. FxGUID] == nil then
                                    FxdCtx.Lyr.Solo[LyrID .. FxGUID] = reaper
                                        .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                            4 + (5 * (LyrID - 1)))
                                end

                                r.ImGui_SameLine(ctx, nil, 3)
                                r.ImGui_SetCursorPosY(ctx, CurY)
                                if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == 0 then
                                    local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                    local Act, Hvr = GF.Generate_Active_And_Hvr_CLRs(Clr)
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Clr)
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Act)
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Hvr)
                                    LyrMuteClrPop = 3
                                end
                                ClickOnMute = r.ImGui_Button(ctx, 'M##' .. LyrID, BtnSizeManual, BtnSizeManual)
                                if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == 0 then
                                    r.ImGui_PopStyleColor(ctx,
                                        LyrMuteClrPop)
                                end



                                if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == nil then
                                    FxdCtx.Lyr.Mute[LyrID .. FxGUID] = reaper
                                        .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                                end

                                if ClickOnMute then
                                    FxdCtx.Lyr.Mute[LyrID .. FxGUID] = r.TrackFX_GetParamNormalized(
                                        LT_Track,
                                        FX_Idx, 5 * (LyrID - 1))
                                    if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == 1 then
                                        FxdCtx.Lyr.Mute[LyrID .. FxGUID] = 0
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                            5 * (LyrID - 1),
                                            FxdCtx.Lyr.Mute[LyrID .. FxGUID])
                                    elseif FxdCtx.Lyr.Mute[LyrID .. FxGUID] == 0 then
                                        FxdCtx.Lyr.Mute[LyrID .. FxGUID] = 1
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1),
                                            FxdCtx.Lyr.Mute[LyrID .. FxGUID])
                                    end
                                end




                                MuteBtnR, MuteBtnB = r.ImGui_GetItemRectMax(ctx)

                                if FxdCtx.FX[FxGUID].AnySoloChan then
                                    if FxdCtx.Lyr.Solo[LyrID .. FxGUID] ~= 1 then
                                        r.ImGui_DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                            0x00000088)
                                    end
                                end
                                if FxdCtx.Lyr.Mute[LyrID .. FxGUID] == 0 then
                                    r.ImGui_DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                        0x00000088)
                                end
                            end
                        end




                        if FxdCtx.FX[FxGUID].ActiveLyrCount ~= 8 then
                            AddNewLayer = r.ImGui_Button(ctx, '+', FXLayeringWin_X, 25)
                            if AddNewLayer then
                                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                                if FxdCtx.FX[FxGUID].ActiveLyrCount <= 8 then
                                    local EmptyChan, _, _, _;
                                    for i, v in ipairs(FxdCtx.FX[FxGUID].LyrID) do
                                        if not EmptyChan then
                                            if v == -1 then EmptyChan = i end
                                        end
                                    end

                                    if not EmptyChan then EmptyChan = FxdCtx.FX[FxGUID].ActiveLyrCount + 1 end
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (EmptyChan - 1), 1)
                                    FxdCtx.FX[FxGUID].ActiveLyrCount = math.min(
                                        FxdCtx.FX[FxGUID].ActiveLyrCount + 1, 8)
                                    FxdCtx.FX[FxGUID][EmptyChan * 2 - 1].V = 0.5 -- init val for Vol
                                    FxdCtx.FX[FxGUID][EmptyChan * 2].V = 0.5     -- init val for Pan

                                    FxdCtx.FX[FxGUID].LyrID[EmptyChan] = EmptyChan

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
                        local title = (FxdCtx.FX[FxGUID].ContainerTitle or 'FX Layering'):gsub("(.)", "%1\n")

                        WindowBtnVertical = r.ImGui_Button(ctx, title .. '##Vertical', 25, 220) -- create window name button
                        if WindowBtnVertical and Mods == 0 then
                        elseif WindowBtnVertical == true and Mods == Shift then
                            state_helpers.ToggleBypassFX()
                        elseif r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                            FxdCtx.FX[FxGUID].DeleteFXLayer = true
                        elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                            FxdCtx.FX[FxGUID].Collapse = nil
                        elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                            BlinkFX = state_helpers.ToggleCollapseAll(FX_Idx)
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

                FxdCtx.FX[FxGUID].DontShowTilNextFullLoop = true

                if not FxdCtx.FX[FxGUID].Collapse then --Create FX windows inside rack
                    local Sel_LyrID
                    Drawlist = r.ImGui_GetBackgroundDrawList(ctx)


                    FxdCtx.Lyr.FrstFXPos[FXGUID_RackMixer] = nil
                    local HowManyFXinLyr = 0
                    for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                        local FXisInLyr

                        for _, LyrID in pairs(FxdCtx.FX[FxGUID].LyrID) do
                            FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)

                            if FxdCtx.FX.InLyr[FXGUID_To_Check_If_InLayer] == FxdCtx.FXGUID[FX_Idx] then --if fx is in rack mixer
                                if FxdCtx.Lyr.Selected[FXGUID_RackMixer] == nil then FxdCtx.Lyr.Selected[FXGUID_RackMixer] = 1 end
                                if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx_InLayer]].inWhichLyr == FxdCtx.FX[FXGUID_RackMixer].LyrID[LyrID] and LyrID == FxdCtx.Lyr.Selected[FXGUID_RackMixer] and not table_helpers.FindStringInTable(BlackListFXs, FxdCtx.FX.Win_Name[FX_Idx_InLayer]) then
                                    r.ImGui_SameLine(ctx, nil, 0)

                                    GF.AddSpaceBtwnFXs(FX_Idx_InLayer, false, nil, LyrID)
                                    Xpos_Left, Ypos_Top = r.ImGui_GetItemRectMin(ctx)
                                    r.ImGui_SameLine(ctx, nil, 0)
                                    if not table_helpers.FindStringInTable(BlackListFXs, FxdCtx.FX.Win_Name[FX_Idx_InLayer]) then
                                        GF.createFXWindow(FX_Idx_InLayer)
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

                        if FxdCtx.FX.InLyr[FXGUID_To_Check_If_InLayer] == FxdCtx.FXGUID[FX_Idx] then
                            if FxdCtx.Lyr.FrstFXPos[FXGUID_RackMixer] == nil then
                                FxdCtx.Lyr.FrstFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                            else
                                FxdCtx.Lyr.FrstFXPos[FXGUID_RackMixer] = math.min(
                                    FxdCtx.Lyr.FrstFXPos[FXGUID_RackMixer],
                                    FX_Idx_InLayer)
                            end
                            FxdCtx.Lyr.LastFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                        end

                        r.ImGui_SameLine(ctx, nil, 0)
                    end


                    FxdCtx.Lyr[FXGUID_RackMixer] = FxdCtx.Lyr[FXGUID_RackMixer] or {}
                    FxdCtx.Lyr[FXGUID_RackMixer].HowManyFX = HowManyFXinLyr



                    if HowManyFXinLyr > 0 and FxdCtx.FX[FxGUID].TheresFXinLyr then -- ==  Add and theres fx in selected layer
                        --if there's fx in the rack

                        AddLastSPCinRack = true

                        GF.AddSpaceBtwnFXs(FX_Idx, nil, nil, Sel_LyrID)
                        AddLastSPCinRack = false
                        Xpos_Right, Ypos_Btm = r.ImGui_GetItemRectMax(ctx)
                        Xpos_Left, Ypos_Top = r.ImGui_GetItemRectMin(ctx)


                        local TheresFXinLyr
                        for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                            if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]] then
                                if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].inWhichLyr == FxdCtx.FX[FXGUID_RackMixer].LyrID[FxdCtx.Lyr.Selected[FXGUID_RackMixer]] and FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx]] == FXGUID_RackMixer then
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







                if FxdCtx.FX[FxGUID].DeleteFXLayer then
                    local FXinRack = 0
                    --count number of fxs in layer
                    for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                        for _, _ in pairs(FxdCtx.FX[FxGUID].LyrID) do
                            local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                            if FxdCtx.FX.InLyr[GUID] == FxdCtx.FXGUID[FX_Idx] then
                                FXinRack = FXinRack + 1
                            end
                        end
                    end

                    if FXinRack == 0 then -- if no fx just delete
                        r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                        r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                        FxdCtx.FX[FxGUID].DeleteFXLayer = nil
                    else -- else prompt user
                        local Modalw, Modalh = 270, 55
                        r.ImGui_SetNextWindowPos(ctx, FxdCtx.VP.x + FxdCtx.VP.w / 2 - Modalw / 2,
                            FxdCtx.VP.y + FxdCtx.VP.h / 2 - Modalh / 2)
                        r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                        r.ImGui_OpenPopup(ctx, 'Delete FX Layer? ##' .. FxGUID)
                    end
                end

                if r.ImGui_BeginPopupModal(ctx, 'Delete FX Layer? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                    r.ImGui_Text(ctx, 'Delete the FXs in layers altogether?')
                    if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                        for i = 0, Sel_Track_FX_Count, 1 do
                            if FxdCtx.FX.InLyr[FxdCtx.FXGUID[i]] == FxdCtx.FXGUID[FX_Idx] then
                                --sets input channel
                                r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                                r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                                --sets Output
                                r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                                r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)
                                FxdCtx.FX.InLyr[FxdCtx.FXGUID[i]] = nil
                                r.SetProjExtState(0, 'FX Devices',
                                    'FXLayer - ' .. 'is FX' .. FxdCtx.FXGUID[i] .. 'in layer', "")
                            end
                        end

                        for i = 0, Sel_Track_FX_Count, 1 do
                            if FxdCtx.FXGUID[FX_Idx] == FxdCtx.Lyr.SplitrAttachTo[FxdCtx.FXGUID[i]] then
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                r.TrackFX_Delete(LT_Track, i)
                            end
                        end

                        FxdCtx.FX[FxGUID].DeleteFXLayer = nil
                    end
                    r.ImGui_SameLine(ctx)

                    if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                        local Spltr, FX_Inst
                        for i = 0, Sel_Track_FX_Count, 1 do
                            if FxdCtx.FXGUID[FX_Idx] == FxdCtx.Lyr.SplitrAttachTo[FxdCtx.FXGUID[i]] then
                                Spltr = i
                            end
                        end
                        r.Undo_BeginBlock()

                        for i = 0, Sel_Track_FX_Count, 1 do
                            if FxdCtx.FX.InLyr[FxdCtx.FXGUID[i]] == FxdCtx.FXGUID[FX_Idx] then
                                FX_Inst = (FX_Inst or 0) + 1
                                r.SetProjExtState(0, 'FX Devices',
                                    'FXLayer - ' .. 'is FX' .. FxdCtx.FXGUID[i] .. 'in layer', "")
                            end
                        end

                        for _ = 0, FX_Inst, 1 do
                            r.TrackFX_Delete(LT_Track, Spltr)
                        end



                        FxdCtx.FX[FxGUID].DeleteFXLayer = nil
                        r.Undo_EndBlock('Delete Layer Container', 0)
                    end
                    r.ImGui_SameLine(ctx)

                    if r.ImGui_Button(ctx, '(c) Cancel  (or Esc)') or r.ImGui_IsKeyPressed(ctx, 67) or r.ImGui_IsKeyPressed(ctx, 27) then
                        FxdCtx.FX[FxGUID].DeleteFXLayer = nil
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                    r.ImGui_SameLine(ctx)

                    r.ImGui_EndPopup(ctx)
                end

                r.ImGui_SameLine(ctx, nil, 0)
                FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].DontShowTilNextFullLoop = true
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
                    if FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx + 1]] then -- if in layering
                        GF.SyncAnalyzerPinWithFX(FX_Idx, FX_Idx + 1, FxdCtx.FX.Win_Name[math.max(FX_Idx - 1, 0)])
                        FxdCtx.FX.InLyr[FxGUID] = FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx + 1]]
                    else
                        FxdCtx.FX.InLyr[FxGUID] = nil
                    end
                end
            elseif FX_Name:find('FXD Split to 4 channels') then
                local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                --if FX below is not Pro-C 2
                if FX_Name_After then
                    if string.find(FX_Name_After, 'Pro%-C 2') then
                        if FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx + 1]] then -- if in layering
                            GF.SyncAnalyzerPinWithFX(FX_Idx, FX_Idx + 1, FX_Name)
                        end
                    end
                end
            elseif FX_Name:find('FXD Gain Reduction Scope') then
                r.gmem_attach('CompReductionScope')
                if FxdCtx.FX[FxdCtx.FXGUID[FX_Idx - 1]] then
                    r.gmem_write(FxdCtx.FX[FxdCtx.FXGUID[FX_Idx - 1]].ProC_ID or 0, FX_Idx - 1)
                end
                local _, FX_Name_Before = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)


                --if FX above is not Pro-C 2
                FxdCtx.FX[FxGUID].ProC_Scope_Del_Wait = (FxdCtx.FX[FxGUID].ProC_Scope_Del_Wait or 0) + 1

                if FxdCtx.FX[FxGUID].ProC_Scope_Del_Wait > FX_Add_Del_WaitTime + 10 then
                    if string.find(FX_Name_Before, 'Pro%-C 2') then
                        if FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx - 1]] then -- if in layering
                            GF.SyncAnalyzerPinWithFX(FX_Idx, FX_Idx - 1, FX_Name)
                        end
                    end
                    FxdCtx.FX[FxGUID].ProC_Scope_Del_Wait = 0
                end

                if FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx - 1]] then
                    FxdCtx.FX.InLyr[FxGUID] = FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx - 1]]
                else
                    FxdCtx.FX.InLyr[FxGUID] = nil
                end
            elseif string.find(FX_Name, 'FXD Split to 32 Channels') ~= nil then
                r.TrackFX_Show(LT_Track, FX_Idx, 2)
                GF.AddSpaceBtwnFXs(FX_Idx, true)
                FxdCtx.Spltr[FxGUID] = FxdCtx.Spltr[FxGUID] or {}
                FxdCtx.Lyr[FxdCtx.Lyr.SplitrAttachTo[FxGUID]] = FxdCtx.Lyr[FxdCtx.Lyr.SplitrAttachTo[FxGUID]] or
                    {}
                if FxdCtx.Lyr[FxdCtx.Lyr.SplitrAttachTo[FxGUID]].HowManyFX == 0 then
                    if FxdCtx.FXGUID[FX_Idx + 1] ~= FxdCtx.Lyr.SplitrAttachTo[FxGUID] then
                        for i = 0, Sel_Track_FX_Count - 1, 1 do
                            if FxdCtx.FXGUID[i] == FxdCtx.Lyr.SplitrAttachTo[FxGUID] then
                                r.TrackFX_CopyToTrack(LT_Track, FX_Idx, LT_Track, i - 1, true)
                            end
                        end
                    end
                end

                if FxdCtx.Spltr[FxGUID].New == true then
                    for i = 0, 16, 2 do
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 1, 0)
                    end

                    for i = 1, 16, 2 do
                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 2, 0)
                    end

                    local FxGUID_Rack = FxdCtx.Lyr.SplitrAttachTo[FxGUID]
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
                    FxdCtx.Spltr[FxGUID].New = false
                end

                if FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx + 1] or ''] then
                    FxdCtx.FX.InLyr[FxGUID] = FxdCtx.FX.InLyr[FxdCtx.FXGUID[FX_Idx + 1]]
                else
                    FxdCtx.FX.InLyr[FxGUID] = nil
                end

                Pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)
            elseif FX_Name:find('FXD Saike BandSplitter') then
                local Width, BtnWidth = 65, 25
                local WinL, WinT, H, WinR
                local WDL = WDL or r.ImGui_GetWindowDrawList(ctx)

                if BandSplitID and not FxdCtx.FX[FxGUID].BandSplitID then
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: BandSplitterID' .. FxGUID, BandSplitID,
                        true)
                    FxdCtx.FX[FxGUID].BandSplitID = BandSplitID
                    BandSplitID = nil
                end
                FxdCtx.FX[FxGUID].FXsInBS = FxdCtx.FX[FxGUID].FXsInBS or {}
                local JoinerID
                for i, v in ipairs(FxdCtx.FXGUID) do
                    if FxdCtx.FX[FxGUID].AttachToJoiner == v then JoinerID = i end
                end
                local BsID = FxdCtx.FX[FxGUID].BandSplitID
                if FxdCtx.FX[FxGUID].Collapse then Width = 35 end


                if r.ImGui_BeginChild(ctx, 'FXD Saike BandSplitter' .. FxGUID, Width, 220) then
                    local SpcW = GF.AddSpaceBtwnFXs(FX_Idx, 'SpaceBeforeBS', nil, nil, 1, FxGUID)
                    gui_helpers.SL(nil, 0)

                    local btnTitle = string.gsub('Band Split', "(.)", "%1\n")
                    local btn = r.ImGui_Button(ctx, btnTitle .. '##Vertical', BtnWidth, 220) -- create window name button   Band Split button


                    if btn and Mods == 0 then
                        GF.openFXwindow(LT_Track, FX_Idx)
                    elseif btn and Mods == Shift then
                        state_helpers.ToggleBypassFX(LT_Track, FX_Idx)
                    elseif btn and Mods == Alt then
                        FxdCtx.FX[FxGUID].DeleteBandSplitter = true
                    elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                        FxdCtx.FX[FxGUID].Collapse = state_helpers.toggle(FxdCtx.FX[FxGUID].Collapse)
                    elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then -- check if all are collapsed
                        local All_Collapsed
                        for i = 0, Sel_Track_FX_Count - 1, 1 do
                            if not FxdCtx.FX[FxdCtx.FXGUID[i]].Collapse then All_Collapsed = false end
                        end
                        if All_Collapsed == false then
                            for i = 0, Sel_Track_FX_Count - 1, 1 do
                                FxdCtx.FX[FxdCtx.FXGUID[i]].Collapse = true
                            end
                        else -- if all is collapsed
                            for i = 0, Sel_Track_FX_Count - 1, 1 do
                                FxdCtx.FX[FxdCtx.FXGUID[i]].Collapse = false
                                FxdCtx.FX.WidthCollapse[FxdCtx.FXGUID[i]] = nil
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
                    gui_helpers.SL(nil, 0)
                    r.gmem_attach('FXD_BandSplit')




                    --r.gmem_write(1,0) --[[1 is MouseR Click Position]]
                    --r.gmem_write(2,0)--[[tells if user R-Click BETWEEN a band]]
                    --r.gmem_write(3,0)--[[tells if user R-Click ON a band]]


                    FxdCtx.FX[FxGUID].Cross = FxdCtx.FX[FxGUID].Cross or {}
                    local Cuts = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 0)
                    FxdCtx.FX[FxGUID].Cross.Cuts = Cuts
                    WinL, WinT = r.ImGui_GetCursorScreenPos(ctx)
                    H, WinR = 220, WinL + Width - BtnWidth - SpcW


                    if FxdCtx.FX[FxGUID].Collapse then
                        local L, T = WinL - BtnWidth, WinT
                        r.ImGui_DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                        r.ImGui_DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                        r.ImGui_DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)
                    else
                        for i = 1, Cuts * 4, 1 do ----------[Repeat for Bands]----------
                            FxdCtx.FX[FxGUID].Cross[i] = FxdCtx.FX[FxGUID].Cross[i] or {}
                            local X = FxdCtx.FX[FxGUID].Cross[i]
                            -- r.gmem_attach('FXD_BandSplit')
                            local BsID = BsID or 0

                            X.Val = r.gmem_read(BsID + i)
                            X.NxtVal = r.gmem_read(BsID + i + 1)
                            X.Pos = math_helpers.SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)


                            --FX[FxGUID].Cross[i].Val = r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)

                            local Cross_Pos = math_helpers.SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                            local NxtCrossPos = math_helpers.SetMinMax(WinT + H - H * X.NxtVal, WinT, WinT + H)


                            if --[[Hovering over a band]] r.ImGui_IsMouseHoveringRect(ctx, WinL, Cross_Pos - 3, WinR, Cross_Pos + 3) then
                                FxdCtx.FX[FxGUID].Cross.HoveringBand = i
                                FxdCtx.FX[FxGUID].Cross.HoveringBandPos = Cross_Pos

                                if IsLBtnClicked then
                                    table.insert(FxdCtx.Sel_Cross, i)
                                    FxdCtx.Sel_Cross.FxID = FxGUID
                                elseif IsRBtnClicked then
                                    --[[ if Cuts * 4 == i then  -- if deleting the top band
                                                r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, 0, math.max(Cuts-0.25,0)) --simply delete top band only, leave others untouched.
                                            else ]]
                                    --delete band
                                    local Rpt = Cuts * 4 - i
                                    local Bd = i + 1
                                    if FxdCtx.FX[FxGUID].Sel_Band == i then FxdCtx.FX[FxGUID].Sel_Band = nil end

                                    local _ = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Bd)
                                    local _, _ = r.TrackFX_GetParamName(LT_Track, FX_Idx, Bd)
                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0,
                                        math.max(Cuts - 0.25, 0)) -- Delete Band
                                    for T = 1, Rpt, 1 do
                                        local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                            i + T)

                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i - 1 + T, NxtBd_V) --adjust band Freq
                                    end
                                    for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                                        if FxdCtx.FX[v].InWhichBand >= i then
                                            FxdCtx.FX[v].InWhichBand = FxdCtx.FX[v].InWhichBand - 1

                                            local Fx = table_helpers.tablefind(FxdCtx.FXGUID, v)
                                            --sets input channel
                                            r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0,
                                                2 ^ ((FxdCtx.FX[v].InWhichBand + 1) * 2 - 2), 0)
                                            r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1,
                                                2 ^ ((FxdCtx.FX[v].InWhichBand + 1) * 2 - 1), 0)
                                            --sets Output +1
                                            r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0,
                                                2 ^ ((FxdCtx.FX[v].InWhichBand + 1) * 2 - 2), 0)
                                            r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1,
                                                2 ^ ((FxdCtx.FX[v].InWhichBand + 1) * 2 - 1), 0)
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX is in which Band' .. v, FxdCtx.FX[v].InWhichBand, true)
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





                            if FxdCtx.Sel_Cross[1] == i and FxdCtx.Sel_Cross.FxID == FxGUID then
                                if IsLBtnHeld then
                                    FxdCtx.FX[FxGUID].Cross.DraggingBand = i
                                    local PrmV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                    DragDeltaX, DragDeltaY = r.ImGui_GetMouseDragDelta(ctx)
                                    if DragDeltaY > 0 or DragDeltaY < 0 then
                                        local B = FxdCtx.Sel_Cross.TweakingBand
                                        if #FxdCtx.Sel_Cross > 1 then
                                            if DragDeltaY > 0 then -- if drag upward
                                                B = math.min(FxdCtx.Sel_Cross[1], FxdCtx.Sel_Cross[2])
                                                table.remove(FxdCtx.Sel_Cross,
                                                    table_helpers.tablefind(FxdCtx.Sel_Cross,
                                                        math.max(FxdCtx.Sel_Cross[1], FxdCtx.Sel_Cross[2])))
                                            else
                                                B = math.max(FxdCtx.Sel_Cross[1], FxdCtx.Sel_Cross[2])
                                                table.remove(FxdCtx.Sel_Cross,
                                                    table_helpers.tablefind(FxdCtx.Sel_Cross,
                                                        math.min(FxdCtx.Sel_Cross[1], FxdCtx.Sel_Cross[2])))
                                            end
                                        else
                                            B = FxdCtx.Sel_Cross[1]
                                        end
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
                                    if FxdCtx.Sel_Cross[1] == i then
                                        r.ImGui_SetNextWindowPos(ctx, WinR, FxdCtx.FX[FxGUID].Cross[i].Pos - 14)
                                        r.ImGui_BeginTooltip(ctx)
                                        r.ImGui_Text(ctx, math_helpers.roundUp(r.gmem_read(BsID + 4 + i), 1) .. ' Hz')
                                        r.ImGui_EndTooltip(ctx)
                                        --r.ImGui_DrawList_AddText(Glob.FDL, WinL, Cross_Pos, getClr(r.ImGui_Col_Text()) , roundUp(r.gmem_read(10+i),1)..' Hz')
                                    end
                                else
                                    FxdCtx.Sel_Cross = {} --r.gmem_write(100, 0)
                                end
                            else
                            end


                            --[[ -- Draw Bands
                                    r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos , WinR, X.Pos, TxtClr )
                                    r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr , roundUp(r.gmem_read(BsID+4+i),1)) ]]
                        end


                        function DropFXintoBS(FxID, FxGUID_BS, Band, Pl, DropDest, DontMove) --Pl is payload    --!!!! Correct drop dest!!!!
                            FxdCtx.FX[FxID] = FxdCtx.FX[FxID] or {}

                            if FxdCtx.FX.InLyr[FxID] then --- move fx out of Layer
                                FxdCtx.FX.InLyr[FxdCtx.FXGUID[DragFX_ID]] = nil
                                r.SetProjExtState(0, 'FX Devices',
                                    'FXLayer - ' .. 'is FX' .. FxdCtx.FXGUID[DragFX_ID] .. 'in layer', '')
                            end



                            if FxdCtx.FX[FxID].InWhichBand then
                                table.remove(FxdCtx.FX[FxGUID_BS].FXsInBS,
                                    table_helpers.tablefind(FxdCtx.FX[FxGUID_BS].FXsInBS, FxID))
                            end



                            if TABinsertPos then
                                table.insert(FxdCtx.FX[FxGUID_BS].FXsInBS, TABinsertPos, FxID)
                            else
                                table.insert(FxdCtx.FX[FxGUID_BS].FXsInBS, FxID)
                            end

                            FxdCtx.FX[FxID].InWhichBand = Band

                            if not DontMove then
                                local DropDest = DropDest
                                table.insert(FxdCtx.MovFX.FromPos, Pl)
                                if Pl > FX_Idx and not DropDest then DropDest = FX_Idx + 1 end


                                if Pl < DropDest then
                                    DropDest = DropDest - 1
                                end



                                table.insert(FxdCtx.MovFX.ToPos, DropDest or FX_Idx)

                                table.insert(FxdCtx.MovFX.Lbl, 'Move FX into Band ' .. Band)
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

                            local IDinPost = table_helpers.tablefind(FxdCtx.Trk[TrkID].PostFX, FxdCtx.FXGUID[DragFX_ID])
                            if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                            local IDinPre = table_helpers.tablefind(FxdCtx.Trk[TrkID].PreFX, FxdCtx.FXGUID[DragFX_ID])
                            if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                        end

                        -- Count numbeer of FXs in bands
                        local FXCountForBand = {}
                        FxdCtx.FX[FxGUID].FXCheckWait = (FxdCtx.FX[FxGUID].FXCheckWait or 0) + 1
                        if FxdCtx.FX[FxGUID].FXCheckWait > 10 then
                            for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                                if not table_helpers.tablefind(FxdCtx.FXGUID, v) then
                                    table.remove(FxdCtx.FX[FxGUID].FXsInBS,
                                        table_helpers.tablefind(FxdCtx.FX[FxGUID].FXsInBS, v))
                                end
                            end
                            FxdCtx.FX[FxGUID].FXCheckWait = 0
                        end

                        for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                            if FxdCtx.FX[v].InWhichBand == 0 then
                                FXCountForBand[0] = (FXCountForBand[0] or 0) + 1
                            elseif FxdCtx.FX[v].InWhichBand == 1 then
                                FXCountForBand[1] = (FXCountForBand[1] or 0) + 1
                            elseif FxdCtx.FX[v].InWhichBand == 2 then
                                FXCountForBand[2] = (FXCountForBand[2] or 0) + 1
                            elseif FxdCtx.FX[v].InWhichBand == 3 then
                                FXCountForBand[3] = (FXCountForBand[3] or 0) + 1
                            elseif FxdCtx.FX[v].InWhichBand == 4 then
                                FXCountForBand[4] = (FXCountForBand[4] or 0) + 1
                            end
                        end

                        for i = 0, 5, 1 do FxdCtx.FX[FxGUID].Cross[i] = FxdCtx.FX[FxGUID].Cross[i] or {} end
                        for i = 0, Cuts * 4, 1 do ------- Rpt for Spaces between band splits
                            local CrossPos, Nxt_CrossPos
                            local Pl = tonumber(Payload)

                            if i == 0 then
                                CrossPos = WinT + H
                            else
                                CrossPos = FxdCtx.FX[FxGUID].Cross[math.min(i, 4)]
                                    .Pos
                            end
                            if i == Cuts * 4 then
                                Nxt_CrossPos = WinT
                            else
                                Nxt_CrossPos = FxdCtx.FX[FxGUID].Cross[i + 1]
                                    .Pos
                            end
                            local HvrOnBand = r.ImGui_IsMouseHoveringRect(ctx, WinL, CrossPos - 3, WinR,
                                CrossPos + 3)
                            local HvrOnNxtBand = r.ImGui_IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos - 3, WinR,
                                Nxt_CrossPos + 3)

                            if --[[Hovering over a band]] r.ImGui_IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos, WinR, CrossPos) and not (HvrOnBand or HvrOnNxtBand) then
                                local function Find_InsPos()
                                    local InsPos
                                    for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                                        if FxdCtx.FX[v].InWhichBand == i then InsPos = table_helpers.tablefind(FxdCtx.FXGUID, v) end
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
                                    if FxdCtx.FX[FxdCtx.FXGUID[Pl]].InWhichBand ~= i then
                                        r.ImGui_DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                            0xffffff66)
                                        if r.ImGui_IsMouseReleased(ctx, 0) then
                                            local InsPos = Find_InsPos()
                                            DropFXintoBS(FxdCtx.FXGUID[Pl], FxGUID, i, Pl, InsPos + 1)
                                        end
                                    end
                                elseif Payload_Type == 'DND ADD FX' then
                                    r.ImGui_DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                        0xffffff66)

                                    if r.ImGui_IsMouseReleased(ctx, 0) then
                                        local InsPos = Find_InsPos()
                                        local _, _, payload, _, _ = r
                                            .ImGui_GetDragDropPayload(ctx)
                                        r.TrackFX_AddByName(LT_Track, payload, false, -1000 - InsPos - 1)
                                        local FXid = r.TrackFX_GetFXGUID(LT_Track, InsPos + 1)
                                        DropFXintoBS(FXid, FxGUID, i, InsPos, FX_Idx, 'DontMove')
                                    end
                                end
                                AnySplitBandHvred = true
                                FxdCtx.FX[FxGUID].PreviouslyMutedBand = FxdCtx.FX[FxGUID].PreviouslyMutedBand or
                                    {}
                                FxdCtx.FX[FxGUID].PreviouslySolodBand = FxdCtx.FX[FxGUID].PreviouslySolodBand or
                                    {}

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
                                        FxdCtx.FX[FxGUID].PreviouslyMutedBand = {}
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
                                        FxdCtx.FX[FxGUID].PreviouslySolodBand = {}
                                    end
                                elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_M()) and Mods == Shift then
                                    local AnyMutedBand

                                    for i = 0, Cuts * 4, 1 do
                                        local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                            5 * i)

                                        if OnOff == 0 then AnyMutedBand = true end
                                        if OnOff == 0 then table.insert(FxdCtx.FX[FxGUID].PreviouslyMutedBand, i) end
                                        if table_helpers.tablefind(FxdCtx.FX[FxGUID].PreviouslyMutedBand, i) and OnOff == 1 then
                                            r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 0)
                                        else
                                            r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 1)
                                        end
                                    end

                                    if not AnyMutedBand then FxdCtx.FX[FxGUID].PreviouslyMutedBand = {} end
                                elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_S()) and Mods == Shift then
                                    local AnySolodBand

                                    for i = 0, Cuts * 4, 1 do
                                        local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID,
                                            4 + 5 * i)

                                        if OnOff == 1 then AnySolodBand = true end
                                        if OnOff == 1 then table.insert(FxdCtx.FX[FxGUID].PreviouslySolodBand, i) end
                                        if table_helpers.tablefind(FxdCtx.FX[FxGUID].PreviouslySolodBand, i) and OnOff == 0 then
                                            r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 1)
                                        else
                                            r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 0)
                                        end
                                    end

                                    if not AnySolodBand then FxdCtx.FX[FxGUID].PreviouslySolodBand = {} end
                                end
                                FxdCtx.FX[FxGUID].PreviouslyMutedBand = FxdCtx.FX[FxGUID].PreviouslyMutedBand or
                                    {}



                                if IsLBtnClicked and (Mods == 0 or Mods == Apl) then
                                    FxdCtx.FX[FxGUID].Sel_Band = i
                                    FxdCtx.FX[FxGUID].StartCount = true
                                elseif IsRBtnClicked and Cuts ~= 1 then
                                    local _, ClickPos = r.ImGui_GetMousePos(ctx, 1)
                                    local H = 213
                                    local Norm_V = (WinT - ClickPos + 3) / H + 1


                                    local X = FxdCtx.FX[FxGUID].Cross

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
                                        FxdCtx.FX[FxGUID].PromptDeleteBand = i
                                        local Modalw, Modalh = 270, 55
                                        r.ImGui_SetNextWindowPos(ctx, FxdCtx.VP.x + FxdCtx.VP.w / 2 - Modalw / 2,
                                            FxdCtx.VP.y + FxdCtx.VP.h / 2 - Modalh / 2)
                                        r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                        r.ImGui_OpenPopup(ctx, 'Delete Band' .. i .. '? ##' .. FxGUID)
                                    end
                                elseif LBtn_MousdDownDuration > 0.06 and (Mods == 0 or Mods == Apl) and not FxdCtx.DraggingFXs.SrcBand and FxdCtx.FX[FxGUID].StartCount then
                                    --Drag FXs to different bands
                                    for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                                        if FxdCtx.FX[v].InWhichBand == i then
                                            table.insert(FxdCtx.DraggingFXs, v)
                                            table.insert(FxdCtx.DraggingFXs_Idx, table_helpers.tablefind(FxdCtx.FXGUID, v))
                                        end
                                    end
                                    FxdCtx.DraggingFXs.SrcBand = i
                                    FxdCtx.DraggingFXs.SrcFxID = FxGUID
                                elseif FxdCtx.DraggingFXs.SrcBand and FxdCtx.DraggingFXs[1] and IsLBtnHeld or Payload_Type == 'FX_Drag' then
                                    FxdCtx.FX[FxGUID].Sel_Band = i
                                end



                                if FxdCtx.DraggingFXs[1] and FxdCtx.DraggingFXs.SrcBand ~= i then
                                    gui_helpers.HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                                        Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1,
                                        NoGetItemRect, NoForeground, NOrounding)
                                    if not IsLBtnHeld and Mods == 0 then -- if Dropped FXs
                                        for _, v in ipairs(FxdCtx.DraggingFXs) do
                                            FxdCtx.FX[v].InWhichBand = i
                                            local Fx = table_helpers.tablefind(FxdCtx.FXGUID, v)
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
                                        for I, _ in ipairs(FxdCtx.DraggingFXs) do
                                            local offset
                                            local srcFX = FxdCtx.DraggingFXs_Idx[I] + Ofs
                                            local TrgFX = srcFX + #FxdCtx.DraggingFXs
                                            if not FXCountForBand[i] then -- if theres no fx in the band
                                            elseif FXCountForBand[i] > 0 then
                                                for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                                                    if FxdCtx.FX[v].InWhichBand == i and table_helpers.tablefind(FxdCtx.FXGUID, v) then
                                                        offset =
                                                            table_helpers.tablefind(FxdCtx.FXGUID, v)
                                                    end
                                                end
                                                TrgFX = offset + I
                                            end


                                            if srcFX >= TrgFX then Ofs = I end


                                            r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, TrgFX,
                                                false)
                                            local ID = r.TrackFX_GetFXGUID(LT_Track, TrgFX)

                                            if not table_helpers.tablefind(FxdCtx.FX[FxGUID].FXsInBS, ID) then
                                                table.insert(
                                                    FxdCtx.FX[FxGUID].FXsInBS, ID)
                                            end
                                            FxdCtx.FX[ID] = FxdCtx.FX[ID] or {}
                                            FxdCtx.FX[ID].InWhichBand = i
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
                            if FxdCtx.FX[FxGUID].Sel_Band == i then
                                gui_helpers.HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
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

                        if r.ImGui_BeginPopupModal(ctx, 'Delete Band' .. (FxdCtx.FX[FxGUID].PromptDeleteBand or '') .. '? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                            r.ImGui_Text(ctx,
                                'Delete the FXs in band ' .. FxdCtx.FX[FxGUID].PromptDeleteBand .. '?')
                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                r.Undo_BeginBlock()
                                local DelFX = {}
                                for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                                    if FxdCtx.FX[v].InWhichBand == FxdCtx.FX[FxGUID].PromptDeleteBand then
                                        table.insert(DelFX, v)
                                        --delete FXs
                                    end
                                end
                                for i, v in ipairs(DelFX) do
                                    r.TrackFX_Delete(LT_Track, table_helpers.tablefind(FxdCtx.FXGUID, v) - i + 1)
                                end


                                r.Undo_EndBlock('Delete all FXs in Band ' .. FxdCtx.FX[FxGUID].PromptDeleteBand,
                                    0)
                                FxdCtx.FX[FxGUID].PromptDeleteBand = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                            end
                            gui_helpers.SL()
                            if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                r.ImGui_CloseCurrentPopup(ctx)
                            end
                            r.ImGui_EndPopup(ctx)
                        end






                        -- draw bands

                        for i = 1, Cuts * 4, 1 do
                            local X = FxdCtx.FX[FxGUID].Cross[i]
                            if IsRBtnHeld then
                                X.Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i);

                                X.Pos = math_helpers.SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                            end
                            local BsID = FxdCtx.FX[FxGUID].BandSplitID
                            local TxtClr = GF.getClr(r.ImGui_Col_Text())

                            r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos, WinR, X.Pos, TxtClr)
                            if FxdCtx.FX[FxGUID].Cross.DraggingBand ~= i then
                                r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                    math_helpers.roundUp(r.gmem_read(BsID + 4 + i), 1))
                            end
                            if FxdCtx.FX[FxGUID].Cross.HoveringBand == i or FxdCtx.FX[FxGUID].Cross.DraggingBand == i then
                                if not FxdCtx.FX[FxGUID].Cross.DraggingBand == i then
                                    r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                        math_helpers.roundUp(r.gmem_read(BsID + 4 + i), 1))
                                end
                                r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos + 1, WinR, X.Pos, TxtClr)

                                if not r.ImGui_IsMouseHoveringRect(ctx, WinL, FxdCtx.FX[FxGUID].Cross.HoveringBandPos - 3, WinR, FxdCtx.FX[FxGUID].Cross.HoveringBandPos + 3)
                                    or (FxdCtx.FX[FxGUID].Cross.DraggingBand == i and not IsLBtnHeld) then
                                    FxdCtx.FX[FxGUID].Cross.HoveringBandPos = 0
                                    FxdCtx.FX[FxGUID].Cross.HoveringBand = nil
                                    FxdCtx.FX[FxGUID].Cross.DraggingBand = nil
                                end
                            end
                        end

                        -- Display Number of FXs in Band
                        for i = 0, Cuts * 4, 1 do
                            if FXCountForBand[i] or 0 > 0 then
                                local This_B_Pos, nxt_X_Pos
                                if i == 4 or (i == 3 and Cuts == 0.75) or (i == 2 and Cuts == 0.5) or (i == 1 and Cuts == 0.25) then
                                    nxt_X_Pos = WinT
                                    This_B_Pos = FxdCtx.FX[FxGUID].Cross[i].Pos
                                elseif i == 0 then
                                    This_B_Pos = WinT + H
                                    nxt_X_Pos = FxdCtx.FX[FxGUID].Cross[1].Pos
                                else
                                    nxt_X_Pos = FxdCtx.FX[FxGUID].Cross[i + 1].Pos or 0
                                    This_B_Pos = FxdCtx.FX[FxGUID].Cross[i].Pos
                                end


                                if This_B_Pos - nxt_X_Pos > 28 and not FxdCtx.DraggingFXs[1] then
                                    r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                        nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                        FXCountForBand[i] or '')
                                elseif FxdCtx.DraggingFXs[1] then
                                    if FxdCtx.DraggingFXs.SrcBand == i then
                                        MsX, MsY = r.ImGui_GetMousePos(ctx)
                                        r.ImGui_DrawList_AddLine(FxdCtx.Glob.FDL, MsX, MsY, WinL + 15,
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
                        r.ImGui_DrawList_AddRectFilled(WDL, WinL, FxdCtx.Glob.WinT, WinR, FxdCtx.Glob.WinB,
                            0xffffff33)

                        local Copy

                        if FxdCtx.DraggingFXs[1] and FXCountForBand[FxdCtx.DraggingFXs.SrcBand] then
                            local MsX, MsY = r.ImGui_GetMousePos(ctx)
                            if Mods == Apl then Copy = 'Copy' end
                            r.ImGui_DrawList_AddTextEx(FxdCtx.Glob.FDL, Font_Andale_Mono_20_B, 14, MsX + 20, MsY,
                                0xffffffaa,
                                (Copy or '') .. ' ' .. FXCountForBand[FxdCtx.DraggingFXs.SrcBand] .. ' FXs')
                        end
                    end


                    if not IsLBtnHeld then FxdCtx.FX[FxGUID].StartCount = nil end


                    r.ImGui_EndChild(ctx)
                end

                if not FxdCtx.FX[FxGUID].Collapse then
                    local LastFX_XPos
                    local FrstFX
                    local ofs = 0



                    for FX_ID = 0, Sel_Track_FX_Count, 1 do
                        for _, v in ipairs(FxdCtx.FX[FxGUID].FXsInBS) do
                            local _, FxName = r.TrackFX_GetFXName(LT_Track, FX_ID)

                            if FxdCtx.FXGUID[FX_ID] == v and FxdCtx.FX[FxGUID].Sel_Band == FxdCtx.FX[v].InWhichBand then
                                if FxName:find('FXD ReSpectrum') then ofs = ofs + 1 end

                                if not FrstFX then
                                    gui_helpers.SL(nil, 0)
                                    GF.AddSpaceBtwnFXs(FX_ID - 1, 'SpcInBS', nil, nil, nil, FxGUID)
                                    FrstFX = true
                                end
                                --if i == 1 then  SL(nil,0)  AddSpaceBtwnFXs(FX_Idx,'SpcInBS',nil,nil,1, FxGUID) end
                                gui_helpers.SL(nil, 0)

                                I = table_helpers.tablefind(FxdCtx.FXGUID, v)
                                if I then
                                    GF.createFXWindow(I)
                                    gui_helpers.SL(nil, 0)
                                    GF.AddSpaceBtwnFXs(I - ofs, 'SpcInBS', nil, nil, nil, FxGUID)
                                    gui_helpers.SL(nil, 0)
                                    --[[ if i == #FX[FxGUID].FXsInBS then  ]]
                                    LastFX_XPos = r.ImGui_GetCursorScreenPos(ctx)
                                end
                            end
                        end
                    end


                    if LastFX_XPos then
                        local Sel_B_Pos, NxtB_Pos, AddTopLine
                        local Cuts = FxdCtx.FX[FxGUID].Cross.Cuts
                        FxdCtx.FX[FxGUID].Sel_Band = FxdCtx.FX[FxGUID].Sel_Band or 0
                        if FxdCtx.FX[FxGUID].Sel_Band == 0 then
                            Sel_B_Pos = WinT + H
                        else
                            Sel_B_Pos = FxdCtx.FX[FxGUID].Cross[FxdCtx.FX[FxGUID].Sel_Band].Pos
                        end


                        if FxdCtx.FX[FxGUID].Sel_Band == 4
                            or (FxdCtx.FX[FxGUID].Sel_Band == 3 and Cuts == 0.75)
                            or (FxdCtx.FX[FxGUID].Sel_Band == 2 and Cuts == 0.5)
                            or (FxdCtx.FX[FxGUID].Sel_Band == 1 and Cuts == 0.25)
                        then
                            NxtB_Pos = WinT
                            AddTopLine = true
                        else
                            NxtB_Pos = FxdCtx.FX[FxGUID].Cross[FxdCtx.FX[FxGUID].Sel_Band + 1].Pos or 0
                        end

                        local Clr = GF.getClr(r.ImGui_Col_Text())
                        WinT = FxdCtx.Glob.WinT
                        H = FxdCtx.Glob.Height or 0
                        WinR = WinR or 0
                        NxtB_Pos = NxtB_Pos or 0
                        WinL = WinL or 0
                        r.ImGui_DrawList_AddLine(WDL, WinR, WinT + H, LastFX_XPos, WinT + H, Clr)
                        r.ImGui_DrawList_AddLine(WDL, WinR, Sel_B_Pos, WinR, WinT + H, Clr)

                        r.ImGui_DrawList_AddLine(WDL, WinR, NxtB_Pos, WinR, WinT, Clr)
                        r.ImGui_DrawList_AddLine(WDL, WinR, WinT, LastFX_XPos, WinT, Clr)
                        r.ImGui_DrawList_AddLine(WDL, LastFX_XPos - 1, WinT, LastFX_XPos - 1, WinT + H, Clr)
                        if AddTopLine then r.ImGui_DrawList_AddLine(WDL, WinL, WinT, WinR, WinT, Clr) end
                        if FxdCtx.FX[FxGUID].Sel_Band == 0 then
                            r.ImGui_DrawList_AddLine(WDL, WinL, WinT + H, WinR,
                                WinT + H, Clr)
                        end

                        if DraggingFX_L_Pos then
                            local W = LastFX_XPos - DraggingFX_L_Pos
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT, LastFX_XPos,
                                WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect, WDL)
                            if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                        end
                    else
                        if DraggingFX_L_Pos then
                            local W = Width - 10
                            gui_helpers.HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT,
                                DraggingFX_L_Pos + W, WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect,
                                WDL)
                            if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                        end
                    end
                end
                if FxdCtx.FX[FxGUID].DeleteBandSplitter then
                    if #FxdCtx.FX[FxGUID].FXsInBS == 0 then
                        r.TrackFX_Delete(LT_Track, FX_Idx + 1)
                        r.TrackFX_Delete(LT_Track, FX_Idx)
                        FxdCtx.FX[FxGUID].DeleteBandSplitter = nil
                    else
                        local Modalw, Modalh = 320, 55
                        r.ImGui_SetNextWindowPos(ctx, FxdCtx.VP.x + FxdCtx.VP.w / 2 - Modalw / 2,
                            FxdCtx.VP.y + FxdCtx.VP.h / 2 - Modalh / 2)
                        r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                        r.ImGui_OpenPopup(ctx, 'Delete Band Splitter? ##' .. FxGUID)
                    end
                end

                if r.ImGui_BeginPopupModal(ctx, 'Delete Band Splitter? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                    r.ImGui_Text(ctx, 'Delete the FXs in band splitter altogether?')
                    if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                        r.Undo_BeginBlock()
                        r.TrackFX_Delete(LT_Track, FX_Idx)
                        r.TrackFX_Delete(LT_Track, FX_Idx + #FxdCtx.FX[FxGUID].FXsInBS)
                        for i = 0, Sel_Track_FX_Count, 1 do
                            if table_helpers.tablefind(FxdCtx.FX[FxGUID].FXsInBS, FxdCtx.FXGUID[i]) then
                                --sets input channel
                                r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                                r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                                --sets Output
                                r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                                r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)

                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: FX is in which BS' .. FxdCtx.FXGUID[i],
                                    '', true)
                                r.GetSetMediaTrackInfo_String(LT_Track,
                                    'P_EXT: FX is in which Band' .. FxdCtx.FXGUID
                                    [i], '', true)
                                FxdCtx.FX[FxdCtx.FXGUID[i]].InWhichBand = nil
                            end
                        end
                        FxdCtx.FX[FxGUID].FXsInBS = nil
                        r.ImGui_CloseCurrentPopup(ctx)
                        FxdCtx.FX[FxGUID].DeleteBandSplitter = nil
                        r.Undo_EndBlock('Delete Band Split and put enclosed FXs back into channel one', 0)
                    end
                    gui_helpers.SL()

                    if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                        r.Undo_BeginBlock()
                        r.TrackFX_Delete(LT_Track, FX_Idx)
                        r.TrackFX_Delete(LT_Track, FX_Idx + #FxdCtx.FX[FxGUID].FXsInBS)
                        local DelFX = {}
                        for i = 0, Sel_Track_FX_Count, 1 do
                            if table_helpers.tablefind(FxdCtx.FX[FxGUID].FXsInBS, FxdCtx.FXGUID[i]) then
                                table.insert(DelFX, FxdCtx.FXGUID[i])
                            end
                        end

                        for i, v in ipairs(DelFX) do
                            FxdCtx.FX[v].InWhichBand = nil
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. v, '',
                                true)
                            r.TrackFX_Delete(LT_Track, table_helpers.tablefind(FxdCtx.FXGUID, v) - i)
                        end


                        r.Undo_EndBlock('Delete Band Split and all enclosed FXs', 0)
                    end
                    gui_helpers.SL()
                    if r.ImGui_Button(ctx, '(esc) Cancel') or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
                        FxdCtx.FX[FxGUID].DeleteBandSplitter = nil
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                    r.ImGui_EndPopup(ctx)
                end
            end --  for if FX_Name ~='JS: FXD (Mix)RackMixer'
            r.ImGui_SameLine(ctx, nil, 0)




            ------- Pre FX Chain --------------
            local FXisInPreChain, offset = nil, 0
            if MacroPos == 0 then offset = 1 end --else offset = 0
            if FxdCtx.Trk[TrkID].PreFX[1] then
                if FxdCtx.Trk[TrkID].PreFX[FX_Idx + 1 - offset] == FxdCtx.FXGUID[FX_Idx] then
                    FXisInPreChain = true
                end
            end

            if FxdCtx.Trk[TrkID].PreFX[1] and not FxdCtx.Trk[TrkID].PreFX_Hide and FX_Idx == #FxdCtx.Trk[TrkID].PreFX - 1 + offset then
                GF.AddSpaceBtwnFXs(FX_Idx, 'End of PreFX', nil)
            end

            if FXisInPreChain then
                if FX_Idx + 1 - offset == #FxdCtx.Trk[TrkID].PreFX and not FxdCtx.Trk[TrkID].PreFX_Hide then
                    local R, B = r.ImGui_GetItemRectMax(ctx)
                    r.ImGui_DrawList_AddRect(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B,
                        r.ImGui_GetColor(ctx, r.ImGui_Col_Button()))
                    r.ImGui_DrawList_AddRectFilled(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B, 0xcccccc10)
                end
            end
            ------------------------------------------
            if FX_Idx + 1 == RepeatTimeForWindows and not FxdCtx.Trk[TrkID].PostFX[1] then -- add last space
                GF.AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc')
            elseif FX_Idx + 1 == RepeatTimeForWindows and FxdCtx.Trk[TrkID].PostFX[1] then
                GF.AddSpaceBtwnFXs(Sel_Track_FX_Count - #FxdCtx.Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
            end
        end --for repeat as many times as FX instances


        for i = 0, #FxdCtx.FXGUID do
            local FXid = r.TrackFX_GetFXGUID(LT_Track, i)

            --Detects if any FX is deleted
            if FXid == nil then
                --Deleted_FXGUID = FXGUID[i]

                --DeleteAllParamOfFX(Deleted_FXGUID, TrkID)
                FxdCtx.FXGUID[i] = nil
            else
            end
        end

        if Sel_Track_FX_Count == 0 and DeletePrms == nil then --if it's the only fx
            state_helpers.DeleteAllParamOfFX(FxdCtx.FXGUID[0], TrkID, 0)
            FxdCtx.FXGUID[0] = nil
            DeletePrms = true
        elseif Sel_Track_FX_Count ~= 0 then
            DeletePrms = nil
        end


        if Sel_Track_FX_Count == 0 then GF.AddSpaceBtwnFXs(0, false, true) end



        --when user switch selected track...
        if TrkID ~= TrkID_End and TrkID_End ~= nil and Sel_Track_FX_Count > 0 then
            Sendgmems = nil
            WaitForGmem = 0

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
                        for P, _ in ipairs(FxdCtx.FX[FxGUID]) do
                            local FP = FxdCtx.FX[FxGUID][P]
                            FP.ModAMT = FP.ModAMT or {}
                            FP.ModBipolar = FP.ModBipolar or {}
                            if FP.WhichCC then
                                for m = 1, 8, 1 do
                                    local Amt = FP.ModAMT[m]
                                    if FP.ModBipolar[m] then Amt = FP.ModAMT[m] + 100 end

                                    if FP.ModAMT[m] then r.gmem_write(1000 * m + P, Amt) end
                                end
                            end
                        end
                    end
                end




                r.gmem_write(2, FxdCtx.PM.DIY_TrkID[TrkID] or 0)

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
end

return fxDisplay
