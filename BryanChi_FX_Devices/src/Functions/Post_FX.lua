-- @noindex
-- @version 1.0Beta 1
function MoveFX_Out_Of_Post(IDinPost, TrkTB)
    table.remove(TrkTB.PostFX, IDinPost or tablefind(TrkTB.PostFX, FXGUID[DragFX_ID]))
    for i = 1, #TrkTB.PostFX + 1, 1 do
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, TrkTB.PostFX[i] or '', true)
    end
end
function If_Drag_FX_to_Right_Edge(Payload_Type, TrkTB)
    local MouseAtRightEdge = im.IsMouseHoveringRect(ctx, VP.X + VP.w - 25, VP.Y, VP.X + VP.w, VP.Y + VP.h)
    if (Payload_Type == 'FX_Drag' or Payload_Type == 'DND ADD FX' and MouseAtRightEdge) and not TrkTB.PostFX[1] then
        im.SameLine(ctx, nil, -5)
        dropped, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
        rv               = im.Button(ctx, 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)
        if im.BeginDragDropTarget(ctx) then -- if drop to post fx chain
            Drop, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
            HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)

            if Drop and not tablefind(TrkTB.PostFX, FXGUID[DragFX_ID]) then
                table.insert(TrkTB.PostFX, FXGUID[DragFX_ID])
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #TrkTB.PostFX, FXGUID [DragFX_ID], true)
                r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)

                local IDinPre = tablefind(TrkTB.PreFX, FXGUID[DragFX_ID])
                if IDinPre then MoveFX_Out_Of_Pre(IDinPre, TrkTB) end
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
end

function Post_FX_Chain (TrkTB, Payload_Type)


    TrkTB.PostFX = TrkTB.PostFX or {}
    if ((DragDroppingFX and MouseAtRightEdge) and not TrkTB.PostFX[1]) then
        if TrkTB.PreFX[1] then MakeSpaceForPostFX = 30 else MakeSpaceForPostFX = 0 end
    elseif TrkTB.PostFX_Hide and TrkTB.PreFX[1] then
        MakeSpaceForPostFX = 20
    else
        MakeSpaceForPostFX = 0
    end


    if not TrkTB.PostFX[1] then
        TrkTB.MakeSpcForPostFXchain = 0
        return 
    end 

    local PostFX_Width = math.min( (MakeSpaceForPostFX or 0) + ((Trk[TrkID].MakeSpcForPostFXchain or 0) + (PostFX_LastSpc or 0)) + 30, VP.w / 2)
    im.SameLine(ctx, nil, 0)
    Line_L, Line_T = im.GetCursorScreenPos(ctx)
    rv             = im.Button(ctx, (#TrkTB.PostFX or '') .. '\n\n' .. 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
    if im.IsItemClicked(ctx, 1) then
        if TrkTB.PostFX_Hide then TrkTB.PostFX_Hide = false else TrkTB.PostFX_Hide = true end
    end
    if im.BeginDragDropTarget(ctx) then -- if drop to post fx chain Btn
        if Payload_Type == 'FX_Drag' then
            Drop, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
            HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)
            if Drop and not tablefind(TrkTB.PostFX, FXGUID[DragFX_ID]) then
                --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)
                table.insert(TrkTB.PostFX, FXGUID[DragFX_ID])
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #TrkTB.PostFX, FXGUID[DragFX_ID], true)


                local IDinPre = tablefind(TrkTB.PreFX, FXGUID[DragFX_ID])
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
                table.insert(TrkTB.PostFX, FXid)
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #TrkTB.PostFX, FXid, true)
            end
        end

        im.EndDragDropTarget(ctx)
    end

    im.SameLine(ctx, nil, 0)
    im.PushStyleColor(ctx, im.Col_ChildBg, 0xffffff11)
    local PostFX_Extend_W = 0
    if PostFX_Width == VP.w / 2 then PostFX_Extend_W = 20 end
    if not TrkTB.PostFX_Hide then
        if im.BeginChild(ctx, 'Post FX chain', PostFX_Width - PostFX_Extend_W, 220) then
            local clr = im.GetStyleColor(ctx, im.Col_Button)
            im.DrawList_AddLine(Glob.FDL, Line_L, Line_T - 1, Line_L + VP.w, Line_T - 1, clr)
            im.DrawList_AddLine(Glob.FDL, Line_L, Line_T + 220, Line_L + VP.w, Line_T + 220, clr)



            TrkTB.MakeSpcForPostFXchain = 0

            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = 0 else offset = 1 end

            for FX_Idx, V in pairs(TrkTB.PostFX) do
                local I = --[[ tablefind(FXGUID, TrkTB.PostFX[#TrkTB.PostFX+1-FX_Idx])  ]]
                    tablefind(FXGUID, V)

                local Spc
                if FX_Idx == 1 and I then AddSpaceBtwnFXs(I - 1, 'SpcInPost', nil, nil, 1) end
                if I then
                    createFXWindow(I)
                    im.SameLine(ctx, nil, 0)

                    FX[FXGUID[I]].PostWin_SzX, _ = im.GetItemRectSize(ctx)
                    TrkTB.MakeSpcForPostFXchain = (TrkTB.MakeSpcForPostFXchain or 0) +
                        (FX.WidthCollapse[FXGUID[I]] or FX[FXGUID[I]].Width or (DefaultWidth)) +
                        10 -- 10 is space btwn fxs

                    if FX_Idx == #TrkTB.PostFX then
                        AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, #TrkTB.PostFX + 1)
                    else
                        AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, FX_Idx + 1)
                    end
                    if FX_Idx == #TrkTB.PostFX and im.IsItemHovered(ctx, im.HoveredFlags_RectOnly) then
                        MouseAtRightEdge = true --[[ else MouseAtRightEdge = nil ]]
                    end
                end
            end




            offset = nil


            if InsertToPost_Src then
                table.insert(TrkTB.PostFX, InsertToPost_Dest, FXGUID[InsertToPost_Src])
                for i = 1, #TrkTB.PostFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i,
                        TrkTB.PostFX[i] or '',
                        true)
                end
                InsertToPost_Src = nil
                InsertToPost_Dest = nil
            end
            im.EndChild(ctx)
        end
    else
        TrkTB.MakeSpcForPostFXchain = 0
    end


    for FX_Idx, V in pairs(TrkTB.PostFX) do
        local I = tablefind(FXGUID, V)
        local P = Sel_Track_FX_Count - #TrkTB.PostFX + (FX_Idx - 1)


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
