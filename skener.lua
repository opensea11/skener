--[[
🔍 COMPLETE REMOTEEVENT SCANNER TOOL
Educational Purpose - Game Security Analysis
Created for understanding Roblox networking patterns
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

-- Scanner data storage
local ScannerData = {
    foundRemotes = {},
    hookedRemotes = {},
    networkLogs = {},
    suspiciousEvents = {},
    isScanning = false,
    isLogging = false
}

-- Patterns for detecting money/economy related events
local SUSPICIOUS_PATTERNS = {
    -- Money related
    "money", "cash", "coins", "currency", "balance", "wallet", "funds",
    "reward", "prize", "bonus", "gift", "earn", "income",
    -- Transaction related  
    "buy", "sell", "purchase", "transaction", "trade", "exchange",
    "add", "give", "remove", "take", "spend", "cost",
    -- Game economy
    "shop", "store", "market", "economy", "bank", "vault",
    "item", "product", "goods", "service", "upgrade"
}

-- GUI Variables
local ScannerGUI = nil
local MainFrame = nil
local LogFrame = nil
local RemoteList = nil
local NetworkLog = nil

-- Utility Functions
local function timestampLog()
    return "[" .. os.date("%H:%M:%S") .. "] "
end

local function logMessage(message, color)
    print(timestampLog() .. message)
    if NetworkLog then
        local logEntry = Instance.new("TextLabel")
        logEntry.Size = UDim2.new(1, -10, 0, 20)
        logEntry.BackgroundTransparency = 1
        logEntry.Text = timestampLog() .. message
        logEntry.TextColor3 = color or Color3.new(1, 1, 1)
        logEntry.TextSize = 12
        logEntry.Font = Enum.Font.RobotoMono
        logEntry.TextXAlignment = Enum.TextXAlignment.Left
        logEntry.Parent = NetworkLog
        
        -- Auto scroll
        NetworkLog.CanvasSize = UDim2.new(0, 0, 0, #NetworkLog:GetChildren() * 20)
        NetworkLog.CanvasPosition = Vector2.new(0, NetworkLog.CanvasSize.Y.Offset)
    end
end

-- Core Scanner Functions
local function analyzeRemoteName(remoteName)
    local name = remoteName:lower()
    local suspiciousScore = 0
    local matchedPatterns = {}
    
    for _, pattern in pairs(SUSPICIOUS_PATTERNS) do
        if name:find(pattern) then
            suspiciousScore = suspiciousScore + 1
            table.insert(matchedPatterns, pattern)
        end
    end
    
    return suspiciousScore, matchedPatterns
end

local function scanRemoteEvents()
    ScannerData.foundRemotes = {}
    ScannerData.suspiciousEvents = {}
    
    logMessage("🔍 Starting comprehensive RemoteEvent scan...", Color3.fromRGB(0, 255, 255))
    
    local function scanFolder(folder, path)
        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("RemoteEvent") then
                local fullPath = path .. child.Name
                local suspiciousScore, patterns = analyzeRemoteName(child.Name)
                
                local remoteData = {
                    name = child.Name,
                    path = fullPath,
                    object = child,
                    suspicious = suspiciousScore > 0,
                    patterns = patterns,
                    score = suspiciousScore
                }
                
                table.insert(ScannerData.foundRemotes, remoteData)
                
                if suspiciousScore > 0 then
                    table.insert(ScannerData.suspiciousEvents, remoteData)
                    logMessage("🚨 SUSPICIOUS: " .. fullPath .. " (Score: " .. suspiciousScore .. ")", Color3.fromRGB(255, 100, 100))
                    logMessage("   Patterns: " .. table.concat(patterns, ", "), Color3.fromRGB(255, 200, 100))
                else
                    logMessage("📡 Found: " .. fullPath, Color3.fromRGB(100, 255, 100))
                end
                
            elseif child:IsA("Folder") or child:IsA("Configuration") then
                scanFolder(child, path .. child.Name .. "/")
            end
        end
    end
    
    -- Scan common locations
    local locations = {
        {ReplicatedStorage, "ReplicatedStorage/"},
        {game.ReplicatedFirst, "ReplicatedFirst/"},
    }
    
    if game.StarterPlayer then
        table.insert(locations, {game.StarterPlayer, "StarterPlayer/"})
    end
    
    for _, location in pairs(locations) do
        if location[1] then
            logMessage("📂 Scanning: " .. location[2], Color3.fromRGB(200, 200, 255))
            scanFolder(location[1], location[2])
        end
    end
    
    logMessage("✅ Scan complete! Found " .. #ScannerData.foundRemotes .. " RemoteEvents", Color3.fromRGB(0, 255, 0))
    logMessage("⚠️ Suspicious events: " .. #ScannerData.suspiciousEvents, Color3.fromRGB(255, 255, 0))
    
    updateRemoteList()
end

local function hookRemoteEvent(remoteData)
    if ScannerData.hookedRemotes[remoteData.name] then
        return -- Already hooked
    end
    
    local remote = remoteData.object
    if not remote or not remote.Parent then
        return
    end
    
    local originalFireServer = remote.FireServer
    
    remote.FireServer = function(self, ...)
        local args = {...}
        local argsString = ""
        
        -- Convert arguments to readable string
        for i, arg in pairs(args) do
            if type(arg) == "table" then
                argsString = argsString .. "Table, "
            else
                argsString = argsString .. tostring(arg) .. ", "
            end
        end
        
        argsString = argsString:sub(1, -3) -- Remove last comma
        
        local logColor = remoteData.suspicious and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 255)
        logMessage("🔥 FIRED: " .. remoteData.name .. "(" .. argsString .. ")", logColor)
        
        -- Store in network logs
        table.insert(ScannerData.networkLogs, {
            name = remoteData.name,
            args = args,
            timestamp = tick(),
            suspicious = remoteData.suspicious
        })
        
        -- Call original function
        return originalFireServer(self, ...)
    end
    
    ScannerData.hookedRemotes[remoteData.name] = true
    logMessage("🪝 Hooked: " .. remoteData.name, Color3.fromRGB(255, 255, 100))
end

local function hookAllRemotes()
    logMessage("🪝 Hooking all RemoteEvents for monitoring...", Color3.fromRGB(255, 255, 0))
    
    for _, remoteData in pairs(ScannerData.foundRemotes) do
        hookRemoteEvent(remoteData)
    end
    
    -- Hook new remotes that get added later
    ReplicatedStorage.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") and ScannerData.isLogging then
            wait(0.1) -- Small delay to ensure object is fully loaded
            local suspiciousScore, patterns = analyzeRemoteName(obj.Name)
            local remoteData = {
                name = obj.Name,
                path = obj:GetFullName(),
                object = obj,
                suspicious = suspiciousScore > 0,
                patterns = patterns,
                score = suspiciousScore
            }
            
            table.insert(ScannerData.foundRemotes, remoteData)
            hookRemoteEvent(remoteData)
            logMessage("🆕 NEW RemoteEvent detected and hooked: " .. obj.Name, Color3.fromRGB(0, 255, 255))
            updateRemoteList()
        end
    end)
    
    ScannerData.isLogging = true
    logMessage("✅ Network monitoring active!", Color3.fromRGB(0, 255, 0))
end

local function testRemoteEvent(remoteData, testValues)
    if not remoteData.object or not remoteData.object.Parent then
        logMessage("❌ RemoteEvent no longer exists: " .. remoteData.name, Color3.fromRGB(255, 0, 0))
        return
    end
    
    logMessage("🧪 Testing RemoteEvent: " .. remoteData.name, Color3.fromRGB(255, 255, 0))
    
    for i, value in pairs(testValues) do
        pcall(function()
            logMessage("   Test " .. i .. ": " .. tostring(value), Color3.fromRGB(200, 200, 200))
            remoteData.object:FireServer(value)
            wait(0.2) -- Prevent spam detection
        end)
    end
    
    logMessage("✅ Testing complete for: " .. remoteData.name, Color3.fromRGB(0, 255, 0))
end

-- GUI Functions
local function updateRemoteList()
    if not RemoteList then return end
    
    -- Clear existing
    for _, child in pairs(RemoteList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add remotes to list
    for i, remoteData in pairs(ScannerData.foundRemotes) do
        local remoteFrame = Instance.new("Frame")
        remoteFrame.Size = UDim2.new(1, -10, 0, 60)
        remoteFrame.Position = UDim2.new(0, 5, 0, (i-1) * 65)
        remoteFrame.BackgroundColor3 = remoteData.suspicious and Color3.fromRGB(60, 20, 20) or Color3.fromRGB(30, 30, 30)
        remoteFrame.BorderSizePixel = 0
        remoteFrame.Parent = RemoteList
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = remoteFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 20)
        nameLabel.Position = UDim2.new(0, 5, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = remoteData.name
        nameLabel.TextColor3 = remoteData.suspicious and Color3.fromRGB(255, 100, 100) or Color3.new(1, 1, 1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = remoteFrame
        
        local pathLabel = Instance.new("TextLabel")
        pathLabel.Size = UDim2.new(1, -10, 0, 15)
        pathLabel.Position = UDim2.new(0, 5, 0, 25)
        pathLabel.BackgroundTransparency = 1
        pathLabel.Text = remoteData.path
        pathLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        pathLabel.Font = Enum.Font.Gotham
        pathLabel.TextSize = 10
        pathLabel.TextXAlignment = Enum.TextXAlignment.Left
        pathLabel.Parent = remoteFrame
        
        if remoteData.suspicious then
            local suspiciousLabel = Instance.new("TextLabel")
            suspiciousLabel.Size = UDim2.new(1, -10, 0, 15)
            suspiciousLabel.Position = UDim2.new(0, 5, 0, 40)
            suspiciousLabel.BackgroundTransparency = 1
            suspiciousLabel.Text = "🚨 Patterns: " .. table.concat(remoteData.patterns, ", ")
            suspiciousLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            suspiciousLabel.Font = Enum.Font.Gotham
            suspiciousLabel.TextSize = 9
            suspiciousLabel.TextXAlignment = Enum.TextXAlignment.Left
            suspiciousLabel.Parent = remoteFrame
        end
        
        -- Test button
        local testButton = Instance.new("TextButton")
        testButton.Size = UDim2.new(0, 60, 0, 25)
        testButton.Position = UDim2.new(1, -70, 0, 5)
        testButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        testButton.Text = "Test"
        testButton.TextColor3 = Color3.new(1, 1, 1)
        testButton.Font = Enum.Font.Gotham
        testButton.TextSize = 10
        testButton.BorderSizePixel = 0
        testButton.Parent = remoteFrame
        
        local testCorner = Instance.new("UICorner")
        testCorner.CornerRadius = UDim.new(0, 3)
        testCorner.Parent = testButton
        
        testButton.MouseButton1Click:Connect(function()
            local testValues = {1, 10, 100, 1000, -1, -100, 999999, "test", true}
            testRemoteEvent(remoteData, testValues)
        end)
    end
    
    -- Update canvas size
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, #ScannerData.foundRemotes * 65)
end

local function createScannerGUI()
    if ScannerGUI then ScannerGUI:Destroy() end
    
    ScannerGUI = Instance.new("ScreenGui")
    ScannerGUI.Name = "RemoteEventScanner"
    ScannerGUI.Parent = CoreGui
    ScannerGUI.ResetOnSpawn = false
    
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 800, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScannerGUI
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 RemoteEvent Scanner - Educational Tool"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        ScannerGUI:Destroy()
    end)
    
    -- Control buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, -20, 0, 40)
    buttonFrame.Position = UDim2.new(0, 10, 0, 50)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = MainFrame
    
    local scanButton = Instance.new("TextButton")
    scanButton.Size = UDim2.new(0, 120, 0, 30)
    scanButton.Position = UDim2.new(0, 0, 0, 5)
    scanButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    scanButton.Text = "🔍 Scan Events"
    scanButton.TextColor3 = Color3.new(1, 1, 1)
    scanButton.Font = Enum.Font.Gotham
    scanButton.TextSize = 12
    scanButton.BorderSizePixel = 0
    scanButton.Parent = buttonFrame
    
    local scanCorner = Instance.new("UICorner")
    scanCorner.CornerRadius = UDim.new(0, 4)
    scanCorner.Parent = scanButton
    
    local hookButton = Instance.new("TextButton")
    hookButton.Size = UDim2.new(0, 120, 0, 30)
    hookButton.Position = UDim2.new(0, 130, 0, 5)
    hookButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    hookButton.Text = "🪝 Hook All"
    hookButton.TextColor3 = Color3.new(1, 1, 1)
    hookButton.Font = Enum.Font.Gotham
    hookButton.TextSize = 12
    hookButton.BorderSizePixel = 0
    hookButton.Parent = buttonFrame
    
    local hookCorner = Instance.new("UICorner")
    hookCorner.CornerRadius = UDim.new(0, 4)
    hookCorner.Parent = hookButton
    
    local clearButton = Instance.new("TextButton")
    clearButton.Size = UDim2.new(0, 120, 0, 30)
    clearButton.Position = UDim2.new(0, 260, 0, 5)
    clearButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    clearButton.Text = "🗑️ Clear Logs"
    clearButton.TextColor3 = Color3.new(1, 1, 1)
    clearButton.Font = Enum.Font.Gotham
    clearButton.TextSize = 12
    clearButton.BorderSizePixel = 0
    clearButton.Parent = buttonFrame
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearButton
    
    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -110)
    contentFrame.Position = UDim2.new(0, 10, 0, 100)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = MainFrame
    
    -- Remote list (left side)
    local remoteListFrame = Instance.new("Frame")
    remoteListFrame.Size = UDim2.new(0.5, -5, 1, 0)
    remoteListFrame.Position = UDim2.new(0, 0, 0, 0)
    remoteListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    remoteListFrame.BorderSizePixel = 0
    remoteListFrame.Parent = contentFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = remoteListFrame
    
    local listTitle = Instance.new("TextLabel")
    listTitle.Size = UDim2.new(1, 0, 0, 30)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "📡 Found RemoteEvents"
    listTitle.TextColor3 = Color3.new(1, 1, 1)
    listTitle.Font = Enum.Font.GothamBold
    listTitle.TextSize = 14
    listTitle.Parent = remoteListFrame
    
    RemoteList = Instance.new("ScrollingFrame")
    RemoteList.Size = UDim2.new(1, -10, 1, -40)
    RemoteList.Position = UDim2.new(0, 5, 0, 35)
    RemoteList.BackgroundTransparency = 1
    RemoteList.BorderSizePixel = 0
    RemoteList.ScrollBarThickness = 8
    RemoteList.Parent = remoteListFrame
    
    -- Network log (right side)
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(0.5, -5, 1, 0)
    logFrame.Position = UDim2.new(0.5, 5, 0, 0)
    logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    logFrame.BorderSizePixel = 0
    logFrame.Parent = contentFrame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 6)
    logCorner.Parent = logFrame
    
    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(1, 0, 0, 30)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "📊 Network Activity Log"
    logTitle.TextColor3 = Color3.new(1, 1, 1)
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextSize = 14
    logTitle.Parent = logFrame
    
    NetworkLog = Instance.new("ScrollingFrame")
    NetworkLog.Size = UDim2.new(1, -10, 1, -40)
    NetworkLog.Position = UDim2.new(0, 5, 0, 35)
    NetworkLog.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    NetworkLog.BorderSizePixel = 0
    NetworkLog.ScrollBarThickness = 8
    NetworkLog.Parent = logFrame
    
    local logFrameCorner = Instance.new("UICorner")
    logFrameCorner.CornerRadius = UDim.new(0, 4)
    logFrameCorner.Parent = NetworkLog
    
    -- Button connections
    scanButton.MouseButton1Click:Connect(function()
        scanRemoteEvents()
    end)
    
    hookButton.MouseButton1Click:Connect(function()
        hookAllRemotes()
    end)
    
    clearButton.MouseButton1Click:Connect(function()
        for _, child in pairs(NetworkLog:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        ScannerData.networkLogs = {}
        logMessage("🗑️ Logs cleared", Color3.fromRGB(100, 100, 100))
    end)
    
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
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
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

-- Initialize
local function initializeScanner()
    createScannerGUI()
    logMessage("🚀 RemoteEvent Scanner initialized!", Color3.fromRGB(0, 255, 0))
    logMessage("📚 Educational tool for understanding game networking", Color3.fromRGB(200, 200, 200))
    logMessage("🔍 Click 'Scan Events' to start analysis", Color3.fromRGB(255, 255, 0))
end

-- Keyboard shortcut to toggle GUI
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if ScannerGUI and ScannerGUI.Parent then
            ScannerGUI:Destroy()
        else
            initializeScanner()
        end
    end
end)

-- Auto-start
initializeScanner()

print("🔍 RemoteEvent Scanner loaded!")
print("📋 Controls:")
print("   INSERT - Toggle scanner GUI")
print("   Use GUI buttons to scan and monitor")
print("🎯 Educational Purpose: Understanding Roblox networking security")
print("⚠️ Use responsibly and ethically!")