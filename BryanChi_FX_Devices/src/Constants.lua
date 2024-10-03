r = reaper

COLLAPSED_FX_WIDTH = 27
Default_WindowBtnWidth = 180
PAR_FX_MIXER_WIN_W = 170
Tooltip= {}
JSFX={P_ORIG_V=100000 ; Velo_Mod=500000}
JSFX.Random1 = JSFX.Velo_Mod + 10000
JSFX.Random2 = JSFX.Velo_Mod + 20000
JSFX.Random3 = JSFX.Velo_Mod + 30000

JSFX.KeyTrack1 = JSFX.Velo_Mod + 40000
JSFX.KeyTrack2 = JSFX.Velo_Mod + 50000
JSFX.KeyTrack3 = JSFX.Velo_Mod + 60000

Midi_Mod_Indicator = { } 
Midi_Mods = {'Velocity', 'Random', 'Random 2' , 'Random 3', 'KeyTrack', 'KeyTrack 2', 'KeyTrack 3'}

AllAvailableKeys = {
    ['0'] = r.ImGui_Key_0(),
    ['1'] = r.ImGui_Key_1(),
    ['2'] = r.ImGui_Key_2(),
    ['3'] = r.ImGui_Key_3(),
    ['4'] = r.ImGui_Key_4(),
    ['5'] = r.ImGui_Key_5(),
    ['6'] = r.ImGui_Key_6(),
    ['7'] = r.ImGui_Key_7(),
    ['8'] = r.ImGui_Key_8(),
    ['9'] = r.ImGui_Key_9(),
    A = r.ImGui_Key_A(),
    B = r.ImGui_Key_B(),
    C = r.ImGui_Key_C(),
    D = r.ImGui_Key_D(),
    E = r.ImGui_Key_E(),
    F = r.ImGui_Key_F(),
    G = r.ImGui_Key_G(),
    H = r.ImGui_Key_H(),
    I = r.ImGui_Key_I(),
    J = r.ImGui_Key_J(),
    K = r.ImGui_Key_K(),
    L = r.ImGui_Key_L(),
    M = r.ImGui_Key_M(),
    N = r.ImGui_Key_N(),
    O = r.ImGui_Key_O(),
    P = r.ImGui_Key_P(),
    Q = r.ImGui_Key_Q(),
    R = r.ImGui_Key_R(),
    S = r.ImGui_Key_S(),
    T = r.ImGui_Key_T(),
    U = r.ImGui_Key_U(),
    V = r.ImGui_Key_V(),
    W = r.ImGui_Key_W(),
    X = r.ImGui_Key_X(),
    Y = r.ImGui_Key_Y(),
    Z = r.ImGui_Key_Z(),
    Esc = r.ImGui_Key_Escape(),
    F1 = r.ImGui_Key_F1(),
    F2 = r.ImGui_Key_F2(),
    F3 = r.ImGui_Key_F3(),
    F4 = r.ImGui_Key_F4(),
    F5 = r.ImGui_Key_F5(),
    F6 = r.ImGui_Key_F6(),
    F7 = r.ImGui_Key_F7(),
    F8 = r.ImGui_Key_F8(),
    F9 = r.ImGui_Key_F9(),
    F10 = r.ImGui_Key_F10(),
    F11 = r.ImGui_Key_F11(),
    F12 = r.ImGui_Key_F12(),
    Apostrophe = r.ImGui_Key_Apostrophe(),
    Backslash = r.ImGui_Key_Backslash(),
    Backspace = r.ImGui_Key_Backspace(),
    Comma = r.ImGui_Key_Comma(),
    Delete = r.ImGui_Key_Delete(),
    DownArrow = r.ImGui_Key_DownArrow(),
    Enter = r.ImGui_Key_Enter(),
    End = r.ImGui_Key_End(),
    Equal = r.ImGui_Key_Equal(),
    GraveAccent = r.ImGui_Key_GraveAccent(),
    Home = r.ImGui_Key_Home(),
    ScrollLock = r.ImGui_Key_ScrollLock(),
    Insert = r.ImGui_Key_Insert(),
    Minus = r.ImGui_Key_Minus(),
    LeftArrow = r.ImGui_Key_LeftArrow(),
    LeftBracket = r.ImGui_Key_LeftBracket(),
    Period = r.ImGui_Key_Period(),
    PageDown = r.ImGui_Key_PageDown(),
    PageUp = r.ImGui_Key_PageUp(),
    Pause = r.ImGui_Key_Pause(),
    RightBracket = r.ImGui_Key_RightBracket(),
    RightArrow = r.ImGui_Key_RightArrow(),
    SemiColon = r.ImGui_Key_Semicolon(),
    Slash = r.ImGui_Key_Slash(),
    Space = r.ImGui_Key_Space(),
    Tab = r.ImGui_Key_Tab(),
    UpArrow = r.ImGui_Key_UpArrow(),
    Pad0 = r.ImGui_Key_Keypad0(),
    Pad1 = r.ImGui_Key_Keypad1(),
    Pad2 = r.ImGui_Key_Keypad2(),
    Pad3 = r.ImGui_Key_Keypad3(),
    Pad4 = r.ImGui_Key_Keypad4(),
    Pad5 = r.ImGui_Key_Keypad5(),
    Pad6 = r.ImGui_Key_Keypad6(),
    Pad7 = r.ImGui_Key_Keypad7(),
    Pad8 = r.ImGui_Key_Keypad8(),
    Pad9 = r.ImGui_Key_Keypad9(),
    PadAdd = r.ImGui_Key_KeypadAdd(),
    PadDecimal = r.ImGui_Key_KeypadDecimal(),
    PadDivide = r.ImGui_Key_KeypadDivide(),
    PadEnter = r.ImGui_Key_KeypadEnter(),
    PadEqual = r.ImGui_Key_KeypadEqual(),
    PadMultiply = r.ImGui_Key_KeypadMultiply(),
    PadSubtract = r.ImGui_Key_KeypadSubtract(),
}

FX_To_Delete_At_Close = {

    'JS: FXD ReSpectrum', 'JS: FXD Gain Reduction Scope', 'JS: FXD Split to 4 channels'
}


