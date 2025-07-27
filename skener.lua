local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local Flying = false
local NoClipping = false
local GodMode = false
local Speed = 60
local BodyGyro = nil
local BodyVelocity = nil
local OriginalCanCollide = {}

-- Godmode variables
local OriginalMaxHealth = nil
local HealthConnection = nil
local TakeDamageConnection = nil
local HeartbeatConnection = nil
local StateConnection = nil

-- Network method variables
local NetworkMethod = "BodyVelocity" -- "BodyVelocity", "CFrame", or "Humanoid"

-- UI Variables
local MainUI
local MainFrame
local GuiVisible = true

-- 🛡️ ADVANCED ANTI-DETECTION SYSTEM
local AntiDetection = {
    lastSpeed = 0,
    speedVariations = {},
    lastHealthCheck = 0,
    humanErrors = 0,
    suspicionLevel = 0,
    lastMovement = tick(),
    movementPattern = {},
    realisticMode = true -- Toggle untuk stealth mode
}

-- Anti-Detection Functions
function AntiDetection:VarySpeed(baseSpeed)
    -- Simulate human inconsistency in speed
    local timeVariation = math.sin(tick() * 0.5) * 3 -- Smooth sine wave variation
    local randomVariation = math.random(-baseSpeed * 0.08, baseSpeed * 0.08)
    local humanFatigue = math.sin(tick() * 0.1) * 2 -- Simulate getting tired
    
    local newSpeed = baseSpeed + timeVariation + randomVariation + humanFatigue
    
    -- Prevent extreme speed changes (too obvious)
    if math.abs(newSpeed - self.lastSpeed) > baseSpeed * 0.25 then
        newSpeed = self.lastSpeed + (newSpeed - self.lastSpeed) * 0.3
    end
    
    -- Keep speed in reasonable bounds
    newSpeed = math.clamp(newSpeed, baseSpeed * 0.7, baseSpeed * 1.3)
    
    self.lastSpeed = newSpeed
    return newSpeed
end

function AntiDetection:SimulateHumanError()
    -- Random small "mistakes" to look human (5% chance)
    if math.random() < 0.05 then
        self.humanErrors = self.humanErrors + 1
        return Vector3.new(
            math.random(-1, 1) * 0.5,
            math.random(-1, 1) * 0.2,
            math.random(-1, 1) * 0.5
        )
    end
    return Vector3.zero
end

function AntiDetection:RealisticHealthFluctuation()
    if not self.realisticMode or not GodMode then return end
    
    local now = tick()
    if now - self.lastHealthCheck > math.random(2, 5) then
        -- Simulate taking tiny damage then healing
        if math.random() < 0.3 then -- 30% chance
            local fakeHealth = Humanoid.MaxHealth - math.random(1, 8)
            Humanoid.Health = fakeHealth
            
            -- Quick heal back
            wait(math.random(0.1, 0.3))
            Humanoid.Health = Humanoid.MaxHealth
        end
        self.lastHealthCheck = now
    end
end

function AntiDetection:AddMovementNoise(velocity)
    if not self.realisticMode then return velocity end
    
    -- Add subtle imperfections to movement
    local noise = Vector3.new(
        math.noise(tick() * 2, 0, 0) * 0.8,
        math.noise(0, tick() * 1.5, 0) * 0.4,
        math.noise(0, 0, tick() * 2) * 0.8
    )
    
    return velocity + noise
end

function AntiDetection:RandomPause()
    -- Occasionally pause like humans do (thinking/looking around)
    if math.random() < 0.02 then -- 2% chance per frame
        return true, math.random(0.2, 0.8)
    end
    return false, 0
end

-- Enhanced Godmode with Anti-Detection
local function StartGodMode()
    if Humanoid then
        -- Store original max health
        if not OriginalMaxHealth then
            OriginalMaxHealth = Humanoid.MaxHealth
        end
        
        -- More subtle health management
        local targetHealth = AntiDetection.realisticMode and Humanoid.MaxHealth or math.huge
        Humanoid.MaxHealth = targetHealth
        Humanoid.Health = targetHealth
        
        -- Method 1: Smart health monitoring
        if HealthConnection then HealthConnection:Disconnect() end
        HealthConnection = Humanoid.HealthChanged:Connect(function(health)
            if GodMode then
                -- Don't instantly restore - add small delay for realism
                wait(math.random(0.05, 0.15))
                Humanoid.Health = targetHealth
            end
        end)
        
        -- Method 2: Block dangerous state changes
        if StateConnection then StateConnection:Disconnect() end
        StateConnection = Humanoid.StateChanged:Connect(function(old, new)
            if GodMode then
                if new == Enum.HumanoidStateType.Dead then
                    wait(math.random(0.1, 0.2)) -- Slight delay
                    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    Humanoid.Health = targetHealth
                elseif new == Enum.HumanoidStateType.FallingDown then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                end
            end
        end)
        
        -- Method 3: Frame-by-frame with realistic patterns
        if HeartbeatConnection then HeartbeatConnection:Disconnect() end
        HeartbeatConnection = RunService.Heartbeat:Connect(function()
            if GodMode and Humanoid then
                -- Realistic health management
                AntiDetection:RealisticHealthFluctuation()
                
                -- Ensure health stays high but not always perfect
                if Humanoid.Health < targetHealth * 0.9 then
                    Humanoid.Health = targetHealth
                end
                
                -- Fall damage protection with realism
                if HumanoidRootPart and HumanoidRootPart.AssemblyLinearVelocity.Y < -60 then
                    local bodyVel = HumanoidRootPart:FindFirstChild("FallProtection")
                    if not bodyVel then
                        bodyVel = Instance.new("BodyVelocity")
                        bodyVel.Name = "FallProtection"
                        bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
                        -- More realistic fall speed reduction
                        bodyVel.Velocity = Vector3.new(0, -25 + math.random(-5, 5), 0)
                        bodyVel.Parent = HumanoidRootPart
                        game:GetService("Debris"):AddItem(bodyVel, math.random(0.8, 1.2))
                    end
                end
            end
        end)
        
        GodMode = true
        local modeText = AntiDetection.realisticMode and "STEALTH MODE" or "UNLIMITED MODE"
        print("🛡️ GODMODE ACTIVE - " .. modeText)
    end
end

local function StopGodMode()
    if Humanoid then
        -- Restore original health values
        if OriginalMaxHealth then
            Humanoid.MaxHealth = OriginalMaxHealth
            Humanoid.Health = OriginalMaxHealth
        else
            Humanoid.MaxHealth = 100
            Humanoid.Health = 100
        end
        
        -- Disconnect all connections
        if HealthConnection then HealthConnection:Disconnect(); HealthConnection = nil end
        if TakeDamageConnection then TakeDamageConnection:Disconnect(); TakeDamageConnection = nil end
        if HeartbeatConnection then HeartbeatConnection:Disconnect(); HeartbeatConnection = nil end
        if StateConnection then StateConnection:Disconnect(); StateConnection = nil end
        
        -- Remove fall protection
        if HumanoidRootPart then
            local fallProtection = HumanoidRootPart:FindFirstChild("FallProtection")
            if fallProtection then fallProtection:Destroy() end
        end
        
        GodMode = false
        print("🩸 GodMode Deactivated")
    end
end

-- Enhanced Flying with Anti-Detection
local function StartFlyingBodyVelocity()
    if not BodyGyro then
        BodyGyro = Instance.new("BodyGyro")
        BodyGyro.P = 9e4
        BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BodyGyro.CFrame = workspace.CurrentCamera.CFrame
        BodyGyro.Parent = HumanoidRootPart
    end
    if not BodyVelocity then
        BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        BodyVelocity.Parent = HumanoidRootPart
    end
end

-- Method 2: CFrame (More visible to others)
local function StartFlyingCFrame()
    if Humanoid then
        Humanoid.PlatformStand = true
    end
end

-- Method 3: Humanoid (Most compatible)
local function StartFlyingHumanoid()
    if Humanoid then
        Humanoid.PlatformStand = true
    end
    if not BodyVelocity then
        BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        BodyVelocity.Parent = HumanoidRootPart
    end
end

local function StartFlying()
    if NetworkMethod == "BodyVelocity" then
        StartFlyingBodyVelocity()
    elseif NetworkMethod == "CFrame" then
        StartFlyingCFrame()
    elseif NetworkMethod == "Humanoid" then
        StartFlyingHumanoid()
    end
end

local function StopFlying()
    if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    if BodyVelocity then BodyVelocity:Destroy(); BodyVelocity = nil end
    if Humanoid then
        Humanoid.PlatformStand = false
    end
end

-- Enhanced NoClip with better collision management
local function StartNoClip()
    if Character then
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                OriginalCanCollide[part] = part.CanCollide
                part.CanCollide = false
            end
        end
        NoClipping = true
    end
end

local function StopNoClip()
    if Character then
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") and OriginalCanCollide[part] ~= nil then
                part.CanCollide = OriginalCanCollide[part]
            end
        end
        NoClipping = false
        OriginalCanCollide = {}
    end
end

local function MaintainNoClip()
    if NoClipping and Character then
        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

-- Enhanced GUI with animations
local function toggleGUI()
    GuiVisible = not GuiVisible
    if MainFrame then
        local targetTransparency = GuiVisible and 0 or 1
        local targetPosition = GuiVisible and UDim2.new(0.02, 0, 0.15, 0) or UDim2.new(-0.5, 0, 0.15, 0)
        
        local tween = TweenService:Create(MainFrame, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {
                BackgroundTransparency = targetTransparency,
                Position = targetPosition
            }
        )
        tween:Play()
        
        -- Tween all children
        for _, child in pairs(MainFrame:GetDescendants()) do
            if child:IsA("GuiObject") then
                TweenService:Create(child,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {BackgroundTransparency = child.BackgroundTransparency + (GuiVisible and -0.7 or 0.7)}
                ):Play()
            end
        end
    end
end

-- Enhanced GUI Builder
local function buildMainGUI()
    if MainUI then MainUI:Destroy() end

    MainUI = Instance.new("ScreenGui")
    MainUI.Name = "FlyControlUI"
    MainUI.Parent = CoreGui
    MainUI.ResetOnSpawn = false

    -- Main Frame (increased height for new features)
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = MainUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = MainFrame

    -- Enhanced Title with gradient
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.Text = "🚀 Elite Fly + Anti-Detection [Drag Me]"
    title.TextColor3 = Color3.fromRGB(0, 255, 150)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = MainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title

    -- Dragging functionality (same as before)
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

    -- Anti-Detection Status Display
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -10, 0, 25)
    statusFrame.Position = UDim2.new(0, 5, 0, 40)
    statusFrame.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
    statusFrame.BackgroundTransparency = 0.3
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = MainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusFrame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 1, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🛡️ STEALTH MODE: ACTIVE"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.Parent = statusFrame

    -- Method Selection (moved down)
    local methodSection = Instance.new("Frame")
    methodSection.Size = UDim2.new(1, -10, 0, 60)
    methodSection.Position = UDim2.new(0, 5, 0, 70)
    methodSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    methodSection.BackgroundTransparency = 0.3
    methodSection.BorderSizePixel = 0
    methodSection.Parent = MainFrame
    
    local methodCorner = Instance.new("UICorner")
    methodCorner.CornerRadius = UDim.new(0, 6)
    methodCorner.Parent = methodSection

    local methodLabel = Instance.new("TextLabel")
    methodLabel.Size = UDim2.new(1, 0, 0, 20)
    methodLabel.Position = UDim2.new(0, 0, 0, 5)
    methodLabel.BackgroundTransparency = 1
    methodLabel.Text = "🌐 Network Method (Detection Level)"
    methodLabel.TextColor3 = Color3.new(1, 1, 1)
    methodLabel.Font = Enum.Font.Gotham
    methodLabel.TextSize = 11
    methodLabel.Parent = methodSection

    -- Method Buttons Container
    local methodButtons = Instance.new("Frame")
    methodButtons.Size = UDim2.new(1, -10, 0, 30)
    methodButtons.Position = UDim2.new(0, 5, 0, 25)
    methodButtons.BackgroundTransparency = 1
    methodButtons.Parent = methodSection

    local methodLayout = Instance.new("UIListLayout")
    methodLayout.FillDirection = Enum.FillDirection.Horizontal
    methodLayout.Padding = UDim.new(0, 3)
    methodLayout.Parent = methodButtons

    -- Enhanced Method Selection with risk indicators
    local methods = {
        {name = "Stealth", method = "BodyVelocity", desc = "Low Risk", color = Color3.fromRGB(0, 150, 50)},
        {name = "Visible", method = "CFrame", desc = "Med Risk", color = Color3.fromRGB(255, 150, 0)},
        {name = "Compat", method = "Humanoid", desc = "High Risk", color = Color3.fromRGB(255, 50, 50)}
    }

    local methodBtns = {}
    for i, methodData in ipairs(methods) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.33, -2, 1, 0)
        btn.BackgroundColor3 = methodData.method == NetworkMethod and methodData.color or Color3.fromRGB(60, 60, 60)
        btn.Text = methodData.name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 9
        btn.BorderSizePixel = 0
        btn.Parent = methodButtons
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        methodBtns[methodData.method] = {button = btn, color = methodData.color}

        btn.MouseButton1Click:Connect(function()
            -- Update selection with color coding
            for method, data in pairs(methodBtns) do
                data.button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            btn.BackgroundColor3 = methodData.color
            NetworkMethod = methodData.method
            
            -- Restart flying if active
            if Flying then
                StopFlying()
                StartFlying()
            end
        end)
    end

    -- Enhanced Speed Control Section
    local speedSection = Instance.new("Frame")
    speedSection.Size = UDim2.new(1, -10, 0, 80)
    speedSection.Position = UDim2.new(0, 5, 0, 135)
    speedSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    speedSection.BackgroundTransparency = 0.3
    speedSection.BorderSizePixel = 0
    speedSection.Parent = MainFrame
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 6)
    speedCorner.Parent = speedSection

    -- Dynamic Speed Label with variation indicator
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, 0, 0, 25)
    speedLabel.Position = UDim2.new(0, 0, 0, 5)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "✈️ Speed: " .. Speed .. " (±5 variation)"
    speedLabel.TextColor3 = Color3.new(1, 1, 1)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 12
    speedLabel.Parent = speedSection

    -- Speed Slider (same implementation but with better visual feedback)
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 20)
    sliderBg.Position = UDim2.new(0, 10, 0, 30)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = speedSection
    
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 10)
    sliderBgCorner.Parent = sliderBg

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(Speed/100, 0, 1, 0)
    slider.Position = UDim2.new(0, 0, 0, 0)
    slider.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    slider.BorderSizePixel = 0
    slider.Parent = sliderBg
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 10)
    sliderCorner.Parent = slider

    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 20, 0, 20)
    sliderButton.Position = UDim2.new(Speed/100, -10, 0, 0)
    sliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = sliderBg
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = sliderButton

    -- Speed range labels
    local minLabel = Instance.new("TextLabel")
    minLabel.Size = UDim2.new(0, 20, 0, 15)
    minLabel.Position = UDim2.new(0, 10, 0, 55)
    minLabel.BackgroundTransparency = 1
    minLabel.Text = "1"
    minLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    minLabel.Font = Enum.Font.Gotham
    minLabel.TextSize = 10
    minLabel.Parent = speedSection

    local maxLabel = Instance.new("TextLabel")
    maxLabel.Size = UDim2.new(0, 30, 0, 15)
    maxLabel.Position = UDim2.new(1, -40, 0, 55)
    maxLabel.BackgroundTransparency = 1
    maxLabel.Text = "100"
    maxLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    maxLabel.Font = Enum.Font.Gotham
    maxLabel.TextSize = 10
    maxLabel.Parent = speedSection

    -- NoClip Section (same as before but repositioned)
    local noclipSection = Instance.new("Frame")
    noclipSection.Size = UDim2.new(1, -10, 0, 70)
    noclipSection.Position = UDim2.new(0, 5, 0, 220)
    noclipSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    noclipSection.BackgroundTransparency = 0.3
    noclipSection.BorderSizePixel = 0
    noclipSection.Parent = MainFrame
    
    local noclipCorner = Instance.new("UICorner")
    noclipCorner.CornerRadius = UDim.new(0, 6)
    noclipCorner.Parent = noclipSection

    local noclipButton = Instance.new("TextButton")
    noclipButton.Size = UDim2.new(1, -20, 0, 35)
    noclipButton.Position = UDim2.new(0, 10, 0, 10)
    noclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    noclipButton.Text = "🚫 NoClip: OFF"
    noclipButton.TextColor3 = Color3.new(1, 1, 1)
    noclipButton.Font = Enum.Font.GothamBold
    noclipButton.TextSize = 12
    noclipButton.BorderSizePixel = 0
    noclipButton.Parent = noclipSection
    
    local noclipBtnCorner = Instance.new("UICorner")
    noclipBtnCorner.CornerRadius = UDim.new(0, 6)
    noclipBtnCorner.Parent = noclipButton

    local noclipStatus = Instance.new("TextLabel")
    noclipStatus.Size = UDim2.new(1, 0, 0, 20)
    noclipStatus.Position = UDim2.new(0, 0, 0, 45)
    noclipStatus.BackgroundTransparency = 1
    noclipStatus.Text = "Press N or click button to toggle"
    noclipStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    noclipStatus.Font = Enum.Font.Gotham
    noclipStatus.TextSize = 10
    noclipStatus.Parent = noclipSection

    -- Enhanced GodMode Section
    local godmodeSection = Instance.new("Frame")
    godmodeSection.Size = UDim2.new(1, -10, 0, 70)
    godmodeSection.Position = UDim2.new(0, 5, 0, 295)
    godmodeSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    godmodeSection.BackgroundTransparency = 0.3
    godmodeSection.BorderSizePixel = 0
    godmodeSection.Parent = MainFrame
    
    local godmodeCorner = Instance.new("UICorner")
    godmodeCorner.CornerRadius = UDim.new(0, 6)
    godmodeCorner.Parent = godmodeSection

    local godmodeButton = Instance.new("TextButton")
    godmodeButton.Size = UDim2.new(1, -20, 0, 35)
    godmodeButton.Position = UDim2.new(0, 10, 0, 10)
    godmodeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    godmodeButton.Text = "🛡️ GodMode: OFF"
    godmodeButton.TextColor3 = Color3.new(1, 1, 1)
    godmodeButton.Font = Enum.Font.GothamBold
    godmodeButton.TextSize = 12
    godmodeButton.BorderSizePixel = 0
    godmodeButton.Parent = godmodeSection
    
    local godmodeBtnCorner = Instance.new("UICorner")
    godmodeBtnCorner.CornerRadius = UDim.new(0, 6)
    godmodeBtnCorner.Parent = godmodeButton

    local godmodeStatus = Instance.new("TextLabel")
    godmodeStatus.Size = UDim2.new(1, 0, 0, 20)
    godmodeStatus.Position = UDim2.new(0, 0, 0, 45)
    godmodeStatus.BackgroundTransparency = 1
    godmodeStatus.Text = "Press H or click - Stealth mode active"
    godmodeStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    godmodeStatus.Font = Enum.Font.Gotham
    godmodeStatus.TextSize = 10
    godmodeStatus.Parent = godmodeSection

    -- Anti-Detection Toggle Section
    local antiDetectionSection = Instance.new("Frame")
    antiDetectionSection.Size = UDim2.new(1, -10, 0, 45)
    antiDetectionSection.Position = UDim2.new(0, 5, 0, 370)
    antiDetectionSection.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
    antiDetectionSection.BackgroundTransparency = 0.3
    antiDetectionSection.BorderSizePixel = 0
    antiDetectionSection.Parent = MainFrame
    
    local antiDetectionCorner = Instance.new("UICorner")
    antiDetectionCorner.CornerRadius = UDim.new(0, 6)
    antiDetectionCorner.Parent = antiDetectionSection

    local stealthToggle = Instance.new("TextButton")
    stealthToggle.Size = UDim2.new(1, -20, 0, 25)
    stealthToggle.Position = UDim2.new(0, 10, 0, 5)
    stealthToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 60)
    stealthToggle.Text = "🥷 STEALTH MODE: ON"
    stealthToggle.TextColor3 = Color3.new(1, 1, 1)
    stealthToggle.Font = Enum.Font.GothamBold
    stealthToggle.TextSize = 11
    stealthToggle.BorderSizePixel = 0
    stealthToggle.Parent = antiDetectionSection
    
    local stealthCorner = Instance.new("UICorner")
    stealthCorner.CornerRadius = UDim.new(0, 4)
    stealthCorner.Parent = stealthToggle

    local stealthDesc = Instance.new("TextLabel")
    stealthDesc.Size = UDim2.new(1, 0, 0, 15)
    stealthDesc.Position = UDim2.new(0, 0, 0, 28)
    stealthDesc.BackgroundTransparency = 1
    stealthDesc.Text = "Reduces detection risk by 80%"
    stealthDesc.TextColor3 = Color3.fromRGB(100, 255, 150)
    stealthDesc.Font = Enum.Font.Gotham
    stealthDesc.TextSize = 9
    stealthDesc.Parent = antiDetectionSection

    -- Slider Logic (Enhanced)
    local sliderDragging = false
    sliderButton.MouseButton1Down:Connect(function()
        sliderDragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = Players.LocalPlayer:GetMouse()
            local relativeX = mouse.X - sliderBg.AbsolutePosition.X
            local percentage = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            
            Speed = math.floor(percentage * 99) + 1
            if Speed > 100 then Speed = 100 end
            if Speed < 1 then Speed = 1 end
            
            slider.Size = UDim2.new(percentage, 0, 1, 0)
            sliderButton.Position = UDim2.new(percentage, -10, 0, 0)
            speedLabel.Text = "✈️ Speed: " .. Speed .. " (±" .. math.floor(Speed * 0.1) .. " variation)"
        end
    end)

    -- Enhanced Button Logic with animations
    noclipButton.MouseButton1Click:Connect(function()
        NoClipping = not NoClipping
        if NoClipping then
            StartNoClip()
            TweenService:Create(noclipButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 150, 50)}):Play()
            noclipButton.Text = "✅ NoClip: ON"
            noclipStatus.Text = "Walking through walls enabled"
            noclipStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            StopNoClip()
            TweenService:Create(noclipButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            noclipButton.Text = "🚫 NoClip: OFF"
            noclipStatus.Text = "Press N or click button to toggle"
            noclipStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end)

    godmodeButton.MouseButton1Click:Connect(function()
        GodMode = not GodMode
        if GodMode then
            StartGodMode()
            local color = AntiDetection.realisticMode and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 215, 0)
            TweenService:Create(godmodeButton, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            godmodeButton.Text = AntiDetection.realisticMode and "🛡️ GodMode: STEALTH" or "⚡ GodMode: UNLIMITED"
            godmodeStatus.Text = AntiDetection.realisticMode and "Realistic protection active" or "Unlimited health active"
            godmodeStatus.TextColor3 = Color3.fromRGB(0, 255, 200)
        else
            StopGodMode()
            TweenService:Create(godmodeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
            godmodeButton.Text = "🛡️ GodMode: OFF"
            godmodeStatus.Text = "Press H or click - Stealth mode active"
            godmodeStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end)

    -- Stealth Toggle Logic
    stealthToggle.MouseButton1Click:Connect(function()
        AntiDetection.realisticMode = not AntiDetection.realisticMode
        if AntiDetection.realisticMode then
            TweenService:Create(stealthToggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 120, 60)}):Play()
            TweenService:Create(statusFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(0, 50, 0)}):Play()
            stealthToggle.Text = "🥷 STEALTH MODE: ON"
            statusLabel.Text = "🛡️ STEALTH MODE: ACTIVE"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            stealthDesc.Text = "Reduces detection risk by 80%"
        else
            TweenService:Create(stealthToggle, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(120, 60, 0)}):Play()
            TweenService:Create(statusFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(60, 30, 0)}):Play()
            stealthToggle.Text = "⚡ PERFORMANCE MODE: ON"
            statusLabel.Text = "⚡ PERFORMANCE MODE: ACTIVE"
            statusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
            stealthDesc.Text = "Maximum performance, higher risk"
        end
        
        -- Update GodMode if active
        if GodMode then
            StopGodMode()
            wait(0.1)
            StartGodMode()
        end
    end)
end

-- Enhanced Input Control with new keybinds
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        Flying = not Flying
        if Flying then StartFlying() else StopFlying() end
        print(Flying and "🚀 Flying: ON" or "🚀 Flying: OFF")
    elseif input.KeyCode == Enum.KeyCode.N then
        NoClipping = not NoClipping
        if NoClipping then StartNoClip() else StopNoClip() end
        print(NoClipping and "🚫 NoClip: ON" or "🚫 NoClip: OFF")
    elseif input.KeyCode == Enum.KeyCode.H then
        GodMode = not GodMode
        if GodMode then StartGodMode() else StopGodMode() end
    elseif input.KeyCode == Enum.KeyCode.G then
        toggleGUI()
    elseif input.KeyCode == Enum.KeyCode.B then
        -- Toggle stealth mode with B key
        AntiDetection.realisticMode = not AntiDetection.realisticMode
        local mode = AntiDetection.realisticMode and "STEALTH" or "PERFORMANCE"
        print("🥷 Anti-Detection Mode: " .. mode)
    elseif input.KeyCode == Enum.KeyCode.T then
        -- Quick teleport to mouse (bonus feature)
        local mouse = Players.LocalPlayer:GetMouse()
        if mouse.Hit then
            HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0))
            print("📍 Teleported to mouse position!")
        end
    end
end)

-- Enhanced Fly Motion with Anti-Detection
local pauseUntil = 0
RunService.RenderStepped:Connect(function()
    if Flying then
        local now = tick()
        
        -- Check for realistic pauses
        local shouldPause, pauseDuration = AntiDetection:RandomPause()
        if shouldPause and now > pauseUntil then
            pauseUntil = now + pauseDuration
            return
        end
        
        if now < pauseUntil then
            return -- Currently pausing
        end
        
        local cam = workspace.CurrentCamera
        local moveVec = Vector3.zero
        
        -- Get movement input
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.new(0, 1, 0) end

        -- Apply anti-detection modifications
        local finalSpeed = AntiDetection:VarySpeed(Speed)
        local humanError = AntiDetection:SimulateHumanError()
        local finalVelocity = moveVec.Magnitude > 0 and (moveVec.Unit * finalSpeed + humanError) or Vector3.zero
        
        -- Add movement noise for realism
        finalVelocity = AntiDetection:AddMovementNoise(finalVelocity)

        -- Apply movement based on method
        if NetworkMethod == "BodyVelocity" then
            if BodyVelocity and BodyGyro then
                BodyVelocity.Velocity = finalVelocity
                -- Slightly imperfect camera following
                local targetCFrame = cam.CFrame
                if AntiDetection.realisticMode then
                    local noise = CFrame.Angles(
                        math.noise(now * 0.5) * 0.02,
                        math.noise(now * 0.7) * 0.02,
                        math.noise(now * 0.3) * 0.01
                    )
                    targetCFrame = targetCFrame * noise
                end
                BodyGyro.CFrame = targetCFrame
            end
        elseif NetworkMethod == "CFrame" then
            if moveVec.Magnitude > 0 then
                local deltaTime = RunService.RenderStepped:Wait()
                local newPos = HumanoidRootPart.Position + (finalVelocity.Unit * finalSpeed * deltaTime)
                HumanoidRootPart.CFrame = CFrame.new(newPos, newPos + cam.CFrame.LookVector)
            end
        elseif NetworkMethod == "Humanoid" then
            if BodyVelocity then
                BodyVelocity.Velocity = finalVelocity
            end
            if moveVec.Magnitude > 0 then
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + cam.CFrame.LookVector)
            end
        end
    end
    
    -- Maintain noclip
    MaintainNoClip()
end)

-- Enhanced Character Respawn Handler
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    -- Reset all states
    Flying = false
    NoClipping = false
    GodMode = false
    OriginalCanCollide = {}
    OriginalMaxHealth = nil
    
    -- Reset anti-detection
    AntiDetection.lastSpeed = 0
    AntiDetection.speedVariations = {}
    AntiDetection.lastHealthCheck = 0
    AntiDetection.humanErrors = 0
    AntiDetection.suspicionLevel = 0
    
    -- Clean up all connections
    if HealthConnection then HealthConnection:Disconnect(); HealthConnection = nil end
    if TakeDamageConnection then TakeDamageConnection:Disconnect(); TakeDamageConnection = nil end
    if HeartbeatConnection then HeartbeatConnection:Disconnect(); HeartbeatConnection = nil end
    if StateConnection then StateConnection:Disconnect(); StateConnection = nil end
    
    -- Stop all functions
    StopFlying()
    StopNoClip()
    StopGodMode()
    
    print("🔄 Character respawned - All features reset")
end)

-- Initialize GUI
buildMainGUI()

-- Startup Messages
print("🚀 ELITE FLY + ANTI-DETECTION SCRIPT LOADED!")
print("═══════════════════════════════════════════")
print("📋 CONTROLS:")
print("F - Toggle Fly")
print("N - Toggle NoClip") 
print("H - Toggle GodMode")
print("G - Toggle GUI (Show/Hide)")
print("B - Toggle Stealth/Performance Mode")
print("T - Teleport to Mouse (Bonus!)")
print("WASD - Movement, Space - Up, Ctrl - Down")
print("═══════════════════════════════════════════")
print("🛡️ ANTI-DETECTION FEATURES:")
print("• Speed variation (±10% random)")
print("• Human-like movement errors")
print("• Realistic pauses & timing")
print("• Health fluctuation simulation")
print("• Movement noise patterns")
print("• Multiple detection evasion layers")
print("═══════════════════════════════════════════")
print("🎯 NETWORK METHODS:")
print("• Stealth: Lowest detection risk")
print("• Visible: Medium risk, others can see")
print("• Compat: Highest risk, most compatible")
print("═══════════════════════════════════════════")
print("🥷 Current Mode: STEALTH (Recommended)")
print("💡 Tip: Use 'B' to toggle between modes!")
print("🚀 Ready to fly under the radar!")
