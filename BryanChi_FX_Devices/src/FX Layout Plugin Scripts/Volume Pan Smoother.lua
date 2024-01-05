-- @noindex
local GF = require("src.Functions.General Functions")
local gui_helpers = require("src.Components.Gui_Helpers")



r = reaper

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid

---------------------------------------------
---------TITLE BAR AREA------------------
---------------------------------------------
FxdCtx.FX[FxGUID].TitleWidth = 50 -- Use this to set title bar width 
FxdCtx.FX[FxGUID].Width = 200   -- use this to set the device's width

gui_helpers.SL()
r.ImGui_Text(ctx, 'title area')
gui_helpers.SL()



ActiveAny, FxdCtx.Wet.Active, FxdCtx.Wet.Val[FX_Idx] = GF.Add_WetDryKnob(ctx, 'a', '', FxdCtx.Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)



---------------------------------------------
---------Body--------------------------------
---------------------------------------------



if not FxdCtx.FX[FxdCtx.FXGUID[FX_Idx]].Collapse then
    if FxdCtx.Prm.InstAdded[PluginScript.Guid] ~= true then
        ----- Declare the parameters here ----------
        --- number in green represents FX Prm Index
        StoreNewParam(FxdCtx.FXGUID[FX_Idx], 'Volume', 0 --[[Prm number]] , FX_Idx, false, 'AddingFromExtState',
            1--[[Prm table index]], FX_Idx )       
        StoreNewParam(FxdCtx.FXGUID[FX_Idx], 'Pan', 1 --[[Prm number]] , FX_Idx, false, 'AddingFromExtState',
        2--[[Prm table index]] , FX_Idx)       
        StoreNewParam(FxdCtx.FXGUID[FX_Idx], 'Pan Law', 2 --[[Prm number]] , FX_Idx, false, 'AddingFromExtState',
        3--[[Prm table index]], FX_Idx )

        FxdCtx.Prm.InstAdded[FxdCtx.FXGUID[FX_Idx]] = true
        r.SetProjExtState(0, 'FX Devices', 'FX' .. FxdCtx.FXGUID[FX_Idx] .. 'Params Added','true') --- this line is needed so the parameters will only be added once.
    end
    function F_Tp(FX_P)
        return FxdCtx.FX.Prm.ToTrkPrm[FxGUID .. FX_P]
    end





    FxdCtx.FX[FxGUID][1].BgClr = 0xffffffff     -- FX[FxGUID][1] is the volume parameter    BgClr sets it's background color 
    AddKnob(ctx, '##Vol', 'Volume', FxdCtx.FX[FxGUID][1--[[Prm table index]]].V or 0, 0, 1, 1, FX_Idx, 0--[[Prm number]],
    style --[[default style]], 20 --[[Radius]], 0, Disabled, 12 --[[Lbl Txt size ]], 'Bottom')
    --[[AddKnob(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, Style, Radius,
                item_inner_spacing, Disabled, LblTextSize, Lbl_Pos, V_Pos, ImgPath)]]

    GF.AddSpacing(5)

    AddSlider(ctx, '##Pan', 'Pan', FxdCtx.FX[FxGUID][2--[[Prm table index]]].V or 0, 0, 1, 2, FX_Idx, 1, SliderStyle, 120 --[[Sldr width]],
        item_inner_spacing, Disable, Vertical, GrabSize, BtmLbl, SpacingBelow, Height)
    --[[AddSlider(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, SliderStyle, Sldr_Width,
                item_inner_spacing, Disable, Vertical, GrabSize, BtmLbl, SpacingBelow, Height)]]

    r.ImGui_Text(ctx, 'example text')
    AddDrag(ctx, '##Pan Law', 'Pan Law', FxdCtx.FX[FxGUID][3--[[Prm table index]]].V or 0, 0, 1, 3, FX_Idx, 2 --[[Prm Num]], Style, 80 --[[width]],
    0, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, 'Left-Right', AllowInput)

    --[[AddDrag(ctx, label, labeltoShow, p_value, v_min, v_max, Fx_P, FX_Idx, P_Num, Style, Sldr_Width,
                 item_inner_spacing, Disable, Lbl_Clickable, Lbl_Pos, V_Pos, DragDir, AllowInput) ]]

    
end
