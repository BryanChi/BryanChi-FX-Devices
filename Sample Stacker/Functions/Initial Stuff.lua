function CreateFont(ImGui)

    Arial_20 = ImGui.CreateFont('Arial',20)
    Arial_21 = ImGui.CreateFont('Arial',21)
end

function AttachFont(ctx, ImGui)
    ImGui.Attach( ctx, Arial_20 )

end