-- @noindex
-- author Suzuki
-- link https://forum.cockos.com/showthread.php?t=284566


r = reaper
Pad          = {}

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid

---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------
FX[FxGUID].TitleWidth = 200 -- Use this to set title bar width 
FX[FxGUID].Width = 350   -- use this to set the device's width

local Root_ID = 0
if FX_Idx < 0x2000000 then Root_ID = FX_Idx   Root_FxGuid = FxGUID end 

ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)


---------------------------------------------
---------Function----------------------------
---------------------------------------------
local posx, posy = r.ImGui_GetCursorScreenPos(ctx)
track = r.GetSelectedTrack2(0, 0, false)

draw_list = r.ImGui_GetWindowDrawList(ctx)

FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/DragNDrop.lua")
dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/Drawing.lua")
dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/General Functions.lua")
dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/Pad Actions.lua")

local function OpenFXInsidePad(a)
  CountPadFX(Pad[a].Pad_Num) -- padfx_idx
  for f = 1, padfx_idx do
    DL = r.ImGui_GetBackgroundDrawList(ctx)
    FX_Id = get_fx_id_from_container_path(track, parent_id, Pad[a].Pad_Num, f)
    FX_Id_next = get_fx_id_from_container_path(track, parent_id, Pad[a].Pad_Num, f + 1)
    local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)
    SL(nil, 0)
    AddSpaceBtwnFXs(FX_Id)
    Xpos_Right, Ypos_Btm = r.ImGui_GetItemRectMax(ctx)
    Xpos_Left, Ypos_Top = r.ImGui_GetItemRectMin(ctx)
    r.ImGui_DrawList_AddLine(DL, Xpos_Left, Ypos_Top, Xpos_Right, Ypos_Top,
    Clr.Dvdr.outline)
    r.ImGui_DrawList_AddLine(DL, Xpos_Left, Ypos_Btm, Xpos_Right, Ypos_Btm,
    Clr.Dvdr.outline)
    r.ImGui_DrawList_AddLine(DL, Xpos_Right, Ypos_Top, Xpos_Right, Ypos_Btm,
    Clr.Dvdr.outline, 14)
    SL(nil, 0)
    createFXWindow(FX_Id)
    SL(nil, 0)
    LastSpc = AddSpaceBtwnFXs(FX_Id_next, nil, nil, nil, nil, nil, nil, FX_Id)
    local w = r.ImGui_GetItemRectSize(ctx)
    FX[FxGUID].Width = (FX[FxGUID].Width or 0) + w + (LastSpc or 0)
    if r.ImGui_IsItemHovered(ctx) then DisableScroll = false end
  end
end

local function DndMoveFXtoPad_TARGET_SWAP(a) 
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0)
  if r.ImGui_BeginDragDropTarget(ctx) then
    local FX_Drag, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
    r.ImGui_EndDragDropTarget(ctx)
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    GetDrumMachineIdx()
    if FX_Drag and Mods == 0 then
        if Pad[a] then   -- add fx to target
          local dst_pad = Pad[a].Pad_ID
          local dst_num = Pad[a].Pad_Num
          -- dst_guid = Pad[a].Pad_GUID
          local dstfx_idx = CountPadFX(dst_num)
          dstfx_idx = dstfx_idx + 1 -- the last slot being offset by 1
          local dst_last = get_fx_id_from_container_path(track, parent_id, dst_num, dstfx_idx)
          r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, dst_last, true) -- true = move
          r.PreventUIRefresh(-1)
          EndUndoBlock("ADD FX TO PAD")
        elseif not Pad[a] then   -- create target and add fx to it
          CountPads()
          AddPad(note_name, a) -- dst
          AddNoteFilter(notenum, pad_num)
          local previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
          local next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
          Pad[a] = { -- dst
            Previous_Pad_ID = previous_pad_id,
            Pad_ID = pad_id,
            Next_Pad_ID = next_pad_id,
            Pad_Num = pad_num,
            TblIdx = a,
            Note_Num = notenum
          }
          local dstfx_idx = CountPadFX(pad_num) 
          dstfx_idx = dstfx_idx + 1 -- the last slot being offset by 1
          local dst_last = get_fx_id_from_container_path(track, parent_id, pad_num, dstfx_idx)
          r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, dst_last, true) -- true = move
          r.PreventUIRefresh(-1)
          EndUndoBlock("MOVE FX TO PAD")
        end
    end
  end
  r.ImGui_PopStyleColor(ctx)
end

local function ButtonDrawlist(splitter, name, color)
  r.ImGui_DrawListSplitter_SetCurrentChannel(splitter, 0)
  color = r.ImGui_IsItemHovered(ctx) and IncreaseDecreaseBrightness(color, 30) or color
  local xs, ys = r.ImGui_GetItemRectMin(ctx)
  local xe, ye = r.ImGui_GetItemRectMax(ctx)

  r.ImGui_DrawList_AddRectFilled(draw_list, xs, ys, xe, ye, r.ImGui_GetColorEx(ctx, color))
  if r.ImGui_IsItemActive(ctx) then
    r.ImGui_DrawList_AddRect(draw_list, xs, ys, xe, ye, 0x22FF44FF)
  end
  if DND_MOVE_FX and r.ImGui_IsMouseHoveringRect(ctx,xs,ys,xe,ye) then
    local x_offset = 2
    r.ImGui_DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, 0xFF0000FF, 2,
        nil, 2)
  end
  if DND_ADD_FX and r.ImGui_IsMouseHoveringRect(ctx,xs,ys,xe,ye) then
    local x_offset = 2
    r.ImGui_DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, COLOR["dnd"], 2,
        nil, 2)
  end
  if FX_DRAG and r.ImGui_IsMouseHoveringRect(ctx,xs,ys,xe,ye) then
    local x_offset = 2
    r.ImGui_DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, COLOR["dnd"], 2,
        nil, 2)
  end

  local font_size = r.ImGui_GetFontSize(ctx)
  local char_size_w,char_size_h = r.ImGui_CalcTextSize(ctx, "A")
  local font_color = CalculateFontColor(color)

  local name = name:sub(1, 11)
  r.ImGui_DrawList_AddTextEx( draw_list, nil, font_size, xs, ys + char_size_h, r.ImGui_GetColorEx(ctx, font_color), name)
  r.ImGui_DrawList_AddText(draw_list, xs, ys, 0xffffffff, note_name)
end

local function DrawListButton(splitter, name, color, round_side, icon, hover, offset)
  r.ImGui_DrawListSplitter_SetCurrentChannel(splitter, 1)
  local multi_color = IS_DRAGGING_RIGHT_CANVAS and color or ColorToHex(color, hover and 50 or 0)
  local xs, ys = r.ImGui_GetItemRectMin(ctx)
  local xe, ye = r.ImGui_GetItemRectMax(ctx)
  local w = xe - xs
  local h = ye - ys

  local round_flag = round_side and ROUND_FLAG[round_side] or nil
  local round_amt = round_flag and ROUND_CORNER or 0

  r.ImGui_DrawList_AddRectFilled(draw_list, xs, ys, xe, ye, r.ImGui_GetColorEx(ctx, multi_color), round_amt,
    round_flag)
  if r.ImGui_IsItemActive(ctx) then
    r.ImGui_DrawList_AddRect(f_draw_list, xs - 2, ys - 2, xe + 2, ye + 2, 0x22FF44FF, 3, nil, 2)
  end

  if icon then r.ImGui_PushFont(ctx, FontAwesome_small) end

  local label_size = r.ImGui_CalcTextSize(ctx, name)
  local FONT_SIZE = r.ImGui_GetFontSize(ctx)
  local font_color = CalculateFontColor(color)

  r.ImGui_DrawList_AddTextEx(draw_list, nil, FONT_SIZE, xs + (w / 2) - (label_size / 2) + (offset or 0),
    ys + ((h / 2)) - FONT_SIZE / 2, r.ImGui_GetColorEx(ctx, font_color), name)
  if icon then r.ImGui_PopFont(ctx) end
end

local function DrawPads(loopmin, loopmax)
  local SPLITTER = r.ImGui_CreateDrawListSplitter(draw_list)
  r.ImGui_DrawListSplitter_Split(SPLITTER, 2)
  CheckDNDType()

  for a = loopmin, loopmax do
    notenum = a - 1
    note_name = getNoteName(notenum)

    if Pad[a] then
      if Pad[a].Rename then
        pad_name = Pad[a].Rename
      elseif Pad[a].Name then
        pad_name = Pad[a].Name
      else
        pad_name = ""
      end
    else
      pad_name = ""
    end
    local y = 150 + math.floor((a - loopmin) / 4) * -50 -- start position + math.floor * - row offset
    local x = 5 + (a - 1) % 4 * 80

    r.ImGui_SetCursorPos(ctx, x, y)
    local ret = r.ImGui_InvisibleButton(ctx, pad_name .. "##" .. a, 75, 30)
    ButtonDrawlist(SPLITTER, pad_name, Pad[a] and COLOR["Container"] or COLOR["n"])
    DndAddFX_TARGET(a)
    DndAddSample_TARGET(a)
    -- DndAddMultipleSamples_TARGET(a)
    DndMoveFX_TARGET_SWAP(a)
    DndMoveFXtoPad_TARGET_SWAP(a)
    PadMenu(a, note_name)
    if ret then 
      ClickPadActions(a)
    elseif r.ImGui_IsItemClicked(ctx, 1) and Pad[a] then 
      if not OPEN_PAD then
        FX_VISIBLE = true
      end
      if OPEN_PAD == a then
        FX_VISIBLE = not FX_VISIBLE
      else
        if not FX_VISIBLE then
          FX_VISIBLE = true
        end
      end
      OPEN_PAD = a
      if FX_VISIBLE then
        OpenFXInsidePad(a)
      end
    else
      DndMoveFX_SRC(a)
    end

    r.ImGui_SetCursorPos(ctx, x, y + 30)
    r.ImGui_InvisibleButton(ctx, "▶##play" .. a, 25, 15)
    SendMidiNote(notenum)
    DrawListButton(SPLITTER,"-", COLOR["n"], nil, true)

    r.ImGui_SetCursorPos(ctx, x + 25, y + 30)
    if r.ImGui_InvisibleButton(ctx, "S##solo" .. a, 25, 15) then
      if Pad[a] then
        CountPads() -- pads_idx
        if Pad[a].Pad_Num == 1 then
          retval1 = false
        else
          retval1 = r.TrackFX_GetEnabled(track, Pad[a].Previous_Pad_ID)
        end
        retval2 = r.TrackFX_GetEnabled(track, Pad[a].Next_Pad_ID)
        if retval1 == false and retval2 == false then -- unsolo
          for i = 1, pads_idx do
            local pad_id = get_fx_id_from_container_path(track, parent_id, i)
            r.TrackFX_SetEnabled(track, pad_id, true)
          end
        else -- solo
          for i = 1, pads_idx do
            local pad_id = get_fx_id_from_container_path(track, parent_id, i)
            r.TrackFX_SetEnabled(track, pad_id, false)
          end
          r.TrackFX_SetEnabled(track, Pad[a].Pad_ID, true)
        end
      end
    end
    --if Pad[a] then
    --  local ok = r.TrackFX_GetEnabled(track, Pad[a].Pad_ID)
    --  DrawListButton("S", ok and 0xff or 0xf1c524ff, nil, nil)
    --else
    DrawListButton(SPLITTER, "S", COLOR["n"], nil, nil)
    --end

    r.ImGui_SetCursorPos(ctx, x + 50, y + 30)
    if r.ImGui_InvisibleButton(ctx, "M##mute" .. a, 25, 15) then
      if Pad[a] then
        local retval = r.TrackFX_GetEnabled(track, Pad[a].Pad_ID)
        if retval == true then
          r.TrackFX_SetEnabled(track, Pad[a].Pad_ID, false)
        else
          r.TrackFX_SetEnabled(track, Pad[a].Pad_ID, true)
        end
      end
    end
    if Pad[a] then
      mute_color = r.TrackFX_GetEnabled(track, Pad[a].Pad_ID)
      DrawListButton(SPLITTER, "M", mute_color == true and COLOR["n"] or 0xff2222ff, nil, nil)
    else
      DrawListButton(SPLITTER, "M", COLOR["n"], nil, nil)
    end
  end
  r.ImGui_DrawListSplitter_Merge(SPLITTER)
end

---------------------------------------------
---------Body (Drawing)----------------------
---------------------------------------------


COLOR              = {
    ["n"]           = 0xff,
    ["Container"]   = 0x123456FF,
    ["dnd"]         = 0x00b4d8ff,
    ["dnd_replace"] = 0xdc5454ff,
    ["dnd_swap"]    = 0xcd6dc6ff,
    ["bg"] = 0x141414ff
  }
  

local s_window_x, s_window_y = r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_WindowPadding())
local s_frame_x, s_frame_y = r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_FramePadding())

local tw, th = r.ImGui_CalcTextSize(ctx, "A") -- just single letter
local iw, ih = tw + (s_frame_x * 2), th + (s_frame_y * 2)

local def_btn_h = tw

local w_open, w_closed = 250, def_btn_h + (s_window_x * 2)

if not FX[FXGUID[FX_Idx]].Collapse then
  CheckKeys()
  UpdatePadID()
    local wx, wy = r.ImGui_GetWindowPos(ctx)
    local w_open, w_closed = 250, def_btn_h + s_window_x * 2 + 10
    local h = 220
    local hh = h + 100
    local hy = hh / 8
  
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), COLOR["bg"])
    r.ImGui_BeginGroup(ctx)
    
    draw_list = r.ImGui_GetWindowDrawList(ctx)                  -- 4 x 4 left veertical bar drawing
    f_draw_list = r.ImGui_GetForegroundDrawList(ctx) 
    local SPLITTER = r.ImGui_CreateDrawListSplitter(f_draw_list)
    r.ImGui_DrawListSplitter_Split(SPLITTER, 2)                     -- NUMBER OF Z ORDER CHANNELS
    --if Pad[a] then
    --  r.ImGui_DrawListSplitter_SetCurrentChannel(SPLITTER, 1)       -- SET HIGHER PRIORITY TO DRAW FIRST
    --  local x, y = r.ImGui_GetCursorPos(ctx)
    --  r.ImGui_DrawList_AddRectFilled(f_draw_list, 100, 100, 100, 100, 0x654321FF)
    --end
    r.ImGui_DrawListSplitter_SetCurrentChannel(SPLITTER, 0)       -- SET LOWER PRIORITY TO DRAW AFTER
    local x, y = r.ImGui_GetCursorPos(ctx)
    --  r.ImGui_DrawList_AddRect(draw_list, wx+x-2, wy+y-2+33 * (i-1), wx+x+33, wy+y+33 * i, 0xFFFFFFFF)  -- white box when selected
     for ci = 0, 8 * (hy - 18), hy - 16.2 do
       for bi = 0, 15, 5 do
         for i = 0, 15, 5 do
           r.ImGui_DrawList_AddRectFilled(f_draw_list, wx + x + i, wy + y + bi + ci, wx + x + 3 + i, wy + y + 3 + bi + ci,
            0x252525FF)
         end
      end
     end
    r.ImGui_DrawListSplitter_Merge(SPLITTER)       -- MERGE EVERYTHING FOR RENDER
  
    if r.ImGui_BeginChild(ctx, 'BUTTON_SECTION', w_closed - 10, h + 100, false) then   -- vertical tab
      for i = 1, 8 do
        r.ImGui_SetCursorPos(ctx, 0, (y) * (i / 1.3  - 0.8))
        if r.ImGui_InvisibleButton(ctx, "B" .. i, 20, 20) then
          if not LAST_MENU then
            VUI_VISIBLE = true
          end
          if LAST_MENU == i then
            VUI_VISIBLE = not VUI_VISIBLE
          else
            if not VUI_VISIBLE then
              VUI_VISIBLE = true
            end
          end
          LAST_MENU = i
        end
      end
      r.ImGui_EndChild(ctx)
    end
    if VUI_VISIBLE then       -- Open pads manu
      r.ImGui_SetCursorPos(ctx, x + w_closed - 10, y - 7)
      if r.ImGui_BeginChild(ctx, "child_menu", w_open + 250, h + 88) then
        if LAST_MENU == 1 then
          DrawPads(113, 128)
        elseif LAST_MENU == 2 then
          DrawPads(97, 112)
        elseif LAST_MENU == 3 then
          DrawPads(81, 96)
        elseif LAST_MENU == 4 then
          DrawPads(65, 80)
        elseif LAST_MENU == 5 then
          DrawPads(49, 64)
        elseif LAST_MENU == 6 then
          DrawPads(33, 48)
        elseif LAST_MENU == 7 then
          DrawPads(17, 32)
        elseif LAST_MENU == 8 then
          DrawPads(1, 16)
        end
        r.ImGui_EndChild(ctx)
      end
    end
    r.ImGui_EndGroup(ctx)
    r.ImGui_PopStyleColor(ctx)
    CheckStaleData()
end