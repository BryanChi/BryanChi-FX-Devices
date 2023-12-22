local function ThirdPartyDeps()
    local ultraschall_path = reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua"
    local readrum_machine = reaper.GetResourcePath() ..
        "/Scripts/Suzuki Scripts/ReaDrum Machine/Suzuki_ReaDrum_Machine_Instruments_Rack.lua"

    local version = tonumber(string.sub(reaper.GetAppVersion(), 0, 4))
    --reaper.ShowConsoleMsg((version))

    local fx_browser_path
    local n, arch = reaper.GetAppVersion():match("(.+)/(.+)")
    local fx_browser_v6_path

    if n:match("^7%.") then
        fx_browser = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"
        fx_browser_reapack = 'sexan fx browser parser v7'
    else
        fx_browser = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
        fx_browser_v6_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
        fx_browser_reapack = 'sexan fx browser parser v6'
    end
    --local fx_browser_v6_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_Parser.lua"
    --local fx_browser_v7_path = reaper.GetResourcePath() .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"

    local reapack_process
    local repos = {
        { name = "Sexan_Scripts",   url = 'https://github.com/GoranKovac/ReaScripts/raw/master/index.xml' },
        { name = "Ultraschall-API", url = 'https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/raw/master/ultraschall_api_index.xml' },
        { name = "Suzuki Scripts",  url = 'https://github.com/Suzuki-Re/Suzuki-Scripts/raw/master/index.xml' },
    }

    for i = 1, #repos do
        local retinfo, url, enabled, autoInstall = reaper.ReaPack_GetRepositoryInfo(repos[i].name)
        if not retinfo then
            retval, error = reaper.ReaPack_AddSetRepository(repos[i].name, repos[i].url, true, 0)
            reapack_process = true
        end
    end

    -- ADD NEEDED REPOSITORIES
    if reapack_process then
        reaper.ShowMessageBox("Added Third-Party ReaPack Repositories", "ADDING REPACK REPOSITORIES", 0)
        reaper.ReaPack_ProcessQueue(true)
        reapack_process = nil
    end

    if not reapack_process then
        -- ULTRASCHALL
        if reaper.file_exists(ultraschall_path) then
            dofile(ultraschall_path)
        else
            reaper.ShowMessageBox("Ultraschall API is needed.\nPlease Install it in next window", "MISSING DEPENDENCIES",
                0)
            reaper.ReaPack_BrowsePackages('ultraschall')
            return 'error ultraschall'
        end
        -- FX BROWSER
        if reaper.file_exists(fx_browser) then
            dofile(fx_browser)
        else
            reaper.ShowMessageBox("Sexan FX BROWSER is needed.\nPlease Install it in next window", "MISSING DEPENDENCIES",
                0)
            reaper.ReaPack_BrowsePackages(fx_browser_reapack)
            return 'error Sexan FX BROWSER'
        end
        -- ReaDrum Machine
        if reaper.file_exists(readrum_machine) then
            local found_readrum_machine = true
        else
            reaper.ShowMessageBox("ReaDrum Machine is needed.\nPlease Install it in next window", "MISSING DEPENDENCIES",
                0)
            reaper.ReaPack_BrowsePackages('readrum machine')
            return 'error Suzuki ReaDrum Machine'
        end
    end
    return nil
end

return ThirdPartyDeps
