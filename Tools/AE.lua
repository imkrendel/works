--[[ Acessoary Editor v1.0.1 | by S7 softworks | https://github.com/misterlerp/s7nc.softworks | License: S7M 1.0 ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

if CoreGui:FindFirstChild("AccessoryEditor") then
    CoreGui:FindFirstChild("AccessoryEditor"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AccessoryEditor"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = CoreGui

local selectedAccessory = nil
local accessories = {}
local selectionBox = nil
local isVisible = true


local Colors = {
    BG        = Color3.fromRGB(28, 28, 32),
    BGLight   = Color3.fromRGB(36, 36, 42),
    BGItem    = Color3.fromRGB(44, 44, 52),
    Selected  = Color3.fromRGB(88, 86, 214),
    SelLight  = Color3.fromRGB(110, 108, 240),
    Border    = Color3.fromRGB(60, 60, 72),
    Text      = Color3.fromRGB(220, 220, 230),
    SubText   = Color3.fromRGB(140, 140, 160),
    Header    = Color3.fromRGB(200, 200, 220),
    Red       = Color3.fromRGB(220, 60, 60),
    Input     = Color3.fromRGB(22, 22, 28),
}

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
end

local function stroke(parent, thickness, color, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Color = color or Colors.Border
    s.Transparency = transparency or 0
    s.Parent = parent
end

local function label(parent, text, size, color, bold, pos, asize, zindex)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or Colors.Text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.BackgroundTransparency = 1
    l.Position = pos or UDim2.new(0, 0, 0, 0)
    l.Size = asize or UDim2.new(1, 0, 1, 0)
    l.TextXAlignment = Enum.TextXAlignment.Left
    if zindex then l.ZIndex = zindex end
    l.Parent = parent
    return l
end

local function input(parent, placeholder, pos, size)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Colors.Input
    frame.Position = pos
    frame.Size = size
    frame.Parent = parent
    corner(frame, 5)
    stroke(frame, 1, Colors.Border)

    local box = Instance.new("TextBox")
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = Colors.SubText
    box.Text = ""
    box.TextColor3 = Colors.Text
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.BackgroundTransparency = 1
    box.Position = UDim2.new(0, 6, 0, 0)
    box.Size = UDim2.new(1, -12, 1, 0)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = frame
    return frame, box
end

local function button(parent, text, pos, size, color)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = color or Colors.BGItem
    btn.Position = pos
    btn.Size = size
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 5)
    stroke(btn, 1, Colors.Border)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color and color:Lerp(Color3.new(1,1,1), 0.1) or Colors.Selected}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color or Colors.BGItem}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(size.X.Scale, size.X.Offset - 2, size.Y.Scale, size.Y.Offset - 2), Position = UDim2.new(pos.X.Scale, pos.X.Offset + 1, pos.Y.Scale, pos.Y.Offset + 1)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = size, Position = pos}):Play()
    end)
    return btn
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Colors.BG
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -270)
MainFrame.Size = UDim2.new(0, 300, 0, 0)
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
corner(MainFrame, 10)
stroke(MainFrame, 1.5, Colors.Border)

local shadow = Instance.new("ImageLabel")
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = -1
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.BackgroundColor3 = Colors.BGLight
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.Parent = MainFrame
corner(TitleBar, 10)

local TitleFix = Instance.new("Frame")
TitleFix.BackgroundColor3 = Colors.BGLight
TitleFix.Position = UDim2.new(0, 0, 0, 26)
TitleFix.Size = UDim2.new(1, 0, 0, 10)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local titleDot = Instance.new("Frame")
titleDot.BackgroundColor3 = Colors.Selected
titleDot.Position = UDim2.new(0, 12, 0.5, -4)
titleDot.Size = UDim2.new(0, 8, 0, 8)
titleDot.Parent = TitleBar
corner(titleDot, 4)

local titleLabel = label(TitleBar, "Accessory Editor  v1.0.1", 13, Colors.Header, true, UDim2.new(0, 28, 0, 0), UDim2.new(1, -60, 1, 0))

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -11)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
corner(CloseBtn, 5)

local Content = Instance.new("Frame")
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 36)
Content.Size = UDim2.new(1, 0, 0, 498)
Content.Parent = MainFrame

local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local ExplorerLabel = label(Content, "Explorer", 11, Colors.SubText, true, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 20))
ExplorerLabel.TextXAlignment = Enum.TextXAlignment.Center

local ExplorerFrame = Instance.new("ScrollingFrame")
ExplorerFrame.BackgroundColor3 = Colors.BGLight
ExplorerFrame.Position = UDim2.new(0, 8, 0, 28)
ExplorerFrame.Size = UDim2.new(1, -16, 0, 130)
ExplorerFrame.ScrollBarThickness = 3
ExplorerFrame.ScrollBarImageColor3 = Colors.Selected
ExplorerFrame.BorderSizePixel = 0
ExplorerFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ExplorerFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ExplorerFrame.Parent = Content
corner(ExplorerFrame, 7)
stroke(ExplorerFrame, 1, Colors.Border)

local ExplorerLayout = Instance.new("UIListLayout")
ExplorerLayout.SortOrder = Enum.SortOrder.LayoutOrder
ExplorerLayout.Padding = UDim.new(0, 2)
ExplorerLayout.Parent = ExplorerFrame

local ExplorerPad = Instance.new("UIPadding")
ExplorerPad.PaddingTop = UDim.new(0, 4)
ExplorerPad.PaddingBottom = UDim.new(0, 4)
ExplorerPad.PaddingLeft = UDim.new(0, 4)
ExplorerPad.PaddingRight = UDim.new(0, 4)
ExplorerPad.Parent = ExplorerFrame

local SepLine = Instance.new("Frame")
SepLine.BackgroundColor3 = Colors.Border
SepLine.Position = UDim2.new(0, 8, 0, 166)
SepLine.Size = UDim2.new(1, -16, 0, 1)
SepLine.BorderSizePixel = 0
SepLine.Parent = Content

local PropertiesLabel = label(Content, "Properties", 11, Colors.SubText, true, UDim2.new(0, 0, 0, 172), UDim2.new(1, 0, 0, 20))
PropertiesLabel.TextXAlignment = Enum.TextXAlignment.Center

local function propRow(parent, labelTxt, yPos)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Position = UDim2.new(0, 8, 0, yPos)
    row.Size = UDim2.new(1, -16, 0, 28)
    row.Parent = parent

    local lbl = label(row, labelTxt, 12, Colors.Text, false, UDim2.new(0, 0, 0, 0), UDim2.new(0.45, 0, 1, 0))
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local _, box = input(row, "—", UDim2.new(0.48, 0, 0.1, 0), UDim2.new(0.52, 0, 0.8, 0))
    return row, box
end

local _, ScaleBox    = propRow(Content, "Scale",    196)
local _, PositionBox = propRow(Content, "Position", 228)
local _, RotationBox = propRow(Content, "Rotation", 260)
local _, NameBox     = propRow(Content, "Name",     292)
local _, TextureBox  = propRow(Content, "Texture",  324)

local DeleteBtn = button(Content, "Delete Selected", UDim2.new(0, 8, 0, 360), UDim2.new(1, -16, 0, 26), Color3.fromRGB(100, 30, 30))
DeleteBtn.TextColor3 = Color3.fromRGB(255, 120, 120)

local SepLine2 = Instance.new("Frame")
SepLine2.BackgroundColor3 = Colors.Border
SepLine2.Position = UDim2.new(0, 8, 0, 394)
SepLine2.Size = UDim2.new(1, -16, 0, 1)
SepLine2.BorderSizePixel = 0
SepLine2.Parent = Content

local CreateLabel = label(Content, "Create Accessory", 11, Colors.SubText, true, UDim2.new(0, 0, 0, 400), UDim2.new(1, 0, 0, 20))
CreateLabel.TextXAlignment = Enum.TextXAlignment.Center

local _, MeshIDBox     = propRow(Content, "MeshID",  424)
local _, TextureNewBox = propRow(Content, "Texture", 456)
local _, PartBox       = propRow(Content, "Part",    488)

local CreateBtn = button(Content, "✦  Create Accessory", UDim2.new(0, 8, 0, 522), UDim2.new(1, -16, 0, 28), Colors.Selected)
CreateBtn.TextSize = 13

local FULL_HEIGHT = 594

local function openAnimation()
    MainFrame.Size = UDim2.new(0, 300, 0, 36)
    MainFrame.ClipsDescendants = true
    Content.Visible = false

    task.wait(0.12)
    Content.Visible = true

    TweenService:Create(MainFrame, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, FULL_HEIGHT)
    }):Play()
end

openAnimation()

local function hideWindow()
    isVisible = false
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 300, 0, 36)
    }):Play()
    task.delay(0.25, function() Content.Visible = false end)
end

local function showWindow()
    isVisible = true
    Content.Visible = true
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 300, 0, FULL_HEIGHT)
    }):Play()
end

CloseBtn.MouseButton1Click:Connect(hideWindow)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F5 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if isVisible then hideWindow() else showWindow() end
    end
end)

local function clearSelectionBox()
    if selectionBox then
        selectionBox:Destroy()
        selectionBox = nil
    end
end

local function createSelectionBox(accessory)
    clearSelectionBox()
    if not accessory then return end
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end

    selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = handle
    selectionBox.Color3 = Colors.SelLight
    selectionBox.LineThickness = 0.04
    selectionBox.SurfaceTransparency = 0.85
    selectionBox.SurfaceColor3 = Colors.Selected
    selectionBox.Parent = CoreGui
end

local function getWeldTarget(handle)
    local wc = handle:FindFirstChildOfClass("WeldConstraint")
    if wc then
        local t = (wc.Part0 ~= handle) and wc.Part0 or wc.Part1
        if t and t ~= handle then return t, wc, "WeldConstraint" end
    end
    local w = handle:FindFirstChildOfClass("Weld")
    if w then
        local t = (w.Part0 ~= handle) and w.Part0 or w.Part1
        if t and t ~= handle then return t, w, "Weld" end
    end
end

local function getHandleOffset(accessory)
    if not accessory then return Vector3.new(0,0,0) end
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return Vector3.new(0,0,0) end
    local target, weld, wtype = getWeldTarget(handle)
    if weld and wtype == "Weld" then
        return weld.C1.Position
    end

    if target then
        return target.CFrame:ToObjectSpace(handle.CFrame).Position
    end
    return Vector3.new(0,0,0)
end

local function getHandleRotation(accessory)
    if not accessory then return Vector3.new(0,0,0) end
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return Vector3.new(0,0,0) end
    local target, weld, wtype = getWeldTarget(handle)
    local localCF
    if weld and wtype == "Weld" then
        localCF = weld.C1
    elseif target then
        localCF = target.CFrame:ToObjectSpace(handle.CFrame)
    else
        localCF = CFrame.new()
    end
    local rx, ry, rz = localCF:ToEulerAnglesXYZ()
    return Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
end

local explorerItems = {}

local function clearExplorer()
    for _, item in pairs(explorerItems) do
        item:Destroy()
    end
    explorerItems = {}
end

local function selectAccessory(accessory, itemFrame)
    for _, item in pairs(explorerItems) do
        TweenService:Create(item, TweenInfo.new(0.15), {BackgroundColor3 = Colors.BGItem}):Play()
        if item:FindFirstChild("Indicator") then
            item.Indicator.BackgroundTransparency = 1
        end
    end
    selectedAccessory = accessory
    createSelectionBox(accessory)
    if itemFrame then
        TweenService:Create(itemFrame, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Selected}):Play()
        if itemFrame:FindFirstChild("Indicator") then
            itemFrame.Indicator.BackgroundTransparency = 0
        end
    end
    if accessory then
        NameBox.Text = accessory.Name
        local handle = accessory:FindFirstChild("Handle")
        if handle then
            local offset = getHandleOffset(accessory)
            PositionBox.Text = string.format("%.2f, %.2f, %.2f", offset.X, offset.Y, offset.Z)
            local rot = getHandleRotation(accessory)
            RotationBox.Text = string.format("%.1f, %.1f, %.1f", rot.X, rot.Y, rot.Z)
            ScaleBox.Text = "1, 1, 1"
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                ScaleBox.Text = string.format("%.1f, %.1f, %.1f", mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z)
                TextureBox.Text = mesh.TextureId ~= "" and mesh.TextureId or "—"
            end
        end
    else
        NameBox.Text = ""
        PositionBox.Text = ""
        RotationBox.Text = ""
        ScaleBox.Text = ""
        TextureBox.Text = ""
    end
end

local function deselectAll()
    selectedAccessory = nil
    clearSelectionBox()
    for _, item in pairs(explorerItems) do
        TweenService:Create(item, TweenInfo.new(0.15), {BackgroundColor3 = Colors.BGItem}):Play()
        if item:FindFirstChild("Indicator") then
            item.Indicator.BackgroundTransparency = 1
        end
    end
    NameBox.Text = ""
    PositionBox.Text = ""
    RotationBox.Text = ""
    ScaleBox.Text = ""
    TextureBox.Text = ""
end

local function buildExplorer()
    clearExplorer()
    accessories = {}

    if not Character then return end
    for _, child in pairs(Character:GetChildren()) do
        if child:IsA("Accessory") then
            table.insert(accessories, child)
        end
    end

    for i, acc in ipairs(accessories) do
        local item = Instance.new("TextButton")
        item.BackgroundColor3 = (selectedAccessory == acc) and Colors.Selected or Colors.BGItem
        item.Size = UDim2.new(1, 0, 0, 28)
        item.Text = ""
        item.AutoButtonColor = false
        item.Parent = ExplorerFrame
        corner(item, 5)
        table.insert(explorerItems, item)

        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.BackgroundColor3 = Colors.SelLight
        indicator.Position = UDim2.new(0, 0, 0.1, 0)
        indicator.Size = UDim2.new(0, 3, 0.8, 0)
        indicator.BackgroundTransparency = (selectedAccessory == acc) and 0 or 1
        indicator.Parent = item
        corner(indicator, 2)

        local icon = Instance.new("ImageLabel")
        icon.Image = "rbxassetid://7547377738"
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(0, 8, 0.5, -8)
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.ImageColor3 = Colors.SelLight
        icon.Parent = item

        label(item, acc.Name, 12, Colors.Text, false, UDim2.new(0, 30, 0, 0), UDim2.new(1, -35, 1, 0))
        item.MouseButton1Click:Connect(function()
            if selectedAccessory == acc then
                deselectAll()
            else
                selectAccessory(acc, item)
            end
        end)

        item.MouseEnter:Connect(function()
            if selectedAccessory ~= acc then
                TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Colors.BGItem:Lerp(Colors.Selected, 0.25)}):Play()
            end
        end)
        item.MouseLeave:Connect(function()
            if selectedAccessory ~= acc then
                TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Colors.BGItem}):Play()
            end
        end)
    end
end

ExplorerFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        task.delay(0.01, function()
            local pos = UserInputService:GetMouseLocation()
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if selectedAccessory and selectedAccessory.Parent then
        local handle = selectedAccessory:FindFirstChild("Handle")
        if handle then
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                if not ScaleBox:IsFocused() then
                    ScaleBox.Text = string.format("%.2f, %.2f, %.2f", mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z)
                end
            end
        end
    end
end)

TextureBox.FocusLost:Connect(function()
    if not selectedAccessory then return end
    local handle = selectedAccessory:FindFirstChild("Handle")
    if not handle then return end
    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if not mesh then return end

    local val = TextureBox.Text
    if not val:match("^rbx") and not val:match("^http") and val ~= "" and val ~= "—" then
        local ok, result = pcall(function()
            return getcustomasset and getcustomasset(val) or val
        end)
        mesh.TextureId = ok and result or val
    else
        mesh.TextureId = val
    end
end)

PositionBox.FocusLost:Connect(function()
    if not selectedAccessory then return end
    local handle = selectedAccessory:FindFirstChild("Handle")
    if not handle then return end
    local nums = {}
    for n in PositionBox.Text:gmatch("[%-%.%d]+") do table.insert(nums, tonumber(n)) end
    if #nums < 3 then return end
    local target, weld, wtype = getWeldTarget(handle)
    if weld and wtype == "Weld" then
        local rotOnly = weld.C1 - weld.C1.Position
        weld.C1 = CFrame.new(nums[1], nums[2], nums[3]) * rotOnly
    end
end)

ScaleBox.FocusLost:Connect(function()
    if not selectedAccessory then return end
    local handle = selectedAccessory:FindFirstChild("Handle")
    if not handle then return end
    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if not mesh then return end
    local nums = {}
    for n in ScaleBox.Text:gmatch("[%-%.%d]+") do table.insert(nums, tonumber(n)) end
    if #nums == 1 then
        mesh.Scale = Vector3.new(nums[1], nums[1], nums[1])
    elseif #nums >= 3 then
        mesh.Scale = Vector3.new(nums[1], nums[2], nums[3])
    end
end)

RotationBox.FocusLost:Connect(function()
    if not selectedAccessory then return end
    local handle = selectedAccessory:FindFirstChild("Handle")
    if not handle then return end
    local nums = {}
    for n in RotationBox.Text:gmatch("[%-%.%d]+") do table.insert(nums, tonumber(n)) end
    if #nums < 3 then return end
    local rx, ry, rz = math.rad(nums[1]), math.rad(nums[2]), math.rad(nums[3])
    local target, weld, wtype = getWeldTarget(handle)
    if weld and wtype == "Weld" then
        weld.C1 = CFrame.new(weld.C1.Position) * CFrame.fromEulerAnglesXYZ(rx, ry, rz)
    end
end)

NameBox.FocusLost:Connect(function()
    if selectedAccessory and NameBox.Text ~= "" then
        selectedAccessory.Name = NameBox.Text
        buildExplorer()
    end
end)

local function deleteSelected()
    if not selectedAccessory then return end
    selectedAccessory:Destroy()
    selectedAccessory = nil
    clearSelectionBox()
    buildExplorer()
    NameBox.Text = "" 
    PositionBox.Text = "" 
    RotationBox.Text = "" 
    ScaleBox.Text = "" 
    TextureBox.Text = ""
end

DeleteBtn.MouseButton1Click:Connect(deleteSelected)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Delete then
        local focused = UserInputService:GetFocusedTextBox()
        if not focused then
            deleteSelected()
        end
    end
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local pos = UserInputService:GetMouseLocation()
    local mfPos = MainFrame.AbsolutePosition
    local mfSize = MainFrame.AbsoluteSize
    local inWindow = pos.X >= mfPos.X and pos.X <= mfPos.X + mfSize.X
        and pos.Y >= mfPos.Y and pos.Y <= mfPos.Y + mfSize.Y
    if not inWindow then
        deselectAll()
    end
end)

local function parseVec3(str, default)
    default = default or Vector3.new(1, 1, 1)
    local parts = {}
    for n in str:gmatch("[%-%.%d]+") do
        table.insert(parts, tonumber(n))
    end
    if #parts >= 3 then
        return Vector3.new(parts[1], parts[2], parts[3])
    end
    return default
end

local function resolvePartByName(name)
    if not Character then return nil end
    name = name:lower():gsub("%s", "")
    local map = {
        head = "Head",
        leftarm = "Left Arm", lefthand = "Left Arm",
        rightarm = "Right Arm", righthand = "Right Arm",
        leftleg = "Left Leg", rightleg = "Right Leg",
        torso = "Torso", uppretorso = "UpperTorso", lowertorso = "LowerTorso",
    }
    local mapped = map[name] or name
    return Character:FindFirstChild(mapped)
end

CreateBtn.MouseButton1Click:Connect(function()
    local meshID = MeshIDBox.Text
    local textureID = TextureNewBox.Text
    local partName = PartBox.Text

    if meshID == "" then return end

    local part = resolvePartByName(partName ~= "" and partName or "Head")
    if not part then
        part = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChildOfClass("BasePart")
    end

    local acc = Instance.new("Accessory")
    acc.Name = "CustomAccessory"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = acc

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = meshID:match("^rbx") and meshID or ("rbxassetid://" .. (meshID:match("%d+") or meshID))

    if textureID ~= "" then
        if not textureID:match("^rbx") and not textureID:match("^http") then
            local ok, result = pcall(function()
                return getcustomasset and getcustomasset(textureID) or textureID
            end)
            mesh.TextureId = ok and result or textureID
        else
            mesh.TextureId = textureID
        end
    end

    mesh.Scale = Vector3.new(1, 1, 1)
    mesh.Parent = handle

    local weld = Instance.new("Weld")
    weld.Part0 = handle
    weld.Part1 = part
    weld.C0 = CFrame.new(0, 0, 0)
    weld.C1 = CFrame.new(0, 0, 0)
    weld.Parent = handle

    handle.CFrame = part.CFrame

    acc.Parent = Character

    task.wait(0.05)
    buildExplorer()
    selectAccessory(acc)

    MeshIDBox.Text = ""
    TextureNewBox.Text = ""
    PartBox.Text = ""
end)

local function onCharacter(char)
    Character = char
    selectedAccessory = nil
    clearSelectionBox()
    buildExplorer()

    char.ChildAdded:Connect(function(child)
        if child:IsA("Accessory") then
            task.wait(0.1)
            buildExplorer()
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Accessory") then
            if selectedAccessory == child then
                selectedAccessory = nil
                clearSelectionBox()
            end
            buildExplorer()
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacter)

if Character then
    onCharacter(Character)
end

print("[AE] Loaded. CTRL+F5 to toggle.")
