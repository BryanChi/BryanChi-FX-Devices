function ThirdPartyDeps()
    local ultraschall_path = r.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua"
    local readrum_machine = r.GetResourcePath() ..
        "/Scripts/Suzuki Scripts/ReaDrum Machine/Suzuki_ReaDrum_Machine_Instruments_Rack.lua"

    local version = tonumber(string.sub(r.GetAppVersion(), 0, 4))


    local fx_browser_path
    local n, arch = r.GetAppVersion():match("(.+)/(.+)")
    local fx_browser_v6_path

    if n:match("^7%.") then
        fx_browser = r.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"
        fx_browser_reapack = '"sexan fx browser parser v7"'
    else
        fx_browser = r.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
        fx_browser_v6_path = r.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
        fx_browser_reapack = '"sexan fx browser parser v6"'
    end
    --local fx_browser_v6_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
    --local fx_browser_v7_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"

    local reapack_process
    local repos = {
        { name = "Sexan_Scripts",   url = 'https://github.com/GoranKovac/ReaScripts/raw/master/index.xml' },
        { name = "Suzuki Scripts",  url = 'https://github.com/Suzuki-Re/Suzuki-Scripts/raw/master/index.xml' },
        { name = "Ultraschall-API", url = 'https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/raw/master/ultraschall_api_index.xml' },
    }

    for i = 1, #repos do
        local retinfo, url, enabled, autoInstall = r.ReaPack_GetRepositoryInfo(repos[i].name)
        if not retinfo then
            retval, error = r.ReaPack_AddSetRepository(repos[i].name, repos[i].url, true, 0)
            reapack_process = true
        end
    end

    -- ADD NEEDED REPOSITORIES
    if reapack_process then
        r.ShowMessageBox("Added Third-Party ReaPack Repositories", "ADDING REPACK REPOSITORIES", 0)
        r.ReaPack_ProcessQueue(true)
        reapack_process = nil
    end

    if not reapack_process then
        local deps = {}
        -- FX BROWSER
        if r.file_exists(fx_browser) then
            dofile(fx_browser)
        else
            deps[#deps + 1] = fx_browser_reapack
        end
        -- js extension
        if r.APIExists("JS_ReaScriptAPI_Version") then
            local js_extension = true
        else
            deps[#deps + 1] = '"js_ReascriptAPI"'
        end
        -- ReaDrum Machine
        if r.file_exists(readrum_machine) then
            local found_readrum_machine = true
        else
            deps[#deps + 1] = '"readrum machine"'
        end
        -- ULTRASCHALL
        if r.file_exists(ultraschall_path) then
            dofile(ultraschall_path)
        else
            deps[#deps + 1] = '"ultraschall"'
        end

        if #deps ~= 0 then
            r.ShowMessageBox("Need Additional Packages.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
            r.ReaPack_BrowsePackages(table.concat(deps, " OR "))
            return true
        end
    end
end




function Default_Values()

    FX_Add_Del_WaitTime = 2
    LFO = { Win = { w = 400, h = 300 }, CtrlNodeSz = 6, NodeSz = 6, Def = { Len = 4 } }

    LFOwin = { w = 400, h = 300 }

    Default_FX_Width = 200
    GapBtwnPrmColumns = 10
    --Sequencer -----
    StepSEQ_W = 20
    StepSEQ_H = 100
    SEQ_Default_Num_of_Steps = 8
    SEQ_Default_Denom = 1
    INVISI_CLR = 0x00000000
    Knob_DefaultFontSize = 10
    LBL_DefaultFontSize = 10
    Df = { V_Sldr_W = 15, KnobRadius = 18, KnobSize = 15 * 3, Sldr_H = 3,   Sldr_W = 160, Dvdr_Width = 15, Dvdr_Hvr_W = 0 , V_Sldr_H = 160 ,
    
    }
end 

function GetVersionNum()
    local script_path = select(2, reaper.get_action_context())
    local pkg = reaper.ReaPack_GetOwner(script_path)
    local version = select(7, reaper.ReaPack_GetEntryInfo(pkg))
    reaper.ReaPack_FreeEntry(pkg)
    return version 
end


function Create_Empty_Tables()
    FXGUID = {}
    HelperMsg= { }
    -----------------------------------------
    -----FX layering
    -----------------------------------------
    Lyr = {
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

    Spltr = {}


    LE = { GridSize = 10, Sel_Items = {}, ChangeR_Bound = {} }
    ----Preset Morph--------------
    PresetMorph = { timer = 0 }

    --- FX Chain -----------------------------
    FXchain = { FxGUID = {}, wait = 0, }


    ----track--------------------------------
    Trk = {
        GUID = {},
        Prm = { FXGUID = {}, Inst = {}, AssignWhich = {}, V = {}, O_V = {}, Num = {}, WhichMcros = {} },
        FxGUID = {},
        PreFX = {}
    }

    ------------------Divider---------------
    Dvdr = { Width = {}, Clr = {}, Spc_Hover = {}, RestoreNormWidthWait = 0, RestoreNormWidthWait = {}, JustDrop = {}, }


    --------Pro C ------------------------
    ProC = { Width = 280, Pt = { R = { m = {}, M = {} }, L = { m = {}, M = {} } } }


    ------- Pro Q -------------------------
    ProQ = {}


    ------------------- Macros --------------------------
    Mc = { Val_Trk = {}, V_Out = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, Name = {} }
    Wet = { DragLbl = {}, Val = {}, P_Num = {} }
    MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8 }

    ClrPallet = {}
    Glob = {} ---@class GLOB
    Sel_Cross = {}
    ToDef = {}
    DraggingFXs = {}; DraggingFXs_Idx = {}
    LO = {}; -- layout for plugins
    VP = {} -- viewport info
    -- demo = {}
    app = {}
    enum_cache = {}
    cache = {}
    Draw = {
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
    AddFX = { Pos = {}, Name = {}, GUID = {} }
    DelFX = { Pos = {},  GUID = {}}
    MovFX = { ToPos = {}, FromPos = {}, Lbl = {}, Copy = {} , FromFxID = {}}


    ----------Parameters --------------------
    Prm = {
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

    -----------------------------------------
    -----Param Modulations
    -----------------------------------------
    PM = { Ins = {}, FXGUID = {}, Corres_Glob_ID = {}, HasMod = {}, Final_V = {}, DIY_TrkID = {} }

end

function PluginScripts()


    PluginScript = {} ---@class PluginScript
    ----- Get plugin scripts path -------
    pluginScriptPath = CurrentDirectory .. 'src/FX Layout Plugin Scripts'
    ---List of Plugin Scripts for FXD
    PluginScripts = scandir(pluginScriptPath)
    for i, v in ipairs(PluginScripts) do
        if not v:find('.lua') then
            PluginScripts[i] = nil
        else
            PluginScripts[i] = v:sub(0, v:find('.lua') - 1)
        end
    end

end

function Customizable_Colors()
        ----------- Custom Colors-------------------
    --[[ CustomColors = { 'Window_BG', 'FX_Devices_Bg', 'FX_Layer_Container_BG', 'Space_Between_FXs', 'Morph_A', 'Morph_B',
    'Layer_Solo', 'Layer_Mute', 'FX_Adder_VST', 'FX_Adder_VST3', 'FX_Adder_JS', 'FX_Adder_AU', 'FX_Adder_CLAP',
    'FX_Adder_LV2',
    'PLink', 'PLink_Edge_DarkBG', 'PLink_Edge_LightBG',
    'RDM_BG', 'RDM_VTab', 'RDM_VTab_Highlight', 'RDM_VTab_Highlight_Edge', 'RDM_PadOff', 'RDM_PadOn', 'RDM_Pad_Highlight',
    'RDM_Play', 'RDM_Solo', 'RDM_Mute', 'RDM_DnDFX', 'RDM_DnD_Move', 'Container_Accent_Clr'  , 'Accent_Clr' , '', 'Track_Modulator_Section_BG'}
 ]]
    CustomColorsDefault = {
    Window_BG = 0x000000ff,
    Track_Modulator_Section_BG = 0x111111ff, 
    Track_Modulator_Individual_BG = 0x191919ff,
    Track_Modulator_Knob = 0x444444ff,
    FX_Devices_Bg = 0x151515ff,
    FX_Layer_Container_BG = 0x262626ff,
    Space_Between_FXs = 0x131313ff,
    Morph_A = 0x22222266,
    Morph_B = 0x78787877,
    Layer_Solo = 0xDADF37ff,
    Layer_Mute = 0xBE0101ff,
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
    RDM_DnD_Move = 0xFF0000FF;
    Container_Accent_Clr =  0x49CC85ff ;
    Container_Accent_Clr_Not_Focused = 0x49CC8577;
    Accent_Clr =  0x49CC85ff ;
    Accent_Clr_Not_Focused = 0x49CC8577;
    FX_Title_Clr = 0x222222ff;
    FX_Title_Clr_Outline = 0x555555ff

    
    }
    local I = 1
    CustomColors = {}
    for i, v in pairs(CustomColorsDefault) do 
        CustomColors[I] = i
        I = I + 1
    end

end 


function Colors()



    ------- ==  Colors ----------

    Clr = {
        SliderGrab = 0x309D89ff,
        Dvdr = {
            Active = 0x777777aa,
            In_Layer = 0x131313ff,
            outline = 0x444444ff
        };

        PAR_FX = { };

    }

    Clr.PAR_FX[1]= 0x999933ff





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
    MacroClrs = { 0xff2121ff, 0xff5521ff, 0xff8921ff, 0xffd321ff,0xf4ff21ff,0xb9ff21ff,0x6fff21ff,0x21ff6bff}

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

    -----end of colors--------

    Array_Macro_Colors = {
        frameBgColor          = {},
        frameBgHoveredColor   = {},
        frameBgActiveColor    = {},
        sliderGrabColor       = {},
        sliderGrabActiveColor = {}
    }


    x = 0.5

    Cont_Param_Add_Mode = false
    OffsetForMultipleMOD = 2

    Array = {}

    for a = 1, 8, 1 do
        table.insert(EightColors.LowSat, HSV(0.08 * (a - 1), 0.25, 0.33, 0.25))
        table.insert(EightColors.LowMidSat, HSV(0.08 * (a - 1), 0.25, 0.33, 0.5))
        table.insert(EightColors.MidSat, HSV(0.08 * (a - 1), 0.5, 0.5, 0.5))
        table.insert(EightColors.Bright, HSV(0.08 * (a - 1), 1, 0.5, 0.2))
        table.insert(EightColors.Bright_HighSat, HSV(0.08 * (a - 1), 1, 1, 0.9))


        table.insert(EightColors.HighSat_MidBright, HSV(0.08 * (a - 1), 1, 0.5, 0.5))
        table.insert(EightColors.bgWhenAsgnMod, HSV(0.08 * (a - 0.7), 0.7, 0.6, 0.2))
        table.insert(EightColors.bgWhenAsgnModAct, HSV(0.08 * (a - 0.7), 0.8, 0.7, 0.9))
        table.insert(EightColors.bgWhenAsgnModHvr, HSV(0.08 * (a - 0.7), 1, 0.2, 0.5))
        table.insert(EightColors.LFO, HSV(0.08 * (a - 1), 0.7, 0.5, 1))
    end


    
end 

function Tables_for_Special_FXs()


    -- FXs listed here will not have a fx window in the script UI
    BlackListFXs = { 'Macros', 'JS: Macros .+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'AU: AULowpass (Apple)', 'AU: AULowpass',
    'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope',
    'JS: FXD Saike BandSplitter', 'JS: FXD Band Joiner', 'FXD Saike BandSplitter', 'FXD Band Joiner','FXD Band Joiner', 'JS: FXD Band Joiner',
    'FXD Split to 32 Channels', 'JS: RDM MIDI Utility', 'Containr Macro', 'JS: FXD Containr Macro'
    }
    UtilityFXs = { 'Macros', 'JS: Macros /[.+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope', 'JS: FXD Band Joiner',
    'FXD Split to 32 Channels'
    }

    SpecialLayoutFXs = { 'VST: FabFilter Pro C 2 ', 'Pro Q 3', 'VST: FabFilter Pro Q 3 ', 'VST3: Pro Q 3 FabFilter',
    'VST3: Pro C 2 FabFilter', 'AU: Pro C 2 FabFilter' }
end 


function Retrieve_User_Settings()


    if r.HasExtState("FXDEVICES", "Settings") then
        stored_data = r.GetExtState("FXDEVICES", "Settings")
        if stored_data ~= nil then
            local storedTable = stringToTable(stored_data)
            if storedTable ~= nil then
                Reverse_Scroll = storedTable.reverse_scroll
                Ctrl_Scroll = storedTable.ctrl_scroll
                ProC.GR_NATIVE = storedTable.proc_gr_native
                ProQ.Analyzer = storedTable.proq_analyzer
                USE_MOD_CONTROL_POPUP =storedTable.USE_MOD_CONTROL_POPUP
                --Use_SystemFont = storedTable.use_systemfont
            end
        end
    end
end 

function Retrieve_All_Saved_Data_Of_Project()

    NumOfTotalTracks = r.CountTracks(0)
        -- Repeat for every track, at the beginning of script
    for Track_Idx = 0, NumOfTotalTracks - 1, 1 do
        local Track = r.GetTrack(0, Track_Idx)
        local TrkID = r.GetTrackGUID(Track)
        local TREE = BuildFXTree(Track)


        Trk[TrkID] = Trk[TrkID] or {}
        Trk[TrkID].Container_Id = {}

        Trk[TrkID].Mod = {}

        Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
        Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
        local AutoPrmCount = GetTrkSavedInfo('How Many Automated Prm in Modulators', Track)
        Trk[TrkID].AutoPrms = Trk[TrkID].AutoPrms or {}
        for i = 1, (AutoPrmCount or 0) + 1, 1 do
            Trk[TrkID].AutoPrms[i] = GetTrkSavedInfo('Auto Mod' .. i, Track, 'str')
        end
    -- Trk[TrkID].Container_Id    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID slot '..i , #Trk[TrkID].Container_Id , true )


        local function RC(str, type)
            if type == 'str' then
                local i= select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false))
                if i =='' then return nil else return i end 
            elseif type =='bool' then   
                local i= select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false))
                if i == 'true' then return true else return end 
            else
                return tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ' .. str, '', false)))
            end
        end


        Trk[TrkID].ShowMOD = RC('Show Modulations' , 'bool')


        for i = 1, 8, 1 do -- for every modulator
            Trk[TrkID].Mod[i] = {}
            local m = Trk[TrkID].Mod[i]

            m.ATK = RC('Macro ' .. i .. ' Atk')
            m.REL = RC('Macro ' .. i .. ' Rel')
            Trk[TrkID].SEQL[i] = RC('Macro ' .. i .. ' SEQ Length')
            Trk[TrkID].SEQ_Dnom[i] = RC('Macro ' .. i .. ' SEQ Denominator')
            m.Smooth = RC('Macro ' .. i .. ' Follower Speed')
            m.Gain = RC('Macro ' .. i .. ' Follower Gain')

            m.LFO_NodeCt = RC('Mod ' .. i .. 'Total Number of Nodes')
            m.LFO_spd = RC('Mod ' .. i .. 'LFO Speed')
            m.LFO_leng = RC('Mod ' .. i .. 'LFO Length')
            m.LFO_Legato = RC('Mod ' .. i .. 'LFO_Legato')
            m.LFO_Env_or_Loop = RC('Mod ' .. i .. 'LFO_Env_or_Loop')
            m.Rel_Type = RC('Mod ' .. i .. 'LFO_Release_Type')
            m.LowNoteFilter = RC('Mod ' .. i ..'Note Filter Low')
            m.HighNoteFilter = RC('Mod ' .. i ..'Note Filter High')

            if m.Rel_Type == 0 then
                m.Rel_Type = 'Latch'
            elseif m.Rel_Type == 1 then
                m.Rel_Type = 'Simple Release'
            elseif m.Rel_Type == 2 then
                m.Rel_Type = 'Custom Release'
            elseif m.Rel_Type == 3 then
                m.Rel_Type = 'Custom Release - No Jump'
            end

            if m.LFO_Env_or_Loop == 1 then m.LFO_Env_or_Loop = 'Envelope' else m.LFO_Env_or_Loop = nil end



            for N = 1, (m.LFO_NodeCt or 0), 1 do
                m.Node = m.Node or {}
                m.Node[N] = m.Node[N] or {}
                m.Node[N].x = RC('Mod ' .. i .. 'Node ' .. N .. ' X')


                m.Node[N].y       = RC('Mod ' .. i .. 'Node ' .. N .. ' Y')
                m.Node[N].ctrlX   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl X')

                m.Node[N].ctrlY   = RC('Mod ' .. i .. 'Node' .. N .. 'Ctrl Y')
                m.NodeNeedConvert = true
            end
            if RC('Mod ' .. i .. 'LFO_Rel_Node') then
                local ID = RC('Mod ' .. i .. 'LFO_Rel_Node')
                m.Node[ID] = m.Node[ID] or {}
                m.Node[ID].Rel = true
            end



            Trk[TrkID].Mod[i].SEQ = Trk[TrkID].Mod[i].SEQ or {}
            --Get Seq Steps
            if Trk[TrkID].SEQL[i] then
                for St = 1, Trk[TrkID].SEQL[i], 1 do
                    Trk[TrkID].Mod[i].SEQ[St] = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', '',
                            false)))
                end
            end

        end

        local FXCount = r.TrackFX_GetCount(Track)
        Trk[TrkID] = Trk[TrkID] or {}
        Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}
        Trk[TrkID].PostFX = Trk[TrkID].PostFX or {}

        RetrieveFXsSavedLayout(FXCount)

        Trk[TrkID].ModPrmInst = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ModPrmInst', '', false)))
        for CC = 1, Trk[TrkID].ModPrmInst or 0, 1 do
            _, Trk.Prm.WhichMcros[CC .. TrkID] = r.GetSetMediaTrackInfo_String(Track,
                'P_EXT: CC Linked to which Modulation' .. CC, '', false)
        end

        _, PM.DIY_TrkID[TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID)
        PM.DIY_TrkID[TrkID] = tonumber(PM.DIY_TrkID[TrkID])

        _, Trk.Prm.Inst[TrkID] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Trk Prm Count', '', false)
        Trk.Prm.Inst[TrkID] = tonumber(Trk.Prm.Inst[TrkID])

        i = 1
        ---retrieve Pre-FX mappings?
        ---store in CurTrk.PreFX
        while i do
            local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. i, '', false)
            if rv then
                Trk[TrkID].PreFX[i] = str; i = i + 1
            else
                i = nil
            end
        end

        i = 1
        ---retrieve Post-FX mappings?
        ---store in CurTrk.PostFX
        while i do
            local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PostFX ' .. i, '', false)
            if rv then
                Trk[TrkID].PostFX[i] = str; i = i + 1
            else
                i = nil
            end
        end



        if Trk[TrkID].PreFX == {} then Trk[TrkID].PreFX = nil end
        for P = 1, Trk.Prm.Inst[TrkID] or 0, 1 do
            _, Trk.Prm.Num[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track' .. TrkID .. ' P =' .. P)
            _, Trk.Prm.WhichMcros[P .. TrkID] = r.GetProjExtState(0, 'FX Devices',
                'Prm' .. P .. 'Has Which Macro Assigned, TrkID =' .. TrkID)
            if Trk.Prm.WhichMcros[P .. TrkID] == '' then Trk.Prm.WhichMcros[P .. TrkID] = nil end

            Trk.Prm.Num[P .. TrkID] = tonumber(Trk.Prm.Num[P .. TrkID])

            for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                _, Trk.Prm.FXGUID[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'P_Trk :' .. P .. 'Trk-' .. TrkID)
            end
        end 



        function Get_FX_Data (TB)
            for i, v in ipairs(TB) do 
            
                local FX_Idx = v.addr_fxid or  i - 1
                local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                local _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
                --local _, FX[FxGUID].   r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Container ID of '..FxGUID , '' , false )
                Trk[TrkID].Container_Id = Trk[TrkID].Container_Id or {}
                if not FxGUID then return end 
                
                if v.children then  -- if it's a container
                    
                    Get_FX_Data (v.children)
                    local id =  RC('Container ID of '..FxGUID)



                end 

                local function Parallel_FX_Solo_and_Mute()


                    --FX[FxGUID].Solo = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Parallel Solo ' .. FxGUID, '', false) 
                    FX[FxGUID].Solo = RC('Parallel Solo ' .. FxGUID, 'bool')
                    FX[FxGUID].Wet_V_before_solo = RC('Wet_V_before_solo ' .. FxGUID)
                    FX[FxGUID].Mute = RC('Parallel Mute ' .. FxGUID, 'bool')
                    FX[FxGUID].Wet_V_before_mute = RC('Wet_V_before_mute ' .. FxGUID)
                    --local rv, ProC_ID = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ProC_ID ' .. FxGUID, '', false)
                
                    FX[FxGUID][0] = FX[FxGUID][0] or {}
                    if FX[FxGUID].Wet_V_before_solo then 
                        FX[FxGUID][0].V = FX[FxGUID].Wet_V_before_solo 
                    elseif FX[FxGUID].Wet_V_before_mute then 
                        FX[FxGUID][0].V =  FX[FxGUID].Wet_V_before_mute
                    end 
                
                end


                Parallel_FX_Solo_and_Mute()

                FX[FxGUID] = FX[FxGUID] or {}
                FX[FxGUID].ModSlots = tonumber( select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Container Active Mod Slots '..FxGUID , '', false )))
                FX[FxGUID].MacroPageActive = StringToBool[ select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Container ID of '..FxGUID..'Macro Active' , '',false ))]



                local _, DefaultSldr_W = r.GetProjExtState(0, 'FX Devices', 'Default Slider Width for FX:' .. FxGUID)
                if DefaultSldr_W ~= '' then FX.Def_Sldr_W[FxGUID] = DefaultSldr_W end
                local _, Def_Type = r.GetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID)
                if Def_Type ~= '' then FX[FxGUID].DefType = Def_Type end


                GetProjExt_FxNameNum(FxGUID)

                _, FX.InLyr[FxGUID]          = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FxGUID .. 'in layer')
                --FX.InLyr[FxGUID] = StringToBool[FX.InLyr[FxGUID]]
                _, FX.LyrNum[FxGUID]         = r.GetProjExtState(0, 'FX Devices', 'FXLayer ' .. FxGUID .. 'LayerNum')
                _, FX[FxGUID].inWhichLyr     = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. FxGUID .. 'is in Layer ID')
                _, FX[FxGUID].ContainerTitle = r.GetProjExtState(0, 'FX Devices - ',
                    'FX' .. FxGUID .. 'FX Layer Container Title ')
                if FX[FxGUID].ContainerTitle == '' then FX[FxGUID].ContainerTitle = nil end

                FX[FxGUID].inWhichLyr = tonumber(FX[FxGUID].inWhichLyr)
                FX.LyrNum[FxGUID] = tonumber(FX.LyrNum[FxGUID])
                _, Lyr.SplitrAttachTo[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. FxGUID)
                _, Prm.InstAdded[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added')
                if Prm.InstAdded[FxGUID] == 'true' then Prm.InstAdded[FxGUID] = true end

                if FX.InLyr[FxGUID] == "" then FX.InLyr[FxGUID] = nil end
                FX[FxGUID].Morph_ID = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID, '', false)))
                _, FX[FxGUID].Unlink = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '',
                    false)
                if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

                if FX[FxGUID].Morph_ID then
                    Trk[TrkID].Morph_ID = Trk[TrkID].Morph_ID or {}
                    Trk[TrkID].Morph_ID[FX[FxGUID].Morph_ID] = FxGUID
                end

                local rv, ProC_ID = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ProC_ID ' .. FxGUID, '', false)
                if rv then FX[FxGUID].ProC_ID = tonumber(ProC_ID) end

                if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

                --for Fx_P = 1, #FX[FxGUID] or 0, 1 do
                for Fx_P in ipairs(FX[FxGUID]) do
                    local FP = FX[FxGUID][Fx_P]

                    local rv, V_before = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', '', false)
                    if rv then FP.V = tonumber(V_before) end

                    local ParamX_Value = 'Param' .. tostring(FX[FxGUID][Fx_P].Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID
                    ParamValue_At_Script_Start = r.TrackFX_GetParamNormalized(Track, FX_Idx, FX[FxGUID][Fx_P].Num or 0)
                    _G[ParamX_Value] = ParamValue_At_Script_Start
                    _, FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = r.GetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'to Trk Prm')
                    FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = tonumber(FX.Prm.ToTrkPrm[FxGUID .. Fx_P])

                    local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]

                    _G[ParamX_Value] = FX[FxGUID][Fx_P].V or 0
                    FP.WhichCC = tonumber(select(2,r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' ..(FP.Num or 0), '', false)))

                    _, FP.WhichMODs = r.GetSetMediaTrackInfo_String(Track,'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods', '', false)
                    if FP.WhichMODs == '' then FP.WhichMODs = nil end
                    FP.ModAMT = {}
                    
                    FP.Cont_Which_CC = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P ..' Container Mod CC' , '' , false)))
                    FP.Cont_ModAMT = {}
                    if FP.Cont_Which_CC then
                        local rv , parent = r.TrackFX_GetNamedConfigParm(Track, FX_Idx, 'parent_container')
                        if parent ~= '' then 
                            local parent_FxGUID =  r.TrackFX_GetFXGUID(Track, parent)
                            FX[parent_FxGUID] = FX[parent_FxGUID] or {}
                            local Ct = FX[parent_FxGUID]
                            Ct.ModPrm = Ct.ModPrm or {}
                            table.insert(Ct.ModPrm,  FxGUID.. ' , prm : '.. FP.Num)
                        end
                    end
                    local HasModAmt, HasContModAmt

                    for i, v in ipairs(Midi_Mods) do 
                        
                        FP.ModAMT[v] =  RC ('FX' .. FxGUID .. 'Prm' .. Fx_P.. ' Mod Amt for '.. v  )
                        if FP.ModAMT[v] then HasModAmt = true end 
                        local CurvePts = RC( v.. 'Curve number of points')

                        Trk[TrkID][v..'Curve']= Trk[TrkID][v..'Curve'] or {}
                        for i=1, CurvePts or 0, 1 do -- Recall curve points x ([1]) y([2]) and log or exp curve ([3])

                            Trk[TrkID][v..'Curve'][i] = Trk[TrkID][v..'Curve'][i] or {}
                            Trk[TrkID][v..'Curve'][i][1] = RC(v..' curve pt'..i..'x') 


                            Trk[TrkID][v..'Curve'][i][2] = RC(v..' curve pt'..i..'y') 
                            Trk[TrkID][v..'Curve'][i][3] = RC(v..' point '..i..' Curve')
                            if i == 1 then  -- first point 
                                if not Trk[TrkID][v..'Curve'][i][1]  then Trk[TrkID][v..'Curve'][i][1] = 0 end 
                                if not Trk[TrkID][v..'Curve'][i][2]  then Trk[TrkID][v..'Curve'][i][2] = 0 end  
                            end
                            if i == CurvePts then 
                                if not Trk[TrkID][v..'Curve'][i][1]  then Trk[TrkID][v..'Curve'][i][1] = 1 end 
                                if not Trk[TrkID][v..'Curve'][i][2]  then Trk[TrkID][v..'Curve'][i][2] = 1 end  
                            end
                        end


                    end

                    local CC = FX[FxGUID][Fx_P].WhichCC

                    for m, v in ipairs(MacroNums) do

                        FP.ModAMT[m] = tonumber(select(2,
                            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                                Fx_P .. 'Macro' .. m .. 'Mod Amt', '', false)))
                        if FP.ModAMT[m] then HasModAmt = true end



                        Trk[TrkID].Mod = Trk[TrkID].Mod or {}
                        Trk[TrkID].Mod[m] = Trk[TrkID].Mod[m] or {}
                        Trk[TrkID].Mod[m].Val = tonumber(select(2,
                            r.GetProjExtState(0, 'FX Devices', 'Macro' .. m .. 'Value of Track' .. TrkID)))

                        FP.ModBypass = RemoveEmptyStr(select(2,
                            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', '',
                                false)))

                        FP.ModBipolar = FP.ModBipolar or {}
                        FP.ModBipolar[m] = StringToBool[select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. m .. 'Mod Bipolar', '', false))]

                        FP.Cont_ModAMT[m] = tonumber(select(2,r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. m .. 'Container Mod Amt', '', false)))

                        if FP.Cont_ModAMT[m] then HasContModAmt = true end 
                    
                    
                    end


                   if not HasModAmt then FP.ModAMT = nil end
                    if not HasContModAmt then FP.Cont_ModAMT = nil end 
                end

                FX[FxGUID] = FX[FxGUID] or {}
                if r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. '1' .. FxGUID, '', false) then
                    FX[FxGUID].MorphA = FX[FxGUID].MorphA or {}
                    FX[FxGUID].MorphB = FX[FxGUID].MorphB or {}
                    FX[FxGUID].PrmList = {}
                    local PrmCount = r.TrackFX_GetNumParams(Track, FX_Idx)

                    RestoreBlacklistSettings(FxGUID, FX_Idx, Track, PrmCount)

                    for i = 0, PrmCount - 4, 1 do
                        _, FX[FxGUID].MorphA[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. i .. FxGUID, '',
                            false)
                        FX[FxGUID].MorphA[i] = tonumber(FX[FxGUID].MorphA[i])
                        _, FX[FxGUID].MorphB[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph B' .. i .. FxGUID, '',
                            false)
                        FX[FxGUID].MorphB[i] = tonumber(FX[FxGUID].MorphB[i])
                    end

                    _, FX[FxGUID].MorphA_Name = r.GetSetMediaTrackInfo_String(Track,
                        'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', '', false)
                    if FX[FxGUID].MorphA_Name == '' then FX[FxGUID].MorphA_Name = nil end
                    _, FX[FxGUID].MorphB_Name = r.GetSetMediaTrackInfo_String(Track,
                        'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', '', false)
                    if FX[FxGUID].MorphB_Name == '' then FX[FxGUID].MorphB_Name = nil end
                end


                _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
                if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
                    local FXGUIDofRackMixer = r.TrackFX_GetFXGUID(Track, FX_Idx)
                    FX[FXGUIDofRackMixer].LyrID = FX[FXGUIDofRackMixer].LyrID or {}
                    FX[FXGUIDofRackMixer].LyrTitle = FX[FXGUIDofRackMixer].LyrTitle or {}
                    FX[FXGUIDofRackMixer].ActiveLyrCount = 0

                    for i = 1, 8, 1 do
                        _, FX[FXGUIDofRackMixer].LyrID[i] = r.GetProjExtState(0, 'FX Devices',
                            'FX' .. FXGUIDofRackMixer .. 'Layer ID ' .. i)
                        _, FX[FXGUIDofRackMixer].LyrTitle[i] = r.GetProjExtState(0, 'FX Devices - ',
                            'FX' .. FXGUIDofRackMixer .. 'Layer Title ' .. i)
                        if FX[FXGUIDofRackMixer].LyrTitle[i] == '' then FX[FXGUIDofRackMixer].LyrTitle[i] = nil end
                        FX[FXGUIDofRackMixer].LyrID[i] = tonumber(FX[FXGUIDofRackMixer].LyrID[i])
                        if FX[FXGUIDofRackMixer].LyrID[i] ~= -1 and FX[FXGUIDofRackMixer].LyrID[i] then
                            FX[FXGUIDofRackMixer].ActiveLyrCount =
                                FX[FXGUIDofRackMixer].ActiveLyrCount + 1
                        end
                    end


                    _, Lyr.FX_Ins[FXGUIDofRackMixer] = r.GetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FxGUID)
                    if Lyr.FX_Ins[FXGUIDofRackMixer] == "" then Lyr.FX_Ins[FXGUIDofRackMixer] = nil end
                    Lyr.FX_Ins[FXGUIDofRackMixer] = tonumber(Lyr.FX_Ins[FXGUIDofRackMixer])
                elseif FX_Name:find('FXD Saike BandSplitter') then
                    FX[FxGUID].BandSplitID = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: BandSplitterID' .. FxGUID, '', false)))
                    _, FX[FxGUID].AttachToJoiner = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Splitter\'s Joiner FxID ' ..
                        FxGUID, '', false)

                    for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                        --Restore Band Split
                        local FxID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                        if select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which BS' .. FxID, '', false)) == FxGUID then
                            --local _, Guid_FX_In_BS = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX is in which BS'..FxID, '', false  )
                            FX[FxID] = FX[FxID] or {}
                            FX[FxID].InWhichBand = tonumber(select(2,
                                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which Band' .. FxID, '', false)))

                            FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
                            table.insert(FX[FxGUID].FXsInBS, FxID)
                        end
                    end
                end



                if Track == LT_Track and string.find(FX_Name, 'Pro%-Q 3') ~= nil then
                    _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 331)
                    ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
                    ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3.DspRange[FX_Idx])
                end

            end
        end 

        for m = 1, 8, 1 do

            Trk[TrkID].Mod[m].Type = RC('Mod' .. m .. 'Type', 'str')

        end
        Get_FX_Data (TREE)
        if not Trk[TrkID].Container_Id [1] then Trk[TrkID].Container_Id = nil end 

    end
end



function GetAllMods( )
    Mods  = im.GetKeyMods(ctx)
    
    if OS:find('OSX') then 
        Alt   = im.Mod_Alt          
        Cmd  = im.Mod_Ctrl     -- this is Command on mac, Ctrl on Windows
        Shift = im.Mod_Shift        
        Ctrl   = im.Mod_Super    -- This is Ctrl on mac, Windows Btn on windows
    else        -- if its not MacOS
        Alt   = im.Mod_Alt
        Ctrl  = im.Mod_Ctrl     -- this is Command on mac, Ctrl on Windows
        Shift = im.Mod_Shift    
        Cmd   = im.Mod_Super    --  Windows Btn on windows
    end
   
end 
function attachImagesAndFonts()

    local script_folder = select(2, r.get_action_context()):match('^(.+)[\\//]')
    script_folder       = script_folder .. '/src'
    icon1               = im.CreateFont(script_folder .. '/Fonts/IconFont1.ttf', 30)
    icon1_middle        = im.CreateFont(script_folder .. '/Fonts/IconFont1.ttf', 15)
    icon1_small         = im.CreateFont(script_folder .. '/Fonts/IconFont1.ttf', 10)
    Img = {
        Trash  = im.CreateImage(CurrentDirectory .. '/src/Images/trash.png'),
        Pin    = im.CreateImage(CurrentDirectory .. '/src/Images/pin.png'),
        Pinned = im.CreateImage(CurrentDirectory .. '/src/Images/pinned.png'),
        Copy   = im.CreateImage(CurrentDirectory .. '/src/Images/copy.png'),
        Paste  = im.CreateImage(CurrentDirectory .. '/src/Images/paste.png'),
        Save   = im.CreateImage(CurrentDirectory .. '/src/Images/save.png'),
        Sine   = im.CreateImage(CurrentDirectory .. '/src/Images/sinewave.png'),
        ModIcon = im.CreateImage(CurrentDirectory .. '/src/Images/Modulation Icon.png'),
        ModIconHollow = im.CreateImage(CurrentDirectory .. '/src/Images/Modulation Icon hollow.png'),
        MouseL = im.CreateImage(CurrentDirectory .. '/src/Images/MouseL.png'),
        MouseR = im.CreateImage(CurrentDirectory .. '/src/Images/MouseR.png'), 
        ModulationArrow = im.CreateImage(CurrentDirectory .. '/src/Images/ModulationArrow.png'),
        AddList = im.CreateImage(CurrentDirectory .. '/src/Images/add-list.png')
    }
    for i = 6, 30, 1 do
        _G['Font_Andale_Mono_' .. i] = im.CreateFont('andale mono', i)
        im.Attach(ctx, _G['Font_Andale_Mono_' .. i])
    end
    for i = 6, 30, 1 do
        _G['Arial_' .. i] = im.CreateFont('Arial', i)
        im.Attach(ctx, _G['Arial_' .. i])
    end

    System_Font = im.CreateFont('sans-serif', 14)
    im.Attach(ctx, System_Font)
    Font_Andale_Mono_20_B = im.CreateFont('andale mono', 20, im.FontFlags_Bold) -- TODO move to constants
    im.Attach(ctx, Font_Andale_Mono_20_B)

    im.Attach(ctx, icon1)
    im.Attach(ctx, icon1_middle)
    im.Attach(ctx, icon1_small)
    for i, v in pairs(Img) do
        im.Attach(ctx, v)
    end

    --[[ for i = 6, 64, 1 do
        _G['Arial_' .. i] = im.CreateFont('Arial', i)
        im.Attach(ctx, _G['Arial_' .. i])
    end ]]

    --Arial = im.CreateFont('Arial', 12) -- TODO move to constants
end



function Retrieve_Keyboard_Shortcut_Settings()
    local KB_Shortcut , Command_ID = {},{}
    if CallFile('r', 'Keyboard Shortcuts.ini') then
 
        local file, filepath = CallFile('r', 'Keyboard Shortcuts.ini')
        if not file then return end
        Content = file:read('*a')
        local L = get_lines(filepath)
        for i, v in ipairs(L) do
         
            KB_Shortcut[i] = v:sub(0, v:find(' =') - 1)
            Command_ID[i] = v:sub(v:find(' =') + 3, nil)
        end
        return KB_Shortcut, Command_ID
    end
end




function FX_State_Table()
        -----------------FX State-----------------
    FX = {
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
end 





function Retrieve_All_Info_Needed_Before_Main_Loop()
    ThirdPartyDeps()
    Default_Values()
    Create_Empty_Tables()
    Customizable_Colors()
    Retrieve_User_Settings()
    Colors()
    FX_State_Table()
    Tables_for_Special_FXs()
    Retrieve_All_Saved_Data_Of_Project()
    attachImagesAndFonts()
    PluginScripts()
    Get_Modulator_JSFX_Info()
    VersionNumber = GetVersionNum()

    FX_LIST, CAT = ReadFXFile()
    if not FX_LIST or not CAT then
        FX_LIST, CAT = MakeFXFiles()
    end


    FLT_MIN, FLT_MAX = im.NumericLimits_Float()
    NumOfTotalTracks = r.CountTracks(0)
    Sel_Track = r.GetSelectedTrack(0, 0)
    if Sel_Track  then Sel_Track_FX_Count = r.TrackFX_GetCount(Sel_Track) end
    ---------------------------------------------------------------
    -----------Retrieve Keyboard Shortcut Settings ----------------
    ---------------------------------------------------------------
    KB_Shortcut, Command_ID = Retrieve_Keyboard_Shortcut_Settings()
    KB_Shortcut = KB_Shortcut or {}
    Command_ID = Command_ID or {}

    FirstLoop = true
    FX_DeviceWindow_NoScroll = 0

    os_separator = package.config:sub(1, 1)

end 


function Get_Modulator_JSFX_Info()
    local MacrosJSFXExist = r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0--[[RecFX]], 0)
    local TrkID = r.GetTrackGUID(LT_Track)
    if MacrosJSFXExist == 0 then
        for i= 0, 7, 1 do 
            local v = r.TrackFX_GetParamNormalized(LT_Track, 0, i)
            local I = i+1
            Trk[TrkID].Mod= Trk[TrkID].Mod or {}
            Trk[TrkID].Mod[I] = Trk[TrkID].Mod[I] or {}
            Trk[TrkID].Mod[I].Val = v 
        end
    end
end 

