-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid

---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------
FX[FxGUID].TitleWidth = 50 -- Use this to set title bar width 
FX[FxGUID].Width = 200   -- use this to set the device's width

SL()
im.Text(ctx, 'title area')
SL()



ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '', Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)



---------------------------------------------
---------Body--------------------------------
---------------------------------------------



if not FX[FxGUID].Collapse then
    if Prm.InstAdded[PluginScript.Guid] ~= true then
        ----- Declare the parameters here ----------
        --- number in green represents FX Prm Index
        StoreNewParam(FxGUID, 'Volume', 0 --[[Prm number]] , FX_Idx, false, 'AddingFromExtState',
            1--[[Prm table index]], FX_Idx )       
        StoreNewParam(FxGUID, 'Pan', 1 --[[Prm number]] , FX_Idx, false, 'AddingFromExtState',
        2--[[Prm table index]] , FX_Idx)       
        StoreNewParam(FxGUID, 'Pan Law', 2 --[[Prm number]] , FX_Idx, false, 'AddingFromExtState',
        3--[[Prm table index]], FX_Idx )

        Prm.InstAdded[FxGUID] = true
        r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added','true') --- this line is needed so the parameters will only be added once.
    end
    function F_Tp(FX_P)
        return FX.Prm.ToTrkPrm[FxGUID .. FX_P]
    end





    FX[FxGUID][1].BgClr = 0xffffffff     -- FX[FxGUID][1] is the volume parameter    BgClr sets it's background color 
    AddKnob(ctx, '##Vol', 'Volume', FX[FxGUID][1--[[Prm table index]]].V or 0, 0, 1, 1, FX_Idx, 0--[[Prm number]],
    style --[[default style]], 20 --[[Radius]], 0, Disabled, 12 --[[Lbl Txt size ]], 'Bottom')
    --[[AddKnob(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, Style, Radius,
                item_inner_spacing, Disabled, LblTextSize, Lbl_Pos, V_Pos, ImgPath)]]

    AddSpacing(5)

    AddSlider(ctx, '##Pan', 'Pan', FX[FxGUID][2--[[Prm table index]]].V or 0, 0, 1, 2, FX_Idx, 1, SliderStyle, 120 --[[Sldr width]],
        item_inner_spacing, Disable, Vertical, GrabSize, BtmLbl, SpacingBelow, Height)
    --[[AddSlider(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, SliderStyle, Sldr_Width,
                item_inner_spacing, Disable, Vertical, GrabSize, BtmLbl, SpacingBelow, Height)]]

    im.Text(ctx, 'example text')
    AddDrag(ctx, '##Pan Law', 'Pan Law', FX[FxGUID][3--[[Prm table index]]].V or 0, 0, 1, 3, FX_Idx, 2 --[[Prm Num]], Style, 80 --[[width]],
    0, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, 'Left-Right', AllowInput)

    --[[AddDrag(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, Style, Sldr_Width,
                 item_inner_spacing, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, DragDir, AllowInput) ]]

    
end
