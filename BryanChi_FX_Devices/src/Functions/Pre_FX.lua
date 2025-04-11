-- @noindex
-- @version 1.0Beta 1


function Add_Btn_To_Drop_On_If_Mouse_Is_At_Left_Edge(TrkTB)
    Cx_LeftEdge, Cy_BeforeFXdevices = im.GetCursorScreenPos(ctx)
    MouseAtLeftEdge = im.IsMouseHoveringRect(ctx, Cx_LeftEdge - 50, Cy_BeforeFXdevices, Cx_LeftEdge + 5, Cy_BeforeFXdevices + 220)

    TrkTB.PreFX = TrkTB.PreFX or {}
    if MouseAtLeftEdge and not TrkTB.PreFX[1] and string.len(Payload_Type) > 1 then
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

    local spaceIfPreFX = 0
    if Trk[TrkID].PreFX[1] and Trk[TrkID].PostFX[1] and not Trk[TrkID].PostFX_Hide then spaceIfPreFX = 20 end
    return spaceIfPreFX
end

function Add_Pre_FX_Btn_If_Needed(Trk)


    if Trk[TrkID].PreFX[1] then
        rv = im.Button(ctx, (#Trk[TrkID].PreFX or '') .. '\n\n' .. 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
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
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #Trk[TrkID].PreFX, FXGUID[DragFX_ID], true)
                end

                -- move fx out of post chain
                local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                --Move FX out of layer
                if FX.InLyr[FXGUID[DragFX_ID]] then
                    FX.InLyr[FXGUID[DragFX_ID]] = nil
                    r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer', '')
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
end


function If_Pre_FXs_are_Not_In_Right_Order(Trk)
    for i, v in pairs(Trk[TrkID].PreFX or {}) do
        if FXGUID[i - offset] ~= v then
            if not AddFX.Name[1] then
                table.insert(MovFX.FromPos, tablefind(FXGUID, v))
                table.insert(MovFX.ToPos, i - offset)
                table.insert(MovFX.Lbl, 'Move FX into Pre-Chain')
            end
        end
    end
end




function MoveFX_Out_Of_Pre(IDinPre, TrkTB)
    table.remove(TrkTB.PreFX, IDinPre or tablefind(TrkTB.PreFX, FXGUID[DragFX_ID]))
    for i = 1, #TrkTB.PreFX + 1, 1 do
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, TrkTB.PreFX[i] or '', true)
    end
end