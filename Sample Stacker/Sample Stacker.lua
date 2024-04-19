r=reaper
CurrentDirectory = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] -- GET DIRECTORY FOR REQUIRE

package.path = CurrentDirectory .. "?.lua;"
require("Functions.General Functions")
require("Functions.Initial Stuff")



if ThirdPartyDeps() then return end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
ImGui = require 'imgui' '0.9'


found_dirs,  dirs_array, found_files, files_array = ultraschall.GetAllRecursiveFilesAndSubdirectories( '/Users/b/Completed Music', dir_filter,  dir_case_sensitive, file_filter,  file_case_sensitive )



for i, v in pairs(dirs_array) do 
msg(i..  '  '..v..'\n')
end 


for i, v in pairs(files_array) do 
msg(i..  '  '..v..'\n')
end 


CreateFont(ImGui)

local ctx = r.ImGui_CreateContext('Sample Stacker', r.ImGui_ConfigFlags_DockingEnable())


AttachFont(ctx, ImGui)

function SearchBar()
    ImGui.PushFont(ctx, Arial_20)
    rv, buf = r.ImGui_InputText( ctx, '##', buf)
    ImGui.PopFont(ctx)
    local rv, MatchedFiles  =  FindStringInTable(files_array, buf) 
    if rv then 
        for i, v in pairs( MatchedFiles) do 
            ImGui.Text(ctx, v)
        end

    end





end

function loop()

    local visible, open = ImGui.Begin(ctx,'Sample Stacker')

    SearchBar()


    if visible then 
        r.ImGui_End(ctx)
    end
    if open then
        r.defer(loop)
    end
end
r.defer(loop)
