--[[
🔍 IMPROVED REMOTEEVENT SCANNER TOOL v2.0
Enhanced version with better error handling and compatibility
Educational Purpose - Game Security Analysis
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Try CoreGui first, fallback to PlayerGui
local GuiParent = game:GetService("CoreGui")
pcall(function()
    local test = Instance.new("ScreenGui")
    test.Parent = GuiParent
    test:Destroy()
end) or (GuiParent = Players.LocalPlayer:WaitForChild("PlayerGui"))

local Player = Players.LocalPlayer

-- Enhanced scanner data storage
local ScannerData = {
    foundRemotes = {},
    hookedRemotes = {},
    networkLogs = {},
    suspiciousEvents = {},
    originalFunctions = {},
    isScanning = false,
    isLogging = false,
    scanDepth = 0,
    maxLogs = 1000
}

-- Expanded suspicious patterns with scoring
local SUSPICIOUS_PATTERNS = {
    -- High priority (Score: 5)
    {patterns = {"money", "cash", "coins", "currency", "balance", "wallet"}, score = 5},
    {patterns = {"give", "add", "remove", "set", "change"}, score = 5},
    {patterns = {"admin", "owner", "dev", "mod", "staff"}, score = 5},
    
    -- Medium priority (Score: 3)
    {patterns = {"buy", "sell", "purchase", "trade", "shop", "store"}, score = 3},
    {patterns = {"item", "tools", "gear", "weapon", "upgrade"}, score = 3},
    {patterns = {"teleport", "tp", "fly", "speed", "jump"}, score = 3},
    
    -- Low priority (Score: 1)
    {patterns = {"reward", "bonus", "gift", "prize", "earn"}, score = 1},
    {patterns = {"level", "exp", "xp", "rank", "points"}, score = 1}
}

-- GUI Variables
local ScannerGUI = nil
local MainFrame = nil
local LogFrame = nil
local RemoteList = nil
local NetworkLog = nil
local StatusLabel = nil

-- Enhanced utility functions
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Scanner Error: " .. tostring(result))
    end
    return success, result
end

local function timestampLog()
    return "[" .. os.date("%H:%M:%S") .. "] "
end

local function formatArgs(args)
    local formatted = {}
    for i, arg in pairs(args) do
        if type(arg) == "table" then
            local success, json = pcall(HttpService.JSONEncode, HttpService, arg)
            if success then
                table.insert(formatted, json)
            else
                table.insert(formatted, "Table[" .. #arg .. "]")
            end
        elseif type(arg) == "userdata" then
            table.insert(formatted, tostring(arg))
        else
            table.insert(formatted, tostring(arg))
        end
    end
    return table.concat(formatted, ", ")
end

local function updateStatus(message, color)
    if StatusLabel then
        StatusLabel.Text = "Status: " .. message
        StatusLabel.TextColor3 = color or Color3.new(1, 1, 1)
    end
end

local function logMessage(message, color, priority)
    print(timestampLog() .. message)
    
    if NetworkLog then
        -- Manage log count
        local children = NetworkLog:GetChildren()
        if #children >= ScannerData.maxLogs then
            children[1]:Destroy()
        end
        
        local logEntry = Instance.new("TextLabel")
        logEntry.Size = UDim2.new(1, -10, 0, 20)
        logEntry.BackgroundTransparency = 1
        logEntry.Text = timestampLog() .. message
        logEntry.TextColor3 = color or Color3.new(1, 1, 1)
        logEntry.TextSize = 12
        logEntry.Font = Enum.Font.RobotoMono
        logEntry.TextXAlignment = Enum.TextXAlignment.Left
        logEntry.Parent = NetworkLog
        
        -- Priority highlighting
        if priority and priority >= 3 then
            logEntry.BackgroundTransparency = 0.8
            logEntry.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        end
        
        -- Auto scroll with animation
        spawn(function()
            wait(0.1)
            NetworkLog.CanvasSize = UDim2.new(0, 0, 0, #NetworkLog:GetChildren() * 20)
            local targetPosition = Vector2.new(0, math.max(0, NetworkLog.CanvasSize.Y.Offset - NetworkLog.AbsoluteSize.Y))
            
            local tween = TweenService:Create(NetworkLog, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CanvasPosition = targetPosition}
            )
            tween:Play()
        end)
    end
end

-- Enhanced analysis functions
local function analyzeRemoteName(remoteName)
    local name = remoteName:lower()
    local totalScore = 0
    local matchedPatterns = {}
    
    for _, patternGroup in pairs(SUSPICIOUS_PATTERNS) do
        for _, pattern in pairs(patternGroup.patterns) do
            if name:find(pattern) then
                totalScore = totalScore + patternGroup.score
                table.insert(matchedPatterns, pattern .. "(" .. patternGroup.score .. ")")
            end
        end
    end
    
    -- Additional heuristics
    if name:match("%d+$") then -- Ends with numbers
        totalScore = totalScore + 1
        table.insert(matchedPatterns, "numbered")
    end
    
    if #name <= 3 then -- Very short names
        totalScore = totalScore + 2
        table.insert(matchedPatterns, "short")
    end
    
    if name:find("_") or name:find("-") then -- Contains separators
        totalScore = totalScore + 1
        table.insert(matchedPatterns, "formatted")
    end
    
    return totalScore, matchedPatterns
end

local function deepScanFolder(folder, path, depth)
    if depth > 10 then return end -- Prevent infinite recursion
    
    safeCall(function()
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
                    score = suspiciousScore,
                    timestamp = tick()
                }
                
                table.insert(ScannerData.foundRemotes, remoteData)
                
                if suspiciousScore > 0 then
                    table.insert(ScannerData.suspiciousEvents, remoteData)
                    local priority = suspiciousScore >= 5 and 5 or (suspiciousScore >= 3 and 3 or 1)
                    logMessage("🚨 SUSPICIOUS: " .. fullPath .. " (Score: " .. suspiciousScore .. ")", 
                        Color3.fromRGB(255, 100, 100), priority)
                    logMessage("   Patterns: " .. table.concat(patterns, ", "), 
                        Color3.fromRGB(255, 200, 100), priority)
                else
                    logMessage("📡 Found: " .. fullPath, Color3.fromRGB(100, 255, 100))
                end
                
            elseif child:IsA("Folder") or child:IsA("Configuration") or 
                   child:IsA("ModuleScript") or child:IsA("LocalScript") then
                deepScanFolder(child, path .. child.Name .. "/", depth + 1)
            end
        end
    end)
end

local function scanRemoteEvents()
    ScannerData.foundRemotes = {}
    ScannerData.suspiciousEvents = {}
    ScannerData.isScanning = true
    
    updateStatus("Scanning for RemoteEvents...", Color3.fromRGB(255, 255, 0))
    logMessage("🔍 Starting enhanced RemoteEvent scan...", Color3.fromRGB(0, 255, 255))
    
    -- Expanded scan locations
    local locations = {
        {ReplicatedStorage, "ReplicatedStorage/"},
        {game.ReplicatedFirst, "ReplicatedFirst/"},
        {game.Lighting, "Lighting/"},
        {game.StarterPlayer, "StarterPlayer/"},
        {game.StarterPack, "StarterPack/"},
        {game.StarterGui, "StarterGui/"},
        {game.SoundService, "SoundService/"},
        {game.Workspace, "Workspace/"}
    }
    
    -- Player-specific locations
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(locations, {player.Character, "Players/" .. player.Name .. "/Character/"})
        end
        if player:FindFirstChild("PlayerGui") then
            table.insert(locations, {player.PlayerGui, "Players/" .. player.Name .. "/PlayerGui/"})
        end
        if player:FindFirstChild("Backpack") then
            table.insert(locations, {player.Backpack, "Players/" .. player.Name .. "/Backpack/"})
        end
    end
    
    local totalFound = 0
    for _, location in pairs(locations) do
        if location[1] then
            logMessage("📂 Scanning: " .. location[2], Color3.fromRGB(200, 200, 255))
            safeCall(deepScanFolder, location[1], location[2], 0)
            wait(0.1) -- Prevent lag
        end
    end
    
    ScannerData.isScanning = false
    totalFound = #ScannerData.foundRemotes
    
    updateStatus("Scan complete! Found " .. totalFound .. " RemoteEvents", Color3.fromRGB(0, 255, 0))
    logMessage("✅ Enhanced scan complete! Found " .. totalFound .. " RemoteEvents", Color3.fromRGB(0, 255, 0))
    logMessage("⚠️ Suspicious events: " .. #ScannerData.suspiciousEvents, Color3.fromRGB(255, 255, 0))
    logMessage("🎯 High priority threats: " .. 
        #table.filter(ScannerData.suspiciousEvents, function(event) return event.score >= 5 end),
        Color3.fromRGB(255, 0, 0))
    
    updateRemoteList()
end

-- Enhanced hooking with better error handling
local function createAdvancedHook(remoteData)
    if ScannerData.hookedRemotes[remoteData.name] then
        return false -- Already hooked
    end
    
    local remote = remoteData.object
    if not remote or not remote.Parent then
        logMessage("❌ Cannot hook - RemoteEvent no longer exists: " .. remoteData.name, Color3.fromRGB(255, 0, 0))
        return false
    end
    
    local success, originalFunction = safeCall(function()
        return remote.FireServer
    end)
    
    if not success then
        logMessage("❌ Cannot access FireServer for: " .. remoteData.name, Color3.fromRGB(255, 0, 0))
        return false
    end
    
    -- Store original function
    ScannerData.originalFunctions[remoteData.name] = originalFunction
    
    -- Create enhanced hook
    safeCall(function()
        remote.FireServer = function(self, ...)
            local args = {...}
            local timestamp = tick()
            
            -- Log the call
            local argsString = formatArgs(args)
            local logColor = remoteData.suspicious and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 255)
            local priority = remoteData.score or 1
            
            logMessage("🔥 FIRED: " .. remoteData.name .. "(" .. argsString .. ")", logColor, priority)
            
            -- Enhanced logging data
            local logEntry = {
                name = remoteData.name,
                args = args,
                timestamp = timestamp,
                suspicious = remoteData.suspicious,
                score = remoteData.score or 0,
                argCount = #args,
                player = Player.Name
            }
            
            table.insert(ScannerData.networkLogs, logEntry)
            
            -- Detect potential exploits
            if #args > 10 then
                logMessage("⚠️ ALERT: Excessive arguments (" .. #args .. ") in " .. remoteData.name, 
                    Color3.fromRGB(255, 0, 0), 5)
            end
            
            for _, arg in pairs(args) do
                if type(arg) == "number" and (arg > 999999 or arg < -999999) then
                    logMessage("⚠️ ALERT: Extreme numeric value (" .. arg .. ") in " .. remoteData.name, 
                        Color3.fromRGB(255, 0, 0), 4)
                end
            end
            
            -- Call original function
            return originalFunction(self, ...)
        end
    end)
    
    ScannerData.hookedRemotes[remoteData.name] = true
    return true
end

local function hookAllRemotes()
    if #ScannerData.foundRemotes == 0 then
        logMessage("❌ No RemoteEvents found. Run scan first!", Color3.fromRGB(255, 0, 0))
        updateStatus("No RemoteEvents to hook", Color3.fromRGB(255, 0, 0))
        return
    end
    
    updateStatus("Hooking RemoteEvents...", Color3.fromRGB(255, 255, 0))
    logMessage("🪝 Starting advanced hook deployment...", Color3.fromRGB(255, 255, 0))
    
    local successCount = 0
    local failCount = 0
    
    for _, remoteData in pairs(ScannerData.foundRemotes) do
        if createAdvancedHook(remoteData) then
            successCount = successCount + 1
            logMessage("🪝 Hooked: " .. remoteData.name, Color3.fromRGB(255, 255, 100))
        else
            failCount = failCount + 1
        end
        wait(0.05) -- Prevent lag
    end
    
    -- Auto-hook new remotes
    if not ScannerData.autoHookConnection then
        ScannerData.autoHookConnection = ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if obj:IsA("RemoteEvent") and ScannerData.isLogging then
                wait(0.2) -- Ensure object is ready
                local suspiciousScore, patterns = analyzeRemoteName(obj.Name)
                local remoteData = {
                    name = obj.Name,
                    path = obj:GetFullName(),
                    object = obj,
                    suspicious = suspiciousScore > 0,
                    patterns = patterns,
                    score = suspiciousScore,
                    timestamp = tick()
                }
                
                table.insert(ScannerData.foundRemotes, remoteData)
                
                if createAdvancedHook(remoteData) then
                    logMessage("🆕 NEW RemoteEvent hooked: " .. obj.Name, Color3.fromRGB(0, 255, 255))
                    updateRemoteList()
                end
            end
        end)
    end
    
    ScannerData.isLogging = true
    updateStatus("Monitoring active! (" .. successCount .. " hooks)", Color3.fromRGB(0, 255, 0))
    logMessage("✅ Hook deployment complete! Success: " .. successCount .. ", Failed: " .. failCount, 
        Color3.fromRGB(0, 255, 0))
end

-- Enhanced testing with safety measures
local function performAdvancedTest(remoteData, testType)
    if not remoteData.object or not remoteData.object.Parent then
        logMessage("❌ Cannot test - RemoteEvent no longer exists: " .. remoteData.name, Color3.fromRGB(255, 0, 0))
        return
    end
    
    updateStatus("Testing " .. remoteData.name, Color3.fromRGB(255, 255, 0))
    logMessage("🧪 Advanced testing: " .. remoteData.name .. " (Type: " .. testType .. ")", 
        Color3.fromRGB(255, 255, 0))
    
    local testSets = {
        basic = {1, 10, 100, true, false, "test"},
        numeric = {0, -1, 999999, -999999, math.huge, -math.huge},
        string = {"", "admin", "give", "money", "hack", string.rep("A", 1000)},
        edge = {nil, {}, {money = 999999}, {admin = true}}
    }
    
    local testValues = testSets[testType] or testSets.basic
    
    for i, value in pairs(testValues) do
        safeCall(function()
            logMessage("   Test " .. i .. "/" .. #testValues .. ": " .. tostring(value), 
                Color3.fromRGB(200, 200, 200))
            remoteData.object:FireServer(value)
            wait(0.3) -- Prevent rate limiting
        end)
    end
    
    updateStatus("Testing complete", Color3.fromRGB(0, 255, 0))
    logMessage("✅ Advanced testing complete for: " .. remoteData.name, Color3.fromRGB(0, 255, 0))
end

-- Rest of the GUI code continues with improvements...
-- [Due to length limits, I'll continue with the enhanced GUI in the next part]
