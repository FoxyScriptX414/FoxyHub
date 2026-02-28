-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- *** UNIVERSAL ANTI-DUPLICATE SYSTEM (ล้างบางทุกเวอร์ชันเก่า) ***
local function clearOldHubs()
	for _, gui in pairs(CoreGui:GetChildren()) do
		if string.find(gui.Name, "FoxyHub") then gui:Destroy() end
	end
	if LocalPlayer:FindFirstChild("PlayerGui") then
		for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
			if string.find(gui.Name, "FoxyHub") then gui:Destroy() end
		end
	end
end
clearOldHubs()
-- ***************************************************************

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FoxyHub_Master"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Variables
local flySpeed = 50
local isFlying = false
local isNoclipping = false
local isInfJump = false
local isSpeedEnabled = false
local isJumpEnabled = false
local targetSpeed = 16
local targetJump = 50
local espEnabled = false
local waypoints = {}
local toggleKey = Enum.KeyCode.RightControl
local antiAfkEnabled = false
local isFrozen = false
local antiAdminEnabled = false

-- Click TP Variables
local ctrlTpEnabled = false
local clickTpKey = Enum.KeyCode.LeftControl

-- Aimlock Variables
local aimlockKey = Enum.KeyCode.G
local aimlockTarget = nil
local isAiming = false

-- ShiftLock Variables
local shiftLockSystemEnabled = false
local isShiftLocked = false

-- *** HELPER: SMART TELEPORT (Vehicle Support) ***
local function SmartTeleport(targetCFrame)
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	
	if hum and hum.SeatPart then
		local seat = hum.SeatPart
		local vehicle = seat.Parent
		if vehicle:IsA("Model") and vehicle.PrimaryPart then
			vehicle:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 3, 0))
		elseif seat:IsA("BasePart") then
			seat.CFrame = targetCFrame + Vector3.new(0, 3, 0)
		end
	elseif root then
		root.CFrame = targetCFrame + Vector3.new(0, 3, 0)
	end
end

-- 1. Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 550)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -275)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Stroke & Corner
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 100, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- *** Custom Drag System ***
local DragFrame = Instance.new("Frame")
DragFrame.Size = UDim2.new(1, 0, 0, 40)
DragFrame.BackgroundTransparency = 1
DragFrame.Parent = MainFrame

local dragging, dragInput, dragStart, startPos
DragFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = input.Position; startPos = MainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
DragFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- *** Resize System ***
local Resizer = Instance.new("ImageButton")
Resizer.Name = "ResizeHandle"
Resizer.Size = UDim2.new(0, 20, 0, 20)
Resizer.Position = UDim2.new(1, -20, 1, -20)
Resizer.BackgroundTransparency = 1
Resizer.Image = "rbxassetid://6031097225"
Resizer.ImageColor3 = Color3.fromRGB(0, 100, 255)
Resizer.ZIndex = 10
Resizer.Parent = MainFrame

local isResizing, resizeStart, startSize
Resizer.MouseButton1Down:Connect(function(x,y)
	isResizing = true; resizeStart = Vector2.new(Mouse.X, Mouse.Y); startSize = MainFrame.AbsoluteSize
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isResizing = false end end)
UserInputService.InputChanged:Connect(function(input)
	if isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = Vector2.new(Mouse.X, Mouse.Y) - resizeStart
		local newX = math.max(450, startSize.X + delta.X)
		local newY = math.max(300, startSize.Y + delta.Y)
		MainFrame.Size = UDim2.new(0, newX, 0, newY)
	end
end)

-- Header
local Title = Instance.new("TextLabel")
Title.Text = "Foxy Hub"
Title.Size = UDim2.new(0, 120, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Font = Enum.Font.FredokaOne
Title.Parent = MainFrame

-- Divider
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0, 2, 1, -20)
Divider.Position = UDim2.new(0, 140, 0, 10)
Divider.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -60)
Sidebar.Position = UDim2.new(0, 5, 0, 50)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Sidebar
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Tab Buttons
local tabs = {}
local pages = {}

local function createTabButton(name, order)
	local btn = Instance.new("TextButton")
	btn.Name = name.."Btn"
	btn.LayoutOrder = order
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(150, 150, 150)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Parent = Sidebar
	local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(0, 100, 255); s.Thickness = 1
	local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 6)
	tabs[name] = btn
	return btn
end

local InfoBtn = createTabButton("Info", 1)
local GenBtn = createTabButton("General", 2)
local SetBtn = createTabButton("Setting", 3)

-- Page Container
local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -155, 1, -20)
PageContainer.Position = UDim2.new(0, 150, 0, 10)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.Parent = MainFrame

local function createPage(name, isScroll)
	local p
	if isScroll then
		p = Instance.new("ScrollingFrame")
		p.ScrollBarThickness = 4
		p.ScrollBarImageColor3 = Color3.fromRGB(0, 100, 255)
	else
		p = Instance.new("Frame")
	end
	p.Name = name.."Page"
	p.Size = UDim2.new(1, 0, 1, 0)
	p.BackgroundTransparency = 1
	p.Visible = false
	p.Parent = PageContainer
	local pad = Instance.new("UIPadding", p)
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 15)
	return p
end

-- Pages
local InfoPage = createPage("Info", false)
local InfoLayout = Instance.new("UIListLayout", InfoPage); InfoLayout.Padding = UDim.new(0, 10)
pages["Info"] = InfoPage

local GenPageScroll = createPage("General", true)
local GenLayout = Instance.new("UIListLayout", GenPageScroll); GenLayout.Padding = UDim.new(0, 8); GenLayout.SortOrder = Enum.SortOrder.LayoutOrder
pages["General"] = GenPageScroll

local SetPageScroll = createPage("Setting", true)
local SetLayout = Instance.new("UIListLayout", SetPageScroll); SetLayout.Padding = UDim.new(0, 8); SetLayout.SortOrder = Enum.SortOrder.LayoutOrder
pages["Setting"] = SetPageScroll

local function SwitchTab(tabName)
	for name, page in pairs(pages) do page.Visible = (name == tabName) end
	for name, btn in pairs(tabs) do
		if name == tabName then
			btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.BackgroundColor3 = Color3.fromRGB(0, 80, 200)
		else
			btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		end
	end
end

InfoBtn.MouseButton1Click:Connect(function() SwitchTab("Info") end)
GenBtn.MouseButton1Click:Connect(function() SwitchTab("General") end)
SetBtn.MouseButton1Click:Connect(function() SwitchTab("Setting") end)
SwitchTab("Info")

-- ================= INFO CONTENT ================= --
local InfoBox = Instance.new("Frame", InfoPage)
InfoBox.Size = UDim2.new(1, 0, 0, 160)
InfoBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
local InfoStroke = Instance.new("UIStroke", InfoBox); InfoStroke.Color = Color3.fromRGB(0, 100, 255)
local InfoCorner = Instance.new("UICorner", InfoBox); InfoCorner.CornerRadius = UDim.new(0, 8)

local AvatarImg = Instance.new("ImageLabel", InfoBox)
AvatarImg.Size = UDim2.new(0, 80, 0, 80); AvatarImg.Position = UDim2.new(0, 10, 0, 10); AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"

local InfoText = Instance.new("TextLabel", InfoBox)
InfoText.Size = UDim2.new(1, -100, 1, -10); InfoText.Position = UDim2.new(0, 100, 0, 5); InfoText.BackgroundTransparency = 1; InfoText.TextColor3 = Color3.fromRGB(255, 255, 255); InfoText.TextXAlignment = Enum.TextXAlignment.Left; InfoText.TextYAlignment = Enum.TextYAlignment.Top; InfoText.Font = Enum.Font.Code; InfoText.TextSize = 14

local startTime = tick()
local function formatTime(seconds)
	local hours = math.floor(seconds / 3600); local minutes = math.floor((seconds % 3600) / 60); local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

RunService.RenderStepped:Connect(function()
	if InfoPage.Visible then
		local timeDiff = math.floor(tick() - startTime); local fps = math.floor(workspace:GetRealPhysicsFPS())
		local currentPlrs = #Players:GetPlayers(); local maxPlrs = Players.MaxPlayers
		InfoText.Text = string.format("\nUser: %s\nDisplay: %s\n\nPlayers: %d/%d\nFPS: %d\nTime: %s", LocalPlayer.Name, LocalPlayer.DisplayName, currentPlrs, maxPlrs, fps, formatTime(timeDiff))
	end
end)

-- ================= GENERAL CONTENT ================= --
local function createRow(height, order, parent)
	local row = Instance.new("Frame", parent)
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, height or 30)
	row.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	local s = Instance.new("UIStroke", row); s.Color = Color3.fromRGB(0, 80, 200); s.Thickness = 1
	local c = Instance.new("UICorner", row); c.CornerRadius = UDim.new(0, 4)
	return row
end

-- 1. Inf Jump
local r1 = createRow(30, 1, GenPageScroll)
local InfBtn = Instance.new("TextButton", r1)
InfBtn.Size = UDim2.new(1,0,1,0); InfBtn.BackgroundTransparency=1; InfBtn.Text="Infinite Jump: OFF"; InfBtn.TextColor3=Color3.fromRGB(200,200,200); InfBtn.Font=Enum.Font.Gotham
InfBtn.MouseButton1Click:Connect(function()
	isInfJump = not isInfJump
	InfBtn.Text = "Infinite Jump: "..(isInfJump and "ON" or "OFF")
	InfBtn.TextColor3 = isInfJump and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
end)
UserInputService.JumpRequest:Connect(function() if isInfJump then LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end end)

-- 2. Jump Power
local r2 = createRow(55, 2, GenPageScroll)
local JmpBtn = Instance.new("TextButton", r2)
JmpBtn.Size = UDim2.new(0.6, 0, 0, 25); JmpBtn.Position = UDim2.new(0, 10, 0, 5); JmpBtn.BackgroundTransparency = 1; JmpBtn.Text = "JumpPower: OFF"; JmpBtn.TextColor3 = Color3.fromRGB(200, 200, 200); JmpBtn.TextXAlignment = Enum.TextXAlignment.Left; JmpBtn.Font = Enum.Font.Gotham
local JmpBox = Instance.new("TextBox", r2); JmpBox.Size = UDim2.new(0.2, 0, 0, 20); JmpBox.Position = UDim2.new(0.75, 0, 0, 5); JmpBox.Text = "50"; JmpBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); JmpBox.TextColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", JmpBox).CornerRadius = UDim.new(0, 4)
local JmpSlider = Instance.new("Frame", r2); JmpSlider.Size = UDim2.new(0.9, 0, 0, 4); JmpSlider.Position = UDim2.new(0.05, 0, 0, 40); JmpSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local JmpFill = Instance.new("Frame", JmpSlider); JmpFill.Size = UDim2.new(50/500, 0, 1, 0); JmpFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
local JmpDot = Instance.new("TextButton", JmpSlider); JmpDot.Size = UDim2.new(0, 12, 0, 12); JmpDot.Position = UDim2.new(50/500, -6, 0.5, -6); JmpDot.Text = ""; JmpDot.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", JmpDot).CornerRadius = UDim.new(1, 0)
local function UpdateJmp(val) targetJump = math.clamp(val, 0, 500); JmpBox.Text = tostring(math.floor(targetJump)); local percent = targetJump / 500; JmpFill.Size = UDim2.new(percent, 0, 1, 0); JmpDot.Position = UDim2.new(percent, -6, 0.5, -6) end
local jmpDrag = false; JmpDot.MouseButton1Down:Connect(function() jmpDrag = true end); JmpBox.FocusLost:Connect(function() UpdateJmp(tonumber(JmpBox.Text) or 50) end)
JmpBtn.MouseButton1Click:Connect(function() isJumpEnabled = not isJumpEnabled; JmpBtn.Text = "JumpPower: " .. (isJumpEnabled and "ON" or "OFF"); JmpBtn.TextColor3 = isJumpEnabled and Color3.new(0, 1, 0) or Color3.new(0.8, 0.8, 0.8); if not isJumpEnabled and LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower = 50; LocalPlayer.Character.Humanoid.UseJumpPower = true end end)

-- 3. Noclip
local r3 = createRow(30, 3, GenPageScroll)
local NoBtn = Instance.new("TextButton", r3)
NoBtn.Size = UDim2.new(1,0,1,0); NoBtn.BackgroundTransparency=1; NoBtn.Text="Noclip: OFF"; NoBtn.TextColor3=Color3.fromRGB(200,200,200); NoBtn.Font=Enum.Font.Gotham
NoBtn.MouseButton1Click:Connect(function()
	isNoclipping = not isNoclipping
	NoBtn.Text = "Noclip: "..(isNoclipping and "ON" or "OFF")
	NoBtn.TextColor3 = isNoclipping and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
end)
RunService.Stepped:Connect(function() if isNoclipping and LocalPlayer.Character then for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end end)

-- 4. Fly
local r4 = createRow(55, 4, GenPageScroll)
local FlyBtn = Instance.new("TextButton", r4); FlyBtn.Size = UDim2.new(0.6,0,0,25); FlyBtn.Position=UDim2.new(0,10,0,5); FlyBtn.BackgroundTransparency=1; FlyBtn.Text="Fly: OFF"; FlyBtn.TextXAlignment=Enum.TextXAlignment.Left; FlyBtn.TextColor3=Color3.fromRGB(200,200,200); FlyBtn.Font=Enum.Font.Gotham
local FlyBox = Instance.new("TextBox", r4); FlyBox.Size=UDim2.new(0.2,0,0,20); FlyBox.Position=UDim2.new(0.75,0,0,5); FlyBox.Text="50"; FlyBox.BackgroundColor3=Color3.fromRGB(30,30,30); FlyBox.TextColor3=Color3.new(1,1,1); Instance.new("UICorner", FlyBox).CornerRadius=UDim.new(0,4)
local FlySlider = Instance.new("Frame", r4); FlySlider.Size = UDim2.new(0.9, 0, 0, 4); FlySlider.Position = UDim2.new(0.05, 0, 0, 40); FlySlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local FlyFill = Instance.new("Frame", FlySlider); FlyFill.Size = UDim2.new(50/500, 0, 1, 0); FlyFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
local FlyDot = Instance.new("TextButton", FlySlider); FlyDot.Size = UDim2.new(0, 12, 0, 12); FlyDot.Position = UDim2.new(50/500, -6, 0.5, -6); FlyDot.Text = ""; FlyDot.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", FlyDot).CornerRadius = UDim.new(1, 0)
local function UpdateFly(val) flySpeed = math.clamp(val, 0, 500); FlyBox.Text = tostring(math.floor(flySpeed)); local percent = flySpeed / 500; FlyFill.Size = UDim2.new(percent, 0, 1, 0); FlyDot.Position = UDim2.new(percent, -6, 0.5, -6) end
local flyDrag = false; FlyDot.MouseButton1Down:Connect(function() flyDrag = true end); FlyBox.FocusLost:Connect(function() UpdateFly(tonumber(FlyBox.Text) or 50) end)
FlyBtn.MouseButton1Click:Connect(function()
	isFlying = not isFlying
	FlyBtn.Text = "Fly: "..(isFlying and "ON" or "OFF")
	FlyBtn.TextColor3 = isFlying and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
	if isFlying then
		task.spawn(function()
			local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			while not HRP do task.wait(); HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end
			local bg = Instance.new("BodyGyro", HRP); bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=9000; local bv = Instance.new("BodyVelocity", HRP); bv.MaxForce=Vector3.new(9e9,9e9,9e9)
			while isFlying do
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					HRP = LocalPlayer.Character.HumanoidRootPart
					if not HRP:FindFirstChild("BodyGyro") then bg = Instance.new("BodyGyro", HRP); bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=9000; bv = Instance.new("BodyVelocity", HRP); bv.MaxForce=Vector3.new(9e9,9e9,9e9) end
					LocalPlayer.Character.Humanoid.PlatformStand = true; bg.CFrame = Workspace.CurrentCamera.CFrame; local cf = Workspace.CurrentCamera.CFrame; local v = Vector3.new()
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then v=v+cf.LookVector end; if UserInputService:IsKeyDown(Enum.KeyCode.S) then v=v-cf.LookVector end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then v=v+cf.RightVector end; if UserInputService:IsKeyDown(Enum.KeyCode.A) then v=v-cf.RightVector end
					bv.Velocity = v*flySpeed
				else task.wait() end; task.wait()
			end
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
			pcall(function() bg:Destroy() bv:Destroy() end)
		end)
	end
end)

-- 5. WalkSpeed
local r5 = createRow(55, 5, GenPageScroll)
local SpdBtn = Instance.new("TextButton", r5); SpdBtn.Size = UDim2.new(0.6, 0, 0, 25); SpdBtn.Position = UDim2.new(0, 10, 0, 5); SpdBtn.BackgroundTransparency = 1; SpdBtn.Text = "WalkSpeed: OFF"; SpdBtn.TextColor3 = Color3.fromRGB(200, 200, 200); SpdBtn.TextXAlignment = Enum.TextXAlignment.Left; SpdBtn.Font = Enum.Font.Gotham
local SpdBox = Instance.new("TextBox", r5); SpdBox.Size = UDim2.new(0.2, 0, 0, 20); SpdBox.Position = UDim2.new(0.75, 0, 0, 5); SpdBox.Text = "16"; SpdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SpdBox.TextColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SpdBox).CornerRadius = UDim.new(0, 4)
local SpdSlider = Instance.new("Frame", r5); SpdSlider.Size = UDim2.new(0.9, 0, 0, 4); SpdSlider.Position = UDim2.new(0.05, 0, 0, 40); SpdSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local SpdFill = Instance.new("Frame", SpdSlider); SpdFill.Size = UDim2.new(16/500, 0, 1, 0); SpdFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
local SpdDot = Instance.new("TextButton", SpdSlider); SpdDot.Size = UDim2.new(0, 12, 0, 12); SpdDot.Position = UDim2.new(16/500, -6, 0.5, -6); SpdDot.Text = ""; SpdDot.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", SpdDot).CornerRadius = UDim.new(1, 0)
local function UpdateSpd(val) targetSpeed = math.clamp(val, 0, 500); SpdBox.Text = tostring(math.floor(targetSpeed)); local percent = targetSpeed / 500; SpdFill.Size = UDim2.new(percent, 0, 1, 0); SpdDot.Position = UDim2.new(percent, -6, 0.5, -6) end
local spdDrag = false; SpdDot.MouseButton1Down:Connect(function() spdDrag = true end); SpdBox.FocusLost:Connect(function() UpdateSpd(tonumber(SpdBox.Text) or 16) end)
SpdBtn.MouseButton1Click:Connect(function() isSpeedEnabled = not isSpeedEnabled; SpdBtn.Text = "WalkSpeed: " .. (isSpeedEnabled and "ON" or "OFF"); SpdBtn.TextColor3 = isSpeedEnabled and Color3.new(0, 1, 0) or Color3.new(0.8, 0.8, 0.8); if not isSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end)

-- 6. ESP
local r6 = createRow(30, 6, GenPageScroll)
local EspBtn = Instance.new("TextButton", r6); EspBtn.Size = UDim2.new(1,0,1,0); EspBtn.BackgroundTransparency=1; EspBtn.Text="ESP Players: OFF"; EspBtn.TextColor3=Color3.fromRGB(200,200,200); EspBtn.Font=Enum.Font.Gotham
local function ClearESP() for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("ESP_Tag") then p.Character.Head.ESP_Tag:Destroy() end end end
local function AddEsp(p) if not espEnabled or p == LocalPlayer then return end; local function app(c) if not espEnabled then return end; local h = c:WaitForChild("Head", 5); if not h or h:FindFirstChild("ESP_Tag") then return end; local b = Instance.new("BillboardGui", h); b.Name="ESP_Tag"; b.Size=UDim2.new(0,100,0,50); b.StudsOffset=Vector3.new(0,2,0); b.AlwaysOnTop=true; local t = Instance.new("TextLabel", b); t.Size=UDim2.new(1,0,0.5,0); t.BackgroundTransparency=1; t.Text=p.Name; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0; local hp = Instance.new("TextLabel", b); hp.Size=UDim2.new(1,0,0.5,0); hp.Position=UDim2.new(0,0,0.5,0); hp.BackgroundTransparency=1; hp.TextColor3=Color3.new(0,1,0); hp.TextStrokeTransparency=0; local hum = c:WaitForChild("Humanoid", 5); if hum then hp.Text="HP: "..math.floor(hum.Health); hum.HealthChanged:Connect(function() hp.Text="HP: "..math.floor(hum.Health) end) end end; if p.Character then app(p.Character) end; p.CharacterAdded:Connect(app) end
EspBtn.MouseButton1Click:Connect(function() espEnabled = not espEnabled; EspBtn.Text = "ESP Players: "..(espEnabled and "ON" or "OFF"); EspBtn.TextColor3 = espEnabled and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8); if espEnabled then for _,p in pairs(Players:GetPlayers()) do AddEsp(p) end else ClearESP() end end); Players.PlayerAdded:Connect(AddEsp)

-- 7. Spectate
local r7 = createRow(35, 7, GenPageScroll)
local SpecBox = Instance.new("TextBox", r7); SpecBox.Size = UDim2.new(0.4, 0, 0, 25); SpecBox.Position = UDim2.new(0.02, 0, 0.1, 0); SpecBox.PlaceholderText = "Name.."; SpecBox.Text = ""; SpecBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SpecBox.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", SpecBox).CornerRadius = UDim.new(0, 4)
local ViewBtn = Instance.new("TextButton", r7); ViewBtn.Size = UDim2.new(0.25, 0, 0, 25); ViewBtn.Position = UDim2.new(0.45, 0, 0.1, 0); ViewBtn.Text = "View"; ViewBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200); ViewBtn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", ViewBtn).CornerRadius = UDim.new(0, 4)
local StopBtn = Instance.new("TextButton", r7); StopBtn.Size = UDim2.new(0.25, 0, 0, 25); StopBtn.Position = UDim2.new(0.73, 0, 0.1, 0); StopBtn.Text = "Stop"; StopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); StopBtn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 4)
ViewBtn.MouseButton1Click:Connect(function() local targetName = string.lower(SpecBox.Text); for _, p in pairs(Players:GetPlayers()) do if string.sub(string.lower(p.Name), 1, #targetName) == targetName or string.sub(string.lower(p.DisplayName), 1, #targetName) == targetName then if p.Character and p.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = p.Character.Humanoid; SpecBox.Text = p.Name; break end end end end)
StopBtn.MouseButton1Click:Connect(function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end end)

-- 8. Freeze
local r8 = createRow(30, 8, GenPageScroll)
local FreezeBtn = Instance.new("TextButton", r8); FreezeBtn.Size = UDim2.new(1,0,1,0); FreezeBtn.BackgroundTransparency=1; FreezeBtn.Text="Freeze Character: OFF"; FreezeBtn.TextColor3=Color3.fromRGB(200,200,200); FreezeBtn.Font=Enum.Font.Gotham
FreezeBtn.MouseButton1Click:Connect(function() isFrozen = not isFrozen; FreezeBtn.Text = "Freeze Character: "..(isFrozen and "ON" or "OFF"); FreezeBtn.TextColor3 = isFrozen and Color3.new(0,1,1) or Color3.new(0.8,0.8,0.8); if not isFrozen and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end end)

-- 9. Click TP (UPDATED: Can Change Keybind)
local r9 = createRow(30, 9, GenPageScroll)
local CtrlTpBtn = Instance.new("TextButton", r9)
CtrlTpBtn.Size = UDim2.new(0.6,0,1,0); CtrlTpBtn.BackgroundTransparency=1; CtrlTpBtn.Text="Click TP: OFF"; CtrlTpBtn.TextColor3=Color3.fromRGB(200,200,200); CtrlTpBtn.Font=Enum.Font.Gotham; CtrlTpBtn.TextXAlignment = Enum.TextXAlignment.Left; CtrlTpBtn.Position = UDim2.new(0, 10, 0, 0)

local CtrlTpKeyBtn = Instance.new("TextButton", r9)
CtrlTpKeyBtn.Size = UDim2.new(0.3, 0, 0, 25); CtrlTpKeyBtn.Position = UDim2.new(0.65, 0, 0, 2.5); CtrlTpKeyBtn.Text = "Key: LCtrl"; CtrlTpKeyBtn.BackgroundColor3 = Color3.fromRGB(40,40,40); CtrlTpKeyBtn.TextColor3 = Color3.new(0,1,1); Instance.new("UICorner", CtrlTpKeyBtn).CornerRadius = UDim.new(0,4)

CtrlTpBtn.MouseButton1Click:Connect(function()
	ctrlTpEnabled = not ctrlTpEnabled
	CtrlTpBtn.Text = "Click TP: "..(ctrlTpEnabled and "ON" or "OFF")
	CtrlTpBtn.TextColor3 = ctrlTpEnabled and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
end)

local tpListening = false
CtrlTpKeyBtn.MouseButton1Click:Connect(function() tpListening = true; CtrlTpKeyBtn.Text = "..." end)
UserInputService.InputBegan:Connect(function(input)
	if tpListening and input.UserInputType == Enum.UserInputType.Keyboard then
		clickTpKey = input.KeyCode
		local keyStr = tostring(clickTpKey):gsub("Enum.KeyCode.", "")
		if keyStr == "LeftControl" then keyStr = "LCtrl" end
		if keyStr == "RightControl" then keyStr = "RCtrl" end
		CtrlTpKeyBtn.Text = "Key: "..keyStr
		tpListening = false
	end
end)
Mouse.Button1Down:Connect(function() if ctrlTpEnabled and UserInputService:IsKeyDown(clickTpKey) and Mouse.Hit then SmartTeleport(CFrame.new(Mouse.Hit.Position)) end end)

-- 10. TP Player
local r10 = createRow(140, 10, GenPageScroll)
local TpLbl = Instance.new("TextLabel", r10); TpLbl.Text="Teleport to Player"; TpLbl.Size=UDim2.new(1,0,0,20); TpLbl.BackgroundTransparency=1; TpLbl.TextColor3=Color3.new(1,1,1); TpLbl.Font=Enum.Font.GothamBold; TpLbl.Position=UDim2.new(0,0,0,5)
local TpSearch = Instance.new("TextBox", r10); TpSearch.Size=UDim2.new(0.9,0,0,25); TpSearch.Position=UDim2.new(0.05,0,0,30); TpSearch.PlaceholderText="Search Player..."; TpSearch.BackgroundColor3=Color3.fromRGB(30,30,30); TpSearch.TextColor3=Color3.new(1,1,1); Instance.new("UICorner", TpSearch).CornerRadius = UDim.new(0,4)
local TpScroll = Instance.new("ScrollingFrame", r10); TpScroll.Size = UDim2.new(0.9, 0, 0, 70); TpScroll.Position = UDim2.new(0.05, 0, 0, 60); TpScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TpScroll.CanvasSize = UDim2.new(0,0,0,0); TpScroll.ScrollBarThickness = 2
local TpList = Instance.new("UIListLayout", TpScroll); TpList.Padding=UDim.new(0,2)
local RefreshTp = Instance.new("ImageButton", r10); RefreshTp.Size = UDim2.new(0,18,0,18); RefreshTp.Position=UDim2.new(1,-25,0,33); RefreshTp.BackgroundColor3=Color3.fromRGB(0,80,200); RefreshTp.Image="rbxassetid://6031097225"; RefreshTp.ZIndex = 2
local function RefreshPlayerList(filter)
	for _,v in pairs(TpScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LocalPlayer then
			local show = true
			if filter and filter ~= "" then if not (string.find(string.lower(p.Name), string.lower(filter)) or string.find(string.lower(p.DisplayName), string.lower(filter))) then show = false end end
			if show then
				local b = Instance.new("TextButton", TpScroll); b.Size=UDim2.new(1,0,0,25); b.Text = p.DisplayName .. " (@" .. p.Name .. ")"; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham; b.TextSize=12
				b.MouseButton1Click:Connect(function() if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then SmartTeleport(p.Character.HumanoidRootPart.CFrame) end end)
			end
		end
	end
	TpScroll.CanvasSize = UDim2.new(0,0,0,TpList.AbsoluteContentSize.Y)
end
RefreshTp.MouseButton1Click:Connect(function() RefreshPlayerList(TpSearch.Text) end)
TpSearch.Changed:Connect(function(prop) if prop == "Text" then RefreshPlayerList(TpSearch.Text) end end)
RefreshPlayerList("")

-- 11. Waypoints
local r11 = createRow(140, 11, GenPageScroll)
local WpLbl = Instance.new("TextLabel", r11); WpLbl.Text="Waypoints System"; WpLbl.Size=UDim2.new(1,0,0,20); WpLbl.BackgroundTransparency=1; WpLbl.TextColor3=Color3.new(1,1,1); WpLbl.Font=Enum.Font.GothamBold; WpLbl.Position=UDim2.new(0,0,0,5)
local WpBox = Instance.new("TextBox", r11); WpBox.Size=UDim2.new(0.6,0,0,25); WpBox.Position=UDim2.new(0.05,0,0,30); WpBox.PlaceholderText="Name..."; WpBox.BackgroundColor3=Color3.fromRGB(30,30,30); WpBox.TextColor3=Color3.new(1,1,1)
local AddWp = Instance.new("TextButton", r11); AddWp.Size=UDim2.new(0.25,0,0,25); AddWp.Position=UDim2.new(0.7,0,0,30); AddWp.Text="Add"; AddWp.BackgroundColor3=Color3.fromRGB(0,80,200); AddWp.TextColor3=Color3.new(1,1,1)
local WpScroll = Instance.new("ScrollingFrame", r11); WpScroll.Size=UDim2.new(0.9,0,0,70); WpScroll.Position=UDim2.new(0.05,0,0,60); WpScroll.BackgroundColor3=Color3.fromRGB(20,20,20); WpScroll.ScrollBarThickness=2
local WpList = Instance.new("UIListLayout", WpScroll); WpList.Padding=UDim.new(0,2)
local function RefreshWp()
	for _,v in pairs(WpScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
	for name, cf in pairs(waypoints) do
		local f = Instance.new("Frame", WpScroll); f.Size=UDim2.new(1,0,0,25); f.BackgroundTransparency=1
		local b = Instance.new("TextButton", f); b.Size=UDim2.new(0.75,0,1,0); b.Text="  "..name; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.new(1,1,1); b.TextXAlignment=Enum.TextXAlignment.Left; b.Font=Enum.Font.Gotham
		b.MouseButton1Click:Connect(function() SmartTeleport(cf) end)
		local d = Instance.new("TextButton", f); d.Size=UDim2.new(0.2,0,1,0); d.Position=UDim2.new(0.8,0,0,0); d.Text="Del"; d.BackgroundColor3=Color3.fromRGB(200,50,50); d.TextColor3=Color3.new(1,1,1); d.Font=Enum.Font.GothamBold
		d.MouseButton1Click:Connect(function() waypoints[name]=nil; RefreshWp() end)
	end
	WpScroll.CanvasSize = UDim2.new(0,0,0,WpList.AbsoluteContentSize.Y)
end
AddWp.MouseButton1Click:Connect(function() local name = WpBox.Text; if name ~= "" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then waypoints[name] = LocalPlayer.Character.HumanoidRootPart.CFrame; WpBox.Text = ""; RefreshWp() end end)

-- 12. AIMLOCK SYSTEM (UPDATED: TOGGLE)
local r12 = createRow(160, 12, GenPageScroll)
local AimTitle = Instance.new("TextLabel", r12); AimTitle.Text = "Aimlock System (Toggle)"; AimTitle.Size=UDim2.new(1,0,0,20); AimTitle.Position=UDim2.new(0,0,0,5); AimTitle.BackgroundTransparency=1; AimTitle.TextColor3=Color3.new(1,1,1); AimTitle.Font=Enum.Font.GothamBold

local AimSearch = Instance.new("TextBox", r12); AimSearch.Size=UDim2.new(0.5,0,0,25); AimSearch.Position=UDim2.new(0.05,0,0,30); AimSearch.PlaceholderText="Search Name..."; AimSearch.BackgroundColor3=Color3.fromRGB(30,30,30); AimSearch.TextColor3=Color3.new(1,1,1); Instance.new("UICorner", AimSearch).CornerRadius = UDim.new(0,4)
local AimKeyBtn = Instance.new("TextButton", r12); AimKeyBtn.Size=UDim2.new(0.3,0,0,25); AimKeyBtn.Position=UDim2.new(0.58,0,0,30); AimKeyBtn.Text="Key: G"; AimKeyBtn.BackgroundColor3=Color3.fromRGB(40,40,40); AimKeyBtn.TextColor3=Color3.new(0,1,1); Instance.new("UICorner", AimKeyBtn).CornerRadius = UDim.new(0,4)
local AimRef = Instance.new("ImageButton", r12); AimRef.Size=UDim2.new(0,25,0,25); AimRef.Position=UDim2.new(0.9,0,0,30); AimRef.Image="rbxassetid://6031097225"; AimRef.BackgroundColor3=Color3.fromRGB(0,80,200); Instance.new("UICorner", AimRef).CornerRadius=UDim.new(0,4)

local AimScroll = Instance.new("ScrollingFrame", r12); AimScroll.Size=UDim2.new(0.9, 0, 0, 90); AimScroll.Position = UDim2.new(0.05, 0, 0, 60); AimScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20); AimScroll.CanvasSize = UDim2.new(0,0,0,0); AimScroll.ScrollBarThickness = 2
local AimList = Instance.new("UIListLayout", AimScroll); AimList.Padding=UDim.new(0,2)

local function RefreshAimList(filter)
	for _,v in pairs(AimScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LocalPlayer then
			local show = true
			if filter and filter ~= "" then if not (string.find(string.lower(p.Name), string.lower(filter)) or string.find(string.lower(p.DisplayName), string.lower(filter))) then show = false end end
			if show then
				local b = Instance.new("TextButton", AimScroll); b.Size=UDim2.new(1,0,0,25); b.Text = p.DisplayName .. " (@" .. p.Name .. ")"; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham; b.TextSize=12
				b.MouseButton1Click:Connect(function() aimlockTarget = p; AimSearch.Text = p.Name; isAiming = false; if not isShiftLocked then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end end)
			end
		end
	end
	AimScroll.CanvasSize = UDim2.new(0,0,0,AimList.AbsoluteContentSize.Y)
end
RefreshAimList("")
AimSearch.Changed:Connect(function(p) if p == "Text" then RefreshAimList(AimSearch.Text) end end)
AimRef.MouseButton1Click:Connect(function() RefreshAimList(AimSearch.Text) end)

local aimListening = false
AimKeyBtn.MouseButton1Click:Connect(function() aimListening = true; AimKeyBtn.Text = "..." end)
UserInputService.InputBegan:Connect(function(input, gp)
	if aimListening and input.UserInputType == Enum.UserInputType.Keyboard then
		aimlockKey = input.KeyCode
		local keyStr = tostring(aimlockKey):gsub("Enum.KeyCode.","")
		if keyStr == "LeftControl" then keyStr = "LCtrl" end
		AimKeyBtn.Text = "Key: "..keyStr; aimListening = false
	elseif not gp and input.KeyCode == aimlockKey then
		-- *** TOGGLE AIMLOCK ***
		isAiming = not isAiming
		if not isAiming and not isShiftLocked then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end
end)

-- ================= SETTING CONTENT ================= --
local AfkFrame = createRow(40, 1, SetPageScroll)
local AfkBtn = Instance.new("TextButton", AfkFrame); AfkBtn.Size=UDim2.new(0.9,0,0,30); AfkBtn.Position=UDim2.new(0.05,0,0,5); AfkBtn.BackgroundColor3=Color3.fromRGB(30,30,30); AfkBtn.Text="Anti-AFK: OFF"; AfkBtn.TextColor3=Color3.fromRGB(200,200,200); AfkBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", AfkBtn).CornerRadius=UDim.new(0,6)
AfkBtn.MouseButton1Click:Connect(function() antiAfkEnabled = not antiAfkEnabled; AfkBtn.Text = "Anti-AFK: "..(antiAfkEnabled and "ON" or "OFF"); AfkBtn.TextColor3 = antiAfkEnabled and Color3.new(0,1,0) or Color3.fromRGB(200,200,200) end)
task.spawn(function() while true do task.wait(60); if antiAfkEnabled then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0,0)) end) end end end)

local AaFrame = createRow(40, 2, SetPageScroll)
local AaBtn = Instance.new("TextButton", AaFrame); AaBtn.Size=UDim2.new(0.9,0,0,30); AaBtn.Position=UDim2.new(0.05,0,0,5); AaBtn.BackgroundColor3=Color3.fromRGB(30,30,30); AaBtn.Text="Anti-Admin (Auto Hop): OFF"; AaBtn.TextColor3=Color3.fromRGB(200,200,200); AaBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", AaBtn).CornerRadius = UDim.new(0,6)
AaBtn.MouseButton1Click:Connect(function() antiAdminEnabled = not antiAdminEnabled; AaBtn.Text = "Anti-Admin (Auto Hop): "..(antiAdminEnabled and "ON" or "OFF"); AaBtn.TextColor3 = antiAdminEnabled and Color3.new(0,1,0) or Color3.fromRGB(200,200,200) end)
local function ServerHop()
	local PlaceID = game.PlaceId; local AllIDs = {}; local found = false
	local function Fetch() local site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100')); for i, v in pairs(site.data) do if v.playing ~= v.maxPlayers and v.id ~= game.JobId then table.insert(AllIDs, v.id) end end; if #AllIDs > 0 then TeleportService:TeleportToPlaceInstance(PlaceID, AllIDs[math.random(1, #AllIDs)], LocalPlayer); found = true end end
	pcall(Fetch); if not found then task.wait(1); pcall(Fetch) end
end
task.spawn(function() while true do task.wait(2); if antiAdminEnabled then for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and (p.UserId == game.CreatorId or (game.CreatorType == Enum.CreatorType.Group and p:GetRankInGroup(game.CreatorId) >= 200)) then ServerHop() end end end end end)

local HopFrame = createRow(40, 3, SetPageScroll)
local HopBtn = Instance.new("TextButton", HopFrame); HopBtn.Size=UDim2.new(0.9,0,0,30); HopBtn.Position=UDim2.new(0.05,0,0,5); HopBtn.BackgroundColor3=Color3.fromRGB(0, 150, 255); HopBtn.Text="Server Hop (Find New)"; HopBtn.TextColor3=Color3.new(1,1,1); HopBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", HopBtn).CornerRadius = UDim.new(0,6)
HopBtn.MouseButton1Click:Connect(ServerHop)

local ShiftFrame = createRow(40, 4, SetPageScroll)
local SLBtn = Instance.new("TextButton", ShiftFrame); SLBtn.Size=UDim2.new(0.9,0,0,30); SLBtn.Position=UDim2.new(0.05,0,0,5); SLBtn.BackgroundColor3=Color3.fromRGB(30,30,30); SLBtn.Text="Enable ShiftLock System: OFF"; SLBtn.TextColor3=Color3.fromRGB(200,200,200); SLBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", SLBtn).CornerRadius=UDim.new(0,6)
local SLDrag = Instance.new("TextButton", ScreenGui); SLDrag.Name = "ShiftLockButton"; SLDrag.Size = UDim2.new(0, 50, 0, 50); SLDrag.Position = UDim2.new(0.8, 0, 0.7, 0); SLDrag.BackgroundColor3 = Color3.fromRGB(20,20,20); SLDrag.Text = ""; SLDrag.Visible = false; Instance.new("UICorner", SLDrag).CornerRadius = UDim.new(1,0); local SLIcon = Instance.new("ImageLabel", SLDrag); SLIcon.Size = UDim2.new(0.6,0,0.6,0); SLIcon.Position = UDim2.new(0.2,0,0.2,0); SLIcon.BackgroundTransparency = 1; SLIcon.Image = "rbxassetid://7059346373"; SLIcon.ImageColor3 = Color3.fromRGB(150,150,150); local SLStroke = Instance.new("UIStroke", SLDrag); SLStroke.Color = Color3.fromRGB(255,255,255); SLStroke.Thickness = 2
local function ToggleLock() if not shiftLockSystemEnabled then return end; isShiftLocked = not isShiftLocked; if isShiftLocked then SLIcon.ImageColor3=Color3.fromRGB(0,255,255); SLStroke.Color=Color3.fromRGB(0,255,255); UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter else SLIcon.ImageColor3=Color3.fromRGB(150,150,150); SLStroke.Color=Color3.fromRGB(255,255,255); if not isAiming then UserInputService.MouseBehavior=Enum.MouseBehavior.Default end end end
SLBtn.MouseButton1Click:Connect(function() shiftLockSystemEnabled = not shiftLockSystemEnabled; SLBtn.Text = "Enable ShiftLock System: "..(shiftLockSystemEnabled and "ON" or "OFF"); SLBtn.TextColor3 = shiftLockSystemEnabled and Color3.new(0,1,0) or Color3.fromRGB(200,200,200); SLDrag.Visible = shiftLockSystemEnabled; if not shiftLockSystemEnabled then isShiftLocked = false; ToggleLock() end end)
SLDrag.MouseButton1Click:Connect(ToggleLock); UserInputService.InputBegan:Connect(function(input, gp) if not gp and shiftLockSystemEnabled and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then ToggleLock() end end)
local d2, ds2, sp2; SLDrag.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d2=true; ds2=i.Position; sp2=SLDrag.Position end end); UserInputService.InputChanged:Connect(function(i) if d2 and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds2; SLDrag.Position=UDim2.new(sp2.X.Scale, sp2.X.Offset+d.X, sp2.Y.Scale, sp2.Y.Offset+d.Y) end end); UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d2=false end end)

local FogFrame = createRow(40, 5, SetPageScroll)
local FogBtn = Instance.new("TextButton", FogFrame); FogBtn.Size=UDim2.new(0.9,0,0,30); FogBtn.Position=UDim2.new(0.05,0,0,5); FogBtn.BackgroundColor3=Color3.fromRGB(30,30,30); FogBtn.Text="No Fog: OFF"; FogBtn.TextColor3=Color3.fromRGB(200,200,200); FogBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", FogBtn).CornerRadius=UDim.new(0,6)
local noFogEnabled = false; local lightingStatsFog = {FogEnd = 1000}; local cachedEffects = {}
FogBtn.MouseButton1Click:Connect(function() noFogEnabled = not noFogEnabled; FogBtn.Text = "No Fog: "..(noFogEnabled and "ON" or "OFF"); FogBtn.TextColor3 = noFogEnabled and Color3.new(0,1,0) or Color3.fromRGB(200,200,200); if noFogEnabled then lightingStatsFog.FogEnd = Lighting.FogEnd; Lighting.FogEnd = 9e9; for _,v in pairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("PostEffect") then v.Parent = nil; table.insert(cachedEffects, v) end end else Lighting.FogEnd = lightingStatsFog.FogEnd; for _,v in pairs(cachedEffects) do v.Parent = Lighting end; cachedEffects = {} end end)

local BriFrame = createRow(60, 6, SetPageScroll)
local BriLbl = Instance.new("TextLabel", BriFrame); BriLbl.Text = "Brightness"; BriLbl.Size=UDim2.new(0.4,0,0,25); BriLbl.Position=UDim2.new(0.05,0,0,5); BriLbl.BackgroundTransparency=1; BriLbl.TextColor3=Color3.new(1,1,1); BriLbl.TextXAlignment=Enum.TextXAlignment.Left; BriLbl.Font=Enum.Font.GothamBold
local MaxBtn = Instance.new("TextButton", BriFrame); MaxBtn.Size = UDim2.new(0.3, 0, 0, 20); MaxBtn.Position = UDim2.new(0.65, 0, 0, 5); MaxBtn.Text = "Max: OFF"; MaxBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); MaxBtn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", MaxBtn).CornerRadius = UDim.new(0, 4)
local BriSlider = Instance.new("Frame", BriFrame); BriSlider.Size = UDim2.new(0.9, 0, 0, 4); BriSlider.Position = UDim2.new(0.05, 0, 0, 40); BriSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
local BriFill = Instance.new("Frame", BriSlider); BriFill.Size = UDim2.new(Lighting.Brightness/10, 0, 1, 0); BriFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
local BriDot = Instance.new("TextButton", BriSlider); BriDot.Size = UDim2.new(0, 12, 0, 12); BriDot.Position = UDim2.new(Lighting.Brightness/10, -6, 0.5, -6); BriDot.Text = ""; BriDot.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", BriDot).CornerRadius = UDim.new(1, 0)
local isMaxBri = false; local origLighting = {Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows, ClockTime = Lighting.ClockTime}
local function UpdateBri(val) local b = math.clamp(val, 0, 10); Lighting.Brightness = b; local percent = b / 10; BriFill.Size = UDim2.new(percent, 0, 1, 0); BriDot.Position = UDim2.new(percent, -6, 0.5, -6) end
local briDrag = false; BriDot.MouseButton1Down:Connect(function() briDrag = true end)
MaxBtn.MouseButton1Click:Connect(function() isMaxBri = not isMaxBri; MaxBtn.Text = "Max: "..(isMaxBri and "ON" or "OFF"); MaxBtn.BackgroundColor3 = isMaxBri and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(40, 40, 40); if isMaxBri then origLighting.Brightness = Lighting.Brightness; origLighting.Ambient = Lighting.Ambient; origLighting.OutdoorAmbient = Lighting.OutdoorAmbient; origLighting.GlobalShadows = Lighting.GlobalShadows; origLighting.ClockTime = Lighting.ClockTime else Lighting.Brightness = origLighting.Brightness; Lighting.Ambient = origLighting.Ambient; Lighting.OutdoorAmbient = origLighting.OutdoorAmbient; Lighting.GlobalShadows = origLighting.GlobalShadows; Lighting.ClockTime = origLighting.ClockTime end end)

local KeyFrame = createRow(40, 7, SetPageScroll)
local KeyLbl = Instance.new("TextLabel", KeyFrame); KeyLbl.Text="Menu Toggle Key:"; KeyLbl.Size=UDim2.new(0.5,0,1,0); KeyLbl.Position=UDim2.new(0,10,0,0); KeyLbl.BackgroundTransparency=1; KeyLbl.TextColor3=Color3.new(1,1,1); KeyLbl.TextXAlignment=Enum.TextXAlignment.Left; KeyLbl.Font=Enum.Font.Gotham
local KeyBtn = Instance.new("TextButton", KeyFrame); KeyBtn.Size=UDim2.new(0.4,0,0,30); KeyBtn.Position=UDim2.new(0.55,0,0,5); KeyBtn.BackgroundColor3=Color3.fromRGB(30,30,30); KeyBtn.Text="RightControl"; KeyBtn.TextColor3=Color3.new(0,1,1); KeyBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", KeyBtn).CornerRadius=UDim.new(0,6)
local listening = false; KeyBtn.MouseButton1Click:Connect(function() listening=true; KeyBtn.Text="Press any key..."; KeyBtn.TextColor3=Color3.new(1,1,0) end)
UserInputService.InputBegan:Connect(function(input) if listening and input.UserInputType==Enum.UserInputType.Keyboard then toggleKey = input.KeyCode; KeyBtn.Text=tostring(toggleKey):gsub("Enum.KeyCode.",""); KeyBtn.TextColor3=Color3.new(0,1,1); listening=false elseif input.KeyCode==toggleKey and not listening then ScreenGui.Enabled=not ScreenGui.Enabled end end)

local JobFrame = createRow(70, 8, SetPageScroll)
local JobBox = Instance.new("TextBox", JobFrame); JobBox.Size=UDim2.new(1,0,0,30); JobBox.BackgroundColor3=Color3.fromRGB(20,20,20); JobBox.TextColor3=Color3.new(0,1,1); JobBox.PlaceholderText="Paste Job ID to Join..."; JobBox.Text=""; Instance.new("UICorner", JobBox).CornerRadius=UDim.new(0,6); Instance.new("UIStroke", JobBox).Color=Color3.fromRGB(0,80,200)
local JoinBtn = Instance.new("TextButton", JobFrame); JoinBtn.Size=UDim2.new(1,0,0,30); JoinBtn.Position=UDim2.new(0,0,0,35); JoinBtn.BackgroundColor3=Color3.fromRGB(0,150,0); JoinBtn.Text="Join This Job ID"; JoinBtn.TextColor3=Color3.new(1,1,1); JoinBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", JoinBtn).CornerRadius=UDim.new(0,6)
JoinBtn.MouseButton1Click:Connect(function() if JobBox.Text ~= "" then JoinBtn.Text="Joining..."; TeleportService:TeleportToPlaceInstance(game.PlaceId, JobBox.Text, LocalPlayer) else JoinBtn.Text="Please enter ID!"; wait(1); JoinBtn.Text="Join This Job ID" end end)

local RejoinBtn = Instance.new("TextButton", SetPageScroll); RejoinBtn.LayoutOrder = 9; RejoinBtn.Size=UDim2.new(1,0,0,30); RejoinBtn.BackgroundColor3=Color3.fromRGB(200,50,50); RejoinBtn.Text="Rejoin Current Server"; RejoinBtn.TextColor3=Color3.new(1,1,1); RejoinBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", RejoinBtn).CornerRadius=UDim.new(0,6)
RejoinBtn.MouseButton1Click:Connect(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
local CopyBtn = Instance.new("TextButton", SetPageScroll); CopyBtn.LayoutOrder = 10; CopyBtn.Size=UDim2.new(1,0,0,30); CopyBtn.BackgroundColor3=Color3.fromRGB(0,80,200); CopyBtn.Text="Copy Server ID"; CopyBtn.TextColor3=Color3.new(1,1,1); CopyBtn.Font=Enum.Font.GothamBold; Instance.new("UICorner", CopyBtn).CornerRadius=UDim.new(0,6)
CopyBtn.MouseButton1Click:Connect(function() setclipboard(game.JobId); CopyBtn.Text="Copied!"; task.wait(1); CopyBtn.Text="Copy Server ID" end)

-- *** FIXED MAIN LOOP ***
RunService.RenderStepped:Connect(function()
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then flyDrag = false; spdDrag = false; briDrag = false; jmpDrag = false end
	local mousePos = UserInputService:GetMouseLocation().X
	if flyDrag then local pos = math.clamp((mousePos - FlySlider.AbsolutePosition.X) / FlySlider.AbsoluteSize.X, 0, 1); UpdateFly(pos * 500) end
	if spdDrag then local pos = math.clamp((mousePos - SpdSlider.AbsolutePosition.X) / SpdSlider.AbsoluteSize.X, 0, 1); UpdateSpd(pos * 500) end
	if jmpDrag then local pos = math.clamp((mousePos - JmpSlider.AbsolutePosition.X) / JmpSlider.AbsoluteSize.X, 0, 1); UpdateJmp(pos * 500) end
	if briDrag then local pos = math.clamp((mousePos - BriSlider.AbsolutePosition.X) / BriSlider.AbsoluteSize.X, 0, 1); UpdateBri(pos * 10); if isMaxBri then isMaxBri = false; MaxBtn.Text = "Max: OFF"; MaxBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end end

	if isSpeedEnabled and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum.WalkSpeed = targetSpeed end end
	if isJumpEnabled and LocalPlayer.Character then local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum.UseJumpPower = true; hum.JumpPower = targetJump end end
	if isMaxBri then Lighting.Brightness = 2; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false; Lighting.ClockTime = 14 end
	if isFrozen and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then local hrp = LocalPlayer.Character.HumanoidRootPart; hrp.Anchored = true; hrp.Velocity = Vector3.new(0,0,0); hrp.RotVelocity = Vector3.new(0,0,0) end
	
	-- TRUE AIMLOCK & SHIFTLOCK LOGIC
	local currentlyLockedCenter = false
	
	if isAiming and aimlockTarget and aimlockTarget.Character and aimlockTarget.Character:FindFirstChild("Head") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local targetPos = aimlockTarget.Character.Head.Position
		local hrp = LocalPlayer.Character.HumanoidRootPart
		-- 1. บังคับหันกล้องไปหาเป้าหมาย
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
		-- 2. บังคับหันตัวละครไปหาเป้าหมาย
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
		-- 3. ล็อคเมาส์
		currentlyLockedCenter = true
	elseif isShiftLocked and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.Humanoid.AutoRotate = false
		currentlyLockedCenter = true
		local lv = Camera.CFrame.LookVector
		LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(lv.X, 0, lv.Z))
	elseif not isAiming and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.AutoRotate = true
	end
	
	if currentlyLockedCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)
