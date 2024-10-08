-- @noindex

function serializeTable(val, name, skipnewlines, depth)
  skipnewlines = skipnewlines or false
  depth = depth or 0
  local tmp = string.rep(" ", depth)
  if name then
    if type(name) == "number" and math.floor(name) == name then
      name = "[" .. name .. "]"
    elseif not string.match(name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
      name = string.gsub(name, "'", "\\'")
      name = "['" .. name .. "']"
    end
    tmp = tmp .. name .. " = "
  end
  if type(val) == "table" then
    tmp = tmp .. "{"
    for k, v in pairs(val) do
      tmp = tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. ","
    end
    tmp = tmp .. string.rep(" ", depth) .. "}"
  elseif type(val) == "number" then
    tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
    tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
    tmp = tmp .. (val and "true" or "false")
  else
    tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end
  return tmp
end

function tableToString(table)
  return serializeTable(table)
end

function stringToTable(str)
  local f, err = load("return " .. str)
  return f ~= nil and f() or nil
end

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
    local slash = '%\\'
    if OS == "OSX32" or OS == "OSX64" or OS == "macOS-arm64" then
      slash = '/'
    end
    local index = filename:match('^.*()' .. slash)
    local SUBFOLDER = subfolder or ''
   --[[  local NewFileName = r.GetResourcePath() ..
        '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/' .. SUBFOLDER .. filename:sub(index)
    local relativePath = '/Scripts/FX Devices/BryanChi_FX_Devices/src/Images/' .. SUBFOLDER .. filename:sub(index)
    ]]
    local dir_path = ConcatPath(CurrentDirectory , 'src', 'Images', SUBFOLDER)

    local file_path = ConcatPath(dir_path, filename:sub(index))

    r.RecursiveCreateDirectory(dir_path, 0)

    local Files = scandir(dir_path)

    local Name = filename:sub(index+1)
    if FindExactStringInTable(Files, file_path) then
      return file_path, Name
    else
      CopyFile(filename, file_path)
      return file_path, Name
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


function TruncatePath(path)

    -- Determine the path separator based on the OS
    local sep = package.config:sub(1, 1)
    -- Find the file name after the last separator
    local fileName = path:match("([^" .. sep .. "]+)$")
    return fileName
end