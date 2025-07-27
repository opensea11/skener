-- Test Button untuk debug
local TestButton = Instance.new("TextButton")
TestButton.Size = UDim2.new(0, 80, 0, 30)
TestButton.Position = UDim2.new(0, 120, 0, 40)
TestButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
TestButton.Text = "🧪 TEST"
TestButton.TextColor3 = Color3.new(1, 1, 1)
TestButton.Font = Enum.Font.GothamBold
TestButton.TextSize = 12
TestButton.BorderSizePixel = 0
TestButton.Parent = Frame

local TestCorner = Instance.new("UICorner")
TestCorner.CornerRadius = UDim.new(0, 6)
TestCorner.Parent = TestButton

TestButton.MouseButton1Click:Connect(function()
    clearResults()
    addResult("🧪 Testing scanner functionality...", Color3.fromRGB(255, 100, 255))
    addResult("✅ GUI is working!", Color3.fromRGB(0, 255, 0))
    addResult("✅ Buttons are clickable!", Color3.fromRGB(0, 255, 0))
    addResult("Player: " .. Player.Name, Color3.fromRGB(100, 200, 255))
    addResult("Game: " .. game.Name, Color3.fromRGB(100, 200, 255))
    addResult("ReplicatedStorage exists: " .. tostring(game.ReplicatedStorage ~= nil), Color3.fromRGB(100, 200, 255))
    print("Test button clicked - GUI is functional!")
end)local Players = game:GetService("Players")
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
    addResult("🔍 Starting RemoteEvent scan...", Color3.fromRGB(100, 200, 255))
    
    local count = 0
    local scanned = {}
    
    -- Debug: Show what services we're scanning
    addResult("📁 Scanning ReplicatedStorage...", Color3.fromRGB(200, 200, 100))
    
    -- Scan ReplicatedStorage
    local success1, error1 = pcall(function()
        if game.ReplicatedStorage then
            for _, obj in pairs(game.ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") and not scanned[obj] then
                    scanned[obj] = true
                    count = count + 1
                    addResult("  📡 " .. obj.Name, Color3.fromRGB(0, 255, 100))
                    addResult("      Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
                end
            end
        end
    end)
    
    if not success1 then
        addResult("❌ Error scanning ReplicatedStorage: " .. tostring(error1), Color3.fromRGB(255, 100, 100))
    end
    
    -- Scan other common locations
    addResult("📁 Scanning Workspace...", Color3.fromRGB(200, 200, 100))
    
    local success2, error2 = pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("RemoteEvent") and not scanned[obj] then
                scanned[obj] = true
                count = count + 1
                addResult("  📡 " .. obj.Name, Color3.fromRGB(255, 200, 0))
                addResult("      Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
            end
        end
    end)
    
    if not success2 then
        addResult("❌ Error scanning Workspace: " .. tostring(error2), Color3.fromRGB(255, 100, 100))
    end
    
    -- Scan StarterGui
    addResult("📁 Scanning StarterGui...", Color3.fromRGB(200, 200, 100))
    
    local success3, error3 = pcall(function()
        if game.StarterGui then
            for _, obj in pairs(game.StarterGui:GetDescendants()) do
                if obj:IsA("RemoteEvent") and not scanned[obj] then
                    scanned[obj] = true
                    count = count + 1
                    addResult("  📡 " .. obj.Name, Color3.fromRGB(100, 150, 255))
                    addResult("      Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
                end
            end
        end
    end)
    
    if not success3 then
        addResult("❌ Error scanning StarterGui: " .. tostring(error3), Color3.fromRGB(255, 100, 100))
    end
    
    -- Final results
    addResult("", Color3.new(1, 1, 1)) -- Empty line
    addResult("✅ Scan complete! Found " .. count .. " RemoteEvents", Color3.fromRGB(0, 255, 0))
    
    if count == 0 then
        addResult("❌ No RemoteEvents found!", Color3.fromRGB(255, 100, 100))
        addResult("💡 This game might not have RemoteEvents", Color3.fromRGB(200, 200, 200))
        addResult("💡 Or they might be protected/hidden", Color3.fromRGB(200, 200, 200))
    else
        addResult("💡 You can copy these paths to use in exploits", Color3.fromRGB(200, 200, 200))
    end
end

-- Button Click with debug
ScanButton.MouseButton1Click:Connect(function()
    print("=== SCAN BUTTON CLICKED ===")
    print("Player:", Player.Name)
    print("ReplicatedStorage exists:", game.ReplicatedStorage ~= nil)
    print("Starting scan...")
    
    ScanButton.Text = "⏳ SCANNING..."
    ScanButton.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
    
    wait(0.1) -- Small delay to show button change
    
    scanRemoteEvents()
    
    ScanButton.Text = "🔍 SCAN"
    ScanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    
    print("=== SCAN COMPLETE ===")
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
