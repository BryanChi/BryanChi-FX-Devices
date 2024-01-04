---State module meant to contain FXD's state.
---For now, state is supposed to be brought into the global scope
---in the main file.
local FxdCtx = {}


---@class ViewPort
FxdCtx.VP = {} -- viewport info
-- demo = {}
FxdCtx.app = {}
FxdCtx.Enum_cache = {}
FxdCtx.Cache = {}
FxdCtx.Draw = {
    Rect = {},
    DrawMode = {},
    ItemInst = {},
    L = {},
    R = {},
    Y = {},
    T = {},
    B = {},
    FxGUID = {},
    Time = 0,
    Df_EdgeRound = {}
}
FxdCtx.AddFX = { Pos = {}, Name = {}, GUID = {} }
FxdCtx.DelFX = { Pos = {}, Name = {} }
FxdCtx.MovFX = { ToPos = {}, FromPos = {}, Lbl = {}, Copy = {} }
---layout for plugins
FxdCtx.LO = {};

FxdCtx.LFO = { Win = { w = 400, h = 300 }, CtrlNodeSz = 6, NodeSz = 6, Def = { Len = 4 } }

FxdCtx.ClrPallet = {}
FxdCtx.Glob = {} ---@class GLOB
FxdCtx.Sel_Cross = {}
FxdCtx.ToDef = {}
FxdCtx.DraggingFXs = {};
FxdCtx.DraggingFXs_Idx = {}

FxdCtx.Prm = {
    McroModAmt = {},
    McroModAmt_Norm = {},
    Pos_L = {},
    Pos_T = {},
    Pos_R = {},
    Pos_B = {},
    ModAngle = {},
    SldrGrabXPos = {},
    Val = {},
    NameS = {},
    FXGUID = {},
    InstAdded = {},
    Init_Val = {},
    Num = {},
    TrkID = {},
    Deletable = {},
    Name = {}
}

FxdCtx.PM = { Ins = {}, FXGUID = {}, Corres_Glob_ID = {}, HasMod = {}, Final_V = {}, DIY_TrkID = {} }
-----------------------------------------
-----FX layering
-----------------------------------------
FxdCtx.Lyr = {
    Selected = {},
    title = {},
    ProgBarClick = {},
    Title = {},
    ProgBarVal = {},
    SpltrID = {},
    Count = {},
    Solo = {},
    Mute = {},
    Rename = {},
    FX_Ins = {},
    ProgBarDrag = {},
    EditingTitle = {},
    LastFXPos = {},
    FrstFXPos = {},
    SplitrAttachTo = {},
    PrevFX = {},
    TitleToShow = {},
}

FxdCtx.Spltr = {}


FxdCtx.LE = { GridSize = 10, Sel_Items = {}, ChangeR_Bound = {} }
----Preset Morph--------------
FxdCtx.PresetMorph = { timer = 0 }

--- FX Chain -----------------------------
FxdCtx.FXchain = { FxGUID = {}, wait = 0, }


----track--------------------------------
FxdCtx.Trk = {
    GUID = {},
    Prm = { FXGUID = {}, Inst = {}, AssignWhich = {}, V = {}, O_V = {}, Num = {}, WhichMcros = {} },
    FxGUID = {},
    PreFX = {}
}

------------------Divider---------------
FxdCtx.Dvdr = { Width = {}, Clr = {}, Spc_Hover = {}, RestoreNormWidthWait = {}, JustDrop = {}, }

-----------------FX State-----------------
FxdCtx.FX = {
    Enable = {},
    InLyr = {},
    Width = {},
    Collapse = {},
    LyrNum = {},
    Win = {},
    Win_Name = {},
    Def_Type = {},
    Win_Name_S = {},
    TitleWidth = {},
    Sldr_W = {},
    WidthCollapse = {},
    Round = {},
    GrbRound = {},
    BgClr = {},
    Def_Sldr_W = {},
    Prm = {
        V_Round = {},
        V_FontSize = {},
        ShowCondition = {},
        ConditionPrm = {},
        ConditionPrm_V = {},
        Switch_W = {},
        Combo_W = {},
        Options = {},
        BgClrHvr = {},
        BgClrAct = {},
        Lbl_Clr = {},
        V_Clr = {},
        DragDir = {},
        Lbl_Pos = {},
        V_Pos = {},
        Style = {},
        GrbClr = {},
        BgClr = {},
        Count = {},
        Name = {},
        Num = {},
        V = {},
        InitV = {},
        AssignWhichParam = {},
        ToTrkPrm = {},
        Lbl = {},
        PosX = {},
        PosY = {},
        VertSldr = {},
        Type = {},
        CustomLbl = {},
        FontSize = {},
        Sldr_H = {}
    }
}



FxdCtx.Df = { V_Sldr_W = 15, KnobRadius = 18, KnobSize = 15 * 3, Sldr_W = 160, Dvdr_Width = 15, Dvdr_Hvr_W = 0 }


-----------ShortCut-----------

FxdCtx.KB_Shortcut = {}
FxdCtx.Command_ID = {}


--------Pro C ------------------------
FxdCtx.ProC = { Width = 280, Pt = { R = { m = {}, M = {} }, L = { m = {}, M = {} } } }









-------------------Macros --------------------------
FxdCtx.Mc = { Val_Trk = {}, V_Out = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, Name = {} }
FxdCtx.Wet = { DragLbl = {}, Val = {}, P_Num = {} }
FxdCtx.MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8 }

FxdCtx.TREE = BuildFXTree(LT_Track or reaper.GetSelectedTrack(0, 0))
FxdCtx.StringToBool = { ['true'] = true, ['false'] = false }

return FxdCtx
