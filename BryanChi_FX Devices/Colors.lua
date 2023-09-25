----------- Custom Colors-------------------
CustomColors = { 'Window_BG', 'FX_Devices_Bg', 'FX_Layer_Container_BG', 'Space_Between_FXs', 'Morph_A', 'Morph_B',
  'Layer_Solo', 'Layer_Mute', 'FX_Adder_VST', 'FX_Adder_VST3', 'FX_Adder_JS', 'FX_Adder_AU' }
CustomColorsDefault = {
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
  FX_Adder_CLAP = 0xB62424FF

}

------- ==  Colors ----------

Clr = {
  SliderGrab = 0x309D89ff,
  Dvdr = {
    Active = 0x777777aa,
    In_Layer = 0x131313ff,
    outline = 0x444444ff
  }

}

CLR_BtwnFXs_Btn_Hover = 0x77777744
CLR_BtwnFXs_Btn_Active = 0x777777aa
FX_Window_Clr_When_Dragging = 0x44444433
FX_Window_Clr_Default = 0x262626ff
Btns_Hover_DefaultColor = 0x2d3b3aff

Btns_DefaultColor = 0x333333ff
Btns_ClickedColor = 0x358f8fff
BGColor_FXLayeringWindow = 0x262626ff

Macro1Color = 0xff2121ff
Macro2Color = 0xff5521ff
Macro3Color = 0xff8921ff
Macro4Color = 0xffd321ff
Macro5Color = 0xf4ff21ff
Macro6Color = 0xb9ff21ff
Macro7Color = 0x6fff21ff
Macro8Color = 0x21ff6bff

EightColors = {
  LowMidSat = {},
  LowSat = {},
  MidSat = {},
  Bright = {},
  Bright_HighSat = {},
  HighSat_MidBright = {},
  bgWhenAsgnMod = {},
  bgWhenAsgnModAct = {},
  bgWhenAsgnModHvr = {},
  LFO = {}
}

---@param h number
---@param s number
---@param v number
---@param a number
function HSV(h, s, v, a)
  local r, g, b = r.ImGui_ColorConvertHSVtoRGB(h, s, v)
  return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

for a = 1, 8, 1 do
  table.insert(EightColors.LowSat, HSV(0.08 * (a - 1), 0.25, 0.33, 0.25))
  table.insert(EightColors.LowMidSat, HSV(0.08 * (a - 1), 0.25, 0.33, 0.5))
  table.insert(EightColors.MidSat, HSV(0.08 * (a - 1), 0.5, 0.5, 0.5))
  table.insert(EightColors.Bright, HSV(0.08 * (a - 1), 1, 0.5, 0.2))
  table.insert(EightColors.Bright_HighSat, HSV(0.08 * (a - 1), 1, 1, 0.9))
  table.insert(EightColors.HighSat_MidBright, HSV(0.08 * (a - 1), 1, 0.5, 0.5))
  table.insert(EightColors.bgWhenAsgnMod, HSV(0.08 * (a - 0.7), 0.7, 0.6, 0.15))
  table.insert(EightColors.bgWhenAsgnModAct, HSV(0.08 * (a - 0.7), 0.8, 0.7, 0.9))
  table.insert(EightColors.bgWhenAsgnModHvr, HSV(0.08 * (a - 0.7), 1, 0.2, 0.5))
  table.insert(EightColors.LFO, HSV(0.08 * (a - 1), 0.7, 0.5, 1))
end



function HSV_Change(InClr, H, S, V, A)
  local R, g, b, a = r.ImGui_ColorConvertU32ToDouble4(InClr)

  local h, s, v = r.ImGui_ColorConvertRGBtoHSV(R, g, b)
  local h, s, v, a = (H or 0) + h, s + (S or 0), v + (V or 0), a + (A or 0)
  local R, g, b = r.ImGui_ColorConvertHSVtoRGB(h, s, v)
  return r.ImGui_ColorConvertDouble4ToU32(R, g, b, a)
end

function BlendColors(Clr1, Clr2, pos)
  local R1, G1, B1, A1 = r.ImGui_ColorConvertU32ToDouble4(Clr1)

  local R2, G2, B2, A2 = r.ImGui_ColorConvertU32ToDouble4(Clr2)

  local R3 = SetMinMax((R2 - R1) * pos + R1, 0, 1)
  local G3 = SetMinMax((G2 - G1) * pos + G1, 0, 1)
  local B3 = SetMinMax((B2 - B1) * pos + B1, 0, 1)
  local A3 = SetMinMax((A2 - A1) * pos + A1, 0, 1)

  return r.ImGui_ColorConvertDouble4ToU32(R3, G3, B3, A3)
end

-----end of colors--------
