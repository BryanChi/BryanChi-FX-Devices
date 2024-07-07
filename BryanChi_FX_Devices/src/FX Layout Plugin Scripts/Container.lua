-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid

FX[FxGUID].TitleWidth  = 0
FX[FxGUID].CustomTitle = 'Container'
FX[FxGUID].Width = 35
FX[FxGUID].V_Win_Btn_Height = 130 
FX[FxGUID].Cont_Collapse = FX[FxGUID].Cont_Collapse or 0
local fx = FX[FxGUID]
local ModIconSz = 18 

local Root_ID = 0
if FX_Idx < 0x2000000 then Root_ID = FX_Idx   Root_FxGuid = FxGUID end 

DEBUG_W = DEBUG_W or {}

local Accent_Clr = 0x49CC85ff



local function Modulation_Icon(LT_Track, slot)
    im.PushStyleColor ( ctx, im.Col_Button, 0x000000000)
    if im.ImageButton(ctx, '##', Img.ModIconHollow, ModIconSz , ModIconSz*0.46, nil, nil, nil, nil, 0x00000000, 0xD3D3D399) then 
        FX[FxGUID].MacroPageActive = toggle (FX[FxGUID].MacroPageActive)
        Trk[TrkID].Container_Id = Trk[TrkID].Container_Id or {}
        table.insert(Trk[TrkID].Container_Id , FxGUID)
        if not slot then slot  = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1)end 
        local _, FirstFX = r.TrackFX_GetFXName(LT_Track, slot)
        if not string.find(FirstFX, 'FXD Containr Macro') then 
            AddMacroJSFX('FXD Containr Macro', slot )
        end 
    end 
    im.PopStyleColor(ctx)
end

local function titleBar()


    if not FX[FxGUID].Collapse then

        SyncWetValues(FX_Idx)
        local x, y = im.GetCursorPos(ctx)
        im.SetCursorPos(ctx, 3, 165)

        Modulation_Icon(LT_Track, fx.LowestID)
    
        im.SetCursorPos(ctx, 3, 135)
        SyncWetValues(FX_Idx)
        

        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 1, 0, 1, FX_Idx)
        

        im.SetCursorPos(ctx,x,y)


    end
end

titleBar()
FX[FxGUID].BgClr = 0x258551ff

---------------------------------------------
---------Body--------------------------------
---------------------------------------------


rv, FX_Count = r.TrackFX_GetNamedConfigParm( LT_Track, FX_Idx, 'container_count')
local WinW = 0 
local AllW = 0

function CollapseIfTab(FxGUID, FX_Idx)


    if FX[FxGUID].Cont_Collapse == 0 then FX[FxGUID].Cont_Collapse= 1
    elseif FX[FxGUID].Cont_Collapse==1 then FX[FxGUID].Cont_Collapse= 0 end 

end


function AddTitleBgClr ()

    local x , y = im.GetCursorScreenPos(ctx)
    local X = x
    local WDL = im.GetWindowDrawList(ctx)

    im.DrawList_AddRectFilled(WDL, X-25, y , X, y + 220, 0x49CC8544)

end


local function DragDropToCollapseView (FX_Id,Xpos, GUID, v)
    if  (Payload_Type == 'FX_Drag' or Payload_Type == 'DND ADD FX') then 
        
        local W, H = 130, 20
        local L,T = im.GetCursorScreenPos(ctx)
        local L = Xpos
        --if FX_Id ~= FX[FxGUID].LastSpc then  L = L-135  end 

        if im.IsMouseHoveringRect(ctx, L, T-H/2, L+W, T+H/2 )  then 
            im.DrawList_AddLine(Glob.FDL, L, T, L+W , T, Accent_Clr, 3)
            if im.IsMouseReleased(ctx, 0) then 
                --msg(FX[GUID].parent .. '   id = '..FX_Idx)
                local Drag_GUID = r.TrackFX_GetFXGUID(LT_Track, Payload)
                local ofs  = 0 
                if FX[FxGUID].parent == FX[Drag_GUID].parent then -- if they're in the same container
                    if Payload < FX_Id then 
                        if v then ofs = v.scale end 
                            
                    end
                end 

                table.insert(MovFX.FromPos, Payload )
                table.insert(MovFX.ToPos,   FX_Id - ofs)
                if Mods == Apl then  NeedCopyFX=true   DropPos = FX_Id end 
            end
        end
        --im.DrawList_AddRect(WDL, L , T-H/2, L+W, T+H/(Last or 2), 0xff77ffff)
    end 
end

local function DndAddFXtoContainer_TARGET()
    im.PushStyleColor(ctx, im.Col_DragDropTarget, 0)
    if im.BeginDragDropTarget(ctx) then
        local dropped, payload = im.AcceptDragDropPayload(ctx, 'DND ADD FX')
        im.EndDragDropTarget(ctx)
        if dropped and Mods == 0  then
            local FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) -- root containder  

            if FxGUID ~= Root_FxGuid then 
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1) 
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1
                
                local function Get_Fx_Ct (TB, base_FX_Ct )
                    local C =  Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                        
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct (C , Nxt_Lyr_FX_Ct )
                    end

                    return Final_FX_Ct
                end

                local FX_Ct =  Get_Fx_Ct (TREE, Rt_FX_Ct )

                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1) 
                
                FX_Id =   Empty_Cont_Fx_Id
            end
            r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Id)
        end
    end
    im.PopStyleColor(ctx)
end

local function DndMoveFXtoContainer_TARGET()
    if im.BeginDragDropTarget(ctx) then
        local rv, payload = im.AcceptDragDropPayload(ctx, 'FX_Drag')
        im.EndDragDropTarget(ctx)
        Highlight_Itm(WDL, 0xffffff33)
        if rv and Mods == 0 then 
            local FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) -- root containder  

            if FxGUID ~= Root_FxGuid then 
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1) 
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1
                
                local function Get_Fx_Ct (TB, base_FX_Ct )
                    local C =  Check_If_Has_Children_Prioritize_Empty_Container(TB)

                    if not C then -- if container has no children
                        Final_FX_Ct = base_FX_Ct
                        
                    else
                        local Nxt_Lyr_FX_Ct = base_FX_Ct * (#C + 1)
                        Get_Fx_Ct (C , Nxt_Lyr_FX_Ct )
                    end

                    return Final_FX_Ct
                end

                local FX_Ct =  Get_Fx_Ct (TREE, Rt_FX_Ct )

                Empty_Cont_Fx_Id = FX_Idx + (FX_Ct * 1) 
                
                FX_Id =   Empty_Cont_Fx_Id

            end
            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Id, true )
        end
    end    
end

local function Render_Collapsed ( v ,  CollapseXPos , FX_Id, CollapseYPos,i ,GUID,TB)
    local Hv
    FX[FxGUID].BgClr=nil
    

    im.SetCursorPosX(ctx, tonumber( CollapseXPos))
    --local FX_Id = 0x2000000 + i*(r.TrackFX_GetCount(LT_Track)+1) + (FX_Idx+1)
    local GUID =  r.TrackFX_GetFXGUID(LT_Track, FX_Id)
    FX[FxGUID].Width = 50 + 150
    if GUID then 
        im.PushStyleVar(ctx, im.StyleVar_ItemSpacing,1 , -3)

        FX[GUID] = FX[GUID]  or {}
        local Click = AddWindowBtn (GUID, FX_Id, 130, true , true , true ) 

        
        SL(165)
        DragDropToCollapseView (FX_Id, CollapseXPos_screen, GUID, v )

        
        --SyncWetValues(FX_Id)
        if Click == 2  then 
            if FX[FxGUID].Sel_Preview ~= FX_Id then 
                FX[FxGUID].Sel_Preview = FX_Id
            else 
                FX[FxGUID].Sel_Preview = nil
            end
        end
        if FX[FxGUID].Sel_Preview == FX_Id then 
            HighlightSelectedItem(nil,Accent_Clr,nil,nil,nil,nil,nil,nil,nil,1,1,'GetItemRect')
        end
        SyncWetValues(FX_Id)
        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Id] = Add_WetDryKnob(ctx, 'a'..FX_Id, '', Wet.Val[FX_Id] or 1, 0, 1, FX_Id)
        
        


        im.PopStyleVar(ctx)
        if Hover then 
            if tonumber(FX_Count) > 9  then 
                --FX_DeviceWindow_NoScroll = im.WindowFlags_NoScrollWithMouse
                DisableScroll = true 
                FX[FxGUID].NoScroll = nil 

            else 
                FX_DeviceWindow_NoScroll = 0
                DisableScroll = false 
                --FX[FxGUID].NoScroll =  im.WindowFlags_NoScrollWithMouse  +  im.WindowFlags_NoScrollbar +  im.WindowFlags_AlwaysAutoResize

            end
        end

        
        --[[ + (    Hv or 0) ]]

        if FX[FxGUID].Cont_Collapse ==1 then 

            FX[FxGUID].LastSpc = FX_Id + (v.scale or 0)

        end
        
        if Hv then  return Hv end 
    end
    
end
local X , Y = im.GetCursorScreenPos(ctx)



local function  macroPage()
    if not fx.MacroPageActive then return end 

    local Size = 15 
    for i = 1 , 8 , 1 do 
        fx.Mc = fx.Mc or {}
        fx.Mc[i] = fx.Mc[i] or {}
    end 

    for i = 0 , 3 , 1 do 
        local I = i +1
        local mc = fx.Mc[I]

        im.SetCursorPos(ctx,45,  10+ i * (Size*2+25))
        
        mc.TweakingKnob , mc.Val = AddKnob_Simple(ctx , 'Macro'..i,  mc.Val or 0, Size)
        im.SetNextItemWidth(ctx, Size*3)
        
        im.SetCursorPos(ctx,35,  10+ i * (Size*2+25) + Size*1.6 )
        --im.InputText(ctx,'##Label'..i)

        _,mc.Name =  r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro '..I..' Name', '', false)
        local rv, label = im.InputText(ctx, '##'..i, mc.Name or 'Mc ' .. I, im.InputTextFlags_AutoSelectAll)
        if rv then 
            mc.Name = label
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container '..FxGUID..' Macro '..I..' Name', label, true )
        end 

        if mc.TweakingKnob then 
            r.TrackFX_SetParamNormalized(LT_Track, fx.LowestID, i, mc.Val)
        end 

    end 



end  
macroPage(fx)

local TB = Upcoming_Container or TREE[Root_ID+1].children

if tonumber( FX_Count) == 0 then 

    im.SetCursorScreenPos(ctx, X-50 , Y)
    im.InvisibleButton(ctx, 'DropDest'..FxGUID , 60 , 210)

    --second_layer_container_id = first_layer_container_id + (first_layer_fx_count * second_layer_container_pos)

    DndMoveFXtoContainer_TARGET()
    DndAddFXtoContainer_TARGET()
else
    local CollapseXPos, CollapseYPos  = im.GetCursorPos(ctx)
     CollapseXPos_screen = im.GetCursorScreenPos(ctx)
    local PreviewW , LastSpc 

    for i, v in ipairs(Upcoming_Container or TREE[Root_ID+1].children) do 
        if i == 1 then 
            fx.LowestID =  v.addr_fxid
        end 
        local FX_Id = v.addr_fxid
        local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)

        

        if  FX[FxGUID].Cont_Collapse == 1  then 

            local W  = Render_Collapsed(v,CollapseXPos,FX_Id, CollapseYPos,i,GUID, TB)
            if W then PreviewW = W end 
            --FX[FxGUID].BgClr = 0xffffff44

        else       -- if not collapsed
            --FX[FxGUID].BgClr = 0xff22ff44
            local function Render_Normal()
                local  diff, Cur_X_ofs
                if i == 1 then 
                    SL(nil,0)
                    im.SetCursorPosY(ctx, 0 )

                     AddSpaceBtwnFXs(FX_Id  , SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth)
                    SL(nil,0)

                end

                If_Theres_Pro_C_Analyzers(FX_Name, FX_Id)
                im.SetCursorPosY(ctx,0)
            
                if v.children then 
                    Upcoming_Container = v.children
                    Upcoming_Container_Parent = v 
                end

                
                local Hv = createFXWindow(FX_Id)
                SL(nil,0)
                
                if v.scale and GUID  then 
                    FX[GUID] = FX[GUID] or {}   
                    FX[GUID].parent =  v.addr_fxid - v.scale * i   
                end 
            
                local w = im.GetItemRectSize(ctx)
                local TB = Upcoming_Container or TREE[Root_ID+1].children
                local FX_Id_next = FX_Id + (v.scale or 0)

                if im.IsItemHovered(ctx) then Hover = true end 
                im.SetCursorPosY(ctx, 0 )
                LastSpc = AddSpaceBtwnFXs(FX_Id_next , nil, nil, nil, nil, nil, nil, FX_Id)

                FX[FxGUID].Width = (FX[FxGUID].Width or 0) + w +( LastSpc or 0)
                
                if Hover then  DisableScroll = false  end 
            end
            local W= Render_Normal()

        end

        if Upcoming_Container and tonumber(i) == (#Upcoming_Container or #TREE[Root_ID+1].children) then 
            Upcoming_Container = nil
        end
    end


    local Add_FX_Btn_Ypos
    if FX[FxGUID].Cont_Collapse == 1   and FX[FxGUID].Sel_Preview then 
        SL()
        Add_FX_Btn_Ypos = im.GetCursorPosY(ctx) + 24
        im.SetCursorPosY(ctx,tonumber( CollapseYPos)  )

        Hv = createFXWindow(FX[FxGUID].Sel_Preview)
        if Hv then PreviewW = Hv end 
        if PreviewW then FX[FxGUID].Width = 50 + 150 + PreviewW end
    end
    if FX[FxGUID].Cont_Collapse == 1 then
        if Add_FX_Btn_Ypos then im.SetCursorPosY(ctx,tonumber( Add_FX_Btn_Ypos)  ) end 
        im.SetCursorPosX(ctx,tonumber( CollapseXPos)  )
        DragDropToCollapseView (FX[FxGUID].LastSpc, CollapseXPos_screen)
        if im.Button(ctx,'+' , 130) then 
            im.OpenPopup(ctx, 'Btwn FX Windows' .. FX[FxGUID].LastSpc)
        end 
        AddFX_Menu(FX[FxGUID].LastSpc)
    end

    if Upcoming_Container  then 
        if not Upcoming_Container[1] then 
            Upcoming_Container =nil
        end

    else 
    
    end
                            
   --[[  if NeedRetrieveLayout then 
        RetrieveFXsSavedLayout(Sel_Track_FX_Count) 
        NeedRetrieveLayout = nil 
    end  ]]


    
    if not FX[FxGUID].Collapse then 
        local WDL = im.GetWindowDrawList(ctx)
        --im.DrawList_AddRect(WDL ,XX - 33, YY, XX+FX[FxGUID].Width -35, YY+220, 0xffffffff)
        HighlightSelectedItem(nil, Accent_Clr, 0, X - 33, Y, X+ (FX[FxGUID].Width or 190)  -35 , Y+218, h, w, 1, 0.2, GetItemRect, Foreground, rounding, 4)
    end 



end

