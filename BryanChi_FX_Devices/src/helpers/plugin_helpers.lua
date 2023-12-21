local pluginHelpers = {}

----- Get plugin scripts path -------
pluginHelpers.pluginScriptPath = CurrentDirectory .. 'src/FX Layout Plugin Scripts'

---Get plugin scripts in FXD's plugins scripts folder
local GetPluginScripts = function()
    local PluginScripts = scandir(pluginHelpers.pluginScriptPath)
    for i, v in ipairs(PluginScripts) do
        if not v:find('.lua') then
            PluginScripts[i] = nil
        else
            PluginScripts[i] = v:sub(0, v:find('.lua') - 1)
        end
    end
    return PluginScripts
end
pluginHelpers.PluginScripts = GetPluginScripts()

return pluginHelpers

