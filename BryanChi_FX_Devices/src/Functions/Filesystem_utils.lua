-- @noindex
r = reaper

---@param old_path string
---@param new_path string
---@return boolean
function CopyFile(old_path, new_path)
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
function CopyImageFile(filename, subfolder)
  if filename then
    local UserOS = r.GetOS()
    local slash = '%\\'
    if UserOS == "OSX32" or UserOS == "OSX64" or UserOS == "macOS-arm64" then
      slash = '/'
    end
    local index = filename:match('^.*()' .. slash)
    local SUBFOLDER = subfolder or ''
    local NewFileName = r.GetResourcePath() ..
        '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Images/' .. SUBFOLDER .. filename:sub(index)
    local relativePath = '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Images/' ..
        SUBFOLDER .. filename:sub(index)
    local Files = scandir('/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Images/' .. SUBFOLDER)
    if FindExactStringInTable(Files, NewFileName) then
      return NewFileName, relativePath
    else
      CopyFile(filename, NewFileName)
      return NewFileName, relativePath
    end
  end
end

---@param fp string file path
---@return string
function GetFileContext(fp)
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
