local math_helpers = require("src.helpers.math_helpers")

local colors = {}

colors.CustomColors = { 'Window_BG', 'FX_Devices_Bg', 'FX_Layer_Container_BG', 'Space_Between_FXs', 'Morph_A', 'Morph_B',
    'Layer_Solo', 'Layer_Mute', 'FX_Adder_VST', 'FX_Adder_VST3', 'FX_Adder_JS', 'FX_Adder_AU', 'FX_Adder_CLAP',
    'FX_Adder_LV2',
    'PLink', 'PLink_Edge_DarkBG', 'PLink_Edge_LightBG',
    'RDM_BG', 'RDM_VTab', 'RDM_VTab_Highlight', 'RDM_VTab_Highlight_Edge', 'RDM_PadOff', 'RDM_PadOn', 'RDM_Pad_Highlight',
    'RDM_Play', 'RDM_Solo', 'RDM_Mute', 'RDM_DnDFX', 'RDM_DnD_Move' }

colors.CustomColorsDefault = {
    Window_BG = 0x000000ff,
    FX_Devices_Bg = 0x151515ff,
    FX_Layer_Container_BG = 0x262626ff,
    Space_Between_FXs = 0x131313ff,
    Morph_A = 0x22222266,
    Morph_B = 0x78787877,
    Layer_Solo = 0xDADF3775,
    Layer_Mute = 0xBE01015C,
    FX_Adder_VST = 0x6FB74BFF,
    FX_Adder_VST3 = 0xC3DC5CFF,
    FX_Adder_JS = 0x9348A9FF,
    FX_Adder_AU = 0x526D97FF,
    FX_Adder_CLAP = 0xB62424FF,
    FX_Adder_LV2 = 0xFFA500FF,
    PLink = 0x1E90FFFF,
    PLink_Edge_DarkBG = 0x1E90FFFF,
    PLink_Edge_LightBG = 0x191970FF,
    RDM_BG = 0x141414ff,
    RDM_VTab = 0x252525FF,
    RDM_VTab_Highlight = 0x12345655,
    RDM_VTab_Highlight_Edge = 0x184673ff,
    RDM_PadOff = 0xff,
    RDM_PadOn = 0x123456FF,
    RDM_Pad_Highlight = 0x256BB155,
    RDM_Play = 0xff,
    RDM_Solo = 0xff,
    RDM_Mute = 0xff,
    RDM_DnDFX = 0x00b4d8ff,
    RDM_DnD_Move = 0xFF0000FF
}

---@param h number
---@param s number
---@param v number
---@param a number
colors.HSV = function(h, s, v, a)
    local r, g, b = r.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

colors.HSV_Change = function(InClr, H, S, V, A)
    local R, g, b, a = r.ImGui_ColorConvertU32ToDouble4(InClr)

    local h, s, v = r.ImGui_ColorConvertRGBtoHSV(R, g, b)
    local h, s, v, a = (H or 0) + h, s + (S or 0), v + (V or 0), a + (A or 0)
    local R, g, b = r.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return r.ImGui_ColorConvertDouble4ToU32(R, g, b, a)
end

colors.BlendColors = function(Clr1, Clr2, pos)
    local R1, G1, B1, A1 = r.ImGui_ColorConvertU32ToDouble4(Clr1)

    local R2, G2, B2, A2 = r.ImGui_ColorConvertU32ToDouble4(Clr2)

    local R3 = math_helpers.SetMinMax((R2 - R1) * pos + R1, 0, 1)
    local G3 = math_helpers.SetMinMax((G2 - G1) * pos + G1, 0, 1)
    local B3 = math_helpers.SetMinMax((B2 - B1) * pos + B1, 0, 1)
    local A3 = math_helpers.SetMinMax((A2 - A1) * pos + A1, 0, 1)

    return r.ImGui_ColorConvertDouble4ToU32(R3, G3, B3, A3)
end

return colors
