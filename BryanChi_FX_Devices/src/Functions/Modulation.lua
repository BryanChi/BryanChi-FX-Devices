-- @version 1.0Beta 2

-- @noindex

r = reaper
local GF = require("src.Functions.General Functions")
local table_helpers = require("src.helpers.table_helpers")
local fs_utils = require("src.Functions.Filesystem_utils")
local layout_editor_helpers = require("src.helpers.layout_editor_helpers")
local INI_parser = require("src.helpers.INI_parser")
FxdCtx.MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
ultraschall = ultraschall

---@param TrkNum number
---@param fxid integer
---@param parmidx integer
---@param AliasName string
function SetPrmAlias(TrkNum, fxid, parmidx, AliasName)
    Retval, TrackStateChunk = ultraschall.GetTrackStateChunk_Tracknumber(TrkNum)
    FXStateChunk = ultraschall.GetFXStateChunk(TrackStateChunk)
    Retval, alteredFXStateChunk = ultraschall.AddParmAlias_FXStateChunk(FXStateChunk, fxid, parmidx, AliasName) --rv, alteredFXStateChunk = u.AddParmAlias_FXStateChunk( FXStateChunk, fxid, parmalias)

    _, TrackStateChunk = ultraschall.SetFXStateChunk(TrackStateChunk, alteredFXStateChunk)
    _ = ultraschall.SetTrackStateChunk_Tracknumber(TrkNum, TrackStateChunk)
end

---@param FX_Idx integer
---@param P_Num number
---@param FxGUID any ---TODO unused
function PrepareFXforModulation(FX_Idx, P_Num, FxGUID)
    local ParamValue_Modding = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    AssignMODtoFX = FX_Idx
    r.gmem_attach('ParamValues')
    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 and r.TrackFX_AddByName(LT_Track, 'Macros', 0, 0) == -1 then
        r.gmem_write(1, FxdCtx.PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
        GF.AddMacroJSFX()
        AssignMODtoFX = AssignMODtoFX + 1
    end


    r.gmem_write(2, FxdCtx.PM.DIY_TrkID[TrkID]) --Sends Trk GUID for jsfx to determine track
    r.gmem_write(11000 + FxdCtx.Trk.Prm.Assign, ParamValue_Modding)
end

---@param FxGUID string
---@param Fx_P integer
---@param P_Num number
---@param FX_Idx integer
function RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)
    if r.ImGui_IsMouseDoubleClicked(ctx, 1) and r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
        if FxdCtx.FX[FxGUID][Fx_P].ModAMT then
            for Mc = 1, 8, 1 do
                if FxdCtx.FX[FxGUID][Fx_P].ModAMT[Mc] then
                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.active", 0)   -- 1 active, 0 inactive
                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.effect", -100) 
                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.param", -1)   
                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_bus", 0)
                    r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_chan", 1)
                    local retval, buf = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".mod.visible") 
                        if retval and buf == "1" then
                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".mod.visible", 0) 
                        r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".mod.visible", 1)   
                        end
                    FxdCtx.FX[FxGUID][Fx_P].ModAMT[Mc] = 0
                end
            end
        end
        
    end
end

FxdCtx.MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }


---@param FxGUID string
---@param Fx_P string|number
---@param FX_Idx integer
---@param P_Num number
---@param p_value number
---@param Sldr_Width number
---@param Type "Knob"|"Vert"
function MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, Type)
    local FP = FxdCtx.FX[FxGUID][Fx_P]
    local CC = FP.WhichCC

    if --[[Link CC back when mouse is up]] Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then
        if FxdCtx.FX[FxGUID][Fx_P].WhichCC then
            local CC = FxdCtx.FX[FxGUID][Fx_P].WhichCC

            r.GetSetMediaTrackInfo_String(LT_Track,
                'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation',
                FxdCtx.FX[FxGUID][Fx_P].V, true)

            r.gmem_write(7, CC) --tells jsfx to retrieve P value
            FxdCtx.PM.TimeNow = r.time_precise()
            r.gmem_write(11000 + CC, p_value)
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.active", 1)   -- 1 active, 0 inactive
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.effect", -100) -- -100 enables midi_msg*
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.param", -1)   -- -1 not parameter link
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_bus", 15) -- 0 based, 15 = Bus 16
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_chan", 16) -- 0 based, 0 = Omni
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_msg", 176)   -- 176 is CC
            r.TrackFX_SetNamedConfigParm(LT_Track, FX_Idx, "param."..P_Num..".plink.midi_msg2", CC) -- CC value
        end

        Tweaking = nil
    end


    if r.ImGui_IsItemClicked(ctx, 1) and FP.ModAMT and AssigningMacro == nil and (Mods == 0 or Mods == Alt) then
        for M, _ in ipairs(FxdCtx.MacroNums) do
            if FP.ModAMT[M] then
                FxdCtx.Trk.Prm.Assign = FP.WhichCC
                AssigningMacro = M


                r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
                r.gmem_write(6, FP.WhichCC)
            end
            FxdCtx.PM.DragOnModdedPrm = true
        end
    elseif r.ImGui_IsItemClicked(ctx, 1) and FP.ModAMT and Mods == Shift then
        for M, _ in ipairs(FxdCtx.MacroNums) do
            if FP.ModAMT[M] then
                FxdCtx.Trk.Prm.Assign = FP.WhichCC
                BypassingMacro = M
                r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                r.gmem_write(6, FP.WhichCC)
            end
        end
        DecideShortOrLongClick = FP
        Dur = r.ImGui_GetMouseDownDuration(ctx, 1)
    --[[ elseif r.ImGui_IsItemClicked(ctx, 1) and FP.ModAMT and Mods == Alt then
        r.gmem_write(1000 * AssigningMacro + FP.WhichCC, (FP.ModAMT[M] or 0) +100 ) ]]  ---  if amount  is 100 ~ 101 then it's bipolar modulation
    end

    if DecideShortOrLongClick == FP and Dur then
        if r.ImGui_IsMouseReleased(ctx, 1) then
            if Dur < 0.14 then
                ---- if short right click
                if FP.ModBypass then
                    r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                    r.gmem_write(1000 * BypassingMacro + FxdCtx.Trk.Prm.Assign, FP.ModAMT[BypassingMacro])
                    r.gmem_write(3, FxdCtx.Trk[TrkID].ModPrmInst)
                    FP.ModBypass = nil
                else
                    FP.ModBypass = BypassingMacro
                    r.gmem_write(5, BypassingMacro)                         --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                    r.gmem_write(1000 * BypassingMacro + FxdCtx.Trk.Prm.Assign, 0) -- set mod amount to 0
                    r.gmem_write(3, FxdCtx.Trk[TrkID].ModPrmInst)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass',
                        BypassingMacro, true)
                end
            else

            end


            DecideShortOrLongClick = nil
        end
        Dur = r.ImGui_GetMouseDownDuration(ctx, 1)
    end


    if --[[Assign Mod]] AssigningMacro and r.ImGui_IsItemClicked(ctx, 1) then
        local _, ValBeforeMod
        r.GetSetMediaTrackInfo_String(LT_Track,
            'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation',
            '',
            false)
        if not ValBeforeMod then
            r.GetSetMediaTrackInfo_String(LT_Track,
                'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FxdCtx.FX[FxGUID][Fx_P].V, true)
        end


        FxdCtx.Trk.Prm.Assign = FP.WhichCC


        --store which param has which Macros assigned
        if FP.WhichMODs == nil then -- if This prm don't have a modulation assigned yet..
            FP.WhichMODs = tostring(AssigningMacro)

            FxdCtx.FX[FxGUID][Fx_P].ModAMT = FxdCtx.FX[FxGUID][Fx_P].ModAMT or {}
            FxdCtx.Trk[TrkID].ModPrmInst = (FxdCtx.Trk[TrkID].ModPrmInst or 0) + 1
            FxdCtx.FX[FxGUID][Fx_P].WhichCC = FxdCtx.Trk[TrkID].ModPrmInst
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' .. P_Num, FP.WhichCC, true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ModPrmInst', FxdCtx.Trk[TrkID].ModPrmInst, true)

            FxdCtx.Trk.Prm.Assign = FxdCtx.Trk[TrkID].ModPrmInst
        elseif FP.WhichMODs and string.find(FP.WhichMODs, tostring(AssigningMacro)) == nil then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            FP.WhichMODs = FP.WhichMODs .. tostring(AssigningMacro)
        end
        local CC = FP.WhichCC


        if not FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID] then
            FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID] = tostring(AssigningMacro)
        elseif FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID] and not string.find(FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID], tostring(AssigningMacro)) then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID] = FxdCtx.Trk.Prm.WhichMcros[CC .. TrkID] .. tostring(AssigningMacro)
        end
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods',
            FP.WhichMODs, true)

        --r.SetProjExtState(0, 'FX Devices', 'Prm'..F_Tp..'Has Which Macro Assigned, TrkID ='..TrkID, Trk.Prm.WhichMcros[F_Tp..TrkID])
        --[[ r.gmem_write(7, CC) --tells jsfx to retrieve P value
        r.gmem_write(11000 + CC, p_value) ]]

        r.gmem_write(6, CC)


        AssignToPrmNum = P_Num

        r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
        PrepareFXforModulation(FX_Idx, P_Num, FxGUID)
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.active", 1)   -- 1 active, 0 inactive
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.effect", -100) -- -100 enables midi_msg*
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.param", -1)   -- -1 not parameter link
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_bus", 15) -- 0 based, 15 = Bus 16
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_chan", 16) -- 0 based, 0 = Omni
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_msg", 176)   -- 176 is CC
        r.TrackFX_SetNamedConfigParm(LT_Track, AssignMODtoFX, "param."..AssignToPrmNum..".plink.midi_msg2", CC) -- CC value
        r.gmem_write(3, FxdCtx.Trk[TrkID].ModPrmInst)

        r.gmem_write(7, CC) --tells jsfx to rfetrieve P value

        if FP.ModBipolar[M] then  --if it's bipolar 
            r.gmem_write(11000 + CC, p_value )  -- sends parameter's value before being modulated
        else            -- if not bipolar 
            r.gmem_write(11000 + CC, p_value)
        end 
    end




    if FxdCtx.PM.DragOnModdedPrm == true and r.ImGui_IsMouseDown(ctx, 1) ~= true then
        AssigningMacro = nil
        FxdCtx.PM.DragOnModdedPrm = nil
    end
    if TrkID ~= TrkID_End then
        r.gmem_write(3, FxdCtx.Trk[TrkID].ModPrmInst or 0)
        if FP.ModAMT and FP.WhichCC then
            for M = 1, 8, 1 do
                r.gmem_write(1000 * M + FP.WhichCC, FP.ModAMT[M] or 0)
            end
        end
    end

    local Vertical
    if Type == 'Vert' then Vertical = 'Vert' end
    if FP then  FP.ModBipolar = FP.ModBipolar or {} end 
    if --[[Right Dragging to adjust Mod Amt]] FxdCtx.Trk.Prm.Assign and FP.WhichCC == FxdCtx.Trk.Prm.Assign and AssigningMacro then
        local Id = FxGUID .. FxdCtx.Trk.Prm.Assign
        local M = AssigningMacro
        local IdM = 'Param:' .. tostring(FxdCtx.Trk.Prm.Assign) .. 'Macro:' .. AssigningMacro


        local sizeX, sizeY = r.ImGui_GetItemRectSize(ctx)

        --[[
                PosX_End_Of_Slider= Prm.Pos_L[Id]+sizeX
                Prm.SldrGrabXPos[Id]=(PosX_End_Of_Slider-Prm.Pos_L[Id])*p_value
                SliderCurPos=Prm.Pos_L[Id]+Prm.SldrGrabXPos[Id] ]]

        local RightBtnDragX, RightBtnDragY = r.ImGui_GetMouseDragDelta(ctx, X, y, 1); local MouseDrag
        if Vertical == 'Vert' or Type == 'knob' then MouseDrag = -RightBtnDragY else MouseDrag = RightBtnDragX end


        FxdCtx.FX[FxGUID][Fx_P].ModAMT[M] = ((MouseDrag / 100) or 0) + (FxdCtx.FX[FxGUID][Fx_P].ModAMT[M] or 0)

        if FP.ModAMT[M] + p_value > 1 then FP.ModAMT[M] = 1 - p_value end
        if FP.ModAMT[M] + p_value < 0 then FP.ModAMT[M] = -p_value end

        local BipolarOut 
        if Mods == Alt and IsRBtnHeld then 
            FP.ModAMT[M] = math.abs( FP.ModAMT[M])
            BipolarOut = FP.ModAMT[M]  + 100

            FP.ModBipolar[M] = true 
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar','true', true)
            r.gmem_write(4, 1)
            r.gmem_write(1000 * AssigningMacro + FxdCtx.Trk.Prm.Assign, BipolarOut or  FP.ModAMT[M]) -- tells jsfx the param's mod amount

        elseif IsRBtnHeld and Mods == 0 then 
            FP.ModBipolar[M] = nil
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Bipolar','', true)
            r.gmem_write(4, 1)
            r.gmem_write(1000 * AssigningMacro + FxdCtx.Trk.Prm.Assign,  FP.ModAMT[M]) -- tells jsfx the param's mod amount

        end


        --if not IsLBtnHeld then r.gmem_write(4, 1) end --tells jsfx that user is changing Macro Mod Amount
        r.ImGui_ResetMouseDragDelta(ctx, 1)

        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Amt',FP.ModAMT[M], true)
    end



    if Type ~= 'knob' and FP.ModAMT then
        local offset = 0
        for M, _ in ipairs(FxdCtx.MacroNums) do
            if FP.ModAMT[M] and FP.ModAMT[M] ~= 0 then
                --if Modulation has been assigned to params
                local sizeX, sizeY = r.ImGui_GetItemRectSize(ctx)
                local P_V_Norm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

                --- indicator of where the param is currently
                if not FxdCtx.FX[FxGUID][Fx_P].V then
                    FxdCtx.FX[FxGUID][Fx_P].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
                end



                DrawModLines(M, true, FxdCtx.Trk[TrkID].Mod[M].Val, FxGUID, FP.WhichCC, ModLineDir or Sldr_Width,
                    FxdCtx.FX[FxGUID][Fx_P].V, Vertical, FP, offset)
                FxdCtx.Mc.V_Out[M] = (FP.ModAMT[M] * p_value)
                ParamHasMod_Any = true
                offset = offset + OffsetForMultipleMOD
            end
        end -- of reapeat for every macro
    end

    return Tweaking
end


function Get_LFO_Shape_From_File(filename)
    if filename then 


        local file = io.open(fs_utils.ConcatPath(CurrentDirectory, 'src', 'LFO Shapes', filename), 'r')
        if file then 

            local L = fs_utils.get_lines(fs_utils.ConcatPath(CurrentDirectory, 'src', 'LFO Shapes', filename))

            local content = file:read("a+")


            local Count = INI_parser.get_aftr_Equal_Num(L[1])
            local Node = {}



            for i= 1, Count or 0, 1 do 

                Node[i] = {}
                local N = Node[i] 
                --N.x = get_aftr_Equal_Num(content, i..'.x = ' )
                N.x = layout_editor_helpers.RecallGlobInfo(content , i..'.x = ', 'Num')

                N.y = layout_editor_helpers.RecallGlobInfo(content , i..'.y = ', 'Num')

                N.ctrlX = layout_editor_helpers.RecallGlobInfo(content , i..'.ctrlX = ' , "Num")

                N.ctrlY = layout_editor_helpers.RecallGlobInfo(content , i..'.ctrlY = ' , 'Num')

            end
            if Node[1] then 
                return Node
            end
        end
    end
end

function AutomateModPrm (Macro,str, jsfxMode, alias)
    FxdCtx.Trk[TrkID].AutoPrms = FxdCtx.Trk[TrkID].AutoPrms or {}
    if not table_helpers.FindExactStringInTable(FxdCtx.Trk[TrkID].AutoPrms, 'Mod'.. Macro..str) then 
        table.insert(FxdCtx.Trk[TrkID].AutoPrms, 'Mod'.. Macro..str)
        SetPrmAlias(LT_TrackNum, 1, 16+#FxdCtx.Trk[TrkID].AutoPrms ,  alias)
        r.GetFXEnvelope(LT_Track, 0, 15+#FxdCtx.Trk[TrkID].AutoPrms, true)
    end
    
    r.gmem_write(4, jsfxMode)  -- set mode to assigned mode
    r.gmem_write(5, Macro) 
    r.gmem_write(9, #FxdCtx.Trk[TrkID].AutoPrms)
    
    for i, v in ipairs(FxdCtx.Trk[TrkID].AutoPrms) do 
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Auto Mod'..i , v, true)
    end
    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: How Many Automated Prm in Modulators' , #FxdCtx.Trk[TrkID].AutoPrms, true)
end

function SetModulationToBipolar(Macro)
    r.gmem_write(4, 18) -- mode to set to bipolar 
    r.gmem_write(5, Macro)
end


function WhenRightClickOnModulators(Macro)
    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
        r.ImGui_OpenPopup(ctx, FxdCtx.Trk[TrkID].Mod[Macro].Type .. Macro .. 'Menu')
    end
    if r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
        if not AssigningMacro then AssigningMacro = Macro
        else AssigningMacro = nil
        end
    end
    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
        SetModulationToBipolar(Macro)
    end
    if AssigningMacro==Macro then gui_helpers.BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink) end 
end



function DrawLFOvalueTrail (MacroTable , x, y, Macro )
    local Pos = r.gmem_read(108+Macro)/4
    local M = MacroTable
    M.Trail = M.Trail or {}
    table.insert(M.Trail, { x = x ; y = y ; })

    if #M.Trail > 40 then table.remove(M.Trail, 1) end 



    for i, v in ipairs( M.Trail ) do 
        
        local ls = M.Trail[math.max(i-1, 1)]

        if v.x < ls.x then 
            

        elseif i > 2 then 
            r.ImGui_DrawList_AddLine(WDL, v.x , v.y , ls.x, ls.y, 0xffffff55, 8 - 16 / i )

        end 

    end


end


function Draw_LFO_Trail ()



end
