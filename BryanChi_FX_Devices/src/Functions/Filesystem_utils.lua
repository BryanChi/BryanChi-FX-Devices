-- @noindex
r = reaper
local table_helpers = require("src.helpers.table_helpers")

local fs_utils = {}

---@param old_path string
---@param new_path string
---@return boolean
fs_utils.CopyFile = function(old_path, new_path)
    local old_file = io.open(old_path, "rb")
    local new_file = io.open(new_path, "wb")
    local old_file_sz, new_file_sz = 0, 0
    if not old_file or not new_file then
        return false
    end
    while true do
        local block = old_file:read(2 ^ 13)
        if not block then
            old_file_sz = old_file:seek("end")
            break
        end
        new_file:write(block)
    end
    old_file:close()
    new_file_sz = new_file:seek("end")
    new_file:close()
    return new_file_sz == old_file_sz
end

---@param filename string
---@param subfolder string
---@return string | nil
---@return string | nil
fs_utils.CopyImageFile = function(filename, subfolder)
    if filename then
        local UserOS = r.GetOS()
        local slash = '%\\'
        if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
            slash = '/'
        end
        local index = filename:match('^.*()' .. slash)
        local SUBFOLDER = subfolder or ''
        local NewFileName = r.GetResourcePath() ..
            '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/' .. SUBFOLDER .. filename:sub(index)
        local relativePath = '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/' ..
            SUBFOLDER .. filename:sub(index)
        local Files = fs_utils.scandir('/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/' .. SUBFOLDER)
        if table_helpers.FindExactStringInTable(Files, NewFileName) then
            return NewFileName, relativePath
        else
            fs_utils.CopyFile(filename, NewFileName)
            return NewFileName, relativePath
        end
    end
end

---@param fp string file path
---@return string
fs_utils.GetFileContext = function(fp)
    local str = "\n"
    -- RETURN ANY STRING JUST FOR SCRIPT NOT TO CRASH IF PATH DOES NOT EXIST
    if not fp then return str end
    local f = io.open(fp, 'r')
    if f then
        str = f:read('a')
        f:close()
    end
    return str
end

---@param directory string path to directory
---@return table
function fs_utils.scandir(directory)
    local Files = {}
    for i = 0, 999, 1 do
        local F = r.EnumerateFiles(directory, i)

        if F and F ~= '.DS_Store' then table.insert(Files, F) end

        if not F then return Files end
    end

    --return F ---TODO should this be Files instead of F ?
end

---@param str string
function fs_utils.GetFileExtension(str)
    return str:match("^.+(%..+)$")
end

function fs_utils.ConcatPath(...)
    -- Get system dependent path separator
    local sep = package.config:sub(1, 1)
    return table.concat({ ... }, sep)
end

return fs_utils
