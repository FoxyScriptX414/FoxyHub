-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FoxyHub_v7_Fixed"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Variables
local flySpeed = 50
local isFlying = false
local isNoclipping = false
local isInfJump = false
local isSpeedEnabled = false
local targetSpeed = 16
local espEnabled = false
local waypoints = {}
local toggleKey = Enum.KeyCode.RightControl

-- 1. Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 350) 
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
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
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
DragFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
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
	isResizing = true
	resizeStart = Vector2.new(Mouse.X, Mouse.Y)
	startSize = MainFrame.AbsoluteSize
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then isResizing = false end
end)
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
	
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 100, 255)
	s.Thickness = 1
	s.Parent = btn
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	
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

local function createPage(name)
	local p = Instance.new("Frame")
	p.Name = name.."Page"
	p.Size = UDim2.new(1, 0, 1, 0)
	p.BackgroundTransparency = 1
	p.Visible = false
	p.Parent = PageContainer
	
	local pad = Instance.new("UIPadding", p)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	return p
end

-- Info Page
local InfoPage = createPage("Info")
local InfoLayout = Instance.new("UIListLayout", InfoPage); InfoLayout.Padding = UDim.new(0, 10)
pages["Info"] = InfoPage

-- General Page
local GenPageScroll = Instance.new("ScrollingFrame")
GenPageScroll.Name = "GeneralPage"
GenPageScroll.Size = UDim2.new(1, 0, 1, 0)
GenPageScroll.BackgroundTransparency = 1
GenPageScroll.ScrollBarThickness = 4
GenPageScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 100, 255)
GenPageScroll.Visible = false
GenPageScroll.Parent = PageContainer
local padGen = Instance.new("UIPadding", GenPageScroll); padGen.PaddingTop = UDim.new(0, 10); padGen.PaddingLeft = UDim.new(0, 10); padGen.PaddingRight = UDim.new(0, 15)
pages["General"] = GenPageScroll

-- Setting Page
local SetPage = createPage("Setting")
local SetLayout = Instance.new("UIListLayout", SetPage); SetLayout.Padding = UDim.new(0, 10)
pages["Setting"] = SetPage

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
InfoBox.Size = UDim2.new(1, 0, 0, 80)
InfoBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
local InfoStroke = Instance.new("UIStroke", InfoBox); InfoStroke.Color = Color3.fromRGB(0, 100, 255)
local InfoCorner = Instance.new("UICorner", InfoBox); InfoCorner.CornerRadius = UDim.new(0, 8)
local InfoText = Instance.new("TextLabel", InfoBox)
InfoText.Size = UDim2.new(1, -20, 1, -10)
InfoText.Position = UDim2.new(0, 10, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.Font = Enum.Font.Code
InfoText.TextSize = 14

local startTime = tick()
RunService.RenderStepped:Connect(function()
	if InfoPage.Visible then
		local time = math.floor(tick() - startTime)
		local fps = math.floor(workspace:GetRealPhysicsFPS())
		InfoText.Text = string.format("Time Played: %ds\nFPS: %d\nUser: %s", time, fps, LocalPlayer.Name)
	end
end)

-- ================= GENERAL CONTENT ================= --
local GenLayout = Instance.new("UIListLayout", GenPageScroll)
GenLayout.Padding = UDim.new(0, 8)
GenLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createRow(height, order)
	local row = Instance.new("Frame", GenPageScroll)
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, height or 30) 
	row.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	local s = Instance.new("UIStroke", row); s.Color = Color3.fromRGB(0, 80, 200); s.Thickness = 1
	local c = Instance.new("UICorner", row); c.CornerRadius = UDim.new(0, 4)
	return row
end

-- 1. Inf Jump
local r1 = createRow(30, 1)
local InfBtn = Instance.new("TextButton", r1)
InfBtn.Size = UDim2.new(1,0,1,0); InfBtn.BackgroundTransparency=1; InfBtn.Text="Infinite Jump: OFF"; InfBtn.TextColor3=Color3.fromRGB(200,200,200); InfBtn.Font=Enum.Font.Gotham
InfBtn.MouseButton1Click:Connect(function()
	isInfJump = not isInfJump
	InfBtn.Text = "Infinite Jump: "..(isInfJump and "ON" or "OFF")
	InfBtn.TextColor3 = isInfJump and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
end)
UserInputService.JumpRequest:Connect(function() if isInfJump then LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end end)

-- 2. Noclip
local r2 = createRow(30, 2)
local NoBtn = Instance.new("TextButton", r2)
NoBtn.Size = UDim2.new(1,0,1,0); NoBtn.BackgroundTransparency=1; NoBtn.Text="Noclip: OFF"; NoBtn.TextColor3=Color3.fromRGB(200,200,200); NoBtn.Font=Enum.Font.Gotham
NoBtn.MouseButton1Click:Connect(function()
	isNoclipping = not isNoclipping
	NoBtn.Text = "Noclip: "..(isNoclipping and "ON" or "OFF")
	NoBtn.TextColor3 = isNoclipping and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
end)
RunService.Stepped:Connect(function()
	if isNoclipping and LocalPlayer.Character then for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end
end)

-- 3. Fly
local r3 = createRow(30, 3)
local FlyBtn = Instance.new("TextButton", r3)
FlyBtn.Size = UDim2.new(0.6,0,1,0); FlyBtn.BackgroundTransparency=1; FlyBtn.Text="Fly: OFF"; FlyBtn.Position=UDim2.new(0,10,0,0); FlyBtn.TextXAlignment=Enum.TextXAlignment.Left; FlyBtn.TextColor3=Color3.fromRGB(200,200,200); FlyBtn.Font=Enum.Font.Gotham
local FlyBox = Instance.new("TextBox", r3); FlyBox.Size=UDim2.new(0.2,0,0,20); FlyBox.Position=UDim2.new(0.75,0,0,5); FlyBox.Text="50"; FlyBox.BackgroundColor3=Color3.fromRGB(30,30,30); FlyBox.TextColor3=Color3.new(1,1,1)
local fc = Instance.new("UICorner", FlyBox); fc.CornerRadius=UDim.new(0,4)
FlyBox:GetPropertyChangedSignal("Text"):Connect(function() flySpeed=tonumber(FlyBox.Text) or 50 end)
FlyBtn.MouseButton1Click:Connect(function()
	isFlying = not isFlying
	FlyBtn.Text = "Fly: "..(isFlying and "ON" or "OFF")
	FlyBtn.TextColor3 = isFlying and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
	if isFlying then
		local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not HRP then return end
		local bg = Instance.new("BodyGyro", HRP); bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=9000
		local bv = Instance.new("BodyVelocity", HRP); bv.MaxForce=Vector3.new(9e9,9e9,9e9)
		repeat task.wait()
			LocalPlayer.Character.Humanoid.PlatformStand = true; bg.CFrame = Workspace.CurrentCamera.CFrame
			local cf = Workspace.CurrentCamera.CFrame; local v = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then v=v+cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then v=v-cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then v=v+cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then v=v-cf.RightVector end
			bv.Velocity = v*flySpeed
		until not isFlying
		LocalPlayer.Character.Humanoid.PlatformStand = false; bg:Destroy(); bv:Destroy()
	end
end)

-- 4. WalkSpeed (FIXED LOGIC)
local r4 = createRow(30, 4)
local SpdBtn = Instance.new("TextButton", r4)
SpdBtn.Size = UDim2.new(0.6, 0, 1, 0)
SpdBtn.Position = UDim2.new(0, 10, 0, 0)
SpdBtn.BackgroundTransparency = 1
SpdBtn.Text = "WalkSpeed: OFF"
SpdBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SpdBtn.TextXAlignment = Enum.TextXAlignment.Left
SpdBtn.Font = Enum.Font.Gotham

local SpdBox = Instance.new("TextBox", r4)
SpdBox.Size = UDim2.new(0.2, 0, 0, 20)
SpdBox.Position = UDim2.new(0.75, 0, 0, 5)
SpdBox.Text = "16"
SpdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SpdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
local sc2 = Instance.new("UICorner", SpdBox); sc2.CornerRadius = UDim.new(0, 4)

-- อัปเดตตัวแปรทันทีที่พิมพ์ (Real-time update)
SpdBox:GetPropertyChangedSignal("Text"):Connect(function()
	targetSpeed = tonumber(SpdBox.Text) or 16
	if targetSpeed > 1000 then targetSpeed = 1000; SpdBox.Text = "1000" end
end)

SpdBtn.MouseButton1Click:Connect(function()
	isSpeedEnabled = not isSpeedEnabled
	SpdBtn.Text = "WalkSpeed: " .. (isSpeedEnabled and "ON" or "OFF")
	SpdBtn.TextColor3 = isSpeedEnabled and Color3.new(0, 1, 0) or Color3.new(0.8, 0.8, 0.8)
	
	-- บังคับอ่านค่าอีกรอบเมื่อกดปุ่ม เพื่อความชัวร์
	targetSpeed = tonumber(SpdBox.Text) or 16
	
	if not isSpeedEnabled and LocalPlayer.Character then
		LocalPlayer.Character.Humanoid.WalkSpeed = 16
	end
end)

-- Speed Loop Logic (Fix Bug)
RunService.RenderStepped:Connect(function()
	if isSpeedEnabled and LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
		if hum then 
			hum.WalkSpeed = targetSpeed 
		end
	end
end)

-- 5. ESP
local r5 = createRow(30, 5)
local EspBtn = Instance.new("TextButton", r5)
EspBtn.Size = UDim2.new(1,0,1,0); EspBtn.BackgroundTransparency=1; EspBtn.Text="ESP Players: OFF"; EspBtn.TextColor3=Color3.fromRGB(200,200,200); EspBtn.Font=Enum.Font.Gotham
EspBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	EspBtn.Text = "ESP Players: "..(espEnabled and "ON" or "OFF")
	EspBtn.TextColor3 = espEnabled and Color3.new(0,1,0) or Color3.new(0.8,0.8,0.8)
	for _,p in pairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("ESP_Tag") then p.Character.Head.ESP_Tag.Enabled = espEnabled end
	end
end)

-- 6. TP Player
local r6 = createRow(110, 6)
local TpLbl = Instance.new("TextLabel", r6); TpLbl.Text="Teleport to Player"; TpLbl.Size=UDim2.new(1,0,0,20); TpLbl.BackgroundTransparency=1; TpLbl.TextColor3=Color3.new(1,1,1); TpLbl.Font=Enum.Font.GothamBold; TpLbl.Position=UDim2.new(0,0,0,5)
local TpScroll = Instance.new("ScrollingFrame", r6)
TpScroll.Size = UDim2.new(0.9, 0, 0, 70); TpScroll.Position = UDim2.new(0.05, 0, 0, 30); TpScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TpScroll.CanvasSize = UDim2.new(0,0,0,0); TpScroll.ScrollBarThickness = 2
local TpList = Instance.new("UIListLayout", TpScroll); TpList.Padding=UDim.new(0,2)
local RefreshTp = Instance.new("ImageButton", r6); RefreshTp.Size = UDim2.new(0,18,0,18); RefreshTp.Position=UDim2.new(1,-25,0,5); RefreshTp.BackgroundColor3=Color3.fromRGB(0,80,200); RefreshTp.Image="rbxassetid://6031097225"
local function RefreshPlayerList()
	for _,v in pairs(TpScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LocalPlayer then
			local b = Instance.new("TextButton", TpScroll); b.Size=UDim2.new(1,0,0,25); b.Text=p.Name; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham
			b.MouseButton1Click:Connect(function() if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then LocalPlayer.Character:MoveTo(p.Character.HumanoidRootPart.Position) end end)
		end
	end
	TpScroll.CanvasSize = UDim2.new(0,0,0,TpList.AbsoluteContentSize.Y)
end
RefreshTp.MouseButton1Click:Connect(RefreshPlayerList); RefreshPlayerList()

-- 7. Waypoints
local r7 = createRow(140, 7)
local WpLbl = Instance.new("TextLabel", r7); WpLbl.Text="Waypoints System"; WpLbl.Size=UDim2.new(1,0,0,20); WpLbl.BackgroundTransparency=1; WpLbl.TextColor3=Color3.new(1,1,1); WpLbl.Font=Enum.Font.GothamBold; WpLbl.Position=UDim2.new(0,0,0,5)
local WpBox = Instance.new("TextBox", r7); WpBox.Size=UDim2.new(0.6,0,0,25); WpBox.Position=UDim2.new(0.05,0,0,30); WpBox.PlaceholderText="Name..."; WpBox.BackgroundColor3=Color3.fromRGB(30,30,30); WpBox.TextColor3=Color3.new(1,1,1)
local AddWp = Instance.new("TextButton", r7); AddWp.Size=UDim2.new(0.25,0,0,25); AddWp.Position=UDim2.new(0.7,0,0,30); AddWp.Text="Add"; AddWp.BackgroundColor3=Color3.fromRGB(0,80,200); AddWp.TextColor3=Color3.new(1,1,1)
local WpScroll = Instance.new("ScrollingFrame", r7); WpScroll.Size=UDim2.new(0.9,0,0,70); WpScroll.Position=UDim2.new(0.05,0,0,60); WpScroll.BackgroundColor3=Color3.fromRGB(20,20,20); WpScroll.ScrollBarThickness=2
local WpList = Instance.new("UIListLayout", WpScroll); WpList.Padding=UDim.new(0,2)
local function RefreshWp()
	for _,v in pairs(WpScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
	for name, cf in pairs(waypoints) do
		local f = Instance.new("Frame", WpScroll); f.Size=UDim2.new(1,0,0,25); f.BackgroundTransparency=1
		local b = Instance.new("TextButton", f); b.Size=UDim2.new(0.75,0,1,0); b.Text="  "..name; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.new(1,1,1); b.TextXAlignment=Enum.TextXAlignment.Left; b.Font=Enum.Font.Gotham
		b.MouseButton1Click:Connect(function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = cf end end)
		local d = Instance.new("TextButton", f); d.Size=UDim2.new(0.2,0,1,0); d.Position=UDim2.new(0.8,0,0,0); d.Text="Del"; d.BackgroundColor3=Color3.fromRGB(200,50,50); d.TextColor3=Color3.new(1,1,1); d.Font=Enum.Font.GothamBold
		d.MouseButton1Click:Connect(function() waypoints[name]=nil; RefreshWp() end)
	end
	WpScroll.CanvasSize = UDim2.new(0,0,0,WpList.AbsoluteContentSize.Y)
end
AddWp.MouseButton1Click:Connect(function() local name = WpBox.Text; if name ~= "" and LocalPlayer.Character then waypoints[name] = LocalPlayer.Character.HumanoidRootPart.CFrame; WpBox.Text = ""; RefreshWp() end end)

-- ESP Function
local function AddEsp(p)
	local function app(c)
		local h = c:WaitForChild("Head", 5)
		if not h or h:FindFirstChild("ESP_Tag") then return end
		local b = Instance.new("BillboardGui", h); b.Name="ESP_Tag"; b.Size=UDim2.new(0,100,0,50); b.StudsOffset=Vector3.new(0,2,0); b.AlwaysOnTop=true; b.Enabled=espEnabled
		local t = Instance.new("TextLabel", b); t.Size=UDim2.new(1,0,0.5,0); t.BackgroundTransparency=1; t.Text=p.Name; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0
		local hp = Instance.new("TextLabel", b); hp.Size=UDim2.new(1,0,0.5,0); hp.Position=UDim2.new(0,0,0.5,0); hp.BackgroundTransparency=1; hp.TextColor3=Color3.new(0,1,0); hp.TextStrokeTransparency=0
		local hum = c:WaitForChild("Humanoid", 5); if hum then hp.Text="HP: "..math.floor(hum.Health); hum.HealthChanged:Connect(function() hp.Text="HP: "..math.floor(hum.Health) end) end
	end
	if p.Character then app(p.Character) end; p.CharacterAdded:Connect(app)
end
for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then AddEsp(p) end end; Players.PlayerAdded:Connect(AddEsp)

-- ================= SETTING CONTENT ================= --
local KeyFrame = Instance.new("Frame", SetPage); KeyFrame.Size = UDim2.new(1,0,0,40); KeyFrame.BackgroundColor3=Color3.fromRGB(15,15,15)
local ks = Instance.new("UIStroke", KeyFrame); ks.Color=Color3.fromRGB(0,80,200); local kc = Instance.new("UICorner", KeyFrame); kc.CornerRadius=UDim.new(0,6)
local KeyLbl = Instance.new("TextLabel", KeyFrame); KeyLbl.Text="Menu Toggle Key:"; KeyLbl.Size=UDim2.new(0.5,0,1,0); KeyLbl.Position=UDim2.new(0,10,0,0); KeyLbl.BackgroundTransparency=1; KeyLbl.TextColor3=Color3.new(1,1,1); KeyLbl.TextXAlignment=Enum.TextXAlignment.Left; KeyLbl.Font=Enum.Font.Gotham
local KeyBtn = Instance.new("TextButton", KeyFrame); KeyBtn.Size=UDim2.new(0.4,0,0,30); KeyBtn.Position=UDim2.new(0.55,0,0,5); KeyBtn.BackgroundColor3=Color3.fromRGB(30,30,30); KeyBtn.Text="RightControl"; KeyBtn.TextColor3=Color3.new(0,1,1); KeyBtn.Font=Enum.Font.GothamBold
local kbc = Instance.new("UICorner", KeyBtn); kbc.CornerRadius=UDim.new(0,6)
local listening = false
KeyBtn.MouseButton1Click:Connect(function() listening=true; KeyBtn.Text="Press any key..."; KeyBtn.TextColor3=Color3.new(1,1,0) end)
UserInputService.InputBegan:Connect(function(input)
	if listening and input.UserInputType==Enum.UserInputType.Keyboard then
		toggleKey = input.KeyCode; KeyBtn.Text=tostring(toggleKey):gsub("Enum.KeyCode.",""); KeyBtn.TextColor3=Color3.new(0,1,1); listening=false
	elseif input.KeyCode==toggleKey and not listening then ScreenGui.Enabled=not ScreenGui.Enabled end
end)

local JobFrame = Instance.new("Frame", SetPage); JobFrame.Size = UDim2.new(1,0,0,70); JobFrame.BackgroundTransparency=1
local JobBox = Instance.new("TextBox", JobFrame); JobBox.Size=UDim2.new(1,0,0,30); JobBox.BackgroundColor3=Color3.fromRGB(20,20,20); JobBox.TextColor3=Color3.new(0,1,1); JobBox.PlaceholderText="Paste Job ID to Join..."; JobBox.Text=""
local jbc = Instance.new("UICorner", JobBox); jbc.CornerRadius=UDim.new(0,6); local jbs = Instance.new("UIStroke", JobBox); jbs.Color=Color3.fromRGB(0,80,200)
local JoinBtn = Instance.new("TextButton", JobFrame); JoinBtn.Size=UDim2.new(1,0,0,30); JoinBtn.Position=UDim2.new(0,0,0,35); JoinBtn.BackgroundColor3=Color3.fromRGB(0,150,0); JoinBtn.Text="Join This Job ID"; JoinBtn.TextColor3=Color3.new(1,1,1); JoinBtn.Font=Enum.Font.GothamBold
local jbc2 = Instance.new("UICorner", JoinBtn); jbc2.CornerRadius=UDim.new(0,6)
JoinBtn.MouseButton1Click:Connect(function() if JobBox.Text ~= "" then JoinBtn.Text="Joining..."; TeleportService:TeleportToPlaceInstance(game.PlaceId, JobBox.Text, LocalPlayer) else JoinBtn.Text="Please enter ID!"; wait(1); JoinBtn.Text="Join This Job ID" end end)
local RejoinBtn = Instance.new("TextButton", SetPage); RejoinBtn.Size=UDim2.new(1,0,0,30); RejoinBtn.BackgroundColor3=Color3.fromRGB(200,50,50); RejoinBtn.Text="Rejoin Current Server"; RejoinBtn.TextColor3=Color3.new(1,1,1); RejoinBtn.Font=Enum.Font.GothamBold
local rbc = Instance.new("UICorner", RejoinBtn); rbc.CornerRadius=UDim.new(0,6)
RejoinBtn.MouseButton1Click:Connect(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
local CopyBtn = Instance.new("TextButton", SetPage); CopyBtn.Size=UDim2.new(1,0,0,30); CopyBtn.BackgroundColor3=Color3.fromRGB(0,80,200); CopyBtn.Text="Copy Server ID"; CopyBtn.TextColor3=Color3.new(1,1,1); CopyBtn.Font=Enum.Font.GothamBold
local cbc = Instance.new("UICorner", CopyBtn); cbc.CornerRadius=UDim.new(0,6)
CopyBtn.MouseButton1Click:Connect(function() setclipboard(game.JobId); CopyBtn.Text="Copied!"; task.wait(1); CopyBtn.Text="Copy Server ID" end)
