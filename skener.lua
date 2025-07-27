local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Scanner Results Storage
local ScanResults = {
    RemoteEvents = {},
    RemoteFunctions = {},
    LocalScripts = {},
    Values = {},
    GUIs = {},
    Bindables = {},
    TouchParts = {},
    ProximityPrompts = {},
    Suspicious = {}
}

-- Money/Currency Keywords
local MoneyKeywords = {
    "money", "cash", "coin", "currency", "dollar", "credit", "point", "score", 
    "gold", "silver", "gem", "diamond", "robux", "buck", "wallet", "bank",
    "balance", "fund", "wealth", "rich", "pay", "earn", "reward", "prize"
}

-- Stats Keywords  
local StatsKeywords = {
    "health", "hp", "level", "exp", "xp", "experience", "stat", "strength",
    "defense", "speed", "mana", "energy", "stamina", "power", "damage",
    "armor", "shield", "life", "lives", "kill", "death", "win", "lose"
}

-- Main Scanner UI
local ScannerUI
local MainFrame
local ResultsFrame
local LogFrame

-- Utility Functions
local function containsKeyword(text, keywords)
    text = string.lower(tostring(text))
    for _, keyword in ipairs(keywords) do
        if string.find(text, keyword) then
            return true, keyword
        end
    end
    return false
end

local function logResult(category, name, path, info)
    table.insert(ScanResults[category], {
        Name = name,
        Path = path,
        Info = info,
        Object = game:FindFirstChild(path, true)
    })
end

local function addLogEntry(text, color)
    if LogFrame and LogFrame:FindFirstChild("ScrollingFrame") then
        local entry = Instance.new("TextLabel")
        entry.Size = UDim2.new(1, -10, 0, 20)
        entry.BackgroundTransparency = 1
        entry.Text = text
        entry.TextColor3 = color or Color3.new(1, 1, 1)
        entry.Font = Enum.Font.SourceCodePro
        entry.TextSize = 11
        entry.TextXAlignment = Enum.TextXAlignment.Left
        entry.Parent = LogFrame.ScrollingFrame
        
        -- Auto-scroll
        LogFrame.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #LogFrame.ScrollingFrame:GetChildren() * 20)
        LogFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, LogFrame.ScrollingFrame.CanvasSize.Y.Offset)
    end
end

-- Core Scanner Functions
local function scanRemoteEvents()
    addLogEntry("🔍 Scanning Remote Events...", Color3.fromRGB(100, 200, 255))
    local count = 0
    
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local isMoney, keyword = containsKeyword(obj.Name, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(obj.Name, StatsKeywords)
            
            local info = "RemoteEvent"
            if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
            if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
            
            logResult("RemoteEvents", obj.Name, obj:GetFullName(), info)
            addLogEntry("  📡 " .. obj.Name .. " - " .. info, isMoney and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150))
            count = count + 1
        end
    end
    
    addLogEntry("✅ Found " .. count .. " Remote Events", Color3.fromRGB(0, 255, 100))
end

local function scanRemoteFunctions()
    addLogEntry("🔍 Scanning Remote Functions...", Color3.fromRGB(100, 200, 255))
    local count = 0
    
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteFunction") then
            local isMoney, keyword = containsKeyword(obj.Name, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(obj.Name, StatsKeywords)
            
            local info = "RemoteFunction"
            if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
            if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
            
            logResult("RemoteFunctions", obj.Name, obj:GetFullName(), info)
            addLogEntry("  🔧 " .. obj.Name .. " - " .. info, isMoney and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150))
            count = count + 1
        end
    end
    
    addLogEntry("✅ Found " .. count .. " Remote Functions", Color3.fromRGB(0, 255, 100))
end

local function scanValues()
    addLogEntry("🔍 Scanning Values (Money/Stats)...", Color3.fromRGB(100, 200, 255))
    local count = 0
    
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
            local isMoney, keyword = containsKeyword(obj.Name, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(obj.Name, StatsKeywords)
            
            if isMoney or isStats then
                local info = obj.ClassName .. " = " .. tostring(obj.Value)
                if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
                if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
                
                logResult("Values", obj.Name, obj:GetFullName(), info)
                addLogEntry("  💎 " .. obj.Name .. " = " .. tostring(obj.Value) .. " - " .. info, 
                    isMoney and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 255, 100))
                count = count + 1
            end
        end
    end
    
    addLogEntry("✅ Found " .. count .. " Valuable Values", Color3.fromRGB(0, 255, 100))
end

local function scanGUIs()
    addLogEntry("🔍 Scanning GUI Elements...", Color3.fromRGB(100, 200, 255))
    local count = 0
    
    for _, obj in pairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local isMoney, keyword = containsKeyword(obj.Name, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(obj.Name, StatsKeywords)
            
            if isMoney or isStats then
                local info = obj.ClassName .. " [Clickable]"
                if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
                if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
                
                logResult("GUIs", obj.Name, obj:GetFullName(), info)
                addLogEntry("  🖱️ " .. obj.Name .. " - " .. info, Color3.fromRGB(255, 150, 50))
                count = count + 1
            end
        end
        
        if obj:IsA("TextLabel") then
            local text = obj.Text
            local isMoney, keyword = containsKeyword(text, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(text, StatsKeywords)
            
            if isMoney or isStats then
                local info = "TextLabel: '" .. text .. "'"
                if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
                if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
                
                logResult("GUIs", obj.Name, obj:GetFullName(), info)
                addLogEntry("  📝 " .. obj.Name .. " - " .. info, Color3.fromRGB(200, 200, 100))
                count = count + 1
            end
        end
    end
    
    addLogEntry("✅ Found " .. count .. " GUI Elements", Color3.fromRGB(0, 255, 100))
end

local function scanProximityPrompts()
    addLogEntry("🔍 Scanning Proximity Prompts...", Color3.fromRGB(100, 200, 255))
    local count = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local isMoney, keyword = containsKeyword(obj.ObjectText, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(obj.ObjectText, StatsKeywords)
            
            local info = "ProximityPrompt: '" .. obj.ObjectText .. "'"
            if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
            if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
            
            logResult("ProximityPrompts", obj.ObjectText, obj:GetFullName(), info)
            addLogResult("  🚪 " .. obj.ObjectText .. " - " .. info, isMoney and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 255, 150))
            count = count + 1
        end
    end
    
    addLogEntry("✅ Found " .. count .. " Proximity Prompts", Color3.fromRGB(0, 255, 100))
end

local function scanTouchParts()
    addLogEntry("🔍 Scanning Touch-Enabled Parts...", Color3.fromRGB(100, 200, 255))
    local count = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Touched then
            local isMoney, keyword = containsKeyword(obj.Name, MoneyKeywords)
            local isStats, statKeyword = containsKeyword(obj.Name, StatsKeywords)
            
            if isMoney or isStats then
                local info = "TouchPart"
                if isMoney then info = info .. " [💰 MONEY: " .. keyword .. "]" end
                if isStats then info = info .. " [📊 STATS: " .. statKeyword .. "]" end
                
                logResult("TouchParts", obj.Name, obj:GetFullName(), info)
                addLogEntry("  👆 " .. obj.Name .. " - " .. info, Color3.fromRGB(255, 100, 255))
                count = count + 1
            end
        end
    end
    
    addLogEntry("✅ Found " .. count .. " Touch Parts", Color3.fromRGB(0, 255, 100))
end

-- Auto-Exploit Functions
local function autoTouchParts()
    addLogEntry("🤖 Auto-touching money parts...", Color3.fromRGB(255, 150, 0))
    
    for _, result in ipairs(ScanResults.TouchParts) do
        if result.Object and result.Object.Parent then
            pcall(function()
                result.Object:Touch(Player.Character.HumanoidRootPart)
            end)
        end
    end
end

local function autoClickButtons()
    addLogEntry("🤖 Auto-clicking money buttons...", Color3.fromRGB(255, 150, 0))
    
    for _, result in ipairs(ScanResults.GUIs) do
        if result.Object and result.Object.Parent and (result.Object:IsA("TextButton") or result.Object:IsA("ImageButton")) then
            pcall(function()
                result.Object.MouseButton1Click:Fire()
            end)
        end
    end
end

local function fireRemoteEvents()
    addLogEntry("🤖 Firing money remote events...", Color3.fromRGB(255, 150, 0))
    
    for _, result in ipairs(ScanResults.RemoteEvents) do
        if result.Object and result.Object.Parent and string.find(string.lower(result.Info), "money") then
            pcall(function()
                result.Object:FireServer()
                -- Try common parameters
                result.Object:FireServer(999999)
                result.Object:FireServer("add", 999999)
                result.Object:FireServer(Player, 999999)
            end)
        end
    end
end

-- GUI Builder
local function buildScannerGUI()
    if ScannerUI then ScannerUI:Destroy() end
    
    ScannerUI = Instance.new("ScreenGui")
    ScannerUI.Name = "UniversalScanner"
    ScannerUI.Parent = CoreGui
    ScannerUI.ResetOnSpawn = false
    
    -- Main Frame
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScannerUI
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = MainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 Universal Game Scanner & Exploit Tool"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 5)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        ScannerUI:Destroy()
    end)
    
    -- Control Panel
    local controlPanel = Instance.new("Frame")
    controlPanel.Size = UDim2.new(1, -20, 0, 100)
    controlPanel.Position = UDim2.new(0, 10, 0, 50)
    controlPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    controlPanel.BorderSizePixel = 0
    controlPanel.Parent = MainFrame
    
    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = UDim.new(0, 8)
    controlCorner.Parent = controlPanel
    
    -- Scan Buttons
    local buttonData = {
        {text = "🔍 Full Scan", func = function()
            addLogEntry("🚀 Starting Full Game Scan...", Color3.fromRGB(255, 255, 0))
            scanRemoteEvents()
            scanRemoteFunctions() 
            scanValues()
            scanGUIs()
            scanProximityPrompts()
            scanTouchParts()
            addLogEntry("✅ Full Scan Complete!", Color3.fromRGB(0, 255, 0))
        end},
        {text = "💰 Money Scan", func = function()
            addLogEntry("💰 Scanning for Money/Currency...", Color3.fromRGB(255, 215, 0))
            scanValues()
            scanGUIs()
        end},
        {text = "🤖 Auto Touch", func = autoTouchParts},
        {text = "🖱️ Auto Click", func = autoClickButtons},
        {text = "📡 Fire Events", func = fireRemoteEvents},
        {text = "🗑️ Clear Log", func = function()
            if LogFrame and LogFrame:FindFirstChild("ScrollingFrame") then
                for _, child in ipairs(LogFrame.ScrollingFrame:GetChildren()) do
                    if child:IsA("TextLabel") then
                        child:Destroy()
                    end
                end
            end
        end}
    }
    
    local buttonLayout = Instance.new("UIGridLayout")
    buttonLayout.CellSize = UDim2.new(0, 90, 0, 35)
    buttonLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    buttonLayout.Parent = controlPanel
    
    for i, data in ipairs(buttonData) do
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.Text = data.text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.Parent = controlPanel
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(data.func)
        
        -- Hover effect
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        end)
        
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
    end
    
    -- Log Frame
    LogFrame = Instance.new("Frame")
    LogFrame.Size = UDim2.new(1, -20, 1, -170)
    LogFrame.Position = UDim2.new(0, 10, 0, 160)
    LogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    LogFrame.BorderSizePixel = 0
    LogFrame.Parent = MainFrame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = LogFrame
    
    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(1, 0, 0, 25)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "📋 Scan Results & Logs"
    logTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextSize = 12
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Position = UDim2.new(0, 10, 0, 0)
    logTitle.Parent = LogFrame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -35)
    scrollFrame.Position = UDim2.new(0, 10, 0, 30)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = LogFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 6)
    scrollCorner.Parent = scrollFrame
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Hotkey
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if ScannerUI then
            ScannerUI:Destroy()
        else
            buildScannerGUI()
        end
    end
end)

-- Initialize
buildScannerGUI()
addLogEntry("🚀 Universal Scanner Loaded! Press INSERT to toggle.", Color3.fromRGB(0, 255, 255))
addLogEntry("💡 Click 'Full Scan' to analyze the game for exploitable elements.", Color3.fromRGB(200, 200, 200))

print("Universal Game Scanner Loaded!")
print("Press INSERT to open/close scanner")
print("Features:")
print("- Scans for RemoteEvents, RemoteFunctions, Values")
print("- Detects money/stats related elements")  
print("- Auto-exploit functions")
print("- Real-time logging")
