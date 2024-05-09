-- @noindex

function CreateFont(ImGui)

    Arial_20 = ImGui.CreateFont('Arial',20)
    Arial_21 = ImGui.CreateFont('Arial',21)
end

function AttachFont(ctx, ImGui)
    ImGui.Attach( ctx, Arial_20 )

end
Added = {}

function GetSelectedItems_And_Add_To_Added_TB()
    local count =  r.CountSelectedMediaItems(0)
    for i= 1, count, 1 do 
        --itm = r.GetSelectedMediaItem(0, i)
        Added[i] = {}
        Added[i].it, Added[i].tk, Added[i].src = GetSelectedMediaItemInfo(i-1)
        Added[i].KeyWord = {}

    end 
end

GetSelectedItems_And_Add_To_Added_TB()


Added_Saamples_Name_Width = 400
Added_Saamples_Name_Height = 40
FirstLoop = true 


Sel_Samples = {}
File_Types_To_Show = {'wav', 'mp3', 'aiff', 'aif'}
Sel_Samples= {}
Delete_Itm = {}
