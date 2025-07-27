local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- Simple GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoteScanner"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.Text = "🔍 RemoteEvent Scanner"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- Scan Button
local ScanButton = Instance.new("TextButton")
ScanButton.Size = UDim2.new(0, 100, 0, 30)
ScanButton.Position = UDim2.new(0, 10, 0, 40)
ScanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ScanButton.Text = "🔍 SCAN"
ScanButton.TextColor3 = Color3.new(1, 1, 1)
ScanButton.Font = Enum.Font.GothamBold
ScanButton.TextSize = 12
ScanButton.BorderSizePixel = 0
ScanButton.Parent = Frame

local ScanCorner = Instance.new("UICorner")
ScanCorner.CornerRadius = UDim.new(0, 6)
ScanCorner.Parent = ScanButton

-- Results List
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -80)
ScrollFrame.Position = UDim2.new(0, 10, 0, 70)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = Frame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = ScrollFrame

-- Clear Results Function
local function clearResults()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

-- Add Result Function
local function addResult(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceCode
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = ScrollFrame
    
    -- Position labels
    local yPos = 0
    for i, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child ~= label then
            yPos = yPos + 20
        end
    end
    label.Position = UDim2.new(0, 5, 0, yPos)
    
    -- Update canvas size
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#ScrollFrame:GetChildren()) * 20)
end

-- Scanner Function
local function scanRemoteEvents()
    clearResults()
    addResult("🔍 Scanning for RemoteEvents...", Color3.fromRGB(100, 200, 255))
    
    local count = 0
    
    -- Scan ReplicatedStorage first (most common location)
    if game:FindFirstChild("ReplicatedStorage") then
        addResult("📁 Checking ReplicatedStorage...", Color3.fromRGB(200, 200, 100))
        for _, obj in pairs(game.ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                count = count + 1
                addResult("  📡 " .. obj.Name .. " - " .. obj:GetFullName(), Color3.fromRGB(0, 255, 100))
            end
        end
    end
    
    -- Scan entire game (slower)
    addResult("📁 Checking entire game...", Color3.fromRGB(200, 200, 100))
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") and not obj:IsDescendantOf(game.ReplicatedStorage) then
            count = count + 1
            addResult("  📡 " .. obj.Name .. " - " .. obj:GetFullName(), Color3.fromRGB(255, 200, 0))
        end
    end
    
    addResult("✅ Scan complete! Found " .. count .. " RemoteEvents", Color3.fromRGB(0, 255, 0))
    
    if count == 0 then
        addResult("❌ No RemoteEvents found. Try a different game!", Color3.fromRGB(255, 100, 100))
    end
end

-- Button Click
ScanButton.MouseButton1Click:Connect(function()
    print("Scanning RemoteEvents...")
    scanRemoteEvents()
end)

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -25, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.BorderSizePixel = 0
CloseButton.Parent = Title

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Toggle with hotkey
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if ScreenGui.Parent then
            ScreenGui:Destroy()
        else
            -- Recreate if destroyed
            print("RemoteEvent Scanner destroyed, run script again to recreate")
        end
    end
end)

-- Make draggable
local dragging = false
local dragStart = nil
local startPos = nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Title.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

print("Simple RemoteEvent Scanner loaded!")
print("Press INSERT to close")
print("Click SCAN button to find RemoteEvents")
