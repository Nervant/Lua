local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Aiming = false
local LockedTarget = nil
local AimPart = "Head"
local DragEnabled = true
local SelectedKey = Enum.KeyCode.Q
local highlight = nil

local function toKeyCode(str)
	local success, key = pcall(function()
		return Enum.KeyCode[str]
	end)
	if success and key then
		return key
	end
	for _, code in ipairs(Enum.KeyCode:GetEnumItems()) do
		if code.Name:lower() == str:lower() then
			return code
		end
	end
	return nil
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "🔫",
	LoadingTitle = "🤨",
	LoadingSubtitle = " ",
	ConfigurationSaving = { Enabled = false },
	DisableRayfieldPrompts = true
})

local MainTab = Window:CreateTab("Main", "target")

MainTab:CreateDropdown({
	Name = "Target Part",
	Options = { "Head", "Torso" },
	CurrentOption = AimPart,
	Flag = "TargetPart",
	Callback = function(part)
		AimPart = part
	end
})

local keys = { "Q", "E", "R", "T", "Y", "F", "G", "Z", "X", "C", "V", "B", "LeftShift", "RightShift" }

MainTab:CreateDropdown({
	Name = "Aimlock Key",
	Options = keys,
	CurrentOption = "Q",
	Flag = "KeySelect",
	Callback = function(key)
		local keyStr = typeof(key) == "table" and key[1] or key
		local kc = toKeyCode(keyStr)
		if kc then
			SelectedKey = kc
		end
	end
})

MainTab:CreateToggle({
	Name = "Mobile Button",
	CurrentValue = false,
	Flag = "MobileBtn",9
	Callback = function(v)
		floatFrame.Visible = v
	end
})

MainTab:CreateToggle({
	Name = "Lock Mobile Button",
	CurrentValue = false,
	Flag = "LockDrag",
	Callback = function(v)
		DragEnabled = not v
	end
})

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AimlockFloat"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

floatFrame = Instance.new("Frame")
floatFrame.Size = UDim2.new(0, 170, 0, 50)
floatFrame.Position = UDim2.new(0.5, -85, 0.5, -25)
floatFrame.BackgroundTransparency = 1
floatFrame.Active = true
floatFrame.Visible = false
floatFrame.Parent = gui

floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(1, 0, 1, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
floatBtn.TextColor3 = Color3.new(1, 1, 1)
floatBtn.Font = Enum.Font.Gotham
floatBtn.TextSize = 14
floatBtn.Text = "Aimlock: OFF"
floatBtn.BorderSizePixel = 0
floatBtn.Parent = floatFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = floatBtn

local function updateButton()
	floatBtn.Text = "Aimlock: " .. (Aiming and "ON" or "OFF")
	floatBtn.BackgroundColor3 = Aiming and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(0, 0, 0)
end

local function getTarget()
	local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local closest, closestDist = nil, math.huge
	for _, v in ipairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
			if player.Team and v.Team and v.Team == player.Team then continue end
			local part = v.Character:FindFirstChild(AimPart) or v.Character:FindFirstChild("HumanoidRootPart")
			if part then
				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if dist < closestDist then
						closestDist = dist
						closest = v
					end
				end
			end
		end
	end
	return closest
end

local function toggleAimlock()
	if Aiming then
		Aiming = false
		LockedTarget = nil
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
	else
		local target = getTarget()
		if target then
			LockedTarget = target
			Aiming = true
			if highlight then
				highlight:Destroy()
			end
			highlight = Instance.new("Highlight")
			highlight.Adornee = target.Character
			highlight.FillColor = target.TeamColor.Color
			highlight.FillTransparency = 0.2
			highlight.OutlineTransparency = 1
			highlight.Parent = target.Character
		end
	end
	updateButton()
end

floatBtn.MouseButton1Click:Connect(toggleAimlock)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == SelectedKey then
		toggleAimlock()
	end
end)

RunService.RenderStepped:Connect(function()
	if Aiming and LockedTarget and LockedTarget.Character then
		local humanoid = LockedTarget.Character:FindFirstChild("Humanoid")
		local part = LockedTarget.Character:FindFirstChild(AimPart) or LockedTarget.Character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and part then
			camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
		else
			Aiming = false
			LockedTarget = nil
			if highlight then
				highlight:Destroy()
				highlight = nil
			end
			updateButton()
		end
	end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == LockedTarget then
		Aiming = false
		LockedTarget = nil
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
		updateButton()
	end
end)

local dragging = false
local dragStart, startPos

floatBtn.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and DragEnabled then
		dragging = true
		dragStart = input.Position
		startPos = floatFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		floatFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

updateButton()
