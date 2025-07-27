local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- Money keywords
local MoneyKeywords = {"money", "cash", "coin", "currency", "dollar", "credit", "point", "score", "gold", "silver", "gem", "diamond", "buck", "wallet", "bank", "balance"}

-- Simple GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoneyScanner"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 500, 0, 400)
Frame.Position = UDim2.new(0.5, -250, 0.5, -200)
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
Title.Text = "💰 Money & Notification Scanner"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- Buttons
local ButtonFrame = Instance.new("Frame")
ButtonFrame.Size = UDim2.new(1, -20, 0, 40)
ButtonFrame.Position = UDim2.new(0, 10, 0, 40)
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Parent = Frame

-- Scan Leaderstats Button
local LeaderstatsButton = Instance.new("TextButton")
LeaderstatsButton.Size = UDim2.new(0, 90, 0, 30)
LeaderstatsButton.Position = UDim2.new(0, 0, 0, 0)
LeaderstatsButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
LeaderstatsButton.Text = "👑 Leaderstats"
LeaderstatsButton.TextColor3 = Color3.new(1, 1, 1)
LeaderstatsButton.Font = Enum.Font.Gotham
LeaderstatsButton.TextSize = 10
LeaderstatsButton.BorderSizePixel = 0
LeaderstatsButton.Parent = ButtonFrame

local LeaderstatsCorner = Instance.new("UICorner")
LeaderstatsCorner.CornerRadius = UDim.new(0, 6)
LeaderstatsCorner.Parent = LeaderstatsButton

-- Scan GUI Button
local GUIButton = Instance.new("TextButton")
GUIButton.Size = UDim2.new(0, 90, 0, 30)
GUIButton.Position = UDim2.new(0, 100, 0, 0)
GUIButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
GUIButton.Text = "🖼️ GUI Money"
GUIButton.TextColor3 = Color3.new(1, 1, 1)
GUIButton.Font = Enum.Font.Gotham
GUIButton.TextSize = 10
GUIButton.BorderSizePixel = 0
GUIButton.Parent = ButtonFrame

local GUICorner = Instance.new("UICorner")
GUICorner.CornerRadius = UDim.new(0, 6)
GUICorner.Parent = GUIButton

-- Scan Values Button
local ValuesButton = Instance.new("TextButton")
ValuesButton.Size = UDim2.new(0, 90, 0, 30)
ValuesButton.Position = UDim2.new(0, 200, 0, 0)
ValuesButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
ValuesButton.Text = "💎 Values"
ValuesButton.TextColor3 = Color3.new(1, 1, 1)
ValuesButton.Font = Enum.Font.Gotham
ValuesButton.TextSize = 10
ValuesButton.BorderSizePixel = 0
ValuesButton.Parent = ButtonFrame

local ValuesCorner = Instance.new("UICorner")
ValuesCorner.CornerRadius = UDim.new(0, 6)
ValuesCorner.Parent = ValuesButton

-- Scan Checkpoints Button
local CheckpointButton = Instance.new("TextButton")
CheckpointButton.Size = UDim2.new(0, 90, 0, 30)
CheckpointButton.Position = UDim2.new(0, 300, 0, 0)
CheckpointButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
CheckpointButton.Text = "🏁 Checkpoints"
CheckpointButton.TextColor3 = Color3.new(1, 1, 1)
CheckpointButton.Font = Enum.Font.Gotham
CheckpointButton.TextSize = 10
CheckpointButton.BorderSizePixel = 0
CheckpointButton.Parent = ButtonFrame

local CheckpointCorner = Instance.new("UICorner")
CheckpointCorner.CornerRadius = UDim.new(0, 6)
CheckpointCorner.Parent = CheckpointButton

-- Clear Button
local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0, 70, 0, 30)
ClearButton.Position = UDim2.new(1, -80, 0, 0)
ClearButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ClearButton.Text = "🗑️ Clear"
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.Font = Enum.Font.Gotham
ClearButton.TextSize = 10
ClearButton.BorderSizePixel = 0
ClearButton.Parent = ButtonFrame

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 6)
ClearCorner.Parent = ClearButton

-- Results List
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -90)
ScrollFrame.Position = UDim2.new(0, 10, 0, 80)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = Frame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = ScrollFrame

-- Utility Functions
local function containsKeyword(text)
    text = string.lower(tostring(text))
    for _, keyword in ipairs(MoneyKeywords) do
        if string.find(text, keyword) then
            return true, keyword
        end
    end
    return false
end

local function clearResults()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

local function addResult(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceCode
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
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

-- Scan Leaderstats
local function scanLeaderstats()
    clearResults()
    addResult("👑 Scanning Player Leaderstats...", Color3.fromRGB(255, 215, 0))
    
    if Player:FindFirstChild("leaderstats") then
        addResult("✅ Found leaderstats!", Color3.fromRGB(0, 255, 0))
        
        for _, stat in pairs(Player.leaderstats:GetChildren()) do
            local value = tostring(stat.Value)
            local isMoney, keyword = containsKeyword(stat.Name)
            
            if isMoney then
                addResult("  💰 " .. stat.Name .. " = " .. value .. " [MONEY: " .. keyword .. "]", Color3.fromRGB(255, 215, 0))
            else
                addResult("  📊 " .. stat.Name .. " = " .. value, Color3.fromRGB(100, 200, 255))
            end
            addResult("      Type: " .. stat.ClassName .. " | Path: " .. stat:GetFullName(), Color3.fromRGB(150, 150, 150))
        end
    else
        addResult("❌ No leaderstats found", Color3.fromRGB(255, 100, 100))
        addResult("💡 This game might use a different money system", Color3.fromRGB(200, 200, 200))
    end
end

-- Scan GUI Money Displays
local function scanGUIMoney()
    clearResults()
    addResult("🖼️ Scanning GUI for money displays...", Color3.fromRGB(100, 200, 255))
    
    local found = 0
    
    for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") then
            local text = gui.Text
            local isMoney, keyword = containsKeyword(text)
            local hasNumber = string.match(text, "%d+")
            
            if isMoney and hasNumber then
                found = found + 1
                addResult("  💰 " .. gui.Name .. ": '" .. text .. "'", Color3.fromRGB(255, 215, 0))
                addResult("      Keyword: " .. keyword .. " | Path: " .. gui:GetFullName(), Color3.fromRGB(150, 150, 150))
            end
        end
    end
    
    addResult("✅ Found " .. found .. " money GUI elements", Color3.fromRGB(0, 255, 0))
    
    if found == 0 then
        addResult("❌ No money displays found in GUI", Color3.fromRGB(255, 100, 100))
        addResult("💡 Try looking after earning money", Color3.fromRGB(200, 200, 200))
    end
end

-- Scan Values
local function scanValues()
    clearResults()
    addResult("💎 Scanning for money-related Values...", Color3.fromRGB(255, 150, 0))
    
    local found = 0
    
    -- Scan player first
    for _, obj in pairs(Player:GetDescendants()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
            local isMoney, keyword = containsKeyword(obj.Name)
            
            if isMoney then
                found = found + 1
                addResult("  💰 " .. obj.Name .. " = " .. tostring(obj.Value), Color3.fromRGB(255, 215, 0))
                addResult("      Keyword: " .. keyword .. " | Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
            end
        end
    end
    
    -- Scan workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
            local isMoney, keyword = containsKeyword(obj.Name)
            
            if isMoney then
                found = found + 1
                addResult("  💎 " .. obj.Name .. " = " .. tostring(obj.Value), Color3.fromRGB(100, 255, 100))
                addResult("      Keyword: " .. keyword .. " | Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
            end
        end
    end
    
    addResult("✅ Found " .. found .. " money values", Color3.fromRGB(0, 255, 0))
end

-- Scan Checkpoints
local function scanCheckpoints()
    clearResults()
    addResult("🏁 Scanning for checkpoints and triggers...", Color3.fromRGB(255, 100, 255))
    
    local found = 0
    
    -- Look for parts with "checkpoint", "finish", "end", etc.
    local checkpointKeywords = {"checkpoint", "check", "finish", "end", "goal", "trigger", "collect", "pickup"}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            
            for _, keyword in ipairs(checkpointKeywords) do
                if string.find(name, keyword) then
                    found = found + 1
                    addResult("  🏁 " .. obj.Name .. " | Position: " .. tostring(obj.Position), Color3.fromRGB(255, 100, 255))
                    addResult("      Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
                    
                    -- Check if it has touch events or proximity prompts
                    if obj:FindFirstChild("ProximityPrompt") then
                        addResult("      💡 Has ProximityPrompt!", Color3.fromRGB(255, 255, 0))
                    end
                    
                    break
                end
            end
        end
        
        -- Look for ProximityPrompts specifically
        if obj:IsA("ProximityPrompt") then
            local isMoney, keyword = containsKeyword(obj.ObjectText)
            
            if isMoney or containsKeyword(obj.ActionText) then
                found = found + 1
                addResult("  🚪 ProximityPrompt: '" .. obj.ObjectText .. "'", Color3.fromRGB(255, 200, 0))
                addResult("      Action: '" .. obj.ActionText .. "' | Path: " .. obj:GetFullName(), Color3.fromRGB(150, 150, 150))
            end
        end
    end
    
    addResult("✅ Found " .. found .. " checkpoints/triggers", Color3.fromRGB(0, 255, 0))
    
    if found > 0 then
        addResult("💡 These might give money when touched!", Color3.fromRGB(200, 200, 200))
    end
end

-- Button Events
LeaderstatsButton.MouseButton1Click:Connect(scanLeaderstats)
GUIButton.MouseButton1Click:Connect(scanGUIMoney)
ValuesButton.MouseButton1Click:Connect(scanValues)
CheckpointButton.MouseButton1Click:Connect(scanCheckpoints)
ClearButton.MouseButton1Click:Connect(clearResults)

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

-- Initial scan
addResult("💰 Money Scanner loaded! Click buttons to scan:", Color3.fromRGB(100, 255, 255))
addResult("👑 Leaderstats - Player money/stats", Color3.fromRGB(200, 200, 200))
addResult("🖼️ GUI Money - Money displays on screen", Color3.fromRGB(200, 200, 200))
addResult("💎 Values - Hidden money values", Color3.fromRGB(200, 200, 200))
addResult("🏁 Checkpoints - Money-giving triggers", Color3.fromRGB(200, 200, 200))

print("Money & Notification Scanner loaded!")
print("This will help find where money is stored!")
print("Try each scan type to find the money system")
