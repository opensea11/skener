local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

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

-- Bring All Players variables
local BringRadius = 10
local BringHeight = 5

local MainUI
local MainFrame
local GuiVisible = true

-- BRING ALL PLAYERS FUNCTIONS
local function BringAllPlayers()
	if not HumanoidRootPart then return end
	
	local myPosition = HumanoidRootPart.Position
	local playersFound = 0
	local playersBrought = 0
	
	print("🌀 Starting Bring All Players...")
	
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer ~= Player then
			playersFound = playersFound + 1
			
			pcall(function()
				if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local targetRoot = targetPlayer.Character.HumanoidRootPart
					
					-- Calculate random position around player
					local angle = math.rad(math.random(0, 360))
					local distance = math.random(3, BringRadius)
					
					local offsetX = math.sin(angle) * distance
					local offsetZ = math.cos(angle) * distance
					local offsetY = BringHeight
					
					local newPosition = myPosition + Vector3.new(offsetX, offsetY, offsetZ)
					
					-- Method 1: Direct CFrame manipulation
					targetRoot.CFrame = CFrame.new(newPosition)
					
					-- Method 2: Velocity-based (more natural)
					local bodyVel = targetRoot:FindFirstChild("BringVelocity")
					if not bodyVel then
						bodyVel = Instance.new("BodyVelocity")
						bodyVel.Name = "BringVelocity"
						bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
						bodyVel.Parent = targetRoot
						
						-- Auto cleanup after 2 seconds
						game:GetService("Debris"):AddItem(bodyVel, 2)
					end
					
					local direction = (newPosition - targetRoot.Position).Unit
					bodyVel.Velocity = direction * 50
					
					playersBrought = playersBrought + 1
					print("✅ Brought: " .. targetPlayer.Name)
				else
					print("❌ Failed: " .. targetPlayer.Name .. " (No character)")
				end
			end)
			
			-- Small delay to prevent lag
			wait(0.05)
		end
	end
	
	print("🎯 Bring Complete! " .. playersBrought .. "/" .. playersFound .. " players brought")
end

local function BringSpecificPlayer(playerName)
	local targetPlayer = Players:FindFirstChild(playerName)
	if not targetPlayer then
		print("❌ Player not found: " .. playerName)
		return false
	end
	
	if targetPlayer == Player then
		print("❌ Cannot bring yourself!")
		return false
	end
	
	pcall(function()
		if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local targetRoot = targetPlayer.Character.HumanoidRootPart
			local myPosition = HumanoidRootPart.Position
			
			-- Position in front of player
			local newPosition = myPosition + (HumanoidRootPart.CFrame.LookVector * 5)
			targetRoot.CFrame = CFrame.new(newPosition)
			
			print("✅ Brought player: " .. targetPlayer.Name)
			return true
		else
			print("❌ Player has no character: " .. targetPlayer.Name)
			return false
		end
	end)
end

-- GODMODE FUNCTIONS (unchanged)
local function StartGodMode()
	if Humanoid then
		-- Store original max health
		if not OriginalMaxHealth then
			OriginalMaxHealth = Humanoid.MaxHealth
		end
		
		-- FORCE UNLIMITED HEALTH - Multiple methods
		Humanoid.MaxHealth = math.huge
		Humanoid.Health = math.huge
		
		-- Method 1: Health monitoring (instant restore)
		if HealthConnection then HealthConnection:Disconnect() end
		HealthConnection = Humanoid.HealthChanged:Connect(function(health)
			if GodMode then
				Humanoid.MaxHealth = math.huge
				Humanoid.Health = math.huge
			end
		end)
		
		-- Method 2: Block state changes that can kill
		if StateConnection then StateConnection:Disconnect() end
		StateConnection = Humanoid.StateChanged:Connect(function(old, new)
			if GodMode then
				if new == Enum.HumanoidStateType.Dead then
					Humanoid:ChangeState(Enum.HumanoidStateType.Running)
					Humanoid.Health = math.huge
				elseif new == Enum.HumanoidStateType.FallingDown then
					Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
				end
			end
		end)
		
		-- Method 3: Frame-by-frame forced unlimited health
		if HeartbeatConnection then HeartbeatConnection:Disconnect() end
		HeartbeatConnection = RunService.Heartbeat:Connect(function()
			if GodMode and Humanoid then
				-- Force unlimited health every frame
				if Humanoid.MaxHealth ~= math.huge then
					Humanoid.MaxHealth = math.huge
				end
				if Humanoid.Health ~= math.huge then
					Humanoid.Health = math.huge
				end
				
				-- Disable fall damage states
				pcall(function()
					Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				end)
				
				-- Slow down extreme falls
				if HumanoidRootPart and HumanoidRootPart.AssemblyLinearVelocity.Y < -80 then
					local bodyVel = HumanoidRootPart:FindFirstChild("FallProtection")
					if not bodyVel then
						bodyVel = Instance.new("BodyVelocity")
						bodyVel.Name = "FallProtection"
						bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
						bodyVel.Velocity = Vector3.new(0, -30, 0)
						bodyVel.Parent = HumanoidRootPart
						game:GetService("Debris"):AddItem(bodyVel, 1)
					end
				end
			end
		end)
		
		-- Method 4: Block damage functions
		pcall(function()
			if TakeDamageConnection then TakeDamageConnection:Disconnect() end
			local takeDamage = Humanoid:FindFirstChild("TakeDamage")
			if takeDamage then
				TakeDamageConnection = takeDamage:Connect(function()
					Humanoid.Health = math.huge
					return false -- Block damage
				end)
			end
		end)
		
		-- Method 5: Block death event
		pcall(function()
			Humanoid.Died:Connect(function()
				if GodMode then
					wait()
					Humanoid.Health = math.huge
					Humanoid.MaxHealth = math.huge
					Humanoid:ChangeState(Enum.HumanoidStateType.Running)
				end
			end)
		end)
		
		GodMode = true
		print("🛡️ UNLIMITED HEALTH ACTIVE - Completely invincible!")
		print("Health: ∞ | MaxHealth: ∞")
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
		
		-- Disconnect all godmode connections
		if HealthConnection then
			HealthConnection:Disconnect()
			HealthConnection = nil
		end
		
		if TakeDamageConnection then
			TakeDamageConnection:Disconnect()
			TakeDamageConnection = nil
		end
		
		if HeartbeatConnection then
			HeartbeatConnection:Disconnect()
			HeartbeatConnection = nil
		end
		
		if StateConnection then
			StateConnection:Disconnect()
			StateConnection = nil
		end
		
		-- Re-enable normal states
		pcall(function()
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		end)
		
		-- Remove fall protection
		if HumanoidRootPart then
			local fallProtection = HumanoidRootPart:FindFirstChild("FallProtection")
			if fallProtection then
				fallProtection:Destroy()
			end
		end
		
		GodMode = false
		print("🩸 GodMode Deactivated - Health back to normal")
	end
end

-- DIFFERENT FLY METHODS FOR VISIBILITY (unchanged)

-- Method 1: BodyVelocity (Local only, smoothest)
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
	-- Disable default physics
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

-- NOCLIP FUNCTIONS (unchanged)
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

-- TOGGLE GUI FUNCTION
local function toggleGUI()
	GuiVisible = not GuiVisible
	if MainFrame then
		MainFrame.Visible = GuiVisible
	end
end

-- GUI BUILDER (Updated with Bring Players section)
local function buildMainGUI()
	if MainUI then MainUI:Destroy() end

	MainUI = Instance.new("ScreenGui")
	MainUI.Name = "FlyControlUI"
	MainUI.Parent = CoreGui
	MainUI.ResetOnSpawn = false

	-- Main Frame (increased height for bring players section)
	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 300, 0, 460)
	MainFrame.Position = UDim2.new(0.02, 0, 0.15, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	MainFrame.BackgroundTransparency = 0.1
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = MainUI
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = MainFrame

	-- Title (Draggable)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 35)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	title.Text = "🚀 Enhanced Script + Bring Players [Drag Me]"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.Parent = MainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
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

	-- Hover effect for title
	title.MouseEnter:Connect(function()
		title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		title.Text = "🚀 Enhanced Script + Bring Players [Dragging...]"
	end)

	title.MouseLeave:Connect(function()
		title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		title.Text = "🚀 Enhanced Script + Bring Players [Drag Me]"
	end)

	-- Method Selection
	local methodSection = Instance.new("Frame")
	methodSection.Size = UDim2.new(1, -10, 0, 60)
	methodSection.Position = UDim2.new(0, 5, 0, 40)
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
	methodLabel.Text = "🌐 Network Method (Visibility)"
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

	-- Method Selection Buttons
	local methods = {
		{name = "Body", method = "BodyVelocity", desc = "Smooth"},
		{name = "CFrame", method = "CFrame", desc = "Visible"},
		{name = "Humanoid", method = "Humanoid", desc = "Compatible"}
	}

	local methodBtns = {}
	for i, methodData in ipairs(methods) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.33, -2, 1, 0)
		btn.BackgroundColor3 = methodData.method == NetworkMethod and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(60, 60, 60)
		btn.Text = methodData.name
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 10
		btn.BorderSizePixel = 0
		btn.Parent = methodButtons
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn

		methodBtns[methodData.method] = btn

		btn.MouseButton1Click:Connect(function()
			-- Update selection
			for method, button in pairs(methodBtns) do
				button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			end
			btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
			NetworkMethod = methodData.method
			
			-- Restart flying if active
			if Flying then
				StopFlying()
				StartFlying()
			end
		end)
	end

	-- Speed Control Section
	local speedSection = Instance.new("Frame")
	speedSection.Size = UDim2.new(1, -10, 0, 80)
	speedSection.Position = UDim2.new(0, 5, 0, 105)
	speedSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	speedSection.BackgroundTransparency = 0.3
	speedSection.BorderSizePixel = 0
	speedSection.Parent = MainFrame
	
	local speedCorner = Instance.new("UICorner")
	speedCorner.CornerRadius = UDim.new(0, 6)
	speedCorner.Parent = speedSection

	-- Speed Label
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1, 0, 0, 25)
	speedLabel.Position = UDim2.new(0, 0, 0, 5)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "✈️ Speed: " .. Speed
	speedLabel.TextColor3 = Color3.new(1, 1, 1)
	speedLabel.Font = Enum.Font.Gotham
	speedLabel.TextSize = 12
	speedLabel.Parent = speedSection

	-- Speed Slider Background
	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, -20, 0, 20)
	sliderBg.Position = UDim2.new(0, 10, 0, 30)
	sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = speedSection
	
	local sliderBgCorner = Instance.new("UICorner")
	sliderBgCorner.CornerRadius = UDim.new(0, 10)
	sliderBgCorner.Parent = sliderBg

	-- Speed Slider
	local slider = Instance.new("Frame")
	slider.Size = UDim2.new(Speed/100, 0, 1, 0)
	slider.Position = UDim2.new(0, 0, 0, 0)
	slider.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	slider.BorderSizePixel = 0
	slider.Parent = sliderBg
	
	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 10)
	sliderCorner.Parent = slider

	-- Speed Slider Button
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

	-- Speed Values
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

	-- BRING PLAYERS CONTROL SECTION (NEW!)
	local bringSection = Instance.new("Frame")
	bringSection.Size = UDim2.new(1, -10, 0, 100)
	bringSection.Position = UDim2.new(0, 5, 0, 190)
	bringSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	bringSection.BackgroundTransparency = 0.3
	bringSection.BorderSizePixel = 0
	bringSection.Parent = MainFrame
	
	local bringCorner = Instance.new("UICorner")
	bringCorner.CornerRadius = UDim.new(0, 6)
	bringCorner.Parent = bringSection

	-- Bring Section Title
	local bringTitle = Instance.new("TextLabel")
	bringTitle.Size = UDim2.new(1, 0, 0, 20)
	bringTitle.Position = UDim2.new(0, 0, 0, 5)
	bringTitle.BackgroundTransparency = 1
	bringTitle.Text = "🌀 Bring Players (Server-Side)"
	bringTitle.TextColor3 = Color3.new(1, 1, 1)
	bringTitle.Font = Enum.Font.GothamBold
	bringTitle.TextSize = 11
	bringTitle.Parent = bringSection

	-- Bring All Button
	local bringAllButton = Instance.new("TextButton")
	bringAllButton.Size = UDim2.new(0.48, 0, 0, 30)
	bringAllButton.Position = UDim2.new(0, 10, 0, 25)
	bringAllButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	bringAllButton.Text = "🌀 Bring ALL"
	bringAllButton.TextColor3 = Color3.new(1, 1, 1)
	bringAllButton.Font = Enum.Font.GothamBold
	bringAllButton.TextSize = 11
	bringAllButton.BorderSizePixel = 0
	bringAllButton.Parent = bringSection
	
	local bringAllCorner = Instance.new("UICorner")
	bringAllCorner.CornerRadius = UDim.new(0, 5)
	bringAllCorner.Parent = bringAllButton

	-- Player Name Input
	local playerInput = Instance.new("TextBox")
	playerInput.Size = UDim2.new(0.48, 0, 0, 30)
	playerInput.Position = UDim2.new(0.52, 0, 0, 25)
	playerInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	playerInput.Text = "Player Name"
	playerInput.TextColor3 = Color3.new(1, 1, 1)
	playerInput.Font = Enum.Font.Gotham
	playerInput.TextSize = 10
	playerInput.BorderSizePixel = 0
	playerInput.Parent = bringSection
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 5)
	inputCorner.Parent = playerInput

	-- Bring Specific Button
	local bringSpecificButton = Instance.new("TextButton")
	bringSpecificButton.Size = UDim2.new(1, -20, 0, 25)
	bringSpecificButton.Position = UDim2.new(0, 10, 0, 60)
	bringSpecificButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	bringSpecificButton.Text = "🎯 Bring Specific Player"
	bringSpecificButton.TextColor3 = Color3.new(1, 1, 1)
	bringSpecificButton.Font = Enum.Font.Gotham
	bringSpecificButton.TextSize = 10
	bringSpecificButton.BorderSizePixel = 0
	bringSpecificButton.Parent = bringSection
	
	local bringSpecificCorner = Instance.new("UICorner")
	bringSpecificCorner.CornerRadius = UDim.new(0, 5)
	bringSpecificCorner.Parent = bringSpecificButton

	-- Status Label
	local bringStatus = Instance.new("TextLabel")
	bringStatus.Size = UDim2.new(1, 0, 0, 15)
	bringStatus.Position = UDim2.new(0, 0, 0, 85)
	bringStatus.BackgroundTransparency = 1
	bringStatus.Text = "⚠️ Use with caution - High detection risk!"
	bringStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
	bringStatus.Font = Enum.Font.Gotham
	bringStatus.TextSize = 9
	bringStatus.Parent = bringSection

	-- NoClip Control Section
	local noclipSection = Instance.new("Frame")
	noclipSection.Size = UDim2.new(1, -10, 0, 70)
	noclipSection.Position = UDim2.new(0, 5, 0, 295)
	noclipSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	noclipSection.BackgroundTransparency = 0.3
	noclipSection.BorderSizePixel = 0
	noclipSection.Parent = MainFrame
	
	local noclipCorner = Instance.new("UICorner")
	noclipCorner.CornerRadius = UDim.new(0, 6)
	noclipCorner.Parent = noclipSection

	-- NoClip Toggle Button
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

	-- NoClip Status Label
	local noclipStatus = Instance.new("TextLabel")
	noclipStatus.Size = UDim2.new(1, 0, 0, 20)
	noclipStatus.Position = UDim2.new(0, 0, 0, 45)
	noclipStatus.BackgroundTransparency = 1
	noclipStatus.Text = "Press N or click button to toggle"
	noclipStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
	noclipStatus.Font = Enum.Font.Gotham
	noclipStatus.TextSize = 10
	noclipStatus.Parent = noclipSection

	-- GODMODE CONTROL SECTION
	local godmodeSection = Instance.new("Frame")
	godmodeSection.Size = UDim2.new(1, -10, 0, 70)
	godmodeSection.Position = UDim2.new(0, 5, 0, 370)
	godmodeSection.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	godmodeSection.BackgroundTransparency = 0.3
	godmodeSection.BorderSizePixel = 0
	godmodeSection.Parent = MainFrame
	
	local godmodeCorner = Instance.new("UICorner")
	godmodeCorner.CornerRadius = UDim.new(0, 6)
	godmodeCorner.Parent = godmodeSection

	-- GodMode Toggle Button
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

	-- GodMode Status Label
	local godmodeStatus = Instance.new("TextLabel")
	godmodeStatus.Size = UDim2.new(1, 0, 0, 20)
	godmodeStatus.Position = UDim2.new(0, 0, 0, 45)
	godmodeStatus.BackgroundTransparency = 1
	godmodeStatus.Text = "Press H or click button to toggle"
	godmodeStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
	godmodeStatus.Font = Enum.Font.Gotham
	godmodeStatus.TextSize = 10
	godmodeStatus.Parent = godmodeSection

	-- Slider Logic
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
			speedLabel.Text = "✈️ Speed: " .. Speed
		end
	end)

	-- Bring Players Button Logic (NEW!)
	bringAllButton.MouseButton1Click:Connect(function()
		bringAllButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		bringAllButton.Text = "🌀 Bringing..."
		bringStatus.Text = "⏳ Bringing all players to you..."
		bringStatus.TextColor3 = Color3.fromRGB(255, 255, 100)
		
		BringAllPlayers()
		
		wait(2)
		bringAllButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		bringAllButton.Text = "🌀 Bring ALL"
		bringStatus.Text = "✅ Bring completed! Check console for details"
		bringStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		wait(3)
		bringStatus.Text = "⚠️ Use with caution - High detection risk!"
		bringStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
	end)

	bringSpecificButton.MouseButton1Click:Connect(function()
		local targetName = playerInput.Text
		if targetName and targetName ~= "Player Name" and targetName ~= "" then
			bringSpecificButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
			bringSpecificButton.Text = "🎯 Bringing..."
			bringStatus.Text = "⏳ Bringing " .. targetName .. "..."
			bringStatus.TextColor3 = Color3.fromRGB(255, 255, 100)
			
			local success = BringSpecificPlayer(targetName)
			
			wait(1)
			bringSpecificButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			bringSpecificButton.Text = "🎯 Bring Specific Player"
			
			if success then
				bringStatus.Text = "✅ Successfully brought " .. targetName .. "!"
				bringStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
			else
				bringStatus.Text = "❌ Failed to bring " .. targetName
				bringStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
			
			wait(3)
			bringStatus.Text = "⚠️ Use with caution - High detection risk!"
			bringStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
		else
			bringStatus.Text = "❌ Please enter a valid player name!"
			bringStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
			wait(2)
			bringStatus.Text = "⚠️ Use with caution - High detection risk!"
			bringStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
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

	-- NoClip Button Logic
	noclipButton.MouseButton1Click:Connect(function()
		NoClipping = not NoClipping
		if NoClipping then
			StartNoClip()
			noclipButton.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
			noclipButton.Text = "✅ NoClip: ON"
			noclipStatus.Text = "Walking through walls enabled"
			noclipStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
		else
			StopNoClip()
			noclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			noclipButton.Text = "🚫 NoClip: OFF"
			noclipStatus.Text = "Press N or click button to toggle"
			noclipStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)

	-- GodMode Button Logic
	godmodeButton.MouseButton1Click:Connect(function()
		GodMode = not GodMode
		if GodMode then
			StartGodMode()
			godmodeButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			godmodeButton.Text = "⚡ GodMode: ON"
			godmodeStatus.Text = "Kebal damage - Health unlimited!"
			godmodeStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
		else
			StopGodMode()
			godmodeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			godmodeButton.Text = "🛡️ GodMode: OFF"
			godmodeStatus.Text = "Press H or click button to toggle"
			godmodeStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)
end

-- INPUT CONTROL (Updated with T and Y keys for Bring functions)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F then
		Flying = not Flying
		if Flying then StartFlying() else StopFlying() end
	elseif input.KeyCode == Enum.KeyCode.N then
		NoClipping = not NoClipping
		if NoClipping then StartNoClip() else StopNoClip() end
	elseif input.KeyCode == Enum.KeyCode.H then
		GodMode = not GodMode
		if GodMode then StartGodMode() else StopGodMode() end
	elseif input.KeyCode == Enum.KeyCode.T then
		-- Bring All Players hotkey
		print("🌀 Hotkey activated: Bringing all players...")
		BringAllPlayers()
	elseif input.KeyCode == Enum.KeyCode.G then
		toggleGUI()
	end
end)

-- FLY MOTION
RunService.RenderStepped:Connect(function()
	if Flying then
		local cam = workspace.CurrentCamera
		local moveVec = Vector3.zero
		
		-- Get movement input
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.new(0, 1, 0) end

		-- Apply movement based on method
		if NetworkMethod == "BodyVelocity" then
			if BodyVelocity and BodyGyro then
				BodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * Speed or Vector3.zero
				BodyGyro.CFrame = cam.CFrame
			end
		elseif NetworkMethod == "CFrame" then
			if moveVec.Magnitude > 0 then
				local deltaTime = RunService.RenderStepped:Wait()
				local newPos = HumanoidRootPart.Position + (moveVec.Unit * Speed * deltaTime)
				HumanoidRootPart.CFrame = CFrame.new(newPos, newPos + cam.CFrame.LookVector)
			end
		elseif NetworkMethod == "Humanoid" then
			if BodyVelocity then
				BodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * Speed or Vector3.zero
			end
			if moveVec.Magnitude > 0 then
				HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + cam.CFrame.LookVector)
			end
		end
	end
	
	-- Maintain noclip
	MaintainNoClip()
end)

-- Handle character respawn
Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	Humanoid = Character:WaitForChild("Humanoid")
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Flying = false
	NoClipping = false
	GodMode = false
	OriginalCanCollide = {}
	OriginalMaxHealth = nil
	
	-- Clean up connections
	if HealthConnection then HealthConnection:Disconnect(); HealthConnection = nil end
	if TakeDamageConnection then TakeDamageConnection:Disconnect(); TakeDamageConnection = nil end
	if HeartbeatConnection then HeartbeatConnection:Disconnect(); HeartbeatConnection = nil end
	if StateConnection then StateConnection:Disconnect(); StateConnection = nil end
	
	StopFlying()
	StopNoClip()
	StopGodMode()
end)

-- INIT GUI
buildMainGUI()

print("Enhanced Fly, NoClip, GodMode & Bring Players Script Loaded!")
print("Controls:")
print("F - Toggle Fly")
print("N - Toggle NoClip") 
print("H - Toggle GodMode")
print("T - Bring All Players (NEW!)")
print("G - Toggle GUI (Show/Hide)")
print("WASD - Movement, Space - Up, Ctrl - Down")
print("Drag title bar to move GUI")
print("Try different network methods for visibility:")
print("- Body: Smoothest (client-side)")
print("- CFrame: More visible to others") 
print("- Humanoid: Most compatible")
print("🛡️ GodMode: Makes you invincible to all damage!")
print("🌀 Bring Players: Teleports all players to your location (HIGH RISK!)")
