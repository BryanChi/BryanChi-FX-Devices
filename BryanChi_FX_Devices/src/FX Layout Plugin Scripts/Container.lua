-- @noindex



r = reaper

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid

FX[FxGUID].TitleWidth  = 0
FX[FxGUID].CustomTitle = 'Container'
FX[FxGUID].Width = 35
FX[FxGUID].V_Win_Btn_Height = 130 
FX[FxGUID].Cont_Collapse = FX[FxGUID].Cont_Collapse or 0

local Root_ID = 0
if FX_Idx < 0x2000000 then Root_ID = FX_Idx   Root_FxGuid = FxGUID end 

--msg(FX_Idx .. 'Begin Container script')

---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------


if not FX[FxGUID].Collapse then

    --[[ local nm = Vertical_FX_Name (FX_Name)
    WindowBtn = r.ImGui_Button(ctx, nm, 25, 130) ]]


    SyncWetValues(FX_Idx)
    local x, y = r.ImGui_GetCursorPos(ctx)
    r.ImGui_SetCursorPos(ctx, 3, 135)
    Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)
    r.ImGui_SetCursorPos(ctx,x,y)

end


local Hover = FX[FxGUID].Hover 


---------------------------------------------
---------Body--------------------------------
---------------------------------------------


rv, FX_Count = r.TrackFX_GetNamedConfigParm( LT_Track, FX_Idx, 'container_count')
local WinW = 0 
local AllW = 0

function CollapseIfTab(FxGUID)
    if r.ImGui_IsWindowHovered(ctx) then Hover = true  end 
    if Hover and r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Tab()) then 

        if FX[FxGUID].Cont_Collapse == 0 then FX[FxGUID].Cont_Collapse= 1
        elseif FX[FxGUID].Cont_Collapse==1 then FX[FxGUID].Cont_Collapse= 0 end 
    end 
end

local function Render_Collapsed ( TB ,  FxGUID , FX_Id)

        local X = r.ImGui_GetCursorPosX(ctx)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(),1 , -3)
        

        r.ImGui_SetCursorPosX(ctx,X)
        --local FX_Id = 0x2000000 + i*(r.TrackFX_GetCount(LT_Track)+1) + (FX_Idx+1)
        local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)
        AddWindowBtn (GUID,FX_Id, 130, true , true ) 
        if r.ImGui_BeginDragDropTarget(ctx) then 
        end
        SL(165)
        --SyncWetValues(FX_Id)
        
        Wet.ActiveAny, Wet.Active, Wet.Val[FX_Id] = Add_WetDryKnob(ctx, 'a'..FX_Id, '', Wet.Val[FX_Id] or 0, 0, 1, FX_Id)
        

        r.ImGui_PopStyleVar(ctx)
        if tonumber(FX_Count) > 9 and Hover then 
            FX_DeviceWindow_NoScroll = r.ImGui_WindowFlags_NoScrollWithMouse() 
            DisableScroll = true 
        else FX_DeviceWindow_NoScroll = 0
            DisableScroll = false 
        end
        FX[FxGUID].Width = 50+140

        WinW = FX[FxGUID].Width
        CollapseIfTab(FxGUID)

end
local x , y = r.ImGui_GetCursorScreenPos(ctx)
 -- 
 

if tonumber( FX_Count) == 0 then 
    r.ImGui_SetCursorScreenPos(ctx, x-50 , y )
    r.ImGui_InvisibleButton(ctx, 'DropDest'..FxGUID , 60 , 210)

    local TB = Upcoming_Container or TREE[Root_ID+1].children

    --second_layer_container_id = first_layer_container_id + (first_layer_fx_count * second_layer_container_pos)

    ------  33554460------
    ------  33554454 ------

    if r.ImGui_BeginDragDropTarget(ctx)then 
        local rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
        Highlight_Itm(WDL, 0xffffff33)

        if rv and Mods == 0 then 
            local FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) -- root containder  

            if FxGUID ~= Root_FxGuid then 
                --FX_Id = 0x2000000 + 1*(r.TrackFX_GetCount(LT_Track)+1) + (Root_ID+1) + 1*(0+1) + (Upcoming_ContainerID+1) 
                local Rt_FX_Ct = r.TrackFX_GetCount(LT_Track) + 1
                
                local Frs_Lyr_FX_Ct =  Rt_FX_Ct *  (#TREE[Root_ID+1].children + 1 )
                local Sec_Lyr_FX_Ct = Frs_Lyr_FX_Ct * (math.max(#TB,1) + 1)

                local Root = 0x2000000 +1
                Frst_Lyr_FX_Id = Root + 1 * (4-1)
                Frst_Lyr_Cont_Id = Root +  1 * (4)


                Sec_Lyr_FX_ID = FX_Idx + (Frs_Lyr_FX_Ct  * 1) 

                third_Lyr_Fx_Id = FX_Idx + (Sec_Lyr_FX_Ct * 1) 

                if Upcoming_Container then 

                end
                FX_Id = third_Lyr_Fx_Id
                
                msg( Sec_Lyr_FX_Ct )
            end

            r.TrackFX_CopyToTrack(LT_Track,DragFX_ID, LT_Track, FX_Id, true )
        end
    end

else

    for i, v in ipairs(Upcoming_Container or TREE[Root_ID+1].children) do 

        local FX_Id = v.addr_fxid
        local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Id)


        if FX[GUID]  and   FX[GUID].Cont_Collapse == 1  then 
            Render_Collapsed(v,GUID,FX_Id)
        else        -- if not collapsed
            local function Render_Normal()
                local WinW
                if i == 1 then 
                    SL(nil,0)
                    local SpcW = AddSpaceBtwnFXs(FX_Id , SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth)
                    SL(nil,0)
                    WinW = SpcW 
                end
            
                if v.children then 
                    Upcoming_Container = v.children
                    Upcoming_ContainerID = i
                end
            
                SL(nil,0)
                local Hv = createFXWindow(FX_Id)
                SL(nil,0)



                --[[ first_layer_fx_id = root_container_id + (root_fx_count * first_layer_fx_pos)
                first_layer_container_id =  root_container_id + (root_fx_count * first_layer_container_pos)
                second_layer_fx_id = first_layer_container_id + (first_layer_fx_count * second_layer_fx_pos)
                second_layer_container_id = first_layer_container_id + (first_layer_fx_count * second_layer_container_pos)
                third_layer_fx_id =  second_layer_container_id + (second_layer_fx_count * third_layer_fx_pos) ]]

            
                local w = r.ImGui_GetItemRectSize(ctx)
                local FX_Id_next = 0x2000000 + (i+1)*(r.TrackFX_GetCount(LT_Track)+1) + (FX_Idx+1)
                local TB = Upcoming_Container or TREE[Root_ID+1].children



                --local FX_Id_next = TB[ math.min(i+1, #TB)].addr_fxid
                --msg(i..'       FX_IDNext= '..FX_Id_next..'     math.min(i+1, #TB) '..math.min(i+1, #TB))
                if r.ImGui_IsItemHovered(ctx) then Hover = true end 
            
                local SpcW = AddSpaceBtwnFXs(FX_Id_next , nil, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container, AdditionalWidth, FX_Id)


                FX[FxGUID].Width = (FX[FxGUID].Width or 0) + w + SpcW


                WinW = (WinW or 0) + w + SpcW   

                if Hv then  Hover = true end 
                if Hover then  DisableScroll = false  end 
                CollapseIfTab(GUID)
                if not v.children then
                    return WinW
                else return 35
                end
            end
            local W= Render_Normal()
            AllW = AllW + (W or 0)
        end

        if Upcoming_Container and tonumber(i) == (#Upcoming_Container or #TREE[Root_ID+1].children) then 
            Upcoming_Container = nil
            if Root_FxGuid~= FxGUID then 
                --FX[Root_FxGuid].Width = (FX[Root_FxGuid].Width + (FX[FxGUID].Width or 0))
            end
        
        end
    end

    if Upcoming_Container  then 
        if not Upcoming_Container[1] then 
            Upcoming_Container =nil
        end
    else 
    
    end


    
    if not FX[FxGUID].Collapse then 
        local WDL = r.ImGui_GetWindowDrawList(ctx)
        r.ImGui_DrawList_AddRect(WDL ,x - 33, y, x+FX[FxGUID].Width -35, y+220, 0xffffffff)
    end 


end


