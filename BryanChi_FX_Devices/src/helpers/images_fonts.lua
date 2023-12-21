local images_fonts = {}

local script_folder = select(2, r.get_action_context()):match('^(.+)[\\//]')
script_folder       = script_folder .. '/src'
images_fonts.FontAwesome         = r.ImGui_CreateFont(script_folder .. '/IconFont1.ttf', 30)
images_fonts.FontAwesome_small   = r.ImGui_CreateFont(script_folder .. '/IconFont1.ttf', 10)

images_fonts.attachImagesAndFonts= function ()
    Img = {
        Trash  = r.ImGui_CreateImage(CurrentDirectory .. '/src/Images/trash.png'),
        Pin    = r.ImGui_CreateImage(CurrentDirectory .. '/src/Images/pin.png'),
        Pinned = r.ImGui_CreateImage(CurrentDirectory .. '/src/Images/pinned.png'),
        Copy   = r.ImGui_CreateImage(CurrentDirectory .. '/src/Images/copy.png'),
        Paste  = r.ImGui_CreateImage(CurrentDirectory .. 'src/Images/paste.png'),
        Save   = r.ImGui_CreateImage(CurrentDirectory .. '/src/Images/save.png'),
        Sine   = r.ImGui_CreateImage(CurrentDirectory .. '/src/Images/sinewave.png'),
    }
    for i = 6, 64, 1 do
        _G['Font_Andale_Mono_' .. i] = r.ImGui_CreateFont('andale mono', i)
    end

    Font_Andale_Mono_20_B = r.ImGui_CreateFont('andale mono', 20, r.ImGui_FontFlags_Bold()) -- TODO move to constants
    r.ImGui_Attach(ctx, Font_Andale_Mono_20_B)
    for i = 6, 64, 1 do
        r.ImGui_Attach(ctx, _G['Font_Andale_Mono_' .. i])
    end
    r.ImGui_Attach(ctx, images_fonts.FontAwesome)
    r.ImGui_Attach(ctx, images_fonts.FontAwesome_small)
    for i, v in pairs(Img) do
        r.ImGui_Attach(ctx, v)
    end




    for i = 6, 64, 1 do
        _G['Arial_' .. i] = r.ImGui_CreateFont('Arial', i)
        r.ImGui_Attach(ctx, _G['Arial_' .. i])
    end

    Arial = r.ImGui_CreateFont('Arial', 12) -- TODO move to constants
end

images_fonts.TrashIcon = function (size, lbl, ClrBG, ClrTint)
    local rv = r.ImGui_ImageButton(ctx, '##' .. lbl, Img.Trash, size, size, nil, nil, nil, nil, ClrBG, ClrTint) -- TODO weird but I can’t find anything in the official docs or the reaImGui repo about this function
    if r.ImGui_IsItemHovered(ctx) then
        TintClr = 0xCE1A28ff
        return rv, TintClr
    end
end


return images_fonts
