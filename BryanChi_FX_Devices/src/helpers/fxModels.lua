local fxModels = {}

-- FXs listed here will not have a fx window in the script UI
fxModels.BlackListFXs = { 'Macros', 'JS: Macros .+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'AU: AULowpass (Apple)', 'AU: AULowpass',
    'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope',
    'JS: FXD Saike BandSplitter', 'JS: FXD Band Joiner', 'FXD Saike BandSplitter', 'FXD Band Joiner',
    'FXD Split to 32 Channels', 'JS: RDM MIDI Note Filter'
}
fxModels.UtilityFXs = { 'Macros', 'JS: Macros /[.+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope', 'JS: FXD Band Joiner',
    'FXD Split to 32 Channels'
}

fxModels.SpecialLayoutFXs = { 'VST: FabFilter Pro C 2 ', 'Pro Q 3', 'VST: FabFilter Pro Q 3 ', 'VST3: Pro Q 3 FabFilter',
    'VST3: Pro C 2 FabFilter', 'AU: Pro C 2 FabFilter' }



return fxModels
