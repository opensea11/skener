local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Kill System Variables
local KillRadius = 50
local KillMethod = "Health" -- "Health", "Destroy", "RootPart"
local AutoKillEnabled = false
local KillCooldown = false

local MainUI
local MainFrame
local GuiVisible = true

-- KILL SYSTEM FUNCTIONS

-- Method 1: Health Manipulation (Most Compatible)
local function KillByHealth(targetPlayer)
    pcall(function()
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = targetPlayer.Character.Humanoid
            humanoid.Health = 0
            humanoid.MaxHealth = 0
            return true
        end
    end)
    return false
end

-- Method 2: Character Destruction (Most Effective)
local function KillByDestroy(targetPlayer)
    pcall(function()
        if targetPlayer.Character then
            targetPlayer.Character:Destroy()
            return true
        end
    end)
    return false
end

-- Method 3: RootPart Removal (Clean Kill)
local function KillByRootPart(targetPlayer)
    pcall(function()
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart:Destroy()
            return true
        end
    end)
    return false
end

-- Method 4: Multi-Method Kill (Most Aggressive)
local function KillByMultiple(targetPlayer)
    local success = false
    
    -- Try all methods for maximum effectiveness
    pcall(function()
        if targetPlayer.Character then
            local char = targetPlayer.Character
            
            -- Method 1: Remove critical parts
            if char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart:Destroy()
                success = true
            end
            
            -- Method 2: Destroy humanoid
            if char:FindFirstChild("Humanoid") then
                char.Humanoid.Health = 0
                char.Humanoid:Destroy()
                success = true
            end
            
            -- Method 3: Remove head (classic kill)
            if char:FindFirstChild("Head") then
                char.Head:Destroy()
                success = true
            end
            
            -- Method 4: Full character destruction
            wait(0.1)
            char:Destroy()
            success = true
        end
    end)
    
    return success
end

-- Execute Kill Based on Selected Method
local function ExecuteKill(targetPlayer)
    local success = false
    
    if KillMethod == "Health" then
        success = KillByHealth(targetPlayer)
    elseif KillMethod == "Destroy" then
        success = KillByDestroy(targetPlayer)
    elseif KillMethod == "RootPart" then
        success = KillByRootPart(targetPlayer)
    elseif KillMethod == "Multiple" then
        success = KillByMultiple(targetPlayer)
    end
    
    return success
end

-- Kill All Players
local function KillAllPlayers()
    if KillCooldown then return end
    KillCooldown = true
    
    local playersFound = 0
    local playersKilled = 0
    
    print("💀 Starting Mass Kill...")
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= Player then
            playersFound = playersFound + 1
            
            local success = ExecuteKill(targetPlayer)
            if success then
                playersKilled = playersKilled + 1
                print("💀 Killed: " .. targetPlayer.Name)
            else
                print("❌ Failed to kill: " .. targetPlayer.Name)
            end
            
            -- Small delay to prevent lag
            wait(0.1)
        end
    end
    
    print("💀 Mass Kill Complete! " .. playersKilled .. "/" .. playersFound .. " players eliminated")
    
    -- Cooldown
    wait(2)
    KillCooldown = false
end

-- Kill Specific Player
local function KillSpecificPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then
        print("❌ Player not found: " .. playerName)
        return false
    end
    
    if targetPlayer == Player then
        print("❌ Cannot kill yourself!")
        return false
    end
    
    local success = ExecuteKill(targetPlayer)
    
    if success then
        print("💀 Successfully killed: " .. targetPlayer.Name)
        return true
    else
        print("❌ Failed to kill: " .. targetPlayer.Name)
        return false
    end
end

-- Kill Players in Radius
local function KillInRadius()
    if not HumanoidRootPart then return end
    
    local myPosition = HumanoidRootPart.Position
    local playersFound = 0
    local playersKilled = 0
    
    print("💥 Starting Radius Kill (Range: " .. KillRadius .. " studs)...")
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
            local distance = (myPosition - targetPosition).Magnitude
            
            if distance <= KillRadius then
                playersFound = playersFound + 1
                
                local success = ExecuteKill(targetPlayer)
                if success then
                    playersKilled = playersKilled + 1
                    print("💀 Radius killed: " .. targetPlayer.Name .. " (Distance: " .. math.floor(distance) .. ")")
                end
                
                wait(0.05)
            end
        end
    end
    
    print("💥 Radius Kill Complete! " .. playersKilled .. "/" .. playersFound .. " players eliminated")
end

-- Auto Kill Loop (Kills anyone who spawns)
local function ToggleAutoKill()
    AutoKillEnabled = not AutoKillEnabled
    
    if AutoKillEnabled then
        print("🔴 AUTO KILL ENABLED - All new spawns will be eliminated!")
        
        spawn(function()
            while AutoKillEnabled do
                for _, targetPlayer in pairs(Players:GetPlayers()) do
                    if targetPlayer ~= Player and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                        local humanoid = targetPlayer.Character.Humanoid
                        if humanoid.Health > 0 then
                            ExecuteKill(targetPlayer)
                            print("🔴 Auto-killed: " .. targetPlayer.Name)
                        end
                    end
                end
                wait(1) -- Check every second
            end
        end)
    else
        print("🟢 Auto Kill Disabled")
    end
end

-- TOGGLE GUI FUNCTION
local function toggleGUI()
    GuiVisible = not GuiVisible
    if MainFrame then
        MainFrame.Visible = GuiVisible
    end
end

-- GUI BUILDER
local function buildKillGUI()
    if MainUI then MainUI:Destroy() end

    MainUI = Instance.new("ScreenGui")
    MainUI.Name = "KillSystemUI"
    MainUI.Parent = CoreGui
    MainUI.ResetOnSpawn = false

    -- Main Frame
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 350, 0, 420)
    MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = MainUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame

    -- Title (Draggable)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    title.Text = "💀 ADVANCED KILL SYSTEM [Drag Me]"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    -- Make GUI Draggable
    local titleDragging = false
    local dragStart = nil
    local startPos = nil

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            titleDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if titleDragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)

    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            titleDragging = false
        end
    end)

    -- Hover effect
    title.MouseEnter:Connect(function()
        title.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
        title.Text = "💀 ADVANCED KILL SYSTEM [Dragging...]"
    end)

    title.MouseLeave:Connect(function()
        title.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        title.Text = "💀 ADVANCED KILL SYSTEM [Drag Me]"
    end)

    -- Kill Method Selection
    local methodSection = Instance.new("Frame")
    methodSection.Size = UDim2.new(1, -20, 0, 80)
    methodSection.Position = UDim2.new(0, 10, 0, 50)
    methodSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    methodSection.BackgroundTransparency = 0.2
    methodSection.BorderSizePixel = 0
    methodSection.Parent = MainFrame
    
    local methodCorner = Instance.new("UICorner")
    methodCorner.CornerRadius = UDim.new(0, 8)
    methodCorner.Parent = methodSection

    local methodLabel = Instance.new("TextLabel")
    methodLabel.Size = UDim2.new(1, 0, 0, 25)
    methodLabel.Position = UDim2.new(0, 0, 0, 5)
    methodLabel.BackgroundTransparency = 1
    methodLabel.Text = "⚔️ Kill Method Selection"
    methodLabel.TextColor3 = Color3.new(1, 1, 1)
    methodLabel.Font = Enum.Font.GothamBold
    methodLabel.TextSize = 12
    methodLabel.Parent = methodSection

    -- Method Buttons
    local methodButtons = Instance.new("Frame")
    methodButtons.Size = UDim2.new(1, -10, 0, 45)
    methodButtons.Position = UDim2.new(0, 5, 0, 30)
    methodButtons.BackgroundTransparency = 1
    methodButtons.Parent = methodSection

    local methodLayout = Instance.new("UIListLayout")
    methodLayout.FillDirection = Enum.FillDirection.Horizontal
    methodLayout.Padding = UDim.new(0, 5)
    methodLayout.Parent = methodButtons

    local killMethods = {
        {name = "Health", method = "Health", desc = "Safe"},
        {name = "Destroy", method = "Destroy", desc = "Fast"},
        {name = "RootPart", method = "RootPart", desc = "Clean"},
        {name = "Multiple", method = "Multiple", desc = "Brutal"}
    }

    local methodBtns = {}
    for i, methodData in ipairs(killMethods) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, -4, 1, 0)
        btn.BackgroundColor3 = methodData.method == KillMethod and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(80, 80, 80)
        btn.Text = methodData.name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.Parent = methodButtons
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn

        methodBtns[methodData.method] = btn

        btn.MouseButton1Click:Connect(function()
            -- Update selection
            for method, button in pairs(methodBtns) do
                button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            end
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            KillMethod = methodData.method
            print("🔧 Kill method changed to: " .. methodData.method)
        end)
    end

    -- Kill All Section
    local killAllSection = Instance.new("Frame")
    killAllSection.Size = UDim2.new(1, -20, 0, 60)
    killAllSection.Position = UDim2.new(0, 10, 0, 140)
    killAllSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    killAllSection.BackgroundTransparency = 0.2
    killAllSection.BorderSizePixel = 0
    killAllSection.Parent = MainFrame
    
    local killAllCorner = Instance.new("UICorner")
    killAllCorner.CornerRadius = UDim.new(0, 8)
    killAllCorner.Parent = killAllSection

    local killAllButton = Instance.new("TextButton")
    killAllButton.Size = UDim2.new(1, -20, 0, 40)
    killAllButton.Position = UDim2.new(0, 10, 0, 10)
    killAllButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    killAllButton.Text = "💀 KILL ALL PLAYERS"
    killAllButton.TextColor3 = Color3.new(1, 1, 1)
    killAllButton.Font = Enum.Font.GothamBold
    killAllButton.TextSize = 14
    killAllButton.BorderSizePixel = 0
    killAllButton.Parent = killAllSection
    
    local killAllBtnCorner = Instance.new("UICorner")
    killAllBtnCorner.CornerRadius = UDim.new(0, 8)
    killAllBtnCorner.Parent = killAllButton

    -- Specific Kill Section
    local specificSection = Instance.new("Frame")
    specificSection.Size = UDim2.new(1, -20, 0, 80)
    specificSection.Position = UDim2.new(0, 10, 0, 210)
    specificSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    specificSection.BackgroundTransparency = 0.2
    specificSection.BorderSizePixel = 0
    specificSection.Parent = MainFrame
    
    local specificCorner = Instance.new("UICorner")
    specificCorner.CornerRadius = UDim.new(0, 8)
    specificCorner.Parent = specificSection

    local specificLabel = Instance.new("TextLabel")
    specificLabel.Size = UDim2.new(1, 0, 0, 20)
    specificLabel.Position = UDim2.new(0, 0, 0, 5)
    specificLabel.BackgroundTransparency = 1
    specificLabel.Text = "🎯 Kill Specific Player"
    specificLabel.TextColor3 = Color3.new(1, 1, 1)
    specificLabel.Font = Enum.Font.GothamBold
    specificLabel.TextSize = 12
    specificLabel.Parent = specificSection

    local playerInput = Instance.new("TextBox")
    playerInput.Size = UDim2.new(0.6, 0, 0, 30)
    playerInput.Position = UDim2.new(0, 10, 0, 25)
    playerInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    playerInput.Text = "Player Name"
    playerInput.TextColor3 = Color3.new(1, 1, 1)
    playerInput.Font = Enum.Font.Gotham
    playerInput.TextSize = 11
    playerInput.BorderSizePixel = 0
    playerInput.Parent = specificSection
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = playerInput

    local killSpecificButton = Instance.new("TextButton")
    killSpecificButton.Size = UDim2.new(0.35, 0, 0, 30)
    killSpecificButton.Position = UDim2.new(0.65, 0, 0, 25)
    killSpecificButton.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
    killSpecificButton.Text = "💀 KILL"
    killSpecificButton.TextColor3 = Color3.new(1, 1, 1)
    killSpecificButton.Font = Enum.Font.GothamBold
    killSpecificButton.TextSize = 11
    killSpecificButton.BorderSizePixel = 0
    killSpecificButton.Parent = specificSection
    
    local killSpecificCorner = Instance.new("UICorner")
    killSpecificCorner.CornerRadius = UDim.new(0, 6)
    killSpecificCorner.Parent = killSpecificButton

    -- Radius Kill Section
    local radiusSection = Instance.new("Frame")
    radiusSection.Size = UDim2.new(1, -20, 0, 100)
    radiusSection.Position = UDim2.new(0, 10, 0, 300)
    radiusSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    radiusSection.BackgroundTransparency = 0.2
    radiusSection.BorderSizePixel = 0
    radiusSection.Parent = MainFrame
    
    local radiusCorner = Instance.new("UICorner")
    radiusCorner.CornerRadius = UDim.new(0, 8)
    radiusCorner.Parent = radiusSection

    local radiusLabel = Instance.new("TextLabel")
    radiusLabel.Size = UDim2.new(1, 0, 0, 25)
    radiusLabel.Position = UDim2.new(0, 0, 0, 5)
    radiusLabel.BackgroundTransparency = 1
    radiusLabel.Text = "💥 Radius Kill: " .. KillRadius .. " studs"
    radiusLabel.TextColor3 = Color3.new(1, 1, 1)
    radiusLabel.Font = Enum.Font.GothamBold
    radiusLabel.TextSize = 12
    radiusLabel.Parent = radiusSection

    -- Radius Slider
    local radiusSliderBg = Instance.new("Frame")
    radiusSliderBg.Size = UDim2.new(1, -20, 0, 20)
    radiusSliderBg.Position = UDim2.new(0, 10, 0, 30)
    radiusSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    radiusSliderBg.BorderSizePixel = 0
    radiusSliderBg.Parent = radiusSection
    
    local radiusSliderBgCorner = Instance.new("UICorner")
    radiusSliderBgCorner.CornerRadius = UDim.new(0, 10)
    radiusSliderBgCorner.Parent = radiusSliderBg

    local radiusSlider = Instance.new("Frame")
    radiusSlider.Size = UDim2.new(KillRadius/100, 0, 1, 0)
    radiusSlider.Position = UDim2.new(0, 0, 0, 0)
    radiusSlider.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    radiusSlider.BorderSizePixel = 0
    radiusSlider.Parent = radiusSliderBg
    
    local radiusSliderCorner = Instance.new("UICorner")
    radiusSliderCorner.CornerRadius = UDim.new(0, 10)
    radiusSliderCorner.Parent = radiusSlider

    local radiusSliderButton = Instance.new("TextButton")
    radiusSliderButton.Size = UDim2.new(0, 20, 0, 20)
    radiusSliderButton.Position = UDim2.new(KillRadius/100, -10, 0, 0)
    radiusSliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
    radiusSliderButton.Text = ""
    radiusSliderButton.BorderSizePixel = 0
    radiusSliderButton.Parent = radiusSliderBg
    
    local radiusButtonCorner = Instance.new("UICorner")
    radiusButtonCorner.CornerRadius = UDim.new(1, 0)
    radiusButtonCorner.Parent = radiusSliderButton

    local radiusKillButton = Instance.new("TextButton")
    radiusKillButton.Size = UDim2.new(0.48, 0, 0, 25)
    radiusKillButton.Position = UDim2.new(0, 10, 0, 60)
    radiusKillButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    radiusKillButton.Text = "💥 RADIUS KILL"
    radiusKillButton.TextColor3 = Color3.new(1, 1, 1)
    radiusKillButton.Font = Enum.Font.GothamBold
    radiusKillButton.TextSize = 10
    radiusKillButton.BorderSizePixel = 0
    radiusKillButton.Parent = radiusSection
    
    local radiusKillCorner = Instance.new("UICorner")
    radiusKillCorner.CornerRadius = UDim.new(0, 6)
    radiusKillCorner.Parent = radiusKillButton

    local autoKillButton = Instance.new("TextButton")
    autoKillButton.Size = UDim2.new(0.48, 0, 0, 25)
    autoKillButton.Position = UDim2.new(0.52, 0, 0, 60)
    autoKillButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    autoKillButton.Text = "🔴 AUTO KILL"
    autoKillButton.TextColor3 = Color3.new(1, 1, 1)
    autoKillButton.Font = Enum.Font.GothamBold
    autoKillButton.TextSize = 10
    autoKillButton.BorderSizePixel = 0
    autoKillButton.Parent = radiusSection
    
    local autoKillCorner = Instance.new("UICorner")
    autoKillCorner.CornerRadius = UDim.new(0, 6)
    autoKillCorner.Parent = autoKillButton

    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 15)
    statusLabel.Position = UDim2.new(0, 0, 0, 85)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "⚠️ EXTREME GRIEFING TOOL - USE RESPONSIBLY!"
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.Parent = radiusSection

    -- BUTTON FUNCTIONALITY

    -- Kill All Button
    killAllButton.MouseButton1Click:Connect(function()
        killAllButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        killAllButton.Text = "💀 KILLING..."
        statusLabel.Text = "💀 Eliminating all players..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        KillAllPlayers()
        
        wait(1)
        killAllButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        killAllButton.Text = "💀 KILL ALL PLAYERS"
        statusLabel.Text = "✅ Mass elimination complete!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        wait(3)
        statusLabel.Text = "⚠️ EXTREME GRIEFING TOOL - USE RESPONSIBLY!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    end)

    -- Kill Specific Button
    killSpecificButton.MouseButton1Click:Connect(function()
        local targetName = playerInput.Text
        if targetName and targetName ~= "Player Name" and targetName ~= "" then
            killSpecificButton.BackgroundColor3 = Color3.fromRGB(100, 25, 0)
            killSpecificButton.Text = "💀 KILLING..."
            statusLabel.Text = "🎯 Targeting " .. targetName .. "..."
            statusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
            
            local success = KillSpecificPlayer(targetName)
            
            wait(1)
            killSpecificButton.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
            killSpecificButton.Text = "💀 KILL"
            
            if success then
                statusLabel.Text = "✅ Successfully eliminated " .. targetName .. "!"
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            else
                statusLabel.Text = "❌ Failed to eliminate " .. targetName
                statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
            
            wait(3)
            statusLabel.Text = "⚠️ EXTREME GRIEFING TOOL - USE RESPONSIBLY!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            statusLabel.Text = "❌ Please enter a valid player name!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            wait(2)
            statusLabel.Text = "⚠️ EXTREME GRIEFING TOOL - USE RESPONSIBLY!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end)

    -- Radius Kill Button
    radiusKillButton.MouseButton1Click:Connect(function()
        radiusKillButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        radiusKillButton.Text = "💥 KILLING..."
        statusLabel.Text = "💥 Radius elimination in progress..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
        
        KillInRadius()
        
        wait(1)
        radiusKillButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        radiusKillButton.Text = "💥 RADIUS KILL"
        statusLabel.Text = "✅ Radius elimination complete!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        wait(3)
        statusLabel.Text = "⚠️ EXTREME GRIEFING TOOL - USE RESPONSIBLY!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    end)

    -- Auto Kill Button
    autoKillButton.MouseButton1Click:Connect(function()
        ToggleAutoKill()
        if AutoKillEnabled then
            autoKillButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            autoKillButton.Text = "🔴 AUTO ON"
            statusLabel.Text = "🔴 Auto Kill Active - Eliminating all spawns!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            autoKillButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            autoKillButton.Text = "🔴 AUTO KILL"
            statusLabel.Text = "🟢 Auto Kill Disabled"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            wait(2)
            statusLabel.Text = "⚠️ EXTREME GRIEFING TOOL - USE RESPONSIBLY!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end)

    -- Radius Slider Logic
    local radiusSliderDragging = false
    radiusSliderButton.MouseButton1Down:Connect(function()
        radiusSliderDragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            radiusSliderDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if radiusSliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = Players.LocalPlayer:GetMouse()
            local relativeX = mouse.X - radiusSliderBg.AbsolutePosition.X
            local percentage = math.clamp(relativeX / radiusSliderBg.AbsoluteSize.X, 0, 1)
            
            KillRadius = math.floor(percentage * 100) + 10
            if KillRadius > 200 then KillRadius = 200 end
            if KillRadius < 10 then KillRadius = 10 end
            
            radiusSlider.Size = UDim2.new(percentage, 0, 1, 0)
            radiusSliderButton.Position = UDim2.new(percentage, -10, 0, 0)
            radiusLabel.Text = "💥 Radius Kill: " .. KillRadius .. " studs"
        end
    end)

    -- Clear placeholder text when clicked
    playerInput.Focused:Connect(function()
        if playerInput.Text == "Player Name" then
            playerInput.Text = ""
        end
    end)

    playerInput.FocusLost:Connect(function()
        if playerInput.Text == "" then
            playerInput.Text = "Player Name"
        end
    end)
end

-- INPUT CONTROL (Hotkeys)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.K then
        -- Kill All Players hotkey
        print("💀 Hotkey activated: Mass Kill initiated...")
        KillAllPlayers()
    elseif input.KeyCode == Enum.KeyCode.R then
        -- Radius Kill hotkey
        print("💥 Hotkey activated: Radius Kill initiated...")
        KillInRadius()
    elseif input.KeyCode == Enum.KeyCode.T then
        -- Toggle Auto Kill hotkey
        ToggleAutoKill()
    elseif input.KeyCode == Enum.KeyCode.G then
        -- Toggle GUI
        toggleGUI()
    end
end)

-- Handle character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- INIT GUI
buildKillGUI()

print("💀 ADVANCED KILL SYSTEM LOADED! 💀")
print("========================================")
print("🔴 EXTREME GRIEFING TOOL - USE RESPONSIBLY!")
print("========================================")
print("Hotkeys:")
print("K - Kill All Players")
print("R - Radius Kill")
print("T - Toggle Auto Kill")
print("G - Toggle GUI")
print("========================================")
print("Kill Methods:")
print("• Health: Set health to 0 (safest)")
print("• Destroy: Destroy character (fast)")
print("• RootPart: Remove HumanoidRootPart (clean)")
print("• Multiple: All methods combined (brutal)")
print("========================================")
print("Features:")
print("✅ Kill All Players")
print("✅ Kill Specific Player")
print("✅ Radius Kill (adjustable range)")
print("✅ Auto Kill (kills anyone who spawns)")
print("✅ Multiple kill methods")
print("✅ Draggable GUI")
print("========================================")
print("⚠️ WARNING: High detection risk!")
print("⚠️ Use in private servers or games with weak anti-cheat")
print("⚠️ This tool is for educational purposes only!")
print("========================================")
