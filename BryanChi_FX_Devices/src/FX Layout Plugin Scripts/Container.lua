-- @noindex

local GF = require("src.Functions.General Functions")
local gui_helpers = require("src.Components.Gui_Helpers")

r                                  = reaper

local FX_Idx                       = PluginScript.FX_Idx
local FxGUID                       = PluginScript.Guid

FxdCtx.FX[FxGUID].TitleWidth       = 0
FxdCtx.FX[FxGUID].CustomTitle      = 'Container'
FxdCtx.FX[FxGUID].Width            = 35
FxdCtx.FX[FxGUID].V_Win_Btn_Height = 130
FxdCtx.FX[FxGUID].Cont_Collapse    = FxdCtx.FX[FxGUID].Cont_Collapse or 0

local Root_ID                      = 0
if FX_Idx < 0x2000000 then
    Root_ID = FX_Idx
    Root_FxGuid = FxGUID
end

DEBUG_W = DEBUG_W or {}

local Accent_Clr = 0x49CC85ff


---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------


if not FxdCtx.FX[FxGUID].Collapse then
    --[[ local nm = Vertical_FX_Name (FX_Name)
    WindowBtn = r.ImGui_Button(ctx, nm, 25, 130) ]]


    SyncWetValues(FX_Idx)
    local x, y = r.ImGui_GetCursorPos(ctx)
    r.ImGui_SetCursorPos(ctx, 3, 135)
    SyncWetValues(FX_Idx)

    FxdCtx.Wet.ActiveAny, FxdCtx.Wet.Active, FxdCtx.Wet.Val[FX_Idx] = GF.Add_WetDryKnob(ctx, 'a', '',
        FxdCtx.Wet.Val[FX_Idx] or 1, 0, 1, FX_Idx)
    r.ImGui_SetCursorPos(ctx, x, y)
end


FxdCtx.FX[FxGUID].BgClr = 0x258551ff

---------------------------------------------
---------Body--------------------------------
---------------------------------------------


Rv, FX_Count = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'container_count')
local WinW = 0
local AllW = 0

---@param TB FXTreeItem[]|nil
---@return FXTreeItem[]|nil
function Check_If_Has_Children_Prioritize_Empty_Container(TB)
    if not TB then return nil end
    local Candidate
    for _, v in ipairs(TB) do
        if v.children then
            if v.children[1] then         --if container not empty
                Candidate = v.children
            elseif not v.children[1] then -- if container empty
                local Final = v.children ~= nil and 'children' or 'candidate'
                return v.children or Candidate
            end
        end
    end
    if Candidate then
        return Candidate
    end
end

---@param FxGUID string
function CollapseIfTab(FxGUID)
    if FxdCtx.FX[FxGUID].Cont_Collapse == 0 then
        FxdCtx.FX[FxGUID].Cont_Collapse = 1
    elseif FxdCtx.FX[FxGUID].Cont_Collapse == 1 then
        FxdCtx.FX[FxGUID].Cont_Collapse = 0
    end
end

function AddTitleBgClr()
    local x, y = r.ImGui_GetCursorScreenPos(ctx)
    local X = x
    local WDL = r.ImGui_GetWindowDrawList(ctx)

    r.ImGui_DrawList_AddRectFilled(WDL, X - 25, y, X, y + 220, 0x49CC8544)
end

local function DragDropToCollapseView(FX_Id, Xpos, GUID, v)
    if (Payload_Type == 'FX_Drag' or Payload_Type == 'DND ADD FX') then
        local W, H = 130, 20
        local L, T = r.ImGui_GetCursorScreenPos(ctx)
        local L = Xpos
        --if FX_Id ~= FX[FxGUID].LastSpc then  L = L-135  end

        if r.ImGui_IsMouseHoveringRect(ctx, L, T - H / 2, L + W, T + H / 2) then
            r.ImGui_DrawList_AddLine(FxdCtx.Glob.FDL, L, T, L + W, T, Accent_Clr, 3)
            if r.ImGui_IsMouseReleased(ctx, 0) then
                --msg(FX[GUID].parent .. '   id = '..FX_Idx)
                local Drag_GUID = r.TrackFX_GetFXGUID(LT_Track, Payload)
                local ofs       = 0
                if FxdCtx.FX[GUID].parent == FxdCtx.FX[Drag_GUID].parent then -- if they're in the same container
                    if Payload < FX_Id then
                        ofs = v.scale
                    end
                end

                table.insert(FxdCtx.MovFX.FromPos, Payload)
                table.insert(FxdCtx.MovFX.ToPos, FX_Id - ofs)
                if Mods == Apl then
                    NeedCopyFX = true
                    DropPos = FX_Id
                end
            end
        end
        --r.ImGui_DrawList_AddRect(WDL, L , T-H/2, L+W, T+H/(Last or 2), 0xff77ffff)
    end
end

local function DndAddFXtoContainer_TARGET()
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0)
    if r.ImGui_BeginDragDropTarget(ctx) then
        local dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX')
        r.ImGui_EndDragDropTarget(ctx)
        if dropped and Mods == 0 then
            local FX_Id = 0x2000000 + 1 * (r.TrackFX_GetCount(LT_Track) + 1) + (Root_ID + 1) -- root containder

            if FxGUID ~= Root_FxGuid then
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1)
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1

                local function Get_Fx_Ct(TB, base_FX_Ct)
                    local C = Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct(C, Nxt_Lyr_FX_Ct)
                    end

                    return Final_FX_Ct
                end

                local FX_Ct = Get_Fx_Ct(FxdCtx.TREE, Rt_FX_Ct)

                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1)

                FX_Id = Empty_Cont_Fx_Id
            end
            r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Id)
        end
    end
    r.ImGui_PopStyleColor(ctx)
end

local function DndMoveFXtoContainer_TARGET()
    if r.ImGui_BeginDragDropTarget(ctx) then
        local rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
        r.ImGui_EndDragDropTarget(ctx)
        gui_helpers.Highlight_Itm(WDL, 0xffffff33)
        if rv and Mods == 0 then
            local FX_Id = 0x2000000 + 1 * (r.TrackFX_GetCount(LT_Track) + 1) + (Root_ID + 1) -- root containder

            if FxGUID ~= Root_FxGuid then
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1)
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1

                ---@param TB FXTreeItem[]|nil
                ---@param base_FX_Ct number
                ---@return any
                local function Get_Fx_Ct(TB, base_FX_Ct)
                    local C = Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct(C, Nxt_Lyr_FX_Ct)
                    end

                    return Final_FX_Ct
                end

                local FX_Ct = Get_Fx_Ct(FxdCtx.TREE, Rt_FX_Ct)

                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1)

                FX_Id = Empty_Cont_Fx_Id
            end
            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Id, true)
        end
    end
end

local function Render_Collapsed(v, CollapseXPos, FX_Id, CollapseYPos, i, GUID, TB)
    local Hv
    FxdCtx.FX[FxGUID].BgClr = nil


    r.ImGui_SetCursorPosX(ctx, tonumber(CollapseXPos))
    --local FX_Id = 0x2000000 + i*(r.TrackFX_GetCount(LT_Track)+1) + (FX_Idx+1)
    local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)
    FxdCtx.FX[FxGUID].Width = 50 + 150
    if GUID then
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 1, -3)

        FxdCtx.FX[GUID] = FxdCtx.FX[GUID] or {}
        local Click = GF.AddWindowBtn(GUID, FX_Id, 130, true, true, true)


        gui_helpers.SL(165)
        DragDropToCollapseView(FX_Id, CollapseXPos_screen, GUID, v)


        --SyncWetValues(FX_Id)
        if Click == 2 then
            if FxdCtx.FX[FxGUID].Sel_Preview ~= FX_Id then
                FxdCtx.FX[FxGUID].Sel_Preview = FX_Id
            else
                FxdCtx.FX[FxGUID].Sel_Preview = nil
            end
        end
        if FxdCtx.FX[FxGUID].Sel_Preview == FX_Id then
            gui_helpers.HighlightSelectedItem(nil, Accent_Clr, nil, nil, nil, nil, nil, nil, nil, 1, 1, 'GetItemRect')
        end
        SyncWetValues(FX_Id)
        FxdCtx.Wet.ActiveAny, FxdCtx.Wet.Active, FxdCtx.Wet.Val[FX_Id] = GF.Add_WetDryKnob(ctx, 'a' .. FX_Id, '',
            FxdCtx.Wet.Val[FX_Id] or 1, 0, 1, FX_Id)




        r.ImGui_PopStyleVar(ctx)
        if Hover then
            if tonumber(FX_Count) > 9 then
                FxdCtx.FX_DeviceWindow_NoScroll = r.ImGui_WindowFlags_NoScrollWithMouse()
                DisableScroll = true
                FxdCtx.FX[FxGUID].NoScroll = nil
            else
                FxdCtx.FX_DeviceWindow_NoScroll = 0
                DisableScroll = false
                FxdCtx.FX[FxGUID].NoScroll = r.ImGui_WindowFlags_NoScrollWithMouse() + r.ImGui_WindowFlags_NoScrollbar() +
                r.ImGui_WindowFlags_AlwaysAutoResize()
            end
        end



        --[[ + (    Hv or 0) ]]

        if FxdCtx.FX[FxGUID].Cont_Collapse == 1 then
            FxdCtx.FX[FxGUID].LastSpc = FX_Id + (v.scale or 0)
        end

        if Hv then return Hv end
    end
end
local X, Y = r.ImGui_GetCursorScreenPos(ctx)
--


local TB = Upcoming_Container or FxdCtx.TREE[Root_ID + 1].children

if tonumber(FX_Count) == 0 then
    r.ImGui_SetCursorScreenPos(ctx, X - 50, Y)
    r.ImGui_InvisibleButton(ctx, 'DropDest' .. FxGUID, 60, 210)

    --second_layer_container_id = first_layer_container_id + (first_layer_fx_count * second_layer_container_pos)

    DndMoveFXtoContainer_TARGET()
    DndAddFXtoContainer_TARGET()
else
    local CollapseXPos, CollapseYPos = r.ImGui_GetCursorPos(ctx)
    CollapseXPos_screen              = r.ImGui_GetCursorScreenPos(ctx)
    local PreviewW, LastSpc

    for i, v in ipairs(Upcoming_Container or FxdCtx.TREE[Root_ID + 1].children) do
        local FX_Id = v.addr_fxid
        local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)



        if FxdCtx.FX[FxGUID].Cont_Collapse == 1 then
            local W = Render_Collapsed(v, CollapseXPos, FX_Id, CollapseYPos, i, GUID, TB)
            if W then PreviewW = W end
            --FX[FxGUID].BgClr = 0xffffff44
        else -- if not collapsed
            --FX[FxGUID].BgClr = 0xff22ff44
            local function Render_Normal()
                local diff, Cur_X_ofs
                if i == 1 then
                    gui_helpers.SL(nil, 0)
                    GF.AddSpaceBtwnFXs(FX_Id, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container,
                        AdditionalWidth)
                    gui_helpers.SL(nil, 0)
                end


                if v.children then
                    Upcoming_Container = v.children
                    Upcoming_Container_Parent = v
                end


                local Hv = GF.createFXWindow(FX_Id)
                gui_helpers.SL(nil, 0)

                if v.scale and GUID then
                    FxdCtx.FX[GUID] = FxdCtx.FX[GUID] or {}
                    FxdCtx.FX[GUID].parent = v.addr_fxid - v.scale * i
                end

                local w = r.ImGui_GetItemRectSize(ctx)
                local TB = Upcoming_Container or FxdCtx.TREE[Root_ID + 1].children
                local FX_Id_next = FX_Id + (v.scale or 0)

                if r.ImGui_IsItemHovered(ctx) then Hover = true end

                LastSpc = GF.AddSpaceBtwnFXs(FX_Id_next, nil, nil, nil, nil, nil, nil, FX_Id)

                FxdCtx.FX[FxGUID].Width = (FxdCtx.FX[FxGUID].Width or 0) + w + (LastSpc or 0)

                if Hover then DisableScroll = false end
            end
            local W = Render_Normal()
        end

        if Upcoming_Container and tonumber(i) == (#Upcoming_Container or #FxdCtx.TREE[Root_ID + 1].children) then
            Upcoming_Container = nil
        end
    end


    local Add_FX_Btn_Ypos
    if FxdCtx.FX[FxGUID].Cont_Collapse == 1 and FxdCtx.FX[FxGUID].Sel_Preview then
        gui_helpers.SL()
        Add_FX_Btn_Ypos = r.ImGui_GetCursorPosY(ctx) + 24
        r.ImGui_SetCursorPosY(ctx, tonumber(CollapseYPos))

        Hv = GF.createFXWindow(FxdCtx.FX[FxGUID].Sel_Preview)
        if Hv then PreviewW = Hv end
        if PreviewW then FxdCtx.FX[FxGUID].Width = 50 + 150 + PreviewW end
    end
    if FxdCtx.FX[FxGUID].Cont_Collapse == 1 then
        if Add_FX_Btn_Ypos then r.ImGui_SetCursorPosY(ctx, tonumber(Add_FX_Btn_Ypos)) end
        r.ImGui_SetCursorPosX(ctx, tonumber(CollapseXPos))
        DragDropToCollapseView(FxdCtx.FX[FxGUID].LastSpc, CollapseXPos_screen)
        if r.ImGui_Button(ctx, '+', 130) then
            r.ImGui_OpenPopup(ctx, 'Btwn FX Windows' .. FxdCtx.FX[FxGUID].LastSpc)
        end
        GF.AddFX_Menu(FxdCtx.FX[FxGUID].LastSpc)
    end

    if Upcoming_Container then
        if not Upcoming_Container[1] then
            Upcoming_Container = nil
        end
    else

    end

    --[[  if NeedRetrieveLayout then
        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
        NeedRetrieveLayout = nil
    end  ]]



    if not FxdCtx.FX[FxGUID].Collapse then
        local WDL = r.ImGui_GetWindowDrawList(ctx)
        --r.ImGui_DrawList_AddRect(WDL ,XX - 33, YY, XX+FX[FxGUID].Width -35, YY+220, 0xffffffff)
        gui_helpers.HighlightSelectedItem(nil, Accent_Clr, 0, X - 33, Y, X + (FxdCtx.FX[FxGUID].Width or 190) - 35, Y + 218, h, W, 1,
            0.2, GetItemRect, Foreground, rounding, 4)
    end
end
