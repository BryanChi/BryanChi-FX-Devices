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

ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)


---------------------------------------------
---------Function----------------------------
---------------------------------------------
local posx, posy = r.ImGui_GetCursorScreenPos(ctx)
track = r.GetSelectedTrack2(0, 0, false)

draw_list = r.ImGui_GetWindowDrawList(ctx)

FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

local posx, posy = r.ImGui_GetCursorScreenPos(ctx)

function InsertDrumMachine()
  local found = false
  count = r.TrackFX_GetCount(track) -- 1 based
  for i = 0, count - 1 do
    local rv, rename = r.TrackFX_GetNamedConfigParm(track, i, 'renamed_name') -- 0 based
    if rename == 'ReaDrum Machine' then
      found = true
      break
    end
  end
  if not found then
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    r.TrackFX_AddByName(track, "Container", false, -1000 - count)                 -- 0 based + count(1 based) = the last slot
    r.TrackFX_SetNamedConfigParm(track, count, 'renamed_name', 'ReaDrum Machine') -- 0 based + count(1 based) = the last slot
    r.PreventUIRefresh(-1)
    EndUndoBlock("ADD DRUM MACHINE")
  end
end

function GetDrumMachineIdx()
  local found = false
  fxcount = r.TrackFX_GetCount(track)                                        -- 1based
  for fx_idx = 0, fxcount - 1 do
    rv, rename = r.TrackFX_GetNamedConfigParm(track, fx_idx, 'renamed_name') -- 0 based
    if rename == 'ReaDrum Machine' then
      parent_id = fx_idx
      found = true
      break
    end
    if not found then
      parent_id = nil
    end
  end
  if parent_id ~= nil then
  parent_id = parent_id + 1 -- 1 based
  end
  return parent_id
end

function get_fx_id_from_container_path(tr, idx1, ...) -- 1based
  local sc, rv = r.TrackFX_GetCount(tr) + 1, 0x2000000 + idx1
  local vararg = {}
  for i, v in ipairs({ ... }) do
    local ccok, cc = r.TrackFX_GetNamedConfigParm(tr, rv, 'container_count')
    vararg[i] = v
    if ccok ~= true then return nil end
    rv = rv + sc * v
    sc = sc * (1 + tonumber(cc))
  end
  local new_sc, new_rv 
  if DrumMachinePath then -- if Drum Machine is nested
    new_vararg = {}
   for i = 1,#DrumMachinePath do
    new_vararg[i] = DrumMachinePath[i]
   end  
    new_vararg[#new_vararg + 1] = idx1
   for i = 1, #vararg do
    new_vararg[#new_vararg + 1] = vararg[i]
   end
   local new_sc, new_rv = reaper.TrackFX_GetCount(track)+1, 0x2000000 + new_vararg[1]
    for i = 2, #new_vararg do
    local new_v = new_vararg[i]
    local new_ccok, new_cc = reaper.TrackFX_GetNamedConfigParm(track, new_rv, 'container_count')
    new_ccok = tostring(new_ccok)
    new_rv = new_rv + new_sc * new_v
    new_sc = new_sc * (1+tonumber(new_cc))  
    end
    return new_rv
  else
    return rv
  end
end

function AddPad(note_name, a) -- pad_id, pad_num
  if pads_idx == 0 then       -- no pads
    pad_num = 1
    pad_id = get_fx_id_from_container_path(track, parent_id, pad_num)
  else                                                                -- pads exist
    pad_num = pads_idx + 1
    pad_id = get_fx_id_from_container_path(track, parent_id, pad_num) -- the last slot after pads
  end
  r.TrackFX_AddByName(track, 'Container', false, -1000 - pad_id)      -- Add a pad
  r.TrackFX_SetNamedConfigParm(track, pad_id, 'renamed_name', note_name)
  r.TrackFX_SetNamedConfigParm(track, pad_id, 'parallel', 1)          -- set parallel
  local previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
  local next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
  Pad[a] = {
    Previous_Pad_ID = previous_pad_id,
    Pad_ID = pad_id,
    Next_Pad_ID = next_pad_id,
    Pad_Num = pad_num,
    Pad_GUID = r.TrackFX_GetFXGUID(track, pad_id),
    TblIdx = a,
    Note_Num = notenum
  }
  return pad_id, pad_num
end

function CountPads()                                                                   -- pads_idx
  GetDrumMachineIdx()
  if parent_id == nil then return end
  rv, pads_idx = r.TrackFX_GetNamedConfigParm(track, parent_id - 1, 'container_count') -- 0 based
  pads_idx = tonumber(pads_idx)
  return pads_idx
end

function GetPadGUID()
  CountPads()
  for p = 1, pads_idx do
    pad_id   = get_fx_id_from_container_path(track, parent_id, p)
    pad_guid = r.TrackFX_GetFXGUID(track, pad_id)
  end
end

function CountPadFX(pad_num)                                                        -- padfx_idx
  which_pad = get_fx_id_from_container_path(track, parent_id, pad_num)
  rv, padfx_idx = r.TrackFX_GetNamedConfigParm(track, which_pad, 'container_count') -- 0 based
  return padfx_idx
end

function SwapRS5kNoteRange(padfx_idx, pad, NoteNum)
  for rs5k_pos = 1, padfx_idx do
    find_rs5k = get_fx_id_from_container_path(track, parent_id, pad, rs5k_pos)
    retval, buf = r.TrackFX_GetNamedConfigParm(track, find_rs5k, 'original_name')
    if buf == "VSTi: ReaSamplOmatic5000 (Cockos)" then
      SetRS5kNoteRange(track, find_rs5k, NoteNum, NoteNum) -- Adjust RS5k note range to match a pad's note
    end
  end
end

function EndUndoBlock(str)
  r.Undo_EndBlock("ReaDrum Machine: " .. str, -1)
end

function ClearPad(a, pad_num)
  clear_pad = get_fx_id_from_container_path(track, parent_id, pad_num) -- remove whole pad
  r.SetTrackMIDINoteNameEx(0, track, notenum, 0, "")                   -- remove note name
  r.TrackFX_Delete(track, clear_pad)
  Pad[a] = nil
end

-------------

local function getNoteName(notenum) -- Thanks Fabian https://forum.cockos.com/showpost.php?p=2521073&postcount=5
  local notes = { "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#" }
  local octave = math.floor(notenum / 12) - 1
  local notename = notes[((notenum - 21) % 12) + 1]  -- 21 A0, 22 A#0, 23 B0, 24 C1, ... 35 B1, 36 C2, ...

  return notename .. octave
end

local function getNoteNumber(note) -- Assumes capital letters, only use '#' (not 'b')
  local notes = { A = 9, ["A#"] = 10, B = 11, C = 0, ["C#"] = 1, D = 2, ["D#"] = 3, E = 4, F = 5, ["F#"] = 6, G = 7,
    ["G#"] = 8 }

  local num = (string.byte(note, 2) == string.byte("#") and 2) or 1
  local base = notes[note:sub(1, num)]
  local oct = string.byte(note, num + 1) - string.byte('0') - 1

  return base + 12 * oct + 24 -- C1 = 24
end

local function FindNoteFilter(pad_num)
  CountPadFX(pad_num) 
  if padfx_idx ~= 0 then
    for f = 1, padfx_idx do      
      local find_filter = get_fx_id_from_container_path(track, parent_id, pad_num, f)
      retval, buf = r.TrackFX_GetNamedConfigParm(track, find_filter, 'fx_ident')
      buf = buf:gsub("Suzuki Scripts\\ReaDrum Machine\\JSFX\\", "")
      if buf == "RDM_midi_note_filter.jsfx" then
      fi = f
      break
      end
    end
  end
  return fi
end

function UpdatePadID()
  if not track then return end
  Pad = {}
  GetDrumMachineIdx()
  if not parent_id then return end
  CountPads()
  if pads_idx == nil then return end
  for p = 1, pads_idx do
    FindNoteFilter(p)
    local filter_id = get_fx_id_from_container_path(track, parent_id, p, fi)
    local rv = r.TrackFX_GetParam(track, filter_id, 0)
    local rv = math.floor(tonumber(rv))
    local previous_pad_id = get_fx_id_from_container_path(track, parent_id, p - 1)
    local next_pad_id = get_fx_id_from_container_path(track, parent_id, p + 1)
    local pad_id = get_fx_id_from_container_path(track, parent_id, p)
    Pad[rv + 1] = {
      Previous_Pad_ID = previous_pad_id,
      Pad_ID = pad_id,
      Next_Pad_ID = next_pad_id,
      Pad_Num = p,
      Pad_GUID = r.TrackFX_GetFXGUID(track, pad_id),
      TblIdx = rv + 1,
      Note_Num = rv
    }
    rev, value = r.GetProjExtState(0, 'ReaDrum Machine', 'Rename' .. rv + 1)
    if rev == 1 then
    Pad[rv + 1].Rename = value
    end
    CountPadFX(p) -- Set Pad[a].Name
    local found = false
    for f = 1, padfx_idx do
      local find_rs5k = get_fx_id_from_container_path(track, parent_id, p, f)
      retval, buf = r.TrackFX_GetNamedConfigParm(track, find_rs5k, 'original_name')
      if buf == "VSTi: ReaSamplOmatic5000 (Cockos)" then
        Pad[rv + 1].RS5k_ID = get_fx_id_from_container_path(track, parent_id, p, f)
        found = true
        _, bf = r.TrackFX_GetNamedConfigParm(track, find_rs5k, 'FILE0')  
        filename = bf:match("([^\\/]+)%.%w%w*$")
        Pad[rv + 1].Name = filename
        if Pad[rv + 1].Rename then
          r.SetTrackMIDINoteNameEx(0, track, rv, 0, Pad[rv + 1].Rename)
        elseif Pad[rv + 1].Name then
          r.SetTrackMIDINoteNameEx(0, track, rv, 0, Pad[rv + 1].Name)
        else
          r.SetTrackMIDINoteNameEx(0, track, rv, 0, "")
        end
      end
      if not found then
        Pad[rv + 1].Name = nil
        r.SetTrackMIDINoteNameEx(0, track, rv, 0, "")
      end
    end
  end
end

function IterateContainerUpdate(depth, track, container_id, parent_fx_count, previous_diff, container_guid)
  local c_ok, c_fx_count = r.TrackFX_GetNamedConfigParm(track, 0x2000000 + container_id, "container_count")
  if not c_ok then return end
  local diff = depth == 0 and parent_fx_count + 1 or (parent_fx_count + 1) * previous_diff
  local child_guids = {}

  for i = 1, c_fx_count do
    local fx_id = container_id + diff * i
    local fx_guid = r.TrackFX_GetFXGUID(TRACK, 0x2000000 + fx_id)
    local _, fx_type = r.TrackFX_GetNamedConfigParm(track, 0x2000000 + fx_id, "fx_type")

    FX_DATA[fx_guid] = {
      type = fx_type,
      IDX = i,
      pid = container_guid,
      guid = fx_guid,
    }
    child_guids[#child_guids + 1] = { guid = fx_guid }
    if fx_type == "Container" then
      FX_DATA[fx_guid].depth = depth + 1
      FX_DATA[fx_guid].DIFF = diff * (c_fx_count + 1)
      IterateContainerUpdate(depth + 1, track, fx_id, c_fx_count, diff, fx_guid)
      FX_DATA[fx_guid].ID = fx_id
    end
  end
  return child_guids
end


function UpdateFxData()
  if not TRACK then return end
  FX_DATA = {}
  FX_DATA = {
    ["ROOT"] = {
      type = "ROOT",
      pid = "ROOT",
      guid = "ROOT",
    }
  }
  local row = 1
  local total_fx_count = r.TrackFX_GetCount(TRACK)
  for i = 1, total_fx_count do
    local _, fx_type = r.TrackFX_GetNamedConfigParm(TRACK, i - 1, "fx_type")
    local fx_guid = r.TrackFX_GetFXGUID(TRACK, i - 1)

    FX_DATA[fx_guid] = {
      type = fx_type,
      IDX = i,
      pid = "ROOT",
      guid = fx_guid,
    }
    if fx_type == "Container" then
      FX_DATA[fx_guid].depth = 0
      FX_DATA[fx_guid].DIFF = (total_fx_count + 1)
      FX_DATA[fx_guid].ID = i
      IterateContainerUpdate(0, TRACK, i, total_fx_count, 0, fx_guid)
    end
  end
  UpdatePadID()
end

-----------------
--- DND START ---
-----------------

function GetPayload()
  local retval, dndtype, payload = r.ImGui_GetDragDropPayload(ctx)
  if retval then
    return dndtype, payload
  end
end

local function CheckDNDType()
  local dnd_type = GetPayload()
  DND_ADD_FX = dnd_type == "DND ADD FX"
  DND_MOVE_FX = dnd_type == "DND MOVE FX"
  -- DND_ADD_SAMPLE = dnd_type == "DND ADD SAMPLE"
  -- DND_MOVE_SAMPLE = dnd_type == "DND MOVE SAMPLE"
end

local function AddNoteFilter(notenum, pad_num)
  filter_id = get_fx_id_from_container_path(track, parent_id, pad_num, 1) -- 1 based, num
  r.TrackFX_AddByName(track, 'RDM_midi_note_filter', false, filter_id)
  r.TrackFX_SetParam(track, filter_id, 0, notenum)                        -- lowest key for filter, pad number = midi note
  r.TrackFX_SetParam(track, filter_id, 1, notenum)                        -- highest key for filter
end

local function DndAddFX_SRC(fx)
  if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptBeforeDelivery()) then
    r.ImGui_SetDragDropPayload(ctx, 'DND ADD FX', fx)
    r.ImGui_Text(ctx, fx)
    r.ImGui_EndDragDropSource(ctx)
  end
end

local function DndMoveFX_SRC(a)
  -- if CTRL then return end
  if Pad[a] then
    if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptBeforeDelivery() | r.ImGui_DragDropFlags_SourceNoPreviewTooltip()) then
      local data = Pad[a].TblIdx
      r.ImGui_SetDragDropPayload(ctx, 'DND MOVE FX', data)
      -- Display preview (could be anything, e.g. when dragging an image we could decide to display
      -- the filename and a small preview of the image, etc.)
      -- CreateCustomPreviewData(tbl,i)
      -- r.ImGui_Text(ctx, Pad[a].Note_Num)
      r.ImGui_EndDragDropSource(ctx)
    end
  end
end

local function DndMoveFX_TARGET_SWAP(a) -- Swap whole pads  -> modulation is kept
  if not DND_MOVE_FX then return end
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0)
  if r.ImGui_BeginDragDropTarget(ctx) then
    local ret, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND MOVE FX')
    r.ImGui_EndDragDropTarget(ctx)
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    GetDrumMachineIdx()
    if ret then
      local is_move = (not CTRL_DRAG) and true or false
      if is_move then    -- move
        if Pad[a] then   -- swap
          local b = payload
          local b = tonumber(b)
          local src_pad = Pad[b].Pad_ID
          local src_num = Pad[b].Pad_Num
          local src_note = Pad[b].Note_Num
          local dst_pad = Pad[a].Pad_ID
          local dst_num = Pad[a].Pad_Num
          local dst_name = Pad[a].Name
          local dst_rename = Pad[a].Rename
          -- dst_guid = Pad[a].Pad_GUID
          srcfx_idx = CountPadFX(src_num)
          dstfx_idx = CountPadFX(dst_num)
          if Pad[b].Rename then 
            src_renamed_name = getNoteName(notenum) .. ": " .. Pad[b].Rename
            r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a, Pad[b].Rename)
            r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. b, "")
          elseif Pad[b].Name then 
            src_renamed_name = getNoteName(notenum) .. ": " .. Pad[b].Name
          else 
            src_renamed_name = getNoteName(notenum) 
          end
          r.TrackFX_SetNamedConfigParm(track, src_pad, "renamed_name", src_renamed_name)
          if Pad[a].Rename then 
            dst_renamed_name = getNoteName(src_note) .. ": " .. Pad[a].Rename
            r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. b, Pad[a].Rename)
            r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a, "")
          elseif Pad[a].Name then 
            dst_renamed_name = getNoteName(src_note) .. ": " .. Pad[a].Name
          else 
            dst_renamed_name = getNoteName(src_note)
          end
          r.TrackFX_SetNamedConfigParm(track, Pad[a].Pad_ID, "renamed_name", dst_renamed_name)
          r.TrackFX_CopyToTrack(track, src_pad, track, dst_pad, true) -- true = move
          local src_num = tonumber(src_num)
          if dst_num > src_num then
            dst_pad_new = get_fx_id_from_container_path(track, parent_id, dst_num - 1)
          end
          if src_num > dst_num then
            dst_pad_new = get_fx_id_from_container_path(track, parent_id, dst_num + 1)
          end
          r.TrackFX_CopyToTrack(track, dst_pad_new, track, src_pad, true)
          FindNoteFilter(dst_num)
          local src_filter = get_fx_id_from_container_path(track, parent_id, dst_num, fi)
          r.TrackFX_SetParam(track, src_filter, 0, notenum)  -- lowest key for filter, pad number = midi note drag
          r.TrackFX_SetParam(track, src_filter, 1, notenum)  -- highest key for filter
          FindNoteFilter(src_num)
          local dst_filter = get_fx_id_from_container_path(track, parent_id, src_num, fi)
          r.TrackFX_SetParam(track, dst_filter, 0, src_note) -- lowest key for filter, pad number = midi note drop
          r.TrackFX_SetParam(track, dst_filter, 1, src_note) -- highest key for filter
          -- SwapRS5kNoteRange(srcfx_idx, dst_num, notenum)
          -- SwapRS5kNoteRange(dstfx_idx, src_num, src_note)
          UpdatePadID()
          r.PreventUIRefresh(-1)
          EndUndoBlock("SWAP/EXCHANGE PAD FX")          
        elseif not Pad[a] then   -- move
          local b = payload
          local b = tonumber(b)
          local src_num = Pad[b].Pad_Num
          CountPads()
          AddPad(note_name, a) -- dst
          src_note = Pad[b].Note_Num
          local previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
          local next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
          Pad[a] = { -- dst
            Previous_Pad_ID = previous_pad_id,
            Pad_ID = pad_id,
            Next_Pad_ID = next_pad_id,
            Pad_Num = pad_num,
            TblIdx = a,
            Note_Num = notenum,
            Name = Pad[b].Name,
          }
          if Pad[b].Rename then
            Pad[a].Rename = Pad[b].Rename
            r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a, Pad[b].Rename)
          end
          rev, value = r.GetProjExtState(0, 'ReaDrum Machine', 'Rename' .. b)
          if rev == 1 then
          r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. b, "")
          Pad[b].Rename = nil
          end
          if Pad[a].Rename then renamed_name = note_name .. ": " .. Pad[a].Rename else renamed_name = note_name end
          r.TrackFX_SetNamedConfigParm(track, Pad[a].Pad_ID, "renamed_name", renamed_name)
          r.SetTrackMIDINoteNameEx(0, track, src_note, 0, "")
          local srcfx_idx = CountPadFX(src_num)
          local dstfx_pos = CountPadFX(Pad[a].Pad_Num)
          for m = 1, srcfx_idx do
            dstfx_pos = dstfx_pos + 1                                                             -- the last slot being offset by 1
            local srcfx = get_fx_id_from_container_path(track, parent_id, src_num, 1)                   -- 1st slot * srcfx_idx times
            local dst_last = get_fx_id_from_container_path(track, parent_id, Pad[a].Pad_Num, dstfx_pos) -- add FX
            r.TrackFX_CopyToTrack(track, srcfx, track, dst_last, true)                            -- true = move
          end
          FindNoteFilter(Pad[a].Pad_Num)
          local filter_id = get_fx_id_from_container_path(track, parent_id, Pad[a].Pad_Num, fi)
          r.TrackFX_SetParam(track, filter_id, 0, notenum)                        -- lowest key for filter, pad number = midi note
          r.TrackFX_SetParam(track, filter_id, 1, notenum)                        -- highest key for filter
          ClearPad(b, src_num) -- remove source pad
          UpdatePadID()
          r.PreventUIRefresh(-1)
          EndUndoBlock("MOVE PAD")
        end
      elseif not is_move then               -- copy
        if Pad[a] then   -- add fx to target
          local b = payload
          local b = tonumber(b)
          local src_num = Pad[b].Pad_Num
          local dst_pad = Pad[a].Pad_ID
          local dst_num = Pad[a].Pad_Num
          -- dst_guid = Pad[a].Pad_GUID
          local srcfx_idx = CountPadFX(src_num)
          local dstfx_idx = CountPadFX(dst_num)
          for c = 1, srcfx_idx do   -- skip filter
            FindNoteFilter(src_num)
            if c == fi then goto NEXT end
            dstfx_idx = dstfx_idx + 1 -- the last slot being offset by 1
            local dst_last = get_fx_id_from_container_path(track, parent_id, dst_num, dstfx_idx)
            local srcfx = get_fx_id_from_container_path(track, parent_id, src_num, c)
            r.TrackFX_CopyToTrack(track, srcfx, track, dst_last, false) -- false = copy
            ::NEXT::
          end
          r.PreventUIRefresh(-1)
          EndUndoBlock("COPY PAD FX")
        elseif not Pad[a] and not is_move then   -- create target and add fx to it
          local b = payload
          local b = tonumber(b)
          local src_num = Pad[b].Pad_Num
          CountPads()
          AddPad(note_name, a) -- dst
          local previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
          local next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
          Pad[a] = { -- dst
            Previous_Pad_ID = previous_pad_id,
            Pad_ID = pad_id,
            Next_Pad_ID = next_pad_id,
            Pad_Num = pad_num,
            TblIdx = a,
            Note_Num = notenum,
            Name = Pad[b].Name,
          }
          if Pad[b].Rename then 
            renamed_name = note_name .. ": " .. Pad[b].Rename
            Pad[a].Rename = Pad[b].Rename
            r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a, Pad[b].Rename)
          else 
            renamed_name = note_name 
          end
          r.TrackFX_SetNamedConfigParm(track, Pad[a].Pad_ID, "renamed_name", renamed_name)
          local srcfx_idx = CountPadFX(src_num)
          local dstfx_idx = CountPadFX(pad_num)
          for c = 1, srcfx_idx do    
            dstfx_idx = dstfx_idx + 1 -- the last slot being offset by 1
            local dst_last = get_fx_id_from_container_path(track, parent_id, pad_num, dstfx_idx)
            local srcfx = get_fx_id_from_container_path(track, parent_id, src_num, c)
            r.TrackFX_CopyToTrack(track, srcfx, track, dst_last, false) -- false = copy
          end
          FindNoteFilter(pad_num)
          local filter_id = get_fx_id_from_container_path(track, parent_id, pad_num, fi)
          r.TrackFX_SetParam(track, filter_id, 0, notenum)
          r.TrackFX_SetParam(track, filter_id, 1, notenum)
          r.PreventUIRefresh(-1)
          EndUndoBlock("COPY PAD")
        end
      end
    end
  end
  r.ImGui_PopStyleColor(ctx)
end

local function DndAddSample_SRC(sample)
  if r.ImGui_BeginDragDropSource(ctx) then
    r.ImGui_SetDragDropPayload(ctx, 'DND ADD SAMPLE', sample)
    r.ImGui_Text(ctx, sample)
    r.ImGui_EndDragDropSource(ctx)
  end
  if dst_rename then
    r.SetTrackMIDINoteNameEx(0, track, src_note, 0, dst_rename)
  elseif dst_name then
    r.SetTrackMIDINoteNameEx(0, track, src_note, 0, dst_name)
  end
  if Pad[b].Rename then
    r.SetTrackMIDINoteNameEx(0, track, notenum, 0, Pad[b].Rename)
  elseif Pad[b].Name then
    r.SetTrackMIDINoteNameEx(0, track, notenum, 0, Pad[b].Name)
  end
end

local function DndAddFX_TARGET(a)
  if not DND_ADD_FX then return end
  InsertDrumMachine()
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0)
  if r.ImGui_BeginDragDropTarget(ctx) then
    local ret, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND ADD FX')
    r.ImGui_EndDragDropTarget(ctx)
    if ret and not Pad[a] then
      GetDrumMachineIdx()     -- parent_id = num
      CountPads()             -- pads_idx = num
      r.Undo_BeginBlock()
      r.PreventUIRefresh(1)
      AddPad(note_name, a)     -- pad_id = loc, pad_num = num
      previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
      next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
      Pad[a] = {
        Previous_Pad_ID = previous_pad_id,
        Pad_ID = pad_id,
        Next_Pad_ID = next_pad_id,
        Pad_Num = pad_num,
        TblIdx = a,
        Note_Num = notenum
      }
      CountPadFX(Pad[a].Pad_Num)                                                             -- padfx_idx = num
      AddNoteFilter(notenum, pad_num)
      padfx_id = get_fx_id_from_container_path(track, parent_id, pad_num, padfx_idx + 2)     -- add FX
      r.TrackFX_AddByName(track, payload, false, padfx_id)
      r.PreventUIRefresh(-1)
      EndUndoBlock("ADD FX") 
    elseif ret and Pad[a].Pad_Num then
      GetDrumMachineIdx()   -- parent_id = num
      CountPadFX(Pad[a].Pad_Num)
      padfx_id = get_fx_id_from_container_path(track, parent_id, Pad[a].Pad_Num, padfx_idx + 1)
      r.Undo_BeginBlock()
      r.PreventUIRefresh(1)
      r.TrackFX_AddByName(track, payload, false, -1000 - padfx_id)
      r.PreventUIRefresh(-1)
      EndUndoBlock("ADD FX")
    end
  end
  r.ImGui_PopStyleColor(ctx)
end

local function AddSamplesToRS5k(pad_num, add_pos, i, a, notenum, note_name)
  rs5k_id = get_fx_id_from_container_path(track, parent_id, pad_num, add_pos)
  rv, payload = r.ImGui_GetDragDropPayloadFile(ctx, i) -- 0 based
  r.TrackFX_AddByName(track, 'ReaSamplomatic5000', false, rs5k_id)
  r.TrackFX_Show(track, rs5k_id, 2)
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, 'MODE', 1)         -- Sample mode
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, '-FILE*', '') -- remove file list
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, 'FILE', payload) -- add file
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, 'DONE', '')        -- always necessary
  -- r.TrackFX_SetParam(track, rs5k_id, 11, 1)                       -- obey note offs
  Pad[a].RS5k_ID = rs5k_id
  rv, buf = r.TrackFX_GetNamedConfigParm(track, rs5k_id, 'FILE')
  filename = buf:match("([^\\/]+)%.%w%w*$")
  r.SetTrackMIDINoteNameEx(0, track, notenum, 0, filename)
  if Pad[a].Rename then renamed_name = note_name .. ": " .. Pad[a].Rename elseif filename then renamed_name = note_name .. ": " .. filename else renamed_name = note_name end
  r.TrackFX_SetNamedConfigParm(track, Pad[a].Pad_ID, "renamed_name", renamed_name)
  Pad[a].Name = filename
end

local function AddSampleFromArrange(pad_num, add_pos, a, filenamebuf, start_offset, end_offset)
  rs5k_id = get_fx_id_from_container_path(track, parent_id, pad_num, add_pos)
  r.TrackFX_AddByName(track, 'ReaSamplomatic5000', false, rs5k_id)
  Pad[a].RS5k_ID = rs5k_id
  r.TrackFX_Show(track, rs5k_id, 2)
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, 'MODE', 1)             -- Sample mode
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, '-FILE*', '')
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, 'FILE', filenamebuf) -- add file
  r.TrackFX_SetNamedConfigParm(track, rs5k_id, 'DONE', '')            -- always necessary
  --r.TrackFX_SetParam(track, rs5k_id, 11, 1)                           -- obey note offs
  r.TrackFX_SetParam(track, rs5k_id, 13, start_offset)                -- Sample start offset
  r.TrackFX_SetParam(track, rs5k_id, 14, end_offset)                  -- Sample end offset
  -- r.TrackFX_SetParam(track, rs5k_id, 15, take_pitch)                  -- Pitch offset
end

local function LoadItemsFromArrange(a)
  InsertDrumMachine()
  GetDrumMachineIdx()                                              -- parent_id = num
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  for c = 1, r.CountSelectedMediaItems(0) do                       -- 1 based
    local item = r.GetSelectedMediaItem(0, c - 1)                  -- 0 based
    local take = r.GetActiveTake(item)
    local item_length = r.GetMediaItemInfo_Value(item, 'D_LENGTH') -- double
    d = 0
    if not take or r.TakeIsMIDI(take) then
      d = d + 1
      goto NEXT
    end
    local take_src = r.GetMediaItemTake_Source(take)
    local start_offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
    local take_pitch = r.GetMediaItemTakeInfo_Value(take, 'D_PITCH') 
    local take_playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
    local take_pan = r.GetMediaItemTakeInfo_Value(take, 'D_PAN')
    local src_length = r.GetMediaSourceLength(take_src)
    local filenamebuf = r.GetMediaSourceFileName(take_src, '')
    local start_offset = start_offs / src_length
    local end_offset = (start_offs + item_length) / src_length
    if not Pad[a + c - 1 - d] then
      CountPads()                                             -- pads_idx = num
      AddPad(getNoteName(notenum + c - 1 - d), a + c - 1 - d) -- pad_id = loc, pad_num = num
      previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
      next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
      Pad[a + c - 1 - d] = {
        Previous_Pad_ID = previous_pad_id,
        Pad_ID = pad_id,
        Next_Pad_ID = next_pad_id,
        Pad_Num = pad_num,
        TblIdx = a + c - 1 - d,
        Note_Num = a + c - 1 - d
      }
      AddNoteFilter(notenum + c - 1 - d, pad_num)
      AddSampleFromArrange(Pad[a + c - 1 - d].Pad_Num, 2, a + c - 1 - d, filenamebuf, start_offset, end_offset)
    elseif Pad[a + c - 1 - d].Pad_Num then
      CountPadFX(Pad[a + c - 1 - d].Pad_Num) -- padfx_idx = num
      local found = false
      for rs5k_pos = 1, padfx_idx do
        find_rs5k = get_fx_id_from_container_path(track, parent_id, Pad[a + c - 1 - d].Pad_Num, rs5k_pos)
        retval, buf = r.TrackFX_GetNamedConfigParm(track, find_rs5k, 'original_name')
        if buf == "VSTi: ReaSamplOmatic5000 (Cockos)" then
          found = true
          r.TrackFX_SetNamedConfigParm(track, find_rs5k, 'FILE0', filenamebuf)   -- change file
          r.TrackFX_SetNamedConfigParm(track, find_rs5k, 'DONE', '')
          --r.TrackFX_SetParam(track, find_rs5k, 11, 1)                            -- obey note offs
          r.TrackFX_SetParam(track, find_rs5k, 13, start_offset)                 -- Sample start offset
          r.TrackFX_SetParam(track, find_rs5k, 14, end_offset)                   -- Sample end offset
        end
      end
      if not found then
        AddSampleFromArrange(Pad[a + c - 1 - d].Pad_Num, padfx_idx + 1, a + c - 1 - d, filenamebuf, start_offset,
          end_offset)
      end
    end
    r.SetTrackMIDINoteNameEx(0, track, notenum + c - 1 - d, 0, 'test' .. notenum + c - 1 - d) -- rename in ME
    ::NEXT::
  end
  r.PreventUIRefresh(-1)
  EndUndoBlock("LOAD ITEMS FROM ARRANGE")
end

local function DndAddSample_TARGET(a)
  if r.ImGui_BeginDragDropTarget(ctx) then
    local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
    if rv then
      InsertDrumMachine()
      GetDrumMachineIdx() -- parent_id = num
      r.Undo_BeginBlock()
      r.PreventUIRefresh(1)
      for i = 0, count - 1 do
        if not Pad[a + i] then
          CountPads()                           -- pads_idx = num
          AddPad(getNoteName(notenum + i), a + i) -- pad_id = loc, pad_num = num
          previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
          next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
          Pad[a + i] = {
            Previous_Pad_ID = previous_pad_id,
            Pad_ID = pad_id,
            Next_Pad_ID = next_pad_id,
            Pad_Num = pad_num,
            TblIdx = a + i,
            Note_Num = notenum + i
          }
          AddNoteFilter(notenum + i, pad_num)
          AddSamplesToRS5k(pad_num, 2, i, a + i, notenum + i, getNoteName(notenum + i)) -- Pad[a].Name
        elseif Pad[a + i].Pad_Num then
          CountPadFX(Pad[a + i].Pad_Num) -- padfx_idx = num
          local found = false
          for rs5k_pos = 1, padfx_idx do
            find_rs5k = get_fx_id_from_container_path(track, parent_id, Pad[a + i].Pad_Num, rs5k_pos)
            retval, buf = r.TrackFX_GetNamedConfigParm(track, find_rs5k, 'original_name')
            if buf == "VSTi: ReaSamplOmatic5000 (Cockos)" then
              found = true
              rv, payload = r.ImGui_GetDragDropPayloadFile(ctx, i)
              r.TrackFX_SetNamedConfigParm(track, find_rs5k, 'FILE0', payload) -- change file
              r.TrackFX_SetNamedConfigParm(track, find_rs5k, 'DONE', '')
              filename = payload:match("([^\\/]+)%.%w%w*$")
              Pad[a].Name = filename
              if Pad[a].Rename then renamed_name = note_name .. ": " .. Pad[a].Rename elseif filename then renamed_name = note_name .. ": " .. filename else renamed_name = note_name end
              r.TrackFX_SetNamedConfigParm(track, Pad[a].Pad_ID, "renamed_name", renamed_name)
              r.SetTrackMIDINoteNameEx(0, track, notenum, 0, filename)
              r.TrackFX_SetParam(track, find_rs5k, 13, 0) -- Sample start offset, reset
              r.TrackFX_SetParam(track, find_rs5k, 14, 1) -- Sample end offset, reset
            end
          end
          if not found then
            AddSamplesToRS5k(Pad[a + i].Pad_Num, padfx_idx + 1, i, a + i, notenum + i, getNoteName(notenum + i))
          end
        end
      end
      r.PreventUIRefresh(-1)
      EndUndoBlock("ADD SAMPLES")
    end
    r.ImGui_EndDragDropTarget(ctx)
  end
end

local function DndAddMultipleSamples_TARGET(a) -- several instances into one pad
  if r.ImGui_BeginDragDropTarget(ctx) then
    local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
    if rv and not Pad[a] then
      InsertDrumMachine()
      GetDrumMachineIdx()  -- parent_id = num
      CountPads()          -- pads_idx = num
      AddPad(note_name, a) -- pad_id = loc, pad_num = num
      previous_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num - 1)
      next_pad_id = get_fx_id_from_container_path(track, parent_id, pad_num + 1)
      Pad[a] = {
        Previous_Pad_ID = previous_pad_id,
        Pad_ID = pad_id,
        Next_Pad_ID = next_pad_id,
        Pad_Num = pad_num
      }
      CountPadFX(pad_num) -- padfx_idx = num
      AddNoteFilter(notenum, pad_num)
      for i = 0, count - 1 do
        rs5k_id = get_fx_id_from_container_path(track, parent_id, pad_num, padfx_idx + 2 + i)
        AddSamplesToRS5k(pad_num, padfx_idx + 2 + i, i, a, note_name)
      end
    elseif rv and Pad[a].Pad_Num then
      GetDrumMachineIdx() -- parent_id = num
      CountPadFX(Pad[a].Pad_Num)
      for i = 0, count - 1 do
        AddSamplesToRS5k(Pad[a].Pad_Num, padfx_idx + 1 + i, i, a, note_name)
      end
    end
    r.ImGui_EndDragDropTarget(ctx)
  end
end

function SetRS5kNoteRange(track, fx, note_start, note_end)
  r.TrackFX_SetParamNormalized(track, fx, 3, note_start / 127)
  r.TrackFX_SetParamNormalized(track, fx, 4, note_end / 127)
end

local function DndCopySample_TARGET() -- replace target sample file with source file

end

local function DndSwapSample_TARGET() -- swap sample file

end
---------------
--- DND END ---
---------------

----------------------------------------------------------------------
-- GUI --
----------------------------------------------------------------------

function SetButtonState(set) -- Set ToolBar Button State
  local is_new_value, filename, sec, cmd, mode, resolution, val = r.get_action_context()
  r.SetToggleCommandState(sec, cmd, set or 0)
  r.RefreshToolbar2(sec, cmd)
end

function Exit()
  SetButtonState()
end

-- Thanks Sexan!! --
local min, max = math.min, math.max
function IncreaseDecreaseBrightness(color, amt, no_alpha)
  function AdjustBrightness(channel, delta)
    return min(255, max(0, channel + delta))
  end

  local alpha = color & 0xFF
  local blue = (color >> 8) & 0xFF
  local green = (color >> 16) & 0xFF
  local red = (color >> 24) & 0xFF

  red = AdjustBrightness(red, amt)
  green = AdjustBrightness(green, amt)
  blue = AdjustBrightness(blue, amt)
  alpha = no_alpha and alpha or AdjustBrightness(alpha, amt)

  return (alpha) | (blue << 8) | (green << 16) | (red << 24)
end

local function CalculateFontColor(color)
  local alpha = color & 0xFF
  local blue = (color >> 8) & 0xFF
  local green = (color >> 16) & 0xFF
  local red = (color >> 24) & 0xFF

  local luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255
  return luminance > 0.5 and 0xFF or 0xFFFFFFFF
end

local function ButtonDrawlist(splitter, name, color)
  r.ImGui_DrawListSplitter_SetCurrentChannel(splitter, 0)
  color = r.ImGui_IsItemHovered(ctx) and IncreaseDecreaseBrightness(color, 30) or color
  local xs, ys = r.ImGui_GetItemRectMin(ctx)
  local xe, ye = r.ImGui_GetItemRectMax(ctx)

  r.ImGui_DrawList_AddRectFilled(draw_list, xs, ys, xe, ye, r.ImGui_GetColorEx(ctx, color))
  if r.ImGui_IsItemActive(ctx) then
    r.ImGui_DrawList_AddRect(f_draw_list, xs, ys, xe, ye, 0x22FF44FF)
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

  local font_size = r.ImGui_GetFontSize(ctx)
  local char_size_w,char_size_h = r.ImGui_CalcTextSize(ctx, "A")
  local font_color = CalculateFontColor(color)
  name = name:sub(1, 11)
  r.ImGui_DrawList_AddTextEx( draw_list, nil, font_size, xs, ys + char_size_h, r.ImGui_GetColorEx(ctx, font_color), name)

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

local function DrawNoteName(x, y)
  local wx, wy = r.ImGui_GetWindowPos(ctx)
  -- r.ImGui_DrawList_AddTextEx(draw_list, nil, 13, wx + x, wy + y, 0xffffffff, note_name)
  r.ImGui_DrawList_AddText(draw_list, wx + x, wy + y, 0xffffffff, note_name)
end

function adjustBrightness(channel, delta)
  return math.min(255, math.max(0, channel + delta))
end

function SplitColorChannels(color)
  local alpha = color & 0xFF
  local blue = (color >> 8) & 0xFF
  local green = (color >> 16) & 0xFF
  local red = (color >> 24) & 0xFF
  return red, green, blue, alpha
end

function ColorToHex(color, amt)
  local red, green, blue, alpha = SplitColorChannels(color)
  alpha = adjustBrightness(alpha, amt)
  blue = adjustBrightness(blue, amt)
  green = adjustBrightness(green, amt)
  red = adjustBrightness(red, amt)
  return (alpha) | (blue << 8) | (green << 16) | (red << 24)
end

function CalculateFontColor(color)
  local red, green, blue, alpha = SplitColorChannels(color)
  local luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;
  if (luminance > 0.5) then
    return 0xFF
  else
    return 0xFFFFFFFF
  end
end

function SendMidiNote(notenum) -- Thanks Sexan!
  if not r.ImGui_IsItemHovered(ctx) then return end
  if r.ImGui_IsMouseClicked(ctx, 0) then
    r.StuffMIDIMessage(0, 0x90, notenum, 96) -- send note_p -- mode, note on, note, velocity
  elseif r.ImGui_IsMouseReleased(ctx, 0) then
    r.StuffMIDIMessage(0, 0x80, notenum, 96) -- send note_r
  end
end

local function CheckKeys()
  ALT = r.ImGui_GetKeyMods(ctx) == r.ImGui_Mod_Alt()
  CTRL = r.ImGui_GetKeyMods(ctx) == r.ImGui_Mod_Shortcut()
  SHIFT = r.ImGui_GetKeyMods(ctx) == r.ImGui_Mod_Shift()

  HOME = r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Home())
  SPACE = r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Space())
  ESC = r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape())

  Z = r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Z())

  if HOME then CANVAS.off_x, CANVAS.off_y = 0, def_vertical_y_center end

  if CTRL and Z then
    r.Main_OnCommand(40029, 0)
    UpdatePadID()
    -- CHECK IF TRACK CHANGED
    TRACK = r.GetSelectedTrack2(0, 0, true)
  end                            -- UNDO
  if r.ImGui_GetKeyMods(ctx) == r.ImGui_Mod_Shortcut() | r.ImGui_Mod_Shift() and Z then
    r.Main_OnCommand(40030, 0)   -- REDO
  end

  if SPACE and (not FX_OPENED and not RENAME_OPENED and not FILE_MANAGER_OPENED) then r.Main_OnCommand(40044, 0) end -- PLAY STOP

  -- ACTIVATE CTRL ONLY IF NOT PREVIOUSLY DRAGGING
  if not CTRL_DRAG then
    CTRL_DRAG = (not MOUSE_DRAG and CTRL) and r.ImGui_IsMouseDragging(ctx, 0)
  end
  MOUSE_DRAG = r.ImGui_IsMouseDragging(ctx, 0)
end

function CheckStaleData()
  if r.ImGui_IsMouseReleased(ctx, 0) then
      CTRL_DRAG = nil
  --    DRAG_PREVIEW = nil
  end
  --if not PEAK_INTO_TOOLTIP then
  --    if PREVIEW_TOOLTIP then PREVIEW_TOOLTIP = nil end
  --end
end


local function AdjustPadVolume(a)
  if not r.ImGui_IsItemHovered(ctx) then return end
  if r.ImGui_IsMouseDragging(ctx, 0) then
    if Pad[a] then
      local wet = r.TrackFX_GetParamFromIdent(track, Pad[a].Pad_ID, ":wet")
      local volume = r.TrackFX_GetParam(track, Pad[a].Pad_ID, wet)
      r.TrackFX_SetParam(track, Pad[a].Pad_ID, volume, v / 100)
    end
  end
end

local function SetLowChannel(e)
  local left = (e - 1) * 2
  local right = left + 1 
  left_low = 2^left
  left_high = 0
  right_low = 2^right
  right_high = 0
end

local function SetHighChannel(e)
  local left = (e - 1) * 2
  local right = left + 1 
  left_low = 0
  left_high = 2^left
  right_low = 0
  right_high = 2^right
end

local function ExplodePadsToTracks()
  CountPads()
  r.SetMediaTrackInfo_Value(track, 'I_NCHAN', 128)
  local drum_id = get_fx_id_from_container_path(track, parent_id)
  r.TrackFX_SetNamedConfigParm(track, drum_id, 'container_nch', 128)
  r.TrackFX_SetNamedConfigParm(track, drum_id, 'container_nch_out', 128)
  local drum_track = track
  local track_id = r.CSurf_TrackToID(track, false)
  r.Main_OnCommand(40001, 0)
  for e = 1, pads_idx do
    if e > 64 then last_child = r.CSurf_TrackFromID(track_id + 1 + e, false) break end
    local pad_id = get_fx_id_from_container_path(track, parent_id, e)
    r.Main_OnCommand(40001, 0)
    local retval, pad_name = r.TrackFX_GetNamedConfigParm(drum_track, pad_id, 'renamed_name')
    local child = r.CSurf_TrackFromID(track_id + 1 + e, false)
    r.GetSetMediaTrackInfo_String(child, 'P_NAME', pad_name, true) -- change child track's name to pad name
    local send = r.CreateTrackSend(drum_track, child)
    local channel_offset = (e - 1) * 2 -- even number
    local num_channels = 0 -- stereo
    local send_info = (num_channels << 9) | channel_offset
    r.SetTrackSendInfo_Value(drum_track, 0, send, 'I_SRCCHAN', send_info) -- set send channel
    if e <= 32 then
      l_pin_idx = 0 --left 
      r_pin_idx = 1 -- right
      if e <= 16 then -- use low for 1~16
        SetLowChannel(e)
      elseif e > 16 then -- use high for 17~32
        local e = e - 16
        SetHighChannel(e)
      end
    elseif e > 32 then
      l_pin_idx = 0 + 0x1000000 -- add 0x1000000 for 64~
      r_pin_idx = 1 + 0x1000000
      if e <= 48 then -- use low for 33~48
      local e = e - 32
      SetLowChannel(e)
      elseif e > 48 then -- use high for 49~64
      local e = e - 48
      SetHighChannel(e)
      end
    end
    r.TrackFX_SetPinMappings(track, pad_id, 1, l_pin_idx, left_low, left_high) -- left
    r.TrackFX_SetPinMappings(track, pad_id, 1, r_pin_idx, right_low, right_high) -- right
    last_child = r.CSurf_TrackFromID(track_id + 1 + pads_idx, false)
  end
  local bus_track = r.CSurf_TrackFromID(track_id + 1, false)
  r.SetMediaTrackInfo_Value(bus_track, 'I_FOLDERDEPTH', 1) -- parent folder
  r.GetSetMediaTrackInfo_String(bus_track, 'P_NAME', "ReaDrum Bus", true)
  r.SetMediaTrackInfo_Value(last_child, 'I_FOLDERDEPTH', -1) -- last child track
  r.SetMediaTrackInfo_Value(bus_track, 'I_FOLDERCOMPACT', 1) -- collapse folder
  r.SetMediaTrackInfo_Value(drum_track, 'I_SELECTED', 1) -- select drum track
  r.SetMediaTrackInfo_Value(drum_track, 'B_MAINSEND', 0) -- turn off master send
end

local function RenameWindow(a, note_name)
  local center = { r.ImGui_Viewport_GetCenter(r.ImGui_GetWindowViewport(ctx)) }
  r.ImGui_SetNextWindowPos(ctx, center[1], center[2], r.ImGui_Cond_Appearing(), 0.5, 0.5)
  if r.ImGui_BeginPopupModal(ctx, 'Rename a pad?##' .. a, nil, r.ImGui_WindowFlags_AlwaysAutoResize()) then
    if r.ImGui_IsWindowAppearing(ctx) then
      r.ImGui_SetKeyboardFocusHere(ctx)
    end
    rv, new_name = r.ImGui_InputTextWithHint(ctx, '##Pad Name', 'PAD NAME', new_name,
      r.ImGui_InputTextFlags_AutoSelectAll())
    IsInputEdited = r.ImGui_IsItemActive(ctx)
    if r.ImGui_Button(ctx, 'OK', 120, 0) or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) or
        r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_KeypadEnter()) then
      if not Pad[a] then
        r.ShowConsoleMsg("There's no pad. Insert FX or sample first.")
      elseif Pad[a] then
        r.Undo_BeginBlock()
        r.PreventUIRefresh(1)
        if #new_name ~= 0 then renamed_name = note_name .. ": " .. new_name else renamed_name = note_name end
        if renamed_name then
        r.TrackFX_SetNamedConfigParm(track, Pad[a].Pad_ID, "renamed_name", renamed_name)
        r.SetTrackMIDINoteNameEx(0, track, notenum, 0, new_name)
        Pad[a].Rename = new_name
        r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a, new_name)
        end
        r.PreventUIRefresh(-1)
        EndUndoBlock("RENAME PAD") 
      end
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_SetItemDefaultFocus(ctx)
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx, 'Cancel', 120, 0) or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_EndPopup(ctx)
  end
end

local function ClickPadActions(a)
  -- if not r.ImGui_IsItemHovered(ctx) then return end
  if Pad[a] then
      if ALT then
        r.Undo_BeginBlock()
        r.PreventUIRefresh(1)
        ClearPad(a, Pad[a].Pad_Num)
        rev, value = r.GetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a)
        if rev == 1 then
        r.SetProjExtState(0, 'ReaDrum Machine', 'Rename' .. a, "")
        end
        UpdatePadID()
        r.PreventUIRefresh(-1)
        EndUndoBlock("CLEAR PAD")
      else
        r.Undo_BeginBlock()
        r.PreventUIRefresh(1)
        local open =  r.TrackFX_GetOpen(track, Pad[a].Pad_ID) -- 0 based
        r.TrackFX_Show(track, Pad[a].Pad_ID, open and 2 or 3)           -- show/hide floating window   
        r.PreventUIRefresh(-1)
        EndUndoBlock("OPEN FX WINDOW")
      end
  end
end

local function PadMenu(a, note_name)
  if r.ImGui_IsItemClicked(ctx, 1) and CTRL then
    r.ImGui_OpenPopup(ctx, "RIGHT_CLICK_MENU##" .. a)
  end
  local open_settings = false
  if r.ImGui_BeginPopup(ctx, "RIGHT_CLICK_MENU##" .. a, r.ImGui_WindowFlags_NoMove()) then
    if r.ImGui_MenuItem(ctx, 'Load Selected Items from Arrange##' .. a) then
      LoadItemsFromArrange(a)
    end
    if r.ImGui_MenuItem(ctx, 'Rename Pad##' .. a) then
      open_settings = true
    end
    if r.ImGui_MenuItem(ctx, 'Toggle Obey note offs##' .. a) then
      if Pad[a] and Pad[a].RS5k_ID then
        rv = r.TrackFX_GetParam(track, Pad[a].RS5k_ID, 11)
        if rv == 0 then
          r.TrackFX_SetParam(track, Pad[a].RS5k_ID, 11, 1) -- obey note offs on
        else
          r.TrackFX_SetParam(track, Pad[a].RS5k_ID, 11, 0)
        end
      end
    end
    if r.ImGui_MenuItem(ctx, 'Toggle Loop##' .. a) then
      if Pad[a] and Pad[a].RS5k_ID then
        rv = r.TrackFX_GetParam(track, Pad[a].RS5k_ID, 12)
        if rv == 0 then
          no = r.TrackFX_GetParam(track, Pad[a].RS5k_ID, 11)
          if no == 0 then
          r.TrackFX_SetParam(track, Pad[a].RS5k_ID, 11, 1) -- obey note offs on
          end
          r.TrackFX_SetParam(track, Pad[a].RS5k_ID, 12, 1) -- Loop on
        else
          r.TrackFX_SetParam(track, Pad[a].RS5k_ID, 12, 0)
        end
      end
    end
    r.ImGui_Separator(ctx)
    if r.ImGui_MenuItem(ctx, 'Explode All Pads to Tracks##' .. a) then
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    ExplodePadsToTracks()
    r.PreventUIRefresh(-1)
    EndUndoBlock("EXPLODE ALL PADS") 
    end
    if r.ImGui_MenuItem(ctx, 'Clear All Pads##' .. a) then
      GetDrumMachineIdx()
      CountPads()                                                          -- pads_idx = num
      r.Undo_BeginBlock()
      r.PreventUIRefresh(1)
      for i = 1, pads_idx do
        local clear_pad = get_fx_id_from_container_path(track, parent_id, 1) -- remove whole pad
        r.TrackFX_Delete(track, clear_pad)
      end
      Pad = {}
      r.SetProjExtState(0, 'ReaDrum Machine', "", "")
      local IsMidiOpen = r.MIDIEditor_LastFocused_OnCommand(40412, false)
      if not IsMidiOpen then
        r.Main_OnCommand(40716, 0)
        r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), 40412)
        r.Main_OnCommand(40716, 0)
      else
        r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), 40412)
      end
      r.PreventUIRefresh(-1)
      EndUndoBlock("CLEAR ALL PADS") 
    end
    -- if r.ImGui_BeginMenu(ctx, 'Context menu') then
    --  r.ImGui_EndMenu(ctx)
    -- end
    r.ImGui_EndPopup(ctx)
  end
  if open_settings then
    r.ImGui_OpenPopup(ctx, 'Rename a pad?##' .. a)
  end
  RenameWindow(a, note_name)
end

function DrawPads(loopmin, loopmax)
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
    DrawNoteName(x, y)
    DndAddFX_TARGET(a)
    DndAddSample_TARGET(a)
    -- DndAddMultipleSamples_TARGET(a)
    DndMoveFX_TARGET_SWAP(a)
    PadMenu(a, note_name)
    if ret then 
      ClickPadActions(a)
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
