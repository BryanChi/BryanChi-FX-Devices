-- @noindex
-- @author Suzuki
-- @link https://forum.cockos.com/showthread.php?t=284566
-- @version 1.6.5
-- @changelog
-- + Added an indicator to the vertical tab when sample/FX is in a pad and a pad plays note.
-- @about ReaDrum Machine is a script which loads samples and FX from browser/arrange into subcontainers inside a container named ReaDrum Machine. 

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

ActiveAny, Active, Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Val[FX_Idx] or 0, 0, 1, FX_Idx,nil,FxGUID)

---------------------------------------------
---------Function----------------------------
---------------------------------------------
local posx, posy = im.GetCursorScreenPos(ctx)

track = r.GetSelectedTrack2(0, 0, false)
if track then
  trackidx = r.CSurf_TrackToID(track, false)
  track_guid = r.GetTrackGUID(track)
end

draw_list = im.GetWindowDrawList(ctx)

FLT_MIN, FLT_MAX = im.NumericLimits_Float()

dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/DragNDrop.lua")
dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/Drawing.lua")
dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/General Functions.lua")
dofile(r.GetResourcePath() .. "/Scripts/Suzuki Scripts/ReaDrum Machine/Modules/Pad Actions.lua")

local function DndMoveFXtoPad_TARGET_SWAP(a) 
  im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)
  if im.BeginDragDropTarget(ctx) then
    local FX_Drag, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
    im.EndDragDropTarget(ctx)
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    GetDrumMachineIdx(track)
    if FX_Drag and Mods == 0 then
        if Pad[a] then   -- add fx to target
          local dst_pad = Pad[a].Pad_ID
          local dst_num = Pad[a].Pad_Num
          -- dst_guid = Pad[a].Pad_GUID
          local dstfx_idx = CountPadFX(dst_num)
          local dstfx_idx = dstfx_idx + 1 -- the last slot being offset by 1
          local dst_id = ConvertPathToNestedPath(parent_id, dst_num)
          local dst_last = ConvertPathToNestedPath(dst_id, dstfx_idx)
          r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, dst_last, true) -- true = move
          r.PreventUIRefresh(-1)
          EndUndoBlock("ADD FX TO PAD")
        elseif not Pad[a] then   -- create target and add fx to it
          CountPads()
          AddPad(note_name, a) -- dst
          AddNoteFilter(notenum, pad_num)
          local dstfx_idx = CountPadFX(pad_num) 
          local dstfx_idx = dstfx_idx + 1 -- the last slot being offset by 1
          local pad_id = ConvertPathToNestedPath(parent_id, pad_num)
          local dst_last = ConvertPathToNestedPath(pad_id, dstfx_idx)
          r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, dst_last, true) -- true = move
          r.PreventUIRefresh(-1)
          EndUndoBlock("MOVE FX TO PAD")
        end
    end
  end
  im.PopStyleColor(ctx)
end

local function ButtonDrawlist(name, color, a)
  --im.DrawListSplitter_SetCurrentChannel(splitter, 0)
  color = im.IsItemHovered(ctx) and IncreaseDecreaseBrightness(color, 30) or color
  local xs, ys = im.GetItemRectMin(ctx)
  local xe, ye = im.GetItemRectMax(ctx)

  im.DrawList_AddRectFilled(draw_list, xs, ys, xe, ye, im.GetColorEx(ctx, color))
  if im.IsItemActive(ctx) then
    im.DrawList_AddRect(draw_list, xs, ys, xe, ye, 0x22FF44FF)
  end
  if DND_MOVE_FX and im.IsMouseHoveringRect(ctx,xs,ys,xe,ye) then
    local x_offset = 2
    im.DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, (RDM_DnD_Move or CustomColorsDefault.RDM_DnD_Move), 2,
        nil, 2)
  end
  if DND_ADD_FX and im.IsMouseHoveringRect(ctx,xs,ys,xe,ye) then
    local x_offset = 2
    im.DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, (RDM_DnDFX or CustomColorsDefault.RDM_DnDFX), 2,
        nil, 2)
  end
  if FX_DRAG and im.IsMouseHoveringRect(ctx,xs,ys,xe,ye) then
    local x_offset = 2
    im.DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, (RDM_DnDFX or CustomColorsDefault.RDM_DnDFX), 2,
        nil, 2)
  end
  if SELECTED and SELECTED[tostring(a)] then
    local x_offset = 1
    im.DrawList_AddRect(f_draw_list, xs - x_offset, ys - x_offset, xe + x_offset, ye + x_offset, 0x9400d3ff, 2,
      nil, 1)
  end

  local font_size = im.GetFontSize(ctx)
  local char_size_w,char_size_h = im.CalcTextSize(ctx, "A")
  local font_color = CalculateFontColor(color)

  local name = name:sub(1, 10)
  im.DrawList_AddTextEx( draw_list, nil, font_size, xs, ys + char_size_h, im.GetColorEx(ctx, font_color), name)
  im.DrawList_AddText(draw_list, xs, ys, im.GetColorEx(ctx, font_color), note_name)

  if FX[FxGUID].OPEN_PAD == a then
    if not Pad[a] then return end
    Highlight_Itm(WDL, (RDM_Pad_Highlight or CustomColorsDefault.RDM_Pad_Highlight), 0x256BB1ff)
  end
  if Pad[a] and Pad[a].Filter_ID then
    local rv = r.TrackFX_GetParam(track, Pad[a].Filter_ID, 1)
    if rv == 1 then   
      local L, T = im.GetItemRectMin(ctx)
      local R, B = im.GetItemRectMax(ctx)
      im.DrawList_AddRectFilled(f_draw_list, L, T, R, B + 15, 0xfde58372, rounding)
    end
  end
end

local function DrawListButton(name, color, round_side, icon, hover, offset)
  --im.DrawListSplitter_SetCurrentChannel(splitter, 1)
  local multi_color = IS_DRAGGING_RIGHT_CANVAS and color or ColorToHex(color, hover and 50 or 0)
  local xs, ys = im.GetItemRectMin(ctx)
  local xe, ye = im.GetItemRectMax(ctx)
  local w = xe - xs
  local h = ye - ys

  local round_flag = round_side and ROUND_FLAG[round_side] or nil
  local round_amt = round_flag and ROUND_CORNER or 0

  im.DrawList_AddRectFilled(draw_list, xs, ys, xe, ye, im.GetColorEx(ctx, multi_color), round_amt,
    round_flag)
  if im.IsItemActive(ctx) then
    im.DrawList_AddRect(f_draw_list, xs - 2, ys - 2, xe + 2, ye + 2, 0x22FF44FF, 3, nil, 2)
  end

  if icon then im.PushFont(ctx, icon1_small) end

  local label_size = im.CalcTextSize(ctx, name)
  local FONT_SIZE = im.GetFontSize(ctx)
  local font_color = CalculateFontColor(color)

  im.DrawList_AddTextEx(draw_list, nil, FONT_SIZE, xs + (w / 2) - (label_size / 2) + (offset or 0),
    ys + ((h / 2)) - FONT_SIZE / 2, im.GetColorEx(ctx, font_color), name)
  if icon then im.PopFont(ctx) end
end

local function OpenFXInsidePad(a)
  if not Pad[a] then return end 
  local padfx_idx = CountPadFX(Pad[a].Pad_Num)
  for f = 1, padfx_idx do
    local FX_Id = ConvertPathToNestedPath(Pad[a].Pad_ID, f)
    local FX_Id_next = ConvertPathToNestedPath(Pad[a].Pad_ID, f + 1)
    local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)
    Spc = AddSpaceBtwnFXs(FX_Id)
    im.SameLine(ctx, nil, 0)
    createFXWindow(FX_Id)
    SL(nil, 0)
    local w = im.GetItemRectSize(ctx)
    if f == tonumber(padfx_idx) then
      LastSpc = AddSpaceBtwnFXs(FX_Id_next, nil, nil, nil, nil, nil, nil, FX_Id)
    end 
    FX[FxGUID].Width = (FX[FxGUID].Width or 0) + w + (Spc or 0)
    if im.IsItemHovered(ctx) then DisableScroll = false end
  end
end

local function DrawPads(loopmin, loopmax)
  local RETURN 
  --im.DrawListSplitter_Split(SPLITTER, 2)
  CheckDNDType()
  DoubleClickActions(loopmin, loopmax)

  for a = loopmin, loopmax do
    notenum = a - 1
    note_name = getNoteName(notenum + midi_oct_offs)

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
    local FX_VISIBLE
    im.SetCursorPos(ctx, x, y)
    local ret = im.InvisibleButton(ctx, pad_name .. "##" .. a, 75, 30)
    ButtonDrawlist(pad_name, Pad[a] and (RDM_PadOn or CustomColorsDefault.RDM_PadOn) or (RDM_PadOff or CustomColorsDefault.RDM_PadOff), a)
    DndAddFX_TARGET(a)
    DndAddSample_TARGET(a)
    -- DndAddMultipleSamples_TARGET(a)
    DndMoveFX_TARGET_SWAP(a)
    DndMoveFXtoPad_TARGET_SWAP(a)
    PadMenu(a, note_name)
    if ret then 
      ClickPadActions(a)
    elseif im.IsItemClicked(ctx, 1) and Pad[a] and not CTRL then

      FX[FxGUID].OPEN_PAD = toggle2(FX[FxGUID].OPEN_PAD, a)

    elseif SHIFT and im.IsMouseDragging(ctx, 0) and im.IsItemActive(ctx) then
      AdjustPadVolume(a)
    else
      DndMoveFX_SRC(a)
    end

    im.SetCursorPos(ctx, x, y + 30)
    im.InvisibleButton(ctx, "▶##play" .. a, 25, 15)
    SendMidiNote(notenum)
    DrawListButton("-", (RDM_Play or CustomColorsDefault.RDM_Play), nil, true)

    im.SetCursorPos(ctx, x + 25, y + 30)
    if im.InvisibleButton(ctx, "S##solo" .. a, 25, 15) then
      if SELECTED then
        Unmuted = 0
        CountSelected = 0
        for k, v in pairs(SELECTED) do
          local k = tonumber(k)
          if Pad[k] then
          CountSelected = CountSelected + 1
            if r.TrackFX_GetEnabled(track, Pad[k].Pad_ID) then
              Unmuted = Unmuted + 1
            end
          end
        end
        if CountSelected == Unmuted then
          AllUnmuted = true
        end
        CountPads() -- pads_idx
        HowManyMuted = 0
        for i = 1, pads_idx do
          local _, pad_id = r.TrackFX_GetNamedConfigParm(track, parent_id, "container_item." .. i - 1)
          local rv = r.TrackFX_GetEnabled(track, pad_id)
          if not rv then
            HowManyMuted = HowManyMuted + 1
          end
        end
        if AllUnmuted and pads_idx - HowManyMuted == CountSelected then
          for i = 1, pads_idx do -- unmute all
            local _, pad_id = r.TrackFX_GetNamedConfigParm(track, parent_id, "container_item." .. i - 1) -- 0 based
            r.TrackFX_SetEnabled(track, pad_id, true)
          end
        else
          for i = 1, pads_idx do -- mute all
            local _, pad_id = r.TrackFX_GetNamedConfigParm(track, parent_id, "container_item." .. i - 1) -- 0 based
            r.TrackFX_SetEnabled(track, pad_id, false)
          end
          for k, v in pairs(SELECTED) do
            local k = tonumber(k)
            if Pad[k] then
              r.TrackFX_SetEnabled(track, Pad[k].Pad_ID, true)
            end
          end
        end
        SELECTED = nil
      else
        if Pad[a] then
          CountPads() -- pads_idx
          if Pad[a].Pad_Num == 1 then
            retval1 = false
          else
            retval1 = r.TrackFX_GetEnabled(track, Pad[a].Previous_Pad_ID)
          end
          local retval2 = r.TrackFX_GetEnabled(track, Pad[a].Next_Pad_ID)
          if retval1 == false and retval2 == false then -- unsolo
            for i = 1, pads_idx do
              local _, pad_id = r.TrackFX_GetNamedConfigParm(track, parent_id, "container_item." .. i - 1) -- 0 based
              r.TrackFX_SetEnabled(track, pad_id, true)
            end
          else -- solo
            for i = 1, pads_idx do
              local _, pad_id = r.TrackFX_GetNamedConfigParm(track, parent_id, "container_item." .. i - 1) -- 0 based
              r.TrackFX_SetEnabled(track, pad_id, false)
            end
            r.TrackFX_SetEnabled(track, Pad[a].Pad_ID, true)
          end
        end
      end
    end
    --if Pad[a] then
    --  local ok = r.TrackFX_GetEnabled(track, Pad[a].Pad_ID)
    --  DrawListButton("S", ok and 0xff or 0xf1c524ff, nil, nil)
    --else
    DrawListButton("S", (RDM_Solo or CustomColorsDefault.RDM_Solo), nil, nil)
    --end

    im.SetCursorPos(ctx, x + 50, y + 30)
    if im.InvisibleButton(ctx, "M##mute" .. a, 25, 15) then
      if SELECTED then
        for k, v in pairs(SELECTED) do
          local k = tonumber(k)
          if Pad[k] and Pad[k].RS5k_ID then 
            local retval = r.TrackFX_GetEnabled(track, Pad[k].Pad_ID)
            if retval == true then
              r.TrackFX_SetEnabled(track, Pad[k].Pad_ID, false)
            else
              r.TrackFX_SetEnabled(track, Pad[k].Pad_ID, true)
            end
          end
        end
        SELECTED = nil
      else
        if Pad[a] then
        local retval = r.TrackFX_GetEnabled(track, Pad[a].Pad_ID)
          if retval == true then
            r.TrackFX_SetEnabled(track, Pad[a].Pad_ID, false)
          else
            r.TrackFX_SetEnabled(track, Pad[a].Pad_ID, true)
          end
        end
      end
    end
    if Pad[a] then
      mute_color = r.TrackFX_GetEnabled(track, Pad[a].Pad_ID)
      DrawListButton("M", mute_color == true and (RDM_Mute or CustomColorsDefault.RDM_Mute) or 0xff2222ff, nil, nil)
    else
      DrawListButton("M", (RDM_Mute or CustomColorsDefault.RDM_Mute), nil, nil)
    end
    if FX[FxGUID].OPEN_PAD == a then 
      RETURN = a 
    end 
  end
  --im.DrawListSplitter_Merge(SPLITTER)
  if RETURN then return RETURN end 
end

--[[ function Draw_Enclose_OpenFXs()
  local DL = im.GetWindowDrawList(ctx)
  im.DrawList_AddRect(DL,  )
end ]]

---------------------------------------------
---------Body (Drawing)----------------------
---------------------------------------------
  
local s_window_x, s_window_y = im.GetStyleVar(ctx, im.StyleVar_WindowPadding)
local s_frame_x, s_frame_y = im.GetStyleVar(ctx, im.StyleVar_FramePadding)

local tw, th = im.CalcTextSize(ctx, "A") -- just single letter
local iw, ih = tw + (s_frame_x * 2), th + (s_frame_y * 2)

local def_btn_h = tw

local w_open, w_closed = 250, def_btn_h + (s_window_x * 2)

if not FX[FXGUID[FX_Idx]].Collapse then
  CheckKeys()
  UpdatePadID()
  midi_oct_offs = GetMidiOctOffsSettings()
  local wx, wy = im.GetWindowPos(ctx)
  local w_open, w_closed = 250, def_btn_h + s_window_x * 2 + 10
  local h = 220
  local hh = h + 100
  local hy = hh / 8
  
  im.PushStyleColor(ctx, im.Col_ChildBg, (RDM_BG or CustomColorsDefault.RDM_BG))
  im.BeginGroup(ctx)
    
  draw_list = im.GetWindowDrawList(ctx)                  -- 4 x 4 left vertical tab drawing
  f_draw_list = im.GetForegroundDrawList(ctx) 
  
  local x, y = im.GetCursorPos(ctx)
    
  local _, n = r.GetProjExtState(0, "ReaDrum Machine", track_guid .. "LAST_MENU")
  if n ~= nil then
    FX[FxGUID].LAST_MENU = tonumber(n)
  end

  im.SetCursorPos(ctx, x, y - 7)
  if im.BeginChild(ctx, 'BUTTON_SECTION', w_closed - 10, h + 100) then   -- vertical tab
    for i = 1, 8 do
      im.SetCursorPos(ctx, 3,  y + 145 - (i - 1) * 24 - 6)
      local rv = im.InvisibleButton(ctx, "B" .. i, 20, 20)
      local xs, ys = im.GetItemRectMin(ctx)
      local xe, ye = im.GetItemRectMax(ctx)
      for hi = 1, 4 do
        for vi = 1, 4 do
          local num = (i - 1) * 16 + (hi - 1) * 4 + vi
          if Pad[num] and Pad[num].Filter_ID then -- flash pad
            local rv = r.TrackFX_GetParam(LT_Track, Pad[num].Filter_ID, 1)
            if rv == 1 then
              rect_color = 0xffd700ff
            else
              rect_color = 0xffffffff
            end
          else
            rect_color = (RDM_VTab or CustomColorsDefault.RDM_VTab)
          end
          im.DrawList_AddRectFilled(draw_list, xs + 5 * (vi - 1), ye - 5 * (hi - 1), xs + 4 + 5 * (vi - 1), ye - 4 - 5 * (hi - 1), rect_color)
        end
      end
      if rv then
        FX[FxGUID].LAST_MENU = RememberTab(FX[FxGUID].LAST_MENU, i)
      end
      im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)
      if im.BeginDragDropTarget(ctx) then
        im.AcceptDragDropPayload(ctx, 'DND ADD FX')
        im.AcceptDragDropPayload(ctx, 'FX_DRAG')
        im.AcceptDragDropPayload(ctx, 'DND MOVE FX')
        im.EndDragDropTarget(ctx)
      end
      im.PopStyleColor(ctx)
      if (DND_ADD_FX or DND_MOVE_FX or FX_DRAG or im.IsMouseDragging(ctx, 0)) and im.IsMouseHoveringRect(ctx, xs, ys, xe, ye) then
        FX[FxGUID].LAST_MENU = i
        r.SetProjExtState(0, "ReaDrum Machine", track_guid .. "LAST_MENU", i)
      end
      HighlightHvredItem()
      if FX[FxGUID].LAST_MENU == i then 
        Highlight_Itm(draw_list, (RDM_VTab_Highlight or CustomColorsDefault.RDM_VTab_Highlight), (RDM_VTab_Highlight_Edge or CustomColorsDefault.RDM_VTab_Highlight_Edge))
      end
    end
    im.EndChild(ctx)
  end
  local openpad 
  if FX[FxGUID].LAST_MENU then       -- Open pads manu
    im.SetCursorPos(ctx, x + w_closed - 10, y - 7)
    if im.BeginChild(ctx, "child_menu", w_open + 250, h + 88) then
      local high = 0 + 16 * (FX[FxGUID].LAST_MENU)
      local low = 0 + 16 * (FX[FxGUID].LAST_MENU - 1) + 1
      openpad = DrawPads(low, high)
      im.EndChild(ctx)
    end
  end

  if FX[FxGUID].OPEN_PAD == openpad and openpad then
      
    im.SetCursorPos(ctx, 340 + 5,0)
    local x1, y1 = im.GetCursorScreenPos(ctx)

    OpenFXInsidePad(FX[FxGUID].OPEN_PAD)
    
    local x, y = im.GetCursorScreenPos(ctx)

    im.DrawList_AddRect(f_draw_list, x1-2, y1, x, y + 220 - 1, 0x123456ff, nil, nil, 2) -- leftover remains when pad is moved while opening fx inside pad
  end
  im.Dummy(ctx,1,1)
  im.EndGroup(ctx)
  im.PopStyleColor(ctx)
  CheckStaleData()
end
